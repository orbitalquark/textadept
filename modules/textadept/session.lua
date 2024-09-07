-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Session support for Textadept.
-- @module textadept.session
local M = {}

--- Save the session when quitting.
-- The default value is `true` unless the user passed the command line switch `-n` or `--nosession`
-- to Textadept.
M.save_on_quit = true
if arg then
	for _, arg in ipairs(arg) do if arg == '-t' or arg == '--test' then M.save_on_quit = false end end
end

-- Events.
local session_events = {'session_save', 'session_load'}
for _, v in ipairs(session_events) do events[v:upper()] = v end

--- Emitted when saving a session.
-- Arguments:
--
-- - *session*: Table of session data to save. All handlers will have access to this same table,
--	and Textadept's default handler reserves the use of some keys. Note that functions,
--	userdata, and circular table values cannot be saved. The latter case is not recognized
--	at all, so beware.
-- @field _G.events.SESSION_SAVE

--- Emitted when loading a session.
-- Arguments:
--
-- - *session*: Table of session data to load. All handlers will have access to this same table.
-- @field _G.events.SESSION_LOAD

-- This comment is needed for LDoc to process the previous field.

local session_file = _USERHOME .. (not CURSES and '/session' or '/session_term')

--- Loads session file *filename* or the user-selected session, returning `true` if a session
-- file was opened and read.
-- Textadept restores split views, opened buffers, cursor information, recent files, and bookmarks.
-- @param[opt] filename Optional absolute path to the session file to load. If `nil`, the user
--	is prompted for one.
-- @return `true` if the session file was opened and read; `nil` otherwise.
-- @usage textadept.session.load(filename)
function M.load(filename)
	local dir, name = session_file:match('^(.-)[/\\]?([^/\\]+)$')
	if not assert_type(filename, 'string/nil', 1) then
		filename = ui.dialogs.open{title = _L['Load Session'], dir = dir, file = name}
		if not filename then return end
	end
	if session_file ~= filename then M.save(session_file) end
	local f = loadfile(filename, 't', {})
	if not f or not io.close_all_buffers() then return end -- fail silently
	local session = f()
	local not_found = {}

	-- Unserialize cwd.
	if session.cwd then lfs.chdir(session.cwd) end

	-- Unserialize buffers.
	for _, buf in ipairs(session.buffers) do
		if lfs.attributes(buf.filename) then
			io.open_file(buf.filename)
			buffer:set_sel(buf.anchor, buf.current_pos)
			view.first_visible_line = buf.top_line
			for _, line in ipairs(buf.bookmarks) do
				buffer:marker_add(line, textadept.bookmarks.MARK_BOOKMARK)
			end
		elseif buf.filename:find('^%[.+%]$') then
			buffer.new()._type = buf.filename
			buffer:set_save_point()
			events.emit(events.FILE_OPENED, buf.filename) -- close initial buffer
		else
			not_found[#not_found + 1] = buf.filename:iconv('UTF-8', _CHARSET)
		end
	end

	-- Unserialize UI state.
	ui.maximized = session.ui.maximized
	if not ui.maximized then ui.size = session.ui.size end

	-- Unserialize views.
	local function unserialize_split(split)
		if type(split) ~= 'table' then
			view:goto_buffer(_BUFFERS[math.min(split, #_BUFFERS)])
		else
			for i, view in ipairs{view:split(split.vertical)} do
				view.size = split.size
				ui.goto_view(view)
				unserialize_split(split[i])
			end
		end
	end
	unserialize_split(session.views[1])
	ui.goto_view(_VIEWS[math.min(session.views.current, #_VIEWS)])

	-- Unserialize recent files.
	io.recent_files = session.recent_files

	-- Unserialize user data.
	events.emit(events.SESSION_LOAD, session)

	if #not_found > 0 then
		ui.dialogs.message{
			title = _L['Session Files Not Found'],
			text = string.format('%s\n • %s', _L['The following session files were not found:'],
				table.concat(not_found, '\n • ')), icon = 'dialog-warning'
		}
	end
	session_file = filename
	return true
end
-- Load session when no args are present.
events.connect(events.ARG_NONE, function() if M.save_on_quit then M.load(session_file) end end)

--- Returns value *val* serialized as a string.
-- This is a very simple implementation suitable for session saving only.
-- Ignores function, userdata, and thread types, and does not handle circular tables.
local function _tostring(val)
	if type(val) == 'table' then
		local t = {}
		for k, v in pairs(val) do t[#t + 1] = string.format('[%s]=%s,', _tostring(k), _tostring(v)) end
		return string.format('{%s}', table.concat(t))
	elseif type(val) == 'function' or type(val) == 'userdata' or type(val) == 'thread' then
		val = nil
	end
	return type(val) == 'string' and string.format('%q', val) or tostring(val)
end

--- Saves the session to file *filename* or the user-selected file.
-- Saves split views, opened buffers, cursor information, recent files, and bookmarks.
-- Upon quitting, the current session is saved to *filename* again, unless
-- `textadept.session.save_on_quit` is `false`.
-- @param filename[opt] Optional absolute path to the session file to save. If `nil`, the user
--	is prompted for one.
-- @usage textadept.session.save(filename)
function M.save(filename)
	local dir, name = session_file:match('^(.-)[/\\]?([^/\\]+)$')
	if not assert_type(filename, 'string/nil', 1) then
		filename = ui.dialogs.save{title = _L['Save Session'], dir = dir, file = name}
		if not filename then return end
	end
	local session = {}

	-- Serialize user data.
	events.emit(events.SESSION_SAVE, session)

	-- Serialize cwd.
	session.cwd = lfs.currentdir()

	-- Serialize buffers.
	session.buffers = {}
	for _, buffer in ipairs(_BUFFERS) do
		if not buffer.filename and not buffer._type then goto continue end
		local current = buffer == view.buffer
		session.buffers[#session.buffers + 1] = {
			filename = buffer.filename or buffer._type,
			anchor = current and buffer.anchor or buffer._anchor or 1,
			current_pos = current and buffer.current_pos or buffer._current_pos or 1,
			top_line = current and view.first_visible_line or buffer._top_line or 1
		}
		local bookmarks = {}
		local BOOKMARK_BIT = 1 << textadept.bookmarks.MARK_BOOKMARK - 1
		local line = buffer:marker_next(1, BOOKMARK_BIT)
		while line ~= -1 do
			bookmarks[#bookmarks + 1] = line
			line = buffer:marker_next(line + 1, BOOKMARK_BIT)
		end
		session.buffers[#session.buffers].bookmarks = bookmarks
		::continue::
	end

	-- Serialize UI state.
	session.ui = {maximized = ui.maximized, size = ui.size}

	-- Serialize views.
	local function serialize_split(split)
		return split.buffer and _BUFFERS[split.buffer] or {
			serialize_split(split[1]), serialize_split(split[2]), vertical = split.vertical,
			size = split.size
		}
	end
	session.views = {serialize_split(ui.get_split_table()), current = _VIEWS[view]}

	-- Serialize recent files.
	session.recent_files = io.recent_files

	-- Write the session.
	assert(io.open(filename, 'wb')):write('return ', _tostring(session)):close()
	session_file = filename
end
-- Saves session on quit.
events.connect(events.QUIT, function() if M.save_on_quit then M.save(session_file) end end, 1)

-- Does not save session on quit.
args.register('-n', '--nosession', 0, function() M.save_on_quit = false end,
	'No session functionality')
-- Loads the given session on startup.
args.register('-s', '--session', 1, function(name)
	if not lfs.attributes(name) then name = string.format('%s/%s', _USERHOME, name) end
	M.load(name)
	return true -- prevent events.ARG_NONE
end, 'Load session')

return M

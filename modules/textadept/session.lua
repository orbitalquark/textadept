-- Copyright 2007-2026 Mitchell. See LICENSE.

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
for _, v in ipairs{'session_save', 'session_load'} do events[v:upper()] = v end

--- Emitted when saving a session.
-- Arguments:
-- - *session*: Table of session data to save. All handlers will have access to this same table,
--	and Textadept's default handler reserves the use of some keys. Note that functions,
--	userdata, and circular table values cannot be saved. The latter case is not recognized
--	at all, so beware of creating in infinite loop.
-- @field _G.events.SESSION_SAVE

--- Emitted when loading a session.
-- Arguments:
-- - *session*: Table of session data to load. All handlers will have access to this same table.
-- @field _G.events.SESSION_LOAD

-- This comment is needed for LDoc to process the previous field.

local session_file = _USERHOME .. (not CURSES and '/session' or '/session_term')

--- Loads a session file.
-- Textadept restores split views, opened buffers, cursor information, recent files, and bookmarks.
-- @param[opt] filename String absolute path to the session file to load. If `nil`, the user
--	is prompted for one.
-- @see events.SESSION_LOAD
function M.load(filename)
	if not assert_type(filename, 'string/nil', 1) then
		local dir, name = session_file:match('^(.-)[/\\]?([^/\\]+)$')
		filename = ui.dialogs.open{title = _L['Load Session'], dir = dir, file = name}
		if not filename then return end
	end
	if session_file ~= filename then M.save(session_file) end
	local f = loadfile(filename, 't', {})
	if not f or not io.close_all_buffers() then return end -- fail silently
	local session, files_not_found = f(), {}

	-- Unserialize cwd.
	if session.cwd then lfs.chdir(session.cwd) end

	-- Unserialize buffers.
	local tabs = ui.tabs
	if tabs then ui.tabs = false end -- avoid repeated tab add-and-redraw
	local MARK_BOOKMARK = textadept.bookmarks.MARK_BOOKMARK
	for _, buf in ipairs(session.buffers) do
		if not lfs.attributes(buf.filename) then
			files_not_found[#files_not_found + 1] = buf.filename:iconv('UTF-8', _CHARSET)
			goto continue
		end
		io.open_file(buf.filename)
		if not buf.selection then buf.selection = buf.anchor - 1 .. '-' .. buf.current_pos - 1 end
		buffer.selection_serialized, view.first_visible_line = buf.selection, buf.top_line
		if buf.folds and #buf.folds > 0 then buffer:colorize(1, -1) end
		for _, line in ipairs(buf.folds or {}) do
			if buffer.fold_level[line] & buffer.FOLDLEVELHEADERFLAG > 0 then view:toggle_fold(line) end
		end
		for _, line in ipairs(buf.bookmarks) do buffer:marker_add(line, MARK_BOOKMARK) end
		::continue::
	end
	if tabs then ui.tabs = tabs end -- restore

	-- Unserialize UI state.
	ui.maximized = session.ui.maximized
	if not ui.maximized then ui.size = session.ui.size end

	-- Unserialize views.
	local function load_split(split)
		if type(split) ~= 'table' then
			view:goto_buffer(_BUFFERS[math.min(split, #_BUFFERS)])
			return
		end
		for i, view in ipairs{view:split(split.vertical)} do
			if i == 1 then view.split_pos = split.size end -- TODO: split_pos?
			ui.goto_view(view)
			load_split(split[i])
		end
	end
	load_split(session.views[1])
	ui.goto_view(_VIEWS[math.min(session.views.current, #_VIEWS)])

	-- Unserialize recent files.
	io.recent_files = {}
	for _, file in ipairs(session.recent_files) do
		if lfs.attributes(file) then io.recent_files[#io.recent_files + 1] = file end
	end

	-- Unserialize user data.
	events.emit(events.SESSION_LOAD, session)

	session_file = filename
	if #files_not_found == 0 then return end
	ui.dialogs.message{
		title = _L['Session Files Not Found'],
		text = string.format('%s\n • %s', _L['The following session files were not found:'],
			table.concat(files_not_found, '\n • ')), icon = 'dialog-warning'
	}
end
-- Load session when no args are present.
events.connect(events.ARG_NONE, function() if M.save_on_quit then M.load(session_file) end end)

--- Returns a value serialized as a string.
-- This is a very simple implementation suitable for session saving only.
-- Ignores function, userdata, and thread types, and does not handle circular tables.
local function _tostring(val)
	if type(val) == 'function' or type(val) == 'userdata' or type(val) == 'thread' then return 'nil' end
	if type(val) == 'table' then
		local t = {}
		for k, v in pairs(val) do t[#t + 1] = string.format('[%s]=%s,', _tostring(k), _tostring(v)) end
		return string.format('{%s}', table.concat(t))
	end
	return type(val) == 'string' and string.format('%q', val) or tostring(val)
end

--- Saves the session to a file.
-- Textadept saves split views, opened buffers, cursor information, recent files, and bookmarks.
--
-- The editor will save the current session to that file again before quitting unless
-- `textadept.session.save_on_quit` is `false`.
-- @param filename[opt] Optional absolute path to the session file to save. If `nil`, the user
--	is prompted for one.
-- @see events.SESSION_SAVE
function M.save(filename)
	if not assert_type(filename, 'string/nil', 1) then
		local dir, name = session_file:match('^(.-)[/\\]?([^/\\]+)$')
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
		if not buffer.filename then goto continue end
		local current = buffer == view.buffer
		session.buffers[#session.buffers + 1] = {
			filename = buffer.filename,
			selection = current and buffer.selection_serialized or buffer._selection or '0',
			top_line = current and view.first_visible_line or buffer._top_line or 1
		}
		local folds = not current and buffer._folds or {}
		if current then
			local i = view:contracted_fold_next(1)
			while i >= 1 do folds[#folds + 1], i = i, view:contracted_fold_next(i + 1) end
		end
		session.buffers[#session.buffers].folds = folds
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
	local function save_split(split)
		return split.buffer and _BUFFERS[split.buffer] or
			{save_split(split[1]), save_split(split[2]), vertical = split.vertical, size = split.size[3]}
	end
	session.views = {save_split(ui.get_split_table()), current = _VIEWS[view]}

	-- Serialize recent files.
	session.recent_files = io.recent_files

	-- Write the session.
	assert(io.open(filename, 'wb')):write('return ', _tostring(session)):close()
	session_file = filename
end
-- Saves session on quit.
events.connect(events.QUIT, function() if M.save_on_quit then M.save(session_file) end end, 1)

-- Does not save session on quit.
args.register('-n', '--nosession', 0, function() M.save_on_quit = false end, 'Disable sessions')
-- Loads a session on startup.
args.register('-s', '--session', 1, function(name)
	if not lfs.attributes(name) then name = string.format('%s/%s', _USERHOME, name) end
	M.load(name)
	return true -- prevent events.ARG_NONE
end, 'Load session')

return M

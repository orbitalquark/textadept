-- Copyright 2007-2025 Mitchell. See LICENSE.

--- Extends Lua's `io` library with Textadept functions for working with files.
-- @module io

-- Events.
local file_io_events = {'file_opened', 'file_before_save', 'file_after_save', 'file_changed'}
for _, v in ipairs(file_io_events) do events[v:upper()] = v end

--- Emitted after opening a file in a new buffer.
-- Arguments:
-- - *filename*: The opened file's filename.
-- @see io.open_file
-- @field _G.events.FILE_OPENED

--- Emitted before saving a file to disk.
-- Arguments:
-- - *filename*: The filename of the file being saved.
-- @see buffer.save
-- @field _G.events.FILE_BEFORE_SAVE

--- Emitted after saving a file to disk.
-- Arguments:
-- - *filename*: The filename of the saved file.
-- - *saved_as*: Whether or not the file was saved under a different filename.
-- @see buffer.save
-- @see buffer.save_as
-- @field _G.events.FILE_AFTER_SAVE

--- Emitted when Textadept detects that an open file was modified externally.
-- The default behavior is to prompt the user to reload the file. In order to override this,
-- connect to this event with an index of `1` and return `true`.
--
-- Arguments:
-- - *filename*: The filename externally modified.
-- @field _G.events.FILE_CHANGED

--- Attempt to detect indentation settings for opened files.
-- If any non-blank line starts with a tab, tabs are used. Otherwise, for the first non-blank
-- line that starts with between two and eight spaces, that number of spaces is used.
--
-- The default value is `true`.
io.detect_indentation = true

--- Ensure there is a final newline when saving text files.
-- This has no effect on binary files.
--
-- The default value is `false` on Windows, and `true` on macOS, Linux, and BSD.
io.ensure_final_newline = not WIN32

--- Track file changes using line markers and buffer indicators.
-- Changes shown are with respect to the file on disk, not the file's version control state
-- (if it has one).
--
-- The terminal version only shows line markers.
--
-- The default value is `false`.
io.track_changes = false

--- The maximum number of files listed in the quick open list.
-- The default value is `5000`.
io.quick_open_max = 5000

--- Table of recently opened files, the most recent being towards the top.
io.recent_files = {}

--- Table of encodings to attempt to decode files with.
-- The default list contains UTF-8, ASCII, CP1252, and UTF-16.
--
-- You should add to this list if you work with files encoded in something else. Valid encodings
-- are [GNU iconv's encodings][], and include:
-- - European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
--	KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
--	Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
--	Macintosh.
-- - Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
--	UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.
--
-- [GNU iconv's encodings]: https://www.gnu.org/software/libiconv/
-- @usage io.encodings[#io.encodings + 1] = 'UTF-32'
-- @see string.iconv
-- @table encodings

-- This comment is needed to prevent LDoc from parsing the following table.

io.encodings = {'UTF-8', 'ASCII', 'CP1252', 'UTF-16'}

--- Opens files for editing.
-- @param[opt] filenames String filename or table of filenames to open. If `nil`,
--	the user is prompted to open one or more.
-- @see _G._CHARSET
-- @see events.FILE_OPENED
function io.open_file(filenames)
	if not assert_type(filenames, 'string/table/nil', 1) then
		filenames = ui.dialogs.open{
			title = _L['Open File'], multiple = true,
			dir = (buffer.filename or ''):match('^(.+)[/\\]') or lfs.currentdir()
		}
		if not filenames then return end
	end
	if type(filenames) == 'string' then filenames = {filenames} end

	for _, filename in ipairs(filenames) do
		filename = lfs.abspath((filename:gsub('^file://', '')))
		for _, buffer in ipairs(_BUFFERS) do
			if filename == buffer.filename then
				view:goto_buffer(buffer)
				goto next_filename
			end
		end

		local buffer = buffer.new()

		if lfs.attributes(filename) then
			local f<close>, errmsg = io.open(filename, 'rb')
			if not f then error(string.format('cannot open %s', errmsg), 2) end
			local text = f:read('a')

			-- Try to detect character encoding and convert to UTF-8.
			-- A nil encoding means the file is treated as a binary file.
			local encoding, has_zeroes = nil, text:find('\0')
			for _, enc in ipairs(io.encodings) do
				if has_zeroes and not enc:find('^UTF') then goto continue end -- non-UTF cannot handle \0
				local ok, conv = pcall(string.iconv, text, 'UTF-8', enc)
				if not ok then goto continue end
				encoding, text = enc, conv
				break
				::continue::
			end
			buffer.encoding, buffer.code_page = encoding, encoding and buffer.CP_UTF8 or 0

			-- Detect indentation.
			if io.detect_indentation then
				if text:find('\n\t+%S') then
					buffer.use_tabs = true
				else
					local s, e = text:find('\n()   ? ? ? ? ? ?()%S')
					if s and e then buffer.use_tabs, buffer.tab_width = false, e - 1 - s end
				end
			end

			-- Detect EOL mode.
			local s, e = text:find('\r?\n')
			if s then buffer.eol_mode = s ~= e and buffer.EOL_CRLF or buffer.EOL_LF end

			-- Insert buffer text.
			buffer:append_text(text)
		end

		-- Set properties.
		view.first_visible_line, view.x_offset = 1, 0 -- reset view scroll
		buffer:empty_undo_buffer()
		buffer.mod_time = lfs.attributes(filename, 'modification') or os.time()
		buffer.filename = filename
		buffer:set_save_point()
		buffer:set_lexer() -- auto-detect
		events.emit(events.FILE_OPENED, filename)

		-- Add file to recent files list, eliminating duplicates.
		table.insert(io.recent_files, 1, filename)
		for i = 2, #io.recent_files do
			if io.recent_files[i] == filename then
				table.remove(io.recent_files, i)
				break
			end
		end
		::next_filename::
	end
end
events.connect(events.APPLEEVENT_ODOC, io.open_file)

-- Documentation is in core/buffer.lua.
local function reload(buffer)
	if not buffer then buffer = _G.buffer end
	if not buffer.filename then return end
	local f<close> = assert(io.open(buffer.filename, 'rb'))
	local text = f:read('a')
	if buffer.encoding then text = text:iconv('UTF-8', buffer.encoding) end
	buffer:target_whole_document()
	buffer:replace_target_minimal(text)
	buffer:set_save_point()
	buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
end

-- Documentation is in core/buffer.lua.
local function set_encoding(buffer, encoding)
	assert_type(encoding, 'string/nil', 1)
	local pos, first_visible_line = buffer.current_pos, view.first_visible_line
	local text, changed = buffer:get_text(), false
	if buffer.encoding then
		text = text:iconv(buffer.encoding, 'UTF-8')
		-- Some single-byte to multi-byte transforms need an extra conversion step
		-- (e.g. CP1252 to UTF-16), but other single-byte to single-byte transforms do
		-- not (e.g. CP1252 to CP936).
		if encoding then
			local ok, conv = pcall(string.iconv, text, encoding, buffer.encoding)
			if ok then text, changed = conv, true end
		end
	end
	if encoding then text = text:iconv('UTF-8', encoding) end
	buffer:target_whole_document()
	buffer:replace_target(text) -- replace_target_minimal will likely not detect changes
	buffer:goto_pos(pos)
	view.first_visible_line = first_visible_line
	buffer.encoding, buffer.code_page = encoding, encoding and buffer.CP_UTF8 or 0
	if not changed then buffer:set_save_point() end
end

-- Documentation is in core/buffer.lua.
local function save(buffer, no_emit)
	if not buffer then buffer = _G.buffer end
	if not buffer.filename then return buffer:save_as() end
	events.emit(events.FILE_BEFORE_SAVE, buffer.filename)
	if io.ensure_final_newline and buffer.encoding and buffer.char_at[buffer.length] ~= 10 then
		buffer:append_text(buffer.eol_mode == buffer.EOL_LF and '\n' or '\r\n')
	end
	local text = buffer:get_text()
	if buffer.encoding then text = text:iconv(buffer.encoding, 'UTF-8') end
	assert(io.open(buffer.filename, 'wb')):write(text):close()
	buffer:set_save_point()
	if buffer ~= _G.buffer then events.emit(events.SAVE_POINT_REACHED, buffer) end -- update tab label
	buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
	if buffer._type then buffer._type = nil end
	if not no_emit then events.emit(events.FILE_AFTER_SAVE, buffer.filename) end
	return true
end

-- Documentation is in core/buffer.lua.
local function save_as(buffer, filename)
	if not buffer then buffer = _G.buffer end
	if not assert_type(filename, 'string/nil', 1) then
		local dir, name = (buffer.filename or lfs.currentdir() .. '/'):match('^(.-)[/\\]?([^/\\]*)$')
		filename = ui.dialogs.save{title = _L['Save File'], dir = dir, file = name}
		if not filename then return end
	end
	buffer.filename = filename
	buffer:save(true)
	buffer:set_lexer() -- auto-detect
	events.emit(events.FILE_AFTER_SAVE, filename, true)
	return true
end

--- Saves all unsaved buffers to their respective files.
-- Print and output buffers are ignored.
-- @param[opt=false] untitled Prompt the user for filenames to save untitled buffers to. If
--	the user cancels saving any untitled buffer, the remaining unsaved files stay unsaved.
-- @return `true` if all savable files were saved; `nil` otherwise.
function io.save_all_files(untitled)
	for _, buffer in ipairs(_BUFFERS) do
		if buffer.modify and (buffer.filename or untitled and not buffer._type) then
			if not buffer.filename then view:goto_buffer(buffer) end
			if not buffer:save() then return end
		end
	end
	return true
end

-- Documentation is in core/buffer.lua.
local function close(buffer, force)
	if not buffer then buffer = _G.buffer end
	if buffer.modify and not force then
		local filename = buffer.filename and buffer.filename:iconv('UTF-8', _CHARSET) or buffer._type or
			_L['Untitled']
		local button = ui.dialogs.message{
			title = _L['Close without saving?'],
			text = string.format('%s\n%s', _L['There are unsaved changes in'], filename),
			icon = 'dialog-question', button1 = _L['Save'], button2 = _L['Cancel'],
			button3 = _L['Close without saving']
		}
		if button == 1 then return buffer:save() end
		if button ~= 3 then return nil end -- do not propagate key command
	end
	buffer:delete()
	return true
end

--- Detects if the current file has been externally modified and, if so, emits
-- `events.FILE_CHANGED`.
local function update_modified_file()
	if not buffer.filename then return end
	local mod_time = lfs.attributes(buffer.filename, 'modification')
	if mod_time and buffer.mod_time and buffer.mod_time < mod_time then
		buffer.mod_time = mod_time
		events.emit(events.FILE_CHANGED, buffer.filename)
	end
end
events.connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
events.connect(events.VIEW_AFTER_SWITCH, update_modified_file)
events.connect(events.FOCUS, update_modified_file)
events.connect(events.RESUME, update_modified_file)

-- Prompts the user to reload the current file if it has been externally modified.
events.connect(events.FILE_CHANGED, function(filename)
	local button = ui.dialogs.message{
		title = _L['Reload modified file?'],
		text = string.format('"%s"\n%s', filename:iconv('UTF-8', _CHARSET),
			_L['has been modified. Reload it?']), icon = 'dialog-question', button1 = _L['Yes'],
		button2 = _L['No']
	}
	if button == 1 then buffer:reload() end
end)

-- Enables or disables showing change history for the current buffer.
local function set_change_history()
	view.change_history = (io.track_changes and buffer.filename and view.CHANGE_HISTORY_ENABLED or
		view.CHANGE_HISTORY_DISABLED) | view.CHANGE_HISTORY_MARKERS |
		(not CURSES and view.CHANGE_HISTORY_INDICATORS or 0)
end
events.connect(events.FILE_OPENED, set_change_history)
events.connect(events.BUFFER_AFTER_SWITCH, set_change_history)
events.connect(events.VIEW_AFTER_SWITCH, set_change_history)
events.connect(events.BUFFER_NEW, set_change_history)
events.connect(events.VIEW_NEW, set_change_history)

--- Helper function for closing all buffers, but returns true if the user cancels the operation.
local function close_all() for _ = 1, #_BUFFERS do if not buffer:close() then return true end end end

--- Closes all open buffers.
-- If there are any unsaved buffers, the user is prompted to confirm closing without saving
-- for each one. If the user does not confirm, the remaining open buffers stay open.
--
-- Buffers are not saved automatically. They must be saved manually.
-- @return `true` if user did not cancel, and all buffers were closed; `nil` otherwise.
function io.close_all_buffers()
	events.disconnect(events.BUFFER_AFTER_SWITCH, update_modified_file)
	local canceled = close_all()
	events.connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
	if not canceled then return true end
end

-- Sets buffer io methods and the default buffer encoding.
local function setup_buffer_io()
	buffer.reload, buffer.save, buffer.save_as, buffer.close = reload, save, save_as, close
	buffer.set_encoding, buffer.encoding = set_encoding, 'UTF-8'
end
events.connect('pre_init', setup_buffer_io) -- for the first buffer, which does not exist yet
events.connect(events.BUFFER_NEW, setup_buffer_io)

-- Closes the initial "Untitled" buffer when another buffer is opened.
events.connect(events.FILE_OPENED, function()
	if #_BUFFERS > 2 then return end
	local buffer = _BUFFERS[1]
	if buffer.filename or buffer._type or buffer.modify or buffer.length > 0 then return end
	buffer:close()
end)

--- Prompts the user to select a recently opened file to reopen.
-- @see recent_files
function io.open_recent_file()
	for i = #io.recent_files, 1, -1 do
		if not lfs.attributes(io.recent_files[i]) then table.remove(io.recent_files, i) end
	end
	if #io.recent_files == 0 then return end
	local utf8_list = table.map(io.recent_files, string.iconv, 'UTF-8', _CHARSET)
	local selected, button = ui.dialogs.list{
		title = _L['Open File'], items = utf8_list, multiple = true, button3 = _L['Clear List'],
		return_button = true
	}
	if button == 3 then io.recent_files = {} end
	if not selected or button ~= 1 then return end
	for _, i in ipairs(selected) do io.open_file(io.recent_files[i]) end
end

--- Map of version control files to their lfs modes.
local vcs = {
	['.bzr'] = 'directory', ['.git'] = 'directory', ['.hg'] = 'directory', ['.svn'] = 'directory',
	['.fslckout'] = 'file', _FOSSIL_ = 'file'
}

--- Returns a project's root directory.
-- Textadept only recognizes projects under one of the following version control systems: Git,
-- Mercurial, SVN, Bazaar, and Fossil.
-- @param[opt] path String path to a project, or the path to a file that belongs to a project. The
--	default value is either the buffer's filename (if available) or the current working directory.
-- @param[opt=false] submodule Return the root of the current submodule instead of the repository
--	root (if applicable).
-- @return string root, or `nil` if no project was found
function io.get_project_root(path, submodule)
	if type(path) == 'boolean' then path, submodule = nil, path end
	if not assert_type(path, 'string/nil', 1) then path = buffer.filename or lfs.currentdir() end
	local dir = path:match('^(.-)[/\\]?$')
	while dir do
		for file, expected_mode in pairs(vcs) do
			local mode = lfs.attributes(dir .. '/' .. file, 'mode')
			if mode and (submodule or mode == expected_mode) then return dir end
		end
		dir = dir:match('^(.+)[/\\]')
	end
	return nil
end

--- Map of directory paths to filters used by `io.quick_open()`.
io.quick_open_filters = {}

--- Prompts the user to select a file to open from a list of files read from a directory.
-- The number of files shown in the list is capped at `io.quick_open_max`.
-- @param[opt] paths String directory path or table of directory paths to search for files
--	in. The default value is the current project's root directory.
-- @param[optchain] filter [Filter](#filters) that specifies the files and directories the
--	iterator should yield. It is a shell-style glob string or table of such glob strings. The
--	default value is `io.quick_open_filters[paths]` if it exists, or `lfs.default_filter`
--	otherwise. Any non-`lfs.default_filter` filter will be combined with `lfs.default_filter`.
-- @usage io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list files in the buffer's directory
-- @usage io.quick_open(io.get_project_root(), '**/*.{lua,c}') -- list Lua and C project files
-- @usage io.quick_open(io.get_project_root(), '!build') -- list non-build project files
function io.quick_open(paths, filter)
	if not assert_type(paths, 'string/table/nil', 1) then
		paths = io.get_project_root()
		if not paths then return end
	end
	if not assert_type(filter, 'string/table/nil', 2) then filter = io.quick_open_filters[paths] end
	if type(paths) == 'string' then paths = {paths} end

	local utf8_list = {}
	local prefix = #paths == 1 and paths[1] .. (not WIN32 and '/' or '\\')
	for _, path in ipairs(paths) do
		for filename in lfs.walk(path, filter) do
			if #utf8_list >= io.quick_open_max then break end
			if prefix then filename = filename:sub(#prefix + 1) end
			utf8_list[#utf8_list + 1] = filename:iconv('UTF-8', _CHARSET)
		end
	end
	if #utf8_list == 0 then return end
	if #utf8_list >= io.quick_open_max then
		ui.dialogs.message{
			title = _L['File Limit Exceeded'], text = string.format('%d %s %d', io.quick_open_max,
				_L['files or more were found. Showing the first'], io.quick_open_max),
			icon = 'dialog-information'
		}
	end

	local title = _L['Open File']
	if prefix then title = title .. ': ' .. prefix:iconv('UTF-8', _CHARSET) end
	local selected = ui.dialogs.list{title = title, items = utf8_list, multiple = true}
	if not selected then return end

	io.open_file(table.map(selected, function(i)
		local filename = utf8_list[i]:iconv(_CHARSET, 'UTF-8')
		return prefix and prefix .. filename or filename
	end))
end

args.register('-', '-', 0, function()
	if buffer.filename or buffer._type then buffer.new() end
	buffer:append_text(io.read('a'))
	buffer:set_save_point()
	return true -- this counts as a "file"
end, 'Read stdin into a new buffer')

-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Extends Lua's `io` library with Textadept functions for working with files.
-- @module io

-- Events.
local file_io_events = {'file_opened', 'file_before_save', 'file_after_save', 'file_changed'}
for _, v in ipairs(file_io_events) do events[v:upper()] = v end

--- Emitted after opening a file in a new buffer.
-- Emitted by `io.open_file()`.
-- Arguments:
--
-- - *filename*: The opened file's filename.
-- @field _G.events.FILE_OPENED

--- Emitted right before saving a file to disk.
-- Emitted by `buffer:save()`.
-- Arguments:
--
-- - *filename*: The filename of the file being saved.
-- @field _G.events.FILE_BEFORE_SAVE

--- Emitted right after saving a file to disk.
-- Emitted by `buffer:save()` and `buffer:save_as()`.
-- Arguments:
--
-- - *filename*: The filename of the file being saved.
-- - *saved_as*: Whether or not the file was saved under a different filename.
-- @field _G.events.FILE_AFTER_SAVE

--- Emitted when Textadept detects that an open file was modified externally.
-- When connecting to this event, connect with an index of 1 in order to override the default
-- prompt to reload the file.
-- Arguments:
--
-- - *filename*: The filename externally modified.
-- @field _G.events.FILE_CHANGED

--- Whether or not to ensure there is a final newline when saving text files.
-- This has no effect on binary files.
-- The default value is `false` on Windows, and `true` on Linux and macOS.
io.ensure_final_newline = not WIN32

--- The maximum number of files listed in the quick open dialog.
-- The default value is `5000`.
io.quick_open_max = 5000

--- List of recently opened files, the most recent being towards the top.
io.recent_files = {}

--- List of encodings to attempt to decode files as.
-- The default list contains UTF-8, ASCII, CP1252, and UTF-16.
--
-- You should add to this list if you get a "Conversion failed" error when trying to open a file
-- whose encoding is not recognized. Valid encodings are [GNU iconv's encodings][] and include:
--
-- - European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
--	KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
--	Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
--	Macintosh.
-- - Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
--	UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.
--
-- [GNU iconv's encodings]: https://www.gnu.org/software/libiconv/
-- @usage io.encodings[#io.encodings + 1] = 'UTF-32'
-- @table encodings

-- This comment is needed to prevent LDoc from parsing the following table.

io.encodings = {'UTF-8', 'ASCII', 'CP1252', 'UTF-16'}

--- Opens *filenames*, a string filename or list of filenames, or the user-selected filename(s).
-- Emits `events.FILE_OPENED`.
-- @param[opt] filenames Optional string filename or table of filenames to open. If `nil`,
--	the user is prompted with a fileselect dialog.
-- @param[optchain] encodings Optional string encoding or table of encodings file contents are in
--	(one encoding per file). If `nil`, encoding auto-detection is attempted via `io.encodings`.
function io.open_file(filenames, encodings)
	assert_type(encodings, 'string/table/nil', 2)
	if not assert_type(filenames, 'string/table/nil', 1) then
		filenames = ui.dialogs.open{
			title = _L['Open File'], multiple = true,
			dir = (buffer.filename or ''):match('^.+[/\\]') or lfs.currentdir()
		}
		if not filenames then return end
	end
	if type(filenames) == 'string' then filenames = {filenames} end
	if type(encodings) ~= 'table' then encodings = {encodings} end
	for i = 1, #filenames do
		local filename = lfs.abspath((filenames[i]:gsub('^file://', '')))
		for _, buffer in ipairs(_BUFFERS) do
			if filename == buffer.filename then
				view:goto_buffer(buffer)
				goto continue
			end
		end

		local text = ''
		if lfs.attributes(filename) then
			local f, errmsg = io.open(filename, 'rb')
			if not f then error(string.format('cannot open %s', errmsg), 2) end
			text = f:read('a')
			f:close()
			if not text then goto continue end -- filename exists, but cannot read it
		end
		local buffer = buffer.new()
		if encodings[i] then
			buffer.encoding, text = encodings[i], text:iconv('UTF-8', encodings[i])
		else
			-- Try to detect character encoding and convert to UTF-8.
			local has_zeroes = text:sub(1, 65535):find('\0')
			for _, encoding in ipairs(io.encodings) do
				if not has_zeroes or encoding:find('^UTF') then
					local ok, conv = pcall(string.iconv, text, 'UTF-8', encoding)
					if ok then
						buffer.encoding, text = encoding, conv
						goto encoding_detected
					end
				end
			end
			assert(has_zeroes, _L['Encoding conversion failed.'])
			buffer.encoding = nil -- binary (default was 'UTF-8')
		end
		::encoding_detected::
		buffer.code_page = buffer.encoding and buffer.CP_UTF8 or 0
		-- Detect EOL mode.
		local s, e = text:find('\r?\n')
		if s then buffer.eol_mode = buffer[s ~= e and 'EOL_CRLF' or 'EOL_LF'] end
		-- Insert buffer text and set properties.
		buffer:append_text(text)
		view.first_visible_line, view.x_offset = 1, 0 -- reset view scroll
		buffer:empty_undo_buffer()
		buffer.mod_time = lfs.attributes(filename, 'modification') or os.time()
		buffer.filename = filename
		buffer:set_save_point()
		buffer:set_lexer() -- auto-detect
		events.emit(events.FILE_OPENED, filename)

		-- Add file to recent files list, eliminating duplicates.
		table.insert(io.recent_files, 1, filename)
		for j = 2, #io.recent_files do
			if io.recent_files[j] == filename then
				table.remove(io.recent_files, j)
				break
			end
		end
		::continue::
	end
end

-- LuaDoc is in core/.buffer.luadoc.
local function reload(buffer)
	if not buffer then buffer = _G.buffer end
	if not buffer.filename then return end
	local f = assert(io.open(buffer.filename, 'rb'))
	local text = f:read('a')
	f:close()
	if buffer.encoding then text = text:iconv('UTF-8', buffer.encoding) end
	buffer:target_whole_document()
	buffer:replace_target(text)
	buffer:set_save_point()
	buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
end

-- LuaDoc is in core/.buffer.luadoc.
local function set_encoding(buffer, encoding)
	assert_type(encoding, 'string/nil', 1)
	local pos, first_visible_line = buffer.current_pos, view.first_visible_line
	local text = buffer:get_text()
	if buffer.encoding then
		text = text:iconv(buffer.encoding, 'UTF-8')
		if encoding then text = text:iconv(encoding, buffer.encoding) end
	end
	if encoding then text = text:iconv('UTF-8', encoding) end
	buffer:target_whole_document()
	buffer:replace_target(text)
	buffer:goto_pos(pos)
	view.first_visible_line = first_visible_line
	buffer.encoding = encoding
	buffer.code_page = buffer.encoding and buffer.CP_UTF8 or 0
end

-- LuaDoc is in core/.buffer.luadoc.
local function save(buffer)
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
	events.emit(events.FILE_AFTER_SAVE, buffer.filename)
	return true
end

-- LuaDoc is in core/.buffer.luadoc.
local function save_as(buffer, filename)
	if not buffer then buffer = _G.buffer end
	local dir, name = (buffer.filename or lfs.currentdir() .. '/'):match('^(.-[/\\]?)([^/\\]*)$')
	if not assert_type(filename, 'string/nil', 1) then
		filename = ui.dialogs.save{title = _L['Save File'], dir = dir, file = name}
		if not filename then return end
	end
	buffer.filename = filename
	buffer:save()
	buffer:set_lexer() -- auto-detect
	events.emit(events.FILE_AFTER_SAVE, filename, true)
	return true
end

--- Saves all unsaved buffers to their respective files, prompting the user for filenames for
-- untitled buffers if *untitled* is `true`, and returns `true` on success.
-- Print and output buffers are ignored.
-- @param untitled Whether or not to prompt for filenames for untitled buffers. The default
--	value is `false`.
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

-- LuaDoc is in core/.buffer.luadoc.
local function close(buffer, force)
	if not buffer then buffer = _G.buffer end
	if buffer.modify and not force then
		local filename = buffer.filename or buffer._type or _L['Untitled']
		if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
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

--- Closes all open buffers, prompting the user to continue if there are unsaved buffers, and
-- returns `true` if the user did not cancel.
-- No buffers are saved automatically. They must be saved manually.
-- @return `true` if user did not cancel; `nil` otherwise.
function io.close_all_buffers()
	events.disconnect(events.BUFFER_AFTER_SWITCH, update_modified_file)
	while #_BUFFERS > 1 do if not buffer:close() then return nil end end
	events.connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
	return buffer:close() -- the last one
end

-- Sets buffer io methods and the default buffer encoding.
events.connect(events.BUFFER_NEW, function()
	buffer.reload = reload
	buffer.set_encoding, buffer.encoding = set_encoding, 'UTF-8'
	buffer.save, buffer.save_as, buffer.close = save, save_as, close
end)
-- Export for later storage into the first buffer, which does not exist yet.
-- Cannot rely on `events.BUFFER_NEW` because init scripts (e.g. menus and key bindings) can
-- access buffer functions before the first `events.BUFFER_NEW` is emitted.
io._reload, io._save, io._save_as, io._close = reload, save, save_as, close

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

-- Closes the initial "Untitled" buffer when another buffer is opened.
events.connect(events.FILE_OPENED, function()
	if #_BUFFERS > 2 then return end
	local buf = _BUFFERS[1]
	if not (buf.filename or buf._type or buf.modify or buf.length > 0) then buf:close() end
end)

--- Prompts the user to select a recently opened file to be reopened.
-- @see recent_files
function io.open_recent_file()
	if #io.recent_files == 0 then return end
	local utf8_list, i = {}, 1
	while i <= #io.recent_files do
		local filename = io.recent_files[i]
		if lfs.attributes(filename) then
			utf8_list[#utf8_list + 1] = io.recent_files[i]:iconv('UTF-8', _CHARSET)
			i = i + 1
		else
			table.remove(io.recent_files, i)
		end
	end
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
	_FOSSIL_ = 'file'
}

--- Returns the root directory of the project that contains filesystem path *path*.
-- In order to be recognized, projects must be under version control. Recognized VCSes are
-- Bazaar, Fossil, Git, Mercurial, and SVN.
-- @param[opt] path Optional filesystem path to a project or a file contained within a project. The
--	default value is the buffer's filename or the current working directory.
-- @param[opt=false] submodule Optional flag that indicates whether or not to return the root
--	of the current submodule (if applicable).
-- @return string root or nil
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

--- Prompts the user to select files to be opened from *paths*, a string directory path or list
-- of directory paths, using a list dialog.
-- If *paths* is `nil`, uses the current project's root directory, which is obtained from
-- `io.get_project_root()`.
-- String or list *filter* determines which files to show in the dialog, with the default filter
-- being `io.quick_open_filters[path]` (if it exists) or `lfs.default_filter`. A filter consists
-- of glob patterns that match file and directory paths to include or exclude. Patterns are
-- inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are given,
-- any path is initially considered. As a convenience, '/' also matches the Windows directory
-- separator ('[/\\]' is not needed).
-- The number of files in the list is capped at `io.quick_open_max`.
-- If *filter* is `nil` and *paths* is ultimately a string, the filter from the
-- `io.quick_open_filters` table is used. If that filter does not exist, `lfs.default_filter`
-- is used.
-- @param[opt] paths Optional string directory path or table of directory paths to search. The
--	default value is the current project's root directory, if available.
-- @param[optchain] filter Optional filter for files and directories to include and/or
--	exclude. The default value is `lfs.default_filter` unless a filter for *paths* is
--	defined in `io.quick_open_filters`.
-- @usage io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list all files in the current
--	file's directory, subject to the default filter
-- @usage io.quick_open(io.get_current_project(), '.lua') -- list all Lua files in the current
--	project
-- @usage io.quick_open(io.get_current_project(), '!/build') -- list all files in the current
--	project except those in the build directory
function io.quick_open(paths, filter)
	if not assert_type(paths, 'string/table/nil', 1) then
		paths = io.get_project_root()
		if not paths then return end
	end
	if not assert_type(filter, 'string/table/nil', 2) then
		filter = io.quick_open_filters[paths] or lfs.default_filter
	end
	local utf8_list = {}
	paths = type(paths) == 'table' and paths or {paths}
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
	local filenames = {}
	for i = 1, #selected do
		local filename = utf8_list[selected[i]]:iconv(_CHARSET, 'UTF-8')
		if prefix then filename = prefix .. filename end
		filenames[i] = filename
	end
	io.open_file(filenames)
end

args.register('-', '-', 0, function()
	if buffer.filename or buffer._type then buffer.new() end
	buffer:append_text(io.read('a'))
	buffer:set_save_point()
	return true -- this counts as a "file"
end, 'Read stdin into a new buffer')

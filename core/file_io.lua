-- Copyright 2007-2022 Mitchell. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- Extends Lua's `io` library with Textadept functions for working with files.
-- @field _G.events.FILE_OPENED (string)
--   Emitted after opening a file in a new buffer.
--   Emitted by [`io.open_file()`]().
--   Arguments:
--
--   * _`filename`_: The opened file's filename.
-- @field _G.events.FILE_BEFORE_SAVE (string)
--   Emitted right before saving a file to disk.
--   Emitted by [`buffer:save()`]().
--   Arguments:
--
--   * _`filename`_: The filename of the file being saved.
-- @field _G.events.FILE_AFTER_SAVE (string)
--   Emitted right after saving a file to disk.
--   Emitted by [`buffer:save()`]() and [`buffer:save_as()`]().
--   Arguments:
--
--   * _`filename`_: The filename of the file being saved.
--   * _`saved_as`_: Whether or not the file was saved under a different filename.
-- @field _G.events.FILE_CHANGED (string)
--   Emitted when Textadept detects that an open file was modified externally.
--   When connecting to this event, connect with an index of 1 in order to override the default
--   prompt to reload the file.
--   Arguments:
--
--   * _`filename`_: The filename externally modified.
-- @field quick_open_max (number)
--   The maximum number of files listed in the quick open dialog.
--   The default value is `1000`.
module('io')]]

-- Events.
-- LuaFormatter off
local file_io_events = {'file_opened','file_before_save','file_after_save','file_changed'}
-- LuaFormatter on
for _, v in ipairs(file_io_events) do events[v:upper()] = v end

io.quick_open_max = 1000

---
-- List of recently opened files, the most recent being towards the top.
-- @class table
-- @name recent_files
io.recent_files = {}

---
-- List of encodings to attempt to decode files as.
-- You should add to this list if you get a "Conversion failed" error when trying to open a file
-- whose encoding is not recognized. Valid encodings are [GNU iconv's encodings][] and include:
--
--   * European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
--     KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
--     Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
--     Macintosh.
--   * Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
--     UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.
--
-- [GNU iconv's encodings]: https://www.gnu.org/software/libiconv/
-- @usage io.encodings[#io.encodings + 1] = 'UTF-32'
-- @class table
-- @name encodings
io.encodings = {'UTF-8', 'ASCII', 'CP1252', 'UTF-16'}

---
-- Opens *filenames*, a string filename or list of filenames, or the user-selected filename(s).
-- Emits a `FILE_OPENED` event.
-- @param filenames Optional string filename or table of filenames to open. If `nil`, the user
--   is prompted with a fileselect dialog.
-- @param encodings Optional string encoding or table of encodings file contents are in (one
--   encoding per file). If `nil`, encoding auto-detection is attempted via `io.encodings`.
-- @see _G.events
-- @name open_file
function io.open_file(filenames, encodings)
  assert_type(encodings, 'string/table/nil', 2)
  if not assert_type(filenames, 'string/table/nil', 1) then
    filenames = ui.dialogs.fileselect{
      title = _L['Open File'], select_multiple = true,
      with_directory = (buffer.filename or ''):match('^.+[/\\]') or lfs.currentdir(),
      width = CURSES and ui.size[1] - 2 or nil
    }
    if not filenames then return end
  end
  if type(filenames) == 'string' then filenames = {filenames} end
  if type(encodings) ~= 'table' then encodings = {encodings} end
  for i = 1, #filenames do
    local filename = lfs.abspath((filenames[i]:gsub('^file://', '')))
    for _, buf in ipairs(_BUFFERS) do
      if filename == buf.filename then
        view:goto_buffer(buf)
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
        if not has_zeroes or encoding:find('^UTF%-[13][62]') then
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
  buffer:set_text(text)
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
  buffer:set_text(text)
  buffer:goto_pos(pos)
  view.first_visible_line = first_visible_line
  buffer.encoding = encoding
  buffer.code_page = buffer.encoding and buffer.CP_UTF8 or 0
end

-- LuaDoc is in core/.buffer.luadoc.
local function save(buffer)
  if not buffer then buffer = _G.buffer end
  if not buffer.filename then
    buffer:save_as()
    return
  end
  events.emit(events.FILE_BEFORE_SAVE, buffer.filename)
  local text = buffer:get_text()
  if buffer.encoding then text = text:iconv(buffer.encoding, 'UTF-8') end
  assert(io.open(buffer.filename, 'wb')):write(text):close()
  buffer:set_save_point()
  buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
  if buffer._type then buffer._type = nil end
  events.emit(events.FILE_AFTER_SAVE, buffer.filename)
end

-- LuaDoc is in core/.buffer.luadoc.
local function save_as(buffer, filename)
  if not buffer then buffer = _G.buffer end
  local dir, name = (buffer.filename or ''):match('^(.-[/\\]?)([^/\\]*)$')
  if not assert_type(filename, 'string/nil', 1) then
    filename = ui.dialogs.filesave{
      title = _L['Save File'], with_directory = dir, with_file = name,
      width = CURSES and ui.size[1] - 2 or nil
    }
    if not filename then return end
  end
  buffer.filename = filename
  buffer:save()
  buffer:set_lexer() -- auto-detect
  events.emit(events.FILE_AFTER_SAVE, filename, true)
end

---
-- Saves all unsaved buffers to their respective files.
-- @see buffer.save
-- @name save_all_files
function io.save_all_files()
  for _, buffer in ipairs(_BUFFERS) do if buffer.filename and buffer.modify then buffer:save() end end
end

-- LuaDoc is in core/.buffer.luadoc.
local function close(buffer, force)
  if not buffer then buffer = _G.buffer end
  if buffer.modify and not force then
    local filename = buffer.filename or buffer._type or _L['Untitled']
    if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
    local button = ui.dialogs.msgbox{
      title = _L['Close without saving?'], text = _L['There are unsaved changes in'],
      informative_text = filename, icon = 'dialog-question', button1 = _L['Cancel'],
      button2 = _L['Close without saving'],
      width = CURSES and #filename > 40 and ui.size[1] - 2 or nil
    }
    if button ~= 2 then return nil end -- do not propagate key command
  end
  buffer:delete()
  return true
end

-- Detects if the current file has been externally modified and, if so, emits a `FILE_CHANGED`
-- event.
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

---
-- Closes all open buffers, prompting the user to continue if there are unsaved buffers, and
-- returns `true` if the user did not cancel.
-- No buffers are saved automatically. They must be saved manually.
-- @return `true` if user did not cancel; `nil` otherwise.
-- @see buffer.close
-- @name close_all_buffers
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
  local button = ui.dialogs.msgbox{
    title = _L['Reload?'], text = _L['Reload modified file?'],
    informative_text = string.format('"%s"\n%s', filename:iconv('UTF-8', _CHARSET),
      _L['has been modified. Reload it?']), -- LuaFormatter
    icon = 'dialog-question', button1 = _L['Yes'], button2 = _L['No'],
    width = CURSES and #filename > 40 and ui.size[1] - 2 or nil
  }
  if button == 1 then buffer:reload() end
end)

-- Closes the initial "Untitled" buffer when another buffer is opened.
events.connect(events.FILE_OPENED, function()
  if #_BUFFERS > 2 then return end
  local buf = _BUFFERS[1]
  if not (buf.filename or buf._type or buf.modify) then buf:close() end
end)

---
-- Prompts the user to select a recently opened file to be reopened.
-- @see recent_files
-- @name open_recent_file
function io.open_recent_file()
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
  local button
  button, i = ui.dialogs.filteredlist{
    title = _L['Open File'], columns = _L['Filename'], items = utf8_list
  }
  if button == 1 and i then io.open_file(io.recent_files[i]) end
end

-- List of version control directories.
local vcs = {'.bzr', '.git', '.hg', '.svn', '_FOSSIL_'}

---
-- Returns the root directory of the project that contains filesystem path *path*.
-- In order to be recognized, projects must be under version control. Recognized VCSes are
-- Bazaar, Fossil, Git, Mercurial, and SVN.
-- @param path Optional filesystem path to a project or a file contained within a project. The
--   default value is the buffer's filename or the current working directory. This parameter
--   may be omitted.
-- @param submodule Optional flag that indicates whether or not to return the root of the
--   current submodule (if applicable). The default value is `false`.
-- @return string root or nil
-- @name get_project_root
function io.get_project_root(path, submodule)
  if type(path) == 'boolean' then path, submodule = nil, path end
  if not assert_type(path, 'string/nil', 1) then path = buffer.filename or lfs.currentdir() end
  local dir = path:match('^(.+)[/\\]?')
  while dir do
    for i = 1, #vcs do
      local mode = lfs.attributes(dir .. '/' .. vcs[i], 'mode')
      if mode and (submodule or mode == 'directory') then return dir end
    end
    dir = dir:match('^(.+)[/\\]')
  end
  return nil
end

---
-- Map of directory paths to filters used by `io.quick_open()`.
-- @class table
-- @name quick_open_filters
-- @see quick_open
io.quick_open_filters = {}

---
-- Prompts the user to select files to be opened from *paths*, a string directory path or list
-- of directory paths, using a filtered list dialog.
-- If *paths* is `nil`, uses the current project's root directory, which is obtained from
-- `io.get_project_root()`.
-- String or list *filter* determines which files to show in the dialog, with the default
-- filter being `io.quick_open_filters[path]` (if it exists) or `lfs.default_filter`. A filter
-- consists of Lua patterns that match file and directory paths to include or exclude. Patterns
-- are inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are
-- given, any path is initially considered. As a convenience, file extensions can be specified
-- literally instead of as a Lua pattern (e.g. '.lua' vs. '%.lua$'), and '/' also matches the
-- Windows directory separator ('[/\\]' is not needed).
-- The number of files in the list is capped at `quick_open_max`.
-- If *filter* is `nil` and *paths* is ultimately a string, the filter from the
-- `io.quick_open_filters` table is used. If that filter does not exist, `lfs.default_filter`
-- is used.
-- *opts* is an optional table of additional options for `ui.dialogs.filteredlist()`.
-- @param paths Optional string directory path or table of directory paths to search. The
--   default value is the current project's root directory, if available.
-- @param filter Optional filter for files and directories to include and/or exclude. The
--   default value is `lfs.default_filter` unless a filter for *paths* is defined in
--   `io.quick_open_filters`.
-- @param opts Optional table of additional options for `ui.dialogs.filteredlist()`.
-- @usage io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list all files in the current
--   file's directory, subject to the default filter
-- @usage io.quick_open(io.get_current_project(), '.lua') -- list all Lua files in the current
--   project
-- @usage io.quick_open(io.get_current_project(), '!/build') -- list all files in the current
--   project except those in the build directory
-- @see io.quick_open_filters
-- @see lfs.default_filter
-- @see quick_open_max
-- @see ui.dialogs.filteredlist
-- @name quick_open
function io.quick_open(paths, filter, opts)
  if not assert_type(paths, 'string/table/nil', 1) then
    paths = io.get_project_root()
    if not paths then return end
  end
  if not assert_type(filter, 'string/table/nil', 2) then
    filter = io.quick_open_filters[paths] or lfs.default_filter
  end
  assert_type(opts, 'table/nil', 3)
  local utf8_list = {}
  for _, path in ipairs(type(paths) == 'table' and paths or {paths}) do
    for filename in lfs.walk(path, filter) do
      if #utf8_list >= io.quick_open_max then break end
      utf8_list[#utf8_list + 1] = filename:iconv('UTF-8', _CHARSET)
    end
  end
  if #utf8_list >= io.quick_open_max then
    ui.dialogs.msgbox{
      title = _L['File Limit Exceeded'], text = string.format('%d %s %d', io.quick_open_max,
        _L['files or more were found. Showing the first'], io.quick_open_max),
      icon = 'dialog-information'
    }
  end
  local options = {
    title = _L['Open File'], columns = _L['Filename'], items = utf8_list, button1 = _L['OK'],
    button2 = _L['Cancel'], select_multiple = true, string_output = true,
    width = CURSES and ui.size[1] - 2 or nil
  }
  if opts then for k, v in pairs(opts) do options[k] = v end end
  local button, utf8_filenames = ui.dialogs.filteredlist(options)
  if button ~= _L['OK'] or not utf8_filenames then return end
  local filenames = {}
  for i = 1, #utf8_filenames do filenames[i] = utf8_filenames[i]:iconv(_CHARSET, 'UTF-8') end
  io.open_file(filenames)
end

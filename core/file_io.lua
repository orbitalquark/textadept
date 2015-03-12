-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

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
--   Emitted by [`io.save_file()`]().
--   Arguments:
--
--   * _`filename`_: The filename of the file being saved.
-- @field _G.events.FILE_AFTER_SAVE (string)
--   Emitted right after saving a file to disk.
--   Emitted by [`io.save_file()`]() and [`io.save_file_as()`]().
--   Arguments:
--
--   * _`filename`_: The filename of the file being saved.
--   * _`saved_as`_: Whether or not the file was saved under a different
--     filename.
-- @field _G.events.FILE_CHANGED (string)
--   Emitted when Textadept detects that an open file was modified externally.
--   When connecting to this event, connect with an index of 1 to override the
--   default prompt to reload the file.
--   Arguments:
--
--   * _`filename`_: The filename externally modified.
-- @field SNAPOPEN_MAX (number)
--   The maximum number of files listed in the snapopen dialog.
--   The default value is `1000`.
module('io')]]

-- Events.
local events, events_connect = events, events.connect
events.FILE_OPENED = 'file_opened'
events.FILE_BEFORE_SAVE = 'file_before_save'
events.FILE_AFTER_SAVE = 'file_after_save'
events.FILE_CHANGED = 'file_changed'

io.SNAPOPEN_MAX = 1000

---
-- List of recently opened files, the most recent being towards the top.
-- @class table
-- @name recent_files
io.recent_files = {}

---
-- List of encodings to attempt to decode files as.
-- You should add to this list if you get a "Conversion failed" error when
-- trying to open a file whose encoding is not recognized. Valid encodings are
-- [GNU iconv's encodings][] and include:
--
--   * European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R, KOI8-U,
--     KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
--     Mac{Roman,CentralEurope,Iceland,Croatian,Romania},
--     Mac{Cyrillic,Ukraine,Greek,Turkish}, Macintosh.
--   * Semitic: ISO-8859-{6,8}, CP{1255,1256}, CP862, Mac{Hebrew,Arabic}.
--   * Japanese: EUC-JP, SHIFT_JIS, CP932, ISO-2022-JP, ISO-2022-JP-2,
--     ISO-2022-JP-1.
--   * Chinese: EUC-CN, HZ, GBK, CP936, GB18030, EUC-TW, BIG5, CP950,
--     BIG5-HKSCS, BIG5-HKSCS:2004, BIG5-HKSCS:2001, BIG5-HKSCS:1999,
--     ISO-2022-CN, ISO-2022-CN-EXT.
--   * Korean: EUC-KR, CP949, ISO-2022-KR, JOHAB.
--   * Armenian: ARMSCII-8.
--   * Georgian: Georgian-Academy, Georgian-PS.
--   * Tajik: KOI8-T.
--   * Kazakh: PT154, RK1048.
--   * Thai: ISO-8859-11, TIS-620, CP874, MacThai.
--   * Laotian: MuleLao-1, CP1133.
--   * Vietnamese: VISCII, TCVN, CP1258.
--   * Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16,
--     UTF-16BE, UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.
--
-- [GNU iconv's encodings]: http://www.gnu.org/software/libiconv/
-- @usage io.encodings[#io.encodings + 1] = 'UTF-16'
-- @class table
-- @name encodings
io.encodings = {'UTF-8', 'ASCII', 'ISO-8859-1', 'MacRoman'}

local BOMs = {
  ['UTF-8'] = '\239\187\191',
  ['UTF-16BE'] = '\254\255', ['UTF-16LE'] = '\255\254',
  ['UTF-32BE'] = '\0\0\254\255', ['UTF-32LE'] = '\255\254\0\0'
}
local c = _SCINTILLA.constants
local EOLs = {['\r\n'] = c.EOL_CRLF, ['\r'] = c.EOL_CR, ['\n'] = c.EOL_LF}
---
-- Opens *filenames*, a string filename or list of filenames, or the
-- user-selected filenames.
-- Emits a `FILE_OPENED` event.
-- @param filenames Optional string filename or table of filenames to open. If
--   `nil`, the user is prompted with a fileselect dialog.
-- @see _G.events
-- @name open_file
function io.open_file(filenames)
  if type(filenames) == 'string' then filenames = {filenames} end
  filenames = filenames or ui.dialogs.fileselect{
    title = _L['Open'], select_multiple = true,
    with_directory = (buffer.filename or ''):match('^.+[/\\]') or
                     lfs.currentdir(),
    width = CURSES and ui.size[1] - 2 or nil
  }
  if not filenames then return end
  for i = 1, #filenames do
    local filename = lfs.abspath((filenames[i]:gsub('^file://', '')))
    for i, buffer in ipairs(_BUFFERS) do
      if filename == buffer.filename then view:goto_buffer(i) goto continue end
    end

    local text = ''
    local f, err = io.open(filename, 'rb')
    if f then
      text = f:read('*a')
      f:close()
      if not text then return end -- filename exists, but cannot read it
    elseif lfs.attributes(filename) then
      error(err)
    end
    local buffer = buffer.new()
    buffer.encoding, buffer.encoding_bom = nil, nil
    -- Try to detect character encoding and convert to UTF-8.
    for encoding, bom in pairs(BOMs) do
      if text:sub(1, #bom) == bom then
        buffer.encoding, buffer.encoding_bom = encoding, bom
        text = text:sub(#bom + 1, -1):iconv('UTF-8', encoding)
        break
      end
    end
    if not buffer.encoding and not text:sub(1, 65536):find('\0') then
      for i = 1, #io.encodings do
        local ok, conv = pcall(string.iconv, text, 'UTF-8', io.encodings[i])
        if ok then buffer.encoding, text = io.encodings[i], conv break end
      end
      assert(buffer.encoding, _L['Encoding conversion failed.'])
    end
    buffer.code_page = buffer.encoding and buffer.CP_UTF8 or 0
    -- Detect EOL mode.
    buffer.eol_mode = EOLs[text:match('\r\n?')] or buffer.EOL_LF
    -- Insert buffer text and set properties.
    buffer:add_text(text, #text)
    buffer:goto_pos(0)
    buffer:empty_undo_buffer()
    buffer.mod_time = lfs.attributes(filename, 'modification') or os.time()
    buffer.filename = filename
    buffer:set_save_point()
    events.emit(events.FILE_OPENED, filename)

    -- Add file to recent files list, eliminating duplicates.
    for i, file in ipairs(io.recent_files) do
      if file == filename then table.remove(io.recent_files, i) break end
    end
    table.insert(io.recent_files, 1, filename)
    ::continue::
  end
end

---
-- Reloads the current buffer's file contents, discarding any changes.
-- @name reload_file
function io.reload_file()
  if not buffer.filename then return end
  local pos, first_visible_line = buffer.current_pos, buffer.first_visible_line
  local f = assert(io.open(buffer.filename, 'rb'))
  local text = f:read('*a')
  f:close()
  local encoding, encoding_bom = buffer.encoding, buffer.encoding_bom
  if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
  if encoding then text = text:iconv('UTF-8', encoding) end
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer:set_save_point()
  buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
end

-- LuaDoc is in core/.buffer.luadoc.
local function set_encoding(buffer, encoding)
  assert(buffer.encoding, _L['Cannot change binary file encoding'])
  local pos, first_visible_line = buffer.current_pos, buffer.first_visible_line
  local text = buffer:get_text()
  text = text:iconv(buffer.encoding, 'UTF-8')
  text = text:iconv(encoding, buffer.encoding)
  text = text:iconv('UTF-8', encoding)
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer.encoding, buffer.encoding_bom = encoding, BOMs[encoding]
end
-- Sets the default buffer encoding.
events_connect(events.BUFFER_NEW, function()
  buffer.set_encoding, buffer.encoding = set_encoding, 'UTF-8'
end)

---
-- Saves the current buffer to its file.
-- Emits `FILE_BEFORE_SAVE` and `FILE_AFTER_SAVE` events.
-- @name save_file
function io.save_file()
  if not buffer.filename then io.save_file_as() return end
  events.emit(events.FILE_BEFORE_SAVE, buffer.filename)
  local text = buffer:get_text()
  if buffer.encoding then
    text = (buffer.encoding_bom or '')..text:iconv(buffer.encoding, 'UTF-8')
  end
  local f = assert(io.open(buffer.filename, 'wb'))
  f:write(text)
  f:close()
  buffer:set_save_point()
  buffer.mod_time = lfs.attributes(buffer.filename, 'modification')
  if buffer._type then buffer._type = nil end
  events.emit(events.FILE_AFTER_SAVE, buffer.filename)
end

---
-- Saves the current buffer to file *filename* or the user-specified filename.
-- Emits a `FILE_AFTER_SAVE` event.
-- @param filename Optional new filepath to save the buffer to. If `nil`, the
--   user is prompted for one.
-- @name save_file_as
function io.save_file_as(filename)
  local dir, name = (buffer.filename or ''):match('^(.-[/\\]?)([^/\\]*)$')
  filename = filename or ui.dialogs.filesave{
    title = _L['Save'], with_directory = dir,
    with_file = name:iconv('UTF-8', _CHARSET),
    width = CURSES and ui.size[1] - 2 or nil
  }
  if not filename then return end
  buffer.filename = filename
  io.save_file()
  events.emit(events.FILE_AFTER_SAVE, filename, true)
end

---
-- Saves all unsaved buffers to their respective files.
-- @see io.save_file
-- @name save_all_files
function io.save_all_files()
  local current_buffer = _BUFFERS[buffer]
  for i, buffer in ipairs(_BUFFERS) do
    view:goto_buffer(i)
    if buffer.filename and buffer.modify then io.save_file() end
  end
  view:goto_buffer(current_buffer)
end

---
-- Closes the current buffer, prompting the user to continue if there are
-- unsaved changes, and returns `true` if the buffer was closed.
-- @return `true` if the buffer was closed; `nil` otherwise.
-- @name close_buffer
function io.close_buffer()
  local filename = buffer.filename or buffer._type or _L['Untitled']
  local confirm = not buffer.modify or ui.dialogs.msgbox{
    title = _L['Close without saving?'],
    text = _L['There are unsaved changes in'],
    informative_text = filename:iconv('UTF-8', _CHARSET),
    icon = 'gtk-dialog-question', button1 = _L['_Cancel'],
    button2 = _L['Close _without saving']
  } == 2
  if not confirm then return nil end -- nil return won't propagate a key command
  buffer:delete()
  return true
end

---
-- Closes all open buffers, prompting the user to continue if there are unsaved
-- buffers, and returns `true` if the user did not cancel.
-- No buffers are saved automatically. They must be saved manually.
-- @return `true` if user did not cancel.
-- @see io.close_buffer
-- @name close_all_buffers
function io.close_all_buffers()
  while #_BUFFERS > 1 do
    view:goto_buffer(#_BUFFERS)
    if not io.close_buffer() then return false end
  end
  return io.close_buffer() -- the last one
end

-- Detects if the current file has been externally modified and, if so, emits a
-- `FILE_CHANGED` event.
local function update_modified_file()
  if not buffer.filename then return end
  local mod_time = lfs.attributes(buffer.filename, 'modification')
  if not mod_time or not buffer.mod_time then return end
  if buffer.mod_time < mod_time then
    buffer.mod_time = mod_time
    events.emit(events.FILE_CHANGED)
  end
end
events_connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
events_connect(events.VIEW_AFTER_SWITCH, update_modified_file)
events_connect(events.FOCUS, update_modified_file)
events_connect(events.RESUME, update_modified_file)

-- Prompts the user to reload the current file if it has been externally
-- modified.
events_connect(events.FILE_CHANGED, function(filename)
  local msg = ('"%s"\n%s'):format(buffer.filename:iconv('UTF-8', _CHARSET),
                                  _L['has been modified. Reload it?'])
  local button = ui.dialogs.msgbox{
    title = _L['Reload?'], text = _L['Reload modified file?'],
    informative_text = msg, icon = 'gtk-dialog-question',
    button1 = _L['_Yes'], button2 = _L['_No']
  }
  if button == 1 then io.reload_file() end
end)

-- Closes the initial "Untitled" buffer.
events_connect(events.FILE_OPENED, function(filename)
  local buf = _BUFFERS[1]
  if #_BUFFERS == 2 and not (buf.filename or buf._type or buf.modify) then
    view:goto_buffer(1)
    io.close_buffer()
  end
end)

---
-- Prompts the user to select a recently opened file to be reopened.
-- @see recent_files
-- @name open_recent_file
function io.open_recent_file()
  local utf8_filenames = {}
  for _, filename in ipairs(io.recent_files) do
    utf8_filenames[#utf8_filenames + 1] = filename:iconv('UTF-8', _CHARSET)
  end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Open'], columns = _L['File'], items = utf8_filenames,
    width = CURSES and ui.size[1] - 2 or nil
  }
  if button == 1 and i then io.open_file(io.recent_files[i]) end
end

-- List of version control directories.
local vcs = {'.bzr', '.git', '.hg', '.svn', 'CVS'}

---
-- Returns the root directory of the project that contains filesystem path
-- *path*.
-- In order to be recognized, projects must be under version control. Recognized
-- VCSes are Bazaar, Git, Mercurial, SVN, and CVS.
-- @param path Optional filesystem path to a project or a file contained within
--   a project. The default value is the buffer's filename or the current
--   working directory.
-- @return string root or nil
-- @name get_project_root
function io.get_project_root(path)
  local root
  local lfs_attributes = lfs.attributes
  local dir = path or (buffer.filename or lfs.currentdir()):match('^(.+)[/\\]')
  while dir do
    for i = 1, #vcs do
      if lfs_attributes(dir..'/'..vcs[i], 'mode') == 'directory' then
        if vcs[i] ~= '.svn' and vcs[i] ~= 'CVS' then return dir end
        root = dir
        break
      end
    end
    dir = dir:match('^(.+)[/\\]')
  end
  return root
end

---
-- Map of file paths to filters used by `io.snapopen()`.
-- @class table
-- @name snapopen_filters
-- @see snapopen
io.snapopen_filters = {}

---
-- Prompts the user to select files to be opened from *paths*, a string
-- directory path or list of directory paths, using a filtered list dialog.
-- If *paths* is `nil`, uses the current project's root directory, which is
-- obtained from `io.get_project_root()`.
-- Files shown in the dialog do not match any pattern in either string or table
-- *filter* or, unless *exclude_FILTER* is `true`, in `lfs.FILTER`. A filter
-- table contains Lua patterns that match filenames to exclude, an optional
-- `folders` sub-table that contains patterns matching directories to exclude,
-- and an optional `extensions` sub-table that contains raw file extensions to
-- exclude. Any patterns starting with '!' exclude files and directories that do
-- not match the pattern that follows. The number of files in the list is capped
-- at `SNAPOPEN_MAX`. If *filter* is `nil` and *paths* is ultimately a string,
-- the filter from the `io.snapopen_filters` table is used. In that case, unless
-- explicitly specified, *exclude_FILTER* becomes `true`.
-- *opts* is an optional table of additional options for
-- `ui.dialogs.filteredlist()`.
-- @param paths Optional string directory path or table of directory paths to
--   search. The default value is the current project's root directory, if
--   available.
-- @param filter Optional filter for files and directories to exclude. The
--   default value comes from `io.snapopen_filters` if *paths* is a string.
-- @param exclude_FILTER Optional flag indicating whether or not to exclude the
--   default filter `lfs.FILTER` in the search. If `false`, adds `lfs.FILTER` to
--   *filter*.
--   Normally, the default value is `false` to include the default filter.
--   However, in the instances where *filter* comes from `io.snapopen_filters`,
--   the default value is `true`.
-- @param opts Optional table of additional options for
--   `ui.dialogs.filteredlist()`.
-- @usage io.snapopen(buffer.filename:match('^.+/')) -- list all files in the
--   current file's directory, subject to the default filter
-- @usage io.snapopen('/project', '!%.lua$') -- list all Lua files in a project
--    directory
-- @usage io.snapopen('/project', {folders = {'build'}}) -- list all source
--   files in a project directory
-- @see io.snapopen_filters
-- @see lfs.FILTER
-- @see SNAPOPEN_MAX
-- @see ui.dialogs.filteredlist
-- @name snapopen
function io.snapopen(paths, filter, exclude_FILTER, opts)
  if not paths then paths = io.get_project_root() end
  if type(paths) == 'string' then
    if not filter then
      filter = io.snapopen_filters[paths]
      if filter and exclude_FILTER == nil then
        exclude_FILTER = filter ~= lfs.FILTER
      end
    end
    paths = {paths}
  end
  local utf8_list = {}
  for i = 1, #paths do
    lfs.dir_foreach(paths[i], function(file)
      if #utf8_list >= io.SNAPOPEN_MAX then return false end
      file = file:gsub('^%.[/\\]', ''):iconv('UTF-8', _CHARSET)
      utf8_list[#utf8_list + 1] = file
    end, filter, exclude_FILTER)
  end
  if #utf8_list >= io.SNAPOPEN_MAX then
    local msg = string.format('%d %s %d', io.SNAPOPEN_MAX,
                              _L['files or more were found. Showing the first'],
                              io.SNAPOPEN_MAX)
    ui.dialogs.msgbox{
      title = _L['File Limit Exceeded'], text = msg, icon = 'gtk-dialog-info'
    }
  end
  local options = {
    title = _L['Open'], columns = _L['File'], items = utf8_list,
    button1 = _L['_OK'], button2 = _L['_Cancel'], select_multiple = true,
    string_output = true, width = CURSES and ui.size[1] - 2 or nil
  }
  if opts then for k, v in pairs(opts) do options[k] = v end end
  local button, files = ui.dialogs.filteredlist(options)
  if button ~= _L['_OK'] or not files then return end
  for i = 1, #files do files[i] = files[i]:iconv(_CHARSET, 'UTF-8') end
  io.open_file(files)
end

-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- Extends Lua's `io` library with Textadept functions for working with files.
--
-- ## Working with UTF-8
--
-- If your filesystem does not use UTF-8-encoded filenames (e.g. Windows),
-- conversions to and from that encoding are necessary since all of Textadept's
-- internal strings are UTF-8-encoded. When opening and saving files through
-- dialogs, these conversions are performed automatically, but if you need to do
-- them manually, use [`string.iconv()`][] along with [`_CHARSET`][], your
-- filesystem's detected encoding. An example is
--
-- <div style="clear: right;"><!-- Clear Table of Contents --></div>
--
--     events.connect(events.FILE_OPENED, function(utf8_filename)
--       local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
--       local f = io.open(filename, 'rb')
--       -- process file
--       f:close()
--     end)
--
-- [`string.iconv()`]: string.html#iconv
-- [`_CHARSET`]: _G.html#_CHARSET
-- @field _G.events.FILE_OPENED (string)
--   Called when opening a file in a new buffer.
--   Emitted by [`open_file()`](#open_file).
--   Arguments:
--
--   * _`filename`_: The UTF-8-encoded filename.
-- @field _G.events.FILE_BEFORE_SAVE (string)
--   Called right before saving a file to disk.
--   Emitted by [`buffer:save()`][].
--   Arguments:
--
--   * _`filename`_: The UTF-8-encoded filename.
--
-- [`buffer:save()`]: buffer.html#save
-- @field _G.events.FILE_AFTER_SAVE (string)
--   Called right after saving a file to disk.
--   Emitted by [`buffer:save()`][].
--   Arguments:
--
--   * _`filename`_: The UTF-8-encoded filename.
--
-- [`buffer:save()`]: buffer.html#save
-- @field _G.events.FILE_SAVED_AS (string)
--   Called after saving a file under a different filename.
--   Emitted by [`buffer:save_as()`][].
--   Arguments:
--
--   * _`filename`_: The UTF-8-encoded filename.
--
-- [`buffer:save_as()`]: buffer.html#save_as
module('io')]]

-- Events.
local events, events_connect = events, events.connect
events.FILE_OPENED = 'file_opened'
events.FILE_BEFORE_SAVE = 'file_before_save'
events.FILE_AFTER_SAVE = 'file_after_save'
events.FILE_SAVED_AS = 'file_saved_as'

---
-- List of recently opened files, the most recent being towards the top.
-- @class table
-- @name recent_files
io.recent_files = {}

---
-- List of byte-order marks (BOMs) for identifying unicode file types.
-- @class table
-- @name boms
io.boms = {
  ['UTF-16BE'] = string.char(254, 255),
  ['UTF-16LE'] = string.char(255, 254),
  ['UTF-32BE'] = string.char(0, 0, 254, 255),
  ['UTF-32LE'] = string.char(255, 254, 0, 0)
}

-- Attempt to detect the encoding of the given text.
-- @param text Text to determine encoding from.
-- @return encoding string for `string.iconv()` (unless `'binary'`, indicating a
--   binary file), byte-order mark (BOM) string or `nil`. If encoding string is
--   `nil`, no encoding has been detected.
local function detect_encoding(text)
  local b1, b2, b3, b4 = string.byte(text, 1, 4)
  if b1 == 239 and b2 == 187 and b3 == 191 then
    return 'UTF-8', string.char(239, 187, 191)
  elseif b1 == 254 and b2 == 255 then
    return 'UTF-16BE', io.boms['UTF-16BE']
  elseif b1 == 255 and b2 == 254 then
    return 'UTF-16LE', io.boms['UTF-16LE']
  elseif b1 == 0 and b2 == 0 and b3 == 254 and b4 == 255 then
    return 'UTF-32BE', io.boms['UTF-32BE']
  elseif b1 == 255 and b2 == 254 and b3 == 0 and b4 == 0 then
    return 'UTF-32LE', io.boms['UTF-32LE']
  else
    local chunk = #text > 65536 and text:sub(1, 65536) or text
    if chunk:find('\0') then return 'binary' end -- binary file
  end
  return nil
end

---
-- List of encodings to try to decode files as.
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
-- @usage io.try_encodings[#io.try_encodings + 1] = 'UTF-16'
-- @class table
-- @name try_encodings
io.try_encodings = {'UTF-8', 'ASCII', 'ISO-8859-1', 'MacRoman'}

---
-- Opens *utf8_filenames*, a "\n" delimited string of UTF-8-encoded filenames,
-- or user-selected files.
-- Emits a `FILE_OPENED` event.
-- @param utf8_filenames Optional list of UTF-8-encoded filenames to open. If
--   `nil`, the user is prompted with a fileselect dialog.
-- @see _G.events
-- @name open_file
function io.open_file(utf8_filenames)
  utf8_filenames = utf8_filenames or
                   gui.dialog('fileselect',
                              '--title', _L['Open'],
                              '--button1', _L['_Open'],
                              '--button2', _L['_Cancel'],
                              '--select-multiple',
                              '--with-directory',
                              (buffer.filename or ''):match('.+[/\\]') or '')
  for utf8_filename in utf8_filenames:gmatch('[^\n]+') do
    utf8_filename = utf8_filename:gsub('^file://', '')
    if WIN32 then utf8_filename = utf8_filename:gsub('/', '\\') end
    for i, buffer in ipairs(_BUFFERS) do
      if utf8_filename == buffer.filename then view:goto_buffer(i) return end
    end

    local filename, text = utf8_filename:iconv(_CHARSET, 'UTF-8'), ''
    local f, err = io.open(filename, 'rb')
    if f then
      text = f:read('*all')
      f:close()
      if not text then return end -- filename exists, but cannot read it
    elseif lfs.attributes(filename) then
      error(err)
    end
    local buffer = new_buffer()
    -- Tries to detect character encoding and convert text from it to UTF-8.
    local encoding, encoding_bom = detect_encoding(text)
    if encoding ~= 'binary' then
      if encoding then
        if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
        text = text:iconv('UTF-8', encoding)
      else
        -- Try list of encodings.
        for _, try_encoding in ipairs(io.try_encodings) do
          local ok, conv = pcall(string.iconv, text, 'UTF-8', try_encoding)
          if ok then encoding, text = try_encoding, conv break end
        end
        if not encoding then error(_L['Encoding conversion failed.']) end
      end
    else
      encoding = nil
    end
    buffer.encoding, buffer.encoding_bom = encoding, encoding_bom
    buffer.code_page = encoding and _SCINTILLA.constants.SC_CP_UTF8 or 0
    -- Tries to set the buffer's EOL mode appropriately based on the file.
    local s, e = text:find('\r\n?')
    if s and e then
      buffer.eol_mode = (s == e and _SCINTILLA.constants.SC_EOL_CR or
                         _SCINTILLA.constants.SC_EOL_CRLF)
    else
      buffer.eol_mode = _SCINTILLA.constants.SC_EOL_LF
    end
    buffer:add_text(text, #text)
    buffer:goto_pos(0)
    buffer:empty_undo_buffer()
    buffer.mod_time = lfs.attributes(filename, 'modification') or os.time()
    buffer.filename = utf8_filename
    buffer:set_save_point()
    events.emit(events.FILE_OPENED, utf8_filename)

    -- Add file to recent files list, eliminating duplicates.
    for i, file in ipairs(io.recent_files) do
      if file == utf8_filename then table.remove(io.recent_files, i) break end
    end
    table.insert(io.recent_files, 1, utf8_filename)
  end
end

-- LuaDoc is in core/.buffer.luadoc.
local function reload(buffer)
  if not buffer then buffer = _G.buffer end
  buffer:check_global()
  if not buffer.filename then return end
  local pos, first_visible_line = buffer.current_pos, buffer.first_visible_line
  local filename = buffer.filename:iconv(_CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'rb')
  if not f then error(err) end
  local text = f:read('*all')
  f:close()
  local encoding, encoding_bom = buffer.encoding, buffer.encoding_bom
  if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
  if encoding then text = text:iconv('UTF-8', encoding) end
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer:set_save_point()
  buffer.mod_time = lfs.attributes(filename, 'modification')
end

-- LuaDoc is in core/.buffer.luadoc.
local function set_encoding(buffer, encoding)
  buffer:check_global()
  if not buffer.encoding then
    error(_L['Cannot change binary file encoding'])
  end
  local pos, first_visible_line = buffer.current_pos, buffer.first_visible_line
  local text = buffer:get_text(buffer.length)
  text = text:iconv(buffer.encoding, 'UTF-8')
  text = text:iconv(encoding, buffer.encoding)
  text = text:iconv('UTF-8', encoding)
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer.encoding, buffer.encoding_bom = encoding, io.boms[encoding]
end

-- LuaDoc is in core/.buffer.luadoc.
local function save(buffer)
  if not buffer then buffer = _G.buffer end
  buffer:check_global()
  if not buffer.filename then buffer:save_as() return end
  events.emit(events.FILE_BEFORE_SAVE, buffer.filename)
  local text = buffer:get_text(buffer.length)
  if buffer.encoding then
    text = (buffer.encoding_bom or '')..text:iconv(buffer.encoding, 'UTF-8')
  end
  local filename = buffer.filename:iconv(_CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'wb')
  if not f then error(err) end
  f:write(text)
  f:close()
  buffer:set_save_point()
  buffer.mod_time = lfs.attributes(filename, 'modification')
  if buffer._type then buffer._type = nil end
  events.emit(events.FILE_AFTER_SAVE, buffer.filename)
end

-- LuaDoc is in core/.buffer.luadoc.
local function save_as(buffer, utf8_filename)
  if not buffer and not utf8_filename then buffer = _G.buffer end
  buffer:check_global()
  if not utf8_filename then
    utf8_filename = gui.dialog('filesave',
                               '--title', _L['Save'],
                               '--button1', _L['_Save'],
                               '--button2', _L['_Cancel'],
                               '--with-directory',
                               (buffer.filename or ''):match('.+[/\\]') or '',
                               '--with-file',
                               (buffer.filename or ''):match('[^/\\]+$') or '',
                               '--no-newline')
  end
  if #utf8_filename > 0 then
    buffer.filename = utf8_filename
    buffer:save()
    events.emit(events.FILE_SAVED_AS, utf8_filename)
  end
end

---
-- Saves all unsaved buffers to their respective files.
-- @see buffer.save
-- @name save_all
function io.save_all()
  local current_buffer = _BUFFERS[buffer]
  for i, buffer in ipairs(_BUFFERS) do
    view:goto_buffer(i)
    if buffer.filename and buffer.dirty then buffer:save() end
  end
  view:goto_buffer(current_buffer)
end

-- LuaDoc is in core/.buffer.luadoc.
local function close(buffer)
  if not buffer then buffer = _G.buffer end
  buffer:check_global()
  local filename = buffer.filename or buffer._type or _L['Untitled']
  if buffer.dirty and gui.dialog('msgbox',
                                 '--title', _L['Close without saving?'],
                                 '--text', _L['There are unsaved changes in'],
                                 '--informative-text', filename,
                                 '--button1', _L['_Cancel'],
                                 '--button2', _L['Close _without saving'],
                                 '--no-newline') ~= '2' then
    return nil -- returning false can cause unwanted key command propagation
  end
  buffer:delete()
  return true
end

---
-- Closes all open buffers, prompting the user to continue with unsaved buffers,
-- and returning `true` if the user did not cancel.
-- No buffers are saved automatically. They must be saved manually.
-- @return `true` if user did not cancel.
-- @see buffer.close
-- @name close_all
function io.close_all()
  while #_BUFFERS > 1 do
    view:goto_buffer(#_BUFFERS)
    if not buffer:close() then return false end
  end
  return buffer:close() -- the last one
end

-- Prompts the user to reload the current file if it has been modified outside
-- of Textadept.
local function update_modified_file()
  if not buffer.filename then return end
  local buffer = buffer
  local utf8_filename = buffer.filename
  local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
  local mod_time = lfs.attributes(filename, 'modification')
  if not mod_time or not buffer.mod_time then return end
  if buffer.mod_time < mod_time then
    buffer.mod_time = mod_time
    if gui.dialog('yesno-msgbox',
                  '--title', _L['Reload?'],
                  '--text', _L['Reload modified file?'],
                  '--informative-text',
                  ('"%s"\n%s'):format(utf8_filename,
                                      _L['has been modified. Reload it?']),
                  '--button1', _L['_Yes'],
                  '--button2', _L['_No'],
                  '--no-cancel',
                  '--no-newline') == '1' then
      buffer:reload()
    end
  end
end
events_connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
events_connect(events.VIEW_AFTER_SWITCH, update_modified_file)

-- Set additional buffer functions.
events_connect(events.BUFFER_NEW, function()
  local buffer = buffer
  buffer.reload = reload
  buffer.save, buffer.save_as = save, save_as
  buffer.close = close
  buffer.encoding, buffer.set_encoding = 'UTF-8', set_encoding
end)

-- Close initial "Untitled" buffer.
events_connect(events.FILE_OPENED, function(utf8_filename)
  local b = _BUFFERS[1]
  if #_BUFFERS == 2 and not (b.filename or b._type or b.dirty) then
    view:goto_buffer(1)
    buffer:close()
  end
end)

---
-- Prompts the user to open a recently opened file.
-- @see recent_files
-- @name open_recent_file
function io.open_recent_file()
  local i = gui.filteredlist(_L['Open'], _L['File'], io.recent_files, true,
                             NCURSES and {'--width', gui.size[1] - 2} or '')
  if i then io.open_file(io.recent_files[i + 1]) end
end

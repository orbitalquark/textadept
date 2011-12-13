-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize
local events = events

--[[ This comment is for LuaDoc.
---
-- Extends Lua's io package to provide file input/output routines for Textadept.
module('io')]]

-- Markdown:
-- ## Converting Filenames to and from UTF-8
--
-- If your filesystem does not use UTF-8 encoded filenames, conversions to and
-- from that encoding will be necessary. When opening and saving files through
-- dialogs, Textadept takes care of these conversions for you, but if you need
-- to do them manually, use [`string.iconv()`][string_iconv] along with
-- `_CHARSET`, your filesystem's detected encoding.
--
-- Example:
--
--     events.connect(events.FILE_OPENED, function(utf8_filename)
--       local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
--       local f = io.open(filename, 'rb')
--       -- process file
--       f:close()
--     end)
--
-- [string_iconv]: ../modules/string.html#iconv
--
-- ## File Events
--
-- * `_G.events.FILE_OPENED`: Called when a file is opened in a new buffer.
--   Arguments:<br />
--       * `filename`: The filename encoded in UTF-8.
-- * `_G.events.FILE_BEFORE_SAVE`: Called right before a file is saved to disk.
--   Arguments:<br />
--       * `filename`: The filename encoded in UTF-8.
-- * `_G.events.FILE_AFTER_SAVE`: Called right after a file is saved to disk.
--   Arguments:<br />
--       * `filename`: The filename encoded in UTF-8.
-- * `_G.events.FILE_SAVED_AS`: Called when a file is saved under a different
--   filename. Arguments:<br />
--       * `filename`: The filename encoded in UTF-8.

-- Events.
events.FILE_OPENED = 'file_opened'
events.FILE_BEFORE_SAVE = 'file_before_save'
events.FILE_AFTER_SAVE = 'file_after_save'
events.FILE_SAVED_AS = 'file_saved_as'

---
-- List of recently opened files.
-- The most recent are towards the top.
-- @class table
-- @name recent_files
io.recent_files = {}

---
-- List of byte-order marks (BOMs).
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
-- List of encodings to try to decode files as after UTF-8.
-- @class table
-- @name try_encodings
io.try_encodings = { 'UTF-8', 'ASCII', 'ISO-8859-1', 'MacRoman' }

---
-- Opens a list of files.
-- @param utf8_filenames A `\n` separated list of UTF-8-encoded filenames to
--   open. If `nil`, the user is prompted with a fileselect dialog.
-- @usage io.open_file(utf8_encoded_filename)
-- @name open_file
function io.open_file(utf8_filenames)
  utf8_filenames = utf8_filenames or
                   gui.dialog('fileselect',
                              '--title', L('Open'),
                              '--select-multiple',
                              '--with-directory',
                              (buffer.filename or ''):match('.+[/\\]') or '')
  for utf8_filename in utf8_filenames:gmatch('[^\n]+') do
    utf8_filename = utf8_filename:gsub('^file://', '')
    if WIN32 then utf8_filename = utf8_filename:gsub('/', '\\') end
    for i, buffer in ipairs(_BUFFERS) do
      if utf8_filename == buffer.filename then view:goto_buffer(i) return end
    end

    local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
    local f, err = io.open(filename, 'rb')
    if not f then error(err) end
    local text = f:read('*all')
    f:close()
    if not text then return end -- filename exists, but cannot read it
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
        if not encoding then error(L('Encoding conversion failed.')) end
      end
    else
      encoding = nil
    end
    local c = _SCINTILLA.constants
    buffer.encoding, buffer.encoding_bom = encoding, encoding_bom
    buffer.code_page = encoding and c.SC_CP_UTF8 or 0
    -- Tries to set the buffer's EOL mode appropriately based on the file.
    local s, e = text:find('\r\n?')
    if s and e then
      buffer.eol_mode = (s == e and c.SC_EOL_CR or c.SC_EOL_CRLF)
    else
      buffer.eol_mode = c.SC_EOL_LF
    end
    buffer:add_text(text, #text)
    buffer:goto_pos(0)
    buffer:empty_undo_buffer()
    buffer.modification_time = lfs.attributes(filename).modification
    buffer.filename = utf8_filename
    buffer:set_save_point()
    events.emit(events.FILE_OPENED, utf8_filename)

    -- Add file to recent files list, eliminating duplicates.
    for i, file in ipairs(io.recent_files) do
      if file == utf8_filename then table.remove(io.recent_files, i) break end
    end
    table.insert(io.recent_files, 1, utf8_filename)
    lfs.chdir(utf8_filename:iconv(_CHARSET, 'UTF-8'):match('.+[/\\]') or '.')
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
  buffer.modification_time = lfs.attributes(filename).modification
end

-- LuaDoc is in core/.buffer.luadoc.
local function set_encoding(buffer, encoding)
  buffer:check_global()
  if not buffer.encoding then error(L('Cannot change binary file encoding')) end
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
  if not buffer.filename then return buffer:save_as() end
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
  buffer.modification_time = lfs.attributes(filename).modification
  if buffer._type then buffer._type = nil end
  events.emit(events.FILE_AFTER_SAVE, buffer.filename)
end

-- LuaDoc is in core/.buffer.luadoc.
local function save_as(buffer, utf8_filename)
  if not buffer and not utf8_filename then buffer = _G.buffer end
  buffer:check_global()
  if not utf8_filename then
    utf8_filename = gui.dialog('filesave',
                               '--title', L('Save'),
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
    lfs.chdir(utf8_filename:iconv(_CHARSET, 'UTF-8'):match('.+[/\\]'))
  end
end

---
-- Saves all dirty buffers to their respective files.
-- @usage io.save_all()
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
  local filename = buffer.filename or buffer._type or L('Untitled')
  if buffer.dirty and gui.dialog('msgbox',
                                 '--title', L('Close without saving?'),
                                 '--text', L('There are unsaved changes in'),
                                 '--informative-text', filename,
                                 '--button1', 'gtk-cancel',
                                 '--button2', L('Close _without saving'),
                                 '--no-newline') ~= '2' then
    return false
  end
  buffer:delete()
  return true
end

---
-- Closes all open buffers.
-- If any buffer is dirty, the user is prompted to continue. No buffers are
-- saved automatically. They must be saved manually.
-- @usage io.close_all()
-- @return true if user did not cancel.
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
  local attributes = lfs.attributes(filename)
  if not attributes or not buffer.modification_time then return end
  if buffer.modification_time < attributes.modification then
    buffer.modification_time = attributes.modification
    if gui.dialog('yesno-msgbox',
                  '--title', L('Reload?'),
                  '--text', L('Reload modified file?'),
                  '--informative-text',
                  ('"%s"\n%s'):format(utf8_filename,
                                      L('has been modified. Reload it?')),
                  '--no-cancel',
                  '--no-newline') == '1' then
      buffer:reload()
    end
  end
end
events.connect(events.BUFFER_AFTER_SWITCH, update_modified_file)
events.connect(events.VIEW_AFTER_SWITCH, update_modified_file)

-- Set additional buffer functions.
events.connect(events.BUFFER_NEW, function()
  local buffer = buffer
  buffer.reload = reload
  buffer.set_encoding = set_encoding
  buffer.save = save
  buffer.save_as = save_as
  buffer.close = close
  buffer.encoding = 'UTF-8'
end)

-- Close initial "Untitled" buffer.
events.connect(events.FILE_OPENED, function(utf8_filename)
  local b = _BUFFERS[1]
  if #_BUFFERS == 2 and not (b.filename or b._type or b.dirty) then
    view:goto_buffer(1)
    buffer:close()
  end
end)

---
-- Prompts the user to open a recently opened file.
-- @name open_recent_file
function io.open_recent_file()
  local i = gui.filteredlist(L('Open'), L('File'), io.recent_files, true)
  if i then M.open_file(io.recent_files[i + 1]) end
end

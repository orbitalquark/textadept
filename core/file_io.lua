-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local events = _G.events

---
-- Extends Lua's io package to provide file input/output routines for Textadept.
module('io', package.seeall)

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
--     events.connect('file_opened',
--       function(utf8_filename)
--         local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
--         local f = io.open(filename, 'rb')
--         -- process file
--         f:close()
--       end)
--
-- [string_iconv]: ../modules/string.html#iconv
--
-- ## Events
--
-- The following is a list of all file I/O events generated in
-- `event_name(arguments)` format:
--
-- * **file\_opened** (filename) <br />
--   Called when a file has been opened in a new buffer.
--       - filename: the filename encoded in UTF-8.
-- * **file\_before\_save** (filename) <br />
--   Called right before a file is saved to disk.
--       - filename: the filename encoded in UTF-8.
-- * **file\_after\_save** (filename) <br />
--   Called right after a file is saved to disk.
--       - filename: the filename encoded in UTF-8.
-- * **file\_saved_as** (filename) <br />
--   Called when a file is saved under another filename.
--       - filename: the other filename encoded in UTF-8.

---
-- List of recently opened files.
-- @class table
-- @name recent_files
recent_files = {}

---
-- List of byte-order marks (BOMs).
-- @class table
-- @name boms
boms = {
  ['UTF-16BE'] = string.char(254, 255),
  ['UTF-16LE'] = string.char(255, 254),
  ['UTF-32BE'] = string.char(0, 0, 254, 255),
  ['UTF-32LE'] = string.char(255, 254, 0, 0)
}

-- Attempt to detect the encoding of the given text.
-- @param text Text to determine encoding from.
-- @return encoding string for string.iconv() (unless 'binary', indicating a
--   binary file), byte-order mark (BOM) string or nil. If encoding string is
--   nil, no encoding has been detected.
local function detect_encoding(text)
  local b1, b2, b3, b4 = string.byte(text, 1, 4)
  if b1 == 239 and b2 == 187 and b3 == 191 then
    return 'UTF-8', string.char(239, 187, 191)
  elseif b1 == 254 and b2 == 255 then
    return 'UTF-16BE', boms['UTF-16BE']
  elseif b1 == 255 and b2 == 254 then
    return 'UTF-16LE', boms['UTF-16LE']
  elseif b1 == 0 and b2 == 0 and b3 == 254 and b4 == 255 then
    return 'UTF-32BE', boms['UTF-32BE']
  elseif b1 == 255 and b2 == 254 and b3 == 0 and b4 == 0 then
    return 'UTF-32LE', boms['UTF-32LE']
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
try_encodings = {
  'UTF-8',
  'ASCII',
  'ISO-8859-1',
  'MacRoman'
}

-- Opens a file or goes to its already open buffer.
-- @param utf8_filename The absolute path to the file to open. Must be UTF-8
--   encoded.
local function open_helper(utf8_filename)
  if not utf8_filename then return end
  utf8_filename = utf8_filename:gsub('^file://', '')
  if WIN32 then utf8_filename = utf8_filename:gsub('/', '\\') end
  for i, buffer in ipairs(_BUFFERS) do
    if utf8_filename == buffer.filename then
      view:goto_buffer(i)
      return
    end
  end

  local text
  local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'rb')
  if not f then error(err) end
  text = f:read('*all')
  f:close()
  if not text then return end -- filename exists, but can't read it
  local buffer = new_buffer()
  -- Tries to detect character encoding and convert text from it to UTF-8.
  local encoding, encoding_bom = detect_encoding(text)
  if encoding ~= 'binary' then
    if encoding then
      if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
      text = text:iconv('UTF-8', encoding)
    else
      -- Try list of encodings.
      for _, try_encoding in ipairs(try_encodings) do
        local ret, conv = pcall(string.iconv, text, 'UTF-8', try_encoding)
        if ret then
          encoding = try_encoding
          text = conv
          break
        end
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
  events.emit('file_opened', utf8_filename)

  -- Add file to recent files list, eliminating duplicates.
  for i, file in ipairs(recent_files) do
    if file == utf8_filename then
      table.remove(recent_files, i)
      break
    end
  end
  recent_files[#recent_files + 1] = utf8_filename
end

---
-- Opens a list of files.
-- @param utf8_filenames A '\n' separated list of filenames to open. If none
--   specified, the user is prompted to open files from a dialog. These paths
--   must be encoded in UTF-8.
-- @usage io.open_file(utf8_encoded_filename)
function open_file(utf8_filenames)
  utf8_filenames = utf8_filenames or
                   gui.dialog('fileselect',
                              '--title', L('Open'),
                              '--select-multiple',
                              '--with-directory',
                              (buffer.filename or ''):match('.+[/\\]') or '')
  for filename in utf8_filenames:gmatch('[^\n]+') do open_helper(filename) end
end

-- LuaDoc is in core/.buffer.luadoc.
local function reload(buffer)
  gui.check_focused_buffer(buffer)
  if not buffer.filename then return end
  local pos = buffer.current_pos
  local first_visible_line = buffer.first_visible_line
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
  gui.check_focused_buffer(buffer)
  if not buffer.encoding then error(L('Cannot change binary file encoding')) end
  local pos = buffer.current_pos
  local first_visible_line = buffer.first_visible_line
  local text = buffer:get_text(buffer.length)
  text = text:iconv(buffer.encoding, 'UTF-8')
  text = text:iconv(encoding, buffer.encoding)
  text = text:iconv('UTF-8', encoding)
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer.encoding, buffer.encoding_bom = encoding, boms[encoding]
end

-- LuaDoc is in core/.buffer.luadoc.
local function save(buffer)
  gui.check_focused_buffer(buffer)
  if not buffer.filename then return buffer:save_as() end
  events.emit('file_before_save', buffer.filename)
  local text = buffer:get_text(buffer.length)
  if buffer.encoding then
    local bom = buffer.encoding_bom or ''
    text = bom..text:iconv(buffer.encoding, 'UTF-8')
  end
  local filename = buffer.filename:iconv(_CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'wb')
  if not f then error(err) end
  f:write(text)
  f:close()
  buffer:set_save_point()
  buffer.modification_time = lfs.attributes(filename).modification
  if buffer._type then buffer._type = nil end
  events.emit('file_after_save', buffer.filename)
end

-- LuaDoc is in core/.buffer.luadoc.
local function save_as(buffer, utf8_filename)
  gui.check_focused_buffer(buffer)
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
    events.emit('file_saved_as', utf8_filename)
  end
end

---
-- Saves all dirty buffers to their respective files.
-- @usage io.save_all()
function save_all()
  local current_buffer = buffer
  local current_index
  for i, buffer in ipairs(_BUFFERS) do
    view:goto_buffer(i)
    if buffer == current_buffer then current_index = i end
    if buffer.filename and buffer.dirty then buffer:save() end
  end
  view:goto_buffer(current_index)
end

-- LuaDoc is in core/.buffer.luadoc.
local function close(buffer)
  gui.check_focused_buffer(buffer)
  if buffer.dirty and
     gui.dialog('msgbox',
                '--title', L('Close without saving?'),
                '--text', L('There are unsaved changes in'),
                '--informative-text',
                string.format('%s', (buffer.filename or
                              buffer._type or L('Untitled'))),
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
function close_all()
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
                  string.format('"%s"\n%s', utf8_filename,
                                L('has been modified. Reload it?')),
                  '--no-cancel',
                  '--no-newline') == '1' then
      buffer:reload()
    end
  end
end
events.connect('buffer_after_switch', update_modified_file)
events.connect('view_after_switch', update_modified_file)

events.connect('buffer_new',
  function() -- set additional buffer functions
    local buffer = buffer
    buffer.reload = reload
    buffer.set_encoding = set_encoding
    buffer.save = save
    buffer.save_as = save_as
    buffer.close = close
    buffer.encoding = 'UTF-8'
  end)

events.connect('file_opened',
  function(utf8_filename) -- close initial 'Untitled' buffer
    local b = _BUFFERS[1]
    if #_BUFFERS == 2 and not (b.filename or b._type or b.dirty) then
      view:goto_buffer(1, true)
      buffer:close()
    end
  end)

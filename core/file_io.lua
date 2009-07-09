-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Provides file input/output routines for Textadept.
-- Opens and saves files and reads API files.
--
-- Events (all filenames are encoded in UTF-8):
--   file_opened(filename)
--   file_before_save(filename)
--   file_saved_as(filename)
module('textadept.io', package.seeall)

local lfs = require 'lfs'

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

---
-- [Local function] Attempt to detect the encoding of the given text.
-- @param text Text to determine encoding from.
-- @return encoding string for textadept.iconv() (unless 'binary', indicating a
--   binary file), byte-order mark (BOM) string or nil. If encoding string is
--   nil, no encoding has been detected.
local function detect_encoding(text)
  local b1, b2, b3, b4 = string.byte(text, 1, 4)
  if b1 == 239 and b2 == 187 and b3 == 191 then
    return 'UTF-8', string.char(239, 187, 191)
  elseif b1 == 254 and b2 == 255 then
    return 'UTF-16BE', boms[encoding]
  elseif b1 == 255 and b2 == 254 then
    return 'UTF-16LE', boms[encoding]
  elseif b1 == 0 and b2 == 0 and b3 == 254 and b4 == 255 then
    return 'UTF-32BE', boms[encoding]
  elseif b1 == 255 and b2 == 254 and b3 == 0 and b4 == 0 then
    return 'UTF-32LE', boms[encoding]
  else
    local chunk = #text > 65536 and text:sub(1, 65536) or text
    if chunk:find('\0') then return 'binary' end -- binary file
  end
  return nil
end

---
-- [Local table] List of encodings to try to decode files as after UTF-8.
-- @class table
-- @name try_encodings
local try_encodings = {
  'UTF-8',
  'ASCII',
  'ISO-8859-1',
  'MacRoman'
}

---
-- [Local function] Opens a file or goes to its already open buffer.
-- @param utf8_filename The absolute path to the file to open. Must be UTF-8
--   encoded.
local function open_helper(utf8_filename)
  if not utf8_filename then return end
  for index, buffer in ipairs(textadept.buffers) do
    if utf8_filename == buffer.filename then
      view:goto_buffer(index)
      return
    end
  end

  local text
  local filename = textadept.iconv(utf8_filename, _CHARSET, 'UTF-8')
  local f = io.open(filename, 'rb')
  if f then
    text = f:read('*all')
    f:close()
    if not text then return end -- filename exists, but can't read it
  end
  local buffer = textadept.new_buffer()
  if text then
    -- Tries to detect character encoding and convert text from it to UTF-8.
    local encoding, encoding_bom = detect_encoding(text)
    if encoding ~= 'binary' then
      if encoding then
        if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
        text = textadept.iconv(text, 'UTF-8', encoding)
      else
        -- Try list of encodings.
        for _, try_encoding in ipairs(try_encodings) do
          local ret, conv = pcall(textadept.iconv, text, 'UTF-8', try_encoding)
          if ret then
            encoding = try_encoding
            text = conv
            break
          end
        end
        if not encoding then error(locale.IO_ICONV_ERROR) end
      end
    else
      encoding = nil
    end
    local c = textadept.constants
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
  end
  buffer.filename = utf8_filename
  buffer:set_save_point()
  textadept.events.handle('file_opened', utf8_filename)

  for index, file in ipairs(recent_files) do
    if file == utf8_filename then
      table.remove(recent_files, index)
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
-- @usage textadept.io.open(utf8_encoded_filename)
function open(utf8_filenames)
  utf8_filenames =
    utf8_filenames or
      textadept.dialog('fileselect',
                       '--title', locale.IO_OPEN_TITLE,
                       '--text', locale.IO_OPEN_TEXT,
                       '--select-multiple',
                       '--with-directory',
                         (buffer.filename or ''):match('.+[/\\]') or '')
  for filename in utf8_filenames:gmatch('[^\n]+') do open_helper(filename) end
end

---
-- Reloads the file in a given buffer.
-- @param buffer The buffer to reload. This must be the currently focused
--   buffer.
-- @usage buffer:reload()
function reload(buffer)
  textadept.check_focused_buffer(buffer)
  if not buffer.filename then return end
  local pos = buffer.current_pos
  local first_visible_line = buffer.first_visible_line
  local filename = textadept.iconv(buffer.filename, _CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'rb')
  if not f then return end
  local text = f:read('*all')
  f:close()
  local encoding, encoding_bom = buffer.encoding, buffer.encoding_bom
  if encoding_bom then text = text:sub(#encoding_bom + 1, -1) end
  if encoding then text = textadept.iconv(text, 'UTF-8', encoding) end
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer:set_save_point()
  buffer.modification_time = lfs.attributes(filename).modification
end

---
-- Sets the encoding for the buffer, converting its contents in the process.
-- @param buffer The buffer to set the encoding for. It must be the currently
--   focused buffer.
-- @param encoding The encoding to set. Valid encodings are ones that GTK's
--   g_convert() function accepts (typically GNU iconv's encodings).
-- @usage buffer:set_encoding('ASCII')
function set_encoding(buffer, encoding)
  textadept.check_focused_buffer(buffer)
  if not buffer.encoding then error('Cannot change binary file encoding') end
  local iconv = textadept.iconv
  local pos = buffer.current_pos
  local first_visible_line = buffer.first_visible_line
  local text = buffer:get_text(buffer.length)
  text = iconv(text, buffer.encoding, 'UTF-8')
  text = iconv(text, encoding, buffer.encoding)
  text = iconv(text, 'UTF-8', encoding)
  buffer:clear_all()
  buffer:add_text(text, #text)
  buffer:line_scroll(0, first_visible_line)
  buffer:goto_pos(pos)
  buffer.encoding, buffer.encoding_bom = encoding, boms[encoding]
end

---
-- Saves the current buffer to a file.
-- @param buffer The buffer to save. Its 'filename' property is used as the
--   path of the file to save to. This must be the currently focused buffer.
-- @usage buffer:save()
function save(buffer)
  textadept.check_focused_buffer(buffer)
  if not buffer.filename then return save_as(buffer) end
  textadept.events.handle('file_before_save', buffer.filename)
  local text = buffer:get_text(buffer.length)
  if buffer.encoding then
    local bom = buffer.encoding_bom or ''
    text = bom..textadept.iconv(text, buffer.encoding, 'UTF-8')
  end
  local filename = textadept.iconv(buffer.filename, _CHARSET, 'UTF-8')
  local f, err = io.open(filename, 'wb')
  if f then
    f:write(text)
    f:close()
    buffer:set_save_point()
    buffer.modification_time = lfs.attributes(filename).modification
  else
    textadept.events.error(err)
  end
  if buffer._type then buffer._type = nil end
end

---
-- Saves the current buffer to a file different than its filename property.
-- @param buffer The buffer to save. This must be the currently focused buffer.
-- @param utf8_filename The new filepath to save the buffer to. Must be UTF-8
--   encoded.
-- @usage buffer:save_as(filename)
function save_as(buffer, utf8_filename)
  textadept.check_focused_buffer(buffer)
  if not utf8_filename then
    utf8_filename =
      textadept.dialog('filesave',
                       '--title', locale.IO_SAVE_TITLE,
                       '--with-directory',
                         (buffer.filename or ''):match('.+[/\\]') or '',
                       '--with-file',
                         (buffer.filename or ''):match('[^/\\]+$') or '',
                       '--no-newline')
  end
  if #utf8_filename > 0 then
    buffer.filename = utf8_filename
    buffer:save()
    textadept.events.handle('file_saved_as', utf8_filename)
  end
end

---
-- Saves all dirty buffers to their respective files.
-- @usage textadept.io.save_all()
function save_all()
  local current_buffer = buffer
  local current_index
  for index, buffer in ipairs(textadept.buffers) do
    view:goto_buffer(index)
    if buffer == current_buffer then current_index = index end
    if buffer.filename and buffer.dirty then buffer:save() end
  end
  view:goto_buffer(current_index)
end

---
-- Closes the current buffer.
-- If the buffer is dirty, the user is prompted to continue. The buffer is not
-- saved automatically. It must be done manually.
-- @param buffer The buffer to close. This must be the currently focused
--   buffer.
-- @usage buffer:close()
function close(buffer)
  textadept.check_focused_buffer(buffer)
  if buffer.dirty and
     textadept.dialog('yesno-msgbox',
                      '--title', locale.IO_CLOSE_TITLE,
                      '--text', locale.IO_CLOSE_TEXT,
                      '--informative-text', locale.IO_CLOSE_MSG,
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
-- @usage textadept.io.close_all()
-- @return true if user did not cancel.
function close_all()
  while #textadept.buffers > 1 do
    view:goto_buffer(#textadept.buffers)
    if not buffer:close() then return false end
  end
  buffer:close() -- the last one
  return true
end

---
-- Loads a Textadept session file.
-- Textadept restores split views, opened buffers, cursor information, and
-- project manager details.
-- @param filename The absolute path to the session file to load. Defaults to
--   $HOME/.textadept/session if not specified.
-- @param only_pm Flag indicating whether or not to load only the Project
--   Manager session settings. Defaults to false.
-- @return true if the session file was opened and read; false otherwise.
-- @usage textadept.io.load_session(filename)
function load_session(filename, only_pm)
  local ta_session = _USERHOME..'/session'
  local f = io.open(filename or ta_session, 'rb')
  if not f then return false end
  local current_view, splits = 1, { [0] = {} }
  for line in f:lines() do
    if not only_pm then
      if line:find('^buffer:') then
        local anchor, current_pos, first_visible_line, filename =
          line:match('^buffer: (%d+) (%d+) (%d+) (.+)$')
        if not filename:find('^%[.+%]$') then
          textadept.io.open(filename or '', 'rb')
        else
          textadept.new_buffer()
          buffer._type = filename
        end
        -- Restore saved buffer selection and view.
        local anchor = tonumber(anchor) or 0
        local current_pos = tonumber(current_pos) or 0
        local first_visible_line = tonumber(first_visible_line) or 0
        local buffer = buffer
        buffer._anchor, buffer._current_pos = anchor, current_pos
        buffer._first_visible_line = first_visible_line
        buffer:line_scroll(0,
          buffer:visible_from_doc_line(first_visible_line))
        buffer:set_sel(anchor, current_pos)
      elseif line:find('^%s*split%d:') then
        local level, num, type, size =
          line:match('^(%s*)split(%d): (%S+) (%d+)')
        local view = splits[#level] and splits[#level][tonumber(num)] or view
        splits[#level + 1] = { view:split(type == 'true') }
        splits[#level + 1][1].size = tonumber(size) -- could be 1 or 2
      elseif line:find('^%s*view%d:') then
        local level, num, buf_idx = line:match('^(%s*)view(%d): (%d+)$')
        local view = splits[#level][tonumber(num)] or view
        buf_idx = tonumber(buf_idx)
        if buf_idx > #textadept.buffers then buf_idx = #textadept.buffers end
        view:goto_buffer(buf_idx)
      elseif line:find('^current_view:') then
        local view_idx = line:match('^current_view: (%d+)')
        current_view = tonumber(view_idx) or 1
      end
    end
    if line:find('^size:') then
      local width, height = line:match('^size: (%d+) (%d+)$')
      if width and height then textadept.size = { width, height } end
    elseif line:find('^pm:') then
      local width, cursor, text = line:match('^pm: (%d+) ([%d:]+) (.+)$')
      textadept.pm.width = width or 0
      textadept.pm.entry_text = text or ''
      textadept.pm.activate()
      if cursor then textadept.pm.cursor = cursor end
    end
  end
  f:close()
  textadept.views[current_view]:focus()
  textadept.session_file = filename or ta_session
  return true
end

---
-- Saves a Textadept session to a file.
-- Saves split views, opened buffers, cursor information, and project manager
-- details.
-- @param filename The absolute path to the session file to save. Defaults to
--   either the current session file or $HOME/.textadept/session if not
--   specified.
-- @usage textadept.io.save_session(filename)
function save_session(filename)
  local session = {}
  local buffer_line = "buffer: %d %d %d %s" -- anchor, cursor, line, filename
  local split_line = "%ssplit%d: %s %d" -- level, number, type, size
  local view_line = "%sview%d: %d" -- level, number, doc index
  -- Write out opened buffers.
  for _, buffer in ipairs(textadept.buffers) do
    local filename = buffer.filename or buffer._type
    if filename then
      local current = buffer.doc_pointer == textadept.focused_doc_pointer
      local anchor = current and 'anchor' or '_anchor'
      local current_pos = current and 'current_pos' or '_current_pos'
      local first_visible_line =
        current and 'first_visible_line' or '_first_visible_line'
      session[#session + 1] =
        buffer_line:format(buffer[anchor] or 0, buffer[current_pos] or 0,
                           buffer[first_visible_line] or 0, filename)
    end
  end
  -- Write out split views.
  local function write_split(split, level, number)
    local c1, c2 = split[1], split[2]
    local vertical, size = tostring(split.vertical), split.size
    local spaces = (' '):rep(level)
    session[#session + 1] = split_line:format(spaces, number, vertical, size)
    spaces = (' '):rep(level + 1)
    if type(c1) == 'table' then
      write_split(c1, level + 1, 1)
    else
      session[#session + 1] = view_line:format(spaces, 1, c1)
    end
    if type(c2) == 'table' then
      write_split(c2, level + 1, 2)
    else
      session[#session + 1] = view_line:format(spaces, 2, c2)
    end
  end
  local splits = textadept.get_split_table()
  if type(splits) == 'table' then
    write_split(splits, 0, 0)
  else
    session[#session + 1] = view_line:format('', 1, splits)
  end
  -- Write out the current focused view.
  local current_view = view
  for index, view in ipairs(textadept.views) do
    if view == current_view then
      current_view = index
      break
    end
  end
  session[#session + 1] = ("current_view: %d"):format(current_view)
  -- Write out other things.
  local size = textadept.size
  session[#session + 1] = ("size: %d %d"):format(size[1], size[2])
  local pm = textadept.pm
  session[#session + 1] =
    ("pm: %d %s %s"):format(pm.width, pm.cursor or '0', pm.entry_text)
  -- Write the session.
  local ta_session = _USERHOME..'/session'
  local f = io.open(filename or textadept.session_file or ta_session, 'wb')
  if f then
    f:write(table.concat(session, '\n'))
    f:close()
  end
end

---
-- Reads an API file.
-- Each non-empty line in the API file is structured as follows:
--   identifier (parameters) description
-- Whitespace is optional, but can used for formatting. In description, '\\n'
-- will be interpreted as a newline (\n) character. 'Overloaded' identifiers
-- are handled appropriately.
-- @param filename The absolute path to the API file to read.
-- @param word_chars Characters considered to be word characters for
--   determining the identifier to lookup. Its contents should be in Lua
--   pattern format suitable for the character class construct.
-- @return API table.
-- @usage textadept.io.read_api_file(filename, '%w_')
function read_api_file(filename, word_chars)
  local api = {}
  local f = io.open(filename, 'rb')
  if not f then return api end
  for line in f:lines() do
    local func, params, desc =
      line:match('(['..word_chars..']+)%s*(%b())(.*)$')
    if func and params and desc then
      if not api[func] then api[func] = {} end
      api[func][#api[func] + 1] = { params, desc }
    end
  end
  f:close()
  return api
end

---
-- [Local function] Prompts the user to reload the current file if it has been
-- modified outside of Textadept.
local function update_modified_file()
  if not buffer.filename then return end
  local utf8_filename = buffer.filename
  local filename = textadept.iconv(utf8_filename, _CHARSET, 'UTF-8')
  local attributes = lfs.attributes(filename)
  if not attributes then return end
  if buffer.modification_time < attributes.modification then
    if textadept.dialog('yesno-msgbox',
                        '--title', locale.IO_RELOAD_TITLE,
                        '--text', locale.IO_RELOAD_TEXT,
                        '--informative-text',
                          string.format(locale.IO_RELOAD_MSG, utf8_filename),
                        '--no-cancel',
                        '--no-newline') == '1' then
      buffer:reload()
    else
      buffer.modification_time = attributes.modification
    end
  end
end
textadept.events.add_handler('buffer_after_switch', update_modified_file)
textadept.events.add_handler('view_after_switch', update_modified_file)

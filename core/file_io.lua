-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Provides file input/output routines for Textadept.
-- Opens and saves files and sessions and reads API files.
--
-- Events:
--   file_opened(filename)
--   file_saved_as(filename)
module('textadept.io', package.seeall)

---
-- List of recently opened files.
-- @class table
-- @name recent_files
recent_files = {}

---
-- [Local function] Opens a file or goes to its already open buffer.
-- @param filename The absolute path to the file to open.
local function open_helper(filename)
  if not filename then return end
  for index, buffer in ipairs(textadept.buffers) do
    if filename == buffer.filename then view:goto_buffer(index) return end
  end
  local buffer = textadept.new_buffer()
  local f, err = io.open(filename, 'rb')
  if f then
    local text = f:read('*all')
    local chunk = #text > 65536 and text:sub(1, 65536) or text
    if chunk:find('\0') then buffer.code_page = 0 end -- binary file; no UTF-8
    buffer:add_text(text, #text)
    buffer:goto_pos(0)
    buffer:empty_undo_buffer()
    f:close()
  end
  buffer.filename = filename
  buffer:set_save_point()
  textadept.events.handle('file_opened', filename)
  recent_files[#recent_files + 1] = filename
end

---
-- Opens a list of files.
-- @param filenames A '\n' separated list of filenames to open. If none
--   specified, the user is prompted to open files from a dialog.
-- @usage textadept.io.open(filename)
function open(filenames)
  local locale = textadept.locale
  filenames =
    filenames or cocoa_dialog('fileselect', {
      title = locale.IO_OPEN_TITLE,
      text = locale.IO_OPEN_TEXT,
      -- in Windows, dialog:get_filenames() is unavailable; only allow single
      -- selection
      ['select-multiple'] = not WIN32 or nil,
      ['with-directory'] = (buffer.filename or ''):match('.+[/\\]')
    })
  for filename in filenames:gmatch('[^\n]+') do open_helper(filename) end
end

---
-- Reloads the file in a given buffer.
-- @param buffer The buffer to reload. This must be the currently focused
--   buffer.
-- @usage buffer:reload()
function reload(buffer)
  textadept.check_focused_buffer(buffer)
  if not buffer.filename then return end
  local f, err = io.open(buffer.filename)
  if f then
    local pos = buffer.current_pos
    local first_visible_line = buffer.first_visible_line
    buffer:set_text(f:read('*all'))
    buffer:line_scroll(0, first_visible_line)
    buffer:goto_pos(pos)
    buffer:set_save_point()
    f:close()
  end
end

---
-- Saves the current buffer to a file.
-- @param buffer The buffer to save. Its 'filename' property is used as the
--   path of the file to save to. This must be the currently focused buffer.
-- @usage buffer:save()
function save(buffer)
  textadept.check_focused_buffer(buffer)
  if not buffer.filename then return save_as(buffer) end
  prepare = _m.textadept.editing.prepare_for_save
  if prepare then prepare() end
  local f, err = io.open(buffer.filename, 'wb')
  if f then
    local txt, _ = buffer:get_text(buffer.length)
    f:write(txt)
    f:close()
    buffer:set_save_point()
  else
    textadept.events.error(err)
  end
end

---
-- Saves the current buffer to a file different than its filename property.
-- @param buffer The buffer to save. This must be the currently focused buffer.
-- @filename The new filepath to save the buffer to.
-- @usage buffer:save_as(filename)
function save_as(buffer, filename)
  textadept.check_focused_buffer(buffer)
  if not filename then
    filename =
      cocoa_dialog('filesave', {
        title = textadept.locale.IO_SAVE_TITLE,
        ['with-directory'] = (buffer.filename or ''):match('.+[/\\]'),
        ['with-file'] = (buffer.filename or ''):match('[^/\\]+$'),
        ['no-newline'] = true
      })
  end
  if #filename > 0 then
    buffer.filename = filename
    buffer:save()
    textadept.events.handle('file_saved_as', filename)
  end
end

---
-- Saves all dirty buffers to their respective files.
-- @usage textadept.io.save_all()
function save_all()
  local current_buffer = buffer
  local current_index
  for idx, buffer in ipairs(textadept.buffers) do
    view:goto_buffer(idx)
    if buffer == current_buffer then current_index = idx end
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
  local locale = textadept.locale
  textadept.check_focused_buffer(buffer)
  if buffer.dirty and cocoa_dialog('yesno-msgbox', {
    title = locale.IO_CLOSE_TITLE,
    text = locale.IO_CLOSE_TEXT,
    ['informative-text'] = locale.IO_CLOSE_MSG,
    ['no-newline'] = true
  }) ~= '2' then return false end
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
--   $HOME/.ta_session if not specified.
-- @param only_pm Flag indicating whether or not to load only the Project
--   Manager session settings. Defaults to false.
-- @return true if the session file was opened and read; false otherwise.
-- @usage textadept.io.load_session(filename)
function load_session(filename, only_pm)
  local user_dir = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')
  if not user_dir then return end
  local ta_session = user_dir..'/.ta_session'
  local f = io.open(filename or ta_session)
  local current_view, splits = 1, { [0] = {} }
  if f then
    for line in f:lines() do
      if not only_pm then
        if line:find('^buffer:') then
          local anchor, current_pos, first_visible_line, filename =
            line:match('^buffer: (%d+) (%d+) (%d+) (.+)$')
          textadept.io.open(filename or '')
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
          view:goto_buffer(tonumber(buf_idx))
        elseif line:find('^current_view:') then
          local view_idx, buf_idx = line:match('^current_view: (%d+)')
          current_view = tonumber(view_idx) or 1
        end
      end
      if line:find('^size:') then
        local width, height = line:match('^size: (%d+) (%d+)$')
        if width and height then textadept.size = { width, height } end
      elseif line:find('^pm:') then
        local width, text = line:match('^pm: (%d+) (.+)$')
        textadept.pm.width = width or 0
        textadept.pm.entry_text = text or ''
        textadept.pm.activate()
      end
    end
    f:close()
    textadept.views[current_view]:focus()
    return true
  end
  return false
end

---
-- Saves a Textadept session to a file.
-- Saves split views, opened buffers, cursor information, and project manager
-- details.
-- @param filename The absolute path to the session file to save. Defaults to
--   $HOME/.ta_session if not specified.
-- @usage textadept.io.save_session(filename)
function save_session(filename)
  local session = {}
  local buffer_line = "buffer: %d %d %d %s" -- anchor, cursor, line, filename
  local split_line = "%ssplit%d: %s %d" -- level, number, type, size
  local view_line = "%sview%d: %d" -- level, number, doc index
  -- Write out opened buffers. (buffer: filename)
  local buffer_indices, offset = {}, 0
  for idx, buffer in ipairs(textadept.buffers) do
    if buffer.filename then
      local current = buffer.doc_pointer == textadept.focused_doc_pointer
      local anchor = current and 'anchor' or '_anchor'
      local current_pos = current and 'current_pos' or '_current_pos'
      local first_visible_line =
        current and 'first_visible_line' or '_first_visible_line'
      session[#session + 1] =
        buffer_line:format(buffer[anchor] or 0,
                           buffer[current_pos] or 0,
                           buffer[first_visible_line] or 0, buffer.filename)
      buffer_indices[buffer.doc_pointer] = idx - offset
    else
      offset = offset + 1 -- don't save untitled files in session
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
  for idx, view in ipairs(textadept.views) do
    if view == current_view then current_view = idx break end
  end
  session[#session + 1] = ("current_view: %d"):format(current_view)
  -- Write out other things.
  local size = textadept.size
  session[#session + 1] = ("size: %d %d"):format(size[1], size[2])
  local pm = textadept.pm
  session[#session + 1] = ("pm: %d %s"):format(pm.width, pm.entry_text)
  -- Write the session.
  local user_dir = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')
  if not user_dir then return end
  local ta_session = user_dir..'/.ta_session'
  local f = io.open(filename or ta_session, 'w')
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
  local f = io.open(filename)
  if f then
    for line in f:lines() do
      local func, params, desc =
        line:match('(['..word_chars..']+)%s*(%b())(.*)$')
      if func and params and desc then
        if not api[func] then api[func] = {} end
        api[func][#api[func] + 1] = { params, desc }
      end
    end
    f:close()
  end
  return api
end

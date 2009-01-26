-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

package.path = _HOME..'/core/?.lua;'..package.path
if not WIN32 then
  package.cpath = _HOME..'/core/?.so;'..package.cpath
else
  package.cpath = _HOME..'/core/?.dll;'..package.cpath
end

_THEME = 'light'
local user_dir = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')
if user_dir then
  local f = io.open(user_dir..'/.ta_theme')
  if f then
    theme = f:read('*line'):match('[^\r\n]+')
    f:close()
    if theme and #theme > 0 then _THEME = theme end
  end
end

require 'iface'
require 'locale'
require 'events'
require 'file_io'
if not MAC then
  require 'lua_dialog'
end

---
-- Checks if the buffer being indexed is the currently focused buffer.
-- This is necessary because any buffer actions are performed in the focused
-- views' buffer, which may not be the buffer being indexed. Throws an error
-- if the check fails.
-- @param buffer The buffer in question.
function textadept.check_focused_buffer(buffer)
  local locale = textadept.locale
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error(locale.ERR_BUFFER_EXPECTED, 2)
  elseif textadept.focused_doc_pointer ~= buffer.doc_pointer then
    error(locale.ERR_BUFFER_NOT_FOCUSED, 2)
  end
end

---
-- Helper function for printing messages to buffers.
-- Opens a new buffer (if one hasn't already been opened) for printing messages.
-- @param buffer_type String type of message buffer.
-- @param ... Message strings.
-- @usage textadept._print('shows_errors', error_message)
-- @usage textadept._print('shows_messages', message)
function textadept._print(buffer_type, ...)
  local function safe_print(...)
    local message = table.concat({...}, '\t')
    local message_buffer
    for index, buffer in ipairs(textadept.buffers) do
      if buffer[buffer_type] then
        message_buffer = buffer
        if buffer.doc_pointer ~= textadept.focused_doc_pointer then
          view:goto_buffer(index)
        end
        break
      end
    end
    if not message_buffer then
      message_buffer = textadept.new_buffer()
      message_buffer[buffer_type] = true
    end
    message_buffer:append_text(message..'\n')
    message_buffer:set_save_point()
  end
  pcall(safe_print, ...) -- prevent endless loops if this errors
end

---
-- Prints messages to the Textadept message buffer.
-- Opens a new buffer (if one hasn't already been opened) for printing messages.
-- @param ... Message strings.
function textadept.print(...) textadept._print('shows_messages', ...) end

---
-- Displays a CocoaDialog of a specified type with given arguments returning
-- the result.
-- @param kind The CocoaDialog type.
-- @param opts A table of key, value arguments. Each key is a --key switch with
--   a "value" value. If value is nil, it is omitted and just the switch is
--   used.
-- @return string CocoaDialog result.
function cocoa_dialog(kind, opts)
  local args = { kind }
  for k, v in pairs(opts) do
    args[#args + 1] = '--'..k
    if k == 'items' and kind:find('dropdown') then
      if not MAC then
        for item in v:gmatch('"(.-)"%s+') do args[#args + 1] = item end
      else
        args[#args + 1] = v
      end
    elseif type(v) == 'string' then
      args[#args + 1] = not MAC and v or '"'..v..'"'
    end
  end
  if not MAC then
    return lua_dialog.run(args)
  else
    local cocoa_dialog = '/CocoaDialog.app/Contents/MacOS/CocoaDialog '
    local p = io.popen(_HOME..cocoa_dialog..table.concat(args, ' '))
    local out = p:read('*all')
    p:close()
    return out
  end
end

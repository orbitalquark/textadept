-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

_RELEASE = "Textadept 2.2 beta 2"

local textadept = _G.textadept

package.path = _HOME..'/core/?.lua;'..package.path

_USERHOME = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')..'/.textadept'
local lfs = require 'lfs'
if not lfs.attributes(_USERHOME) then lfs.mkdir(_USERHOME) end

_LEXERPATH = _USERHOME..'/lexers/?.lua;'.._HOME..'/lexers'

_THEME = 'light'
local f = io.open(_USERHOME..'/theme', 'rb')
if f then
  local theme = f:read('*line'):match('[^\r\n]+')
  f:close()
  if theme and #theme > 0 then _THEME = theme end
end
if not _THEME:find('[/\\]') then
  local theme = _THEME
  _THEME = _HOME..'/themes/'..theme
  if not lfs.attributes(_THEME) then _THEME = _USERHOME..'/themes/'..theme end
end

require 'iface'
require 'locale'
require 'events'
require 'file_io'

rawset = nil -- do not allow modifications which could compromise stability

-- LuaDoc is in core/.textadept.lua.
function textadept.check_focused_buffer(buffer)
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error(locale.ERR_BUFFER_EXPECTED, 2)
  elseif textadept.focused_doc_pointer ~= buffer.doc_pointer then
    error(locale.ERR_BUFFER_NOT_FOCUSED, 2)
  end
end

-- LuaDoc is in core/.textadept.lua.
function textadept._print(buffer_type, ...)
  local function safe_print(...)
    local message = table.concat({...}, '\t')
    local message_buffer, message_buffer_index
    local message_view, message_view_index
    for index, buffer in ipairs(textadept.buffers) do
      if buffer._type == buffer_type then
        message_buffer, message_buffer_index = buffer, index
        for jndex, view in ipairs(textadept.views) do
          if view.doc_pointer == message_buffer.doc_pointer then
            message_view, message_view_index = view, jndex
            break
          end
        end
        break
      end
    end
    if not message_view then
      local _, message_view = view:split(false) -- horizontal split
      if not message_buffer then
        message_buffer = textadept.new_buffer()
        message_buffer._type = buffer_type
      else
        message_view:goto_buffer(message_buffer_index, true)
      end
    else
      textadept.goto_view(message_view_index, true)
    end
    message_buffer:append_text(message..'\n')
    message_buffer:set_save_point()
  end
  pcall(safe_print, ...) -- prevent endless loops if this errors
end

-- LuaDoc is in core/.textadept.lua.
function textadept.print(...) textadept._print(locale.MESSAGE_BUFFER, ...) end

-- LuaDoc is in core/.textadept.lua.
function textadept.switch_buffer()
  local items = {}
  for _, buffer in ipairs(textadept.buffers) do
    local filename = buffer.filename or buffer._type or locale.UNTITLED
    local dirty = buffer.dirty and '*' or ''
    items[#items + 1] = dirty..filename:match('[^/\\]+$')
    items[#items + 1] = filename
  end
  local out =
    textadept.dialog('filteredlist',
                     '--title', locale.SWITCH_BUFFERS,
                     '--button1', 'gtk-ok',
                     '--button2', 'gtk-cancel',
                     '--no-newline',
                     '--columns', 'Name', 'File',
                     '--items', unpack(items))
  local i = tonumber(out:match('%-?%d+$'))
  if i and i >= 0 then view:goto_buffer(i + 1, true) end
end

-- LuaDoc is in core/.textadept.lua.
function textadept.user_dofile(filename)
  if lfs.attributes(_USERHOME..'/'..filename) then
    local ret, errmsg = pcall(dofile, _USERHOME..'/'..filename)
    if not ret then textadept.print(errmsg) end
    return ret
  end
  return false
end

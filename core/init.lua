-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

_RELEASE = "Textadept 3.2"

package.path = _HOME..'/core/?.lua;'..package.path

require 'iface'
require 'args'
require 'locale'
require 'events'
require 'file_io'
require 'gui'

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
  _THEME = _USERHOME..'/themes/'..theme
  if not lfs.attributes(_THEME) then _THEME = _HOME..'/themes/'..theme end
end

-- LuaDoc is in core/._G.lua.
function _G.user_dofile(filename)
  if lfs.attributes(_USERHOME..'/'..filename) then
    local ret, errmsg = pcall(dofile, _USERHOME..'/'..filename)
    if not ret then gui.print(errmsg) end
    return ret
  end
  return false
end

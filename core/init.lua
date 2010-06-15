-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

_RELEASE = "Textadept 2.2"

package.path = _HOME..'/core/?.lua;'..package.path

_USERHOME = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')..'/.textadept'
local lfs = require 'lfs'
if not lfs.attributes(_USERHOME) then lfs.mkdir(_USERHOME) end
if not lfs.attributes(_USERHOME..'/init.lua') then
  local f = io.open(_USERHOME..'/init.lua', 'w')
  if f then
    f:write("require 'textadept'\n")
    f:close()
  end
end

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
require 'gui'

rawset = nil -- do not allow modifications which could compromise stability

-- LuaDoc is in core/._G.lua.
function _G.user_dofile(filename)
  if lfs.attributes(_USERHOME..'/'..filename) then
    local ret, errmsg = pcall(dofile, _USERHOME..'/'..filename)
    if not ret then gui.print(errmsg) end
    return ret
  end
  return false
end

-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

_RELEASE = "Textadept 3.7 beta"

package.path = _HOME..'/core/?.lua;'..package.path
os.setlocale('C', 'collate')

require 'iface'
require 'args'
require 'locale'
require 'events'
require 'file_io'
require 'gui'
require 'keys'

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

-- LuaDoc is in core/._G.luadoc.
function _G.user_dofile(filename)
  if not lfs.attributes(_USERHOME..'/'..filename) then return false end
  local ok, err = pcall(dofile, _USERHOME..'/'..filename)
  if not ok then gui.print(err) end
  return ok
end

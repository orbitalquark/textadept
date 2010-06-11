-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local paths = {
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua',
  _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua',
  _HOME..'/modules/?/init.lua',
  package.path
}
package.path = table.concat(paths, ';')

if not user_dofile('init.lua') then
require 'textadept'
end

if not RESETTING then
  -- for Windows, create arg table from single command line string (arg[0])
  if WIN32 and #arg[0] > 0 then
    local lpeg = require 'lpeg'
    local P, C = lpeg.P, lpeg.C
    local param = P('"') * C((1 - P('"'))^0) * '"' + C((1 - P(' '))^1)
    local args = lpeg.match(lpeg.Ct(param * (P(' ') * param)^0), arg[0])
    for _, a in ipairs(args) do arg[#arg + 1] = a end
  end

  -- process command line arguments
  if MAC and arg[1] and arg[1]:find('^%-psn_0') then table.remove(arg, 1) end
  if #arg == 0 then
    _m.textadept.session.load()
  else
    -- process command line switches
    for i, switch in ipairs(arg) do
      if switch == '-ns' or switch == '--no-session' then
        _m.textadept.session.SAVE_ON_QUIT = false
        table.remove(arg, i)
      end
    end

    -- open files
    for _, filename in ipairs(arg) do io.open_file(filename) end
  end
end

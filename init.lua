-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

local paths = {
  _HOME..'/modules/?.lua',
  _HOME..'/modules/?/init.lua',  
  _USERHOME..'/modules/?.lua',
  _USERHOME..'/modules/?/init.lua',
  package.path
}
package.path = table.concat(paths, ';')

local loaded_user_modules = false
local user_init = _USERHOME..'/init.lua'
local lfs = require 'lfs'
if lfs.attributes(user_init) then
  local ret, errmsg = pcall(dofile, user_init)
  if not ret then error(errmsg) end
  loaded_user_modules = ret
end

if not loaded_user_modules then
-- Core extension modules to load on startup.
require 'ext/keys' -- provides key command support
require 'ext/find' -- provides functionality for find/replace
require 'ext/command_entry' -- provides tab-completion for the command entry
require 'ext/mime_types' -- provides support for language detection based on
                         -- the file; loads its language-specific module if
                         -- it exists

-- Generic modules to load on startup.
require 'textadept'

-- Core extension modules that must be loaded last.
require 'ext/menu' -- provides the menu bar
require 'ext/key_commands' -- key commands
end

if not RESETTING then
  -- for Windows, create arg table from single command line string (arg[0])
  if WIN32 and #arg[0] > 0 then
    local lpeg = require 'lpeg'
    local P, C = lpeg.P, lpeg.C
    param = P('"') * C((1 - P('"'))^0) * '"' + C((1 - P(' '))^1)
    cmdline = lpeg.Ct(param * (P(' ') * param)^0)
    args = lpeg.match(cmdline, arg[0])
    for _, a in ipairs(args) do arg[#arg + 1] = a end
  end

  -- process command line arguments
  if MAC and arg[1] and arg[1]:find('^%-psn_0') then
    table.remove(arg, 1)
  end
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
    local base_dir = arg[0]:match('^.+/') or ''
    for _, filename in ipairs(arg) do
      if not filename:find('^~?/') then filename = base_dir..filename end
      textadept.io.open(filename)
    end
  end
end

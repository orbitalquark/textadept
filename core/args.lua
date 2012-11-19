-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Processes command line arguments for Textadept.
--
-- ## Arg Events
--
-- + `'arg_none'`
--   Called when no command line arguments are passed to Textadept on startup.
module('args')]]

local arg = arg

-- Contains registered command line switches.
-- @class table
-- @name switches
local switches = {}

---
-- Registers a command line switch.
-- @param switch1 String switch (short version).
-- @param switch2 String switch (long version).
-- @param narg The number of expected parameters for the switch.
-- @param f The Lua function to run when the switch is tripped.
-- @param description Description of the switch for command line help.
-- @name register
function M.register(switch1, switch2, narg, f, description)
  local t = {f, narg, description}
  switches[switch1], switches[switch2] = t, t
end

---
-- Processes command line arguments.
-- Add command line switches with `args.register()`. Any unrecognized arguments
-- are treated as filepaths and opened.
-- Emits an `'arg_none'` event when no args are present.
-- @param arg Argument table.
-- @see register
-- @see events
-- @name process
function M.process(arg)
  local no_args = true
  local i = 1
  while i <= #arg do
    local switch = switches[arg[i]]
    if switch then
      local f, n = table.unpack(switch)
      local args = {}
      for j = i + 1, i + n do args[#args + 1] = arg[j] end
      f(table.unpack(args))
      i = i + n
    else
      if not arg[i]:find(not WIN32 and '^/' or '^%u:[/\\]') then
        -- Convert relative path to absolute path.
        local cwd = arg[-1] or lfs.currentdir()
        arg[i] = cwd..(not WIN32 and '/' or '\\')..arg[i]
      end
      io.open_file(arg[i])
      no_args = false
    end
    i = i + 1
  end
  if no_args then events.emit('arg_none') end
end

-- Shows all registered command line switches on the command line.
local function show_help()
  print('Usage: textadept [args] [filenames]')
  local line = "  %s [%d args]: %s"
  for k, v in pairs(switches) do print(line:format(k, table.unpack(v, 2))) end
  os.exit()
end
if not NCURSES then M.register('-h', '--help', 0, show_help, 'Shows this') end

-- For Windows, create arg table from single command line string (arg[0]).
if WIN32 and #arg[0] > 0 then
  local P, C = lpeg.P, lpeg.C
  local param = P('"') * C((1 - P('"'))^0) * '"' + C((1 - P(' '))^1)
  local params = lpeg.match(lpeg.Ct(param * (P(' ')^1 * param)^0), arg[0])
  for i = 1, #params do arg[#arg + 1] = params[i] end
end

-- Set `_G._USERHOME`.
local userhome = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')..'/.textadept'
for i = 1, #arg do
  if (arg[i] == '-u' or arg[i] == '--userhome') and arg[i + 1] then
    userhome = arg[i + 1]
    break
  end
end
if not lfs.attributes(userhome) then lfs.mkdir(userhome) end
if not lfs.attributes(userhome..'/init.lua') then
  local f = io.open(userhome..'/init.lua', 'w')
  if f then
    f:write("_M.textadept = require 'textadept'\n")
    f:close()
  end
end
_G._USERHOME = userhome

M.register('-u', '--userhome', 1, function() end, 'Sets alternate _USERHOME')
M.register('-f', '--force', 0, function() end, 'Forces unique instance')

return M

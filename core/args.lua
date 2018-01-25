-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Processes command line arguments for Textadept.
-- @field _G.events.ARG_NONE (string)
--   Emitted when no command line arguments are passed to Textadept on startup.
module('args')]]

events.ARG_NONE = 'arg_none'

-- Contains registered command line switches.
-- @class table
-- @name switches
local switches = {}

---
-- Registers a command line switch with short and long versions *short* and
-- *long*, respectively. *narg* is the number of arguments the switch accepts,
-- *f* is the function called when the switch is tripped, and *description* is
-- the switch's description when displaying help.
-- @param short The string short version of the switch.
-- @param long The string long version of the switch.
-- @param narg The number of expected parameters for the switch.
-- @param f The Lua function to run when the switch is tripped.
-- @param description The string description of the switch for command line
--   help.
-- @name register
function M.register(short, long, narg, f, description)
  local t = {f, narg, description}
  switches[short], switches[long] = t, t
end

-- Processes command line argument table *arg*, handling switches previously
-- defined using `args.register()` and treating unrecognized arguments as
-- filenames to open.
-- Emits an `ARG_NONE` event when no arguments are present.
-- @param arg Argument table.
-- @see register
-- @see _G.events
local function process(arg)
  local no_args = true
  local i = 1
  while i <= #arg do
    local switch = switches[arg[i]]
    if switch then
      local f, n = table.unpack(switch)
      f(table.unpack(arg, i + 1, i + n))
      i = i + n
    else
      io.open_file(lfs.abspath(arg[i], arg[-1]))
      no_args = false
    end
    i = i + 1
  end
  if no_args then events.emit(events.ARG_NONE) end
end
events.connect(events.INITIALIZED, function() if arg then process(arg) end end)
events.connect('cmd_line', process) -- undocumented, single-instance event

if not CURSES then
  -- Shows all registered command line switches on the command line.
  M.register('-h', '--help', 0, function()
    print('Usage: textadept [args] [filenames]')
    local line = "  %s [%d args]: %s"
    for k, v in pairs(switches) do print(line:format(k, table.unpack(v, 2))) end
    os.exit()
  end, 'Shows this')
  -- Shows Textadept version and copyright on the command line.
  M.register('-v', '--version', 0, function()
    print(_RELEASE..'\n'.._COPYRIGHT)
    quit()
  end, 'Prints Textadept version and copyright')
  -- After Textadept finishes initializing and processes arguments, remove the
  -- help and version switches in order to prevent another instance from sending
  -- '-h', '--help', '-v', and '--version' to the first instance, killing the
  -- latter.
  events.connect(events.INITIALIZED, function()
    switches['-h'], switches['--help'] = nil, nil
    switches['-v'], switches['--version'] = nil, nil
  end)
end

-- Set `_G._USERHOME`.
_USERHOME = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')..'/.textadept'
for i = 1, #arg do
  if (arg[i] == '-u' or arg[i] == '--userhome') and arg[i + 1] then
    _USERHOME = arg[i + 1]
    break
  end
end
if not lfs.attributes(_USERHOME) then lfs.mkdir(_USERHOME) end
local f = io.open(_USERHOME..'/init.lua', 'a+') -- ensure existence
if f then f:close() end

M.register('-u', '--userhome', 1, function() end, 'Sets alternate _USERHOME')
M.register('-f', '--force', 0, function() end, 'Forces unique instance')

return M

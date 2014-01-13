-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Processes command line arguments for Textadept.
--
-- ## Arg Events
--
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

---
-- Processes command line argument table *arg*, handling switches previously
-- defined using `args.register()` and treating unrecognized arguments as
-- filenames to open.
-- Emits an `ARG_NONE` event when no arguments are present.
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
      if not arg[i]:find(not WIN32 and '^/' or '^%a:[/\\]') then
        -- Convert relative path to absolute path.
        local cwd = arg[-1] or lfs.currentdir()
        arg[i] = cwd..(not WIN32 and '/' or '\\')..arg[i]
      end
      io.open_file(arg[i])
      no_args = false
    end
    i = i + 1
  end
  if no_args then events.emit(events.ARG_NONE) end
end

-- Shows all registered command line switches on the command line.
local function show_help()
  print('Usage: textadept [args] [filenames]')
  local line = "  %s [%d args]: %s"
  for k, v in pairs(switches) do print(line:format(k, table.unpack(v, 2))) end
  os.exit()
end
if not CURSES then M.register('-h', '--help', 0, show_help, 'Shows this') end

-- For Windows, create arg table from single command line string (arg[0]).
if WIN32 and not CURSES and #arg[0] > 0 then
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
local f = io.open(userhome..'/init.lua', 'a+') -- ensure existence
if f then f:close() end
_G._USERHOME = userhome

M.register('-u', '--userhome', 1, function() end, 'Sets alternate _USERHOME')
M.register('-f', '--force', 0, function() end, 'Forces unique instance')

events.connect(events.INITIALIZED,
               function() if arg then M.process(arg) end end)

return M

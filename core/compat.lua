-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

-- When using LuaJIT try to retain backwards compatibility (Lua 5.1).
-- LuaJIT is compiled with LUAJIT_ENABLE_LUA52COMPAT for some Lua 5.2 features.

-- In Lua 5.1, `load` did not take mode and environment parameters.
local load51 = load
function load(ld, source, mode, env)
  local f, err = load51(ld, source)
  if f and env then return setfenv(f, env) end
  return f, err
end

-- In Lua 5.1, `loadfile` did not take mode and environment parameters.
local loadfile51 = loadfile
function loadfile(filename, mode, env)
  local f, err = loadfile51(filename)
  if f and env then return setfenv(f, env) end
  return f, err
end

-- In Lua 5.1, `xpcall` did not accept function arguments.
local xpcall51 = xpcall
function xpcall(f, error, ...)
  local args = {...}
  return xpcall51(function() return f(unpack(args)) end, error)
end

-- In Lua 5.1, `module` exists.
_G.module = nil -- use _G prefix so LuaDoc does not get confused

-- In Lua 5.1, `package.loaders` is `package.searchers`
package.searchers = package.loaders

-- TODO: table.pack
-- In Lua 5.1, `table.pack` did not exist.

-- TODO: string.rep
-- In Lua 5.1, `string.rep` did not take separation string parameter.

-- TODO: math.log, math.log10
-- In Lua 5.1, `math.log` does not take base parameter and `math.log10` existed.

-- In LuaJIT, `bit` is used instead of `bit32`
bit32 = bit

-- In Lua 5.1, `os.execute` returned an integer depending on shell availability.
-- It also returned just a status code.
local os_execute51 = os.execute
function os.execute(command)
  if not command then return os_execute51() ~= 0 end
  local code = os_execute51(command)
  return code == 0, 'exit', code
end

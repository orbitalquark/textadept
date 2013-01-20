-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

-- When using LuaJIT try to retain backwards compatibility (Lua 5.1).
-- LuaJIT is compiled with LUAJIT_ENABLE_LUA52COMPAT for some Lua 5.2 features.

-- In Lua 5.1, `module` exists.
_G.module = nil -- use _G prefix so LuaDoc does not get confused

-- In Lua 5.1, `package.loaders` is `package.searchers`
package.searchers = package.loaders

-- In LuaJIT, `bit` is used instead of `bit32`
bit32 = bit

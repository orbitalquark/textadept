-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The ansi_c module.
-- It provides utilities for editing C code.
--
-- ## Key Bindings
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX | `M-L, M` in curses)
--   Open this module for editing.
-- + `.`
--   Show an autocompletion list of members for the symbol behind the caret.
-- + `->`
--   Show an autocompletion list of members for the symbol behind the caret.
-- + `Shift+Enter` (`⇧↩` | `S-Enter`)
--   Add ';' to the end of the current line and insert a newline.
-- @field sense
--   The C [Adeptsense](textadept.adeptsense.html).
--   It loads user tags from *`_USERHOME`/modules/ansi_c/tags* and user apidocs
--   from *`_USERHOME`/modules/ansi_c/api*.
module('_M.ansi_c')]]

-- Adeptsense.

M.sense = textadept.adeptsense.new('ansi_c')
local as = textadept.adeptsense
M.sense.ctags_kinds = {
  c = as.CLASS, d = as.FUNCTION, e = as.FIELD, f = as.FUNCTION, g = as.CLASS,
  m = as.FIELD, s = as.CLASS, t = as.CLASS
}
M.sense:load_ctags(_HOME..'/modules/ansi_c/tags', true)
M.sense.api_files = {
  _HOME..'/modules/ansi_c/api', _HOME..'/modules/ansi_c/lua_api'
}
M.sense.syntax.type_declarations = {
  '([%w_%.]+)[%s%*&]+%_[^%w_]', -- Foo bar, Foo *bar, Foo* bar, Foo &bar, etc.
}
M.sense:add_trigger('.')
M.sense:add_trigger('->')

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/ansi_c/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/ansi_c/tags')
end
if lfs.attributes(_USERHOME..'/modules/ansi_c/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/ansi_c/api'
end

-- Commands.

---
-- Table of C-specific key bindings.
-- @class table
-- @name _G.keys.ansi_c
keys.ansi_c = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = {io.open_file, _HOME..'/modules/ansi_c/init.lua'},
  },
  ['s\n'] = function()
    buffer:line_end()
    buffer:add_text(';')
    buffer:new_line()
  end,
}

-- Snippets.

---
-- Table of C-specific snippets.
-- @class table
-- @name _G.snippets.ansi_c
if type(snippets) == 'table' then
  snippets.ansi_c = {
    -- Lua snippets
    lf = 'static int %1(function)(lua_State *%2(lua)) {\n\t%0\n\treturn 0;\n}',
    ls = 'lua_State',
    lgf = 'lua_getfield(%1(lua), %2(-1), %3(field));',
    lgg = 'lua_getglobal(%1(lua), %2(global));',
    lgt = 'lua_gettable(%1(lua), %2(-2));',
    ltop = 'lua_gettop(%1(lua));',
    lib = 'lua_isboolean(%1(lua), %2(-1))',
    licf = 'lua_iscfunction(%1(lua), %2(-1))',
    lif = 'lua_isfunctionu(%1(lua), %2(-1))',
    linil = 'lua_isnil(%1(lua), %2(-1))',
    linone = 'lua_isnone(%1(lua), %2(-1))',
    linonen = 'lua_isnoneornil(%1(lua), %2(-1))',
    lin = 'lua_isnumber(%1(lua), %2(-1))',
    lis = 'lua_isstring(%1(lua), %2(-1))',
    lit = 'lua_istable(%1(lua), %2(-1))',
    lith = 'lua_isthread(%1(lua), %2(-1))',
    liu = 'lua_isuserdata(%1(lua), %2(-1))',
    llen = 'lua_rawlen(%1(lua), %2(-1))',
    lpop = 'lua_pop(%1(lua), %2(1));',
    lpb = 'lua_pushboolean(%1(lua), %2(boolean));',
    lpcc = 'lua_pushcclosure(%1(lua), %2(closure_func), %3(num_values));',
    lpcf = 'lua_pushcfunction(%1(lua), %2(cfunction));',
    lpi = 'lua_pushinteger(%1(lua), %2(integer));',
    lplu = 'lua_pushlightuserdata(%1(lua), %2(userdata));',
    lpnil = 'lua_pushnil(%1(lua));',
    lpn = 'lua_pushnumber(%1(lua), %2(number));',
    lps = 'lua_pushstring(%1(lua), %2(string));',
    lpth = 'lua_pushthread(%1(lua));',
    lpv = 'lua_pushvalue(%1(lua), %2(-1));',
    lrg = 'lua_rawget(%1(lua), %2(-2));',
    lrgi = 'lua_rawgeti(%1(lua), %2(-2), %3(1));',
    lrs = 'lua_rawset(%1(lua), %2(-3));',
    lrsi = 'lua_rawseti(%1(lua), %2(-2), %3(1));',
    lr = 'lua_register(%1(lua), %2(fname), %3(cfunction));',
    lsf = 'lua_setfield(%1(lua), %2(-2), %3(field));',
    lsg = 'lua_setglobal(%1(lua), %2(global));',
    lst = 'lua_settable(%1(lua), %2(-3));',
    ltb = 'lua_toboolean(%1(lua), %2(-1))',
    ltcf = 'lua_tocfunction(%1(lua), %2(-1))',
    lti = 'lua_tointeger(%1(lua), %2(-1))',
    ltn = 'lua_tonumber(%1(lua), %2(-1))',
    ltp = 'lua_topointer(%1(lua), %2(-1))',
    lts = 'lua_tostring(%1(lua), %2(-1))',
    ltth = 'lua_tothread(%1(lua), %2(-1))',
    ltu = 'lua_touserdata(%1(lua), %2(-1))',
    lt = 'lua_type(%1(lua), %2(-1))',
    llcint = 'luaL_checkint(%1(lua), %2(-1))',
    llci = 'luaL_checkinteger(%1(lua), %2(-1))',
    llcl = 'luaL_checklong(%1(lua), %2(-1))',
    llcn = 'luaL_checknumber(%1(lua), %2(-1))',
    llcs = 'luaL_checkstring(%1(lua), %2(-1))',
    llcu = 'luaL_checkudata(%1(lua), %2(-1), %3(mt_name))',
    llerr = 'luaL_error(%1(lua), %2(errorstring)%3(, %4(arg)));',
    lloint = 'luaL_optint(%1(lua), %2(-1), %3(default))',
    lloi = 'luaL_optinteger(%1(lua), %2(-1), %3(default))',
    llol = 'luaL_optlong(%1(lua), %2(-1), %3(default))',
    llon = 'luaL_optnumber(%1(lua), %2(-1), %3(default))',
    llos = 'luaL_optstring(%1(lua), %2(-1), %3(default))',
  }
end

return M

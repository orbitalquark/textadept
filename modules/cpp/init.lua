-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The cpp module.
-- It provides utilities for editing C/C++ code.
-- User tags are loaded from _USERHOME/modules/cpp/tags and user apis are loaded
-- from _USERHOME/modules/cpp/api.
module('_m.cpp', package.seeall)]]

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX): Open this module for editing.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `->`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `Shift+Return` (`⇧↩`): Add ';' to line end and insert newline.
--
-- ## Fields
--
-- * `sense`: The C/C++ [Adeptsense](_m.textadept.adeptsense.html).

local m_editing, m_run = _m.textadept.editing, _m.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.cpp = '//'
-- Compile and Run command tables use file extensions.
m_run.compile_command.c =
  'gcc -pedantic -Os -o "%(filename_noext)" %(filename)'
m_run.compile_command.cpp =
  'g++ -pedantic -Os -o "%(filename_noext)" %(filename)'
m_run.run_command.c = '%(filedir)%(filename_noext)'
m_run.run_command.cpp = '%(filedir)%(filename_noext)'
m_run.error_detail.c = {
  pattern = '^(.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

---
-- Sets default buffer properties for C/C++ files.
-- @name set_buffer_properties
function M.set_buffer_properties()

end

-- Adeptsense.

M.sense = _m.textadept.adeptsense.new('cpp')
M.sense.ctags_kinds = {
  c = 'classes',
  d = 'functions',
  e = 'fields',
  f = 'functions',
  g = 'classes',
  m = 'fields',
  s = 'classes',
  t = 'classes'
}
M.sense:load_ctags(_HOME..'/modules/cpp/tags', true)
M.sense.api_files = { _HOME..'/modules/cpp/api', _HOME..'/modules/cpp/lua_api' }
M.sense.syntax.type_declarations = {
  '([%w_%.]+)[%s%*&]+%_[^%w_]', -- Foo bar, Foo *bar, Foo* bar, Foo &bar, etc.
}
M.sense:add_trigger('.')
M.sense:add_trigger('->')

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/cpp/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/cpp/tags')
end
if lfs.attributes(_USERHOME..'/modules/cpp/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/cpp/api'
end

-- Commands.

---
-- Container for C/C++-specific key commands.
-- @class table
-- @name _G.keys.cpp
keys.cpp = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = { io.open_file,
          (_HOME..'/modules/cpp/init.lua'):iconv('UTF-8', _CHARSET) },
  },
  ['s\n'] = function()
    buffer:line_end()
    buffer:add_text(';')
    buffer:new_line()
  end,
}

-- Snippets.

---
-- Container for C/C++-specific snippets.
-- @class table
-- @name _G.snippets.cpp
if type(snippets) == 'table' then
  snippets.cpp = {
    rc = 'reinterpret_cast<%1>(%2(%<selected_text>))',
    sc = 'static_cast<%1>(%2(%<selected_text>))',
    cc = 'const_cast<%1>(%2(%<selected_text>))',

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
    llen = 'lua_objlen(%1(lua), %2(-1))',
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

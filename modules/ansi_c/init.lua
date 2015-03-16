-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The ansi_c module.
-- It provides utilities for editing C code.
--
-- ## Key Bindings
--
-- + `Shift+Enter` (`⇧↩` | `S-Enter`)
--   Add ';' to the end of the current line and insert a newline.
module('_M.ansi_c')]]

-- Autocompletion and documentation.

---
-- List of ctags files to use for autocompletion in addition to the current
-- project's top-level *tags* file or the current directory's *tags* file.
-- @class table
-- @name tags
M.tags = {_HOME..'/modules/ansi_c/tags', _USERHOME..'/modules/ansi_c/tags'}

local XPM = textadept.editing.XPM_IMAGES
local xpms = setmetatable({
  c = XPM.CLASS, d = XPM.SLOT, e = XPM.VARIABLE, f = XPM.METHOD,
  g = XPM.TYPEDEF, m = XPM.VARIABLE, s = XPM.STRUCT, t = XPM.TYPEDEF,
  v = XPM.VARIABLE
}, {__index = function() return 0 end})

textadept.editing.autocompleters.ansi_c = function()
  local list = {}
  -- Retrieve the symbol behind the caret.
  local line, pos = buffer:get_cur_line()
  local symbol, op, part = line:sub(1, pos):match('([%w_]-)([%.%->]*)([%w_]*)$')
  if symbol == '' and part == '' and op ~= '' then return nil end -- lone ., ->
  if op ~= '' and op ~= '.' and op ~= '->' then return nil end
  -- Attempt to identify the symbol type.
  if symbol ~= '' then
    local buffer = buffer
    local decl = '([%w_]+)[%s%*&]+'..symbol:gsub('(%p)', '%%%1')..'[^%w_]'
    for i = buffer:line_from_position(buffer.current_pos) - 1, 0, -1 do
      local class = buffer:get_line(i):match(decl)
      if class then symbol = class break end
    end
  end
  -- Search through ctags for completions for that symbol.
  local tags_files = {}
  for i = 1, #M.tags do tags_files[#tags_files + 1] = M.tags[i] end
  tags_files[#tags_files + 1] = (io.get_project_root(buffer.filename) or
                                 lfs.currentdir())..'/tags'
  local name_patt = '^'..part
  local sep = string.char(buffer.auto_c_type_separator)
  for i = 1, #tags_files do
    if lfs.attributes(tags_files[i]) then
      for tag_line in io.lines(tags_files[i]) do
        local name = tag_line:match('^%S+')
        if name:find(name_patt) and not name:find('^!') and not list[name] then
          local fields = tag_line:match(';"\t(.*)$')
          if (fields:match('class:(%S+)') or fields:match('enum:(%S+)') or
              fields:match('struct:(%S+)') or fields:match('typedef:(%S+)') or
              '') == symbol then
            list[#list + 1] = ("%s%s%d"):format(name, sep,
                                                xpms[fields:sub(1, 1)])
            list[name] = true
          end
        end
      end
    end
  end
  return #part, list
end

textadept.editing.api_files.ansi_c = {
  _HOME..'/modules/ansi_c/api', _HOME..'/modules/ansi_c/lua_api',
  _USERHOME..'/modules/ansi_c/api'
}

-- Commands.

---
-- Table of C-specific key bindings.
-- @class table
-- @name _G.keys.ansi_c
keys.ansi_c = {
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
    lc = 'lua_call(%1(L), %2(nargs), %3(nresults))',
    lcs = 'lua_checkstack(%1(L), %2(1))',
    lf = 'static int %1(func)(lua_State *%2(L)) {\n\t%0\n\treturn %3(0);\n}',
    lgf = 'lua_getfield(%1(L), %2(-1), %3(field))',
    lgg = 'lua_getglobal(%1(L), %2(global))',
    lgmt = 'lua_getmetatable(%1(L), %2(-1))',
    lgt = 'lua_gettable(%1(L), %2(-2))',
    ltop = 'lua_gettop(%1(L))',
    lib = 'lua_isboolean(%1(L), %2(-1))',
    licf = 'lua_iscfunction(%1(L), %2(-1))',
    lif = 'lua_isfunction(%1(L), %2(-1))',
    lilu = 'lua_islightuserdata(%1(L), %2(-1))',
    linil = 'lua_isnil(%1(L), %2(-1))',
    linone = 'lua_isnone(%1(L), %2(-1))',
    linonen = 'lua_isnoneornil(%1(L), %2(-1))',
    lin = 'lua_isnumber(%1(L), %2(-1))',
    lis = 'lua_isstring(%1(L), %2(-1))',
    lit = 'lua_istable(%1(L), %2(-1))',
    liu = 'lua_isuserdata(%1(L), %2(-1))',
    llen = 'lua_len(%1(L), %2(-1))',
    lrlen = 'lua_rawlen(%1(L), %2(-1))',
    lnt = 'lua_newtable(%1(L))',
    lnu = '(%3 *)lua_newuserdata(%1(L), %2(sizeof(%3(struct))))',
    ln = 'lua_next(%1(L), %2(-2))',
    lpc = 'lua_pcall(%1(L), %2(nargs), %3(nresults), %4(msgh))',
    lpop = 'lua_pop(%1(L), %2(1))',
    lpb = 'lua_pushboolean(%1(L), %2(bool))',
    lpcc = 'lua_pushcclosure(%1(L), %2(cfunc), %3(nvalues))',
    lpcf = 'lua_pushcfunction(%1(L), %2(cfunc))',
    lpi = 'lua_pushinteger(%1(L), %2(integer))',
    lplu = 'lua_pushlightuserdata(%1(L), %2(pointer))',
    lpnil = 'lua_pushnil(%1(L))',
    lpn = 'lua_pushnumber(%1(L), %2(number))',
    lps = 'lua_pushstring(%1(L), %2(string))',
    lpls = 'lua_pushlstring(%1(L), %2(string), %3(len))',
    lpv = 'lua_pushvalue(%1(L), %2(-1))',
    lrg = 'lua_rawget(%1(L), %2(-2))',
    lrgi = 'lua_rawgeti(%1(L), %2(-2), %3(1))',
    lrs = 'lua_rawset(%1(L), %2(-3))',
    lrsi = 'lua_rawseti(%1(L), %2(-2), %3(1))',
    lr = 'lua_register(%1(L), %2(name), %3(cfunc))',
    lsf = 'lua_setfield(%1(L), %2(-2), %3(field))',
    lsg = 'lua_setglobal(%1(L), %2(global))',
    lsmt = 'lua_setmetatable(%1(L), %2(-2))',
    lst = 'lua_settable(%1(L), %2(-3))',
    ltb = 'lua_toboolean(%1(L), %2(-1))',
    lti = 'lua_tointeger(%1(L), %2(-1))',
    ltn = 'lua_tonumber(%1(L), %2(-1))',
    ltls = 'lua_tolstring(%1(L), %2(-1), &%3(int))',
    lts = 'lua_tostring(%1(L), %2(-1))',
    ltu = '(%3 *)lua_touserdata(%1(L), %2(-1))',
    lt = 'lua_type(%1(L), %2(-1))',
    llac = 'luaL_argcheck(%1(L), %2(expr), %3(1), %4(extramsg))',
    llci = 'luaL_checkinteger(%1(L), %2(1))',
    llcl = 'luaL_checklong(%1(L), %2(1))',
    llcls = 'luaL_checklstring(%1(L), %2(1), &%3(int))',
    llcn = 'luaL_checknumber(%1(L), %2(1))',
    llcs = 'luaL_checkstring(%1(L), %2(1))',
    llcu = '(%4 *)luaL_checkudata(%1(L), %2(1), %3(mt_name))',
    llerr = 'luaL_error(%1(L), %2(message)%3(, %4(arg)))',
    llgmt = 'luaL_getmetatable(%1(L), %2(mt_name))',
    llnmt = 'luaL_newmetatable(%1(L), %2(mt_name))',
    lloi = 'luaL_optinteger(%1(L), %2(1), %3(default))',
    llol = 'luaL_optlong(%1(L), %2(1), %3(default))',
    llon = 'luaL_optnumber(%1(L), %2(1), %3(default))',
    llos = 'luaL_optstring(%1(L), %2(1), %3(default))',
    llref = 'luaL_ref(%1(L), %2(LUA_REGISTRYINDEX))',
    llsmt = 'luaL_setmetatable(%1(L), %2(mt_name))',
    lluref = 'luaL_unref(%1(L), %2(LUA_REGISTRYINDEX), %3(ref))',
  }
end

return M

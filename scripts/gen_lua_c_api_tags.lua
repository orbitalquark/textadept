#!/usr/bin/lua
-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

local f = io.open('../modules/ansi_c/lua_tags', 'w')
-- Lua header files define API functions in a way ctags cannot detect.
-- For example: `LUA_API lua_State *(lua_newstate) (lua_Alloc f, void *ud);`.
-- The function name enclosed in parenthesis is causing the problem. A regex
-- must be used to capture those definitions.
local p = io.popen('ctags -o - --regex-c++="/\\(([a-zA-Z_]+)\\) +\\(/\\1/f/" '..
                   '../src/lua/src/lua.h ../src/lua/src/lauxlib.h')
for line in p:read('*a'):gmatch('[^\n]+') do
  -- Strip comment lines and replace file and ex_cmd fields with empty info.
  if not line:find('^!') then
    local tag, _, _, ext_fields = line:match('^(%S+)\t(%S+)\t(.-);"\t?(.*)$')
    f:write(tag, '\t_\t0;"\t', ext_fields, '\n')
  end
end
p:close()
f:close()

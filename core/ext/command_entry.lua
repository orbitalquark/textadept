-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale
local ce = textadept.command_entry

-- LuaDoc is in core/.command_entry.lua
function ce.get_completions_for(command)
  local substring = command:match('[%w_.:]+$') or ''
  local path, o, prefix = substring:match('^([%w_.:]-)([.:]?)([%w_]*)$')
  local ret, tbl = pcall(loadstring('return ('..path..')'))
  if not ret then tbl = getfenv(0) end
  if type(tbl) ~= 'table' then return end
  local cmpls = {}
  for k in pairs(tbl) do
    if type(k) == 'string' and k:find('^'..prefix) then
      cmpls[#cmpls + 1] = k
    end
  end
  if path == 'buffer' then
    if o == ':' then
      for f in pairs(textadept.buffer_functions) do
        if f:find('^'..prefix) then cmpls[#cmpls + 1] = f end
      end
    else
      for p in pairs(textadept.buffer_properties) do
        if p:find('^'..prefix) then cmpls[#cmpls + 1] = p end
      end
    end
  end
  table.sort(cmpls)
  return cmpls
end

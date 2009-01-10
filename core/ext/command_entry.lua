-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local ce = textadept.command_entry

---
-- Gets completions for the current command_entry text.
-- This function is called internally and shouldn't be called by script.
-- @param command The command to complete.
-- @return sorted table of completions
function ce.get_completions_for(command)
  local substring = command:match('[%w_.:]+$') or ''
  local path, o, prefix = substring:match('^([%w_.:]-)([.:]?)([%w_]*)$')
  local ret, tbl = pcall(loadstring('return ('..path..')'))
  if not ret then tbl = getfenv(0) end
  if type(tbl) ~= 'table' then return end
  local cmpls = {}
  for k in pairs(tbl) do
    if type(k) == 'string' and k:match('^'..prefix) then
      cmpls[#cmpls + 1] = k
    end
  end
  if path == 'buffer' then
    if o == ':' then
      for f in pairs(textadept.buffer_functions) do
        if f:match('^'..prefix) then cmpls[#cmpls + 1] = f end
      end
    else
      for p in pairs(textadept.buffer_properties) do
        if p:match('^'..prefix) then cmpls[#cmpls + 1] = p end
      end
    end
  end
  table.sort(cmpls)
  return cmpls
end

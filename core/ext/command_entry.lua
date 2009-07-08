-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

textadept.events.add_handler('command_entry_completions_request',
  function(command) -- get a Lua completion list for the command being entered
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
    textadept.command_entry.show_completions(cmpls)
  end)

textadept.events.add_handler('command_entry_command',
  function(command) -- execute a Lua command
    local f, err = loadstring(command)
    if err then error(err) end
    f()
  end)

textadept.events.add_handler('command_entry_keypress',
  function(code)
    local ce = textadept.command_entry
    if code == 65307 then -- escape
      ce.focus() -- toggle focus to hide
      return true
    elseif code == 65289 then -- tab
      textadept.events.handle('command_entry_completions_request',
                              ce.entry_text)
      return true
    end
  end)

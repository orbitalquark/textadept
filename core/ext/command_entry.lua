-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local locale = _G.locale

events.connect('command_entry_command',
  function(command) -- execute a Lua command
    local f, err = loadstring(command)
    if err then error(err) end
    gui.command_entry.focus() -- toggle focus to hide
    f()
  end)

events.connect('command_entry_keypress',
  function(code)
    local ce = gui.command_entry
    local KEYSYMS = keys.KEYSYMS
    if KEYSYMS[code] == 'esc' then
      ce.focus() -- toggle focus to hide
      return true
    elseif KEYSYMS[code] == '\t' then
      local substring = ce.entry_text:match('[%w_.:]+$') or ''
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
          for f in pairs(_SCINTILLA.functions) do
            if f:find('^'..prefix) then cmpls[#cmpls + 1] = f end
          end
        else
          for p in pairs(_SCINTILLA.properties) do
            if p:find('^'..prefix) then cmpls[#cmpls + 1] = p end
          end
        end
      end
      table.sort(cmpls)
      ce.show_completions(cmpls)
      return true
    end
  end)

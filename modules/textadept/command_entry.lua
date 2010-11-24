-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Modified by Jay Gould.

local locale = _G.locale

-- Environment for abbreviated commands.
-- @class table
-- @name env
local env = setmetatable({}, {
  __index = function(t, k)
    local f = buffer[k]
    if f and type(f) == 'function' then
      f = function(...) buffer[k](buffer, ...) end
    elseif f == nil then
      f = view[k] or gui[k] or _G[k]
    end
    return f
  end,
  __newindex = function(t, k, v)
    for _, t2 in ipairs{ buffer, view, gui } do
      if t2[k] ~= nil then
        t2[k] = v
        return
      end
    end
    rawset(t, k, v)
  end,
})

events.connect('command_entry_command',
  function(command) -- execute a Lua command
    local f, err = loadstring(command)
    if err then error(err) end
    gui.command_entry.focus() -- toggle focus to hide
    setfenv(f, env)
    f()
    events.emit('update_ui')
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
      local f, err = loadstring('return ('..path..')')
      if type(f) == "function" then setfenv(f, env) end
      local ok, tbl = pcall(f)
      local cmpls = {}
      prefix = '^'..prefix
      if not ok then -- shorthand notation
        for _, t in ipairs{ buffer, view, gui, _G } do
          for k in pairs(t) do
            if type(k) == 'string' and k:find(prefix) then
              cmpls[#cmpls + 1] = k
            end
          end
        end
        for f in pairs(_SCINTILLA.functions) do
          if f:find(prefix) then cmpls[#cmpls + 1] = f end
        end
        for p in pairs(_SCINTILLA.properties) do
          if p:find(prefix) then cmpls[#cmpls + 1] = p end
        end
      else
        if type(tbl) ~= 'table' then return end
        for k in pairs(tbl) do
          if type(k) == 'string' and k:find(prefix) then
            cmpls[#cmpls + 1] = k
          end
        end
        if path == 'buffer' then
          if o == ':' then
            for f in pairs(_SCINTILLA.functions) do
              if f:find(prefix) then cmpls[#cmpls + 1] = f end
            end
          else
            for p in pairs(_SCINTILLA.properties) do
              if p:find(prefix) then cmpls[#cmpls + 1] = p end
            end
          end
        end
      end
      table.sort(cmpls)
      ce.show_completions(cmpls)
      return true
    end
  end)

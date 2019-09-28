-- Copyright 2018 Mitchell mitchell.att.foicica.com. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- A module for recording, playing, saving, and loading keyboard macros.
-- Menu commands are also recorded.
-- At this time, typing into multiple cursors during macro playback is not
-- supported.
module('textadept.macros')]]
local M = {}

local recording, macro

-- Commands bound to keys to ignore during macro recording, as the command(s)
-- ultimately executed will be recorded in some form.
local ignore
events.connect(events.INITIALIZED, function()
  local m_tools = textadept.menu.menubar[_L['_Tools']]
  ignore = {
    textadept.menu.menubar[_L['_Search']][_L['_Find']][2],
    ui.find.find_incremental,
    m_tools[_L['Select Co_mmand']][2],
    m_tools[_L['_Macros']][_L['Start/Stop _Recording']][2]
  }
end)

-- Event handlers for recording macro-able events.
local function event_recorder(event)
  return function(...) macro[#macro + 1] = {event, ...} end
end
local event_recorders = {
  [events.KEYPRESS] = function(code, shift, control, alt, meta)
    local key = code < 256 and string.char(code) or keys.KEYSYMS[code]
    if key then
      -- Note: this is a simplified version of key handling.
      shift = shift and (code >= 256 or code == 9)
      local key_seq = (control and 'c' or '')..(alt and 'a' or '')..
                      (meta and OSX and 'm' or '')..(shift and 's' or '')..key
      for i = 1, #ignore do if keys[key_seq] == ignore[i] then return end end
    end
    macro[#macro + 1] = {events.KEYPRESS, code, shift, control, alt, meta}
  end,
  [events.MENU_CLICKED] = event_recorder(events.MENU_CLICKED),
  [events.CHAR_ADDED] = event_recorder(events.CHAR_ADDED),
  [events.FIND] = event_recorder(events.FIND),
  [events.REPLACE] = event_recorder(events.REPLACE),
  [events.UPDATE_UI] = function()
    if #keys.keychain == 0 then ui.statusbar_text = _L['Macro recording'] end
  end
}

---
-- Toggles between starting and stopping macro recording.
-- @name record
function M.record()
  if not recording then
    macro = {}
    for event, f in pairs(event_recorders) do events.connect(event, f, 1) end
    ui.statusbar_text = _L['Macro recording']
  else
    for event, f in pairs(event_recorders) do events.disconnect(event, f) end
    ui.statusbar_text = _L['Macro stopped recording']
  end
  recording = not recording
end

---
-- Plays a recorded or loaded macro.
-- @see load
-- @name play
function M.play()
  if recording or not macro then return end
  events.emit(events.KEYPRESS, 27) -- needed to initialize for some reason
  for i = 1, #macro do
    if macro[i][1] == events.CHAR_ADDED then
      local f = buffer[buffer.selection_empty and 'add_text' or 'replace_sel']
      f(buffer, utf8.char(macro[i][2]))
    end
    events.emit(table.unpack(macro[i]))
  end
end

---
-- Saves a recorded macro to file *filename* or the user-selected file.
-- @param filename Optional filename to save the recorded macro to. If `nil`,
--   the user is prompted for one.
-- @name save
function M.save(filename)
  if recording or not macro then return end
  filename = filename or ui.dialogs.filesave{
    title = _L['Save Macro'], with_directory = _USERHOME, with_extension = 'm'
  }
  if not filename then return end
  local f = assert(io.open(filename, 'w'))
  f:write('return {\n')
  for i = 1, #macro do
    f:write('{"', macro[i][1], '",')
    for j = 2, #macro[i] do
      if type(macro[i][j]) == 'string' then f:write('"') end
      f:write(tostring(macro[i][j]))
      f:write(type(macro[i][j]) == 'string' and '",' or ',')
    end
    f:write('},\n')
  end
  f:write('}\n')
  f:close()
end

---
-- Loads a macro from file *filename* or the user-selected file.
-- @param filename Optional macro file to load. If `nil`, the user is prompted
--   for one.
-- @name load
function M.load(filename)
  if recording then return end
  filename = filename or ui.dialogs.fileselect{
    title = _L['Load Macro'], with_directory = _USERHOME, with_extension = 'm'
  }
  if filename then macro = assert(loadfile(filename, 't', {}))() end
end

return M

-- Copyright 2018-2023 Mitchell. See LICENSE.

---
-- A module for recording, playing, saving, and loading keyboard macros.
-- Menu commands are also recorded.
-- At this time, typing into multiple cursors during macro playback is not supported.
-- @module textadept.macros
local M = {}

local recording, macro

-- List of commands bound to keys to ignore during macro recording, as the command(s) ultimately
-- executed will be recorded in some form.
local ignore
events.connect(events.INITIALIZED, function()
  local m_tools = textadept.menu.menubar[_L['Tools']]
  ignore = {
    textadept.menu.menubar[_L['Search']][_L['Find']][2],
    textadept.menu.menubar[_L['Search']][_L['Find Incremental']][2],
    m_tools[_L['Select Command']][2], m_tools[_L['Macros']][_L['Start/Stop Recording']][2]
  }
end)

-- Event handlers for recording macro-able events.
local function event_recorder(event) return function(...) macro[#macro + 1] = {event, ...} end end
local event_recorders = {
  [events.KEYPRESS] = function(key)
    for i = 1, #ignore do if keys[key] == ignore[i] then return end end
    macro[#macro + 1] = {events.KEYPRESS, key}
  end, --
  [events.MENU_CLICKED] = event_recorder(events.MENU_CLICKED),
  [events.CHAR_ADDED] = event_recorder(events.CHAR_ADDED),
  [events.FIND] = event_recorder(events.FIND), --
  [events.REPLACE] = event_recorder(events.REPLACE), --
  [events.UPDATE_UI] = function()
    if #keys.keychain == 0 then ui.statusbar_text = _L['Macro recording'] end
  end
}

--- Toggles between starting and stopping macro recording.
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
function M.play()
  if recording or not macro then return end
  -- If this function is run as a key command, `keys.keychain` cannot be cleared until this
  -- function returns. Emit 'esc' to forcibly clear it so subsequent keypress events can be
  -- properly handled.
  events.emit(events.KEYPRESS, 'esc')
  for _, event in ipairs(macro) do
    if event[1] == events.CHAR_ADDED then
      local f = buffer.selection_empty and buffer.add_text or buffer.replace_sel
      f(buffer, utf8.char(event[2]))
    end
    events.emit(table.unpack(event))
  end
end

---
-- Saves a recorded macro to file *filename* or the user-selected file.
-- @param[opt] filename Optional filename to save the recorded macro to. If `nil`, the user is
--   prompted for one.
function M.save(filename)
  if recording or not macro then return end
  if not assert_type(filename, 'string/nil', 1) then
    filename = ui.dialogs.save{title = _L['Save Macro'], dir = _USERHOME}
    if not filename then return end
  end
  local f = assert(io.open(filename, 'w'))
  f:write('return {\n')
  for _, event in ipairs(macro) do
    f:write(string.format('{%q,', event[1]))
    for i = 2, #event do
      f:write(string.format(type(event[i]) == 'string' and '%q,' or '%s,', event[i]))
    end
    f:write('},\n')
  end
  f:write('}\n'):close()
end

---
-- Loads a macro from file *filename* or the user-selected file.
-- @param[opt] filename Optional macro file to load. If `nil`, the user is prompted for one.
function M.load(filename)
  if recording then return end
  if not assert_type(filename, 'string/nil', 1) then
    filename = ui.dialogs.open{title = _L['Load Macro'], dir = _USERHOME}
    if not filename then return end
  end
  macro = assert(loadfile(filename, 't', {}))()
end

return M

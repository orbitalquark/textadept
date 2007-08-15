-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Support for recording, saving, and playing macros for the textadept module.
module('_m.textadept.macros', package.seeall)

local MACRO_FILE = _HOME..'/saved_macros'

---
-- The list of available macros.
-- Each key is the macro name, and the value is a numerically indexed table of
-- commands. Each command is a table with a structure as follows:
-- { command, wParam, lParam, type = 'function' or 'property' }
-- where command is the buffer function or property name (depending on type)
-- and wParam and lParam are the arguments for it.
-- @class table
-- @name list
list = {}

---
-- [Local table] The currently recording macro.
-- It is a numerically indexed table of commands with each command having the
-- same structure as described in list.
-- @class table
-- @name current
-- @see list
local current = {}

local recording = false

---
-- [Local function] Handles a Scintilla macro notification.
-- If a macro is being recorded, add this command to 'current'.
-- @param msg The Scintilla message ID.
local function macro_notification(msg, wParam, lParam)
  if recording then
    current[#current + 1] = { msg, wParam or '', lParam or '' }
    textadept.statusbar_text = 'Macro recording'
  end
end
textadept.events.add_handler('macro_record', macro_notification)

---
-- Starts recording a macro.
function start_recording()
  if recording then return end
  buffer:start_record()
  current = {}
  recording = true
  textadept.statusbar_text = 'Macro recording'
end

---
-- Stops recording a macro.
-- Each command's msg in the recorded macro is changed to the name of the
-- message and the type of the command is changed appropriately (function or
-- property). Then the user is prompted for a macro name and the macro is saved
-- to the current macro list and macro file.
function stop_recording()
  if not recording then return end
  buffer:stop_record()
  recording = false
  local textadept = textadept
  local bf, bp = textadept.buffer_functions, textadept.buffer_properties
  local macro_name =
    io.popen('zenity --entry --text "Macro name:"'):read('*all'):sub(1, -2)
  if #macro_name > 0 then
    for _, command in ipairs(current) do
      command.type = 'function'
      local msg = command[1]
      for f, t in pairs(bf) do
        if t[1] == msg then command[1] = f break end
      end
      if type( command[1] ) ~= 'string' then
        command.type = 'property'
        for p, t in pairs(bp) do
          if t[1] == msg or t[2] == msg then command[1] = p break end
        end
      end
    end
    list[macro_name] = current
    save()
    textadept.statusbar_text = 'Macro saved'
    textadept.events.handle('macro_saved')
  else
    textadept.statusbar_text = 'Macro not saved'
  end
end

---
-- Toggles between recording a macro and not recording one.
function toggle_record()
  (not recording and start_recording or stop_recording)()
end

---
-- Plays a specified macro.
-- @param macro_name The name of the macro to play. If none specified, the user
--   is prompted to choose one from a list of available macros.
function play(macro_name)
  if not macro_name then
    local macro_list = ''
    for name in pairs(list) do macro_list = macro_list..name..' ' end
    macro_name = io.popen('zenity --list --text "Select a Macro" '..
      '--column Name '..macro_list):read('*all'):sub(1, -2)
  end
  local macro = list[macro_name]
  if not macro then return end
  local buffer = buffer
  for _, command in ipairs(macro) do
    local cmd, wParam, lParam = unpack(command)
    if command.type == 'function' then
      buffer[cmd](buffer, wParam, lParam)
    else
      buffer[cmd] = #wParam > 0 and wParam or lParam
    end
  end
end

---
-- Deletes a specified macro.
-- @param macro_name The name of the macro to delete.
function delete(macro_name)
  if list[macro_name] then
    list[macro_name] = nil
    save()
    textadept.events.handle('macro_deleted')
  end
end

---
-- Saves the current list of macros to a specified file.
-- @param filename The absolute path to the file to save the macros to.
function save(filename)
  if not filename then filename = MACRO_FILE end
  local f = assert( io.open(filename, 'w') )
  for name, macro in pairs(list) do
    f:write(name, '\n')
    for _, command in ipairs(macro) do
      f:write( ("%s\t%s\t%s\t%s\n"):format( command.type, unpack(command) ) )
    end
    f:write('\n')
  end
  f:close()
end

---
-- Loads macros from a specified file.
-- @param filename The absolute path to the file to load the macros from.
function load(filename)
  if not filename then filename = MACRO_FILE end
  local f = io.open(filename)
  if not f then return end
  local name, current_macro
  for line in f:lines() do
    if not name then -- new macro
      name = line
      current_macro = {}
    else
      if line == '' then -- finished; save current macro
        list[name] = current_macro
        name = nil
      else
        local type, cmd, wParam, lParam =
          line:match('^([^\t]+)\t([^\t]+)\t?([^\t]*)\t?(.*)$')
        if type and cmd then
          local command = { cmd, wParam, lParam }
          command.type = type
          current_macro[#current_macro + 1] = command
        end
      end
    end
  end
end

load() -- load saved macros on startup

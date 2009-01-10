-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Support for recording, saving, and playing macros for the textadept module.
--
-- Events:
--   macro_saved()
--   macro_deleted()
module('_m.textadept.macros', package.seeall)

local MACRO_FILE = _HOME..'/saved_macros'

---
-- The list of available macros.
-- Each key is the macro name, and the value is a numerically indexed table of
-- commands. Each command is a table with a structure as follows:
-- { command, wParam, lParam }
-- where command is the buffer function and wParam and lParam are the arguments
-- for it.
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
    current[#current + 1] = { msg, wParam or 0, lParam or 0 }
    textadept.statusbar_text = textadept.locale.M_TEXTADEPT_MACRO_RECORDING
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
-- message Then the user is prompted for a macro name and the macro is saved to
-- the current macro list and macro file.
function stop_recording()
  if not recording then return end
  buffer:stop_record()
  recording = false
  local locale = textadept.locale
  local ret, macro_name =
    cocoa_dialog('standard-inputbox', {
      ['informative-text'] = locale.M_TEXTADEPT_MACRO_SAVE_TITLE,
      text = locale.M_TEXTADEPT_MACRO_SAVE_TEXT,
      ['no-newline'] = true
    }):match('^(%d)\n([^\n]+)$')

  if ret == '1' and macro_name and #macro_name > 0 then
    for _, command in ipairs(current) do
      local msg = command[1]
      for f, t in pairs(textadept.buffer_functions) do
        if t[1] == msg then command[1] = f break end
      end
    end
    list[macro_name] = current
    save()
    textadept.statusbar_text = locale.M_TEXTADEPT_MACRO_SAVED
    textadept.events.handle('macro_saved')
  else
    textadept.statusbar_text = locale.M_TEXTADEPT_MACRO_NOT_SAVED
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
    local locale = textadept.locale
    local macros = {}
    for name, _ in pairs(list) do macros[#macros + 1] = name end
    if #macros > 0 then
      local ret
      ret, macro_name =
        cocoa_dialog('standard-dropdown', {
          title = locale.M_TEXTADEPT_MACRO_SELECT_TITLE,
          text = locale.M_TEXTADEPT_MACRO_SELECT_TEXT,
          items = '"'..table.concat(macros, '" "')..'"',
          ['string-output'] = true,
          ['no-newline'] = true
        }):match('^([^\n]+)\n([^\n]+)$')
      if ret == 'Cancel' then return end
    end
  end
  local macro = list[macro_name]
  if not macro then return end
  local buffer = buffer
  local bf = textadept.buffer_functions
  for _, command in ipairs(macro) do
    local cmd, wParam, lParam = unpack(command)
    local _, _, p1_type, p2_type  = unpack(bf[cmd])
    if p2_type == 7 and p1_type == 0 or p1_type == 2 then -- single string param
      buffer[cmd](buffer, lParam)
    else
      buffer[cmd](buffer, wParam, lParam)
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
  local f = assert(io.open(filename, 'w'))
  for name, macro in pairs(list) do
    f:write(name, '\n')
    for _, command in ipairs(macro) do
      local msg, wParam, lParam = unpack(command)
      if type(lParam) == 'string' then
        lParam =
          lParam:gsub('[\t\n\r\f]',
                      { ['\t'] = '\\t', ['\n'] = '\\n', ['\r'] = '\\r',
                        ['\f'] = '\\f' })
      end
      f:write(("%s\t%s\t%s\n"):format(msg, wParam, lParam))
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
        local cmd, wParam, lParam = line:match('^([^\t]+)\t([^\t]+)\t(.*)$')
        if cmd and wParam and lParam then
          lParam =
            lParam:gsub('\\[tnrf]',
                        { ['\\t'] = '\t', ['\\n'] = '\n', ['\\r'] = '\r',
                          ['\\f'] = '\f' })
          local num = wParam:match('^-?%d+$')
          if num then wParam = tonumber(num) end
          num = lParam:match('^-?%d+$')
          if num then lParam = tonumber(num) end
          local command = { cmd, wParam, lParam }
          current_macro[#current_macro + 1] = command
        end
      end
    end
  end
end

load() -- load saved macros on startup

-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

local M = ui.command_entry

--[[ This comment is for LuaDoc.
---
-- Textadept's Command Entry.
--
-- ## Modes
--
-- The command entry supports multiple [modes](#keys.Modes) that have their own
-- sets of key bindings stored in a separate table in `_G.keys` under a mode
-- prefix key. Mode names are arbitrary, but cannot conflict with lexer names or
-- key sequence strings (e.g. `'lua'` or `'send'`) due to the method Textadept
-- uses for looking up key bindings. An example mode is "lua_command" mode for
-- executing Lua commands:
--
--     local function complete_lua() ... end
--     local function execute_lua() ... end
--     keys['ce'] = {ui.command_entry.enter_mode, 'lua_command'}
--     keys.lua_command = {
--       ['\t'] = complete_lua,
--       ['\n'] = {ui.command_entry.finish_mode, execute_lua}
--     }
--
-- In this case, `Ctrl+E` opens the command entry and enters "lua_command" key
-- mode where the `Tab` and `Enter` keys have special, defined functionality.
-- (By default, Textadept pre-defines `Esc` to exit any command entry mode.)
-- `Tab` shows a list of Lua completions for the entry text and `Enter` exits
-- "lua_command" key mode and executes the entered code. The command entry
-- handles all other keys normally.
-- @field entry_text (string)
--   The text in the command entry.
module('ui.command_entry')]]

---
-- Opens the command entry in key mode *mode*.
-- Key bindings will be looked up in `keys[mode]` instead of `keys`. The `Esc`
-- key exits the current mode, closes the command entry, and restores normal key
-- lookup.
-- This function is useful for binding keys to enter a command entry mode.
-- @param mode The key mode to enter into, or `nil` to exit the current mode.
-- @usage keys['ce'] = {ui.command_entry.enter_mode, 'command_entry'}
-- @see _G.keys.MODE
-- @name enter_mode
function M.enter_mode(mode)
  keys.MODE = mode
  if mode and not keys[mode]['esc'] then keys[mode]['esc'] = M.enter_mode end
  -- In curses, M.focus() does not return immediately, so the key sequence that
  -- called M.focus() is still on the keychain. Clear it.
  if CURSES then keys.clear_key_sequence() end
  M.focus()
end

---
-- Exits the current key mode, closes the command entry, and calls function *f*
-- (if given) with the command entry's text as an argument.
-- This is useful for binding keys to exit a command entry mode and perform an
-- action with the entered text.
-- @param f Optional function to call. It should accept the command entry text
--   as an argument.
-- @usage keys['\n'] = {ui.command_entry.finish_mode, ui.print}
-- @name finish_mode
function M.finish_mode(f)
  M.enter_mode(nil)
  if f then f(M.entry_text) end
  if CURSES then return false end -- propagate to exit CDK entry on Enter
end

-- Environment for abbreviated commands.
-- @class table
-- @name env
local env = setmetatable({}, {
  __index = function(t, k)
    local f = buffer[k]
    if f and type(f) == 'function' then
      f = function(...) buffer[k](buffer, ...) end
    elseif f == nil then
      f = view[k] or ui[k] or _G[k]
    end
    return f
  end,
  __newindex = function(t, k, v)
    for _, t2 in ipairs{buffer, view, ui} do
      if t2[k] ~= nil then t2[k] = v return end
    end
    rawset(t, k, v)
  end,
})

-- Executes string *code* as Lua code that is subject to an "abbreviated"
-- environment.
-- In this environment, the contents of the `buffer`, `view`, and `ui` tables
-- are also considered as global functions and fields.
-- Prints the results of '=' expressions like in the Lua prompt.
-- @param code The Lua code to execute.
local function execute_lua(code)
  if code:find('^=') then code = 'return '..code:sub(2) end
  local result = assert(load(code, nil, 'bt', env))()
  if result ~= nil or code:find('^return ') then ui.print(result) end
  events.emit(events.UPDATE_UI)
end
args.register('-e', '--execute', 1, execute_lua, 'Execute Lua code')

-- Shows a set of Lua code completions for string *code* or `entry_text`.
-- Completions are subject to an "abbreviated" environment where the `buffer`,
-- `view`, and `ui` tables are also considered as globals.
-- @param code The Lua code to complete. The default value is the value of
--   `entry_text`.
local function complete_lua(code)
  if not code then code = M.entry_text end
  local symbol, op, part = code:match('([%w_.]-)([%.:]?)([%w_]*)$')
  local ok, result = pcall((load('return ('..symbol..')', nil, 'bt', env)))
  local cmpls = {}
  part = '^'..part
  if (not ok or type(result) ~= 'table') and symbol ~= '' then return end
  if not ok then -- shorthand notation
    local pool = {
      buffer, view, ui, _G, _SCINTILLA.functions, _SCINTILLA.properties
    }
    for i = 1, #pool do
      for k in pairs(pool[i]) do
        if type(k) == 'string' and k:find(part) then cmpls[#cmpls + 1] = k end
      end
    end
  else
    for k in pairs(result) do
      if type(k) == 'string' and k:find(part) then cmpls[#cmpls + 1] = k end
    end
    if symbol == 'buffer' and op == ':' then
      for f in pairs(_SCINTILLA.functions) do
        if f:find(part) then cmpls[#cmpls + 1] = f end
      end
    elseif symbol == 'buffer' and op == '.' then
      for p in pairs(_SCINTILLA.properties) do
        if p:find(part) then cmpls[#cmpls + 1] = p end
      end
    end
  end
  table.sort(cmpls)
  M.show_completions(cmpls)
end

-- Define key mode for entering Lua commands.
keys.lua_command = {
  ['\t'] = complete_lua, ['\n'] = {M.finish_mode, execute_lua}
}

-- Pass command entry keys to the default keypress handler.
-- Since the command entry is designed to be modal, command entry key bindings
-- should stay separate from editor key bindings.
events.connect(events.COMMAND_ENTRY_KEYPRESS, function(...)
  if keys.MODE then return events.emit(events.KEYPRESS, ...) end
end)

--[[ The function below is a Lua C function.

---
-- Opens the Lua command entry.
-- @class function
-- @name focus
local focus

---
-- Shows completion list *completions* for the current word prefix.
-- Word prefix characters are alphanumerics and underscores. On selection, the
-- word prefix is replaced with the completion.
-- @param completions The table of completions to show. Non-string values are
--   ignored.
-- @class function
-- @name show_completions
local show_completions
]]

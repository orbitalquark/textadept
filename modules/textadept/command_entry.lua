-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

local M = gui.command_entry

--[[ This comment is for LuaDoc.
---
-- Textadept's Command Entry.
--
-- ## Modes
--
-- The command entry supports multiple [modes][] that have their own sets of key
-- bindings stored in a separate table in `_G.keys` under a mode prefix key.
-- Mode names are arbitrary, but cannot conflict with lexer names or key
-- sequence strings (e.g. `'lua'` or `'send'`) due to the method used for
-- looking up key bindings. An example mode is "lua_command" mode for executing
-- Lua commands:
--
--     local gui_ce = gui.command_entry
--     keys['ce'] = {gui_ce.enter_mode, 'lua_command'}
--     keys.lua_command = {
--       ['\t'] = gui_ce.complete_lua,
--       ['\n'] = {gui_ce.finish_mode, gui_ce.execute_lua}
--     }
--
-- In this case, `Ctrl+E` opens the command entry and enters "lua_command" key
-- mode where the `Tab` and `Enter` keys have special, defined functionality.
-- (By default, `Esc` is pre-defined to exit any command entry mode.) `Tab`
-- shows a list of Lua completions for the entry text and `Enter` exits
-- "lua_command" key mode and executes the entered code. All other keys are
-- handled normally by the command entry.
--
-- It is important to note that while in any command entry key mode, all editor
-- key bindings are ignored -- even if the editor, not the command entry, has
-- focus. You must first exit the key mode by pressing `Esc` (or `Enter` in the
-- case of the above "lua_command" key mode).
--
-- [modes]: keys.html#Modes
-- @field entry_text (string)
--   The text in the entry.
module('gui.command_entry')]]

---
-- Opens the command entry in key mode *mode*.
-- Key bindings will be looked up in `keys[mode]` instead of `keys`. The `Esc`
-- (`⎋` on Mac OSX | `Esc` in curses) key exits the current mode, closes the
-- command entry, and restores normal key lookup.
-- This function is useful for binding keys to enter a command entry mode.
-- @param mode The key mode to enter into, or `nil` to exit the current mode.
-- @usage keys['ce'] = {gui.command_entry.enter_mode, 'command_entry'}
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
-- (if given) with the command entry text as an argument.
-- This is useful for binding keys to exit a command entry mode and perform an
-- action with the entered text.
-- @param f Optional function to call. It should accept the command entry text
--   as an argument.
-- @usage keys['\n'] = {gui.command_entry.finish_mode, gui.print}
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
      f = view[k] or gui[k] or _G[k]
    end
    return f
  end,
  __newindex = function(t, k, v)
    for _, t2 in ipairs{buffer, view, gui} do
      if t2[k] ~= nil then t2[k] = v return end
    end
    rawset(t, k, v)
  end,
})

---
-- Executes string *code* as Lua code.
-- Code is subject to an "abbreviated" environment where the `buffer`, `view`,
-- and `gui` tables are also considered as globals.
-- @param code The Lua code to execute.
-- @name execute_lua
function M.execute_lua(code)
  local f, err = load(code, nil, 'bt', env)
  if err then error(err) end
  f()
  events.emit(events.UPDATE_UI)
end
args.register('-e', '--execute', 1, M.execute_lua, 'Execute Lua code')

---
-- Shows a set of Lua code completions for string *code* or `entry_text`.
-- Completions are subject to an "abbreviated" environment where the `buffer`,
-- `view`, and `gui` tables are also considered as globals.
-- @param code The Lua code to complete. The default value is the value of
--   `entry_text`.
-- @name complete_lua
function M.complete_lua(code)
  local substring = (code or M.entry_text):match('[%w_.:]+$') or ''
  local path, op, prefix = substring:match('^([%w_.:]-)([.:]?)([%w_]*)$')
  local f, err = load('return ('..path..')', nil, 'bt', env)
  local ok, result = pcall(f)
  local cmpls = {}
  prefix = '^'..prefix
  if not ok then -- shorthand notation
    for _, t in ipairs{buffer, view, gui, _G} do
      for k in pairs(t) do
        if type(k) == 'string' and k:find(prefix) then cmpls[#cmpls + 1] = k end
      end
    end
    for f in pairs(_SCINTILLA.functions) do
      if f:find(prefix) then cmpls[#cmpls + 1] = f end
    end
    for p in pairs(_SCINTILLA.properties) do
      if p:find(prefix) then cmpls[#cmpls + 1] = p end
    end
  else
    if type(result) ~= 'table' then return end
    for k in pairs(result) do
      if type(k) == 'string' and k:find(prefix) then cmpls[#cmpls + 1] = k end
    end
    if path == 'buffer' and op == ':' then
      for f in pairs(_SCINTILLA.functions) do
        if f:find(prefix) then cmpls[#cmpls + 1] = f end
      end
    elseif path == 'buffer' and op == '.' then
      for p in pairs(_SCINTILLA.properties) do
        if p:find(prefix) then cmpls[#cmpls + 1] = p end
      end
    end
  end
  table.sort(cmpls)
  M.show_completions(cmpls)
end

-- Pass command entry keys to the default keypress handler.
-- Since the command entry is designed to be modal, command entry key bindings
-- should stay separate from editor key bindings.
events.connect(events.COMMAND_ENTRY_KEYPRESS, function(...)
  if keys.MODE then return events.emit(events.KEYPRESS, ...) end
end)

--[[ The function below is a Lua C function.

---
-- Focuses the command entry.
-- @class function
-- @name focus
local focus

---
-- Shows the completion list *completions* for the current word prefix.
-- Word prefix characters are alphanumerics and underscores. On selection, the
-- word prefix is replaced with the completion.
-- @param completions The table of completions to show. Non-string values are
--   ignored.
-- @class function
-- @name show_completions
local show_completions
]]

-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.
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
--     local function run_lua() ... end
--     keys['ce'] = function() ui.command_entry.enter_mode('lua_command') end
--     keys.lua_command = {
--       ['\t'] = complete_lua,
--       ['\n'] = function() return ui.command_entry.finish_mode(run_lua) end
--     }
--
-- In this case, `Ctrl+E` opens the command entry and enters "lua_command" key
-- mode where the `Tab` and `Enter` keys have special, defined functionality.
-- (By default, Textadept pre-defines `Esc` to exit any command entry mode.)
-- `Tab` shows a list of Lua completions for the entry text and `Enter` exits
-- "lua_command" key mode and executes the entered code. The command entry
-- handles all other editing and movement keys normally.
-- @field height (number)
--   The height in pixels of the command entry.
module('ui.command_entry')]]

---
-- A metatable with typical platform-specific key bindings for text entries.
-- This metatable may be used to add basic editing keys to command entry modes.
-- It is automatically added to command entry modes unless a metatable was
-- previously set.
-- @usage setmetatable(keys.my_mode, ui.command_entry.editing_keys)
-- @class table
-- @name editing_keys
M.editing_keys = {__index = {
  -- Note: cannot use `M.cut`, `M.copy`, etc. since M is never considered the
  -- global buffer.
  [not OSX and 'cx' or 'mx'] = function() M:cut() end,
  [not OSX and 'cc' or 'mc'] = function() M:copy() end,
  [not OSX and 'cv' or 'mv'] = function() M:paste() end,
  [not OSX and not CURSES and 'ca' or 'ma'] = function() M:select_all() end,
  [not OSX and 'cz' or 'mz'] = function() M:undo() end,
  [not OSX and 'cZ' or 'mZ'] = function() M:redo() end,
  [not OSX and 'cy' or '\0'] = function() M:redo() end,
  -- Movement keys.
  [(OSX or CURSES) and 'cf' or '\0'] = function() M:char_right() end,
  [(OSX or CURSES) and 'cb' or '\0'] = function() M:char_left() end,
  [(OSX or CURSES) and 'ca' or '\0'] = function() M:vc_home() end,
  [(OSX or CURSES) and 'ce' or '\0'] = function() M:line_end() end,
  [(OSX or CURSES) and 'cd' or '\0'] = function() M:clear() end
}}

---
-- Opens the command entry in key mode *mode*, highlighting text with lexer name
-- *lexer*, and displaying *height* number of lines at a time.
-- Key bindings will be looked up in `keys[mode]` instead of `keys`. The `Esc`
-- key exits the current mode, closes the command entry, and restores normal key
-- lookup.
-- This function is useful for binding keys to enter a command entry mode.
-- @param mode The key mode to enter into, or `nil` to exit the current mode.
-- @param lexer Optional string lexer name to use for command entry text. The
--   default value is `'text'`.
-- @param height Optional number of lines to display in the command entry. The
--   default value is `1`.
-- @usage keys['ce'] =
--   function() ui.command_entry.enter_mode('command_entry') end
-- @see _G.keys.MODE
-- @name enter_mode
function M.enter_mode(mode, lexer, height)
  if M:auto_c_active() then M:auto_c_cancel() end -- may happen in curses
  keys.MODE = mode
  if mode then
    local mkeys = keys[mode]
    if not mkeys['esc'] then mkeys['esc'] = M.enter_mode end
    if not getmetatable(mkeys) then setmetatable(mkeys, M.editing_keys) end
  end
  M:select_all()
  M.focus()
  M:set_lexer(lexer or 'text')
  M.height = M:text_height(0) * (height or 1)
end

---
-- Exits the current key mode, closes the command entry, and calls function *f*
-- (if given) with the command entry's text as an argument.
-- This is useful for binding keys to exit a command entry mode and perform an
-- action with the entered text.
-- @param f Optional function to call. It should accept the command entry text
--   as an argument.
-- @usage keys['\n'] =
--   function() return ui.command_entry.finish_mode(ui.print) end
-- @name finish_mode
function M.finish_mode(f)
  if M:auto_c_active() then return false end -- allow Enter to autocomplete
  M.enter_mode(nil)
  if f then f(M:get_text()) end
end

-- Environment for abbreviated Lua commands.
-- @class table
-- @name env
local env = setmetatable({}, {
  __index = function(_, k)
    local f = buffer[k]
    if f and type(f) == 'function' then
      f = function(...) return buffer[k](buffer, ...) end
    elseif f == nil then
      f = view[k] or ui[k] or _G[k]
    end
    return f
  end,
  __newindex = function(self, k, v)
    local ok, value = pcall(function() return buffer[k] end)
    if ok and value ~= nil or not ok and value:find('write-only property') then
      buffer[k] = v return
    end
    if view[k] ~= nil then view[k] = v return end
    if ui[k] ~= nil then ui[k] = v return end
    rawset(self, k, v)
  end,
})

-- Executes string *code* as Lua code that is subject to an "abbreviated"
-- environment.
-- In this environment, the contents of the `buffer`, `view`, and `ui` tables
-- are also considered as global functions and fields.
-- Prints the results of expressions like in the Lua prompt. Also invokes bare
-- functions as commands.
-- @param code The Lua code to execute.
local function run_lua(code)
  if code:find('^=') then code = code:sub(2) end -- for compatibility
  local f, errmsg = load('return '..code, nil, 't', env)
  if not f then f, errmsg = load(code, nil, 't', env) end
  local result = assert(f, errmsg)()
  if type(result) == 'function' then result = result() end
  if type(result) == 'table' then
    local items = {}
    for k, v in pairs(result) do
      items[#items + 1] = tostring(k)..' = '..tostring(v)
    end
    table.sort(items)
    result = '{'..table.concat(items, ', ')..'}'
    if buffer.edge_column > 0 and #result > buffer.edge_column then
      local indent = string.rep(' ', buffer.tab_width)
      result = '{\n'..indent..table.concat(items, ',\n'..indent)..'\n}'
    end
  end
  if result ~= nil or code:find('^return ') then ui.print(result) end
  events.emit(events.UPDATE_UI)
end
args.register('-e', '--execute', 1, run_lua, 'Execute Lua code')

-- Shows a set of Lua code completions for the entry's text, subject to an
-- "abbreviated" environment where the `buffer`, `view`, and `ui` tables are
-- also considered as globals.
local function complete_lua()
  local line, pos = M:get_cur_line()
  local symbol, op, part = line:sub(1, pos):match('([%w_.]-)([%.:]?)([%w_]*)$')
  local ok, result = pcall((load('return ('..symbol..')', nil, 'bt', env)))
  if (not ok or type(result) ~= 'table') and symbol ~= '' then return end
  local cmpls = {}
  part = '^'..part
  if not ok or symbol == 'buffer' then
    local pool
    if not ok then
      -- Consider `buffer`, `view`, `ui` as globals too.
      pool = {buffer, view, ui, _G, _SCINTILLA.functions, _SCINTILLA.properties}
    else
      pool = op == ':' and {_SCINTILLA.functions} or
                           {_SCINTILLA.properties, _SCINTILLA.constants}
    end
    for i = 1, #pool do
      for k in pairs(pool[i]) do
        if type(k) == 'string' and k:find(part) then cmpls[#cmpls + 1] = k end
      end
    end
  end
  if ok then
    for k, v in pairs(result) do
      if type(k) == 'string' and k:find(part) and
         (op == '.' or type(v) == 'function') then
        cmpls[#cmpls + 1] = k
      end
    end
  end
  table.sort(cmpls)
  M:auto_c_show(#part - 1, table.concat(cmpls, ' '))
end

-- Define key mode for entering Lua commands.
keys.lua_command = {
  ['\t'] = complete_lua,
  ['\n'] = function() return M.finish_mode(run_lua) end
}

-- Configure the command entry's default properties.
events.connect(events.INITIALIZED, function()
  M.h_scroll_bar, M.v_scroll_bar = false, false
  M.margin_width_n[0], M.margin_width_n[1], M.margin_width_n[2] = 0, 0, 0
  M.call_tip_position = true
end)

--[[ The function below is a Lua C function.

---
-- Opens the command entry.
-- @class function
-- @name focus
local focus
]]

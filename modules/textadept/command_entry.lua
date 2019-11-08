-- Copyright 2007-2019 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

local M = ui.command_entry

--[[ This comment is for LuaDoc.
---
-- Textadept's Command Entry.
-- It supports multiple modes that each have their own functionality, such as
-- running Lua code, searching for text incrementally, and filtering text
-- through shell commands.
-- @field height (number)
--   The height in pixels of the command entry.
module('ui.command_entry')]]

---
-- A metatable with typical platform-specific key bindings for text entries.
-- This metatable may be used to add basic editing and movement keys to command
-- entry modes. It is automatically added to command entry modes unless a
-- metatable was previously set.
-- @usage setmetatable(mode_keys, ui.command_entry.editing_keys)
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
  local ok, result = pcall((load('return ('..symbol..')', nil, 't', env)))
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

-- Key mode for entering Lua commands.
-- @class table
-- @name lua_mode_keys
local lua_mode_keys = {['\t'] = complete_lua}

---
-- Opens the command entry, subjecting it to any key bindings defined in table
-- *mode_keys*, highlighting text with lexer name *lexer*, and displaying
-- *height* number of lines at a time, and then when the `Enter` key is pressed,
-- closes the command entry and calls function *f* (if non-`nil`) with the
-- command entry's text as an argument.
-- By default with no arguments given, opens a Lua command entry.
-- The command entry does not respond to Textadept's default key bindings, but
-- instead to the key bindings defined in *mode_keys* and in
-- `ui.command_entry.editing_keys`.
-- @param f Optional function to call upon pressing `Enter` in the command
--   entry, ending the mode. It should accept the command entry text as an
--   argument.
-- @param mode_keys Optional table of key bindings to respond to. This is in
--   addition to the basic editing and movement keys defined in
--   `ui.command_entry.editing_keys`.
--   `Esc` and `Enter` are automatically defined to cancel and finish the
--   command entry, respectively.
--   This parameter may be omitted completely.
-- @param lexer Optional string lexer name to use for command entry text. The
--   default value is `'text'`.
-- @param height Optional number of lines to display in the command entry. The
--   default value is `1`.
-- @see editing_keys
-- @usage ui.command_entry.run(ui.print)
-- @name run
function M.run(f, mode_keys, lexer, height)
  if M:auto_c_active() then M:auto_c_cancel() end -- may happen in curses
  if not f and not mode_keys then
    f, mode_keys, lexer = run_lua, lua_mode_keys, 'lua'
  elseif type(mode_keys) == 'string' then
    mode_keys, lexer, height = {}, mode_keys, lexer
  elseif not mode_keys then
    mode_keys = {}
  end
  if not mode_keys['esc'] then mode_keys['esc'] = M.focus end -- hide
  mode_keys['\n'] = mode_keys['\n'] or function()
    if M:auto_c_active() then return false end -- allow Enter to autocomplete
    M.focus() -- hide
    if f then f((M:get_text())) end
  end
  if not getmetatable(mode_keys) then
    setmetatable(mode_keys, M.editing_keys)
  end
  M:select_all()
  M.focus()
  M:set_lexer(lexer or 'text')
  M.height = M:text_height(0) * (height or 1)
  keys._command_entry, keys.MODE = mode_keys, '_command_entry'
end

-- Redefine ui.command_entry.focus() to clear any current key mode on hide/show.
local orig_focus = M.focus
M.focus = function()
  keys.MODE = nil
  orig_focus()
end

-- Configure the command entry's default properties.
-- Also find the key binding for `textadept.editing.show_documentation` and use
-- it to show Lua documentation in the Lua command entry.
events.connect(events.INITIALIZED, function()
  M.h_scroll_bar, M.v_scroll_bar = false, false
  M.margin_width_n[0], M.margin_width_n[1], M.margin_width_n[2] = 0, 0, 0
  M.call_tip_position = true
  for key, f in pairs(keys) do
    if f == textadept.editing.show_documentation then
      lua_mode_keys[key] = function()
        -- Temporarily change _G.buffer since ui.command_entry is the "active"
        -- buffer.
        local orig_buffer = _G.buffer
        _G.buffer = ui.command_entry
        textadept.editing.show_documentation()
        _G.buffer = orig_buffer
      end
      break
    end
  end
end)

--[[ The function below is a Lua C function.

---
-- Opens the command entry.
-- @class function
-- @name focus
local focus
]]

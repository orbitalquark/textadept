-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

local M = ui.command_entry

--[[ This comment is for LuaDoc.
---
-- Textadept's Command Entry.
-- It supports multiple modes that each have their own functionality (such as
-- running Lua code and filtering text through shell commands) and history.
-- @field height (number)
--   The height in pixels of the command entry.
-- @field active (boolean)
--   Whether or not the command entry is active.
module('ui.command_entry')]]

-- Command history per mode.
-- The current mode is in the `mode` field.
-- @class table
-- @name history
local history = {}

-- Cycles through command history for the current mode.
-- @param prev Flag that indicates whether to cycle to the previous command or
--   the next one.
local function cycle_history(prev)
  if M:auto_c_active() then M[prev and 'line_up' or 'line_down'](M) return end
  local mode_history = history[history.mode]
  if not mode_history or prev and mode_history.pos <= 1 then return end
  if not prev and mode_history.pos >= #mode_history then return end
  M:line_delete()
  local i, bound = prev and -1 or 1, prev and 1 or #mode_history
  mode_history.pos = math[prev and 'max' or 'min'](mode_history.pos + i, bound)
  M:add_text(mode_history[mode_history.pos])
end

---
-- A metatable with typical platform-specific key bindings for text entries.
-- This metatable may be used to add basic editing and movement keys to command
-- entry modes. It is automatically added to command entry modes unless a
-- metatable was previously set.
-- @usage setmetatable(mode_keys, ui.command_entry.editing_keys)
-- @class table
-- @name editing_keys
M.editing_keys = {__index = {}}

-- Fill in default platform-specific key bindings.
local ekeys, plat = M.editing_keys.__index, CURSES and 3 or OSX and 2 or 1
local bindings = {
  -- Note: cannot use `M.cut`, `M.copy`, etc. since M is never considered the
  -- global buffer.
  [function() M:undo() end] = {'ctrl+z', 'cmd+z', 'ctrl+z'},
  [function() M:undo() end] = {nil, nil, 'meta+z'},
  [function() M:redo() end] = {'ctrl+y', 'cmd+Z', 'ctrl+y'},
  [function() M:redo() end] = {'ctrl+Z', nil, 'meta+Z'},
  [function() M:cut() end] = {'ctrl+x', 'cmd+x', 'ctrl+x'},
  [function() M:copy() end] = {'ctrl+c', 'cmd+c', 'ctrl+c'},
  [function() M:paste() end] = {'ctrl+v', 'cmd+v', 'ctrl+v'},
  [function() M:select_all() end] = {'ctrl+a', 'cmd+a', 'meta+a'},
  [function() cycle_history(true) end] = {'up', 'up', 'up'},
  [cycle_history] = {'down', 'down', 'down'},
  -- Movement keys.
  [function() M:char_right() end] = {nil, 'ctrl+f', 'ctrl+f'},
  [function() M:char_left() end] = {nil, 'ctrl+b', 'ctrl+b'},
  [function() M:vc_home() end] = {nil, 'ctrl+a', 'ctrl+a'},
  [function() M:line_end() end] = {nil, 'ctrl+e', 'ctrl+e'},
  [function() M:clear() end] = {nil, 'ctrl+d', 'ctrl+d'}
}
for f, plat_keys in pairs(bindings) do
  if plat_keys[plat] then ekeys[plat_keys[plat]] = f end
end

-- Environment for abbreviated Lua commands.
-- @class table
-- @name env
local env = setmetatable({}, {
  __index = function(_, k)
    if type(buffer[k]) == 'function' then
      return function(...) return buffer[k](buffer, ...) end
    elseif type(view[k]) == 'function' then
      return function(...) view[k](view, ...) end -- do not return a value
    end
    return buffer[k] or view[k] or ui[k] or _G[k]
  end,
  __newindex = function(self, k, v)
    local ok, value = pcall(function() return buffer[k] end)
    if ok and value ~= nil or not ok and value:find('write-only property') then
      buffer[k] = v
      return
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
  local f, errmsg = load('return ' .. code, nil, 't', env)
  if not f then f, errmsg = load(code, nil, 't', env) end
  local result = assert(f, errmsg)()
  if type(result) == 'function' then result = result() end
  if type(result) == 'table' then
    local items = {}
    for k, v in pairs(result) do
      items[#items + 1] = string.format('%s = %s', k, v)
    end
    table.sort(items)
    result = string.format('{%s}', table.concat(items, ', '))
    if view.edge_column > 0 and #result > view.edge_column then
      local indent = string.rep(' ', buffer.tab_width)
      result = string.format(
        '{\n%s%s\n}', indent, table.concat(items, ',\n' .. indent))
    end
  end
  if result ~= nil or code:find('^return ') then ui.print(result) end
  events.emit(events.UPDATE_UI, 0)
end
args.register('-e', '--execute', 1, run_lua, 'Execute Lua code')

-- Shows a set of Lua code completions for the entry's text, subject to an
-- "abbreviated" environment where the contents of the `buffer`, `view`, and
-- `ui` tables are also considered as globals.
local function complete_lua()
  local line, pos = M:get_cur_line()
  local symbol, op, part = line:sub(1, pos - 1):match(
    '([%w_.]-)([%.:]?)([%w_]*)$')
  local ok, result = pcall(
    (load(string.format('return (%s)', symbol), nil, 't', env)))
  if (not ok or type(result) ~= 'table') and symbol ~= '' then return end
  local cmpls = {}
  part = '^' .. part
  local sep = string.char(M.auto_c_type_separator)
  local XPM = textadept.editing.XPM_IMAGES
  if not ok or symbol == 'buffer' then
    local sci = _SCINTILLA
    local global_envs =
      not ok and {buffer, view, ui, _G, sci.functions, sci.properties} or
      op == ':' and {sci.functions} or {sci.properties, sci.constants}
    for _, env in ipairs(global_envs) do
      for k, v in pairs(env) do
        if type(k) == 'string' and k:find(part) then
          local xpm = (type(v) == 'function' or env == sci.functions) and
            XPM.METHOD or XPM.VARIABLE
          cmpls[#cmpls + 1] = k .. sep .. xpm
        end
      end
    end
  else
    for k, v in pairs(result) do
      if type(k) == 'string' and k:find(part) and
         (op == '.' or type(v) == 'function') then
        local xpm = type(v) == 'function' and XPM.METHOD or XPM.VARIABLE
        cmpls[#cmpls + 1] = k .. sep .. xpm
      end
    end
  end
  table.sort(cmpls)
  M.auto_c_order = buffer.ORDER_PRESORTED
  M:auto_c_show(#part - 1, table.concat(cmpls, string.char(M.auto_c_separator)))
end

-- Key mode for entering Lua commands.
-- @class table
-- @name lua_keys
local lua_keys = {['\t'] = complete_lua}

local prev_key_mode

---
-- Opens the command entry, subjecting it to any key bindings defined in table
-- *keys*, highlighting text with lexer name *lang*, and displaying
-- *height* number of lines at a time, and then when the `Enter` key is pressed,
-- closes the command entry and calls function *f* (if non-`nil`) with the
-- command entry's text as an argument.
-- By default with no arguments given, opens a Lua command entry.
-- The command entry does not respond to Textadept's default key bindings, but
-- instead to the key bindings defined in *keys* and in
-- `ui.command_entry.editing_keys`.
-- @param f Optional function to call upon pressing `Enter` in the command
--   entry, ending the mode. It should accept the command entry text as an
--   argument.
-- @param keys Optional table of key bindings to respond to. This is in
--   addition to the basic editing and movement keys defined in
--   `ui.command_entry.editing_keys`.
--   `Esc` and `Enter` are automatically defined to cancel and finish the
--   command entry, respectively.
--   This parameter may be omitted completely.
-- @param lang Optional string lexer name to use for command entry text. The
--   default value is `'text'`.
-- @param height Optional number of lines to display in the command entry. The
--   default value is `1`.
-- @see editing_keys
-- @usage ui.command_entry.run(ui.print)
-- @name run
function M.run(f, keys, lang, height)
  if M:auto_c_active() then M:auto_c_cancel() end -- may happen in curses
  if not assert_type(f, 'function/nil', 1) and not keys then
    f, keys, lang = run_lua, lua_keys, 'lua'
  elseif type(assert_type(keys, 'table/string/nil', 2)) == 'string' then
    lang, height, keys = keys, assert_type(lang, 'number/nil', 3), {}
  else
    if not keys then keys = {} end
    assert_type(lang, 'string/nil', 3)
    assert_type(height, 'number/nil', 4)
  end
  if not keys['esc'] then keys['esc'] = M.focus end -- hide
  if not keys['\n'] then
    keys['\n'] = function()
      if M:auto_c_active() then return false end -- allow Enter to autocomplete
      M.focus() -- hide
      if not f then return end
      local mode_history = history[history.mode]
      mode_history[#mode_history + 1] = M:get_text()
      mode_history.pos = #mode_history
      f(M:get_text())
    end
  end
  if not getmetatable(keys) then setmetatable(keys, M.editing_keys) end
  if f and not history[f] then history[f] = {pos = 0} end
  history.mode = f
  local mode_history = history[history.mode]
  M:set_text(mode_history and mode_history[mode_history.pos] or '')
  M:select_all()
  prev_key_mode = _G.keys.mode
  M.focus()
  M:set_lexer(lang or 'text')
  M.height = M:text_height(1) * (height or 1)
  _G.keys._command_entry, _G.keys.mode = keys, '_command_entry'
end

-- Redefine ui.command_entry.focus() to clear any current key mode on hide/show.
local orig_focus = M.focus
M.focus = function()
  keys.mode = prev_key_mode
  M.active = not M.active
  orig_focus()
end

-- Configure the command entry's default properties.
-- Also find the key binding for `textadept.editing.show_documentation` and use
-- it to show Lua documentation in the Lua command entry.
events.connect(events.INITIALIZED, function()
  M.h_scroll_bar, M.v_scroll_bar = false, false
  for i = 1, M.margins do M.margin_width_n[i] = 0 end
  M.call_tip_position = true
  for key, f in pairs(keys) do
    if f ~= textadept.editing.show_documentation then goto continue end
    lua_keys[key] = function()
      -- Temporarily change _G.buffer and _G.view since ui.command_entry is
      -- the "active" buffer and view.
      local orig_buffer, orig_view = _G.buffer, _G.view
      _G.buffer, _G.view = ui.command_entry, ui.command_entry
      textadept.editing.show_documentation()
      _G.buffer, _G.view = orig_buffer, orig_view
    end
    ::continue::
  end
end)

--[[ The function below is a Lua C function.

---
-- Opens the command entry.
-- @class function
-- @name focus
local focus
]]

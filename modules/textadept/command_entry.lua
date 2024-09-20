-- Copyright 2007-2024 Mitchell. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

--- Textadept's Command Entry.
-- It supports multiple modes that each have their own functionality (such as running Lua code
-- and filtering text through shell commands) and history.
-- In addition to the functions and fields listed below, the command entry also has the same
-- functions and fields that `buffer`s and `view`s do.
-- @module ui.command_entry
local M = ui.command_entry

--- The text of the command entry label. (Write-only)
-- @field label

--- The height in pixels of the command entry.
-- @field height

--- Whether or not the command entry is active.
-- @field active

--- Command history per mode.
-- The current mode is in the `mode` field.
-- @table history
-- @local
local history = setmetatable({}, {
	__index = function(t, k)
		if type(k) == 'function' or getmetatable(k) and getmetatable(k).__call then t[k] = {pos = 0} end
		return rawget(t, k)
	end
})

--- Cycles through command history for the current mode.
-- @param prev Flag that indicates whether to cycle to the previous command or the next one.
local function cycle_history(prev)
	if M:auto_c_active() then
		M[prev and 'line_up' or 'line_down'](M)
		return
	end
	local mode_history = history[history.mode]
	if not mode_history or prev and mode_history.pos <= 1 then return end
	if not prev and mode_history.pos >= #mode_history then return end
	M:line_delete()
	local i, bound = prev and -1 or 1, prev and 1 or #mode_history
	mode_history.pos = math[prev and 'max' or 'min'](mode_history.pos + i, bound)
	M:add_text(mode_history[mode_history.pos])
end

--- A metatable with typical platform-specific key bindings for text entries.
-- This metatable may be used to add basic editing and movement keys to command entry modes. It
-- is automatically added to command entry modes unless a metatable was previously set.
-- @usage setmetatable(mode_keys, ui.command_entry.editing_keys)
-- @table editing_keys

-- This separation is needed to prevent LDoc from parsing the following table.

M.editing_keys = {__index = {}}

--- Fill in default key bindings for Windows/Linux, macOS, Terminal.
local bindings = {
	-- Note: cannot use `M.cut`, `M.copy`, etc. since M is never considered the global buffer.
	[function() M:undo() end] = {'ctrl+z', 'cmd+z', 'ctrl+z'},
	[function() M:redo() end] = {{'ctrl+y', 'ctrl+Z'}, {'cmd+Z', 'cmd+y'}, {'ctrl+y', 'ctrl+meta+z'}},
	[function() M:cut() end] = {'ctrl+x', 'cmd+x', 'ctrl+x'},
	[function() M:copy() end] = {'ctrl+c', 'cmd+c', 'ctrl+c'},
	[function() M:paste() end] = {'ctrl+v', 'cmd+v', 'ctrl+v'},
	[function() M:select_all() end] = {'ctrl+a', 'cmd+a', 'ctrl+a'},
	[function() cycle_history(true) end] = {'up', 'up', 'up'},
	[cycle_history] = {'down', 'down', 'down'},
	-- Movement keys.
	[function() M:char_right() end] = {nil, 'ctrl+f', 'ctrl+f'},
	[function() M:char_left() end] = {nil, 'ctrl+b', 'ctrl+b'},
	[function() M:word_right() end] = {nil, 'alt+right', nil},
	[function() M:word_left() end] = {nil, 'alt+left', nil},
	[function() M:vc_home() end] = {nil, {'ctrl+a', 'cmd+left'}, nil},
	[function() M:line_end() end] = {nil, {'ctrl+e', 'cmd+right'}, 'ctrl+e'},
	[function() M:clear() end] = {nil, {'del', 'ctrl+d'}, 'ctrl+d'}
}
local plat = CURSES and 3 or OSX and 2 or 1
for f, plat_keys in pairs(bindings) do
	local key = plat_keys[plat]
	if type(key) == 'string' then
		M.editing_keys.__index[key] = f
	elseif type(key) == 'table' then
		for _, key in ipairs(key) do M.editing_keys.__index[key] = f end
	end
end

--- Environment for abbreviated Lua commands.
-- @table env
-- @local
local env = setmetatable({}, {
	__index = function(_, k)
		if type(buffer[k]) == 'function' then
			return function(...) return buffer[k](buffer, ...) end
		elseif type(view[k]) == 'function' then
			return function(...) view[k](view, ...) end -- do not return a value
		end
		return buffer[k] or view[k] or ui[k] or _G[k] or textadept[k]
	end, --
	__newindex = function(self, k, v)
		local ok, value = pcall(function() return buffer[k] end)
		if ok and value ~= nil or not ok and value:find('write-only property') then
			buffer[k] = v -- buffer and view are interchangeable in this case
		elseif view[k] ~= nil then
			view[k] = v
		elseif ui[k] ~= nil then
			ui[k] = v
		else
			rawset(self, k, v)
		end
	end
})

--- Executes string *code* as Lua code that is subject to an "abbreviated" environment.
-- In this environment, the contents of the `buffer`, `view`, `ui`, and `textadept` tables are
-- also considered as global functions and fields.
-- Prints the results of expressions like in the Lua prompt. Also invokes bare functions as
-- commands.
-- @param code The Lua code to execute.
local function run_lua(code)
	local f, errmsg = load('return ' .. code, nil, 't', env)
	if not f then f, errmsg = load(code, nil, 't', env) end
	local result = assert(f, errmsg)()
	if type(result) == 'function' then result = result() end
	if type(result) == 'table' then
		local items = {}
		for k, v in pairs(result) do items[#items + 1] = string.format('%s = %s', k, v) end
		table.sort(items)
		result = string.format('{%s}', table.concat(items, ', '))
		if view.edge_column > 0 and #result > view.edge_column then
			local indent = buffer.use_tabs and '\t' or string.rep(' ', buffer.tab_width)
			result = string.format('{\n%s%s\n}', indent, table.concat(items, ',\n' .. indent))
		end
	end
	if result ~= nil or code:find('^return ') then ui.output(tostring(result), '\n') end
	events.emit(events.UPDATE_UI, 1) -- update UI if necessary (e.g. statusbar)
end
args.register('-e', '--execute', 1, run_lua, 'Execute Lua code')

--- Shows a set of Lua code completions for the entry's text, subject to an "abbreviated"
-- environment where the contents of the `buffer`, `view`, `ui`, and `textadept` tables are
-- also considered as globals.
local function complete_lua()
	local line, pos = M:get_cur_line()
	local symbol, op, part = line:sub(1, pos - 1):match('([%w_.]-)([%.:]?)([%w_]*)$')
	local ok, result = pcall((load(string.format('return (%s)', symbol), nil, 't', env)))
	if (not ok or type(result) ~= 'table') and symbol ~= '' then return end
	local cmpls = {}
	local patt = '^' .. part
	local XPM = textadept.editing.XPM_IMAGES
	local sep = string.char(M.auto_c_type_separator)
	if not ok or symbol == 'buffer' or symbol == 'view' then
		local sci, is_sci_func = _SCINTILLA, function(v) return type(v) == 'table' and #v == 4 end
		local global_envs = not ok and {buffer, view, ui, _G, textadept, sci} or {sci}
		for _, t in ipairs(global_envs) do
			for k, v in pairs(t) do
				if type(k) ~= 'string' or not k:find(patt) then goto continue end
				if t == sci and op == ':' and not is_sci_func(v) then goto continue end
				if t == sci and op == '.' and is_sci_func(v) then goto continue end
				local xpm = (type(v) == 'function' or (t == sci and is_sci_func(v))) and XPM.METHOD or
					XPM.VARIABLE
				cmpls[#cmpls + 1] = k .. sep .. xpm
				::continue::
			end
		end
	else
		for k, v in pairs(result) do
			if type(k) == 'string' and k:find(patt) and (op == '.' or type(v) == 'function') then
				local xpm = type(v) == 'function' and XPM.METHOD or XPM.VARIABLE
				cmpls[#cmpls + 1] = k .. sep .. xpm
			end
		end
	end
	table.sort(cmpls)
	M.auto_c_separator, M.auto_c_order = string.byte(' '), buffer.ORDER_PRESORTED
	M:auto_c_show(#part, table.concat(cmpls, ' '))
end

--- Mode for entering Lua commands.
local lua_keys = {['\t'] = complete_lua}

local prev_key_mode

--- Appends string *text* to the history for the current or most recent command entry mode.
-- @param text String text to append to history.
local function append_history(text)
	local mode_history = history[history.mode]
	if mode_history[#mode_history] == text then return end -- already exists
	mode_history[#mode_history + 1], mode_history.pos = text, #mode_history + 1
end

--- Opens the command entry with label *label* (and optionally with string *initial_text*),
-- subjecting it to any key bindings defined in table *keys*, highlighting text with lexer
-- name *lang*, and then when the `Enter` key is pressed, closes the command entry and calls
-- function *f* (if non-`nil`) with the command entry's text as an argument, along with any
-- extra arguments passed to this function.
-- By default with no arguments given, opens a Lua command entry.
-- The command entry does not respond to Textadept's default key bindings, but instead to the
-- key bindings defined in *keys* and in `ui.command_entry.editing_keys`.
-- @param label String label to display in front of input.
-- @param f Function to call upon pressing `Enter` in the command entry, ending the mode.
--	It should accept at a minimum the command entry text as an argument.
-- @param[opt] keys Optional table of key bindings to respond to. This is in addition to the
--	basic editing and movement keys defined in `ui.command_entry.editing_keys`. `Esc` and
--	`Enter` are automatically defined to cancel and finish the command entry, respectively.
-- @param[opt='text'] lang Optional string lexer name to use for command entry text.
-- @param[optchain] initial_text Optional string of text to initially show in the command entry. The
--	default value comes from the command history for *f*.
-- @param[optchain] ... Optional additional arguments to pass to *f*.
-- @usage ui.command_entry.run('echo:', ui.print)
function M.run(label, f, keys, lang, initial_text, ...)
	if _G.keys.mode == '_command_entry' then return end -- already in command entry
	local args = table.pack(...)
	if not assert_type(label, 'string/nil', 1) then label = _L['Lua command:'] end
	if not assert_type(f, 'function/nil', 2) and not keys then
		f, keys, lang = run_lua, lua_keys, 'lua'
	elseif type(assert_type(keys, 'table/string/nil', 3)) == 'string' then
		table.insert(args, 1, initial_text)
		initial_text, lang, keys = assert_type(lang, 'string/nil', 4), keys, {}
	else
		if not keys then keys = {} end
		assert_type(lang, 'string/nil', 4)
		assert_type(initial_text, 'string/nil', 5)
	end

	-- Auto-define Esc and Enter keys to cancel and finish the command entry, respectively,
	-- and connect to keybindings in `ui.command_entry.editing_keys`.
	if not keys['esc'] then keys['esc'] = M.focus end -- hide
	if not keys['\n'] then
		keys['\n'] = function()
			if M:auto_c_active() then return false end -- allow Enter to autocomplete
			M.focus() -- hide
			append_history(M:get_text())
			if f then f(M:get_text(), table.unpack(args)) end
		end
	end
	if not getmetatable(keys) then setmetatable(keys, M.editing_keys) end

	-- Setup and open the command entry.
	history.mode = f
	if initial_text then append_history(initial_text) end -- cycling will be incorrect otherwise
	local mode_history = history[history.mode]
	M:set_text(mode_history and mode_history[mode_history.pos] or '')
	M:select_all()
	if initial_text then M:line_end() end
	prev_key_mode = _G.keys.mode -- save before M.focus()
	M.label = label
	M.focus()
	M:set_lexer(lang or 'text')
	M.height = M:text_height(1)
	_G.keys._command_entry, _G.keys.mode = keys, '_command_entry'
end

-- Redefine ui.command_entry.focus() to clear any current key mode on hide/show.
local orig_focus = M.focus
M.focus = function()
	keys.mode = prev_key_mode
	orig_focus()
end

-- Configure the command entry's default properties.
events.connect(events.INITIALIZED, function()
	M.h_scroll_bar, M.v_scroll_bar = false, false
	for i = 1, M.margins do M.margin_width_n[i] = 0 end
	M.margin_type_n[1], M.margin_style[1] = view.MARGIN_TEXT, view.STYLE_LINENUMBER
	M.call_tip_use_style = M.tab_width * M:text_width(view.STYLE_CALLTIP, ' ')
	M.call_tip_position = true
end)

-- The function below is a Lua C function.

--- Opens the command entry. This is a low-level function. You probably want to use the higher-level
-- `ui.command_entry.run()`.
-- @function focus

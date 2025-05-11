-- Copyright 2007-2025 Mitchell. See LICENSE.
-- Abbreviated environment and commands from Jay Gould.

--- Textadept's Command Entry.
-- It supports multiple modes that each have their own functionality (such as running Lua code
-- and filtering text through shell commands) and history.
-- In addition to the API listed below, the command entry also shares the same API as `buffer`
-- and `view`.
-- @module ui.command_entry
local M = ui.command_entry

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
-- @param[opt=false] prev Cycle to the previous command instead of the next one.
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

--- A Lua metatable that contains a set of typical key bindings for text entries.
-- It is automatically added to keys passed to `ui.command_entry.run()` unless those keys
-- already have their own metatable.
-- @table editing_keys

-- This separation is needed to prevent LDoc from parsing the following table.

M.editing_keys = {__index = {}}

-- Fill in default key bindings for Windows/Linux/BSD, macOS, Terminal.
keys.assign_platform_bindings(M.editing_keys.__index, {
	-- Note: cannot use `M.cut`, `M.copy`, etc. since M is never considered the global buffer.
	[function() M:undo() end] = {'ctrl+z', 'cmd+z', 'ctrl+z'},
	[function() M:redo() end] = {{'ctrl+y', 'ctrl+Z'}, {'cmd+Z', 'cmd+y'}, {'ctrl+y', 'ctrl+meta+z'}},
	[function() M:cut_allow_line() end] = {'ctrl+x', 'cmd+x', 'ctrl+x'},
	[function() M:copy_allow_line() end] = {'ctrl+c', 'cmd+c', 'ctrl+c'},
	[function() M:paste() end] = {'ctrl+v', 'cmd+v', 'ctrl+v'},
	[function() M:select_all() end] = {'ctrl+a', 'cmd+a', 'ctrl+a'},
	[function() cycle_history(true) end] = {'up', 'up', 'up'},
	[cycle_history] = {'down', 'down', 'down'},
	-- Extra movement keys (in addition to Scintilla's defaults).
	[function() M:char_right() end] = {nil, 'ctrl+f', 'ctrl+f'},
	[function() M:char_left() end] = {nil, 'ctrl+b', 'ctrl+b'},
	[function() M:word_right() end] = {nil, 'alt+right', nil},
	[function() M:word_left() end] = {nil, 'alt+left', nil},
	[function() M:vc_home() end] = {nil, {'ctrl+a', 'cmd+left'}, nil},
	[function() M:line_end() end] = {nil, {'ctrl+e', 'cmd+right'}, 'ctrl+e'},
	[function() M:clear() end] = {nil, {'del', 'ctrl+d'}, 'ctrl+d'}
})

--- Environment for abbreviated Lua commands.
-- @table env
-- @local
local env = setmetatable({}, {
	__index = function(_, k)
		if type(buffer[k]) == 'function' then return function(...) return buffer[k](buffer, ...) end end
		if type(view[k]) == 'function' then return function(...) view[k](view, ...) end end -- no return
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

--- Executes Lua code that is subject to an "abbreviated" environment.
-- In this environment, the contents of the `buffer`, `view`, `ui`, and `textadept` tables are
-- also considered as global functions and fields.
-- Prints the results of expressions like in the Lua prompt. Also invokes bare functions as
-- commands.
-- @param code String Lua code to execute.
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
	events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT) -- update UI if necessary (e.g. statusbar)
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
	local sep = string.char(M.auto_c_type_separator)
	if not ok or symbol == 'buffer' or symbol == 'view' then
		local sci, is_sci_func = _SCINTILLA, function(v) return type(v) == 'table' and #v == 4 end
		local is_sci_table = function(v) return type(v) == 'table' and #v == 5 and v[4] ~= 0 end
		local global_envs = not ok and {buffer, view, ui, _G, textadept, sci} or {sci}
		for _, t in ipairs(global_envs) do
			for k, v in pairs(t) do
				if type(k) ~= 'string' or not k:find(patt) then goto continue end
				if t == sci and op == ':' and not is_sci_func(v) then goto continue end
				if t == sci and op == '.' and is_sci_func(v) then goto continue end
				local xpm =
					M._xpm[(type(v) == 'function' or (t == sci and is_sci_func(v))) and 'function' or
						(t == sci and not is_sci_table(v)) and 'variable' or type(v)]
				cmpls[#cmpls + 1] = k .. sep .. xpm
				::continue::
			end
		end
	else
		for k, v in pairs(result) do
			if type(k) == 'string' and k:find(patt) and (op == '.' or type(v) == 'function') then
				cmpls[#cmpls + 1] = k .. sep .. M._xpm[type(v)]
			end
		end
	end
	table.sort(cmpls)
	M.auto_c_separator, M.auto_c_order = string.byte(' '), buffer.ORDER_PRESORTED
	M:auto_c_show(#part, table.concat(cmpls, ' '))
end

--- Appends to the history for the current or most recent command entry mode.
-- @param text String text to append to history.
local function append_history(text)
	local mode_history = history[history.mode]
	if mode_history[#mode_history] == text then return end -- already exists
	mode_history[#mode_history + 1], mode_history.pos = text, #mode_history + 1
end

--- Opens the command entry.
-- This function may be called with no arguments to open the Lua command entry.
-- @param label String label to display in front of the entry.
-- @param f Function to call upon pressing `Enter`. It should accept at a minimum the command
--	entry text as an argument.
-- @param[opt] keys Table of key bindings to respond to. This is in addition to the basic
--	editing and movement keys defined in `ui.command_entry.editing_keys`. `Esc` and `Enter`
--	are automatically defined to cancel and finish the command entry, respectively. The
--	command entry does not respond to Textadept's default key bindings.
-- @param[opt='text'] lang String lexer name to use for syntax highlighting command entry text.
-- @param[optchain] initial_text String text to initially show. The default value comes from
--	the command history for *f*.
-- @param[optchain] ... Additional arguments to pass to *f*.
-- @usage ui.command_entry.run('echo:', ui.print)
-- @usage ui.command_entry.run('$', os.spawn, 'bash', 'env', ui.print) -- spawn a process
function M.run(label, f, keys, lang, initial_text, ...)
	if _G.keys.mode == '_command_entry' then return end -- already in command entry
	local args = table.pack(...)
	if not label then
		label, f, keys, lang = _L['Lua command:'], run_lua, {['\t'] = complete_lua}, 'lua'
	else
		assert_type(label, 'string', 1)
		assert_type(f, 'function', 2)
		if type(assert_type(keys, 'table/string/nil', 3)) == 'string' then
			table.insert(args, 1, initial_text)
			initial_text, lang, keys = assert_type(lang, 'string/nil', 4), keys, {}
		else
			if not keys then keys = {} end
			assert_type(lang, 'string/nil', 4)
			assert_type(initial_text, 'string/nil', 5)
		end
	end

	-- Auto-define Esc and Enter keys to cancel and finish the command entry, respectively,
	-- and connect to keybindings in `ui.command_entry.editing_keys`.
	local key_mode = _G.keys.mode
	local function hide()
		_G.keys.mode = key_mode
		M.focus()
	end
	keys['esc'], keys['\n'] = hide, function()
		if M:auto_c_active() then return false end -- allow Enter to autocomplete
		hide()
		append_history(M:get_text())
		f(M:get_text(), table.unpack(args))
	end
	if not getmetatable(keys) then setmetatable(keys, M.editing_keys) end

	-- Setup and open the command entry.
	M.label = label
	history.mode = f
	if initial_text then append_history(initial_text) end -- cycling will be incorrect otherwise
	local mode_history = history[history.mode]
	M:set_text(mode_history and mode_history[mode_history.pos] or '')
	M[initial_text and 'line_end' or 'select_all'](M)
	M:set_lexer(lang or 'text')
	M.focus()
	M.height = M:text_height(1)
	_G.keys._command_entry, _G.keys.mode = keys, '_command_entry'
end

-- LuaFormatter off
local xpm16={table=not CURSES and '/* XPM */ static char *dummy[]={ "16 16 18 1", ". c None", "d c #262626", "e c #333333", "p c #404040", "n c #4c4c4c", "c c #595959", "h c #666666", "o c #737373", "k c #808080", "l c #8c8c8c", "g c #999999", "f c #a6a6a6", "# c #b2b2b2", "j c #bfbfbf", "m c #cccccc", "i c #d9d9d9", "a c #e6e6e6", "b c #f2f2f2", ".##############.", "#abbbbbbbbbbbba#", "#aaaaaaacde#aaa#", "faaaaaagdeecaaaf", "faaaaaaheeehaaag", "giiiijkeeeciiiig", "giiledecmaaaiiig", "giiennn#aiiiiiig", "liiccccgiiiiiiil", "liimoccck#iiiiil", "kiiiaamhpeefiiik", "kiiiiii#ohcciiik", "kiiimmmmoooliimk", "ommmmmmijkgmmmmo", "o#mmmmmmiaaimm#o", ".oooooooooooooo."};' or '#',['function']=not CURSES and '/* XPM */ static char *dummy[]={ "16 16 18 1", ". c None", "g c #1a1a1a", "f c #333333", "k c #404040", "j c #4c4c4c", "m c #595959", "h c #666666", "n c #737373", "o c #808080", "l c #8c8c8c", "i c #999999", "d c #a6a6a6", "# c #b2b2b2", "p c #bfbfbf", "e c #cccccc", "c c #d9d9d9", "a c #e6e6e6", "b c #f2f2f2", ".##############.", "#abbbbbbbbbbbba#", "#aaaacccccaaaaa#", "daaaefgggggggaad", "daaaaahffffffaad", "icccccajkkkkkcci", "iccccchkkkkkkcci", "icccclfjjjjjjcci", "lccccjjjjjhjjccl", "lccc#jmmncaojcco", "occcimmdacccocco", "occc#hlaccccacco", "oecccopecceeccco", "neeecpeeeeeeeeen", "n#eeeceeeeeeee#n", ".nhhhhhhhhhhhhn."}; ' or '*',variable=not CURSES and '/* XPM */ static char *dummy[]={ "16 16 1 1", ". c None", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................", "................"};' or ' '}
local xpm32={table=not CURSES and '/* XPM */ static char *dummy[]={ "32 32 18 1", ". c None", "p c #000000", "f c #333333", "h c #404040", "e c #4c4c4c", "c c #595959", "j c #666666", "m c #737373", "i c #808080", "d c #8c8c8c", "b c #999999", "o c #a6a6a6", "n c #b2b2b2", "k c #bfbfbf", "l c #cccccc", "g c #d9d9d9", "# c #e6e6e6", "a c #f2f2f2", "................................", "................................", "...###########a###########a##...", "..############################..", "..############################..", "..################bccd########..", "..###############effffe#######..", "..#####ggg######dfhhhhfi####g#..", "..#gggggggggggg#chhhhhhc#gggg#..", "..#gggggggggggg#ehhhhhhj#gggg#..", "..#ggggggggggggkhhhhhhhdggggg#..", "..ggggggggggg#lehhhhhhm#ggggg#..", "..ggggggggicceheheiidn#ggggggg..", "..ggggggleeeeeeeiggggggggggggg..", "..ggggggjeeeeeecgggggggggggggg..", "..ggggggeeeeeeemgggggggggggggg..", "..ggggggeeeeeeemgggggggggggggg..", "..ggggggieccccccgggggggggggggg..", "..gggggggjccccccjggggggggggggg..", "..ggggggggoddicccejjjdgggggggg..", "..gggggggggggggijjjjjcjggggggg..", "..gggggggggggggljjjjjjcdgggggg..", "..lgggggggggggggjjjjjjjmgggggg..", "..llllllllllllggijjjjjjiglllll..", "..llllllllllllllojmmmmjollllll..", "..llllllllllllllgdjmmjdgllllll..", "..lllllllllllllllgkobnglllllll..", "..llllllllllllllllllllllllllll..", "..kllllllllllllllllllllllllllk..", "..hnllllggggggggggggglllglllnh..", "....pppppppppppppppppppppppp....", "................................"};' or '#',['function']=not CURSES and '/* XPM */ static char *dummy[]={ "32 32 18 1", ". c None", "p c #000000", "f c #333333", "g c #404040", "h c #4c4c4c", "j c #595959", "n c #666666", "e c #737373", "c c #808080", "m c #8c8c8c", "l c #999999", "k c #a6a6a6", "o c #b2b2b2", "b c #bfbfbf", "i c #cccccc", "d c #d9d9d9", "# c #e6e6e6", "a c #f2f2f2", "................................", "................................", "...###########a###########a##...", "..############################..", "..############################..", "..############################..", "..#######bcccccccccccccc######..", "..#####dd#efffffffffffff######..", "..#ddddddd#efggggggggggf#dddd#..", "..#dddddddd#eggggggggggf#dddd#..", "..#ddddddddd#egggggggggg#dddd#..", "..dddddddddddbgggggggggg#dddd#..", "..ddddddddddbhghhhhhhhgg#ddddd..", "..dddddddddihhhhhhhhhhhgdddddd..", "..dddddddd#jhhhhhhhhhhhgdddddd..", "..ddiiiiddkhhhhhhhhhhhhhdiiidd..", "..diiiiiidehhhhhhhjchhhhdiiiid..", "..iiiiiiibhjjjjjhlddchjhdiiiii..", "..iiiiiiimjjjjjeiiiidcjhdiiiii..", "..iiiiiiimjnnneiiiiiidchdiiiii..", "..iiiiiiimnnnciiiiiiiidcdiiiii..", "..iiiiiiimneniiiiiiiiiiddiiiii..", "..iiiiiiilneliiiiiiiiiiiiiiiii..", "..iiiiiiiieeiiiiiiiiiiiiiiiiii..", "..iiiiiiiilliiiiiiiiiiiiiiiiii..", "..iiiiiiiibbiiiiiiiiiiiiiiiiii..", "..iiiiiiiiiiiiiiiiiiiiiiiiiiii..", "..iiiiiiiiiiiiiiiiiiiiiiiiiiii..", "..biiiiiiiiiiiiiiiiiiiiiiiiiib..", "..goiiiiiiiiiiiiiiiiiiiiiiiiog..", "....pppppppppppppppppppppppp....", "................................"};' or '*',variable=not CURSES and '/* XPM */ static char *dummy[]={ "32 32 1 1", ". c None", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................", "................................"};' or ' '}
-- LuaFormatter on

-- Configure the command entry's default properties and XPM images.
events.connect(events.INITIALIZED, function()
	M.h_scroll_bar, M.v_scroll_bar = false, false
	for i = 1, M.margins do M.margin_width_n[i] = 0 end
	M.call_tip_use_style, M.call_tip_position = 4 * M:text_width(view.STYLE_CALLTIP, ' '), true
	M._xpm = setmetatable({}, {__index = function(t) return t.variable end})
	local image_type = 1 -- no need to use M.new_image_type() since this is a special view
	for name, xpm in pairs(not is_hidpi() and xpm16 or xpm32) do
		M:register_image(image_type, xpm)
		M._xpm[name], image_type = image_type, image_type + 1
	end
end)

-- The fields below were defined in C.

--- The text of the command entry label. (Write-only)
-- @field label

--- The height in pixels of the command entry.
-- @field height

--- Whether or not the command entry is active.
-- @field active

-- The function below is a Lua C function.

--- Opens the command entry. This is a low-level function. You probably want to use the higher-level
-- `ui.command_entry.run()`.
-- @function focus

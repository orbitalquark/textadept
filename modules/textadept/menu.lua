-- Copyright 2007-2024 Mitchell. See LICENSE.
-- Contributions from Robert Gieseke.

--- Defines the menus used by Textadept.
-- Menus are simply tables of menu items and submenus and may be edited in place. A menu item
-- itself is a table whose first element is a menu label and whose second element is a menu
-- command to run. Submenus have `title` keys assigned to string text.
-- @module textadept.menu
local M = {}

local _L, SEPARATOR = _L, {''}

-- LuaFormatter off
-- The following buffer and view functions need to be made constant in order for menu items to
-- identify the key associated with the functions.
local menu_buffer_functions = {'undo','redo','cut','copy','paste','selection_duplicate','clear','select_all','upper_case','lower_case','move_selected_lines_up','move_selected_lines_down'}
-- LuaFormatter on
for _, f in ipairs(menu_buffer_functions) do buffer[f] = buffer[f] end
view.zoom_in, view.zoom_out = view.zoom_in, view.zoom_out

--- Wrapper around `buffer:upper_case()` and `buffer:lower_case()`.
local function change_case(upper)
	local select, pos = buffer.selection_empty, buffer.current_pos
	if select then textadept.editing.select_word() end
	buffer[upper and 'upper_case' or 'lower_case'](buffer)
	if select then buffer:goto_pos(pos) end
end
--- Wrapper around `buffer.tab_width`.
local function set_indentation(i)
	buffer.tab_width = i
	events.emit(events.UPDATE_UI, 1) -- for updating statusbar
end
--- Wrapper around `buffer.eol_mode`.
local function set_eol_mode(mode)
	buffer.eol_mode = mode
	buffer:convert_eols(mode)
	events.emit(events.UPDATE_UI, 1) -- for updating statusbar
end
--- Wrapper around `buffer:set_encoding()`.
local function set_encoding(encoding)
	buffer:set_encoding(encoding)
	events.emit(events.UPDATE_UI, 1) -- for updating statusbar
end
--- Opens the given URL in the user's default web browser.
local function open_page(url)
	local cmd = (WIN32 and 'start ""') or (OSX and 'open') or 'xdg-open'
	os.spawn(string.format('%s "%s"', cmd, not OSX and url or 'file://' .. url))
end

--- The default main menubar.
-- Individual menus, submenus, and menu items can be retrieved by name in addition to table
-- index number.
-- As a convenience, a single menu path may be used, with submenus delineated by '/'. Labels
-- are localized as needed, so English labels or their localized equivalent may be used.
-- @usage textadept.menu.menubar['File/New']
-- @usage textadept.menu.menubar['File/New'][2] = function() .. end
-- @table menubar

-- This separation is needed to prevent LDoc from parsing the following table.

local default_menubar = {
	{
		title = _L['File'], --
		{_L['New'], buffer.new}, --
		{_L['Open'], io.open_file}, --
		{_L['Open Recent...'], io.open_recent_file}, --
		{_L['Reload'], buffer.reload}, --
		{_L['Save'], buffer.save}, --
		{_L['Save As'], buffer.save_as}, --
		{_L['Save All'], io.save_all_files}, --
		SEPARATOR, --
		{_L['Close'], buffer.close}, --
		{_L['Close All'], io.close_all_buffers}, --
		SEPARATOR, --
		{_L['Load Session...'], textadept.session.load}, --
		{_L['Save Session...'], textadept.session.save}, --
		SEPARATOR, --
		{_L['Quit'], quit}
	}, {
		title = _L['Edit'], --
		{_L['Undo'], buffer.undo}, --
		{_L['Redo'], buffer.redo}, --
		SEPARATOR, --
		{_L['Cut'], buffer.cut}, --
		{_L['Copy'], buffer.copy}, --
		{_L['Paste'], buffer.paste}, --
		{_L['Paste Reindent'], textadept.editing.paste_reindent}, --
		{_L['Duplicate Line/Selection'], buffer.selection_duplicate}, --
		{_L['Delete'], buffer.clear}, {
			_L['Delete Word'], function()
				textadept.editing.select_word()
				buffer:delete_back()
			end
		}, {_L['Select All'], buffer.select_all}, --
		SEPARATOR, {
			_L['Match Brace'], function()
				local match_pos = buffer:brace_match(buffer.current_pos, 0)
				if match_pos ~= -1 then buffer:goto_pos(match_pos) end
			end
		}, {_L['Complete Word'], function() textadept.editing.autocomplete('word') end},
		{_L['Toggle Block Comment'], textadept.editing.toggle_comment},
		{_L['Join Lines'], textadept.editing.join_lines}, {
			_L['Filter Through'], function()
				ui.command_entry.run(_L['Shell command:'], textadept.editing.filter_through, 'bash')
			end
		}, {
			title = _L['Select'],
			{_L['Select between Matching Delimiters'], textadept.editing.select_enclosed},
			{_L['Select Word'], textadept.editing.select_word},
			{_L['Deselect Word'], function() buffer:drop_selection_n(buffer.selections) end},
			{_L['Select Line'], textadept.editing.select_line},
			{_L['Select Paragraph'], textadept.editing.select_paragraph}
		}, {
			title = _L['Selection'], --
			{_L['Upper Case Selection'], function() change_case(true) end},
			{_L['Lower Case Selection'], change_case}, --
			SEPARATOR, {
				_L['Enclose as XML Tags'], function()
					buffer:begin_undo_action()
					textadept.editing.enclose('<', '>')
					for i = 1, buffer.selections do
						local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
						while buffer.char_at[s - 1] ~= string.byte('<') do s = s - 1 end
						buffer:set_target_range(e, e)
						buffer:replace_target('</' .. buffer:text_range(s, e))
						buffer.selection_n_start[i], buffer.selection_n_end[i] = e, e
					end
					buffer:end_undo_action()
				end
			}, {_L['Enclose as Single XML Tag'], function() textadept.editing.enclose('<', ' />') end},
			{_L['Enclose in Single Quotes'], function() textadept.editing.enclose("'", "'") end},
			{_L['Enclose in Double Quotes'], function() textadept.editing.enclose('"', '"') end},
			{_L['Enclose in Parentheses'], function() textadept.editing.enclose('(', ')') end},
			{_L['Enclose in Brackets'], function() textadept.editing.enclose('[', ']') end},
			{_L['Enclose in Braces'], function() textadept.editing.enclose('{', '}') end}, --
			SEPARATOR, --
			{_L['Move Selected Lines Up'], buffer.move_selected_lines_up},
			{_L['Move Selected Lines Down'], buffer.move_selected_lines_down}
		}, {
			title = _L['History'], --
			{_L['Navigate Backward'], textadept.history.back},
			{_L['Navigate Forward'], textadept.history.forward},
			{_L['Record Location'], textadept.history.record}, --
			SEPARATOR, --
			{_L['Clear History'], textadept.history.clear}
		}, --
		SEPARATOR, --
		{_L['Preferences'], function() io.open_file(_USERHOME .. '/init.lua') end}
	}, {
		title = _L['Search'], --
		{_L['Find'], ui.find.focus}, --
		{_L['Find Next'], ui.find.find_next}, --
		{_L['Find Previous'], ui.find.find_prev}, --
		{_L['Replace'], ui.find.replace}, --
		{_L['Replace All'], ui.find.replace_all},
		{_L['Find Incremental'], function() ui.find.focus{incremental = true} end}, --
		SEPARATOR, --
		{_L['Find in Files'], function() ui.find.focus{in_files = true} end},
		{_L['Go To Next File Found'], function() ui.find.goto_file_found(true) end},
		{_L['Go To Previous File Found'], function() ui.find.goto_file_found(false) end}, --
		SEPARATOR, --
		{_L['Go To Line...'], textadept.editing.goto_line}
	}, {
		title = _L['Tools'], --
		{_L['Command Entry'], ui.command_entry.run},
		{_L['Select Command'], function() M.select_command() end}, --
		SEPARATOR, --
		{_L['Run'], textadept.run.run}, --
		{_L['Compile'], textadept.run.compile}, --
		{_L['Build'], textadept.run.build}, --
		{_L['Run tests'], textadept.run.test}, --
		{_L['Run project'], textadept.run.run_project}, --
		{_L['Stop'], textadept.run.stop},
		{_L['Next Error'], function() textadept.run.goto_error(true) end},
		{_L['Previous Error'], function() textadept.run.goto_error(false) end}, --
		SEPARATOR, --
		{
			title = _L['Bookmarks'], --
			{_L['Toggle Bookmark'], textadept.bookmarks.toggle},
			{_L['Clear Bookmarks'], textadept.bookmarks.clear},
			{_L['Next Bookmark'], function() textadept.bookmarks.goto_mark(true) end},
			{_L['Previous Bookmark'], function() textadept.bookmarks.goto_mark(false) end},
			{_L['Go To Bookmark...'], textadept.bookmarks.goto_mark}
		}, {
			title = _L['Macros'], --
			{_L['Start/Stop Recording'], textadept.macros.record}, --
			{_L['Play'], textadept.macros.play}, --
			SEPARATOR, --
			{_L['Save...'], textadept.macros.save}, --
			{_L['Load...'], textadept.macros.load}
		}, {
			title = _L['Quick Open'],
			{_L['Quickly Open User Home'], function() io.quick_open(_USERHOME) end},
			{_L['Quickly Open Textadept Home'], function() io.quick_open(_HOME) end}, {
				_L['Quickly Open Current Directory'],
				function()
					if buffer.filename then io.quick_open(buffer.filename:match('^(.+)[/\\]')) end
				end
			}, {_L['Quickly Open Current Project'], io.quick_open}
		}, {
			title = _L['Snippets'], --
			{_L['Insert Snippet...'], textadept.snippets.select},
			{_L['Expand Snippet/Next Placeholder'], textadept.snippets.insert},
			{_L['Previous Snippet Placeholder'], textadept.snippets.previous},
			{_L['Cancel Snippet'], textadept.snippets.cancel}, --
			SEPARATOR, --
			{_L['Complete Trigger Word'], function() textadept.editing.autocomplete('snippet') end}
		}, --
		SEPARATOR, {
			_L['Show Style'], function()
				local char =
					buffer:text_range(buffer.current_pos, buffer:position_after(buffer.current_pos))
				if char == '' then return end -- end of buffer
				local bytes = string.rep(' 0x%X', #char):format(char:byte(1, #char))
				local style = buffer.style_at[buffer.current_pos]
				local style_name = buffer:name_of_style(style):gsub('%.', '_')
				local text = string.format("'%s' (U+%04X:%s)\n%s %s\n%s %s (%d)", char,
					utf8.codepoint(char), bytes, _L['Lexer'], buffer:get_lexer(true), _L['Style'], style_name,
					style)
				view:call_tip_show(buffer.current_pos, text)
			end
		}
	}, {
		title = _L['Buffer'], --
		{_L['Next Buffer'], function() view:goto_buffer(1) end},
		{_L['Previous Buffer'], function() view:goto_buffer(-1) end},
		{_L['Switch to Buffer...'], ui.switch_buffer}, --
		SEPARATOR, --
		{
			title = _L['Indentation'], --
			{_L['Tab width: 2'], function() set_indentation(2) end},
			{_L['Tab width: 3'], function() set_indentation(3) end},
			{_L['Tab width: 4'], function() set_indentation(4) end},
			{_L['Tab width: 8'], function() set_indentation(8) end}, --
			SEPARATOR, {
				_L['Toggle Use Tabs'], function()
					buffer.use_tabs = not buffer.use_tabs
					events.emit(events.UPDATE_UI, 1) -- for updating statusbar
				end
			}, {_L['Convert Indentation'], textadept.editing.convert_indentation}
		}, {
			title = _L['EOL Mode'], --
			{_L['CRLF'], function() set_eol_mode(buffer.EOL_CRLF) end},
			{_L['LF'], function() set_eol_mode(buffer.EOL_LF) end}
		}, {
			title = _L['Encoding'], --
			{_L['UTF-8 Encoding'], function() set_encoding('UTF-8') end},
			{_L['ASCII Encoding'], function() set_encoding('ASCII') end},
			{_L['CP-1252 Encoding'], function() set_encoding('CP1252') end},
			{_L['UTF-16 Encoding'], function() set_encoding('UTF-16LE') end}
		}, --
		SEPARATOR, --
		{_L['Toggle Tab Bar'], function() ui.tabs = not ui.tabs end}, --
		SEPARATOR, {
			_L['Select Lexer...'], function()
				local lexers = lexer.names()
				local i = ui.dialogs.list{title = _L['Select Lexer'], items = lexers}
				if i then buffer:set_lexer(lexers[i]) end
			end
		}
	}, {
		title = _L['View'], --
		{_L['Next View'], function() ui.goto_view(1) end},
		{_L['Previous View'], function() ui.goto_view(-1) end}, --
		SEPARATOR, --
		{_L['Split View Horizontal'], function() view:split() end},
		{_L['Split View Vertical'], function() view:split(true) end},
		{_L['Unsplit View'], function() view:unsplit() end},
		{_L['Unsplit All Views'], function() while view:unsplit() do end end},
		{
			_L['Grow View'],
			function() if view.size then view.size = view.size + view:text_height(1) end end
		}, {
			_L['Shrink View'],
			function() if view.size then view.size = view.size - view:text_height(1) end end
		}, --
		SEPARATOR, {
			_L['Toggle Current Fold'], function()
				local line = buffer:line_from_position(buffer.current_pos)
				view:toggle_fold(math.max(buffer.fold_parent[line], line))
			end
		}, --
		SEPARATOR, {
			_L['Toggle Wrap Mode'], function()
				local first_visible_line = view.first_visible_line
				local display_line = view:visible_from_doc_line(first_visible_line)
				view.wrap_mode = view.wrap_mode == 0 and view.WRAP_WHITESPACE or 0
				view:line_scroll(0, first_visible_line - display_line)
			end
		}, {
			_L['Toggle Margins'], function()
				local widths, width_n = view._margin_widths or {}, view.margin_width_n
				if not view._margin_widths then
					for i = 1, view.margins do widths[i], width_n[i] = width_n[i], 0 end
				else
					for i = 1, view.margins do width_n[i] = widths[i] end
				end
				view._margin_widths = not view._margin_widths and widths or nil
			end
		}, {
			_L['Toggle Show Indent Guides'],
			function()
				view.indentation_guides = view.indentation_guides == 0 and view.IV_LOOKBOTH or 0
			end
		}, {
			_L['Toggle View Whitespace'],
			function() view.view_ws = view.view_ws == 0 and view.WS_VISIBLEALWAYS or 0 end
		}, {
			_L['Toggle Virtual Space'], function()
				buffer.virtual_space_options = buffer.virtual_space_options == 0 and
					buffer.VS_USERACCESSIBLE or 0
			end
		}, --
		SEPARATOR, --
		{_L['Zoom In'], view.zoom_in}, --
		{_L['Zoom Out'], view.zoom_out}, --
		{_L['Reset Zoom'], function() view.zoom = 0 end}
	}, {
		title = _L['Help'], --
		{_L['Show Manual'], function() open_page(_HOME .. '/docs/manual.html') end},
		{_L['Show LuaDoc'], function() open_page(_HOME .. '/docs/api.html') end}, --
		SEPARATOR, {
			_L['About'],
			function() ui.dialogs.message{title = _RELEASE, text = _COPYRIGHT, icon = 'textadept'} end
		}
	}
}

--- The default right-click context menu.
-- Submenus, and menu items can be retrieved by name in addition to table index number.
-- @usage textadept.menu.context_menu[#textadept.menu.context_menu + 1] = {...}
-- @table context_menu

-- This separation is needed to prevent LDoc from parsing the following table.

local default_context_menu = {
	{_L['Undo'], buffer.undo}, --
	{_L['Redo'], buffer.redo}, --
	SEPARATOR, --
	{_L['Cut'], buffer.cut}, --
	{_L['Copy'], buffer.copy}, --
	{_L['Paste'], buffer.paste}, --
	{_L['Delete'], buffer.clear}, --
	SEPARATOR, --
	{_L['Select All'], buffer.select_all}
}

--- The default tabbar context menu.
-- Submenus, and menu items can be retrieved by name in addition to table index number.
-- @table tab_context_menu

-- This separation is needed to prevent LDoc from parsing the following table.

local default_tab_context_menu = {
	{_L['Close'], buffer.close}, --
	SEPARATOR, --
	{_L['Save'], buffer.save}, --
	{_L['Save As'], buffer.save_as}, --
	SEPARATOR, --
	{_L['Reload'], buffer.reload}
}

--- Table of proxy tables for menus.
local proxies = {}

local key_shortcuts, menu_items, contextmenu_items

local SHIFT, CTRL, ALT, META = view.MOD_SHIFT, view.MOD_CTRL, view.MOD_ALT, view.MOD_META
local ignore = {[0xFE20] = true, [0x01000002] = true}
--- Returns for a key sequence the integer keycode and modifier mask used to create a menu
-- item accelerator.
-- Keycodes are either ASCII bytes or codes from `keys.KEYSYMS`. Modifiers are a combination of
-- `SCMOD_*` modifiers.
-- @param key_seq The string key sequence.
-- @return keycode and modifier mask
local function get_menu_key_seq(key_seq)
	if not key_seq then return nil end
	local mods, key = key_seq:match('^(.*%+)(.+)$')
	if not mods and not key then mods, key = '', key_seq end
	local modifiers = ((mods:find('shift%+') or key:lower() ~= key) and SHIFT or 0) +
		(mods:find('ctrl%+') and CTRL or 0) + (mods:find('alt%+') and ALT or 0) +
		(mods:find('cmd%+') and META or 0)
	local code = string.byte(key)
	if #key > 1 or code < 32 then
		for i, s in pairs(keys.KEYSYMS) do
			if s == key and i >= (not QT and 0xFE20 or 0x01000000) and not ignore[i] then
				code = i
				break
			end
		end
	end
	return code, modifiers
end

--- Creates a menu suitable for `ui.menu()` from the menu table format.
-- Also assigns key bindings.
-- @param menu The menu to create a menu from.
-- @param contextmenu Flag indicating whether or not the menu is a context menu. If so, menu_id
--	offset is 1000. The default value is `false`.
-- @return menu that can be passed to `ui.menu()`.
local function read_menu_table(menu, contextmenu)
	local ui_menu = {title = menu.title}
	for _, item in ipairs(menu) do
		if item.title then
			ui_menu[#ui_menu + 1] = read_menu_table(item, contextmenu)
		else -- item = {label, function}
			local menu_id = not contextmenu and #menu_items + 1 or #contextmenu_items + 1000 + 1
			local key, mods = get_menu_key_seq(key_shortcuts[tostring(item[2])])
			ui_menu[#ui_menu + 1] = {item[1], menu_id, key, mods}
			if item[2] then
				local items = not contextmenu and menu_items or contextmenu_items
				items[menu_id < 1000 and menu_id or menu_id - 1000] = item
			end
		end
	end
	return ui_menu
end

--- Returns a proxy table for menu table *menu* such that when a menu item is changed or added,
-- *update* is called to update the menu in the UI.
-- @param menu The menu or table of menus to create a proxy for.
-- @param update The function to call to update the menu in the UI when a menu item is changed
--	or added.
-- @param menubar Used internally to keep track of the top-level menu for calling *update* with.
local function proxy_menu(menu, update, menubar)
	local proxy_mt = {
		__index = function(_, k)
			local v
			if type(k) == 'number' or k == 'title' then
				v = menu[k]
			elseif type(k) == 'string' then
				for _, item in ipairs(menu) do
					if item.title == _L[k] or item[1] == _L[k] then
						v = item
						break
					end
				end
			end
			return type(v) == 'table' and proxy_menu(v, update, menubar or menu) or v
		end, --
		__newindex = function(_, k, v)
			menu[k] = getmetatable(v) and getmetatable(v).menu or v
			-- After adding or removing menus or menu items, update the menubar or context menu. When
			-- updating a menu item's function, do nothing extra.
			if type(v) ~= 'function' then update(menubar or menu) end
		end, --
		__len = function() return #menu end, --
		menu = menu -- store existing menu for copying (e.g. m[#m + 1] = m[#m])
	}
	local proxy = setmetatable({}, proxy_mt)
	if menubar then return proxy end
	-- Handle shorthand `menubar['Edit/Select/Select Word']` notation for top-level menus.
	local toplevel_proxy_mt = {}
	for k, v in pairs(proxy_mt) do toplevel_proxy_mt[k] = v end
	toplevel_proxy_mt.__index = function(_, k)
		if type(k) ~= 'string' or not k:find('/') then return proxy[k] end
		local proxy = proxy
		for label in k:gmatch('[^/]+') do
			proxy = proxy[label]
			if not proxy then break end
		end
		return proxy
	end
	return setmetatable({}, toplevel_proxy_mt)
end

--- Sets `ui.menubar` from menu table *menubar*.
-- Each menu is an ordered list of menu items and has a `title` key for the title text. Menu
-- items are tables containing menu text and either a function to call or a table containing a
-- function with its parameters to call when an item is clicked. Menu items may also be sub-menus,
-- ordered lists of menu items with an additional `title` key for the sub-menu's title text.
-- @param menubar The table of menu tables to create the menubar from. If `nil`, clears the
--	menubar from view, but keeps it intact in order for `textadept.menu.select_command()`
--	to function properly.
-- @see ui.menu
local function set_menubar(menubar)
	if not menubar then
		ui.menubar = {}
		return
	end
	key_shortcuts, menu_items = {}, {} -- reset
	for key, f in pairs(keys) do key_shortcuts[tostring(f)] = key end
	local _menubar = {}
	for _, menu in ipairs(menubar) do _menubar[#_menubar + 1] = ui.menu(read_menu_table(menu)) end
	ui.menubar = _menubar
	proxies.menubar = proxy_menu(menubar, set_menubar)
end
events.connect(events.INITIALIZED, function() set_menubar(default_menubar) end)
-- Define menu proxy for use by keys.lua and user scripts.
-- Do not use an update function because this is expensive at startup, and `events.INITIALIZED`
-- will create the first visible menubar and proper proxy.
proxies.menubar = proxy_menu(default_menubar, function() end)

--- Sets `ui.context_menu` and `ui.tab_context_menu` from menu item lists *buffer_menu* and
-- *tab_menu*, respectively.
-- Menu items are tables containing menu text and either a function to call or a table containing a
-- function with its parameters to call when an item is clicked. Menu items may also be sub-menus,
-- ordered lists of menu items with an additional `title` key for the sub-menu's title text.
-- @param[opt] buffer_menu Optional menu table to create the buffer context menu from. If `nil`,
--	uses the default context menu.
-- @param[optchain] tab_menu Optional menu table to create the tabbar context menu from. If
--	`nil`, uses the default tab context menu.
-- @see ui.menu
local function set_contextmenus(buffer_menu, tab_menu)
	contextmenu_items = {} -- reset
	local menus = {
		context_menu = buffer_menu or default_context_menu,
		tab_context_menu = tab_menu or default_tab_context_menu
	}
	for name, menu in pairs(menus) do
		ui[name] = ui.menu(read_menu_table(menu, true))
		proxies[name] = proxy_menu(menu, function()
			set_contextmenus(menus.context_menu, menus.tab_context_menu)
		end)
	end
end
events.connect(events.INITIALIZED, set_contextmenus)
-- Define menu proxies for use by user scripts.
-- Do not use an update function because this is expensive at startup, and `events.INITIALIZED`
-- will create these visible menus and their proper proxies.
proxies.context_menu = proxy_menu(default_context_menu, function() end)
proxies.tab_context_menu = proxy_menu(default_tab_context_menu, function() end)

-- Performs the appropriate action when clicking a menu item.
events.connect(events.MENU_CLICKED, function(menu_id)
	local items = menu_id < 1000 and menu_items or contextmenu_items
	local f = items[menu_id < 1000 and menu_id or menu_id - 1000][2]
	assert_type(f, 'function', 'command')()
end)

--- Prompts the user to select a menu command to run.
function M.select_command()
	local items = {}
	-- Builds the item tables for the list dialog.
	-- @param menu The menu to read from.
	local function build_command_tables(menu)
		for _, item in ipairs(menu) do
			if item.title then
				build_command_tables(item)
			elseif item[1] ~= '' then -- item = {label, function}
				local label = menu.title and string.format('%s: %s', menu.title, item[1]) or item[1]
				items[#items + 1] = label:gsub('[_&]([^_&])', '%1')
				items[#items + 1] = key_shortcuts[tostring(item[2])] or ''
			end
		end
	end
	build_command_tables(getmetatable(M.menubar).menu)
	local i = ui.dialogs.list{
		title = _L['Run Command'], columns = {_L['Command'], _L['Key Binding']}, items = items
	}
	if i then events.emit(events.MENU_CLICKED, i) end
end

return setmetatable(M, {
	__index = function(_, k) return proxies[k] or rawget(M, k) end, __newindex = function(_, k, v)
		if k == 'menubar' then
			set_menubar(v)
		elseif k == 'context_menu' then
			set_contextmenus(v) -- TODO: this can reset tab_context_menu
		elseif k == 'tab_context_menu' then
			set_contextmenus(nil, v) -- TODO: this can reset context_menu
		else
			rawset(M, k, v)
		end
	end
})

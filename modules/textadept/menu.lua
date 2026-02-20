-- Copyright 2007-2026 Mitchell. See LICENSE.
-- Contributions from Robert Gieseke.

--- Defines the menus used by Textadept.
-- Menus are simply tables of menu items and submenus. A menu item itself is a two-element table: a
-- menu label and a menu command to run. Submenus have `title` keys assigned to string label text.
--
-- Menus may be edited in place using normal Lua table operations. You can index a menu with
-- either an index, a string label name, or a string path with submenus separated by '/'. When
-- indexing with strings, labels are localized as needed, so you can use either English labels
-- or their localized equivalent.
--
-- ```lua
-- -- Append to the right-click context menu.
-- table.insert(textadept.menu.context_menu, {'Label', function() ... end})
-- -- Append an encoding in the "Buffer > Encoding" menu.
-- table.insert(textadept.menu.menubar['Buffer/Encoding'],
-- 	{'UTF-32', function() buffer:set_encoding('UTF-32') end})
-- -- Change the "Search > Find" command.
-- textadept.menu.menubar['Search/Find'][2] = function() ... end
-- ```
-- @module textadept.menu
local M = {}

local _L, SEPARATOR = _L, {''}

-- LuaFormatter off
-- The following buffer and view functions need to be made constant in order for menu items to
-- identify the key associated with the functions.
local menu_buffer_functions = {'undo','redo','cut_allow_line','copy_allow_line','paste','selection_duplicate','clear','select_all','upper_case','lower_case','move_selected_lines_up','move_selected_lines_down'}
-- LuaFormatter on
for _, f in ipairs(menu_buffer_functions) do buffer[f] = buffer[f] end
view.zoom_in, view.zoom_out = view.zoom_in, view.zoom_out

-- Forward-declare these, mostly for `show_keys()`.
local key_shortcuts, menu_items, contextmenu_items

--- Restores the previous non-selected caret position.
local function deselect()
	if buffer.selection_empty or not buffer._deselect_pos then return end
	buffer:set_empty_selection(buffer._deselect_pos)
end
events.connect(events.UPDATE_UI, function(updated)
	if not updated or updated & (buffer.UPDATE_CONTENT | buffer.UPDATE_SELECTION) == 0 then return end
	if buffer.selection_empty then buffer._deselect_pos = buffer.current_pos end
end)

--- Wrapper around `buffer:upper_case()` and `buffer:lower_case()`.
local function change_case(upper)
	local select, pos = buffer.selection_empty, buffer.current_pos
	if select then textadept.editing.select_word() end
	buffer[upper and 'upper_case' or 'lower_case'](buffer)
	if select then buffer:goto_pos(pos) end
end

--- Returns for a list dialog a list of menu items and their key shortcuts.
-- @param menu Menu to read from.
-- @param[opt] items Table to append items to. This is used internally and should not be set.
local function get_menu_items(menu, items)
	if not items then items = {} end
	for _, item in ipairs(menu) do
		if item.title then
			get_menu_items(item, items)
		elseif item[1] ~= '' then -- item = {label, function}
			local label = menu.title and string.format('%s: %s', menu.title, item[1]) or item[1]
			items[#items + 1] = label:gsub('[_&]([^_&])', '%1')
			items[#items + 1] = key_shortcuts[item[2]] or ''
		end
	end
	return items
end

--- Prompts the user to select a menu command to run.
function M.select_command()
	local i = ui.dialogs.list{
		title = _L['Run Command'], columns = {_L['Command'], _L['Key Binding']},
		items = get_menu_items(getmetatable(M.menubar).menu)
	}
	if i then events.emit(events.MENU_CLICKED, i) end
end

local press_any_key = _L['Press any key or Esc to cancel...']
--- Show the key shortcut and assigned command (if any) for the next keypress.
local function show_keys() keys.mode, ui.statusbar_text = '_show_keys', press_any_key end
keys._show_keys = setmetatable({esc = function() keys.mode = nil end}, {
	__index = function(_, k)
		return function()
			local command = keys[k] and _L['Unknown'] or _L['Unassigned']
			for _, item in ipairs(menu_items) do
				if key_shortcuts[item[2]] == k then
					command = item[1]:gsub('[_&]([^_&])', '%1') -- no longer 'Unknown'
					break
				end
			end
			local key = k:gsub('[\b\t\n]', {['\b'] = '\\b', ['\t'] = '\\t', ['\n'] = '\\n'})
			ui.statusbar_text = string.format('%s (%s) - %s', key, command, press_any_key)
			buffer:copy_text(key) -- copy for convenience
		end
	end
})

-- Show character and style information at the caret position.
local function show_style()
	local char = buffer:text_range(buffer.current_pos, buffer:position_after(buffer.current_pos))
	if char == '' then return end -- end of buffer
	local bytes = string.rep(' 0x%X', #char):format(char:byte(1, #char))
	local style = buffer.style_at[buffer.current_pos]
	local style_name = buffer:name_of_style(style):gsub('%.', '_')
	local text = string.format("'%s' (U+%04X:%s)\n%s %s\n%s %s (%d)", char, utf8.codepoint(char),
		bytes, _L['Lexer'], buffer:get_lexer(true), _L['Style'], style_name, style)
	view:call_tip_show(buffer.current_pos, text)
end

--- Trigger a statusbar update.
local function update_statusbar() events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT) end

--- Wrapper around `buffer.tab_width`.
local function set_indentation(i)
	buffer.tab_width = i
	update_statusbar()
end

--- Wrapper around `buffer.eol_mode`.
local function set_eol_mode(mode)
	buffer.eol_mode = mode
	buffer:convert_eols(mode)
	update_statusbar()
end

--- Wrapper around `buffer:set_encoding()`.
local function set_encoding(encoding)
	buffer:set_encoding(encoding)
	update_statusbar()
end

--- Resizes a split view.
-- @param view The view to resize.
-- @param grow Whether to grow or shrink the view.
local function resize_view(view, grow)
	if not view.split_pos then return end
	view.split_pos = view.split_pos + (grow and 1 or -1) * 10 * view:text_height(1)
end

--- Wrapper around `view:fold_all()`.
local function fold_all(action, level)
	if not level then
		view:fold_all(action)
	else
		for i = 1, buffer.line_count do
			if buffer.fold_level[i] & buffer.FOLDLEVELHEADERFLAG == 0 then goto continue end
			local parent, parents = buffer.fold_parent[i], 1
			while parent ~= -1 do parent, parents = buffer.fold_parent[parent], parents + 1 end
			if parents ~= level then goto continue end
			view.fold_expanded[i] = false
			view:hide_lines(i + 1, buffer:get_last_child(i, -1))
			::continue::
		end
	end
	view:vertical_center_caret()
end

--- Opens a URL in the user's default web browser.
local function open_page(url)
	local cmd = (WIN32 and 'start ""') or (OSX and 'open') or 'xdg-open'
	os.spawn(string.format('%s "%s"', cmd, not OSX and url or 'file://' .. url))
end

--- The default main menubar.
-- @usage table.insert(textadept.menu.menubar['Tools'], {...}) -- Append to the Tools menu
-- @usage textadept.menu.menubar['File/New'] --> table for "File > New"
-- @usage textadept.menu.menubar['File/New'][2] = function() ... end -- change "File > New" command
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
		{_L['Cut'], buffer.cut_allow_line}, --
		{_L['Copy'], buffer.copy_allow_line}, --
		{_L['Paste'], buffer.paste}, --
		{_L['Paste Reindent'], textadept.editing.paste_reindent}, --
		{_L['Duplicate Line/Selection'], buffer.selection_duplicate}, --
		{_L['Delete'], buffer.clear}, {
			_L['Delete Word'], function()
				textadept.editing.select_word()
				buffer:delete_back()
			end
		}, {_L['Select All'], buffer.select_all}, --
		{_L['Deselect'], deselect}, --
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
		}, SEPARATOR, --
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
		{_L['Toggle Match Case'], function() ui.find.match_case = not ui.find.match_case end},
		{_L['Toggle Whole Word'], function() ui.find.whole_word = not ui.find.whole_word end},
		{_L['Toggle Regex'], function() ui.find.regex = not ui.find.regex end}, --
		SEPARATOR, --
		{_L['Find in Files'], function() ui.find.focus{in_files = true} end},
		{_L['Go To Next File Found'], function() ui.find.goto_file_found(true) end},
		{_L['Go To Previous File Found'], function() ui.find.goto_file_found(false) end}, --
		SEPARATOR, --
		{_L['Go To Line...'], textadept.editing.goto_line}
	}, {
		title = _L['Tools'], --
		{_L['Command Entry'], ui.command_entry.run}, --
		{_L['Select Command'], M.select_command}, --
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
		}, SEPARATOR, --
		{_L['Show Keys...'], show_keys}, --
		{_L['Show Style'], show_style}
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
					update_statusbar()
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
		}, SEPARATOR, --
		{_L['Toggle Tab Bar'], function() ui.tabs = not ui.tabs end}, {
			_L['Toggle Code Folding'], function()
				buffer.folding = not buffer.folding
				buffer:set_lexer(buffer.lexer_language) -- reload
			end
		}, SEPARATOR, {
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
		{_L['Grow View'], function() resize_view(view, true) end},
		{_L['Shrink View'], function() resize_view(view, false) end}, --
		SEPARATOR, {
			title = _L['Code Folding'], {
				_L['Toggle Current Fold'], function()
					local line = buffer:line_from_position(buffer.current_pos)
					view:toggle_fold(math.max(buffer.fold_parent[line], line))
				end
			}, SEPARATOR,
			{_L['Toggle Level 1 Folds'], function() fold_all(view.FOLDACTION_CONTRACT, 1) end},
			{_L['Toggle Level 2 Folds'], function() fold_all(view.FOLDACTION_CONTRACT, 2) end},
			{_L['Toggle Level 3 Folds'], function() fold_all(view.FOLDACTION_CONTRACT, 3) end}, --
			SEPARATOR,
			{_L['Collapse All Folds'], function() fold_all(view.FOLDACTION_CONTRACT_EVERY_LEVEL) end},
			{_L['Expand All Folds'], function() fold_all(view.FOLDACTION_EXPAND) end}
		}, SEPARATOR, {
			_L['Toggle Wrap Mode'], function()
				local display_line = view:visible_from_doc_line(view.first_visible_line)
				view.wrap_mode = view.wrap_mode == 0 and view.WRAP_WHITESPACE or 0
				view:scroll_vertical(display_line, 1)
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
					buffer.VS_RECTANGULARSELECTION | buffer.VS_USERACCESSIBLE or 0
			end
		}, SEPARATOR, --
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
if QT and OSX then
	-- Note: do not localize "Window" since it's hardcoded until Qt supports it natively.
	table.insert(default_menubar, #default_menubar,
		{title = 'Window', {_L['Zoom'], function() ui.maximized = not ui.maximized end}})
end

--- The default right-click context menu.
-- @usage table.insert(textadept.menu.context_menu, {'Label', function() ... end})
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

local SHIFT, CTRL, ALT, META = view.MOD_SHIFT, view.MOD_CTRL, view.MOD_ALT, view.MOD_META
local ignore = {[0xFE20] = true, [0x01000002] = true}
--- Returns for a key sequence the integer keycode and modifier mask used to create a menu
-- item accelerator.
-- Keycodes are either ASCII bytes or codes from `keys.KEYSYMS`. Modifiers are a combination of
-- `SCMOD_*` modifiers.
-- @param key_seq String key sequence.
-- @return keycode and modifier mask
local function get_menu_accel(key_seq)
	if not key_seq then return nil end
	local mods, key = key_seq:match('^(.*%+)(.+)$')
	if not mods and not key then mods, key = '', key_seq end
	local mask = ((mods:find('shift%+') or key:lower() ~= key) and SHIFT or 0) |
		(mods:find('ctrl%+') and CTRL or 0) | (mods:find('alt%+') and ALT or 0) |
		(mods:find('cmd%+') and META or 0)
	local code = string.byte(key)
	if #key == 1 and code >= 32 then return code, mask end
	for c, s in pairs(keys.KEYSYMS) do
		if s == key and c >= (not QT and 0xFE20 or 0x01000000) and not ignore[c] then return c, mask end
	end
	return code, mask
end

--- Creates a menu suitable for `ui.menu()` from the menu table format.
-- Also assigns key bindings.
-- @param menu Menu to create a menu from.
-- @param[opt=false] contextmenu The menu is a context menu. If so, menu_id offset is 1000.
-- @return menu that can be passed to `ui.menu()`.
local function read_menu_table(menu, contextmenu)
	local ui_menu = {title = menu.title}
	for _, item in ipairs(menu) do
		if item.title then
			ui_menu[#ui_menu + 1] = read_menu_table(item, contextmenu)
		else -- item = {label, function}
			local menu_id = not contextmenu and #menu_items + 1 or #contextmenu_items + 1000 + 1
			ui_menu[#ui_menu + 1] = {item[1], menu_id, get_menu_accel(key_shortcuts[item[2]])}
			if item[2] then
				local items = not contextmenu and menu_items or contextmenu_items
				items[menu_id < 1000 and menu_id or menu_id - 1000] = item
			end
		end
	end
	return ui_menu
end

--- Returns a proxy table for a menu table such that when a menu item is changed or added,
-- the menu is updated in the UI.
-- @param menu Menu or table of menus to create a proxy for.
-- @param[opt] update Function to call to update the menu in the UI when a menu item is changed
--	or added.
-- @param[optchain] menubar Used internally to keep track of the top-level menu for calling
--	*update* with.
local function proxy_menu(menu, update, menubar)
	local proxy_mt = {menu = menu} -- store existing menu for copying (e.g. m[#m + 1] = m[#m])
	proxy_mt.__index = function(_, k)
		if type(k) == 'number' or k == 'title' then
			local v = menu[k]
			return type(v) == 'table' and proxy_menu(v, update, menubar or menu) or v
		end
		if type(k) ~= 'string' then return nil end
		k = _L[k]
		for _, item in ipairs(menu) do
			if item.title == k or item[1] == k then return proxy_menu(item, update, menubar or menu) end
		end
		return nil
	end
	proxy_mt.__newindex = function(_, k, v)
		menu[k] = getmetatable(v) and getmetatable(v).menu or v
		-- After adding or removing menus or menu items, update the menubar or context menu. When
		-- updating a menu item's function, do nothing extra.
		if type(v) ~= 'function' and update then update(menubar or menu) end
	end
	proxy_mt.__len = function() return #menu end

	local proxy = setmetatable({}, proxy_mt)
	if menubar then return proxy end -- this is a sub-menu

	-- Handle shorthand `menubar['Edit/Select/Select Word']` notation for top-level menus.
	local toplevel_proxy_mt = {}
	for k, v in pairs(proxy_mt) do toplevel_proxy_mt[k] = v end
	toplevel_proxy_mt.__index = function(_, k)
		if type(k) ~= 'string' or not k:find('/') then return proxy[k] end
		local sub_proxy = proxy
		for label in k:gmatch('[^/]+') do
			sub_proxy = sub_proxy[label]
			if not sub_proxy then break end
		end
		return sub_proxy
	end
	return setmetatable({}, toplevel_proxy_mt)
end

--- Sets `ui.menubar` from a menu table.
-- Each menu is an ordered list of menu items and has a `title` key for the title text. Menu
-- items are tables containing menu text and either a function to call or a table containing a
-- function with its parameters to call when an item is clicked. Menu items may also be sub-menus,
-- ordered lists of menu items with an additional `title` key for the sub-menu's title text.
-- @param[opt] menubar Table of menu tables to create the menubar from. If `nil`, clears the
--	menubar from view, but keeps it intact in order for `textadept.menu.select_command()`
--	to function properly.
-- @see ui.menu
local function set_menubar(menubar)
	if not menubar then
		ui.menubar = {}
		return
	end
	key_shortcuts, menu_items = {}, {} -- reset
	for key, f in pairs(keys) do key_shortcuts[f] = key end
	ui.menubar = table.map(menubar, function(menu) return ui.menu(read_menu_table(menu)) end)
	proxies.menubar = proxy_menu(menubar, set_menubar)
end
events.connect(events.INITIALIZED, function() set_menubar(default_menubar) end)
-- Define menu proxy for use by keys.lua and user scripts.
-- Do not use an update function because this is expensive at startup, and `events.INITIALIZED`
-- will create the first visible menubar and proper proxy.
proxies.menubar = proxy_menu(default_menubar)

--- Set a context menu from the given menu item lists.
-- Menu items are tables containing menu text and either a function to call or a table containing a
-- function with its parameters to call when an item is clicked. Menu items may also be sub-menus,
-- ordered lists of menu items with an additional `title` key for the sub-menu's title text.
-- @param name Name of the context menu, either 'context_menu' or 'tab_context_menu'.
-- @param menu Menu table to create the buffer context menu from.
--	menu from.
-- @see ui.menu
local function set_contextmenu(name, menu)
	if name == 'context_menu' then contextmenu_items = {} end -- reset
	ui[name] = ui.menu(read_menu_table(menu, true))
	proxies[name] = proxy_menu(menu, function() set_contextmenu(name, menu) end)
end
events.connect(events.INITIALIZED, function()
	set_contextmenu('context_menu', default_context_menu)
	set_contextmenu('tab_context_menu', default_tab_context_menu)
end)
-- Define menu proxies for use by user scripts.
-- Do not use an update function because this is expensive at startup, and `events.INITIALIZED`
-- will create these visible menus and their proper proxies.
proxies.context_menu = proxy_menu(default_context_menu)
proxies.tab_context_menu = proxy_menu(default_tab_context_menu)

-- Performs the appropriate action when clicking a menu item.
events.connect(events.MENU_CLICKED, function(menu_id)
	local items = menu_id < 1000 and menu_items or contextmenu_items
	local f = items[menu_id < 1000 and menu_id or menu_id - 1000][2]
	if not OSX or not key_shortcuts[f] then
		assert_type(f, 'function', 'command')()
		-- On macOS, `events.MENU_CLICKED` will also emit `events.KEYPRESS` if there is a key
		-- shortcut (see below). This would result in recording the command twice during macro
		-- record. Therefore, macro recording ignores `events.MENU_CLICKED`, but listens for
		-- this undocumented event instead when a shortcut does not exist.
		events.emit('menu_clicked_no_shortcut', menu_id)
		return
	end
	-- The macOS menubar eats key shortcuts, emits menu events, and prevents keypress events.
	-- This affects user-defined key bindings, as well as command entry key bindings.
	-- Instead of invoking a menu item's function, emit the keypress for its shortcut.
	if not ui.command_entry.active and not keys.mode then events.emit(events.KEYPRESS, keys.CLEAR) end
	events.emit(events.KEYPRESS, key_shortcuts[f])
end)

return setmetatable(M, {
	__index = function(_, k) return proxies[k] or rawget(M, k) end, __newindex = function(_, k, v)
		if k == 'menubar' then
			set_menubar(v)
		elseif k == 'context_menu' or k == 'tab_context_menu' then
			set_contextmenu(k, v)
		else
			rawset(M, k, v)
		end
	end
})

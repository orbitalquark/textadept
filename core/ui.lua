-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Utilities for interacting with Textadept's user interface.
-- @module ui
local ui = ui

--- Option for `ui.tabs` that always shows the tab bar, even if only one buffer is open.
ui.SHOW_ALL_TABS = 2 -- ui.tabs options must be greater than 1
if CURSES then ui.tabs = false end -- not supported right now

--- List buffers by their z-order (most recently viewed to least recently viewed) in the switcher
-- dialog, instead of listing buffers in their left-to-right tab order.
-- The default value is `true`.
ui.buffer_list_zorder = true

--- Helper function for getting the print view.
local function get_print_view(type)
	for _, view in ipairs(_VIEWS) do if view.buffer._type == type then return view end end
end
--- Helper function for getting the print buffer.
local function get_print_buffer(type)
	if buffer._type == type then return buffer end -- optimize
	for _, buffer in ipairs(_BUFFERS) do if buffer._type == type then return buffer end end
end

--- Returns a buffer's UTF-8 filename and basename for display.
-- If that buffer does not have a filename, returns its type or 'Untitled'.
-- @param buffer Buffer to get display names for.
local function get_display_names(buffer)
	local filename = buffer.filename or buffer._type or _L['Untitled']
	if buffer.filename then filename = select(2, pcall(string.iconv, filename, 'UTF-8', _CHARSET)) end
	return filename, buffer.filename and filename:match('[^/\\]+$') or filename
end

--- Sets a buffer's tab label based on its saved status.
-- @param[opt=_G.buffer] buffer Buffer whose tab label to set.
local function set_tab_label(buffer)
	if not buffer then buffer = _G.buffer end
	buffer.tab_label = select(2, get_display_names(buffer)) .. (buffer.modify and '*' or '')
end

--- Helper function for printing to buffers.
-- @see ui.print_to
-- @see ui.print_silent_to
-- @see output_to
local function print_to(buffer_type, silent, ...args)
	local print_view, buffer = get_print_view(buffer_type), get_print_buffer(buffer_type)
	if not buffer or not silent and not print_view then -- no buffer or buffer not visible
		if not silent and #_VIEWS > 1 then
			ui.goto_view(1) -- go to another view to print to
		elseif not silent and not ui.tabs then
			view:split() -- create a new view to print to
		end
		if not buffer then
			local prev_buffer = _G.buffer
			buffer = _G.buffer.new()
			buffer._type = buffer_type
			buffer.undo_collection = false
			if silent then view:goto_buffer(prev_buffer) end
		else
			view:goto_buffer(buffer)
		end
	elseif print_view and not silent then
		ui.goto_view(print_view)
	end
	buffer:append_text(table.concat(args))
	buffer:document_end()
	buffer:set_save_point()
	if silent then
		buffer._selection, buffer._top_line = buffer.selection_serialized, buffer.line_count -- scroll
		set_tab_label(buffer) -- events.SAVE_POINT_REACHED does not pass this buffer
	end
	-- Scroll all views showing this buffer (if any).
	for _, view in ipairs(_VIEWS) do
		if view.buffer == buffer and view ~= _G.view then view:document_end() end
	end
	return buffer
end

--- Prints a message along with a trailing newline to a typed buffer, creating it if necessary.
-- If the print buffer is already open in a view, the message is printed to that view. Otherwise
-- the view is split (unless `ui.tabs` is `true`) and the print buffer is displayed before
-- being printed to.
-- @param type String type of print buffer.
-- @param message String message to print.
-- @return the typed buffer printed to
-- @usage ui.print_to('[Typed Buffer]', message)
function ui.print_to(type, message)
	return print_to(assert_type(type, 'string', 1), false,
		assert_type(message, 'string/nil', 2) or '', '\n')
end

--- Prints a message to a typed buffer (creating it if necessary) without switching to it.
-- @param type String type of print buffer.
-- @param message String message to print.
-- @return the typed buffer printed to
function ui.print_silent_to(type, message)
	return print_to(assert_type(type, 'string', 1), true, assert_type(message, 'string/nil', 2) or '',
		'\n')
end

--- Helper function for printing to the output buffer.
-- @see ui.output
-- @see ui.output_silent
local function output_to(silent, ...)
	local buffer = print_to(_L['[Output Buffer]'], silent, ...)
	if buffer.lexer_language ~= 'output' then buffer:set_lexer('output') end
	buffer:colorize(buffer:position_from_line(buffer:line_from_position(buffer.end_styled)), -1)
	return buffer
end

--- Prints to the output buffer, creating it if necessary.
-- The output buffer attempts to understand the error messages and warnings produced by various
-- tools.
--
-- If the output buffer is already open in a view, output is printed to that view. Otherwise
-- the view is split (unless `ui.tabs` is `true`) and the output buffer is displayed before
-- being printed to.
-- @param ... Strings to print.
-- @return the output buffer
function ui.output(...) return output_to(false, ...) end

--- Prints to the output buffer (creating it if necessary) without switching to it.
-- @param ... Strings to print.
-- @return the output buffer
function ui.output_silent(...) return output_to(true, ...) end

--- Prints to the output buffer (creating it if necessary), along with a trailing newline.
-- This function is primarily for use in the Lua command entry in place of Lua's `print()`
-- function.
-- @param ... Values to print. Lua's `tostring()` function is called for each value. They will
--	be printed as tab-separated values.
function ui.print(...args) ui.output(table.concat(table.map(args, tostring), '\t'), '\n') end

--- Buffer z-order list (most recently accessed buffer on top).
local buffers_zorder = {}

--- Updates the z-order list.
local function update_zorder()
	for i = #buffers_zorder, 1, -1 do
		if buffers_zorder[i] == buffer or not _BUFFERS[buffers_zorder[i]] then
			table.remove(buffers_zorder, i)
		end
	end
	table.insert(buffers_zorder, 1, buffer)
end
events.connect(events.BUFFER_NEW,
	function() if buffer ~= ui.command_entry then update_zorder() end end)
events.connect(events.BUFFER_AFTER_SWITCH, update_zorder)
events.connect(events.VIEW_AFTER_SWITCH, update_zorder)
events.connect(events.BUFFER_DELETED, update_zorder)

-- Saves and restores buffer zorder data during a reset.
events.connect(events.RESET_BEFORE, function(persist) persist.ui_zorder = buffers_zorder end)
events.connect(events.RESET_AFTER, function(persist) buffers_zorder = persist.ui_zorder end)

--- Prompts the user to select a buffer to switch to.
-- Buffers are listed in their left-to-right tab order unless `ui.buffer_list_zorder` is `true`, in
-- which case buffers are listed by their z-order (most recently viewed to least recently viewed).
--
-- Buffers in the same project as the current buffer are shown with relative paths.
function ui.switch_buffer()
	local buffers = not ui.buffer_list_zorder and _BUFFERS or buffers_zorder
	local columns, items = {_L['Name'], _L['Filename']}, {}
	local root = io.get_project_root()
	if root then root = select(2, pcall(string.iconv, root, 'UTF-8', _CHARSET)) end
	for i = (not ui.buffer_list_zorder or #_BUFFERS == 1) and 1 or 2, #buffers do
		local filename, basename = get_display_names(buffers[i])
		if root and filename:find(root, 1, true) then filename = filename:sub(#root + 2) end
		items[#items + 1], items[#items + 2] = (buffers[i].modify and '*' or '') .. basename, filename
	end
	local i = ui.dialogs.list{title = _L['Switch Buffers'], columns = columns, items = items}
	if i then view:goto_buffer(buffers[(not ui.buffer_list_zorder or #_BUFFERS == 1) and i or i + 1]) end
end

--- Go to a particular file, opening it if necessary.
-- @param filename String filename of the buffer to go to.
-- @param[opt=false] split Open the buffer in a split view if there is only one view and it is
--	not showing *filename*.
-- @param[optchain] preferred_view View to open the buffer in if it is not visible in any other
--	view. The default value is a view other than the current one.
-- @param[optchain=false] sloppy Matches *filename* to only the last part of `buffer.filename`
--	This is useful for compile/run/test/build commands, which output relative filenames
--	and paths instead of full ones, and it is likely that the file in question is already open.
function ui.goto_file(filename, split, preferred_view, sloppy)
	assert_type(filename, 'string', 1)
	local patt = (not sloppy and filename or filename:match('[^/\\]+$')):gsub('%p', '%%%0') .. '$'
	if not sloppy then patt = '^' .. patt end
	if WIN32 then
		patt = patt:gsub('%a', function(c) return string.format('[%s%s]', c:upper(), c:lower()) end)
	end
	if #_VIEWS == 1 and split and not (view.buffer.filename or ''):find(patt) then
		view:split()
		if _VIEWS[preferred_view] then ui.goto_view(-1) end
	else
		local other_view = _VIEWS[preferred_view] and preferred_view
		for _, view in ipairs(_VIEWS) do
			if (view.buffer.filename or ''):find(patt) then
				ui.goto_view(view)
				return
			end
			if not other_view and view ~= _G.view then other_view = view end
		end
		if other_view then ui.goto_view(other_view) end
	end
	for _, buffer in ipairs(_BUFFERS) do
		if (buffer.filename or ''):find(patt) then
			view:goto_buffer(buffer)
			return
		end
	end
	io.open_file(filename)
end

local CONTENT_OR_SELECTION = 3 -- buffer.UPDATE_CONTENT | buffer.UPDATE_SELECTION

-- Ensure title, statusbar, etc. are updated for new views.
events.connect(events.VIEW_NEW, function() events.emit(events.UPDATE_UI, CONTENT_OR_SELECTION) end)

-- Switches between buffers when a tab is clicked.
events.connect(events.TAB_CLICKED, function(index) view:goto_buffer(_BUFFERS[index]) end)

-- Closes a buffer when its tab close button is clicked.
events.connect(events.TAB_CLOSE_CLICKED, function(index)
	if _BUFFERS[index] ~= buffer then view:goto_buffer(_BUFFERS[index]) end
	buffer:close()
end)

--- Sets the title of the Textadept window to the active buffer's filename and indicates whether
-- the buffer is "clean" or "dirty".
local function set_title()
	local filename, basename = get_display_names(buffer)
	ui.title = string.format('%s %s Textadept (%s)', basename, buffer.modify and '*' or '-', filename)
end
events.connect(events.SAVE_POINT_REACHED, set_title)
events.connect(events.SAVE_POINT_LEFT, set_title)

-- Sets the buffer's tab label based on its saved status.
events.connect(events.BUFFER_NEW, set_tab_label)
events.connect(events.SAVE_POINT_REACHED, set_tab_label)
events.connect(events.SAVE_POINT_LEFT, set_tab_label)

-- Open uri(s).
events.connect(events.URI_DROPPED, function(utf8_uris)
	for utf8_path in utf8_uris:gmatch('file://([^\r\n]+)') do
		local path = utf8_path:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end)
			:iconv(_CHARSET, 'UTF-8')
		-- On Windows, ignore a leading '/', but not '//' (network path).
		if WIN32 and not path:match('^//') then path = path:sub(2, -1) end
		local mode = lfs.attributes(path, 'mode')
		if mode and mode ~= 'directory' then io.open_file(path) end
	end
	ui.goto_view(view) -- work around any view focus synchronization issues
end)

-- Sets buffer statusbar text.
events.connect(events.UPDATE_UI, function(updated)
	if not updated or updated & CONTENT_OR_SELECTION == 0 then return end
	local text = not CURSES and '%s %d/%d    %s %d    %s    %s    %s    %s' or
		'%s %d/%d  %s %d  %s  %s  %s  %s'
	local pos = buffer.current_pos
	local line, max = buffer:line_from_position(pos), buffer.line_count
	local col = buffer.column[pos] + buffer.selection_n_caret_virtual_space[buffer.main_selection]
	local lang = buffer.lexer_language
	local eol = buffer.eol_mode == buffer.EOL_CRLF and _L['CRLF'] or _L['LF']
	local tabs = string.format('%s %d', buffer.use_tabs and _L['Tabs:'] or _L['Spaces:'],
		buffer.tab_width)
	local encoding = buffer.encoding or ''
	ui.buffer_statusbar_text = string.format(text, _L['Line:'], line, max, _L['Col:'], col, lang, eol,
		tabs, encoding)
end)

--- Save buffer properties.
local function save_buffer_state()
	-- Save view state.
	buffer._selection = buffer.selection_serialized
	buffer._top_line = view:doc_line_from_visible(view.first_visible_line)
	buffer._sub_line = view.first_visible_line - view:visible_from_doc_line(buffer._top_line) + 1
	buffer._x_offset = view.x_offset
	-- Save fold state.
	buffer._folds = {}
	local i = view:contracted_fold_next(1)
	while i >= 1 do buffer._folds[#buffer._folds + 1], i = i, view:contracted_fold_next(i + 1) end
end
events.connect(events.BUFFER_BEFORE_SWITCH, save_buffer_state)
events.connect(events.BUFFER_BEFORE_REPLACE_TEXT, save_buffer_state)

--- Restore buffer properties.
local function restore_buffer_state()
	if not buffer._folds then return end
	-- Restore fold state.
	for _, line in ipairs(buffer._folds) do view:toggle_fold(line) end
	-- Restore view state.
	if buffer.length > 1 then buffer.selection_serialized = buffer._selection end
	buffer:choose_caret_x()
	view:scroll_vertical(buffer._top_line, buffer._sub_line)
	view.x_offset = buffer._x_offset
end
events.connect(events.BUFFER_AFTER_SWITCH, restore_buffer_state)
events.connect(events.BUFFER_AFTER_REPLACE_TEXT, restore_buffer_state)

--- Updates titlebar and statusbar.
local function update_bars()
	set_title()
	events.emit(events.UPDATE_UI, CONTENT_OR_SELECTION)
end
events.connect(events.BUFFER_NEW, update_bars)
events.connect(events.BUFFER_AFTER_SWITCH, update_bars)
events.connect(events.VIEW_AFTER_SWITCH, update_bars)

events.connect(events.RESET_AFTER, function() ui.statusbar_text = _L['Lua reset'] end)

-- Prompts for confirmation if any buffers are modified.
events.connect(events.QUIT, function()
	local items = {}
	for _, buffer in ipairs(_BUFFERS) do
		if buffer.modify and not buffer._type then items[#items + 1] = get_display_names(buffer) end
	end
	if #items == 0 then return end
	local button = ui.dialogs.message{
		title = _L['Quit without saving?'],
		text = string.format('%s\n • %s', _L['The following buffers are unsaved:'],
			table.concat(items, '\n • ')), icon = 'dialog-question', button1 = _L['Save all'],
		button2 = _L['Cancel'], button3 = _L['Quit without saving']
	}
	if button == 1 then return not io.save_all_files(true) or nil end -- do not return false
	if button ~= 3 then return true end -- prevent quit
end)

-- Keeps track of, and switches back to the previous buffer after buffer close.
events.connect(events.BUFFER_BEFORE_SWITCH, function() view._prev_buffer = buffer end)
events.connect(events.BUFFER_DELETED, function()
	if not _BUFFERS[view._prev_buffer] or buffer == view._prev_buffer then return end
	restore_buffer_state() -- restore so it is properly saved before switching buffers
	view:goto_buffer(view._prev_buffer)
end)

-- Handle mouse events and functionality in the terminal version.
if CURSES then
	if not WIN32 then
		local function enable_mouse() io.stdout:write("\x1b[?1002h\x1b[?1006h"):flush() end
		local function disable_mouse() io.stdout:write("\x1b[?1002l\x1b[?1006l"):flush() end
		events.connect(events.INITIALIZED, enable_mouse)
		events.connect(events.SUSPEND, disable_mouse)
		events.connect(events.RESUME, enable_mouse)
		events.connect(events.QUIT, disable_mouse)
	end

	--- Retrieves the view or split at the given terminal coordinates.
	-- @param view View or split to test for coordinates within.
	-- @param y Y terminal coordinate.
	-- @param x X terminal coordinate.
	local function get_view(view, y, x)
		if not view[1] and not view[2] then return view end
		local vertical, split = view.vertical, view.size[3]
		if vertical and x < split or not vertical and y < split then
			return get_view(view[1], y, x)
		elseif vertical and x > split or not vertical and y > split then
			-- Zero y or x relative to the other view based on split orientation.
			return get_view(view[2], vertical and y or y - split - 1, vertical and x - split - 1 or x)
		else
			return view -- in-between views; return the split itself
		end
	end

	local resize
	-- Focus a clicked view, or resize the views connected to a clicked-and-dragged splitter bar.
	events.connect(events.MOUSE, function(event, button, _, y, x)
		if event == view.MOUSE_RELEASE or button ~= 1 then return end
		if event == view.MOUSE_PRESS then
			local view = get_view(ui.get_split_table(), y - 1, x) -- title is at y = 1
			if not view[1] and not view[2] then
				ui.goto_view(view)
				resize = nil
			else
				resize = function(y2, x2)
					local i = getmetatable(view[1]) == getmetatable(_G.view) and 1 or 2
					view[i].split_pos = view.size[3] + (view.vertical and x2 - x or y2 - y)
				end
			end
		elseif resize then
			resize(y, x)
		end
		return resize ~= nil -- false resends mouse event to current view
	end)
end

--- Show pre-initialization errors in a textbox. After that, leave error handling to the
-- run module.
local function textbox(text) ui.dialogs.message{title = _L['Initialization Error'], text = text} end
events.connect(events.ERROR, textbox)
events.connect(events.INITIALIZED, function() events.disconnect(events.ERROR, textbox) end)

-- The fields below were defined in C.

--- The title text of Textadept's window. (Write-only)
-- @field title

--- The buffer's context menu, a `ui.menu()`.
-- This is a low-level field. You probably want to use the higher-level
-- `textadept.menu.context_menu`.
-- @field context_menu

--- The context menu for the buffer's tab, a `ui.menu()`.
-- This is a low-level field. You probably want to use the higher-level
-- `textadept.menu.tab_context_menu`.
-- @field tab_context_menu

--- Whether or not the statusbar is visible.
-- The default value is `true`.
-- @field statusbar

--- The text displayed in the statusbar.
-- @field statusbar_text

--- The text displayed in the buffer statusbar.
-- @field buffer_statusbar_text

--- Whether or not Textadept's window is maximized.
-- This field is always `false` in the terminal version.
-- @field maximized

--- Display the tab bar when multiple buffers are open.
-- The default value is `true` in the GUI version, and `false` in the terminal version.
-- A third option, `ui.SHOW_ALL_TABS` may be used to always show the tab bar, even if only one
-- buffer is open.
-- @field tabs

-- The tables below were defined in C.

--- A table of menus defining a menubar. (Write-only).
-- This is a low-level field. You probably want to use the higher-level `textadept.menu.menubar`.
-- @table menubar

--- A table that contains the width and height pixel values of Textadept's window.
-- @usage ui.size = {1000, 625} -- resize window
-- @table size

-- The functions below are Lua C functions.

--- Returns the text on the clipboard.
-- The terminal version relies on `textadept.clipboard.paste_command` to retrieve the contents
-- of the system clipboard, falling back on its own internal clipboard if necessary.
-- @param[opt=false] internal Get the terminal version's internal clipboard text.
-- @see buffer.copy_text
-- @function get_clipboard_text

--- Returns a split table that contains Textadept's current split view structure.
-- This is primarily used in session saving.
-- @return table of split views. Each split view entry is a table with 4 fields: `1`, `2`,
--	`vertical`, and `size`. `1` and `2` have values of either nested split view entries or
--	the views themselves; `vertical` is a flag that indicates if the split is vertical or
--	not; and `size` is a table of width, height, and split position integers.
-- @function get_split_table

--- Switches focus to another view.
-- @param view View to switch to, or index of a relative view to switch to (typically 1 or -1).
-- @see events.VIEW_BEFORE_SWITCH
-- @see events.VIEW_AFTER_SWITCH
-- @usage ui.goto_view(_VIEWS[1]) -- switch to first view
-- @usage ui.goto_view(-1) -- switch to the view before the current one
-- @function goto_view

--- Low-level function for creating a menu.
-- You probably want to use the higher-level `textadept.menu.menubar`,
-- `textadept.menu.context_menu`, or `textadept.menu.tab_context_menu` tables.
-- @param menu_table Ordered list of tables with a string menu item, integer menu ID, and
--	optional keycode and modifier mask. The latter two are used to display key shortcuts in
--	the menu. '&' characters are treated as a menu mnemonics in Qt ('_' is the equivalent
--	in GTK). If the menu item is empty, a menu separator item is created. Submenus are just
--	nested menu-structure tables. Their title text is defined with a `title` key.
-- @return menu userdata
-- @usage ui.menu{ {'_New', 1}, {'_Open', 2}, {''}, {'&Quit', 4} }
-- @usage ui.menu{ {'_New', 1, string.byte('n'), view.MOD_CTRL} } -- 'Ctrl+N'
-- @function menu

--- Displays a popup menu, typically the right-click context menu.
-- @param menu Menu to display.
-- @usage ui.popup_menu(ui.context_menu)
-- @see ui.context_menu
-- @see ui.menu
-- @function popup_menu

--- Processes pending UI events, including reading from spawned processes.
-- This function is primarily used in Textadept's own unit tests.
-- @function update

--- Suspends Textadept.
-- This only works in the terminal version. By default, Textadept ignores ^Z suspend signals from
-- the terminal.
-- @usage keys['ctrl+z'] = ui.suspend
-- @see events.SUSPEND
-- @see events.RESUME
-- @function suspend

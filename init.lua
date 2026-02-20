-- Copyright 2007-2026 Mitchell. See LICENSE.

package.path = table.concat({
	_USERHOME .. '/modules/?.lua', _USERHOME .. '/modules/?/init.lua', _HOME .. '/modules/?.lua',
	_HOME .. '/modules/?/init.lua', package.path
}, ';');
package.cpath = table.concat({
	string.format('%s/modules/?.%s', _USERHOME, not WIN32 and 'so' or 'dll'),
	string.format('%s/modules/?.%s', _HOME, not WIN32 and 'so' or 'dll'), package.cpath
}, ';')

events.emit('pre_init') -- allow core modules to operate on the first buffer and view

textadept = require('textadept')

-- The remainder of this file defines default buffer and view properties and applies them
-- to subsequent buffers and views. Normally, a setting like `buffer.use_tabs = false` only
-- applies to the current (initial) buffer. However, temporarily tap into buffer and view's
-- metatables in order to capture these initial settings (both from Textadept's init.lua and
-- from the user's init.lua) so they can be applied to subsequent buffers and views.

local buffer_settings, view_settings = {}, {}

local buffer_mt, view_mt = getmetatable(buffer), getmetatable(view)
local settings = {[buffer_mt] = buffer_settings, [view_mt] = view_settings}
local name = {[buffer_mt] = 'buffer', [view_mt] = 'view'}
local function repr(v) return string.format(type(v) == 'string' and '%q' or '%s', v) end
for _, mt in ipairs{buffer_mt, view_mt} do
	mt.__orig_index, mt.__orig_newindex = mt.__index, mt.__newindex
	mt.__index = function(t, k)
		local v = mt.__orig_index(t, k)
		if type(v) == 'function' then
			if k:find('^new_') and (k:find('_number$') or k:find('_type$')) then return v end
			return function(...args)
				if type(args[1]) == 'table' then table.remove(args, 1) end -- self
				for i = 1, #args do args[i] = repr(args[i]) end
				table.insert(settings[mt], string.format('%s:%s(%s)', name[mt], k, table.concat(args, ',')))
				return v(...)
			end
		elseif type(v) == 'table' then
			local property_mt = getmetatable(v)
			setmetatable(v, {
				__index = property_mt.__index, __newindex = function(property, k2, v2)
					table.insert(settings[mt], string.format('%s.%s[%s]=%s', name[mt], k, repr(k2), repr(v2)))
					local ok, errmsg = pcall(property_mt.__newindex, property, k2, v2)
					if not ok then error(errmsg, 2) end
				end
			})
		end
		return v
	end
	mt.__newindex = function(t, k, v)
		table.insert(settings[mt], string.format('%s[%s]=%s', name[mt], repr(k), repr(v)))
		mt.__orig_newindex(t, k, v)
	end
end

-- Record the initial call(s) to `view:set_theme()` in order to apply it to subsequent views.
local theme, env
rawset(view, 'set_theme', function(_, name_, env_) theme, env = name_, env_ end)
events.connect(events.VIEW_NEW, function() view:set_theme(theme, env) end)
-- Set the command entry theme after initialization and synchronize light/dark editor theme
-- with light/dark GUI mode.
events.connect(events.INITIALIZED, function()
	ui.command_entry:set_theme(theme, env)
	events.connect(events.MODE_CHANGED, function()
		if type(theme) == 'string' then return end -- do not override a manually set theme
		for _, view in ipairs(_VIEWS) do view:set_theme(theme) end -- env/nil
		ui.command_entry:set_theme(theme) -- env/nil
	end)
end)

-- Default buffer and view settings.

local buffer, view = buffer, view

if CURSES then view:set_theme('term') end

-- Multiple Selection and Virtual Space.
buffer.multiple_selection, buffer.additional_selection_typing = true, true
buffer.multi_paste = buffer.MULTIPASTE_EACH
-- buffer.virtual_space_options = buffer.VS_RECTANGULARSELECTION | buffer.VS_USERACCESSIBLE
view.rectangular_selection_modifier = view.MOD_ALT
view.mouse_selection_rectangular_switch = true
-- view.additional_carets_blink = false
-- view.additional_carets_visible = false

-- Undo and Redo.
buffer.undo_selection_history = buffer.UNDO_SELECTION_HISTORY_ENABLED

-- Scrolling.
view:set_x_caret_policy(view.CARET_SLOP, 20)
view:set_y_caret_policy(view.CARET_SLOP | view.CARET_STRICT | view.CARET_EVEN, 1)
view:set_visible_policy(view.VISIBLE_SLOP | view.VISIBLE_STRICT, 5)
-- view.h_scroll_bar = false
-- view.v_scroll_bar = false
view.scroll_width = 1
local function reset_scroll_width() _G.view.scroll_width = 1 end
events.connect(events.BUFFER_NEW, reset_scroll_width)
events.connect(events.BUFFER_AFTER_SWITCH, reset_scroll_width)
events.connect(events.FILE_OPENED, reset_scroll_width)
view.scroll_width_tracking = true
-- view.end_at_last_line = false

-- Whitespace.
-- view.view_ws = view.WS_VISIBLEONLYININDENT
-- view.whitespace_size =
-- view.extra_ascent =
-- view.extra_descent =

-- Line Endings.
-- view.view_eol = true

-- Styling.
if not CURSES then view.idle_styling = view.IDLESTYLING_ALL end

-- Caret and Selection Styles.
-- view.sel_eol_filled = true
-- if not CURSES then view.caret_line_frame = 1 end
view.caret_line_visible_always = true
-- view.caret_line_highlight_subline = true
-- view.caret_period = 0
-- view.caret_style = view.CARETSTYLE_BLOCK
-- view.caret_width =
-- buffer.caret_sticky = buffer.CARETSTICKY_ON

-- Make `view.caret_line_visible_always` apply only to one view at a time, and only while
-- Textadept has focus.
local visible_always
local function save_caret_line_visible_always()
	visible_always, _G.view.caret_line_visible_always = _G.view.caret_line_visible_always, false
end
events.connect(events.VIEW_BEFORE_SWITCH, save_caret_line_visible_always)
events.connect(events.UNFOCUS, save_caret_line_visible_always)
local function restore_caret_line_visible_always()
	if not _G.view.caret_line_visible_always then _G.view.caret_line_visible_always = visible_always end
end
events.connect(events.VIEW_AFTER_SWITCH, restore_caret_line_visible_always)
events.connect(events.FOCUS, restore_caret_line_visible_always)

-- Margins.
-- view.margin_left =
-- view.margin_right =
-- Line Number Margin.
local function resize_line_number_margin(shrinkable)
	-- This needs to be evaluated dynamically since themes/styles can change.
	local view = _G.view -- luacheck: no redefined
	local width = math.max(4, #tostring(_G.buffer.line_count)) *
		view:text_width(view.STYLE_LINENUMBER, '9') + (not CURSES and 4 or 0)
	view.margin_width_n[1] = not shrinkable and math.max(view.margin_width_n[1], width) or width
end
events.connect(events.BUFFER_NEW, resize_line_number_margin)
events.connect(events.VIEW_NEW, resize_line_number_margin)
events.connect(events.FILE_OPENED, resize_line_number_margin)
events.connect(events.RESET_AFTER, resize_line_number_margin)
events.connect(events.ZOOM, function() resize_line_number_margin(true) end)
-- Marker Margin.
view.margin_width_n[2] = not CURSES and 4 or 1
-- Fold Margin.
view.margin_width_n[3] = not CURSES and 12 or 1
view.margin_mask_n[3] = view.MASK_FOLDERS
local function update_fold_margin()
	_G.view._fold_margin_width = math.max(_G.view.margin_width_n[3], _G.view._fold_margin_width or 0)
	_G.view.margin_width_n[3] = _G.buffer.folding and _G.view._fold_margin_width or 0
end
events.connect(events.LEXER_LOADED, update_fold_margin) -- emitted during BUFFER_NEW
events.connect(events.BUFFER_AFTER_SWITCH, update_fold_margin)
events.connect(events.VIEW_AFTER_SWITCH, update_fold_margin)
events.connect(events.VIEW_NEW, update_fold_margin)
-- Other Margins.
for i = 2, view.margins do
	view.margin_sensitive_n[i], view.margin_cursor_n[i] = true, view.CURSORARROW
end

-- Annotations.
view.annotation_visible = not CURSES and view.ANNOTATION_BOXED or view.ANNOTATION_STANDARD
view.eol_annotation_visible = not CURSES and view.EOLANNOTATION_BOXED or view.EOLANNOTATION_STANDARD

-- Other.
-- view.buffered_draw = not GTK
-- buffer.word_chars =
-- buffer.whitespace_chars =
-- buffer.punctuation_chars =

-- Tabs and Indentation Guides.
-- buffer.tab_width = 4
-- buffer.use_tabs = false
-- buffer.indent = 2
-- buffer.tab_indents = false
buffer.back_space_un_indents = true
if not CURSES then view.indentation_guides = view.IV_LOOKBOTH end

-- Margin Markers.
view:marker_define(textadept.bookmarks.MARK_BOOKMARK, view.MARK_FULLRECT)
view:marker_define(textadept.run.MARK_WARNING, view.MARK_FULLRECT)
view:marker_define(textadept.run.MARK_ERROR, view.MARK_FULLRECT)
-- Arrow Folding Symbols.
-- view:marker_define(view.MARKNUM_FOLDEROPEN, view.MARK_ARROWDOWN)
-- view:marker_define(view.MARKNUM_FOLDER, view.MARK_ARROW)
-- view:marker_define(view.MARKNUM_FOLDERSUB, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDERTAIL, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDEREND, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDEROPENMID, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDERMIDTAIL, view.MARK_EMPTY)
-- Plus/Minus Folding Symbols.
-- view:marker_define(view.MARKNUM_FOLDEROPEN, view.MARK_MINUS)
-- view:marker_define(view.MARKNUM_FOLDER, view.MARK_PLUS)
-- view:marker_define(view.MARKNUM_FOLDERSUB, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDERTAIL, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDEREND, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDEROPENMID, view.MARK_EMPTY)
-- view:marker_define(view.MARKNUM_FOLDERMIDTAIL, view.MARK_EMPTY)
-- Circle Tree Folding Symbols.
-- view:marker_define(view.MARKNUM_FOLDEROPEN, view.MARK_CIRCLEMINUS)
-- view:marker_define(view.MARKNUM_FOLDER, view.MARK_CIRCLEPLUS)
-- view:marker_define(view.MARKNUM_FOLDERSUB, view.MARK_VLINE)
-- view:marker_define(view.MARKNUM_FOLDERTAIL, view.MARK_LCORNERCURVE)
-- view:marker_define(view.MARKNUM_FOLDEREND, view.MARK_CIRCLEPLUSCONNECTED)
-- view:marker_define(view.MARKNUM_FOLDEROPENMID, view.MARK_CIRCLEMINUSCONNECTED)
-- view:marker_define(view.MARKNUM_FOLDERMIDTAIL, view.MARK_TCORNERCURVE)
-- Box Tree Folding Symbols.
view:marker_define(view.MARKNUM_FOLDEROPEN, view.MARK_BOXMINUS)
view:marker_define(view.MARKNUM_FOLDER, view.MARK_BOXPLUS)
view:marker_define(view.MARKNUM_FOLDERSUB, view.MARK_VLINE)
view:marker_define(view.MARKNUM_FOLDERTAIL, view.MARK_LCORNER)
view:marker_define(view.MARKNUM_FOLDEREND, view.MARK_BOXPLUSCONNECTED)
view:marker_define(view.MARKNUM_FOLDEROPENMID, view.MARK_BOXMINUSCONNECTED)
view:marker_define(view.MARKNUM_FOLDERMIDTAIL, view.MARK_TCORNER)
-- view:marker_enable_highlight(true)

-- Indicators.
view.indic_style[ui.find.INDIC_FIND] = view.INDIC_ROUNDBOX
view.indic_under[ui.find.INDIC_FIND] = not CURSES
view.indic_style[textadept.editing.INDIC_HIGHLIGHT] = view.INDIC_ROUNDBOX
view.indic_under[textadept.editing.INDIC_HIGHLIGHT] = not CURSES
view.indic_style[textadept.run.INDIC_WARNING] = view.INDIC_SQUIGGLE
view.indic_style[textadept.run.INDIC_ERROR] = view.INDIC_SQUIGGLE
view.indic_style[textadept.snippets.INDIC_PLACEHOLDER] = not CURSES and view.INDIC_DOTBOX or
	view.INDIC_STRAIGHTBOX
for _, kind in ipairs{'MODIFIED', 'SAVED', 'REVERTED_TO_MODIFIED', 'REVERTED_TO_ORIGIN'} do
	view.indic_style[view['INDICATOR_HISTORY_' .. kind .. '_INSERTION']] = view.INDIC_PLAIN
	view.indic_style[view['INDICATOR_HISTORY_' .. kind .. '_DELETION']] = view.INDIC_POINT_TOP
end

-- Autocompletion.
-- buffer.auto_c_separator =
-- buffer.auto_c_cancel_at_start = false
-- buffer.auto_c_fill_ups = '('
buffer.auto_c_choose_single = true
-- buffer.auto_c_ignore_case = true
-- buffer.auto_c_case_insensitive_behavior = buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE
buffer.auto_c_multi = buffer.MULTIAUTOC_EACH
-- buffer.auto_c_auto_hide = false
-- buffer.auto_c_drop_rest_of_word = true
-- buffer.auto_c_type_separator =
-- view.auto_c_max_height =
-- view.auto_c_max_width =
if is_hidpi() then view.auto_c_image_scale = 200 end

-- Call Tips.
view.call_tip_use_style = buffer.tab_width * view:text_width(view.STYLE_CALLTIP, ' ')
-- view.call_tip_position = true

-- Folding.
buffer.folding = true
-- buffer.fold_by_indentation = true
-- buffer.fold_on_zero_sum_lines = true
-- buffer.fold_compact = true
-- Reset lexer properties so their settings get picked up by the __newindex metamethod.
events.connect(events.RESET_BEFORE, function()
	for k in pairs(_G.buffer) do if k:find('^fold') then _G.buffer[k] = nil end end
end)
view.automatic_fold = view.AUTOMATICFOLD_SHOW | view.AUTOMATICFOLD_CLICK | view.AUTOMATICFOLD_CHANGE
-- view.fold_flags = not CURSES and view.FOLDFLAG_LINEAFTER_CONTRACTED or 0
view.fold_display_text_style = view.FOLDDISPLAYTEXT_BOXED
view:set_default_fold_display_text(not CURSES and ' ... ' or '[...]')

-- Line Wrapping.
-- view.wrap_mode = view.WRAP_WHITESPACE
-- view.wrap_visual_flags = view.WRAPVISUALFLAG_MARGIN
-- view.wrap_visual_flags_location = view.WRAPVISUALFLAGLOC_END_BY_TEXT
-- view.wrap_indent_mode = view.WRAPINDENT_SAME
-- view.wrap_start_indent =
view.layout_threads = 1000 -- will be reduced to system specs

-- Long Lines.
-- view.edge_mode = not CURSES and view.EDGE_LINE or view.EDGE_BACKGROUND
-- view.edge_column = 80

-- Accessibility.
-- view.accessibility = view.ACCESSIBILITY_DISABLED

-- Notifications.
if QT and WIN32 then view.mouse_dwell_time = 500 end -- only different here for some reason

-- Load user init file, which may also define default buffer settings.
local user_init = _USERHOME .. '/init.lua'
if lfs.attributes(user_init) then
	local ok, errmsg = pcall(dofile, user_init)
	if not ok then
		events.connect(events.INITIALIZED, function() events.emit(events.ERROR, errmsg) end)
	end
end

-- Generate default buffer settings for subsequent buffers and remove temporary buffer and view
-- metatable listeners.
local load_buffer_settings = load(table.concat(buffer_settings, '\n'))
local load_view_settings = load(table.concat(view_settings, '\n'))
buffer_mt.__index, buffer_mt.__newindex = buffer_mt.__orig_index, buffer_mt.__orig_newindex
view_mt.__index, view_mt.__newindex = view_mt.__orig_index, view_mt.__orig_newindex

-- Sets default properties for a Scintilla document.
events.connect(events.BUFFER_NEW, load_buffer_settings, 1)

-- Sets default properties for a Scintilla window.
events.connect(events.VIEW_NEW, function()
	local view, CTRL, SHIFT = _G.view, view.MOD_CTRL, view.MOD_SHIFT -- luacheck: no redefined
	-- Allow redefinitions of these Scintilla key bindings.
	for _, code in utf8.codes('[]/\\ZYXCVALTDU') do view:clear_cmd_key(code | CTRL << 16) end
	for _, code in utf8.codes('LTUZ') do view:clear_cmd_key(code | (CTRL | SHIFT) << 16) end
	load_view_settings()
	-- The buffer and view APIs have an artificial separation. Some settings like
	-- `buffer.multiple_selection` and `buffer.auto_c_*` actually belong to views, while other
	-- settings like `buffer.tab_width` and `buffer.use_tabs` really do belong to buffers.
	-- Load buffer settings for new views, but retain any true buffer settings overwritten.
	local buffer_props = {
		'eol_mode', 'word_chars', 'whitespace_chars', 'punctuation_chars', 'tab_width', 'use_tabs',
		'indent', 'tab_indents', 'back_space_un_indents'
	}
	for _, prop in ipairs(buffer_props) do buffer_props[prop] = _G.buffer[prop] end
	load_buffer_settings()
	for _, prop in ipairs(buffer_props) do _G.buffer[prop] = buffer_props[prop] end
end, 1)

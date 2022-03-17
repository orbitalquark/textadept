-- Copyright 2007-2022 Mitchell. See LICENSE.

package.path = table.concat({
  _USERHOME .. '/modules/?.lua', _USERHOME .. '/modules/?/init.lua', _HOME .. '/modules/?.lua',
  _HOME .. '/modules/?/init.lua', package.path
}, ';');
package.cpath = table.concat({
  string.format('%s/modules/?.%s', _USERHOME, not WIN32 and 'so' or 'dll'),
  string.format('%s/modules/?.%s', _HOME, not WIN32 and 'so' or 'dll'), package.cpath
}, ';')

-- Populate initial `_G.buffer` with temporarily exported io functions now that it exists. This
-- is needed for menus and key bindings.
for name, f in pairs(io) do if name:find('^_') then buffer[name:sub(2)], io[name] = f, nil end end

textadept = require('textadept')

local SETLEXER = _SCINTILLA.properties.i_lexer[2]

-- Documentation is in core/.view.luadoc.
local function set_theme(view, name, env)
  for k in pairs(lexer.colors) do lexer.colors[k] = nil end -- clear mimic
  if not assert_type(name, 'string', 2):find('[/\\]') then
    name = package.searchpath(name,
      string.format('%s/themes/?.lua;%s/themes/?.lua', _USERHOME, _HOME))
  end
  if not name or not lfs.attributes(name) then return end
  if not assert_type(env, 'table/nil', 3) then env = {} end
  local orig_view = _G.view
  if view ~= orig_view then ui.goto_view(view) end
  -- In the event the command entry is calling this function, tell the LPeg lexer that this view
  -- (LexerLPeg instance) is the one to set styles for (as opposed to the command entry's view).
  -- See note in LexerLPeg::Init(). Otherwise, this call is harmless and does not end up doing
  -- much extra work.
  buffer:private_lexer_call(SETLEXER, buffer._lexer or 'text')
  loadfile(name, 't', setmetatable(env, {__index = _G}))()
  -- Force reload of all styles since the current lexer may have defined its own styles. (The
  -- LPeg lexer has only refreshed default lexer styles.)
  -- Note: cannot use `buffer.set_lexer()` because it may not exist yet.
  buffer:private_lexer_call(SETLEXER, buffer._lexer or 'text')
  if view ~= orig_view then ui.goto_view(orig_view) end
end
events.connect(events.VIEW_NEW, function() view.set_theme = set_theme end)
view.set_theme = set_theme -- needed for the first view
-- On reset, _LOADED['lexer'] is removed. Force a reload in order for set_theme to work properly.
if not arg then view:goto_buffer(buffer) end

-- The remainder of this file defines default buffer and view properties and applies them to
-- subsequent buffers and views. Normally, a setting like `buffer.use_tabs = false` only applies
-- to the current (initial) buffer.However, temporarily tap into buffer and view's metatables in
-- order to capture these initial settings (both from Textadept's init.lua and from the user's
-- init.lua) so they can be applied to subsequent buffers and views.

local settings = {}

local buffer_mt, view_mt = getmetatable(buffer), getmetatable(view)
local function repr(v) return string.format(type(v) == 'string' and '%q' or '%s', v) end
for _, mt in ipairs{buffer_mt, view_mt} do
  mt.__orig_index, mt.__orig_newindex = mt.__index, mt.__newindex
  mt.__index = function(t, k)
    local v = mt.__orig_index(t, k)
    if type(v) == 'function' then
      return function(...)
        local args = {...}
        if type(args[1]) == 'table' then table.remove(args, 1) end -- self
        for i = 1, #args do args[i] = repr(args[i]) end
        settings[#settings + 1] = string.format('buffer:%s(%s)', k, table.concat(args, ','))
        return v(...)
      end
    elseif type(v) == 'table' then
      local property_mt = getmetatable(v)
      setmetatable(v, {
        __index = property_mt.__index, __newindex = function(property, k2, v2)
          settings[#settings + 1] = string.format('buffer.%s[%s]=%s', k, repr(k2), repr(v2))
          local ok, errmsg = pcall(property_mt.__newindex, property, k2, v2)
          if not ok then error(errmsg, 2) end
        end
      })
    end
    return v
  end
  mt.__newindex = function(t, k, v)
    settings[#settings + 1] = string.format('buffer[%s]=%s', repr(k), repr(v))
    mt.__orig_newindex(t, k, v)
  end
end

-- Mimic the `lexer` module because (1) it is not yet available and (2) even if it was, color,
-- style, and property settings would not be captured during init.
local property = view.property
local colors = setmetatable({}, {
  __newindex = function(t, name, color)
    if type(color) == 'string' then
      local r, g, b = color:match('^#(%x%x)(%x%x)(%x%x)$')
      color = tonumber(string.format('%s%s%s', b, g, r), 16) or 0
    end
    property['color.' .. name] = color
    rawset(t, name, color) -- cache instead of __index for property[...]
  end
})
local styles = setmetatable({}, {
  __newindex = function(_, name, props)
    local settings = {}
    for k, v in pairs(props) do
      settings[#settings + 1] = type(v) ~= 'boolean' and string.format('%s:%s', k, v) or
        string.format('%s%s', v and '' or 'not', k)
    end
    property['style.' .. name] = table.concat(settings, ',')
  end
})
lexer = setmetatable({colors = colors, styles = styles}, {
  __newindex = function(_, k, v)
    property[k ~= 'folding' and k:gsub('_', '.') or 'fold'] = v and '1' or '0'
  end
})

-- Default buffer and view settings.

local buffer, view = buffer, view
view:set_theme(not CURSES and 'light' or 'term')

-- Multiple Selection and Virtual Space
buffer.multiple_selection, buffer.additional_selection_typing = true, true
buffer.multi_paste = buffer.MULTIPASTE_EACH
-- buffer.virtual_space_options = buffer.VS_RECTANGULARSELECTION | buffer.VS_USERACCESSIBLE
view.rectangular_selection_modifier = view.MOD_ALT
view.mouse_selection_rectangular_switch = true
-- view.additional_carets_blink = false
-- view.additional_carets_visible = false

-- Scrolling.
view:set_x_caret_policy(view.CARET_SLOP, 20)
view:set_y_caret_policy(view.CARET_SLOP | view.CARET_STRICT | view.CARET_EVEN, 1)
view:set_visible_policy(view.VISIBLE_SLOP | view.VISIBLE_STRICT, 5)
-- view.h_scroll_bar = CURSES
-- view.v_scroll_bar = false
if CURSES and not (WIN32 or LINUX or BSD) then view.v_scroll_bar = false end
-- view.scroll_width =
-- view.scroll_width_tracking = true
-- view.end_at_last_line = false

-- Whitespace
view.view_ws = view.WS_INVISIBLE
-- view.whitespace_size =
-- view.extra_ascent =
-- view.extra_descent =

-- Line Endings
buffer.eol_mode = WIN32 and buffer.EOL_CRLF or buffer.EOL_LF
view.view_eol = false

-- Styling
if not CURSES then view.idle_styling = view.IDLESTYLING_ALL end

-- Caret and Selection Styles.
-- view.sel_eol_filled = true
-- view.caret_line_visible_always = true
-- view.caret_period = 0
-- view.caret_style = view.CARETSTYLE_BLOCK
-- view.caret_width =
-- buffer.caret_sticky = buffer.CARETSTICKY_ON

-- Margins.
-- view.margin_left =
-- view.margin_right =
-- Line Number Margin.
view.margin_type_n[1] = view.MARGIN_NUMBER
local function resize_line_number_margin(shrinkable)
  -- This needs to be evaluated dynamically since themes/styles can change.
  local buffer, view = _G.buffer, _G.view
  local width = math.max(4, #tostring(buffer.line_count)) *
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
-- Other Margins.
for i = 2, view.margins do
  view.margin_type_n[i] = view.MARGIN_SYMBOL
  view.margin_sensitive_n[i], view.margin_cursor_n[i] = true, view.CURSORARROW
  if i > 3 then view.margin_width_n[i] = 0 end
end

-- Annotations.
view.annotation_visible = view.ANNOTATION_BOXED
view.eol_annotation_visible = view.EOLANNOTATION_BOXED

-- Other.
buffer.buffered_draw = not CURSES and not OSX -- Quartz buffers drawing on macOS
-- buffer.word_chars =
-- buffer.whitespace_chars =
-- buffer.punctuation_chars =

-- Tabs and Indentation Guides.
-- Note: tab and indentation settings apply to individual buffers.
buffer.tab_width, buffer.use_tabs = 2, false
-- buffer.indent = 2
buffer.tab_indents, buffer.back_space_un_indents = true, true
view.indentation_guides = not CURSES and view.IV_LOOKBOTH or view.IV_NONE

-- Margin Markers.
view:marker_define(textadept.bookmarks.MARK_BOOKMARK, view.MARK_FULLRECT)
view:marker_define(textadept.run.MARK_WARNING, view.MARK_FULLRECT)
view:marker_define(textadept.run.MARK_ERROR, view.MARK_FULLRECT)
-- Arrow Folding Symbols.
-- view:marker_define(buffer.MARKNUM_FOLDEROPEN, view.MARK_ARROWDOWN)
-- view:marker_define(buffer.MARKNUM_FOLDER, view.MARK_ARROW)
-- view:marker_define(buffer.MARKNUM_FOLDERSUB, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDERTAIL, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDEREND, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDEROPENMID, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, view.MARK_EMPTY)
-- Plus/Minus Folding Symbols.
-- view:marker_define(buffer.MARKNUM_FOLDEROPEN, view.MARK_MINUS)
-- view:marker_define(buffer.MARKNUM_FOLDER, view.MARK_PLUS)
-- view:marker_define(buffer.MARKNUM_FOLDERSUB, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDERTAIL, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDEREND, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDEROPENMID, view.MARK_EMPTY)
-- view:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, view.MARK_EMPTY)
-- Circle Tree Folding Symbols.
-- view:marker_define(buffer.MARKNUM_FOLDEROPEN, view.MARK_CIRCLEMINUS)
-- view:marker_define(buffer.MARKNUM_FOLDER, view.MARK_CIRCLEPLUS)
-- view:marker_define(buffer.MARKNUM_FOLDERSUB, view.MARK_VLINE)
-- view:marker_define(buffer.MARKNUM_FOLDERTAIL, view.MARK_LCORNERCURVE)
-- view:marker_define(buffer.MARKNUM_FOLDEREND, view.MARK_CIRCLEPLUSCONNECTED)
-- view:marker_define(buffer.MARKNUM_FOLDEROPENMID, view.MARK_CIRCLEMINUSCONNECTED)
-- view:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, view.MARK_TCORNERCURVE)
-- Box Tree Folding Symbols.
view:marker_define(buffer.MARKNUM_FOLDEROPEN, view.MARK_BOXMINUS)
view:marker_define(buffer.MARKNUM_FOLDER, view.MARK_BOXPLUS)
view:marker_define(buffer.MARKNUM_FOLDERSUB, view.MARK_VLINE)
view:marker_define(buffer.MARKNUM_FOLDERTAIL, view.MARK_LCORNER)
view:marker_define(buffer.MARKNUM_FOLDEREND, view.MARK_BOXPLUSCONNECTED)
view:marker_define(buffer.MARKNUM_FOLDEROPENMID, view.MARK_BOXMINUSCONNECTED)
view:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, view.MARK_TCORNER)
-- view:marker_enable_highlight(true)

-- Indicators.
view.indic_style[ui.find.INDIC_FIND] = view.INDIC_ROUNDBOX
view.indic_under[ui.find.INDIC_FIND] = not CURSES
view.indic_style[textadept.editing.INDIC_BRACEMATCH] = view.INDIC_BOX
view:brace_highlight_indicator(not CURSES, textadept.editing.INDIC_BRACEMATCH)
view.indic_style[textadept.editing.INDIC_HIGHLIGHT] = view.INDIC_ROUNDBOX
view.indic_under[textadept.editing.INDIC_HIGHLIGHT] = not CURSES
view.indic_style[textadept.snippets.INDIC_PLACEHOLDER] = not CURSES and view.INDIC_DOTBOX or
  view.INDIC_STRAIGHTBOX

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

-- Call Tips.
view.call_tip_use_style = buffer.tab_width * view:text_width(view.STYLE_CALLTIP, ' ')
-- view.call_tip_position = true

-- Folding.
lexer.folding = true
-- lexer.fold_by_indentation = true
-- lexer.fold_line_groups = true
-- lexer.fold_on_zero_sum_lines = true
-- lexer.fold_compact = true
view.automatic_fold = view.AUTOMATICFOLD_SHOW | view.AUTOMATICFOLD_CLICK | view.AUTOMATICFOLD_CHANGE
view.fold_flags = not CURSES and view.FOLDFLAG_LINEAFTER_CONTRACTED or 0
view.fold_display_text_style = view.FOLDDISPLAYTEXT_BOXED

-- Line Wrapping.
view.wrap_mode = view.WRAP_NONE
-- view.wrap_visual_flags = view.WRAPVISUALFLAG_MARGIN
-- view.wrap_visual_flags_location = view.WRAPVISUALFLAGLOC_END_BY_TEXT
-- view.wrap_indent_mode = view.WRAPINDENT_SAME
-- view.wrap_start_indent =
view.layout_threads = 1000 -- will be reduced to system specs

-- Long Lines.
-- view.edge_mode = not CURSES and view.EDGE_LINE or view.EDGE_BACKGROUND
-- view.edge_column = 80

-- Accessibility.
buffer.accessibility = buffer.ACCESSIBILITY_DISABLED

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
local load_settings = load(table.concat(settings, '\n'))
for _, mt in ipairs{buffer_mt, view_mt} do
  mt.__index, mt.__newindex = mt.__orig_index, mt.__orig_newindex
end

local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLUASTATE = _SCINTILLA.functions.change_lexer_state[1]
local CREATELOADER = _SCINTILLA.functions.create_loader[1]
-- Sets default properties for a Scintilla document.
events.connect(events.BUFFER_NEW, function()
  local buffer = _G.buffer
  buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLUASTATE, _LUA)
  buffer:private_lexer_call(CREATELOADER, _USERHOME .. '/lexers')
  buffer:private_lexer_call(CREATELOADER, _HOME .. '/lexers')
  load_settings()
  buffer:private_lexer_call(SETLEXER, 'text')
  _G.lexer = require('lexer') -- replace mimic
  if buffer == ui.command_entry then ui.command_entry.caret_line_visible = false end
end, 1)

-- Sets default properties for a Scintilla window.
events.connect(events.VIEW_NEW, function()
  local buffer, view = _G.buffer, _G.view
  -- Allow redefinitions of these Scintilla key bindings.
  for _, code in utf8.codes('[]/\\ZYXCVALTDU') do view:clear_cmd_key(code | view.MOD_CTRL << 16) end
  for _, code in utf8.codes('LTUZ') do
    view:clear_cmd_key(code | (view.MOD_CTRL | view.MOD_SHIFT) << 16)
  end
  -- Since BUFFER_NEW loads themes and settings on startup, only load them for subsequent views.
  if #_VIEWS == 1 then return end
  load_settings()
  -- Refresh styles in case a lexer has extra style settings. When load_settings() calls
  -- `view.property['style.default'] = ...`, the LPeg lexer resets all styles to that default.
  -- However, some lexers have extra style settings that are not set by load_settings(), and
  -- thus need refreshing. This is not an issue in BUFFER_NEW since a lexer is set immediately
  -- afterwards, which refreshes styles.
  -- Note: `buffer:set_lexer()` is insufficient for some reason.
  buffer:private_lexer_call(SETLEXER, buffer._lexer or 'text')
end, 1)

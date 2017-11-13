-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

package.path = table.concat({
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua', _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua', _HOME..'/modules/?/init.lua',
  package.path
}, ';');
local so = not WIN32 and '/?.so' or '/?.dll'
package.cpath = table.concat({
  _USERHOME..so, _USERHOME..'/modules'..so, _HOME..'/modules'..so, package.cpath
}, ';')

textadept = require('textadept')

-- Documentation is in core/.buffer.luadoc.
function buffer.set_theme(name, props)
  name = name:find('[/\\]') and name or
         package.searchpath(name, _USERHOME..'/themes/?.lua;'..
                                  _HOME..'/themes/?.lua')
  if not name or not lfs.attributes(name) then return end
  dofile(name)
  for prop, value in pairs(props or {}) do buffer.property[prop] = value end
end
-- On reset, _LOADED['lexer'] is removed. Force a reload in order for set_theme
-- to work properly.
if not arg then view:goto_buffer(buffer) end

-- The remainder of this file defines default buffer properties and applies them
-- to subsequent buffers. Normally, a setting like `buffer.use_tabs = false`
-- only applies to the current (initial) buffer. However, temporarily tap into
-- buffer's metatable in order to capture these initial buffer settings (both
-- from Textadept's init.lua and from the user's init.lua).

local settings = {}

local buffer_mt = getmetatable(buffer)
local orig__index, orig__newindex = buffer_mt.__index, buffer_mt.__newindex
local function repr(v)
  return type(v) == 'string' and string.format("%q", v) or tostring(v)
end
buffer_mt.__index = function(buffer, k)
  local v = orig__index(buffer, k)
  if type(v) == 'function' then
    return function(...)
      local args = {...}
      if type(args[1]) == 'table' then table.remove(args, 1) end -- ignore self
      for i = 1, #args do args[i] = repr(args[i]) end
      settings[#settings + 1] = string.format("buffer:%s(%s)", k,
                                              table.concat(args, ','))
      return v(...)
    end
  elseif type(v) == 'table' then
    local property_mt = getmetatable(v)
    setmetatable(v, {
      __index = property_mt.__index,
      __newindex = function(property, k2, v2)
        settings[#settings + 1] = string.format("buffer.%s[%s]=%s", k, repr(k2),
                                                repr(v2))
        property_mt.__newindex(property, k2, v2)
      end
    })
  end
  return v
end
buffer_mt.__newindex = function(buffer, k, v)
  settings[#settings + 1] = string.format("buffer[%s]=%s", repr(k), repr(v))
  orig__newindex(buffer, k, v)
end

-- Default buffer settings.

local buffer = buffer
buffer.set_theme(not CURSES and 'light' or 'term')

-- Multiple Selection and Virtual Space
buffer.multiple_selection = true
buffer.additional_selection_typing = true
--buffer.multi_paste = buffer.MULTIPASTE_EACH
--buffer.virtual_space_options = buffer.VS_RECTANGULARSELECTION +
--                               buffer.VS_USERACCESSIBLE
buffer.rectangular_selection_modifier = buffer.MOD_ALT
buffer.mouse_selection_rectangular_switch = true
--buffer.additional_carets_blink = false
--buffer.additional_carets_visible = false

-- Scrolling.
buffer:set_x_caret_policy(buffer.CARET_SLOP, 20)
buffer:set_y_caret_policy(buffer.CARET_SLOP + buffer.CARET_STRICT +
  buffer.CARET_EVEN, 1)
buffer:set_visible_policy(buffer.VISIBLE_SLOP + buffer.VISIBLE_STRICT, 5)
--buffer.h_scroll_bar = CURSES
--buffer.v_scroll_bar = false
if CURSES and not (WIN32 or LINUX or BSD) then buffer.v_scroll_bar = false end
--buffer.scroll_width =
--buffer.scroll_width_tracking = true
--buffer.end_at_last_line = false

-- Whitespace
buffer.view_ws = buffer.WS_INVISIBLE
--buffer.whitespace_size =
--buffer.extra_ascent =
--buffer.extra_descent =

-- Line Endings
buffer.view_eol = false

-- Styling
if not CURSES then buffer.idle_styling = buffer.IDLESTYLING_ALL end

-- Caret and Selection Styles.
--buffer.sel_eol_filled = true
buffer.caret_line_visible = not CURSES
--buffer.caret_line_visible_always = true
--buffer.caret_period = 0
--buffer.caret_style = buffer.CARETSTYLE_BLOCK
--buffer.caret_width =
--buffer.caret_sticky = buffer.CARETSTICKY_ON

-- Margins.
--buffer.margin_left =
--buffer.margin_right =
-- Line Number Margin.
buffer.margin_type_n[0] = buffer.MARGIN_NUMBER
local width = 4 * buffer:text_width(buffer.STYLE_LINENUMBER, '9')
buffer.margin_width_n[0] = width + (not CURSES and 4 or 0)
-- Marker Margin.
buffer.margin_width_n[1] = not CURSES and 4 or 1
-- Fold Margin.
buffer.margin_width_n[2] = not CURSES and 12 or 1
buffer.margin_mask_n[2] = buffer.MASK_FOLDERS
-- Other Margins.
for i = 1, buffer.margins - 1 do
  buffer.margin_type_n[i] = buffer.MARGIN_SYMBOL
  buffer.margin_sensitive_n[i] = true
  buffer.margin_cursor_n[i] = buffer.CURSORARROW
  if i > 2 then buffer.margin_width_n[i] = 0 end
end

-- Annotations.
buffer.annotation_visible = buffer.ANNOTATION_BOXED

-- Other.
--buffer.word_chars =
--buffer.whitespace_chars =
--buffer.punctuation_chars =

-- Tabs and Indentation Guides.
-- Note: tab and indentation settings apply to individual buffers.
buffer.tab_width = 2
buffer.use_tabs = false
--buffer.indent = 2
buffer.tab_indents = true
buffer.back_space_un_indents = true
buffer.indentation_guides = not CURSES and buffer.IV_LOOKBOTH or buffer.IV_NONE

-- Margin Markers.
buffer:marker_define(textadept.bookmarks.MARK_BOOKMARK, buffer.MARK_FULLRECT)
buffer:marker_define(textadept.run.MARK_WARNING, buffer.MARK_FULLRECT)
buffer:marker_define(textadept.run.MARK_ERROR, buffer.MARK_FULLRECT)
-- Arrow Folding Symbols.
--buffer:marker_define(buffer.MARKNUM_FOLDEROPEN, buffer.MARK_ARROWDOWN)
--buffer:marker_define(buffer.MARKNUM_FOLDER, buffer.MARK_ARROW)
--buffer:marker_define(buffer.MARKNUM_FOLDERSUB, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDERTAIL, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDEREND, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDEROPENMID, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, buffer.MARK_EMPTY)
-- Plus/Minus Folding Symbols.
--buffer:marker_define(buffer.MARKNUM_FOLDEROPEN, buffer.MARK_MINUS)
--buffer:marker_define(buffer.MARKNUM_FOLDER, buffer.MARK_PLUS)
--buffer:marker_define(buffer.MARKNUM_FOLDERSUB, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDERTAIL, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDEREND, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDEROPENMID, buffer.MARK_EMPTY)
--buffer:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, buffer.MARK_EMPTY)
-- Circle Tree Folding Symbols.
--buffer:marker_define(buffer.MARKNUM_FOLDEROPEN, buffer.MARK_CIRCLEMINUS)
--buffer:marker_define(buffer.MARKNUM_FOLDER, buffer.MARK_CIRCLEPLUS)
--buffer:marker_define(buffer.MARKNUM_FOLDERSUB, buffer.MARK_VLINE)
--buffer:marker_define(buffer.MARKNUM_FOLDERTAIL, buffer.MARK_LCORNERCURVE)
--buffer:marker_define(buffer.MARKNUM_FOLDEREND,
--                     buffer.MARK_CIRCLEPLUSCONNECTED)
--buffer:marker_define(buffer.MARKNUM_FOLDEROPENMID,
--                     buffer.MARK_CIRCLEMINUSCONNECTED)
--buffer:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, buffer.MARK_TCORNERCURVE)
-- Box Tree Folding Symbols.
buffer:marker_define(buffer.MARKNUM_FOLDEROPEN, buffer.MARK_BOXMINUS)
buffer:marker_define(buffer.MARKNUM_FOLDER, buffer.MARK_BOXPLUS)
buffer:marker_define(buffer.MARKNUM_FOLDERSUB, buffer.MARK_VLINE)
buffer:marker_define(buffer.MARKNUM_FOLDERTAIL, buffer.MARK_LCORNER)
buffer:marker_define(buffer.MARKNUM_FOLDEREND, buffer.MARK_BOXPLUSCONNECTED)
buffer:marker_define(buffer.MARKNUM_FOLDEROPENMID,
                     buffer.MARK_BOXMINUSCONNECTED)
buffer:marker_define(buffer.MARKNUM_FOLDERMIDTAIL, buffer.MARK_TCORNER)
--buffer:marker_enable_highlight(true)

-- Indicators.
buffer.indic_style[ui.find.INDIC_FIND] = buffer.INDIC_ROUNDBOX
if not CURSES then buffer.indic_under[ui.find.INDIC_FIND] = true end
local INDIC_BRACEMATCH = textadept.editing.INDIC_BRACEMATCH
buffer.indic_style[INDIC_BRACEMATCH] = buffer.INDIC_BOX
buffer:brace_highlight_indicator(not CURSES, INDIC_BRACEMATCH)
local INDIC_HIGHLIGHT = textadept.editing.INDIC_HIGHLIGHT
buffer.indic_style[INDIC_HIGHLIGHT] = buffer.INDIC_ROUNDBOX
if not CURSES then buffer.indic_under[INDIC_HIGHLIGHT] = true end
local INDIC_PLACEHOLDER = textadept.snippets.INDIC_PLACEHOLDER
buffer.indic_style[INDIC_PLACEHOLDER] = not CURSES and buffer.INDIC_DOTBOX or
                                        buffer.INDIC_STRAIGHTBOX

-- Autocompletion.
--buffer.auto_c_separator =
--buffer.auto_c_cancel_at_start = false
--buffer.auto_c_fill_ups = '('
buffer.auto_c_choose_single = true
--buffer.auto_c_ignore_case = true
--buffer.auto_c_case_insensitive_behaviour =
--  buffer.CASEINSENSITIVEBEHAVIOUR_IGNORECASE
buffer.auto_c_multi = buffer.MULTIAUTOC_EACH
--buffer.auto_c_auto_hide = false
--buffer.auto_c_drop_rest_of_word = true
--buffer.auto_c_type_separator =
--buffer.auto_c_max_height =
--buffer.auto_c_max_width =

-- Call Tips.
buffer.call_tip_use_style = buffer.tab_width *
                            buffer:text_width(buffer.STYLE_CALLTIP, ' ')
--buffer.call_tip_position = true

-- Folding.
buffer.property['fold'] = '1'
--buffer.property['fold.by.indentation'] = '1'
--buffer.property['fold.line.comments'] = '1'
--buffer.property['fold.on.zero.sum.lines'] = '1'
buffer.automatic_fold = buffer.AUTOMATICFOLD_SHOW + buffer.AUTOMATICFOLD_CLICK +
                        buffer.AUTOMATICFOLD_CHANGE
buffer.fold_flags = not CURSES and buffer.FOLDFLAG_LINEAFTER_CONTRACTED or 0
buffer.fold_display_text_style = buffer.FOLDDISPLAYTEXT_BOXED

-- Line Wrapping.
buffer.wrap_mode = buffer.WRAP_NONE
--buffer.wrap_visual_flags = buffer.WRAPVISUALFLAG_MARGIN
--buffer.wrap_visual_flags_location = buffer.WRAPVISUALFLAGLOC_END_BY_TEXT
--buffer.wrap_indent_mode = buffer.WRAPINDENT_SAME
--buffer.wrap_start_indent =

-- Long Lines.
--buffer.edge_mode = not CURSES and buffer.EDGE_LINE or buffer.EDGE_BACKGROUND
--buffer.edge_column = 80

-- Accessibility.
buffer.accessibility = buffer.ACCESSIBILITY_DISABLED

-- Load user init file, which may also define default buffer settings.
local user_init = _USERHOME..'/init.lua'
if lfs.attributes(user_init) then dofile(user_init) end

-- Generate default buffer settings for subsequent buffers and remove temporary
-- buffer metatable listener.
local load_settings = load(table.concat(settings, '\n'))
buffer_mt.__index, buffer_mt.__newindex = orig__index, orig__newindex

-- Sets default properties for a Scintilla document.
events.connect(events.BUFFER_NEW, function()
  local buffer = _G.buffer
  local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
  local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
  local SETLUASTATE = _SCINTILLA.functions.change_lexer_state[1]
  local SETLEXERLANGUAGE = _SCINTILLA.properties.lexer_language[2]
  buffer.lexer_language = 'lpeg'
  buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLUASTATE, _LUA)
  buffer.property['lexer.lpeg.home'] = _USERHOME..'/lexers/?.lua;'..
                                       _HOME..'/lexers'
  load_settings()
  buffer:private_lexer_call(SETLEXERLANGUAGE, 'text')
  if buffer == ui.command_entry then buffer.caret_line_visible = false end
end, 1)

-- Sets default properties for a Scintilla window.
events.connect(events.VIEW_NEW, function()
  local buffer = _G.buffer
  -- Allow redefinitions of these Scintilla key commands.
  local ctrl_keys = {
    '[', ']', '/', '\\', 'Z', 'Y', 'X', 'C', 'V', 'A', 'L', 'T', 'D', 'U'
  }
  local ctrl_shift_keys = {'L', 'T', 'U', 'Z'}
  for i = 1, #ctrl_keys do
    buffer:clear_cmd_key(string.byte(ctrl_keys[i]) +
                         bit32.lshift(buffer.MOD_CTRL, 16))
  end
  for i = 1, #ctrl_shift_keys do
    buffer:clear_cmd_key(string.byte(ctrl_shift_keys[i]) +
                         bit32.lshift(buffer.MOD_CTRL + buffer.MOD_SHIFT, 16))
  end
  -- Since BUFFER_NEW loads themes and settings on startup, only load them for
  -- subsequent views.
  if #_VIEWS > 1 then load_settings() end
end, 1)

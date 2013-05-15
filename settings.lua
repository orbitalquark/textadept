-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local buffer = buffer
local c = _SCINTILLA.constants

-- Multiple Selection and Virtual Space
buffer.multiple_selection = true
buffer.additional_selection_typing = true
--buffer.multi_paste = c.SC_MULTIPASTE_EACH
--buffer.virtual_space_options = c.SCVS_RECTANGULARSELECTION +
--                               c.SCVS_USERACCESSIBLE
buffer.rectangular_selection_modifier = (WIN32 or OSX) and c.SCMOD_ALT or
                                                           c.SCMOD_SUPER
--buffer.additional_carets_blink = false
--buffer.additional_carets_visible = false

-- Scrolling.
buffer:set_x_caret_policy(1, 20) -- CARET_SLOP
buffer:set_y_caret_policy(13, 1) -- CARET_SLOP | CARET_STRICT | CARET_EVEN
--buffer:set_visible_policy()
--buffer.h_scroll_bar = false
--buffer.v_scroll_bar = false
--buffer.x_offset =
--buffer.scroll_width =
--buffer.scroll_width_tracking = true
--buffer.end_at_last_line = false

-- Whitespace
--buffer.view_ws = c.SCWS_VISIBLEALWAYS
--buffer.whitespace_size =
--buffer.extra_ascent =
--buffer.extra_descent =

-- Line Endings
--buffer.view_eol = true

-- Caret and Selection Styles.
--buffer.sel_eol_filled = true
buffer.caret_line_visible = not CURSES
--buffer.caret_line_visible_always = true
--buffer.caret_period = 0
--buffer.caret_style = c.CARETSTYLE_BLOCK
--buffer.caret_width =
--buffer.caret_sticky = c.SC_CARETSTICKY_ON

-- Line Number Margin.
local width = 4 * buffer:text_width(c.STYLE_LINENUMBER, '9')
buffer.margin_width_n[0] = width + (not CURSES and 4 or 0)

-- Marker Margin.
buffer.margin_width_n[1] = not CURSES and 0 or 1

-- Fold Margin.
buffer.margin_width_n[2] = not CURSES and 10 or 1
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true
--buffer.margin_left =
--buffer.margin_right =

-- Annotations.
buffer.annotation_visible = c.ANNOTATION_BOXED

-- Other.
buffer.buffered_draw = not CURSES and not OSX -- Quartz buffers drawing on OSX
--buffer.two_phase_draw = false

-- Tabs and Indentation Guides.
-- Note: tab and indentation settings apply to individual buffers.
buffer.tab_width = 2
buffer.use_tabs = false
--buffer.indent = 2
buffer.tab_indents = true
buffer.back_space_un_indents = true
buffer.indentation_guides = c.SC_IV_LOOKBOTH

-- Fold Margin Markers.
if not CURSES then
  buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_ARROWDOWN)
  buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_ARROW)
  buffer:marker_define(c.SC_MARKNUM_FOLDERSUB, c.SC_MARK_EMPTY)
  buffer:marker_define(c.SC_MARKNUM_FOLDERTAIL, c.SC_MARK_EMPTY)
  buffer:marker_define(c.SC_MARKNUM_FOLDEREND, c.SC_MARK_EMPTY)
  buffer:marker_define(c.SC_MARKNUM_FOLDEROPENMID, c.SC_MARK_EMPTY)
  buffer:marker_define(c.SC_MARKNUM_FOLDERMIDTAIL, c.SC_MARK_EMPTY)
end

-- Autocompletion.
--buffer.auto_c_cancel_at_start = false
buffer.auto_c_choose_single = true
--buffer.auto_c_auto_hide = false
--buffer.auto_c_max_height =
--buffer.auto_c_max_width =

-- Call Tips.
buffer.call_tip_use_style = buffer.tab_width *
                            buffer:text_width(c.STYLE_CALLTIP, ' ')

-- Folding.
buffer.property['fold'] = '1'
buffer.property['fold.by.indentation'] = '1'
buffer.property['fold.line.comments'] = '0'
buffer.fold_flags = not CURSES and c.SC_FOLDFLAG_LINEAFTER_CONTRACTED or 0

-- Line Wrapping.
--buffer.wrap_mode = c.SC_WRAP_WORD
--buffer.wrap_visual_flags = c.SC_WRAPVISUALFLAG_MARGIN
--buffer.wrap_visual_flags_location = c.SC_WRAPVISUALFLAGLOC_END_BY_TEXT
--buffer.wrap_indent_mode = c.SC_WRAPINDENT_SAME
--buffer.wrap_start_indent =

-- Long Lines.
--buffer.edge_mode = not CURSES and c.EDGE_LINE or c.EDGE_BACKGROUND
--buffer.edge_column = 80

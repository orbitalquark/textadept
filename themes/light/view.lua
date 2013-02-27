-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Light editor theme for Textadept.

local c = _SCINTILLA.constants
local buffer = buffer

-- Multiple Selection and Virtual Space
buffer.multiple_selection = true
buffer.additional_selection_typing = true
--buffer.multi_paste = c.SC_MULTIPASTE_EACH
--buffer.virtual_space_options = c.SCVS_RECTANGULARSELECTION +
--                               c.SCVS_USERACCESSIBLE
buffer.rectangular_selection_modifier = (WIN32 or OSX) and c.SCMOD_ALT or
                                                           c.SCMOD_SUPER
--buffer.additional_sel_alpha =
--buffer.additional_sel_fore =
--buffer.additional_sel_back =
--buffer.additional_caret_fore =
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
buffer:set_sel_fore(true, 0x333333)
buffer:set_sel_back(true, 0x999999)
--buffer.sel_alpha =
--buffer.sel_eol_filled = true
buffer.caret_fore = 0x4D4D4D
buffer.caret_line_visible = true
--buffer.caret_line_visible_always = true
buffer.caret_line_back = 0xCCCCCC
--buffer.caret_line_back_alpha =
--buffer.caret_period = 0
--buffer.caret_style = c.CARETSTYLE_BLOCK
--buffer.caret_width =
--buffer.caret_sticky = c.SC_CARETSTICKY_ON

-- Line Number Margin.
buffer.margin_width_n[0] = 4 + 4 * buffer:text_width(c.STYLE_LINENUMBER, '9')

-- Marker Margin.
buffer.margin_width_n[1] = 0 -- marker margin invisible

-- Fold Margin.
buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
buffer.margin_width_n[2] = 10
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true
--buffer.margin_left =
--buffer.margin_right =
buffer:set_fold_margin_colour(true, 0xE6E6E6)
buffer:set_fold_margin_hi_colour(true, 0xE6E6E6)

-- Annotations.
buffer.annotation_visible = c.ANNOTATION_BOXED

-- Other.
--buffer.buffered_draw = false
--buffer.two_phase_draw = false

-- Indentation Guides.
buffer.indentation_guides = c.SC_IV_LOOKBOTH

-- Fold Margin Markers.
buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_ARROWDOWN)
buffer.marker_fore[c.SC_MARKNUM_FOLDEROPEN] = 0x808080
buffer.marker_back[c.SC_MARKNUM_FOLDEROPEN] = 0x808080
buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_ARROW)
buffer.marker_fore[c.SC_MARKNUM_FOLDER] = 0x808080
buffer.marker_back[c.SC_MARKNUM_FOLDER] = 0x808080
buffer:marker_define(c.SC_MARKNUM_FOLDERSUB, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERTAIL, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEREND, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEROPENMID, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERMIDTAIL, c.SC_MARK_EMPTY)

-- Autocompletion.
--buffer.auto_c_cancel_at_start = false
buffer.auto_c_choose_single = true
--buffer.auto_c_auto_hide = false
--buffer.auto_c_max_height =
--buffer.auto_c_max_width =

-- Call Tips.
--buffer.call_tip_use_style =

-- Folding.
buffer.fold_flags = c.SC_FOLDFLAG_LINEAFTER_CONTRACTED

-- Line Wrapping.
--buffer.wrap_mode = c.SC_WRAP_WORD
--buffer.wrap_visual_flags = c.SC_WRAPVISUALFLAG_MARGIN
--buffer.wrap_visual_flags_location = c.SC_WRAPVISUALFLAGLOC_END_BY_TEXT
--buffer.wrap_indent_mode = c.SC_WRAPINDENT_SAME
--buffer.wrap_start_indent =

-- Long Lines.
--buffer.edge_mode = c.EDGE_LINE
--buffer.edge_column = 80
--buffer.edge_colour = 0x808080

-- Notifications.
buffer.mod_event_mask = c.SC_MOD_CHANGEFOLD

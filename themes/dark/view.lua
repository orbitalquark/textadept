-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Dark editor theme for Textadept.

local c = _SCINTILLA.constants
local buffer = buffer

-- Multiple Selection and Virtual Space
buffer.multiple_selection = true
buffer.additional_selection_typing = true
--buffer.multi_paste = 1
--buffer.virtual_space_options = 3
if not WIN32 and not OSX then buffer.rectangular_selection_modifier = 8 end
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
--buffer.view_ws = 1
--buffer.whitespace_size =
--buffer.extra_ascent =
--buffer.extra_descent =

-- Line Endings
--buffer.view_eol = true

-- Caret and Selection Styles.
buffer:set_sel_fore(1, 3355443) -- 0x33 | 0x33 << 8 | 0x33 << 16
buffer:set_sel_back(1, 10066329) -- 0x99 | 0x99 << 8 | 0x99 << 16
--buffer.sel_alpha =
--buffer.sel_eol_filled = true
buffer.caret_fore = 11184810 -- 0xAA | 0xAA << 8 | 0xAA << 16
buffer.caret_line_visible = true
buffer.caret_line_back = 4473924 -- 0x44 | 0x44 << 8 | 0x44 << 16
--buffer.caret_line_back_alpha =
--buffer.caret_period = 0
--buffer.caret_style = 2
--buffer.caret_width =
--buffer.caret_sticky = 1

-- Line Number Margin.
buffer.margin_width_n[0] = 4 + 3 *
  buffer:text_width(c.STYLE_LINENUMBER, '9')

-- Marker Margin.
buffer.margin_width_n[1] = 0 -- marker margin invisible

-- Fold Margin.
buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
buffer.margin_width_n[2] = 10
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true
--buffer.margin_left =
--buffer.margin_right =
buffer:set_fold_margin_colour(1, 11184810) -- 0xAA | 0xAA << 8 | 0xAA << 16
buffer:set_fold_margin_hi_colour(1, 11184810) -- 0xAA | 0xAA << 8 | 0xAA << 16

-- Annotations.
buffer.annotation_visible = 2

-- Other.
--buffer.buffered_draw = false
--buffer.two_phase_draw = false

-- Indentation Guides.
buffer.indentation_guides = 1

-- Fold Margin Markers.
buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_ARROWDOWN)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDEROPEN, 0)
buffer:marker_set_back(c.SC_MARKNUM_FOLDEROPEN, 0)
buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_ARROW)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDER, 0)
buffer:marker_set_back(c.SC_MARKNUM_FOLDER, 0)
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
buffer.call_tip_use_style = 0

-- Folding.
buffer:set_fold_flags(16)

-- Line Wrapping.
--buffer.wrap_mode = 1
--buffer.wrap_visual_flags = 1
--buffer.wrap_visual_flags_location = 1
--buffer.wrap_indent_mode = 1
--buffer.wrap_start_indent =

-- Long Lines.
--buffer.edge_mode = 1
--buffer.edge_column = 80
--buffer.edge_colour = 11184810 -- 0xAA | 0xAA << 8 | 0xAA << 16

-- Notifications.
buffer.mod_event_mask = c.SC_MOD_CHANGEFOLD

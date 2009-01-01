-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Light editor theme for Textadept.

local c, buffer = textadept.constants, buffer

-- caret
buffer.caret_fore = 3355443 -- 0x33 | 0x33 << 8 | 0x33 << 16
buffer.caret_line_visible = true
buffer.caret_line_back = 14540253 -- 0xDD | 0xDD << 8 | 0xDD << 16
buffer:set_x_caret_policy(1, 20) -- CARET_SLOP
buffer:set_y_caret_policy(13, 1) -- CARET_SLOP | CARET_STRICT | CARET_EVEN
buffer.caret_style = 2
buffer.caret_period = 0

-- selection
buffer:set_sel_fore(1, 3355443) -- 0x33 | 0x33 << 8 | 0x33 << 16
buffer:set_sel_back(1, 10066329) -- 0x99 | 0x99 << 8 | 0x99 << 16

buffer.margin_width_n[0] = 4 + 3 * -- line number margin
  buffer:text_width(c.STYLE_LINENUMBER, '9')

buffer.margin_width_n[1] = 0 -- marker margin invisible

-- fold margin
buffer:set_fold_margin_colour(1, 13421772) -- 0xCC | 0xCC << 8 | 0xCC << 16
buffer:set_fold_margin_hi_colour(1, 13421772) -- 0xCC | 0xCC << 8 | 0xCC << 16
buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
buffer.margin_width_n[2] = 10
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true

-- fold margin markers
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

-- various
buffer.buffered_draw = true
buffer.two_phase_draw = false
buffer.call_tip_use_style = 32
buffer.use_popup = 0
buffer:set_fold_flags(16)
buffer.mod_event_mask = c.SC_MOD_CHANGEFOLD
buffer.scroll_width = 2000
buffer.h_scroll_bar = true
buffer.end_at_last_line = true
buffer.caret_sticky = false

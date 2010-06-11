-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- SciTE editor theme for Textadept.

local c = _SCINTILLA.constants
local buffer = buffer

buffer.margin_width_n[0] = 4 * buffer:text_width(c.STYLE_LINENUMBER, "9")

buffer.caret_period = 500

-- fold margin
buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
buffer.margin_width_n[2] = 16
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true

-- fold margin markers
buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_MINUS)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDEROPEN, 16777215)
buffer:marker_set_back(c.SC_MARKNUM_FOLDEROPEN, 0)
buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_PLUS)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDER, 16777215)
buffer:marker_set_back(c.SC_MARKNUM_FOLDER, 0)
buffer:marker_define(c.SC_MARKNUM_FOLDERSUB, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERTAIL, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEREND, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEROPENMID, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERMIDTAIL, c.SC_MARK_EMPTY)
buffer:set_fold_flags(16)

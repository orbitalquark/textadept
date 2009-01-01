-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Light editor theme for Textadept.

local textadept, buffer = textadept, buffer

-- folding
buffer.property['fold'] = '1'
buffer.property['fold.by.indentation'] = '1'

-- tabs and indentation
buffer.tab_width = 2
buffer.use_tabs = false
buffer.indent = 2
buffer.tab_indents = true
buffer.back_space_un_indents = true
buffer.indentation_guides = 1

-- various
buffer.eol_mode = textadept.constants.SC_EOL_LF
buffer.auto_c_choose_single = true

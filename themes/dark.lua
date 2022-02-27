-- Copyright 2007-2022 Mitchell. See LICENSE.
-- Dark theme for Textadept.
-- Contributions by Ana Balan.

local view, colors, styles = view, lexer.colors, lexer.styles

-- Greyscale colors.
colors.dark_black = 0x000000
colors.black = 0x1A1A1A
colors.light_black = 0x333333
colors.grey_black = 0x4D4D4D
colors.dark_grey = 0x666666
colors.grey = 0x808080
colors.light_grey = 0x999999
colors.grey_white = 0xB3B3B3
colors.dark_white = 0xCCCCCC
colors.white = 0xE6E6E6
colors.light_white = 0xFFFFFF

-- Dark colors.
colors.dark_red = 0x1A1A66
colors.dark_yellow = 0x1A6666
colors.dark_green = 0x1A661A
colors.dark_teal = 0x66661A
colors.dark_purple = 0x661A66
colors.dark_orange = 0x1A66B3
colors.dark_pink = 0x6666B3
colors.dark_lavender = 0xB36666
colors.dark_blue = 0xB3661A

-- Normal colors.
colors.red = 0x4D4D99
colors.yellow = 0x4D9999
colors.green = 0x4D994D
colors.teal = 0x99994D
colors.purple = 0x994D99
colors.orange = 0x4D99E6
colors.pink = 0x9999E6
colors.lavender = 0xE69999
colors.blue = 0xE6994D

-- Light colors.
colors.light_red = 0x8080CC
colors.light_yellow = 0x80CCCC
colors.light_green = 0x80CC80
colors.light_teal = 0xCCCC80
colors.light_purple = 0xCC80CC
colors.light_orange = 0x80CCFF
colors.light_pink = 0xCCCCFF
colors.light_lavender = 0xFFCCCC
colors.light_blue = 0xFFCC80

-- Default font.
if not font then
  font = WIN32 and 'Courier New' or OSX and 'Monaco' or 'Bitstream Vera Sans Mono'
end
if not size then size = not OSX and 10 or 12 end

-- Predefined styles.
styles.default = {font = font, size = size, fore = colors.light_grey, back = colors.black}
styles.line_number = {fore = colors.dark_grey, back = colors.black}
-- styles.control_char =
styles.indent_guide = {fore = colors.light_black}
styles.call_tip = {fore = colors.light_grey, back = colors.light_black}
styles.fold_display_text = {fore = colors.dark_grey}

-- Token styles.
styles.class = {fore = colors.light_yellow}
styles.comment = {fore = colors.dark_grey}
styles.constant = {fore = colors.red}
styles.embedded = {fore = colors.dark_white, back = colors.light_black}
styles.error = {fore = colors.red, italics = true}
styles['function'] = {fore = colors.blue}
styles.identifier = {}
styles.keyword = {fore = colors.dark_white}
styles.label = {fore = colors.orange}
styles.number = {fore = colors.teal}
styles.operator = {fore = colors.yellow}
styles.preprocessor = {fore = colors.purple}
styles.regex = {fore = colors.light_green}
styles.string = {fore = colors.green}
styles.type = {fore = colors.lavender}
styles.variable = {fore = colors.light_blue}
styles.whitespace = {}

-- Element colors.
-- view.element_color[view.ELEMENT_SELECTION_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_BACK] = colors.grey_black
-- view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_BACK] = colors.grey_black
-- view.element_color[view.ELEMENT_SELECTION_SECONDARY_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_SECONDARY_BACK] = colors.grey_black
-- view.element_color[view.ELEMENT_SELECTION_INACTIVE_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_INACTIVE_BACK] = colors.light_black
view.element_color[view.ELEMENT_CARET] = colors.grey
-- view.element_color[view.ELEMENT_CARET_ADDITIONAL] =
view.element_color[view.ELEMENT_CARET_LINE_BACK] = colors.light_black

-- Fold Margin.
view:set_fold_margin_color(true, colors.black)
view:set_fold_margin_hi_color(true, colors.black)

-- Markers.
-- view.marker_fore[textadept.bookmarks.MARK_BOOKMARK] = colors.black
view.marker_back[textadept.bookmarks.MARK_BOOKMARK] = colors.dark_blue
-- view.marker_fore[textadept.run.MARK_WARNING] = colors.black
view.marker_back[textadept.run.MARK_WARNING] = colors.yellow
-- view.marker_fore[textadept.run.MARK_ERROR] = colors.black
view.marker_back[textadept.run.MARK_ERROR] = colors.red
for i = buffer.MARKNUM_FOLDEREND, buffer.MARKNUM_FOLDEROPEN do -- fold margin
  view.marker_fore[i] = colors.black
  view.marker_back[i] = colors.dark_grey
  view.marker_back_selected[i] = colors.light_grey
end

-- Indicators.
view.indic_fore[ui.find.INDIC_FIND] = colors.yellow
view.indic_alpha[ui.find.INDIC_FIND] = 128
view.indic_fore[textadept.editing.INDIC_BRACEMATCH] = colors.light_grey
view.indic_outline_alpha[textadept.editing.INDIC_BRACEMATCH] = 128
view.indic_fore[textadept.editing.INDIC_HIGHLIGHT] = colors.orange
view.indic_alpha[textadept.editing.INDIC_HIGHLIGHT] = 128
view.indic_fore[textadept.snippets.INDIC_PLACEHOLDER] = colors.grey

-- Call tips.
view.call_tip_fore_hlt = colors.light_blue

-- Long Lines.
view.edge_color = colors.dark_grey

-- Find & replace pane entries.
ui.find.entry_font = font .. ' ' .. size

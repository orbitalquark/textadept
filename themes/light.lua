-- Copyright 2007-2021 Mitchell. See LICENSE.
-- Light theme for Textadept.
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
  font = WIN32 and 'Courier New' or OSX and 'Monaco' or
    'Bitstream Vera Sans Mono'
end
if not size then size = not OSX and 10 or 12 end

-- Predefined styles.
styles.default = {
  font = font, size = size, fore = colors.light_black, back = colors.white
}
styles.line_number = {fore = colors.grey, back = colors.white}
--styles.control_char = {}
styles.indent_guide = {fore = colors.dark_white}
styles.call_tip = {fore = colors.light_black, back = colors.dark_white}
styles.fold_display_text = {fore = colors.grey}

-- Token styles.
styles.class = {fore = colors.yellow}
styles.comment = {fore = colors.grey}
styles.constant = {fore = colors.red}
styles.embedded = {fore = colors.dark_blue, back = colors.dark_white}
styles.error = {fore = colors.red, italics = true}
styles['function'] = {fore = colors.dark_orange}
styles.identifier = {}
styles.keyword = {fore = colors.dark_blue}
styles.label = {fore = colors.dark_orange}
styles.number = {fore = colors.teal}
styles.operator = {fore = colors.purple}
styles.preprocessor = {fore = colors.dark_yellow}
styles.regex = {fore = colors.dark_green}
styles.string = {fore = colors.green}
styles.type = {fore = colors.lavender}
styles.variable = {fore = colors.dark_lavender}
styles.whitespace = {}

-- Multiple Selection and Virtual Space
--view.additional_sel_alpha =
--view.additional_sel_fore =
--view.additional_sel_back =
--view.additional_caret_fore =

-- Caret and Selection Styles.
view:set_sel_fore(true, colors.light_black)
view:set_sel_back(true, colors.light_grey)
--view.sel_alpha =
view.caret_fore = colors.grey_black
view.caret_line_back = colors.dark_white
--view.caret_line_back_alpha =

-- Fold Margin.
view:set_fold_margin_color(true, colors.white)
view:set_fold_margin_hi_color(true, colors.white)

-- Markers.
--view.marker_fore[textadept.bookmarks.MARK_BOOKMARK] = colors.white
view.marker_back[textadept.bookmarks.MARK_BOOKMARK] = colors.dark_blue
--view.marker_fore[textadept.run.MARK_WARNING] = colors.white
view.marker_back[textadept.run.MARK_WARNING] = colors.light_yellow
--view.marker_fore[textadept.run.MARK_ERROR] = colors.white
view.marker_back[textadept.run.MARK_ERROR] = colors.light_red
for i = buffer.MARKNUM_FOLDEREND, buffer.MARKNUM_FOLDEROPEN do -- fold margin
  view.marker_fore[i] = colors.white
  view.marker_back[i] = colors.grey
  view.marker_back_selected[i] = colors.grey_black
end

-- Indicators.
view.indic_fore[ui.find.INDIC_FIND] = colors.yellow
view.indic_alpha[ui.find.INDIC_FIND] = 128
view.indic_fore[textadept.editing.INDIC_BRACEMATCH] = colors.grey
view.indic_fore[textadept.editing.INDIC_HIGHLIGHT] = colors.orange
view.indic_alpha[textadept.editing.INDIC_HIGHLIGHT] = 128
view.indic_fore[textadept.snippets.INDIC_PLACEHOLDER] = colors.grey_black

-- Call tips.
view.call_tip_fore_hlt = colors.light_blue

-- Long Lines.
view.edge_color = colors.grey

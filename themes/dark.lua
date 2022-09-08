-- Copyright 2007-2022 Mitchell. See LICENSE.
-- Dark theme for Textadept.

local view, colors, styles = view, view.colors, view.styles

-- Greyscale colors.
colors.black = 0x000000
colors.light_black = 0x333333
colors.dark_grey = 0x666666
colors.grey = 0x999999 -- unused
colors.light_grey = 0xCCCCCC
colors.white = 0xFFFFFF -- unused

-- Normal colors.
colors.red = 0x000099
colors.orange = 0x0066CC
colors.yellow = 0x009999
colors.lime = 0x00CC99
colors.green = 0x009900
colors.teal = 0x999900
colors.blue = 0xCC6600
colors.violet = 0xCC0066
colors.purple = 0x990099
colors.magenta = 0x6600CC

-- Default font.
if not font then font = WIN32 and 'Consolas' or OSX and 'Monaco' or 'Monospace' end
if not size then size = not OSX and 10 or 12 end

-- Predefined styles.
styles.default = {font = font, size = size, fore = colors.light_grey, back = colors.black}
styles.line_number = {fore = colors.dark_grey, back = colors.black}
styles.brace_light = {fore = colors.blue, bold = true}
styles.brace_bad = {fore = colors.red}
-- styles.control_char = {}
styles.indent_guide = {fore = colors.light_black}
styles.call_tip = {fore = colors.light_grey, back = colors.light_black}
styles.fold_display_text = {fore = colors.dark_grey, back = colors.light_black}

-- Tag styles.
styles.attribute = {fore = colors.violet}
styles.bold = {bold = true}
styles.class = {fore = colors.yellow}
styles.code = {fore = colors.dark_grey, eolfilled = true}
styles.comment = {fore = colors.dark_grey}
-- styles.constant = {}
styles.constant_builtin = {fore = colors.magenta}
styles.embedded = {fore = colors.purple}
styles.error = {fore = colors.red}
-- styles['function'] = {}
styles.function_builtin = {fore = colors.orange}
-- styles.function_method = {}
styles.heading = {fore = colors.purple}
-- styles.identifier = {}
styles.italic = {italic = true}
styles.keyword = {fore = colors.blue}
styles.label = {fore = colors.purple}
styles.link = {underline = true}
styles.number = {fore = colors.teal}
-- styles.operator = {}
styles.preprocessor = {fore = colors.purple}
styles.reference = {underline = true}
styles.regex = {fore = colors.lime}
styles.string = {fore = colors.green}
styles.tag = {fore = colors.blue}
styles.type = {fore = colors.violet}
styles.underline = {underline = true}
-- styles.variable = {}
styles.variable_builtin = {fore = colors.yellow}
-- styles.whitespace = {}

-- CSS.
styles.property = styles.attribute
-- styles.pseudoclass = {}
-- styles.pseudoelement = {}
-- Diff.
styles.addition = {fore = colors.green}
styles.deletion = {fore = colors.red}
styles.change = {fore = colors.yellow}
-- HTML.
styles.tag_unknown = styles.tag .. {italics = true}
styles.attribute_unknown = styles.attribute .. {italics = true}
-- YAML.
styles.error_indent = {back = colors.red}

-- Element colors.
-- view.element_color[view.ELEMENT_SELECTION_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_BACK] = colors.light_black
-- view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_BACK] = colors.light_black
-- view.element_color[view.ELEMENT_SELECTION_SECONDARY_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_SECONDARY_BACK] = colors.light_black
-- view.element_color[view.ELEMENT_SELECTION_INACTIVE_TEXT] = colors.light_grey
view.element_color[view.ELEMENT_SELECTION_INACTIVE_BACK] = colors.light_black
view.element_color[view.ELEMENT_CARET] = colors.light_grey
-- view.element_color[view.ELEMENT_CARET_ADDITIONAL] =
view.element_color[view.ELEMENT_CARET_LINE_BACK] = colors.light_black | 0x80000000
view.caret_line_layer = view.LAYER_UNDER_TEXT

-- Fold Margin.
view:set_fold_margin_color(true, colors.black)
view:set_fold_margin_hi_color(true, colors.black)

-- Markers.
-- view.marker_fore[textadept.bookmarks.MARK_BOOKMARK] = colors.black
view.marker_back[textadept.bookmarks.MARK_BOOKMARK] = colors.blue
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
view.indic_alpha[ui.find.INDIC_FIND] = 0x80
view.indic_fore[textadept.editing.INDIC_HIGHLIGHT] = colors.orange
view.indic_alpha[textadept.editing.INDIC_HIGHLIGHT] = 0x80
view.indic_fore[textadept.snippets.INDIC_PLACEHOLDER] = colors.light_grey

-- Call tips.
view.call_tip_fore_hlt = colors.blue

-- Long Lines.
view.edge_color = colors.light_black

-- Find & replace pane entries.
ui.find.entry_font = font .. ' ' .. size

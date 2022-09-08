-- Copyright 2007-2022 Mitchell. See LICENSE.
-- Terminal theme for Textadept.

local view, colors, styles = view, view.colors, view.styles

-- Normal colors.
colors.black = 0x000000
colors.red = 0x000080
colors.green = 0x008000
colors.yellow = 0x008080
colors.blue = 0x800000
colors.magenta = 0x800080
colors.cyan = 0x808000
colors.white = 0xC0C0C0

-- Light colors. (16 color terminals only.)
-- These only apply to 16 color terminals. For other terminals, set the
-- style's `bold` attribute to use the light color variant.
colors.light_black = 0x404040
colors.light_red = 0x0000FF
colors.light_green = 0x00FF00
colors.light_yellow = 0x00FFFF
colors.light_blue = 0xFF0000
colors.light_magenta = 0xFF00FF
colors.light_cyan = 0xFFFF00
colors.light_white = 0xFFFFFF

-- Predefined styles.
styles.default = {fore = colors.white, back = colors.black}
styles.line_number = {fore = colors.black, bold = true}
styles.brace_light = {bold = true}
styles.brace_bad = {fore = colors.red, bold = true}
-- styles.control_char =
-- styles.indent_guide =
styles.call_tip = {fore = colors.white, back = colors.black}
styles.fold_display_text = {fore = colors.black, bold = true}

-- Tag styles.
styles.attribute = {fore = colors.blue}
-- styles.bold = {}
styles.class = {fore = colors.yellow, bold = true}
-- styles.code = {}
styles.comment = {fore = colors.black, bold = true}
-- styles.constant = {}
styles.constant_builtin = {fore = colors.magenta, bold = true}
-- styles.embedded = {}
styles.error = {fore = colors.red, bold = true}
-- styles['function'] = {}
styles.function_builtin = {fore = colors.yellow}
-- styles.function_method = {}
styles.heading = {fore = colors.magenta}
styles.identifier = {}
-- styles.italic = {}
styles.keyword = {fore = colors.blue, bold = true}
styles.label = {fore = colors.magenta}
-- styles.link = {}
styles.number = {fore = colors.cyan}
-- styles.operator = {}
styles.preprocessor = {fore = colors.magenta}
-- styles.reference = {}
styles.regex = {fore = colors.green, bold = true}
styles.string = {fore = colors.green}
styles.tag = {fore = colors.blue, bold = true}
styles.type = {fore = colors.blue}
-- styles.underline = {}
-- styles.variable = {}
styles.variable_builtin = {fore = colors.yellow, bold = true}
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
styles.tag_unknown = styles.tag .. {fore = colors.red, bold = true}
styles.attribute_unknown = styles.attribute .. {fore = colors.red, bold = true}
-- YAML.
styles.error_indent = {back = colors.red}

-- Element colors.
-- view.element_color[view.ELEMENT_SELECTION_TEXT] = colors.white
-- view.element_color[view.ELEMENT_SELECTION_BACK] = colors.black
-- view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_TEXT] = colors.white
-- view.element_color[view.ELEMENT_SELECTION_ADDITIONAL_BACK] = colors.black
-- view.element_color[view.ELEMENT_CARET] = colors.black
-- view.element_color[view.ELEMENT_CARET_ADDITIONAL] =
-- view.element_color[view.ELEMENT_CARET_LINE_BACK] =

-- Fold Margin.
-- view:set_fold_margin_color(true, colors.white)
-- view:set_fold_margin_hi_color(true, colors.white)

-- Markers.
view.marker_back[textadept.bookmarks.MARK_BOOKMARK] = colors.blue
view.marker_back[textadept.run.MARK_WARNING] = colors.yellow
view.marker_back[textadept.run.MARK_ERROR] = colors.red

-- Indicators.
view.indic_fore[ui.find.INDIC_FIND] = colors.yellow
view.indic_fore[textadept.editing.INDIC_HIGHLIGHT] = colors.yellow
view.indic_fore[textadept.snippets.INDIC_PLACEHOLDER] = colors.magenta

-- Call tips.
view.call_tip_fore_hlt = colors.blue

-- Long Lines.
view.edge_color = colors.red

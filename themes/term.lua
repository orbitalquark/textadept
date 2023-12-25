-- Copyright 2007-2024 Mitchell. See LICENSE.
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
styles[view.STYLE_DEFAULT] = {fore = colors.white, back = colors.black}
styles[view.STYLE_LINENUMBER] = {fore = colors.black, bold = true}
styles[view.STYLE_BRACELIGHT] = {bold = true}
styles[view.STYLE_BRACEBAD] = {fore = colors.red, bold = true}
-- styles[view.STYLE_CONTROLCHAR] ={}
-- styles[view.STYLE_INDENTGUIDE] ={}
styles[view.STYLE_CALLTIP] = {fore = colors.white, back = colors.black}
styles[view.STYLE_FOLDDISPLAYTEXT] = {fore = colors.black, bold = true}

-- Tag styles.
styles[lexer.ANNOTATION] = {fore = colors.magenta, bold = true}
styles[lexer.ATTRIBUTE] = {fore = colors.blue}
-- styles[lexer.BOLD] = {}
styles[lexer.CLASS] = {fore = colors.yellow, bold = true}
-- styles[lexer.CODE] = {}
styles[lexer.COMMENT] = {fore = colors.black, bold = true}
-- styles[lexer.CONSTANT] = {}
styles[lexer.CONSTANT_BUILTIN] = {fore = colors.magenta}
-- styles[lexer.EMBEDDED] = {}
styles[lexer.ERROR] = {fore = colors.red, bold = true}
-- styles[lexer.FUNCTION] = {}
styles[lexer.FUNCTION_BUILTIN] = {fore = colors.yellow}
-- styles[lexer.FUNCTION_METHOD] = {}
styles[lexer.HEADING] = {fore = colors.magenta, bold = true}
styles[lexer.IDENTIFIER] = {}
-- styles[lexer.ITALIC] = {}
styles[lexer.KEYWORD] = {fore = colors.blue, bold = true}
styles[lexer.LABEL] = {fore = colors.magenta, bold = true}
-- styles[lexer.LINK] = {}
styles[lexer.LIST] = {fore = colors.cyan}
styles[lexer.NUMBER] = {fore = colors.cyan}
-- styles[lexer.OPERATOR] = {}
styles[lexer.PREPROCESSOR] = {fore = colors.magenta, bold = true}
-- styles[lexer.REFERENCE] = {}
styles[lexer.REGEX] = {fore = colors.green, bold = true}
styles[lexer.STRING] = {fore = colors.green}
styles[lexer.TAG] = {fore = colors.blue, bold = true}
styles[lexer.TYPE] = {fore = colors.blue}
-- styles[lexer.UNDERLINE] = {}
-- styles[lexer.VARIABLE] = {}
styles[lexer.VARIABLE_BUILTIN] = {fore = colors.yellow, bold = true}
-- styles[lexer.WHITESPACE] = {}

-- CSS.
styles.property = styles[lexer.ATTRIBUTE]
-- styles.pseudoclass = {}
-- styles.pseudoelement = {}
-- Diff.
styles.addition = {fore = colors.green}
styles.deletion = {fore = colors.red}
styles.change = {fore = colors.yellow}
-- HTML.
styles.tag_unknown = styles.tag .. {fore = colors.red, bold = true}
styles.attribute_unknown = styles.attribute .. {fore = colors.red, bold = true}
-- Latex, TeX, and Texinfo.
styles.command = styles[lexer.KEYWORD]
styles.command_section = styles[lexer.HEADING]
styles.environment = styles[lexer.TYPE]
styles.environment_math = styles[lexer.NUMBER]
-- Makefile.
-- styles.target = {}
-- Markdown.
-- styles.hr = {}
-- Python.
styles.keyword_soft = {}
-- XML.
-- styles.cdata = {}
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

-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Light theme for Textadept.
-- Contributions by Ana Balan.

local buffer = buffer
local property, property_int = buffer.property, buffer.property_int

-- Greyscale colors.
--property['color.dark_black'] = 0x000000
--property['color.black'] = 0x1A1A1A
property['color.light_black'] = 0x333333
property['color.grey_black'] = 0x4D4D4D
--property['color.dark_grey'] = 0x666666
property['color.grey'] = 0x808080
property['color.light_grey'] = 0x999999
--property['color.grey_white'] = 0xB3B3B3
property['color.dark_white'] = 0xCCCCCC
property['color.white'] = 0xE6E6E6
--property['color.light_white'] = 0xFFFFFF

-- Dark colors.
--property['color.dark_red'] = 0x1A1A66
property['color.dark_yellow'] = 0x1A6666
property['color.dark_green'] = 0x1A661A
--property['color.dark_teal'] = 0x66661A
--property['color.dark_purple'] = 0x661A66
property['color.dark_orange'] = 0x1A66B3
--property['color.dark_pink'] = 0x6666B3
property['color.dark_lavender'] = 0xB36666
property['color.dark_blue'] = 0xB3661A

-- Normal colors.
property['color.red'] = 0x4D4D99
property['color.yellow'] = 0x4D9999
property['color.green'] = 0x4D994D
property['color.teal'] = 0x99994D
property['color.purple'] = 0x994D99
property['color.orange'] = 0x4D99E6
--property['color.pink'] = 0x9999E6
property['color.lavender'] = 0xE69999
--property['color.blue'] = 0xE6994D

-- Light colors.
property['color.light_red'] = 0x8080CC
--property['color.light_yellow'] = 0x80CCCC
--property['color.light_green'] = 0x80CC80
--property['color.light_teal'] = 0xCCCC80
--property['color.light_purple'] = 0xCC80CC
--property['color.light_orange'] = 0x80CCFF
--property['color.light_pink'] = 0xCCCCFF
--property['color.light_lavender'] = 0xFFCCCC
property['color.light_blue'] = 0xFFCC80

-- Default font.
property['font'], property['fontsize'] = 'Bitstream Vera Sans Mono', 10
if WIN32 then
  property['font'] = 'Courier New'
elseif OSX then
  property['font'], property['fontsize'] = 'Monaco', 12
end

-- Token styles.
property['style.nothing'] = ''
property['style.class'] = 'fore:%(color.yellow)'
property['style.comment'] = 'fore:%(color.grey)'
property['style.constant'] = 'fore:%(color.red)'
property['style.error'] = 'fore:%(color.red),italics'
property['style.function'] = 'fore:%(color.dark_orange)'
property['style.keyword'] = 'fore:%(color.dark_blue)'
property['style.label'] = 'fore:%(color.dark_orange)'
property['style.number'] = 'fore:%(color.teal)'
property['style.operator'] = 'fore:%(color.purple)'
property['style.regex'] = 'fore:%(color.dark_green)'
property['style.string'] = 'fore:%(color.green)'
property['style.preprocessor'] = 'fore:%(color.dark_yellow)'
property['style.type'] = 'fore:%(color.lavender)'
property['style.variable'] = 'fore:%(color.dark_lavender)'
property['style.whitespace'] = ''
property['style.embedded'] = '%(style.tag),back:%(color.dark_white)'
property['style.identifier'] = '%(style.nothing)'

-- Predefined styles.
property['style.default'] = 'font:%(font),size:%(fontsize),'..
                            'fore:%(color.light_black),back:%(color.white)'
property['style.linenumber'] = 'fore:%(color.grey),back:%(color.white)'
property['style.bracelight'] = 'fore:%(color.light_blue)'
property['style.bracebad'] = 'fore:%(color.light_red)'
property['style.controlchar'] = '%(style.nothing)'
property['style.indentguide'] = 'fore:%(color.dark_white)'
property['style.calltip'] = 'fore:%(color.light_black),back:%(color.dark_white)'

-- Multiple Selection and Virtual Space
--buffer.additional_sel_alpha =
--buffer.additional_sel_fore =
--buffer.additional_sel_back =
--buffer.additional_caret_fore =

-- Caret and Selection Styles.
buffer:set_sel_fore(true, property_int['color.light_black'])
buffer:set_sel_back(true, property_int['color.light_grey'])
--buffer.sel_alpha =
buffer.caret_fore = property_int['color.grey_black']
buffer.caret_line_back = property_int['color.dark_white']
--buffer.caret_line_back_alpha =

-- Fold Margin.
buffer:set_fold_margin_colour(true, property_int['color.white'])
buffer:set_fold_margin_hi_colour(true, property_int['color.white'])

-- Fold Margin Markers.
buffer.marker_fore[buffer.SC_MARKNUM_FOLDEROPEN] = property_int['color.grey']
buffer.marker_back[buffer.SC_MARKNUM_FOLDEROPEN] = property_int['color.grey']
buffer.marker_fore[buffer.SC_MARKNUM_FOLDER] = property_int['color.grey']
buffer.marker_back[buffer.SC_MARKNUM_FOLDER] = property_int['color.grey']

-- Long Lines.
buffer.edge_colour = property_int['color.grey']

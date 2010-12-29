-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Light lexer theme for Textadept.

-- Please note this theme is in a separate Lua state than Textadept's main one.
-- This means the global variables like 'buffer', 'view', and 'gui' are not
-- available here. Only the variables in the 'lexer' module are.

module('lexer', package.seeall)

colors = {
  green   = color('4D', '99', '4D'),
  blue    = color('4D', '4D', '99'),
  red     = color('99', '4C', '4C'),
  yellow  = color('99', '99', '4D'),
  teal    = color('4D', '99', '99'),
  white   = color('EE', 'EE', 'EE'),
  black   = color('33', '33', '33'),
  grey    = color('AA', 'AA', 'AA'),
  purple  = color('99', '4D', '99'),
  orange  = color('C0', '80', '40'),
  lgreen  = color('80', 'C0', '40'),
  lblue   = color('40', '80', 'C0'),
  lred    = color('C0', '40', '40'),
  lyellow = color('C0', 'C0', '40'),
  lteal   = color('40', 'C0', 'C0'),
  lpurple = color('C0', '40', '80'),
  lorange = color('C0', '80', '40'),
}

style_nothing    = style {                                        }
style_char       = style { fore = colors.red,    bold      = true }
style_class      = style { fore = colors.black,  underline = true }
style_comment    = style { fore = colors.lblue,  bold      = true }
style_constant   = style { fore = colors.teal,   bold      = true }
style_definition = style { fore = colors.red,    bold      = true }
style_error      = style { fore = colors.lred                     }
style_function   = style { fore = colors.blue,   bold      = true }
style_keyword    = style { fore = colors.yellow, bold      = true }
style_number     = style { fore = colors.teal                     }
style_operator   = style { fore = colors.black,  bold      = true }
style_string     = style { fore = colors.green,  bold      = true }
style_preproc    = style { fore = colors.red                      }
style_tag        = style { fore = colors.teal,   bold      = true }
style_type       = style { fore = colors.green                    }
style_variable   = style { fore = colors.red                      }
style_whitespace = style {                                        }
style_embedded   = style_tag..{ back = color('DD', 'DD', 'DD')    }
style_identifier = style_nothing

-- Default styles.
local font_face = '!Bitstream Vera Sans Mono'
local font_size = 10
if WIN32 then
  font_face = '!Courier New'
elseif OSX then
  font_face = '!Monaco'
  font_size = 12
end
style_default = style {
  font = font_face,
  size = font_size,
  fore = colors.black,
  back = colors.white
}
style_line_number = style { fore = colors.black, back = colors.grey }
style_bracelight = style { fore = color('66', '99', 'FF'), bold = true }
style_bracebad = style { fore = color('FF', '66', '99'), bold = true }
style_controlchar = style_nothing
style_indentguide = style { fore = colors.grey, back = colors.white }
style_calltip = style { fore = colors.black, back = color('DD', 'DD', 'DD') }

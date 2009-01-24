-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- SciTE lexer theme for Textadept.

module('lexer', package.seeall)

lexer.colors = {
  green = color('00', '7F', '00'),
  blue = color('00', '00', '7F'),
  red = color('7F', '00', '00'),
  yellow = color('7F', '7F', '00'),
  teal = color('00', '7F', '7F'),
  white = color('FF', 'FF', 'FF'),
  black = color('00', '00', '00'),
  grey = color('80', '80', '80'),
  purple = color('7F', '00', '7F'),
  orange = color('B0', '7F', '00'),
}

style_nothing     = style {                                  }
style_char        = style { fore = colors.purple             }
style_class       = style { fore = colors.black, bold = true }
style_comment     = style { fore = colors.green              }
style_constant    = style { fore = colors.teal, bold = true  }
style_definition  = style { fore = colors.black, bold = true }
style_error       = style { fore = colors.red                }
style_function    = style { fore = colors.black, bold = true }
style_keyword     = style { fore = colors.blue, bold = true  }
style_number      = style { fore = colors.teal               }
style_operator    = style { fore = colors.black, bold = true }
style_string      = style { fore = colors.purple             }
style_preproc     = style { fore = colors.yellow             }
style_tag         = style { fore = colors.teal               }
style_type        = style { fore = colors.blue               }
style_variable    = style { fore = colors.black              }
style_identifier  = style_nothing

-- Default styles.
local font_face = '!Monospace'
local font_size = 11
if WIN32 then
  font_face = '!Courier New'
elseif MAC then
  font_face = '!Monaco'
  font_size = 12
end
style_default = style{
  font = font_face,
  size = font_size,
  fore = colors.black,
  back = colors.white,
}
style_line_number = style { back = color('C0', 'C0', 'C0') }
style_bracelight  = style { fore = color('00', '00', 'FF'), bold = true }
style_bracebad    = style { fore = color('FF', '00', '00'), bold = true }
style_controlchar = style_nothing
style_indentguide = style { fore = color('C0', 'C0', 'C0'), back = colors.white }
style_calltip     = style { fore = colors.white, back = color('44', '44', '44') }

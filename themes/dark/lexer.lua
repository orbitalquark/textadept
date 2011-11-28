-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Dark lexer theme for Textadept.
-- Contributions by Ana Balan.

-- Please note this theme is in a separate Lua state than Textadept's main one.
-- This means the global variables like 'buffer', 'view', and 'gui' are not
-- available here. Only the variables in the 'lexer' module are.

module('lexer', package.seeall)

colors = {
  -- Greyscale colors.
--dark_black   = color('00', '00', '00'),
  black        = color('1A', '1A', '1A'),
  light_black  = color('33', '33', '33'),
  --             color('4D', '4D', '4D'),
  dark_grey    = color('66', '66', '66'),
--grey         = color('80', '80', '80'),
  light_grey   = color('99', '99', '99'),
  --             color('B3', 'B3', 'B3'),
  dark_white   = color('CC', 'CC', 'CC'),
--white        = color('E6', 'E6', 'E6'),
--light_white  = color('FF', 'FF', 'FF'),

  -- Dark colors.
--dark_red      = color('66', '1A', '1A'),
--dark_yellow   = color('66', '66', '1A'),
--dark_green    = color('1A', '66', '1A'),
--dark_teal     = color('1A', '66', '66'),
--dark_purple   = color('66', '1A', '66'),
--dark_orange   = color('B3', '66', '1A'),
--dark_pink     = color('B3', '66', '66'),
--dark_lavender = color('66', '66', 'B3'),
--dark_blue     = color('1A', '66', 'B3'),

  -- Normal colors.
  red      = color('99', '4D', '4D'),
  yellow   = color('99', '99', '4D'),
  green    = color('4D', '99', '4D'),
  teal     = color('4D', '99', '99'),
  purple   = color('99', '4D', '99'),
  orange   = color('E6', '99', '4D'),
--pink     = color('E6', '99', '99'),
  lavender = color('99', '99', 'E6'),
  blue     = color('4D', '99', 'E6'),

  -- Light colors.
  light_red      = color('CC', '80', '80'),
  light_yellow   = color('CC', 'CC', '80'),
  light_green    = color('80', 'CC', '80'),
--light_teal     = color('80', 'CC', 'CC'),
--light_purple   = color('CC', '80', 'CC'),
--light_orange   = color('FF', 'CC', '80'),
--light_pink     = color('FF', 'CC', 'CC'),
--light_lavender = color('CC', 'CC', 'FF'),
  light_blue     = color('80', 'CC', 'FF'),
}

style_nothing    = style {                                  }
style_class      = style { fore = colors.light_yellow       }
style_comment    = style { fore = colors.dark_grey          }
style_constant   = style { fore = colors.red                }
style_definition = style { fore = colors.light_yellow       }
style_error      = style { fore = colors.red, italic = true }
style_function   = style { fore = colors.blue               }
style_keyword    = style { fore = colors.dark_white         }
style_label      = style { fore = colors.orange             }
style_number     = style { fore = colors.teal               }
style_operator   = style { fore = colors.yellow             }
style_regex      = style { fore = colors.light_green        }
style_string     = style { fore = colors.green              }
style_preproc    = style { fore = colors.purple             }
style_tag        = style { fore = colors.dark_white         }
style_type       = style { fore = colors.lavender           }
style_variable   = style { fore = colors.light_blue         }
style_whitespace = style {                                  }
style_embedded   = style_tag..{ back = colors.light_black   }
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
  fore = colors.light_grey,
  back = colors.black
}
style_line_number = style { fore = colors.dark_grey, back = colors.black }
style_bracelight = style { fore = colors.light_blue }
style_bracebad = style { fore = colors.light_red }
style_controlchar = style_nothing
style_indentguide = style { fore = colors.light_black, back = colors.light_black }
style_calltip = style { fore = colors.light_grey, back = colors.light_black }

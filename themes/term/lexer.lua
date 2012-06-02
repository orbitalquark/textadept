-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Terminal lexer theme for Textadept.
-- Contributions by Ana Balan.

-- Please note this theme is in a separate Lua state than Textadept's main one.
-- This means the global variables like 'buffer', 'view', and 'gui' are not
-- available here. Only the variables in the 'lexer' module are.

local l, color, style = lexer, lexer.color, lexer.style

l.colors = {
  black = color('00', '00', '00'),
  red = color('FF', '00', '00'),
  green = color('00', 'FF', '00'),
  yellow = color('FF', 'FF', '00'),
  blue = color('00', '00', 'FF'),
  magenta = color('FF', '00', 'FF'),
  cyan = color('00', 'FF', 'FF'),
  white = color('FF', 'FF', 'FF')
}

l.style_nothing    = style {                                      }
l.style_class      = style { fore = l.colors.yellow, bold = true  }
l.style_comment    = style { fore = l.colors.black, bold = true   }
l.style_constant   = style { fore = l.colors.red                  }
l.style_definition = style { fore = l.colors.yellow, bold = true  }
l.style_error      = style { fore = l.colors.red, bold = true     }
l.style_function   = style { fore = l.colors.blue                 }
l.style_keyword    = style { fore = l.colors.white, bold = true   }
l.style_label      = style { fore = l.colors.red, bold = true     }
l.style_number     = style { fore = l.colors.cyan                 }
l.style_operator   = style { fore = l.colors.yellow               }
l.style_regex      = style { fore = l.colors.green, bold = true   }
l.style_string     = style { fore = l.colors.green                }
l.style_preproc    = style { fore = l.colors.magenta              }
l.style_tag        = style { fore = l.colors.white, bold = true   }
l.style_type       = style { fore = l.colors.magenta, bold = true }
l.style_variable   = style { fore = l.colors.blue, bold = true    }
l.style_whitespace = l.style_nothing
l.style_embedded   = l.style_tag..{ back = l.colors.black, bold = true }
l.style_identifier = l.style_nothing

-- Default styles.
l.style_default = style { fore = l.colors.white, back = l.colors.black }
l.style_line_number = l.style_default
l.style_bracelight = style { fore = l.colors.black, back = l.colors.white }
l.style_bracebad = style { fore = l.colors.red, bold = true }
l.style_controlchar = l.style_nothing
l.style_indentguide = l.style_nothing
l.style_calltip = l.style_default

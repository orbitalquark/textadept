-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Defines the key commands used by the Textadept key command manager.
-- For non-ascii keys, see textadept.keys for string aliases.
-- This set of key commands is pretty standard among other text editors.
module('textadept.key_commands_mac', package.seeall)

--[[
  C:                     J   L                 U   W X   Z
  A:     B   D E     H   J K L                 U
  CS:      C D     G H I J K L M   O   Q   S T U V W X Y Z
  SA:  A B C D   F   H   J K L M N O   Q R   T U V   X
  CA:  A   C   E   G     J K L M N O   Q R S T U V W X Y Z
  CSA: A   C D E   G H   J K L M N O P Q R S T U V W X Y Z
]]--

local keys = _G.keys

keys.clear_sequence = 'aesc'

local b, v = 'buffer', 'view'
local t = textadept

keys.at = {} -- Textadept command chain

-- File
keys.an  = { t.new_buffer   }
keys.ao  = { t.io.open      }
-- TODO: { 'reload', b }
keys.as  = { 'save', b      }
keys.sas = { 'save_as', b   }
keys.aw  = { 'close', b     }
keys.saw = { t.io.close_all }
-- TODO: { t.io.load_session } after prompting with open dialog
-- TODO: { t.io.save_session } after prompting with save dialog
keys.aq = { t.quit }

-- Edit
local m_editing = _m.textadept.editing
keys.az  = { 'undo', b                       }
keys.saz = { 'redo', b                       }
keys.ax  = { 'cut', b                        }
keys.ac  = { m_editing.smart_cutcopy, 'copy' }
keys.av  = { m_editing.smart_paste           }
-- Delete is delete.
keys.aa  = { 'select_all', b }
keys.cm  = { m_editing.match_brace              }
keys.sae = { m_editing.match_brace, 'select'    }
keys.esc = { m_editing.autocomplete_word, '%w_' }
keys.cq  = { m_editing.block_comment            }
-- TODO: { m_editing.current_word, 'delete' }
keys.ct = { m_editing.transpose_chars }
-- TODO: { m_editing.squeeze }
-- TODO: { m_editing.convert_indentation }
keys.ck = { m_editing.smart_cutcopy }
-- TODO: { m_editing.smart_cutcopy, 'copy' }
keys.cy  = { m_editing.smart_paste            }
keys.ay  = { m_editing.smart_paste, 'cycle'   }
keys.say = { m_editing.smart_paste, 'reverse' }
keys.cc = { -- enClose in...
  t     = { m_editing.enclose, 'tag'        },
  st    = { m_editing.enclose, 'single_tag' },
  ['"'] = { m_editing.enclose, 'dbl_quotes' },
  ["'"] = { m_editing.enclose, 'sng_quotes' },
  ['('] = { m_editing.enclose, 'parens'     },
  ['['] = { m_editing.enclose, 'brackets'   },
  ['{'] = { m_editing.enclose, 'braces'     },
  c     = { m_editing.enclose, 'chars'      },
}
keys.cs = { -- select in...
  e     = { m_editing.select_enclosed               },
  t     = { m_editing.select_enclosed, 'tags'       },
  ['"'] = { m_editing.select_enclosed, 'dbl_quotes' },
  ["'"] = { m_editing.select_enclosed, 'sng_quotes' },
  ['('] = { m_editing.select_enclosed, 'parens'     },
  ['['] = { m_editing.select_enclosed, 'brackets'   },
  ['{'] = { m_editing.select_enclosed, 'braces'     },
  w     = { m_editing.current_word, 'select'        },
  l     = { m_editing.select_line                   },
  p     = { m_editing.select_paragraph              },
  b     = { m_editing.select_indented_block         },
  s     = { m_editing.select_scope                  },
  g     = { m_editing.grow_selection, 1             },
}

-- Search
keys.af  = { t.find.focus          } -- find/replace
keys.ag  = { t.find.call_find_next }
keys.sag = { t.find.call_find_prev }
keys.ar  = { t.find.call_replace   }
keys.cg  = { m_editing.goto_line   }

-- Tools
keys['f2'] = { t.command_entry.focus }
-- Run
local m_run = _m.textadept.run
keys.cr  = { m_run.go      }
keys.csr = { m_run.compile }
-- Snippets
local m_snippets = _m.textadept.lsnippets
keys.ai   = { m_snippets.insert         }
keys.sai  = { m_snippets.prev           }
keys.cai  = { m_snippets.cancel_current }
keys.casi = { m_snippets.list           }
keys.ci   = { m_snippets.show_style     }
-- Multiple Line Editing
local m_mlines = _m.textadept.mlines
keys.am    = {}
keys.am.a  = { m_mlines.add             }
keys.am.sa = { m_mlines.add_multiple    }
keys.am.r  = { m_mlines.remove          }
keys.am.sr = { m_mlines.remove_multiple }
keys.am.u  = { m_mlines.update          }
keys.am.c  = { m_mlines.clear           }

-- Buffers
keys['c\t']  = { 'goto_buffer', v, 1, false  }
keys['ca\t'] = { 'goto_buffer', v, -1, false }
local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  t.events.update_ui() -- for updating statusbar
end
keys.at.v = {
  e      = { toggle_setting, 'view_eol'           },
  w      = { toggle_setting, 'wrap_mode'          },
  i      = { toggle_setting, 'indentation_guides' },
  ['\t'] = { toggle_setting, 'use_tabs'           },
  [' ']  = { toggle_setting, 'view_ws'            },
}
keys['f5'] = { 'colourise', b, 0, -1 }

-- Views
keys.cv = {
  n  = { t.goto_view, 1, false                      },
  p  = { t.goto_view, -1, false                     },
  ss = { 'split', v                                 }, -- vertical
  s  = { 'split', v, false                          }, -- horizontal
  w  = { function() view:unsplit() return true end  },
  sw = { function() while view:unsplit() do end end },
  -- TODO: { function() view.size = view.size + 10 end  }
  -- TODO: { function() view.size = view.size - 10 end  }
}

-- Project Manager
local function pm_activate(text)
  t.pm.entry_text = text
  t.pm.activate()
end
keys.sap = { function() if t.pm.width > 0 then t.pm.toggle_visible() end end }
keys.ap  = {
  function()
    if t.pm.width == 0 then t.pm.toggle_visible() end
    t.pm.focus()
  end
}
keys.cap = {
  c = { pm_activate, 'ctags'   },
  b = { pm_activate, 'buffers' },
  f = { pm_activate, '/'       },
-- TODO: { pm_activate, 'macros' }
  m = { pm_activate, 'modules' },
}

-- Miscellaneous not in standard menu.
-- Recent files.
local RECENT_FILES = 1
t.events.add_handler('user_list_selection',
  function(type, text)
    if type == RECENT_FILES then t.io.open(text) end
  end)
keys.co = {
  function()
    local buffer = buffer
    local files = {}
    for _, filename in ipairs(t.io.recent_files) do
      table.insert(files, 1, filename)
    end
    local sep = buffer.auto_c_separator
    buffer.auto_c_separator = ('|'):byte()
    buffer:user_list_show(RECENT_FILES, table.concat(files, '|'))
    buffer.auto_c_separator = sep
  end
}

-- Movement/selection commands
keys.cf   = { 'char_right',             b }
keys.csf  = { 'char_right_extend',      b }
keys.caf  = { 'word_right',             b }
keys.csaf = { 'word_right_extend',      b }
keys.cb   = { 'char_left',              b }
keys.csb  = { 'char_left_extend',       b }
keys.cab  = { 'word_left',              b }
keys.csab = { 'word_left_extend',       b }
keys.cn   = { 'line_down',              b }
keys.csn  = { 'line_down_extend',       b }
keys.cp   = { 'line_up',                b }
keys.csp  = { 'line_up_extend',         b }
keys.ca   = { 'vc_home',                b }
keys.csa  = { 'home_extend',            b }
keys.ce   = { 'line_end',               b }
keys.cse  = { 'line_end_extend',        b }
keys.ch   = { 'delete_back',            b }
keys.cah  = { 'del_word_left',          b }
keys.cd   = { 'clear',                  b }
keys.cad  = { 'del_word_right',         b }

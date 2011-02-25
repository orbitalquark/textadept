-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors.
module('_m.textadept.keys', package.seeall)

local keys = _G.keys
local b, v = 'buffer', 'view'
local gui = gui

-- Utility functions used by both layouts.
local function enclose_in_tag()
  m_editing.enclose('<', '>')
  local buffer = buffer
  local pos = buffer.current_pos
  while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
  buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
end
local function any_char_mt(f)
  return setmetatable({['\0'] = {}}, {
                        __index = function(t, k)
                          if #k == 1 then return { f, k, k } end
                        end })
end
local function toggle_setting(setting, i)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and (i or 1) or 0
  end
  events.emit('update_ui') -- for updating statusbar
end
local RECENT_FILES = 1
events.connect('user_list_selection',
  function(type, text) if type == RECENT_FILES then io.open_file(text) end end)
local function show_recent_file_list()
  local buffer = buffer
  local files = {}
  for _, filename in ipairs(io.recent_files) do
    table.insert(files, 1, filename)
  end
  local sep = buffer.auto_c_separator
  buffer.auto_c_separator = ('|'):byte()
  buffer:user_list_show(RECENT_FILES, table.concat(files, '|'))
  buffer.auto_c_separator = sep
end

-- CTRL = 'c'
-- SHIFT = 's'
-- ALT = 'a'
-- ADD = ''
-- Control, Shift, Alt, and 'a' = 'caA'
-- Control, Shift, Alt, and '\t' = 'csa\t'

if not OSX then
  -- Windows and Linux key commands.

  --[[
    C:         D           J K   M               U
    A:   A B C D E F G H   J K L M N   P     S T U V W X Y Z
    CS:  A B C D     G   I J K L M N O   Q     T U V   X Y Z
    SA:  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    CA:  A B C D E F G H   J K L M N O   Q R S T U V W X Y Z
    CSA: A B C D E F G H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'esc'

  keys.ct = {} -- Textadept command chain

  -- File
  local m_session = _m.textadept.session
  keys.cn  = { new_buffer   }
  keys.co  = { io.open_file }
  -- TODO: { 'reload', b }
  keys.cs  = { 'save', b    }
  keys.cS  = { 'save_as', b }
  keys.cw  = { 'close', b   }
  keys.cW  = { io.close_all }
  -- TODO: { m_session.load } after prompting with open dialog
  -- TODO: { m_session.save } after prompting with save dialog
  keys.aq = { quit }

  -- Edit
  local m_editing = _m.textadept.editing
  keys.cz = { 'undo', b       }
  keys.cy = { 'redo', b       }
  keys.cx = { 'cut', b        }
  keys.cc = { 'copy', b       }
  keys.cv = { 'paste', b      }
  -- Delete is delete.
  keys.ca = { 'select_all', b }
  keys.ce       = { m_editing.match_brace              }
  keys.cE       = { m_editing.match_brace, 'select'    }
  keys['c\n']   = { m_editing.autocomplete_word, '%w_' }
  keys['c\n\r'] = { m_editing.autocomplete_word, '%w_' } -- win32
  keys.cq       = { m_editing.block_comment            }
  -- TODO: { m_editing.current_word, 'delete' }
  keys.csh = { m_editing.highlight_word }
  -- TODO: { m_editing.transpose_chars }
  -- TODO: { m_editing.convert_indentation }
  keys.ac = { -- enClose in...
    t     = { enclose_in_tag },
    T     = { m_editing.enclose, '<', ' />' },
    ['"'] = { m_editing.enclose, '"', '"'   },
    ["'"] = { m_editing.enclose, "'", "'"   },
    ['('] = { m_editing.enclose, '(', ')'   },
    ['['] = { m_editing.enclose, '[', ']'   },
    ['{'] = { m_editing.enclose, '{', '}'   },
    c     = any_char_mt(m_editing.enclose),
  }
  keys.as = { -- select in...
    t     = { m_editing.select_enclosed, '>', '<' },
    ['"'] = { m_editing.select_enclosed, '"', '"' },
    ["'"] = { m_editing.select_enclosed, "'", "'" },
    ['('] = { m_editing.select_enclosed, '(', ')' },
    ['['] = { m_editing.select_enclosed, '[', ']' },
    ['{'] = { m_editing.select_enclosed, '{', '}' },
    w     = { m_editing.current_word, 'select'    },
    l     = { m_editing.select_line               },
    p     = { m_editing.select_paragraph          },
    b     = { m_editing.select_indented_block     },
    s     = { m_editing.select_scope              },
    g     = { m_editing.grow_selection, 1         },
    c     = any_char_mt(m_editing.select_enclosed),
  }

  -- Search
  keys.cf = { gui.find.focus } -- find/replace
  keys['f3'] = { gui.find.find_next }
  -- Find Next is an when find pane is focused.
  -- Find Prev is ap when find pane is focused.
  -- Replace is ar when find pane is focused.
  keys.cF = { gui.find.find_incremental }
  -- Find in Files is ai when find pane is focused.
  -- TODO: { gui.find.goto_file_in_list, true  }
  -- TODO: { gui.find.goto_file_in_list, false }
  keys.cg = { m_editing.goto_line }

  -- Tools
  keys['f2'] = { gui.command_entry.focus }
  -- Run
  local m_run = _m.textadept.run
  keys.cr = { m_run.run     }
  keys.cR = { m_run.compile }
  keys.ar = { _m.textadept.filter_through.filter_through }
  -- Snippets
  local m_snippets = _m.textadept.snippets
  keys['\t']  = { m_snippets._insert         }
  keys['s\t'] = { m_snippets._prev           }
  keys.cai    = { m_snippets._cancel_current }
  keys.caI    = { m_snippets._list           }
  keys.ai     = { m_snippets._show_style     }

  -- Buffers
  keys.cb      = { gui.switch_buffer           }
  keys['c\t']  = { 'goto_buffer', v, 1, false  }
  keys['cs\t'] = { 'goto_buffer', v, -1, false }
  keys.ct.v = {
    e      = { toggle_setting, 'view_eol'                 },
    w      = { toggle_setting, 'wrap_mode'                },
    i      = { toggle_setting, 'indentation_guides'       },
    ['\t'] = { toggle_setting, 'use_tabs'                 },
    [' ']  = { toggle_setting, 'view_ws'                  },
    v      = { toggle_setting, 'virtual_space_options', 2 },
  }
  keys.cl    = { _m.textadept.mime_types.select_lexer }
  keys['f5'] = { 'colourise', b, 0, -1     }

  -- Views
  keys.cav = {
    n = { gui.goto_view, 1, false                    },
    p = { gui.goto_view, -1, false                   },
    S = { 'split', v                                 }, -- vertical
    s = { 'split', v, false                          }, -- horizontal
    w = { function() view:unsplit() return true end  },
    W = { function() while view:unsplit() do end end },
    -- TODO: { function() view.size = view.size + 10 end  }
    -- TODO: { function() view.size = view.size - 10 end  }
  }
  keys.c0 = { function() buffer.zoom = 0 end }

  -- Miscellaneous not in standard menu.
  keys.ao = { show_recent_file_list }

else
  -- Mac OSX key commands

  --[[
    C:                     J     M               U   W X   Z
    A:         D E     H   J K L                 U       Y
    CS:      C D     G H I J K L M   O   Q   S T U V W X Y Z
    SA:  A B C D       H I J K L M N O   Q R   T U V   X Y
    CA:  A   C   E         J K L M N O   Q   S   U V W X Y Z
    CSA: A   C D E     H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'aesc'

  keys.at = {} -- Textadept command chain

  -- File
  local m_session = _m.textadept.session
  keys.an = { new_buffer   }
  keys.ao = { io.open_file }
  -- TODO: { 'reload', b }
  keys.as = { 'save', b    }
  keys.aS = { 'save_as', b }
  keys.aw = { 'close', b   }
  keys.aW = { io.close_all }
  -- TODO: { m_session.load } after prompting with open dialog
  -- TODO: { m_session.save } after prompting with save dialog
  keys.aq = { quit }

  -- Edit
  local m_editing = _m.textadept.editing
  keys.az  = { 'undo', b  }
  keys.aZ  = { 'redo', b  }
  keys.ax  = { 'cut', b   }
  keys.ac  = { 'copy', b  }
  keys.av  = { 'paste', b }
  -- Delete is delete.
  keys.aa  = { 'select_all', b }
  keys.cm  = { m_editing.match_brace              }
  keys.aE  = { m_editing.match_brace, 'select'    }
  keys.esc = { m_editing.autocomplete_word, '%w_' }
  keys.cq  = { m_editing.block_comment            }
  -- TODO: { m_editing.current_word, 'delete' }
  keys.cat = { m_editing.highlight_word }
  keys.ct = { m_editing.transpose_chars }
  -- TODO: { m_editing.convert_indentation }
  keys.cc = { -- enClose in...
    t     = { enclose_in_tag },
    T     = { m_editing.enclose, '<', ' />' },
    ['"'] = { m_editing.enclose, '"', '"'   },
    ["'"] = { m_editing.enclose, "'", "'"   },
    ['('] = { m_editing.enclose, '(', ')'   },
    ['['] = { m_editing.enclose, '[', ']'   },
    ['{'] = { m_editing.enclose, '{', '}'   },
    c     = any_char_mt(m_editing.enclose),
  }
  keys.cs = { -- select in...
    t     = { m_editing.select_enclosed, '>', '<' },
    ['"'] = { m_editing.select_enclosed, '"', '"' },
    ["'"] = { m_editing.select_enclosed, "'", "'" },
    ['('] = { m_editing.select_enclosed, '(', ')' },
    ['['] = { m_editing.select_enclosed, '[', ']' },
    ['{'] = { m_editing.select_enclosed, '{', '}' },
    w     = { m_editing.current_word, 'select'    },
    l     = { m_editing.select_line               },
    p     = { m_editing.select_paragraph          },
    b     = { m_editing.select_indented_block     },
    s     = { m_editing.select_scope              },
    g     = { m_editing.grow_selection, 1         },
    c     = any_char_mt(m_editing.select_enclosed),
  }

  -- Search
  keys.af = { gui.find.focus     } -- find/replace
  keys.ag = { gui.find.find_next }
  keys.aG = { gui.find.find_prev }
  keys.ar = { gui.find.replace   }
  keys.ai = { gui.find.find_incremental }
  keys.aF = {
    function()
      gui.find.in_files = true
      gui.find.focus()
    end
  }
  keys.cag = { gui.find.goto_file_in_list, true  }
  keys.caG = { gui.find.goto_file_in_list, false }
  keys.cg  = { m_editing.goto_line               }

  -- Tools
  keys['f2'] = { gui.command_entry.focus }
  -- Run
  local m_run = _m.textadept.run
  keys.cr = { m_run.run     }
  keys.cR = { m_run.compile }
  keys.car = { _m.textadept.filter_through.filter_through }
  -- Snippets
  local m_snippets = _m.textadept.snippets
  keys['\t']  = { m_snippets._insert         }
  keys['s\t'] = { m_snippets._prev           }
  keys.cai    = { m_snippets._cancel_current }
  keys.caI    = { m_snippets._list           }
  keys.ci     = { m_snippets._show_style     }

  -- Buffers
  keys.ab      = { gui.switch_buffer           }
  keys['c\t']  = { 'goto_buffer', v, 1, false  }
  keys['cs\t'] = { 'goto_buffer', v, -1, false }
  keys.at.v = {
    e      = { toggle_setting, 'view_eol'                 },
    w      = { toggle_setting, 'wrap_mode'                },
    i      = { toggle_setting, 'indentation_guides'       },
    ['\t'] = { toggle_setting, 'use_tabs'                 },
    [' ']  = { toggle_setting, 'view_ws'                  },
    v      = { toggle_setting, 'virtual_space_options', 2 },
  }
  keys.cl    = { _m.textadept.mime_types.select_lexer }
  keys['f5'] = { 'colourise', b, 0, -1     }

  -- Views
  keys.cv = {
    n = { gui.goto_view, 1, false                    },
    p = { gui.goto_view, -1, false                   },
    S = { 'split', v                                 }, -- vertical
    s = { 'split', v, false                          }, -- horizontal
    w = { function() view:unsplit() return true end  },
    W = { function() while view:unsplit() do end end },
    -- TODO: { function() view.size = view.size + 10 end  }
    -- TODO: { function() view.size = view.size - 10 end  }
  }
  keys.c0 = { function() buffer.zoom = 0 end }

  -- Miscellaneous not in standard menu.
  keys.co = { show_recent_file_list }

  -- Movement/selection commands
  keys.cf  = { 'char_right',        b }
  keys.cF  = { 'char_right_extend', b }
  keys.caf = { 'word_right',        b }
  keys.caF = { 'word_right_extend', b }
  keys.cb  = { 'char_left',         b }
  keys.cB  = { 'char_left_extend',  b }
  keys.cab = { 'word_left',         b }
  keys.caB = { 'word_left_extend',  b }
  keys.cn  = { 'line_down',         b }
  keys.cN  = { 'line_down_extend',  b }
  keys.cp  = { 'line_up',           b }
  keys.cP  = { 'line_up_extend',    b }
  keys.ca  = { 'vc_home',           b }
  keys.cA  = { 'home_extend',       b }
  keys.ce  = { 'line_end',          b }
  keys.cE  = { 'line_end_extend',   b }
  --keys.ch  = { 'delete_back',       b }
  keys.cah = { 'del_word_left',     b }
  keys.cd  = { 'clear',             b }
  keys.cad = { 'del_word_right',    b }
  keys.ck  = {
    function()
      buffer:line_end_extend()
      buffer:cut()
    end
  }
  keys.cy = { 'paste', b }
end

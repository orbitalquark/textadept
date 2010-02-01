-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Defines the key commands used by the Textadept key command manager.
-- This set of key commands is pretty standard among other text editors.
module('textadept.key_commands', package.seeall)

-- Markdown:
-- ## Overview
--
-- Key commands are defined in the global table `keys`. Each key-value pair in
-- `keys` consists of either:
--
-- * A string representing a key command and an associated action table.
-- * A string language name and its associated `keys`-like table.
-- * A string style name and its associated `keys`-like table.
-- * A string representing a key command and its associated `keys`-like table.
--   (This is a keychain sequence.)
--
-- A key command string is built from a combination of the `CTRL`, `SHIFT`,
-- `ALT`, and `ADD` constants as well as the pressed key itself. The value of
-- `ADD` is inserted between each of `CTRL`, `SHIFT`, `ALT`, and the key.
-- For example:
--
--     -- keys.lua:
--     CTRL = 'Ctrl'
--     SHIFT = 'Shift'
--     ALT = 'Alt'
--     ADD = '+'
--     -- pressing control, shift, alt and 'a' yields: 'Ctrl+Shift+Alt+a'
--
-- For key values less than 255, Lua's [`string.char()`][string_char] is used to
-- determine the key's string representation. Otherwise, the `KEYSYMS` lookup
-- table in [`textadept.keys`][textadept_keys] is used.
--
-- [string_char]: http://www.lua.org/manual/5.1/manual.html#pdf-string.char
-- [textadept_keys]: ../modules/textadept.keys.html
--
-- An action table is a table consisting of either:
--
-- * A Lua function followed by a list of arguments to pass to that function.
-- * A string representing a [buffer][buffer] or [view][view] function followed
--   by its respective `'buffer'` or `'view'` string and then any arguments to
--   pass to the resulting function.
--
--       `buffer.`_`function`_ by itself cannot be used because at the time of
--       evaluation, `buffer.`_`function`_ would apply only to the current
--       buffer, not for all buffers. By using this string reference system, the
--       correct `buffer.`_`function`_ will be evaluated every time. The same
--       applies to `view`.
--
-- [buffer]: ../modules/buffer.html
-- [view]: ../modules/view.html
--
-- Language names are the names of the lexer files in `lexers/` such as `cpp`
-- and `lua`. Style names are different lexer styles, most of which are in
-- `lexers/lexer.lua`; examples are `whitespace`, `comment`, and `string`.
--
-- Key commands can be chained like in Emacs using keychain sequences. By
-- default, the `Esc` key cancels the current keychain, but it can be redefined
-- by setting the `keys.clear_sequence` field. Naturally, the clear sequence
-- cannot be chained.
--
-- ## Key Command Precedence
--
-- When searching for a key command to execute in the `keys` table, key commands
-- in the current style have priority, followed by the  ones in the current lexer,
-- and finally the ones in the global table.
--
-- ## Example
--
--     keys = {
--       ['ctrl+f'] = { 'char_right', 'buffer' },
--       ['ctrl+b'] = { 'char_left',  'buffer' },
--       lua = {
--         ['ctrl+c'] = { 'add_text', 'buffer', '-- ' },
--         whitespace = {
--           ['ctrl+f'] = { function() print('whitespace') end }
--         }
--       }
--     }
--
-- The first two key commands are global and call `buffer:char_right()` and
-- `buffer:char_left()` respectively. The last two commands apply only in the
-- Lua lexer with the very last one only being available in Lua's `whitespace`
-- style. If `ctrl+f` is pressed when the current style is `whitespace` in the
-- `lua` lexer, the global key command with the same shortcut is overriden and
-- `whitespace` is printed to standard out.
--
-- ## Problems
--
-- All Lua functions must be defined BEFORE they are reference in key commands.
-- Therefore, any module containing key commands should be loaded after all
-- other modules, whose functions are being referenced, have been loaded.

-- Windows and Linux key commands are listed in the first block.
-- Mac OSX key commands are listed in the second block.

local keys = _G.keys
local b, v = 'buffer', 'view'
local t = textadept

-- CTRL = 'c'
-- SHIFT = 's'
-- ALT = 'a'
-- ADD = ''
-- Control, Shift, Alt, and 'a' = 'caA'
-- Control, Shift, Alt, and '\t' = 'csa\t'

if not MAC then
  -- Windows and Linux key commands.

  --[[
    C:     B   D       H I J K L                 U
    A:   A B C D E F G H   J K L M N   P   R S T U V W X Y Z
    CS:  A B C D     G H I J K L M N O   Q     T U V   X Y Z
    SA:  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    CA:  A B C D E F G H   J K L M N O   Q R S T U V W X Y Z
    CSA: A B C D E F G H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'esc'

  keys.ct = {} -- Textadept command chain

  -- File
  local m_session = _m.textadept.session
  keys.cn  = { t.new_buffer   }
  keys.co  = { t.io.open      }
  -- TODO: { 'reload', b }
  keys.cs  = { 'save', b      }
  keys.cS  = { 'save_as', b   }
  keys.cw  = { 'close', b     }
  keys.cW  = { t.io.close_all }
  -- TODO: { m_session.load } after prompting with open dialog
  -- TODO: { m_session.save } after prompting with save dialog
  keys.aq = { t.quit }

  -- Edit
  local m_editing = _m.textadept.editing
  keys.cz = { 'undo', b       }
  keys.cy = { 'redo', b       }
  keys.cx = { 'cut', b        }
  keys.cc = { 'copy', b       }
  keys.cv = { 'paste', b      }
  -- Delete is delete.
  keys.ca = { 'select_all', b }
  keys.ce     = { m_editing.match_brace              }
  keys.cE     = { m_editing.match_brace, 'select'    }
  keys['c\n'] = { m_editing.autocomplete_word, '%w_' }
  keys['c\n\r'] = { m_editing.autocomplete_word, '%w_' } -- win32
  keys.cq     = { m_editing.block_comment            }
  -- TODO: { m_editing.current_word, 'delete' }
  -- TODO: { m_editing.transpose_chars }
  -- TODO: { m_editing.squeeze }
  -- TODO: { m_editing.convert_indentation }
  -- TODO: { m_editing.smart_cutcopy }
  -- TODO: { m_editing.smart_cutcopy, 'copy' }
  -- TODO: { m_editing.smart_paste }
  -- TODO: { m_editing.smart_paste, 'cycle' }
  -- TODO: { m_editing.smart_paste, 'reverse' }
  keys.ac = { -- enClose in...
    t     = { m_editing.enclose, 'tag'        },
    T     = { m_editing.enclose, 'single_tag' },
    ['"'] = { m_editing.enclose, 'dbl_quotes' },
    ["'"] = { m_editing.enclose, 'sng_quotes' },
    ['('] = { m_editing.enclose, 'parens'     },
    ['['] = { m_editing.enclose, 'brackets'   },
    ['{'] = { m_editing.enclose, 'braces'     },
    c     = { m_editing.enclose, 'chars'      },
  }
  keys.as = { -- select in...
    t     = { m_editing.select_enclosed, 'tags'       },
    ['"'] = { m_editing.select_enclosed, 'dbl_quotes' },
    ["'"] = { m_editing.select_enclosed, 'sng_quotes' },
    ['('] = { m_editing.select_enclosed, 'parens'     },
    ['['] = { m_editing.select_enclosed, 'brackets'   },
    ['{'] = { m_editing.select_enclosed, 'braces'     },
    w     = { m_editing.current_word, 'select'        },
    l      = { m_editing.select_line                   },
    p      = { m_editing.select_paragraph              },
    b      = { m_editing.select_indented_block         },
    s      = { m_editing.select_scope                  },
    g      = { m_editing.grow_selection, 1             },
  }

  -- Search
  keys.cf = { t.find.focus } -- find/replace
  keys['f3'] = { t.find.find_next }
  -- Find Next is an when find pane is focused.
  -- Find Prev is ap when find pane is focused.
  -- Replace is ar when find pane is focused.
  keys.cF = { t.find.find_incremental }
  -- Find in Files is ai when find pane is focused.
  -- TODO: { t.find.goto_file_in_list, true  }
  -- TODO: { t.find.goto_file_in_list, false }
  keys.cg = { m_editing.goto_line }

  -- Tools
  keys['f2'] = { t.command_entry.focus }
  -- Run
  local m_run = _m.textadept.run
  keys.cr = { m_run.go      }
  keys.cR = { m_run.compile }
  -- Snippets
  local m_snippets = _m.textadept.lsnippets
  keys['\t']  = { m_snippets.insert         }
  keys['s\t'] = { m_snippets.prev           }
  keys.cai    = { m_snippets.cancel_current }
  keys.caI    = { m_snippets.list           }
  keys.ai     = { m_snippets.show_style     }
  -- Multiple Line Editing
  local m_mlines = _m.textadept.mlines
  keys.cm   = {}
  keys.cm.a = { m_mlines.add             }
  keys.cm.A = { m_mlines.add_multiple    }
  keys.cm.r = { m_mlines.remove          }
  keys.cm.R = { m_mlines.remove_multiple }
  keys.cm.u = { m_mlines.update          }
  keys.cm.c = { m_mlines.clear           }

  -- Buffers
  keys['c\t']  = { 'goto_buffer', v, 1, false  }
  keys['cs\t'] = { 'goto_buffer', v, -1, false }
  local function toggle_setting(setting)
    local state = buffer[setting]
    if type(state) == 'boolean' then
      buffer[setting] = not state
    elseif type(state) == 'number' then
      buffer[setting] = buffer[setting] == 0 and 1 or 0
    end
    t.events.handle('update_ui') -- for updating statusbar
  end
  keys.ct.v = {
    e      = { toggle_setting, 'view_eol'           },
    w      = { toggle_setting, 'wrap_mode'          },
    i      = { toggle_setting, 'indentation_guides' },
    ['\t'] = { toggle_setting, 'use_tabs'           },
    [' ']  = { toggle_setting, 'view_ws'            },
  }
  keys['f5'] = { 'colourise', b, 0, -1 }

  -- Views
  keys.cav = {
    n = { t.goto_view, 1, false                      },
    p = { t.goto_view, -1, false                     },
    S = { 'split', v                                 }, -- vertical
    s = { 'split', v, false                          }, -- horizontal
    w = { function() view:unsplit() return true end  },
    W = { function() while view:unsplit() do end end },
    -- TODO: { function() view.size = view.size + 10 end  }
    -- TODO: { function() view.size = view.size - 10 end  }
  }

  -- Project Manager
  local function pm_activate(text)
    t.pm.entry_text = text
    t.pm.activate()
  end
  keys.cP = { function() if t.pm.width > 0 then t.pm.toggle_visible() end end }
  keys.cp = {
    function()
      if t.pm.width == 0 then t.pm.toggle_visible() end
      t.pm.focus()
    end
  }
  keys.cap = {
    c = { pm_activate, 'ctags'   },
    b = { pm_activate, 'buffers' },
    f = { pm_activate, '/'       },
    m = { pm_activate, 'modules' },
  }

  -- Miscellaneous not in standard menu.
  -- Recent files.
  local RECENT_FILES = 1
  t.events.add_handler('user_list_selection',
    function(type, text)
      if type == RECENT_FILES then t.io.open(text) end
    end)
  keys.ao = {
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

else
  -- Mac OSX key commands

  --[[
    C:                     J   L                 U   W X   Z
    A:     B   D E     H   J K L                 U
    CS:      C D     G H I J K L M   O   Q   S T U V W X Y Z
    SA:  A B C D       H I J K L M N O   Q R   T U V   X
    CA:  A   C   E         J K L M N O   Q R S T U V W X Y Z
    CSA: A   C D E     H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'aesc'

  keys.at = {} -- Textadept command chain

  -- File
  local m_session = _m.textadept.session
  keys.an = { t.new_buffer   }
  keys.ao = { t.io.open      }
  -- TODO: { 'reload', b }
  keys.as = { 'save', b      }
  keys.aS = { 'save_as', b   }
  keys.aw = { 'close', b     }
  keys.aW = { t.io.close_all }
  -- TODO: { m_session.load } after prompting with open dialog
  -- TODO: { m_session.save } after prompting with save dialog
  keys.aq = { t.quit }

  -- Edit
  local m_editing = _m.textadept.editing
  keys.az  = { 'undo', b                       }
  keys.aZ  = { 'redo', b                       }
  keys.ax  = { 'cut', b                        }
  keys.ac  = { m_editing.smart_cutcopy, 'copy' }
  keys.av  = { m_editing.smart_paste           }
  -- Delete is delete.
  keys.aa  = { 'select_all', b }
  keys.cm  = { m_editing.match_brace              }
  keys.aE  = { m_editing.match_brace, 'select'    }
  keys.esc = { m_editing.autocomplete_word, '%w_' }
  keys.cq  = { m_editing.block_comment            }
  -- TODO: { m_editing.current_word, 'delete' }
  keys.ct = { m_editing.transpose_chars }
  -- TODO: { m_editing.squeeze }
  -- TODO: { m_editing.convert_indentation }
  keys.ck = { m_editing.smart_cutcopy }
  -- TODO: { m_editing.smart_cutcopy, 'copy' }
  keys.cy = { m_editing.smart_paste            }
  keys.ay = { m_editing.smart_paste, 'cycle'   }
  keys.aY = { m_editing.smart_paste, 'reverse' }
  keys.cc = { -- enClose in...
    t     = { m_editing.enclose, 'tag'        },
    T     = { m_editing.enclose, 'single_tag' },
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
  keys.af = { t.find.focus            } -- find/replace
  keys.ag = { t.find.find_next   }
  keys.aG = { t.find.find_prev   }
  keys.ar = { t.find.replace     }
  keys.ai = { t.find.find_incremental }
  keys.aF = {
    function()
      t.find.in_files = true
      t.find.focus()
    end
  }
  keys.cag = { t.find.goto_file_in_list, true  }
  keys.caG = { t.find.goto_file_in_list, false }
  keys.cg  = { m_editing.goto_line             }

  -- Tools
  keys['f2'] = { t.command_entry.focus }
  -- Run
  local m_run = _m.textadept.run
  keys.cr = { m_run.run     }
  keys.cR = { m_run.compile }
  -- Snippets
  local m_snippets = _m.textadept.lsnippets
  keys['\t']  = { m_snippets.insert         }
  keys['s\t'] = { m_snippets.prev           }
  keys.cai    = { m_snippets.cancel_current }
  keys.caI    = { m_snippets.list           }
  keys.ci     = { m_snippets.show_style     }
  -- Multiple Line Editing
  local m_mlines = _m.textadept.mlines
  keys.am   = {}
  keys.am.a = { m_mlines.add             }
  keys.am.A = { m_mlines.add_multiple    }
  keys.am.r = { m_mlines.remove          }
  keys.am.R = { m_mlines.remove_multiple }
  keys.am.u = { m_mlines.update          }
  keys.am.c = { m_mlines.clear           }

  -- Buffers
  keys['c\t']  = { 'goto_buffer', v, 1, false  }
  keys['cs\t'] = { 'goto_buffer', v, -1, false }
  local function toggle_setting(setting)
    local state = buffer[setting]
    if type(state) == 'boolean' then
      buffer[setting] = not state
    elseif type(state) == 'number' then
      buffer[setting] = buffer[setting] == 0 and 1 or 0
    end
    t.events.handle('update_ui') -- for updating statusbar
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
    n = { t.goto_view, 1, false                      },
    p = { t.goto_view, -1, false                     },
    S = { 'split', v                                 }, -- vertical
    s = { 'split', v, false                          }, -- horizontal
    w = { function() view:unsplit() return true end  },
    W = { function() while view:unsplit() do end end },
    -- TODO: { function() view.size = view.size + 10 end  }
    -- TODO: { function() view.size = view.size - 10 end  }
  }

  -- Project Manager
  local function pm_activate(text)
    t.pm.entry_text = text
    t.pm.activate()
  end
  keys.aP = { function() if t.pm.width > 0 then t.pm.toggle_visible() end end }
  keys.ap = {
    function()
      if t.pm.width == 0 then t.pm.toggle_visible() end
      t.pm.focus()
    end
  }
  keys.cap = {
    c = { pm_activate, 'ctags'   },
    b = { pm_activate, 'buffers' },
    f = { pm_activate, '/'       },
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
  keys.ch  = { 'delete_back',       b }
  keys.cah = { 'del_word_left',     b }
  keys.cd  = { 'clear',             b }
  keys.cad = { 'del_word_right',    b }
end

---
-- This module has no functions.
function no_functions() end
no_functions = nil -- undefine

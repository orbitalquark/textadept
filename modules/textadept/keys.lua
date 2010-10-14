-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local locale = _G.locale
local events = _G.events

---
-- Manages and defines key commands in Textadept.
-- This set of key commands is pretty standard among other text editors.
module('_m.textadept.keys', package.seeall)

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
--     -- pressing control, shift, alt and 'a' yields: 'Ctrl+Shift+Alt+A'
--
-- For key values less than 255, Lua's [`string.char()`][string_char] is used to
-- determine the key's string representation. Otherwise, the
-- [`KEYSYMS`][keysyms] lookup table is used.
--
-- [string_char]: http://www.lua.org/manual/5.1/manual.html#pdf-string.char
-- [keysyms]: ../modules/_m.textadept.keys.html#KEYSYMS
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
-- ## Settings
--
-- * `SCOPES_ENABLED`: Flag indicating whether scopes/styles can be used for key
--   commands.
-- * `CTRL`: The string representing the Control key.
-- * `SHIFT`: The string representing the Shift key.
-- * `ALT`: The string representing the Alt key (the Apple key on Mac OSX).
-- * `ADD`: The string representing used to join together a sequence of Control,
--   Shift, or Alt modifier keys.
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
-- `lua` lexer, the global key command with the same shortcut is overridden and
-- `whitespace` is printed to standard out.
--
-- ## Problems
--
-- All Lua functions must be defined BEFORE they are reference in key commands.
-- Therefore, any module containing key commands should be loaded after all
-- other modules, whose functions are being referenced, have been loaded.
--
-- ## Configuration
--
-- It is not recommended to edit Textadept's `modules/textadept/keys.lua`.
-- Instead you can modify `_G.keys` from within your `~/.textadept/init.lua` or
-- from a file `require`d by your `init.lua`.

-- Windows and Linux key commands are listed in the first block.
-- Mac OSX key commands are listed in the second block.

-- settings
local SCOPES_ENABLED = true
local ADD = ''
local CTRL = 'c'..ADD
local SHIFT = 's'..ADD
local ALT = 'a'..ADD
-- end settings

local keys = _M
local b, v = 'buffer', 'view'
local gui = gui

-- CTRL = 'c'
-- SHIFT = 's'
-- ALT = 'a'
-- ADD = ''
-- Control, Shift, Alt, and 'a' = 'caA'
-- Control, Shift, Alt, and '\t' = 'csa\t'

if not MAC then
  -- Windows and Linux key commands.

  --[[
    C:         D       H I J K   M               U
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
  local function toggle_setting(setting)
    local state = buffer[setting]
    if type(state) == 'boolean' then
      buffer[setting] = not state
    elseif type(state) == 'number' then
      buffer[setting] = buffer[setting] == 0 and 1 or 0
    end
    events.emit('update_ui') -- for updating statusbar
  end
  keys.ct.v = {
    e      = { toggle_setting, 'view_eol'           },
    w      = { toggle_setting, 'wrap_mode'          },
    i      = { toggle_setting, 'indentation_guides' },
    ['\t'] = { toggle_setting, 'use_tabs'           },
    [' ']  = { toggle_setting, 'view_ws'            },
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
  -- Recent files.
  local RECENT_FILES = 1
  events.connect('user_list_selection',
    function(type, text)
      if type == RECENT_FILES then io.open_file(text) end
    end)
  keys.ao = {
    function()
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
  }

else
  -- Mac OSX key commands

  --[[
    C:                     J     M               U   W X   Z
    A:         D E     H   J K L                 U       Y
    CS:      C D     G H I J K L M   O   Q   S T U V W X Y Z
    SA:  A B C D       H I J K L M N O   Q R   T U V   X Y
    CA:  A   C   E         J K L M N O   Q R S T U V W X Y Z
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
  keys.ct = { m_editing.transpose_chars }
  -- TODO: { m_editing.squeeze }
  -- TODO: { m_editing.convert_indentation }
  keys.ck = { m_editing.smart_cutcopy }
  -- TODO: { m_editing.smart_cutcopy, 'copy' }
  keys.cy = { 'paste', b }
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
  keys.af = { gui.find.focus       } -- find/replace
  keys.ag = { gui.find.find_next   }
  keys.aG = { gui.find.find_prev   }
  keys.ar = { gui.find.replace     }
  keys.ai = { gui.find.find_incremental }
  keys.aF = {
    function()
      gui.find.in_files = true
      gui.find.focus()
    end
  }
  keys.cag = { gui.find.goto_file_in_list, true  }
  keys.caG = { gui.find.goto_file_in_list, false }
  keys.cg  = { m_editing.goto_line             }

  -- Tools
  keys['f2'] = { gui.command_entry.focus }
  -- Run
  local m_run = _m.textadept.run
  keys.cr = { m_run.run     }
  keys.cR = { m_run.compile }
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
  local function toggle_setting(setting)
    local state = buffer[setting]
    if type(state) == 'boolean' then
      buffer[setting] = not state
    elseif type(state) == 'number' then
      buffer[setting] = buffer[setting] == 0 and 1 or 0
    end
    events.emit('update_ui') -- for updating statusbar
  end
  keys.at.v = {
    e      = { toggle_setting, 'view_eol'           },
    w      = { toggle_setting, 'wrap_mode'          },
    i      = { toggle_setting, 'indentation_guides' },
    ['\t'] = { toggle_setting, 'use_tabs'           },
    [' ']  = { toggle_setting, 'view_ws'            },
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
  -- Recent files.
  local RECENT_FILES = 1
  events.connect('user_list_selection',
    function(type, text)
      if type == RECENT_FILES then io.open_file(text) end
    end)
  keys.co = {
    function()
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
-- Provides access to key commands from _G.
-- @class table
-- @name _G.keys
_G.keys = _M

--------------------------------------------------------------------------------
------------------------- Do not edit below this line. -------------------------
--------------------------------------------------------------------------------

-- Optimize for speed.
local string = _G.string
local string_char = string.char
local string_format = string.format
local pcall = _G.pcall
local next = _G.next
local type = _G.type
local unpack = _G.unpack
local MAC = _G.MAC

---
-- Lookup table for key values higher than 255.
-- If a key value given to 'keypress' is higher than 255, this table is used to
-- return a string representation of the key if it exists.
-- @class table
-- @name KEYSYMS
KEYSYMS = { -- from <gdk/gdkkeysyms.h>
  [65056] = '\t', -- backtab; will be 'shift'ed
  [65288] = '\b',
  [65289] = '\t',
  [65293] = '\n',
  [65307] = 'esc',
  [65535] = 'del',
  [65360] = 'home',
  [65361] = 'left',
  [65362] = 'up',
  [65363] = 'right',
  [65364] = 'down',
  [65365] = 'pup',
  [65366] = 'pdown',
  [65367] = 'end',
  [65379] = 'ins',
  [65470] = 'f1', [65471] = 'f2',  [65472] = 'f3',  [65473] = 'f4',
  [65474] = 'f5', [65475] = 'f6',  [65476] = 'f7',  [65477] = 'f8',
  [65478] = 'f9', [65479] = 'f10', [65480] = 'f11', [65481] = 'f12',
}

-- The current key sequence.
local keychain = {}

-- Clears the current key sequence.
local function clear_key_sequence()
  keychain = {}
  gui.statusbar_text = ''
end

-- Return codes for run_key_command().
local INVALID = -1
local PROPAGATE = 0
local CHAIN = 1
local HALT = 2

-- Runs a key command associated with the current keychain.
-- @param lexer Optional lexer name for lexer-specific commands.
-- @param scope Optional scope name for scope-specific commands.
-- @return INVALID, PROPAGATE, CHAIN, or HALT.
local function run_key_command(lexer, scope)
  local key = keys
  if lexer and type(key) == 'table' and key[lexer] then key = key[lexer] end
  if scope and type(key) == 'table' and key[scope] then key = key[scope] end
  if type(key) ~= 'table' then return INVALID end

  for i = 1, #keychain do
    key = key[keychain[i]]
    if type(key) ~= 'table' then return INVALID end
  end
  if #key == 0 and next(key) then
    gui.statusbar_text = locale.KEYCHAIN..table.concat(keychain, ' ')
    return CHAIN
  end

  local f, args = key[1], { unpack(key, 2) }
  if type(key[1]) == 'string' then
    if key[2] == 'buffer' then
      f, args = buffer[f], { buffer, unpack(key, 3) }
    elseif key[2] == 'view' then
      f, args = view[f], { view, unpack(key, 3) }
    end
  end

  if type(f) ~= 'function' then
    error(locale.KEYS_UNKNOWN_COMMAND..tostring(f))
  end
  return f(unpack(args)) == false and PROPAGATE or HALT
end

-- Key command order for lexer and scope args passed to run_key_command().
local order = {
  { true, true }, -- lexer and scope-specific commands
  { true, false }, -- lexer-specific commands
  { false, false } -- general commands
}

-- Handles Textadept keypresses.
-- It is called every time a key is pressed, and based on lexer and scope,
-- executes a command. The command is looked up in the global 'keys' key
-- command table.
-- @return whatever the executed command returns, true by default. A true
--   return value will tell Textadept not to handle the key afterwords.
local function keypress(code, shift, control, alt)
  local buffer = buffer
  local key
  --print(code, string.char(code))
  if code < 256 then
    key = string_char(code)
    shift = false -- for printable characters, key is upper case
    if MAC and not shift and not control and not alt then
      local ch = string_char(code)
      -- work around native GTK-OSX's handling of Alt key
      if ch:find('[%p%d]') and #keychain == 0 then
        if buffer.anchor ~= buffer.current_pos then buffer:delete_back() end
        buffer:add_text(ch)
        events.emit('char_added', code)
        return true
      end
    end
  else
    if not KEYSYMS[code] then return end
    key = KEYSYMS[code]
  end
  control = control and CTRL or ''
  shift = shift and SHIFT or ''
  alt = alt and ALT or ''
  local key_seq = string_format('%s%s%s%s', control, shift, alt, key)

  if #keychain > 0 and key_seq == keys.clear_sequence then
    clear_key_sequence()
    return true
  end
  keychain[#keychain + 1] = key_seq

  local lexer, scope = buffer:get_lexer(), nil
  if SCOPES_ENABLED then
    scope = buffer:get_style_name(buffer.style_at[buffer.current_pos])
  end
  local success, status
  for i = SCOPES_ENABLED and 1 or 2, #order do
    status = run_key_command(order[i][1] and lexer, order[i][2] and scope)
    if status > 0 then -- CHAIN or HALT
      if status == HALT then
        -- Clear the key sequence, but keep any status messages from the key
        -- command itself.
        keychain = {}
        if not (gui.statusbar_text == locale.INVALID or
                gui.statusbar_text:find('^'..locale.KEYCHAIN)) then
          gui.statusbar_text = ''
        end
      end
      return true
    end
    success = success or status ~= -1
  end
  local size = #keychain - 1
  clear_key_sequence()
  if not success and size > 0 then -- INVALID keychain sequence
    gui.statusbar_text = locale.KEYS_INVALID
    return true
  end
  -- PROPAGATE otherwise.
end
events.connect('keypress', keypress, 1)

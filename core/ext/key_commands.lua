-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Manages and defines key commands in Textadept.
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
--     -- pressing control, shift, alt and 'a' yields: 'Ctrl+Shift+Alt+A'
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
-- `lua` lexer, the global key command with the same shortcut is overriden and
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
-- It is not recommended to edit Textadept's `core/ext/key_commands.lua`. You
-- can either override or add to default key commands in your
-- `~/.textadept/key_commands.lua` or `require` a separate module in your
-- `~/.textadept/init.lua` instead of `ext/key_commands`.

-- Windows and Linux key commands are listed in the first block.
-- Mac OSX key commands are listed in the second block.

-- settings
local SCOPES_ENABLED = true
local ADD = ''
local CTRL = 'c'..ADD
local SHIFT = 's'..ADD
local ALT = 'a'..ADD
-- end settings

---
-- Global container that holds all key commands.
-- @class table
-- @name _G.keys
_G.keys = {}

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
  keys.cn  = { t.new_buffer   }
  keys.co  = { io.open_file   }
  -- TODO: { 'reload', b }
  keys.cs  = { 'save', b      }
  keys.cS  = { 'save_as', b   }
  keys.cw  = { 'close', b     }
  keys.cW  = { io.close_all }
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
  keys.cr = { m_run.run     }
  keys.cR = { m_run.compile }
  -- Snippets
  local m_snippets = _m.textadept.snippets
  keys['\t']  = { m_snippets.insert         }
  keys['s\t'] = { m_snippets.prev           }
  keys.cai    = { m_snippets.cancel_current }
  keys.caI    = { m_snippets.list           }
  keys.ai     = { m_snippets.show_style     }

  -- Buffers
  keys.cb      = { t.switch_buffer             }
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
  keys.cl    = { _m.textadept.mime_types.select_lexer }
  keys['f5'] = { 'colourise', b, 0, -1     }

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
  keys.c0 = { function() buffer.zoom = 0 end }

  -- Miscellaneous not in standard menu.
  -- Recent files.
  local RECENT_FILES = 1
  t.events.add_handler('user_list_selection',
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
  keys.an = { t.new_buffer   }
  keys.ao = { io.open_file   }
  -- TODO: { 'reload', b }
  keys.as = { 'save', b      }
  keys.aS = { 'save_as', b   }
  keys.aw = { 'close', b     }
  keys.aW = { io.close_all }
  -- TODO: { m_session.load } after prompting with open dialog
  -- TODO: { m_session.save } after prompting with save dialog
  keys.aq = { t.quit }

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
  keys.af = { t.find.focus       } -- find/replace
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
  local m_snippets = _m.textadept.snippets
  keys['\t']  = { m_snippets.insert         }
  keys['s\t'] = { m_snippets.prev           }
  keys.cai    = { m_snippets.cancel_current }
  keys.caI    = { m_snippets.list           }
  keys.ci     = { m_snippets.show_style     }

  -- Buffers
  keys.ab      = { t.switch_buffer             }
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
  keys.cl    = { _m.textadept.mime_types.select_lexer }
  keys['f5'] = { 'colourise', b, 0, -1     }

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
  keys.c0 = { function() buffer.zoom = 0 end }

  -- Miscellaneous not in standard menu.
  -- Recent files.
  local RECENT_FILES = 1
  t.events.add_handler('user_list_selection',
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

textadept.user_dofile('key_commands.lua') -- load user key commands

-- Do not edit below this line.

-- optimize for speed
local string = _G.string
local string_char = string.char
local string_format = string.format
local pcall = _G.pcall
local ipairs = _G.ipairs
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
  textadept.statusbar_text = ''
end

-- Helper function that gets commands associated with the current keychain from
-- 'keys'.
-- If the current item in the keychain is part of a chain, throw an error value
-- of -1. This way, pcall will return false and -1, where the -1 can easily and
-- efficiently be checked rather than using a string error message.
local function try_get_cmd(active_table)
  for _, key_seq in ipairs(keychain) do active_table = active_table[key_seq] end
  if #active_table == 0 and next(active_table) then
    textadept.statusbar_text = locale.KEYCHAIN..table.concat(keychain, ' ')
    error(-1, 0)
  else
    local func = active_table[1]
    if type(func) == 'function' then
      return func, { unpack(active_table, 2) }
    elseif type(func) == 'string' then
      local object = active_table[2]
      if object == 'buffer' then
        return buffer[func], { buffer, unpack(active_table, 3) }
      elseif object == 'view' then
        return view[func], { view, unpack(active_table, 3) }
      end
    else
      error(locale.KEYS_UNKNOWN_COMMAND..tostring(func))
    end
  end
end

-- Tries to get a key command based on the lexer and current scope.
local function try_get_cmd1(keys, lexer, scope)
  return try_get_cmd(keys[lexer][scope])
end

-- Tries to get a key command based on the lexer.
local function try_get_cmd2(keys, lexer)
  return try_get_cmd(keys[lexer])
end

-- Tries to get a global key command.
local function try_get_cmd3(keys)
  return try_get_cmd(keys)
end

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
        textadept.events.handle('char_added', code)
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

  local lexer = buffer:get_lexer_language()
  keychain[#keychain + 1] = key_seq
  local ret, func, args
  if SCOPES_ENABLED then
    local style = buffer.style_at[buffer.current_pos]
    local scope = buffer:get_style_name(style)
    --print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)
    ret, func, args = pcall(try_get_cmd1, keys, lexer, scope)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd2, keys, lexer)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd3, keys)
  end

  if ret then
    clear_key_sequence()
    if type(func) == 'function' then
      local ret, retval = pcall(func, unpack(args))
      if ret then
        if type(retval) == 'boolean' then return retval end
      else
        error(retval)
      end
    end
    return true
  else
    -- Clear key sequence because it's not part of a chain.
    -- (try_get_cmd throws error number -1.)
    if func ~= -1 then
      local size = #keychain - 1
      clear_key_sequence()
      if size > 0 then -- previously in a chain
        textadept.statusbar_text = locale.KEYS_INVALID
        return true
      end
    else
      return true
    end
  end
end
textadept.events.add_handler('keypress', keypress, 1)

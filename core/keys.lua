-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Manages key commands in Textadept.
module('keys', package.seeall)

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
-- in the current style have priority, followed by the  ones in the current
-- lexer, and finally the ones in the global table.
--
-- ## Example
--
--     keys = {
--       ['ctrl+f'] = { 'char_right', 'buffer' },
--       ['ctrl+b'] = { 'char_left',  'buffer' },
--       lua = {
--         ['ctrl+c'] = { 'add_text', 'buffer', '-- ' },
--         comment = {
--           ['ctrl+f'] = { function() print('comment') end }
--         }
--       }
--     }
--
-- The first two key commands are global and call `buffer:char_right()` and
-- `buffer:char_left()` respectively. The last two commands apply only in the
-- Lua lexer with the very last one only being available in Lua's `comment`
-- style. If `ctrl+f` is pressed when the current style is `comment` in the
-- `lua` lexer, the global key command with the same shortcut is overridden and
-- `comment` is printed to standard out.
--
-- ## Problems
--
-- All Lua functions must be defined BEFORE they are reference in key commands.
-- Therefore, any module containing key commands should be loaded after all
-- other modules, whose functions are being referenced, have been loaded.
--
-- ## Events
--
-- The following is a list of all key events generated in
-- `event_name(arguments)` format:
--
-- * **keypress** (code, shift, control, alt)<br />
--   Called when a key is pressed.
--       - code: the key code (according to `<gdk/gdkkeysyms.h>`).
--       - shift: flag indicating whether or not the Shift key is pressed.
--       - control: flag indicating whether or not the Control key is pressed.
--       - alt: flag indicating whether or not the Alt/Apple key is pressed.
--   <br />
--   Note: The Alt-Option key in Mac OSX is not available.

-- settings
local SCOPES_ENABLED = true
local ADD = ''
local CTRL = 'c'..ADD
local SHIFT = 's'..ADD
local ALT = 'a'..ADD
-- end settings

-- Optimize for speed.
local string = _G.string
local string_char = string.char
local xpcall = _G.xpcall
local next = _G.next
local type = _G.type
local unpack = _G.unpack
local error = function(e) events.emit('error', e) end

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
  if #keychain > 0 then keychain = {} end
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
    gui.statusbar_text = L('Keychain:')..' '..table.concat(keychain, ' ')
    return CHAIN
  end

  local f, args = key[1], { unpack(key, 2) }
  if type(key[1]) == 'string' and (key[2] == 'buffer' or key[2] == 'view') then
    local v = _G[key[2]]
    f, args = v[f], { v, unpack(key, 3) }
  end

  local _, ret = xpcall(function() return f(unpack(args)) end, error)
  return ret == false and PROPAGATE or HALT
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
  else
    key = KEYSYMS[code]
    if not key then return end
  end
  control = control and CTRL or ''
  shift = shift and SHIFT or ''
  alt = alt and ALT or ''
  local key_seq = control..shift..alt..key

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
        local text = gui.statusbar_text or ''
        if text == L('Invalid sequence') or text:find('^'..L('Keychain:')) then
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
    gui.statusbar_text = L('Invalid sequence')
    return true
  end
  -- PROPAGATE otherwise.
end
events.connect('keypress', keypress, 1)

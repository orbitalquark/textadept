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
-- * A string representing a key command and an associated function or table.
-- * A string language name and its associated `keys`-like table.
-- * A string representing a key command and its associated `keys`-like table.
--   (This is a keychain sequence.)
--
-- Language names are the names of the lexer files in `lexers/` such as `cpp`
-- and `lua`.
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
-- [`KEYSYMS`](../modules/_m.textadept.keys.html#KEYSYMS) lookup table is used.
--
-- [string_char]: http://www.lua.org/manual/5.1/manual.html#pdf-string.char
--
-- Normally, Lua functions are assigned to key commands, but those functions are
-- called without any arguments. In order to pass arguments to a function,
-- assign a table to the key command. This table contains the function followed
-- by its arguments in order. Any [buffer](../modules/buffer.html) or
-- [view](../modules/view.html) references are handled correctly at runtime.
--
-- Key commands can be chained like in Emacs using keychain sequences. By
-- default, the `Esc` key (`Apple+Esc` on Mac OSX) cancels the current keychain,
-- but it can be redefined by setting the `keys.clear_sequence` field.
-- Naturally, the clear sequence cannot be chained.
--
-- ## Settings
--
-- * `CTRL` [string]: The string representing the Control key.
-- * `SHIFT` [string]: The string representing the Shift key.
-- * `ALT` [string]: The string representing the Alt key (the Apple key on Mac
--   OSX).
-- * `ADD` [string]: The string representing used to join together a sequence of
--   Control, Shift, or Alt modifier keys.
--
-- ## Key Command Precedence
--
-- When searching for a key command to execute in the `keys` table, key commands
-- in the current lexer have priority, followed by the ones in the global table.
--
-- ## Example
--
--     keys = {
--       ['ctrl+f'] = { 'char_right', 'buffer' },
--       ['ctrl+b'] = { 'char_left',  'buffer' },
--       lua = {
--         ['ctrl+f'] = { 'add_text', 'buffer', 'function' },
--       }
--     }
--
-- The first two key commands are global and call `buffer:char_right()` and
-- `buffer:char_left()` respectively. The last command applies only in the Lua
-- lexer. If `ctrl+f` is pressed in a Lua file, the global key command with the
-- same shortcut is overridden and `function` is added to the buffer.
--
-- ## Problems
--
-- All Lua functions must be defined BEFORE they are reference in key commands.
-- Therefore, any module containing key commands should be loaded after all
-- other modules, whose functions are being referenced, have been loaded.

-- settings
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
local no_args = {}
local getmetatable = getmetatable
local error = function(e) events.emit(events.ERROR, e) end

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
-- @return INVALID, PROPAGATE, CHAIN, or HALT.
local function run_key_command(lexer)
  local key, key_type = keys, type(keys)
  if lexer and key_type == 'table' and key[lexer] then key = key[lexer] end
  if type(key) ~= 'table' then return INVALID end

  key = key[keychain[1]]
  for i = 2, #keychain do
    if type(key) ~= 'table' then return INVALID end
    key = key[keychain[i]]
  end
  key_type = type(key)

  if key_type ~= 'function' and key_type ~= 'table' then return INVALID end
  if key_type == 'table' and #key == 0 and next(key) then
    gui.statusbar_text = L('Keychain:')..' '..table.concat(keychain, ' ')
    return CHAIN
  end

  local f, args = key_type == 'function' and key or key[1], no_args
  if key_type == 'table' then
    args = key
    -- If the argument is a view or buffer, use the current one instead.
    if type(args[2]) == 'table' then
      local mt, buffer, view = getmetatable(args[2]), buffer, view
      if mt == getmetatable(buffer) then
        args[2] = buffer
      elseif mt == getmetatable(view) then
        args[2] = view
      end
    end
  end
  local _, ret = xpcall(function() return f(unpack(args, 2)) end, error)
  return ret == false and PROPAGATE or HALT
end

-- Handles Textadept keypresses.
-- It is called every time a key is pressed, and based on lexer, executes a
-- command. The command is looked up in the global 'keys' key command table.
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

  local success
  for i = 1, 2 do
    local status = run_key_command(i == 1 and buffer:get_lexer())
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
events.connect(events.KEYPRESS, keypress, 1)

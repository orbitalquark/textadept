-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Manages key bindings in Textadept.
--
-- ## Overview
--
-- Key bindings are defined in the global table `keys`. Each key-value pair in
-- `keys` consists of either a string key sequence and its associated command,
-- a string lexer language (from the *lexers/* directory) with a table of key
-- sequences and commands, or a key sequence with a table of more sequences and
-- commands. The latter is part of what is called a "key chain". When searching
-- for a command to run based on a key sequence, key bindings in the current
-- lexer have priority, followed by the ones in the global table. This means if
-- there are two commands with the same key sequence, the one specific to the
-- current lexer is run. However, if the command returns the boolean value
-- `false`, the lower-priority command is also run. (This is useful for
-- language-specific modules to override commands like Adeptsense
-- autocompletion, but fall back to word autocompletion if the first command
-- fails.)
--
-- ## Key Sequences
--
-- Key sequences are strings built from a combination of modifier keys and the
-- key itself. Modifier keys are "Control", "Shift", and "Alt" on Windows,
-- Linux, BSD, and in curses. On Mac OSX they are "Command" (`⌘`), "Alt/Option"
-- (`⌥`), "Control" (`^`), and "Shift" (`⇧`). These modifiers have the following
-- string representations:
--
-- Modifier | Linux / Win32 | Mac OSX | Terminal |
-- ---------|---------------|---------|----------|
-- Control  | `'c'`         | `'m'`   | `'c'`    |
-- Alt      | `'a'`         | `'a'`   | `'m'`    |
-- Shift    | `'s'`         | `'s'`   | `'s'`    |
-- Command  | N/A           | `'c'`   | N/A      |
--
-- For key values less than 255, their string representation is the character
-- that would normally be inserted if the "Control", "Alt", and "Command"
-- modifiers were not held down. Therefore, a combination of `Ctrl+Alt+Shift+A`
-- has the key sequence `caA` on Windows and Linux, but a combination of
-- `Ctrl+Shift+Tab` has the key sequence `cs\t`. On a United States English
-- keyboard, since the combination of `Ctrl+Shift+,` has the key sequence `c<`
-- (`Shift+,` inserts a `<`), the key binding is referred to as `Ctrl+<`. This
-- allows key bindings to be language and layout agnostic. For key values
-- greater than 255, the [`KEYSYMS`](#KEYSYMS) lookup table is used. Therefore,
-- `Ctrl+Right Arrow` has the key sequence `cright`. Uncommenting the `print()`
-- statements in *core/keys.lua* will print key sequences to standard out
-- (stdout) for inspection.
--
-- ## Commands
--
-- Commands associated with key sequences can be either Lua functions, or
-- tables containing Lua functions with a set of arguments to call the function
-- with. Examples are:
--
--     keys['cn'] = new_buffer
--     keys['cs'] = buffer.save
--     keys['a('] = {_M.textadept.editing.enclose, '(', ')'}
--
-- Note that [`buffer`][] references are handled properly.
--
-- [`buffer`]: buffer.html
--
-- ## Key Chains
--
-- Key chains are a powerful concept. They allow multiple key bindings to be
-- assigned to one key sequence. Language-specific modules
-- [use key chains](#LANGUAGE_MODULE_PREFIX) for their functions. By default,
-- the `Esc` (`⎋` on Mac OSX | `Esc` in curses) key cancels a key chain, but it
-- can be redefined via [`CLEAR`](#CLEAR). An example key chain looks like:
--
--     keys['aa'] = {
--       a = function1,
--       b = function2,
--       c = {function3, arg1, arg2}
--     }
-- @field CLEAR (string)
--   The string representing the key sequence that clears the current key chain.
--   It cannot be part of a key chain.
--   The default value is `'esc'` for the `Esc` (`⎋` on Mac OSX | `Esc` in
--   curses) key.
-- @field LANGUAGE_MODULE_PREFIX (string)
--   The starting key of the key chain reserved for language-specific modules.
--   The default value is `'cl'` on platforms other than Mac OSX, `'ml'`
--   otherwise. Equivalent to `Ctrl+L` (`⌘L` on Mac OSX | `M-L` in curses).
module('keys')]]

local ADD = ''
local CTRL, ALT, META, SHIFT = 'c'..ADD, 'a'..ADD, 'm'..ADD, 's'..ADD
if CURSES then ALT = META end
M.CLEAR = 'esc'
M.LANGUAGE_MODULE_PREFIX = (not OSX and not CURSES and CTRL or META)..'l'

-- Optimize for speed.
local OSX = OSX
local string = string
local string_byte, string_char = string.byte, string.char
local table_unpack = table.unpack
local xpcall, next, type = xpcall, next, type
local no_args = {}
local getmetatable = getmetatable
local error = function(e) events.emit(events.ERROR, e) end

---
-- Lookup table for string representations of key codes higher than 255.
-- Key codes can be identified by temporarily uncommenting the `print()`
-- statements in *core/keys.lua*.
-- @class table
-- @name KEYSYMS
M.KEYSYMS = {
  -- From Scintilla.h and cdk/curdefs.h.
  [7] = 'esc', [8] = '\b', [9] = '\t', [13] = '\n', [27] = 'esc',
  -- From curses.h.
  [263] = '\b',
  -- From Scintilla.h.
  [300] = 'down', [301] = 'up', [302] = 'left', [303] = 'right',
  [304] = 'home', [305] = 'end',
  [306] = 'pgup', [307] = 'pgdn',
  [308] = 'del',
  [309] = 'ins',
  -- From <gdk/gdkkeysyms.h>.
  [0xFE20] = '\t', -- backtab; will be 'shift'ed
  [0xFF08] = '\b',
  [0xFF09] = '\t',
  [0xFF0D] = '\n',
  [0xFF1B] = 'esc',
  [0xFFFF] = 'del',
  [0xFF50] = 'home',
  [0xFF51] = 'left',  [0xFF52] = 'up',
  [0xFF53] = 'right', [0xFF54] = 'down',
  [0xFF55] = 'pgup',  [0xFF56] = 'pgdn',
  [0xFF57] = 'end',
  [0xFF63] = 'ins',
  [0xFF95] = 'kphome',
  [0xFF96] = 'kpleft',  [0xFF97] = 'kpup',
  [0xFF98] = 'kpright', [0xFF99] = 'kpdown',
  [0xFF9A] = 'kppgup',  [0xFF9B] = 'kppgdn',
  [0xFF9C] = 'kpend',
  [0xFFAA] = 'kpmul', [0xFFAB] = 'kpadd',
  [0xFFAD] = 'kpsub', [0xFFAF] = 'kpdiv',
  [0xFFAE] = 'kpdec',
  [0xFFB0] = 'kp0', [0xFFB1] = 'kp1', [0xFFB2] = 'kp2', [0xFFB3] = 'kp3',
  [0xFFB4] = 'kp4', [0xFFB5] = 'kp5', [0xFFB6] = 'kp6', [0xFFB7] = 'kp7',
  [0xFFB8] = 'kp8', [0xFFB9] = 'kp9',
  [0xFFBE] = 'f1',  [0xFFBF] = 'f2',  [0xFFC0] = 'f3',  [0xFFC1] = 'f4',
  [0xFFC2] = 'f5',  [0xFFC3] = 'f6',  [0xFFC4] = 'f7',  [0xFFC5] = 'f8',
  [0xFFC6] = 'f9',  [0xFFC7] = 'f10', [0xFFC8] = 'f11', [0xFFC9] = 'f12',
  -- Mac OSX.
  [16777232] = 'fn', -- GTKOSX does not recognize Fn-key combinations, just this
}

-- The current key sequence.
local keychain = {}

-- Clears the current key sequence.
local function clear_key_sequence()
  -- Clearing a table is faster than re-creating one.
  if #keychain == 1 then keychain[1] = nil else keychain = {} end
end

-- Runs a given command.
-- This is also used by *modules/textadept/menu.lua*.
-- @param command A function or table as described above.
-- @param command_type Equivalent to `type(command)`.
-- @return the value the command returns.
local function run_command(command, command_type)
  local f, args = command_type == 'function' and command or command[1], no_args
  if command_type == 'table' then
    args = command
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
  local _, result = xpcall(f, error, table_unpack(args, 2))
  return result
end
M.run_command = run_command -- export for menu.lua without creating LuaDoc

-- Return codes for `run_key_command()`.
local INVALID, PROPAGATE, CHAIN, HALT = -1, 0, 1, 2

-- Runs a key command associated with the current keychain.
-- @param lexer Optional lexer name for lexer-specific commands.
-- @return `INVALID`, `PROPAGATE`, `CHAIN`, or `HALT`.
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
    gui.statusbar_text = _L['Keychain:']..' '..table.concat(keychain, ' ')
    return CHAIN
  end

  return run_command(key, key_type) == false and PROPAGATE or HALT
end

-- Handles Textadept keypresses.
-- It is called every time a key is pressed, and based on lexer, executes a
-- command. The command is looked up in the `_G.keys` table.
-- @param code The keycode.
-- @param shift Whether or not the Shift modifier is pressed.
-- @param control Whether or not the Control modifier is pressed.
-- @param alt Whether or not the Alt/option modifier is pressed.
-- @param meta Whether or not the Command modifier on Mac OSX is pressed.
-- @return `true` to stop handling the key; `nil` otherwise.
local function keypress(code, shift, control, alt, meta)
  local buffer = buffer
  local key
  --print(code, M.KEYSYMS[code], shift, control, alt, meta)
  if code < 256 then
    key = (not CURSES or code ~= 7) and string_char(code) or M.KEYSYMS[code]
    shift = shift and code < 32 -- for printable characters, key is upper case
  else
    key = M.KEYSYMS[code]
    if not key then return end
  end
  local key_seq = (control and CTRL or '')..(alt and ALT or '')..
                  (meta and OSX and META or '')..(shift and SHIFT or '')..key
  --print(key_seq)

  gui.statusbar_text = ''
  --if CURSES then gui.statusbar_text = '"'..key_seq..'"' end
  if #keychain > 0 and key_seq == M.CLEAR then
    clear_key_sequence()
    return true
  end
  keychain[#keychain + 1] = key_seq

  local success
  for i = 1, 2 do
    local status = run_key_command(i == 1 and buffer:get_lexer(true))
    if status > 0 then -- CHAIN or HALT
      if status == HALT then clear_key_sequence() end
      return true
    end
    success = success or status ~= -1
  end
  local size = #keychain
  clear_key_sequence()
  if not success and size > 1 then -- INVALID keychain sequence
    gui.statusbar_text = _L['Invalid sequence']
    return true
  end
  -- PROPAGATE otherwise.
end
events.connect(events.KEYPRESS, keypress, 1)

-- Returns the GDK integer keycode and modifier mask for a key sequence.
-- This is used for creating menu accelerators.
-- @param key_seq The string key sequence.
-- @return keycode and modifier mask
local function get_gdk_key(key_seq)
  if not key_seq then return nil end
  local mods, key = key_seq:match('^([cams]*)(.+)$')
  if not mods or not key then return nil end
  local modifiers = ((mods:find('s') or key:lower() ~= key) and 1 or 0) +
                    (mods:find('c') and 4 or 0) + (mods:find('a') and 8 or 0) +
                    (mods:find('m') and 268435456 or 0)
  local byte = string_byte(key)
  if #key > 1 or byte < 32 then
    for i, s in pairs(M.KEYSYMS) do
      if s == key and i > 0xFE20 then byte = i break end
    end
  end
  return byte, modifiers
end
M.get_gdk_key = get_gdk_key -- export for menu.lua without generating LuaDoc

---
-- Map of key bindings to commands, with language-specific key tables assigned
-- to a lexer name key.
-- @class table
-- @name _G.keys
local keys

return M

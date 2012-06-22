-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Manages key commands in Textadept.
--
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
-- A key command string is built from a combination of the `CTRL`, `ALT`,
-- `META`, `SHIFT`, and `ADD` constants as well as the pressed key itself. The
-- value of `ADD` is inserted between each of `CTRL`, `ALT`, `META`, `SHIFT`,
-- and the key. For example:
--
--     -- keys.lua:
--     CTRL = 'Ctrl'
--     ALT = 'Alt'
--     SHIFT = 'Shift'
--     META = 'Meta'
--     ADD = '+'
--     -- pressing control, alt, shift, and 'a' yields: 'Ctrl+Alt+Shift+A'
--
-- For key values less than 255, Lua's [`string.char()`][] is used to determine
-- the key's string representation. Otherwise, the [`KEYSYMS`](#KEYSYMS) lookup
-- table is used.
--
-- [`string.char()`]: http://www.lua.org/manual/5.2/manual.html#pdf-string.char
--
-- Normally, Lua functions are assigned to key commands, but those functions are
-- called without any arguments. In order to pass arguments to a function,
-- assign a table to the key command. This table contains the function followed
-- by its arguments in order. Any [buffer][] or [view][] references are handled
-- correctly at runtime.
--
-- [buffer]: buffer.html
-- [view]: view.html
--
-- Key commands can be chained like in Emacs using keychain sequences. By
-- default, the `Esc` key (`Apple+Esc` on Mac OSX) cancels the current keychain,
-- but it can be redefined by re-defining [`CLEAR`](#CLEAR). Naturally, the
-- clear sequence cannot be chained.
--
-- ## Precedence
--
-- When searching for a key command to execute in the `keys` table, key commands
-- in the current lexer have priority, followed by the ones in the global table.
--
-- ### Propagation
--
-- Normally when the same key command is assigned to two separate functions of
-- different precedence, the higher priority key command is run and the lower
-- priority one is not. However, it is sometimes desirable to have the lower
-- priority command run after the higher one. For example, `Ctrl+Enter` may
-- trigger Adeptsense autocompletion in lexers that have Adeptsense, but should
-- fall back on autocompleting words in the buffer if no Adeptsense completions
-- are available. In order for this to happen, the first function has to return
-- `false` (and only `false`; `nil` is not sufficient) when it wants to allow a
-- lower priority function to run. Any other return value halts propagation and
-- the key is consumed.
--
-- ## Example
--
--     keys = {
--       ['ctrl+f'] = buffer.char_right
--       ['ctrl+b'] = buffer.char_left,
--       lua = {
--         ['ctrl+f'] = { buffer.add_text, buffer, 'function' },
--         ['ctrl+b'] = function() return false end
--       }
--     }
--
-- The first two key commands are global and call `buffer:char_right()` and
-- `buffer:char_left()` respectively. The last two commands apply only in the
-- Lua lexer. If `ctrl+f` is pressed in a Lua file, the global key command with
-- the same shortcut is overridden and `function` is added to the buffer.
-- However, `ctrl+b` in a Lua file does not override its global command because
-- of the `false` return. Instead, propagation occurs as described above.
--
-- ## Problems
--
-- All Lua functions must be defined **before** they are reference in key
-- commands. Therefore, any module containing key commands should be loaded
-- after all other modules, whose functions are being referenced, have been
-- loaded.
-- @field CLEAR (string)
--   The string representing the key sequence that clears the current keychain.
--   The default value is `'esc'` (Escape).
-- @field LANGUAGE_MODULE_PREFIX (string)
--   The starting key command of the keychain reserved for language-specific
--   modules.
--   The default value is Ctrl/Cmd+L.
module('keys')]]

local ADD = ''
local CTRL, ALT, META, SHIFT = 'c'..ADD, 'a'..ADD, 'm'..ADD, 's'..ADD
if NCURSES then ALT = META end
M.CLEAR = 'esc'
M.LANGUAGE_MODULE_PREFIX = (not OSX and not NCURSES and CTRL or META)..'l'

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
-- Lookup table for key codes higher than 255.
-- If a key code given to `keypress()` is higher than 255, this table is used to
-- return a string representation of the key if it exists.
-- @class table
-- @name KEYSYMS
M.KEYSYMS = {
  -- from Scintilla.h
  [300] = 'down', [301] = 'up', [302] = 'left', [303] = 'right',
  [304] = 'home', [305] = 'end',
  [306] = 'pgup', [307] = 'pgdn',
  [308] = 'del',
  [309] = 'ins',
  -- from <gdk/gdkkeysyms.h>
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
}

-- The current key sequence.
local keychain = {}

-- Clears the current key sequence.
local function clear_key_sequence()
  -- Clearing a table is faster than re-creating one.
  if #keychain == 1 then keychain[1] = nil else keychain = {} end
end

-- Runs a given command.
-- This is also used by `modules/textadept/menu.lua`.
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
  --print(code, M.KEYSYMS[ch], shift, control, alt, meta)
  if code < 256 then
    key = string_char(code)
    shift = shift and code < 32 -- for printable characters, key is upper case
  else
    key = M.KEYSYMS[code]
    if not key then return end
  end
  local key_seq = (control and CTRL or '')..(alt and ALT or '')..
                  (meta and OSX and META or '')..(shift and SHIFT or '')..key
  --print(key_seq)

  gui.statusbar_text = ''
  --if NCURSES then gui.statusbar_text = '"'..key_seq..'"' end
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
      if s == key and i ~= 0xFE20 then byte = i break end
    end
  end
  return byte, modifiers
end
M.get_gdk_key = get_gdk_key -- export for menu.lua without generating LuaDoc

return M

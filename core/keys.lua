-- Copyright 2007-2020 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Manages key bindings in Textadept.
--
-- ### Overview
--
-- Define key bindings in the global `keys` table in key-value pairs. Each pair
-- consists of either a string key sequence and its associated command, a string
-- lexer name (from the *lexers/* directory) with a table of key sequences and
-- commands, a string key mode with a table of key sequences and commands, or a
-- key sequence with a table of more sequences and commands. The latter is part
-- of what is called a "key chain", to be discussed below. When searching for a
-- command to run based on a key sequence, Textadept considers key bindings in
-- the current key mode to have priority. If no key mode is active,
-- language-specific key bindings have priority, followed by the ones in the
-- global table. This means if there are two commands with the same key
-- sequence, Textadept runs the language-specific one. However, if the command
-- returns the boolean value `false`, Textadept also runs the lower-priority
-- command. (This is useful for language modules to override commands like
-- autocompletion, but fall back to word autocompletion if the first command
-- fails.)
--
-- ### Key Sequences
--
-- Key sequences are strings built from an ordered combination of modifier keys
-- and the key's inserted character. Modifier keys are "Control", "Shift", and
-- "Alt" on Windows, Linux, BSD, and in the terminal version. On macOS they are
-- "Control" (`^`), "Alt/Option" (`⌥`), "Command" (`⌘`), and "Shift" (`⇧`).
-- These modifiers have the following string representations:
--
-- Modifier | Linux / Win32 | macOS     | Terminal  |
-- ---------|---------------|-----------|-----------|
-- Control  | `'ctrl'`      | `'ctrl'`  | `'ctrl'`  |
-- Alt      | `'alt'`       | `'alt'`   | `'meta'`  |
-- Command  | N/A           | `'cmd'`   | N/A       |
-- Shift    | `'shift'`     | `'shift'` | `'shift'` |
--
-- The string representation of key values less than 255 is the character that
-- Textadept would normally insert if the "Control", "Alt", and "Command"
-- modifiers were not held down. Therefore, a combination of `Ctrl+Alt+Shift+A`
-- has the key sequence `ctrl+alt+A` on Windows and Linux, but a combination of
-- `Ctrl+Shift+Tab` has the key sequence `ctrl+shift+\t`. On a United States
-- English keyboard, since the combination of `Ctrl+Shift+,` has the key
-- sequence `ctrl+<` (`Shift+,` inserts a `<`), Textadept recognizes the key
-- binding as `Ctrl+<`. This allows key bindings to be language and layout
-- agnostic. For key values greater than 255, Textadept uses the
-- [`keys.KEYSYMS`]() lookup table. Therefore, `Ctrl+Right Arrow` has the key
-- sequence `ctrl+right`. Uncommenting the `print()` statements in
-- *core/keys.lua* causes Textadept to print key sequences to standard out
-- (stdout) for inspection.
--
-- ### Commands
--
-- A command bound to a key sequence is simply a Lua function. For example:
--
--     keys['ctrl+n'] = buffer.new
--     keys['ctrl+z'] = buffer.undo
--     keys['ctrl+u'] = function() io.quick_open(_USERHOME) end
--
-- Textadept handles [`buffer`]() references properly in static contexts.
--
-- ### Modes
--
-- Modes are groups of key bindings such that when a key [mode](#keys.mode) is
-- active, Textadept ignores all key bindings defined outside the mode until the
-- mode is unset. Here is a simple vi mode example:
--
--     keys.command_mode = {
--       ['h'] = buffer.char_left,
--       ['j'] = buffer.line_up,
--       ['k'] = buffer.line_down,
--       ['l'] = buffer.char_right,
--       ['i'] = function()
--         keys.mode = nil
--         ui.statusbar_text = 'INSERT MODE'
--       end
--     }
--     keys['esc'] = function() keys.mode = 'command_mode' end
--     events.connect(events.UPDATE_UI, function()
--       if keys.mode == 'command_mode' then return end
--       ui.statusbar_text = 'INSERT MODE'
--     end)
--     keys.mode = 'command_mode' -- default mode
--
-- **Warning**: When creating a mode, be sure to define a way to exit the mode,
-- otherwise you will probably have to restart Textadept.
--
-- ### Key Chains
--
-- Key chains are a powerful concept. They allow you to assign multiple key
-- bindings to one key sequence. By default, the `Esc` key cancels a key chain,
-- but you can redefine it via [`keys.CLEAR`](). An example key chain looks
-- like:
--
--     keys['alt+a'] = {
--       a = function1,
--       b = function2,
--       c = {...}
--     }
-- @field CLEAR (string)
--   The key that clears the current key chain.
--   It cannot be part of a key chain.
--   The default value is `'esc'` for the `Esc` key.
-- @field mode (string)
--   The current key mode.
--   When non-`nil`, all key bindings defined outside of `keys[mode]` are
--   ignored.
--   The default value is `nil`.
module('keys')]]

local CTRL, ALT, CMD, SHIFT = 'ctrl+', 'alt+', 'cmd+', 'shift+'
if CURSES then ALT = 'meta+' end
M.CLEAR = 'esc'

---
-- Lookup table for string representations of key codes higher than 255.
-- Key codes can be identified by temporarily uncommenting the `print()`
-- statements in *core/keys.lua*.
-- Recognized codes are: esc, \b, \t, \n, down, up, left, right, home, end,
-- pgup, pgdn, del, ins, and f1-f12.
-- The GUI version also recognizes: kpenter, kphome, kpend, kpleft, kpup,
-- kpright, kpdown, kppgup, kppgdn, kpmul, kpadd, kpsub, kpdiv, kpdec, and
-- kp0-kp9.
-- @class table
-- @name KEYSYMS
M.KEYSYMS = {--[[From Scintilla.h for CURSES]][7]='esc',[8]='\b',[9]='\t',[13]='\n',--[[From curses.h]][263]='\b',[343]='\n',--[[From Scintilla.h for CURSES]][300]='down',[301]='up',[302]='left',[303]='right',[304]='home',[305]='end',[306]='pgup',[307]='pgdn',[308]='del',[309]='ins',--[[From <gdk/gdkkeysyms.h>]][0xFE20]='\t'--[[backtab; will be 'shift'ed]],[0xFF08]='\b',[0xFF09]='\t',[0xFF0D]='\n',[0xFF1B]='esc',[0xFFFF]='del',[0xFF50]='home',[0xFF51]='left',[0xFF52]='up',[0xFF53]='right',[0xFF54]='down',[0xFF55]='pgup',[0xFF56]='pgdn',[0xFF57]='end',[0xFF63]='ins',[0xFF8D]='kpenter',[0xFF95]='kphome',[0xFF9C]='kpend',[0xFF96]='kpleft',[0xFF97]='kpup',[0xFF98]='kpright',[0xFF99]='kpdown',[0xFF9A]='kppgup',[0xFF9B]='kppgdn',[0xFFAA]='kpmul',[0xFFAB]='kpadd',[0xFFAD]='kpsub',[0xFFAF]='kpdiv',[0xFFAE]='kpdec',[0xFFB0]='kp0',[0xFFB1]='kp1',[0xFFB2]='kp2',[0xFFB3]='kp3',[0xFFB4]='kp4',[0xFFB5]='kp5',[0xFFB6]='kp6',[0xFFB7]='kp7',[0xFFB8]='kp8',[0xFFB9]='kp9',[0xFFBE]='f1',[0xFFBF]='f2',[0xFFC0]='f3',[0xFFC1]='f4',[0xFFC2]='f5',[0xFFC3]='f6',[0xFFC4]='f7',[0xFFC5]='f8',[0xFFC6]='f9',[0xFFC7]='f10',[0xFFC8]='f11',[0xFFC9]='f12'}

-- The current key sequence.
local keychain = {}

---
-- The current chain of key sequences. (Read-only.)
-- @class table
-- @name keychain
M.keychain = setmetatable({}, {
  __index = keychain,
  __newindex = function() error('read-only table') end,
  __len = function() return #keychain end
})

-- Clears the current key sequence.
local function clear_key_seq() for i = 1, #keychain do keychain[i] = nil end end

-- Return codes for `key_command()`.
local INVALID, PROPAGATE, CHAIN, HALT = -1, 0, 1, 2

-- Error handler for key commands that simply emits the error. This is needed
-- so `key_command()` can return `HALT` instead of never returning due to the
-- error.
local function key_error(errmsg) events.emit(events.ERROR, errmsg) end

-- Runs a key command associated with the current keychain.
-- @param prefix Optional prefix name for mode/lexer-specific commands.
-- @return `INVALID`, `PROPAGATE`, `CHAIN`, or `HALT`.
local function key_command(prefix)
  local key = not prefix and M or M[prefix]
  for i = 1, #keychain do
    if type(key) ~= 'table' then return INVALID end
    key = key[keychain[i]]
  end
  if type(key) ~= 'function' and type(key) ~= 'table' then return INVALID end
  if type(key) == 'table' then
    ui.statusbar_text = string.format(
      '%s %s', _L['Keychain:'], table.concat(keychain, ' '))
    return CHAIN
  end
  return select(2, xpcall(key, key_error)) == false and PROPAGATE or HALT
end

-- Handles Textadept keypresses, executing commands based on a mode or lexer as
-- necessary.
events.connect(events.KEYPRESS, function(code, shift, control, alt, cmd, caps)
  --print(code, M.KEYSYMS[code], shift, control, alt, cmd, caps)
  if caps and (shift or control or alt or cmd) and code < 256 then
    code = string[shift and 'upper' or 'lower'](string.char(code)):byte()
  end
  local key = code >= 32 and code < 256 and string.char(code) or M.KEYSYMS[code]
  if not key then return end
  -- Since printable characters are uppercased, disable shift.
  if shift and code >= 32 and code < 256 then shift = false end
  -- For composed keys on macOS, ignore alt.
  if OSX and alt and code < 256 then alt = false end
  local key_seq = (control and CTRL or '') .. (alt and ALT or '') ..
    (cmd and OSX and CMD or '') .. (shift and SHIFT or '') .. key
  --print(key_seq)

  ui.statusbar_text = ''
  --if CURSES then ui.statusbar_text = string.format('"%s"', key_seq) end
  local in_chain = #keychain > 0
  if in_chain and key_seq == M.CLEAR then clear_key_seq() return true end
  keychain[#keychain + 1] = key_seq

  local status = PROPAGATE
  if not M.mode then
    status = key_command(buffer:get_lexer(true))
    if status <= PROPAGATE and not M.mode then status = key_command() end
  else
    status = key_command(M.mode)
  end
  if status ~= CHAIN then clear_key_seq() end
  if status > PROPAGATE then return true end -- CHAIN or HALT
  if status == INVALID and in_chain then
    ui.statusbar_text = _L['Invalid sequence']
    return true
  end
  -- PROPAGATE otherwise.
end)

--[[ This comment is for LuaDoc.
---
-- Map of key bindings to commands, with language-specific key tables assigned
-- to a lexer name key.
-- @class table
-- @name _G.keys
local keys]]

for lexer in string.gmatch('actionscript ada apdl ansi_c antlr apl applescript asp autoit awk b_lang bash batch bibtex boo chuck clojure cmake coffeescript context cpp crystal csharp css cuda desktop django dmd dockerfile dot eiffel elixir elm erlang fantom faust fennel fish forth fortran fsharp gap gettext gherkin glsl gnuplot go groovy gtkrc haskell html icon idl inform ini Io java javascript jq json jsp latex ledger less lilypond lisp logtalk lua makefile matlab moonscript myrddin nemerle nim nsis objective_c pascal perl php pico8 pike pkgbuild prolog props protobuf ps pure python rails rc rebol rest rexx rhtml rstats ruby rust sass scala scheme smalltalk sml snobol4 sql tcl tex text toml vala vb vbscript verilog vhdl wsf xml yaml', '%S+') do M[lexer] = {} end

return M

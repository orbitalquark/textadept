-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Manages key bindings in Textadept.
--
-- ### Key Bindings Overview
--
-- Define key bindings in the global `keys` table in key-value pairs. Each pair consists of either:
-- - A string key sequence and its associated command.
-- - A string lexer name and its table of key sequences and commands. These are called
--	language-specific keys.
-- - A string key mode and its table of key sequences and commands. This is called a key mode.
-- - A key sequence and its table of more key sequences and commands. This is called a key chain.
--
-- When searching for a command to run based on a key sequence, Textadept considers key bindings
-- in the current key mode to have priority. If no key mode is active, language-specific key
-- bindings have priority, followed by the ones in the global table. This means if there are
-- two commands with the same key sequence, Textadept runs the language-specific one. However,
-- if the command returns the boolean value `false`, Textadept also runs the lower-priority
-- command. (This is useful for overriding commands like autocompletion with language-specific
-- completion, but fall back to word autocompletion if the first command fails.)
--
-- ### Key Sequences
--
-- Key sequences are strings built from an ordered combination of modifier keys and the key's
-- inserted character. Modifier keys are "Control", "Shift", and "Alt" on Windows, Linux/BSD,
-- and in the terminal version. On macOS they are "Control" (`^`), "Alt/Option" (`⌥`), "Command"
-- (`⌘`), and "Shift" (`⇧`). These modifiers have the following string representations:
--
-- Modifier |  Windows / Linux / BSD | macOS | Terminal
-- -|-|-|-
-- Control | `'ctrl'` | `'ctrl'` | `'ctrl'`
-- Alt | `'alt'` | `'alt'` | `'meta'`
-- Command | N/A | `'cmd'` | N/A
-- Shift | `'shift'` | `'shift'` | `'shift'`
--
-- The string representation of key values less than 255 is the character that Textadept would
-- normally insert if the "Control", "Alt", and "Command" modifiers were not held down. Therefore,
-- a combination of `Ctrl+Alt+Shift+A` has the key sequence `ctrl+alt+A` on Windows and Linux/BSD,
-- but a combination of `Ctrl+Shift+Tab` has the key sequence `ctrl+shift+\t`. On a United States
-- English keyboard, since the combination of `Ctrl+Shift+,` has the key sequence `ctrl+<`
-- (`Shift+,` inserts a `<`), Textadept recognizes the key binding as `Ctrl+<`. This allows
-- key bindings to be language and layout agnostic. For key values greater than 255, Textadept
-- uses the `keys.KEYSYMS` lookup table. Therefore, `Ctrl+Right Arrow` has the key sequence
-- `ctrl+right`.
--
-- Activating the "Tools > Show Keys..." menu item or its key binding will start showing key
-- sequences in the statusbar, along with their assigned commands, if any. For sequences with
-- a trailing "0x*XXXX*", that number can be aliased to a string representation in `keys.KEYSYMS`.
-- For your convenience, Textadept copies key sequences to the clipboard.
--
-- ### Commands
--
-- A command bound to a key sequence is simply a Lua function. For example:
--
-- ```lua
-- keys['ctrl+n'] = buffer.new
-- keys['ctrl+z'] = buffer.undo
-- keys.c['shift+\n'] = function() -- language-specific key
-- 	buffer:line_end()
-- 	buffer:add_text(';')
-- 	buffer:new_line()
-- end
-- keys['0x1234'] = function() ... end -- key code not in keys.KEYSYMS
-- ```
--
-- Textadept handles `buffer` and `view` references properly in this context; it will use the
-- correct buffer and view when running the key command.
--
-- ### Modes
--
-- Modes are groups of key bindings such that when a key [mode](#keys.mode) is active, Textadept
-- ignores all key bindings defined outside the mode until the mode is unset. Here is a simple
-- vi mode example:
--
-- ```lua
-- keys.command_mode = {
-- 	['h'] = buffer.char_left,
-- 	['j'] = buffer.line_up,
-- 	['k'] = buffer.line_down,
-- 	['l'] = buffer.char_right,
-- 	['i'] = function()
-- 		keys.mode = nil
-- 		ui.statusbar_text = 'INSERT MODE'
-- 	end
-- }
-- keys['esc'] = function() keys.mode = 'command_mode' end
-- events.connect(events.UPDATE_UI, function()
-- 	if keys.mode == 'command_mode' then return end
-- 	ui.statusbar_text = 'INSERT MODE'
-- end)
-- keys.mode = 'command_mode' -- default mode
-- ```
--
-- **Warning**: When creating a mode, be sure to define a way to exit the mode, otherwise you
-- will probably have to restart Textadept.
--
-- ### Key Chains
--
-- Key chains are a powerful concept. They allow you to assign multiple key bindings to one
-- key sequence. By default, the `Esc` key cancels a key chain, but you can redefine it via
-- `keys.CLEAR`. An example key chain looks like:
--
-- ```lua
-- keys['alt+a'] = {
-- 	a = function1,
-- 	b = function2,
-- 	c = {...}
-- }
-- ```
--
-- Pressing `Alt+A` activates the chain, and pressing `A` after that invokes function1. `Alt+A`
-- followed by `B` invokes function2, and so on.
-- @module keys
local M = {}

--- The current key mode.
-- When non-`nil`, all key bindings defined outside of `keys[keys.mode]` are ignored.
--
-- The default value is `nil`.
-- @field mode

--- Emitted when pressing a recognized key.
-- If any handler returns `true`, the key is not handled further (e.g. inserted into the buffer).
--
-- Arguments:
-- - *key*: The string representation of the [key sequence](#key-sequences).
-- @field _G.events.KEYPRESS

--- The key that clears the current key chain.
-- It cannot be part of a key chain.
-- The default value is `'esc'` for the `Esc` key.
M.CLEAR = 'esc'

--- Lookup table for string representations of key codes higher than 255.
-- Recognized codes are: esc, \b, \t, \n, down, up, left, right, home, end, pgup, pgdn, del, ins,
-- and f1-f12. Unrecognized key codes can be identified using the "Tools > Show Keys..." menu
-- item and start with "0x".
--
-- The GUI version also recognizes: menu, kpenter, kphome, kpend, kpleft, kpup, kpright, kpdown,
-- kppgup, kppgdn, kpmul, kpadd, kpsub, kpdiv, kpdec, and kp0-kp9.
-- @usage keys.KEYSYMS[0x1234] = 'symbol'
-- @usage keys['ctrl+symbol'] = function() ... end
-- @table KEYSYMS

-- LuaFormatter off
M.KEYSYMS = {--[[From Scintilla.h for CURSES]][7]='esc',[8]='\b',[9]='\t',[13]='\n',--[[From curses.h]][263]='\b',[343]='\n',--[[From Scintilla.h for CURSES]][300]='down',[301]='up',[302]='left',[303]='right',[304]='home',[305]='end',[306]='pgup',[307]='pgdn',[308]='del',[309]='ins',--[[From <gdk/gdkkeysyms.h>]][0xFE20]='\t'--[[backtab; will be 'shift'ed]],[0xFF08]='\b',[0xFF09]='\t',[0xFF0D]='\n',[0xFF1B]='esc',[0xFFFF]='del',[0xFF50]='home',[0xFF51]='left',[0xFF52]='up',[0xFF53]='right',[0xFF54]='down',[0xFF55]='pgup',[0xFF56]='pgdn',[0xFF57]='end',[0xFF63]='ins',[0xFF67]='menu',[0xFF8D]='kpenter',[0xFF95]='kphome',[0xFF9C]='kpend',[0xFF96]='kpleft',[0xFF97]='kpup',[0xFF98]='kpright',[0xFF99]='kpdown',[0xFF9A]='kppgup',[0xFF9B]='kppgdn',[0xFFAA]='kpmul',[0xFFAB]='kpadd',[0xFFAD]='kpsub',[0xFFAF]='kpdiv',[0xFFAE]='kpdec',[0xFFB0]='kp0',[0xFFB1]='kp1',[0xFFB2]='kp2',[0xFFB3]='kp3',[0xFFB4]='kp4',[0xFFB5]='kp5',[0xFFB6]='kp6',[0xFFB7]='kp7',[0xFFB8]='kp8',[0xFFB9]='kp9',[0xFFBE]='f1',[0xFFBF]='f2',[0xFFC0]='f3',[0xFFC1]='f4',[0xFFC2]='f5',[0xFFC3]='f6',[0xFFC4]='f7',[0xFFC5]='f8',[0xFFC6]='f9',[0xFFC7]='f10',[0xFFC8]='f11',[0xFFC9]='f12',--[[From Qt]][0x01000000]='esc',[0x01000001]='\t',[0x01000002]='\t'--[[backtab; will be 'shift'ed]],[0x01000003]='\b',[0x01000004]='\n',[0x01000005]='kpenter',[0x01000006]='ins',[0x01000007]='del',[0x01000010]='home',[0x01000011]='end',[0x01000012]='left',[0x01000013]='up',[0x01000014]='right',[0x01000015]='down',[0x01000016]='pgup',[0x01000017]='pgdn',[0x01000030]='f1',[0x01000031]='f2',[0x01000032]='f3',[0x01000033]='f4',[0x01000034]='f5',[0x01000035]='f6',[0x01000036]='f7',[0x01000037]='f8',[0x01000038]='f9',[0x01000039]='f10',[0x0100003a]='f11',[0x0100003b]='f12',[0x01000055]='menu'}
local qt_ignore, gtk_ignore = {[0x1000020]=true,[0x1000021]=true,[0x1000022]=true,[0x1000023]=true}, {[0xFFE1]=true,[0xFFE2]=true,[0xFFE3]=true,[0xFFE4]=true,[0xFFE9]=true,[0xFFEA]=true,[0xFFEB]=true,[0xFFEC]=true}
-- LuaFormatter on

local SHIFT, CTRL, ALT, META = _SCINTILLA.MOD_SHIFT, _SCINTILLA.MOD_CTRL, _SCINTILLA.MOD_ALT,
	_SCINTILLA.MOD_META
-- Converts raw key events into key sequences and emits `events.KEYPRESS`.
events.connect(events.KEY, function(code, mods)
	if QT and qt_ignore[code] or GTK and gtk_ignore[code] then return end -- e.g. lone modifier key
	local shift, ctrl, alt, cmd = mods & SHIFT > 0, mods & CTRL > 0, mods & ALT > 0, mods & META > 0
	if OSX and not CURSES then ctrl, cmd = cmd, ctrl end -- swap
	local key = code >= 32 and code < 256 and string.char(code) or M.KEYSYMS[code]
	-- Qt always reports upper-case key codes.
	if key and QT and not shift and code < 256 then key = key:lower() end
	-- Except on macOS for some reason, Qt reports '⌘{' and '⌘}' (and only those) as '⇧⌘[' and '⇧⌘]'.
	if OSX and QT and cmd and shift and key:find('^[%[%]]$') then key = key == '[' and '{' or '}' end
	-- Since printable characters are uppercased, disable shift.
	if shift and code >= 32 and code < 256 then shift = false end
	-- For composed keys on macOS, ignore alt.
	if (OSX and not CURSES) and alt and code < 256 then alt = false end
	-- Report unrecognized codes in hex.
	if not key then key = string.format('0x%X', code) end
	-- Emit the keypress.
	return events.emit(events.KEYPRESS, string.format('%s%s%s%s%s', ctrl and 'ctrl+' or '', alt and
		(not CURSES and 'alt+' or 'meta+') or '', cmd and OSX and 'cmd+' or '',
		shift and 'shift+' or '', key))
end)

--- The current key sequence.
local keychain = {}

--- The current chain of key sequences. (Read-only)
-- @table keychain
M.keychain = setmetatable({}, {
	__index = keychain, __newindex = function() error('read-only table') end,
	__len = function() return #keychain end
})

--- Clears the current key sequence.
local function clear_key_seq() for i = 1, #keychain do keychain[i] = nil end end

-- Return codes for `key_command()`.
local INVALID, PROPAGATE, CHAIN, HALT = -1, 0, 1, 2

--- Error handler for key commands that simply emits the error.
-- This is needed so `key_command()` can return `HALT` instead of never returning due to the error.
local function key_error(errmsg) events.emit(events.ERROR, errmsg) end

--- Runs a key command associated with the current keychain.
-- @param[opt] prefix Optional prefix name for mode/lexer-specific commands.
-- @return `INVALID`, `PROPAGATE`, `CHAIN`, or `HALT`.
local function key_command(prefix)
	local key = not prefix and M or M[prefix]
	for i = 1, #keychain do
		if type(key) ~= 'table' then return INVALID end
		key = key[keychain[i]]
	end
	if type(key) ~= 'function' and type(key) ~= 'table' then return INVALID end
	if type(key) == 'table' and (not getmetatable(key) or not getmetatable(key).__call) then
		if key._lexer and prefix == M.mode then return PROPAGATE end -- typed key matches lexer name
		ui.statusbar_text = string.format('%s %s', _L['Keychain:'], table.concat(keychain, ' '))
		return CHAIN
	end
	return select(2, xpcall(key, key_error)) == false and PROPAGATE or HALT
end

-- Handles Textadept keypresses, executing commands based on a mode or lexer as necessary.
events.connect(events.KEYPRESS, function(key)
	ui.statusbar_text = ''
	local in_chain = #keychain > 0
	if in_chain and key == M.CLEAR then
		clear_key_seq()
		return true
	end
	keychain[#keychain + 1] = key

	local status
	if not M.mode then
		status = key_command(buffer:get_lexer(true))
		if status <= PROPAGATE then status = key_command() end
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

local platform = CURSES and 3 or OSX and 2 or 1
--- Assigns key bindings for the current platform based on a map of commands to lists of their
-- platform-specific key sequences.
-- @param[opt=keys] keys Table to assign key bindings in.
-- @param bindings Map of Lua functions to tables of key sequences for Windows/Linux/BSD, macOS,
--	and the terminal version, in that order. A platform key sequence may itself be a table
--	of sequences in order to assign multiple sequences to the same command.
-- @usage keys.assign_platform_bindings{
--		[buffer.new] = {'ctrl+n', 'cmd+n', 'ctrl+n'}
--		[buffer.line_down] = {'down', {'down', 'ctrl+n'}, 'down'},
--	}
function M.assign_platform_bindings(keys, bindings)
	if not bindings then keys, bindings = _G.keys, keys end
	for f, platform_keys in pairs(bindings) do
		local platform_key = platform_keys[platform]
		if type(platform_key) == 'string' then
			keys[platform_key] = f
		elseif type(platform_key) == 'table' then
			for _, key in ipairs(platform_key) do keys[key] = f end
		end
	end
end

--- Textadept's [key bindings](#the-keys-module), a map of key shortcuts to commands or key chains.
-- Language-specific keys are in subtables assigned to lexer names.
-- @usage keys['ctrl+n'] = buffer.new
-- @usage keys.c['shift+\n'] = function() -- language-specific key
--		buffer:line_end()
--		buffer:add_text(';')
--		buffer:new_line()
--	end
-- @table _G.keys

for _, name in ipairs(lexer.names()) do M[name] = {_lexer = true} end

return M

-- Copyright 2025-2026 Mitchell. See LICENSE.

if UI ~= 'terminal' then return nil end

--- Allows the terminal version's buffer clipboard functions to operate on the system clipboard.
-- This module is only enabled in the terminal version.
-- @module textadept.clipboard
local M = {}

--- The command to retrieve the system clipboard's contents.
-- The default values are:
-- - Windows: `powershell get-clipboard`
-- - macOS: `pbpaste`
-- - Linux/BSD: `xsel -b -o` if it exists, or `wl-paste -n` otherwise. A package manager likely
--	supplies these commands. On Ubuntu for example, the `xsel` and `wl-clipboard` packages,
--	respectively, supply these commands.
M.paste_command = OS == 'macos' and 'pbpaste' or OS == 'windows' and 'powershell get-clipboard' or
	os.execute('xsel > /dev/null 2>&1') and 'xsel -b -o' or 'wl-paste -n'

--- The command to modify the system clipboard's contents.
-- The default values are:
-- - Windows: `clip`
-- - macOS: `pbcopy`
-- - Linux/BSD: `xsel -n -b -i` if it exists, or `wl-copy -f` otherwise. A package manager
--	likely supplies these commands. On Ubuntu for example, the `xsel` and `wl-clipboard`
--	packages, respectively, supply these commands.
--	Note: this command should not fork.
M.copy_command = OS == 'macos' and 'pbcopy' or OS == 'windows' and 'clip' or
	os.execute('xsel > /dev/null 2>&1') and 'xsel -n -b -i' or 'wl-copy -f'

local get_scintilla_clipboard = ui.get_clipboard_text
-- Documentation is in core/ui.lua.
function ui.get_clipboard_text(internal)
	if internal then return get_scintilla_clipboard() end
	local proc = os.spawn(M.paste_command)
	local text = proc and proc:read('a') or get_scintilla_clipboard()
	if proc and OS == 'windows' then text = text:gsub('\r?\n$', '') end -- powershell appends newline
	return text
end

-- LuaFormatter off
--- Map of function names to their original buffer functions that operate on the internal clipboard.
local orig = {'cut','copy','line_cut','line_copy','copy_range','copy_text','cut_allow_line','copy_allow_line'}
-- LuaFormatter on
for _, name in ipairs(orig) do orig[name] = buffer[name] end
local orig_paste = buffer.paste

-- Replaces buffer clipboard functions with functions that use the system clipboard.
local function enable_system_clipboard()
	for _, name in ipairs(orig) do
		buffer[name] = function(...)
			orig[name](...) -- copy to internal clipboard
			local proc = os.spawn(M.copy_command)
			if not proc then return end
			proc:write(ui.get_clipboard_text(true)) -- copy internal clipboard to system clipboard
			proc:close()
			if OS == 'windows' or OS == 'macos' then
				proc:wait()
			else
				-- For whatever reason, the clipboard copy processes do not die after closing stdin.
				timeout(1, proc.kill, proc)
			end
		end
	end

	buffer.paste = function()
		orig.copy_text(ui.get_clipboard_text()) -- copy system clipboard to internal clipboard
		orig_paste() -- paste from internal clipboard
	end
end
enable_system_clipboard() -- so menus and key bindings use the right functions
events.connect(events.BUFFER_NEW, enable_system_clipboard)

return M

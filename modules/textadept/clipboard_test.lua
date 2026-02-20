-- Copyright 2025-2026 Mitchell. See LICENSE.

local proc

--- Copies text to the system clipboard using `textadept.clipboard.copy_command`.
-- @param text String text to copy.
local function copy(text)
	proc = os.spawn(textadept.clipboard.copy_command)
	if not proc then return end
	proc:write(text)
	proc:close()
	if WIN32 or OSX then
		proc:wait()
		return
	end
	-- Outside a desktop environment, the clipboard copy process provides the clipboard
	-- itself and that process needs to be alive during the entire test.
	test.wait(function() return ui.get_clipboard_text() == text end)
end

teardown(function()
	if proc and not WIN32 and not OSX then proc:kill() end
	proc = nil
end)

test('ui.get_clipboard_text should use the system clipboard', function()
	local text = 'text' .. math.random()
	copy(text)

	test.assert_equal(ui.get_clipboard_text(), text)
end)
if not CURSES then skip('the GUI version uses the system clipboard') end
if BSD and os.getenv('CI') == 'true' then skip('X is not running on CI') end

test('ui.get_clipboard_text should fall back on using its own internal clipboard', function()
	copy('system' .. math.random())
	local _<close> = test.mock(textadept.clipboard, 'copy_command', 'does-not-exist')
	local text = 'internal' .. math.random()
	buffer:copy_text(text)

	test.assert_equal(ui.get_clipboard_text(true), text)
end)
if not CURSES then skip('the GUI version uses the system clipboard') end

test('buffer.copy_text should use the system clipboard', function()
	local text = 'text' .. math.random()
	buffer:copy_text(text)

	test.assert_equal(ui.get_clipboard_text(), text)
end)
if not CURSES then skip('the GUI version uses the system clipboard') end
if BSD and os.getenv('CI') == 'true' then skip('X is not running on CI') end

test('buffer.paste should use the system clipboard', function()
	local text = 'text' .. math.random()
	copy(text)

	buffer:paste()

	test.assert_equal(buffer:get_text(), text)
end)
if not CURSES then skip('the GUI version uses the system clipboard') end
if BSD and os.getenv('CI') == 'true' then skip('X is not running on CI') end

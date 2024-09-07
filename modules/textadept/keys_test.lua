-- Copyright 2020-2024 Mitchell. See LICENSE.

test('shift+\\n should start a new line below the current one', function()
	buffer:append_text('1')

	test.type('shift+\n')

	test.assert_equal(buffer:get_text(), test.lines{'1', ''})
	test.assert_equal(buffer:line_from_position(buffer.current_pos), 2)
end)
if CURSES then skip('shift+\\n is not defined') end

test('ctrl+shift+\\n should start a new line above the current one', function()
	local start_new_line = keys['shift+\n']
	local start_new_line_above = function() start_new_line(true) end
	local _<close> = test.mock(keys, 'ctrl+shift+\n', start_new_line_above)

	buffer:append_text('2')
	test.type('ctrl+shift+\n')

	test.assert_equal(buffer:get_text(), test.lines{'', '2'})
	test.assert_equal(buffer.current_pos, 1)
end)
if CURSES then skip('ctrl+shift+\\n is not defined') end

-- TODO: test('ctrl+pgup/pgdn should scroll without moving the caret')

test('ctrl+k should cut to EOL with empty selection', function()
	local text = 'text'
	buffer:append_text(' ' .. text)
	buffer:char_right()

	test.type('ctrl+k')

	test.assert_equal(buffer:get_text(), ' ')
	test.assert_equal(ui.clipboard_text, text)
end)
if not OSX or CURSES then skip('ctrl+k is not defined') end

test('ctrl+k at EOL should delete EOL', function()
	buffer:append_text(test.lines(2, true))

	test.type('ctrl+k')

	test.assert_equal(buffer.line_count, 1)
end)
if not OSX or CURSES then skip('ctrl+k is not defined') end

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

-- TODO: test('ctrl+k on macOS should cut to EOL', function() end)

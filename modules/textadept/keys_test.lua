-- Copyright 2020-2025 Mitchell. See LICENSE.

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

test('alt+pgup should line scroll up without moving the caret', function()
	buffer:append_text(test.lines(50))
	buffer:document_end()
	local top_line = view.first_visible_line

	test.type(not OSX and 'alt+pgup' or 'ctrl+pgup')

	test.assert(view.first_visible_line < top_line, 'view was not scrolled up')
	test.assert_equal(buffer.current_pos, buffer.length + 1)
end)
skip('this test randomly fails') -- TODO: no amount of ui.update() is good enough
if CURSES then skip('alt+pgup is not defined') end

test('alt+pgdn should line scroll down without moving the caret', function()
	buffer:append_text(test.lines(50))

	test.type(not OSX and 'alt+pgdn' or 'ctrl+pgdn')

	test.assert(view.first_visible_line > 0, 'view was not scrolled down')
	test.assert_equal(buffer.current_pos, 1)
end)
if CURSES then skip('alt+pgdn is not defined') end

test('ctrl+k should cut to EOL with empty selection', function()
	local text = 'text'
	buffer:append_text(' ' .. text)
	buffer:char_right()

	test.type('ctrl+k')

	test.assert_equal(buffer:get_text(), ' ')
	test.assert_equal(ui.get_clipboard_text(), text)
end)
if not OSX or CURSES then skip('ctrl+k is not defined') end

test('ctrl+k at EOL should delete EOL', function()
	buffer:append_text(test.lines(2, true))

	test.type('ctrl+k')

	test.assert_equal(buffer.line_count, 1)
end)
if not OSX or CURSES then skip('ctrl+k is not defined') end

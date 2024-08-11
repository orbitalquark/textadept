-- Copyright 2020-2024 Mitchell. See LICENSE.

setup(textadept.history.clear)

test('history.back should jump to the previous buffer after switching between buffers', function()
	buffer.new()

	textadept.history.back()

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test('history.back should jump to the previous file after opening another one', function()
	local f<close> = test.tmpfile(true)
	local _<close> = test.tmpfile(true)

	textadept.history.back()

	test.assert_equal(buffer.filename, f.filename)
end)

test('history.back should jump back to the last edit position when far enough away', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1, true)
	local _<close> = test.tmpfile(contents, true)
	test.type(' ')
	local last_edit_pos = buffer.current_pos
	buffer:document_end()

	textadept.history.back()

	test.assert_equal(buffer.current_pos, last_edit_pos)
end)

test('history.back should jump back to the last main edit pos for multiple selections', function()
	local word = 'word'
	local lines = {word}
	for i = 1, textadept.history.minimum_line_distance do lines[#lines + 1] = '' end
	lines[#lines + 1] = word
	local _<close> = test.tmpfile(test.lines(lines), true)
	textadept.editing.select_word(true)
	test.type('\b')
	local last_edit_pos = buffer.current_pos -- at document end
	buffer:cancel()
	buffer:document_start()

	textadept.history.back()

	test.assert_equal(buffer.current_pos, last_edit_pos)
end)

test('history.back should not consider edits within history.minimum_line_distance as distinct',
	function()
		local contents = test.lines(1 + textadept.history.minimum_line_distance)
		local _<close> = test.tmpfile(contents, true)
		textadept.history.clear() -- start with a clean history
		test.type(' ')
		buffer:goto_line(1 + textadept.history.minimum_line_distance)
		test.type(' ')
		local last_edit_pos = buffer.current_pos
		buffer:document_start()

		textadept.history.back() -- should go back to last edit pos
		textadept.history.back() -- should not go back to first edit pos

		test.assert_equal(buffer.current_pos, last_edit_pos)
	end)

test('history.back should not be affected by reload, undo, or redo', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1)
	local _<close> = test.tmpfile(contents, true)
	test.type(' ')
	local last_edit_pos = buffer.current_pos
	buffer:reload() -- keeps caret at last_edit_pos, so reloaded line must not be empty
	buffer:undo()
	buffer:redo()
	buffer:document_end() -- go beyond minimum_line_distance

	textadept.history.back()

	test.assert_equal(buffer.current_pos, last_edit_pos)
end)

test('history.back should re-open a closed file', function()
	local f<close> = test.tmpfile(true)
	buffer:close()

	textadept.history.back()

	test.assert_equal(buffer.filename, f.filename)
end)

test('history.forward should return to the place before history.back', function()
	local f<close> = test.tmpfile(true)
	textadept.history.back()

	textadept.history.forward()

	test.assert_equal(buffer.filename, f.filename)
end)

test('history.forward should not return to a position without edits', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1)
	local _<close> = test.tmpfile(contents, true)
	test.type(' ')
	local last_edit_pos = buffer.current_pos
	buffer:document_end()
	textadept.history.back()

	textadept.history.forward() -- should not go to document end

	test.assert_equal(buffer.current_pos, last_edit_pos)
end)

test('history should be finite', function()
	local _<close> = test.mock(textadept.history, 'maximum_history_size', 0)
	buffer.new()
	local f<close> = test.tmpfile(true)

	textadept.history.back() -- no history to go back to

	test.assert_equal(buffer.filename, f.filename)
end)

test('history should be over-writeable', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1)
	local f<close> = test.tmpfile(contents, true)
	test.type(' ')
	local _<close> = test.tmpfile(true)
	textadept.history.back()
	buffer:document_end()
	test.type(' ') -- should overwrite forward history

	textadept.history.forward() -- should remain in first file

	test.assert_equal(buffer.filename, f.filename)
end)

test('history should be per-view', function()
	local f1<close> = test.tmpfile(true)
	local f2<close> = test.tmpfile(true)
	local view1, view2 = view:split()
	textadept.history.back() -- no history
	local should_be_f2 = buffer.filename
	local _<close> = test.tmpfile(true)

	textadept.history.back()

	ui.goto_view(view1)
	textadept.history.back()

	test.assert_equal(should_be_f2, f2.filename)
	test.assert_equal(view1.buffer.filename, f1.filename)
	test.assert_equal(view2.buffer.filename, f2.filename)
end)

test('history.back/forward should update soft records', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1)
	local f1<close> = test.tmpfile(contents, true)
	local f2<close> = test.tmpfile(contents, true)

	textadept.history.back()
	buffer:document_end()
	textadept.history.forward() -- should update soft record in f1
	buffer:document_end()

	textadept.history.back() -- should update soft record in f2
	local f1_pos = buffer.current_pos
	textadept.history.forward()
	local f2_pos = buffer.current_pos

	test.assert_equal(buffer.filename, f2.filename)
	test.assert_equal(f1_pos, _BUFFERS[1].length + 1)
	test.assert_equal(f2_pos, _BUFFERS[2].length + 1)
end)

test('edits should replace soft records', function()
	local contents = test.lines(1 + textadept.history.minimum_line_distance + 1)
	local f<close> = test.tmpfile(contents, true)
	local _<close> = test.tmpfile(true)
	textadept.history.back()
	buffer:document_end()

	test.type(' ') -- should update soft record
	local last_edit_pos = buffer.current_pos
	textadept.history.forward()
	textadept.history.back()

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer.current_pos, last_edit_pos)
end)

test('typed buffer edits should always be soft records', function()
	local f<close> = test.tmpfile(true)
	local type = '[Typed Buffer]'
	local chunk = test.lines(1 + textadept.history.minimum_line_distance + 1)
	ui.print_to(type)
	view:goto_buffer(-1)
	ui.print_to(type, chunk)
	ui.print_to(type, chunk) -- should not create separate record

	textadept.history.back()

	test.assert_equal(buffer.filename, f.filename)
end)

test('history.clear should clear history', function()
	buffer.new()

	textadept.history.clear()
	textadept.history.back()

	test.assert_equal(_BUFFERS[buffer], 2)
end)

-- Copyright 2020-2024 Mitchell. See LICENSE.

test('history.back should jump to the previous buffer after switching between buffers', function()
	textadept.history.clear()
	buffer.new()

	textadept.history.back()

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test('history.back should jump to the previous file after opening another one', function()
	local filename1, _<close> = test.tempfile()
	local filename2, _<close> = test.tempfile()
	io.open_file(filename1)
	io.open_file(filename2)

	textadept.history.back()

	test.assert_equal(buffer.filename, filename1)
end)

test('history.back should do nothing without more history', function()
	textadept.history.clear()
	buffer.new()
	textadept.history.back()

	textadept.history.back()

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test('history.back should navigate back to the last edit position when far enough away', function()
	buffer:append_text(test.lines(textadept.history.minimum_line_distance))
	test.type(' ')
	local pos = buffer.current_pos
	buffer:document_end()

	textadept.history.back()

	test.assert_equal(buffer.current_pos, pos)
end)

test('history.back should navigate back to the last main edit position for multiple selections',
	function()
		buffer:append_text('word')
		buffer:append_text(test.lines(textadept.history.minimum_line_distance + 1))
		buffer:append_text('word')
		textadept.editing.select_word(true)
		buffer.main_selection = 1 -- make the first selection the main one
		test.type('\b')
		buffer:cancel()
		buffer:document_end()

		textadept.history.back()

		test.assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	end)

test('history.back should not consider edits within history.minimum_line_distance as distinct',
	function()
		buffer:append_text(test.lines(textadept.history.minimum_line_distance * 2))
		test.type(' ')
		buffer:goto_line(textadept.history.minimum_line_distance)
		test.type(' ')
		local last_edit_pos = buffer.current_pos
		buffer:document_end()

		textadept.history.back()
		local still_last_edit_pos = buffer.current_pos
		textadept.history.back()

		test.assert_equal(buffer.current_pos, last_edit_pos)
		test.assert_equal(still_last_edit_pos, last_edit_pos)
	end)

test('history.back should not be affected by reload, undo, or redo', function()
	local contents = string.rep('\n', textadept.history.minimum_line_distance * 2)
	local filename, _<close> = test.tempfile(contents)
	io.open_file(filename)
	buffer:line_down()
	local pos = buffer.current_pos
	test.type(' ')
	buffer:reload()
	buffer:undo()
	buffer:redo()
	buffer:document_end() -- go beyond minimum_line_distance

	textadept.history.back()

	test.assert_equal(buffer.current_pos, pos)
end)

test('history.back should re-open a closed file', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:close()

	textadept.history.back()

	test.assert_equal(buffer.filename, filename)
end)

test('history.forward should return to the place before history.back', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	textadept.history.back()

	textadept.history.forward()

	test.assert_equal(buffer.filename, filename)
end)

test('history.forward should do nothing without more history', function()
	buffer.new()
	textadept.history.forward()

	textadept.history.forward()

	test.assert_equal(_BUFFERS[buffer], 2)
end)

test('history.forward should not return to a position without edits', function()
	buffer:append_text(test.lines(textadept.history.minimum_line_distance + 1))
	test.type(' ')
	local pos = buffer.current_pos
	buffer:document_end()
	textadept.history.back()

	textadept.history.forward() -- should not go to document end

	test.assert_equal(buffer.current_pos, pos)
end)

test('history should be finite', function()
	textadept.history.clear()
	local _<close> = test.mock(textadept.history, 'maximum_history_size', 0)
	local filename, _<close> = test.tempfile()
	buffer.new()
	io.open_file(filename)

	textadept.history.back() -- no history to go back to

	test.assert_equal(buffer.filename, filename)
end)

test('history should be over-writeable', function()
	buffer:append_text(test.lines(10))
	local filename, _<close> = test.tempfile()
	test.type(' ')
	io.open_file(filename)
	textadept.history.back()
	buffer:document_end()
	test.type(' ') -- should overwrite forward history

	textadept.history.forward()

	test.assert(buffer.filename ~= filename, 'should not have switched back to file')
end)

test('history should be per-view', function()
	local filename1, _<close> = test.tempfile()
	local filename2, _<close> = test.tempfile()
	local filename3, _<close> = test.tempfile()
	io.open_file(filename1)
	io.open_file(filename2)
	local view1, view2 = view:split()
	textadept.history.back() -- no history
	local should_be_filename2 = buffer.filename
	io.open_file(filename3)

	textadept.history.back()

	ui.goto_view(view1)
	textadept.history.back()

	test.assert_equal(should_be_filename2, filename2)
	test.assert_equal(view1.buffer.filename, filename1)
	test.assert_equal(view2.buffer.filename, filename2)
end)

test('history.record should raise errors for invalid arguments', function()
	local invalid_filename = function() textadept.history.record({}) end
	local invalid_line = function() textadept.history.record(nil, true) end
	local invalid_column = function() textadept.history.record(nil, 1, false) end

	test.assert_raises(invalid_filename, 'string/nil expected')
	test.assert_raises(invalid_line, 'number/nil expected')
	test.assert_raises(invalid_column, 'number/nil expected')
end)

test('history.back/forward should update soft records', function()
	local contents = string.rep('\n', textadept.history.minimum_line_distance * 2)
	local filename1, _<close> = test.tempfile(contents)
	local filename2, _<close> = test.tempfile(contents)

	io.open_file(filename1)
	io.open_file(filename2)

	textadept.history.back()
	buffer:document_end()
	textadept.history.forward() -- should update soft record in filename1
	buffer:document_end()

	textadept.history.back() -- should update soft record in filename2
	local filename1_pos = buffer.current_pos
	textadept.history.forward()
	local filename2_pos = buffer.current_pos

	test.assert_equal(buffer.filename, filename2)
	test.assert_equal(filename1_pos, _BUFFERS[1].length + 1)
	test.assert_equal(filename2_pos, _BUFFERS[2].length + 1)
end)

test('edits should replace soft records', function()
	local contents = string.rep('\n', textadept.history.minimum_line_distance)
	local filename1, _<close> = test.tempfile(contents)
	local filename2, _<close> = test.tempfile()
	io.open_file(filename1)
	io.open_file(filename2)
	textadept.history.back()
	buffer:document_end()

	test.type(' ') -- should update soft record
	textadept.history.forward()
	textadept.history.back()

	test.assert_equal(buffer.filename, filename1)
	test.assert_equal(buffer.current_pos, buffer.length + 1)
end)

test('history.clear should clear history', function()
	buffer.new()

	textadept.history.clear()
	textadept.history.back()

	test.assert_equal(_BUFFERS[buffer], 2)
end)

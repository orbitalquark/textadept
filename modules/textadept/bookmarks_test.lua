-- Copyright 2020-2024 Mitchell. See LICENSE.

local function has_bookmark(line)
	return buffer:marker_get(line) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
end

test('bookmarks.toggle should bookmark the current line', function()
	textadept.bookmarks.toggle()

	test.assert_equal(has_bookmark(1), true)
end)

test("bookmarks.toggle should remove a line's existing bookmark", function()
	textadept.bookmarks.toggle()

	textadept.bookmarks.toggle()

	test.assert_equal(has_bookmark(1), false)
end)

test('bookmarks.clear should remove all buffer bookmarks', function()
	-- Note: toggling a bookmark and then typing Enter will move the bookmark down.
	test.type('\n')
	textadept.bookmarks.toggle()
	buffer:line_up()
	textadept.bookmarks.toggle()

	textadept.bookmarks.clear()

	test.assert_equal(has_bookmark(1), false)
	test.assert_equal(has_bookmark(2), false)
end)

test('bookmarks.goto_mark should prompt for a bookmark to go to', function()
	buffer:new_line()
	textadept.bookmarks.toggle()
	buffer:line_up()

	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	textadept.bookmarks.goto_mark()
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 2)
end)

test('bookmarks.goto_mark should be able to go to the next bookmark', function()
	test.type('\n')
	textadept.bookmarks.toggle()
	buffer:line_up()

	textadept.bookmarks.goto_mark(true)
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 2)
end)

test('bookmarks.goto_mark should be able to go to the next (wrapped) bookmark', function()
	test.type('\n')
	buffer:line_up()
	textadept.bookmarks.toggle()
	buffer:line_down()

	textadept.bookmarks.goto_mark(true)
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 1)
end)

test('bookmarks.goto_mark should be able to go to the previous bookmark', function()
	test.type('\n')
	buffer:line_up()
	textadept.bookmarks.toggle()
	buffer:line_down()

	textadept.bookmarks.goto_mark(false)
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 1)
end)

test('bookmarks.goto_mark should be able to go to the previous (wrapped) bookmark', function()
	test.type('\n')
	textadept.bookmarks.toggle()
	buffer:line_up()

	textadept.bookmarks.goto_mark(false)
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 2)
end)

test('bookmarks.goto_mark prompt should include bookmarks from other buffers', function()
	local filename, _<close> = test.tempfile()
	io.open(filename, 'wb'):write(test.newline()):close()
	io.open_file(filename)
	buffer:goto_line(2)
	textadept.bookmarks.toggle()

	buffer.new()
	textadept.bookmarks.toggle()

	local select_second_item = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'list', select_second_item)

	textadept.bookmarks.goto_mark()
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(line, 2)
end)

test('bookmarks should restore upon file reload', function()
	local filename, _<close> = test.tempfile()
	io.open(filename, 'wb'):write(test.newline()):close()
	io.open_file(filename)
	buffer:goto_line(2)
	textadept.bookmarks.toggle()

	buffer:reload()

	test.assert_equal(has_bookmark(2), true)
end)

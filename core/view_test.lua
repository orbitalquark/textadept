-- Copyright 2020-2024 Mitchell. See LICENSE.

test('view.goto_buffer should switch to a given buffer', function()
	buffer.new()

	view:goto_buffer(_BUFFERS[1])

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test('view.goto_buffer should switch to a relative buffer with wrapping (left)', function()
	buffer.new()
	buffer.new()
	view:goto_buffer(_BUFFERS[1])

	view:goto_buffer(-1)

	test.assert_equal(_BUFFERS[buffer], 3)
end)

test('view.goto_buffer should switch to a relative buffer with wrapping (right)', function()
	buffer.new()
	buffer.new()

	view:goto_buffer(2)

	test.assert_equal(_BUFFERS[buffer], 2)
end)

test('view.goto_buffer should switch to a large relative buffer with wrapping (left)', function()
	buffer.new()
	buffer.new()

	view:goto_buffer(-4)

	test.assert_equal(_BUFFERS[buffer], 2)
end)
expected_failure() -- TODO:

test('view.goto_buffer should switch to a large relative buffer with wrapping (right)', function()
	buffer.new()
	buffer.new()
	view:goto_buffer(_BUFFERS[1])

	view:goto_buffer(4)

	test.assert_equal(_BUFFERS[buffer], 2)
end)

test('view.split should split the current view in two', function()
	local old, new = view:split()

	test.assert_equal(#_VIEWS, 2)
	test.assert_equal(_VIEWS[old], 1)
	test.assert_equal(_VIEWS[new], 2)
end)

test('view.split should preserve buffer state', function()
	buffer:append_text(test.lines(100))
	buffer:set_sel(buffer:position_from_line(50), buffer.line_end_position[50])
	local selected_text = buffer:get_sel_text()
	local first_line = view.first_visible_line
	local x_offset = 10
	view.x_offset = x_offset

	view:split()

	test.assert_equal(buffer:get_sel_text(), selected_text)
	if QT then ui.update() end
	test.assert_equal(view.first_visible_line, first_line)
	test.assert_equal(view.x_offset, x_offset)
end)

test('view.unsplit should remove the other view', function()
	view:split()
	buffer.new()

	view:unsplit()

	test.assert_equal(#_VIEWS, 1)
	test.assert_equal(_BUFFERS[buffer], 2)
end)

test('view.unsplit should remove the other views', function()
	view:split()
	view:split(true)
	ui.goto_view(_VIEWS[1])

	view:unsplit()

	test.assert_equal(#_VIEWS, 1)
end)

test('switching between views should toggle view.caret_line_visible_always', function()
	local _<close> = test.mock(view, 'caret_line_visible_always', true)

	local old_view, new_view = view:split()
	local should_be_false = old_view.caret_line_visible_always
	local _<close> = test.mock(view, 'caret_line_visible_always', true)
	ui.goto_view(-1)

	test.assert_equal(should_be_false, false)
	test.assert_equal(old_view.caret_line_visible_always, true)
	test.assert_equal(new_view.caret_line_visible_always, false)
end)

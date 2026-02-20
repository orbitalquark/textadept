-- Copyright 2020-2026 Mitchell. See LICENSE.

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

test('view.split should split the current view into roughly equal halves', function()
	view:split(true)
	view:split()

	test.wait(function()
		local size = ui.get_split_table().size
		local half_width, split_pos = size[1] / 2, size[3]
		return math.abs(half_width - split_pos) / half_width < 0.1
	end)
	local size = ui.get_split_table()[2].size
	local half_height, split_pos = size[2] / 2, size[3]
	test.assert(math.abs(half_height - split_pos) / half_height <= 0.1, 'split sizes are unequal')
end)
if GTK then
	local gtk2 = os.getenv('CI') == 'true' and io.popen('dpkg --list'):read('a'):find('gtk2%.0%-dev')
	if not gtk2 then expected_failure() end -- TODO: second size[3] == 0
end

test('view.split should preserve buffer state', function()
	buffer:append_text(test.lines(100))
	buffer:set_sel(buffer:position_from_line(50), buffer.line_end_position[50])
	local selected_text = buffer:get_sel_text()
	local first_line = view.first_visible_line
	local x_offset = 10
	view.x_offset = x_offset

	view:split(true) -- vertical split preserves scroll position

	test.assert_equal(buffer:get_sel_text(), selected_text)
	if QT then ui.update() end
	test.assert_equal(view.first_visible_line, first_line)
	test.assert_equal(view.x_offset, x_offset)
end)
if GTK then retry(1) end -- GTK 2

test('view.split should ensure the caret remains visible', function()
	buffer:append_text(test.lines(100))
	buffer:set_sel(buffer:position_from_line(50), buffer.line_end_position[50])

	view:split() -- horizontal split should scroll caret into view as necessary

	if QT then ui.update() end
	local top_line = view.first_visible_line
	local bottom_line = top_line + view.lines_on_screen
	local line = buffer:line_from_position(buffer.current_pos)
	test.assert(line >= top_line and line <= bottom_line, 'caret was not scrolled into view')
end)

-- Note: view.split_pos is tested in modules/textadept/menu_test.lua.
test('view.parent_split_pos should give access to parent split size', function()
	view:split(true)
	view:split()

	test.assert(view.parent_split_pos, 'view.parent_split_pos is nil')
end)

test('view.parent_split_pos should be mutable', function()
	view:split(true)
	view:split()
	local size, offset = view.parent_split_pos, 10

	view.parent_split_pos = view.parent_split_pos + offset

	test.assert_equal(view.parent_split_pos, size + offset)
end)

test('view.parent_split_pos should be nil otherwise', function()
	view:split()

	test.assert_equal(view.parent_split_pos, nil)
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

test('events.MODE_CHANGED should trigger view.set_theme', function()
	local set_theme = test.stub()
	local _<close> = test.mock(view, 'set_theme', set_theme)

	events.emit(events.MODE_CHANGED) -- simulate OS-generated event

	test.assert_equal(set_theme.called, true)
end)
if CURSES then skip('the terminal version does not emit this event') end

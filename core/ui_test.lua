-- Copyright 2020-2024 Mitchell. See LICENSE.

test('ui.print_to should raise errors for invalid arguments', function()
	local not_a_string = function() ui.print_to(1) end

	test.assert_raises(not_a_string, 'string expected')
end)

test('ui.print_to should print to a typed buffer', function()
	local _<close> = test.mock(ui, 'tabs', true)
	local type = '[Typed Buffer]'
	local output = 'output'

	local buf = ui.print_to(type, output)

	test.assert_equal(#_BUFFERS, 2)
	test.assert_equal(#_VIEWS, 1)
	test.assert(buf == buffer, 'should have returned print buffer')
	test.assert_equal(buffer._type, type)
	test.assert_equal(buffer:get_text(), output .. test.newline())
	test.assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	test.assert_equal(buffer.modify, false)
end)

test('ui.print_to should print multiple values separated by tabs', function()
	local _<close> = test.mock(ui, 'tabs', true)
	local type = '[Typed Buffer]'
	local output = {1, 2}
	local text_output = table.concat(output, '\t')

	ui.print_to(type, table.unpack(output))

	test.assert_equal(buffer:get_text(), text_output .. test.newline())
end)

test('ui.print_to should switch to the print buffer', function()
	local _<close> = test.mock(ui, 'tabs', true)
	local type = '[Typed Buffer]'
	ui.print_to(type)
	view:goto_buffer(-1)

	ui.print_to(type)

	test.assert_equal(buffer._type, type)
end)

test('ui.print_to should print to a typed buffer in another view if ui.tabs is disabled', function()
	local _<close> = test.mock(ui, 'tabs', false)
	local type = '[Typed Buffer]'

	ui.print_to(type)

	test.assert_equal(#_BUFFERS, 2)
	test.assert_equal(#_VIEWS, 2)
	test.assert_equal(buffer._type, type)
	test.assert_equal(_VIEWS[view], 2)
	test.assert(_VIEWS[1].buffer == _BUFFERS[1], 'should not have switched buffers')
end)

test('ui.print_to should switch to the print buffer, but in another view if ui.tabs is disabled',
	function()
		local _<close> = test.mock(ui, 'tabs', false)
		local type = '[Typed Buffer]'
		ui.print_to(type)
		ui.goto_view(-1)

		ui.print_to(type)

		test.assert_equal(_VIEWS[view], 2)
	end)

test('ui.print_to should print to another split view if it is showing the print buffer', function()
	local type = '[Typed Buffer]'
	view:split()

	ui.print_to(type)

	test.assert_equal(#_VIEWS, 2)
	test.assert_equal(_VIEWS[view], 1)
end)

test('ui.print_silent_to should print to a buffer without switching to it', function()
	local _<close> = test.mock(ui, 'tabs', true)
	local type = '[Typed Buffer]'
	local silent_output = 'silent'

	local buf = ui.print_silent_to(type, silent_output)

	test.assert(buffer ~= buf, 'should not have switched buffers')
	test.assert_equal(buf:get_text(), silent_output .. test.newline())
end)

test('ui.print_silent_to should not split the view if ui.tabs is disabled', function()
	local _<close> = test.mock(ui, 'tabs', false)
	local type = '[Typed Buffer]'

	ui.print_silent_to(type)

	test.assert_equal(#_VIEWS, 1)
end)

test('ui.print_silent_to should scroll any views showing the print buffer', function()
	local type = '[Typed Buffer]'
	view:split()
	ui.print_to(type)
	ui.goto_view(1)

	ui.print_silent_to(type, string.rep(test.newline(), 100))

	if GTK then ui.update() end
	test.assert(_VIEWS[1].first_visible_line > 1, 'should have scrolled view')
	-- TODO: on QT, ui.goto_view(1) is needed to avoid crash during ui.switch_buffer tests
end)

test('ui.print should print to the message buffer', function()
	local message = 'message'

	ui.print(message)

	test.assert_equal(buffer._type, _L['[Message Buffer]'])
	test.assert_equal(buffer:get_text(), message .. test.newline())
end)

test('ui.print_silent should silently print to the message buffer', function()
	local buf = ui.print_silent()

	test.assert_equal(buf._type, _L['[Message Buffer]'])
end)

test('ui.output should print to the output buffer', function()
	ui.output()

	test.assert_equal(buffer._type, _L['[Output Buffer]'])
	test.assert_equal(buffer.lexer_language, 'output')
	test.assert_equal(buffer.length, 0) -- no trailing newline
end)

test('ui.output should not print tabs between values', function()
	local output = {1, 2, 3}
	local text_output = table.concat(output)

	ui.output(table.unpack(output))

	test.assert_equal(buffer:get_text(), text_output)
end)

test('ui.output should highlight recognized error messages', function()
	local output = 'file.lua:1: error'
	local file_pos = 1
	local line_pos = output:find('%d')
	local message_pos = output:find(': ') + 2

	ui.output(output, test.newline())
	local style_at_file_pos = buffer:name_of_style(buffer.style_at[file_pos])
	local style_at_line_pos = buffer:name_of_style(buffer.style_at[line_pos])
	local style_at_message_pos = buffer:name_of_style(buffer.style_at[message_pos])

	test.assert_equal(style_at_file_pos, 'filename')
	test.assert_equal(style_at_line_pos, 'line')
	test.assert_equal(style_at_message_pos, 'message')
end)

test('ui.output_silent should silently print to the output buffer', function()
	local buf = ui.output_silent()

	test.assert_equal(buf._type, _L['[Output Buffer]'])
end)

test('ui.switch_buffer should prompt to switch between buffers', function()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	buffer.new()

	ui.switch_buffer()

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test('ui.switch_buffer should prompt to switch between recent buffers', function()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	buffer.new()
	buffer.new()

	ui.switch_buffer()

	test.assert_equal(_BUFFERS[buffer], 2)
end)

test('ui.switch_buffer should prompt with relative paths of buffers in the current project',
	function()
		local dir, _<close> = test.tempdir{['.hg'] = {}, 'file1.txt', 'file2.txt'}
		local filename, _<close> = test.tempfile()
		io.open_file(dir .. '/file1.txt')
		io.open_file(dir .. '/file2.txt')
		io.open_file(filename) -- absolute path

		-- TODO: how to actually test this?
		local select_first_item = test.stub(1)
		local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

		ui.switch_buffer() -- back to init.lua
		ui.switch_buffer() -- back to temp file
	end)

-- Note: reset() causes the same trouble described in *init_test.lua*.
test('ui.switch_buffer should persist recent buffers over reset #skip', function()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	buffer.new()
	buffer.new()

	ui.switch_buffer()
	reset()
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	ui.switch_buffer()

	test.assert_equal(_BUFFERS[buffer], 3)
end)

test('ui.goto_file should raise errors for invalid arguments', function()
	local invalid_filename = function() ui.goto_file(1) end

	test.assert_raises(invalid_filename, 'string expected')
end)

test('ui.goto_file should open a file in the current view', function()
	local filename, _<close> = test.tempfile()

	ui.goto_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(#_VIEWS, 1)
end)

test('ui.goto_file should switch to an already opened file in the same view', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer.new()

	ui.goto_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(#_VIEWS, 1)
	test.assert_equal(#_BUFFERS, 2)
end)

test('ui.goto_file should match filenames case-insensitively on WIN32', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer.new()
	local _<close> = test.mock(_G, 'WIN32', true)

	ui.goto_file(filename:upper())

	test.assert_equal(buffer.filename, filename)
end)

test('ui.goto_file should optionally open a file in a split view', function()
	local filename, _<close> = test.tempfile()
	buffer.new()

	ui.goto_file(filename, true)

	test.assert_equal(#_VIEWS, 2)
	test.assert_equal(buffer.filename, filename)
	test.assert(_VIEWS[1].buffer ~= buffer, 'should not have switched buffers')
end)

test('ui.goto_file should go to the view showing the file', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	view:split()
	buffer.new()

	ui.goto_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(_VIEWS[view], 1)
end)

test(
	'ui.goto_file should switch to an already opened file with the same basename, and in the same view',
	function()
		local filename, _<close> = test.tempfile()
		local dir, name = filename:match('^(.+[/\\])([^/\\]+)')
		io.open_file(filename)
		buffer.new()

		ui.goto_file(dir .. '/does-not-exist/' .. name, false, nil, true)

		test.assert_equal(buffer.filename, filename)
		test.assert_equal(#_VIEWS, 1)
		test.assert_equal(#_BUFFERS, 2)
	end)

test(
	'ui.goto_file should switch to an already opened file with the same basename, but optionally in a split view',
	function()
		local filename, _<close> = test.tempfile()
		local dir, name = filename:match('^(.+[/\\])([^/\\]+)$')
		io.open_file(filename)
		buffer.new()
		view:split()

		ui.goto_file(dir .. '/does-not-exist/' .. name, true, nil, true)

		test.assert_equal(buffer.filename, filename)
		test.assert_equal(_VIEWS[view], 1)
	end)

test('ui.goto_file should switch to an already opened file, and in a preferred split view',
	function()
		local filename, _<close> = test.tempfile()
		io.open_file(filename)
		buffer.new()
		view:split()
		view:split()

		ui.goto_file(filename, false, _VIEWS[2])

		test.assert_equal(buffer.filename, filename)
		test.assert_equal(_VIEWS[view], 2)
	end)

test("clicking a buffer's tab should switch to that buffer", function()
	buffer.new()

	events.emit(events.TAB_CLICKED, 1) -- simulate

	test.assert_equal(_BUFFERS[buffer], 1)
end)

test("clicking a buffer's tab close button should close that buffer", function()
	buffer.new()
	buffer:append_text('modified')

	events.emit(events.TAB_CLOSE_CLICKED, 1) -- simulate

	test.assert_equal(#_BUFFERS, 1)
	test.assert_equal(buffer.modify, true)
end)

test('dropping a file URI should open it', function()
	local contents = 'dropped'
	local dir, _<close> = test.tempdir{['dropped file.txt'] = contents}
	local uri = 'file://' .. dir:gsub('\\', '/') .. '/dropped%20file.txt'

	events.emit(events.URI_DROPPED, uri) -- simulate

	test.assert_equal(buffer:get_text(), contents)
end)

test('dropping a directory URI should do nothing', function()
	local dir, _<close> = test.tempdir{'file.txt'}

	events.emit(events.URI_DROPPED, 'file://' .. dir:gsub('\\', '/'))

	test.assert_equal(#_BUFFERS, 1)
end)

-- TODO: OSX APPLEEVENT_ODOC

test('switching between buffers should save/restore buffer state', function()
	for i = 1, 100 do buffer:append_text(i .. test.newline()) end
	buffer:set_sel(buffer:position_from_line(50), buffer.line_end_position[50])
	local selected_text = buffer:get_sel_text()
	local first_line = view.first_visible_line
	local x_offset = 10
	view.x_offset = x_offset

	buffer.new():close()

	test.assert_equal(buffer:get_sel_text(), selected_text)
	test.assert_equal(view.first_visible_line, first_line)
	test.assert_equal(view.x_offset, x_offset)
end)

test('switching between buffers should save/restore fold state', function()
	buffer:set_text(test.lines{'if true then', '\tprint()', 'end'})
	buffer:set_lexer('lua')
	view:fold_line(1, view.FOLDACTION_CONTRACT)

	buffer.new():close()

	test.assert_equal(view.fold_expanded[1], false)
end)

test('reloading a buffer should restore its state', function()
	local filename, _<close> = test.tempfile()
	io.open(filename, 'wb'):write('123456'):close()
	io.open_file(filename)
	buffer:set_sel(4, 7)
	local selected_text = buffer:get_sel_text()
	io.open(filename, 'wb'):write('123456789'):close()

	buffer:reload()

	test.assert_equal(buffer:get_sel_text(), selected_text)
end)

test('quitting should be unimpeded by unmodified buffers', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	local halt = events.emit(events.QUIT) -- simulate

	test.assert_equal(not halt, true)
end)

test('quitting with modified buffers should prompt for save', function()
	buffer:append_text('modified')
	local is_confirm_quit = function(opts) return opts.title == _L['Quit without saving?'] end
	local cancel_quit = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'message', is_confirm_quit, cancel_quit)

	local cancelled = events.emit(events.QUIT) -- simulate

	test.assert_equal(cancelled, true)
end)

test('quitting should be unimpeded by modified, typed buffers', function()
	ui.print_silent():append_text('modified')

	local halt = events.emit(events.QUIT) -- simulate

	test.assert_equal(not halt, true)
end)

test('closing a buffer should switch back to the previously shown one', function()
	buffer:append_text('1')
	buffer.new():append_text('2')
	buffer.new():append_text('3')
	view:goto_buffer(_BUFFERS[1])

	buffer:close(true) -- should switch back to 3

	test.assert_equal(buffer:get_text(), '3')
end)

if CURSES then
	test('clicking in a view should focus it', function()
		view:split(true)

		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, 2, 2)
		local should_be_left_view = _VIEWS[view]

		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, 2, ui.size[1] - 2)
		local should_be_right_view = _VIEWS[view]

		test.assert_equal(should_be_left_view, 1)
		test.assert_equal(should_be_right_view, 2)
	end)

	test('clicking and dragging on a splitter bar should resize split view', function()
		view:split(true)
		view:split()
		_VIEWS[1].size = 1

		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, 2, 1)
		events.emit(events.MOUSE, view.MOUSE_DRAG, 1, 0, 2, 2)

		test.assert_equal(_VIEWS[1].size, 2)
	end)
end

test("ui.maximized should report the window's maximized state", function()
	local maximized = ui.maximized

	test.assert_equal(maximized, false)
end)

test("ui.maximized = true should change the window's maximized state", function()
	if CURSES then return end -- not applicable
	local _<close> = test.mock(ui, 'maximized', true)

	-- For some reason, the following fails, even though the window maximized status is toggled.
	-- `ui.update()` does not seem to help.
	test.assert_equal(ui.maximized, true)
end)
if LINUX and GTK then expected_failure() end

test("ui.size should report the window's size", function()
	local width, height = ui.size[1], ui.size[2]

	test.assert(width > 0, 'width should be non-zero')
	test.assert(height > 0, 'height should be non-zero')
end)

test('ui.size = {width, height} should resize the window', function()
	if CURSES then return end -- not applicable
	local new_size = {ui.size[1] - 50, ui.size[2] + 50}

	local _<close> = test.mock(ui, 'size', new_size)

	-- For some reason, reading ui.size fails, even though the window has been resized.
	-- `ui.update()` does not seem to help.
	test.assert_equal(ui.size, new_size)
end)
if LINUX and GTK then expected_failure() end

test('ui.get_split_table should report the current split view state', function()
	view:split(true)
	view:split()

	local splits = ui.get_split_table()

	test.assert_equal(splits.vertical, true)
	test.assert(splits.size > 0, 'should be a non-zero size')
	test.assert_equal(_VIEWS[1], splits[1])
	test.assert_equal(splits[2].vertical, false)
	test.assert(splits[2].size > 0, 'should be a non-zero size')
	test.assert_equal(_VIEWS[2], splits[2][1])
	test.assert_equal(_VIEWS[3], splits[2][2])
end)
if GTK then expected_failure() end -- TODO: splits[2].size == 0

test('ui.goto_view should raise errors for invalid arguments', function()
	local not_a_view = function() ui.goto_view(buffer) end

	test.assert_raises(not_a_view, 'View expected')
end)

test('ui.goto_view should focus a given view', function()
	view:split()

	ui.goto_view(_VIEWS[1])

	test.assert_equal(_VIEWS[view], 1)
end)

test('ui.goto_view should focus a relative view with wrapping (left)', function()
	view:split()
	view:split()
	ui.goto_view(_VIEWS[1])

	ui.goto_view(-1)

	test.assert_equal(_VIEWS[view], 3)
end)

test('ui.goto_view should focus a relative view with wrapping (right)', function()
	view:split()
	view:split()

	ui.goto_view(2)

	test.assert_equal(_VIEWS[view], 2)
end)

test('ui.goto_view should focus a large relative view with wrapping (left)', function()
	view:split()
	view:split()

	ui.goto_view(-4)

	test.assert_equal(_VIEWS[view], 2)
end)
expected_failure()

test('ui.goto_view should focus a large relative view with wrapping (right)', function()
	view:split()
	view:split()
	ui.goto_view(_VIEWS[1])

	ui.goto_view(4)

	test.assert_equal(_VIEWS[view], 2)
end)

-- Copyright 2020-2024 Mitchell. See LICENSE.

test('buffer:text_range should raise errors for invalid arguments', function()
	local no_args = function() buffer:text_range() end
	local no_second_arg = function() buffer:text_range(5) end

	test.assert_raises(no_args, 'number expected')
	test.assert_raises(no_second_arg, 'number expected')
end)

test("buffer:text_range should implement Scintilla's SCI_GETTEXTRANGE", function()
	local text = '123456789'
	buffer:append_text(text)

	local sub_range = buffer:text_range(4, 7)
	local full_range = buffer:text_range(1, buffer.length + 1)
	local clamp_start_range = buffer:text_range(-1, 4)
	local clamp_end_range = buffer:text_range(7, 11)

	test.assert_equal(sub_range, text:sub(4, 6))
	test.assert_equal(full_range, text)
	test.assert_equal(clamp_start_range, text:sub(1, 3))
	test.assert_equal(clamp_end_range, text:sub(7))
end)

test('buffer:text_range should not modify buffer.target_range', function()
	local text = '123456789'
	buffer:append_text(text)
	buffer:set_target_range(4, 7)

	buffer:text_range(1, 4) -- 123

	test.assert_equal(buffer.target_text, text:sub(4, 6))
end)

test('view.styles[k] = v should raise errors for invalid values', function()
	local not_a_style = 1
	local invalid_assignment = function() view.styles.name = not_a_style end

	test.assert_raises(invalid_assignment, 'table expected')
	-- TODO: error when setting existing style like view.styles.default = 1?
end)

test('view.styles[k] .. style should raise errors for invalid values', function()
	local style = view.styles[view.STYLE_DEFAULT]
	local not_a_style = 1
	local invalid_concat = function() view.styles.name = style .. not_a_style end

	test.assert_raises(invalid_concat, 'table expected')
end)

test('view:set_theme should set the theme for a view, leaving others alone', function()
	local lua_file, _<close> = test.tempfile('.lua')
	local c_file, _<close> = test.tempfile('.c')
	view:split()
	io.open_file(lua_file)
	view:split(true)
	io.open_file(c_file)

	_VIEWS[2]:set_theme('dark')
	_VIEWS[3]:set_theme('light')

	local view2_style = _VIEWS[2].style_fore[view.STYLE_DEFAULT]
	local view3_style = _VIEWS[3].style_fore[view.STYLE_DEFAULT]
	test.assert(view2_style ~= view3_style, 'views should have different styles')
end)

test('move_buffer should raise errors for invalid arguments', function()
	local invalid_from_index = function() move_buffer('') end
	local no_to_index = function() move_buffer(1) end
	local invalid_to_index = function() move_buffer(1, true) end
	local out_of_bounds_to_index = function() move_buffer(1, 10) end
	local negative_to_index = function() move_buffer(1, -1) end
	local out_of_bounds_from_index = function() move_buffer(10, 1) end
	local negative_from_index = function() move_buffer(-1, 1) end

	test.assert_raises(invalid_from_index, 'number expected')
	test.assert_raises(no_to_index, 'number expected')
	test.assert_raises(invalid_to_index, 'number expected')
	test.assert_raises(out_of_bounds_to_index, 'out of bounds')
	test.assert_raises(negative_to_index, 'out of bounds')
	test.assert_raises(out_of_bounds_from_index, 'out of bounds')
	test.assert_raises(negative_from_index, 'out of bounds')
end)

test('move_buffer should allow moving a buffer backwards', function()
	local buffer1 = buffer.new()
	buffer1:set_text('1')
	local buffer2 = buffer.new()
	buffer2:set_text('2')
	local buffer3 = buffer.new()
	buffer3:set_text('3')
	local buffer4 = buffer.new()
	buffer4:set_text('4')

	move_buffer(_BUFFERS[buffer4], _BUFFERS[buffer1])

	test.assert(_BUFFERS[buffer4] < _BUFFERS[buffer1], 'buffer4 should be before buffer1')
	test.assert(_BUFFERS[buffer1] < _BUFFERS[buffer2], 'buffer1 should be before buffer2')
	test.assert(_BUFFERS[buffer2] < _BUFFERS[buffer3], 'buffer2 should be before buffer3')
end)

test('move_buffer should allow moving a buffer forwards', function()
	local buffer1 = buffer.new()
	buffer1:set_text('1')
	local buffer2 = buffer.new()
	buffer2:set_text('2')
	local buffer3 = buffer.new()
	buffer3:set_text('3')
	local buffer4 = buffer.new()
	buffer4:set_text('4')

	move_buffer(_BUFFERS[buffer2], _BUFFERS[buffer3])

	test.assert(_BUFFERS[buffer1] < _BUFFERS[buffer3], 'buffer1 should be before buffer3')
	test.assert(_BUFFERS[buffer3] < _BUFFERS[buffer2], 'buffer3 should be before buffer2')
	test.assert(_BUFFERS[buffer2] < _BUFFERS[buffer4], 'buffer2 should be before buffer4')
end)

-- Note: testing reset creates extra temporary _USERHOMEs and discards the test runner's
-- events.QUIT handler.
test('reset should reset the Lua state #skip', function()
	_G.variable = ''

	reset()

	test.assert_equal(_G.variable, nil)
end)

-- Note: cannot test events.RESET_AFTER because there is no opportunity to connect to it
-- during reset.
test('reset should emit before events with a table to persist #skip', function()
	local before = test.stub()

	events.connect(events.RESET_BEFORE, before)
	reset()

	test.assert_equal(before.called, true)
	test.assert_equal(type(before.args[1]), 'table')
end)

test('timeout should raise errors for invalid arguments', function()
	local no_interval = function() timeout() end
	local invalid_interval = function() timeout(0) end
	local invalid_function = function() timeout(1, '') end

	test.assert_raises(no_interval, 'number expected')
	test.assert_raises(invalid_interval, 'interval must be > 0')
	test.assert_raises(invalid_function, 'function expected')
end)

test('timeout should repeatedly call a function as long as it returns true', function()
	local interval = 0.1
	local count, stop = 0, 2
	local function counter()
		count = count + 1
		return count < stop
	end
	local socket = require('socket')
	local start_time = socket.gettime()

	timeout(interval, counter)
	test.wait(function() return count == stop end)

	local duration = socket.gettime() - start_time
	local expected_duration = interval * stop
	test.assert(duration > expected_duration, 'should have waited %fs, but waited only %fs)',
		expected_duration, duration)
end)
if not pcall(require, 'socket') then expected_failure() end

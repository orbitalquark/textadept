-- Copyright 2020-2024 Mitchell. See LICENSE.

test("buffer.text_range should implement Scintilla's SCI_GETTEXTRANGE", function()
	local text = '123456789'
	buffer:append_text(text)

	local sub_range = buffer:text_range(4, 7) -- 456
	local full_range = buffer:text_range(1, buffer.length + 1) -- 123456789
	local clamp_start_range = buffer:text_range(-1, 4) -- 123
	local clamp_end_range = buffer:text_range(7, 11) -- 789

	test.assert_equal(sub_range, text:sub(4, 6))
	test.assert_equal(full_range, text)
	test.assert_equal(clamp_start_range, text:sub(1, 3))
	test.assert_equal(clamp_end_range, text:sub(7))
end)

test('buffer.text_range should not modify buffer.target_range', function()
	local text = '123456789'
	buffer:append_text(text)
	buffer:set_target_range(4, 7) -- 456
	local target_text = buffer.target_text

	buffer:text_range(1, 4) -- 123

	test.assert_equal(buffer.target_text, target_text)
end)

test('replacing buffer text should emit events.BUFFER_{BEFORE,AFTER}_REPLACE_TEXT', function()
	buffer:append_text('text')
	local before_replace = test.stub()
	local after_replace = test.stub()
	local _<close> = test.connect(events.BUFFER_BEFORE_REPLACE_TEXT, before_replace)
	local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after_replace)

	buffer:set_text('replacement')

	test.assert_equal(before_replace.called, true)
	test.assert_equal(after_replace.called, true)
end)

for _, method in ipairs{'undo', 'redo'} do
	test('multi-line ' .. method .. ' should emit an event after updating UI', function()
		buffer:append_text('text')
		buffer:set_text(test.lines{'multi-line', 'text'})
		if method == 'redo' then buffer:undo() end
		local after_replace = test.stub()
		local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after_replace)

		buffer[method](buffer)
		local overwritten_by_scintilla = after_replace.called
		ui.update() -- invokes events.UPDATE_UI
		if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
		local overwrites_scintilla = after_replace.called

		-- Scintilla would overwrite any changes by handlers if those handlers were called too soon.
		-- Instead, they should be called later to overwrite any Scintilla changes.
		test.assert_equal(overwritten_by_scintilla, false)
		test.assert_equal(overwrites_scintilla, true)
	end)
end

test('view.set_theme should set the theme for a view, leaving others alone', function()
	local _<close> = test.tmpfile('.lua', true)
	view:split(true)
	local _<close> = test.tmpfile('.c', true)

	_VIEWS[1]:set_theme('dark')
	_VIEWS[2]:set_theme('light')

	local view1_style = _VIEWS[1].style_fore[view.STYLE_DEFAULT]
	local view2_style = _VIEWS[2].style_fore[view.STYLE_DEFAULT]
	test.assert(view1_style ~= view2_style, 'views should have different styles')
end)

test('move_buffer should allow moving a buffer backwards', function()
	local f1<close> = test.tmpfile('.1', true)
	local f2<close> = test.tmpfile('.2', true)
	local f3<close> = test.tmpfile('.3', true)

	move_buffer(3, 1)

	test.assert_equal(_BUFFERS[1].filename, f3.filename)
	test.assert_equal(_BUFFERS[2].filename, f1.filename)
	test.assert_equal(_BUFFERS[3].filename, f2.filename)
end)

test('move_buffer should allow moving a buffer forwards', function()
	local f1<close> = test.tmpfile('.1', true)
	local f2<close> = test.tmpfile('.2', true)
	local f3<close> = test.tmpfile('.3', true)

	move_buffer(2, 3)

	test.assert_equal(_BUFFERS[1].filename, f1.filename)
	test.assert_equal(_BUFFERS[2].filename, f3.filename)
	test.assert_equal(_BUFFERS[3].filename, f2.filename)
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
	local before_reset = test.stub()
	events.connect(events.RESET_BEFORE, before_reset)

	reset()

	test.assert_equal(before_reset.called, true)
	local persist = before_reset.args[1]
	test.assert_equal(persist, {})
end)

-- TODO: quit?

test('timeout should repeatedly call a function as long as it returns true', function()
	local interval = 0.1
	local count, stop = 0, 2
	local function counter()
		count = count + 1
		return count < stop
	end
	local socket = require('debugger').socket
	local start_time = socket.gettime()

	timeout(interval, counter)
	test.wait(function() return count == stop end)

	local duration = socket.gettime() - start_time
	local expected_duration = interval * stop
	test.assert(duration > expected_duration, 'should have waited %fs, but waited only %fs)',
		expected_duration, duration)
end)
if BSD then skip('luasocket was not built for this platform') end

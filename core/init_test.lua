-- Copyright 2020-2026 Mitchell. See LICENSE.

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
if OS == 'bsd' then skip('luasocket was not built for this platform') end
if UI == 'gtk' and os.getenv('CI') == 'true' then
	local p<close> = io.popen('dpkg --list')
	if p:read('a'):find('gtk2%.0%-dev') then skip('smoke test for GTK2 does not include modules') end
end

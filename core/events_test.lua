-- Copyright 2020-2024 Mitchell. See LICENSE.

-- Test event
local event = 'event'

test('events.emit should call a connected handler', function()
	local handler = test.stub()
	local _<close> = test.connect(event, handler)

	events.emit(event)

	test.assert_equal(handler.called, true)
end)

test('events.emit should not call a disconnected handler', function()
	local handler = test.stub()
	events.connect(event, handler)
	events.disconnect(event, handler)

	events.emit(event)

	test.assert_equal(handler.called, false)
end)

test('events.connect should only connect a handler once', function()
	local handler = test.stub()

	local _<close> = test.connect(event, handler)
	local _<close> = test.connect(event, handler) -- should disconnect the first connection
	events.emit(event)

	test.assert_equal(handler.called, true) -- would be 2 if called twice
end)

test('events.connect should allow for inserting a handler before another', function()
	local call_order = {}
	local record = function(name) call_order[#call_order + 1] = name end
	local f1 = function() record('f1') end
	local f2 = function() record('f2') end

	local _<close> = test.connect(event, f1)
	local _<close> = test.connect(event, f2, 1) -- should run before f1
	events.emit(event)

	test.assert_equal(call_order, {'f2', 'f1'})
end)

test('events.emit should stop calling handlers when one returns a value', function()
	local returns_value = test.stub(true)
	local should_ignore = test.stub()
	local _<close> = test.connect(event, returns_value)
	local _<close> = test.connect(event, should_ignore)

	events.emit(event)

	test.assert_equal(returns_value.called, true)
	test.assert_equal(should_ignore.called, false)
end)

test("events.emit should return a handler's non-nil value (if any)", function()
	local catch = 'catch'
	local throw = test.stub(catch)
	local _<close> = test.connect(event, throw)

	local result = events.emit(event)

	test.assert_equal(result, catch)
end)

-- Coverage tests.

test('events.emit should not skip calling handlers if one removes itself', function()
	local function disconnects_self() events.disconnect(event, disconnects_self) end
	local should_not_skip = test.stub()
	local _<close> = test.connect(event, disconnects_self)
	local _<close> = test.connect(event, should_not_skip)

	events.emit(event)

	test.assert_equal(should_not_skip.called, true)
end)

test('events.emit should emit an event if a handler errors', function()
	local error_handler = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, error_handler, 1)
	local error_message = 'error!'
	local raise_error = function() error(error_message) end
	local _<close> = test.connect(event, raise_error)

	events.emit(event)

	test.assert_equal(error_handler.called, true)
	local message = error_handler.args[1]
	test.assert_contains(message, error_message)
end)

test('events.emit should write to io.stderr if the default error handler itself errors', function()
	local stderr_writer = test.stub()
	local _<close> = test.mock(io, 'stderr', {write = stderr_writer})
	local error_message = 'error!'
	local raise_error = function() error(error_message) end
	local _<close> = test.connect(events.ERROR, raise_error, 1)

	events.emit(events.ERROR)

	test.assert_equal(stderr_writer.called, true)
	local stderr = stderr_writer.args[2]
	test.assert_contains(stderr, error_message)
end)

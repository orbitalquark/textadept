-- Copyright 2020-2024 Mitchell. See LICENSE.

-- Test event
local event = 'event'

test('events.connect api should raise errors for invalid argument types', function()
	local no_event_name = function() events.connect() end
	local no_event_handler = function() events.connect(event, nil) end
	local f = test.stub()
	local invalid_index = function() events.connect(event, f, 'invalid') end

	test.assert_raises(no_event_name, 'string expected')
	test.assert_raises(no_event_handler, 'function expected')
	test.assert_raises(invalid_index, 'number/nil expected')
end)

test('events.disconnect api should raise errors for invalid argument types', function()
	local no_event_name = function() events.disconnect() end
	local no_event_handler = function() events.disconnect(event) end

	test.assert_raises(no_event_name, 'expected, got nil')
	test.assert_raises(no_event_handler, 'function expected')
end)

test('events.emit api should raise errors for an invalid argument type', function()
	local no_event_name = function() events.emit() end

	test.assert_raises(no_event_name, 'string expected')
end)

test('events.emit should call a handler connected with events.connect', function()
	local handler = test.stub()
	local _<close> = test.connect(event, handler)

	events.emit(event)
	test.assert_equal(handler.called, true)
end)

test('events.emit should not call a disconnected handler', function()
	local handler = test.stub()
	local _<close> = test.connect(event, handler)
	events.disconnect(event, handler)
	events.emit(event)
	test.assert_equal(handler.called, false)
end)

test('events.connect should only connect a handler once', function()
	local handler = test.stub()
	local _<close> = test.connect(event, handler)
	local _<close> = test.connect(event, handler) -- should disconnect the first connection
	events.emit(event)
	test.assert_equal(handler.called, true)
end)

test('events.connect should allow inserting an event handler before others', function()
	local call_order = {}
	local add1 = function() call_order[#call_order + 1] = 1 end
	local add2 = function() call_order[#call_order + 1] = 2 end
	local _<close> = test.connect(event, add2)
	local _<close> = test.connect(event, add1, 1)
	events.emit(event)
	test.assert_equal(call_order, {1, 2})
end)

test('events.emit should stop calling handlers when one returns a value', function()
	local returns_value = test.stub(true)
	local ignored = test.stub()
	local _<close> = test.connect(event, returns_value)
	local _<close> = test.connect(event, ignored)
	events.emit(event)
	test.assert_equal(ignored.called, false)
end)

test('events.emit should not skip calling handlers if one removes itself', function()
	local function disconnects_self() events.disconnect(event, disconnects_self) end
	local not_skipped = test.stub()
	local _<close> = test.connect(event, disconnects_self)
	local _<close> = test.connect(event, not_skipped)
	events.emit(event)
	test.assert_equal(not_skipped.called, true)
end)

test('events.emit should emit events.ERROR if a handler errors', function()
	local error_handler = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, error_handler, 1)
	local raise_error = function() error('error!') end
	local _<close> = test.connect(event, raise_error)
	events.emit(event)
	test.assert(error_handler.args[1]:find('error!'), 'should have emitted error event')
end)

test('events.emit should write to io.stderr if an error handler errors', function()
	local stderr = io.stderr
	local _<close> = test.defer(function() io.stderr = stderr end)
	local stderr_writer = test.stub()
	io.stderr = {write = function(self, ...) return stderr_writer(...) end}

	local raises_error = function() error('error!') end
	local _<close> = test.connect(events.ERROR, raises_error, 1)
	events.emit(events.ERROR)
	test.assert(stderr_writer.args[1]:find('error!'), 'should have written error to io.stderr')
end)

test('events.emit should return the value returned by a handler (if any)', function()
	local throw = function() return 'catch' end
	local _<close> = test.connect(event, throw)
	local catch = events.emit(event)
	test.assert_equal(catch, 'catch')
end)

test('emit events prior to and after replacing text', function()
	buffer:set_text('text')
	local before = test.stub()
	local after = test.stub()
	local _<close> = test.connect(events.BUFFER_BEFORE_REPLACE_TEXT, before)
	local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after)

	buffer:set_text('replacement')
	test.assert_equal(before.called, true)
	test.assert_equal(after.called, true)
end)

for _, method in ipairs{'undo', 'redo'} do
	test('emit replacement event after updating UI after a multi-line ' .. method, function()
		buffer:set_text('text')
		buffer:set_text('multi-line\ntext')
		if method == 'redo' then buffer:undo() end

		local after = test.stub()
		local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after)

		buffer[method](buffer)
		test.assert_equal(after.called, false) -- Scintilla would overwrite any changes by handlers
		ui.update() -- invokes events.UPDATE_UI
		test.assert_equal(after.called, true) -- handlers can overwrite any Scintilla changes
	end)
end

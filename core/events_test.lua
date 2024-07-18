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

test('events.connect should allow inserting an event handler before others', function()
	local call_order = {}
	local record = function(name) call_order[#call_order + 1] = name end
	local f1 = function() record('f1') end
	local f2 = function() record('f2') end

	local _<close> = test.connect(event, f1)
	local _<close> = test.connect(event, f2, 1)
	events.emit(event)

	test.assert_equal(call_order, {'f2', 'f1'})
end)

test('events.emit should stop calling handlers when one returns a value', function()
	local returns_value = test.stub(true)
	local should_ignore = test.stub()

	local _<close> = test.connect(event, returns_value)
	local _<close> = test.connect(event, should_ignore)
	events.emit(event)

	test.assert_equal(should_ignore.called, false)
end)

test('events.emit should not skip calling handlers if one removes itself', function()
	local function disconnects_self() events.disconnect(event, disconnects_self) end
	local should_not_skip = test.stub()

	local _<close> = test.connect(event, disconnects_self)
	local _<close> = test.connect(event, should_not_skip)
	events.emit(event)

	test.assert_equal(should_not_skip.called, true)
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
	local stderr_writer = test.stub()
	local _<close> = test.mock(io, 'stderr', {write = stderr_writer})
	local raise_error = function() error('error!') end

	local _<close> = test.connect(events.ERROR, raise_error, 1)
	events.emit(events.ERROR)

	test.assert(stderr_writer.args[2]:find('error!'), 'should have written error to io.stderr')
end)

test('events.emit should return the value returned by a handler (if any)', function()
	local throw = test.stub('catch')

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
		local overwritten_by_scintilla = after.called
		ui.update() -- invokes events.UPDATE_UI
		local overwrites_scintilla = after.called

		-- Scintilla would overwrite any changes by handlers if those handlers were called too soon.
		-- Instead, they should be called later to overwrite any Scintilla changes.
		test.assert_equal(overwritten_by_scintilla, false)
		test.assert_equal(overwrites_scintilla, true)
	end)
end

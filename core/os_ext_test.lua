-- Copyright 2020-2024 Mitchell. See LICENSE.

test('os.spawn should raise errors for invalid arguments', function()
	local invalid_command = function() os.spawn(true) end
	local invalid_callback = function() os.spawn('echo', false) end
	local nonexistent_command = 'does-not-exist'
	local command_does_not_exist = function() assert(os.spawn(nonexistent_command)) end

	test.assert_raises(invalid_command, 'string expected')
	test.assert_raises(invalid_callback, 'function or nil expected')
	if not (WIN32 and CURSES) then -- 'cmd /c does not exist' prints to stderr and returns 1
		test.assert_raises(command_does_not_exist, nonexistent_command .. ':')
	end
end)

test("os.spawn should act like Lua's io.popen", function()
	local output = 'output'
	local stdout = os.spawn('echo ' .. output):read('a')

	test.assert_equal(stdout, output .. test.newline())
end)

test('os.spawn should spawn from the current working directory', function()
	local pwd = not WIN32 and 'pwd' or 'cd'
	local dir, _<close> = test.tempdir(nil, true)

	local cwd = os.spawn(pwd):read('a')

	test.assert_equal(cwd, test.lines{dir, ''})
end)

test('os.spawn should spawn from a given working directory', function()
	local pwd = not WIN32 and 'pwd' or 'cd'
	local dir, _<close> = test.tempdir()

	local cwd = os.spawn(pwd, dir):read('a')

	test.assert_equal(cwd, test.lines{dir, ''})
end)

test('os.spawn should inherit from the current environment', function()
	local env = not WIN32 and 'env' or 'set'

	local output = os.spawn(env):read('a')

	test.assert(output ~= test.newline(), 'should have a non-empty, inherited env')
end)

test('os.spawn should allow setting an environment from a map', function()
	local env_cmd = not WIN32 and 'env' or 'set'
	local env = {NAME = 'value'}

	local output = os.spawn(env_cmd, env):read('a')

	test.assert_equal(output, test.lines{'NAME=value', ''})
end)

test('os.spawn should allow setting an environment from a list', function()
	local env_cmd = not WIN32 and 'env' or 'set'
	local env = {'NAME=value'}

	local output = os.spawn(env_cmd, env):read('a')

	test.assert_equal(output, test.lines{'NAME=value', ''})
end)

test('os.spawn environment should ignore non-environment assignments', function()
	local env_cmd = not WIN32 and 'env' or 'set'
	local env = {[true] = false}

	local output = os.spawn(env_cmd, env):read('a')

	test.assert(not output:find('true=false'), 'should not have included non-string pair')
end)

test('os.spawn should report stdout, stderr, and exit status using callbacks', function()
	local stdout = test.stub()
	local stderr = test.stub()
	local exit = test.stub()
	local output = 'output'

	local p = os.spawn('echo ' .. output, stdout, stderr, exit)
	test.wait(function() return stdout.called end)
	if QT then p:wait() end

	test.assert_equal(stdout.called, true)
	test.assert_equal(stdout.args, {output .. test.newline()})
	test.assert_equal(stderr.called, false)
	test.assert_equal(exit.called, true)
	test.assert_equal(exit.args, {0})
end)

test('proc:status should report the status of a spawned process', function()
	local p = os.spawn('echo')

	local running = p:status()
	p:wait()
	local terminated = p:status()

	test.assert_equal(running, 'running')
	test.assert_equal(terminated, 'terminated')
end)

test('proc:wait should wait for process exit and return its code', function()
	local p = os.spawn('echo')

	local code = p:wait()

	test.assert_equal(code, 0)
end)

test('proc:wait should allow multiple calls to it and return the same exit code', function()
	local p = os.spawn('echo')

	p:wait()
	local code = p:wait()

	test.assert_equal(code, 0)
end)

test('os.spawn should invoke an exit callback even if proc:wait is called', function()
	local exit = test.stub()

	os.spawn('echo', nil, nil, exit):wait()

	test.assert_equal(exit.called, true)
	test.assert_equal(exit.args, {0})
end)

test('os.spawn should allow two-way communication with a spawned process', function()
	local filename, _<close> = test.tempfile('.lua')
	io.open(filename, 'wb'):write('print(io.read())'):close()
	local input = 'input'

	local textadept = arg[0]
	local p = os.spawn(string.format('"%s" -L "%s"', textadept, filename))
	p:write(input .. '\n')
	p:close()
	local output = p:read('l')
	local eof = p:read('a')

	test.assert_equal(output, input)
	test.assert_equal(eof, '')
end)

test('proc:kill should kill a spawned process', function()
	local sleep = not WIN32 and 'sleep 1' or 'timeout /T 1'
	local p = os.spawn(sleep)

	p:kill()
	local code = p:wait()
	local status = p:status()

	test.assert(code ~= 0, 'should have killed process')
	test.assert_equal(status, 'terminated')
end)

test('os.spawn should emit an error when a stdout/stderr callback errors', function()
	local event = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, event, 1)
	local raises_error = function(output) error('error: ' .. output) end
	local output = 'output'

	os.spawn('echo ' .. output, raises_error)

	test.wait(function() return event.called end)
	test.assert(event.args[1]:find('error: ' .. output), 'should have included stdout error message')
end)

test('os.spawn should emit an error when an exit callback errors', function()
	local event = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, event, 1)
	local raises_error = function(code) error('error: ' .. code) end

	os.spawn('echo', nil, nil, raises_error):wait()

	test.assert_equal(event.called, true)
	test.assert(event.args[1]:find('error: 0'), 'should have included exit error message')
end)

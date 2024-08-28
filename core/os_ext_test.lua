-- Copyright 2020-2024 Mitchell. See LICENSE.

test("os.spawn should act like Lua's io.popen", function()
	local output = 'output'
	local stdout = os.spawn('echo ' .. output):read()

	test.assert_equal(stdout, output)
end)

test('os.spawn should spawn from the current working directory', function()
	local pwd = not WIN32 and 'pwd' or 'cd'
	local dir<close> = test.tmpdir(true)

	local cwd = os.spawn(pwd):read('a')

	test.assert_equal(cwd, test.lines{dir.dirname, ''})
end)

test('os.spawn should allow spawning from a given working directory', function()
	local pwd = not WIN32 and 'pwd' or 'cd'
	local dir<close> = test.tmpdir()

	local cwd = os.spawn(pwd, dir.dirname):read('a')

	test.assert_equal(cwd, test.lines{dir.dirname, ''})
end)

test('os.spawn should inherit from the current environment', function()
	local env = not WIN32 and 'env' or 'set'

	local output = os.spawn(env):read() or ''

	test.assert(output ~= '', 'should have a non-empty, inherited env')
end)

test('os.spawn should allow setting an environment from a map', function()
	local env_command = not WIN32 and 'env' or 'set'
	local env = {NAME = 'value'}

	local output = os.spawn(env_command, env):read('a')

	test.assert_contains(output, 'NAME=value')
end)

test('os.spawn should allow setting an environment from a list', function()
	local env_command = not WIN32 and 'env' or 'set'
	local env = {'NAME=value'}

	local output = os.spawn(env_command, env):read('a')

	test.assert_contains(output, 'NAME=value')
end)

test('os.spawn environment should ignore non-environment assignments', function()
	local env_command = not WIN32 and 'env' or 'set'
	local env = {[true] = false}
	if WIN32 and CURSES then env.PATH = os.getenv('PATH') end -- needed to find env_command

	local output = os.spawn(env_command, env):read('a')

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
	test.assert_equal(stdout.args, {test.lines{output, ''}})
	test.assert_equal(stderr.called, false)
	test.assert_equal(exit.called, true)
	test.assert_equal(exit.args, {0})
end)

test('proc.status should report the status of a spawned process', function()
	local p = os.spawn('echo')

	local running = p:status()
	p:wait()
	local terminated = p:status()

	test.assert_equal(running, 'running')
	test.assert_equal(terminated, 'terminated')
end)

test('proc.wait should wait for process exit and return its code after each call', function()
	local p = os.spawn('echo')

	local code = p:wait()
	local same_code = p:wait()

	test.assert_equal(code, 0)
	test.assert_equal(same_code, code)
end)

test('os.spawn should invoke an exit callback even if proc.wait is called', function()
	local exit = test.stub()

	os.spawn('echo', nil, nil, exit):wait()

	test.assert_equal(exit.called, true)
	test.assert_equal(exit.args, {0})
end)

test('os.spawn should allow two-way communication with a spawned process', function()
	local textadept = lfs.abspath(arg[0])
	local f<close> = test.tmpfile('.lua', 'print(io.read())')
	local command = string.format('"%s" -L "%s"', textadept, f.filename)
	local input = 'input'

	test.log('spawning ', command)
	local p = os.spawn(command)
	p:write(input .. (not WIN32 and '\n' or '\r\n'))
	p:close()
	local output = assert(p:read())
	local eof = p:read('a')

	test.assert_equal(output, input)
	test.assert_equal(eof, '')
end)

test('proc.kill should kill a spawned process', function()
	local sleep = not WIN32 and 'sleep 1' or 'timeout /T 1'
	local p = os.spawn(sleep)

	p:kill()
	local code = p:wait()
	local status = p:status()

	test.assert(code ~= 0, 'should have killed process')
	test.assert_equal(status, 'terminated')
end)

test('os.spawn should raise an error if the command does not exist', function()
	local nonexistent_command = 'does-not-exist'
	local command_does_not_exist = function() assert(os.spawn(nonexistent_command)) end

	test.assert_raises(command_does_not_exist, nonexistent_command .. ':')
end)
if WIN32 then skip("'cmd /c does not exist' prints to stderr and returns 1") end

-- Coverage tests.

test('os.spawn should emit an error when a stdout/stderr callback errors', function()
	local event = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, event, 1)
	local error_prefix = 'error: '
	local raises_error = function(output) error(error_prefix .. output) end
	local output = 'output'

	os.spawn('echo ' .. output, raises_error)

	test.wait(function() return event.called end)
	local error_message = event.args[1]
	test.assert_contains(error_message, error_prefix .. output)
end)

test('os.spawn should emit an error when an exit callback errors', function()
	local event = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, event, 1)
	local error_prefix = 'error: '
	local raises_error = function(code) error(error_prefix .. code) end

	os.spawn('echo', nil, nil, raises_error):wait()

	test.assert_equal(event.called, true)
	local error_message = event.args[1]
	test.assert_contains(error_message, error_prefix .. '0')
end)

test('proc.read(n) should read n bytes', function()
	local output = 'output'
	local p = os.spawn('echo ' .. output)

	local bytes = p:read(#output)

	test.assert_equal(bytes, output)
end)

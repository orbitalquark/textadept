-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Sends command line table *arg* for processing.
-- @param arg Table of command line arguments to process.
local function send_command_line(arg)
	events.emit('command_line', assert_type(arg, 'table', 1))
end

test('should open command-line filenames', function()
	local f<close> = test.tmpfile()

	send_command_line{f.filename}

	test.assert_equal(#_BUFFERS, 1)
	test.assert_equal(buffer.filename, f.filename)
end)

test('should change cwd to command-line directory', function()
	local dir<close> = test.tmpdir()
	local cwd = lfs.currentdir()
	local _<close> = test.defer(function() lfs.chdir(cwd) end)

	send_command_line{dir.dirname}

	test.assert_equal(lfs.currentdir(), dir.dirname)
end)

test('should open relative command-line files with respect to cwd', function()
	local cwd = lfs.currentdir()
	local _<close> = test.defer(function() lfs.chdir(cwd) end)

	local file = 'file.txt'
	local dir<close> = test.tmpdir{file}
	local filename = dir / file

	send_command_line{dir.dirname, file}

	test.assert_equal(buffer.filename, filename)
end)

test('args.register should register command line options', function()
	local z = test.stub()
	args.register('-z', '--zz', 1, z, '')
	local value = 1

	send_command_line{'-z', value}
	send_command_line{'--zz', value}

	test.assert_equal(z.called, 2) -- called once for short, once for long
	test.assert_equal(z.args, {value})
end)

-- TODO: should emit events.ARG_NONE when no command-line args are given
-- TODO: a command-line option handler can return true to prevent events.ARG_NONE

-- Coverage tests.

test('--help should show command line options and then quit', function()
	local print = test.stub()
	local _<close> = test.mock(_G, 'print', print)
	local quit = test.stub()
	local _<close> = test.mock(_G, 'quit', quit)

	send_command_line{'--help'}

	test.wait(function() return quit.called end)
	test.assert(print.called > 1, 'help should have been printed')
end)
if CURSES then skip('printing to stdout is not supported') end

test('--version should show version information and then quit', function()
	local print = test.stub()
	local _<close> = test.mock(_G, 'print', print)
	local quit = test.stub()
	local _<close> = test.mock(_G, 'quit', quit)

	send_command_line{'--version'}

	test.wait(function() return quit.called end)
	test.assert_equal(print.called, true)
end)
if CURSES then skip('printing to stdout is not supported') end

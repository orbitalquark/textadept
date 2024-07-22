-- Copyright 2020-2024 Mitchell. See LICENSE.

test('a file passed on the command line should be opened', function()
	local filename, _<close> = test.tempfile()

	events.emit('command_line', {filename}) -- simulate

	test.assert_equal(#_BUFFERS, 1)
	test.assert_equal(buffer.filename, filename)
end)

test('a directory passed on the command line should change the working dir', function()
	local dir, _<close> = test.tempdir()
	local cwd = lfs.currentdir()
	local _<close> = test.defer(function() lfs.chdir(cwd) end)

	events.emit('command_line', {dir}) -- simulate

	test.assert_equal(lfs.currentdir(), dir)
end)

test('--help should show command line options and then quit', function()
	local print = test.stub()
	local _<close> = test.mock(_G, 'print', print)
	local quit = test.stub()
	local _<close> = test.mock(_G, 'quit', quit)

	events.emit('command_line', {'--help'}) -- simulate
	test.wait(function() return quit.called end)

	test.assert(print.called > 1, 'help should have been printed')
	test.assert_equal(quit.called, true)
end)

test('--version should show version information and then quit', function()
	local print = test.stub()
	local _<close> = test.mock(_G, 'print', print)
	local quit = test.stub()
	local _<close> = test.mock(_G, 'quit', quit)

	events.emit('command_line', {'--version'}) -- simulate
	test.wait(function() return quit.called end)

	test.assert_equal(print.called, true)
	test.assert_equal(quit.called, true)
end)

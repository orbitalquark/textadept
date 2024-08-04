-- Copyright 2020-2024 Mitchell. See LICENSE.

test('run.compile should raise errors for invalid arguments', function()
	local invalid_filename = function() textadept.run.compile(true) end

	test.assert_raises(invalid_filename, 'string/nil expected')
end)

test('run.* should prompt for a command to run', function()
	local prompt = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', prompt)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	textadept.run.compile()

	test.assert_equal(prompt.called, true)
	local label = prompt.args[1]
	local lexer = prompt.args[3]
	test.assert(label ~= '', 'command entry should have label')
	test.assert_equal(lexer, 'bash')
end)

test('run.* should not prompt for a command to run if run.run_without_prompt is enabled', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local prompt = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', prompt)
	local filename, _<close> = test.tempfile()

	textadept.run.compile(filename)

	test.assert_equal(prompt.called, false)
end)

test('run.compile/run should allow commands based on filename', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local filename, _<close> = test.tempfile()
	local command = 'command'
	textadept.run.compile_commands[filename] = command

	textadept.run.compile(filename)

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should allow commands based on file extension', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local filename, _<close> = test.tempfile('.txt')
	local command = 'command'
	local _<close> = test.mock(textadept.run.compile_commands, 'txt', command)

	textadept.run.compile(filename)

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should allow commands based on lexer', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local command = 'command'
	local _<close> = test.mock(textadept.run.compile_commands, 'text', command)

	textadept.run.compile()

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should save a modified file before running a command for it', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:append_text(' ')

	textadept.run.compile()

	test.assert_equal(buffer.modify, false)
end)

test('run.compile should run a compile command for the current file', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	local command = 'echo compile'
	textadept.run.compile_commands[filename] = command

	textadept.run.compile(filename)

	test.assert_equal(buffer._type, _L['[Output Buffer]'])
	test.assert_equal(buffer.current_pos, buffer.length + 1)
	test.wait(function() return buffer:get_text():find('> exit status:') end)
	local output = buffer:get_text()
	test.assert(output:find('> ' .. command), 'should have run compile command')
	test.assert(output:find('\ncompile'), 'should have captured command stdout')
	test.assert(output:find('> exit status: 0'), 'should have captured exit status')
end)

test('run.* should do nothing with an empty command', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	textadept.run.compile_commands[filename] = ''

	textadept.run.compile(filename)

	test.assert_equal(buffer._type, nil)
end)

test('run.compile should mark recognized errors', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile('file.txt:1: error!')
	local command = (not WIN32 and 'cat ' or 'type ') .. filename
	textadept.run.compile_commands[filename] = command

	textadept.run.compile(filename)

	test.wait(function() return buffer:get_text():find('> exit status:') end)
	local line = buffer:marker_next(1, 1 << textadept.run.MARK_ERROR - 1)
	test.assert(line ~= -1, 'should have marked error')
end)

test('run.* should silently run a command if run.run_in_background is enabled', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(textadept.run, 'run_in_background', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	textadept.run.compile_commands[filename] = 'echo'

	textadept.run.compile()

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(#_BUFFERS, 2)
	test.assert_equal(_BUFFERS[2]._type, _L['[Output Buffer]'])
end)

test('run.run should raise errors for invalid arguments', function()
	local invalid_filename = function() textadept.run.run(true) end

	test.assert_raises(invalid_filename, 'string/nil expected')
end)

local output_events = {
	[textadept.run.compile] = events.COMPILE_OUTPUT, --
	[textadept.run.run] = events.RUN_OUTPUT, --
	[textadept.run.build] = events.BUILD_OUTPUT, --
	[textadept.run.test] = events.TEST_OUTPUT, --
	[textadept.run.run_project] = events.RUN_OUTPUT
}
local function capture_output(f, path, command)
	local output = {}
	local capture = function(out)
		output[#output + 1] = out
		return true -- avoid propagation to default handlers that print to the output buffer
	end
	local _<close> = test.connect(output_events[f], capture, 1)

	if not command then
		local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
		f(path)
	else
		local run = function(_, run_f, _, _, ...) run_f(command, ...) end
		local _<close> = test.mock(ui.command_entry, 'run', run)
		f(path)
	end
	test.wait(function() return output[#output]:find('> exit status:') end)

	return table.concat(output)
end

test('run.run should run a run command for the current file', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local command = 'echo run'
	textadept.run.run_commands[filename] = command

	local output = capture_output(textadept.run.run)

	test.assert(output:find('> ' .. command), 'should have run run command')
	test.assert(output:find('\nrun'), 'should have captured command stdout')
	test.assert(output:find('> exit status: 0'), 'should have captured exit status')
end)

test('run.* should auto-update commands', function()
	local filename, _<close> = test.tempfile()
	textadept.run.run_commands[filename] = 'echo 1'

	local command = 'echo 2'
	local output = capture_output(textadept.run.run, filename, command)
	local same_output = capture_output(textadept.run.run, filename)

	test.assert(output:find('> ' .. command), 'should have run new command')
	test.assert_equal(same_output, output)
end)

test('run.* should allow functions to return commands and working dirs', function()
	local dir, _<close> = test.tempdir()
	local filename, _<close> = test.tempfile()
	local command = not WIN32 and 'pwd' or 'cd'
	textadept.run.run_commands[filename] = function() return command, dir end

	local output = capture_output(textadept.run.run, filename)

	test.assert(output:find('> cd ' .. dir, 1, true),
		'should have gotten working directory from function')
	test.assert(output:find('> ' .. command), 'should have gotten command from function')
end)

-- TODO: test env

test('run.compile/run should allow macros in commands', function()
	local filename, _<close> = test.tempfile('.txt')
	textadept.run.run_commands[filename] = 'echo %p\t%d\t%f\t%e'

	local output = capture_output(textadept.run.run, filename)

	local arg_string = output:match('> echo ([^\r\n]+)')
	local args = {}
	for arg in arg_string:gmatch('[^\t]+') do args[#args + 1] = arg end
	local dirname = filename:match('^(.+)[/\\]')
	local basename = filename:match('[^/\\]+$')
	local basename_no_ext = basename:match('^(.+)%.')
	test.assert_equal(args, {filename, dirname, basename, basename_no_ext})
end)

test('run.build should raise errors for invalid arguments', function()
	local invalid_dir = function() textadept.run.build(true) end

	test.assert_raises(invalid_dir, 'string/nil expected')
end)

test('run.build should run a build command for the current project', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}
	io.open_file(dir .. '/file.txt')
	local command = 'echo build'
	textadept.run.build_commands[dir] = command

	local output = capture_output(textadept.run.build)
	test.assert(output:find('> ' .. command), 'should have run build command')
	test.assert(output:find('\nbuild'), 'should have captured command stdout')
	test.assert(output:find('> exit status: 0'), 'should have captured exit status')
end)

test('run.build should allow commands based on top-level files', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}
	local command = 'echo build'
	local _<close> = test.mock(textadept.run.build_commands, 'file.txt', command)

	local output = capture_output(textadept.run.build, dir)
	test.assert(output:find('> ' .. command), 'should have run build command')
end)

test('run.test should run a test command for the current project', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}
	io.open_file(dir .. '/file.txt')
	local command = 'echo test'
	textadept.run.test_commands[dir] = command

	local output = capture_output(textadept.run.test)
	test.assert(output:find('> ' .. command), 'should have run test command')
	test.assert(output:find('\ntest'), 'should have captured command stdout')
	test.assert(output:find('> exit status: 0'), 'should have captured exit status')
end)

test('run.test should run a project command for the current project', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}
	io.open_file(dir .. '/file.txt')
	local command = 'echo project'
	textadept.run.run_project_commands[dir] = command

	local output = capture_output(textadept.run.run_project)
	test.assert(output:find('> ' .. command), 'should have run project command')
	test.assert(output:find('\nproject'), 'should have captured command stdout')
	test.assert(output:find('> exit status: 0'), 'should have captured exit status')
end)

test('run.stop should stop the currently running process', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	local command = not WIN32 and 'sleep 1' or 'timeout 1'
	textadept.run.run_commands[filename] = command
	textadept.run.run(filename)

	textadept.run.stop()

	test.wait(function() return buffer:get_text():find('> exit status:') end)
	local status = buffer:get_text():match('> exit status: (%d+)')
	test.assert(status ~= '0', 'should have killed process')
end)

test('run.stop should prompt when there are multiple running processes', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	local command = not WIN32 and 'sleep 1' or 'timeout 1'
	textadept.run.run_commands[filename] = command
	textadept.run.run(filename)
	textadept.run.run(filename)

	local select_all = test.stub({1, 2})
	local _<close> = test.mock(ui.dialogs, 'list', select_all)

	textadept.run.stop()

	local status = '> exit status:'
	test.wait(function() return select(2, buffer:get_text():gsub(status, status)) == 2 end)
	test.assert_equal(select_all.called, true)
	test.assert(select(2, buffer:get_text():gsub(status, status)) == 2,
		'should have killed both processes')
end)

test('run.* should send the output buffer line as stdin on Enter', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile('.lua', 'print("read: " .. io.read())')
	local textadept_exe = arg[0]
	textadept.run.run_commands[filename] = textadept_exe .. ' -L "%f"'
	textadept.run.run(filename)

	test.type('line\n')

	test.wait(function() return buffer:get_text():find('> exit status:') end)
	test.assert(buffer:get_text():find('read: line'), 'should have sent stdin')
end)

test('run.goto_error should raise errors for invalid arguments', function()
	local invalid_location = function() textadept.run.goto_error('') end

	test.assert_raises(invalid_location, 'boolean/number expected')
end)

test('run.goto_error(true) should go to the next error/warning found', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:append_text(test.lines{filename .. ':1: error!', filename .. ':2: warning: warning!', ''})

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run()
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	textadept.run.goto_error(true)
	local first_line = buffer:line_from_position(buffer.current_pos)

	textadept.run.goto_error(true)
	local second_line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(first_line, 1)
	test.assert_equal(second_line, 2)
end)

test('run.goto_error should allow going to columns if available', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open(filename, 'wb'):write(filename, ':1:2: error!', '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.current_pos, buffer:find_column(1, 2))
end)

test('run.goto_error should show an annotation with the error message', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	local errmsg = 'error!'
	io.open(filename, 'wb'):write(filename, ':1: ', errmsg, '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.annotation_text[1], errmsg)
end)

test('run.goto_error should work with relative file names', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	local basename = filename:match('[^/\\]+$')
	io.open(filename, 'wb'):write(basename, ':1: error!', '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.filename, filename)
end)

test('run.goto_error should work if neither the output view nor buffer is visible', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open(filename, 'w'):write(filename, ':1: error!', '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	view:goto_buffer(-1)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.filename, filename)
end)

test('run.goto_error(false) should go to the previous error/warning found', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:append_text(test.lines{filename .. ':1: error!', filename .. ':2: warning: warning!', ''})

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run()
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	textadept.run.goto_error(false)
	local first_line = buffer:line_from_position(buffer.current_pos)

	textadept.run.goto_error(false)
	local second_line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(first_line, 2)
	test.assert_equal(second_line, 1)
end)

test('Enter in an output buffer error should jump to that error', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open(filename, 'w'):write(filename, ':1: error!', '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	buffer:line_up()
	buffer:line_up()

	test.type('\n')

	test.assert_equal(buffer.filename, filename)
end)

test('double-clicking an error in the output buffer should jump to it', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local filename, _<close> = test.tempfile()
	io.open(filename, 'w'):write(filename, ':1: error!', '\n'):close()

	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[filename] = command .. ' "%f"'
	textadept.run.run(filename)
	test.wait(function() return buffer:get_text():find('> exit status:') end)

	buffer:line_up()
	buffer:line_up()
	local line = buffer:line_from_position(buffer.current_pos)

	events.emit(events.DOUBLE_CLICK, buffer.current_pos, line)

	test.assert_equal(buffer.filename, filename)
end)

test('Lua errors should be recognized', function()
	xpcall(error, function(message) events.emit(events.ERROR, debug.traceback(message)) end,
		'internal error', 2)
	textadept.run.goto_error(1)

	test.assert(buffer.filename:find('[/\\]run_test%.lua$'), 'did not detect internal Lua error')
end)

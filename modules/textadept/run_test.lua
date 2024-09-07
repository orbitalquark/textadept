-- Copyright 2020-2024 Mitchell. See LICENSE.

test('run.* should prompt for a command to run', function()
	local prompt = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', prompt)
	local _<close> = test.tmpfile(true)

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
	local f<close> = test.tmpfile()

	textadept.run.compile(f.filename)

	test.assert_equal(prompt.called, false)
end)

test('run.compile/run should allow commands based on filename', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local f<close> = test.tmpfile()
	local command = 'command'
	textadept.run.compile_commands[f.filename] = command

	textadept.run.compile(f.filename)

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should allow commands based on file extension', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local f<close> = test.tmpfile('.txt')
	local command = 'command'
	local _<close> = test.mock(textadept.run.compile_commands, 'txt', command)

	textadept.run.compile(f.filename)

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should allow commands based on lexer', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)
	local _<close> = test.tmpfile(true)
	local command = 'command'
	local _<close> = test.mock(textadept.run.compile_commands, 'text', command)

	textadept.run.compile()

	local run_command = run.args[4]
	test.assert_equal(run_command, command)
end)

test('run.compile/run should save a modified file before running a command for it', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.tmpfile(true)
	buffer:append_text(' ')

	textadept.run.compile()

	test.assert_equal(buffer.modify, false)
end)

test('run.compile should run a compile command and print results to the output buffer', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local f<close> = test.tmpfile()
	local stdout = 'compile'
	local command = 'echo ' .. stdout
	textadept.run.compile_commands[f.filename] = command

	textadept.run.compile(f.filename)

	test.assert_equal(buffer._type, _L['[Output Buffer]'])
	test.wait(function() return buffer:get_text():find('> exit status:') end)
	local output = buffer:get_text()
	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. stdout) -- match from stdout, not command
	test.assert_contains(output, '> exit status: 0')
end)

--- Basic mock for `os.spawn()` that emits stdout and return a 0 exit status.
-- The stdout emitted depends on the incoming command:
--
-- - cat or type: stdout is the contents of the file argument
-- - echo: stdout is all arguments
-- - pwd or cd: stdout is the given directory
--
-- If the incoming command was not recognized, returns nil and an error message, just like
-- `os.spawn()`.
local function mock_spawn(command, dir, emit, _, exit)
	if command:find('^cat ') or command:find('^type ') then
		local filename = command:match('^%S+ "?(.-)"?$')
		filename = lfs.abspath(filename, dir)
		local f<close>, errmsg = io.open(filename)
		if not f then return nil, errmsg end
		emit(f:read('a'))
	elseif command:find('^echo ') then
		emit(command:match('^echo (.+)$'))
	elseif command == 'pwd' or command == 'cd' then
		emit(dir)
	else
		return nil, 'command not found: ' .. command:match('^%S+')
	end
	exit(0)
	return {status = function() return 'terminated' end}
end

test('run.* should mark recognized errors', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile('file.txt:1: error!')
	local command = (not WIN32 and 'cat ' or 'type ') .. f.filename
	textadept.run.compile_commands[f.filename] = command

	textadept.run.compile(f.filename)

	local line = buffer:marker_next(1, 1 << textadept.run.MARK_ERROR - 1)
	test.assert(line ~= -1, 'should have marked error')
end)

test('run.* should silently run a command if run.run_in_background is enabled', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(textadept.run, 'run_in_background', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile(true)
	textadept.run.compile_commands[f.filename] = 'echo compile'

	textadept.run.compile()

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(#_BUFFERS, 2)
	test.assert_equal(_BUFFERS[2]._type, _L['[Output Buffer]'])
end)

--- Map of run functions with the events they emit.
local output_events = {
	[textadept.run.compile] = events.COMPILE_OUTPUT, --
	[textadept.run.run] = events.RUN_OUTPUT, --
	[textadept.run.build] = events.BUILD_OUTPUT, --
	[textadept.run.test] = events.TEST_OUTPUT, --
	[textadept.run.run_project] = events.RUN_OUTPUT
}

--- Invokes run function *f* for filename or directory *path*, optionally with command *command*,
-- and returns its string output.
-- @param f Run function to use (e.g. `textadept.run.run`).
-- @param path Filename or directory to pass to *f*.
-- @param[opt] command Optional string command to run. If omitted, *f* will determine the
--	command to run from *path*.
-- @return command output string
local function mock_run(f, path, command)
	local output = {}
	local capture = function(out)
		output[#output + 1] = out
		return true -- avoid propagation to default handlers that print to the output buffer
	end
	local _<close> = test.connect(output_events[f], capture, 1)

	local _<close> = test.mock(os, 'spawn', mock_spawn)

	if not command then
		local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
		f(path)
	else
		local run = function(_, run_f, _, _, ...) run_f(command, ...) end
		local _<close> = test.mock(ui.command_entry, 'run', run)
		f(path)
	end

	return table.concat(output)
end

test('run.run should run a run command for the current file', function()
	local f<close> = test.tmpfile(true)
	local stdout = 'run'
	local command = 'echo ' .. stdout
	textadept.run.run_commands[f.filename] = command

	local output = mock_run(textadept.run.run)

	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. stdout) -- match from stdout, not command
	test.assert_contains(output, '> exit status: 0')
end)

test('run.* should allow functions to return commands and working dirs', function()
	local dir<close> = test.tmpdir()
	local f<close> = test.tmpfile()
	local command = not WIN32 and 'pwd' or 'cd'
	local command_in_dir = function() return command, dir.dirname end
	textadept.run.run_commands[f.filename] = command_in_dir

	local output = mock_run(textadept.run.run, f.filename)

	test.assert_contains(output, '> cd ' .. dir.dirname)
	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. dir.dirname) -- match from stdout, not cd
end)

-- TODO: test env

test('run.compile/run should allow macros in commands', function()
	local f<close> = test.tmpfile('.txt')
	textadept.run.run_commands[f.filename] = 'echo %p\t%d\t%f\t%e'

	local output = mock_run(textadept.run.run, f.filename)

	local arg_string = output:match('> echo ([^\r\n]+)')
	local args = {}
	for arg in arg_string:gmatch('[^\t]+') do args[#args + 1] = arg end
	local dirname = f.filename:match('^(.+)[/\\]')
	local basename = f.filename:match('[^/\\]+$')
	local basename_no_ext = basename:match('^(.+)%.')
	test.assert_equal(args, {f.filename, dirname, basename, basename_no_ext})
end)

test('run.* should auto-update command tables per filename/directory', function()
	local f<close> = test.tmpfile()
	textadept.run.run_commands[f.filename] = 'echo 1'
	local command = 'echo 2'

	mock_run(textadept.run.run, f.filename, command)

	test.assert_equal(textadept.run.run_commands[f.filename], command)
end)

test('run.build should run a build command for the current project', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	io.open_file(dir / file)
	local stdout = 'build'
	local command = 'echo ' .. stdout
	textadept.run.build_commands[dir.dirname] = command

	local output = mock_run(textadept.run.build)

	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. stdout) -- match from stdout, not command
	test.assert_contains(output, '> exit status: 0')
end)

test('run.build should allow commands based on top-level files', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	local command = 'echo build'
	local _<close> = test.mock(textadept.run.build_commands, file, command)

	local output = mock_run(textadept.run.build, dir.dirname)

	test.assert_contains(output, '> ' .. command)
end)

test('run.test should run a test command for the current project', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	io.open_file(dir / file)
	local stdout = 'test'
	local command = 'echo ' .. stdout
	textadept.run.test_commands[dir.dirname] = command

	local output = mock_run(textadept.run.test)

	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. stdout) -- match from stdout, not command
	test.assert_contains(output, '> exit status: 0')
end)

test('run.test should run a project command for the current project', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	io.open_file(dir / file)
	local stdout = 'project'
	local command = 'echo ' .. stdout
	textadept.run.run_project_commands[dir.dirname] = command

	local output = mock_run(textadept.run.run_project)

	test.assert_contains(output, '> ' .. command)
	test.assert_contains(output, '\n' .. stdout) -- match from stdout, not command
	test.assert_contains(output, '> exit status: 0')
end)

test('run.stop should stop the currently running process', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local f<close> = test.tmpfile()
	local command = not WIN32 and 'sleep 1' or 'timeout 1'
	textadept.run.run_commands[f.filename] = command
	textadept.run.run(f.filename)

	textadept.run.stop()

	test.wait(function() return buffer:get_text():find('> exit status:') end)
	local status = buffer:get_text():match('> exit status: (%d+)')
	test.assert(status ~= '0', 'should have killed process')
end)

test('run.stop should prompt when there are multiple running processes', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local f<close> = test.tmpfile()
	local command = not WIN32 and 'sleep 1' or 'timeout 1'
	textadept.run.run_commands[f.filename] = command
	textadept.run.run(f.filename)
	textadept.run.run(f.filename)

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
	local f<close> = test.tmpfile('.lua', 'print("read: " .. io.read())')
	local textadept_exe = lfs.abspath(arg[0])
	textadept.run.run_commands[f.filename] = textadept_exe .. ' -L "%f"'
	textadept.run.run(f.filename)

	test.type('line\n')

	test.wait(function() return buffer:get_text():find('> exit status:') end)
	test.assert_contains(buffer:get_text(), 'read: line')
end)

test('run.goto_error(true) should go to the next error/warning found', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile(true)
	buffer:append_text(test.lines{
		f.filename .. ':1: error!', --
		f.filename .. ':2: warning: warning!', --
		''
	})
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run()

	textadept.run.goto_error(true)
	local first_line = buffer:line_from_position(buffer.current_pos)

	textadept.run.goto_error(true)
	local second_line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(first_line, 1)
	test.assert_equal(second_line, 2)
end)
if WIN32 then expected_failure() end -- TODO: output lexer does not recognize absolute c:\ paths

test('run.goto_error should work with relative file names', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	f:write(basename, ':1: error!', '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.filename, f.filename)
end)

test('run.goto_error should allow going to columns if available', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	f:write(basename, ':1:2: error!', '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.current_pos, buffer:find_column(1, 2))
end)

test('run.goto_error should show an annotation with the error message', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	local errmsg = 'error!'
	f:write(basename, ':1: ', errmsg, '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.annotation_text[1], errmsg)
end)

test('run.goto_error should work if neither the output view nor buffer is visible', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	f:write(basename, ':1: error!', '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)
	view:goto_buffer(-1)

	textadept.run.goto_error(true)

	test.assert_equal(buffer.filename, f.filename)
end)

test('run.goto_error(false) should go to the previous error/warning found', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile(true)
	local basename = f.filename:match('[^/\\]+$')
	buffer:append_text(test.lines{
		basename .. ':1: error!', --
		basename .. ':2: warning: warning!', --
		''
	})
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run()

	textadept.run.goto_error(false)
	local first_line = buffer:line_from_position(buffer.current_pos)

	textadept.run.goto_error(false)
	local second_line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(first_line, 2)
	test.assert_equal(second_line, 1)
end)

-- Coverage tests.

test('Enter in an output buffer error should jump to that error', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	f:write(basename, ':1: error!', '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)
	for i = 1, 3 do buffer:line_up() end

	test.type('\n')

	test.assert_equal(buffer.filename, f.filename)
end)

test('double-clicking an error in the output buffer should jump to it', function()
	local _<close> = test.mock(textadept.run, 'run_without_prompt', true)
	local _<close> = test.mock(os, 'spawn', mock_spawn)
	local f<close> = test.tmpfile()
	local basename = f.filename:match('[^/\\]+$')
	f:write(basename, ':1: error!', '\n')
	local command = not WIN32 and 'cat' or 'type'
	textadept.run.run_commands[f.filename] = command .. ' "%f"'
	textadept.run.run(f.filename)
	for i = 1, 3 do buffer:line_up() end
	local line = buffer:line_from_position(buffer.current_pos)

	events.emit(events.DOUBLE_CLICK, buffer.current_pos, line)

	test.assert_equal(buffer.filename, f.filename)
end)

test('Lua errors should be recognized', function()
	local function error_handler(message) events.emit(events.ERROR, debug.traceback(message)) end
	xpcall(error, error_handler, 'this is a simulated error; ignore me', 2)
	textadept.run.goto_error(1)

	test.assert_contains(buffer.filename, 'run_test.lua')
end)

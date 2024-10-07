-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Compile and run source code files with Textadept.
-- Language [modules][] may tweak the `textadept.run.compile_commands`, and
-- `textadept.run.run_commands` tables for particular languages. The user may
-- tweak `textadept.run.build_commands`, `textadept.run.test_commands`, and
-- `textadept.run.run_project_commands` for particular projects.
--
-- [modules]: manual.html#modules
-- @module textadept.run
local M = {}

--- Run shell commands silently in the background.
-- The default value is `false`.
M.run_in_background = false

--- Run shell commands without prompting.
-- The default value is `false`.
M.run_without_prompt = false

--- The run or compile warning marker number.
M.MARK_WARNING = view.new_marker_number()
--- The run or compile error marker number.
M.MARK_ERROR = view.new_marker_number()
--- The run or compile warning indicator number.
M.INDIC_WARNING = view.new_indic_number()
--- The run or compile error indicator number.
M.INDIC_ERROR = view.new_indic_number()

-- Events.
local run_events = {'compile_output', 'run_output', 'build_output', 'test_output'}
for _, event in ipairs(run_events) do events[event:upper()] = event end

--- Emitted when executing a language's compile shell command.
-- By default, compiler output is printed to the output buffer. In order to override this
-- behavior, connect to the event with an index of `1` and return `true`.
-- Arguments:
--
-- - *output*: A line of string output from the command.
-- @field _G.events.COMPILE_OUTPUT

--- Emitted when executing a language's or project's run shell command.
-- By default, output is printed to the output buffer. In order to override this behavior,
-- connect to the event with an index of `1` and return `true`.
-- Arguments:
--
-- - *output*: A line of string output from the command.
-- @field _G.events.RUN_OUTPUT

--- Emitted when executing a project's build shell command.
-- By default, output is printed to the output buffer. In order to override this behavior,
-- connect to the event with an index of `1` and return `true`.
-- Arguments:
--
-- - *output*: A line of string output from the command.
-- @field _G.events.BUILD_OUTPUT

--- Emitted when executing a project's shell command for running tests.
-- By default, output is printed to the output buffer. In order to override this behavior,
-- connect to the event with an index of `1` and return `true`.
-- Arguments:
--
-- - *output*: A line of string output from the command.
-- @field _G.events.TEST_OUTPUT

--- Table of currently running spawned processes.
-- Each entry is a table that contains 'proc' and 'command' fields that describe the process.
local procs = {}

-- Keep track of the view the most recent process was spawned from in order to go to messages
-- (which are displayed in a split view) in the original view.
local preferred_view

--- Returns whether or not the given buffer is the output buffer.
local function is_out_buf(buf) return buf._type == _L['[Output Buffer]'] end

--- Helper function for getting the output view.
local function get_output_view()
	for _, view in ipairs(_VIEWS) do if is_out_buf(view.buffer) then return view end end
end
--- Helper function for getting the output buffer.
local function get_output_buffer()
	for _, buffer in ipairs(_BUFFERS) do if is_out_buf(buffer) then return buffer end end
end

local line_state_marks = {M.MARK_ERROR, M.MARK_WARNING}
local line_state_indics = {M.INDIC_ERROR, M.INDIC_WARNING}
--- Prints output from a compile, run, build, or test shell command, or prints a Lua error.
-- Any filenames encoded in _CHARSET are left alone and may not display properly.
-- All stdout and stderr from the command is printed silently.
-- @param silent Whether or not to print silently.
-- @param ... Output to print.
local function print_output(silent, ...)
	local buffer = get_output_buffer()
	local last_line = buffer and buffer.line_count or 1
	buffer = ui[silent and 'output_silent' or 'output'](...)
	for i = last_line, buffer.line_count do
		local line_state = buffer.line_state[i]
		if line_state > 0 then
			buffer:marker_add(i, line_state_marks[line_state])
			local s, e = buffer:position_from_line(i), buffer.line_end_position[i]
			while s < e and buffer:name_of_style(buffer.style_at[s]) ~= 'message' do s = s + 1 end
			while e > s and buffer:name_of_style(buffer.style_at[e]) ~= 'message' do e = e - 1 end
			buffer.indicator_current = line_state_indics[line_state]
			buffer:indicator_fill_range(s, e - s + 1)
		end
	end
end
for _, event in ipairs(run_events) do
	events.connect(event, function(...)
		print_output(M.run_in_background or not (...):find('^> ') or (...):find('^> exit'), ...)
	end)
end
events.connect(events.ERROR, function(errmsg) print_output(false, errmsg, '\n') end) -- mark Lua errors

--- Separate command entry run functions for distinct command histories.
local command_entry_f = {}
--- Prompts the user with the command entry to run command *command* in working directory *dir*,
-- emitting events of type *event* with any output received.
-- @param label String label to display in the command entry.
-- @param command String command to run, or a function returning such a string and optional
--	working directory and environment table. A returned working directory overrides *dir*.
-- @param dir String working directory to run *command* in.
-- @param event String event name to emit command output with.
-- @param commands Table of commands that *command* came from. This is for saving/restoring
--	custom commands per file/directory.
-- @param key String key in *commands* that produced *command*. This is for saving/restoring
--	custom commands per file/directory.
-- @param[opt] macros Optional table of '%[char]' macros to expand within *command*.
local function run_command(label, command, dir, event, commands, key, macros)
	local is_func, working_dir, env = type(command) == 'function'
	if is_func then command, working_dir, env = command() end
	local id = event .. key
	if not command_entry_f[id] then
		command_entry_f[id] = function(command, dir, env, event, commands, key, macros)
			if not command or command:find('^%s*$') then return end
			if not is_func then commands[key] = command end -- update if not originally a function
			if macros then command = command:gsub('%%%a', macros) end
			preferred_view = view
			local function emit(output) events.emit(event, output) end
			events.emit(event, string.format('> cd %s\n', dir:gsub('[/\\]$', '')))
			events.emit(event, string.format('> %s\n', command:iconv('UTF-8', _CHARSET)))
			local args = {
				command, dir, emit, emit, function(status)
					events.emit(event, string.format('> exit status: %d\n\n', status))
					ui.statusbar_text = status == 0 and _L['Command succeeded'] or _L['Command failed']
				end
			}
			if env then table.insert(args, 3, env) end
			procs[#procs + 1] = {proc = assert(os.spawn(table.unpack(args))), command = args[1]}
		end
	end
	if M.run_without_prompt then
		command_entry_f[id](command, working_dir or dir, env, event, commands, key, macros)
		return
	end
	ui.command_entry.run(label, command_entry_f[id], 'bash', command, working_dir or dir, env, event,
		commands, key, macros)
end

--- Compiles or runs file *filename* based on a shell command in *commands*.
-- @param filename The file to run.
-- @param commands Either `compile_commands` or `run_commands`.
local function compile_or_run(filename, commands)
	if filename == buffer.filename then
		buffer:annotation_clear_all()
		if buffer.modify then buffer:save() end
	end
	local label = commands == M.compile_commands and _L['Compile command:'] or _L['Run command:']
	local ext = filename:match('[^/\\.]+$')
	local lang = filename == buffer.filename and buffer.lexer_language or lexer.detect(ext)
	local command = commands[filename] or commands[ext] or commands[lang]
	local dirname, basename = '', filename
	if filename:find('[/\\]') then dirname, basename = filename:match('^(.+)[/\\]([^/\\]+)$') end
	local event = commands == M.compile_commands and events.COMPILE_OUTPUT or events.RUN_OUTPUT
	local macros = {
		['%p'] = filename, ['%d'] = dirname, ['%f'] = basename, ['%e'] = basename:match('^(.+)%.') -- no extension
	}
	run_command(label, command, dirname, event, commands, filename, macros)
end

--- Map of filenames, file extensions, and lexer names to their associated "compile" shell
-- command line strings or functions that return such strings.
-- Command line strings may have the following macros:
--
-- - `%f`: The file's name, including its extension.
-- - `%e`: The file's name, excluding its extension.
-- - `%d`: The file's directory path.
-- - `%p`: The file's full path.
--
-- Functions may also return a working directory and process environment table to operate in. By
-- default, the working directory is the current file's parent directory and the environment
-- is Textadept's environment.
-- @table compile_commands

-- LuaFormatter off
M.compile_commands = {actionscript='mxmlc "%f"',ada='gnatmake "%f"',c='gcc -o "%e" "%f"',antlr='antlr4 "%f"',g='antlr3 "%f"',applescript='osacompile "%f" -o "%e.scpt"',asm='nasm "%f"'--[[ && ld "%e.o" -o "%e"']],boo='booc "%f"',caml='ocamlc -o "%e" "%f"',csharp=WIN32 and 'csc "%f"' or 'mcs "%f"',coffeescript='coffee -c "%f"',context='context --nonstopmode "%f"',cpp='g++ -o "%e" "%f"',cuda=WIN32 and 'nvcc -o "%e.exe" "%f"' or 'nvcc -o "%e" "%f"',dmd='dmd "%f"',dot='dot -Tps "%f" -o "%e.ps"',eiffel='se c "%f"',elixir='elixirc "%f"',erlang='erl -compile "%e"',faust='faust -o "%e.cpp" "%f"',fsharp=WIN32 and 'fsc.exe "%f"' or 'mono fsc.exe "%f"',fortran='gfortran -o "%e" "%f"',gap='gac -o "%e" "%f"',go='go build "%f"',groovy='groovyc "%f"',hare='hare build -o "%e" "%f"',haskell=WIN32 and 'ghc -o "%e.exe" "%f"' or 'ghc -o "%e" "%f"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%f"',ltx='pdflatex -file-line-error -halt-on-error "%f"',less='lessc --no-color "%f" "%e.css"',lilypond='lilypond "%f"',lisp='clisp -c "%f"',litcoffee='coffee -c "%f"',lua='luac -o "%e.luac" "%f"',moon='moonc "%f"',markdown='markdown "%f" > "%e.html"',myr='mbld -b "%e" "%f"',nemerle='ncc "%f" -out:"%e.exe"',nim='nim c "%f"',nsis='MakeNSIS "%f"',objective_c='gcc -o "%e" "%f"',pascal='fpc "%f"',perl='perl -c "%f"',php='php -l "%f"',pony='ponyc "%f"',prolog='gplc --no-top-level "%f"',python='python -m py_compile "%f"',ruby='ruby -c "%f"',rust='rustc "%f"',sass='sass "%f" "%e.css"',scala='scalac "%f"',sml='mlton "%f"',tex='pdflatex -file-line-error -halt-on-error "%f"',typescript='tsc "%f"',vala='valac "%f"',vb=WIN32 and 'vbc "%f"' or 'vbnc "%f"',zig='zig build-exe "%f"'}
-- LuaFormatter on

--- Prompts the user with the command entry to compile file *filename* or the current file using
-- an appropriate shell command from the `textadept.run.compile_commands` table.
-- The shell command is determined from the file's filename, extension, or language, in that order.
-- Emits `events.COMPILE_OUTPUT`.
-- @param[opt=buffer.filename] filename Optional path to the file to compile.
function M.compile(filename)
	if not assert_type(filename, 'string/nil', 1) and not buffer.filename then return end
	compile_or_run(filename or buffer.filename, M.compile_commands)
end

--- Map of filenames, file extensions, and lexer names to their associated "run" shell command
-- line strings or functions that return strings.
-- Command line strings may have the following macros:
--
-- - `%f`: The file's name, including its extension.
-- - `%e`: The file's name, excluding its extension.
-- - `%d`: The file's directory path.
-- - `%p`: The file's full path.
--
-- Functions may also return a working directory and process environment table to operate in. By
-- default, the working directory is the current file's parent directory and the environment
-- is Textadept's environment.
-- @table run_commands

-- LuaFormatter off
M.run_commands = {actionscript=WIN32 and 'start "" "%e.swf"' or OSX and 'open "file://%e.swf"' or 'xdg-open "%e.swf"',ada=WIN32 and '"%e"' or '"./%e"',c=WIN32 and '"%e"' or '"./%e"',applescript='osascript "%f"',asm='"./%e"',awk='awk -f "%f"',batch='"%f"',boo='booi "%f"',caml='ocamlrun "%e"',csharp=WIN32 and '"%e"' or 'mono "%e.exe"',chuck='chuck "%f"',clojure='clj -M "%f"',cmake='cmake -P "%f"',coffeescript='coffee "%f"',context=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',cpp=WIN32 and '"%e"' or '"./%e"',crystal='crystal "%f"',cuda=WIN32 and '"%e"' or '"./%e"',dart='dart "%f"',dmd=WIN32 and '"%e"' or '"./%e"',eiffel="./a.out",elixir='elixir "%f"',fsharp=WIN32 and '"%e"' or 'mono "%e.exe"',fantom='fan "%f"',fennel='fennel "%f"',forth='gforth "%f" -e bye',fortran=WIN32 and '"%e"' or '"./%e"',gnuplot='gnuplot "%f"',go='go run "%f"',groovy='groovy "%f"',hare='hare run "%f"',haskell=WIN32 and '"%e"' or '"./%e"',html=WIN32 and 'start "" "%f"' or OSX and 'open "file://%f"' or 'xdg-open "%f"',icon='icont "%e" -x',idl='idl -batch "%f"',Io='io "%f"',java='java "%e"',javascript='node "%f"',jq='jq -f "%f"',julia='julia "%f"',ltx=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',less='lessc --no-color "%f"',lilypond=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',lisp='clisp "%f"',litcoffee='coffee "%f"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%f"',makefile=WIN32 and 'nmake -f "%f"' or 'make -f "%f"',markdown='markdown "%f"',moon='moon "%f"',myr=WIN32 and '"%e"' or '"./%e"',nemerle=WIN32 and '"%e"' or 'mono "%e.exe"',nim='nim c -r "%f"',objective_c=WIN32 and '"%e"' or '"./%e"',pascal=WIN32 and '"%e"' or '"./%e"',perl='perl "%f"',php='php "%f"',pike='pike "%f"',pkgbuild='makepkg -p "%f"',pony=WIN32 and '"%e"' or '"./%e"',prolog=WIN32 and '"%e"' or '"./%e"',pure='pure "%f"',python=function() return buffer:get_line(1):find('^#!.-python3') and 'python3 -u "%f"' or 'python -u "%f"' end,rstats=WIN32 and 'Rterm -f "%f"' or 'R -f "%f"',rebol='REBOL "%f"',rexx=WIN32 and 'rexx "%f"' or 'regina "%f"',ruby='ruby "%f"',rust=WIN32 and '"%e"' or '"./%e"',sass='sass "%f"',scala='scala "%e"',bash='bash "%f"',csh='tcsh "%f"',ksh='ksh "%f"',mksh='mksh "%f"',sh='sh "%f"',zsh='zsh "%f"',rc='rc "%f"',smalltalk='gst "%f"',sml=WIN32 and '"%e"' or '"./%e"',snobol4='snobol4 -b "%f"',tcl='tclsh "%f"',tex=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',vala=WIN32 and '"%e"' or '"./%e"',vb=WIN32 and '"%e"' or 'mono "%e.exe"',xs='xs "%f"',zig=WIN32 and '"%e"' or '"./%e"'}
-- LuaFormatter on

--- Prompts the user with the command entry to run file *filename* or the current file using an
-- appropriate shell command from the `textadept.run.run_commands` table.
-- The shell command is determined from the file's filename, extension, or language, in that order.
-- Emits `events.RUN_OUTPUT`.
-- @param[opt=buffer.filename] filename Optional path to the file to run.
function M.run(filename)
	if not assert_type(filename, 'string/nil', 1) and not buffer.filename then return end
	compile_or_run(filename or buffer.filename, M.run_commands)
end

--- Map of project root paths and "makefiles" to their associated "build" shell command line
-- strings or functions that return such strings.
-- Functions may also return a working directory and process environment table to operate
-- in. By default, the working directory is the project's root directory and the environment
-- is Textadept's environment.
-- @table build_commands

-- LuaFormatter off
M.build_commands = {--[[Ant]]['build.xml']='ant',--[[Dockerfile]]Dockerfile='docker build .',--[[Make]]Makefile='make',GNUmakefile='make',makefile='make',--[[Meson]]['meson.build']='meson compile',--[[Maven]]['pom.xml']='mvn',--[[Ruby]]Rakefile='rake'}
-- LuaFormatter on

--- Prompts the user with the command entry to build the project whose root path is *dir*
-- or the current project using the shell command from the `textadept.run.build_commands` table.
-- The current project is determined by either the buffer's filename or the current working
-- directory.
-- Emits `events.BUILD_OUTPUT`.
-- @param[opt] dir Optional path to the project to build. The default value is the current project.
function M.build(dir)
	if not assert_type(dir, 'string/nil', 1) then
		dir = io.get_project_root()
		if not dir then return end
	end
	for _, buffer in ipairs(_BUFFERS) do buffer:annotation_clear_all() end
	local cmd = M.build_commands[dir]
	if not cmd then
		for build_file, build_command in pairs(M.build_commands) do
			if lfs.attributes(string.format('%s/%s', dir, build_file)) then
				cmd = build_command
				break
			end
		end
	end
	run_command(_L['Build command:'], cmd, dir, events.BUILD_OUTPUT, M.build_commands, dir)
end

--- Map of project root paths to their associated "test" shell command line strings or functions
-- that return such strings.
-- Functions may also return a working directory and process environment table to operate
-- in. By default, the working directory is the project's root directory and the environment
-- is Textadept's environment.
M.test_commands = {}

--- Prompts the user with the command entry to run tests for the project whose root path is *dir*
-- or the current project using the shell command from the `textadept.run.test_commands` table.
-- The current
-- project is determined by either the buffer's filename or the current working directory.
-- Emits `events.TEST_OUTPUT`.
-- @param[opt] dir Optional path to the project to run tests for. The default value is the
--	current project.
function M.test(dir)
	if not assert_type(dir, 'string/nil', 1) then
		dir = io.get_project_root()
		if not dir then return end
	end
	for _, buffer in ipairs(_BUFFERS) do buffer:annotation_clear_all() end
	local cmd = M.test_commands[dir]
	run_command(_L['Test command:'], cmd, dir, events.TEST_OUTPUT, M.test_commands, dir)
end

--- Map of project root paths to their associated "run" shell command line strings or functions
-- that return such strings.
-- Functions may also return a working directory and process environment table to operate
-- in. By default, the working directory is the project's root directory and the environment
-- is Textadept's environment.
M.run_project_commands = {}

--- Prompts the user with the command entry to run shell command *cmd* or the shell command
-- from the `textadept.run.run_project_commands` table for the project whose root path is *dir*
-- or the current project.
-- The current project is determined by either the buffer's filename or the current working
-- directory.
-- Emits `events.RUN_OUTPUT`.
-- @param[opt] dir Optional path to the project to run a command for. The default value is the
--	current project.
-- @param[optchain] cmd Optional string command to run. If given, the command entry initially
--	shows this command. The default value comes from `textadept.run.run_project_commands`
--	and *dir*.
function M.run_project(dir, cmd)
	if not assert_type(dir, 'string/nil', 1) then
		dir = io.get_project_root()
		if not dir then return end
	end
	if not assert_type(cmd, 'string/nil', 2) then cmd = M.run_project_commands[dir] end
	run_command(_L['Project run command:'], cmd, dir, events.RUN_OUTPUT, M.run_project_commands, dir)
end

--- Stops the currently running process, if any.
-- If there is more than one running process, the user is prompted to select the process to stop.
-- Processes in the list are sorted from longest lived at the top to shortest lived on the bottom.
function M.stop()
	for i = #procs, 1, -1 do if procs[i].proc:status() ~= 'running' then table.remove(procs, i) end end
	if #procs == 0 then return end
	local utf8_cmds = {}
	for _, proc in ipairs(procs) do utf8_cmds[#utf8_cmds + 1] = proc.command:iconv('UTF-8', _CHARSET) end
	local selected = #procs == 1 and {1} or
		ui.dialogs.list{title = _L['Stop Process'], items = utf8_cmds, multiple = true}
	if selected then for _, i in ipairs(selected) do procs[i].proc:kill() end end
end

-- Send line as input to process stdin on return.
events.connect(events.CHAR_ADDED, function(code)
	local proc = #procs > 0 and procs[#procs].proc or nil
	if code == string.byte('\n') and proc and proc:status() == 'running' and is_out_buf(buffer) then
		local line_num = buffer:line_from_position(buffer.current_pos) - 1
		proc:write(buffer:get_line(line_num))
	end
end)

--- Returns text tagged with the given output lexer tag on the given line number.
-- @param line_num Line number to get text from.
-- @param tag String tag name, either 'filename', 'line', 'column', or 'message'.
-- @return tagged text or nil if none was found
local function get_tagged_text(line_num, tag)
	for pos = buffer:position_from_line(line_num), buffer.line_end_position[line_num] do
		local style = buffer.style_at[pos]
		if buffer:name_of_style(style) == tag then
			local s, e = pos, pos
			repeat e = e + 1 until e > buffer.length or buffer.style_at[e] ~= style
			return buffer:text_range(s, e)
		end
	end
end

--- Jumps to the source of the next or previous recognized compile/run warning or error in
-- the output buffer, or the warning/error on a given line number, depending on the value
-- of *location*.
-- Displays an annotation with the warning or error message if possible.
-- @param location When `true`, jumps to the next recognized warning/error. When `false`,
--	jumps to the previous one. When a line number, jumps to it.
function M.goto_error(location)
	local line_num = type(assert_type(location, 'boolean/number', 1)) == 'number' and location
	local output_view, output_buffer = get_output_view(), get_output_buffer()
	if not output_view and not output_buffer then return end
	if output_view then
		ui.goto_view(output_view)
	else
		view:goto_buffer(output_buffer)
	end

	-- If no line number was given, find the next warning or error marker.
	if not line_num then
		local f, next = location and buffer.marker_next or buffer.marker_previous, location
		line_num = buffer:line_from_position(buffer.current_pos)
		local WARN_BIT, ERROR_BIT = 1 << M.MARK_WARNING - 1, 1 << M.MARK_ERROR - 1
		local wrapped = false
		::retry::
		local wline = f(buffer, line_num + (next and 1 or -1), WARN_BIT)
		local eline = f(buffer, line_num + (next and 1 or -1), ERROR_BIT)
		if wline == -1 and eline == -1 then
			wline = f(buffer, next and 1 or buffer.line_count, WARN_BIT)
			eline = f(buffer, next and 1 or buffer.line_count, ERROR_BIT)
		elseif wline == -1 or eline == -1 then
			if wline == -1 then
				wline = eline
			else
				eline = wline
			end
		end
		line_num = (next and math.min or math.max)(wline, eline)
		if line_num == -1 and not wrapped then
			line_num = next and 1 or buffer.line_count
			wrapped = true
			goto retry
		end
	end

	-- Go to the warning or error and show an annotation.
	if buffer.line_state[line_num] == 0 then return end
	local filename = get_tagged_text(line_num, 'filename')
	if filename == '' then return end -- incorrectly tagged message
	local line = tonumber(get_tagged_text(line_num, 'line') or '')
	local column = tonumber(get_tagged_text(line_num, 'column') or '')
	local message = get_tagged_text(line_num, 'message')
	buffer:goto_line(line_num)
	textadept.editing.select_line()
	if not filename:find(not WIN32 and '^/' or '^%a?:?[/\\][/\\]?') then
		for i = line_num, 1, -1 do
			local cwd = buffer:get_line(i):match('^> cd ([^\n]+)')
			if cwd then
				filename = cwd .. (not WIN32 and '/' or '\\') .. filename
				break
			end
		end
	end
	local sloppy = not filename:find(not WIN32 and '^/' or '^%a?:?[/\\][/\\]?')
	ui.goto_file(filename, true, preferred_view, sloppy)
	textadept.editing.goto_line(line)
	if column then buffer:goto_pos(buffer:position_relative(buffer.current_pos, column - 1)) end
	if not message then return end
	buffer.annotation_text[line] = message
	if buffer.line_state[line_num] > 1 then return end -- non-error
	buffer.annotation_style[line] = buffer:style_of_name(lexer.ERROR)
end

-- Jump to the error or warning when pressing Enter.
events.connect(events.KEYPRESS, function(key)
	local line_num = buffer:line_from_position(buffer.current_pos)
	if key ~= '\n' or not is_out_buf(buffer) or buffer.line_state[line_num] == 0 then return end
	M.goto_error(line_num)
	return true
end)

-- Jump to the error or warning when double-clicking a line.
events.connect(events.DOUBLE_CLICK,
	function(_, line) if is_out_buf(buffer) then M.goto_error(line) end end)

return M

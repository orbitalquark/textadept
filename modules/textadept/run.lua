-- Copyright 2007-2022 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile and run source code files with Textadept.
-- [Language modules](#compile-and-run) may tweak the `compile_commands`, and `run_commands`
-- tables for particular languages.
-- The user may tweak `build_commands` and `test_commands` for particular projects.
-- @field run_in_background (bool)
--   Run shell commands silently in the background.
--   This only applies when the output buffer is open, though it does not have to be visible.
--   The default value is `false`.
-- @field MARK_WARNING (number)
--   The run or compile warning marker number.
-- @field MARK_ERROR (number)
--   The run or compile error marker number.
-- @field _G.events.COMPILE_OUTPUT (string)
--   Emitted when executing a language's compile shell command.
--   By default, compiler output is printed to the output buffer. In order to override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
-- @field _G.events.RUN_OUTPUT (string)
--   Emitted when executing a language's run shell command.
--   By default, output is printed to the output buffer. In order to override this behavior,
--   connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
-- @field _G.events.BUILD_OUTPUT (string)
--   Emitted when executing a project's build shell command.
--   By default, output is printed to the output buffer. In order to override this behavior,
--   connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
-- @field _G.events.TEST_OUTPUT (string)
--   Emitted when executing a project's shell command for running tests.
--   By default, output is printed to the output buffer. In order to override this behavior,
--   connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
module('textadept.run')]]

M.run_in_background = false

M.MARK_WARNING = _SCINTILLA.next_marker_number()
M.MARK_ERROR = _SCINTILLA.next_marker_number()

-- Events.
local run_events = {'compile_output', 'run_output', 'build_output', 'test_output'}
for _, event in ipairs(run_events) do events[event:upper()] = event end

-- Keep track of: the last process spawned in order to kill it if requested; the cwd of that
-- process in order to jump to relative file paths in recognized warning or error messages;
-- and the view the process was spawned from in order to jump to messages (which are displayed
-- in a split view) in the original view.
local proc, cwd, preferred_view

-- Returns whether or not the given buffer is the output buffer.
local function is_out_buf(buf) return buf._type == _L['[Output Buffer]'] end

-- Helper functions for getting the output view and buffer.
local function get_output_view()
  for _, view in ipairs(_VIEWS) do if is_out_buf(view.buffer) then return view end end
end
local function get_output_buffer()
  for _, buf in ipairs(_BUFFERS) do if is_out_buf(buf) then return buf end end
end

local line_state_marks = {M.MARK_ERROR, M.MARK_WARNING}
-- Prints output from a compile, run, build, or test shell command.
-- Any filenames encoded in _CHARSET are left alone and may not display properly.
-- All stdout and stderr from the command is printed silently.
-- @param output The output to print.
local function print_output(output)
  local buffer = get_output_buffer()
  local last_line = buffer and buffer.line_count or 1
  local silent = M.run_in_background or not output:find('^> ') or output:find('^> exit')
  ui[silent and 'output_silent' or 'output'](output)
  if not buffer then buffer = get_output_buffer() end
  for i = last_line, buffer.line_count - 1 do -- ui.output() outputs trailing '\n'
    local line_state = buffer.line_state[i]
    if line_state > 0 then buffer:marker_add(i, line_state_marks[line_state]) end
  end
end
for _, event in ipairs(run_events) do events.connect(event, print_output) end

-- Runs command *command* in working directory *dir*, emitting events of type *event* with any
-- output received.
-- @param command String command to run, or a function returning such a string and optional
--   working directory and environment table. A returned working directory overrides *dir*.
-- @param dir String working directory to run *command* in.
-- @param event String event name to emit command output with.
-- @param macros Optional table of '%[char]' macros to expand within *command*.
local function run_command(command, dir, event, macros)
  local working_dir, env
  if type(command) == 'function' then command, working_dir, env = command() end
  if not command or command == '' then return end
  if macros then command = command:gsub('%%%a', macros) end
  preferred_view = view
  local function emit(output) events.emit(event, output) end
  cwd = (working_dir or dir):gsub('[/\\]$', '')
  events.emit(event, string.format('> cd %s\n', cwd))
  events.emit(event, string.format('> %s\n', command:iconv('UTF-8', _CHARSET)))
  local args = {
    command, cwd, emit, emit,
    function(status) events.emit(event, string.format('> exit status: %d\n', status)) end
  }
  if env then table.insert(args, 3, env) end
  proc = assert(os.spawn(table.unpack(args)))
end

-- Compiles or runs file *filename* based on a shell command in *commands*.
-- @param filename The file to run.
-- @param commands Either `compile_commands` or `run_commands`.
local function compile_or_run(filename, commands)
  if filename == buffer.filename then
    buffer:annotation_clear_all()
    if buffer.modify then buffer:save() end
  end
  local ext = filename:match('[^/\\.]+$')
  local lang = filename == buffer.filename and buffer.lexer_language or
    textadept.file_types.extensions[ext]
  local command = commands[filename] or commands[ext] or commands[lang]
  local dirname, basename = '', filename
  if filename:find('[/\\]') then dirname, basename = filename:match('^(.+)[/\\]([^/\\]+)$') end
  local event = commands == M.compile_commands and events.COMPILE_OUTPUT or events.RUN_OUTPUT
  local macros = {
    ['%p'] = filename, ['%d'] = dirname, ['%f'] = basename, ['%e'] = basename:match('^(.+)%.') -- no extension
  }
  run_command(command, dirname, event, macros)
end

-- LuaFormatter off
---
-- Map of filenames, file extensions, and lexer names to their associated "compile" shell
-- command line strings or functions that return such strings.
-- Command line strings may have the following macros:
--
--   + `%f`: The file's name, including its extension.
--   + `%e`: The file's name, excluding its extension.
--   + `%d`: The file's directory path.
--   + `%p`: The file's full path.
--
-- Functions may also return a working directory and process environment table to operate in. By
-- default, the working directory is the current file's parent directory and the environment
-- is Textadept's environment.
-- @class table
-- @name compile_commands
M.compile_commands = {actionscript='mxmlc "%f"',ada='gnatmake "%f"',ansi_c='gcc -o "%e" "%f"',antlr='antlr4 "%f"',g='antlr3 "%f"',applescript='osacompile "%f" -o "%e.scpt"',asm='nasm "%f"'--[[ && ld "%e.o" -o "%e"']],boo='booc "%f"',caml='ocamlc -o "%e" "%f"',csharp=WIN32 and 'csc "%f"' or 'mcs "%f"',coffeescript='coffee -c "%f"',context='context --nonstopmode "%f"',cpp='g++ -o "%e" "%f"',cuda=WIN32 and 'nvcc -o "%e.exe" "%f"' or 'nvcc -o "%e" "%f"',dmd='dmd "%f"',dot='dot -Tps "%f" -o "%e.ps"',eiffel='se c "%f"',elixir='elixirc "%f"',erlang='erl -compile "%e"',faust='faust -o "%e.cpp" "%f"',fsharp=WIN32 and 'fsc.exe "%f"' or 'mono fsc.exe "%f"',fortran='gfortran -o "%e" "%f"',gap='gac -o "%e" "%f"',go='go build "%f"',groovy='groovyc "%f"',hare='hare build -o "%e" "%f"',haskell=WIN32 and 'ghc -o "%e.exe" "%f"' or 'ghc -o "%e" "%f"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%f"',ltx='pdflatex -file-line-error -halt-on-error "%f"',less='lessc --no-color "%f" "%e.css"',lilypond='lilypond "%f"',lisp='clisp -c "%f"',litcoffee='coffee -c "%f"',lua='luac -o "%e.luac" "%f"',moon='moonc "%f"',markdown='markdown "%f" > "%e.html"',myr='mbld -b "%e" "%f"',nemerle='ncc "%f" -out:"%e.exe"',nim='nim c "%f"',nsis='MakeNSIS "%f"',objective_c='gcc -o "%e" "%f"',pascal='fpc "%f"',perl='perl -c "%f"',php='php -l "%f"',pony='ponyc "%f"',prolog='gplc --no-top-level "%f"',python='python -m py_compile "%f"',ruby='ruby -c "%f"',rust='rustc "%f"',sass='sass "%f" "%e.css"',scala='scalac "%f"',sml='mlton "%f"',tex='pdflatex -file-line-error -halt-on-error "%f"',typescript='tsc "%f"',vala='valac "%f"',vb=WIN32 and 'vbc "%f"' or 'vbnc "%f"',zig='zig build-exe "%f"'}
-- LuaFormatter on

---
-- Compiles file *filename* or the current file using an appropriate shell command from the
-- `compile_commands` table.
-- The shell command is determined from the file's filename, extension, or language in that order.
-- Emits `COMPILE_OUTPUT` events.
-- @param filename Optional path to the file to compile. The default value is the current
--   file's filename.
-- @see compile_commands
-- @see _G.events
-- @name compile
function M.compile(filename)
  if assert_type(filename, 'string/nil', 1) or buffer.filename then
    compile_or_run(filename or buffer.filename, M.compile_commands)
  end
end

-- LuaFormatter off
---
-- Map of filenames, file extensions, and lexer names to their associated "run" shell command
-- line strings or functions that return strings.
-- Command line strings may have the following macros:
--
--   + `%f`: The file's name, including its extension.
--   + `%e`: The file's name, excluding its extension.
--   + `%d`: The file's directory path.
--   + `%p`: The file's full path.
--
-- Functions may also return a working directory and process environment table to operate in. By
-- default, the working directory is the current file's parent directory and the environment
-- is Textadept's environment.
-- @class table
-- @name run_commands
M.run_commands = {actionscript=WIN32 and 'start "" "%e.swf"' or OSX and 'open "file://%e.swf"' or 'xdg-open "%e.swf"',ada=WIN32 and '"%e"' or '"./%e"',ansi_c=WIN32 and '"%e"' or '"./%e"',applescript='osascript "%f"',asm='"./%e"',awk='awk -f "%f"',batch='"%f"',boo='booi "%f"',caml='ocamlrun "%e"',csharp=WIN32 and '"%e"' or 'mono "%e.exe"',chuck='chuck "%f"',clojure='clj -M "%f"',cmake='cmake -P "%f"',coffeescript='coffee "%f"',context=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',cpp=WIN32 and '"%e"' or '"./%e"',crystal='crystal "%f"',cuda=WIN32 and '"%e"' or '"./%e"',dart='dart "%f"',dmd=WIN32 and '"%e"' or '"./%e"',eiffel="./a.out",elixir='elixir "%f"',fsharp=WIN32 and '"%e"' or 'mono "%e.exe"',fantom='fan "%f"',fennel='fennel "%f"',forth='gforth "%f" -e bye',fortran=WIN32 and '"%e"' or '"./%e"',gnuplot='gnuplot "%f"',go='go run "%f"',groovy='groovy "%f"',hare='hare run "%f"',haskell=WIN32 and '"%e"' or '"./%e"',html=WIN32 and 'start "" "%f"' or OSX and 'open "file://%f"' or 'xdg-open "%f"',icon='icont "%e" -x',idl='idl -batch "%f"',Io='io "%f"',java='java "%e"',javascript='node "%f"',jq='jq -f "%f"',julia='julia "%f"',ltx=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',less='lessc --no-color "%f"',lilypond=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',lisp='clisp "%f"',litcoffee='coffee "%f"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%f"',makefile=WIN32 and 'nmake -f "%f"' or 'make -f "%f"',markdown='markdown "%f"',moon='moon "%f"',myr=WIN32 and '"%e"' or '"./%e"',nemerle=WIN32 and '"%e"' or 'mono "%e.exe"',nim='nim c -r "%f"',objective_c=WIN32 and '"%e"' or '"./%e"',pascal=WIN32 and '"%e"' or '"./%e"',perl='perl "%f"',php='php "%f"',pike='pike "%f"',pkgbuild='makepkg -p "%f"',pony=WIN32 and '"%e"' or '"./%e"',prolog=WIN32 and '"%e"' or '"./%e"',pure='pure "%f"',python=function() return buffer:get_line(1):find('^#!.-python3') and 'python3 -u "%f"' or 'python -u "%f"' end,rstats=WIN32 and 'Rterm -f "%f"' or 'R -f "%f"',rebol='REBOL "%f"',rexx=WIN32 and 'rexx "%f"' or 'regina "%f"',ruby='ruby "%f"',rust=WIN32 and '"%e"' or '"./%e"',sass='sass "%f"',scala='scala "%e"',bash='bash "%f"',csh='tcsh "%f"',ksh='ksh "%f"',mksh='mksh "%f"',sh='sh "%f"',zsh='zsh "%f"',rc='rc "%f"',smalltalk='gst "%f"',sml=WIN32 and '"%e"' or '"./%e"',snobol4='snobol4 -b "%f"',tcl='tclsh "%f"',tex=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',vala=WIN32 and '"%e"' or '"./%e"',vb=WIN32 and '"%e"' or 'mono "%e.exe"',xs='xs "%f"',zig=WIN32 and '"%e"' or '"./%e"'}
-- LuaFormatter on

---
-- Runs file *filename* or the current file using an appropriate shell command from the
-- `run_commands` table.
-- The shell command is determined from the file's filename, extension, or language in that order.
-- Emits `RUN_OUTPUT` events.
-- @param filename Optional path to the file to run. The default value is the current file's
--   filename.
-- @see run_commands
-- @see _G.events
-- @name run
function M.run(filename)
  if assert_type(filename, 'string/nil', 1) or buffer.filename then
    compile_or_run(filename or buffer.filename, M.run_commands)
  end
end

---
-- Appends the command line argument strings *run* and *compile* to their respective run and
-- compile commands for file *filename* or the current file.
-- If either is `nil`, prompts the user for missing the arguments. Each filename has its own
-- set of compile and run arguments.
-- @param filename Optional path to the file to set run/compile arguments for.
-- @param run Optional string run arguments to set. If `nil`, the user is prompted for them. Pass
--   the empty string for no run arguments.
-- @param compile Optional string compile arguments to set. If `nil`, the user is prompted
--   for them. Pass the empty string for no compile arguments.
-- @see run_commands
-- @see compile_commands
-- @name set_arguments
function M.set_arguments(filename, run, compile)
  if not assert_type(filename, 'string/nil', 1) then
    filename = buffer.filename
    if not filename then return end
  end
  assert_type(run, 'string/nil', 2)
  assert_type(compile, 'string/nil', 3)
  local base_commands, utf8_args = {}, {}
  for i, commands in ipairs{M.run_commands, M.compile_commands} do
    -- Compare the base run/compile command with the one for the current file. The difference
    -- is any additional arguments set previously.
    base_commands[i] = commands[filename:match('[^.]+$')] or commands[buffer.lexer_language] or ''
    local current_command = commands[filename] or ''
    local args = (i == 1 and run or compile) or current_command:sub(#base_commands[i] + 2)
    utf8_args[i] = args:iconv('UTF-8', _CHARSET)
  end
  if not run or not compile then
    local button
    button, utf8_args = ui.dialogs.inputbox{
      title = _L['Set Arguments...']:gsub('_', ''),
      informative_text = {_L['Command line arguments'], _L['For Run:'], _L['For Compile:']},
      text = utf8_args, width = not CURSES and 400 or nil
    }
    if button ~= 1 then return end
  end
  for i, commands in ipairs{M.run_commands, M.compile_commands} do
    -- Add the additional arguments to the base run/compile command and set the new command to
    -- be the one used for the current file.
    commands[filename] = string.format('%s %s', base_commands[i],
      utf8_args[i]:iconv(_CHARSET, 'UTF-8'))
  end
end

-- LuaFormatter off
---
-- Map of project root paths and "makefiles" to their associated "build" shell command line
-- strings or functions that return such strings.
-- Functions may also return a working directory and process environment table to operate
-- in. By default, the working directory is the project's root directory and the environment
-- is Textadept's environment.
-- @class table
-- @name build_commands
M.build_commands = {--[[Ant]]['build.xml']='ant',--[[Dockerfile]]Dockerfile='docker build .',--[[Make]]Makefile='make',GNUmakefile='make',makefile='make',--[[Meson]]['meson.build']='meson compile',--[[Maven]]['pom.xml']='mvn',--[[Ruby]]Rakefile='rake'}
-- LuaFormatter on

---
-- Builds the project whose root path is *root_directory* or the current project using the
-- shell command from the `build_commands` table.
-- If a "makefile" type of build file is found, prompts the user for the full build command. The
-- current project is determined by either the buffer's filename or the current working directory.
-- Emits `BUILD_OUTPUT` events.
-- @param root_directory The path to the project to build. The default value is the current project.
-- @see build_commands
-- @see _G.events
-- @name build
function M.build(root_directory)
  if not assert_type(root_directory, 'string/nil', 1) then
    root_directory = io.get_project_root()
    if not root_directory then return end
  end
  for i = 1, #_BUFFERS do _BUFFERS[i]:annotation_clear_all() end
  local command = M.build_commands[root_directory]
  if not command then
    for build_file, build_command in pairs(M.build_commands) do
      if lfs.attributes(string.format('%s/%s', root_directory, build_file)) then
        local button, utf8_command = ui.dialogs.inputbox{
          title = _L['Command'], informative_text = root_directory, text = build_command,
          button1 = _L['OK'], button2 = _L['Cancel']
        }
        if button == 1 then command = utf8_command:iconv(_CHARSET, 'UTF-8') end
        break
      end
    end
  end
  run_command(command, root_directory, events.BUILD_OUTPUT)
end

---
-- Map of project root paths to their associated "test" shell command line strings or functions
-- that return such strings.
-- Functions may also return a working directory and process environment table to operate
-- in. By default, the working directory is the project's root directory and the environment
-- is Textadept's environment.
-- @class table
-- @name test_commands
M.test_commands = {}

---
-- Runs tests for the project whose root path is *root_directory* or the current project using
-- the shell command from the `test_commands` table.
-- The current project is determined by either the buffer's filename or the current working
-- directory.
-- Emits `TEST_OUTPUT` events.
-- @param root_directory The path to the project to run tests for. The default value is the
--   current project.
-- @see test_commands
-- @see _G.events
-- @name test
function M.test(root_directory)
  if not assert_type(root_directory, 'string/nil', 1) then
    root_directory = io.get_project_root()
    if not root_directory then return end
  end
  for i = 1, #_BUFFERS do _BUFFERS[i]:annotation_clear_all() end
  run_command(M.test_commands[root_directory], root_directory, events.TEST_OUTPUT)
end

---
-- Stops the currently running process, if any.
-- @name stop
function M.stop() if proc then proc:kill() end end

-- Send line as input to process stdin on return.
events.connect(events.CHAR_ADDED, function(code)
  if code == string.byte('\n') and proc and proc:status() == 'running' and is_out_buf(buffer) then
    local line_num = buffer:line_from_position(buffer.current_pos) - 1
    proc:write(buffer:get_line(line_num))
  end
end)

-- Returns text tagged with the given output lexer tag on the given line number.
-- @param line_num Line number to get text from.
-- @param tag String tag name, either 'filename', 'line', 'column', or 'message'.
-- @param tagged text or nil if none was found
local function get_tagged_text(line_num, tag)
  for pos = buffer:position_from_line(line_num), buffer.line_end_position[line_num] do
    local style = buffer.style_at[pos]
    if buffer:name_of_style(style) ~= tag then goto continue end
    local s, e = pos, pos
    repeat e = e + 1 until e > buffer.length or buffer.style_at[e] ~= style
    do return buffer:text_range(s, e) end
    ::continue::
  end
end

---
-- Jumps to the source of the recognized compile/run warning or error on line number *line_num*
-- in the output buffer.
-- If *line_num* is `nil`, jumps to the next or previous warning or error, depending on boolean
-- *next*. Displays an annotation with the warning or error message if possible.
-- @param line_num Optional line number in the output buffer that contains the compile/run
--   warning or error to go to. This parameter may be omitted completely.
-- @param next Optional flag indicating whether to go to the next recognized warning/error or
--   the previous one. Only applicable when *line_num* is `nil`.
-- @name goto_error
function M.goto_error(line_num, next)
  if type(line_num) == 'boolean' then line_num, next = nil, line_num end
  local output_view, output_buffer = get_output_view(), get_output_buffer()
  if not output_view and not output_buffer then return end
  if output_view then
    ui.goto_view(output_view)
  else
    view:goto_buffer(output_buffer)
  end

  -- If no line number was given, find the next warning or error marker.
  if not assert_type(line_num, 'number/nil', 1) and next ~= nil then
    local f = next and buffer.marker_next or buffer.marker_previous
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

  -- Goto the warning or error and show an annotation.
  if buffer.line_state[line_num] == 0 then return end
  local filename = get_tagged_text(line_num, 'filename')
  if filename == '' then return end -- incorrectly tagged message
  local line = tonumber(get_tagged_text(line_num, 'line') or '')
  local column = tonumber(get_tagged_text(line_num, 'column') or '')
  local message = get_tagged_text(line_num, 'message')
  buffer:goto_line(line_num)
  textadept.editing.select_line()
  if not filename:find(not WIN32 and '^/' or '^%a?:?[/\\][/\\]?') and cwd then
    filename = cwd .. (not WIN32 and '/' or '\\') .. filename
  end
  local sloppy = not filename:find(not WIN32 and '^/' or '^%a?:?[/\\][/\\]?')
  ui.goto_file(filename, true, preferred_view, sloppy)
  textadept.editing.goto_line(line)
  if column then buffer:goto_pos(buffer:find_column(line, column)) end
  if not message then return end
  buffer.annotation_text[line] = message
  if buffer.line_state[line_num] > 1 then return end -- non-error
  buffer.annotation_style[line] = buffer:style_of_name('error')
end
events.connect(events.KEYPRESS, function(code)
  local line_num = buffer:line_from_position(buffer.current_pos)
  if keys.KEYSYMS[code] == '\n' and is_out_buf(buffer) and buffer.line_state[line_num] > 0 then
    M.goto_error(line_num)
    return true
  end
end)
events.connect(events.DOUBLE_CLICK,
  function(_, line) if is_out_buf(buffer) then M.goto_error(line) end end)

return M

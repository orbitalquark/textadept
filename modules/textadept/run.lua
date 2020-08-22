-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile and run source code files with Textadept.
-- [Language modules](#_M.Compile.and.Run) may tweak the `compile_commands`,
-- `run_commands`, and `error_patterns` tables for particular languages.
-- The user may tweak `build_commands` for particular projects.
-- @field run_in_background (bool)
--   Run shell commands silently in the background.
--   This only applies when the message buffer is open, though it does not have
--   to be visible.
--   The default value is `false`.
-- @field MARK_WARNING (number)
--   The run or compile warning marker number.
-- @field MARK_ERROR (number)
--   The run or compile error marker number.
-- @field _G.events.COMPILE_OUTPUT (string)
--   Emitted when executing a language's compile shell command.
--   By default, compiler output is printed to the message buffer. In order to
--   override this behavior, connect to the event with an index of `1` and
--   return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
--   * `ext_or_lexer`: The file extension or lexer name associated with the
--     executed compile command.
-- @field _G.events.RUN_OUTPUT (string)
--   Emitted when executing a language's run shell command.
--   By default, output is printed to the message buffer. In order to override
--   this behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
--   * `ext_or_lexer`: The file extension or lexer name associated with the
--     executed run command.
-- @field _G.events.BUILD_OUTPUT (string)
--   Emitted when executing a project's build shell command.
--   By default, output is printed to the message buffer. In order to override
--   this behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `output`: A line of string output from the command.
module('textadept.run')]]

M.run_in_background = false

M.MARK_WARNING = _SCINTILLA.next_marker_number()
M.MARK_ERROR = _SCINTILLA.next_marker_number()

-- Events.
events.COMPILE_OUTPUT, events.RUN_OUTPUT = 'compile_output', 'run_output'
events.BUILD_OUTPUT = 'build_output'

-- Keep track of: the last process spawned in order to kill it if requested; the
-- cwd of that process in order to jump to relative file paths in recognized
-- warning or error messages; and the view the process was spawned from in order
-- to jump to messages (which are displayed in a split view) in the original
-- view.
local proc, cwd, preferred_view

-- Scans the given message for a warning or error message and, if one is found,
-- returns table of the warning/error's details.
-- @param message The message to parse for warnings or errors. The message
--   is assumed to be encoded in _CHARSET.
-- @param ext_or_lexer Optional file extension or lexer name associated with the
--   shell command that produced the warning/error.
-- @return error details table with 'filename', 'line', 'column', and 'message'
--   fields along with a 'warning' flag.
-- @see error_patterns
local function scan_for_error(message, ext_or_lexer)
  for key, patterns in pairs(M.error_patterns) do
    if ext_or_lexer and key ~= ext_or_lexer then goto continue end
    for _, patt in ipairs(patterns) do
      if not message:find(patt) then goto continue end
      -- Extract details from the warning or error.
      local detail, i = {message:match(patt)}, 1
      for capture in patt:gmatch('[^%%](%b())') do
        if capture == '(.-)' then
          detail.filename = detail[i]
        elseif capture == '(%d+)' then
          local line_or_column = not detail.line and 'line' or 'column'
          detail[line_or_column] = tonumber(detail[i])
        else
          detail.message = detail[i]
        end
        i = i + 1
      end
      detail.warning =
        message:lower():find('warning') and not message:lower():find('error')
      -- Compile and run commands specify the file extension or lexer name used
      -- to determine the command, so the error patterns used are guaranteed to
      -- be correct. Build commands have no such context and instead iterate
      -- through all possible error patterns. Only consider the error/warning
      -- valid if the extracted filename's extension or lexer name matches the
      -- error pattern's extension or lexer name.
      if ext_or_lexer then return detail end
      local ext = detail.filename:match('[^/\\.]+$')
      local lexer_name = textadept.file_types.extensions[ext]
      if key == ext or key == lexer_name then return detail end
      ::continue::
    end
    ::continue::
  end
  return nil
end

-- Prints an output line from a compile, run, or build shell command.
-- Assume output is UTF-8 unless there's a recognized warning or error message.
-- In that case assume it is encoded in _CHARSET and mark it.
-- All stdout and stderr from the command is printed silently.
-- @param line The output line to print.
-- @param ext_or_lexer Optional file extension or lexer name associated with the
--   executed command. This is used for better error detection in compile and
--   run commands.
local function print_line(line, ext_or_lexer)
  local error = scan_for_error(line, ext_or_lexer)
  ui.silent_print = M.run_in_background or ext_or_lexer or
    not line:find('^> ') or line:find('^> exit')
  ui.print(not error and line or line:iconv('UTF-8', _CHARSET))
  ui.silent_print = false
  if error then
    -- Current position is one line below the error due to ui.print()'s '\n'.
    buffer:marker_add(
      buffer.line_count - 1, error.warning and M.MARK_WARNING or M.MARK_ERROR)
  end
end

local output_buffer
-- Prints the output from a compile, run, or build shell command as a series of
-- lines, performing buffering as needed.
-- @param output The output to print, or `nil` to flush any buffered output.
-- @param ext_or_lexer Optional file extension or lexer name associated with the
--   executed command. This is used for better error detection in compile and
--   run commands.
local function print_output(output, ext_or_lexer)
  if output then
    if output_buffer then output = output_buffer .. output end
    local remainder = 1
    for line, e in output:gmatch('([^\r\n]*)\r?\n()') do
      print_line(line, ext_or_lexer)
      remainder = e
    end
    output_buffer = remainder <= #output and output:sub(remainder)
  elseif output_buffer then
    print_line(output_buffer, ext_or_lexer)
    output_buffer = nil
  end
end

-- Runs command *command* in working directory *dir*, emitting events of type
-- *event* with any output received.
-- @param command String command to run, or a function returning such a string
--   and optional working directory. A returned working directory overrides
--   *dir*.
-- @param dir String working directory to run *command* in.
-- @param event String event name to emit command output with.
-- @param macros Optional table of '%[char]' macros to expand within *command*.
-- @param ext_or_lexer Optional file extension or lexer name associated with the
--   executed command. This is used for better error detection in compile and
--   run commands.
local function run_command(command, dir, event, macros, ext_or_lexer)
  local working_dir
  if type(command) == 'function' then command, working_dir = command() end
  if not command then return end
  if macros then command = command:gsub('%%%a', macros) end
  preferred_view = view
  local function emit(output) events.emit(event, output, ext_or_lexer) end
  cwd = (working_dir or dir):gsub('[/\\]$', '')
  events.emit(event, string.format('> cd %s\n', cwd))
  events.emit(event, string.format('> %s\n', command:iconv('UTF-8', _CHARSET)))
  proc = assert(os.spawn(command, cwd, emit, emit, function(status)
    emit() -- flush
    events.emit(event, string.format('> exit status: %d\n', status))
  end))
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
  local lang = filename == buffer.filename and buffer:get_lexer() or
    textadept.file_types.extensions[ext]
  local command = commands[filename] or commands[ext] or commands[lang]
  local dirname, basename = '', filename
  if filename:find('[/\\]') then
    dirname, basename = filename:match('^(.+)[/\\]([^/\\]+)$')
  end
  local event = commands == M.compile_commands and events.COMPILE_OUTPUT or
    events.RUN_OUTPUT
  local macros = {
    ['%p'] = filename, ['%d'] = dirname, ['%f'] = basename,
    ['%e'] = basename:match('^(.+)%.') -- no extension
  }
  run_command(command, dirname, event, macros, commands[ext] and ext or lang)
end

---
-- Map of filenames, file extensions, and lexer names to their associated
-- "compile" shell command line strings or functions that return such strings.
-- Command line strings may have the following macros:
--
--   + `%f`: The file's name, including its extension.
--   + `%e`: The file's name, excluding its extension.
--   + `%d`: The file's directory path.
--   + `%p`: The file's full path.
--
-- Functions may also return a working directory to operate in. By default, it
-- is the current file's parent directory.
-- @class table
-- @name compile_commands
M.compile_commands = {actionscript='mxmlc "%f"',ada='gnatmake "%f"',ansi_c='gcc -o "%e" "%f"',antlr='antlr4 "%f"',g='antlr3 "%f"',applescript='osacompile "%f" -o "%e.scpt"',asm='nasm "%f"'--[[ && ld "%e.o" -o "%e"']],boo='booc "%f"',caml='ocamlc -o "%e" "%f"',csharp=WIN32 and 'csc "%f"' or 'mcs "%f"',coffeescript='coffee -c "%f"',context='context --nonstopmode "%f"',cpp='g++ -o "%e" "%f"',cuda=WIN32 and 'nvcc -o "%e.exe" "%f"' or 'nvcc -o "%e" "%f"',dmd='dmd "%f"',dot='dot -Tps "%f" -o "%e.ps"',eiffel='se c "%f"',elixir='elixirc "%f"',erlang='erl -compile "%e"',faust='faust -o "%e.cpp" "%f"',fsharp=WIN32 and 'fsc.exe "%f"' or 'mono fsc.exe "%f"',fortran='gfortran -o "%e" "%f"',gap='gac -o "%e" "%f"',go='go build "%f"',groovy='groovyc "%f"',haskell=WIN32 and 'ghc -o "%e.exe" "%f"' or 'ghc -o "%e" "%f"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%f"',ltx='pdflatex -file-line-error -halt-on-error "%f"',less='lessc --no-color "%f" "%e.css"',lilypond='lilypond "%f"',lisp='clisp -c "%f"',litcoffee='coffee -c "%f"',lua='luac -o "%e.luac" "%f"',moon='moonc "%f"',markdown='markdown "%f" > "%e.html"',myr='mbld -b "%e" "%f"',nemerle='ncc "%f" -out:"%e.exe"',nim='nim c "%f"',nsis='MakeNSIS "%f"',objective_c='gcc -o "%e" "%f"',pascal='fpc "%f"',perl='perl -c "%f"',php='php -l "%f"',prolog='gplc --no-top-level "%f"',python='python -m py_compile "%f"',ruby='ruby -c "%f"',rust='rustc "%f"',sass='sass "%f" "%e.css"',scala='scalac "%f"',sml='mlton "%f"',tex='pdflatex -file-line-error -halt-on-error "%f"',vala='valac "%f"',vb=WIN32 and 'vbc "%f"' or 'vbnc "%f"',}

---
-- Compiles file *filename* or the current file using an appropriate shell
-- command from the `compile_commands` table.
-- The shell command is determined from the file's filename, extension, or
-- language in that order.
-- Emits `COMPILE_OUTPUT` events.
-- @param filename Optional path to the file to compile. The default value is
--   the current file's filename.
-- @see compile_commands
-- @see _G.events
-- @name compile
function M.compile(filename)
  if assert_type(filename, 'string/nil', 1) or buffer.filename then
    compile_or_run(filename or buffer.filename, M.compile_commands)
  end
end
events.connect(events.COMPILE_OUTPUT, print_output)

---
-- Map of filenames, file extensions, and lexer names to their associated "run"
-- shell command line strings or functions that return strings.
-- Command line strings may have the following macros:
--
--   + `%f`: The file's name, including its extension.
--   + `%e`: The file's name, excluding its extension.
--   + `%d`: The file's directory path.
--   + `%p`: The file's full path.
--
-- Functions may also return a working directory to operate in. By default, it
-- is the current file's parent directory.
-- @class table
-- @name run_commands
M.run_commands = {actionscript=WIN32 and 'start "" "%e.swf"' or OSX and 'open "file://%e.swf"' or 'xdg-open "%e.swf"',ada=WIN32 and '"%e"' or './"%e"',ansi_c=WIN32 and '"%e"' or './"%e"',applescript='osascript "%f"',asm='./"%e"',awk='awk -f "%f"',batch='"%f"',boo='booi "%f"',caml='ocamlrun "%e"',csharp=WIN32 and '"%e"' or 'mono "%e.exe"',chuck='chuck "%f"',cmake='cmake -P "%f"',coffeescript='coffee "%f"',context=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',cpp=WIN32 and '"%e"' or './"%e"',crystal='crystal "%f"',cuda=WIN32 and '"%e"' or './"%e"',dart='dart "%f"',dmd=WIN32 and '"%e"' or './"%e"',eiffel="./a.out",elixir='elixir "%f"',fsharp=WIN32 and '"%e"' or 'mono "%e.exe"',fennel='fennel "%f"',forth='gforth "%f" -e bye',fortran=WIN32 and '"%e"' or './"%e"',gnuplot='gnuplot "%f"',go='go run "%f"',groovy='groovy "%f"',haskell=WIN32 and '"%e"' or './"%e"',html=WIN32 and 'start "" "%f"' or OSX and 'open "file://%f"' or 'xdg-open "%f"',icon='icont "%e" -x',idl='idl -batch "%f"',Io='io "%f"',java='java "%e"',javascript='node "%f"',ltx=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',less='lessc --no-color "%f"',lilypond=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',lisp='clisp "%f"',litcoffee='coffee "%f"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%f"',makefile=WIN32 and 'nmake -f "%f"' or 'make -f "%f"',markdown='markdown "%f"',moon='moon "%f"',myr=WIN32 and '"%e"' or './"%e"',nemerle=WIN32 and '"%e"' or 'mono "%e.exe"',nim='nim c -r "%f"',objective_c=WIN32 and '"%e"' or './"%e"',pascal=WIN32 and '"%e"' or './"%e"',perl='perl "%f"',php='php "%f"',pike='pike "%f"',pkgbuild='makepkg -p "%f"',prolog=WIN32 and '"%e"' or './"%e"',pure='pure "%f"',python=function() return buffer:get_line(0):find('^#!.-python3') and 'python3 -u "%f"' or 'python -u "%f"' end,rstats=WIN32 and 'Rterm -f "%f"' or 'R -f "%f"',rebol='REBOL "%f"',rexx=WIN32 and 'rexx "%f"' or 'regina "%f"',ruby='ruby "%f"',rust=WIN32 and '"%e"' or './"%e"',sass='sass "%f"',scala='scala "%e"',bash='bash "%f"',csh='tcsh "%f"',ksh='ksh "%f"',mksh='mksh "%f"',sh='sh "%f"',zsh='zsh "%f"',rc='rc "%f"',smalltalk='gst "%f"',sml=WIN32 and '"%e"' or './"%e"',snobol4='snobol4 -b "%f"',tcl='tclsh "%f"',tex=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',vala=WIN32 and '"%e"' or './"%e"',vb=WIN32 and '"%e"' or 'mono "%e.exe"',}

---
-- Runs file *filename* or the current file using an appropriate shell command
-- from the `run_commands` table.
-- The shell command is determined from the file's filename, extension, or
-- language in that order.
-- Emits `RUN_OUTPUT` events.
-- @param filename Optional path to the file to run. The default value is the
--   current file's filename.
-- @see run_commands
-- @see _G.events
-- @name run
function M.run(filename)
  if assert_type(filename, 'string/nil', 1) or buffer.filename then
    compile_or_run(filename or buffer.filename, M.run_commands)
  end
end
events.connect(events.RUN_OUTPUT, print_output)

---
-- Map of project root paths and "makefiles" to their associated "build" shell
-- command line strings or functions that return such strings.
-- Functions may also return a working directory to operate in. By default, it
-- is the project's root directory.
-- @class table
-- @name build_commands
M.build_commands = {--[[Ant]]['build.xml']='ant',--[[Dockerfile]]Dockerfile='docker build .',--[[Make]]Makefile='make',GNUmakefile='make',makefile='make',--[[Maven]]['pom.xml']='mvn',--[[Ruby]]Rakefile='rake'}

---
-- Builds the project whose root path is *root_directory* or the current project
-- using the shell command from the `build_commands` table.
-- If a "makefile" type of build file is found, prompts the user for the full
-- build command.
-- The current project is determined by either the buffer's filename or the
-- current working directory.
-- Emits `BUILD_OUTPUT` events.
-- @param root_directory The path to the project to build. The default value is
--   the current project.
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
          title = _L['Command'], informative_text = root_directory,
          text = build_command, button1 = _L['OK'], button2 = _L['Cancel']
        }
        if button == 1 then command = utf8_command:iconv(_CHARSET, 'UTF-8') end
        break
      end
    end
  end
  run_command(command, root_directory, events.BUILD_OUTPUT)
end
events.connect(events.BUILD_OUTPUT, print_output)

---
-- Stops the currently running process, if any.
-- @name stop
function M.stop() if proc then proc:kill() end end

-- Send line as input to process stdin on return.
events.connect(events.CHAR_ADDED, function(code)
  if code == string.byte('\n') and proc and proc:status() == 'running' and
     buffer._type == _L['[Message Buffer]'] then
    local line_num = buffer:line_from_position(buffer.current_pos) - 1
    proc:write(buffer:get_line(line_num))
  end
end)

---
-- Map of file extensions and lexer names to their associated lists of string
-- patterns that match warning and error messages emitted by compile and run
-- commands for those file extensions and lexers.
-- Patterns match single lines and contain captures for a filename, line number,
-- column number (optional), and warning or error message (optional).
-- Double-clicking a warning or error message takes the user to the source of
-- that warning/error.
-- Note: `(.-)` captures in patterns are interpreted as filenames; `(%d+)`
-- captures are interpreted as line numbers first, and then column numbers; and
-- any other capture is treated as warning/error message text.
-- @class table
-- @name error_patterns
M.error_patterns = {actionscript={'^(.-)%((%d+)%): col: (%d+) (.+)$'},ada={'^(.-):(%d+):(%d+):%s*(.*)$','^[^:]+: (.-):(%d+) (.+)$'},ansi_c={'^(.-):(%d+):(%d+): (.+)$'},antlr={'^error%(%d+%): (.-):(%d+):(%d+): (.+)$','^warning%(%d+%): (.-):(%d+):(%d+): (.+)$'},--[[ANTLR]]g={'^error%(%d+%): (.-):(%d+):(%d+): (.+)$','^warning%(%d+%): (.-):(%d+):(%d+): (.+)$'},asm={'^(.-):(%d+): (.+)$'},awk={'^awk: (.-):(%d+): (.+)$'},boo={'^(.-)%((%d+),(%d+)%): (.+)$'},caml={'^%s*File "(.-)", line (%d+), characters (%d+)'},chuck={'^(.-)line%((%d+)%)%.char%((%d+)%): (.+)$'},cmake={'^CMake Error at (.-):(%d+)','^(.-):(%d+):$'},coffeescript={'^(.-):(%d+):(%d+): (.+)$'},context={'error on line (%d+) in file (.-): (.+)$'},cpp={'^(.-):(%d+):(%d+): (.+)$'},csharp={'^(.-)%((%d+),(%d+)%): (.+)$'},cuda={'^(.-)%((%d+)%): (error.+)$'},dart={"^'(.-)': error: line (%d+) pos (%d+): (.+)$",'%(file://(.-):(%d+):(%d+)%)'},dmd={'^(.-)%((%d+)%): (Error.+)$'},dot={'^Warning: (.-): (.+) in line (%d+)'},eiffel={'^Line (%d+) columns? .- in .- %((.-)%):$','^line (%d+) column (%d+) file (.-)$'},elixir={'^(.-):(%d+): (.+)$','Error%) (.-):(%d+): (.+)$'},erlang={'^(.-):(%d+): (.+)$'},faust={'^(.-):(%d+):(.+)$'},fennel={'^%S+ error in (.-):(%d+)'},forth={'^(.-):(%d+): (.+)$'},fortran={'^(.-):(%d+)%D+(%d+):%s*(.*)$'},fsharp={'^(.-)%((%d+),(%d+)%): (.+)$'},gap={'^(.+) in (.-) line (%d+)$'},gnuplot={'^"(.-)", line (%d+): (.+)$'},go={'^(.-):(%d+): (.+)$'},groovy={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},haskell={'^(.-):(%d+):(%d+):%s*(.*)$'},icon={'^File (.-); Line (%d+) # (.+)$','^.-from line (%d+) in (.-)$'},java={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},javascript={'^%s+at .-%((.-):(%d+):(%d+)%)$','^%s+at (.-):(%d+):(%d+)$','^(.-):(%d+):?$'},ltx={'^(.-):(%d+): (.+)$'},less={'^(.+) in (.-) on line (%d+), column (%d+):$'},lilypond={'^(.-):(%d+):(%d+):%s*(.*)$'},litcoffee={'^(.-):(%d+):(%d+): (.+)$'},lua={'^luac?: (.-):(%d+): (.+)$'},makefile={'^(.-):(%d+): (.+)$'},nemerle={'^(.-)%((%d+),(%d+)%): (.+)$'},nim={'^(.-)%((%d+), (%d+)%) (%w+:.+)$'},objective_c={'^(.-):(%d+):(%d+): (.+)$'},pascal={'^(.-)%((%d+),(%d+)%) (%w+:.+)$'},perl={'^(.+) at (.-) line (%d+)'},php={'^(.+) in (.-) on line (%d+)$'},pike={'^(.-):(%d+):(.+)$'},prolog={'^(.-):(%d+):(%d+): (.+)$','^(.-):(%d+): (.+)$'},pure={'^(.-), line (%d+): (.+)$'},python={'^%s*File "(.-)", line (%d+)'},rexx={'^Error %d+ running "(.-)", line (%d+): (.+)$'},ruby={'^%s+from (.-):(%d+):','^(.-):(%d+):%s*(.+)$'},rust={'^(.-):(%d+):(%d+): (.+)$',"panicked at '([^']+)', (.-):(%d+)"},sass={'^WARNING on line (%d+) of (.-):$','^%s+on line (%d+) of (.-)$'},scala={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},sh={'^(.-): (%d+): %1: (.+)$'},bash={'^(.-): line (%d+): (.+)$'},zsh={'^(.-):(%d+): (.+)$'},smalltalk={'^(.-):(%d+): (.+)$','%((.-):(%d+)%)$'},snobol4={'^(.-):(%d+): (.+)$'},tcl={'^%s*%(file "(.-)" line (%d+)%)$'},tex={'^(.-):(%d+): (.+)$'},vala={'^(.-):(%d+)%.(%d+)[%-%.%d]+: (.+)$','^(.-):(%d+):(%d+): (.+)$'},vb={'^(.-)%((%d+),(%d+)%): (.+)$'}}
-- Note: APDL,IDL,REBOL,Verilog,VHDL are proprietary.
-- Note: ASP,CSS,Desktop,diff,django,gettext,Gtkrc,HTML,ini,JSON,JSP,Markdown,Postscript,Properties,R,RHTML,XML don't have parse-able errors.
-- Note: Batch,BibTeX,ConTeXt,Dockerfile,GLSL,Inform,Io,Lisp,MoonScript,Scheme,SQL,TeX cannot be parsed for one reason or another.

-- Returns whether or not the given buffer is a message buffer.
local function is_msg_buf(buf) return buf._type == _L['[Message Buffer]'] end
---
-- Jumps to the source of the recognized compile/run warning or error on line
-- number *line_num* in the message buffer.
-- If *line_num* is `nil`, jumps to the next or previous warning or error,
-- depending on boolean *next*. Displays an annotation with the warning or error
-- message if possible.
-- @param line_num Optional line number in the message buffer that contains the
--   compile/run warning or error to go to. This parameter may be omitted
--   completely.
-- @param next Optional flag indicating whether to go to the next recognized
--   warning/error or the previous one. Only applicable when *line_num* is
--   `nil`.
-- @see error_patterns
-- @name goto_error
function M.goto_error(line_num, next)
  if type(line_num) == 'boolean' then line_num, next = nil, line_num end
  local msg_view, msg_buf = nil, nil
  for i = 1, #_VIEWS do
    if is_msg_buf(_VIEWS[i].buffer) then msg_view = _VIEWS[i] break end
  end
  for i = 1, #_BUFFERS do
    if is_msg_buf(_BUFFERS[i]) then msg_buf = _BUFFERS[i] break end
  end
  if not msg_view and not msg_buf then return end
  if msg_view then ui.goto_view(msg_view) else view:goto_buffer(msg_buf) end

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
      if wline == -1 then wline = eline else eline = wline end
    end
    line_num = (next and math.min or math.max)(wline, eline)
    if line_num == -1 and not wrapped then
      line_num = next and 1 or buffer.line_count
      wrapped = true
      goto retry
    end
  end

  -- Goto the warning or error and show an annotation.
  local line = buffer:get_line(line_num):match('^[^\r\n]*')
  local detail = scan_for_error(line:iconv(_CHARSET, 'UTF-8'))
  if not detail then return end
  buffer:goto_line(line_num)
  textadept.editing.select_line()
  if not detail.filename:find(not WIN32 and '^/' or '^%a:[/\\]') and cwd then
    detail.filename = cwd .. (not WIN32 and '/' or '\\') .. detail.filename
  end
  local sloppy = not detail.filename:find(not WIN32 and '^/' or '^%a:[/\\]')
  ui.goto_file(detail.filename, true, preferred_view, sloppy)
  textadept.editing.goto_line(detail.line)
  if detail.column then
    buffer:goto_pos(buffer:find_column(detail.line, detail.column))
  end
  if detail.message then
    buffer.annotation_text[detail.line] = detail.message
    if not detail.warning then
      buffer.annotation_style[detail.line] = buffer:style_of_name('error')
    end
  end
end
events.connect(events.KEYPRESS, function(code)
  if keys.KEYSYMS[code] == '\n' and is_msg_buf(buffer) and
     scan_for_error(buffer:get_cur_line():match('^[^\r\n]*')) then
    M.goto_error(buffer:line_from_position(buffer.current_pos))
    return true
  end
end)
events.connect(events.DOUBLE_CLICK, function(_, line)
  if is_msg_buf(buffer) then M.goto_error(line) end
end)

return M

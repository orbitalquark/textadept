-- Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile, run, and check the syntax of source code files with Textadept.
-- [Language modules](#_M.Compile.and.Run) may tweak the `compile_commands`,
-- `run_commands`, `error_patterns`, `syntax_commands`, and
-- `syntax_error_patterns` tables for particular languages.
-- The user may tweak `build_commands` for particular projects.
-- @field RUN_IN_BACKGROUND (bool)
--   Run shell commands silently in the background.
--   This only applies when the message buffer is open, though it does not have
--   to be visible.
--   The default value is `false`.
-- @field CHECK_SYNTAX (bool)
--   Check the syntax of sources files upon saving them.
--   This applies only to languages that have syntax-checking commands and error
--   message patterns defined in the `syntax_commands` and
--   `syntax_error_patterns` tables, respectively.
--   The default value is `true`.
-- @field GOTO_SYNTAX_ERRORS (bool)
--   Immediately jump to recognized syntax errors after saving a source file.
--   The default value is `true`.
-- @field MARK_WARNING (number)
--   The run or compile warning marker number.
-- @field MARK_ERROR (number)
--   The run or compile error marker number.
-- @field cwd (string, Read-only)
--   The most recently executed compile or run shell command's working
--   directory.
--   It is used for going to error messages with relative file paths.
-- @field proc (process)
--   The currently running process or the most recent process run.
-- @field _G.events.COMPILE_OUTPUT (string)
--   Emitted when executing a language's compile shell command.
--   By default, compiler output is printed to the message buffer. To override
--   this behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The language's lexer name.
--   * `output`: A line of string output from the command.
-- @field _G.events.RUN_OUTPUT (string)
--   Emitted when executing a language's run shell command.
--   By default, output is printed to the message buffer. To override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The language's lexer name.
--   * `output`: A line of string output from the command.
-- @field _G.events.BUILD_OUTPUT (string)
--   Emitted when executing a project's build shell command.
--   By default, output is printed to the message buffer. To override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `project`: The path to the project being built.
--   * `output`: A line of string output from the command.
module('textadept.run')]]

M.RUN_IN_BACKGROUND = false
M.CHECK_SYNTAX = true
M.GOTO_SYNTAX_ERRORS = true

M.MARK_WARNING = _SCINTILLA.next_marker_number()
M.MARK_ERROR = _SCINTILLA.next_marker_number()

-- Events.
events.COMPILE_OUTPUT, events.RUN_OUTPUT = 'compile_output', 'run_output'
events.BUILD_OUTPUT = 'build_output'

local preferred_view

-- Executes a compile, run, or build shell command from *commands*.
-- Emits events named *event*.
-- @param commands Either `compile_commands`, `run_commands`, or
-- `build_commands`.
-- @param event Event to emit upon command output.
-- @see _G.events
local function run_command(commands, event)
  local command, cwd, data
  if commands ~= M.build_commands then
    if not buffer.filename then return end
    buffer:annotation_clear_all()
    io.save_file()
    command = commands[buffer.filename:match('[^.]+$')] or
              commands[buffer:get_lexer()]
    cwd = buffer.filename:match('^(.+)[/\\][^/\\]+$') or ''
    data = buffer:get_lexer()
  else
    for i = 1, #_BUFFERS do _BUFFERS[i]:annotation_clear_all() end
    cwd = io.get_project_root()
    command = commands[cwd]
    if not command then
      local lfs_attributes = lfs.attributes
      for build_file, build_command in pairs(commands) do
        if lfs_attributes(cwd..'/'..build_file) then
          local button, cmd = ui.dialogs.inputbox{
            title = _L['Command'], informative_text = cwd, text = build_command,
            button1 = _L['_OK'], button2 = _L['_Cancel']
          }
          if button == 1 then command = cmd end
          break
        end
      end
    end
    data = cwd
  end
  if type(command) == 'function' then
    local wd
    command, wd = command()
    if wd then cwd, data = wd, commands ~= M.build_commands and data or wd end
  end
  if not command then return end
  if buffer.filename then
    local filepath, filedir, filename = buffer.filename, '', buffer.filename
    if filepath:find('[/\\]') then
      filedir, filename = filepath:match('^(.+[/\\])([^/\\]+)$')
    end
    local filename_noext = filename:match('^(.+)%.')
    command = command:gsub('%%([pdfe])', {
      p = filepath, d = filedir, f = filename, e = filename_noext
    })
  end

  preferred_view = view
  local function emit_output(output, focus)
    ui.SILENT_PRINT = not focus
    for line in output:gmatch('[^\r\n]+') do
      events.emit(event, data, line:iconv('UTF-8', _CHARSET))
    end
    ui.SILENT_PRINT = false
  end
  local function emit_status(status) emit_output('> exit status: '..status) end

  if commands == M.build_commands then emit_output('> cd '..cwd) end
  emit_output('> '..command, not M.RUN_IN_BACKGROUND)
  local p, err = spawn(command, cwd, emit_output, emit_output, emit_status)
  if not p then error(err) end

  M.proc, M.cwd = p, cwd
end

-- Parses the given message for a warning or error message and returns a table
-- of the warning/error's details.
-- @param message The message to parse for warnings or errors.
-- @see error_patterns
local function get_error(message)
  for i = 1, #M.error_patterns do
    local patt = M.error_patterns[i]
    if message:find(patt) then
      local captures = {message:match(patt)}
      for detail in patt:gmatch('[^%%](%b())') do
        if detail == '(.-)' then
          captures.filename = table.remove(captures, 1):iconv(_CHARSET, 'UTF-8')
        elseif detail == '(%d+)' then
          captures.line = tonumber(table.remove(captures, 1))
        else
          captures.message = table.remove(captures, 1)
        end
      end
      local warn = message:find('[Ww]arning') and not message:find('[Ee]rror')
      captures.text, captures.warning = message, warn
      return captures
    end
  end
  return nil
end

-- Prints the output from a run or compile shell command.
-- If the output is a recognized warning or error message, mark it.
-- @param _ The current lexer.
-- @param output The output to print.
local function print_output(_, output)
  ui.print(output)
  local error = get_error(output)
  if not error then return end
  -- Current position is one line below the error due to ui.print()'s '\n'.
  buffer:marker_add(buffer.line_count - 2,
                    error.warning and M.MARK_WARNING or M.MARK_ERROR)
end

---
-- Map of file extensions or lexer names to their associated "compile" shell
-- command line strings or functions that return such strings.
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
M.compile_commands = {actionscript='mxmlc "%f"',ada='gnatmake "%f"',ansi_c='gcc -o "%e" "%f"',antlr='antlr4 "%f"',g='antlr3 "%f"',applescript='osacompile "%f" -o "%e.scpt"',asm='nasm "%f" && ld "%e.o" -o "%e"',boo='booc "%f"',caml='ocamlc -o "%e" "%f"',csharp=WIN32 and 'csc "%f"' or 'mcs "%f"',cpp='g++ -o "%e" "%f"',coffeescript='coffee -c "%f"',context='context --nonstopmode "%f"',cuda=WIN32 and 'nvcc -o "%e.exe" "%f"' or 'nvcc -o "%e" "%f"',dmd='dmd "%f"',dot='dot -Tps "%f" -o "%e.ps"',eiffel='se c "%f"',elixir='elixirc "%f"',erlang='erl -compile "%e"',fsharp=WIN32 and 'fsc.exe "%f"' or 'mono fsc.exe "%f"',fortran='gfortran -o "%e" "%f"',gap='gac -o "%e" "%f"',go='go build "%f"',groovy='groovyc "%f"',haskell=WIN32 and 'ghc -o "%e.exe" "%f"' or 'ghc -o "%e" "%f"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%f"',ltx='pdflatex -file-line-error -halt-on-error "%f"',less='lessc "%f" "%e.css"',lilypond='lilypond "%f"',lisp='clisp -c "%f"',litcoffee='coffee -c "%f"',lua='luac -o "%e.luac" "%f"',moon='moonc "%f"',markdown='markdown "%f" > "%e.html"',nemerle='ncc "%f" -out:"%e.exe"',nim='nim c "%f"',nsis='MakeNSIS "%f"',objective_c='gcc -o "%e" "%f"',pascal='fpc "%f"',perl='perl -c "%f"',php='php -l "%f"',prolog='gplc --no-top-level "%f"',python='python -m py_compile "%f"',ruby='ruby -c "%f"',rust='rustc "%f"',sass='sass "%f" "%e.css"',scala='scalac "%f"',tex='pdflatex -file-line-error -halt-on-error "%f"',vala='valac "%f"',vb=WIN32 and 'vbc "%f"' or 'vbnc "%f"',}

---
-- Compiles the current file based on its extension or language using the
-- shell command from the `compile_commands` table.
-- Emits `COMPILE_OUTPUT` events.
-- @see compile_commands
-- @see _G.events
-- @name compile
function M.compile() run_command(M.compile_commands, events.COMPILE_OUTPUT) end
events.connect(events.COMPILE_OUTPUT, print_output)

---
-- Map of file extensions or lexer names to their associated "run" shell command
-- line strings or functions that return strings.
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
M.run_commands = {actionscript=WIN32 and 'start "" "%e.swf"' or OSX and 'open "file://%e.swf"' or 'xdg-open "%e.swf"',ada=WIN32 and '"%e"' or './"%e"',ansi_c=WIN32 and '"%e"' or './"%e"',applescript='osascript "%f"',asm='./"%e"',awk='awk -f "%f"',batch='"%f"',boo='booi "%f"',caml='ocamlrun "%e"',csharp=WIN32 and '"%e"' or 'mono "%e.exe"',cpp=WIN32 and '"%e"' or './"%e"',chuck='chuck "%f"',cmake='cmake -P "%f"',coffeescript='coffee "%f"',context=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',cuda=WIN32 and '"%e"' or './"%e"',dmd=WIN32 and '"%e"' or './"%e"',eiffel="./a.out",elixir='elixir "%f"',fsharp=WIN32 and '"%e"' or 'mono "%e.exe"',forth='gforth "%f" -e bye',fortran=WIN32 and '"%e"' or './"%e"',gnuplot='gnuplot "%f"',go='go run "%f"',groovy='groovy "%f"',haskell=WIN32 and '"%e"' or './"%e"',html=WIN32 and 'start "" "%f"' or OSX and 'open "file://%f"' or 'xdg-open "%f"',icon='icont "%e" -x',idl='idl -batch "%f"',Io='io "%f"',java='java "%e"',javascript='node "%f"',ltx=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',less='lessc --no-color "%f"',lilypond=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',lisp='clisp "%f"',litcoffee='coffee "%f"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%f"',makefile=WIN32 and 'nmake -f "%f"' or 'make -f "%f"',markdown='markdown "%f"',moon='moon "%f"',nemerle=WIN32 and '"%e"' or 'mono "%e.exe"',nim='nim c -r "%f"',objective_c=WIN32 and '"%e"' or './"%e"',pascal=WIN32 and '"%e"' or './"%e"',perl='perl "%f"',php='php "%f"',pike='pike "%f"',pkgbuild='makepkg -p "%f"',prolog=WIN32 and '"%e"' or './"%e"',pure='pure "%f"',python='python -u "%f"',rstats=WIN32 and 'Rterm -f "%f"' or 'R -f "%f"',rebol='REBOL "%f"',rexx=WIN32 and 'rexx "%e"' or 'regina "%e"',ruby='ruby "%f"',rust=WIN32 and '"%e"' or './"%e"',sass='sass "%f"',scala='scala "%e"',bash='bash "%f"',csh='tcsh "%f"',sh='sh "%f"',zsh='zsh "%f"',smalltalk='gst "%f"',snobol4='snobol4 -b "%f"',tcl='tclsh "%f"',tex=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',vala=WIN32 and '"%e"' or './"%e"',vb=WIN32 and '"%e"' or 'mono "%e.exe"',}

---
-- Runs the current file based on its extension or language using the shell
-- command from the `run_commands` table.
-- Emits `RUN_OUTPUT` events.
-- @see run_commands
-- @see _G.events
-- @name run
function M.run() run_command(M.run_commands, events.RUN_OUTPUT) end
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
-- Builds the current project (based on the buffer's filename or the current
-- working directory) using the shell command from the `build_commands` table.
-- If a "makefile" type of build file is found, prompts the user for the full
-- build command.
-- Emits `BUILD_OUTPUT` events.
-- @see build_commands
-- @see _G.events
-- @name build
function M.build() run_command(M.build_commands, events.BUILD_OUTPUT) end
events.connect(events.BUILD_OUTPUT, print_output)

---
-- Stops the currently running process, if any.
-- @name stop
function M.stop() if M.proc then M.proc:kill() end end

-- Send line as input to process stdin on return.
events.connect(events.CHAR_ADDED, function(byte)
  local proc = M.proc
  if byte == 10 and proc and proc.status and proc:status() == 'running' and
     buffer._type == _L['[Message Buffer]'] then
    local line_num = buffer:line_from_position(buffer.current_pos) - 1
    proc:write((buffer:get_line(line_num)))
  end
end)

---
-- List of warning and error string patterns that match various compile and run
-- warnings and errors.
-- Patterns contain filename, line number, and optional warning or error message
-- captures for single lines. When a warning or error message is double-clicked,
-- the user is taken to the point of warning/error.
-- When adding to this list, use `(.-)` to match filenames and `(%d+)` to match
-- line numbers. Also keep in mind that patterns are matched in sequential
-- order; once a pattern matches, no more are tried.
-- @class table
-- @name error_patterns
M.error_patterns = {--[[ANTLR]]'^error%(%d+%): (.-):(%d+):%d+: (.+)$','^warning%(%d+%): (.-):(%d+):%d+: (.+)$',--[[AWK]]'^awk: (.-): line (%d+): (.+)$',--[[ChucK]]'^%[(.-)%]:line%((%d+)%)%.char%(%d+%): (.+)$',--[[CMake]]'^CMake Error at (.-):(%d+)',--[[Dot]]'^Error: (.-):(%d+): (.+)$',--[[Eiffel]]'^Line (%d+) columns? .- in .- %((.-)%):$','^line (%d+) column %d+ file (.-)$',--[[CoffeeScript,LitCoffee]]'^%s+at .-%((.-):(%d+):%d+, .-%)$',--[[Groovy,Java,Javascript]]'^%s+at .-%((.-):(%d+):?%d*%)$',--[[Icon]]'^File (.-); Line (%d+) # (.+)$',--[[JavaScript]]'^%s+at (.-):(%d+):%d+$',--[[GNUPlot]]'^"(.-)", line (%d+): (.+)$',--[[Lua]]'^luac?: (.-):(%d+): (.+)$',--[[Prolog]]'^warning: (.-):(%d+): (.+)$',--[[OCaml,Python]]'^%s*File "(.-)", line (%d+)',--[[Rexx]]'^Error %d+ running "(.-)", line (%d+): (.+)$',--[[Sass]]'^WARNING on line (%d+) of (.-):$','^%s+on line (%d+) of (.-)$',--[[Tcl]]'^%s*%(file "(.-)" line (%d+)%)$',--[[Actionscript]]'^(.-)%((%d+)%): col %d+ (.+)$',--[[CUDA,D]]'^(.-)%((%d+)%): ([Ee]rror.+)$',--[[Boo,C#,F#,Nemerle,VB]]'^(.-)%((%d+),%d+%): (.+)$',--[[Pascal,Nim]]'^(.-)%((%d+),?%s*%d*%) (%w+:.+)$',--[[Ada,C/C++,Haskell,LilyPond,Objective C,Prolog]]'^(.-):(%d+):%d+:%s*(.*)$',--[[Fortran,Vala]]'^(.-):(%d+)[%.%-][%.%d%-]+:%s*(.*)$',--[[CMake,Javascript]]'^(.-):(%d+):$',--[[Pure]]'^(.-), line (%d+): (.+)$',--[[Python]]'^.-: %(\'([^\']+)\', %(\'(.-)\', (%d+), %d,','^.-: (.+) %((.-), line (%d+)%)$',--[[Shell (Bash)]]'^(.-): line (%d+): (.+)$',--[[Shell (sh)]]'^(.-): (%d+): %1: (.+)$',--[[Erlang,Forth,Groovy,Go,Java,LilyPond,Makefile,Pike,Ruby,Scala,Smalltalk,SNOBOL4]]'^%s*(.-):%s*(%d+):%s*(.+)$',--[[Less]]'^(.+) in (.-) on line (%d+), column %d+:$',--[[PHP]]'^(.+) in (.-) on line (%d+)$',--[[Gap]]'^(.+) in (.-) line (%d+)$',--[[Perl]]'^(.+) at (.-) line (%d+)',--[[APDL,IDL,REBOL,Verilog,VHDL:proprietary]]--[[ASP,CSS,Desktop,diff,django,gettext,Gtkrc,HTML,ini,JSON,JSP,Markdown,Postscript,Properties,R,RHTML,XML:none]]--[[Batch,BibTeX,ConTeXt,Dockerfile,GLSL,Inform,Io,Lisp,MoonScript,Scheme,SQL,TeX:cannot parse]]}

-- Returns whether or not the given buffer is a message buffer.
local function is_msg_buf(buf) return buf._type == _L['[Message Buffer]'] end
---
-- Jumps to the source of the recognized compile/run warning or error on line
-- number *line* in the message buffer.
-- If *line* is `nil`, jumps to the next or previous warning or error, depending
-- on boolean *next*. Displays an annotation with the warning or error message
-- if possible.
-- @param line The line number in the message buffer that contains the
--   compile/run warning/error to go to.
-- @param next Optional flag indicating whether to go to the next recognized
--   warning/error or the previous one. Only applicable when *line* is `nil` or
--   `false`.
-- @see error_patterns
-- @see cwd
-- @name goto_error
function M.goto_error(line, next)
  local msg_view, msg_buf = nil, nil
  for i = 1, #_VIEWS do
    if is_msg_buf(_VIEWS[i].buffer) then msg_view = i break end
  end
  for i = 1, #_BUFFERS do
    if is_msg_buf(_BUFFERS[i]) then msg_buf = i break end
  end
  if not msg_view and not msg_buf then return end
  if msg_view then ui.goto_view(msg_view) else view:goto_buffer(msg_buf) end

  -- If no line was given, find the next warning or error marker.
  if not line and next ~= nil then
    local f = buffer['marker_'..(next and 'next' or 'previous')]
    line = buffer:line_from_position(buffer.current_pos)
    local wline = f(buffer, line + (next and 1 or -1), 2^M.MARK_WARNING)
    local eline = f(buffer, line + (next and 1 or -1), 2^M.MARK_ERROR)
    if wline == -1 and eline == -1 then
      wline = f(buffer, next and 0 or buffer.line_count, 2^M.MARK_WARNING)
      eline = f(buffer, next and 0 or buffer.line_count, 2^M.MARK_ERROR)
    elseif wline == -1 or eline == -1 then
      if wline == -1 then wline = eline else eline = wline end
    end
    line = (next and math.min or math.max)(wline, eline)
    if line == -1 then return end
  end
  buffer:goto_line(line)

  -- Goto the warning or error and show an annotation.
  local error = get_error(buffer:get_line(line):match('^[^\r\n]*'))
  if not error then return end
  textadept.editing.select_line()
  ui.goto_file(M.cwd..'/'..error.filename, true, preferred_view, true)
  local line_num, message = error.line, error.message
  textadept.editing.goto_line(line_num)
  if message then
    buffer.annotation_text[line_num - 1] = message
    -- Style number 8 is the error style.
    if not error.warning then buffer.annotation_style[line_num - 1] = 8 end
  end
end
events.connect(events.KEYPRESS, function(code)
  if keys.KEYSYMS[code] == '\n' and is_msg_buf(buffer) and M.cwd and
     get_error(buffer:get_cur_line():match('^[^\r\n]*')) then
    M.goto_error(buffer:line_from_position(buffer.current_pos))
    return true
  end
end)
events.connect(events.DOUBLE_CLICK, function(_, line)
  if is_msg_buf(buffer) and M.cwd then M.goto_error(line) end
end)

---
-- Map of file extensions or lexer names to their associated syntax checker
-- command line strings or functions that return such strings.
-- `%f` in command line strings represents the file to check the syntax of.
-- Upon saving a source file, this table is consulted for potentially running a
-- syntax checking utility on that file. This usually only makes sense for
-- interpreted languages and markup languages.
-- @class table
-- @name syntax_commands
M.syntax_commands = {awk='gawk --source "BEGIN{exit(0)} END{exit(0)}" --file "%f"',bash = function() return (buffer:get_line(0):match('^#!.+/([^/%s]+)') or 'bash')..' -n "%f"' end,coffeescript='coffee -cp "%f"',css='csslint --format=compact --quiet "%f"',fish='fish -n "%f"',go='gofmt -l "%f"',html='tidy -e -q -utf8 "%f"',javascript='jshint "%f"',less='lessc --lint --no-color "%f"',litcoffee='coffee -cp "%f"',lua='luac -p "%f"',perl='perl -c -X "%f"',php='php -l "%f"',python=function() return ([[python -c "compile(open('%f').read(),'%f','exec',0,1)"]]):gsub('%%f', (buffer.filename:gsub('\\', '\\\\\\\\'))) end,ruby='ruby -c "%f"',sass='sass -c -q "%f"',snobol4='snobol4 -b -n "%f"',xml='xmllint "%f"',}

---
-- Map of file extensions or lexer names to patterns that match their respective
-- syntax-checkers' error messages or functions that return such patterns.
-- Patterns contain line number, optional column number, and error message
-- captures.
-- When adding to this map, use `(%d+)` to match line and column numbers.
-- `(%s*)` may also be used to match column numbers for visual error messages.
-- @class table
-- @name syntax_error_patterns
M.syntax_error_patterns = {awk=':(%d+): (%s*)^ ([^\r\n]+)',bash='[:%s](%d+): ([^\r\n]+)',coffeescript='In [^,]+, (.-) on line (%d+):?([^\r\n]*)',css='line (%d+), col (%d+), ([^\r\n]+)',fish='fish: ([^\r\n]+).-line (%d+).:',go=':(%d+):(%d+): ([^\r\n]+)',html='line (%d+) column (%d+) %- Error: ([^\r\n]+)',javascript='line (%d+), col (%d+), ([^\r\n]+)',less='^(.-) in .- on line (%d+), column (%d+):',litcoffee='In [^,]+, (.-) on line (%d+):?([^\r\n]*)',lua=':(%d+): ([^\r\n]+)',perl='^(.-) at .- line (%d+)',php='^(.-) in .- on line (%d+)',python='", line (%d+)[\r\n]+.-(%w+: [^\r\n]+)',ruby=':(%d+): ([^\r\n]+).-[\r\n]+(%s*)^?[\r\n]*$',sass='^([^\r\n]+).-on line (%d+)',snobol4='^(.-):(%d+): ([^\r\n]+)',xml=':(%d+): ([^\r\n]+).-[\r\n]+(%s*)^',}

-- Check syntax upon saving a file.
events.connect(events.FILE_AFTER_SAVE, function(filename)
  if not M.CHECK_SYNTAX then return end
  -- Determine the syntax checker command.
  local ext, lexer = buffer.filename:match('[^.]+$'), buffer:get_lexer()
  local command = M.syntax_commands[ext] or M.syntax_commands[lexer]
  local patt = M.syntax_error_patterns[ext] or M.syntax_error_patterns[lexer]
  if type(command) == 'function' then command = command() end
  if type(patt) == 'function' then patt = patt() end
  if not command or not patt then return end
  -- Run the syntax checker command and look for errors.
  buffer:annotation_clear_all()
  local out = {}
  local output = function(output) out[#out + 1] = output end
  spawn(command:gsub('%%f', filename), nil, output, output, function()
    local captures = {message = '', table.concat(out):match(patt)}
    if #captures == 0 then return end
    -- Parse out the line, column, and error message.
    for detail in patt:gmatch('[^%%](%b())') do
      if detail == '(%d+)' then
        local source = not captures.line and 'line' or 'column'
        captures[source] = tonumber(table.remove(captures, 1)) - 1
      elseif detail == '(%s*)' then
        captures.column = #table.remove(captures, 1)
      else
        captures.message = captures.message..table.remove(captures, 1)
      end
    end
    if not captures.line or not captures.message then return end
    -- Display the annotation and either jump to, or note the position.
    buffer.annotation_text[captures.line] = captures.message
    buffer.annotation_style[captures.line] = 8 -- error style number
    local top_line = buffer:doc_line_from_visible(buffer.first_visible_line)
    local bottom_line = buffer:doc_line_from_visible(buffer.first_visible_line +
                                                     buffer.lines_on_screen) - 1
    if M.GOTO_SYNTAX_ERRORS then
      buffer:goto_pos(buffer:find_column(captures.line, captures.column or 0))
    elseif captures.line < top_line or captures.line > bottom_line then
      local line = buffer:line_from_position(buffer.current_pos)
      buffer.annotation_text[line] = string.format('%s %d\n%s', _L['Line:'],
                                                   captures.line + 1,
                                                   captures.message)
      buffer.annotation_style[line] = 8 -- error style number
    end
  end)
end)

return M

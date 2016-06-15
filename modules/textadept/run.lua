-- Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.

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
    for i = 1, #patterns do
      if not message:find(patterns[i]) then goto continue end
      -- Extract details from the warning or error.
      local details, j = {message:match(patterns[i])}, 1
      for capture in patterns[i]:gmatch('[^%%](%b())') do
        if capture == '(.-)' then
          details.filename = details[j]
        elseif capture == '(%d+)' then
          local line_or_column = not details.line and 'line' or 'column'
          details[line_or_column] = tonumber(details[j])
        else
          details.message = details[j]
        end
        j = j + 1
      end
      details.warning = message:lower():find('warning') and
                        not message:lower():find('error')
      -- Compile and run commands specify the file extension or lexer used to
      -- determine the command, so the error patterns used are guaranteed to be
      -- correct. Build commands have no such context and instead iterate
      -- through all possible error patterns. Only consider the error/warning
      -- valid if the extracted filename's extension or lexer matches the error
      -- pattern's extension or lexer.
      if ext_or_lexer then return details end
      local ext = details.filename:match('[^/\\.]+$')
      local lexer = textadept.file_types.extensions[ext]
      if ext == key or lexer == key then return details end
      ::continue::
    end
    ::continue::
  end
  return nil
end

-- Prints the output from a compile, run, or build shell command.
-- Assume output is UTF-8 unless there's a recognized warning or error message.
-- In that case assume it is encoded in _CHARSET and mark it.
-- All stdout and stderr from the command is printed silently.
-- @param output The output to print.
-- @param ext_or_lexer Optional file extension or lexer name associated with the
--   executed command. This is used for better error detection in compile and
--   run commands.
local function print_output(output, ext_or_lexer)
  local error = scan_for_error(output, ext_or_lexer)
  ui.silent_print = (M.run_in_background or ext_or_lexer or
                     not output:find('^> ') or output:find('^> exit')) and true
  ui.print(not error and output or output:iconv('UTF-8', _CHARSET))
  ui.silent_print = false
  if error then
    -- Current position is one line below the error due to ui.print()'s '\n'.
    buffer:marker_add(buffer.line_count - 2,
                      error.warning and M.MARK_WARNING or M.MARK_ERROR)
  end
end

-- Compiles or runs file *filename* based on a shell command in *commands*.
-- @param filename The file to run.
-- @param commands Either `compile_commands` or `run_commands`.
local function compile_or_run(filename, commands)
  if filename == buffer.filename then
    buffer:annotation_clear_all()
    io.save_file()
  end
  -- Determine the command.
  local ext = filename:match('[^/\\.]+$')
  local lexer = filename == buffer.filename and buffer:get_lexer() or
                textadept.file_types.extensions[ext]
  local command = commands[filename] or commands[ext] or commands[lexer]
  local working_dir
  if type(command) == 'function' then command, working_dir = command() end
  if not command then return end
  -- Replace macros in the command.
  local dirname, basename = '', filename
  if filename:find('[/\\]') then
    dirname, basename = filename:match('^(.+[/\\])([^/\\]+)$')
  end
  local basename_no_ext = basename:match('^(.+)%.')
  command = command:gsub('%%([pdfe])', {
    p = filename, d = dirname, f = basename, e = basename_no_ext
  })
  -- Prepare to run the command.
  preferred_view = view
  local event = commands == M.compile_commands and events.COMPILE_OUTPUT or
                events.RUN_OUTPUT
  local ext_or_lexer = commands[ext] and ext or lexer
  local function emit_output(output)
    for line in output:gmatch('[^\r\n]+') do
      events.emit(event, line, ext_or_lexer)
    end
  end
  -- Run the command.
  cwd = working_dir or dirname
  if cwd ~= dirname then events.emit(event, '> cd '..cwd) end
  events.emit(event, '> '..command:iconv('UTF-8', _CHARSET))
  proc = assert(spawn(command, cwd, emit_output, emit_output, function(status)
    events.emit(event, '> exit status: '..status)
  end))
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
M.compile_commands = {actionscript='mxmlc "%f"',ada='gnatmake "%f"',ansi_c='gcc -o "%e" "%f"',antlr='antlr4 "%f"',g='antlr3 "%f"',applescript='osacompile "%f" -o "%e.scpt"',asm='nasm "%f"'--[[ && ld "%e.o" -o "%e"']],boo='booc "%f"',caml='ocamlc -o "%e" "%f"',csharp=WIN32 and 'csc "%f"' or 'mcs "%f"',coffeescript='coffee -c "%f"',context='context --nonstopmode "%f"',cpp='g++ -o "%e" "%f"',cuda=WIN32 and 'nvcc -o "%e.exe" "%f"' or 'nvcc -o "%e" "%f"',dmd='dmd "%f"',dot='dot -Tps "%f" -o "%e.ps"',eiffel='se c "%f"',elixir='elixirc "%f"',erlang='erl -compile "%e"',faust='faust -o "%e.cpp" "%f"',fsharp=WIN32 and 'fsc.exe "%f"' or 'mono fsc.exe "%f"',fortran='gfortran -o "%e" "%f"',gap='gac -o "%e" "%f"',go='go build "%f"',groovy='groovyc "%f"',haskell=WIN32 and 'ghc -o "%e.exe" "%f"' or 'ghc -o "%e" "%f"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%f"',ltx='pdflatex -file-line-error -halt-on-error "%f"',less='lessc --no-color "%f" "%e.css"',lilypond='lilypond "%f"',lisp='clisp -c "%f"',litcoffee='coffee -c "%f"',lua='luac -o "%e.luac" "%f"',moon='moonc "%f"',markdown='markdown "%f" > "%e.html"',nemerle='ncc "%f" -out:"%e.exe"',nim='nim c "%f"',nsis='MakeNSIS "%f"',objective_c='gcc -o "%e" "%f"',pascal='fpc "%f"',perl='perl -c "%f"',php='php -l "%f"',prolog='gplc --no-top-level "%f"',python='python -m py_compile "%f"',ruby='ruby -c "%f"',rust='rustc "%f"',sass='sass "%f" "%e.css"',scala='scalac "%f"',tex='pdflatex -file-line-error -halt-on-error "%f"',vala='valac "%f"',vb=WIN32 and 'vbc "%f"' or 'vbnc "%f"',}

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
  if not filename and not buffer.filename then return end
  compile_or_run(filename or buffer.filename, M.compile_commands)
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
M.run_commands = {actionscript=WIN32 and 'start "" "%e.swf"' or OSX and 'open "file://%e.swf"' or 'xdg-open "%e.swf"',ada=WIN32 and '"%e"' or './"%e"',ansi_c=WIN32 and '"%e"' or './"%e"',applescript='osascript "%f"',asm='./"%e"',awk='awk -f "%f"',batch='"%f"',boo='booi "%f"',caml='ocamlrun "%e"',csharp=WIN32 and '"%e"' or 'mono "%e.exe"',chuck='chuck "%f"',cmake='cmake -P "%f"',coffeescript='coffee "%f"',context=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',cpp=WIN32 and '"%e"' or './"%e"',cuda=WIN32 and '"%e"' or './"%e"',dart='dart "%f"',dmd=WIN32 and '"%e"' or './"%e"',eiffel="./a.out",elixir='elixir "%f"',fsharp=WIN32 and '"%e"' or 'mono "%e.exe"',forth='gforth "%f" -e bye',fortran=WIN32 and '"%e"' or './"%e"',gnuplot='gnuplot "%f"',go='go run "%f"',groovy='groovy "%f"',haskell=WIN32 and '"%e"' or './"%e"',html=WIN32 and 'start "" "%f"' or OSX and 'open "file://%f"' or 'xdg-open "%f"',icon='icont "%e" -x',idl='idl -batch "%f"',Io='io "%f"',java='java "%e"',javascript='node "%f"',ltx=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',less='lessc --no-color "%f"',lilypond=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',lisp='clisp "%f"',litcoffee='coffee "%f"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%f"',makefile=WIN32 and 'nmake -f "%f"' or 'make -f "%f"',markdown='markdown "%f"',moon='moon "%f"',nemerle=WIN32 and '"%e"' or 'mono "%e.exe"',nim='nim c -r "%f"',objective_c=WIN32 and '"%e"' or './"%e"',pascal=WIN32 and '"%e"' or './"%e"',perl='perl "%f"',php='php "%f"',pike='pike "%f"',pkgbuild='makepkg -p "%f"',prolog=WIN32 and '"%e"' or './"%e"',pure='pure "%f"',python='python -u "%f"',rstats=WIN32 and 'Rterm -f "%f"' or 'R -f "%f"',rebol='REBOL "%f"',rexx=WIN32 and 'rexx "%f"' or 'regina "%f"',ruby='ruby "%f"',rust=WIN32 and '"%e"' or './"%e"',sass='sass "%f"',scala='scala "%e"',bash='bash "%f"',csh='tcsh "%f"',sh='sh "%f"',zsh='zsh "%f"',smalltalk='gst "%f"',snobol4='snobol4 -b "%f"',tcl='tclsh "%f"',tex=WIN32 and 'start "" "%e.pdf"' or OSX and 'open "%e.pdf"' or 'xdg-open "%e.pdf"',vala=WIN32 and '"%e"' or './"%e"',vb=WIN32 and '"%e"' or 'mono "%e.exe"',}

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
  if not filename and not buffer.filename then return end
  compile_or_run(filename or buffer.filename, M.run_commands)
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
  if not root_directory then root_directory = io.get_project_root() end
  if not root_directory then return end
  for i = 1, #_BUFFERS do _BUFFERS[i]:annotation_clear_all() end
  -- Determine command.
  local command = M.build_commands[root_directory]
  if not command then
    for build_file, build_command in pairs(M.build_commands) do
      if lfs.attributes(root_directory..'/'..build_file) then
        local button, utf8_command = ui.dialogs.inputbox{
          title = _L['Command'], informative_text = root_directory,
          text = build_command, button1 = _L['_OK'], button2 = _L['_Cancel']
        }
        if button == 1 then command = utf8_command:iconv(_CHARSET, 'UTF-8') end
        break
      end
    end
  end
  local working_dir
  if type(command) == 'function' then command, working_dir = command() end
  if not command then return end
  -- Prepare to run the command.
  preferred_view = view
  local function emit_output(output)
    for line in output:gmatch('[^\r\n]+') do
      events.emit(events.BUILD_OUTPUT, line)
    end
  end
  -- Run the command.
  cwd = working_dir or root_directory
  events.emit(event, '> cd '..cwd)
  events.emit(event, '> '..command:iconv('UTF-8', _CHARSET))
  proc = assert(spawn(command, cwd, emit_output, emit_output, function(status)
    events.emit(event, '> exit status: '..status)
  end))
end
events.connect(events.BUILD_OUTPUT, print_output)

---
-- Stops the currently running process, if any.
-- @name stop
function M.stop() if proc then proc:kill() end end

-- Send line as input to process stdin on return.
events.connect(events.CHAR_ADDED, function(code)
  if code == 10 and proc and proc:status() == 'running' and
     buffer._type == _L['[Message Buffer]'] then
    local line_num = buffer:line_from_position(buffer.current_pos) - 1
    proc:write((buffer:get_line(line_num)))
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
M.error_patterns = {actionscript={'^(.-)%((%d+)%): col: (%d+) (.+)$'},ada={'^(.-):(%d+):(%d+):%s*(.*)$','^[^:]+: (.-):(%d+) (.+)$'},ansi_c={'^(.-):(%d+):(%d+): (.+)$'},antlr={'^error%(%d+%): (.-):(%d+):(%d+): (.+)$','^warning%(%d+%): (.-):(%d+):(%d+): (.+)$'},--[[ANTLR]]g={'^error%(%d+%): (.-):(%d+):(%d+): (.+)$','^warning%(%d+%): (.-):(%d+):(%d+): (.+)$'},asm={'^(.-):(%d+): (.+)$'},awk={'^awk: (.-):(%d+): (.+)$'},boo={'^(.-)%((%d+),(%d+)%): (.+)$'},caml={'^%s*File "(.-)", line (%d+), characters (%d+)'},chuck={'^(.-)line%((%d+)%)%.char%((%d+)%): (.+)$'},cmake={'^CMake Error at (.-):(%d+)','^(.-):(%d+):$'},coffeescript={'^(.-):(%d+):(%d+): (.+)$'},context={'error on line (%d+) in file (.-): (.+)$'},cpp={'^(.-):(%d+):(%d+): (.+)$'},csharp={'^(.-)%((%d+),(%d+)%): (.+)$'},cuda={'^(.-)%((%d+)%): (error.+)$'},dart={"^'(.-)': error: line (%d+) pos (%d+): (.+)$",'%(file://(.-):(%d+):(%d+)%)'},dmd={'^(.-)%((%d+)%): (Error.+)$'},dot={'^Warning: (.-): (.+) in line (%d+)'},eiffel={'^Line (%d+) columns? .- in .- %((.-)%):$','^line (%d+) column (%d+) file (.-)$'},elixir={'^(.-):(%d+): (.+)$','Error%) (.-):(%d+): (.+)$'},erlang={'^(.-):(%d+): (.+)$'},faust={'^(.-):(%d+):(.+)$'},forth={'^(.-):(%d+): (.+)$'},fortran={'^(.-):(%d+)%D+(%d+):%s*(.*)$'},fsharp={'^(.-)%((%d+),(%d+)%): (.+)$'},gap={'^(.+) in (.-) line (%d+)$'},gnuplot={'^"(.-)", line (%d+): (.+)$'},go={'^(.-):(%d+): (.+)$'},groovy={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},haskell={'^(.-):(%d+):(%d+):%s*(.*)$'},icon={'^File (.-); Line (%d+) # (.+)$','^.-from line (%d+) in (.-)$'},java={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},javascript={'^%s+at .-%((.-):(%d+):(%d+)%)$','^%s+at (.-):(%d+):(%d+)$','^(.-):(%d+):?$'},ltx={'^(.-):(%d+): (.+)$'},less={'^(.+) in (.-) on line (%d+), column (%d+):$'},lilypond={'^(.-):(%d+):(%d+):%s*(.*)$'},litcoffee={'^(.-):(%d+):(%d+): (.+)$'},lua={'^luac?: (.-):(%d+): (.+)$'},makefile={'^(.-):(%d+): (.+)$'},nemerle={'^(.-)%((%d+),(%d+)%): (.+)$'},nim={'^(.-)%((%d+), (%d+)%) (%w+:.+)$'},objective_c={'^(.-):(%d+):(%d+): (.+)$'},pascal={'^(.-)%((%d+),(%d+)%) (%w+:.+)$'},perl={'^(.+) at (.-) line (%d+)'},php={'^(.+) in (.-) on line (%d+)$'},pike={'^(.-):(%d+):(.+)$'},prolog={'^(.-):(%d+):(%d+): (.+)$','^(.-):(%d+): (.+)$'},pure={'^(.-), line (%d+): (.+)$'},python={'^%s*File "(.-)", line (%d+)'},rexx={'^Error %d+ running "(.-)", line (%d+): (.+)$'},ruby={'^%s+from (.-):(%d+):','^(.-):(%d+):%s*(.+)$'},rust={'^(.-):(%d+):(%d+): (.+)$',"panicked at '([^']+)', (.-):(%d+)"},sass={'^WARNING on line (%d+) of (.-):$','^%s+on line (%d+) of (.-)$'},scala={'^%s+at .-%((.-):(%d+)%)$','^(.-):(%d+): (.+)$'},sh={'^(.-): (%d+): %1: (.+)$'},bash={'^(.-): line (%d+): (.+)$'},zsh={'^(.-):(%d+): (.+)$'},smalltalk={'^(.-):(%d+): (.+)$','%((.-):(%d+)%)$'},snobol4={'^(.-):(%d+): (.+)$'},tcl={'^%s*%(file "(.-)" line (%d+)%)$'},tex={'^(.-):(%d+): (.+)$'},vala={'^(.-):(%d+)%.(%d+)[%-%.%d]+: (.+)$','^(.-):(%d+):(%d+): (.+)$'},vb={'^(.-)%((%d+),(%d+)%): (.+)$'}}
-- Note: APDL,IDL,REBOL,Verilog,VHDL are proprietary.
-- Note: ASP,CSS,Desktop,diff,django,gettext,Gtkrc,HTML,ini,JSON,JSP,Markdown,Postscript,Properties,R,RHTML,XML don't have parse-able errors.
-- Note: Batch,BibTeX,ConTeXt,Dockerfile,GLSL,Inform,Io,Lisp,MoonScript,Scheme,SQL,TeX cannot be parsed for one reason or another.

-- Returns whether or not the given buffer is a message buffer.
local function is_msg_buf(buf) return buf._type == _L['[Message Buffer]'] end
---
-- Jumps to the source of the recognized compile/run warning or error on line
-- number *line* in the message buffer.
-- If *line* is `nil`, jumps to the next or previous warning or error, depending
-- on boolean *next*. Displays an annotation with the warning or error message
-- if possible.
-- @param line The line number in the message buffer that contains the
--   compile/run warning or error to go to.
-- @param next Optional flag indicating whether to go to the next recognized
--   warning/error or the previous one. Only applicable when *line* is `nil` or
--   `false`.
-- @see error_patterns
-- @name goto_error
function M.goto_error(line, next)
  if not cwd then return end -- no previously run command
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
  textadept.editing.goto_line(line + 1) -- ensure visible

  -- Goto the warning or error and show an annotation.
  local line = buffer:get_line(line):match('^[^\r\n]*')
  local error = scan_for_error(line:iconv(_CHARSET, 'UTF-8'))
  if not error then return end
  textadept.editing.select_line()
  ui.goto_file(cwd..(not WIN32 and '/' or '\\')..error.filename, true,
               preferred_view, true)
  textadept.editing.goto_line(error.line)
  if error.column then
    buffer:goto_pos(buffer:find_column(error.line - 1, error.column - 1))
  end
  if error.message then
    buffer.annotation_text[error.line - 1] = error.message
    -- Style number 8 is the error style.
    if not error.warning then buffer.annotation_style[error.line - 1] = 8 end
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

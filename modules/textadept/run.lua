-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile and run source code files with Textadept.
-- [Language modules][] may tweak the `compile_commands`, `run_commands`, and/or
-- `error_patterns` tables for particular languages.
--
-- [Language modules]: _M.html#Compile.and.Run
-- @field MARK_WARNING (number)
--   The run or compile warning marker number.
-- @field MARK_ERROR (number)
--   The run or compile error marker number.
-- @field cwd (string, Read-only)
--   The working directory for the most recently executed compile or run
--   command.
--   It is used for going to error messages with relative file paths.
-- @field _G.events.COMPILE_OUTPUT (string)
--   Emitted after executing a language's compile command.
--   By default, compiler output is printed to the message buffer. To override
--   this behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The language's lexer name.
--   * `output`: The string output from the command.
-- @field _G.events.RUN_OUTPUT (string)
--   Emitted after executing a language's run command.
--   By default, output is printed to the message buffer. To override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The language's lexer name.
--   * `output`: The string output from the command.
module('textadept.run')]]

M.MARK_WARNING = _SCINTILLA.next_marker_number()
M.MARK_ERROR = _SCINTILLA.next_marker_number()

-- Events.
events.COMPILE_OUTPUT, events.RUN_OUTPUT = 'compile_output', 'run_output'

local preferred_view

-- Executes a compile or run command.
-- Emits a `COMPILE_OUTPUT` or `RUN_OUTPUT` event based on the `compiling` flag.
-- @param commands Either `compile_commands` or `run_commands`.
-- @param compiling Flag indicating whether or not the command is a compiler
--   command. The default value is `false`.
-- @see _G.events
local function command(commands, compiling)
  if not buffer.filename then return end
  buffer:annotation_clear_all()
  io.save_file()
  local command = commands[buffer.filename:match('[^.]+$')] or
                  commands[buffer:get_lexer()]
  if not command then return end
  if type(command) == 'function' then command = command() end

  preferred_view = view
  local filepath, filedir, filename = buffer.filename, '', buffer.filename
  if filepath:find('[/\\]') then
    filedir, filename = filepath:match('^(.+[/\\])([^/\\]+)$')
  end
  local filename_noext = filename:match('^(.+)%.')
  command = command:gsub('%%%b()', {
    ['%(filepath)'] = filepath, ['%(filedir)'] = filedir,
    ['%(filename)'] = filename, ['%(filename_noext)'] = filename_noext,
  })
  local current_dir = lfs.currentdir()
  lfs.chdir(filedir)
  local event = compiling and events.COMPILE_OUTPUT or events.RUN_OUTPUT
  local events_emit = events.emit
  local lexer = buffer:get_lexer()
  events_emit(event, lexer, '> '..command:iconv('UTF-8', _CHARSET))
  local p = io.popen(command..' 2>&1')
  for line in p:lines() do
    events_emit(event, lexer, line:iconv('UTF-8', _CHARSET))
  end
  local ok, status, code = p:close()
  if ok and code then events_emit(event, lexer, status..': '..code) end
  M.cwd = filedir
  lfs.chdir(current_dir)
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

-- Prints the output from a run or compile command.
-- If the output is a recognized warning or error message, mark it.
-- @param lexer The current lexer.
-- @param output The output to print.
local function print_output(lexer, output)
  ui.print(output)
  local error = get_error(output)
  if not error then return end
  -- Current position is one line below the error due to ui.print()'s '\n'.
  buffer:marker_add(buffer.line_count - 2,
                    error.warning and M.MARK_WARNING or M.MARK_ERROR)
end

---
-- Map of file extensions (excluding the leading '.') or lexer names to their
-- associated "compile" shell command line strings or functions returning such
-- strings.
-- Command line strings may have the following macros:
--
--   + `%(filepath)`: The current file's full path.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The file's name, including its extension.
--   + `%(filename_noext)`: The file's name, excluding its extension.
-- @class table
-- @name compile_commands
M.compile_commands = {actionscript='mxmlc "%(filename)"',ada='gnatmake "%(filename)"',antlr='antlr4 "%(filename)"',g='antlr3 "%(filename)"',applescript='osacompile "%(filename)" -o "%(filename_noext).scpt"',asm='nasm "%(filename)" && ld "%(filename_noext).o" -o "%(filename_noext)"',boo='booc "%(filename)"',caml='ocamlc -o "%(filename_noext)" "%(filename)"',csharp=WIN32 and 'csc "%(filename)"' or 'mcs "%(filename)"',cpp='g++ -o "%(filename_noext)" "%(filename)"',c='gcc -o "%(filename_noext)" "%(filename)"',coffeescript='coffee -c "%(filename)"',context='context --nonstopmode "%(filename)"',cuda=WIN32 and 'nvcc -o "%(filename_noext).exe" "%(filename)"' or 'nvcc -o "%(filename_noext)" "%(filename)"',dmd='dmd "%(filename)"',dot='dot -Tps "%(filename)" -o "%(filename_noext).ps"',eiffel='se c "%(filename)"',erlang='erl -compile "%(filename_noext)"',fsharp=WIN32 and 'fsc.exe "%(filename)"' or 'mono fsc.exe "%(filename)"',fortran='gfortran -o "%(filename_noext)" "%(filename)"',gap='gac -o "%(filename_noext)" "%(filename)"',go='go build "%(filename)"',groovy='groovyc "%(filename)"',haskell=WIN32 and 'ghc -o "%(filename_noext).exe" "%(filename)"' or 'ghc -o "%(filename_noext)" "%(filename)"',inform=function() return 'inform -c "'..buffer.filename:match('^(.+%.inform[/\\])Source')..'"' end,java='javac "%(filename)"',latex='pdflatex -file-line-error -halt-on-error "%(filename)"',less='lessc "%(filename)" "%(filename_noext).css"',lilypond='lilypond "%(filename)"',lisp='clisp -c "%(filename)"',litcoffee='coffee -c "%(filename)"',lua='luac -o "%(filename_noext).luac" "%(filename)"',markdown='markdown "%(filename)" > "%(filename_noext).html"',nemerle='ncc "%(filename)" -out:"%(filename_noext).exe"',nimrod='nimrod c "%(filename)"',nsis='MakeNSIS "%(filename)"',objective_c='gcc -o "%(filename_noext)" "%(filename)"',pascal='fpc "%(filename)"',perl='perl -c "%(filename)"',php='php -l "%(filename)"',prolog='gplc --no-top-level "%(filename)"',python='python -m py_compile "%(filename)"',ruby='ruby -c "%(filename)"',sass='sass "%(filename)" "%(filename_noext).css"',scala='scalac "%(filename)"',tex='pdftex -file-line-error -halt-on-error "%(filename)"',vala='valac "%(filename)"',vb=WIN32 and 'vbc "%(filename)"' or 'vbnc "%(filename)"',}

---
-- Compiles the file based on its extension or language, using the command from
-- the `compile_commands` table.
-- Emits a `COMPILE_OUTPUT` event.
-- @see compile_commands
-- @see _G.events
-- @name compile
function M.compile() command(M.compile_commands, true) end
events.connect(events.COMPILE_OUTPUT, print_output)

---
-- Map of file extensions (excluding the leading '.') or lexer names to their
-- associated "run" shell command line strings or functions returning such
-- strings.
-- Command line strings may have the following macros:
--
--   + `%(filepath)`: The full path of the current file.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The name of the file, including its extension.
--   + `%(filename_noext)`: The name of the file, excluding its extension.
-- @class table
-- @name run_commands
M.run_commands = {actionscript=WIN32 and 'start "" "%(filename_noext).swf"' or OSX and 'open "file://%(filename_noext).swf"' or 'xdg-open "%(filename_noext).swf"',ada=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',applescript='osascript "%(filename)"',asm='./"%(filename_noext)"',awk='awk -f "%(filename)"',batch='"%(filename)"',boo='booi "%(filename)"',caml='ocamlrun "%(filename_noext)"',csharp=WIN32 and '"%(filename_noext)"' or 'mono "%(filename_noext).exe"',cpp=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',chuck='chuck "%(filename)"',cmake='cmake -P "%(filename)"',coffeescript='coffee "%(filename)"',context=WIN32 and 'start "" "%(filename_noext).pdf"' or OSX and 'open "%(filename_noext).pdf"' or 'xdg-open "%(filename_noext).pdf"',cuda=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',dmd=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',eiffel="./a.out",fsharp=WIN32 and '"%(filename_noext)"' or 'mono "%(filename_noext).exe"',forth='gforth "%(filename)" -e bye',fortran=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',gnuplot='gnuplot "%(filename)"',go='go run "%(filename)"',groovy='groovy "%(filename)"',haskell=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',hypertext=WIN32 and 'start "" "%(filename)"' or OSX and 'open "file://%(filename)"' or 'xdg-open "%(filename)"',idl='idl -batch "%(filename)"',Io='io "%(filename)"',java='java "%(filename_noext)"',javascript='node "%(filename)"',latex=WIN32 and 'start "" "%(filename_noext).pdf"' or OSX and 'open "%(filename_noext).pdf"' or 'xdg-open "%(filename_noext).pdf"',less='lessc --no-color "%(filename)"',lilypond=WIN32 and 'start "" "%(filename_noext).pdf"' or OSX and 'open "%(filename_noext).pdf"' or 'xdg-open "%(filename_noext).pdf"',lisp='clisp "%(filename)"',litcoffee='coffee "%(filename)"',lua='lua -e "io.stdout:setvbuf(\'no\')" "%(filename)"',makefile=WIN32 and 'nmake -f "%(filename)"' or 'make -f "%(filename)"',markdown='markdown "%(filename)"',nemerle=WIN32 and '"%(filename_noext)"' or 'mono "%(filename_noext).exe"',nimrod=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',objective_c=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',pascal=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',perl='perl "%(filename)"',php='php "%(filename)"',pike='pike "%(filename)"',pkgbuild='makepkg -p "%(filename)"',prolog=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',python='python "%(filename)"',rstats=WIN32 and 'Rterm -f "%(filename)"' or 'R -f "%(filename)"',rebol='REBOL "%(filename)"',rexx=WIN32 and 'rexx "%(filename_noext)"' or 'regina "%(filename_noext)"',ruby='ruby "%(filename)"',sass='sass "%(filename)"',scala='scala "%(filename_noext)"',bash='bash "%(filename)"',csh='tcsh "%(filename)"',sh='sh "%(filename)"',zsh='zsh "%(filename)"',smalltalk='gst "%(filename)"',tcl='tclsh "%(filename)"',tex=WIN32 and 'start "" "%(filename_noext).pdf"' or OSX and 'open "%(filename_noext).pdf"' or 'xdg-open "%(filename_noext).pdf"',vala=WIN32 and '"%(filename_noext)"' or './"%(filename_noext)"',vb=WIN32 and '"%(filename_noext)"' or 'mono "%(filename_noext).exe"',}

---
-- Runs the file based on its extension or language, using the command from the
-- `run_commands` table.
-- Emits a `RUN_OUTPUT` event.
-- @see run_commands
-- @see _G.events
-- @name run
function M.run() command(M.run_commands) end
events.connect(events.RUN_OUTPUT, print_output)

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
M.error_patterns = {--[[ANTLR]]'^error%(%d+%): (.-):(%d+):%d+: (.+)$','^warning%(%d+%): (.-):(%d+):%d+: (.+)$',--[[AWK]]'^awk: (.-): line (%d+): (.+)$',--[[ChucK]]'^%[(.-)%]:line%((%d+)%)%.char%(%d+%): (.+)$',--[[CMake]]'^CMake Error at (.-):(%d+)',--[[Dot]]'^Error: (.-):(%d+): (.+)$',--[[Eiffel]]'^Line (%d+) columns? .- in .- %((.-)%):$','^line (%d+) column %d+ file (.-)$',--[[CoffeeScript,LitCoffee]]'^%s+at .-%((.-):(%d+):%d+, .-%)$',--[[Groovy,Java,Javascript]]'^%s+at .-%((.-):(%d+):?%d*%)$',--[[JavaScript]]'^%s+at (.-):(%d+):%d+$',--[[GNUPlot]]'^"(.-)", line (%d+): (.+)$',--[[Lua]]'^luac?: (.-):(%d+): (.+)$',--[[Prolog]]'^warning: (.-):(%d+): (.+)$',--[[OCaml,Python]]'^%s*File "(.-)", line (%d+)',--[[Rexx]]'^Error %d+ running "(.-)", line (%d+): (.+)$',--[[Sass]]'^WARNING on line (%d+) of (.-):$','^%s+on line (%d+) of (.-)$',--[[Tcl]]'^%s*%(file "(.-)" line (%d+)%)$',--[[Actionscript]]'^(.-)%((%d+)%): col %d+ (.+)$',--[[CUDA,D]]'^(.-)%((%d+)%): ([Ee]rror.+)$',--[[Boo,C#,F#,Nemerle,VB]]'^(.-)%((%d+),%d+%): (.+)$',--[[Pascal,Nimrod]]'^(.-)%((%d+),?%s*%d*%) (%w+:.+)$',--[[Ada,C/C++,Haskell,LilyPond,Objective C,Prolog]]'^(.-):(%d+):%d+:%s*(.*)$',--[[Fortran,Vala]]'^(.-):(%d+)[%.%-][%.%d%-]+:%s*(.*)$',--[[CMake,Javascript]]'^(.-):(%d+):$',--[[Python]]'^.-: %(\'([^\']+)\', %(\'(.-)\', (%d+), %d,','^.-: (.+) %((.-), line (%d+)%)$',--[[Shell (Bash)]]'^(.-): line (%d+): (.+)$',--[[Shell (sh)]]'^(.-): (%d+): %1: (.+)$',--[[Erlang,Forth,Groovy,Go,Java,LilyPond,Makefile,Pike,Ruby,Scala,Smalltalk]]'^%s*(.-):%s*(%d+):%s*(.+)$',--[[Less]]'^(.+) in (.-) on line (%d+), column %d+:$',--[[PHP]]'^(.+) in (.-) on line (%d+)$',--[[Gap]]'^(.+) in (.-) line (%d+)$',--[[Perl]]'^(.+) at (.-) line (%d+)',--[[APDL,IDL,REBOL,Verilog,VHDL:proprietary]]--[[ASP,CSS,Desktop,diff,django,gettext,Gtkrc,HTML,ini,JSON,JSP,Markdown,Postscript,Properties,R,RHTML,XML:none]]--[[Batch,BibTeX,ConTeXt,GLSL,Inform,Io,Lisp,Scheme,SQL,TeX:cannot parse]]}

-- Returns whether or not the given buffer is a message buffer.
local function is_msg_buf(buf) return buf._type == _L['[Message Buffer]'] end
---
-- Jumps to the source of the recognized compile/run warning or error on line
-- number *line* in the message buffer or the next or previous recognized
-- warning or error depending on boolean *next*.
-- Displays an annotation with the warning or error message, if available.
-- @param line The line number in the message buffer that contains the
--   compile/run warning/error to go to.
-- @param next Optional flag indicating whether to go to the next recognized
--   warning/error or the previous one. Only applicable when *line* is `nil` or
--   `false`.
-- @see error_patterns
-- @see cwd
-- @name goto_error
function M.goto_error(line, next)
  local cur_buf, msg_view, msg_buf = _BUFFERS[buffer], nil, nil
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
    if line == -1 then if CURSES then view:goto_buffer(cur_buf) end return end
  end
  buffer:goto_line(line)

  -- Goto the warning or error and show an annotation.
  local error = get_error(buffer:get_line(line):match('^[^\r\n]+'))
  if not error then if CURSES then view:goto_buffer(cur_buf) end return end
  textadept.editing.select_line()
  ui.goto_file(M.cwd..error.filename, true, preferred_view, true)
  local line, message = error.line, error.message
  buffer:goto_line(line - 1)
  if message then
    buffer.annotation_text[line - 1] = message
    if not error.warning then buffer.annotation_style[line - 1] = 8 end -- error
  end
end
events.connect(events.DOUBLE_CLICK, function(pos, line)
  if is_msg_buf(buffer) then M.goto_error(line) end
end)

return M

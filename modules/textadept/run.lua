-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile and run/execute source files with Textadept.
-- Typically, [language modules][] populate the `compile_command`,
-- `run_command`, and `error_detail` tables for a particular language's file
-- extension.
--
-- [language modules]: _M.html#Compile.and.Run
-- @field ERROR_COLOR (string)
--   The name of the color in the current theme to mark a line containing a
--   recognized run or compile error.
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
--   * `lexer`: The lexer language name.
--   * `output`: The string output from the command.
-- @field _G.events.RUN_OUTPUT (string)
--   Emitted after executing a language's run command.
--   By default, output is printed to the message buffer. To override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The lexer language name.
--   * `output`: The string output from the command.
module('textadept.run')]]

M.ERROR_COLOR = not CURSES and 'color.light_red' or 'color.red'

-- Events.
events.COMPILE_OUTPUT, events.RUN_OUTPUT = 'compile_output', 'run_output'

local preferred_view

-- Executes a compile or run command.
-- Emits a `COMPILE_OUTPUT` or `RUN_OUTPUT` event based on the `compiling` flag.
-- @param cmd_table Either `compile_command` or `run_command`.
-- @param compiling Flag indicating whether or not the command is a compiler
--   command. The default value is `false`.
-- @see _G.events
local function command(cmd_table, compiling)
  if not buffer.filename then return end
  buffer:annotation_clear_all()
  buffer:save()
  local command = cmd_table[buffer.filename:match('[^.]+$')]
  if not command then return end
  if type(command) == 'function' then command = command() end

  preferred_view = view
  local filepath = buffer.filename:iconv(_CHARSET, 'UTF-8')
  local filedir, filename = '', filepath
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

-- Parses the given message for an error description and returns a table of the
-- error's details.
-- @param message The message to parse for errors.
-- @see error_detail
local function get_error_details(message)
  for _, error_detail in pairs(M.error_detail) do
    local captures = {message:match(error_detail.pattern)}
    if #captures > 0 then
      local details = {}
      for detail, i in pairs(error_detail) do details[detail] = captures[i] end
      return details
    end
  end
  return nil
end

local MARK_ERROR = _SCINTILLA.next_marker_number()

-- Prints the output from a run or compile command.
-- If the output is a recognized error message, mark it.
-- @param lexer The current lexer.
-- @param output The output to print.
local function print_output(lexer, output)
  ui.print(output)
  if get_error_details(output) then
    -- Current position is one line below the error due to ui.print()'s '\n'.
    buffer:marker_add(buffer.line_count - 2, MARK_ERROR)
  end
end

---
-- Map of file extensions (excluding the leading '.') to their associated
-- "compile" shell command line strings or functions returning such strings.
-- Command line strings may have the following macros:
--
--   + `%(filepath)`: The full path of the current file.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The name of the file, including its extension.
--   + `%(filename_noext)`: The name of the file, excluding its extension.
--
-- This table is typically populated by [language modules][].
--
-- [language modules]: _M.html#Compile.and.Run
-- @class table
-- @name compile_command
M.compile_command = {}

---
-- Compiles the file based on its extension using the command from the
-- `compile_command` table.
-- Emits a `COMPILE_OUTPUT` event.
-- @see compile_command
-- @see _G.events
-- @name compile
function M.compile() command(M.compile_command, true) end
events.connect(events.COMPILE_OUTPUT, print_output)

---
-- Map of file extensions (excluding the leading '.') to their associated
-- "run" shell command line strings or functions returning such strings.
-- Command line strings may have the following macros:
--
--   + `%(filepath)`: The full path of the current file.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The name of the file, including its extension.
--   + `%(filename_noext)`: The name of the file, excluding its extension.
--
-- This table is typically populated by [language modules][].
--
-- [language modules]: _M.html#Compile.and.Run
-- @class table
-- @name run_command
M.run_command = {}

---
-- Runs/executes the file based on its extension using the command from the
-- `run_command` table.
-- Emits a `RUN_OUTPUT` event.
-- @see run_command
-- @see _G.events
-- @name run
function M.run() command(M.run_command) end
events.connect(events.RUN_OUTPUT, print_output)

---
-- Map of lexer names to their error string details, tables containing the
-- following fields:
--
--   + `pattern`: A Lua pattern that matches the language's error string,
--     capturing the filename the error occurs in, the line number the error
--     occurred on, and optionally the error message.
--   + `filename`: The numeric index of the Lua capture containing the filename
--      the error occurred in.
--   + `line`: The numeric index of the Lua capture containing the line number
--      the error occurred on.
--   + `message`: (Optional) The numeric index of the Lua capture containing the
--     error's message. An annotation will be displayed if a message was
--     captured.
--
-- When an error message is double-clicked, the user is taken to the point of
-- error.
-- This table is usually populated by [language modules][].
--
-- [language modules]: _M.html#Compile.and.Run
-- @class table
-- @name error_detail
M.error_detail = {}

-- Returns whether or not the given buffer is a message buffer.
local function is_msg_buf(buf) return buf._type == _L['[Message Buffer]'] end
---
-- Goes to the source of the recognized compile/run error on line number *line*
-- in the message buffer or the next or previous recognized error depending on
-- boolean *next*.
-- Displays an annotation with the error message, if available.
-- @param line The line number in the message buffer that contains the
--   compile/run error to go to.
-- @param next Optional flag indicating whether to go to the next recognized
--   error or the previous one. Only applicable when *line* is `nil` or `false`.
-- @see error_detail
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

  -- If no line was given, find the next error marker.
  if not line and next ~= nil then
    local f = buffer['marker_'..(next and 'next' or 'previous')]
    line = f(buffer, buffer:line_from_position(buffer.current_pos) +
                     (next and 1 or -1), 2^MARK_ERROR)
    if line == -1 then
      line = f(buffer, next and 0 or buffer.line_count, 2^MARK_ERROR)
      if line == -1 then if CURSES then view:goto_buffer(cur_buf) end return end
    end
  end
  buffer:goto_line(line)

  -- Goto the error and show an annotation.
  local err = get_error_details(buffer:get_line(line))
  if not err then if CURSES then view:goto_buffer(cur_buf) end return end
  textadept.editing.select_line()
  ui.goto_file(M.cwd..err.filename, true, preferred_view, true)
  local line, message = err.line, err.message
  buffer:goto_line(line - 1)
  if message then
    buffer.annotation_text[line - 1] = message
    buffer.annotation_style[line - 1] = 8 -- error
  end
end
events.connect(events.DOUBLE_CLICK, function(pos, line)
  if is_msg_buf(buffer) then M.goto_error(line) end
end)

local CURSES_MARK = buffer.SC_MARK_CHARACTER + string.byte(' ')
-- Sets view properties for error markers.
local function set_error_properties()
  if CURSES then buffer:marker_define(MARK_ERROR, CURSES_MARK) end
  buffer.marker_back[MARK_ERROR] = buffer.property_int[M.ERROR_COLOR]
end
if buffer then set_error_properties() end
events.connect(events.VIEW_NEW, set_error_properties)

return M

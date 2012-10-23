-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Compile and run/execute source files with Textadept.
-- Typically, [language-specific modules][] populate the `compile_command`,
-- `run_command`, and `error_detail` tables for a particular language's file
-- extension.
--
-- [language-specific modules]: _M.html#Compile.and.Run
-- @field _G.events.COMPILE_OUTPUT (string)
--   Called after a compile command is executed.
--   By default, compiler output is printed to the message buffer. To override
--   this behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The lexer language.
--   * `output`: The output from the command.
-- @field _G.events.RUN_OUTPUT (string)
--   Called after a run command is executed.
--   By default, output is printed to the message buffer. To override this
--   behavior, connect to the event with an index of `1` and return `true`.
--   Arguments:
--
--   * `lexer`: The lexer language.
--   * `output`: The output from the command.
module('_M.textadept.run')]]

-- Events.
local events, events_connect, events_emit = events, events.connect, events.emit
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
  local lexer = buffer:get_lexer()
  events_emit(event, lexer, '> '..command:iconv('UTF-8', _CHARSET))
  local p = io.popen(command..' 2>&1')
  for line in p:lines() do
    events_emit(event, lexer, line:iconv('UTF-8', _CHARSET))
  end
  local ok, status, code = p:close()
  if ok and code then events_emit(event, lexer, status..': '..code) end
  lfs.chdir(current_dir)
end

-- Parses the given message for an error description and returns a table of the
-- error's details.
-- @param message The message to parse for errors.
-- @see error_detail
local function get_error_details(message)
  for _, error_detail in pairs(M.error_detail) do
    local captures = { message:match(error_detail.pattern) }
    if #captures > 0 then
      local details = {}
      for detail, i in pairs(error_detail) do details[detail] = captures[i] end
      return details
    end
  end
  return nil
end

-- Prints the output from a run or compile command.
-- If the output is an error message, an annotation is shown in the source file
-- if the file is currently open in another view.
-- @param lexer The current lexer.
-- @param output The output to print.
local function print_output(lexer, output)
  gui.print(output)
  local error_details = get_error_details(output)
  if not error_details or not error_details.message then return end
  for i = 1, #_VIEWS do
    local filename = _VIEWS[i].buffer.filename
    if filename and filename:find(error_details.filename..'$') then
      gui.goto_view(i)
      buffer.annotation_text[error_details.line - 1] = error_details.message
      buffer.annotation_style[error_details.line - 1] = 8 -- error_details
      return
    end
  end
end

---
-- File extensions and their associated "compile" shell commands.
-- Each key is a file extension whose value is a either a command line string to
-- execute or a function returning one. The command string can have the
-- following macros:
--
--   + `%(filepath)`: The full path of the current file.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The name of the file including extension.
--   + `%(filename_noext)`: The name of the file excluding extension.
--
-- This table is typically populated by [language-specific modules][].
--
-- [language-specific modules]: _M.html#Compile.and.Run
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
events_connect(events.COMPILE_OUTPUT, print_output)

---
-- File extensions and their associated "run" shell commands.
-- Each key is a file extension whose value is either a command line string to
-- execute or a function returning one. The command string can have the
-- following macros:
--
--   + `%(filepath)`: The full path of the current file.
--   + `%(filedir)`: The current file's directory path.
--   + `%(filename)`: The name of the file including extension.
--   + `%(filename_noext)`: The name of the file excluding extension.
--
-- This table is typically populated by [language-specific modules][].
--
-- [language-specific modules]: _M.html#Compile.and.Run
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
events_connect(events.RUN_OUTPUT, print_output)

---
-- A table of error string details for different programming languages.
-- Each key is a lexer name whose value is a table with the following fields:
--
--   + `pattern`: The Lua pattern that matches a specific error string with
--     captures for the filename the error occurs in, the line number the error
--     occurred on, and an optional error message.
--   + `filename`: The index of the Lua capture that contains the filename the
--     error occured in.
--   + `line`: The index of the Lua capture that contains the line number the
--     error occured on.
--   + `message`: (Optional) The index of the Lua capture that contains the
--     error's message. An annotation will be displayed if a message was
--     captured.
--
-- When an error message is double-clicked, the user is taken to the point of
-- error.
-- This table is usually populated by [language-specific modules][].
--
-- [language-specific modules]: _M.html#Compile.and.Run
-- @class table
-- @name error_detail
M.error_detail = {}

---
-- Goes to the line in the file an error occured at based on the error message
-- at the given position and displays an annotation with the error message.
-- This is typically called by an event handler for when the user double-clicks
-- on an error message.
-- @param pos The position of the caret.
-- @param line_num The line number the caret is on with the error message.
-- @see error_detail
function goto_error(pos, line_num)
  if buffer._type ~= _L['[Message Buffer]'] and
     buffer._type ~= _L['[Error Buffer]'] then
    return
  end
  local error_details = get_error_details(buffer:get_line(line_num))
  if not error_details then return end
  gui.goto_file(error_details.filename, true, preferred_view, true)
  local line, message = error_details.line, error_details.message
  buffer:goto_line(line - 1)
  if message then
    buffer.annotation_text[line - 1] = message
    buffer.annotation_style[line - 1] = 8 -- error
  end
end
events_connect(events.DOUBLE_CLICK, goto_error)

return M

-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Module for running/executing source files.
-- Typically, language-specific modules populate the `compile_command`,
-- `run_command`, and `error_detail` tables for a particular language's file
-- extension.
--
-- ## Run Events
--
-- * `_G.events.COMPILE_OUTPUT`
--   Called after a compile command is executed.
--   When connecting to this event (typically from a language-specific module),
--   connect with an index of `1` and return `true` if the event was handled and
--   you want to override the default handler that prints the output to a new
--   view.
--   Arguments:
--     * `lexer`: The lexer language.
--     * `output`: The output from the command.
-- * `_G.events.RUN_OUTPUT`
--   Called after a run command is executed.
--   When connecting to this event (typically from a language-specific module),
--   connect with an index of `1` and return `true` if the event was handled and
--   you want to override the default handler that prints the output to a new
--   view.
--   Arguments:
--     * `lexer`: The lexer language.
--     * `output`: The output from the command.
module('_M.textadept.run')]]

-- Events.
local events, events_connect, events_emit = events, events.connect, events.emit
local COMPILE_OUTPUT, RUN_OUTPUT = 'compile_output', 'run_output'
events.COMPILE_OUTPUT, events.RUN_OUTPUT = COMPILE_OUTPUT, RUN_OUTPUT

local preferred_view

---
-- Executes the command line parameter and prints the output to Textadept.
-- @param command The command line string.
--   It can have the following macros:
--     + `%(filepath)`: The full path of the current file.
--     + `%(filedir)`: The current file's directory path.
--     + `%(filename)`: The name of the file including extension.
--     + `%(filename_noext)`: The name of the file excluding extension.
-- @param lexer The current lexer.
-- @name execute
function M.execute(command, lexer)
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
  events_emit(COMPILE_OUTPUT, lexer, '> '..command:iconv('UTF-8', _CHARSET))
  local p = io.popen(command..' 2>&1')
  for line in p:lines() do
    events_emit(COMPILE_OUTPUT, lexer, line:iconv('UTF-8', _CHARSET))
  end
  local ok, status, code = p:close()
  if ok and code then events_emit(COMPILE_OUTPUT, lexer, status..': '..code) end
  lfs.chdir(current_dir)
end

-- Executes a compile or run command.
-- @param cmd_table Either `compile_command` or `run_command`.
-- @param lexer The current lexer.
local function command(cmd_table, lexer)
  if not buffer.filename then return end
  buffer:save()
  local action = cmd_table[buffer.filename:match('[^.]+$')]
  if not action then return end
  M.execute(type(action) == 'function' and action() or action, lexer)
end

---
-- File extensions and their associated 'compile' actions.
-- Each key is a file extension whose value is a either a command line string to
-- execute or a function returning one.
-- This table is typically populated by language-specific modules.
-- @class table
-- @name compile_command
M.compile_command = {}

---
-- Compiles the file as specified by its extension in the `compile_command`
-- table.
-- @see compile_command
-- @name compile
function M.compile() command(M.compile_command, buffer:get_lexer()) end
events_connect(COMPILE_OUTPUT, function(lexer, output) gui.print(output) end)

---
-- File extensions and their associated 'go' actions.
-- Each key is a file extension whose value is either a command line string to
-- execute or a function returning one.
-- This table is typically populated by language-specific modules.
-- @class table
-- @name run_command
M.run_command = {}

---
-- Runs/executes the file as specified by its extension in the `run_command`
-- table.
-- @see run_command
-- @name run
function M.run() command(M.run_command, buffer:get_lexer()) end
events_connect(RUN_OUTPUT, function(lexer, output) gui.print(output) end)

---
-- A table of error string details.
-- Each entry is a table with the following fields:
--
--   + `pattern`: The Lua pattern that matches a specific error string.
--   + `filename`: The index of the Lua capture that contains the filename the
--     error occured in.
--   + `line`: The index of the Lua capture that contains the line number the
--     error occured on.
--   + `message`: [Optional] The index of the Lua capture that contains the
--     error's message. A call tip will be displayed if a message was captured.
--
-- When an error message is double-clicked, the user is taken to the point of
-- error.
-- This table is usually populated by language-specific modules.
-- @class table
-- @name error_detail
M.error_detail = {}

---
-- When the user double-clicks an error message, go to the line in the file
-- the error occured at and display a calltip with the error message.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
-- @see error_detail
function goto_error(pos, line_num)
  if buffer._type ~= _L['[Message Buffer]'] and
     buffer._type ~= _L['[Error Buffer]'] then
    return
  end
  line = buffer:get_line(line_num)
  for _, error_detail in pairs(M.error_detail) do
    local captures = { line:match(error_detail.pattern) }
    if #captures > 0 then
      local utf8_filename = captures[error_detail.filename]
      local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
      gui.goto_file(utf8_filename, true, preferred_view, true)
      _M.textadept.editing.goto_line(captures[error_detail.line])
      local msg = captures[error_detail.message]
      if msg then buffer:call_tip_show(buffer.current_pos, msg) end
      return
    end
  end
end
events_connect(events.DOUBLE_CLICK, goto_error)

return M

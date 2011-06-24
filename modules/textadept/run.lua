-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Module for running/executing source files.
-- Typically, language-specific modules populate the 'compile_command',
-- 'run_command', and 'error_detail' tables for a particular language's file
-- extension.
module('_m.textadept.run', package.seeall)

---
-- Executes the command line parameter and prints the output to Textadept.
-- @param command The command line string.
--   It can have the following macros:
--     * %(filepath) The full path of the current file.
--     * %(filedir) The current file's directory path.
--     * %(filename) The name of the file including extension.
--     * %(filename_noext) The name of the file excluding extension.
function execute(command)
  local filepath = buffer.filename:iconv(_CHARSET, 'UTF-8')
  local filedir, filename = '', filepath
  if filepath:find('[/\\]') then
    filedir, filename = filepath:match('^(.+[/\\])([^/\\]+)$')
  end
  local filename_noext = filename:match('^(.+)%.')
  command = command:gsub('%%%b()', {
    ['%(filepath)'] = filepath,
    ['%(filedir)'] = filedir,
    ['%(filename)'] = filename,
    ['%(filename_noext)'] = filename_noext,
  })
  local current_dir = lfs.currentdir()
  lfs.chdir(filedir)
  local p = io.popen(command..' 2>&1')
  local out = p:read('*all')
  p:close()
  lfs.chdir(current_dir)
  gui.print(('> '..command..'\n'..out):iconv('UTF-8', _CHARSET))
end

-- Executes a compile or run command.
-- @param cmd_table Either compile_command or run_command
local function command(cmd_table)
  if not buffer.filename then return end
  buffer:save()
  local action = cmd_table[buffer.filename:match('[^.]+$')]
  if action then execute(type(action) == 'function' and action() or action) end
end

---
-- File extensions and their associated 'compile' actions.
-- Each key is a file extension whose value is a either a command line string to
-- execute or a function returning one.
-- This table is typically populated by language-specific modules.
-- @class table
-- @name compile_command
compile_command = {}

---
-- Compiles the file as specified by its extension in the compile_command
-- table.
-- @see compile_command
function compile() command(compile_command) end

---
-- File extensions and their associated 'go' actions.
-- Each key is a file extension whose value is either a command line string to
-- execute or a function returning one.
-- This table is typically populated by language-specific modules.
-- @class table
-- @name run_command
run_command = {}

---
-- Runs/executes the file as specified by its extension in the run_command
-- table.
-- @see run_command
function run() command(run_command) end

---
-- A table of error string details.
-- Each entry is a table with the following fields:
--   pattern: the Lua pattern that matches a specific error string.
--   filename: the index of the Lua capture that contains the filename the error
--     occured in.
--   line: the index of the Lua capture that contains the line number the error
--     occured on.
--   message: [Optional] the index of the Lua capture that contains the error's
--     message. A call tip will be displayed if a message was captured.
-- When an error message is double-clicked, the user is taken to the point of
--   error.
-- This table is usually populated by language-specific modules.
-- @class table
-- @name error_detail
error_detail = {}

---
-- When the user double-clicks an error message, go to the line in the file
-- the error occured at and display a calltip with the error message.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
-- @see error_detail
function goto_error(pos, line_num)
  local type = buffer._type
  if type == L('[Message Buffer]') or type == L('[Error Buffer]') then
    line = buffer:get_line(line_num)
    for _, error_detail in pairs(error_detail) do
      local captures = { line:match(error_detail.pattern) }
      if #captures > 0 then
        local utf8_filename = captures[error_detail.filename]
        local filename = utf8_filename:iconv(_CHARSET, 'UTF-8')
        if lfs.attributes(filename) then
          io.open_file(utf8_filename)
          _m.textadept.editing.goto_line(captures[error_detail.line])
          local msg = captures[error_detail.message]
          if msg then buffer:call_tip_show(buffer.current_pos, msg) end
        else
          error(string.format('"%s" %s', utf8_filename, L('does not exist')))
        end
        break
      end
    end
  end
end
events.connect(events.DOUBLE_CLICK, goto_error)

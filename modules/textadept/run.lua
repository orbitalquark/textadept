-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Module for running/executing source files.
module('_m.textadept.run', package.seeall)

--- [Local function] Prints a command to Textadept.
local function print_command(cmd, output)
  textadept.print('> '..cmd..'\n'..output)
  buffer:goto_pos(buffer.length)
end

---
-- Passes the current file to a specified compiler to run with the given flags
-- and prints the output to Textadept.
-- @param compiler The system's compiler for the file.
-- @param flags A string of flags to pass to the interpreter.
-- @param args Table of arguments key keys as follows:
--   * filename_noext_with_flag The value of this flag passed to the compiler
--                              is the filename without its extension.
function compiler(compiler, cflags, args)
  if type(cflags) ~= 'string' then cflags = '' end
  if not args then args = {} end
  local file = buffer.filename
  if args.filename_noext_with_flag then
    local filename_noext = file:match('^(.+)%.')
    local flag = args.filename_noext_with_flag
    cflags = string.format('%s %s"%s"', cflags, flag, filename_noext)
  end
  local command = string.format('%s %s "%s" 2>&1', compiler, cflags, file)
  local p = io.popen(command)
  local out = p:read('*all')
  p:close()
  print_command(command, out)
end

---
-- Passes the current file to a specified interpreter to run with the given
-- flags and prints the output to Textadept.
-- @param interpreter The system's interpreter for the file.
-- @param flags A string of flags to pass to the interpreter.
-- @param args Table of arguments with keys as follows:
--   * noext Do not include the filename's extension when passing to the
--           interpreter.
--   * nopath Do not include the full filepath, only the file's name.
--   * nopath_path_with_flag Same as nopath, but use the path as the value of
--                           a flag passed to the interpreter.
function interpreter(interpreter, flags, args)
  if type(flags) ~= 'string' then flags = '' end
  if not args then args = {} end
  local file = buffer.filename
  if args.noext then file = file:match('^(.+)%.') end
  if args.nopath then file = file:match('[^/\\]+$') end
  if args.nopath_path_with_flag then
    local path = file:match('^.+/')
    local flag = args.nopath_path_with_flag
    flags = string.format('%s %s"%s"', flags, flag, path)
    file = file:match('[^/\\]+$')
  end
  local command = string.format('%s %s "%s" 2>&1', interpreter, flags, file)
  local p = io.popen(command)
  local out = p:read('*all')
  p:close()
  print_command(command, out)
end

-- TODO: makefile
-- TODO: etc.

---
-- [Local table] File extensions and their associated 'compile' actions.
-- Each key is a file extension whose value is a table with the compile function
-- and parameters given as an ordered list.
-- @class table
-- @name compile_for_ext
local compile_for_ext = {
  c = { compiler, 'gcc', '-pedantic -Os',
        { filename_noext_with_flag = '-o ' } },
  cpp = { compiler, 'g++', '-pedantic -Os',
          { filename_noext_with_flag = '-o ' } },
  java = { compiler, 'javac' },
}

---
-- Compiles the file as specified by its extension in the compile_for_ext table.
-- @see compile_for_ext
function compile()
  local ext = buffer.filename:match('[^.]+$')
  local action = compile_for_ext[ext]
  if not action then return end
  local f, args = action[1], { unpack(action) }
  table.remove(args, 1) -- function
  f(unpack(args))
end

---
-- [Local table] File extensions and their associated 'go' actions.
-- Each key is a file extension whose value is a table with the run function
-- and parameters given as an ordered list.
-- @class table
-- @name go_for_ext
local go_for_ext = {
  c = { interpreter, '', '', { noext = true } },
  cpp = { interpreter, '', '', { noext = true } },
  java = { interpreter, 'java', '',
           { noext = true, nopath_path_with_flag = '-cp '  } },
  lua = { interpreter, 'lua' },
  pl = { interpreter, 'perl' },
  php = { interpreter, 'php', '-f' },
  py = { interpreter, 'python' },
  rb = { interpreter, 'ruby' },
}

---
-- Runs/executes the file as specified by its extension in the go_for_ext table.
-- @see go_for_ext
function go()
  local ext = buffer.filename:match('[^.]+$')
  local action = go_for_ext[ext]
  if not action then return end
  local f, args = action[1], { unpack(action) }
  table.remove(args, 1) -- function
  f(unpack(args))
end

---
-- [Local table] A table of error string details.
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
-- @class table
-- @name error_details
local error_details = {
  -- c, c++, and java errors and warnings have the same format as ruby ones
  lua = {
    pattern = '^lua: (.-):(%d+): (.+)$',
    filename = 1, line = 2, message = 3
  },
  perl = {
    pattern = '^(.+) at (.-) line (%d+)',
    message = 1, filename = 2, line = 3
  },
  php_error = {
    pattern = '^Parse error: (.+) in (.-) on line (%d+)',
    message = 1, filename = 2, line = 3
  },
  php_warning = {
    pattern = '^Warning: (.+) in (.-) on line (%d+)',
    message = 1, filename = 2, line = 3
  },
  python = {
    pattern = '^%s*File "([^"]+)", line (%d+)',
    filename = 1, line = 2
  },
  ruby = {
    pattern = '^(.-):(%d+): (.+)$',
    filename = 1, line = 2, message = 3
  },
}

---
-- When the user double-clicks an error message, go to the line in the file
-- the error occured at and display a calltip with the error message.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
-- @see error_details
function goto_error(pos, line_num)
  if buffer.shows_errors then
    line = buffer:get_line(line_num)
    for _, error_detail in pairs(error_details) do
      local captures = { line:match(error_detail.pattern) }
      if #captures > 0 then
        textadept.io.open(captures[error_detail.filename])
        _m.textadept.editing.goto_line(captures[error_detail.line])
        local msg = captures[error_detail.message]
        if msg then buffer:call_tip_show(buffer.current_pos, msg) end
        break
      end
    end
  end
end
textadept.events.add_handler('double_click', goto_error)

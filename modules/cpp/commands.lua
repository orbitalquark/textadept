-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the cpp module.
module('_m.cpp.commands', package.seeall)

-- Markdown:
-- ## Key Commands
--
-- + `Alt+L, M`: Open this module for editing.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `->`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `Ctrl+I`: (Windows and Linux) Autocomplete symbol.
-- + `~`: (Mac OSX) Autocomplete symbol.
-- + `Tab`: When the caret is to the right of a `(` in a known function call,
--   show a calltip with documentation for the function.
-- + `Shift+Return`: Add ';' to line end and insert newline.

local m_editing, m_run = _m.textadept.editing, _m.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.cpp = '//'
-- Compile and Run command tables use file extensions.
m_run.compile_command.c =
  'gcc -pedantic -Os -o "%(filename_noext)" %(filename)'
m_run.compile_command.cpp =
  'g++ -pedantic -Os -o "%(filename_noext)" %(filename)'
m_run.run_command.c = '%(filedir)%(filename_noext)'
m_run.run_command.cpp = '%(filedir)%(filename_noext)'
m_run.error_detail.c = {
  pattern = '^(.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

-- C++-specific key commands.
local cppsense = _m.cpp.adeptsense.sense
local keys = _G.keys
if type(keys) == 'table' then
  keys.cpp = {
    al = {
      m = { io.open_file,
            (_HOME..'/modules/cpp/init.lua'):iconv('UTF-8', _CHARSET) },
    },
    ['s\n'] = { function()
      buffer:line_end()
      buffer:add_text(';')
      buffer:new_line()
    end },
    [not OSX and 'ci' or '~'] = { cppsense.complete, cppsense },
    ['\t'] = { function()
      if string.char(buffer.char_at[buffer.current_pos - 1]) ~= '(' then
        return false
      end
      return cppsense:show_apidoc()
    end },
  }
end

---
-- This module contains no functions.
function no_functions() end no_functions = nil

-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Commands for the cpp module.
module('_m.cpp.commands', package.seeall)

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
local keys = _G.keys
if type(keys) == 'table' then
  keys.cpp = {
    al = {
      m = { io.open_file,
            textadept.iconv(_HOME..'/modules/cpp/init.lua',
                            'UTF-8', _CHARSET) },
    },
    ['s\n'] = { function()
      buffer:line_end()
      buffer:add_text(';')
      buffer:new_line()
    end },
  }
end

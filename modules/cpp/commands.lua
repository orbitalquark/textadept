-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Commands for the cpp module.
module('_m.cpp.commands', package.seeall)

local run = _m.textadept.run
if run then
  run.compile_command.c = 'gcc -pedantic -Os -o "%(filename_noext)" %(filename)'
  run.compile_command.cpp = 'g++ -pedantic -Os -o "%(filename_noext)" %(filename)'
  run.run_command.c = '%(filedir)%(filename_noext)'
  run.run_command.cpp = '%(filedir)%(filename_noext)'
  run.error_detail.c = {
    pattern = '^(.-):(%d+): (.+)$',
    filename = 1, line = 2, message = 3
  }
end

-- C++-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  local m_editing = _m.textadept.editing
  keys.cpp = {
    al = {
      m = { textadept.io.open,
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

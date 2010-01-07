-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Commands for the cpp module.
module('_m.cpp.commands', package.seeall)

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
    ['('] = { function()
      m_editing.show_call_tip(_m.cpp.api, true)
      return false
    end },
  }
end

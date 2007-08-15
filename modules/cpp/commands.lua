-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the cpp module.
module('_m.cpp.commands', package.seeall)

-- C++-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  local m_editing = _m.textadept.editing
  keys.cpp = {
    al = { textadept.io.open, _HOME..'/modules/cpp/init.lua' },
    ['s\n'] = { function()
      buffer:line_end()
      buffer:add_text(';')
      buffer:new_line()
    end },
    cq = { m_editing.block_comment, '//~' },
    ['('] = { function()
      m_editing.show_call_tip(_m.cpp.api, true)
      return false
    end },
  }
end

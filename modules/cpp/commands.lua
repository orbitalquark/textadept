-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the cpp module.
module('modules.cpp.commands', package.seeall)

-- C++-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  local m_editing = modules.textadept.editing
  local m_handlers = textadept.handlers
  keys.cpp = {
    al = { textadept.io.open, _HOME..'/modules/cpp/init.lua' },
    ['s\n'] = { function()
      buffer:line_end()
      buffer:add_text(';')
      buffer:new_line()
    end },
    cq = { m_editing.block_comment, '//~' },
    ['('] = { function()
--~      buffer.word_chars =
--~        '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      m_editing.show_call_tip(modules.cpp.api, true)
--~      buffer:set_chars_default()
      return false
    end },
  }
end

-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the lua module.
module('_m.lua.commands', package.seeall)

local m_editing, m_run = _m.textadept.editing, _m.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.lua = '--'
-- Compile and Run command tables use file extensions.
m_run.run_command.lua = 'lua %(filename)'
m_run.error_detail.lua = {
  pattern = '^lua: (.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

---
-- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%b()%s*$', '^%s*local%s*function'
}

---
-- Tries to autocomplete Lua's 'end' keyword for control structures like 'if',
-- 'while', 'for', etc.
-- @see control_structure_patterns
function try_to_autocomplete_end()
  local buffer = buffer
  buffer:begin_undo_action()
  buffer:line_end()
  buffer:new_line()
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num - 1)
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = buffer.line_indentation[line_num - 1]
      buffer:add_text(patt:find('repeat') and '\nuntil' or '\nend')
      buffer.line_indentation[line_num + 1] = indent
      buffer.line_indentation[line_num] = indent + buffer.indent
      buffer:line_up()
      buffer:line_end()
      break
    end
  end
  buffer:end_undo_action()
end

---
-- Determines the Lua file being 'require'd, searches through package.path for
-- that file, and opens it in Textadept.
function goto_required()
  local buffer = buffer
  local line = buffer:get_cur_line()
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not file then return end
  file = file:sub(2, -2):gsub('%.', '/')
  local lfs = require 'lfs'
  for path in package.path:gmatch('[^;]+') do
    path = path:gsub('?', file)
    if lfs.attributes(path) then
      io.open_file(path:iconv('UTF-8', _CHARSET))
      break
    end
  end
end

-- Lua-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  keys.lua = {
    al = {
      m = { io.open_file,
            (_HOME..'/modules/lua/init.lua'):iconv('UTF-8', _CHARSET) },
      g = { goto_required },
    },
    ['s\n'] = { try_to_autocomplete_end },
  }
end

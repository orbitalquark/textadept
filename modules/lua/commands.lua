-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the lua module.
module('_m.lua.commands', package.seeall)

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
  buffer:line_end() buffer:new_line()
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num - 1)
  for _, patt in ipairs(control_structure_patterns) do
    if line:match(patt) then
      local indent = buffer.line_indentation[line_num - 1]
      buffer:add_text( patt:match('repeat') and '\nuntil' or '\nend' )
      buffer.line_indentation[line_num + 1] = indent
      buffer.line_indentation[line_num] = indent + buffer.indent
      buffer:line_up() buffer:line_end()
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
  local line = buffer:get_line( buffer:line_from_position(buffer.current_pos) )
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  file = file:sub(2, -2):gsub('%.', '/')
  for path in package.path:gmatch('[^;]+') do
    path = path:gsub('?', file)
    local f = io.open(path)
    if f then f:close() textadept.io.open(path) break end
  end
end

---
-- Executes the current file.
function run()
  local buffer = buffer
  local cmd = 'lua "'..buffer.filename..'" 2>&1'
  local p = io.popen(cmd)
  local out = p:read('*all')
  p:close()
  textadept.print('> '..cmd..'\n'..out)
end

-- Lua-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  local m_editing = _m.textadept.editing
  keys.lua = {
    al = { textadept.io.open, _HOME..'/modules/lua/init.lua' },
    ac = {
      g = { goto_required }
    },
    ['s\n'] = { try_to_autocomplete_end },
    cq = { m_editing.block_comment, '--~' },
    cg = { run },
    ['('] = { function()
      buffer.word_chars =
        '_.:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      m_editing.show_call_tip(_m.lua.api, true)
      buffer:set_chars_default()
      return false
    end },
  }
end

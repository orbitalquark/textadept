-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the lua module.
module('_m.lua.commands', package.seeall)

-- Markdown:
-- ## Key Commands
--
-- + `Alt+L, M`: Open this module for editing.
-- + `Alt+L, G`: Goto file being 'require'd on the current line.
-- + `Shift+Return`: Try to autocomplete an `if`, `for`, etc. statement with
--   `end`.
-- + `.`: When to the right of a known symbol, show an autocompletion list of
--   fields and functions.
-- + `:`: When to the right of a known symbol, show an autocompletion list of
--   functions only.
-- + `Ctrl+I`: (Windows and Linux) Autocomplete symbol.
-- + `~`: (Mac OSX) Autocomplete symbol.
-- + `Tab`: When the caret is to the right of a `(` in a known function call,
--   show a calltip with documentation for the function.

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
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num)
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = buffer.line_indentation[line_num]
      buffer:begin_undo_action()
      buffer:new_line()
      buffer:new_line()
      buffer:add_text(patt:find('repeat') and 'until' or 'end')
      buffer.line_indentation[line_num + 1] = indent + buffer.indent
      buffer:line_up()
      buffer:line_end()
      buffer:end_undo_action()
      return true
    end
  end
  return false
end

---
-- Determines the Lua file being 'require'd, searches through package.path for
-- that file, and opens it in Textadept.
function goto_required()
  local line = buffer:get_cur_line()
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not file then return end
  file = file:sub(2, -2):gsub('%.', '/')
  for path in package.path:gmatch('[^;]+') do
    path = path:gsub('?', file)
    if lfs.attributes(path) then
      io.open_file(path:iconv('UTF-8', _CHARSET))
      break
    end
  end
end

events.connect('file_after_save',
  function() -- show syntax errors as annotations
    if buffer:get_lexer() == 'lua' then
      local buffer = buffer
      buffer:annotation_clear_all()
      local text = buffer:get_text()
      text = text:gsub('^#![^\n]+', '') -- ignore shebang line
      local _, err = loadstring(text)
      if err then
        local line, msg = err:match('^.-:(%d+):%s*(.+)$')
        line = tonumber(line)
        if line then
          buffer.annotation_visible = 2
          buffer:annotation_set_text(line - 1, msg)
          buffer.annotation_style[line - 1] = 8 -- error style number
          buffer:goto_line(line - 1)
        end
      end
    end
  end)

-- Lua-specific key commands.
local keys = _G.keys
local luasense = _m.lua.adeptsense.sense
if type(keys) == 'table' then
  keys.lua = {
    al = {
      m = { io.open_file,
            (_HOME..'/modules/lua/init.lua'):iconv('UTF-8', _CHARSET) },
      g = { goto_required },
    },
    ['s\n'] = { try_to_autocomplete_end },
    [not OSX and 'ci' or '~'] = { function()
      local line, pos = buffer:get_cur_line()
      local symbol = line:sub(1, pos):match(luasense.syntax.symbol_chars..'*$')
      return luasense:complete(false, symbol:find(':'))
    end },
    ['\t'] = { function()
      if string.char(buffer.char_at[buffer.current_pos - 1]) ~= '(' then
        return false
      end
      return luasense:show_apidoc()
    end },
  }
end

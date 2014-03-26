-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The lua module.
-- It provides utilities for editing Lua code.
--
-- ## Key Bindings
--
-- + `Ctrl+L, M` (`⌘L, M` on Mac OSX | `M-L, M` in curses)
--   Open this module for editing.
-- + `.`
--   Show an autocompletion list of fields for the symbol behind the caret.
-- + `:`
--   Show an autocompletion list of functions for the symbol behind the caret.
-- + `Shift+Enter` (`⇧↩` | `S-Enter`)
--   Autocomplete an `if`, `while`, `for`, etc. control structure with the `end`
--   keyword.
-- @field sense
--   The Lua [Adeptsense](textadept.adeptsense.html).
--   It loads user tags from *`_USERHOME`/modules/lua/tags* and user apidocs
--   from *`_USERHOME`/modules/lua/api*.
module('_M.lua')]]

-- Adeptsense.

M.sense = textadept.adeptsense.new('lua')
M.sense.syntax.class_definition = 'module%s*%(?%s*[\'"]([%w_%.]+)'
M.sense.syntax.symbol_chars = '[%w_%.:]'
M.sense.syntax.type_declarations = {}
M.sense.syntax.type_assignments = {
  ['^[\'"]'] = 'string', -- foo = 'bar' or foo = "bar"
  ['^([%w_%.]+)%s*$'] = '%1', -- foo = textadept.adeptsense
  ['^(_M%.textadept%.adeptsense)%.new'] = '%1',
  ['require%s*%(?%s*(["\'])([%w_%.]+)%1%)?'] = '%2',
  ['^io%.p?open%s*%b()%s*$'] = 'file',
  ['^spawn%s*%b()%s*$'] = 'proc'
}
M.sense.api_files = {_HOME..'/modules/lua/api'}
M.sense:add_trigger('.')
M.sense:add_trigger(':', false, true)

-- script/update_doc generates a fake set of ctags used for autocompletion.
local as = textadept.adeptsense
M.sense.ctags_kinds = {
  f = as.FUNCTION, F = as.FIELD, m = as.CLASS, t = as.FIELD
}
M.sense:load_ctags(_HOME..'/modules/lua/tags', true)

-- Strips '_G' from symbols since it's implied.
function M.sense:get_symbol()
  local symbol, part = self.super.get_symbol(self)
  if symbol:find('^_G') then symbol = symbol:gsub('_G%.?', '') end
  if part == '_G' then part = '' end
  return symbol, part
end

-- Shows an autocompletion list for the symbol behind the caret.
-- If the symbol contains a ':', only display functions. Otherwise, display
-- both functions and fields.
function M.sense:complete(only_fields, only_functions)
  local line, pos = buffer:get_cur_line()
  local symbol = line:sub(1, pos):match(self.syntax.symbol_chars..'*$')
  return self.super.complete(self, false, symbol:find(':'))
end

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/lua/tags') then
  M.sense:load_ctags(_USERHOME..'/modules/lua/tags')
end
if lfs.attributes(_USERHOME..'/modules/lua/api') then
  M.sense.api_files[#M.sense.api_files + 1] = _USERHOME..'/modules/lua/api'
end

-- Commands.

---
-- List of patterns for auto-`end` completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%b()%s*$', '^%s*local%s*function'
}

---
-- Tries to autocomplete control structures like `if`, `while`, `for`, etc. with
-- the `end` keyword.
-- @see control_structure_patterns
-- @name try_to_autocomplete_end
function M.try_to_autocomplete_end()
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num)
  local line_indentation = buffer.line_indentation
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = line_indentation[line_num]
      buffer:begin_undo_action()
      buffer:new_line()
      buffer:new_line()
      buffer:add_text(patt:find('repeat') and 'until' or 'end')
      line_indentation[line_num + 1] = indent + buffer.tab_width
      buffer:line_up()
      buffer:line_end()
      buffer:end_undo_action()
      return true
    end
  end
  return false
end

-- Show syntax errors as annotations.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() ~= 'lua' then return end
  buffer:annotation_clear_all()
  local text = buffer:get_text():gsub('^#![^\n]+', '') -- ignore shebang line
  local f, err = load(text)
  if f then return end
  local line, msg = err:match('^.-:(%d+):%s*(.+)$')
  if line then
    buffer.annotation_text[line - 1] = msg
    buffer.annotation_style[line - 1] = 8 -- error style number
    buffer:goto_line(line - 1)
  end
end)

---
-- Container for Lua-specific key bindings.
-- @class table
-- @name _G.keys.lua
keys.lua = {
  [keys.LANGUAGE_MODULE_PREFIX] = {
    m = {io.open_file, _HOME..'/modules/lua/init.lua'},
  },
  ['s\n'] = M.try_to_autocomplete_end,
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Container for Lua-specific snippets.
-- @class table
-- @name _G.snippets.lua
  snippets.lua = {
    l = "local %1(expr)%2( = %3(value))",
    p = "print(%0)",
    f = "function %1(name)(%2(args))\n\t%0\nend",
    ['for'] = "for i = %1(1), %2(10)%3(, -1) do\n\t%0\nend",
    fori = "for %1(i), %2(val) in ipairs(%3(table)) do\n\t%0\nend",
    forp = "for %1(k), %2(v) in pairs(%3(table)) do\n\t%0\nend",
  }
end

return M

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
-- + `Shift+Enter` (`⇧↩` | `S-Enter`)
--   Autocomplete an `if`, `while`, `for`, etc. control structure with the `end`
--   keyword.
module('_M.lua')]]

-- Autocompletion and documentation.

---
-- List of "fake" ctags files to use for autocompletion.
-- The kind 'm' is recognized as a module, 'f' as a function, 't' as a table and
-- 'F' as a module or table field.
-- @class table
-- @name tags
-- @see textadept.editing.autocomplete
M.tags = {_HOME..'/modules/lua/tags', _USERHOME..'/modules/lua/tags'}

---
-- Map of expression patterns to their types.
-- Expressions are expected to match after the '=' sign of a statement.
-- @class table
-- @name expr_types
-- @usage _M.lua.expr_types['^spawn%b()%s*$'] = 'proc'
M.expr_types = {['^[\'"]'] = 'string', ['^io%.p?open%s*%b()%s*$'] = 'file'}

local XPM = textadept.editing.XPM_IMAGES
local xpms = {m = XPM.CLASS, f = XPM.METHOD, F = XPM.VARIABLE, t = XPM.TYPEDEF}

textadept.editing.autocompleters.lua = function()
  local list = {}
  -- Retrieve the symbol behind the caret.
  local line, pos = buffer:get_cur_line()
  local symbol, op, part = line:sub(1, pos):match('([%w_%.]-)([%.:]?)([%w_]*)$')
  if symbol == '' and part == '' and op ~= '' then return nil end -- lone .
  symbol, part = symbol:gsub('^_G%.?', ''), part ~= '_G' and part or ''
  -- Attempt to identify string type and file type symbols.
  local buffer = buffer
  local assignment = '%f[%w_]'..symbol:gsub('(%p)', '%%%1')..'%s*=%s*(.*)$'
  for i = buffer:line_from_position(buffer.current_pos) - 1, 0, -1 do
    local expr = buffer:get_line(i):match(assignment)
    if expr then
      for patt, type in pairs(M.expr_types) do
        if expr:find(patt) then symbol = type break end
      end
    end
  end
  -- Search through ctags for completions for that symbol.
  local name_patt = '^'..part
  local sep = string.char(buffer.auto_c_type_separator)
  for i = 1, #M.tags do
    if lfs.attributes(M.tags[i]) then
      for line in io.lines(M.tags[i]) do
        local name = line:match('^%S+')
        if name:find(name_patt) and not list[name] then
          local fields = line:match(';"\t(.*)$')
          local k, class = fields:sub(1, 1), fields:match('class:(%S+)') or ''
          if class == symbol and (op ~= ':' or k == 'f') then
            list[#list + 1] = ("%s%s%d"):format(name, sep, xpms[k])
            list[name] = true
          end
        end
      end
    end
  end
  return #part, list
end

textadept.editing.api_files.lua = {
  _HOME..'/modules/lua/api', _USERHOME..'/modules/lua/api'
}

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
    f = "function %1(name)(%2(args))\n\t%0\nend",
    ['for'] = "for %1(i) = %2(1), %3(10)%4(, %5(-1)) do\n\t%0\nend",
    fori = "for %1(i), %2(v) in ipairs(%3(t)) do\n\t%0\nend",
    forp = "for %1(k), %2(v) in pairs(%3(t)) do\n\t%0\nend"
  }
end

return M

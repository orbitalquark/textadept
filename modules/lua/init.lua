-- Copyright 2007-2023 Mitchell. See LICENSE.

local M = {}

-- Autocompletion and documentation.

-- Returns a function that, when called from a Textadept Lua file, the Lua command entry, or
-- a special Lua buffer (e.g. a REPL), returns the given Textadept tags or API file for use in
-- autocompletion and documentation.
-- @param filename Textadept tags or api file to return.
local function ta_api(filename)
  local home = '^' .. _HOME:gsub('%p', '%%%0'):gsub('%%[/\\]', '[/\\]')
  local userhome = '^' .. _USERHOME:gsub('%p', '%%%0'):gsub('%%[/\\]', '[/\\]')
  return function()
    local ta_file = (buffer.filename or ''):find(home) or (buffer.filename or ''):find(userhome)
    return (ta_file or ui.command_entry.active or buffer._type) and filename
  end
end

-- List of "fake" ctags files (or functions that return such files) to use for autocompletion.
-- The kind 'm' is recognized as a module, 'f' as a function, 't' as a table and 'F' as a module
-- or table field.
-- The *modules/lua/tadoc.lua* script can generate *tags* and [*api*](#textadept.editing.api_files)
-- files for Lua modules via LuaDoc.
-- @class table
-- @name tags
M.tags = {
  _HOME .. '/modules/lua/tags', _USERHOME .. '/modules/lua/tags',
  ta_api(_HOME .. '/modules/lua/ta_tags')
}

-- Map of expression patterns to their types.
-- Used for type-hinting when showing autocompletions for variables. Expressions are expected
-- to match after the '=' sign of a statement.
-- @class table
-- @name expr_types
-- @usage _M.lua.expr_types['^spawn%b()%s*$'] = 'proc'
M.expr_types = {['^[\'"]'] = 'string', ['^io%.p?open%s*%b()%s*$'] = 'file'}

M.autocomplete_snippets = true

local XPM = textadept.editing.XPM_IMAGES
local xpms = {m = XPM.CLASS, f = XPM.METHOD, F = XPM.VARIABLE, t = XPM.TYPEDEF}

textadept.editing.autocompleters.lua = function()
  local list = {}
  -- Retrieve the symbol behind the caret.
  local line, pos = buffer:get_cur_line()
  local symbol, op, part = line:sub(1, pos - 1):match('([%w_%.]-)([%.:]?)([%w_]*)$')
  if symbol == '' and part == '' then return nil end -- nothing to complete
  if symbol == '' and M.autocomplete_snippets then
    local _, snippets = textadept.editing.autocompleters.snippet()
    for i = 1, #snippets do list[#list + 1] = snippets[i] end
  end
  symbol, part = symbol:gsub('^_G%.?', ''), part ~= '_G' and part or ''
  -- Attempt to identify string type and file type symbols.
  local assignment = '%f[%w_]' .. symbol:gsub('(%p)', '%%%1') .. '%s*=%s*(.*)$'
  for i = buffer:line_from_position(buffer.current_pos) - 1, 1, -1 do
    local expr = buffer:get_line(i):match(assignment)
    if not expr then goto continue end
    for patt, type in pairs(M.expr_types) do
      if expr:find(patt) then
        symbol = type
        break
      end
    end
    ::continue::
  end
  -- Search through ctags for completions for that symbol.
  local name_patt = '^' .. part
  local sep = string.char(buffer.auto_c_type_separator)
  for _, filename in ipairs(M.tags) do
    if type(filename) == 'function' then filename = filename() end
    if not filename or not lfs.attributes(filename) then goto continue end
    for tag_line in io.lines(filename) do
      local name = tag_line:match('^%S+')
      if not name:find(name_patt) or list[name] then goto continue end
      local fields = tag_line:match(';"\t(.*)$')
      local k, class = fields:sub(1, 1), fields:match('class:(%S+)') or ''
      if class == symbol and (op ~= ':' or k == 'f') then
        list[#list + 1], list[name] = name .. sep .. xpms[k], true
      end
      ::continue::
    end
    ::continue::
  end
  if #list == 1 and list[1]:find(name_patt .. '%?') then return nil end
  return #part, list
end

local api_files = textadept.editing.api_files.lua
table.insert(api_files, _HOME .. '/modules/lua/api')
table.insert(api_files, _USERHOME .. '/modules/lua/api')
table.insert(api_files, ta_api(_HOME .. '/modules/lua/ta_api'))

-- Snippets.

local snip = snippets.lua
snip.func = 'function %1(name)(%2(args))\n\t%0\nend'
snip['if'] = 'if %1 then\n\t%0\nend'
snip.eif = 'elseif %1 then\n\t'
snip['for'] = 'for %1(i) = %2(1), %3(10)%4(, %5(-1)) do\n\t%0\nend'
snip.forp = 'for %1(k), %2(v) in pairs(%3(t)) do\n\t%0\nend'
snip.fori = 'for %1(i), %2(v) in ipairs(%3(t)) do\n\t%0\nend'
snip['while'] = 'while %1 do\n\t%0\nend'
snip['repeat'] = 'repeat\n\t%0\nuntil %1'
snip['do'] = 'do\n\t%0\nend'

return M

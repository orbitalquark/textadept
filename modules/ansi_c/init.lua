-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The ansi_c module.
-- It provides utilities for editing C code.
module('_M.ansi_c')]]

-- Autocompletion and documentation.

---
-- List of ctags files to use for autocompletion in addition to the current
-- project's top-level *tags* file or the current directory's *tags* file.
-- @class table
-- @name tags
M.tags = {
  _HOME..'/modules/ansi_c/tags', _HOME..'/modules/ansi_c/lua_tags',
  _USERHOME..'/modules/ansi_c/tags'
}

local XPM = textadept.editing.XPM_IMAGES
local xpms = setmetatable({
  c = XPM.CLASS, d = XPM.SLOT, e = XPM.VARIABLE, f = XPM.METHOD,
  g = XPM.TYPEDEF, m = XPM.VARIABLE, s = XPM.STRUCT, t = XPM.TYPEDEF,
  v = XPM.VARIABLE
}, {__index = function() return 0 end})

textadept.editing.autocompleters.ansi_c = function()
  -- Retrieve the symbol behind the caret.
  local line, pos = buffer:get_cur_line()
  local symbol, op, part = line:sub(1, pos):match('([%w_]-)([%.%->]*)([%w_]*)$')
  if symbol == '' and part == '' and op ~= '' then return nil end -- lone ., ->
  if op ~= '' and op ~= '.' and op ~= '->' then return nil end
  -- Attempt to identify the symbol type.
  if symbol ~= '' then
    local buffer = buffer
    local decl = '([%w_]+)[%s%*&]+'..symbol:gsub('(%p)', '%%%1')..'[^%w_]'
    for i = buffer:line_from_position(buffer.current_pos) - 1, 0, -1 do
      local class = buffer:get_line(i):match(decl)
      if class then symbol = class break end
    end
  end
  -- Search through ctags for completions for that symbol.
  local tags_files = {}
  for i = 1, #M.tags do tags_files[#tags_files + 1] = M.tags[i] end
  tags_files[#tags_files + 1] = (io.get_project_root(buffer.filename) or
                                 lfs.currentdir())..'/tags'
  local name_patt = '^'..part
  local sep = string.char(buffer.auto_c_type_separator)
  ::rescan::
  local list = {}
  for i = 1, #tags_files do
    if lfs.attributes(tags_files[i]) then
      for tag_line in io.lines(tags_files[i]) do
        local name = tag_line:match('^%S+')
        if (name:find(name_patt) and not name:find('^!') and not list[name]) or
           name == symbol then
          local fields = tag_line:match(';"\t(.*)$')
          if (fields:match('class:(%S+)') or fields:match('enum:(%S+)') or
              fields:match('struct:(%S+)') or '') == symbol then
            list[#list + 1] = string.format('%s%s%d', name, sep,
                                            xpms[fields:sub(1, 1)])
            list[name] = true
          elseif name == symbol and fields:match('typeref:') then
            -- For typeref, change the lookup symbol to the referenced name and
            -- rescan tags files.
            symbol = fields:match('[^:]+$')
            goto rescan
          end
        end
      end
    end
  end
  return #part, list
end

textadept.editing.api_files.ansi_c = {
  _HOME..'/modules/ansi_c/api', _HOME..'/modules/ansi_c/lua_api',
  _USERHOME..'/modules/ansi_c/api'
}

-- Commands.

---
-- Table of C-specific key bindings.
--
-- + `Shift+Enter` (`⇧↩` | `S-Enter`)
--   Add ';' to the end of the current line and insert a newline.
-- @class table
-- @name _G.keys.ansi_c
keys.ansi_c = {
  ['s\n'] = function()
    buffer:line_end()
    buffer:add_text(';')
    buffer:new_line()
  end,
}

-- Snippets.

if type(snippets) == 'table' then
---
-- Table of C-specific snippets.
-- @class table
-- @name _G.snippets.ansi_c
  snippets.ansi_c = {
    func = '%1(int) %2(name)(%3(args)) {\n\t%0\n\treturn %4(0);\n}',
    vfunc = 'void %1(name)(%2(args)) {\n\t%0\n}',
    ['if'] = 'if (%1) {\n\t%0\n}',
    eif = 'else if (%1) {\n\t%0\n}',
    ['else'] = 'else {\n\t%0\n}',
    ['for'] = 'for (%1; %2; %3) {\n\t%0\n}',
    ['fori'] = 'for (%1(int) %2(i) = %3(0); %2 %4(<) %5(count); %2%6(++)) {\n'..
               '\t%0\n}',
    ['while'] = 'while (%1) {\n\t%0\n}',
    ['do'] = 'do {\n\t%0\n} while (%1);',
    sw = 'switch (%1) {\n\tcase %2:\n\t\t%0\n\t\tbreak;\n}',
    case = 'case %1:\n\t%0\n\tbreak;',

    st = 'struct %1(name) {\n\t%0\n};',
    td = 'typedef %1(int) %2(name_t);',
    tds = 'typedef struct %1(name) {\n\t%0\n} %1%2(_t);',

    def = '#define %1(name) %2(value)',
    inc = '#include "%1"',
    Inc = '#include <%1>',
    pif = '#if %1\n%0\n#endif',

    main = 'int main(int argc, const char **argv) {\n\t%0\n\treturn 0;\n}',
    printf = 'printf("%1(%s)\\n", %2);',
  }
end

return M

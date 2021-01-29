-- Copyright 2007-2021 Mitchell. See LICENSE.

-- Markdown doclet for Luadoc.
-- @usage luadoc -doclet path/to/markdowndoc [file(s)] > api.md
local M = {}

local TOC = '1. [%s](%s)\n'
local MODULE = '<a id="%s"></a>\n## The `%s` Module\n'
local FIELD = '<a id="%s"></a>\n#### `%s` %s\n\n'
local FUNCTION = '<a id="%s"></a>\n#### `%s`(*%s*)\n\n'
local FUNCTION_NO_PARAMS = '<a id="%s"></a>\n#### `%s`()\n\n'
local DESCRIPTION = '%s\n\n'
local LIST_TITLE = '%s:\n\n'
local PARAM = '* *`%s`*: %s\n'
local USAGE = '* `%s`\n'
local RETURN = '* %s\n'
local SEE = '* [`%s`](#%s)\n'
local TABLE = '<a id="%s"></a>\n#### `%s`\n\n'
local TFIELD = '* `%s`: %s\n'
local titles = {
  [PARAM] = 'Parameters', [USAGE] = 'Usage', [RETURN] = 'Return',
  [SEE] = 'See also', [TFIELD] = 'Fields'
}

-- Writes a LuaDoc description to the given file.
-- @param f The markdown file being written to.
-- @param description The description.
-- @param name The name of the module the description belongs to. Used for
--   headers in module descriptions.
local function write_description(f, description, name)
  -- Substitute custom [`code`]() link convention with [`code`](#code) links.
  local self_link = '(%[`([^`(]+)%(?%)?`%])%(%)'
  description = description:gsub(self_link, function(link, id)
    return string.format('%s(#%s)', link, id:gsub(':', '.'))
  end)
  f:write(string.format(DESCRIPTION, description))
end

-- Writes a LuaDoc list to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a list item.
-- @param list The LuaDoc list.
-- @param name The name of the module the list belongs to. Used for @see.
local function write_list(f, fmt, list, name)
  if not list or #list == 0 then return end
  if type(list) == 'string' then list = {list} end
  f:write(string.format(LIST_TITLE, titles[fmt]))
  for _, value in ipairs(list) do
    if fmt == SEE and name ~= '_G' then
      if not value:find('%.') then
        -- Prepend module name to identifier if necessary.
        value = name .. '.' .. value
      else
        -- TODO: cannot link to fields, functions, or tables in `_G`?
        value = value:gsub('^_G%.', '')
      end
    end
    f:write(string.format(fmt, value, value))
  end
  f:write('\n')
end

-- Writes a LuaDoc hashmap to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a hashmap item.
-- @param list The LuaDoc hashmap.
local function write_hashmap(f, fmt, hashmap)
  if not hashmap or #hashmap == 0 then return end
  f:write(string.format(LIST_TITLE, titles[fmt]))
  for _, name in ipairs(hashmap) do
    f:write(string.format(fmt, name, hashmap[name] or ''))
  end
  f:write('\n')
end

-- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function M.start(doc)
  local modules, files = doc.modules, doc.files
  local f = io.stdout
  f:write('## Textadept API Documentation\n\n')

  -- Create the table of contents.
  for _, name in ipairs(modules) do
    f:write(string.format(TOC, name, '#' .. name))
  end
  f:write('\n')

  -- Create a map of doc objects to file names so their Markdown doc comments
  -- can be extracted.
  local filedocs = {}
  for _, name in ipairs(files) do filedocs[files[name].doc] = name end

  -- Loop over modules, writing the Markdown document to stdout.
  for _, name in ipairs(modules) do
    local module = modules[name]

    -- Write the header and description.
    f:write(string.format(MODULE, name, name))
    f:write('---\n\n')
    write_description(f, module.description, name)

    -- Write fields.
    if module.doc[1].class == 'module' then
      local fields = module.doc[1].field
      if fields and #fields > 0 then
        table.sort(fields)
        f:write('### Fields defined by `', name, '`\n\n')
        for _, field in ipairs(fields) do
          local type, description = fields[field]:match('^(%b())%s*(.+)$')
          if not field:find('%.') and name ~= '_G' then
            field = name .. '.' .. field -- absolute name
          else
            field = field:gsub('^_G%.', '') -- strip _G required for Luadoc
          end
          f:write(string.format(FIELD, field, field, type or ''))
          write_description(f, description or fields[field])
        end
        f:write('\n')
      end
    end

    -- Write functions.
    local funcs = module.functions
    if #funcs > 0 then
      f:write('### Functions defined by `', name, '`\n\n')
      for _, fname in ipairs(funcs) do
        local func = funcs[fname]
        local params = table.concat(func.param, ', '):gsub('_', '\\_')
        if not func.name:find('[%.:]') and name ~= '_G' then
          func.name = name .. '.' .. func.name -- absolute name
        end
        if params ~= '' then
          f:write(string.format(FUNCTION, func.name, func.name, params))
        else
          f:write(string.format(FUNCTION_NO_PARAMS, func.name, func.name))
        end
        write_description(f, func.description)
        write_hashmap(f, PARAM, func.param)
        write_list(f, USAGE, func.usage)
        write_list(f, RETURN, func.ret)
        write_list(f, SEE, func.see, name)
      end
      f:write('\n')
    end

    -- Write tables.
    local tables = module.tables
    if #tables > 0 then
      f:write('### Tables defined by `', name, '`\n\n')
      for _, tname in ipairs(tables) do
        local tbl = tables[tname]
        if not tbl.name:find('%.') and
           (name ~= '_G' or tbl.name == 'buffer' or tbl.name == 'view') then
          tbl.name = name .. '.' .. tbl.name -- absolute name
        elseif tbl.name ~= '_G.keys' and tbl.name ~= '_G.snippets' then
          tbl.name = tbl.name:gsub('^_G%.', '') -- strip _G required for Luadoc
        end
        f:write(string.format(TABLE, tbl.name, tbl.name))
        write_description(f, tbl.description)
        write_hashmap(f, TFIELD, tbl.field)
        write_list(f, USAGE, tbl.usage)
        write_list(f, SEE, tbl.see, name)
      end
    end
    f:write('---\n')
  end
end

return M

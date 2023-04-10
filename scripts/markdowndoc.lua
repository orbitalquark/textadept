-- Copyright 2007-2023 Mitchell. See LICENSE.

--- Markdown filter for LDoc and doclet for Luadoc.
-- @usage ldoc --filter markdowndoc.ldoc [ldoc opts] > api.md
-- @usage luadoc --doclet path/to/markdowndoc [file(s)] > api.md
-- @module markdowndoc
local M = {}

local TOC = '1. [%s](%s)\n'
local MODULE = '<a id="%s"></a>\n## The `%s` Module\n'
local FIELD = '<a id="%s"></a>\n#### `%s` %s\n\n'
local FUNCTION = '<a id="%s"></a>\n#### `%s`(%s)\n\n'
local FUNCTION_NO_PARAMS = '<a id="%s"></a>\n#### `%s`()\n\n'
local DESCRIPTION = '%s\n\n'
local LIST_TITLE = '%s:\n\n'
local PARAM = '- *%s*: %s\n'
local USAGE = '- `%s`\n'
local RETURN = '- %s\n'
local SEE = '- [`%s`](#%s)\n'
local TABLE = '<a id="%s"></a>\n#### `%s`\n\n'
local TFIELD = '- `%s`: %s\n'
local titles = {
  [PARAM] = 'Parameters', [USAGE] = 'Usage', [RETURN] = 'Return', [SEE] = 'See also',
  [TFIELD] = 'Fields'
}

--- Writes an LDoc description to the given file.
-- @param f The markdown file being written to.
-- @param description The description.
-- @param name The name of the module the description belongs to. Used for headers in module
--   descriptions.
local function write_description(f, description, name)
  -- Substitute custom [`code`]() link convention with [`code`](#code) links.
  local self_link = '(%[`([^`(]+)%(?%)?`%])%(%)'
  description = description:gsub(self_link, function(link, id)
    return string.format('%s(#%s)', link, id:gsub(':', '.'))
  end)
  description = description:gsub('\n ', '\n') -- strip leading spaces
  f:write(string.format(DESCRIPTION, description))
end

--- Writes an LDoc list to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a list item.
-- @param list The LDoc list.
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

--- Writes an LDoc hashmap to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a hashmap item.
-- @param list The LDoc hashmap.
local function write_hashmap(f, fmt, hashmap)
  if not hashmap or #hashmap == 0 then return end
  f:write(string.format(LIST_TITLE, titles[fmt]))
  for _, name in ipairs(hashmap) do
    local description = hashmap.map and hashmap.map[name] or hashmap[name] or ''
    if fmt == PARAM then description = description:gsub('^%[opt%] ', '') end
    f:write(string.format(fmt, name, description))
  end
  f:write('\n')
end

--- Called by LDoc to process a doc object.
-- @param doc The LDoc doc object.
function M.ldoc(doc)
  local f = io.stdout
  f:write('## Textadept API Documentation\n\n')

  table.sort(doc, function(a, b) return a.name < b.name end)

  -- Relocate '_G.' fields in modules to their target modules.
  for _, module in ipairs(doc) do
    local i = 1
    while i <= #module.items do
      local item, relocated = module.items[i], false
      if item.name:find('^_G%.[^.]+') and module.name ~= '_G' then
        local target_module = item.name:match('^_G.(.-)%.[^.]+$') or '_G'
        for _, module2 in ipairs(doc) do
          if module2.name == target_module then
            item.name = item.name:gsub('^_G%.[^.]+%.', ''):gsub('^_G%.', '')
            module2.items[#module2.items + 1] = item
            table.remove(module.items, i)
            relocated = true
            break
          elseif module2.name == target_module:match('^(.+)%.[^.]+$') then
            local target_item = target_module:match('[^.]+$')
            for _, item2 in ipairs(module2.items) do
              if item2.name == target_item then
                item2.params[#item2.params + 1] = item.name:match('[^.]+$')
                item2.params.map[item.name:match('[^.]+$')] = item.summary .. item.description
                table.remove(module.items, i)
                relocated = true
              end
            end
          end
        end
        if not relocated then print('[WARN] Could not find target module for ' .. item.name) end
      end
      if not relocated then i = i + 1 end
    end
  end

  -- Create the table of contents.
  for _, module in ipairs(doc) do f:write(string.format(TOC, module.name, '#' .. module.name)) end
  f:write('\n')

  -- Loop over modules, writing the Markdown document to stdout.
  for _, module in ipairs(doc) do
    local name = module.name

    -- Write the header and description.
    f:write(string.format(MODULE, name, name))
    f:write('---\n\n')
    write_description(f, module.summary .. module.description, name)

    -- Write fields.
    local fields = {}
    for _, item in ipairs(module.items) do
      if item.type == 'field' then fields[#fields + 1] = item end
    end
    table.sort(fields, function(a, b) return a.name < b.name end)
    if #fields > 0 then
      f:write('### Fields defined by `', name, '`\n\n')
      for _, field in ipairs(fields) do
        if not field.name:find('%.') and name ~= '_G' then
          field.name = name .. '.' .. field.name -- absolute name
        elseif field.name:find('^_G%.[^.]+%.[^.]+') then
          field.name = field.name:gsub('^_G%.', '') -- strip _G required for LDoc
        end
        local is_buffer_view_constant = field.name:find('^buffer%.[A-Z_]+$') or
          field.name:find('^view%.[A-Z_]+$')
        if not is_buffer_view_constant then
          f:write(string.format(FIELD, field.name:gsub('^_G%.', ''), field.name, ''))
          write_description(f, field.summary .. field.description)
        end
      end
      f:write('\n')
    end

    -- Write functions.
    local funcs = {}
    for _, item in ipairs(module.items) do
      if item.type == 'function' then funcs[#funcs + 1] = item end
    end
    table.sort(funcs, function(a, b) return a.name < b.name end)
    if #funcs > 0 then
      f:write('### Functions defined by `', name, '`\n\n')
      for _, func in ipairs(funcs) do
        if not func.name:find('[%.:]') and name ~= '_G' then
          func.name = name .. '.' .. func.name -- absolute name
        end
        f:write(string.format(FUNCTION, func.name:gsub(':', '.'), func.name,
          func.args:sub(2, -2):gsub('[%w_]+', '*%0*')))
        write_description(f, func.summary .. func.description)
        write_hashmap(f, PARAM, func.params)
        write_list(f, USAGE, func.usage)
        write_list(f, RETURN, func.ret)
        write_list(f, SEE, func.tags.see, name)
      end
      f:write('\n')
    end

    -- Write tables.
    local tables = {}
    for _, item in ipairs(module.items) do
      if item.type == 'table' then tables[#tables + 1] = item end
    end
    table.sort(tables, function(a, b) return a.name < b.name end)
    if #tables > 0 then
      f:write('### Tables defined by `', name, '`\n\n')
      for _, tbl in ipairs(tables) do
        if not tbl.name:find('%.') and name ~= '_G' then
          tbl.name = name .. '.' .. tbl.name -- absolute name
        else
          tbl.name = tbl.name:gsub('^_G%.', '') -- strip _G required for LDoc/LuaDoc
        end
        local tbl_id = tbl.name ~= 'buffer' and tbl.name ~= 'view' and tbl.name ~= 'keys' and
          tbl.name:gsub('^_G.', '') or ('_G.' .. tbl.name)
        f:write(string.format(TABLE, tbl_id, tbl.name))
        write_description(f, tbl.summary .. tbl.description)
        write_hashmap(f, TFIELD, tbl.params)
        write_list(f, USAGE, tbl.usage)
        write_list(f, SEE, tbl.tags.see, name)
      end
    end
    f:write('---\n')
  end
end

--- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function M.start(doc)
  local modules, files = doc.modules, doc.files
  local f = io.stdout
  f:write('## Textadept API Documentation\n\n')

  -- Create the table of contents.
  for _, name in ipairs(modules) do f:write(string.format(TOC, name, '#' .. name)) end
  f:write('\n')

  -- Create a map of doc objects to file names so their Markdown doc comments can be extracted.
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
            field = field:gsub('^_G%.', '') -- strip _G required for LuaDoc
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
        if not tname:find('%.') and (name ~= '_G' or tname == 'buffer' or tname == 'view') then
          tname = name .. '.' .. tname -- absolute name
        elseif tname ~= '_G.keys' and tname ~= '_G.snippets' then
          tname = tname:gsub('^_G%.', '') -- strip _G required for LuaDoc
        end
        f:write(string.format(TABLE, tname, tname))
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

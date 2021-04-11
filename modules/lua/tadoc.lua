-- Copyright 2007-2021 Mitchell. See LICENSE.

-- Textadept autocompletions and API documentation doclet for LuaDoc.
-- This module is used by LuaDoc to create Lua autocompletion and API documentation files that
-- Textadept can read.
-- To preserve formatting, the included *luadoc.patch* file must be applied to your instance
-- of LuaDoc. It will not affect the look of HTML web pages, only the look of plain-text output.
-- Also requires LuaFileSystem (lfs) to be installed.
-- @usage luadoc -d [output_path] -doclet path/to/tadoc [file(s)]
local M = {}

local CTAG = '%s\t%s\t/^%s$/;"\t%s\t%s'
local string_format = string.format
local lfs = require('lfs')

-- As a special case for Textadept API tags, do not store the local path, but use a `_HOME`
-- prefix that will be filled in by consumers. Do this by making use of a custom command line
-- switch: --ta-home="path/to/ta/home".
local _HOME
for i = 1, #arg do
  _HOME = arg[i]:match('^%-%-ta%-home=(.+)$')
  if _HOME then
    _HOME = _HOME:gsub('%p', '%%%0')
    break
  end
end

-- Writes a ctag.
-- @param file The file to write to.
-- @param name The name of the tag.
-- @param filename The filename the tag occurs in.
-- @param code The line of code the tag occurs on.
-- @param k The kind of ctag. The Lua module recognizes 4 kinds: m Module, f Function, t Table,
--   and F Field.
-- @param ext_fields The ext_fields for the ctag.
local function write_tag(file, name, filename, code, k, ext_fields)
  if _HOME then filename = filename:gsub(_HOME, '_HOME') end
  if ext_fields == 'class:_G' then ext_fields = '' end
  file[#file + 1] = string_format(CTAG, name, filename, code, k, ext_fields)
end

-- Sanitizes Markdown from the given documentation string by stripping links and replacing
-- HTML entities.
-- @param s String to sanitize Markdown from.
-- @return string
local function sanitize_markdown(s)
  return s:gsub('%[([^%]\r\n]+)%]%b[]', '%1') -- [foo][]
  :gsub('%[([^%]\r\n]+)%]%b()', '%1') -- [foo](bar)
  :gsub('\r?\n\r?\n%[([^%]\r\n]+)%]:[^\r\n]+', '') -- [foo]: bar
  :gsub('\r?\n%[([^%]\r\n]+)%]:[^\r\n]+', '') -- [foo]: bar
  :gsub('&([%a]+);', {quot = '"', apos = "'"})
end

-- Writes a function or field apidoc.
-- @param file The file to write to.
-- @param m The LuaDoc module object.
-- @param b The LuaDoc block object.
local function write_apidoc(file, m, b)
  -- Function or field name.
  local name = b.name
  if not name:find('[%.:]') then name = string.format('%s.%s', m.name, name) end
  -- Block documentation for the function or field.
  local doc = {}
  -- Function arguments or field type.
  local class = b.class
  local header = name
  if class == 'function' then
    header = header .. (b.param and string.format('(%s)', table.concat(b.param, ', ')) or '')
  elseif class == 'field' and b.description:find('^%s*%b()') then
    header = string.format('%s %s', header, b.description:match('^%s*(%b())'))
  elseif class == 'module' or class == 'table' then
    header = string.format('%s (%s)', header, class)
  end
  doc[#doc + 1] = header
  -- Function or field description.
  local description = b.description
  if class == 'module' then
    -- Modules usually have additional Markdown documentation so just grab the documentation
    -- before a Markdown header.
    description = description:match('^(.-)[\r\n]+#') or description
  elseif class == 'field' then
    -- Type information is already in the header; discard it in the description.
    description = description:match('^%s*%b()[\t ]*[\r\n]*(.+)$') or description
    -- Strip consistent leading whitespace.
    local indent
    indent, description = description:match('^(%s*)(.*)$')
    if indent ~= '' then description = description:gsub('\n' .. indent, '\n') end
  end
  doc[#doc + 1] = sanitize_markdown(description)
  -- Function parameters (@param).
  if class == 'function' and b.param then
    for _, p in ipairs(b.param) do
      if b.param[p] and #b.param[p] > 0 then
        doc[#doc + 1] = string.format('@param %s %s', p, sanitize_markdown(b.param[p]))
      end
    end
  end
  -- Function usage (@usage).
  if class == 'function' and b.usage then
    if type(b.usage) == 'string' then
      doc[#doc + 1] = '@usage ' .. b.usage
    else
      for _, u in ipairs(b.usage) do doc[#doc + 1] = '@usage ' .. u end
    end
  end
  -- Function returns (@return).
  if class == 'function' and b.ret then
    if type(b.ret) == 'string' then
      doc[#doc + 1] = '@return ' .. b.ret
    else
      for _, u in ipairs(b.ret) do doc[#doc + 1] = '@return ' .. u end
    end
  end
  -- See also (@see).
  if b.see then
    if type(b.see) == 'string' then
      doc[#doc + 1] = '@see ' .. b.see
    else
      for _, s in ipairs(b.see) do doc[#doc + 1] = '@see ' .. s end
    end
  end
  -- Format the block documentation.
  doc = table.concat(doc, '\n'):gsub('\\n', '\\\\n'):gsub('\n', '\\n')
  file[#file + 1] = string.format('%s %s', name:match('[^%.:]+$'), doc)
end

-- Returns the absolute path of the given relative path.
-- @param string path String relative path.
-- @return absolute path
local function abspath(path)
  path = string.format('%s/%s', lfs.currentdir(), path)
  path = path:gsub('%f[^/]%./', '') -- clean up './'
  while path:find('[^/]+/%.%./') do
    path = path:gsub('[^/]+/%.%./', '', 1) -- clean up '../'
  end
  return path
end

-- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function M.start(doc)
  --  require('luarocks.require')
  --  local profiler = require('profiler')
  --  profiler.start()

  local modules, files = doc.modules, doc.files

  -- Map doc objects to file names so a module can be mapped to its filename.
  for _, filename in ipairs(files) do
    local doc = files[filename].doc
    files[doc] = abspath(filename)
  end

  -- Add a module's fields to its LuaDoc.
  for _, filename in ipairs(files) do
    local module_doc = files[filename].doc[1]
    if module_doc and module_doc.class == 'module' and modules[module_doc.name] then
      modules[module_doc.name].fields = module_doc.field
    elseif module_doc then
      print(string.format('[WARN] %s has no module declaration', filename))
    end
  end

  -- Convert module functions in the Lua luadoc into LuaDoc modules.
  local lua_luadoc = files['../modules/lua/lua.luadoc']
  if lua_luadoc and #files == 1 then
    for _, function_name in ipairs(lua_luadoc.functions) do
      local func = lua_luadoc.functions[function_name]
      local module_name = func.name:match('^([^%.:]+)[%.:]') or '_G'
      if not modules[module_name] then
        modules[#modules + 1] = module_name
        modules[module_name] = {name = module_name, functions = {}, doc = {{code = func.code}}}
        files[modules[module_name].doc] = abspath(files[1])
        -- For functions like file:read(), 'file' is not a module; fake it.
        if func.name:find(':') then modules[module_name].fake = true end
      end
      local module = modules[module_name]
      module.description = string.format('Lua %s module.', module.name)
      module.functions[#module.functions + 1] = func.name
      module.functions[func.name] = func
    end
    for _, table_name in ipairs(lua_luadoc.tables) do
      local table = lua_luadoc.tables[table_name]
      local module = modules[table.name or '_G']
      if not module.fields then module.fields = {} end
      local fields = module.fields
      for k, v in pairs(table.field) do
        if not tonumber(k) then fields[#fields + 1], fields[k] = k, v end
      end
    end
  end

  -- Process LuaDoc and write the tags and api files.
  local ctags, apidoc = {}, {}
  for _, module_name in ipairs(modules) do
    local m = modules[module_name]
    local filename = files[m.doc]
    if not m.fake then
      -- Tag and document the module.
      write_tag(ctags, m.name, filename, m.doc[1].code[1], 'm', '')
      if m.name:find('%.') then
        -- Tag the last part of the module as a table of the first part.
        local parent, child = m.name:match('^(.-)%.([^%.]+)$')
        write_tag(ctags, child, filename, m.doc[1].code[1], 'm', 'class:' .. parent)
      end
      m.class = 'module'
      write_apidoc(apidoc, {name = '_G'}, m)
    end
    -- Tag and document the functions.
    for _, function_name in ipairs(m.functions) do
      local module_name, name = function_name:match('^(.-)[%.:]?([^.:]+)$')
      if module_name == '' then module_name = m.name end
      local func = m.functions[function_name]
      write_tag(ctags, name, filename, func.code[1], 'f', 'class:' .. module_name)
      write_apidoc(apidoc, m, func)
    end
    if m.tables then
      -- Document the tables.
      for _, table_name in ipairs(m.tables) do
        local table = m.tables[table_name]
        local module_name = m.name
        if table_name:find('^_G%.') then
          module_name, table_name = table_name:match('^_G%.(.-)%.?([^%.]+)$')
          if not module_name then
            print('[ERROR] Cannot determine module name for ' .. table.name)
          elseif module_name == '' then
            module_name = '_G' -- _G.keys or _G.snippets
          end
        end
        write_tag(ctags, table_name, filename, table.code[1], 't', 'class:' .. module_name)
        write_apidoc(apidoc, m, table)
        if table.field then
          -- Tag and document the table's fields.
          table_name = string.format('%s.%s', module_name, table_name)
          for _, field_name in ipairs(table.field) do
            write_tag(ctags, field_name, filename, table.code[1], 'F', 'class:' .. table_name)
            write_apidoc(apidoc, {name = table_name}, {
              name = field_name, description = table.field[field_name], class = 'table'
            })
          end
        end
      end
    end
    if m.fields then
      -- Tag and document the fields.
      for _, field_name in ipairs(m.fields) do
        local field = m.fields[field_name]
        local module_name = m.name
        if field_name:find('^_G%.') then
          module_name, field_name = field_name:match('^_G%.(.-)%.?([^%.]+)$')
          if not module_name then
            print('[ERROR] Cannot determine module name for ' .. field.name)
          end
        end
        write_tag(ctags, field_name, filename, m.doc[1].code[1], 'F', 'class:' .. module_name)
        write_apidoc(apidoc, {name = field_name}, {
          name = string.format('%s.%s', module_name, field_name), description = field,
          class = 'field'
        })
      end
    end
  end
  table.sort(ctags)
  table.sort(apidoc)
  local f = io.open(M.options.output_dir .. '/tags', 'wb')
  f:write(table.concat(ctags, '\n'))
  f:close()
  f = io.open(M.options.output_dir .. '/api', 'wb')
  f:write(table.concat(apidoc, '\n'))
  f:close()

  --  profiler.stop()
end

return M

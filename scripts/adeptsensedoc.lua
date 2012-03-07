-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

---
-- Adeptsense doclet for LuaDoc.
-- This module is used by LuaDoc to create an adeptsense for Lua with a fake
-- ctags file and an api file.
-- Since LuaDoc does not recognize module fields, this doclet parses the Lua
-- modules for comments of the form "-- * `field_name`" to generate a field tag
-- and apidoc. Multiple line comments for fields must be indented flush with
-- `field_name` (3 spaces). Indenting more than this preserves formatting in the
-- apidoc.
-- @usage luadoc -d [output_path] -doclet path/to/adeptsensedoc [file(s)]
module('adeptsensedoc', package.seeall)

local CTAGS_FMT = '%s\t_\t0;"\t%s\t%s'
local string_format = string.format

-- Writes a ctag.
-- @param file The file to write to.
-- @param name The name of the tag.
-- @param k The kind of ctag. Lua adeptsense uses 4 kinds: m Module, f Function,
--   t Table, and F Field.
-- @param ext_fields The ext_fields for the ctag.
local function write_tag(file, name, k, ext_fields)
  if type(ext_fields) == 'table' then
    ext_fields = table.concat(ext_fields, '\t')
  end
  file[#file + 1] = string_format(CTAGS_FMT, name, k, ext_fields)
end

-- Writes a function or field apidoc.
-- @param file The file to write to.
-- @param m The LuaDoc module object.
-- @param b The LuaDoc block object.
local function write_apidoc(file, m, b)
  -- Function or field name.
  local name = b.name
  if not name:find('[%.:]') then name = m.name..'.'..name end
  -- Block documentation for the function or field.
  local doc = {}
  -- Function arguments or field type.
  local header = name
  if b.class == 'function' then
    header = header..(b.param and '('..table.concat(b.param, ', ')..')' or '')
  end
  if b.modifier and b.modifier ~= '' then header = header..' '..b.modifier end
  doc[#doc + 1] = header
  -- Function or field description.
  doc[#doc + 1] = b.description:gsub('\\n', '\\\\n')
  -- Function parameters (@param).
  if b.class == 'function' and b.param then
    for _, p in ipairs(b.param) do
      if b.param[p] and #b.param[p] > 0 then
        doc[#doc + 1] = '@param '..p..' '..b.param[p]:gsub('\\n', '\\\\n')
      end
    end
  end
  -- Function usage (@usage).
  if b.class == 'function' and b.usage then
    if type(b.usage) == 'string' then
      doc[#doc + 1] = '@usage '..b.usage
    else
      for _, u in ipairs(b.usage) do doc[#doc + 1] = '@usage '..u end
    end
  end
  -- Function returns (@return).
  if b.class == 'function' and b.ret then
    if type(b.ret) == 'string' then
      doc[#doc + 1] = '@return '..b.ret
    else
      for _, u in ipairs(b.ret) do doc[#doc + 1] = '@return '..u end
    end
  end
  -- See also (@see).
  if b.see then
    if type(b.see) == 'string' then
      doc[#doc + 1] = '@see '..b.see
    else
      for _, s in ipairs(b.see) do doc[#doc + 1] = '@see '..s end
    end
  end
  -- Format the block documentation.
  doc = table.concat(doc, '\n'):gsub('\n', '\\n')
  file[#file + 1] = name:match('[^%.:]+$')..' '..doc
end

-- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function start(doc)
--  require 'luarocks.require'
--  local profiler = require 'profiler'
--  profiler.start()

  local modules = doc.modules

  -- Convert module functions in the Lua luadoc into LuaDoc modules.
  local lua_luadoc = doc.files['../modules/lua/lua.luadoc']
  if lua_luadoc then
    for _, f in ipairs(lua_luadoc.functions) do
      f = lua_luadoc.functions[f]
      local module = f.name:match('^([^%.:]+)[%.:]') or '_G'
      if not modules[module] then
        modules[#modules + 1] = module
        modules[module] = { name = module, functions = {} }
        -- For functions like file:read(), 'file' is not a module; fake it.
        if f.name:find(':') then modules[module].fake = true end
      end
      local module = modules[module]
      module.description = 'Lua '..module.name..' module.'
      module.functions[#module.functions + 1] = f.name
      module.functions[f.name] = f
    end
  end

  -- Parse out module fields (-- * `FIELD`: doc) and insert them into the
  -- module's LuaDoc.
  for _, file in ipairs(doc.files) do
    local module, field, docs
    -- Adds the field to its module's LuaDoc.
    local function add_field()
      local doc = table.concat(docs, '\n')
      doc = doc:gsub('%[([^%]]+)%]%b[]', '%1'):gsub('%[([^%]]+)%]%b()', '%1')
      field.description = doc
      local m = modules[field.module]
      if not m then
        local name = field.module
        _G.print("Module '"..name.."' does not exist. Faking...")
        m = { name = name, functions = {}, fake = true }
        modules[#modules + 1] = name
        modules[name] = m
      end
      if not m.fields then m.fields = {} end
      m.fields[#m.fields + 1] = field.name
      m.fields[field.name] = field
      field = nil
    end
    local f = io.open(file, 'rb')
    for line in f:lines() do
      if not field and line:find('^module%(') then
        -- Get the module's name to add the parsed fields to.
        module = line:match("^module%('([^']+)'")
      elseif line:find('^%-%- %* `') then
        -- New field; if another field was parsed right before this one, add
        -- the former field to its module's LuaDoc.
        if field then add_field() end
        field, docs = {}, {}
        local name, doc = line:match('^%-%- %* `([^`]+)`([^\r\n]*)')
        field.module = name:match('^_G%.(.-)%.[^%.]+$') or module or
                       name:match('^[^%.]+')
        field.name = name:match('[^%.]+$')
        if doc ~= '' then
          field.modifier, doc = doc:match('^%s*([^:]*):?%s*(.*)$')
        end
        if doc ~= '' then docs[#docs + 1] = doc end
      elseif field and line:find('^%-%-%s+[^\r\n]+') then
        docs[#docs + 1] = line:match('^%-%-%s%s%s(%s*[^\r\n]+)')
      elseif field and
             (line:find('^%-%-[\r\n]*$') or line:find('^[\r\n]*$')) then
        -- End of field documentation. Add it to its module's LuaDoc.
        add_field()
      end
    end
    f:close()
  end

  -- Process LuaDoc and write the ctags and api file.
  local ctags, apidoc = {}, {}
  for _, m in ipairs(modules) do
    m = modules[m]
    local module = m.name
    if not m.fake then
      -- Tag the module and write the apidoc.
      write_tag(ctags, module, 'm', '')
      if module:find('%.') then
        -- Tag the last part of the module as a table of the first part.
        local parent, child = module:match('^(.-)%.([^%.]+)$')
        write_tag(ctags, child, 't', 'class:'..parent)
      elseif module ~= '_G' then
        -- Tag the module as a global table.
        write_tag(ctags, module, 't', '')
      end
      m.modifier = '[module]'
      write_apidoc(apidoc, { name = '_G' }, m)
    end
    -- Tag the functions and write the apidoc.
    for _, f in ipairs(m.functions) do
      local func = f:match('[^%.:]+$')
      local ext_fields = module == '_G' and '' or 'class:'..module
      write_tag(ctags, func, 'f', ext_fields)
      write_apidoc(apidoc, m, m.functions[f])
    end
    -- Tag the tables and write the apidoc.
    for _, t in ipairs(m.tables or {}) do
      local table = m.tables[t]
      local module = module -- define locally so any modification stays local
      if t:find('^_G%.') then module, t = t:match('^_G%.(.-)%.?([^%.]+)$') end
      if not module then _G.print(table.name) end
      local ext_fields = module == '_G' and '' or 'class:'..module
      write_tag(ctags, t, 't', ext_fields)
      table.modifier = '[table]'
      write_apidoc(apidoc, m, table)
      -- Tag the fields of the tables.
      t = module..'.'..t
      for _, f in ipairs(table.field or {}) do
        write_tag(ctags, f, 'F', 'class:'..t)
        write_apidoc(apidoc, { name = t },
                     { name = f, description = table.field[f] })
      end
    end
    -- Tag the fields.
    for _, f in ipairs(m.fields or {}) do
      local ext_fields = module == '_G' and '' or 'class:'..module
      write_tag(ctags, f, 'F', ext_fields)
      write_apidoc(apidoc, m, m.fields[f])
    end
  end
  table.sort(ctags)
  table.sort(apidoc)
  local f = io.open(options.output_dir..'/tags', 'w')
  f:write(table.concat(ctags, '\n'))
  f:close()
  f = io.open(options.output_dir..'api', 'w')
  f:write(table.concat(apidoc, '\n'))
  f:close()

--  profiler.stop()
end

return _M

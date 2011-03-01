-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Adeptsense doclet for LuaDoc.
-- This module is used by LuaDoc to create an adeptsense for Lua with a fake
-- ctags file and an api file.
-- Since LuaDoc does not recognize module fields, this doclet parses the Lua
-- files for comments of the form "-- * `field_name`" to generate a field tag.
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

-- Writes a function apidoc.
-- @param file The file to write to.
-- @param m The LuaDoc module object.
-- @param f The LuaDoc function object.
local function write_function_apidoc(file, m, f)
  -- Function name.
  local name = f.name
  if not name:find('[%.:]') then name = m.name..'.'..name end
  -- Block documentation for the function.
  local doc = { 'fmt -s -w 80 <<"EOF"' }
  -- Function arguments.
  doc[#doc + 1] = name..'('..table.concat(f.param, ', ')..')'
  -- Function description.
  doc[#doc + 1] = f.description:gsub('\\n', '\\\\n')
  -- Function parameters (@param).
  if f.param then
    for _, p in ipairs(f.param) do
      if f.param[p] and #f.param[p] > 0 then
        doc[#doc + 1] = '@param '..f.param[p]:gsub('\\n', '\\\\n')
      end
    end
  end
  -- Function usage (@usage).
  if f.usage then
    if type(f.usage) == 'string' then
      doc[#doc + 1] = '@usage '..f.usage
    else
      for _, u in ipairs(f.usage) do doc[#doc + 1] = '@usage '..u end
    end
  end
  -- Function returns (@return).
  if f.ret then doc[#doc + 1] = '@return '..f.ret end
  -- See also (@see).
  if f.see then
    if type(f.see) == 'string' then
      doc[#doc + 1] = '@see '..f.see
    else
      for _, s in ipairs(f.see) do doc[#doc + 1] = '@see '..s end
    end
  end
  -- Format the block documentation.
  doc[#doc + 1] = 'EOF'
  local p = io.popen(table.concat(doc, '\n'))
  doc = p:read('*all'):gsub('\n', '\\n')
  p:close()
  file[#file + 1] = table.concat({ name:match('[^%.:]+$') , doc }, ' ')
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
      local module = f.name:match('^([^%.]+)%.') or '_G'
      if not modules[module] then
        modules[#modules + 1] = module
        modules[module] = { name = module, functions = {} }
      end
      local module = modules[module]
      module.functions[#module.functions + 1] = f.name
      module.functions[f.name] = f
    end
  end

  -- Parse out module fields (-- * `FIELD`) and insert them into their LuaDoc
  -- modules.
  for _, file in ipairs(doc.files) do
    local p = io.popen('grep -r "^-- \\* \\`" '..file)
    local output = p:read('*all')
    p:close()
    for line in output:gmatch('[^\n]+') do
      local field = line:match('^%-%- %* `([^`]+)`')
      p = io.popen('grep "^module" '..file)
      local module = (p:read('*l') or ''):match("module%('([^']+)'")
      p:close()
      if not module then module = field:match('^[^%.]+') end -- lua.luadoc
      local module = modules[module]
      if not module.fields then module.fields = {} end
      module.fields[#module.fields + 1] = field:match('[^%.]+$')
    end
  end

  -- Process LuaDoc and write the ctags and api file.
  local ctags, apidoc = {}, {}
  for _, m in ipairs(modules) do
    m = modules[m]
    local module = m.name
    -- Tag the module.
    write_tag(ctags, module, 'm', '')
    if module:find('%.') then
      -- Tag the last part of the module as a table of the first part.
      local parent, child = module:match('^(.-)%.([^%.]+)$')
      write_tag(ctags, child, 't', 'class:'..parent)
    elseif module ~= '_G' then
      -- Tag the module as a global table.
      write_tag(ctags, module, 't', 'class:_G')
      write_tag(ctags, module, 't', '')
    end
    -- Tag the functions and write the apidoc.
    for _, f in ipairs(m.functions) do
      if not f:find('no_functions') then -- ignore placeholders
        local func = f:match('[^%.:]+$')
        write_tag(ctags, func, 'f', 'class:'..module)
        if module == '_G' then write_tag(ctags, func, 'f', '') end -- global
        write_function_apidoc(apidoc, m, m.functions[f])
      end
    end
    -- Tag the tables.
    for _, t in ipairs(m.tables or {}) do
      write_tag(ctags, t, 't', 'class:'..module)
      if module == '_G' then write_tag(ctags, t, 't', '') end -- global
    end
    -- Tag the fields.
    for _, f in ipairs(m.fields or {}) do
      write_tag(ctags, f, 'F', 'class:'..module)
      if module == '_G' then write_tag(ctags, f, 'F', '') end -- global
    end
  end
  local f = io.open(options.output_dir..'/tags', 'w')
  f:write(table.concat(ctags, '\n'))
  f:close()
  f = io.open(options.output_dir..'api', 'w')
  f:write(table.concat(apidoc, '\n'))
  f:close()

--  profiler.stop()
end

return _M

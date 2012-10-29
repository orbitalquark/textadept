-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local ipairs, type = ipairs, type
local io_open, io_popen = io.open, io.popen
local string_format, string_rep = string.format, string.rep
local table_concat = table.concat

-- Markdown doclet for Luadoc.
-- Requires Discount (http://www.pell.portland.or.us/~orc/Code/discount/).
-- @usage luadoc -d [output_path] -doclet path/to/markdowndoc [file(s)]
local M = {}

local NAVFILE = '%s* [%s](%s)\n'
local FIELD = '<a id="%s"></a>\n### `%s` %s\n\n'
local FUNCTION = '<a id="%s"></a>\n### `%s` (%s)\n\n'
--local FUNCTION = '### `%s` (%s)\n\n'
local DESCRIPTION = '%s\n\n'
local LIST_TITLE = '%s:\n\n'
local PARAM = '* `%s`: %s\n'
local USAGE = '* `%s`\n'
local RETURN = '* %s\n'
local SEE = '* [`%s`](%s)\n'
local TABLE = '<a id="%s"></a>\n### `%s`\n\n'
--local TABLE = '### `%s`\n\n'
local TFIELD = '* `%s`: %s\n '
local HTML = [[
  <!doctype html>
  <html>
    <head>
      <title>%(title)</title>
      <link rel="stylesheet" href="../style.css" type="text/css" />
      <link rel="icon" href="../icon.png" type="image/png" />
      <meta charset="utf-8" />
    </head>
    <body>
      <div id="content">
        <div id="header">
          %(header)
        </div>
        <div id="nav">
          <h2>Modules</h2>
          %(nav)
        </div>
        <div id="toc">
          <h2>Contents</h2>
          %(toc)
        </div>
        <div id="main">
          %(main)
        </div>
        <div id="footer">
          %(footer)
        </div>
      </div>
    </body>
  </html>
]]
local titles = {
  [PARAM] = 'Parameters', [USAGE] = 'Usage', [RETURN] = 'Return',
  [SEE] = 'See also', [TFIELD] = 'Fields'
}

-- Writes LuaDoc hierarchical module navigation to the given file.
-- @param f The navigation file being written to.
-- @param list The module list.
-- @param parent String parent module with a trailing '.' for sub-modules in
--   order to generate full page links.
local function write_nav(f, list, parent)
  if not parent then parent = '' end
  local level = 0
  for _ in parent:gmatch('%.') do level = level + 1 end
  for _, name in ipairs(list) do
    f:write(string_format(NAVFILE, string_rep(' ', level * 4), name,
                          parent..name..'.html'))
    if list[name] then
      f:write('\n')
      write_nav(f, list[name], parent..name..'.')
    end
  end
end

-- Writes a LuaDoc description to the given file.
-- @param f The markdown file being written to.
-- @param description The description.
local function write_description(f, description)
  f:write(string_format(DESCRIPTION, description))
end

-- Writes a LuaDoc list to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a list item.
-- @param list The LuaDoc list.
local function write_list(f, fmt, list)
  if not list or #list == 0 then return end
  if type(list) == 'string' then list = { list } end
  f:write(string_format(LIST_TITLE, titles[fmt]))
  for _, value in ipairs(list) do
    if fmt ~= SEE then
      f:write(string_format(fmt, value, value))
    else
      -- Parse the identifier to determine if it belongs to the current module.
      if value:find('%.') then
        -- The identifier belongs to a different module. Link to it.
        -- TODO: cannot link to fields, functions, or tables in `_G`.
        value = value:gsub('^_G%.', '')
        local link = value..'.html'
        local module, func = value:match('^(.+)%.([^.]+)$')
        if module and func then
          link = module..'.html'..(func ~= '' and '#'..func or '')
        end
        f:write(string_format(fmt, value, link))
      else
        -- The identifier belongs to the same module. Anchor it.
        f:write(string_format(fmt, value, '#'..value))
      end
    end
  end
  f:write('\n')
end

-- Writes a LuaDoc hashmap to the given file.
-- @param f The markdown file being written to.
-- @param fmt The format of a hashmap item.
-- @param list The LuaDoc hashmap.
local function write_hashmap(f, fmt, hashmap)
  if not hashmap or #hashmap == 0 then return end
  f:write(string_format(LIST_TITLE, titles[fmt]))
  for _, name in ipairs(hashmap) do
    f:write(string_format(fmt, name, hashmap[name] or ''))
  end
  f:write('\n')
end

-- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function M.start(doc)
  local template = {
    title = 'Textadept API', header = '', toc = '', main = '', footer = ''
  }
  local modules, files = doc.modules, doc.files

  -- Create the header and footer, if given a template.
  local header, footer = '', ''
  if M.options.template_dir ~= 'luadoc/doclet/html/' then
    local p = io.popen('markdown "'..M.options.template_dir..'.header.md"')
    template.header = p:read('*all')
    p:close()
    p = io.popen('markdown "'..M.options.template_dir..'.footer.md"')
    template.footer = p:read('*all')
    p:close()
  end

  -- Create the navigation list.
  local hierarchy = {}
  for _, name in ipairs(modules) do
    local parent, self = name:match('^(.-)%.?([^.]+)$')
    local h = hierarchy
    for table in parent:gmatch('[^.]+') do
      if not h[table] then h[table] = {} end
      h = h[table]
    end
    h[#h + 1] = self
  end
  (require 'lfs').mkdir(M.options.output_dir..'/api')
  local navfile = M.options.output_dir..'/api/.nav.md'
  local f = io_open(navfile, 'wb')
  write_nav(f, hierarchy)
  f:close()
  local p = io_popen('markdown "'..navfile..'"')
  local nav = p:read('*all')
  p:close()

  -- Write index.html.
  template.nav = nav
  local api_index = M.options.output_dir..'/.api_index.md'
  if (require 'lfs').attributes(api_index) then
    local p = io_popen('markdown -f toc -T "'..api_index..'"')
    template.toc, template.main = p:read('*all'):match('^(.-\n</ul>\n)(.+)$')
    p:close()
  end
  f = io_open(M.options.output_dir..'/api/index.html', 'wb')
  local html = HTML:gsub('%%%(([^)]+)%)', template)
  f:write(html)
  f:close()

  -- Create a map of doc objects to file names so their Markdown doc comments
  -- can be extracted.
  local filedocs = {}
  for _, name in ipairs(files) do filedocs[files[name].doc] = name end

  -- Loop over modules, creating Markdown documents.
  for _, name in ipairs(modules) do
    local module = modules[name]
    local filename = filedocs[module.doc]

    local mdfile = M.options.output_dir..'/api/'..name..'.md'
    local f = io_open(mdfile, 'wb')

    -- Write the header and description.
    f:write('# ', name, '\n\n')
    f:write(module.description, '\n\n')
    f:write('- - -\n\n')

    -- Write fields.
    if module.doc[1].class == 'module' then
      local fields = module.doc[1].field
      if fields and #fields > 0 then
        table.sort(fields)
        f:write('## Fields\n\n')
        f:write('- - -\n\n')
        for _, field in ipairs(fields) do
          local type, description = fields[field]:match('^(%b())%s*(.+)$')
          f:write(string_format(FIELD, field, field, type or ''))
          write_description(f, description or fields[field])
          f:write('- - -\n\n')
        end
        f:write('\n')
      end
    end

    -- Write functions.
    local funcs = module.functions
    if #funcs > 0 then
      f:write('## Functions\n\n')
      f:write('- - -\n\n')
      for _, fname in ipairs(funcs) do
        local func = funcs[fname]
        f:write(string_format(FUNCTION, func.name, func.name,
                              table_concat(func.param, ', '):gsub('_', '\\_')))
        write_description(f, func.description)
        write_hashmap(f, PARAM, func.param)
        write_list(f, USAGE, func.usage)
        write_list(f, RETURN, func.ret)
        write_list(f, SEE, func.see)
        f:write('- - -\n\n')
      end
      f:write('\n')
    end

    -- Write tables.
    local tables = module.tables
    if #tables > 0 then
      f:write('## Tables\n\n')
      f:write('- - -\n\n')
      for _, tname in ipairs(tables) do
        local tbl = tables[tname]
        f:write(string_format(TABLE, tbl.name, tbl.name))
        write_description(f, tbl.description)
        write_hashmap(f, TFIELD, tbl.field)
        write_list(f, USAGE, tbl.usage)
        write_list(f, SEE, tbl.see)
        f:write('- - -\n\n')
      end
    end

    f:close()

    -- Write HTML.
    template.title = name..' - Textadept API'
    template.nav = nav:gsub('<a[^>]+>('..name:match('[^%.]+$')..')</a>', '%1')
    local p = io_popen('markdown -f toc -T "'..mdfile..'"')
    template.toc, template.main = p:read('*all'):match('^(.-\n</ul>\n)(.+)$')
    p:close()
    template.toc = template.toc:gsub('(<a.-)%b()(</a>)', '%1%2') -- strip params
                               :gsub('<code>([^<]+)</code>', '%1') -- sans serif
                               :gsub('_G.(events.[%w_]+)', '<small>%1</small>')
                               :gsub('SC_[%u]+', '<small>%0</small>')
    f = io_open(M.options.output_dir..'/api/'..name..'.html', 'wb')
    local html = HTML:gsub('%%%(([^)]+)%)', template)
    f:write(html)
    f:close()
  end
end

return M

-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local HTML = [[
  <!doctype html>
  <html>
    <head>
      <title>%(title)</title>
      <link rel="stylesheet" href="../style.css" type="text/css" />
      <meta charset="utf-8" />
    </head>
    <body>
      <div id="content">
        <div id="nav">
          <h2>Manual</h2>
          %(nav)
        </div>
        <div id="toc">
          <h2>Contents</h2>
          %(toc)
        </div>
        <div id="main">
          %(main)
        </div>
      </div>
    </body>
  </html>
]]

-- Get manual pages.
local pages = {}
local lfs = require 'lfs'
for file in lfs.dir('manual/') do
  if file:find('^%d+_.-%.md$') then pages[#pages + 1] = file end
end
table.sort(pages)
pages[#pages + 1] = '../../README.md'
pages[#pages + 1] = '../../CHANGELOG.md'
pages[#pages + 1] = '../../THANKS.md'

-- Create the navigation list.
local navfile = 'manual/.nav.md'
local f = io.open(navfile, 'wb')
for _, page in ipairs(pages) do
  local name = page:match('^%A+(.-)%.md$'):gsub('(%l)(%u)', '%1 %2')
  if page:find('^%.%./') then page = page:match('^%A+(.+)$') end
  f:write('* [', name, '](', page:gsub('%.md$', '.html'), ')\n')
end
f:close()
local p = io.popen('markdown "'..navfile..'"')
local nav = p:read('*all')
p:close()

-- Write HTML.
for _, page in ipairs(pages) do
  local name = page:match('^%A+(.-)%.md$'):gsub('(%l)(%u)', '%1 %2')
  local p = io.popen('markdown -f toc -T "manual/'..page..'"')
  local toc, main = p:read('*all'):match('^(.-\n</ul>\n)(.+)$')
  p:close()
  if page:find('^%.%./') then page = page:match('^%A+(.+)$') end
  f = io.open('manual/'..page:gsub('%.md$', '.html'), 'wb')
  local html = HTML:gsub('%%%(([^)]+)%)', {
    title = name..' - Textadept Manual', nav = nav, toc = toc, main = main
  })
  f:write(html)
  f:close()
end

#!/usr/bin/lua
-- Filters the given file through markdown, replaces simple {{ variable }}
-- templates, and saves the result to an HTML file of the same name for offline
-- documentation generation.

-- Filter the file through markdown using TOC generation in order to get header
-- anchors, but ignore the actual TOC.
local name = arg[1]
local f = io.open(name, 'r')
local markdown = f:read('*a')
f:close()
local p = io.popen('markdown -f toc -T ' .. name)
local html = p:read('*a'):match('^.-\n</ul>\n(.+)$')
p:close()

-- Fill in HTML layout with markdown content.
f = io.open('../docs/_layouts/default.html')
html = f:read('*a'):gsub('{{ page.title }}', html:match('<h%d.->([^<]+)')):
  gsub('{{ content }}', (html:gsub('%%', '%%%%')))
f:close()

-- Write to HTML file.
io.open(name:gsub('^(.+)%.md$', '%1.html'), 'wb'):write(html):close()

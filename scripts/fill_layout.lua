#!/usr/bin/lua
-- Filters the given file through markdown, inserts it into the template
-- specified by stdin by replacing simple {{ variable }} tags, and outputs the
-- result to stdout.

-- Filter the file through markdown using TOC generation in order to get header
-- anchors, but ignore the actual TOC.
local name = arg[1]
local f = io.open(name, 'r')
local markdown = f:read('*a')
f:close()
local p = io.popen('markdown -f toc -T ' .. name)
local html = p:read('*a'):match('^.-\n</ul>\n(.+)$')
p:close()

-- Fill in HTML layout (stdin) with markdown output and print the result.
local title, content = '{{ page.title }}', '{{ content }}'
io.write(io.stdin:read('*a'):gsub(title, html:match('<h%d.->([^<]+)')):
  gsub(content, (html:gsub('%%', '%%%%'))))

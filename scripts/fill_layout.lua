#!/usr/bin/lua
-- Filters the given file through markdown, inserts it into the template
-- specified by stdin by replacing simple {{ variable }} tags, and outputs the
-- result to stdout.

-- Filter the file through markdown using TOC generation in order to get header
-- anchors, but ignore the actual TOC.
local p = io.popen('markdown -f toc -T ' .. arg[1])
local html = p:read('*a'):match('^.-\n</ul>\n(.+)$')
p:close()

-- Fill in HTML layout (stdin) with markdown output and print the result.
local tags = {
  ['page.title'] = html:match('<h%d.->([^<]+)'),
  content = html:gsub('%%', '%%%%')
}
io.write(io.stdin:read('*a'):gsub('{{ (%S+) }}', tags))

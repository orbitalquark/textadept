#!/usr/bin/env lua
-- Copyright 2020-2024 Mitchell. See LICENSE.

-- Filters the given file through markdown, inserts it into the template specified by stdin by
-- replacing simple {{ variable }} tags, and outputs the result to stdout.
-- Requires Discount.
-- Usage: cat template.html | fill_layout.lua file.md > file.html

-- Filter the file through markdown using TOC generation in order to get header anchors, but
-- ignore the actual TOC.
local p = io.popen('markdown -f toc -T ' .. arg[1])
local html = p:read('a'):match('^.-\n</ul>\n(.+)$')
html = html:gsub('<h(%d) id="([^"]+)"', function(n, id)
	id = id:gsub('%p+', '-'):gsub('%-$', ''):lower():gsub('^l%-', '')
	return string.format('<h%d id="%s"', n, id)
end)
p:close()

-- Fill in HTML layout (stdin) with markdown output and print the result.
local tags = {['page.title'] = html:match('<h%d.->([^<]+)'), content = html}
io.write((io.stdin:read('*a'):gsub('{{ (%S+) }}', tags)))

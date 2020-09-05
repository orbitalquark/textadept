#!/usr/bin/lua
-- Part of a pipeline that fills in simple {{ variable }} templates when
-- generating documentation offline.
-- cat file.md | markdown | gen_doc > file.html

local html = io.read('*a')
local f = io.open('../docs/_layouts/default.html')
io.write(
  f:read('*a'):gsub('{{ page.title }}', html:match('<h%d>([^<]+)')):
    gsub('{{ content }}', (html:gsub('%%', '%%%%'))))
f:close()

-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Snippets for the lua module.
module('_m.lua.snippets', package.seeall)

local snippets = _G.snippets

if type(snippets) == 'table' then
  snippets.lua = {
    l = "local %1(expr)%2( = %3(value))",
    p = "print(%0)",
    f = "function %1(name)(%2(args))\n\t%0\nend",
    ['for'] = "for i=%1(1), %2(10)%3(, -1) do\n\t%0\nend",
    fori = "for %1(i), %2(val) in ipairs(%3(table)) do\n\t%0\nend",
    forp = "for %1(k), %2(v) in pairs(%3(table)) do\n\t%0\nend",
  }
end


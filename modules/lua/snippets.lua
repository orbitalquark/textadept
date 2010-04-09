-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Snippets for the lua module.
module('_m.lua.snippets', package.seeall)

local snippets = _G.snippets

if type(snippets) == 'table' then
  snippets.lua = {
    l    = "local %1(expr)%2( = %3(value))",
    p    = "print(%0)",
    f    = "function %1(name)(%2(args))\n\t%0\nend",
    fori = "for %1(i), %2(val) in ipairs(%3(table)) do\n\t%0\nend",
    ['for'] = "for i=%1(1), %2(10)%3(, -1) do\n\t%0\nend",
    forp = "for %1(k), %2(v) in pairs(%3(table)) do\n\t%0\nend",
    find = "string.find(%1(str), %2(pattern))",
    len  = "string.len(%1(str))",
    gsub = "string.gsub(%1(str), %2(pattern), %3(repl))",
    gfind = "for %1(match) in string.gfind(%2(str), %3(pattern)) do\n\t%0\nend",
    c    = "-- ",

    tc  = "local %1(tc) = lunit.TestCase('%2(description)')",
    ae  = "lunit.assert_equal(%1(expected), %2(actual))",
    ane = "lunit.assert_not_equal(%1(unexpected), %2(actual))",
    at  = "lunit.assert_true(%1(actual))",
    af  = "lunit.assert_false(%1(actual))",
    run = "lunit.run()",
    abool  = "lunit.assert_boolean(%1(expr))",
    anbool = "lunit.assert_not_boolean(%1(expr))",
    ['anil'] = "lunit.assert_nil(%1(expr))",
    annil  = "lunit.assert_not_nil(%1(expr))",
    anum   = "lunit.assert_number(%1(expr))",
    annum  = "lunit.assert_not_number(%1(expr))",
    astr   = "lunit.assert_string(%1(expr))",
    anstr  = "lunit.assert_not_string(%1(expr))",
    atab   = "lunit.assert_table(%1(expr))",
    antab  = "lunit.assert_not_table(%1(expr))",
    athr   = "lunit.assert_thread(%1(expr))",
    anthr  = "lunit.assert_not_thread(%1(expr))",
    afunc  = "lunit.assert_function(%1(expr))",
    anfunc = "lunit.assert_not_function(%1(expr))",
    aud    = "lunit.assert_userdata(%1(expr))",
    anud   = "lunit.assert_not_userdata(%1(expr))"
  }
end


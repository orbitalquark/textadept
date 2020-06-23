function foo() end
local function bar() end
baz = {}
function baz:quux() end

--[[ For LuaDoc
module('foo')]]
local M = {}

---
-- Foo
-- @name new
function M.new() end

return M

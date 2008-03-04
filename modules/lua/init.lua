-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- The lua module.
-- It provides utilities for editing Lua code.
module('_m.lua', package.seeall)

if type(_G.snippets) == 'table' then
---
-- Container for Lua-specific snippets.
-- @class table
-- @name snippets.lua
  _G.snippets.lua = {}
end

if type(_G.keys) == 'table' then
---
-- Container for Lua-specific key commands.
-- @class table
-- @name keys.lua
  _G.keys.lua = {}
end

require 'lua.commands'
require 'lua.snippets'

function set_buffer_properties()

end

api = textadept.io.read_api_file(_HOME..'/modules/lua/api', '%w_.:')

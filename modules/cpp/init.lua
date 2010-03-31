-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- The cpp module.
-- It provides utilities for editing C/C++ code.
module('_m.cpp', package.seeall)

if type(_G.snippets) == 'table' then
---
-- Container for C/C++-specific snippets.
-- @class table
-- @name snippets.cpp
  _G.snippets.cpp = {}
end

if type(_G.keys) == 'table' then
---
-- Container for C/C++-specific key commands.
-- @class table
-- @name keys.cpp
  _G.keys.cpp = {}
end

require 'cpp.commands'
require 'cpp.snippets'

function set_buffer_properties()

end

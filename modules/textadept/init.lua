-- Copyright 2007-2021 Mitchell. See LICENSE.

local M = {}
textadept = M -- forward declaration

--[[ This comment is for LuaDoc.
---
-- The textadept module.
-- It provides utilities for editing text in Textadept.
module('textadept')]]

local modules = {
  'bookmarks', 'command_entry', 'editing', 'file_types', 'find', 'history', 'macros', 'run',
  'session', 'snippets', --[[need to be last]] 'menu', 'keys'
}
for _, name in ipairs(modules) do M[name] = require('textadept.' .. name) end
M.command_entry, M.find = nil, nil -- ui.command_entry, ui.find

return M

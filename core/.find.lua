-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept.find table.

---
-- Textadept's integrated find/replace dialog.
-- [Dummy file]
module('textadept.find')

-- Usage:
-- In additional to offering standard find and replace, Textadept allows you
-- to find with Lua patterns and replace with Lua captures and even Lua code!
-- Lua captures (%n) are available for a Lua pattern search and embedded Lua
-- code enclosed in %() is always available.

---
-- Textadept's find table.
-- @class table
-- @name textadept.find
-- @field find_entry_text The text in the find entry.
-- @field replace_entry_text The text in the replace entry.
find = { find_entry_text = nil, replace_entry_text = nil }

--- Displays and focuses the find/replace dialog.
function focus() end

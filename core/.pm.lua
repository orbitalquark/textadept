-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept.pm table.

---
-- Textadept's project manager.
-- [Dummy file]
module('textadept.pm')

---
-- Textadept's project manager table.
-- @class table
-- @name textadept.pm
-- @field entry_text The text in the entry.
-- @field width The width of the project manager.
pm = {}

--- Focuses the project manager entry.
function focus() end

--- Clears the project manager contents.
function clear() end

--- Requests the project manager to get its contents based on its entry text.
function activate() end

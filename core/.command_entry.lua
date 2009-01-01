-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept.command_entry table.

---
-- Textadept's Lua command entry.
-- [Dummy file]
module('textadept.command_entry')

---
-- Textadept's Lua command entry table.
-- @class table
-- @name textadept.command_entry
-- @field entry_text The text in the entry.
command_entry = {}

--- Focuses the command entry.
function focus() end

---
-- Gets completions for the current command_entry text.
-- This function is called internally and shouldn't be called by script.
-- @param command The command to complete.
-- @return sorted table of completions
function get_completions_for(command) end

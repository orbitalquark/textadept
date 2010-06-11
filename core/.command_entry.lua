-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global gui.command_entry table.

---
-- Textadept's Command entry.
module('gui.command_entry')

-- Markdown:
-- ## Fields
--
-- * `entry_text`: The text in the entry.
--
-- ## Overview
--
-- Access to the Lua state is available through this command entry. It is useful
-- for debugging, inspecting, and entering buffer or view commands. If you try
-- cause instability in Textadept's Lua state, you might very well succeed. Be
-- careful.
--
-- Tab-completion for functions, variables, tables, etc. is available. Press the
-- `Tab` key to display a list of available completions. Use the arrow keys to
-- make a selection and press `Enter` to insert it.
--
-- Note: Use [`gui.print()`][gui_print] instead of the global `print()`
-- function. The former prints to a new buffer, the latter to standard out
-- (`STDOUT`).
--
-- [gui_print]: ../modules/gui.html#print
--
-- ## Extending
--
-- You can extend the command entry to do more than enter Lua commands. An
-- example of this is [incremental search][inc_search]. See
-- `modules/textadept/find.lua` for the implementation.
--
-- [inc_search]: ../modules/gui.find.html#incremental

--- Focuses the command entry.
function focus() end

-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept.find table.

---
-- Textadept's integrated find/replace dialog.
-- [Dummy file]
module('textadept.find')

-- Usage:
-- In addition to offering standard find and replace, Textadept allows you to
-- find with Lua patterns and replace with Lua captures and even Lua code! Lua
-- captures (%n) are available for a Lua pattern search and embedded Lua code
-- enclosed in %() is always available.
--
-- If any block of text is selected for 'Replace All', only matches found in
-- that block are replaced.
--
-- Find in Files will prompt for a directory to recursively search and display
-- the results in a new buffer. Double-clicking a search result will jump to it
-- in the file. Replace in Files is not supported. You will have to Find in
-- Files first, and then 'Replace All' for each file a result is found in.
-- The 'Match Case', 'Whole Word', and 'Lua pattern' flags still apply.

---
-- Textadept's find table.
-- @class table
-- @name textadept.find
-- @field find_entry_text The text in the find entry.
-- @field replace_entry_text The text in the replace entry.
find = { find_entry_text = nil, replace_entry_text = nil }

--- Displays and focuses the find/replace dialog.
function focus() end

---
-- [Local table] Text escape sequences with their associated characters.
-- @class table
-- @name escapes
local escapes = {}

---
-- Finds and selects text in the current buffer.
-- This is used by the find dialog. It is recommended to use the buffer:find()
-- function for scripting.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a number mask of 4 flags: match case (2),
--   whole word (4), Lua pattern (8), and in files (16) joined with binary OR.
--   If nil, this is determined based on the checkboxes in the find box.
-- @param nowrap Flag indicating whether or not the search won't wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or -1
function find.find(text, next, flags, nowrap, wrapped) end

---
-- Replaces found text.
-- This function is used by the find dialog. It is not recommended to call it
-- via scripts.
-- textadept.find.find is called first, to select any found text. The selected
-- text is then replaced by the specified replacement text.
-- This function ignores 'Find in Files'.
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (%n where 1 <= n <= 9) for Lua pattern searches and %()
--   sequences for embedding Lua code for any search.
-- @see find.find
function find.replace(rtext) end

---
-- Replaces all found text.
-- This function is used by the find dialog. It is not recommended to call it
-- via scripts.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores 'Find in Files'.
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @param flags The number mask identical to the one in 'find'.
-- @see find.find
function find.replace_all(ftext, rtext, flags) end

---
-- Mimicks a press of the 'Find Next' button in the Find box.
function find.call_find_next() end

---
-- Mimicks a press of the 'Find Prev' button in the Find box.
function find.call_find_prev() end

---
-- Mimicks a press of the 'Replace' button in the Find box.
function find.call_replace() end

---
-- Mimicks a press of the 'Replace All' button in the Find box.
function find.call_replace_all() end

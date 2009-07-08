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
--
-- Customizing look and feel:
--   Like the project manager, there are no function calls to make that
--   customize the look and feel of the find dialog. Instead you can manipulate
--   it via GTK rc files. The find and replace entries widget names of
--   'textadept-find-entry' and 'textadept-replace-entry' respectively.
--   Resource file documentation can be found at
--   http://library.gnome.org/devel/gtk/unstable/gtk-Resource-Files.html.

---
-- Textadept's find table.
-- @class table
-- @name find
-- @field find_entry_text The text in the find entry.
-- @field replace_entry_text The text in the replace entry.
-- @field match_case Flag indicating whether or not case-sensitive search is
--   performed.
-- @field whole_word Flag indicating whether or not only whole-word matches are
--   allowed in searches.
-- @field lua Flag indicating whether or not the text to find in a search is a
--   Lua pattern.
-- @field in_files Flag indicating whether or not to search for the text in a
--   list of files.
find = {
  find_entry_text = nil, replace_entry_text = nil,
  match_case = nil, whole_word = nil, lua = nil, in_files = nil
}

--- Displays and focuses the find/replace dialog.
function focus() end

---
-- Mimicks a press of the 'Find Next' button in the Find box.
function find_next() end

---
-- Mimicks a press of the 'Find Prev' button in the Find box.
function find_prev() end

---
-- Mimicks a press of the 'Replace' button in the Find box.
function replace() end

---
-- Mimicks a press of the 'Replace All' button in the Find box.
function replace_all() end

---
-- Goes to the next or previous file found relative to the file
-- on the current line.
-- @param next Flag indicating whether or not to go to the next file.
function find.goto_file_in_list(next) end

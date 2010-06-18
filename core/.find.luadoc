-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global gui.find table.

---
-- Textadept's integrated find/replace dialog.
module('gui.find')

-- Markdown:
-- ## Fields
--
-- * `find_entry_text`: The text in the find entry.
-- * `replace_entry_text`: The text in the replace entry.
-- * `match_case`: Flag indicating whether or not case-sensitive search is
--   performed.
-- * `whole_word`: Flag indicating whether or not only whole-word matches are
--   allowed in searches.
-- * `lua`: Flag indicating whether or not the text to find in a search is a Lua
--   pattern.
-- * `in_files`: Flag indicating whether or not to search for the text in a list
--   of files.
--
-- ## Overview
--
-- In addition to offering standard find and replace, Textadept allows you to
-- find with [Lua patterns][lua_patterns] and replace with Lua captures and even
-- Lua code! Lua captures (`%n`) are only available from a Lua pattern search,
-- but embedded Lua code enclosed in `%()` is always available.
--
-- [lua_patterns]: http://www.lua.org/manual/5.1/manual.html#5.4.1
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
-- Incremental search uses the Command Entry.
--
-- ## Customizing Look and Feel
--
-- There is no way to theme the dialog from within Textadept. Instead you can
-- use [GTK Resource files][gtkrc]. The find and replace entries have widget
-- names of `textadept-find-entry` and `textadept-replace-entry` respectively.
--
-- [gtkrc]: http://library.gnome.org/devel/gtk/unstable/gtk-Resource-Files.html.

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
function goto_file_in_list(next) end

---
-- Begins an incremental find using the Lua command entry.
-- Lua command functionality will be unavailable until the search is finished
-- (pressing 'Escape' by default).
function incremental() end

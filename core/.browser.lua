-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for a textadept.pm browser.

---
-- A model browser for the Textadept project manager.
-- It can be loaded by adding to the browsers table in core/ext/pm.lua.
-- [Dummy file]
module('textadept.pm.browser')

---
-- Determines whether or not to use this browser for the text in the project
-- manager entry.
-- All loaded browsers are called in sequence to match to the given entry text.
-- When a match is found, that browser is used.
-- @param entry_text The text in the entry.
-- @return boolean indicating whether or not to use this browser.
function matches(entry_text)

---
-- This function is called for contents to show in the browser.
-- @param full_path An ordered list of parent IDs leading down to the selected
--   child (if expanding); the entry text is at the first index.
-- @param expanding Boolean indicating whether or not a parent is being
--   expanded.
-- @return table of contents to display. Each entry in the table is a key-value
--   pair. The key must be a string ID and the value a table. Three key-value
--   pairs are looked for in the table: parent, pixbuf, and text. parent is an
--   optional boolean indicating whether or not the item should be identified as
--   a parent (parents can be expanded so they have the arrow next to them).
--   pixbuf is an optional string specifying a GTK stock icon to be associated
--   with the item. text is a required string that is shown in the project
--   manager; it can have Pango markup. All other items in the table are
--   ignored.
function get_contents_for(full_path, expanding)

---
-- This function is called when a user selects an item in the browser.
-- @param selected_item An ordered list of parent IDs leading down to the
--   selected child; the entry text is at the first index.
function perform_action(selected_item)

---
-- Requests a context menu for the selected item in the browser.
-- @param selected_item An ordered list of parent IDs leading down to the
--   selected child; the entry text is at the first index.
-- @return table used to construct a GTK menu.
-- @see textadept.gtkmenu
function get_context_menu(selected_item)

---
-- This function is called when a user selects a context menu item.
-- @param menu_item The text of the menu item selected.
-- @param selected_item An ordered list of parent IDs leading down to the
--   selected child; the entry text is at the first index.
function perform_menu_action(menu_item, selected_item)

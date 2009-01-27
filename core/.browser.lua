-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for a textadept.pm browser.

---
-- A model browser for the Textadept project manager.
-- It can be loaded by adding to the browsers table in core/ext/pm.lua or by
-- 'require'ing it elsewhere.
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
-- Requests treeview contents from browser that matches pm_entry's text.
-- This function is called internally and shouldn't be called by a script.
-- @param full_path A numerically indexed table of treeview item parents. The
--   first index contains the text of pm_entry. Subsequent indexes contain the
--   ID's of parents of the child requested for expanding (if any).
-- @param expanding Optional flag indicating if the contents of a parent are
--   being requested. Defaults to false.
-- @return table of tables to for display in the treeview (single level).
--   Each key in the return table is the treeview item's ID. The table value
--   has the following recognized fields:
--     parent - boolean value indicating if this entry can contain children. If
--       true, an expanding arrow is displayed next to the entry.
--     pixbuf - a string representing a GTK stock-id whose icon is displayed
--       next to an entry.
--     text - the entry's Pango marked-up display text.
--   Note that only a SINGLE level of data needs to be returned. When parents
--   are expanded, this function is called again to get that level of data.
function get_contents_for(full_path, expanding)

---
-- Performs an action based on the selected treeview item.
-- This function is called internally and shouldn't be called by a script.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @see pm.get_contents_for
function perform_action(selected_item)

---
-- Creates a context menu based on the selected treeview item.
-- This function is called internally and shouldn't be called by a script.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @return table of menu items.
--   The return table consists of an ordered list of strings to be used to
--   construct a context menu. The strings are handled as follows:
--     'gtk-*' - a stock menu item is created based on the GTK stock-id.
--     'separator' - a menu separator item is created.
--     Otherwise a regular menu item with a mnemonic is created.
-- @see pm.get_contents_for
function get_context_menu(selected_item)

---
-- Performs an action based on the selected menu item.
-- This function is called internally and shouldn't be called by a script.
-- @param menu_id The numeric ID of the menu item.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @see pm.get_contents_for
function perform_menu_action(menu_id, selected_item)

---
-- Toggles the width of the project manager.
-- If the pm is visible, it's width is saved and then set to 0, effectively
-- hiding it. If it is hidden, the width is restored.
function toggle_visible()

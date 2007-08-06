-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Browsers loaded by the project manager.
-- @class table
-- @name browsers
local browsers = { 'buffer_browser', 'file_browser', 'ctags_browser' }
for _, b in ipairs(browsers) do require('ext/pm.'..b) end

local pm = textadept.pm

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
function pm.get_contents_for(full_path, expanding)
  for _, browser in pairs(pm.browsers) do
    if browser.matches( full_path[1] ) then
      return browser.get_contents_for(full_path, expanding)
    end
  end
end

---
-- Performs an action based on the selected treeview item.
-- This function is called internally and shouldn't be called by a script.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @see pm.get_contents_for
function pm.perform_action(selected_item)
  for _, browser in pairs(pm.browsers) do
    if browser.matches( selected_item[1] ) then
      return browser.perform_action(selected_item)
    end
  end
end

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
function pm.get_context_menu(selected_item)
  for _, browser in pairs(pm.browsers) do
    if browser.matches( selected_item[1] ) then
      return browser.get_context_menu(selected_item)
    end
  end
end

---
-- Performs an action based on the selected menu item.
-- This function is called internally and shouldn't be called by a script.
-- @param menu_item The label text of the menu item selected.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @see pm.get_contents_for
function pm.perform_menu_action(menu_item, selected_item)
  for _, browser in pairs(pm.browsers) do
    if browser.matches( selected_item[1] ) then
      return browser.perform_menu_action(menu_item, selected_item)
    end
  end
end

---
-- Toggles the width of the project manager.
-- If the pm is visible, it's width is saved and then set to 0, effectively
-- hiding it. If it is hidden, the width is restored.
function pm.toggle_visible()
  if pm.width > 0 then
    pm.prev_width = pm.width
    pm.width = 0
  else
    pm.width = pm.prev_width or 150
  end
end

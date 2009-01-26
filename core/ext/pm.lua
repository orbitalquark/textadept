-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

-- Usage:
-- Interactive search:
--   Typing text into the project manager view begins the interactive search.
--   If the text matches ANY part of an item in the view (case sensitively), the
--   item is highlighted and subsequent matches can be navigated to using the
--   up/down arrow keys.
--
-- Customizing look and feel:
--   There are no function calls to make that customize the look and feel of the
--   project manager. Instead you can manipulate it via GTK rc files. The pm
--   entry and view have widget names of 'textadept-pm-entry' and
--   'textadept-pm-view' respectively. Resource file documentation can be found
--   at http://library.gnome.org/devel/gtk/unstable/gtk-Resource-Files.html.
--   My rc file is something like this:
--
--     pixmap_path "/usr/share/icons/Tango/:/home/mitchell/.icons/prog/"
--
--     style "textadept-pm-display-style" {
--        fg[NORMAL]     = "#AAAAAA" # treeview arrows foreground
--        fg[PRELIGHT]   = "#AAAAAA" # treeview arrows hover foreground
--        bg[NORMAL]     = "#333333" # entry border background
--        base[NORMAL]   = "#333333" # entry, treeview background
--        base[ACTIVE]   = "#444444" # treeview unfocused selection background
--        base[SELECTED] = "#444444" # entry, treeview selection background
--        text[NORMAL]   = "#AAAAAA" # entry, treeview text foreground
--        text[ACTIVE]   = "#AAAAAA" # treeview unfocused selection text
--        text[SELECTED] = "#DDDDDD" # entry, treeview selection text foreground
--
--        stock["gtk-directory"]  = {{ "16x16/places/stock_folder.png", LTR }}
--        stock["gtk-folder-new"] = {{ "16x16/actions/folder_new.png", LTR }}
--        stock["prog-class"]     = {{ "class.png", LTR }}
--        stock["prog-enum"]      = {{ "enum.png", LTR }}
--        stock["prog-field"]     = {{ "field.png", LTR }}
--        stock["prog-interface"] = {{ "interface.png", LTR }}
--        stock["prog-literal"]   = {{ "literal.png", LTR }}
--        stock["prog-method"]    = {{ "method.png", LTR }}
--        stock["prog-namespace"] = {{ "namespace.png", LTR }}
--        stock["prog-reference"] = {{ "reference.png", LTR }}
--        stock["prog-struct"]    = {{ "struct.png", LTR }}
--      }
--
--      widget "*textadept-pm-entry" style "textadept-pm-display-style"
--      widget "*textadept-pm-view" style "textadept-pm-display-style"

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
    if browser.matches(full_path[1]) then
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
    if browser.matches(selected_item[1]) then
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
    if browser.matches(selected_item[1]) then
      return browser.get_context_menu(selected_item)
    end
  end
end

---
-- Performs an action based on the selected menu item.
-- This function is called internally and shouldn't be called by a script.
-- @param menu_id The numeric ID of the menu item.
-- @param selected_item Identical to 'full_path' in pm.get_contents_for.
-- @see pm.get_contents_for
function pm.perform_menu_action(menu_id, selected_item)
  for _, browser in pairs(pm.browsers) do
    if browser.matches(selected_item[1]) then
      return browser.perform_menu_action(menu_id, selected_item)
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

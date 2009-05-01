-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept.pm table.

---
-- Textadept's project manager.
-- [Dummy file]
module('textadept.pm')

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

---
-- Textadept's project manager table.
-- @class table
-- @name textadept.pm
-- @field entry_text The text in the entry.
-- @field width The width of the project manager.
-- @field cursor The cursor in the project manager (string representation of
--   current GtkTreePath).
pm = { entry_text = nil, width = nil, cursor = nil }

--- Focuses the project manager entry.
function focus() end

--- Clears the project manager contents.
function clear() end

--- Requests the project manager to get its contents based on its entry text.
function activate() end

---
-- Adds a browser prefix to the list of browsers available in the project
-- manager entry combo box.
-- @param prefix The text to add.
function add_browser(prefix) end

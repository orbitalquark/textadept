-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept table.

---
-- The core textadept table.
-- [Dummy file]
module('textadept')

---
-- The core textadept table.
-- @class table
-- @name textadept
-- @field title The title of the Textadept window.
-- @field focused_doc_pointer The pointer to the document associated with the
--   buffer of the currently focused view. (Used internally; read-only)
-- @field menubar A table of GTK menus defining a menubar (write-only).
-- @field clipboard_text The text on the clipboard (read-only).
-- @field statusbar_text The text displayed by the statusbar (write-only).
-- @field docstatusbar_text The text displayed by the doc statusbar
--   (write-only).
-- @field size The size of the Textadept window ({ width, height}).
textadept = {
  title = nil, focused_doc_pointer = nil, clipboard_text = nil, menubar = nil,
  statusbar_text = nil, docstatusbar_text = nil, size = nil
}

---
-- A numerically indexed table of open buffers in Textadept.
-- @class table
-- @name buffers
buffers = {}

---
-- A numerically indexed table of views in Textadept.
-- @class table
-- @name views
views = {}

---
-- Creates a new buffer.
-- Activates the 'buffer_new' signal.
-- @return the new buffer.
function new_buffer() end

---
-- Goes to the specified view.
-- Activates the 'view_switch' signal.
-- @param n A relative or absolute view index.
-- @param absolute Flag indicating if n is an absolute index or not.
function goto_view(n, absolute) end

---
-- Gets the current split view structure.
-- @return table of split views. Each split view entry is a table with 4
--   fields: 1, 2, vertical, and size. 1 and 2 have values of either
--   split view entries or the index of the buffer shown in each view.
--   vertical is a flag indicating if the split is vertical or not, and
--   size is the integer position of the split resizer.
function get_split_table() end

---
-- Creates a GTK menu, returning the userdata.
-- @param menu_table A table defining the menu. It is an ordered list of tables
--   with a string menu item and integer menu ID.
--   The string menu item is handled as follows:
--     'gtk-*' - a stock menu item is created based on the GTK stock-id.
--     'separator' - a menu separator item is created.
--     Otherwise a regular menu item with a mnemonic is created.
--   Submenus are just nested menu-structure tables. Their title text is defined
--   with a 'title' key.
-- @see popupmenu
function gtkmenu(menu_table) end

---
-- Pops up a GTK menu at the cursor.
-- @param menu The menu userdata returned by gtkmenu.
-- @see gtkmenu
function popupmenu(menu) end

---
-- Resets the Lua state by reloading all init scripts.
-- Language-specific modules for opened files are NOT reloaded. Re-opening the
-- files that use them will reload those modules.
-- This function is useful for modifying init scripts (such as key_commands.lua)
-- on the fly without having to restart Textadept.
-- A global RESETTING variable is set to true when re-initing the Lua State. Any
-- scripts that need to differentiate between startup and reset can utilize this
-- variable.
function reset() end

--- Quits Textadept.
function quit() end

---
-- Checks if the buffer being indexed is the currently focused buffer.
-- This is necessary because any buffer actions are performed in the focused
-- views' buffer, which may not be the buffer being indexed. Throws an error
-- if the check fails.
-- @param buffer The buffer in question.
function check_focused_buffer(buffer) end

---
-- Helper function for printing messages to buffers.
-- Splits the view and opens a new buffer for printing messages. If the message
-- buffer is already open and a view is currently showing it, the message is
-- printed to that view. Otherwise the view is split, goes to the open message
-- buffer, and prints to it.
-- @param buffer_type String type of message buffer.
-- @param ... Message strings.
-- @usage textadept._print(textadept.locale.ERROR_BUFFER, error_message)
-- @usage textadept._print(textadept.locale.MESSAGE_BUFFER, message)
function _print(buffer_type, ...)

---
-- Prints messages to the Textadept message buffer.
-- Opens a new buffer (if one hasn't already been opened) for printing messages.
-- @param ... Message strings.
function textadept.print(...) end

---
-- Displays a CocoaDialog of a specified type with given arguments returning
-- the result.
-- @param kind The CocoaDialog type.
-- @param opts A table of key, value arguments. Each key is a --key switch with
--   a "value" value. If value is nil, it is omitted and just the switch is
--   used.
-- @return string CocoaDialog result.
function cocoa_dialog(kind, opts)

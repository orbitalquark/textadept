-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global textadept table.

---
-- The core textadept table.
module('textadept')

-- Markdown:
-- ## Fields
--
-- * `title`: The title of the Textadept window.
-- * `focused_doc_pointer`: The pointer to the document associated with the
--   buffer of the currently focused view. (Used internally; read-only.)
-- * `menubar`: A table of GTK menus defining a menubar (write-only).
-- * `context_menu`: A GTK menu defining the editor's context menu.
-- * `clipboard_text`: The text on the clipboard (read-only).
-- * `statusbar_text`: The text displayed by the statusbar (write-only).
-- * `docstatusbar_text`: The text displayed by the doc statusbar (write-only).
-- * `size`: The size of the Textadept window (`{ width, height}`).
-- * `constants`: Table containing Scintilla constants.
-- * `buffer_functions`: Table containing Scintilla functions.
-- * `buffer_properties`: Table containing Scintilla set/get functions.

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
-- Activates the 'view_*_switch' signal.
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
function gtkmenu(menu_table) end

---
-- Converts a string from one character set to another using iconv().
-- Valid character sets are ones GLib's g_convert() accepts, typically GNU
-- iconv's character sets.
-- @param text The text to convert.
-- @param to The character set to convert to.
-- @param from The character set to convert from.
function iconv(text, to, from) end

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
-- @usage textadept._print(locale.ERROR_BUFFER, error_message)
-- @usage textadept._print(locale.MESSAGE_BUFFER, message)
function _print(buffer_type, ...) end

---
-- Prints messages to the Textadept message buffer.
-- Opens a new buffer (if one hasn't already been opened) for printing messages.
-- @param ... Message strings.
function print(...) end

---
-- Displays a dialog with a list of buffers to switch to and switches to the
-- selected one, if any.
function switch_buffer() end

---
-- Displays a CocoaDialog of a specified type with the given string arguments.
-- Each argument is like a string in Lua's 'arg' table.
-- @return string CocoaDialog result.
function dialog(kind, ...) end

---
-- Calls 'dofile' on the given filename in the user's Textadept directory.
-- This is typically used for loading user files like key commands or snippets.
-- @param filename The name of the file (not path).
function user_dofile(filename) end

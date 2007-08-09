-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.
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
-- @field clipboard_text The text on the clipboard (read-only).
-- @field statusbar_text The text displayed by the statusbar (write-only).
-- @field docstatusbar_text The text displayed by the doc statusbar
--   (write-only).
textadept = { title = nil, focused_doc_pointer = nil, clipboard_text = nil,
  statusbar_text = nil, docstatusbar_text = nil }

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
-- Focuses the command entry.
function focus_command() end

---
-- Checks if the buffer being indexed is the currently focused buffer.
-- This is necessary because any buffer actions are performed in the focused
-- views' buffer, which may not be the buffer being indexed. Throws an error
-- if the check fails.
-- @param buffer The buffer in question.
function check_focused_buffer(buffer) end

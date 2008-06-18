-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global view table.

---
-- The currently focused view.
-- It also represents the structure of any view table in 'views'.
-- [Dummy file]
module('view')

---
-- The currently focused view.
-- It also represents the structure of any view table in 'views'.
-- @class table
-- @name view
-- @field size The integer position of the split resizer (if this view is part
--   of a split view).
view = { size = nil }

---
-- Splits the indexed view vertically or horizontally and focuses the new view.
-- @param vertical Flag indicating a vertical split. False for horizontal.
-- @return old view and new view tables.
function view:split(vertical) end

---
-- Unsplits the indexed view if possible.
-- @return boolean if the view was unsplit or not.
function view:unsplit() end

---
-- Goes to the specified buffer in the indexed view.
-- Activates the 'buffer_switch' signal.
-- @param n A relative or absolute buffer index.
-- @param absolute Flag indicating if n is an absolute index or not.
function view:goto_buffer(n, absolute) end

---
-- Focuses the indexed view if it hasn't been already.
function view:focus() end


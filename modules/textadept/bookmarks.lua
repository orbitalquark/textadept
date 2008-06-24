-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Bookmarks for the textadept module.
-- There are several option variables used:
--   MARK_BOOKMARK: The integer mark used to identify a bookmarked line.
--   MARK_BOOKMARK_COLOR: The Scintilla color used for a bookmarked line.
module('_m.textadept.bookmarks', package.seeall)

-- options
local MARK_BOOKMARK = 0
local MARK_BOOKMARK_COLOR = 0xC08040
-- end options

---
-- Adds a bookmark to the current line.
function add()
  local buffer = buffer
  buffer:marker_set_back(MARK_BOOKMARK, MARK_BOOKMARK_COLOR)
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:marker_add(line, MARK_BOOKMARK)
end

---
-- Clears the bookmark at the current line.
function remove()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:marker_delete(line, MARK_BOOKMARK)
end

---
-- Toggles a bookmark on the current line.
function toggle()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  local markers = buffer:marker_get(line) -- bit mask
  if markers % 2 == 0 then add() else remove() end -- first bit is set?
end

---
-- Clears all bookmarks in the current buffer.
function clear()
  local buffer = buffer
  buffer:marker_delete_all(MARK_BOOKMARK)
end

---
-- Goes to the next bookmark in the current buffer.
function goto_next()
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_next(current_line, 1)
  if line >= 0 then _m.textadept.editing.goto_line(line + 1) end
end

---
-- Goes to the previous bookmark in the current buffer.
function goto_prev()
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_previous(current_line, 1)
  if line >= 0 then _m.textadept.editing.goto_line(line + 1) end
end

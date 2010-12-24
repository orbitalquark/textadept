-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Bookmarks for the textadept module.
module('_m.textadept.bookmarks', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `MARK_BOOKMARK`: The unique integer mark used to identify a bookmarked
--    line.
-- * `MARK_BOOKMARK_COLOR`: The [Scintilla color][scintilla_color] used for a
--    bookmarked line.
--
-- [scintilla_color]: http://scintilla.org/ScintillaDoc.html#colour

-- settings
MARK_BOOKMARK = 1
MARK_BOOKMARK_COLOR = 0xC08040
-- end settings

---
-- Adds a bookmark to the current line.
function add()
  local buffer = buffer
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
  local bit = 2^MARK_BOOKMARK
  if markers % (bit + bit) < bit then add() else remove() end
end

---
-- Clears all bookmarks in the current buffer.
function clear() buffer:marker_delete_all(MARK_BOOKMARK) end

---
-- Goes to the next bookmark in the current buffer.
function goto_next()
  local buffer = buffer
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_next(current_line + 1, 2^MARK_BOOKMARK)
  if line == -1 then line = buffer:marker_next(0, 2^MARK_BOOKMARK) end
  if line >= 0 then _m.textadept.editing.goto_line(line + 1) end
end

---
-- Goes to the previous bookmark in the current buffer.
function goto_prev()
  local buffer = buffer
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = buffer:marker_previous(current_line - 1, 2^MARK_BOOKMARK)
  if line == -1 then
    line = buffer:marker_previous(buffer.line_count, 2^MARK_BOOKMARK)
  end
  if line >= 0 then _m.textadept.editing.goto_line(line + 1) end
end

if buffer then buffer:marker_set_back(MARK_BOOKMARK, MARK_BOOKMARK_COLOR) end
events.connect('view_new',
  function() buffer:marker_set_back(MARK_BOOKMARK, MARK_BOOKMARK_COLOR) end)

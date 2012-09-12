-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Bookmarks for Textadept.
-- @field MARK_BOOKMARK_COLOR (number)
--   The color used for a bookmarked line in `0xBBGGRR` format.
module('_M.textadept.bookmarks')]]

M.MARK_BOOKMARK_COLOR = not NCURSES and 0xB3661A or 0xFF0000

local MARK_BOOKMARK = _SCINTILLA.next_marker_number()

---
-- Toggles a bookmark on the current line.
-- @param on If `true`, adds a bookmark to the current line. If `false`, removes
--   the bookmark on the current line. Otherwise, toggles a bookmark.
-- @name toggle
function M.toggle(on)
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  local f = on and buffer.marker_add or buffer.marker_delete
  if on == nil then -- toggle
    local bit, marker_mask = 2^MARK_BOOKMARK, buffer:marker_get(line)
    if marker_mask % (bit + bit) < bit then f = buffer.marker_add end
  end
  f(buffer, line, MARK_BOOKMARK)
end

---
-- Clears all bookmarks in the current buffer.
-- @name clear
function M.clear()
  buffer:marker_delete_all(MARK_BOOKMARK)
end

-- Uses the given function and parameters to go to the next or previous mark.
-- @param f `buffer.marker_next` when going to the next mark,
--   `buffer.marker_previous` when going to the previous mark.
-- @param increment `1` when going to the next mark, `-1` when going to the
--   previous mark.
-- @param start `0` when going to the next mark, `buffer.line_count` when going
--   to the previous mark.
local function goto_mark(f, increment, wrap_start)
  local buffer = buffer
  local current_line = buffer:line_from_position(buffer.current_pos)
  local line = f(buffer, current_line + increment, 2^MARK_BOOKMARK)
  if line == -1 then line = f(buffer, wrap_start, 2^MARK_BOOKMARK) end
  if line >= 0 then _M.textadept.editing.goto_line(line + 1) end
end

---
-- Goes to the next bookmark in the current buffer.
-- @name goto_next
function M.goto_next()
  goto_mark(buffer.marker_next, 1, 0)
end

---
-- Goes to the previous bookmark in the current buffer.
-- @name goto_prev
function M.goto_prev()
  goto_mark(buffer.marker_previous, -1, buffer.line_count)
end

---
-- Goes to selected bookmark from a filtered list.
-- @name goto_bookmark
function M.goto_bookmark()
  local buffer = buffer
  local markers, line = {}, buffer:marker_next(0, 2^MARK_BOOKMARK)
  if line == -1 then return end
  repeat
    local text = buffer:get_line(line):sub(1, -2) -- chop \n
    markers[#markers + 1] = tostring(line + 1)..': '..text
    line = buffer:marker_next(line + 1, 2^MARK_BOOKMARK)
  until line < 0
  local line = gui.filteredlist(_L['Select Bookmark'], _L['Bookmark'], markers)
  if line then _M.textadept.editing.goto_line(line:match('^%d+')) end
end

local NCURSES_MARK = _SCINTILLA.constants.SC_MARK_CHARACTER + string.byte(' ')
-- Sets view properties for bookmark markers.
local function set_bookmark_properties()
  if NCURSES then buffer:marker_define(MARK_BOOKMARK, NCURSES_MARK) end
  buffer.marker_back[MARK_BOOKMARK] = M.MARK_BOOKMARK_COLOR
end
if buffer then set_bookmark_properties() end
events.connect(events.VIEW_NEW, set_bookmark_properties)

return M

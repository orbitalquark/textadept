-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Bookmarks for Textadept.
-- @field BOOKMARK_COLOR (string)
--   The name of the color in the current theme to mark a bookmarked line with.
module('_M.textadept.bookmarks')]]

M.BOOKMARK_COLOR = not CURSES and 'color.dark_blue' or 'color.blue'

local MARK_BOOKMARK = _SCINTILLA.next_marker_number()

---
-- Toggles the bookmark on the current line unless *on* is given.
-- If *on* is `true` or `false`, adds or removes the bookmark, respectively.
-- @param on Optional flag indicating whether to add or remove a bookmark on the
--   current line. The default value is `nil`, toggling a bookmark.
-- @name toggle
function M.toggle(on)
  local line = buffer:line_from_position(buffer.current_pos)
  local f = on and buffer.marker_add or buffer.marker_delete
  if on == nil then -- toggle
    local bit, marker_mask = 2^MARK_BOOKMARK, buffer:marker_get(line)
    if bit32.band(marker_mask, bit) == 0 then f = buffer.marker_add end
  end
  f(buffer, line, MARK_BOOKMARK)
end

---
-- Clears all bookmarks in the current buffer.
-- @name clear
function M.clear()
  buffer:marker_delete_all(MARK_BOOKMARK)
end

---
-- Prompts the user to select a bookmarked line to go to unless *next* is given.
-- If *next* is `true` or `false`, goes to the next or previous bookmark,
-- respectively.
-- @param next Optional flag indicating whether to go to the next or previous
--   bookmarked line relative to the current line. The default value is `nil`,
--   prompting the user for a bookmarked line to go to.
-- @name goto_mark
function M.goto_mark(next)
  if next == nil then
    local buffer = buffer
    local marks, line = {}, buffer:marker_next(0, 2^MARK_BOOKMARK)
    if line == -1 then return end
    repeat
      local text = buffer:get_line(line):sub(1, -2) -- chop \n
      marks[#marks + 1] = tostring(line + 1)..': '..text
      line = buffer:marker_next(line + 1, 2^MARK_BOOKMARK)
    until line < 0
    local line = gui.filteredlist(_L['Select Bookmark'], _L['Bookmark'], marks)
    if line then _M.textadept.editing.goto_line(line:match('^%d+')) end
  else
    local f = next and buffer.marker_next or buffer.marker_previous
    local current_line = buffer:line_from_position(buffer.current_pos)
    local line = f(buffer, current_line + (next and 1 or -1), 2^MARK_BOOKMARK)
    if line == -1 then
      line = f(buffer, (next and 0 or buffer.line_count), 2^MARK_BOOKMARK)
    end
    if line >= 0 then _M.textadept.editing.goto_line(line + 1) end
  end
end

local CURSES_MARK = buffer.SC_MARK_CHARACTER + string.byte(' ')
-- Sets view properties for bookmark markers.
local function set_bookmark_properties()
  if CURSES then buffer:marker_define(MARK_BOOKMARK, CURSES_MARK) end
  buffer.marker_back[MARK_BOOKMARK] = buffer.property_int[M.BOOKMARK_COLOR]
end
if buffer then set_bookmark_properties() end
events.connect(events.VIEW_NEW, set_bookmark_properties)

return M

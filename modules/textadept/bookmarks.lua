-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Bookmarks for Textadept.
-- @field MARK_BOOKMARK (number)
--   The bookmark mark number.
module('textadept.bookmarks')]]

M.MARK_BOOKMARK = _SCINTILLA.next_marker_number()

---
-- Toggles the bookmark on line number *line* or the current line, unless *on*
-- is given.
-- If *on* is `true` or `false`, adds or removes the bookmark, respectively.
-- @param on Optional flag indicating whether to add or remove a bookmark on
--   line *line* or the current line. The default value is `nil`, toggling a
--   bookmark.
-- @param line Optional line number to add or remove a bookmark on.
-- @name toggle
function M.toggle(on, line)
  line = line or buffer:line_from_position(buffer.current_pos)
  local f = on and buffer.marker_add or buffer.marker_delete
  if on == nil then -- toggle
    local bit, marker_mask = 2^M.MARK_BOOKMARK, buffer:marker_get(line)
    if bit32.band(marker_mask, bit) == 0 then f = buffer.marker_add end
  end
  f(buffer, line, M.MARK_BOOKMARK)
end

---
-- Clears all bookmarks in the current buffer.
-- @name clear
function M.clear() buffer:marker_delete_all(M.MARK_BOOKMARK) end

---
-- Prompts the user to select a bookmarked line to move the caret to the
-- beginning of unless *next* is given.
-- If *next* is `true` or `false`, moves the caret to the beginning of the next
-- or previously bookmarked line, respectively.
-- @param next Optional flag indicating whether to go to the next or previous
--   bookmarked line relative to the current line. The default value is `nil`,
--   prompting the user for a bookmarked line to go to.
-- @name goto_mark
function M.goto_mark(next)
  if next == nil then
    local marks, line = {}, buffer:marker_next(0, 2^M.MARK_BOOKMARK)
    if line == -1 then return end
    while line >= 0 do
      local text = buffer:get_line(line):match('^[^\r\n]*')
      marks[#marks + 1] = tostring(line + 1)..': '..text
      line = buffer:marker_next(line + 1, 2^M.MARK_BOOKMARK)
    end
    local button, i = ui.dialogs.filteredlist{
      title = _L['Select Bookmark'], columns = _L['Bookmark'], items = marks
    }
    if button ~= 1 or not i then return end
    textadept.editing.goto_line(marks[i]:match('^%d+'))
  else
    local f = next and buffer.marker_next or buffer.marker_previous
    local current_line = buffer:line_from_position(buffer.current_pos)
    local line = f(buffer, current_line + (next and 1 or -1), 2^M.MARK_BOOKMARK)
    if line == -1 then
      line = f(buffer, (next and 0 or buffer.line_count), 2^M.MARK_BOOKMARK)
    end
    if line >= 0 then textadept.editing.goto_line(line + 1) end
  end
end

return M

-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Bookmarks for Textadept.
-- @field MARK_BOOKMARK (number)
--   The bookmark mark number.
module('textadept.bookmarks')]]

M.MARK_BOOKMARK = _SCINTILLA.next_marker_number()

---
-- Toggles a bookmark on the current line.
-- @name toggle
function M.toggle()
  local line = buffer:line_from_position(buffer.current_pos)
  local has_mark = buffer:marker_get(line) & 1 << M.MARK_BOOKMARK > 0
  local f = has_mark and buffer.marker_delete or buffer.marker_add
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
  if next ~= nil then
    local f = next and buffer.marker_next or buffer.marker_previous
    local current_line = buffer:line_from_position(buffer.current_pos)
    local line = f(
      buffer, current_line + (next and 1 or -1), 1 << M.MARK_BOOKMARK)
    if line == -1 then
      line = f(buffer, (next and 0 or buffer.line_count), 1 << M.MARK_BOOKMARK)
    end
    if line >= 0 then textadept.editing.goto_line(line) end
    return
  end
  local scan_this_buffer, utf8_list, buffers = true, {}, {}
  -- List the current buffer's marks, and then all other buffers' marks.
  ::rescan::
  for _, buffer in ipairs(_BUFFERS) do
    if not (scan_this_buffer == (buffer == _G.buffer)) then goto continue end
    local filename = buffer.filename or buffer._type or _L['Untitled']
    if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
    local basename = buffer.filename and filename:match('[^/\\]+$') or filename
    local line = buffer:marker_next(0, 1 << M.MARK_BOOKMARK)
    while line >= 0 do
      utf8_list[#utf8_list + 1] = string.format(
        '%s:%d: %s', basename, line + 1,
        buffer:get_line(line):match('^[^\r\n]*'))
      buffers[#buffers + 1] = buffer
      line = buffer:marker_next(line + 1, 1 << M.MARK_BOOKMARK)
    end
    ::continue::
  end
  scan_this_buffer = not scan_this_buffer
  if not scan_this_buffer then goto rescan end
  if #utf8_list == 0 then return end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Select Bookmark'], columns = _L['Bookmark'], items = utf8_list
  }
  if button ~= 1 or not i then return end
  view:goto_buffer(buffers[i])
  textadept.editing.goto_line(utf8_list[i]:match('^[^:]+:(%d+):') - 1)
end

return M

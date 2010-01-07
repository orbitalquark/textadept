-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Multiple line editing for the textadept module.
module('_m.textadept.mlines', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `MARK_MLINE`: The unique integer mark used to identify an MLine marked
--   line.
-- * `MARK_MLINE_COLOR`: The [Scintilla color][scintilla_color] used for an
--   MLine marked line.
--
-- [scintilla_color]: http://scintilla.org/ScintillaDoc.html#colour

-- settings
MARK_MLINE = 2
MARK_MLINE_COLOR = 0x4D994D
-- end settings

-- Contains all MLine marked lines with the column index to edit with respect to
-- for each specific line.
local mlines = {}

local mlines_most_recent

---
-- Adds an mline marker to the current line and stores the line number and
-- column position of the caret in the mlines table.
function add()
  local buffer = buffer
  local column = buffer.column[buffer.current_pos]
  local line = buffer:line_from_position(buffer.current_pos)
  local new_marker = buffer:marker_add(line, MARK_MLINE)
  mlines[line] = { marker = new_marker, start_col = column }
  mlines_most_recent = line
end

---
-- Adds mline markers to all lines from the most recently added line to the
-- current line.
-- The mlines table is updated as in add(), but all column positions are the
-- same as the current column caret position.
function add_multiple()
  local buffer = buffer
  if mlines_most_recent then
    local line = buffer:line_from_position(buffer.current_pos)
    local column = buffer.column[buffer.current_pos]
    local start_line, end_line
    if mlines_most_recent < line then
      start_line, end_line = mlines_most_recent, line
    else
      start_line, end_line = line, mlines_most_recent
    end
    for curr_line = start_line, end_line do
      local new_mark = buffer:marker_add(curr_line, MARK_MLINE)
      mlines[curr_line] = { marker = new_mark, start_col = column }
    end
    mlines_most_recent = line
  end
end

---
-- Clears the mline marker at the current line.
function remove()
  local buffer = buffer
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:marker_delete(line, MARK_MLINE)
  mlines[line] = nil
end

---
-- Clears the mline markers from the line whose marker was most recently
-- removed (or the line where a marker was most recently added to) to the
-- current line.
function remove_multiple()
  local buffer = buffer
  if mlines_most_recent then
    local line = buffer:line_from_position(buffer.current_pos)
    local start_line, end_line
    if mlines_most_recent < line then
      start_line, end_line = mlines_most_recent, line
    else
      start_line, end_line = line, mlines_most_recent
    end
    for curr_line = start_line, end_line do
      buffer:marker_delete(curr_line, MARK_MLINE)
      mlines[curr_line] = nil
    end
    mlines_most_recent = line
  end
end

---
-- Clears all mline markers and the mlines table.
function clear()
  local buffer = buffer
  buffer:marker_delete_all(MARK_MLINE)
  mlines = {}
  mlines_most_recent = nil
end

---
-- Applies changes made in the current line relative to the caret column
-- position stored initially to all lines with mline markers in relation to
-- their initial column positions.
function update()
  local buffer = buffer
  local curr_line = buffer:line_from_position(buffer.current_pos)
  local curr_col = buffer.column[buffer.current_pos]
  buffer:begin_undo_action()
  if mlines[curr_line] then
    local s = buffer:find_column(curr_line, mlines[curr_line].start_col)
    local e = buffer:find_column(curr_line, curr_col)
    local delta = e - s
    local txt = ''
    if delta > 0 then txt = buffer:text_range(s, e) end
    for line_num, item in pairs(mlines) do
      if line_num ~= curr_line then
        local next_pos = buffer:find_column(line_num, item.start_col)
        if delta < 0 then
          buffer.current_pos, buffer.anchor = next_pos, next_pos
          for i = 1, math.abs(delta) do buffer:delete_back() end
          item.start_col = buffer.column[buffer.current_pos]
        else
          buffer:insert_text(next_pos, txt)
          item.start_col = item.start_col + #txt
        end
      end
    end
    if delta < 0 then
      local pos = buffer:position_from_line(curr_line) + curr_col
      buffer:goto_pos(pos)
    end
    mlines[curr_line].start_col = curr_col
  end
  buffer:end_undo_action()
end

if buffer then buffer:marker_set_back(MARK_MLINE, MARK_MLINE_COLOR) end
textadept.events.add_handler('view_new',
  function() buffer:marker_set_back(MARK_MLINE, MARK_MLINE_COLOR) end)

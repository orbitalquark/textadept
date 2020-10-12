-- Copyright 2019-2020 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Records buffer positions within Textadept views over time and allows for
-- navigating through that history.
--
-- This module listens for text edit events and buffer switch events. Each time
-- an insertion or deletion occurs, its location is recorded in the current
-- view's location history. If the edit is close enough to the previous record,
-- the previous record is amended. Each time a buffer switch occurs, the before
-- and after locations are also recorded.
-- @field minimum_line_distance (number)
--   The minimum number of lines between distinct history records.
--   The default value is `3`.
-- @field maximum_history_size (number)
--   The maximum number of history records to keep per view.
--   The default value is `100`.
module('textadept.history')]]

M.minimum_line_distance = 3
M.maximum_history_size = 100

-- Map of views to their history records.
-- Each record has a `pos` field that points to the current history position in
-- the associated view.
-- @class table
-- @name view_history
local view_history = setmetatable({}, {__index = function(t, view)
  t[view] = {pos = 0}
  return t[view]
end})

-- Listens for text insertion and deletion events and records their locations.
events.connect(events.MODIFIED, function(position, mod_type, text, length)
  local buffer = buffer
  -- Only interested in text insertion or deletion.
  if mod_type & buffer.MOD_INSERTTEXT > 0 then
    if length == buffer.length then return end -- ignore file loading
    position = position + length
  elseif mod_type & buffer.MOD_DELETETEXT > 0 then
    if buffer.length == 0 then return end -- ignore replacing buffer contents
  else
    return
  end
  -- Ignore undo/redo.
  if mod_type & (buffer.PERFORMED_UNDO | buffer.PERFORMED_REDO) > 0 then
    return
  end
  M.record(nil, buffer:line_from_position(position), buffer.column[position])
end)

-- Do not record positions during buffer switches when jumping backwards or
-- forwards.
local jumping = false

-- Jumps to the current position in the current view's history after adjusting
-- that position backwards or forwards.
local function goto_record()
  jumping = true
  local history = view_history[view]
  local record = history[history.pos]
  local filename, line, column = record.filename, record.line, record.column
  if lfs.attributes(filename) then
    io.open_file(filename)
  else
    for _, buffer in ipairs(_BUFFERS) do
      if buffer.filename == filename or buffer._type == filename or
         not buffer.filename and not buffer._type and
         filename == _L['Untitled'] then
        view:goto_buffer(buffer)
        break
      end
    end
  end
  buffer:goto_pos(buffer:find_column(line, column))
  jumping = false
end

---
-- Navigates backwards through the current view's history.
-- @name back
function M.back()
  local history = view_history[view]
  if #history == 0 then return end -- nothing to do
  local record = history[history.pos]
  local line = buffer:line_from_position(buffer.current_pos)
  if buffer.filename ~= record.filename or
     math.abs(record.line - line) > M.minimum_line_distance then
    -- When navigated away from the most recent record, and if that record is
    -- not a soft record, jump back to it first, then navigate backwards.
    if not record.soft then goto_record() return end
    -- Otherwise, update the soft record with the current position and
    -- immediately navigate backwards.
    M.record(record.filename, nil, nil, record.soft)
  end
  if history.pos > 1 then history.pos = history.pos - 1 end
  goto_record()
end

---
-- Navigates forwards through the current view's history.
-- @name forward
function M.forward()
  local history = view_history[view]
  if history.pos == #history then return end -- nothing to do
  local record = history[history.pos]
  if record.soft then M.record(record.filename, nil, nil, record.soft) end
  history.pos = history.pos + 1
  goto_record()
end

---
-- Records the given location in the current view's history.
-- @param filename Optional string filename, buffer type, or identifier of the
--   buffer to store. If `nil`, uses the current buffer.
-- @param line Optional Integer line number to store. If `nil`, uses the current
--   line.
-- @param column Optional integer column number on line *line* to store. If
--   `nil`, uses the current column.
-- @param soft Optional flag that indicates whether or not this record should be
--   skipped when navigating backward towards it, and updated when navigating
--   away from it. The default value is `false`.
-- @name record
function M.record(filename, line, column, soft)
  if not assert_type(filename, 'string/nil', 1) then
    filename = buffer.filename or buffer._type or _L['Untitled']
  end
  if not assert_type(line, 'number/nil', 2) then
    line = buffer:line_from_position(buffer.current_pos)
  end
  if not assert_type(column, 'number/nil', 3) then
    column = buffer.column[buffer.current_pos]
  end
  local history = view_history[view]
  if #history > 0 then
    local record = history[history.pos]
    if filename == record.filename and
       (math.abs(record.line - line) <= M.minimum_line_distance or
         record.soft) then
      -- If the most recent record is close enough (distance-wise), or if that
      -- record is a soft record, update it instead of recording a new one.
      record.line, record.column = line, column
      record.soft = soft and record.soft
      return
    end
  end
  if history.pos < #history then
    for i = history.pos + 1, #history do history[i] = nil end -- clear forward
  end
  history[#history + 1] = {
    filename = filename, line = line, column = column, soft = soft
  }
  if #history > M.maximum_history_size then table.remove(history, 1) end
  history.pos = #history
end

-- Softly record positions when switching between buffers.
local function record_switch()
  if not jumping then M.record(nil, nil, nil, true) end
end
events.connect(events.BUFFER_BEFORE_SWITCH, record_switch)
events.connect(events.BUFFER_AFTER_SWITCH, record_switch)
events.connect(events.FILE_OPENED, record_switch)

---
-- Clears all view history.
-- @name clear
function M.clear()
  for view in pairs(view_history) do view_history[view] = {pos = 0} end
end

return M
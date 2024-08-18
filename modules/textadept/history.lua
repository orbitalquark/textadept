-- Copyright 2019-2024 Mitchell. See LICENSE.

--- Records buffer positions within Textadept views over time and allows for navigating through
-- that history.
--
-- This module listens for text edit events and buffer switch events. Each time an insertion
-- or deletion occurs, its location is recorded in the current view's location history. If the
-- edit is close enough to the previous record, the previous record is amended. Each time a
-- buffer switch occurs, the before and after locations are also recorded.
-- @module textadept.history
local M = {}

--- The minimum number of lines between distinct history records.
-- The default value is `3`.
M.minimum_line_distance = 3

--- The maximum number of history records to keep per view.
-- The default value is `100`.
M.maximum_history_size = 100

--- Map of views to their history records.
-- Each record has a `pos` field that points to the current history position in the associated view.
-- @table view_history
-- @local
local view_history = setmetatable({}, {
	__index = function(t, view)
		t[view] = {pos = 0}
		return t[view]
	end
})

local INSERT, DELETE = buffer.MOD_INSERTTEXT, buffer.MOD_DELETETEXT
local UNDO, REDO = buffer.PERFORMED_UNDO, buffer.PERFORMED_REDO
-- Listens for text insertion and deletion events and records their locations.
events.connect(events.MODIFIED, function(position, mod, text, length)
	if mod & (INSERT | DELETE) == 0 or buffer.length == (mod & INSERT > 0 and length or 0) then
		return -- ignore non-insertion/deletion, file loading, and replacing buffer contents
	end
	if mod & INSERT > 0 then position = position + length end
	if mod & (UNDO | REDO) > 0 then return end -- ignore undo/redo
	local line, column = buffer:line_from_position(position), buffer.column[position]
	if buffer.selections > 1 and line ~= buffer:line_from_position(buffer.current_pos) then return end
	M.record(nil, line, column, buffer._type ~= nil)
end)

-- Do not record positions during buffer switches when jumping backwards or forwards.
local jumping = false

--- Jumps to the given record in the current view's history.
-- @param record History record to jump to.
local function jump(record)
	jumping = true
	local filename = record.filename
	if lfs.attributes(filename) then
		io.open_file(filename)
	else
		for _, buffer in ipairs(_BUFFERS) do
			if buffer.filename == filename or buffer._type == filename or
				(not buffer.filename and not buffer._type and filename == _L['Untitled']) then
				view:goto_buffer(buffer)
				break
			end
		end
	end
	buffer:goto_pos(buffer:find_column(record.line, record.column))
	jumping = false
end

--- Navigates backwards through the current view's history.
function M.back()
	local history = view_history[view]
	if #history == 0 then return end -- nothing to do
	local record = history[history.pos]
	local line = buffer:line_from_position(buffer.current_pos)
	if buffer.filename ~= record.filename and buffer._type ~= record.filename or
		math.abs(record.line - line) > M.minimum_line_distance then
		-- When navigated away from the most recent record, and if that record is not a soft record,
		-- jump back to it first, then navigate backwards.
		if not record.soft then
			jump(record)
			return
		end
		-- Otherwise, update the soft record with the current position and immediately navigate
		-- backwards.
		M.record(record.filename, nil, nil, record.soft)
	end
	if history.pos > 1 then history.pos = history.pos - 1 end
	jump(history[history.pos])
end

--- Navigates forwards through the current view's history.
function M.forward()
	local history = view_history[view]
	if history.pos == #history then return end -- nothing to do
	local record = history[history.pos]
	if record.soft then M.record(record.filename, nil, nil, record.soft) end
	history.pos = history.pos + 1
	jump(history[history.pos])
end

--- Records the given location in the current view's history.
-- @param[opt] filename Optional string filename, buffer type, or identifier of the buffer to
--	store. If `nil`, uses the current buffer.
-- @param[optchain] line Optional Integer line number to store. If `nil`, uses the current line.
-- @param[optchain] column Optional integer column number on line *line* to store. If `nil`,
--	uses the current column.
-- @param[optchain=false] soft Optional flag that indicates whether or not this record should
--	be skipped when navigating backward towards it, and updated when navigating away from it.
function M.record(filename, line, column, soft)
	if not assert_type(filename, 'string/nil', 1) then
		filename = buffer.filename or buffer._type or _L['Untitled']
	end
	if not assert_type(line, 'number/nil', 2) then
		line = buffer:line_from_position(buffer.current_pos)
	end
	if not assert_type(column, 'number/nil', 3) then column = buffer.column[buffer.current_pos] end
	local history = view_history[view]
	if #history > 0 then
		local record = history[history.pos]
		if filename == record.filename and
			(math.abs(record.line - line) <= M.minimum_line_distance or record.soft) then
			-- If the most recent record is close enough (distance-wise), or if that record is a soft
			-- record, update it instead of recording a new one.
			record.line, record.column = line, column
			record.soft = soft and record.soft
			return
		end
	end
	if history.pos < #history then
		for i = history.pos + 1, #history do history[i] = nil end -- clear forward
	end
	history[#history + 1] = {filename = filename, line = line, column = column, soft = soft}
	if #history > M.maximum_history_size then table.remove(history, 1) end
	history.pos = #history
end

--- Softly record positions when switching between buffers.
local function record_switch() if not jumping then M.record(nil, nil, nil, true) end end
events.connect(events.BUFFER_BEFORE_SWITCH, record_switch)
events.connect(events.BUFFER_AFTER_SWITCH, record_switch)
events.connect(events.FILE_OPENED, record_switch)

--- Clears all view history.
function M.clear() for view in pairs(view_history) do view_history[view] = {pos = 0} end end

return M

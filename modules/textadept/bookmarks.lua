-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Bookmarks for Textadept.
-- @module textadept.bookmarks
local M = {}

--- The bookmark mark number.
M.MARK_BOOKMARK = view.new_marker_number()

--- Toggles a bookmark on the current line.
function M.toggle()
	local line = buffer:line_from_position(buffer.current_pos)
	local has_mark = buffer:marker_get(line) & 1 << M.MARK_BOOKMARK - 1 > 0
	local f = has_mark and buffer.marker_delete or buffer.marker_add
	f(buffer, line, M.MARK_BOOKMARK)
end

--- Clears all bookmarks in the current buffer.
function M.clear() buffer:marker_delete_all(M.MARK_BOOKMARK) end

--- Returns an iterator for all bookmarks in the given buffer.
local function bookmarks(buffer)
	return function(buffer, line)
		line = buffer:marker_next(line + 1, 1 << M.MARK_BOOKMARK - 1)
		return line >= 1 and line or nil
	end, buffer, 0
end

--- Prompts the user to select a bookmarked line to move the caret to the beginning of unless
-- *next* is given.
-- If *next* is `true` or `false`, moves the caret to the beginning of the next or previously
-- bookmarked line, respectively.
-- @param[opt] next Optional flag indicating whether to go to the next or previous bookmarked line
--	relative to the current line. If `nil`, the user is prompted for a bookmarked line to go to.
function M.goto_mark(next)
	if next ~= nil then
		local f = next and buffer.marker_next or buffer.marker_previous
		local line = buffer:line_from_position(buffer.current_pos)
		local BOOKMARK_BIT = 1 << M.MARK_BOOKMARK - 1
		line = f(buffer, line + (next and 1 or -1), BOOKMARK_BIT)
		if line == -1 then line = f(buffer, (next and 1 or buffer.line_count), BOOKMARK_BIT) end
		if line >= 1 then textadept.editing.goto_line(line) end
		return
	end
	-- List the current buffer's marks, and then all other buffers' marks.
	local scan_this_buffer, utf8_list, buffers = true, {}, {}
	::rescan::
	for _, buffer in ipairs(_BUFFERS) do
		if scan_this_buffer ~= (buffer == _G.buffer) then goto continue end
		local filename = buffer.filename or buffer._type or _L['Untitled']
		if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
		local basename = buffer.filename and filename:match('[^/\\]+$') or filename
		for line in bookmarks(buffer) do
			utf8_list[#utf8_list + 1] = string.format('%s:%d: %s', basename, line,
				buffer:get_line(line):match('^[^\r\n]*'))
			buffers[#buffers + 1] = buffer
		end
		::continue::
	end
	scan_this_buffer = not scan_this_buffer
	if not scan_this_buffer then goto rescan end
	if #utf8_list == 0 then return end
	local i = ui.dialogs.list{title = _L['Select Bookmark'], items = utf8_list}
	if not i then return end
	view:goto_buffer(buffers[i])
	textadept.editing.goto_line(tonumber(utf8_list[i]:match('^[^:]+:(%d+):')))
end

local lines = {}
-- Save and restore bookmarks when replacing buffer text (e.g. buffer:reload(),
-- textadept.editing.filter_through()).
events.connect(events.BUFFER_BEFORE_REPLACE_TEXT,
	function() for line in bookmarks(buffer) do lines[#lines + 1] = line end end)
events.connect(events.BUFFER_AFTER_REPLACE_TEXT, function()
	for _, line in ipairs(lines) do buffer:marker_add(line, M.MARK_BOOKMARK) end
	lines = {} -- clear
end)

return M

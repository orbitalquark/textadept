-- Copyright 2007-2026 Mitchell. See LICENSE.

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

--- Iterator function that returns a buffer's next bookmark after a given line.
-- @usage for line in next_bookmark, buffer, 0 do ... end
local function next_bookmark(buffer, line)
	line = buffer:marker_next(line + 1, 1 << M.MARK_BOOKMARK - 1)
	return line >= 1 and line or nil
end

--- Adds all bookmarks in a buffer to the given lists.
-- @param buffer Buffer to add bookmarks from.
-- @param utf8_list List of bookmarks to show the user.
-- @param buffers List of buffers associated with bookmarks in *utf8_list*.
local function add_bookmarks(buffer, utf8_list, buffers)
	local filename = buffer.filename and buffer.filename:iconv('UTF-8', _CHARSET) or buffer._type or
		_L['Untitled']
	local basename = buffer.filename and filename:match('[^/\\]+$') or filename
	for line in next_bookmark, buffer, 0 do
		utf8_list[#utf8_list + 1] = string.format('%s:%d: %s', basename, line,
			buffer:get_line(line):match('^[^\r\n]*'))
		buffers[#buffers + 1] = buffer
	end
end

--- Jumps to a the beginning of a bookmarked line.
-- @param[opt] next Jump to the next bookmarked line in the current buffer instead of the
--	previous one. If `nil`, the user is prompted to select bookmarked line to jump to,
--	which includes bookmarks from all open buffers.
-- @usage textadept.bookmarks.goto_mark(true) -- jump to the next bookmark
-- @usage textadept.bookmarks.goto_mark(false) -- jump to the previous bookmark
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
	local utf8_list, buffers = {}, {}
	add_bookmarks(buffer, utf8_list, buffers)
	for _, buffer in ipairs(_BUFFERS) do
		if buffer ~= _G.buffer then add_bookmarks(buffer, utf8_list, buffers) end
	end
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
	function() for line in next_bookmark, buffer, 0 do lines[#lines + 1] = line end end)
events.connect(events.BUFFER_AFTER_REPLACE_TEXT, function()
	for _, line in ipairs(lines) do buffer:marker_add(line, M.MARK_BOOKMARK) end
	lines = {} -- clear
end)

return M

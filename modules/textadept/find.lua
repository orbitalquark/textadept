-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Textadept's Find & Replace pane.
-- @module ui.find
local M = ui.find

--- The text in the "Find" entry.
-- @field find_entry_text

--- The text in the "Replace" entry.
-- When searching for text in a directory of files, this is the current file and directory filter.
-- @field replace_entry_text

--- Match search text case sensitively.
-- The default value is `false`.
-- @field match_case

--- Match search text only when it is surrounded by non-word characters in searches.
-- The default value is `false`.
-- @field whole_word

--- Interpret search text as a Regular Expression.
-- The default value is `false`.
-- @field regex

--- Find search text in a directory of files.
-- The default value is `false`.
-- @field in_files

--- Find search text incrementally as it is typed.
-- The default value is `false`.
-- @field incremental

--- The font to use in the "Find" and "Replace" entries in "name size" format. (Write-only)
-- The default value is system-dependent.
-- @field entry_font

--- Whether or not the Find & Replace pane is active.
-- @field active

--- The text of the "Find" label. (Write-only)
-- This is primarily used for localization.
M.find_label_text = _L['Find:']:gsub('&', '')

--- The text of the "Replace" label. (Write-only)
-- This is primarily used for localization.
M.replace_label_text = _L['Replace:']:gsub('&', '')

--- The text of the "Find Next" button. (Write-only)
-- This is primarily used for localization.
M.find_next_button_text = not CURSES and _L['Find Next'] or _L['[Next]']

--- The text of the "Find Prev" button. (Write-only)
-- This is primarily used for localization.
M.find_prev_button_text = not CURSES and _L['Find Prev'] or _L['[Prev]']

--- The text of the "Replace" button. (Write-only)
-- This is primarily used for localization.
M.replace_button_text = not CURSES and _L['Replace'] or _L['[Replace]']

--- The text of the "Replace All" button. (Write-only)
-- This is primarily used for localization.
M.replace_all_button_text = not CURSES and _L['Replace All'] or _L['[All]']

--- The text of the "Match case" label. (Write-only)
-- This is primarily used for localization.
M.match_case_label_text = not CURSES and _L['Match case'] or _L['Case(F1)']

--- The text of the "Whole word" label. (Write-only)
-- This is primarily used for localization.
M.whole_word_label_text = not CURSES and _L['Whole word'] or _L['Word(F2)']

--- The text of the "Regex" label. (Write-only)
-- This is primarily used for localization.
M.regex_label_text = not CURSES and _L['Regex'] or _L['Regex(F3)']

--- The text of the "In files" label. (Write-only)
-- This is primarily used for localization.
M.in_files_label_text = not CURSES and _L['In files'] or _L['Files(F4)']

--- Whether or not to highlight all occurrences of found text in the current buffer.
-- The default value is `false`.
M.highlight_all_matches = false

--- Whether to show filenames in the find in files search progressbar.
-- This can be useful for determining whether or not custom filters are working as expected.
-- Showing filenames can slow down searches on computers with really fast SSDs.
-- The default value is `false`.
M.show_filenames_in_progressbar = false

--- The find results highlight indicator number.
M.INDIC_FIND = view.new_indic_number()

-- Events.
local find_events = {'find_result_found', 'find_wrapped'}
for _, v in ipairs(find_events) do events[v:upper()] = v end

--- Emitted when a result is found. It is selected and has been scrolled into view.
-- Arguments:
--
-- - *find_text*: The text originally searched for.
-- - *wrapped*: Whether or not the result found is after a text search wrapped.
-- @field _G.events.FIND_RESULT_FOUND

--- Emitted when a text search wraps (passes through the beginning of the buffer), either from
-- bottom to top (when searching for a next occurrence), or from top to bottom (when searching
-- for a previous occurrence).
-- This is useful for implementing a more visual or audible notice when a search wraps in
-- addition to the statusbar message.
-- @field _G.events.FIND_WRAPPED (string)

--- Map of directory paths to filters used when finding in files.
-- This table is updated when the user manually specifies a filter in the "Filter" entry during
-- an "In files" search.
M.find_in_files_filters = {}

-- When finding in files, note the current view since results are shown in a split view. Jumping
-- between results should be done in the original view.
local preferred_view

-- Keep track of find text and found text so that "replace all" works as expected during a find
-- session ("replace all" with selected text normally does "replace in selection"). Also track
-- find text for incremental find (if text has changed, the user is still typing; if text is
-- the same, the user clicked "Find Next" or "Find Prev"). Keep track of repl_text for non-"In
-- files" in order to restore it from filter text as necessary.
local find_text, found_text, repl_text = nil, nil, ui.find.replace_entry_text

--- Returns a reasonable initial directory for use with Find in Files.
local function ff_dir()
	return io.get_project_root() or (buffer.filename or ''):match('^(.+)[/\\]') or lfs.currentdir()
end

local orig_focus = M.focus
--- Displays and focuses the Find & Replace Pane.
-- @param[opt] options Optional table of `ui.find` field options to initially set.
function M.focus(options)
	local already_in_files = M.in_files
	if not assert_type(options, 'table/nil', 1) then options = {} end
	if not options.in_files then options.in_files = false end -- reset
	if not options.incremental then options.incremental = false end -- reset
	for k, v in pairs(options) do M[k] = v end
	M.replace_label_text = (not M.in_files and _L['Replace:'] or _L['Filter:']):gsub('&', '')
	if M.in_files then
		if not already_in_files then repl_text = M.replace_entry_text end -- save
		local filter = M.find_in_files_filters[ff_dir()] or lfs.default_filter
		M.replace_entry_text = type(filter) == 'string' and filter or table.concat(filter, ',')
	elseif M.replace_entry_text ~= repl_text then
		M.replace_entry_text = repl_text -- restore
	end
	orig_focus()
end

--- Returns a bit-mask of search flags to use in Scintilla search functions based on the checkboxes
-- in the find box.
-- The "Find in Files" flag is unused by Scintilla, but used by Textadept.
-- @return search flag bit-mask
local function get_flags()
	return (M.match_case and buffer.FIND_MATCHCASE or 0) |
		(M.whole_word and buffer.FIND_WHOLEWORD or 0) | (M.regex and buffer.FIND_REGEXP or 0)
end

--- Returns whether or not the given buffer is a files found buffer.
local function is_ff_buf(buf) return buf._type == _L['[Files Found Buffer]'] end

--- Clears highlighted match indicators.
local function clear_highlighted_matches()
	buffer.indicator_current = M.INDIC_FIND
	buffer:indicator_clear_range(1, buffer.length)
end
events.connect(events.KEYPRESS, function(key)
	if key ~= 'esc' or is_ff_buf(buffer) then return end
	clear_highlighted_matches()
end, 1)

local incremental_orig_pos
--- Finds and selects text in the current buffer.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a bit-mask of 4 flags: `buffer.FIND_MATCHCASE`,
--	`buffer.FIND_WHOLEWORD`, `buffer.FIND_REGEXP`, and 1 << 31 (in files), each joined with
--	binary OR. If `nil`, this is determined based on the checkboxes in the find box.
-- @param no_wrap Flag indicating whether or not the search will not wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped for displaying
--	useful statusbar information. This flag is used and set internally, and should not be
--	set otherwise.
-- @return position of the found text or `-1`
local function find(text, next, flags, no_wrap, wrapped)
	if not flags then flags = get_flags() end
	if not is_ff_buf(buffer) then clear_highlighted_matches() end

	if M.incremental and not wrapped then
		local pos = buffer.current_pos
		if type(M.incremental) == 'boolean' then
			-- Starting a new incremental search, anchor at current pos.
			M.incremental, incremental_orig_pos = pos, pos
		elseif text == find_text and found_text ~= '' then
			-- "Find Next" or "Find Prev" clicked, anchor at new current pos.
			M.incremental = buffer:position_relative(pos, next and 1 or -1)
		end
		buffer:set_empty_selection(M.incremental or 1)
	elseif not M.incremental then
		incremental_orig_pos = nil
	end

	-- If text is selected, assume it is from the current search and move the caret appropriately
	-- for the next search.
	buffer:set_empty_selection(next and buffer.selection_end or buffer.selection_start)
	if not M.incremental and M.regex and find_text == text and found_text == '' and next and
		not wrapped then buffer:set_empty_selection(buffer.current_pos + (next and 1 or -1)) end

	-- Scintilla search.
	buffer:search_anchor()
	local f = next and buffer.search_next or buffer.search_prev
	local pos = f(buffer, flags, text)
	if pos ~= -1 then
		view:ensure_visible_enforce_policy(buffer:line_from_position(pos))
		view:scroll_range(buffer.anchor, buffer.current_pos)
		events.emit(events.FIND_RESULT_FOUND, text, wrapped)
	end
	-- Track find text and found text for "replace all" and incremental find.
	find_text, found_text = text, buffer:get_sel_text()
	repl_text = ui.find.replace_entry_text -- save for ui.find.focus()

	-- If nothing was found, wrap the search.
	if pos == -1 and not no_wrap then
		local anchor = buffer.anchor
		buffer:set_empty_selection(next and 1 or buffer.length + 1)
		events.emit(events.FIND_WRAPPED)
		pos = find(text, next, flags, true, true)
		if pos == -1 then
			ui.statusbar_text = _L['No results found']
			buffer:set_empty_selection(incremental_orig_pos or anchor)
		end
	end

	return pos
end

--- Prompts the user for a directory to search in for files that match search text and search
-- options, and prints the results to a buffer titled "Files Found", highlighting found text.
-- A filter determines which files to search in, with the default filter being
-- `ui.find.find_in_files_filters[dir]` (if it exists) or `lfs.default_filter`.
local function find_in_files()
	local dir = ui.dialogs.open{title = _L['Select Directory'], only_dirs = true, dir = ff_dir()}
	if not dir then return end
	if M.replace_entry_text ~= repl_text then
		-- Update stored filter.
		local t = {}
		for patt in M.replace_entry_text:gmatch('[^,]+') do t[#t + 1] = patt end
		M.find_in_files_filters[dir], M.find_in_files_filters[ff_dir()] = t, t
	end
	local filter = M.find_in_files_filters[dir] or lfs.default_filter
	if not CURSES and ui.find.active then
		ui.find.in_files = false
		orig_focus() -- attempt to hide
		ui.update() -- register widget focus/visibility changes
		if ui.find.active then orig_focus() end -- hide
	end

	if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
	local function print(message) ui.print_to(_L['[Files Found Buffer]'], message) end
	print(_L['Find:']:gsub('[_&]', '') .. ' ' .. M.find_entry_text)
	print(_L['Directory:'] .. ' ' .. dir)
	print(_L['Filter:']:gsub('[_&]', '') .. ' ' ..
		(type(filter) == 'string' and filter or table.concat(filter, ',')))

	-- Determine which files to search.
	local filenames, utf8_filenames, iterator = {}, {}, lfs.walk(dir, filter)
	local stopped = ui.dialogs.progress{
		title = string.format('%s\n%s...', _L['Scanning for files to search in'], dir),
		work = function()
			for i = 1, 1000 do -- scan filenames (not contents) in blocks for performance
				local filename = iterator()
				if not filename then return nil end -- done
				filenames[#filenames + 1] = filename
				utf8_filenames[#utf8_filenames + 1] = filename:sub(#dir + 2):iconv('UTF-8', _CHARSET)
			end
			return -1 -- indeterminate
		end
	}
	if stopped then
		print(_L['Find in Files aborted'])
		print() -- blank line
		return
	end

	-- Perform the search in a temporary buffer and print results.
	local ff_buffer, buffer = buffer, buffer.new()
	view:goto_buffer(ff_buffer)
	buffer.code_page = 0 -- default is UTF-8
	buffer.search_flags = get_flags()
	local text, i, found, show_names = M.find_entry_text, 1, false, M.show_filenames_in_progressbar
	stopped = ui.dialogs.progress{
		title = string.format('%s: %s', _L['Find in Files']:gsub('[_&]', ''), text),
		text = show_names and utf8_filenames[i], work = function()
			if i > #filenames then return nil end
			local f<close> = io.open(filenames[i], 'rb')
			buffer:target_whole_document()
			buffer:replace_target(f:read('a'))
			local binary = nil -- determine lazily for performance reasons
			buffer:target_whole_document()
			while buffer:search_in_target(text) ~= -1 do
				found = true
				if binary == nil then binary = buffer:text_range(1, 65536):find('\0') end
				if binary then
					print(string.format('%s:1:%s', utf8_filenames[i], _L['Binary file matches.']))
					break
				end
				local line_num = buffer:line_from_position(buffer.target_start)
				local line = buffer:get_line(line_num):match('^[^\r\n]*')
				print(string.format('%s:%d:%s', utf8_filenames[i], line_num, line))
				local pos = ff_buffer.line_end_position[ff_buffer.line_count - 1] - #line +
					buffer.target_start - buffer:position_from_line(line_num)
				ff_buffer.indicator_current = M.INDIC_FIND
				ff_buffer:indicator_fill_range(pos, buffer.target_end - buffer.target_start)
				buffer:set_target_range(buffer.target_end, buffer.length + 1)
			end
			buffer:clear_all()
			buffer:empty_undo_buffer()
			view:scroll_caret() -- [Files Found Buffer]
			i = i + 1
			return (i - 1) * 100 / #filenames, show_names and utf8_filenames[i] or nil
		end
	}
	buffer:close(true) -- temporary buffer
	local status = stopped and _L['Find in Files aborted'] or not found and _L['No results found']
	if status then print(status) end
	print() -- blank line
end

-- Handle "Find Next" or "Find Prev" click.
events.connect(events.FIND, function(text, next)
	if text == '' then return end
	if not M.in_files then
		find(text, next)
	else
		find_in_files()
	end
end)

-- Search incrementally as find text changes.
events.connect(events.FIND_TEXT_CHANGED,
	function() if M.incremental then return ui.find.find_next() end end)

-- Count and optionally highlight all found occurrences.
events.connect(events.FIND_RESULT_FOUND, function(text, wrapped)
	local count, current = 0, 1
	buffer.search_flags = get_flags()
	buffer:target_whole_document()
	while buffer:search_in_target(text) ~= -1 do
		local s, e = buffer.target_start, buffer.target_end
		if s == e then e = e + 1 end -- prevent loops for zero-length results
		if M.highlight_all_matches and e - s > 1 and not is_ff_buf(buffer) then
			buffer:indicator_fill_range(s, e - s)
		end
		count = count + 1
		if s == buffer.current_pos then current = count end
		if e > buffer.length then break end
		buffer:set_target_range(e, buffer.length + 1)
	end
	local message = string.format('%s %d/%d', _L['Match'], current, count)
	if wrapped then message = string.format('%s (%s)', message, _L['Search wrapped']) end
	ui.statusbar_text = message
	-- For regex searches, `buffer.tag` was clobbered. It needs to be filled in again for any
	-- subsequent replace operations that need it.
	if ui.find.regex then
		buffer:set_target_range(buffer.selection_start, buffer.length + 1)
		buffer:search_in_target(text)
	end
end)

-- Notify via statusbar if a search wrapped.
events.connect(events.FIND_WRAPPED, function() ui.statusbar_text = _L['Search wrapped'] end)

local P, V, C, upper, lower = lpeg.P, lpeg.V, lpeg.C, string.upper, string.lower
local esc = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t', v = '\v'}
local re_patt = lpeg.Cs(P{
	(V('text') + V('u') + V('l') + V('U') + V('L') + V('esc'))^1,
	text = (1 - '\\' * lpeg.S('uUlLEbfnrtv'))^1, --
	u = '\\u' * C(1) / upper, l = '\\l' * C(1) / lower,
	U = P('\\U') / '' * (V('text') / upper + V('u') + V('l'))^0 * V('E')^-1,
	L = P('\\L') / '' * (V('text') / lower + V('u') + V('l'))^0 * V('E')^-1, --
	E = P('\\E') / '', esc = '\\' * C(1) / esc
})
--- Returns string *text* with the following sequences unescaped:
--
-- - "\uXXXX" sequences replaced with the equivalent UTF-8 character.
-- - "\d" sequences replaced with the text of capture number *d* from the regular expression
--	(or the entire match for *d* = 0).
-- - "\U" and "\L" sequences convert everything up to the next "\U", "\L", or "\E" to uppercase
--	and lowercase, respectively.
-- - "\u" and "\l" sequences convert the next character to uppercase and lowercase, respectively.
--	They may appear within "\U" and "\L" constructs.
-- @param text String text to unescape.
-- @return unescaped text
local function unescape(text)
	text = text:gsub('%f[\\]\\u(%x%x%x%x)', function(code) return utf8.char(tonumber(code, 16)) end)
		:gsub('\\0', buffer.target_text):gsub('\\(%d)', buffer.tag)
	return re_patt:match(text) or text
end

-- Replaces found (selected) text.
events.connect(events.REPLACE, function(text)
	if buffer.selection_empty then return end
	buffer:target_from_selection()
	buffer:replace_target(not M.regex and text or unescape(text))
	buffer:set_sel(buffer.target_start, buffer.target_end)
end)

local INDIC_REPLACE = view.new_indic_number()
-- Replaces all found text in the current buffer (ignores "Find in Files").
-- If any text is selected (other than text just found), only found text in that selection
-- is replaced.
events.connect(events.REPLACE_ALL, function(ftext, rtext)
	if ftext == '' then return end
	repl_text = rtext -- save for ui.find.focus()
	local count = 0
	local replace_in_sel = not buffer.selection_empty and
		(ftext ~= find_text or buffer:get_sel_text() ~= found_text)
	if replace_in_sel then buffer.indicator_current = INDIC_REPLACE end

	for i = 1, buffer.selections do
		local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
		if replace_in_sel then buffer:indicator_fill_range(e, 1) end
		local EOF = replace_in_sel and e == buffer.length + 1 -- no indicator at EOF

		-- Perform the search and replace.
		buffer:begin_undo_action()
		buffer.search_flags = get_flags()
		buffer:set_target_range(not replace_in_sel and 1 or s, buffer.length + 1)
		while buffer:search_in_target(ftext) ~= -1 and
			(not replace_in_sel or buffer.target_end <= buffer:indicator_end(INDIC_REPLACE, s) or EOF) do
			local offset = buffer.target_start ~= buffer.target_end and 0 or 1 -- for preventing loops
			if M.regex and ftext:find('^^') and offset == 0 then offset = 1 end -- avoid extra matches
			buffer:replace_target(not M.regex and rtext or unescape(rtext))
			count = count + 1
			if buffer.target_end + offset > buffer.length then break end
			buffer:set_target_range(buffer.target_end + offset, buffer.length + 1)
		end
		buffer:end_undo_action()

		-- Restore any original selection.
		if replace_in_sel then
			e = buffer:indicator_end(INDIC_REPLACE, s)
			buffer.selection_n_start[i], buffer.selection_n_end[i] = s, e > 1 and e or buffer.length + 1
			if e > 1 then buffer:indicator_clear_range(e, 1) end
		end
	end

	ui.statusbar_text = string.format('%d %s', count, _L['replacement(s) made'])
end)

--- Helper function for getting the files found view.
local function get_ff_view()
	for _, view in ipairs(_VIEWS) do if is_ff_buf(view.buffer) then return view end end
end
--- Helper function for getting the files found buffer.
local function get_ff_buffer()
	for _, buffer in ipairs(_BUFFERS) do if is_ff_buf(buffer) then return buffer end end
end

--- Jumps to the source of the next or previous find in files search result in the buffer titled
-- "Files Found", or the result on a given line number, depending on the value of *location*.
-- @param location When `true`, jumps to the next search result. When `false`, jumps to the
--	previous one. When a line number, jumps to it.
function M.goto_file_found(location)
	local line_num = type(assert_type(location, 'boolean/number', 1)) == 'number' and location
	local ff_view, ff_buffer = get_ff_view(), get_ff_buffer()
	if not ff_view and not ff_buffer then return end
	if ff_view then
		ui.goto_view(ff_view)
	else
		view:goto_buffer(ff_buffer)
	end

	-- If no line number was given, find the next search result, wrapping as necessary.
	if not line_num then
		local f, next = location and buffer.search_next or buffer.search_prev, location
		buffer[next and 'line_end' or 'home'](buffer)
		buffer:search_anchor()
		local pos = f(buffer, buffer.FIND_REGEXP, '^.+:\\d+:.+$')
		if pos == -1 then
			buffer:goto_line(next and 1 or buffer.line_count)
			buffer:search_anchor()
			pos = f(buffer, buffer.FIND_REGEXP, '^.+:\\d+:.+$')
		end
		if pos == -1 then return end
		line_num = buffer:line_from_position(pos)
	end
	buffer:goto_line(line_num)

	-- Get the search directory for relative result paths.
	local utf8_dir, patt = nil, '^' .. _L['Directory:']:gsub('%p', '%%%0') .. ' ([^\r\n]+)'
	for i = line_num, 1, -1 do
		utf8_dir = buffer:get_line(i):match(patt)
		if utf8_dir then break end
	end
	if not utf8_dir then return end

	-- Go to the source of the search result.
	local line = buffer:get_cur_line()
	local utf8_filename, pos
	utf8_filename, line_num, pos = line:match('^(.+):(%d+):()')
	if not utf8_filename then return end
	utf8_filename = utf8_dir .. (not WIN32 and '/' or '\\') .. utf8_filename
	line_num = tonumber(line_num)
	textadept.editing.select_line()
	pos = buffer.selection_start + pos - 1 -- absolute pos of result text on line
	local s = buffer:indicator_end(M.INDIC_FIND, buffer.selection_start)
	local e = buffer:indicator_end(M.INDIC_FIND, s)
	if buffer:line_from_position(s) == buffer:line_from_position(pos) then
		s, e = s - pos, e - pos -- relative to line start
	else
		s, e = 0, 0 -- binary file notice, or highlighting was somehow removed
	end
	ui.goto_file(utf8_filename:iconv(_CHARSET, 'UTF-8'), ff_view, preferred_view)
	textadept.editing.goto_line(line_num)
	if buffer:line_from_position(buffer.current_pos + s) == line_num then
		buffer:set_sel(buffer.current_pos + e, buffer.current_pos + s)
	end
end

-- Jump to the find in files result when pressing Enter.
events.connect(events.KEYPRESS, function(key)
	if key ~= '\n' or not is_ff_buf(buffer) then return end
	M.goto_file_found(buffer:line_from_position(buffer.current_pos))
	return true
end)

-- Jump to the find in files result when double-clicking a line.
events.connect(events.DOUBLE_CLICK,
	function(_, line) if is_ff_buf(buffer) then M.goto_file_found(line) end end)

-- The functions below are Lua C functions.

--- Mimics pressing the "Find Next" button.
-- Emits `events.FIND`.
-- @function find_next

--- Mimics pressing the "Find Prev" button.
-- Emits `events.FIND`.
-- @function find_prev

--- Mimics pressing the "Replace" button.
-- Emits `events.REPLACE` followed by `events.FIND` unless any `events.REPLACE` handler returns
-- `true`.
-- @function replace

--- Mimics pressing the "Replace All" button.
-- Emits `events.REPLACE_ALL`.
-- @function replace_all

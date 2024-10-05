-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Editing features for Textadept.
-- @module textadept.editing
local M = {}

--- Map of lexer names to line comment strings for programming languages, used by
-- `editing.toggle_comment()`.
-- Keys are lexer names and values are either the language's line comment prefixes or block
-- comment delimiters separated by a '|' character. If no comment string exists for a given
-- language, the lexer-supplied string is used, if available.
M.comment_string = {}

--- Map of autocompleter names to autocompletion functions.
-- Names are typically lexer names and autocompletion functions typically autocomplete symbols.
-- Autocompletion functions must return two values: the number of characters behind the caret
-- that are used as the prefix of the entity to be autocompleted, and a list of completions
-- to be shown. By default, the list of completions should be separated by space characters,
-- but the function may change `buffer.auto_c_separator` if needed. Also, autocompletion lists
-- are sorted automatically by default, but the function may change `buffer.auto_c_order`
-- if it wants to control sort order.
-- @see autocomplete
M.autocompleters = {}

--- Autocomplete the current word using words from all open buffers.
-- If `true`, performance may be slow when many buffers are open.
-- The default value is `false`.
M.autocomplete_all_words = false

--- Map of auto-paired characters like parentheses, brackets, braces, and quotes.
-- The default auto-paired characters are "()", "[]", "{}", "&apos;&apos;", "&quot;&quot;",
-- and "``". For certain XML-like lexers, "<>" is also auto-paired.
-- @usage textadept.editing.auto_pairs['*'] = '*'
-- @usage textadept.editing.auto_pairs = nil -- disable completely
M.auto_pairs = {}
for k, v in string.gmatch([[()[]{}''""``]], '(.)(.)') do M.auto_pairs[k] = v end

--- Whether or not to type over an auto-paired complement character.
-- The default value is `true`.
M.typeover_auto_paired = true

--- Match the previous line's indentation level after inserting a new line.
-- The default value is `true`.
M.auto_indent = true

--- Whether or not to auto-enclose selected text when typing a punctuation character, taking
-- `textadept.editing.auto_pairs` into account.
-- The default value is `false`.
M.auto_enclose = false

--- Strip trailing whitespace before saving files. (Does not apply to binary files.)
-- The default value is `false`.
M.strip_trailing_spaces = false

M.HIGHLIGHT_NONE, M.HIGHLIGHT_CURRENT, M.HIGHLIGHT_SELECTED = 1, 2, 3
--- The word highlight mode.
--
-- - `textadept.editing.HIGHLIGHT_CURRENT`
--	Automatically highlight all instances of the current word.
-- - `textadept.editing.HIGHLIGHT_SELECTED`
--	Automatically highlight all instances of the selected word.
-- - `textadept.editing.HIGHLIGHT_NONE`
--	Do not automatically highlight words.
--
-- The default value is `textadept.editing.HIGHLIGHT_NONE`.
M.highlight_words = M.HIGHLIGHT_NONE

--- The word highlight indicator number.
M.INDIC_HIGHLIGHT = view.new_indic_number()

--- Map of image names to registered image numbers.
-- @field CLASS The image number for classes.
-- @field NAMESPACE The image number for namespaces.
-- @field METHOD The image number for methods.
-- @field SIGNAL The image number for signals.
-- @field SLOT The image number for slots.
-- @field VARIABLE The image number for variables.
-- @field STRUCT The image number for structures.
-- @field TYPEDEF The image number for type definitions.
-- @table XPM_IMAGES

-- LuaFormatter off
M.XPM_IMAGES = {not CURSES and '/* XPM */static char *class[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #001CD0","X c #008080","o c #0080E8","O c #00C0C0","+ c #24D0FC","@ c #00FFFF","# c #A4E8FC","$ c #C0FFFF","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or '*',not CURSES and '/* XPM */static char *namespace[] = {/* columns rows colors chars-per-pixel */"16 16 7 1 ","  c #000000",". c #1D1D1D","X c #393939","o c #555555","O c #A8A8A8","+ c #AAAAAA","@ c None",/* pixels */"@@@@@@@@@@@@@@@@","@@@@+@@@@@@@@@@@","@@@.o@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@+.@@@@@@@+@@@@","@@+ @@@@@@@o.@@@","@@@ +@@@@@@+ @@@","@@@ +@@@@@@+ @@@","@@@.X@@@@@@@.+@@","@@@@+@@@@@@@ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@X.@@@","@@@@@@@@@@@+@@@@","@@@@@@@@@@@@@@@@"};' or '@',not CURSES and '/* XPM */static char *method[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOOOOO","OO  X. OOOOOOOOO","OOOO  OOOOOOOOOO"};' or '+',not CURSES and '/* XPM */static char *signal[] = {/* columns rows colors chars-per-pixel */"16 16 6 1 ","  c #000000",". c #FF0000","X c #E0BC38","o c #F0DC5C","O c #FCFC80","+ c None",/* pixels */"++++++++++++++++","++++++++++++++++","++++++++++++++++","++++++++++  ++++","+++++++++ OO  ++","++++++++ OOOOO +","+++++++ OOOOOX +","++++  + ooOOXX +","+++ OO  oooXXX +","++ OOOOO ooXX ++","+ OOOOOX  oX +++","+ ooOOXX +  ++++","+ oooXXX +++++++","+ oooXX +++++..+","++  oX ++++++..+","++++  ++++++++++"};' or '~',not CURSES and '/* XPM */static char *slot[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOO   ","OO  X. OOOOOO O ","OOOO  OOOOOOO   "};' or '-',not CURSES and '/* XPM */static char *variable[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #8C748C","X c #9C94A4","o c #ACB4C0","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOO  OOOOO","OOOOOOOO oo  OOO","OOOOOOO ooooo OO","OOOOOO ooooo. OO","OOOOOO XXoo.. OO","OOOOOO XXX... OO","OOOOOO XXX.. OOO","OOOOOOO  X. OOOO","OOOOOOOOO  OOOOO","OOOOOOOOOOOOOOOO"};' or '.',not CURSES and '/* XPM */static char *struct[] = {/* columns rows colors chars-per-pixel */"16 16 14 1 ","  c #000000",". c #008000","X c #00C000","o c #00FF00","O c #808000","+ c #C0C000","@ c #FFFF00","# c #008080","$ c #00C0C0","% c #00FFFF","& c #C0FFC0","* c #FFFFC0","= c #C0FFFF","- c None",/* pixels */"-----  ---------","---- &&  -------","--- &&&oo ------","-- ooooo.   ----","-- XXoo.. ==  --","-- XXX.. ===%% -","-- XXX. %%%%%# -","---   . $$%%## -","--- **  $$$### -","-- ***@@ $$## --","- @@@@@O  $# ---","- ++@@OO -  ----","- +++OOO -------","- +++OO --------","--  +O ---------","----  ----------"};' or '}',not CURSES and '/* XPM */static char *typedef[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #404040","X c #6D6D6D","o c #777777","O c #949494","+ c #ACACAC","@ c #BBBBBB","# c #DBDBDB","$ c #EEEEEE","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or ':',CLASS=1,NAMESPACE=2,METHOD=3,SIGNAL=4,SLOT=5,VARIABLE=6,STRUCT=7,TYPEDEF=8}
-- LuaFormatter on

--- Comments or uncomments the selected lines based on the current language.
-- As long as any part of a line is selected, the entire line is eligible for
-- commenting/uncommenting.
-- @see comment_string
function M.toggle_comment()
	local lang = buffer:get_lexer(true)
	local comment = M.comment_string[lang] or buffer.property['scintillua.comment.' .. lang]
	local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
	if not prefix then return end
	local anchor, pos = buffer.selection_start, buffer.selection_end
	local s, e = buffer:line_from_position(anchor), buffer:line_from_position(pos)
	local ignore_last_line = s ~= e and pos == buffer:position_from_line(e)
	anchor, pos = buffer.line_end_position[s] - anchor, buffer.length + 1 - pos
	local column = math.huge
	buffer:begin_undo_action()
	for line = s, not ignore_last_line and e or e - 1 do
		local p = buffer.line_indent_position[line]
		local uncomment = buffer:text_range(p, p + #prefix) == prefix
		if not uncomment then
			column = math.min(buffer.column[p], column)
			p = buffer:find_column(line, column)
			buffer:insert_text(p, prefix)
			if suffix ~= '' then buffer:insert_text(buffer.line_end_position[line], suffix) end
		else
			buffer:delete_range(p, #prefix)
			if suffix ~= '' then
				p = buffer.line_end_position[line]
				buffer:delete_range(p - #suffix, #suffix)
			end
		end
		if line == s then anchor = anchor + #suffix * (uncomment and -1 or 1) end
		if line == e then pos = pos + #suffix * (uncomment and -1 or 1) end
	end
	buffer:end_undo_action()
	anchor, pos = buffer.line_end_position[s] - anchor, buffer.length + 1 - pos
	-- Keep the anchor and caret on the first line as necessary.
	local start_pos = buffer:position_from_line(s)
	anchor, pos = math.max(anchor, start_pos), math.max(pos, start_pos)
	if s ~= e then
		buffer:set_sel(anchor, pos)
	else
		buffer:goto_pos(pos)
	end
end

--- Moves the caret to the beginning of line number *line* or the user-specified line, ensuring
-- that line is visible.
-- @param[opt] line Optional line number to go to. If `nil`, the user is prompted for one.
function M.goto_line(line)
	if not assert_type(line, 'number/nil', 1) then
		line = tonumber(ui.dialogs.input{title = _L['Go to line number:']} or nil)
		if not line then return end
	end
	view:ensure_visible_enforce_policy(line)
	buffer:goto_line(line)
end
args.register('-l', '--line', 1, function(line) M.goto_line(tonumber(line) or line) end,
	'Go to line')

--- Joins the currently selected lines or the current line with the line below it.
-- As long as any part of a line is selected, the entire line is eligible for joining.
function M.join_lines()
	buffer:target_from_selection()
	buffer:line_end()
	local line = buffer:line_from_position(buffer.target_start)
	if line == buffer:line_from_position(buffer.target_end) then
		buffer.target_end = buffer:position_from_line(line + 1)
	end
	buffer:lines_join()
end

--- Encloses the selected text or the current word within strings *left* and *right*, taking
-- multiple selections into account.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @param[opt=false] select Optional flag that indicates whether or not to keep enclosed text
--	selected.
function M.enclose(left, right, select)
	assert_type(left, 'string', 1)
	assert_type(right, 'string', 2)
	assert_type(select, 'boolean/nil', 3)
	buffer:begin_undo_action()
	for i = 1, buffer.selections do
		local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
		if s == e then
			s = buffer:word_start_position(s, true)
			e = buffer:word_end_position(e, true)
		end
		buffer:set_target_range(s, e)
		buffer:replace_target(left .. buffer.target_text .. right)
		buffer.selection_n_start[i] = not select and buffer.target_end or buffer.target_start + #left
		buffer.selection_n_end[i] = buffer.target_end - (not select and 0 or #right)
	end
	buffer:end_undo_action()
end

--- Selects the text between strings *left* and *right* that enclose the caret.
-- If that range is already selected, toggles between selecting *left* and *right* as well.
-- If *left* and *right* are not provided, they are assumed to be one of the delimiter pairs
-- specified in `textadept.editing.auto_pairs` and are inferred from the current position
-- or selection.
-- @param[opt] left Optional left part of the enclosure.
-- @param[optchain] right Optional right part of the enclosure.
function M.select_enclosed(left, right)
	local s, e, anchor, pos = -1, -1, buffer.anchor, buffer.current_pos
	if assert_type(left, 'string/nil', 1) and assert_type(right, 'string', 2) then
		if anchor ~= pos then buffer:goto_pos(pos - #right) end
		buffer:search_anchor()
		s, e = buffer:search_prev(0, left), buffer:search_next(0, right)
	elseif M.auto_pairs then
		s = buffer.selection_start
		repeat
			-- Backtrack, looking for an auto-paired range that includes the current position.
			local char = buffer:text_range(s, buffer:position_after(s))
			local match = M.auto_pairs[char] or (char == '>' and M.auto_pairs['<'] and '<') -- >...<
			if not match then goto continue end
			left, right = char, match
			-- If the auto-paired brace range includes the current position, use it.
			e = buffer:brace_match(s, 0)
			if e >= buffer.selection_end - 1 then break end
			if e ~= -1 then e = -1 end
			-- If the auto-paired non-brace range (e.g. quotes) is in the same style as, and includes
			-- the current position, use it.
			if buffer.style_at[s] ~= buffer.style_at[buffer.selection_start] then goto continue end
			buffer.search_flags = 0
			buffer:set_target_range(s + 1, buffer.length + 1)
			if buffer:search_in_target(match) >= buffer.selection_end - 1 then
				e = buffer.target_end - 1
				break
			end
			::continue::
			s = s - 1
		until s < 1
	end
	if s == -1 or e == -1 then return end
	if s + #left == anchor and e == pos then s, e = s - #left, e + #right end
	buffer:set_sel(s + #left, e)
end

--- Selects the current word or, if *all* is `true`, all occurrences of the current word.
-- If a word is already selected, selects the next occurrence as a multiple selection.
-- @param all Whether or not to select all occurrences of the current word. The default value is
--	`false`.
-- @see buffer.word_chars
function M.select_word(all)
	buffer:target_whole_document()
	buffer.search_flags = buffer.FIND_MATCHCASE
	if buffer.selection_empty or buffer:is_range_word(buffer.selection_start, buffer.selection_end) then
		buffer.search_flags = buffer.search_flags | buffer.FIND_WHOLEWORD
		if all then buffer:multiple_select_add_next() end -- select word first
	end
	buffer['multiple_select_add_' .. (not all and 'next' or 'each')](buffer)
end

--- Selects the current line.
-- If a current selection spans multiple lines, expands the selection to include whole lines.
function M.select_line()
	local s = buffer:position_from_line(buffer:line_from_position(buffer.selection_start))
	local e = buffer.line_end_position[buffer:line_from_position(buffer.selection_end)]
	if buffer.anchor > buffer.current_pos then s, e = e, s end
	buffer:set_sel(s, e)
end

--- Selects the current paragraph.
-- Paragraphs are surrounded by one or more blank lines.
function M.select_paragraph()
	buffer:line_down()
	buffer:para_up()
	buffer:para_down_extend()
end

--- Converts indentation between tabs and spaces according to `buffer.use_tabs`.
-- If `buffer.use_tabs` is `true`, `buffer.tab_width` indenting spaces are converted to tabs.
-- Otherwise, all indenting tabs are converted to `buffer.tab_width` spaces.
function M.convert_indentation()
	buffer:begin_undo_action()
	for line = 1, buffer.line_count do
		local s = buffer:position_from_line(line)
		local indent = buffer.line_indentation[line]
		local e = buffer.line_indent_position[line]
		local current_indentation, new_indentation = buffer:text_range(s, e), nil
		if buffer.use_tabs then
			local tabs = indent // buffer.tab_width
			local spaces = math.fmod(indent, buffer.tab_width)
			new_indentation = string.rep('\t', tabs) .. string.rep(' ', spaces)
		else
			new_indentation = string.rep(' ', indent)
		end
		if current_indentation ~= new_indentation then
			buffer:set_target_range(s, e)
			buffer:replace_target(new_indentation)
		end
	end
	buffer:end_undo_action()
end

--- Pastes the text from the clipboard, taking into account the buffer's indentation settings
-- and the indentation of the current and preceding lines.
function M.paste_reindent()
	-- Normalize EOLs and strip leading indentation from clipboard text.
	local text = ui.clipboard_text
	if not buffer.encoding then text = text:iconv('CP1252', 'UTF-8') end
	if buffer.eol_mode == buffer.EOL_CRLF then
		text = text:gsub('^\n', '\r\n'):gsub('([^\r])\n', '%1\r\n')
	end
	local lead_indent = text:match('^[ \t]*')
	if lead_indent ~= '' then text = text:sub(#lead_indent + 1):gsub('\n' .. lead_indent, '\n') end
	-- Change indentation to match buffer indentation settings.
	local indent, tab_width = buffer.use_tabs and '\t' or string.rep(' ', buffer.tab_width), math.huge
	text = text:gsub('\n([ \t]+)', function(indentation)
		if indentation:find('^\t') then return '\n' .. indentation:gsub('\t', indent) end
		tab_width = math.min(tab_width, #indentation)
		local level = #indentation // tab_width
		local spaces = string.rep(' ', math.fmod(#indentation, tab_width))
		return string.format('\n%s%s', string.rep(indent, level), spaces)
	end)
	-- Re-indent according to whichever of the current and preceding lines has the higher indentation
	-- amount. However, if the preceding line is a fold header, indent by an extra level.
	local line = buffer:line_from_position(buffer.selection_start)
	local i = line - 1
	while i >= 1 and buffer:position_from_line(i) == buffer.line_end_position[i] do i = i - 1 end
	if i < 1 or buffer.line_indentation[i] < buffer.line_indentation[line] then i = line end
	local indentation =
		buffer:text_range(buffer:position_from_line(i), buffer.line_indent_position[i])
	local fold_header = i ~= line and buffer.fold_level[i] & buffer.FOLDLEVELHEADERFLAG > 0
	if fold_header then indentation = indentation .. indent end
	text = text:gsub('\n', '\n' .. indentation)
	-- Paste the text and adjust first and last line indentation accordingly.
	local start_indent = buffer.line_indentation[i]
	if fold_header then start_indent = start_indent + buffer.tab_width end
	local end_line = buffer:line_from_position(buffer.selection_end)
	local end_indent = buffer.line_indentation[end_line]
	local end_column = buffer.column[buffer.selection_end]
	buffer:begin_undo_action()
	buffer:replace_sel(text)
	buffer.line_indentation[line] = start_indent
	if text:find('\n') then
		line = buffer:line_from_position(buffer.current_pos)
		buffer.line_indentation[line] = end_indent
		buffer:goto_pos(buffer:find_column(line, end_column))
	end
	buffer:end_undo_action()
end

--- Passes the selected text or all buffer text to string shell command *command* as standard input
-- (stdin) and replaces the input text with the command's standard output (stdout). *command*
-- may contain shell pipes ('|').
-- Standard input is as follows:
--
-- 1. If no text is selected, the entire buffer is used.
-- 2. If text is selected and spans a single line, is a multiple selection, or is a rectangular
--	selection, only the selected text is used.
-- 3. If text is selected and spans multiple lines, all text on the lines that have text selected
--	is passed as stdin. However, if the end of the selection is at the beginning of a line,
--	only the line ending delimiters from the previous line are included. The rest of the
--	line is excluded.
--
-- Note: Be careful when using commands that emit stdout while reading stdin (as opposed
-- to emitting stdout only after stdin is closed). Input that generates more output
-- than an OS-specific pipe can hold may hang Textadept. On Linux, this may be 64K. See
-- `spawn_proc:write()`.
-- @param command The OS shell command to filter text through. May contain pipes.
function M.filter_through(command)
	assert_type(command, 'string', 1)
	local s, e, top_line = buffer.selection_start, buffer.selection_end, view.first_visible_line
	if s == e then
		-- Use the whole buffer as input.
		buffer:target_whole_document()
	elseif buffer.selections == 1 then
		-- Use the selected lines as input.
		local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
		if i < j then
			s = buffer:position_from_line(i)
			if buffer.column[e] > 1 then e = buffer:position_from_line(j + 1) end
		end
		buffer:set_target_range(s, e)
	end
	local commands = lpeg.match(lpeg.Ct(lpeg.P{
		lpeg.C(lpeg.V('command')) * ('|' * lpeg.C(lpeg.V('command')))^0, --
		command = (1 - lpeg.S('"\'|') + lpeg.V('str'))^1, --
		str = '"' * (1 - lpeg.S('"\\') + lpeg.P('\\') * 1)^0 * lpeg.P('"')^-1 +
			("'" * (1 - lpeg.S("'\\") + lpeg.P('\\') * 1)^0 * lpeg.P("'")^-1)
	}), command)
	local inout = buffer.selections == 1 and buffer.target_text or {}
	if buffer.selections > 1 then
		-- Use selected text as input.
		for i = 1, buffer.selections do
			inout[#inout + 1] = buffer:text_range(buffer.selection_n_start[i], buffer.selection_n_end[i])
		end
		local newline = not WIN32 and '\n' or '\r\n'
		inout = table.concat(inout, newline) .. newline
	end
	for i = 1, #commands do
		local p = assert(os.spawn(commands[i]:match('^%s*(.-)%s*$')))
		p:write(inout)
		p:close()
		inout = p:read('a') or ''
		if p:wait() ~= 0 then
			ui.statusbar_text = string.format('"%s" %s', commands[i], _L['returned non-zero status'])
			return
		end
	end
	if not utf8.len(inout) then inout = inout:iconv('UTF-8', _CHARSET) end
	if buffer.selections == 1 then
		if buffer:get_text() == inout then return end -- do not perform no-op
		buffer:replace_target(inout)
		view.first_visible_line = top_line
		if s == e then buffer.target_start, buffer.target_end = s, s end
		buffer:set_sel(buffer.target_start, buffer.target_end)
	elseif buffer.selection_is_rectangle then
		local anchor, pos = buffer.rectangular_selection_anchor, buffer.rectangular_selection_caret
		buffer:replace_rectangular(inout)
		buffer.rectangular_selection_anchor, buffer.rectangular_selection_caret = anchor, pos
	else
		local lines = {}
		for line in inout:gmatch('[^\r\n]*') do lines[#lines + 1] = line end
		buffer:begin_undo_action()
		for i = 1, buffer.selections do
			buffer:set_target_range(buffer.selection_n_start[i], buffer.selection_n_end[i])
			buffer:replace_target(lines[i] or '')
			buffer.selection_n_end[i] = buffer.selection_n_start[i] + #(lines[i] or '')
		end
		buffer:end_undo_action()
	end
end

--- Displays an autocompletion list provided by the autocompleter function associated with string
-- *name*, and returns `true` if completions were found.
-- @param name The name of an autocompleter function in the `textadept.editing.autocompleters`
--	table to use for providing autocompletions.
-- @see autocompleters
function M.autocomplete(name)
	if not M.autocompleters[assert_type(name, 'string', 1)] then return end
	buffer.auto_c_separator, buffer.auto_c_order = string.byte(' '), buffer.ORDER_PERFORMSORT
	local len_entered, list = M.autocompleters[name]() -- may change separator, order
	if not len_entered or not list or #list == 0 then return end
	local pos = buffer.current_pos
	buffer:auto_c_show(len_entered, table.concat(list, string.char(buffer.auto_c_separator)))
	-- At this point, there is either (1) a list of completions shown, (2) a single completion was
	-- automatically chosen, or (3) no completions are shown because none were valid (e.g. a language
	-- server returned a "fuzzy" list of completions that Scintilla does not recognize as valid).
	return buffer:auto_c_active() or buffer.auto_c_choose_single and buffer.current_pos ~= pos
end

--- Returns for the word part behind the caret a list of whole word completions
-- constructed from the current buffer or all open buffers (depending on
-- `textadept.editing.autocomplete_all_words`).
-- If `buffer.auto_c_ignore_case` is `true`, completions are not case-sensitive.
-- @see buffer.word_chars
-- @see autocomplete
-- @function _G.textadept.editing.autocompleters.word
M.autocompleters.word = function()
	local list, matches = {}, {}
	local s = buffer:word_start_position(buffer.current_pos, true)
	if s == buffer.current_pos then return end
	local word_part = buffer:text_range(s, buffer.current_pos)
	for _, buffer in ipairs(_BUFFERS) do
		if buffer == _G.buffer or M.autocomplete_all_words then
			buffer.search_flags = buffer.FIND_WORDSTART |
				(not _G.buffer.auto_c_ignore_case and buffer.FIND_MATCHCASE or 0)
			buffer:target_whole_document()
			while buffer:search_in_target(word_part) ~= -1 do
				local e = buffer:word_end_position(buffer.target_end, true)
				local match = buffer:text_range(buffer.target_start, e)
				if #match > #word_part and not matches[match] then
					list[#list + 1], matches[match] = match, true
				end
				buffer:set_target_range(e, buffer.length + 1)
			end
		end
	end
	return #word_part, list
end

--- Table of brace characters to highlight.
-- Brace characters are ASCII values assigned to `true`.
-- Recognized characters are '(', ')', '[', ']', '{', '}', '<', and '>'. This table is updated
-- based on a lexer's "scintillua.angle.braces" property.
local brace_matches = {}

--- Table of auto-paired characters to move over when typed.
-- Typeover characters are keys assigned to `true`.
local typeover_chars = {}

--- Update auto_pairs, brace_matches, and typeover_chars based on lexer.
local function update_language_specific_features()
	brace_matches, typeover_chars = {}, {} -- clear
	local angles = buffer.property['scintillua.angle.braces'] ~= ''
	for _, code in utf8.codes(angles and '()[]{}<>' or '()[]{}') do brace_matches[code] = true end
	if not M.auto_pairs then return end
	M.auto_pairs['<'] = angles and '>' or nil
	for _, char in pairs(M.auto_pairs) do typeover_chars[char] = true end
end
events.connect(events.LEXER_LOADED, function()
	update_language_specific_features()
	local word_chars = buffer.property['scintillua.word.chars']
	if word_chars ~= '' then buffer.word_chars = word_chars end
end)
events.connect(events.BUFFER_AFTER_SWITCH, update_language_specific_features)
events.connect(events.VIEW_AFTER_SWITCH, update_language_specific_features)

-- Matches characters specified in auto_pairs, taking multiple selections into account.
events.connect(events.CHAR_ADDED, function(code)
	if not M.auto_pairs or not M.auto_pairs[utf8.char(code)] then return end
	buffer:begin_undo_action()
	for i = 1, buffer.selections do
		local pos = buffer.selection_n_caret[i]
		buffer:set_target_range(pos, pos)
		buffer:replace_target(M.auto_pairs[utf8.char(code)])
	end
	buffer:end_undo_action()
end)

-- Removes matched chars on backspace, taking multiple selections into account.
events.connect(events.KEYPRESS, function(key)
	if not M.auto_pairs or key ~= '\b' or ui.command_entry.active then return end
	buffer:begin_undo_action()
	for i = 1, buffer.selections do
		local pos = buffer.selection_n_caret[i]
		local char = buffer:text_range(pos, buffer:position_after(pos))
		local char_before = buffer:text_range(buffer:position_before(pos), pos)
		if char == M.auto_pairs[char_before] then buffer:delete_range(pos, #char) end
	end
	buffer:end_undo_action()
end, 1) -- need index of 1 because default key handler halts propagation

-- Moves over auto-paired complement characters when typed, taking multiple selections into
-- account.
events.connect(events.KEYPRESS, function(key)
	if not M.typeover_auto_paired or not typeover_chars[key] then return end
	if not buffer.selection_empty or ui.command_entry.active then return end
	local handled = false
	for i = 1, buffer.selections do
		local pos = buffer.selection_n_caret[i]
		if buffer:text_range(pos, buffer:position_after(pos)) == key then
			buffer.selection_n_start[i], buffer.selection_n_end[i] = pos + 1, pos + 1
			handled = true
		end
	end
	if handled then return true end -- prevent typing
end)

-- Auto-indent on return.
events.connect(events.CHAR_ADDED, function(code)
	if not M.auto_indent or code ~= string.byte('\n') then return end
	local line = buffer:line_from_position(buffer.current_pos)
	if line > 1 and buffer:get_line(line - 1):find('^[\r\n]+$') and
		buffer:get_line(line):find('^[^\r\n]') then
		return -- do not auto-indent when pressing enter from start of previous line
	end
	local i = line - 1
	while i >= 1 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
	if i >= 1 then
		buffer.line_indentation[line] = buffer.line_indentation[i]
		buffer:vc_home()
	end
end)

-- Enclose selected text in punctuation or auto-paired characters.
events.connect(events.KEYPRESS, function(key)
	if not M.auto_enclose or buffer.selection_empty or not key:find('^%p$') then return end
	if ui.command_entry.active then return end
	M.enclose(key, M.auto_pairs[key] or key, true)
	return true -- prevent typing
end, 1)

-- Highlights matching braces.
events.connect(events.UPDATE_UI, function(updated)
	if updated & 3 == 0 then return end -- ignore scrolling
	if brace_matches[buffer.char_at[buffer.current_pos]] then
		local match = buffer:brace_match(buffer.current_pos, 0)
		local f = match ~= -1 and view.brace_highlight or view.brace_bad_light
		f(buffer, buffer.current_pos, match)
		return
	end
	view:brace_bad_light(-1)
end)

-- Highlight all instances of the current or selected word.
events.connect(events.UPDATE_UI, function(updated)
	if updated & buffer.UPDATE_SELECTION == 0 or ui.find.active then return end
	if M.highlight_words == M.HIGHLIGHT_NONE then return end
	buffer.indicator_current = M.INDIC_HIGHLIGHT
	buffer:indicator_clear_range(1, buffer.length)
	if M.highlight_words == M.HIGHLIGHT_CURRENT then
		local s = buffer:word_start_position(buffer.current_pos, true)
		local e = buffer:word_end_position(buffer.current_pos, true)
		buffer:set_target_range(s, e)
	elseif M.highlight_words == M.HIGHLIGHT_SELECTED then
		buffer:target_from_selection()
		if not buffer:is_range_word(buffer.target_start, buffer.target_end) then return end
		if buffer.target_text:find(string.format('[^%s]', buffer.word_chars)) then return end
	end
	local word = buffer.target_text
	if word == '' then return end
	buffer.search_flags = buffer.FIND_MATCHCASE | buffer.FIND_WHOLEWORD
	buffer:target_whole_document()
	while buffer:search_in_target(word) ~= -1 do
		buffer:indicator_fill_range(buffer.target_start, buffer.target_end - buffer.target_start)
		buffer:set_target_range(buffer.target_end, buffer.length + 1)
	end
end)

-- Enables and disables bracketed paste mode in curses and disables auto-pair and auto-indent
-- while pasting.
if CURSES and not WIN32 then
	local function enable_br_paste() io.stdout:write('\x1b[?2004h'):flush() end
	local function disable_br_paste() io.stdout:write('\x1b[?2004l'):flush() end
	enable_br_paste()
	events.connect(events.SUSPEND, disable_br_paste)
	events.connect(events.RESUME, enable_br_paste)
	events.connect(events.QUIT, disable_br_paste)

	local auto_pairs, auto_indent
	events.connect(events.CSI, function(cmd, args)
		if cmd ~= string.byte('~') then return end
		if args[1] == 200 then
			auto_pairs, M.auto_pairs = M.auto_pairs, nil
			auto_indent, M.auto_indent = M.auto_indent, false
		elseif args[1] == 201 then
			M.auto_pairs, M.auto_indent = auto_pairs, auto_indent
		end
	end)
end

-- Strips trailing whitespace ('\t' or ' ') in text files, prior to saving them.
events.connect(events.FILE_BEFORE_SAVE, function()
	if not M.strip_trailing_spaces or not buffer.encoding then return end
	buffer:begin_undo_action()
	for line = 1, buffer.line_count do
		local s, e = buffer:position_from_line(line), buffer.line_end_position[line]
		local i, byte = e - 1, buffer.char_at[e - 1]
		while i >= s and (byte == 9 or byte == 32) do i, byte = i - 1, buffer.char_at[i - 1] end
		if i < e - 1 then buffer:delete_range(i + 1, e - i - 1) end
	end
	buffer:end_undo_action()
end)

-- Registers XPM images for new views.
events.connect(events.VIEW_NEW, function()
	local view = buffer ~= ui.command_entry and view or ui.command_entry
	for name, i in pairs(M.XPM_IMAGES) do
		if type(name) == 'string' then view:register_image(i, M.XPM_IMAGES[i]) end
	end
end)
for _ = 1, #M.XPM_IMAGES do view.new_image_type() end -- sync

return M

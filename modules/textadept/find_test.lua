-- Copyright 2020-2024 Mitchell. See LICENSE.

-- Test find and replace text.
local find = 'word'
local replace = find:upper()

teardown(function()
	if not ui.find.active then return end
	ui.find.incremental, ui.find.in_files = false, false
	ui.find.focus()
end)

test('find should search for text and select the first match', function()
	buffer:append_text(find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should emit an event for results found', function()
	local found = test.stub()
	local _<close> = test.connect(events.FIND_RESULT_FOUND, found)
	buffer:append_text(find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(found.called, true)
	test.assert_equal(found.args, {find})
end)

test('find should count how many occurrences it found #skip', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	-- TODO: how to assert ui.statusbar_text was written to? Cannot mock it.
end)

test('find should wrap around when searching', function()
	buffer:add_text(find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should emit an event after wrapping', function()
	local wrapped = test.stub()
	local _<close> = test.connect(events.FIND_WRAPPED, wrapped)
	buffer:add_text(find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(wrapped.called, true)
end)

test('find should allow repeatedly searching for occurrences', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.find_next()

	ui.find.find_next()

	test.assert_equal(buffer.selection_start, buffer.length + 1 - #find)
	test.assert_equal(buffer.selection_end, buffer.length + 1)
end)

test('find should display a statusbar message if it could not find anything #skip', function()
	ui.find.find_entry_text = 'will not be found'

	ui.find.find_next()

	-- TODO: how to assert ui.statusbar_text was written to? Cannot mock it.
end)

test('find should allow searching backwards and select the first match', function()
	buffer:add_text(find)
	ui.find.find_entry_text = find

	ui.find.find_prev()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should wrap around when searching backwards', function()
	buffer:append_text(find)
	ui.find.find_entry_text = find

	ui.find.find_prev()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should allow repeatedly searching backwards for occurrences', function()
	buffer:add_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.find_prev()

	ui.find.find_prev()

	test.assert_equal(buffer.selection_start, 1)
	test.assert_equal(buffer.selection_end, 1 + #find)
end)

test('find should allow searching case-sensitively', function()
	local _<close> = test.mock(ui.find, 'match_case', true)
	buffer:append_text(find:upper() .. find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should allow searching for whole words', function()
	local _<close> = test.mock(ui.find, 'whole_word', true)
	buffer:append_text(find .. find .. ' ' .. find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(buffer.selection_start, buffer.length + 1 - #find)
	test.assert_equal(buffer.selection_end, buffer.length + 1)
end)

test('find should allow searching with regex', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:append_text(find)
	ui.find.find_entry_text = '^' .. find

	ui.find.find_next()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should handle and advance through zero-width matches', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:append_text(test.lines{'', ''})
	ui.find.find_entry_text = '^'

	ui.find.find_next()
	local first_match_line = buffer:line_from_position(buffer.current_pos)
	ui.find.find_next()
	local second_match_line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(first_match_line, 1)
	test.assert_equal(second_match_line, 2)
end)

test('find should allow advancing backwards through zero-width matches', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:add_text(test.lines{'', ''})
	ui.find.find_entry_text = '$'

	ui.find.find_prev()

	test.assert_equal(buffer:position_from_line(buffer.current_pos), 1)
end)
expected_failure() -- TODO: Scintilla bug?

test('find should highlight results if ui.find.highlight_all_matches is enabled', function()
	local _<close> = test.mock(ui.find, 'highlight_all_matches', true)
	buffer:append_text(find .. ' ' .. find)
	ui.find.find_entry_text = find

	ui.find.find_next()

	local highlighted_matches = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(highlighted_matches, {find, find})
end)

test('find should clear highlights before searching again', function()
	local _<close> = test.mock(ui.find, 'highlight_all_matches', true)
	buffer:append_text(find)
	ui.find.find_entry_text = find
	ui.find.find_next()

	ui.find.find_entry_text = 'not' .. find
	ui.find.find_next()

	local no_highlights = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(no_highlights, {})
end)

test('find should not highlight single-character matches (for performance)', function()
	local _<close> = test.mock(ui.find, 'highlight_all_matches', true)
	local char = find:sub(1, 1)
	buffer:append_text(char)
	ui.find.find_entry_text = char

	ui.find.find_next()

	local no_highlights = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(no_highlights, {})
end)

test('find should allow searching incrementally with typing', function()
	buffer:append_text(find)
	ui.find.focus{find_entry_text = '', incremental = true}

	test.type(find)

	test.assert_equal(buffer:get_sel_text(), find)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('find should retain the incremental search anchor even for failures', function()
	buffer:append_text(find)
	ui.find.focus{find_entry_text = '', incremental = true}

	local first_char, rest = find:match('^(.)(.+)$')
	test.type(first_char .. first_char)
	local found_typo = not buffer.selection_empty
	local anchor = buffer.anchor
	test.type('\b' .. rest)

	test.assert_equal(found_typo, false)
	test.assert_equal(anchor, 1)
	test.assert_equal(buffer:get_sel_text(), find)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('find should move the incremental search anchor on successful Enter/find next', function()
	buffer:append_text(find .. find)
	ui.find.focus{find_entry_text = '', incremental = true}

	local first_char, rest = find:match('^(.)(.+)$')
	test.type(first_char)
	test.type('\n')
	test.type(rest)

	test.assert_equal(buffer.selection_start, buffer.length + 1 - #find)
	test.assert_equal(buffer.selection_end, buffer.length + 1)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('find should not move the incremental search anchor on failed Enter/find next', function()
	buffer:append_text(find .. find)
	ui.find.focus{find_entry_text = '', incremental = true}
	local bad_char = 'z'

	test.type(bad_char .. '\n')
	test.type('\b' .. find)

	test.assert_equal(buffer.selection_start, 1)
	test.assert_equal(buffer.selection_end, 1 + #find)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('ui.find.focus with in_files should show the default filter in the replace entry', function()
	ui.find.focus{in_files = true}

	test.assert_equal(ui.find.replace_entry_text, table.concat(lfs.default_filter, ','))
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('ui.find.focus without in_files should restore replace entry text', function()
	ui.find.replace_entry_text = ''
	ui.find.focus{in_files = true}

	ui.find.focus()

	test.assert_equal(ui.find.in_files, false)
	test.assert_equal(ui.find.replace_entry_text, '')
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('ui.find.focus with in_files should use a project-specific filter if possible', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	ui.find.find_in_files_filters[dir.dirname] = '*.txt'
	io.open_file(dir / file)

	ui.find.focus{in_files = true}

	test.assert_equal(ui.find.replace_entry_text, '*.txt')
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('find should allow prompting to search in files and output results to a new buffer', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{[file] = find, [subdir] = {[subfile] = find}}
	local select_directory = test.stub(dir.dirname)
	local _<close> = test.mock(ui.dialogs, 'open', select_directory)
	ui.find.focus{find_entry_text = find, in_files = true}

	ui.find.find_next()

	test.assert_equal(select_directory.called, true)
	local dialog_opts = select_directory.args[1]
	test.assert_equal(dialog_opts.only_dirs, true)
	test.assert_equal(buffer._type, _L['[Files Found Buffer]'])
	test.assert_equal(buffer.current_pos, buffer.length + 1)

	local output = buffer:get_text()

	test.assert_contains(output, _L['Find:']:gsub('[_&]', '') .. ' ' .. ui.find.find_entry_text)
	test.assert_contains(output, _L['Directory:'] .. ' ' .. dir.dirname)
	test.assert_contains(output, _L['Filter:']:gsub('[_&]', ''))

	test.assert_contains(output, file .. ':1:' .. find)
	test.assert_contains(output, subfile .. ':1:' .. find)

	local highlighted_results = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(highlighted_results, {find, find})
end)
if CURSES then skip('find & replace pane blocks the UI') end

--- Performs find in files for directory *dir*, find text *find*, and optional filter *filter*.
-- @param dir String path to the directory to search in.
-- @param find String text to search for.
-- @param filter Optional filter string to use when searching.
local function find_in_files(dir, find, filter)
	ui.find.find_entry_text = find
	if filter then ui.find.replace_entry_text = filter end
	local _<close> = test.mock(ui.find, 'in_files', true)
	local select_directory = test.stub(dir)
	local _<close> = test.mock(ui.dialogs, 'open', select_directory)
	ui.find.find_next()
end

test('ui.find.find_in_files should update the filter if changed', function()
	local dir<close> = test.tmpdir({}, true)
	find_in_files(dir.dirname, find, '*.txt') -- find does not matter; just needs to not be empty

	test.assert_equal(ui.find.find_in_files_filters[lfs.currentdir()], {'*.txt'})
	test.assert_equal(ui.find.find_in_files_filters[dir.dirname], {'*.txt'})
end)

test('replace should replace found text', function()
	buffer:append_text(find)
	ui.find.find_entry_text = find
	local replace = 'replacement' -- should not match find case-insensitively
	ui.find.replace_entry_text = replace
	ui.find.find_next()

	ui.find.replace()

	test.assert_equal(buffer:get_text(), replace)
	test.assert_equal(buffer.selection_empty, true)
	test.assert_equal(buffer.current_pos, buffer.length + 1)
end)

test('replace should select the next occurrence after replacing', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace
	ui.find.find_next()

	ui.find.replace()

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('replace should not unescape \\[bfnrtv] in normal replacement', function()
	buffer:append_text(find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = '\\t'
	ui.find.find_next()

	ui.find.replace()

	test.assert_equal(buffer:get_text(), '\\t')
end)

--- Searches for regex string *find* in subject string *text*, replaces all instances with
-- string *replace*, and returns the string result.
-- @param text Subject string to search.
-- @param find Regex string to find.
-- @param replace String to replace with.
-- @return replacement string
local function regex_replace(text, find, replace)
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:append_text(text)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace
	ui.find.find_next()

	ui.find.replace()

	return buffer:get_text()
end

test('replace should unescape \\[bfnrtv] in regex replacement', function()
	local result = regex_replace(find, find, '\\t')

	test.assert_equal(result, '\t')
end)

test('replace should unescape \\d with its captured text in regex replacements', function()
	local result = regex_replace(find, '(' .. find .. ')', '\\1')

	test.assert_equal(result, find)
end)

test('replace should unescape \\0 with the whole match in regex replacements', function()
	local result = regex_replace(find, find, '\\0')

	test.assert_equal(result, find)
end)

test('replace should unescape \\uXXXX with its UTF-8 char in regex replacements', function()
	local result = regex_replace(find, find, '\\u00A9')

	test.assert_equal(result, '©')
end)

test('replace should upper-case between \\U and \\E in regex replacements', function()
	local result = regex_replace(find .. find, find, '\\U\\0\\E')
	-- TODO: if previous search was for 'word', find_next() incorrectly advances search pos.

	test.assert_equal(result, find:upper() .. find)
end)
expected_failure()

test('replace should lower-case between \\L and \\E in regex replacements', function()
	local result = regex_replace(find:upper(), find, '\\L\\0\\E')

	test.assert_equal(result, find)
end)

test('replace should upper-case the next char after \\u in regex replacements', function()
	local result = regex_replace(find, find, '\\u\\0')

	test.assert_equal(result, find:gsub('^.', string.upper))
end)

test('replace should lower-case the next char after \\l in regex replacements', function()
	local find = find:upper()
	local result = regex_replace(find, find, '\\l\\0')

	test.assert_equal(result, find:gsub('^.', string.lower))
end)

test('replace should allow \\l inside \\U and \\E in regex replacements', function()
	local result = regex_replace(find, find, '\\U\\l\\0\\E')

	test.assert_equal(result, find:upper():gsub('^.', string.lower))
end)

test('replace should allow \\u inside \\L and \\E in regex replacements', function()
	local find = find:upper()
	local result = regex_replace(find, find, '\\L\\u\\0\\E')

	test.assert_equal(result, find:lower():gsub('^.', string.upper))
end)

test('replace all should replace all found occurrences', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), replace .. replace)
end)

test('replace all should have atomic undo', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = find:upper()
	ui.find.replace_all()

	buffer:undo()

	test.assert_equal(buffer:get_text(), find .. find)
end)

test('replace all should only replace in selected text', function()
	buffer:append_text(find .. ' ' .. find)
	buffer:word_right_end_extend()
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), replace .. ' ' .. find)
end)

test('replace all should preserve the selection, extending it if needed', function()
	buffer:append_text(find .. ' ' .. find)
	buffer:word_right_end_extend()
	ui.find.find_entry_text = find
	local longer_replace = replace .. replace
	ui.find.replace_entry_text = longer_replace

	ui.find.replace_all()

	test.assert_equal(buffer:get_sel_text(), longer_replace)
end)

test('replace all should replace all occurrences if one is selected', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace
	ui.find.find_next()

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), replace .. replace)
end)

test('replace all should handle replacing only within multiple selections', function()
	buffer:append_text(test.lines{find, find, find})
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace
	textadept.editing.select_word()
	textadept.editing.select_word()

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), test.lines{replace, replace, find})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), replace .. replace) -- Scintilla stores it this way
end)

test('replace all should handle zero-width matches', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	ui.find.find_entry_text = '.?'
	ui.find.replace_entry_text = replace

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), replace)
end)

test('replace all should not match ^ more than once per line', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	local find = '\t'
	buffer:append_text(find .. find)
	ui.find.find_entry_text = '^' .. find
	ui.find.replace_entry_text = ''

	ui.find.replace_all()

	test.assert_equal(buffer:get_text(), find)
end)

test('replace all should count the number of replacements made #skip', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find

	ui.find.replace_all()

	-- TODO: how to assert ui.statusbar_text was written to? Cannot mock it.
end)

test('ui.find.goto_file_found(true) should go to and select the next occurrence in the list',
	function()
		local file = 'file.txt'
		local dir<close> = test.tmpdir{[file] = find}
		find_in_files(dir.dirname, find)

		ui.find.goto_file_found(true)

		test.assert_equal(buffer.filename, dir / file)
		test.assert_equal(buffer:get_sel_text(), find)
	end)

test('ui.find.goto_file_found should not select in binary files', function()
	local binfile = 'binary'
	local dir<close> = test.tmpdir{[binfile] = '\0' .. find}
	find_in_files(dir.dirname, find)

	ui.find.goto_file_found(true)

	test.assert_equal(buffer.selection_empty, true)
	test.assert_equal(buffer.current_pos, 1)
end)

test('ui.find.goto_file_found should work if neither the ff view nor buffer is visible', function()
	local _<close> = test.mock(ui, 'tabs', true) -- for CURSES
	local file = 'file.txt'
	local dir<close> = test.tmpdir{[file] = find}
	find_in_files(dir.dirname, find)
	view:goto_buffer(-1)

	ui.find.goto_file_found(true)

	test.assert_equal(buffer.filename, dir / file)
	test.assert_equal(#_VIEWS, 1)
end)

test('ui.find.goto_file_found(false) should go to the previous file in the list', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{[file] = find, [subdir] = {[subfile] = find}}
	find_in_files(dir.dirname, find)

	local last_file
	for i = buffer.line_count, 1, -1 do
		local line = buffer:get_line(i)
		if line:find(find) then
			last_file = line:match('^[^:]+')
			break
		end
	end

	ui.find.goto_file_found(false)

	test.assert_equal(buffer.filename, dir / last_file)
end)

-- Coverage tests.

test('find should not affect buffer.tag for regex searches', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:append_text(find)
	ui.find.find_entry_text = '(' .. find .. ')'

	ui.find.find_next()

	test.assert_equal(buffer.tag[1], find)
end)

test('Esc should clear highlighted find results', function()
	local _<close> = test.mock(ui.find, 'highlight_all_matches', true)
	buffer:append_text(find .. ' ' .. find)
	ui.find.find_entry_text = find
	ui.find.find_next()

	test.type('esc')

	local highlighted_matches = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(highlighted_matches, {})
end)

test('ui.find.find_in_files should allow canceling the search', function()
	local dir<close> = test.tmpdir()
	local cancel_search = test.stub(true)
	local _<close> = test.mock(ui.dialogs, 'progress', cancel_search)
	find_in_files(dir.dirname, find)

	test.assert_equal(cancel_search.called, true)
	test.assert_contains(buffer:get_text(), _L['Find in Files aborted'])
end)

test('ui.find.find_in_files should indicate if nothing was found', function()
	local dir<close> = test.tmpdir()

	find_in_files(dir.dirname, find)

	test.assert_contains(buffer:get_text(), _L['No results found'])
end)

test('ui.find.find_in_files should handle binary files', function()
	local dir<close> = test.tmpdir{binary = '\0' .. find}

	find_in_files(dir.dirname, find)

	test.assert_contains(buffer:get_text(), 'binary:1:' .. _L['Binary file matches.'])
end)

test('Enter in the files found list should jump to that file', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{[file] = find}
	find_in_files(dir.dirname, find)
	buffer:line_up()
	buffer:line_up()

	test.type('\n')

	test.assert_equal(buffer.filename, dir / file)
end)

test('double-clicking in the files found list should jump to that file', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{[file] = find}
	find_in_files(dir.dirname, find)
	buffer:line_up()
	buffer:line_up()
	local line = buffer:line_from_position(buffer.current_pos)

	events.emit(events.DOUBLE_CLICK, buffer.current_pos, line) -- simulate

	test.assert_equal(buffer.filename, dir / file)
end)

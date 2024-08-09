-- Copyright 2020-2024 Mitchell. See LICENSE.

-- Test find and replace text.
local find = 'word'
local replace = find:upper()

events.connect(events.TEST_CLEANUP, function()
	if not ui.find.active then return end
	ui.find.incremental, ui.find.in_files = false, false
	ui.find.focus()
end)

test('ui.find.focus should raise an error for invalid arguments', function()
	if CURSES then return end -- blocks the UI
	local invalid_argment = function() ui.find.focus(true) end

	test.assert_raises(invalid_argment, 'table/nil expected')
end)

test('ui.find.focus activates the find & replace pane', function()
	if CURSES then return end -- blocks the UI
	ui.find.focus()

	test.assert_equal(ui.find.active, true)
end)

test('ui.find.find_next should emit an event', function()
	local event = test.stub(false) -- prevent default handler from searching
	local _<close> = test.connect(events.FIND, event, 1)
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {find, true})
end)

test('ui.find.find_prev should emit an event', function()
	local event = test.stub(false) -- prevent default handler from searching
	local _<close> = test.connect(events.FIND, event, 1)
	ui.find.find_entry_text = find

	ui.find.find_prev()

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {find, false})
end)

test('ui.find.replace should emit events', function()
	local replace_event = test.stub(false) -- prevent default handler from replacing
	local find_event = test.stub(false) -- prevent default handler from searching
	local _<close> = test.connect(events.REPLACE, replace_event, 1)
	local _<close> = test.connect(events.FIND, find_event, 1)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace

	ui.find.replace()

	test.assert_equal(replace_event.called, true)
	test.assert_equal(replace_event.args, {replace})
	test.assert_equal(find_event.called, true)
	test.assert_equal(find_event.args, {find, true})
end)

test('ui.find.replace_all should emit an event', function()
	local event = test.stub(false) -- prevent default handler from replacing
	local _<close> = test.connect(events.REPLACE_ALL, event, 1)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = replace

	ui.find.replace_all()

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {find, replace})
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

test('find should repeatedly search for occurrences', function()
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

test('find should not scroll the view if it could not find anything', function()
	buffer:append_text(test.lines(100))
	buffer:goto_pos(buffer.length)
	local first_visible_line = view.first_visible_line
	ui.find.find_entry_text = 'will not be found'

	ui.find.find_next()

	test.assert_equal(view.first_visible_line, first_visible_line)
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
	test.assert_equal(buffer.selection_end, 5)
end)

test('find should search case-insensitively by default', function()
	buffer:append_text(find:upper())
	ui.find.find_entry_text = find

	ui.find.find_next()

	test.assert_equal(buffer:get_sel_text(), find:upper())
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
	buffer:append_text(string.format('%s%s %s', find, find, find))
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
expected_failure() -- Scintilla bug?

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

test('find should not highlight results if by default', function()
	buffer:append_text(find .. ' ' .. find)
	ui.find.find_entry_text = find

	ui.find.find_next()
	local no_highlights = test.get_indicated_text(ui.find.INDIC_FIND)

	test.assert_equal(no_highlights, {})
end)

test('find should not affect buffer.tag for regex searches', function()
	local _<close> = test.mock(ui.find, 'regex', true)
	buffer:append_text(find)
	ui.find.find_entry_text = '(' .. find .. ')'

	ui.find.find_next()

	test.assert_equal(buffer.tag[1], find)
end)

test('find should allow searching incrementally with typing', function()
	if CURSES then return end -- blocks the UI
	buffer:append_text(find)
	ui.find.focus{find_entry_text = '', incremental = true}

	test.type(find)

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('find should retain the incremental search anchor even for failures', function()
	if CURSES then return end -- blocks the UI
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

test('find should move the incremental search anchor on successful Enter/find next', function()
	if CURSES then return end -- blocks the UI
	buffer:append_text(find .. find)
	ui.find.focus{find_entry_text = '', incremental = true}

	local first_char, rest = find:match('^(.)(.+)$')
	test.type(first_char)
	test.type('\n')
	test.type(rest)

	test.assert_equal(buffer.selection_start, buffer.length + 1 - #find)
	test.assert_equal(buffer.selection_end, buffer.length + 1)
end)

test('find should not move the incremental search anchor on failed Enter/find next', function()
	if CURSES then return end -- blocks the UI
	buffer:append_text(find .. find)
	ui.find.focus{find_entry_text = '', incremental = true}

	test.type('z\n')
	test.type('\b' .. find)

	test.assert_equal(buffer.selection_start, 1)
	test.assert_equal(buffer.selection_end, 1 + #find)
end)

test('ui.find.focus with in_files should show the default filter in the replace entry', function()
	if CURSES then return end -- blocks the UI
	ui.find.focus{in_files = true}

	test.assert_equal(ui.find.replace_entry_text, table.concat(lfs.default_filter, ','))
end)

test('ui.find.focus without in_files should restore replace entry text', function()
	if CURSES then return end -- blocks the UI
	ui.find.replace_entry_text = ''
	ui.find.focus{in_files = true}

	ui.find.focus()

	test.assert_equal(ui.find.in_files, false)
	test.assert_equal(ui.find.replace_entry_text, '')
end)

test('ui.find.focus with in_files should use a project-specific filter if possible', function()
	if CURSES then return end -- blocks the UI
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}
	ui.find.find_in_files_filters[dir] = '*.txt'
	io.open_file(dir .. '/file.txt')

	ui.find.focus{in_files = true}

	test.assert_equal(ui.find.replace_entry_text, '*.txt')
end)

test('find should allow searching in files and output results to a new buffer', function()
	if CURSES then return end -- blocks the UI
	local dir, _<close> = test.tempdir{['file.txt'] = find, subdir = {['subfile.txt'] = find}}
	local select_directory = test.stub(dir)
	local _<close> = test.mock(ui.dialogs, 'open', select_directory)
	ui.find.focus{find_entry_text = find, in_files = true}

	ui.find.find_next()
	local highlighted_results = test.get_indicated_text(ui.find.INDIC_FIND)

	test.assert_equal(buffer._type, _L['[Files Found Buffer]'])
	test.assert_equal(buffer.current_pos, buffer.length + 1)
	local output = buffer:get_text()
	test.assert(output:find(_L['Find:']:gsub('[_&]', '') .. ' ' .. ui.find.find_entry_text),
		'should have output search text')
	test.assert(output:find(_L['Directory:'] .. ' ' .. dir), 'should have output directory searched')
	test.assert(output:find(_L['Filter:']:gsub('[_&]', '')), 'should have output search filter')

	test.assert(output:find('file%.txt:1:' .. find), 'should have found file.txt')
	test.assert(output:find('subfile%.txt:1:' .. find), 'should have found subfile.txt')

	test.assert_equal(highlighted_results, {find, find})
end)

test('ui.find.find_in_files should raise errors for invalid arguments', function()
	local invalid_directory = function() ui.find.find_in_files({}) end
	local invalid_filter = function() ui.find.find_in_files('', true) end

	test.assert_raises(invalid_directory, 'string/nil expected')
	test.assert_raises(invalid_filter, 'string/table/nil expected')
end)

test('ui.find.find_in_files should update the filter if changed', function()
	local dir, _<close> = test.tempdir({}, true)
	ui.find.find_entry_text = 'does not matter'
	ui.find.replace_entry_text = '*.txt'

	ui.find.find_in_files(dir)

	test.assert_equal(ui.find.find_in_files_filters[lfs.currentdir()], {'*.txt'})
	test.assert_equal(ui.find.find_in_files_filters[dir], {'*.txt'})
end)

test('ui.find.find_in_files should allow canceling the search', function()
	local dir, _<close> = test.tempdir()
	local cancel = test.stub(true)
	local _<close> = test.mock(ui.dialogs, 'progress', cancel)

	ui.find.find_in_files(dir)

	test.assert(buffer:get_text():find(_L['Find in Files aborted']), 'should have notified of cancel')
end)

test('ui.find.find_in_files should indicate if nothing was found', function()
	local dir, _<close> = test.tempdir{'file.txt'}
	ui.find.find_entry_text = 'will find nothing'

	ui.find.find_in_files(dir)

	test.assert(buffer:get_text():find(_L['No results found']), 'should have said no results found')
end)

test('ui.find.find_in_files should handle binary files', function()
	local dir, _<close> = test.tempdir{binary = '\0' .. find}
	ui.find.find_entry_text = find

	ui.find.find_in_files(dir)

	test.assert(buffer:get_text():find('binary:1:' .. _L['Binary file matches.']),
		'should have found binary file')
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

test('replace should not replace text not found', function()
	ui.find.replace_entry_text = 'nothing to replace'

	ui.find.replace()

	test.assert_equal(buffer.length, 0)
end)

test('replace should select the next occurrence after replacing', function()
	buffer:append_text(find .. find)
	ui.find.find_entry_text = find
	ui.find.replace_entry_text = 'replacement'
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

test('ui.find.goto_file_found should raise errors for invalid arguments', function()
	local invalid_location = function() ui.find.goto_file_found('') end

	test.assert_raises(invalid_location, 'boolean/number expected')
end)

test('ui.find.goto_file_found(true) should go to the next file found in the list', function()
	local dir, _<close> = test.tempdir{['file.txt'] = find, subdir = {['subfile.txt'] = find}}
	local file = lfs.abspath(dir .. '/file.txt')
	local subfile = lfs.abspath(dir .. '/subdir/subfile.txt')

	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)

	ui.find.goto_file_found(true)
	local first_filename = buffer.filename
	ui.find.goto_file_found(true)
	local second_filename = buffer.filename

	test.assert_equal(first_filename, file)
	test.assert_equal(second_filename, subfile)
end)

test('ui.find.goto_file_found should select the occurrence', function()
	local dir, _<close> = test.tempdir{['file.txt'] = find}
	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)

	ui.find.goto_file_found(true)

	test.assert_equal(buffer:get_sel_text(), find)
end)

test('ui.find.goto_file_found should not select in binary files', function()
	local dir, _<close> = test.tempdir{binary = '\0' .. find}
	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)

	ui.find.goto_file_found(true)

	test.assert_equal(buffer.selection_empty, true)
	test.assert_equal(buffer.current_pos, 1)
end)

test('ui.find.goto_file_found should work if neither the ff view nor buffer is visible', function()
	local _<close> = test.mock(ui, 'tabs', true)
	local dir, _<close> = test.tempdir{['file.txt'] = find, subdir = {['subfile.txt'] = find}}
	local subfile = lfs.abspath(dir .. '/subdir/subfile.txt')

	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)
	view:goto_buffer(-1)

	ui.find.goto_file_found(true)
	ui.find.goto_file_found(true)

	test.assert_equal(buffer.filename, subfile)
	test.assert_equal(#_VIEWS, 1)
end)

test('ui.find.goto_file_found(false) should go to the previous file in the list', function()
	local dir, _<close> = test.tempdir{['file.txt'] = find, subdir = {['subfile.txt'] = find}}
	local subfile = lfs.abspath(dir .. '/subdir/subfile.txt')

	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)

	ui.find.goto_file_found(false)

	test.assert_equal(buffer.filename, subfile)
end)

test('Enter in the files found list should jump to that file', function()
	local dir, _<close> = test.tempdir{['file.txt'] = find}
	local file = lfs.abspath(dir .. '/file.txt')
	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)
	buffer:line_up()
	buffer:line_up()

	test.type('\n')

	test.assert_equal(buffer.filename, file)
end)

test('double-clicking in the files found list should jump to that file', function()
	local dir, _<close> = test.tempdir{['file.txt'] = find}
	local file = lfs.abspath(dir .. '/file.txt')
	ui.find.find_entry_text = find
	ui.find.find_in_files(dir)
	buffer:line_up()
	buffer:line_up()
	local line = buffer:line_from_position(buffer.current_pos)

	events.emit(events.DOUBLE_CLICK, buffer.current_pos, line)

	test.assert_equal(buffer.filename, file)
end)

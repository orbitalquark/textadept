-- Copyright 2020-2024 Mitchell. See LICENSE.

test('editing.toggle_comment should comment out the current line', function()
	local comment_char = '#'
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_char)
	local line = 'text'
	buffer:append_text(line)

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), comment_char .. line)
	test.assert_equal(buffer.current_pos, 1 + #comment_char)
end)

test('editing.toggle_comment should uncomment the current line', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local line = 'text'
	buffer:append_text(line)
	textadept.editing.toggle_comment()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), line)
	test.assert_equal(buffer.current_pos, 1)
end)

test('editing.toggle_comment should comment out the selected lines', function()
	local comment_char = '#'
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_char)
	buffer:append_text(test.lines{'12', '23', ''})
	buffer:char_right()
	local offset = 1 -- from line start
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#12', '#23', ''})
	test.assert_equal(buffer.anchor, 1 + offset + #comment_char)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + offset + #comment_char)
end)

test('editing.toggle_comment should uncomment the selected lines', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'12', '23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	local offset = 1 -- from line start
	buffer:line_down_extend()
	textadept.editing.toggle_comment()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), lines)
	test.assert_equal(buffer.anchor, 1 + offset)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + offset)
end)

test('editing.toggle_comment should not include the last line if no part is selected', function()
	local comment_char = '#'
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_char)
	buffer:append_text(test.lines{'1', ''})
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{comment_char .. '1', ''})
end)

test('editing.toggle_comment should handle mixed comments', function()
	local comment_char = '#'
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_char)
	buffer:append_text(test.lines{'1', comment_char .. '2', ''})
	buffer:line_down_extend()
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{comment_char .. '1', '2', ''})
end)

test('editing.toggle_comment should allow block comments', function()
	local comment_char = '#'
	local comment_string = comment_char .. '|' .. comment_char
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_string)
	local lines = test.lines{'12', '23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	local offset = 1 -- from line start
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#12#', '#23#', ''})
	test.assert_equal(buffer.anchor, 1 + offset + #comment_char)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + offset + #comment_char)
end)

test('editing.toggle_comment should allow uncommenting block comments', function()
	local comment_char = '#'
	local comment_string = comment_char .. '|' .. comment_char
	local _<close> = test.mock(textadept.editing.comment_string, 'text', comment_string)
	local lines = test.lines{'12', '23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	local offset = 1 -- from line start
	buffer:line_down_extend()
	textadept.editing.toggle_comment()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), lines)
	test.assert_equal(buffer.anchor, 1 + offset)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + offset)
end)

test('editing.toggle_comment should have atomic undo', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'1', '2', ''}
	buffer:append_text(lines)
	buffer:select_all()
	textadept.editing.toggle_comment()

	buffer:undo()

	test.assert_equal(buffer:get_text(), lines)
end)

test('editing.goto_line should go to a given line', function()
	test.type('\n')

	textadept.editing.goto_line(1)

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, 1)
end)

test('editing.goto_line should prompt for a line to go to if none was given', function()
	test.type('\n')
	local return_1 = test.stub('1')
	local _<close> = test.mock(ui.dialogs, 'input', return_1)

	textadept.editing.goto_line()

	test.assert_equal(return_1.called, true)
	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, 1)
end)

test('--line command line argument should go to a given line', function()
	buffer:new_line()

	events.emit('command_line', {'--line', '1'}) -- simulate

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, 1)
end)

test('editing.join_lines should join the current line with the one below', function()
	buffer:append_text(test.lines{'1', '2'})

	textadept.editing.join_lines()

	test.assert_equal(buffer:get_text(), '1 2')
	test.assert_equal(buffer.current_pos, 2)
end)

test('editing.enclose should wrap the current word with given delimiters', function()
	local word = 'word'
	buffer:append_text(word .. ' ' .. word)

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), string.format('"%s" %s', word, word))
	test.assert_equal(buffer.current_pos, 1 + 1 + #word + 1)
end)

test('editing.enclose should wrap the selected text with the given delimiters', function()
	local text = 'word word'
	buffer:append_text(text)
	buffer:select_all()

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), '"' .. text .. '"')
end)

test('editing.enclose should wrap in all selections', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()
	local word = 'word'
	test.type(word)

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), test.lines{'"' .. word .. '"', '"' .. word .. '"'})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], buffer.line_end_position[1])
	test.assert_equal(buffer.selection_n_end[1], buffer.line_end_position[1])
	test.assert_equal(buffer.selection_n_start[2], buffer.line_end_position[2])
	test.assert_equal(buffer.selection_n_end[2], buffer.line_end_position[2])
end)

test('editing.enclose should allow selecting wrapped text', function()
	local word = 'word'
	buffer:append_text(word)

	textadept.editing.enclose('"', '"', true)

	test.assert_equal(buffer:get_sel_text(), word)
end)

test('editing.enclose should have atomic undo', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()
	local word = 'word'
	test.type('word')
	textadept.editing.enclose('"', '"')

	buffer:undo()

	test.assert_equal(buffer:get_text(), test.lines{word, word})
end)

test('editing.select_enclosed should select between given delimiters', function()
	local word = 'word'
	buffer:append_text('(' .. word .. ')')
	buffer:char_right()

	textadept.editing.select_enclosed('(', ')')

	test.assert_equal(buffer:get_sel_text(), word)
end)

test("editing.select_enclosed should recognize when it's between auto-pairs", function()
	local word = 'word'
	buffer:append_text('(' .. word .. ')')
	buffer:char_right()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), word)
end)

test('editing.select_enclosed should only select ranges that include the current pos', function()
	local enclosed = '(word) word'
	buffer:append_text('(' .. enclosed .. ')')
	buffer:line_end()
	buffer:char_left()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), enclosed)
end)

test("editing.select_enclosed should be able to recognize it's between XML tags", function()
	buffer:set_lexer('html')
	local text = 'text'
	buffer:append_text(test.lines{'<tag>', text, '</tag>'})
	buffer:line_down()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), test.lines{'', text, ''})
end)

test('editing.select_enclosed should select the delimiters when called again', function()
	local contents = '(word)'
	buffer:append_text(contents)
	buffer:char_right()
	textadept.editing.select_enclosed()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), contents)
end)

test('editing.select_enclosed should deselect the delimiters when called again', function()
	local word = 'word'
	buffer:append_text('(' .. word .. ')')
	buffer:select_all()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), word)
end)

test('editing.select_word should select the current word', function()
	local word = 'word'
	buffer:append_text(word .. ' ' .. word)

	textadept.editing.select_word()

	test.assert_equal(buffer:get_sel_text(), word)
end)

test('editing.select_word should select the next instance of the current word if already selected',
	function()
		local word = 'word'
		buffer:append_text(word .. ' ' .. word)
		textadept.editing.select_word()

		textadept.editing.select_word()

		test.assert_equal(buffer.selections, 2)
		test.assert_equal(buffer:get_sel_text(), word .. word) -- Scintilla stores it this way
	end)

test('editing.select_word should be able to select all instances of the current word', function()
	local word = 'word'
	buffer:append_text(word .. ' ' .. word)

	textadept.editing.select_word(true)

	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), word .. word) -- Scintilla stores it this way
end)

test('editing.select_word should only consider whole words with matching case', function()
	buffer:append_text('word word2 Word word')

	textadept.editing.select_word(true)

	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), 'wordword') -- Scintilla stores it this way
end)

test('editing.select_line should select the current line up to EOL', function()
	buffer:append_text(test.lines{'1', '2'})

	textadept.editing.select_line()

	test.assert_equal(buffer:get_sel_text(), '1')
end)

test('editing.select_line should extend multi-line selections', function()
	local contents = test.lines{'12', '23'}
	buffer:add_text(contents)
	buffer:char_right()
	buffer:line_up_extend()

	textadept.editing.select_line()

	test.assert_equal(buffer:get_sel_text(), contents)
end)

test('editing.select_paragraph should select the current paragraph', function()
	buffer:append_text(test.lines{'', '2', '', '4'})
	buffer:line_down()

	textadept.editing.select_paragraph()

	test.assert_equal(buffer:get_sel_text(), test.lines{'2', '', ''}) -- up to line 4
end)

test('editing.convert_indentation should convert from tabs to spaces', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	local lines = test.lines{'1', '\t2', '3'}
	buffer:append_text(lines)

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), lines:gsub('\t', string.rep(' ', buffer.tab_width)))
end)

test('editing.convert_indentation should convert from spaces to tabs', function()
	local _<close> = test.mock(buffer, 'tab_width', 4)
	local lines = test.lines{'1', '    2', '3'}
	buffer:append_text(lines)

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), lines:gsub(string.rep(' ', buffer.tab_width), '\t'))
end)

test('editing.convert_indentation should handle mixed indentation', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	local lines = test.lines{'1', '\t2', '  3'}
	buffer:append_text(lines)

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), lines:gsub('\t', string.rep(' ', buffer.tab_width)))
end)

test('editing.convert_indentation should have atomic undo', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	local content = test.lines{'1', '\t2', '3'}
	buffer:append_text(content)
	textadept.editing.convert_indentation()

	buffer:undo()

	test.assert_equal(buffer:get_text(), content)
end)

test('editing.paste_reindent should increase incoming indent to match', function()
	test.type('\t1\n')
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'2', '\t3', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'\t1', '\t2', '\t\t3', '\t'})
end)

test('editing.paste_reindent should decrease incoming indent to match', function()
	test.type('1\n')
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'\t2', '\t\t3', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'1', '2', '\t3', ''})
end)

test('editing.paste_reindent should indent extra below a fold header', function()
	local _<close> = test.tmpfile('.lua', test.lines{'if true then', 'end'}, true)
	buffer:line_down()
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'\t\tprint()', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'if true then', '\tprint()', 'end'})
end)

test('editing.paste_reindent should convert incoming tab indentation to spaces', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	test.type('  1\n')
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'\t2', '\t\t3', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'  1', '  2', '    3', '  '})
end)

test('editing.paste_reindent should convert incoming 4-space indentation to 2 spaces', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	test.type('  1\n')
	local _<close> = test.mock(ui, 'clipboard_text',
		test.lines{string.rep(' ', 4) .. '2', string.rep(' ', 8) .. '3', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'  1', '  2', '    3', '  '})
end)

test('editing.paste_reindent should convert incoming newlines (LF to CRLF)', function()
	local _<close> = test.mock(buffer, 'eol_mode', buffer.EOL_CRLF)
	local _<close> = test.mock(ui, 'clipboard_text', '1\n2')

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'1', '2'})
end)

test('editing.paste_reindent should have atomic undo', function()
	local contents = '\t'
	buffer:add_text(contents)
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'1', '2'})
	textadept.editing.paste_reindent()

	buffer:undo()

	test.assert_equal(buffer:get_text(), contents)
end)

test('editing.filter_through should pipe buffer text through a shell command', function()
	local lines = {'3', '1', '5', '4', '2'}
	buffer:append_text(test.lines(lines))

	textadept.editing.filter_through('sort')

	table.sort(lines)
	lines[#lines + 1] = ''
	test.assert_equal(buffer:get_text(), test.lines(lines))
end)

test('editing.filter_through should pipe selected text through a shell command', function()
	buffer:append_text(test.lines{'3', '1', '5', '4', '2'})
	buffer:line_down_extend()
	buffer:line_down_extend()

	textadept.editing.filter_through('sort')

	test.assert_equal(buffer:get_sel_text(), test.lines{'1', '3', ''})
	test.assert_equal(buffer:get_text(), test.lines{'1', '3', '5', '4', '2'})
end)

test('editing.filter_through should pipe multiple selections through a shell command', function()
	local word = 'word'
	buffer:append_text(word:gsub('^.', '%0%0') .. ' ' .. word:gsub('^.', '%0%0'))
	textadept.editing.select_word(true)

	textadept.editing.filter_through('sed -e "s/.//;"')

	test.assert_equal(buffer:get_text(), word .. ' ' .. word)
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), word .. word) -- Scintilla stores it this way
end)
if WIN32 then skip('sed does not exist') end

test('editing.filter_through should pipe a rectangular selection through a shell command',
	function()
		buffer:append_text(test.lines{'22', '13'})
		buffer:line_down_rect_extend()
		buffer:char_right_rect_extend()
		local offset = 1 -- from line start

		textadept.editing.filter_through('sort')

		test.assert_equal(buffer:get_text(), test.lines{'12', '23'})
		test.assert_equal(buffer.rectangular_selection_anchor, 1)
		test.assert_equal(buffer.rectangular_selection_caret, buffer:position_from_line(2) + offset)
	end)

test('editing.filter_through should allow pipes', function()
	buffer:append_text(test.lines{'3', '1', '5', '4', '2', '1'})

	textadept.editing.filter_through('sort | uniq')

	test.assert_equal(buffer:get_text(), test.lines{'1', '2', '3', '4', '5', ''})
end)
if WIN32 then skip('uniq does not exist') end

test('editing.filter_through should not do anything if output == input', function()
	local _<close> = test.tmpfile(test.lines{'input', ''}, true)

	textadept.editing.filter_through('sort')

	test.assert_equal(buffer.modify, false)
end)

test("editing.autocomplete('word') should show a list of word completions", function()
	local word = 'word'
	buffer:add_text(string.format('%s %s', word, word:sub(1, 1)))
	local auto_c_show = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', auto_c_show)
	local auto_c_active = test.stub(true)
	local _<close> = test.mock(buffer, 'auto_c_active', auto_c_active)

	local completions_found = textadept.editing.autocomplete('word')

	test.assert_equal(completions_found, true)
	test.assert_equal(auto_c_show.called, true)
	local items = auto_c_show.args[3]
	test.assert_equal(items, word)
end)

test("editing.autocomplete('word') should consider editing.autocomplete_all_words", function()
	local _<close> = test.mock(textadept.editing, 'autocomplete_all_words', true)
	local word = 'word'
	buffer:append_text(word .. word)
	buffer.new():add_text(word .. ' ' .. word:sub(1, 1))
	local auto_c_show = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', auto_c_show)

	textadept.editing.autocomplete('word')

	local items = {}
	for item in auto_c_show.args[3]:gmatch('%S+') do items[#items + 1] = item end
	test.assert_equal(items, {word .. word, word})
end)

test("editing.autocomplete('word') should allow for case-insensitive completions", function()
	local _<close> = test.mock(buffer, 'auto_c_ignore_case', true)
	local word = 'word'
	buffer:add_text(word:upper() .. ' ' .. word:sub(1, 1))
	local auto_c_show = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', auto_c_show)

	textadept.editing.autocomplete('word')

	local items = auto_c_show.args[3]
	test.assert_equal(items, word:upper())
end)

test('editing.autocomplete should return true even if an item was auto-selected', function()
	buffer:add_text('word w')

	local completions_found = textadept.editing.autocomplete('word')

	test.assert_equal(completions_found, true)
end)

test('editing.auto_pairs should auto-pair parentheses', function()
	test.type('(')

	test.assert_equal(buffer:get_text(), '()')
	test.assert_equal(buffer.current_pos, 2)
end)

test('editing.auto_pairs should auto-pair parentheses in all selections', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()

	test.type('(')

	test.assert_equal(buffer:get_text(), test.lines{'()', '()'})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], 2)
	test.assert_equal(buffer.selection_n_end[1], 2)
	test.assert_equal(buffer.selection_n_start[2], buffer:position_from_line(2) + 1)
	test.assert_equal(buffer.selection_n_end[2], buffer:position_from_line(2) + 1)
end)

test('editing.auto_pairs should have atomic undo', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()
	test.type('(')

	buffer:undo()

	test.assert_equal(buffer:get_text(), test.lines{'(', '('})
end)

test('editing.auto_pairs should remove both chars after backspace', function()
	test.type('(')

	test.type('\b')

	test.assert_equal(buffer.length, 0)
end)

test('editing.auto_pairs should remove both chars in all selections after backspace', function()
	local lines = test.lines(2, true)
	buffer:append_text(lines)
	buffer:line_down_rect_extend()
	test.type('(')

	test.type('\b')

	test.assert_equal(buffer:get_text(), lines)
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], 1)
	test.assert_equal(buffer.selection_n_end[1], 1)
	test.assert_equal(buffer.selection_n_start[2], buffer:position_from_line(2))
	test.assert_equal(buffer.selection_n_end[2], buffer:position_from_line(2))
end)

test('editing.auto_pairs should have atomic undo when removing chars', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()
	test.type('(')
	test.type('\b')
	buffer:undo() -- undo simulated backspace

	buffer:undo() -- normal undo the user would perform

	test.assert_equal(buffer:get_text(), test.lines{'()', '()'})
end)

test('editing.auto_pairs should handle UTF-8 characters', function()
	local _<close> = test.mock(textadept.editing, 'auto_pairs', {['“'] = '”'})

	test.type('“')
	local auto_paired = buffer:get_text()
	test.type('\b')
	local should_be_empty = buffer:get_text()

	test.assert_equal(auto_paired, '“”')
	test.assert_equal(should_be_empty, '')
end)

test('editing.typeover_auto_paired should type over auto-pairs', function()
	test.type('()')

	test.assert_equal(buffer:get_text(), '()')
end)

test('editing.typeover_auto_paired should type over auto-pairs in all selections', function()
	buffer:new_line()
	buffer:line_up_rect_extend()

	test.type('()')

	test.assert_equal(buffer:get_text(), test.lines{'()', '()'})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], buffer.line_end_position[2])
	test.assert_equal(buffer.selection_n_end[1], buffer.line_end_position[2])
	test.assert_equal(buffer.selection_n_start[2], 3)
	test.assert_equal(buffer.selection_n_end[2], 3)
end)

test('editing.typeover_auto_paired should not type over non-paired characters', function()
	local contents = 'text'
	buffer:append_text(contents)

	test.type(')')

	test.assert_equal(buffer:get_text(), ')' .. contents)
end)

test('editing.auto_indent should preserve indentation on Enter', function()
	test.type('\n')
	local line = buffer:line_from_position(buffer.current_pos)
	local no_indent = buffer.line_indentation[line]

	test.type('\t\n')
	local line = buffer:line_from_position(buffer.current_pos)
	local indent = buffer.line_indentation[line]

	test.assert_equal(no_indent, 0)
	test.assert_equal(indent, buffer.tab_width)
	test.assert_equal(buffer.current_pos, buffer.line_indent_position[line])
end)

test('editing.auto_indent should preserve indentation over blank lines', function()
	test.type('\t\n')
	buffer:back_tab() -- unindent

	test.type('\n')

	local line = buffer:line_from_position(buffer.current_pos)
	local indent = buffer.line_indentation[line]
	test.assert_equal(indent, buffer.tab_width)
end)

test('editing.auto_indent should not auto-indent an already indented line', function()
	buffer:append_text(test.lines{'\t', '\t'})
	buffer:line_down()

	test.type('\n')

	local line = buffer:line_from_position(buffer.current_pos)
	local indent = buffer.line_indentation[line]
	test.assert_equal(indent, buffer.tab_width)
end)

test('editing.auto_enclose should wrap selections in typed punctuation', function()
	local _<close> = test.mock(textadept.editing, 'auto_enclose', true)
	local word = 'word'
	buffer:append_text(word)
	buffer:select_all()

	test.type('"')

	test.assert_equal(buffer:get_text(), '"' .. word .. '"')
	test.assert_equal(buffer:get_sel_text(), word)
end)

test('editing.auto_enclose should consider auto-pairs when wrapping', function()
	local _<close> = test.mock(textadept.editing, 'auto_enclose', true)
	local word = 'word'
	buffer:append_text(word)
	buffer:select_all()

	test.type('(')

	test.assert_equal(buffer:get_text(), '(' .. word .. ')')
end)

--- Gives Scintilla a chance to process any cursor/selection changes and emit SCN_UPDATEUI.
local function process_selection_update()
	ui.update()
	if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
end

--- Returns a list of words highlighted by editing.INDIC_HIGHLIGHT.
local function get_highlighted_words()
	return test.get_indicated_text(textadept.editing.INDIC_HIGHLIGHT)
end

test('editing.highlight_words should allow highlighting all instances of the current word',
	function()
		local _<close> = test.mock(textadept.editing, 'highlight_words',
			textadept.editing.HIGHLIGHT_CURRENT)

		buffer:add_text('word word')
		process_selection_update()

		local highlighted_words = get_highlighted_words()
		test.assert_equal(highlighted_words, {'word', 'word'})
	end)

test('editing.highlight_words should not highlight non-words', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_CURRENT)

	buffer:add_text('- -')
	process_selection_update()

	local no_highlights = get_highlighted_words()
	test.assert_equal(no_highlights, {})
end)

test('editing.highlight_words should only consider whole words with matching case', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_CURRENT)

	buffer:add_text('word word2 Word word')
	process_selection_update()

	local highlighted_words = get_highlighted_words()
	test.assert_equal(highlighted_words, {'word', 'word'})
end)

test('editing.highlight_words should automatically clear any previous highlighting', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_CURRENT)
	buffer:add_text('word')
	process_selection_update() -- highlight

	buffer:add_text(' ')
	process_selection_update()

	local no_highlights = get_highlighted_words()
	test.assert_equal(no_highlights, {})
end)

test('editing.highlight_words should allow highlighting all instances of the selected word',
	function()
		local _<close> = test.mock(textadept.editing, 'highlight_words',
			textadept.editing.HIGHLIGHT_SELECTED)
		buffer:add_text('word word')

		textadept.editing.select_word()
		process_selection_update()

		local highlighted_words = get_highlighted_words()
		test.assert_equal(highlighted_words, {'word', 'word'})
	end)

test('editing.highlight_words should not highlight non-word selections', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_SELECTED)

	buffer:append_text('- -')
	buffer:char_right_extend()
	process_selection_update()
	local symbol_highlights = get_highlighted_words()

	buffer:set_text('word word')
	buffer:select_all()
	process_selection_update()
	local non_word_highlights = get_highlighted_words()

	test.assert_equal(symbol_highlights, {})
	test.assert_equal(non_word_highlights, {})
end)

if CURSES and not WIN32 then
	test('bracketed paste should disable auto-pair and auto-indent', function()
		local content = '\t()\n'

		events.emit(events.CSI, string.byte('~'), {200})
		local disabled_auto = not textadept.editing.auto_pairs and not textadept.editing.auto_indent
		test.type(content)
		events.emit(events.CSI, string.byte('~'), {201})
		local reenabled_auto = textadept.editing.auto_pairs and textadept.editing.auto_indent

		test.assert_equal(disabled_auto, true)
		test.assert_equal(buffer:get_text(), content)
		test.assert_equal(reenabled_auto, true)
	end)
end

test('buffer.save should strip trailing spaces if editing.strip_trailing_spaces is enabled',
	function()
		local _<close> = test.mock(textadept.editing, 'strip_trailing_spaces', true)
		local _<close> = test.tmpfile(test.lines{'text', '\t'}, true)

		buffer:save()

		test.assert_equal(buffer:get_text(), test.lines{'text', ''})
	end)

test('buffer.save should never strip trailing spaces for binary files', function()
	local _<close> = test.mock(textadept.editing, 'strip_trailing_spaces', true)
	local binary_contents = '\x00\xff\xff\x00 '
	local _<close> = test.tmpfile(binary_contents, true)

	buffer:save()

	test.assert_equal(buffer:get_text(), binary_contents)
end)

-- Coverage tests.

test('editing.filter_through should write command errors to the statusbar', function()
	textadept.editing.filter_through('false')

	-- TODO: how to assert ui.statusbar_text was written to? Cannot mock it.
end)
if WIN32 then skip('false does not exist') end

-- TODO: test highlight matching braces.

test('most languages should not auto-pair <>', function()
	test.assert_equal(textadept.editing.auto_pairs['<'], nil)
end)

test('some languages like HTML should auto-pair <>', function()
	buffer:set_lexer('html')

	test.assert_equal(textadept.editing.auto_pairs['<'], '>')
end)

test("most languages should not consider '-' to be a word character", function()
	test.assert(not buffer.word_chars:find('%-'), "'-' should not be a word character")
end)

test("some languages like HTML should consider '-' to be a word character", function()
	buffer:set_lexer('html')

	test.assert(buffer.word_chars:find('%-'), "'-' should be a word character")
end)

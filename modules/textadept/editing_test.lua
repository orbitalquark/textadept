-- Copyright 2020-2024 Mitchell. See LICENSE.

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

test('editing.auto_pairs should auto-pair parentheses', function()
	test.type('(')

	test.assert_equal(buffer:get_text(), '()')
	test.assert_equal(buffer.current_pos, 2)
end)

test('editing.auto_pairs should not auto-pair parentheses if disabled', function()
	local _<close> = test.mock(textadept.editing, 'auto_pairs', nil)

	test.type('(')

	test.assert_equal(buffer:get_text(), '(')
end)

test('editing.auto_pairs should auto-pair parentheses in all selections', function()
	buffer:new_line()
	buffer:line_up_rect_extend()

	test.type('(')

	test.assert_equal(buffer:get_text(), test.lines{'()', '()'})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], buffer:position_from_line(2) + 1)
	test.assert_equal(buffer.selection_n_end[1], buffer:position_from_line(2) + 1)
	test.assert_equal(buffer.selection_n_start[2], 2)
	test.assert_equal(buffer.selection_n_end[2], 2)
end)

test('editing.auto_pairs should have atomic undo', function()
	buffer:new_line()
	buffer:line_up_rect_extend()
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
	buffer:new_line()
	buffer:line_up_rect_extend()
	test.type('(')

	test.type('\b')

	test.assert_equal(buffer:get_text(), test.lines{'', ''})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], buffer:position_from_line(2))
	test.assert_equal(buffer.selection_n_end[1], buffer:position_from_line(2))
	test.assert_equal(buffer.selection_n_start[2], 1)
	test.assert_equal(buffer.selection_n_end[2], 1)
end)

test('editing.auto_pairs should have atomic undo when removing chars', function()
	buffer:new_line()
	buffer:line_up_rect_extend()
	test.type('(')
	test.type('\b')
	buffer:undo() -- undo simulated backspace

	buffer:undo() -- normal undo the user would perform

	test.assert_equal(buffer:get_text(), test.lines{'()', '()'})
end)

test('editing.auto_pairs should not cause trouble when backspacing multi-byte chars', function()
	buffer:add_text('(⌘⇧')
	buffer:goto_pos(buffer:position_before(buffer.current_pos)) -- char left

	test.type('\b') -- ⌘ does not have a complement
	test.type('\b') -- ⇧ is not a complement
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

test('editing.highlight_words should only consider whole words with matching case', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_CURRENT)
	buffer:add_text('word word2 Word word')

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

test('esc should clear highlighted words', function()
	local _<close> = test.mock(textadept.editing, 'highlight_words',
		textadept.editing.HIGHLIGHT_CURRENT)
	buffer:add_text('word')
	process_selection_update()

	test.type('esc')
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

test('editing.highlight_words should clear any previous highlighting when selecting text',
	function()
		local _<close> = test.mock(textadept.editing, 'highlight_words',
			textadept.editing.HIGHLIGHT_SELECTED)
		buffer:add_text('word')
		buffer:select_all()
		process_selection_update()

		buffer:char_right_extend()
		process_selection_update()
		local no_highlights = get_highlighted_words()

		test.assert_equal(no_highlights, {})
	end)

test('editing.highlight_words should do nothing by default', function()
	buffer:add_text('word')
	process_selection_update()
	local current_word_highlights = get_highlighted_words()

	buffer:select_all()
	process_selection_update()
	local selected_word_highlights = get_highlighted_words()

	test.assert_equal(current_word_highlights, {})
	test.assert_equal(selected_word_highlights, {})
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

test('editing.typeover_auto_paired should not type over auto-pairs if disabled', function()
	local _<close> = test.mock(textadept.editing, 'typeover_auto_paired', false)

	test.type('()')

	test.assert_equal(buffer:get_text(), '())')
end)

test('editing.auto_indent should preserve indentation on Enter', function()
	buffer:new_line()
	local no_indent = buffer.line_indentation[2]

	buffer:tab()
	buffer:new_line()
	local indent = buffer.line_indentation[3]

	test.assert_equal(no_indent, 0)
	test.assert_equal(indent, buffer.tab_width)
	test.assert_equal(buffer.current_pos, buffer.line_indent_position[3])
end)

test('editing.auto_indent should preserve indentation over blank lines', function()
	buffer:tab()
	buffer:new_line()
	buffer:back_tab()

	buffer:new_line()
	local indent = buffer.line_indentation[buffer.line_count]

	test.assert_equal(indent, buffer.tab_width)
end)

test('editing.auto_indent should not auto-indent an already indented line', function()
	buffer:tab()
	buffer:new_line()
	buffer:home()

	buffer:new_line()
	local indent = buffer.line_indentation[buffer.line_count]

	test.assert_equal(indent, buffer.tab_width)
end)

test('editing.auto_indent should do nothing if disabled', function()
	local _<close> = test.mock(textadept.editing, 'auto_indent', false)
	buffer:tab()

	buffer:new_line()
	local indent = buffer.line_indentation[buffer.line_count]

	test.assert_equal(indent, 0)
end)

if CURSES and not WIN32 then
	test('bracketed paste should disable auto-pair and auto-indent #now', function()
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

test('buffer:save should strip trailing spaces if editing.strip_trailing_spaces is enabled',
	function()
		local _<close> = test.mock(textadept.editing, 'strip_trailing_spaces', true)
		local filename, _<close> = test.tempfile()
		io.open_file(filename)
		buffer:append_text(test.lines{'text ', '\t'})

		buffer:save()

		test.assert_equal(buffer:get_text(), test.lines{'text', ''})
	end)

test('buffer:save should never strip trailing spaces for binary files', function()
	local _<close> = test.mock(textadept.editing, 'strip_trailing_spaces', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local binary_contents = ' '
	buffer:append_text(binary_contents)
	buffer.encoding = nil -- pretend it was detected as a binary file

	buffer:save()

	test.assert_equal(buffer:get_text(), binary_contents)
end)

test('buffer:save should not strip trailing spaces by default', function()
	local _<close> = test.mock(io, 'ensure_final_newline', false)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local contents = ' '
	buffer:append_text(contents)

	buffer:save()

	test.assert_equal(buffer:get_text(), contents)
end)

test('editing.paste_reindent should decrease incoming indent to match (tabs to tabs)', function()
	buffer:add_text('1')
	buffer:new_line()
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'\t2', '\t\t3', '\t4', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'1', '2', '\t3', '4', ''})
end)

test('editing.paste_reindent should convert incoming newlines (LF to CRLF)', function()
	local _<close> = test.mock(buffer, 'eol_mode', buffer.EOL_CRLF)
	local _<close> = test.mock(ui, 'clipboard_text', '1\n2')

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'1', '2'})
end)

test('editing.paste_reindent should increase incoming indent to match (tabs to tabs)', function()
	buffer:add_text('\t1')
	buffer:new_line()
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'2', '\t3', '4', ''})

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'\t1', '\t2', '\t\t3', '\t4', '\t'})
end)

test('editing.paste_reindent should convert incoming 4-space indentation to 2 spaces', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	buffer:add_text('  1')
	buffer:new_line()

	local tabs = test.lines{'\t2', '\t\t3', '\t4', ''}
	local spaces = tabs:gsub('\t', string.rep(' ', 4))
	local _<close> = test.mock(ui, 'clipboard_text', spaces)

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'  1', '  2', '    3', '  4', '  '})
end)

test('editing.paste_reindent should indent extra below a fold header', function()
	buffer:append_text(test.lines{'if true then', 'end'})
	buffer:set_lexer('lua')
	buffer:line_down()
	local _<close> = test.mock(ui, 'clipboard_text', 'print()' .. test.newline())

	textadept.editing.paste_reindent()

	test.assert_equal(buffer:get_text(), test.lines{'if true then', '\tprint()', 'end'})
end)
if GTK or LINUX and CURSES then expected_failure() end -- TODO:

test('editing.paste_reindent should have atomic undo', function()
	local contents = '\t'
	buffer:add_text(contents)
	local _<close> = test.mock(ui, 'clipboard_text', test.lines{'1', '2'})
	textadept.editing.paste_reindent()

	buffer:undo()

	test.assert_equal(buffer:get_text(), contents)
end)

test('editing.toggle_comment should comment out the current line', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local line = 'text'
	buffer:append_text(line)

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), '#' .. line)
end)

test('editing.toggle_comment should uncomment the current line', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local line = 'text'
	buffer:append_text(line)
	textadept.editing.toggle_comment()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), line)
end)

test('editing.toggle_comment should shift the caret during toggling', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local line = 'text'
	buffer:append_text(line)

	textadept.editing.toggle_comment()
	local commented_pos = buffer.current_pos

	textadept.editing.toggle_comment()
	local uncommented_pos = buffer.current_pos

	test.assert_equal(commented_pos, 2)
	test.assert_equal(uncommented_pos, 1)
end)

test('editing.toggle_comment should comment out the selected lines', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'12', '23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#12', '#23', ''})
	test.assert_equal(buffer.anchor, 3)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + 2)
end)

test('editing.toggle_comment should uncomment the selected lines', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'#12', '#23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	buffer:char_right()
	buffer:line_down_extend()
	buffer:swap_main_anchor_caret()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'12', '23', ''})
	test.assert_equal(buffer.anchor, 2)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + 1)
end)

test('editing.toggle_comment should not include the last line if no part is selected', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'1', ''}
	buffer:append_text(lines)
	buffer:line_down_rect_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#1', ''})
end)

test('editing.toggle_comment should handle mixed comments', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'1', '#2', ''}
	buffer:append_text(lines)
	buffer:line_down_extend()
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#1', '2', ''})
end)

test('editing.toggle_comment should allow suffixes when commenting', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#|#')
	local lines = test.lines{'12', '23', ''}
	buffer:append_text(lines)
	buffer:char_right()
	buffer:line_down_extend()
	buffer:swap_main_anchor_caret()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'#12#', '#23#', ''})
	test.assert_equal(buffer.anchor, 3)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + 2)
end)

test('editing.toggle_comment should allow suffixes when uncommenting', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#|#')
	local lines = test.lines{'#12#', '#23#', ''}
	buffer:append_text(lines)
	buffer:char_right()
	buffer:char_right()
	buffer:line_down_extend()

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), test.lines{'12', '23', ''})
	test.assert_equal(buffer.anchor, 2)
	test.assert_equal(buffer.current_pos, buffer:position_from_line(2) + 1)
end)

test('editing.toggle_comment should have atomic undo', function()
	local _<close> = test.mock(textadept.editing.comment_string, 'text', '#')
	local lines = test.lines{'1', '2', ''}
	buffer:append_text(lines)
	buffer:line_down_extend()
	buffer:line_down_extend()
	textadept.editing.toggle_comment()

	buffer:undo()

	test.assert_equal(buffer:get_text(), lines)
end)

test('editing.toggle_comment should do nothing for plain text', function()
	local line = 'line'
	buffer:append_text(line)

	textadept.editing.toggle_comment()

	test.assert_equal(buffer:get_text(), line)
end)

test('editing.goto_line should raise errors for invalid arguments', function()
	local not_a_number = function() textadept.editing.goto_line(true) end

	test.assert_raises(not_a_number, 'number/nil expected')
end)

test('editing.goto_line should go to a given line', function()
	buffer:new_line()

	textadept.editing.goto_line(1)
	local line = buffer:line_from_position(buffer.current_pos)

	test.assert_equal(line, 1)
end)

test('editing.goto_line should prompt for a line to go to if none was given', function()
	local return_1 = test.stub('1')
	local _<close> = test.mock(ui.dialogs, 'input', return_1)
	buffer:new_line()

	textadept.editing.goto_line()
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

test('editing.enclose should raise errors for invalid arguments', function()
	local not_a_string = function() textadept.editing.enclose(1) end
	local missing_second_arg = function() textadept.editing.enclose('*') end
	local invalid_third_arg = function() textadept.editing.enclose('(', ')', 1) end

	test.assert_raises(not_a_string, 'string expected')
	test.assert_raises(missing_second_arg, 'string expected')
	test.assert_raises(invalid_third_arg, 'boolean/nil expected')
end)

test('editing.enclose should wrap the current word with given delimiters', function()
	buffer:append_text('word word')

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), '"word" word')
	test.assert_equal(buffer.current_pos, 7)
end)

test('editing.enclose should wrap the selected text with the given delimiters', function()
	buffer:append_text('word word')
	buffer:select_all()

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), '"word word"')
end)

test('editing.enclose should wrap in all selections', function()
	buffer:new_line()
	buffer:line_up_rect_extend()
	test.type('word')

	textadept.editing.enclose('"', '"')

	test.assert_equal(buffer:get_text(), test.lines{'"word"', '"word"'})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[2], buffer.line_end_position[1])
	test.assert_equal(buffer.selection_n_end[2], buffer.line_end_position[1])
	test.assert_equal(buffer.selection_n_start[1], buffer.line_end_position[2])
	test.assert_equal(buffer.selection_n_end[1], buffer.line_end_position[2])
end)

test('editing.enclose should allow selecting wrapped text', function()
	buffer:append_text('word')

	textadept.editing.enclose('"', '"', true)

	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test('editing.enclose should have atomic undo', function()
	buffer:new_line()
	buffer:line_up_rect_extend()
	test.type('word')
	textadept.editing.enclose('"', '"')

	buffer:undo()

	test.assert_equal(buffer:get_text(), test.lines{'word', 'word'})
end)

test('editing.auto_enclose should wrap selections in typed punctuation', function()
	local _<close> = test.mock(textadept.editing, 'auto_enclose', true)
	buffer:append_text('word')
	buffer:select_all()

	test.type('"')

	test.assert_equal(buffer:get_text(), '"word"')
	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test('editing.auto_enclose should consider auto-pairs when wrapping', function()
	local _<close> = test.mock(textadept.editing, 'auto_enclose', true)
	buffer:append_text('word')
	buffer:select_all()

	test.type('(')

	test.assert_equal(buffer:get_text(), '(word)')
end)

test('editing.auto_enclose should do nothing by default', function()
	buffer:append_text('word')
	buffer:select_all()

	test.type('*')

	test.assert_equal(buffer:get_text(), '*')
end)

test('editing.select_enclosed should raise errors for invalid arguments', function()
	local missing_second_arg = function() textadept.editing.select_enclosed('*') end

	test.assert_raises(missing_second_arg, 'string expected')
end)

test('editing.select_enclosed should select between given delimiters', function()
	buffer:append_text('(word)')
	buffer:char_right()

	textadept.editing.select_enclosed('(', ')')

	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test("editing.select_enclosed should recognize when it's between auto-pairs", function()
	buffer:append_text('(word)')
	buffer:char_right()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test('editing.select_enclosed should not select a range before the current position', function()
	buffer:append_text('((word) word)')
	buffer:line_end()
	buffer:char_left()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), '(word) word')
end)

test("editing.select_enclosed should be able to recognize it's between XML tags", function()
	buffer:set_lexer('html')
	buffer:append_text('<tag>text</tag>')
	buffer:goto_pos(8)

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), 'text')
end)

test('editing.select_enclosed should select the delimiters when called again', function()
	local contents = '(word)'
	buffer:append_text(contents)
	buffer:char_right()
	textadept.editing.select_enclosed()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), contents)
end)

test('editing.select_enclosed should deselect the delimiters when called a third time', function()
	buffer:append_text('(word)')
	buffer:char_right()
	textadept.editing.select_enclosed()
	textadept.editing.select_enclosed()

	textadept.editing.select_enclosed()

	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test("editing.select_enclosed should not not select anything if it's not enclosed", function()
	buffer:append_text('word')

	textadept.editing.select_enclosed()

	test.assert_equal(buffer.selection_empty, true)
end)

test('editing.select_word should select the current word', function()
	buffer:append_text('word word')

	textadept.editing.select_word()

	test.assert_equal(buffer:get_sel_text(), 'word')
end)

test('editing.select_word should select the next instance of the current word if already selected',
	function()
		buffer:append_text('word word')
		textadept.editing.select_word()

		textadept.editing.select_word()

		test.assert_equal(buffer.selections, 2)
		test.assert_equal(buffer:get_sel_text(), 'wordword') -- Scintilla stores it this way
	end)

test('editing.select_word should be able to select all instances of the current word', function()
	buffer:append_text('word word')

	textadept.editing.select_word(true)

	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), 'wordword') -- Scintilla stores it this way
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

test('editing.select_paragraph should select the current paragraph', function()
	buffer:append_text(test.lines{'', '2', '', '4'})
	buffer:line_down()

	textadept.editing.select_paragraph()

	test.assert_equal(buffer:get_sel_text(), test.lines{'2', '', ''}) -- up to line 4
end)

test('editing.convert_indentation should convert from tabs to spaces', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	buffer:append_text(test.lines{'1', '\t2', '3'})

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), test.lines{'1', '  2', '3'})
end)

test('editing.convert_indentation should convert from spaces to tabs', function()
	local _<close> = test.mock(buffer, 'tab_width', 4)
	buffer:append_text(test.lines{'1', '    2', '3'})

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), test.lines{'1', '\t2', '3'})
end)

test('editing.convert_indentation should handle mixed indentation', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local _<close> = test.mock(buffer, 'tab_width', 2)
	buffer:append_text(test.lines{'1', '\t2', '  3'})

	textadept.editing.convert_indentation()

	test.assert_equal(buffer:get_text(), test.lines{'1', '  2', '  3'})
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

test('editing.filter_through should raise errors for invalid arguments', function()
	local not_a_string = function() textadept.editing.filter_through(test.stub()) end

	test.assert_raises(not_a_string, 'string expected')
end)

test('editing.filter_through should pipe buffer text through a shell command', function()
	buffer:append_text(test.lines{'3', '1', '5', '4', '2'})

	textadept.editing.filter_through('sort')

	test.assert_equal(buffer:get_text(), test.lines{'1', '2', '3', '4', '5', ''})
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
	if WIN32 then return end
	buffer:append_text('wword wword')
	textadept.editing.select_word(true)

	textadept.editing.filter_through('sed -e "s/.//;"')

	test.assert_equal(buffer:get_text(), 'word word')
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer:get_sel_text(), 'wordword') -- Scintilla stores it this way
end)

test('editing.filter_through should pipe a rectangular selection through a shell command',
	function()
		buffer:append_text(test.lines{'22', '13'})
		buffer:line_down_rect_extend()
		buffer:char_right_rect_extend()

		textadept.editing.filter_through('sort')

		test.assert_equal(buffer:get_text(), test.lines{'12', '23'})
		test.assert_equal(buffer.rectangular_selection_anchor, 1)
		test.assert_equal(buffer.rectangular_selection_caret, buffer:position_from_line(2) + 1)
	end)

test('editing.filter_through should allow pipes', function()
	if WIN32 then return end
	buffer:append_text(test.lines{'3', '1', '5', '4', '2', '1'})

	textadept.editing.filter_through('sort | uniq')

	test.assert_equal(buffer:get_text(), test.lines{'1', '2', '3', '4', '5', ''})
end)

test('editing.filter_through should not do anything if output == input', function()
	local filename, _<close> = test.tempfile()
	io.open(filename, 'w'):write(test.lines{'input', ''}):close()
	io.open_file(filename)

	textadept.editing.filter_through('sort')

	test.assert_equal(buffer.modify, false)
end)

test('editing.filter_through should write command errors to the statusbar #skip', function()
	if WIN32 then return end
	textadept.editing.filter_through('false')

	-- TODO: how to assert ui.statusbar_text was written to? Cannot mock it.
end)

test('editing.autocomplete should raise errors for invalid arguments', function()
	local not_a_string = function() textadept.editing.autocomplete(true) end

	test.assert_raises(not_a_string, 'string expected')
end)

test("editing.autocomplete('word') should show a list of word completions", function()
	buffer:add_text('word word2 w')

	local completions_found = textadept.editing.autocomplete('word')

	test.assert_equal(completions_found, true)
	test.assert_equal(buffer:auto_c_active(), true)
	test.assert_equal(buffer.auto_c_current_text, 'word')
end)

test("editing.autocomplete('word') should consider editing.autocomplete_all_words", function()
	local _<close> = test.mock(textadept.editing, 'autocomplete_all_words', true)
	buffer:add_text('word')
	buffer.new():add_text('word2 w')

	textadept.editing.autocomplete('word')

	test.assert_equal(buffer:auto_c_active(), true)
	test.assert_equal(buffer.auto_c_current_text, 'word')
end)

test("editing.autocomplete('word') should allow for case-insensitive completions", function()
	local _<close> = test.mock(buffer, 'auto_c_ignore_case', true)
	buffer:add_text('Word word2 w')

	textadept.editing.autocomplete('word')
	test.type('up') -- move to previous completion

	test.assert_equal(buffer:auto_c_active(), true)
	test.assert_equal(buffer.auto_c_current_text, 'Word')
end)

test('editing.autocomplete should return true even if an item was auto-selected', function()
	buffer:add_text('word w')

	local completions_found = textadept.editing.autocomplete('word')

	test.assert_equal(completions_found, true)
end)

test('editing.autocomplete should not return true if there were no completions', function()
	local completions_found = textadept.editing.autocomplete('word')

	test.assert_equal(not completions_found, true)
end)

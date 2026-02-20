-- Copyright 2020-2026 Mitchell. See LICENSE.

teardown(function()
	while textadept.snippets.active do textadept.snippets.cancel() end
end)

test('snippets.insert should act on trigger words', function()
	local trigger = 'trigger'
	local snippet = 'text'
	local _<close> = test.mock(snippets, trigger, snippet)
	buffer:add_text(trigger)

	textadept.snippets.insert()

	test.assert_equal(buffer:get_text(), snippet)
end)

test('snippets.insert should prefer language-specific triggers over global ones', function()
	local trigger = 'trigger'
	local global_snippet = 'global text'
	local language_snippet = 'language-specific text'
	local _<close> = test.mock(snippets, trigger, global_snippet)
	local _<close> = test.mock(snippets.text, trigger, language_snippet)
	buffer:add_text(trigger)

	textadept.snippets.insert()

	test.assert_equal(buffer:get_text(), language_snippet)
end)

test('snippets.insert should consider snippets in snippets.paths', function()
	local trigger = 'trigger'
	local global_snippet = 'global text'
	local language_snippet = 'language-specific text'
	local dir<close> = test.tmpdir{
		[trigger] = global_snippet, ['text.' .. trigger] = language_snippet
	}
	local _<close> = test.mock(textadept.snippets, 'paths', {dir.dirname})
	buffer:add_text(trigger)

	textadept.snippets.insert()

	test.assert_equal(buffer:get_text(), language_snippet)
end)

test('snippets.insert should return false if it did not insert anything', function()
	local inserted = textadept.snippets.insert()

	test.assert_equal(inserted, false)
end)

test('snippets.insert should match buffer indentation (convert tabs to spaces)', function()
	local _<close> = test.mock(buffer, 'use_tabs', false)
	local text = 'text'
	local snippet = '\t' .. text

	textadept.snippets.insert(snippet)

	local indent = string.rep(' ', buffer.tab_width)
	test.assert_equal(buffer:get_text(), indent .. text)
end)

test('snippets.insert should match buffer indentation (convert spaces to tabs)', function()
	local _<close> = test.mock(buffer, 'tab_width', 4)
	local text = 'text'
	local indent = string.rep(' ', buffer.tab_width)
	local snippet = indent .. text

	textadept.snippets.insert(snippet)

	test.assert_equal(buffer:get_text(), '\t' .. text)
end)

test('snippets.insert should increase indent to match', function()
	local _<close> = test.mock(buffer, 'tab_width', 4)
	local snippet = test.lines{'1', '\t2', '3'}
	buffer:add_text('\t')

	textadept.snippets.insert(snippet)

	local indented_snippet = '\t' .. snippet:gsub('\r?\n', '%0\t')
	test.assert_equal(buffer:get_text(), indented_snippet)
end)

test('snippets.insert should match EOL mode', function()
	local _<close> = test.mock(buffer, 'eol_mode', buffer.EOL_CRLF)
	local lines = {'1', '2'}
	local snippet = table.concat(lines, '\n')

	textadept.snippets.insert(snippet)

	test.assert_equal(buffer:get_text(), test.lines(lines))
end)

test('snippets should allow escaped text', function()
	textadept.snippets.insert('\\$1 \\${2} \\`\\`')

	test.assert_equal(buffer:get_text(), '$1 ${2} ``')
end)

test('snippets should allow variables', function()
	textadept.snippets.insert('$TM_LINE_NUMBER')

	test.assert_equal(buffer:get_text(), '1')
end)

test('snippets should allow user-defined variables', function()
	local value = 'value'
	local _<close> = test.mock(textadept.snippets.variables, 'VARIABLE', value)

	textadept.snippets.insert('$VARIABLE')

	test.assert_equal(buffer:get_text(), value)
end)

test('snippets should allow variable transforms', function()
	buffer:add_text('word')
	buffer:select_all()

	textadept.snippets.insert('${TM_SELECTED_TEXT/.+/${0:/capitalize}/}')

	test.assert_equal(buffer:get_text(), 'Word')
end)

test('snippets should allow shell code', function()
	local date_cmd = not WIN32 and 'date' or 'date /T'
	local p<close> = io.popen(date_cmd)
	local date = p:read()

	textadept.snippets.insert(string.format('`%s`', date_cmd))

	test.assert_equal(buffer:get_text(), date)
end)
retry(1) -- date can sometimes be off by one second

test('snippets should allow variables in shell code', function()
	local variable = not WIN32 and '$TM_LINE_INDEX' or '%TM_LINE_INDEX%'

	textadept.snippets.insert('`echo ' .. variable .. '`')

	test.assert_equal(buffer:get_text(), '0')
end)

test('snippets should allow Lua code', function()
	local date = os.date()

	textadept.snippets.insert('```os.date()```')

	test.assert_equal(buffer:get_text(), date)
end)

test('snippets should allow tab stops', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]

	test.assert_equal(buffer.current_pos, 2)
end)

--- Completes the snippet by tabbing through its remaining placeholders.
local function complete_snippet() while textadept.snippets.active do test.type('\t') end end

test('snippets.active should indicate an active snippet', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]
	local snippet_was_active = textadept.snippets.active
	complete_snippet()

	test.assert_equal(snippet_was_active, true)
	test.assert_equal(textadept.snippets.active, false)
end)

test('\t (via snippets.insert) should visit the next placeholder', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]

	test.type('1\t') -- [1, |, ]

	test.assert_equal(buffer.current_pos, 5)
end)

test('snippets should by default place the caret at their ends upon completion', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]
	complete_snippet() -- [, , ]|

	test.assert_equal(buffer.current_pos, buffer.length + 1)
end)

test('snippets should place the caret at the $0 placeholder, if it exists, upon completion',
	function()
		textadept.snippets.insert('$0[$1, $2, $3]') -- [|, , ]
		complete_snippet() -- |[, , ]

		test.assert_equal(buffer.current_pos, 1)
	end)

test('snippets should allow default values in placeholders', function()
	textadept.snippets.insert('[${1:1}, ${2:2}, ${3:3}]') -- [<1>, 2, 3]
	local first_placeholder = buffer:get_sel_text()
	complete_snippet()

	test.assert_equal(first_placeholder, '1')
	test.assert_equal(buffer:get_text(), '[1, 2, 3]')
end)

test('snippets should allow nested placeholders', function()
	textadept.snippets.insert('[${1:1${2:, 2, 3}}]') -- [<1>, 2, 3]

	test.type('\t') -- [1<, 2, 3>]

	test.assert_equal(buffer:get_sel_text(), ', 2, 3')
end)

test('\t should always visit the next available placeholder', function()
	textadept.snippets.insert('[${1:1, ${2:2}}, ${3:3}]') -- [<1, 2>, 3]
	local first_placeholder = buffer:get_sel_text()

	test.type('\b4\t') -- [4, <3>]
	local second_placeholder = buffer:get_sel_text()
	complete_snippet() -- [4, 3]

	test.assert_equal(first_placeholder, '1, 2')
	test.assert_equal(second_placeholder, '3')
	test.assert_equal(buffer:get_text(), '[4, 3]')
end)

test('snippets should allow mirrors', function()
	textadept.snippets.insert('[$1, $1]') -- [|, ]
	local initial_snippet = buffer:get_text()
	local selections = buffer.selections

	test.type('1\t') -- [1|, 1]
	complete_snippet()

	test.assert_equal(initial_snippet, '[, ] ') -- include sentinel
	test.assert_equal(selections, 2)
	test.assert_equal(buffer:get_text(), '[1, 1]')
	test.assert_equal(buffer.selections, 1)
end)

test('snippets mirrors should mirror a default value', function()
	textadept.snippets.insert('[$1, ${1:1}]') -- [<1>, <1>]
	local was_at_default_placeholder = buffer.selection_n_start[1] > buffer.selection_n_start[2]

	test.type('2') -- [2|, 2|]
	complete_snippet()

	test.assert_equal(was_at_default_placeholder, true)
	test.assert_equal(buffer:get_text(), '[2, 2]')
end)

test('snippets should allow mirrors in placeholders', function()
	textadept.snippets.insert('[${1:1}${2:, $1}]') -- [<1> <, 1>]

	test.type('2\t') -- [2<, 2>]

	test.assert_equal(buffer:get_sel_text(), ', 2')
end)

test('snippets should allow transforms', function()
	textadept.snippets.insert('${1:word} ${1/.+/${0:/upcase}/}') -- <word> <WORD>
	complete_snippet()

	test.assert_equal(buffer:get_text(), 'word WORD')
end)

test('transform placeholders should allow options', function()
	textadept.snippets.insert('${1:word} ${1/./${0:/upcase}/g}') -- <word> <WORD>
	complete_snippet()

	test.assert_equal(buffer:get_text(), 'word WORD')
end)

test('typing should update transforms', function()
	textadept.snippets.insert('${1:word} ${1/.+/${0:/upcase}/}') -- <word> <WORD>

	test.type('other') -- <other> <OTHER>
	complete_snippet()

	test.assert_equal(buffer:get_text(), 'other OTHER')
end)

test('snippets should ignore orphan transforms', function()
	textadept.snippets.insert('$0${2/.+/${0:/capitalize}/}')

	test.assert_equal(buffer.length, 0)
end)

test('snippets should allow conditional transforms and typing should update them', function()
	textadept.snippets.insert('${1:word} ${1/^word$/${0:?true:false}/}') -- <word> true
	local initial_snippet = buffer:get_text()

	test.type('no') -- no| false

	test.assert_equal(initial_snippet, 'word true ') -- include sentinel
	test.assert_equal(buffer:get_text(), 'no false ') -- include sentinel
end)

test('snippets should allow conditional transforms with captures', function()
	textadept.snippets.insert('${1:word} ${1/^word([0-9]*)$/${1:?true:false}/}') -- <word> false
	local initial_snippet = buffer:get_text()

	test.type('word2') -- [word2] true

	test.assert_equal(initial_snippet, 'word false ') -- include sentinel
	test.assert_equal(buffer:get_text(), 'word2 true ') -- include sentinel
end)

test('snippets should allow choices', function()
	local autocomplete = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', autocomplete)
	textadept.snippets.insert('[${1|1,2,3|}, 2, 3]') -- [<1>, 2, 3]

	test.assert_equal(autocomplete.called, true)
	local items = autocomplete.args[3]
	test.assert_equal(items, '1,2,3')
end)

test('snippets.insert should allow nested snippets', function()
	local snippet = '[${1:1}, ${2:2}]'
	textadept.snippets.insert(snippet) -- [<1>, 2]
	buffer:clear() -- [|, 2]
	textadept.snippets.insert(snippet) -- [[<1>, 2] , 2] (include sentinel)
	local placeholders = {buffer:get_sel_text()}

	test.type('\t') -- [[1, <2>], 2]
	placeholders[#placeholders + 1] = buffer:get_sel_text()
	test.type('\t') -- [[1, 2]|, 2]
	placeholders[#placeholders + 1] = buffer:get_sel_text()
	local no_placeholder_after_complete_nested = buffer.selection_empty
	local nested_end_pos = buffer.current_pos
	local a_snippet_was_still_active = textadept.snippets.active
	test.type('\t') -- [[1, 2], <2>]
	placeholders[#placeholders + 1] = buffer:get_sel_text()
	test.type('\t') -- [[1, 2], 2]|

	test.assert_equal(placeholders, {'1', '2', '', '2'})
	test.assert_equal(no_placeholder_after_complete_nested, true)
	test.assert_equal(nested_end_pos, 8)
	test.assert_equal(a_snippet_was_still_active, true)
	test.assert_equal(buffer:get_text(), '[[1, 2], 2]')
	test.assert_equal(textadept.snippets.active, false)
end)

test('snippets.previous should go back to a previous placeholder', function()
	textadept.snippets.insert('[${1:1}, ${2:2}, ${3:3}]') -- [<1>, 2, 3]
	test.type('\b\t') -- [, <2>, 3]

	textadept.snippets.previous() -- [<1>, 2, 3]

	test.assert_equal(buffer:get_sel_text(), '1')
	test.assert_equal(buffer:get_text(), '[1, 2, 3] ') -- include sentinel
end)

test('snippets.previous should cancel if there are no previous placeholders', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]

	textadept.snippets.previous()

	test.assert_equal(textadept.snippets.active, false)
	test.assert_equal(buffer.length, 0)
end)

test('snippets.cancel should cancel a snippet', function()
	textadept.snippets.insert('[$1, $2, $3]') -- [|, , ]

	test.type('1\t') -- [1, |, ]
	textadept.snippets.cancel()

	test.assert_equal(textadept.snippets.active, false)
	test.assert_equal(buffer.length, 0)
end)

test('snippets.cancel should resume an active snippet', function()
	local snippet = '[${1:1}, ${2:2}]'
	textadept.snippets.insert(snippet) -- [<1>, 2]
	buffer:char_right() -- [1|, 2]
	textadept.snippets.insert(snippet) -- [1[<1>, 2] , 2] (include sentinel)

	textadept.snippets.cancel() -- [1|, 2]
	local no_placeholder_after_cancel = buffer.selection_empty
	test.type('\t') -- [1, <2>]
	local next_placeholder_text = buffer:get_sel_text()
	complete_snippet()

	test.assert_equal(no_placeholder_after_cancel, true)
	test.assert_equal(next_placeholder_text, '2')
	test.assert_equal(buffer:get_text(), '[1, 2]')
end)

test('snippets.select should prompt for a snippet to insert', function()
	local trigger = 'trigger'
	local text = 'text'
	local _<close> = test.mock(snippets, trigger, text)
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	textadept.snippets.select()

	test.assert_equal(select_first_item.called, true)
	test.assert_equal(buffer:get_text(), text)
end)

test('snippets.select should recognize snippets in snippet.paths', function()
	local dir<close> = test.tmpdir{
		trigger1 = 'text1', --
		['trigger2.txt'] = 'text2', --
		['text.trigger3'] = 'text3', --
		['text.trigger4.txt'] = 'text4'
	}
	local _<close> = test.mock(textadept.snippets, 'paths', {dir.dirname})
	local cancel_select = test.stub()
	local _<close> = test.mock(ui.dialogs, 'list', cancel_select)

	textadept.snippets.select()

	test.assert_equal(cancel_select.called, true)
	local items = cancel_select.args[1].items
	test.assert_equal(items, {
		'trigger1', 'text1', 'trigger2', 'text2', 'trigger3', 'text3', 'trigger4', 'text4'
	})
end)

test("editing.autocomplete('snippet') should produce triggers", function()
	local trigger1 = 'trigger1'
	local trigger2 = 'trigger2'
	local snippet = 'text'
	local _<close> = test.mock(snippets, trigger1, snippet)
	local _<close> = test.mock(snippets, trigger2, snippet)
	local autocomplete = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', autocomplete)
	buffer:add_text(trigger1:sub(1, 1))

	textadept.editing.autocomplete('snippet')

	test.assert_equal(autocomplete.called, true)
	local cmpls = {}
	for cmpl in autocomplete.args[3]:gmatch('[^ ]+') do cmpls[#cmpls + 1] = cmpl end
	table.sort(cmpls)
	test.assert_equal(cmpls, {trigger1, trigger2})
end)

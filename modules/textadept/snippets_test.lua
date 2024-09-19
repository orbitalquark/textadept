-- Copyright 2020-2024 Mitchell. See LICENSE.

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

-- TODO: make these follow the AAA principle.

test('snippets.insert should visit placeholders in order', function()
	textadept.snippets.insert('$0${1:1} ${2:2}')

	test.assert_equal(textadept.snippets.active, true)
	test.assert_equal(buffer:get_sel_text(), '1')

	textadept.snippets.insert()

	test.assert_equal(buffer:get_sel_text(), '2')

	test.type('\t')

	test.assert_equal(textadept.snippets.active, false)
	test.assert_equal(buffer:get_text(), '1 2')
	test.assert_equal(buffer.current_pos, 1)
end)

test('snippets.insert should visit placeholders in order, even if they are irregular', function()
	textadept.snippets.insert('${1:1 ${2:2}}${5:5}')

	test.assert_equal(buffer:get_sel_text(), '1 2')

	test.type('\b\t')

	test.assert_equal(buffer:get_sel_text(), '5')

	test.type('\t')

	test.assert_equal(buffer:get_text(), '5')
end)

test('snippets.insert should mirror placeholders', function()
	textadept.snippets.insert('${1:1}$1')

	test.assert_equal(buffer:get_text(), '11 ')

	test.type('2\t')

	test.assert_equal(buffer:get_text(), '22')
end)

test('snippets.insert should update transforms', function()
	textadept.snippets.insert('${1:word} ${1/.+/${0:/upcase}/}')

	test.assert_equal(buffer:get_text(), 'word WORD ')

	test.type('other\t')

	test.assert_equal(buffer:get_text(), 'other OTHER')
end)

test('snippets.insert should handle unvisited transforms', function()
	textadept.snippets.insert('$0${2/.+/${0:/capitalize}/}')

	test.assert_equal(buffer.length, 0)
end)

test('snippets.insert should allow variables', function()
	textadept.snippets.insert('$TM_LINE_NUMBER')

	test.assert_equal(buffer:get_text(), '1')
end)

test('snippets.insert should allow user-defined variables', function()
	local value = 'value'
	local _<close> = test.mock(textadept.snippets.variables, 'VARIABLE', value)

	textadept.snippets.insert('$VARIABLE')

	test.assert_equal(buffer:get_text(), value)
end)

test('snippets.insert should allow choices', function()
	local autocomplete = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', autocomplete)
	textadept.snippets.insert('${1|1,2|}')

	test.assert_equal(autocomplete.called, true)
	local items = autocomplete.args[3]
	test.assert_equal(items, '1,2')
end)

test('snippets.insert should allow shell code', function()
	local date_cmd = not WIN32 and 'date' or 'date /T'
	local p<close> = io.popen(date_cmd)
	local date = p:read()

	textadept.snippets.insert(string.format('`%s`', date_cmd))

	test.assert_equal(buffer:get_text(), date)
end)

test('snippets.insert should allow variables in shell code', function()
	local variable = not WIN32 and '$TM_LINE_INDEX' or '%TM_LINE_INDEX%'

	textadept.snippets.insert('`echo ' .. variable .. '`')

	test.assert_equal(buffer:get_text(), '0')
end)

test('snippets.insert should allow Lua code', function()
	local date = os.date()

	textadept.snippets.insert('```os.date()```')

	test.assert_equal(buffer:get_text(), date)
end)

test('snippets.insert should allow escaped text', function()
	textadept.snippets.insert('\\$1 \\${2} \\`\\`')

	test.assert_equal(buffer:get_text(), '$1 ${2} ``')
end)

test('snippets.insert should allow nested snippets', function()
	local snippet = '${1:1}${2:2}${3:3}'

	textadept.snippets.insert(snippet)
	buffer:char_right()
	textadept.snippets.insert(snippet)

	test.assert_equal(buffer:get_sel_text(), '1')
	test.type('\t')
	test.assert_equal(buffer:get_sel_text(), '2')
	test.type('\t')
	test.assert_equal(buffer:get_sel_text(), '3')
	test.type('\t')
	test.assert_equal(buffer.selection_empty, true)
	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), '2')
	test.type('\t')
	test.assert_equal(buffer:get_sel_text(), '3')
	test.type('\t')

	test.assert_equal(buffer:get_text(), '112323')
end)

test('snippets.insert should allow mirrors in placeholders', function()
	textadept.snippets.insert('${1:1} ${2:2{$1\\}3}')

	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), '2{1}3')
end)

test('snippets.insert should allow nested placeholders', function()
	textadept.snippets.insert('${1:1}${2:{${3:3}\\}}')

	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), '{3}')

	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), '3')
end)

test('snippets.insert should allow more nested placeholders', function()
	textadept.snippets.insert('${1:1}(2${2:, ${3:3}})')

	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), ', 3')

	test.type('\t')

	test.assert_equal(buffer:get_sel_text(), '3')
end)

test('snippets.insert should allow transform options', function()
	textadept.snippets.insert('${1:word} ${1/./${0:/upcase}/g}')

	test.type('\t')

	test.assert_equal(buffer:get_text(), 'word WORD')
end)

test('snippets.previous should go back to a previous placeholder', function()
	textadept.snippets.insert('${1:1} ${2:2} ${3:3}')

	test.type('\b\t') -- clear '1' and move to '2'

	textadept.snippets.previous()

	test.assert_equal(buffer:get_sel_text(), '1')
	test.assert_equal(buffer:get_text(), '1 2 3 ')
end)

test('snippets.previous should cancel if there are no previous placeholders', function()
	textadept.snippets.insert('${1:1} ${2:2} ${3:3}')

	textadept.snippets.previous()

	test.assert_equal(textadept.snippets.active, false)
	test.assert_equal(buffer.length, 0)
end)

test('snippets.cancel should cancel a snippet', function()
	textadept.snippets.insert('${1:1}')

	textadept.snippets.cancel()

	test.assert_equal(textadept.snippets.active, false)
	test.assert_equal(buffer.length, 0)
end)

test('snippets.cancel should resume an active snippet', function()
	local snippet = '${1:1}${2:2}${3:3}'
	textadept.snippets.insert(snippet)
	buffer:char_right()
	textadept.snippets.insert(snippet)

	textadept.snippets.cancel()
	test.assert_equal(buffer.selection_empty, true)

	test.type('\t')
	test.assert_equal(buffer:get_sel_text(), '2')
	test.type('\t')
	test.type('\t')

	test.assert_equal(buffer:get_text(), '123')
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

test('snippets in snippet.paths should be recognized', function()
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
	test.assert_equal(cancel_select.args[1].items, {
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
	test.assert_equal(#cmpls, 2)
	-- TODO: Scintilla does not always sort these properly.
	-- local xpm = textadept.editing.XPM_IMAGES.NAMESPACE
	-- local sep = string.char(buffer.auto_c_type_separator)
	-- test.assert_equal(autocomplete.args[3], table.concat({
	--	trigger1 .. sep .. xpm, trigger2 .. sep .. xpm
	-- }, string.char(buffer.auto_c_separator)))
end)

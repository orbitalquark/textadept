-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Simulates clicking the given menu item.
-- @param item String menu path (e.g. 'File/New').
local function click(item) textadept.menu.menubar[item][2]() end

test('Edit > Delete Word should delete the current word', function()
	local word = 'word'
	buffer:add_text(word .. ' ' .. word)

	click('Edit/Delete Word')

	test.assert_equal(buffer:get_text(), word .. ' ')
end)

test('Edit > Match Brace should jump to a matching brace', function()
	buffer:append_text('()')

	click('Edit/Match Brace')

	local current_char = string.char(buffer.char_at[buffer.current_pos])
	test.assert_equal(current_char, ')')
end)

test('Edit > Complete Word should do so', function()
	local autocomplete = test.stub()
	local _<close> = test.mock(textadept.editing, 'autocomplete', autocomplete)

	click('Edit/Complete Word')

	test.assert_equal(autocomplete.called, true)
	local autocompleter = autocomplete.args[1]
	test.assert(textadept.editing.autocompleters[autocompleter],
		'should have used valid autocompleter')
end)

test('Edit > Filter Through should prompt to filter buffer text through a shell command', function()
	local run = test.stub()
	local _<close> = test.mock(ui.command_entry, 'run', run)

	click('Edit/Filter Through')

	test.assert_equal(run.called, true)
end)

test('Edit > Select > Deselect Word should drop the most recent multiple selection', function()
	local word = 'word'
	buffer:append_text(word .. ' ' .. word)
	textadept.editing.select_word()
	textadept.editing.select_word()

	click('Edit/Select/Deselect Word')

	test.assert_equal(buffer:get_sel_text(), word)
end)

test('Edit > Selection > Upper Case Selection should use the current word if nothing is selected',
	function()
		local word = 'word'
		buffer:add_text(word .. ' ' .. word)

		click('Edit/Selection/Upper Case Selection')

		test.assert_equal(buffer:get_text(), word .. ' ' .. word:upper())
	end)

test('Edit > Selection > Lower Case Selection should use the current word if nothing is selected',
	function()
		local word = 'WORD'
		buffer:add_text(word .. ' ' .. word)

		click('Edit/Selection/Lower Case Selection')

		test.assert_equal(buffer:get_text(), word .. ' ' .. word:lower())
	end)

test('Edit > Selection > Enclose as XML Tags should wrap selections in tags', function()
	local text = 'tag'
	buffer:append_text(test.lines{text, text})
	textadept.editing.select_word(true)

	click('Edit/Selection/Enclose as XML Tags')

	test.assert_equal(buffer:get_text(), test.lines{
		string.format('<%s></%s>', text, text), --
		string.format('<%s></%s>', text, text)
	})
	test.assert_equal(buffer.selections, 2)
	test.assert_equal(buffer.selection_n_start[1], 1 + #('<' .. text .. '>'))
	test.assert_equal(buffer:get_sel_text(), '')
end)

test('Edit > Selection > Enclose as XML Tags should have atomic undo', function()
	local text = 'tag'
	buffer:append_text(text)

	click('Edit/Selection/Enclose as XML Tags')
	buffer:undo()

	test.assert_equal(buffer:get_text(), text)
end)

test('Edit > Selection > Enclose as Single XML Tag should wrap selections', function()
	local text = 'tag'
	buffer:append_text(text)

	click('Edit/Selection/Enclose as Single XML Tag')

	test.assert_equal(buffer:get_text(), '<' .. text .. ' />')
end)

local enclosures = {
	['Single Quotes'] = "'", ['Double Quotes'] = '"', ['Parentheses'] = '(', ['Brackets'] = '[',
	['Braces'] = '{'
}
for name, auto_pair in pairs(enclosures) do
	test('Edit > Selection > Enclose in ' .. name .. ' should wrap selections', function()
		local text = 'word'
		buffer:append_text(text)

		click('Edit/Selection/Enclose in ' .. name)

		local s = auto_pair
		local e = textadept.editing.auto_pairs[s]
		test.assert_equal(buffer:get_text(), s .. text .. e)
	end)
end

test('Edit > Preferences should open _USERHOME/init.lua', function()
	click('Edit/Preferences')

	test.assert_equal(buffer.filename, lfs.abspath(_USERHOME .. '/init.lua'))
end)

test('Search > Find Incremental should start incremental search', function()
	local find_focus = test.stub()
	local _<close> = test.mock(ui.find, 'focus', find_focus)

	click('Search/Find Incremental')

	test.assert_equal(find_focus.called, true)
	test.assert_equal(find_focus.args[1].incremental, true)
end)

test('Search > Find in Files should start searching in files', function()
	local find_focus = test.stub()
	local _<close> = test.mock(ui.find, 'focus', find_focus)

	click('Search/Find in Files')

	test.assert_equal(find_focus.called, true)
	test.assert_equal(find_focus.args[1].in_files, true)
end)

test('Tools > Select Command should prompt for a command to run', function()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	click('Tools/Select Command') -- File > New

	test.assert_equal(#_BUFFERS, 2)
end)

test('Tools > Quick Open > Quickly Open User Home should do so', function()
	local quick_open = test.stub()
	local _<close> = test.mock(io, 'quick_open', quick_open)

	click('Tools/Quick Open/Quickly Open User Home')

	test.assert_equal(quick_open.called, true)
	test.assert_equal(quick_open.args, {_USERHOME})
end)

test('Tools > Quick Open > Quickly Open Textadept Home should do so', function()
	local quick_open = test.stub()
	local _<close> = test.mock(io, 'quick_open', quick_open)

	click('Tools/Quick Open/Quickly Open Textadept Home')

	test.assert_equal(quick_open.called, true)
	test.assert_equal(quick_open.args, {_HOME})
end)

test('Tools > Quick Open > Quickly Open Current Directory should do so', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{file}
	local quick_open = test.stub()
	local _<close> = test.mock(io, 'quick_open', quick_open)
	io.open_file(dir / file)

	click('Tools/Quick Open/Quickly Open Current Directory')

	test.assert_equal(quick_open.called, true)
	test.assert_equal(quick_open.args, {dir.dirname})
end)

test('Tools > Snippets > Complete Trigger Word should do so', function()
	local autocomplete = test.stub()
	local _<close> = test.mock(textadept.editing, 'autocomplete', autocomplete)

	click('Tools/Snippets/Complete Trigger Word')

	test.assert_equal(autocomplete.called, true)
	local autocompleter = autocomplete.args[1]
	test.assert(textadept.editing.autocompleters[autocompleter],
		'should have used valid autocompleter')
end)

test('Tools > Show Style should show a calltip with style info at the current position', function()
	local call_tip_show = test.stub()
	local _<close> = test.mock(view, 'call_tip_show', call_tip_show)
	buffer:append_text(' ')

	click('Tools/Show Style')

	test.assert_equal(call_tip_show.called, true)
	local calltip = call_tip_show.args[3]
	test.log(calltip)
	test.assert_contains(calltip, string.gsub("' ' (U+0020: 0x20)", '%p', '%%%0'))
	test.assert_contains(calltip, _L['Lexer'] .. ' text')
	test.assert_contains(calltip, _L['Style'] .. ' whitespace')
end)

for _, tab_width in ipairs{2, 3, 4, 8} do
	test('Buffer > Indentation > Tab width: ' .. tab_width .. ' should set the tab width', function()
		local _<close> = test.mock(buffer, 'tab_width', 1)

		click('Buffer/Indentation/Tab width: ' .. tab_width)

		test.assert_equal(buffer.tab_width, tab_width)
	end)
end

test('Buffer > Indentation > Toggle Use Tabs should toggle tab usage', function()
	local use_tabs = buffer.use_tabs

	click('Buffer/Indentation/Toggle Use Tabs')

	test.assert_equal(buffer.use_tabs, not use_tabs)
end)

test('Buffer > EOL Mode > CRLF should change the EOL mode', function()
	local _<close> = test.mock(buffer, 'eol_mode', buffer.EOL_LF)

	click('Buffer/EOL Mode/CRLF')

	test.assert_equal(buffer.eol_mode, buffer.EOL_CRLF)
end)

local encodings = {
	['UTF-8'] = 'UTF-8', ASCII = 'ASCII', ['CP-1252'] = 'CP1252', ['UTF-16'] = 'UTF-16LE'
}
for name, encoding in pairs(encodings) do
	test('Buffer > Encoding > ' .. name .. ' Encoding should set the encoding', function()
		local set_encoding = test.stub()
		local _<close> = test.mock(buffer, 'set_encoding', set_encoding)

		click('Buffer/Encoding/' .. name .. ' Encoding')

		test.assert_equal(set_encoding.called, true)
		test.assert_equal(set_encoding.args[2], encoding)
	end)
end

test('Buffer > Toggle Tab Bar should toggle tab bar visibility', function()
	local tabs = ui.tabs

	click('Buffer/Toggle Tab Bar')

	test.assert_equal(ui.tabs, not tabs)
end)

test('Buffer > Select Lexer... should prompt for a lexer selection', function()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	click('Buffer/Select Lexer...')

	test.assert_equal(buffer.lexer_language, lexer.names()[1])
end)

test('View > Unsplit All Views should do so', function()
	view:split()
	view:split()

	click('View/Unsplit All Views')

	test.assert_equal(#_VIEWS, 1)
end)

test('View > Grow View should do so', function()
	view:split()
	ui.goto_view(-1)
	local size = view.size

	click('View/Grow View')

	test.assert(view.size > size, 'should have grown view')
end)

test('View > Shrink View should do so', function()
	view:split()
	ui.goto_view(-1)
	local size = view.size

	click('View/Shrink View')

	test.assert(view.size < size or size == 0, 'should have shrunk view')
end)

test('View > Toggle Current Fold should do so', function()
	local _<close> = test.tmpfile('.lua', test.lines{'local t = {', '', '}'}, true)
	buffer:line_down()

	click('View/Toggle Current Fold')

	test.assert_equal(view.fold_expanded[1], false)
end)

test('View > Toggle Wrap Mode should do so and retain the first visible line', function()
	buffer:append_text(test.lines(100))
	buffer:goto_line(50)
	local first_visible_line = view.first_visible_line

	click('View/Toggle Wrap Mode')

	test.assert_equal(view.first_visible_line, first_visible_line)
end)

test('View > Toggle Margins should do so', function()
	local nonzero_widths = {}
	for i = 1, view.margins do nonzero_widths[i] = view.margin_width_n[i] end

	click('View/Toggle Margins')
	local hidden_widths = {}
	for i = 1, view.margins do hidden_widths[i] = view.margin_width_n[i] end

	click('View/Toggle Margins')
	local restored_widths = {}
	for i = 1, view.margins do restored_widths[i] = view.margin_width_n[i] end

	local zero_widths = {}
	for i = 1, view.margins do zero_widths[i] = 0 end
	test.assert_equal(hidden_widths, zero_widths)
	test.assert_equal(restored_widths, nonzero_widths)
end)

local view_settings = {
	['Show Indent Guides'] = 'indentation_guides', ['View Whitespace'] = 'view_ws',
	['Virtual Space'] = 'virtual_space_options'
}
for name, setting in pairs(view_settings) do
	test('View > Toggle ' .. name .. ' should do so', function()
		local value = view[setting]

		click('View/Toggle ' .. name)

		test.assert(view[setting] ~= value, 'should have toggled ' .. name)
	end)
end

for name, help in pairs{Manual = 'manual.html', LuaDoc = 'api.html'} do
	test('Help > Show ' .. name .. ' should do so', function()
		local spawn = test.stub()
		local _<close> = test.mock(os, 'spawn', spawn)

		click('Help/Show ' .. name)

		test.assert_equal(spawn.called, true)
		test.assert_contains(spawn.args[1], help)
	end)
end

test('Help > About should show about dialog', function()
	local message = test.stub()
	local _<close> = test.mock(ui.dialogs, 'message', message)

	click('Help/About')

	test.assert_equal(message.called, true)
end)

test('textadept.menu.menubar should be mutable', function()
	local label = 'Extra Item'
	local item = {label, function() end}

	table.insert(textadept.menu.menubar, {title = 'Extra Menu', item})

	test.assert_equal(textadept.menu.menubar['Extra Menu'][label], item)
end)

test('textadept.menu.context_menu should be mutable', function()
	local label = 'Context Label'
	local item = {label, function() end}

	local _<close> = test.mock(textadept.menu, 'context_menu', {item})

	test.assert_equal(textadept.menu.context_menu[label], item)
end)

test('textadept.menu.tab_context_menu should be mutable', function()
	local label = 'Context Label'
	local item = {label, function() end}

	local _<close> = test.mock(textadept.menu, 'tab_context_menu', {item})

	test.assert_equal(textadept.menu.tab_context_menu[label], item)
end)

-- Coverage tests.

test('textadept.menu.menubar should be hideable', function()
	textadept.menu.menubar = nil -- hide

	textadept.menu.menubar = textadept.menu.menubar -- show

	test.assert(textadept.menu.menubar['File'] ~= nil, 'should not have cleared menubar')
end)

test('textadept.menu should still act like a table', function()
	local key = 'key'
	local value = 'value'

	local _<close> = test.mock(textadept.menu, key, value)

	test.assert_equal(textadept.menu[key], value)
end)

-- TODO: ui.popup_menu

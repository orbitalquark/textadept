-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Returns the current buffer's syntax highlighting as a tag table:
--	{'function', 9, 'whitespace', 10, ...}.
-- @param offset Optional offset position to start at. The default value is 1.
-- @return tag table
local function get_syntax_highlighting(offset)
	local tags = {}
	if not offset then offset = 1 end
	local style_num = buffer.style_at[offset]
	local i = offset + 1
	while i <= buffer.length + 1 do
		if buffer.style_at[i] == style_num then goto continue end
		tags[#tags + 1] = buffer:name_of_style(style_num)
		tags[#tags + 1] = i
		style_num = buffer.style_at[i]
		::continue::
		i = i + 1
	end
	return tags
end

test('syntax highlighting should invoke Scintillua and style the buffer with the result', function()
	local _<close> = test.tmpfile('.lua', table.concat({
		'function foo(z)', --
		'	local x = 1', --
		'	local y = [[2]]', --
		'	print(x + y)', --
		'end'
	}, '\n'), true)

	local actual_tags = get_syntax_highlighting()
	local expected_tags = buffer.lexer:lex(buffer:get_text())
	test.assert_equal(actual_tags, expected_tags)
end)

test('syntax highlighting should support incremental highlighting', function()
	local _<close> = test.tmpfile('.lua', table.concat({
		'function foo(z)', --
		'	local x = 1', --
		'local y = [[2]]', -- intentional unindent
		'	print(x + y)', --
		'end'
	}, '\n'), true)
	local style_needed = test.stub()
	local _<close> = test.connect(events.STYLE_NEEDED, style_needed, 1)

	buffer.line_indentation[3] = buffer.tab_width -- indent line 3
	-- Trigger style needed.
	ui.update()
	if CURSES then events.emit(events.STYLE_NEEDED, buffer.length + 1, buffer) end

	test.wait(function() return style_needed.called end)

	local offset = buffer:position_from_line(3) -- lexing starts here
	local actual_tags = get_syntax_highlighting(offset)

	local text = buffer:get_text():sub(offset)
	local start_style_num = buffer:style_of_name('whitespace_lua')
	local expected_tags = buffer.lexer:lex(text, start_style_num)
	for i = 2, #expected_tags, 2 do expected_tags[i] = expected_tags[i] + offset - 1 end

	test.assert_equal(actual_tags, expected_tags)
end)

test('code folding should invoke Scintillua and mark fold headers with the result', function()
	local _<close> = test.tmpfile('.lua', table.concat({
		'function foo(z)', --
		'	local x = 1', --
		'	local y = [[2]]', --
		'	print(x + y)', --
		'end'
	}, '\n'), true)

	-- Construct a fold table from fold levels of the same form as the one returned by
	-- lex:fold(), which looks like {9216, 1025, ...}.
	local actual_folds = {}
	for i = 1, buffer.line_count do actual_folds[i] = buffer.fold_level[i] end

	local expected_folds = buffer.lexer:fold(buffer:get_text(), 1, buffer.FOLDLEVELBASE)

	test.assert_equal(actual_folds, expected_folds)
end)

local lexers = {}
for file in lfs.dir(_LEXERPATH:match('[^;]+$')) do -- just _HOME/lexers
	local name = file:match('^(.+)%.lua$')
	if name and name ~= 'lexer' then lexers[#lexers + 1] = name end
end
table.sort(lexers)

for _, name in ipairs(lexers) do
	test(name .. ' lexer should load and lex without error', function()
		buffer:append_text('text')
		buffer:set_lexer(name)
	end)
end

test('buffer.get_lexer should allow getting the current language in multi-language lexers',
	function()
		local _<close> = test.tmpfile('.html', table.concat({
			'<html><head><style type="text/css">', --
			'h1 {}', --
			'</style></head></html>'
		}, '\n'), true)
		buffer:line_down()

		local parent_lexer = buffer:get_lexer()
		local current_lexer = buffer:get_lexer(true)

		test.assert_equal(parent_lexer, 'html')
		test.assert_equal(current_lexer, 'css')
	end)

test('buffer.set_lexer should set the lexer', function()
	buffer:set_lexer('lua')

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('buffer.set_lexer should allow auto-detecting a lexer by filename', function()
	buffer.filename = 'file.lua'

	buffer:set_lexer()

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('buffer.set_lexer should allow auto-detecting a lexer by the first line of text', function()
	buffer:append_text('#!/bin/sh')

	buffer:set_lexer()

	test.assert_equal(buffer.lexer_language, 'bash')
end)

test('buffer.set_lexer should emit events.LEXER_LOADED', function()
	local event = test.stub()
	local _<close> = test.connect(events.LEXER_LOADED, event)

	buffer:set_lexer('lua')

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {'lua'})
end)

test('buffer.named_styles should reflect the number of lexer styles', function()
	buffer:set_lexer('lua')

	test.assert(buffer.named_styles > 0, 'should be more than one style defined')
end)

test('buffer.name_of_style should link style numbers with style names', function()
	local style_num = buffer.style_at[buffer.current_pos]

	local style_name = buffer:name_of_style(style_num)
	local unknown_style_name = buffer:name_of_style(view.STYLE_MAX)

	test.assert_equal(style_name, 'whitespace')
	test.assert_equal(unknown_style_name, 'Unknown')
end)

test('buffer.style_of_name should link style names with style numbers', function()
	local default_style_num = buffer:style_of_name(lexer.DEFAULT)
	local unknown_style_num = buffer:style_of_name('unknown')
	local non_default_style_num = buffer:style_of_name(lexer.STRING)

	test.assert_equal(default_style_num, view.STYLE_DEFAULT)
	test.assert_equal(unknown_style_num, view.STYLE_DEFAULT)
	test.assert(non_default_style_num ~= view.STYLE_DEFAULT, 'style should be defined')
end)

test('buffer.style_of_name should handle underscore and dot notation in style names', function()
	-- Scintillua uses dot notation (e.g. function.builtin) while Textadept uses underscore
	-- notation (e.g. function_builtin).
	local style_num_from_dot_notation = buffer:style_of_name(lexer.FUNCTION_BUILTIN)
	local style_num_from_underscore_notation = buffer:style_of_name('function_builtin')

	test.assert(style_num_from_dot_notation ~= view.STYLE_DEFAULT, 'style should be defined')
	test.assert_equal(style_num_from_dot_notation, style_num_from_underscore_notation)
end)

test('buffer.style_of_name should raises errors for invalid arguments', function()
	local not_style_name = function() buffer:style_of_name(33) end

	test.assert_raises(not_style_name, 'string expected')
end)

-- Coverage tests.

test('lexer errors should style the entire buffer the default style', function()
	local error_handler = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, error_handler, 1)
	local raise_error = function() error('') end
	local _<close> = test.mock(buffer.lexer, 'lex', raise_error)

	buffer:append_text('text')
	-- Tigger style needed.
	ui.update()
	if CURSES then events.emit(events.STYLE_NEEDED, buffer.length + 1, buffer) end

	if GTK then test.wait(function() return error_handler.called end) end
	test.assert_equal(error_handler.called, true)
	test.assert_equal(buffer.style_at[1], view.STYLE_DEFAULT)
	test.assert_equal(buffer.end_styled, buffer.length + 1)
end)

test('view should refresh its styles when switching between buffers with different lexers',
	function()
		buffer:set_lexer('html')

		local _<close> = test.tmpfile('.lua', '[[longstring]]', true)
		local longstring_style_num = buffer.style_at[1]
		local longstring_name = buffer:name_of_style(longstring_style_num)

		buffer:close() -- switch back to HTML
		local style_num = buffer:style_of_name(longstring_name)

		test.assert_equal(style_num, view.STYLE_DEFAULT) -- unknown
	end)

-- TODO: test view/scintilla <-> lexer api (e.g. view.folding = false disables lex:fold())

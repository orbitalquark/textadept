-- Copyright 2020-2024 Mitchell. See LICENSE.

test('buffer:get_lexer should default to text', function()
	local lexer = buffer:get_lexer()

	test.assert_equal(lexer, 'text')
end)

test('buffer:get_lexer should distinguish between child languages in multi-language lexers',
	function()
		local filename, _<close> = test.tempfile('html')
		io.open(filename, 'wb'):write(test.lines{
			'<html><head><style type="text/css">', --
			'h1 { color: red; }', --
			'</style></head></html>'
		}):close()
		io.open_file(filename)
		buffer:goto_pos(buffer:position_from_line(2))

		local lexer = buffer:get_lexer()
		local child = buffer:get_lexer(true)

		test.assert_equal(lexer, 'html')
		test.assert_equal(child, 'css')
	end)

test('buffer:set_lexer should raise errors for invalid arguments', function()
	local invalid_name = function() buffer:set_lexer(true) end

	test.assert_raises(invalid_name, 'string/nil expected')
end)

test('buffer:set_lexer should initialize the Scintillua lexer', function()
	buffer:set_lexer('lua')

	test.assert_equal(buffer.lexer_language, 'lua')
	test.assert_equal(type(buffer.lexer), 'table')
	test.assert(buffer.named_styles > 0, 'should have updated named styles')
end)

test('buffer:set_lexer should auto-detect a lexer by filename', function()
	buffer.filename = 'CMakeLists.txt'

	buffer:set_lexer()

	test.assert_equal(buffer.lexer_language, 'cmake')
end)

test('buffer:set_lexer should auto-detect a lexer by the first line of text like a shebang',
	function()
		buffer:set_text('#!/bin/sh')

		buffer:set_lexer()

		test.assert_equal(buffer.lexer_language, 'bash')
	end)

test('buffer:set_lexer should emit an event', function()
	local event = test.stub()
	local _<close> = test.connect(events.LEXER_LOADED, event)

	buffer:set_lexer('lua')

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {'lua'})
end)

test('buffer:name_of_style should raise errors for invalid arguments', function()
	local not_style_number = function() buffer:name_of_style('whitespace') end

	test.assert_raises(not_style_number, 'number expected')
end)

test('buffer:name_of_style should link style numbers with style names', function()
	local style_num = buffer.style_at[buffer.current_pos]

	local style_name = buffer:name_of_style(style_num)

	test.assert_equal(style_name, 'whitespace')
end)

test('buffer:style_of_name should raises errors for invalid arguments', function()
	local not_style_name = function() buffer:style_of_name(33) end

	test.assert_raises(not_style_name, 'string expected')
end)

test('buffer:style_of_name should link style names with style numbers', function()
	local default_style_num = buffer:style_of_name(lexer.DEFAULT)
	local non_default_style_num = buffer:style_of_name(lexer.STRING)

	test.assert_equal(default_style_num, view.STYLE_DEFAULT)
	test.assert(non_default_style_num ~= view.STYLE_DEFAULT, 'style should be defined')
end)

test('buffer:style_of_name should return the default style for an unknown style name', function()
	local style_num = buffer:style_of_name('unknown')

	test.assert_equal(style_num, view.STYLE_DEFAULT)
end)

test('buffer:style_of_name should handle underscore and dot notation in style names', function()
	-- Scintillua uses dot notation (e.g. function.builtin) while Textadept uses underscore
	-- notation (e.g. function_builtin).
	local style_num_from_dot_notation = buffer:style_of_name(lexer.FUNCTION_BUILTIN)
	local style_num_from_underscore_notation = buffer:style_of_name('function_builtin')

	test.assert(style_num_from_dot_notation ~= view.STYLE_DEFAULT, 'style should be defined')
	test.assert_equal(style_num_from_dot_notation, style_num_from_underscore_notation)
end)

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
	buffer:set_text(test.lines{
		'function foo(z)', --
		'	local x = 1', --
		'	local y = [[2]]', --
		'	print(x + y)', --
		'end'
	})

	buffer:set_lexer('lua')

	local actual_tags = get_syntax_highlighting()
	local expected_tags = buffer.lexer:lex(buffer:get_text())
	test.assert_equal(actual_tags, expected_tags)
end)

test('syntax highlighting should be performed incrementally', function()
	buffer:set_text(test.lines{
		'function foo(z)', --
		'	local x = 1', --
		'local y = [[2]]', -- intentional unindent
		'	print(x + y)', --
		'end'
	})
	buffer:set_lexer('lua')
	local event = test.stub()
	local _<close> = test.connect(events.STYLE_NEEDED, event, 1)
	buffer.line_indentation[3] = buffer.tab_width

	ui.update() -- trigger style needed

	test.assert_equal(event.called, true)

	local offset = buffer:position_from_line(3) -- lexing starts here
	local actual_tags = get_syntax_highlighting(offset)

	local text = buffer:get_text():sub(offset)
	local start_style_num = buffer:style_of_name('whitespace_lua')
	local expected_tags = buffer.lexer:lex(text, start_style_num)
	for i = 2, #expected_tags, 2 do expected_tags[i] = expected_tags[i] + offset - 1 end

	test.assert_equal(actual_tags, expected_tags)
end)

test('lexer errors should style the entire buffer the default style', function()
	local error_handler = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, error_handler, 1)
	local error_message = 'error!'
	local raise_error = function() error(error_message) end
	local _<close> = test.mock(buffer.lexer, 'lex', raise_error)
	buffer:set_text('text')

	ui.update() -- trigger style needed

	test.assert_equal(buffer.style_at[1], view.STYLE_DEFAULT)
	test.assert_equal(buffer.end_styled, buffer.length + 1)
	test.assert(error_handler.args[1]:find(error_message), 'should have emitted error event')
end)

test('code folding should invoke Scintillua and mark fold headers with the result', function()
	buffer:set_text(test.lines{
		'function foo(z)', --
		'	local x = 1', --
		'	local y = [[2]]', --
		'	print(x + y)', --
		'end'
	})

	buffer:set_lexer('lua')

	-- Construct a fold table from fold levels of the same form as the one returned by
	-- lex:fold(), which looks like {9216, 1025, ...}.
	local actual_folds = {}
	for i = 1, buffer.line_count do actual_folds[i] = buffer.fold_level[i] end

	local expected_folds = buffer.lexer:fold(buffer:get_text(), 1, buffer.FOLDLEVELBASE)

	test.assert_equal(actual_folds, expected_folds)
end)

test('view should refresh its styles when switching between buffers with different lexers',
	function()
		buffer:set_lexer('html')

		buffer.new()
		buffer:append_text('[[foo]]')
		buffer:set_lexer('lua')
		local longstring_style_num = buffer.style_at[1]
		local longstring_name = buffer:name_of_style(longstring_style_num)

		buffer:close(true) -- switch back to HTML
		local style_num = buffer:style_of_name(longstring_name)

		test.assert_equal(style_num, view.STYLE_DEFAULT) -- unknown
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

-- TODO: test lexer api

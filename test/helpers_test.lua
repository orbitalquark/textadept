-- Copyright 2020-2024 Mitchell. See LICENSE.

test('test.assert_equal should assert two values are equal', function()
	local equal = pcall(test.assert_equal, 'foo', 'foo')

	test.assert_equal(equal, true)
end)

test('test.assert_equal should assert two tables are equal', function()
	local equal = pcall(test.assert_equal, {1, 2, 3}, {1, 2, 3})

	test.assert_equal(equal, true)
end)

test('test.assert_equal should raise an error if two values are unequal', function()
	local failed_assertion = function() test.assert_equal('foo', 1) end

	test.assert_raises(failed_assertion, 'foo ~= 1')
end)

test('test.assert_equal should raise an error if two tables are unequal', function()
	local failed_assertion = function() test.assert_equal({1, 2, 3}, {1, 2}) end

	test.assert_raises(failed_assertion, '{1, 2, 3} ~= {1, 2}')
end)

test('test.assert_raises should catch an error', function()
	local error_message = 'error!'
	local raises_error = function() error(error_message) end

	local caught = pcall(test.assert_raises, raises_error, error_message)

	test.assert_equal(caught, true)
end)

test('test.assert_raises should raise an error if it did not catch an error', function()
	local no_error = function() end

	local silent, errmsg = pcall(test.assert_raises, no_error)

	test.assert_equal(silent, false)
	test.assert(errmsg:find('error expected'), 'should have errored with "error expected"')
end)

test('test.assert_contains should assert a string contains a substring', function()
	local subject = 'string'
	local find = 's'

	test.assert_contains(subject, find)
end)

test('test.assert_contains should assert a table contains a value', function()
	local subject = {1, 2, 3}
	local find = 1

	test.assert_contains(subject, find)
end)

test('test.assert_contains should raise an error if the value could not be found', function()
	local subject = 'string'
	local find = 'does not exist'
	local failed_assertion = function() test.assert_contains(subject, find) end

	test.assert_raises(failed_assertion, string.format("'%s' was not found in '%s'", find, subject))
end)

test('stub should be uncalled at first', function()
	local f = test.stub()

	test.assert_equal(f.called, false)
	test.assert_equal(f.args, nil)
end)

test('stub should know if it has been called', function()
	local f = test.stub()

	f()

	test.assert_equal(f.called, true)
end)

test('stub should record the arguments it was called with', function()
	local f = test.stub()
	local args = {'arg', 1}

	f(table.unpack(args))

	test.assert_equal(f.args, args)
end)

test('stub should call its callback when called', function()
	local callback = test.stub()
	local f = test.stub(callback)
	local args = {'arg', 1}

	f(table.unpack(args))

	test.assert_equal(callback.called, true)
	test.assert_equal(callback.args, args)
end)

test('stub should return the values it was initialized with', function()
	local return_values = {true, false}
	local f = test.stub(table.unpack(return_values))

	local result = {f()}

	test.assert_equal(result, return_values)
end)

test('stub should track the number of times it has been called', function()
	local f = test.stub()

	f()
	f()

	test.assert_equal(f.called, 2)
end)

test('defer should invoke its function when it goes out of scope', function()
	local f = test.stub()

	do local _<close> = test.defer(f) end

	test.assert_equal(f.called, true)
end)

test('tmpfile should create a temporary file and defer deleting it', function()
	local filename, created

	do
		local f<close> = test.tmpfile()
		filename = f.filename
		created = lfs.attributes(filename, 'mode') == 'file'
	end
	local still_exists = lfs.attributes(filename) ~= nil

	test.assert_equal(created, true)
	test.assert_equal(still_exists, false)
end)

test('tmpfile should allow an optional file extension', function()
	local ext = '.txt'
	local f<close> = test.tmpfile(ext)

	test.assert(f.filename:match('%' .. ext .. '$'), ext)
end)

test('tmpfile should allow optional file contents', function()
	local contents = 'contents'
	local f<close> = test.tmpfile(contents)

	test.assert_equal(f:read(), contents)
end)

test('tmpfile should optionally open the file', function()
	local contents = 'contents'
	local f<close> = test.tmpfile(contents, true)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer:get_text(), contents)
end)

test('tmpfile should allow opening an empty file with extension', function()
	local f<close> = test.tmpfile('.txt', true)

	test.assert_contains(buffer.filename, '.txt')
	test.assert_equal(buffer.length, 0)
end)

test('tmpdir should create a temporary directory and defer deleting it', function()
	local dirname
	local created = {}

	do
		local dir<close> = test.tmpdir{'file.txt', subdir = {'subfile.txt'}}
		dirname = dir.dirname
		created[dirname] = lfs.attributes(dirname, 'mode') == 'directory'
		created['file.txt'] = lfs.attributes(dirname .. '/file.txt', 'mode') == 'file'
		created['subdir'] = lfs.attributes(dirname .. '/subdir', 'mode') == 'directory'
		created['subfile.txt'] = lfs.attributes(dirname .. '/subdir/subfile.txt', 'mode') == 'file'
	end
	local still_exists = lfs.attributes(dirname) ~= nil

	test.assert_equal(created[dirname], true)
	test.assert_equal(created['file.txt'], true)
	test.assert_equal(created['subdir'], true)
	test.assert_equal(created['subfile.txt'], true)
	test.assert_equal(still_exists, false)
end)

test("tmpdir should allow a file's contents to be given", function()
	local contents = 'contents'

	local dir<close> = test.tmpdir{'empty.txt', ['file.txt'] = contents}

	local empty_f<close> = io.open(dir.dirname .. '/empty.txt')
	local f<close> = io.open(dir.dirname .. '/file.txt')
	test.assert_equal(empty_f:read('a'), '')
	test.assert_equal(f:read('a'), contents)
end)

test('tmpdir should allow changing to it', function()
	local cwd = lfs.currentdir()
	local changed_dir

	do
		local dir<close> = test.tmpdir(true)
		changed_dir = lfs.currentdir() == dir.dirname
	end

	test.assert_equal(changed_dir, true)
	test.assert_equal(lfs.currentdir(), cwd)
end)

test('tmpdir / path should return a functional path', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{file}

	local path = dir / file

	test.assert_equal(path, lfs.abspath(file, dir.dirname))
end)

test('connect should connect to an event and defer disconnecting it', function()
	local event = 'test_deferred_disconnect'
	local f = test.stub()

	do local _<close> = test.connect(event, f) end
	events.emit(event)

	test.assert_equal(f.called, false)
end)

test('mock should change a module field for as long as it is in scope', function()
	local module = {field = true}
	local field

	do
		local _<close> = test.mock(module, 'field', false)
		field = module.field
	end

	test.assert_equal(field, false)
	test.assert_equal(module.field, true)
end)

test('mock should replace a module function for as long as it is in scope', function()
	local module = {}
	function module.name() return 'unmocked' end
	local mock = function() return 'mocked' end
	local mock_result

	do
		local _<close> = test.mock(module, 'name', mock)
		mock_result = module.name()
	end
	local unmocked_result = module.name()

	test.assert_equal(mock_result, 'mocked')
	test.assert_equal(unmocked_result, 'unmocked')
end)

test('mock should allow conditionally mocking a module function', function()
	local module = {['unmocked key'] = 'unmocked value'}
	function module.name(key) return module[key] end
	local conditional = function(value) return value == 'mock key' end
	local mock = test.stub('mocked value')

	local _<close> = test.mock(module, 'name', conditional, mock)
	local mocked_results = {module.name('mock key')}
	local unmocked_results = {module.name('unmocked key')}

	test.assert_equal(mocked_results, {'mocked value'})
	test.assert_equal(mock.args, {'mock key'})
	test.assert_equal(unmocked_results, {'unmocked value'})
end)

test('wait should return when a condition succeeds', function()
	local f = test.stub()
	local function condition()
		if f.called then return f.called end
		f()
	end

	local result = test.wait(condition)

	test.assert_equal(result, true)
end)

test('wait should timeout if a condition fails for long enough', function()
	local noop = function() end
	local timeout = 0.1
	local loop = function() test.wait(noop, timeout) end

	test.assert_raises(loop, 'timed out waiting')
end)

test('type should type into the buffer', function()
	local text = 'text'

	test.type(text)

	test.assert_equal(buffer:get_text(), text)
end)

test('type should emit events.CHAR_ADDED', function()
	local char_added = test.stub()
	local _<close> = test.connect(events.CHAR_ADDED, char_added)
	local key = 'a'

	test.type(key)

	test.assert_equal(char_added.called, true)
	test.assert_equal(char_added.args, {string.byte(key)})
end)

test('type should type into multiple selections', function()
	buffer:append_text(test.lines(2, true))
	buffer:line_down_rect_extend()
	local text = 'text'

	test.type(text)

	test.assert_equal(buffer:get_text(), test.lines{text, text})
end)

test('type should replace selected text', function()
	buffer:append_text('find')
	buffer:select_all()
	local text = 'replace'

	test.type(text)

	test.assert_equal(buffer:get_text(), text)
end)

test('type should not type a key handled by events.KEYPRESS', function()
	local keypress = test.stub(true) -- do not propagate to default keypress handler
	local _<close> = test.connect(events.KEYPRESS, keypress, 1)
	local key = 'a'

	test.type(key)

	test.assert_equal(buffer.length, 0)
end)

test('type should emit events.KEYPRESS for a key shortcut with modifiers', function()
	local keypress = test.stub(true) -- do not propagate to default keypress handler
	local _<close> = test.connect(events.KEYPRESS, keypress, 1)
	local key = 'ctrl+a'

	test.type(key)

	test.assert_equal(keypress.called, true)
	test.assert_equal(keypress.args, {key})
end)

test('type should emit events.KEYPRESS for a non-newline key in keys.KEYSYMS', function()
	local keypress = test.stub(true) -- do not propagate to default keypress handler
	local _<close> = test.connect(events.KEYPRESS, keypress, 1)
	local key = 'right'

	test.type(key)

	test.assert_equal(keypress.called, true)
	test.assert_equal(keypress.args, {key})
end)

test('typing \\n should include \\r in CR+LF EOL mode', function()
	local _<close> = test.mock(buffer, 'eol_mode', buffer.EOL_CRLF)

	test.type('\n')

	test.assert_equal(buffer:get_text(), '\r\n')
end)

test('type should type into the command entry if ui.command_entry.active is true', function()
	local text = 'text'
	ui.command_entry.run()
	local _<close> = test.defer(function() test.type('esc') end)

	test.type(text)

	test.assert_equal(ui.command_entry:get_text(), text)
	test.assert_equal(buffer.length, 0)
end)
if OSX then skip('find in files progress dialog interferes with focus') end -- TODO:

test('type should change ui.find.find_entry_text if ui.find.active is true', function()
	ui.find.focus{find_entry_text = ''}
	local _<close> = test.defer(ui.find.focus)
	local text = 'text'
	local typo = 'z\b'

	test.type(text)
	test.type(typo)

	test.assert_equal(ui.find.find_entry_text, text)
	test.assert_equal(buffer.length, 0)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('type should call ui.find.find_next() when typing \\n if ui.find.active is true', function()
	local find_next = test.stub()
	local _<close> = test.mock(ui.find, 'find_next', find_next)
	ui.find.focus()
	local _<close> = test.defer(ui.find.focus)

	test.type('\n')

	test.assert_equal(find_next.called, true)
	test.assert_equal(buffer.length, 0)
end)
if CURSES then skip('find & replace pane blocks the UI') end

test('get_marked_lines should identify marked lines', function()
	local mark = view:new_marker_number()
	local line = 1
	buffer:marker_add(line, mark)

	local marked = test.get_marked_lines(mark)

	test.assert_equal(marked, {line})
end)

test('get_indicated_text should identify indicated text', function()
	local indic = view:new_indic_number()
	local word = 'word'
	buffer:append_text(word .. word)
	buffer.indicator_current = indic
	buffer:indicator_fill_range(1, #word)

	local indicated = test.get_indicated_text(indic)

	test.assert_equal(indicated, {word})
end)

local attempt = 0
test('retry should try to run a test again', function()
	attempt = attempt + 1
	assert(attempt > 2)
end)
retry(2)

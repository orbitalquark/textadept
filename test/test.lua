-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Overloads tostring() to print more user-friendly output for `assert_equal()`.
local function tostring(value)
	if type(value) == 'table' then
		return string.format('{%s}', table.concat(value, ', '))
	elseif type(value) == 'string' then
		return string.format('%q', value)
	else
		return _G.tostring(value) -- this is not recursive since unit tests are executed in a load() env
	end
end

--- Asserts that values *v1* and *v2* are equal.
-- Tables are compared by value, not by reference.
local function assert_equal(v1, v2)
	if v1 == v2 then return end
	if type(v1) == 'table' and type(v2) == 'table' then
		if #v1 == #v2 then
			for k, v in pairs(v1) do if v2[k] ~= v then goto continue end end
			for k, v in pairs(v2) do if v1[k] ~= v then goto continue end end
			return
		end
		::continue::
		v1 = string.format('{%s}', table.concat(v1, ', '))
		v2 = string.format('{%s}', table.concat(v2, ', '))
	end
	error(string.format('%s ~= %s', v1, v2), 2)
end

--- Asserts that function *f* raises an error whose error message contains string *expected_errmsg*.
-- @param f Function to call.
-- @param expected_errmsg String the error message should contain.
local function assert_raises(f, expected_errmsg)
	local ok, errmsg = pcall(f)
	if ok then error('error expected', 2) end
	if expected_errmsg ~= errmsg and not tostring(errmsg):find(expected_errmsg, 1, true) then
		error(string.format('error message %q expected, was %q', expected_errmsg, errmsg), 2)
	end
end

--- Returns the filename *filename* with directory separators matching the current platform.
-- This is only needed for filename comparisons. Filenames passed to functions like
-- `io.open_file()` do not need to be converted if no later filename tests are performed.
local function file(filename) return not WIN32 and filename or filename:gsub('/', '\\') end

if WIN32 then
	local os_tmpname = os.tmpname
	-- Overloads os.tmpname() to create the file too, just like in Linux.
	function os.tmpname()
		local filename = os_tmpname()
		io.open(filename, 'wb'):close()
		return filename
	end
end

--- Sleeps for *n* number of seconds.
-- On Windows this has to be an integer so *n* is rounded up as necessary.
local function sleep(n)
	if WIN32 then n = math.ceil(n) end
	os.execute(not WIN32 and 'sleep ' .. n or 'timeout /T ' .. n)
end

--- Removes directory *dir* and its contents.
local function removedir(dir) os.execute((not WIN32 and 'rm -r ' or 'rmdir /Q') .. dir) end

local newlines = ({[buffer.EOL_LF] = '\n', [buffer.EOL_CRLF] = '\r\n'})
--- Returns a string containing a single newline depending on the current buffer EOL mode.
local function newline() return newlines[buffer.eol_mode] end

local expected_failures = {}
local function expected_failure(f) expected_failures[f] = true end

--------------------------------------------------------------------------------

function test_assert()
	assert_equal(assert(true, 'okay'), true)
	assert_raises(function() assert(false, 'not okay') end, 'not okay')
	assert_raises(function() assert(false, 'not okay: %s', false) end, 'not okay: false')
	assert_raises(function() assert(false, 'not okay: %s') end, 'no value')
	assert_raises(function() assert(false, 1234) end, '1234')
	assert_raises(function() assert(false) end, 'assertion failed!')
end

function test_assert_types()
	local function foo(bar, baz, quux)
		assert_type(bar, 'string', 1)
		assert_type(baz, 'boolean/nil', 2)
		assert_type(quux, 'string/table/nil', 3)
		return bar
	end
	assert_equal(foo('bar'), 'bar')
	assert_raises(function() foo(1) end, "bad argument #1 to 'foo' (string expected, got number")
	assert_raises(function() foo('bar', 'baz') end,
		"bad argument #2 to 'foo' (boolean/nil expected, got string")
	assert_raises(function() foo('bar', true, 1) end,
		"bad argument #3 to 'foo' (string/table/nil expected, got number")

	foo = function(bar) assert_type(bar, string) end
	assert_raises(function() foo(1) end,
		"bad argument #2 to 'assert_type' (string expected, got table")
	foo = function(bar) assert_type(bar, 'string') end
	assert_raises(function() foo(1) end, "bad argument #3 to 'assert_type' (value expected, got nil")
end

function test_events_basic()
	local emitted = false
	local event, handler = 'test_basic', function() emitted = true end
	events.connect(event, handler)
	events.emit(event)
	assert(emitted, 'event not emitted or handled')
	emitted = false
	events.disconnect(event, handler)
	events.emit(event)
	assert(not emitted, 'event still handled')

	assert_raises(function() events.connect(nil) end, 'string expected')
	assert_raises(function() events.connect(event, nil) end, 'function expected')
	assert_raises(function() events.connect(event, function() end, 'bar') end, 'number/nil expected')
	assert_raises(function() events.disconnect() end, 'expected, got nil')
	assert_raises(function() events.disconnect(event, nil) end, 'function expected')
	assert_raises(function() events.emit(nil) end, 'string expected')
end

function test_events_single_handle()
	local count = 0
	local event, handler = 'test_single_handle', function() count = count + 1 end
	events.connect(event, handler)
	events.connect(event, handler) -- should disconnect first
	events.emit(event)
	assert_equal(count, 1)
end

function test_events_insert()
	local foo = {}
	local event = 'test_insert'
	events.connect(event, function() foo[#foo + 1] = 2 end)
	events.connect(event, function() foo[#foo + 1] = 1 end, 1)
	events.emit(event)
	assert_equal(foo, {1, 2})
end

function test_events_short_circuit()
	local emitted = false
	local event = 'test_short_circuit'
	events.connect(event, function() return true end)
	events.connect(event, function() emitted = true end)
	assert_equal(events.emit(event), true)
	assert_equal(emitted, false)
end

function test_events_disconnect_during_handle()
	local foo = {}
	local event, handlers = 'test_disconnect_during_handle', {}
	for i = 1, 3 do
		handlers[i] = function()
			foo[#foo + 1] = i
			events.disconnect(event, handlers[i])
		end
		events.connect(event, handlers[i])
	end
	events.emit(event)
	assert_equal(foo, {1, 2, 3})
end

function test_events_error()
	local errmsg
	local event, handler = 'test_error', function(message)
		errmsg = message
		return false -- halt propagation
	end
	events.connect(events.ERROR, handler, 1)
	events.connect(event, function() error('foo') end)
	events.emit(event)
	events.disconnect(events.ERROR, handler)
	assert(errmsg:find('foo'), 'error handler did not run')
end

function test_events_value_passing()
	local event = 'test_value_passing'
	events.connect(event, function() return end)
	events.connect(event, function() return {1, 2, 3} end) -- halts propagation
	events.connect(event, function() return 'foo' end)
	assert_equal(events.emit(event), {1, 2, 3})
end

function test_lexer_get_lexer()
	buffer.new()
	buffer:set_lexer('html')
	buffer:set_text(table.concat({
		'<html><head><style type="text/css">', --
		'h1 { color: red; }', --
		'</style></head></html>'
	}, newline()))
	buffer:colorize(1, -1)
	buffer:goto_pos(buffer:position_from_line(2))
	assert_equal(buffer.lexer_language, 'html')
	assert_equal(buffer:get_lexer(true), 'css')
	assert_equal(buffer:name_of_style(buffer.style_at[buffer.current_pos]), 'tag')
	assert_equal(buffer:name_of_style(buffer.style_at[buffer.current_pos + 5]), 'property')
	assert(buffer:name_of_style(buffer.style_at[buffer.current_pos + 12]):find('constant.builtin'),
		'not a builtin constant style')
	buffer:close(true)
end

function test_lexer_set_lexer()
	local lexer_loaded
	local handler = function(name) lexer_loaded = name end
	events.connect(events.LEXER_LOADED, handler)
	buffer.new()
	buffer.filename = 'foo.lua'
	buffer:set_lexer()
	assert_equal(buffer.lexer_language, 'lua')
	assert_equal(lexer_loaded, 'lua')
	buffer.filename = 'foo'
	buffer:set_text('#!/bin/sh')
	buffer:set_lexer()
	assert_equal(buffer.lexer_language, 'bash')
	buffer:undo()
	buffer.filename = 'Makefile'
	buffer:set_lexer()
	assert_equal(buffer.lexer_language, 'makefile')
	view:goto_buffer(1)
	view:goto_buffer(-1)
	assert_equal(buffer.lexer_language, 'makefile')
	events.disconnect(events.LEXER_LOADED, handler)
	buffer:close(true)

	assert_raises(function() buffer:set_lexer(true) end, 'string/nil expected, got boolean')
end

function test_lexer_set_lexer_after_buffer_switch()
	buffer.new()
	buffer:add_text('[[foo]]')
	buffer:set_lexer('lua')
	local longstring_style = buffer.style_at[1]
	local longstring_name = buffer:name_of_style(longstring_style)
	assert(longstring_name:find('string.longstring'), 'not a longstring style')
	local longstring_fore = view.style_fore[longstring_style]
	assert(longstring_fore ~= view.style_fore[view.STYLE_DEFAULT], 'longstring fore is default fore')
	buffer.new()
	buffer:set_lexer('html')
	assert_equal(buffer:style_of_name(longstring_name), view.STYLE_DEFAULT)
	assert(buffer:name_of_style(longstring_style) ~= longstring_name, 'lexer not properly changed')
	assert(view.style_fore[longstring_style] ~= longstring_fore, 'styles not reset')
	buffer:close(true)
	assert_equal(buffer:name_of_style(buffer.style_at[1]), longstring_name)
	assert_equal(view.style_fore[buffer.style_at[1]], longstring_fore)
	buffer:close(true)
end

function test_lexer_load_lexers()
	local lexers = {}
	for file in lfs.dir(_LEXERPATH:match('[^;]+$')) do -- just _HOME/lexers
		local name = file:match('^(.+)%.lua$')
		if name and name ~= 'lexer' then lexers[#lexers + 1] = name end
	end
	table.sort(lexers)
	print('Loading lexers...')
	if #_VIEWS > 1 then view:unsplit() end
	view:goto_buffer(-1)
	buffer.new()
	for _, name in ipairs(lexers) do
		print_silent('Loading lexer ' .. name)
		buffer:set_lexer(name)
	end
	buffer:close()
end

local locales = {}
-- Load localizations from *locale_conf* and return them in a table.
-- @param locale_conf String path to a local file to load.
local function load_locale(locale_conf)
	if locales[locale_conf] then return locales[locale_conf] end
	print(string.format('Loading locale "%s"', locale_conf))
	local L = {}
	for line in io.lines(locale_conf) do
		if not line:find('^%s*[^%w_%[]') then
			local id, str = line:match('^(.-)%s*=%s*(.+)$')
			if id and str and assert(not L[id], 'duplicate locale id "%s"', id) then L[id] = str end
		end
	end
	locales[locale_conf] = L
	return L
end

-- Looks for use of localization in the given Lua file and verifies that each use is okay.
-- @param filename String filename of the Lua file to check.
-- @param L Table of localizations to read from.
local function check_localizations(filename, L)
	print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
	local count = 0
	for line in io.lines(filename) do
		for id in line:gmatch([=[_L%[['"]([^'"]+)['"]%]]=]) do
			assert(L[id], 'locale missing id "%s"', id)
			count = count + 1
		end
	end
	print(string.format('Checked %d localizations.', count))
end

local loaded_extra = {}
-- Records localization assignments in the given Lua file for use in subsequent checks.
-- @param L Table of localizations to add to.
local function load_extra_localizations(filename, L)
	if loaded_extra[filename] then return end
	print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
	local count = 0
	for line in io.lines(filename) do
		if line:find('_L%b[]%s*=') then
			for id in line:gmatch([=[_L%[['"]([^'"]+)['"]%]%s*=]=]) do
				assert(not L[id], 'duplicate locale id "%s"', id)
				L[id], count = true, count + 1
			end
		end
	end
	loaded_extra[filename] = true
	print(string.format('Added %d localizations.', count))
end

local LOCALE_CONF = _HOME .. '/core/locale.conf'
local LOCALE_DIR = _HOME .. '/core/locales'

function test_locale_load()
	local L = load_locale(LOCALE_CONF)
	for locale_conf in lfs.walk(LOCALE_DIR) do
		local l = load_locale(locale_conf)
		for id in pairs(L) do assert(l[id], 'locale missing id "%s"', id) end
		for id in pairs(l) do assert(L[id], 'locale has extra id "%s"', id) end
	end
end

function test_locale_use_core()
	local L = load_locale(LOCALE_CONF)
	local ta_dirs = {'core', 'modules/textadept'}
	for _, dir in ipairs(ta_dirs) do
		dir = _HOME .. '/' .. dir
		for filename in lfs.walk(dir, '.lua') do check_localizations(filename, L) end
	end
	check_localizations(_HOME .. '/init.lua', L)
end

function test_locale_use_extra()
	local L = load_locale(LOCALE_CONF)
	for filename in lfs.walk(_HOME, '.lua') do load_extra_localizations(filename, L) end
	for filename in lfs.walk(_HOME, '.lua') do check_localizations(filename, L) end
end

function test_locale_use_userhome()
	local L = load_locale(LOCALE_CONF)
	for filename in lfs.walk(_HOME, '.lua') do load_extra_localizations(filename, L) end
	for filename in lfs.walk(_USERHOME, '.lua') do load_extra_localizations(filename, L) end
	L['%1'] = true -- snippet
	for filename in lfs.walk(_USERHOME, '.lua') do check_localizations(filename, L) end
end

function test_file_io_open_file_detect_encoding()
	io.recent_files = {} -- clear
	local recent_files = {}
	local files = {
		[file(_HOME .. '/test/file_io/utf8')] = 'UTF-8', --
		[file(_HOME .. '/test/file_io/cp1252')] = 'CP1252', --
		[file(_HOME .. '/test/file_io/utf16')] = 'UTF-16', --
		[file(_HOME .. '/test/file_io/binary')] = ''
	}
	for filename, encoding in pairs(files) do
		print(string.format('Opening file %s', filename))
		io.open_file(filename)
		assert_equal(buffer.filename, filename)
		local f = io.open(filename, 'rb')
		local contents = f:read('a')
		f:close()
		if encoding ~= '' then
			-- assert_equal(buffer:get_text():iconv(encoding, 'UTF-8'), contents)
			assert_equal(buffer.encoding, encoding)
			assert_equal(buffer.code_page, buffer.CP_UTF8)
		else
			assert_equal(buffer:get_text(), contents)
			assert_equal(buffer.encoding, nil)
			assert_equal(buffer.code_page, 0)
		end
		buffer:close()
		table.insert(recent_files, 1, filename)
	end
	assert_equal(io.recent_files, recent_files)

	assert_raises(function() io.open_file(1) end, 'string/table/nil expected, got number')
	assert_raises(function() io.open_file('/tmp/foo', true) end,
		'string/table/nil expected, got boolean')
	-- TODO: encoding failure
end

function test_file_io_open_file_detect_newlines()
	local files = {
		[file(_HOME .. '/test/file_io/lf')] = buffer.EOL_LF,
		[file(_HOME .. '/test/file_io/crlf')] = buffer.EOL_CRLF
	}
	for filename, mode in pairs(files) do
		io.open_file(filename)
		assert_equal(buffer.eol_mode, mode)
		buffer:close()
	end
end

function test_file_io_open_file_with_encoding()
	local num_buffers = #_BUFFERS
	local files = {
		file(_HOME .. '/test/file_io/utf8'), --
		file(_HOME .. '/test/file_io/cp1252'), --
		file(_HOME .. '/test/file_io/utf16')
	}
	local encodings = {nil, 'CP1252', 'UTF-16'}
	io.open_file(files, encodings)
	assert_equal(#_BUFFERS, num_buffers + #files)
	for i = #files, 1, -1 do
		view:goto_buffer(_BUFFERS[num_buffers + i])
		assert_equal(buffer.filename, files[i])
		if encodings[i] then assert_equal(buffer.encoding, encodings[i]) end
		buffer:close()
	end
end

function test_file_io_open_file_already_open()
	local filename = file(_HOME .. '/test/file_io/utf8')
	io.open_file(filename)
	buffer.new()
	local num_buffers = #_BUFFERS
	io.open_file(filename)
	assert_equal(buffer.filename, filename)
	assert_equal(#_BUFFERS, num_buffers)
	view:goto_buffer(1)
	buffer:close() -- untitled
	buffer:close() -- filename
end

function test_file_io_open_file_interactive()
	local num_buffers = #_BUFFERS
	io.open_file()
	if #_BUFFERS > num_buffers then buffer:close() end
end

function test_file_io_open_file_errors()
	if LINUX then
		assert_raises(function() io.open_file('/etc/gshadow-') end,
			'cannot open /etc/gshadow-: Permission denied')
	end
	-- TODO: find a case where the file can be opened, but not read
end

function test_file_io_open_first_visible_line()
	io.open_file(_HOME .. '/src/textadept.c')
	buffer:goto_line(100)
	view.x_offset = 10
	io.open_file(_HOME .. '/core/init.lua')
	ui.update()
	assert_equal(view.first_visible_line, 1)
	assert_equal(view.x_offset, 0)
	buffer:close()
	buffer:close()
end

function test_file_io_open_set_lexer()
	io.open_file(_HOME .. '/src/textadept.c')
	assert_equal(buffer.lexer_language, 'ansi_c')
	buffer:close()
end

function test_file_io_reload_file()
	io.open_file(_HOME .. '/test/file_io/utf8')
	local pos = 10
	buffer:goto_pos(pos)
	local text = buffer:get_text()
	buffer:append_text('foo')
	assert(buffer:get_text() ~= text, 'buffer text is unchanged')
	buffer:reload()
	assert_equal(buffer:get_text(), text)
	ui.update()
	if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
	assert_equal(buffer.current_pos, pos)
	buffer:close()
end

function test_file_io_set_encoding()
	io.open_file(_HOME .. '/test/file_io/utf8')
	local pos = 10
	buffer:goto_pos(pos)
	local text = buffer:get_text()
	buffer:set_encoding('CP1252')
	assert_equal(buffer.encoding, 'CP1252')
	assert_equal(buffer.code_page, buffer.CP_UTF8)
	assert_equal(buffer:get_text(), text) -- fundamentally the same
	assert_equal(buffer.current_pos, pos)
	buffer:reload()
	buffer:close()

	assert_raises(function() buffer:set_encoding(true) end, 'string/nil expected, got boolean')
end

function test_file_io_save_file()
	local final_newline = io.ensure_final_newline
	io.ensure_final_newline = false
	buffer.new()
	buffer._type = '[Foo Buffer]'
	buffer:append_text('foo')
	local filename = os.tmpname()
	buffer:save_as(filename)
	local f = assert(io.open(filename, 'rb'))
	local contents = f:read('a')
	f:close()
	assert_equal(buffer:get_text(), contents)
	assert(not buffer._type, 'still has a type')
	buffer:append_text('bar')
	assert(io.save_all_files(), 'did not save all files')
	f = assert(io.open(filename, 'rb'))
	contents = f:read('a')
	f:close()
	assert_equal(buffer:get_text(), contents)
	io.ensure_final_newline = true
	assert(buffer:save(), 'not saved')
	assert_equal(buffer:get_text(), 'foobar' .. (not WIN32 and '\n' or '\r\n'))
	f = assert(io.open(filename, 'rb'))
	contents = f:read('a')
	f:close()
	assert_equal(buffer:get_text(), contents)
	buffer:close()
	os.remove(filename)
	io.ensure_final_newline = final_newline -- restore

	assert_raises(function() buffer:save_as(1) end, 'string/nil expected, got number')
end

function test_file_io_save_as_set_lexer()
	buffer.new()
	assert_equal(buffer.lexer_language, 'text')
	local name = os.tmpname() .. '.lua'
	assert(buffer:save_as(name), 'not saved')
	os.remove(name)
	assert_equal(buffer.lexer_language, 'lua')
	buffer:close()
end

function test_file_io_save_all_interactive()
	buffer.new()
	local cwd = lfs.currentdir()
	local name = os.tmpname()
	os.remove(name)
	lfs.mkdir(name)
	io.open(name .. '/test', 'w'):close()
	lfs.chdir(name)
	buffer:append_text('foo')
	assert(io.save_all_files(true), 'files should have been saved')
	removedir(name)
	lfs.chdir(cwd) -- restore
	buffer:close(true)
end

function test_file_io_non_global_buffer_functions()
	local filename = os.tmpname()
	local buf = buffer.new()
	buf:append_text('foo')
	view:goto_buffer(-1)
	assert(buffer ~= buf, 'still in untitled buffer')
	assert_equal(buf:get_text(), 'foo')
	assert(buffer ~= buf, 'jumped to untitled buffer')
	buf:save_as(filename)
	assert(buffer ~= buf, 'jumped to untitled buffer')
	view:goto_buffer(1)
	assert(buffer == buf, 'not in saved buffer')
	assert_equal(buffer.filename, filename)
	assert(not buffer.modify, 'saved buffer still marked modified')
	local f = io.open(filename, 'rb')
	local contents = f:read('a')
	f:close()
	assert_equal(buffer:get_text(), contents)
	buffer:append_text('bar')
	view:goto_buffer(-1)
	assert(buffer ~= buf, 'still in saved buffer')
	buf:save()
	assert(buffer ~= buf, 'jumped to untitled buffer')
	f = io.open(filename, 'rb')
	contents = f:read('a')
	f:close()
	assert_equal(buf:get_text(), contents)
	buf:append_text('baz')
	assert_equal(buf:get_text(), contents .. 'baz')
	assert(buf.modify, 'buffer not marked modified')
	buf:reload()
	assert_equal(buf:get_text(), contents)
	assert(not buf.modify, 'buffer still marked modified')
	buf:append_text('baz')
	buf:close(true)
	assert(buffer ~= buf, 'closed the wrong buffer')
	os.remove(filename)
end

function test_file_io_close_modified_interactive()
	buffer.new()
	buffer:add_text('foo')
	buffer:close()
	assert_equal(#_BUFFERS, 2, 'modified buffer closed')
	buffer:close(true)
end

function test_file_io_close_hidden()
	local buffer1 = buffer.new()
	buffer1:add_text('1')
	view:split(true)
	local buffer2 = buffer.new()
	buffer2:add_text('2')
	local buffer3 = buffer.new()
	buffer3:add_text('3')
	view:split()
	local buffer4 = buffer.new()
	buffer4:add_text('4')
	assert(_VIEWS[1].buffer == buffer1, 'buffer1 not visible')
	assert(_VIEWS[2].buffer == buffer3, 'buffer3 not visible')
	assert(_VIEWS[3].buffer == buffer4, 'buffer4 not visible')
	buffer2:close(true)
	assert(_VIEWS[1].buffer == buffer1, 'buffer1 not visible')
	assert(_VIEWS[2].buffer == buffer3, 'buffer3 not visible')
	assert(_VIEWS[3].buffer == buffer4, 'buffer4 not visible')
	buffer1:close(true)
	buffer3:close(true)
	buffer4:close(true)
	while view:unsplit() do end
end
if not QT then expected_failure(test_file_io_close_hidden) end

function test_file_io_file_detect_modified()
	local modified = false
	local handler = function(filename)
		assert_type(filename, 'string', 1)
		modified = true
		return false -- halt propagation
	end
	events.connect(events.FILE_CHANGED, handler, 1)
	local filename = os.tmpname()
	local f = assert(io.open(filename, 'wb'))
	f:write('foo\n'):close()
	io.open_file(filename)
	assert_equal(buffer:get_text(), 'foo\n')
	view:goto_buffer(-1)
	sleep(1) -- filesystem mod time has 1-second granularity
	f = assert(io.open(filename, 'ab'))
	f:write('bar\n'):close()
	view:goto_buffer(1)
	assert_equal(modified, true)
	buffer:close()
	os.remove(filename)
	events.disconnect(events.FILE_CHANGED, handler)
end

function test_file_io_file_detect_modified_interactive()
	local filename = os.tmpname()
	local f = assert(io.open(filename, 'wb'))
	f:write('foo\n'):close()
	io.open_file(filename)
	assert_equal(buffer:get_text(), 'foo\n')
	view:goto_buffer(-1)
	sleep(1) -- filesystem mod time has 1-second granularity
	f = assert(io.open(filename, 'ab'))
	f:write('bar\n'):close()
	view:goto_buffer(1)
	assert_equal(buffer:get_text(), 'foo\nbar\n')
	buffer:close()
	os.remove(filename)
end

function test_file_io_recent_files()
	io.recent_files = {} -- clear
	local recent_files = {}
	local files = {
		file(_HOME .. '/test/file_io/utf8'), --
		file(_HOME .. '/test/file_io/cp1252'), --
		file(_HOME .. '/test/file_io/utf16'), --
		file(_HOME .. '/test/file_io/binary')
	}
	for _, filename in ipairs(files) do
		io.open_file(filename)
		buffer:close()
		table.insert(recent_files, 1, filename)
	end
	assert_equal(io.recent_files, recent_files)
end

function test_file_io_open_recent_interactive()
	local filename = file(_HOME .. '/test/file_io/utf8')
	io.open_file(filename)
	buffer:close()
	local tmpfile = os.tmpname()
	io.open_file(tmpfile)
	buffer:close()
	os.remove(tmpfile)
	io.open_recent_file()
	assert_equal(buffer.filename, filename)
	buffer:close()
end

function test_file_io_get_project_root()
	local cwd = lfs.currentdir()
	lfs.chdir(_HOME)
	assert_equal(io.get_project_root(), _HOME)
	lfs.chdir(cwd)
	assert_equal(io.get_project_root(_HOME), _HOME)
	assert_equal(io.get_project_root(file(_HOME .. '/core')), _HOME)
	assert_equal(io.get_project_root(file(_HOME .. '/core/init.lua')), _HOME)
	assert_equal(io.get_project_root(not WIN32 and '/tmp' or 'C:\\'), nil)
	lfs.chdir(cwd)

	-- Test git submodules.
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	lfs.mkdir(dir .. '/.git')
	lfs.mkdir(dir .. '/foo')
	io.open(dir .. '/foo/.git', 'w'):write():close() -- simulate submodule
	assert_equal(io.get_project_root(file(dir .. '/foo/bar.txt')), dir)
	io.open_file(file(dir .. '/foo/bar.txt'))
	assert_equal(io.get_project_root(true), file(dir .. '/foo'))
	buffer:close()
	removedir(dir)

	assert_raises(function() io.get_project_root(1) end, 'string/nil expected, got number')
end

function test_file_io_quick_open_interactive()
	local num_buffers = #_BUFFERS
	local cwd = lfs.currentdir()
	local dir = file(_HOME .. '/core')
	lfs.chdir(dir)
	io.quick_open_filters[dir] = '.lua'
	io.quick_open(dir)
	if #_BUFFERS > num_buffers then
		assert(buffer.filename:find('%.lua$'), '.lua file filter did not work')
		buffer:close()
	end
	io.quick_open_filters[dir] = true
	assert_raises(function() io.quick_open(dir) end, 'string/table/nil expected, got boolean')
	io.quick_open_filters[dir] = nil
	io.quick_open_filters[_HOME] = '.lua'
	io.quick_open()
	if #_BUFFERS > num_buffers then
		assert(buffer.filename:find('%.lua$'), '.lua file filter did not work')
		buffer:close()
	end
	local quick_open_max = io.quick_open_max
	io.quick_open_max = 10
	io.quick_open(_HOME)
	assert(#_BUFFERS > num_buffers, 'File limit exceeded notification did not occur')
	buffer:close()
	io.quick_open_max = quick_open_max -- restore
	lfs.chdir(cwd)

	assert_raises(function() io.quick_open(1) end, 'string/table/nil expected, got number')
	assert_raises(function() io.quick_open(_HOME, true) end, 'string/table/nil expected, got boolean')
end

function test_keys_keychain()
	local ctrl_a = keys['ctrl+a']
	local foo = false
	keys['ctrl+a'] = {a = function() foo = true end}
	events.emit(events.KEYPRESS, 'a')
	assert(not foo, 'foo set outside keychain')
	events.emit(events.KEYPRESS, 'ctrl+a')
	assert_equal(#keys.keychain, 1)
	assert_equal(keys.keychain[1], 'ctrl+a')
	events.emit(events.KEYPRESS, 'esc')
	assert_equal(#keys.keychain, 0, 'keychain not canceled')
	events.emit(events.KEYPRESS, 'ctrl+a', false, true)
	events.emit(events.KEYPRESS, 'b') -- invalid sequence
	assert_equal(#keys.keychain, 0, 'keychain still active')
	events.emit(events.KEYPRESS, 'a')
	assert(not foo, 'foo set outside keychain')
	events.emit(events.KEYPRESS, 'ctrl+a')
	events.emit(events.KEYPRESS, 'a')
	assert(foo, 'foo not set')
	keys['ctrl+a'] = ctrl_a -- restore
end

function test_keys_propagation()
	buffer:new()
	local foo, bar, baz = false, false, false
	keys.a = function() foo = true end
	keys.b = function() bar = true end
	keys.c = function() baz = true end
	keys.cpp.a = function() end -- halt
	keys.cpp.b = function() return false end -- propagate
	keys.cpp.c = function()
		keys.mode = 'test_mode'
		return false -- propagate
	end
	buffer:set_lexer('cpp')
	events.emit(events.KEYPRESS, 'a')
	assert(not foo, 'foo set')
	events.emit(events.KEYPRESS, 'b')
	assert(bar, 'bar set')
	events.emit(events.KEYPRESS, 'c')
	assert(not baz, 'baz set') -- mode changed, so cannot propagate to keys.c
	assert_equal(keys.mode, 'test_mode')
	keys.mode = nil
	keys.a, keys.b, keys.c, keys.cpp.a, keys.cpp.b, keys.cpp.c = nil, nil, nil, nil, nil, nil -- reset
	buffer:close()
end

function test_keys_modes()
	buffer.new()
	local foo, bar = false, false
	keys.a = function() foo = true end
	keys.test_mode = {
		a = function()
			bar = true
			keys.mode = nil
			return false -- propagate
		end
	}
	keys.cpp.a = function() keys.mode = 'test_mode' end
	events.emit(events.KEYPRESS, 'a')
	assert(foo, 'foo not set')
	assert(not keys.mode, 'key mode entered')
	assert(not bar, 'bar set outside mode')
	foo = false
	buffer:set_lexer('cpp')
	events.emit(events.KEYPRESS, 'a')
	assert_equal(keys.mode, 'test_mode')
	assert(not foo, 'foo set outside mode')
	assert(not bar, 'bar set outside mode')
	events.emit(events.KEYPRESS, 'a')
	assert(bar, 'bar not set')
	assert(not keys.mode, 'key mode still active')
	assert(not foo, 'foo set') -- TODO: should this propagate?
	keys.a, keys.test_mode, keys.cpp.a = nil, nil, nil -- reset
	buffer:close()
end

function test_lfs_ext_walk()
	local files, directories = 0, 0
	for filename in lfs.walk(_HOME .. '/core', nil, nil, true) do
		if not filename:find('[/\\]$') then
			files = files + 1
		else
			directories = directories + 1
		end
	end
	assert(files > 0, 'no files found')
	assert(directories > 0, 'no directories found')

	assert_raises(function() lfs.walk() end, 'string expected, got nil')
	assert_raises(function() lfs.walk(_HOME, 1) end, 'string/table/nil expected, got number')
	assert_raises(function() lfs.walk(_HOME, nil, true) end, 'number/nil expected, got boolean')
end

function test_lfs_ext_walk_filter_lua()
	local count = 0
	for filename in lfs.walk(_HOME .. '/core', '.lua') do
		assert(filename:find('%.lua$'), '"%s" not a Lua file', filename)
		count = count + 1
	end
	assert(count > 0, 'no Lua files found')
end

function test_lfs_ext_walk_filter_exclusive()
	local count = 0
	for filename in lfs.walk(_HOME .. '/core', '!.lua') do
		assert(not filename:find('%.lua$'), '"%s" is a Lua file', filename)
		count = count + 1
	end
	assert(count > 0, 'no non-Lua files found')
end

function test_lfs_ext_walk_filter_dir()
	local count = 0
	for filename in lfs.walk(_HOME, '/core') do
		assert(filename:find('[/\\]core[/\\]'), '"%s" is not in core/', filename)
		count = count + 1
	end
	assert(count > 0, 'no core files found')
end
expected_failure(test_lfs_ext_walk_filter_dir)

function test_lfs_ext_walk_filter_mixed()
	local count = 0
	for filename in lfs.walk(_HOME .. '/core', {'!/locales', '.lua'}) do
		assert(not filename:find('/locales/') and filename:find('%.lua$'), '"%s" should not match',
			filename)
		count = count + 1
	end
	assert(count > 0, 'no matching files found')
end

function test_lfs_ext_walk_max_depth()
	local count = 0
	for filename in lfs.walk(_HOME, '.lua', 0) do count = count + 1 end
	assert_equal(count, 1) -- init.lua
end

function test_lfs_ext_walk_halt()
	local count, count_at_halt = 0, 0
	for filename in lfs.walk(_HOME .. '/core') do
		count = count + 1
		if filename:find('[/\\]locales[/\\].') then
			count_at_halt = count
			break
		end
	end
	assert_equal(count, count_at_halt)

	for filename in lfs.walk(_HOME .. '/core', nil, nil, true) do
		count = count + 1
		if filename:find('[/\\]$') then
			count_at_halt = count
			break
		end
	end
	assert_equal(count, count_at_halt)
end

function test_lfs_ext_walk_win32()
	local win32 = _G.WIN32
	_G.WIN32 = true
	local count = 0
	for filename in lfs.walk(_HOME, {'/core'}) do
		assert(not filename:find('/'), '"%s" has /', filename)
		if filename:find('\\core') then count = count + 1 end
	end
	assert(count > 0, 'no core files found')
	_G.WIN32 = win32 -- reset just in case
end

function test_lfs_ext_walk_symlinks()
	if WIN32 then return end -- not supported
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	lfs.mkdir(dir .. '/1')
	io.open(dir .. '/1/foo', 'w'):close()
	lfs.mkdir(dir .. '/1/bar')
	io.open(dir .. '/1/bar/baz', 'w'):close()
	lfs.link(dir .. '/1/', dir .. '/1/bar/quux', true) -- trailing '/' on purpose
	lfs.mkdir(dir .. '/2')
	io.open(dir .. '/2/foobar', 'w'):close()
	lfs.link(dir .. '/2/foobar', dir .. '/2/foobaz', true)
	lfs.link(dir .. '/2', dir .. '/1/2', true)
	local files = {}
	for filename in lfs.walk(dir .. '/1/') do -- trailing '/' on purpose
		files[#files + 1] = filename
	end
	table.sort(files)
	local expected_files = {
		dir .. '/1/foo', dir .. '/1/bar/baz', dir .. '/1/2/foobar', dir .. '/1/2/foobaz'
	}
	table.sort(expected_files)
	assert_equal(files, expected_files)
	removedir(dir)

	lfs.mkdir(dir)
	io.open(dir .. '/foo', 'w'):close()
	local cwd = lfs.currentdir()
	lfs.chdir(dir)
	lfs.link('.', 'bar', true)
	lfs.mkdir(dir .. '/baz')
	lfs.mkdir(dir .. '/baz/quux')
	lfs.chdir(dir .. '/baz/quux')
	lfs.link('../../baz/', 'foobar', true)
	lfs.chdir(cwd)
	local count = 0
	for filename in lfs.walk(dir) do count = count + 1 end
	assert_equal(count, 1)
	removedir(dir)
end

function test_lfs_ext_walk_root()
	local filename = lfs.walk(not WIN32 and '/' or 'C:\\', nil, 0, true)()
	assert(not filename:find('lfs_ext.lua:'), 'coroutine error')
end

function test_lfs_ext_abs_path()
	if not WIN32 then
		assert_equal(lfs.abspath('bar', '/foo'), '/foo/bar')
		assert_equal(lfs.abspath('./bar', '/foo'), '/foo/bar')
		assert_equal(lfs.abspath('../bar', '/foo'), '/bar')
		assert_equal(lfs.abspath('/bar', '/foo'), '/bar')
		assert_equal(lfs.abspath('../../././baz', '/foo/bar'), '/baz')
	end
	local win32 = _G.WIN32
	_G.WIN32 = true
	assert_equal(lfs.abspath('bar', 'C:\\foo'), 'C:\\foo\\bar')
	assert_equal(lfs.abspath('.\\bar', 'C:\\foo'), 'C:\\foo\\bar')
	assert_equal(lfs.abspath('..\\bar', 'C:\\foo'), 'C:\\bar')
	assert_equal(lfs.abspath('C:\\bar', 'C:\\foo'), 'C:\\bar')
	assert_equal(lfs.abspath('c:\\bar', 'c:\\foo'), 'C:\\bar')
	assert_equal(lfs.abspath('..\\../.\\./baz', 'C:\\foo\\bar'), 'C:\\baz')
	_G.WIN32 = win32 -- reset just in case

	assert_raises(function() lfs.abspath() end, 'string expected, got nil')
	assert_raises(function() lfs.abspath('foo', 1) end, 'string/nil expected, got number')
end

function test_ui_print()
	local tabs = ui.tabs

	ui.tabs = true
	ui.print('foo')
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert_equal(#_VIEWS, 1)
	assert_equal(buffer:get_text(), 'foo\n')
	assert(buffer:line_from_position(buffer.current_pos) > 1, 'still on first line')
	ui.print('bar', 'baz')
	assert_equal(buffer:get_text(), 'foo\nbar\tbaz\n')
	buffer:close()

	ui.tabs = false
	ui.print(1, 2, 3)
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert_equal(#_VIEWS, 2)
	assert_equal(buffer:get_text(), '1\t2\t3\n')
	ui.goto_view(-1) -- first view
	assert(buffer._type ~= _L['[Message Buffer]'], 'still in message buffer')
	ui.print(4, 5, 6) -- should go to second view
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert_equal(buffer:get_text(), '1\t2\t3\n4\t5\t6\n')
	ui.goto_view(-1) -- first view
	assert(buffer._type ~= _L['[Message Buffer]'], 'still in message buffer')
	ui.print_silent(7, 8, 9) -- should stay in first view
	assert(buffer._type ~= _L['[Message Buffer]'], 'switched to message buffer')
	assert_equal(_BUFFERS[#_BUFFERS]:get_text(), '1\t2\t3\n4\t5\t6\n7\t8\t9\n')
	ui.print_silent(string.rep('\n', 100))
	ui.goto_view(1) -- second view
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert(view.first_visible_line > 1, 'message view did not scroll')
	buffer:undo() -- 100 \n
	view:goto_buffer(-1)
	assert(buffer._type ~= _L['[Message Buffer]'], 'message buffer still visible')
	ui.print()
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert_equal(buffer:get_text(), '1\t2\t3\n4\t5\t6\n7\t8\t9\n\n')
	view:unsplit()

	buffer:close()
	ui.tabs = tabs
end

function test_ui_print_to_other_view()
	view:split()
	ui.goto_view(-1)
	assert_equal(_VIEWS[view], 1)
	ui.print('foo') -- should print to other view, not split again
	assert_equal(#_VIEWS, 2)
	assert_equal(_VIEWS[view], 2)
	buffer:close()
	ui.goto_view(-1)
	view:unsplit()
end

function test_ui_print_silent()
	buffer.new():set_text('foo')
	view:split()
	buffer.new():set_text('bar')
	ui.goto_view(-1)
	ui.print_silent('baz')
	assert(view == _VIEWS[1], 'ui.print_silent() should not switch views')
	assert_equal(_VIEWS[1].buffer:get_text(), 'foo')
	assert_equal(_VIEWS[2].buffer:get_text(), 'bar')
	assert_equal(_BUFFERS[#_BUFFERS]:get_text(), 'baz\n')
	view:unsplit()
	for i = 1, 3 do
		view:goto_buffer(_BUFFERS[#_BUFFERS])
		buffer:close(true)
	end
end

function test_ui_output()
	ui.output('file.lua:1: message', '\n')
	assert_equal(buffer._type, _L['[Output Buffer]'])
	assert_equal(buffer.lexer_language, 'output')
	assert_equal(buffer:name_of_style(buffer.style_at[1]), 'filename')
	assert_equal(buffer:name_of_style(buffer.style_at[10]), 'line')
	assert_equal(buffer:name_of_style(buffer.style_at[13]), 'message')
	view:goto_buffer(-1)
	ui.output_silent('stdout')
	assert(buffer._type ~= _L['[Output Buffer]'], 'did not silently output')
	view:goto_buffer(1)
	assert_equal(buffer.style_at[buffer:position_from_line(2)], view.STYLE_DEFAULT)
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
end

function test_ui_dialogs_message_interactive()
	local button = ui.dialogs.message{
		title = 'Title', text = 'text', icon = 'dialog-information', button1 = 'Button 1',
		button2 = 'Button 2', button3 = 'Button 3'
	}
	assert_equal(type(button), 'number')
end

function test_ui_dialogs_input_interactive()
	local text = ui.dialogs.input{title = 'Title', text = 'foo'}
	assert_equal(text, 'foo')

	text, button = ui.dialogs.input{title = 'Title', text = 'bar', return_button = true}
	assert_equal(text, 'bar')
	assert_equal(type(button), 'number')
end

function test_ui_dialogs_open_save_interactive()
	local test_filename = file(_HOME .. '/test/ui/empty')
	local test_dir, test_file = test_filename:match('^(.+[/\\])([^/\\]+)$')
	local filename = ui.dialogs.save{dir = test_dir, file = test_file}
	assert_equal(filename, test_filename)
	filename = ui.dialogs.open{dir = test_dir, file = test_file, multiple = true}
	assert_equal(filename, {test_filename})
	filename = ui.dialogs.open{dir = test_dir, only_dirs = true}
	assert_equal(filename, test_dir:match('^(.+)[/\\]$'))
end

function test_ui_dialogs_progress_interactive()
	local i = 0
	local stopped = ui.dialogs.progress{
		title = 'foo', work = function()
			sleep(0.1)
			i = i + 10
			if i > 100 then return nil end
			return i, i .. '%'
		end
	}
	assert(not stopped, 'progressbar was stopped')

	stopped = ui.dialogs.progress{
		title = 'foo', work = function()
			sleep(0.1)
			return 50
		end
	}
	assert(stopped, 'progressbar not stopped')

	local errmsg
	local handler = function(message)
		errmsg = message
		return false -- halt propagation
	end
	events.connect(events.ERROR, handler, 1)
	ui.dialogs.progress{work = function() error('foo') end}
	assert(errmsg:find('foo'), 'error handler did not run')
	events.disconnect(events.ERROR, handler)

	assert_raises(function() ui.dialogs.progress{} end, "'work' function expected")
end

function test_ui_dialogs_list_interactive()
	local i = ui.dialogs.list{title = 'Title', items = {'bar', 'baz', 'quux'}, text = 'b z'}
	assert_equal(i, 2)
	local i, button = ui.dialogs.list{
		columns = {'1', '2'}, items = {'foo', 'foobar', 'bar', 'barbaz', 'baz', 'bazfoo'},
		search_column = 2, text = 'baz', multiple = true, button1 = _L['OK'], button2 = _L['Cancel'],
		button3 = 'Other', return_button = true
	}
	assert_equal(i, {2})
	assert_equal(type(button), 'number')

	assert_raises(function() ui.dialogs.list{} end, "non-empty 'items' table expected")
	assert_raises(function() ui.dialogs.list{search_column = 2} end, "invalid 'search_column'")
end

function test_ui_switch_buffer_interactive()
	local buffer_list_zorder = ui.buffer_list_zorder
	ui.buffer_list_zorder = false
	buffer.new()
	buffer:append_text('foo')
	buffer.new()
	buffer:append_text('bar')
	buffer:new()
	buffer:append_text('baz')
	ui.switch_buffer() -- back to [Test Output]
	local text = buffer:get_text()
	assert(text ~= 'foo' and text ~= 'bar' and text ~= 'baz')
	for i = 1, 3 do view:goto_buffer(1) end -- cycle back to baz
	ui.buffer_list_zorder = true
	ui.switch_buffer()
	assert_equal(buffer:get_text(), 'bar')
	for i = 1, 3 do buffer:close(true) end

	-- Test relative path display for project files.
	io.open_file(file(_HOME .. '/README.md'))
	io.open_file(file(_HOME .. '/init.lua'))
	local name = os.tmpname()
	io.open_file(name)
	ui.switch_buffer() -- back to init.lua
	ui.switch_buffer() -- back to temp file
	for i = 1, 3 do buffer:close() end

	ui.buffer_list_zorder = buffer_list_zorder -- restore
end

function test_ui_goto_file()
	local dir1_file1 = file(_HOME .. '/test/ui/dir1/file1')
	local dir1_file2 = file(_HOME .. '/test/ui/dir1/file2')
	local dir2_file1 = file(_HOME .. '/test/ui/dir2/file1')
	local dir2_file2 = file(_HOME .. '/test/ui/dir2/file2')
	ui.goto_file(dir1_file1) -- current view
	assert_equal(#_VIEWS, 1)
	assert_equal(buffer.filename, dir1_file1)
	ui.goto_file(dir1_file2, true) -- split view
	assert_equal(#_VIEWS, 2)
	assert_equal(buffer.filename, dir1_file2)
	assert_equal(_VIEWS[1].buffer.filename, dir1_file1)
	ui.goto_file(dir1_file1) -- should go back to first view
	assert_equal(buffer.filename, dir1_file1)
	assert_equal(_VIEWS[2].buffer.filename, dir1_file2)
	ui.goto_file(dir2_file2, true, nil, true) -- should sloppily go back to second view
	assert_equal(buffer.filename, dir1_file2) -- sloppy
	assert_equal(_VIEWS[1].buffer.filename, dir1_file1)
	ui.goto_file(dir2_file1) -- should go back to first view
	assert_equal(buffer.filename, dir2_file1)
	assert_equal(_VIEWS[2].buffer.filename, dir1_file2)
	ui.goto_file(dir2_file2, false, _VIEWS[2]) -- should go to second view
	assert_equal(#_VIEWS, 2)
	assert_equal(buffer.filename, dir2_file2)
	assert_equal(_VIEWS[1].buffer.filename, dir2_file1)
	view:unsplit()
	assert_equal(#_VIEWS, 1)
	for i = 1, 4 do buffer:close() end
end

function test_ui_uri_drop()
	local filename = file(_HOME .. '/test/ui/uri drop')
	local uri = 'file://' .. _HOME:gsub('\\', '/') .. '/test/ui/uri%20drop'
	events.emit(events.URI_DROPPED, uri)
	assert_equal(buffer.filename, filename)
	buffer:close()
	local buffer = buffer
	events.emit(events.URI_DROPPED, 'file://' .. _HOME:gsub('\\', '/'))
	assert_equal(buffer, _G.buffer) -- do not open directory

	-- TODO: OSX
end

function test_ui_buffer_switch_save_restore_properties()
	local folding = view.folding
	view.folding = true
	local filename = _HOME .. '/test/ui/test.lua'
	io.open_file(filename)
	buffer:goto_pos(10)
	view:fold_line(buffer:line_from_position(buffer.current_pos), view.FOLDACTION_CONTRACT)
	view:goto_buffer(-1)
	view:goto_buffer(1)
	assert_equal(buffer.current_pos, 10)
	assert_equal(view.fold_expanded[buffer:line_from_position(buffer.current_pos)], false)
	buffer:close()
	view.folding = false -- restore
end

function test_ui_quit()
	assert(not events.emit('quit'), 'should quit') -- simulate

	ui.print('foo')
	buffer:append_text('bar') -- modify print buffer
	if #_VIEWS > 1 then view:unsplit() end
	assert(not events.emit('quit'), 'should still quit') -- simulate
	buffer:close(true)
end

function test_ui_quit_interactive()
	buffer.new()
	buffer:append_text('foo')
	assert(events.emit('quit'), 'should not quit') -- simulate
	buffer:close(true)
end

if CURSES then
	function test_ui_mouse()
		view:split(true)
		view:split()
		assert(view == _VIEWS[3], 'not in bottom right view')
		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, 2, 2)
		assert(view == _VIEWS[1], 'not in left view')
		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, ui.size[2] - 2, ui.size[1] - 2)
		assert(view == _VIEWS[3], 'not in bottom right view')
		_VIEWS[1].size = 1
		events.emit(events.MOUSE, view.MOUSE_PRESS, 1, 0, 2, 1)
		events.emit(events.MOUSE, view.MOUSE_DRAG, 1, 0, 2, 2)
		assert_equal(_VIEWS[1].size, 2)
		view:unsplit()
		view:unsplit()
	end
end

function test_spawn_cwd()
	local pwd = not WIN32 and 'pwd' or 'cd'
	local tmp = not WIN32 and (not OSX and '/tmp' or '/private/tmp') or os.getenv('TEMP')
	local newline = not WIN32 and '\n' or '\r\n'
	local cwd = not (WIN32 and CURSES) and lfs.currentdir() or 'C:\\Windows'
	assert_equal(os.spawn(pwd):read('a'), cwd .. newline)
	assert_equal(os.spawn(pwd, tmp):read('a'), tmp .. newline)
end

function test_spawn_env()
	if WIN32 and CURSES then return end -- not supported
	local env_cmd = not WIN32 and 'env' or 'set'
	assert(not os.spawn(env_cmd):read('a'):find('^%s*$'), 'empty env')
	assert(os.spawn(env_cmd, {FOO = 'bar'}):read('a'):find('FOO=bar\r?\n'), 'env not set')
	local output = os.spawn(env_cmd, {FOO = 'bar', 'BAR=baz', [true] = 'false'}):read('a')
	assert(output:find('FOO=bar\r?\n'), 'env not set properly')
	assert(output:find('BAR=baz\r?\n'), 'env not set properly')
	assert(not output:find('true=false\r?\n'), 'env not set properly')
end

function test_spawn_stdin()
	if WIN32 or OSX then return end -- TODO:
	local p = os.spawn('lua -e "print(io.read())"')
	p:write('foo\n')
	p:close()
	assert_equal(p:read('l'), 'foo')
	assert_equal(p:read('a'), '')
end

function test_spawn_callbacks()
	local exit_status = -1
	os.spawn('echo foo', ui.print, nil, function(status) exit_status = status end)
	sleep(0.1)
	ui.update()
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert(buffer:get_text():find('^foo'), 'no spawn stdout')
	assert_equal(exit_status, 0)
	buffer:close(true)
	view:unsplit()
	-- Verify stdout is not read as stderr.
	os.spawn('echo foo', nil, ui.print)
	sleep(0.1)
	ui.update()
	assert_equal(#_BUFFERS, 1)
end

function test_spawn_wait()
	local exit_status = -1
	local p = os.spawn(not WIN32 and 'sleep 0.1' or 'ping 127.0.0.1 -n 2', nil, nil,
		function(status) exit_status = status end)
	if not (WIN32 and CURSES) then assert_equal(p:status(), "running") end
	assert_equal(p:wait(), 0)
	assert_equal(exit_status, 0)
	assert_equal(p:status(), 'terminated')
	-- Verify call to wait again returns previous exit status.
	assert_equal(p:wait(), exit_status)
end

function test_spawn_kill()
	if WIN32 and CURSES then return end -- not supported
	local p = os.spawn(not WIN32 and 'sleep 1' or 'ping 127.0.0.1 -n 2')
	p:kill()
	assert(p:wait() ~= 0)
	assert_equal(p:status(), 'terminated')
end

function test_spawn_errors_interactive()
	local ok, errmsg = os.spawn('does not exist')
	assert(not ok, 'no spawn error')
	assert(type(errmsg) == 'string' and errmsg:find('^does not exist:'), 'incorrect spawn error')
	os.spawn('echo foo', error)
	os.spawn('echo foo', nil, nil, error)
end
if CURSES then expected_failure(test_spawn_errors_interactive) end

function test_buffer_text_range()
	buffer.new()
	buffer:set_text('foo\nbar\nbaz')
	buffer:set_target_range(5, 8)
	assert_equal(buffer.target_text, 'bar')
	assert_equal(buffer:text_range(1, buffer.length + 1), 'foo\nbar\nbaz')
	assert_equal(buffer:text_range(-1, 4), 'foo')
	assert_equal(buffer:text_range(9, 16), 'baz')
	assert_equal(buffer.target_text, 'bar') -- assert target range is unchanged
	buffer:close(true)

	assert_raises(function() buffer:text_range() end, 'number expected, got nil')
	assert_raises(function() buffer:text_range(5) end, 'number expected, got nil')
end

function test_buffer_style_of_name()
	assert_equal(buffer:style_of_name('default'), view.STYLE_DEFAULT)
	assert_equal(buffer:style_of_name('unknown'), view.STYLE_DEFAULT, 'style unexpectedly in use')
	assert(buffer:style_of_name('string') ~= view.STYLE_DEFAULT, 'style not in use')
	assert(buffer:style_of_name(lexer.STRING) ~= view.STYLE_DEFAULT, 'style not in use')
end

function test_buffer_deleted()
	local filename = file(_HOME .. '/core/init.lua')
	io.open_file(filename)
	local function f(buffer)
		assert_equal(buffer.filename, filename)
		assert_raises(function() buffer:text_range(1, 2) end, 'nil value')
	end
	events.connect(events.BUFFER_DELETED, f)
	buffer:close()
	events.disconnect(events.BUFFER_DELETED, f)
end

function test_bookmarks()
	local function has_bookmark(line)
		return buffer:marker_get(line) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
	end

	buffer.new()
	buffer:new_line()
	assert(buffer:line_from_position(buffer.current_pos) > 1, 'still on first line')
	textadept.bookmarks.toggle()
	assert(has_bookmark(2), 'no bookmark')
	textadept.bookmarks.toggle()
	assert(not has_bookmark(2), 'bookmark still there')

	buffer:goto_pos(buffer:position_from_line(1))
	textadept.bookmarks.toggle()
	buffer:goto_pos(buffer:position_from_line(2))
	textadept.bookmarks.toggle()
	textadept.bookmarks.goto_mark(true)
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	textadept.bookmarks.goto_mark(true)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	textadept.bookmarks.goto_mark(false)
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	textadept.bookmarks.goto_mark(false)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	textadept.bookmarks.clear()
	assert(not has_bookmark(1), 'bookmark still there')
	assert(not has_bookmark(2), 'bookmark still there')
	buffer:close(true)
end

function test_bookmarks_interactive()
	buffer.new()
	buffer:new_line()
	textadept.bookmarks.toggle()
	buffer:line_up()
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	textadept.bookmarks.goto_mark()
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	buffer:close(true)
end

function test_bookmarks_reload()
	local function has_bookmark(line)
		return buffer:marker_get(line) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
	end

	io.open_file(_HOME .. '/test/modules/textadept/bookmarks/foo')
	buffer:line_down()
	textadept.bookmarks.toggle()
	buffer:line_down()
	buffer:line_down()
	textadept.bookmarks.toggle()
	assert(has_bookmark(2), 'line not bookmarked')
	assert(has_bookmark(4), 'line not bookmarked')
	buffer:reload()
	ui.update()
	if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
	assert(has_bookmark(2), 'bookmark not restored')
	assert(has_bookmark(4), 'bookmark not restored')
	buffer:close(true)
end

function test_command_entry_run()
	local command_run, tab_pressed = false, false
	ui.command_entry.run('label:', function(command) command_run = command end,
		{['\t'] = function() tab_pressed = true end})
	ui.update() -- redraw command entry
	if not OSX then assert_equal(ui.command_entry.active, true) end -- macOS has focus issues here
	assert_equal(ui.command_entry.margin_text[1], 'label:')
	assert(ui.command_entry.margin_width_n[1] > 0, 'margin label is not visible')
	assert(ui.command_entry.margin_width_n[2] > 0, 'no space between margin label and command entry')
	assert_equal(ui.command_entry.lexer_language, 'text')
	if not WIN32 and not OSX then -- there are odd synchronization issues here on Windows and macOS
		assert(ui.command_entry.height == ui.command_entry:text_height(1), 'height ~= 1 line')
		ui.command_entry.height = ui.command_entry:text_height(1) * 2
		ui.update() -- redraw command entry
		assert(ui.command_entry.height > ui.command_entry:text_height(1), 'height < 2 lines')
	end
	ui.command_entry:set_text('foo')
	events.emit(events.KEYPRESS, '\t')
	events.emit(events.KEYPRESS, '\n')
	if not WIN32 then assert_equal(command_run, 'foo') end
	assert(tab_pressed, '\\t not registered')
	assert_equal(ui.command_entry.active, false)

	ui.command_entry.run('', function(text, arg) assert_equal(arg, 'arg') end, 'text', nil, 'arg')
	events.emit(events.KEYPRESS, '\n')

	assert_raises(function() ui.command_entry.run(1) end, 'string/nil expected, got number')
	assert_raises(function() ui.command_entry.run('', '') end, 'function/nil expected, got string')
	assert_raises(function() ui.command_entry.run('', function() end, 1) end,
		'table/string/nil expected, got number')
	assert_raises(function() ui.command_entry.run('', function() end, {}, 1) end,
		'string/nil expected, got number')
	assert_raises(function() ui.command_entry.run('', function() end, {}, true) end,
		'string/nil expected, got boolean')
	assert_raises(function() ui.command_entry.run('', function() end, {}, 'text', true) end,
		'string/nil expected, got boolean')
end

function test_command_entry_run_persistent_label()
	ui.command_entry.run('label:', function() end)
	ui.command_entry:add_text('a')
	assert_equal(ui.command_entry.length, 1)
	ui.command_entry:delete_back() -- without a patch, Scintilla clears margin text
	assert_equal(ui.command_entry.length, 0)
	assert_equal(ui.command_entry.margin_text[1], 'label:')
	events.emit(events.KEYPRESS, 'esc')
end

local function run_lua_command(command)
	ui.command_entry.run()
	ui.command_entry:set_text(command)
	assert_equal(ui.command_entry.lexer_language, 'lua')
	events.emit(events.KEYPRESS, '\n')
end

function test_command_entry_run_lua()
	run_lua_command('print(_HOME)')
	assert_equal(buffer._type, _L['[Message Buffer]'])
	assert_equal(buffer:get_text(), _HOME .. '\n')
	run_lua_command('{key="value"}')
	assert(buffer:get_text():find('{key = value}'), 'table not pretty-printed')
	local column = view.edge_column
	view.edge_column = 80
	run_lua_command('buffer')
	assert_equal(buffer:get_line(buffer.line_count - 1), '}\n') -- result over multiple lines
	view.edge_column = column -- reset
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
end

function test_command_entry_run_lua_abbreviated_env()
	-- buffer get/set.
	run_lua_command('length')
	assert(buffer:get_text():find('%d+%s*$'), 'buffer.length result not a number')
	run_lua_command('auto_c_active')
	assert(buffer:get_text():find('false%s*$'), 'buffer:auto_c_active() result not false')
	run_lua_command('view_eol=true')
	assert_equal(view.view_eol, true)
	-- view get/set.
	if #_VIEWS > 1 then view:unsplit() end
	run_lua_command('split')
	assert_equal(#_VIEWS, 2)
	local size = not CURSES and 100 or 10
	run_lua_command('size=' .. size)
	assert_equal(view.size, size)
	run_lua_command('unsplit')
	assert_equal(#_VIEWS, 1)
	-- ui get/set.
	run_lua_command('dialogs')
	assert(buffer:get_text():find('%b{}%s*$'), 'ui.dialogs result not a table')
	run_lua_command('statusbar_text="foo"')
	-- _G get/set.
	run_lua_command('foo="bar"')
	run_lua_command('foo')
	assert(buffer:get_text():find('bar%s*$'), 'foo result not "bar"')
	-- textadept get/set.
	run_lua_command('editing')
	assert(buffer:get_text():find('%b{}%s*$'), 'textadept.editing result not a table')
	run_lua_command('editing.select_paragraph')
	assert(buffer.selection_start ~= buffer.selection_end,
		'textadept.editing.select_paragraph() did not select paragraph')
	run_lua_command('clipboard_text="foo_copied"')
	buffer:paste()
	assert(buffer:get_text():find('foo_copied'), 'ui.clipboard_text not set')
	buffer:close(true)
end

local function assert_lua_autocompletion(text, first_item)
	ui.command_entry:set_text(text)
	ui.command_entry:goto_pos(ui.command_entry.length + 1)
	events.emit(events.KEYPRESS, '\t')
	assert_equal(ui.command_entry:auto_c_active(), true)
	assert_equal(ui.command_entry.auto_c_current_text, first_item)
	events.emit(events.KEYPRESS, 'down')
	events.emit(events.KEYPRESS, 'up') -- up
	assert_equal(ui.command_entry:get_text(), text) -- no history cycling
	assert_equal(ui.command_entry:auto_c_active(), true)
	assert_equal(ui.command_entry.auto_c_current_text, first_item)
	ui.command_entry:auto_c_cancel()
end

function test_command_entry_complete_lua()
	ui.command_entry.run()
	assert_lua_autocompletion('string.', 'byte')
	assert_lua_autocompletion('auto', 'auto_c_active')
	assert_lua_autocompletion('MARK', 'MARKER_MAX')
	assert_lua_autocompletion('buffer.auto', 'auto_c_auto_hide')
	assert_lua_autocompletion('buffer:auto', 'auto_c_active')
	assert_lua_autocompletion('caret', 'caret_fore')
	assert_lua_autocompletion('ANNO', 'ANNOTATION_BOXED')
	assert_lua_autocompletion('view.margin', 'margin_back_n')
	assert_lua_autocompletion('view:call', 'call_tip_active')
	assert_lua_autocompletion('goto', 'goto_buffer')
	assert_lua_autocompletion('_', '_BUFFERS')
	assert_lua_autocompletion('fi', 'find')
	ui.command_entry:focus() -- hide
end

function test_command_entry_lua_documentation()
	ui.command_entry.run()
	ui.command_entry:set_text('print(') -- Lua api
	require('lsp')
	textadept.menu.menubar['Tools/Language Server/Show Documentation'][2]()
	assert(ui.command_entry:call_tip_active(), 'documentation not found')
	ui.command_entry:call_tip_cancel()
	ui.command_entry:set_text('current_pos') -- Textadept api
	textadept.menu.menubar['Tools/Language Server/Show Documentation'][2]()
	assert(ui.command_entry:call_tip_active(), 'documentation not found')
	ui.command_entry:focus() -- hide
end
expected_failure(test_command_entry_lua_documentation)

function test_command_entry_history()
	local one, two = function() end, function() end

	ui.command_entry.run('', one)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), '') -- no prior history
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), '') -- no further history
	ui.command_entry:add_text('foo')
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', two)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), '') -- no prior history
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), '') -- no further history
	ui.command_entry:add_text('bar')
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', one)
	assert_equal(ui.command_entry:get_text(), 'foo')
	assert_equal(ui.command_entry.selection_start, 1)
	assert_equal(ui.command_entry.selection_end, 4)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'foo') -- no prior history
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), 'foo') -- no further history
	ui.command_entry:set_text('baz')
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', one)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'foo')
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), 'baz')
	events.emit(events.KEYPRESS, 'up') -- 'foo'
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', one)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'baz')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'foo')
	events.emit(events.KEYPRESS, 'esc')

	ui.command_entry.run('', two)
	assert_equal(ui.command_entry:get_text(), 'bar')
	events.emit(events.KEYPRESS, 'esc')
end

function test_command_entry_history_initial_text()
	local f = function() end

	ui.command_entry.run('', f, 'text', 'initial')
	assert_equal(ui.command_entry:get_text(), 'initial')
	assert_equal(ui.command_entry.selection_start, ui.command_entry.selection_end)
	assert_equal(ui.command_entry.current_pos, ui.command_entry.length + 1)
	ui.command_entry:set_text('foo')
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', f, 'text', 'initial')
	assert_equal(ui.command_entry:get_text(), 'initial')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'foo')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'initial')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'initial') -- no prior history
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), 'foo')
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), 'initial')
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), 'initial') -- no further history
	events.emit(events.KEYPRESS, '\n')

	ui.command_entry.run('', f, 'text', 'initial')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), 'foo') -- no duplicate 'initial'
	events.emit(events.KEYPRESS, '\n')
end

function test_command_entry_mode_restore()
	local mode = 'test_mode'
	keys.mode = mode
	ui.command_entry.run()
	assert(keys.mode ~= mode)
	events.emit(events.KEYPRESS, '\n')
	assert_equal(keys.mode, mode)
	keys.mode = nil
end

function test_command_entry_text_changed_event()
	local changed = false
	ui.command_entry.run()
	events.connect(events.COMMAND_TEXT_CHANGED, function() changed = true end)
	ui.command_entry:set_text('foo')
	assert(changed, 'changed event not emitted')
	changed = false
	ui.command_entry:undo()
	assert(changed, 'changed event not emitted')
	ui.command_entry:focus() -- hide
end

function test_editing_auto_pair()
	buffer.new()
	-- Single selection.
	buffer:add_text('foo(')
	events.emit(events.CHAR_ADDED, string.byte('('))
	assert_equal(buffer:get_text(), 'foo()')
	events.emit(events.KEYPRESS, ')')
	assert_equal(buffer.current_pos, buffer.line_end_position[1])
	buffer:char_left()
	-- Note: cannot check for brace highlighting; indicator search does not work.
	events.emit(events.KEYPRESS, '\b')
	assert_equal(buffer:get_text(), 'foo')
	-- Multi-selection.
	buffer:set_text('foo(\nfoo(')
	local pos1 = buffer.line_end_position[1]
	local pos2 = buffer.line_end_position[2]
	buffer:set_selection(pos1, pos1)
	buffer:add_selection(pos2, pos2)
	events.emit(events.CHAR_ADDED, string.byte('('))
	assert_equal(buffer:get_text(), 'foo()\nfoo()')
	assert_equal(buffer.selections, 2)
	assert_equal(buffer.selection_n_start[1], buffer.selection_n_end[1])
	assert_equal(buffer.selection_n_start[1], pos1)
	assert_equal(buffer.selection_n_start[2], buffer.selection_n_end[2])
	assert_equal(buffer.selection_n_start[2], pos2 + 1)
	-- TODO: typeover.
	events.emit(events.KEYPRESS, '\b')
	assert_equal(buffer:get_text(), 'foo\nfoo')
	-- Verify atomic undo for multi-select.
	buffer:undo() -- simulated backspace
	buffer:undo() -- normal undo that a user would perform
	assert_equal(buffer:get_text(), 'foo()\nfoo()')
	buffer:undo()
	assert_equal(buffer:get_text(), 'foo(\nfoo(')
	-- Verify multi-byte characters do not cause issues.
	buffer:set_text('(⌘⇧')
	buffer:line_end()
	buffer:goto_pos(buffer:position_relative(buffer.current_pos, -1))
	events.emit(events.KEYPRESS, '\b') -- ⌘ does not have a complement
	assert_equal(buffer:get_text(), '(⇧')
	events.emit(events.KEYPRESS, '\b') -- ⇧ is not a complement
	assert_equal(buffer:get_text(), '⇧')
	buffer:close(true)
end

function test_editing_auto_pair_html()
	buffer.new()
	buffer:add_text('<')
	events.emit(events.CHAR_ADDED, string.byte('<'))
	assert_equal(buffer:get_text(), '<') -- not auto-paired by default
	buffer:set_lexer('html')
	events.emit(events.CHAR_ADDED, string.byte('<'))
	assert_equal(buffer:get_text(), '<>')
	buffer:clear() -- delete '>'
	buffer.new()
	buffer:add_text('<')
	events.emit(events.CHAR_ADDED, string.byte('<'))
	assert_equal(buffer:get_text(), '<') -- updated for plain text
	view:goto_buffer(-1)
	events.emit(events.CHAR_ADDED, string.byte('<'))
	assert_equal(buffer:get_text(), '<>') -- updated again for HTML
	view:goto_buffer(1)
	buffer:close(true)
	buffer:close(true)
end

function test_editing_auto_indent()
	buffer.new()
	buffer:add_text('foo')
	buffer:new_line()
	assert_equal(buffer.line_indentation[2], 0)
	buffer:tab()
	buffer:add_text('bar')
	buffer:new_line()
	assert_equal(buffer.line_indentation[3], buffer.tab_width)
	assert_equal(buffer.current_pos, buffer.line_indent_position[3])
	buffer:new_line()
	buffer:back_tab()
	assert_equal(buffer.line_indentation[4], 0)
	assert_equal(buffer.current_pos, buffer:position_from_line(4))
	buffer:new_line() -- should indent since previous line is blank
	assert_equal(buffer.line_indentation[5], buffer.tab_width)
	assert_equal(buffer.current_pos, buffer.line_indent_position[5])
	buffer:goto_pos(buffer:position_from_line(2)) -- "\tbar"
	buffer:new_line() -- should not change indentation
	assert_equal(buffer.line_indentation[3], buffer.tab_width)
	assert_equal(buffer.current_pos, buffer:position_from_line(3))
	buffer:close(true)
end

function test_editing_strip_trailing_spaces()
	local strip = textadept.editing.strip_trailing_spaces
	textadept.editing.strip_trailing_spaces = true
	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	local text = table.concat({
		'foo ', --
		'  bar\t\r', --
		'baz\t ', --
		' \t '
	}, '\n')
	buffer:set_text(text)
	buffer:goto_pos(buffer.line_end_position[2])
	events.emit(events.FILE_BEFORE_SAVE)
	assert_equal(buffer:get_text(), table.concat({
		'foo', --
		'  bar\r', --
		'baz', --
		''
	}, '\n'))
	assert_equal(buffer.current_pos, buffer.line_end_position[2])
	buffer:undo()
	assert_equal(buffer:get_text(), text)
	buffer.encoding = nil -- treat as a binary file
	events.emit(events.FILE_BEFORE_SAVE)
	assert_equal(buffer:get_text(), text)
	buffer:close(true)
	textadept.editing.strip_trailing_spaces = strip -- restore
end

function test_editing_paste_reindent_tabs_to_tabs()
	ui.clipboard_text = table.concat({
		'\tfoo', --
		'', --
		'\t\tbar', --
		'\tbaz'
	}, newline())
	buffer.new()
	buffer.use_tabs, buffer.eol_mode = true, buffer.EOL_CRLF
	buffer:add_text('quux\r\n')
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'quux', --
		'foo', --
		'', --
		'\tbar', --
		'baz'
	}, '\r\n'))
	buffer:clear_all()
	buffer:add_text('\t\tquux\r\n\r\n') -- no auto-indent
	assert_equal(buffer.line_indentation[2], 0)
	assert_equal(buffer.line_indentation[3], 0)
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'\t\tquux', --
		'', --
		'\t\tfoo', --
		'\t\t', --
		'\t\t\tbar', --
		'\t\tbaz'
	}, '\r\n'))
	buffer:clear_all()
	buffer:add_text('\t\tquux\r\n')
	assert_equal(buffer.line_indentation[2], 0)
	buffer:new_line() -- auto-indent
	assert_equal(buffer.line_indentation[3], 2 * buffer.tab_width)
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'\t\tquux', --
		'', --
		'\t\tfoo', --
		'\t\t', --
		'\t\t\tbar', --
		'\t\tbaz'
	}, '\r\n'))
	buffer:close(true)
end
expected_failure(test_editing_paste_reindent_tabs_to_tabs)

function test_editing_paste_reindent_spaces_to_spaces()
	ui.clipboard_text = table.concat({
		'    foo', --
		'', --
		'        bar', --
		'            baz', --
		'    quux'
	}, newline())
	buffer.new()
	buffer.use_tabs, buffer.tab_width = false, 2
	buffer:add_text('foobar\n')
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'foobar', --
		'foo', --
		'', --
		'  bar', --
		'    baz', --
		'quux'
	}, newline()))
	buffer:clear_all()
	buffer:add_text('    foobar\n\n') -- no auto-indent
	assert_equal(buffer.line_indentation[2], 0)
	assert_equal(buffer.line_indentation[3], 0)
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'    foobar', --
		'', --
		'    foo', --
		'    ', --
		'      bar', --
		'        baz', --
		'    quux'
	}, newline()))
	buffer:clear_all()
	buffer:add_text('    foobar\n')
	assert_equal(buffer.line_indentation[2], 0)
	buffer:new_line() -- auto-indent
	assert_equal(buffer.line_indentation[3], 4)
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'    foobar', --
		'', --
		'    foo', --
		'    ', --
		'      bar', --
		'        baz', --
		'    quux'
	}, newline()))
	buffer:close(true)
end
expected_failure(test_editing_paste_reindent_spaces_to_spaces)

function test_editing_paste_reindent_spaces_to_tabs()
	ui.clipboard_text = table.concat({
		'  foo', --
		'    bar', --
		'  baz'
	}, newline())
	buffer.new()
	buffer.use_tabs, buffer.tab_width = true, 4
	buffer:add_text('\tquux')
	buffer:new_line()
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'\tquux', --
		'\tfoo', --
		'\t\tbar', --
		'\tbaz'
	}, newline()))
	buffer:close(true)
end

function test_editing_paste_reindent_tabs_to_spaces()
	ui.clipboard_text = table.concat({
		'\tif foo and', --
		'\t   bar then', --
		'\t\tbaz()', --
		'\tend', --
		''
	}, newline())
	buffer.new()
	buffer.use_tabs, buffer.tab_width = false, 2
	buffer:set_lexer('lua')
	buffer:add_text('function quux()')
	buffer:new_line()
	buffer:insert_text(-1, 'end')
	buffer:colorize(1, -1) -- first line should be a fold header
	textadept.editing.paste_reindent()
	assert_equal(buffer:get_text(), table.concat({
		'function quux()', --
		'  if foo and', --
		'     bar then', --
		'    baz()', --
		'  end', --
		'end'
	}, newline()))
	buffer:close(true)
end
expected_failure(test_editing_paste_reindent_tabs_to_spaces)

function test_editing_toggle_comment_lines()
	buffer.new()
	buffer:add_text('foo')
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), 'foo')
	buffer:set_lexer('lua')
	local text = table.concat({
		'', --
		'local foo = "bar"', --
		'  local baz = "quux"', --
		''
	}, newline())
	buffer:set_text(text)
	buffer:goto_pos(buffer:position_from_line(2))
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), table.concat({
		'', --
		'--local foo = "bar"', --
		'  local baz = "quux"', --
		''
	}, newline()))
	assert_equal(buffer.current_pos, buffer:position_from_line(2) + 2)
	textadept.editing.toggle_comment() -- uncomment
	assert_equal(buffer:get_line(2), 'local foo = "bar"' .. newline())
	assert_equal(buffer.current_pos, buffer:position_from_line(2))
	local offset = 5
	buffer:set_sel(buffer:position_from_line(2) + offset, buffer:position_from_line(4) - offset)
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), table.concat({
		'', --
		'--local foo = "bar"', --
		'--  local baz = "quux"', --
		''
	}, newline()))
	assert_equal(buffer.selection_start, buffer:position_from_line(2) + offset + 2)
	assert_equal(buffer.selection_end, buffer:position_from_line(4) - offset)
	textadept.editing.toggle_comment() -- uncomment
	assert_equal(buffer:get_text(), table.concat({
		'', --
		'local foo = "bar"', --
		'  local baz = "quux"', --
		''
	}, newline()))
	assert_equal(buffer.selection_start, buffer:position_from_line(2) + offset)
	assert_equal(buffer.selection_end, buffer:position_from_line(4) - offset)
	buffer:undo() -- comment
	buffer:undo() -- uncomment
	assert_equal(buffer:get_text(), text) -- verify atomic undo
	buffer:set_text(table.concat({
		'--foo', --
		'  --foo'
	}, newline()))
	buffer:select_all()
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), table.concat({
		'foo', --
		'  foo'
	}, newline()))
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), table.concat({
		'--foo', --
		'--  foo'
	}, newline()))
	buffer:close(true)
end

function test_editing_toggle_comment()
	buffer.new()
	buffer:set_lexer('ansi_c')
	textadept.editing.comment_string.ansi_c = '/*|*/'
	buffer:set_text(table.concat({
		'', --
		'  const char *foo = "bar";', --
		'const char *baz = "quux";', --
		''
	}, newline()))
	buffer:set_sel(buffer:position_from_line(2), buffer:position_from_line(4))
	textadept.editing.toggle_comment()
	assert_equal(buffer:get_text(), table.concat({
		'', --
		'  /*const char *foo = "bar";*/', --
		'/*const char *baz = "quux";*/', --
		''
	}, newline()))
	assert_equal(buffer.selection_start, buffer:position_from_line(2) + 2)
	assert_equal(buffer.selection_end, buffer:position_from_line(4))
	textadept.editing.toggle_comment() -- uncomment
	assert_equal(buffer:get_text(), table.concat({
		'', --
		'  const char *foo = "bar";', --
		'const char *baz = "quux";', --
		''
	}, newline()))
	assert_equal(buffer.selection_start, buffer:position_from_line(2))
	assert_equal(buffer.selection_end, buffer:position_from_line(4))
	buffer:close(true)
end

function test_editing_goto_line()
	buffer.new()
	buffer:new_line()
	textadept.editing.goto_line(1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	textadept.editing.goto_line(2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	buffer:close(true)

	assert_raises(function() textadept.editing.goto_line(true) end, 'number/nil expected, got boolean')
end

function test_editing_goto_line_interactive()
	buffer.new()
	textadept.editing.goto_line() -- verify the popup dialog is shown
	buffer:close()
end

function test_editing_join_lines()
	buffer.new()
	buffer:append_text('foo\nbar\n  baz\nquux\n')
	textadept.editing.join_lines()
	assert_equal(buffer:get_text(), 'foo bar\n  baz\nquux\n')
	assert_equal(buffer.current_pos, 4)
	buffer:set_sel(buffer:position_from_line(2) + 5, buffer:position_from_line(4) - 5)
	textadept.editing.join_lines()
	assert_equal(buffer:get_text(), 'foo bar\n  baz quux\n')
	buffer:close(true)
end

function test_editing_enclose()
	buffer.new()
	buffer.add_text('foo bar')
	textadept.editing.enclose('"', '"')
	assert_equal(buffer:get_text(), 'foo "bar"')
	buffer:undo()
	buffer:select_all()
	textadept.editing.enclose('(', ')')
	assert_equal(buffer:get_text(), '(foo bar)')
	buffer:undo()
	buffer:append_text('\nfoo bar')
	buffer:set_selection(buffer.line_end_position[1], buffer.line_end_position[1])
	buffer:add_selection(buffer.line_end_position[2], buffer.line_end_position[2])
	textadept.editing.enclose('<', '>')
	assert_equal(buffer:get_text(), 'foo <bar>\nfoo <bar>')
	buffer:undo()
	assert_equal(buffer:get_text(), 'foo bar\nfoo bar') -- verify atomic undo
	buffer:set_selection(buffer:position_from_line(1), buffer.line_end_position[1])
	buffer:add_selection(buffer:position_from_line(2), buffer.line_end_position[2])
	textadept.editing.enclose('-', '-')
	assert_equal(buffer:get_text(), '-foo bar-\n-foo bar-')
	assert(buffer.selection_empty, 'enclosed text still selected')
	buffer:undo()
	textadept.editing.enclose('*', '*', true)
	assert_equal(buffer:get_sel_text(), 'bar')
	textadept.editing.enclose('*', '*')
	assert_equal(buffer:get_text(), 'foo **bar**\nfoo bar')
	buffer:close(true)

	assert_raises(function() textadept.editing.enclose() end, 'string expected, got nil')
	assert_raises(function() textadept.editing.enclose('<', 1) end, 'string expected, got number')
	assert_raises(function() textadept.editing.enclose('<', '>', 1) end,
		'boolean/nil expected, got number')
end

function test_editing_auto_enclose()
	local auto_enclose = textadept.editing.auto_enclose
	buffer.new()
	buffer:add_text('foo bar')
	buffer:word_left_extend()
	textadept.editing.auto_enclose = false
	events.emit(events.KEYPRESS, '*') -- simulate typing
	assert(buffer:get_text() ~= 'foo *bar*')
	textadept.editing.auto_enclose = true
	events.emit(events.KEYPRESS, '*') -- simulate typing
	assert_equal(buffer:get_text(), 'foo *bar*')
	buffer:undo()
	buffer:select_all()
	events.emit(events.KEYPRESS, '(') -- simulate typing
	assert_equal(buffer:get_text(), '(foo bar)')
	buffer:close(true)
	textadept.editing.auto_enclose = auto_enclose -- restore
end

function test_editing_select_enclosed()
	buffer.new()
	buffer:add_text('("foo bar")')
	buffer:goto_pos(6)
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'foo bar')
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), '"foo bar"')
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'foo bar')
	buffer:goto_pos(6)
	textadept.editing.select_enclosed('("', '")')
	assert_equal(buffer:get_sel_text(), 'foo bar')
	textadept.editing.select_enclosed('("', '")')
	assert_equal(buffer:get_sel_text(), '("foo bar")')
	textadept.editing.select_enclosed('("', '")')
	assert_equal(buffer:get_sel_text(), 'foo bar')
	buffer:append_text('"baz"')
	buffer:goto_pos(10) -- last " on first line
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'foo bar')
	buffer:close(true)

	assert_raises(function() textadept.editing.select_enclosed('"') end, 'string expected, got nil')
end
expected_failure(test_editing_select_enclosed)

function test_editing_select_enclosed_html()
	buffer.new()
	buffer:add_text('<foo>(bar) baz</foo>')
	buffer:goto_pos(3)
	textadept.editing.select_enclosed()
	assert(buffer.selection_empty, 'selected text') -- <> are not paired by default
	buffer:set_lexer('html')
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'foo')
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), '<foo>')
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'foo')
	buffer:goto_pos(8)
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), 'bar')
	buffer:goto_pos(13)
	textadept.editing.select_enclosed()
	assert_equal(buffer:get_sel_text(), '(bar) baz')
	buffer:close(true)
end

function test_editing_select_word()
	buffer.new()
	buffer:append_text(table.concat({
		'foo', --
		'foobar', --
		'bar foo', --
		'baz foo bar', --
		'fooquux', --
		'foo'
	}, newline()))
	textadept.editing.select_word()
	assert_equal(buffer:get_sel_text(), 'foo')
	textadept.editing.select_word()
	assert_equal(buffer.selections, 2)
	assert_equal(buffer:get_sel_text(), 'foofoo') -- Scintilla stores it this way
	textadept.editing.select_word(true)
	assert_equal(buffer.selections, 4)
	assert_equal(buffer:get_sel_text(), 'foofoofoofoo')
	local lines = {}
	for i = 1, buffer.selections do
		lines[#lines + 1] = buffer:line_from_position(buffer.selection_n_start[i])
	end
	table.sort(lines)
	assert_equal(lines, {1, 3, 4, 6})
	buffer:close(true)
end

function test_editing_select_line()
	buffer.new()
	buffer:add_text('foo\n  bar')
	textadept.editing.select_line()
	assert_equal(buffer:get_sel_text(), '  bar')
	buffer:close(true)
end

function test_editing_select_paragraph()
	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	buffer:set_text(table.concat({
		'foo', --
		'', --
		'bar', --
		'baz', --
		'', --
		'quux'
	}, '\n'))
	buffer:goto_pos(buffer:position_from_line(3))
	textadept.editing.select_paragraph()
	assert_equal(buffer:get_sel_text(), 'bar\nbaz\n\n')
	buffer:close(true)
end

function test_editing_convert_indentation()
	buffer.new()
	local text = table.concat({
		'\tfoo', --
		'  bar', --
		'\t    baz', --
		'    \tquux'
	}, newline())
	buffer:set_text(text)
	buffer.use_tabs, buffer.tab_width = true, 4
	textadept.editing.convert_indentation()
	assert_equal(buffer:get_text(), table.concat({
		'\tfoo', --
		'  bar', --
		'\t\tbaz', --
		'\t\tquux'
	}, newline()))
	buffer:undo()
	assert_equal(buffer:get_text(), text) -- verify atomic undo
	buffer.use_tabs, buffer.tab_width = false, 2
	textadept.editing.convert_indentation()
	assert_equal(buffer:get_text(), table.concat({
		'  foo', --
		'  bar', --
		'      baz', --
		'      quux'
	}, newline()))
	buffer:close(true)
end

function test_editing_highlight_word()
	local function verify(indics)
		local bit = 1 << textadept.editing.INDIC_HIGHLIGHT - 1
		for _, pos in ipairs(indics) do
			local mask = buffer:indicator_all_on_for(pos)
			assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
		end
	end
	local function update()
		ui.update()
		if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
	end

	local highlight = textadept.editing.highlight_words
	textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_SELECTED
	buffer.new()
	buffer:append_text(table.concat({
		'foo', --
		'foobar', --
		'bar  foo', --
		'baz foo bar', --
		'fooquux', --
		'foo'
	}, newline()))
	local function verify_foo()
		verify{
			buffer:position_from_line(1), --
			buffer:position_from_line(3) + 5, --
			buffer:position_from_line(4) + 4, --
			buffer:position_from_line(6)
		}
	end
	textadept.editing.select_word()
	update()
	verify_foo()
	events.emit(events.KEYPRESS, 'esc')
	local pos = buffer:indicator_end(textadept.editing.INDIC_HIGHLIGHT, 1)
	assert_equal(pos, 1) -- highlights cleared
	-- Verify turning off word highlighting.
	textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_NONE
	textadept.editing.select_word()
	update()
	pos = buffer:indicator_end(textadept.editing.INDIC_HIGHLIGHT, 2)
	assert_equal(pos, 1) -- no highlights
	textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_SELECTED
	-- Verify partial word selections do not highlight words.
	buffer:set_sel(1, 3)
	pos = buffer:indicator_end(textadept.editing.INDIC_HIGHLIGHT, 2)
	assert_equal(pos, 1) -- no highlights
	-- Verify multi-word selections do not highlight words.
	buffer:set_sel(buffer:position_from_line(3), buffer.line_end_position[3])
	assert(buffer:is_range_word(buffer.selection_start, buffer.selection_end))
	pos = buffer:indicator_end(textadept.editing.INDIC_HIGHLIGHT, 2)
	assert_equal(pos, 1) -- no highlights
	-- Verify current word highlighting.
	textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_CURRENT
	buffer:goto_pos(1)
	update()
	verify_foo()
	buffer:line_down()
	update()
	verify{buffer:position_from_line(2)}
	buffer:line_down()
	update()
	verify{buffer:position_from_line(3), buffer:position_from_line(4) + 9}
	buffer:word_right()
	update()
	verify_foo()
	buffer:char_left()
	update()
	pos = buffer:indicator_end(textadept.editing.INDIC_HIGHLIGHT, 2)
	assert_equal(pos, 1) -- no highlights
	buffer:close(true)
	textadept.editing.highlight_words = highlight -- reset
end

function test_editing_filter_through()
	buffer.new()
	if not WIN32 then
		buffer:set_text('3|baz\n1|foo\n5|foobar\n1|foo\n4|quux\n2|bar\n')
		textadept.editing.filter_through('sort')
		assert_equal(buffer:get_text(), '1|foo\n1|foo\n2|bar\n3|baz\n4|quux\n5|foobar\n')
	else
		buffer:set_text('3|baz\r\n1|foo\r\n5|foobar\r\n1|foo\r\n4|quux\r\n2|bar\r\n')
		if not CURSES then
			textadept.editing.filter_through('sort')
			assert_equal(buffer:get_text(), '1|foo\r\n1|foo\r\n2|bar\r\n3|baz\r\n4|quux\r\n5|foobar\r\n')
		else
			assert_raises(function() textadept.editing.filter_through('sort') end, 'not implemented')
		end
		goto done -- it works; remaining commands are predominantly Unix ones
	end
	buffer:undo()
	textadept.editing.filter_through('sort | uniq|cut -d "|" -f2')
	assert_equal(buffer:get_text(), 'foo\nbar\nbaz\nquux\nfoobar\n')
	buffer:undo()
	buffer:set_sel(buffer:position_from_line(2) + 2, buffer.line_end_position[2])
	textadept.editing.filter_through('sed "s/o/O/g;"')
	assert_equal(buffer:get_text(), '3|baz\n1|fOO\n5|foobar\n1|foo\n4|quux\n2|bar\n')
	buffer:undo()
	buffer:set_sel(buffer:position_from_line(2), buffer:position_from_line(5))
	textadept.editing.filter_through('sort')
	assert_equal(buffer:get_text(), '3|baz\n1|foo\n1|foo\n5|foobar\n4|quux\n2|bar\n')
	buffer:undo()
	buffer:set_sel(buffer:position_from_line(2), buffer:position_from_line(5) + 1)
	textadept.editing.filter_through('sort')
	assert_equal(buffer:get_text(), '3|baz\n1|foo\n1|foo\n4|quux\n5|foobar\n2|bar\n')
	buffer:undo()
	-- Test rectangular selection.
	buffer:set_text('987654321\n123456789\n')
	buffer.rectangular_selection_anchor = 4
	buffer.rectangular_selection_caret = 17
	textadept.editing.filter_through('sort')
	assert_equal(buffer:get_text(), '987456321\n123654789\n')
	assert_equal(buffer.rectangular_selection_anchor, 4)
	assert_equal(buffer.rectangular_selection_caret, 17)
	buffer:undo()
	assert_equal(buffer:get_text(), '987654321\n123456789\n')
	-- Test multiple selection.
	buffer:set_text('foo\n\tfoo\n\t\tfoo\nfoo')
	buffer:goto_pos(1)
	textadept.editing.select_word()
	textadept.editing.select_word()
	textadept.editing.select_word()
	textadept.editing.filter_through('tr -d o')
	assert_equal(buffer:get_text(), 'f\n\tf\n\t\tf\nfoo')
	assert_equal(buffer.selections, 3)
	for i = 1, buffer.selections do
		assert_equal(buffer:text_range(buffer.selection_n_start[i], buffer.selection_n_end[i]), 'f')
	end
	buffer:undo()
	assert_equal(buffer:get_text(), 'foo\n\tfoo\n\t\tfoo\nfoo')
	::done::
	buffer:close(true)

	assert_raises(function() textadept.editing.filter_through() end, 'string expected, got nil')
end

function test_editing_autocomplete()
	assert_raises(function() textadept.editing.autocomplete() end, 'string expected, got nil')
end

function test_editing_autocomplete_word()
	local all_words = textadept.editing.autocomplete_all_words
	textadept.editing.autocomplete_all_words = false
	buffer.new()
	buffer:add_text('foo f')
	assert(textadept.editing.autocomplete('word'), 'did not autocomplete')
	assert_equal(buffer:get_text(), 'foo foo')
	buffer:add_text('bar f')
	assert(textadept.editing.autocomplete('word'), 'not attempting autocompletion')
	assert(buffer:auto_c_active(), 'autocomplete list not shown')
	buffer:auto_c_select('foob')
	buffer:auto_c_complete()
	assert_equal(buffer:get_text(), 'foo foobar foobar')
	local ignore_case = buffer.auto_c_ignore_case
	buffer.auto_c_ignore_case = false
	buffer:add_text(' Bar b')
	assert(not textadept.editing.autocomplete('word'), 'unexpectedly autocompleted')
	assert_equal(buffer:get_text(), 'foo foobar foobar Bar b')
	buffer.auto_c_ignore_case = true
	textadept.editing.autocomplete('word')
	assert_equal(buffer:get_text(), 'foo foobar foobar Bar Bar')
	buffer.new()
	buffer:add_text('b')
	textadept.editing.autocomplete_all_words = true
	textadept.editing.autocomplete('word')
	assert_equal(buffer:get_text(), 'Bar')
	textadept.editing.autocomplete_all_words = all_words
	buffer:close(true)
	buffer.auto_c_ignore_case = ignore_case
	buffer:close(true)
end

function test_ui_find_find_text()
	local wrapped = false
	local handler = function() wrapped = true end
	buffer.new()
	buffer:set_text(table.concat({
		' foo', --
		'foofoo', --
		'FOObar', --
		'foo bar baz'
	}, newline()))
	ui.find.find_entry_text = 'foo'
	ui.find.find_next()
	assert_equal(buffer.selection_start, 1 + 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.whole_word = true
	ui.find.find_next()
	assert_equal(buffer.selection_start, buffer:position_from_line(4))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	events.connect(events.FIND_WRAPPED, handler)
	ui.find.find_next()
	assert(wrapped, 'search did not wrap')
	events.disconnect(events.FIND_WRAPPED, handler)
	assert_equal(buffer.selection_start, 1 + 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.find_prev()
	assert_equal(buffer.selection_start, buffer:position_from_line(4))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.match_case, ui.find.whole_word = true, false
	ui.find.find_entry_text = 'FOO'
	ui.find.find_next()
	assert_equal(buffer.selection_start, buffer:position_from_line(3))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.find_next()
	assert_equal(buffer.selection_start, buffer:position_from_line(3))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.regex = true
	ui.find.find_entry_text = 'f(.)\\1'
	ui.find.find_next()
	assert_equal(buffer.selection_start, buffer:position_from_line(4))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.find_entry_text = 'quux'
	ui.find.find_next()
	assert_equal(buffer.selection_start, buffer.selection_end) -- no match
	assert_equal(events.emit(events.FIND, 'not found'), -1) -- simulate Find Next
	ui.find.match_case, ui.find.regex = false, false
	ui.find.find_entry_text = ''
	buffer:close(true)
end

function test_ui_find_highlight_results()
	local function assert_indics(indics)
		local bit = 1 << ui.find.INDIC_FIND - 1
		for _, pos in ipairs(indics) do
			local mask = buffer:indicator_all_on_for(pos)
			assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
		end
	end

	local highlight_all_matches = ui.find.highlight_all_matches
	ui.find.highlight_all_matches = true
	buffer.new()
	buffer:append_text(table.concat({
		'foo', --
		'foobar', --
		'bar foo', --
		'baz foo bar', --
		'fooquux', --
		'foo'
	}, newline()))
	-- Normal search.
	ui.find.find_entry_text = 'foo'
	ui.find.find_next()
	assert_indics{
		buffer:position_from_line(1), --
		buffer:position_from_line(3) + 4, --
		buffer:position_from_line(4) + 4, --
		buffer:position_from_line(6)
	}
	-- Regex search.
	ui.find.find_entry_text = 'ba.'
	ui.find.regex = true
	ui.find.find_next()
	assert_indics{
		buffer:position_from_line(2) + 3, --
		buffer:position_from_line(3), --
		buffer:position_from_line(4), --
		buffer:position_from_line(4) + 8
	}
	ui.find.regex = false
	-- Do not highlight short searches (potential performance issue).
	ui.find.find_entry_text = 'f'
	ui.find.find_next()
	local pos = buffer:indicator_end(ui.find.INDIC_FIND, 2)
	assert_equal(pos, 1)
	-- Verify turning off match highlighting works.
	ui.find.highlight_all_matches = false
	ui.find.find_entry_text = 'foo'
	ui.find.find_next()
	pos = buffer:indicator_end(ui.find.INDIC_FIND, 2)
	assert_equal(pos, 1)
	ui.find.find_entry_text = ''
	ui.find.highlight_all_matches = highlight_all_matches -- reset
	buffer:close(true)
end

function test_ui_find_incremental()
	buffer.new()
	buffer:set_text(table.concat({
		' foo', --
		'foobar', --
		'FOObaz', --
		'FOOquux'
	}, newline()))
	assert_equal(buffer.current_pos, 1)
	ui.find.incremental = true
	ui.find.find_entry_text = 'f' -- simulate 'f' keypress
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.selection_start, 1 + 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 1)
	ui.find.find_entry_text = 'fo' -- simulate 'o' keypress
	ui.find.find_entry_text = 'foo' -- simulate 'o' keypress
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.selection_start, 1 + 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	events.emit(events.FIND, ui.find.find_entry_text, true) -- simulate Find Next
	assert_equal(buffer.selection_start, buffer:position_from_line(2))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.find_entry_text = 'fooq' -- simulate 'q' keypress
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.selection_start, buffer:position_from_line(4))
	assert_equal(buffer.selection_end, buffer.selection_start + 4)
	ui.find.find_entry_text = 'foo' -- simulate backspace
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.selection_start, buffer:position_from_line(2))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	events.emit(events.FIND, ui.find.find_entry_text, true) -- simulate Find Next
	assert_equal(buffer.selection_start, buffer:position_from_line(3))
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.match_case = true
	events.emit(events.FIND, ui.find.find_entry_text, true) -- simulate Find Next, wrap
	assert_equal(buffer.selection_start, 1 + 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	ui.find.match_case = false
	ui.find.whole_word = true
	ui.find.find_entry_text = 'foob'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert(buffer.selection_empty, 'no text should be found')
	ui.find.find_entry_text = 'foobar'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer:get_sel_text(), 'foobar')
	ui.find.whole_word = false
	ui.find.find_entry_text = ''
	ui.find.incremental = false
	buffer:close(true)
end

function test_ui_find_incremental_highlight()
	local highlight_all_matches = ui.find.highlight_all_matches
	ui.find.highlight_all_matches = true
	buffer.new()
	buffer:set_text(table.concat({
		' foo', --
		'foobar', --
		'FOObaz', --
		'FOOquux'
	}, newline()))
	ui.find.incremental = true
	ui.find.find_entry_text = 'f' -- simulate 'f' keypress
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	local pos = buffer:indicator_end(ui.find.INDIC_FIND, 2)
	assert_equal(pos, 1) -- too short
	ui.find.find_entry_text = 'fo' -- simulate 'o' keypress
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	local indics = {
		buffer:position_from_line(1) + 1, --
		buffer:position_from_line(2), --
		buffer:position_from_line(3), --
		buffer:position_from_line(4)
	}
	local bit = 1 << ui.find.INDIC_FIND - 1
	for _, pos in ipairs(indics) do
		local mask = buffer:indicator_all_on_for(pos)
		assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
	end
	ui.find.find_entry_text = ''
	ui.find.incremental = false
	ui.find.highlight_all_matches = highlight_all_matches
	buffer:close(true)
end

function test_ui_find_incremental_not_found()
	buffer.new()
	buffer:set_text('foobar')
	ui.find.incremental = true
	ui.find.find_entry_text = 'b'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.current_pos, 4)
	ui.find.find_entry_text = 'bb'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer.current_pos, 1)
	events.emit(events.FIND, ui.find.find_entry_text, true) -- simulate Find Next
	assert_equal(buffer.current_pos, 1) -- cursor did not advance
	ui.find.find_entry_text = ''
	ui.find.incremental = false
	buffer:close(true)
end

function test_ui_find_find_regex_empty()
	buffer.new()
	buffer:set_text('foo\n\n\nfoo')
	ui.find.regex = true
	for _, text in ipairs{'^', '$', '^.*$'} do
		buffer:document_start()
		ui.find.find_entry_text = text
		for i = 1, buffer.line_count do
			ui.find.find_next()
			assert(buffer:line_from_position(buffer.current_pos), i)
			if #text == 1 then
				assert(buffer.selection_empty, 'zero-width find result expected')
			else
				assert_equal(buffer:get_sel_text(), buffer:get_line(i):match('^[^\r\n]*'))
			end
		end
		if #text > 1 then
			ui.find.find_next() -- should wrap
			assert_equal(buffer:line_from_position(buffer.current_pos), 1)
		end
	end
	ui.find.regex = false
	buffer:close(true)
end

function test_ui_find_find_prev_regex_empty()
	buffer.new()
	buffer:add_text('foo\n\n\nfoo')
	ui.find.find_entry_text, ui.find.regex = '$', true
	ui.find.find_prev()
	assert_equal(buffer:line_from_position(buffer.current_pos), buffer.line_count - 1)
	ui.find.regex = false
	buffer:close(true)
end
expected_failure(test_ui_find_find_prev_regex_empty) -- Scintilla bug?

function test_ui_find_find_in_files()
	ui.find.find_entry_text = 'foo'
	ui.find.match_case = true
	ui.find.find_in_files(_HOME .. '/test')
	assert_equal(buffer._type, _L['[Files Found Buffer]'])
	assert(buffer:get_text():find('\nDirectory: ' .. _HOME .. '[/\\]test[\r\n]'),
		'directory not shown')
	if #_VIEWS > 1 then view:unsplit() end
	local count = 0
	for filename, text in buffer:get_text():gmatch('\n([^:]+):%d+:([^\n]+)') do
		assert(not filename:find('^[/\\]'), 'invalid filename "%s"', filename)
		assert(text:find('foo'), '"foo" not found in "%s"', text)
		count = count + 1
	end
	assert(count > 0, 'no files found')
	local s = buffer:indicator_end(ui.find.INDIC_FIND, 0)
	while true do
		local e = buffer:indicator_end(ui.find.INDIC_FIND, s)
		if e == s then break end -- no more results
		assert_equal(buffer:text_range(s, e), 'foo')
		s = buffer:indicator_end(ui.find.INDIC_FIND, e + 1)
	end
	ui.find.goto_file_found(true) -- wraps around
	assert_equal(#_VIEWS, 2)
	assert(buffer.filename, 'not in file found result')
	ui.goto_view(1)
	assert_equal(view.buffer._type, _L['[Files Found Buffer]'])
	local filename, line_num = view.buffer:get_sel_text():match('^([^:]+):(%d+)')
	filename = file(_HOME .. '/test/' .. filename)
	ui.goto_view(-1)
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), tonumber(line_num))
	assert_equal(buffer:get_sel_text(), 'foo')
	ui.goto_view(1) -- files found buffer
	events.emit(events.KEYPRESS, '\n')
	assert_equal(buffer.filename, filename)
	ui.goto_view(1) -- files found buffer
	events.emit(events.DOUBLE_CLICK, nil, buffer:line_from_position(buffer.current_pos))
	assert_equal(buffer.filename, filename)
	buffer:close()
	ui.goto_view(1) -- files found buffer
	ui.find.goto_file_found(false) -- wraps around
	assert(buffer.filename and buffer.filename ~= filename, 'opened the same file')
	buffer:close()
	ui.goto_view(1) -- files found buffer
	ui.find.find_entry_text = ''
	view:unsplit()
	buffer:close()

	assert_raises(function() ui.find.find_in_files('', 1) end, 'string/table/nil expected, got number')
	assert_raises(function() ui.find.goto_file_found() end, 'boolean/number expected')
end

function test_ui_find_find_in_files_interactive()
	if WIN32 then return end -- TODO: cannot cd to network path
	local cwd = lfs.currentdir()
	lfs.chdir(_HOME)
	local filter = ui.find.find_in_files_filters[_HOME]
	ui.find.find_in_files_filters[_HOME] = nil -- ensure not set
	ui.find.find_entry_text = 'foo'
	ui.find.in_files = true
	ui.find.replace_entry_text = '/test'
	events.emit(events.FIND, ui.find.find_entry_text, true)
	local results = buffer:get_text()
	assert(results:find('Directory: '), 'directory not shown')
	assert(results:find('Filter: /test\n'), 'no filter defined')
	assert(results:find('find/foo.c'), 'foo.c not found')
	assert(results:find('find/foo.h'), 'foo.h not found')
	assert_equal(table.concat(ui.find.find_in_files_filters[_HOME], ','), '/test')
	buffer:clear_all()
	ui.find.replace_entry_text = '/test,.c'
	events.emit(events.FIND, ui.find.find_entry_text, true)
	results = buffer:get_text()
	assert(results:find('Filter: /test,.c\n'), 'no filter defined')
	assert(results:find('find/foo.c'), 'foo.c not found')
	assert(not results:find('find/foo.h'), 'foo.h found')
	assert_equal(table.concat(ui.find.find_in_files_filters[_HOME], ','), '/test,.c')
	if not CURSES then
		-- Verify save and restore of replacement text and directory filters.
		ui.find.focus{in_files = false}
		assert_equal(ui.find.in_files, false)
		ui.find.replace_entry_text = 'bar'
		ui.find.focus{in_files = true}
		assert_equal(ui.find.in_files, true)
		assert_equal(ui.find.replace_entry_text, '/test,.c')
		ui.find.focus{in_files = false}
		assert_equal(ui.find.replace_entry_text, 'bar')
	end
	ui.find.find_entry_text = ''
	ui.find.in_files = false
	buffer:close()
	ui.goto_view(1)
	view:unsplit()
	ui.find.find_in_files_filters[_HOME] = filter
	lfs.chdir(cwd)
end

function test_ui_find_in_files_single_char()
	ui.find.find_entry_text = 'z'
	ui.find.find_in_files(_HOME .. '/test')
	ui.find.goto_file_found(true)
	assert_equal(buffer:get_sel_text(), 'z')
	ui.find.find_entry_text = ''
	buffer:close()
	ui.goto_view(1)
	view:unsplit()
	buffer:close()
end

function test_ui_find_replace()
	buffer.new()
	buffer:set_text('foofoo')
	ui.find.find_entry_text = 'foo'
	ui.find.find_next()
	ui.find.replace_entry_text = 'bar'
	ui.find.replace()
	assert_equal(buffer.selection_start, 4)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	assert_equal(buffer:get_sel_text(), 'foo')
	assert_equal(buffer:get_text(), 'barfoo')
	ui.find.regex = true
	ui.find.find_entry_text = 'f(.)\\1'
	ui.find.find_next()
	ui.find.replace_entry_text = 'b\\1\\1\\u1234'
	ui.find.replace()
	assert_equal(buffer:get_text(), 'barbooሴ')
	ui.find.regex = false
	ui.find.find_entry_text = 'quux'
	ui.find.find_next()
	ui.find.replace_entry_text = ''
	ui.find.replace()
	assert_equal(buffer:get_text(), 'barbooሴ')
	ui.find.find_entry_text, ui.find.replace_entry_text = '', ''
	buffer:close(true)
end

function test_ui_find_replace_text_save_restore()
	if CURSES then return end -- there are focus issues in curses
	ui.find.focus()
	ui.find.find_entry_text = 'foo'
	ui.find.replace_entry_text = 'bar'
	ui.find.find_next()
	ui.find.focus() -- simulate activating "Find"
	assert_equal(ui.find.replace_entry_text, 'bar')
	ui.find.focus{in_files = true} -- simulate activating "Find in Files"
	assert(ui.find.replace_entry_text ~= 'bar', 'filter entry text not set')
	ui.find.focus{in_files = false} -- simulate activating "Find"
	assert_equal(ui.find.replace_entry_text, 'bar')
	ui.find.replace_entry_text = 'baz'
	ui.find.replace_all()
	ui.find.focus() -- simulate activating "Find"
	assert_equal(ui.find.replace_entry_text, 'baz')
end

function test_ui_find_replace_all()
	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	local text = table.concat({
		'foo', --
		'foobar', --
		'foobaz', --
		'foofoo'
	}, '\n')
	buffer:set_text(text)
	ui.find.find_entry_text, ui.find.replace_entry_text = 'foo', 'bar'
	ui.find.replace_all()
	assert_equal(buffer:get_text(), 'bar\nbarbar\nbarbaz\nbarbar')
	buffer:undo()
	assert_equal(buffer:get_text(), text) -- verify atomic undo
	ui.find.regex = true
	buffer:set_sel(buffer:position_from_line(2), buffer:position_from_line(4) + 3)
	ui.find.find_entry_text, ui.find.replace_entry_text = 'f(.)\\1', 'b\\1\\1'
	ui.find.replace_all() -- replace in selection
	assert_equal(buffer:get_text(), 'foo\nboobar\nboobaz\nboofoo')
	assert_equal(buffer.selection_start, buffer:position_from_line(2))
	assert_equal(buffer.selection_end, buffer:position_from_line(4) + 3)
	ui.find.regex = false
	buffer:undo()
	ui.find.find_entry_text, ui.find.replace_entry_text = 'foo', ''
	ui.find.replace_all()
	assert_equal(buffer:get_text(), '\nbar\nbaz\n')
	ui.find.find_entry_text, ui.find.replace_entry_text = 'quux', ''
	ui.find.replace_all()
	assert_equal(buffer:get_text(), '\nbar\nbaz\n')
	buffer:undo()
	buffer:set_selection(1, 4)
	buffer:add_selection(buffer:position_from_line(3), buffer:position_from_line(3) + 3)
	ui.find.find_entry_text, ui.find.replace_entry_text = 'foo', 'quux'
	ui.find.replace_all() -- replace in multiple selection
	assert_equal(buffer:get_text(), 'quux\nfoobar\nquuxbaz\nfoofoo')
	assert_equal(buffer.selections, 2)
	assert_equal(buffer.selection_n_start[1], 1)
	assert_equal(buffer.selection_n_end[1], 5)
	assert_equal(buffer.selection_n_start[2], buffer:position_from_line(3))
	assert_equal(buffer.selection_n_end[2], buffer:position_from_line(3) + 4)
	ui.find.find_entry_text, ui.find.replace_entry_text = '', ''
	buffer:close(true)
end

function test_ui_find_replace_all_empty_matches()
	buffer.new()
	buffer:set_text('1\n2\n3\n4')
	ui.find.find_entry_text, ui.find.replace_entry_text = '$', ','
	ui.find.regex = true
	ui.find.replace_all()
	assert_equal(buffer:get_text(), '1,\n2,\n3,\n4,')
	buffer:undo()
	buffer:set_sel(buffer:position_from_line(2), buffer:position_from_line(4))
	ui.find.replace_all()
	assert_equal(buffer:get_text(), '1\n2,\n3,\n4')
	buffer:undo()
	ui.find.find_entry_text, ui.find.replace_entry_text = '^', '$'
	ui.find.replace_all()
	assert_equal(buffer:get_text(), '$1\n$2\n$3\n$4')
	ui.find.find_entry_text, ui.find.replace_entry_text = '', ''
	ui.find.regex = false
	buffer:close(true)
end
if OSX then expected_failure(test_ui_find_replace_all_empty_matches) end

function test_ui_find_replace_regex_transforms()
	buffer.new()
	buffer:set_text('foObaRbaz')
	ui.find.find_entry_text = 'f([oO]+)ba(..)'
	ui.find.regex = true
	local replacements = {
		['f\\1ba\\2'] = 'foObaRbaz', --
		['f\\u\\1ba\\l\\2'] = 'fOObarbaz', --
		['f\\U\\1ba\\2'] = 'fOOBARBaz', --
		['f\\U\\1ba\\l\\2'] = 'fOOBArBaz', --
		['f\\U\\1\\Eba\\2'] = 'fOObaRbaz', --
		['f\\L\\1ba\\2'] = 'foobarbaz', --
		['f\\L\\1ba\\u\\2'] = 'foobaRbaz', --
		['f\\L\\1ba\\U\\2'] = 'foobaRBaz', --
		['f\\L\\1\\Eba\\2'] = 'foobaRbaz', --
		['f\\L\\u\\1ba\\2'] = 'fOobarbaz', --
		['f\\L\\u\\1ba\\U\\l\\2'] = 'fOobarBaz', --
		['f\\L\\u\\1\\Eba\\2'] = 'fOobaRbaz', --
		['f\\1ba\\U\\2'] = 'foObaRBaz', --
		['f\\1ba\\L\\2'] = 'foObarbaz', --
		['f\\1ba\\U\\l\\2'] = 'foObarBaz', --
		[''] = 'az', --
		['\\0'] = 'foObaRbaz', --
		['\\r\\n\\t'] = '\r\n\taz'
	}
	for regex, replacement in pairs(replacements) do
		ui.find.replace_entry_text = regex
		ui.find.find_next()
		ui.find.replace()
		assert_equal(buffer:get_text(), replacement)
		buffer:undo()
		ui.find.replace_all()
		assert_equal(buffer:get_text(), replacement)
		buffer:undo()
	end
	ui.find.find_entry_text, ui.find.replace_entry_text = '', ''
	ui.find.regex = false
	buffer:close(true)
end

function test_ui_find_replace_all_anchors()
	buffer.new()
	buffer:set_text(table.concat({
		'  foo', --
		'    bar', --
		'  baz'
	}, newline()))
	ui.find.find_entry_text = '^  '
	ui.find.regex = true
	ui.find.replace_all()
	assert_equal(buffer:get_text(), table.concat({
		'foo', --
		'  bar', --
		'baz'
	}, newline()))
	ui.find.find_entry_text = ''
	ui.find.regex = false
	buffer:close(true)
end

function test_ui_find_focus()
	if CURSES then return end -- there are focus issues in curses
	buffer:new()
	buffer:append_text(' foo\n\n foo')
	ui.find.focus{incremental = true}
	ui.find.find_entry_text = 'foo'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	buffer:line_down()
	ui.find.focus() -- should turn off incremental find
	ui.find.find_entry_text = 'f'
	if CURSES then events.emit(events.FIND_TEXT_CHANGED) end -- simulate
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	buffer:close(true)

	assert_raises(function() ui.find.focus(1) end, 'table/nil expected, got number')
end

function test_history()
	local filename1 = file(_HOME .. '/test/modules/textadept/history/1')
	io.open_file(filename1)
	textadept.history.clear() -- clear initial buffer switch record
	buffer:goto_line(5)
	textadept.history.back() -- should not do anything
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	buffer:add_text('foo')
	buffer:goto_line(5 + textadept.history.minimum_line_distance + 1)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	assert_equal(buffer.current_pos, buffer.line_end_position[5])
	textadept.history.forward() -- should stay put (no edits have been made since)
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	buffer:new_line()
	buffer:add_text('bar') -- close changes should update current history
	local filename2 = file(_HOME .. '/test/modules/textadept/history/2')
	io.open_file(filename2)
	buffer:goto_line(10)
	buffer:add_text('baz')
	textadept.history.back() -- should ignore initial file load and go back to file 1
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	textadept.history.back() -- should stay put (updated history from line 5 to line 6)
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	textadept.history.forward()
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	textadept.history.back()
	buffer:goto_line(15)
	buffer:clear() -- erases forward history to file 2
	textadept.history.forward() -- should not do anything
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	textadept.history.forward()
	view:goto_buffer(1)
	assert_equal(buffer.filename, filename2)
	buffer:goto_line(20)
	buffer:add_text('quux')
	view:goto_buffer(-1)
	assert_equal(buffer.filename, filename1)
	buffer:undo() -- undo delete of '\n'
	buffer:undo() -- undo add of 'foo'
	buffer:redo() -- re-add 'foo'
	textadept.history.back() -- undo and redo should not affect history
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 20)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	buffer:target_whole_document()
	buffer:replace_target(string.rep(newline(), buffer.line_count)) -- whole buffer replacements should not affect history (e.g. clang-format)
	textadept.history.forward()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	view:goto_buffer(1)
	assert_equal(buffer.filename, filename2)
	buffer:close(true)
	textadept.history.back() -- should re-open file 2
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 20)
	buffer:close(true)
	buffer:close(true)

	assert_raises(function() textadept.history.record(1) end, 'string/nil expected, got number')
	assert_raises(function() textadept.history.record('', true) end,
		'number/nil expected, got boolean')
	assert_raises(function() textadept.history.record('', 1, '') end,
		'number/nil expected, got string')
end

function test_history_soft_records()
	local filename1 = file(_HOME .. '/test/modules/textadept/history/1')
	io.open_file(filename1)
	textadept.history.clear() -- clear initial buffer switch record
	buffer:goto_line(5)
	local filename2 = file(_HOME .. '/test/modules/textadept/history/2')
	io.open_file(filename2)
	buffer:goto_line(10)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	buffer:goto_line(15)
	textadept.history.forward() -- should update soft record from line 5 to 15
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	buffer:goto_line(20)
	textadept.history.back() -- should update soft record from line 10 to 20
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	textadept.history.forward()
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 20)
	buffer:goto_line(10)
	buffer:add_text('foo') -- should update soft record from line 20 to 10 and make it hard
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	textadept.history.forward()
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	buffer:goto_line(20)
	buffer:add_text('bar') -- should create a new record
	textadept.history.back()
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	buffer:close(true)
	buffer:close(true)
end

function test_history_per_view()
	local filename1 = file(_HOME .. '/test/modules/textadept/history/1')
	io.open_file(filename1)
	textadept.history.clear() -- clear initial buffer switch record
	buffer:goto_line(5)
	buffer:add_text('foo')
	buffer:goto_line(10)
	buffer:add_text('bar')
	view:split()
	textadept.history.back() -- no history for this view
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	local filename2 = file(_HOME .. '/test/modules/textadept/history/2')
	io.open_file(filename2)
	buffer:goto_line(15)
	buffer:add_text('baz')
	buffer:goto_line(20)
	textadept.history.back()
	assert_equal(buffer.filename, filename2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 15)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	textadept.history.back() -- no more history for this view
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	ui.goto_view(-1)
	textadept.history.back()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	textadept.history.forward()
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	textadept.history.forward() -- no more history for this view
	assert_equal(buffer.filename, filename1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	view:unsplit()
	view:goto_buffer(1)
	buffer:close(true)
	buffer:close(true)
end

function test_history_print_buffer()
	local tabs = ui.tabs
	ui.tabs = true
	ui.print('foo')
	textadept.history.back()
	assert(buffer._type ~= _L['[Message Buffer]'])
	textadept.history.forward()
	assert_equal(buffer._type, _L['[Message Buffer]'])
	buffer:close()
	ui.tabs = tabs -- restore
end

function test_history_undo_full_buffer_change()
	if WIN32 and CURSES then return end -- filter_through not implemented
	buffer.new()
	local lines = {}
	for i = 99, 1, -1 do lines[#lines + 1] = tostring(i) end
	buffer:add_text(table.concat(lines, newline()))
	buffer:goto_line(50)
	buffer:add_text('1')
	textadept.editing.filter_through(not WIN32 and 'sort -n' or 'sort')
	ui.update()
	assert(buffer:get_line(buffer:line_from_position(buffer.current_pos)) ~= '150' .. newline(),
		'not sorted')
	local pos, first_visible_line = buffer.current_pos, view.first_visible_line
	buffer:undo()
	-- Verify the view state was restored.
	ui.update()
	if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
	assert_equal(buffer.current_pos, pos)
	assert_equal(buffer:get_line(buffer:line_from_position(buffer.current_pos)), '150' .. newline())
	assert_equal(view.first_visible_line, first_visible_line)
	buffer:redo()
	-- Verify the previous view state was kept.
	ui.update()
	if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
	assert_equal(buffer.current_pos, pos)
	assert_equal(view.first_visible_line, first_visible_line)
	buffer:close(true)
end

function test_history_multiple_selection_edit()
	for i = 1, 5 do ui.print(i) end
	for i = 5, 1, -1 do ui.print(i) end
	if #_VIEWS > 1 then view:unsplit() end
	buffer:goto_pos(buffer:position_from_line(buffer.line_count // 2))
	buffer:insert_text(-1, ' ')
	buffer:goto_line(1)
	textadept.editing.select_word() -- select '1' on first line
	textadept.editing.select_word() -- select '1' on last line
	assert_equal(buffer.selections, 2)
	for i = 1, buffer.selections do
		buffer:set_target_range(buffer.selection_n_start[i], buffer.selection_n_end[i])
		buffer:replace_target('foo') -- simulate typing into multiple selections
	end
	textadept.history.back() -- should not jump between multi-line edits
	assert_equal(buffer:line_from_position(buffer.current_pos), buffer.line_count // 2)
	textadept.history.forward()
	assert_equal(buffer:line_from_position(buffer.current_pos), buffer.line_count - 1)
	buffer:close(true)
end

function test_macro_record_play_save_load()
	textadept.macros.save() -- should not do anything
	textadept.macros.play() -- should not do anything
	assert_equal(#_BUFFERS, 1)
	assert(not buffer.modify, 'a macro was played')

	textadept.macros.record()
	events.emit(events.MENU_CLICKED, 1) -- File > New
	buffer:add_text('f')
	events.emit(events.CHAR_ADDED, string.byte('f'))
	events.emit(events.FIND, 'f', true)
	events.emit(events.REPLACE, 'b')
	buffer:replace_sel('a') -- typing would do this
	events.emit(events.CHAR_ADDED, string.byte('a'))
	buffer:add_text('r')
	events.emit(events.CHAR_ADDED, string.byte('r'))
	local enclose = not OSX and (not CURSES and 'alt' or 'meta') .. '+"' or 'ctrl+"'
	events.emit(events.KEYPRESS, enclose)
	textadept.macros.play() -- should not do anything
	textadept.macros.save() -- should not do anything
	textadept.macros.load() -- should not do anything
	textadept.macros.record() -- stop
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer:get_text(), '"ar"')
	buffer:close(true)
	textadept.macros.play()
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer:get_text(), '"ar"')
	buffer:close(true)
	local filename = os.tmpname()
	textadept.macros.save(filename)
	textadept.macros.record()
	textadept.macros.record()
	textadept.macros.load(filename)
	textadept.macros.play()
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer:get_text(), '"ar"')
	buffer:close(true)
	os.remove(filename)

	assert_raises(function() textadept.macros.save(1) end, 'string/nil expected, got number')
	assert_raises(function() textadept.macros.load(1) end, 'string/nil expected, got number')
	assert_raises(function() textadept.macros.play(1) end, 'string/nil expected, got number')
end

function test_macro_registers()
	buffer.new()
	buffer:append_text('foobar')
	textadept.macros.record()
	events.emit(events.KEYPRESS, 'right')
	assert_equal(buffer.current_pos, 2)
	textadept.macros.record() -- stop
	textadept.macros.play()
	assert_equal(buffer.current_pos, 3)
	textadept.macros.record() -- should store previously recorded macro (char right) in register 0
	events.emit(events.KEYPRESS, 'left')
	assert_equal(buffer.current_pos, 2)
	textadept.macros.record() -- stop
	textadept.macros.play('0') -- char right (should store previously recorded macro, char left)
	assert_equal(buffer.current_pos, 3)
	textadept.macros.play('0') -- char left
	assert_equal(buffer.current_pos, 2)
	textadept.macros.save('test1')
	assert(lfs.attributes(_USERHOME .. '/macros/test1'), 'macro not saved to _USERHOME/macros/')
	textadept.macros.record()
	for i = 1, 2 do events.emit(events.KEYPRESS, 'right') end
	textadept.macros.record() -- stop
	assert_equal(buffer.current_pos, 4)
	textadept.macros.play('test1') -- char left
	assert_equal(buffer.current_pos, 3)
	textadept.macros.play() -- not 2 x char right
	assert_equal(buffer.current_pos, 2)
	os.remove(_USERHOME .. '/macros/test1')
	buffer:close(true)
end

function test_macro_record_play_with_keys_only()
	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	buffer:append_text('foo\nbar\nbaz\n')
	local start_stop = not OSX and (not CURSES and 'alt+,' or 'meta+,') or 'ctrl+,'
	local play = not OSX and (not CURSES and 'alt+.' or 'meta+.') or 'ctrl+.'
	events.emit(events.KEYPRESS, start_stop) -- start recording
	events.emit(events.KEYPRESS, 'end')
	events.emit(events.KEYPRESS, '\n')
	buffer:new_line()
	events.emit(events.KEYPRESS, 'down')
	events.emit(events.KEYPRESS, start_stop) -- stop recording
	assert_equal(buffer:get_text(), 'foo\n\nbar\nbaz\n')
	assert_equal(buffer.current_pos, buffer:position_from_line(3))
	events.emit(events.KEYPRESS, play)
	assert_equal(buffer:get_text(), 'foo\n\nbar\n\nbaz\n')
	assert_equal(buffer.current_pos, buffer:position_from_line(5))
	events.emit(events.KEYPRESS, play)
	assert_equal(buffer:get_text(), 'foo\n\nbar\n\nbaz\n\n')
	assert_equal(buffer.current_pos, buffer:position_from_line(7))
	events.emit(events.KEYPRESS, start_stop) -- start recording
	events.emit(events.KEYPRESS, start_stop) -- stop recording
	events.emit(events.KEYPRESS, not OSX and (not CURSES and 'ctrl+alt+r' or 'meta+r') or 'ctrl+cmd+r')
	events.emit(events.KEYPRESS, '0') -- play previously recorded macro
	assert_equal(buffer.current_pos, buffer:position_from_line(8))
	buffer:close(true)
end

function test_menu_menu_functions()
	buffer.new()
	buffer:append_text('foo\nfoo\nfoo\n')
	textadept.editing.select_word()
	textadept.editing.select_word()
	assert_equal(buffer.selections, 2)
	textadept.menu.menubar['Edit/Select/Deselect Word'][2]()
	assert_equal(buffer.selections, 1)
	assert_equal(buffer:get_sel_text(), 'foo')
	textadept.menu.menubar['Edit/Selection/Upper Case Selection'][2]()
	assert_equal(buffer:get_sel_text(), 'FOO')
	buffer:char_left()
	textadept.menu.menubar['Edit/Selection/Lower Case Selection'][2]()
	assert(buffer:get_text():find('^foo'), 'did not lower case current word')
	assert(buffer.selection_empty, 'lower case kept selection')
	assert_equal(buffer.current_pos, 1) -- caret should be restored to original position
	textadept.menu.menubar['Buffer/Indentation/Tab width: 8'][2]()
	assert_equal(buffer.tab_width, 8)
	textadept.menu.menubar['Buffer/EOL Mode/CRLF'][2]()
	assert_equal(buffer.eol_mode, buffer.EOL_CRLF)
	textadept.menu.menubar['Buffer/Encoding/CP-1252 Encoding'][2]()
	assert_equal(buffer.encoding, 'CP1252')
	buffer:set_text('foo')
	textadept.menu.menubar['Edit/Delete Word'][2]()
	assert_equal(buffer:get_text(), '')
	buffer:set_text('(foo)')
	buffer:home()
	textadept.menu.menubar['Edit/Match Brace'][2]()
	assert_equal(buffer.char_at[buffer.current_pos], string.byte(')'))
	buffer:set_text('foo f')
	buffer:line_end()
	textadept.menu.menubar['Edit/Complete Word'][2]()
	assert_equal(buffer:get_text(), 'foo foo')
	buffer:set_text(table.concat({'2', '1', '3', ''}, newline()))
	if not (WIN32 and CURSES) then
		textadept.menu.menubar['Edit/Filter Through'][2]()
		ui.command_entry:set_text('sort')
		events.emit(events.KEYPRESS, '\n')
		assert_equal(buffer:get_text(), table.concat({'1', '2', '3', ''}, newline()))
	end
	buffer:set_text('foo')
	buffer:line_end()
	textadept.menu.menubar['Edit/Selection/Enclose as XML Tags'][2]()
	assert_equal(buffer:get_text(), '<foo></foo>')
	assert_equal(buffer.current_pos, 6)
	buffer:undo()
	assert_equal(buffer:get_text(), 'foo') -- verify atomic undo
	textadept.menu.menubar['Edit/Selection/Enclose as Single XML Tag'][2]()
	assert_equal(buffer:get_text(), '<foo />')
	assert_equal(buffer.current_pos, buffer.line_end_position[1])
	if not CURSES then -- there are focus issues in curses
		textadept.menu.menubar['Search/Find in Files'][2]()
		assert(ui.find.in_files, 'not finding in files')
		textadept.menu.menubar['Search/Find'][2]()
		assert(not ui.find.in_files, 'finding in files')
	end
	buffer:clear_all()
	buffer:insert_text(-1, '.')
	textadept.menu.menubar['Tools/Show Style'][2]()
	assert(view:call_tip_active(), 'style not shown')
	view:call_tip_cancel()
	local use_tabs = buffer.use_tabs
	textadept.menu.menubar['Buffer/Indentation/Toggle Use Tabs'][2]()
	assert(buffer.use_tabs ~= use_tabs, 'use tabs not toggled')
	view:split()
	ui.update()
	local size = view.size
	textadept.menu.menubar['View/Grow View'][2]()
	assert(view.size > size, 'view shrunk')
	textadept.menu.menubar['View/Shrink View'][2]()
	assert_equal(view.size, size)
	view.folding = true -- view.property['fold'] = '1'
	buffer:set_text('if foo then\n  bar\nend')
	buffer:set_lexer('lua')
	buffer:colorize(1, -1)
	textadept.menu.menubar['View/Toggle Current Fold'][2]()
	assert_equal(view.fold_expanded[buffer:line_from_position(buffer.current_pos)], false)
	local wrap_mode = view.wrap_mode
	textadept.menu.menubar['View/Toggle Wrap Mode'][2]()
	assert(view.wrap_mode ~= wrap_mode, 'wrap mode not toggled')
	local line_margin_width = view.margin_width_n[1]
	textadept.menu.menubar['View/Toggle Margins'][2]()
	assert(view.margin_width_n[1] == 0, 'margins not hidden')
	textadept.menu.menubar['View/Toggle Margins'][2]()
	assert(view.margin_width_n[1] == line_margin_width, 'margins not hidden')
	local indentation_guides = view.indentation_guides
	textadept.menu.menubar['View/Toggle Show Indent Guides'][2]()
	assert(view.indentation_guides ~= indentation_guides, 'indentation guides not toggled')
	local view_whitespace = view.view_ws
	textadept.menu.menubar['View/Toggle View Whitespace'][2]()
	assert(view.view_ws ~= view_whitespace, 'view whitespace not toggled')
	local virtual_space = buffer.virtual_space_options
	textadept.menu.menubar['View/Toggle Virtual Space'][2]()
	assert(buffer.virtual_space_options ~= virtual_space, 'virtual space not toggled')
	ui.goto_view(-1)
	view:unsplit()
	buffer:close(true)
end

function test_menu_functions_interactive()
	buffer.new()
	local name = buffer.lexer_language
	textadept.menu.menubar['Buffer/Select Lexer...'][2]()
	assert(buffer.lexer_language ~= name, 'lexer unchanged')
	buffer:close()

	io.open_file(_HOME .. '/core/init.lua')
	textadept.menu.menubar['Tools/Quick Open/Quickly Open Current Directory'][2]()
	assert(buffer.filename:find(file(_HOME .. '/core/')), 'did not quickly open in current directory')
	buffer:close()
	buffer:close()

	textadept.menu.menubar['Help/Show Manual'][2]()
	textadept.menu.menubar['Help/About'][2]()

	buffer.new()
	table.insert(textadept.menu.context_menu, {'Test', function() end})
	textadept.menu.context_menu = textadept.menu.context_menu -- should not error
	ui.popup_menu(ui.context_menu)
	buffer:close(true)

	textadept.menu.tab_context_menu = textadept.menu.tab_context_menu -- should not error

	textadept.menu.foo = 'foo'
	assert_equal(textadept.menu.foo, 'foo')
end

function test_menu_select_command_interactive()
	local num_buffers = #_BUFFERS
	textadept.menu.select_command()
	assert(#_BUFFERS > num_buffers, 'new buffer not created')
	buffer:close()
end

function test_run_compile_run()
	if WIN32 or OSX then return end -- TODO:
	textadept.run.compile() -- should not do anything
	assert_equal(ui.command_entry.active, false)
	textadept.run.run() -- should not do anything
	assert_equal(ui.command_entry.active, false)
	assert_equal(#_BUFFERS, 1)
	assert(not buffer.modify, 'a command was run')

	local compile_file = _HOME .. '/test/modules/textadept/run/compile.lua'
	textadept.run.compile(compile_file)
	assert_equal(ui.command_entry.active, true)
	assert(ui.command_entry:get_text():find('^luac'), 'incorrect compile command')
	events.emit(events.KEYPRESS, '\n')
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer._type, _L['[Output Buffer]'])
	ui.update() -- process output
	assert(buffer:get_text():find("'end' expected"), 'no compile error')
	assert(buffer:get_text():find('> exit status: %d+'), 'no compile error')
	if #_VIEWS > 1 then view:unsplit() end
	view:goto_buffer(-1) -- hide output buffer
	textadept.run.goto_error(true) -- wraps
	assert_equal(#_VIEWS, 2)
	assert_equal(buffer.filename, compile_file)
	assert_equal(buffer:line_from_position(buffer.current_pos), 3)
	assert(buffer.annotation_text[3]:find("'end' expected"), 'annotation not visible')
	ui.goto_view(1) -- output buffer
	assert_equal(buffer._type, _L['[Output Buffer]'])
	assert(buffer:get_sel_text():find("'end' expected"), 'compile error not selected')
	local markers = buffer:marker_get(buffer:line_from_position(buffer.current_pos))
	assert(markers & 1 << textadept.run.MARK_ERROR - 1 > 0)
	local s = buffer:indicator_end(textadept.run.INDIC_ERROR, buffer.selection_start)
	local e = buffer:indicator_end(textadept.run.INDIC_ERROR, s + 1)
	assert(buffer:text_range(s, e):find("^'end' expected"), 'compile error not indicated')
	events.emit(events.KEYPRESS, '\n')
	assert_equal(buffer.filename, compile_file)
	ui.goto_view(1) -- output buffer
	events.emit(events.DOUBLE_CLICK, nil, buffer:line_from_position(buffer.current_pos) + 1)
	assert_equal(buffer._type, _L['[Output Buffer]']) -- there was no error to go to
	events.emit(events.DOUBLE_CLICK, nil, buffer:line_from_position(buffer.current_pos))
	assert_equal(buffer.filename, compile_file)
	textadept.run.compile() -- clears annotation
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	view:goto_buffer(1)
	assert(not buffer.annotation_text[3]:find("'end' expected"), 'annotation visible')
	buffer:close() -- compile_file

	local run_file = _HOME .. '/test/modules/textadept/run/run.lua'
	textadept.run.run_commands[run_file] = function()
		return textadept.run.run_commands.lua, run_file:match('^(.+[/\\])') -- intentional trailing '/'
	end
	io.open_file(run_file)
	textadept.run.run()
	assert_equal(ui.command_entry.active, true)
	assert(ui.command_entry:get_text():find('^lua'), 'incorrect run command')
	events.emit(events.KEYPRESS, '\n')
	assert_equal(buffer._type, _L['[Output Buffer]'])
	ui.update() -- process output
	assert(buffer:get_text():find('attempt to call a nil value'), 'no run error')
	textadept.run.goto_error(false)
	assert_equal(buffer.filename, run_file)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	textadept.run.goto_error(false)
	assert_equal(buffer.filename, run_file)
	assert_equal(buffer:line_from_position(buffer.current_pos), 1)
	ui.goto_view(1)
	markers = buffer:marker_get(buffer:line_from_position(buffer.current_pos))
	assert(markers & 1 << textadept.run.MARK_WARNING - 1 > 0)
	local s = buffer:indicator_end(textadept.run.INDIC_WARNING, buffer.selection_start)
	local e = buffer:indicator_end(textadept.run.INDIC_WARNING, s + 1)
	assert_equal(buffer:text_range(s, e), 'warning: foo')
	ui.goto_view(-1)
	textadept.run.goto_error(false)
	assert_equal(buffer.filename, compile_file)
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close() -- compile_file
	buffer:close() -- run_file
	buffer:close() -- output buffer

	assert_raises(function() textadept.run.compile({}) end, 'string/nil expected, got table')
	assert_raises(function() textadept.run.run({}) end, 'string/nil expected, got table')
	assert_raises(function() textadept.run.goto_error() end, 'boolean/number expected')
end

function test_run_distinct_command_histories()
	if WIN32 or OSX then return end -- TODO:
	local run_file = _HOME .. '/test/modules/textadept/run/foo.lua'
	io.open_file(run_file)
	textadept.run.run()
	local orig_run_command = ui.command_entry:get_text()
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	assert(buffer:get_text():find('nil'), 'unexpected argument was passed to run command')
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
	textadept.run.run()
	ui.command_entry:append_text(' bar')
	local run_command = ui.command_entry:get_text()
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	assert(buffer:get_text():find('bar'), 'argument not passed to run command')
	if QT then ui.update() end -- process exit
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close() -- output buffer
	textadept.run.run()
	assert_equal(ui.command_entry:get_text(), run_command)
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), orig_run_command)
	events.emit(events.KEYPRESS, 'down')
	assert_equal(ui.command_entry:get_text(), run_command)
	events.emit(events.KEYPRESS, 'esc')
	buffer:close()

	buffer.new()
	buffer.filename = 'foo.lua'
	textadept.run.run()
	run_command = ui.command_entry:get_text()
	assert(not run_command:find('bar'), 'argument persisted to another run command')
	events.emit(events.KEYPRESS, 'up')
	assert_equal(ui.command_entry:get_text(), run_command) -- no prior history
	events.emit(events.KEYPRESS, 'esc')
	buffer:close()
end

function test_run_no_prompt()
	if WIN32 then return end -- TODO: cannot cd to network path
	io.open_file(_HOME .. '/test/modules/textadept/run/foo.lua')
	local run_without_prompt = textadept.run.run_without_prompt
	textadept.run.run_without_prompt = true
	textadept.run.run()
	assert_equal(ui.command_entry.active, false)
	assert_equal(buffer._type, _L['[Output Buffer]'])
	ui.update() -- process output
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
	buffer:close()
	textadept.run.run_without_prompt = run_without_prompt -- restore
end

function test_run_no_command()
	if WIN32 then return end -- TODO: cannot cd to network path
	io.open_file(_HOME .. '/test/modules/textadept/run/foo.txt')
	textadept.run.run()
	if not OSX then assert_equal(ui.command_entry.active, true) end -- macOS has focus issues here
	assert_equal(ui.command_entry:get_text(), '')
	ui.command_entry:set_text(not WIN32 and 'cat %f' or 'type %f')
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	assert(buffer:get_text():find('bar'), 'did not run command')
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
	textadept.run.run()
	assert(ui.command_entry:get_text():find(not WIN32 and '^cat' or '^type'),
		'previous command not saved')
	events.emit(events.KEYPRESS, 'esc')
	buffer:close()
end

function test_run_build()
	if WIN32 or OSX then return end -- TODO:
	local build_command = 'lua modules/textadept/run/build.lua'
	textadept.run.build_commands[_HOME] = function()
		return build_command, _HOME .. '/test/' -- intentional trailing '/'
	end
	textadept.run.stop() -- should not do anything
	textadept.run.build(_HOME)
	assert_equal(ui.command_entry.active, true)
	assert_equal(ui.command_entry:get_text(), build_command)
	events.emit(events.KEYPRESS, '\n')
	if #_VIEWS > 1 then view:unsplit() end
	assert_equal(buffer._type, _L['[Output Buffer]'])
	sleep(0.1) -- ensure process is running
	buffer:add_text('foo')
	buffer:new_line() -- should send previous line as stdin
	sleep(0.1) -- ensure process processed stdin
	if QT then ui.update() end -- ensure Qt processed stdin
	textadept.run.stop()
	ui.update() -- process output
	assert(buffer:get_text():find('> cd '), 'did not change directory')
	assert(buffer:get_text():find('build%.lua'), 'did not run build command')
	assert(buffer:get_text():find('read "foo"'), 'did not send stdin')
	if QT then ui.update() end -- process exit
	assert(buffer:get_text():find('> exit status: 9'), 'build not stopped')
	textadept.run.stop() -- should not do anything
	buffer:close()
end

function test_run_build_no_command()
	if WIN32 then return end -- TODO: cannot cd to network path
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	lfs.mkdir(dir .. '/.hg') -- simulate version control
	io.open_file(dir .. '/BuildFile')
	buffer:save()
	textadept.run.build()
	assert_equal(ui.command_entry:get_text(), '')
	ui.command_entry:set_text(not WIN32 and 'ls' or 'dir')
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	assert(buffer:get_text():find('BuildFile'), 'did not run command')
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
	textadept.run.build()
	assert(ui.command_entry:get_text():find(not WIN32 and '^ls' or '^dir'),
		'previous command not saved')
	events.emit(events.KEYPRESS, 'esc')
	textadept.run.build_commands[dir] = nil -- reset
	io.open(dir .. '/Makefile', 'w'):close()
	textadept.run.build()
	assert_equal(ui.command_entry:get_text(), 'make')
	events.emit(events.KEYPRESS, 'esc')
	buffer:close()
	removedir(dir)
end

function test_run_test()
	if WIN32 or OSX then return end -- TODO:
	local test_command = 'lua modules/textadept/run/test.lua'
	textadept.run.test_commands[_HOME] = function()
		return test_command, _HOME .. '/test/' -- intentional trailing '/'
	end
	textadept.run.test(_HOME)
	assert_equal(ui.command_entry.active, true)
	assert_equal(ui.command_entry:get_text(), test_command)
	events.emit(events.KEYPRESS, '\n')
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	if #_VIEWS > 1 then view:unsplit() end
	ui.update() -- process output
	assert(buffer:get_text():find('test%.lua'), 'did not run test command')
	assert(buffer:get_text():find('assertion failed!'), 'assertion failure not detected')
	buffer:close()

	local file = os.tmpname()
	io.open_file(file)
	buffer:save()
	textadept.run.test() -- nothing should happen
	assert_equal(ui.command_entry.active, false)
	buffer:close()
	os.remove(file)
end

function test_run_run_project()
	if WIN32 then return end -- TODO: cannot cd to network path
	io.open_file(_HOME .. '/init.lua')
	textadept.run.run_project(nil, 'foo')
	if not OSX then assert_equal(ui.command_entry.active, true) end -- macOS has focus issues here
	assert_equal(ui.command_entry:get_text(), 'foo')
	events.emit(events.KEYPRESS, 'esc')
	buffer:close()

	local run_command = not WIN32 and 'ls' or 'dir'
	textadept.run.run_project_commands[_HOME] = run_command
	textadept.run.run_project(_HOME)
	assert_equal(ui.command_entry:get_text(), run_command)
	events.emit(events.KEYPRESS, '\n')
	ui.update() -- process output
	assert(buffer:get_text():find('README.md'), 'did not run project command')
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	if #_VIEWS > 1 then view:unsplit() end
	buffer:close()
end

function test_run_goto_internal_lua_error()
	xpcall(error, function(message) events.emit(events.ERROR, debug.traceback(message)) end,
		'internal error', 2)
	if #_VIEWS > 1 then view:unsplit() end
	textadept.run.goto_error(1)
	if not OSX then -- error message is likely too long and starts with '...'
		assert(buffer.filename:find('[/\\]test[/\\]test%.lua$'), 'did not detect internal Lua error')
	end
	view:unsplit()
	buffer:close()
	buffer:close()
end

function test_run_commands_function()
	if WIN32 or OSX then return end -- TODO:
	for _, cmd in ipairs{[[lua -e "print(os.getenv('FOO'))"]], [[lua -e 'print(os.getenv("FOO"))']]} do
		local filename = os.tmpname()
		io.open_file(filename)
		textadept.run.run_commands.text = function() return cmd, '/tmp', {FOO = 'bar'} end
		textadept.run.run()
		events.emit(events.KEYPRESS, '\n')
		assert_equal(#_BUFFERS, 3) -- including [Test Output]
		assert_equal(buffer._type, _L['[Output Buffer]'])
		sleep(0.1)
		ui.update() -- process output
		assert(buffer:get_text():find('> cd /tmp'), 'cwd not set properly')
		if QT then -- process exit
			ui.update()
			sleep(0.1)
			ui.update()
		end
		assert(buffer:get_text():find('bar'), 'env not set properly')
		if #_VIEWS > 1 then view:unsplit() end
		buffer:close()
		buffer:close()
		textadept.run.run_commands.text = nil -- reset
		os.remove(filename)
	end
end

function test_run_run_in_background()
	local run_in_background = textadept.run.run_in_background
	textadept.run.run_in_background = true
	local filename = file(_HOME .. '/test/modules/textadept/run/run.lua')
	io.open_file(filename)
	textadept.run.run()
	events.emit(events.KEYPRESS, '\n')
	ui.update()
	assert_equal(buffer.filename, filename)
	assert_equal(#_VIEWS, 1)
	view:goto_buffer(1) -- [Output]
	assert_equal(buffer:line_from_position(buffer.current_pos), buffer.line_count) -- scrolled to bottom
	buffer:close()
	buffer:close() -- filename
	textadept.run.run_in_background = run_in_background -- restore
end

function test_session_save()
	local handler = function(session)
		session.baz = true
		session.quux = assert
		session.foobar = buffer.doc_pointer
		session.foobaz = coroutine.create(function() end)
	end
	events.connect(events.SESSION_SAVE, handler)
	buffer.new()
	buffer.filename = 'foo.lua'
	textadept.bookmarks.toggle()
	view:split()
	buffer.new()
	buffer.filename = 'bar.lua'
	local session_file = os.tmpname()
	textadept.session.save(session_file)
	local session = assert(loadfile(session_file, 't', {}))()
	assert_equal(session.buffers[#session.buffers - 1].filename, 'foo.lua')
	assert_equal(session.buffers[#session.buffers - 1].bookmarks, {1})
	assert_equal(session.buffers[#session.buffers].filename, 'bar.lua')
	assert_equal(session.ui.maximized, false)
	assert_equal(type(session.views[1]), 'table')
	assert_equal(session.views[1][1], #_BUFFERS - 1)
	assert_equal(session.views[1][2], #_BUFFERS)
	assert(not session.views[1].vertical, 'split vertical')
	assert(session.views[1].size > 1, 'split size not set properly')
	assert_equal(session.views.current, #_VIEWS)
	assert_equal(session.baz, true)
	assert(not session.quux, 'function serialized')
	assert(not session.foobar, 'userdata serialized')
	assert(not session.foobaz, 'thread serialized')
	view:unsplit()
	buffer:close()
	buffer:close()
	os.remove(session_file)
	events.disconnect(events.SESSION_SAVE, handler)
end

function test_session_save_before_load()
	local test_output_text = buffer:get_text()
	local foo = os.tmpname()
	local bar = os.tmpname()
	local baz = os.tmpname()
	buffer.new()
	buffer.filename = foo
	local session1 = os.tmpname()
	textadept.session.save(session1)
	buffer:close()
	buffer.new()
	buffer.filename = bar
	local session2 = os.tmpname()
	textadept.session.save(session2)
	buffer.new()
	buffer.filename = baz
	textadept.session.load(session1) -- should save baz to session
	assert_equal(#_BUFFERS, 1 + 1) -- test output buffer is open
	assert_equal(buffer.filename, foo)
	for i = 1, 2 do
		textadept.session.load(session2) -- when i == 2, reload; should not re-save
		assert_equal(#_BUFFERS, 2 + 1) -- test output buffer is open
		assert_equal(_BUFFERS[#_BUFFERS - 1].filename, bar)
		assert_equal(_BUFFERS[#_BUFFERS].filename, baz)
		buffer:close()
		buffer:close()
	end
	os.remove(foo)
	os.remove(bar)
	os.remove(baz)
	os.remove(session1)
	os.remove(session2)
	buffer:add_text(test_output_text)
end

function test_snippets_find_snippet()
	snippets.foo = 'bar'
	textadept.snippets.paths[1] = _HOME .. '/test/modules/textadept/snippets'

	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	buffer:add_text('foo')
	assert(textadept.snippets.insert() == nil, 'snippet not inserted')
	assert_equal(buffer:get_text(), 'bar') -- from snippets
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'baz\n') -- from bar file
	buffer:delete_back()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'quux\n') -- from baz.txt file
	buffer:delete_back()
	assert(not textadept.snippets.insert(), 'snippet inserted')
	assert_equal(buffer:get_text(), 'quux')
	buffer:clear_all()
	buffer:set_lexer('lua') -- prefer lexer-specific snippets
	snippets.lua = {foo = 'baz'} -- overwrite language module
	buffer:add_text('foo')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'baz') -- from snippets.lua
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'bar\n') -- from lua.baz.lua file
	buffer:delete_back()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'quux\n') -- from lua.bar file
	buffer:close(true)

	snippets.foo = nil
	table.remove(textadept.snippets.paths, 1)
end

function test_snippets_no_expand_lexer_name()
	buffer.new()
	buffer:add_text('lua')
	assert(textadept.snippets.insert() == false, 'snippet not inserted')
	buffer:close(true)
end

function test_snippets_match_indentation()
	local snippet = '\t    foo'
	local multiline_snippet = table.concat({
		'foo', --
		'\tbar', --
		'\t    baz', --
		'quux'
	}, newline())
	buffer.new()

	buffer.use_tabs, buffer.tab_width, buffer.eol_mode = true, 4, buffer.EOL_CRLF
	textadept.snippets.insert(snippet)
	assert_equal(buffer:get_text(), '\t\tfoo')
	buffer:clear_all()
	buffer:add_text('\t')
	textadept.snippets.insert(snippet)
	assert_equal(buffer:get_text(), '\t\t\tfoo')
	buffer:clear_all()
	buffer:add_text('\t')
	textadept.snippets.insert(multiline_snippet)
	assert_equal(buffer:get_text(), table.concat({
		'\tfoo', --
		'\t\tbar', --
		'\t\t\tbaz', --
		'\tquux'
	}, '\r\n'))
	buffer:clear_all()

	buffer.use_tabs, buffer.tab_width, buffer.eol_mode = false, 2, buffer.EOL_LF
	textadept.snippets.insert(snippet)
	assert_equal(buffer:get_text(), '      foo')
	buffer:clear_all()
	buffer:add_text('  ')
	textadept.snippets.insert(snippet)
	assert_equal(buffer:get_text(), '        foo')
	buffer:clear_all()
	buffer:add_text('  ')
	textadept.snippets.insert(multiline_snippet)
	assert_equal(buffer:get_text(), table.concat({
		'  foo', --
		'    bar', --
		'        baz', --
		'  quux'
	}, '\n'))
	buffer:close(true)

	assert_raises(function() textadept.snippets.insert(true) end, 'string/nil expected, got boolean')
end

function test_snippets_placeholders()
	buffer.new()
	buffer.eol_mode = buffer.EOL_LF
	local date_cmd = not WIN32 and 'date' or 'date /T'
	local lua_date = os.date()
	local p = io.popen(date_cmd)
	local shell_date = p:read('l')
	p:close()
	textadept.snippets.insert(table.concat({
		'$0placeholder: ${1:foo} ${2:bar}', --
		'choice: ${3|baz,quux|}', --
		'mirror: $2$3', --
		'transform: ${1/.+/${0:/upcase}/}', --
		'variable: $TM_LINE_NUMBER', --
		string.format('Shell: `echo %s` `%s`', not WIN32 and '$TM_LINE_INDEX' or '%TM_LINE_INDEX%',
			date_cmd), --
		'Lua: ```os.date()```', --
		'escape: \\$1 \\${4} \\`\\`'
	}, '\n'))
	assert_equal(buffer.selections, 1)
	assert_equal(buffer.selection_start, 1 + 14)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	assert_equal(buffer:get_sel_text(), 'foo')
	buffer:replace_sel('baz')
	events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT + buffer.UPDATE_SELECTION) -- simulate typing
	assert_equal(buffer:get_text(), table.concat({
		' placeholder: baz bar', -- placeholders to visit have 1 empty space
		'choice:  ', -- placeholder choices are initially empty
		'mirror:   ', -- placeholder mirrors are initially empty
		'transform: BAZ', -- verify real-time transforms
		'variable: 1', --
		'Shell: 0 ' .. shell_date, --
		'Lua: ' .. lua_date, --
		'escape: $1 ${4} `` ' -- trailing space for snippet sentinel
	}, newline()))
	textadept.snippets.insert()
	assert_equal(buffer.selections, 2)
	assert_equal(buffer.selection_start, 1 + 18)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	for i = 1, buffer.selections do
		assert_equal(buffer.selection_n_end[i], buffer.selection_n_start[i] + 3)
		assert_equal(buffer:text_range(buffer.selection_n_start[i], buffer.selection_n_end[i]), 'bar')
	end
	assert(buffer:get_text():find('mirror: bar'), 'mirror not updated')
	textadept.snippets.insert()
	assert_equal(buffer.selections, 2)
	assert(buffer:auto_c_active(), 'no choice')
	buffer:auto_c_select('quux')
	buffer:auto_c_complete()
	assert(buffer:get_text():find('\nmirror: barquux\n'), 'choice mirror not updated')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), table.concat({
		'placeholder: baz bar', --
		'choice: quux', --
		'mirror: barquux', --
		'transform: BAZ', --
		'variable: 1', --
		'Shell: 0 ' .. shell_date, --
		'Lua: ' .. lua_date, --
		'escape: $1 ${4} ``'
	}, '\n'))
	assert_equal(buffer.selection_start, 1)
	assert_equal(buffer.selection_start, 1)
	buffer:close(true)
end

function test_snippets_irregular_placeholders()
	buffer.new()
	textadept.snippets.insert('${1:foo ${2:bar}}${5:quux}')
	assert_equal(buffer:get_sel_text(), 'foo bar')
	buffer:delete_back()
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'quux')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'quux')
	buffer:close(true)
end

function test_snippets_previous_cancel()
	buffer.new()
	textadept.snippets.insert('${1:foo} ${2:bar} ${3:baz}')
	assert_equal(buffer:get_text(), 'foo bar baz ') -- trailing space for snippet sentinel
	buffer:delete_back()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), ' bar baz ')
	buffer:delete_back()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), '  baz ')
	textadept.snippets.previous()
	textadept.snippets.previous()
	assert_equal(buffer:get_text(), 'foo bar baz ')
	assert_equal(buffer:get_sel_text(), 'foo')
	textadept.snippets.insert()
	textadept.snippets.cancel()
	assert_equal(buffer.length, 0)
	buffer:close(true)
end

function test_snippets_nested()
	snippets.foo = '${1:foo}${2:bar}${3:baz}'
	buffer.new()

	buffer:add_text('foo')
	textadept.snippets.insert()
	buffer:char_right()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'foobarbaz barbaz ') -- trailing spaces for snippet sentinels
	assert_equal(buffer:get_sel_text(), 'foo')
	assert_equal(buffer.selection_start, 1)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	buffer:replace_sel('quux')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'bar')
	assert_equal(buffer.selection_start, 1 + 4)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'baz')
	assert_equal(buffer.selection_start, 1 + 7)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer.current_pos, 1 + 10)
	assert_equal(buffer.selection_start, buffer.selection_end)
	assert_equal(buffer:get_text(), 'quuxbarbazbarbaz ')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'bar')
	assert_equal(buffer.selection_start, 1 + 10)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'baz')
	assert_equal(buffer.selection_start, 1 + 13)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'quuxbarbazbarbaz')
	buffer:clear_all()

	buffer:add_text('foo')
	textadept.snippets.insert()
	buffer:char_right()
	textadept.snippets.insert()
	textadept.snippets.cancel()
	assert_equal(buffer.current_pos, 1 + 3)
	assert_equal(buffer.selection_start, buffer.selection_end)
	assert_equal(buffer:get_text(), 'foobarbaz ')
	buffer:add_text('quux')
	assert_equal(buffer:get_text(), 'fooquuxbarbaz ')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'bar')
	assert_equal(buffer.selection_start, 1 + 7)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'baz')
	assert_equal(buffer.selection_start, 1 + 10)
	assert_equal(buffer.selection_end, buffer.selection_start + 3)
	textadept.snippets.insert()
	assert_equal(buffer.current_pos, buffer.line_end_position[1])
	assert_equal(buffer.selection_start, buffer.selection_end)
	assert_equal(buffer:get_text(), 'fooquuxbarbaz')

	buffer:close(true)
	snippets.foo = nil
end

function test_snippets_select_interactive()
	snippets.foo = 'bar'
	buffer.new()
	textadept.snippets.select()
	assert(buffer.length > 0, 'no snippet inserted')
	buffer:close(true)
	snippets.foo = nil
end

function test_snippets_autocomplete()
	snippets.bar = 'baz'
	snippets.baz = 'quux'
	buffer.new()
	buffer:add_text('ba')
	textadept.editing.autocomplete('snippet')
	assert(buffer:auto_c_active(), 'snippet autocompletion list not shown')
	buffer:auto_c_complete()
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'baz')
	buffer:close(true)
	snippets.bar = nil
	snippets.baz = nil
end

function test_snippets_mirror_in_placeholder()
	snippets.foo = '${1:one} ${2:two{$1\\}.three}'
	buffer.new()
	buffer:add_text('foo')
	textadept.snippets.insert()
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'two{one}.three')
	textadept.snippets.cancel()
	buffer:close(true)
	snippets.foo = nil
end

function test_snippets_nested_placeholders()
	snippets.foo = '${1:bar}${2:{${3:baz}\\}}'
	buffer.new()
	buffer:add_text('foo')
	textadept.snippets.insert()
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), '{baz}')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'baz')
	textadept.snippets.cancel()
	snippets.foo = '${1:bar}(baz${2:, ${3:quux}})'
	textadept.snippets.insert()
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), ', quux')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'quux')
	textadept.snippets.cancel()
	buffer:close(true)
	snippets.foo = nil
end

function test_snippets_transform_options()
	buffer.new()
	textadept.snippets.insert('${1:bar} ${1/./${0:/upcase}/}')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'bar Bar')
	buffer:clear_all()
	textadept.snippets.insert('${1:bar} ${1/./${0:/upcase}/g}')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'bar BAR')
	buffer:close(true)
	snippets.foo = nil
end

function test_snippets_lexer_specific()
	buffer.new()
	snippets.ansi_c = {lgg = 'lua_getglobal(${1:lua}, "${2:name}")'}
	snippets.lua = {}
	buffer:set_lexer('ansi_c')
	buffer:add_text('lgg')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'lua')
	textadept.snippets.insert()
	assert_equal(buffer:get_sel_text(), 'name')
	textadept.snippets.insert()
	assert_equal(buffer:get_text(), 'lua_getglobal(lua, "name")')
	buffer:close(true)
	snippets.ansi_c, snippets.lua = nil, nil
end

function test_lexer_api()
	buffer.new()
	buffer:set_lexer('lua')
	-- TODO:
	buffer:close()
end

function test_ui_size()
	local size = ui.size
	local new_size = {size[1] - 50, size[2] + 50}
	ui.size = new_size
	-- For some reason, reading ui.size fails, even though the window has been resized.
	-- `ui.update()` does not seem to help.
	assert_equal(ui.size, new_size)
	ui.size = size
end
if LINUX and GTK or CURSES then expected_failure(test_ui_size) end

function test_ui_maximized()
	if CURSES then return end -- not applicable
	local maximized = ui.maximized
	ui.maximized = not maximized
	local not_maximized = ui.maximized
	ui.maximized = maximized -- reset
	-- For some reason, the following fails, even though the window maximized status is toggled.
	-- `ui.update()` does not seem to help.
	assert_equal(not_maximized, not maximized)
end
if LINUX and GTK then expected_failure(test_ui_maximized) end

function test_move_buffer()
	local buffer1 = buffer.new()
	buffer1:set_text('1')
	local buffer2 = buffer.new()
	buffer2:set_text('2')
	local buffer3 = buffer.new()
	buffer3:set_text('3')
	local buffer4 = buffer.new()
	buffer4:set_text('4')
	move_buffer(_BUFFERS[buffer4], _BUFFERS[buffer1])
	assert(_BUFFERS[buffer4] < _BUFFERS[buffer1], 'buffer4 not before buffer1')
	assert(_BUFFERS[buffer1] < _BUFFERS[buffer2], 'buffer1 not before buffer2')
	assert(_BUFFERS[buffer2] < _BUFFERS[buffer3], 'buffer2 not before buffer3')
	move_buffer(_BUFFERS[buffer2], _BUFFERS[buffer3])
	assert(_BUFFERS[buffer4] < _BUFFERS[buffer1], 'buffer4 not before buffer1')
	assert(_BUFFERS[buffer1] < _BUFFERS[buffer3], 'buffer1 not before buffer3')
	assert(_BUFFERS[buffer3] < _BUFFERS[buffer2], 'buffer3 not before buffer2')

	assert_raises(function() move_buffer('') end, 'number expected')
	assert_raises(function() move_buffer(1) end, 'number expected')
	assert_raises(function() move_buffer(1, true) end, 'number expected')
	assert_raises(function() move_buffer(1, 10) end, 'out of bounds')
	assert_raises(function() move_buffer(1, -1) end, 'out of bounds')
	assert_raises(function() move_buffer(10, 1) end, 'out of bounds')
	assert_raises(function() move_buffer(-1, 1) end, 'out of bounds')
	buffer1:close(true)
	buffer2:close(true)
	buffer3:close(true)
	buffer4:close(true)
end

function test_reset()
	local _persist
	_G.foo = 'bar'
	reset()
	assert(not _G.foo, 'Lua not reset')
	_G.foo = 'bar'
	events.connect(events.RESET_BEFORE, function(persist)
		persist.foo = _G.foo
		_persist = persist -- store
	end)
	reset()
	-- events.RESET_AFTER has already been run, but there was no opportunity to connect to it in
	-- this test, so connect and simulate the event again.
	events.connect(events.RESET_AFTER, function(persist) _G.foo = persist.foo end)
	events.emit(events.RESET_AFTER, _persist)
	assert_equal(_G.foo, 'bar')
end

function test_timeout()
	if CURSES then
		assert_raises(function() timeout(1, function() end) end, 'could not add timeout')
		return
	end

	local count = 0
	local function f()
		count = count + 1
		return count < 2
	end
	timeout(0.4, f)
	assert_equal(count, 0)
	sleep(0.5)
	ui.update()
	assert_equal(count, 1)
	sleep(0.5)
	ui.update()
	assert_equal(count, 2)
	sleep(0.5)
	ui.update()
	assert_equal(count, 2)
end

function test_view_split_resize_unsplit()
	view:split()
	local size = view.size
	view.size = view.size - 1
	assert_equal(view.size, size - 1)
	assert_equal(#_VIEWS, 2)
	view:split(true)
	size = view.size
	view.size = view.size + 1
	assert_equal(view.size, size + 1)
	assert_equal(#_VIEWS, 3)
	local current_view = view
	view:unsplit()
	assert_equal(#_VIEWS, 2)
	assert(view == current_view, 'view focus changed')
	view:split(true)
	ui.goto_view(_VIEWS[1])
	view:unsplit() -- unsplits split view, leaving single view
	assert_equal(#_VIEWS, 1)
	view:split()
	view:split()
	_VIEWS[1]:unsplit()
	assert_equal(#_VIEWS, 1)
end

function test_view_split_refresh_styles()
	io.open_file(_HOME .. '/init.lua')
	local style = buffer:style_of_name('string_longstring')
	assert(style ~= view.STYLE_DEFAULT, 'cannot retrieve number of longstring style')
	local color = view.style_fore[style]
	assert(color ~= view.style_fore[view.STYLE_DEFAULT], 'longstring style not set')
	view:split()
	for _, view in ipairs(_VIEWS) do
		local view_style = buffer:style_of_name('string_longstring')
		assert_equal(view_style, style)
		local view_color = view.style_fore[view_style]
		assert_equal(view_color, color)
	end
	view:unsplit()
	buffer:close(true)
end

function test_buffer_read_write_only_properties()
	assert_raises(function() view.all_lines_visible = false end, 'read-only property')
	assert_raises(function() return buffer.auto_c_fill_ups end, 'write-only property')
	assert_raises(function() buffer.annotation_text = {} end, 'read-only property')
	assert_raises(function() buffer.char_at[1] = string.byte(' ') end, 'read-only property')
	assert_raises(function() return view.marker_alpha[1] end, 'write-only property')
	assert_raises(function() return buffer.tab_label end, 'write-only property')
	assert_raises(function() view.buffer = nil end, 'read-only property')
end

function test_set_theme()
	view:split()
	io.open_file(_HOME .. '/init.lua')
	view:split(true)
	io.open_file(_HOME .. '/src/textadept.c')
	_VIEWS[2]:set_theme('dark')
	_VIEWS[3]:set_theme('light')
	assert(_VIEWS[2].style_fore[view.STYLE_DEFAULT] ~= _VIEWS[3].style_fore[view.STYLE_DEFAULT],
		'same default styles')
	buffer:close(true)
	buffer:close(true)
	ui.goto_view(_VIEWS[1])
	view:unsplit()
end

function test_set_view_style()
	buffer.new()
	buffer:set_lexer('lua')
	buffer:add_text('dofile()')
	buffer:colorize(1, -1)
	local style = buffer:style_of_name('function_builtin')
	assert_equal(buffer.style_at[1], style)
	local function_builtin_fore = view.style_fore[style]
	local default_fore = view.style_fore[view.STYLE_DEFAULT]
	assert(function_builtin_fore ~= default_fore,
		'builtin function name style_fore same as default style_fore')
	view.style_fore[style] = view.style_fore[view.STYLE_DEFAULT]
	assert_equal(view.style_fore[style], default_fore)
	local color = view.colors[not CURSES and 'orange' or 'blue']
	assert(color > 0 and color ~= default_fore)
	view.styles.function_builtin = {fore = color}
	view:set_styles()
	assert_equal(view.style_fore[style], color)
	view.styles.function_builtin = {fore = function_builtin_fore} -- restore
	buffer:close(true)
	-- Defined in HTML lexer, which is not currently loaded.
	assert(buffer:style_of_name('tag_unknown'), view.STYLE_DEFAULT)

	-- buffer:name_of_style() returns the dotted form of the name, so ensure that it can also be
	-- used in view.styles, but that it's converted to the underscore form.
	view.styles['custom.name'] = {bold = true}
	assert(view.styles.custom_name and view.styles.custom_name.bold, 'dot style not converted')

	assert_raises(function() view.styles.foo = 1 end, 'table expected')
	assert_raises(function() view.styles.foo = view.styles[view.STYLE_DEFAULT] .. 1 end,
		'table expected')
	-- TODO: error when setting existing style like view.styles.default = 1?
end

function test_view_fold_properties()
	view.property['fold.scintillua.compact'] = '0'
	assert(not view.fold_compact, 'view.fold_compact not updated')
	view.fold_compact = true
	assert(view.fold_compact, 'view.fold_compact not updated')
	assert_equal(view.property['fold.scintillua.compact'], '1')
	view.fold_compact = nil
	assert(not view.fold_compact)
	assert_equal(view.property['fold.scintillua.compact'], '0')
	local truthy, falsy = {true, '1', 1}, {false, '0', 0}
	for i = 1, #truthy do
		view.fold_compact = truthy[i]
		assert(view.fold_compact, 'view.fold_compact not updated for "%s"', tostring(truthy[i]))
		view.fold_compact = falsy[i]
		assert(not view.fold_compact, 'view.fold_compact not updated for "%s"', tostring(falsy[i]))
	end
	-- Verify fold and folding properties are synchronized.
	view.fold_compact = true
	assert_equal(view.property['fold.scintillua.compact'], '1')
	view.fold_compact = nil
	assert_equal(view.property['fold.scintillua.compact'], '0')
	view.property['fold'] = '0'
	assert(not view.folding)
	view.folding = true
	assert_equal(view.property['fold'], '1')
end
expected_failure(test_view_fold_properties)

function test_buffer_view_settings_segregation()
	buffer.new()
	local use_tabs, tab_width = not buffer.use_tabs, buffer.tab_width + 2
	buffer.use_tabs, buffer.tab_width = use_tabs, tab_width
	local view_eol = view.view_eol
	view.view_eol = not view_eol
	local multiple_selection = buffer.multiple_selection
	view:split()
	assert_equal(buffer.use_tabs, use_tabs)
	assert_equal(buffer.tab_width, tab_width)
	assert_equal(view.view_eol, view_eol)
	assert_equal(buffer.multiple_selection, multiple_selection) -- this "buffer" property be set too
	view:unsplit()
	buffer.new()
	assert(buffer.use_tabs ~= use_tabs, 'custom buffer settings carried over to new buffer')
	assert(buffer.tab_width ~= tab_width, 'custom buffer settings carried over to new buffer')
	buffer:close()
	buffer:close()
end

function test_debugger_ansi_c()
	if WIN32 or OSX then return end -- TODO:
	local debugger = require('debugger')
	local use_status_buffers = debugger.use_status_buffers
	local project_commands = debugger.project_commands
	debugger.use_status_buffers = false
	debugger.project_commands = {} -- reset
	require('debugger.gdb').logging = true
	-- Runs the given debugger function with arguments and waits for or processes the response.
	-- Most debugger functions have a callback that needs to be executed asynchronously or else
	-- strange errors will occur.
	local function run_and_wait(f, ...)
		f(...)
		if ui.command_entry.active then events.emit(events.KEYPRESS, '\n') end
		os.spawn('sleep 0.2'):wait()
		ui.update()
	end
	local tabs = ui.tabs
	ui.tabs = false
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	local filename = dir .. '/foo.c'
	os.execute(string.format('cp %s/test/modules/debugger/ansi_c/foo.c %s', _HOME, filename))
	io.open_file(filename)
	debugger.toggle_breakpoint(nil, 8)
	assert(buffer:marker_get(8) > 0, 'breakpoint marker not set')
	textadept.run.compile_commands[filename] = textadept.run.compile_commands.ansi_c .. ' -g'
	run_and_wait(textadept.run.compile)
	assert_equal(#_VIEWS, 2)
	local msg_buf = buffer
	assert(buffer:get_text():find('status: 0'), 'compile failed')
	ui.goto_view(-1)
	run_and_wait(debugger.start, nil, dir .. '/foo')
	run_and_wait(debugger.continue)
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), 8)
	assert(buffer:marker_number_from_line(8, 2) > 0, 'current line marker not set')
	assert(not msg_buf:get_text():find('^start\n'), 'not at breakpoint')
	run_and_wait(debugger.restart)
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), 8)
	assert(buffer:marker_number_from_line(8, 2) > 0, 'current line marker not set')
	assert(not msg_buf:get_text():find('^start\n'), 'not at breakpoint')
	run_and_wait(debugger.stop)
	assert_equal(buffer:marker_number_from_line(8, 2), -1, 'still debugging')
	run_and_wait(debugger.start, nil, dir .. '/foo')
	run_and_wait(debugger.continue)
	debugger.toggle_breakpoint() -- clear
	run_and_wait(debugger.step_over)
	assert_equal(buffer:line_from_position(buffer.current_pos), 9)
	assert(buffer:marker_get(9) > 0, 'current line marker not set')
	assert_equal(buffer:marker_get(8), 0) -- current line marker cleared
	-- TODO: gdb does not print program stdout to its stdout until the end when using the mi interface.
	-- assert(msg_buf:get_text():find('^start\n'), 'process stdout not captured')
	run_and_wait(debugger.step_over)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	run_and_wait(debugger.evaluate, 'i')
	assert_equal(buffer.filename, filename) -- still in file being debugged
	assert(msg_buf:get_text():find('\n0\n'), 'evaluation of i failed')
	run_and_wait(debugger.step_into)
	assert_equal(buffer:line_from_position(buffer.current_pos), 4)
	run_and_wait(debugger.set_frame, 2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	textadept.history.back()
	assert_equal(buffer:line_from_position(buffer.current_pos), 4)
	textadept.history.forward()
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	run_and_wait(debugger.set_frame, 1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 4)
	buffer:search_anchor()
	local pos = buffer:search_next(buffer.FIND_MATCHCASE | buffer.FIND_WHOLEWORD, 'i')
	assert(pos > 0, "'i' not found")
	run_and_wait(debugger.inspect, pos)
	assert(view:call_tip_active(), 'no call tip active')
	run_and_wait(debugger.step_out)
	-- assert(msg_buf:get_text():find('\nfoo 0\n'), 'process stdout not captured')
	assert_equal(buffer:line_from_position(buffer.current_pos), 9)
	debugger.set_watch('i')
	run_and_wait(debugger.continue)
	assert_equal(buffer:line_from_position(buffer.current_pos), 9)
	assert(not msg_buf:get_text():find('\nfoo 1\n'), 'watch point failed')
	debugger.remove_watch(1)
	debugger.set_watch('&i', true) -- no break
	run_and_wait(debugger.step_over)
	events.emit(events.MARGIN_CLICK, 2, buffer.current_pos, 0) -- simulate breakpoint margin click
	run_and_wait(debugger.continue)
	assert_equal(buffer:line_from_position(buffer.current_pos), 10)
	-- assert(msg_buf:get_text():find('\nfoo 1\n'), 'set breakpoint failed')
	assert(not msg_buf:get_text():find('\nfoo 2\n'), 'set breakpoint failed')
	events.emit(events.MARGIN_CLICK, 2, buffer.current_pos, 0) -- simulate breakpoint margin click; clear
	run_and_wait(debugger.continue)
	-- assert(msg_buf:get_text():find('\nfoo 2\n'), 'process stdout not captured')
	-- assert(msg_buf:get_text():find('\nfoo 3\n'), 'process stdout not captured')
	-- assert(msg_buf:get_text():find('\nend\n'), 'process stdout not captured')
	for i = 1, buffer.line_count do assert_equal(buffer:marker_get(i), 0) end
	ui.goto_view(1)
	buffer:close(true)
	view:unsplit()
	buffer:close(true)
	removedir(dir)
	ui.tabs = tabs
	debugger.use_status_buffers = use_status_buffers -- restore
	debugger.project_commands = project_commands -- restore
end

function test_debugger_lua()
	if WIN32 or OSX then return end -- TODO:
	local debugger = require('debugger')
	local use_status_buffers = debugger.use_status_buffers
	local project_commands = debugger.project_commands
	debugger.use_status_buffers = false
	debugger.project_commands = {} -- reset
	-- Runs the given debugger function with arguments and waits for or processes the response.
	-- Most debugger functions have a callback that needs to be executed asynchronously or else
	-- strange errors or 'Unknown Error' will occur.
	local function run_and_wait(f, ...)
		f(...)
		for i = 1, 10 do
			os.spawn('sleep 0.1'):wait()
			ui.update()
		end
	end
	local tabs = ui.tabs
	ui.tabs = false
	local filename = _HOME .. '/test/modules/debugger/lua/foo.lua'
	io.open_file(filename)
	debugger.toggle_breakpoint(nil, 5)
	assert(buffer:marker_get(5) > 0, 'breakpoint marker not set')
	run_and_wait(debugger.continue) -- start
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	assert(buffer:marker_number_from_line(5, 2) > 0, 'current line marker not set')
	assert_equal(#_VIEWS, 1)
	run_and_wait(debugger.restart)
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), 3) -- for whatever reason
	assert(buffer:marker_get(3) > 0, 'current line marker not set')
	assert_equal(#_VIEWS, 1)
	run_and_wait(debugger.stop)
	assert_equal(buffer:marker_number_from_line(5, 2), -1, 'still debugging')
	run_and_wait(debugger.continue) -- start
	debugger.toggle_breakpoint() -- clear
	run_and_wait(debugger.step_over)
	assert_equal(#_VIEWS, 2)
	assert_equal(buffer.filename, filename)
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	assert(buffer:marker_get(6) > 0, 'current line marker not set')
	assert_equal(buffer:marker_get(5), 0) -- current line marker cleared
	local msg_buf = _VIEWS[#_VIEWS].buffer
	assert(msg_buf:get_text():find('^"start"\n'), 'process stdout not captured')
	run_and_wait(debugger.step_over)
	assert_equal(buffer:line_from_position(buffer.current_pos), 7)
	run_and_wait(debugger.evaluate, "print('i', i)")
	assert_equal(buffer.filename, filename) -- still in file being debugged
	assert(msg_buf:get_text():find('\n"i"%s1\n'), 'evaluation of i failed')
	run_and_wait(debugger.step_into)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	run_and_wait(debugger.set_frame, 2)
	assert_equal(buffer:line_from_position(buffer.current_pos), 7)
	run_and_wait(debugger.set_frame, 1)
	assert_equal(buffer:line_from_position(buffer.current_pos), 2)
	buffer:search_anchor()
	local pos = buffer:search_next(buffer.FIND_MATCHCASE | buffer.FIND_WHOLEWORD, 'i')
	assert(pos > 0, "'i' not found")
	run_and_wait(debugger.inspect, pos)
	assert(view:call_tip_active(), 'no call tip active')
	run_and_wait(debugger.step_out)
	assert(msg_buf:get_text():find('\n"foo"%s1\n'), 'process stdout not captured')
	assert_equal(buffer:line_from_position(buffer.current_pos), 6)
	run_and_wait(debugger.set_watch, 'i')
	run_and_wait(debugger.continue)
	assert_equal(buffer:line_from_position(buffer.current_pos), 7)
	assert(not msg_buf:get_text():find('\n"foo"%s2\n'), 'watch point failed')
	run_and_wait(debugger.remove_watch, 1)
	run_and_wait(debugger.set_watch, 'foo', true) -- no break
	events.emit(events.MARGIN_CLICK, 2, buffer.current_pos, 0) -- simulate breakpoint margin click
	run_and_wait(debugger.continue)
	assert_equal(buffer:line_from_position(buffer.current_pos), 7) -- TODO: test_debugger_interactive causes failure here
	assert(msg_buf:get_text():find('\n"foo"%s2\n'), 'set breakpoint failed')
	assert(not msg_buf:get_text():find('\n"foo"%s3\n'), 'set breakpoint failed')
	events.emit(events.MARGIN_CLICK, 2, buffer.current_pos, 0) -- simulate breakpoint margin click; clear
	run_and_wait(debugger.continue)
	assert(msg_buf:get_text():find('\n"foo"%s3\n'), 'process stdout not captured')
	assert(msg_buf:get_text():find('\n"foo"%s4\n'), 'process stdout not captured')
	assert(msg_buf:get_text():find('\n"end"\n'), 'process stdout not captured')
	for i = 1, buffer.line_count do assert_equal(buffer:marker_get(i), 0) end
	ui.goto_view(1)
	buffer:close(true)
	view:unsplit()
	buffer:close(true)
	ui.tabs = tabs
	debugger.use_status_buffers = use_status_buffers -- restore
	debugger.project_commands = project_commands -- restore
end

function test_debugger_interactive()
	if WIN32 or OSX then return end -- TODO:
	local debugger = require('debugger')

	local filename = _HOME .. '/test/modules/debugger/lua/foo.lua'
	io.open_file(filename)
	debugger.toggle_breakpoint(nil, 5)
	debugger.toggle_breakpoint(nil, 9)
	debugger.remove_breakpoint()
	assert_equal(buffer:marker_get(5), 0)

	debugger.set_watch()
	debugger.set_watch('i')
	debugger.remove_watch()

	buffer:close(true)
end

-- TODO: debug status buffers

function test_export_interactive()
	if CURSES then return end -- cannot add timeout
	local export = require('export')
	buffer.new()
	buffer:add_text("_G.foo=table.concat{1,'bar',true,print}\nbar=[[<>& ]]")
	buffer:set_lexer('lua')
	local filename = os.tmpname()
	export.to_html(nil, filename)
	_G.timeout(0.5, function() os.remove(filename) end)
	buffer:close(true)
end

function test_file_diff()
	local diff = require('file_diff')

	local filename1 = file(_HOME .. '/test/modules/file_diff/1')
	local filename2 = file(_HOME .. '/test/modules/file_diff/2')
	io.open_file(filename1)
	io.open_file(filename2)
	view:split()
	ui.goto_view(-1)
	view:goto_buffer(-1)
	diff.start('-', '-')
	assert_equal(#_VIEWS, 2)
	assert_equal(view, _VIEWS[1])
	local buffer1, buffer2 = _VIEWS[1].buffer, _VIEWS[2].buffer
	assert_equal(buffer1.filename, filename1)
	assert_equal(buffer2.filename, filename2)

	local function verify(buffer, markers, indicators, annotations)
		for i = 1, buffer.line_count do
			if not markers[i] then
				assert(buffer:marker_get(i) == 0, 'unexpected marker on line %d', i)
			else
				assert(buffer:marker_get(i) & 1 << markers[i] - 1 > 0, 'incorrect marker on line %d', i)
			end
			if not annotations[i] then
				assert(buffer.annotation_text[i] == '', 'unexpected annotation on line %d', i)
			else
				assert(buffer.annotation_text[i] == annotations[i], 'incorrect annotation on line %d', i)
			end
		end
		for _, indic in ipairs{diff.INDIC_DELETION, diff.INDIC_ADDITION} do
			local s = buffer:indicator_end(indic, 1)
			local e = buffer:indicator_end(indic, s)
			while s < buffer.length and e > s do
				local text = buffer:text_range(s, e)
				assert(indicators[text] == indic, 'incorrect indicator for "%s"', text)
				s = buffer:indicator_end(indic, e)
				e = buffer:indicator_end(indic, s)
			end
		end
	end

	-- Verify line markers.
	verify(buffer1, {
		[1] = diff.MARK_MODIFICATION, --
		[2] = diff.MARK_MODIFICATION, --
		[3] = diff.MARK_MODIFICATION, --
		[4] = diff.MARK_MODIFICATION, --
		[5] = diff.MARK_MODIFICATION, --
		[6] = diff.MARK_MODIFICATION, --
		[7] = diff.MARK_MODIFICATION, --
		[12] = diff.MARK_MODIFICATION, --
		[14] = diff.MARK_MODIFICATION, --
		[15] = diff.MARK_MODIFICATION, --
		[16] = diff.MARK_DELETION
	}, {
		['is'] = diff.INDIC_DELETION, --
		['line\n'] = diff.INDIC_DELETION, --
		['    '] = diff.INDIC_DELETION, --
		['+'] = diff.INDIC_DELETION, --
		['pl'] = diff.INDIC_DELETION, --
		['one'] = diff.INDIC_DELETION, --
		['wo'] = diff.INDIC_DELETION, --
		['three'] = diff.INDIC_DELETION, --
		['will'] = diff.INDIC_DELETION
	}, {[11] = ' \n'})
	verify(buffer2, {
		[1] = diff.MARK_MODIFICATION, --
		[2] = diff.MARK_MODIFICATION, --
		[3] = diff.MARK_MODIFICATION, --
		[4] = diff.MARK_MODIFICATION, --
		[5] = diff.MARK_MODIFICATION, --
		[6] = diff.MARK_MODIFICATION, --
		[7] = diff.MARK_MODIFICATION, --
		[12] = diff.MARK_ADDITION, --
		[13] = diff.MARK_ADDITION, --
		[14] = diff.MARK_MODIFICATION, --
		[16] = diff.MARK_MODIFICATION, --
		[17] = diff.MARK_MODIFICATION
	}, {
		['at'] = diff.INDIC_ADDITION, --
		['paragraph\n    '] = diff.INDIC_ADDITION, --
		['-'] = diff.INDIC_ADDITION, --
		['min'] = diff.INDIC_ADDITION, --
		['two'] = diff.INDIC_ADDITION, --
		['\t'] = diff.INDIC_ADDITION, --
		['hree'] = diff.INDIC_ADDITION, --
		['there are '] = diff.INDIC_ADDITION, --
		['four'] = diff.INDIC_ADDITION, --
		['have'] = diff.INDIC_ADDITION, --
		['d'] = diff.INDIC_ADDITION
	}, {[17] = ' '})

	-- Stop comparing, verify the buffers are restored to normal, and then start comparing again.
	textadept.menu.menubar['Tools/Compare Files/Stop Comparing'][2]()
	verify(buffer1, {}, {}, {})
	verify(buffer2, {}, {}, {})
	textadept.menu.menubar['Tools/Compare Files/Compare Buffers'][2]()

	-- Test goto next/prev change.
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
	diff.goto_change()
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
	diff.goto_change()
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 15)
	diff.goto_change()
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
	diff.goto_change()
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 7)
	ui.goto_view(1)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 1)
	diff.goto_change(true)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 12)
	diff.goto_change(true)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 14)
	diff.goto_change(true)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 16)
	diff.goto_change(true)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 17)
	diff.goto_change(true)
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 1)
	diff.goto_change()
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 17)
	diff.goto_change()
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 14)
	diff.goto_change()
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 13)
	diff.goto_change()
	assert_equal(buffer2:line_from_position(buffer2.current_pos), 7)
	ui.goto_view(-1)
	buffer1:goto_line(1)

	-- Merge first block right to left and verify.
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
	diff.merge(true)
	assert(buffer1:get_line(1):find('^that'), 'did not merge from right to left')
	local function verify_first_merge()
		for i = 1, 7 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
		verify(buffer1, {
			[12] = diff.MARK_MODIFICATION, --
			[14] = diff.MARK_MODIFICATION, --
			[15] = diff.MARK_MODIFICATION, --
			[16] = diff.MARK_DELETION
		}, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {[11] = ' \n'})
		verify(buffer2, {
			[12] = diff.MARK_ADDITION, --
			[13] = diff.MARK_ADDITION, --
			[14] = diff.MARK_MODIFICATION, --
			[16] = diff.MARK_MODIFICATION, --
			[17] = diff.MARK_MODIFICATION
		}, {
			['four'] = diff.INDIC_ADDITION, --
			['have'] = diff.INDIC_ADDITION, --
			['d'] = diff.INDIC_ADDITION
		}, {[17] = ' '})
	end
	verify_first_merge()
	-- Undo, merge left to right, and verify.
	buffer1:undo()
	buffer1:goto_line(1)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
	diff.merge()
	assert(buffer2:get_line(1):find('^this'), 'did not merge from left to right')
	verify_first_merge()

	local verify_third_merge, verify_fourth_merge, verify_fifth_merge -- forward-declare for label
	if CURSES then goto curses_skip end -- TODO: curses chokes trying to automate this

	-- Go to next difference, merge second block right to left, and verify.
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
	ui.update()
	diff.merge(true)
	assert(buffer1:get_line(12):find('^%('), 'did not merge from right to left')
	for i = 12, 13 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
	verify(buffer1, {
		[14] = diff.MARK_MODIFICATION, --
		[16] = diff.MARK_MODIFICATION, --
		[17] = diff.MARK_MODIFICATION, --
		[18] = diff.MARK_DELETION
	}, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {})
	verify(buffer2, {
		[14] = diff.MARK_MODIFICATION, --
		[16] = diff.MARK_MODIFICATION, --
		[17] = diff.MARK_MODIFICATION
	}, {
		['four'] = diff.INDIC_ADDITION, --
		['have'] = diff.INDIC_ADDITION, --
		['d'] = diff.INDIC_ADDITION
	}, {[17] = ' '})
	-- Undo, merge left to right, and verify.
	buffer1:undo()
	buffer1:goto_line(11)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
	diff.merge()
	assert(buffer2:get_line(12):find('^be changed'), 'did not merge from left to right')
	verify(buffer1, {
		[12] = diff.MARK_MODIFICATION, --
		[14] = diff.MARK_MODIFICATION, --
		[15] = diff.MARK_MODIFICATION, --
		[16] = diff.MARK_DELETION
	}, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {})
	verify(buffer2, {
		[12] = diff.MARK_MODIFICATION, --
		[14] = diff.MARK_MODIFICATION, --
		[15] = diff.MARK_MODIFICATION
	}, {
		['four'] = diff.INDIC_ADDITION, --
		['have'] = diff.INDIC_ADDITION, --
		['d'] = diff.INDIC_ADDITION
	}, {[15] = ' '})

	-- Already on next difference; merge third block from right to left, and verify.
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
	diff.merge(true)
	assert(buffer1:get_line(12):find('into four'), 'did not merge from right to left')
	assert_equal(buffer1:get_line(12), buffer2:get_line(12))
	verify_third_merge = function()
		verify(buffer1, {
			[14] = diff.MARK_MODIFICATION, --
			[15] = diff.MARK_MODIFICATION, --
			[16] = diff.MARK_DELETION
		}, {['will'] = diff.INDIC_DELETION}, {})
		verify(buffer2, {
			[14] = diff.MARK_MODIFICATION, --
			[15] = diff.MARK_MODIFICATION
		}, {['have'] = diff.INDIC_ADDITION, ['d'] = diff.INDIC_ADDITION}, {[15] = ' '})
	end
	verify_third_merge()
	-- Undo, merge left to right, and verify.
	buffer1:undo()
	buffer1:goto_line(12)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
	diff.merge()
	assert(buffer2:get_line(12):find('into three'), 'did not merge from left to right')
	verify_third_merge()

	-- Go to next difference, merge fourth block from right to left, and verify.
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
	diff.merge(true)
	assert(buffer1:get_line(14):find('have'), 'did not merge from right to left')
	verify_fourth_merge = function()
		for i = 14, 15 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
		verify(buffer1, {[16] = diff.MARK_DELETION}, {}, {})
		verify(buffer2, {}, {}, {[15] = ' '})
	end
	verify_fourth_merge()
	-- Undo, merge left to right, and verify.
	buffer1:undo()
	buffer1:goto_line(14)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
	diff.merge()
	assert(buffer2:get_line(14):find('will'), 'did not merge from left to right')
	verify_fourth_merge()

	-- Go to next difference, merge fifth block from right to left, and verify.
	diff.goto_change(true)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
	diff.merge(true)
	assert(buffer1:get_line(16):find('^\n'), 'did not merge from right to left')
	verify_fifth_merge = function()
		assert_equal(buffer1.length, buffer2.length)
		for i = 1, buffer1.length do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
		verify(buffer1, {}, {}, {})
		verify(buffer2, {}, {}, {})
	end
	verify_fifth_merge()
	-- Undo, merge left to right, and verify.
	buffer1:undo()
	buffer1:goto_line(16)
	assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
	diff.merge()
	assert(buffer2:get_line(16):find('^%('), 'did not merge from left to right')
	verify_fifth_merge()

	-- Test scroll synchronization.
	_VIEWS[1].x_offset = 50
	ui.update()
	assert_equal(_VIEWS[2].x_offset, _VIEWS[1].x_offset)
	_VIEWS[1].x_offset = 0
	-- TODO: test vertical synchronization

	::curses_skip::
	textadept.menu.menubar['Tools/Compare Files/Stop Comparing'][2]()
	ui.goto_view(_VIEWS[#_VIEWS])
	buffer:close(true)
	ui.goto_view(-1)
	view:unsplit()
	buffer:close(true)
	-- Make sure nothing bad happens.
	diff.goto_change()
	diff.merge()
end

function test_file_diff_interactive()
	local diff = require('file_diff')
	diff.start(_HOME .. '/test/modules/file_diff/1')
	assert_equal(#_VIEWS, 2)
	textadept.menu.menubar['Tools/Compare Files/Stop Comparing'][2]()
	local different_files = _VIEWS[1].buffer.filename ~= _VIEWS[2].buffer.filename
	ui.goto_view(1)
	buffer:close(true)
	view:unsplit()
	if different_files then buffer:close(true) end
end

function test_format_code_clang_format()
	if WIN32 or OSX then return end -- TODO:
	io.open_file(_HOME .. '/test/modules/format/foo.c')
	require('format').code()
	assert_equal(buffer:get_text(), 'int main() { return 0; }' .. newline())
	buffer:close(true)
end

function test_format_paragraph()
	if WIN32 or OSX then return end -- depends on UNIX `fmt` tool.
	local format = require('format')
	local line_length = format.line_length
	format.line_length = 20

	buffer.new()
	local code = table.concat({
		'local foo', --
		'-- This is a really long line comment that should be wrapped.',
		'-- This is another really long line comment that should be wrapped.', --
		'local bar'
	}, newline())
	buffer:set_text(code)
	buffer:set_lexer('lua')
	format.paragraph() -- should do nothing on first line
	assert_equal(buffer:get_text(), code)
	buffer:goto_line(3)
	format.paragraph()
	assert_equal(buffer:get_text(), table.concat({
		'local foo', --
		'-- This is a', --
		'-- really long', --
		'-- line comment', --
		'-- that should', --
		'-- be wrapped.', --
		'-- This is another', --
		'-- really long', --
		'-- line comment', --
		'-- that should', --
		'-- be wrapped.', --
		'local bar'
	}, newline()))
	buffer:undo()
	buffer:goto_line(2)
	buffer:line_down_extend()
	format.paragraph()
	assert_equal(buffer:get_text(), table.concat({
		'local foo', --
		'-- This is a', --
		'-- really long', --
		'-- line comment', --
		'-- that should', --
		'-- be wrapped.', --
		'-- This is another really long line comment that should be wrapped.', --
		'local bar'
	}, newline()))

	format.line_length = line_length -- restore
	buffer:close(true)
end

function test_lsp_clangd()
	if WIN32 or OSX then return end -- TODO:
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	lfs.mkdir(dir .. '/.hg') -- simulate version control
	os.execute(string.format('%s %s %s', not WIN32 and 'cp' or 'copy',
		file(_HOME .. '/test/modules/lsp/clangd/*'), dir))
	local lsp = require('lsp')
	lsp.server_commands.cpp = 'clangd'
	lsp.log_rpc = true

	io.open_file(dir .. '/main.cpp')
	-- Ensure the language server starts. It normally autostarts, but this will not happen when
	-- the lsp module is loaded after init and was not able to hook into events.LEXER_LOADED,
	-- events.FILE_OPENED, etc.
	lsp.start()
	sleep(0.5) -- allow time to initialize
	textadept.menu.menubar['Tools/Language Server/Show Log'][2]()
	local lsp_buf = _BUFFERS[#_BUFFERS]
	assert_equal(lsp_buf._type, '[LSP]')
	assert(lsp_buf:get_line(1):find('^Starting language server: clangd'), 'clangd did not start')
	view:goto_buffer(-1)

	-- Test completions.
	buffer:goto_pos(buffer:find_column(1, 13)) -- #include "F
	sleep(0.5)
	lsp.autocomplete()
	assert(buffer:auto_c_active(), 'no autocompletions')
	sleep(0.5)
	lsp.autocomplete()
	assert_equal(buffer.auto_c_current_text, 'Foo.h"') -- does not work the first time for some reason
	buffer:auto_c_cancel()
	buffer:goto_pos(buffer:find_column(6, 28)) -- foo.bar().
	lsp.autocomplete()
	assert(buffer:auto_c_active(), 'no autocompletions')
	assert_equal(buffer.auto_c_current_text, 'append')
	buffer:auto_c_cancel()
	events.emit(events.CHAR_ADDED, string.byte('.'))
	assert(buffer:auto_c_active(), 'no autocompletions after trigger character')
	buffer:auto_c_cancel()

	-- Test hover/dwell.
	events.emit(events.DWELL_START, buffer.line_indent_position[6]) -- printf
	assert(view:call_tip_active(), 'call tip not active')
	events.emit(events.DWELL_END)
	assert(not view:call_tip_active(), 'call tip still active')

	-- Test signature help.
	buffer:goto_pos(buffer:find_column(5, 11)) -- Foo foo(
	lsp.signature_help()
	assert(view:call_tip_active(), 'call tip not active')
	textadept.menu.menubar['Tools/Language Server/Show Documentation'][2]() -- cycle through signatures
	assert(view:call_tip_active(), 'call tip still not active')
	view:call_tip_cancel()
	events.emit(events.CHAR_ADDED, string.byte('('))
	assert(view:call_tip_active(), 'call tip not active after trigger character')
	view:call_tip_cancel()

	-- Test goto definition.
	buffer:goto_pos(buffer.line_indent_position[5]) -- Foo
	lsp.goto_definition()
	assert_equal(buffer.filename, file(dir .. '/Foo.h'))
	assert_equal(buffer:line_from_position(buffer.current_pos), 3)
	assert_equal(buffer:get_sel_text(), 'Foo')
	buffer:close()

	-- Test goto declaration.
	buffer:goto_pos(buffer:find_column(6, 18)) -- foo
	lsp.goto_declaration()
	assert_equal(buffer.filename, file(dir .. '/main.cpp'))
	assert_equal(buffer:line_from_position(buffer.current_pos), 5)
	assert_equal(buffer:get_sel_text(), 'foo')

	-- Test select.
	buffer:goto_pos(buffer:find_column(6, 12)) -- %s
	lsp.select()
	assert_equal(buffer:get_sel_text(), '"%s\\n"')
	lsp.select()
	assert_equal(buffer.selection_start, buffer.line_indent_position[6])
	assert_equal(buffer.selection_end, buffer.line_end_position[6] - 1) -- ends before ';'

	-- Test find references.
	buffer:goto_pos(buffer:find_column(6, 25)) -- foo.bar
	lsp.find_references()
	local ff_buf = _BUFFERS[#_BUFFERS] -- Files Found buffer opened
	assert_equal(ff_buf._type, '[Files Found Buffer]')
	assert(ff_buf:get_text():find('main.cpp:6'), 'main.cpp reference not found')
	-- assert(ff_buf:get_text():find('Foo.h:6'), 'Foo.h reference not found')
	if #_VIEWS > 1 then
		ui.goto_view(-1)
		view:unsplit()
	else
		view:goto_buffer(-2) -- skip over [LSP] too
	end

	-- Simulate save.
	events.emit(events.FILE_AFTER_SAVE, buffer.filename)
	sleep(1)
	ui.update()

	lsp.stop()
	sleep(0.5)
	ui.update()
	if QT then -- process exit
		ui.update()
		sleep(0.5)
		ui.update()
	end
	assert(lsp_buf:get_text():find('Server exited with status 0'), 'clangd did not stop')
	buffer:close(true)
	lsp_buf:close()
	ff_buf:close()

	lsp.server_commands.cpp = nil -- reset
	removedir(dir)
end

function test_lsp_clangd_interactive()
	if WIN32 or OSX then return end -- TODO:
	local dir = os.tmpname()
	os.remove(dir)
	lfs.mkdir(dir)
	lfs.mkdir(dir .. '/.hg') -- simulate version control
	os.execute(string.format('%s %s %s', not WIN32 and 'cp' or 'copy',
		file(_HOME .. '/test/modules/lsp/clangd/*'), dir))
	local lsp = require('lsp')
	local lsp_menu = textadept.menu.menubar['Tools/Language Server']

	io.open_file(dir .. '/main.cpp')
	lsp.server_commands.cpp = 'clangd'
	lsp_menu[_L['Start Server...']][2]()
	sleep(0.5)
	ui.update()
	if #_BUFFERS < 3 then
		-- LSP has not autostarted. This happens when the lsp module is loaded after init and was not
		-- able to hook into events.LEXER_LOADED, events.FILE_OPENED, etc.
		lsp.start()
		sleep(0.5)
		ui.update()
	end
	if QT then -- process start
		ui.update()
		sleep(0.5)
		ui.update()
	end
	local lsp_buf = _BUFFERS[#_BUFFERS] -- LSP view opened
	if #_VIEWS > 1 then view:unsplit() end

	-- Test goto symbol.
	lsp.goto_symbol('Foo')
	assert_equal(buffer.filename, file(dir .. '/Foo.h'))
	assert_equal(buffer:line_from_position(buffer.current_pos), 3)
	assert_equal(buffer:get_sel_text(), 'Foo')
	buffer:close()

	lsp.goto_symbol()
	assert_equal(buffer.filename, file(dir .. '/main.cpp'))
	assert_equal(buffer:line_from_position(buffer.selection_start), 4) -- entire main() is selected

	lsp_menu[_L['Stop Server']][2]()
	sleep(0.5)
	ui.update()
	if QT then -- process exit
		ui.update()
		sleep(0.1)
		ui.update()
	end
	assert(lsp_buf:get_text():find('Server exited with status 0'), 'clangd did not stop')
	buffer:close(true)
	buffer:close() -- [LSP]

	lsp.server_commands.cpp = nil -- reset
	removedir(dir)
end

function test_lsp_lua()
	local lsp = require('lsp')
	buffer.new()
	buffer:set_lexer('lua')
	-- Ensure the language server starts. It normally autostarts, but this will not happen when
	-- the lsp module is loaded after init and was not able to hook into events.LEXER_LOADED,
	-- events.FILE_OPENED, etc.
	lsp.start()
	sleep(0.5) -- allow time to initialize
	buffer:add_text('t')
	lsp.autocomplete()
	assert(buffer:auto_c_active(), 'autocompletion not active')
	assert_equal(buffer.auto_c_current_text, 'table')
	buffer:auto_c_complete()
	buffer:add_text('.')
	events.emit(events.CHAR_ADDED, string.byte('.'))
	assert(buffer:auto_c_active(), 'autocompletion not active')
	assert_equal(buffer.auto_c_current_text, 'concat')
	buffer:auto_c_complete()
	buffer:add_text('(')
	events.emit(events.CHAR_ADDED, string.byte('('))
	assert(view:call_tip_active(), 'call tip not active')
	lsp.stop()
	buffer:close(true)
end

function test_lua_repl()
	local repl = require('lua_repl')
	repl.open()
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer._type, '[Lua REPL]')
	view:goto_buffer(-1)
	repl.open() -- should re-open existing REPL
	assert_equal(#_BUFFERS, 2)
	assert_equal(buffer._type, '[Lua REPL]')
	view:split()
	view:goto_buffer(-1)
	repl.open() -- should switch to other view
	assert_equal(buffer._type, '[Lua REPL]')
	view:unsplit()

	-- Test simple evaluation.
	buffer:add_text('1+2')
	repl.evaluate_repl()
	assert_equal(buffer:get_line(buffer.line_count - 1), '--> 3' .. newline())

	-- Test multi-line evaluation.
	buffer:add_text('2+')
	assert(not repl.evaluate_repl())
	buffer:new_line()
	buffer:add_text('3')
	buffer:line_up_extend()
	repl.evaluate_repl()
	assert_equal(buffer:get_line(buffer.line_count - 1), '--> 5' .. newline())

	-- Test pretty-printing.
	buffer:add_text('{1,2,3}')
	repl.evaluate_repl()
	assert_equal(buffer:get_line(buffer.line_count - 1), '--> {1 = 1, 2 = 2, 3 = 3}' .. newline())

	-- Test completions.
	buffer:add_text('string.')
	repl.complete_lua()
	assert(buffer:auto_c_active(), 'no autocompletions')
	assert_equal(buffer.auto_c_current_text, 'byte')
	buffer:auto_c_cancel()
	buffer:del_line_left()
	buffer:add_text('buffer:get')
	events.emit(events.KEYPRESS, 'ctrl+ ')
	repl.complete_lua()
	assert(buffer:auto_c_active(), 'no autocompletions')
	assert_equal(buffer.auto_c_current_text, 'get_cur_line')
	buffer:auto_c_cancel()
	buffer:del_line_left()
	buffer:add_text('_SCINTILLA.constants.AL')
	repl.complete_lua()
	assert(buffer:auto_c_active(), 'no autocompletions')
	assert_equal(buffer.auto_c_current_text, 'ALPHA_NOALPHA')
	buffer:auto_c_cancel()
	buffer:del_line_left()

	-- Test history.
	repl.cycle_history_prev()
	assert_equal(buffer:get_line(buffer.line_count), '{1,2,3}')
	events.emit(events.KEYPRESS, not CURSES and 'ctrl+up' or 'ctrl+p')
	assert_equal(buffer:get_line(buffer.line_count - 1), '2+' .. newline())
	assert_equal(buffer:get_line(buffer.line_count), '3')
	repl.cycle_history_prev()
	assert_equal(buffer:get_line(buffer.line_count), '1+2')
	repl.cycle_history_prev() -- nothing more
	assert_equal(buffer:get_line(buffer.line_count), '1+2')
	repl.cycle_history_prev()
	assert_equal(buffer:get_line(buffer.line_count), '1+2')
	repl.cycle_history_next()
	assert_equal(buffer:get_line(buffer.line_count - 1), '2+' .. newline())
	assert_equal(buffer:get_line(buffer.line_count), '3')
	events.emit(events.KEYPRESS, not CURSES and 'ctrl+down' or 'ctrl+n')
	assert_equal(buffer:get_line(buffer.line_count), '{1,2,3}')
	repl.cycle_history_next() -- nothing more
	assert_equal(buffer:get_line(buffer.line_count), '{1,2,3}')
	buffer:del_line_left()

	-- Test it still works after reset.
	-- TODO: this fails if require('lua_repl') is not called from user init.lua
	reset()
	buffer:add_text('print("foo")')
	events.emit(events.KEYPRESS, '\n')
	assert_equal(buffer:get_line(buffer.line_count - 1), '--> foo' .. newline())

	-- Test long line result.
	view.edge_column = 80
	buffer:add_text('buffer')
	repl.evaluate_repl()
	assert_equal(buffer:get_line(buffer.line_count - 1), '--> }' .. newline()) -- result over multiple lines

	-- Test autocompletion list cycling instead of history cycling.
	buffer:add_text('table.')
	repl.complete_lua()
	assert(buffer:auto_c_active(), 'no completions')
	assert(buffer.auto_c_current_text, 'concat')
	repl.cycle_history_next()
	assert(buffer.auto_c_current_text, 'insert')
	repl.cycle_history_prev()
	assert(buffer.auto_c_current_text, 'concat')
	buffer:auto_c_cancel()

	buffer:close(true)
end

function test_open_file_mode()
	if WIN32 then return end -- TODO: cannot complete network paths
	local open_file_mode = require('open_file_mode')
	open_file_mode()
	ui.command_entry:add_text(file(_HOME .. '/t'))
	events.emit(events.KEYPRESS, '\t')
	assert(ui.command_entry:auto_c_active(), 'no completions')
	ui.command_entry:line_end() -- highlight last completion
	assert_equal(ui.command_entry.auto_c_current_text, file('themes/'))
	ui.command_entry:auto_c_complete()
	events.emit(events.KEYPRESS, '\t')
	ui.command_entry:auto_c_complete()
	events.emit(events.KEYPRESS, '\n')
	assert_equal(buffer.filename, file(_HOME .. '/themes/dark.lua'))
	buffer:close()
end

-- TODO: scratch module

function test_spellcheck()
	local spellcheck = require('spellcheck')
	local SPELLING_ID = 1 -- not accessible
	buffer:new()
	buffer:add_text('-- foose bar\nbaz = "quux"')

	-- Test background highlighting.
	spellcheck.check_spelling()
	local function get_misspellings()
		local misspellings = {}
		local s = buffer:indicator_end(spellcheck.INDIC_SPELLING, 1)
		local e = buffer:indicator_end(spellcheck.INDIC_SPELLING, s)
		while e > s do
			misspellings[#misspellings + 1] = buffer:text_range(s, e)
			s = buffer:indicator_end(spellcheck.INDIC_SPELLING, e)
			e = buffer:indicator_end(spellcheck.INDIC_SPELLING, s)
		end
		return misspellings
	end
	assert_equal(get_misspellings(), {'foose', 'baz', 'quux'})
	buffer:set_lexer('lua')
	spellcheck.check_spelling()
	assert_equal(get_misspellings(), {'foose', 'quux'})

	-- Test interactive parts.
	spellcheck.check_spelling(true)
	assert(buffer:auto_c_active(), 'no misspellings')
	local s, e = buffer.current_pos, buffer:word_end_position(buffer.current_pos)
	assert_equal(buffer:text_range(s, e), 'foose')
	buffer:cancel()
	events.emit(events.USER_LIST_SELECTION, SPELLING_ID, 'goose', s)
	assert_equal(buffer:text_range(s, e), 'goose')
	ui.update()
	if CURSES then spellcheck.check_spelling() end -- not needed when interactive
	spellcheck.check_spelling(true)
	assert(buffer:auto_c_active(), 'spellchecker not active')
	s, e = buffer.current_pos, buffer:word_end_position(buffer.current_pos)
	assert_equal(buffer:text_range(s, e), 'quux')
	buffer:cancel()
	events.emit(events.INDICATOR_CLICK, s)
	assert(buffer:auto_c_active(), 'spellchecker not active')
	buffer:cancel()
	events.emit(events.USER_LIST_SELECTION, 1, '(Ignore)', s)
	assert_equal(get_misspellings(), {})
	spellcheck.check_spelling(true)
	assert(not buffer:auto_c_active(), 'misspellings')

	-- TODO: test add.

	buffer:close(true)
end

function test_spellcheck_encodings()
	if WIN32 or OSX then return end -- TODO:
	local spellcheck = require('spellcheck')
	local SPELLING_ID = 1 -- not accessible
	buffer:new()

	-- Test UTF-8 dictionary and caret placement.
	buffer:set_text(' multiumesc')
	spellcheck.load('ro_RO')
	spellcheck.check_spelling()
	events.emit(events.INDICATOR_CLICK, 8)
	assert_equal(buffer.auto_c_current_text, 'mulțumesc')
	ui.update()
	events.emit(events.USER_LIST_SELECTION, SPELLING_ID, buffer.auto_c_current_text,
		buffer.current_pos)
	assert_equal(buffer:get_text(), ' mulțumesc')
	assert_equal(buffer.current_pos, 9)

	-- Test ISO8859-1 dictionary with different buffer encodings.
	for _, encoding in pairs{'UTF-8', 'ISO8859-1', 'CP1252'} do
		buffer:clear_all()
		buffer:set_encoding(encoding)
		buffer:set_text('schoen')
		ui.update()
		spellcheck.load('de_DE')
		spellcheck.check_spelling(true)
		assert_equal(buffer.auto_c_current_text, 'schön')
		events.emit(events.USER_LIST_SELECTION, SPELLING_ID, buffer.auto_c_current_text,
			buffer.current_pos)
		assert_equal(buffer:get_text():iconv(encoding, 'UTF-8'),
			string.iconv('schön', encoding, 'UTF-8'))
		ui.update()
		spellcheck.check_spelling()
		assert_equal(buffer:indicator_end(spellcheck.INDIC_SPELLING, 1), 1)
	end

	buffer:close(true)
end

function test_spellcheck_load_interactive()
	require('spellcheck')
	textadept.menu.menubar['Tools/Spelling/Load Dictionary...'][2]()
end

-- Load buffer and view API from their respective LuaDoc files.
local function load_buffer_view_props()
	local buffer_props, view_props = {}, {}
	for line in io.lines(_HOME .. '/core/.buffer.luadoc') do
		if line:find('@field view%.') then
			view_props[line:match('@field view%.([%w_]+)')] = true
		elseif line:find('@table view%.') then
			view_props[line:match('@table view%.([%w_]+)')] = true
		elseif line:find('@function view:') then
			view_props[line:match('@function view:([%w_]+)')] = true
		elseif line:find('@field') then
			buffer_props[line:match('@field ([%w_]+)')] = true
		elseif line:find('@table') then
			buffer_props[line:match('@table ([%w_]+)')] = true
		elseif line:find('@function') then
			buffer_props[line:match('@function ([%w_]+)')] = true
		end
	end
	return buffer_props, view_props
end

local function check_property_usage(filename, buffer_props, view_props, errors)
	print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
	local line_num, count = 1, 0
	for line in io.lines(filename) do
		for pos, id, prop in line:gmatch('()([%w_]+)[.:]([%w_]+)') do
			if id == 'M' or id == 'f' or id:find('^p%d?$') or id == 'lexer' or id == 'spawn_proc' then
				goto continue
			end
			if prop == 'MARK_BOOKMARK' and id == 'textadept' then goto continue end
			if prop == 'size' and (id == 'ui' or id == 'split') then goto continue end
			if prop == 'home' and id == 'keys' then goto continue end
			if prop == 'save' and id == 'Rout' then goto continue end
			if (prop == 'filename' or prop == 'column') and (id == 'detail' or id == 'record') then
				goto continue
			end
			if prop == 'length' and (id == 'placeholder' or id == 'ph') then goto continue end
			if prop == 'close' and (id == 'client' or id == 'server') then goto continue end
			if prop == 'new' and (id == 'Foo' or id == 'Array' or id == 'Server' or id == 'snippet') then
				goto continue
			end
			if id == 'snippets' then goto continue end
			if prop == 'indent' and id == 'state' then goto continue end
			if prop == 'line_length' and id == 'format' then goto continue end
			if prop == 'tag' and id == 'styles' then goto continue end
			if prop == 'property' and (id == 'styles' or id == 'view') then goto continue end
			if prop == 'auto_c_fill_ups' and id == 'server' then goto continue end
			if prop == 'buffer' and (id == '_G' or id == 'split' or id == 'view1' or id == 'view2') then
				goto continue
			end
			if prop == 'goto_pos' and id == 'view' then goto continue end -- core/ui.lua's print_to()
			if buffer_props[prop] then
				if not id:find('^buffer%d?$') and not id:find('buf$') then
					errors[#errors + 1] = string.format('%s:%d:%d: "%s" should be a buffer property',
						filename, line_num, pos, prop)
				end
				count = count + 1
			elseif view_props[prop] then
				if id ~= 'view' then
					errors[#errors + 1] = string.format('%s:%d:%d: "%s" should be a view property', filename,
						line_num, pos, prop)
				end
				count = count + 1
			end
			::continue::
		end
		line_num = line_num + 1
	end
	print(string.format('Checked %d buffer/view property usages.', count))
end

function test_buffer_view_usage()
	local buffer_props, view_props = load_buffer_view_props()
	local filter = {
		'.lua', '.luadoc', '!/lexers', '!/modules/lsp/doc', '!/modules/lsp/dkjson.lua',
		'!/modules/lsp/ldoc', '!/modules/lsp/ldoc.lua', '!modules/lsp/pl', '!modules/lsp/logging',
		'!/modules/debugger/dkjson.lua', '!/modules/debugger/lua/mobdebug.lua',
		'!/modules/debugger/lua/socket.lua', '!/modules/debugger/luasocket', '!/scripts', '!/build'
	}
	local errors = {}
	for filename in lfs.walk(_HOME, filter) do
		check_property_usage(filename, buffer_props, view_props, errors)
	end
	assert(#errors == 0, '\n' .. table.concat(errors, '\n'))
end

--------------------------------------------------------------------------------

local TEST_OUTPUT_BUFFER = '[Test Output]'
function print(...) ui.print_to(TEST_OUTPUT_BUFFER, ...) end
function print_silent(...) ui.print_silent_to(TEST_OUTPUT_BUFFER, ...) end
-- Clean up after a previously failed test.
local function cleanup()
	while #_BUFFERS > 1 do
		if buffer._type == TEST_OUTPUT_BUFFER then view:goto_buffer(1) end
		buffer:close(true)
	end
	while view:unsplit() do end
end

-- Determines whether or not to run the test whose name is string *name*.
-- If no arg patterns are provided, returns true.
-- If only inclusive arg patterns are provided, returns true if *name* matches at least one of
-- those patterns.
-- If only exclusive arg patterns are provided ('-' prefix), returns true if *name* does not
-- match any of them.
-- If both inclusive and exclusive arg patterns are provided, returns true if *name* matches
-- at least one of the inclusive ones, but not any of the exclusive ones.
-- @param name Name of the test to check for inclusion.
-- @return true or false
local function include_test(name)
	if #arg == 0 then return true end
	local include, includes, excludes = false, false, false
	for _, patt in ipairs(arg) do
		if patt:find('^%-') then
			if name:find(patt:sub(2)) then return false end
			excludes = true
		else
			if name:find(patt) then include = true end
			includes = true
		end
	end
	return include or not includes and excludes
end

local tests = {}
for k in pairs(_ENV) do if k:find('^test_') and include_test(k) then tests[#tests + 1] = k end end
table.sort(tests)

print('Starting test suite')

local tests_run, tests_failed, tests_failed_expected = 0, 0, 0

for i = 1, #tests do
	cleanup()
	assert_equal(#_BUFFERS, 1)
	assert_equal(#_VIEWS, 1)

	_ENV = setmetatable({}, {__index = _ENV})
	local name, f = tests[i], _ENV[tests[i]]
	print(string.format('Running %s', name))
	ui.update()
	local ok, errmsg = xpcall(f, function(errmsg)
		local fail = not expected_failures[f] and 'Failed!' or 'Expected failure.'
		return string.format('%s %s', fail, debug.traceback(errmsg, 3))
	end)
	ui.update()
	if not errmsg then
		if #_BUFFERS > 1 then
			ok, errmsg = false, 'Failed! Test did not close the buffer(s) it created'
		elseif #_VIEWS > 1 then
			ok, errmsg = false, 'Failed! Test did not unsplit the view(s) it created'
		elseif expected_failures[f] then
			ok, errmsg = false, 'Failed! Test should have failed'
			expected_failures[f] = nil
		end
	end
	print(ok and 'Passed.' or errmsg)

	tests_run = tests_run + 1
	if not ok then
		tests_failed = tests_failed + 1
		if expected_failures[f] then tests_failed_expected = tests_failed_expected + 1 end
	end
end

print(string.format('%d tests run, %d unexpected failures, %d expected failures', tests_run,
	tests_failed - tests_failed_expected, tests_failed_expected))

-- Note: stock luacov crashes on hook.lua lines 51 and 58 every other run.
-- `file.max` and `file.max_hits` are both `nil`, so change comparisons to be `(file.max or 0)`
-- and `(file.max_hits or 0)`, respectively.
if package.loaded['luacov'] then
	require('luacov').save_stats()
	os.execute('luacov -c ' .. _HOME .. '/.luacov')
	local f = assert(io.open('luacov.report.out'))
	buffer:append_text(f:read('a'):match('\nSummary.+$'))
	f:close()
else
	buffer:new_line()
	buffer:append_text('No LuaCov coverage to report.')
end
buffer:set_save_point()

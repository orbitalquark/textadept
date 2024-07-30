-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Tests to run.
local tests = {}

--- Registers a unit test to run.
-- Tests are tagged with the file they belong to. For example, tests in *core/init_test.lua*
-- are tagged with '#core/init'. This allows individual test suites to be included or excluded
-- when running tests.
-- Use a '#skip' tag to skip a test by default.
-- @param name Name or description of the unit test.
-- @param f Unit test function.
-- @function _G.test
local test = setmetatable(dofile(_HOME .. '/test/helpers.lua'), {
	__call = function(self, name, f)
		name = string.format('%s - #%s ', name, _TESTSUITE)
		tests[#tests + 1], tests[name] = name, f
	end
})

--- Map of tests expected to fail to `true`.
local expected_failures = {}

--- Expect the most recently defined test to fail. If it does not fail, that is considered
-- a failure.
-- @name _G.expected_failure
local function expected_failure() expected_failures[tests[#tests]] = true end

-- Test environment.
local env = setmetatable({expected_failure = expected_failure, test = test}, {__index = _G})

-- Load all tests from *_test.lua files in _HOME.
local test_files = {}
for test_file in lfs.walk(_HOME, '.lua') do -- TODO: '*_test.lua'
	if test_file:find('_test%.lua$') then test_files[#test_files + 1] = test_file end
end
table.sort(test_files)
for _, test_file in ipairs(test_files) do
	_TESTSUITE = test_file:sub(#_HOME + 2, -string.len('_test.lua') - 1)
	assert(loadfile(test_file, 't', env))()
end

-- Read tags to include and exclude from arg.
local include_tags, exclude_tags = {}, {skip = true}
for _, tag in ipairs(arg) do
	if tag:find('^%-') then
		exclude_tags[tag:sub(2)] = true
	else
		include_tags[tag] = true
	end
end

--- Returns a string snapshot of the current Textadept state suitable for error reporting,
-- unless it contains a single, empty buffer. In that case, returns an empty string.
local function snapshot()
	local lines = {''} -- leading newline
	for i, buffer in ipairs(_BUFFERS) do
		local text = buffer:get_text():gsub('(\r?\n)', '%1\t')
		if text == '' and #_BUFFERS == 1 then return '' end -- shortcut
		lines[#lines + 1] = string.format('buffer %d (%s):\n\t%s\n', i,
			buffer.filename or buffer._type or _L['Untitled'], text)
		local pos = buffer.current_pos
		lines[#lines + 1] = string.format('caret position: (%d:%d)', buffer:line_from_position(pos),
			buffer.column[pos])
		lines[#lines + 1] = string.format('selection: %d-%d ("%s")', buffer.selection_start,
			buffer.selection_end, buffer:get_sel_text())
	end
	for i, view in ipairs(_VIEWS) do
		lines[#lines + 1] = string.format('view %d: buffer %d', i, _BUFFERS[view.buffer])
	end
	return table.concat(lines, '\n')
end

local tests_passed, tests_failed, tests_skipped, tests_failed_expected = 0, 0, 0, 0

if CURSES then io.output('test.log') end

for _, name in ipairs(tests) do
	local f = tests[name]
	local ok, errmsg, status

	-- Determine if the test should be skipped.
	local skip = next(include_tags)
	for tag in name:gmatch('%#(%S+)') do
		if exclude_tags[tag] then
			skip = true
			break
		elseif skip and include_tags[tag] then
			skip = false
			break
		end
	end
	if skip then goto skip end

	-- Run the test.
	do
		_ENV = setmetatable({}, {__index = _G}) -- simple sandbox
		ok, errmsg = xpcall(f, function(errmsg)
			if expected_failures[name] then return false end -- do not print traceback
			local text = buffer:get_text():gsub('(\r?\n)', '%1\t')
			local s, e = buffer.selection_start, buffer.selection_end
			return string.format('%s\nlog:\n\t%s%s', debug.traceback(errmsg, 3),
				table.concat(test.log, '\n\t'), snapshot())
		end)
	end
	if errmsg == nil and expected_failures[name] then
		ok = false
		local info = debug.getinfo(f)
		errmsg = string.format('%s:%d: Test passed, but should have failed', info.short_src,
			info.linedefined)
		expected_failures[name] = nil
	end

	-- Clean up after the test.
	test.log:clear()
	while view:unsplit() do end
	while #_BUFFERS > 1 do buffer:close(true) end
	buffer:close(true) -- the last one
	ui.update()
	if ui.command_entry.active then test.type('esc') end
	if ui.find.active then
		ui.find.incremental, ui.find.in_files = false, false
		ui.find.focus()
	end

	-- Write test output.
	if ok then
		status = 'OK'
	elseif expected_failures[name] then
		status = 'OK*'
	else
		status = 'FAIL'
		io.output():write(string.rep('-', 100), '\n')
	end
	io.output():write(status, ' ', name, '\n'):flush()
	if not ok and errmsg then io.output():write(errmsg, '\n', string.rep('-', 100), '\n') end

	::skip::
	-- Update statistics.
	if ok then
		tests_passed = tests_passed + 1
	elseif skip then
		tests_skipped = tests_skipped + 1
	elseif not expected_failures[name] then
		tests_failed = tests_failed + 1
	else
		tests_failed_expected = tests_failed_expected + 1
	end
end

io.output():write(string.format('%d failed, %d passed, %d skipped, %d expected failures\n',
	tests_failed, tests_passed, tests_skipped, tests_failed_expected))

-- Note: stock luacov crashes on hook.lua lines 56 and 63 every other run.
-- `file.max` and `file.max_hits` are both `nil`, so change comparisons to be `(file.max or 0)`
-- and `(file.max_hits or 0)`, respectively.
if package.loaded['luacov'] then
	require('luacov').save_stats()
	os.execute('luacov -c ' .. _HOME .. '/.luacov')
	local report = _HOME .. '/luacov.report.out'
	local f = assert(io.open(report))
	io.stdout:write('\n', 'LuaCov Summary (', report, ')', f:read('a'):match('Summary(.+)$'))
	f:close()
end

-- Quit Textadept with exit status depending on whether any tests failed.
textadept.session.save_on_quit = false -- do not clobber default session
timeout(0.01, function() quit(tests_failed) end)

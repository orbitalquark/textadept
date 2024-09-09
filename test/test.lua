-- Copyright 2020-2024 Mitchell. See LICENSE.

if CURSES or os.getenv('CI') == 'true' then io.output('test.log') end

--- Map of test suites to their setup functions.
local setups = {}

--- Defines function *f* as the setup function for tests in the current suite.
-- @param f Test setup function.
-- @name _G.setup
local function setup(f) setups[_TESTSUITE] = f end

--- Map of test suites to their teardown functions.
local teardowns = {}

--- Defines function *f* as the teardown function for tests in the current suite.
-- @param f Test teardown function.
-- @name _G.teardown
local function teardown(f) teardowns[_TESTSUITE] = f end

--- Tests to run.
local tests = {}

--- Registers a unit test described by string *name* to test function *f*.
-- *name* may contain '#tag' tags in order to easily include or exclude tests.
-- Tests are automatically tagged with the file they belong to, effectively making test suites
-- that can be included or excluded in test runs. For example, tests in *core/init_test.lua*
-- are tagged with '#core/init'.
-- Use a '#skip' tag to skip a test by default.
-- @param name Name or description of the unit test.
-- @param f Unit test function.
-- @usage test('it should do #something', function() ... end)
-- @function _G.test
local test = setmetatable(dofile(_HOME .. '/test/helpers.lua'), {
	__call = function(self, name, f)
		name = string.format('%s - #%s', name, _TESTSUITE)
		tests[#tests + 1], tests[name] = name, f
	end
})

--- Skips the most recently defined test.
local function skip() tests[#tests] = tests[#tests] .. ' #skip' end

--- Map of tests to retries.
local retries = setmetatable({}, {__index = function() return 1 end})

--- If the most recently defined test fails, retry it up to *n* times.
-- Tests that depend on external processes may fail every now and then due to I/O instabilities,
-- particularly on CI.
-- The default is to retry once.
local function retry(n) retries[tests[#tests]] = n end

--- Map of tests expected to fail to `true`.
local expected_failures = {}

--- Expect the most recently defined test to fail. If it does not fail, that is considered
-- a failure.
-- @name _G.expected_failure
local function expected_failure() expected_failures[tests[#tests]] = true end

-- Test environment.
local env = setmetatable({
	setup = setup, teardown = teardown, test = test, skip = skip, retry = retry,
	expected_failure = expected_failure
}, {__index = _G})
for _, f in ipairs{'message', 'input', 'open', 'save', 'list'} do
	ui.dialogs[f] = function() error(debug.traceback('ui.dialogs.' .. f .. ' not mocked', 2), 2) end
end

-- Load all tests from '*_test.lua' files in _HOME.
local test_files = {}
for test_file in lfs.walk(_HOME, {'.lua', '!/build'}) do -- TODO: '*_test.lua'
	if test_file:find('_test%.lua$') then test_files[#test_files + 1] = test_file end
end
table.sort(test_files)
for _, test_file in ipairs(test_files) do
	_TESTSUITE = test_file:sub(#_HOME + 2, -string.len('_test.lua') - 1):gsub('\\', '/'):gsub(
		'/init$', '')
	local ok, errmsg = loadfile(test_file, 't', env)
	if ok then ok, errmsg = pcall(ok) end
	if not ok then io.output():write('load error: ', errmsg, '\n') end
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

-- Qt on Linux needs a window manager to facilitate focus events.
-- When running under xvfb-run, start a window manager before running tests.
if QT and LINUX and os.getenv('DISPLAY'):find('99') then
	local ok, errmsg = pcall(os.spawn, 'matchbox-window-manager')
	if not ok then io.output():write('spawn error: ', errmsg, '\n') end
end

-- Run tests.
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
		end
	end
	if skip then goto skip end

	-- Run the test.
	for i = 1, retries[name] + 1 do
		local suite = name:match('[^#]+$')
		if setups[suite] then
			local ok, errmsg = pcall(setups[suite])
			if not ok then io.output():write('setup error: ', errmsg, '\n') end
		end

		_ENV = setmetatable({}, {__index = _G}) -- simple sandbox
		ok, errmsg = xpcall(f, function(errmsg)
			if expected_failures[name] then return false end -- do not print traceback
			local text = buffer:get_text():gsub('(\r?\n)', '%1\t')
			local s, e = buffer.selection_start, buffer.selection_end
			errmsg = debug.traceback(errmsg, 3)
			return string.format('%s\nlog:\n\t%s%s', errmsg, table.concat(test.log, '\n\t'), snapshot())
		end)

		if teardowns[suite] then
			local ok, errmsg = pcall(teardowns[suite])
			if not ok then io.output():write('teardown error: ', errmsg, '\n') end
		end
		while view:unsplit() do end
		while #_BUFFERS > 1 do buffer:close(true) end
		buffer:close(true) -- the last one

		if ok or expected_failures[name] then break end
		test.log('retrying test (attempt #', i + 1, ')')
	end
	if errmsg == nil and expected_failures[name] then
		ok = false
		local info = debug.getinfo(f)
		errmsg = string.format('%s:%d: Test passed, but should have failed', info.short_src,
			info.linedefined)
		expected_failures[name] = nil
	end
	test.log:clear()
	::skip::

	-- Write test output.
	if ok then
		status = 'OK'
	elseif expected_failures[name] then
		status = 'OK*'
	elseif skip then
		status = 'SKIP'
	else
		status = 'FAIL'
		io.output():write(string.rep('-', 100), '\n')
	end
	if not skip or not next(include_tags) then
		io.output():write(status, ' ', name, '\n'):flush()
		if not ok and errmsg then io.output():write(errmsg, '\n', string.rep('-', 100), '\n') end
	end

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

-- Output final result.
io.output():write(string.format('%d failed, %d passed, %d skipped, %d expected failures\n',
	tests_failed, tests_passed, tests_skipped, tests_failed_expected))

-- Note: stock luacov crashes on hook.lua lines 56 and 63 every other run.
-- `file.max` and `file.max_hits` are both `nil`, so change comparisons to be `(file.max or 0)`
-- and `(file.max_hits or 0)`, respectively.
if package.loaded['luacov'] then
	require('luacov').save_stats()
	os.execute('luacov -c ' .. _HOME .. '/.luacov')
	local report = lfs.abspath('luacov.report.out')
	local ok, f = pcall(io.open, report)
	if ok then
		io.output():write('\n', 'LuaCov Summary (', report, ')', f:read('a'):match('Summary(.+)$'))
		f:close()
	else
		io.output():write('open error: ', f, '\n')
	end
end

-- Quit Textadept with exit status depending on whether any tests failed.
timeout(0.01, function() quit(tests_failed) end)

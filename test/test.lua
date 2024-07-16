-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Tests to run.
local tests = {}

--- Registers a unit test to run.
-- @param name Name or description of the unit test.
-- @param f Unit test function.
-- @function test
local test = setmetatable(dofile(_HOME .. '/test/helpers.lua'), {
	__call = function(self, name, f) tests[#tests + 1], tests[name] = name, f end
})

--- Map of tests expected to fail to `true`.
local expected_failures = {}

--- Expect the test *f* to fail. If it does not fail, that is considered a failure.
local function expected_failure(f) expected_failures[assert_type(f, 'function', 1)] = true end

-- Test environment.
local env = setmetatable({expected_failure = expected_failure, test = test}, {__index = _G})

-- Load tests.
-- TODO: lfs.walk(_HOME, '*_test.lua')
for test_file in lfs.walk(_HOME, '.lua') do
	if test_file:find('_test%.lua$') then assert(loadfile(test_file, 't', env))() end
end

--- Returns a string snapshot of the current Textadept state suitable for error reporting,
-- unless it contains a single, empty buffer. In that case, returns an empty string.
local function snapshot()
	local lines = {''} -- leading newline
	for i, buffer in ipairs(_BUFFERS) do
		local text = buffer:get_text():gsub('(\r?\n)', '\t%1')
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

local tests_succeeded, tests_failed, tests_failed_expected = 0, 0, 0

if CURSES then io.output('test.log') end

for _, name in ipairs(tests) do
	-- Run the test.
	io.output():write(name, '... '):flush()
	local f = tests[name]
	local ok, errmsg
	do
		_ENV = setmetatable({}, {__index = _G}) -- simple sandbox
		ok, errmsg = xpcall(f, function(errmsg)
			local text = buffer:get_text():gsub('(\r?\n)', '%1\t')
			local s, e = buffer.selection_start, buffer.selection_end
			return string.format('%s\nlog:\n\t%s%s', debug.traceback(errmsg, 3),
				table.concat(test.log, '\n\t'), snapshot())
		end)
	end
	if not errmsg and expected_failures[f] then
		ok, errmsg = false, 'Test passed, but should have failed'
		expected_failures[f] = nil
	end

	-- Write test output.
	io.output():write(ok and 'PASS' or 'FAIL', '\n'):flush()
	if not ok then print(errmsg) end

	-- Clean up after the test.
	test.log:clear()
	while #_BUFFERS > 1 do buffer:close(true) end
	buffer:close(true) -- the last one
	while view:unsplit() do end

	-- Update statistics.
	if ok then
		tests_succeeded = tests_succeeded + 1
	elseif not expected_failures[f] then
		tests_failed = tests_failed + 1
	else
		tests_failed_expected = tests_failed_expected + 1
	end
end

print(string.format('%d successes, %d failures, %d expected failures', tests_succeeded,
	tests_failed, tests_failed_expected))

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
else
	print('No LuaCov coverage to report.')
end

-- Quit Textadept with exit status depending on whether any tests failed.
timeout(0.1, function() quit(tests_failed) end)

-- Copyright 2020-2024 Mitchell. See LICENSE.

test('assert should return its argument on success', function()
	local value = 1

	local result = test.assert(value)

	test.assert_equal(result, value)
end)

test('assert should raise an error on fail', function()
	local error_message = 'error!'
	local false_assertion = function() test.assert(false, error_message) end

	test.assert_raises(false_assertion, error_message)
end)

test('assert should format a given error message', function()
	local value = 0
	local false_assertion = function() test.assert(false, 'error: %s', value) end

	test.assert_raises(false_assertion, 'error: ' .. value)
end)

test('assert should fall back on a default error message', function()
	local default_error_message = 'assertion failed!'
	local false_assertion = function() test.assert(false) end

	test.assert_raises(false_assertion, default_error_message)
end)

test('assert_type should return its argument on success', function()
	local s = ''
	local needs_string = function(s) return assert_type(s, 'string', 1) end

	local result = needs_string(s)

	test.assert_equal(result, s)
end)

test('assert_type should recognize more than one type', function()
	local n = 1
	local needs_string_or_number = function(v) return assert_type(v, 'string/number', 1) end

	local result = needs_string_or_number(n)

	test.assert_equal(result, n)
end)

test('assert_type should allow a value to be optional', function()
	local optional_table = function(v) return assert_type(v, 'table/nil', 1) end

	local result = optional_table()

	test.assert_equal(result, nil)
end)

test('assert_type should consider an object with a __call metamethod to be a function', function()
	local f = setmetatable({}, {__call = function() end})
	local needs_callable = function(f) return assert_type(f, 'function', 1) end

	local callable = needs_callable(f)

	test.assert_equal(callable, f)
end)

test('assert_type should raise an error on fail', function()
	local needs_string = function(s) assert_type(s, 'string', 1) end
	local optional_second_boolean = function(_, b) assert_type(b, 'boolean/nil', 2) end

	test.assert_raises(function() needs_string(1) end,
		"bad argument #1 to 'needs_string' (string expected, got number")
	test.assert_raises(function() optional_second_boolean('', '') end,
		"bad argument #2 to 'optional_second_boolean' (boolean/nil expected, got string")
end)

-- Coverage tests.

test('assert_type should raise an error for invalid arguments', function()
	local invalid_argument = function() assert_type(true, 1) end
	local missing_narg = function() assert_type(true, '') end

	test.assert_raises(invalid_argument, 'string expected, got number')
	test.assert_raises(missing_narg, 'value expected, got nil')
end)

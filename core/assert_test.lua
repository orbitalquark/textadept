-- Copyright 2020-2024 Mitchell. See LICENSE.

test('assert should return its argument on success', function()
	local result = test.assert(1)

	test.assert_equal(result, 1)
end)

test('assert should raise an error on fail', function()
	local error_message = 'error!'
	local false_assertion = function() test.assert(false, error_message) end

	test.assert_raises(false_assertion, error_message)
end)

test('assert should format a given error message', function()
	local false_assertion = function() test.assert(false, 'error: %s', 0) end

	test.assert_raises(false_assertion, 'error: 0')
end)

test('assert should fall back on a default error message', function()
	local false_assertion = function() test.assert(false) end

	test.assert_raises(false_assertion, 'assertion failed!')
end)

test('assert_type should raise errors for invalid arguments', function()
	local invalid_type_name = function() assert_type(nil, {}) end
	local missing_narg = function() assert_type(nil, '') end

	test.assert_raises(function() invalid_type_name() end,
		"bad argument #2 to 'assert_type' (string expected, got table")
	test.assert_raises(function() missing_narg() end,
		"bad argument #3 to 'assert_type' (value expected, got nil")
end)

test('assert_type should return its argument on success', function()
	local needs_string = function(s) return assert_type(s, 'string', 1) end
	local s = ''

	local result = needs_string(s)

	test.assert_equal(result, s)
end)

test('assert_type should recognize more than one type', function()
	local needs_string_or_number = function(v) return assert_type(v, 'string/number', 1) end
	local n = 1

	local result = needs_string_or_number(n)

	test.assert_equal(result, n)
end)

test('assert_type should allow a value to be optional', function()
	local optional_table = function(v) return assert_type(v, 'table/nil', 1) end

	local result = optional_table()

	test.assert_equal(result, nil)
end)

test('assert_type should consider an object with a __call metamethod to be a function', function()
	local needs_callable = function(f) return assert_type(f, 'function', 1) end
	local f = setmetatable({}, {__call = function() end})

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

-- Copyright 2020-2024 Mitchell. See LICENSE.

test('assert should return a truthy first argument', function()
	local result = test.assert(1, 'okay')
	test.assert_equal(result, 1)
end)

test('assert should use the second argument as an error message', function()
	local false_assertion = function() test.assert(false, 'not okay') end
	test.assert_raises(false_assertion, 'not okay')
end)

test('assert should format an error message using additional arguments', function()
	local false_assertion = function() test.assert(false, 'not okay: %s', 0) end
	test.assert_raises(false_assertion, 'not okay: 0')
end)

test('assert should allow a non-string error object', function()
	local false_assertion = function() test.assert(false, 1234) end
	test.assert_raises(false_assertion, '1234')
end)

test("assert should fall back on Lua assert's default error message", function()
	local false_assertion = function() test.assert(false) end
	test.assert_raises(false_assertion, 'assertion failed!')
end)

test('assert_type api should raise errors if any of its argument types are invalid', function()
	local invalid_second_arg = function() assert_type(nil, string) end
	test.assert_raises(function() invalid_second_arg() end,
		"bad argument #2 to 'assert_type' (string expected, got table")

	local omitted_third_arg = function() assert_type(nil, 'string') end
	test.assert_raises(function() omitted_third_arg() end,
		"bad argument #3 to 'assert_type' (value expected, got nil")
end)

test('assert_type should return the given argument if its type matches the assertion', function()
	local needs_string = function(s) return assert_type(s, 'string', 1) end
	local result = needs_string('bar')
	test.assert_equal(result, 'bar')
end)

test('assert_type should recognize more than one type', function()
	local needs_string_or_number = function(v) return assert_type(v, 'string/number', 1) end
	local result = needs_string_or_number(1)
	test.assert_equal(result, 1)
end)

test('assert_type should allow a value to be optional', function()
	local optional_table = function(v) return assert_type(v, 'table/nil', 1) end
	local result = optional_table()
	test.assert_equal(result, nil)
end)

test('assert_type should consider an object with a __call metamethod to be a function', function()
	local needs_callable = function(f) return assert_type(f, 'function', 1) end
	local f = setmetatable({}, {__call = function() end})
	test.assert_equal(needs_callable(f), f)
end)

test('assert_type should raise an error if a type assertion fails', function()
	local needs_string = function(s) assert_type(s, 'string', 1) end
	test.assert_raises(function() needs_string(1) end,
		"bad argument #1 to 'needs_string' (string expected, got number")

	local optional_second_boolean = function(_, b) assert_type(b, 'boolean/nil', 2) end
	test.assert_raises(function() optional_second_boolean('', '') end,
		"bad argument #2 to 'optional_second_boolean' (boolean/nil expected, got string")
end)

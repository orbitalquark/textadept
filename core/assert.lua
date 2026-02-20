-- Copyright 2020-2026 Mitchell. See LICENSE.

--- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @module _G

--- Asserts a value is truthy or raises an error.
-- @param v Value to assert is not `false` or `nil`.
-- @param[opt='assertion failed!'] message Message to show on error. It need not be a string.
-- @param[optchain] ... If *message* is a format string, these arguments are passed to
--	`string.format()` and the result is the error message to show.
-- @return *v*
function assert(v, message, ...)
	if v then return v end
	if type(message) == 'string' and message:find('%%') then message = message:format(...) end
	error(message or 'assertion failed!', 2)
end

--- Asserts that a value has an expected type or raises an error.
-- Use this with API function arguments so users receive more helpful error messages.
-- @param v Value to assert the type of.
-- @param expected_type String type to assert. Multiple types are allowed, separated by
--	non-letter characters.
-- @param narg Positional argument number or string table field name associated with *v* . An
--	error message will reference this.
-- @usage assert_type(filename, 'string/nil', 1) -- assert first arg is optional string
-- @usage assert_type(option.setting, 'number', 'setting') -- assert 'setting' field is a number
-- @return *v*
function assert_type(v, expected_type, narg)
	if type(v) == expected_type then return v end
	-- Note: do not use assert for performance reasons (avoid constructing formatted strings).
	if type(expected_type) ~= 'string' then
		error(string.format("bad argument #2 to '%s' (string expected, got %s)",
			debug.getinfo(1, 'n').name, type(expected_type)), 2)
	elseif narg == nil then
		error(string.format("bad argument #3 to '%s' (value expected, got %s)",
			debug.getinfo(1, 'n').name, type(narg)), 2)
	end
	for type_option in expected_type:gmatch('%a+') do
		if type(v) == type_option then return v end
		if type_option == 'function' and getmetatable(v) and getmetatable(v).__call then return v end
	end
	error(string.format("bad argument #%s to '%s' (%s expected, got %s)", narg,
		debug.getinfo(2, 'n').name or '?', expected_type, type(v)), 3)
end

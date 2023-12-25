-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @module _G

--- Asserts that value *v* is not `false` or `nil` and returns *v*, or calls `error()` with
-- *message* as the error message, defaulting to "assertion failed!".
-- If *message* is a format string, the remaining arguments are passed to `string.format()`
-- and the resulting string becomes the error message.
-- @param v Value to assert.
-- @param[opt='assertion failed!'] message Optional error message to show on error.
-- @param[optchain] ... If *message* is a format string, these arguments are passed to
--	`string.format()`.
function assert(v, message, ...)
	if v then return v end
	if type(message) == 'string' and message:find('%%') then message = string.format(message, ...) end
	error(message or 'assertion failed!', 2)
end

--- Asserts that value *v* has type string *expected_type* and returns *v*, or calls `error()`
-- with an error message that implicates function argument number *narg*.
-- This is intended to be used with API function arguments so users receive more helpful error
-- messages.
-- @param v Value to assert the type of.
-- @param expected_type String type to assert. It may be a non-letter-delimited list of type
--	options.
-- @param narg The positional argument number *v* is associated with. This is not required to
--	be a number.
-- @usage assert_type(filename, 'string/nil', 1)
-- @usage assert_type(option.setting, 'number', 'setting') -- implicates key
function assert_type(v, expected_type, narg)
	if type(v) == expected_type then return v end
	-- Note: do not use assert for performance reasons.
	if type(expected_type) ~= 'string' then
		error(string.format("bad argument #2 to '%s' (string expected, got %s)",
			debug.getinfo(1, 'n').name, type(expected_type)), 2)
	elseif narg == nil then
		error(string.format("bad argument #3 to '%s' (value expected, got %s)",
			debug.getinfo(1, 'n').name, type(narg)), 2)
	end
	for type_option in expected_type:gmatch('%a+') do if type(v) == type_option then return v end end
	error(string.format("bad argument #%s to '%s' (%s expected, got %s)", narg,
		debug.getinfo(2, 'n').name or '?', expected_type, type(v)), 3)
end

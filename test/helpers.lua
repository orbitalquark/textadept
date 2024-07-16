-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Unit test helper methods.
-- @module test
local M = {}

--- Asserts that value *v* is not `false` or `nil` and returns *v*, or calls `error()` with
-- *message* as the error message, defaulting to "assertion failed!".
-- If *message* is a format string, the remaining arguments are passed to `string.format()`
-- and the resulting string becomes the error message.
-- @param v Value to assert.
-- @param[opt='assertion failed!'] message Optional error message to show on error.
-- @param[optchain] ... If *message* is a format string, these arguments are passed to
--	`string.format()`.
-- @function assert
M.assert = assert

--- Asserts that values *v1* and *v2* are equal.
-- Tables are compared by value, not by reference.
-- @param v1 Value to compare.
-- @param v2 Other value to compare.
function M.assert_equal(v1, v2)
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
function M.assert_raises(f, expected_errmsg)
	local ok, errmsg = pcall(assert_type(f, 'function', 1))
	if ok then error('error expected', 2) end
	if expected_errmsg ~= errmsg and not tostring(errmsg):find(expected_errmsg, 1, true) then
		error(string.format('error message %q expected, was %q', expected_errmsg, errmsg), 2)
	end
end

--- Logs string *message* to the current test's log.
-- If a test errors, its test log will be displayed.
-- @param message String message to log.
-- @function log
M.log = setmetatable({clear = function(self) for i = 1, #self do self[i] = nil end end}, {
	__call = function(self, message) self[#self + 1] = assert_type(message, 'string', 1) end
})

--- Returns a callable stub that tracks whether (or how many multiple times) it has been called,
-- and with what arguments it was called with; it returns value *ret* when called.
-- The returned stub has the following fields:
--
-- - `called`: Either a flag that indicates whether or not the stub has been called, or the
-- 	number of times it has been called if it is more than 1.
-- - `args`: Table of arguments from the most recent call, or `nil` if it has not been called.
-- - `reset`: Function to reset the `called` and `args` fields to their initial values.
-- @param[opt] ret Value to return when called. The default value is `nil`.
-- @return callable stub
-- @usage local f = stub()
-- @usage assert(f.called)
-- @usage f:reset()
function M.stub(ret)
	return setmetatable({
		called = false, reset = function(self) self.called, self.args = false, nil end
	}, {
		__call = function(self, ...)
			self.called = type(self.called) == 'number' and self.called + 1 or self.called and 2 or true
			self.args = {...}
			return ret
		end
	})
end

--- Returns the filename *filename* with directory separators matching the current platform.
-- This is only needed for filename comparisons. Filenames passed to functions like
-- `io.open_file()` do not need to be converted if no later filename tests are performed.
-- @param filename Filename to normalize.
function M.file(filename) return not WIN32 and filename or filename:gsub('/', '\\') end

--- Sleeps for *n* number of seconds.
-- On Windows this has to be an integer so *n* is rounded up as necessary.
-- @param n Number of seconds to sleep for.
function M.sleep(n)
	if WIN32 then n = math.ceil(n) end
	os.execute(not WIN32 and 'sleep ' .. n or 'timeout /T ' .. n)
end

--- Returns a to-be-closed value will call function *f* when the that value goes out of scope.
-- @usage local _<close> = defer(function() ... end)
function M.defer(f) return setmetatable({}, {__close = assert_type(f, 'function', 1)}) end

--- Creates a temporary file (with optional extension *ext*) and returns its filename along
-- with a to-be-closed value for deleting that file.
-- @param ext Optional file extension to use for the temporary file. The default is no file
--	extension.
-- @return filename, to-be-closed value
-- @usage local filename, _<close> = tempfile('.lua')
function M.tempfile(ext)
	local filename = os.tmpname()
	if assert_type(ext, 'string/nil', 1) then
		if not WIN32 then os.remove(filename) end
		filename = filename .. '.' .. ext
	end
	if WIN32 then io.open(filename, 'wb'):close() end -- create the file too, just like on Linux
	return filename, M.defer(function() os.remove(filename) end)
end

--- Creates a temporary directory (with optional structure table *structure*) and returns its
-- path along with a to-be-closed value for deleting that directory and all of its contents.
-- @param structure Optional directory structure for the temporary directory. Folder names are
--	keys assigned to table subdirectories. Filenames are string values. The default is an
--	empty directory.
-- @return path, to-be-closed value
-- @usage local dir, _<close> = tempdir{foo = {'bar.lua'}, 'baz.txt'}
function M.tempdir(structure)
	local dir = os.tmpname()
	if not WIN32 then os.remove(dir) end

	local function mkdir(root, structure)
		lfs.mkdir(root)
		for k, v in pairs(structure) do
			if type(v) == 'table' then
				mkdir(root .. '/' .. k, v)
			else
				io.open(root .. '/' .. v, 'wb'):close()
			end
		end
	end

	mkdir(dir, assert_type(structure, 'table/nil', 1) or {})
	return dir, M.defer(function() os.execute((not WIN32 and 'rm -r ' or 'rmdir /Q ') .. dir) end)
end

--- Connects function *f* to event *event* at index *index* and returns a to-be-closed value
-- that disconnects *f* from *event*.
-- @see events.connect
-- @return to-be-closed value
-- @usage local _<close> = connect(event, f)
function M.connect(event, f, index)
	events.connect(event, f, index)
	return M.defer(function() events.disconnect(event, f) end)
end

--- Repeatedly calls function *condition* until it either returns a truthy value, or a timeout
-- of *timeout* seconds is reached.
-- If *condition* succeeds, returns its value. Otherwise raises an error on timeout.
-- @param condition Function to call.
-- @param timeout Number of seconds to wait before timing out. The default value is 1.
-- @return value returned by *condition* unless there was a timeout
-- @usage assert(wait(function() return f.called end), 'should have called f')
function M.wait(condition, timeout)
	assert_type(condition, 'function', 1)
	local interval = not WIN32 and 0.1 or 1
	for i = 1, (assert_type(timeout, 'number/nil', 2) or 1) // interval do
		M.sleep(interval)
		ui.update()
		local result = condition()
		if result then return result end
	end
	error('timed out waiting', 2)
end

--- Removes directory *dir* and its contents.
function M.removedir(dir) os.execute((not WIN32 and 'rm -r ' or 'rmdir /Q') .. dir) end

local newlines = ({[buffer.EOL_LF] = '\n', [buffer.EOL_CRLF] = '\r\n'})
--- Returns a string containing a single newline depending on the current buffer EOL mode.
function M.newline() return newlines[buffer.eol_mode] end

return M

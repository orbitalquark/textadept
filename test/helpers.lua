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

--- Asserts that string or list *subject* contains value *find*.
-- @param subject Container to search.
-- @param find Value to search for.
function M.assert_contains(subject, find)
	assert_type(subject, 'string/table', 1)
	if type(subject) == 'string' then
		if subject:find(find) then return end
		error(string.format("'%s' was not found in '%s'", find, subject), 2)
	else
		if subject[find] then return end
		for _, value in ipairs(subject) do if value == find then return end end
		error(string.format("'%s' was not found in {%s}", find, table.concat(subject, ',')), 2)
	end
end

--- Logs the given arguments to the current test's log.
-- If a test errors, its test log will be displayed.
-- @param ... Arguments to log. Tables have their contents logged (non-recursively).
-- @function log
M.log = setmetatable({clear = function(self) for i = 1, #self do self[i] = nil end end}, {
	__call = function(self, ...)
		local args = {}
		for _, arg in pairs{...} do
			if type(arg) == 'table' then
				local kvs = {}
				for k, v in pairs(arg) do kvs[#kvs] = tostring(k) .. ' = ' .. tostring(v) end
				arg = '{' .. table.concat(kvs) .. '}'
			end
			args[#args + 1] = tostring(arg)
		end
		self[#self + 1] = table.concat(args)
	end
})

--- Returns whether or not the given value is callable, that is, whether or not it is a function
-- or a table with a `__call` metamethod.
local function is_callable(f)
	return type(f) == 'function' or getmetatable(f) and getmetatable(f).__call
end

--- Returns a callable stub that tracks whether (or how many multiple times) it has been called,
-- and with what arguments it was called with; it returns any given values it was originally
-- given when called.
-- If function *callback* is given, calls it when the stub is called.
-- The returned stub has the following fields:
--
-- - `called`: Either a flag that indicates whether or not the stub has been called, or the
-- 	number of times it has been called if it is more than 1.
-- - `args`: Table of arguments from the most recent call, or `nil` if it has not been called.
-- @param[opt] callback Optional callback to call when the stub is called.
-- @param[opt] ... Optional values to return when called. The default value is `nil`.
-- @return callable stub
-- @usage local f = stub()
-- @usage assert(f.called)
function M.stub(callback, ...)
	local returns = {...}
	if not is_callable(callback) then
		table.insert(returns, 1, callback)
		callback = nil
	end
	return setmetatable({called = false}, {
		__call = function(self, ...)
			self.called = type(self.called) == 'number' and self.called + 1 or self.called and 2 or true
			self.args = {...}
			if callback then callback(...) end
			return table.unpack(returns)
		end
	})
end

--- Returns a to-be-closed value will call function *f* when the that value goes out of scope.
-- @usage local _<close> = defer(function() ... end)
function M.defer(f) return setmetatable({}, {__close = assert_type(f, 'function', 1)}) end

--- A temporary file
-- @field filename The file's filename.
local tmpfile = {}
tmpfile.__index = tmpfile

--- Creates a new temporary file object.
-- @param filename String existing filename to assume control over.
function tmpfile.new(filename)
	return setmetatable({filename = assert_type(filename, 'string', 1)}, tmpfile)
end

--- Returns the contents of this temporary file on disk.
function tmpfile:read()
	local f<close> = io.open(self.filename)
	return f:read('a')
end

--- Writes the contents of this temporary file to disk.
function tmpfile:write(...) io.open(self.filename, 'wb'):write(...):close() end

--- Deletes this temporary file from disk.
function tmpfile:delete() os.remove(self.filename) end

--- To-be-closed method for deleting this temporary file from disk.
function tmpfile:__close() self:delete() end

--- Creates a temporary file (with optional extension *ext* and *contents*), optionally opens
-- it if *open* is `true`, and returns it as a to-be-closed value for deleting that file.
-- It has a `filename` field that contains its full filename, and `read()` and `write()` methods.
-- @param[opt] ext Optional file extension to use for the temporary file. The default is no file
--	extension.
-- @param[opt] contents Optional contents of the temporary file. The default is an empty file.
-- @param[opt] open Optional flag that indicates whether or not to open the temporary file.
-- @return to-be-closed temporary file
-- @usage local f<close> = tmpfile('.lua')
function M.tmpfile(ext, contents, open)
	assert_type(ext, 'string/boolean/nil', 1)
	assert_type(contents, 'string/boolean/nil', 2)
	if type(ext) == 'string' then
		if not ext:find('^%.') then
			ext, contents, open = nil, ext, contents
		elseif type(contents) ~= 'string' then
			contents, open = nil, contents
		end
	else
		ext, contents, open = nil, nil, ext
	end

	local filename = os.tmpname()
	if WIN32 and not ext and filename:find('%.') then ext = '.txt' end -- avoid unexpected detections
	if ext then
		if not WIN32 then os.remove(filename) end
		filename = filename .. ext
		io.open(filename, 'w'):close()
	end
	if OSX then filename = '/private' .. filename end

	local f = tmpfile.new(filename)
	if contents or WIN32 then f:write(contents or '') end

	if open then io.open_file(f.filename) end

	return f
end

--- Recursively creates a directory at *root* with the given structure.
local function mkdir(root, structure)
	lfs.mkdir(root)
	for k, v in pairs(structure) do
		if type(v) == 'table' then
			mkdir(root .. '/' .. k, v)
		elseif type(k) == 'string' then
			io.open(root .. '/' .. k, 'wb'):write(v):close()
		else
			io.open(root .. '/' .. v, 'w'):close()
		end
	end
end

--- A temporary directory.
-- @field dirname The directory's name.
local tmpdir = {}
tmpdir.__index = tmpdir

--- Creates a new temporary directory object.
-- @param dirname String existing directory name to assume control over.
function tmpdir.new(dirname)
	return setmetatable({dirname = assert_type(dirname, 'string', 1)}, tmpdir)
end

--- Changes the current working directory to this directory.
-- When the directory is deleted, the original working directory is restored.
function tmpdir:cd()
	self.oldwd = lfs.currentdir()
	lfs.chdir(self.dirname)
end

--- Returns a canonical path for this directory and a relative path.
-- The returned path respects directory separators on the current platform.
-- @usage filename = dir / file
function tmpdir:__div(path) return lfs.abspath(path, self.dirname) end

--- Deletes this temporary directory and all contents from disk.
function tmpdir:__close()
	if self.oldwd then lfs.chdir(self.oldwd) end
	os.execute((not WIN32 and 'rm -r ' or 'rmdir /S /Q ') .. self.dirname)
end

--- Creates a temporary directory (with optional structure table *structure*), optionally changes
-- to it if *chdir* is `true`, and returns its path along with a to-be-closed value for deleting
-- that directory and all of its contents, and changing back to the original directory.
-- @param[opt] structure Optional directory structure for the temporary directory. Folder names
--	are keys assigned to table subdirectories. Filenames are string values. The default is
--	an empty directory.
-- @param[opt] chdir Optional flag that indicates whether or not to change the current working
--	directory to the temporary directory. The default value is `false`.
-- @return to-be-closed temporary directory
-- @usage local dir<close> = tmpdir{foo = {'bar.lua'}, 'baz.txt'}
function M.tmpdir(structure, chdir)
	local dirname = os.tmpname()
	if not WIN32 then os.remove(dirname) end
	if OSX then dirname = '/private' .. dirname end

	if type(structure) == 'boolean' then structure, chdir = nil, structure end
	mkdir(dirname, assert_type(structure, 'table/nil', 1) or {})

	local dir = tmpdir.new(dirname)

	if chdir then dir:cd() end

	return dir
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

--- Mocks the value assigned to string *name* in module *module* (`module.name`) with *mock*,
-- and returns a to-be-closed value that restores the original value.
-- If *mock* is a function, it can be conditionally called depending on the return value of
-- optional function *condition*.
-- @param module Table module to mock inside of.
-- @param name String field name in *module* to mock.
-- @param[opt] condition Optional function that returns whether or not a mock function will
--	be called (if it is not called, the original function is). If omitted, the mock will
--	always be used, regardless of whether or not it is a function.
-- @param mock Value to replace `module.name` with.
-- @return to-be-closed value
-- @usage local _<close> = mock(module, 'name', function() return ... end)
function M.mock(module, name, condition, mock)
	assert_type(module, 'table', 1)
	assert_type(name, 'string', 2)
	if mock ~= nil then
		assert_type(condition, 'function', 3)
	else
		condition, mock = nil, condition
	end

	local original_value = module[name]
	if is_callable(mock) then
		module[name] = function(...)
			if not condition or condition(...) then return mock(...) end
			if is_callable(original_value) then return original_value(...) end
			return original_value
		end
	else
		module[name] = mock
	end

	return M.defer(function() module[name] = original_value end)
end

--- Sleep for *n* seconds.
-- @param n Number of seconds to sleep for. It may be fractional.
local function sleep(n) os.execute((not WIN32 and 'sleep ' or 'timeout /T ') .. n) end
local have_sleep = pcall(require, 'debugger')
if have_sleep then sleep = require('debugger').socket.sleep end

--- Repeatedly calls function *condition* until it either returns a truthy value, or a timeout
-- of *timeout* seconds is reached.
-- If *condition* succeeds, returns its value. Otherwise raises an error on timeout.
-- @param condition Function to call.
-- @param timeout Number of seconds to wait before timing out. The default value is 1.
-- @return value returned by *condition* unless there was a timeout
-- @usage wait(function() return f.called end)
function M.wait(condition, timeout)
	assert_type(condition, 'function', 1)
	if not assert_type(timeout, 'number/nil', 2) then timeout = (have_sleep or not WIN32) and 1 or 2 end
	local interval = (have_sleep or not WIN32) and 0.1 or 1
	for i = 1, timeout // interval do
		sleep(interval)
		ui.update()
		local result = condition()
		if result then return result end
	end
	error('timed out waiting', 2)
end

local newlines = ({[buffer.EOL_LF] = '\n', [buffer.EOL_CRLF] = '\r\n'})
--- Returns *lines* number of lines, or table of lines *lines*, separated by newlines depending
-- on the current buffer EOL mode.
-- Unless *blank* is `false`, the return list of lines is enumerated starting from 1.
-- @param lines Number of lines to produce or table of lines to use.
-- @param blank Optional flag that indicates whether or not to output blank lines. When `false`,
--	lines are enumerated starting from 1. The default value is `false`.
-- @return string
function M.lines(lines, blank)
	if type(assert_type(lines, 'number/table', 1)) == 'number' then
		local t = {}
		for i = 1, lines do t[#t + 1] = not blank and tostring(i) or '' end
		lines = t
	end
	return table.concat(lines, newlines[buffer.eol_mode])
end

--- Emulates typing the given key or text.
function M.type(text)
	if text:find('^ctrl%+') or text:find('^alt%+') or text:find('^meta%+') or text:find('^cmd%+') or
		text:find('^shift%+') then
		M.log('emitting keypress: ', text)
		events.emit(events.KEYPRESS, text)
		return
	elseif text ~= '\n' then
		for _, v in pairs(keys.KEYSYMS) do
			if v == text then
				M.log('emitting keypress: ', text)
				events.emit(events.KEYPRESS, text)
				return
			end
		end
	end

	local buffer = not ui.command_entry.active and buffer or ui.command_entry

	for _, code in utf8.codes(text) do
		local char = utf8.char(code)
		if ui.find.active then
			if char == '\n' then
				M.log('calling ui.find.find_next')
				ui.find.find_next()
			else
				if char == '\b' then
					ui.find.find_entry_text = ui.find.find_entry_text:sub(1, -2)
				else
					ui.find.find_entry_text = ui.find.find_entry_text .. char
				end
				M.log('ui.find.find_entry_text = ', ui.find.find_entry_text)
				if CURSES then events.emit(events.FIND_TEXT_CHANGED) end
			end
			goto continue
		end

		if events.emit(events.KEYPRESS, char) then goto continue end
		if char == '\n' and buffer.eol_mode == buffer.EOL_CRLF then char = '\r\n' end

		buffer:begin_undo_action()
		for i = 1, buffer.selections do
			if buffer.selections > 1 then
				local pos = buffer.selection_n_start[i]
				buffer:set_target_range(pos, buffer.selection_n_end[i])
				buffer:replace_target(char)
				buffer.selection_n_anchor[i] = pos + #char
				buffer.selection_n_caret[i] = pos + #char
			elseif not buffer.selection_empty then
				buffer:replace_sel(char)
			else
				buffer:add_text(char)
			end
		end
		buffer:end_undo_action()
		events.emit(events.CHAR_ADDED, code)

		::continue::
		ui.update() -- emit events.UPDATE_UI
		if CURSES then events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT | buffer.UPDATE_SELECTION) end
	end

end

--- Returns a list of all line numbers with marker number *marker* set.
-- @param marker Marker number to get lines for.
-- @param[opt] buffer Buffer to get markers from. The default value is the global buffer.
-- @return line number list
function M.get_marked_lines(marker, buffer)
	if not buffer then buffer = _G.buffer end
	local lines = {}
	for i = 1, buffer.line_count do
		if buffer:marker_get(i) & 1 << marker - 1 > 0 then lines[#lines + 1] = i end
	end
	return lines
end

--- Returns a list of all text segments with indicator number *indic* set.
-- The returned list contains only strings, not position information.
-- @param indic Indicator number to get segments for.
-- @param[opt] buffer Buffer to get segments from. The default value is the global buffer.
-- @return string list
function M.get_indicated_text(indic, buffer)
	if not buffer then buffer = _G.buffer end
	local words = {}
	local s = buffer:indicator_all_on_for(1) & 1 << indic - 1 > 0 and 1 or
		buffer:indicator_end(indic, 1)
	while true do
		local e = buffer:indicator_end(indic, s)
		if e == 1 or e == s then break end
		words[#words + 1] = buffer:text_range(s, e)
		s = buffer:indicator_end(indic, e)
	end
	return words
end

return M

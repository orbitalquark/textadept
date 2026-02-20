-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Processes command line arguments for Textadept.
-- You can register your own command line arguments. For example:
--
-- ```lua
-- args.register('-r', '--read-only', 0, function()
-- 	events.connect(events.FILE_OPENED, function()
-- 		buffer.read_only = true -- make all opened buffers read-only
-- 	end)
-- 	textadept.menu.menubar = nil -- hide the menubar
-- end, "Read-only mode")
-- ```
--
-- Running `textadept -r file.txt` will open that and all subsequent files in read-only mode.
-- @module args
local M = {}

--- Emitted when no filename or directory command line arguments are passed to Textadept on startup.
_G.events.ARG_NONE = 'arg_none'

--- Map of registered command line options.
local options = {}

--- Registers a command line option.
-- @param short String short version of the option.
-- @param long String long version of the option.
-- @param narg Number of expected parameters for the option.
-- @param f Function to run when the option is set. It is passed *narg* string arguments. If *f*
--	returns `true`, `events.ARG_NONE` will ultimately not be emitted.
-- @param description String description of the option shown in command line help.
-- @usage args.register('-r', '--read-only', 0, function() ... end, 'Read-only mode')
function M.register(short, long, narg, f, description)
	local option = {
		narg = assert_type(narg, 'number', 3), f = assert_type(f, 'function', 4),
		description = assert_type(description, 'string', 5)
	}
	options[assert_type(short, 'string', 1)] = option
	options[assert_type(long, 'string', 2)] = option
end

--- Processes command line arguments.
-- It handles options previously defined using `args.register()` and treats unrecognized
-- arguments as filenames to open or directories to change to.
-- @param arg Argument table.
-- @param[opt=false] no_emit_arg_none When `true`, do not emit `ARG_NONE` when no file or
--	directory arguments are present.
local function process(arg, no_emit_arg_none)
	local no_args = true
	local i = 1
	while i <= #arg do
		local option = options[arg[i]]
		if option then
			if option.f(table.unpack(arg, i + 1, i + option.narg)) then no_args = false end
			i = i + option.narg
		else
			local filename = lfs.abspath(arg[i], arg[-1] or lfs.currentdir())
			local f = lfs.attributes(filename, 'mode') ~= 'directory' and io.open_file or lfs.chdir
			f(filename)
			no_args = false
		end
		i = i + 1
	end
	if no_args and not no_emit_arg_none then events.emit(events.ARG_NONE) end
end
events.connect(events.INITIALIZED, function() if arg then process(arg) end end)
-- Undocumented, single-instance event handler for forwarding arguments.
events.connect('command_line', function(arg) process(arg, true) end)

-- Set `_G._USERHOME`.
-- This needs to be set as soon as possible since the processing of arguments is positional.

--- The path to the user's *~/.textadept/* directory, where all preferences and user-data is stored.
-- On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
-- *C:\Users\username\\*). On macOS and Linux/BSD machines *~/* is the value of "$HOME"
-- (typically */Users/username/* and */home/username/*, respectively).
_G._USERHOME = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE') .. '/.textadept'
for i, option in ipairs(arg) do
	if (option == '-u' or option == '--userhome') and arg[i + 1] then
		_USERHOME = arg[i + 1]
		break
	elseif option == '-t' or option == '--test' then
		-- Run unit tests using a temporary _USERHOME, which will ultimately be deleted.
		_USERHOME = os.tmpname()
		if not WIN32 then os.remove(_USERHOME) end -- created as a file on *nix
		break
	end
end
local mode = lfs.attributes(_USERHOME, 'mode')
assert(not mode or mode == 'directory', '"%s" is not a directory', _USERHOME)
if not mode then assert(lfs.mkdir(_USERHOME), 'cannot create "%s"', _USERHOME) end
local user_init = _USERHOME .. '/init.lua'
mode = lfs.attributes(user_init, 'mode')
assert(not mode or mode == 'file', '"%s" is not a file (%s)', user_init, mode)
if not mode then assert(io.open(user_init, 'w'), 'unable to create "%s"', user_init):close() end

-- Placeholders.
M.register('-u', '--userhome', 1, function() end, 'Sets alternate _USERHOME')
M.register('-f', '--force', 0, function() end, 'Forces unique instance')
M.register('-p', '--preserve', 0, function() end, 'Preserve ^Q (XON) and ^S (XOFF) flow control')
M.register('-L', '--lua', 1, function() end, 'Runs the given file as a Lua script and exits')
M.register('-T', '--cov', 0, function() end, 'Runs unit tests with code coverage')

-- Shows all registered command line options on the command line.
M.register('-h', '--help', 0, function()
	if CURSES then return end -- not supported
	print('Usage: textadept [args] [filenames]')
	local list = {}
	for name in pairs(options) do list[#list + 1] = name end
	table.sort(list, function(a, b) return a:match('^%-*(.*)$') < b:match('^%-*(.*)$') end)
	for _, name in ipairs(list) do
		local option = options[name]
		print(string.format('  %s [%d arg(s)]: %s', name, option.narg, option.description))
	end
	timeout(0.01, quit, 0, false)
	return true
end, 'Shows this')

-- Shows Textadept version and copyright on the command line.
M.register('-v', '--version', 0, function()
	if CURSES then return end -- not supported
	print(_RELEASE .. '\n' .. _COPYRIGHT)
	timeout(0.01, quit, 0, false)
	return true
end, 'Prints Textadept version and copyright')

-- After Textadept finishes initializing and processes arguments, remove some options in order
-- to prevent another instance from quitting the first one.
local function remove_options_that_quit()
	for _, opt in ipairs{'-h', '--help', '-v', '--version', '-t', '--test'} do options[opt] = nil end
end
events.connect(events.INITIALIZED, remove_options_that_quit)

-- Run unit tests.
-- Note: have them run after the last `events.INITIALIZED` handler so everything is completely
-- initialized (e.g. menus, macro module, etc.).
M.register('-t', '--test', 1, function(tags)
	events.disconnect(events.INITIALIZED, remove_options_that_quit) -- allow unit tests for these

	events.connect(events.INITIALIZED, function()
		local arg = {}
		if tags then for tag in tags:gmatch('[^,]+') do arg[#arg + 1] = tag end end
		assert(loadfile(_HOME .. '/test/test.lua', 't', setmetatable({arg = arg}, {__index = _G})))()
	end)

	-- Remove temporary _USERHOME on quit.
	events.connect(events.QUIT, function()
		local info = debug.getinfo(4)
		if GTK and info then return end -- ignore simulated quit event
		if info and info.name ~= 'quit' then return end -- ignore simulated quit event
		os.execute(string.format('%s "%s"', not WIN32 and 'rm -r' or 'rmdir /S /Q', _USERHOME))
	end)

	return true
end, 'Runs unit tests indicated by comma-separated list of tags (or all tests)')

return M

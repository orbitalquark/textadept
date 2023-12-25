-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Processes command line arguments for Textadept.
-- @module args
local M = {}

--- Emitted when no filename or directory command line arguments are passed to Textadept on startup.
_G.events.ARG_NONE = 'arg_none'

--- Map of registered command line options.
local options = {}

--- Registers a command line option with short and long versions *short* and *long*, respectively.
-- *narg* is the number of arguments the option accepts, *f* is the function called when the
-- option is set, and *description* is the option's description when displaying help.
-- Normally, options are not considered command line arguments, so they do not prevent
-- `events.ARG_NONE` from being emitted. However, if *f* returns `true`, this option counts as
-- an argment and it will prevent `events.ARG_NONE` from being emitted.
-- @param short The string short version of the option.
-- @param long The string long version of the option.
-- @param narg The number of expected parameters for the option.
-- @param f The Lua function to run when the option is set. It is passed *narg* string arguments.
-- @param description The string description of the option for command line help.
function M.register(short, long, narg, f, description)
	local option = {
		narg = assert_type(narg, 'number', 3), f = assert_type(f, 'function', 4),
		description = assert_type(description, 'string', 5)
	}
	options[assert_type(short, 'string', 1)] = option
	options[assert_type(long, 'string', 2)] = option
end

--- Processes command line argument table *arg*, handling options previously defined using
-- `args.register()` and treats unrecognized arguments as filenames to open or directories to
-- change to.
-- Emits `events.ARG_NONE` when no file or directory arguments are present unless
-- *no_emit_arg_none* is `true`.
-- @param arg Argument table.
-- @param[opt=false] no_emit_arg_none When `true`, do not emit `ARG_NONE` when no arguments
--	are present.
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
			if lfs.attributes(filename, 'mode') ~= 'directory' then
				io.open_file(filename)
			else
				lfs.chdir(filename)
			end
			no_args = false
		end
		i = i + 1
	end
	if no_args and not no_emit_arg_none then events.emit(events.ARG_NONE) end
end
events.connect(events.INITIALIZED, function() if arg then process(arg) end end)
-- Undocumented, single-instance event handler for forwarding arguments.
events.connect('command_line', function(arg) process(arg, true) end)

if not CURSES then
	-- Shows all registered command line options on the command line.
	M.register('-h', '--help', 0, function()
		print('Usage: textadept [args] [filenames]')
		local list = {}
		for name in pairs(options) do list[#list + 1] = name end
		table.sort(list, function(a, b) return a:match('^%-*(.*)$') < b:match('^%-*(.*)$') end)
		for _, name in ipairs(list) do
			local option = options[name]
			print(string.format('  %s [%d args]: %s', name, option.narg, option.description))
		end
		os.exit()
	end, 'Shows this')
	-- Shows Textadept version and copyright on the command line.
	M.register('-v', '--version', 0, function()
		print(_RELEASE .. '\n' .. _COPYRIGHT)
		os.exit()
	end, 'Prints Textadept version and copyright')
	-- After Textadept finishes initializing and processes arguments, remove the help and
	-- version options in order to prevent another instance from sending '-h', '--help', '-v',
	-- and '--version' to the first instance, killing the latter.
	events.connect(events.INITIALIZED, function()
		options['-h'], options['--help'] = nil, nil
		options['-v'], options['--version'] = nil, nil
	end)
end

-- Set `_G._USERHOME`.
-- This needs to be set as soon as possible since the processing of arguments is positional.

---
-- The path to the user's *~/.textadept/* directory, where all preferences and user-data is stored.
-- On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
-- *C:\Users\username\\* or *C:\Documents and Settings\username\\*). On Linux and macOS machines
-- *~/* is the value of "$HOME" (typically */home/username/* and */Users/username/* respectively).
_G._USERHOME = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE') .. '/.textadept'
for i, option in ipairs(arg) do
	if (option == '-u' or option == '--userhome') and arg[i + 1] then
		_USERHOME = arg[i + 1]
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

-- Run unit tests.
-- Note: have them run after the last `events.INITIALIZED` handler so everything is completely
-- initialized (e.g. menus, macro module, etc.).
M.register('-t', '--test', 1, function(patterns)
	events.connect(events.INITIALIZED, function()
		local arg = {}
		for patt in (patterns or ''):gmatch('[^,]+') do arg[#arg + 1] = patt end
		local env = setmetatable({arg = arg}, {__index = _G})
		assert(loadfile(_HOME .. '/test/test.lua', 't', env))()
	end)
end, 'Runs unit tests indicated by comma-separated list of patterns (or all)')

return M

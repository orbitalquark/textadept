-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @module _G

--- The Textadept release version string.
_RELEASE = 'Textadept 12.4'
--- Textadept's copyright information.
_COPYRIGHT = 'Copyright © 2007-2024 Mitchell. See LICENSE.\n' ..
	'https://orbitalquark.github.io/textadept'

package.path = string.format('%s/core/?.lua;%s', _HOME, package.path)

-- for _, arg in ipairs(arg) do if arg == '-t' or arg == '--test' then pcall(require, 'luacov') end end

require('assert')
_SCINTILLA = require('iface')
events = require('events')
args = require('args')
_L = require('locale')
require('file_io')
lexer = require('lexer')
require('lfs_ext')
require('ui')
keys = require('keys')

-- pdcurses compatibility.
if CURSES and WIN32 then
	function os.spawn(cmd, ...)
		local cwd = lfs.currentdir()
		local args, i = {...}, 1
		if type(args[i]) == 'string' then
			lfs.chdir(args[i]) -- cwd
			i = i + 1
		end
		if type(args[i]) == 'table' then i = i + 1 end -- env (ignore)
		local p = io.popen(assert_type(cmd, 'string', 1) .. ' 2>&1')
		local output = p:read('a'):gsub('\r?\n', '\r\n') -- ensure \r\n
		if type(args[i]) == 'function' then args[i](output) end -- stdout_cb
		local status = select(3, p:close())
		if type(args[i + 2]) == 'function' then args[i + 2](status) end -- exit_cb
		lfs.chdir(cwd) -- restore
		local noop = function() end
		return {
			read = function() return output end, status = function() return 'terminated' end,
			wait = function() return status end, write = noop, close = noop, kill = noop
		}
	end
end

--- Replacement for original `buffer:text_range()`, which has a C struct for an argument.
-- Documentation is in core/.buffer.luadoc.
local function text_range(buffer, start_pos, end_pos)
	local target_start, target_end = buffer.target_start, buffer.target_end
	buffer:set_target_range(math.max(1, assert_type(start_pos, 'number', 2)),
		math.min(assert_type(end_pos, 'number', 3), buffer.length + 1))
	local text = buffer.target_text
	buffer:set_target_range(target_start, target_end) -- restore
	return text
end

events.connect(events.BUFFER_NEW, function() buffer.text_range = text_range end, 1)

--- A table of style properties that can be concatenated with other tables of properties.
local style_object = {}
style_object.__index = style_object

--- Creates a new style object.
-- @param props Table of style properties to use.
local function style_obj(props)
	local style = {}
	for k, v in pairs(props) do style[k] = v end
	return setmetatable(style, style_object)
end

--- Returns a new style object with a set of merged properties.
-- @param props Table of style properties to merge into this one.
-- @local
function style_object:__concat(props)
	local style = style_obj(self) -- copy
	for k, v in pairs(assert_type(props, 'table', 2)) do style[k] = v end
	return style
end

--- Looks up the style settings for a style number *style_num*, and applies them to view *view*.
-- @param view A view.
-- @param style_num Style number to set the style for.
local function set_style(view, style_num)
	local styles = buffer ~= ui.command_entry and view.styles or _G.view.styles
	local style = rawget(styles, style_num) or styles[buffer:name_of_style(style_num):gsub('%.', '_')]
	if style then for k, v in pairs(style) do view['style_' .. k][style_num] = v end end
end

-- Documentation is in core/.buffer.luadoc.
local function set_styles(view)
	if buffer == ui.command_entry then view = ui.command_entry end
	view:style_reset_default()
	set_style(view, view.STYLE_DEFAULT)
	view:style_clear_all()
	local num_styles, num_predefined = buffer.named_styles, 8 -- DEFAULT to FOLDDISPLAYTEXT
	for i = 1, math.max(num_styles - num_predefined, view.STYLE_DEFAULT - 1) do set_style(view, i) end
	for i = view.STYLE_DEFAULT + 1, view.STYLE_FOLDDISPLAYTEXT do set_style(view, i) end
	for i = view.STYLE_FOLDDISPLAYTEXT + 1, num_styles do set_style(view, i) end
end

-- Documentation is in core/.buffer.luadoc.
local function set_theme(view, name, env)
	if not name or type(name) == 'table' then name, env = _THEME, name end
	if not assert_type(name, 'string', 2):find('[/\\]') then
		name = package.searchpath(name,
			string.format('%s/themes/?.lua;%s/themes/?.lua', _USERHOME, _HOME))
	end
	if not name or not lfs.attributes(name) then return end
	if not assert_type(env, 'table/nil', 3) then env = {} end
	env.view = view
	for name in pairs(view.styles) do view.styles[name] = nil end -- reset
	assert(loadfile(name, 't', setmetatable(env, {__index = _G})))()
	view:set_styles()
end

--- Metatable for `view.styles`, whose documentation is in core/.buffer.luadoc.
local styles_mt = {
	__index = function(t, k) return k and t[k:match('^(.+)[_%.]')] or nil end,
	__newindex = function(t, k, v)
		rawset(t, type(k) == 'string' and k:gsub('%.', '_') or k, style_obj(assert_type(v, 'table', 3)))
	end
}

events.connect(events.VIEW_NEW, function()
	local view = buffer ~= ui.command_entry and view or ui.command_entry
	view.colors, view.styles = {}, setmetatable({}, styles_mt)
	view.set_styles, view.set_theme = set_styles, set_theme
end, 1)

--- The path to Textadept's home, or installation, directory.
-- @field _HOME

--- The filesystem's character encoding.
-- This is used when [working with files](#io).
-- @field _CHARSET

--- Whether or not Textadept is running on Windows.
-- @field WIN32

--- Whether or not Textadept is running on macOS.
-- @field OSX

--- Whether or not Textadept is running on Linux.
-- @field LINUX

--- Whether or not Textadept is running as a GTK GUI application.
-- @field GTK

--- Whether or not Textadept is running as a Qt GUI application.
-- @field QT

--- Whether or not Textadept is running in a terminal.
-- Curses feature incompatibilities are listed in the [Appendix][].
--
-- [Appendix]: manual.html#terminal-version-compatibility
-- @field CURSES

--- Textadept's current UI mode, either "light" or "dark".
-- Manually changing this field has no effect.
-- @field _THEME

-- The tables below were defined in C.

--- Table of command line parameters passed to Textadept.
-- @see args
-- @table arg

--- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric keys.
-- @usage _BUFFERS[n]      --> buffer at index n
-- @usage _BUFFERS[buffer] --> index of buffer in _BUFFERS
-- @see buffer
-- @table _BUFFERS

--- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric keys.
-- @usage _VIEWS[n]    --> view at index n
-- @usage _VIEWS[view] --> index of view in _VIEWS
-- @see view
-- @table _VIEWS

--- The current [buffer](#buffer) in the [current view](#_G.view).
-- @table buffer

--- The current [view](#view).
-- @table view

-- The functions below are Lua C functions.

--- Moves the buffer at index *from* to index *to* in the `_BUFFERS` table, shifting other buffers
-- as necessary.
-- This changes the order buffers are displayed in in the tab bar and buffer browser.
-- @param from Index of the buffer to move.
-- @param to Index to move the buffer to.
-- @function move_buffer

--- Emits `events.QUIT`, and unless any handler returns `false`, quits Textadept.
-- @function quit

--- Resets the Lua State by reloading all initialization scripts.
-- This function is useful for modifying user scripts (such as *~/.textadept/init.lua*) on the
-- fly without having to restart Textadept. `arg` is set to `nil` when reinitializing the Lua
-- State. Any scripts that need to differentiate between startup and reset can test `arg`.
-- @function reset

--- Calls function *f* with the given arguments after *interval* seconds.
-- If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long as *f* returns
-- `true`. A `nil` or `false` return value stops repetition.
-- @param interval The interval in seconds to call *f* after.
-- @param f The function to call.
-- @param[opt] ... Additional arguments to pass to *f*.
-- @function timeout

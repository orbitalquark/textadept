-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @module _G

for _, arg in ipairs(arg) do if arg == '-T' or arg == '--cov' then require('luacov') end end

--- The Textadept release version string.
_RELEASE = 'Textadept 13.0 alpha 2'
--- Textadept's copyright information.
_COPYRIGHT = 'Copyright © 2007-2026 Mitchell. See LICENSE.\n' ..
	'https://orbitalquark.github.io/textadept'

package.path = string.format('%s/core/?.lua;%s', _HOME, package.path)

require('assert')
_SCINTILLA = require('iface')
events = require('events')
args = require('args')
_L = require('locale')
lexer = require('lexer')
keys = require('keys')
for _, mod in ipairs{'buffer', 'file_io', 'lfs_ext', 'table_ext', 'ui', 'view'} do require(mod) end

-- The fields below were defined in C.

--- The path to Textadept's home, or installation, directory.
-- @field _HOME

--- The filesystem's character encoding.
-- This really only matters on Windows, where there is a mismatch between the UI encoding
-- (UTF-8), and the filesystem encoding (non-UTF-8).
-- @usage local utf8_filename = buffer.filename:iconv('UTF-8', _CHARSET)
-- @usage local f = io.open(utf8_filename:iconv(_CHARSET, 'UTF-8'))
-- @see string.iconv
-- @field _CHARSET

--- Whether or not Textadept is running on Windows.
-- @field WIN32

--- Whether or not Textadept is running on macOS.
-- @field OSX

--- Whether or not Textadept is running on Linux.
-- @field LINUX

--- Whether or not Textadept is running on BSD.
-- @field BSD

--- Whether or not Textadept is running as a GTK GUI application.
-- @field GTK

--- Whether or not Textadept is running as a Qt GUI application.
-- @field QT

--- Whether or not Textadept is running in a terminal.
-- @field CURSES

--- Textadept's current UI mode, either "light" or "dark".
-- Manually changing this field has no effect. It is used internally to set a theme on startup
-- based on the current OS theme.
-- @see view.set_theme
-- @see events.MODE_CHANGED
-- @field _THEME

-- The tables below were defined in C.

--- Table of command line parameters passed to Textadept, just like in Lua.
-- @see args
-- @table arg

--- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric keys as values.
-- @usage local buffer = _BUFFERS[n] -- buffer at index n
-- @usage local i = _BUFFERS[buffer] -- index of buffer in _BUFFERS
-- @see buffer
-- @table _BUFFERS

--- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric keys as values.
-- @usage local view = _VIEWS[n] -- view at index n
-- @usage local i = _VIEWS[view] -- index of view in _VIEWS
-- @see view
-- @table _VIEWS

--- The current [buffer](#the-buffer-module) in the [current view](#_G.view).
-- @table buffer

--- The current [view](#the-view-module).
-- @table view

-- The functions below are Lua C functions.

--- Moves buffers within the `_BUFFERS` table, changing their display order in the tab bar and
-- buffer browser.
-- @param from Index of the buffer to move.
-- @param to Index to move the buffer to.
-- @function move_buffer

--- Attempts to quit Textadept.
-- @param[opt=0] status Status code for Textadept to exit with.
-- @param[optchain=true] events Emit `events.QUIT`, which could prevent quitting. Passing
--	`false` could result in data loss.
-- @function quit

--- Resets Textadept's Lua State by reloading all initialization scripts.
-- This allows for testing theme and user script modifications (e.g. *~/.textadept/init.lua*)
-- without having to restart Textadept.
--
-- `arg` is `nil` during re-initialization. Scripts that need to differentiate between startup
-- and reset can test `arg`.
-- @see events.RESET_BEFORE
-- @see events.RESET_AFTER
-- @function reset

--- Calls a function after a timeout interval.
-- Terminal version note: timeout functions will not be called until an active Find & Replace
-- pane session finishes, or until an active dialog closes.
-- @param interval Interval in seconds to call *f* after.
-- @param f Function to call. If it returns `true`, it will be called again after *interval*
--	seconds.
-- @param[opt] ... Additional arguments to pass to *f*.
-- @function timeout

--- Returns whether or not Textadept is currently running on a HiDPI/Retina display.
-- @function is_hidpi

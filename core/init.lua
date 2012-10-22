-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

_RELEASE = "Textadept 6.0 beta 3"

package.path = _HOME..'/core/?.lua;'..package.path

if jit then require 'compat' end -- compatibility for LuaJIT
_SCINTILLA = require 'iface'
args = require 'args'
_L = require 'locale'
events = require 'events'
require 'file_io'
require 'gui'
keys = require 'keys'

_LEXERPATH = _USERHOME..'/lexers/?.lua;'.._HOME..'/lexers'

gui.set_theme()

_M = {} -- modules table

--[[ This comment is for LuaDoc.
---
-- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @field _HOME (string)
--   Path to the directory containing Textadept.
-- @field _LEXERPATH (string)
--   Paths to lexers, formatted like [`package.path`][].
--
--   [`package.path`]: http://lua.org/manual/5.2/manual.html#pdf-package.path
-- @field _RELEASE (string)
--   The Textadept release version.
-- @field _USERHOME (string)
--   Path to the user's `~/.textadept/`, where all preferences and user-data is
--   stored.
--   On Windows machines `~/` is the value of the `USERHOME` environment
--   variable, typically `C:\Users\<username>\` or
--   `C:\Documents and Settings\<username>\`. On Linux, BSD, and Mac OSX
--   machines `~/` is the value of `HOME`, typically `/home/<username>/` and
--   `/Users/<username>/` respectively.
-- @field _CHARSET (string)
--   The character set encoding of the filesystem.
--   This is used when [working with files](io.html).
-- @field RESETTING (bool)
--   If [`reset()`](#reset) has been called, this flag is `true` while the Lua
--   state is being re-initialized.
-- @field WIN32 (bool)
--   If Textadept is running on Windows, this flag is `true`.
-- @field OSX (bool)
--   If Textadept is running on Mac OSX, this flag is `true`.
-- @field NCURSES (bool)
--   If Textadept is running in the terminal, this flag is `true`.
--   ncurses feature incompatibilities are listed in the [Appendix][].
--
--   [Appendix]: ../14_Appendix.html#Ncurses.Compatibility
-- @field buffer The current [buffer][] in the current [view](#view).
--
-- [buffer]: buffer.html
-- @field view The currently focused [view](view.html).
module('_G')]]

--[[ The tables below were defined in C.

---
-- Command line parameters passed to Textadept.
-- @class table
-- @see _G.args
-- @name arg
local arg

---
-- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric
-- keys.
-- @class table
-- @usage _BUFFERS[1] contains the first buffer.
-- @usage _BUFFERS[buffer] returns the index of the current buffer in _BUFFERS.
-- @see _G.buffer
-- @name _BUFFERS
local _BUFFERS

---
-- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric
-- keys.
-- @class table
-- @usage _VIEWS[1] contains the first view.
-- @usage _VIEWS[view] returns the index of the current view in _VIEWS.
-- @see _G.view
-- @name _VIEWS
local _VIEWS

-- The functions below are Lua C functions.

---
-- Creates a new buffer.
-- Emits a `BUFFER_NEW` event.
-- @return the new buffer.
-- @class function
-- @see events.BUFFER_NEW
-- @name new_buffer
local new_buffer

---
-- Quits Textadept.
-- Emits a `QUIT` event. If any handler returns `false`, Textadept does not
-- quit.
-- @see events.QUIT
-- @class function
-- @name quit
local quit

---
-- Resets the Lua state by reloading all init scripts.
-- Language-specific modules for opened files are NOT reloaded. Re-opening the
-- files that use them will reload those modules instead.
-- This function is useful for modifying user scripts (such as
-- `~/.textadept/init.lua` and `~/.textadept/modules/textadept/keys.lua`) on
-- the fly without having to restart Textadept. `_G.RESETTING` is set to `true`
-- when re-initing the Lua State. Any scripts that need to differentiate between
-- startup and reset can utilize this variable.
-- @class function
-- @see RESETTING
-- @name reset
local reset

---
-- Calls a given function after an interval of time.
-- To repeatedly call the function, return `true` inside the function. A `nil`
-- or `false` return value stops repetition.
-- @param interval The interval in seconds to call the function after.
-- @param f The function to call.
-- @param ... Additional arguments to pass to `f`.
-- @class function
-- @name timeout
local timeout
]]

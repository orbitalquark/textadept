-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

_RELEASE = "Textadept 5.2"

package.path = _HOME..'/core/?.lua;'..package.path
os.setlocale('C', 'collate')

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
-- Extends Lua's _G table to provide extra functions and fields.
-- @field _HOME (string)
--   Path to the directory containing Textadept.
-- @field _LEXERPATH (string)
--   Paths to lexers, formatted like
--   [`package.path`](http://lua.org/manual/5.2/manual.html#pdf-package.path).
-- @field _RELEASE (string)
--   The Textadept release version.
-- @field _USERHOME (string)
--   Path to the user's `~/.textadept/`.
-- @field _CHARSET (string)
--   The character set encoding of the filesystem.
--   This is used in [File I/O](io.html).
-- @field RESETTING (bool)
--   If [`reset()`](#reset) has been called, this flag is `true` while the Lua
--   state is being re-initialized.
-- @field WIN32 (bool)
--   If Textadept is running on Windows, this flag is `true`.
-- @field OSX (bool)
--   If Textadept is running on Mac OSX, this flag is `true`.
module('_G')]]

---
-- Calls `dofile()` on the given filename in the user's Textadept directory.
-- Errors are printed to the Textadept message buffer.
-- @param filename The name of the file (not path).
-- @return `true` if successful; `false` otherwise.
-- @see dofile
function user_dofile(filename)
  if not lfs.attributes(_USERHOME..'/'..filename) then return false end
  local ok, err = pcall(dofile, _USERHOME..'/'..filename)
  if not ok then gui.print(err) end
  return ok
end

--[[ The tables below were defined in C.

---
-- Command line parameters.
-- @class table
-- @name arg
local arg

---
-- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric
-- keys.
-- @class table
-- @name _BUFFERS
-- @usage _BUFFERS[1] contains the first buffer.
-- @usage _BUFFERS[buffer] returns the index of the current buffer in _BUFFERS.
local _BUFFERS

---
-- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric
-- keys.
-- @class table
-- @name _VIEWS
-- @usage _VIEWS[1] contains the first view.
-- @usage _VIEWS[view] returns the index of the current view in _VIEWS.
local _VIEWS

-- The functions below are Lua C functions.

---
-- Creates a new buffer.
-- Generates a `BUFFER_NEW` event.
-- @return the new buffer.
-- @class function
-- @name new_buffer
local new_buffer

---
-- Quits Textadept.
-- @class function
-- @name quit
local quit

---
-- Resets the Lua state by reloading all init scripts.
-- Language-specific modules for opened files are NOT reloaded. Re-opening the
-- files that use them will reload those modules.
-- This function is useful for modifying init scripts (such as the user's
-- `modules/textadept/keys.lua`) on the fly without having to restart Textadept.
-- `_G.RESETTING` is set to `true` when re-initing the Lua State. Any scripts
-- that need to differentiate between startup and reset can utilize this
-- variable.
-- @class function
-- @see RESETTING
-- @name reset
local reset

---
-- Calls a given function after an interval of time.
-- To repeatedly call the function, return true inside the function. A `nil` or
-- `false` return value stops repetition.
-- @param interval The interval in seconds to call the function after.
-- @param f The function to call.
-- @param ... Additional arguments to pass to `f`.
-- @class function
-- @name timeout
local timeout
]]

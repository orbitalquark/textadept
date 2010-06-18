-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- _G table.

--- Extends Lua's _G table to provide extra functions and fields.
module('_G')

-- Markdown:
-- ## Fields
--
-- * `_HOME`: Path to the directory containing Textadept.
-- * `_LEXERPATH`: Paths to lexers, formatted like
--   [`package.path`][package_path].
-- * `_RELEASE`: The Textadept release version.
-- * `_THEME`: The [theme][theme] file to use.
-- * `_USERHOME`: Path to the user's `~/.textadept/`.
-- * `_CHARSET`: The character set encoding of the filesystem. This is used in
--   [File I/O][file_io].
-- * `RESETTING`: If [`reset()`][reset] has been called,
--   this flag is `true` while the Lua state is being re-initialized.
-- * `WIN32`: If Textadept is running on Windows, this flag is `true`.
-- * `MAC`: If Textadept is running on Mac OSX, this flag is `true`.
--
-- [package_path]: http://www.lua.org/manual/5.1/manual.html#pdf-package.path
-- [theme]: ../manual/6_Startup.html
-- [file_io]: ../modules/io.html
-- [reset]: ../modules/_G.html#reset

---
-- Command line parameters.
-- @class table
-- @name arg
arg = {}


---
-- A numerically indexed table of open buffers in Textadept.
-- @class table
-- @name _BUFFERS
_BUFFERS = {}

---
-- A numerically indexed table of views in Textadept.
-- @class table
-- @name _VIEWS
_VIEWS = {}

---
-- Creates a new buffer.
-- Activates the 'buffer_new' signal.
-- @return the new buffer.
function new_buffer() end

---
-- Resets the Lua state by reloading all init scripts.
-- Language-specific modules for opened files are NOT reloaded. Re-opening the
-- files that use them will reload those modules.
-- This function is useful for modifying init scripts (such as keys.lua) on the
-- fly without having to restart Textadept.
-- A global RESETTING variable is set to true when re-initing the Lua State. Any
-- scripts that need to differentiate between startup and reset can utilize this
-- variable.
function reset() end

--- Quits Textadept.
function quit() end

---
-- Calls 'dofile' on the given filename in the user's Textadept directory.
-- This is typically used for loading user files like key commands or snippets.
-- Errors are printed to the Textadept message buffer.
-- @param filename The name of the file (not path).
-- @return true if successful; false otherwise.
function user_dofile(filename) end

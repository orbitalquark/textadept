-- Copyright 2007-2020 Mitchell. See LICENSE.

_RELEASE = 'Textadept 11.0 alpha 3'
_COPYRIGHT = 'Copyright © 2007-2020 Mitchell. See LICENSE.\n' ..
  'https://orbitalquark.github.io/textadept'

package.path = string.format('%s/core/?.lua;%s', _HOME, package.path)

--for _, arg in ipairs(arg) do
--  if arg == '-t' or arg == '--test' then pcall(require, 'luacov') end
--end

require('assert')
_SCINTILLA = require('iface')
events = require('events')
args = require('args')
_L = require('locale')
require('file_io')
require('lfs_ext')
require('ui')
keys = require('keys')
_M = {} -- language modules table

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
    if type(args[i]) == 'function' then args[i](p:read('a')) end -- stdout_cb
    local status = select(3, p:close())
    if type(args[i + 2]) == 'function' then args[i + 2](status) end -- exit_cb
    lfs.chdir(cwd) -- restore
    return p
  end
end

-- Replacement for original `buffer:text_range()`, which has a C struct for an
-- argument.
-- Documentation is in core/.buffer.luadoc.
local function text_range(buffer, start_pos, end_pos)
  assert_type(start_pos, 'number', 2)
  assert_type(end_pos, 'number', 3)
  local target_start, target_end = buffer.target_start, buffer.target_end
  if start_pos < 1 then start_pos = 1 end
  if end_pos > buffer.length + 1 then end_pos = buffer.length + 1 end
  buffer:set_target_range(start_pos, end_pos)
  local text = buffer.target_text
  buffer:set_target_range(target_start, target_end) -- restore
  return text
end

-- Documentation is in core/.buffer.luadoc.
local function style_of_name(buffer, style_name)
  assert_type(style_name, 'string', 2)
  local GETNAMEDSTYLE = _SCINTILLA.properties.named_styles[1]
  return buffer:private_lexer_call(GETNAMEDSTYLE, style_name)
end

events.connect(events.BUFFER_NEW, function()
  buffer.text_range, buffer.style_of_name = text_range, style_of_name
end)

--[[ This comment is for LuaDoc.
---
-- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @field _HOME (string)
--   The path to Textadept's home, or installation, directory.
-- @field _RELEASE (string)
--   The Textadept release version string.
-- @field _USERHOME (string)
--   The path to the user's *~/.textadept/* directory, where all preferences and
--   user-data is stored.
--   On Windows machines *~/* is the value of the "USERHOME" environment
--   variable (typically *C:\Users\username\\* or
--   *C:\Documents and Settings\username\\*). On Linux, BSD, and macOS
--   machines *~/* is the value of "$HOME" (typically */home/username/* and
--   */Users/username/* respectively).
-- @field _CHARSET (string)
--   The filesystem's character encoding.
--   This is used when [working with files](#io).
-- @field WIN32 (bool)
--   Whether or not Textadept is running on Windows.
-- @field OSX (bool)
--   Whether or not Textadept is running on macOS as a GUI application.
-- @field LINUX (bool)
--   Whether or not Textadept is running on Linux.
-- @field BSD (bool)
--   Whether or not Textadept is running on BSD.
-- @field CURSES (bool)
--   Whether or not Textadept is running in a terminal.
--   Curses feature incompatibilities are listed in the [Appendix][].
--
--   [Appendix]: manual.html#terminal-version-compatibility
module('_G')]]

--[[ The tables below were defined in C.

---
-- Table of command line parameters passed to Textadept.
-- @class table
-- @see args
-- @name arg
local arg

---
-- Table of all open buffers in Textadept.
-- Numeric keys have buffer values and buffer keys have their associated numeric
-- keys.
-- @class table
-- @usage _BUFFERS[n]      --> buffer at index n
-- @usage _BUFFERS[buffer] --> index of buffer in _BUFFERS
-- @see _G.buffer
-- @name _BUFFERS
local _BUFFERS

---
-- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric
-- keys.
-- @class table
-- @usage _VIEWS[n]    --> view at index n
-- @usage _VIEWS[view] --> index of view in _VIEWS
-- @see _G.view
-- @name _VIEWS
local _VIEWS

---
-- The current [buffer](#buffer) in the [current view](#_G.view).
-- @class table
-- @name buffer
local buffer

---
-- The current [view](#view).
-- @class table
-- @name view
local view

-- The functions below are Lua C functions.

---
-- Emits a `QUIT` event, and unless any handler returns `false`, quits
-- Textadept.
-- @see events.QUIT
-- @class function
-- @name quit
local quit

---
-- Resets the Lua State by reloading all initialization scripts.
-- Language modules for opened files are NOT reloaded. Re-opening the files that
-- use them will reload those modules instead.
-- This function is useful for modifying user scripts (such as
-- *~/.textadept/init.lua* and *~/.textadept/modules/textadept/keys.lua*) on
-- the fly without having to restart Textadept. `arg` is set to `nil` when
-- reinitializing the Lua State. Any scripts that need to differentiate between
-- startup and reset can test `arg`.
-- @class function
-- @name reset
local reset

---
-- Calls function *f* with the given arguments after *interval* seconds.
-- If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long
-- as *f* returns `true`. A `nil` or `false` return value stops repetition.
-- @param interval The interval in seconds to call *f* after.
-- @param f The function to call.
-- @param ... Additional arguments to pass to *f*.
-- @class function
-- @name timeout
local timeout
]]

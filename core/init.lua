-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

_RELEASE = "Textadept 9.2"
_COPYRIGHT = 'Copyright © 2007-2017 Mitchell. See LICENSE.\n'..
             'http://foicica.com/textadept'

package.path = _HOME..'/core/?.lua;'..package.path

_SCINTILLA = require('iface')
events = require('events')
args = require('args')
_L = require('locale')
require('file_io')
require('lfs_ext')
require('ui')
keys = require('keys')

_M = {} -- language modules table
-- LuaJIT compatibility.
if jit then module, package.searchers, bit32 = nil, package.loaders, bit end
-- pdcurses compatibility.
if CURSES and WIN32 then
  function spawn(argv, cwd, ...)
    local current_dir = lfs.currentdir()
    if cwd then lfs.chdir(cwd) end
    local p = io.popen(argv..' 2>&1')
    local cb_index = type(select(1, ...)) ~= 'table' and 1 or 2 -- ignore env
    local stdout_cb, exit_cb = select(cb_index, ...), select(cb_index + 2, ...)
    if stdout_cb then stdout_cb(p:read('*a')) end
    if exit_cb then exit_cb(select(3, p:close())) else p:close() end
    lfs.chdir(current_dir)
    return p
  end
end

-- Replacement for original `buffer:text_range()`, which has a C struct for an
-- argument.
-- Documentation is in core/.buffer.luadoc.
local function text_range(buffer, start_pos, end_pos)
  local target_start, target_end = buffer.target_start, buffer.target_end
  if start_pos < 0 then start_pos = 0 end
  if end_pos > buffer.length then end_pos = buffer.length end
  buffer:set_target_range(start_pos, end_pos)
  local text = buffer.target_text
  buffer:set_target_range(target_start, target_end) -- reset
  return text
end
events.connect(events.BUFFER_NEW, function() buffer.text_range = text_range end)

local _brace_match
-- Compatibility function for Scintilla's current `buffer:brace_match()`, which
-- has an extra, required `0` parameter (introduced in 3.7.0).
-- Documentation is in core/.buffer.luadoc.
local function brace_match(buffer, pos) return _brace_match(buffer, pos, 0) end
events.connect(events.BUFFER_NEW, function()
  if not _brace_match then _brace_match = buffer.brace_match end
  buffer.brace_match = brace_match
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
--   *C:\Documents and Settings\username\\*). On Linux, BSD, and Mac OSX
--   machines *~/* is the value of "$HOME" (typically */home/username/* and
--   */Users/username/* respectively).
-- @field _CHARSET (string)
--   The filesystem's character encoding.
--   This is used when [working with files](#io).
-- @field WIN32 (bool)
--   Whether or not Textadept is running on Windows.
-- @field OSX (bool)
--   Whether or not Textadept is running on Mac OSX as a GUI application.
-- @field LINUX (bool)
--   Whether or not Textadept is running on Linux.
-- @field BSD (bool)
--   Whether or not Textadept is running on BSD.
-- @field CURSES (bool)
--   Whether or not Textadept is running in the terminal.
--   Curses feature incompatibilities are listed in the [Appendix][].
--
--   [Appendix]: manual.html#Curses.Compatibility
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

-- The function below comes from the lspawn module.

---
-- Spawns an interactive child process *argv* in a separate thread, returning
-- a handle to that process.
-- At the moment, only the Win32 terminal version spawns processes in the same
-- thread.
-- @param argv A command line string that contains the program's name followed
--   by arguments to pass to it. `PATH` is searched for program names.
-- @param cwd Optional current working directory (cwd) for the child
--   process. The default value is `nil`, which inherits the parent's cwd.
-- @param env Optional list of environment variables for the child process.
--   Each element in the list is a 'KEY=VALUE' string. The default value is
--   `nil`, which inherits the parent's environment.
--   This parameter should be omitted completely instead of specifying `nil`.
-- @param stdout_cb Optional Lua function that accepts a string parameter for a
--   block of standard output read from the child. Stdout is read asynchronously
--   in 1KB or 0.5KB blocks (depending on the platform), or however much data is
--   available at the time.
--   At the moment, only the Win32 terminal version sends all output, whether it
--   be stdout or stderr, to this callback after the process finishes.
-- @param stderr_cb Optional Lua function that accepts a string parameter for a
--   block of standard error read from the child. Stderr is read asynchronously
--   in 1KB or 0.5kB blocks (depending on the platform), or however much data is
--   available at the time.
-- @param exit_cb Optional Lua function that is called when the child process
--   finishes. The child's exit status is passed.
-- @return proc or nil plus an error message on failure
-- @usage spawn('lua buffer.filename', nil, print)
-- @usage proc = spawn('lua -e "print(io.read())"', nil, print)
--        proc:write('foo\n')
-- @class function
-- @name spawn
local spawn

---
-- Returns the status of process *spawn_proc*, which is either "running" or
-- "terminated".
-- @return "running" or "terminated"
function spawn_proc:status() end

---
-- Blocks until process *spawn_proc* finishes.
function spawn_proc:wait() end

---
-- Reads and returns stdout from process *spawn_proc*, according to string
-- format or number *arg*.
-- Similar to Lua's `io.read()` and blocks for input. *spawn_proc* must still be
-- running. If an error occurs while reading, returns `nil`, an error code, and
-- an error message.
-- Ensure any read operations read all stdout available, as the stdout callback
-- function passed to `spawn()` will not be called until the stdout buffer is
-- clear.
-- @param arg Optional argument similar to those in Lua's `io.read()`, but "n"
--   is not supported. The default value is "l", which reads a line.
-- @return string of bytes read
function spawn_proc:read(arg) end

---
-- Writes string input to the stdin of process *spawn_proc*.
-- Note: On Linux, if more than 65536 bytes (64K) are to be written, it is
-- possible those bytes need to be written in 65536-byte (64K) chunks, or the
-- process may not receive all input. However, it is also possible that there is
-- a limit on how many bytes can be written in a short period of time, perhaps
-- 196608 bytes (192K).
-- @param ... Standard input for *spawn_proc*.
function spawn_proc:write(...) end

---
-- Closes standard input for process *spawn_proc*, effectively sending an EOF
-- (end of file) to it.
function spawn_proc:close() end

---
-- Kills running process *spawn_proc*, or sends it Unix signal *signal*.
-- @param signal Optional Unix signal to send to *spawn_proc*. The default value
--   is 9 (`SIGKILL`), which kills the process.
function spawn_proc:kill() end
]]

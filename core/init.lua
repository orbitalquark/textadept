-- Copyright 2007-2022 Mitchell. See LICENSE.

_RELEASE = 'Textadept 11.4'
_COPYRIGHT = 'Copyright © 2007-2022 Mitchell. See LICENSE.\n' ..
  'https://orbitalquark.github.io/textadept'

package.path = string.format('%s/core/?.lua;%s', _HOME, package.path)

-- for _, arg in ipairs(arg) do if arg == '-t' or arg == '--test' then pcall(require, 'luacov') end end

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

-- Replacement for original `buffer:text_range()`, which has a C struct for an argument.
-- Documentation is in core/.buffer.luadoc.
local function text_range(buffer, start_pos, end_pos)
  local target_start, target_end = buffer.target_start, buffer.target_end
  buffer:set_target_range(math.max(1, assert_type(start_pos, 'number', 2)),
    math.min(assert_type(end_pos, 'number', 3), buffer.length + 1))
  local text = buffer.target_text
  buffer:set_target_range(target_start, target_end) -- restore
  return text
end

-- Documentation is in core/.buffer.luadoc.
local function style_of_name(buffer, style_name)
  assert_type(style_name, 'string', 2)
  for i = 1, view.STYLE_MAX do if buffer:name_of_style(i) == style_name then return i end end
  return view.STYLE_DEFAULT
end

events.connect(events.BUFFER_NEW,
  function() buffer.text_range, buffer.style_of_name = text_range, style_of_name end)

-- A table of style properties that can be concatenated with other tables of properties.
local style_object = {}
style_object.__index = style_object

-- Creates a new style object.
local function style_obj(props)
  local style = {}
  for k, v in pairs(assert_type(props, 'table', 1)) do style[k] = v end
  return setmetatable(style, style_object)
end

-- Returns a new style object with a set of merged properties.
function style_object.__concat(self, props)
  local style = style_obj(self)
  for k, v in pairs(assert_type(props, 'table', 2)) do style[k] = v end
  return style
end

local map = {italics = 'italic', underlined = 'underline', eolfilled = 'eol_filled'} -- legacy
-- Looks up the style settings for a given style number, and applies them to the given view.
local function set_style(view, style_num)
  local styles = buffer ~= ui.command_entry and view.styles or _G.view.styles
  local style = styles[buffer:name_of_style(assert_type(style_num, 'number', 2))]
  if style then for k, v in pairs(style) do view['style_' .. (map[k] or k)][style_num] = v end end
end

-- Documentation is in core/.view.luadoc.
local function set_styles(view)
  if buffer == ui.command_entry then view = ui.command_entry end
  view:style_reset_default()
  set_style(view, view.STYLE_DEFAULT)
  view:style_clear_all()
  local num_styles = buffer.named_styles
  local num_predefined = view.STYLE_FOLDDISPLAYTEXT - view.STYLE_DEFAULT + 1
  for i = 1, math.min(num_styles - num_predefined, view.STYLE_DEFAULT - 1) do set_style(view, i) end
  for i = view.STYLE_DEFAULT + 1, view.STYLE_FOLDDISPLAYTEXT do set_style(view, i) end
  for i = view.STYLE_FOLDDISPLAYTEXT + 1, num_styles do set_style(view, i) end
end

-- Documentation is in core/.view.luadoc.
local function set_theme(view, name, env)
  if not assert_type(name, 'string', 2):find('[/\\]') then
    name = package.searchpath(name,
      string.format('%s/themes/?.lua;%s/themes/?.lua', _USERHOME, _HOME))
  end
  if not name or not lfs.attributes(name) then return end
  if not assert_type(env, 'table/nil', 3) then env = {} end
  local orig_view = _G.view
  if view ~= orig_view then ui.goto_view(view) end
  assert(loadfile(name, 't', setmetatable(env, {__index = _G})))()
  if view ~= orig_view then ui.goto_view(orig_view) end
  view:set_styles()
end

local styles_mt = {
  __index = function(t, k) return k and t[k:match('^(.+)%.')] or nil end,
  __newindex = function(t, k, v) rawset(t, k, style_obj(v)) end
}

events.connect(events.VIEW_NEW, function()
  view.colors, view.styles = {}, setmetatable({}, styles_mt)
  view.set_styles, view.set_theme = set_styles, set_theme
end)

--[[ This comment is for LuaDoc.
---
-- Extends Lua's _G table to provide extra functions and fields for Textadept.
-- @field _HOME (string)
--   The path to Textadept's home, or installation, directory.
-- @field _RELEASE (string)
--   The Textadept release version string.
-- @field _USERHOME (string)
--   The path to the user's *~/.textadept/* directory, where all preferences and user-data
--   is stored.
--   On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
--   *C:\Users\username\\* or *C:\Documents and Settings\username\\*). On Linux, BSD, and macOS
--   machines *~/* is the value of "$HOME" (typically */home/username/* and */Users/username/*
--   respectively).
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
-- @field _COPYRIGHT (string)
--   Textadept's copyright information.
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
-- Numeric keys have buffer values and buffer keys have their associated numeric keys.
-- @class table
-- @usage _BUFFERS[n]      --> buffer at index n
-- @usage _BUFFERS[buffer] --> index of buffer in _BUFFERS
-- @see _G.buffer
-- @name _BUFFERS
local _BUFFERS

---
-- Table of all views in Textadept.
-- Numeric keys have view values and view keys have their associated numeric keys.
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
-- Moves the buffer at index *from* to index *to* in the `_BUFFERS` table, shifting other buffers
-- as necessary.
-- This changes the order buffers are displayed in in the tab bar and buffer browser.
-- @param from Index of the buffer to move.
-- @param to Index to move the buffer to.
-- @see _BUFFERS
-- @class function
-- @name move_buffer
local move_buffer

---
-- Emits a `QUIT` event, and unless any handler returns `false`, quits Textadept.
-- @see events.QUIT
-- @class function
-- @name quit
local quit

---
-- Resets the Lua State by reloading all initialization scripts.
-- Language modules for opened files are NOT reloaded. Re-opening the files that use them will
-- reload those modules instead.
-- This function is useful for modifying user scripts (such as *~/.textadept/init.lua* and
-- *~/.textadept/modules/textadept/keys.lua*) on the fly without having to restart Textadept. `arg`
-- is set to `nil` when reinitializing the Lua State. Any scripts that need to differentiate
-- between startup and reset can test `arg`.
-- @class function
-- @name reset
local reset

---
-- Calls function *f* with the given arguments after *interval* seconds.
-- If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long as *f* returns
-- `true`. A `nil` or `false` return value stops repetition.
-- @param interval The interval in seconds to call *f* after.
-- @param f The function to call.
-- @param ... Additional arguments to pass to *f*.
-- @class function
-- @name timeout
local timeout
]]

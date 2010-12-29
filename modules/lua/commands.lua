-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the lua module.
module('_m.lua.commands', package.seeall)

-- Markdown:
-- ## Key Commands
--
-- + `Alt+l, m`: Open this module for editing.
-- + `Alt+l, g`: Goto file being 'require'd on the current line.
-- + `Shift+Return`: Try to autocomplete an `if`, `for`, etc. statement with
--   `end`.
-- + `.`: When to the right of a known identifier, show an autocompletion list
--   of fields.
-- + `:`: When to the right of a known identifier, show an autocompletion list
--   of functions.
-- + `Tab`: When the caret is to the right of a `(` in a known function call,
--   show a calltip with documentation for the function.
--
-- ## Autocompletion of Fields and Functions
--
-- This module parses files in the `api_files` table for LuaDoc documentation.
-- Currently all Textadept and Lua identifiers are supported.
--
-- #### Syntax
--
-- Fields are recognized as Lua comments of the form ``-- * `field_name` ``.
-- Functions are recognized as Lua functions of the form `function func(args)`
-- or `function namespace:func(args)`. `.`-completion shows autocompletion for
-- both fields and functions using the first function syntax. `:`-completion
-- shows completions for functions only. Any LuaDoc starting with `---` and
-- including any subsequent comments up until the function declaration will be
-- shown with a calltip when requested.
--
-- In order to be recognized, all comments and functions MUST begin the line.
--
-- Syntatically valid Lua code is not necessary for parsing; only the patterns
-- described above are necessary.
--
-- For example:
--
-- In file `~/.textadept/modules/foo/foo.luadoc`:
--
--     -- * `bar`: Bar field.
--
--     --- LuaDoc for bar.
--     function baz()
--
--     ---
--     -- LuaDoc for foobar.
--     -- @param barfoo First arg.
--     function foobar(barfoo)
--
--     ---
--     -- LuaDoc for foo:barbaz.
--     -- @param foo Foo table.
--     function foo:barbaz()
--
-- In file `_HOME/modules/lua/commands.lua` below `api_files` declaration:
--
--     api_files['foo'] = _USERHOME..'/modules/foo/foo.luadoc'
--
-- In any Lua file:
--
--     foo. -- shows autocompletion list with [bar, baz, foobar].
--     foo: -- shows autocompletion list with [foobar, barbaz].

local m_editing, m_run = _m.textadept.editing, _m.textadept.run
-- Comment string tables use lexer names.
m_editing.comment_string.lua = '--'
-- Compile and Run command tables use file extensions.
m_run.run_command.lua = 'lua %(filename)'
m_run.error_detail.lua = {
  pattern = '^lua: (.-):(%d+): (.+)$',
  filename = 1, line = 2, message = 3
}

---
-- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%b()%s*$', '^%s*local%s*function'
}

---
-- Tries to autocomplete Lua's 'end' keyword for control structures like 'if',
-- 'while', 'for', etc.
-- @see control_structure_patterns
function try_to_autocomplete_end()
  local buffer = buffer
  local line_num = buffer:line_from_position(buffer.current_pos)
  local line = buffer:get_line(line_num)
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = buffer.line_indentation[line_num]
      buffer:begin_undo_action()
      buffer:new_line()
      buffer:new_line()
      buffer:add_text(patt:find('repeat') and 'until' or 'end')
      buffer.line_indentation[line_num + 1] = indent + buffer.indent
      buffer:line_up()
      buffer:line_end()
      buffer:end_undo_action()
      return true
    end
  end
  return false
end

---
-- Determines the Lua file being 'require'd, searches through package.path for
-- that file, and opens it in Textadept.
function goto_required()
  local buffer = buffer
  local line = buffer:get_cur_line()
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  if not file then return end
  file = file:sub(2, -2):gsub('%.', '/')
  for path in package.path:gmatch('[^;]+') do
    path = path:gsub('?', file)
    if lfs.attributes(path) then
      io.open_file(path:iconv('UTF-8', _CHARSET))
      break
    end
  end
end

events.connect('file_after_save',
  function() -- show syntax errors as annotations
    if buffer:get_lexer() == 'lua' then
      local buffer = buffer
      buffer:annotation_clear_all()
      local text = buffer:get_text()
      text = text:gsub('^#![^\n]+', '') -- ignore shebang line
      local _, err = loadstring(text)
      if err then
        local line, msg = err:match('^.-:(%d+):%s*(.+)$')
        line = tonumber(line)
        if line then
          buffer.annotation_visible = 2
          buffer:annotation_set_text(line - 1, msg)
          buffer.annotation_style[line - 1] = 8 -- error style number
          buffer:goto_line(line - 1)
        end
      end
    end
  end)

---
-- LuaDoc to load API from.
-- Keys are Lua table names with LuaDoc file values.
-- @class table
-- @name api_files
local api_files = {
  ['args'] = _HOME..'/core/args.lua',
  ['buffer'] = _HOME..'/core/.buffer.luadoc',
  ['events'] = _HOME..'/core/events.lua',
  ['gui'] = _HOME..'/core/.gui.luadoc',
  ['gui.find'] = _HOME..'/core/.find.luadoc',
  ['gui.command_entry'] = _HOME..'/core/.command_entry.luadoc',
  ['l'] = _HOME..'/lexers/lexer.lua',
  ['view'] = _HOME..'/core/.view.luadoc',
}
-- Add API for loaded textadept modules.
for p in pairs(package.loaded) do
  if p:find('^_m%.textadept%.') then
    api_files[p] = _HOME..'/modules/textadept/'..p:match('[^%.]+$')..'.lua'
  end
end
-- Add Lua API
local lua = { 'coroutine', 'debug', 'io', 'math', 'os', 'string', 'table' }
for _, m in ipairs(lua) do
  api_files[m] = _HOME..'/modules/lua/api/'..m..'.luadoc'
end
api_files[''] = _HOME..'/modules/lua/api/_G.luadoc'

-- Load API.
local apis = {}
local current_doc = {}
local f_args = {}
for word, api_file in pairs(api_files) do
  if lfs.attributes(api_file) then
    apis[word] = { fields = {}, funcs = {} }
    for line in io.lines(api_file) do
      if line:match('^%-%- %* `([^`]+)`') then -- field
        local fields = apis[word].fields
        fields[#fields + 1] = line:match('^%-%- %* `([^`]+)`')..'?2'
      elseif line:match('^function ') then -- function
        local f, n = line:match('^function [%w_]+:(([%w_]+)%([^)]*%))')
        if not f then
          f, n = line:match('^function (([%w_]+)%([^)]*%))')
          local fields = apis[word].fields
          fields[#fields + 1] = n..'?1'
        end
        local funcs = apis[word].funcs
        funcs[#funcs + 1] = n..'?1'
        if f and #current_doc > 0 then
          table.insert(current_doc, 1, f)
          f = table.concat(current_doc, '\n')
          current_doc = {}
        end
        local c = line:find(':') and ':' or '.'
        if word == '' then c = '' end
        f_args[word..c..n] = f
      elseif line:match('^%-%-%-? (.+)$') then
        current_doc[#current_doc + 1] = line:match('^%-%-%-? (.+)$')
      elseif #current_doc > 0 then
        current_doc = {}
      end
    end
    table.sort(apis[word].fields)
    table.sort(apis[word].funcs)
  end
end

local f_xpm = '/* XPM */\nstatic char *function[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c black",\n". c #E0BC38",\n"X c #F0DC5C",\n"o c #FCFC80",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOO  OOOO",\n"OOOOOOOOO oo  OO",\n"OOOOOOOO ooooo O",\n"OOOOOOO ooooo. O",\n"OOOO  O XXoo.. O",\n"OOO oo  XXX... O",\n"OO ooooo XX.. OO",\n"O ooooo.  X. OOO",\n"O XXoo.. O  OOOO",\n"O XXX... OOOOOOO",\n"O XXX.. OOOOOOOO",\n"OO  X. OOOOOOOOO",\n"OOOO  OOOOOOOOOO"\n};'
local v_xpm = '/* XPM */\nstatic char *field[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c black",\n". c #8C748C",\n"X c #9C94A4",\n"o c #ACB4C0",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOO oo  OOO",\n"OOOOOOO ooooo OO",\n"OOOOOO ooooo. OO",\n"OOOOOO XXoo.. OO",\n"OOOOOO XXX... OO",\n"OOOOOO XXX.. OOO",\n"OOOOOOO  X. OOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOOOOOOOOOO"\n};'

-- Returns word specified by patt behind the caret.
-- @param patt Lua pattern containing word characters.
-- @param pos Optional position to start from.
-- @return word.
local function prev_word(patt, pos)
  local buffer = buffer
  local e = pos or buffer.current_pos - 1
  local s = e - 1
  while s >= 0 and string.char(buffer.char_at[s]):find(patt) do s = s - 1 end
  return buffer:text_range(s + 1, e)
end

-- Shows autocompletion list.
-- @param len Length passed to buffer:auto_c_show.
-- @param completions Table of completions.
-- @see buffer:auto_c_show.
local function auto_c_show(len, completions)
  local buffer = buffer
  buffer:clear_registered_images()
  buffer:register_image(1, f_xpm)
  buffer:register_image(2, v_xpm)
  buffer:auto_c_show(len, table.concat(completions, ' '))
end

events.connect('char_added',
  function(c) -- show autocomplete list or calltip
    if c == 46 or c == 58 then -- '.' or ':'
      if buffer:get_lexer() ~= 'lua' then return end
      local word = prev_word('[%w_%.]')
      if word == '' or not apis[word] then return end
      auto_c_show(0, c == 46 and apis[word].fields or apis[word].funcs)
    end
  end)

-- Lua-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  keys.lua = {
    al = {
      m = { io.open_file,
            (_HOME..'/modules/lua/init.lua'):iconv('UTF-8', _CHARSET) },
      g = { goto_required },
    },
    ['s\n'] = { try_to_autocomplete_end },
    [not OSX and 'c\n' or 'esc'] = { function() -- complete API
      local buffer = buffer
      local part = prev_word('[%w_]', buffer.current_pos)
      local pos = buffer.current_pos - #part - 1
      if pos > 0 then
        local word = prev_word('[%w_%.]', pos)
        if word == '' or not apis[word] then return false end -- handle normally
        local c = buffer.char_at[pos]
        auto_c_show(#part, c == 46 and apis[word].fields or apis[word].funcs)
      end
    end },
    ['\t'] = { function() -- show API calltip
      local func = prev_word('[%w_%.:]')
      if not f_args[func] then return false end -- handle normally
      buffer:call_tip_show(buffer.current_pos, f_args[func])
    end },
  }
end

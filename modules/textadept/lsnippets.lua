-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Provides Lua-centric snippets for Textadept.
-- Snippets are basically pieces of text inserted into a document, but can
-- execute code, contain placeholders a user can enter in dynamic text for, and
-- make transformations on that text. This is much more powerful than standard
-- text templating.
-- There are several option variables used:
--   MARK_SNIPPET: The integer mark used to identify the line that marks the
--     end of a snippet.
--   MARK_SNIPPET_COLOR: The Scintilla color used for the line
--     that marks the end of the snippet.
--
module('_m.textadept.lsnippets', package.seeall)

-- Usage:
-- Snippets are defined in the global table 'snippets'. Keys in that table are
-- snippet trigger words, and values are the snippet's text to insert. The
-- exceptions are language names and style names. Language names have table
-- values of either snippets or style keys with table values of snippets.
-- See /lexers/lexer.lua for some default style names. Each lexer's 'add_style'
-- function adds additional styles, the string argument being the style's name.
-- For example:
--   snippets = {
--     file = '%(buffer.filename)',
--     lua = {
--       f = 'function %1(name)(%2(args))\n  %0\nend',
--       string = { [string-specific snippets here] }
--     }
--   }
-- Style and lexer insensitive snippets should be placed in the lexer and
-- snippets tables respectively.
--
-- When searching for a snippet to expand in the snippets table, snippets in the
-- current style have priority, then the ones in the current lexer, and finally
-- the ones in the global table.
--
-- As mentioned, snippets are key-value pairs, the key being the trigger word
-- and the value being the snippet text: ['trigger'] = 'text'.
-- Snippet text however can contain more than just text.
--
-- Insert-time Lua and shell code: %(lua_code), `shell_code`
--   The code is executed the moment the snippet is inserted. For Lua code, the
--   result of the code execution is inserted, so print statements are useless.
--   All global variables and a 'selected_text' variable are available.
--
-- Tab stops/Mirrors: %num
--   These are visited in numeric order with %0 being the final position of the
--   caret, the end of the snippet if not specified. If there is a placeholder
--   (described below) with the specified num, its text is mirrored here.
--
-- Placeholders: %num(text)
--   These are also visited in numeric order, having precedence over tab stops,
--   and inserting the specified text. If no placeholder is available, the tab
--   stop is visited instead. The specified text can contain Lua code executed
--   at run-time: #(lua_code).
--
-- Transformations: %num(pattern|replacement)
--   These act like mirrors, but transform the text that would be inserted using
--   a given Lua pattern and replacement. The replacement can contain Lua code
--   executed at run-time: #(lua_code), as well as the standard Lua capture
--   sequences: %n where 1 <= n <= 9.
--   See the Lua documentation for using patterns and replacements.
--
-- To escape any of the special characters '%', '`', ')', '|', or '#', prepend
-- the standard Lua escape character '%'. Note:
--   * Only '`' needs to be escaped in shell code.
--   * '|'s after the first in transformations do not need to be escaped.
--   * Only unmatched ')'s need to be escaped. Nested ()s are ignored.

local MARK_SNIPPET = 4
local MARK_SNIPPET_COLOR = 0x4D9999

---
-- Global container that holds all snippet definitions.
-- @class table
-- @name snippets
_G.snippets = {}

_G.snippets.file = "%(buffer.filename)"
_G.snippets.path = "%((buffer.filename or ''):match('^.+/'))"
_G.snippets.tab  = "%%%1(1)(%2(default))"
_G.snippets.key  = "['%1'] = { %2(func)%3(, %4(arg)) }"

---
-- [Local table] The current snippet.
-- @class table
-- @name snippet
local snippet = {}

---
-- [Local table] The stack of currently running snippets.
-- @class table
-- @name snippet_stack
local snippet_stack = {}

-- Local functions.
local snippet_info, run_lua_code, handle_escapes, unhandle_escapes, unescape

---
-- Begins expansion of a snippet.
-- The text inserted has escape sequences handled.
-- @param s_text Optional snippet to expand. If none is specified, the snippet
--   is determined from the trigger word (left of the caret), lexer, and style.
function insert(s_text)
  local buffer = buffer
  local caret = buffer.current_pos
  local lexer, style, start, s_name
  if not s_text then
    lexer  = buffer:get_lexer_language()
    style  = buffer:get_style_name( buffer.style_at[caret] )
    buffer:word_left_extend()
    start  = buffer.current_pos
    s_name = buffer:get_sel_text()
  end
  if s_name then
    local function try_get_snippet(...)
      local table = _G.snippets
      for _, idx in ipairs{...} do table = table[idx] end
      return type(table) == 'string' and table or error()
    end
    local ret
    ret, s_text = pcall(try_get_snippet, lexer, style, s_name)
    if not ret then ret, s_text = pcall(try_get_snippet, lexer, s_name) end
    if not ret then ret, s_text = pcall(try_get_snippet, s_name) end
    if not ret then buffer:goto_pos(caret) end -- restore caret
  end

  if s_text then
    buffer:begin_undo_action()
    s_text = handle_escapes(s_text)

    -- Execute Lua and shell code.
    s_text = s_text:gsub('%%(%b())', run_lua_code)
    s_text = s_text:gsub('`([^`]+)`',
      function(code)
        local p = io.popen(code)
        local out = p:read('*all'):sub(1, -2)
        p:close()
        return out
      end)

    -- Initialize the new snippet. If one is running, push it onto the stack.
    if snippet.index then snippet_stack[#snippet_stack + 1] = snippet end
    snippet = {}
    snippet.snapshots = {}
    snippet.start_pos = start or caret
    snippet.prev_sel_text = buffer:get_sel_text()
    snippet.index, snippet.max_index = 0, 0
    for i in s_text:gmatch('%%(%d+)') do
      i = tonumber(i)
      if i > snippet.max_index then snippet.max_index = i end
    end

    -- Insert the snippet and set a mark defining the end of it.
    buffer:replace_sel(s_text) buffer:add_text('\n')
    local line = buffer:line_from_position(buffer.current_pos)
    snippet.end_marker = buffer:marker_add(line, MARK_SNIPPET)
    buffer:marker_set_back(MARK_SNIPPET, MARK_SNIPPET_COLOR)

    -- Indent all lines inserted.
    buffer.current_pos = snippet.start_pos
    local count = 0 for _ in s_text:gmatch('\n') do count = count + 1 end
    if count > 0 then
      local ref_line = buffer:line_from_position(start)
      local isize, ibase = buffer.indent, buffer.line_indentation[ref_line]
      local inum = ibase / isize -- number of indents needed to match
      for i = 1, count do
        local linei = buffer.line_indentation[ref_line + i]
        buffer.line_indentation[ref_line + i] = linei + isize * inum
      end
    end
    buffer:end_undo_action()
  end

  next()
end

---
-- If previously at a placeholder or tab stop, attempts to mirror and/or
-- transform the entered text at all appropriate mirrors before moving on to
-- the next placeholder or tab stop.
function next()
  if not snippet.index then return end
  local buffer = buffer
  local s_start, s_end, s_text = snippet_info()
  if not s_text then cancel_current() return end

  local index = snippet.index
  snippet.snapshots[index] = s_text
  if index > 0 then
    buffer:begin_undo_action()
    local caret = math.max(buffer.anchor, buffer.current_pos)
    local ph_text = buffer:text_range(snippet.ph_pos, caret)

    -- Transform mirror.
    s_text = s_text:gsub('%%'..index..'(%b())',
      function(mirror)
        local pattern, replacement = mirror:match('^%(([^|]+)|(.+)%)$')
        if not pattern and not replacement then return ph_text end
        return ph_text:gsub( unhandle_escapes(pattern),
          function(...)
            local arg = {...}
            local repl = replacement:gsub('%%(%d)',
              function(i) return arg[ tonumber(i) ] or '' end)
            return repl:gsub('#(%b())', run_lua_code)
          end )
      end)

    -- Regular mirror.
    s_text = s_text:gsub('%%'..index, ph_text)

    buffer:set_sel(s_start, s_end) buffer:replace_sel(s_text)
    s_start, s_end = snippet_info()
    buffer:end_undo_action()
  end

  buffer:begin_undo_action()
  index = index + 1
  if index <= snippet.max_index then
    local s, e, next_item = s_text:find('%%'..index..'(%b())')
    if next_item and not next_item:find('|') then -- placeholder
      s, e = buffer:find('%'..index..next_item, 0, s_start)
      next_item = next_item:gsub('#(%b())', run_lua_code)
      next_item = unhandle_escapes( next_item:sub(2, -2) )
      buffer:set_sel(s, e) buffer:replace_sel(next_item)
      buffer:set_sel(s, s + #next_item)
    else -- use the first mirror as a placeholder
      s, e = buffer:find('%'..index..'[^(]', 2097152, s_start) -- regexp
      if not s and not e then
        -- Scintilla cannot match [\r\n\f] in regexp mode; use '$' instead
        s, e = buffer:find('%'..index..'$', 2097152, s_start) -- regexp
        if e then e = e + 1 end
      end
      if not s then snippet.index = index + 1 return next() end
      buffer:set_sel(s, e - 1) buffer:replace_sel('')
    end
    snippet.ph_pos = s
    snippet.index = index
  else
    s_text = unescape( unhandle_escapes( s_text:gsub('%%0', '%%__caret') ) )
    buffer:set_sel(s_start, s_end) buffer:replace_sel(s_text)
    s_start, s_end = snippet_info()
    if s_end then buffer:goto_pos(s_end + 1) buffer:delete_back() end
    local s, e = buffer:find('%__caret', 4, s_start)
    if s and s <= s_end then buffer:set_sel(s, e) buffer:replace_sel('') end
    buffer:marker_delete_handle(snippet.end_marker)
    snippet = #snippet_stack > 0 and table.remove(snippet_stack) or {}
  end
  buffer:end_undo_action()
end

---
-- Goes back to the previous placeholder or tab stop, reverting changes made to
-- subsequent ones.
function prev()
  if not snippet.index then return end
  local buffer = buffer
  local index = snippet.index
  if index > 1 then
    local s_start, s_end = snippet_info()
    local s_text = snippet.snapshots[index - 2]
    buffer:set_sel(s_start, s_end) buffer:replace_sel(s_text)
    snippet.index = index - 2
    next()
  end
end

---
-- Cancels the active snippet, reverting to the state before its activation,
-- and restores the previous running snippet (if any).
function cancel_current()
  if not snippet.index then return end
  local buffer = buffer
  local s_start, s_end = snippet_info()
  buffer:begin_undo_action()
  if s_start and s_end then
    buffer:set_sel(s_start, s_end) buffer:replace_sel('')
    s_start, s_end = snippet_info()
    buffer:goto_pos(s_end + 1) buffer:delete_back()
  end
  if snippet.prev_sel_text then buffer:add_text(snippet.prev_sel_text) end
  buffer:end_undo_action()
  buffer:marker_delete_handle(snippet.end_marker)
  snippet = #snippet_stack > 0 and table.remove(snippet_stack) or {}
end

---
-- Lists available snippets in an autocompletion list.
-- Global snippets and snippets in the current lexer and style are used.
function list()
  local buffer = buffer
  local list, list_str = {}, ''
  local function add_snippets(snippets)
    for s_name in pairs(snippets) do list[#list + 1] = s_name end
  end
  local snippets = _G.snippets
  add_snippets(snippets)
  local lexer = buffer:get_lexer_language()
  local style = buffer:get_style_name( buffer.style_at[buffer.current_pos] )
  if snippets[lexer] and type( snippets[lexer] ) == 'table' then
    add_snippets( snippets[lexer] )
    if snippets[lexer][style] then add_snippets( snippets[lexer][style] ) end
  end
  table.sort(list)
  local sep = string.char(buffer.auto_c_separator)
  for _, v in ipairs(list) do list_str = list_str..v..sep end
  list_str = list_str:sub(1, -2)
  local caret = buffer.current_pos
  buffer:auto_c_show(caret - buffer:word_start_position(caret, true), list_str)
end

---
-- Shows the style at the current caret position in a call tip.
function show_style()
  local buffer = buffer
  local lexer = buffer:get_lexer_language()
  local style_num = buffer.style_at[buffer.current_pos]
  local style = buffer:get_style_name(style_num)
  local text = string.format(
    textadept.locale.M_TEXTADEPT_SNIPPETS_SHOW_STYLE, lexer, style, style_num )
  buffer:call_tip_show(buffer.current_pos, text)
end

---
-- [Local function] Gets the start position, end position, and text of the
-- currently running snippet.
-- @return start pos, end pos, and snippet text.
snippet_info = function()
  local buffer = buffer
  local s = snippet.start_pos
  local e = buffer:position_from_line(
    buffer:marker_line_from_handle(snippet.end_marker) ) - 1
  if e >= s then return s, e, buffer:text_range(s, e) end
end

---
-- [Local function] Runs the given Lua code.
run_lua_code = function(code)
  code = unhandle_escapes(code)
  local env = setmetatable(
    { selected_text = buffer:get_sel_text() }, { __index = _G } )
  local _, val = pcall( setfenv( loadstring('return '..code), env ) )
  return val or ''
end

---
-- [Local function] Replaces escaped characters with their octal equivalents in
-- a given string.
-- '%%' is the escape character used.
handle_escapes = function(s)
  return s:gsub('%%([%%`%)|#])',
    function(char) return ("\\%03d"):format( char:byte() ) end)
end

---
-- [Local function] Replaces octal characters with their escaped equivalents in
-- a given string.
unhandle_escapes = function(s)
  return s:gsub('\\(%d%d%d)',
    function(value) return '%'..string.char(value) end)
end

---
-- [Local function] Replaces escaped characters with the actual characters in a
-- given string.
-- This is used when escape sequences are no longer needed.
unescape = function(s) return s:gsub('%%([%%`%)|#])', '%1') end

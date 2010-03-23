-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Provides Lua-style snippets for Textadept.
module('_m.textadept.lsnippets', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `MARK_SNIPPET`: The unique integer mark used to identify the line that
--    marks the end of a snippet.
-- * `MARK_SNIPPET_COLOR`: The [Scintilla color][scintilla_color] used for the
--   line that marks the end of the snippet.
--
-- [scintilla_color]: http://scintilla.org/ScintillaDoc.html#colour
--
-- ## Overview
--
-- Snippets are basically pieces of text inserted into a document, but can
-- execute code, contain placeholders you can enter dynamic text for, and
-- perform transformations on that text. This is much more powerful than
-- standard text templating.
--
-- Snippets are defined in the global table `snippets`. Each key-value pair in
-- `snippets` consist of either:
--
-- * A string snippet trigger word and its expanded text.
-- * A string language name and its associated `snippets`-like table.
-- * A string style name and its associated `snippets`-like table.
--
-- Language names are the names of the lexer files in `lexers/` such as `cpp`
-- and `lua`. Style names are different lexer styles, most of which are in
-- `lexers/lexer.lua`; examples are `whitespace`, `comment`, and `string`.
--
-- ## Snippet Precedence
--
-- When searching for a snippet to expand in the `snippets` table, snippets in
-- the current style have priority, followed by the ones in the current lexer,
-- and finally the ones in the global table.
--
-- ## Snippet Syntax
--
-- A snippet to insert may contain any of the following:
--
-- #### Plain Text
--
-- Any plain text characters may be used with the exception of `%` and &#96;.
-- These are special characters and must be "escaped" by prefixing one with a
-- `%`. As an example, `%%` inserts a single `%` in the snippet.
--
-- #### Lua and Shell Code
--
--     %(lua_code)
--     `shell_code`
--
-- The code is executed the moment the snippet is inserted.
--
-- For Lua code, the global Lua state is available as well as a `selected_text`
-- variable (containing the current selection in the buffer) for convenience.
-- Only the return value of the code execution is inserted, not standard out.
-- Therefore any `print()` statements are meaningless.
--
-- Shell code is run via Lua's [`io.popen()`][io_popen].
--
-- [io_popen]: http://www.lua.org/manual/5.1/manual.html#pdf-io.popen
--
-- #### Tab Stops and Mirrors
--
--     %num
--
-- These are visited in numeric order (1, 2, 3, etc.) with %0 being the final
-- position of the caret, or the end of the snippet if %0 is not specified. If
-- there is a placeholder (described below) with the specified `num`, its text
-- is mirrored here.
--
-- #### Placeholders
--
--     %num(text)
--
-- These are also visited in numeric order, but have precedence over tab stops,
-- and insert the specified `text` at the current position upon entry. `text`
-- can contain Lua code executed at run-time:
--
--     %num(#(lua_code))
--
-- The global Lua state is available as well as a `selected_text` variable
-- (containing the current selection in the buffer) for convenience.
--
-- `#`'s will have to be escaped with `%` for plain text. Any mis-matched `)`'s
-- must also be escaped, but balanced `()`'s need not be.
--
-- #### Transformations
--
--     %num(pattern|replacement)
--
-- These act like mirrors, but transform the text that would be inserted using
-- a given [Lua pattern][lua_pattern] and replacement. Like in placeholders,
-- `replacement` can contain Lua code executed at run-time as well as the
-- standard Lua capture sequences: `%n` where 1 <= `n` <= 9.
--
-- [lua_pattern]: http://www.lua.org/manual/5.1/manual.html#5.4.1
--
-- Any `|`'s after the first one do not need to be escaped.
--
-- ## Example
--
--     snippets = {
--       file = '%(buffer.filename)',
--       lua = {
--         f = 'function %1(name)(%2(args))\n  %0\nend',
--         string = { [string-specific snippets here] }
--       }
--     }
--
-- The first snippet is global and runs the Lua code to determine the current
-- buffer's filename and inserts it. The other snippets apply only in the `lua`
-- lexer. Any snippets in the `string` table are available only when the current
-- style is `string` in the `lua` lexer.

-- settings
MARK_SNIPPET = 4
MARK_SNIPPET_COLOR = 0x4D9999
-- end settings

---
-- Global container that holds all snippet definitions.
-- @class table
-- @name _G.snippets
_G.snippets = {}

_G.snippets.file = "%(buffer.filename)"
_G.snippets.path = "%((buffer.filename or ''):match('^.+/'))"
_G.snippets.tab  = "%%%1(1)(%2(default))"
_G.snippets.key  = "['%1'] = { %2(func)%3(, %4(arg)) }"

-- The current snippet.
local snippet = {}

-- The stack of currently running snippets.
local snippet_stack = {}

-- Replaces escaped characters with their octal equivalents in a given string.
-- @param s The string to handle escapes in.
-- @return string with escapes handled.
local function handle_escapes(s)
  return s:gsub('%%([%%`%)|#])',
    function(char) return ("\\%03d"):format(char:byte()) end)
end

-- Replaces octal characters with their escaped equivalents in a given string.
-- @param s The string to unhandle escapes in.
-- @return string with escapes unhandled.
local function unhandle_escapes(s)
  local char = string.char
  return s:gsub('\\(%d%d%d)', function(byte) return '%'..char(byte) end)
end

-- Replaces escaped characters with the actual characters in a given string.
-- This is used when escape sequences are no longer needed.
-- @param s The string to unescape escapes in.
-- @return string with escapes unescaped.
local function unescape(s) return s:gsub('%%([%%`%)|#])', '%1') end

-- Gets the start position, end position, and text of the currently running
-- snippet.
-- @return start pos, end pos, and snippet text.
local function snippet_info()
  local buffer = buffer
  local s = snippet.start_pos
  local e =
    buffer:position_from_line(
      buffer:marker_line_from_handle(snippet.end_marker)) - 1
  if e >= s then return s, e, buffer:text_range(s, e) end
end

-- Runs the given Lua code.
-- @param code The Lua code to run.
-- @return string result from the code run.
local function run_lua_code(code)
  code = unhandle_escapes(code)
  local env =
    setmetatable({ selected_text = buffer:get_sel_text() }, { __index = _G })
  local _, val = pcall(setfenv(loadstring('return '..code), env))
  return val or ''
end

-- If previously at a placeholder or tab stop, attempts to mirror and/or
-- transform the entered text at all appropriate mirrors before moving on to
-- the next placeholder or tab stop.
-- @return false if no snippet was expanded; nil otherwise
local function next_tab_stop()
  if not snippet.index then return false end -- no snippet active
  local buffer = buffer
  local s_start, s_end, s_text = snippet_info()
  if not s_text then
    cancel_current()
    return
  end

  local index = snippet.index
  snippet.snapshots[index] = s_text
  if index > 0 then
    buffer:begin_undo_action()
    local caret = math.max(buffer.anchor, buffer.current_pos)
    local ph_text = buffer:text_range(snippet.ph_pos, caret)

    -- Transform mirror.
    s_text =
      s_text:gsub('%%'..index..'(%b())',
        function(mirror)
          local pattern, replacement = mirror:match('^%(([^|]+)|(.+)%)$')
          if not pattern and not replacement then return ph_text end
          return ph_text:gsub(unhandle_escapes(pattern),
            function(...)
              local arg = {...}
              local repl = replacement:gsub('%%(%d+)',
                function(i) return arg[tonumber(i)] or '' end)
              return repl:gsub('#(%b())', run_lua_code)
            end, 1)
        end)

    -- Regular mirror.
    s_text = s_text:gsub('()%%'..index,
      function(pos)
        for mirror, e in s_text:gmatch('%%%d+(%b())()') do
          local s = mirror:find('|')
          if s and pos > s and pos < e then return nil end -- inside transform
        end
        return ph_text
      end)

    buffer:set_sel(s_start, s_end)
    buffer:replace_sel(s_text)
    s_start, s_end = snippet_info()
    buffer:end_undo_action()
  end

  buffer:begin_undo_action()
  index = index + 1
  if index <= snippet.max_index then
    -- Find the next tab stop.
    local s, e, next_item
    repeat -- ignore replacement mirrors
      s, e, next_item = s_text:find('%%'..index..'(%b())', e)
    until not s or next_item and not next_item:find('|')
    if next_item then -- placeholder
      buffer.target_start, buffer.target_end = s_start, buffer.length
      buffer.search_flags = 0
      buffer:search_in_target('%'..index..next_item)
      next_item = next_item:gsub('#(%b())', run_lua_code)
      next_item = unhandle_escapes(next_item:sub(2, -2))
      buffer:replace_target(next_item)
      buffer:set_sel(buffer.target_start, buffer.target_start + #next_item)
      snippet.ph_pos = buffer.target_start
    else
      repeat -- ignore placeholders
        local found = true
        s, e = (s_text..' '):find('%%'..index..'[^(]', e)
        if not s then
          snippet.index = index + 1
          next_tab_stop()
          return
        end
        for p_s, p_e in s_text:gmatch('%%%d+()%b()()') do
          if s > p_s and s < p_e then
            found = false
            break
          end
        end
      until found
      buffer:set_sel(s_start + s - 1, s_start + e - 1)
      buffer:replace_sel('') -- replace_target() doesn't place caret
      snippet.ph_pos = s_start + s - 1
    end
    snippet.index = index
  else
    -- Finished. Find '%0' and place the caret there.
    s_text = unescape(unhandle_escapes(s_text))
    buffer:set_sel(s_start, s_end)
    buffer:replace_sel(s_text)
    s_start, s_end = snippet_info()
    if s_end then
      buffer:goto_pos(s_end + 1)
      buffer:delete_back()
    end
    local s, e = s_text:find('%%0')
    if s and e then
      buffer:set_sel(s_start + s - 1, s_start + e)
      buffer:replace_sel('')
    end
    buffer:marker_delete_handle(snippet.end_marker)
    snippet = #snippet_stack > 0 and table.remove(snippet_stack) or {}
  end
  buffer:end_undo_action()
end

---
-- Begins expansion of a snippet.
-- The text inserted has escape sequences handled.
-- @param s_text Optional snippet to expand. If none is specified, the snippet
--   is determined from the trigger word (left of the caret), lexer, and style.
-- @return false if no snippet was expanded; true otherwise.
function insert(s_text)
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  local lexer, style, start, s_name
  if not s_text then
    lexer = buffer:get_lexer_language()
    style = buffer:get_style_name(buffer.style_at[caret])
    buffer:word_left_extend()
    start = buffer.current_pos
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
    if not ret then buffer:set_sel(anchor, caret) end -- restore caret
  end

  if s_text then
    buffer:begin_undo_action()
    s_text = handle_escapes(s_text)

    -- Execute Lua and shell code.
    s_text = s_text:gsub('%%(%b())', run_lua_code)
    s_text =
      s_text:gsub('`([^`]+)`',
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
    buffer:replace_sel(s_text)
    buffer:add_text('\n')
    local line = buffer:line_from_position(buffer.current_pos)
    snippet.end_marker = buffer:marker_add(line, MARK_SNIPPET)
    buffer:marker_set_back(MARK_SNIPPET, MARK_SNIPPET_COLOR)

    -- Indent all lines inserted.
    buffer.current_pos = snippet.start_pos
    local count = 0
    for _ in s_text:gmatch('\n') do count = count + 1 end
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

  return next_tab_stop() ~= false
end

---
-- Goes back to the previous placeholder or tab stop, reverting changes made to
-- subsequent ones.
-- @return false if no snippet is active; nil otherwise
function prev()
  if not snippet.index then return false end -- no snippet active
  local buffer = buffer
  local index = snippet.index
  if index > 1 then
    local s_start, s_end = snippet_info()
    local s_text = snippet.snapshots[index - 2]
    buffer:set_sel(s_start, s_end)
    buffer:replace_sel(s_text)
    snippet.index = index - 2
    next_tab_stop()
  else
    cancel_current()
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
    buffer:set_sel(s_start, s_end)
    buffer:replace_sel('')
    s_start, s_end = snippet_info()
    buffer:goto_pos(s_end + 1)
    buffer:delete_back()
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
  local list = {}
  local function add_snippets(snippets)
    for s_name in pairs(snippets) do list[#list + 1] = s_name end
  end
  local snippets = _G.snippets
  add_snippets(snippets)
  local lexer = buffer:get_lexer_language()
  local style = buffer:get_style_name(buffer.style_at[buffer.current_pos])
  if snippets[lexer] and type(snippets[lexer]) == 'table' then
    add_snippets(snippets[lexer])
    if snippets[lexer][style] then add_snippets(snippets[lexer][style]) end
  end
  table.sort(list)
  local caret = buffer.current_pos
  buffer:auto_c_show(caret - buffer:word_start_position(caret, true),
                     table.concat(list, string.char(buffer.auto_c_separator)))
end

---
-- Shows the style at the current caret position in a call tip.
function show_style()
  local buffer = buffer
  local lexer = buffer:get_lexer_language()
  local style_num = buffer.style_at[buffer.current_pos]
  local style = buffer:get_style_name(style_num)
  local text =
    string.format(locale.M_TEXTADEPT_SNIPPETS_SHOW_STYLE, lexer, style,
                  style_num)
  buffer:call_tip_show(buffer.current_pos, text)
end

textadept.user_dofile('snippets.lua') -- load user snippets

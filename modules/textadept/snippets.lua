-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Provides Lua-style snippets for Textadept.
module('_m.textadept.snippets', package.seeall)

-- Markdown:
-- ## Overview
--
-- Snippets are dynamic pieces of text inserted into a document that contain
-- placeholders for further input, mirror or transform that input, and execute
-- code.
--
-- Snippets are defined in the global table `snippets`. Each key-value pair in
-- `snippets` consists of either:
--
-- * A string snippet trigger word and its expanded text.
-- * A string lexer language name and its associated `snippets`-like table.
--
-- Language names are the names of the lexer files in `lexers/` such as `cpp`
-- and `lua`.
--
-- By default, the `Tab` key expands a snippet and tabs through placeholders and
-- tab stops while `Shift+Tab` tabs backwards through them. Snippets can also be
-- expanded inside one another.
--
-- ## Settings
--
-- * `MARK_SNIPPET`: The unique integer mark used to identify the line that
--    marks the end of a snippet.
-- * `MARK_SNIPPET_COLOR`: The [Scintilla color][scintilla_color] used for the
--   line that marks the end of the snippet.
--
-- [scintilla_color]: http://scintilla.org/ScintillaDoc.html#colour
--
-- ## Snippet Precedence
--
-- When searching for a snippet to expand in the `snippets` table, snippets in
-- the current lexer have priority, followed by the ones in the global table.
--
-- ## Snippet Syntax
--
-- A snippet to insert may contain any of the following:
--
-- #### Plain Text
--
-- Any plain text characters may be used with the exception of `%` followed
-- immediately by a digit (`0`-`9`), `(`, `)`, `>`, or `]` character. These are
-- "escape sequences" for the more complicated features of snippets. If you want
-- to use `%` followed by one of the before-mentioned characters, prepend
-- another `%` to the first `%`. For example, `%%>` in the snippet inserts a
-- literal `%>` into the document.
--
-- #### Placeholders
--
-- Textadept's snippets provide a number of different placeholders. The simplest
-- ones are of the form
--
--     %num
--
-- where `num` is a number. Placeholders are visited in numeric order (1, 2, 3,
-- etc.) with the `Tab` key after the snippet is inserted and can be used to
-- enter in additional text. When no more placeholders are left, the caret is
-- placed at either the end of the snippet or the `%0` placeholder if it exists.
--
-- A placeholder can specify default text. It is of the form
--
--     %num(default text)
--
-- where, again, `num` is a number. These kinds of placeholders take precedence
-- over the simpler placeholders described above. If a snippet contains more
-- than one placeholder with the same `num`, the one containing default text is
-- visited first and the others become _mirrors_. Mirrors simply mirror the text
-- typed into the current placeholder.
--
-- The last kind of placeholder executes either Lua or Shell code.
--
--     %<lua_code>
--     %num<lua_code>
--     %[shell_code]
--     %num[shell_code]
--
-- For placeholders that omit `num`, their code is executed the moment the
-- snippet is inserted. Otherwise the code is executed as placeholders are
-- visited.
--
-- For Lua code, the global Lua state is available as well as a `selected_text`
-- variable (containing the current selection in the buffer). After execution,
-- the placeholder contains the return value of the code that was run.
--
-- Shell code is executed using Lua's [`io.popen()`][io_popen] which reads from
-- the process' standard output (STDOUT). After execution, the placeholder will
-- contain the STDOUT of the process.
--
-- [io_popen]: http://www.lua.org/manual/5.1/manual.html#pdf-io.popen
--
-- These kinds of placeholders can be used to transform mirrored text. For
-- example, `%2<([[%1]]):gsub('^.', function(c) return c:upper() end)>` will
-- capitalize a mirrored `%1` placeholder.
--
-- ##### Important Note
--
-- It is very important that any `%`, `(`, `)`, `>`, or `]` characters
-- **within** placeholders be escaped with a `%` as necessary. Otherwise,
-- unexpected results will occur. `%`s only need to be escaped if they are
-- proceeded by a digit, `(`s and `)`s only need to be escaped inside default
-- text placeholders **if and only if** there is no matching parenthesis (thus,
-- nested parenthesis do not need to be escaped), `]`s only need to be escaped
-- inside Shell code placeholders, and `>`s only need to be escaped inside Lua
-- code placeholders.
--
-- ## Example
--
--     _G.snippets.snippet = '_G.snippets.%1 = \'%0\''
--     _G.snippets.file = '%<buffer.filename>'
--     _G.snippets.lua = {
--       f = 'function %1(name)(%2(args))\n  %0\nend'
--     }
--
-- The first two snippets are global. The first is quite simple to understand.
-- The second runs Lua code to determine the current buffer's filename and
-- inserts it. The last snippet expands only when editing Lua code.

-- settings
MARK_SNIPPET = 4
MARK_SNIPPET_COLOR = 0x4D9999
-- end settings

-- The stack of currently running snippets.
local snippet_stack = {}

-- Contains newline sequences for buffer.eol_mode.
-- This table is used by new_snippet().
-- @class table
-- @name newlines
local newlines = { [0] = '\r\n', '\r', '\n' }

-- Inserts a new snippet.
-- @param text The new snippet to insert.
-- @param replace_word Flag indicating whether or not a trigger word was used.
--   If true, removes it. Defaults to false.
local function new_snippet(text, replace_word)
  local buffer = buffer
  local start_position = buffer.current_pos
  local original_sel_text = buffer:get_sel_text()
  local newline = newlines[buffer.eol_mode]

  -- Convert and match indentation.
  local lines = {}
  local indent = { [true] = '\t', [false] = (' '):rep(buffer.tab_width) }
  local use_tabs = buffer.use_tabs
  for line in (text..newline):gmatch('([^\r\n]*)'..newline) do
    lines[#lines + 1] = line:gsub('^(%s*)', function(indentation)
      return indentation:gsub(indent[not use_tabs], indent[use_tabs])
    end)
  end
  if #lines > 1 then
    -- Match indentation on all lines after the first.
    local indent_size = #buffer:get_cur_line():match('^%s*')
    if not use_tabs then indent_size = indent_size / buffer.indent end
    local additional_indent = indent[use_tabs]:rep(indent_size)
    for i = 2, #lines do lines[i] = additional_indent..lines[i] end
  end
  text = table.concat(lines, newline)

  -- Insert the snippet and its mark into the buffer.
  buffer:begin_undo_action()
  if replace_word then
    buffer.target_start = buffer:word_start_position(start_position)
    buffer.target_end = start_position
    buffer:replace_target('')
  end
  buffer:replace_sel(text..newline)
  local line = buffer:line_from_position(buffer.current_pos)
  local end_marker = buffer:marker_add(line, MARK_SNIPPET)
  buffer:end_undo_action()

  -- Set the snippet object metatable, add it to the snippet stack, and return
  -- the snippet object.
  local snippet = setmetatable({
    start_position = start_position,
    end_marker = end_marker,
    original_sel_text = original_sel_text,
    snapshots = {}
  }, { __index = _snippet_mt })
  snippet_stack[#snippet_stack + 1] = snippet
  return snippet
end

---
-- Inserts a snippet.
-- @param text Optional snippet text. If none is specified, the snippet text
--   is determined from the trigger and lexer.
-- @return false if no snippet was expanded; true otherwise.
function _insert(text)
  local buffer = buffer
  local from_trigger = text == nil
  if not text then
    local current_pos = buffer.current_pos
    local lexer = buffer:get_lexer()
    local trigger = buffer:text_range(buffer:word_start_position(current_pos),
                                      current_pos)
    local snip = _G.snippets
    text = snip[trigger]
    if type(snip) == 'table' and snip[lexer] then snip = snip[lexer] end
    text = snip[trigger] or text
  end
  local snippet = snippet_stack[#snippet_stack]
  if text and type(text) == 'string' then
    snippet = new_snippet(text, from_trigger)
    snippet:execute_code('') -- execute shell and Lua code
  end
  if not snippet then return false end
  snippet:next()
end

---
-- Goes back to the previous placeholder or tab stop, reverting any changes from
-- the current placeholder or tab stop.
-- @return false if no snippet is active; nil otherwise.
function _previous()
  if #snippet_stack == 0 then return false end
  snippet_stack[#snippet_stack]:prev()
end

---
-- Cancels the active snippet, reverting to the state before its activation, and
-- restores the previously running snippet (if any).
function _cancel_current()
  if #snippet_stack == 0 then snippet_stack[#snippet_stack]:cancel() end
end

---
-- Prompts the user to select a snippet to insert from a filtered list dialog.
-- Global snippets and snippets in the current lexer are shown.
function _select()
  local list = {}
  local table_concat, type = table.concat, type
  for trigger, text in pairs(_G.snippets) do
    if type(text) == 'string' and
       trigger ~= '_NAME' and trigger ~= '_PACKAGE' then
      list[#list + 1] = table_concat({trigger, 'global', text }, '\0')
    end
  end
  local lexer = buffer:get_lexer()
  for trigger, text in pairs(_G.snippets[lexer] or {}) do
    if type(text) == 'string' then
      list[#list + 1] = concat({trigger, lexer, text }, '\0')
    end
  end
  table.sort(list)
  local s = {}
  for i = 1, #list do
    s[#s + 1], s[#s + 2], s[#s + 3] = list[i]:match('^(%Z+)%z(%Z+)%z(%Z+)$')
  end
  local i = gui.filteredlist(L('Select Snippet'),
                             { ('Trigger'), L('Scope'), L('Snippet Text') },
                             s, true, '--output-column', '2')
  if i then _insert(s[(i + 1) * 3]) end
end

-- Table of escape sequences.
-- @class table
-- @name escapes
local escapes = {
  ['%%'] = '\027\027', ['\027\027'] = '%%',
  ['%('] = '\027\017', ['\027\017'] = '%(',
  ['%)'] = '\027\018', ['\027\018'] = '%)',
  ['%>'] = '\027\019', ['\027\019'] = '%>',
  ['%]'] = '\027\020', ['\027\020'] = '%]'
}

-- Metatable for a snippet object.
-- @class table
-- @name _snippet_mt
_snippet_mt = {
  -- Gets a snippet's end position in the Scintilla buffer.
  -- @param snippet The snippet returned by new_snippet().
  get_end_position = function(snippet)
    return buffer:position_from_line(
                  buffer:marker_line_from_handle(snippet.end_marker)) - 1
  end,

  -- Gets the text for a snippet.
  -- @param snippet The snippet returned by new_snippet().
  get_text = function(snippet)
    return buffer:text_range(snippet.start_position, snippet:get_end_position())
  end,

  -- Sets the text for a snippet.
  -- This text will be displayed immediately in the Scintilla buffer.
  -- @param snippet The snippet returned by new_snippet().
  -- @param text The snippet's text.
  set_text = function(snippet, text)
    local buffer = buffer
    buffer.target_start = snippet.start_position
    buffer.target_end = snippet:get_end_position()
    buffer:replace_target(text)
  end,

  -- Returns the escaped form of the snippet's text.
  -- @param snippet The snippet returned by new_snippet().
  -- @see escapes
  get_escaped_text = function(snippet)
    return snippet:get_text():gsub('%%[%%%(%)>%]]', escapes)
  end,

  -- Returns the unescaped form of the given text.
  -- This does the opposite of get_escaped_text() by default. The behaviour is
  -- slightly different when the 'complete' parameter is true.
  -- @param text Text to unescape.
  -- @param complete Flag indicating whether or not to also remove the extra
  --   escape character '%'. Defaults to false.
  unescape_text = function(text, complete)
    text = text:gsub('\027.', escapes)
    return complete and text:gsub('%%([%%%(%)>%]])', '%1') or text
  end,

  -- Executes code in the snippet for the given index.
  -- @param snippet The snippet returned by new_snippet().
  -- @param index Execute code with this index.
  execute_code = function(snippet, index)
    local escaped_text = snippet:get_escaped_text()
    -- Lua code.
    escaped_text = escaped_text:gsub('%%'..index..'<([^>]*)>', function(code)
      local env = setmetatable({ selected_text = snippet.original_sel_text },
                               { __index = _G })
      local f, errmsg = loadstring('return '..snippet.unescape_text(code, true))
      if not f then return errmsg end
      local _, result = pcall(setfenv(f, env))
      return result or ''
    end)
    -- Shell code.
    escaped_text = escaped_text:gsub('%%'..index..'%[([^%]]*)%]', function(code)
      local p = io.popen(snippet.unescape_text(code, true))
      local result = p:read('*all'):sub(1, -2) -- chop '\n'
      p:close()
      return result
    end)
    snippet:set_text(snippet.unescape_text(escaped_text))
  end,

  -- Goes to the next placeholder or tab stop in a snippet.
  -- @param snippet The snippet returned by new_snippet().
  next = function(snippet)
    local buffer = buffer

    -- If the snippet was just initialized, determine how many tab stops it has.
    if not snippet.index then
      snippet.index, snippet.max_index = 0, 0
      for i in snippet:get_escaped_text():gmatch('%%(%d+)') do
        i = tonumber(i)
        if i > snippet.max_index then snippet.max_index = i end
      end
    end

    local index, start_position = snippet.index, snippet.start_position
    snippet.snapshots[index] = snippet:get_text()

    index = index + 1
    if index <= snippet.max_index then
      -- Execute shell and Lua code.
      snippet:execute_code(index)
      local escaped_text = snippet:get_escaped_text()..' '

      -- Find the next tab stop or placeholder that is not a replacement mirror.
      local s, e, placeholder, _
      repeat
        s, _, placeholder, e = escaped_text:find('%%'..index..'(%b())()', e)
      until not s or placeholder
      if placeholder then placeholder = placeholder:sub(2, -2) end
      if not placeholder then
        -- Tab stop.
        s, _, e = escaped_text:find('%%'..index..'()[^(]')
        if not s then
          snippet.index = index
          snippet:next()
          return
        end
        placeholder = ''
      end
      s, e = start_position + s - 1, start_position + e - 1
      buffer:set_sel(s, e)
      buffer:replace_sel(snippet.unescape_text(placeholder))
      if placeholder ~= '' then buffer:set_sel(s, s + #placeholder) end

      -- Add additional carets at mirrors.
      escaped_text = snippet:get_escaped_text()..' '
      offset = 0
      for s, e in escaped_text:gmatch('()%%'..index..'()[^(]') do
        buffer.target_start = start_position + s - 1 + offset
        buffer.target_end = start_position + e - 1 + offset
        buffer:replace_target(placeholder)
        offset = offset + (#placeholder - (e - s))
        buffer:add_selection(buffer.target_start, buffer.target_end)
      end
      buffer.main_selection = 0

      -- Done.
      snippet.index = index
    else
      -- Finished.
      snippet:finish()
    end
  end,

  -- Goes to the previous placeholder or tab stop in a snippet.
  -- @param snippet The snippet returned by new_snippet().
  prev = function(snippet)
    if snippet.index > 1 then
      snippet:set_text(snippet.snapshots[snippet.index - 2])
      snippet.index = snippet.index - 2
      snippet:next()
    else
      snippet:cancel()
    end
  end,

  -- Cancels a snippet.
  -- @param snippet The snippet returned by new_snippet().
  cancel = function(snippet)
    local buffer = buffer
    buffer:set_sel(snippet.start_position, snippet:get_end_position() + 1)
    buffer:replace_sel(snippet.original_sel_text or '')
    buffer:marker_delete_handle(snippet.end_marker)
    snippet_stack[#snippet_stack] = nil
  end,

  -- Finishes a snippet by going to its '%0' tab stop and cleaning up.
  -- @param snippet The snippet returned by new_snippet().
  finish = function(snippet)
    local buffer = buffer
    snippet:set_text(snippet.unescape_text(snippet:get_text(), true))
    local s, e = snippet:get_text():find('%%0')
    if s and e then
      s, e = snippet.start_position + s - 1, snippet.start_position + e
      buffer:set_sel(s, e)
      buffer:replace_sel('')
    else
      buffer:goto_pos(snippet:get_end_position())
    end
    e = snippet:get_end_position()
    buffer.target_start, buffer.target_end = e, e + 1
    buffer:replace_target('')
    buffer:marker_delete_handle(snippet.end_marker)
    snippet_stack[#snippet_stack] = nil
  end,
}

if buffer then buffer:marker_set_back(MARK_SNIPPET, MARK_SNIPPET_COLOR) end
events.connect('view_new',
  function() buffer:marker_set_back(MARK_SNIPPET, MARK_SNIPPET_COLOR) end)

---
-- Provides access to snippets from _G.
-- @class table
-- @name _G.snippets
_G.snippets = _M

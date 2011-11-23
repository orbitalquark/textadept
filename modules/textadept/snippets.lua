-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize

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
-- By default, the `Tab` key expands a snippet and tabs through placeholders
-- while `Shift+Tab` tabs backwards through them. Snippets can also be expanded
-- inside one another.
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
-- proceeded by a digit, `(`s and `)`s only need to be escaped directly after a
-- %num sequence or inside default text placeholders **if and only if** there is
-- no matching parenthesis (thus, nested parentheses do not need to be escaped),
-- `]`s only need to be escaped inside Shell code placeholders, and `>`s only
-- need to be escaped inside Lua code placeholders.
--
-- ## Example
--
--     snippets.snippet = 'snippets.%1 = \'%0\''
--     snippets.file = '%<buffer.filename>'
--     snippets.lua = {
--       f = 'function %1(name)(%2(args))\n\t%0\nend'
--     }
--
-- The first two snippets are global. The first is quite simple to understand.
-- The second runs Lua code to determine the current buffer's filename and
-- inserts it. The last snippet expands only when editing Lua code.
--
-- It is recommended to use tab characters instead of spaces like in the last
-- example. Tabs will be converted to spaces as necessary.

-- The stack of currently running snippets.
local snippet_stack = {}

-- Contains newline sequences for `buffer.eol_mode`.
-- This table is used by `new_snippet()`.
-- @class table
-- @name newlines
local newlines = { [0] = '\r\n', '\r', '\n' }

local INDIC_SNIPPET = _SCINTILLA.next_indic_number()

-- Inserts a new snippet.
-- @param text The new snippet to insert.
-- @param trigger The trigger text used to expand the snippet, if any.
local function new_snippet(text, trigger)
  local buffer = buffer
  local snippet = setmetatable({
    trigger = trigger,
    original_sel_text = buffer:get_sel_text(),
    snapshots = {}
  }, { __index = _snippet_mt })
  snippet_stack[#snippet_stack + 1] = snippet

  -- Convert and match indentation.
  local lines = {}
  local indent = { [true] = '\t', [false] = (' '):rep(buffer.tab_width) }
  local use_tabs = buffer.use_tabs
  for line in (text..'\n'):gmatch('([^\r\n]*)\r?\n') do
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
  text = table.concat(lines, newlines[buffer.eol_mode])

  -- Insert the snippet and its mark into the buffer.
  buffer:target_from_selection()
  if trigger then buffer.target_start = buffer.current_pos - #trigger end
  snippet.start_position = buffer.target_start
  buffer:replace_target(text..' ')
  buffer.indicator_current = INDIC_SNIPPET
  buffer:indicator_fill_range(buffer.target_end - 1, 1)

  snippet:execute_code('')
  return snippet
end

---
-- Inserts a snippet.
-- @param text Optional snippet text. If none is specified, the snippet text
--   is determined from the trigger and lexer.
-- @return `false` if no snippet was expanded; `true` otherwise.
function _insert(text)
  local buffer = buffer
  local trigger
  if not text then
    local lexer = buffer:get_lexer(true)
    trigger = buffer:text_range(buffer:word_start_position(buffer.current_pos),
                                buffer.current_pos)
    local snip = snippets
    text = snip[trigger]
    if type(snip) == 'table' and snip[lexer] then snip = snip[lexer] end
    text = snip[trigger] or text
  end
  local snippet = snippet_stack[#snippet_stack]
  if type(text) == 'string' then snippet = new_snippet(text, trigger) end
  if not snippet then return false end
  snippet:next()
end

---
-- Goes back to the previous placeholder, reverting any changes from the current
-- one.
-- @return `false` if no snippet is active; `nil` otherwise.
function _previous()
  if #snippet_stack == 0 then return false end
  snippet_stack[#snippet_stack]:previous()
end

---
-- Cancels the active snippet, reverting to the state before its activation, and
-- restores the previously running snippet (if any).
function _cancel_current()
  if #snippet_stack > 0 then snippet_stack[#snippet_stack]:cancel() end
end

---
-- Prompts the user to select a snippet to insert from a filtered list dialog.
-- Global snippets and snippets in the current lexer are shown.
function _select()
  local list = {}
  local type = type
  for trigger, text in pairs(snippets) do
    if type(text) == 'string' and
       trigger ~= '_NAME' and trigger ~= '_PACKAGE' then
      list[#list + 1] = trigger..'\0global\0'..text
    end
  end
  local lexer = buffer:get_lexer()
  for trigger, text in pairs(snippets[lexer] or {}) do
    if type(text) == 'string' then
      list[#list + 1] = trigger..'\0'..lexer..'\0'..text
    end
  end
  table.sort(list)
  local t = {}
  for i = 1, #list do
    t[#t + 1], t[#t + 2], t[#t + 3] = list[i]:match('^(%Z+)%z(%Z+)%z(%Z+)$')
  end
  local i = gui.filteredlist(L('Select Snippet'),
                             { L('Trigger'), L('Scope'), L('Snippet Text') },
                             t, true, '--output-column', '2')
  if i then _insert(t[(i + 1) * 3]) end
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
  -- Gets a snippet's end position in the buffer.
  -- @param snippet The snippet returned by `new_snippet()`.
  get_end_position = function(snippet)
    local e = buffer:indicator_end(INDIC_SNIPPET, snippet.start_position + 1)
    if e == 0 then e = snippet.start_position end
    return e
  end,

  -- Gets the text for a snippet.
  -- @param snippet The snippet returned by `new_snippet()`.
  get_text = function(snippet)
    local s, e = snippet.start_position, snippet:get_end_position()
    local ok, text = pcall(buffer.text_range, buffer, s, e)
    return ok and text or ''
  end,

  -- Sets the text for a snippet.
  -- This text will be displayed immediately in the buffer.
  -- @param snippet The snippet returned by `new_snippet()`.
  -- @param text The snippet's text.
  set_text = function(snippet, text)
    local buffer = buffer
    buffer.target_start = snippet.start_position
    buffer.target_end = snippet:get_end_position()
    buffer:replace_target(text)
  end,

  -- Returns the escaped form of the snippet's text.
  -- @param snippet The snippet returned by `new_snippet()`.
  -- @see escapes
  get_escaped_text = function(snippet)
    return snippet:get_text():gsub('%%[%%%(%)>%]]', escapes)
  end,

  -- Returns the unescaped form of the given text.
  -- This does the opposite of `get_escaped_text()` by default. The behaviour is
  -- slightly different when `complete` true.
  -- @param text Text to unescape.
  -- @param complete Flag indicating whether or not to also remove the extra
  --   escape character '%'. Defaults to `false`.
  unescape_text = function(text, complete)
    text = text:gsub('\027.', escapes)
    return complete and text:gsub('%%([%%%(%)>%]])', '%1') or text
  end,

  -- Executes code in the snippet for the given index.
  -- @param snippet The snippet returned by `new_snippet()`.
  -- @param index Execute code with this index.
  execute_code = function(snippet, index)
    local escaped_text = snippet:get_escaped_text()
    -- Lua code.
    escaped_text = escaped_text:gsub('%%'..index..'<([^>]*)>', function(code)
      local env = setmetatable({ selected_text = snippet.original_sel_text },
                               { __index = _G })
      local f, result = loadstring('return '..snippet.unescape_text(code, true))
      if f then f, result = pcall(setfenv(f, env)) end
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

  -- Goes to the next placeholder in a snippet.
  -- @param snippet The snippet returned by `new_snippet()`.
  next = function(snippet)
    local buffer = buffer
    -- If the snippet was just initialized, determine how many placeholders it
    -- has.
    if not snippet.index then
      snippet.index, snippet.max_index = 1, 0
      for i in snippet:get_escaped_text():gmatch('%%(%d+)') do
        i = tonumber(i)
        if i > snippet.max_index then snippet.max_index = i end
      end
    end
    local index = snippet.index
    snippet.snapshots[index] = snippet:get_text()

    if index <= snippet.max_index then
      -- Execute shell and Lua code.
      snippet:execute_code(index)
      local escaped_text = snippet:get_escaped_text()..' '

      -- Find the next placeholder.
      local s, _, placeholder, e = escaped_text:find('%%'..index..'(%b())()')
      if not s then s, _, e = escaped_text:find('%%'..index..'()[^(]') end
      if s then
        local start = snippet.start_position
        placeholder = (placeholder or ''):sub(2, -2)

        -- Place the caret at the placeholder.
        buffer.target_start, buffer.target_end = start + s - 1, start + e - 1
        buffer:replace_target(snippet.unescape_text(placeholder))
        buffer:set_sel(buffer.target_start, buffer.target_end)

        -- Add additional carets at mirrors.
        escaped_text = snippet:get_escaped_text()..' '
        offset = 0
        for s, e in escaped_text:gmatch('()%%'..index..'()[^(]') do
          buffer.target_start = start + s - 1 + offset
          buffer.target_end = start + e - 1 + offset
          buffer:replace_target(placeholder)
          buffer:add_selection(buffer.target_start, buffer.target_end)
          offset = offset + (#placeholder - (e - s))
        end
        buffer.main_selection = 0
      end
      snippet.index = index + 1
      if not s then snippet:next() end
    else
      snippet:finish()
    end
  end,

  -- Goes to the previous placeholder in a snippet.
  -- @param snippet The snippet returned by `new_snippet()`.
  previous = function(snippet)
    if snippet.index > 2 then
      snippet:set_text(snippet.snapshots[snippet.index - 2])
      snippet.index = snippet.index - 2
      snippet:next()
    else
      snippet:cancel()
    end
  end,

  -- Cancels a snippet.
  -- @param snippet The snippet returned by `new_snippet()`.
  cancel = function(snippet)
    local buffer = buffer
    buffer:set_sel(snippet.start_position, snippet:get_end_position())
    buffer:replace_sel(snippet.trigger or snippet.original_sel_text)
    buffer.indicator_current = INDIC_SNIPPET
    buffer:indicator_clear_range(snippet:get_end_position(), 1)
    snippet_stack[#snippet_stack] = nil
  end,

  -- Finishes a snippet by going to its `%0` placeholder and cleaning up.
  -- @param snippet The snippet returned by `new_snippet()`.
  finish = function(snippet)
    local buffer = buffer
    snippet:set_text(snippet.unescape_text(snippet:get_text(), true))
    local s, e = snippet:get_text():find('%%0')
    if s and e then
      buffer:set_sel(snippet.start_position + s - 1, snippet.start_position + e)
      buffer:replace_sel('')
    else
      buffer:goto_pos(snippet:get_end_position())
    end
    buffer.indicator_current = INDIC_SNIPPET
    e = snippet:get_end_position()
    buffer:indicator_clear_range(e, 1)
    buffer.target_start, buffer.target_end = e, e + 1
    buffer:replace_target('') -- clear initial padding space
    snippet_stack[#snippet_stack] = nil
  end,
}

local INDIC_HIDDEN = _SCINTILLA.constants.INDIC_HIDDEN
if buffer then buffer.indic_style[INDIC_SNIPPET] = INDIC_HIDDEN end
events.connect(events.VIEW_NEW,
               function() buffer.indic_style[INDIC_SNIPPET] = INDIC_HIDDEN end)

---
-- Provides access to snippets from `_G`.
-- @class table
-- @name _G.snippets
_G.snippets = _M

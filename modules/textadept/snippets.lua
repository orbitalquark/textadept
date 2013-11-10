-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[=[ This comment is for LuaDoc.
---
-- Snippets for Textadept.
--
-- ## Overview
--
-- Define snippets in the global `snippets` table in key-value pairs. Each pair
-- consists of either a string trigger word and its snippet text, or a string
-- lexer language (from the *lexers/* directory) with a table of trigger words
-- and snippet texts. When searching for a snippet to insert based on a trigger
-- word, Textadept considers snippets in the current lexer to have priority,
-- followed by the ones in the global table. This means if there are two
-- snippets with the same trigger word, Textadept inserts the one specific to
-- the current lexer, not the global one.
--
-- ## Special Sequences
--
-- ### `%`*n*`(`*text*`)`
--
-- Represents a placeholder, where *n* is an integer and *text* is default
-- placeholder text. Textadept moves the caret to placeholders in numeric order
-- each time it calls [`_insert()`](#_insert), finishing at either the "%0"
-- placeholder if it exists or at the end of the snippet. Examples are
--
--     snippets['foo'] = 'foobar%1(baz)'
--     snippets['bar'] = 'start\n\t%0\nend'
--
-- ### `%`*n*
--
-- Represents a mirror, where *n* is an integer. Mirrors with the same *n* as a
-- placeholder mirror any user input in the placeholder. If no placeholder
-- exists for *n*, the first occurrence of that mirror in the snippet becomes
-- the placeholder, but with no default text. Examples are
--
--     snippets['foo'] = '%1(mirror), %1, on the wall'
--     snippets['q'] = '"%1"'
--
-- ### `%`*n*`<`*Lua code*`>`<br/>`%`*n*`[`*Shell code*`]`
--
-- Represents a transform, where *n* is an integer, *Lua code* is arbitrary Lua
-- code, and *Shell code* is arbitrary Shell code. Textadept executes the code
-- when the editor visits placeholder *n*. If the transform omits *n*, Textadept
-- executes the transform's code the moment the editor inserts the snippet.
--
-- Textadept runs Lua code in its Lua State and replaces the transform with the
-- code's return text. The code may use a temporary `selected_text` global
-- variable that contains the currently selected text. An example is
--
--     snippets['add'] = '%1(1) + %2(2) = %3<%1 + %2>'
--
-- Textadept executes shell code using Lua's [`io.popen()`][] and replaces the
-- transform with the process' standard output (stdout). An example is
--
--     snippets['foo'] = '$%1(HOME) = %2[echo $%1]'
--
-- ### `%%`
--
-- Stands for a single '%' since '%' by itself has a special meaning in
-- snippets.
--
-- ### `\t`
--
-- A single unit of indentation based on the user's indentation settings
-- (`buffer.use_tabs` and `buffer.tab_width`).
--
-- ### `\n`
--
-- A single set of line ending delimiters based on the user's end of line mode
-- (`buffer.eol_mode`).
--
-- [`io.popen()`]: http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
module('textadept.snippets')]=]

-- The stack of currently running snippets.
local snippet_stack = {}

local INDIC_SNIPPET = _SCINTILLA.next_indic_number()

local newlines = {[0] = '\r\n', '\r', '\n'}
-- Inserts a new snippet.
-- @param text The new snippet to insert.
-- @param trigger The trigger text used to expand the snippet, if any.
local function new_snippet(text, trigger)
  local snippet = setmetatable({
    trigger = trigger,
    original_sel_text = buffer:get_sel_text(),
    snapshots = {}
  }, {__index = M._snippet_mt})
  snippet_stack[#snippet_stack + 1] = snippet

  -- Convert and match indentation.
  local lines = {}
  local indent = {[true] = '\t', [false] = (' '):rep(buffer.tab_width)}
  local use_tabs = buffer.use_tabs
  for line in (text..'\n'):gmatch('([^\r\n]*)\r?\n') do
    lines[#lines + 1] = line:gsub('^(%s*)', function(indentation)
      return indentation:gsub(indent[not use_tabs], indent[use_tabs])
    end)
  end
  if #lines > 1 then
    -- Match indentation on all lines after the first.
    local indent_size = #buffer:get_cur_line():match('^%s*')
    if not use_tabs then indent_size = indent_size / buffer.tab_width end
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
-- Inserts snippet text *text* or the snippet assigned to the trigger word
-- behind the caret or, if a snippet is active, goes to the active snippet's
-- next placeholder.
-- Returns `false` if no action was taken.
-- @param text Optional snippet text to insert. If `nil`, attempts to insert a
--   new snippet based on the trigger, the word behind caret, and the current
--   lexer.
-- @return `false` if no action was taken; `nil` otherwise.
-- @see buffer.word_chars
-- @name _insert
function M._insert(text)
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
-- Jumps back to the previous snippet placeholder, reverting any changes from
-- the current one.
-- Returns `false` if no snippet is active.
-- @return `false` if no snippet is active; `nil` otherwise.
-- @name _previous
function M._previous()
  if #snippet_stack == 0 then return false end
  snippet_stack[#snippet_stack]:previous()
end

---
-- Cancels the active snippet, removing all inserted text.
-- @name _cancel_current
function M._cancel_current()
  if #snippet_stack > 0 then snippet_stack[#snippet_stack]:cancel() end
end

---
-- Prompts the user to select a snippet to insert from a list of global and
-- language-specific snippets.
-- @name _select
function M._select()
  local list, t = {}, {}
  local type = type
  for trigger, text in pairs(snippets) do
    if type(text) == 'string' then list[#list + 1] = trigger..'\0 \0'..text end
  end
  local lexer = buffer:get_lexer(true)
  for trigger, text in pairs(snippets[lexer] or {}) do
    if type(text) == 'string' then
      list[#list + 1] = trigger..'\0'..lexer..'\0'..text
    end
  end
  table.sort(list)
  for i = 1, #list do
    t[#t + 1], t[#t + 2], t[#t + 3] = list[i]:match('^(%Z+)%z(%Z+)%z(%Z+)$')
  end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Select Snippet'],
    columns = {_L['Trigger'], _L['Scope'], _L['Snippet Text']}, items = t,
    width = CURSES and ui.size[1] - 2 or nil
  }
  if button == 1 and i then M._insert(t[i * 3]) end
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
M._snippet_mt = {
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
  --   escape character '%'. The default value is `false`.
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
      local env = setmetatable({selected_text = snippet.original_sel_text},
                               {__index = _G})
      local f, result = load('return '..snippet.unescape_text(code, true), nil,
                             'bt', env)
      if f then f, result = pcall(f) end
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
    if snippet.index <= 2 then snippet:cancel() return end
    snippet:set_text(snippet.snapshots[snippet.index - 2])
    snippet.index = snippet.index - 2
    snippet:next()
  end,

  -- Cancels a snippet.
  -- @param snippet The snippet returned by `new_snippet()`.
  cancel = function(snippet)
    buffer:set_sel(snippet.start_position, snippet:get_end_position())
    buffer:replace_sel(snippet.trigger or snippet.original_sel_text)
    buffer.indicator_current = INDIC_SNIPPET
    buffer:indicator_clear_range(snippet:get_end_position(), 1)
    snippet_stack[#snippet_stack] = nil
  end,

  -- Finishes a snippet by going to its "%0" placeholder and cleaning up.
  -- @param snippet The snippet returned by `new_snippet()`.
  finish = function(snippet)
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
    buffer:delete_range(e, 1) -- clear initial padding space
    snippet_stack[#snippet_stack] = nil
  end,
}

events.connect(events.VIEW_NEW, function()
  buffer.indic_style[INDIC_SNIPPET] = buffer.INDIC_HIDDEN
end)

---
-- Map of snippet triggers with their snippet text, with language-specific
-- snippets tables assigned to a lexer name key.
-- This table also contains the `textadept.snippets` module.
-- @class table
-- @name _G.snippets
_G.snippets = M

return M

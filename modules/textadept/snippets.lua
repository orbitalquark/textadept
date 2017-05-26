-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

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
-- each time it calls [`textadept.snippets._insert()`](), finishing at either
-- the "%0" placeholder if it exists or at the end of the snippet. Examples are
--
--     snippets['foo'] = 'foobar%1(baz)'
--     snippets['bar'] = 'start\n\t%0\nend'
--
-- ### `%`*n*`{`*list*`}`
--
-- Also represents a placeholder (where *n* is an integer), but presents a list
-- of choices for placeholder text constructed from comma-separated *list*.
-- Examples are
--
--     snippets['op'] = 'operator(%1(1), %2(1), "%3{add,sub,mul,div}")'
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
-- Represents a transform, where *n* is an integer that has an associated
-- placeholder, *Lua code* is arbitrary Lua code, and *Shell code* is arbitrary
-- Shell code. Textadept executes the code as text is typed into placeholder
-- *n*. If the transform omits *n*, Textadept executes the transform's code the
-- moment the editor inserts the snippet.
--
-- Textadept runs Lua code in its Lua State and replaces the transform with the
-- code's return text. The code may use the temporary `text` and `selected_text`
-- global variables which contain placeholder *n*'s text and the text originally
-- selected when the snippet was inserted, respectively. An example is
--
--     snippets['attr'] = [[
--     %1(int) %2(foo) = %3;
--
--     %1 get%2<text:gsub('^.', function(c) return c:upper() end)>() {
--     	return %2;
--     }
--     void set%2<text:gsub('^.', function(c) return c:upper() end)>(%1 value) {
--     	%2 = value;
--     }
--     ]]
--
-- Textadept executes shell code using Lua's [`io.popen()`][] and replaces the
-- transform with the process' standard output (stdout). The code may use a `%`
-- character to represent placeholder *n*'s text. An example is
--
--     snippets['env'] = '$%1(HOME) = %1[echo $%]'
--
-- ### `%%`
--
-- Stands for a single '%' since '%' by itself has a special meaning in
-- snippets.
--
-- ### `%(`<br/>`%{`
--
-- Stands for a single '(' or '{', respectively, after a `%`*n* mirror.
-- Otherwise, the mirror would be interpreted as a placeholder or transform.
-- Note: it is currently not possible to escape a '<' or '[' immediately after
-- a `%`*n* mirror due to `%<...>` and `%[...]` sequences being interpreted as
-- code to execute.
--
-- ### `\t`
--
-- A single unit of indentation based on the buffer's indentation settings
-- ([`buffer.use_tabs`]() and [`buffer.tab_width`]()).
--
-- ### `\n`
--
-- A single set of line ending delimiters based on the buffer's end of line mode
-- ([`buffer.eol_mode`]()).
--
-- [`io.popen()`]: http://www.lua.org/manual/5.3/manual.html#pdf-io.popen
--
-- @field INDIC_PLACEHOLDER (number)
--   The snippet placeholder indicator number.
module('textadept.snippets')]=]

M.INDIC_PLACEHOLDER = _SCINTILLA.next_indic_number()

---
-- List of directory paths to look for snippet files in.
-- Filenames are of the form *lexer.trigger.ext* or *trigger.ext* (*.ext* is an
-- optional, arbitrary file extension). If the global `snippets` table does not
-- contain a snippet for a given trigger, this table is consulted for a matching
-- filename, and the contents of that file is inserted as a snippet.
-- Note: If a directory has multiple snippets with the same trigger, the snippet
-- chosen for insertion is not defined and may not be constant.
-- @class table
-- @name _paths
M._paths = {}

local INDIC_SNIPPET = _SCINTILLA.next_indic_number()
local INDIC_CURRENTPLACEHOLDER = _SCINTILLA.next_indic_number()

-- The stack of currently running snippets.
local snippet_stack = {}

-- Inserts a new snippet, adds it to the snippet stack, and returns the snippet.
-- @param text The new snippet to insert.
-- @param trigger The trigger text used to expand the snippet, if any.
local function new_snippet(text, trigger)
  -- An inserted snippet.
  -- @field trigger The word that triggered this snippet.
  -- @field original_sel_text The text originally selected when this snippet was
  --   inserted.
  -- @field start_pos This snippet's start position.
  -- @field end_pos This snippet's end position. This is a metafield that is
  --   computed based on the `INDIC_SNIPPET` sentinel.
  -- @field placeholder_pos The beginning of the current placeholder in this
  --   snippet. This is used by transforms to identify text to transform. This
  --   is a metafield that is computed based on `INDIC_CURRENTPLACEHOLDER`.
  -- @field index This snippet's current placeholder index.
  -- @field max_index The number of different placeholders in this snippet.
  -- @field snapshots A record of this snippet's text over time. The snapshot
  --   for a given placeholder index contains the state of the snippet with all
  --   placeholders of that index filled in (prior to moving to the next
  --   placeholder index). Snippet state consists of a `text` string field and a
  --   `placeholders` table field.
  -- @class table
  -- @name snippet
  local snippet = setmetatable({
    trigger = trigger, original_sel_text = buffer:get_sel_text(),
    start_pos = buffer.selection_start - (trigger and #trigger or 0),
    index = 0, max_index = 0, snapshots = {},
  }, {__index = function(self, k)
    if k == 'end_pos' then
      local end_pos = buffer:indicator_end(INDIC_SNIPPET, self.start_pos)
      return end_pos > self.start_pos and end_pos or self.start_pos
    elseif k == 'placeholder_pos' then
      -- Normally the marker is one character behind the placeholder. However
      -- it will not exist at all if the placeholder is at the beginning of the
      -- snippet. Also account for the marker being at the beginning of the
      -- snippet. (If so, pos will point to the correct position.)
      local pos = buffer:indicator_end(INDIC_CURRENTPLACEHOLDER, self.start_pos)
      if pos == 0 then pos = self.start_pos end
      return bit32.band(buffer:indicator_all_on_for(pos),
                        2^INDIC_CURRENTPLACEHOLDER) > 0 and pos + 1 or pos
    else
      return M._snippet_mt[k]
    end
  end})
  snippet_stack[#snippet_stack + 1] = snippet

  -- Convert and match indentation.
  local lines = {}
  local indent = {[true] = '\t', [false] = string.rep(' ', buffer.tab_width)}
  local use_tabs = buffer.use_tabs
  for line in (text..'\n'):gmatch('([^\r\n]*)\r?\n') do
    lines[#lines + 1] = line:gsub('^(%s*)', function(indentation)
      return indentation:gsub(indent[not use_tabs], indent[use_tabs])
    end)
  end
  if #lines > 1 then
    -- Match indentation on all lines after the first.
    local line = buffer:line_from_position(buffer.current_pos)
    -- Need integer division and LuaJIT does not have // operator.
    local level = math.floor(buffer.line_indentation[line] / buffer.tab_width)
    local additional_indent = indent[use_tabs]:rep(level)
    for i = 2, #lines do lines[i] = additional_indent..lines[i] end
  end
  text = table.concat(lines, ({[0] = '\r\n', '\r', '\n'})[buffer.eol_mode])

  -- Parse placeholders and generate initial snapshot.
  local snapshot = {text = '', placeholders = {}}
  local P, S, R, V = lpeg.P, lpeg.S, lpeg.R, lpeg.V
  local C, Cp, Ct, Cg, Cc = lpeg.C, lpeg.Cp, lpeg.Ct, lpeg.Cg, lpeg.Cc
  local patt = P{
    V('plain_text') * V('placeholder') * Cp() + V('plain_text') * -1,
    plain_text = C(((P(1) - '%' + '%' * S('({'))^1 + '%%')^0),
    placeholder = Ct('%' * (V('index')^-1 * (V('angles') + V('brackets') +
                                             V('braces')) *
                            V('transform') +
                            V('index') * (V('parens') + V('simple')))),
    index = Cg(R('09')^1 / tonumber, 'index'),
    parens = '(' * Cg((1 - S('()') + V('parens'))^0, 'default') * ')',
    simple = Cg(Cc(true), 'simple'), transform = Cg(Cc(true), 'transform'),
    brackets = '[' * Cg((1 - S('[]') + V('brackets'))^0, 'sh_code') * ']',
    braces = '{' * Cg((1 - S('{}') + V('braces'))^0, 'choice') * '}',
    angles = '<' * -P('/') * Cg((1 - S('<>') + V('angles'))^0, 'lua_code') * '>'
  }
  -- A snippet placeholder.
  -- Each placeholder is stored in a snippet snapshot.
  -- @field id This placeholder's unique ID. This field is used as an
  --   indicator's value for identification purposes.
  -- @field index This placeholder's index.
  -- @field default This placeholder's default text, if any.
  -- @field transform Whether or not this placeholder is a transform (containing
  --   either Lua or Shell code).
  -- @field lua_code The Lua code of this transform.
  -- @field sh_code The Shell code of this transform.
  -- @field choice A list of options to insert from an autocompletion list.
  -- @field position This placeholder's initial position in its snapshot. This
  --   field will not update until the next snapshot is taken. Use
  --   `snippet:each_placeholder()` to determine a placeholder's current
  --   position.
  -- @field length This placeholder's initial length in its snapshot. This field
  --   will never update. Use `buffer:indicator_end()` in conjunction with
  --   `snippet:each_placeholder()` to determine a placeholder's current length.
  -- @class table
  -- @name placeholder
  local text_part, placeholder, e = patt:match(text)
  while placeholder do
    if placeholder.index then
      local i = placeholder.index
      if i > snippet.max_index then snippet.max_index = i end
      placeholder.id = #snapshot.placeholders + 1
      snapshot.placeholders[#snapshot.placeholders + 1] = placeholder
    end
    if text_part ~= '' then
      snapshot.text = snapshot.text..text_part:gsub('%%(%p)', '%1')
    end
    placeholder.position = #snapshot.text
    if placeholder.default then
      -- Execute any embedded code first.
      placeholder.default = placeholder.default:gsub('%%%b<>', function(s)
        return snippet:execute_code{lua_code = s:sub(3, -2)}
      end):gsub('%%%b[]', function(s)
        return snippet:execute_code{sh_code = s:sub(3, -2)}
      end)
      if placeholder.default:find('%%%d+') then
        -- Parses out embedded placeholders, adding them to this snippet's
        -- snapshot.
        -- @param s The placeholder string to parse.
        -- @param start_pos The absolute position in the snippet `s` starts
        --   from. All computed positions are anchored from here.
        -- @return plain text from `s` (i.e. no placeholder markup)
        local function process_placeholders(s, start_pos)
          -- Processes a placeholder capture from LPeg.
          -- @param position The position a the beginning of the placeholder.
          -- @param index The placeholder index.
          -- @param default The default placeholder text, if any.
          local function ph(position, index, default)
            position = start_pos + position - 1
            if default then
              -- Process sub-placeholders starting at the index after '%n('.
              default = process_placeholders(default:sub(2, -2),
                                             position + #index + 2)
            end
            index = tonumber(index)
            if index > snippet.max_index then snippet.max_index = index end
            snapshot.placeholders[#snapshot.placeholders + 1] = {
              id = #snapshot.placeholders + 1, index = index,
              default = default, simple = not default or nil,
              length = #(default or ' '),
              position = snippet.start_pos + position,
            }
            return default or ' '
          end
          local ph_patt = P{
            lpeg.Cs((Cp() * '%' * C(R('09')^1) * C(V('parens'))^-1 / ph + 1)^0),
            parens = '(' * (1 - S('()') + V('parens'))^0 * ')'
          }
          return ph_patt:match(s)
        end
        placeholder.default = process_placeholders(placeholder.default,
                                                   placeholder.position)
      end
      snapshot.text = snapshot.text..placeholder.default
    elseif placeholder.transform and not placeholder.index then
      snapshot.text = snapshot.text..snippet:execute_code(placeholder)
    else
      snapshot.text = snapshot.text..' ' -- fill empty placeholders for display
    end
    placeholder.length = #snapshot.text - placeholder.position
    placeholder.position = snippet.start_pos + placeholder.position -- absolute
    text_part, placeholder, e = patt:match(text, e)
  end
  if text_part ~= '' then
    snapshot.text = snapshot.text..text_part:gsub('%%(%p)', '%1')
  end
  snippet.snapshots[0] = snapshot

  -- Insert the snippet into the buffer and mark its end position.
  buffer:begin_undo_action()
  buffer:set_target_range(snippet.start_pos, buffer.selection_end)
  buffer:replace_target('  ') -- placeholder for snippet text
  buffer.indicator_current = INDIC_SNIPPET
  buffer:indicator_fill_range(snippet.start_pos + 1, 1)
  snippet:insert() -- insert into placeholder
  buffer:end_undo_action()

  return snippet
end

---
-- Inserts snippet text *text* or the snippet assigned to the trigger word
-- behind the caret.
-- Otherwise, if a snippet is active, goes to the active snippet's next
-- placeholder. Returns `false` if no action was taken.
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
    text = type(M[lexer]) == 'table' and M[lexer][trigger] or M[trigger]
    if not text then
      for i = 1, #M._paths do
        for basename in lfs.dir(M._paths[i]) do
          -- Snippet files are either of the form "lexer.trigger.ext" or
          -- "trigger.ext". Prefer "lexer."-prefixed snippets.
          local first, second = basename:match('^([^.]+)%.?([^.]*)')
          if first == lexer and second == trigger or
             first == trigger and second == '' and not text then
            local f = io.open(M._paths[i]..'/'..basename)
            text = f:read('*a')
            f:close()
          end
        end
      end
    end
  end
  if type(text) == 'function' and not trigger:find('^_') then text = text() end
  local snippet = type(text) == 'string' and new_snippet(text, trigger) or
                  snippet_stack[#snippet_stack]
  if snippet then snippet:next() else return false end
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
  if #snippet_stack > 0 then snippet_stack[#snippet_stack]:finish(true) end
end

---
-- Prompts the user to select a snippet to insert from a list of global and
-- language-specific snippets.
-- @name _select
function M._select()
  local list, items = {}, {}
  for trigger, text in pairs(snippets) do
    if type(text) == 'string' then list[#list + 1] = trigger..'|'..text end
  end
  local lexer = buffer:get_lexer(true)
  if snippets[lexer] then
    for trigger, text in pairs(snippets[lexer]) do
      if type(text) == 'string' then list[#list + 1] = trigger..'|'..text end
    end
  end
  for i = 1, #M._paths do
    for basename in lfs.dir(M._paths[i]) do
      local first, second = basename:match('^([^.]+)%.?([^.]*)')
      if second == '' or first == lexer then
        local f = io.open(M._paths[i]..'/'..basename)
        list[#list + 1] = (second ~= '' and second or first)..'|'..f:read('*a')
        f:close()
      end
    end
  end
  table.sort(list)
  for i = 1, #list do
    items[#items + 1], items[#items + 2] = list[i]:match('^([^|]+)|(.+)$')
  end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Select Snippet'], columns = {_L['Trigger'], _L['Snippet Text']},
    items = items, width = CURSES and ui.size[1] - 2 or nil
  }
  if button == 1 and i then M._insert(items[i * 2]) end
end

-- Metatable for a snippet object.
-- @class table
-- @name _snippet_mt
M._snippet_mt = {
  -- Inserts the current snapshot (based on `self.index`) of this snippet into
  -- the buffer and marks placeholders.
  insert = function(self)
    buffer:set_target_range(self.start_pos, self.end_pos)
    buffer:replace_target(self.snapshots[self.index].text)
    buffer.indicator_current = M.INDIC_PLACEHOLDER
    for id, placeholder in pairs(self.snapshots[self.index].placeholders) do
      buffer.indicator_value = id
      buffer:indicator_fill_range(placeholder.position, placeholder.length)
    end
  end,

  -- Jumps to the next placeholder in this snippet and adds additional carets
  -- at mirrors.
  next = function(self)
    if buffer:auto_c_active() then buffer:auto_c_complete() end
    -- Take a snapshot of the current state in order to restore it later if
    -- necessary.
    if self.index > 0 and self.start_pos < self.end_pos then
      local text = buffer:text_range(self.start_pos, self.end_pos)
      local placeholders = {}
      for pos, ph in self:each_placeholder() do
        -- Only the position of placeholders changes between snapshots; save it
        -- and keep all other existing properties.
        -- Note that nested placeholders will return the same placeholder id
        -- twice: once before a nested placeholder, and again after. (e.g.
        -- [foo[bar]baz] will will return the '[foo' and 'baz]' portions of the
        -- same placeholder.) Only process the first occurrence.
        if not placeholders[ph.id] then
          placeholders[ph.id] = setmetatable({position = pos}, {
            __index = self.snapshots[self.index - 1].placeholders[ph.id]
          })
        end
      end
      self.snapshots[self.index] = {text = text, placeholders = placeholders}
    end
    self.index = self.index < self.max_index and self.index + 1 or 0

    -- Find the default placeholder, which may be the first mirror.
    local ph = select(2, self:each_placeholder(self.index, 'default')()) or
               select(2, self:each_placeholder(self.index, 'choice')()) or
               select(2, self:each_placeholder(self.index, 'simple')()) or
               self.index == 0 and {position = self.end_pos, length = 0}
    if not ph then self:next() return end -- try next placeholder

    -- Mark the position of the placeholder so transforms can identify it.
    buffer.indicator_current = INDIC_CURRENTPLACEHOLDER
    buffer:indicator_clear_range(self.placeholder_pos - 1, 1)
    if ph.position > self.start_pos and self.index > 0 then
      -- Place it directly behind the placeholder so it will be preserved.
      buffer:indicator_fill_range(ph.position - 1, 1)
    end

    buffer:begin_undo_action()

    -- Jump to the default placeholder and clear its marker.
    buffer:set_sel(ph.position, ph.position + ph.length)
    local e = buffer:indicator_end(M.INDIC_PLACEHOLDER, ph.position)
    buffer.indicator_current = M.INDIC_PLACEHOLDER
    buffer:indicator_clear_range(ph.position, e - ph.position)
    if not ph.default then buffer:replace_sel('') end -- delete filler ' '
    if ph.choice then
      local sep = buffer.auto_c_separator
      buffer.auto_c_separator = string.byte(',')
      buffer:auto_c_show(0, ph.choice)
      buffer.auto_c_separator = sep -- restore
    end

    -- Add additional carets at mirrors and clear their markers.
    local text = ph.default or ''
    ::redo::
    for pos in self:each_placeholder(self.index, 'simple') do
      local e = buffer:indicator_end(M.INDIC_PLACEHOLDER, pos)
      buffer:indicator_clear_range(pos, e - pos)
      buffer:set_target_range(pos, pos + 1)
      buffer:replace_target(text)
      buffer:add_selection(pos, pos + #text)
      goto redo -- indicator positions have changed
    end
    buffer.main_selection = 0

    -- Update transforms.
    self:update_transforms()

    buffer:end_undo_action()

    if self.index == 0 then self:finish() end
  end,

  -- Jumps to the previous placeholder in this snippet and restores the state
  -- associated with that placeholder.
  previous = function(self)
    if self.index < 2 then self:finish(true) return end
    self.index = self.index - 2
    self:insert()
    self:next()
  end,

  -- Finishes or cancels this snippet depending on boolean *canceling*.
  -- The snippet cleans up after itself regardless.
  -- @param canceling Whether or not to cancel inserting this snippet. When
  --   `true`, the buffer is restored to its state prior to snippet expansion.
  finish = function(self, canceling)
    local s, e = self.start_pos, self.end_pos
    buffer:delete_range(e, 1) -- clear initial padding space
    if not canceling then
      buffer.indicator_current = M.INDIC_PLACEHOLDER
      buffer:indicator_clear_range(s, e - s)
    else
      buffer:set_sel(s, e)
      buffer:replace_sel(self.trigger or self.original_sel_text)
    end
    snippet_stack[#snippet_stack] = nil
  end,

  -- Returns a generator that returns each placeholder's position and state for
  -- all placeholders in this snippet.
  -- DO NOT modify the buffer while this generator is running. Doing so will
  -- affect the generator's state and cause errors. Re-run the generator each
  -- time a buffer edit is made (e.g. via `goto`).
  -- @param index Optional placeholder index to constrain results to.
  -- @param type Optional placeholder type to constrain results to.
  each_placeholder = function(self, index, type)
    local snapshot = self.snapshots[self.index > 0 and self.index - 1 or
                                    #self.snapshots]
    local i = self.start_pos
    return function()
      local s = buffer:indicator_end(M.INDIC_PLACEHOLDER, i)
      while s > 0 and s <= self.end_pos do
        if bit32.band(buffer:indicator_all_on_for(i),
                      2^M.INDIC_PLACEHOLDER) > 0 then
          -- This next indicator comes directly after the previous one; adjust
          -- start and end positions to compensate.
          s, i = buffer:indicator_start(M.INDIC_PLACEHOLDER, i), s
        else
          i = buffer:indicator_end(M.INDIC_PLACEHOLDER, s)
        end
        local id = buffer:indicator_value_at(M.INDIC_PLACEHOLDER, s)
        local ph = snapshot.placeholders[id]
        if (not index or ph.index == index) and (not type or ph[type]) then
          return s, ph
        end
        s = buffer:indicator_end(M.INDIC_PLACEHOLDER, i)
      end
    end
  end,

  -- Returns the result of executing Lua or Shell code, in placeholder table
  -- *placeholder*, in the context of this snippet.
  -- @param placeholder The placeholder that contains code to execute.
  execute_code = function(self, placeholder)
    local s, e = self.placeholder_pos, buffer.selection_end
    local text = s < e and buffer:text_range(s, e) or buffer:text_range(e, s)
    if not self.index then text = '' end -- %<...> or %[...]
    if placeholder.lua_code then
      local env = {text = text, selected_text = self.original_sel_text}
      local f, result = load('return '..placeholder.lua_code, nil, 'bt',
                             setmetatable(env, {__index = _G}))
      return f and select(2, pcall(f)) or result or ''
    elseif placeholder.sh_code then
      -- Note: cannot use spawn since $env variables are not expanded.
      local command = placeholder.sh_code:gsub('%f[%%]%%%f[^%%]', text)
      local p = io.popen(command)
      local result = p:read('*a'):sub(1, -2) -- chop '\n'
      p:close()
      return result
    end
  end,

  -- Updates transforms in place based on the current placeholder's text.
  update_transforms = function(self)
    buffer.indicator_current = M.INDIC_PLACEHOLDER
    local processed = {}
    ::redo::
    for s, ph in self:each_placeholder(nil, 'transform') do
      if ph.index == self.index and not processed[ph] then
        -- Execute the code and replace any existing transform text.
        local result = self:execute_code(ph)
        if result == '' then result = ' ' end -- fill for display
        local id = buffer:indicator_value_at(M.INDIC_PLACEHOLDER, s)
        buffer:set_target_range(s, buffer:indicator_end(M.INDIC_PLACEHOLDER, s))
        buffer:replace_target(result)
        buffer.indicator_value = id
        buffer:indicator_fill_range(s, #result) -- re-mark
        processed[ph] = true
        goto redo -- indicator positions have changed
      elseif ph.index < self.index or self.index == 0 then
        -- Clear obsolete transforms, deleting filler text if necessary.
        local e = buffer:indicator_end(M.INDIC_PLACEHOLDER, s)
        buffer:indicator_clear_range(s, e - s)
        if buffer:text_range(s, e) == ' ' then
          buffer:set_target_range(s, e)
          buffer:replace_target('')
          goto redo
        end
      end
      -- TODO: insert initial transform for ph.index > self.index
    end
  end,
}

-- Update snippet transforms when text is added or deleted.
events.connect(events.UPDATE_UI, function(updated)
  if #snippet_stack > 0 and updated and
     bit32.band(updated, buffer.UPDATE_CONTENT) > 0 then
    snippet_stack[#snippet_stack]:update_transforms()
  end
end)

events.connect(events.VIEW_NEW, function()
  buffer.indic_style[INDIC_SNIPPET] = buffer.INDIC_HIDDEN
  buffer.indic_style[INDIC_CURRENTPLACEHOLDER] = buffer.INDIC_HIDDEN
end)

---
-- Map of snippet triggers with their snippet text or functions that return such
-- text, with language-specific snippets tables assigned to a lexer name key.
-- This table also contains the `textadept.snippets` module.
-- @class table
-- @name _G.snippets
_G.snippets = M

return M

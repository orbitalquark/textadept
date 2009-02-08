-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

---
-- Provides Textmate-like snippets for the textadept module.
-- There are several option variables used:
--   MARK_SNIPPET: The integer mark used to identify the line that marks the
--     end of a snippet.
--   SCOPES_ENABLED: Flag indicating whether scopes/styles can be used for
--     snippets.
--   MARK_SNIPPET_COLOR: The Scintilla color used for the line that marks the
--     end of the snippet.
module('_m.textadept.snippets', package.seeall)

-- options
local MARK_SNIPPET   = 4
local SCOPES_ENABLED = true
local MARK_SNIPPET_COLOR = 0x4D9999
local DEBUG = false
local RUN_TESTS = false
-- end options

---
-- Global container that holds all snippet definitions.
-- @class table
-- @name snippets
_G.snippets = {}

-- some default snippets
_G.snippets.file = "$(buffer.filename)"
_G.snippets.path = "$((buffer.filename or ''):match('^.+/))"
_G.snippets.tab  = "\${${1:1}:${2:default}}"
_G.snippets.key  = "['${1:}'] = { ${2:func}${3:, ${4:arg}} }"

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

-- local functions
local next_snippet_item
local snippet_text, match_indention, join_lines, load_scopes
local escape, unescape, remove_escapes, _DEBUG

---
-- Begins expansion of a snippet.
-- @param snippet_arg Optional snippet to expand. If none is specified, the
--   snippet is determined from the trigger word to the left of the caret, the
--   lexer, and scope.
function insert(snippet_arg)
  local buffer = buffer
  local orig_pos, new_pos, s_name
  local sel_text = buffer:get_sel_text()
  if not snippet_arg then
    orig_pos = buffer.current_pos buffer:word_left_extend()
    new_pos = buffer.current_pos
    lexer = buffer:get_lexer_language()
    style = buffer.style_at[orig_pos]
    scope = buffer:get_style_name(style)
    s_name = buffer:get_sel_text()
  else
    if buffer.current_pos > buffer.anchor then
      buffer.current_pos, buffer.anchor = buffer.anchor, buffer.current_pos
    end
    orig_pos, new_pos = buffer.current_pos, buffer.current_pos
  end

  -- Get snippet text by lexer, scope, and/or trigger word.
  local s_text
  if s_name then
    _DEBUG('s_name: '..s_name..', lexer: '..lexer..', scope: '..scope)
    local function try_get_snippet(...)
      local table = _G.snippets
      for _, idx in ipairs(arg) do table = table[idx] end
      if table and type(table) == 'string' then return table end
    end
    local ret
    if SCOPES_ENABLED then
      ret, s_text = pcall(try_get_snippet, lexer, scope, s_name)
    end
    if not ret then ret, s_text = pcall(try_get_snippet, lexer, s_name) end
    if not ret then ret, s_text = pcall(try_get_snippet, s_name) end
  else
    s_text = snippet_arg
  end

  buffer:begin_undo_action()
  if s_text then
    s_text = escape(s_text)
    _DEBUG('s_text escaped:\n'..s_text)

    -- Replace Lua code return.
    local env = setmetatable({ selected_text = sel_text }, { __index = _G })
    s_text = s_text:gsub('$(%b())',
      function(s)
        local f = loadstring('return '..s:sub(2, -2))
        setfenv(f, env)
        local ret, val = pcall(f)
        if ret then return val or '' end
        buffer:goto_pos(orig_pos)
        error(val)
      end)

    -- Execute any shell code.
    s_text = s_text:gsub('`(.-)`',
      function(code)
        local p = io.popen(code)
        local out = p:read('*all')
        p:close()
        if out:sub(-1) == '\n' then return out:sub(1, -2) end
      end)

    -- If another snippet is running, push it onto the stack.
    if snippet.index then snippet_stack[#snippet_stack + 1] = snippet end

    snippet = {}
    snippet.index = 0
    snippet.start_pos = buffer.current_pos
    snippet.cursor = nil
    snippet.sel_text = sel_text

    -- Make a table of placeholders and tab stops.
    local patt, patt2 = '($%b{})', '^%${(%d+):.*}$'
    local s, _, item = s_text:find(patt)
    while item do
      local num = item:match(patt2)
      if num then snippet[tonumber(num)] = unescape(item) end
      local i = s + 1
      s, _, item = s_text:find(patt, i)
    end

    s_text = unescape(s_text)
    _DEBUG('s_text unescaped:\n'..s_text)

    -- Insert the snippet and set a mark defining the end of it.
    buffer:replace_sel(s_text)
    buffer:new_line()
    local line = buffer:line_from_position(buffer.current_pos)
    snippet.end_marker = buffer:marker_add(line, MARK_SNIPPET)
    buffer:marker_set_back(MARK_SNIPPET, MARK_SNIPPET_COLOR)
    _DEBUG('snippet:')
    if DEBUG then table.foreach(snippet, print) end

    -- Indent all lines inserted.
    buffer.current_pos = new_pos
    local count, i = -1, -1
    repeat
      count = count + 1
      i = s_text:find('\n', i + 1)
    until i == nil
    match_indention(buffer:line_from_position(orig_pos), count)
  else
    buffer:goto_pos(orig_pos)
  end
  buffer:end_undo_action()

  next_snippet_item()
end

---
-- [Local function] Mirrors or transforms the most recently modified field in
-- the current snippet and moves on to the next field.
next_snippet_item = function()
  if not snippet.index then return end
  local buffer = buffer
  local s_start, s_end, s_text = snippet_text()

  -- If something went wrong and the snippet has been 'messed' up
  -- (e.g. by undo/redo commands).
  if not s_text then cancel_current() return end

  -- Mirror and transform.
  buffer:begin_undo_action()
  if snippet.index > 0 then
    if snippet.cursor then
      buffer:set_sel(snippet.cursor, buffer.current_pos)
    else
      buffer:word_left_extend()
    end
    local last_item = buffer:get_sel_text()
    _DEBUG('last_item:\n'..last_item)

    buffer:set_sel(s_start, s_end)
    s_text = escape(s_text)
    _DEBUG('s_text escaped:\n'..s_text)

    -- Regex mirror.
    patt = '%${'..snippet.index..'/(.-)/(.-)/([iomxneus]*)}'
    s_text =
      s_text:gsub(patt,
        function(pattern, replacement, options)
          local script = [[
            li  = %q(last_item)
            rep = %q(replacement)
            li  =~ /pattern/options
            if data = $~
              rep.gsub!(/\#\{(.+?)\}/) do
                expr = $1.gsub(/\$(\d\d?)/, 'data[\1]')
                eval expr
              end
              puts rep.gsub(/\$(\d\d?)/) { data[$1.to_i] }
            end
          ]]
          pattern     = unescape(pattern)
          replacement = unescape(replacement)
          script = script:gsub('last_item', last_item)
          script = script:gsub('pattern', pattern)
          script = script:gsub('options', options)
          script = script:gsub('replacement', replacement)
          _DEBUG('script:\n'..script)

          local p = io.popen("ruby 2>&1 <<'_EOF'\n"..script..'\n_EOF')
          local out = p:read('*all')
          p:close()
          _DEBUG('regex out:\n'..out)
          if out:sub(-1) == '\n' then out = out:sub(1, -2) end -- chomp
          return out
        end)
    _DEBUG('patterns replaced:\n'..s_text)

    -- Plain text mirror.
    local mirror = '%${'..snippet.index..'}'
    s_text = s_text:gsub(mirror, last_item)
    _DEBUG('mirrors replaced:\n'..s_text)
  else
    s_text = escape(s_text)
    _DEBUG('s_text escaped:\n'..s_text)
  end
  buffer:end_undo_action()

  buffer:set_sel(s_start, s_end)

  -- Find next snippet item or finish.
  buffer:begin_undo_action()
  snippet.index = snippet.index + 1
  if snippet[snippet.index] then
    _DEBUG('next index: '..snippet.index)
    local s = s_text:find('${'..snippet.index..':')
    local next_item = s_text:match('($%b{})', s)
    s_text = unescape(s_text)
    _DEBUG('s_text unescaped:\n'..s_text)
    buffer:replace_sel(s_text)
    if s and next_item then
      next_item = unescape(next_item)
      _DEBUG('next_item:\n'..next_item)
      local s, e
      buffer.target_start, buffer.target_end = s_start, buffer.length
      buffer.search_flags = 0
      if buffer:search_in_target(next_item) ~= -1 then
        s, e = buffer.target_start, buffer.target_end
      end
      if s and e then
        buffer:set_sel(s, e)
        snippet.cursor = s
        local patt = '^%${'..snippet.index..':(.*)}$'
        local default = next_item:match(patt)
        buffer:replace_sel(default)
        buffer:set_sel(s, s + #default)
      else
        _DEBUG('search failed:\n'..next_item)
        next_snippet_item()
      end
    else
      _DEBUG('no item for '..snippet.index)
      next_snippet_item()
    end
  else -- finished
    _DEBUG('snippet finishing...')
    s_text = s_text:gsub('${0}', '$CURSOR', 1)
    s_text = unescape(s_text)
    _DEBUG('s_text unescaped:\n'..s_text)
    s_text = remove_escapes(s_text)
    _DEBUG('s_text escapes removed:\n'..s_text)
    buffer:replace_sel(s_text)
    local _, s_end = snippet_text()
    if s_end then
      -- Compensate for extra char in CR+LF line endings.
      if buffer.eol_mode == 0 then s_end = s_end - 1 end
      buffer:goto_pos(s_end)
      join_lines()
    end

    local s, e
    buffer.target_start, buffer.target_end = s_start, buffer.length
    buffer.search_flags = 4
    if buffer:search_in_target('$CURSOR') ~= -1 then
      s, e = buffer.target_start, buffer.target_end
    end
    if s and e then
      buffer:set_sel(s, e)
      buffer:replace_sel('')
    else
      buffer:goto_pos(s_end) -- at snippet end marker
    end
    buffer:marker_delete_handle(snippet.end_marker)
    snippet = {}

    -- Restore previous running snippet (if any).
    if #snippet_stack > 0 then snippet = table.remove(snippet_stack) end
  end
  buffer:end_undo_action()
end

---
-- Cancels active snippet, reverting to the state before the snippet was
-- activated.
function cancel_current()
  if not snippet.index then return end
  local buffer = buffer
  local s_start, s_end = snippet_text()
  if s_start and s_end then
    buffer:set_sel(s_start, s_end)
    buffer:replace_sel('')
    join_lines()
  end
  if snippet.sel_text then
    buffer:add_text(snippet.sel_text)
    buffer.anchor = buffer.anchor - #snippet.sel_text
  end
  buffer:marker_delete_handle(snippet.end_marker)
  snippet = {}

  -- Restore previous running snippet (if any).
  if #snippet_stack > 0 then snippet = table.remove(snippet_stack) end
end

---
-- Lists available snippet triggers as an autocompletion list.
-- Global snippets and snippets in the current lexer and scope are used.
function list()
  local buffer = buffer
  local list = {}

  local function add_snippets(snippets)
    for s_name in pairs(snippets) do table.insert(list, s_name) end
  end

  local snippets = _G.snippets
  add_snippets(snippets)
  if SCOPES_ENABLED then
    local lexer = buffer:get_lexer_language()
    local style = buffer.style_at[buffer.current_pos]
    local scope = buffer:get_style_name(style)
    if snippets[lexer] and type(snippets[lexer]) == 'table' then
      add_snippets(snippets[lexer])
      if snippets[lexer][scope] then add_snippets(snippets[lexer][scope]) end
    end
  end
  table.sort(list)

  buffer:auto_c_show(0,
                     table.concat(list, string.char(buffer.auto_c_separator)))
end

---
-- Shows the scope/style at the current caret position as a call tip.
function show_scope()
  if not SCOPES_ENABLED then print('Scopes disabled') return end
  local buffer = buffer
  local lexer = buffer:get_lexer_language()
  local scope = buffer.style_at[buffer.current_pos]
  local text =
    string.format(textadept.locale.M_TEXTADEPT_SNIPPETS_SHOW_STYLE, lexer,
                  style, style_num)
  buffer:call_tip_show(buffer.current_pos, text)
end

---
-- [Local function] Gets the text of the snippet.
-- This is the text bounded by the start of the trigger word to the end snippet
-- marker on the line after the snippet's end.
snippet_text = function()
  local buffer = buffer
  local s = snippet.start_pos
  local e =
    buffer:position_from_line(
      buffer:marker_line_from_handle(snippet.end_marker) ) - 1
  if e >= s then return s, e, buffer:text_range(s, e) end
end

---
-- [Local function] Replaces escaped snippet characters with their octal
-- equivalents.
escape = function(text)
  return text:gsub('\\([$/}`])',
    function(char)
      return ("\\%03d"):format(char:byte())
    end)
end

---
-- [Local function] Replaces octal snippet characters with their escaped
-- equivalents.
unescape = function(text)
  return text:gsub('\\(%d%d%d)',
    function(value)
      return '\\'..string.char(value)
    end)
end

---
-- [Local function] Removes escaping forward-slashes from escaped snippet
-- characters.
-- At this point, they are no longer necessary.
remove_escapes = function(text) return text:gsub('\\([$/}`])', '%1') end

---
-- [Local function] When snippets are inserted, matches their indentation level
-- with their surroundings.
match_indention = function(ref_line, num_lines)
  if num_lines == 0 then return end
  local buffer = buffer
  local isize = buffer.indent
  local ibase = buffer.line_indentation[ref_line]
  local inum  = ibase / isize -- num of indents needed to match
  local line = ref_line + 1
  for i = 0, num_lines - 1 do
    local linei = buffer.line_indentation[line + i]
    buffer.line_indentation[line + i] = linei + isize * inum
  end
end

---
-- [Local function] Joins current line with the line below it, eliminating
-- whitespace.
-- This is used to remove the empty line containing the end of snippet marker.
join_lines = function()
  local buffer = buffer
  buffer:line_down()
  buffer:vc_home()
  if buffer.column[buffer.current_pos] == 0 then buffer:vc_home() end
  buffer:home_extend()
  if #buffer:get_sel_text() > 0 then buffer:delete_back() end
  buffer:delete_back()
end

---
-- [Local function] Prints debug text if the DEBUG flag is set.
-- @param text Debug text to print.
_DEBUG = function(text) if DEBUG then print('---\n'..text) end end

-- run tests
if RUN_TESTS then
  function next_item() next_snippet_item() end
  if not package.path:find(_HOME) then
    package.path = package.path..';'.._HOME..'/scripts/'
  end
  require 'utils/test_snippets'
end

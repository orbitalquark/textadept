-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Editing commands for the textadept module.
module('_m.textadept.editing', package.seeall)

---
-- [Local table] The kill-ring.
-- @class table
-- @name kill_ring
-- @field maxn The maximum size of the kill-ring.
local kill_ring = { pos = 1, maxn = 10 }

---
-- [Local table] Character matching.
-- Used for auto-matching parentheses, brackets, braces, and quotes.
-- @class table
-- @name char_matches
local char_matches = {
  ['('] = ')', ['['] = ']', ['{'] = '}',
  ["'"] = "'", ['"'] = '"'
}

---
-- [Local table] Brace characters.
-- Used for going to matching brace positions.
-- @class table
-- @name braces
local braces = { -- () [] {} <>
  [40] = 1, [91] = 1, [123] = 1, [60] = 1,
  [41] = 1, [93] = 1, [125] = 1, [62] = 1,
}

---
-- [Local table] The current call tip.
-- Used for displaying call tips.
-- @class table
-- @name current_call_tip
local current_call_tip = {}

---
-- [Local table] Enclosures for enclosing or selecting ranges of text.
-- Note chars and tag enclosures are generated at runtime.
-- @class table
-- @name enclosure
local enclosure = {
  dbl_quotes = { left = '"', right = '"' },
  sng_quotes = { left = "'", right = "'" },
  parens     = { left = '(', right = ')' },
  brackets   = { left = '[', right = ']' },
  braces     = { left = '{', right = '}' },
  chars      = { left = ' ', right = ' ' },
  tags       = { left = '>', right = '<' },
  tag        = { left = ' ', right = ' ' },
  single_tag = { left = '<', right = ' />' }
}

---
-- [Local table] Comment strings for various lexer languages.
-- Used for the block_comment function.
-- @class table
-- @name comment_strings
-- @see block_comment
local comment_strings = {
  cpp = '//~',
  lua = '--~',
  python = '#~',
  ruby = '#~',
}

textadept.events.add_handler('char_added',
  function(c) -- matches characters specified in char_matches
    if char_matches[c] then buffer:insert_text(-1, char_matches[c]) end
  end)

textadept.events.add_handler('update_ui',
  function() -- highlights matching braces
    local buffer = buffer
    local current_pos = buffer.current_pos
    if braces[buffer.char_at[current_pos]] and
      buffer:get_style_name(buffer.style_at[current_pos]) == 'operator' then
      local pos = buffer:brace_match(current_pos)
      if pos ~= -1 then
        buffer:brace_highlight(current_pos, pos)
      else
        buffer:brace_bad_light(current_pos)
      end
    else
      buffer:brace_bad_light(-1)
    end
  end)

textadept.events.add_handler('char_added',
  function(char) -- auto-indent on return
    if char ~= '\n' then return end
    local buffer = buffer
    local anchor, caret = buffer.anchor, buffer.current_pos
    local curr_line = buffer:line_from_position(caret)
    local last_line = curr_line - 1
    while last_line >= 0 and #buffer:get_line(last_line) == 1 do
      last_line = last_line - 1
    end
    if last_line >= 0 then
      local indentation = buffer.line_indentation[last_line]
      local s = buffer.line_indent_position[curr_line]
      buffer.line_indentation[curr_line] = indentation
      local e = buffer.line_indent_position[curr_line]
      local diff = e - s
      if e > s then -- move selection on
        if anchor >= s then anchor = anchor + diff end
        if caret  >= s then caret  = caret  + diff end
      elseif e < s then -- move selection back
        if anchor >= e then anchor = anchor >= s and anchor + diff or e end
        if caret  >= e then caret  = caret  >= s and caret  + diff or e end
      end
      buffer:set_sel(anchor, caret)
    end
  end)

-- local functions
local insert_into_kill_ring, scroll_kill_ring
local get_preceding_number, get_sel_or_line

---
-- Goes to a matching brace position, selecting the text inside if specified.
-- @param select If true, selects the text between matching braces.
function match_brace(select)
  local buffer = buffer
  local caret = buffer.current_pos
  local match_pos = buffer:brace_match(caret)
  if match_pos ~= -1 then
    if select then
      if match_pos > caret then
        buffer:set_sel(caret, match_pos + 1)
      else
        buffer:set_sel(caret + 1, match_pos)
      end
    else
      buffer:goto_pos(match_pos)
    end
  end
end

---
-- Pops up an autocompletion list for the current word based on other words in
-- the document.
-- @param word_chars String of chars considered to be part of words.
function autocomplete_word(word_chars)
  local buffer = buffer
  local caret, length = buffer.current_pos, buffer.length
  local completions, c_list = {}, {}
  local buffer_text = buffer:get_text(length)
  local root = buffer_text:sub(1, caret):match('['..word_chars..']+$')
  if not root or #root == 0 then return end
  buffer.target_start, buffer.target_end = 0, buffer.length
  buffer.search_flags = 1048580 -- word start and match case
  local match_pos = buffer:search_in_target(root)
  while match_pos ~= -1 do
    local s, e = buffer_text:find('^['..word_chars..']+', match_pos + 1)
    local match = buffer_text:sub(s, e)
    if not completions[match] and #match > #root then
      c_list[#c_list + 1] = match
      completions[match] = true
    end
    buffer.target_start, buffer.target_end = match_pos + 1, buffer.length
    match_pos = buffer:search_in_target(root)
  end
  if #c_list > 0 then buffer:auto_c_show(#root, table.concat(c_list, ' ')) end
end

---
-- Displays a call tip based on the word to the left of the cursor and a given
-- API table.
-- @param api Table of functions call tips can be displayed for. Each key is a
--   function name, and each value is a table of tables. Each of those tables
--   represents a function. It has 2 indexes: parameters and a description.
--   This enables call tips for 'overloaded' functions. Even if there is just
--   one function, it must be enclosed in a table. You can get an API table
--   from a file via textadept.io.read_api_file().
-- @param start Flag indicating whether or not to start a call tip. If the user
--   clicks an arrow, you should call show_call_tip again with this value being
--   false to display the next function.
-- @see textadept.io.read_api_file
function show_call_tip(api, start)
  local buffer = buffer
  local funcs
  local call_tip = ''
  if start then
    local s = buffer:word_start_position(buffer.current_pos - 1, true)
    local word = buffer:text_range(s, buffer.current_pos)
    funcs = api[word]
    if not funcs then return end
    if #funcs > 1 then call_tip = call_tip..'\001' end
    current_call_tip = {
      name = word,
      num = 1,
      max = #funcs,
      start_pos = buffer.current_pos,
      ['api'] = api
    }
  elseif buffer:call_tip_active() and current_call_tip.max > 1 then
    call_tip = call_tip..'\001'
    funcs = api[current_call_tip.name]
  else
    return
  end
  local func = funcs[current_call_tip.num]
  local name = current_call_tip.name
  local params = func[1]
  local desc = #funcs == 1 and func[2] or '\002'..func[2]
  call_tip = call_tip..name..params..'\n'..desc:gsub('\\n', '\n')
  buffer:call_tip_show(current_call_tip.start_pos, call_tip)
end

textadept.events.add_handler('call_tip_click',
  function(position) -- display the next or previous call tip
    if not buffer:call_tip_active() then return end
    if position == 1 and current_call_tip.num > 1 then
      current_call_tip.num = current_call_tip.num - 1
      show_call_tip(current_call_tip.api, false)
    elseif position == 2 and current_call_tip.num < current_call_tip.max then
      current_call_tip.num = current_call_tip.num + 1
      show_call_tip(current_call_tip.api, false)
    end
  end)

---
-- Block comments or uncomments code with a given comment string.
-- @param comment The comment string inserted or removed from the beginning of
--   each line in the selection.
function block_comment(comment)
  local buffer = buffer
  if not comment then
    comment = comment_strings[buffer:get_lexer_language()]
    if not comment then return end
  end
  local caret, anchor = buffer.current_pos, buffer.anchor
  if caret < anchor then anchor, caret = caret, anchor end
  local s = buffer:line_from_position(anchor)
  local e = buffer:line_from_position(caret)
  local mlines = s ~= e
  if mlines and caret == buffer:position_from_line(e) then e = e - 1 end
  buffer:begin_undo_action()
  for line = s, e do
    local pos = buffer:position_from_line(line)
    if buffer:text_range(pos, pos + #comment) == comment then
      buffer:set_sel(pos, pos + #comment)
      buffer:replace_sel('')
      caret = caret - #comment
    else
      buffer:insert_text(pos, comment)
      caret = caret + #comment
    end
  end
  buffer:end_undo_action()
  if mlines then buffer:set_sel(anchor, caret) else buffer:goto_pos(caret) end
end

---
-- Goes to the requested line.
-- @param line Optional line number to go to.
function goto_line(line)
  local buffer = buffer
  if not line then
    line =
      cocoa_dialog('standard-inputbox', {
        title = locale.M_TEXTADEPT_EDITING_GOTO_TITLE,
        text = locale.M_TEXTADEPT_EDITING_GOTO_TEXT,
        ['no-newline'] = true
      })
    line = tonumber(line:match('%-?%d+$'))
    if not line or line < 0 then return end
  end
  buffer:ensure_visible_enforce_policy(line - 1)
  buffer:goto_line(line - 1)
end

---
-- Prepares the buffer for saving to a file.
-- Strips trailing whitespace off of every line, ensures an ending newline, and
-- converts non-consistent EOLs.
function prepare_for_save()
  local buffer = buffer
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  local lines = buffer.line_count
  for line = 0, lines - 1 do
    local s = buffer:position_from_line(line)
    local e = buffer.line_end_position[line]
    local i = e - 1
    local c = buffer.char_at[i]
    while i >= s and c == 9 or c == 32 do
      i = i - 1
      c = buffer.char_at[i]
    end
    if i < e - 1 then
      buffer.target_start, buffer.target_end = i + 1, e
      buffer:replace_target('')
    end
  end
  -- Ensure ending newline.
  local e = buffer:position_from_line(lines)
  if lines == 1 or
    lines > 1 and e > buffer:position_from_line(lines - 1) then
    buffer:insert_text(e, '\n')
  end
  -- Convert non-consistent EOLs
  buffer:convert_eo_ls(buffer.eol_mode)
  buffer:end_undo_action()
end

---
-- Cuts or copies text ranges intelligently. (Behaves like Emacs.)
-- If no text is selected, all text from the cursor to the end of the line is
-- cut or copied as indicated by action and pushed onto the kill-ring. If there
-- is text selected, it is cut or copied and pushed onto the kill-ring.
-- @param copy If false, the text is cut. Otherwise it is copied.
-- @see insert_into_kill_ring
function smart_cutcopy(copy)
  local buffer = buffer
  local txt = buffer:get_sel_text()
  if #txt == 0 then buffer:line_end_extend() end
  txt = buffer:get_sel_text()
  insert_into_kill_ring(txt)
  kill_ring.pos = 1
  if copy then buffer:copy() else buffer:cut() end
end

---
-- Retrieves the top item off the kill-ring and pastes it.
-- If an action is specified, the text is kept selected for scrolling through
-- the kill-ring.
-- @param action If given, specifies whether to cycle through the kill-ring in
--   normal or reverse order. A value of 'cycle' cycles through normally,
--   'reverse' in reverse.
-- @param reindent Flag indicating whether or not to reindent the pasted text.
-- @see scroll_kill_ring
function smart_paste(action, reindent)
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  if caret < anchor then anchor = caret end
  local txt = buffer:get_sel_text()
  if txt == kill_ring[kill_ring.pos] then scroll_kill_ring(action) end

  -- If text was copied to the clipboard from other apps, insert it into the
  -- kill-ring so it can be pasted (thanks to Nathan Robinson).
  local clip_txt, found = textadept.clipboard_text, false
  if clip_txt ~= '' then
    for _, ring_txt in ipairs(kill_ring) do
      if clip_txt == ring_txt then found = true break end
    end
  end
  if not found then insert_into_kill_ring(clip_txt) end

  txt = kill_ring[kill_ring.pos]
  if txt then
    if reindent then
      local indent =
        buffer.line_indentation[
          buffer:line_from_position(buffer.current_pos)]
      local padding =
        string.rep(buffer.use_tabs and '\t' or ' ',
                   buffer.use_tabs and indent / buffer.tab_width or indent)
      txt = txt:gsub('\n', '\n'..padding)
    end
    buffer:replace_sel(txt)
    if action then buffer.anchor = anchor end -- cycle
  end
end

---
-- Selects the current word under the caret and if action indicates, deletes it.
-- @param action Optional action to perform with selected word. If 'delete', it
--   is deleted.
function current_word(action)
  local buffer = buffer
  local s = buffer:word_start_position(buffer.current_pos)
  local e = buffer:word_end_position(buffer.current_pos)
  buffer:set_sel(s, e)
  if action == 'delete' then buffer:delete_back() end
end

---
-- Transposes characters intelligently.
-- If the caret is at the end of the current word, the two characters before
-- the caret are transposed. Otherwise the characters to the left and right of
-- the caret are transposed.
function transpose_chars()
  local buffer = buffer
  buffer:begin_undo_action()
  local caret = buffer.current_pos
  local char = buffer.char_at[caret - 1]
  buffer:delete_back()
  if caret > buffer.length or buffer.char_at[caret - 1] == 32 then
    buffer:char_left()
  else
    buffer:char_right()
  end
  buffer:insert_text(-1, string.char(char))
  buffer:end_undo_action()
  buffer:goto_pos(caret)
end

---
-- Reduces multiple characters occurances to just one.
-- If char is not given, the character to be squeezed is the one under the
-- caret.
-- @param char The character (integer) to be used for squeezing.
function squeeze(char)
  local buffer = buffer
  if not char then char = buffer.char_at[buffer.current_pos - 1] end
  local s, e = buffer.current_pos - 1, buffer.current_pos - 1
  while buffer.char_at[s] == char do s = s - 1 end
  while buffer.char_at[e] == char do e = e + 1 end
  buffer:set_sel(s + 1, e)
  buffer:replace_sel(string.char(char))
end

---
-- Joins the current line with the line below, eliminating whitespace.
function join_lines()
  local buffer = buffer
  buffer:begin_undo_action()
  buffer:line_end()
  buffer:clear()
  buffer:add_text(' ')
  squeeze()
  buffer:end_undo_action()
end

---
-- Encloses text in an enclosure set.
-- If text is selected, it is enclosed. Otherwise, the previous word is
-- enclosed. The n previous words can be enclosed by appending n (a number) to
-- the end of the last word. When enclosing with a character, append the
-- character to the end of the word(s). To enclose previous word(s) with n
-- characters, append n (a number) to the end of character set.
-- Examples:
--   enclose this2 -> 'enclose this' (enclose in sng_quotes)
--   enclose this2**2 -> **enclose this**
-- @param str The enclosure type in enclosure.
-- @see enclosure
-- @see get_preceding_number
function enclose(str)
  local buffer = buffer
  buffer:begin_undo_action()
  local txt = buffer:get_sel_text()
  if txt == '' then
    if str == 'chars' then
      local num_chars, len_num_chars = get_preceding_number()
      for i = 1, len_num_chars do buffer:delete_back() end
      for i = 1, num_chars do buffer:char_left_extend() end
      enclosure[str].left  = buffer:get_sel_text()
      enclosure[str].right = enclosure[str].left
      buffer:delete_back()
    end
    local num_words, len_num_chars = get_preceding_number()
    for i = 1, len_num_chars do buffer:delete_back() end
    for i = 1, num_words do buffer:word_left_extend() end
    txt = buffer:get_sel_text()
  end
  local len = 0
  if str == 'tag' then
    enclosure[str].left  = '<'..txt..'>'
    enclosure[str].right = '</'..txt..'>'
    len = #txt + 3
    txt = ''
  end
  local left  = enclosure[str].left
  local right = enclosure[str].right
  buffer:replace_sel(left..txt..right)
  if str == 'tag' then buffer:goto_pos(buffer.current_pos - len) end
  buffer:end_undo_action()
end

---
-- Selects text in a specified enclosure.
-- @param str The enclosure type in enclosure. If str is not specified,
--   matching character pairs defined in char_matches are searched for from the
--   caret outwards.
-- @see enclosure
-- @see char_matches
function select_enclosed(str)
  local buffer = buffer
  if str then
    buffer:search_anchor()
    local s = buffer:search_prev(0, enclosure[str].left)
    local e = buffer:search_next(0, enclosure[str].right)
    if s and e then buffer:set_sel(s + 1, e) end
  end
end

---
-- Grows the selection by a character amount on either end.
-- @param amount The amount to grow the selection on either end.
function grow_selection(amount)
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  if anchor < caret then
    buffer:set_sel(anchor - amount, caret + amount)
  else
    buffer:set_sel(anchor + amount, caret - amount)
  end
end

---
-- Selects the current line.
function select_line()
  local buffer = buffer
  buffer:home()
  buffer:line_end_extend()
end

---
-- Selects the current paragraph.
-- Paragraphs are delimited by two or more consecutive newlines.
function select_paragraph()
  local buffer = buffer
  buffer:para_up()
  buffer:para_down_extend()
end

---
-- Selects indented blocks intelligently.
-- If no block of text is selected, all text with the current level of
-- indentation is selected. If a block of text is selected and the lines to the
-- top and bottom of it are one indentation level lower, they are added to the
-- selection. In all other cases, the behavior is the same as if no text is
-- selected.
function select_indented_block()
  local buffer = buffer
  local s = buffer:line_from_position(buffer.anchor)
  local e = buffer:line_from_position(buffer.current_pos)
  if s > e then s, e = e, s end
  local indent = buffer.line_indentation[s] - buffer.indent
  if indent < 0 then return end
  if buffer:get_sel_text() ~= '' then
    if buffer.line_indentation[s - 1] == indent and
      buffer.line_indentation[e + 1] == indent then
      s, e = s - 1, e + 1
      indent = indent + buffer.indent -- don't run while loops
    end
  end
  while buffer.line_indentation[s - 1] > indent do s = s - 1 end
  while buffer.line_indentation[e + 1] > indent do e = e + 1 end
  s = buffer:position_from_line(s)
  e = buffer.line_end_position[e]
  buffer:set_sel(s, e)
end

---
-- Selects all text with the same scope/style as under the caret.
function select_scope()
  local buffer = buffer
  local start_pos = buffer.current_pos
  local base_style = buffer.style_at[start_pos]
  local pos = start_pos - 1
  while buffer.style_at[pos] == base_style do pos = pos - 1 end
  local start_style = pos
  pos = start_pos + 1
  while buffer.style_at[pos] == base_style do pos = pos + 1 end
  buffer:set_sel(start_style + 1, pos)
end

---
-- Converts indentation between tabs and spaces.
function convert_indentation()
  local buffer = buffer
  buffer:begin_undo_action()
  for line = 0, buffer.line_count do
    local s = buffer:position_from_line(line)
    local indent = buffer.line_indentation[line]
    local indent_pos = buffer.line_indent_position[line]
    current_indentation = buffer:text_range(s, indent_pos)
    if buffer.use_tabs then
      new_indentation = ('\t'):rep(indent / buffer.tab_width)
    else
      new_indentation = (' '):rep(indent)
    end
    if current_indentation ~= new_indentation then
      buffer.target_start = s
      buffer.target_end = indent_pos
      buffer:replace_target(new_indentation)
    end
  end
  buffer:end_undo_action()
end

---
-- [Local function] Inserts text into kill_ring.
-- If it grows larger than maxn, the oldest inserted text is replaced.
-- @see smart_cutcopy
insert_into_kill_ring = function(txt)
  table.insert(kill_ring, 1, txt)
  local maxn = kill_ring.maxn
  if #kill_ring > maxn then kill_ring[maxn + 1] = nil end
end

---
-- [Local function] Scrolls kill_ring in the specified direction.
-- @param direction The direction to scroll: 'forward' (default) or 'reverse'.
-- @see smart_paste
scroll_kill_ring = function(direction)
  if direction == 'reverse' then
    kill_ring.pos = kill_ring.pos - 1
    if kill_ring.pos < 1 then kill_ring.pos = #kill_ring end
  else
    kill_ring.pos = kill_ring.pos + 1
    if kill_ring.pos > #kill_ring then kill_ring.pos = 1 end
  end
end

---
-- [Local function] Returns the number to the left of the caret.
-- This is used for the enclose function.
-- @see enclose
get_preceding_number = function()
  local buffer = buffer
  local caret = buffer.current_pos
  local char = buffer.char_at[caret - 1]
  local txt = ''
  while tonumber(string.char(char)) do
    txt = txt..string.char(char)
    caret = caret - 1
    char = buffer.char_at[caret - 1]
  end
  return tonumber(txt) or 1, #txt
end

---
-- [Local function] Returns the current selection or the contents of the
-- current line.
get_sel_or_line = function()
  local buffer = buffer
  if buffer:get_sel_text() == '' then select_line() end
  return buffer:get_sel_text()
end

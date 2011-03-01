-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local events = _G.events
local K = keys.KEYSYMS

---
-- Editing commands for the textadept module.
module('_m.textadept.editing', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `AUTOPAIR`: Flag indicating whether or not when an opening `(`, `[`, `[`,
--   `"`, or `'` is typed, its closing complement character is automatically
--   inserted.
-- * `HIGHLIGHT_BRACES`: Flag indicating whether or not when the caret is over a
--   brace character (any of the following: `()[]{}<>`), its matching complement
--   brace is highlighted.
-- * `AUTOINDENT`: Flag indicating whether or not when the enter key is pressed,
--   the inserted line has is indented to match the level of indentation of the
--   previous line.
-- * `SAVE_STRIPS_WS`: Flag indicating whether or not to strip trailing
--   whitespace on file save.
-- * `MARK_HIGHLIGHT`: The unique integer mark used to identify a line
--   containing a highlighted word.
-- * `MARK_HIGHLIGHT_BACK`: The [Scintilla color][scintilla_color] used for a
--   line containing a highlighted word.
-- * `INDIC_HIGHLIGHT`: The unique integer indicator for highlighted words.
-- * `INDIC_HIGHLIGHT_BACK`: The [Scintilla color][scintilla_color] used for an
--   indicator for a highlighted word.
-- * `INDIC_HIGHLIGHT_ALPHA`: The transparency used for an indicator for a
--   highlighted word.

-- settings
AUTOPAIR = true
HIGHLIGHT_BRACES = true
AUTOINDENT = true
SAVE_STRIPS_WS = true
MARK_HIGHLIGHT = 2
MARK_HIGHLIGHT_BACK = buffer and buffer.caret_line_back or 0xEEEEEE
INDIC_HIGHLIGHT = 8 -- INDIC_CONTAINER
INDIC_HIGHLIGHT_BACK = 0x4080C0
INDIC_HIGHLIGHT_ALPHA = 100
-- end settings

---
-- Comment strings for various lexer languages.
-- Used for the block_comment() function. Keys are lexer language names and
-- values are the line comment delimiters for the language. This table is
-- typically populated by language-specific modules.
-- @class table
-- @name comment_string
-- @see block_comment
comment_string = {}

---
-- Auto-matched characters.
-- Used for auto-matching parentheses, brackets, braces, quotes, etc. Keys are
-- lexer language names and values are tables of character match pairs. This
-- table can be populated by language-specific modules.
-- @class table
-- @name char_matches
-- @usage _m.textadept.editing.char_matches.hypertext = { ..., [60] = '>' }
char_matches = {
  [40] = ')', [91] = ']', [123] = '}', [39] = "'", [34] = '"'
}

---
-- Highlighted brace characters.
-- Keys are lexer language names and values are tables of characters that count
-- as brace characters. This table can be populated by language-specific
-- modules.
-- @class table
-- @name braces
-- @usage _m.textadept.editing.braces.hypertext = { ..., [60] = 1, [62] = 1 }
braces = { -- () [] {}
  [40] = 1, [91] = 1, [123] = 1,
  [41] = 1, [93] = 1, [125] = 1,
}

-- The current call tip.
-- Used for displaying call tips.
-- @class table
-- @name current_call_tip
local current_call_tip = {}

-- Matches characters specified in char_matches.
events.connect('char_added', function(c)
  if not AUTOPAIR then return end
  local buffer = buffer
  local match = (char_matches[buffer:get_lexer()] or char_matches)[c]
  if match and buffer.selections == 1 then buffer:insert_text(-1, match) end
end)

-- Removes matched chars on backspace.
events.connect('keypress', function(code, shift, control, alt)
  if not AUTOPAIR or K[code] ~= '\b' or buffer.selections ~= 1 then return end
  local buffer = buffer
  local pos = buffer.current_pos
  local c = buffer.char_at[pos - 1]
  local match = (char_matches[buffer:get_lexer()] or char_matches)[c]
  if match and buffer.char_at[pos] == string.byte(match) then buffer:clear() end
end)

-- Highlights matching braces.
events.connect('update_ui', function()
  if not HIGHLIGHT_BRACES then return end
  local buffer = buffer
  local current_pos = buffer.current_pos
  if (braces[buffer:get_lexer()] or braces)[buffer.char_at[current_pos]] then
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

-- Auto-indent on return.
events.connect('char_added', function(char)
  if not AUTOINDENT or char ~= 10 then return end
  local buffer = buffer
  local anchor, caret = buffer.anchor, buffer.current_pos
  local line = buffer:line_from_position(caret)
  local pline = line - 1
  while pline >= 0 and #buffer:get_line(pline) == 1 do pline = pline - 1 end
  if pline >= 0 then
    local indentation = buffer.line_indentation[pline]
    local s = buffer.line_indent_position[line]
    buffer.line_indentation[line] = indentation
    local e = buffer.line_indent_position[line]
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
-- @return true if there were completions to show; false otherwise.
function autocomplete_word(word_chars)
  local buffer = buffer
  local caret, length = buffer.current_pos, buffer.length
  local completions, c_list = {}, {}
  local buffer_text = buffer:get_text(buffer.length)
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
  if #c_list > 0 then
    buffer:auto_c_show(#root, table.concat(c_list, ' '))
    return true
  end
end

---
-- Block comments or uncomments code with a given comment string.
-- @param comment The comment string inserted or removed from the beginning of
--   each line in the selection.
function block_comment(comment)
  local buffer = buffer
  if not comment then
    comment = comment_string[buffer:get_lexer()]
    if not comment then return end
  end
  local anchor, caret = buffer.selection_start, buffer.selection_end
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
  if not line then
    line = tonumber(gui.dialog('standard-inputbox',
                               '--title', L('Go To'),
                               '--text', L('Line Number:'),
                               '--no-newline'):match('%-?%d+$'))
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
  if not SAVE_STRIPS_WS then return end
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
events.connect('file_before_save', prepare_for_save)

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
-- If the caret is at the end of a line, the two characters before the caret are
-- transposed. Otherwise, the characters to the left and right are.
function transpose_chars()
  local buffer = buffer
  buffer:begin_undo_action()
  local pos = buffer.current_pos
  local c1, c2 = buffer.char_at[pos - 1], buffer.char_at[pos]
  buffer:delete_back()
  buffer:insert_text((c2 == 10 or c2 == 13) and pos - 2 or pos, string.char(c1))
  buffer:end_undo_action()
  buffer:goto_pos(pos)
end

---
-- Joins the current line with the line below.
function join_lines()
  local buffer = buffer
  buffer:line_end()
  local line = buffer:line_from_position(buffer.current_pos)
  buffer.target_start = buffer.current_pos
  buffer.target_end = buffer:position_from_line(line + 1)
  buffer:lines_join()
end

---
-- Encloses text within a given pair of strings.
-- If text is selected, it is enclosed. Otherwise, the previous word is
-- enclosed.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
function enclose(left, right)
  local buffer = buffer
  buffer:begin_undo_action()
  local txt = buffer:get_sel_text()
  if #txt == 0 then
    buffer:word_left_extend()
    txt = buffer:get_sel_text()
  end
  buffer:replace_sel(left..txt..right)
  buffer:end_undo_action()
end

---
-- Selects text between a given pair of strings.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
function select_enclosed(left, right)
  local buffer = buffer
  buffer:search_anchor()
  local s = buffer:search_prev(0, left)
  local e = buffer:search_next(0, right)
  if s and e then buffer:set_sel(s + 1, e) end
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
  buffer:home()
  buffer:line_end_extend()
end

---
-- Selects the current paragraph.
-- Paragraphs are delimited by two or more consecutive newlines.
function select_paragraph()
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
  local s = buffer:line_from_position(buffer.selection_start)
  local e = buffer:line_from_position(buffer.selection_end)
  local indent = buffer.line_indentation[s] - buffer.indent
  if indent < 0 then return end
  if buffer:get_sel_text() ~= '' then
    if buffer.line_indentation[s - 1] == indent and
       buffer.line_indentation[e + 1] == indent then
      s, e = s - 1, e + 1
      indent = indent + buffer.indent -- do not run while loops
    end
  end
  while buffer.line_indentation[s - 1] > indent do s = s - 1 end
  while buffer.line_indentation[e + 1] > indent do e = e + 1 end
  s, e = buffer:position_from_line(s), buffer.line_end_position[e]
  buffer:set_sel(s, e)
end

---
-- Selects all text with the same style as under the caret.
function select_scope()
  local buffer = buffer
  local start_pos, length = buffer.current_pos, buffer.length
  local base_style, style_at = buffer.style_at[start_pos], buffer.style_at
  local pos = start_pos - 1
  while pos >= 0 and style_at[pos] == base_style do pos = pos - 1 end
  local start_style = pos
  pos = start_pos + 1
  while pos < length and style_at[pos] == base_style do pos = pos + 1 end
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
      buffer.target_start, buffer.target_end = s, indent_pos
      buffer:replace_target(new_indentation)
    end
  end
  buffer:end_undo_action()
end

-- Clears highlighted word indicators and markers.
local function clear_highlighted_words()
  local buffer = buffer
  buffer:marker_delete_all(MARK_HIGHLIGHT)
  buffer.indicator_current = INDIC_HIGHLIGHT
  buffer:indicator_clear_range(0, buffer.length)
end
events.connect('keypress',
  function(c) if K[c] == 'esc' then clear_highlighted_words() end end)

---
-- Highlights all occurances of the word under the caret and adds markers to the
-- lines they are on.
function highlight_word()
  clear_highlighted_words()
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s, e = buffer:word_start_position(s), buffer:word_end_position(s)
  end
  local word = buffer:text_range(s, e)
  if word == '' then return end
  buffer.search_flags = _SCINTILLA.constants.SCFIND_WHOLEWORD +
                        _SCINTILLA.constants.SCFIND_MATCHCASE
  buffer.target_start = 0
  buffer.target_end = buffer.length
  while buffer:search_in_target(word) > 0 do
    local len = buffer.target_end - buffer.target_start
    buffer:marker_add(buffer:line_from_position(buffer.target_start),
                      MARK_HIGHLIGHT)
    buffer:indicator_fill_range(buffer.target_start, len)
    buffer.target_start = buffer.target_end
    buffer.target_end = buffer.length
  end
  buffer:set_sel(s, e)
end

-- Sets view properties for highlighted word indicators and markers.
local function set_highlight_properties()
  local buffer = buffer
  buffer:marker_set_back(MARK_HIGHLIGHT, MARK_HIGHLIGHT_BACK)
  buffer.indic_fore[INDIC_HIGHLIGHT] = INDIC_HIGHLIGHT_BACK
  buffer.indic_style[INDIC_HIGHLIGHT] = _SCINTILLA.constants.INDIC_ROUNDBOX
  buffer.indic_alpha[INDIC_HIGHLIGHT] = INDIC_HIGHLIGHT_ALPHA
end
if buffer then set_highlight_properties() end
events.connect('view_new', set_highlight_properties)

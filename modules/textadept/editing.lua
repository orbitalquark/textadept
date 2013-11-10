-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Editing features for Textadept.
-- @field AUTOPAIR (bool)
--   Automatically close opening brace and quote characters with their
--   complements.
--   The default value is `true`.
--   Auto-paired characters are defined in the [`char_matches`](#char_matches)
--   table.
-- @field HIGHLIGHT_BRACES (bool)
--   Highlight matching brace characters like "()[]{}".
--   The default value is `true`.
--   Matching braces are defined in the [`braces`](#braces) table.
-- @field TYPEOVER_CHARS (bool)
--   Move over closing brace and quote characters under the caret when typing
--   them instead of inserting them.
--   The default value is `true`.
--   Typeover characters are defined in the [`typeover_chars`](#typeover_chars)
--   table.
-- @field AUTOINDENT (bool)
--   Match the previous line's indentation level after inserting a new line.
--   The default value is `true`.
-- @field STRIP_TRAILING_SPACES (bool)
--   Strip trailing whitespace before saving files.
--   The default value is `true`.
-- @field INDIC_BRACEMATCH (number)
--   The matching brace highlight indicator number.
-- @field INDIC_HIGHLIGHT (number)
--   The word highlight indicator number.
module('textadept.editing')]]

M.AUTOPAIR = true
M.HIGHLIGHT_BRACES = true
M.TYPEOVER_CHARS = true
M.AUTOINDENT = true
M.STRIP_TRAILING_SPACES = true
M.INDIC_BRACEMATCH = _SCINTILLA.next_indic_number()
M.INDIC_HIGHLIGHT = _SCINTILLA.next_indic_number()

---
-- Map of lexer names to line comment strings for programming languages, used by
-- the `block_comment()` function.
-- Keys are lexer names and values are either the language's line comment
-- prefixes or block comment delimiters separated by a '|' character.
-- @class table
-- @name comment_string
-- @see block_comment
M.comment_string = {actionscript='//',ada='--',antlr='//',adpl='!',ansi_c='/*|*/',applescript='--',asp='\'',awk='#',b_lang='//',bash='#',batch=':',bibtex='%',boo='#',chuck='//',cmake='#',coffeescript='#',context='%',cpp='//',csharp='//',css='/*|*/',cuda='//',desktop='#',django='{#|#}',dmd='//',dot='//',eiffel='--',erlang='%',forth='|\\',fortran='!',fsharp='//',gap='#',gettext='#',glsl='//',gnuplot='#',go='//',groovy='//',gtkrc='#',haskell='--',hypertext='<!--|-->',idl='//',inform='!',ini='#',Io='#',java='//',javascript='//',json='/*|*/',jsp='//',latex='%',less='//',lilypond='%',lisp=';',lua='--',makefile='#',matlab='#',nemerle='//',nsis='#',objective_c='//',pascal='//',perl='#',php='//',pike='//',pkgbuild='#',prolog='%',props='#',ps='%',python='#',rails='#',rebol=';',rexx='--',rhtml='<!--|-->',rstats='#',ruby='#',sass='//',scala='//',scheme=';',smalltalk='"|"',sql='#',tcl='#',tex='%',text='',vala='//',vb='\'',vbscript='\'',verilog='//',vhdl='--',xml='<!--|-->'}

---
-- Map of auto-paired characters like parentheses, brackets, braces, and quotes,
-- with language-specific auto-paired character maps assigned to a lexer name
-- key.
-- The ASCII values of opening characters are assigned to strings containing
-- complement characters. The default auto-paired characters are "()", "[]",
-- "{}", "&apos;&apos;", and "&quot;&quot;".
-- @class table
-- @name char_matches
-- @usage textadept.editing.char_matches.hypertext = {..., [60] = '>'}
-- @see AUTOPAIR
M.char_matches = {[40] = ')', [91] = ']', [123] = '}', [39] = "'", [34] = '"'}

---
-- Table of brace characters to highlight, with language-specific brace
-- character tables assigned to a lexer name key.
-- The ASCII values of brace characters are keys and are assigned non-`nil`
-- values. The default brace characters are '(', ')', '[', ']', '{', and '}'.
-- @class table
-- @name braces
-- @usage textadept.editing.braces.hypertext = {..., [60] = 1, [62] = 1}
-- @see HIGHLIGHT_BRACES
M.braces = {[40] = 1, [41] = 1, [91] = 1, [93] = 1, [123] = 1, [125] = 1}

---
-- Table of characters to move over when typed, with language-specific typeover
-- character tables assigned to a lexer name key.
-- The ASCII values of characters are keys and are assigned non-`nil` values.
-- The default characters are ')', ']', '}', '&apos;', and '&quot;'.
-- @class table
-- @name typeover_chars
-- @usage textadept.editing.typeover_chars.hypertext = {..., [62] = 1}
-- @see TYPEOVER_CHARS
M.typeover_chars = {[41] = 1, [93] = 1, [125] = 1, [39] = 1, [34] = 1}

-- Matches characters specified in char_matches.
events.connect(events.CHAR_ADDED, function(c)
  if not M.AUTOPAIR then return end
  local match = (M.char_matches[buffer:get_lexer(true)] or M.char_matches)[c]
  if match and buffer.selections == 1 then buffer:insert_text(-1, match) end
end)

-- Removes matched chars on backspace.
events.connect(events.KEYPRESS, function(code)
  if not M.AUTOPAIR or keys.KEYSYMS[code] ~= '\b' or buffer.selections ~= 1 then
    return
  end
  local pos, char = buffer.current_pos, buffer.char_at[buffer.current_pos - 1]
  local match = (M.char_matches[buffer:get_lexer(true)] or M.char_matches)[char]
  if match and buffer.char_at[pos] == string.byte(match) then buffer:clear() end
end)

-- Highlights matching braces.
events.connect(events.UPDATE_UI, function()
  if not M.HIGHLIGHT_BRACES then return end
  local pos = buffer.current_pos
  if (M.braces[buffer:get_lexer(true)] or M.braces)[buffer.char_at[pos]] then
    local match = buffer:brace_match(pos)
    if match ~= -1 then
      buffer:brace_highlight(pos, match)
    else
      buffer:brace_bad_light(pos)
    end
  else
    buffer:brace_bad_light(-1)
  end
end)

-- Moves over typeover characters when typed.
events.connect(events.KEYPRESS, function(code)
  if not M.TYPEOVER_CHARS then return end
  if M.typeover_chars[code] and buffer.char_at[buffer.current_pos] == code then
    buffer:char_right()
    return true
  end
end)

-- Auto-indent on return.
events.connect(events.CHAR_ADDED, function(char)
  if not M.AUTOINDENT or char ~= 10 then return end
  local buffer = buffer
  local pos = buffer.current_pos
  local line = buffer:line_from_position(pos)
  local i = line - 1
  while i >= 0 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
  if i >= 0 then
    buffer.line_indentation[line] = buffer.line_indentation[i]
    buffer:goto_pos(buffer.line_indent_position[line])
  end
end)

-- Autocomplete multiple selections.
events.connect(events.AUTO_C_SELECTION, function(text, position)
  local buffer = buffer
  local pos = buffer.selection_n_caret[buffer.main_selection]
  buffer:begin_undo_action()
  for i = 0, buffer.selections - 1 do
    buffer.target_start = buffer.selection_n_anchor[i] - (pos - position)
    buffer.target_end = buffer.selection_n_caret[i]
    buffer:replace_target(text)
    buffer.selection_n_anchor[i] = buffer.selection_n_anchor[i] + #text
    buffer.selection_n_caret[i] = buffer.selection_n_caret[i] + #text
  end
  buffer:end_undo_action()
  buffer:auto_c_cancel() -- tell Scintilla not to handle autocompletion normally
end)

-- Prepares the buffer for saving to a file.
events.connect(events.FILE_BEFORE_SAVE, function()
  if not M.STRIP_TRAILING_SPACES then return end
  local buffer = buffer
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  local line_end_position, char_at = buffer.line_end_position, buffer.char_at
  local lines = buffer.line_count
  for line = 0, lines - 1 do
    local s, e = buffer:position_from_line(line), line_end_position[line]
    local i, c = e - 1, char_at[e - 1]
    while i >= s and c == 9 or c == 32 do i, c = i - 1, char_at[i - 1] end
    if i < e - 1 then buffer:delete_range(i + 1, e - i - 1) end
  end
  -- Ensure ending newline.
  local e = buffer:position_from_line(lines)
  if lines == 1 or e > buffer:position_from_line(lines - 1) then
    buffer:insert_text(e, '\n')
  end
  -- Convert non-consistent EOLs
  buffer:convert_eols(buffer.eol_mode)
  buffer:end_undo_action()
end)

---
-- Goes to the current character's matching brace, selecting the text in between
-- if *select* is `true`.
-- @param select Optional flag indicating whether or not to select the text
--   between matching braces. The default value is `false`.
-- @name match_brace
function M.match_brace(select)
  local pos = buffer.current_pos
  local match_pos = buffer:brace_match(pos)
  if match_pos == -1 then return end
  if not select then
    buffer:goto_pos(match_pos)
  elseif match_pos > pos then
    buffer:set_sel(pos, match_pos + 1)
  else
    buffer:set_sel(pos + 1, match_pos)
  end
end

---
-- Displays an autocompletion list, built from the set of words in string
-- *words* and existing words in the buffer, for the word behind the caret,
-- returning `true` if completions were found.
-- @param words Optional list of words considered to be in the buffer,
--   even if they are not. Words may contain [registered images][].
--
-- [registered images]: buffer.html#register_image
-- @return `true` if there were completions to show; `false` otherwise.
-- @see buffer.word_chars
-- @name autocomplete_word
function M.autocomplete_word(words)
  local buffer = buffer
  local pos, length = buffer.current_pos, buffer.length
  local completions, c_list = {}, {}
  local buffer_text = buffer:get_text()
  local root = buffer_text:sub(1, pos):match('['..buffer.word_chars..']+$')
  if not root or root == '' then return end
  for _, word in ipairs(words or {}) do
    if word:match('^'..root) then
      c_list[#c_list + 1], completions[word:match('^(.-)%??%d*$')] = word, true
    end
  end
  local patt = '^['..buffer.word_chars..']+'
  buffer.target_start, buffer.target_end = 0, buffer.length
  buffer.search_flags = buffer.FIND_WORDSTART
  if not buffer.auto_c_ignore_case then
    buffer.search_flags = buffer.search_flags + buffer.FIND_MATCHCASE
  end
  local match_pos = buffer:search_in_target(root)
  while match_pos ~= -1 do
    local s, e = buffer_text:find(patt, match_pos + 1)
    local match = buffer_text:sub(s, e)
    if not completions[match] and #match > #root then
      c_list[#c_list + 1], completions[match] = match, true
    end
    buffer.target_start, buffer.target_end = match_pos + 1, buffer.length
    match_pos = buffer:search_in_target(root)
  end
  if not buffer.auto_c_ignore_case then
    table.sort(c_list)
  else
    table.sort(c_list, function(a, b) return a:upper() < b:upper() end)
  end
  if #c_list > 0 then
    if not buffer.auto_c_choose_single or #c_list ~= 1 then
      buffer.auto_c_order = 0 -- pre-sorted
      buffer:auto_c_show(#root, table.concat(c_list, ' '))
    else
      -- Scintilla does not emit AUTO_C_SELECTION in this case. This is
      -- necessary for autocompletion with multiple selections.
      local text = c_list[1]:match('^(.-)%??%d*$')
      events.emit(events.AUTO_C_SELECTION, text, pos - #root)
    end
    return true
  end
end

---
-- Comments or uncomments the selected lines based on the current language.
-- As long as any part of a line is selected, the entire line is eligible for
-- commenting/uncommenting.
-- @see comment_string
-- @name block_comment
function M.block_comment()
  local buffer = buffer
  local comment = M.comment_string[buffer:get_lexer(true)]
  local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
  if not prefix then return end
  local anchor, pos = buffer.selection_start, buffer.selection_end
  local s, e = buffer:line_from_position(anchor), buffer:line_from_position(pos)
  local ignore_last_line = s ~= e and pos == buffer:position_from_line(e)
  anchor, pos = buffer.line_end_position[s] - anchor, buffer.length - pos
  buffer:begin_undo_action()
  for line = s, not ignore_last_line and e or e - 1 do
    local p = buffer:position_from_line(line)
    if buffer:text_range(p, p + #prefix) == prefix then
      buffer:set_sel(p, p + #prefix)
      buffer:replace_sel('')
      if suffix ~= '' then
        p = buffer.line_end_position[line]
        buffer:set_sel(p - #suffix, p)
        buffer:replace_sel('')
        if line == s then anchor = anchor - #suffix end
        if line == e then pos = pos - #suffix end
      end
    else
      buffer:insert_text(p, prefix)
      if suffix ~= '' then
        buffer:insert_text(buffer.line_end_position[line], suffix)
        if line == s then anchor = anchor + #suffix end
        if line == e then pos = pos + #suffix end
      end
    end
  end
  buffer:end_undo_action()
  anchor, pos = buffer.line_end_position[s] - anchor, buffer.length - pos
  -- Keep the anchor and caret on the first line as necessary.
  local start_pos = buffer:position_from_line(s)
  anchor, pos = math.max(anchor, start_pos), math.max(pos, start_pos)
  if s ~= e then buffer:set_sel(anchor, pos) else buffer:goto_pos(pos) end
end

---
-- Moves the caret to the beginning of line number *line* or the user-specified
-- line, ensuring the line is visible.
-- @param line Optional line number to go to. If `nil`, the user is prompted for
--   one.
-- @name goto_line
function M.goto_line(line)
  if not line then
    local button, value = ui.dialogs.inputbox{
      title = _L['Go To'], informative_text = _L['Line Number:'],
      button1 = _L['_OK'], button2 = _L['_Cancel']
    }
    line = tonumber(value)
    if button ~= 1 or not line then return end
  end
  buffer:ensure_visible_enforce_policy(line - 1)
  buffer:goto_line(line - 1)
end

---
-- Transposes characters intelligently.
-- If the caret is at the end of a line, transposes the two characters before
-- the caret. Otherwise, the characters to the left and right are.
-- @name transpose_chars
function M.transpose_chars()
  if buffer.length == 0 then return end
  local pos, char = buffer.current_pos, buffer.char_at[buffer.current_pos]
  if char == 10 or char == 13 or pos == buffer.length then pos = pos - 1 end
  buffer.target_start, buffer.target_end = pos - 1, pos + 1
  buffer:replace_target(buffer:text_range(pos - 1, pos + 1):reverse())
  buffer:goto_pos(pos + 1)
end

---
-- Joins the currently selected lines or the current line with the line below
-- it.
-- As long as any part of a line is selected, the entire line is eligible for
-- joining.
-- @name join_lines
function M.join_lines()
  buffer:target_from_selection()
  buffer:line_end()
  local line = buffer:line_from_position(buffer.target_start)
  if line == buffer:line_from_position(buffer.target_end) then
    buffer.target_end = buffer:position_from_line(line + 1)
  end
  buffer:lines_join()
end

---
-- Encloses the selected text or the current word within strings *left* and
-- *right*.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @name enclose
function M.enclose(left, right)
  buffer:target_from_selection()
  local s, e = buffer.target_start, buffer.target_end
  if s == e then
    buffer.target_start = buffer:word_start_position(s, true)
    buffer.target_end = buffer:word_end_position(e, true)
    s, e = buffer.target_start, buffer.target_end
  end
  buffer:replace_target(left..buffer:text_range(s, e)..right)
  buffer:goto_pos(buffer.target_end)
end

---
-- Selects the text between strings *left* and *right* containing the caret.
-- If already selected, toggles between selecting *left* and *right* too.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @name select_enclosed
function M.select_enclosed(left, right)
  local anchor, pos = buffer.anchor, buffer.current_pos
  if anchor ~= pos then buffer:goto_pos(pos - #right) end
  buffer:search_anchor()
  local s, e = buffer:search_prev(0, left), buffer:search_next(0, right)
  if s >= 0 and e >= 0 then
    if s + #left == anchor and e == pos then s, e = s - #left, e + #right end
    buffer:set_sel(s + #left, e)
  end
end

---
-- Selects the current word.
-- If already selected, selects the next occurrence as a multiple selection.
-- @see buffer.word_chars
-- @name select_word
function M.select_word()
  if buffer:get_sel_text() == '' then
    buffer:set_selection(buffer:word_start_position(buffer.current_pos, true),
                         buffer:word_end_position(buffer.current_pos, true))
  else
    local word = buffer:text_range(buffer.selection_start, buffer.selection_end)
    buffer.target_start = buffer.selection_n_end[buffer.selections - 1]
    buffer.target_end = buffer.length - 1
    buffer.search_flags = buffer.FIND_MATCHCASE + buffer.FIND_WHOLEWORD
    if buffer:search_in_target(word) ~= -1 then
      buffer:add_selection(buffer.target_start, buffer.target_end)
      buffer.main_selection = 0
    end
  end
end

---
-- Selects the current line.
-- @name select_line
function M.select_line()
  buffer:home()
  buffer:line_end_extend()
end

---
-- Selects the current paragraph.
-- Paragraphs are surrounded by one or more blank lines.
-- @name select_paragraph
function M.select_paragraph()
  buffer:line_down()
  buffer:para_up()
  buffer:para_down_extend()
end

---
-- Selects all text with the current level of indentation.
-- If a text block is selected and the lines immediately above and below it are
-- one indentation level lower, adds those lines to the selection.
-- @name select_indented_block
function M.select_indented_block()
  local buffer = buffer
  local s = buffer:line_from_position(buffer.selection_start)
  local e = buffer:line_from_position(buffer.selection_end)
  local indent = buffer.line_indentation[s] - buffer.tab_width
  if indent < 0 then return end
  if buffer:get_sel_text() ~= '' and
     buffer.line_indentation[s - 1] == indent and
     buffer.line_indentation[e + 1] == indent then
    s, e, indent = s - 1, e + 1, indent + buffer.tab_width
  end
  while buffer.line_indentation[s - 1] > indent do s = s - 1 end
  while buffer.line_indentation[e + 1] > indent do e = e + 1 end
  s, e = buffer:position_from_line(s), buffer.line_end_position[e]
  buffer:set_sel(s, e)
end

---
-- Converts indentation between tabs and spaces based on `buffer.use_tabs`.
-- If `buffer.use_tabs` is `true`, `buffer.tab_width` indenting spaces are
-- converted to tabs. Otherwise, all indenting tabs are converted to
-- `buffer.tab_width` spaces.
-- @see buffer.use_tabs
-- @name convert_indentation
function M.convert_indentation()
  local buffer = buffer
  local line_indentation = buffer.line_indentation
  local line_indent_position = buffer.line_indent_position
  buffer:begin_undo_action()
  for line = 0, buffer.line_count do
    local s = buffer:position_from_line(line)
    local indent = line_indentation[line]
    local indent_pos = line_indent_position[line]
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
  buffer.indicator_current = M.INDIC_HIGHLIGHT
  buffer:indicator_clear_range(0, buffer.length)
end
events.connect(events.KEYPRESS, function(code)
  if keys.KEYSYMS[code] == 'esc' then clear_highlighted_words() end
end)

---
-- Highlights all occurrences of the selected text or the current word.
-- @see buffer.word_chars
-- @name highlight_word
function M.highlight_word()
  clear_highlighted_words()
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s, e = buffer:word_start_position(s, true), buffer:word_end_position(s)
  end
  if s == e then return end
  local word = buffer:text_range(s, e)
  buffer.search_flags = buffer.FIND_WHOLEWORD + buffer.FIND_MATCHCASE
  buffer.target_start, buffer.target_end = 0, buffer.length
  while buffer:search_in_target(word) > -1 do
    local len = buffer.target_end - buffer.target_start
    buffer:indicator_fill_range(buffer.target_start, len)
    buffer.target_start, buffer.target_end = buffer.target_end, buffer.length
  end
  buffer:set_sel(s, e)
end

---
-- Passes the selected text or all buffer text to string shell command *command*
-- as standard input (stdin) and replaces the input text with the command's
-- standard output (stdout).
-- Standard input is as follows:
--
-- 1. If text is selected and spans multiple lines, all text on the lines
-- containing the selection is passed as stdin. However, if the end of the
-- selection is at the beginning of a line, only the line ending delimiters from
-- the previous line are included. The rest of the line is excluded.
-- 2. If text is selected and spans a single line, only the selected text is
-- used.
-- 3. If no text is selected, the entire buffer is used.
-- @param command The Linux, BSD, Mac OSX, or Windows shell command to filter
--   text through.
-- @name filter_through
function M.filter_through(command)
  local s, e = buffer.selection_start, buffer.selection_end
  local input
  if s ~= e then -- use selected lines as input
    local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
    if i < j then
      s = buffer:position_from_line(i)
      if buffer.column[e] > 0 then e = buffer:position_from_line(j + 1) end
    end
    input = buffer:text_range(s, e)
  else -- use whole buffer as input
    input = buffer:get_text()
  end
  local tmpfile = _USERHOME..'/.ft'
  local f = io.open(tmpfile, 'wb')
  f:write(input)
  f:close()
  local cmd = (not WIN32 and 'cat' or 'type')..' "'..tmpfile..'" | '..command
  if WIN32 then cmd = cmd:gsub('/', '\\') end
  local p = io.popen(cmd)
  if s ~= e then
    buffer.target_start, buffer.target_end = s, e
    buffer:replace_target(p:read('*all'))
    buffer:set_sel(buffer.target_start, buffer.target_end)
  else
    buffer:set_text(p:read('*all'))
    buffer:goto_pos(s)
  end
  p:close()
  os.remove(tmpfile)
end

return M

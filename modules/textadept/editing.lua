-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Editing features for Textadept.
-- @field AUTOPAIR (bool)
--   Automatically close opening brace and quote characters with their
--   complements.
--   The default value is `true`.
--   Auto-paired characters are defined in the
--   [`textadept.editing.char_matches`]() table.
-- @field TYPEOVER_CHARS (bool)
--   Move over closing brace and quote characters under the caret when typing
--   them.
--   The default value is `true`.
--   Typeover characters are defined in the
--   [`textadept.editing.typeover_chars`]() table.
-- @field AUTOINDENT (bool)
--   Match the previous line's indentation level after inserting a new line.
--   The default value is `true`.
-- @field STRIP_TRAILING_SPACES (bool)
--   Strip trailing whitespace before saving files.
--   The default value is `false`.
-- @field AUTOCOMPLETE_ALL (bool)
--   Autocomplete the current word using words from all open buffers.
--   If `true`, performance may be slow when many buffers are open.
--   The default value is `false`.
-- @field INDIC_BRACEMATCH (number)
--   The matching brace highlight indicator number.
-- @field INDIC_HIGHLIGHT (number)
--   The word highlight indicator number.
module('textadept.editing')]]

M.AUTOPAIR = true
M.TYPEOVER_CHARS = true
M.AUTOINDENT = true
M.STRIP_TRAILING_SPACES = false
M.AUTOCOMPLETE_ALL = false
M.INDIC_BRACEMATCH = _SCINTILLA.next_indic_number()
M.INDIC_HIGHLIGHT = _SCINTILLA.next_indic_number()

---
-- Map of image names to registered image numbers.
-- @field CLASS The image number for classes.
-- @field NAMESPACE The image number for namespaces.
-- @field METHOD The image number for methods.
-- @field SIGNAL The image number for signals.
-- @field SLOT The image number for slots.
-- @field VARIABLE The image number for variables.
-- @field STRUCT The image number for structures.
-- @field TYPEDEF The image number for type definitions.
-- @class table
-- @name XPM_IMAGES
M.XPM_IMAGES = {
  not CURSES and '/* XPM */static char *class[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #001CD0","X c #008080","o c #0080E8","O c #00C0C0","+ c #24D0FC","@ c #00FFFF","# c #A4E8FC","$ c #C0FFFF","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or '*',
  not CURSES and '/* XPM */static char *namespace[] = {/* columns rows colors chars-per-pixel */"16 16 7 1 ","  c #000000",". c #1D1D1D","X c #393939","o c #555555","O c #A8A8A8","+ c #AAAAAA","@ c None",/* pixels */"@@@@@@@@@@@@@@@@","@@@@+@@@@@@@@@@@","@@@.o@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@+.@@@@@@@+@@@@","@@+ @@@@@@@o.@@@","@@@ +@@@@@@+ @@@","@@@ +@@@@@@+ @@@","@@@.X@@@@@@@.+@@","@@@@+@@@@@@@ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@X.@@@","@@@@@@@@@@@+@@@@","@@@@@@@@@@@@@@@@"};' or '@',
  not CURSES and '/* XPM */static char *method[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOOOOO","OO  X. OOOOOOOOO","OOOO  OOOOOOOOOO"};' or '+',
  not CURSES and '/* XPM */static char *signal[] = {/* columns rows colors chars-per-pixel */"16 16 6 1 ","  c #000000",". c #FF0000","X c #E0BC38","o c #F0DC5C","O c #FCFC80","+ c None",/* pixels */"++++++++++++++++","++++++++++++++++","++++++++++++++++","++++++++++  ++++","+++++++++ OO  ++","++++++++ OOOOO +","+++++++ OOOOOX +","++++  + ooOOXX +","+++ OO  oooXXX +","++ OOOOO ooXX ++","+ OOOOOX  oX +++","+ ooOOXX +  ++++","+ oooXXX +++++++","+ oooXX +++++..+","++  oX ++++++..+","++++  ++++++++++"};' or '~',
  not CURSES and '/* XPM */static char *slot[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOO   ","OO  X. OOOOOO O ","OOOO  OOOOOOO   "};' or '-',
  not CURSES and '/* XPM */static char *variable[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #8C748C","X c #9C94A4","o c #ACB4C0","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOO  OOOOO","OOOOOOOO oo  OOO","OOOOOOO ooooo OO","OOOOOO ooooo. OO","OOOOOO XXoo.. OO","OOOOOO XXX... OO","OOOOOO XXX.. OOO","OOOOOOO  X. OOOO","OOOOOOOOO  OOOOO","OOOOOOOOOOOOOOOO"};' or '.',
  not CURSES and '/* XPM */static char *struct[] = {/* columns rows colors chars-per-pixel */"16 16 14 1 ","  c #000000",". c #008000","X c #00C000","o c #00FF00","O c #808000","+ c #C0C000","@ c #FFFF00","# c #008080","$ c #00C0C0","% c #00FFFF","& c #C0FFC0","* c #FFFFC0","= c #C0FFFF","- c None",/* pixels */"-----  ---------","---- &&  -------","--- &&&oo ------","-- ooooo.   ----","-- XXoo.. ==  --","-- XXX.. ===%% -","-- XXX. %%%%%# -","---   . $$%%## -","--- **  $$$### -","-- ***@@ $$## --","- @@@@@O  $# ---","- ++@@OO -  ----","- +++OOO -------","- +++OO --------","--  +O ---------","----  ----------"};' or '}',
  not CURSES and '/* XPM */static char *typedef[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #404040","X c #6D6D6D","o c #777777","O c #949494","+ c #ACACAC","@ c #BBBBBB","# c #DBDBDB","$ c #EEEEEE","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or ':',
  CLASS = 1, NAMESPACE = 2, METHOD = 3, SIGNAL = 4, SLOT = 5, VARIABLE = 6,
  STRUCT = 7, TYPEDEF = 8
}
events.connect(events.VIEW_NEW, function()
  for name, i in pairs(M.XPM_IMAGES) do
    if type(name) == 'string' then buffer:register_image(i, M.XPM_IMAGES[i]) end
  end
end)
for _ = 1, #M.XPM_IMAGES do _SCINTILLA.next_image_type() end -- sync

---
-- Map of lexer names to line comment strings for programming languages, used by
-- the `block_comment()` function.
-- Keys are lexer names and values are either the language's line comment
-- prefixes or block comment delimiters separated by a '|' character.
-- @class table
-- @name comment_string
-- @see block_comment
M.comment_string = {actionscript='//',ada='--',antlr='//',adpl='!',ansi_c='/*|*/',applescript='--',asp='\'',awk='#',b_lang='//',bash='#',batch=':',bibtex='%',boo='#',chuck='//',cmake='#',coffeescript='#',context='%',cpp='//',csharp='//',css='/*|*/',cuda='//',desktop='#',django='{#|#}',dmd='//',dot='//',eiffel='--',elixir='#',erlang='%',fish='#',forth='|\\',fortran='!',fsharp='//',gap='#',gettext='#',glsl='//',gnuplot='#',go='//',groovy='//',gtkrc='#',haskell='--',html='<!--|-->',idl='//',inform='!',ini='#',Io='#',java='//',javascript='//',json='/*|*/',jsp='//',latex='%',less='//',lilypond='%',lisp=';',lua='--',makefile='#',matlab='#',nemerle='//',nsis='#',objective_c='//',pascal='//',perl='#',php='//',pike='//',pkgbuild='#',prolog='%',props='#',ps='%',python='#',rails='#',rebol=';',rest='.. ',rexx='--',rhtml='<!--|-->',rstats='#',ruby='#',rust='//',sass='//',scala='//',scheme=';',smalltalk='"|"',sql='#',tcl='#',tex='%',text='',toml='#',vala='//',vb='\'',vbscript='\'',verilog='//',vhdl='--',wsf='<!--|-->',xml='<!--|-->',yaml='#'}

---
-- Map of auto-paired characters like parentheses, brackets, braces, and quotes,
-- with language-specific auto-paired character maps assigned to a lexer name
-- key.
-- The ASCII values of opening characters are assigned to strings that contain
-- complement characters. The default auto-paired characters are "()", "[]",
-- "{}", "&apos;&apos;", and "&quot;&quot;".
-- @class table
-- @name char_matches
-- @usage textadept.editing.char_matches.html = {..., [60] = '>'}
-- @see AUTOPAIR
M.char_matches = {[40] = ')', [91] = ']', [123] = '}', [39] = "'", [34] = '"'}

---
-- Table of brace characters to highlight, with language-specific brace
-- character tables assigned to a lexer name key.
-- The ASCII values of brace characters are keys and are assigned non-`nil`
-- values. The default brace characters are '(', ')', '[', ']', '{', and '}'.
-- @class table
-- @name braces
-- @usage textadept.editing.braces.html = {..., [60] = 1, [62] = 1}
M.braces = {[40] = 1, [41] = 1, [91] = 1, [93] = 1, [123] = 1, [125] = 1}

---
-- Table of characters to move over when typed, with language-specific typeover
-- character tables assigned to a lexer name key.
-- The ASCII values of characters are keys and are assigned non-`nil` values.
-- The default characters are ')', ']', '}', '&apos;', and '&quot;'.
-- @class table
-- @name typeover_chars
-- @usage textadept.editing.typeover_chars.html = {..., [62] = 1}
-- @see TYPEOVER_CHARS
M.typeover_chars = {[41] = 1, [93] = 1, [125] = 1, [39] = 1, [34] = 1}

---
-- Map of autocompleter names to autocompletion functions.
-- Names are typically lexer names and autocompletion functions typically
-- autocomplete symbols.
-- Autocompletion functions must return two values: the number of characters
-- behind the caret that are used as the prefix of the entity to be
-- autocompleted, and a list of completions to be shown. Autocompletion lists
-- are sorted automatically.
-- @class table
-- @name autocompleters
-- @see autocomplete
M.autocompleters = {}

---
-- Map of lexer names to API documentation file tables.
-- Each line in an API file consists of a symbol name (not a fully qualified
-- symbol name), a space character, and that symbol's documentation. '\n'
-- represents a newline character.
-- @class table
-- @name api_files
-- @see show_documentation
M.api_files = {}

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
  local line = buffer:line_from_position(buffer.current_pos)
  local i = line - 1
  while i >= 0 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
  if i >= 0 then
    buffer.line_indentation[line] = buffer.line_indentation[i]
    buffer:vc_home()
  end
end)

-- Enables and disables bracketed paste mode in curses and disables auto-pair
-- and auto-indent while pasting.
if CURSES and not WIN32 then
  local function enable_bracketed_paste_mode()
    io.stdout:write('\x1b[?2004h')
    io.stdout:flush()
  end
  enable_bracketed_paste_mode()
  local function disable_bracketed_paste_mode()
    io.stdout:write('\x1b[?2004l')
    io.stdout:flush()
  end
  events.connect(events.SUSPEND, disable_bracketed_paste_mode)
  events.connect(events.RESUME, enable_bracketed_paste_mode)
  events.connect(events.QUIT, disable_bracketed_paste_mode)

  local reenable_autopair, reenable_autoindent
  events.connect(events.CSI, function(cmd, args)
    if cmd ~= string.byte('~') then return end
    if args[1] == 200 then
      reenable_autopair, M.AUTOPAIR = M.AUTOPAIR, false
      reenable_autoindent, M.AUTOINDENT = M.AUTOINDENT, false
    elseif args[1] == 201 then
      M.AUTOPAIR, M.AUTOINDENT = reenable_autopair, reenable_autoindent
    end
  end)
end

-- Prepares the buffer for saving to a file.
events.connect(events.FILE_BEFORE_SAVE, function()
  if not M.STRIP_TRAILING_SPACES then return end
  local buffer = buffer
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  local lines = buffer.line_count
  for line = 0, lines - 1 do
    local s, e = buffer:position_from_line(line), buffer.line_end_position[line]
    local i, c = e - 1, buffer.char_at[e - 1]
    while i >= s and (c == 9 or c == 32) do
      i, c = i - 1, buffer.char_at[i - 1]
    end
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
-- Comments or uncomments the selected lines based on the current language.
-- As long as any part of a line is selected, the entire line is eligible for
-- commenting/uncommenting.
-- @see comment_string
-- @name block_comment
function M.block_comment()
  local buffer = buffer
  local comment = M.comment_string[buffer:get_lexer(true)] or ''
  local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
  if not prefix then return end
  local anchor, pos = buffer.selection_start, buffer.selection_end
  local s, e = buffer:line_from_position(anchor), buffer:line_from_position(pos)
  local ignore_last_line = s ~= e and pos == buffer:position_from_line(e)
  anchor, pos = buffer.line_end_position[s] - anchor, buffer.length - pos
  buffer:begin_undo_action()
  for line = s, not ignore_last_line and e or e - 1 do
    local p = buffer.line_indent_position[line]
    if buffer:text_range(p, p + #prefix) == prefix then
      buffer:delete_range(p, #prefix)
      if suffix ~= '' then
        p = buffer.line_end_position[line]
        buffer:delete_range(p - #suffix, #suffix)
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
-- line, ensuring *line* is visible.
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
  if buffer.length == 0 or buffer.current_pos == 0 then return end
  local pos, char = buffer.current_pos, buffer.char_at[buffer.current_pos]
  if char == 10 or char == 13 or pos == buffer.length then pos = pos - 1 end
  buffer:set_target_range(pos - 1, pos + 1)
  buffer:replace_target(buffer.target_text:reverse())
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
    buffer:set_target_range(buffer:word_start_position(s, true),
                            buffer:word_end_position(e, true))
  end
  buffer:replace_target(left..buffer.target_text..right)
  buffer:goto_pos(buffer.target_end)
end

---
-- Selects the text between strings *left* and *right* that enclose the caret.
-- If that range is already selected, toggles between selecting *left* and
-- *right* as well.
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
-- Selects the current word or, if *all* is `true`, all occurrences of the
-- current word.
-- If a word is already selected, selects the next occurrence as a multiple
-- selection.
-- @param all Whether or not to select all occurrences of the current word.
--   The default value is `false`.
-- @see buffer.word_chars
-- @name select_word
function M.select_word(all)
  buffer:target_whole_document()
  buffer.search_flags = buffer.FIND_MATCHCASE
  if buffer.selection_empty or
     buffer:is_range_word(buffer.selection_start, buffer.selection_end) then
    buffer.search_flags = buffer.search_flags + buffer.FIND_WHOLEWORD
    if all then buffer:multiple_select_add_next() end -- select word first
  end
  buffer['multiple_select_add_'..(not all and 'next' or 'each')](buffer)
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
-- Converts indentation between tabs and spaces according to `buffer.use_tabs`.
-- If `buffer.use_tabs` is `true`, `buffer.tab_width` indenting spaces are
-- converted to tabs. Otherwise, all indenting tabs are converted to
-- `buffer.tab_width` spaces.
-- @see buffer.use_tabs
-- @name convert_indentation
function M.convert_indentation()
  local buffer = buffer
  buffer:begin_undo_action()
  for line = 0, buffer.line_count do
    local s = buffer:position_from_line(line)
    local indent = buffer.line_indentation[line]
    local e = buffer.line_indent_position[line]
    local current_indentation, new_indentation = buffer:text_range(s, e), nil
    if buffer.use_tabs then
      -- Need integer division and LuaJIT does not have // operator.
      new_indentation = ('\t'):rep(math.floor(indent / buffer.tab_width))
    else
      new_indentation = (' '):rep(indent)
    end
    if current_indentation ~= new_indentation then
      buffer:set_target_range(s, e)
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
-- Highlights all occurrences of the selected text or all occurrences of the
-- current word.
-- @see buffer.word_chars
-- @name highlight_word
function M.highlight_word()
  clear_highlighted_words()
  local buffer = buffer
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    s = buffer:word_start_position(s, true)
    e = buffer:word_end_position(s, true)
  end
  if s == e then return end
  local word = buffer:text_range(s, e)
  buffer.search_flags = buffer.FIND_WHOLEWORD + buffer.FIND_MATCHCASE
  buffer:target_whole_document()
  while buffer:search_in_target(word) > -1 do
    local len = buffer.target_end - buffer.target_start
    buffer:indicator_fill_range(buffer.target_start, len)
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
  buffer:set_sel(s, e)
end

---
-- Passes the selected text or all buffer text to string shell command *command*
-- as standard input (stdin) and replaces the input text with the command's
-- standard output (stdout).
-- Standard input is as follows:
--
-- 1. If text is selected and spans multiple lines, all text on the lines that
-- have text selected is passed as stdin. However, if the end of the selection
-- is at the beginning of a line, only the line ending delimiters from the
-- previous line are included. The rest of the line is excluded.
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
  local p = spawn(command)
  p:write(input)
  p:close()
  if s ~= e then
    buffer:set_target_range(s, e)
    buffer:replace_target(p:read('*a'))
    buffer:set_sel(buffer.target_start, buffer.target_end)
  else
    buffer:set_text(p:read('*a'))
    buffer:goto_pos(s)
  end
end

---
-- Displays an autocompletion list provided by the autocompleter function
-- associated with string *name*, and returns `true` if completions were found.
-- @param name The name of an autocompleter function in the `autocompleters`
--   table to use for providing autocompletions.
-- @name autocomplete
-- @see autocompleters
function M.autocomplete(name)
  if not M.autocompleters[name] then return end
  local len_entered, list = M.autocompleters[name]()
  if not len_entered or not list or #list == 0 then return end
  buffer.auto_c_order = buffer.ORDER_PERFORMSORT
  buffer:auto_c_show(len_entered,
                     table.concat(list, string.char(buffer.auto_c_separator)))
  return true
end

-- Returns for the word behind the caret a list of completions constructed from
-- the current buffer or all open buffers (depending on `M.AUTOCOMPLETE_ALL`).
-- @see buffer.word_chars
-- @see autocomplete
M.autocompleters.word = function()
  local list, ignore_case = {}, buffer.auto_c_ignore_case
  local line, pos = buffer:get_cur_line()
  local word_char = '['..buffer.word_chars:gsub('(%p)', '%%%1')..']'
  local word = line:sub(1, pos):match(word_char..'*$')
  if word == '' then return nil end
  local word_patt = word:gsub('(%p)', '%%%1')
  if ignore_case then
    word_patt = word_patt:lower():gsub('%l', function(c)
      return string.format('[%s%s]', string.upper(c), c)
    end)
  end
  word_patt = '()('..word_patt..word_char..'+)'
  local nonword_char = '^[^'..buffer.word_chars:gsub('(%p)', '%%%1')..']'
  for i = 1, #_BUFFERS do
    if _BUFFERS[i] == buffer or M.AUTOCOMPLETE_ALL then
      local text = _BUFFERS[i]:get_text()
      for match_pos, match in text:gmatch(word_patt) do
        -- Frontier pattern (%f) is too slow, so check prior char after a match.
        if (match_pos == 1 or text:find(nonword_char, match_pos - 1)) and
           not list[match] then
          list[#list + 1], list[match] = match, true
        end
      end
    end
  end
  if #list == 0 then return nil end
  return #word, list
end

local api_docs
---
-- Displays a call tip with documentation for the symbol under or directly
-- behind the caret.
-- Documentation is read from API files in the `api_files` table.
-- If a call tip is already shown, cycles to the next one if it exists.
-- Symbols are determined by using `buffer.word_chars`.
-- @name show_documentation
-- @see api_files
-- @see buffer.word_chars
function M.show_documentation()
  if buffer:call_tip_active() then events.emit(events.CALL_TIP_CLICK) return end
  local lang = buffer:get_lexer(true)
  if not M.api_files[lang] then return end
  local s = buffer:word_start_position(buffer.current_pos, true)
  local e = buffer:word_end_position(buffer.current_pos, true)
  local symbol = buffer:text_range(s, e)
  if symbol == '' then return nil end
  api_docs = {}
  local symbol_patt = '^'..symbol:gsub('(%p)', '%%%1')
  for i = 1, #M.api_files[lang] do
    if lfs.attributes(M.api_files[lang][i]) then
      for line in io.lines(M.api_files[lang][i]) do
        if line:find(symbol_patt) then
          api_docs[#api_docs + 1] = line:match(symbol_patt..'%s+(.+)$')
        end
      end
    end
  end
  if #api_docs == 0 then return end
  for i = 1, #api_docs do
    local doc = api_docs[i]:gsub('%f[\\]\\n', '\n'):gsub('\\\\', '\\')
    if #api_docs > 1 then
      if not doc:find('\n') then doc = doc..'\n' end
      doc = '\001'..doc:gsub('\n', '\n\002', 1)
    end
    api_docs[i] = doc
  end
  if not api_docs.pos then api_docs.pos = 1 end
  buffer:call_tip_show(buffer.current_pos, api_docs[api_docs.pos])
end
-- Cycle through apidoc calltips.
events.connect(events.CALL_TIP_CLICK, function(position)
  if not api_docs then return end
  api_docs.pos = api_docs.pos + (position == 1 and -1 or 1)
  if api_docs.pos > #api_docs then api_docs.pos = 1 end
  if api_docs.pos < 1 then api_docs.pos = #api_docs end
  buffer:call_tip_show(buffer.current_pos, api_docs[api_docs.pos])
end)

return M

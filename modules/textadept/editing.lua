-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Editing features for Textadept.
-- @field auto_indent (bool)
--   Match the previous line's indentation level after inserting a new line.
--   The default value is `true`.
-- @field strip_trailing_spaces (bool)
--   Strip trailing whitespace before saving files.
--   The default value is `false`.
-- @field paste_reindents (bool)
--   Reindent pasted text according to the buffer's indentation settings.
--   The default value is `true`.
-- @field autocomplete_all_words (bool)
--   Autocomplete the current word using words from all open buffers.
--   If `true`, performance may be slow when many buffers are open.
--   The default value is `false`.
-- @field INDIC_BRACEMATCH (number)
--   The matching brace highlight indicator number.
-- @field INDIC_HIGHLIGHT (number)
--   The word highlight indicator number.
module('textadept.editing')]]

M.auto_indent = true
M.strip_trailing_spaces = false
M.paste_reindents = true
M.autocomplete_all_words = false
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
M.comment_string = {actionscript='//',ada='--',apdl='!',ansi_c='/*|*/',antlr='//',apl='#',applescript='--',asp='\'',autoit=';',awk='#',b_lang='//',bash='#',batch=':',bibtex='%',boo='#',chuck='//',cmake='#',coffeescript='#',context='%',cpp='//',crystal='#',csharp='//',css='/*|*/',cuda='//',desktop='#',django='{#|#}',dmd='//',dockerfile='#',dot='//',eiffel='--',elixir='#',erlang='%',faust='//',fish='#',forth='|\\',fortran='!',fsharp='//',gap='#',gettext='#',gherkin='#',glsl='//',gnuplot='#',go='//',groovy='//',gtkrc='#',haskell='--',html='<!--|-->',icon='#',idl='//',inform='!',ini='#',Io='#',java='//',javascript='//',json='/*|*/',jsp='//',latex='%',ledger='#',less='//',lilypond='%',lisp=';',logtalk='%',lua='--',makefile='#',matlab='#',moonscript='--',myrddin='//',nemerle='//',nsis='#',objective_c='//',pascal='//',perl='#',php='//',pico8='//',pike='//',pkgbuild='#',prolog='%',props='#',protobuf='//',ps='%',pure='//',python='#',rails='#',rc='#',rebol=';',rest='.. ',rexx='--',rhtml='<!--|-->',rstats='#',ruby='#',rust='//',sass='//',scala='//',scheme=';',smalltalk='"|"',sml='(*)',snobol4='#',sql='#',tcl='#',tex='%',text='',toml='#',vala='//',vb='\'',vbscript='\'',verilog='//',vhdl='--',wsf='<!--|-->',xml='<!--|-->',yaml='#'}

---
-- Map of auto-paired characters like parentheses, brackets, braces, and quotes.
-- The ASCII values of opening characters are assigned to strings that contain
-- complement characters. The default auto-paired characters are "()", "[]",
-- "{}", "&apos;&apos;", and "&quot;&quot;".
-- @class table
-- @name auto_pairs
-- @usage textadept.editing.auto_pairs[60] = '>' -- pair '<' and '>'
-- @usage textadept.editing.auto_pairs = nil -- disable completely
M.auto_pairs = {[40] = ')', [91] = ']', [123] = '}', [39] = "'", [34] = '"'}

---
-- Table of brace characters to highlight.
-- The ASCII values of brace characters are keys and are assigned non-`nil`
-- values. The default brace characters are '(', ')', '[', ']', '{', and '}'.
-- @class table
-- @name brace_matches
-- @usage textadept.editing.brace_matches[60] = true -- '<'
-- @usage textadept.editing.brace_matches[62] = true -- '>'
M.brace_matches = {[40] = 1, [41] = 1, [91] = 1, [93] = 1, [123] = 1, [125] = 1}

---
-- Table of characters to move over when typed.
-- The ASCII values of characters are keys and are assigned non-`nil` values.
-- The default characters are ')', ']', '}', '&apos;', and '&quot;'.
-- @class table
-- @name typeover_chars
-- @usage textadept.editing.typeover_chars[62] = true -- '>'
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
-- symbol name), a space character, and that symbol's documentation. "\n"
-- represents a newline character.
-- @class table
-- @name api_files
-- @see show_documentation
M.api_files = {}

-- Matches characters specified in auto_pairs.
events.connect(events.CHAR_ADDED, function(code)
  if M.auto_pairs and M.auto_pairs[code] and buffer.selections == 1 then
    buffer:insert_text(-1, M.auto_pairs[code])
  end
end)

-- Removes matched chars on backspace.
events.connect(events.KEYPRESS, function(code)
  if not M.auto_pairs or keys.KEYSYMS[code] ~= '\b' or
     buffer.selections ~= 1 then
    return
  end
  local byte = buffer.char_at[buffer.current_pos - 1]
  if M.auto_pairs[byte] and
     buffer.char_at[buffer.current_pos] == string.byte(M.auto_pairs[byte]) then
    buffer:clear()
  end
end)

-- Highlights matching braces.
events.connect(events.UPDATE_UI, function(updated)
  if updated and bit32.band(updated, 3) == 0 then return end -- ignore scrolling
  if M.brace_matches[buffer.char_at[buffer.current_pos]] then
    local match = buffer:brace_match(buffer.current_pos, 0)
    if match ~= -1 then
      buffer:brace_highlight(buffer.current_pos, match)
    else
      buffer:brace_bad_light(buffer.current_pos)
    end
  else
    buffer:brace_bad_light(-1)
  end
end)

-- Moves over typeover characters when typed.
events.connect(events.KEYPRESS, function(code)
  if M.typeover_chars and M.typeover_chars[code] and
     buffer.selection_start == buffer.selection_end and
     buffer.char_at[buffer.current_pos] == code then
    buffer:char_right()
    return true
  end
end)

-- Auto-indent on return.
events.connect(events.CHAR_ADDED, function(code)
  if not M.auto_indent or code ~= 10 then return end
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
  local function enable_br_paste() io.stdout:write('\x1b[?2004h'):flush() end
  local function disable_br_paste() io.stdout:write('\x1b[?2004l'):flush() end
  enable_br_paste()
  events.connect(events.SUSPEND, disable_br_paste)
  events.connect(events.RESUME, enable_br_paste)
  events.connect(events.QUIT, disable_br_paste)

  local auto_pairs, auto_indent
  events.connect(events.CSI, function(cmd, args)
    if cmd ~= string.byte('~') then return end
    if args[1] == 200 then
      auto_pairs, M.auto_pairs = M.auto_pairs, nil
      auto_indent, M.auto_indent = M.auto_indent, false
    elseif args[1] == 201 then
      M.auto_pairs, M.auto_indent = auto_pairs, auto_indent
    end
  end)
end

-- Prepares the buffer for saving to a file.
events.connect(events.FILE_BEFORE_SAVE, function()
  if not M.strip_trailing_spaces then return end
  local buffer = buffer
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  for line = 0, buffer.line_count - 1 do
    local s, e = buffer:position_from_line(line), buffer.line_end_position[line]
    local i, byte = e - 1, buffer.char_at[e - 1]
    while i >= s and (byte == 9 or byte == 32) do
      i, byte = i - 1, buffer.char_at[i - 1]
    end
    if i < e - 1 then buffer:delete_range(i + 1, e - i - 1) end
  end
  -- Ensure ending newline.
  local e = buffer:position_from_line(buffer.line_count)
  if buffer.line_count == 1 or
     e > buffer:position_from_line(buffer.line_count - 1) then
    buffer:insert_text(e, '\n')
  end
  -- Convert non-consistent EOLs
  buffer:convert_eols(buffer.eol_mode)
  buffer:end_undo_action()
end)

---
-- Pastes the text from the clipboard, taking into account the buffer's
-- indentation settings and the indentation of the current and preceding lines.
-- @name paste
function M.paste()
  local line = buffer:line_from_position(buffer.selection_start)
  if not M.paste_reindents or
     buffer.selection_start > buffer.line_indent_position[line] then
    buffer:paste()
    return
  end
  -- Strip leading indentation from clipboard text.
  local text = ui.clipboard_text
  local lead = text:match('^[ \t]*')
  if lead ~= '' then text = text:sub(#lead + 1):gsub('\n'..lead, '\n') end
  -- Change indentation to match buffer indentation settings.
  local tab_width = math.huge
  text = text:gsub('\n([ \t]+)', function(indentation)
    if indentation:find('^\t') then
      if buffer.use_tabs then return '\n'..indentation end
      return '\n'..indentation:gsub('\t', string.rep(' ', buffer.tab_width))
    else
      tab_width = math.min(tab_width, #indentation)
      local indent = math.floor(#indentation / tab_width)
      local spaces = string.rep(' ', math.fmod(#indentation, tab_width))
      if buffer.use_tabs then return '\n'..string.rep('\t', indent)..spaces end
      return '\n'..string.rep(' ', buffer.tab_width):rep(indent)..spaces
    end
  end)
  -- Re-indent according to whichever of the current and preceding lines has the
  -- higher indentation amount.
  local i = line - 1
  while i >= 0 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
  if i < 0 or buffer.line_indentation[i] < buffer.line_indentation[line] then
    i = line
  end
  local s, e = buffer:position_from_line(i), buffer.line_indent_position[i]
  text = text:gsub('\n', '\n'..buffer:text_range(s, e))
  -- Paste the text and adjust first and last line indentation accordingly.
  local start_indent = buffer.line_indentation[i]
  local end_line = buffer:line_from_position(buffer.selection_end)
  local end_indent = buffer.line_indentation[end_line]
  local end_column = buffer.column[buffer.selection_end]
  buffer:begin_undo_action()
  buffer:replace_sel(text)
  buffer.line_indentation[line] = start_indent
  if text:find('\n') then
    local line = buffer:line_from_position(buffer.current_pos)
    buffer.line_indentation[line] = end_indent
    buffer:goto_pos(buffer:find_column(line, end_column))
  end
  buffer:end_undo_action()
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
    line = line - 1
  end
  buffer:ensure_visible_enforce_policy(line)
  buffer:goto_line(line)
end

---
-- Transposes characters intelligently.
-- If the caret is at the end of a line, transposes the two characters before
-- the caret. Otherwise, the characters to the left and right are.
-- @name transpose_chars
function M.transpose_chars()
  if buffer.current_pos == 0 then return end
  local pos, byte = buffer.current_pos, buffer.char_at[buffer.current_pos]
  if byte == 10 or byte == 13 or pos == buffer.length then
    pos = buffer:position_before(pos)
  end
  local pos1, pos2 = buffer:position_before(pos), buffer:position_after(pos)
  local ch1, ch2 = buffer:text_range(pos1, pos), buffer:text_range(pos, pos2)
  buffer:set_target_range(pos1, pos2)
  buffer:replace_target(ch2..ch1)
  buffer:goto_pos(pos2)
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
-- *right*, taking multiple selections into account.
-- @param left The left part of the enclosure.
-- @param right The right part of the enclosure.
-- @name enclose
function M.enclose(left, right)
  buffer:begin_undo_action()
  for i = 0, buffer.selections - 1 do
    local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
    if s == e then
      buffer:set_target_range(buffer:word_start_position(s, true),
                              buffer:word_end_position(e, true))
    else
      buffer:set_target_range(s, e)
    end
    buffer:replace_target(left..buffer.target_text..right)
    buffer.selection_n_start[i] = buffer.target_end
    buffer.selection_n_end[i] = buffer.target_end
  end
  buffer:end_undo_action()
end

---
-- Selects the text between strings *left* and *right* that enclose the caret.
-- If that range is already selected, toggles between selecting *left* and
-- *right* as well.
-- If *left* and *right* are not provided, they are assumed to be one of the
-- delimiter pairs specified in `auto_pairs` and are inferred from the current
-- position or selection.
-- @param left Optional left part of the enclosure.
-- @param right Optional right part of the enclosure.
-- @see auto_pairs
-- @name select_enclosed
function M.select_enclosed(left, right)
  local s, e, anchor, pos = -1, -1, buffer.anchor, buffer.current_pos
  if left and right then
    if anchor ~= pos then buffer:goto_pos(pos - #right) end
    buffer:search_anchor()
    s, e = buffer:search_prev(0, left), buffer:search_next(0, right)
  elseif M.auto_pairs then
    s = buffer.selection_start
    local char_at, style_at = buffer.char_at, buffer.style_at
    while s >= 0 do
      local match = M.auto_pairs[char_at[s]]
      left, right = string.char(char_at[s]), match
      if match then
        if buffer:brace_match(s, 0) >= buffer.selection_end - 1 then
          e = buffer:brace_match(s, 0)
          break
        elseif M.brace_matches[char_at[s]] or
               style_at[s] == style_at[buffer.selection_start] then
          buffer.search_flags = 0
          buffer:set_target_range(s + 1, buffer.length)
          if buffer:search_in_target(match) >= buffer.selection_end - 1 then
            e = buffer.target_end - 1
            break
          end
        end
      end
      s = s - 1
    end
  end
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
  for line = 0, buffer.line_count - 1 do
    local s = buffer:position_from_line(line)
    local indent = buffer.line_indentation[line]
    local e = buffer.line_indent_position[line]
    local current_indentation, new_indentation = buffer:text_range(s, e), nil
    if buffer.use_tabs then
      -- Need integer division and LuaJIT does not have // operator.
      local tabs = math.floor(indent / buffer.tab_width)
      local spaces = math.fmod(indent, buffer.tab_width)
      new_indentation = string.rep('\t', tabs)..string.rep(' ', spaces)
    else
      new_indentation = string.rep(' ', indent)
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
    buffer:indicator_fill_range(buffer.target_start,
                                buffer.target_end - buffer.target_start)
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
  buffer:set_sel(s, e)
end

---
-- Passes the selected text or all buffer text to string shell command *command*
-- as standard input (stdin) and replaces the input text with the command's
-- standard output (stdout). *command* may contain pipes.
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
--   text through. May contain pipes.
-- @name filter_through
function M.filter_through(command)
  local s, e = buffer.selection_start, buffer.selection_end
  if s ~= e then
    -- Use the selected lines as input.
    local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
    if i < j then
      s = buffer:position_from_line(i)
      if buffer.column[e] > 0 then e = buffer:position_from_line(j + 1) end
    end
    buffer:set_target_range(s, e)
  else
    -- Use the whole buffer as input.
    buffer:target_whole_document()
  end
  local commands = lpeg.match(lpeg.Ct(lpeg.P{
    lpeg.C(lpeg.V('command')) * ('|' * lpeg.C(lpeg.V('command')))^0,
    command = (1 - lpeg.S('"\'|') + lpeg.V('str'))^1,
    str = '"' * (1 - lpeg.S('"\\') + lpeg.P('\\') * 1)^0 * lpeg.P('"')^-1 +
          "'" * (1 - lpeg.S("'\\") + lpeg.P('\\') * 1)^0 * lpeg.P("'")^-1,
  }), command)
  local output = buffer.target_text
  for i = 1, #commands do
    local p = assert(spawn(commands[i]))
    p:write(output)
    p:close()
    output = p:read('*a') or ''
  end
  buffer:replace_target(output:iconv('UTF-8', _CHARSET))
  if s ~= e then
    buffer:set_sel(buffer.target_start, buffer.target_end)
  else
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
-- the current buffer or all open buffers (depending on
-- `M.autocomplete_all_words`).
-- @see buffer.word_chars
-- @see autocomplete
M.autocompleters.word = function()
  local list, matches = {}, {}
  local s = buffer:word_start_position(buffer.current_pos, true)
  if s == buffer.current_pos then return end
  local word = buffer:text_range(s, buffer.current_pos)
  for i = 1, #_BUFFERS do
    if _BUFFERS[i] == buffer or M.autocomplete_all_words then
      local buffer = _BUFFERS[i]
      buffer.search_flags = buffer.FIND_WORDSTART
      if not buffer.auto_c_ignore_case then
        buffer.search_flags = buffer.search_flags + buffer.FIND_MATCHCASE
      end
      buffer:target_whole_document()
      while buffer:search_in_target(word) > -1 do
        local e = buffer:word_end_position(buffer.target_end, true)
        local match = buffer:text_range(buffer.target_start, e)
        if #match > #word and not matches[match] then
          list[#list + 1], matches[match] = match, true
        end
        buffer:set_target_range(e, buffer.length)
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

  api_docs = {}
  ::lookup::
  if symbol ~= '' then
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
  end
  -- Search backwards for an open function call and show API documentation for
  -- that function as well.
  local char_at = buffer.char_at
  while s >= 0 and char_at[s] ~= 40 do s = s - 1 end
  e = buffer:brace_match(s, 0)
  if s > 0 and (e == -1 or e >= buffer.current_pos) then
    s, e = buffer:word_start_position(s - 1, true), s - 1
    symbol = buffer:text_range(s, e + 1)
    goto lookup
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
  if api_docs.pos > #api_docs then
    api_docs.pos = 1
  elseif api_docs.pos < 1 then
    api_docs.pos = #api_docs
  end
  buffer:call_tip_show(buffer.current_pos, api_docs[api_docs.pos])
end)

return M

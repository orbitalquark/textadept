-- Copyright 2007-2020 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Editing features for Textadept.
-- @field auto_indent (bool)
--   Match the previous line's indentation level after inserting a new line.
--   The default value is `true`.
-- @field strip_trailing_spaces (bool)
--   Strip trailing whitespace before saving files. (Does not apply to binary
--   files.)
--   The default value is `false`.
-- @field autocomplete_all_words (bool)
--   Autocomplete the current word using words from all open buffers.
--   If `true`, performance may be slow when many buffers are open.
--   The default value is `false`.
-- @field highlight_words (number)
--   The word highlight mode.
--
--   * `textadept.editing.HIGHLIGHT_CURRENT`
--     Automatically highlight all instances of the current word.
--   * `textadept.editing.HIGHLIGHT_SELECTED`
--     Automatically highlight all instances of the selected word.
--   * `textadept.editing.HIGHLIGHT_NONE`
--     Do not automatically highlight words.
--
--   The default value is `textadept.editing.HIGHLIGHT_NONE`.
-- @field auto_enclose (bool)
--   Whether or not to auto-enclose selected text when typing a punctuation
--   character, taking [`textadept.editing.auto_pairs`]() into account.
--   The default value is `false`.
-- @field INDIC_BRACEMATCH (number)
--   The matching brace highlight indicator number.
-- @field INDIC_HIGHLIGHT (number)
--   The word highlight indicator number.
module('textadept.editing')]]

M.auto_indent = true
M.strip_trailing_spaces = false
M.autocomplete_all_words = false
M.HIGHLIGHT_NONE, M.HIGHLIGHT_CURRENT, M.HIGHLIGHT_SELECTED = 1, 2, 3
M.highlight_words = M.HIGHLIGHT_NONE
M.auto_enclose = false
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
M.XPM_IMAGES = {not CURSES and '/* XPM */static char *class[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #001CD0","X c #008080","o c #0080E8","O c #00C0C0","+ c #24D0FC","@ c #00FFFF","# c #A4E8FC","$ c #C0FFFF","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or '*',not CURSES and '/* XPM */static char *namespace[] = {/* columns rows colors chars-per-pixel */"16 16 7 1 ","  c #000000",". c #1D1D1D","X c #393939","o c #555555","O c #A8A8A8","+ c #AAAAAA","@ c None",/* pixels */"@@@@@@@@@@@@@@@@","@@@@+@@@@@@@@@@@","@@@.o@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@@ +@@@@@@@@@@@","@@+.@@@@@@@+@@@@","@@+ @@@@@@@o.@@@","@@@ +@@@@@@+ @@@","@@@ +@@@@@@+ @@@","@@@.X@@@@@@@.+@@","@@@@+@@@@@@@ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@+ @@@","@@@@@@@@@@@X.@@@","@@@@@@@@@@@+@@@@","@@@@@@@@@@@@@@@@"};' or '@',not CURSES and '/* XPM */static char *method[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOOOOO","OO  X. OOOOOOOOO","OOOO  OOOOOOOOOO"};' or '+',not CURSES and '/* XPM */static char *signal[] = {/* columns rows colors chars-per-pixel */"16 16 6 1 ","  c #000000",". c #FF0000","X c #E0BC38","o c #F0DC5C","O c #FCFC80","+ c None",/* pixels */"++++++++++++++++","++++++++++++++++","++++++++++++++++","++++++++++  ++++","+++++++++ OO  ++","++++++++ OOOOO +","+++++++ OOOOOX +","++++  + ooOOXX +","+++ OO  oooXXX +","++ OOOOO ooXX ++","+ OOOOOX  oX +++","+ ooOOXX +  ++++","+ oooXXX +++++++","+ oooXX +++++..+","++  oX ++++++..+","++++  ++++++++++"};' or '~',not CURSES and '/* XPM */static char *slot[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #E0BC38","X c #F0DC5C","o c #FCFC80","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOO  OOOO","OOOOOOOOO oo  OO","OOOOOOOO ooooo O","OOOOOOO ooooo. O","OOOO  O XXoo.. O","OOO oo  XXX... O","OO ooooo XX.. OO","O ooooo.  X. OOO","O XXoo.. O  OOOO","O XXX... OOOOOOO","O XXX.. OOOOO   ","OO  X. OOOOOO O ","OOOO  OOOOOOO   "};' or '-',not CURSES and '/* XPM */static char *variable[] = {/* columns rows colors chars-per-pixel */"16 16 5 1 ","  c #000000",". c #8C748C","X c #9C94A4","o c #ACB4C0","O c None",/* pixels */"OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOOOOOOOOO","OOOOOOOOO  OOOOO","OOOOOOOO oo  OOO","OOOOOOO ooooo OO","OOOOOO ooooo. OO","OOOOOO XXoo.. OO","OOOOOO XXX... OO","OOOOOO XXX.. OOO","OOOOOOO  X. OOOO","OOOOOOOOO  OOOOO","OOOOOOOOOOOOOOOO"};' or '.',not CURSES and '/* XPM */static char *struct[] = {/* columns rows colors chars-per-pixel */"16 16 14 1 ","  c #000000",". c #008000","X c #00C000","o c #00FF00","O c #808000","+ c #C0C000","@ c #FFFF00","# c #008080","$ c #00C0C0","% c #00FFFF","& c #C0FFC0","* c #FFFFC0","= c #C0FFFF","- c None",/* pixels */"-----  ---------","---- &&  -------","--- &&&oo ------","-- ooooo.   ----","-- XXoo.. ==  --","-- XXX.. ===%% -","-- XXX. %%%%%# -","---   . $$%%## -","--- **  $$$### -","-- ***@@ $$## --","- @@@@@O  $# ---","- ++@@OO -  ----","- +++OOO -------","- +++OO --------","--  +O ---------","----  ----------"};' or '}',not CURSES and '/* XPM */static char *typedef[] = {/* columns rows colors chars-per-pixel */"16 16 10 1 ","  c #000000",". c #404040","X c #6D6D6D","o c #777777","O c #949494","+ c #ACACAC","@ c #BBBBBB","# c #DBDBDB","$ c #EEEEEE","% c None",/* pixels */"%%%%%  %%%%%%%%%","%%%% ##  %%%%%%%","%%% ###++ %%%%%%","%% +++++.   %%%%","%% oo++.. $$  %%","%% ooo.. $$$@@ %","%% ooo. @@@@@X %","%%%   . OO@@XX %","%%% ##  OOOXXX %","%% ###++ OOXX %%","% +++++.  OX %%%","% oo++.. %  %%%%","% ooo... %%%%%%%","% ooo.. %%%%%%%%","%%  o. %%%%%%%%%","%%%%  %%%%%%%%%%"};' or ':',CLASS=1,NAMESPACE=2,METHOD=3,SIGNAL=4,SLOT=5,VARIABLE=6,STRUCT=7,TYPEDEF=8}
events.connect(events.VIEW_NEW, function()
  local view = buffer ~= ui.command_entry and view or ui.command_entry
  for name, i in pairs(M.XPM_IMAGES) do
    if type(name) == 'string' then view:register_image(i, M.XPM_IMAGES[i]) end
  end
end)
for _ = 1, #M.XPM_IMAGES do _SCINTILLA.next_image_type() end -- sync

---
-- Map of lexer names to line comment strings for programming languages, used by
-- the `toggle_comment()` function.
-- Keys are lexer names and values are either the language's line comment
-- prefixes or block comment delimiters separated by a '|' character.
-- @class table
-- @name comment_string
-- @see toggle_comment
M.comment_string = {actionscript='//',ada='--',apdl='!',ansi_c='/*|*/',antlr='//',apl='#',applescript='--',asp='\'',autoit=';',awk='#',b_lang='//',bash='#',batch=':',bibtex='%',boo='#',chuck='//',clojure=';',cmake='#',coffeescript='#',context='%',cpp='//',crystal='#',csharp='//',css='/*|*/',cuda='//',desktop='#',django='{#|#}',dmd='//',dockerfile='#',dot='//',eiffel='--',elixir='#',elm='--',erlang='%',fantom='//',faust='//',fennel=';',fish='#',forth='|\\',fortran='!',fsharp='//',gap='#',gettext='#',gherkin='#',glsl='//',gnuplot='#',go='//',groovy='//',gtkrc='#',haskell='--',html='<!--|-->',icon='#',idl='//',inform='!',ini='#',Io='#',java='//',javascript='//',jq='#',json='/*|*/',jsp='//',julia='#',latex='%',ledger='#',less='//',lilypond='%',lisp=';',logtalk='%',lua='--',makefile='#',matlab='#',moonscript='--',myrddin='//',nemerle='//',nim='#',nsis='#',objective_c='//',pascal='//',perl='#',php='//',pico8='//',pike='//',pkgbuild='#',prolog='%',props='#',protobuf='//',ps='%',pure='//',python='#',rails='#',rc='#',rebol=';',rest='.. ',rexx='--',rhtml='<!--|-->',rstats='#',ruby='#',rust='//',sass='//',scala='//',scheme=';',smalltalk='"|"',sml='(*)',snobol4='#',sql='--',tcl='#',tex='%',text='',toml='#',vala='//',vb='\'',vbscript='\'',verilog='//',vhdl='--',wsf='<!--|-->',xml='<!--|-->',yaml='#'}

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
-- File tables contain API file paths or functions that return such paths.
-- Each line in an API file consists of a symbol name (not a fully qualified
-- symbol name), a space character, and that symbol's documentation. "\n"
-- represents a newline character.
-- @class table
-- @name api_files
-- @see show_documentation
M.api_files = setmetatable({}, {__index = function(t, k)
  t[k] = {}
  return t[k]
end})

-- Matches characters specified in auto_pairs, taking multiple selections into
-- account.
events.connect(events.CHAR_ADDED, function(code)
  if not M.auto_pairs or not M.auto_pairs[code] then return end
  buffer:begin_undo_action()
  for i = 1, buffer.selections do
    local pos = buffer.selection_n_caret[i]
    buffer:set_target_range(pos, pos)
    buffer:replace_target(M.auto_pairs[code])
  end
  buffer:end_undo_action()
end)

-- Removes matched chars on backspace, taking multiple selections into account.
events.connect(events.KEYPRESS, function(code)
  if M.auto_pairs and keys.KEYSYMS[code] == '\b' and
     not ui.command_entry.active then
    buffer:begin_undo_action()
    for i = 1, buffer.selections do
      local pos = buffer.selection_n_caret[i]
      local complement = M.auto_pairs[buffer.char_at[pos - 1]]
      if complement and buffer.char_at[pos] == string.byte(complement) then
        buffer:delete_range(pos, 1)
      end
    end
    buffer:end_undo_action()
  end
end, 1) -- need index of 1 because default key handler halts propagation

-- Highlights matching braces.
events.connect(events.UPDATE_UI, function(updated)
  if updated & 3 == 0 then return end -- ignore scrolling
  if M.brace_matches[buffer.char_at[buffer.current_pos]] then
    local match = buffer:brace_match(buffer.current_pos, 0)
    local f = match ~= -1 and view.brace_highlight or view.brace_bad_light
    f(buffer, buffer.current_pos, match)
  else
    view:brace_bad_light(-1)
  end
end)

-- Clears highlighted word indicators.
local function clear_highlighted_words()
  buffer.indicator_current = M.INDIC_HIGHLIGHT
  buffer:indicator_clear_range(1, buffer.length)
end
events.connect(events.KEYPRESS, function(code)
  if keys.KEYSYMS[code] == 'esc' then clear_highlighted_words() end
end, 1)

-- Highlight all instances of the current or selected word.
events.connect(events.UPDATE_UI, function(updated)
  if updated & buffer.UPDATE_SELECTION == 0 or ui.find.active then return end
  local word
  if M.highlight_words == M.HIGHLIGHT_CURRENT then
    clear_highlighted_words()
    local s = buffer:word_start_position(buffer.current_pos, true)
    local e = buffer:word_end_position(buffer.current_pos, true)
    if s == e then return end
    word = buffer:text_range(s, e)
  elseif M.highlight_words == M.HIGHLIGHT_SELECTED then
    local s, e = buffer.selection_start, buffer.selection_end
    if s ~= e then clear_highlighted_words() end
    if not buffer:is_range_word(s, e) then return end
    word = buffer:text_range(s, e)
    if word:find(string.format('[^%s]', buffer.word_chars)) then return end
  else
    return
  end
  buffer.search_flags = buffer.FIND_MATCHCASE | buffer.FIND_WHOLEWORD
  buffer:target_whole_document()
  while buffer:search_in_target(word) ~= -1 do
    buffer:indicator_fill_range(
      buffer.target_start, buffer.target_end - buffer.target_start)
    buffer:set_target_range(buffer.target_end, buffer.length + 1)
  end
end)

-- Moves over typeover characters when typed, taking multiple selections into
-- account.
events.connect(events.KEYPRESS, function(code)
  if M.typeover_chars and M.typeover_chars[code] and
     not ui.command_entry.active then
    local handled = false
    for i = 1, buffer.selections do
      local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
      if s ~= e or buffer.char_at[s] ~= code then goto continue end
      buffer.selection_n_start[i], buffer.selection_n_end[i] = s + 1, s + 1
      handled = true
      ::continue::
    end
    if handled then return true end -- prevent typing
  end
end)

-- Auto-indent on return.
events.connect(events.CHAR_ADDED, function(code)
  if not M.auto_indent or code ~= string.byte('\n') then return end
  local line = buffer:line_from_position(buffer.current_pos)
  if line > 1 and buffer:get_line(line - 1):find('^[\r\n]+$') and
     buffer:get_line(line):find('^[^\r\n]') then
    return -- do not auto-indent when pressing enter from start of previous line
  end
  local i = line - 1
  while i >= 1 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
  if i >= 1 then
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

-- Prepares the buffer for saving to a file by stripping trailing whitespace,
-- ensuring a final newline, and normalizing line endings.
events.connect(events.FILE_BEFORE_SAVE, function()
  if not M.strip_trailing_spaces or not buffer.encoding then return end
  buffer:begin_undo_action()
  -- Strip trailing whitespace.
  for line = 1, buffer.line_count do
    local s, e = buffer:position_from_line(line), buffer.line_end_position[line]
    local i, byte = e - 1, buffer.char_at[e - 1]
    while i >= s and (byte == 9 or byte == 32) do -- '\t' or ' '
      i, byte = i - 1, buffer.char_at[i - 1]
    end
    if i < e - 1 then buffer:delete_range(i + 1, e - i - 1) end
  end
  -- Ensure final newline.
  if buffer.char_at[buffer.length] ~= 10 then buffer:append_text('\n') end
  -- Convert non-consistent EOLs
  buffer:convert_eols(buffer.eol_mode)
  buffer:end_undo_action()
end)

---
-- Pastes the text from the clipboard, taking into account the buffer's
-- indentation settings and the indentation of the current and preceding lines.
-- @name paste_reindent
function M.paste_reindent()
  local line = buffer:line_from_position(buffer.selection_start)
  -- Strip leading indentation from clipboard text.
  local text = ui.clipboard_text
  if not buffer.encoding then text = text:iconv('CP1252', 'UTF-8') end
  if buffer.eol_mode == buffer.EOL_CRLF then
    text = text:gsub('^\n', '\r\n'):gsub('([^\r])\n', '%1\r\n')
  end
  local lead = text:match('^[ \t]*')
  if lead ~= '' then text = text:sub(#lead + 1):gsub('\n' .. lead, '\n') end
  -- Change indentation to match buffer indentation settings.
  local tab_width = math.huge
  text = text:gsub('\n([ \t]+)', function(indentation)
    if indentation:find('^\t') then
      return buffer.use_tabs and '\n' .. indentation or
        '\n' .. indentation:gsub('\t', string.rep(' ', buffer.tab_width))
    else
      tab_width = math.min(tab_width, #indentation)
      local indent = math.floor(#indentation / tab_width)
      local spaces = string.rep(' ', math.fmod(#indentation, tab_width))
      return string.format(
        '\n%s%s', buffer.use_tabs and string.rep('\t', indent) or
        string.rep(' ', buffer.tab_width):rep(indent), spaces)
    end
  end)
  -- Re-indent according to whichever of the current and preceding lines has the
  -- higher indentation amount. However, if the preceding line is a fold header,
  -- indent by an extra level.
  local i = line - 1
  while i >= 1 and buffer:get_line(i):find('^[\r\n]+$') do i = i - 1 end
  if i < 1 or buffer.line_indentation[i] < buffer.line_indentation[line] then
    i = line
  end
  local indentation = buffer:text_range(
    buffer:position_from_line(i), buffer.line_indent_position[i])
  local fold_header =
    i ~= line and buffer.fold_level[i] & buffer.FOLDLEVELHEADERFLAG > 0
  if fold_header then
    indentation = indentation ..
      (buffer.use_tabs and '\t' or string.rep(' ', buffer.tab_width))
  end
  text = text:gsub('\n', '\n' .. indentation)
  -- Paste the text and adjust first and last line indentation accordingly.
  local start_indent = buffer.line_indentation[i]
  if fold_header then start_indent = start_indent + buffer.tab_width end
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
-- @name toggle_comment
function M.toggle_comment()
  local comment = M.comment_string[buffer:get_lexer(true)] or ''
  local prefix, suffix = comment:match('^([^|]+)|?([^|]*)$')
  if not prefix then return end
  local anchor, pos = buffer.selection_start, buffer.selection_end
  local s, e = buffer:line_from_position(anchor), buffer:line_from_position(pos)
  local ignore_last_line = s ~= e and pos == buffer:position_from_line(e)
  anchor, pos = buffer.line_end_position[s] - anchor, buffer.length + 1 - pos
  local column = math.huge
  buffer:begin_undo_action()
  for line = s, not ignore_last_line and e or e - 1 do
    local p = buffer.line_indent_position[line]
    column = math.min(buffer.column[p], column)
    p = buffer:find_column(line, column)
    local uncomment = buffer:text_range(p, p + #prefix) == prefix
    if not uncomment then
      buffer:insert_text(p, prefix)
      if suffix ~= '' then
        buffer:insert_text(buffer.line_end_position[line], suffix)
      end
    else
      buffer:delete_range(p, #prefix)
      if suffix ~= '' then
        p = buffer.line_end_position[line]
        buffer:delete_range(p - #suffix, #suffix)
      end
    end
    if line == s then anchor = anchor + #suffix * (uncomment and -1 or 1) end
    if line == e then pos = pos + #suffix * (uncomment and -1 or 1) end
  end
  buffer:end_undo_action()
  anchor, pos = buffer.line_end_position[s] - anchor, buffer.length + 1 - pos
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
  if not assert_type(line, 'number/nil', 1) then
    local button, value = ui.dialogs.inputbox{
      title = _L['Go To'], informative_text = _L['Line Number:'],
      button1 = _L['OK'], button2 = _L['Cancel']
    }
    line = tonumber(value)
    if button ~= 1 or not line then return end
  end
  view:ensure_visible_enforce_policy(line)
  buffer:goto_line(line)
end
args.register('-l', '--line', 1, function(line)
  M.goto_line(tonumber(line) or line)
end, 'Go to line')

---
-- Transposes characters intelligently.
-- If the caret is at the end of a line, transposes the two characters before
-- the caret. Otherwise, the characters to the left and right are.
-- @name transpose_chars
function M.transpose_chars()
  local pos = buffer.current_pos
  local line_end = buffer.line_end_position[buffer:line_from_position(pos)]
  if pos == line_end then pos = buffer:position_before(pos) end
  local pos1, pos2 = buffer:position_before(pos), buffer:position_after(pos)
  local ch1, ch2 = buffer:text_range(pos1, pos), buffer:text_range(pos, pos2)
  buffer:set_target_range(pos1, pos2)
  buffer:replace_target(ch2 .. ch1)
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
  assert_type(left, 'string', 1)
  assert_type(right, 'string', 2)
  buffer:begin_undo_action()
  for i = 1, buffer.selections do
    local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]
    if s == e then
      s = buffer:word_start_position(s, true)
      e = buffer:word_end_position(e, true)
    end
    buffer:set_target_range(s, e)
    buffer:replace_target(left .. buffer.target_text .. right)
    buffer.selection_n_start[i] = buffer.target_end
    buffer.selection_n_end[i] = buffer.target_end
  end
  buffer:end_undo_action()
end

-- Enclose selected text in punctuation or auto-paired characters.
events.connect(events.KEYPRESS, function(code, shift, ctrl, alt, cmd)
  if M.auto_enclose and not buffer.selection_empty and code < 256 and
     not ctrl and not alt and not cmd and not ui.command_entry.active then
    local char = string.char(code)
    if char:find('^%P') then return end -- not punctuation
    M.enclose(char, M.auto_pairs[code] or char)
    return true -- prevent typing
  end
end, 1)

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
  if assert_type(left, 'string/nil', 1) and assert_type(right, 'string', 2) then
    if anchor ~= pos then buffer:goto_pos(pos - #right) end
    buffer:search_anchor()
    s, e = buffer:search_prev(0, left), buffer:search_next(0, right)
  elseif M.auto_pairs then
    s = buffer.selection_start
    while s >= 1 do
      local match = M.auto_pairs[buffer.char_at[s]]
      if not match then goto continue end
      left, right = string.char(buffer.char_at[s]), match
      if buffer:brace_match(s, 0) >= buffer.selection_end - 1 then
        e = buffer:brace_match(s, 0)
        break
      elseif M.brace_matches[buffer.char_at[s]] or
             buffer.style_at[s] == buffer.style_at[buffer.selection_start] then
        buffer.search_flags = 0
        buffer:set_target_range(s + 1, buffer.length + 1)
        if buffer:search_in_target(match) >= buffer.selection_end - 1 then
          e = buffer.target_end - 1
          break
        end
      end
      ::continue::
      s = s - 1
    end
  end
  if s == -1 or e == -1 then return end
  if s + #left == anchor and e == pos then s, e = s - #left, e + #right end
  buffer:set_sel(s + #left, e)
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
    buffer.search_flags = buffer.search_flags | buffer.FIND_WHOLEWORD
    if all then buffer:multiple_select_add_next() end -- select word first
  end
  buffer['multiple_select_add_' .. (not all and 'next' or 'each')](buffer)
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
  buffer:begin_undo_action()
  for line = 1, buffer.line_count do
    local s = buffer:position_from_line(line)
    local indent = buffer.line_indentation[line]
    local e = buffer.line_indent_position[line]
    local current_indentation, new_indentation = buffer:text_range(s, e), nil
    if buffer.use_tabs then
      local tabs = indent // buffer.tab_width
      local spaces = math.fmod(indent, buffer.tab_width)
      new_indentation = string.rep('\t', tabs) .. string.rep(' ', spaces)
    else
      new_indentation = string.rep(' ', indent)
    end
    if current_indentation == new_indentation then goto continue end
    buffer:set_target_range(s, e)
    buffer:replace_target(new_indentation)
    ::continue::
  end
  buffer:end_undo_action()
end

---
-- Passes the selected text or all buffer text to string shell command *command*
-- as standard input (stdin) and replaces the input text with the command's
-- standard output (stdout). *command* may contain shell pipes ('|').
-- Standard input is as follows:
--
-- 1. If no text is selected, the entire buffer is used.
-- 2. If text is selected and spans a single line, only the selected text is
-- used.
-- 3. If text is selected and spans multiple lines, all text on the lines that
-- have text selected is passed as stdin. However, if the end of the selection
-- is at the beginning of a line, only the line ending delimiters from the
-- previous line are included. The rest of the line is excluded.
-- @param command The Linux, BSD, macOS, or Windows shell command to filter text
--   through. May contain pipes.
-- @name filter_through
function M.filter_through(command)
  assert(not (WIN32 and CURSES), 'not implemented in this environment')
  assert_type(command, 'string', 1)
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    -- Use the whole buffer as input.
    buffer:target_whole_document()
  else
    -- Use the selected lines as input.
    local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
    if i < j then
      s = buffer:position_from_line(i)
      if buffer.column[e] > 1 then e = buffer:position_from_line(j + 1) end
    end
    buffer:set_target_range(s, e)
  end
  local commands = lpeg.match(lpeg.Ct(lpeg.P{
    lpeg.C(lpeg.V('command')) * ('|' * lpeg.C(lpeg.V('command')))^0,
    command = (1 - lpeg.S('"\'|') + lpeg.V('str'))^1,
    str = '"' * (1 - lpeg.S('"\\') + lpeg.P('\\') * 1)^0 * lpeg.P('"')^-1 +
      "'" * (1 - lpeg.S("'\\") + lpeg.P('\\') * 1)^0 * lpeg.P("'")^-1,
  }), command)
  local output = buffer.target_text
  for i = 1, #commands do
    local p = assert(os.spawn(commands[i]:match('^%s*(.-)%s*$')))
    p:write(output)
    p:close()
    output = p:read('a') or ''
    if p:wait() ~= 0 then
      ui.statusbar_text = string.format(
        '"%s" %s', commands[i], _L['returned non-zero status'])
      return
    end
  end
  buffer:replace_target(output:iconv('UTF-8', _CHARSET))
  if s == e then buffer:goto_pos(s) return end
  buffer:set_sel(buffer.target_start, buffer.target_end)
end

---
-- Displays an autocompletion list provided by the autocompleter function
-- associated with string *name*, and returns `true` if completions were found.
-- @param name The name of an autocompleter function in the `autocompleters`
--   table to use for providing autocompletions.
-- @name autocomplete
-- @see autocompleters
function M.autocomplete(name)
  if not M.autocompleters[assert_type(name, 'string', 1)] then return end
  local len_entered, list = M.autocompleters[name]()
  if not len_entered or not list or #list == 0 then return end
  buffer.auto_c_order = buffer.ORDER_PERFORMSORT
  buffer:auto_c_show(
    len_entered, table.concat(list, string.char(buffer.auto_c_separator)))
  return true
end

-- Returns for the word part behind the caret a list of whole word completions
-- constructed from the current buffer or all open buffers (depending on
-- `M.autocomplete_all_words`).
-- If `buffer.auto_c_ignore_case` is `true`, completions are not case-sensitive.
-- @see buffer.word_chars
-- @see autocomplete
M.autocompleters.word = function()
  local list, matches = {}, {}
  local s = buffer:word_start_position(buffer.current_pos, true)
  if s == buffer.current_pos then return end
  local word_part = buffer:text_range(s, buffer.current_pos)
  for _, buffer in ipairs(_BUFFERS) do
    if buffer == _G.buffer or M.autocomplete_all_words then
      buffer.search_flags = buffer.FIND_WORDSTART |
        (not buffer.auto_c_ignore_case and buffer.FIND_MATCHCASE or 0)
      buffer:target_whole_document()
      while buffer:search_in_target(word_part) ~= -1 do
        local e = buffer:word_end_position(buffer.target_end, true)
        local match = buffer:text_range(buffer.target_start, e)
        if #match > #word_part and not matches[match] then
          list[#list + 1], matches[match] = match, true
        end
        buffer:set_target_range(e, buffer.length + 1)
      end
    end
  end
  return #word_part, list
end

local api_docs
---
-- Displays a call tip with documentation for the symbol under or directly
-- behind position *pos* or the caret position.
-- Documentation is read from API files in the `api_files` table.
-- If a call tip is already shown, cycles to the next one if it exists.
-- Symbols are determined by using `buffer.word_chars`.
-- @param pos Optional position of the symbol to show documentation for. If
--   omitted, the caret position is used.
-- @param ignore_case Optional flag that indicates whether or not to search
--   API files case-insensitively for symbols. The default value is `false`.
-- @name show_documentation
-- @see api_files
-- @see buffer.word_chars
function M.show_documentation(pos, ignore_case)
  if view:call_tip_active() then events.emit(events.CALL_TIP_CLICK) return end
  local api_files = M.api_files[buffer:get_lexer(true)]
  if not api_files then return end
  if not assert_type(pos, 'number/nil', 1) then pos = buffer.current_pos end
  local s = buffer:word_start_position(pos, true)
  local e = buffer:word_end_position(pos, true)
  local symbol = buffer:text_range(s, e)

  api_docs = {pos = pos, i = 1}
  ::lookup::
  if symbol ~= '' then
    local symbol_patt = '^' .. symbol:gsub('(%p)', '%%%1')
    if ignore_case then
      symbol_patt = symbol_patt:gsub('%a', function(letter)
        return string.format('[%s%s]', letter:upper(), letter:lower())
      end)
    end
    for _, file in ipairs(api_files) do
      if type(file) == 'function' then file = file() end
      if not file or not lfs.attributes(file) then goto continue end
      for line in io.lines(file) do
        if not line:find(symbol_patt) then goto continue end
        api_docs[#api_docs + 1] = line:match(symbol_patt .. '%s+(.+)$')
        ::continue::
      end
      ::continue::
    end
  end
  -- Search backwards for an open function call and show API documentation for
  -- that function as well.
  while s > 1 and buffer.char_at[s] ~= 40 do s = s - 1 end -- '('
  e = buffer:brace_match(s, 0)
  if s > 1 and (e == -1 or e >= pos) then
    s, e = buffer:word_start_position(s - 1, true), s - 1
    symbol = buffer:text_range(s, e + 1)
    goto lookup
  end

  if #api_docs == 0 then
    api_docs = nil -- prevent the call tip click handler below from running
    return
  end
  for i = 1, #api_docs do
    local doc = api_docs[i]:gsub('%f[\\]\\n', '\n'):gsub('\\\\', '\\')
    if #api_docs > 1 then
      if not doc:find('\n') then doc = doc .. '\n' end
      doc = '\001' .. doc:gsub('\n', '\n\002', 1)
    end
    api_docs[i] = doc
  end
  view:call_tip_show(pos, api_docs[api_docs.i])
end
-- Cycle through apidoc calltips.
events.connect(events.CALL_TIP_CLICK, function(position)
  if not api_docs then return end
  api_docs.i = api_docs.i + (position == 1 and -1 or 1)
  if api_docs.i > #api_docs then
    api_docs.i = 1
  elseif api_docs.i < 1 then
    api_docs.i = #api_docs
  end
  view:call_tip_show(api_docs.pos, api_docs[api_docs.i])
end)

return M

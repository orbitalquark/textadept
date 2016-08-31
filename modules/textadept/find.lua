-- Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = ui.find

--[[ This comment is for LuaDoc.
---
-- Textadept's Find & Replace pane.
-- @field find_entry_text (string)
--   The text in the "Find" entry.
-- @field replace_entry_text (string)
--   The text in the "Replace" entry.
-- @field match_case (bool)
--   Match search text case sensitively.
--   The default value is `false`.
-- @field whole_word (bool)
--   Match search text only when it is surrounded by non-word characters in
--   searches.
--   The default value is `false`.
-- @field regex (bool)
--   Interpret search text as a Regular Expression.
--   The default value is `false`.
-- @field in_files (bool)
--   Find search text in a list of files.
--   The default value is `false`.
-- @field find_label_text (string, Write-only)
--   The text of the "Find" label.
--   This is primarily used for localization.
-- @field replace_label_text (string, Write-only)
--   The text of the "Replace" label.
--   This is primarily used for localization.
-- @field find_next_button_text (string, Write-only)
--   The text of the "Find Next" button.
--   This is primarily used for localization.
-- @field find_prev_button_text (string, Write-only)
--   The text of the "Find Prev" button.
--   This is primarily used for localization.
-- @field replace_button_text (string, Write-only)
--   The text of the "Replace" button.
--   This is primarily used for localization.
-- @field replace_all_button_text (string, Write-only)
--   The text of the "Replace All" button.
--   This is primarily used for localization.
-- @field match_case_label_text (string, Write-only)
--   The text of the "Match case" label.
--   This is primarily used for localization.
-- @field whole_word_label_text (string, Write-only)
--   The text of the "Whole word" label.
--   This is primarily used for localization.
-- @field regex_label_text (string, Write-only)
--   The text of the "Regex" label.
--   This is primarily used for localization.
-- @field in_files_label_text (string, Write-only)
--   The text of the "In files" label.
--   This is primarily used for localization.
-- @field find_in_files_timeout (number)
--   The approximate interval in seconds between prompts for continuing an
--   "In files" search.
--   The default value is 10 seconds.
-- @field INDIC_FIND (number)
--   The find in files highlight indicator number.
-- @field _G.events.FIND_WRAPPED (string)
--   Emitted when a text search wraps (passes through the beginning of the
--   buffer), either from bottom to top (when searching for a next occurrence),
--   or from top to bottom (when searching for a previous occurrence).
--   This is useful for implementing a more visual or audible notice when a
--   search wraps in addition to the statusbar message.
module('ui.find')]]

local _L = _L
M.find_label_text = not CURSES and _L['_Find:'] or _L['Find:']
M.replace_label_text = not CURSES and _L['R_eplace:'] or _L['Replace:']
M.find_next_button_text = not CURSES and _L['Find _Next'] or _L['[Next]']
M.find_prev_button_text = not CURSES and _L['Find _Prev'] or _L['[Prev]']
M.replace_button_text = not CURSES and _L['_Replace'] or _L['[Replace]']
M.replace_all_button_text = not CURSES and _L['Replace _All'] or _L['[All]']
M.match_case_label_text = not CURSES and _L['_Match case'] or _L['Case(F1)']
M.whole_word_label_text = not CURSES and _L['_Whole word'] or _L['Word(F2)']
M.regex_label_text = not CURSES and _L['Rege_x'] or _L['Regex(F3)']
M.in_files_label_text = not CURSES and _L['_In files'] or _L['Files(F4)']

M.find_in_files_timeout = 10
M.INDIC_FIND = _SCINTILLA.next_indic_number()

-- Events.
events.FIND_WRAPPED = 'find_wrapped'

-- When finding in files, note the current view since results are shown in a
-- split view. Jumping between results should be done in the original view.
local preferred_view

---
-- The table of Lua patterns matching files and directories to exclude when
-- finding in files.
-- The filter table contains:
--
--   + Lua patterns that match filenames to exclude.
--   + Optional `folders` sub-table that contains patterns matching directories
--     to exclude.
--   + Optional `extensions` sub-table that contains raw file extensions to
--     exclude.
--   + Optional `symlink` flag that when `true`, excludes symlinked files (but
--     not symlinked directories).
--   + Optional `folders.symlink` flag that when `true`, excludes symlinked
--     directories.
--
-- Any patterns starting with '!' exclude files and directories that do not
-- match the pattern that follows.
-- The default value is `lfs.default_filter`, a filter for common binary file
-- extensions and version control directories.
-- @see find_in_files
-- @see lfs.default_filter
-- @class table
-- @name find_in_files_filter
M.find_in_files_filter = lfs.default_filter

-- Text escape sequences with their associated characters and vice-versa.
-- @class table
-- @name escapes
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}
for k, v in pairs(escapes) do escapes[v] = k end

-- Finds and selects text in the current buffer.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a number mask of 4 flags: match case (2),
--   whole word (4), Lua pattern (8), and in files (16) joined with binary OR.
--   If `nil`, this is determined based on the checkboxes in the find box.
-- @param no_wrap Flag indicating whether or not the search will not wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or `-1`
local function find(text, next, flags, no_wrap, wrapped)
  if text == '' then return end
  if not flags then
    flags = 0
    if M.match_case then flags = flags + buffer.FIND_MATCHCASE end
    if M.whole_word then flags = flags + buffer.FIND_WHOLEWORD end
    if M.regex then flags = flags + buffer.FIND_REGEXP end
    if M.in_files then flags = flags + 0x1000000 end -- next after 0x800000
  end
  if flags >= 0x1000000 then M.find_in_files() return end -- not performed here
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  -- If text is selected, assume it is from the current search and increment the
  -- caret appropriately for the next search.
  if not buffer.selection_empty then
    local pos = buffer[next and 'selection_end' or 'selection_start']
    buffer:goto_pos(buffer:position_relative(pos, next and 1 or -1))
  end

  -- Scintilla search.
  buffer:search_anchor()
  local f = buffer['search_'..(next and 'next' or 'prev')]
  local pos = f(buffer, flags, text)
  buffer:scroll_range(buffer.anchor, buffer.current_pos)

  -- If nothing was found, wrap the search.
  if pos == -1 and not no_wrap then
    local anchor = buffer.anchor
    buffer:goto_pos(next and 0 or buffer.length)
    ui.statusbar_text = _L['Search wrapped']
    events.emit(events.FIND_WRAPPED)
    pos = find(text, next, flags, true, true)
    if pos == -1 then
      ui.statusbar_text = _L['No results found']
      buffer:line_scroll(0, first_visible_line - buffer.first_visible_line)
      buffer:goto_pos(anchor)
    end
  elseif not wrapped then
    ui.statusbar_text = ''
  end

  return pos
end
events.connect(events.FIND, find)

local incremental_start

-- Finds and selects text incrementally in the current buffer from a starting
-- position.
-- Flags other than `FIND_MATCHCASE` are ignored.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Flag indicating whether or not to search from the current
--   position.
local function find_incremental(text, next, anchor)
  if anchor then
    incremental_start = buffer:position_relative(buffer.current_pos,
                                                 next and 1 or -1)
  end
  buffer:goto_pos(incremental_start or 0)
  find(text, next, M.match_case and buffer.FIND_MATCHCASE or 0)
end

---
-- Begins an incremental search using the command entry if *text* is `nil`.
-- Otherwise, continues an incremental search by searching for the next or
-- previous instance of string *text*, depending on boolean *next*.
-- *anchor* indicates whether or not to search for *text* starting from the
-- caret position instead of the position where the incremental search began.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality is unavailable until the search is finished or by pressing
-- `Esc` (`⎋` on Mac OSX | `Esc` in curses).
-- @param text The text to incrementally search for, or `nil` to begin an
--   incremental search.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Optional flag indicating whether or not to start searching from
--   the caret position. The default value is `false`.
-- @name find_incremental
function M.find_incremental(text, next, anchor)
  if text then find_incremental(text, next, anchor) return end
  incremental_start = buffer.current_pos
  ui.command_entry:set_text('')
  ui.command_entry.enter_mode('find_incremental')
end

---
-- Searches directory *dir* or the user-specified directory for files that match
-- search text and search options (subject to optional filter *filter*), and
-- prints the results to a buffer titled "Files Found", highlighting found text.
-- Use the `find_text`, `match_case`, `whole_word`, and `regex` fields to set
-- the search text and option flags, respectively.
-- @param dir Optional directory path to search. If `nil`, the user is prompted
--   for one.
-- @param filter Optional filter for files and directories to exclude. The
--   default value is `ui.find.find_in_files_filter`.
-- @see find_in_files_filter
-- @name find_in_files
function M.find_in_files(dir, filter)
  dir = dir or ui.dialogs.fileselect{
    title = _L['Find in Files'], select_only_directories = true,
    with_directory = io.get_project_root() or
                     (buffer.filename or ''):match('^.+[/\\]') or
                     lfs.currentdir()
  }
  if not dir then return end

  if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
  ui.silent_print = false
  ui._print(_L['[Files Found Buffer]'], _L['Find:']..' '..M.find_entry_text)
  buffer.indicator_current = M.INDIC_FIND
  local ff_buffer = buffer

  local buffer = buffer.new() -- temporary buffer
  buffer.code_page = 0
  local text, flags, found, ref_time = M.find_entry_text, 0, false, os.time()
  if M.match_case then flags = flags + buffer.FIND_MATCHCASE end
  if M.whole_word then flags = flags + buffer.FIND_WHOLEWORD end
  if M.regex then flags = flags + buffer.FIND_REGEXP end
  buffer.search_flags = flags
  lfs.dir_foreach(dir, function(filename)
    buffer:clear_all()
    buffer:empty_undo_buffer()
    local f = io.open(filename, 'rb')
    while f:read(0) do buffer:append_text(f:read(1048576)) end
    --buffer:set_text(f:read('*a'))
    f:close()
    local binary = nil -- determine lazily for performance reasons
    buffer:target_whole_document()
    while buffer:search_in_target(text) > -1 do
      found = true
      if binary == nil then binary = buffer:text_range(0, 65536):find('\0') end
      local utf8_filename = filename:iconv('UTF-8', _CHARSET)
      if not binary then
        local line_num = buffer:line_from_position(buffer.target_start)
        local line = buffer:get_line(line_num)
        ff_buffer:append_text(string.format('%s:%d:%s', utf8_filename,
                                            line_num + 1, line))
        local pos = ff_buffer.length - #line +
                    buffer.target_start - buffer:position_from_line(line_num)
        ff_buffer:indicator_fill_range(pos,
                                       buffer.target_end - buffer.target_start)
        if not line:find('\n$') then ff_buffer:append_text('\n') end
      else
        ff_buffer:append_text(string.format('%s:1:%s\n', utf8_filename,
                                            _L['Binary file matches.']))
        break
      end
      buffer:set_target_range(buffer.target_end, buffer.length)
    end
    if os.difftime(os.time(), ref_time) >= M.find_in_files_timeout then
      local continue = ui.dialogs.yesno_msgbox{
        title = _L['Continue?'],
        text = _L['Still searching in files... Continue waiting?'],
        icon = 'gtk-dialog-question', no_cancel = true
      } == 1
      if not continue then
        ff_buffer:append_text(_L['Find in Files aborted']..'\n')
        return false
      end
      ref_time = os.time()
    end
  end, filter or M.find_in_files_filter)
  if not found then ff_buffer:append_text(_L['No results found']) end
  buffer:delete() -- delete temporary buffer
  ui._print(_L['[Files Found Buffer]'], '') -- goto end, set save pos, etc.
end

-- Replaces found text.
-- `find()` is called first, to select any found text. The selected text is
-- then replaced by the specified replacement text.
-- This function ignores "Find in Files".
-- @param rtext The text to replace found text with. It can contain regex
--   capture groups (`\d` where 0 <= `d` <= 9).
-- @see find
local function replace(rtext)
  if buffer.selection_empty then return end
  if M.in_files then M.in_files = false end
  buffer:target_from_selection()
  buffer[not M.regex and 'replace_target' or 'replace_target_re'](buffer, rtext)
  buffer:set_sel(buffer.target_start, buffer.target_end)
end
events.connect(events.REPLACE, replace)

local INDIC_REPLACE = _SCINTILLA.next_indic_number()
-- Replaces all found text.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores "Find in Files".
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @see find
local function replace_all(ftext, rtext)
  if ftext == '' then return end
  if M.in_files then M.in_files = false end
  buffer:begin_undo_action()
  local count = 0
  if buffer.selection_empty then
    buffer:goto_pos(0)
    while find(ftext, true, nil, true) ~= -1 do
      if buffer.selection_empty then break end -- prevent infinite loops
      replace(rtext)
      count = count + 1
    end
  else
    local s, e = buffer.selection_start, buffer.selection_end
    buffer.indicator_current = INDIC_REPLACE
    buffer:indicator_fill_range(e, 1)
    buffer:goto_pos(s)
    local pos = find(ftext, true, nil, true)
    while pos ~= -1 and pos < buffer:indicator_end(INDIC_REPLACE, s) do
      replace(rtext)
      count = count + 1
      pos = find(ftext, true, nil, true)
    end
    e = buffer:indicator_end(INDIC_REPLACE, s)
    buffer:set_sel(s, e > 0 and e or buffer.length)
    buffer:indicator_clear_range(e, 1)
  end
  ui.statusbar_text = string.format('%d %s', count, _L['replacement(s) made'])
  buffer:end_undo_action()
end
events.connect(events.REPLACE_ALL, replace_all)

-- Returns whether or not the given buffer is a files found buffer.
local function is_ff_buf(buf) return buf._type == _L['[Files Found Buffer]'] end
---
-- Jumps to the source of the find in files search result on line number
-- *line_num* in the buffer titled "Files Found" or, if *line_num* is `nil`,
-- jumps to the next or previous search result, depending on boolean *next*.
-- @param line_num The line number in the files found buffer that contains the
--   search result to go to.
-- @param next Optional flag indicating whether to go to the next search result
--   or the previous one. Only applicable when *line_num* is `nil` or `false`.
-- @name goto_file_found
function M.goto_file_found(line_num, next)
  local ff_view, ff_buf = nil, nil
  for i = 1, #_VIEWS do
    if is_ff_buf(_VIEWS[i].buffer) then ff_view = _VIEWS[i] break end
  end
  for i = 1, #_BUFFERS do
    if is_ff_buf(_BUFFERS[i]) then ff_buf = _BUFFERS[i] break end
  end
  if not ff_view and not ff_buf then return end
  if ff_view then ui.goto_view(ff_view) else view:goto_buffer(ff_buf) end

  -- If no line was given, find the next search result.
  if not line_num and next ~= nil then
    if next then buffer:line_end() else buffer:home() end
    buffer:search_anchor()
    local f = buffer['search_'..(next and 'next' or 'prev')]
    local pos = f(buffer, buffer.FIND_REGEXP, '^.+:\\d+:.+$')
    if pos == -1 then
      buffer:goto_line(next and 0 or buffer.line_count)
      buffer:search_anchor()
      pos = f(buffer, buffer.FIND_REGEXP, '^.+:\\d+:.+$')
    end
    if pos == -1 then return end
    line_num = buffer:line_from_position(pos)
  end
  buffer:goto_line(line_num)

  -- Goto the source of the search result.
  local line = buffer:get_cur_line()
  local utf8_filename, pos
  utf8_filename, line_num, pos = line:match('^(.+):(%d+):().+$')
  if not utf8_filename then return end
  textadept.editing.select_line()
  pos = buffer.anchor + pos - 1 -- absolute position of result text on line
  local s = buffer:indicator_end(M.INDIC_FIND, pos)
  local e = buffer:indicator_end(M.INDIC_FIND, s + 1)
  if buffer:line_from_position(s) == buffer:line_from_position(pos) then
    s, e = s - pos, e - pos -- relative to line start
  else
    s, e = 0, 0 -- binary file notice, or highlighting was somehow removed
  end
  ui.goto_file(utf8_filename:iconv(_CHARSET, 'UTF-8'), true, preferred_view)
  textadept.editing.goto_line(line_num - 1)
  if buffer:line_from_position(buffer.current_pos + s) == line_num - 1 then
    buffer:set_sel(buffer.current_pos + e, buffer.current_pos + s)
  end
end
events.connect(events.KEYPRESS, function(code)
  if keys.KEYSYMS[code] == '\n' and is_ff_buf(buffer) then
    M.goto_file_found(buffer:line_from_position(buffer.current_pos))
    return true
  end
end)
events.connect(events.DOUBLE_CLICK, function(_, line)
  if is_ff_buf(buffer) then M.goto_file_found(line) end
end)

--[[ The functions below are Lua C functions.

---
-- Displays and focuses the Find & Replace Pane.
-- @class function
-- @name focus
local focus

---
-- Mimics pressing the "Find Next" button.
-- @class function
-- @name find_next
local find_next

---
-- Mimics pressing the "Find Prev" button.
-- @class function
-- @name find_prev
local find_prev

---
-- Mimics pressing the "Replace" button.
-- @class function
-- @name replace
local replace

---
-- Mimics pressing the "Replace All" button.
-- @class function
-- @name replace_all
local replace_all
]]

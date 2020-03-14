-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

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
M.find_label_text = _L['Find:']
M.replace_label_text = _L['Replace:']
M.find_next_button_text = not CURSES and _L['Find Next'] or _L['[Next]']
M.find_prev_button_text = not CURSES and _L['Find Prev'] or _L['[Prev]']
M.replace_button_text = not CURSES and _L['Replace'] or _L['[Replace]']
M.replace_all_button_text = not CURSES and _L['Replace All'] or _L['[All]']
M.match_case_label_text = not CURSES and _L['Match case'] or _L['Case(F1)']
M.whole_word_label_text = not CURSES and _L['Whole word'] or _L['Word(F2)']
M.regex_label_text = not CURSES and _L['Regex'] or _L['Regex(F3)']
M.in_files_label_text = not CURSES and _L['In files'] or _L['Files(F4)']

M.find_in_files_timeout = 10
M.INDIC_FIND = _SCINTILLA.next_indic_number()

-- Events.
events.FIND_WRAPPED = 'find_wrapped'

-- When finding in files, note the current view since results are shown in a
-- split view. Jumping between results should be done in the original view.
local preferred_view

---
-- Map of file paths to filters used in `ui.find.find_in_files()`.
-- @class table
-- @name find_in_files_filters
-- @see find_in_files
M.find_in_files_filters = {}

-- Keep track of find text and found text so that "replace all" works as
-- expected during a find session ("replace all" with selected text normally
-- does "replace in selection").
local find_text, found_text

-- Returns a bit-mask of search flags to use in Scintilla search functions based
-- on the checkboxes in the find box.
-- The "Find in Files" flag is unused by Scintilla, but used by Textadept.
-- @return search flag bit-mask
local function get_flags()
  return (M.match_case and buffer.FIND_MATCHCASE or 0) +
    (M.whole_word and buffer.FIND_WHOLEWORD or 0) +
    (M.regex and buffer.FIND_REGEXP or 0) + (M.in_files and 1 << 31 or 0)
end

-- Finds and selects text in the current buffer.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a bit-mask of 4 flags:
--   `buffer.FIND_MATCHCASE`, `buffer.FIND_WHOLEWORD`, `buffer.FIND_REGEXP`, and
--   1 << 31 (in files), each joined with binary OR.
--   If `nil`, this is determined based on the checkboxes in the find box.
-- @param no_wrap Flag indicating whether or not the search will not wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or `-1`
local function find(text, next, flags, no_wrap, wrapped)
  -- Note: cannot use assert_type(), as event errors are handled silently.
  if text == '' then return end
  if not flags then flags = get_flags() end
  if flags >= 1 << 31 then M.find_in_files() return end -- not performed here
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  -- If text is selected, assume it is from the current search and move the
  -- caret appropriately for the next search.
  buffer:goto_pos(next and buffer.selection_end or buffer.selection_start)

  -- Scintilla search.
  buffer:search_anchor()
  local f = next and buffer.search_next or buffer.search_prev
  local pos = f(buffer, flags, text)
  buffer:ensure_visible_enforce_policy(buffer:line_from_position(pos))
  buffer:scroll_range(buffer.anchor, buffer.current_pos)
  find_text, found_text = text, buffer:get_sel_text() -- track for "replace all"

  -- If nothing was found, wrap the search.
  if pos == -1 and not no_wrap then
    local anchor = buffer.anchor
    buffer:goto_pos(next and 0 or buffer.length)
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
events.connect(
  events.FIND_WRAPPED, function() ui.statusbar_text = _L['Search wrapped'] end)

local incremental_start

-- Finds and selects text incrementally in the current buffer from a starting
-- position.
-- Flags other than `FIND_MATCHCASE` are ignored.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Flag indicating whether or not to search from the current
--   position.
local function find_incremental(text, next, anchor)
  local orig_pos = buffer.current_pos
  if anchor then
    incremental_start = buffer:position_relative(orig_pos, next and 1 or -1)
  end
  buffer:goto_pos(incremental_start or 0)
  -- Note: even though `events.FIND` does not support a flags parameter, the
  -- default handler has one, so make use of it.
  events.emit(
    events.FIND, text, next, M.match_case and buffer.FIND_MATCHCASE or 0)
  if buffer.selection_empty and anchor then buffer:goto_pos(orig_pos) end
end

---
-- Begins an incremental search using the command entry if *text* is `nil`.
-- Otherwise, continues an incremental search by searching for the next or
-- previous instance of string *text*, depending on boolean *next*.
-- *anchor* indicates whether or not to search for *text* starting from the
-- caret position instead of the position where the incremental search began.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality is unavailable until the search is finished or by pressing
-- `Esc`.
-- @param text The text to incrementally search for, or `nil` to begin an
--   incremental search.
-- @param next Flag indicating whether or not the search direction is forward.
--   Only applicable when *text* is not `nil`.
-- @param anchor Optional flag indicating whether or not to start searching from
--   the caret position. The default value is `false`.
-- @name find_incremental
function M.find_incremental(text, next, anchor)
  assert_type(text, 'string/nil', 1)
  if text then find_incremental(text, next, anchor) return end
  incremental_start = buffer.current_pos
  ui.command_entry:set_text('')
  ui.command_entry.run(nil, M.find_incremental_keys)
end

---
-- Table of key bindings used when searching for text incrementally.
-- @class table
-- @name find_incremental_keys
M.find_incremental_keys = setmetatable({
  ['\n'] = function()
    M.find_entry_text = ui.command_entry:get_text() -- save
    M.find_incremental(ui.command_entry:get_text(), true, true)
  end,
  ['\b'] = function()
    local e = ui.command_entry:position_before(ui.command_entry.length)
    M.find_incremental(ui.command_entry:text_range(0, e), true)
    return false -- propagate
  end
}, {__index = function(_, k)
  -- Add the character for any key pressed without modifiers to incremental
  -- find.
  if #k > 1 and k:find('^[cams]*.+$') then return end
  M.find_incremental(ui.command_entry:get_text() .. k, true)
end})

---
-- Searches directory *dir* or the user-specified directory for files that match
-- search text and search options (subject to optional filter *filter*), and
-- prints the results to a buffer titled "Files Found", highlighting found text.
-- Use the `find_text`, `match_case`, `whole_word`, and `regex` fields to set
-- the search text and option flags, respectively.
-- A filter determines which files to search in, with the default filter being
-- `lfs.default_filter`. A filter consists of Lua patterns that match filenames
-- to include or exclude. Exclusive patterns begin with a '!'. If no inclusive
-- patterns are given, any filename is initially considered. As a convenience,
-- file extensions can be specified literally instead of as a Lua pattern (e.g.
-- '.lua' vs. '%.lua$'), and '/' also matches the Windows directory separator
-- ('[/\\]' is not needed).
-- If *filter* is `nil`, the filter from the `ui.find.find_in_files_filters`
-- table is used. If that filter does not exist, `lfs.default_filter` is used.
-- @param dir Optional directory path to search. If `nil`, the user is prompted
--   for one.
-- @param filter Optional filter for files and directories to exclude. The
--   default value is `lfs.default_filter` unless a filter for *dir* is defined
--   in `ui.find.find_in_files_filters`.
-- @see find_in_files_filters
-- @name find_in_files
function M.find_in_files(dir, filter)
  if not assert_type(dir, 'string/nil', 1) then
    dir = ui.dialogs.fileselect{
      title = _L['Select Directory'], select_only_directories = true,
      with_directory = io.get_project_root() or
        (buffer.filename or ''):match('^.+[/\\]') or lfs.currentdir()
    }
    if not dir then return end
  end

  if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
  ui.silent_print = false
  ui._print(
    _L['[Files Found Buffer]'],
    string.format('%s %s', _L['Find:']:gsub('_', ''), M.find_entry_text))
  buffer.indicator_current = M.INDIC_FIND
  local ff_buffer = buffer

  local buffer = buffer.new() -- temporary buffer
  buffer.code_page = 0
  local text, found, ref_time = M.find_entry_text, false, os.time()
  buffer.search_flags = get_flags()
  lfs.dir_foreach(dir, function(filename)
    buffer:clear_all()
    buffer:empty_undo_buffer()
    local f = io.open(filename, 'rb')
    buffer:set_text(f:read('a'))
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
        ff_buffer:append_text(
          string.format('%s:%d:%s', utf8_filename, line_num + 1, line))
        local pos = ff_buffer.length - #line +
          buffer.target_start - buffer:position_from_line(line_num)
        ff_buffer:indicator_fill_range(
          pos, buffer.target_end - buffer.target_start)
        if not line:find('\n$') then ff_buffer:append_text('\n') end
      else
        ff_buffer:append_text(
          string.format('%s:1:%s\n', utf8_filename, _L['Binary file matches.']))
        break
      end
      buffer:set_target_range(buffer.target_end, buffer.length)
    end
    if os.difftime(os.time(), ref_time) >= M.find_in_files_timeout then
      local button = ui.dialogs.yesno_msgbox{
        title = _L['Continue?'],
        text = _L['Still searching in files... Continue waiting?'],
        icon = 'gtk-dialog-question', no_cancel = true
      }
      if button ~= 1 then
        ff_buffer:append_text(_L['Find in Files aborted'] .. '\n')
        return false
      end
      ref_time = os.time()
    end
  end, filter or M.find_in_files_filters[dir] or lfs.default_filter)
  if not found then ff_buffer:append_text(_L['No results found']) end
  buffer:delete() -- delete temporary buffer
  ui._print(_L['[Files Found Buffer]'], '') -- goto end, set save pos, etc.
end

-- Unescapes \uXXXX sequences in the string *text* and returns the result.
-- Just like with \n, \t, etc., escape sequence interpretation only happens for
-- regex search and replace.
-- @param text String text to unescape.
-- @return unescaped text
local function unescape(text)
  return M.regex and text:gsub('%f[\\]\\u(%x%x%x%x)', function(code)
    return utf8.char(tonumber(code, 16))
  end) or text
end

-- Replaces found (selected) text.
events.connect(events.REPLACE, function(rtext)
  if buffer.selection_empty then return end
  buffer:target_from_selection()
  local f = not M.regex and buffer.replace_target or buffer.replace_target_re
  f(buffer, unescape(rtext))
  buffer:set_sel(buffer.target_start, buffer.target_end)
end)

local INDIC_REPLACE = _SCINTILLA.next_indic_number()
-- Replaces all found text in the current buffer (ignores "Find in Files").
-- If any text is selected (other than text just found), only found text in that
-- selection is replaced.
events.connect(events.REPLACE_ALL, function(ftext, rtext)
  if ftext == '' then return end
  local count = 0
  local s, e = buffer.selection_start, buffer.selection_end
  local replace_in_sel =
    s ~= e and (ftext ~= find_text or buffer:get_sel_text() ~= found_text)
  if replace_in_sel then
    buffer.indicator_current = INDIC_REPLACE
    buffer:indicator_fill_range(e, 1)
  end
  local EOF = replace_in_sel and e == buffer.length -- no indicator at EOF
  local f = not M.regex and buffer.replace_target or buffer.replace_target_re
  rtext = unescape(rtext)

  -- Perform the search and replace.
  buffer:begin_undo_action()
  buffer.search_flags = get_flags()
  buffer:set_target_range(not replace_in_sel and 0 or s, buffer.length)
  while buffer:search_in_target(ftext) ~= -1 and (not replace_in_sel or
        buffer.target_end <= buffer:indicator_end(INDIC_REPLACE, s) or EOF) do
    if buffer.target_start == buffer.target_end then break end -- prevent loops
    f(buffer, rtext)
    count = count + 1
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
  buffer:end_undo_action()

  -- Restore any original selection and report the number of replacements made.
  if replace_in_sel then
    e = buffer:indicator_end(INDIC_REPLACE, s)
    buffer:set_sel(s, e > 0 and e or buffer.length)
    if e > 0 then buffer:indicator_clear_range(e, 1) end
  end
  ui.statusbar_text = string.format('%d %s', count, _L['replacement(s) made'])
end)

-- Returns whether or not the given buffer is a files found buffer.
local function is_ff_buf(buf) return buf._type == _L['[Files Found Buffer]'] end
---
-- Jumps to the source of the find in files search result on line number
-- *line_num* in the buffer titled "Files Found" or, if *line_num* is `nil`,
-- jumps to the next or previous search result, depending on boolean *next*.
-- @param line_num The line number in the files found buffer that contains the
--   search result to go to.
-- @param next Optional flag indicating whether to go to the next search result
--   or the previous one. Only applicable when *line_num* is `nil`.
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

  -- If no line was given, find the next search result, wrapping as necessary.
  if not assert_type(line_num, 'number/nil', 1) and next ~= nil then
    if next then buffer:line_end() else buffer:home() end
    buffer:search_anchor()
    local f = next and buffer.search_next or buffer.search_prev
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
  utf8_filename, line_num, pos = line:match('^(.+):(%d+):()')
  if not utf8_filename then return end
  textadept.editing.select_line()
  pos = buffer.selection_start + pos - 1 -- absolute pos of result text on line
  local s = buffer:indicator_end(M.INDIC_FIND, pos - 1)
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
  if keys.KEYSYMS[code] ~= '\n' or not is_ff_buf(buffer) then return end
  M.goto_file_found(buffer:line_from_position(buffer.current_pos))
  return true
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

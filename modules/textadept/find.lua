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
-- @field lua (bool)
--   Interpret search text as a Lua pattern.
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
-- @field lua_pattern_label_text (string, Write-only)
--   The text of the "Lua pattern" label.
--   This is primarily used for localization.
-- @field in_files_label_text (string, Write-only)
--   The text of the "In files" label.
--   This is primarily used for localization.
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
M.lua_pattern_label_text = not CURSES and _L['_Lua pattern'] or
                           _L['Pattern(F3)']
M.in_files_label_text = not CURSES and _L['_In files'] or _L['Files(F4)']

M.INDIC_FIND = _SCINTILLA.next_indic_number()

-- Events.
events.FIND_WRAPPED = 'find_wrapped'

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
-- The default value is `lfs.FILTER`, a filter for common binary file extensions
-- and version control directories.
-- @see find_in_files
-- @see lfs.FILTER
-- @class table
-- @name FILTER
M.FILTER = lfs.FILTER

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
    if M.lua then flags = flags + 8 end
    if M.in_files then flags = flags + 16 end
  end
  if flags >= 16 then M.find_in_files() return end -- not performed here
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  -- If text is selected, assume it is from the current search and increment the
  -- caret appropriately for the next search.
  if not buffer.selection_empty then
    local pos = buffer[next and 'current_pos' or 'anchor']
    buffer:goto_pos(buffer:position_relative(pos, next and 1 or -1))
  end

  local pos = -1
  if flags < 8 then
    -- Scintilla search.
    buffer:search_anchor()
    pos = buffer['search_'..(next and 'next' or 'prev')](buffer, flags, text)
    M.captures = nil -- clear captures from any previous Lua pattern searches
  elseif flags < 16 then
    -- Lua pattern search.
    -- Note: I do not trust utf8.find completely, so only use it if there are
    -- UTF-8 characters in the pattern. Otherwise default to string.find.
    local lib_find = not text:find('[\xC2-\xF4]') and string.find or utf8.find
    local s = next and buffer.current_pos or 0
    local e = next and buffer.length or buffer.current_pos
    local patt = text:gsub('\\[abfnrtv\\]', escapes)
    if not next then patt = '^.*()'..patt end
    local caps = {lib_find(buffer:text_range(s, e), patt)}
    M.captures = {table.unpack(caps, next and 3 or 4)}
    if #caps > 0 and caps[2] >= caps[1] then
      if lib_find == string.find then
        -- Positions are bytes.
        pos, e = s + caps[next and 1 or 3] - 1, s + caps[2]
      else
        -- Positions are characters, which may be multiple bytes.
        pos = buffer:position_relative(s, caps[next and 1 or 3] - 1)
        e = buffer:position_relative(s, caps[2])
      end
      M.captures[0] = buffer:text_range(pos, e)
      buffer:set_sel(e, pos)
    end
  end
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

-- Finds and selects text incrementally in the current buffer from a starting
-- position.
-- Flags other than `FIND_MATCHCASE` are ignored.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Flag indicating whether or not to search from the current
--   position.
local function find_incremental(text, next, anchor)
  if anchor then
    M._incremental_start = buffer:position_relative(buffer.current_pos,
                                                    next and 1 or -1)
  end
  buffer:goto_pos(M._incremental_start or 0)
  find(text, next, M.match_case and buffer.FIND_MATCHCASE or 0)
end

---
-- Begins an incremental search using the command entry if *text* is `nil`.
-- Otherwise, continues an incremental search by searching for the next or
-- previous instance of string *text*, depending on boolean *next*.
-- *anchor* indicates whether or not to search for *text* starting from the
-- caret position instead of the position where the incremental search began.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality is unavailable until the search is finished by pressing `Esc`
-- (`⎋` on Mac OSX | `Esc` in curses).
-- @param text The text to incrementally search for, or `nil` to begin an
--   incremental search.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Optional flag indicating whether or not to start searching from
--   the caret position. The default value is `false`.
-- @name find_incremental
function M.find_incremental(text, next, anchor)
  if text then find_incremental(text, next, anchor) return end
  M._incremental_start = buffer.current_pos
  ui.command_entry:set_text('')
  ui.command_entry.enter_mode('find_incremental')
end

---
-- Searches directory *dir* or the user-specified directory for files that match
-- search text and search options, and prints the results to a buffer titled
-- "Files Found".
-- Use the `find_text`, `match_case`, `whole_word`, and `lua` fields to set the
-- search text and option flags, respectively. Use `FILTER` to set the search
-- filter.
-- @param dir Optional directory path to search. If `nil`, the user is prompted
--   for one.
-- @see FILTER
-- @name find_in_files
function M.find_in_files(dir)
  dir = dir or ui.dialogs.fileselect{
    title = _L['Find in Files'], select_only_directories = true,
    with_directory = (buffer.filename or ''):match('^.+[/\\]') or
                     lfs.currentdir()
  }
  if not dir then return end

  local text = M.find_entry_text
  if not M.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
  if not M.match_case then text = text:lower() end
  if M.whole_word then text = '%f[%w_]'..text..'%f[^%w_]' end -- TODO: wordchars

  if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
  ui.SILENT_PRINT = false
  ui._print(_L['[Files Found Buffer]'], _L['Find:']..' '..text)
  buffer.indicator_current = M.INDIC_FIND

  -- Note: I do not trust utf8.find completely, so only use it if there are
  -- UTF-8 characters in the pattern. Otherwise default to string.find.
  local lib_find = not text:find('[\xC2-\xF4]') and string.find or utf8.find
  local found = false
  lfs.dir_foreach(dir, function(filename)
    local match_case = M.match_case
    local line_num = 1
    for line in io.lines(filename) do
      local s, e = lib_find(match_case and line or line:lower(), text)
      if s and e then
        local utf8_filename = filename:iconv('UTF-8', _CHARSET)
        buffer:append_text(string.format('%s:%d:%s\n', utf8_filename, line_num,
                                         line))
        local pos = buffer:position_from_line(buffer.line_count - 2) +
                    #utf8_filename + #tostring(line_num) + 2
        if lib_find == string.find then
          -- Positions are bytes.
          buffer:indicator_fill_range(pos + s - 1, e - s + 1)
        else
          -- Positions are characters, which may be multiple bytes.
          s = buffer:position_relative(pos, s - 1)
          e = buffer:position_relative(pos, e)
          buffer:indicator_fill_range(s, e - s)
        end
        found = true
      end
      line_num = line_num + 1
    end
  end, M.FILTER, true)
  if not found then buffer:append_text(_L['No results found']) end
  ui._print(_L['[Files Found Buffer]'], '') -- goto end, set save pos, etc.
end

-- Replaces found text.
-- `find()` is called first, to select any found text. The selected text is
-- then replaced by the specified replacement text.
-- This function ignores "Find in Files".
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (`%n` where 1 <= `n` <= 9) for Lua pattern searches and `%()`
--   sequences for embedding Lua code for any search.
-- @see find
local function replace(rtext)
  if buffer.selection_empty then return end
  if M.in_files then M.in_files = false end
  buffer:target_from_selection()
  rtext = rtext:gsub('\\[abfnrtv\\]', escapes):gsub('%%%%', '\\037')
  if M.captures then
    for i = 0, #M.captures do
      rtext = rtext:gsub('%%'..i, (M.captures[i]:gsub('%%', '%%%%')))
    end
  end
  local ok
  ok, rtext = pcall(string.gsub, rtext, '%%(%b())', function(code)
    code = code:gsub('[\a\b\f\n\r\t\v\\]', escapes)
    local result = assert(load('return '..code))()
    return tostring(result):gsub('\\[abfnrtv\\]', escapes)
  end)
  if ok then
    buffer:replace_target(rtext:gsub('\\037', '%%'))
    buffer:goto_pos(buffer.target_end) -- 'find' text after this replacement
  else
    ui.dialogs.msgbox{
      title = _L['Error'], text = _L['An error occured:'],
      informative_text = rtext:match(':1:(.+)$') or rtext:match(':%d+:(.+)$'),
      icon = 'gtk-dialog-error'
    }
    -- Since find is called after replace returns, have it 'find' the current
    -- text again, rather than the next occurance so the user can fix the error.
    buffer:goto_pos(buffer.current_pos)
  end
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
      replace(rtext)
      count = count + 1
    end
  else
    local s, e = buffer.selection_start, buffer.selection_end
    buffer.indicator_current = INDIC_REPLACE
    buffer:indicator_fill_range(e, 1)
    buffer:goto_pos(s)
    local pos = find(ftext, true, nil, true)
    while pos ~= -1 and pos <= buffer:indicator_end(INDIC_REPLACE, s) do
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
-- Jumps to the source of the find in files search result on line number *line*
-- in the buffer titled "Files Found" or, if *line* is `nil`, jumps to the next
-- or previous search result, depending on boolean *next*.
-- @param line The line number in the files found buffer that contains the
--   search result to go to.
-- @param next Optional flag indicating whether to go to the next search result
--   or the previous one. Only applicable when *line* is `nil` or `false`.
-- @name goto_file_found
function M.goto_file_found(line, next)
  local ff_view, ff_buf = nil, nil
  for i = 1, #_VIEWS do
    if is_ff_buf(_VIEWS[i].buffer) then ff_view = i break end
  end
  for i = 1, #_BUFFERS do
    if is_ff_buf(_BUFFERS[i]) then ff_buf = i break end
  end
  if not ff_view and not ff_buf then return end
  if ff_view then ui.goto_view(ff_view) else view:goto_buffer(ff_buf) end

  -- If no line was given, find the next search result.
  if not line and next ~= nil then
    if next then buffer:line_end() else buffer:home() end
    buffer:search_anchor()
    local f = buffer['search_'..(next and 'next' or 'prev')]
    local pos = f(buffer, buffer.FIND_REGEXP, '^.+:[0-9]+:.+$')
    if pos == -1 then
      buffer:goto_line(next and 0 or buffer.line_count)
      buffer:search_anchor()
      pos = f(buffer, buffer.FIND_REGEXP, '^.+:[0-9]+:.+$')
    end
    if pos == -1 then return end
    line = buffer:line_from_position(pos)
  end
  buffer:goto_line(line)

  -- Goto the source of the search result.
  local utf8_filename, line_num = buffer:get_cur_line():match('^(.+):(%d+):.+$')
  if not utf8_filename then return end
  textadept.editing.select_line()
  ui.goto_file(utf8_filename:iconv(_CHARSET, 'UTF-8'), true, preferred_view)
  textadept.editing.goto_line(line_num)
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

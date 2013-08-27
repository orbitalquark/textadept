-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = ui.find

--[[ This comment is for LuaDoc.
---
-- Textadept's Find & Replace pane.
-- @field find_entry_text (string)
--   The text in the find entry.
-- @field replace_entry_text (string)
--   The text in the replace entry.
-- @field match_case (bool)
--   Searches are case-sensitive.
--   The default value is `false`.
-- @field whole_word (bool)
--   Match only whole-words in searches.
--   The default value is `false`.
-- @field lua (bool)
--   Interpret search text as a Lua pattern.
--   The default value is `false`.
-- @field in_files (bool)
--   Search for the text in a list of files.
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
-- @field _G.events.FIND_WRAPPED (string)
--   Emitted when a search for text wraps, either from bottom to top when
--   searching for a next occurrence, or from top to bottom when searching for a
--   previous occurrence.
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

-- Events.
events.FIND_WRAPPED = 'find_wrapped'

local preferred_view

---
-- Table of Lua patterns matching files and folders to exclude when finding in
-- files.
-- Each filter string is a pattern that matches filenames to exclude, with
-- patterns matching folders to exclude listed in a `folders` sub-table.
-- Patterns starting with '!' exclude files and folders that do not match the
-- pattern that follows. Use a table of raw file extensions assigned to an
-- `extensions` key for fast filtering by extension. All strings must be encoded
-- in `_G._CHARSET`, not UTF-8.
-- The default value is `lfs.FILTER`, a filter for common binary file extensions
-- and version control folders.
-- @see find_in_files
-- @class table
-- @name FILTER
M.FILTER = lfs.FILTER

-- Text escape sequences with their associated characters.
-- @class table
-- @name escapes
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}

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
local function find_(text, next, flags, no_wrap, wrapped)
  if text == '' then return end
  if not flags then
    flags = 0
    if M.match_case then flags = flags + buffer.SCFIND_MATCHCASE end
    if M.whole_word then flags = flags + buffer.SCFIND_WHOLEWORD end
    if M.lua then flags = flags + 8 end
    if M.in_files then flags = flags + 16 end
  end
  if flags >= 16 then M.find_in_files() return end -- not performed here
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  -- If text is selected, assume it is from the current search and increment the
  -- caret appropriately for the next search.
  if buffer:get_sel_text() ~= '' then
    buffer:goto_pos(buffer[next and 'current_pos' or 'anchor'] +
                    (next and 1 or -1))
  end

  local pos = -1
  if flags < 8 then
    -- Scintilla search.
    buffer:search_anchor()
    pos = buffer['search_'..(next and 'next' or 'prev')](buffer, flags, text)
  elseif flags < 16 then
    -- Lua pattern search.
    local patt = text:gsub('\\[abfnrtv\\]', escapes)
    local s = next and buffer.current_pos or 0
    local e = next and buffer.length or buffer.current_pos
    local caps = {buffer:text_range(s, e):find(next and patt or '^.*()'..patt)}
    M.captures = {table.unpack(caps, next and 3 or 4)}
    if #caps > 0 and caps[2] >= caps[1] then
      pos, e = s + caps[next and 1 or 3] - 1, s + caps[2]
      buffer:set_sel(e, pos)
    end
  end
  buffer:scroll_range(buffer.anchor, buffer.current_pos)

  -- If nothing was found, wrap the search.
  if pos == -1 and not no_wrap then
    local anchor, pos = buffer.anchor, buffer.current_pos
    buffer:goto_pos(next and 0 or buffer.length)
    ui.statusbar_text = _L['Search wrapped']
    events.emit(events.FIND_WRAPPED)
    pos = find_(text, next, flags, true, true)
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
events.connect(events.FIND, find_)

-- Finds and selects text incrementally in the current buffer from a starting
-- position.
-- Flags other than `SCFIND_MATCHCASE` are ignored.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Flag indicating whether or not to search from the current
--   position.
local function find_incremental(text, next, anchor)
  if anchor then
    M.incremental_start = buffer.current_pos + (next and 1 or -1)
  end
  buffer:goto_pos(M.incremental_start or 0)
  find_(text, next, M.match_case and buffer.SCFIND_MATCHCASE or 0)
end

---
-- Begins an incremental search using the command entry if *text* is `nil`;
-- otherwise continues an incremental search by searching for the next or
-- previous instance of string *text* depending on boolean *next*.
-- If *anchor* is `true`, searches for *text* starting from the current position
-- instead of the position where incremental search began at.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality is unavailable until the search is finished by pressing `Esc`
-- (`⎋` on Mac OSX | `Esc` in curses).
-- @param text The text to incrementally search for, or `nil` to begin an
--   incremental search.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param anchor Optional flag indicating whether or not to start searching from
--   the current position. The default value is `false`.
-- @name find_incremental
function M.find_incremental(text, next, anchor)
  if text then find_incremental(text, next, anchor) return end
  M.incremental_start = buffer.current_pos
  ui.command_entry.entry_text = ''
  ui.command_entry.enter_mode('find_incremental')
end

---
-- Searches the *utf8_dir* or user-specified directory for files that match
-- search text and options and prints the results to a buffer.
-- Use the `find_text`, `match_case`, `whole_word`, and `lua` fields to set the
-- search text and option flags, respectively. Use `FILTER` to set the search
-- filter.
-- @param utf8_dir Optional UTF-8-encoded directory path to search. If `nil`,
--   the user is prompted for one.
-- @see FILTER
-- @name find_in_files
function M.find_in_files(utf8_dir)
  if not utf8_dir then
    utf8_dir = ui.dialog('fileselect',
                         '--title', _L['Find in Files'],
                         '--select-only-directories',
                         '--with-directory',
                         (buffer.filename or ''):match('^.+[/\\]') or '',
                         '--no-newline')
  end
  if utf8_dir == '' then return end

  local text = M.find_entry_text
  if not M.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
  if not M.match_case then text = text:lower() end
  if M.whole_word then text = '%f[%w_]'..text..'%f[^%w_]' end
  local matches = {_L['Find:']..' '..text}
  lfs.dir_foreach(utf8_dir, function(file)
    local match_case = M.match_case
    local line_num = 1
    for line in io.lines(file) do
      if (match_case and line or line:lower()):find(text) then
        file = file:iconv('UTF-8', _CHARSET)
        matches[#matches + 1] = ('%s:%s:%s'):format(file, line_num, line)
      end
      line_num = line_num + 1
    end
  end, M.FILTER, true)
  if #matches == 1 then matches[2] = _L['No results found'] end
  matches[#matches + 1] = ''
  if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
  ui._print(_L['[Files Found Buffer]'], table.concat(matches, '\n'))
end

-- Replaces found text.
-- `find_()` is called first, to select any found text. The selected text is
-- then replaced by the specified replacement text.
-- This function ignores "Find in Files".
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (`%n` where 1 <= `n` <= 9) for Lua pattern searches and `%()`
--   sequences for embedding Lua code for any search.
-- @see find
local function replace(rtext)
  if buffer:get_sel_text() == '' then return end
  if M.in_files then M.in_files = false end
  buffer:target_from_selection()
  rtext = rtext:gsub('%%%%', '\\037') -- escape '%%'
  if M.captures then
    for i = 1, #M.captures do
      rtext = rtext:gsub('%%'..i, (M.captures[i]:gsub('%%', '%%%%')))
    end
  end
  local ok, rtext = pcall(rtext.gsub, rtext, '%%(%b())', function(code)
    local ok, result = pcall(load('return '..code))
    if not ok then error(result) end
    return result
  end)
  if ok then
    rtext = rtext:gsub('\\037', '%%') -- unescape '%'
    buffer:replace_target(rtext:gsub('\\[abfnrtv\\]', escapes))
    buffer:goto_pos(buffer.target_end) -- 'find' text after this replacement
  else
    ui.dialog('ok-msgbox',
              '--title', _L['Error'],
              '--text', _L['An error occured:'],
              '--informative-text',
              rtext:match(':1:(.+)$') or rtext:match(':%d+:(.+)$'),
              '--icon', 'gtk-dialog-error',
              '--button1', _L['_OK'],
              '--button2', _L['_Cancel'],
              '--no-cancel')
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
  if buffer:get_sel_text() == '' then
    buffer:goto_pos(0)
    while(find_(ftext, true, nil, true) ~= -1) do
      replace(rtext)
      count = count + 1
    end
  else
    local s, e = buffer.selection_start, buffer.selection_end
    buffer.indicator_current = INDIC_REPLACE
    buffer:indicator_fill_range(e, 1)
    buffer:goto_pos(s)
    local pos = find_(ftext, true, nil, true)
    while pos ~= -1 and pos <= buffer:indicator_end(INDIC_REPLACE, s) do
      replace(rtext)
      count = count + 1
      pos = find_(ftext, true, nil, true)
    end
    e = buffer:indicator_end(INDIC_REPLACE, s)
    buffer:set_sel(s, e > 0 and e or buffer.length)
    buffer:indicator_clear_range(e, 1)
  end
  ui.statusbar_text = ("%d %s"):format(count, _L['replacement(s) made'])
  buffer:end_undo_action()
end
events.connect(events.REPLACE_ALL, replace_all)

-- Returns whether or not the given buffer is a files found buffer.
local function is_ff_buf(buf) return buf._type == _L['[Files Found Buffer]'] end
---
-- Goes to the source of the find in files search result on line number *line*
-- in the files found buffer, or if `nil`, the next or previous search result
-- depending on boolean *next*.
-- @param line The line number in the files found buffer that contains the
--   search result to go to.
-- @param next Optional flag indicating whether to go to the next search result
--   or the previous one. Only applicable when *line* is `nil` or `false`.
-- @name goto_file_found
function M.goto_file_found(line, next)
  local cur_buf, ff_view, ff_buf = _BUFFERS[buffer], nil, nil
  for i = 1, #_VIEWS do
    if is_ff_buf(_VIEWS[i].buffer) then ff_view = i break end
  end
  for i = 1, #_BUFFERS do
    if is_ff_buf(_BUFFERS[i]) then ff_buf = i break end
  end
  if not ff_view and not ff_buf then return end
  if ff_view then ui.goto_view(ff_view) else view:goto_buffer(ff_buf) end

  -- If not line was given, find the next search result.
  if not line and next ~= nil then
    if next then buffer:line_end() else buffer:home() end
    buffer:search_anchor()
    local f = buffer['search_'..(next and 'next' or 'prev')]
    local pos = f(buffer, buffer.SCFIND_REGEXP, '^.+:[0-9]+:.+$')
    if pos == -1 then
      buffer:goto_line(next and 0 or buffer.line_count)
      buffer:search_anchor()
      pos = f(buffer, buffer.SCFIND_REGEXP, '^.+:[0-9]+:.+$')
    end
    if pos == -1 then if CURSES then view:goto_buffer(cur_buf) end return end
    line = buffer:line_from_position(pos)
  end
  buffer:goto_line(line)

  -- Goto the source of the search result.
  local file, line_num = buffer:get_cur_line():match('^(.+):(%d+):.+$')
  if not file then if CURSES then view:goto_buffer(cur_buf) end return end
  _M.textadept.editing.select_line()
  ui.goto_file(file, true, preferred_view)
  _M.textadept.editing.goto_line(line_num)
end
events.connect(events.DOUBLE_CLICK, function(pos, line)
  if is_ff_buf(buffer) then M.goto_file_found(line) end
end)

--[[ The functions below are Lua C functions.

---
-- Displays and focuses the Find & Replace pane.
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

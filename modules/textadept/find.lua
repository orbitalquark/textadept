-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local find = gui.find

--[[ This comment is for LuaDoc.
---
-- Textadept's Find & Replace pane.
-- @field find_entry_text (string)
--   The text in the find entry.
-- @field replace_entry_text (string)
--   The text in the replace entry.
-- @field match_case (bool)
--   Searches are case-sensitive.
-- @field whole_word (bool)
--   Only whole-word matches are allowed in searches.
-- @field lua (bool)
--   The search text is interpreted as a Lua pattern.
-- @field in_files (bool)
--   Search for the text in a list of files.
-- @field find_label_text (string, Write-only)
--   The text of the 'Find' label.
--   This is primarily used for localization.
-- @field replace_label_text (string, Write-only)
--   The text of the 'Replace' label.
--   This is primarily used for localization.
-- @field find_next_button_text (string, Write-only)
--   The text of the 'Find Next' button.
--   This is primarily used for localization.
-- @field find_prev_button_text (string, Write-only)
--   The text of the 'Find Prev' button.
--   This is primarily used for localization.
-- @field replace_button_text (string, Write-only)
--   The text of the 'Replace' button.
--   This is primarily used for localization.
-- @field replace_all_button_text (string, Write-only)
--   The text of the 'Replace All' button.
--   This is primarily used for localization.
-- @field match_case_label_text (string, Write-only)
--   The text of the 'Match case' label.
--   This is primarily used for localization.
-- @field whole_word_label_text (string, Write-only)
--   The text of the 'Whole word' label.
--   This is primarily used for localization.
-- @field lua_pattern_label_text (string, Write-only)
--   The text of the 'Lua pattern' label.
--   This is primarily used for localization.
-- @field in_files_label_text (string, Write-only)
--   The text of the 'In files' label.
--   This is primarily used for localization.
-- @field _G.events.FIND_WRAPPED (string)
--   Called when a search for text wraps, either from bottom to top when
--   searching for a next occurrence, or from top to bottom when searching for a
--   previous occurrence.
--   This is useful for implementing a more visual or audible notice when a
--   search wraps in addition to the statusbar message.
module('gui.find')]]

local _L = _L
find.find_label_text = not NCURSES and _L['_Find:'] or _L['Find:']
find.replace_label_text = not NCURSES and _L['R_eplace:'] or _L['Replace:']
find.find_next_button_text = not NCURSES and _L['Find _Next'] or _L['[Next]']
find.find_prev_button_text = not NCURSES and _L['Find _Prev'] or _L['[Prev]']
find.replace_button_text = not NCURSES and _L['_Replace'] or _L['[Replace]']
find.replace_all_button_text = not NCURSES and _L['Replace _All'] or _L['[All]']
find.match_case_label_text = not NCURSES and _L['_Match case'] or _L['Case(F1)']
find.whole_word_label_text = not NCURSES and _L['_Whole word'] or _L['Word(F2)']
find.lua_pattern_label_text = not NCURSES and _L['_Lua pattern'] or
                              _L['Pattern(F3)']
find.in_files_label_text = not NCURSES and _L['_In files'] or _L['Files(F4)']

-- Events.
local events, events_connect = events, events.connect
events.FIND_WRAPPED = 'find_wrapped'

local MARK_FIND = _SCINTILLA.next_marker_number()
local MARK_FIND_COLOR = 0x4D9999
local preferred_view

-- Text escape sequences with their associated characters.
-- @class table
-- @name escapes
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}

---
-- Searches the given directory for files that match search text and options and
-- prints the results to a buffer.
-- Use the `find_text`, `match_case`, `whole_word`, and `lua` fields to set the
-- search text and option flags, respectively.
-- @param utf8_dir UTF-8 encoded directory name. If `nil`, the user is prompted
-- for one.
-- @name find_in_files
function find.find_in_files(utf8_dir)
  if not utf8_dir then
    utf8_dir = gui.dialog('fileselect',
                          '--title', _L['Find in Files'],
                          '--button1', _L['_Open'],
                          '--button2', _L['_Cancel'],
                          '--select-only-directories',
                          '--with-directory',
                          (buffer.filename or ''):match('^.+[/\\]') or '',
                          '--no-newline')
  end
  if #utf8_dir > 0 then
    local text = find.find_entry_text
    if not find.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
    if not find.match_case then text = text:lower() end
    if find.whole_word then text = '%f[%w_]'..text..'%f[^%w_]' end
    local match_case, whole_word = find.match_case, find.whole_word
    local matches = { 'Find: '..text }
    function search_file(file)
      local line_num = 1
      for line in io.lines(file) do
        local optimized_line = line
        if not match_case then optimized_line = line:lower() end
        if optimized_line:find(text) then
          file = file:iconv('UTF-8', _CHARSET)
          matches[#matches + 1] = ('%s:%s:%s'):format(file, line_num, line)
        end
        line_num = line_num + 1
      end
    end
    local lfs_dir, lfs_attributes = lfs.dir, lfs.attributes
    function search_dir(directory)
      for file in lfs_dir(directory) do
        if not file:find('^%.%.?$') then -- ignore . and ..
          local path = directory..(not WIN32 and '/' or '\\')..file
          local type = lfs_attributes(path, 'mode')
          if type == 'directory' then
            search_dir(path)
          elseif type == 'file' then
            search_file(path)
          end
        end
      end
    end
    local dir = utf8_dir:iconv(_CHARSET, 'UTF-8')
    search_dir(dir)
    if #matches == 1 then matches[2] = _L['No results found'] end
    matches[#matches + 1] = ''
    if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
    gui._print(_L['[Files Found Buffer]'], table.concat(matches, '\n'))
  end
end

local c = _SCINTILLA.constants

-- Finds and selects text in the current buffer.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a number mask of 4 flags: match case (2),
--   whole word (4), Lua pattern (8), and in files (16) joined with binary OR.
--   If `nil`, this is determined based on the checkboxes in the find box.
-- @param nowrap Flag indicating whether or not the search will not wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or `-1`
local function find_(text, next, flags, nowrap, wrapped)
  if text == '' then return end
  local buffer = buffer
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  local increment
  if buffer.current_pos == buffer.anchor then
    increment = 0
  elseif not wrapped then
    increment = next and 1 or -1
  end

  if not flags then
    flags = 0
    if find.match_case then flags = flags + c.SCFIND_MATCHCASE end
    if find.whole_word then flags = flags + c.SCFIND_WHOLEWORD end
    if find.lua then flags = flags + 8 end
    if find.in_files then flags = flags + 16 end
  end

  local result
  find.captures = nil

  if flags < 8 then
    buffer:goto_pos(buffer[next and 'current_pos' or 'anchor'] + increment)
    buffer:search_anchor()
    result = buffer['search_'..(next and 'next' or 'prev')](buffer, flags, text)
    if result ~= -1 then buffer:scroll_caret() end
  elseif flags < 16 then -- lua pattern search (forward search only)
    text = text:gsub('\\[abfnrtv\\]', escapes)
    local buffer_text = buffer:get_text(buffer.length)
    local results = { buffer_text:find(text, buffer.anchor + increment + 1) }
    if #results > 0 then
      find.captures = { table.unpack(results, 3) }
      buffer:set_sel(results[2], results[1] - 1)
    end
    result = results[1] or -1
  else -- find in files
    find.find_in_files()
    return
  end

  if result == -1 and not nowrap and not wrapped then -- wrap the search
    local anchor, pos = buffer.anchor, buffer.current_pos
    buffer:goto_pos((next or flags >= 8) and 0 or buffer.length)
    gui.statusbar_text = _L['Search wrapped']
    events.emit(events.FIND_WRAPPED)
    result = find_(text, next, flags, true, true)
    if result == -1 then
      gui.statusbar_text = _L['No results found']
      buffer:line_scroll(0, first_visible_line)
      buffer:goto_pos(anchor)
    end
    return result
  elseif result ~= -1 and not wrapped then
    gui.statusbar_text = ''
  end

  return result
end
events_connect(events.FIND, find_)

-- Finds and selects text incrementally in the current buffer from a start
-- point.
-- Flags other than `SCFIND_MATCHCASE` are ignored.
-- @param text The text to find.
local function find_incremental(text)
  local flags = find.match_case and c.SCFIND_MATCHCASE or 0
  buffer:goto_pos(find.incremental_start or 0)
  find_(text, true, flags)
end

---
-- Begins an incremental find using the command entry.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality will be unavailable until the search is finished by pressing
-- `Esc` (`⎋` on Mac OSX | `Esc` in ncurses).
-- @name find_incremental
function find.find_incremental()
  find.incremental, find.incremental_start = true, buffer.current_pos
  gui.command_entry.entry_text = ''
  gui.command_entry.focus()
end

events_connect(events.COMMAND_ENTRY_KEYPRESS, function(code)
  if not find.incremental then return end
  if not NCURSES and keys.KEYSYMS[code] == 'esc' or code == 27 then
    find.incremental = nil
  elseif keys.KEYSYMS[code] == '\b' then
    find_incremental(gui.command_entry.entry_text:sub(1, -2))
  elseif code < 256 then
    find_incremental(gui.command_entry.entry_text..string.char(code))
  end
end, 1) -- place before command_entry.lua's handler (if necessary)

-- 'Find next' for incremental search.
events_connect(events.COMMAND_ENTRY_COMMAND, function(text)
  if find.incremental then
    find.incremental_start = buffer.current_pos + 1
    find_incremental(text)
    return true
  end
end, 1) -- place before command_entry.lua's handler (if necessary)

-- Optimize for speed.
local load, pcall = load, pcall

-- Runs the given code.
-- This function is passed to `string.gsub()` in the `replace()` function.
-- @param code The code to run.
local function run(code)
  local ok, val = pcall(load('return '..code))
  if not ok then
    gui.dialog('ok-msgbox',
               '--title', _L['Error'],
               '--text', _L['An error occured:'],
               '--informative-text', val:gsub('"', '\\"'),
               '--button1', _L['_OK'],
               '--button2', _L['_Cancel'],
               '--no-cancel')
    error()
  end
  return val
end

-- Replaces found text.
-- `find_()` is called first, to select any found text. The selected text is
-- then replaced by the specified replacement text.
-- This function ignores 'Find in Files'.
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (`%n` where 1 <= `n` <= 9) for Lua pattern searches and `%()`
--   sequences for embedding Lua code for any search.
-- @see find
local function replace(rtext)
  if buffer:get_sel_text() == '' then return end
  if find.in_files then find.in_files = false end
  local buffer = buffer
  buffer:target_from_selection()
  rtext = rtext:gsub('%%%%', '\\037') -- escape '%%'
  local captures = find.captures
  if captures then
    for i = 1, #captures do
      rtext = rtext:gsub('%%'..i, (captures[i]:gsub('%%', '%%%%')))
    end
  end
  local ok, rtext = pcall(rtext.gsub, rtext, '%%(%b())', run)
  if ok then
    rtext = rtext:gsub('\\037', '%%') -- unescape '%'
    buffer:replace_target(rtext:gsub('\\[abfnrtv\\]', escapes))
    buffer:goto_pos(buffer.target_end) -- 'find' text after this replacement
  else
    -- Since find is called after replace returns, have it 'find' the current
    -- text again, rather than the next occurance so the user can fix the error.
    buffer:goto_pos(buffer.current_pos)
  end
end
events_connect(events.REPLACE, replace)

-- Replaces all found text.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores 'Find in Files'.
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @param flags The number mask identical to the one in `find_()`.
-- @see find
local function replace_all(ftext, rtext, flags)
  if #ftext == 0 then return end
  if find.in_files then find.in_files = false end
  local buffer = buffer
  buffer:begin_undo_action()
  local count = 0
  if #buffer:get_sel_text() == 0 then
    buffer:goto_pos(0)
    while(find_(ftext, true, flags, true) ~= -1) do
      replace(rtext)
      count = count + 1
    end
  else
    local anchor, current_pos = buffer.selection_start, buffer.selection_end
    local s, e = anchor, current_pos
    buffer:insert_text(e, '\n')
    local end_marker = buffer:marker_add(buffer:line_from_position(e + 1),
                                         MARK_FIND)
    buffer:goto_pos(s)
    local pos = find_(ftext, true, flags, true)
    while pos ~= -1 and
          pos < buffer:position_from_line(
                       buffer:marker_line_from_handle(end_marker)) do
      replace(rtext)
      count = count + 1
      pos = find_(ftext, true, flags, true)
    end
    e = buffer:position_from_line(buffer:marker_line_from_handle(end_marker))
    buffer:goto_pos(e)
    buffer:delete_back() -- delete '\n' added
    if s == current_pos then anchor = e - 1 else current_pos = e - 1 end
    buffer:set_sel(anchor, current_pos)
    buffer:marker_delete_handle(end_marker)
  end
  gui.statusbar_text = ("%d %s"):format(count, _L['replacement(s) made'])
  buffer:end_undo_action()
end
events_connect(events.REPLACE_ALL, replace_all)

-- When the user double-clicks a found file, go to the line in the file the text
-- was found at.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
local function goto_file(pos, line_num)
  if buffer._type == _L['[Files Found Buffer]'] then
    line = buffer:get_line(line_num)
    local file, file_line_num = line:match('^(.+):(%d+):.+$')
    if file and file_line_num then
      buffer:marker_delete_all(MARK_FIND)
      buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR
      buffer:marker_add(line_num, MARK_FIND)
      buffer:goto_pos(buffer.current_pos)
      gui.goto_file(file, true, preferred_view)
      _M.textadept.editing.goto_line(file_line_num)
    end
  end
end
events_connect(events.DOUBLE_CLICK, goto_file)

---
-- Goes to the next or previous file found relative to the file on the current
-- line in the results list.
-- @param next Flag indicating whether or not to go to the next file.
-- @name goto_file_in_list
function find.goto_file_in_list(next)
  local orig_view = _VIEWS[view]
  for _, buffer in ipairs(_BUFFERS) do
    if buffer._type == _L['[Files Found Buffer]'] then
      for j, view in ipairs(_VIEWS) do
        if view.buffer == buffer then
          gui.goto_view(j)
          local orig_line = buffer:line_from_position(buffer.current_pos)
          local line = orig_line
          while true do
            line = line + (next and 1 or -1)
            if line > buffer.line_count - 1 then line = 0 end
            if line < 0 then line = buffer.line_count - 1 end
            -- Prevent infinite loops.
            if line == orig_line then gui.goto_view(orig_view) return end
            if buffer:get_line(line):match('^(.+):(%d+):.+$') then
              buffer:goto_line(line)
              goto_file(buffer.current_pos, line)
              return
            end
          end
        end
      end
    end
  end
end

if buffer then buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR end
events_connect(events.VIEW_NEW, function()
  buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR
end)

--[[ The functions below are Lua C functions.

---
-- Displays and focuses the Find & Replace pane.
-- @class function
-- @name focus
local focus

---
-- Mimicks a press of the 'Find Next' button.
-- @class function
-- @name find_next
local find_next

---
-- Mimicks a press of the 'Find Prev' button.
-- @class function
-- @name find_prev
local find_prev

---
-- Mimicks a press of the 'Replace' button.
-- @class function
-- @name replace
local replace

---
-- Mimicks a press of the 'Replace All' button.
-- @class function
-- @name replace_all
local replace_all
]]

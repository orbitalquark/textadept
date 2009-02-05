-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local find = textadept.find

local MARK_REPLACEALL_END = 0
local previous_view

---
-- [Local table] Text escape sequences with their associated characters.
-- @class table
-- @name escapes
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}

---
-- Finds and selects text in the current buffer.
-- This is used by the find dialog. It is recommended to use the buffer:find()
-- function for scripting.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a number mask of 4 flags: match case (2),
--   whole word (4), Lua pattern (8), and in files (16) joined with binary OR.
--   If nil, this is determined based on the checkboxes in the find box.
-- @param nowrap Flag indicating whether or not the search won't wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or -1
function find.find(text, next, flags, nowrap, wrapped)
  local buffer = buffer
  local locale = textadept.locale
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  local increment
  if buffer.current_pos == buffer.anchor then
    increment = 0
  elseif not wrapped then
    increment = next and 1 or -1
  end

  if not flags then
    local find, c = find, textadept.constants
    flags = 0
    if find.match_case then flags = flags + c.SCFIND_MATCHCASE end
    if find.whole_word then flags = flags + c.SCFIND_WHOLEWORD end
    if find.lua then flags = flags + 8 end
    if find.in_files then flags = flags + 16 end
  end

  local result
  find.captures = nil
  text = text:gsub('\\[abfnrtv\\]', escapes)

  if flags < 8 then
    buffer:goto_pos(buffer[next and 'current_pos' or 'anchor'] + increment)
    buffer:search_anchor()
    if next then
      result = buffer:search_next(flags, text)
    else
      result = buffer:search_prev(flags, text)
    end
    if result ~= -1 then buffer:scroll_caret() end

  elseif flags < 16 then -- lua pattern search (forward search only)
    local buffer_text = buffer:get_text(buffer.length)
    local results = { buffer_text:find(text, buffer.anchor + increment) }
    if #results > 0 then
      result = results[1]
      find.captures = { unpack(results, 3) }
      buffer:set_sel(results[2], result - 1)
    else
      result = -1
    end

  else -- find in files
    local dir =
      cocoa_dialog('fileselect', {
        title = locale.FIND_IN_FILES_TITLE,
        text = locale.FIND_IN_FILES_TEXT,
        ['select-only-directories'] = true,
        ['with-directory'] = (buffer.filename or ''):match('^.+[/\\]'),
        ['no-newline'] = true
      })
    if #dir > 0 then
      if not find.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
      if not find.match_case then text = text:lower() end
      if find.whole_word then text = '[^%W_]'..text..'[^%W_]' end
      local lfs = require 'lfs'
      local match_case = find.match_case
      local whole_word = find.whole_word
      local format = string.format
      local matches = { 'Find: '..text }
      function search_file(file)
        local line_num = 1
        for line in io.lines(file) do
          local optimized_line = line
          if not match_case then optimized_line = line:lower() end
          if whole_word then optimized_line = ' '..line..' ' end
          if string.find(optimized_line, text) then
            matches[#matches + 1] = format('%s:%s:%s', file, line_num, line)
          end
          line_num = line_num + 1
        end
      end
      function search_dir(directory)
        for file in lfs.dir(directory) do
          if not file:find('^%.') then
            local path = directory..'/'..file
            local type = lfs.attributes(path).mode
            if type == 'directory' then
              search_dir(path)
            elseif type == 'file' then
              search_file(path)
            end
          end
        end
      end
      search_dir(dir)
      if #matches == 1 then matches[2] = locale.FIND_NO_RESULTS end
      matches[#matches + 1] = ''
      previous_view = view
      textadept._print('shows_files_found', table.concat(matches, '\n'))
    end
    return
  end

  if result == -1 and not nowrap and not wrapped then -- wrap the search
    local anchor, pos = buffer.anchor, buffer.current_pos
    if next or flags >= 8 then
      buffer:goto_pos(0)
    else
      buffer:goto_pos(buffer.length)
    end
    textadept.statusbar_text = locale.FIND_SEARCH_WRAPPED
    result = find.find(text, next, flags, true, true)
    if result == -1 then
      textadept.statusbar_text = locale.FIND_NO_RESULTS
      buffer:line_scroll(0, first_visible_line)
      buffer:goto_pos(anchor)
    end
    return result
  elseif result ~= -1 and not wrapped then
    textadept.statusbar_text = ''
  end

  return result
end

---
-- Replaces found text.
-- This function is used by the find dialog. It is not recommended to call it
-- via scripts.
-- textadept.find.find is called first, to select any found text. The selected
-- text is then replaced by the specified replacement text.
-- This function ignores 'Find in Files'.
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (%n where 1 <= n <= 9) for Lua pattern searches and %()
--   sequences for embedding Lua code for any search.
-- @see find.find
function find.replace(rtext)
  if #buffer:get_sel_text() == 0 then return end
  if find.in_files then find.in_files = false end
  local buffer = buffer
  buffer:target_from_selection()
  rtext = rtext:gsub('%%%%', '\\037') -- escape '%%'
  if find.captures then
    for i, v in ipairs(find.captures) do
      v = v:gsub('%%', '%%%%') -- escape '%' for gsub
      rtext = rtext:gsub('%%'..i, v)
    end
  end
  local ret, rtext = pcall(rtext.gsub, rtext, '%%(%b())',
    function(code)
      local locale = textadept.locale
      local ret, val = pcall(loadstring('return '..code))
      if not ret then
        cocoa_dialog('msgbox', {
          title = locale.FIND_ERROR_DIALOG_TITLE,
          text = locale.FIND_ERROR_DIALOG_TEXT,
          ['informative-text'] = val:gsub('"', '\\"')
        })
        error()
      end
      return val
    end)
  if ret then
    rtext = rtext:gsub('\\037', '%%') -- unescape '%'
    buffer:replace_target(rtext:gsub('\\[abfnrtv\\]', escapes))
    buffer:goto_pos(buffer.target_end) -- 'find' text after this replacement
  else
    -- Since find is called after replace returns, have it 'find' the current
    -- text again, rather than the next occurance so the user can fix the error.
    buffer:goto_pos(buffer.current_pos)
  end
end

---
-- Replaces all found text.
-- This function is used by the find dialog. It is not recommended to call it
-- via scripts.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores 'Find in Files'.
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @param flags The number mask identical to the one in 'find'.
-- @see find.find
function find.replace_all(ftext, rtext, flags)
  local buffer = buffer
  if find.in_files then find.in_files = false end
  buffer:begin_undo_action()
  local count = 0
  if #buffer:get_sel_text() == 0 then
    buffer:goto_pos(0)
    while(find.find(ftext, true, flags, true) ~= -1) do
      find.replace(rtext)
      count = count + 1
    end
  else
    local anchor, current_pos = buffer.anchor, buffer.current_pos
    local s, e = anchor, current_pos
    if s > e then s, e = e, s end
    buffer:insert_text(e, '\n')
    local end_marker =
      buffer:marker_add(buffer:line_from_position(e + 1), MARK_REPLACEALL_END)
    buffer:goto_pos(s)
    local pos = find.find(ftext, true, flags, true)
    while pos ~= -1 and
          pos < buffer:position_from_line(
            buffer:marker_line_from_handle(end_marker)) do
      find.replace(rtext)
      count = count + 1
      pos = find.find(ftext, true, flags, true)
    end
    e = buffer:position_from_line(buffer:marker_line_from_handle(end_marker))
    buffer:goto_pos(e)
    buffer:delete_back() -- delete '\n' added
    if s == current_pos then anchor = e - 1 else current_pos = e - 1 end
    buffer:set_sel(anchor, current_pos)
    buffer:marker_delete_handle(end_marker)
  end
  textadept.statusbar_text =
    string.format(textadept.locale.FIND_REPLACEMENTS_MADE, tostring(count))
  buffer:end_undo_action()
end

---
-- When the user double-clicks a found file, go to the line in the file the text
-- was found at.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
function goto_file(pos, line_num)
  if buffer.shows_files_found then
    line = buffer:get_line(line_num)
    local file, line_num = line:match('^(.+):(%d+):.+$')
    if file and line_num then
      if previous_view then previous_view:focus() end
      textadept.io.open(file)
      buffer:ensure_visible_enforce_policy(line_num - 1)
      buffer:goto_line(line_num - 1)
    end
  end
end
textadept.events.add_handler('double_click', goto_file)

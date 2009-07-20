-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale
local find = textadept.find

local lfs = require 'lfs'

local MARK_FIND = 0
local MARK_FIND_COLOR = 0x4D9999
local previous_view

-- Text escape sequences with their associated characters.
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}

-- Finds and selects text in the current buffer.
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
local function find_(text, next, flags, nowrap, wrapped)
  if #text == 0 then return end
  local buffer = buffer
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
    text = text:gsub('\\[abfnrtv\\]', escapes)
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
    local utf8_dir =
      textadept.dialog('fileselect',
                       '--title', locale.FIND_IN_FILES_TITLE,
                       '--select-only-directories',
                       '--with-directory',
                         (buffer.filename or ''):match('^.+[/\\]') or '',
                       '--no-newline')
    if #utf8_dir > 0 then
      if not find.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
      if not find.match_case then text = text:lower() end
      if find.whole_word then text = '[^%W_]'..text..'[^%W_]' end
      local match_case = find.match_case
      local whole_word = find.whole_word
      local iconv = textadept.iconv
      local format = string.format
      local matches = { 'Find: '..text }
      function search_file(file)
        local line_num = 1
        for line in io.lines(file) do
          local optimized_line = line
          if not match_case then optimized_line = line:lower() end
          if whole_word then optimized_line = ' '..line..' ' end
          if string.find(optimized_line, text) then
            file = iconv(file, 'UTF-8', _CHARSET)
            matches[#matches + 1] = format('%s:%s:%s', file, line_num, line)
          end
          line_num = line_num + 1
        end
      end
      function search_dir(directory)
        for file in lfs.dir(directory) do
          if not file:find('^%.%.?$') then -- ignore . and ..
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
      local dir = iconv(utf8_dir, _CHARSET, 'UTF-8')
      search_dir(dir)
      if #matches == 1 then matches[2] = locale.FIND_NO_RESULTS end
      matches[#matches + 1] = ''
      if buffer._type ~= locale.FIND_FILES_FOUND_BUFFER then
        previous_view = view
      end
      textadept._print(locale.FIND_FILES_FOUND_BUFFER,
                       table.concat(matches, '\n'))
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
    result = find_(text, next, flags, true, true)
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
textadept.events.add_handler('find', find_)

-- Finds and selects text incrementally in the current buffer from a start
-- point.
-- Flags other than SCFIND_MATCHCASE are ignored.
-- @param text The text to find.
local function find_incremental(text)
  local c = textadept.constants
  local flags = find.match_case and c.SCFIND_MATCHCASE or 0
  --if find.lua then flags = flags + 8 end
  buffer:goto_pos(find.incremental_start or 0)
  find_(text, true, flags)
end

-- LuaDoc is in core/.find.lua.
function find.find_incremental()
  find.incremental = true
  find.incremental_start = buffer.current_pos
  textadept.command_entry.entry_text = ''
  textadept.command_entry.focus()
end

textadept.events.add_handler('command_entry_keypress',
  function(code)
    if find.incremental then
      if code == 0xff1b then -- escape
        find.incremental = nil
      elseif code < 256 or code == 0xff08 then -- character or backspace
        local text = textadept.command_entry.entry_text
        if code == 0xff08 then
          find_incremental(text:sub(1, -2))
        else
          find_incremental(text..string.char(code))
        end
      end
    end
  end, 1) -- place before command_entry.lua's handler (if necessary)

textadept.events.add_handler('command_entry_command',
  function(text) -- 'find next' for incremental search
    if find.incremental then
      find.incremental_start = buffer.current_pos + 1
      find_incremental(text)
      return true
    end
  end, 1) -- place before command_entry.lua's handler (if necessary)

-- Replaces found text.
-- 'find_' is called first, to select any found text. The selected text is then
-- replaced by the specified replacement text.
-- This function ignores 'Find in Files'.
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (%n where 1 <= n <= 9) for Lua pattern searches and %()
--   sequences for embedding Lua code for any search.
-- @see find
local function replace(rtext)
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
      local ret, val = pcall(loadstring('return '..code))
      if not ret then
        textadept.dialog('ok-msgbox',
                         '--title', locale.FIND_ERROR_DIALOG_TITLE,
                         '--text', locale.FIND_ERROR_DIALOG_TEXT,
                         '--informative-text', val:gsub('"', '\\"'),
                         '--no-cancel')
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
textadept.events.add_handler('replace', replace)

-- Replaces all found text.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores 'Find in Files'.
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @param flags The number mask identical to the one in 'find'.
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
    local anchor, current_pos = buffer.anchor, buffer.current_pos
    local s, e = anchor, current_pos
    if s > e then s, e = e, s end
    buffer:insert_text(e, '\n')
    local end_marker =
      buffer:marker_add(buffer:line_from_position(e + 1), MARK_FIND)
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
  textadept.statusbar_text =
    string.format(locale.FIND_REPLACEMENTS_MADE, tostring(count))
  buffer:end_undo_action()
end
textadept.events.add_handler('replace_all', replace_all)

-- When the user double-clicks a found file, go to the line in the file the text
-- was found at.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
local function goto_file(pos, line_num)
  if buffer._type == locale.FIND_FILES_FOUND_BUFFER then
    line = buffer:get_line(line_num)
    local file, file_line_num = line:match('^(.+):(%d+):.+$')
    if file and file_line_num then
      buffer:marker_delete_all(MARK_FIND)
      buffer:marker_set_back(MARK_FIND, MARK_FIND_COLOR)
      buffer:marker_add(line_num, MARK_FIND)
      buffer:goto_pos(buffer.current_pos)
      if #textadept.views == 1 then
        _, previous_view = view:split(false) -- horizontal
      else
        local clicked_view = view
        if previous_view then previous_view:focus() end
        if buffer._type == locale.FIND_FILES_FOUND_BUFFER then
          -- there are at least two find in files views; find one of those views
          -- that the file was not selected from and focus it
          for _, v in ipairs(textadept.views) do
            if v ~= clicked_view then
              previous_view = v
              v:focus()
              break
            end
          end
        end
      end
      textadept.io.open(file)
      buffer:ensure_visible_enforce_policy(file_line_num - 1)
      buffer:goto_line(file_line_num - 1)
    end
  end
end
textadept.events.add_handler('double_click', goto_file)

-- LuaDoc is in core/.find.lua.
function find.goto_file_in_list(next)
  local orig_view = view
  for _, buffer in ipairs(textadept.buffers) do
    if buffer._type == locale.FIND_FILES_FOUND_BUFFER then
      for _, view in ipairs(textadept.views) do
        if view.doc_pointer == buffer.doc_pointer then
          view:focus()
          local orig_line = buffer:line_from_position(buffer.current_pos)
          local line = orig_line
          while true do
            line = line + (next and 1 or -1)
            if line > buffer.line_count - 1 then line = 0 end
            if line < 0 then line = buffer.line_count - 1 end
            if line == orig_line then -- prevent infinite loops
              orig_view:focus()
              return
            end
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

if buffer then buffer:marker_set_back(MARK_FIND, MARK_FIND_COLOR) end
textadept.events.add_handler('view_new',
  function() buffer:marker_set_back(MARK_FIND, MARK_FIND_COLOR) end)

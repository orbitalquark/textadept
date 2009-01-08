-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local find = textadept.find

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
-- @param flags Search flags. This is a number mask of 3 flags: match case (2),
--   whole word (4), and Lua pattern (8) joined with binary OR. If nil, this is
--   determined based on the checkboxes in the find box.
-- @param nowrap Flag indicating whether or not the search won't wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
function find.find(text, next, flags, nowrap, wrapped)
  local buffer, textadept = buffer, textadept
  local increment, result
  text = text:gsub('\\[abfnrtv\\]', escapes)
  find.captures = nil
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
  end
  if flags < 8 then
    buffer:goto_pos(buffer[next and 'current_pos' or 'anchor'] + increment)
    buffer:search_anchor()
    if next then
      result = buffer:search_next(flags, text)
    else
      result = buffer:search_prev(flags, text)
    end
    if result then buffer:scroll_caret() end
  else -- lua pattern search (forward search only)
    local buffer_text = buffer:get_text(buffer.length)
    local results = { buffer_text:find(text, buffer.anchor + increment) }
    if #results > 0 then
      result = results[1]
      find.captures = { unpack(results, 3) }
      buffer:set_sel(results[2], result - 1)
    else
      result = -1
    end
  end
  if result == -1 and not nowrap and not wrapped then -- wrap the search
    local anchor, pos = buffer.anchor, buffer.current_pos
    if next or flags >= 8 then
      buffer:goto_pos(0)
    else
      buffer:goto_pos(buffer.length)
    end
    textadept.statusbar_text = textadept.locale.FIND_SEARCH_WRAPPED
    result = find.find(text, next, flags, true, true)
    if not result then
      textadept.statusbar_text = textadept.locale.FIND_NO_RESULTS
      buffer:goto_pos(anchor)
    end
    return result
  elseif result ~= -1 and not wrapped then
    textadept.statusbar_text = ''
  end
  return result ~= -1
end

---
-- Replaces found text.
-- This function is used by the find dialog. It is not recommended to call it
-- via scripts.
-- textadept.find.find is called first, to select any found text. The selected
-- text is then replaced by the specified replacement text.
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (%n where 1 <= n <= 9) for Lua pattern searches and %()
--   sequences for embedding Lua code for any search.
function find.replace(rtext)
  if #buffer:get_sel_text() == 0 then return end
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
    buffer:goto_pos(buffer.target_end + 1) -- 'find' text after this replacement
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
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @param flags The number mask identical to the one in 'find'.
-- @see find.find
function find.replace_all(ftext, rtext, flags)
  local textadept = textadept
  buffer:goto_pos(0)
  local count = 0
  while(find.find(ftext, true, flags, true)) do
    find.replace(rtext)
    count = count + 1
  end
  textadept.statusbar_text =
    string.format(textadept.locale.FIND_REPLACEMENTS_MADE, tostring(count))
end

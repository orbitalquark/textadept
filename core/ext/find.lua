-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
-- @param flags Search flags. This is a number mask of 3 flags: match case (2),
--   whole word (4), and Lua pattern (8) joined with binary AND.
-- @param next Boolean indicating search direction (next is forward).
-- @param wrapped Utility boolean indicating whether the search has wrapped or
--   not for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
function find.find(text, flags, next, wrapped)
  local buffer = buffer
  local result
  text = text:gsub('\\[abfnrtv\\]', escapes)
  find.captures = nil
  if flags < 8 then
    if next then
      buffer:goto_pos(buffer.current_pos + 1)
      buffer:search_anchor()
      result = buffer:search_next(flags, text)
    else
      buffer:goto_pos(buffer.anchor - 1)
      buffer:search_anchor()
      result = buffer:search_prev(flags, text)
    end
    if result then buffer:scroll_caret() end
  else -- lua pattern search
    local buffer_text = buffer:get_text(buffer.length)
    local results = { buffer_text:find(text, buffer.anchor + 1) }
    if #results > 0 then
      result = results[1]
      find.captures = { unpack(results, 3) }
      buffer:set_sel(results[2], result - 1)
    else
      result = -1
    end
  end
  if result == -1 and not wrapped then -- wrap the search
    local anchor, pos = buffer.anchor, buffer.current_pos
    if next or flags >= 8 then
      buffer:goto_pos(0)
    else
      buffer:goto_pos(buffer.length)
    end
    textadept.statusbar_text = 'Search wrapped'
    result = find.find(text, flags, next, true)
    if not result then
      textadept.statusbar_text = 'No results found'
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
-- @param rtext The text to replace found text with. It can contain Lua escape
--   sequences to use text captured by a Lua pattern. (%n where 1 <= n <= 9.)
function find.replace(rtext)
  if #buffer:get_sel_text() == 0 then return end
  local buffer = buffer
  buffer:target_from_selection()
  if find.captures then
    for i, v in ipairs(find.captures) do
      rtext = rtext:gsub('[^%%]?[^%%]?%%'..i, v) -- not entirely correct
    end
  end
  buffer:replace_target( rtext:gsub('\\[abfnrtv\\]', escapes) )
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
  local count = 0
  while( find.find(ftext, flags, true) ) do
    find.replace(rtext)
    count = count + 1
  end
  textadept.statusbar_text = tostring(count)..' replacement(s) made'
end

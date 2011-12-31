-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Filter-Through for the textadept module.
module('_m.textadept.filter_through')]]

local cat = not WIN32 and 'cat' or 'type'
local tmpfile = _USERHOME..'/.ft'
local filter_through_active = false

---
-- Prompts for a Linux, Mac OSX, or Windows shell command to filter text
-- through.
-- The standard input (stdin) for shell commands is determined as follows: (1)
-- If text is selected and spans multiple lines, all text on the lines
-- containing the selection is used. However, if the end of the selection is at
-- the beginning of a line, only the EOL (end of line) characters from the
-- previous line are included as input. The rest of the line is excluded. (2) If
-- text is selected and spans a single line, only the selected text is used. (3)
-- If no text is selected, the entire buffer is used.
-- The input text is replaced with the standard output (stdout) of the command.
-- @name filter_through
function M.filter_through()
  filter_through_active = true
  gui.command_entry.focus()
end

local events = events

events.connect(events.COMMAND_ENTRY_KEYPRESS, function(code)
  if filter_through_active and keys.KEYSYMS[code] == 'esc' then
    filter_through_active = false
  end
end, 1) -- place before command_entry.lua's handler (if necessary)

-- Filter through.
events.connect(events.COMMAND_ENTRY_COMMAND, function(text)
  if filter_through_active then
    local buffer = buffer
    local s, e = buffer.selection_start, buffer.selection_end
    local input
    if s ~= e then -- use selected lines as input
      local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
      if i < j then
        s = buffer:position_from_line(i)
        if buffer.column[e] > 0 then e = buffer:position_from_line(j + 1) end
      end
      input = buffer:text_range(s, e)
    else -- use whole buffer as input
      input = buffer:get_text()
    end
    local f = io.open(tmpfile, 'wb')
    f:write(input)
    f:close()
    local cmd = cat..' "'..tmpfile..'" | '..text
    if WIN32 then cmd = cmd:gsub('/', '\\') end
    local p = io.popen(cmd)
    if s ~= e then
      buffer.target_start, buffer.target_end = s, e
      buffer:replace_target(p:read('*all'))
      buffer:set_sel(buffer.target_start, buffer.target_end)
    else
      buffer:set_text(p:read('*all'))
      buffer:goto_pos(s)
    end
    p:close()
    os.remove(tmpfile)
    filter_through_active = false
    return true
  end
end, 1) -- place before command_entry.lua's handler (if necessary)

return M

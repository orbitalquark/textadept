-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize

---
-- Filter-Through for the textadept module.
module('_m.textadept.filter_through', package.seeall)

local cat = not WIN32 and 'cat' or 'type'
local tmpfile = _USERHOME..'/.ft'
local filter_through_active = false

---
-- Prompts for a Linux, Mac OSX, or Windows shell command to filter text
-- through. If text is selected, all text on the lines containing the selection
-- is used as the standard input (stdin) to the command. Otherwise the entire
-- buffer is used. Either the selected text or buffer is replaced with the
-- standard output (stdout) of the command.
function filter_through()
  filter_through_active = true
  gui.command_entry.entry_text = ''
  gui.command_entry.focus()
end

events.connect('command_entry_keypress',
  function(code)
    if filter_through_active and code == 0xff1b then -- escape
      filter_through_active = false
    end
  end, 1) -- place before command_entry.lua's handler (if necessary)

events.connect('command_entry_command',
  function(text) -- filter through
    if filter_through_active then
      local buffer = buffer
      local s, e = buffer.selection_start, buffer.selection_end
      local input
      if s ~= e then -- use selected lines as input
        s = buffer:position_from_line(buffer:line_from_position(s))
        if buffer.column[e] > 0 then
          e = buffer:position_from_line(buffer:line_from_position(e) + 1)
        end
        input = buffer:get_sel_text()
      else -- use whole buffer as input
        input = buffer:get_text()
      end
      local f = io.open(tmpfile, 'wb')
      f:write(input)
      f:close()
      local cmd = table.concat({ cat, '"'..tmpfile..'"', '|', text }, ' ')
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


-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local pm = textadept.pm

local current_browser = nil

-- For restoring browser cursors
local last_browser_text = nil
local browser_cursors = {}

-- LuaDoc is in core/.browser.lua.
function pm.get_contents_for(full_path, expanding)
  for _, browser in pairs(pm.browsers) do
    if browser.matches(full_path[1]) then
      current_browser = browser
      if last_browser_text and last_browser_text ~= pm.entry_text then
        -- Switching browsers, save the current one's cursor.
        -- Don't reset last_browser_text here though, we still need to detect
        -- the switch when the 'pm_view_filled' event is called so as to restore
        -- the cursor to the new browser.
        browser_cursors[last_browser_text] = pm.cursor
      end
      return browser.get_contents_for(full_path, expanding)
    end
  end
end

-- LuaDoc is in core/.browser.lua.
function pm.perform_action(selected_item)
  current_browser.perform_action(selected_item)
end

-- LuaDoc is in core/.browser.lua.
function pm.get_context_menu(selected_item)
  return current_browser.get_context_menu(selected_item)
end

-- LuaDoc is in core/.browser.lua.
function pm.perform_menu_action(menu_id, selected_item)
  current_browser.perform_menu_action(menu_id, selected_item)
end

-- LuaDoc is in core/.browser.lua.
function pm.toggle_visible()
  if pm.width > 0 then
    pm.prev_width = pm.width
    pm.width = 0
  else
    pm.width = pm.prev_width or 150
  end
end

textadept.events.add_handler('pm_view_filled',
  function() -- tries to restore the cursor for a previous browser
    if last_browser_text ~= pm.entry_text then
      last_browser_text = pm.entry_text
      local previous_cursor = browser_cursors[pm.entry_text]
      if previous_cursor then pm.cursor = previous_cursor end
    end
  end)

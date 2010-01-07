-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local pm = textadept.pm

local current_browser = nil

-- For restoring browser cursors
local last_browser_text = nil
local browser_cursors = {}

textadept.events.add_handler('pm_contents_request',
  function(full_path, expanding)
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
        pm.fill(browser.get_contents_for(full_path, expanding), expanding)
        textadept.events.handle('pm_view_filled')
      end
    end
  end)

textadept.events.add_handler('pm_item_selected',
  function(selected_item) current_browser.perform_action(selected_item) end)

textadept.events.add_handler('pm_context_menu_request',
  function(selected_item, event)
    local menu = current_browser.get_context_menu(selected_item)
    if menu then pm.show_context_menu(menu, event) end
  end)

textadept.events.add_handler('pm_menu_clicked',
  function(menu_id, selected_item)
    current_browser.perform_menu_action(menu_id, selected_item)
  end)

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
  function() -- try to restore previous browser cursor
    if last_browser_text ~= pm.entry_text then
      last_browser_text = pm.entry_text
      local previous_cursor = browser_cursors[pm.entry_text]
      if previous_cursor then pm.cursor = previous_cursor end
    end
  end)

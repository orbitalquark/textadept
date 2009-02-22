-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Macro browser for the Textadept project manager.
-- It is enabled with the prefix 'macros' in the project manager entry field.
module('textadept.pm.browsers.macro', package.seeall)

if not RESETTING then textadept.pm.add_browser('macros') end

function matches(entry_text)
  return entry_text:sub(1, 7) == 'macros'
end

function get_contents_for()
  local m_macros = _m.textadept.macros
  local contents = {}
  for name in pairs(m_macros.list) do contents[name] = { text = name } end
  return contents
end

function perform_action(selected_item)
  _m.textadept.macros.play(selected_item[2])
  view:focus()
end

local ID = { DELETE = 1 }

function get_context_menu(selected_item)
  return { { locale.PM_BROWSER_MACRO_DELETE, ID.DELETE } }
end

function perform_menu_action(menu_id, selected_item)
  local m_macros = _m.textadept.macros
  if menu_id == ID.DELETE then
    m_macros.delete(selected_item[2])
  end
  textadept.pm.activate()
end

local function update_view()
  if matches(textadept.pm.entry_text) then textadept.pm.activate() end
end
textadept.events.add_handler('macro_saved', update_view)
textadept.events.add_handler('macro_deleted', update_view)

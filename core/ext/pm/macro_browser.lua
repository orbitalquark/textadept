-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Macro browser for the Textadept project manager.
-- It is enabled with the prefix 'macros' in the project manager entry field.
module('textadept.pm.browsers.macro', package.seeall)

local textadept = textadept

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
  _m.textadept.macros.play( selected_item[2] )
  view:focus()
end

function get_context_menu(selected_item)
  return { '_Delete' }
end

function perform_menu_action(menu_item, selected_item)
  local m_macros = _m.textadept.macros
  if menu_item == 'Delete' then
    m_macros.delete( selected_item[2] )
  end
  textadept.pm.activate()
end

local add_function_to_handler = textadept.handlers.add_function_to_handler
local function update_view()
  if matches(textadept.pm.entry_text) then textadept.pm.activate() end
end
add_function_to_handler('macro_saved', update_view)
add_function_to_handler('macro_deleted', update_view)

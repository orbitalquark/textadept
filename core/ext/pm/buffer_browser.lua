-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Buffer browser for the Textadept project manager.
-- It is enabled with the prefix 'buffers' in the project manager entry field.
module('textadept.pm.browsers.buffer', package.seeall)

function matches(entry_text)
  return entry_text:sub(1, 7) == 'buffers'
end

function get_contents_for()
  local contents = {}
  for index, buffer in ipairs(textadept.buffers) do
    index = string.format("%02i", index)
    contents[index] = {
      pixbuf = buffer.dirty and 'gtk-edit' or 'gtk-file',
      text = (buffer.filename or textadept.locale.UNTITLED):match('[^/\\]+$')
    }
  end
  return contents
end

function perform_action(selected_item)
  local index = selected_item[2]
  local buffer = textadept.buffers[ tonumber(index) ]
  if buffer then view:goto_buffer(index) view:focus() end
end

local ID = { NEW = 1, OPEN = 2, SAVE = 3, SAVEAS = 4, CLOSE = 5 }

function get_context_menu(selected_item)
  local locale = textadept.locale
  return {
    { locale.PM_BROWSER_BUFFER_NEW, ID.NEW },
    { locale.PM_BROWSER_BUFFER_OPEN, ID.OPEN },
    { locale.PM_BROWSER_BUFFER_SAVE, ID.SAVE },
    { locale.PM_BROWSER_BUFFER_SAVEAS, ID.SAVEAS },
    { 'separator', 0 },
    { locale.PM_BROWSER_BUFFER_CLOSE, ID.CLOSE },
  }
end

function perform_menu_action(menu_item, menu_id, selected_item)
  if menu_id == ID.NEW then
    textadept.new_buffer()
  elseif menu_id == ID.OPEN then
    textadept.io.open()
  elseif menu_id == ID.SAVE then
    view:goto_buffer( tonumber( selected_item[2] ) )
    buffer:save()
  elseif menu_id == ID.SAVEAS then
    view:goto_buffer( tonumber( selected_item[2] ) )
    buffer:save_as()
  elseif menu_id == ID.CLOSE then
    view:goto_buffer( tonumber( selected_item[2] ) )
    buffer:close()
  end
  textadept.pm.activate()
end

local add_handler = textadept.events.add_handler
local function update_view()
  if matches(textadept.pm.entry_text) then textadept.pm.activate() end
end
add_handler('file_opened', update_view)
add_handler('buffer_new', update_view)
add_handler('buffer_deleted', update_view)
add_handler('save_point_reached', update_view)
add_handler('save_point_left', update_view)

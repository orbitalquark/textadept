-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
      text = (buffer.filename or 'Untitled'):match('[^/]+$')
    }
  end
  return contents
end

function perform_action(selected_item)
  local index = selected_item[2]
  local buffer = textadept.buffers[ tonumber(index) ]
  if buffer then view:goto_buffer(index) view:focus() end
end

function get_context_menu(selected_item)
  return { '_New', '_Open', '_Save', 'Save _As...', 'separator', '_Close' }
end

function perform_menu_action(menu_item, selected_item)
  if menu_item == 'New' then
    textadept.new_buffer()
  elseif menu_item == 'Open' then
    textadept.io.open()
  elseif menu_item == 'Save' then
    textadept.buffers[ tonumber( selected_item[2] ) ]:save()
  elseif menu_item == 'Save As...' then
    textadept.buffers[ tonumber( selected_item[2] ) ]:save_as()
  elseif menu_item == 'Close' then
    textadept.buffers[ tonumber( selected_item[2] ) ]:close()
  end
  textadept.pm.activate()
end

local add_function_to_handler = textadept.handlers.add_function_to_handler
local function update_view()
  if matches(textadept.pm.entry_text) then textadept.pm.activate() end
end
add_function_to_handler('file_opened', update_view)
add_function_to_handler('buffer_new', update_view)
add_function_to_handler('buffer_deleted', update_view)
add_function_to_handler('save_point_reached', update_view)
add_function_to_handler('save_point_left', update_view)

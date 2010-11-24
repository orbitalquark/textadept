-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local gui = _G.gui

-- LuaDoc is in core/.gui.luadoc.
function gui.check_focused_buffer(buffer)
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error(L('Buffer argument expected.'), 2)
  elseif gui.focused_doc_pointer ~= buffer.doc_pointer then
    error(L('The indexed buffer is not the focused one.'), 2)
  end
end

-- LuaDoc is in core/.gui.luadoc.
function gui._print(buffer_type, ...)
  local function safe_print(...)
    local message_buffer, message_buffer_index
    local message_view, message_view_index
    for i, buffer in ipairs(_BUFFERS) do
      if buffer._type == buffer_type then
        message_buffer, message_buffer_index = buffer, i
        for j, view in ipairs(_VIEWS) do
          if view.doc_pointer == message_buffer.doc_pointer then
            message_view, message_view_index = view, j
            break
          end
        end
        break
      end
    end
    if not message_view then
      local _, message_view = view:split(false) -- horizontal split
      if not message_buffer then
        message_buffer = new_buffer()
        message_buffer._type = buffer_type
        events.emit('file_opened')
      else
        message_view:goto_buffer(message_buffer_index, true)
      end
    else
      gui.goto_view(message_view_index, true)
    end
    message_buffer:append_text(table.concat({...}, '\t'))
    message_buffer:append_text('\n')
    message_buffer:set_save_point()
  end
  pcall(safe_print, ...) -- prevent endless loops on error
end

-- LuaDoc is in core/.gui.luadoc.
function gui.print(...) gui._print(L('[Message Buffer]'), ...) end

-- LuaDoc is in core/.gui.luadoc.
function gui.switch_buffer()
  local items = {}
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type or L('Untitled')
    local dirty = buffer.dirty and '*' or ''
    items[#items + 1] = dirty..filename:match('[^/\\]+$')
    items[#items + 1] = filename
  end
  local response = gui.dialog('filteredlist',
                              '--title', L('Switch Buffers'),
                              '--button1', 'gtk-ok',
                              '--button2', 'gtk-cancel',
                              '--no-newline',
                              '--columns', 'Name', 'File',
                              '--items', items)
  local ok, i = response:match('(%-?%d+)\n(%d+)$')
  if ok == '1' then view:goto_buffer(tonumber(i) + 1, true) end
end

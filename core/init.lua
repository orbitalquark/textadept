-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

package.path = _HOME..'/core/?.lua;'..package.path
package.cpath = _HOME..'/core/?.so;'..package.cpath

require 'iface'
require 'events'
require 'file_io'
require 'lua_dialog'

---
-- Checks if the buffer being indexed is the currently focused buffer.
-- This is necessary because any buffer actions are performed in the focused
-- views' buffer, which may not be the buffer being indexed. Throws an error
-- if the check fails.
-- @param buffer The buffer in question.
function textadept.check_focused_buffer(buffer)
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error('Buffer argument expected.', 2)
  elseif textadept.focused_doc_pointer ~= buffer.doc_pointer then
    error('The indexed buffer is not the focused one.', 2)
  end
end

---
-- Displays a CocoaDialog of a specified type with given arguments returning
-- the result.
-- @param kind The CocoaDialog type.
-- @param ... A table of key, value arguments. Each key is a --key switch with
--   a "value" value. If value is nil, it is omitted and just the switch is
--   used.
-- @return string CocoaDialog result.
function cocoa_dialog(kind, opts)
  local args = { kind }
  for k, v in pairs(opts) do
    args[#args + 1] = '--'..k
    if type(v) == 'string' then args[#args + 1] = v end
  end
  return lua_dialog.run(args)
end

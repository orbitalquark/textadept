-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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

package.path = package.path..';'.._HOME..'/core/?.lua'

require 'iface'
require 'events'
require 'file_io'

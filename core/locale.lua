-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Table of all messages used by Textadept for localization.
module('_L')]]

local none = 'No Localization: '

---
-- Returns whether or not a localized message exists for the given message.
-- @param message The message to localize.
-- @return `true` if a localization exists, `false` otherwise.
function M._EXISTS(message) return M[message] ~= none..message end

local f = io.open(_USERHOME..'/locale.conf', 'rb')
if not f then f = io.open(_HOME..'/core/locale.conf', 'rb') end
if not f then error('"core/locale.conf" not found.') end
for line in f:lines() do
  if not line:find('^%s*%%') then
    local id, str = line:match('^(.-)%s*=%s*(.+)$')
    if id and str then M[id] = not NCURSES and str or str:gsub('_', '') end
  end
end
f:close()

return setmetatable(M, { __index = function(t, k) return none..k end })

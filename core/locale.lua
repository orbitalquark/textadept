-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

local f = io.open(_USERHOME..'/locale.conf', 'rb')
if not f then f = io.open(_HOME..'/core/locale.conf', 'rb') end
if not f then error('"core/locale.conf" not found.') end
for line in f:lines() do
  if not line:find('^%s*%%') then
    local id, str = line:match('^(.-)%s*=%s*(.+)$')
    if id and str then M[id] = str end
  end
end
f:close()

return setmetatable(M, { __index = function() return 'No Localization' end })

-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Table of all messages used by Textadept for localization.
module('_L')]]

-- Markdown:
-- # Settings
--
-- * `_NIL` [string]: String returned when no localization for a given message
--   exists.

M._NIL = 'No Localization'

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

---
-- This table contains no functions.
-- @class function
-- @name no_functions
local no_functions

return setmetatable(M, { __index = function() return M._NIL end })

-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- This module loads all messages used by Textadept for localization.
-- Localized strings are contained in 'core/locale.conf'. Please see this file
-- for more information.
module('locale', package.seeall)

local escapes = { ['\\n'] = '\n', ['\\r'] = '\r', ['\\t'] = '\t' }

local f = io.open(_HOME..'/core/locale.conf', 'rb')
if not f then error('"core/locale.conf" not found.') end
for line in f:lines() do
  if not line:find('^%s*%%') then
    local id, str = line:match('^%s*(%S+)%s+"(.+)"$')
    if id and str then locale[id] = str:gsub('\\[nrt]', escapes) end
  end
end
f:close()

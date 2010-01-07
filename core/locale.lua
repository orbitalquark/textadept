-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Contains all messages used by Textadept for localization.
module('locale', package.seeall)

-- Markdown:
-- ## Overview
--
-- All Textadept messages displayed are located in `core/locale.conf`. To change
-- the language, simply replace that file with a similar file containing the
-- translated messages. See `core/locale.conf` for more information.
--
-- Feel free to translate Textadept and send your modified `locale.conf` files
-- to me. I will put them up on the site where they can be accessed.
--
-- ## Fields
--
-- Each message ID in `core/locale.conf` is accessible as a field in this
-- module.

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

---
-- This module contains no functions.
function no_functions() end
no_functions = nil -- undefine

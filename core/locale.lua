-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Contains all messages used by Textadept for localization.
module('locale', package.seeall)

-- Markdown:
-- ## Overview
--
-- All Textadept messages displayed are located in `core/locale.conf`. To change
-- the language, simply put a similar file containing the translated messages in
-- your `~/.textadept/` folder. See `core/locale.conf` for more information.
--
-- Feel free to translate Textadept and send your modified `locale.conf` files
-- to me. I will put them up on the site where they can be accessed.
--
-- ## Fields
--
-- Each message ID in `core/locale.conf` is accessible as a field in this
-- module.

-- Contains all localizations for the current locale.
-- @class table
-- @name localizations
local localizations = {}

local f = io.open(_USERHOME..'/locale.conf', 'rb')
if not f then f = io.open(_HOME..'/core/locale.conf', 'rb') end
if not f then error('"core/locale.conf" not found.') end
for line in f:lines() do
  if not line:find('^%s*%%') then
    local id, str = line:match('^(.-)%s*=%s*(.+)$')
    if id and str then localizations[id] = str end
  end
end
f:close()

---
-- Localizes the given string.
-- @param id String to localize.
function localize(id) return localizations[id] or 'No Localization' end

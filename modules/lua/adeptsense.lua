-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Adeptsense for the lua module.
-- User tags are loaded from _USERHOME/modules/lua/tags.
module('_m.lua.adeptsense', package.seeall)

sense = _m.textadept.adeptsense.new('lua')
sense.syntax.symbol_chars = '[%w_%.:]'
sense.api_files = { _HOME..'/modules/lua/api' }
sense:add_trigger('.')
sense:add_trigger(':', false, true)
function sense:get_class(symbol) return nil end -- no such thing

-- script/update_doc generates a fake set of ctags used for autocompletion.
sense.ctags_kinds = {
  f = 'functions',
  F = 'fields',
  m = 'modules',
  t = 'fields',
}
sense:load_ctags(_HOME..'/modules/lua/tags', true)

-- Load user tags
if lfs.attributes(_USERHOME..'/modules/lua/tags') then
  sense:load_ctags(_USERHOME..'/modules/lua/tags')
end

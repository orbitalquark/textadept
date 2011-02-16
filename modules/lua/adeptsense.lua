-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Adeptsense for the lua module.
-- User tags are loaded from _USERHOME/modules/lua/tags and user apis are loaded
-- from _USERHOME/modules/lua/api.
module('_m.lua.adeptsense', package.seeall)

sense = _m.textadept.adeptsense.new('lua')
sense.syntax.class_definition = 'module%s*%(?%s*[\'"]([%w_%.]+)'
sense.syntax.symbol_chars = '[%w_%.:]'
sense.api_files = { _HOME..'/modules/lua/api' }
sense:add_trigger('.')
sense:add_trigger(':', false, true)

---
-- Returns the current module's name (if any) for showing module completions in
-- addition to global completions. Otherwise returns nil so only global
-- completions are shown.
-- @param symbol Must be the empty string ('').
function sense:get_class(symbol)
  if symbol ~= '' then return nil end -- no such thing
  return self.super.get_class(self, symbol) -- try to get current module
end

-- script/update_doc generates a fake set of ctags used for autocompletion.
sense.ctags_kinds = {
  f = 'functions',
  F = 'fields',
  m = 'modules',
  t = 'fields',
}
sense:load_ctags(_HOME..'/modules/lua/tags', true)

-- Load user tags and apidoc.
if lfs.attributes(_USERHOME..'/modules/lua/tags') then
  sense:load_ctags(_USERHOME..'/modules/lua/tags')
end
if lfs.attributes(_USERHOME..'/modules/lua/api') then
  sense.api_files[#sense.api_files + 1] = _USERHOME..'/modules/lua/api'
end

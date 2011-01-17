-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Adeptsense for the cpp module.
-- User tags are loaded from _USERHOME/modules/cpp/tags.
module('_m.cpp.adeptsense', package.seeall)

sense = _m.textadept.adeptsense.new('cpp')
sense.ctags_kinds = {
  c = 'classes',
  d = 'functions',
  e = 'fields',
  f = 'functions',
  g = 'classes',
  m = 'fields',
  s = 'classes',
  t = 'classes'
}
sense.syntax.type_declarations = {
  '(%u[%w_%.]+)[%s%*]+%_', -- Foo bar, Foo *bar, Foo* bar, etc.
}
sense:add_trigger('.')
sense:add_trigger('->')

-- Load user tags
if lfs.attributes(_USERHOME..'/modules/cpp/tags') then
  sense:load_ctags(_USERHOME..'/modules/cpp/tags')
end

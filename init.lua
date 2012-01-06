-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

package.path = table.concat({
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua', _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua', _HOME..'/modules/?/init.lua',
  package.path
}, ';');

if not user_dofile('init.lua') then require 'textadept' end

if not RESETTING then args.process() end

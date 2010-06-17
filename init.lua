-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local paths = {
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua',
  _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua',
  _HOME..'/modules/?/init.lua',
  package.path
}
package.path = table.concat(paths, ';')

if not user_dofile('init.lua') then require 'textadept' end

if not RESETTING then args.process() end

-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

package.path = table.concat({
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua', _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua', _HOME..'/modules/?/init.lua',
  package.path
}, ';');
local so = not WIN32 and '/?.so;' or '/?.dll;'
package.cpath = _USERHOME..so.._USERHOME..'/modules'..so..package.cpath

local user_init, exists = _USERHOME..'/init.lua', lfs.attributes
local ok, err = pcall(dofile, user_init)
if ok or not exists(user_init) then require('textadept') else gui.print(err) end

if not RESETTING then args.process(arg) end

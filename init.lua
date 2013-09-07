-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

package.path = table.concat({
  _USERHOME..'/?.lua',
  _USERHOME..'/modules/?.lua', _USERHOME..'/modules/?/init.lua',
  _HOME..'/modules/?.lua', _HOME..'/modules/?/init.lua',
  package.path
}, ';');
local so = not WIN32 and '/?.so;' or '/?.dll;'
package.cpath = _USERHOME..so.._USERHOME..'/modules'..so..package.cpath

textadept = require('textadept')
local ok, err = pcall(dofile, _USERHOME..'/init.lua')
if not ok and lfs.attributes(_USERHOME..'/init.lua') then ui.print(err) end

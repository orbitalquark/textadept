-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

require 'ext/pm'
require 'ext/find'
require 'ext/mime_types'
require 'ext/keys'

local mpath = _HOME..'modules/?.lua;'.._HOME..'/modules/?/init.lua'
package.path  = package.path..';'..mpath

-- modules to load on startup
require 'textadept'
-- end modules

require 'ext/key_commands'

-- process command line arguments
local textadept = textadept
if #arg == 0 then
  textadept.io.load_session()
else
  local base_dir = arg[0]:match('^.+/') or ''
  for _, filename in ipairs(arg) do
    textadept.io.open(base_dir..filename)
  end
  textadept.pm.entry_text = 'buffers'
  textadept.pm.activate()
end

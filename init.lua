-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

require 'ext/pm'
require 'ext/find'
require 'ext/mime_types'

local mpath = _HOME..'modules/?.lua;'.._HOME..'/modules/?/init.lua'
package.path  = package.path..';'..mpath

require 'textadept'

local textadept = textadept
if #arg == 0 then
  textadept.io.load_session()
else
  local base_dir = arg[0]:match('^.+/')
  for _, filename in ipairs(arg) do
    textadept.io.open(base_dir..filename)
  end
  textadept.pm.entry_text = 'buffers'
  textadept.pm.activate()
end

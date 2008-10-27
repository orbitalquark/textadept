-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

require 'ext/pm'
require 'ext/find'
require 'ext/command_entry'
require 'ext/mime_types'
require 'ext/keys'

local mpath = _HOME..'/modules/?.lua;'.._HOME..'/modules/?/init.lua'
package.path  = mpath..';'..package.path

-- modules to load on startup
require 'textadept'
-- end modules

--require 'ext/menu'
--require 'ext/key_commands_std'
require 'ext/key_commands'

if not RESETTING then
  -- process command line arguments
  local textadept = textadept
  if #arg == 0 then
    textadept.io.load_session()
  else
    local base_dir = arg[0]:match('^.+/') or ''
    local filepath
    for _, filename in ipairs(arg) do
      if not MAC or not filename:match('^%-psn_0') then
        if not filename:match('^~?/') then
          textadept.io.open(base_dir..filename)
        else
          textadept.io.open(filename)
        end
      end
    end
    -- read only the Project Manager session settings
    if not textadept.io.load_session(nil, true) then
      textadept.pm.entry_text = 'buffers'
      textadept.pm.activate()
    end
  end
end

-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local mpath = _HOME..'/modules/?.lua;'.._HOME..'/modules/?/init.lua'
package.path  = mpath..';'..package.path

-- Core extension modules to load on startup.
require 'ext/keys' -- provides key command support
require 'ext/find' -- provides functionality for find/replace
require 'ext/command_entry' -- provides tab-completion for the command entry
require 'ext/mime_types' -- provides support for language detection based on
                         -- the file; loads its language-specific module if
                         -- it exists
require 'ext/pm' -- provides the dynamic browser (side pane) functionality
require 'ext/pm.buffer_browser'  -- buffer browser
require 'ext/pm.file_browser'    -- file browser
require 'ext/pm.project_browser' -- project browser
require 'ext/pm.modules_browser' -- modules browser
require 'ext/pm.macro_browser'   -- macro browser
if not WIN32 then
  require 'ext/pm.ctags_browser' -- ctags browser
  require 'ext/pm.find_browser'  -- find browser
end

-- Generic modules to load on startup.
require 'textadept'

-- Core extension modules that must be loaded last.
require 'ext/menu' -- provides the menu bar
--require 'ext/key_commands_std' -- key commands for Windows and Linux
--require 'ext/key_commands_mac' -- key commands for Mac OSX
require 'ext/key_commands' -- key commands for Mitchell (Nano-Emacs hybrid)

if not RESETTING then
  -- process command line arguments
  local textadept = textadept
  if MAC and arg[1] and arg[1]:match('^%-psn_0') then
    table.remove(arg, 1)
  end
  if #arg == 0 then
    textadept.io.load_session()
  else
    local base_dir = arg[0]:match('^.+/') or ''
    local filepath
    for _, filename in ipairs(arg) do
      if not filename:match('^~?/') then
        textadept.io.open(base_dir..filename)
      else
        textadept.io.open(filename)
      end
    end
    -- read only the Project Manager session settings
    if not textadept.io.load_session(nil, true) then
      textadept.pm.entry_text = 'buffers'
      textadept.pm.activate()
    end
  end
end

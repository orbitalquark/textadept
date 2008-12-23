-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Modules browser for the Textadept project manager.
-- It is enabled with the prefix 'modules' in the project manager entry field.
module('textadept.pm.browsers.modules', package.seeall)

local lfs = require 'lfs'
local os = require 'os'

local INIT = [[
-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- The $1 module.
-- It provides utilities for editing $2 code.
module('_m.$1', package.seeall)

if type(_G.snippets) == 'table' then
---
-- Container for $2-specific snippets.
-- @class table
-- @name snippets.$1
  _G.snippets.$1 = {}
end

if type(_G.keys) == 'table' then
---
-- Container for $2-specific key commands.
-- @class table
-- @name keys.$1
  _G.keys.$1 = {}
end

require '$1.commands'
require '$1.snippets'

function set_buffer_properties()

end
]]

local SNIPPETS = [[
-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Snippets for the $1 module.
module('_m.$1.snippets', package.seeall)

local snippets = _G.snippets

if type(snippets) == 'table' then
  snippets.$1 = {}
end
]]

local COMMANDS = [[
-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the $1 module.
module('_m.$1.commands', package.seeall)

-- $2-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  keys.$1 = {
    al = {
      m = { textadept.io.open, _HOME..'/modules/$1/init.lua' },
    },
  }
end
]]

function matches(entry_text)
  return entry_text:sub(1, 7) == 'modules'
end

local function modify_path(path)
  path[1] = _HOME..'/modules'
  return path
end

function get_contents_for(full_path)
  full_path = modify_path(full_path)
  local dir = {}
  local dirpath = table.concat(full_path, '/')
  for name in lfs.dir(dirpath) do
    if not name:match('^%.') then
      dir[name] = { text = name }
      if lfs.attributes(dirpath..'/'..name, 'mode') == 'directory' then
        dir[name].parent = true
        dir[name].pixbuf = 'gtk-directory'
      end
    end
  end
  return dir
end

function perform_action(selected_item)
  selected_item = modify_path(selected_item)
  local filepath = table.concat(selected_item, '/')
  textadept.io.open(filepath)
  view:focus()
end

function get_context_menu(selected_item)
  return {
    '_New Module', '_Delete Module', 'separator',
    'Configure _MIME Types', 'Configure _Key Commands', 'separator',
    '_Reload Modules'
  }
end

function perform_menu_action(menu_item, selected_item)
  if menu_item == 'New Module' then
    local status, module_name = cocoa_dialog( 'standard-inputbox', {
      ['title'] = 'Module Name',
      ['informative-text'] = 'Module name:'
    } ):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    local status, lang_name = cocoa_dialog( 'standard-inputbox', {
      ['title'] = 'Language Name',
      ['informative-text'] = 'Language name:'
    } ):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    local module_dir = _HOME..'/modules/'..module_name
    if lfs.mkdir(module_dir) then
      -- write init.lua from template
      local f = io.open(module_dir..'/init.lua', 'w')
      local out = INIT:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
      -- write snippets.lua from template
      f = io.open(module_dir..'/snippets.lua', 'w')
      out = SNIPPETS:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
      -- write commands.lua from template
      f = io.open(module_dir..'/commands.lua', 'w')
      out = COMMANDS:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
    else
      cocoa_dialog( 'msgbox', {
        ['text'] = 'Error',
        ['informative-text'] = 'A module by that name already exists or\n'..
          'you do not have permission to create the module.'
      } )
      return
    end
  elseif menu_item == 'Delete Module' then
    local module_name = selected_item[2]
    if cocoa_dialog( 'yesno-msgbox', {
        ['text'] = 'Delete Module?',
        ['informative-text'] = 'Are you sure you want to permanently delete '..
          'the "'..module_name..'" module?',
        ['no-cancel'] = true,
        ['no-newline'] = true
      } ) == '1' then
      local function remove_directory(dirpath)
        for name in lfs.dir(dirpath) do
          if not name:match('^%.%.?$') then os.remove(dirpath..'/'..name) end
        end
        lfs.rmdir(dirpath)
      end
      remove_directory(_HOME..'/modules/'..module_name)
    else
      return
    end
  elseif menu_item == 'Configure MIME Types' then
    textadept.io.open(_HOME..'/core/ext/mime_types.lua')
  elseif menu_item == 'Configure Key Commands' then
    local textadept = textadept
    if textadept.key_commands then
      textadept.io.open(_HOME..'/core/ext/key_commands.lua')
    elseif textadept.key_commands_std then
      textadept.io.open(_HOME..'/core/ext/key_commands_std.lua')
    elseif textadept.key_commands_mac then
      textadept.io.open(_HOME..'/core/ext/key_commands_mac.lua')
    end
  elseif menu_item == 'Reload Modules' then
    textadept.reset()
  end
  textadept.pm.activate()
end

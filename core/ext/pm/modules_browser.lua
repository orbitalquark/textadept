-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Modules browser for the Textadept project manager.
-- It is enabled with the prefix 'modules' in the project manager entry field.
module('textadept.pm.browsers.modules', package.seeall)

if not RESETTING then textadept.pm.add_browser('modules') end

local lfs = require 'lfs'
local os = require 'os'

local INIT = [[
-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Snippets for the $1 module.
module('_m.$1.snippets', package.seeall)

local snippets = _G.snippets

if type(snippets) == 'table' then
  snippets.$1 = {}
end
]]

local COMMANDS = [[
-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Commands for the $1 module.
module('_m.$1.commands', package.seeall)

-- $2-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
  keys.$1 = {
    al = {
      m = { textadept.io.open,
            textadept.iconv(_HOME..'/modules/$1/init.lua',
                            'UTF-8', _CHARSET) },
    },
  }
end
]]

function matches(entry_text)
  return entry_text:sub(1, 7) == 'modules'
end

local function modify_path(path)
  path[1] = textadept.iconv(_HOME..'/modules', 'UTF-8', _CHARSET)
  return path
end

function get_contents_for(full_path)
  full_path = modify_path(full_path)
  local iconv = textadept.iconv
  local dir = {}
  local dirpath = iconv(table.concat(full_path, '/'), _CHARSET, 'UTF-8')
  for filename in lfs.dir(dirpath) do
    if not filename:find('^%.') then
      local utf8_filename = iconv(filename, 'UTF-8', _CHARSET)
      dir[utf8_filename] = { text = utf8_filename }
      if lfs.attributes(dirpath..'/'..filename, 'mode') == 'directory' then
        dir[utf8_filename].parent = true
        dir[utf8_filename].pixbuf = 'gtk-directory'
      end
    end
  end
  return dir
end

function perform_action(selected_item)
  selected_item = modify_path(selected_item)
  local utf8_filepath = table.concat(selected_item, '/')
  textadept.io.open(utf8_filepath)
  view:focus()
end

local ID = {
  NEW = 1, DELETE = 2, CONF_MIME_TYPES = 3, CONF_KEY_COMMANDS = 4, RELOAD = 5
}

function get_context_menu(selected_item)
  return {
    { locale.PM_BROWSER_MODULE_NEW, ID.NEW },
    { locale.PM_BROWSER_MODULE_DELETE, ID.DELETE },
    { locale.PM_BROWSER_MODULE_CONF_MIME_TYPES, ID.CONF_MIME_TYPES },
    { locale.PM_BROWSER_MODULE_CONF_KEY_COMMANDS, ID.CONF_KEY_COMMANDS },
    { 'separator', 0 },
    { locale.PM_BROWSER_MODULE_RELOAD, ID.RELOAD },
  }
end

function perform_menu_action(menu_id, selected_item)
  if menu_id == ID.NEW then
    local status, module_name =
      cocoa_dialog('standard-inputbox', {
        ['title'] = locale.PM_BROWSER_MODULE_NEW_TITLE,
        ['informative-text'] = locale.PM_BROWSER_MODULE_NEW_INFO_TEXT
      }):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    local status, lang_name =
      cocoa_dialog('standard-inputbox', {
        ['title'] = locale.PM_BROWSER_MODULE_NEW_LANG_TITLE,
        ['informative-text'] = locale.PM_BROWSER_MODULE_NEW_LANG_INFO_TEXT
      }):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    local module_dir = _HOME..'/modules/'..module_name
    if lfs.mkdir(module_dir) then
      -- write init.lua from template
      local f = io.open(module_dir..'/init.lua', 'wb')
      local out = INIT:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
      -- write snippets.lua from template
      f = io.open(module_dir..'/snippets.lua', 'wb')
      out = SNIPPETS:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
      -- write commands.lua from template
      f = io.open(module_dir..'/commands.lua', 'wb')
      out = COMMANDS:gsub('$1', module_name):gsub('$2', lang_name)
      f:write(out)
      f:close()
    else
      cocoa_dialog('ok-msgbox', {
        ['text'] = locale.PM_BROWSER_MODULE_NEW_ERROR,
        ['informative-text'] = locale.PM_BROWSER_MODULE_NEW_ERROR_TEXT,
        ['no-cancel'] = true
      })
      return
    end
  elseif menu_id == ID.DELETE then
    local module_name = selected_item[2]
    if cocoa_dialog('yesno-msgbox', {
        ['text'] = locale.PM_BROWSER_MODULE_DELETE_TITLE,
        ['informative-text'] =
          string.format(locale.PM_BROWSER_MODULE_DELETE_TEXT, module_name),
        ['no-cancel'] = true,
        ['no-newline'] = true
      }) == '1' then
      local function remove_directory(dirpath)
        for name in lfs.dir(dirpath) do
          if not name:find('^%.%.?$') then os.remove(dirpath..'/'..name) end
        end
        lfs.rmdir(dirpath)
      end
      remove_directory(_HOME..'/modules/'..module_name)
    else
      return
    end
  elseif menu_id == ID.CONF_MIME_TYPES then
    textadept.io.open(
      textadept.iconv(_HOME..'/core/ext/mime_types.lua', 'UTF-8', _CHARSET))
  elseif menu_id == ID.CONF_KEY_COMMANDS then
    if textadept.key_commands then
      textadept.io.open(
        textadept.iconv(_HOME..'/core/ext/key_commands.lua', 'UTF-8', _CHARSET))
    end
  elseif menu_id == ID.RELOAD then
    textadept.reset()
  end
  textadept.pm.activate()
end

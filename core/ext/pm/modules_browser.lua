-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Modules browser for the Textadept project manager.
-- It is enabled with the prefix 'modules' in the project manager entry field.
module('textadept.pm.browsers.modules', package.seeall)

function matches(entry_text)
  return entry_text:sub(1, 7) == 'modules'
end

local function modify_path(path)
  table.remove(path, 1) -- 'modules' entry_text
  table.insert(path, 1, _HOME..'/modules')
  return path
end

function get_contents_for(full_path)
  full_path = modify_path(full_path)
  local dirpath = table.concat(full_path, '/')
  local p = io.popen('ls -1p "'..dirpath..'"')
  local out = p:read('*all')
  p:close()
  if #out == 0 then
    error('No such directory: '..dirpath)
    return {}
  end
  local dir = {}
  for entry in out:gmatch('[^\n]+') do
    if entry:sub(-1, -1) == '/' then
      local name = entry:sub(1, -2)
      dir[name] = {
        parent = true,
        display_text = name,
        pixbuf = 'gtk-directory'
      }
    else
      dir[entry] = { display_text = entry, pixbuf = '' }
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
    local status, module_name = cocoa_dialog( 'inputbox', {
      ['title'] = 'Module Name',
      ['informative-text'] = 'Module name:',
      ['button2'] = 'gtk-cancel'
    } ):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    local status, lang_name = cocoa_dialog( 'inputbox', {
      ['title'] = 'Language Name',
      ['informative-text'] = 'Language name:',
      ['button2'] = 'gtk-cancel'
    } ):match('^(%d)%s+([^\n]+)%s+$')
    if status ~= '1' then return end
    status = os.execute('cd "'.._HOME..'/modules"; '..
      './new "'..module_name..'" "'..lang_name..'"')
    if status ~= 0 then
      cocoa_dialog( 'msgbox', {
        ['title'] = 'Error',
        ['informative-text'] = 'An error occured. It is likely the module '..
          'already exists.'
      } )
      return
    end
  elseif menu_item == 'Delete Module' then
    local module_name = selected_item[2]
    if cocoa_dialog( 'yesno-msgbox', {
        ['title'] = 'Confirm Delete',
        ['informative-text'] = 'Are you sure you want to delete the "'..
          module_name..'" module?',
        ['no-cancel'] = true,
        ['no-newline'] = true
      } ) == '1' then
      os.execute('rm -r "'.._HOME..'/modules/'..module_name..'"')
    else
      return
    end
  elseif menu_item == 'Configure MIME Types' then
    textadept.io.open(_HOME..'/core/ext/mime_types.lua')
  elseif menu_item == 'Configure Key Commands' then
    textadept.io.open(_HOME..'/core/ext/key_commands.lua')
  elseif menu_item == 'Reload Modules' then
    textadept.reset()
  end
  textadept.pm.activate()
end

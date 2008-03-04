-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- File browser for the Textadept project manager.
-- It is enabled by providing the absolute path to a directory in the project
-- manager entry field.
module('textadept.pm.browsers.file', package.seeall)

function matches(entry_text)
  return entry_text:sub(1, 1) == '/'
end

function get_contents_for(full_path)
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
      dir[entry] = { display_text = entry }
    end
  end
  return dir
end

function perform_action(selected_item)
  local filepath = table.concat(selected_item, '/')
  textadept.io.open(filepath)
  view:focus()
end

function get_context_menu(selected_item)
  return { '_Change Directory', 'File _Details' }
end

function perform_menu_action(menu_item, selected_item)
  local filepath = table.concat(selected_item, '/')
  if menu_item == 'Change Directory' then
    textadept.pm.entry_text = filepath
    textadept.pm.activate()
  elseif menu_item == 'File Details' then
    local p = io.popen('ls -dhl "'..filepath..'"')
    local out = p:read('*all')
    p:close()
    local perms, num_dirs, owner, group, size, mod_date =
      out:match('^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+ %S)')
    out = 'File details for:\n'..filepath..'\n'..
          'Perms:\t'..perms..'\n'..
          '#Dirs:\t'..num_dirs..'\n'..
          'Owner:\t'..owner..'\n'..
          'Group:\t'..group..'\n'..
          'Size:\t'..size..'\n'..
          'Date:\t'..mod_date
    text_input(out, nil, false, 250, 250)
  end
end

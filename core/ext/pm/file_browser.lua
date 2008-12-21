-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- File browser for the Textadept project manager.
-- It is enabled by providing the absolute path to a directory in the project
-- manager entry field.
module('textadept.pm.browsers.file', package.seeall)

local lfs = require 'lfs'
local os = require 'os'

function matches(entry_text)
  if not WIN32 then
    return entry_text:sub(1, 1) == '/'
  else
    return entry_text:match('[A-Za-z]:[\\/]')
  end
end

function get_contents_for(full_path)
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
    local date_format = '%D %T'
    local attr = lfs.attributes(filepath)
    local out = string.format( [[
      Mode:	%s
      Size:	%s
      UID:	%s
      GID:	%s
      Device:	%s
      Accessed:	%s
      Modified:	%s
      Changed:	%s
    ]], attr.mode, attr.size, attr.uid, attr.gid, attr.dev,
      os.date(date_format, attr.access),
      os.date(date_format, attr.modification),
      os.date(date_format, attr.change) )
    cocoa_dialog( 'textbox', {
      ['informative-text'] = 'File details for '..filepath,
      text = out,
      button1 = 'OK',
      editable = false
    } )
  end
end

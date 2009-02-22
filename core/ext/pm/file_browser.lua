-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- File browser for the Textadept project manager.
-- It is enabled by providing the absolute path to a directory in the project
-- manager entry field.
module('textadept.pm.browsers.file', package.seeall)

if not RESETTING then textadept.pm.add_browser(not WIN32 and '/' or 'C:\\') end

local lfs = require 'lfs'
local os = require 'os'

show_dot_files = false

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
  local path = lfs.attributes(dirpath)
  local invalid_file = show_dot_files and '^%.%.?$' or '^%.'
  if path and path.mode == 'directory' then
    for name in lfs.dir(dirpath) do
      if not name:find(invalid_file) then
        dir[name] = { text = name }
        if lfs.attributes(dirpath..'/'..name, 'mode') == 'directory' then
          dir[name].parent = true
          dir[name].pixbuf = 'gtk-directory'
        end
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

local ID = { CHANGE_DIR = 1, FILE_INFO = 2, SHOW_DOT_FILES = 3 }

function get_context_menu(selected_item)
  return {
    { 'separator', 0 }, -- make it harder to click 'Change Directory' by mistake
    { locale.PM_BROWSER_FILE_CD, ID.CHANGE_DIR },
    { locale.PM_BROWSER_FILE_INFO, ID.FILE_INFO },
    { locale.PM_BROWSER_FILE_SHOW_DOT_FILES, ID.SHOW_DOT_FILES },
  }
end

function perform_menu_action(menu_id, selected_item)
  local filepath = table.concat(selected_item, '/'):gsub('[/\\]+', '/')
  if menu_id == ID.CHANGE_DIR then
    textadept.pm.entry_text = filepath
    textadept.pm.activate()
  elseif menu_id == ID.FILE_INFO then
    local date_format = '%D %T'
    local attr = lfs.attributes(filepath)
    local out =
      string.format(locale.PM_BROWSER_FILE_DATA,
                    attr.mode, attr.size, attr.uid, attr.gid, attr.dev,
                    os.date(date_format, attr.access),
                    os.date(date_format, attr.modification),
                    os.date(date_format, attr.change))
    cocoa_dialog('textbox', {
      ['informative-text'] =
        string.format(locale.PM_BROWSER_FILE_INFO_TEXT, filepath),
      text = out,
      button1 = locale.PM_BROWSER_FILE_INFO_OK,
      editable = false
    })
  elseif menu_id == ID.SHOW_DOT_FILES then
    show_dot_files = not show_dot_files
    textadept.pm.activate()
  end
end

-- load the dropped directory (if any) into the file browser; events.lua's
-- "uri_dropped" handler already opens dropped files
textadept.events.add_handler('uri_dropped',
  function(uris)
    for uri in uris:gmatch('[^\r\n\f]+') do
      if uri:find('^file://') then
        uri = uri:match('^file://([^\r\n\f]+)')
        uri = uri:gsub('%%20', ' ') -- sub back for spaces
        if WIN32 then uri = uri:sub(2, -1) end -- ignore leading '/'
        if lfs.attributes(uri).mode == 'directory' then
          textadept.pm.entry_text = uri
          textadept.pm.activate()
          return
        end
      end
    end
  end)

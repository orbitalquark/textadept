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
  local iconv = textadept.iconv
  local dir = {}
  local dirpath = iconv(table.concat(full_path, '/'), _CHARSET, 'UTF-8')
  local path = lfs.attributes(dirpath)
  if path and path.mode == 'directory' then
    local invalid_file = show_dot_files and '^%.%.?$' or '^%.'
    for filename in lfs.dir(dirpath) do
      if not filename:find(invalid_file) then
        local utf8_filename = iconv(filename, 'UTF-8', _CHARSET)
        dir[utf8_filename] = { text = utf8_filename }
        if lfs.attributes(dirpath..'/'..filename, 'mode') == 'directory' then
          dir[utf8_filename].parent = true
          dir[utf8_filename].pixbuf = 'gtk-directory'
        end
      end
    end
  end
  return dir
end

function perform_action(selected_item)
  local utf8_filepath = table.concat(selected_item, '/')
  textadept.io.open(utf8_filepath)
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
  local utf8_filepath = table.concat(selected_item, '/'):gsub('[/\\]+', '/')
  local filepath = textadept.iconv(utf8_filepath, _CHARSET, 'UTF-8')
  if menu_id == ID.CHANGE_DIR then
    textadept.pm.entry_text = utf8_filepath
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
    textadept.dialog('textbox',
                     '--informative-text',
                       string.format(locale.PM_BROWSER_FILE_INFO_TEXT,
                                     utf8_filepath),
                     '--text', out,
                     '--button1', locale.PM_BROWSER_FILE_INFO_OK)
  elseif menu_id == ID.SHOW_DOT_FILES then
    show_dot_files = not show_dot_files
    textadept.pm.activate()
  end
end

-- load the dropped directory (if any) into the file browser; events.lua's
-- "uri_dropped" handler already opens dropped files
textadept.events.add_handler('uri_dropped',
  function(utf8_uris)
    local lfs = require 'lfs'
    for utf8_uri in utf8_uris:gmatch('[^\r\n\f]+') do
      if utf8_uri:find('^file://') then
        utf8_uri = utf8_uri:match('^file://([^\r\n\f]+)')
        utf8_uri = utf8_uri:gsub('%%(%x%x)',
          function(hex) return string.char(tonumber(hex, 16)) end)
        if WIN32 then utf8_uri = utf8_uri:sub(2, -1) end -- ignore leading '/'
        local uri = textadept.iconv(utf8_uri, _CHARSET, 'UTF-8')
        if lfs.attributes(uri).mode == 'directory' then
          textadept.pm.add_browser(utf8_uri)
          textadept.pm.entry_text = utf8_uri
          textadept.pm.activate()
        end
      end
    end
  end)

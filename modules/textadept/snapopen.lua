-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local locale = _G.locale

---
-- Snapopen for the textadept module.
module('_m.textadept.snapopen', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `PATHS`: Table of default paths to search.
-- * `DEPTH`: Maximum directory depth to search (defaults to 4).
-- * `MAX`: Maximum number of files to list (defaults to 1000).
--
-- ## Examples
--
--     local snapopen = _m.textadept.snapopen
--
--     -- Show all files in PATHS.
--     snapopen()
--
--     -- Show all files in the current file's directory.
--     snapopen(buffer.filename:match('^.+[/\\]'), nil, true)
--
--     -- Show all Lua files in PATHS.
--     snapopen(nil, '!%.lua$')
--
--     -- Ignore the .hg folder in the local Mercurial repository.
--     local project_dir = '/path/to/project'
--     snapopen(project_dir, { folders = { '%.hg' } }, true)

-- settings
PATHS = {}
DEPTH = 4
MAX = 1000
-- end settings

local lfs = require 'lfs'

-- Determines whether or not the given file matches the given filter.
-- @param file The filename.
-- @param filter The filter table.
-- @return boolean true or false.
local function exclude(file, filter)
  if not filter then return false end
  local string_match, string_sub = string.match, string.sub
  for i = 1, #filter do
    local patt = filter[i]
    if string_sub(patt, 1, 1) ~= '!' then
      if string_match(file, patt) then return true end
    else
      if not string_match(file, string_sub(patt, 2)) then return true end
    end
  end
  return false
end

-- Adds a directory's contents to a list of files.
-- @param dir The directory to open.
-- @param list The list of files to add dir's contents to.
-- @param depth The current depth of nested folders.
-- @param filter The filter table.
local function add_directory(dir, list, depth, filter)
  local string_match, string_gsub = string.match, string.gsub
  for file in lfs.dir(dir) do
    if not string_match(file, '^%.%.?$') then
      file = dir..(not WIN32 and '/' or '\\')..file
      if lfs.attributes(file).mode == 'directory' then
        if not exclude(file, filter.folders) and depth < DEPTH then
          add_directory(file, list, depth + 1, filter)
        end
      elseif not exclude(file, filter) then
        if #list >= MAX then return end
        list[#list + 1] = string_gsub(file, '^%.[/\\]', '')
      end
    end
  end
end

---
-- Quickly open a file in set of directories.
-- @param paths A string directory path or table of directory paths to search.
-- @param filter A filter for files and folders to exclude. The filter may be
--   a string or table. Each filter is a Lua pattern. Any files matching a
--   filter are excluded. Prefix a pattern with '!' to exclude any files that
--   do not match the filter. Directories can be excluded by adding filters to
--   a table assigned to a 'folders' key in the filter table.
-- @param exclusive Flag indicating whether or not to exclude PATHS in the
--   search. Defaults to false.
-- @usage _m.textadept.snapopen.open()
-- @usage _m.textadept.snapopen.open(buffer.filename:match('^.+/'), nil, true)
-- @usage _m.textadept.snapopen.open(nil, '!%.lua$')
-- @usage _m.textadept.snapopen.open(nil, { folders = { '%.hg' } })
function open(paths, filter, exclusive)
  if not paths then paths = {} end
  if type(paths) == 'string' then paths = { paths } end
  if not filter then filter = {} end
  if type(filter) == 'string' then filter = { filter } end
  if not exclusive then
    for _, path in ipairs(PATHS) do paths[#paths + 1] = path end
  end
  local list = {}
  for _, path in ipairs(paths) do add_directory(path, list, 1, filter) end
  if #list >= MAX then
    gui.dialog('ok-msgbox',
               '--title', locale.M_SNAPOPEN_LIMIT_EXCEEDED_TITLE,
               '--informative-text',
                 string.format(locale.M_SNAPOPEN_LIMIT_EXCEEDED_TEXT, MAX, MAX))
  end
  local out =
    gui.dialog('filteredlist',
               '--title', locale.IO_OPEN_TITLE,
               '--button1', 'gtk-ok',
               '--button2', 'gtk-cancel',
               '--no-newline',
               '--columns', 'File',
               '--items', unpack(list))
  local response, index = out:match('^(%d+)[\r\n]+(%d+)')
  if response == '1' then io.open_file(list[tonumber(index) + 1]) end
end

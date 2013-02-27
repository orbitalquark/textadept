-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Quickly open files in a set of directories using a filtered list dialog.
-- @field DEFAULT_DEPTH (number)
--   The maximum directory depth to search.
--   The default value is `99`.
-- @field MAX (number)
--   The maximum number of files to list.
--   The default value is `1000`.
module('_M.textadept.snapopen')]]

---
-- The default filter table containing common binary file extensions and version
-- control folders to exclude from snapopen file lists.
-- @class table
-- @name FILTER
M.FILTER = {
  extensions = {
    'a', 'bmp', 'bz2', 'class', 'dll', 'exe', 'gif', 'gz', 'jar', 'jpeg', 'jpg',
    'o', 'png', 'so', 'tar', 'tgz', 'tif', 'tiff', 'zip'
  },
  folders = {'%.bzr$', '%.git$', '%.hg$', '%.svn$', 'CVS$'}
}
M.DEFAULT_DEPTH = 99
M.MAX = 1000

local lfs_dir, lfs_attributes = lfs.dir, lfs.attributes
local DEPTH = M.DEFAULT_DEPTH

-- Determines whether or not the given file matches the given filter.
-- @param file The filename.
-- @param filter The filter table.
-- @return boolean `true` or `false`.
local function exclude(file, filter)
  if not filter then return false end
  local string_match, string_sub = string.match, string.sub
  local utf8_file = file:iconv('UTF-8', _CHARSET)
  local ext = filter.extensions
  if ext and ext[utf8_file:match('[^%.]+$')] then return true end
  for i = 1, #filter do
    local patt = filter[i]
    if string_sub(patt, 1, 1) ~= '!' then
      if string_match(utf8_file, patt) then return true end
    else
      if not string_match(utf8_file, string_sub(patt, 2)) then return true end
    end
  end
  return false
end

-- Adds a directory's contents to a list of files.
-- @param utf8_dir The UTF-8 directory to open.
-- @param list The list of files to add dir's contents to.
-- @param depth The current depth of nested folders.
-- @param filter The filter table.
local function add_directory(utf8_dir, list, depth, filter)
  local string_match, string_gsub, MAX = string.match, string.gsub, M.MAX
  local dir = utf8_dir:iconv(_CHARSET, 'UTF-8')
  for file in lfs_dir(dir) do
    if not string_match(file, '^%.%.?$') then
      file = dir..(not WIN32 and '/' or '\\')..file
      if lfs_attributes(file, 'mode') == 'directory' then
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
-- Quickly open files from the set of directories *utf8_paths* using a filtered
-- list dialog.
-- Files shown in the dialog do not match any pattern in string or table
-- *filter*, and, unless *exclude_FILTER* is `true`, `FILTER` as well. A filter
-- table contains Lua patterns that match filenames to exclude. Patterns
-- starting with '!' exclude files that do not match the pattern that follows.
-- The filter may also contain an `extensions` key whose value is a table of
-- file extensions to exclude. Additionally, it may contain a `folders` key
-- whose value is a table of folder names to exclude. Extensions and folder
-- names must be encoded in UTF-8. The number of files in the list is capped at
-- `MAX`.
-- @param utf8_paths A UTF-8 string directory path or table of UTF-8 directory
--   paths to search.
-- @param filter Optional filter for files and folders to exclude.
-- @param exclude_FILTER Optional flag indicating whether or not to exclude the
--   default filter `FILTER` in the search. If `false`, adds `FILTER` to
--   *filter*.
--   The default value is `false` to include the default filter.
-- @param depth Number of directories to recurse into for finding files.
--   The default value is `DEFAULT_DEPTH`.
-- @usage _M.textadept.snapopen.open(buffer.filename:match('^.+/')) -- list all
--   files in the current file's directory, subject to the default filter
-- @usage _M.textadept.snapopen.open('/project', '!%.lua$') -- list all Lua
--    files in a project directory
-- @usage _M.textadept.snapopen.open('/project', {folders = {'build'}}) -- list
--   all source files in a project directory
-- @see FILTER
-- @see DEFAULT_DEPTH
-- @see MAX
-- @name open
function M.open(utf8_paths, filter, exclude_FILTER, depth)
  -- Convert utf8_paths to a table from nil or string arguments.
  if not utf8_paths then utf8_paths = {} end
  if type(utf8_paths) == 'string' then utf8_paths = {utf8_paths} end
  -- Convert filter to a table from nil or string arguments.
  if not filter then filter = {} end
  if type(filter) == 'string' then filter = {filter} end
  -- Add FILTER to filter unless specified otherwise.
  if not exclude_FILTER then
    for k, v in pairs(M.FILTER) do
      if not filter[k] then filter[k] = {} end
      local filter_k = filter[k]
      for i = 1, #v do filter_k[#filter_k + 1] = v[i] end
    end
  end
  DEPTH = depth or M.DEFAULT_DEPTH

  -- Create file extension filter hash table for quick lookups.
  local ext = filter.extensions
  if ext then for i = 1, #ext do ext[ext[i]] = true end end

  -- Create the file list, prompt the user to choose a file, then open the file.
  local list = {}
  for _, path in ipairs(utf8_paths) do add_directory(path, list, 1, filter) end
  if #list >= M.MAX then
    gui.dialog('ok-msgbox',
               '--title', _L['File Limit Exceeded'],
               '--text',
               string.format('%d %s %d', M.MAX,
                             _L['files or more were found. Showing the first'],
                             M.MAX),
               '--button1', _L['_OK'])
  end
  local width = NCURSES and {'--width', gui.size[1] - 2} or ''
  local utf8_filenames = gui.filteredlist(_L['Open'], _L['File'], list, false,
                                          '--select-multiple', width) or ''
  for filename in utf8_filenames:gmatch('[^\n]+') do io.open_file(filename) end
end

return M

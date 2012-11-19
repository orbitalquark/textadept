-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Quickly open files in a set of directories using a filtered list dialog.
-- @field DEFAULT_DEPTH (number)
--   Maximum directory depth to search.
--   The default value is `99`.
-- @field MAX (number)
--   Maximum number of files to list.
--   The default value is `1000`.
module('_M.textadept.snapopen')]]

---
-- Table of default UTF-8 paths to search.
-- @class table
-- @name PATHS
M.PATHS = {}
---
-- Default file and directory filters.
-- Contains common binary file extensions and version control folders.
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
-- Quickly open files in set of directories using a filtered list dialog.
-- The number of files in the list is capped at `MAX`.
-- @param utf8_paths A UTF-8 string directory path or table of UTF-8 directory
--   paths to search.
-- @param filter A filter for files and folders to exclude. The filter may be
--   a string or table. Each filter is a Lua pattern. Any files matching a
--   filter are excluded. Prefix a pattern with '!' to exclude any files that
--   do not match a filter. File extensions can be more efficiently excluded by
--   adding the extension text to a table assigned to an `extensions` key in the
--   filter table instead of using individual filters. Directories can be
--   excluded by adding filters to a table assigned to a `folders` key in the
--   filter table. All strings should be UTF-8 encoded.
-- @param exclude_PATHS Flag indicating whether or not to exclude `PATHS` in the
--   search. The default value is `false`.
-- @param exclude_FILTER Flag indicating whether or not to exclude `FILTER` from
--   `filter` in the search. If false, adds `FILTER` to the given `filter`.
--   The default value is `false`.
-- @param depth Number of directories to recurse into for finding files.
--   The default value is `DEFAULT_DEPTH`.
-- @usage _M.textadept.snapopen.open() -- list all files in PATHS
-- @usage _M.textadept.snapopen.open(buffer.filename:match('^.+/'), nil, true)
--   -- list all files in the current file's directory
-- @usage _M.textadept.snapopen.open(nil, '!%.lua$') -- list all Lua files in
--    PATHS
-- @usage _M.textadept.snapopen.open('/project', {folders = {'secret'}},
--   true) -- list all project files except those in a secret folder
-- @see PATHS
-- @see FILTER
-- @see DEFAULT_DEPTH
-- @see MAX
-- @name open
function M.open(utf8_paths, filter, exclude_PATHS, exclude_FILTER, depth)
  -- Convert utf8_paths to a table from nil or string arguments.
  if not utf8_paths then utf8_paths = {} end
  if type(utf8_paths) == 'string' then utf8_paths = {utf8_paths} end
  -- Convert filter to a table from nil or string arguments.
  if not filter then filter = {} end
  if type(filter) == 'string' then filter = {filter} end
  -- Add PATHS to utf8_paths unless specified otherwise.
  if not exclude_PATHS then
    for i = 1, #M.PATHS do utf8_paths[#utf8_paths + 1] = M.PATHS[i] end
  end
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
               '--informative-text',
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

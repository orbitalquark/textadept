-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Snapopen for the textadept module.
module('_M.textadept.snapopen')]]

-- Markdown:
-- ## Settings
--
-- * `PATHS` [table]: Table of default UTF-8 paths to search.
-- * `DEFAULT_DEPTH` [number]: Maximum directory depth to search. The default
--   value is `4`.
-- * `MAX` [number]: Maximum number of files to list. The default value is
--   `1000`.
--
-- ## Examples
--
--     local snapopen = _M.textadept.snapopen.open
--
--     -- Show all files in PATHS.
--     snapopen()
--
--     -- Show all files in the current file's directory.
--     snapopen(buffer.filename:match('^(.+)[/\\]'), nil, true)
--
--     -- Show all Lua files in PATHS.
--     snapopen(nil, '!%.lua$')
--
--     -- Ignore the .hg folder in the local Mercurial repository.
--     local project_dir = '/path/to/project'
--     snapopen(project_dir, { folders = { '%.hg' } }, true)

M.PATHS = {}
M.DEFAULT_DEPTH = 4
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
-- Quickly open a file in set of directories.
-- @param utf8_paths A UTF-8 string directory path or table of UTF-8 directory
--   paths to search.
-- @param filter A filter for files and folders to exclude. The filter may be
--   a string or table. Each filter is a Lua pattern. Any files matching a
--   filter are excluded. Prefix a pattern with `!` to exclude any files that
--   do not match the filter. Directories can be excluded by adding filters to
--   a table assigned to a `folders` key in the filter table. All strings should
--   be UTF-8 encoded.
-- @param exclusive Flag indicating whether or not to exclude `PATHS` in the
--   search. Defaults to `false`.
-- @param depth Number of directories to recurse into for finding files.
--   Defaults to `DEFAULT_DEPTH`.
-- @usage _M.textadept.snapopen.open()
-- @usage _M.textadept.snapopen.open(buffer.filename:match('^.+/'), nil, true)
-- @usage _M.textadept.snapopen.open(nil, '!%.lua$')
-- @usage _M.textadept.snapopen.open(nil, { folders = { '%.hg' } })
-- @name open
function M.open(utf8_paths, filter, exclusive, depth)
  if not utf8_paths then utf8_paths = {} end
  if type(utf8_paths) == 'string' then utf8_paths = { utf8_paths } end
  if not filter then filter = {} end
  if type(filter) == 'string' then filter = { filter } end
  if not exclusive then
    for _, path in ipairs(M.PATHS) do utf8_paths[#utf8_paths + 1] = path end
  end
  DEPTH = depth or M.DEFAULT_DEPTH
  local list = {}
  for _, path in ipairs(utf8_paths) do add_directory(path, list, 1, filter) end
  if #list >= M.MAX then
    gui.dialog('ok-msgbox',
               '--title', _L['File Limit Exceeded'],
               '--informative-text',
               string.format('%d %s %d', M.MAX,
                             _L['files or more were found. Showing the first'],
                             M.MAX))
  end
  local utf8_filenames = gui.filteredlist(_L['Open'], _L['File'], list, false,
                                          '--select-multiple') or ''
  for filename in utf8_filenames:gmatch('[^\n]+') do io.open_file(filename) end
end

return M

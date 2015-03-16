-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- Extends the `lfs` library to find files in directories and determine absolute
-- file paths.
module('lfs')]]

---
-- The filter table containing common binary file extensions and version control
-- directories to exclude when iterating over files and directories using
-- `dir_foreach` when its `exclude_FILTER` argument is `false`.
-- @see dir_foreach
-- @class table
-- @name FILTER
lfs.FILTER = {
  extensions = {
    'a', 'bmp', 'bz2', 'class', 'dll', 'exe', 'gif', 'gz', 'jar', 'jpeg', 'jpg',
    'o', 'png', 'so', 'tar', 'tgz', 'tif', 'tiff', 'zip'
  },
  folders = {'%.bzr$', '%.git$', '%.hg$', '%.svn$', 'CVS$'}
}

-- Determines whether or not the given file matches the given filter.
-- @param file The filename.
-- @param filter The filter table.
-- @return boolean `true` or `false`.
local function exclude(file, filter)
  if not filter then return false end
  local ext = filter.extensions
  if ext and ext[file:match('[^%.]+$')] then return true end
  for i = 1, #filter do
    local patt = filter[i]
    if patt:sub(1, 1) ~= '!' then
      if file:find(patt) then return true end
    else
      if not file:find(patt:sub(2)) then return true end
    end
  end
  return false
end

---
-- Iterates over all files and sub-directories (up to *n* levels deep) in
-- directory *dir*, calling function *f* with each file found.
-- Files passed to *f* do not match any pattern in string or table *filter*,
-- and, unless *exclude_FILTER* is `true`, `lfs.FILTER` as well. A filter table
-- contains Lua patterns that match filenames to exclude, an optional `folders`
-- sub-table that contains patterns matching directories to exclude, and an
-- optional `extensions` sub-table that contains raw file extensions to exclude.
-- Any patterns starting with '!' exclude files and directories that do not
-- match the pattern that follows.
-- @param dir The directory path to iterate over.
-- @param f Function to call with each full file path found. If *f* returns
--   `false` explicitly, iteration ceases.
-- @param filter Optional filter for files and directories to exclude.
-- @param exclude_FILTER Optional flag indicating whether or not to exclude the
--   default filter `lfs.FILTER` in the search. If `false`, adds `lfs.FILTER` to
--   *filter*.
--   The default value is `false` to include the default filter.
-- @param n Optional maximum number of directory levels to descend into.
--   The default value is `nil`, which indicates no limit.
-- @param include_dirs Optional flag indicating whether or not to call *f* with
--   directory names too. Directory names are passed with a trailing '/' or '\',
--   depending on the current platform.
--   The default value is `false`.
-- @param level Utility value indicating the directory level this function is
--   at. This value is used and set internally, and should not be set otherwise.
-- @see FILTER
-- @name dir_foreach
function lfs.dir_foreach(dir, f, filter, exclude_FILTER, n, include_dirs, level)
  if not level then level = 0 end
  if level == 0 then
    -- Convert filter to a table from nil or string arguments.
    if not filter then filter = {} end
    if type(filter) == 'string' then filter = {filter} end
    -- Add FILTER to filter unless specified otherwise.
    if not exclude_FILTER then
      for k, v in pairs(lfs.FILTER) do
        if not filter[k] then filter[k] = {} end
        local filter_k = filter[k]
        for i = 1, #v do filter_k[#filter_k + 1] = v[i] end
      end
    end
    -- Create file extension filter hash table for quick lookups.
    local ext = filter.extensions
    if ext then for i = 1, #ext do ext[ext[i]] = true end end
  end
  local dir_sep, lfs_attributes = not WIN32 and '/' or '\\', lfs.attributes
  for file in lfs.dir(dir) do
    if not file:find('^%.%.?$') then -- ignore . and ..
      file = dir..(dir ~= '/' and dir_sep or '')..file
      local type = lfs_attributes(file, 'mode')
      if type == 'directory' and not exclude(file, filter.folders) then
        if include_dirs and f(file..dir_sep) == false then return end
        if not n or level < n then
          lfs.dir_foreach(file, f, filter, nil, n, include_dirs, level + 1)
        end
      elseif type == 'file' and not exclude(file, filter) then
        if f(file) == false then return end
      end
    end
  end
end

---
-- Returns the absolute path to string *filename*.
-- *prefix* or `lfs.currentdir()` is prepended to a relative filename. The
-- returned path is not guaranteed to exist.
-- @param filename The relative or absolute path to a file.
-- @param prefix Optional prefix path prepended to a relative filename.
-- @return string absolute path
-- @name abspath
function lfs.abspath(filename, prefix)
  if WIN32 then filename = filename:gsub('/', '\\') end
  if not filename:find(not WIN32 and '^/' or '^%a:[/\\]') and
     not (WIN32 and filename:find('^\\\\')) then
    prefix = prefix or lfs.currentdir()
    filename = prefix..(not WIN32 and '/' or '\\')..filename
  end
  filename = filename:gsub('%f[^/\\]%.[/\\]', '') -- clean up './'
  while filename:find('[^/\\]+[/\\]%.%.[/\\]') do
    filename = filename:gsub('[^/\\]+[/\\]%.%.[/\\]', '') -- clean up '../'
  end
  return filename
end

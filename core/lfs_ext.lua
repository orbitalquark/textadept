-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- Extends the `lfs` library to find files in directories and determine absolute
-- file paths.
module('lfs')]]

---
-- The filter table containing common binary file extensions and version control
-- directories to exclude when iterating over files and directories using
-- `dir_foreach`.
-- @see dir_foreach
-- @class table
-- @name default_filter
lfs.default_filter = {
  extensions = {
    'a', 'bmp', 'bz2', 'class', 'dll', 'exe', 'gif', 'gz', 'jar', 'jpeg', 'jpg',
    'o', 'pdf', 'png', 'so', 'tar', 'tgz', 'tif', 'tiff', 'xz', 'zip'
  },
  folders = {'%.bzr$', '%.git$', '%.hg$', '%.svn$', 'node_modules'}
}

local lfs_symlinkattributes = lfs.symlinkattributes
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
  return filter.symlink and lfs_symlinkattributes(file, 'mode') == 'link'
end

---
-- Iterates over all files and sub-directories (up to *n* levels deep) in
-- directory *dir*, calling function *f* with each file found.
-- Files passed to *f* do not match any pattern in string or table *filter*
-- (or `lfs.default_filter` when *filter* is `nil`). A filter table contains:
--
--   + Lua patterns that match filenames to exclude.
--   + Optional `folders` sub-table that contains patterns matching directories
--     to exclude.
--   + Optional `extensions` sub-table that contains raw file extensions to
--     exclude.
--   + Optional `symlink` flag that when `true`, excludes symlinked files (but
--     not symlinked directories).
--   + Optional `folders.symlink` flag that when `true`, excludes symlinked
--     directories.
--
-- Any filter patterns starting with '!' exclude files and directories that do
-- not match the pattern that follows.
-- @param dir The directory path to iterate over.
-- @param f Function to call with each full file path found. If *f* returns
--   `false` explicitly, iteration ceases.
-- @param filter Optional filter for files and directories to exclude. The
--   default value is `lfs.default_filter`.
-- @param n Optional maximum number of directory levels to descend into.
--   The default value is `nil`, which indicates no limit.
-- @param include_dirs Optional flag indicating whether or not to call *f* with
--   directory names too. Directory names are passed with a trailing '/' or '\',
--   depending on the current platform.
--   The default value is `false`.
-- @param level Utility value indicating the directory level this function is
--   at. This value is used and set internally, and should not be set otherwise.
-- @see filter
-- @name dir_foreach
function lfs.dir_foreach(dir, f, filter, n, include_dirs, level)
  if not level then level = 0 end
  if level == 0 then
    -- Convert filter to a table from nil or string arguments.
    if not filter then filter = lfs.default_filter end
    if type(filter) == 'string' then filter = {filter} end
    -- Create file extension filter hash table for quick lookups.
    local ext = filter.extensions
    if ext then for i = 1, #ext do ext[ext[i]] = true end end
  end
  local dir_sep, lfs_attributes = not WIN32 and '/' or '\\', lfs.attributes
  for basename in lfs.dir(dir) do
    if not basename:find('^%.%.?$') then -- ignore . and ..
      local filename = dir..(dir ~= '/' and dir_sep or '')..basename
      local mode = lfs_attributes(filename, 'mode')
      if mode == 'directory' and not exclude(filename, filter.folders) then
        if include_dirs and f(filename..dir_sep) == false then return end
        if not n or level < n then
          local halt = lfs.dir_foreach(filename, f, filter, n, include_dirs,
                                       level + 1) == false
          if halt then return false end
        end
      elseif mode == 'file' and not exclude(filename, filter) then
        if f(filename) == false then return false end
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
    filename = filename:gsub('[^/\\]+[/\\]%.%.[/\\]', '', 1) -- clean up '../'
  end
  return filename
end

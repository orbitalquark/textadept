-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

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
  -- File extensions to exclude.
  '!.a', '!.bmp', '!.bz2', '!.class', '!.dll', '!.exe', '!.gif', '!.gz',
  '!.jar', '!.jpeg', '!.jpg', '!.o', '!.pdf', '!.png', '!.so', '!.tar', '!.tgz',
  '!.tif', '!.tiff', '!.xz', '!.zip',
  -- Directories to exclude.
  '!/%.bzr$', '!/%.git$', '!/%.hg$', '!/%.svn$', '!/node_modules$',
}

---
-- Iterates over all files and sub-directories (up to *n* levels deep) in
-- directory *dir*, calling function *f* with each file found.
-- String or list *filter* determines which files to pass through to *f*, with
-- the default filter being `lfs.default_filter`. A filter consists of Lua
-- patterns that match file and directory paths to include or exclude. Exclusive
-- patterns begin with a '!'. If no inclusive patterns are given, any path is
-- initially considered. As a convenience, file extensions can be specified
-- literally instead of as a Lua pattern (e.g. '.lua' vs. '%.lua$'), and '/'
-- also matches the Windows directory separator ('[/\\]' is not needed).
-- @param dir The directory path to iterate over.
-- @param f Function to call with each full file path found. If *f* returns
--   `false` explicitly, iteration ceases.
-- @param filter Optional filter for files and directories to include and
--   exclude. The default value is `lfs.default_filter`.
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
  assert_type(dir, 'string', 1)
  assert_type(f, 'function', 2)
  assert_type(filter, 'string/table/nil', 3)
  assert_type(n, 'number/nil', 4)
  if not level then
    -- Convert filter to a table from nil or string arguments.
    if not filter then filter = lfs.default_filter end
    if type(filter) == 'string' then filter = {filter} end
    -- Process the given filter into something that can match files more easily
    -- and/or quickly. For example, convert '.ext' shorthand to '%.ext$',
    -- substitute '/' with '[/\\]', and enable hash lookup for file extensions
    -- to include or exclude.
    local processed_filter = {
      consider_any = true,
      exts = setmetatable({}, {__index = function() return true end})
    }
    for _, patt in ipairs(filter) do
      patt = patt:gsub('^(!?)%%?%.([^.]+)$', '%1%%.%2$') -- '.lua' to '%.lua$'
      patt = patt:gsub('/([^\\])', '[/\\]%1') -- '/' to '[/\\]'
      local include = not patt:find('^!')
      local ext = patt:match('^!?%%.([^.]+)%$$')
      if ext then
        processed_filter.exts[ext] = include
        if include then setmetatable(processed_filter.exts, nil) end
      else
        if include then processed_filter.consider_any = false end
        processed_filter[#processed_filter + 1] = patt
      end
    end
    filter = processed_filter
  end
  for basename in lfs.dir(dir) do
    if basename:find('^%.%.?$') then goto continue end -- ignore . and ..
    local filename = dir .. (dir ~= '/' and '/' or '') .. basename
    local mode = lfs.attributes(filename, 'mode')
    if mode ~= 'directory' and mode ~= 'file' then goto continue end
    local include
    if mode == 'file' then
      local ext = filename:match('[^.]+$')
      if ext and not filter.exts[ext] then goto continue end
      include = filter.consider_any or ext ~= nil
    elseif mode == 'directory' then
      include = filter.consider_any
    end
    for _, patt in ipairs(filter) do
      -- Treat exclusive patterns as logical AND.
      if patt:find('^!') and filename:find(patt:sub(2)) then goto continue end
      -- Treat inclusive patterns as logical OR.
      include = include or (not patt:find('^!') and filename:find(patt))
    end
    local sep = not WIN32 and '/' or '\\'
    local os_filename = not WIN32 and filename or filename:gsub('/', sep)
    if include and mode == 'directory' then
      if include_dirs and f(os_filename .. sep) == false then return false end
      if n and (level or 0) >= n then goto continue end
      local halt = lfs.dir_foreach(
        filename, f, filter, n, include_dirs, (level or 0) + 1) == false
      if halt then return false end
    elseif include and mode == 'file' then
      if f(os_filename) == false then return false end
    end
    ::continue::
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
  assert_type(filename, 'string', 1)
  assert_type(prefix, 'string/nil', 2)
  if WIN32 then filename = filename:gsub('/', '\\') end
  if not filename:find(not WIN32 and '^/' or '^%a:[/\\]') and
     not (WIN32 and filename:find('^\\\\')) then
    if not prefix then prefix = lfs.currentdir() end
    filename = prefix .. (not WIN32 and '/' or '\\') .. filename
  end
  filename = filename:gsub('%f[^/\\]%.[/\\]', '') -- clean up './'
  while filename:find('[^/\\]+[/\\]%.%.[/\\]') do
    filename = filename:gsub('[^/\\]+[/\\]%.%.[/\\]', '', 1) -- clean up '../'
  end
  return filename
end

-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

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
  --[[Temporary backwards-compatibility]]extensions={'a','bmp','bz2','class','dll','exe','gif','gz','jar','jpeg','jpg','o','pdf','png','so','tar','tgz','tif','tiff','xz','zip'},folders={'%.bzr$','%.git$','%.hg$','%.svn$','node_modules'}
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
  if not level then
    -- Convert filter to a table from nil or string arguments.
    if not filter then filter = lfs.default_filter end
    if type(filter) == 'string' then filter = {filter} end
    --[[Temporary backwards-compatibility.]]if filter.extensions and filter~=lfs.default_filter then;local compat_filter={};ui.dialogs.textbox{title='Compatibility Notice',informative_text='Warning: use of deprecated filter format; please update your scripts',text=debug.traceback()};for i=1,#filter do if filter[i]:find('^!')then compat_filter[i]=filter[i]:sub(2)else compat_filter[i]='!'..filter[i]end end;for i=1,#filter.extensions do compat_filter[#compat_filter+1]='!.'..filter.extensions[i]end;if filter.folders then for i=1,#filter.folders do; compat_filter[#compat_filter+1]='!'..filter.folders[i]:gsub('^%%.[^.]+%$$','[/\\]%0')end end;filter = compat_filter;end
    -- Process the given filter into something that can match files more easily
    -- and/or quickly. For example, convert '.ext' shorthand to '%.ext$',
    -- substitute '/' with '[/\\]', and enable hash lookup for file extensions
    -- to include or exclude.
    local processed_filter = {consider_any = true, exts = {}}
    for i = 1, #filter do
      local patt = filter[i]
      patt = patt:gsub('^(!?)%%?%.([^.]+)$', '%1%%.%2$') -- '.lua' to '%.lua$'
      patt = patt:gsub('/([^\\])', '[/\\]%1') -- '/' to '[/\\]'
      local include = not patt:find('^!')
      if include then processed_filter.consider_any = false end
      local ext = patt:match('^!?%%.([^.]+)%$$')
      if ext then
        processed_filter.exts[ext] = include and 'include' or 'exclude'
        if include and not getmetatable(processed_filter.exts) then
          -- Exclude any extensions not manually specified.
          setmetatable(processed_filter.exts,
                       {__index = function() return 'exclude' end})
        end
      else
        processed_filter[#processed_filter + 1] = patt
      end
    end
    filter = processed_filter
  end
  local dir_sep, lfs_attributes = not WIN32 and '/' or '\\', lfs.attributes
  for basename in lfs.dir(dir) do
    if not basename:find('^%.%.?$') then -- ignore . and ..
      local filename = dir..(dir ~= '/' and dir_sep or '')..basename
      local mode = lfs_attributes(filename, 'mode')
      if mode ~= 'directory' and mode ~= 'file' then goto skip end
      local include
      if mode == 'file' then
        local ext = filename:match('[^.]+$')
        if ext and filter.exts[ext] == 'exclude' then goto skip end
        include = filter.consider_any or ext and filter.exts[ext] == 'include'
      elseif mode == 'directory' then
        include = filter.consider_any or #filter == 0
      end
      for i = 1, #filter do
        local patt = filter[i]
        -- Treat exclusive patterns as logical AND.
        if patt:find('^!') and filename:find(patt:sub(2)) then goto skip end
        -- Treat inclusive patterns as logical OR.
        include = include or (not patt:find('^!') and filename:find(patt))
      end
      if include and mode == 'directory' then
        if include_dirs and f(filename..dir_sep) == false then return end
        if not n or (level or 0) < n then
          local halt = lfs.dir_foreach(filename, f, filter, n, include_dirs,
                                       (level or 0) + 1) == false
          if halt then return false end
        end
      elseif include and mode == 'file' then
        if f(filename) == false then return false end
      end
      ::skip::
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

-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Extends the `lfs` library to find files in directories and determine absolute file paths.
-- @module lfs

--- The filter table containing common binary file extensions and version control directories
-- to exclude when iterating over files and directories using `lfs.walk`.
-- Extensions excluded: a, bmp, bz2, class, dll, exe, gif, gz, jar, jpeg, jpg, o, pdf, png,
-- so, tar, tgz, tif, tiff, xz, and zip.
-- Directories excluded: .bzr, .git, .hg, .svn, _FOSSIL_, and node_modules.
-- @table default_filter

-- LuaFormatter off
lfs.default_filter = {--[[Extensions]]'!.a','!.bmp','!.bz2','!.class','!.dll','!.exe','!.gif','!.gz','!.jar','!.jpeg','!.jpg','!.o','!.pdf','!.png','!.so','!.tar','!.tgz','!.tif','!.tiff','!.xz','!.zip',--[[Directories]]'!/.bzr','!/.git','!/.hg','!/.svn','!/_FOSSIL_','!/node_modules'}
-- LuaFormatter on

--- Documentation is in `lfs.walk()`.
-- @param dir
-- @param filter
-- @param n
-- @param include_dirs
-- @param seen Utility table that holds directories seen. If there is a duplicate, stop walking
--	down that path (it's probably a recursive symlink).
-- @param level Utility value indicating the directory level this function is at.
local function walk(dir, filter, n, include_dirs, seen, level)
	if not seen then seen = {} end
	local sep = not WIN32 and '/' or '\\'
	seen[not WIN32 and dir or dir:gsub('/', sep)] = true
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
		if not include then goto continue end
		local os_filename = not WIN32 and filename or filename:gsub('/', sep)
		if mode == 'file' then
			coroutine.yield(os_filename)
		elseif mode == 'directory' then
			local link = lfs.symlinkattributes(filename, 'target')
			if link and seen[lfs.abspath(link .. sep, dir):gsub('[/\\]+$', '')] then goto continue end
			if include_dirs then coroutine.yield(os_filename .. sep) end
			if n and (level or 0) >= n then goto continue end
			walk(filename, filter, n, include_dirs, seen, (level or 0) + 1)
		end
		::continue::
	end
end

--- Returns an iterator that iterates over all files and sub-directories (up to *n* levels deep)
-- in directory *dir* and yields each file found.
-- String or list *filter* determines which files to yield, with the default filter being
-- `lfs.default_filter`. A filter consists of glob patterns that match file and directory paths to
-- include or exclude. Exclusive patterns begin with a '!'. If no inclusive patterns are given,
-- any path is initially considered. As a convenience, '/' also matches the Windows directory
-- separator ('[/\\]' is not needed).
-- @param dir The directory path to iterate over.
-- @param[opt=lfs.default_filter] filter Optional filter for files and directories to include
--	and exclude.
-- @param[optchain] n Optional maximum number of directory levels to descend into. The default
--	is to have no limit.
-- @param[optchain=false] include_dirs Optional flag indicating whether or not to yield directory
--	names too.  Directory names are passed with a trailing '/' or '\', depending on the
--	current platform.
function lfs.walk(dir, filter, n, include_dirs)
	dir = assert_type(dir, 'string', 1):match('^(..-)[/\\]?$')
	if not assert_type(filter, 'string/table/nil', 2) then filter = lfs.default_filter end
	assert_type(n, 'number/nil', 3)
	-- Process the given filter into something that can match files more easily and/or quickly. For
	-- example, convert '.ext' shorthand to '%.ext$', substitute '/' with '[/\\]', and enable
	-- hash lookup for file extensions to include or exclude.
	local processed_filter = {
		consider_any = true, exts = setmetatable({}, {__index = function() return true end})
	}
	for _, patt in ipairs(type(filter) == 'table' and filter or {filter}) do
		patt = patt:gsub('[.+%()-]', '%%%0'):gsub('%?', '.'):gsub('%*', '.-')
		patt = patt:gsub('/([^\\])', '[/\\]%1') -- '/' to '[/\\]'
		local include = not patt:find('^!')
		local ext = patt:match('^!?%%.([^.]+)$')
		if ext then
			processed_filter.exts[ext] = include
			if include then setmetatable(processed_filter.exts, nil) end
		else
			if include then processed_filter.consider_any = false end
			processed_filter[#processed_filter + 1] = patt
		end
	end
	local co = coroutine.create(function() walk(dir, processed_filter, n, include_dirs) end)
	return function() return select(2, coroutine.resume(co)) end
end

--- Returns the absolute path to string *filename*.
-- *prefix* or `lfs.currentdir()` is prepended to a relative filename. The returned path is
-- not guaranteed to exist.
-- @param filename The relative or absolute path to a file.
-- @param[opt] prefix Optional prefix path prepended to a relative filename.
-- @return string absolute path
function lfs.abspath(filename, prefix)
	assert_type(filename, 'string', 1)
	assert_type(prefix, 'string/nil', 2)
	if WIN32 then filename = filename:gsub('/', '\\'):gsub('^%l:[/\\]', string.upper) end
	if not filename:find(not WIN32 and '^/' or '^%a:[/\\]') and not (WIN32 and filename:find('^\\\\')) then
		if not prefix then prefix = lfs.currentdir() end
		filename = prefix .. (not WIN32 and '/' or '\\') .. filename
	end
	filename = filename:gsub('%f[^/\\]%.[/\\]', '') -- clean up './'
	while filename:find('[^/\\]+[/\\]%.%.[/\\]') do
		filename = filename:gsub('[^/\\]+[/\\]%.%.[/\\]', '', 1) -- clean up '../'
	end
	return filename
end

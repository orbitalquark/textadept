-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Extends the `lfs` library to find files in directories and determine absolute file paths.
--
-- ### Filters
--
-- The `lfs.walk()` function accepts a filter that specifies which files and directories the
-- returned iterator should yield. A filter is a shell-style glob string or table of such
-- strings with the following syntax:
-- - `/`: directory separator (Windows will expand this to match '\\' too).
-- - `*`: matches any part of a single file or directory name.
-- - `?`: matches any character in a file or directory name.
-- - `[...]`: matches any character in the set; may be a range like `[0-9]`.
-- - `[!...]` or `[^...]`: matches any character not in the set; may be a range like `[^0-9]`.
-- - `{...}`: matches any one of the comma-separated items in the group.
-- - `**`: matches any number of directories, including no directory.
-- - `!glob`: rejects a matched glob. The `!` must be the first character.
--
-- For example:
-- ```lua
-- '*.lua' -- match all Lua files in the top-level directory
-- '**/*.lua' -- match all Lua files in any directory
-- {'**/*.{c,h}', '!build'} -- match all C source files except in the top-level build/ directory
-- {'include/*', 'src/*'} -- match all immediate children of the 'include/' and 'src/' dirs
-- {'include/**', 'src/**'} -- match everything in 'include/' and 'src/', including subdirectories
-- ```
-- @module lfs

--- A filter for including or excluding files and directories in `lfs.walk()`.
-- @field include Table of patterns this filter accepts.
-- @field exclude Table of patterns this filter rejects.
-- @field recurse Whether or not to recurse through directories. This is `true` for filters
--	with only exclusive patterns and for filters with at least one inclusive pattern with a
--	'**' glob.
local filter_object = {}
filter_object.__index = filter_object

--- Returns a new filter for a set of shell-style globs.
-- @param globs Table of glob strings or a single string glob.
-- @local
function filter_object.new(globs)
	return setmetatable({include = {}, exclude = {}, recurse = true}, filter_object) .. globs
end

--- Adds a glob to this filter.
-- The glob is transformed into a Lua pattern.
-- @param glob String glob to add.
-- @local
function filter_object:add(glob)
	if glob == '' then return end
	if glob:find('{') then
		-- Break up groups into separate globs and add them individually.
		local globs = {''}
		local suffix, n = glob:gsub('(.-)(%b{})', function(prefix, group_text)
			for i = 1, #globs do globs[i] = globs[i] .. prefix end
			local n, group = #globs, {}
			for item in group_text:sub(2, -2):gmatch('[^,]+') do group[#group + 1] = item end
			for i = 1, n do for _ = 1, #group - 1 do globs[#globs + 1] = globs[i] end end -- copy
			for i = 1, #group do
				for j = n * (i - 1) + 1, n * i do globs[j] = globs[j] .. group[i] end -- add each item
			end
			return ''
		end)
		if n > 0 then for _, glob_prefix in ipairs(globs) do self:add(glob_prefix .. suffix) end end
		return
	end

	glob = glob:gsub('[/\\]$', '') -- strip trailing slash, as it will interfere with a dir match
	glob = glob:gsub('/([^\\])', '[/\\]%1') -- convert '/' to OS-agnostic '[/\\]'
	glob = glob:gsub('[.+()-]', '%%%0') -- escape special Lua pattern chars
	glob = glob:gsub('?', '.') -- match any character
	glob = glob:gsub('%[!', '[^') -- allow '[!set]' sets
	glob = glob:gsub('%*%*', '.-') -- match any number of directories
	glob = glob:gsub('%*', '[^/\\]*') -- match any path part
	glob = glob:gsub('^!?', '%0^') .. '$' -- anchor for exact matches

	local include, recurse = not glob:find('^!'), glob:find('^^%.%-')
	if include and (recurse or #self.include == 0) then self.recurse = recurse end
	table.insert(include and self.include or self.exclude, include and glob or glob:sub(2))
end

--- Helper function that returns whether or not a pattern matches a filename.
-- @param filename String filename to match against.
-- @param patt String pattern to match with.
local function matches(filename, patt)
	if filename:find(patt) then return true end
	-- If the pattern is a '**/' glob and the filename is not in a subdirectory, try matching
	-- without the '**/' prefix (i.e. match no directory).
	local _, e = patt:find('^.-[/\\]', 1, true)
	return e and not filename:find('[/\\]') and filename:find(patt:sub(e + 1))
end

--- Returns whether or not a filename matches this filter.
-- @param filename String filename to match.
-- @param is_directory Whether or not the filename is a directory.
-- @local
function filter_object:match(filename, is_directory)
	for _, patt in ipairs(self.exclude) do if matches(filename, patt) then return false end end
	if is_directory and self.recurse then return true end -- exclusive filter or '**' globs exist
	for _, patt in ipairs(self.include) do
		if matches(filename, patt) then return true end
		if not is_directory or not patt:find('[^-]%[/\\%][^$]') then goto continue end
		-- Recursion is not enabled, but this included pattern contains subdirectories.
		-- As long as this directory is a parent of the included subdirectory, consider it a match.
		-- For example, 'subdir/subdir2/*.txt' should match 'subdir/' and 'subdir/subdir2/' so that
		-- '*.txt' ultimately has a chance to match.
		local parent_dir = ''
		for part, sep in patt:gmatch('(.-)(%[/\\%])') do
			if filename:find(parent_dir .. part .. '$') then return true end
			parent_dir = parent_dir .. part .. sep
		end
		::continue::
	end
	return #self.include == 0 and not is_directory -- exclusive filter or no '**' globs exist
end

--- Appends another filter's globs with this filter's.
-- @param other Filter whose globs to add.
-- @return this filter
-- @local
function filter_object:__concat(other)
	for _, glob in ipairs(type(other) == 'table' and other or {other}) do self:add(glob) end
	return self
end

--- The default filter table used when iterating over files and directories using `lfs.walk()`.
-- - File extensions excluded: a, bmp, bz2, class, dll, exe, gif, gz, jar, jpeg, jpg, o, pdf,
--	png, so, tar, tgz, tif, tiff, xz, and zip.
-- - Directories excluded: .bzr, .git, .hg, .svn, \_FOSSIL\_, and node_modules.
-- @table default_filter

-- LuaFormatter off
lfs.default_filter = {--[[Extensions]]'!**/*.{a,bmp,bz2,class,dll,exe,gif,gz,jar,jpeg,jpg,o,pdf,png,so,tar,tgz,tif,tiff,xz,zip}',--[[Directories]]'!**/{.bzr,.git,.hg,.svn,_FOSSIL_,node_modules}'}
-- LuaFormatter on

--- Documentation is in `lfs.walk()`.
-- @param dir
-- @param filter
-- @param n
-- @param include_dirs
-- @param root Utility string that holds the original directory passed to `lfs.walk()`.
-- @param seen Utility table that holds directories seen. If there is a duplicate, stop walking
--	down that path (it is probably a recursive symlink).
-- @param level Utility value indicating the directory level this function is at.
local function walk(dir, filter, n, include_dirs, root, seen, level)
	if not root then root = dir:gsub('[/\\]+$', '') end
	if not seen then seen = {} end
	local sep = not WIN32 and '/' or '\\'
	seen[not WIN32 and dir or dir:gsub('/', sep)] = true
	for basename in lfs.dir(dir) do
		if basename:find('^%.%.?$') then goto continue end -- ignore . and ..
		local filename = dir .. (dir ~= '/' and '/' or '') .. basename
		local mode = lfs.attributes(filename, 'mode')
		if mode ~= 'directory' and mode ~= 'file' then goto continue end -- ignore non-dirs, non-files
		local relative = filename:sub(#root + 2)
		if not filter:match(relative, mode == 'directory') then goto continue end -- ignore filtered out
		local os_filename = not WIN32 and filename or filename:gsub('/', sep)
		if mode == 'file' then
			coroutine.yield(os_filename)
		elseif mode == 'directory' then
			local link = lfs.symlinkattributes(filename, 'target')
			if link and seen[lfs.abspath(link .. sep, dir):gsub('[/\\]+$', '')] then goto continue end
			if include_dirs then coroutine.yield(os_filename .. sep) end
			if n and (level or 0) >= n then goto continue end -- too deep
			walk(filename, filter, n, include_dirs, root, seen, (level or 0) + 1)
		end
		::continue::
	end
end

--- Returns an iterator that iterates over all files in a directory and its sub-directories.
-- @param dir String directory path to iterate over.
-- @param[opt=lfs.default_filter] filter [Filter](#filters) that specifies the files and
--	directories the iterator should yield. It is a shell-style glob string or table of such
--	glob strings. If *filter* is not `nil`, it will be combined with `lfs.default_filter`.
-- @param[optchain] n Maximum number of directory levels to descend into. The default
--	is to have no limit.
-- @param[optchain=false] include_dirs Include directory names in iterator results. Directory
--	names will have a trailing '/' or '\\' (depending on the current platform) to distinguish
--	them from regular files.
-- @usage for filename in lfs.walk(buffer.filename:match('^.+[/\\]')) do ... end
function lfs.walk(dir, filter, n, include_dirs)
	assert(lfs.attributes(assert_type(dir, 'string', 1), 'mode') == 'directory',
		'directory not found: %s', dir)
	filter = filter_object.new(assert_type(filter, 'string/table/nil', 2) or {}) .. lfs.default_filter
	assert_type(n, 'number/nil', 3)
	local co = coroutine.create(walk)
	return function() return select(2, coroutine.resume(co, dir, filter, n, include_dirs)) end
end

--- Returns the absolute path to a filename.
-- The returned path is not guaranteed to exist.
-- @param filename String path to a file.
-- @param[opt] prefix String prefix path prepended to a relative filename. The default
--	value is Textadept's current working directory.
function lfs.abspath(filename, prefix)
	assert_type(filename, 'string', 1)
	if WIN32 then filename = filename:gsub('/', '\\'):gsub('^%l:[/\\]', string.upper) end
	if not filename:find(not WIN32 and '^/' or '^%a:[/\\]') and not (WIN32 and filename:find('^\\\\')) then
		if not assert_type(prefix, 'string/nil', 2) then prefix = lfs.currentdir() end
		filename = prefix .. (not WIN32 and '/' or '\\') .. filename
	end
	filename = filename:gsub('%f[^/\\]%.[/\\]', '') -- clean up './'
	local n
	repeat filename, n = filename:gsub('[^/\\]+[/\\]%.%.[/\\]', '', 1) until n == 0 -- clean up '../'
	return filename
end

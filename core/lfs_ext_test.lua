-- Copyright 2020-2026 Mitchell. See LICENSE.

test('lfs.walk should walk a directory tree', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files, dirs = {}, {}

	for filename in lfs.walk(dir.dirname, nil, nil, true) do
		if not filename:find('[/\\]$') then
			files[#files + 1] = filename
		else
			dirs[#dirs + 1] = filename
		end
	end

	table.sort(files)
	test.assert_equal(files, {dir / file, dir / (subdir .. '/' .. subfile)})
	test.assert_equal(dirs, {dir / (subdir .. '/')})
end)

test('lfs.walk should allow filters to include files by extension', function()
	local lua_file = 'file.lua'
	local non_lua_file = 'file.luadoc'
	local subdir = 'subdir'
	local sub_lua_file = 'subfile.lua'
	local dir<close> = test.tmpdir{lua_file, non_lua_file, [subdir] = {sub_lua_file}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '**/*.lua') do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files, {dir / lua_file, dir / (subdir .. '/' .. sub_lua_file)})
end)

test('lfs.walk should not recurse for a filter with non-recursive includes', function()
	local non_lua_file = 'file.luadoc'
	local subdir = 'subdir'
	local lua_file = 'file.lua'
	local dir<close> = test.tmpdir{non_lua_file, [subdir] = {lua_file}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '*.lua') do files[#files + 1] = filename end

	test.assert_equal(files, {})
end)

test('lfs.walk should not recurse for a *', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '*', nil, true) do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files, {dir / file, dir / subdir .. (not WIN32 and '/' or '\\')})
end)

test('lfs.walk should recurse as long as one glob starts with "**"', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, {'**/*.txt', 'nodir/*'}) do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files, {dir / file, dir / (subdir .. '/' .. subfile)})
end)

test('lfs.walk should allow filters to match a group', function()
	local h_file, c_file = 'lib.h', 'lib.c'
	local subdir = 'src'
	local dir<close> = test.tmpdir{[subdir] = {h_file, c_file}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '**/*.{c,h}') do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files, {dir / (subdir .. '/' .. c_file), dir / (subdir .. '/' .. h_file)})
end)

test('lfs.walk should allow filters to match multiple groups', function()
	local h_int_file, h_float_file = 'lib_int.h', 'lib_float.h'
	local c_int_file, c_float_file = 'lib_int.c', 'lib_float.c'
	local dir<close> = test.tmpdir{h_int_file, h_float_file, c_int_file, c_float_file}
	local files = {}

	for filename in lfs.walk(dir.dirname, 'lib_{int,float}.{c,h}') do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files,
		{dir / c_float_file, dir / h_float_file, dir / c_int_file, dir / h_int_file})
end)

test('lfs.walk should allow filters to exclude files by extension', function()
	local lua_file = 'file.lua'
	local subdir = 'subdir'
	local lua_subfile = 'subfile.lua'
	local non_lua_subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{lua_file, [subdir] = {lua_subfile, non_lua_subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '!**/*.lua') do files[#files + 1] = filename end

	test.assert_equal(files, {dir / (subdir .. '/' .. non_lua_subfile)})
end)

test('lfs.walk should allow filters to include files in subdirectories', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, subdir .. '/*.txt') do files[#files + 1] = filename end

	table.sort(files)
	test.assert_equal(files, {dir / (subdir .. '/' .. subfile)})
end)

test('lfs.walk should allow filters to include files in nested subdirectories', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local subdir2 = 'subdir2'
	local subfile2 = 'subfile2.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile, [subdir2] = {subfile2}}}
	local files = {}

	for filename in lfs.walk(dir.dirname, subdir .. '/' .. subdir2 .. '/*.txt') do
		files[#files + 1] = filename
	end

	table.sort(files)
	test.assert_equal(files, {dir / (subdir .. '/' .. subdir2 .. '/' .. subfile2)})
end)

test('lfs.walk should allow mixed filters', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, {'!' .. subdir, '*.txt'}) do files[#files + 1] = filename end

	test.assert_equal(files, {dir / file})
end)

test('lfs.walk should have a default filter', function()
	local file = 'file.so'
	local subdir = '.hg'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname) do files[#files + 1] = filename end

	test.assert_equal(files, {})
end)

test('lfs.walk should stop after reaching a maximum depth', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile = 'subfile.txt'
	local dir<close> = test.tmpdir{file, [subdir] = {subfile}}
	local files = {}

	for filename in lfs.walk(dir.dirname, '*.txt', 0) do files[#files + 1] = filename end

	test.assert_equal(files, {dir / file})
end)

test('lfs.walk should be able to walk from the root directory', function()
	local filename = lfs.walk(not WIN32 and '/' or 'C:\\', nil, 0, true)()

	test.assert(not filename:find('lfs_ext.lua:'), 'should not error')
end)

test('lfs.walk should be able to handle directory symlinks, even recursive ones', function()
	-- `lfs.walk()` should be able to handle symlinks, even recursive ones.
	-- dir/
	-- 	foo
	-- 	bar -> .
	-- 	baz/
	-- 		quux/
	-- 			foobar -> ../../baz
	local dir<close> = test.tmpdir({'foo', baz = {quux = {}}}, true)
	lfs.chdir(dir.dirname)
	lfs.link('.', 'bar', true)
	lfs.chdir(dir / '/baz/quux')
	lfs.link('../../baz', 'foobar', true)
	local files = {}

	for filename in lfs.walk(dir.dirname) do files[#files + 1] = filename end

	test.assert_equal(files, {dir / 'foo'})
end)
if WIN32 then skip('symlinks are not supported') end

test('lfs.walk should be able to handle symlinks to parent dirs, even recursive ones', function()
	-- `lfs.walk()` should be able to handle symlinks, even recursive ones.
	-- dir/
	-- 	1/
	-- 		foo
	-- 		bar/
	-- 			baz
	-- 			quux -> ../../1
	-- 		2 -> ../2
	-- 	2/
	-- 		foobar
	-- 		foobaz -> foobar
	local dir<close> = test.tmpdir{['1'] = {'foo', bar = {'baz'}}, ['2'] = {'foobar'}}
	assert(lfs.link(dir / '1', dir / '1/bar/quux', true))
	assert(lfs.link(dir / '2/foobar', dir / '2/foobaz', true))
	assert(lfs.link(dir / '2', dir / '1/2', true))
	local files = {}

	for filename in lfs.walk(dir / '1') do files[#files + 1] = filename end

	table.sort(files)
	local expected_files = {dir / '1/foo', dir / '1/bar/baz', dir / '1/2/foobar', dir / '1/2/foobaz'}
	table.sort(expected_files)
	test.assert_equal(files, expected_files)
end)
if WIN32 then skip('symlinks are not supported') end

test('lfs.walk should raise an error if the directory does not exist', function()
	local dir_does_not_exist = function() lfs.walk('does-not-exist') end

	test.assert_raises(dir_does_not_exist, 'directory not found: does-not-exist')
end)

test('lfs.abspath should produce paths relative to the current working directory', function()
	local dir<close> = test.tmpdir(true)
	local subdir = 'subdir'

	local path = lfs.abspath(subdir)

	test.assert_equal(path, dir / subdir)
end)

test('lfs.abspath should produce paths relative to a given prefix', function()
	local dir<close> = test.tmpdir()
	local subdir = 'subdir'

	local path = lfs.abspath(subdir, dir.dirname)

	test.assert_equal(path, dir / subdir)
end)

test('lfs.abspath should resolve ./', function()
	local dir<close> = test.tmpdir()
	local subdir = 'subdir'

	local path = lfs.abspath('./' .. subdir .. '/./', dir.dirname)

	test.assert_equal(path, dir / (subdir .. '/'))
end)

test('lfs.abspath should resolve ../', function()
	local dir<close> = test.tmpdir()
	local subdir = 'subdir'

	local path = lfs.abspath(subdir .. '/../' .. subdir .. '/../', dir.dirname)

	test.assert_equal(path, dir.dirname .. (not WIN32 and '/' or '\\'))
end)

test('lfs.abspath should canonicalize paths on Windows', function()
	local _<close> = test.mock(_G, 'WIN32', true)
	local drive = 'c:'
	local subdir = 'subdir'
	local file = 'file.txt'

	local path = lfs.abspath(drive .. '/' .. subdir .. '/' .. file)

	test.assert_equal(path, drive:upper() .. '\\' .. subdir .. '\\' .. file)
end)

test('lfs.abspath should not produce relative paths to Windows shared drives', function()
	local _<close> = test.mock(_G, 'WIN32', true)
	local shared_dir = '\\\\shared\\dir'

	local path = lfs.abspath(shared_dir)

	test.assert_equal(path, shared_dir)
end)

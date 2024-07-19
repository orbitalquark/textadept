-- Copyright 2020-2024 Mitchell. See LICENSE.

test('lfs.walk api should raise errors for invalid arguments and types', function()
	local no_dir_given = function() lfs.walk() end
	local invalid_filter = function() lfs.walk(_HOME, 1) end
	local dir_does_not_exist = function() lfs.walk('does-not-exist') end
	local invalid_depth = function() lfs.walk(_HOME, nil, true) end

	test.assert_raises(no_dir_given, 'string expected')
	test.assert_raises(invalid_filter, 'string/table/nil expected')
	test.assert_raises(dir_does_not_exist, 'directory not found: does-not-exist')
	test.assert_raises(invalid_depth, 'number/nil expected')
end)

test('lfs.walk should walk a basic directory tree', function()
	local dir, _<close> = test.tempdir{'file.txt', subdir = {'subfile.txt'}}

	local files, dirs = {}, {}
	for filename in lfs.walk(dir, nil, nil, true) do
		if not filename:find('[/\\]$') then
			files[#files + 1] = filename
		else
			dirs[#dirs + 1] = filename
		end
	end
	table.sort(files)

	test.assert_equal(files, {test.file(dir .. '/file.txt'), test.file(dir .. '/subdir/subfile.txt')})
	test.assert_equal(dirs, {test.file(dir .. '/subdir/')})
end)

test('lfs.walk should not include extra slashes in paths', function()
	local dir, _<close> = test.tempdir{'file.txt'}

	local files = {}
	for filename in lfs.walk(dir .. '/') do files[#files + 1] = filename end

	test.assert_equal(files, {test.file(dir .. '/file.txt')})
end)

test('lfs.walk should include files by extension', function()
	local dir, _<close> = test.tempdir{'file.luadoc', subdir = {'file.lua'}}

	local files = {}
	for filename in lfs.walk(dir, '.lua') do files[#files + 1] = filename end

	test.assert_equal(files, {test.file(dir .. '/subdir/file.lua')})
end)

test('lfs.walk should exclude files by extension', function()
	local dir, _<close> = test.tempdir{'file.lua', subdir = {'subfile.lua', 'subfile.txt'}}

	local files = {}
	for filename in lfs.walk(dir, '!.lua') do files[#files + 1] = filename end

	test.assert_equal(files, {test.file(dir .. '/subdir/subfile.txt')})
end)

test('lfs.walk should include directories', function()
	local dir, _<close> = test.tempdir{'file.txt', subdir = {'subfile.txt'}}

	local files = {}
	for filename in lfs.walk(dir, '/subdir') do files[#files + 1] = filename end
	table.sort(files)

	test.assert_equal(files, {test.file(dir .. '/subdir/subfile.txt')})
end)
expected_failure()

test('lfs.walk should handle mixed filters', function()
	local dir, _<close> = test.tempdir{'file.txt', subdir = {'subfile.txt'}}

	local files = {}
	for filename in lfs.walk(dir, {'!/subdir', '.txt'}) do files[#files + 1] = filename end

	test.assert_equal(files, {test.file(dir .. '/file.txt')})
end)

test('lfs.walk should stop after reaching a maximum depth', function()
	local dir, _<close> = test.tempdir{'file.txt', subdir = {'subfile.txt'}}

	local files = {}
	for filename in lfs.walk(dir, '.txt', 0) do files[#files + 1] = filename end

	test.assert_equal(files, {test.file(dir .. '/file.txt')})
end)

test('lfs.walk should be able to handle directory symlinks, even recursive ones', function()
	if not WIN32 then return end -- not supported
	-- `lfs.walk()` should be able to handle symlinks, even recursive ones.
	-- dir/
	-- 	foo
	-- 	bar -> .
	-- 	baz/
	-- 		quux/
	-- 			foobar -> ../../baz
	local dir, _<close> = test.tempdir{'foo', baz = {quux = {}}}
	local cwd = lfs.currentdir()
	local _<close> = defer(function() lfs.chdir(cwd) end)
	lfs.chdir(dir)
	lfs.link('.', 'bar', true)
	lfs.chdir(dir .. '/baz/quux')
	lfs.link('../../baz', 'foobar', true)

	local files = {}
	for filename in lfs.walk(dir) do files[#files + 1] = filename end

	test.assert_equal(files, {dir .. '/foo'})
end)

test('lfs.walk should be able to handle symlinks to parent dirs, even recursive ones', function()
	if WIN32 then return end -- not supported
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
	local dir, _<close> = test.tempdir{['1'] = {'foo', bar = {'baz'}}, ['2'] = {'foobar'}}
	assert(lfs.link(dir .. '/1', dir .. '/1/bar/quux', true))
	assert(lfs.link(dir .. '/2/foobar', dir .. '/2/foobaz', true))
	assert(lfs.link(dir .. '/2', dir .. '/1/2', true))

	local files = {}
	for filename in lfs.walk(dir .. '/1') do files[#files + 1] = filename end
	table.sort(files)

	local expected_files = {
		dir .. '/1/foo', dir .. '/1/bar/baz', dir .. '/1/2/foobar', dir .. '/1/2/foobaz'
	}
	table.sort(expected_files)
	test.assert_equal(files, expected_files)
end)

test('lfs.walk should be able to from the root directory', function()
	local filename = lfs.walk(not WIN32 and '/' or 'C:\\', nil, 0, true)()

	test.assert(not filename:find('lfs_ext.lua:'), 'should not error')
end)

test('lfs.abspath api should raise an error for invalid argument types', function()
	local no_path_given = function() lfs.abspath() end
	local invalid_prefix = function() lfs.abspath('foo', 1) end

	test.assert_raises(no_path_given, 'string expected')
	test.assert_raises(invalid_prefix, 'string/nil expected')
end)

test('lfs.abspath should not produce relative paths for absolute paths', function()
	local dir, _<close> = test.tempdir(nil, true)
	local root = dir
	repeat root = root:gsub('[^/\\]+$', '') until not root:find('[^/\\]$')

	local path = lfs.abspath(root)

	test.assert_equal(path, root)
end)

test('lfs.abspath should produce paths relative to the current working directory', function()
	local dir, _<close> = test.tempdir(nil, true)

	local path = lfs.abspath('subdir')

	test.assert_equal(path, test.file(dir .. '/subdir'))
end)

test('lfs.abspath should produce paths relative to a prefix', function()
	local dir, _<close> = test.tempdir()

	local path = lfs.abspath('subdir', dir)

	test.assert_equal(path, test.file(dir .. '/subdir'))
end)

test('lfs.abspath should resolve ./', function()
	local dir, _<close> = test.tempdir()

	local path = lfs.abspath(test.file('./subdir/./'), dir)

	test.assert_equal(path, test.file(dir .. '/subdir/'))
end)

test('lfs.abspath should resolve ../', function()
	local dir, _<close> = test.tempdir()

	local path = lfs.abspath(test.file('subdir/../subdir/../'), dir)

	test.assert_equal(path, test.file(dir .. '/'))
end)

test('lfs.abspath should capitalize Windows drive letters', function()
	local _<close> = test.mock(_G, 'WIN32', true)

	local path = lfs.abspath('c:\\')

	test.assert_equal(path, 'C:\\')
end)

test('lfs.abspath should not produce relative paths to Windows shared drives', function()
	local _<close> = test.mock(_G, 'WIN32', true)
	local shared_dir = '\\\\shared\\dir'

	local path = lfs.abspath(shared_dir)

	test.assert_equal(path, shared_dir)
end)

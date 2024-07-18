-- Copyright 2020-2024 Mitchell. See LICENSE.

test('assert_equal should assert two values are equal', function()
	local equal = pcall(test.assert_equal, 'foo', 'foo')

	test.assert_equal(equal, true)
end)

test('assert_equal should assert two tables are equal', function()
	local equal = pcall(test.assert_equal, {1, 2, 3}, {1, 2, 3})

	test.assert_equal(equal, true)
end)

test('assert_equal should assert two values are not equal', function()
	local failed_assertion = function() test.assert_equal('foo', 1) end

	test.assert_raises(failed_assertion, 'foo ~= 1')
end)

test('assert_equal should assert that two tables are not equal', function()
	local failed_assertion = function() test.assert_equal({1, 2, 3}, {1, 2}) end

	test.assert_raises(failed_assertion, '{1, 2, 3} ~= {1, 2}')
end)

test('assert_raises should catch an error', function()
	local errmsg = 'error!'
	local raises_error = function() error(errmsg) end

	local caught = pcall(test.assert_raises, raises_error, errmsg)

	test.assert_equal(caught, true)
end)

test('assert_raises should error if it did not catch an error', function()
	local no_error = function() end

	local silent, errmsg = pcall(test.assert_raises, no_error)

	test.assert_equal(silent, false)
	test.assert(errmsg:find('error expected'), 'should have errored with "error expected"')
end)

test('stub should be uncalled at first', function()
	local f = test.stub()

	test.assert_equal(f.called, false)
	test.assert_equal(f.args, nil)
end)

test('stub should know if it has been called', function()
	local f = test.stub()

	f()

	test.assert_equal(f.called, true)
end)

test('stub should record the arguments it was called with', function()
	local f = test.stub()
	local args = {'arg', 1}

	f(table.unpack(args))

	test.assert_equal(f.args, args)
end)

test('stub should call its callback when called', function()
	local callback = test.stub()
	local f = test.stub(callback)

	f()

	test.assert_equal(callback.called, true)
end)

test('stub should return the values it was initialized with', function()
	local return_values = {true, false}
	local f = test.stub(table.unpack(return_values))

	local result = {f()}

	test.assert_equal(result, return_values)
end)

test('stub should track the number of times it has been called', function()
	local f = test.stub()

	f()
	f()

	test.assert_equal(f.called, 2)
end)

test('stub should reset its tracking data', function()
	local f = test.stub()
	local arg = 'arg'

	f(arg)
	f:reset()

	test.assert_equal(f.called, false)
	test.assert_equal(f.args, nil)
end)

test('defer should invoke its function when it goes out of scope', function()
	local f = test.stub()

	do local _<close> = test.defer(f) end

	test.assert_equal(f.called, true)
end)

test('tempfile should create a temporary file and defer deleting it', function()
	local filename, created

	do
		local f, _<close> = test.tempfile()
		filename = f
		created = lfs.attributes(filename, 'mode') == 'file'
	end
	local still_exists = lfs.attributes(filename) ~= nil

	test.assert_equal(created, true)
	test.assert_equal(still_exists, false)
end)

test('tempdir should create a temporary directory and defer deleting it', function()
	local dir
	local created = {}

	do
		local d, _<close> = test.tempdir{'file.txt', subdir = {'subfile.txt'}}
		dir = d
		created[dir] = lfs.attributes(dir, 'mode') == 'directory'
		created['file.txt'] = lfs.attributes(dir .. '/file.txt', 'mode') == 'file'
		created['subdir'] = lfs.attributes(dir .. '/subdir', 'mode') == 'directory'
		created['subfile.txt'] = lfs.attributes(dir .. '/subdir/subfile.txt', 'mode') == 'file'
	end
	local still_exists = lfs.attributes(dir) ~= nil

	test.assert_equal(created[dir], true)
	test.assert_equal(created['file.txt'], true)
	test.assert_equal(created['subdir'], true)
	test.assert_equal(created['subfile.txt'], true)
	test.assert_equal(still_exists, false)
end)

test('tempdir should allow changing to it', function()
	local cwd = lfs.currentdir()
	local changed_dir

	do
		local dir, _<close> = test.tempdir({}, true)
		changed_dir = lfs.currentdir() == dir
	end

	test.assert_equal(changed_dir, true)
	test.assert_equal(lfs.currentdir(), cwd)
end)

test('connect should connect to an event and defer disconnecting it', function()
	local event = 'test_deferred_disconnect'
	local f = test.stub()

	do local _<close> = test.connect(event, f) end
	events.emit(event)

	test.assert_equal(f.called, false)
end)

test('mock api should raise errors for invalid argument types', function()
	local invalid_module = function() test.mock(print) end
	local invalid_name = function() test.mock(string, 1) end
	local valid_mock = test.stub('chunk')
	local invalid_conditional = function() test.mock(string, 'dump', true, valid_mock) end

	test.assert_raises(invalid_module, 'table expected')
	test.assert_raises(invalid_name, 'string expected')
	test.assert_raises(invalid_conditional, 'function expected')
end)

test('mock should change a module field', function()
	local module = {field = true}
	local field

	do
		local _<close> = test.mock(module, 'field', false)
		field = module.field
	end

	test.assert_equal(field, false)
	test.assert_equal(module.field, true)
end)

test('mock should replace a module function', function()
	local module = {}
	function module.name() return 'unmocked' end
	local mock = function() return 'mocked' end
	local mock_result

	do
		local _<close> = test.mock(module, 'name', mock)
		mock_result = module.name()
	end
	local unmocked_result = module.name()

	test.assert_equal(mock_result, 'mocked')
	test.assert_equal(unmocked_result, 'unmocked')
end)

test('mock should allow conditionally mocking a module function', function()
	local module = {['unmocked key'] = 'unmocked value'}
	function module.name(key) return module[key] end
	local conditional = function(value) return value == 'mock key' end
	local mock = test.stub('mocked value')

	local _<close> = test.mock(module, 'name', conditional, mock)
	local mocked_results = {module.name('mock key')}
	local unmocked_results = {module.name('unmocked key')}

	test.assert_equal(mocked_results, {'mocked value'})
	test.assert_equal(mock.args, {'mock key'})
	test.assert_equal(unmocked_results, {'unmocked value'})
end)

test('wait should return when a condition succeeds', function()
	local f = test.stub()
	local function condition()
		if f.called then return f.called end
		f()
	end

	local result = test.wait(condition)

	test.assert_equal(result, true)
end)

test('wait should timeout if a condition fails for long enough', function()
	local noop = function() end
	local timeout = 0.1
	local loop = function() test.wait(noop, timeout) end

	test.assert_raises(loop, 'timed out waiting')
end)

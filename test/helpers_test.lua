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
	local assertion = function() test.assert_equal('foo', 1) end
	test.assert_raises(assertion, 'foo ~= 1')
end)

test('assert_equal should assert that two tables are not equal', function()
	local assertion = function() test.assert_equal({1, 2, 3}, {1, 2}) end
	test.assert_raises(assertion, '{1, 2, 3} ~= {1, 2}')
end)

test('assert_raises should catch an error', function()
	local errorf = function() error('foo') end
	local caught = pcall(test.assert_raises, errorf, 'foo')
	test.assert_equal(caught, true)
end)

test('assert_raises should error if it did not catch an error', function()
	local non_errorf = function() end
	local silent, errmsg = pcall(test.assert_raises, non_errorf)
	test.assert_equal(silent, false)
	test.assert(errmsg:find('error expected'), 'should have errored with "error expected"')
end)

test('stub should track whether or not it has been called', function()
	local f = test.stub()
	test.assert_equal(f.called, false)
	f()
	test.assert_equal(f.called, true)
end)

test('stub should record the arguments it was called with', function()
	local f = test.stub()
	f('foo', 1)
	test.assert_equal(f.args, {'foo', 1})
end)

test('stub should return the value it was initialized with', function()
	local f = test.stub(true)
	local result = f()
	test.assert_equal(result, true)
end)

test('stub should track the number of times it has been called', function()
	local f = test.stub()
	f()
	f()
	test.assert_equal(f.called, 2)
end)

test('stub should reset its tracking data', function()
	local f = test.stub()
	f('foo')
	f:reset()
	test.assert_equal(f.called, false)
	test.assert_equal(f.args, nil)
end)

test('defer should invoke its function when it goes out of scope', function()
	local f = test.stub()
	do
		local _<close> = test.defer(f)
		test.assert_equal(f.called, false)
	end
	test.assert_equal(f.called, true)
end)

test('defer should still invoke its function if an error occurs', function()
	local f = test.stub()
	pcall(function()
		local _<close> = test.defer(f)
		error()
	end)
	test.assert_equal(f.called, true)
end)

test('tempfile should create a temporary file and defer deleting it', function()
	local filename
	do
		local f, _<close> = test.tempfile()
		filename = f
		test.assert_equal(lfs.attributes(filename, 'mode'), 'file')
	end
	test.assert_equal(not lfs.attributes(filename), true)
end)

test('tempdir should create a temporary directory and defer deleting it', function()
	local dir
	do
		local d, _<close> = test.tempdir{foo = {'bar.txt'}, 'baz'}
		dir = d
		test.assert_equal(lfs.attributes(dir, 'mode'), 'directory')
		test.assert_equal(lfs.attributes(dir .. '/foo', 'mode'), 'directory')
		test.assert_equal(lfs.attributes(dir .. '/foo/bar.txt', 'mode'), 'file')
		test.assert_equal(lfs.attributes(dir .. '/baz', 'mode'), 'file')
	end
	test.assert(not lfs.attributes(dir), 'should have deleted directory')
end)

test('connect should connect to an event and defer disconnecting it', function()
	local event = 'test_deferred_disconnect'
	local f = test.stub()
	do
		local _<close> = test.connect(event, f)
		events.emit(event)
		test.assert_equal(f.called, true)
	end
	events.emit(event)
	test.assert_equal(f.called, true)
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
	local fail = function() end
	local timeout = 0.1
	test.assert_raises(function() test.wait(fail, timeout) end, 'timed out waiting')
end)

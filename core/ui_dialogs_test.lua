-- Copyright 2020-2024 Mitchell. See LICENSE.

test('ui.dialogs.message should prompt with a message', function()
	local click_ok = test.stub(1)

	local _<close> = test.mock(ui.dialogs, 'message', click_ok)
	local button = ui.dialogs.message{
		title = 'Title', text = 'text', icon = 'dialog-information', button1 = 'Button 1',
		button2 = 'Button 2', button3 = 'Button 3'
	}

	test.assert_equal(button, 1)
end)

test('ui.dialogs should prompt for input', function()
	local input_text = test.stub('input')

	local _<close> = test.mock(ui.dialogs, 'input', input_text)
	local input = ui.dialogs.input{title = 'Title', text = 'input'}

	test.assert_equal(input, 'input')
end)

test('ui.dialogs should prompt for input and optionally return the button clicked', function()
	local input_text_and_click_ok = test.stub('input', 1)

	local _<close> = test.mock(ui.dialogs, 'input', input_text_and_click_ok)
	local input, button = ui.dialogs.input{title = 'Title', text = 'input', return_button = true}

	test.assert_equal(input, 'input')
	test.assert_equal(button, 1)
end)

test('ui.dialogs.open should prompt for a file to open', function()
	local filename, _<close> = test.tempfile()
	local test_dir, test_file = filename:match('^(.+[/\\])([^/\\]+)$')

	local select_filename = test.stub({filename})
	local _<close> = test.mock(ui.dialogs, 'open', select_filename)
	local filenames = ui.dialogs.open{dir = test_dir, file = test_file, multiple = true}

	test.assert_equal(filenames, {filename})
end)

test('ui.dialogs.open should allow prompting for a directory to open', function()
	if CURSES then return end -- not supported by CDK
	local dir, _<close> = test.tempdir()

	local select_directory = test.stub(dir)
	local _<close> = test.mock(ui.dialogs, 'open', select_directory)
	local directory = ui.dialogs.open{dir = test_dir, only_dirs = true}

	test.assert_equal(directory, dir)
end)

test('ui.dialots.save should prompt for a file to save', function()
	local filename, _<close> = test.tempfile()

	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	local selected_filename = ui.dialogs.save{dir = test_dir, file = test_file}

	test.assert_equal(selected_filename, filename)
end)

test('ui.dialogs.progress should raise errors for invalid arguments', function()
	local no_work_function = function() ui.dialogs.progress{} end

	test.assert_raises(no_work_function, "'work' function expected")
end)

test('ui.dialogs.progress should show progress for work done', function()
	local i = 0
	local stopped = ui.dialogs.progress{
		title = 'Title', work = function()
			-- test.sleep(0.1)
			i = i + 10
			if i > 100 then return nil end
			return i, i .. '%'
		end
	}

	test.assert_equal(not stopped, true)
end)

test('ui.dialogs.progress should allow for cancelling work', function()
	local stop = test.stub(true)
	local _<close> = test.mock(ui.dialogs, 'progress', stop)
	local stopped = ui.dialogs.progress{
		title = 'Title', work = function()
			test.sleep(0.1)
			return 50
		end
	}

	test.assert_equal(stopped, true)
end)

test('ui.dialogs.progress should emit errors when work errors', function()
	local event = test.stub(false) -- halt propagation to default error handler
	local _<close> = test.connect(events.ERROR, event, 1)

	local error_message = 'error!'
	local raises_error = function() error(error_message) end
	local stopped = ui.dialogs.progress{work = raises_error}

	test.assert_equal(not stopped, true) -- user did not click stop
	test.assert_equal(event.called, true)
	test.assert(event.args[1]:find(error_message), 'should have included error message')
end)

test('ui.dialogs.list should raise errors for invalid arguments', function()
	local no_items = function() ui.dialogs.list{} end
	local invalid_search_column = function() ui.dialogs.list{search_column = 2} end

	test.assert_raises(no_items, "non-empty 'items' table expected")
	test.assert_raises(invalid_search_column, "invalid 'search_column'")
end)

test('ui.dialogs.list should prompt for a selection from a list', function()
	local select_item = test.stub(2, 1)
	local _<close> = test.mock(ui.dialogs, 'list', select_item)
	local i = ui.dialogs.list{title = 'Title', items = {'foo', 'bar', 'baz'}, text = 'b z'}

	test.assert_equal(i, 2)
end)

test('ui.dialogs.list should optionally prompt for multiple selections from a list', function()
	local select_item = test.stub({2}, 1)
	local _<close> = test.mock(ui.dialogs, 'list', select_item)
	local i, button = ui.dialogs.list{
		columns = {'1', '2'}, items = {'foo', 'foobar', 'bar', 'barbaz', 'baz', 'bazfoo'},
		search_column = 2, text = 'baz', multiple = true, button1 = _L['OK'], button2 = _L['Cancel'],
		button3 = 'Other', return_button = true
	}

	test.assert_equal(i, {2})
	test.assert_equal(button, 1)
end)

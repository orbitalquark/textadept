-- Copyright 2020-2024 Mitchell. See LICENSE.

test('session.save should raise errors for invalid arguments', function()
	local invalid_filename = function() textadept.session.save(true) end

	test.assert_raises(invalid_filename, 'string/nil expected')
end)

test('session.save should save to a given session file', function()
	local filename, _<close> = test.tempfile()
	os.remove(filename) -- should not exist yet

	textadept.session.save(filename)

	test.assert(lfs.attributes(filename), 'should have saved session')
end)

test('session.save should prompt for a session file if none was given', function()
	local filename, _<close> = test.tempfile()
	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)

	textadept.session.save()

	test.assert_equal(select_filename.called, true)
end)

test('session.load should prompt for a session file if none was given', function()
	local cancel = test.stub(nil)
	local _<close> = test.mock(ui.dialogs, 'open', cancel)

	textadept.session.load()

	test.assert_equal(cancel.called, true)
end)

test('sessions should save userdata', function()
	local session, _<close> = test.tempfile()
	local save_userdata = function(session)
		session.key = 'value'
		session.invalid = function() end
	end
	local _<close> = test.connect(events.SESSION_SAVE, save_userdata)
	local loaded_key, loaded_invalid
	local load_userdata = function(session)
		loaded_key = session.key
		loaded_invalid = session.invalid
	end
	local _<close> = test.connect(events.SESSION_LOAD, load_userdata)

	textadept.session.save(session)
	textadept.session.load(session)

	test.assert_equal(loaded_key, 'value')
	test.assert_equal(loaded_invalid, nil)
end)

test('sessions should save the current working directory', function()
	local session, _<close> = test.tempfile()

	local dir1, _<close> = test.tempdir(nil, true)
	textadept.session.save(session)

	local dir2, _<close> = test.tempdir(nil, true)
	textadept.session.load(session)

	test.assert_equal(lfs.currentdir(), dir1)
end)

test('sessions should save open buffers and their states', function()
	local session, _<close> = test.tempfile()
	local filename, _<close> = test.tempfile()
	local newline = test.newline()
	local f = io.open(filename, 'wb')
	for i = 1, 100 do f:write(i .. newline) end
	f:close()
	io.open_file(filename)
	buffer:goto_line(50)
	textadept.editing.select_line()
	local selected_text = buffer:get_sel_text()
	local first_visible_line = view.first_visible_line

	textadept.session.save(session)
	buffer:close()
	textadept.session.load(session)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(buffer:get_sel_text(), selected_text)
	test.assert_equal(view.first_visible_line, first_visible_line)
end)

test('sessions should save bookmarks', function()
	local session, _<close> = test.tempfile()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	textadept.bookmarks.toggle()

	textadept.session.save(session)
	buffer:close()
	textadept.session.load(session)

	test.assert(buffer:marker_get(1) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0,
		'should have saved bookmark')
end)

test('sessions should save window state', function()
	local session, _<close> = test.tempfile()
	local _<close> = test.mock(ui, 'maximized', true)

	textadept.session.save(session)
	ui.maximized = not ui.maximized
	textadept.session.load(session)

	test.assert_equal(ui.maximized, true)
end)

test('sessions should save window size', function()
	if CURSES then return end -- not applicable
	local session, _<close> = test.tempfile()
	local size = {400, 300}
	local _<close> = test.mock(ui, 'size', size)

	textadept.session.save(session)
	ui.size = {size[1] + 100, size[2] + 100}
	textadept.session.load(session)

	test.assert_equal(ui.size, size)
end)

test('sessions should save view state', function()
	local session, _<close> = test.tempfile()
	view:split()
	view:split(true)
	local view1_size = _VIEWS[1].size
	local view2_size = _VIEWS[2].size

	textadept.session.save(session)
	while view:unsplit() do end
	textadept.session.load(session)

	test.assert_equal(#_VIEWS, 3)
	test.assert_equal(_VIEWS[1].size, view1_size)
	test.assert_equal(_VIEWS[2].size, view2_size)
end)

test('sessions should save recent files', function()
	local session, _<close> = test.tempfile()
	local _<close> = test.mock(io, 'recent_files', {})
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:close()

	textadept.session.save(session)
	io.recent_files = {}
	textadept.session.load(session)

	test.assert_equal(io.recent_files, {filename})
end)

test('sessions should save typed buffers', function()
	local session, _<close> = test.tempfile()
	ui.print()

	textadept.session.save(session)
	buffer:close()
	textadept.session.load(session)

	test.assert_equal(buffer._type, _L['[Message Buffer]'])
end)

-- TODO: loading a new session will save the current session under the previous session name.
-- This leaves a temporary file on disk.
test('session.load should not load if there are unsaved files and the user cancels #skip',
	function()
		local session, _<close> = test.tempfile()
		local cancel = test.stub(2)
		local _<close> = test.mock(ui.dialogs, 'message', cancel)
		buffer:append_text('modified')

		textadept.session.load(session)

		test.assert_equal(buffer:get_text(), 'modified')
	end)

test('session.load should notify of non-existent session files', function()
	local session, _<close> = test.tempfile()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	textadept.session.save(session)
	buffer:close()
	os.remove(filename)

	local non_existent_message = test.stub()
	local _<close> = test.mock(ui.dialogs, 'message', non_existent_message)

	textadept.session.load(session)

	test.assert_equal(non_existent_message.called, true)
	test.assert(non_existent_message.args[1].text:find(filename, 1, true),
		'should have listed non-existent filename')
end)

test('--session should load the given session', function()
	local session, _<close> = test.tempfile()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	textadept.session.save(session)
	buffer:close()

	events.emit('command_line', {'--session', session}) -- simulate

	test.assert_equal(buffer.filename, filename)
end)

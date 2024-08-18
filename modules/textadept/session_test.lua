-- Copyright 2020-2024 Mitchell. See LICENSE.

test('session.save should save to a given session file', function()
	local sf<close> = test.tmpfile()
	sf:delete() -- should not exist yet

	textadept.session.save(sf.filename)

	local file_exists = lfs.attributes(sf.filename, 'mode') == 'file'
	test.assert(file_exists, 'should have saved session')
end)

test('session.save should prompt for a session file if none was given', function()
	local cancel_save = test.stub()
	local _<close> = test.mock(ui.dialogs, 'save', cancel_save)

	textadept.session.save()

	test.assert_equal(cancel_save.called, true)
end)

test('session.load should prompt for a session file if none was given', function()
	local cancel_load = test.stub(nil)
	local _<close> = test.mock(ui.dialogs, 'open', cancel_load)

	textadept.session.load()

	test.assert_equal(cancel_load.called, true)
end)

test('sessions should save userdata', function()
	local sf<close> = test.tmpfile()
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

	textadept.session.save(sf.filename)
	textadept.session.load(sf.filename)

	test.assert_equal(loaded_key, 'value')
	test.assert_equal(loaded_invalid, nil)
end)

test('sessions should save the current working directory', function()
	local sf<close> = test.tmpfile()
	local dir<close> = test.tmpdir(true)

	textadept.session.save(sf.filename)
	local _<close> = test.tmpdir(true) -- change to another directory
	textadept.session.load(sf.filename)

	test.assert_equal(lfs.currentdir(), dir.dirname)
end)

test('sessions should save open buffers and their states', function()
	local sf<close> = test.tmpfile()
	local f<close> = test.tmpfile(test.lines(100), true)
	buffer:goto_line(50)
	textadept.editing.select_line()
	local selected_text = buffer:get_sel_text()
	local first_visible_line = view.first_visible_line

	textadept.session.save(sf.filename)
	buffer:close()
	textadept.session.load(sf.filename)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer:get_sel_text(), selected_text)
	test.assert_equal(view.first_visible_line, first_visible_line)
end)

test('sessions should save bookmarks', function()
	local sf<close> = test.tmpfile()
	local _<close> = test.tmpfile(true)
	textadept.bookmarks.toggle()

	textadept.session.save(sf.filename)
	buffer:close()
	textadept.session.load(sf.filename)

	local has_bookmark = buffer:marker_get(1) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
	test.assert(has_bookmark, 'should have saved bookmark')
end)

test('sessions should save window state', function()
	local sf<close> = test.tmpfile()
	local _<close> = test.mock(ui, 'maximized', true)

	textadept.session.save(sf.filename)
	ui.maximized = not ui.maximized
	textadept.session.load(sf.filename)

	test.assert_equal(ui.maximized, true)
end)
if GTK then expected_failure() end -- TODO:
if CURSES then skip('window state cannot be changed') end

test('sessions should save window size', function()
	local sf<close> = test.tmpfile()
	local size = {800, 600}
	local _<close> = test.mock(ui, 'size', size)

	textadept.session.save(sf.filename)
	ui.size = {size[1] + 100, size[2] + 100}
	textadept.session.load(sf.filename)

	test.assert_equal(ui.size, size)
end)
if GTK then expected_failure() end -- TODO:
if CURSES then skip('window size cannot be changed') end

test('sessions should save view state', function()
	local sf<close> = test.tmpfile()
	view:split()
	view:split(true)
	local view1_size = _VIEWS[1].size
	local view2_size = _VIEWS[2].size

	textadept.session.save(sf.filename)
	while view:unsplit() do end
	textadept.session.load(sf.filename)

	test.assert_equal(#_VIEWS, 3)
	test.assert_equal(_VIEWS[1].size, view1_size)
	test.assert_equal(_VIEWS[2].size, view2_size)
end)

test('sessions should save recent files', function()
	local sf<close> = test.tmpfile()
	local _<close> = test.mock(io, 'recent_files', {})
	local f<close> = test.tmpfile(true)
	buffer:close()

	textadept.session.save(sf.filename)
	io.recent_files = {}
	textadept.session.load(sf.filename)

	test.assert_equal(io.recent_files, {f.filename})
end)

test('sessions should save typed buffers', function()
	local sf<close> = test.tmpfile()
	ui.output()

	textadept.session.save(sf.filename)
	buffer:close()
	textadept.session.load(sf.filename)

	test.assert_equal(buffer._type, _L['[Output Buffer]'])
end)

-- TODO: loading a new session will save the current session under the previous session name.
-- This leaves a temporary file on disk.
test('session.load should not load if there are unsaved files and the user cancels #skip',
	function()
		local sf<close> = test.tmpfile()
		local cancel = test.stub(2)
		local _<close> = test.mock(ui.dialogs, 'message', cancel)
		buffer:append_text('modified')

		textadept.session.load(sf.filename)

		test.assert_equal(buffer:get_text(), 'modified')
	end)

test('session.load should notify of non-existent session files', function()
	local sf<close> = test.tmpfile()
	local f<close> = test.tmpfile(true)
	textadept.session.save(sf.filename)
	buffer:close()
	f:delete()

	local non_existent_message = test.stub()
	local _<close> = test.mock(ui.dialogs, 'message', non_existent_message)

	textadept.session.load(sf.filename)

	test.assert_equal(non_existent_message.called, true)
	local dialog_opts = non_existent_message.args[1]
	test.assert_contains(dialog_opts.text, f.filename)
end)

test('--session should load the given session', function()
	local sf<close> = test.tmpfile()
	local f<close> = test.tmpfile(true)
	textadept.session.save(sf.filename)
	buffer:close()

	events.emit('command_line', {'--session', sf.filename}) -- simulate

	test.assert_equal(buffer.filename, f.filename)
end)

-- Copyright 2020-2026 Mitchell. See LICENSE.

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

test('sessions should save folded line state', function()
	local sf<close> = test.tmpfile()
	local _<close> = test.tmpfile('.lua', test.lines{
		'-- Comment', --
		'for i = 1, 3 do', --
		'\tprint(i)', --
		'end'
	}, true)
	buffer:colorize(1, -1)
	buffer:toggle_fold(2)

	textadept.session.save(sf.filename)
	buffer:close()
	textadept.session.load(sf.filename)

	test.assert_equal(2, view:contracted_fold_next(1))
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
if GTK then expected_failure() end
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
if GTK then expected_failure() end
if CURSES then skip('window size cannot be changed') end

test('sessions should save view state', function()
	local sf<close> = test.tmpfile()
	view:split()
	view:split(true)
	local view1_split_pos = _VIEWS[1].split_pos
	local view2_split_pos = _VIEWS[2].split_pos

	textadept.session.save(sf.filename)
	while view:unsplit() do end
	textadept.session.load(sf.filename)

	test.assert_equal(#_VIEWS, 3)
	test.assert_equal(_VIEWS[1].split_pos, view1_split_pos)
	test.assert_equal(_VIEWS[2].split_pos, view2_split_pos)
end)

test('sessions should restore the view states of files opened in more than one view', function()
	local sf<close> = test.tmpfile()
	local _<close> = test.tmpfile(test.lines(50), true)
	buffer:line_down_extend()
	local selection1 = buffer:get_sel_text()
	view:split(true)
	buffer:goto_line(50)
	buffer:line_down_extend()
	local selection2 = buffer:get_sel_text()

	textadept.session.save(sf.filename)
	while view:unsplit() do end
	textadept.session.load(sf.filename)

	test.assert_equal(buffer:get_sel_text(), selection2)
	ui.goto_view(-1)
	test.assert_equal(buffer:get_sel_text(), selection1)
end)
expected_failure() -- TODO:

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

test('session.load should not load if there are unsaved files and the user cancels', function()
	local sf<close> = test.tmpfile()
	local cancel = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'message', cancel)
	buffer:append_text('modified')
	-- Note: loading a new session will save the current session under the previous session name.
	-- Prevent this from leaving a temporary file on disk.
	local function ignore_saving_current_session() end
	local _<close> = test.mock(textadept.session, 'save', ignore_saving_current_session)

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

test('session.load should ignore non-existant recent files', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local sf<close> = test.tmpfile()
	local f<close> = test.tmpfile(true)
	buffer:close()
	textadept.session.save(sf.filename)
	f:delete()

	textadept.session.load(sf.filename)

	test.assert_equal(io.recent_files, {})
end)

test('--session should load the given session', function()
	local sf<close> = test.tmpfile()
	local f<close> = test.tmpfile(true)
	textadept.session.save(sf.filename)
	buffer:close()

	events.emit('command_line', {'--session', sf.filename}) -- simulate

	test.assert_equal(buffer.filename, f.filename)
end)

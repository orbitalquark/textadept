-- Copyright 2020-2024 Mitchell. See LICENSE.

test('io.open_file api should raise an error for an invalid argument type', function()
	local invalid_filename = function() io.open_file(1) end

	test.assert_raises(invalid_filename, 'string/table/nil expected')
end)

test('io.open_file should open a file and set it up for editing', function()
	local filename, _<close> = test.tempfile()
	io.open(filename, 'wb'):write('text'):close()

	io.open_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(buffer:get_text(), 'text')
	test.assert_equal(buffer.modify, false)
	test.assert_equal(buffer.lexer_language, 'text')
end)

test('io.open_file should prompt for a file to open if none was given', function()
	local filename, _<close> = test.tempfile()

	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'open', select_filename)
	io.open_file()

	test.assert_equal(buffer.filename, filename)
end)

test('io.open_file should emit a file opened event', function()
	local filename, _<close> = test.tempfile()
	local event = test.stub()

	local _<close> = test.connect(events.FILE_OPENED, event)
	io.open_file(filename)

	test.assert_equal(event.called, true)
	test.assert_equal(event.args, {filename})
end)

test('io.open_file should switch to an already open file instead of opening a new copy', function()
	local filename, _<close> = test.tempfile()

	io.open_file(filename)
	buffer.new()
	local num_buffers = #_BUFFERS
	io.open_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(#_BUFFERS, num_buffers)
end)

test('io.open_file should raise an error if it cannot open or read a file', function()
	if LINUX then
		local cannot_open = function() io.open_file('/etc/gshadow-') end

		test.assert_raises(cannot_open, 'cannot open /etc/gshadow-: Permission denied')
	end
	-- TODO: find a case where the file can be opened, but not read
end)

for file, encoding in pairs{utf8 = 'UTF-8', cp1252 = 'CP1252', utf16 = 'UTF-16', binary = 'binary'} do
	test('io.open_file should detect encoding: ' .. encoding, function()
		local filename = _HOME .. '/test/file_io/' .. file
		test.log(string.format('opening file: %s', filename))
		local f<close> = io.open(filename, 'rb')
		local contents = f:read('a')

		io.open_file(filename)

		if encoding ~= 'binary' then
			test.assert_equal(buffer:get_text():iconv(encoding, 'UTF-8'), contents)
			test.assert_equal(buffer.encoding, encoding)
			test.assert_equal(buffer.code_page, buffer.CP_UTF8)
		else
			test.assert_equal(buffer:get_text(), contents)
			test.assert_equal(buffer.encoding, nil)
			test.assert_equal(buffer.code_page, 0)
		end
	end)
end

test('io.open_file should detect tabs and switch indentation from spaces', function()
	local set_indentation_spaces = function() buffer.use_tabs = false end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_spaces) -- temporary

	local _<close> = test.mock(io, 'detect_indentation', true)
	io.open_file(_HOME .. '/test/file_io/tabs')

	test.assert_equal(buffer.use_tabs, true)
end)

test('io.open_file should not detect tabs and should not switch indentation from spaces', function()
	local set_indentation_spaces = function() buffer.use_tabs = false end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_spaces) -- temporary

	local _<close> = test.mock(io, 'detect_indentation', false)
	io.open_file(_HOME .. '/test/file_io/tabs')

	test.assert_equal(buffer.use_tabs, false)
end)

test('io.open_file should detect spaces and switch indentation from tabs', function()
	local set_indentation_tabs = function() buffer.use_tabs, buffer.tab_width = true, 4 end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_tabs) -- temporary

	local _<close> = test.mock(io, 'detect_indentation', true)
	io.open_file(_HOME .. '/test/file_io/spaces')

	test.assert_equal(buffer.use_tabs, false)
	test.assert_equal(buffer.tab_width, 2)
end)

test('io.open_file should not detect spaces and should not switch indentation from tabs', function()
	local set_indentation_tabs = function() buffer.use_tabs, buffer.tab_width = true, 4 end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_tabs) -- temporary

	local _<close> = test.mock(io, 'detect_indentation', false)
	io.open_file(_HOME .. '/test/file_io/spaces')

	test.assert_equal(buffer.use_tabs, true)
	test.assert_equal(buffer.tab_width, 4)
end)

for file, mode in pairs{lf = buffer.EOL_LF, crlf = buffer.EOL_CRLF} do
	test('io.open_file should detect end-of-line (EOL) mode: ' .. file:upper(), function()
		local filename = _HOME .. '/test/file_io/' .. file
		test.log(string.format('opening file: %s', filename))

		io.open_file(filename)

		test.assert_equal(buffer.eol_mode, mode)
	end)
end

test('io.open_file should scroll to the beginning of the file', function()
	local filename1, _<close> = test.tempfile()
	local filename2, _<close> = test.tempfile()
	local f1, f2 = io.open(filename1, 'wb'), io.open(filename2, 'wb')
	for i = 1, 100 do
		f1:write(i, '\n')
		f2:write(i, '\n')
	end
	f1:close()
	f2:close()

	io.open_file(filename1)
	buffer:goto_line(100)
	view.x_offset = 10

	io.open_file(filename2)

	test.assert_equal(view.first_visible_line, 1)
	test.assert_equal(view.x_offset, 0)
end)

test('io.open_file should auto-detect and set the lexer for the file', function()
	local filename, _<close> = test.tempfile('lua')

	io.open_file(filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('io.open_file should keep track of the most recent files open', function()
	local file1, _<close> = test.tempfile('1')
	local file2, _<close> = test.tempfile('2')

	local _<close> = test.mock(io, 'recent_files', {})
	io.open_file(file1)
	io.open_file(file2)

	test.assert_equal(io.recent_files, {file2, file1})
end)

test('io.open_file should not duplicate recently opened files', function()
	local file1, _<close> = test.tempfile('1')
	local file2, _<close> = test.tempfile('2')

	local _<close> = test.mock(io, 'recent_files', {})
	io.open_file(file1)
	buffer:close()
	io.open_file(file2)
	io.open_file(file1)

	test.assert_equal(io.recent_files, {file1, file2})
end)

test('buffer:reload should discard any changes', function()
	io.open_file(_HOME .. '/test/file_io/utf8')
	local text = buffer:get_text()

	buffer:append_text('changed')
	buffer:reload()

	test.assert_equal(buffer:get_text(), text)
	test.assert_equal(buffer.modify, false)
end)

test('buffer:set_encoding api should raise an error for an invalid argument type', function()
	local invalid_encoding = function() buffer:set_encoding(true) end

	test.assert_raises(invalid_encoding, 'string/nil expected')
end)

test('buffer:set_encoding should change from multi- to single-byte and mark the buffer as dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/utf8')
		local text = buffer:get_text()

		buffer:set_encoding('CP1252')

		test.assert_equal(buffer.encoding, 'CP1252')
		test.assert_equal(buffer.code_page, buffer.CP_UTF8)
		test.assert_equal(buffer:get_text(), text) -- fundamentally the same
		test.assert_equal(buffer.modify, true)
	end)

test('buffer:set_encoding should switch between single-byte encodings without marking buffer dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/cp936')
		local initially_detected_cp1252 = buffer.encoding == 'CP1252' -- incorrectly detected
		local text = '中文\n'
		local initially_showed_cp1252 = buffer:get_text() ~= text

		buffer:set_encoding('CP936')

		test.assert_equal(initially_detected_cp1252, true)
		test.assert_equal(initially_showed_cp1252, true)
		test.assert_equal(buffer.encoding, 'CP936')
		test.assert_equal(buffer:get_text(), text)
		test.assert_equal(buffer.modify, false)
	end)

test('buffer:set_encoding should change from single- to multi-byte and mark the buffer as dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/cp1252')
		local text = buffer:get_text()

		buffer:set_encoding('UTF-16')

		test.assert_equal(buffer.encoding, 'UTF-16')
		test.assert_equal(buffer:get_text(), text)
		test.assert_equal(buffer.modify, true)
	end)

test('buffer:save should save the file', function()
	local filename, _<close> = test.tempfile()
	os.remove(filename) -- should not exist yet
	io.open_file(_HOME .. '/test/file_io/utf8')
	buffer.filename = filename -- pretend this was the opened file
	local text = buffer:get_text()

	local saved = buffer:save()
	local f<close> = assert(io.open(filename, 'rb'))
	local contents = f:read('a')

	test.assert_equal(saved, true)
	test.assert_equal(contents, text)
end)

test('buffer:save should mark the file as having no changes', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	buffer:append_text('changed')
	buffer:save()

	test.assert_equal(buffer.modify, false)
end)

test('buffer:save should not ensure a trailing newline', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	local _<close> = test.mock(io, 'ensure_final_newline', false)
	buffer:append_text('text')
	buffer:save()
	local f<close> = io.open(filename, 'rb')
	local file_contents = f:read('a')

	test.assert_equal(buffer:get_text(), 'text')
	test.assert_equal(file_contents, 'text')
end)

test('buffer:save should ensure a trailing newline', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	local _<close> = test.mock(io, 'ensure_final_newline', true)
	buffer:append_text('text')
	buffer:save()
	local f<close> = io.open(filename, 'rb')
	local file_contents = f:read('a')

	test.assert_equal(buffer:get_text(), 'text' .. test.newline())
	test.assert_equal(file_contents, 'text' .. test.newline())
end)

test('buffer:save should emit before and after save events at the right times', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	os.remove(filename) -- delete for tracking before and after events

	local file_exists = {}
	local check_file_exists = function()
		file_exists[#file_exists + 1] = lfs.attributes(filename, 'mode') == 'file'
	end
	local before = test.stub(check_file_exists)
	local after = test.stub(check_file_exists)

	local _<close> = test.connect(events.FILE_BEFORE_SAVE, before)
	local _<close> = test.connect(events.FILE_AFTER_SAVE, after)
	buffer:save()

	test.assert_equal(before.called, true)
	test.assert_equal(before.args, {filename})
	test.assert_equal(after.called, true)
	test.assert_equal(after.args, {filename})
	test.assert_equal(file_exists, {false, true})
end)

test('buffer:save should remove the buffer type once it has a filename', function()
	local filename, _<close> = test.tempfile()
	buffer._type = '[Typed Buffer]'

	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	buffer:save()

	test.assert_equal(buffer._type, nil)
end)

test('buffer:save_as should raise an error for an invalid argument type', function()
	local invalid_filename = function() buffer:save_as(1) end

	test.assert_raises(invalid_filename, 'string/nil expected')
end)

test('buffer:save_as should save the untitled file as a named file', function()
	local filename, _<close> = test.tempfile()
	os.remove(filename) -- should not exist yet

	local saved = buffer:save_as(filename)

	test.assert_equal(saved, true)
	test.assert_equal(buffer.filename, filename)
	test.assert(lfs.attributes(filename, 'mode'), 'file')
end)

test('buffer:save_as should prompt for a file to save to', function()
	local filename, _<close> = test.tempfile()

	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	local saved = buffer:save_as()

	test.assert_equal(saved, true)
end)

test('buffer:save_as should update the lexer', function()
	local filename, _<close> = test.tempfile('lua')

	buffer:save_as(filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('buffer:save_as should emit a distinct after save event', function()
	local filename, _<close> = test.tempfile()
	local event = test.stub()

	local _<close> = test.connect(events.FILE_AFTER_SAVE, event)
	buffer:save_as(filename)

	test.assert_equal(event.called, 2) -- TODO: ideally this would only be called once
	test.assert_equal(event.args, {filename, true})
end)

test('io.save_all_files should save all modified files', function()
	local saved = setmetatable({}, {__index = function() return false end})
	local record_saved = function(filename) saved[filename] = true end
	local _<close> = test.connect(events.FILE_AFTER_SAVE, record_saved)

	local modified_file, _<close> = test.tempfile()
	io.open_file(modified_file)
	buffer:append_text('modified_file')

	local unmodified_file, _<close> = test.tempfile()
	io.open_file(unmodified_file)

	local modified_untitled_buffer = buffer.new()
	buffer:append_text('new')

	local modified_typed_buffer = buffer.new()
	buffer._type = '[Typed Buffer]'
	buffer:append_text('typed')

	local saved_all = io.save_all_files()

	test.assert_equal(saved_all, true)
	test.assert_equal(saved[modified_file], true)
	test.assert_equal(saved[unmodified_file], false)
	test.assert_equal(saved[modified_untitled_buffer], false)
	test.assert_equal(saved[modified_typed_buffer], false)
end)

test('io.save_all_files should switch to untitled buffers and prompt for files to save to',
	function()
		buffer:append_text('save me')

		-- Open another file to verify the untitled buffer is switched to prior to saving.
		local filename, _<close> = test.tempfile()
		io.open_file(filename)

		local switched_to_untitled_buffer = false
		local check_for_untitled = function() switched_to_untitled_buffer = not buffer.filename end
		local _<close> = test.connect(events.BUFFER_AFTER_SWITCH, check_for_untitled)
		local do_not_save = test.stub()
		local _<close> = test.mock(ui.dialogs, 'save', do_not_save)

		io.save_all_files(true)

		test.assert_equal(switched_to_untitled_buffer, true)
	end)

test('buffer:close should close a buffer without changes', function()
	buffer.new()

	local closed = buffer:close()

	test.assert_equal(closed, true)
	test.assert_equal(#_BUFFERS, 1)
end)

test('buffer:close should prompt before closing a modified buffer', function()
	buffer.new():append_text('text')

	local cancel_close = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'message', cancel_close)
	local closed = buffer:close()

	test.assert_equal(not closed, true)
	test.assert_equal(#_BUFFERS, 2)
end)

test('buffer:close should close a modified buffer', function()
	buffer.new():append_text('text')

	local closed = buffer:close(true)

	test.assert_equal(closed, true)
end)

test('detect external file modifications', function()
	local file_changed = test.stub(false) -- halt propagation to default, prompting handler
	local _<close> = test.connect(events.FILE_CHANGED, file_changed, 1)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	-- Mock an external file modification.
	local request_mod_time = function(_, request) return request == 'modification' end
	local return_future_time = test.stub(os.time() + 1)
	local _<close> = test.mock(lfs, 'attributes', request_mod_time, return_future_time)
	buffer.new():close() -- trigger check

	test.assert_equal(file_changed.called, true)
	test.assert_equal(file_changed.args, {filename})
end)

test('prompt to reload files modified externally', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	io.open(filename, 'wb'):write('reloaded'):close()
	buffer.mod_time = buffer.mod_time - 1 -- simulate sleep
	local reload = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'message', reload)
	buffer.new():close() -- trigger check

	test.assert_equal(buffer:get_text(), 'reloaded')
end)

test('io.close_all_buffers should close all unmodified buffers without checking for external mods',
	function()
		local file_changed = test.stub(false) -- prevent propagation to default, prompting handler
		local _<close> = test.connect(events.FILE_CHANGED, file_changed, 1)
		local filename, _<close> = test.tempfile()

		io.open_file(filename)
		buffer.mod_time = buffer.mod_time - 1 -- simulate file modified

		buffer.new()._type = '[Foo Buffer]'

		local closed_all = io.close_all_buffers()

		test.assert_equal(closed_all, true)
		test.assert_equal(file_changed.called, false)
		test.assert_equal(#_BUFFERS, 1)
		test.assert(not buffer.filename and not buffer._type, 'should have closed all buffers')
	end)

test('buffer.reload should use the global buffer', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	io.open(filename, 'wb'):write('text'):close()

	buffer.reload()

	test.assert_equal(buffer:get_text(), 'text')
end)

test('buffer.save should use the global buffer', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	local saved = buffer.save()

	test.assert_equal(saved, true)
end)

test('buffer.save_as should prompt for the global buffer', function()
	local filename, _<close> = test.tempfile()

	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	local saved = buffer.save_as()

	test.assert_equal(saved, true)
end)

test('buffer.close should use the global buffer', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	buffer.close()

	test.assert_equal(#_BUFFERS, 1)
end)

test('io.open_recent_file should prompt for a recently opened file if it still exists', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:close()
	do
		local deleted, _<close> = test.tempfile()
		io.open_file(deleted)
		buffer:close()
	end -- deletes the file

	local select_first_item = test.stub({1}, 1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	io.open_recent_file()

	test.assert_equal(buffer.filename, filename)
end)

test('io.open_recent_file should allow clearing the list during prompt', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:close()

	local clear_recent_files = test.stub({}, 3)
	local _<close> = test.mock(ui.dialogs, 'list', clear_recent_files)

	io.open_recent_file()

	test.assert_equal(io.recent_files, {})
	test.assert_equal(#_BUFFERS, 1)
end)

test('io.get_project_root should raise an error for an invalid argument type', function()
	local invalid_path = function() io.get_project_root(1) end

	test.assert_raises(invalid_path, 'string/nil expected')
end)

test('io.get_project_root should detect the project root directory from the working dir', function()
	local dir, _<close> = test.tempdir({['.hg'] = {}}, true)

	local root = io.get_project_root()

	test.assert_equal(root, dir)
end)

test('io.get_project_root should detect the project root directory from the current file',
	function()
		local dir, _<close> = test.tempdir{['.hg'] = {}, subdir = {'file.txt'}}

		io.open_file(dir .. '/subdir/file.txt')
		local root = io.get_project_root()

		test.assert_equal(root, dir)
	end)

test('io.get_project_root should detect the project root directory from a path', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, subdir = {}}

	local root = io.get_project_root(dir)
	local same_root = io.get_project_root(dir .. '/subdir')

	test.assert_equal(root, dir)
	test.assert_equal(same_root, dir)
end)

test('io.get_project_root should handle not detecting the project root directory', function()
	local dir, _<close> = test.tempdir()

	local root = io.get_project_root(dir)

	test.assert_equal(root, nil)
end)

test('io.get_project_root should consider a submodule directory as the project root directory',
	function()
		local dir, _<close> = test.tempdir{['.git'] = {}, subdir = {'.git', 'file.txt'}}

		io.open_file(dir .. '/subdir/bar.txt')
		local root = io.get_project_root(true)

		test.assert_equal(root, dir .. '/subdir')
	end)

test('io.quick_open should raise errors for invalid argument types', function()
	local invalid_path = function() io.quick_open(1) end
	local invalid_filter = function() io.quick_open({}, true) end

	test.assert_raises(invalid_path, 'string/table/nil expected')
	test.assert_raises(invalid_filter, 'string/table/nil expected')
end)

test('io.quick_open should prompt for a project file to open', function()
	local dir, _<close> = test.tempdir({['.hg'] = {}, 'file.txt'}, true)

	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	io.quick_open()

	test.assert(buffer.filename, 'should have found file to open')
end)

test('io.quick_open should prompt for a file to open from a directory', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt'}

	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	io.quick_open(dir)

	test.assert(buffer.filename, 'should have found file to open')
end)

test('io.quick_open should prompt for a file to open, subject to a filter', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt', subdir = {'file.lua'}}

	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	io.quick_open(dir, '.lua')

	test.assert(buffer.filename:find('%.lua$'), 'should have found lua file to open')
end)

test('io.quick_open should prompt for a file to open, subject to an exclusive filter', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt', subdir = {'file.lua'}}

	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	io.quick_open(dir, {'!.txt'})

	test.assert(buffer.filename:find('%.lua$'), 'should have found lua file to open')
end)

test('io.quick_open should prompt for a file to open, but at a maximum depth', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, 'file.txt', subdir = {'file.lua'}}

	local _<close> = test.mock(io, 'quick_open_max', 1)
	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)
	local max_reached_ok = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'message', max_reached_ok)
	io.quick_open(dir)

	test.assert(buffer.filename, 'should have found file to open')
	test.assert_equal(max_reached_ok.called, true)
end)

test('buffer:close for a hidden buffer should not affect buffers in existing views', function()
	local buffer1 = buffer.new()
	buffer1:append_text('1')
	view:split(true)
	local buffer2 = buffer.new()
	buffer2:append_text('2')
	local buffer3 = buffer.new()
	buffer3:append_text('3')
	view:split()
	local buffer4 = buffer.new()
	buffer4:append_text('4')

	local buffer1_was_visible = _VIEWS[1].buffer == buffer1
	local buffer3_was_visible = _VIEWS[2].buffer == buffer3
	local buffer4_was_visible = _VIEWS[3].buffer == buffer4

	buffer2:close(true)

	test.assert_equal(buffer1_was_visible, true)
	test.assert_equal(buffer3_was_visible, true)
	test.assert_equal(buffer4_was_visible, true)
	test.assert(_VIEWS[1].buffer == buffer1, 'buffer1 should still be visible')
	test.assert(_VIEWS[2].buffer == buffer3, 'buffer3 should still be visible')
	test.assert(_VIEWS[3].buffer == buffer4, 'buffer4 should still be visible')
end)
if not QT then test.expected_failure() end

test('read stdin into a new buffer as a file', function()
	local stdin_provider = test.stub('text')

	local _<close> = test.mock(io, 'read', stdin_provider)
	events.emit('command_line', {'-'}) -- simulate arg

	test.assert_equal(buffer:get_text(), 'text')
	test.assert_equal(buffer.modify, false)
end)

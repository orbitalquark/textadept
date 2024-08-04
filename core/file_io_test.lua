-- Copyright 2020-2024 Mitchell. See LICENSE.

test('io.open_file should raise errors for invalid arguments', function()
	local invalid_filename = function() io.open_file(1) end

	test.assert_raises(invalid_filename, 'string/table/nil expected')
end)

test('io.open_file should open a file and set it up for editing', function()
	local contents = 'text'
	local filename, _<close> = test.tempfile(contents)

	io.open_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(buffer:get_text(), contents)
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

test('io.open_file should emit an event', function()
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

	io.open_file(filename)

	test.assert_equal(buffer.filename, filename)
	test.assert_equal(#_BUFFERS, 2)
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

test('io.open_file should detect and switch to tabs', function()
	local set_indentation_spaces = function() buffer.use_tabs = false end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_spaces) -- temporary

	io.open_file(_HOME .. '/test/file_io/tabs')

	test.assert_equal(buffer.use_tabs, true)
end)

test('io.open_file should not detect and switch to tabs if io.detect_indentation is disabled',
	function()
		local _<close> = test.mock(io, 'detect_indentation', false)
		local set_indentation_spaces = function() buffer.use_tabs = false end
		local _<close> = test.connect(events.BUFFER_NEW, set_indentation_spaces) -- temporary

		io.open_file(_HOME .. '/test/file_io/tabs')

		test.assert_equal(buffer.use_tabs, false)
	end)

test('io.open_file should detect and switch to spaces', function()
	local set_indentation_tabs = function() buffer.use_tabs, buffer.tab_width = true, 4 end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_tabs) -- temporary

	io.open_file(_HOME .. '/test/file_io/spaces')

	test.assert_equal(buffer.use_tabs, false)
	test.assert_equal(buffer.tab_width, 2)
end)

test('io.open_file should not detect and switch to spaces if io.detect_indentation is disabled',
	function()
		local _<close> = test.mock(io, 'detect_indentation', false)
		local set_indentation_tabs = function() buffer.use_tabs, buffer.tab_width = true, 4 end
		local _<close> = test.connect(events.BUFFER_NEW, set_indentation_tabs) -- temporary

		io.open_file(_HOME .. '/test/file_io/spaces')

		test.assert_equal(buffer.use_tabs, true)
		test.assert_equal(buffer.tab_width, 4)
	end)

for file, mode in pairs{lf = buffer.EOL_LF, crlf = buffer.EOL_CRLF} do
	test('io.open_file should detect end-of-line (EOL) mode: ' .. file:upper(), function()
		local filename = _HOME .. '/test/file_io/' .. file

		io.open_file(filename)

		test.assert_equal(buffer.eol_mode, mode)
	end)
end

test('io.open_file should scroll to the beginning of the file', function()
	local contents = string.rep('\n', 100)
	local filename1, _<close> = test.tempfile(contents)
	local filename2, _<close> = test.tempfile(contents)

	io.open_file(filename1)
	buffer:goto_line(100)
	view.x_offset = 10

	io.open_file(filename2)

	test.assert_equal(view.first_visible_line, 1)
	test.assert_equal(view.x_offset, 0)
end)

test("io.open_file should auto-detect and set the file's lexer", function()
	local filename, _<close> = test.tempfile('.lua')

	io.open_file(filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('io.open_file should keep track of the most recently opened files', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local file1, _<close> = test.tempfile('.1')
	local file2, _<close> = test.tempfile('.2')

	io.open_file(file1)
	io.open_file(file2)

	test.assert_equal(io.recent_files, {file2, file1})
end)

test('io.open_file should not duplicate any recently opened files', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local file1, _<close> = test.tempfile('.1')
	local file2, _<close> = test.tempfile('.2')

	io.open_file(file1)
	buffer:close()
	io.open_file(file2)

	io.open_file(file1)

	test.assert_equal(io.recent_files, {file1, file2})
end)

test('buffer:reload should discard any unsaved changes', function()
	io.open_file(_HOME .. '/test/file_io/utf8')
	local file_contents = buffer:get_text()
	buffer:append_text('changed')

	buffer:reload()

	test.assert_equal(buffer:get_text(), file_contents)
	test.assert_equal(buffer.modify, false)
end)

test('buffer:set_encoding should raise errors for invalid arguments', function()
	local invalid_encoding = function() buffer:set_encoding(true) end

	test.assert_raises(invalid_encoding, 'string/nil expected')
end)

test('buffer:set_encoding should handle multi- to single-byte changes and mark the buffer as dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/utf8')
		local file_contents = buffer:get_text()
		local encoding = 'CP1252'

		buffer:set_encoding(encoding)

		test.assert_equal(buffer.encoding, encoding)
		test.assert_equal(buffer.code_page, buffer.CP_UTF8)
		test.assert_equal(buffer:get_text(), file_contents) -- fundamentally the same
		test.assert_equal(buffer.modify, true)
	end)

test('buffer:set_encoding should handle single-byte changes without marking buffer dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/cp936')
		local initially_detected_cp1252 = buffer.encoding == 'CP1252' -- incorrectly detected
		local correct_encoding = 'CP936'
		local correct_contents = '中文\n'
		local initially_showed_cp1252 = buffer:get_text() ~= correct_contents

		buffer:set_encoding(correct_encoding)

		test.assert_equal(initially_detected_cp1252, true)
		test.assert_equal(initially_showed_cp1252, true)
		test.assert_equal(buffer.encoding, correct_encoding)
		test.assert_equal(buffer:get_text(), correct_contents)
		test.assert_equal(buffer.modify, false)
	end)

test('buffer:set_encoding should handle single- to multi-byte changes and mark the buffer as dirty',
	function()
		io.open_file(_HOME .. '/test/file_io/cp1252')
		local text = buffer:get_text()
		local encoding = 'UTF-16'

		buffer:set_encoding(encoding)

		test.assert_equal(buffer.encoding, encoding)
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

	test.assert_equal(saved, true)
	local f<close> = assert(io.open(filename, 'rb'))
	local contents = f:read('a')
	test.assert_equal(contents, text)
end)

test('buffer:save should mark the file as having no changes', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	buffer:append_text('changed')

	buffer:save()

	test.assert_equal(buffer.modify, false)
end)

test('buffer:save should not write a trailing newline if io.ensure_final_newline is disabled',
	function()
		local _<close> = test.mock(io, 'ensure_final_newline', false)
		local filename, _<close> = test.tempfile()
		io.open_file(filename)
		local contents = 'text'
		buffer:append_text(contents)

		buffer:save()

		test.assert_equal(buffer:get_text(), contents)
		local f<close> = io.open(filename, 'rb')
		local file_contents = f:read('a')
		test.assert_equal(file_contents, contents)
	end)

test('buffer:save should write a trailing newline if io.ensure_final_newline is enabled', function()
	local _<close> = test.mock(io, 'ensure_final_newline', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local contents = 'text'
	buffer:append_text(contents)

	buffer:save()

	test.assert_equal(buffer:get_text(), test.lines{contents, ''})
end)

test('buffer:save should never write a trailing newline for binary files', function()
	local _<close> = test.mock(io, 'ensure_final_newline', true)
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local binary_contents = 'binary'
	buffer:append_text(binary_contents)
	buffer.encoding = nil -- pretend it was detected as a binary file

	buffer:save()

	test.assert_equal(buffer:get_text(), binary_contents)
end)

test('buffer:save should emit before and after events', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	os.remove(filename) -- delete for tracking before and after events

	local file_exists = {}
	local check_file_exists = function(filename)
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

test("buffer:save should remove a buffer's type once it has a filename", function()
	local filename, _<close> = test.tempfile()
	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	buffer._type = '[Typed Buffer]'

	buffer:save()

	test.assert_equal(buffer._type, nil)
end)

test('buffer:save_as should raise errors for invalid arguments', function()
	local invalid_filename = function() buffer:save_as(1) end

	test.assert_raises(invalid_filename, 'string/nil expected')
end)

test('buffer:save_as should save with a given filename', function()
	local filename, _<close> = test.tempfile()
	os.remove(filename) -- should not exist yet

	local saved = buffer:save_as(filename)
	local file_exists = lfs.attributes(filename, 'mode') == 'file'

	test.assert_equal(saved, true)
	test.assert_equal(buffer.filename, filename)
	test.assert_equal(file_exists, true)
end)

test('buffer:save_as should prompt for a file to save to if none was given', function()
	local filename, _<close> = test.tempfile()
	local select_filename = test.stub(filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)

	local saved = buffer:save_as()

	test.assert_equal(saved, true)
end)

test('buffer:save_as should update the lexer', function()
	local filename, _<close> = test.tempfile('.lua')

	buffer:save_as(filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('buffer:save_as should emit a distinct event afterwards', function()
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
		buffer:append_text('modified')

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

test('buffer:close should immediately close a buffer without changes', function()
	buffer.new()

	local closed = buffer:close()

	test.assert_equal(closed, true)
	test.assert_equal(#_BUFFERS, 1)
end)

test('buffer:close should prompt before closing a modified buffer', function()
	local cancel_close = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'message', cancel_close)
	buffer.new():append_text('text')

	local closed = buffer:close()

	test.assert_equal(not closed, true)
	test.assert_equal(#_BUFFERS, 2)
end)

test('buffer:close should allow closing a modified buffer without prompting', function()
	buffer.new():append_text('text')

	local closed = buffer:close(true)

	test.assert_equal(closed, true)
end)

test('external file modifications should be detected', function()
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

test('externally modified files should prompt for reload', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)

	local reloaded_contents = 'reloaded'
	io.open(filename, 'wb'):write(reloaded_contents):close()
	buffer.mod_time = buffer.mod_time - 1 -- simulate modification in the past
	local reload = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'message', reload)

	buffer.new():close() -- trigger check

	test.assert_equal(buffer:get_text(), reloaded_contents)
end)

test('io.close_all_buffers should close all unmodified buffers without checking for external mods',
	function()
		local file_changed = test.stub(false) -- prevent propagation to default, prompting handler
		local _<close> = test.connect(events.FILE_CHANGED, file_changed, 1)
		local filename, _<close> = test.tempfile()

		io.open_file(filename)
		buffer.mod_time = buffer.mod_time - 1 -- simulate file modified
		buffer.new()

		local closed_all = io.close_all_buffers()

		test.assert_equal(closed_all, true)
		test.assert_equal(file_changed.called, false)
		test.assert_equal(#_BUFFERS, 1)
		test.assert(not buffer.filename and not buffer._type, 'should have closed all buffers')
	end)

test('buffer.reload should use the global buffer', function()
	local filename, _<close> = test.tempfile()
	io.open_file(filename)
	local contents = 'text'
	io.open(filename, 'wb'):write(contents):close()

	buffer.reload()

	test.assert_equal(buffer:get_text(), contents)
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

	local clear_recent_files = test.stub({1}, 3)
	local _<close> = test.mock(ui.dialogs, 'list', clear_recent_files)

	io.open_recent_file()

	test.assert_equal(io.recent_files, {})
	test.assert_equal(#_BUFFERS, 1)
end)

test('io.get_project_root should raise errors for invalid arguments', function()
	local invalid_path = function() io.get_project_root(1) end

	test.assert_raises(invalid_path, 'string/nil expected')
end)

test('io.get_project_root should detect the project root from the working directory', function()
	local dir, _<close> = test.tempdir({['.hg'] = {}}, true)

	local root = io.get_project_root()

	test.assert_equal(root, dir)
end)

test('io.get_project_root should detect the project root from the current file', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, subdir = {'file.txt'}}
	io.open_file(dir .. '/subdir/file.txt')

	local root = io.get_project_root()

	test.assert_equal(root, dir)
end)

test('io.get_project_root should detect the project root from a given path', function()
	local dir, _<close> = test.tempdir{['.hg'] = {}, subdir = {}}
	local root = io.get_project_root(dir)

	local same_root = io.get_project_root(dir .. '/subdir')

	test.assert_equal(root, dir)
	test.assert_equal(same_root, dir)
end)

test('io.get_project_root should handle not detecting the project root', function()
	local dir, _<close> = test.tempdir()

	local root = io.get_project_root(dir)

	test.assert_equal(root, nil)
end)

test('io.get_project_root should allow a submodule directory to be the project root', function()
	local dir, _<close> = test.tempdir{['.git'] = {}, subdir = {'.git', 'file.txt'}}
	local subdir = dir .. '/subdir'
	io.open_file(subdir .. '/bar.txt')

	local root = io.get_project_root(true)

	test.assert_equal(root, subdir)
end)

test('io.quick_open should raise errors for invalid arguments', function()
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

test('io.quick_open should prompt for a file to open from a given directory', function()
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
	view:split(true)
	local buffer2 = buffer.new()
	local buffer3 = buffer.new()
	view:split()
	local buffer4 = buffer.new()

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
if not QT then expected_failure() end

test('- should read stdin into a new buffer as a file', function()
	local stdin_provider = test.stub('text')
	local _<close> = test.mock(io, 'read', stdin_provider)

	events.emit('command_line', {'-'}) -- simulate arg

	test.assert_equal(buffer:get_text(), 'text')
	test.assert_equal(buffer.modify, false)
end)

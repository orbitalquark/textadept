-- Copyright 2020-2024 Mitchell. See LICENSE.

test('io.open_file should open a file and set it up for editing', function()
	local contents = 'text'
	local f<close> = test.tmpfile(contents)

	io.open_file(f.filename)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer:get_text(), contents)
	test.assert_equal(buffer.modify, false)
	test.assert_equal(buffer:can_undo(), false)
end)

test("io.open_file should auto-detect and set the file's lexer", function()
	local f<close> = test.tmpfile('.lua')

	io.open_file(f.filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('io.open_file should emit events.FILE_OPENED', function()
	local f<close> = test.tmpfile()
	local file_opened = test.stub()
	local _<close> = test.connect(events.FILE_OPENED, file_opened)

	io.open_file(f.filename)

	test.assert_equal(file_opened.called, true)
	test.assert_equal(file_opened.args, {f.filename})
end)

test('io.open_file should open a list of files given', function()
	local f1<close> = test.tmpfile()
	local f2<close> = test.tmpfile()

	io.open_file{f1.filename, f2.filename}

	test.assert_equal(#_BUFFERS, 2)
	test.assert_equal(_BUFFERS[1].filename, f1.filename)
	test.assert_equal(_BUFFERS[2].filename, f2.filename)
end)

test('io.open_file should prompt for a file(s) to open if none was given', function()
	local f<close> = test.tmpfile()
	local select_filename = test.stub(f.filename)
	local _<close> = test.mock(ui.dialogs, 'open', select_filename)

	io.open_file()

	test.assert_equal(select_filename.called, true)
	test.assert_equal(buffer.filename, f.filename)
	local dialog_opts = select_filename.args[1]
	test.assert_contains(dialog_opts, 'multiple')
end)

test("io.open_file should prompt in the current filename's directory", function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{file}
	io.open_file(dir / file)
	local cancel_open = test.stub()
	local _<close> = test.mock(ui.dialogs, 'open', cancel_open)

	io.open_file()

	local dialog_opts = cancel_open.args[1]
	test.assert_equal(dialog_opts.dir, dir.dirname)
end)

test('io.open_file should switch to an already open file instead of opening a new copy', function()
	local f<close> = test.tmpfile()
	io.open_file(f.filename)
	buffer.new()

	io.open_file(f.filename)

	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(#_BUFFERS, 2) -- should not be 3
end)

test('io.open_file should allow opening non-existent files', function()
	local f<close> = test.tmpfile()
	f:delete()

	io.open_file(f.filename)

	test.assert_equal(buffer.filename, f.filename)
end)

test('io.open_file should handle UTF-8-encoded files', function()
	local utf8_contents = 'Copyright ©'
	local f<close> = test.tmpfile(utf8_contents)

	io.open_file(f.filename)

	test.assert_equal(buffer:get_text(), utf8_contents)
	test.assert_equal(buffer.encoding, 'UTF-8')
	test.assert_equal(buffer.code_page, buffer.CP_UTF8)
end)

test('io.open_file should handle CP1252-encoded files', function()
	local utf8_contents = 'Copyright ©'
	local cp1252_contents = utf8_contents:iconv('CP1252', 'UTF-8')
	local f<close> = test.tmpfile(cp1252_contents)

	io.open_file(f.filename)

	test.assert_equal(buffer:get_text(), utf8_contents)
	test.assert_equal(buffer.encoding, 'CP1252')
end)

test('io.open_file should handle UTF-16-encoded files', function()
	local utf8_contents = 'Copyright ©'
	local utf16_contents = utf8_contents:iconv('UTF-16', 'UTF-8')
	local f<close> = test.tmpfile(utf16_contents)

	io.open_file(f.filename)

	test.assert_equal(buffer:get_text(), utf8_contents)
	test.assert_equal(buffer.encoding, 'UTF-16')
end)

test('io.open_file should handle binary files', function()
	local binary_contents = '\x00\xff\xff'
	local f<close> = test.tmpfile(binary_contents)

	io.open_file(f.filename)

	test.assert_equal(buffer:get_text(), binary_contents)
	test.assert_equal(buffer.encoding, nil)
	test.assert_equal(buffer.code_page, 0)
end)

test('io.open_file should detect and switch to spaces', function()
	local f<close> = test.tmpfile(test.lines{
		'1', -- no indent
		'    ', -- ignore blank line
		'          2', -- too much indentation
		'  3', -- should detect this
		'    4' -- should ignore
	})

	io.open_file(f.filename)

	test.assert_equal(buffer.use_tabs, false)
	test.assert_equal(buffer.tab_width, 2)
end)

test('io.open_file should detect and switch to tabs if buffer.use_tabs is false', function()
	local set_indentation_spaces = function() buffer.use_tabs = false end
	local _<close> = test.connect(events.BUFFER_NEW, set_indentation_spaces) -- temporary
	local f<close> = test.tmpfile(test.lines{'1', '\t2', '3'})

	io.open_file(f.filename)

	test.assert_equal(buffer.use_tabs, true)
end)

test('io.open_file should detect LF', function()
	local f<close> = test.tmpfile('\n')

	io.open_file(f.filename)

	test.assert_equal(buffer.eol_mode, buffer.EOL_LF)
end)

test('io.open_file should detect CR+LF', function()
	local f<close> = test.tmpfile('\r\n')

	io.open_file(f.filename)

	test.assert_equal(buffer.eol_mode, buffer.EOL_CRLF)
end)

test('io.open_file should scroll to the beginning of the file', function()
	local contents = string.rep('\n', view.lines_on_screen * 2)
	local f1<close> = test.tmpfile(contents)
	local f2<close> = test.tmpfile(contents)

	io.open_file(f1.filename)
	buffer:document_end()
	view.x_offset = 10

	io.open_file(f2.filename)

	test.assert_equal(view.first_visible_line, 1)
	test.assert_equal(view.x_offset, 0)
end)

test('io.open_file should keep track of the most recently opened files', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local f1<close> = test.tmpfile('.1')
	local f2<close> = test.tmpfile('.2')

	io.open_file{f1.filename, f2.filename}

	test.assert_equal(io.recent_files, {f2.filename, f1.filename})
end)

test('io.open_file should not duplicate any recently opened files', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local f1<close> = test.tmpfile('.1')
	local f2<close> = test.tmpfile('.2')

	io.open_file(f1.filename)
	buffer:close()

	io.open_file{f2.filename, f1.filename}

	test.assert_equal(io.recent_files, {f1.filename, f2.filename})
end)

test('buffer.reload should discard any unsaved changes', function()
	local contents = 'text'
	local _<close> = test.tmpfile(contents, true)
	buffer:clear_all()

	buffer:reload()

	test.assert_equal(buffer:get_text(), contents)
	test.assert_equal(buffer.modify, false)
end)

test('buffer.set_encoding should handle multi- to single-byte changes and mark the buffer as dirty',
	function()
		local utf8_contents = 'Copyright ©'
		local _<close> = test.tmpfile(utf8_contents, true)
		local encoding = 'CP1252'

		buffer:set_encoding(encoding)

		test.assert_equal(buffer.encoding, encoding)
		test.assert_equal(buffer:get_text(), utf8_contents) -- only different written to disk
		test.assert_equal(buffer.modify, true)
	end)

test('buffer.set_encoding should handle single-byte changes without marking buffer dirty',
	function()
		local utf8_contents = '中文\n'
		local encoding = 'CP936'
		local cp936_contents = utf8_contents:iconv(encoding, 'UTF-8')
		local _<close> = test.tmpfile(cp936_contents, true)
		local initially_detected_cp1252 = buffer.encoding == 'CP1252' -- incorrectly detected
		local initially_showed_cp1252 = buffer:get_text() ~= utf8_contents

		buffer:set_encoding(encoding)

		test.assert_equal(initially_detected_cp1252, true)
		test.assert_equal(initially_showed_cp1252, true)
		test.assert_equal(buffer.encoding, encoding)
		test.assert_equal(buffer:get_text(), utf8_contents)
		test.assert_equal(buffer.modify, false)
	end)
if OSX then skip('crashes on macOS due to system iconv error') end -- TODO:

test('buffer.set_encoding should handle single- to multi-byte changes and mark the buffer as dirty',
	function()
		local utf8_contents = 'Copyright ©'
		local cp1252_contents = utf8_contents:iconv('CP1252', 'UTF-8')
		local _<close> = test.tmpfile(cp1252_contents, true)
		local encoding = 'UTF-16'

		buffer:set_encoding(encoding)

		test.assert_equal(buffer.encoding, encoding)
		test.assert_equal(buffer:get_text(), utf8_contents)
		test.assert_equal(buffer.modify, true)
	end)

test('buffer.save should save the file and mark the buffer as unmodified', function()
	local contents = 'text'
	local f<close> = test.tmpfile(contents, true)
	buffer:append_text(' ')

	local saved = buffer:save()

	test.assert_equal(saved, true)
	test.assert_equal(buffer:get_text(), f:read())
	test.assert_equal(buffer.modify, false)
end)

test('buffer.save should prompt for a filename if the buffer does not have one', function()
	local f<close> = test.tmpfile()
	local select_filename = test.stub(f.filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)

	buffer:save()

	test.assert_equal(buffer.filename, f.filename)
end)

test('buffer.save should write a trailing newline if io.ensure_final_newline is enabled', function()
	local _<close> = test.mock(io, 'ensure_final_newline', true)
	local _<close> = test.tmpfile(true)
	local contents = 'text'
	buffer:append_text(contents)

	buffer:save()

	test.assert_equal(buffer:get_text(), test.lines{contents, ''})
end)

test('buffer:save should never write a trailing newline for binary files', function()
	local _<close> = test.mock(io, 'ensure_final_newline', true)
	local binary_contents = '\x00\xff\xff'
	local _<close> = test.tmpfile(binary_contents, true)

	buffer:save()

	test.assert_equal(buffer:get_text(), binary_contents)
end)

test('buffer.save should emit events.FILE_BEFORE_SAVE and events.FILE_AFTER_SAVE', function()
	local f<close> = test.tmpfile(true)
	f:delete() -- delete for tracking before and after events

	local file_exists = {}
	local check_file_exists = function(filename)
		file_exists[#file_exists + 1] = lfs.attributes(filename, 'mode') == 'file'
	end
	local before_save = test.stub(check_file_exists)
	local after_save = test.stub(check_file_exists)
	local _<close> = test.connect(events.FILE_BEFORE_SAVE, before_save)
	local _<close> = test.connect(events.FILE_AFTER_SAVE, after_save)

	buffer:save()

	test.assert_equal(before_save.called, true)
	test.assert_equal(before_save.args, {f.filename})
	test.assert_equal(after_save.called, true)
	test.assert_equal(after_save.args, {f.filename})
	test.assert_equal(file_exists, {false, true})
end)

test('buffer.save_as should save with a given filename', function()
	local f<close> = test.tmpfile()
	f:delete() -- should not exist yet

	local saved = buffer:save_as(f.filename)

	test.assert_equal(saved, true)
	test.assert_equal(buffer.filename, f.filename)
	local file_exists = lfs.attributes(f.filename, 'mode') == 'file'
	test.assert_equal(file_exists, true)
end)

test('buffer.save_as should prompt for a file to save to if none was given', function()
	local f<close> = test.tmpfile()
	local select_filename = test.stub(f.filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)

	local saved = buffer:save_as()

	test.assert_equal(saved, true)
end)

test('buffer.save_as should prompt with the current file', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{file}
	io.open_file(dir / file)
	local cancel_save = test.stub()
	local _<close> = test.mock(ui.dialogs, 'save', cancel_save)

	buffer:save_as()

	test.assert_equal(cancel_save.called, true)
	local dialog_opts = cancel_save.args[1]
	test.assert_equal(dialog_opts.dir, dir.dirname)
	test.assert_equal(dialog_opts.file, file)
end)

test('buffer.save_as should update the lexer', function()
	local f<close> = test.tmpfile('.lua')

	buffer:save_as(f.filename)

	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('buffer:save_as should emit a distinct events.FILE_AFTER_SAVE', function()
	local f<close> = test.tmpfile()
	local after_save = test.stub()
	local _<close> = test.connect(events.FILE_AFTER_SAVE, after_save)

	buffer:save_as(f.filename)

	test.assert_equal(after_save.called, 2) -- TODO: ideally this would only be called once
	test.assert_equal(after_save.args, {f.filename, true})
end)

test('io.save_all_files should save all modified files', function()
	local saved = test.stub()
	local _<close> = test.connect(events.FILE_AFTER_SAVE, saved)

	local modified_file<close> = test.tmpfile(true)
	buffer:append_text('modified_file')

	local unmodified_file<close> = test.tmpfile(true)

	local modified_untitled_buffer = buffer.new()
	buffer:append_text('new')

	local modified_typed_buffer = buffer.new()
	buffer._type = '[Typed Buffer]'
	buffer:append_text('typed')

	local saved_all = io.save_all_files()

	test.assert_equal(saved_all, true)
	test.assert_equal(saved.called, true) -- only one call
	test.assert_equal(saved.args, {modified_file.filename})
end)

test('io.save_all_files(true) should prompt to save untitled files', function()
	buffer:append_text('modified')

	-- Open another file to verify the untitled buffer is switched to prior to saving.
	local _<close> = test.tmpfile(true)

	local switched_to_untitled_buffer = false
	local check_for_untitled_buffer = function() switched_to_untitled_buffer = not buffer.filename end
	local cancel_save = test.stub(check_for_untitled_buffer)
	local _<close> = test.mock(ui.dialogs, 'save', cancel_save)

	io.save_all_files(true)

	test.assert_equal(switched_to_untitled_buffer, true)
end)

test('buffer.close should immediately close a buffer without changes', function()
	buffer.new()

	local closed = buffer:close()

	test.assert_equal(closed, true)
	test.assert_equal(#_BUFFERS, 1)
end)

test('buffer.close should prompt before closing a modified buffer', function()
	local cancel_close = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'message', cancel_close)
	local contents = 'text'
	buffer:append_text(contents)

	local closed = buffer:close()

	test.assert_equal(not closed, true)
	test.assert_equal(buffer:get_text(), contents)
end)

test('buffer.close should allow closing a modified buffer without prompting', function()
	buffer:append_text('text')

	local closed = buffer:close(true)

	test.assert_equal(closed, true)
end)

test('external file modifications should emit events.FILE_CHANGED', function()
	local file_changed = test.stub(false) -- halt propagation to default, prompting handler
	local _<close> = test.connect(events.FILE_CHANGED, file_changed, 1)
	local f<close> = test.tmpfile(true)

	-- Mock an external file modification.
	local request_mod_time = function(_, request) return request == 'modification' end
	local return_future_time = test.stub(os.time() + 1)
	local _<close> = test.mock(lfs, 'attributes', request_mod_time, return_future_time)

	buffer.new():close() -- trigger check

	test.assert_equal(file_changed.called, true)
	test.assert_equal(file_changed.args, {f.filename})
end)

--- Creates, opens, optionally modifies in-place with string *new_contents*, and returns a
-- temporary file.
-- The returned file will be detected as externally modified when switched away from and back to.
-- @param[opt] new_contents Optional string contents for the modified file.
-- @return to-be-closed temporary file
local function open_and_externally_modify_tmpfile(new_contents)
	local f = test.tmpfile(true)
	if new_contents then f:write(new_contents) end
	buffer.mod_time = buffer.mod_time - 1 -- simulate modification in the past
	return f
end

test('externally modified files should prompt for reload', function()
	local reloaded_contents = 'reloaded'
	local f<close> = open_and_externally_modify_tmpfile(reloaded_contents)
	local reload = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'message', reload)

	buffer.new():close() -- trigger check

	test.assert_equal(buffer:get_text(), reloaded_contents)
end)

test('io.close_all_buffers should close all unmodified buffers without checking for external mods',
	function()
		local file_changed = test.stub(false) -- prevent propagation to default, prompting handler
		local _<close> = test.connect(events.FILE_CHANGED, file_changed, 1)
		local f<close> = open_and_externally_modify_tmpfile()
		buffer.new()

		local closed_all = io.close_all_buffers()

		test.assert_equal(closed_all, true)
		test.assert_equal(file_changed.called, false)
		test.assert_equal(#_BUFFERS, 1)
		test.assert_equal(buffer.filename, nil)
	end)

test('buffer.reload should use the global buffer', function()
	local contents = 'text'
	local f<close> = test.tmpfile(true)
	f:write(contents)

	buffer.reload()

	test.assert_equal(buffer:get_text(), contents)
end)

test('buffer.save should use the global buffer', function()
	local _<close> = test.tmpfile(true)

	local saved = buffer.save()

	test.assert_equal(saved, true)
end)

test('buffer.save_as should prompt to save the global buffer', function()
	local f<close> = test.tmpfile(true)
	local name = f.filename:match('[^/\\]+$')
	local cancel_save = test.stub()
	local _<close> = test.mock(ui.dialogs, 'save', cancel_save)

	buffer.save_as()

	test.assert_equal(cancel_save.called, true)
	test.assert_equal(cancel_save.args[1].file, name)
end)

test('buffer.close should use the global buffer', function()
	local _<close> = test.tmpfile(true)

	buffer.close()

	test.assert_equal(buffer.filename, nil)
end)

test('io.open_recent_file should prompt for a recently opened file if it still exists', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local f<close> = test.tmpfile(true)
	buffer:close()
	do
		local _<close> = test.tmpfile(true)
		buffer:close()
	end -- deletes the file

	local select_first_item = test.stub({1}, 1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	io.open_recent_file()

	test.assert_equal(buffer.filename, f.filename)
end)

test('io.open_recent_file should allow clearing the list during prompt', function()
	local _<close> = test.mock(io, 'recent_files', {})
	local _<close> = test.tmpfile(true)
	buffer:close()

	local clear_recent_files = test.stub({1}, 3)
	local _<close> = test.mock(ui.dialogs, 'list', clear_recent_files)

	io.open_recent_file()

	test.assert_equal(io.recent_files, {})
	test.assert_equal(buffer.filename, nil)
end)

test('io.get_project_root should detect the project root from the working directory', function()
	local dir<close> = test.tmpdir({['.hg'] = {}}, true)

	local root = io.get_project_root()

	test.assert_equal(root, dir.dirname)
end)

test('io.get_project_root should detect the project root from the current file', function()
	local subdir = 'subdir'
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, [subdir] = {file}}
	io.open_file(dir / subdir .. '/' .. file)

	local root = io.get_project_root()

	test.assert_equal(root, dir.dirname)
end)

test('io.get_project_root should detect the project root from a given path', function()
	local subdir = 'subdir'
	local dir<close> = test.tmpdir{['.hg'] = {}, [subdir] = {}}

	local root = io.get_project_root(dir.dirname)
	local same_root = io.get_project_root(dir / subdir)

	test.assert_equal(root, dir.dirname)
	test.assert_equal(same_root, root)
end)

test('io.get_project_root should allow a submodule directory to be the project root', function()
	local subdir = 'subdir'
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.git'] = {}, [subdir] = {'.git', file}}
	io.open_file(dir / subdir .. '/' .. file)

	local root = io.get_project_root(true)

	test.assert_equal(root, dir / subdir)
end)

test('io.quick_open should prompt for a project file to open', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir({['.hg'] = {}, file}, true)
	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	io.quick_open()

	test.assert_equal(buffer.filename, dir / file)
end)

test('io.quick_open should prompt for a file to open from a given directory', function()
	local file = 'file.txt'
	local dir<close> = test.tmpdir{['.hg'] = {}, file}
	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	io.quick_open(dir.dirname)

	test.assert_equal(buffer.filename, dir / file)
end)

test('io.quick_open should prompt for a file to open, subject to a filter', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile_lua = 'subfile.lua'
	local dir<close> = test.tmpdir{['.hg'] = {}, file, [subdir] = {subfile_lua}}
	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	io.quick_open(dir.dirname, '.lua')

	test.assert_equal(buffer.filename, dir / (subdir .. '/' .. subfile_lua))
end)

test('io.quick_open should prompt for a file to open, subject to an exclusive filter', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile_lua = 'subfile.lua'
	local dir<close> = test.tmpdir{['.hg'] = {}, file, [subdir] = {subfile_lua}}
	local select_first_item = test.stub({1})
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	io.quick_open(dir.dirname, {'!.txt'})

	test.assert_equal(buffer.filename, dir / (subdir .. '/' .. subfile_lua))
end)

test('io.quick_open should prompt for a file to open, but with a maximum list length', function()
	local file = 'file.txt'
	local subdir = 'subdir'
	local subfile_lua = 'subfile.lua'
	local dir<close> = test.tmpdir{['.hg'] = {}, file, [subdir] = {subfile_lua}}
	local _<close> = test.mock(io, 'quick_open_max', 1)
	local cancel_open = test.stub()
	local _<close> = test.mock(ui.dialogs, 'list', cancel_open)
	local max_reached_ok = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'message', max_reached_ok)

	io.quick_open(dir.dirname)

	local dialog_opts = cancel_open.args[1]
	test.assert_equal(#dialog_opts.items, 1)
	test.assert_equal(max_reached_ok.called, true)
end)

test('- command line argument should read stdin into a new buffer as a file', function()
	local stdin_provider = test.stub('text')
	local _<close> = test.mock(io, 'read', stdin_provider)

	events.emit('command_line', {'-'}) -- simulate arg

	test.assert_equal(buffer:get_text(), 'text')
	test.assert_equal(buffer.modify, false)
end)

-- Related tests.

test('buffer.delete for a hidden buffer should not affect buffers in existing views', function()
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

-- Coverage tests.

test('io.open_file should raise an error if it cannot open or read a file', function()
	if LINUX then
		local cannot_open = function() io.open_file('/etc/gshadow-') end

		test.assert_raises(cannot_open, 'cannot open /etc/gshadow-: Permission denied')
	end
	-- TODO: find a case where the file can be opened, but not read
end)

test("buffer.save should remove a buffer's type once it has a filename", function()
	local f<close> = test.tmpfile()
	local select_filename = test.stub(f.filename)
	local _<close> = test.mock(ui.dialogs, 'save', select_filename)
	buffer._type = '[Typed Buffer]'

	buffer:save()

	test.assert_equal(buffer._type, nil)
end)

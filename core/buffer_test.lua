-- Copyright 2020-2026 Mitchell. See LICENSE.

test("buffer.text_range should implement Scintilla's SCI_GETTEXTRANGE", function()
	local text = '123456789'
	buffer:append_text(text)

	local sub_range = buffer:text_range(4, 7) -- 456
	local full_range = buffer:text_range(1, buffer.length + 1) -- 123456789
	local clamp_start_range = buffer:text_range(-1, 4) -- 123
	local clamp_end_range = buffer:text_range(7, 11) -- 789

	test.assert_equal(sub_range, text:sub(4, 6))
	test.assert_equal(full_range, text)
	test.assert_equal(clamp_start_range, text:sub(1, 3))
	test.assert_equal(clamp_end_range, text:sub(7))
end)

test('buffer.text_range should not modify buffer.target_range', function()
	local text = '123456789'
	buffer:append_text(text)
	buffer:set_target_range(4, 7) -- 456
	local target_text = buffer.target_text

	buffer:text_range(1, 4) -- 123

	test.assert_equal(buffer.target_text, target_text)
end)

test('replacing buffer text should emit events.BUFFER_{BEFORE,AFTER}_REPLACE_TEXT', function()
	buffer:append_text('text')
	local before_replace = test.stub()
	local after_replace = test.stub()
	local _<close> = test.connect(events.BUFFER_BEFORE_REPLACE_TEXT, before_replace)
	local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after_replace)

	buffer:set_text('replacement')

	test.assert_equal(before_replace.called, true)
	test.assert_equal(after_replace.called, true)
end)

for _, method in ipairs{'undo', 'redo'} do
	test('multi-line ' .. method .. ' should emit an event after updating UI', function()
		buffer:append_text('text')
		buffer:set_text(test.lines{'multi-line', 'text'})
		if method == 'redo' then buffer:undo() end
		local after_replace = test.stub()
		local _<close> = test.connect(events.BUFFER_AFTER_REPLACE_TEXT, after_replace)

		buffer[method](buffer)
		local overwritten_by_scintilla = after_replace.called
		ui.update() -- invokes events.UPDATE_UI
		if UI == 'terminal' then events.emit(events.UPDATE_UI, buffer.UPDATE_SELECTION) end
		local overwrites_scintilla = after_replace.called

		-- Scintilla would overwrite any changes by handlers if those handlers were called too soon.
		-- Instead, they should be called later to overwrite any Scintilla changes.
		test.assert_equal(overwritten_by_scintilla, false)
		test.assert_equal(overwrites_scintilla, true)
	end)
end

test('buffer.delete should emit events.BUFFER_DELETED', function()
	local f<close> = test.tmpfile(true)
	local deleted = test.stub()
	local _<close> = test.connect(events.BUFFER_DELETED, deleted)

	buffer:close()

	test.assert_equal(deleted.called, true)
	local buffer = deleted.args[1]
	test.assert_equal(buffer.filename, f.filename)
	local call_nil_value = function() return buffer:get_text() end
	test.assert_raises(call_nil_value, 'nil value')
end)

test('read/write-only properties should raise errors at the appropriate times', function()
	local read_only_sci_property = function() buffer.modify = false end
	local write_only_sci_property = function() return buffer.auto_c_fill_ups end
	local read_only_sci_field = function() buffer.char_at[1] = 0 end
	local write_only_sci_field = function() return view.marker_fore[1] end
	local read_only_property = function() view.buffer = nil end
	local write_only_property = function() return buffer.tab_label end

	test.assert_raises(read_only_sci_property, 'read-only property')
	test.assert_raises(write_only_sci_property, 'write-only property')
	test.assert_raises(read_only_sci_field, 'read-only property')
	test.assert_raises(write_only_sci_field, 'write-only property')
	test.assert_raises(read_only_property, 'read-only property')
	test.assert_raises(write_only_property, 'write-only property')
end)

--- Load buffer and view API.
local function load_props()
	local buffer_props, view_props = {}, {}
	for line in io.lines(_HOME .. '/core/buffer.lua') do
		if line:find('@field view%.') then
			view_props[line:match('@field view%.([%w_]+)')] = true
		elseif line:find('@table view%.') then
			view_props[line:match('@table view%.([%w_]+)')] = true
		elseif line:find('@function view:') then
			view_props[line:match('@function view:([%w_]+)')] = true
		elseif line:find('@field') then
			buffer_props[line:match('@field ([%w_]+)')] = true
		elseif line:find('@table') then
			buffer_props[line:match('@table ([%w_]+)')] = true
		elseif line:find('@function') then
			buffer_props[line:match('@function ([%w_]+)')] = true
		end
	end
	return buffer_props, view_props
end

--- Returns Textadept file *filename* relative to _HOME, with slashes.
local function file(filename) return ((_HOME .. '/' .. filename):gsub('\\', '/')) end

-- Valid usages to ignore.
local ignore_ids = {_G = true, M = true, _SCINTILLA = true, snippets = true}
local ignore_exprs = {['ui.size'] = true}
local exceptions = {
	[file('core/buffer.lua')] = {'buf:select_all', 'buf:replace_sel', 'v:select_all'},
	[file('core/lexer.lua')] = {
		'lexer.style_at', 'lexer.fold_level', 'lexer.line_from_position', 'lexer.line_end',
		'lexer.text_range'
	}, [file('core/lfs_ext.lua')] = {'filter_object.new'}, --
	[file('core/ui.lua')] = {'view:document_end'}, --
	[file('core/view.lua')] = {'env.view'},
	[file('modules/textadept/clipboard.lua')] = {'proc:close', 'orig.copy_text'}, --
	[file('modules/textadept/editing.lua')] = {'proc:close'}, --
	[file('modules/textadept/find.lua')] = {
		'ff_buffer.line_end_position', 'ff_buffer.line_count', 'ff_buffer.indicator_current',
		'ff_buffer:indicator_fill_range'
	}, --
	[file('modules/textadept/history.lua')] = {'record.filename', 'record.column'},
	[file('modules/textadept/session.lua')] = {
		'buf.filename', 'buf.anchor', 'buf.current_pos', 'split.buffer'
	}, --
	[file('modules/textadept/snippets.lua')] = {'snippet.new', 'placeholder.length', 'ph.length'}
}

--- Looks for use of buffer and view properties, and returns a list of invalid usages.
-- @param filename String filename of the Lua file to check.
-- @param buffer_props Table of valid buffer properties.
-- @param view_props Table of valid view properties.
local function check_usage(filename, buffer_props, view_props)
	local invalid_usages = {}

	local found_exceptions = {}
	for _, expr in ipairs(exceptions[filename] or {}) do
		exceptions[filename][expr] = true
		found_exceptions[expr] = false
	end

	local count = 0
	local line_num = 1
	for line in io.lines(filename) do
		for pos, expr, id, prop in line:gmatch('()(([%w_]+)[.:]([%w_]+))') do
			if ignore_ids[id] then goto continue end
			if ignore_exprs[expr] then goto continue end
			if found_exceptions[expr] ~= nil then
				found_exceptions[expr] = true
				goto continue
			end

			if buffer_props[prop] then
				if id ~= 'buffer' then
					invalid_usages[#invalid_usages + 1] = string.format("%d:%d: '%s' should be a 'buffer.%s'",
						line_num, pos, expr, prop, prop)
				end
				count = count + 1
			elseif view_props[prop] then
				if id ~= 'view' then
					invalid_usages[#invalid_usages + 1] = string.format("%d:%d: '%s' should be a 'view.%s'",
						line_num, pos, expr, prop, prop)
				end
				count = count + 1
			end
			::continue::
		end
		line_num = line_num + 1
	end
	if count > 0 then test.log(string.format('Checked %s usages.', count)) end

	for expr, found in pairs(found_exceptions) do
		if not found then
			invalid_usages[#invalid_usages + 1] = string.format("exception '%s' not found", expr)
		end
	end

	return invalid_usages
end

local buffer_props, view_props = load_props()

local stock_files = {}
local filter = {'*.lua', 'core/*.lua', 'modules/textadept/*.lua', '!**/*_test.lua'}
for filename in lfs.walk(_HOME, filter) do stock_files[#stock_files + 1] = filename:gsub('\\', '/') end
table.sort(stock_files)

-- Test each stock file.
for _, stock_file in ipairs(stock_files) do
	test(stock_file:sub(#_HOME + 2) .. ' should be using buffer and view API consistently', function()
		local invalid_usages = check_usage(stock_file, buffer_props, view_props)

		test.assert_equal(invalid_usages, {})
	end)
end

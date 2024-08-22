-- Copyright 2020-2024 Mitchell. See LICENSE.

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

--- Load buffer and view API from .buffer.luadoc.
local function load_props()
	local buffer_props, view_props = {}, {}
	for line in io.lines(_HOME .. '/core/.buffer.luadoc') do
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
	[file('core/init.lua')] = {'env.view'},
	[file('core/lexer.lua')] = {'lexer.style_at', 'lexer.fold_level', 'lexer.line_from_position'},
	[file('core/ui.lua')] = {'view:goto_pos'}, --
	[file('modules/textadept/editing.lua')] = {'p:close'}, --
	[file('modules/textadept/find.lua')] = {
		'ff_buffer.line_end_position', 'ff_buffer.line_count', 'ff_buffer.indicator_current',
		'ff_buffer:indicator_fill_range'
	}, --
	[file('modules/textadept/history.lua')] = {'record.filename', 'record.column'},
	[file('modules/textadept/session.lua')] = {
		'buf.filename', 'buf.anchor', 'buf.current_pos', 'split.size', 'split.buffer'
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
for _, dir in ipairs{file('core'), file('modules/textadept')} do
	for filename in lfs.walk(dir, '.lua') do
		if not filename:find('_test.lua') then
			stock_files[#stock_files + 1] = filename:gsub('\\', '/')
		end
	end
end
stock_files[#stock_files + 1] = file('init.lua')
table.sort(stock_files)

-- Test each stock file.
for _, stock_file in ipairs(stock_files) do
	test(stock_file:sub(#_HOME + 2) .. ' should be using buffer and view API consistently', function()
		local invalid_usages = check_usage(stock_file, buffer_props, view_props)

		test.assert_equal(invalid_usages, {})
	end)
end

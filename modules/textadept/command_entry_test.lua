-- Copyright 2020-2024 Mitchell. See LICENSE.

teardown(function()
	ui.update()
	if ui.command_entry.active then test.type('esc') end
end)

test('ui.command_entry.run should show a Lua command entry', function()
	ui.command_entry.run()

	test.assert_equal(ui.command_entry.margin_text[1], _L['Lua command:'])
	test.assert(ui.command_entry.margin_width_n[1] > 0, 'margin label should be visible')
	test.assert(ui.command_entry.margin_width_n[2] > 0, 'label and text should be separated')
	test.assert_equal(ui.command_entry.length, 0)
	test.assert_equal(ui.command_entry.lexer_language, 'lua')
	test.assert_equal(ui.command_entry.height, ui.command_entry:text_height(1))
	test.assert(keys.mode, 'should be in a command entry key mode')
	if QT then test.wait(function() return ui.command_entry.active end) end
	test.assert_equal(ui.command_entry.active, true)
end)
if GTK then expected_failure() end -- ui.command_entry.height is incorrect

test('ui.command_entry.run should not have issues being called again while active', function()
	ui.command_entry.run()
	ui.command_entry.run()
end)

test('ui.command_entry.run should run a Lua command on Enter', function()
	local echo = test.stub()
	local _<close> = test.mock(_G, 'echo', echo)
	ui.command_entry.run()

	test.type('echo(_HOME)\n')

	test.assert_equal(ui.command_entry.active, false)
	test.assert_equal(echo.called, true)
	test.assert_equal(echo.args, {_HOME})
end)

test('ui.command_entry.run should show and select the previously run command', function()
	ui.command_entry.run()
	test.type('nil\n')

	ui.command_entry.run()

	test.assert_equal(ui.command_entry:get_text(), 'nil')
	test.assert_equal(ui.command_entry:get_sel_text(), 'nil')
end)

test('ui.command_entry.run should invoke functions without parentheses', function()
	local f = test.stub()
	local _<close> = test.mock(_G, 'f', f)
	ui.command_entry.run()

	test.type('f\n')

	test.assert_equal(f.called, true)
end)

--- Runs Lua command *lua* using the command entry and returns the result that would be printed
-- to the output buffer.
-- @param lua String Lua command to run.
-- @return string output
local function run(lua)
	local ui_print = test.stub()
	local _<close> = test.mock(ui, 'output', ui_print)

	ui.command_entry.run()
	test.type(lua .. '\n')

	if ui_print.args then return ui_print.args[1] end
end

test('ui.command_entry.run should pretty-print Lua table values', function()
	local result = run("{key='value'}")

	test.assert_equal(result, "{key = value}")
end)

test('ui.command_entry.run should wrap pretty-printed tables longer than view.edge_column',
	function()
		local _<close> = test.mock(view, 'edge_column', 10)

		local result = run("{key='value'}")

		test.assert_equal(result, table.concat({'{', '\tkey = value', '}'}, '\n'))
	end)

test('ui.command_entry.run should consider Scintilla fields/functions as globals', function()
	local length = run('length')
	run('view_eol=not view_eol')
	local view_eol = view.view_eol
	local auto_c_active = run('auto_c_active')

	test.assert_equal(length, '0')
	test.assert_equal(view_eol, true)
	test.assert_equal(auto_c_active, 'false')
end)

test('ui.command_entry.run should consider view fields/functions as globals', function()
	run('split')
	local split = #_VIEWS > 1
	local original_view_size = view.size
	run('size=size//2')

	test.assert_equal(split, true)
	test.assert(view.size < original_view_size, 'should have resized view')
end)

test('ui.command_entry.run should consider ui fields/functions as globals', function()
	local _<close> = test.mock(ui, 'tabs', true) -- for CURSES
	local switch_buffer = test.stub()
	local _<close> = test.mock(ui, 'switch_buffer', switch_buffer)

	run('tabs=not tabs')
	run('switch_buffer')

	test.assert_equal(ui.tabs, false)
	test.assert_equal(switch_buffer.called, true)
end)

test('ui.command_entry.run should consider textadept modules as globals', function()
	local auto_indent = run('editing.auto_indent')

	test.assert_equal(auto_indent, 'true')
end)

test('ui.command_entry.run should allow setting globals', function()
	local _<close> = test.defer(function() _G.global = nil end)

	run('global=true')
	local global = run('global')

	test.assert_equal(global, 'true')
end)

test('--execute should run Lua code via ui.command_entry.run', function()
	local f = test.stub()
	local _<close> = test.mock(_G, 'f', f)

	events.emit('command_line', {'--execute', 'f'}) -- simulate

	test.assert_equal(f.called, true)
end)

--- Returns table of tab completions for Lua command *lua*.
-- Return completion items will contain trailing '?n' sequences, where *n* is an XPM type.
-- @param lua String Lua command to tab-complete.
-- @return table of completions
local function tab_complete(lua)
	local show = test.stub()
	local _<close> = test.mock(ui.command_entry, 'auto_c_show', show)

	ui.command_entry.run()
	ui.command_entry:clear_all()

	test.type(lua .. '\t')

	local cmpls = {}
	if show.called then for c in show.args[3]:gmatch('%S+') do cmpls[#cmpls + 1] = c end end
	return cmpls
end

local XPMS = textadept.editing.XPM_IMAGES

test('ui.command_entry.run should have tab-completion', function()
	local completions = tab_complete('string.')

	test.assert(#completions > 0, 'should have returned completions')
	test.assert_equal(completions[1], 'byte?' .. XPMS.METHOD)
end)

test('ui.command_entry.run should tab-complete global Scintilla fields/functions', function()
	local constants = tab_complete('MARK')
	local fields = tab_complete('caret')
	local functions = tab_complete('auto')

	test.assert_equal(constants[1], 'MARKER_MAX?' .. XPMS.VARIABLE)
	test.assert_equal(fields[1], 'caret_fore?' .. XPMS.VARIABLE)
	test.assert_equal(functions[1], 'auto_c_active?' .. XPMS.METHOD)
end)

test('ui.command_entry.run should tab-complete global view fields/functions', function()
	local completions = tab_complete('goto')

	test.assert_equal(completions[1], 'goto_buffer?' .. XPMS.METHOD)
end)

test('ui.command_entry.run should tab-complete global ui fields/functions', function()
	local fields = tab_complete('fin')
	local functions = tab_complete('ou')

	test.assert_equal(fields[1], 'find?' .. XPMS.VARIABLE)
	test.assert_equal(functions[1], 'output?' .. XPMS.METHOD)
end)

test('ui.command_entry.run should tab-complete global textadept modules', function()
	local completions = tab_complete('ma')

	test.assert_equal(completions[1], 'macros?' .. XPMS.VARIABLE)
end)

test("ui.command_entry.run should tab-complete only functions when using ':'", function()
	local functions = tab_complete('buffer:auto')

	test.assert_equal(functions[1], 'auto_c_active?' .. XPMS.METHOD)
end)

test('ui.command_entry.run should include Scintilla field/function tab-completions in views',
	function()
		local fields = tab_complete('view.margin')
		local functions = tab_complete('view:call')

		test.assert_equal(fields[1], 'margin_back_n?' .. XPMS.VARIABLE)
		test.assert_equal(functions[1], 'call_tip_active?' .. XPMS.METHOD)
	end)

test('ui.command_entry.run should do nothing if tab-completion fails', function()
	local text = 'nocompletions'
	local no_completions = tab_complete(text)

	test.assert_equal(no_completions, {})
	test.assert_equal(ui.command_entry:get_text(), text)
end)

test('ui.command_entry should start with an empty command history for each mode', function()
	local f = test.stub()
	ui.command_entry:set_text('previous command')

	ui.command_entry.run('', f)

	test.assert_equal(ui.command_entry:get_text(), '')
end)

test('ui.command_entry.run should add to the command history on Enter', function()
	local f = test.stub()
	ui.command_entry.run('', f)

	test.type('command\n')
	ui.command_entry.run('', f)

	test.assert_equal(ui.command_entry:get_text(), 'command')
end)

test('ui.command_entry.run history should be cycle-able', function()
	local f = test.stub()
	ui.command_entry.run('', f)
	test.type('1\n')
	ui.command_entry.run('', f)
	test.type('2\n')
	ui.command_entry.run('', f)

	test.type('up')
	local should_be_1 = ui.command_entry:get_text()
	test.type('up')
	local should_still_be_1 = ui.command_entry:get_text()
	test.type('down')
	local should_be_2 = ui.command_entry:get_text()
	test.type('down')
	local should_still_be_2 = ui.command_entry:get_text()

	test.assert_equal(should_be_1, '1')
	test.assert_equal(should_still_be_1, '1')
	test.assert_equal(should_be_2, '2')
	test.assert_equal(should_still_be_2, '2')
end)

test('ui.command_entry.run history cycling should handle initial text', function()
	local f = test.stub()
	ui.command_entry.run('', f)
	test.type('1\n')
	ui.command_entry.run('', f, 'text', '2')

	test.type('up')
	test.type('down')

	test.assert_equal(ui.command_entry:get_text(), '2')
end)

test('ui.command_entry.run should not duplicate consecutive commands in history', function()
	local f = test.stub()
	ui.command_entry.run('', f)
	test.type('1\n')
	ui.command_entry.run('', f)
	test.type('2\n')
	ui.command_entry.run('', f)
	test.type('\n') -- run previous command
	ui.command_entry.run('', f)

	test.type('up')

	test.assert_equal(ui.command_entry:get_text(), '1')
end)

test('ui.command_entry.run should not cycle history when autocomplete is active', function()
	ui.command_entry.run()
	test.type('nil\n') -- add a command to the history
	ui.command_entry.run()
	test.type('s')
	local active = test.stub(true)
	local _<close> = test.mock(ui.command_entry, 'auto_c_active', active) -- simulate tab-completion

	test.type('up')

	test.assert_equal(ui.command_entry:auto_c_active(), true)
	test.assert_equal(ui.command_entry:get_text(), 's') -- not previous command, 'nil'
end)

test('ui.command_entry.run should add non-existing esc key to the given keybindings', function()
	local f = test.stub()
	ui.command_entry.run('', f, {})

	test.type('esc')

	test.assert_equal(ui.command_entry.active, false)
end)

test('ui.command_entry.run should add non-existing \\n key to the given keybindings', function()
	local f = test.stub()
	ui.command_entry.run('', f, {})

	test.type('\n')

	test.assert_equal(f.called, true)
end)

test('ui.command_entry.run should not select initial text if it was given', function()
	local f = test.stub()
	ui.command_entry.run('', f, 'text', 'initial')

	test.assert_equal(ui.command_entry.selection_empty, true)
	test.assert_equal(ui.command_entry.current_pos, ui.command_entry.length + 1)
end)

test('ui.command_entry should restore an active key mode', function()
	local mode = 'test_mode'
	local _<close> = test.mock(keys, 'mode', mode)
	ui.command_entry.run()
	test.type('esc')

	test.assert_equal(keys.mode, mode)
end)

test('ui.command_entry.run should pass additional arguments to the run function', function()
	local f = test.stub()
	ui.command_entry.run('', f, 'text', 'initial', 1)

	test.type('\n')

	test.assert_equal(f.args, {'initial', 1})
end)

test('ui.command_entry should emit events.COMMAND_TEXT_CHANGED when its text changes', function()
	local changed = test.stub()
	local _<close> = test.connect(events.COMMAND_TEXT_CHANGED, changed)

	ui.command_entry:append_text('changed')

	test.assert_equal(changed.called, true)
end)

test('ui.command_entry.run should preserve margin text when the entry is blank', function()
	local label = 'label:'
	local f = test.stub()
	ui.command_entry.run(label, f)
	ui.command_entry:add_text('a')
	ui.command_entry:delete_back() -- without a patch, Scintilla clears margin text

	test.assert_equal(ui.command_entry.length, 0)
	test.assert_equal(ui.command_entry.margin_text[1], label)
end)

-- TODO: textadept.menu.menubar['Tools/Language Server/Show Documentation'][2]()

-- Copyright 2020-2024 Mitchell. See LICENSE.

test('key sequences should come in via events.KEY and emit events.KEYPRESS', function()
	local key = test.stub()

	local _<close> = test.connect(events.KEYPRESS, key, 1)
	events.emit(events.KEY, string.byte('A'), view.MOD_CTRL | view.MOD_SHIFT)

	test.assert_equal(key.called, true)
	test.assert_equal(key.args, {not OSX and 'ctrl+A' or 'cmd+A'})
end)

test('symbolic keys should come from keys.KEYSYMS', function()
	local key = test.stub()

	local _<close> = test.connect(events.KEYPRESS, key, 1)
	local up_keysym = QT and 0x01000013 or GTK and 0xFF52 or 301
	events.emit(events.KEY, up_keysym, 0)

	test.assert_equal(key.args, {'up'})
end)

test('key commands should be bound to specific key sequences', function()
	local ctrl_a = 'ctrl+a'
	local a = 'a'
	local ctrl_A = 'ctrl+A'
	local command = test.stub()

	local _<close> = test.mock(keys, ctrl_a, command)
	events.emit(events.KEYPRESS, a)
	local command_called_by_a = command.called
	events.emit(events.KEYPRESS, ctrl_A)
	local command_called_by_ctrl_A = command.called
	events.emit(events.KEYPRESS, ctrl_a)
	local command_called_by_ctrl_a = command.called

	test.assert_equal(command_called_by_a, false)
	test.assert_equal(command_called_by_ctrl_A, false)
	test.assert_equal(command_called_by_ctrl_a, true)
end)

test('keys.keychain api should be read-only', function()
	local set_key = function() keys.keychain[1] = 'ctrl+a' end

	test.assert_raises(set_key, 'read-only')
end)

test('keys.keychain should contain the current key chain', function()
	local ctrl_a = 'ctrl+a'

	local _<close> = test.mock(keys, ctrl_a, {})
	events.emit(events.KEYPRESS, ctrl_a)
	local _<close> = test.defer(function() events.emit(events.KEYPRESS, keys.CLEAR) end)

	test.assert_equal(keys.keychain, {ctrl_a})
end)

test('key chains can be cancelled', function()
	local ctrl_a = 'ctrl+a'

	local _<close> = test.mock(keys, ctrl_a, {})
	events.emit(events.KEYPRESS, ctrl_a)
	events.emit(events.KEYPRESS, 'esc')

	test.assert_equal(keys.keychain, {})
end)

test('key chains should run their key commands when the entire chain is typed', function()
	local ctrl_a = 'ctrl+a'
	local command = test.stub()

	local _<close> = test.mock(keys, ctrl_a, {[ctrl_a] = command})
	events.emit(events.KEYPRESS, ctrl_a)
	local called_early = command.called
	events.emit(events.KEYPRESS, ctrl_a)

	test.assert_equal(called_early, false)
	test.assert_equal(command.called, true)
	test.assert_equal(keys.keychain, {})
end)

test('key chains with invalid sequences should be cancelled', function()
	local ctrl_a = 'ctrl+a'
	local ctrl_b = 'ctrl+b'
	local command = test.stub()

	local _<close> = test.mock(keys, ctrl_a, {})
	local _<close> = test.mock(keys, ctrl_b, command)
	events.emit(events.KEYPRESS, ctrl_a)
	events.emit(events.KEYPRESS, ctrl_b)

	test.assert_equal(keys.keychain, {})
	test.assert_equal(command.called, false)
end)

test('language-specific keys should have priority over global keys', function()
	local ctrl_a = 'ctrl+a'
	local command = test.stub()
	local ignored = test.stub()

	local _<close> = test.mock(keys.text, ctrl_a, command)
	local _<close> = test.mock(keys, ctrl_a, ignored)
	events.emit(events.KEYPRESS, ctrl_a)

	test.assert_equal(command.called, true)
	test.assert_equal(ignored.called, false)
end)

test('language-specific keys should propagate to global keys', function()
	local ctrl_a = 'ctrl+a'
	local propagate = test.stub(false)
	local command = test.stub()

	local _<close> = test.mock(keys.text, ctrl_a, propagate)
	local _<close> = test.mock(keys, ctrl_a, command)
	events.emit(events.KEYPRESS, ctrl_a)

	test.assert_equal(command.called, true)
end)

test('mode keys should have priority over language-specific and global keys', function()
	local ctrl_a = 'ctrl+a'
	local mode_command = test.stub()
	local language_command = test.stub()
	local global_command = test.stub()

	local _<close> = test.mock(keys, 'new_mode', {[ctrl_a] = mode_command})
	local _<close> = test.mock(keys.text, ctrl_a, language_command)
	local _<close> = test.mock(keys, ctrl_a, global_command)

	local _<close> = test.mock(keys, 'mode', 'new_mode')
	events.emit(events.KEYPRESS, ctrl_a)

	test.assert_equal(mode_command.called, true)
	test.assert_equal(language_command.called, false)
	test.assert_equal(global_command.called, false)
end)

test('mode keys should not be able to propagate to language-specific or global keys', function()
	local ctrl_a = 'ctrl+a'
	local propagate = test.stub(false)
	local language_command = test.stub(false)
	local global_command = test.stub()

	local _<close> = test.mock(keys, 'new_mode', {[ctrl_a] = mode_command})
	local _<close> = test.mock(keys.text, ctrl_a, language_command)
	local _<close> = test.mock(keys, ctrl_a, global_command)

	local _<close> = test.mock(keys, 'mode', 'new_mode')
	events.emit(events.KEYPRESS, ctrl_a)

	test.assert_equal(language_command.called, false)
	test.assert_equal(global_command.called, false)
end)

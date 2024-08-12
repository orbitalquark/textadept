-- Copyright 2020-2024 Mitchell. See LICENSE.

test('keys should contain sequences bound to commands', function()
	local sequence1 = 'ctrl+a'
	local command1 = test.stub()
	local sequence2 = 'ctrl+A'
	local command2 = test.stub()
	local _<close> = test.mock(keys, sequence1, command1)
	local _<close> = test.mock(keys, sequence2, command2)

	test.type(sequence1)
	test.type(sequence2)

	test.assert_equal(command1.called, true)
	test.assert_equal(command2.called, true)
end)

test('keys should allow sequences bound to key chains', function()
	local sequence = 'ctrl+a'
	local command = test.stub()
	local _<close> = test.mock(keys, sequence, {[sequence] = command})

	test.type(sequence)
	local intermediate_keychain = {table.unpack(keys.keychain)}
	local called_early = command.called
	test.type(sequence)

	test.assert_equal(intermediate_keychain, {sequence})
	test.assert_equal(called_early, false)
	test.assert_equal(command.called, true)
	test.assert_equal(keys.keychain, {})
end)

test('key chains should be cancellable', function()
	local sequence = 'ctrl+a'
	local chain = {}
	local _<close> = test.mock(keys, sequence, chain)
	test.type(sequence)

	test.type('esc')

	test.assert_equal(keys.keychain, {})
end)

test('key chains with invalid sequences should be cancelled', function()
	local sequence = 'ctrl+a'
	local non_chain_sequence = 'ctrl+b'
	local non_chain_command = test.stub()
	local chain = {}
	local _<close> = test.mock(keys, sequence, chain)
	local _<close> = test.mock(keys, non_chain_sequence, non_chain_command)
	test.type(sequence)

	test.type(non_chain_sequence)

	test.assert_equal(keys.keychain, {})
	test.assert_equal(non_chain_command.called, false)
end)

test('language-specific keys should have priority over global keys', function()
	local sequence = 'ctrl+a'
	local language_command = test.stub()
	local global_command = test.stub()
	local _<close> = test.mock(keys.text, sequence, language_command)
	local _<close> = test.mock(keys, sequence, global_command)

	test.type(sequence)

	test.assert_equal(language_command.called, true)
	test.assert_equal(global_command.called, false)
end)

test('language-specific keys should be able to propagate to global keys', function()
	local sequence = 'ctrl+a'
	local language_command_that_propagates = test.stub(false)
	local global_command = test.stub()
	local _<close> = test.mock(keys.text, sequence, language_command_that_propagates)
	local _<close> = test.mock(keys, sequence, global_command)

	test.type(sequence)

	test.assert_equal(global_command.called, true)
end)

test('mode keys should have priority over language-specific and global keys', function()
	local key_mode = 'test_mode'
	local sequence = 'ctrl+a'
	local mode_command = test.stub()
	local language_command = test.stub()
	local global_command = test.stub()
	local _<close> = test.mock(keys, key_mode, {[sequence] = mode_command})
	local _<close> = test.mock(keys.text, sequence, language_command)
	local _<close> = test.mock(keys, sequence, global_command)

	local _<close> = test.mock(keys, 'mode', key_mode)

	test.type(sequence)

	test.assert_equal(mode_command.called, true)
	test.assert_equal(language_command.called, false)
	test.assert_equal(global_command.called, false)
end)

test('mode keys should not be allowed to propagate to language-specific or global keys', function()
	local key_mode = 'test_mode'
	local sequence = 'ctrl+a'
	local mode_command = test.stub(false)
	local language_command = test.stub(false)
	local global_command = test.stub()
	local _<close> = test.mock(keys, key_mode, {[sequence] = mode_command})
	local _<close> = test.mock(keys.text, sequence, language_command)
	local _<close> = test.mock(keys, sequence, global_command)

	local _<close> = test.mock(keys, 'mode', key_mode)

	test.type(sequence)

	test.assert_equal(language_command.called, false)
	test.assert_equal(global_command.called, false)
end)

-- Coverage tests.

test('key sequences should come in via events.KEY and emit events.KEYPRESS', function()
	local key = test.stub()
	local _<close> = test.connect(events.KEYPRESS, key, 1)

	events.emit(events.KEY, string.byte('A'), view.MOD_CTRL | view.MOD_SHIFT)

	test.assert_equal(key.called, true)
	test.assert_equal(key.args, {(not OSX or CURSES) and 'ctrl+A' or 'cmd+A'})
end)

test('symbolic keys should come from keys.KEYSYMS', function()
	local key = test.stub()
	local _<close> = test.connect(events.KEYPRESS, key, 1)
	local up_keysym = QT and 0x01000013 or GTK and 0xFF52 or 301

	events.emit(events.KEY, up_keysym, 0)

	test.assert_equal(key.args, {'up'})
end)

test('keys.keychain should be read-only', function()
	local set_key = function() keys.keychain[1] = 'ctrl+a' end

	test.assert_raises(set_key, 'read-only')
end)

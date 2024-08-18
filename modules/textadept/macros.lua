-- Copyright 2018-2024 Mitchell. See LICENSE.

--- A module for recording, playing, saving, and loading keyboard macros.
-- Menu commands are also recorded.
-- At this time, typing into multiple cursors during macro playback is not supported.
-- @module textadept.macros
local M = {}

local macro_path = _USERHOME .. (not WIN32 and '/' or '\\') .. 'macros'
local recording, macro

-- List of commands bound to keys to ignore during macro recording, as the command(s) ultimately
-- executed will be recorded in some form.
local ignore
events.connect(events.INITIALIZED, function()
	ignore = {
		textadept.menu.menubar['Search/Find'][2], textadept.menu.menubar['Search/Find Incremental'][2],
		textadept.menu.menubar['Tools/Select Command'][2],
		textadept.menu.menubar['Tools/Macros']['Start/Stop Recording'][2]
	}
end)

--- Returns a function that records a macro-able event.
-- @param event The name of the event to record.
local function event_recorder(event) return function(...) macro[#macro + 1] = {event, ...} end end
--- Event handlers for recording macro-able events.
local event_recorders = {
	[events.KEYPRESS] = function(key)
		for i = 1, #ignore do if keys[key] == ignore[i] then return end end
		macro[#macro + 1] = {events.KEYPRESS, key}
	end, --
	[events.MENU_CLICKED] = event_recorder(events.MENU_CLICKED),
	[events.CHAR_ADDED] = event_recorder(events.CHAR_ADDED),
	[events.FIND] = event_recorder(events.FIND), --
	[events.REPLACE] = event_recorder(events.REPLACE), --
	[events.UPDATE_UI] = function()
		if #keys.keychain == 0 then ui.statusbar_text = _L['Macro recording'] end
	end
}
--- Prevents `events.FIND` from being emitted immediately after `events.REPLACE`.
local function inhibit_find_next() return true end

--- Toggles between starting and stopping macro recording.
function M.record()
	if not recording then
		if macro then M.save('0') end -- store most recently recorded macro in register 0
		macro = {}
		for event, f in pairs(event_recorders) do events.connect(event, f, 1) end
		events.connect(events.REPLACE, inhibit_find_next)
		ui.statusbar_text = _L['Macro recording']
	else
		for event, f in pairs(event_recorders) do events.disconnect(event, f) end
		events.disconnect(events.REPLACE, inhibit_find_next)
		ui.statusbar_text = _L['Macro stopped recording']
	end
	recording = not recording
end

--- Plays a recorded or previously loaded macro, or loads and plays the macro from file *filename*
-- if given.
-- @param[opt] filename Optional filename of a macro to load and play. If the filename is a
--	relative path, it will be relative to *`_USERHOME`/macros/*.
function M.play(filename)
	if recording then return end
	if assert_type(filename, 'string/nil', 1) then M.load(filename) end
	if not macro then return end
	-- If this function is run as a key command, `keys.keychain` cannot be cleared until this
	-- function returns. Emit 'esc' to forcibly clear it so subsequent keypress events can be
	-- properly handled.
	events.emit(events.KEYPRESS, 'esc')
	for _, event in ipairs(macro) do
		if event[1] == events.CHAR_ADDED then
			local f = buffer.selection_empty and buffer.add_text or buffer.replace_sel
			f(buffer, utf8.char(event[2]))
		end
		events.emit(table.unpack(event))
	end
end

--- Saves a recorded macro to file *filename* or the user-selected file.
-- @param[opt] filename Optional filename to save the recorded macro to. If `nil`, the user
--	is prompted for one. If the filename is a relative path, it will be relative to
--	*`_USERHOME`/macros/*.
function M.save(filename)
	if recording or not macro then return end
	if not assert_type(filename, 'string/nil', 1) then
		filename = ui.dialogs.save{title = _L['Save Macro'], dir = macro_path}
		if not filename then return end
	end
	local f = assert(io.open(lfs.abspath(filename, macro_path), 'w'))
	f:write('return {\n')
	for _, event in ipairs(macro) do
		f:write(string.format('{%q,', event[1]))
		for i = 2, #event do
			f:write(string.format(type(event[i]) == 'string' and '%q,' or '%s,', event[i]))
		end
		f:write('},\n')
	end
	f:write('}\n'):close()
end

--- Loads a macro from file *filename* or the user-selected file.
-- @param[opt] filename Optional macro file to load. If `nil`, the user is prompted for one. If
--	the filename is a relative path, it will be relative to *`_USERHOME`/macros/*.
function M.load(filename)
	if recording then return end
	if not assert_type(filename, 'string/nil', 1) then
		filename = ui.dialogs.open{title = _L['Load Macro'], dir = macro_path}
		if not filename then return end
	end
	local loaded = assert(loadfile(lfs.abspath(filename, macro_path), 't', {}))()
	M.save('0') -- store previous macro in register 0
	macro = loaded
end

if not lfs.attributes(macro_path) then lfs.mkdir(macro_path) end

return M

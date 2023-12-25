-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Textadept's core event structure and handlers.
--
-- Textadept emits events when you do things like create a new buffer, press a key, click on
-- a menu, etc. You can even emit events yourself using Lua. Each event has a set of event
-- handlers, which are simply Lua functions called in the order they were connected to an
-- event. For example, if you created a module that needs to do something each time Textadept
-- creates a new buffer, connect a Lua function to the `events.BUFFER_NEW` event:
--
--	events.connect(events.BUFFER_NEW, function()
--		-- Do something here.
--	end)
--
-- Events themselves are nothing special. You do not have to declare one before using it. Events
-- are simply strings containing arbitrary event names. When either you or Textadept emits an
-- event, Textadept runs all event handlers connected to the event, passing any given arguments
-- to the event's handler functions. If an event handler explicitly returns a value that is not
-- `nil`, Textadept will not call subsequent handlers. This is useful if you want to stop the
-- propagation of an event like a keypress if your event handler handled it, or if you want to
-- use the event framework to pass values.
-- @module events
local M = {}

--- Emitted when macOS tells Textadept to open a file.
-- Arguments:
--
-- - *uri*: The UTF-8-encoded URI to open.
-- @field APPLEEVENT_ODOC

--- Emitted after deleting a character while an autocompletion or user list is active.
-- @field AUTO_C_CHAR_DELETED

--- Emitted when canceling an autocompletion or user list.
-- @field AUTO_C_CANCELED

--- Emitted after inserting an item from an autocompletion list into the buffer.
-- Arguments:
--
-- - *text*: The selection's text.
-- - *position*: The autocompleted word's beginning position.
-- @field AUTO_C_COMPLETED

--- Emitted after selecting an item from an autocompletion list, but before inserting that item
-- into the buffer.
-- Automatic insertion can be canceled by calling `buffer:auto_c_cancel()` before returning
-- from the event handler.
-- Arguments:
--
-- - *text*: The selection's text.
-- - *position*: The autocompleted word's beginning position.
-- @field AUTO_C_SELECTION

--- Emitted as items are highlighted in an autocompletion or user list.
-- Arguments:
--
-- - *id*: Either the *id* from `buffer:user_list_show()` or `0` for an autocompletion list.
-- - *text*: The current selection's text.
-- - *position*: The position the list was displayed at.
-- @field AUTO_C_SELECTION_CHANGE

--- Emitted right after switching to another buffer.
-- The buffer being switched to is `buffer`.
-- Emitted by `view:goto_buffer()`.
-- @field BUFFER_AFTER_SWITCH

--- Emitted before replacing the contents of the current buffer.
-- Note that it is not guaranteed that `events.BUFFER_AFTER_REPLACE_TEXT` will be emitted
-- shortly after this event.
-- The buffer **must not** be modified during this event.
-- @field BUFFER_BEFORE_REPLACE_TEXT

--- Emitted right before switching to another buffer.
-- The buffer being switched from is `buffer`.
-- Emitted by `view:goto_buffer()`.
-- @field BUFFER_BEFORE_SWITCH

--- Emitted after replacing the contents of the current buffer.
-- Note that it is not guaranteed that `events.BUFFER_BEFORE_REPLACE_TEXT` was emitted previously.
-- The buffer **must not** be modified during this event.
-- @field BUFFER_AFTER_REPLACE_TEXT

--- Emitted after deleting a buffer.
-- Emitted by `buffer:delete()`.
-- Arguments:
--
-- - *buffer*: Simple representation of the deleted buffer. Buffer operations cannot be performed
--	on it, but fields like `buffer.filename` can be read.
-- @field BUFFER_DELETED

--- Emitted after creating a new buffer.
-- The new buffer is `buffer`.
-- Emitted on startup and by `buffer.new()`.
-- @field BUFFER_NEW

--- Emitted when clicking on a calltip.
-- This event is not emitted by the Qt version.
-- Arguments:
--
-- - *position*: `1` if the up arrow was clicked, `2` if the down arrow was clicked, and `0`
--	otherwise.
-- @field CALL_TIP_CLICK

--- Emitted after the user types a text character into the buffer.
-- Arguments:
--
-- - *code*: The text character's character code.
-- @field CHAR_ADDED

--- Emitted when the text in the command entry changes.
-- `ui.command_entry:get_text()` returns the current text.
-- @field COMMAND_TEXT_CHANGED

--- Emitted after double-clicking the mouse button.
-- Arguments:
--
-- - *position*: The position double-clicked.
-- - *line*: The line number of the position double-clicked.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.
-- @field DOUBLE_CLICK

--- Emitted when the terminal version receives an unrecognized CSI sequence.
-- Arguments:
--
-- - *cmd*: The 24-bit CSI command value. The lowest byte contains the command byte. The second
--	lowest byte contains the leading byte, if any (e.g. '?'). The third lowest byte contains
--	the intermediate byte, if any (e.g. '$').
-- - *args*: Table of numeric arguments of the CSI sequence.
-- @field CSI

--- Emitted after `events.DWELL_START` when the user moves the mouse, presses a key, or scrolls
-- the view.
-- Arguments:
--
-- - *position*: The position closest to *x* and *y*.
-- - *x*: The x-coordinate of the mouse in the view.
-- - *y*: The y-coordinate of the mouse in the view.
-- @field DWELL_END

--- Emitted when the mouse is stationary for `view.mouse_dwell_time` milliseconds.
-- Arguments:
--
-- - *position*: The position closest to *x* and *y*.
-- - *x*: The x-coordinate of the mouse in the view.
-- - *y*: The y-coordinate of the mouse in the view.
-- @field DWELL_START

--- Emitted when an error occurs.
-- Arguments:
--
-- - *text*: The error message text.
-- @field ERROR

--- Emitted to find text via the Find & Replace Pane.
-- Arguments:
--
-- - *text*: The text to search for.
-- - *next*: Whether or not to search forward.
-- @field FIND

--- Emitted when the text in the "Find" field of the Find & Replace Pane changes.
-- `ui.find.find_entry_text` contains the current text.
-- @field FIND_TEXT_CHANGED

--- Emitted when Textadept receives focus.
-- This event is never emitted when Textadept is running in the terminal.
-- @field FOCUS

--- Emitted when clicking the mouse on text that has an indicator present.
-- Arguments:
--
-- - *position*: The clicked text's position.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.
-- @field INDICATOR_CLICK

--- Emitted when releasing the mouse after clicking on text that has an indicator present.
-- Arguments:
--
-- - *position*: The clicked text's position.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.
-- @field INDICATOR_RELEASE

--- Emitted after Textadept finishes initializing.
-- @field INITIALIZED

--- Emitted when clicking the mouse inside a sensitive margin.
-- Arguments:
--
-- - *margin*: The margin number clicked.
-- - *position*: The beginning position of the clicked margin's line.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.
-- @field MARGIN_CLICK

--- Emitted after selecting a menu item.
-- Arguments:
--
-- - *menu_id*: The numeric ID of the menu item, which was defined in `ui.menu()`.
-- @field MENU_CLICKED

--- Emitted by the GUI version when switching between light mode and dark mode.
-- Arguments:
--
-- - *mode*: Either "light" or "dark".
-- @field MODE_CHANGED

--- Emitted by the terminal version for an unhandled mouse event.
-- A handler should return `true` if it handled the event. Otherwise Textadept will try again.
-- (This side effect for a `false` or `nil` return is useful for sending the original mouse
-- event to a different view that a handler has switched to.)
-- Arguments:
--
-- - *event*: The mouse event: `view.MOUSE_PRESS`, `view.MOUSE_DRAG`, or `view.MOUSE_RELEASE`.
-- - *button*: The mouse button number.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`, `view.MOD_SHIFT`,
--	and `view.MOD_ALT`.
-- - *y*: The y-coordinate of the mouse event, starting from 1.
-- - *x*: The x-coordinate of the mouse event, starting from 1.
-- @field MOUSE

--- Emitted when quitting Textadept.
-- When connecting to this event, connect with an index of 1 if the handler needs to run before
-- Textadept closes all open buffers. If a handler returns `true`, Textadept does not quit. It is
-- not recommended to return `false` from a quit handler, as that may interfere with Textadept's
-- normal shutdown procedure.
-- Emitted by `quit()`.
-- @field QUIT

--- Emitted to replace selected (found) text.
-- Arguments:
--
-- - *text*: The replacement text.
-- @field REPLACE

--- Emitted to replace all occurrences of found text.
-- Arguments:
--
-- - *find_text*: The text to search for.
-- - *repl_text*: The replacement text.
-- @field REPLACE_ALL

--- Emitted after resetting Textadept's Lua state.
-- Emitted by `reset()`.
-- Arguments:
--
-- - *persist*: Table of data persisted by `events.RESET_BEFORE`. All handlers will have access
--	to this same table.
-- @field RESET_AFTER

--- Emitted before resetting Textadept's Lua state.
-- Emitted by `reset()`.
-- Arguments:
--
-- - *persist*: Table to store persistent data in for use by `events.RESET_AFTER`. All handlers
--	will have access to this same table.
-- @field RESET_BEFORE

--- Emitted when resuming Textadept from a suspended state.
-- This event is only emitted by the terminal version.
-- @field RESUME

--- Emitted after leaving a save point.
-- @field SAVE_POINT_LEFT

--- Emitted after reaching a save point.
-- @field SAVE_POINT_REACHED

--- Emitted prior to suspending Textadept.
-- This event is only emitted by the terminal version.
-- @field SUSPEND

--- Emitted when the user clicks on a buffer tab.
-- When connecting to this event, connect with an index of 1 if the handler needs to run before
-- Textadept switches between buffers.
-- Note that Textadept always displays a context menu on right-click.
-- Arguments:
--
-- - *index*: The numeric index of the clicked tab.
-- - *button*: The mouse button number that was clicked, either `1` (left button), `2` (middle
--	button), `3` (right button), `4` (wheel up), or `5` (wheel down).
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.
-- @field TAB_CLICKED

--- Emitted when the user clicks a buffer tab's close button.
-- When connecting to this event, connect with an index of 1 if the handler needs to run before
-- Textadept closes the buffer.
-- This event is only emitted in the Qt GUI version.
-- Arguments:
--
-- - *index*: The numeric index of the clicked tab.
-- @field TAB_CLOSE_CLICKED

--- Emitted when Textadept loses focus.
-- This event is never emitted when Textadept is running in the terminal.
-- @field UNFOCUS

--- Emitted after the view is visually updated.
-- Arguments:
--
-- - *updated*: A bitmask of changes since the last update.
--
--	+ `buffer.UPDATE_CONTENT`
--		Buffer contents, styling, or markers have changed.
--	+ `buffer.UPDATE_SELECTION`
--		Buffer selection has changed (including caret movement).
--	+ `view.UPDATE_V_SCROLL`
--		View has scrolled vertically.
--	+ `view.UPDATE_H_SCROLL`
--		View has scrolled horizontally.
-- @field UPDATE_UI

--- Emitted after dragging and dropping a URI into a view.
-- Arguments:
--
-- - *text*: The UTF-8-encoded URI dropped.
-- @field URI_DROPPED

--- Emitted after selecting an item in a user list.
-- Arguments:
--
-- - *id*: The *id* from `buffer:user_list_show()`.
-- - *text*: The selection's text.
-- - *position*: The position the list was displayed at.
-- @field USER_LIST_SELECTION

--- Emitted after creating a new view.
-- The new view is `view`.
-- Emitted on startup and by `view:split()`.
-- @field VIEW_NEW

--- Emitted right before switching to another view.
-- The view being switched from is `view`.
-- Emitted by `ui.goto_view()`.
-- @field VIEW_BEFORE_SWITCH

--- Emitted right after switching to another view.
-- The view being switched to is `view`.
-- Emitted by `ui.goto_view()`.
-- @field VIEW_AFTER_SWITCH

--- Emitted after changing `view.zoom`.
-- Emitted by `view:zoom_in()` and `view:zoom_out()`.
-- @field ZOOM

--- Map of event names to tables of handler functions.
-- Handler tables are auto-created as needed.
-- @table handlers
-- @local
local handlers = setmetatable({}, {
	__index = function(t, k)
		t[k] = {}
		return t[k]
	end
})

--- Adds function *f* to the set of event handlers for event *event* at position *index*.
-- If *index* not given, appends *f* to the set of handlers. *event* may be any arbitrary string
-- and does not need to have been previously defined.
-- @param event The string event name.
-- @param f The Lua function to connect to *event*.
-- @param[opt] index Optional index to insert the handler into.
-- @usage events.connect('my_event', function(msg) ui.print(msg) end)
function M.connect(event, f, index)
	assert_type(event, 'string', 1)
	assert_type(f, 'function', 2)
	assert_type(index, 'number/nil', 3)
	M.disconnect(event, f) -- in case it already exists
	table.insert(handlers[event], index or #handlers[event] + 1, f)
end

--- Removes function *f* from the set of handlers for event *event*.
-- @param event The string event name.
-- @param f The Lua function connected to *event*.
function M.disconnect(event, f)
	assert_type(f, 'function', 2)
	for i = 1, #handlers[assert_type(event, 'string', 1)] do
		if handlers[event][i] == f then
			table.remove(handlers[event], i)
			break
		end
	end
end

local error_emitted = false
--- Sequentially calls all handler functions for event *event* with the given arguments.
-- *event* may be any arbitrary string and does not need to have been previously defined. If
-- any handler explicitly returns a value that is not `nil`, `emit()` returns that value and
-- ceases to call subsequent handlers. This is useful for stopping the propagation of an event
-- like a keypress after it has been handled, or for passing back values from handlers.
-- @param event The string event name.
-- @param[opt] ... Arguments passed to the handler.
-- @return `nil` unless any any handler explicitly returned a non-`nil` value; otherwise returns
--	that value
-- @usage events.emit('my_event', 'my message')
function M.emit(event, ...)
	local event_handlers = handlers[assert_type(event, 'string', 1)]
	local i = 1
	while i <= #event_handlers do
		local handler = event_handlers[i]
		local ok, result = pcall(handler, ...)
		if not ok then
			if not error_emitted then
				error_emitted = true
				M.emit(M.ERROR, result)
				error_emitted = false
			else
				io.stderr:write(result) -- prevent infinite loop
			end
		end
		if result ~= nil then return result end
		if event_handlers[i] == handler then i = i + 1 end -- unless M.disconnect()
	end
end

-- Handles Scintilla notifications.
M.connect('SCN', function(notification)
	local iface = _SCINTILLA.events[notification.code]
	local args = {}
	for i = 2, #iface do args[i - 1] = notification[iface[i]] end
	return M.emit(iface[1], table.unpack(args))
end)

-- Set event constants.
for _, v in pairs(_SCINTILLA.events) do M[v[1]:upper()] = v[1] end
-- LuaFormatter off
local textadept_events = {'appleevent_odoc','buffer_after_replace_text','buffer_after_switch','buffer_before_replace_text','buffer_before_switch','buffer_deleted','buffer_new','csi','command_text_changed','error','find','find_text_changed','focus','initialized','keypress','menu_clicked','mode_changed','mouse','quit','replace','replace_all','reset_after','reset_before','resume','suspend', 'tab_clicked','tab_close_clicked','unfocus','view_after_switch','view_before_switch','view_new'}
-- LuaFormatter on
for _, v in pairs(textadept_events) do M[v:upper()] = v end

-- Implement `events.BUFFER_{BEFORE,AFTER}_REPLACE_TEXT` as a convenience in lieu of the
-- undocumented `events.MODIFIED`.
local DELETE, INSERT, UNDOREDO = _SCINTILLA.constants.MOD_BEFOREDELETE,
	_SCINTILLA.constants.MOD_INSERTTEXT, _SCINTILLA.constants.MULTILINEUNDOREDO
--- Helper function for emitting `events.BUFFER_AFTER_REPLACE_TEXT` after a full-buffer undo/redo
-- operation, e.g. after reloading buffer contents and then performing an undo.
local function emit_after_replace_text()
	M.disconnect(M.UPDATE_UI, emit_after_replace_text)
	M.emit(M.BUFFER_AFTER_REPLACE_TEXT)
end
-- Emits events prior to and after replacing buffer text.
M.connect(M.MODIFIED, function(position, mod, text, length)
	if mod & (DELETE | INSERT) == 0 or length ~= buffer.length then return end
	if mod & (INSERT | UNDOREDO) == INSERT | UNDOREDO then
		-- Cannot emit BUFFER_AFTER_REPLACE_TEXT here because Scintilla will do things like update
		-- the selection afterwards, which could undo what event handlers do.
		M.connect(M.UPDATE_UI, emit_after_replace_text)
		return
	end
	M.emit(mod & DELETE > 0 and M.BUFFER_BEFORE_REPLACE_TEXT or M.BUFFER_AFTER_REPLACE_TEXT)
end)

return M

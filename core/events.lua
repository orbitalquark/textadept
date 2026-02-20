-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Textadept's core event structure and handlers.
--
-- Textadept emits events when you do things like create a new buffer, press a key, click on
-- a menu, etc. You can even emit events yourself using Lua. Each event has a set of event
-- handlers, which are simply Lua functions called in the order they were connected to an
-- event. For example, if you created a module that needs to do something each time Textadept
-- creates a new buffer, connect a Lua function to the `events.BUFFER_NEW` event:
--
-- ```lua
-- events.connect(events.BUFFER_NEW, function()
-- 	-- Do something here.
-- end)
-- ```
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

--- Adds an event handler.
-- @param event String event name to handle. It does not need to have been previously defined.
-- @param f Handler function. If it returns a non-`nil` value, subsequent handlers for *event*
--	will not be invoked when that event is emitted.
-- @param[opt] index Index to insert the handler at (typically 1 or none). If none is given,
--	*f* is appended to the list of handlers for *event*.
function M.connect(event, f, index)
	assert_type(index, 'number/nil', 3)
	M.disconnect(assert_type(event, 'string', 1), assert_type(f, 'function', 2)) -- in case it exists
	table.insert(handlers[event], index or #handlers[event] + 1, f)
end

--- Removes an event handler.
-- @param event String event name to remove a handler for.
-- @param f Handler function to remove.
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
--- Sequentially invoke all of an event's handler functions.
-- If any handler returns a non-`nil` value, subsequent handlers will not be called. This is
-- useful for stopping the propagation of an event like a keypress after it has been handled,
-- or for passing back values from handlers.
-- @param event String event name. It does not need to have been previously defined.
-- @param[opt] ... Arguments passed to each handler.
-- @return the first non-`nil` value returned by a handler, if any
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
		if event_handlers[i] == handler then i = i + 1 end -- M.disconnect() may have removed handler
	end
end

-- Handles Scintilla notifications.
-- Each notification has a code and populated data fields. _SCINTILLA maps those codes to event
-- tables with event names and the names of the event's populated data fields.
M.connect('SCN', function(notification)
	local iface = _SCINTILLA[notification.code] -- e.g. {'style_needed','position'}
	-- Note: `notification[v] or v` is a data field or event name, respectively.
	return M.emit(table.unpack(table.map(iface, function(v) return notification[v] or v end)))
end)

-- Set event constants (events are numeric ID keys).
for k, v in pairs(_SCINTILLA) do if type(k) == 'number' then M[v[1]:upper()] = v[1] end end
-- LuaFormatter off
local textadept_events = {'appleevent_odoc','buffer_after_replace_text','buffer_after_switch','buffer_before_replace_text','buffer_before_switch','buffer_deleted','buffer_new','csi','command_text_changed','error','find','find_pane_show','find_pane_hide','find_text_changed','focus','initialized','keypress','menu_clicked','mode_changed','mouse','quit','replace','replace_all','reset_after','reset_before','resume','suspend', 'tab_clicked','tab_close_clicked','unfocus','view_after_switch','view_before_switch','view_new'}
-- LuaFormatter on
for _, v in pairs(textadept_events) do M[v:upper()] = v end

return M

--- Emitted when macOS tells Textadept to open a file.
-- Arguments:
-- - *uri*: The UTF-8-encoded URI to open.
-- @field APPLEEVENT_ODOC

--- Emitted after deleting a character while an autocompletion or user list is active.
-- @field AUTO_C_CHAR_DELETED

--- Emitted when canceling an autocompletion or user list.
-- @field AUTO_C_CANCELED

--- Emitted after inserting an item from an autocompletion list into the buffer.
-- Arguments:
-- - *text*: The selection's text.
-- - *position*: The autocompleted word's beginning position.
-- - *code*: The code of the character from `buffer.auto_c_fill_ups` that made the selection,
--	or `0` if no character was used.
-- @field AUTO_C_COMPLETED

--- Emitted after selecting an item from an autocompletion list, but before inserting that item
-- into the buffer.
-- Calling `buffer:auto_c_cancel()` from an event handler will prevent automatic insertion.
--
-- Arguments:
-- - *text*: The selection's text.
-- - *position*: The autocompleted word's beginning position.
-- - *code*: The code of the character from `buffer.auto_c_fill_ups` that made the selection,
--	or `0` if no character was used.
-- @field AUTO_C_SELECTION

--- Emitted as items are highlighted in an autocompletion or user list.
-- Arguments:
-- - *id*: Either the *id* from `buffer:user_list_show()` or `0` for an autocompletion list.
-- - *text*: The current selection's text.
-- - *position*: The position the list was displayed at.
-- @field AUTO_C_SELECTION_CHANGE

--- Emitted after switching to another buffer.
-- The buffer being switched to is `buffer`.
-- @see view.goto_buffer
-- @field BUFFER_AFTER_SWITCH

--- Emitted before replacing the contents of the current buffer.
-- Note that it is not guaranteed that `events.BUFFER_AFTER_REPLACE_TEXT` will be emitted
-- shortly after this event.
-- The buffer **must not** be modified during this event.
-- @field BUFFER_BEFORE_REPLACE_TEXT

--- Emitted before switching to another buffer.
-- The buffer being switched from is `buffer`.
-- @see view.goto_buffer
-- @see buffer.new
-- @field BUFFER_BEFORE_SWITCH

--- Emitted after replacing the contents of the current buffer.
-- Note that it is not guaranteed that `events.BUFFER_BEFORE_REPLACE_TEXT` was emitted previously.
-- The buffer **must not** be modified during this event.
-- @field BUFFER_AFTER_REPLACE_TEXT

--- Emitted after deleting a buffer.
-- Arguments:
-- - *buffer*: Simple representation of the deleted buffer. Buffer operations cannot be performed
--	on it, but fields like `buffer.filename` can be read.
-- @see buffer.delete
-- @field BUFFER_DELETED

--- Emitted after creating a new buffer.
-- The new buffer is `buffer`.
-- @see buffer.new
-- @field BUFFER_NEW

--- Emitted when clicking on a calltip.
-- This event is not emitted by the Qt version.
--
-- Arguments:
-- - *position*: `1` if the up arrow was clicked, `2` if the down arrow was clicked, and `0`
--	otherwise.
-- @field CALL_TIP_CLICK

--- Emitted after the user types a text character into the buffer.
-- Arguments:
-- - *code*: The text character's character code.
-- @field CHAR_ADDED

--- Emitted when the text in the command entry changes.
-- `ui.command_entry:get_text()` returns the current text.
-- @field COMMAND_TEXT_CHANGED

--- Emitted after double-clicking the mouse button.
-- Arguments:
-- - *position*: The position double-clicked.
-- - *line*: The position's line number.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field DOUBLE_CLICK

--- Emitted when the terminal version receives an unrecognized CSI sequence.
-- Arguments:
-- - *cmd*: The 24-bit CSI command value. The lowest byte contains the command byte. The second
--	lowest byte contains the leading byte, if any (e.g. '?'). The third lowest byte contains
--	the intermediate byte, if any (e.g. '$').
-- - *args*: Table of numeric arguments of the CSI sequence.
-- @field CSI

--- Emitted after `events.DWELL_START` when the user moves the mouse, presses a key, or scrolls
-- the view.
-- Arguments:
-- - *position*: The position closest to *x* and *y*.
-- - *x*: The x-coordinate of the mouse in the view.
-- - *y*: The y-coordinate of the mouse in the view.
-- @field DWELL_END

--- Emitted when the mouse is stationary for `view.mouse_dwell_time` milliseconds.
-- Arguments:
-- - *position*: The position closest to *x* and *y*.
-- - *x*: The x-coordinate of the mouse in the view.
-- - *y*: The y-coordinate of the mouse in the view.
-- @field DWELL_START

--- Emitted when an error occurs.
-- Arguments:
-- - *text*: The error message text.
-- @field ERROR

--- Emitted when Textadept shows the find & replace pane.
-- @field FIND_PANE_SHOW

--- Emitted when Textadept hides the find & replace pane.
-- @field FIND_PANE_HIDE

--- Emitted to find text.
-- `ui.find` contains active find options.
--
-- Arguments:
-- - *text*: The text to search for.
-- - *next*: Whether or not to search forward instead of backward.
-- @see ui.find.find_next
-- @see ui.find.find_prev
-- @field FIND

--- Emitted when the text in the "Find" field of the find & replace pane changes.
-- `ui.find.find_entry_text` contains the current text.
-- @field FIND_TEXT_CHANGED

--- Emitted when Textadept receives focus.
-- This event is never emitted when Textadept is running in the terminal.
-- @field FOCUS

--- Emitted when clicking the mouse on text within an [indicator range](#mark-text-with-indicators).
-- Arguments:
-- - *position*: The clicked text's position.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field INDICATOR_CLICK

--- Emitted when releasing the mouse after clicking on text within an [indicator
-- range](#mark-text-with-indicators).
-- Arguments:
-- - *position*: The clicked text's position.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field INDICATOR_RELEASE

--- Emitted after Textadept finishes initializing.
-- @field INITIALIZED

--- Emitted when clicking the mouse inside a sensitive margin.
-- Arguments:
-- - *margin*: The margin number clicked.
-- - *position*: The position of the beginning of the clicked margin's line.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field MARGIN_CLICK

--- Emitted when right-clicking the mouse inside a sensitive margin.
-- Arguments:
-- - *margin*: The margin number right-clicked.
-- - *position*: The position of the beginning of the clicked margin's line.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field MARGIN_RIGHT_CLICK

--- Emitted after selecting a menu item.
-- Arguments:
-- - *menu_id*: The numeric ID of the menu item, which was defined in `ui.menu()`.
-- @field MENU_CLICKED

--- Emitted by the GUI version when switching between light mode and dark mode.
-- Arguments:
-- - *mode*: Either "light" or "dark".
-- @field MODE_CHANGED

--- Emitted by the terminal version for an unhandled mouse event.
-- A handler should return `true` if it handled the event. Otherwise Textadept will try again.
-- (This side effect for `nil` return is useful for sending the original mouse event to a
-- different view that a handler has switched to.)
--
-- Arguments:
-- - *event*: The mouse event: `view.MOUSE_PRESS`, `view.MOUSE_DRAG`, or `view.MOUSE_RELEASE`.
-- - *button*: The mouse button number.
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`, `view.MOD_SHIFT`,
--	and `view.MOD_ALT`.
-- - *y*: The y-coordinate of the mouse event, starting from 1.
-- - *x*: The x-coordinate of the mouse event, starting from 1.
-- @field MOUSE

--- Emitted when quitting Textadept.
-- The default behavior is to close all buffers and, if that was successful, quit the application.
-- In order to do something before Textadept closes all open buffers, connect to this event with
-- an index of `1`. If a handler returns `true`, Textadept does not quit. It is not recommended
-- to return `false` from a quit handler, as that may interfere with Textadept's normal shutdown
-- procedure.
-- @see quit
-- @field QUIT

--- Emitted to replace selected (found) text.
-- `ui.find` contains active find options.
--
-- Arguments:
-- - *text*: The replacement text.
-- @see ui.find.replace
-- @field REPLACE

--- Emitted to replace all occurrences of found text.
-- `ui.find` contains active find options.
--
-- Arguments:
-- - *find_text*: The text to search for.
-- - *repl_text*: The replacement text.
-- @see ui.find.replace_all
-- @field REPLACE_ALL

--- Emitted after resetting Textadept's Lua state.
-- Arguments:
-- - *persist*: Table of data persisted by `events.RESET_BEFORE`. All handlers will have access
--	to this same table.
-- @see reset
-- @field RESET_AFTER

--- Emitted before resetting Textadept's Lua state.
-- Arguments:
-- - *persist*: Table to store persistent data in for use by `events.RESET_AFTER`. All handlers
--	will have access to this same table.
-- @see reset
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
-- The default behavior is to switch to the clicked tab's buffer. In order to do something
-- before the switch, connect to this event with an index of `1`.
--
-- Note that Textadept always displays a context menu for a right-click.
--
-- Arguments:
-- - *index*: The numeric index of the clicked tab.
-- - *button*: The mouse button number that was clicked, either `1` (left button), `2` (middle
--	button), `3` (right button), `4` (wheel up), or `5` (wheel down).
-- - *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
--	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
--	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
--	`view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
--	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.
-- @field TAB_CLICKED

--- Emitted when the user clicks a buffer tab's close button.
-- The default behavior is to close the tab's buffer. If you need to do something before
-- Textadept closes the buffer, connect to this event with an index of `1`.
--
-- This event is only emitted in the Qt version.
--
-- Arguments:
-- - *index*: The numeric index of the clicked tab.
-- @field TAB_CLOSE_CLICKED

--- Emitted when Textadept loses focus.
-- This event is never emitted when Textadept is running in the terminal.
-- @field UNFOCUS

--- Emitted after the view is visually updated.
-- Arguments:
-- - *updated*: A bitmask of changes since the last update.
--
--	+ `buffer.UPDATE_CONTENT`
--		The buffer's contents, styling, or markers have changed.
--	+ `buffer.UPDATE_SELECTION`
--		The buffer's selection has changed (including caret movement).
--	+ `view.UPDATE_V_SCROLL`
--		The view has scrolled vertically.
--	+ `view.UPDATE_H_SCROLL`
--		The view has scrolled horizontally.
-- @field UPDATE_UI

--- Emitted after dragging and dropping a URI into a view.
-- Arguments:
-- - *text*: The UTF-8-encoded URI dropped.
-- @field URI_DROPPED

--- Emitted after selecting an item in a user list.
-- Arguments:
-- - *id*: The *id* from `buffer:user_list_show()`.
-- - *text*: The selection's text.
-- - *position*: The position the list was displayed at.
-- @field USER_LIST_SELECTION

--- Emitted after creating a new view.
-- The new view is `view`.
-- @see view.split
-- @field VIEW_NEW

--- Emitted before switching to another view.
-- The view being switched from is `view`.
-- @see ui.goto_view
-- @see view.split
-- @field VIEW_BEFORE_SWITCH

--- Emitted after switching to another view.
-- The view being switched to is `view`.
-- @see ui.goto_view
-- @field VIEW_AFTER_SWITCH

--- Emitted after changing `view.zoom`.
-- @see view.zoom_in
-- @see view.zoom_out
-- @field ZOOM

-- Undocumented events.
-- src/textadept.c does not pass all of the listed event parameters.
-- - STYLE_NEEDED (position)
-- - MODIFY_ATTEMPT_RO
-- - KEY (ch, modifiers)
-- - MODIFIED (position, modification_type, text, length, lines_added, line, fold_level_now,
-- 	fold_level_prev, token, annotation_lines_added)
-- - MACRORECORD (message, w_param, l_param)
-- - NEED_SHOWN (position, length)
-- - PAINTED
-- - HOT_SPOT_CLICK (position, modifiers)
-- - HOT_SPOT_DOUBLE_CLICK (position, modifiers)
-- - HOT_SPOT_RELEASE_CLICK (position, modifiers)
-- - FOCUS_IN
-- - FOCUS_OUT

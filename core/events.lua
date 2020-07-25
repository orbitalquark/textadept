-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Textadept's core event structure and handlers.
--
-- Textadept emits events when you do things like create a new buffer, press a
-- key, click on a menu, etc. You can even emit events yourself using Lua. Each
-- event has a set of event handlers, which are simply Lua functions called in
-- the order they were connected to an event. For example, if you created a
-- module that needs to do something each time Textadept creates a new buffer,
-- connect a Lua function to the [`events.BUFFER_NEW`]() event:
--
--     events.connect(events.BUFFER_NEW, function()
--       -- Do something here.
--     end)
--
-- Events themselves are nothing special. You do not have to declare one before
-- using it. Events are simply strings containing arbitrary event names. When
-- either you or Textadept emits an event, Textadept runs all event handlers
-- connected to the event, passing any given arguments to the event's handler
-- functions. If an event handler explicitly returns a value that is not `nil`,
-- Textadept will not call subsequent handlers. This is useful if you want to
-- stop the propagation of an event like a keypress if your event handler
-- handled it, or if you want to use the event framework to pass values.
--
-- @field APPLEEVENT_ODOC (string)
--   Emitted when Mac OSX tells Textadept to open a file.
--   Arguments:
--
--   * _`uri`_: The UTF-8-encoded URI to open.
-- @field AUTO_C_CHAR_DELETED (string)
--   Emitted after deleting a character while an autocompletion or user list is
--   active.
-- @field AUTO_C_CANCELED (string)
--   Emitted when canceling an autocompletion or user list.
-- @field AUTO_C_COMPLETED (string)
--   Emitted after inserting an item from an autocompletion list into the
--   buffer.
--   Arguments:
--
--   * _`text`_: The selection's text.
--   * _`position`_: The autocompleted word's beginning position.
-- @field AUTO_C_SELECTION (string)
--   Emitted after selecting an item from an autocompletion list, but before
--   inserting that item into the buffer.
--   Automatic insertion can be canceled by calling
--   [`buffer:auto_c_cancel()`]() before returning from the event handler.
--   Arguments:
--
--   * _`text`_: The selection's text.
--   * _`position`_: The autocompleted word's beginning position.
-- @field AUTO_C_SELECTION_CHANGE (string)
--   Emitted as items are highlighted in an autocompletion or user list.
--   Arguments:
--
--   * _`id`_: Either the *id* from [`buffer.user_list_show()`]() or `0` for an
--     autocompletion list.
--   * _`text`_: The current selection's text.
--   * _`position`_: The position the list was displayed at.
-- @field BUFFER_AFTER_SWITCH (string)
--   Emitted right after switching to another buffer.
--   Emitted by [`view.goto_buffer()`]().
-- @field BUFFER_BEFORE_SWITCH (string)
--   Emitted right before switching to another buffer.
--   Emitted by [`view.goto_buffer()`]().
-- @field BUFFER_DELETED (string)
--   Emitted after deleting a buffer.
--   Emitted by [`buffer.delete()`]().
-- @field BUFFER_NEW (string)
--   Emitted after creating a new buffer.
--   The new buffer is `buffer`.
--   Emitted on startup and by [`buffer.new()`]().
-- @field CALL_TIP_CLICK (string)
--   Emitted when clicking on a calltip.
--   Arguments:
--
--   * _`position`_: `1` if the up arrow was clicked, 2 if the down arrow was
--     clicked, and 0 otherwise.
-- @field CHAR_ADDED (string)
--   Emitted after the user types a text character into the buffer.
--   Arguments:
--
--   * _`code`_: The text character's character code.
-- @field DOUBLE_CLICK (string)
--   Emitted after double-clicking the mouse button.
--   Arguments:
--
--   * _`position`_: The position double-clicked.
--   * _`line`_: The line number of the position double-clicked.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `view.MOD_CTRL`,
--     `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`.
--     On Mac OSX, the Command modifier key is reported as `view.MOD_CTRL` and
--     Ctrl is `view.MOD_META`.
--     Note: If you set `view.rectangular_selection_modifier` to
--     `view.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK.
-- @field CSI (string)
--   Emitted when the terminal version receives an unrecognized CSI sequence.
--   Arguments:
--
--   * _`cmd`_: The 24-bit CSI command value. The lowest byte contains the
--     command byte. The second lowest byte contains the leading byte, if any
--     (e.g. '?'). The third lowest byte contains the intermediate byte, if any
--     (e.g. '$').
--   * _`args`_: Table of numeric arguments of the CSI sequence.
-- @field DWELL_END (string)
--   Emitted after `DWELL_START` when the user moves the mouse, presses a key,
--   or scrolls the view.
--   Arguments:
--
--   * _`position`_: The position closest to *x* and *y*.
--   * _`x`_: The x-coordinate of the mouse in the view.
--   * _`y`_: The y-coordinate of the mouse in the view.
-- @field DWELL_START (string)
--   Emitted when the mouse is stationary for [`view.mouse_dwell_time`]()
--   milliseconds.
--   Arguments:
--
--   * _`position`_: The position closest to *x* and *y*.
--   * _`x`_: The x-coordinate of the mouse in the view.
--   * _`y`_: The y-coordinate of the mouse in the view.
-- @field ERROR (string)
--   Emitted when an error occurs.
--   Arguments:
--
--   * _`text`_: The error message text.
-- @field FIND (string)
--   Emitted to find text via the Find & Replace Pane.
--   Arguments:
--
--   * _`text`_: The text to search for.
--   * _`next`_: Whether or not to search forward.
-- @field FIND_TEXT_CHANGED (string)
--   Emitted when the text in the "Find" field of the Find & Replace Pane
--   changes.
--   `ui.find.find_entry_text` contains the current text.
-- @field FOCUS (string)
--   Emitted when Textadept receives focus.
--   This event is never emitted when Textadept is running in the terminal.
-- @field INDICATOR_CLICK (string)
--   Emitted when clicking the mouse on text that has an indicator present.
--   Arguments:
--
--   * _`position`_: The clicked text's position.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `view.MOD_CTRL`,
--     `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`.
--     On Mac OSX, the Command modifier key is reported as `view.MOD_CTRL` and
--     Ctrl is `view.MOD_META`.
--     Note: If you set `view.rectangular_selection_modifier` to
--     `view.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK.
-- @field INDICATOR_RELEASE (string)
--   Emitted when releasing the mouse after clicking on text that has an
--   indicator present.
--   Arguments:
--
--   * _`position`_: The clicked text's position.
-- @field INITIALIZED (string)
--   Emitted after Textadept finishes initializing.
-- @field KEYPRESS (string)
--   Emitted when pressing a key.
--   If any handler returns `true`, the key is not inserted into the buffer.
--   Arguments:
--
--   * _`code`_: The numeric key code.
--   * _`shift`_: The "Shift" modifier key is held down.
--   * _`ctrl`_: The "Control" modifier key is held down.
--   * _`alt`_: The "Alt"/"Option" modifier key is held down.
--   * _`cmd`_: The "Command" modifier key on Mac OSX is held down.
--   * _`caps_lock`_: The "Caps Lock" modifier is on.
-- @field MARGIN_CLICK (string)
--   Emitted when clicking the mouse inside a sensitive margin.
--   Arguments:
--
--   * _`margin`_: The margin number clicked.
--   * _`position`_: The beginning position of the clicked margin's line.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `view.MOD_CTRL`,
--     `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`.
--     On Mac OSX, the Command modifier key is reported as `view.MOD_CTRL` and
--     Ctrl is `view.MOD_META`.
--     Note: If you set `view.rectangular_selection_modifier` to
--     `view.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK.
-- @field MENU_CLICKED (string)
--   Emitted after selecting a menu item.
--   Arguments:
--
--   * _`menu_id`_: The numeric ID of the menu item, which was defined in
--     [`ui.menu()`]().
-- @field MOUSE (string)
--   Emitted by the terminal version for an unhandled mouse event.
--   A handler should return `true` if it handled the event. Otherwise Textadept
--   will try again. (This side effect for a `false` or `nil` return is useful
--   for sending the original mouse event to a different view that a handler
--   has switched to.)
--   Arguments:
--
--   * _`event`_: The mouse event: `view.MOUSE_PRESS`, `view.MOUSE_DRAG`, or
--     `view.MOUSE_RELEASE`.
--   * _`button`_: The mouse button number.
--   * _`y`_: The y-coordinate of the mouse event, starting from 1.
--   * _`x`_: The x-coordinate of the mouse event, starting from 1.
--   * _`shift`_: The "Shift" modifier key is held down.
--   * _`ctrl`_: The "Control" modifier key is held down.
--   * _`alt`_: The "Alt"/"Option" modifier key is held down.
-- @field QUIT (string)
--   Emitted when quitting Textadept.
--   When connecting to this event, connect with an index of 1 if the handler
--   needs to run before Textadept closes all open buffers. If a handler returns
--   `true`, Textadept does not quit. It is not recommended to return `false`
--   from a quit handler, as that may interfere with Textadept's normal shutdown
--   procedure.
--   Emitted by [`quit()`]().
-- @field REPLACE (string)
--   Emitted to replace selected (found) text.
--   Arguments:
--
--   * _`text`_: The replacement text.
-- @field REPLACE_ALL (string)
--   Emitted to replace all occurrences of found text.
--   Arguments:
--
--   * _`find_text`_: The text to search for.
--   * _`repl_text`_: The replacement text.
-- @field RESET_AFTER (string)
--   Emitted after resetting the Lua state.
--   Emitted by [`reset()`]().
--   Arguments:
--
--   * _`persist`_: Table of data persisted by `events.RESET_BEFORE`. All
--     handlers will have access to this same table.
-- @field RESET_BEFORE (string)
--   Emitted before resetting the Lua state.
--   Emitted by [`reset()`]().
--   Arguments:
--
--   * _`persist`_: Table to store persistent data in for use by
--     `events.RESET_AFTER`. All handlers will have access to this same table.
-- @field RESUME (string)
--   Emitted when resuming Textadept from a suspended state.
--   This event is only emitted by the terminal version.
-- @field SAVE_POINT_LEFT (string)
--   Emitted after leaving a save point.
-- @field SAVE_POINT_REACHED (string)
--   Emitted after reaching a save point.
-- @field SUSPEND (string)
--   Emitted when suspending Textadept. If any handler returns `true`, Textadept
--   does not suspend.
--   This event is only emitted by the terminal version.
-- @field TAB_CLICKED (string)
--   Emitted when the user clicks on a buffer tab.
--   When connecting to this event, connect with an index of 1 if the handler
--   needs to run before Textadept switches between buffers.
--   Note that Textadept always displays a context menu on right-click.
--   Arguments:
--
--   * _`index`_: The numeric index of the clicked tab.
--   * _`button`_: The mouse button number that was clicked, either `1` (left
--     button), `2` (middle button), `3` (right button), `4` (wheel up), or `5`
--    (wheel down).
--   * _`shift`_: The "Shift" modifier key is held down.
--   * _`ctrl`_: The "Control" modifier key is held down.
--   * _`alt`_: The "Alt"/"Option" modifier key is held down.
--   * _`cmd`_: The "Command" modifier key on Mac OSX is held down.
-- @field UPDATE_UI (string)
--   Emitted after the view is visually updated.
--   Arguments:
--
--   * _`updated`_: A bitmask of changes since the last update.
--
--     + `buffer.UPDATE_CONTENT`
--       Buffer contents, styling, or markers have changed.
--     + `buffer.UPDATE_SELECTION`
--       Buffer selection has changed (including caret movement).
--     + `view.UPDATE_V_SCROLL`
--       Buffer has scrolled vertically.
--     + `view.UPDATE_H_SCROLL`
--       Buffer has scrolled horizontally.
-- @field URI_DROPPED (string)
--   Emitted after dragging and dropping a URI into a view.
--   Arguments:
--
--   * _`text`_: The UTF-8-encoded URI dropped.
-- @field USER_LIST_SELECTION (string)
--   Emitted after selecting an item in a user list.
--   Arguments:
--
--   * _`id`_: The *id* from [`buffer.user_list_show()`]().
--   * _`text`_: The selection's text.
--   * _`position`_: The position the list was displayed at.
-- @field VIEW_NEW (string)
--   Emitted after creating a new view.
--   The new view is `view`.
--   Emitted on startup and by [`view.split()`]().
-- @field VIEW_BEFORE_SWITCH (string)
--   Emitted right before switching to another view.
--   Emitted by [`ui.goto_view()`]().
-- @field VIEW_AFTER_SWITCH (string)
--   Emitted right after switching to another view.
--   Emitted by [`ui.goto_view()`]().
-- @field ZOOM (string)
--   Emitted after changing [`view.zoom`]().
--   Emitted by [`view.zoom_in()`]() and [`view.zoom_out()`]().
module('events')]]

-- Map of event names to tables of handler functions.
-- Handler tables are auto-created as needed.
-- @class table
-- @name handlers
local handlers = setmetatable({}, {__index = function(t, k)
  t[k] = {}
  return t[k]
end})

---
-- Adds function *f* to the set of event handlers for event *event* at position
-- *index*.
-- If *index* not given, appends *f* to the set of handlers. *event* may be any
-- arbitrary string and does not need to have been previously defined.
-- @param event The string event name.
-- @param f The Lua function to connect to *event*.
-- @param index Optional index to insert the handler into.
-- @usage events.connect('my_event', function(msg) ui.print(msg) end)
-- @see disconnect
-- @name connect
function M.connect(event, f, index)
  assert_type(event, 'string', 1)
  assert_type(f, 'function', 2)
  assert_type(index, 'number/nil', 3)
  M.disconnect(event, f) -- in case it already exists
  table.insert(handlers[event], index or #handlers[event] + 1, f)
end

---
-- Removes function *f* from the set of handlers for event *event*.
-- @param event The string event name.
-- @param f The Lua function connected to *event*.
-- @see connect
-- @name disconnect
function M.disconnect(event, f)
  assert_type(f, 'function', 2)
  for i = 1, #handlers[assert_type(event, 'string', 1)] do
    if handlers[event][i] == f then table.remove(handlers[event], i) break end
  end
end

local error_emitted = false
---
-- Sequentially calls all handler functions for event *event* with the given
-- arguments.
-- *event* may be any arbitrary string and does not need to have been previously
-- defined. If any handler explicitly returns a value that is not `nil`,
-- `emit()` returns that value and ceases to call subsequent handlers. This is
-- useful for stopping the propagation of an event like a keypress after it has
-- been handled, or for passing back values from handlers.
-- @param event The string event name.
-- @param ... Arguments passed to the handler.
-- @return `nil` unless any any handler explicitly returned a non-`nil` value;
--   otherwise returns that value
-- @usage events.emit('my_event', 'my message')
-- @name emit
function M.emit(event, ...)
  local event_handlers = handlers[assert_type(event, 'string', 1)]
  local i = 1
  while i <= #event_handlers do
    local handler = event_handlers[i]
    local ok, result = pcall(handler, ...)
    if not ok then
      if not error_emitted then
        error_emitted = true
        M.emit(events.ERROR, result)
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
  local f = _SCINTILLA.events[notification.code]
  if not f then return end
  local args = {}
  for i = 2, #f do args[i - 1] = notification[f[i]] end
  return M.emit(f[1], table.unpack(args))
end)

-- Set event constants.
for _, v in pairs(_SCINTILLA.events) do M[v[1]:upper()] = v[1] end
local textadept_events = { -- defined in C
  'appleevent_odoc', 'buffer_after_switch', 'buffer_before_switch',
  'buffer_deleted', 'buffer_new', 'csi', 'error', 'find', 'find_text_changed',
  'focus', 'initialized', 'keypress', 'menu_clicked', 'mouse', 'quit',
  'replace', 'replace_all', 'reset_after', 'reset_before', 'resume', 'suspend',
  'tab_clicked', 'view_after_switch', 'view_before_switch', 'view_new'
}
for _, v in pairs(textadept_events) do M[v:upper()] = v end

return M

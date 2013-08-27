-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Textadept's core event structure and handlers.
--
-- ## Overview
--
-- Textadept emits events when you do things like create a new buffer, press a
-- key, click on a menu, etc. You can even emit events yourself using Lua. Each
-- event has a set of event handlers, which are simply Lua functions called in
-- the order they were connected to an event. For example, if you created a
-- module that needs to do something each time Textadept creates a new buffer,
-- connect a Lua function to the [BUFFER_NEW](#BUFFER_NEW) event:
--
--     events.connect(events.BUFFER_NEW, function()
--       -- Do something here.
--     end)
--
-- Events themselves are nothing special. You do not have to declare one before
-- using it. Events are simply strings containing arbitrary event names. When
-- either you or Textadept emits an event, Textadept runs all event handlers
-- connected to the event, passing any given arguments to the event's handler
-- functions. If an event handler explicitly returns a `true` or `false` boolean
-- value, Textadept will not call subsequent handlers. This is useful if you
-- want to stop the propagation of an event like a keypress if your event
-- handler handled it.
--
-- @field APPLEEVENT_ODOC (string)
--   Emitted when Mac OSX tells Textadept to open a document.
--   Arguments:
--
--   * _`uri`_: The UTF-8-encoded URI to open.
-- @field AUTO_C_CHAR_DELETED (string)
--   Emitted when deleting a character while the autocompletion list is active.
-- @field AUTO_C_RELEASE (string)
--   Emitted when canceling the autocompletion list.
-- @field AUTO_C_SELECTION (string)
--   Emitted when selecting an item in the autocompletion list and before
--   inserting the selection.
--   Automatic insertion can be cancelled by calling
--   [`buffer:auto_c_cancel()`][] before returning from the event handler.
--   Arguments:
--
--   * _`text`_: The text of the selection.
--   * _`position`_: The position in the buffer of the beginning of the
--     autocompleted word.
-- @field BUFFER_AFTER_SWITCH (string)
--   Emitted right after switching to another buffer.
--   Emitted by [`view:goto_buffer()`][].
-- @field BUFFER_BEFORE_SWITCH (string)
--   Emitted right before switching to another buffer.
--   Emitted by [`view:goto_buffer()`][].
-- @field BUFFER_DELETED (string)
--   Emitted after deleting a buffer.
--   Emitted by [`buffer:delete()`][].
-- @field BUFFER_NEW (string)
--   Emitted after creating a new buffer.
--   Emitted on startup and by [`buffer.new()`][].
-- @field CALL_TIP_CLICK (string)
--   Emitted when clicking on a calltip.
--   Arguments:
--
--   * _`position`_: `1` if the up arrow was clicked, 2 if the down arrow was
--     clicked, and 0 otherwise.
-- @field CHAR_ADDED (string)
--   Emitted after adding an ordinary text character to the buffer.
--   Arguments:
--
--   * _`ch`_: The text character byte.
-- @field COMMAND_ENTRY_KEYPRESS (string)
--   Emitted when pressing a key in the Command Entry.
--   If any handler returns `true`, the key is not inserted into the entry.
--   Arguments:
--
--   * _`code`_: The numeric key code.
--   * _`shift`_: The "Shift" modifier key is held down.
--   * _`ctrl`_: The "Control"/"Command" modifier key is held down.
--   * _`alt`_: The "Alt"/"Option" modifier key is held down.
--   * _`meta`_: The "Control" modifier key on Mac OSX is held down.
-- @field DOUBLE_CLICK (string)
--   Emitted after double-clicking the mouse button.
--   Arguments:
--
--   * _`position`_: The position in the buffer double-clicked.
--   * _`line`_: The line number double-clicked.
--   * _`modifiers`_: A bit-mask of modifier keys held down. Modifiers are
--     `buffer.SCMOD_ALT`, `buffer.SCMOD_CTRL`, `buffer.SCMOD_SHIFT`, and
--     `buffer.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.SCMOD_CTRL`, the "Control" modifier is reported as *both*
--     "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field DWELL_END (string)
--   Emitted after a `DWELL_START` when the mouse moves, a key is pressed, etc.
--   Arguments:
--
--   * _`position`_: The position in the buffer closest to *x* and *y*.
--   * _`x`_: The x-coordinate of the mouse in the view.
--   * _`y`_: The y-coordinate of the mouse in the view.
-- @field DWELL_START (string)
--   Emitted after keeping the mouse stationary for the [dwell period][]
--   Arguments:
--
--   * _`position`_: The position in the buffer closest to *x* and *y*.
--   * _`x`_: The x-coordinate of the mouse in the view.
--   * _`y`_: The y-coordinate of the mouse in the view.
-- @field ERROR (string)
--   Emitted when an error occurs.
--   Arguments:
--
--   * _`text`_: The error text.
-- @field FIND (string)
--   Emitted to find text via the Find dialog box.
--   Arguments:
--
--   * _`text`_: The text to search for.
--   * _`next`_: Whether or not to search forward.
-- @field HOTSPOT_CLICK (string)
--   Emitted when clicking on text that is in a style with the hotspot attribute
--   set.
--   Arguments:
--
--   * _`position`_: The position in the buffer clicked.
--   * _`modifiers`_: A bit-mask of modifier keys held down. Modifiers are
--     `buffer.SCMOD_ALT`, `buffer.SCMOD_CTRL`, `buffer.SCMOD_SHIFT`, and
--     `buffer.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.SCMOD_CTRL`, the "Control" modifier is reported as *both*
--     "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_DOUBLE_CLICK (string)
--   Emitted when double-clicking on text that is in a style with the hotspot
--   attribute set.
--   Arguments:
--
--   * _`position`_: The position in the buffer double-clicked.
--   * _`modifiers`_: A bit-mask of modifier keys held down. Modifiers are
--     `buffer.SCMOD_ALT`, `buffer.SCMOD_CTRL`, `buffer.SCMOD_SHIFT`, and
--     `buffer.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.SCMOD_CTRL`, the "Control" modifier is reported as *both*
--     "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_RELEASE_CLICK (string)
--   Emitted after releasing the mouse after clicking on text that was in a
--   style with the hotspot attribute set.
--   Arguments:
--
--   * _`position`_: The position in the buffer unclicked.
-- @field INDICATOR_CLICK (string)
--   Emitted when clicking the mouse on text that has an indicator.
--   Arguments:
--
--   * _`position`_: The position in the buffer clicked.
--   * _`modifiers`_: A bit-mask of modifier keys held down. Modifiers are
--     `buffer.SCMOD_ALT`, `buffer.SCMOD_CTRL`, `buffer.SCMOD_SHIFT`, and
--     `buffer.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.SCMOD_CTRL`, the "Control" modifier is reported as *both*
--     "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field INDICATOR_RELEASE (string)
--   Emitted after releasing the mouse after clicking on text that had an
--   indicator.
--   Arguments:
--
--   * _`position`_: The position in the buffer unclicked.
-- @field KEYPRESS (string)
--   Emitted when pressing a key.
--   If any handler returns `true`, the key is not inserted into the buffer.
--   Arguments:
--
--   * _`code`_: The numeric key code.
--   * _`shift`_: The "Shift" modifier key is held down.
--   * _`ctrl`_: The "Control"/"Command" modifier key is held down.
--   * _`alt`_: The "Alt"/"Option" modifier key is held down.
--   * _`meta`_: The "Control" modifier key on Mac OSX is held down.
-- @field MARGIN_CLICK (string)
--   Emitted when clicking the mouse inside a margin.
--   Arguments:
--
--   * _`margin`_: The margin number clicked.
--   * _`position`_: The position of the start of the line in the buffer whose
--     margin line was clicked.
--   * _`modifiers`_: A bit-mask of modifier keys held down. Modifiers are
--     `buffer.SCMOD_ALT`, `buffer.SCMOD_CTRL`, `buffer.SCMOD_SHIFT`, and
--     `buffer.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.SCMOD_CTRL`, the "Control" modifier is reported as *both*
--     "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field MENU_CLICKED (string)
--   Emitted after selecting a menu item.
--   Arguments:
--
--   * _`menu_id`_: The numeric ID of the menu item set in [`ui.menu()`][].
-- @field QUIT (string)
--   Emitted when quitting Textadept.
--   When connecting to this event, connect with an index of 1 or the handler
--   will be ignored.
--   Emitted by [`quit()`][].
-- @field REPLACE (string)
--   Emitted to replace selected (found) text.
--   Arguments:
--
--   * _`text`_: The text to replace the selected text with.
-- @field REPLACE_ALL (string)
--   Emitted to replace all occurrences of found text.
--   Arguments:
--
--   * _`find_text`_: The text to search for.
--   * _`repl_text`_: The text to replace found text with.
-- @field RESET_AFTER (string)
--   Emitted after resetting the Lua state.
--   Emitted by [`reset()`][].
-- @field RESET_BEFORE (string)
--   Emitted before resetting the Lua state.
--   Emitted by [`reset()`][].
-- @field SAVE_POINT_LEFT (string)
--   Emitted after leaving a save point.
-- @field SAVE_POINT_REACHED (string)
--   Emitted after reaching a save point.
-- @field UPDATE_UI (string)
--   Emitted when the text, styling, or selection range in the buffer changes.
-- @field URI_DROPPED (string)
--   Emitted after dragging and dropping a URI such as a file name onto the
--   view.
--   Arguments:
--
--   * _`text`_: The UTF-8-encoded URI text.
-- @field USER_LIST_SELECTION (string)
--   Emitted after selecting an item in a user list.
--   Arguments:
--
--   * _`list_type`_: The *list_type* from [`buffer:user_list_show()`][].
--   * _`text`_: The text of the selection.
--   * _`position`_: The position in the buffer the list was displayed at.
-- @field VIEW_NEW (string)
--   Emitted after creating a new view.
--   Emitted on startup and by [`view:split()`][].
-- @field VIEW_BEFORE_SWITCH (string)
--   Emitted right before switching to another view.
--   Emitted by [`ui.goto_view()`][].
-- @field VIEW_AFTER_SWITCH (string)
--   Emitted right after switching to another view.
--   Emitted by [`ui.goto_view()`][].
--
-- [`buffer:auto_c_cancel()`]: buffer.html#auto_c_cancel
-- [`view:goto_buffer()`]: view.html#goto_buffer
-- [`buffer.new()`]: buffer.html#new
-- [`buffer:delete()`]: buffer.html#delete
-- [dwell period]: buffer.html#mouse_dwell_time
-- [`ui.menu()`]: ui.html#menu
-- [`quit()`]: _G.html#quit
-- [`reset()`]: _G.html#reset
-- [`buffer:user_list_show()`]: buffer.html#user_list_show
-- [`view:split()`]: view.html#split
-- [`ui.goto_view()`]: ui.html#goto_view
module('events')]]

local handlers = {}

---
-- Adds function *f* to the set of event handlers for *event* at position
-- *index*, returning a handler ID for *f*. *event* is an arbitrary event name
-- that does not need to have been previously defined.
-- @param event The string event name.
-- @param f The Lua function to connect to *event*.
-- @param index Optional index to insert the handler into.
-- @return handler ID.
-- @usage events.connect('my_event', function(msg) ui.print(msg) end)
-- @see disconnect
-- @name connect
function M.connect(event, f, index)
  if not event then error(_L['Undefined event name']) end
  if not handlers[event] then handlers[event] = {} end
  local h = handlers[event]
  if index then table.insert(h, index, f) else h[#h + 1] = f end
  return index or #h
end

---
-- Removes handler ID *id*, returned by `events.connect()`, from the set of
-- event handlers for *event*.
-- @param event The string event name.
-- @param id ID of the handler returned by `events.connect()`.
-- @see connect
-- @name disconnect
function M.disconnect(event, id)
  if not handlers[event] then return end
  table.remove(handlers[event], id)
end

local error_emitted = false
---
-- Sequentially calls all handler functions for *event* with the given
-- arguments.
-- *event* is an arbitrary event name that does not need to have been previously
-- defined. If any handler explicitly returns `true` or `false`, the event is
-- not propagated any further, iteration ceases, and `emit()` returns that
-- value. This is useful for stopping the propagation of an event like a
-- keypress after it has been handled.
-- @param event The string event name.
-- @param ... Arguments passed to the handler.
-- @return `true` or `false` if any handler explicitly returned such; `nil`
--   otherwise.
-- @usage events.emit('my_event', 'my message')
-- @name emit
function M.emit(event, ...)
  if not event then error(_L['Undefined event name']) end
  local h = handlers[event]
  if not h then return end
  local pcall, table_unpack, type = pcall, table.unpack, type
  for i = 1, #h do
    local ok, result = pcall(h[i], table_unpack{...})
    if not ok then
      if not error_emitted then
        error_emitted = true
        M.emit(events.ERROR, result)
        error_emitted = false
      else
        io.stderr:write(result)
      end
    end
    if type(result) == 'boolean' then return result end
  end
end

--- Map of Scintilla notifications to their handlers.
local c = _SCINTILLA.constants
local scnotifications = {
  [c.SCN_CHARADDED] = {'char_added', 'ch'},
  [c.SCN_SAVEPOINTREACHED] = {'save_point_reached'},
  [c.SCN_SAVEPOINTLEFT] = {'save_point_left'},
  [c.SCN_DOUBLECLICK] = {'double_click', 'position', 'line', 'modifiers'},
  [c.SCN_UPDATEUI] = {'update_ui'},
  [c.SCN_MODIFIED] = {'modified', 'modification_type'}, -- undocumented
  [c.SCN_MARGINCLICK] = {'margin_click', 'margin', 'position', 'modifiers'},
  [c.SCN_USERLISTSELECTION] = {
    'user_list_selection', 'wParam', 'text', 'position'
  },
  [c.SCN_URIDROPPED] = {'uri_dropped', 'text'},
  [c.SCN_DWELLSTART] = {'dwell_start', 'position', 'x', 'y'},
  [c.SCN_DWELLEND] = {'dwell_end', 'position', 'x', 'y'},
  [c.SCN_HOTSPOTCLICK] = {'hotspot_click', 'position', 'modifiers'},
  [c.SCN_HOTSPOTDOUBLECLICK] = {
    'hotspot_double_click', 'position', 'modifiers'
  },
  [c.SCN_CALLTIPCLICK] = {'call_tip_click', 'position'},
  [c.SCN_AUTOCSELECTION] = {'auto_c_selection', 'text', 'position'},
  [c.SCN_INDICATORCLICK] = {'indicator_click', 'position', 'modifiers'},
  [c.SCN_INDICATORRELEASE] = {'indicator_release', 'position'},
  [c.SCN_AUTOCCANCELLED] = {'auto_c_cancelled'},
  [c.SCN_AUTOCCHARDELETED] = {'auto_c_char_deleted'},
  [c.SCN_HOTSPOTRELEASECLICK] = {'hotspot_release_click', 'position'},
}

-- Handles Scintilla notifications.
M.connect('SCN', function(n)
  local f = scnotifications[n.code]
  if not f then return end
  local args = {}
  for i = 2, #f do args[i - 1] = n[f[i]] end
  return M.emit(f[1], table.unpack(args))
end)

-- Set event constants.
for _, n in pairs(scnotifications) do M[n[1]:upper()] = n[1] end
local ta_events = {
  'appleevent_odoc', 'buffer_after_switch', 'buffer_before_switch',
  'buffer_deleted', 'buffer_new', 'command_entry_command',
  'command_entry_keypress', 'error', 'find', 'keypress', 'menu_clicked', 'quit',
  'replace', 'replace_all', 'reset_after', 'reset_before', 'view_after_switch',
  'view_before_switch', 'view_new'
}
for _, e in pairs(ta_events) do M[e:upper()] = e end

return M

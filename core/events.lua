-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

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
-- functions. If an event handler explicitly returns a `true` or `false` boolean
-- value, Textadept will not call subsequent handlers. This is useful if you
-- want to stop the propagation of an event like a keypress if your event
-- handler handled it.
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
-- @field AUTO_C_SELECTION (string)
--   Emitted after selecting an item from an autocompletion list, but before
--   inserting that item into the buffer.
--   Automatic insertion can be cancelled by calling
--   [`buffer:auto_c_cancel()`]() before returning from the event handler.
--   Arguments:
--
--   * _`text`_: The selection's text.
--   * _`position`_: The autocompleted word's beginning position.
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
--   * _`byte`_: The text character's byte.
-- @field DOUBLE_CLICK (string)
--   Emitted after double-clicking the mouse button.
--   Arguments:
--
--   * _`position`_: The position double-clicked.
--   * _`line`_: The line number of the position double-clicked.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `buffer.MOD_CTRL`,
--     `buffer.MOD_SHIFT`, `buffer.MOD_ALT`, and `buffer.MOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK+.
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
--   Emitted when the mouse is stationary for [`buffer.mouse_dwell_time`]()
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
-- @field FOCUS (string)
--   Emitted when Textadept receives focus.
--   This event is never emitted when Textadept is running in the terminal.
-- @field HOTSPOT_CLICK (string)
--   Emitted when clicking on text that is in a style that has the hotspot
--   attribute set.
--   Arguments:
--
--   * _`position`_: The clicked text's position.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `buffer.MOD_CTRL`,
--     `buffer.MOD_SHIFT`, `buffer.MOD_ALT`, and `buffer.MOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_DOUBLE_CLICK (string)
--   Emitted when double-clicking on text that is in a style that has the
--   hotspot attribute set.
--   Arguments:
--
--   * _`position`_: The double-clicked text's position.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `buffer.MOD_CTRL`,
--     `buffer.MOD_SHIFT`, `buffer.MOD_ALT`, and `buffer.MOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_RELEASE_CLICK (string)
--   Emitted when releasing the mouse after clicking on text that is in a style
--   that has the hotspot attribute set.
--   Arguments:
--
--   * _`position`_: The clicked text's position.
-- @field INDICATOR_CLICK (string)
--   Emitted when clicking the mouse on text that has an indicator present.
--   Arguments:
--
--   * _`position`_: The clicked text's position.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `buffer.MOD_CTRL`,
--     `buffer.MOD_SHIFT`, `buffer.MOD_ALT`, and `buffer.MOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK+.
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
--   * _`meta`_: The "Command" modifier key on Mac OSX is held down.
-- @field MARGIN_CLICK (string)
--   Emitted when clicking the mouse inside a sensitive margin.
--   Arguments:
--
--   * _`margin`_: The margin number clicked.
--   * _`position`_: The beginning position of the clicked margin's line.
--   * _`modifiers`_: A bit-mask of any modifier keys used: `buffer.MOD_CTRL`,
--     `buffer.MOD_SHIFT`, `buffer.MOD_ALT`, and `buffer.MOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `buffer.MOD_CTRL`, the "Control" modifier is reported as *both* "Control"
--     and "Alt" due to a Scintilla limitation with GTK+.
-- @field MENU_CLICKED (string)
--   Emitted after selecting a menu item.
--   Arguments:
--
--   * _`menu_id`_: The numeric ID of the menu item set in [`ui.menu()`]().
-- @field QUIT (string)
--   Emitted when quitting Textadept.
--   When connecting to this event, connect with an index of 1 or the handler
--   will be ignored.
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
-- @field RESET_BEFORE (string)
--   Emitted before resetting the Lua state.
--   Emitted by [`reset()`]().
-- @field SAVE_POINT_LEFT (string)
--   Emitted after leaving a save point.
-- @field SAVE_POINT_REACHED (string)
--   Emitted after reaching a save point.
-- @field UPDATE_UI (string)
--   Emitted after the view is visually updated.
--   Arguments:
--
--   * _`updated`_: A bitmask of changes since the last update.
--
--     + `buffer.UPDATE_CONTENT`
--       Buffer contents, styling, or markers have changed.
--     + `buffer.UPDATE_SELECTION`
--       Buffer selection has changed.
--     + `buffer.UPDATE_V_SCROLL`
--       Buffer has scrolled vertically.
--     + `buffer.UPDATE_H_SCROLL`
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
--   Emitted on startup and by [`view.split()`]().
-- @field VIEW_BEFORE_SWITCH (string)
--   Emitted right before switching to another view.
--   Emitted by [`ui.goto_view()`]().
-- @field VIEW_AFTER_SWITCH (string)
--   Emitted right after switching to another view.
--   Emitted by [`ui.goto_view()`]().
module('events')]]

local handlers = {}

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
  if not event then error(_L['Undefined event name']) end
  if not handlers[event] then handlers[event] = {} end
  if handlers[event][f] then M.disconnect(event, f) end
  table.insert(handlers[event], index or #handlers[event] + 1, f)
  handlers[event][f] = index or #handlers[event]
end

---
-- Removes function *f* from the set of handlers for event *event*.
-- @param event The string event name.
-- @param f The Lua function connected to *event*.
-- @see connect
-- @name disconnect
function M.disconnect(event, f)
  if not handlers[event] or not handlers[event][f] then return end
  table.remove(handlers[event], handlers[event][f])
  handlers[event][f] = nil
end

local error_emitted = false
---
-- Sequentially calls all handler functions for event *event* with the given
-- arguments.
-- *event* may be any arbitrary string and does not need to have been previously
-- defined. If any handler explicitly returns `true` or `false`, `emit()`
-- returns that value and ceases to call subsequent handlers. This is useful for
-- stopping the propagation of an event like a keypress after it has been
-- handled.
-- @param event The string event name.
-- @param ... Arguments passed to the handler.
-- @return `true` or `false` if any handler explicitly returned such; `nil`
--   otherwise.
-- @usage events.emit('my_event', 'my message')
-- @name emit
function M.emit(event, ...)
  assert(event, _L['Undefined event name'])
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
  [c.SCN_UPDATEUI] = {'update_ui', 'updated'},
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
  'buffer_deleted', 'buffer_new', 'csi', 'error', 'find', 'focus',
  'initialized', 'keypress', 'menu_clicked', 'quit', 'replace', 'replace_all',
  'reset_after', 'reset_before', 'view_after_switch', 'view_before_switch',
  'view_new'
}
for _, e in pairs(ta_events) do M[e:upper()] = e end

return M

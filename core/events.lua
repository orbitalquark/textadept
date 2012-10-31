-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Textadept's core event structure and handlers.
--
-- ## Overview
--
-- Events occur when you do things like create a new buffer, press a key, click
-- on a menu, etc. You can even emit events yourself using Lua. Each event has a
-- set of event handlers, which are simply Lua functions called in the order
-- they were connected to an event. This enables dynamically loaded modules to
-- connect to events.
--
-- Events themselves are nothing special. They do not have to be declared in
-- order to be used. They are simply strings containing an arbitrary event name.
-- When an event of this name is emitted, either by Textadept or you, all event
-- handlers assigned to it are run. Events can be given any number of arguments.
-- These arguments will be passed to the event's handler functions. If an event
-- handler returns a `true` or `false` boolean value explicitly, no subsequent
-- handlers are called. This is useful if you want to stop the propagation of an
-- event like a keypress if it has already been handled.
--
-- @field APPLEEVENT_ODOC (string)
--   Called when Mac OSX tells Textadept to open a document.
--   Arguments:
--
--   * `uri`: The URI to open encoded in UTF-8.
-- @field AUTO_C_CHAR_DELETED (string)
--   Called when the user deleted a character while the autocompletion list was
--   active.
-- @field AUTO_C_RELEASE (string)
--   Called when the user has cancelled the autocompletion list.
-- @field AUTO_C_SELECTION (string)
--   Called when the user has selected an item in an autocompletion list and
--   before the selection is inserted.
--   Automatic insertion can be cancelled by calling
--   [`buffer:auto_c_cancel()`][] before returning from the event handler.
--   Arguments:
--
--   * `text`: The text of the selection.
--   * `position`: The start position of the word being completed.
-- @field BUFFER_AFTER_SWITCH (string)
--   Called right after a buffer is switched to.
--   This is emitted by [`view:goto_buffer()`][].
-- @field BUFFER_BEFORE_SWITCH (string)
--   Called right before another buffer is switched to.
--   This is emitted by [`view:goto_buffer()`][].
-- @field BUFFER_DELETED (string)
--   Called after a buffer was deleted.
--   This is emitted by [`buffer:delete()`][].
-- @field BUFFER_NEW (string)
--   Called when a new buffer is created.
--   This is emitted on startup and by [`new_buffer()`][].
-- @field CALL_TIP_CLICK (string)
--   Called when the user clicks on a calltip.
--   Arguments:
--
--   * `position`: Set to 1 if the click is in an up arrow, 2 if in a down
--     arrow, and 0 if elsewhere.
-- @field CHAR_ADDED (string)
--   Called when an ordinary text character is added to the buffer.
--   Arguments:
--
--   * `ch`: The text character byte.
-- @field COMMAND_ENTRY_COMMAND (string)
--   Called when a command is entered into the Command Entry.
--   If any handler returns `true`, the Command Entry does not hide
--   automatically.
--   Arguments:
--
--   * `command`: The command text.
-- @field COMMAND_ENTRY_KEYPRESS (string)
--   Called when a key is pressed in the Command Entry.
--   If any handler returns `true`, the key is not inserted into the entry.
--   Arguments:
--
--   * `code`: The key code.
--   * `shift`: The "Shift" modifier key is held down.
--   * `ctrl`: The "Control"/"Command" modifier key is held down.
--   * `alt`: The "Alt"/"Option" modifier key is held down.
--   * `meta`: The "Control" modifier key on Mac OSX is held down.
-- @field DOUBLE_CLICK (string)
--   Called when the mouse button is double-clicked.
--   Arguments:
--
--   * `position`: The text position of the double click.
--   * `line`: The line of the double click.
--   * `modifiers`: The key modifiers held down. It is a combination of zero or
--     more of `_SCINTILLA.constants.SCMOD_ALT`,
--     `_SCINTILLA.constants.SCMOD_CTRL`,
--     `_SCINTILLA.constants.SCMOD_SHIFT`, and
--     `_SCINTILLA.constants.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `_SCINTILLA.constants.SCMOD_CTRL`, the "Control" modifier is reported as
--     *both* "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field DWELL_END (string)
--   Called after a `DWELL_START` and the mouse is moved or other activity such
--   as key press indicates the dwell is over.
--   Arguments:
--
--   * `position`: The nearest position in the document to the position where
--     the mouse pointer was lingering.
--   * `x`: Where the pointer lingered.
--   * `y`: Where the pointer lingered.
-- @field DWELL_START (string)
--   Called when the user keeps the mouse in one position for the dwell period
--   (see `_SCINTILLA.constants.SCI_SETMOUSEDWELLTIME`).
--   Arguments:
--
--   * `position`: The nearest position in the document to the position where
--     the mouse pointer was lingering.
--   * `x`: Where the pointer lingered.
--   * `y`: Where the pointer lingered.
-- @field ERROR (string)
--   Called when an error occurs.
--   Arguments:
--
--   * `text`: The error text.
-- @field FIND (string)
--   Called when finding text via the Find dialog box.
--   Arguments:
--
--   * `text`: The text to search for.
--   * `next`: Search forward.
-- @field HOTSPOT_CLICK (string)
--   Called when the user clicks on text that is in a style with the hotspot
--   attribute set.
--   Arguments:
--
--   * `position`: The text position of the click.
--   * `modifiers`: The key modifiers held down. It is a combination of zero or
--     more of `_SCINTILLA.constants.SCMOD_ALT`,
--     `_SCINTILLA.constants.SCMOD_CTRL`,
--     `_SCINTILLA.constants.SCMOD_SHIFT`, and
--     `_SCINTILLA.constants.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `_SCINTILLA.constants.SCMOD_CTRL`, the "Control" modifier is reported as
--     *both* "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_DOUBLE_CLICK (string)
--   Called when the user double clicks on text that is in a style with the
--   hotspot attribute set.
--   Arguments:
--
--   * `position`: The text position of the double click.
--   * `modifiers`: The key modifiers held down. It is a combination of zero or
--     more of `_SCINTILLA.constants.SCMOD_ALT`,
--     `_SCINTILLA.constants.SCMOD_CTRL`,
--     `_SCINTILLA.constants.SCMOD_SHIFT`, and
--     `_SCINTILLA.constants.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `_SCINTILLA.constants.SCMOD_CTRL`, the "Control" modifier is reported as
--     *both* "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field HOTSPOT_RELEASE_CLICK (string)
--   Called when the user releases the mouse on text that is in a style with the
--   hotspot attribute set.
--   Arguments:
--
--   * `position`: The text position of the release.
-- @field INDICATOR_CLICK (string)
--   Called when the user clicks the mouse on text that has an indicator.
--   Arguments:
--
--   * `position`: The text position of the click.
--   * `modifiers`: The key modifiers held down. It is a combination of zero or
--     more of `_SCINTILLA.constants.SCMOD_ALT`,
--     `_SCINTILLA.constants.SCMOD_CTRL`,
--     `_SCINTILLA.constants.SCMOD_SHIFT`, and
--     `_SCINTILLA.constants.SCMOD_META`.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `_SCINTILLA.constants.SCMOD_CTRL`, the "Control" modifier is reported as
--     *both* "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field INDICATOR_RELEASE (string)
--   Called when the user releases the mouse on text that has an indicator.
--   Arguments:
--
--   * `position`: The text position of the release.
-- @field KEYPRESS (string)
--   Called when a key is pressed.
--   If any handler returns `true`, the key is not inserted into the buffer.
--   Arguments:
--
--   * `code`: The key code.
--   * `shift`: The "Shift" modifier key is held down.
--   * `ctrl`: The "Control"/"Command" modifier key is held down.
--   * `alt`: The "Alt"/"Option" modifier key is held down.
--   * `meta`: The "Control" modifier key on Mac OSX is held down.
-- @field MARGIN_CLICK (string)
--   Called when the mouse is clicked inside a margin.
--   Arguments:
--
--   * `margin`: The margin number that was clicked.
--   * `position`: The position of the start of the line in the buffer that
--     corresponds to the margin click.
--   * `modifiers`: The appropriate combination of
--     `_SCINTILLA.constants.SCI_SHIFT`, `_SCINTILLA.constants.SCI_CTRL`,
--     and `_SCINTILLA.constants.SCI_ALT` to indicate the keys that were held
--     down at the time of the margin click.
--     Note: If you set `buffer.rectangular_selection_modifier` to
--     `_SCINTILLA.constants.SCMOD_CTRL`, the "Control" modifier is reported as
--     *both* "Control" and "Alt" due to a Scintilla limitation with GTK+.
-- @field MENU_CLICKED (string)
--   Called when a menu item is selected.
--   Arguments:
--
--   * `menu_id`: The numeric ID of the menu item set in [`gui.menu()`][].
-- @field QUIT (string)
--   Called when quitting Textadept.
--   When connecting to this event, connect with an index of 1 or the handler
--   will be ignored.
--   This is emitted by [`quit()`][].
-- @field REPLACE (string)
--   Called to replace selected (found) text.
--   Arguments:
--
--   * `text`: The text to replace selected text with.
-- @field REPLACE_ALL (string)
--   Called to replace all occurances of found text.
--   Arguments:
--
--   * `find_text`: The text to search for.
--   * `repl_text`: The text to replace found text with.
-- @field RESET_AFTER (string)
--   Called after resetting the Lua state.
--   This is emitted by [`reset()`][].
-- @field RESET_BEFORE (string)
--   Called before resetting the Lua state.
--   This is emitted by [`reset()`][].
-- @field SAVE_POINT_LEFT (string)
--   Called when a save point is left.
-- @field SAVE_POINT_REACHED (string)
--   Called when a save point is entered.
-- @field UPDATE_UI (string)
--   Called when either the text or styling of the buffer has changed or the
--   selection range has changed.
-- @field URI_DROPPED (string)
--   Called when the user has dragged a URI such as a file name onto the view.
--   Arguments:
--
--   * `text`: The URI text encoded in UTF-8.
-- @field USER_LIST_SELECTION (string)
--   Called when the user has selected an item in a user list.
--   Arguments:
--
--   * `list_type`: This is set to the list_type parameter from the
--     [`buffer:user_list_show()`][] call that initiated the list.
--   * `text`: The text of the selection.
--   * `position`: The position the list was displayed at.
-- @field VIEW_NEW (string)
--   Called when a new view is created.
--   This is emitted on startup and by [`view:split()`][].
-- @field VIEW_BEFORE_SWITCH (string)
--   Called right before another view is switched to.
--   This is emitted by [`gui.goto_view()`][].
-- @field VIEW_AFTER_SWITCH (string)
--   Called right after another view is switched to.
--   This is emitted by [`gui.goto_view()`][].
--
-- [`buffer:auto_c_cancel()`]: buffer.html#auto_c_cancel
-- [`view:goto_buffer()`]: view.html#goto_buffer
-- [`new_buffer()`]: _G.html#new_buffer
-- [`buffer:delete()`]: buffer.html#delete
-- [`gui.menu()`]: gui.html#menu
-- [`quit()`]: _G.html#quit
-- [`reset()`]: _G.html#reset
-- [`buffer:user_list_show()`]: buffer.html#user_list_show
-- [`view:split()`]: view.html#split
-- [`gui.goto_view()`]: gui.html#goto_view
module('events')]]

---
-- A table of event names and a table of functions connected to them.
-- @class table
-- @name handlers
M.handlers = {}

---
-- Adds a handler function to an event.
-- @param event The string event name. It is arbitrary and does not need to be
--   defined previously.
-- @param f The Lua function to add.
-- @param index Optional index to insert the handler into.
-- @return Index of handler.
-- @usage events.connect('my_event', function(msg) gui.print(msg) end)
-- @see disconnect
-- @name connect
function M.connect(event, f, index)
  if not event then error(_L['Undefined event name']) end
  if not M.handlers[event] then M.handlers[event] = {} end
  local h = M.handlers[event]
  if index then table.insert(h, index, f) else h[#h + 1] = f end
  return index or #h
end

---
-- Disconnects a handler function from an event.
-- @param event The string event name.
-- @param index Index of the handler returned by `events.connect()`.
-- @see connect
-- @name disconnect
function M.disconnect(event, index)
  if not M.handlers[event] then return end
  table.remove(M.handlers[event], index)
end

local error_emitted = false

---
-- Calls all handlers for the given event in sequence.
-- If `true` or `false` is explicitly returned by any handler, the event is not
-- propagated any further; iteration ceases. This is useful if you want to stop
-- the propagation of an event like a keypress.
-- @param event The string event name. It is arbitrary and does not need to be
--   defined previously.
-- @param ... Arguments passed to the handler.
-- @return `true` or `false` if any handler explicitly returned such; `nil`
--   otherwise.
-- @usage events.emit('my_event', 'my message')
-- @name emit
function M.emit(event, ...)
  if not event then error(_L['Undefined event name']) end
  local h = M.handlers[event]
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
  [c.SCN_CHARADDED] = { 'char_added', 'ch' },
  [c.SCN_SAVEPOINTREACHED] = { 'save_point_reached' },
  [c.SCN_SAVEPOINTLEFT] = { 'save_point_left' },
  [c.SCN_DOUBLECLICK] = { 'double_click', 'position', 'line', 'modifiers' },
  [c.SCN_UPDATEUI] = { 'update_ui' },
  [c.SCN_MODIFIED] = { 'modified', 'modification_type' }, -- undocumented
  [c.SCN_MARGINCLICK] = { 'margin_click', 'margin', 'position', 'modifiers' },
  [c.SCN_USERLISTSELECTION] = {
    'user_list_selection', 'wParam', 'text', 'position'
  },
  [c.SCN_URIDROPPED] = { 'uri_dropped', 'text' },
  [c.SCN_DWELLSTART] = { 'dwell_start', 'position', 'x', 'y' },
  [c.SCN_DWELLEND] = { 'dwell_end', 'position', 'x', 'y' },
  [c.SCN_HOTSPOTCLICK] = { 'hotspot_click', 'position', 'modifiers' },
  [c.SCN_HOTSPOTDOUBLECLICK] = {
    'hotspot_double_click', 'position', 'modifiers'
  },
  [c.SCN_CALLTIPCLICK] = { 'call_tip_click', 'position' },
  [c.SCN_AUTOCSELECTION] = { 'auto_c_selection', 'text', 'position' },
  [c.SCN_INDICATORCLICK] = { 'indicator_click', 'position', 'modifiers' },
  [c.SCN_INDICATORRELEASE] = { 'indicator_release', 'position' },
  [c.SCN_AUTOCCANCELLED] = { 'auto_c_cancelled' },
  [c.SCN_AUTOCCHARDELETED] = { 'auto_c_char_deleted' },
  [c.SCN_HOTSPOTRELEASECLICK] = { 'hotspot_release_click', 'position' },
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

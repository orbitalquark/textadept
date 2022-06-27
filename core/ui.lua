-- Copyright 2007-2022 Mitchell. See LICENSE.

local ui = ui

--[[ This comment is for LuaDoc.
---
-- Utilities for interacting with Textadept's user interface.
-- @field title (string, Write-only)
--   The title text of Textadept's window.
-- @field context_menu (userdata)
--   The buffer's context menu, a [`ui.menu()`]().
--   This is a low-level field. You probably want to use the higher-level
--   [`textadept.menu.context_menu`]().
-- @field tab_context_menu (userdata)
--   The context menu for the buffer's tab, a [`ui.menu()`]().
--   This is a low-level field. You probably want to use the higher-level
--   [`textadept.menu.tab_context_menu`]().
-- @field clipboard_text (string)
--   The text on the clipboard.
-- @field statusbar_text (string, Write-only)
--   The text displayed in the statusbar.
-- @field buffer_statusbar_text (string, Write-only)
--   The text displayed in the buffer statusbar.
-- @field maximized (bool)
--   Whether or not Textadept's window is maximized.
-- @field tabs (bool)
--   Whether or not to display the tab bar when multiple buffers are open.
--   The default value is `true`.
--   A third option, `ui.SHOW_ALL_TABS` may be used to always show the tab bar, even if only
--   one buffer is open.
-- @field silent_print (bool)
--   Whether or not to print messages to buffers silently.
--   This is not guaranteed to be a constant value, as Textadept may change it for the editor's
--   own purposes. This flag should be used only in conjunction with a group of [`ui.print()`]()
--   and [`ui._print()`]() function calls.
--   The default value is `false`, and focuses buffers when messages are printed to them.
-- @field SHOW_ALL_TABS (number)
--
module('ui')]]

ui.SHOW_ALL_TABS = 2 -- ui.tabs options must be greater than 1

ui.silent_print = false

-- Helper function for jumping to another view to print to, or creating a new view to print to
-- (the latter depending on settings).
local function prepare_view()
  if #_VIEWS > 1 then
    ui.goto_view(1)
  elseif not ui.tabs then
    view:split()
  end
end

-- Helper function for printing messages to buffers.
-- @see ui._print
local function _print(buffer_type, ...)
  local buffer
  for _, buf in ipairs(_BUFFERS) do
    if buf._type == buffer_type then
      buffer = buf
      break
    end
  end
  if not buffer then
    prepare_view()
    buffer = _G.buffer.new()
    buffer._type = buffer_type
  elseif not ui.silent_print then
    for _, view in ipairs(_VIEWS) do
      if view.buffer._type == buffer_type then
        ui.goto_view(view)
        goto view_found
      end
    end
    prepare_view()
    view:goto_buffer(buffer)
    ::view_found::
  end
  local args, n = {...}, select('#', ...)
  for i = 1, n do args[i] = tostring(args[i]) end
  buffer:append_text(table.concat(args, '\t'))
  buffer:append_text('\n')
  buffer:goto_pos(buffer.length + 1)
  buffer:set_save_point()
end
---
-- Prints the given string messages to the buffer of string type *buffer_type*.
-- Opens a new buffer for printing messages to if necessary. If the message buffer is already
-- open in a view, the message is printed to that view. Otherwise the view is split (unless
-- `ui.tabs` is `true`) and the message buffer is displayed before being printed to.
-- @param buffer_type String type of message buffer.
-- @param ... Message strings.
-- @usage ui._print(_L['[Message Buffer]'], message)
-- @name _print
function ui._print(buffer_type, ...) _print(assert_type(buffer_type, 'string', 1), ...) end

---
-- Prints the given string messages to the message buffer.
-- Opens a new buffer if one has not already been opened for printing messages.
-- @param ... Message strings.
-- @name print
function ui.print(...) ui._print(_L['[Message Buffer]'], ...) end

-- Returns 0xBBGGRR colors transformed into "#RRGGBB" for the colorselect dialog.
-- @param value Number color to transform.
-- @return string or nil if the transform failed
local function torgb(value)
  local bbggrr = string.format('%06X', value)
  local b, g, r = bbggrr:match('^(%x%x)(%x%x)(%x%x)$')
  return r and g and b and string.format('#%s%s%s', r, g, b) or nil
end

-- Documentation is in core/.ui.dialogs.luadoc.
ui.dialogs = setmetatable({}, {
  __index = function(_, k)
    -- Wrapper for `ui.dialog(k)`, transforming the given table of arguments into a set of
    -- command line arguments and transforming the resulting standard output into Lua objects.
    -- @param options Table of key-value command line options for gtdialog.
    -- @param f Work function for progressbar dialogs.
    -- @return Lua objects depending on the dialog kind
    return function(options, f)
      if not options.button1 then options.button1 = _L['OK'] end
      if k == 'filteredlist' and not options.width then
        options.width = ui.size[1] - 2 * (CURSES and 1 or 100)
      end
      -- Transform key-value pairs into command line arguments.
      local args = {}
      for option, value in pairs(options) do
        if assert_type(value, 'string/number/table/boolean', option) then
          args[#args + 1] = '--' .. option:gsub('_', '-')
          if type(value) == 'table' then
            for i, val in ipairs(value) do
              local narg = string.format('%s[%d]', option, i)
              assert_type(val, 'string/number', narg)
              if option == 'palette' and type(val) == 'number' then
                value[i] = torgb(val) -- nil return is okay
              elseif option == 'select' and assert_type(val, 'number', narg) then
                value[i] = val - 1 -- convert from 1-based index to 0-based index
              end
            end
          elseif option == 'color' and type(value) == 'number' then
            value = torgb(value)
          elseif option == 'select' and assert_type(value, 'number', option) then
            value = value - 1 -- convert from 1-based index to 0-based index
          end
          if type(value) ~= 'boolean' then args[#args + 1] = value end
        end
      end
      if k == 'progressbar' then args[#args + 1] = assert_type(f, 'function', 2) end
      -- Call gtdialog, stripping any trailing newline in the output.
      local result = ui.dialog(k:gsub('_', '-'), table.unpack(args)):match('^(.-)\n?$')
      -- Depending on the dialog type, transform the result into Lua objects.
      if k == 'fileselect' or k == 'filesave' then
        if result == '' then return nil end
        if WIN32 and not CURSES then result = result:iconv(_CHARSET, 'UTF-8') end
        if k == 'filesave' or not options.select_multiple then return result end
        local filenames = {}
        for filename in result:gmatch('[^\n]+') do filenames[#filenames + 1] = filename end
        return filenames
      elseif k == 'filteredlist' or k == 'optionselect' or
        (k:find('input') and result:match('^[^\n]+\n?(.*)$'):find('\n')) then
        local button, value = result:match('^([^\n]+)\n?(.*)$')
        if not options.string_output then button = tonumber(button) end
        if k == 'optionselect' then
          options.select_multiple = true
        elseif k:find('input') then
          options.string_output, options.select_multiple = true, true
        end
        local items, patt = {}, not k:find('input') and '[^\n]+' or '([^\n]*)\n'
        for item in (value .. '\n'):gmatch(patt) do
          items[#items + 1] = options.string_output and item or tonumber(item) + 1
        end
        return button, options.select_multiple and items or items[1]
      elseif k == 'colorselect' then
        if options.string_output then return result ~= '' and result or nil end
        local r, g, b = result:match('^#(%x%x)(%x%x)(%x%x)$')
        local bgr = r and g and b and string.format('0x%s%s%s', b, g, r) or nil
        return tonumber(bgr)
      elseif k == 'fontselect' or k == 'progressbar' then
        return result ~= '' and result or nil
      elseif not options.string_output then
        local i, value = result:match('^(%-?%d+)\n?(.*)$')
        i = tonumber(i)
        if k:find('dropdown') then value = i > 0 and tonumber(value) + 1 or nil end
        return i, value
      end
      return result:match('([^\n]+)\n?(.*)$')
    end
  end
})

local buffers_zorder = {}

-- Adds new buffers to the z-order list.
events.connect(events.BUFFER_NEW, function()
  if buffer ~= ui.command_entry then table.insert(buffers_zorder, 1, buffer) end
end)

-- Updates the z-order list.
local function update_zorder()
  local i = 1
  while i <= #buffers_zorder do
    if buffers_zorder[i] == buffer or not _BUFFERS[buffers_zorder[i]] then
      table.remove(buffers_zorder, i)
    else
      i = i + 1
    end
  end
  table.insert(buffers_zorder, 1, buffer)
end
events.connect(events.BUFFER_AFTER_SWITCH, update_zorder)
events.connect(events.VIEW_AFTER_SWITCH, update_zorder)
events.connect(events.BUFFER_DELETED, update_zorder)

-- Saves and restores buffer zorder data during a reset.
events.connect(events.RESET_BEFORE, function(persist) persist.ui_zorder = buffers_zorder end)
events.connect(events.RESET_AFTER, function(persist) buffers_zorder = persist.ui_zorder end)

---
-- Prompts the user to select a buffer to switch to.
-- Buffers are listed in the order they were opened unless `zorder` is `true`, in which case
-- buffers are listed by their z-order (most recently viewed to least recently viewed).
-- @param zorder Flag that indicates whether or not to list buffers by their z-order. The
--   default value is `false`.
-- @name switch_buffer
function ui.switch_buffer(zorder)
  local buffers = not zorder and _BUFFERS or buffers_zorder
  local columns, utf8_list = {_L['Name'], _L['Filename']}, {}
  for i = not zorder and 1 or 2, #buffers do
    local buffer = buffers[i]
    local filename = buffer.filename or buffer._type or _L['Untitled']
    if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
    local basename = buffer.filename and filename:match('[^/\\]+$') or filename
    utf8_list[#utf8_list + 1] = (buffer.modify and '*' or '') .. basename
    utf8_list[#utf8_list + 1] = filename
  end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Switch Buffers'], columns = columns, items = utf8_list
  }
  if button ~= 1 or not i then return end
  view:goto_buffer(buffers[not zorder and i or i + 1])
end

---
-- Switches to the existing view whose buffer's filename is *filename*.
-- If no view was found and *split* is `true`, splits the current view in order to show the
-- requested file. If *split* is `false`, shifts to the next or *preferred_view* view in order
-- to show the requested file. If *sloppy* is `true`, requires only the basename of *filename*
-- to match a buffer's `filename`. If the requested file was not found, it is opened in the
-- desired view.
-- @param filename The filename of the buffer to go to.
-- @param split Optional flag that indicates whether or not to open the buffer in a split view
--   if there is only one view. The default value is `false`.
-- @param preferred_view Optional view to open the desired buffer in if the buffer is not
--   visible in any other view.
-- @param sloppy Optional flag that indicates whether or not to not match *filename* to
--   `buffer.filename` exactly. When `true`, matches *filename* to only the last part of
--   `buffer.filename` This is useful for run and compile commands which output relative filenames
--   and paths instead of full ones and it is likely that the file in question is already open.
--   The default value is `false`.
-- @name goto_file
function ui.goto_file(filename, split, preferred_view, sloppy)
  assert_type(filename, 'string', 1)
  local patt = string.format('%s%s$', not sloppy and '^' or '',
    not sloppy and filename or filename:match('[^/\\]+$')) -- TODO: escape filename properly
  if WIN32 then
    patt = patt:gsub('%a', function(letter)
      return string.format('[%s%s]', letter:upper(), letter:lower())
    end)
  end
  if #_VIEWS == 1 and split and not (view.buffer.filename or ''):find(patt) then
    view:split()
  else
    local other_view = _VIEWS[preferred_view] and preferred_view
    for _, view in ipairs(_VIEWS) do
      local view_filename = view.buffer.filename or ''
      if view_filename:find(patt) then
        ui.goto_view(view)
        return
      end
      if not other_view and view ~= _G.view then other_view = view end
    end
    if other_view then ui.goto_view(other_view) end
  end
  for _, buf in ipairs(_BUFFERS) do
    if (buf.filename or ''):find(patt) then
      view:goto_buffer(buf)
      return
    end
  end
  io.open_file(filename)
end

-- Ensure title, statusbar, etc. are updated for new views.
events.connect(events.VIEW_NEW, function() events.emit(events.UPDATE_UI, 3) end)

-- Switches between buffers when a tab is clicked.
events.connect(events.TAB_CLICKED, function(index) view:goto_buffer(_BUFFERS[index]) end)

-- Sets the title of the Textadept window to the buffer's filename.
local function set_title()
  local filename = buffer.filename or buffer._type or _L['Untitled']
  if buffer.filename then filename = select(2, pcall(string.iconv, filename, 'UTF-8', _CHARSET)) end
  local basename = buffer.filename and filename:match('[^/\\]+$') or filename
  ui.title = string.format('%s %s Textadept (%s)', basename, buffer.modify and '*' or '-', filename)
  buffer.tab_label = basename .. (buffer.modify and '*' or '')
end

-- Changes Textadept title to show the buffer as being "clean" or "dirty".
events.connect(events.SAVE_POINT_REACHED, set_title)
events.connect(events.SAVE_POINT_LEFT, set_title)

-- Open uri(s).
events.connect(events.URI_DROPPED, function(utf8_uris)
  for utf8_path in utf8_uris:gmatch('file://([^\r\n]+)') do
    local path = utf8_path:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end)
      :iconv(_CHARSET, 'UTF-8')
    -- In WIN32, ignore a leading '/', but not '//' (network path).
    if WIN32 and not path:match('^//') then path = path:sub(2, -1) end
    local mode = lfs.attributes(path, 'mode')
    if mode and mode ~= 'directory' then io.open_file(path) end
  end
  ui.goto_view(view) -- work around any view focus synchronization issues
end)
events.connect(events.APPLEEVENT_ODOC,
  function(uri) return events.emit(events.URI_DROPPED, 'file://' .. uri) end)

-- Sets buffer statusbar text.
events.connect(events.UPDATE_UI, function(updated)
  if updated & 3 == 0 then return end -- ignore scrolling
  local text = not CURSES and '%s %d/%d    %s %d    %s    %s    %s    %s' or
    '%s %d/%d  %s %d  %s  %s  %s  %s'
  local pos = buffer.current_pos
  local line, max = buffer:line_from_position(pos), buffer.line_count
  local col = buffer.column[pos]
  local lang = buffer:get_lexer()
  local eol = buffer.eol_mode == buffer.EOL_CRLF and _L['CRLF'] or _L['LF']
  local tabs = string.format('%s %d', buffer.use_tabs and _L['Tabs:'] or _L['Spaces:'],
    buffer.tab_width)
  local encoding = buffer.encoding or ''
  ui.buffer_statusbar_text = string.format(text, _L['Line:'], line, max, _L['Col:'], col, lang, eol,
    tabs, encoding)
end)

-- Save buffer properties.
local function save_buffer_state()
  -- Save view state.
  buffer._anchor, buffer._current_pos = buffer.anchor, buffer.current_pos
  local n = buffer.main_selection
  buffer._anchor_virtual_space = buffer.selection_n_anchor_virtual_space[n]
  buffer._caret_virtual_space = buffer.selection_n_caret_virtual_space[n]
  buffer._top_line = view:doc_line_from_visible(view.first_visible_line)
  buffer._x_offset = view.x_offset
  -- Save fold state.
  local folds, i = {}, view:contracted_fold_next(1)
  while i >= 1 do folds[#folds + 1], i = i, view:contracted_fold_next(i + 1) end
  buffer._folds = folds
end
events.connect(events.BUFFER_BEFORE_SWITCH, save_buffer_state)
events.connect(events.BUFFER_BEFORE_REPLACE_TEXT, save_buffer_state)

-- Restore buffer properties.
local function restore_buffer_state()
  if not buffer._folds then return end
  -- Restore fold state.
  for _, line in ipairs(buffer._folds) do view:toggle_fold(line) end
  -- Restore view state.
  buffer:set_sel(buffer._anchor, buffer._current_pos)
  buffer.selection_n_anchor_virtual_space[1] = buffer._anchor_virtual_space
  buffer.selection_n_caret_virtual_space[1] = buffer._caret_virtual_space
  buffer:choose_caret_x()
  local _top_line, top_line = buffer._top_line, view.first_visible_line
  view:line_scroll(0, view:visible_from_doc_line(_top_line) - top_line)
  view.x_offset = buffer._x_offset or 0
end
events.connect(events.BUFFER_AFTER_SWITCH, restore_buffer_state)
events.connect(events.BUFFER_AFTER_REPLACE_TEXT, restore_buffer_state)

-- Updates titlebar and statusbar.
local function update_bars()
  set_title()
  events.emit(events.UPDATE_UI, 3)
end
events.connect(events.BUFFER_NEW, update_bars)
events.connect(events.BUFFER_AFTER_SWITCH, update_bars)
events.connect(events.VIEW_AFTER_SWITCH, update_bars)

-- Save view state.
local function save_view_state()
  buffer._view_ws, buffer._wrap_mode = view.view_ws, view.wrap_mode
  buffer._margin_type_n, buffer._margin_width_n = {}, {}
  for i = 1, view.margins do
    buffer._margin_type_n[i] = view.margin_type_n[i]
    buffer._margin_width_n[i] = view.margin_width_n[i]
  end
end
events.connect(events.BUFFER_BEFORE_SWITCH, save_view_state)
events.connect(events.VIEW_BEFORE_SWITCH, save_view_state)

-- Restore view state.
local function restore_view_state()
  if not buffer._margin_type_n then return end
  view.view_ws, view.wrap_mode = buffer._view_ws, buffer._wrap_mode
  for i = 1, view.margins do
    view.margin_type_n[i] = buffer._margin_type_n[i]
    view.margin_width_n[i] = buffer._margin_width_n[i]
  end
end
events.connect(events.BUFFER_AFTER_SWITCH, restore_view_state)
events.connect(events.VIEW_AFTER_SWITCH, restore_view_state)

events.connect(events.RESET_AFTER, function() ui.statusbar_text = _L['Lua reset'] end)

-- Prompts for confirmation if any buffers are modified.
events.connect(events.QUIT, function()
  local utf8_list = {}
  for _, buffer in ipairs(_BUFFERS) do
    if not buffer.modify then goto continue end
    local filename = buffer.filename or buffer._type or _L['Untitled']
    if buffer.filename then filename = filename:iconv('UTF-8', _CHARSET) end
    utf8_list[#utf8_list + 1] = filename
    ::continue::
  end
  if #utf8_list == 0 then return end
  local button = ui.dialogs.msgbox{
    title = _L['Quit without saving?'], text = _L['The following buffers are unsaved:'],
    informative_text = table.concat(utf8_list, '\n'), icon = 'dialog-question',
    button1 = _L['Cancel'], button2 = _L['Quit without saving'],
    width = CURSES and ui.size[1] - 2 or nil
  }
  if button ~= 2 then return true end -- prevent quit
end)

-- Keeps track of, and switches back to the previous buffer after buffer close.
events.connect(events.BUFFER_BEFORE_SWITCH, function() view._prev_buffer = buffer end)
events.connect(events.BUFFER_DELETED, function()
  if _BUFFERS[view._prev_buffer] and buffer ~= view._prev_buffer then
    restore_view_state() -- events.BUFFER_AFTER_SWITCH is not emitted in time
    view:goto_buffer(view._prev_buffer)
  end
end)

-- Properly handle clipboard text between views in curses, enables and disables mouse mode,
-- and focuses and resizes views based on mouse events.
if CURSES then
  events.connect(events.VIEW_BEFORE_SWITCH, function() ui._clipboard_text = ui.clipboard_text end)
  events.connect(events.VIEW_AFTER_SWITCH, function() ui.clipboard_text = ui._clipboard_text end)

  if not WIN32 then
    local function enable_mouse() io.stdout:write("\x1b[?1002h"):flush() end
    local function disable_mouse() io.stdout:write("\x1b[?1002l"):flush() end
    enable_mouse()
    events.connect(events.SUSPEND, disable_mouse)
    events.connect(events.RESUME, enable_mouse)
    events.connect(events.QUIT, disable_mouse)
  end

  -- Retrieves the view or split at the given terminal coordinates.
  -- @param view View or split to test for coordinates within.
  -- @param y The y terminal coordinate.
  -- @param x The x terminal coordinate.
  local function get_view(view, y, x)
    if not view[1] and not view[2] then return view end
    local vertical, size = view.vertical, view.size
    if vertical and x < size or not vertical and y < size then
      return get_view(view[1], y, x)
    elseif vertical and x > size or not vertical and y > size then
      -- Zero y or x relative to the other view based on split orientation.
      return get_view(view[2], vertical and y or y - size - 1, vertical and x - size - 1 or x)
    else
      return view -- in-between views; return the split itself
    end
  end

  local resize
  events.connect(events.MOUSE, function(event, button, y, x)
    if event == view.MOUSE_RELEASE or button ~= 1 then return end
    if event == view.MOUSE_PRESS then
      local view = get_view(ui.get_split_table(), y - 1, x) -- title is at y = 1
      if not view[1] and not view[2] then
        ui.goto_view(view)
        resize = nil
      else
        resize = function(y2, x2)
          local i = getmetatable(view[1]) == getmetatable(_G.view) and 1 or 2
          view[i].size = view.size + (view.vertical and x2 - x or y2 - y)
        end
      end
    elseif resize then
      resize(y, x)
    end
    return resize ~= nil -- false resends mouse event to current view
  end)
end

events.connect(events.INITIALIZED, function()
  local lua_error = (not WIN32 and '^/' or '^%a?:?[/\\][/\\]?') .. '.-%.lua:%d+:'
  -- Print internal Lua error messages as they are reported.
  -- Attempt to mimic the Lua interpreter's error message format so tools that look for it can
  -- recognize these errors too.
  events.connect(events.ERROR, function(text)
    if text and text:find(lua_error) then text = 'lua: ' .. text end
    ui.print(text)
  end)
end)

--[[ The tables below were defined in C.

---
-- A table of menus defining a menubar. (Write-only).
-- This is a low-level field. You probably want to use the higher-level `textadept.menu.menubar`.
-- @see textadept.menu.menubar
-- @class table
-- @name menubar
local menubar

---
-- A table containing the width and height pixel values of Textadept's window.
-- @class table
-- @name size
local size

The functions below are Lua C functions.

---
-- Low-level function for prompting the user with a [gtdialog][] of kind *kind* with the given
-- string and table arguments, returning a formatted string of the dialog's output.
-- You probably want to use the higher-level functions in the [`ui.dialogs`]() module.
-- Table arguments containing strings are allowed and expanded in place. This is useful for
-- filtered list dialogs with many items.
--
-- [gtdialog]: https://orbitalquark.github.io/gtdialog/manual.html
-- @param kind The kind of gtdialog.
-- @param ... Parameters to the gtdialog.
-- @return string gtdialog result.
-- @class function
-- @name dialog
local dialog

---
-- Returns a split table that contains Textadept's current split view structure.
-- This is primarily used in session saving.
-- @return table of split views. Each split view entry is a table with 4 fields: `1`, `2`,
--   `vertical`, and `size`. `1` and `2` have values of either nested split view entries or
--   the views themselves; `vertical` is a flag that indicates if the split is vertical or not;
--   and `size` is the integer position of the split resizer.
-- @class function
-- @name get_split_table
local get_split_table

---
-- Shifts to view *view* or the view *view* number of views relative to the current one.
-- Emits `VIEW_BEFORE_SWITCH` and `VIEW_AFTER_SWITCH` events.
-- @param view A view or relative view number (typically 1 or -1).
-- @see _G._VIEWS
-- @see events.VIEW_BEFORE_SWITCH
-- @see events.VIEW_AFTER_SWITCH
-- @class function
-- @name goto_view
local goto_view

---
-- Low-level function for creating a menu from table *menu_table* and returning the userdata.
-- You probably want to use the higher-level `textadept.menu.menubar`,
-- `textadept.menu.context_menu`, or `textadept.menu.tab_context_menu` tables.
-- Emits a `MENU_CLICKED` event when a menu item is selected.
-- @param menu_table A table defining the menu. It is an ordered list of tables with a string
--   menu item, integer menu ID, and optional GDK keycode and modifier mask. The latter
--   two are used to display key shortcuts in the menu. '_' characters are treated as a menu
--   mnemonics. If the menu item is empty, a menu separator item is created. Submenus are just
--   nested menu-structure tables. Their title text is defined with a `title` key.
-- @usage ui.menu{ {'_New', 1}, {'_Open', 2}, {''}, {'_Quit', 4} }
-- @usage ui.menu{ {'_New', 1, string.byte('n'), 4} } -- 'Ctrl+N'
-- @see events.MENU_CLICKED
-- @see textadept.menu.menubar
-- @see textadept.menu.context_menu
-- @see textadept.menu.tab_context_menu
-- @class function
-- @name menu
local menu

---
-- Displays a popup menu, typically the right-click context menu.
-- @param menu Menu to display.
-- @usage ui.popup_menu(ui.context_menu)
-- @see ui.menu
-- @see ui.context_menu
-- @class function
-- @name popup_menu
local popup_menu

---
-- Processes pending GTK events, including reading from spawned processes.
-- This function is primarily used in unit tests.
-- @class function
-- @name update
local update
]]

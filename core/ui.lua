-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

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
-- @field bufstatusbar_text (string, Write-only)
--   The text displayed in the buffer statusbar.
-- @field maximized (bool)
--   Whether or not Textadept's window is maximized.
-- @field tabs (bool)
--   Whether or not to display the tab bar when multiple buffers are open.
--   The default value is `true`.
-- @field SILENT_PRINT (bool)
--   Whether or not to print messages to buffers silently.
--   The default value is `false`, and focuses buffers when messages are printed
--   to them.
module('ui')]]

ui.SILENT_PRINT = false

local theme = package.searchpath(not CURSES and 'light' or 'term',
                                 _USERHOME..'/themes/?.lua;'..
                                 _HOME..'/themes/?.lua')
local theme_props = {}

-- Helper function for printing messages to buffers.
-- @see ui._print
local function _print(buffer_type, ...)
  local print_buffer
  for i, buffer in ipairs(_BUFFERS) do
    if buffer._type == buffer_type then print_buffer = buffer break end
  end
  if not print_buffer then
    if not ui.tabs then view:split() end
    print_buffer = buffer.new()
    print_buffer._type = buffer_type
    events.emit(events.FILE_OPENED)
  elseif not ui.SILENT_PRINT then
    local index = _BUFFERS[print_buffer]
    for i, view in ipairs(_VIEWS) do
      if view.buffer._type == buffer_type then ui.goto_view(i) break end
    end
    if view.buffer._type ~= buffer_type then view:goto_buffer(index) end
  end
  local args, n = {...}, select('#', ...)
  for i = 1, n do args[i] = tostring(args[i]) end
  print_buffer:append_text(table.concat(args, '\t'))
  print_buffer:append_text('\n')
  print_buffer:goto_pos(buffer.length)
  print_buffer:set_save_point()
end
---
-- Prints the given string messages to the buffer of type *buffer_type*.
-- Opens a new buffer for printing messages to if necessary. If the message
-- buffer is already open in a view, the message is printed to that view.
-- Otherwise the view is split (unless `ui.tabs` is `true`) and the message
-- buffer is displayed before being printed to.
-- @param buffer_type String type of message buffer.
-- @param ... Message strings.
-- @usage ui._print(_L['[Message Buffer]'], message)
-- @name _print
function ui._print(buffer_type, ...) pcall(_print, buffer_type, ...) end

---
-- Prints the given string messages to the message buffer.
-- Opens a new buffer if one has not already been opened for printing messages.
-- @param ... Message strings.
-- @name print
function ui.print(...) ui._print(_L['[Message Buffer]'], ...) end

-- Documentation is in core/.ui.dialogs.luadoc.
ui.dialogs = setmetatable({}, {__index = function(t, k)
  -- Wrapper for `ui.dialog(k)`, transforming the given table of arguments into
  -- a set of command line arguments and transforming the resulting standard
  -- output into Lua objects.
  -- @param options Table of key-value command line options for gtdialog.
  -- @return Lua objects depending on the dialog kind
  return function(options)
    if not options.button1 then options.button1 = _L['_OK'] end
    local select = options.select
    if type(select) == 'number' then
      options.select = select - 1
    elseif type(select) == 'table' then
      for i = 1, #select do select[i] = select[i] - 1 end
    end
    -- Transform key-value pairs into command line arguments.
    local args = {}
    for option, value in pairs(options) do
      if value then
        args[#args + 1] = '--'..option:gsub('_', '-')
        if value ~= true then args[#args + 1] = value end
      end
    end
    -- Call gtdialog, stripping any trailing newline in the standard output.
    local result = ui.dialog(k:gsub('_', '-'), table.unpack(args))
    result = result:match('^(.-)\n?$')
    -- Depending on the dialog type, transform the result into Lua objects.
    if k == 'fileselect' or k == 'filesave' then
      if result == '' then return nil end
      if k == 'filesave' or not options.select_multiple then return result end
      local files = {}
      for file in result:gmatch('[^\n]+') do files[#files + 1] = file end
      return files
    elseif k == 'filteredlist' or k == 'optionselect' or
           k:find('input') and result:match('^[^\n]+\n?(.*)$'):find('\n') then
      local button, value = result:match('^([^\n]+)\n?(.*)$')
      if not options.string_output then button = tonumber(button) end
      if k == 'optionselect' then
        options.select_multiple = true
      elseif k:find('input') then
        options.string_output, options.select_multiple = true, true
      end
      local items, patt = {}, not k:find('input') and '[^\n]+' or '([^\n]*)\n'
      for item in (value..'\n'):gmatch(patt) do
        items[#items + 1] = options.string_output and item or tonumber(item) + 1
      end
      return button, options.select_multiple and items or items[1]
    elseif not options.string_output then
      local i, value = result:match('^(%-?%d+)\n?(.*)$')
      i = tonumber(i)
      if k == 'dropdown' then value = i > 0 and tonumber(value) + 1 or nil end
      return i, value
    end
    return result:match('([^\n]+)\n(.*)$')
  end
end})

---
-- Prompts the user to select a buffer to switch to.
-- @name switch_buffer
function ui.switch_buffer()
  local columns, items = {_L['Name'], _L['File']}, {}
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type or _L['Untitled']
    filename = filename:iconv('UTF-8', _CHARSET)
    local basename = buffer.filename and filename:match('[^/\\]+$') or filename
    items[#items + 1] = (buffer.modify and '*' or '')..basename
    items[#items + 1] = filename
  end
  local button, i = ui.dialogs.filteredlist{
    title = _L['Switch Buffers'], columns = columns, items = items,
    width = CURSES and ui.size[1] - 2 or nil
  }
  if button == 1 and i then view:goto_buffer(i) end
end

---
-- Switches to the existing view whose buffer's filename is *filename*.
-- If no view was found and *split* is `true`, splits the current view in order
-- to show the requested file. If *split* is `false`, shifts to the next or
-- *preferred_view* view in order to show the requested file. If *sloppy* is
-- `true`, requires only the last part of *filename* to match a buffer's
-- `filename`. If the requested file was not found, it is opened in the desired
-- view.
-- @param filename The filename of the buffer to go to.
-- @param split Optional flag that indicates whether or not to open the buffer
--   in a split view if there is only one view. The default value is `false`.
-- @param preferred_view Optional view to open the desired buffer in if the
--   buffer is not visible in any other view.
-- @param sloppy Optional flag that indicates whether or not to not match
--   *filename* to `buffer.filename` exactly. When `true`, matches *filename* to
--   only the last part of `buffer.filename` This is useful for run and compile
--   commands which output relative filenames and paths instead of full ones and
--   it is likely that the file in question is already open. The default value
--   is `false`.
-- @name goto_file
function ui.goto_file(filename, split, preferred_view, sloppy)
  local patt = '^'..filename..'$'
  if sloppy then patt = filename:match('[^/\\]+$')..'$' end
  if #_VIEWS == 1 and split and not (view.buffer.filename or ''):find(patt) then
    view:split()
  else
    local other_view = _VIEWS[preferred_view]
    for i, v in ipairs(_VIEWS) do
      if (v.buffer.filename or ''):find(patt) then ui.goto_view(i) return end
      if not other_view and v ~= view then other_view = i end
    end
    if other_view then ui.goto_view(other_view) end
  end
  for i, buffer in ipairs(_BUFFERS) do
    if (buffer.filename or ''):find(patt) then view:goto_buffer(i) return end
  end
  io.open_file(filename)
end

---
-- Switches the editor theme to string *name* and (optionally) assigns the
-- properties contained in table *props*.
-- User themes override Textadept's default themes when they have the same name.
-- If *name* contains slashes, it is assumed to be an absolute path to a theme
-- instead of a theme name.
-- @param name The name or absolute path of a theme to set.
-- @param props Optional table of theme property assignments that override the
--   theme's defaults.
-- @usage ui.set_theme('light', {font = 'Monospace', fontsize = 12})
-- @name set_theme
function ui.set_theme(name, props)
  name = name:find('[/\\]') and name or
         package.searchpath(name, _USERHOME..'/themes/?.lua;'..
                                  _HOME..'/themes/?.lua')
  if not name or not lfs.attributes(name) then return end
  props = props or {}
  local current_buffer, current_view = _BUFFERS[buffer], _VIEWS[view]
  for i = 1, #_BUFFERS do
    view:goto_buffer(i)
    dofile(name)
    for prop, value in pairs(props) do buffer.property[prop] = value end
  end
  view:goto_buffer(current_buffer)
  for i = 1, #_VIEWS do
    ui.goto_view(i)
    dofile(name)
    for prop, value in pairs(props) do buffer.property[prop] = value end
  end
  ui.goto_view(current_view)
  theme, theme_props = name, props
end

local events, events_connect = events, events.connect

-- Loads the theme and properties files.
local function load_theme_and_settings()
  dofile(theme)
  for prop, value in pairs(theme_props) do buffer.property[prop] = value end
  dofile(_HOME..'/properties.lua')
  if lfs.attributes(_USERHOME..'/properties.lua') then
    dofile(_USERHOME..'/properties.lua')
  end
end

-- Sets default properties for a Scintilla window.
events_connect(events.VIEW_NEW, function()
  local buffer = buffer
  -- Allow redefinitions of these Scintilla key commands.
  local ctrl_keys = {
    '[', ']', '/', '\\', 'Z', 'Y', 'X', 'C', 'V', 'A', 'L', 'T', 'D', 'U'
  }
  local ctrl_shift_keys = {'L', 'T', 'U', 'Z'}
  for _, key in ipairs(ctrl_keys) do
    buffer:clear_cmd_key(string.byte(key), buffer.MOD_CTRL)
  end
  for _, key in ipairs(ctrl_shift_keys) do
    buffer:clear_cmd_key(string.byte(key), buffer.MOD_CTRL + buffer.MOD_SHIFT)
  end
  -- Since BUFFER_NEW loads themes and settings on startup, only load them for
  -- subsequent views.
  if #_VIEWS > 1 then load_theme_and_settings() end
end)
events_connect(events.VIEW_NEW, function() events.emit(events.UPDATE_UI) end)

local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLUASTATE = _SCINTILLA.functions.change_lexer_state[1]
local SETLEXERLANGUAGE = _SCINTILLA.properties.lexer_language[2]
-- Sets default properties for a Scintilla document.
events_connect(events.BUFFER_NEW, function()
  buffer.code_page = buffer.CP_UTF8
  buffer.lexer_language = 'lpeg'
  buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLUASTATE, _LUA)
  buffer.property['lexer.lpeg.home'] = _USERHOME..'/lexers/?.lua;'..
                                       _HOME..'/lexers'
  load_theme_and_settings()
  buffer:private_lexer_call(SETLEXERLANGUAGE, 'text')
end)

-- Sets the title of the Textadept window to the buffer's filename.
local function set_title()
  local filename = buffer.filename or buffer._type or _L['Untitled']
  filename = filename:iconv('UTF-8', _CHARSET)
  local basename = buffer.filename and filename:match('[^/\\]+$') or filename
  ui.title = string.format('%s %s Textadept (%s)', basename,
                           buffer.modify and '*' or '-', filename)
  buffer.tab_label = basename..(buffer.modify and '*' or '')
end

-- Changes Textadept title to show the buffer as being "clean" or "dirty".
events_connect(events.SAVE_POINT_REACHED, set_title)
events_connect(events.SAVE_POINT_LEFT, set_title)

-- Open uri(s).
events_connect(events.URI_DROPPED, function(utf8_uris)
  for utf8_uri in utf8_uris:gmatch('[^\r\n]+') do
    if utf8_uri:find('^file://') then
      local uri = utf8_uri:iconv(_CHARSET, 'UTF-8')
      uri = uri:match('^file://([^\r\n]+)'):gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
      end)
      if WIN32 then uri = uri:sub(2, -1) end -- ignore leading '/'
      local mode = lfs.attributes(uri, 'mode')
      if mode and mode ~= 'directory' then io.open_file(uri) end
    end
  end
end)
events_connect(events.APPLEEVENT_ODOC, function(uri)
  return events.emit(events.URI_DROPPED, 'file://'..uri)
end)

local EOLs = {_L['CRLF'], _L['CR'], _L['LF']}
local GETLEXERLANGUAGE = _SCINTILLA.properties.lexer_language[1]
-- Sets buffer statusbar text.
events_connect(events.UPDATE_UI, function()
  local pos = buffer.current_pos
  local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
  local col = buffer.column[pos] + 1
  local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE):match('^[^/]+')
  local eol = EOLs[buffer.eol_mode + 1]
  local tabs = string.format('%s %d', buffer.use_tabs and _L['Tabs:'] or
                                      _L['Spaces:'], buffer.tab_width)
  local enc = buffer.encoding or ''
  local bom = buffer.encoding_bom and '(BOM)' or ''
  local text = not CURSES and '%s %d/%d    %s %d    %s    %s    %s    %s%s' or
                              '%s %d/%d  %s %d  %s  %s  %s  %s%s'
  ui.bufstatusbar_text = string.format(text, _L['Line:'], line, max, _L['Col:'],
                                       col, lexer, eol, tabs, enc, bom)
end)

-- Updates the statusbar and titlebar for a new Scintilla document.
events_connect(events.BUFFER_NEW, function() events.emit(events.UPDATE_UI) end)
events_connect(events.BUFFER_NEW, function() set_title() end)

-- Save buffer properties.
events_connect(events.BUFFER_BEFORE_SWITCH, function()
  local buffer = buffer
  -- Save view state.
  buffer._anchor, buffer._current_pos = buffer.anchor, buffer.current_pos
  buffer._top_line = buffer:doc_line_from_visible(buffer.first_visible_line)
  -- Save fold state.
  buffer._folds = {}
  local folds, i = buffer._folds, buffer:contracted_fold_next(0)
  while i >= 0 do
    folds[#folds + 1], i = i, buffer:contracted_fold_next(i + 1)
  end
end)

-- Restore buffer properties.
events_connect(events.BUFFER_AFTER_SWITCH, function()
  local buffer = buffer
  if not buffer._folds then return end
  -- Restore fold state.
  for i = 1, #buffer._folds do buffer:toggle_fold(buffer._folds[i]) end
  -- Restore view state.
  buffer:set_sel(buffer._anchor, buffer._current_pos)
  buffer:line_scroll(0, buffer:visible_from_doc_line(buffer._top_line) -
                        buffer.first_visible_line)
end)

-- Updates titlebar and statusbar.
local function update_bars()
  set_title()
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  events.emit(events.UPDATE_UI)
end
events_connect(events.BUFFER_AFTER_SWITCH, update_bars)
events_connect(events.VIEW_AFTER_SWITCH, update_bars)

events_connect(events.RESET_AFTER,
               function() ui.statusbar_text = 'Lua reset' end)

-- Prompts for confirmation if any buffers are modified.
events_connect(events.QUIT, function()
  local list = {}
  for _, buffer in ipairs(_BUFFERS) do
    if buffer.modify then
      local filename = buffer.filename or buffer._type or _L['Untitled']
      list[#list + 1] = filename:iconv('UTF-8', _CHARSET)
    end
  end
  local cancel = #list > 0 and ui.dialogs.msgbox{
    title = _L['Quit without saving?'],
    text = _L['The following buffers are unsaved:'],
    informative_text = table.concat(list, '\n'), icon = 'gtk-dialog-question',
    button1 = _L['_Cancel'], button2 = _L['Quit _without saving']
  } ~= 2
  if cancel then return true end -- prevent quit
end)

-- Keeps track of and switches back to the previous buffer after buffer close.
events_connect(events.BUFFER_BEFORE_SWITCH, function()
  view._prev_buffer = buffer
end)
events_connect(events.BUFFER_DELETED, function()
  local i = _BUFFERS[view._prev_buffer]
  if i and _BUFFERS[buffer] ~= i then view:goto_buffer(i) end
end)

-- Enables and disables mouse mode in curses and focuses and resizes views based
-- on mouse events.
if CURSES then
  if not WIN32 then
    io.stdout:write("\x1b[?1002h") -- enable mouse mode
    io.stdout:flush()
    events.connect(events.QUIT, function()
      io.stdout:write("\x1b[?1002l") -- disable mouse mode
      io.stdout:flush()
    end)
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
      return get_view(view[2], vertical and y or y - size - 1,
                      vertical and x - size - 1 or x)
    else
      return view -- in-between views; return the split itself
    end
  end

  local resize
  events.connect(events.MOUSE, function(event, button, y, x)
    if event == buffer.MOUSE_RELEASE or button ~= 1 then return end
    if event == buffer.MOUSE_PRESS then
      local view = get_view(ui.get_split_table(), y - 1, x) -- title is at y = 1
      if not view[1] and not view[2] then
        ui.goto_view(_VIEWS[view])
        resize = nil
      else
        resize = function(y2, x2)
          view[1].size = view.size + (view.vertical and x2 - x or y2 - y)
        end
      end
    elseif resize then
      resize(y, x)
    end
  end)
end

events_connect(events.ERROR, ui.print)

--[[ The tables below were defined in C.

---
-- A table of menus defining a menubar.
-- This is a low-level field. You probably want to use the higher-level
-- `textadept.menu.menubar`.
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
-- Low-level function for prompting the user with a [gtdialog][] of kind *kind*
-- with the given string and table arguments, returning a formatted string of
-- the dialog's output.
-- You probably want to use the higher-level functions in the [`ui.dialogs`]()
-- module.
-- Table arguments containing strings are allowed and expanded in place. This is
-- useful for filtered list dialogs with many items.
--
-- [gtdialog]: http://foicica.com/gtdialog/manual.html#Usage
-- @param kind The kind of gtdialog.
-- @param ... Parameters to the gtdialog.
-- @return string gtdialog result.
-- @class function
-- @name dialog
local dialog

---
-- Returns a split table that contains Textadept's current split view structure.
-- This is primarily used in session saving.
-- @return table of split views. Each split view entry is a table with 4
--   fields: `1`, `2`, `vertical`, and `size`. `1` and `2` have values of either
--   nested split view entries or the views themselves; `vertical` is a flag
--   that indicates if the split is vertical or not; and `size` is the integer
--   position of the split resizer.
-- @class function
-- @name get_split_table
local get_split_table

---
-- Shifts to view number *n*.
-- *relative* indicates whether or not *n* is an index relative to the current
-- view's index in `_VIEWS` instead of an absolute index.
-- Emits `VIEW_BEFORE_SWITCH` and `VIEW_AFTER_SWITCH` events.
-- @param n A relative or absolute view index in `_VIEWS`.
-- @param relative Optional flag that indicates whether *n* is a relative or
--   absolute index. The default value is `false`, for an absolute index.
-- @see _G._VIEWS
-- @see events.VIEW_BEFORE_SWITCH
-- @see events.VIEW_AFTER_SWITCH
-- @class function
-- @name goto_view
local goto_view

---
-- Low-level function for creating a menu from table *menu_table* and returning
-- the userdata.
-- You probably want to use the higher-level `textadept.menu.menubar`,
-- `textadept.menu.context_menu`, or `textadept.menu.tab_context_menu` tables.
-- Emits a `MENU_CLICKED` event when a menu item is selected.
-- @param menu_table A table defining the menu. It is an ordered list of tables
--   with a string menu item, integer menu ID, and optional GDK keycode and
--   modifier mask. The latter two are used to display key shortcuts in the
--   menu. '_' characters are treated as a menu mnemonics. If the menu item is
--   empty, a menu separator item is created. Submenus are just nested
--   menu-structure tables. Their title text is defined with a `title` key.
-- @usage ui.menu{{'_New', 1}, {'_Open', 2}, {''}, {'_Quit', 4}}
-- @usage ui.menu{{'_New', 1, string.byte('n'), 4}} -- 'Ctrl+N'
-- @see events.MENU_CLICKED
-- @see textadept.menu.menubar
-- @see textadept.menu.context_menu
-- @see textadept.menu.tab_context_menu
-- @class function
-- @name menu
local menu
]]

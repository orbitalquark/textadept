-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local gui = gui

--[[ This comment is for LuaDoc.
--- The core gui table.
-- @field title (string, Write-only)
--   The title of the Textadept window.
-- @field context_menu
--   A GTK menu defining the editor's context menu.
-- @field clipboard_text (string, Read-only)
--   The text on the clipboard.
-- @field statusbar_text (string, Write-only)
--   The text displayed by the statusbar.
-- @field docstatusbar_text (string, Write-only)
--   The text displayed by the doc statusbar.
module('gui')]]

local _L = _L

-- Helper function for printing messages to buffers.
-- @see gui._print
local function _print(buffer_type, ...)
  if buffer._type ~= buffer_type then
    for i, view in ipairs(_VIEWS) do
      if view.buffer._type == buffer_type then gui.goto_view(i) break end
    end
    if view.buffer._type ~= buffer_type then
      view:split()
      for i, buffer in ipairs(_BUFFERS) do
        if buffer._type == buffer_type then view:goto_buffer(i) break end
      end
      if buffer._type ~= buffer_type then
        new_buffer()._type = buffer_type
        events.emit(events.FILE_OPENED)
      end
    end
  end
  local args, n = {...}, select('#', ...)
  for i = 1, n do args[i] = tostring(args[i]) end
  buffer:append_text(table.concat(args, '\t'))
  buffer:append_text('\n')
  buffer:goto_pos(buffer.length)
  buffer:set_save_point()
end
---
-- Helper function for printing messages to buffers.
-- Splits the view and opens a new buffer for printing messages. If the message
-- buffer is already open and a view is currently showing it, the message is
-- printed to that view. Otherwise the view is split, goes to the open message
-- buffer, and prints to it.
-- @param buffer_type String type of message buffer.
-- @param ... Message strings.
-- @usage gui._print(_L['[Error Buffer]'], error_message)
-- @usage gui._print(_L['[Message Buffer]'], message)
-- @name _print
function gui._print(buffer_type, ...) pcall(_print, buffer_type, ...) end

---
-- Prints messages to the Textadept message buffer.
-- Opens a new buffer (if one has not already been opened) for printing
-- messages.
-- @param ... Message strings.
-- @name print
function gui.print(...) gui._print(_L['[Message Buffer]'], ...) end

---
-- Shortcut function for `gui.dialog('filtered_list', ...)` with 'Ok' and
-- 'Cancel' buttons.
-- @param title The title for the filteredlist dialog.
-- @param columns A column name or list of column names.
-- @param items An item or list of items.
-- @param int_return If `true`, returns the integer index of the selected item
--   in the filteredlist. The default value is `false`, which returns the string
--   item. Not compatible with a `'--select-multiple'` filteredlist.
-- @param ... Additional parameters to pass to `gui.dialog()`.
-- @return Either a string or integer on success; `nil` otherwise.
-- @usage gui.filteredlist('Title', 'Foo', { 'Bar', 'Baz' })
-- @usage gui.filteredlist('Title', { 'Foo', 'Bar' }, { 'a', 'b', 'c', 'd' },
--                         false, '--output-column', '2')
-- @name filteredlist
function gui.filteredlist(title, columns, items, int_return, ...)
  local out = gui.dialog('filteredlist',
                         '--title', title,
                         '--button1', _L['_OK'],
                         '--button2', _L['_Cancel'],
                         '--no-newline',
                         int_return and '' or '--string-output',
                         '--columns', columns,
                         '--items', items,
                         ...)
  local patt = int_return and '^(%-?%d+)\n(%d+)$' or '^([^\n]+)\n(.+)$'
  local response, value = out:match(patt)
  if response == (int_return and '1' or _L['_OK']) then
    return not int_return and value or tonumber(value)
  end
end

---
-- Displays a dialog with a list of buffers to switch to and switches to the
-- selected one, if any.
-- @name switch_buffer
function gui.switch_buffer()
  local columns, items = { _L['Name'], _L['File'] }, {}
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type or _L['Untitled']
    local basename = buffer.filename and filename:match('[^/\\]+$') or filename
    items[#items + 1] = (buffer.dirty and '*' or '')..basename
    items[#items + 1] = filename
  end
  local i = gui.filteredlist(_L['Switch Buffers'], columns, items, true)
  if i then view:goto_buffer(i + 1) end
end

---
-- Goes to the buffer with the given filename.
-- If the desired buffer is open in a view, goes to that view. Otherwise, opens
-- the buffer in either the `preferred_view` if given, the first view that is
-- not the current one, a split view if `split` is `true`, or the current view.
-- @param filename The filename of the buffer to go to.
-- @param split If there is only one view, split it and open the buffer in the
--   other view.
-- @param preferred_view When multiple views exist and the desired buffer is not
--   open in any of them, open it in this one.
-- @param sloppy Flag indicating whether or not to not match `filename` to
--   `buffer.filename` exactly. When `true`, matches `filename` to only the last
--   part of `buffer.filename` This is useful for run and compile commands which
--   output relative filenames and paths instead of full ones and it is likely
--   that the file in question is already open. The default value is `false`.
-- @name goto_file
function gui.goto_file(filename, split, preferred_view, sloppy)
  local patt = not sloppy and '^'..filename..'$' or filename..'$'
  if #_VIEWS == 1 and split and not (view.buffer.filename or ''):find(patt) then
    view:split()
  else
    local other_view = _VIEWS[preferred_view]
    for i, v in ipairs(_VIEWS) do
      if (v.buffer.filename or ''):find(patt) then gui.goto_view(i) return end
      if not other_view and v ~= view then other_view = i end
    end
    if other_view then gui.goto_view(other_view) end
  end
  for i, buffer in ipairs(_BUFFERS) do
    if (buffer.filename or ''):find(patt) then view:goto_buffer(i) return end
  end
  io.open_file(filename)
end

local THEME
---
-- Sets the editor theme from the given name.
-- Themes in `_USERHOME/themes/` are checked first, followed by `_HOME/themes/`.
-- If the name contains slashes ('/' on Linux and Mac OSX and '\' on Win32), it
-- is assumed to be an absolute path so `_USERHOME` and `_HOME` are not checked.
-- Throws an error if the theme is not found. Any errors in the theme are
-- printed to `io.stderr`.
-- @param name The name or absolute path of a theme. If nil, sets the default
--   theme.
-- @name set_theme
function gui.set_theme(name)
  if not name then
    -- Read theme from ~/.textadept/theme, defaulting to 'light'.
    local f = io.open(_USERHOME..'/theme', 'rb')
    if f then
      name = f:read('*line'):match('[^\r\n]+')
      f:close()
    end
    if not name or name == '' then name = 'light' end
  end

  -- Get the path of the theme.
  local theme
  if not name:find('[/\\]') then
    if lfs.attributes(_USERHOME..'/themes/'..name) then
      theme = _USERHOME..'/themes/'..name
    elseif lfs.attributes(_HOME..'/themes/'..name) then
      theme = _HOME..'/themes/'..name
    end
  elseif lfs.attributes(name) then
    theme = name
  end
  if not theme then error(('"%s" %s'):format(name, _L["theme not found."])) end

  if buffer and view then
    local current_buffer, current_view = _BUFFERS[buffer], _VIEWS[view]
    for i in ipairs(_BUFFERS) do
      view:goto_buffer(i)
      buffer.property['lexer.lpeg.color.theme'] = theme..'/lexer.lua'
      local lexer = buffer:get_lexer()
      buffer:set_lexer('null') -- lexer needs to be changed to reset styles
      buffer:set_lexer(lexer)
      local ok, err = pcall(dofile, theme..'/buffer.lua')
      if not ok then io.stderr:write(err) end
    end
    view:goto_buffer(current_buffer)
    for i in ipairs(_VIEWS) do
      gui.goto_view(i)
      local lexer = buffer:get_lexer()
      buffer:set_lexer('null') -- lexer needs to be changed to reset styles
      buffer:set_lexer(lexer)
      local ok, err = pcall(dofile, theme..'/view.lua')
      if not ok then io.stderr:write(err) end
    end
    gui.goto_view(current_view)
  end
  THEME = theme
end

---
-- Prompts the user to select an editor theme from a filtered list.
-- @name select_theme
function gui.select_theme()
  local themes, themes_found = {}, {}
  for theme in lfs.dir(_HOME..'/themes') do
    if not theme:find('^%.%.?$') then themes_found[theme] = true end
  end
  if lfs.attributes(_USERHOME..'/themes') then
    for theme in lfs.dir(_USERHOME..'/themes') do
      if not theme:find('^%.%.?$') then themes_found[theme] = true end
    end
  end
  for theme in pairs(themes_found) do themes[#themes + 1] = theme end
  table.sort(themes)
  local theme = gui.filteredlist(_L['Select Theme'], _L['Name'], themes)
  if not theme then return end
  gui.set_theme(theme)
  -- Write the theme to the user's theme file.
  local f = io.open(_USERHOME..'/theme', 'wb')
  if not f then return end
  f:write(theme)
  f:close()
end

local events, events_connect = events, events.connect

-- Sets default properties for a Scintilla window.
events_connect(events.VIEW_NEW, function()
  local buffer = buffer
  local c = _SCINTILLA.constants

  -- Allow redefinitions of these Scintilla key commands.
  local ctrl_keys = {
    '[', ']', '/', '\\', 'Z', 'Y', 'X', 'C', 'V', 'A', 'L', 'T', 'D', 'U'
  }
  local ctrl_shift_keys = { 'L', 'T', 'U', 'Z' }
  for _, key in ipairs(ctrl_keys) do
    buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL)
  end
  for _, key in ipairs(ctrl_shift_keys) do
    buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL + c.SCMOD_SHIFT)
  end
  -- Load theme.
  local ok, err = pcall(dofile, THEME..'/view.lua')
  if not ok then io.stderr:write(err) end
end)
events_connect(events.VIEW_NEW, function() events.emit(events.UPDATE_UI) end)

local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.functions.set_lexer_language[1]
local function set_properties()
  local buffer = buffer
  -- Lexer.
  buffer:set_lexer_language('lpeg')
  buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, 'container')
  buffer.style_bits = 8
  -- Properties.
  buffer.property['textadept.home'] = _HOME
  buffer.property['lexer.lpeg.home'] = _LEXERPATH
  buffer.property['lexer.lpeg.color.theme'] = THEME..'/lexer.lua'
  -- Buffer.
  buffer.code_page = _SCINTILLA.constants.SC_CP_UTF8
  -- Load theme.
  local ok, err = pcall(dofile, THEME..'/buffer.lua')
  if not ok then io.stderr:write(err) end
end

-- Sets default properties for a Scintilla document.
events_connect(events.BUFFER_NEW, function()
  -- Normally when an error occurs, a new buffer is created with the error
  -- message, but if an error occurs here, this event would be called again and
  -- again, erroring each time resulting in an infinite loop; print error to
  -- stderr instead.
  local ok, err = pcall(set_properties)
  if not ok then io.stderr:write(err) end
end)

-- Sets the title of the Textadept window to the buffer's filename.
-- @param buffer The global buffer.
local function set_title(buffer)
  local filename = buffer.filename or buffer._type or _L['Untitled']
  local basename = buffer.filename and filename:match('[^/\\]+$') or filename
  gui.title = string.format('%s %s Textadept (%s)', basename,
                            buffer.dirty and '*' or '-', filename)
end

-- Changes Textadept title to show the buffer as being "clean".
events_connect(events.SAVE_POINT_REACHED, function()
  buffer.dirty = false
  set_title(buffer)
end)

-- Changes Textadept title to show thee buffer as "dirty".
events_connect(events.SAVE_POINT_LEFT, function()
  buffer.dirty = true
  set_title(buffer)
end)

-- Open uri(s).
events_connect(events.URI_DROPPED, function(utf8_uris)
  for utf8_uri in utf8_uris:gmatch('[^\r\n]+') do
    if utf8_uri:find('^file://') then
      utf8_uri = utf8_uri:match('^file://([^\r\n]+)')
      utf8_uri = utf8_uri:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
      end)
      if WIN32 then utf8_uri = utf8_uri:sub(2, -1) end -- ignore leading '/'
      local uri = utf8_uri:iconv(_CHARSET, 'UTF-8')
      if lfs.attributes(uri).mode ~= 'directory' then io.open_file(utf8_uri) end
    end
  end
end)
events_connect(events.APPLEEVENT_ODOC, function(uri)
  return events.emit(events.URI_DROPPED, 'file://'..uri)
end)

local string_format = string.format
local EOLs = { _L['CRLF'], _L['CR'], _L['LF'] }
local GETLEXERLANGUAGE = _SCINTILLA.functions.get_lexer_language[1]
-- Sets docstatusbar text.
events_connect(events.UPDATE_UI, function()
  local buffer = buffer
  local pos = buffer.current_pos
  local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
  local col = buffer.column[pos] + 1
  local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE)
  local eol = EOLs[buffer.eol_mode + 1]
  local tabs = string_format('%s %d', buffer.use_tabs and _L['Tabs:'] or
                             _L['Spaces:'], buffer.indent)
  local enc = buffer.encoding or ''
  local text = not NCURSES and '%s %d/%d    %s %d    %s    %s    %s    %s' or
                               '%s %d/%d  %s %d  %s  %s  %s  %s'
  gui.docstatusbar_text = string_format(text, _L['Line:'], line, max,
                                        _L['Col:'], col, lexer, eol, tabs, enc)
end)

-- Toggles folding.
events_connect(events.MARGIN_CLICK, function(margin, pos, modifiers)
  if margin == 2 then buffer:toggle_fold(buffer:line_from_position(pos)) end
end)

-- Updates the statusbar and titlebar for a new Scintilla document.
events_connect(events.BUFFER_NEW, function() events.emit(events.UPDATE_UI) end)
events_connect(events.BUFFER_NEW, function() set_title(buffer) end)

-- Save buffer properties.
events_connect(events.BUFFER_BEFORE_SWITCH, function()
  local buffer = buffer
  -- Save view state.
  buffer._anchor, buffer._current_pos = buffer.anchor, buffer.current_pos
  buffer._first_visible_line = buffer.first_visible_line
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
  for _, i in ipairs(buffer._folds) do buffer:toggle_fold(i) end
  -- Restore view state.
  buffer:set_sel(buffer._anchor, buffer._current_pos)
  buffer:line_scroll(0,
                     buffer:visible_from_doc_line(buffer._first_visible_line) -
                     buffer.first_visible_line)
end)

-- Updates titlebar and statusbar.
events_connect(events.BUFFER_AFTER_SWITCH, function()
  set_title(buffer)
  events.emit(events.UPDATE_UI)
end)

-- Updates titlebar and statusbar.
events_connect(events.VIEW_AFTER_SWITCH, function()
  set_title(buffer)
  events.emit(events.UPDATE_UI)
end)

events_connect(events.RESET_AFTER,
               function() gui.statusbar_text = 'Lua reset' end)

-- Prompts for confirmation if any buffers are dirty.
events_connect(events.QUIT, function()
  local list = {}
  for _, buffer in ipairs(_BUFFERS) do
    if buffer.dirty then
      list[#list + 1] = buffer.filename or buffer._type or _L['Untitled']
    end
  end
  return #list < 1 or gui.dialog('msgbox',
                                 '--title', _L['Quit without saving?'],
                                 '--text',
                                 _L['The following buffers are unsaved:'],
                                 '--informative-text', table.concat(list, '\n'),
                                 '--button1', _L['_Cancel'],
                                 '--button2', _L['Quit _without saving'],
                                 '--no-newline') == '2'
end)

events_connect(events.ERROR,
               function(...) gui._print(_L['[Error Buffer]'], ...) end)

--[[ The tables below were defined in C.

---
-- A table of GTK menus defining a menubar. (Write-only)
-- @class table
-- @name menubar
local menubar

---
-- The size of the Textadept window (`{ width, height }`).
-- @class table
-- @name size
local size

The functions below are Lua C functions.

---
-- Displays a gtdialog of a specified type with the given string arguments.
-- Each argument is like a string in Lua's `arg` table. Tables of strings are
-- allowed as arguments and are expanded in place. This is useful for
-- filteredlist dialogs with many items.
-- @param kind The kind of gtdialog.
-- @param ... Parameters to the gtdialog.
-- @return string gtdialog result.
-- @class function
-- @name dialog
local dialog

---
-- Gets the current split view structure.
-- @return table of split views. Each split view entry is a table with 4
--   fields: `1`, `2`, `vertical`, and `size`. `1` and `2` have values of either
--   nested split view entries or the views themselves; `vertical` is a flag
--   indicating if the split is vertical or not; and `size` is the integer
--   position of the split resizer.
-- @class function
-- @name get_split_table
local get_split_table

---
-- Goes to the specified view.
-- Generates `VIEW_BEFORE_SWITCH` and `VIEW_AFTER_SWITCH` events.
-- @param n A relative or absolute view index.
-- @param relative Flag indicating if n is a relative index or not. The default
--   value is `false`.
-- @class function
-- @name goto_view
local goto_view

---
-- Creates a menu, returning the userdata.
-- @param menu_table A table defining the menu. It is an ordered list of tables
--   with a string menu item, integer menu ID, and optional GDK keycode and
--   modifier mask. The latter two are used to display key shortcuts in the
--   menu. `_` characters are treated as a menu mnemonics. If the menu item is
--   empty, a menu separator item is created. Submenus are just nested
--   menu-structure tables. Their title text is defined with a `title` key.
-- @usage gui.menu{ { '_New', 1 }, { '_Open', 2 }, { '' }, { '_Quit', 4 } }
-- @usage gui.menu{ { '_New', 1, keys.get_gdk_key('cn') } }
-- @see keys.get_gdk_key
-- @class function
-- @name menu
local menu
]]

-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Contributions from Robert Gieseke.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines the menus used by Textadept.
-- If applicable, load this module last in your *~/.textadept/init.lua*, after
-- `textadept.keys` since it looks up defined key commands to show them in
-- menus.
module('textadept.menu')]]

local _L, buffer, view = _L, buffer, view
local editing, utils = textadept.editing, textadept.keys.utils
local SEPARATOR = {''}

-- The default main menubar.
local menubar = {
  { title = _L['_File'],
    {_L['_New'], buffer.new},
    {_L['_Open'], io.open_file},
    {_L['Open _Recent...'], io.open_recent_file},
    {_L['Re_load'], io.reload_file},
    {_L['_Save'], io.save_file},
    {_L['Save _As'], io.save_file_as},
    SEPARATOR,
    {_L['_Close'], io.close_buffer},
    {_L['Close All'], io.close_all_buffers},
    SEPARATOR,
    {_L['Loa_d Session...'], textadept.session.load},
    {_L['Sav_e Session...'], textadept.session.save},
    SEPARATOR,
    {_L['_Quit'], quit},
  },
  { title = _L['_Edit'],
    {_L['_Undo'], buffer.undo},
    {_L['_Redo'], buffer.redo},
    SEPARATOR,
    {_L['Cu_t'], buffer.cut},
    {_L['_Copy'], buffer.copy},
    {_L['_Paste'], buffer.paste},
    {_L['Duplicate _Line'], buffer.line_duplicate},
    {_L['_Delete'], buffer.clear},
    {_L['D_elete Word'], utils.delete_word},
    {_L['Select _All'], buffer.select_all},
    SEPARATOR,
    {_L['_Match Brace'], editing.match_brace},
    {_L['Complete _Word'], editing.autocomplete_word},
    {_L['_Highlight Word'], editing.highlight_word},
    {_L['Toggle _Block Comment'], editing.block_comment},
    {_L['T_ranspose Characters'], editing.transpose_chars},
    {_L['_Join Lines'], editing.join_lines},
    {_L['_Filter Through'], {ui.command_entry.enter_mode, 'filter_through'}},
    { title = _L['_Select'],
      {_L['Select to _Matching Brace'], {editing.match_brace, 'select'}},
      {_L['Select between _XML Tags'], {editing.select_enclosed, '>', '<'}},
      {_L['Select in XML _Tag'], {editing.select_enclosed, '<', '>'}},
      {_L['Select in _Single Quotes'], {editing.select_enclosed, "'", "'"}},
      {_L['Select in _Double Quotes'], {editing.select_enclosed, '"', '"'}},
      {_L['Select in _Parentheses'], {editing.select_enclosed, '(', ')'}},
      {_L['Select in _Brackets'], {editing.select_enclosed, '[', ']'}},
      {_L['Select in B_races'], {editing.select_enclosed, '{', '}'}},
      {_L['Select _Word'], editing.select_word},
      {_L['Select _Line'], editing.select_line},
      {_L['Select Para_graph'], editing.select_paragraph},
      {_L['Select _Indented Block'], editing.select_indented_block},
    },
    { title = _L['Selectio_n'],
      {_L['_Upper Case Selection'], buffer.upper_case},
      {_L['_Lower Case Selection'], buffer.lower_case},
      SEPARATOR,
      {_L['Enclose as _XML Tags'], utils.enclose_as_xml_tags},
      {_L['Enclose as Single XML _Tag'], {editing.enclose, '<', ' />'}},
      {_L['Enclose in Single _Quotes'], {editing.enclose, "'", "'"}},
      {_L['Enclose in _Double Quotes'], {editing.enclose, '"', '"'}},
      {_L['Enclose in _Parentheses'], {editing.enclose, '(', ')'}},
      {_L['Enclose in _Brackets'], {editing.enclose, '[', ']'}},
      {_L['Enclose in B_races'], {editing.enclose, '{', '}'}},
      SEPARATOR,
      {_L['_Move Selected Lines Up'], buffer.move_selected_lines_up},
      {_L['Move Selected Lines Do_wn'], buffer.move_selected_lines_down},
    },
  },
  { title = _L['_Search'],
    {_L['_Find'], ui.find.focus},
    {_L['Find _Next'], ui.find.find_next},
    {_L['Find _Previous'], ui.find.find_prev},
    {_L['_Replace'], ui.find.replace},
    {_L['Replace _All'], ui.find.replace_all},
    {_L['Find _Incremental'], ui.find.find_incremental},
    SEPARATOR,
    {_L['Find in Fi_les'], utils.find_in_files},
    {_L['Goto Nex_t File Found'], {ui.find.goto_file_found, false, true}},
    {_L['Goto Previou_s File Found'], {ui.find.goto_file_found, false, false}},
    SEPARATOR,
    {_L['_Jump to'], editing.goto_line},
  },
  { title = _L['_Tools'],
    {_L['Command _Entry'], {ui.command_entry.enter_mode, 'lua_command'}},
    {_L['Select Co_mmand'], utils.select_command},
    SEPARATOR,
    {_L['_Run'], textadept.run.run},
    {_L['_Compile'], textadept.run.compile},
    {_L['_Next Error'], {textadept.run.goto_error, false, true}},
    {_L['_Previous Error'], {textadept.run.goto_error, false, false}},
    SEPARATOR,
    { title = _L['_Adeptsense'],
      {_L['_Complete Symbol'], textadept.adeptsense.complete},
      {_L['Show _Documentation'], textadept.adeptsense.show_apidoc},
    },
    { title = _L['_Bookmark'],
      {_L['_Toggle Bookmark'], textadept.bookmarks.toggle},
      {_L['_Clear Bookmarks'], textadept.bookmarks.clear},
      {_L['_Next Bookmark'], {textadept.bookmarks.goto_mark, true}},
      {_L['_Previous Bookmark'], {textadept.bookmarks.goto_mark, false}},
      {_L['_Goto Bookmark...'], textadept.bookmarks.goto_mark},
    },
    { title = _L['Snap_open'],
      {_L['Snapopen _User Home'], {io.snapopen, _USERHOME}},
      {_L['Snapopen _Textadept Home'], {io.snapopen, _HOME}},
      {_L['Snapopen _Current Directory'], utils.snapopen_filedir},
    },
    { title = _L['_Snippets'],
      {_L['_Insert Snippet...'], textadept.snippets._select},
      {_L['_Expand Snippet/Next Placeholder'], textadept.snippets._insert},
      {_L['_Previous Snippet Placeholder'], textadept.snippets._previous},
      {_L['_Cancel Snippet'], textadept.snippets._cancel_current},
    },
    SEPARATOR,
    {_L['Show St_yle'], utils.show_style},
  },
  { title = _L['_Buffer'],
    {_L['_Next Buffer'], {view.goto_buffer, view, 1, true}},
    {_L['_Previous Buffer'], {view.goto_buffer, view, -1, true}},
    {_L['_Switch to Buffer...'], ui.switch_buffer},
    SEPARATOR,
    { title = _L['_Indentation'],
      {_L['Tab width: _2'], {utils.set_indentation, 2}},
      {_L['Tab width: _3'], {utils.set_indentation, 3}},
      {_L['Tab width: _4'], {utils.set_indentation, 4}},
      {_L['Tab width: _8'], {utils.set_indentation, 8}},
      SEPARATOR,
      {_L['_Toggle Use Tabs'], {utils.toggle_property, 'use_tabs'}},
      {_L['_Convert Indentation'], editing.convert_indentation},
    },
    { title = _L['_EOL Mode'],
      {_L['CRLF'], {utils.set_eol_mode, buffer.SC_EOL_CRLF}},
      {_L['CR'], {utils.set_eol_mode, buffer.SC_EOL_CR}},
      {_L['LF'], {utils.set_eol_mode, buffer.SC_EOL_LF}},
    },
    { title = _L['E_ncoding'],
      {_L['_UTF-8 Encoding'], {utils.set_encoding, 'UTF-8'}},
      {_L['_ASCII Encoding'], {utils.set_encoding, 'ASCII'}},
      {_L['_ISO-8859-1 Encoding'], {utils.set_encoding, 'ISO-8859-1'}},
      {_L['_MacRoman Encoding'], {utils.set_encoding, 'MacRoman'}},
      {_L['UTF-1_6 Encoding'], {utils.set_encoding, 'UTF-16LE'}},
    },
    SEPARATOR,
    {_L['Select _Lexer...'], textadept.file_types.select_lexer},
    {_L['_Refresh Syntax Highlighting'], {buffer.colourise, buffer, 0, -1}},
  },
  { title = _L['_View'],
    {_L['_Next View'], {ui.goto_view, 1, true}},
    {_L['_Previous View'], {ui.goto_view, -1, true}},
    SEPARATOR,
    {_L['Split View _Horizontal'], {view.split, view}},
    {_L['Split View _Vertical'], {view.split, view, true}},
    {_L['_Unsplit View'], {view.unsplit, view}},
    {_L['Unsplit _All Views'], utils.unsplit_all},
    {_L['_Grow View'], {utils.grow, 10}},
    {_L['Shrin_k View'], {utils.shrink, 10}},
    SEPARATOR,
    {_L['Toggle Current _Fold'], utils.toggle_current_fold},
    SEPARATOR,
    {_L['Toggle View _EOL'], {utils.toggle_property, 'view_eol'}},
    {_L['Toggle _Wrap Mode'], {utils.toggle_property, 'wrap_mode'}},
    {_L['Toggle Show In_dent Guides'],
      {utils.toggle_property, 'indentation_guides'}},
    {_L['Toggle View White_space'], {utils.toggle_property, 'view_ws'}},
    {_L['Toggle _Virtual Space'],
      {utils.toggle_property, 'virtual_space_options',
       buffer.SCVS_USERACCESSIBLE}},
    SEPARATOR,
    {_L['Zoom _In'], buffer.zoom_in},
    {_L['Zoom _Out'], buffer.zoom_out},
    {_L['_Reset Zoom'], utils.reset_zoom},
  },
  { title = _L['_Help'],
    {_L['Show _Manual'],
      {utils.open_webpage, _HOME..'/doc/01_Introduction.html'}},
    {_L['Show _LuaDoc'], {utils.open_webpage, _HOME..'/doc/api/index.html'}},
    SEPARATOR,
    {_L['_About'],
      {ui.dialog, 'ok-msgbox', '--title', 'Textadept', '--text', _RELEASE,
       '--informative-text', 'Copyright © 2007-2013 Mitchell. See LICENSE\n'..
       'http://foicica.com/textadept', '--button1', _L['_OK'], '--no-cancel',
       '--icon-file', _HOME..'/core/images/ta_64x64.png'}},
  },
}

-- The default right-click context menu.
local context_menu = {
  {_L['_Undo'], buffer.undo},
  {_L['_Redo'], buffer.redo},
  SEPARATOR,
  {_L['Cu_t'], buffer.cut},
  {_L['_Copy'], buffer.copy},
  {_L['_Paste'], buffer.paste},
  {_L['_Delete'], buffer.clear},
  SEPARATOR,
  {_L['Select _All'], buffer.select_all}
}

-- Returns the GDK integer keycode and modifier mask for a key sequence.
-- This is used for creating menu accelerators.
-- @param key_seq The string key sequence.
-- @return keycode and modifier mask
local function get_gdk_key(key_seq)
  if not key_seq then return nil end
  local mods, key = key_seq:match('^([cams]*)(.+)$')
  if not mods or not key then return nil end
  local modifiers = ((mods:find('s') or key:lower() ~= key) and 1 or 0) +
                    (mods:find('c') and 4 or 0) + (mods:find('a') and 8 or 0) +
                    (mods:find('m') and 268435456 or 0)
  local byte = string.byte(key)
  if #key > 1 or byte < 32 then
    for i, s in pairs(keys.KEYSYMS) do
      if s == key and i > 0xFE20 then byte = i break end
    end
  end
  return byte, modifiers
end

-- Get a string uniquely identifying a key binding.
-- This is used to match menu items with key bindings to show the key shortcut.
-- @param f A value in the `keys` table.
local function get_id(f)
  local id = ''
  if type(f) == 'function' then
    id = tostring(f)
  elseif type(f) == 'table' then
    for i = 1, #f do id = id..tostring(f[i]) end
  end
  return id
end

local key_shortcuts, menu_actions, contextmenu_actions

-- Creates a menu suitable for `ui.menu()` from the menu table format.
-- Also assigns key commands.
-- @param menu The menu to create a GTK+ menu from.
-- @param contextmenu Flag indicating whether or not the menu is a context menu.
--   If so, menu_id offset is 1000. The default value is `false`.
-- @return GTK+ menu that can be passed to `ui.menu()`.
-- @see ui.menu
local function read_menu_table(menu, contextmenu)
  local gtkmenu = {}
  gtkmenu.title = menu.title
  for _, menuitem in ipairs(menu) do
    if menuitem.title then
      gtkmenu[#gtkmenu + 1] = read_menu_table(menuitem, contextmenu)
    else
      local label, f = menuitem[1], menuitem[2]
      local menu_id = not contextmenu and #menu_actions + 1 or
                      #contextmenu_actions + 1000 + 1
      local key, mods = get_gdk_key(key_shortcuts[get_id(f)])
      gtkmenu[#gtkmenu + 1] = {label, menu_id, key, mods}
      if f then
        local actions = not contextmenu and menu_actions or contextmenu_actions
        actions[menu_id < 1000 and menu_id or menu_id - 1000] = f
      end
    end
  end
  return gtkmenu
end

-- Builds the item and commands tables for the filtered list dialog.
-- @param menu The menu to read from.
-- @param title The title of the menu.
-- @param items The current list of items.
-- @param commands The current list of commands.
local function build_command_tables(menu, title, items, commands)
  for _, menuitem in ipairs(menu) do
    if menuitem.title then
      build_command_tables(menuitem, menuitem.title, items, commands)
    elseif menuitem[1] ~= '' then
      local label, f = menuitem[1], menuitem[2]
      if title then label = title..': '..label end
      items[#items + 1] = label:gsub('_([^_])', '%1')
      items[#items + 1] = key_shortcuts[get_id(f)] or ''
      commands[#commands + 1] = f
    end
  end
end

local items, commands

---
-- Sets `ui.menubar` from *menubar*, a table of menus.
-- Each menu is an ordered list of menu items and has a `title` key for the
-- title text. Menu items are tables containing menu text and either a function
-- to call or a table containing a function with its parameters to call when an
-- item is clicked. Menu items may also be sub-menus, ordered lists of menu
-- items with an additional `title` key for the sub-menu's title text.
-- @param menubar The table of menu tables to create the menubar from.
-- @see ui.menubar
-- @see ui.menu
-- @name set_menubar
function M.set_menubar(menubar)
  key_shortcuts = {}
  for key, f in pairs(keys) do key_shortcuts[get_id(f)] = key end
  menu_actions = {}
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = ui.menu(read_menu_table(menubar[i]))
  end
  ui.menubar = _menubar
  items, commands = {}, {}
  build_command_tables(menubar, nil, items, commands)
end
M.set_menubar(menubar)

---
-- Sets `ui.context_menu` from *menu*, an ordered list of menu items.
-- Menu items are tables containing menu text and either a function to call or
-- a table containing a function with its parameters to call when an item is
-- clicked. Menu items may also be sub-menus, ordered lists of menu items with
-- an additional `title` key for the sub-menu's title text.
-- @param menu The menu table to create the context menu from.
-- @see ui.context_menu
-- @see ui.menu
-- @name set_contextmenu
function M.set_contextmenu(menu)
  contextmenu_actions = {}
  ui.context_menu = ui.menu(read_menu_table(menu, true))
end
if not CURSES then M.set_contextmenu(context_menu) end

---
-- Prompts the user to select a menu command to run.
-- @name select_command
function M.select_command()
  local i = ui.filteredlist(_L['Run Command'],
                            {_L['Command'], _L['Key Command']}, items, true,
                            CURSES and {'--width', ui.size[1] - 2} or '')
  if i then keys.run_command(commands[i + 1], type(commands[i + 1])) end
end

-- Performs the appropriate action when clicking a menu item.
events.connect(events.MENU_CLICKED, function(menu_id)
  local actions = menu_id < 1000 and menu_actions or contextmenu_actions
  local action = actions[menu_id < 1000 and menu_id or menu_id - 1000]
  if type(action) ~= 'function' and type(action) ~= 'table' then
    error(_L['Unknown command:']..' '..tostring(action))
  end
  keys.run_command(action, type(action))
end)

if not CURSES then
  -- Set a language-specific context menu or the default one.
  local function set_language_contextmenu()
    local lang = _G.buffer:get_lexer()
    M.set_contextmenu(_M[lang] and _M[lang].context_menu or context_menu)
  end
  events.connect(events.LEXER_LOADED, set_language_contextmenu)
  events.connect(events.BUFFER_AFTER_SWITCH, set_language_contextmenu)
  events.connect(events.VIEW_AFTER_SWITCH, set_language_contextmenu)
  events.connect(events.BUFFER_NEW, set_language_contextmenu)
end

return M

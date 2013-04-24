-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Contributions from Robert Gieseke.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines the menus used by Textadept.
-- If applicable, load this module last in your *~/.textadept/init.lua*, after
-- `_M.textadept.keys` since it looks up defined key commands to show them in
-- menus.
module('_M.textadept.menu')]]

-- Get a string uniquely identifying a key binding.
-- This is used to match menu items with key bindings to show the key shortcut.
-- @param f A value in the `keys` table.
local function get_id(f)
  local id = ''
  if type(f) == 'function' then
    id = tostring(f)
  elseif type(f) == 'table' then
    for _, v in ipairs(f) do id = id..tostring(v) end
  end
  return id
end

local _L, io, gui, gui_find, buffer, view = _L, io, gui, gui.find, buffer, view
local m_textadept, m_editing = _M.textadept, _M.textadept.editing
local m_bookmarks, Msnippets = m_textadept.bookmarks, m_textadept.snippets
local utils = m_textadept.keys.utils
local SEPARATOR, c = {''}, _SCINTILLA.constants

---
-- Defines the default main menubar.
-- Changing this field does not change the menubar. Use `set_menubar()` instead.
-- @see set_menubar
-- @class table
-- @name menubar
M.menubar = {
  { title = _L['_File'],
    {_L['_New'], buffer.new},
    {_L['_Open'], io.open_file},
    {_L['Open _Recent...'], io.open_recent_file},
    {_L['Re_load'], buffer.reload},
    {_L['_Save'], buffer.save},
    {_L['Save _As'], buffer.save_as},
    SEPARATOR,
    {_L['_Close'], buffer.close},
    {_L['Close All'], io.close_all},
    SEPARATOR,
    {_L['Loa_d Session...'], m_textadept.session.load},
    {_L['Sav_e Session...'], m_textadept.session.save},
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
    {_L['_Match Brace'], m_editing.match_brace},
    {_L['Complete _Word'], {m_editing.autocomplete_word, '%w_'}},
    {_L['_Highlight Word'], m_editing.highlight_word},
    {_L['Toggle _Block Comment'], m_editing.block_comment},
    {_L['T_ranspose Characters'], m_editing.transpose_chars},
    {_L['_Join Lines'], m_editing.join_lines},
    { title = _L['_Select'],
      {_L['Select to _Matching Brace'], {m_editing.match_brace, 'select'}},
      {_L['Select between _XML Tags'], {m_editing.select_enclosed, '>', '<'}},
      {_L['Select in XML _Tag'], {m_editing.select_enclosed, '<', '>'}},
      {_L['Select in _Single Quotes'], {m_editing.select_enclosed, "'", "'"}},
      {_L['Select in _Double Quotes'], {m_editing.select_enclosed, '"', '"'}},
      {_L['Select in _Parentheses'], {m_editing.select_enclosed, '(', ')'}},
      {_L['Select in _Brackets'], {m_editing.select_enclosed, '[', ']'}},
      {_L['Select in B_races'], {m_editing.select_enclosed, '{', '}'}},
      {_L['Select _Word'], m_editing.select_word},
      {_L['Select _Line'], m_editing.select_line},
      {_L['Select Para_graph'], m_editing.select_paragraph},
      {_L['Select _Indented Block'], m_editing.select_indented_block},
    },
    { title = _L['Selectio_n'],
      {_L['_Upper Case Selection'], buffer.upper_case},
      {_L['_Lower Case Selection'], buffer.lower_case},
      SEPARATOR,
      {_L['Enclose as _XML Tags'], utils.enclose_as_xml_tags},
      {_L['Enclose as Single XML _Tag'], {m_editing.enclose, '<', ' />'}},
      {_L['Enclose in Single _Quotes'], {m_editing.enclose, "'", "'"}},
      {_L['Enclose in _Double Quotes'], {m_editing.enclose, '"', '"'}},
      {_L['Enclose in _Parentheses'], {m_editing.enclose, '(', ')'}},
      {_L['Enclose in _Brackets'], {m_editing.enclose, '[', ']'}},
      {_L['Enclose in B_races'], {m_editing.enclose, '{', '}'}},
      SEPARATOR,
      {_L['_Grow Selection'], {m_editing.grow_selection, 1}},
      {_L['_Shrink Selection'], {m_editing.grow_selection, -1}},
      SEPARATOR,
      {_L['_Move Selected Lines Up'], buffer.move_selected_lines_up},
      {_L['Move Selected Lines Do_wn'], buffer.move_selected_lines_down},
    },
  },
  { title = _L['_Search'],
    {_L['_Find'], gui_find.focus},
    {_L['Find _Next'], gui_find.find_next},
    {_L['Find _Previous'], gui_find.find_prev},
    {_L['_Replace'], gui_find.replace},
    {_L['Replace _All'], gui_find.replace_all},
    {_L['Find _Incremental'], gui_find.find_incremental},
    SEPARATOR,
    {_L['Find in Fi_les'], utils.find_in_files},
    {_L['Goto Nex_t File Found'], {gui_find.goto_file_in_list, true}},
    {_L['Goto Previou_s File Found'], {gui_find.goto_file_in_list, false}},
    SEPARATOR,
    {_L['_Jump to'], m_editing.goto_line},
  },
  { title = _L['_Tools'],
    {_L['Command _Entry'], {gui.command_entry.enter_mode, 'lua_command'}},
    {_L['Select Co_mmand'], utils.select_command},
    SEPARATOR,
    {_L['_Run'], m_textadept.run.run},
    {_L['_Compile'], m_textadept.run.compile},
    {_L['_Filter Through'], {gui.command_entry.enter_mode, 'filter_through'}},
    SEPARATOR,
    { title = _L['_Adeptsense'],
      {_L['_Complete Symbol'], m_textadept.adeptsense.complete},
      {_L['Show _Documentation'], m_textadept.adeptsense.show_apidoc},
    },
    { title = _L['_Bookmark'],
      {_L['_Toggle Bookmark'], m_bookmarks.toggle},
      {_L['_Clear Bookmarks'], m_bookmarks.clear},
      {_L['_Next Bookmark'], m_bookmarks.goto_next},
      {_L['_Previous Bookmark'], m_bookmarks.goto_prev},
      {_L['_Goto Bookmark...'], m_bookmarks.goto_bookmark},
    },
    { title = _L['Snap_open'],
      {_L['Snapopen _User Home'], {io.snapopen, _USERHOME}},
      {_L['Snapopen _Textadept Home'], {io.snapopen, _HOME}},
      {_L['Snapopen _Current Directory'], utils.snapopen_filedir},
    },
    { title = _L['_Snippets'],
      {_L['_Insert Snippet...'], Msnippets._select},
      {_L['_Expand Snippet/Next Placeholder'], Msnippets._insert},
      {_L['_Previous Snippet Placeholder'], Msnippets._previous},
      {_L['_Cancel Snippet'], Msnippets._cancel_current},
    },
    SEPARATOR,
    {_L['Show St_yle'], utils.show_style},
  },
  { title = _L['_Buffer'],
    {_L['_Next Buffer'], {view.goto_buffer, view, 1, true}},
    {_L['_Previous Buffer'], {view.goto_buffer, view, -1, true}},
    {_L['_Switch to Buffer...'], gui.switch_buffer},
    SEPARATOR,
    { title = _L['_Indentation'],
      {_L['Tab width: _2'], {utils.set_indentation, 2}},
      {_L['Tab width: _3'], {utils.set_indentation, 3}},
      {_L['Tab width: _4'], {utils.set_indentation, 4}},
      {_L['Tab width: _8'], {utils.set_indentation, 8}},
      SEPARATOR,
      {_L['_Toggle Use Tabs'], {utils.toggle_property, 'use_tabs'}},
      {_L['_Convert Indentation'], m_editing.convert_indentation},
    },
    { title = _L['_EOL Mode'],
      {_L['CRLF'], {utils.set_eol_mode, c.SC_EOL_CRLF}},
      {_L['CR'], {utils.set_eol_mode, c.SC_EOL_CR}},
      {_L['LF'], {utils.set_eol_mode, c.SC_EOL_LF}},
    },
    { title = _L['E_ncoding'],
      {_L['_UTF-8 Encoding'], {utils.set_encoding, 'UTF-8'}},
      {_L['_ASCII Encoding'], {utils.set_encoding, 'ASCII'}},
      {_L['_ISO-8859-1 Encoding'], {utils.set_encoding, 'ISO-8859-1'}},
      {_L['_MacRoman Encoding'], {utils.set_encoding, 'MacRoman'}},
      {_L['UTF-1_6 Encoding'], {utils.set_encoding, 'UTF-16LE'}},
    },
    SEPARATOR,
    {_L['Select _Lexer...'], m_textadept.mime_types.select_lexer},
    {_L['_Refresh Syntax Highlighting'], {buffer.colourise, buffer, 0, -1}},
  },
  { title = _L['_View'],
    {_L['_Next View'], {gui.goto_view, 1, true}},
    {_L['_Previous View'], {gui.goto_view, -1, true}},
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
      {utils.toggle_property, 'virtual_space_options', c.SCVS_USERACCESSIBLE}},
    SEPARATOR,
    {_L['Zoom _In'], buffer.zoom_in},
    {_L['Zoom _Out'], buffer.zoom_out},
    {_L['_Reset Zoom'], utils.reset_zoom},
    SEPARATOR,
    {_L['Select _Theme...'], gui.select_theme},
  },
  { title = _L['_Help'],
    {_L['Show _Manual'],
      {utils.open_webpage, _HOME..'/doc/01_Introduction.html'}},
    {_L['Show _LuaDoc'], {utils.open_webpage, _HOME..'/doc/api/index.html'}},
    SEPARATOR,
    {_L['_About'],
      {gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--text', _RELEASE,
       '--informative-text', 'Copyright © 2007-2013 Mitchell. See LICENSE\n'..
       'http://foicica.com/textadept', '--button1', _L['_OK'], '--no-cancel',
       '--icon-file', _HOME..'/core/images/ta_64x64.png'}},
  },
}

---
-- Defines the default right-click context menu.
-- Changing this field does not change the context menu. Use `set_contextmenu()`
-- instead.
-- @see set_contextmenu
-- @class table
-- @name context_menu
M.context_menu = {
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

local key_shortcuts = {}
local menu_actions, contextmenu_actions = {}, {}

-- Creates a menu suitable for `gui.menu()` from the menu table format.
-- Also assigns key commands.
-- @param menu The menu to create a GTK+ menu from.
-- @param contextmenu Flag indicating whether or not the menu is a context menu.
--   If so, menu_id offset is 1000. The default value is `false`.
-- @return GTK+ menu that can be passed to `gui.menu()`.
-- @see gui.menu
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
      local key, mods = keys.get_gdk_key(key_shortcuts[get_id(f)])
      gtkmenu[#gtkmenu + 1] = {label, menu_id, key, mods}
      if f then
        local actions = not contextmenu and menu_actions or contextmenu_actions
        actions[menu_id < 1000 and menu_id or menu_id - 1000] = f
      end
    end
  end
  return gtkmenu
end

local items, commands

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

---
-- Sets `gui.menubar` from *menubar*, a table of menus.
-- Each menu is an ordered list of menu items and has a `title` key for the
-- title text. Menu items are tables containing menu text and either a function
-- to call or a table containing a function with its parameters to call when an
-- item is clicked. Menu items may also be sub-menus, ordered lists of menu
-- items with an additional `title` key for the sub-menu's title text.
-- @param menubar The table of menu tables to create the menubar from.
-- @see gui.menubar
-- @see gui.menu
-- @name set_menubar
function M.set_menubar(menubar)
  key_shortcuts = {}
  for key, f in pairs(keys) do key_shortcuts[get_id(f)] = key end
  menu_actions = {}
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = gui.menu(read_menu_table(menubar[i]))
  end
  gui.menubar = _menubar
  items, commands = {}, {}
  build_command_tables(M.menubar, nil, items, commands)
end
M.set_menubar(M.menubar)

---
-- Sets `gui.context_menu` from *menu*, an ordered list of menu items.
-- Menu items are tables containing menu text and either a function to call or
-- a table containing a function with its parameters to call when an item is
-- clicked. Menu items may also be sub-menus, ordered lists of menu items with
-- an additional `title` key for the sub-menu's title text.
-- @param menu The menu table to create the context menu from.
-- @see gui.context_menu
-- @see gui.menu
-- @name set_contextmenu
function M.set_contextmenu(menu)
  contextmenu_actions = {}
  gui.context_menu = gui.menu(read_menu_table(menu, true))
end
if not CURSES then M.set_contextmenu(M.context_menu) end

local columns = {_L['Command'], _L['Key Command']}
---
-- Prompts the user to select a menu command to run.
-- @name select_command
function M.select_command()
  local i = gui.filteredlist(_L['Run Command'], columns, items, true,
                             CURSES and {'--width', gui.size[1] - 2} or '')
  if i then keys.run_command(commands[i + 1], type(commands[i + 1])) end
end

local events, events_connect = events, events.connect

events_connect(events.MENU_CLICKED, function(menu_id)
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
    local lang = _G.buffer:get_lexer(true)
    M.set_contextmenu(_M[lang] and _M[lang].context_menu or M.context_menu)
  end
  events_connect(events.LANGUAGE_MODULE_LOADED, set_language_contextmenu)
  events_connect(events.BUFFER_AFTER_SWITCH, set_language_contextmenu)
  events_connect(events.VIEW_AFTER_SWITCH, set_language_contextmenu)
  events_connect(events.BUFFER_NEW, set_lang_contextmenu)
end

return M

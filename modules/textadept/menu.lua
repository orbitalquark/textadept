-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Contributions from Robert Gieseke.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Provides dynamic menus for Textadept.
-- This module should be `require`ed last, after `_M.textadept.keys` since it
-- looks up defined key commands to show them in menus.
module('_M.textadept.menu')]]

-- Get a string uniquely identifying a key command.
-- This is used to match menu items with key commands to show the key shortcut.
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
local SEPARATOR, c = { 'separator' }, _SCINTILLA.constants

---
-- Contains the main menubar.
-- @class table
-- @name menubar
M.menubar = {
  { title = _L['File'],
    { _L['gtk-new'], new_buffer },
    { _L['gtk-open'], io.open_file },
    { _L['Open Recent...'], io.open_recent_file },
    { _L['Reload'], buffer.reload },
    { _L['gtk-save'], buffer.save },
    { _L['gtk-save-as'], buffer.save_as },
    SEPARATOR,
    { _L['gtk-close'], buffer.close },
    { _L['Close All'], io.close_all },
    SEPARATOR,
    { _L['Load Session...'], m_textadept.session.prompt_load },
    { _L['Save Session...'], m_textadept.session.prompt_save },
    SEPARATOR,
    { _L['gtk-quit'], quit },
  },
  { title = _L['Edit'],
    { _L['gtk-undo'], buffer.undo },
    { _L['gtk-redo'], buffer.redo },
    SEPARATOR,
    { _L['gtk-cut'], buffer.cut },
    { _L['gtk-copy'], buffer.copy },
    { _L['gtk-paste'], buffer.paste },
    { _L['Duplicate Line'], buffer.line_duplicate },
    { _L['gtk-delete'], buffer.clear },
    { _L['Delete Word'], utils.delete_word },
    { _L['gtk-select-all'], buffer.select_all },
    SEPARATOR,
    { _L['Match Brace'], m_editing.match_brace },
    { _L['Complete Word'], { m_editing.autocomplete_word, '%w_' } },
    { _L['Highlight Word'], m_editing.highlight_word },
    { _L['Toggle Block Comment'], m_editing.block_comment },
    { _L['Transpose Characters'], m_editing.transpose_chars },
    { _L['Join Lines'], m_editing.join_lines },
    { title = _L['Select'],
      { _L['Select to Matching Brace'], { m_editing.match_brace, 'select' } },
      { _L['Select between XML Tags'],
        { m_editing.select_enclosed, '>', '<' } },
      { _L['Select in XML Tag'], { m_editing.select_enclosed, '<', '>' } },
      { _L['Select in Single Quotes'],
        { m_editing.select_enclosed, "'", "'" } },
      { _L['Select in Double Quotes'],
        { m_editing.select_enclosed, '"', '"' } },
      { _L['Select in Parentheses'], { m_editing.select_enclosed, '(', ')' } },
      { _L['Select in Brackets'], { m_editing.select_enclosed, '[', ']' } },
      { _L['Select in Braces'], { m_editing.select_enclosed, '{', '}' } },
      { _L['Select Word'], m_editing.select_word },
      { _L['Select Line'], m_editing.select_line },
      { _L['Select Paragraph'], m_editing.select_paragraph },
      { _L['Select Indented Block'], m_editing.select_indented_block },
    },
    { title = _L['Selection'],
      { _L['Upper Case Selection'], buffer.upper_case },
      { _L['Lower Case Selection'], buffer.lower_case },
      SEPARATOR,
      { _L['Enclose as XML Tags'], utils.enclose_as_xml_tags },
      { _L['Enclose as Single XML Tag'], { m_editing.enclose, '<', ' />' } },
      { _L['Enclose in Single Quotes'], { m_editing.enclose, "'", "'" } },
      { _L['Enclose in Double Quotes'], { m_editing.enclose, '"', '"' } },
      { _L['Enclose in Parentheses'], { m_editing.enclose, '(', ')' } },
      { _L['Enclose in Brackets'], { m_editing.enclose, '[', ']' } },
      { _L['Enclose in Braces'], { m_editing.enclose, '{', '}' } },
      SEPARATOR,
      { _L['Grow Selection'], { m_editing.grow_selection, 1 } },
      { _L['Shrink Selection'], { m_editing.grow_selection, -1 } },
      SEPARATOR,
      { _L['Move Selected Lines Up'], buffer.move_selected_lines_up },
      { _L['Move Selected Lines Down'], buffer.move_selected_lines_down },
    },
  },
  { title = _L['Search'],
    { _L['gtk-find'], gui_find.focus },
    { _L['Find Next'], gui_find.find_next },
    { _L['Find Previous'], gui_find.find_prev },
    { _L['Replace'], gui_find.replace },
    { _L['Replace All'], gui_find.replace_all },
    { _L['Find Incremental'], gui_find.find_incremental },
    SEPARATOR,
    { _L['Find in Files'], utils.find_in_files },
    { _L['Goto Next File Found'], { gui_find.goto_file_in_list, true } },
    { _L['Goto Previous File Found'], { gui_find.goto_file_in_list, false } },
    SEPARATOR,
    { _L['gtk-jump-to'], m_editing.goto_line },
  },
  { title = _L['Tools'],
    { _L['Command Entry'], gui.command_entry.focus },
    { _L['Select Command'], utils.select_command },
    SEPARATOR,
    { _L['Run'], m_textadept.run.run },
    { _L['Compile'], m_textadept.run.compile },
    { _L['Filter Through'], _M.textadept.filter_through.filter_through },
    SEPARATOR,
    { title = _L['Adeptsense'],
      { _L['Complete Symbol'], m_textadept.adeptsense.complete_symbol },
      { _L['Show Documentation'], m_textadept.adeptsense.show_documentation },
    },
    { title = _L['Bookmark'],
      { _L['Toggle Bookmark'], m_bookmarks.toggle },
      { _L['Clear Bookmarks'], m_bookmarks.clear },
      { _L['Next Bookmark'], m_bookmarks.goto_next },
      { _L['Previous Bookmark'], m_bookmarks.goto_prev },
      { _L['Goto Bookmark...'], m_bookmarks.goto_bookmark },
    },
    { title = _L['Snapopen'],
      { _L['Snapopen User Home'], { m_textadept.snapopen.open, _USERHOME } },
      { _L['Snapopen Textadept Home'], { m_textadept.snapopen.open, _HOME } },
      { _L['Snapopen Current Directory'], utils.snapopen_filedir },
    },
    { title = _L['Snippets'],
      { _L['Insert Snippet...'], Msnippets._select },
      { _L['Expand Snippet/Next Placeholder'], Msnippets._insert },
      { _L['Previous Snippet Placeholder'], Msnippets._previous },
      { _L['Cancel Snippet'], Msnippets._cancel_current },
    },
    SEPARATOR,
    { _L['Show Style'], utils.show_style },
  },
  { title = _L['Buffer'],
    { _L['Next Buffer'], { view.goto_buffer, view, 1, true } },
    { _L['Previous Buffer'], { view.goto_buffer, view, -1, true } },
    { _L['Switch to Buffer...'], gui.switch_buffer },
    SEPARATOR,
    { title = _L['Indentation'],
      { _L['Tab width: 2'], { utils.set_indentation, 2 } },
      { _L['Tab width: 3'], { utils.set_indentation, 3 } },
      { _L['Tab width: 4'], { utils.set_indentation, 4 } },
      { _L['Tab width: 8'], { utils.set_indentation, 8 } },
      SEPARATOR,
      { _L['Toggle Use Tabs'], { utils.toggle_property, 'use_tabs' } },
      { _L['Convert Indentation'], m_editing.convert_indentation },
    },
    { title = _L['EOL Mode'],
      { _L['CRLF'], { utils.set_eol_mode, c.SC_EOL_CRLF } },
      { _L['CR'], { utils.set_eol_mode, c.SC_EOL_CR } },
      { _L['LF'], { utils.set_eol_mode, c.SC_EOL_LF } },
    },
    { title = _L['Encoding'],
      { _L['UTF-8 Encoding'], { utils.set_encoding, 'UTF-8' } },
      { _L['ASCII Encoding'], { utils.set_encoding, 'ASCII' } },
      { _L['ISO-8859-1 Encoding'], { utils.set_encoding, 'ISO-8859-1' } },
      { _L['MacRoman Encoding'], { utils.set_encoding, 'MacRoman' } },
      { _L['UTF-16 Encoding'], { utils.set_encoding, 'UTF-16LE' } },
    },
    SEPARATOR,
    { _L['Select Lexer...'], m_textadept.mime_types.select_lexer },
    { _L['Refresh Syntax Highlighting'],
      { buffer.colourise, buffer, 0, -1 } },
  },
  { title = _L['View'],
    { _L['Next View'], { gui.goto_view, 1, true } },
    { _L['Previous View'], { gui.goto_view, -1, true } },
    SEPARATOR,
    { _L['Split View Horizontal'], { view.split, view } },
    { _L['Split View Vertical'], { view.split, view, true } },
    { _L['Unsplit View'], { view.unsplit, view } },
    { _L['Unsplit All Views'], utils.unsplit_all },
    { _L['Grow View'], { utils.grow, 10 } },
    { _L['Shrink View'], { utils.shrink, 10 } },
    SEPARATOR,
    { _L['Toggle Current Fold'], utils.toggle_current_fold },
    SEPARATOR,
    { _L['Toggle View EOL'], { utils.toggle_property, 'view_eol' } },
    { _L['Toggle Wrap Mode'], { utils.toggle_property, 'wrap_mode' } },
    { _L['Toggle Show Indent Guides'],
      { utils.toggle_property, 'indentation_guides' } },
    { _L['Toggle View Whitespace'], { utils.toggle_property, 'view_ws' } },
    { _L['Toggle Virtual Space'],
      { utils.toggle_property, 'virtual_space_options',
        c.SCVS_USERACCESSIBLE } },
    SEPARATOR,
    { _L['Zoom In'], buffer.zoom_in },
    { _L['Zoom Out'], buffer.zoom_out },
    { _L['Reset Zoom'], utils.reset_zoom },
    SEPARATOR,
    { _L['Select Theme...'], gui.select_theme },
  },
  { title = _L['Help'],
    { _L['Show Manual'],
      { utils.open_webpage, _HOME..'/doc/manual/1_Introduction.html' } },
    { _L['Show LuaDoc'], { utils.open_webpage, _HOME..'/doc/index.html' } },
    SEPARATOR,
    { _L['gtk-about'],
      { gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
        _RELEASE, '--no-cancel' } },
  },
}

---
-- Contains the default right-click context menu.
-- @class table
-- @name context_menu
M.context_menu = {
  { _L['gtk-undo'], buffer.undo },
  { _L['gtk-redo'], buffer.redo },
  SEPARATOR,
  { _L['gtk-cut'], buffer.cut },
  { _L['gtk-copy'], buffer.copy },
  { _L['gtk-paste'], buffer.paste },
  { _L['gtk-delete'], buffer.clear },
  SEPARATOR,
  { _L['gtk-select-all'], buffer.select_all }
}

local key_shortcuts = {}
local menu_actions, contextmenu_actions = {}, {}

-- Creates a menu suitable for `gui.gtkmenu()` from the menu table format.
-- Also assigns key commands.
-- @param menu The menu to create a gtkmenu from.
-- @param contextmenu Flag indicating whether or not the menu is a context menu.
--   If so, menu_id offset is 1000. The default value is `false`.
-- @return gtkmenu that can be passed to `gui.gtkmenu()`.
-- @see gui.gtkmenu
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
      gtkmenu[#gtkmenu + 1] = { label, menu_id, key, mods }
      if f then
        local actions = not contextmenu and menu_actions or contextmenu_actions
        actions[menu_id < 1000 and menu_id or menu_id - 1000] = f
      end
    end
  end
  return gtkmenu
end

---
-- Sets `gui.menubar` from the given table of menus.
-- @param menubar The table of menus to create the menubar from. Each table
--   entry is another table that corresponds to a particular menu. A menu can
--   have a `title` key with string value. Each menu item is either a submenu
--   (another menu table) or a table consisting of two items: string menu text
--   and a function or action table just like in `keys`. The table can
--   optionally contain 2 more number values: a GDK keycode and modifier mask
--   for setting a menu accelerator. If the menu text is `'separator'`, a menu
--   separator is created and no action table is required.
-- @see keys.get_gdk_key
-- @name set_menubar
function M.set_menubar(menubar)
  key_shortcuts = {}
  for key, f in pairs(keys) do key_shortcuts[get_id(f)] = key end
  menu_actions = {}
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = gui.gtkmenu(read_menu_table(menubar[i]))
  end
  gui.menubar = _menubar
end
M.set_menubar(M.menubar)

---
-- Sets `gui.context_menu` from the given menu table.
-- @param menu_table The menu table to create the context menu from. Each table
--   entry is either a submenu or menu text and a function or action table.
-- @see set_menubar
-- @name set_contextmenu
function M.set_contextmenu(menu_table)
  contextmenu_actions = {}
  gui.context_menu = gui.gtkmenu(read_menu_table(menu_table, true))
end
M.set_contextmenu(M.context_menu)

local items, commands

-- Builds the item and commands tables for the filteredlist dialog.
-- @param menu The menu to read from.
-- @param title The title of the menu.
-- @param items The current list of items.
-- @param commands The current list of commands.
local function build_command_tables(menu, title, items, commands)
  for _, menuitem in ipairs(menu) do
    if menuitem.title then
      build_command_tables(menuitem, menuitem.title, items, commands)
    elseif menuitem[1] ~= 'separator' then
      local label, f = menuitem[1], menuitem[2]
      if title then label = title..': '..label end
      items[#items + 1] = label:gsub('_([^_])', '%1'):gsub('^gtk%-', '')
      items[#items + 1] = key_shortcuts[get_id(f)] or ''
      commands[#commands + 1] = f
    end
  end
end

local columns = { _L['Command'], _L['Key Command'] }
---
-- Prompts the user with a filteredlist to run menu commands.
-- @name select_command
function M.select_command()
  local i = gui.filteredlist(_L['Run Command'], columns, items, true)
  if i then keys.run_command(commands[i + 1], type(commands[i + 1])) end
end

---
-- Rebuilds the tables used by `select_command()`.
-- This should be called every time `set_menubar()` is called.
-- @name rebuild_command_tables
function M.rebuild_command_tables()
  items, commands = {}, {}
  build_command_tables(M.menubar, nil, items, commands)
end
M.rebuild_command_tables()

local events, events_connect = events, events.connect

events_connect(events.MENU_CLICKED, function(menu_id)
  local actions = menu_id < 1000 and menu_actions or contextmenu_actions
  local action = actions[menu_id < 1000 and menu_id or menu_id - 1000]
  if type(action) ~= 'function' and type(action) ~= 'table' then
    error(_L['Unknown command:']..' '..tostring(action))
  end
  keys.run_command(action, type(action))
end)

-- Set a language-specific context menu or the default one.
local function set_language_contextmenu()
  local lang = _G.buffer:get_lexer(true)
  M.set_contextmenu(_M[lang] and _M[lang].context_menu or M.context_menu)
end
events_connect(events.LANGUAGE_MODULE_LOADED, set_language_contextmenu)
events_connect(events.BUFFER_AFTER_SWITCH, set_language_contextmenu)
events_connect(events.VIEW_AFTER_SWITCH, set_language_contextmenu)
events_connect(events.BUFFER_NEW, set_lang_contextmenu)

return M

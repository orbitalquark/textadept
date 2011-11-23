-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Contributions from Robert Gieseke.

local L = locale.localize
local gui = gui

---
-- Provides dynamic menus for Textadept.
-- This module should be `require`ed last, after `_m.textadept.keys` since it
-- looks up defined key commands to show them in menus.
module('_m.textadept.menu', package.seeall)

local _buffer, _view = buffer, view
local m_textadept, m_editing = _m.textadept, _m.textadept.editing
local c, SEPARATOR = _SCINTILLA.constants, { 'separator' }
local utils = m_textadept.keys.utils

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

---
-- Contains the main menubar.
-- @class table
-- @name menubar
menubar = {
  { title = L('File'),
    { L('gtk-new'), new_buffer },
    { L('gtk-open'), io.open_file },
    { L('Open Recent...'), io.open_recent_file },
    { L('Reload'), _buffer.reload },
    { L('gtk-save'), _buffer.save },
    { L('gtk-save-as'), _buffer.save_as },
    SEPARATOR,
    { L('gtk-close'), _buffer.close },
    { L('Close All'), io.close_all },
    SEPARATOR,
    { L('Load Session...'), m_textadept.session.prompt_load },
    { L('Save Session...'), m_textadept.session.prompt_save },
    SEPARATOR,
    { L('gtk-quit'), quit },
  },
  { title = L('Edit'),
    { L('gtk-undo'), _buffer.undo },
    { L('gtk-redo'), _buffer.redo },
    SEPARATOR,
    { L('gtk-cut'), _buffer.cut },
    { L('gtk-copy'), _buffer.copy },
    { L('gtk-paste'), _buffer.paste },
    { L('Duplicate Line'), _buffer.line_duplicate },
    { L('gtk-delete'), _buffer.clear },
    { L('gtk-select-all'), _buffer.select_all },
    SEPARATOR,
    { L('Match Brace'), m_editing.match_brace },
    { L('Complete Word'), { m_editing.autocomplete_word, '%w_' } },
    { L('Delete Word'), { m_editing.current_word, 'delete' } },
    { L('Highlight Word'), m_editing.highlight_word },
    { L('Toggle Block Comment'), m_editing.block_comment },
    { L('Transpose Characters'), m_editing.transpose_chars },
    { L('Join Lines'), m_editing.join_lines },
    { title = L('Select'),
      { L('Select to Matching Brace'), { m_editing.match_brace, 'select' } },
      { L('Select between XML Tags'), { m_editing.select_enclosed, '>', '<' } },
      { L('Select in XML Tag'), { m_editing.select_enclosed, '<', '>' } },
      { L('Select in Single Quotes'), { m_editing.select_enclosed, "'", "'" } },
      { L('Select in Double Quotes'), { m_editing.select_enclosed, '"', '"' } },
      { L('Select in Parentheses'), { m_editing.select_enclosed, '(', ')' } },
      { L('Select in Brackets'), { m_editing.select_enclosed, '[', ']' } },
      { L('Select in Braces'), { m_editing.select_enclosed, '{', '}' } },
      { L('Select Word'), { m_editing.current_word, 'select' } },
      { L('Select Line'), m_editing.select_line },
      { L('Select Paragraph'), m_editing.select_paragraph },
      { L('Select Indented Block'), m_editing.select_indented_block },
    },
    { title = L('Selection'),
      { L('Upper Case Selection'), _buffer.upper_case },
      { L('Lower Case Selection'), _buffer.lower_case },
      SEPARATOR,
      { L('Enclose as XML Tags'), utils.enclose_as_xml_tags },
      { L('Enclose as Single XML Tag'), { m_editing.enclose, '<', ' />' } },
      { L('Enclose in Single Quotes'), { m_editing.enclose, "'", "'" } },
      { L('Enclose in Double Quotes'), { m_editing.enclose, '"', '"' } },
      { L('Enclose in Parentheses'), { m_editing.enclose, '(', ')' } },
      { L('Enclose in Brackets'), { m_editing.enclose, '[', ']' } },
      { L('Enclose in Braces'), { m_editing.enclose, '{', '}' } },
      SEPARATOR,
      { L('Grow Selection'), { m_editing.grow_selection, 1 } },
      { L('Shrink Selection'), { m_editing.grow_selection, -1 } },
      SEPARATOR,
      { L('Move Selected Lines Up'), _buffer.move_selected_lines_up },
      { L('Move Selected Lines Down'), _buffer.move_selected_lines_down },
    },
  },
  { title = L('Search'),
    { L('gtk-find'), gui.find.focus },
    { L('Find Next'), gui.find.find_next },
    { L('Find Previous'), gui.find.find_prev },
    { L('Replace'), gui.find.replace },
    { L('Replace All'), gui.find.replace_all },
    { L('Find Incremental'), gui.find.find_incremental },
    SEPARATOR,
    { L('Find in Files'), utils.find_in_files },
    { L('Goto Next File Found'), { gui.find.goto_file_in_list, true } },
    { L('Goto Previous File Found'), { gui.find.goto_file_in_list, false } },
    SEPARATOR,
    { L('gtk-jump-to'), m_editing.goto_line },
  },
  { title = L('Tools'),
    { L('Command Entry'), gui.command_entry.focus },
    { L('Select Command'), utils.select_command },
    SEPARATOR,
    { L('Run'), m_textadept.run.run },
    { L('Compile'), m_textadept.run.compile },
    { L('Filter Through'), _m.textadept.filter_through.filter_through },
    SEPARATOR,
    { title = L('Adeptsense'),
      { L('Complete Symbol'), m_textadept.adeptsense.complete_symbol },
      { L('Show Documentation'), m_textadept.adeptsense.show_documentation },
    },
    { title = L('Bookmark'),
      { L('Toggle Bookmark'), m_textadept.bookmarks.toggle },
      { L('Clear Bookmarks'), m_textadept.bookmarks.clear },
      { L('Next Bookmark'), m_textadept.bookmarks.goto_next },
      { L('Previous Bookmark'), m_textadept.bookmarks.goto_prev },
      { L('Goto Bookmark...'), m_textadept.bookmarks.goto },
    },
    { title = L('Snapopen'),
      { L('Snapopen User Home'), { m_textadept.snapopen.open, _USERHOME } },
      { L('Snapopen Textadept Home'), { m_textadept.snapopen.open, _HOME } },
      { L('Snapopen Current Directory'), utils.snapopen_filedir },
    },
    { title = L('Snippets'),
      { L('Insert Snippet...'), m_textadept.snippets._select },
      { L('Expand Snippet/Next Placeholder'), m_textadept.snippets._insert },
      { L('Previous Snippet Placeholder'), m_textadept.snippets._previous },
      { L('Cancel Snippet'), m_textadept.snippets._cancel_current },
    },
    SEPARATOR,
    { L('Show Style'), utils.show_style },
  },
  { title = L('Buffer'),
    { L('Next Buffer'), { _view.goto_buffer, _view, 1, true } },
    { L('Previous Buffer'), { _view.goto_buffer, _view, -1, true } },
    { L('Switch to Buffer...'), gui.switch_buffer },
    SEPARATOR,
    { title = L('Indentation'),
      { L('Tab width: 2'), { utils.set_indentation, 2 } },
      { L('Tab width: 3'), { utils.set_indentation, 3 } },
      { L('Tab width: 4'), { utils.set_indentation, 4 } },
      { L('Tab width: 8'), { utils.set_indentation, 8 } },
      SEPARATOR,
      { L('Toggle Use Tabs'), { utils.toggle_property, 'use_tabs' } },
      { L('Convert Indentation'), m_editing.convert_indentation },
    },
    { title = L('EOL Mode'),
      { L('CRLF'), { utils.set_eol_mode, c.SC_EOL_CRLF } },
      { L('CR'), { utils.set_eol_mode, c.SC_EOL_CR } },
      { L('LF'), { utils.set_eol_mode, c.SC_EOL_LF } },
    },
    { title = L('Encoding'),
      { L('UTF-8 Encoding'), { utils.set_encoding, 'UTF-8' } },
      { L('ASCII Encoding'), { utils.set_encoding, 'ASCII' } },
      { L('ISO-8859-1 Encoding'), { utils.set_encoding, 'ISO-8859-1' } },
      { L('MacRoman Encoding'), { utils.set_encoding, 'MacRoman' } },
      { L('UTF-16 Encoding'), { utils.set_encoding, 'UTF-16LE' } },
    },
    SEPARATOR,
    { L('Select Lexer...'), m_textadept.mime_types.select_lexer },
    { L('Refresh Syntax Highlighting'), { _buffer.colourise, _buffer, 0, -1 } },
  },
  { title = L('View'),
    { L('Next View'), { gui.goto_view, 1, true } },
    { L('Previous View'), { gui.goto_view, -1, true } },
    SEPARATOR,
    { L('Split View Horizontal'), { _view.split, _view } },
    { L('Split View Vertical'), { _view.split, _view, true } },
    { L('Unsplit View'), { _view.unsplit, _view } },
    { L('Unsplit All Views'), utils.unsplit_all },
    { L('Grow View'), { utils.grow, 10 } },
    { L('Shrink View'), { utils.shrink, 10 } },
    SEPARATOR,
    { L('Toggle Current Fold'), utils.toggle_current_fold },
    SEPARATOR,
    { L('Toggle View EOL'), { utils.toggle_property, 'view_eol' } },
    { L('Toggle Wrap Mode'), { utils.toggle_property, 'wrap_mode' } },
    { L('Toggle Show Indent Guides'),
      { utils.toggle_property, 'indentation_guides' } },
    { L('Toggle View Whitespace'), { utils.toggle_property, 'view_ws' } },
    { L('Toggle Virtual Space'),
      { utils.toggle_property, 'virtual_space_options',
        c.SCVS_USERACCESSIBLE } },
    SEPARATOR,
    { L('Zoom In'), _buffer.zoom_in },
    { L('Zoom Out'), _buffer.zoom_out },
    { L('Reset Zoom'), utils.reset_zoom },
    SEPARATOR,
    { L('Select Theme...'), gui.select_theme },
  },
  { title = L('Help'),
    { L('Show Manual'),
      { utils.open_webpage, _HOME..'/doc/manual/1_Introduction.html' } },
    { L('Show LuaDoc'), { utils.open_webpage, _HOME..'/doc/index.html' } },
    SEPARATOR,
    { L('gtk-about'),
      { gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
        _RELEASE, '--no-cancel' } },
  },
}

---
-- Contains the default right-click context menu.
-- @class table
-- @name context_menu
context_menu = {
  { L('gtk-undo'), _buffer.undo },
  { L('gtk-redo'), _buffer.redo },
  SEPARATOR,
  { L('gtk-cut'), _buffer.cut },
  { L('gtk-copy'), _buffer.copy },
  { L('gtk-paste'), _buffer.paste },
  { L('gtk-delete'), _buffer.clear },
  SEPARATOR,
  { L('gtk-select-all'), _buffer.select_all }
}

local key_shortcuts = {}
local menu_actions = {}
local contextmenu_actions = {}

-- Creates a menu suitable for `gui.gtkmenu()` from the menu table format.
-- Also assigns key commands.
-- @param menu The menu to create a gtkmenu from.
-- @param contextmenu Flag indicating whether or not the menu is a context menu.
--   If so, menu_id offset is 1000. Defaults to `false`.
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
function set_menubar(menubar)
  key_shortcuts = {}
  for key, f in pairs(keys) do key_shortcuts[get_id(f)] = key end
  menu_actions = {}
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = gui.gtkmenu(read_menu_table(menubar[i]))
  end
  gui.menubar = _menubar
end
set_menubar(menubar)

---
-- Sets `gui.context_menu` from the given menu table.
-- @param menu_table The menu table to create the context menu from. Each table
--   entry is either a submenu or menu text and a function or action table.
-- @see set_menubar
function set_contextmenu(menu_table)
  contextmenu_actions = {}
  gui.context_menu = gui.gtkmenu(read_menu_table(menu_table, true))
end
set_contextmenu(context_menu)

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

local columns = { L('Command'), L('Key Command') }
---
-- Prompts the user with a filteredlist to run menu commands.
function select_command()
  local i = gui.filteredlist(L('Run Command'), columns, items, true)
  if i then keys.run_command(commands[i + 1], type(commands[i + 1])) end
end

---
-- Rebuilds the tables used by `select_command()`.
-- This should be called every time `set_menubar()` is called.
function rebuild_command_tables()
  items, commands = {}, {}
  build_command_tables(menubar, nil, items, commands)
end
rebuild_command_tables()

events.connect(events.MENU_CLICKED, function(menu_id)
  local actions = menu_id < 1000 and menu_actions or contextmenu_actions
  local action = actions[menu_id < 1000 and menu_id or menu_id - 1000]
  if type(action) ~= 'function' and type(action) ~= 'table' then
    error(L('Unknown command:')..' '..tostring(action))
  end
  keys.run_command(action, type(action))
end)

-- Set a language-specific context menu or the default one.
local function set_language_contextmenu()
  local lang = buffer:get_lexer()
  set_contextmenu(_m[lang] and _m[lang].context_menu or context_menu)
end
events.connect(events.LANGUAGE_MODULE_LOADED, set_language_contextmenu)
events.connect(events.BUFFER_AFTER_SWITCH, set_language_contextmenu)
events.connect(events.VIEW_AFTER_SWITCH, set_language_contextmenu)
events.connect(events.BUFFER_NEW, set_lang_contextmenu)

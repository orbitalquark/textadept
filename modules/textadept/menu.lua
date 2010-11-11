-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Modified by Robert Gieseke.

local L = _G.locale.localize
local events = _G.events
local gui = _G.gui

---
-- Provides dynamic menus for Textadept.
-- This module, like _m.textadept.keys, should be 'require'ed last.
module('_m.textadept.menu', package.seeall)

local SEPARATOR = 'separator'
local b, v = 'buffer', 'view'
local m_snippets = _m.textadept.snippets
local m_editing = _m.textadept.editing
local m_bookmarks = _m.textadept.bookmarks
local m_snapopen = _m.textadept.snapopen
local m_run = _m.textadept.run

local function set_encoding(encoding)
  buffer:set_encoding(encoding)
  events.emit('update_ui') -- for updating statusbar
end
local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  events.emit('update_ui') -- for updating statusbar
end
local function set_eol_mode(mode)
  buffer.eol_mode = mode
  buffer:convert_eo_ls(mode)
  events.emit('update_ui') -- for updating statusbar
end
local function set_lexer(lexer)
  buffer:set_lexer(lexer)
  buffer:colourise(0, -1)
  events.emit('update_ui') -- for updating statusbar
end
local function open_webpage(url)
  local cmd
  if WIN32 then
    cmd = string.format('start "" "%s"', url)
    local p = io.popen(cmd)
    if not p then error(L('Error loading webpage:')..url) end
  else
    cmd = string.format(OSX and 'open "file://%s"' or 'xdg-open "%s" &', url)
    if os.execute(cmd) ~= 0 then error(L('Error loading webpage:')..url) end
  end
end

---
-- Contains the main menubar.
-- @class table
-- @name menubar
menubar = {
  { title = L('_File'),
    { L('gtk-new'), { new_buffer } },
    { L('gtk-open'), { io.open_file } },
    { L('_Reload'), { 'reload', b } },
    { L('gtk-save'), { 'save', b } },
    { L('gtk-save-as'), { 'save_as', b } },
    { SEPARATOR },
    { L('gtk-close'), { 'close', b } },
    { L('Close A_ll'), { io.close_all } },
    { SEPARATOR },
    { L('Loa_d Session...'), {
      function()
        local session_file = _SESSIONFILE or ''
        local utf8_filename = gui.dialog('fileselect',
                                         '--title', L('Load Session'),
                                         '--with-directory',
                                         session_file:match('.+[/\\]') or '',
                                         '--with-file',
                                         session_file:match('[^/\\]+$') or '',
                                         '--no-newline')
        if #utf8_filename > 0 then
          _m.textadept.session.load(utf8_filename:iconv(_CHARSET, 'UTF-8'))
        end
      end
    } },
    { L('Sa_ve Session...'), {
      function()
        local session_file = _SESSIONFILE or ''
        local utf8_filename = gui.dialog('filesave',
                                         '--title', L('Save Session'),
                                         '--with-directory',
                                         session_file:match('.+[/\\]') or '',
                                         '--with-file',
                                         session_file:match('[^/\\]+$') or '',
                                         '--no-newline')
        if #utf8_filename > 0 then
          _m.textadept.session.save(utf8_filename:iconv(_CHARSET, 'UTF-8'))
        end
      end
    } },
    { SEPARATOR },
    { L('gtk-quit'), { quit } },
  },
  { title = L('_Edit'),
    { L('gtk-undo'), { 'undo', b } },
    { L('gtk-redo'), { 'redo', b } },
    { SEPARATOR },
    { L('gtk-cut'), { 'cut', b } },
    { L('gtk-copy'), { 'copy', b } },
    { L('gtk-paste'), { 'paste', b } },
    { L('gtk-delete'), { 'clear', b } },
    { L('gtk-select-all'), { 'select_all', b } },
    { SEPARATOR },
    { L('Match _Brace'), { m_editing.match_brace } },
    { L('Select t_o Brace'), { m_editing.match_brace, 'select' } },
    { L('Complete _Word'), { m_editing.autocomplete_word, '%w_' } },
    { L('De_lete Word'), { m_editing.current_word, 'delete' } },
    { L('_Highlight Word'), { m_editing.highlight_word } },
    { L('Tran_spose Characters'), { m_editing.transpose_chars } },
    { L('_Join Lines'), { m_editing.join_lines } },
    { L('Convert _Indentation'), { m_editing.convert_indentation } },
    { title = L('S_election'),
      { title = L('_Enclose in...'),
        { L('_HTML Tags'), { m_editing.enclose, 'tag' } },
        { L('HTML Single _Tag'), { m_editing.enclose, 'single_tag' } },
        { L('_Double Quotes'), { m_editing.enclose, 'dbl_quotes' } },
        { L('_Single Quotes'), { m_editing.enclose, 'sng_quotes' } },
        { L('_Parentheses'), { m_editing.enclose, 'parens' } },
        { L('_Brackets'), { m_editing.enclose, 'brackets' } },
        { L('B_races'), { m_editing.enclose, 'braces' } },
        { L('_Character Sequence'), { m_editing.enclose, 'chars' } },
      },
      { L('_Grow'), { m_editing.grow_selection, 1 } },
    },
    { title = L('Select i_n...'),
      { L('_HTML Tag'), { m_editing.select_enclosed, 'tags' } },
      { L('_Double Quote'), { m_editing.select_enclosed, 'dbl_quotes' } },
      { L('_Single Quote'), { m_editing.select_enclosed, 'sng_quotes' } },
      { L('_Parenthesis'), { m_editing.select_enclosed, 'parens' } },
      { L('_Bracket'), { m_editing.select_enclosed, 'brackets' } },
      { L('B_race'), { m_editing.select_enclosed, 'braces' } },
      { L('_Word'), { m_editing.current_word, 'select' } },
      { L('_Line'), { m_editing.select_line } },
      { L('Para_graph'), { m_editing.select_paragraph } },
      { L('_Indented Block'), { m_editing.select_indented_block } },
      { L('S_cope'), { m_editing.select_scope } },
    },
  },
  { title = L('_Tools'),
    { title = L('_Find'),
      { L('gtk-find'), { gui.find.focus } },
      { L('Find _Next'), { gui.find.call_find_next } },
      { L('Find _Previous'), { gui.find.call_find_prev } },
      { L('gtk-find-and-replace'), { gui.find.focus } },
      { L('Replace'), { gui.find.call_replace } },
      { L('Replace _All'), { gui.find.call_replace_all } },
      { L('Find _Incremental'), { gui.find.find_incremental } },
      { SEPARATOR },
      { L('Find in Fi_les'), {
        function()
          gui.find.in_files = true
          gui.find.focus()
        end
      } },
      { L('Goto Next File Found'), { gui.find.goto_file_in_list, true } },
      { L('Goto Previous File Found'), { gui.find.goto_file_in_list, false } },
      { SEPARATOR },
      { L('gtk-jump-to'), { m_editing.goto_line } },
    },
    { L('Command _Entry'), { gui.command_entry.focus } },
    { SEPARATOR },
    { L('_Run'), { m_run.run } },
    { L('_Compile'), { m_run.compile } },
    { SEPARATOR },
    { title = L('_Snippets'),
      { L('_Insert'), { m_snippets._insert } },
      { L('_Previous Placeholder'), { m_snippets._prev } },
      { L('_Cancel'), { m_snippets._cancel_current } },
      { L('_List'), { m_snippets._list } },
      { L('_Show Scope'), { m_snippets._show_style } },
    },
    { title = L('_Bookmark'),
      { L('_Toggle on Current Line'), { m_bookmarks.toggle } },
      { L('_Clear All'), { m_bookmarks.clear } },
      { L('_Next'), { m_bookmarks.goto_next } },
      { L('_Previous'), { m_bookmarks.goto_prev } },
    },
    { title = L('Snap_open'),
      { L('_User Home'), { m_snapopen.open, _USERHOME } },
      { L('_Textadept Home'), { m_snapopen.open, _HOME } },
      { L('_Current Directory'), {
        function()
          if buffer.filename then
            m_snapopen.open(buffer.filename:match('^(.+)[/\\]'))
          end
        end
      } },
    },
  },
  { title = L('_Buffer'),
    { L('_Next Buffer'), { 'goto_buffer', v, 1, false } },
    { L('_Previous Buffer'), { 'goto_buffer', v, -1, false } },
    { L('Swit_ch Buffer'), { gui.switch_buffer } },
    { SEPARATOR, SEPARATOR },
    { L('Toggle View _EOL'), { toggle_setting, 'view_eol' } },
    { L('Toggle _Wrap Mode'), { toggle_setting, 'wrap_mode' } },
    { L('Toggle Show _Indentation Guides'),
      { toggle_setting, 'indentation_guides' } },
    { L('Toggle Use _Tabs'), { toggle_setting, 'use_tabs' } },
    { L('Toggle View White_space'), { toggle_setting, 'view_ws' } },
    { SEPARATOR },
    { title = L('EOL Mode'),
      { L('CRLF'), { set_eol_mode, 0 } },
      { L('CR'), { set_eol_mode, 1 } },
      { L('LF'), { set_eol_mode, 2 } },
    },
    { title = L('Encoding'),
      { L('UTF-8'), { set_encoding, 'UTF-8' } },
      { L('ASCII'), { set_encoding, 'ASCII' } },
      { L('ISO-8859-1'), { set_encoding, 'ISO-8859-1' } },
      { L('MacRoman'), { set_encoding, 'MacRoman' } },
      { L('UTF-16'), { set_encoding, 'UTF-16LE' } },
    },
    { SEPARATOR },
    { L('_Refresh Syntax Highlighting'), { 'colourise', b, 0, -1 } },
  },
  { title = L('_View'),
    { L('_Next View'), { gui.goto_view, 1, false } },
    { L('_Previous View'), { gui.goto_view, -1, false } },
    { SEPARATOR },
    { L('Split _Vertical'), { 'split', v } },
    { L('Split _Horizontal'), { 'split', v, false } },
    { L('_Unsplit'), { function() view:unsplit() end } },
    { L('Unsplit _All'), { function() while view:unsplit() do end end } },
    { SEPARATOR },
    { L('_Grow'), {
      function() if view.size then view.size = view.size + 10 end end
    } },
    { L('_Shrink'), {
      function() if view.size then view.size = view.size - 10 end end
    } },
  },
  -- Lexer menu inserted here
  { title = L('_Help'),
    { L('_Manual'),
      { open_webpage, _HOME..'/doc/manual/1_Introduction.html' } },
    { L('_LuaDoc'), { open_webpage, _HOME..'/doc/index.html' } },
    { SEPARATOR },
    { L('gtk-about'),
      { gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
        _RELEASE, '--no-cancel' }
    },
  },
}
local lexer_menu = { title = L('Le_xers') }
for _, lexer in ipairs(_m.textadept.mime_types.lexers) do
  lexer_menu[#lexer_menu + 1] = { lexer:gsub('_', '__'), { set_lexer, lexer} }
end
table.insert(menubar, #menubar, lexer_menu) -- before 'Help'

---
-- Contains the right-click context menu.
-- @class table
-- @name context_menu
context_menu = {
  { L('gtk-undo'), { 'undo', b } },
  { L('gtk-redo'), { 'redo', b } },
  { SEPARATOR },
  { L('gtk-cut'), { 'cut', b } },
  { L('gtk-copy'), { 'copy', b } },
  { L('gtk-paste'), { 'paste', b } },
  { L('gtk-delete'), { 'clear', b } },
  { SEPARATOR },
  { L('gtk-select-all'), { 'select_all', b } }
}

local menu_actions = {}
local contextmenu_actions = {}

-- Creates a menu suitable for gui.gtkmenu from the menu table format.
-- @param menu The menu to create a gtkmenu from.
-- @return gtkmenu that can be passed to gui.gtkmenu.
local function read_menu_table(menu)
  local gtkmenu = {}
  gtkmenu.title = menu.title
  for _, menuitem in ipairs(menu) do
    if menuitem.title then
      table.insert(gtkmenu, read_menu_table(menuitem))
    else
      local menu_id = #menu_actions + 1
      table.insert(gtkmenu, { menuitem[1], menu_id })
      if menuitem[2] then menu_actions[menu_id] = menuitem[2] end
    end
  end
  return gtkmenu
end

---
-- Sets gui.menubar from the given table of menus.
-- @param menubar The table of menus to create the menubar from. Each table
--   entry is another table that corresponds to a particular menu. A menu can
--   have a 'title' key with string value. Each menu item is either a submenu
--   (another menu table) or a table consisting of two items: string menu text
--   and an action table just like `_G.keys`'s action table. If the menu text is
--   'separator', a menu separator is created and no action table is required.
function set_menubar(menubar)
  menu_actions = {}
  local _menubar = {}
  for _, menu in ipairs(menubar) do
    _menubar[#_menubar + 1] = gui.gtkmenu(read_menu_table(menu))
  end
  gui.menubar = _menubar
end

---
-- Sets gui.context_menu from the given menu table.
-- @param menu_table The menu table to create the context menu from. Each table
--   entry is either a submenu or menu text and an action table.
-- @see set_menubar
function set_contextmenu(menu_table)
  context_actions = {}
  local context_menu = {}
  for menu_id, menuitem in ipairs(menu_table) do
    table.insert(context_menu, { menuitem[1], menu_id + 1000 })
    if menuitem[2] then context_actions[menu_id] = menuitem[2] end
  end
  gui.context_menu = gui.gtkmenu(context_menu)
end

set_menubar(menubar)
set_contextmenu(context_menu)

-- Most of this handling code comes from keys.lua.
events.connect('menu_clicked',
  function(menu_id)
    local active_table
    if menu_id > 1000 then
      active_table = context_actions[menu_id - 1000]
    else
      active_table = menu_actions[menu_id]
    end
    local f, args
    if active_table and #active_table > 0 then
      local func = active_table[1]
      if type(func) == 'function' then
        f, args = func, { unpack(active_table, 2) }
      elseif type(func) == 'string' then
        local object = active_table[2]
        if object == 'buffer' then
          f, args = buffer[func], { buffer, unpack(active_table, 3) }
        elseif object == 'view' then
          f, args = view[func], { view, unpack(active_table, 3) }
        end
      end
      if f and args then
        local ret, retval = pcall(f, unpack(args))
        if not ret then error(retval) end
      else
        error(L('Unknown command:')..' '..tostring(func))
      end
    end
  end)

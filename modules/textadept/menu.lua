-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Contributions from Robert Gieseke.

local L = locale.localize
local events = events
local gui = gui

---
-- Provides dynamic menus for Textadept.
-- It also loads key commands from _USERHOME/keys.conf,
-- _HOME/modules/textadept/keys.conf, _USERHOME/keys.osx.conf, or
-- _HOME/modules/textadept/keys.osx.conf depending on the platform.
-- This module, like _m.textadept.keys, should be 'require'ed last.
module('_m.textadept.menu', package.seeall)

local _buffer, _view = buffer, view
local m_textadept, m_editing = _m.textadept, _m.textadept.editing
local SEPARATOR = { 'separator' }

-- Load menu key commands.
local K = {}
local escapes = {
  ['\\b'] = '\b', ['\\n'] = '\n', ['\\r'] = '\r', ['\\t'] = '\t',
  ['\\\\'] = '\\', ['\\s'] = ' '
}
local conf = 'keys'..(OSX and '.osx' or '')..'.conf'
local f = io.open(_USERHOME..'/'..conf)
if not f then f = io.open(_HOME..'/modules/textadept/'..conf) end
for line in f:lines() do
  if not line:find('^%s*%%') then
    local id, keys = line:match('^(.-)%s*=%s*(.+)$')
    if id and keys then
      K[id] = {}
      for key in keys:gmatch('%S+') do
        K[id][#K[id] + 1] = key:gsub('\\[bnrt\\s]', escapes)
      end
    end
  end
end
f:close()

local function set_encoding(encoding)
  buffer:set_encoding(encoding)
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function toggle_setting(setting, i)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and (i or 1) or 0
  end
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function set_indentation(i)
  buffer.indent, buffer.tab_width = i, i
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function set_eol_mode(mode)
  buffer.eol_mode = mode
  buffer:convert_eo_ls(mode)
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function set_lexer(lexer)
  buffer:set_lexer(lexer)
  buffer:colourise(0, -1)
  events.emit(events.UPDATE_UI) -- for updating statusbar
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
  { title = L('File'),
    { L('gtk-new'), new_buffer, K['gtk-new'] },
    { L('gtk-open'), io.open_file, K['gtk-open'] },
    { L('Open Recent...'), io.open_recent_file, K['Open Recent...'] },
    { L('Reload'), _buffer.reload, K['Reload'] },
    { L('gtk-save'), _buffer.save, K['gtk-save'] },
    { L('gtk-save-as'), _buffer.save_as, K['gtk-save-as'] },
    SEPARATOR,
    { L('gtk-close'), _buffer.close, K['gtk-close'] },
    { L('Close All'), io.close_all, K['Close All'] },
    SEPARATOR,
    { L('Load Session...'), function()
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
    end, K['Load Session...'] },
    { L('Save Session...'), function()
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
    end, K['Save Session...'] },
    SEPARATOR,
    { L('gtk-quit'), quit, K['gtk-quit'] },
  },
  { title = L('Edit'),
    { L('gtk-undo'), _buffer.undo, K['gtk-undo'] },
    { L('gtk-redo'), _buffer.redo, K['gtk-redo'] },
    SEPARATOR,
    { L('gtk-cut'), _buffer.cut, K['gtk-cut'] },
    { L('gtk-copy'), _buffer.copy, K['gtk-copy'] },
    { L('gtk-paste'), _buffer.paste, K['gtk-paste'] },
    { L('Duplicate'), _buffer.line_duplicate, K['Duplicate'] },
    { L('gtk-delete'), _buffer.clear, K['gtk-delete'] },
    { L('gtk-select-all'), _buffer.select_all, K['gtk-select-all'] },
    SEPARATOR,
    { L('Match Brace'), m_editing.match_brace, K['Match Brace'] },
    { L('Select to Brace'), { m_editing.match_brace, 'select' },
      K['Select to Brace'] },
    { L('Complete Word'), { m_editing.autocomplete_word, '%w_' },
      K['Complete Word'] },
    { L('Delete Word'), { m_editing.current_word, 'delete' },
      K['Delete Word'] },
    { L('Highlight Word'), m_editing.highlight_word, K['Highlight Word'] },
    { L('Complete Symbol'), function()
      local m = _m[buffer:get_lexer()]
      if m and m.sense then m.sense:complete() end
    end, K['Complete Symbol'] },
    { L('Show Documentation'), function()
      local m = _m[buffer:get_lexer()]
      if m and m.sense then m.sense:show_apidoc() end
    end, K['Show Documentation'] },
    { L('Toggle Block Comment'), m_editing.block_comment,
      K['Toggle Block Comment'] },
    { L('Transpose Characters'), m_editing.transpose_chars,
      K['Transpose Characters'] },
    { L('Join Lines'), m_editing.join_lines, K['Join Lines'] },
    { L('Convert Indentation'), m_editing.convert_indentation,
      K['Convert Indentation'] },
    { title = L('Selection'),
      { title = L('Enclose in...'),
        { L('HTML Tags'), function()
          m_editing.enclose('<', '>')
          local buffer = buffer
          local pos = buffer.current_pos
          while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
          buffer:insert_text(-1,
                             '</'..buffer:text_range(pos, buffer.current_pos))
        end, K['HTML Tags'] },
        { L('HTML Single Tag'), { m_editing.enclose, '<', ' />' },
          K['HTML Single Tag'] },
        { L('Double Quotes'), { m_editing.enclose, '"', '"' },
          K['Double Quotes'] },
        { L('Single Quotes'), { m_editing.enclose, "'", "'" },
          K['Single Quotes'] },
        { L('Parentheses'), { m_editing.enclose, '(', ')' }, K['Parentheses'] },
        { L('Brackets'), { m_editing.enclose, '[', ']' }, K['Brackets'] },
        { L('Braces'), { m_editing.enclose, '{', '}' }, K['Braces'] },
      },
      { L('Grow Selection'), { m_editing.grow_selection, 1 },
        K['Grow Selection'] },
      { L('Shrink Selection'), { m_editing.grow_selection, -1 },
        K['Shrink Selection'] },
    },
    { title = L('Select in...'),
      { L('Between Tags'), { m_editing.select_enclosed, '>', '<' },
        K['Between Tags'] },
      { L('HTML Tag'), { m_editing.select_enclosed, '<', '>' },
        K['HTML Tag'] },
      { L('Double Quote'), { m_editing.select_enclosed, '"', '"' },
        K['Double Quote'] },
      { L('Single Quote'), { m_editing.select_enclosed, "'", "'" },
        K['Single Quote'] },
      { L('Parenthesis'), { m_editing.select_enclosed, '(', ')' },
        K['Parenthesis'] },
      { L('Bracket'), { m_editing.select_enclosed, '[', ']' }, K['Bracket'] },
      { L('Brace'), { m_editing.select_enclosed, '{', '}' }, K['Brace'] },
      { L('Word'), { m_editing.current_word, 'select' }, K['Word'] },
      { L('Line'), m_editing.select_line, K['Line'] },
      { L('Paragraph'), m_editing.select_paragraph, K['Paragraph'] },
      { L('Indented Block'), m_editing.select_indented_block,
        K['Indented Block'] },
      { L('Style'), m_editing.select_style, K['Style'] },
    },
  },
  { title = L('Search'),
    { L('gtk-find'), gui.find.focus, K['gtk-find'] },
    { L('Find Next'), gui.find.find_next, K['Find Next'] },
    { L('Find Previous'), gui.find.find_prev, K['Find Previous'] },
    { L('Replace'), gui.find.replace, K['Replace'] },
    { L('Replace All'), gui.find.replace_all, K['Replace All'] },
    { L('Find Incremental'), gui.find.find_incremental, K['Find Incremental'] },
    SEPARATOR,
    { L('Find in Files'), function()
      gui.find.in_files = true
      gui.find.focus()
    end, K['Find in Files'] },
    { L('Goto Next File Found'), { gui.find.goto_file_in_list, true },
      K['Goto Next File Found'] },
    { L('Goto Previous File Found'), { gui.find.goto_file_in_list, false },
      K['Goto Previous File Found'] },
    SEPARATOR,
    { L('gtk-jump-to'), m_editing.goto_line, K['gtk-jump-to'] },
  },
  { title = L('Tools'),
    { L('Command Entry'), gui.command_entry.focus, K['Command Entry'] },
    SEPARATOR,
    { L('Run'), m_textadept.run.run, K['Run'] },
    { L('Compile'), m_textadept.run.compile, K['Compile'] },
    { L('Filter Through'), _m.textadept.filter_through.filter_through,
      K['Filter Through'] },
    SEPARATOR,
    { title = L('Snippets'),
      { L('Expand'), m_textadept.snippets._insert, K['Expand'] },
      { L('Insert...'), m_textadept.snippets._select, K['Insert...'] },
      { L('Previous Placeholder'), m_textadept.snippets._previous,
        K['Previous Placeholder'] },
      { L('Cancel'), m_textadept.snippets._cancel_current, K['Cancel'] },
    },
    { title = L('Bookmark'),
      { L('Toggle on Current Line'), m_textadept.bookmarks.toggle,
        K['Toggle on Current Line'] },
      { L('Clear All'), m_textadept.bookmarks.clear, K['Clear All'] },
      { L('Next'), m_textadept.bookmarks.goto_next, K['Next'] },
      { L('Previous'), m_textadept.bookmarks.goto_prev, K['Previous'] },
      { L('Goto Bookmark...'), m_textadept.bookmarks.goto,
        K['Goto Bookmark...'] },
    },
    { title = L('Snapopen'),
      { L('User Home'), { m_textadept.snapopen.open, _USERHOME },
        K['User Home'] },
      { L('Textadept Home'), { m_textadept.snapopen.open, _HOME },
        K['Textadept Home'] },
      { L('Current Directory'), function()
        if buffer.filename then
          m_textadept.snapopen.open(buffer.filename:match('^(.+)[/\\]'))
        end
      end, K['Current Directory'] },
    },
    SEPARATOR,
    { L('Show Style'), function()
      local buffer = buffer
      local style = buffer.style_at[buffer.current_pos]
      local text = string.format("%s %s\n%s %s (%d)", L('Lexer'),
                                 buffer:get_lexer(), L('Style'),
                                 buffer:get_style_name(style), style)
      buffer:call_tip_show(buffer.current_pos, text)
    end , K['Show Style'] },
  },
  { title = L('Buffer'),
    { L('Next Buffer'), { _view.goto_buffer, _view, 1, false },
      K['Next Buffer'] },
    { L('Previous Buffer'), { _view.goto_buffer, _view, -1, false },
      K['Previous Buffer'] },
    { L('Switch Buffer'), gui.switch_buffer, K['Switch Buffer'] },
    SEPARATOR,
    { L('Toggle View EOL'), { toggle_setting, 'view_eol' },
      K['Toggle View EOL'] },
    { L('Toggle Wrap Mode'), { toggle_setting, 'wrap_mode' },
      K['Toggle Wrap Mode'] },
    { L('Toggle Show Indent Guides'),
      { toggle_setting, 'indentation_guides' },
      K['Toggle Show Indent Guides'] },
    { L('Toggle Use Tabs'), { toggle_setting, 'use_tabs' },
      K['Toggle Use Tabs'] },
    { L('Toggle View Whitespace'), { toggle_setting, 'view_ws' },
      K['Toggle View Whitespace'] },
    { L('Toggle Virtual Space'),
      { toggle_setting, 'virtual_space_options', 2 },
      K['Toggle Virtual Space'] },
    SEPARATOR,
    { title = L('Indentation'),
      { '2', { set_indentation, 2 } },
      { '3', { set_indentation, 3 } },
      { '4', { set_indentation, 4 } },
      { '8', { set_indentation, 8 } },
    },
    { title = L('EOL Mode'),
      { L('CRLF'), { set_eol_mode, 0 }, K['CRLF'] },
      { L('CR'), { set_eol_mode, 1 }, K['CR'] },
      { L('LF'), { set_eol_mode, 2 }, K['LF'] },
    },
    { title = L('Encoding'),
      { L('UTF-8'), { set_encoding, 'UTF-8' }, K['UTF-8'] },
      { L('ASCII'), { set_encoding, 'ASCII' }, K['ASCII'] },
      { L('ISO-8859-1'), { set_encoding, 'ISO-8859-1' }, K['ISO-8859-1'] },
      { L('MacRoman'), { set_encoding, 'MacRoman' }, K['MacRoman'] },
      { L('UTF-16'), { set_encoding, 'UTF-16LE' }, K['UTF-16'] },
    },
    SEPARATOR,
    { L('Select Lexer...'), m_textadept.mime_types.select_lexer,
      K['Select Lexer...'] },
    { L('Refresh Syntax Highlighting'),
      { _buffer.colourise, _buffer, 0, -1 }, K['Refresh Syntax Highlighting'] },
  },
  { title = L('View'),
    { L('Next View'), { gui.goto_view, 1, false }, K['Next View'] },
    { L('Previous View'), { gui.goto_view, -1, false }, K['Previous View'] },
    SEPARATOR,
    { L('Split Vertical'), { _view.split, _view }, K['Split Vertical'] },
    { L('Split Horizontal'), { _view.split, _view, false },
      K['Split Horizontal'] },
    { L('Unsplit'), function() view:unsplit() end, K['Unsplit'] },
    { L('Unsplit All'), function() while view:unsplit() do end end,
      K['Unsplit All'] },
    SEPARATOR,
    { L('Grow View'),
      function() if view.size then view.size = view.size + 10 end end,
      K['Grow View'] },
    { L('Shrink View'),
      function() if view.size then view.size = view.size - 10 end end,
      K['Shrink View'] },
    SEPARATOR,
    { L('Zoom In'), _buffer.zoom_in, K['Zoom In'] },
    { L('Zoom Out'), _buffer.zoom_out, K['Zoom Out'] },
    { L('Reset Zoom'), function() buffer.zoom = 0 end, K['Reset Zoom'] },
  },
  -- Lexer menu inserted here
  { title = L('Help'),
    { L('Manual'),
      { open_webpage, _HOME..'/doc/manual/1_Introduction.html' }, K['Manual'] },
    { L('LuaDoc'), { open_webpage, _HOME..'/doc/index.html' }, K['LuaDoc'] },
    SEPARATOR,
    { L('gtk-about'),
      { gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
        _RELEASE, '--no-cancel' }, K['gtk-about'] },
  },
}
local lexer_menu = { title = L('Lexers') }
for _, lexer in ipairs(_m.textadept.mime_types.lexers) do
  lexer_menu[#lexer_menu + 1] = { lexer:gsub('_', '__'), { set_lexer, lexer } }
end
table.insert(menubar, #menubar, lexer_menu) -- before 'Help'

---
-- Contains the right-click context menu.
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

local menu_actions = {}
local contextmenu_actions = {}

-- Creates a menu suitable for gui.gtkmenu from the menu table format.
-- Also assigns key commands.
-- @param menu The menu to create a gtkmenu from.
-- @return gtkmenu that can be passed to gui.gtkmenu.
local function read_menu_table(menu)
  local gtkmenu = {}
  gtkmenu.title = menu.title
  for _, menuitem in ipairs(menu) do
    if menuitem.title then
      gtkmenu[#gtkmenu + 1] = read_menu_table(menuitem)
    else
      local label, f, k = menuitem[1], menuitem[2], menuitem[3]
      local menu_id = #menu_actions + 1
      local key, mods = keys.get_gdk_key(k and k[1])
      gtkmenu[#gtkmenu + 1] = { label, menu_id, key, mods }
      if f then
        menu_actions[menu_id] = f
        if k then for _, key in ipairs(k) do keys[key] = f end end
      end
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
--   and a function or action table just like in `keys`. The table can
--   optionally contain 2 more number values: a GDK keycode and modifier mask
--   for setting a menu accelerator. If the menu text is 'separator', a menu
--   separator is created and no action table is required.
-- @see keys.get_gdk_key
function set_menubar(menubar)
  menu_actions = {}
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = gui.gtkmenu(read_menu_table(menubar[i]))
  end
  gui.menubar = _menubar
end

---
-- Sets gui.context_menu from the given menu table.
-- @param menu_table The menu table to create the context menu from. Each table
--   entry is either a submenu or menu text and a function or action table.
-- @see set_menubar
function set_contextmenu(menu_table)
  context_actions = {}
  local context_menu = {}
  for menu_id, menuitem in ipairs(menu_table) do
    context_menu[#context_menu + 1] = { menuitem[1], menu_id + 1000 }
    if menuitem[2] then context_actions[menu_id] = menuitem[2] end
  end
  gui.context_menu = gui.gtkmenu(context_menu)
end

set_menubar(menubar)
set_contextmenu(context_menu)

-- Most of this handling code comes from keys.lua.
local no_args = {}
events.connect(events.MENU_CLICKED, function(menu_id)
  local action, action_type
  if menu_id > 1000 then
    action = context_actions[menu_id - 1000]
  else
    action = menu_actions[menu_id]
  end
  action_type = type(action)
  if action_type ~= 'function' and action_type ~= 'table' then
    error(L('Unknown command:')..' '..tostring(action))
  end

  local f, args = action_type == 'function' and action or action[1], no_args
  if action_type == 'table' then
    args = action
    -- If the argument is a view or buffer, use the current one instead.
    if type(args[2]) == 'table' then
      local mt, buffer, view = getmetatable(args[2]), buffer, view
      if mt == getmetatable(buffer) then
        args[2] = buffer
      elseif mt == getmetatable(view) then
        args[2] = view
      end
    end
  end
  f(unpack(args, 2))
end)

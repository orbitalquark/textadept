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

-- Creates a menuitem readable by read_menu_table().
-- @param label The label that will be localized.
-- @param f The function or table.
local function menuitem(label, f)
  return { L(label), f, K[L(label):gsub('_([^_])', '%1')] }
end

---
-- Contains the main menubar.
-- @class table
-- @name menubar
menubar = {
  { title = L('File'),
    menuitem('gtk-new', new_buffer),
    menuitem('gtk-open', io.open_file),
    menuitem('Open Recent...', io.open_recent_file),
    menuitem('Reload', _buffer.reload),
    menuitem('gtk-save', _buffer.save),
    menuitem('gtk-save-as', _buffer.save_as),
    SEPARATOR,
    menuitem('gtk-close', _buffer.close),
    menuitem('Close All', io.close_all),
    SEPARATOR,
    menuitem('Load Session...', function()
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
    end),
    menuitem('Save Session...', function()
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
    end),
    SEPARATOR,
    menuitem('gtk-quit', quit),
  },
  { title = L('Edit'),
    menuitem('gtk-undo', _buffer.undo),
    menuitem('gtk-redo', _buffer.redo),
    SEPARATOR,
    menuitem('gtk-cut', _buffer.cut),
    menuitem('gtk-copy', _buffer.copy),
    menuitem('gtk-paste', _buffer.paste),
    menuitem('Duplicate Line', _buffer.line_duplicate),
    menuitem('gtk-delete', _buffer.clear),
    menuitem('gtk-select-all', _buffer.select_all),
    SEPARATOR,
    menuitem('Match Brace', m_editing.match_brace),
    menuitem('Complete Word', { m_editing.autocomplete_word, '%w_' }),
    menuitem('Delete Word', { m_editing.current_word, 'delete' }),
    menuitem('Highlight Word', m_editing.highlight_word),
    menuitem('Toggle Block Comment', m_editing.block_comment),
    menuitem('Transpose Characters', m_editing.transpose_chars),
    menuitem('Join Lines', m_editing.join_lines),
    { title = L('Select'),
      menuitem('Select to Matching Brace', { m_editing.match_brace, 'select' }),
      menuitem('Select between XML Tags',
               { m_editing.select_enclosed, '>', '<' }),
      menuitem('Select in XML Tag', { m_editing.select_enclosed, '<', '>' }),
      menuitem('Select in Double Quotes',
               { m_editing.select_enclosed, '"', '"' }),
      menuitem('Select in Single Quotes',
               { m_editing.select_enclosed, "'", "'" }),
      menuitem('Select in Parentheses',
               { m_editing.select_enclosed, '(', ')' }),
      menuitem('Select in Brackets', { m_editing.select_enclosed, '[', ']' }),
      menuitem('Select in Braces', { m_editing.select_enclosed, '{', '}' }),
      menuitem('Select Word', { m_editing.current_word, 'select' }),
      menuitem('Select Line', m_editing.select_line),
      menuitem('Select Paragraph', m_editing.select_paragraph),
      menuitem('Select Indented Block', m_editing.select_indented_block),
      menuitem('Select Style', m_editing.select_style),
    },
    { title = L('Selection'),
      menuitem('Upper Case Selection', _buffer.upper_case),
      menuitem('Lower Case Selection', _buffer.lower_case),
      SEPARATOR,
      menuitem('Enclose as XML Tags', function()
        m_editing.enclose('<', '>')
        local buffer = buffer
        local pos = buffer.current_pos
        while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
        buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
      end),
      menuitem('Enclose as Single XML Tag', { m_editing.enclose, '<', ' />' }),
      menuitem('Enclose in Single Quotes', { m_editing.enclose, "'", "'" }),
      menuitem('Enclose in Double Quotes', { m_editing.enclose, '"', '"' }),
      menuitem('Enclose in Parentheses', { m_editing.enclose, '(', ')' }),
      menuitem('Enclose in Brackets', { m_editing.enclose, '[', ']' }),
      menuitem('Enclose in Braces', { m_editing.enclose, '{', '}' }),
      SEPARATOR,
      menuitem('Grow Selection', { m_editing.grow_selection, 1 }),
      menuitem('Shrink Selection', { m_editing.grow_selection, -1 }),
      SEPARATOR,
      menuitem('Move Selected Lines Up', _buffer.move_selected_lines_up),
      menuitem('Move Selected Lines Down', _buffer.move_selected_lines_down),
    },
  },
  { title = L('Search'),
    menuitem('gtk-find', gui.find.focus),
    menuitem('Find Next', gui.find.find_next),
    menuitem('Find Previous', gui.find.find_prev),
    menuitem('Replace', gui.find.replace),
    menuitem('Replace All', gui.find.replace_all),
    menuitem('Find Incremental', gui.find.find_incremental),
    SEPARATOR,
    menuitem('Find in Files', function()
      gui.find.in_files = true
      gui.find.focus()
    end),
    menuitem('Goto Next File Found', { gui.find.goto_file_in_list, true }),
    menuitem('Goto Previous File Found', { gui.find.goto_file_in_list, false }),
    SEPARATOR,
    menuitem('gtk-jump-to', m_editing.goto_line),
  },
  { title = L('Tools'),
    menuitem('Command Entry', gui.command_entry.focus),
    menuitem('Select Command', function() _M.select_command() end),
    SEPARATOR,
    menuitem('Run', m_textadept.run.run),
    menuitem('Compile', m_textadept.run.compile),
    menuitem('Filter Through', _m.textadept.filter_through.filter_through),
    SEPARATOR,
    { title = L('Adeptsense'),
      menuitem('Complete Symbol', function()
        local m = _m[buffer:get_lexer()]
        if m and m.sense then m.sense:complete() end
      end),
      menuitem('Show Documentation', function()
        local m = _m[buffer:get_lexer()]
        if m and m.sense then m.sense:show_apidoc() end
      end),
    },
    { title = L('Snippets'),
      menuitem('Insert Snippet...', m_textadept.snippets._select),
      menuitem('Expand Snippet/Next Placeholder', m_textadept.snippets._insert),
      menuitem('Previous Snippet Placeholder', m_textadept.snippets._previous),
      menuitem('Cancel Snippet', m_textadept.snippets._cancel_current),
    },
    { title = L('Bookmark'),
      menuitem('Toggle Bookmark', m_textadept.bookmarks.toggle),
      menuitem('Clear Bookmarks', m_textadept.bookmarks.clear),
      menuitem('Next Bookmark', m_textadept.bookmarks.goto_next),
      menuitem('Previous Bookmark', m_textadept.bookmarks.goto_prev),
      menuitem('Goto Bookmark...', m_textadept.bookmarks.goto),
    },
    { title = L('Snapopen'),
      menuitem('Snapopen User Home', { m_textadept.snapopen.open, _USERHOME }),
      menuitem('Snapopen Textadept Home', { m_textadept.snapopen.open, _HOME }),
      menuitem('Snapopen Current Directory', function()
        if buffer.filename then
          m_textadept.snapopen.open(buffer.filename:match('^(.+)[/\]'))
        end
      end),
    },
    SEPARATOR,
    menuitem('Show Style', function()
      local buffer = buffer
      local style = buffer.style_at[buffer.current_pos]
      local text = string.format("%s %s\n%s %s (%d)", L('Lexer'),
                                 buffer:get_lexer(), L('Style'),
                                 buffer:get_style_name(style), style)
      buffer:call_tip_show(buffer.current_pos, text)
    end),
  },
  { title = L('Buffer'),
    menuitem('Next Buffer', { _view.goto_buffer, _view, 1, false }),
    menuitem('Previous Buffer', { _view.goto_buffer, _view, -1, false }),
    menuitem('Switch Buffer', gui.switch_buffer),
    SEPARATOR,
    menuitem('Toggle View EOL', { toggle_setting, 'view_eol' }),
    menuitem('Toggle Wrap Mode', { toggle_setting, 'wrap_mode' }),
    menuitem('Toggle Show Indent Guides',
             { toggle_setting, 'indentation_guides' }),
    menuitem('Toggle Use Tabs', { toggle_setting, 'use_tabs' }),
    menuitem('Toggle View Whitespace', { toggle_setting, 'view_ws' }),
    menuitem('Toggle Virtual Space',
             { toggle_setting, 'virtual_space_options', 2 }),
    SEPARATOR,
    { title = L('Indentation'),
      menuitem('Tab width: 2', { set_indentation, 2 }),
      menuitem('Tab width: 3', { set_indentation, 3 }),
      menuitem('Tab width: 4', { set_indentation, 4 }),
      menuitem('Tab width: 8', { set_indentation, 8 }),
      SEPARATOR,
      menuitem('Convert Indentation', m_editing.convert_indentation),
    },
    { title = L('EOL Mode'),
      menuitem('CRLF', { set_eol_mode, 0 }),
      menuitem('CR', { set_eol_mode, 1 }),
      menuitem('LF', { set_eol_mode, 2 }),
    },
    { title = L('Encoding'),
      menuitem('UTF-8 Encoding', { set_encoding, 'UTF-8' }),
      menuitem('ASCII Encoding', { set_encoding, 'ASCII' }),
      menuitem('ISO-8859-1 Encoding', { set_encoding, 'ISO-8859-1' }),
      menuitem('MacRoman Encoding', { set_encoding, 'MacRoman' }),
      menuitem('UTF-16 Encoding', { set_encoding, 'UTF-16LE' }),
    },
    SEPARATOR,
    menuitem('Select Lexer...', m_textadept.mime_types.select_lexer),
    menuitem('Refresh Syntax Highlighting',
             { _buffer.colourise, _buffer, 0, -1 }),
  },
  { title = L('View'),
    menuitem('Next View', { gui.goto_view, 1, false }),
    menuitem('Previous View', { gui.goto_view, -1, false }),
    SEPARATOR,
    menuitem('Split View Vertical', { _view.split, _view }),
    menuitem('Split View Horizontal', { _view.split, _view, false }),
    menuitem('Unsplit View', function() view:unsplit() end),
    menuitem('Unsplit All Views', function() while view:unsplit() do end end),
    SEPARATOR,
    menuitem('Grow View',
             function() if view.size then view.size = view.size + 10 end end),
    menuitem('Shrink View',
             function() if view.size then view.size = view.size - 10 end end),
    SEPARATOR,
    menuitem('Zoom In', _buffer.zoom_in),
    menuitem('Zoom Out', _buffer.zoom_out),
    menuitem('Reset Zoom', function() buffer.zoom = 0 end),
  },
  -- Lexer menu inserted here
  { title = L('Help'),
    menuitem('Show Manual',
             { open_webpage, _HOME..'/doc/manual/1_Introduction.html' }),
    menuitem('Show LuaDoc', { open_webpage, _HOME..'/doc/index.html' }),
    SEPARATOR,
    menuitem('gtk-about', { gui.dialog, 'ok-msgbox', '--title', 'Textadept',
                            '--informative-text', _RELEASE, '--no-cancel' }),
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
  keys.run_command(action, action_type)
end)

local items, commands
local columns = { L('Command'), L('Key Command') }

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
      local label, f, key_commands = menuitem[1], menuitem[2], menuitem[3]
      if title then label = title..': '..label end
      items[#items + 1] = label:gsub('_([^_])', '%1'):gsub('^gtk%-', '')
      items[#items + 1] = key_commands and key_commands[1] or ''
      commands[#commands + 1] = f
    end
  end
end

---
-- Prompts the user with a filteredlist to run menu commands.
function select_command()
  local i = gui.filteredlist(L('Run Command'), columns, items, true)
  if i then keys.run_command(commands[i + 1], type(commands[i + 1])) end
end

---
-- Rebuilds the tables used by select_command().
-- This should be called every time set_menubar() is called.
function rebuild_command_tables()
  items, commands = {}, {}
  build_command_tables(menubar, nil, items, commands)
end

rebuild_command_tables()

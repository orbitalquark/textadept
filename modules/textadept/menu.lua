-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Modified by Robert Gieseke.

local L = locale.localize
local events = events
local gui = gui

---
-- Provides dynamic menus for Textadept.
-- This module, like _m.textadept.keys, should be 'require'ed last.
module('_m.textadept.menu', package.seeall)

local _buffer, _view = buffer, view
local m_textadept, m_editing = _m.textadept, _m.textadept.editing
local SEPARATOR = { 'separator' }

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
    { L('gtk-new'), new_buffer },
    { L('gtk-open'), io.open_file },
    { L('Open Recent...'), io.open_recent_file },
    { L('Reload'), { _buffer.reload, _buffer } },
    { L('gtk-save'), { _buffer.save, _buffer } },
    { L('gtk-save-as'), { _buffer.save_as, _buffer } },
    SEPARATOR,
    { L('gtk-close'), { _buffer.close, _buffer } },
    { L('Close All'), io.close_all },
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
    end },
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
    end },
    SEPARATOR,
    { L('gtk-quit'), quit },
  },
  { title = L('Edit'),
    { L('gtk-undo'), { _buffer.undo, _buffer } },
    { L('gtk-redo'), { _buffer.redo, _buffer } },
    SEPARATOR,
    { L('gtk-cut'), { _buffer.cut, _buffer } },
    { L('gtk-copy'), { _buffer.copy, _buffer } },
    { L('gtk-paste'), { _buffer.paste, _buffer } },
    { L('Duplicate'), { _buffer.line_duplicate, _buffer } },
    { L('gtk-delete'), { _buffer.clear, _buffer } },
    { L('gtk-select-all'), { _buffer.select_all, _buffer } },
    SEPARATOR,
    { L('Match Brace'), m_editing.match_brace },
    { L('Select to Brace'), { m_editing.match_brace, 'select' } },
    { L('Complete Word'), { m_editing.autocomplete_word, '%w_' } },
    { L('Delete Word'), { m_editing.current_word, 'delete' } },
    { L('Highlight Word'), m_editing.highlight_word },
    { L('Complete Symbol'), function()
      local m = _m[buffer:get_lexer()]
      if m and m.adeptsense then m.adeptsense.sense:complete() end
    end },
    { L('Show Documentation'), function()
      local m = _m[buffer:get_lexer()]
      if m and m.adeptsense then m.adeptsense.sense:show_apidoc() end
    end },
    { L('Toggle Block Comment'), m_editing.block_comment },
    { L('Transpose Characters'), m_editing.transpose_chars },
    { L('Join Lines'), m_editing.join_lines },
    { L('Convert Indentation'), m_editing.convert_indentation },
    { title = L('Selection'),
      { title = L('Enclose in...'),
        { L('HTML Tags'), function()
          m_editing.enclose('<', '>')
          local buffer = buffer
          local pos = buffer.current_pos
          while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
          buffer:insert_text(-1,
                             '</'..buffer:text_range(pos, buffer.current_pos))
        end },
        { L('HTML Single Tag'), { m_editing.enclose, '<', ' />' } },
        { L('Double Quotes'), { m_editing.enclose, '"', '"' } },
        { L('Single Quotes'), { m_editing.enclose, "'", "'" } },
        { L('Parentheses'), { m_editing.enclose, '(', ')' } },
        { L('Brackets'), { m_editing.enclose, '[', ']' } },
        { L('Braces'), { m_editing.enclose, '{', '}' } },
      },
      { L('Grow'), { m_editing.grow_selection, 1 } },
    },
    { title = L('Select in...'),
      { L('HTML Tag'), { m_editing.select_enclosed, '>', '<' } },
      { L('Double Quote'), { m_editing.select_enclosed, '"', '"' } },
      { L('Single Quote'), { m_editing.select_enclosed, "'", "'" } },
      { L('Parenthesis'), { m_editing.select_enclosed, '(', ')' } },
      { L('Bracket'), { m_editing.select_enclosed, '[', ']' } },
      { L('Brace'), { m_editing.select_enclosed, '{', '}' } },
      { L('Word'), { m_editing.current_word, 'select' } },
      { L('Line'), m_editing.select_line },
      { L('Paragraph'), m_editing.select_paragraph },
      { L('Indented Block'), m_editing.select_indented_block },
      { L('Scope'), m_editing.select_scope },
    },
  },
  { title = L('Search'),
    { L('gtk-find'), gui.find.focus },
    { L('Find Next'), gui.find.call_find_next },
    { L('Find Previous'), gui.find.call_find_prev },
    { L('Replace'), gui.find.call_replace },
    { L('Replace All'), gui.find.call_replace_all },
    { L('Find Incremental'), gui.find.find_incremental },
    SEPARATOR,
    { L('Find in Files'), function()
      gui.find.in_files = true
      gui.find.focus()
    end },
    { L('Goto Next File Found'), { gui.find.goto_file_in_list, true } },
    { L('Goto Previous File Found'), { gui.find.goto_file_in_list, false } },
    SEPARATOR,
    { L('gtk-jump-to'), m_editing.goto_line },
  },
  { title = L('Tools'),
    { L('Command Entry'), gui.command_entry.focus },
    SEPARATOR,
    { L('Run'), m_textadept.run.run },
    { L('Compile'), m_textadept.run.compile },
    { L('Filter Through'), _m.textadept.filter_through.filter_through },
    SEPARATOR,
    { title = L('Snippets'),
      { L('Expand'), m_textadept.snippets._insert },
      { L('Insert...'), m_textadept.snippets._select },
      { L('Previous Placeholder'), m_textadept.snippets._previous },
      { L('Cancel'), m_textadept.snippets._cancel_current },
    },
    { title = L('Bookmark'),
      { L('Toggle on Current Line'), m_textadept.bookmarks.toggle },
      { L('Clear All'), m_textadept.bookmarks.clear },
      { L('Next'), m_textadept.bookmarks.goto_next },
      { L('Previous'), m_textadept.bookmarks.goto_prev },
      { L('Goto Bookmark...'), m_textadept.bookmarks.goto },
    },
    { title = L('Snapopen'),
      { L('User Home'), { m_textadept.snapopen.open, _USERHOME } },
      { L('Textadept Home'), { m_textadept.snapopen.open, _HOME } },
      { L('Current Directory'), function()
        if buffer.filename then
          m_textadept.snapopen.open(buffer.filename:match('^(.+)[/\\]'))
        end
      end },
    },
  },
  { title = L('Buffer'),
    { L('Next Buffer'), { _view.goto_buffer, _view, 1, false } },
    { L('Previous Buffer'), { _view.goto_buffer, _view, -1, false } },
    { L('Switch Buffer'), gui.switch_buffer },
    SEPARATOR,
    { L('Toggle View EOL'), { toggle_setting, 'view_eol' } },
    { L('Toggle Wrap Mode'), { toggle_setting, 'wrap_mode' } },
    { L('Toggle Show Indentation Guides'),
      { toggle_setting, 'indentation_guides' } },
    { L('Toggle Use Tabs'), { toggle_setting, 'use_tabs' } },
    { L('Toggle View Whitespace'), { toggle_setting, 'view_ws' } },
    { L('Toggle Virtual Space'),
      { toggle_setting, 'virtual_space_options', 2} },
    SEPARATOR,
    { title = L('Indentation'),
      { '2', { set_indentation, 2 } },
      { '3', { set_indentation, 3 } },
      { '4', { set_indentation, 4 } },
      { '8', { set_indentation, 8 } },
    },
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
    SEPARATOR,
    { L('Refresh Syntax Highlighting'),
      { _buffer.colourise, _buffer, 0, -1 } },
  },
  { title = L('View'),
    { L('Next View'), { gui.goto_view, 1, false } },
    { L('Previous View'), { gui.goto_view, -1, false } },
    SEPARATOR,
    { L('Split Vertical'), { _view.split, _view } },
    { L('Split Horizontal'), { _view.split, _view, false } },
    { L('Unsplit'), function() view:unsplit() end },
    { L('Unsplit All'), function() while view:unsplit() do end end },
    SEPARATOR,
    { L('Grow'),
      function() if view.size then view.size = view.size + 10 end end
    },
    { L('Shrink'),
      function() if view.size then view.size = view.size - 10 end end
    },
    SEPARATOR,
    { L('Zoom In'), function() buffer.zoom = buffer.zoom + 1 end },
    { L('Zoom Out'), function() buffer.zoom = buffer.zoom - 1 end },
    { L('Reset Zoom'), function() buffer.zoom = 0 end },
  },
  -- Lexer menu inserted here
  { title = L('Help'),
    { L('Manual'),
      { open_webpage, _HOME..'/doc/manual/1_Introduction.html' } },
    { L('LuaDoc'), { open_webpage, _HOME..'/doc/index.html' } },
    SEPARATOR,
    { L('gtk-about'),
      { gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
        _RELEASE, '--no-cancel' }
    },
  },
}
local lexer_menu = { title = L('Lexers') }
for _, lexer in ipairs(_m.textadept.mime_types.lexers) do
  lexer_menu[#lexer_menu + 1] = { lexer:gsub('_', '__'), { set_lexer, lexer} }
end
table.insert(menubar, #menubar, lexer_menu) -- before 'Help'

---
-- Contains the right-click context menu.
-- @class table
-- @name context_menu
context_menu = {
  { L('gtk-undo'), { _buffer.undo, _buffer } },
  { L('gtk-redo'), { _buffer.redo, _buffer } },
  SEPARATOR,
  { L('gtk-cut'), { _buffer.cut, _buffer } },
  { L('gtk-copy'), { _buffer.copy, _buffer } },
  { L('gtk-paste'), { _buffer.paste, _buffer } },
  { L('gtk-delete'), { _buffer.clear, _buffer } },
  SEPARATOR,
  { L('gtk-select-all'), { _buffer.select_all, _buffer } }
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
      gtkmenu[#gtkmenu + 1] = read_menu_table(menuitem)
    else
      local menu_id = #menu_actions + 1
      gtkmenu[#gtkmenu + 1] = { menuitem[1], menu_id }
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
--   and an action table just like `keys`'s action table. If the menu text is
--   'separator', a menu separator is created and no action table is required.
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
--   entry is either a submenu or menu text and an action table.
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

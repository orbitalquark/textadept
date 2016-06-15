-- Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Contributions from Robert Gieseke.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines the menus used by Textadept.
-- Menus are simply tables of menu items and submenus and may be edited in
-- place. A menu item itself is a table whose first element is a menu label and
-- whose second element is a menu command to run. Submenus have `title` keys
-- assigned to string text.
module('textadept.menu')]]

local _L = _L
local SEPARATOR = {''}

-- The following buffer functions need to be constantized in order for menu
-- items to identify the key associated with the functions.
local menu_buffer_functions = {
  'undo', 'redo', 'cut', 'copy', 'paste', 'line_duplicate', 'clear',
  'select_all', 'upper_case', 'lower_case', 'move_selected_lines_up',
  'move_selected_lines_down', 'zoom_in', 'zoom_out', 'colourise'
}
for i = 1, #menu_buffer_functions do
  buffer[menu_buffer_functions[i]] = buffer[menu_buffer_functions[i]]
end

-- Commonly used functions in menu commands.
local sel_enc = textadept.editing.select_enclosed
local enc = textadept.editing.enclose
local function set_indentation(i)
  buffer.tab_width = i
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function set_eol_mode(mode)
  buffer.eol_mode = mode
  buffer:convert_eols(mode)
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function set_encoding(encoding)
  buffer:set_encoding(encoding)
  events.emit(events.UPDATE_UI) -- for updating statusbar
end
local function open_page(url)
  local cmd = (WIN32 and 'start ""') or (OSX and 'open') or 'xdg-open'
  spawn(string.format('%s "%s"', cmd, not OSX and url or 'file://'..url))
end

---
-- The default main menubar.
-- Individual menus, submenus, and menu items can be retrieved by name in
-- addition to table index number.
-- @class table
-- @name menubar
-- @usage textadept.menu.menubar[_L['_File']][_L['_New']]
-- @usage textadept.menu.menubar[_L['_File']][_L['_New']][2] = function() .. end
local default_menubar = {
  {
    title = _L['_File'],
    {_L['_New'], buffer.new},
    {_L['_Open'], io.open_file},
    {_L['Open _Recent...'], io.open_recent_file},
    {_L['Re_load'], io.reload_file},
    {_L['_Save'], io.save_file},
    {_L['Save _As'], io.save_file_as},
    {_L['Save All'], io.save_all_files},
    SEPARATOR,
    {_L['_Close'], io.close_buffer},
    {_L['Close All'], io.close_all_buffers},
    SEPARATOR,
    {_L['Loa_d Session...'], textadept.session.load},
    {_L['Sav_e Session...'], textadept.session.save},
    SEPARATOR,
    {_L['_Quit'], quit}
  },
  {
    title = _L['_Edit'],
    {_L['_Undo'], buffer.undo},
    {_L['_Redo'], buffer.redo},
    SEPARATOR,
    {_L['Cu_t'], buffer.cut},
    {_L['_Copy'], buffer.copy},
    {_L['_Paste'], buffer.paste},
    {_L['Duplicate _Line'], buffer.line_duplicate},
    {_L['_Delete'], buffer.clear},
    {_L['D_elete Word'], function()
      textadept.editing.select_word()
      buffer:delete_back()
    end},
    {_L['Select _All'], buffer.select_all},
    SEPARATOR,
    {_L['_Match Brace'], textadept.editing.match_brace},
    {_L['Complete _Word'], function()
      textadept.editing.autocomplete('word')
    end},
    {_L['_Highlight Word'], textadept.editing.highlight_word},
    {_L['Toggle _Block Comment'], textadept.editing.block_comment},
    {_L['T_ranspose Characters'], textadept.editing.transpose_chars},
    {_L['_Join Lines'], textadept.editing.join_lines},
    {_L['_Filter Through'], function()
      ui.command_entry.enter_mode('filter_through', 'bash')
    end},
    {
      title = _L['_Select'],
      {_L['Select to _Matching Brace'], function()
        textadept.editing.match_brace('select')
      end},
      {_L['Select between _XML Tags'], function() sel_enc('>', '<') end},
      {_L['Select in XML _Tag'], function() sel_enc('<', '>') end},
      {_L['Select in _Single Quotes'], function() sel_enc("'", "'") end},
      {_L['Select in _Double Quotes'], function() sel_enc('"', '"') end},
      {_L['Select in _Parentheses'], function() sel_enc('(', ')') end},
      {_L['Select in _Brackets'], function() sel_enc('[', ']') end},
      {_L['Select in B_races'], function() sel_enc('{', '}') end},
      {_L['Select _Word'], textadept.editing.select_word},
      {_L['Select _Line'], textadept.editing.select_line},
      {_L['Select Para_graph'], textadept.editing.select_paragraph}
    },
    {
      title = _L['Selectio_n'],
      {_L['_Upper Case Selection'], buffer.upper_case},
      {_L['_Lower Case Selection'], buffer.lower_case},
      SEPARATOR,
      {_L['Enclose as _XML Tags'], function()
        enc('<', '>')
        local pos = buffer.current_pos
        while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
        buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
      end},
      {_L['Enclose as Single XML _Tag'], function() enc('<', ' />') end},
      {_L['Enclose in Single _Quotes'], function() enc("'", "'") end},
      {_L['Enclose in _Double Quotes'], function() enc('"', '"') end},
      {_L['Enclose in _Parentheses'], function() enc('(', ')') end},
      {_L['Enclose in _Brackets'], function() enc('[', ']') end},
      {_L['Enclose in B_races'], function() enc('{', '}') end},
      SEPARATOR,
      {_L['_Move Selected Lines Up'], buffer.move_selected_lines_up},
      {_L['Move Selected Lines Do_wn'], buffer.move_selected_lines_down}
    }
  },
  {
    title = _L['_Search'],
    {_L['_Find'], function()
      ui.find.in_files = false
      ui.find.focus()
    end},
    {_L['Find _Next'], ui.find.find_next},
    {_L['Find _Previous'], ui.find.find_prev},
    {_L['_Replace'], ui.find.replace},
    {_L['Replace _All'], ui.find.replace_all},
    {_L['Find _Incremental'], ui.find.find_incremental},
    SEPARATOR,
    {_L['Find in Fi_les'], function()
      ui.find.in_files = true
      ui.find.focus()
    end},
    {_L['Goto Nex_t File Found'], function()
      ui.find.goto_file_found(false, true)
    end},
    {_L['Goto Previou_s File Found'], function()
      ui.find.goto_file_found(false, false)
    end},
    SEPARATOR,
    {_L['_Jump to'], textadept.editing.goto_line}
  },
  {
    title = _L['_Tools'],
    {_L['Command _Entry'], function()
      ui.command_entry.enter_mode('lua_command', 'lua')
    end},
    {_L['Select Co_mmand'], function() M.select_command() end},
    SEPARATOR,
    {_L['_Run'], textadept.run.run},
    {_L['_Compile'], textadept.run.compile},
    {_L['Set _Arguments...'], function()
      if not buffer.filename then return end
      local run_commands = textadept.run.run_commands
      local compile_commands = textadept.run.compile_commands
      local base_commands, utf8_args = {}, {}
      for i, commands in ipairs{run_commands, compile_commands} do
        -- Compare the base run/compile command with the one for the current
        -- file. The difference is any additional arguments set previously.
        base_commands[i] = commands[buffer.filename:match('[^.]+$')] or
                           commands[buffer:get_lexer()] or ''
        local current_command = (commands[buffer.filename] or '')
        local args = current_command:sub(#base_commands[i] + 2)
        utf8_args[i] = args:iconv('UTF-8', _CHARSET)
      end
      local button, utf8_args = ui.dialogs.inputbox{
        title = _L['Set _Arguments...']:gsub('_', ''), informative_text = {
          _L['Command line arguments'], _L['For Run:'], _L['For Compile:']
        }, text = utf8_args, width = not CURSES and 400 or nil
      }
      if button ~= 1 then return end
      for i, commands in ipairs{run_commands, compile_commands} do
        -- Add the additional arguments to the base run/compile command and set
        -- the new command to be the one used for the current file.
        commands[buffer.filename] = base_commands[i]..' '..
                                    utf8_args[i]:iconv(_CHARSET, 'UTF-8')
      end
    end},
    {_L['Buil_d'], textadept.run.build},
    {_L['S_top'], textadept.run.stop},
    {_L['_Next Error'], function() textadept.run.goto_error(false, true) end},
    {_L['_Previous Error'], function()
      textadept.run.goto_error(false, false)
    end},
    SEPARATOR,
    {
      title = _L['_Bookmark'],
      {_L['_Toggle Bookmark'], textadept.bookmarks.toggle},
      {_L['_Clear Bookmarks'], textadept.bookmarks.clear},
      {_L['_Next Bookmark'], function()
        textadept.bookmarks.goto_mark(true)
      end},
      {_L['_Previous Bookmark'], function()
        textadept.bookmarks.goto_mark(false)
      end},
      {_L['_Goto Bookmark...'], textadept.bookmarks.goto_mark},
    },
    {
      title = _L['Quick _Open'],
      {_L['Quickly Open _User Home'], function() io.quick_open(_USERHOME) end},
      {_L['Quickly Open _Textadept Home'], function() io.quick_open(_HOME) end},
      {_L['Quickly Open _Current Directory'], function()
        if buffer.filename then
          io.quick_open(buffer.filename:match('^(.+)[/\\]'))
        end
      end},
      {_L['Quickly Open Current _Project'], io.quick_open},
    },
    {
      title = _L['_Snippets'],
      {_L['_Insert Snippet...'], textadept.snippets._select},
      {_L['_Expand Snippet/Next Placeholder'], textadept.snippets._insert},
      {_L['_Previous Snippet Placeholder'], textadept.snippets._previous},
      {_L['_Cancel Snippet'], textadept.snippets._cancel_current},
    },
    SEPARATOR,
    {_L['_Complete Symbol'], function()
      textadept.editing.autocomplete(buffer:get_lexer(true))
    end},
    {_L['Show _Documentation'], textadept.editing.show_documentation},
    {_L['Show St_yle'], function()
      local char = buffer:text_range(buffer.current_pos,
                                     buffer:position_after(buffer.current_pos))
      if char == '' then return end -- end of buffer
      local bytes = string.rep(' 0x%X', #char):format(char:byte(1, #char))
      local style = buffer.style_at[buffer.current_pos]
      local text = string.format("'%s' (U+%04X:%s)\n%s %s\n%s %s (%d)", char,
                                 utf8.codepoint(char), bytes, _L['Lexer'],
                                 buffer:get_lexer(true), _L['Style'],
                                 buffer.style_name[style], style)
      buffer:call_tip_show(buffer.current_pos, text)
    end}
  },
  {
    title = _L['_Buffer'],
    {_L['_Next Buffer'], function() view:goto_buffer(1, true) end},
    {_L['_Previous Buffer'], function() view:goto_buffer(-1, true) end},
    {_L['_Switch to Buffer...'], ui.switch_buffer},
    SEPARATOR,
    {
      title = _L['_Indentation'],
      {_L['Tab width: _2'], function() set_indentation(2) end},
      {_L['Tab width: _3'], function() set_indentation(3) end},
      {_L['Tab width: _4'], function() set_indentation(4) end},
      {_L['Tab width: _8'], function() set_indentation(8) end},
      SEPARATOR,
      {_L['_Toggle Use Tabs'], function()
        buffer.use_tabs = not buffer.use_tabs
        events.emit(events.UPDATE_UI) -- for updating statusbar
      end},
      {_L['_Convert Indentation'], textadept.editing.convert_indentation}
    },
    {
      title = _L['_EOL Mode'],
      {_L['CRLF'], function() set_eol_mode(buffer.EOL_CRLF) end},
      {_L['LF'], function() set_eol_mode(buffer.EOL_LF) end}
    },
    {
      title = _L['E_ncoding'],
      {_L['_UTF-8 Encoding'], function() set_encoding('UTF-8') end},
      {_L['_ASCII Encoding'], function() set_encoding('ASCII') end},
      {_L['_ISO-8859-1 Encoding'], function() set_encoding('ISO-8859-1') end},
      {_L['_MacRoman Encoding'], function() set_encoding('MacRoman') end},
      {_L['UTF-1_6 Encoding'], function() set_encoding('UTF-16LE') end}
    },
    SEPARATOR,
    {_L['Toggle View _EOL'], function()
      buffer.view_eol = not buffer.view_eol
    end},
    {_L['Toggle _Wrap Mode'], function()
      buffer.wrap_mode = buffer.wrap_mode == 0 and buffer.WRAP_WHITESPACE or 0
    end},
    {_L['Toggle View White_space'], function()
      buffer.view_ws = buffer.view_ws == 0 and buffer.WS_VISIBLEALWAYS or 0
    end},
    SEPARATOR,
    {_L['Select _Lexer...'], textadept.file_types.select_lexer},
    {_L['_Refresh Syntax Highlighting'], function() buffer:colourise(0, -1) end}
  },
  {
    title = _L['_View'],
    {_L['_Next View'], function() ui.goto_view(1, true) end},
    {_L['_Previous View'], function() ui.goto_view(-1, true) end},
    SEPARATOR,
    {_L['Split View _Horizontal'], function() view:split() end},
    {_L['Split View _Vertical'], function() view:split(true) end},
    {_L['_Unsplit View'], function() view:unsplit() end},
    {_L['Unsplit _All Views'], function() while view:unsplit() do end end},
    {_L['_Grow View'], function()
      if view.size then view.size = view.size + buffer:text_height(0) end
    end},
    {_L['Shrin_k View'], function()
      if view.size then view.size = view.size - buffer:text_height(0) end
    end},
    SEPARATOR,
    {_L['Toggle Current _Fold'], function()
      buffer:toggle_fold(buffer:line_from_position(buffer.current_pos))
    end},
    SEPARATOR,
    {_L['Toggle Show In_dent Guides'], function()
      local off = buffer.indentation_guides == 0
      buffer.indentation_guides = off and buffer.IV_LOOKBOTH or 0
    end},
    {_L['Toggle _Virtual Space'], function()
      local off = buffer.virtual_space_options == 0
      buffer.virtual_space_options = off and buffer.VS_USERACCESSIBLE or 0
    end},
    SEPARATOR,
    {_L['Zoom _In'], buffer.zoom_in},
    {_L['Zoom _Out'], buffer.zoom_out},
    {_L['_Reset Zoom'], function() buffer.zoom = 0 end}
  },
  {
    title = _L['_Help'],
    {_L['Show _Manual'], function() open_page(_HOME..'/doc/manual.html') end},
    {_L['Show _LuaDoc'], function() open_page(_HOME..'/doc/api.html') end},
    SEPARATOR,
    {_L['_About'], function()
      ui.dialogs.msgbox({
        title = 'Textadept', text = _RELEASE, informative_text = _COPYRIGHT,
        icon_file = _HOME..'/core/images/ta_64x64.png'
      })
    end}
  }
}

---
-- The default right-click context menu.
-- Submenus, and menu items can be retrieved by name in addition to table index
-- number.
-- @class table
-- @name context_menu
-- @usage textadept.menu.context_menu[#textadept.menu.context_menu + 1] = {...}
local default_context_menu = {
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

---
-- The default tabbar context menu.
-- Submenus, and menu items can be retrieved by name in addition to table index
-- number.
-- @class table
-- @name tab_context_menu
local default_tab_context_menu = {
  {_L['_Close'], io.close_buffer},
  SEPARATOR,
  {_L['_Save'], io.save_file},
  {_L['Save _As'], io.save_file_as},
  SEPARATOR,
  {_L['Re_load'], io.reload_file},
}

-- Table of proxy tables for menus.
local proxies = {}

local key_shortcuts, menu_actions, contextmenu_actions

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
                    (mods:find('m') and 0x10000000 or 0)
  local code = string.byte(key)
  if #key > 1 or code < 32 then
    for i, s in pairs(keys.KEYSYMS) do
      if s == key and i > 0xFE20 then code = i break end
    end
  end
  return code, modifiers
end

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
  for i = 1, #menu do
    if menu[i].title then
      gtkmenu[#gtkmenu + 1] = read_menu_table(menu[i], contextmenu)
    else
      local label, f = menu[i][1], menu[i][2]
      local menu_id = not contextmenu and #menu_actions + 1 or
                      #contextmenu_actions + 1000 + 1
      local key, mods = get_gdk_key(key_shortcuts[tostring(f)])
      gtkmenu[#gtkmenu + 1] = {label, menu_id, key, mods}
      if f then
        local actions = not contextmenu and menu_actions or contextmenu_actions
        actions[menu_id < 1000 and menu_id or menu_id - 1000] = f
      end
    end
  end
  return gtkmenu
end

-- Returns a proxy table for menu table *menu* such that when a menu item is
-- changed or added, *update* is called to update the menu in the UI.
-- @param menu The menu or table of menus to create a proxy for.
-- @param update The function to call to update the menu in the UI when a menu
--   item is changed or added.
-- @param menubar Used internally to keep track of the top-level menu for
--   calling *update* with.
local function proxy_menu(menu, update, menubar)
  return setmetatable({}, {
    __index = function(_, k)
      local v
      if type(k) == 'number' or k == 'title' then
        v = menu[k]
      elseif type(k) == 'string' then
        for i = 1, #menu do
          if menu[i].title == k or menu[i][1] == k then v = menu[i] break end
        end
      end
      return type(v) == 'table' and proxy_menu(v, update, menubar or menu) or v
    end,
    __newindex = function(_, k, v)
      menu[k] = getmetatable(v) and getmetatable(v).menu or v
      update(menubar or menu)
    end,
    __len = function() return #menu end,
    menu = menu -- store existing menu for copying (e.g. m[#m + 1] = m[#m])
  })
end

-- Sets `ui.menubar` from menu table *menubar*.
-- Each menu is an ordered list of menu items and has a `title` key for the
-- title text. Menu items are tables containing menu text and either a function
-- to call or a table containing a function with its parameters to call when an
-- item is clicked. Menu items may also be sub-menus, ordered lists of menu
-- items with an additional `title` key for the sub-menu's title text.
-- @param menubar The table of menu tables to create the menubar from. If `nil`,
--   clears the menubar from view, but keeps it intact in order for
--   `M.select_command()` to function properly.
-- @see ui.menubar
-- @see ui.menu
local function set_menubar(menubar)
  if not menubar then ui.menubar = {} return end
  key_shortcuts, menu_actions = {}, {} -- reset
  for key, f in pairs(keys) do key_shortcuts[tostring(f)] = key end
  local _menubar = {}
  for i = 1, #menubar do
    _menubar[#_menubar + 1] = ui.menu(read_menu_table(menubar[i]))
  end
  ui.menubar = _menubar
  proxies.menubar = proxy_menu(menubar, set_menubar)
end
proxies.menubar = proxy_menu(default_menubar, function() end) -- for keys.lua
events.connect(events.INITIALIZED, function() set_menubar(default_menubar) end)

-- Sets `ui.context_menu` and `ui.tab_context_menu` from menu item lists
-- *buffer_menu* and *tab_menu*, respectively.
-- Menu items are tables containing menu text and either a function to call or
-- a table containing a function with its parameters to call when an item is
-- clicked. Menu items may also be sub-menus, ordered lists of menu items with
-- an additional `title` key for the sub-menu's title text.
-- @param buffer_menu Optional menu table to create the buffer context menu
--   from. If `nil`, uses the default context menu.
-- @param tab_menu Optional menu table to create the tabbar context menu from.
--   If `nil`, uses the default tab context menu.
-- @see ui.context_menu
-- @see ui.tab_context_menu
-- @see ui.menu
local function set_contextmenus(buffer_menu, tab_menu)
  contextmenu_actions = {} -- reset
  local menu = buffer_menu or default_context_menu
  ui.context_menu = ui.menu(read_menu_table(menu, true))
  proxies.context_menu = proxy_menu(menu, set_contextmenus)
  menu = tab_menu or default_tab_context_menu
  ui.tab_context_menu = ui.menu(read_menu_table(menu, true))
  proxies.tab_context_menu = proxy_menu(menu, function()
    set_contextmenus(nil, menu)
  end)
end
events.connect(events.INITIALIZED, set_contextmenus)

-- Performs the appropriate action when clicking a menu item.
events.connect(events.MENU_CLICKED, function(menu_id)
  local actions = menu_id < 1000 and menu_actions or contextmenu_actions
  local action = actions[menu_id < 1000 and menu_id or menu_id - 1000]
  assert(type(action) == 'function',
         _L['Unknown command:']..' '..tostring(action))
  action()
end)

---
-- Prompts the user to select a menu command to run.
-- @name select_command
function M.select_command()
  local items, commands = {}, {}
  -- Builds the item and commands tables for the filtered list dialog.
  -- @param menu The menu to read from.
  local function build_command_tables(menu)
    for i = 1, #menu do
      if menu[i].title then
        build_command_tables(menu[i])
      elseif menu[i][1] ~= '' then
        local label = menu.title and menu.title..': '..menu[i][1] or menu[i][1]
        items[#items + 1] = label:gsub('_([^_])', '%1')
        items[#items + 1] = key_shortcuts[tostring(menu[i][2])] or ''
        commands[#commands + 1] = menu[i][2]
      end
    end
  end
  build_command_tables(getmetatable(M.menubar).menu)
  local button, i = ui.dialogs.filteredlist{
    title = _L['Run Command'], columns = {_L['Command'], _L['Key Command']},
    items = items, width = CURSES and ui.size[1] - 2 or nil
  }
  if button ~= 1 or not i then return end
  assert(type(commands[i]) == 'function',
         _L['Unknown command:']..' '..tostring(commands[i]))
  commands[i]()
end

return setmetatable(M, {
  __index = function(_, k) return proxies[k] or rawget(M, k) end,
  __newindex = function(_, k, v)
    if k == 'menubar' then
      set_menubar(v)
    elseif k == 'context_menu' then
      set_contextmenus(v)
    elseif k == 'tab_context_menu' then
      set_contextmenus(nil, v)
    else
      rawset(M, k, v)
    end
  end
})

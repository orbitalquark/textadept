-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local events = _G.events

---
-- Provides dynamic menus for Textadept.
-- This module, like _m.textadept.keys, should be 'require'ed last.
module('_m.textadept.menu', package.seeall)

local gui = gui
local l = locale
local gtkmenu = gui.gtkmenu

local SEPARATOR = 'separator'
local ID = {
  SEPARATOR = 0,
  -- File
  NEW = 101,
  OPEN = 102,
  RELOAD = 103,
  SAVE = 104,
  SAVEAS = 105,
  CLOSE = 106,
  CLOSE_ALL = 107,
  LOAD_SESSION = 108,
  SAVE_SESSION = 109,
  QUIT = 110,
  -- Edit
  UNDO = 201,
  REDO = 202,
  CUT = 203,
  COPY = 204,
  PASTE = 205,
  DELETE = 206,
  SELECT_ALL = 207,
  MATCH_BRACE = 208,
  SELECT_TO_BRACE = 209,
  COMPLETE_WORD = 210,
  DELETE_WORD = 211,
  HIGHLIGHT_WORD = 213,
  TRANSPOSE_CHARACTERS = 212,
  JOIN_LINES = 245,
  CONVERT_INDENTATION = 216,
  ENCLOSE_IN_HTML_TAGS = 224,
  ENCLOSE_IN_HTML_SINGLE_TAG = 225,
  ENCLOSE_IN_DOUBLE_QUOTES = 226,
  ENCLOSE_IN_SINGLE_QUOTES = 227,
  ENCLOSE_IN_PARENTHESES = 228,
  ENCLOSE_IN_BRACKETS = 229,
  ENCLOSE_IN_BRACES = 230,
  ENCLOSE_IN_CHARACTER_SEQUENCE = 231,
  GROW_SELECTION = 232,
  SELECT_IN_HTML_TAG = 234,
  SELECT_IN_DOUBLE_QUOTE = 235,
  SELECT_IN_SINGLE_QUOTE = 236,
  SELECT_IN_PARENTHESIS = 237,
  SELECT_IN_BRACKET = 238,
  SELECT_IN_BRACE = 239,
  SELECT_IN_WORD = 240,
  SELECT_IN_LINE = 241,
  SELECT_IN_PARAGRAPH = 242,
  SELECT_IN_INDENTED_BLOCK = 243,
  SELECT_IN_SCOPE = 244,
  -- Tools
  FIND = 301,
  FIND_NEXT = 302,
  FIND_PREV = 303,
  FIND_AND_REPLACE = 304,
  REPLACE = 305,
  REPLACE_ALL = 306,
  FIND_IN_FILES = 308,
  FIND_INCREMENTAL = 311,
  GOTO_NEXT_FILE_FOUND = 309,
  GOTO_PREV_FILE_FOUND = 310,
  GOTO_LINE = 307,
  FOCUS_COMMAND_ENTRY = 401,
  RUN = 420,
  COMPILE = 421,
  INSERT_SNIPPET = 402,
  PREVIOUS_SNIPPET_PLACEHOLDER = 403,
  CANCEL_SNIPPET = 404,
  LIST_SNIPPETS = 405,
  SHOW_SCOPE = 406,
  ADD_MULTIPLE_LINE = 407,
  ADD_MULTIPLE_LINES = 408,
  REMOVE_MULTIPLE_LINE = 409,
  REMOVE_MULTIPLE_LINES = 410,
  UPDATE_MULTIPLE_LINES = 411,
  FINISH_MULTIPLE_LINES = 412,
  TOGGLE_BOOKMARK = 416,
  CLEAR_BOOKMARKS = 417,
  GOTO_NEXT_BOOKMARK = 418,
  GOTO_PREV_BOOKMARK = 419,
  SNAPOPEN_USERHOME = 422,
  SNAPOPEN_HOME = 423,
  SNAPOPEN_CURRENTDIR = 424,
  -- Buffer
  NEXT_BUFFER = 501,
  PREV_BUFFER = 502,
  TOGGLE_VIEW_EOL = 503,
  TOGGLE_WRAP_MODE = 504,
  TOGGLE_SHOW_INDENT_GUIDES = 505,
  TOGGLE_USE_TABS = 506,
  TOGGLE_VIEW_WHITESPACE = 507,
  EOL_MODE_CRLF = 509,
  EOL_MODE_CR = 510,
  EOL_MODE_LF = 511,
  ENCODING_UTF8 = 512,
  ENCODING_ASCII = 513,
  ENCODING_ISO88591 = 514,
  ENCODING_MACROMAN = 515,
  ENCODING_UTF16 = 516,
  REFRESH_SYNTAX_HIGHLIGHTING = 508,
  SWITCH_BUFFER = 517,
  -- View
  NEXT_VIEW = 601,
  PREV_VIEW = 602,
  SPLIT_VIEW_VERTICAL = 603,
  SPLIT_VIEW_HORIZONTAL = 604,
  UNSPLIT_VIEW = 605,
  UNSPLIT_ALL_VIEWS = 606,
  GROW_VIEW = 607,
  SHRINK_VIEW = 608,
  -- Lexers (will be generated dynamically)
  LEXER_START = 801,
  -- Help
  MANUAL = 901,
  LUADOC = 902,
  ABOUT = 903,
}


local menubar = {
  gtkmenu {
    title = L('_File'),
    { L('gtk-new'), ID.NEW },
    { L('gtk-open'), ID.OPEN },
    { L('_Reload'), ID.RELOAD },
    { L('gtk-save'), ID.SAVE },
    { L('gtk-save-as'), ID.SAVEAS },
    { SEPARATOR, ID.SEPARATOR },
    { L('gtk-close'), ID.CLOSE },
    { L('Close A_ll'), ID.CLOSE_ALL },
    { SEPARATOR, ID.SEPARATOR },
    { L('Loa_d Session...'), ID.LOAD_SESSION },
    { L('Sa_ve Session...'), ID.SAVE_SESSION },
    { SEPARATOR, ID.SEPARATOR },
    { L('gtk-quit'), ID.QUIT },
  },
  gtkmenu {
    title = L('_Edit'),
    { L('gtk-undo'), ID.UNDO },
    { L('gtk-redo'), ID.REDO },
    { SEPARATOR, ID.SEPARATOR },
    { L('gtk-cut'), ID.CUT },
    { L('gtk-copy'), ID.COPY },
    { L('gtk-paste'), ID.PASTE },
    { L('gtk-delete'), ID.DELETE },
    { L('gtk-select-all'), ID.SELECT_ALL },
    { SEPARATOR, ID.SEPARATOR },
    { L('Match _Brace'), ID.MATCH_BRACE },
    { L('Select t_o Brace'), ID.SELECT_TO_BRACE },
    { L('Complete _Word'), ID.COMPLETE_WORD },
    { L('De_lete Word'), ID.DELETE_WORD },
    { L('_Highlight Word'), ID.HIGHLIGHT_WORD },
    { L('Tran_spose Characters'), ID.TRANSPOSE_CHARACTERS },
    { L('_Join Lines'), ID.JOIN_LINES },
    { L('Convert _Indentation'), ID.CONVERT_INDENTATION },
    { title = L('S_election'),
      { title = L('_Enclose in...'),
        { L('_HTML Tags'), ID.ENCLOSE_IN_HTML_TAGS },
        { L('HTML Single _Tag'), ID.ENCLOSE_IN_HTML_SINGLE_TAG },
        { L('_Double Quotes'), ID.ENCLOSE_IN_DOUBLE_QUOTES },
        { L('_Single Quotes'), ID.ENCLOSE_IN_SINGLE_QUOTES },
        { L('_Parentheses'), ID.ENCLOSE_IN_PARENTHESES },
        { L('_Brackets'), ID.ENCLOSE_IN_BRACKETS },
        { L('B_races'), ID.ENCLOSE_IN_BRACES },
        { L('_Character Sequence'), ID.ENCLOSE_IN_CHARACTER_SEQUENCE },
      },
      { L('_Grow'), ID.GROW_SELECTION },
    },
    { title = L('Select i_n...'),
      { L('_HTML Tag'), ID.SELECT_IN_HTML_TAG },
      { L('_Double Quote'), ID.SELECT_IN_DOUBLE_QUOTE },
      { L('_Single Quote'), ID.SELECT_IN_SINGLE_QUOTE },
      { L('_Parenthesis'), ID.SELECT_IN_PARENTHESIS },
      { L('_Bracket'), ID.SELECT_IN_BRACKET },
      { L('B_race'), ID.SELECT_IN_BRACE },
      { L('_Word'), ID.SELECT_IN_WORD },
      { L('_Line'), ID.SELECT_IN_LINE },
      { L('Para_graph'), ID.SELECT_IN_PARAGRAPH },
      { L('_Indented Block'), ID.SELECT_IN_INDENTED_BLOCK },
      { L('S_cope'), ID.SELECT_IN_SCOPE },
    },
  },
  gtkmenu {
    title = L('_Tools'),
    { title = L('_Find'),
      { L('gtk-find'), ID.FIND },
      { L('Find _Next'), ID.FIND_NEXT },
      { L('Find _Previous'), ID.FIND_PREV },
      { L('gtk-find-and-replace'), ID.FIND_AND_REPLACE },
      { L('Replace'), ID.REPLACE },
      { L('Replace _All'), ID.REPLACE_ALL },
      { L('Find _Incremental'), ID.FIND_INCREMENTAL },
      { SEPARATOR, ID.SEPARATOR },
      { L('Find in Fi_les'), ID.FIND_IN_FILES },
      { L('Goto Next File Found'), ID.GOTO_NEXT_FILE_FOUND },
      { L('Goto Previous File Found'), ID.GOTO_PREV_FILE_FOUND },
      { SEPARATOR, ID.SEPARATOR },
      { L('gtk-jump-to'), ID.GOTO_LINE },
    },
    { L('Command _Entry'), ID.FOCUS_COMMAND_ENTRY },
    { SEPARATOR, ID.SEPARATOR },
    { L('_Run'), ID.RUN },
    { L('_Compile'), ID.COMPILE },
    { SEPARATOR, ID.SEPARATOR },
    { title = L('_Snippets'),
      { L('_Insert'), ID.INSERT_SNIPPET },
      { L('_Previous Placeholder'), ID.PREVIOUS_SNIPPET_PLACEHOLDER },
      { L('_Cancel'), ID.CANCEL_SNIPPET },
      { L('_List'), ID.LIST_SNIPPETS },
      { L('_Show Scope'), ID.SHOW_SCOPE },
    },
    { title = L('_Bookmark'),
      { L('_Toggle on Current Line'), ID.TOGGLE_BOOKMARK },
      { L('_Clear All'), ID.CLEAR_BOOKMARKS },
      { L('_Next'), ID.GOTO_NEXT_BOOKMARK },
      { L('_Previous'), ID.GOTO_PREV_BOOKMARK },
    },
    { title = L('Snap_open'),
      { L('_User Home'), ID.SNAPOPEN_USERHOME },
      { L('_Textadept Home'), ID.SNAPOPEN_HOME },
      { L('_Current Directory'), ID.SNAPOPEN_CURRENTDIR },
    },
  },
  gtkmenu {
    title = L('_Buffer'),
    { L('_Next Buffer'), ID.NEXT_BUFFER },
    { L('_Previous Buffer'), ID.PREV_BUFFER },
    { L('Swit_ch Buffer'), ID.SWITCH_BUFFER },
    { SEPARATOR, ID.SEPARATOR },
    { L('Toggle View _EOL'), ID.TOGGLE_VIEW_EOL },
    { L('Toggle _Wrap Mode'), ID.TOGGLE_WRAP_MODE },
    { L('Toggle Show _Indentation Guides'), ID.TOGGLE_SHOW_INDENT_GUIDES },
    { L('Toggle Use _Tabs'), ID.TOGGLE_USE_TABS },
    { L('Toggle View White_space'), ID.TOGGLE_VIEW_WHITESPACE },
    { SEPARATOR, ID.SEPARATOR },
    { title = L('EOL Mode'),
      { L('CRLF'), ID.EOL_MODE_CRLF },
      { L('CR'), ID.EOL_MODE_CR },
      { L('LF'), ID.EOL_MODE_LF },
    },
    { title = L('Encoding'),
      { L('UTF-8'), ID.ENCODING_UTF8 },
      { L('ASCII'), ID.ENCODING_ASCII },
      { L('ISO-8859-1'), ID.ENCODING_ISO88591 },
      { L('MacRoman'), ID.ENCODING_MACROMAN },
      { L('UTF-16'), ID.ENCODING_UTF16 },
    },
    { SEPARATOR, ID.SEPARATOR },
    { L('_Refresh Syntax Highlighting'), ID.REFRESH_SYNTAX_HIGHLIGHTING },
  },
  gtkmenu {
    title = L('_View'),
    { L('_Next View'), ID.NEXT_VIEW },
    { L('_Previous View'), ID.PREV_VIEW },
    { SEPARATOR, ID.SEPARATOR },
    { L('Split _Vertical'), ID.SPLIT_VIEW_VERTICAL },
    { L('Split _Horizontal'), ID.SPLIT_VIEW_HORIZONTAL },
    { L('_Unsplit'), ID.UNSPLIT_VIEW },
    { L('Unsplit _All'), ID.UNSPLIT_ALL_VIEWS },
    { SEPARATOR, ID.SEPARATOR },
    { L('_Grow'), ID.GROW_VIEW },
    { L('_Shrink'), ID.SHRINK_VIEW },
  },
  -- Lexer menu inserted here
  gtkmenu {
    title = L('_Help'),
    { L('_Manual'), ID.MANUAL },
    { L('_LuaDoc'), ID.LUADOC },
    { SEPARATOR, ID.SEPARATOR },
    { L('gtk-about'), ID.ABOUT },
  },
}
local lexer_menu = { title = L('Le_xers') }
for _, lexer in ipairs(_m.textadept.mime_types.lexers) do
  lexer = lexer:gsub('_', '__') -- no accelerators
  lexer_menu[#lexer_menu + 1] = { lexer, ID.LEXER_START + #lexer_menu }
end
table.insert(menubar, #menubar, gtkmenu(lexer_menu)) -- before 'Help'
gui.menubar = menubar

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
  buffer:set_lexer(lexer:gsub('__', '_'))
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

local actions = {
  -- File
  [ID.NEW] = { new_buffer },
  [ID.OPEN] = { io.open_file },
  [ID.RELOAD] = { 'reload', b },
  [ID.SAVE] = { 'save', b },
  [ID.SAVEAS] = { 'save_as', b },
  [ID.CLOSE] = { 'close', b },
  [ID.CLOSE_ALL] = { io.close_all },
  [ID.LOAD_SESSION] = {
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
  },
  [ID.SAVE_SESSION] = {
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
  },
  [ID.QUIT] = { quit },
  -- Edit
  [ID.UNDO] = { 'undo', b },
  [ID.REDO] = { 'redo', b },
  [ID.CUT] = { 'cut', b },
  [ID.COPY] = { 'copy', b },
  [ID.PASTE] = { 'paste', b },
  [ID.DELETE] = { 'clear', b },
  [ID.SELECT_ALL] = { 'select_all', b },
  [ID.MATCH_BRACE] = { m_editing.match_brace },
  [ID.SELECT_TO_BRACE] = { m_editing.match_brace, 'select' },
  [ID.COMPLETE_WORD] = { m_editing.autocomplete_word, '%w_' },
  [ID.DELETE_WORD] = { m_editing.current_word, 'delete' },
  [ID.HIGHLIGHT_WORD] = { m_editing.highlight_word },
  [ID.TRANSPOSE_CHARACTERS] = { m_editing.transpose_chars },
  [ID.JOIN_LINES] = { m_editing.join_lines },
  [ID.CONVERT_INDENTATION] = { m_editing.convert_indentation },
  -- Edit -> Selection -> Enclose in...
  [ID.ENCLOSE_IN_HTML_TAGS] = { m_editing.enclose, 'tag' },
  [ID.ENCLOSE_IN_HTML_SINGLE_TAG] = { m_editing.enclose, 'single_tag' },
  [ID.ENCLOSE_IN_DOUBLE_QUOTES] = { m_editing.enclose, 'dbl_quotes' },
  [ID.ENCLOSE_IN_SINGLE_QUOTES] = { m_editing.enclose, 'sng_quotes' },
  [ID.ENCLOSE_IN_PARENTHESES] = { m_editing.enclose, 'parens' },
  [ID.ENCLOSE_IN_BRACKETS] = { m_editing.enclose, 'brackets' },
  [ID.ENCLOSE_IN_BRACES] = { m_editing.enclose, 'braces' },
  [ID.ENCLOSE_IN_CHARACTER_SEQUENCE] = { m_editing.enclose, 'chars' },
  -- Edit -> Selection
  [ID.GROW_SELECTION] = { m_editing.grow_selection, 1 },
  -- Edit -> Select In...
  [ID.SELECT_IN_HTML_TAG] = { m_editing.select_enclosed, 'tags' },
  [ID.SELECT_IN_DOUBLE_QUOTE] = { m_editing.select_enclosed, 'dbl_quotes' },
  [ID.SELECT_IN_SINGLE_QUOTE] = { m_editing.select_enclosed, 'sng_quotes' },
  [ID.SELECT_IN_PARENTHESIS] = { m_editing.select_enclosed, 'parens' },
  [ID.SELECT_IN_BRACKET] = { m_editing.select_enclosed, 'brackets' },
  [ID.SELECT_IN_BRACE] = { m_editing.select_enclosed, 'braces' },
  [ID.SELECT_IN_WORD] = { m_editing.current_word, 'select' },
  [ID.SELECT_IN_LINE] = { m_editing.select_line },
  [ID.SELECT_IN_PARAGRAPH] = { m_editing.select_paragraph },
  [ID.SELECT_IN_INDENTED_BLOCK] = { m_editing.select_indented_block },
  [ID.SELECT_IN_SCOPE] = { m_editing.select_scope },
  -- Tools
  [ID.FIND] = { gui.find.focus },
  [ID.FIND_NEXT] = { gui.find.call_find_next },
  [ID.FIND_PREV] = { gui.find.call_find_prev },
  [ID.FIND_AND_REPLACE] = { gui.find.focus },
  [ID.REPLACE] = { gui.find.call_replace },
  [ID.REPLACE_ALL] = { gui.find.call_replace_all },
  [ID.FIND_INCREMENTAL] = { gui.find.find_incremental },
  [ID.FIND_IN_FILES] = {
    function()
      gui.find.in_files = true
      gui.find.focus()
    end
  },
  [ID.GOTO_NEXT_FILE_FOUND] = { gui.find.goto_file_in_list, true },
  [ID.GOTO_PREV_FILE_FOUND] = { gui.find.goto_file_in_list, false },
  [ID.GOTO_LINE] = { m_editing.goto_line },
  [ID.FOCUS_COMMAND_ENTRY] = { gui.command_entry.focus },
  [ID.RUN] = { m_run.run },
  [ID.COMPILE] = { m_run.compile },
  -- Tools -> Snippets
  [ID.INSERT_SNIPPET] = { m_snippets._insert },
  [ID.PREVIOUS_SNIPPET_PLACEHOLDER] = { m_snippets._prev },
  [ID.CANCEL_SNIPPET] = { m_snippets._cancel_current },
  [ID.LIST_SNIPPETS] = { m_snippets._list },
  [ID.SHOW_SCOPE] = { m_snippets._show_style },
  -- Tools -> Bookmark
  [ID.TOGGLE_BOOKMARK] = { m_bookmarks.toggle },
  [ID.CLEAR_BOOKMARKS] = { m_bookmarks.clear },
  [ID.GOTO_NEXT_BOOKMARK] = { m_bookmarks.goto_next },
  [ID.GOTO_PREV_BOOKMARK] = { m_bookmarks.goto_prev },
  -- Tools -> Snapopen
  [ID.SNAPOPEN_USERHOME] = { m_snapopen.open, _USERHOME },
  [ID.SNAPOPEN_HOME] = { m_snapopen.open, _HOME },
  [ID.SNAPOPEN_CURRENTDIR] = {
    function()
      if buffer.filename then
        m_snapopen.open(buffer.filename:match('^(.+)[/\\]'))
      end
    end
  },
  -- Buffer
  [ID.NEXT_BUFFER] = { 'goto_buffer', v, 1, false },
  [ID.PREV_BUFFER] = { 'goto_buffer', v, -1, false },
  [ID.TOGGLE_VIEW_EOL] = { toggle_setting, 'view_eol' },
  [ID.TOGGLE_WRAP_MODE] = { toggle_setting, 'wrap_mode' },
  [ID.TOGGLE_SHOW_INDENT_GUIDES] = { toggle_setting, 'indentation_guides' },
  [ID.TOGGLE_USE_TABS] = { toggle_setting, 'use_tabs' },
  [ID.TOGGLE_VIEW_WHITESPACE] = { toggle_setting, 'view_ws' },
  [ID.EOL_MODE_CRLF] = { set_eol_mode, 0 },
  [ID.EOL_MODE_CR] = { set_eol_mode, 1 },
  [ID.EOL_MODE_LF] = { set_eol_mode, 2 },
  [ID.ENCODING_UTF8] = { set_encoding, 'UTF-8' },
  [ID.ENCODING_ASCII] = { set_encoding, 'ASCII' },
  [ID.ENCODING_ISO88591] = { set_encoding, 'ISO-8859-1' },
  [ID.ENCODING_MACROMAN] = { set_encoding, 'MacRoman' },
  [ID.ENCODING_UTF16] = { set_encoding, 'UTF-16LE' },
  [ID.REFRESH_SYNTAX_HIGHLIGHTING] = { 'colourise', b, 0, -1 },
  [ID.SWITCH_BUFFER] = { gui.switch_buffer },
  -- View
  [ID.NEXT_VIEW] = { gui.goto_view, 1, false },
  [ID.PREV_VIEW] = { gui.goto_view, -1, false },
  [ID.SPLIT_VIEW_VERTICAL] = { 'split', v },
  [ID.SPLIT_VIEW_HORIZONTAL] = { 'split', v, false },
  [ID.UNSPLIT_VIEW] = { function() view:unsplit() end },
  [ID.UNSPLIT_ALL_VIEWS] = { function() while view:unsplit() do end end },
  [ID.GROW_VIEW] = {
    function() if view.size then view.size = view.size + 10 end end
  },
  [ID.SHRINK_VIEW] = {
    function() if view.size then view.size = view.size - 10 end end
  },
  -- Help
  [ID.MANUAL] = { open_webpage, _HOME..'/doc/manual/1_Introduction.html' },
  [ID.LUADOC] = { open_webpage, _HOME..'/doc/index.html' },
  [ID.ABOUT] = {
    gui.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
                _RELEASE, '--no-cancel'
  },
}

-- Most of this handling code comes from keys.lua.
events.connect('menu_clicked',
  function(menu_id)
    local active_table = actions[menu_id]
    if menu_id >= ID.LEXER_START and menu_id < ID.LEXER_START + 99 then
      active_table = { set_lexer, lexer_menu[menu_id - ID.LEXER_START + 1][1] }
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

-- Right-click context menu.
gui.context_menu = gtkmenu {
  { L('gtk-undo'), ID.UNDO },
  { L('gtk-redo'), ID.REDO },
  { SEPARATOR, ID.SEPARATOR },
  { L('gtk-cut'), ID.CUT },
  { L('gtk-copy'), ID.COPY },
  { L('gtk-paste'), ID.PASTE },
  { L('gtk-delete'), ID.DELETE },
  { SEPARATOR, ID.SEPARATOR },
  { L('gtk-select-all'), ID.SELECT_ALL }
}

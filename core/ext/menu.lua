-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Provides dynamic menus for Textadept.
-- This module, like ext/key_commands, should be 'require'ed last.
module('textadept.menu', package.seeall)

local t = textadept
local l = locale
local gtkmenu = textadept.gtkmenu

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
  TRANSPOSE_CHARACTERS = 212,
  SQUEEZE = 213,
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
    title = l.MENU_FILE_TITLE,
    { l.MENU_FILE_NEW, ID.NEW },
    { l.MENU_FILE_OPEN, ID.OPEN },
    { l.MENU_FILE_RELOAD, ID.RELOAD },
    { l.MENU_FILE_SAVE, ID.SAVE },
    { l.MENU_FILE_SAVEAS, ID.SAVEAS },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_FILE_CLOSE, ID.CLOSE },
    { l.MENU_FILE_CLOSE_ALL, ID.CLOSE_ALL },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_FILE_LOAD_SESSION, ID.LOAD_SESSION },
    { l.MENU_FILE_SAVE_SESSION, ID.SAVE_SESSION },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_FILE_QUIT, ID.QUIT },
  },
  gtkmenu {
    title = l.MENU_EDIT_TITLE,
    { l.MENU_EDIT_UNDO, ID.UNDO },
    { l.MENU_EDIT_REDO, ID.REDO },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_EDIT_CUT, ID.CUT },
    { l.MENU_EDIT_COPY, ID.COPY },
    { l.MENU_EDIT_PASTE, ID.PASTE },
    { l.MENU_EDIT_DELETE, ID.DELETE },
    { l.MENU_EDIT_SELECT_ALL, ID.SELECT_ALL },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_EDIT_MATCH_BRACE, ID.MATCH_BRACE },
    { l.MENU_EDIT_SELECT_TO_BRACE, ID.SELECT_TO_BRACE },
    { l.MENU_EDIT_COMPLETE_WORD, ID.COMPLETE_WORD },
    { l.MENU_EDIT_DELETE_WORD, ID.DELETE_WORD },
    { l.MENU_EDIT_TRANSPOSE_CHARACTERS, ID.TRANSPOSE_CHARACTERS },
    { l.MENU_EDIT_SQUEEZE, ID.SQUEEZE },
    { l.MENU_EDIT_JOIN_LINES, ID.JOIN_LINES },
    { l.MENU_EDIT_CONVERT_INDENTATION, ID.CONVERT_INDENTATION },
    { title = l.MENU_EDIT_SEL_TITLE,
      { title = l.MENU_EDIT_SEL_ENC_TITLE,
        { l.MENU_EDIT_SEL_ENC_HTML_TAGS, ID.ENCLOSE_IN_HTML_TAGS },
        { l.MENU_EDIT_SEL_ENC_HTML_SINGLE_TAG, ID.ENCLOSE_IN_HTML_SINGLE_TAG },
        { l.MENU_EDIT_SEL_ENC_DOUBLE_QUOTES, ID.ENCLOSE_IN_DOUBLE_QUOTES },
        { l.MENU_EDIT_SEL_ENC_SINGLE_QUOTES, ID.ENCLOSE_IN_SINGLE_QUOTES },
        { l.MENU_EDIT_SEL_ENC_PARENTHESES, ID.ENCLOSE_IN_PARENTHESES },
        { l.MENU_EDIT_SEL_ENC_BRACKETS, ID.ENCLOSE_IN_BRACKETS },
        { l.MENU_EDIT_SEL_ENC_BRACES, ID.ENCLOSE_IN_BRACES },
        { l.MENU_EDIT_SEL_ENC_CHAR_SEQ, ID.ENCLOSE_IN_CHARACTER_SEQUENCE },
      },
      { l.MENU_EDIT_SEL_GROW, ID.GROW_SELECTION },
    },
    { title = l.MENU_EDIT_SEL_IN_TITLE,
      { l.MENU_EDIT_SEL_IN_HTML_TAG, ID.SELECT_IN_HTML_TAG },
      { l.MENU_EDIT_SEL_IN_DOUBLE_QUOTE, ID.SELECT_IN_DOUBLE_QUOTE },
      { l.MENU_EDIT_SEL_IN_SINGLE_QUOTE, ID.SELECT_IN_SINGLE_QUOTE },
      { l.MENU_EDIT_SEL_IN_PARENTHESIS, ID.SELECT_IN_PARENTHESIS },
      { l.MENU_EDIT_SEL_IN_BRACKET, ID.SELECT_IN_BRACKET },
      { l.MENU_EDIT_SEL_IN_BRACE, ID.SELECT_IN_BRACE },
      { l.MENU_EDIT_SEL_IN_WORD, ID.SELECT_IN_WORD },
      { l.MENU_EDIT_SEL_IN_LINE, ID.SELECT_IN_LINE },
      { l.MENU_EDIT_SEL_IN_PARAGRAPH, ID.SELECT_IN_PARAGRAPH },
      { l.MENU_EDIT_SEL_IN_INDENTED_BLOCK, ID.SELECT_IN_INDENTED_BLOCK },
      { l.MENU_EDIT_SEL_IN_SCOPE, ID.SELECT_IN_SCOPE },
    },
  },
  gtkmenu {
    title = l.MENU_TOOLS_TITLE,
    { title = l.MENU_TOOLS_SEARCH_TITLE,
      { l.MENU_TOOLS_SEARCH_FIND, ID.FIND },
      { l.MENU_TOOLS_SEARCH_FIND_NEXT, ID.FIND_NEXT },
      { l.MENU_TOOLS_SEARCH_FIND_PREV, ID.FIND_PREV },
      { l.MENU_TOOLS_SEARCH_FIND_AND_REPLACE, ID.FIND_AND_REPLACE },
      { l.MENU_TOOLS_SEARCH_REPLACE, ID.REPLACE },
      { l.MENU_TOOLS_SEARCH_REPLACE_ALL, ID.REPLACE_ALL },
      { l.MENU_TOOLS_SEARCH_FIND_INCREMENTAL, ID.FIND_INCREMENTAL },
      { SEPARATOR, ID.SEPARATOR },
      { l.MENU_TOOLS_SEARCH_FIND_IN_FILES, ID.FIND_IN_FILES },
      { l.MENU_TOOLS_SEARCH_GOTO_NEXT_FILE_FOUND, ID.GOTO_NEXT_FILE_FOUND },
      { l.MENU_TOOLS_SEARCH_GOTO_PREV_FILE_FOUND, ID.GOTO_PREV_FILE_FOUND },
      { SEPARATOR, ID.SEPARATOR },
      { l.MENU_TOOLS_SEARCH_GOTO_LINE, ID.GOTO_LINE },
    },
    { l.MENU_TOOLS_FOCUS_COMMAND_ENTRY, ID.FOCUS_COMMAND_ENTRY },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_TOOLS_RUN, ID.RUN },
    { l.MENU_TOOLS_COMPILE, ID.COMPILE },
    { SEPARATOR, ID.SEPARATOR },
    { title = l.MENU_TOOLS_SNIPPETS_TITLE,
      { l.MENU_TOOLS_SNIPPETS_INSERT, ID.INSERT_SNIPPET },
      { l.MENU_TOOLS_SNIPPETS_PREV_PLACE, ID.PREVIOUS_SNIPPET_PLACEHOLDER },
      { l.MENU_TOOLS_SNIPPETS_CANCEL, ID.CANCEL_SNIPPET },
      { l.MENU_TOOLS_SNIPPETS_LIST, ID.LIST_SNIPPETS },
      { l.MENU_TOOLS_SNIPPETS_SHOW_SCOPE, ID.SHOW_SCOPE },
    },
    { title = l.MENU_TOOLS_BM_TITLE,
      { l.MENU_TOOLS_BM_TOGGLE, ID.TOGGLE_BOOKMARK },
      { l.MENU_TOOLS_BM_CLEAR_ALL, ID.CLEAR_BOOKMARKS },
      { l.MENU_TOOLS_BM_NEXT, ID.GOTO_NEXT_BOOKMARK },
      { l.MENU_TOOLS_BM_PREV, ID.GOTO_PREV_BOOKMARK },
    },
  },
  gtkmenu {
    title = l.MENU_BUF_TITLE,
    { l.MENU_BUF_NEXT, ID.NEXT_BUFFER },
    { l.MENU_BUF_PREV, ID.PREV_BUFFER },
    { l.MENU_BUF_SWITCH, ID.SWITCH_BUFFER },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_BUF_TOGGLE_VIEW_EOL, ID.TOGGLE_VIEW_EOL },
    { l.MENU_BUF_TOGGLE_WRAP, ID.TOGGLE_WRAP_MODE },
    { l.MENU_BUF_TOGGLE_INDENT_GUIDES, ID.TOGGLE_SHOW_INDENT_GUIDES },
    { l.MENU_BUF_TOGGLE_TABS, ID.TOGGLE_USE_TABS },
    { l.MENU_BUF_TOGGLE_VIEW_WHITESPACE, ID.TOGGLE_VIEW_WHITESPACE },
    { SEPARATOR, ID.SEPARATOR },
    { title = l.MENU_BUF_EOL_MODE_TITLE,
      { l.MENU_BUF_EOL_MODE_CRLF, ID.EOL_MODE_CRLF },
      { l.MENU_BUF_EOL_MODE_CR, ID.EOL_MODE_CR },
      { l.MENU_BUF_EOL_MODE_LF, ID.EOL_MODE_LF },
    },
    { title = l.MENU_BUF_ENCODING_TITLE,
      { l.MENU_BUF_ENCODING_UTF8, ID.ENCODING_UTF8 },
      { l.MENU_BUF_ENCODING_ASCII, ID.ENCODING_ASCII },
      { l.MENU_BUF_ENCODING_ISO88591, ID.ENCODING_ISO88591 },
      { l.MENU_BUF_ENCODING_MACROMAN, ID.ENCODING_MACROMAN },
      { l.MENU_BUF_ENCODING_UTF16, ID.ENCODING_UTF16 },
    },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_BUF_REFRESH, ID.REFRESH_SYNTAX_HIGHLIGHTING },
  },
  gtkmenu {
    title = l.MENU_VIEW_TITLE,
    { l.MENU_VIEW_NEXT, ID.NEXT_VIEW },
    { l.MENU_VIEW_PREV, ID.PREV_VIEW },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_VIEW_SPLIT_VERTICAL, ID.SPLIT_VIEW_VERTICAL },
    { l.MENU_VIEW_SPLIT_HORIZONTAL, ID.SPLIT_VIEW_HORIZONTAL },
    { l.MENU_VIEW_UNSPLIT, ID.UNSPLIT_VIEW },
    { l.MENU_VIEW_UNSPLIT_ALL, ID.UNSPLIT_ALL_VIEWS },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_VIEW_GROW, ID.GROW_VIEW },
    { l.MENU_VIEW_SHRINK, ID.SHRINK_VIEW },
  },
  -- Lexer menu inserted here
  gtkmenu {
    title = l.MENU_HELP_TITLE,
    { l.MENU_HELP_MANUAL, ID.MANUAL },
    { l.MENU_HELP_LUADOC, ID.LUADOC },
    { SEPARATOR, ID.SEPARATOR },
    { l.MENU_HELP_ABOUT, ID.ABOUT },
  },
}
local lexer_menu = { title = l.MENU_LEX_TITLE }
for _, lexer in ipairs(textadept.mime_types.lexers) do
  lexer_menu[#lexer_menu + 1] = { lexer, ID.LEXER_START + #lexer_menu }
end
table.insert(menubar, #menubar, gtkmenu(lexer_menu)) -- before 'Help'
t.menubar = menubar

local b, v = 'buffer', 'view'
local m_snippets = _m.textadept.snippets
local m_editing = _m.textadept.editing
local m_bookmarks = _m.textadept.bookmarks
local m_run = _m.textadept.run

local function set_encoding(encoding)
  buffer:set_encoding(encoding)
  t.events.handle('update_ui') -- for updating statusbar
end
local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  t.events.handle('update_ui') -- for updating statusbar
end
local function set_eol_mode(mode)
  buffer.eol_mode = mode
  buffer:convert_eo_ls(mode)
  t.events.handle('update_ui') -- for updating statusbar
end
local function set_lexer(lexer)
  buffer:set_lexer(lexer)
  buffer:colourise(0, -1)
  t.events.handle('update_ui') -- for updating statusbar
end
local function open_webpage(url)
  local cmd
  if WIN32 then
    cmd = string.format('start "" "%s"', url)
    local p = io.popen(cmd)
    if not p then error(l.MENU_BROWSER_ERROR..url) end
  else
    cmd = string.format(MAC and 'open "file://%s"' or 'xdg-open "%s" &', url)
    if os.execute(cmd) ~= 0 then error(l.MENU_BROWSER_ERROR..url) end
  end
end

local actions = {
  -- File
  [ID.NEW] = { t.new_buffer },
  [ID.OPEN] = { io.open_file },
  [ID.RELOAD] = { 'reload', b },
  [ID.SAVE] = { 'save', b },
  [ID.SAVEAS] = { 'save_as', b },
  [ID.CLOSE] = { 'close', b },
  [ID.CLOSE_ALL] = { io.close_all },
  [ID.LOAD_SESSION] = {
    function()
      local utf8_filename =
        t.dialog('fileselect',
                 '--title', l.MENU_LOAD_SESSION_TITLE,
                 '--with-directory',
                   (textadept.session_file or ''):match('.+[/\\]') or '',
                 '--with-file',
                   (textadept.session_file or ''):match('[^/\\]+$') or '',
                  '--no-newline')
      if #utf8_filename > 0 then
        _m.textadept.session.load(t.iconv(utf8_filename, _CHARSET, 'UTF-8'))
      end
    end
  },
  [ID.SAVE_SESSION] = {
    function()
      local utf8_filename =
        t.dialog('filesave',
                 '--title', l.MENU_SAVE_SESSION_TITLE,
                 '--with-directory',
                   (textadept.session_file or ''):match('.+[/\\]') or '',
                 '--with-file',
                   (textadept.session_file or ''):match('[^/\\]+$') or '',
                 '--no-newline')
      if #utf8_filename > 0 then
        _m.textadept.session.save(t.iconv(utf8_filename, _CHARSET, 'UTF-8'))
      end
    end
  },
  [ID.QUIT] = { t.quit },
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
  [ID.TRANSPOSE_CHARACTERS] = { m_editing.transpose_chars },
  [ID.SQUEEZE] = { m_editing.squeeze },
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
  [ID.FIND] = { t.find.focus },
  [ID.FIND_NEXT] = { t.find.call_find_next },
  [ID.FIND_PREV] = { t.find.call_find_prev },
  [ID.FIND_AND_REPLACE] = { t.find.focus },
  [ID.REPLACE] = { t.find.call_replace },
  [ID.REPLACE_ALL] = { t.find.call_replace_all },
  [ID.FIND_INCREMENTAL] = { t.find.find_incremental },
  [ID.FIND_IN_FILES] = {
    function()
      t.find.in_files = true
      t.find.focus()
    end
  },
  [ID.GOTO_NEXT_FILE_FOUND] = { t.find.goto_file_in_list, true },
  [ID.GOTO_PREV_FILE_FOUND] = { t.find.goto_file_in_list, false },
  [ID.GOTO_LINE] = { m_editing.goto_line },
  [ID.FOCUS_COMMAND_ENTRY] = { t.command_entry.focus },
  [ID.RUN] = { m_run.run },
  [ID.COMPILE] = { m_run.compile },
  -- Tools -> Snippets
  [ID.INSERT_SNIPPET] = { m_snippets.insert },
  [ID.PREVIOUS_SNIPPET_PLACEHOLDER] = { m_snippets.prev },
  [ID.CANCEL_SNIPPET] = { m_snippets.cancel_current },
  [ID.LIST_SNIPPETS] = { m_snippets.list },
  [ID.SHOW_SCOPE] = { m_snippets.show_style },
  -- Tools -> Bookmark
  [ID.TOGGLE_BOOKMARK] = { m_bookmarks.toggle },
  [ID.CLEAR_BOOKMARKS] = { m_bookmarks.clear },
  [ID.GOTO_NEXT_BOOKMARK] = { m_bookmarks.goto_next },
  [ID.GOTO_PREV_BOOKMARK] = { m_bookmarks.goto_prev },
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
  [ID.SWITCH_BUFFER] = { t.switch_buffer },
  -- View
  [ID.NEXT_VIEW] = { t.goto_view, 1, false },
  [ID.PREV_VIEW] = { t.goto_view, -1, false },
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
    t.dialog, 'ok-msgbox', '--title', 'Textadept', '--informative-text',
              _RELEASE, '--no-cancel'
  },
}

-- Most of this handling code comes from keys.lua.
t.events.add_handler('menu_clicked',
  function(menu_id)
    local active_table = actions[menu_id]
    if menu_id >= ID.LEXER_START and menu_id < ID.LEXER_START + 99 then
      active_table =
        { set_lexer, lexer_menu[menu_id - ID.LEXER_START + 1][1] }
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
        error(l.MENU_UNKNOWN_COMMAND..tostring(func))
      end
    end
  end)

-- Right-click context menu.
t.context_menu = gtkmenu {
  { l.MENU_EDIT_UNDO, ID.UNDO },
  { l.MENU_EDIT_REDO, ID.REDO },
  { SEPARATOR, ID.SEPARATOR },
  { l.MENU_EDIT_CUT, ID.CUT },
  { l.MENU_EDIT_COPY, ID.COPY },
  { l.MENU_EDIT_PASTE, ID.PASTE },
  { l.MENU_EDIT_DELETE, ID.DELETE },
  { SEPARATOR, ID.SEPARATOR },
  { l.MENU_EDIT_SELECT_ALL, ID.SELECT_ALL }
}

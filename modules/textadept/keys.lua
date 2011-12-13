-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize
local gui = gui

local M = {}

--[[
---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors.
-- This module, should be 'require'ed last, but before _m.textadept.menu.
module('_m.textadept.keys', package.seeall)]]

local keys, _buffer, _view = keys, buffer, view
local m_textadept, m_editing = _m.textadept, _m.textadept.editing
local c, OSX = _SCINTILLA.constants, OSX

-- Utility functions.
M.utils = {
  enclose_as_xml_tags = function()
    m_editing.enclose('<', '>')
    local buffer = buffer
    local pos = buffer.current_pos
    while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
    buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
  end,
  find_in_files = function()
    gui.find.in_files = true
    gui.find.focus()
  end,
  select_command = function() _m.textadept.menu.select_command() end,
  snapopen_filedir = function()
    if buffer.filename then
      m_textadept.snapopen.open(buffer.filename:match('^(.+)[/\\]'))
    end
  end,
  show_style = function()
    local buffer = buffer
    local style = buffer.style_at[buffer.current_pos]
    local text = string.format("%s %s\n%s %s (%d)", L('Lexer'),
                               buffer:get_lexer(), L('Style'),
                               buffer:get_style_name(style), style)
    buffer:call_tip_show(buffer.current_pos, text)
  end,
  set_indentation = function(i)
    buffer.indent, buffer.tab_width = i, i
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  toggle_property = function(property, i)
    local state = buffer[property]
    if type(state) == 'boolean' then
      buffer[property] = not state
    elseif type(state) == 'number' then
      buffer[property] = buffer[property] == 0 and (i or 1) or 0
    end
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  set_encoding = function(encoding)
    buffer:set_encoding(encoding)
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  set_eol_mode = function(mode)
    buffer.eol_mode = mode
    buffer:convert_eo_ls(mode)
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  unsplit_all = function() while view:unsplit() do end end,
  grow = function() if view.size then view.size = view.size + 10 end end,
  shrink = function() if view.size then view.size = view.size - 10 end end,
  toggle_current_fold = function()
    local buffer = buffer
    buffer:toggle_fold(buffer:line_from_position(buffer.current_pos))
  end,
  reset_zoom = function() buffer.zoom = 0 end,
  open_webpage = function(url)
    local cmd
    if WIN32 then
      cmd = string.format('start "" "%s"', url)
      local p = io.popen(cmd)
      if not p then error(L('Error loading webpage:')..url) end
    else
      cmd = string.format(OSX and 'open "file://%s"' or 'xdg-open "%s" &', url)
      local _, _, code = os.execute(cmd)
      if code ~= 0 then error(L('Error loading webpage:')..url) end
    end
  end
}
-- The following buffer functions need to be constantized in order for menu
-- items to identify the key associated with the functions.
local menu_buffer_functions = {
  'undo', 'redo', 'cut', 'copy', 'paste', 'line_duplicate', 'clear',
  'select_all', 'upper_case', 'lower_case', 'move_selected_lines_up',
  'move_selected_lines_down', 'zoom_in', 'zoom_out', 'colourise'
}
local function constantize_menu_buffer_functions()
  local buffer = buffer
  for _, f in ipairs(menu_buffer_functions) do buffer[f] = buffer[f] end
end
events.connect(events.BUFFER_NEW, constantize_menu_buffer_functions)
-- Scintilla's first buffer does not have this.
if not RESETTING then constantize_menu_buffer_functions() end

--[[
  Windows and Linux menu key commands.

  Unassigned keys (~ denotes keys reserved by the operating system):
  c:   A B C         H              p qQ       ~ V   X Y      ) ] }  *      \n
  a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpP QrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=~~\n\s
  ca: aAbBcCdDeE F      jJkKlLmM N   PqQ    t       xXy zZ_"'()[]{}<>*  / ~~  \s

  CTRL = 'c' (Control ^)
  ALT = 'a' (Alt)
  META = [unused]
  SHIFT = 's' (Shift ⇧)
  ADD = ''
  Control, Alt, Shift, and 'a' = 'caA'
  Control, Alt, Shift, and '\t' = 'cas\t'

  Mac OSX menu key commands.

  Unassigned keys (~ denotes keys reserved by the operating system):
  m:   A B C        ~    JkK  ~M    p  ~    t  U V   XyY      ) ] }  *    ~~\n~~
  c:      cC D    gG H  J K L    oO  qQ             xXyYzZ_   ) ] }  *  /     \s
  cm: aAbBcC~DeE F  ~HiIjJkKlL~MnN  pPq~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=\t\n~~

  CTRL = 'c' (Control ^)
  ALT = 'a' (Alt/option ⌥)
  META = 'm' (Command ⌘)
  SHIFT = 's' (Shift ⇧)
  ADD = ''
  Command, Option, Shift, and 'a' = 'amA'
  Command, Option, Shift, and '\t' = 'ams\t'
]]--

-- File.
keys[not OSX and 'cn' or 'mn'] = new_buffer
keys[not OSX and 'co' or 'mo'] = io.open_file
keys[not OSX and 'cao' or 'cmo'] = io.open_recent_file
keys[not OSX and 'cO' or 'mO'] = _buffer.reload
keys[not OSX and 'cs' or 'ms'] = _buffer.save
keys[not OSX and 'cS' or 'mS'] = _buffer.save_as
keys[not OSX and 'cw' or 'mw'] = _buffer.close
keys[not OSX and 'cW' or 'mW'] = io.close_all
-- TODO: m_textadept.sessions.prompt_load
-- TODO: m_textadept.sessions.prompt_save
keys[not OSX and 'aq' or 'mq'] = quit

-- Edit.
keys[not OSX and 'cz' or 'mz'] = _buffer.undo
if not OSX then keys.cy = _buffer.redo end
keys[not OSX and 'cZ' or 'mZ'] = _buffer.redo
keys[not OSX and 'cx' or 'mx'] = _buffer.cut
keys[not OSX and 'cc' or 'mc'] = _buffer.copy
keys[not OSX and 'cv' or 'mv'] = _buffer.paste
keys[not OSX and 'cd' or 'md'] = _buffer.line_duplicate
keys.del = _buffer.clear
keys[not OSX and 'ca' or 'ma'] = _buffer.select_all
keys.cm = m_editing.match_brace
keys[not OSX and 'c\n' or 'cesc'] = { m_editing.autocomplete_word, '%w_' }
keys[not OSX and 'adel' or 'cdel'] = { m_editing.current_word, 'delete' }
keys[not OSX and 'caH' or 'mH'] = m_editing.highlight_word
keys[not OSX and 'c/' or 'm/'] = m_editing.block_comment
keys.ct = m_editing.transpose_chars
keys[not OSX and 'cJ' or 'cj'] = m_editing.join_lines
-- Select.
keys.cM = { m_editing.match_brace, 'select' }
keys[not OSX and 'c<' or 'm<'] = { m_editing.select_enclosed, '>', '<' }
keys[not OSX and 'c>' or 'm>'] = { m_editing.select_enclosed, '<', '>' }
keys[not OSX and "c'" or "m'"] = { m_editing.select_enclosed, "'", "'" }
keys[not OSX and 'c"' or 'm"'] = { m_editing.select_enclosed, '"', '"' }
keys[not OSX and 'c(' or 'm('] = { m_editing.select_enclosed, '(', ')' }
keys[not OSX and 'c[' or 'm['] = { m_editing.select_enclosed, '[', ']' }
keys[not OSX and 'c{' or 'm{'] = { m_editing.select_enclosed, '{', '}' }
keys[not OSX and 'cD' or 'mD'] = { m_editing.current_word, 'select' }
keys[not OSX and 'cN' or 'mN'] = m_editing.select_line
keys[not OSX and 'cP' or 'mP'] = m_editing.select_paragraph
keys[not OSX and 'cI' or 'mI'] = m_editing.select_indented_block
-- Selection.
keys[not OSX and 'cau' or 'cu'] = _buffer.upper_case
keys[not OSX and 'caU' or 'cU'] = _buffer.lower_case
keys[not OSX and 'a<' or 'c<'] = M.utils.enclose_as_xml_tags
keys[not OSX and 'a>' or 'c>'] = { m_editing.enclose, '<', ' />' }
keys[not OSX and "a'" or "c'"] = { m_editing.enclose, "'", "'" }
keys[not OSX and 'a"' or 'c"'] = { m_editing.enclose, '"', '"' }
keys[not OSX and 'a(' or 'c('] = { m_editing.enclose, '(', ')' }
keys[not OSX and 'a[' or 'c['] = { m_editing.enclose, '[', ']' }
keys[not OSX and 'a{' or 'c{'] = { m_editing.enclose, '{', '}' }
keys[not OSX and 'c+' or 'm+'] = { m_editing.grow_selection, 1 }
keys[not OSX and 'c_' or 'm_'] = { m_editing.grow_selection, -1 }
keys.csup = _buffer.move_selected_lines_up
keys.csdown = _buffer.move_selected_lines_down

-- Search.
keys[not OSX and 'cf' or 'mf'] = gui.find.focus
keys[not OSX and 'cg' or 'mg'] = gui.find.find_next
if not OSX then keys.f3 = keys.cg end
keys[not OSX and 'cG' or 'mG'] = gui.find.find_prev
if not OSX then keys.sf3 = keys.cG end
keys[not OSX and 'car' or 'cr'] = gui.find.replace
keys[not OSX and 'caR' or 'cR'] = gui.find.replace_all
-- Find Next is an when find pane is focused.
-- Find Prev is ap when find pane is focused.
-- Replace is ar when find pane is focused.
-- Replace All is aa when find pane is focused.
keys[not OSX and 'caf' or 'cmf'] = gui.find.find_incremental
keys[not OSX and 'cF' or 'mF'] = M.utils.find_in_files
-- Find in Files is ai when find pane is focused.
keys[not OSX and 'cag' or 'cmg'] = { gui.find.goto_file_in_list, true }
keys[not OSX and 'caG' or 'cmG'] = { gui.find.goto_file_in_list, false }
keys[not OSX and 'cj' or 'mj'] = m_editing.goto_line

-- Tools.
keys[not OSX and 'ce' or 'me'] = gui.command_entry.focus
keys[not OSX and 'cE' or 'mE'] = M.utils.select_command
keys[not OSX and 'cr' or 'mr'] = m_textadept.run.run
keys[not OSX and 'cR' or 'mR'] = m_textadept.run.compile
keys[not OSX and 'c|' or 'm|'] = m_textadept.filter_through.filter_through
-- Adeptsense.
keys[not OSX and 'c ' or 'aesc'] = m_textadept.adeptsense.complete_symbol
keys.ch = m_textadept.adeptsense.show_documentation
-- Snippets.
keys[not OSX and 'ck' or 'a\t'] = m_textadept.snippets._select
keys['\t'] = m_textadept.snippets._insert
keys['s\t'] = m_textadept.snippets._previous
keys[not OSX and 'cK' or 'as\t'] = m_textadept.snippets._cancel_current
-- Bookmark.
keys[not OSX and 'cf2' or 'mf2'] = m_textadept.bookmarks.toggle
keys[not OSX and 'csf2' or 'msf2'] = m_textadept.bookmarks.clear
keys.f2 = m_textadept.bookmarks.goto_next
keys.sf2 = m_textadept.bookmarks.goto_prev
keys.af2 = m_textadept.bookmarks.goto_bookmark
-- Snapopen.
keys[not OSX and 'cu' or 'mu'] = { m_textadept.snapopen.open, _USERHOME }
-- TODO: { m_textadept.snapopen.open, _HOME }
keys[not OSX and 'caO' or 'cmO'] = M.utils.snapopen_filedir
keys[not OSX and 'ci' or 'mi'] = M.utils.show_style

-- Buffer.
keys['c\t'] = { _view.goto_buffer, _view, 1, true }
keys['cs\t'] = { _view.goto_buffer, _view, -1, true }
keys[not OSX and 'cb' or 'mb'] = gui.switch_buffer
-- Indentation.
-- TODO: { M.utils.set_indentation, 2 }
-- TODO: { M.utils.set_indentation, 3 }
-- TODO: { M.utils.set_indentation, 4 }
-- TODO: { M.utils.set_indentation, 8 }
keys[not OSX and 'caT' or 'cT'] = { M.utils.toggle_property, 'use_tabs' }
keys[not OSX and 'cai' or 'ci'] = m_editing.convert_indentation
-- EOL Mode.
-- TODO: { M.utils.set_eol_mode, c.SC_EOL_CRLF }
-- TODO: { M.utils.set_eol_mode, c.SC_EOL_CR }
-- TODO: { M.utils.set_eol_mode, c.SC_EOL_LF }
-- Encoding.
-- TODO: { M.utils.set_encoding, 'UTF-8' }
-- TODO: { M.utils.set_encoding, 'ASCII' }
-- TODO: { M.utils.set_encoding, 'ISO-8859-1' }
-- TODO: { M.utils.set_encoding, 'MacRoman' }
-- TODO: { M.utils.set_encoding, 'UTF-16LE' }
keys[not OSX and 'cL' or 'mL'] = m_textadept.mime_types.select_lexer
keys.f5 = { _buffer.colourise, _buffer, 0, -1 }

-- View.
keys[not OSX and 'can' or 'ca\t'] = { gui.goto_view, 1, true }
keys[not OSX and 'cap' or 'cas\t'] = { gui.goto_view, -1, true }
keys[not OSX and 'cas' or 'cs'] = { _view.split, _view }
if not OSX then keys.cah = keys.cas end
keys[not OSX and 'cav' or 'cv'] = { _view.split, _view, true }
keys[not OSX and 'caw' or 'cw'] = { _view.unsplit, _view }
keys[not OSX and 'caW' or 'cW'] = M.utils.unsplit_all
keys[not OSX and 'ca+' or 'c+'] = { M.utils.grow, 10 }
keys[not OSX and 'ca=' or 'c='] = { M.utils.grow, 10 }
keys[not OSX and 'ca-' or 'c-'] = { M.utils.shrink, 10 }
-- TODO: M.utils.toggle_current_fold
keys[not OSX and 'ca\n' or 'c\n'] = { M.utils.toggle_property, 'view_eol' }
if not OSX then keys['ca\n\r'] = keys['ca\n'] end
keys[not OSX and 'ca\\' or 'c\\'] = { M.utils.toggle_property, 'wrap_mode' }
keys[not OSX and 'caI' or 'cI'] =
  { M.utils.toggle_property, 'indentation_guides' }
keys[not OSX and 'caS' or 'cS'] = { M.utils.toggle_property, 'view_ws' }
keys[not OSX and 'caV' or 'cV'] =
  { M.utils.toggle_property, 'virtual_space_options', c.SCVS_USERACCESSIBLE }
keys[not OSX and 'c=' or 'm='] = _buffer.zoom_in
keys[not OSX and 'c-' or 'm-'] = _buffer.zoom_out
keys[not OSX and 'c0' or 'm0'] = M.utils.reset_zoom
keys[not OSX and 'cT' or 'mT'] = gui.select_theme

-- Help.
keys.f1 = { M.utils.open_webpage, _HOME..'/doc/manual/1_Introduction.html' }
keys.sf1 = { M.utils.open_webpage, _HOME..'/doc/index.html' }
-- TODO: { gui.dialog, 'ok-msgbox', '--title', 'Textadept'
--         '--informative-text', _RELEASE, '--no-cancel' }

-- Movement commands.
if OSX then
  keys.ck = function()
    buffer:line_end_extend()
    buffer:cut()
  end
  keys.cf = _buffer.char_right
  keys.cF = _buffer.char_right_extend
  keys.cmf = _buffer.word_right
  keys.cmF = _buffer.word_right_extend
  keys.cb = _buffer.char_left
  keys.cB = _buffer.char_left_extend
  keys.cmb = _buffer.word_left
  keys.cmB = _buffer.word_left_extend
  keys.cn = _buffer.line_down
  keys.cN = _buffer.line_down_extend
  keys.cp = _buffer.line_up
  keys.cP = _buffer.line_up_extend
  keys.ca = _buffer.vc_home
  keys.cA = _buffer.vc_home_extend
  keys.ce = _buffer.line_end
  keys.cE = _buffer.line_end_extend
  keys.cd = _buffer.clear
  keys.cl = _buffer.vertical_centre_caret
end

return M

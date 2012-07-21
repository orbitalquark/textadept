-- Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors.
-- This module, should be `require`d last, but before `_M.textadept.menu`.
module('_M.textadept.keys')]]

-- Utility functions.
M.utils = {
  delete_word = function()
    _M.textadept.editing.select_word()
    buffer:delete_back()
  end,
  enclose_as_xml_tags = function()
    _M.textadept.editing.enclose('<', '>')
    local buffer = buffer
    local pos = buffer.current_pos
    while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
    buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
  end,
  find_in_files = function()
    gui.find.in_files = true
    gui.find.focus()
  end,
  select_command = function() _M.textadept.menu.select_command() end,
  snapopen_filedir = function()
    if buffer.filename then
      _M.textadept.snapopen.open(buffer.filename:match('^(.+)[/\\]'))
    end
  end,
  show_style = function()
    local buffer = buffer
    local style = buffer.style_at[buffer.current_pos]
    local text = string.format("%s %s\n%s %s (%d)", _L['Lexer'],
                               buffer:get_lexer(true), _L['Style'],
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
      if not p then error(_L['Error loading webpage:']..url) end
      p:close()
    else
      cmd = string.format(OSX and 'open "file://%s"' or 'xdg-open "%s" &', url)
      local _, _, code = os.execute(cmd)
      if code ~= 0 then error(_L['Error loading webpage:']..url) end
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

local keys = keys
local io, gui, gui_find, buffer, view = io, gui, gui.find, buffer, view
local m_textadept, m_editing = _M.textadept, _M.textadept.editing
local m_bookmarks, m_snippets = m_textadept.bookmarks, m_textadept.snippets
local OSX, c = OSX, _SCINTILLA.constants
local utils = M.utils

-- Windows and Linux menu key commands.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:   A B C         H              p  Q       ~ V   X Y      ) ] }  *
-- a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=\n\s
-- ca: aAbBcCdDeE F      jJkKlLmM N   PqQ    t       xXy zZ_"'()[]{}<>*  /   \s
--
-- CTRL = 'c' (Control ^)
-- ALT = 'a' (Alt)
-- META = [unused]
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Control, Alt, Shift, and 'a' = 'caA'
-- Control, Alt, Shift, and '\t' = 'cas\t'
--
-- Mac OSX menu key commands.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- m:   A B C        ~    JkK  ~M    p  ~    t  U V   XyY      ) ] }  *    ~~\n
-- c:      cC D    gG H  J K L    oO  qQ             xXyYzZ_   ) ] }  *  /
-- cm: aAbBcC~DeE F  ~HiIjJkKlL~MnN  pPq~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=\t\n
--
-- CTRL = 'c' (Control ^)
-- ALT = 'a' (Alt/option ⌥)
-- META = 'm' (Command ⌘)
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Command, Option, Shift, and 'a' = 'amA'
-- Command, Option, Shift, and '\t' = 'ams\t'
--
-- ncurses key commands.
--
-- The terminal keymap is much more limited and complicated:
--   * Control+[Shift+](digit/symbol) gives limited results.
--     Here are example keymaps for a US English keyboard:
--       Pressing Control+ `1234567890-=[]\;',./
--       Results in c:     @ @ \]^_   __ ]\ g
--       (e.g. `keys.c2` in the GUI would be `keys['c@']` in the terminal.)
--       Notes:
--         * Adding the Shift modifier to any of the above keys gives the same
--           result.
--         * Adding the Alt and/or Shift modifiers to any of the above keys also
--           gives the same result, but with only the Alt modifier being
--           recognized (e.g. `keys['ca$']` would be `keys['ca\']`).
--   * Control+[Alt+]Shift+letter does not report the uppercase letter (e.g.
--     `keys.cA` in the GUI would be `keys.ca` in the terminal and similarly,
--     `keys.caA` would be `keys.caa`).
--   * No modifiers are recognized for the function keys (e.g. F1-F12).
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:        g~~   ~             ^]
-- cm:  bcd  g~~ k ~  pq  t v xyz
-- m:          e          J            qQ  sS  u vVw xXyYzZ*
-- Note: m[befhstv] may be used by GUI terminals.
--
-- CTRL = 'c' (Control ^)
-- ALT = [unused]
-- META = 'm' (Alt)
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Control, Meta, and 'a' = 'cma'

-- File.
keys[not OSX and (not NCURSES and 'cn' or 'cmn') or 'mn'] = new_buffer
keys[not OSX and 'co' or 'mo'] = io.open_file
keys[not OSX and not NCURSES and 'cao' or 'cmo'] = io.open_recent_file
keys[not OSX and (not NCURSES and 'cO' or 'mo') or 'mO'] = buffer.reload
keys[not OSX and 'cs' or 'ms'] = buffer.save
keys[not OSX and (not NCURSES and 'cS' or 'cms') or 'mS'] = buffer.save_as
keys[not OSX and 'cw' or 'mw'] = buffer.close
keys[not OSX and (not NCURSES and 'cW' or 'cmw') or 'mW'] = io.close_all
-- TODO: m_textadept.sessions.load
-- TODO: m_textadept.sessions.save
keys[not OSX and 'cq' or 'mq'] = quit

-- Edit.
keys[not OSX and 'cz' or 'mz'] = buffer.undo
if not OSX then keys.cy = buffer.redo end
if not NCURSES then keys[not OSX and 'cZ' or 'mZ'] = buffer.redo end
keys[not OSX and 'cx' or 'mx'] = buffer.cut
keys[not OSX and 'cc' or 'mc'] = buffer.copy
keys[not OSX and 'cv' or 'mv'] = buffer.paste
if not NCURSES then keys[not OSX and 'cd' or 'md'] = buffer.line_duplicate end
keys.del = buffer.clear
keys[not OSX and (not NCURSES and 'adel' or 'mdel')
             or 'cdel'] = utils.delete_word
keys[not OSX and not NCURSES and 'ca' or 'ma'] = buffer.select_all
keys[not NCURSES and 'cm' or 'mm'] = m_editing.match_brace
keys[not OSX and (not NCURSES and 'c\n' or 'cmj')
             or 'cesc'] = { m_editing.autocomplete_word, '%w_' }
if not NCURSES then
  keys[not OSX and 'caH' or 'mH'] = m_editing.highlight_word
end
keys[not OSX and not NCURSES and 'c/' or 'm/'] = m_editing.block_comment
keys.ct = m_editing.transpose_chars
keys[not OSX and (not NCURSES and 'cJ' or 'mj') or 'cj'] = m_editing.join_lines
-- Select.
keys[not NCURSES and 'cM' or 'mM'] = { m_editing.match_brace, 'select' }
keys[not OSX and not NCURSES and 'c<'
                             or 'm<'] = { m_editing.select_enclosed, '>', '<' }
if not NCURSES then
  keys[not OSX and 'c>' or 'm>'] = { m_editing.select_enclosed, '<', '>' }
end
keys[not OSX and not NCURSES and "c'"
                             or "m'"] = { m_editing.select_enclosed, "'", "'" }
keys[not OSX and not NCURSES and 'c"'
                             or 'm"'] = { m_editing.select_enclosed, '"', '"' }
keys[not OSX and not NCURSES and 'c('
                             or 'm('] = { m_editing.select_enclosed, '(', ')' }
keys[not OSX and not NCURSES and 'c['
                             or 'm['] = { m_editing.select_enclosed, '[', ']' }
keys[not OSX and not NCURSES and 'c{'
                             or 'm{'] = { m_editing.select_enclosed, '{', '}' }
keys[not OSX and (not NCURSES and 'cD' or 'mW') or 'mD'] = m_editing.select_word
keys[not OSX and not NCURSES and 'cN' or 'mN'] = m_editing.select_line
keys[not OSX and not NCURSES and 'cP' or 'mP'] = m_editing.select_paragraph
keys[not OSX and not NCURSES and 'cI' or 'mI'] = m_editing.select_indented_block
-- Selection.
keys[not OSX and 'cau' or 'cu'] = buffer.upper_case
keys[not OSX and (not NCURSES and 'caU' or 'cml') or 'cU'] = buffer.lower_case
keys[not OSX and (not NCURSES and 'a<' or 'm>')
             or 'c<'] = utils.enclose_as_xml_tags
if not NCURSES then
  keys[not OSX and 'a>' or 'c>'] = { m_editing.enclose, '<', ' />' }
  keys[not OSX and "a'" or "c'"] = { m_editing.enclose, "'", "'" }
  keys[not OSX and 'a"' or 'c"'] = { m_editing.enclose, '"', '"' }
end
keys[not OSX and (not NCURSES and 'a(' or 'm)')
             or 'c('] = { m_editing.enclose, '(', ')' }
keys[not OSX and (not NCURSES and 'a[' or 'm]')
             or 'c['] = { m_editing.enclose, '[', ']' }
keys[not OSX and (not NCURSES and 'a{' or 'm}')
             or 'c{'] = { m_editing.enclose, '{', '}' }
keys[not OSX and not NCURSES and 'c+' or 'm+'] = { m_editing.grow_selection, 1 }
keys[not OSX and not NCURSES and 'c_'
                             or 'm_'] = { m_editing.grow_selection, -1 }
keys.csup = buffer.move_selected_lines_up
keys.csdown = buffer.move_selected_lines_down

-- Search.
keys[not OSX and not NCURSES and 'cf' or 'mf'] = gui_find.focus
if NCURSES then keys.mF = keys.mf end -- in case mf is used by GUI terminals
keys[not OSX and not NCURSES and 'cg' or 'mg'] = gui_find.find_next
if not OSX and not NCURSES then keys.f3 = keys.cg end
keys[not OSX and not NCURSES and 'cG' or 'mG'] = gui_find.find_prev
if not OSX and not NCURSES then keys.sf3 = keys.cG end
keys[not OSX and (not NCURSES and 'car' or 'mr') or 'cr'] = gui_find.replace
keys[not OSX and (not NCURSES and 'caR' or 'mR') or 'cR'] = gui_find.replace_all
-- Find Next is an when find pane is focused in GUI.
-- Find Prev is ap when find pane is focused in GUI.
-- Replace is ar when find pane is focused in GUI.
-- Replace All is aa when find pane is focused in GUI.
keys[not OSX and not NCURSES and 'caf' or 'cmf'] = gui_find.find_incremental
if not NCURSES then keys[not OSX and 'cF' or 'mF'] = utils.find_in_files end
-- Find in Files is ai when find pane is focused in GUI.
if not NCURSES then
  keys[not OSX and 'cag' or 'cmg'] = { gui_find.goto_file_in_list, true }
  keys[not OSX and 'caG' or 'cmG'] = { gui_find.goto_file_in_list, false }
end
keys[not OSX and 'cj' or 'mj'] = m_editing.goto_line

-- Tools.
keys[not OSX and (not NCURSES and 'ce' or 'mc')
             or 'me'] = gui.command_entry.focus
keys[not OSX and (not NCURSES and 'cE' or 'mC')
             or 'mE'] = utils.select_command
keys[not OSX and 'cr' or 'mr'] = m_textadept.run.run
keys[not OSX and (not NCURSES and 'cR' or 'cmr')
             or 'mR'] = m_textadept.run.compile
keys[not OSX and (not NCURSES and 'c|' or 'c\\')
             or 'm|'] = m_textadept.filter_through.filter_through
-- Adeptsense.
keys[not OSX and (not NCURSES and 'c ' or 'c@')
             or 'aesc'] = m_textadept.adeptsense.complete_symbol
keys[not NCURSES and 'ch' or 'mh'] = m_textadept.adeptsense.show_documentation
if NCURSES then keys.mH = keys.mh end -- in case mh is used by GUI terminals
-- Snippets.
keys[not OSX and (not NCURSES and 'ck' or 'mk') or 'a\t'] = m_snippets._select
keys['\t'] = m_snippets._insert
keys['s\t'] = m_snippets._previous
keys[not OSX and (not NCURSES and 'cK' or 'mK')
             or 'as\t'] = m_snippets._cancel_current
if not NCURSES then
  -- Bookmark.
  keys[not OSX and 'cf2' or 'mf2'] = m_bookmarks.toggle
  keys[not OSX and 'csf2' or 'msf2'] = m_bookmarks.clear
  keys.f2 = m_bookmarks.goto_next
  keys.sf2 = m_bookmarks.goto_prev
  keys.af2 = m_bookmarks.goto_bookmark
end
-- Snapopen.
keys[not OSX and 'cu' or 'mu'] = { m_textadept.snapopen.open, _USERHOME }
-- TODO: { m_textadept.snapopen.open, _HOME }
keys[not OSX and (not NCURSES and 'caO' or 'mO')
             or 'cmO'] = utils.snapopen_filedir
if not NCURSES then keys[not OSX and 'ci' or 'mi'] = utils.show_style end

-- Buffer.
keys[not NCURSES and 'c\t' or 'mn'] = { view.goto_buffer, view, 1, true }
keys[not NCURSES and 'cs\t' or 'mp'] = { view.goto_buffer, view, -1, true }
keys[not OSX and not NCURSES and 'cb' or 'mb'] = gui.switch_buffer
if NCURSES then keys.mB = keys.mb end -- in case mb is used by GUI terminals
-- Indentation.
-- TODO: { utils.set_indentation, 2 }
-- TODO: { utils.set_indentation, 3 }
-- TODO: { utils.set_indentation, 4 }
-- TODO: { utils.set_indentation, 8 }
keys[not OSX and (not NCURSES and 'caT' or 'mt')
             or 'cT'] = { utils.toggle_property, 'use_tabs' }
if NCURSES then keys.mT = keys.mt end -- in case mt is used by GUI terminals
keys[not OSX and (not NCURSES and 'cai' or 'mi')
             or 'ci'] = m_editing.convert_indentation
-- EOL Mode.
-- TODO: { utils.set_eol_mode, c.SC_EOL_CRLF }
-- TODO: { utils.set_eol_mode, c.SC_EOL_CR }
-- TODO: { utils.set_eol_mode, c.SC_EOL_LF }
-- Encoding.
-- TODO: { utils.set_encoding, 'UTF-8' }
-- TODO: { utils.set_encoding, 'ASCII' }
-- TODO: { utils.set_encoding, 'ISO-8859-1' }
-- TODO: { utils.set_encoding, 'MacRoman' }
-- TODO: { utils.set_encoding, 'UTF-16LE' }
keys[not OSX and not NCURSES and 'cL'
                             or 'mL'] = m_textadept.mime_types.select_lexer
keys.f5 = { buffer.colourise, buffer, 0, -1 }
if NCURSES then keys.cl = keys.f5 end

-- View.
if not NCURSES then
  keys[not OSX and 'can' or 'ca\t'] = { gui.goto_view, 1, true }
  keys[not OSX and 'cap' or 'cas\t'] = { gui.goto_view, -1, true }
  keys[not OSX and 'cas' or 'cs'] = { view.split, view }
  if not OSX then keys.cah = keys.cas end
  keys[not OSX and 'cav' or 'cv'] = { view.split, view, true }
  keys[not OSX and 'caw' or 'cw'] = { view.unsplit, view }
  keys[not OSX and 'caW' or 'cW'] = utils.unsplit_all
  keys[not OSX and 'ca+' or 'c+'] = { utils.grow, 10 }
  keys[not OSX and 'ca=' or 'c='] = { utils.grow, 10 }
  keys[not OSX and 'ca-' or 'c-'] = { utils.shrink, 10 }
end
-- TODO: utils.toggle_current_fold
if not NCURSES then
  keys[not OSX and 'ca\n' or 'c\n'] = { utils.toggle_property, 'view_eol' }
  if not OSX then keys['ca\n\r'] = keys['ca\n'] end
  keys[not OSX and 'ca\\' or 'c\\'] = { utils.toggle_property, 'wrap_mode' }
  keys[not OSX and 'caI' or 'cI'] =
    { utils.toggle_property, 'indentation_guides' }
  keys[not OSX and 'caS' or 'cS'] = { utils.toggle_property, 'view_ws' }
  keys[not OSX and 'caV' or 'cV'] =
    { utils.toggle_property, 'virtual_space_options', c.SCVS_USERACCESSIBLE }
end
keys[not OSX and not NCURSES and 'c=' or 'm='] = buffer.zoom_in
keys[not OSX and not NCURSES and 'c-' or 'm-'] = buffer.zoom_out
keys[not OSX and not NCURSES and 'c0' or 'm0'] = utils.reset_zoom
if not NCURSES then keys[not OSX and 'cT' or 'mT'] = gui.select_theme end

-- Help.
if not NCURSES then
  keys.f1 = { utils.open_webpage, _HOME..'/doc/01_Introduction.html' }
  keys.sf1 = { utils.open_webpage, _HOME..'/doc/api/index.html' }
end
-- TODO: { gui.dialog, 'ok-msgbox', '--title', 'Textadept'
--         '--informative-text', _RELEASE, '--button1', _L['_OK'],
--         '--no-cancel' }

-- Movement commands.
if OSX or NCURSES then
  keys.ck = function()
    _G.buffer:line_end_extend()
    _G.buffer:cut()
  end
  keys.cf = buffer.char_right
  keys.cb = buffer.char_left
  keys.cn = buffer.line_down
  keys.cp = buffer.line_up
  keys.ca = buffer.vc_home
  keys.ce = buffer.line_end
  keys[OSX and 'cA' or 'mA'] = buffer.vc_home_extend
  keys[OSX and 'cE' or 'mE'] = buffer.line_end_extend
  keys.cd = buffer.clear
  if OSX then
    keys.cF = buffer.char_right_extend
    keys.cmf = buffer.word_right
    keys.cmF = buffer.word_right_extend
    keys.cB = buffer.char_left_extend
    keys.cmb = buffer.word_left
    keys.cmB = buffer.word_left_extend
    keys.cN = buffer.line_down_extend
    keys.cP = buffer.line_up_extend
    keys.cl = buffer.vertical_centre_caret
    keys.aright = buffer.word_right
    keys.aleft = buffer.word_left
  else
    keys.md = utils.delete_word
    keys.cma = buffer.document_start
    keys.cme = buffer.document_end
    keys.mU = buffer.page_up_extend
    keys.mD = buffer.page_down_extend
  end
  -- GTKOSX reports Fn-key as a single keycode which confuses Scintilla. Do not
  -- propagate it.
  keys.fn = function() return true end
end

return M

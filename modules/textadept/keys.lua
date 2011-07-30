-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize
local gui = gui

---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors.
-- This module, should be 'require'ed last, but before _m.textadept.menu.
module('_m.textadept.keys', package.seeall)

local keys, _buffer, _view = keys, buffer, view
local m_textadept, m_editing = _m.textadept, _m.textadept.editing
local c, OSX = _SCINTILLA.constants, OSX

-- Utility functions.
utils = {
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
      if os.execute(cmd) ~= 0 then error(L('Error loading webpage:')..url) end
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
-- Scintilla's first buffer doesn't have this.
if not RESETTING then constantize_menu_buffer_functions() end

--[[
  Windows and Linux menu key commands.

  Unassigned keys (~ denotes keys reserved by the operating system):
  c:   A B C         H           N  p qQ     T ~ V   X Y      ) ] }  *      \n
  a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpP QrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=~~\n\s
  ca: aAbBcCdDeE F  h   jJkK LmMnN  pPqQ    t   v   xXy zZ_"'()[]{}<>*  /

  CTRL = 'c' (Control ^)
  ALT = 'a' (Alt)
  META = [unused]
  SHIFT = 's' (Shift ⇧)
  ADD = ''
  Control, Alt, Shift, and 'a' = 'caA'
  Control, Alt, Shift, and '\t' = 'cas\t'

  Mac OSX menu key commands.

  Unassigned keys (~ denotes keys reserved by the operating system):
  c:   A B C        ~    JkK  ~M N  p  ~    tT U V   Xy       ) ] }  *    ~~\n~~
  ca: aAbBcC~DeE F  ~HiIjJkK L~MnN  pPq~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=  \n~~
  m:      cC D    gG H  J K L    oO  qQ         v   xXyYzZ_   ) ] }  *  /

  CTRL = 'c' (Command ⌘)
  ALT = 'a' (Alt/option ⌥)
  META = 'm' (Control ^)
  SHIFT = 's' (Shift ⇧)
  ADD = ''
  Command, Alt, Shift, and 'a' = 'caA'
  Command, Alt, Shift, and '\t' = 'cas\t'
]]--

-- File.
keys.cn = new_buffer
keys.co = io.open_file
keys.cao = io.open_recent_file
keys.cO = _buffer.reload
keys.cs = _buffer.save
keys.cS = _buffer.save_as
keys.cw = _buffer.close
keys.cW = io.close_all
-- TODO: m_textadept.sessions.prompt_load
-- TODO: m_textadept.sessions.prompt_save
keys[not OSX and 'aq' or 'cq'] = quit

-- Edit.
keys.cz = _buffer.undo
if not OSX then keys.cy = _buffer.redo end
keys.cZ = _buffer.redo
keys.cx = _buffer.cut
keys.cc = _buffer.copy
keys.cv = _buffer.paste
keys.cd = _buffer.line_duplicate
keys.del = _buffer.clear
keys.ca = _buffer.select_all
keys[not OSX and 'cm' or 'mm'] = m_editing.match_brace
keys[not OSX and 'c\n' or 'mesc'] = { m_editing.autocomplete_word, '%w_' }
keys[not OSX and 'adel' or 'mdel'] = { m_editing.current_word, 'delete' }
keys[not OSX and 'caH' or 'cH'] = m_editing.highlight_word
keys['c/'] = m_editing.block_comment
keys[not OSX and 'ct' or 'mt'] = m_editing.transpose_chars
keys[not OSX and 'cJ' or 'mj'] = m_editing.join_lines
-- Select.
keys[not OSX and 'cM' or 'mM'] = { m_editing.match_brace, 'select' }
keys['c<'] = { m_editing.select_enclosed, '>', '<' }
keys['c>'] = { m_editing.select_enclosed, '<', '>' }
keys["c'"] = { m_editing.select_enclosed, "'", "'" }
keys['c"'] = { m_editing.select_enclosed, '"', '"' }
keys['c('] = { m_editing.select_enclosed, '(', ')' }
keys['c['] = { m_editing.select_enclosed, '[', ']' }
keys['c{'] = { m_editing.select_enclosed, '{', '}' }
keys.cD = { m_editing.current_word, 'select' }
keys.cL = m_editing.select_line
keys.cP = m_editing.select_paragraph
keys.cI = m_editing.select_indented_block
keys.cY = m_editing.select_style
-- Selection.
keys[not OSX and 'cau' or 'mu'] = _buffer.upper_case
keys[not OSX and 'caU' or 'mU'] = _buffer.lower_case
keys[not OSX and 'a<' or 'm<'] = utils.enclose_as_xml_tags
keys[not OSX and 'a>' or 'm>'] = { m_editing.enclose, '<', ' />' }
keys[not OSX and "a'" or "m'"] = { m_editing.enclose, "'", "'" }
keys[not OSX and 'a"' or 'm"'] = { m_editing.enclose, '"', '"' }
keys[not OSX and 'a(' or 'm('] = { m_editing.enclose, '(', ')' }
keys[not OSX and 'a[' or 'm['] = { m_editing.enclose, '[', ']' }
keys[not OSX and 'a{' or 'm{'] = { m_editing.enclose, '{', '}' }
keys['c+'] = { m_editing.grow_selection, 1 }
keys['c_'] = { m_editing.grow_selection, -1 }
keys[not OSX and 'csup' or 'msup'] = _buffer.move_selected_lines_up
keys[not OSX and 'csdown' or 'msdown'] = _buffer.move_selected_lines_down

-- Search.
keys.cf = gui.find.focus
keys.cg = gui.find.find_next
if not OSX then keys.f3 = keys.cg end
keys.cG = gui.find.find_prev
if not OSX then keys.sf3 = keys.cG end
keys.cr = gui.find.replace
keys.cR = gui.find.replace_all
keys.caf = gui.find.find_incremental
keys.cF = utils.find_in_files
keys.cag = { gui.find.goto_file_in_list, true }
keys.caG = { gui.find.goto_file_in_list, false }
keys.cj = m_editing.goto_line

-- Tools.
keys.ce = gui.command_entry.focus
keys.cE = utils.select_command
keys[not OSX and 'car' or 'mr'] = m_textadept.run.run
keys[not OSX and 'caR' or 'mR'] = m_textadept.run.compile
keys['c|'] = m_textadept.filter_through.filter_through
-- Adeptsense.
keys[not OSX and 'c ' or 'aesc'] = m_textadept.adeptsense.complete_symbol
keys[not OSX and 'ch' or 'mh'] = m_textadept.adeptsense.show_documentation
-- Snippets.
keys[not OSX and 'ck' or 'a\t'] = m_textadept.snippets._select
keys['\t'] = m_textadept.snippets._insert
keys['s\t'] = m_textadept.snippets._previous
keys[not OSX and 'cK' or 'as\t'] = m_textadept.snippets._cancel_current
-- Bookmark.
keys.cf2 = m_textadept.bookmarks.toggle
keys.csf2 = m_textadept.bookmarks.clear
keys.f2 = m_textadept.bookmarks.goto_next
keys.sf2 = m_textadept.bookmarks.goto_prev
keys.af2 = m_textadept.bookmarks.goto
-- Snapopen.
keys.cu = { m_textadept.snapopen.open, _USERHOME }
-- TODO: { m_textadept.snapopen.open, _HOME }
keys.caO = utils.snapopen_filedir
keys.ci = utils.show_style

-- Buffer.
keys[not OSX and 'c\t' or 'm`'] = { _view.goto_buffer, _view, 1, false }
keys[not OSX and 'cs\t' or 'm~'] = { _view.goto_buffer, _view, -1, false }
keys.cb = gui.switch_buffer
-- Indentation.
-- TODO: { utils.set_indentation, 2 }
-- TODO: { utils.set_indentation, 3 }
-- TODO: { utils.set_indentation, 4 }
-- TODO: { utils.set_indentation, 8 }
keys[not OSX and 'caT' or 'mT'] = { utils.toggle_property, 'use_tabs' }
keys[not OSX and 'cai' or 'mi'] = m_editing.convert_indentation
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
keys.cal = m_textadept.mime_types.select_lexer
keys.f5 = { _buffer.colourise, _buffer, 0, -1 }

-- View.
keys[not OSX and 'ca\t' or 'm\t'] = { gui.goto_view, 1, false }
keys[not OSX and 'cas\t' or 'ms\t'] = { gui.goto_view, -1, false }
keys[not OSX and 'caS' or 'mS'] = { _view.split, _view }
keys[not OSX and 'cas' or 'ms'] = { _view.split, _view, false }
keys[not OSX and 'caw' or 'mw'] = { _view.unsplit, _view }
keys[not OSX and 'caW' or 'mW'] = utils.unsplit_all
keys[not OSX and 'ca+' or 'm+'] = { utils.grow, 10 }
keys[not OSX and 'ca=' or 'm='] = { utils.grow, 10 }
keys[not OSX and 'ca-' or 'm-'] = { utils.shrink, 10 }
-- TODO: utils.toggle_current_fold
keys[not OSX and 'ca\n' or 'm\n'] = { utils.toggle_property, 'view_eol' }
if not OSX then keys['ca\n\r'] = keys['ca\n'] end
keys[not OSX and 'ca\\' or 'm\\'] = { utils.toggle_property, 'wrap_mode' }
keys[not OSX and 'caI' or 'mI'] =
  { utils.toggle_property, 'indentation_guides' }
keys[not OSX and 'ca ' or 'm '] = { utils.toggle_property, 'view_ws' }
keys[not OSX and 'caV' or 'mV'] =
  { utils.toggle_property, 'virtual_space_options', c.SCVS_USERACCESSIBLE }
keys['c='] = _buffer.zoom_in
keys['c-'] = _buffer.zoom_out
keys.c0 = utils.reset_zoom

-- Help.
keys.f1 = { utils.open_webpage, _HOME..'/doc/manual/1_Introduction.html' }
keys.sf1 = { utils.open_webpage, _HOME..'/doc/index.html' }
-- TODO: { gui.dialog, 'ok-msgbox', '--title', 'Textadept'
--         '--informative-text', _RELEASE, '--no-cancel' }

-- Movement commands.
if OSX then
  keys.mk = function()
    buffer:line_end_extend()
    buffer:cut()
  end
  keys.mf = _buffer.char_right
  keys.mF = _buffer.char_right_extend
  keys.amf = _buffer.word_right
  keys.amF = _buffer.word_right_extend
  keys.mb = _buffer.char_left
  keys.mB = _buffer.char_left_extend
  keys.amb = _buffer.word_left
  keys.amB = _buffer.word_left_extend
  keys.mn = _buffer.line_down
  keys.mN = _buffer.line_down_extend
  keys.mp = _buffer.line_up
  keys.mP = _buffer.line_up_extend
  keys.ma = _buffer.vc_home
  keys.mA = _buffer.vc_home_extend
  keys.me = _buffer.line_end
  keys.mE = _buffer.line_end_extend
  keys.md = _buffer.clear
  keys.ml = _buffer.vertical_centre_caret
end

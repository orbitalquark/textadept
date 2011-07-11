-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize

---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors.
module('_m.textadept.keys', package.seeall)

local keys = keys
local _buffer, _view = buffer, view
local gui, m_textadept = gui, _m.textadept

-- Utility functions used by both layouts.
local function enclose_in_tag()
  m_editing.enclose('<', '>')
  local buffer = buffer
  local pos = buffer.current_pos
  while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
  buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
end
local function any_char_mt(f)
  return setmetatable({['\0'] = {}}, {
                        __index = function(t, k)
                          if #k == 1 then return { f, k, k } end
                        end })
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
local function show_style()
  local buffer = buffer
  local style = buffer.style_at[buffer.current_pos]
  local text = string.format("%s %s\n%s %s (%d)", L('Lexer'),
                             buffer:get_lexer(), L('Style'),
                             buffer:get_style_name(style), style)
  buffer:call_tip_show(buffer.current_pos, text)
end

-- CTRL = 'c'
-- SHIFT = 's'
-- ALT = 'a'
-- ADD = ''
-- Control, Shift, Alt, and 'a' = 'caA'
-- Control, Shift, Alt, and '\t' = 'csa\t'

if not OSX then
  -- Windows and Linux key commands.

  --[[
    C:         D           J K   M             T U
    A:   A B   D E F G H   J K L M N   P       T U V W X Y Z
    CS:  A   C D     G   I J K L M N O   Q     T U V   X Y Z
    SA:  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    CA:  A B C D E F G H   J K L M N O   Q R S T U   W X Y Z
    CSA: A B C D E F G H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'esc'

  -- File
  keys.cn = new_buffer
  keys.co = io.open_file
  -- TODO: { _buffer.reload, _buffer }
  keys.cs = { _buffer.save, _buffer }
  keys.cS = { _buffer.save_as, _buffer }
  keys.cw = { _buffer.close, _buffer }
  keys.cW = io.close_all
  -- TODO: m_textadept.session.load after prompting with open dialog
  -- TODO: m_textadept.session.save after prompting with save dialog
  keys.aq = quit

  -- Edit
  local m_editing = m_textadept.editing
  keys.cz = { _buffer.undo, _buffer }
  keys.cy = { _buffer.redo, _buffer }
  keys.cx = { _buffer.cut, _buffer }
  keys.cc = { _buffer.copy, _buffer }
  keys.cv = { _buffer.paste, _buffer }
  -- Delete is delete.
  keys.ca = { _buffer.select_all, _buffer }
  keys.ce = m_editing.match_brace
  keys.cE = { m_editing.match_brace, 'select' }
  keys['c\n'] = { m_editing.autocomplete_word, '%w_' }
  keys['c\n\r'] = { m_editing.autocomplete_word, '%w_' } -- win32
  keys.cq = m_editing.block_comment
  -- TODO: { m_editing.current_word, 'delete' }
  keys.cH = m_editing.highlight_word
  -- TODO: m_editing.transpose_chars
  -- TODO: m_editing.convert_indentation
  keys.ac = { -- enClose in...
    t = enclose_in_tag,
    T = { m_editing.enclose, '<', ' />' },
    ['"'] = { m_editing.enclose, '"', '"' },
    ["'"] = { m_editing.enclose, "'", "'" },
    ['('] = { m_editing.enclose, '(', ')' },
    ['['] = { m_editing.enclose, '[', ']' },
    ['{'] = { m_editing.enclose, '{', '}' },
    c     = any_char_mt(m_editing.enclose),
  }
  keys.as = { -- select in...
    t  = { m_editing.select_enclosed, '>', '<' },
    ['"'] = { m_editing.select_enclosed, '"', '"' },
    ["'"] = { m_editing.select_enclosed, "'", "'" },
    ['('] = { m_editing.select_enclosed, '(', ')' },
    ['['] = { m_editing.select_enclosed, '[', ']' },
    ['{'] = { m_editing.select_enclosed, '{', '}' },
    w = { m_editing.current_word, 'select' },
    l = m_editing.select_line,
    p = m_editing.select_paragraph,
    b = m_editing.select_indented_block,
    s = m_editing.select_scope,
    g = { m_editing.grow_selection, 1 },
    c = any_char_mt(m_editing.select_enclosed),
  }

  -- Search
  keys.cf = gui.find.focus -- find/replace
  keys['f3'] = gui.find.find_next
  -- Find Next is an when find pane is focused.
  -- Find Prev is ap when find pane is focused.
  -- Replace is ar when find pane is focused.
  keys.cF = gui.find.find_incremental
  -- Find in Files is ai when find pane is focused.
  -- TODO: { gui.find.goto_file_in_list, true }
  -- TODO: { gui.find.goto_file_in_list, false }
  keys.cg = m_editing.goto_line

  -- Tools
  keys['f2'] = gui.command_entry.focus
  -- Run
  keys.cr = m_textadept.run.run
  keys.cR = m_textadept.run.compile
  keys.ar = m_textadept.filter_through.filter_through
  -- Snippets
  keys['\t'] = m_textadept.snippets._insert
  keys['s\t'] = m_textadept.snippets._previous
  keys.cai = m_textadept.snippets._cancel_current
  keys.ai = m_textadept.snippets._select

  -- Buffers
  keys.cb = gui.switch_buffer
  keys['c\t'] = { _view.goto_buffer, _view, 1, false  }
  keys['cs\t'] = { _view.goto_buffer, _view, -1, false }
  keys.cB = {
    e = { toggle_setting, 'view_eol' },
    w = { toggle_setting, 'wrap_mode' },
    i = { toggle_setting, 'indentation_guides' },
    ['\t'] = { toggle_setting, 'use_tabs' },
    [' '] = { toggle_setting, 'view_ws' },
    v = { toggle_setting, 'virtual_space_options', 2 },
  }
  keys.cl = m_textadept.mime_types.select_lexer
  keys['f5'] = { _buffer.colourise, _buffer, 0, -1 }

  -- Views
  keys.cav = {
    n = { gui.goto_view, 1, false },
    p = { gui.goto_view, -1, false },
    S = { _view.split, _view }, -- vertical
    s = { _view.split, _view, false }, -- horizontal
    w = function() view:unsplit() return true end,
    W = function() while view:unsplit() do end end,
    -- TODO: function() view.size = view.size + 10 end
    -- TODO: function() view.size = view.size - 10 end
  }
  keys.c0 = function() buffer.zoom = 0 end

  -- Miscellaneous not in standard menu.
  keys.ao = io.open_recent_file
  keys.caI = show_style

else
  -- Mac OSX key commands

  --[[
    C:                     J     M               U   W X   Z
    A:         D E     H   J K L               T U       Y
    CS:      C D     G H I J K L M   O   Q   S T U V W X Y Z
    SA:  A   C D       H I J K L M N O   Q R   T U V   X Y
    CA:  A   C   E         J K L M N O   Q   S   U V W X Y Z
    CSA: A   C D E     H   J K L M N O P Q R S T U V W X Y Z
  ]]--

  keys.clear_sequence = 'aesc'

  -- File
  keys.an = new_buffer
  keys.ao = io.open_file
  -- TODO: { _buffer.reload, _buffer }
  keys.as = { _buffer.save, _buffer }
  keys.aS = { _buffer.save_as, _buffer }
  keys.aw = { _buffer.close, _buffer }
  keys.aW = { io.close_all }
  -- TODO: m_textadept.session.load after prompting with open dialog
  -- TODO: m_textadept.session.save after prompting with save dialog
  keys.aq = quit

  -- Edit
  local m_editing = m_textadept.editing
  keys.az = { _buffer.undo, _buffer }
  keys.aZ = { _buffer.redo, _buffer }
  keys.ax = { _buffer.cut, _buffer }
  keys.ac = { _buffer.copy, _buffer }
  keys.av = { _buffer.paste, _buffer }
  -- Delete is delete.
  keys.aa  = { _buffer.select_all, _buffer }
  keys.cm  = m_editing.match_brace
  keys.aE  = { m_editing.match_brace, 'select' }
  keys.esc = { m_editing.autocomplete_word, '%w_' }
  keys.cq  = m_editing.block_comment
  -- TODO: { m_editing.current_word, 'delete' }
  keys.cat = m_editing.highlight_word
  keys.ct = m_editing.transpose_chars
  -- TODO: m_editing.convert_indentation
  keys.cc = { -- enClose in...
    t = enclose_in_tag,
    T = { m_editing.enclose, '<', ' />' },
    ['"'] = { m_editing.enclose, '"', '"' },
    ["'"] = { m_editing.enclose, "'", "'" },
    ['('] = { m_editing.enclose, '(', ')' },
    ['['] = { m_editing.enclose, '[', ']' },
    ['{'] = { m_editing.enclose, '{', '}' },
    c = any_char_mt(m_editing.enclose),
  }
  keys.cs = { -- select in...
    t = { m_editing.select_enclosed, '>', '<' },
    ['"'] = { m_editing.select_enclosed, '"', '"' },
    ["'"] = { m_editing.select_enclosed, "'", "'" },
    ['('] = { m_editing.select_enclosed, '(', ')' },
    ['['] = { m_editing.select_enclosed, '[', ']' },
    ['{'] = { m_editing.select_enclosed, '{', '}' },
    w = { m_editing.current_word, 'select' },
    l = m_editing.select_line,
    p = m_editing.select_paragraph,
    b = m_editing.select_indented_block,
    s = m_editing.select_scope,
    g = { m_editing.grow_selection, 1 },
    c = any_char_mt(m_editing.select_enclosed),
  }

  -- Search
  keys.af = gui.find.focus -- find/replace
  keys.ag = gui.find.find_next
  keys.aG = gui.find.find_prev
  keys.ar = gui.find.replace
  keys.ai = gui.find.find_incremental
  keys.aF = function()
    gui.find.in_files = true
    gui.find.focus()
  end
  keys.cag = { gui.find.goto_file_in_list, true }
  keys.caG = { gui.find.goto_file_in_list, false }
  keys.cg  = m_editing.goto_line

  -- Tools
  keys['f2'] = gui.command_entry.focus
  -- Run
  keys.cr = { m_textadept.run.run }
  keys.cR = { m_textadept.run.compile }
  keys.car = { m_textadept.filter_through.filter_through }
  -- Snippets
  keys['\t'] = m_textadept.snippets._insert
  keys['s\t'] = m_textadept.snippets._previous
  keys.cai = m_textadept.snippets._cancel_current
  keys.ci = m_textadept.snippets._select

  -- Buffers
  keys.ab = gui.switch_buffer
  keys['c\t'] = { _view.goto_buffer, _view, 1, false }
  keys['cs\t'] = { _view.goto_buffer, _view, -1, false }
  keys.aB = {
    e = { toggle_setting, 'view_eol' },
    w = { toggle_setting, 'wrap_mode' },
    i = { toggle_setting, 'indentation_guides' },
    ['\t'] = { toggle_setting, 'use_tabs' },
    [' '] = { toggle_setting, 'view_ws' },
    v = { toggle_setting, 'virtual_space_options', 2 },
  }
  keys.cl = m_textadept.mime_types.select_lexer
  keys['f5'] = { _buffer.colourise, _buffer, 0, -1 }

  -- Views
  keys.cv = {
    n = { gui.goto_view, 1, false },
    p = { gui.goto_view, -1, false },
    S = { _view.split, _view }, -- vertical
    s = { _view.split, _view, false }, -- horizontal
    w = function() view:unsplit() return true end,
    W = function() while view:unsplit() do end end,
    -- TODO: function() view.size = view.size + 10 end
    -- TODO: function() view.size = view.size - 10 end
  }
  keys.c0 = function() buffer.zoom = 0 end

  -- Miscellaneous not in standard menu.
  keys.co = io.open_recent_file
  keys.caI = show_style

  -- Movement/selection commands
  keys.cf = { _buffer.char_right, _buffer }
  keys.cF = { _buffer.char_right_extend, _buffer }
  keys.caf = { _buffer.word_right, _buffer }
  keys.caF = { _buffer.word_right_extend, _buffer }
  keys.cb = { _buffer.char_left, _buffer }
  keys.cB = { _buffer.char_left_extend, _buffer }
  keys.cab = { _buffer.word_left, _buffer }
  keys.caB = { _buffer.word_left_extend, _buffer }
  keys.cn = { _buffer.line_down, _buffer }
  keys.cN = { _buffer.line_down_extend, _buffer }
  keys.cp = { _buffer.line_up, _buffer }
  keys.cP = { _buffer.line_up_extend, _buffer }
  keys.ca = { _buffer.vc_home, _buffer }
  keys.cA = { _buffer.home_extend, _buffer }
  keys.ce = { _buffer.line_end, _buffer }
  keys.cE = { _buffer.line_end_extend, _buffer }
  keys.cah = { _buffer.del_word_left, _buffer }
  keys.cd = { _buffer.clear, _buffer }
  keys.cad = { _buffer.del_word_right, _buffer }
  keys.ck = function()
    buffer:line_end_extend()
    buffer:cut()
  end
  keys.cy = { _buffer.paste, _buffer }
end

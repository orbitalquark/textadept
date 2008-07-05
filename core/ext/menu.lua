-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Provides dynamic menus for Textadept.
module('textadept.menu', package.seeall)

local t, gtkmenu = textadept, textadept.gtkmenu

t.menubar = {
  gtkmenu {
    title = '_File',
    'gtk-new',
    'gtk-open',
    '_Reload',
    'gtk-save',
    'gtk-save-as',
    'gtk-close',
    'Close _All',
    'separator',
    '_Load Session...',
    'Sa_ve Session...',
    'separator',
    'gtk-quit',
  },
  gtkmenu {
    title = '_Edit',
    'gtk-undo',
    'gtk-redo',
    'separator',
    'gtk-cut',
    'gtk-copy',
    'gtk-paste',
    'gtk-delete',
    'gtk-select-all',
    'separator',
    { title = '_Kill Ring',
      '_Cut to line end',
      'Co_py to line end',
      '_Paste from ring',
      'Paste _next from ring',
      'Paste pre_v from ring',
    },
    'Match _Brace',
    'Select t_o Brace',
    'Complete _Word',
    'De_lete Word',
    'Tran_spose Characters',
    'S_queeze',
    '_Move line up',
    'Mo_ve line down',
    'Convert _Indentation',
    { title = 'S_election',
      { title = 'E_xecute as...',
        '_Ruby',
        '_Lua',
      },
      { title = '_Enclose in...',
        '_HTML Tag',
        'HTML _Single Tag',
        '_Double Quotes',
        '_Single Quotes',
        '_Parentheses',
        '_Brackets',
        'B_races',
        '_Character Sequence',
      },
      '_Grow',
    },
    { title = 'Sele_ct in...',
      '_Structure',
      '_HTML Tag',
      '_Double Quote',
      '_Single Quote',
      'Parenthesis',
      'Bracket',
      'Brace',
      'Word',
      'Line',
      'Paragraph',
      'Indented Block',
      'Scope',
    },
  },
  gtkmenu {
    title = '_Search',
    'gtk-find',
    'Find _Next',
    'Find _Prev',
    'gtk-find-and-replace',
    'separator',
    'gtk-jump-to',
  },
  gtkmenu {
    title = '_Tools',
    { title = '_Snippets',
      '_Insert Snippet',
      '_Previous Placeholder',
      '_Cancel Snippet',
      '_List Snippets',
      '_Show Scope',
    },
    { title = '_Multiple Line Editing',
      '_Add Line',
      'Add _Multiple Lines',
      '_Remove Line',
      'R_emove Multiple Lines',
      '_Update Multiple Lines',
      '_Finished Editing',
    },
  },
  gtkmenu {
    title = '_Buffers',
    '_Next Buffer',
    '_Prev Buffer',
    'separator',
    'Toggle View _EOL',
    'Toggle _Wrap Mode',
    'Toggle Show _Indentation Guides',
    'Toggle Use _Tabs',
    'Toggle View White_space',
    'separator',
    '_Refresh Syntax Highlighting',
  },
  gtkmenu {
    title = '_Views',
    '_Next View',
    '_Prev View',
    'separator',
    'Split _Vertical',
    'Split _Horizontal',
    '_Unsplit',
    'Unsplit _All',
    'separator',
    '_Grow View',
    '_Shrink View',
  },
  gtkmenu {
    title = '_Project Manager',
    '_Toggle PM Visible',
    '_Focus PM',
    'Show PM _Buffers',
    'Show PM _Ctags',
    'Show PM _Macros',
  },
}

local b, v = 'buffer', 'view'
local m_snippets = _m.textadept.lsnippets
local m_editing = _m.textadept.editing
local m_mlines = _m.textadept.mlines

local function pm_activate(text) t.pm.entry_text = text t.pm.activate() end
local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  t.events.update_ui() -- for updating statusbar
end

local actions = {
  -- File
  New = { t.new_buffer },
  Open = { t.io.open },
  Reload = { 'reload', b },
  Save = { 'save', b },
  ['Save As...'] = { 'save_as', b },
  Close = { 'close', b },
  ['Close All'] = { t.io.close_all },
  ['Load Session...'] = { t.io.load_session }, -- TODO: file open dialog prompt
  ['Save Session...'] = { t.io.save_session }, -- TODO: file save dialog prompt
  Quit = {}, -- TODO: quit
  -- Edit
  Undo = { 'undo', b },
  Redo = { 'redo', b },
  Cut = { 'cut', b },
  Copy = { 'copy', b },
  Paste = { 'paste', b },
  Delete = { 'clear', b },
  ['Select All'] = { 'select_all', b },
  ['Cut to line end'] = { m_editing.smart_cutcopy },
  ['Copy to line end'] = { m_editing.smart_cutcopy, 'copy' },
  ['Paste from ring'] = { m_editing.smart_paste },
  ['Paste next from ring'] = { m_editing.smart_paste, 'cycle' },
  ['Paste prev from ring'] = { m_editing.smart_paste, 'reverse' },
  ['Match Brace'] = { m_editing.match_brace },
  ['Select to Brace'] = { m_editing.match_brace, 'select' },
  ['Complete Word'] = { m_editing.autocomplete_word, '%w_' },
  ['Delete Word'] = { m_editing.current_word, 'delete' },
  ['Transpose Chars'] = { m_editing.transpose_chars },
  ['Squeeze'] = { m_editing.squeeze },
  ['Join Lines'] = { m_editing.join_lines },
  ['Move line up'] = { m_editing.move_line, 'up' },
  ['Move line down'] = { m_editing.move_line, 'down' },
  ['Convert Indentation'] = { m_editing.convert_indentation },
  Ruby = { m_editing.ruby_exec },
  Lua = { m_editing.lua_exec },
  ['HTML Tag'] = { m_editing.enclose, 'tag' },
  ['HTML Single Tag'] = { m_editing.enclose, 'single_tag' },
  ['Double Quotes'] = { m_editing.enclose, 'dbl_quotes' },
  ['Single Quotes'] = { m_editing.enclose, 'sng_quotes' },
  Parentheses = { m_editing.enclose, 'parens' },
  Brackets = { m_editing.enclose, 'brackets' },
  Braces = { m_editing.enclose, 'braces' },
  ['Character Sequence'] = { m_editing.enclose, 'chars' },
  Grow = { m_editing.grow_selection, 1 },
  Structure = { m_editing.select_enclosed },
  ['HTML Tag'] = { m_editing.select_enclosed, 'tags' },
  ['Double Quote'] = { m_editing.select_enclosed, 'dbl_quotes' },
  ['Single Quote'] = { m_editing.select_enclosed, 'sng_quotes' },
  Parenthesis = { m_editing.select_enclosed, 'parens' },
  Bracket = { m_editing.select_enclosed, 'brackets' },
  Brace = { m_editing.select_enclosed, 'braces' },
  Word = { m_editing.current_word, 'select' },
  Line = { m_editing.select_line },
  Paragraph = { m_editing.select_paragraph },
  ['Indented Block'] = { m_editing.select_indeted_block },
  Scope = { m_editing.select_scope },
  -- Search
  Find = { t.find.focus },
  ['Jump to'] = { m_editing.goto_line },
  -- Tools
  ['Insert Snippet'] = { m_snippets.insert },
  ['Previous Placeholder'] = { m_snippets.prev },
  ['Cancel Snippet'] = { m_snippets.cancel_current },
  ['List Snippets'] = { m_snippets.list },
  ['Show Scope'] = { m_snippets.show_style },
  ['Add Line'] = { m_mlines.add },
  ['Add Multiple Lines'] = { m_mlines.add_multiple },
  ['Remove Line'] = { m_mlines.remove },
  ['Remove Multiple Lines'] = { m_mlines.remove_multiple },
  ['Update Multiple Lines'] = { m_mlines.update },
  ['Finished Editing'] = { m_mlines.clear },
  -- Buffers
  ['Next Buffer'] = { 'goto_buffer', v, 1, false },
  ['Prev Buffer'] = { 'goto_buffer', v, -1, false },
  ['Toggle View EOL'] = { toggle_setting, 'view_eol' },
  ['Toggle Wrap Mode'] = { toggle_setting, 'wrap_mode' },
  ['Toggle Show Indentation Guides'] = { toggle_setting, 'indentation_guides' },
  ['Toggle Use Tabs'] = { toggle_setting, 'use_tabs' },
  ['Toggle View Whitespace'] = { toggle_setting, 'view_ws' },
  ['Refresh Syntax Highlighting'] = { 'colourise', b, 0, -1 },
  -- Views
  ['Hext View'] = { t.goto_view, 1, false },
  ['Prev View'] = { t.goto_view, -1, false },
  ['Split Vertical'] = { 'split', v },
  ['Split Horizontal'] = { 'split', v, false },
  ['Unsplit'] = { function() view:unsplit() end },
  ['Unsplit All'] = { function() while view:unsplit() do end end },
  ['Grow View'] = { function() view.size = view.size + 10 end },
  ['Shrink View'] = { function() view.size = view.size - 10 end },
  -- Project Manager
  ['Toggle PM Visible'] = { t.pm.toggle_visible },
  ['Focus PM'] = { t.pm.focus },
  ['Show PM Buffers'] = { pm_activate, 'buffers' },
  ['Show PM Ctags'] = { pm_activate, 'ctags' },
  ['Show PM Macros'] = { pm_activate, 'macros' },
}

t.events.add_handler('menu_clicked',
  function(menu_item)
    local active_table = actions[menu_item]
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
        local ret, retval = pcall( f, unpack(args) )
        if not ret then textadept.events.error(retval) end -- error
      else
        error( 'Unknown command: '..tostring(func) )
      end
    end
  end)

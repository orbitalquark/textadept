-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local gui = _G.gui

-- LuaDoc is in core/.gui.luadoc.
function gui.check_focused_buffer(buffer)
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error(L('Buffer argument expected.'), 2)
  elseif gui.focused_doc_pointer ~= buffer.doc_pointer then
    error(L('The indexed buffer is not the focused one.'), 2)
  end
end

-- LuaDoc is in core/.gui.luadoc.
function gui._print(buffer_type, ...)
  local function safe_print(...)
    local message_buffer, message_buffer_index
    local message_view, message_view_index
    for i, buffer in ipairs(_BUFFERS) do
      if buffer._type == buffer_type then
        message_buffer, message_buffer_index = buffer, i
        for j, view in ipairs(_VIEWS) do
          if view.doc_pointer == message_buffer.doc_pointer then
            message_view, message_view_index = view, j
            break
          end
        end
        break
      end
    end
    if not message_view then
      local _, message_view = view:split(false) -- horizontal split
      if not message_buffer then
        message_buffer = new_buffer()
        message_buffer._type = buffer_type
        events.emit('file_opened')
      else
        message_view:goto_buffer(message_buffer_index, true)
      end
    else
      gui.goto_view(message_view_index, true)
    end
    message_buffer:append_text(table.concat({...}, '\t'))
    message_buffer:append_text('\n')
    message_buffer:set_save_point()
  end
  pcall(safe_print, ...) -- prevent endless loops on error
end

-- LuaDoc is in core/.gui.luadoc.
function gui.print(...) gui._print(L('[Message Buffer]'), ...) end

-- LuaDoc is in core/.gui.luadoc.
function gui.switch_buffer()
  local items = {}
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type or L('Untitled')
    local dirty = buffer.dirty and '*' or ''
    items[#items + 1] = dirty..filename:match('[^/\\]+$')
    items[#items + 1] = filename
  end
  local response = gui.dialog('filteredlist',
                              '--title', L('Switch Buffers'),
                              '--button1', 'gtk-ok',
                              '--button2', 'gtk-cancel',
                              '--no-newline',
                              '--columns', 'Name', 'File',
                              '--items', items)
  local ok, i = response:match('(%-?%d+)\n(%d+)$')
  if ok == '1' then view:goto_buffer(tonumber(i) + 1, true) end
end

local connect = _G.events.connect

connect('view_new',
  function() -- sets default properties for a Scintilla window
    local buffer = buffer
    local c = _SCINTILLA.constants

    -- Allow redefinitions of these Scintilla key commands.
    local ctrl_keys = {
      '[', ']', '/', '\\', 'Z', 'Y', 'X', 'C', 'V', 'A', 'L', 'T', 'D', 'U'
    }
    local ctrl_shift_keys = { 'L', 'T', 'U' }
    for _, key in ipairs(ctrl_keys) do
      buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL)
    end
    for _, key in ipairs(ctrl_shift_keys) do
      buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL + c.SCMOD_SHIFT)
    end

    if _THEME and #_THEME > 0 then
      local ok, err = pcall(dofile, _THEME..'/view.lua')
      if ok then return end
      io.stderr:write(err)
    end
  end)
connect('view_new', events.emit('update_ui')) -- update document status

local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.functions.set_lexer_language[1]
connect('buffer_new',
  function() -- sets default properties for a Scintilla document
    local function run()
      local buffer = buffer

      -- Lexer.
      buffer:set_lexer_language('lpeg')
      buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
      buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
      buffer:private_lexer_call(SETLEXERLANGUAGE, 'container')
      buffer.style_bits = 8

      -- Properties.
      buffer.property['textadept.home'] = _HOME
      buffer.property['lexer.lpeg.home'] = _LEXERPATH
      buffer.property['lexer.lpeg.script'] = _HOME..'/lexers/lexer.lua'
      if _THEME and #_THEME > 0 then
        buffer.property['lexer.lpeg.color.theme'] = _THEME..'/lexer.lua'
      end

      -- Buffer.
      buffer.code_page = _SCINTILLA.constants.SC_CP_UTF8

      if _THEME and #_THEME > 0 then
        local ok, err = pcall(dofile, _THEME..'/buffer.lua')
        if ok then return end
        io.stderr:write(err)
      end
    end
    -- Normally when an error occurs, a new buffer is created with the error
    -- message, but if an error occurs here, this event would be called again
    -- and again, erroring each time resulting in an infinite loop; print error
    -- to stderr instead.
    local ok, err = pcall(run)
    if not ok then io.stderr:write(err) end
  end)
connect('buffer_new', events.emit('update_ui')) -- update document status

-- Sets the title of the Textadept window to the buffer's filename.
-- @param buffer The currently focused buffer.
local function set_title(buffer)
  local buffer = buffer
  local filename = buffer.filename or buffer._type or L('Untitled')
  local dirty = buffer.dirty and '*' or '-'
  gui.title = string.format('%s %s Textadept (%s)', filename:match('[^/\\]+$'),
                            dirty, filename)
end

connect('save_point_reached',
  function() -- changes Textadept title to show 'clean' buffer
    buffer.dirty = false
    set_title(buffer)
  end)

connect('save_point_left',
  function() -- changes Textadept title to show 'dirty' buffer
    buffer.dirty = true
    set_title(buffer)
  end)

connect('uri_dropped',
  function(utf8_uris) -- open uri(s)
    for utf8_uri in utf8_uris:gmatch('[^\r\n]+') do
      if utf8_uri:find('^file://') then
        utf8_uri = utf8_uri:match('^file://([^\r\n]+)')
        utf8_uri = utf8_uri:gsub('%%(%x%x)',
          function(hex) return string.char(tonumber(hex, 16)) end)
        if WIN32 then utf8_uri = utf8_uri:sub(2, -1) end -- ignore leading '/'
        local uri = utf8_uri:iconv(_CHARSET, 'UTF-8')
        if lfs.attributes(uri).mode ~= 'directory' then
          io.open_file(utf8_uri)
        end
      end
    end
  end)

local string_format = string.format
local EOLs = { L('CRLF'), L('CR'), L('LF') }
local GETLEXERLANGUAGE = _SCINTILLA.functions.get_lexer_language[1]
connect('update_ui',
  function() -- sets docstatusbar text
    local buffer = buffer
    local pos = buffer.current_pos
    local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
    local col = buffer.column[pos] + 1
    local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE)
    local eol = EOLs[buffer.eol_mode + 1]
    local tabs = string_format('%s %d', buffer.use_tabs and L('Tabs:') or
                               L('Spaces:'), buffer.indent)
    local enc = buffer.encoding or ''
    gui.docstatusbar_text =
      string_format('%s %d/%d    %s %d    %s    %s    %s    %s', L('Line:'),
                    line, max, L('Col:'), col, lexer, eol, tabs, enc)
  end)

connect('margin_click',
  function(margin, modifiers, position) -- toggles folding
    buffer:toggle_fold(buffer:line_from_position(position))
  end)

connect('buffer_new', function() set_title(buffer) end)

connect('buffer_before_switch',
  function() -- save buffer properties
    local buffer = buffer
    -- Save view state.
    buffer._anchor = buffer.anchor
    buffer._current_pos = buffer.current_pos
    buffer._first_visible_line = buffer.first_visible_line
    -- Save fold state.
    buffer._folds = {}
    local folds = buffer._folds
    local i = buffer:contracted_fold_next(0)
    while i >= 0 do
      folds[#folds + 1] = i
      i = buffer:contracted_fold_next(i + 1)
    end
  end)

connect('buffer_after_switch',
  function() -- restore buffer properties
    local buffer = buffer
    if not buffer._folds then return end
    -- Restore fold state.
    for _, i in ipairs(buffer._folds) do buffer:toggle_fold(i) end
    -- Restore view state.
    buffer:set_sel(buffer._anchor, buffer._current_pos)
    buffer:line_scroll(0,
      buffer:visible_from_doc_line(buffer._first_visible_line) -
        buffer.first_visible_line)
  end)

connect('buffer_after_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    events.emit('update_ui')
  end)

connect('view_after_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    events.emit('update_ui')
  end)

connect('reset_after', function() gui.statusbar_text = 'Lua reset' end)

connect('quit',
  function() -- prompts for confirmation if any buffers are dirty
    local list = {}
    for _, buffer in ipairs(_BUFFERS) do
      if buffer.dirty then
        list[#list + 1] = buffer.filename or buffer._type or L('Untitled')
      end
    end
    if #list > 0 and
       gui.dialog('msgbox',
                  '--title', L('Quit without saving?'),
                  '--text', L('The following buffers are unsaved:'),
                  '--informative-text',
                  string.format('%s', table.concat(list, '\n')),
                  '--button1', 'gtk-cancel',
                  '--button2', L('Quit _without saving'),
                  '--no-newline') ~= '2' then
      return false
    end
    return true
  end)

if OSX then
  connect('appleevent_odoc',
    function(uri) return events.emit('uri_dropped', 'file://'..uri) end)

  connect('buffer_new',
    function() -- GTK-OSX has clipboard problems
      buffer.paste = function()
        local clipboard_text = gui.clipboard_text
        if #clipboard_text > 0 then buffer:replace_sel(clipboard_text) end
      end
    end)
end

connect('error', function(...) gui._print(L('[Error Buffer]'), ...) end)

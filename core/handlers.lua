-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

--- Handler module that handles Scintilla and Textadept notifications/events.
module('textadept.handlers', package.seeall)

local handlers = textadept.handlers

---
-- Adds a function to a handler.
-- Every handler has a table of functions associated with it that are run when
-- the handler is called by Textadept.
-- @param handler The string handler name.
-- @param f The Lua function to add.
-- @param index Optional index to insert the handler into.
function add_handler_function(handler, f, index)
  local plural = handler..'s'
  if not handlers[plural] then handlers[plural] = {} end
  local funcs = handlers[plural]
  if index then
    table.insert(funcs, index, f)
  else
    funcs[#funcs+ 1] = f
  end
end

---
-- Calls every function added to a handler in sequence.
-- If true or false is returned by any function, the iteration ceases.
-- @param handler The string handler name.
-- @param ... Arguments to the handler.
function handle(handler, ...)
  local plural = handler..'s'
  if not handlers[plural] then return end
  local funcs = handlers[plural]
  for _, f in ipairs(funcs) do
    local result = f( unpack{...} )
    if result == true or result == false then return result end
  end
end

---
-- Reloads handlers.
-- Clears each table of handlers for each handler function and reloads this
-- module to reset to the default handlers.
function reload()
  package.loaded['handlers'] = nil
  for handler in pairs(handlers) do
    if handlers[handler..'s'] then handlers[handler..'s'] = nil end
  end
  require 'handlers'
end

-- Signals.
function buffer_new()
  return handle('buffer_new')
end
function buffer_deleted()
  return handle('buffer_deleted')
end
function buffer_switch()
  return handle('buffer_switch')
end
function view_new()
  return handle('view_new')
end
function view_switch()
  return handle('view_switch')
end
function quit()
  return handle('quit')
end
function keypress(code, shift, control, alt)
  return handle('keypress', code, shift, control, alt)
end

-- Scintilla notifications.
function char_added(n)
  return handle( 'char_added', string.char(n.ch) )
end
function save_point_reached()
  return handle('save_point_reached')
end
function save_point_left()
  return handle('save_point_left')
end
function double_click(n)
  return handle('double_click', n.position, n.line)
end
function update_ui()
  return handle('update_ui')
end
function macro_record(n)
  return handle('macro_record', n.message, n.wParam, n.lParam)
end
function margin_click(n)
  return handle('margin_click', n.margin, n.modifiers, n.position)
end
function user_list_selection(n)
  return handle('user_list_selection', n.wParam, n.text)
end
function uri_dropped(n)
  return handle('uri_dropped', n.text)
end
function call_tip_click(n)
  return handle('call_tip_click', n.position)
end
function auto_c_selection(n)
  return handle('auto_c_selection', n.lParam, n.text)
end

--- Map of Scintilla notifications to their handlers.
local c = textadept.constants
local scnnotifications = {
  [c.SCN_CHARADDED] = char_added,
  [c.SCN_SAVEPOINTREACHED] = save_point_reached,
  [c.SCN_SAVEPOINTLEFT] = save_point_left,
  [c.SCN_DOUBLECLICK] = double_click,
  [c.SCN_UPDATEUI] = update_ui,
  [c.SCN_MACRORECORD] = macro_record,
  [c.SCN_MARGINCLICK] = margin_click,
  [c.SCN_USERLISTSELECTION] = user_list_selection,
  [c.SCN_URIDROPPED] = uri_dropped,
  [c.SCN_CALLTIPCLICK] = call_tip_click,
  [c.SCN_AUTOCSELECTION] = auto_c_selection
}

---
-- Handles Scintilla notifications.
-- @param n The Scintilla notification structure as a Lua table.
function notification(n)
  local f = scnnotifications[n.code]
  if f then f(n) end
end

-- Default handlers to follow.

add_handler_function('char_added',
  function(char) -- auto-indent on return
    if char ~= '\n' then return end
    local buffer = buffer
    local pos = buffer.current_pos
    local curr_line = buffer:line_from_position(pos)
    local last_line = curr_line - 1
    while last_line >= 0 and #buffer:get_line(last_line) == 1 do
      last_line = last_line - 1
    end
    if last_line >= 0 then
      local indentation = buffer.line_indentation[last_line]
      local s = buffer.line_indent_position[curr_line]
      buffer.line_indentation[curr_line] = indentation
      local e = buffer.line_indent_position[curr_line]
      buffer:goto_pos(pos + e - s)
    end
  end)

---
-- [Local function] Sets the title of the Textadept window to the buffer's
-- filename.
-- @param buffer The currently focused buffer.
local function set_title(buffer)
  local buffer = buffer
  local filename = buffer.filename or 'Untitled'
  local d = buffer.dirty and ' * ' or ' - '
  textadept.title = filename:match('[^/]+$')..d..'Textadept ('..filename..')'
end

add_handler_function('save_point_reached',
  function() -- changes Textadept title to show 'clean' buffer
    buffer.dirty = false
    set_title(buffer)
  end)

add_handler_function('save_point_left',
  function() -- changes Textadept title to show 'dirty' buffer
    buffer.dirty = true
    set_title(buffer)
  end)

---
-- [Local table] A table of (integer) brace characters with their matches.
-- @class table
-- @name _braces
local _braces = { -- () [] {} <>
  [40] = 1, [91] = 1, [123] = 1, [60] = 1,
  [41] = 1, [93] = 1, [125] = 1, [62] = 1,
}

---
-- [Local function] Highlights matching/mismatched braces appropriately.
-- @param current_pos The position to match braces at.
local function match_brace(current_pos)
  local buffer = buffer
  if _braces[ buffer.char_at[current_pos] ] and
    buffer:get_style_name( buffer.style_at[current_pos] ) == 'operator' then
    local pos = buffer:brace_match(current_pos)
    if pos ~= -1 then
      buffer:brace_highlight(current_pos, pos)
    else
      buffer:brace_bad_light(current_pos)
    end
    return true
  end
  return false
end

add_handler_function('update_ui',
  function() -- highlights matching braces
    local buffer = buffer
    if not match_brace(buffer.current_pos) then buffer:brace_bad_light(-1) end
  end)

local docstatusbar_text =
  "Line: %d/%d    Col: %d    Lexer: %s    %s    %s    %s"
add_handler_function('update_ui',
  function() -- sets docstatusbar text
    local buffer = buffer
    local pos = buffer.current_pos
    local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
    local col = buffer.column[pos] + 1
    local lexer = buffer:get_lexer_language()
    local mode = buffer.overtype and 'OVR' or 'INS'
    local eol = ( { 'CRLF', 'CR', 'LF' } )[buffer.eol_mode + 1]
    local tabs = (buffer.use_tabs and 'Tabs:' or 'Spaces:')..buffer.indent
    textadept.docstatusbar_text =
      docstatusbar_text:format(line, max, col, lexer, mode, eol, tabs)
  end)

add_handler_function('margin_click',
  function(margin, modifiers, position) -- toggles folding
    local buffer = buffer
    local line = buffer:line_from_position(position)
    buffer:toggle_fold(line)
  end)

add_handler_function('buffer_new',
  function() -- set additional buffer functions
    local buffer, textadept = buffer, textadept
    buffer.save = textadept.io.save
    buffer.save_as = textadept.io.save_as
    buffer.close = textadept.io.close
    set_title(buffer)
  end)

add_handler_function('buffer_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    update_ui()
  end)

add_handler_function('view_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    update_ui()
  end)

add_handler_function('quit',
  function() -- prompts for confirmation if any buffers are dirty; saves session
    local any = false
    local list = 'The following buffers are unsaved:\n\n'
    for _, buffer in ipairs(textadept.buffers) do
      if buffer.dirty then
        list = list..(buffer.filename or 'Untitled')..'\n'
        any = true
      end
    end
    if any then
      list = list..'\nQuit without saving?'
      if os.execute('zenity --question --title Alert '..
        '--text "'..list..'"') ~= 0 then
        return false
      end
    end
    textadept.io.save_session()
    return true
  end)


---
-- Shows completions for the current command_entry text.
-- Opens a new buffer (if one hasn't already been opened) for printing possible
-- completions.
-- @param command The command to complete.
function show_completions(command)
  local textadept = textadept
  local cmpl_buffer, goto
  if buffer.shows_completions then
    cmpl_buffer = buffer
  else
    for index, buffer in ipairs(textadept.buffers) do
      if buffer.shows_completions then
        cmpl_buffer = index
        goto = buffer.doc_pointer ~= textadept.focused_doc_pointer
      elseif buffer.doc_pointer == textadept.focused_doc_pointer then
        textadept.prev_buffer = index
      end
    end
    if not cmpl_buffer then
      cmpl_buffer = textadept.new_buffer()
      cmpl_buffer.shows_completions = true
    else
      if goto then view:goto(cmpl_buffer) end
      cmpl_buffer = textadept.buffers[cmpl_buffer]
    end
  end
  cmpl_buffer:clear_all()

  local substring = command:match('[%w_.:]+$') or ''
  local path, o, prefix = substring:match('^([%w_.:]-)([.:]?)([%w_]*)$')
  local ret, tbl = pcall(loadstring('return ('..path..')'))
  if not ret then tbl = getfenv(0) end
  if type(tbl) ~= 'table' then return end
  local cmpls = {}
  for k in pairs(tbl) do
    if type(k) == 'string' and k:match('^'..prefix) then
      cmpls[#cmpls + 1] = k
    end
  end
  if path == 'buffer' then
    if o == ':' then
      for f in pairs(textadept.buffer_functions) do
        if f:match('^'..prefix) then cmpls[#cmpls + 1] = f end
      end
    else
      for p in pairs(textadept.buffer_properties) do
        if p:match('^'..prefix) then cmpls[#cmpls + 1] = p end
      end
    end
  end
  table.sort(cmpls)
  for _, cmpl in ipairs(cmpls) do cmpl_buffer:add_text(cmpl..'\n') end
  cmpl_buffer:set_save_point()
end

---
-- Hides the completion buffer if it is currently focused and restores the
-- previous focused buffer (if possible).
function hide_completions()
  local textadept = textadept
  if buffer.shows_completions then
    buffer:close()
    if textadept.prev_buffer then view:goto_buffer(textadept.prev_buffer) end
  end
end

---
-- Default error handler.
-- Opens a new buffer (if one hasn't already been opened) for printing errors.
-- @param ... Error strings.
function error(...)
  local function handle_error(...)
    local textadept = textadept
    local error_message = table.concat( {...} , '\n' )
    local error_buffer
    for index, buffer in ipairs(textadept.buffers) do
      if buffer.shows_errors then
        error_buffer = buffer
        if buffer.doc_pointer ~= textadept.focused_doc_pointer then
          view:goto_buffer(index)
        end
        break
      end
    end
    if not error_buffer then
      error_buffer = textadept.new_buffer()
      error_buffer.shows_errors = true
    end
    error_buffer:append_text(error_message..'\n')
    error_buffer:set_save_point()
  end
  pcall( handle_error, unpack{...} ) -- prevent endless loops if this errors
end

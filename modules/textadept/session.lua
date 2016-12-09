-- Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Session support for Textadept.
-- @field default_session (string)
--   The path to the default session file, *`_USERHOME`/session*, or
--   *`_USERHOME`/session_term* if [`CURSES`]() is `true`.
-- @field save_on_quit (bool)
--   Save the session when quitting.
--   The session file saved is always `textadept.session.default_session`, even
--   if a different session was loaded with [`textadept.session.load()`]().
--   The default value is `true` unless the user passed the command line switch
--   `-n` or `--nosession` to Textadept.
-- @field max_recent_files (number)
--   The maximum number of recent files to save in session files.
--   Recent files are stored in [`io.recent_files`]().
--   The default value is `10`.
module('textadept.session')]]

M.default_session = _USERHOME..(not CURSES and '/session' or '/session_term')
M.save_on_quit = true
M.max_recent_files = 10

---
-- Loads session file *filename* or the user-selected session, returning `true`
-- if a session file was opened and read.
-- Textadept restores split views, opened buffers, cursor information, recent
-- files, and bookmarks.
-- @param filename Optional absolute path to the session file to load. If `nil`,
--   the user is prompted for one.
-- @return `true` if the session file was opened and read; `false` otherwise.
-- @usage textadept.session.load(filename)
-- @see default_session
-- @name load
function M.load(filename)
  local dir, name = M.default_session:match('^(.-[/\\]?)([^/\\]+)$')
  filename = filename or ui.dialogs.fileselect{
    title = _L['Load Session'], with_directory = dir, with_file = name
  }
  if not filename then return end
  local not_found = {}
  local f = io.open(filename, 'rb')
  if not f or not io.close_all_buffers() then return false end
  io.recent_files = {}
  local current_view, splits = view, {[0] = {}}
  for line in f:lines() do
    if line:find('^buffer:') then
      local patt = '^buffer: (%d+) (%d+) (%d+) (.+)$'
      local anchor, current_pos, top_line, filename = line:match(patt)
      if not filename:find('^%[.+%]$') then
        if lfs.attributes(filename) then
          io.open_file(filename)
        else
          not_found[#not_found + 1] = filename
        end
      else
        buffer.new()._type = filename
        events.emit(events.FILE_OPENED, filename) -- close initial untitled buf
      end
      -- Restore saved buffer selection and view.
      buffer:set_sel(tonumber(anchor), tonumber(current_pos))
      buffer:line_scroll(0, buffer:visible_from_doc_line(tonumber(top_line)) -
                            buffer.first_visible_line)
    elseif line:find('^bookmarks:') then
      local lines = line:match('^bookmarks: (.*)$')
      for line in lines:gmatch('%d+') do
        buffer:marker_add(tonumber(line), textadept.bookmarks.MARK_BOOKMARK)
      end
    elseif line:find('^size:') then
      local maximized, width, height = line:match('^size: (%l+) (%d+) (%d+)$')
      ui.maximized = maximized == 'true'
      if not ui.maximized then ui.size = {width, height} end
    elseif line:find('^%s*split%d:') then
      local level, num, type, size = line:match('^(%s*)split(%d): (%S+) (%d+)')
      local view = splits[#level] and splits[#level][tonumber(num)] or view
      ui.goto_view(view)
      splits[#level + 1] = {view:split(type == 'true')}
      splits[#level + 1][1].size = tonumber(size) -- could be 1 or 2
    elseif line:find('^%s*view%d:') then
      local level, num, buf_idx = line:match('^(%s*)view(%d): (%d+)$')
      local view = splits[#level][tonumber(num)] or view
      buf_idx = tonumber(buf_idx)
      if buf_idx > #_BUFFERS then buf_idx = #_BUFFERS end
      view:goto_buffer(_BUFFERS[buf_idx])
    elseif line:find('^current_view:') then
      current_view = _VIEWS[tonumber(line:match('^current_view: (%d+)')) or 1]
    elseif line:find('^recent:') then
      -- If a recent file is already open, do not add it to the list again.
      local recent_file, exists = line:match('^recent: (.+)$'), false
      for i = 1, #io.recent_files do
        if io.recent_files[i] == recent_file then exists = true break end
      end
      if not exists then io.recent_files[#io.recent_files + 1] = recent_file end
    end
  end
  f:close()
  ui.goto_view(current_view)
  if #not_found > 0 then
    ui.dialogs.msgbox{
      title = _L['Session Files Not Found'],
      text = _L['The following session files were not found'],
      informative_text = table.concat(not_found, '\n'):iconv('UTF-8', _CHARSET),
      icon = 'gtk-dialog-warning'
    }
  end
  return true
end
-- Load session when no args are present.
events.connect(events.ARG_NONE, function()
  if M.save_on_quit then M.load(M.default_session) end
end)

---
-- Saves the session to file *filename* or the user-selected file.
-- Saves split views, opened buffers, cursor information, recent files, and
-- bookmarks.
-- @param filename Optional absolute path to the session file to save. If `nil`,
--   the user is prompted for one.
-- @usage textadept.session.save(filename)
-- @see default_session
-- @name save
function M.save(filename)
  local dir, name = M.default_session:match('^(.-[/\\]?)([^/\\]+)$')
  filename = filename or ui.dialogs.filesave{
    title = _L['Save Session'], with_directory = dir,
    with_file = name:iconv('UTF-8', _CHARSET)
  }
  if not filename then return end
  local session = {}
  local buffer_line = 'buffer: %d %d %d %s' -- anchor, cursor, line, filename
  local split_line = '%ssplit%d: %s %d' -- level, number, type, size
  local view_line = '%sview%d: %d' -- level, number, doc index
  -- Write out opened buffers.
  for i = 1, #_BUFFERS do
    local buffer = _BUFFERS[i]
    local filename = buffer.filename or buffer._type
    if filename then
      local current = buffer == view.buffer
      local anchor = current and 'anchor' or '_anchor'
      local current_pos = current and 'current_pos' or '_current_pos'
      local top_line = current and 'first_visible_line' or '_top_line'
      session[#session + 1] = buffer_line:format(buffer[anchor] or 0,
                                                 buffer[current_pos] or 0,
                                                 buffer[top_line] or 0,
                                                 filename)
      -- Write out bookmarks.
      local lines = {}
      local line = buffer:marker_next(0, 2^textadept.bookmarks.MARK_BOOKMARK)
      while line >= 0 do
        lines[#lines + 1] = line
        line = buffer:marker_next(line + 1, 2^textadept.bookmarks.MARK_BOOKMARK)
      end
      session[#session + 1] = 'bookmarks: '..table.concat(lines, ' ')
    end
  end
  -- Write out window size. Do this before writing split views since split view
  -- size depends on the window size.
  local maximized, size = tostring(ui.maximized), ui.size
  session[#session + 1] = string.format('size: %s %d %d', maximized, size[1],
                                        size[2])
  -- Write out split views.
  local function write_split(split, level, number)
    local c1, c2 = split[1], split[2]
    local vertical, size = tostring(split.vertical), split.size
    local spaces = string.rep(' ', level)
    session[#session + 1] = split_line:format(spaces, number, vertical, size)
    spaces = string.rep(' ', level + 1)
    if c1[1] and c1[2] then
      write_split(c1, level + 1, 1)
    else
      session[#session + 1] = view_line:format(spaces, 1, _BUFFERS[c1.buffer])
    end
    if c2[1] and c2[2] then
      write_split(c2, level + 1, 2)
    else
      session[#session + 1] = view_line:format(spaces, 2, _BUFFERS[c2.buffer])
    end
  end
  local splits = ui.get_split_table()
  if splits[1] and splits[2] then
    write_split(splits, 0, 0)
  else
    session[#session + 1] = view_line:format('', 1, _BUFFERS[splits.buffer])
  end
  -- Write out the current focused view.
  session[#session + 1] = string.format('current_view: %d', _VIEWS[view])
  -- Write out other things.
  for i = 1, #io.recent_files do
    if i > M.max_recent_files then break end
    session[#session + 1] = string.format('recent: %s', io.recent_files[i])
  end
  -- Write the session.
  local f = io.open(filename, 'wb')
  if f then
    f:write(table.concat(session, '\n'))
    f:close()
  end
end
-- Saves session on quit.
events.connect(events.QUIT, function()
  if M.save_on_quit then M.save(M.default_session) end
end, 1)

-- Does not save session on quit.
args.register('-n', '--nosession', 0,
              function() M.save_on_quit = false end, 'No session functionality')
-- Loads the given session on startup.
args.register('-s', '--session', 1, function(name)
  if not lfs.attributes(name) then name = _USERHOME..'/'..name end
  M.load(name)
end, 'Load session')

return M

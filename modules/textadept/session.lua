-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Session support for Textadept.
-- @field DEFAULT_SESSION (string)
--   The path to the default session file, *`_USERHOME`/session*, or
--   *`_USERHOME`/session_term* if [`_G.CURSES`][] is `true`.
--
--   [`_G.CURSES`]: _G.html#CURSES
-- @field SAVE_ON_QUIT (bool)
--   Save the session when quitting.
--   The session file saved is always `DEFAULT_SESSION`, even if a different
--   session was loaded with [`load()`](#load).
--   The default value is `true`, but is disabled when passing the command line
--   switch `-n` or `--nosession` to Textadept.
-- @field MAX_RECENT_FILES (number)
--   The maximum number of recent files to save to the session.
--   Recent files are stored in [`io.recent_files`][].
--   The default value is `10`.
--
--   [`io.recent_files`]: io.html#recent_files
module('_M.textadept.session')]]

M.DEFAULT_SESSION = _USERHOME..(not CURSES and '/session' or '/session_term')
M.SAVE_ON_QUIT = true
M.MAX_RECENT_FILES = 10

---
-- Loads the Textadept session file *filename* or prompts the user to select
-- one, returning `true` if the session file was opened and read.
-- Textadept restores split views, opened buffers, cursor information, and
-- recent files.
-- @param filename Optional absolute path to the session file to load. If `nil`,
--   the user is prompted for one.
-- @return `true` if the session file was opened and read; `false` otherwise.
-- @usage _M.textadept.session.load(filename)
-- @see DEFAULT_SESSION
-- @name load
function M.load(filename)
  filename = filename or gui.dialog('fileselect',
                                    '--title', _L['Load Session'],
                                    '--with-directory',
                                    M.DEFAULT_SESSION:match('.+[/\\]') or '',
                                    '--with-file',
                                    M.DEFAULT_SESSION:match('[^/\\]+$') or '',
                                    '--no-newline'):iconv(_CHARSET, 'UTF-8')
  if filename == '' then return end
  local not_found = {}
  local f = io.open(filename, 'rb')
  if not f then io.close_all() return false end
  local current_view, splits = 1, {[0] = {}}
  local lfs_attributes = lfs.attributes
  for line in f:lines() do
    if line:find('^buffer:') then
      local anchor, current_pos, first_visible_line, filename =
        line:match('^buffer: (%d+) (%d+) (%d+) (.+)$')
      if not filename:find('^%[.+%]$') then
        if lfs_attributes(filename) then
          io.open_file(filename)
        else
          not_found[#not_found + 1] = filename
        end
      else
        buffer.new()._type = filename
        events.emit(events.FILE_OPENED, filename)
      end
      -- Restore saved buffer selection and view.
      local anchor = tonumber(anchor) or 0
      local current_pos = tonumber(current_pos) or 0
      local first_visible_line = tonumber(first_visible_line) or 0
      buffer._anchor, buffer._current_pos = anchor, current_pos
      buffer._first_visible_line = first_visible_line
      buffer:line_scroll(0, buffer:visible_from_doc_line(first_visible_line))
      buffer:set_sel(anchor, current_pos)
    elseif line:find('^%s*split%d:') then
      local level, num, type, size = line:match('^(%s*)split(%d): (%S+) (%d+)')
      local view = splits[#level] and splits[#level][tonumber(num)] or view
      splits[#level + 1] = {view:split(type == 'true')}
      splits[#level + 1][1].size = tonumber(size) -- could be 1 or 2
    elseif line:find('^%s*view%d:') then
      local level, num, buf_idx = line:match('^(%s*)view(%d): (%d+)$')
      local view = splits[#level][tonumber(num)] or view
      buf_idx = tonumber(buf_idx)
      if buf_idx > #_BUFFERS then buf_idx = #_BUFFERS end
      view:goto_buffer(buf_idx)
    elseif line:find('^current_view:') then
      current_view = tonumber(line:match('^current_view: (%d+)')) or 1
    elseif line:find('^size:') then
      local maximized, width, height = line:match('^size: (%l*) ?(%d+) (%d+)$')
      maximized = maximized == 'true'
      if maximized then gui.maximized = true else gui.size = {width, height} end
    elseif line:find('^recent:') then
      local filename = line:match('^recent: (.+)$')
      local recent, exists = io.recent_files, false
      for i, file in ipairs(recent) do
        if filename == file then exists = true break end
      end
      if not exists then recent[#recent + 1] = filename end
    end
  end
  f:close()
  gui.goto_view(current_view)
  if #not_found > 0 then
    gui.dialog('msgbox',
               '--title', _L['Session Files Not Found'],
               '--text', _L['The following session files were not found'],
               '--informative-text', table.concat(not_found, '\n'),
               '--icon', 'gtk-dialog-warning',
               '--button1', _L['_OK'])
  end
  return true
end
-- Load session when no args are present.
events.connect('arg_none', function()
  if M.SAVE_ON_QUIT then M.load(M.DEFAULT_SESSION) end
end)

---
-- Saves a Textadept session to file *filename* or a user-selected file.
-- Saves split views, opened buffers, cursor information, and recent files.
-- @param filename Optional absolute path to the session file to save. If `nil`,
--   the user is prompted for one.
-- @usage _M.textadept.session.save(filename)
-- @see DEFAULT_SESSION
-- @name save
function M.save(filename)
  filename = filename or gui.dialog('filesave',
                                    '--title', _L['Save Session'],
                                    '--with-directory',
                                    M.DEFAULT_SESSION:match('.+[/\\]') or '',
                                    '--with-file',
                                    M.DEFAULT_SESSION:match('[^/\\]+$') or '',
                                    '--no-newline'):iconv(_CHARSET, 'UTF-8')
  if filename == '' then return end
  local session = {}
  local buffer_line = "buffer: %d %d %d %s" -- anchor, cursor, line, filename
  local split_line = "%ssplit%d: %s %d" -- level, number, type, size
  local view_line = "%sview%d: %d" -- level, number, doc index
  -- Write out opened buffers.
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type
    if filename then
      local current = buffer == view.buffer
      local anchor = current and 'anchor' or '_anchor'
      local current_pos = current and 'current_pos' or '_current_pos'
      local top_line = current and 'first_visible_line' or '_first_visible_line'
      session[#session + 1] = buffer_line:format(buffer[anchor] or 0,
                                                 buffer[current_pos] or 0,
                                                 buffer[top_line] or 0,
                                                 filename)
    end
  end
  -- Write out split views.
  local function write_split(split, level, number)
    local c1, c2 = split[1], split[2]
    local vertical, size = tostring(split.vertical), split.size
    local spaces = (' '):rep(level)
    session[#session + 1] = split_line:format(spaces, number, vertical, size)
    spaces = (' '):rep(level + 1)
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
  local splits = gui.get_split_table()
  if splits[1] and splits[2] then
    write_split(splits, 0, 0)
  else
    session[#session + 1] = view_line:format('', 1, _BUFFERS[splits.buffer])
  end
  -- Write out the current focused view.
  session[#session + 1] = ("current_view: %d"):format(_VIEWS[view])
  -- Write out other things.
  local maximized, size = tostring(gui.maximized), gui.size
  session[#session + 1] = ("size: %s %d %d"):format(maximized, size[1], size[2])
  for i = 1, #io.recent_files do
    if i > M.MAX_RECENT_FILES then break end
    session[#session + 1] = ("recent: %s"):format(io.recent_files[i])
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
  if M.SAVE_ON_QUIT then M.save(M.DEFAULT_SESSION) end
end, 1)

-- Does not save session on quit.
args.register('-n', '--nosession', 0,
              function() M.SAVE_ON_QUIT = false end, 'No session functionality')
-- Loads the given session on startup.
args.register('-s', '--session', 1, function(name)
  if lfs.attributes(name) then M.load(name) return end
  M.load(_USERHOME..'/'..name)
end, 'Load session')

return M

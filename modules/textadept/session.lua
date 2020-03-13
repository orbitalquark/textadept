-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Session support for Textadept.
-- @field save_on_quit (bool)
--   Save the session when quitting.
--   The default value is `true` unless the user passed the command line switch
--   `-n` or `--nosession` to Textadept.
-- @field _G.events.SESSION_SAVE (string)
--   Emitted when saving a session.
--
--   Arguments:
--
--   * `session`: Table of session data to save. All handlers will have access
--     to this same table, and Textadept's default handler reserves the use of
--     some keys.
--     Note that functions, userdata, and circular table values cannot be saved.
--     The latter case is not recognized at all, so beware.
-- @field _G.events.SESSION_LOAD (string)
--   Emitted when loading a session.
--   Arguments:
--
--   * `session`: Table of session data to load. All handlers will have access
--     to this same table.
module('textadept.session')]]

M.save_on_quit = true

-- Events.
events.SESSION_SAVE, events.SESSION_LOAD = 'session_save', 'session_load'

local session_file = _USERHOME .. (not CURSES and '/session' or '/session_term')

---
-- Loads session file *filename* or the user-selected session, returning `true`
-- if a session file was opened and read.
-- Textadept restores split views, opened buffers, cursor information, recent
-- files, and bookmarks.
-- @param filename Optional absolute path to the session file to load. If `nil`,
--   the user is prompted for one.
-- @return `true` if the session file was opened and read; `nil` otherwise.
-- @usage textadept.session.load(filename)
-- @name load
function M.load(filename)
  local dir, name = session_file:match('^(.-[/\\]?)([^/\\]+)$')
  if not assert_type(filename, 'string/nil', 1) then
    filename = ui.dialogs.fileselect{
      title = _L['Load Session'], with_directory = dir, with_file = name
    }
    if not filename then return end
  end

  local f = loadfile(filename, 't', {})
  if not f or not io.close_all_buffers() then return end -- fail silently
  local session = f()
  local not_found = {}

  -- Unserialize buffers.
  for _, buf in ipairs(session.buffers) do
    if not buf.filename:find('^%[.+%]$') then
      if lfs.attributes(buf.filename) then
        io.open_file(buf.filename)
        buffer:set_sel(buf.anchor, buf.current_pos)
        buffer:line_scroll(0, buf.top_line - buffer.first_visible_line)
        for _, line in ipairs(buf.bookmarks) do
          buffer:marker_add(line, textadept.bookmarks.MARK_BOOKMARK)
        end
      else
        not_found[#not_found + 1] = buf.filename
      end
    else
      buffer.new()._type = buf.filename
      buffer:set_save_point()
      events.emit(events.FILE_OPENED, buf.filename) -- close initial buffer
    end
  end

  -- Unserialize UI state.
  ui.maximized = session.ui.maximized
  if not ui.maximized then ui.size = session.ui.size end

  -- Unserialize views.
  local function unserialize_split(split)
    if type(split) ~= 'table' then
      view:goto_buffer(_BUFFERS[math.min(split, #_BUFFERS)])
      return
    end
    local one, two = view:split(split.vertical)
    one.size = split.size -- could use either one or two, it does not matter
    for i, view in ipairs{one, two} do
      ui.goto_view(view)
      unserialize_split(split[i])
    end
  end
  unserialize_split(session.views[1])
  ui.goto_view(_VIEWS[math.min(session.views.current, #_VIEWS)])

  -- Unserialize recent files.
  io.recent_files = session.recent_files

  -- Unserialize user data.
  events.emit(events.SESSION_LOAD, session)

  if #not_found > 0 then
    ui.dialogs.msgbox{
      title = _L['Session Files Not Found'],
      text = _L['The following session files were not found'],
      informative_text = table.concat(not_found, '\n'):iconv('UTF-8', _CHARSET),
      icon = 'gtk-dialog-warning'
    }
  end
  session_file = filename
  return true
end
-- Load session when no args are present.
local function load_default_session()
  if M.save_on_quit then M.load(session_file) end
end
events.connect(events.ARG_NONE, load_default_session)

-- Returns value *val* serialized as a string.
-- This is a very simple implementation suitable for session saving only.
local function _tostring(val)
  if type(val) == 'function' or type(val) == 'userdata' then val = nil end
  if type(val) == 'table' then
    local t = {}
    for k, v in pairs(val) do
      t[#t + 1] = string.format('[%s]=%s,', _tostring(k), _tostring(v))
    end
    return string.format('{%s}', table.concat(t))
  end
  return type(val) == 'string' and string.format('%q', val) or tostring(val)
end

---
-- Saves the session to file *filename* or the user-selected file.
-- Saves split views, opened buffers, cursor information, recent files, and
-- bookmarks.
-- @param filename Optional absolute path to the session file to save. If `nil`,
--   the user is prompted for one.
-- @usage textadept.session.save(filename)
-- @name save
function M.save(filename)
  local dir, name = session_file:match('^(.-[/\\]?)([^/\\]+)$')
  if not assert_type(filename, 'string/nil', 1) then
    filename = ui.dialogs.filesave{
      title = _L['Save Session'], with_directory = dir,
      with_file = name:iconv('UTF-8', _CHARSET)
    }
    if not filename then return end
  end
  local session = {}

  -- Serialize user data.
  events.emit(events.SESSION_SAVE, session)

  -- Serialize buffers.
  session.buffers = {}
  for _, buffer in ipairs(_BUFFERS) do
    if not buffer.filename and not buffer._type then goto continue end
    local current = buffer == view.buffer
    session.buffers[#session.buffers + 1] = {
      filename = buffer.filename or buffer._type,
      anchor = current and buffer.anchor or buffer._anchor,
      current_pos = current and buffer.current_pos or buffer._current_pos,
      top_line = current and buffer.first_visible_line or buffer._top_line,
    }
    local bookmarks = {}
    local line = buffer:marker_next(0, 1 << textadept.bookmarks.MARK_BOOKMARK)
    while line ~= -1 do
      bookmarks[#bookmarks + 1] = line
      line = buffer:marker_next(
        line + 1, 1 << textadept.bookmarks.MARK_BOOKMARK)
    end
    session.buffers[#session.buffers].bookmarks = bookmarks
    ::continue::
  end

  -- Serialize UI state.
  session.ui = {maximized = ui.maximized, size = ui.size}

  -- Serialize views.
  local function serialize_split(split)
    local one, two = split[1], split[2]
    return {
      one.buffer and _BUFFERS[one.buffer] or serialize_split(one),
      two.buffer and _BUFFERS[two.buffer] or serialize_split(two),
      vertical = split.vertical, size = split.size
    }
  end
  local splits = ui.get_split_table()
  session.views = {
    splits.buffer and _BUFFERS[splits.buffer] or serialize_split(splits),
    current = _VIEWS[view]
  }

  -- Serialize recent files.
  session.recent_files = io.recent_files

  -- Write the session.
  local f = io.open(filename, 'wb')
  if f then f:write('return ', _tostring(session)):close() end
  session_file = filename
end
-- Saves session on quit.
events.connect(events.QUIT, function()
  if M.save_on_quit then M.save(session_file) end
end, 1)

-- Does not save session on quit.
args.register('-n', '--nosession', 0, function()
  M.save_on_quit = false
end, 'No session functionality')
-- Loads the given session on startup.
args.register('-s', '--session', 1, function(name)
  if not lfs.attributes(name) then
    name = string.format('%s/%s', _USERHOME, name)
  end
  M.load(name)
  events.disconnect(events.ARG_NONE, load_default_session)
end, 'Load session')

return M

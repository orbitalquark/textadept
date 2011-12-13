-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize

local M = {}

--[[ This comment is for LuaDoc.
---
-- Session support for the textadept module.
module('_m.textadept.session', package.seeall)]]

-- Markdown:
-- ## Settings
--
-- * `DEFAULT_SESSION` [string]: The path to the default session file.
-- * `SAVE_ON_QUIT` [bool]: Save the session when quitting. The default value is
--   `true` and can be disabled by passing the command line switch `-n` or
--   `--nosession` to Textadept.
-- * `MAX_RECENT_FILES` [number]: The maximum number of files from the recent
--   files list to save to the session. The default is `10`.

-- settings
M.DEFAULT_SESSION = _USERHOME..'/session'
M.SAVE_ON_QUIT = true
M.MAX_RECENT_FILES = 10
-- end settings

---
-- Loads a Textadept session file.
-- Textadept restores split views, opened buffers, cursor information, and
-- project manager details.
-- @param filename The absolute path to the session file to load. Defaults to
--   `DEFAULT_SESSION` if not specified.
-- @return `true` if the session file was opened and read; `false` otherwise.
-- @usage _m.textadept.session.load(filename)
-- @name load
function M.load(filename)
  local not_found = {}
  local f = io.open(filename or M.DEFAULT_SESSION, 'rb')
  if not f then io.close_all() return false end
  local current_view, splits = 1, { [0] = {} }
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
        new_buffer()._type = filename
        events.emit(events.FILE_OPENED, filename)
      end
      -- Restore saved buffer selection and view.
      local anchor = tonumber(anchor) or 0
      local current_pos = tonumber(current_pos) or 0
      local first_visible_line = tonumber(first_visible_line) or 0
      local buffer = buffer
      buffer._anchor, buffer._current_pos = anchor, current_pos
      buffer._first_visible_line = first_visible_line
      buffer:line_scroll(0,
             buffer:visible_from_doc_line(first_visible_line))
      buffer:set_sel(anchor, current_pos)
    elseif line:find('^%s*split%d:') then
      local level, num, type, size =
        line:match('^(%s*)split(%d): (%S+) (%d+)')
      local view = splits[#level] and splits[#level][tonumber(num)] or view
      splits[#level + 1] = { view:split(type == 'true') }
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
      local width, height = line:match('^size: (%d+) (%d+)$')
      if width and height then gui.size = { width, height } end
    elseif line:find('^recent:') then
      local filename = line:match('^recent: (.+)$')
      local recent = io.recent_files
      for i, file in ipairs(recent) do
        if filename == file then break end
        if i == #recent then recent[#recent + 1] = filename end
      end
    end
  end
  f:close()
  gui.goto_view(current_view)
  if #not_found > 0 then
    gui.dialog('msgbox',
               '--title', L('Session Files Not Found'),
               '--text', L('The following session files were not found'),
               '--informative-text', table.concat(not_found, '\n'))
  end
  return true
end
-- Load session when no args are present.
events.connect('arg_none', function() if M.SAVE_ON_QUIT then M.load() end end)

---
-- Saves a Textadept session to a file.
-- Saves split views, opened buffers, cursor information, and project manager
-- details.
-- @param filename The absolute path to the session file to save. Defaults to
--   either the current session file or `DEFAULT_SESSION` if not specified.
-- @usage _m.textadept.session.save(filename)
-- @name save
function M.save(filename)
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
  local size = gui.size
  session[#session + 1] = ("size: %d %d"):format(size[1], size[2])
  for i, filename in ipairs(io.recent_files) do
    if i > M.MAX_RECENT_FILES then break end
    session[#session + 1] = ("recent: %s"):format(filename)
  end
  -- Write the session.
  local f = io.open(filename or M.DEFAULT_SESSION, 'wb')
  if f then
    f:write(table.concat(session, '\n'))
    f:close()
  end
end

---
-- Prompts the user for a Textadept session to load.
-- @name prompt_load
function M.prompt_load()
  local utf8_filename = gui.dialog('fileselect',
                                   '--title', L('Load Session'),
                                   '--with-directory',
                                   M.DEFAULT_SESSION:match('.+[/\\]') or '',
                                   '--with-file',
                                   M.DEFAULT_SESSION:match('[^/\\]+$') or '',
                                   '--no-newline')
  if #utf8_filename > 0 then M.load(utf8_filename:iconv(_CHARSET, 'UTF-8')) end
end

---
-- Prompts the user to save the current Textadept session to a file.
-- @name prompt_save
function M.prompt_save()
  local utf8_filename = gui.dialog('filesave',
                                   '--title', L('Save Session'),
                                   '--with-directory',
                                   M.DEFAULT_SESSION:match('.+[/\\]') or '',
                                   '--with-file',
                                   M.DEFAULT_SESSION:match('[^/\\]+$') or '',
                                   '--no-newline')
  if #utf8_filename > 0 then M.save(utf8_filename:iconv(_CHARSET, 'UTF-8')) end
end

events.connect(events.QUIT,
               function() if M.SAVE_ON_QUIT then M.save() end end, 1)

local function no_session() M.SAVE_ON_QUIT = false end
args.register('-n', '--nosession', 0, no_session, 'No session functionality')

return M

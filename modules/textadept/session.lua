-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local locale = _G.locale

---
-- Session support for the textadept module.
module('_m.textadept.session', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `DEFAULT_SESSION`: The path to the default session file.
-- * `SAVE_ON_QUIT`: Save the session when quitting. Defaults to true and can be
--   disabled by passing the command line switch '-ns' or '--no-session' to
--   Textadept.

-- settings
DEFAULT_SESSION = _USERHOME..'/session'
SAVE_ON_QUIT = true
-- end settings

local lfs = require 'lfs'

---
-- Loads a Textadept session file.
-- Textadept restores split views, opened buffers, cursor information, and
-- project manager details.
-- @param filename The absolute path to the session file to load. Defaults to
--   DEFAULT_SESSION if not specified.
-- @return true if the session file was opened and read; false otherwise.
-- @usage _m.textadept.session.load(filename)
function load(filename)
  local not_found = {}
  local f = io.open(filename or DEFAULT_SESSION, 'rb')
  if not f then
    if not io.close_all() then return false end
  end
  if not f then return false end
  local current_view, splits = 1, { [0] = {} }
  for line in f:lines() do
    if line:find('^buffer:') then
      local anchor, current_pos, first_visible_line, filename =
        line:match('^buffer: (%d+) (%d+) (%d+) (.+)$')
      if not filename:find('^%[.+%]$') then
        if lfs.attributes(filename) then
          io.open_file(filename)
        else
          not_found[#not_found + 1] = filename
        end
      else
        new_buffer()
        buffer._type = filename
        events.emit('file_opened', filename)
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
      local view_idx = line:match('^current_view: (%d+)')
      current_view = tonumber(view_idx) or 1
    end
    if line:find('^size:') then
      local width, height = line:match('^size: (%d+) (%d+)$')
      if width and height then gui.size = { width, height } end
    end
  end
  f:close()
  _VIEWS[current_view]:focus()
  _SESSIONFILE = filename or DEFAULT_SESSION
  if #not_found > 0 then
    gui.dialog('msgbox',
               '--title', locale.M_SESSION_FILES_NOT_FOUND_TITLE,
               '--text', locale.M_SESSION_FILES_NOT_FOUND_TEXT,
               '--informative-text',
                 string.format('%s', table.concat(not_found, '\n')))
  end
  return true
end

---
-- Saves a Textadept session to a file.
-- Saves split views, opened buffers, cursor information, and project manager
-- details.
-- @param filename The absolute path to the session file to save. Defaults to
--   either the current session file or DEFAULT_SESSION if not specified.
-- @usage _m.textadept.session.save(filename)
function save(filename)
  local session = {}
  local buffer_line = "buffer: %d %d %d %s" -- anchor, cursor, line, filename
  local split_line = "%ssplit%d: %s %d" -- level, number, type, size
  local view_line = "%sview%d: %d" -- level, number, doc index
  -- Write out opened buffers.
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type
    if filename then
      local current = buffer.doc_pointer == gui.focused_doc_pointer
      local anchor = current and 'anchor' or '_anchor'
      local current_pos = current and 'current_pos' or '_current_pos'
      local first_visible_line =
        current and 'first_visible_line' or '_first_visible_line'
      session[#session + 1] =
        buffer_line:format(buffer[anchor] or 0, buffer[current_pos] or 0,
                           buffer[first_visible_line] or 0, filename)
    end
  end
  -- Write out split views.
  local function write_split(split, level, number)
    local c1, c2 = split[1], split[2]
    local vertical, size = tostring(split.vertical), split.size
    local spaces = (' '):rep(level)
    session[#session + 1] = split_line:format(spaces, number, vertical, size)
    spaces = (' '):rep(level + 1)
    if type(c1) == 'table' then
      write_split(c1, level + 1, 1)
    else
      session[#session + 1] = view_line:format(spaces, 1, c1)
    end
    if type(c2) == 'table' then
      write_split(c2, level + 1, 2)
    else
      session[#session + 1] = view_line:format(spaces, 2, c2)
    end
  end
  local splits = gui.get_split_table()
  if type(splits) == 'table' then
    write_split(splits, 0, 0)
  else
    session[#session + 1] = view_line:format('', 1, splits)
  end
  -- Write out the current focused view.
  local current_view = view
  for i = 1, #_VIEWS do
    if _VIEWS[i] == current_view then
      current_view = i
      break
    end
  end
  session[#session + 1] = ("current_view: %d"):format(current_view)
  -- Write out other things.
  local size = gui.size
  session[#session + 1] = ("size: %d %d"):format(size[1], size[2])
  -- Write the session.
  local f =
    io.open(filename or _SESSIONFILE or DEFAULT_SESSION, 'wb')
  if f then
    f:write(table.concat(session, '\n'))
    f:close()
  end
end

events.connect('quit', function() if SAVE_ON_QUIT then save() end end, 1)

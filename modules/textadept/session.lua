-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
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

---
-- Loads a Textadept session file.
-- Textadept restores split views, opened buffers, cursor information, and
-- project manager details.
-- @param filename The absolute path to the session file to load. Defaults to
--   DEFAULT_SESSION if not specified.
-- @param only_pm Flag indicating whether or not to load only the Project
--   Manager session settings. Defaults to false.
-- @return true if the session file was opened and read; false otherwise.
-- @usage _m.textadept.session.load(filename)
function load(filename, only_pm)
  local f = io.open(filename or DEFAULT_SESSION, 'rb')
  if not only_pm and not f then
    if not textadept.io.close_all() then return false end
  end
  if not f then return false end
  local current_view, splits = 1, { [0] = {} }
  for line in f:lines() do
    if not only_pm then
      if line:find('^buffer:') then
        local anchor, current_pos, first_visible_line, filename =
          line:match('^buffer: (%d+) (%d+) (%d+) (.+)$')
        if not filename:find('^%[.+%]$') then
          textadept.io.open(filename or '')
        else
          textadept.new_buffer()
          buffer._type = filename
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
        if buf_idx > #textadept.buffers then buf_idx = #textadept.buffers end
        view:goto_buffer(buf_idx)
      elseif line:find('^current_view:') then
        local view_idx = line:match('^current_view: (%d+)')
        current_view = tonumber(view_idx) or 1
      end
    end
    if line:find('^size:') then
      local width, height = line:match('^size: (%d+) (%d+)$')
      if width and height then textadept.size = { width, height } end
    elseif line:find('^pm:') then
      local width, cursor, text = line:match('^pm: (%d+) ([%d:]+) (.*)$')
      textadept.pm.width = width or 0
      textadept.pm.entry_text = text or ''
      textadept.pm.activate()
      if cursor then textadept.pm.cursor = cursor end
    end
  end
  f:close()
  textadept.views[current_view]:focus()
  textadept.session_file = filename or DEFAULT_SESSION
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
  for _, buffer in ipairs(textadept.buffers) do
    local filename = buffer.filename or buffer._type
    if filename then
      local current = buffer.doc_pointer == textadept.focused_doc_pointer
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
  local splits = textadept.get_split_table()
  if type(splits) == 'table' then
    write_split(splits, 0, 0)
  else
    session[#session + 1] = view_line:format('', 1, splits)
  end
  -- Write out the current focused view.
  local current_view = view
  for index, view in ipairs(textadept.views) do
    if view == current_view then
      current_view = index
      break
    end
  end
  session[#session + 1] = ("current_view: %d"):format(current_view)
  -- Write out other things.
  local size = textadept.size
  session[#session + 1] = ("size: %d %d"):format(size[1], size[2])
  local pm = textadept.pm
  session[#session + 1] =
    ("pm: %d %s %s"):format(pm.width, pm.cursor or '0', pm.entry_text)
  -- Write the session.
  local f = io.open(filename or textadept.session_file or DEFAULT_SESSION, 'wb')
  if f then
    f:write(table.concat(session, '\n'))
    f:close()
  end
end

textadept.events.add_handler('quit',
                             function() if SAVE_ON_QUIT then save() end end, 1)

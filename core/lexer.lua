-- Copyright 2007-2023 Mitchell. See LICENSE.

--- @module lexer
local M = dofile(_HOME .. '/lexers/lexer.lua')

--- A ';'-separated list of directory paths that contain lexers for syntax highlighting.
_G._LEXERPATH = string.format('%s/lexers;%s/lexers', _USERHOME, _HOME)

M.property = setmetatable({}, {__index = function() return '' end}) -- avoid auto-initialization
local names = M.names
M.names = function(path) return names(path or _LEXERPATH) end

---
-- Emitted after loading a language lexer.
-- This is useful for automatically loading language modules as source files are opened, or
-- setting up language-specific editing features for source files.
-- Arguments:
--
--   - *name*: The language lexer's name.
_G.events.LEXER_LOADED = 'lexer_loaded'

-- LuaDoc is in core/.buffer.luadoc.
local function get_lexer(buffer, current)
  if not current then return buffer.lexer_language end
  local style_at, name_of_style = buffer.style_at, buffer.name_of_style
  local pos = buffer.current_pos
  while pos > 0 do
    local style = style_at[pos]
    local lang = name_of_style(buffer, style):match('^whitespace%.(.+)$')
    if lang then return lang end
    repeat pos = pos - 1 until pos < 1 or style_at[pos] ~= style
  end
  return buffer.lexer_language
end

-- LuaDoc is in core/.buffer.luadoc.
-- Note: cannot use `M.` references here since these buffer functions persist through reset
-- (thus referencing the original, unreset `M` upvalue).
local function set_lexer(buffer, name)
  if not assert_type(name, 'string/nil', 2) then
    name = lexer.detect(buffer.filename or '', buffer:get_line(1):sub(1, 128)) or 'text'
  end

  -- Setup the lexer.
  for k in pairs(lexer.property) do lexer.property[k] = nil end -- clear existing properties
  lexer.property['scintillua.lexers'] = _LEXERPATH
  rawset(buffer, 'lexer', lexer.load(name))
  rawset(buffer, 'lexer_language', name)
  rawset(buffer, 'named_styles', #buffer.lexer._TAGS)
  if buffer.lexer._CHILDREN then
    local ws = {} -- style numbers considered to be whitespace styles in multi-language lexers
    for i = 1, view.STYLE_MAX do ws[i] = buffer:name_of_style(i):find('whitespace') ~= nil end
    if #ws > 0 then buffer._ws = ws end
  end

  -- Update styles, forward folding properties to the lexer, copy lexer-specific properties to
  -- the buffer, and refresh syntax highlighting.
  if view.set_styles then view.set_styles(buffer ~= ui.command_entry and view or ui.command_entry) end
  for k, v in pairs(view) do
    if not k:find('^fold') then goto continue end
    lexer.property[(k ~= 'folding' and k:gsub('_', '.') or 'fold'):gsub('^fold%.',
      'fold.scintillua.')] = v and '1' or '0'
    ::continue::
  end
  for k in pairs(buffer.property) do buffer.property[k] = nil end
  for k, v in pairs(lexer.property) do buffer.property[k] = v end
  local last_line = view.first_visible_line + view.lines_on_screen
  buffer:colorize(1, buffer:position_from_line(last_line + 1))

  if buffer ~= ui.command_entry then events.emit(events.LEXER_LOADED, name) end
  events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT) -- for updating statusbar
end

-- Documentation is in core/.buffer.luadoc.
local function name_of_style(buffer, style_num)
  return buffer.lexer._TAGS[assert_type(style_num, 'number', 2)] or 'Unknown'
end

-- Documentation is in core/.buffer.luadoc.
local function style_of_name(buffer, name)
  return buffer.lexer._TAGS[assert_type(name, 'string', 2):gsub('_', '.')] or view.STYLE_DEFAULT
end

-- Performs syntax highlighting as needed.
-- Start from the beginning of the current style so the lexer can match the tag.
-- For multilang lexers, start at whitespace since embedded languages have whitespace.[lang]
-- styles. This is so the lexer can start matching child languages instead of parent ones
-- if necessary.
events.connect(events.STYLE_NEEDED, function(pos, buffer)
  local s = buffer:position_from_line(buffer:line_from_position(buffer.end_styled))
  local style_at, ws = buffer.style_at, buffer._ws
  local init_style = s > 1 and style_at[s - 1] or view.STYLE_DEFAULT
  while s > 1 and style_at[s - 1] == init_style do s = s - 1 end
  if ws then while s > 1 and not ws[style_at[s]] do s = s - 1 end end

  -- Setup buffer-specific lexer fields.
  local name_of_style, line_from_position = buffer.name_of_style, buffer.line_from_position
  lexer.style_at = setmetatable({}, {
    __index = function(_, pos) return name_of_style(buffer, style_at[s + pos - 1]) end
  })
  rawset(lexer, 'fold_level', buffer.fold_level) -- override legacy compatibility
  lexer.line_from_position = function(pos) return line_from_position(buffer, s + pos - 1) end
  lexer.line_state, lexer.indent_amount = buffer.line_state, buffer.line_indentation

  -- Invoke the lexer and style text from the returned table of tags.
  buffer:start_styling(s, 0)
  local ok, styles = xpcall(lexer.lex, debug.traceback, buffer.lexer, buffer:text_range(s, pos),
    init_style)
  if not ok then
    buffer:set_styling(pos - s, view.STYLE_DEFAULT)
    events.emit(events.ERROR, styles)
    return
  end
  local set_styling, tags, p = buffer.set_styling, buffer.lexer._TAGS, 1
  for i = 1, #styles, 2 do
    local e = styles[i + 1]
    set_styling(buffer, e - p, tags[styles[i]])
    p = e
  end
  buffer:set_styling(pos - (s + p - 1), view.STYLE_DEFAULT)

  -- Invoke the folder and fold the text from the returned table of fold levels.
  local line = buffer:line_from_position(s)
  s = buffer:position_from_line(line)
  local level = buffer.fold_level[line] & buffer.FOLDLEVELNUMBERMASK
  local folds = lexer.fold(buffer.lexer, buffer:text_range(s, pos), line, level)
  for line, level in pairs(folds) do buffer.fold_level[line] = level end
end)

-- Gives new buffers lexer-specific functions and sets a default lexer.
events.connect(events.BUFFER_NEW, function()
  rawset(buffer, 'property', setmetatable({}, {__index = function() return '' end}))
  buffer.get_lexer, buffer.set_lexer = get_lexer, set_lexer
  buffer.name_of_style, buffer.style_of_name = name_of_style, style_of_name
  set_lexer(buffer, 'text')
end)

-- Refreshes styles for the buffer's lexer.
local function refresh_styles() if view.set_styles then view:set_styles() end end
events.connect(events.BUFFER_AFTER_SWITCH, refresh_styles)
events.connect(events.VIEW_AFTER_SWITCH, refresh_styles)
events.connect(events.VIEW_NEW, refresh_styles)

return M

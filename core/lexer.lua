-- Copyright 2007-2023 Mitchell. See LICENSE.

_LEXERPATH = string.format('%s/lexers;%s/lexers', _USERHOME, _HOME)

local lexer = dofile(_HOME .. '/lexers/lexer.lua')

local M = {}
-- Import detect* and tag names.
for k, v in pairs(lexer) do if k:find('^detect') or k:find('^%u') then M[k] = v end end

-- Events.
events.LEXER_LOADED = 'lexer_loaded'

-- LuaDoc is in core/.buffer.luadoc.
local function get_lexer(buffer, current)
  if not current then return buffer.lexer_language end
  local name_of_style, style_at = buffer.name_of_style, buffer.style_at
  local pos = buffer.current_pos
  while pos > 0 do
    local style = style_at[pos]
    local lang = name_of_style(style):match('^whitespace%.(.+)$')
    if lang then return lang end
    repeat pos = pos - 1 until pos < 1 or style_at[pos] ~= style
  end
  return buffer.lexer_language
end

-- LuaDoc is in core/.buffer.luadoc.
local function set_lexer(buffer, name)
  if not assert_type(name, 'string/nil', 2) then
    name = lexer.detect(buffer.filename or '', buffer:get_line(1):sub(1, 128)) or 'text'
  end
  if name == buffer.lexer_language then
    if view.set_styles then view:set_styles() end
    return -- no change
  end

  -- Set the lexer and check for errors.
  buffer.i_lexer = name
  local errmsg = view.property['lexer.scintillua.error']
  if #errmsg > 0 then
    buffer.i_lexer = 'text'
    error(errmsg, 2)
  end
  buffer._lexer = name

  -- Update styles, forward folding properties to the lexer, and refresh syntax highlighting.
  if view.set_styles then view.set_styles(buffer ~= ui.command_entry and view or ui.command_entry) end
  for k, v in pairs(view) do
    if not k:find('^fold') then goto continue end
    view.property[(k ~= 'folding' and k:gsub('_', '.') or 'fold'):gsub('^fold%.', 'fold.scintillua.')] =
      v and '1' or '0'
    ::continue::
  end
  local last_line = view.first_visible_line + view.lines_on_screen
  buffer:colorize(1, buffer:position_from_line(last_line + 1))

  -- Load language-specific module and emit events.
  if package.searchpath(name, package.path) then _M[name] = require(name) end
  if buffer ~= ui.command_entry then events.emit(events.LEXER_LOADED, name) end

  events.emit(events.UPDATE_UI, 1) -- for updating statusbar
end

-- Gives new buffers lexer-specific functions.
events.connect(events.BUFFER_NEW,
  function() buffer.get_lexer, buffer.set_lexer = get_lexer, set_lexer end, 1)

-- Restores the buffer's lexer, primarily for the side-effect of emitting `events.LEXER_LOADED`.
local function restore_lexer() if buffer.set_lexer then buffer:set_lexer(buffer._lexer) end end
events.connect(events.BUFFER_AFTER_SWITCH, restore_lexer, 1)
events.connect(events.BUFFER_NEW, restore_lexer) -- emit for 'text'
events.connect(events.VIEW_AFTER_SWITCH, restore_lexer)
events.connect(events.VIEW_NEW, restore_lexer)

return M

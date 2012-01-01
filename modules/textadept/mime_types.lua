-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Handles file-specific settings.
module('_m.textadept.mime_types')]]

-- Markdown:
-- ## Overview
--
-- This module adds an extra function to `buffer`:
--
-- * **buffer:set\_lexer** (language)<br />
--   Replacement for [`buffer:set_lexer_language()`][buffer_set_lexer_language].
--   <br /> Sets a `buffer._lexer` field so it can be restored without querying
--   the mime-types tables. Also if the user manually sets the lexer, it should
--   be restored.<br />
--   Loads the language-specific module if it exists.
--       - lang: The string language to set.
--
-- [buffer_set_lexer_language]: buffer.html#buffer:set_lexer_language
--
-- ## Mime-type Events
--
-- * `_G.events.LANGUAGE_MODULE_LOADED`: Called when loading a language-specific
--   module. This is useful for overriding its key commands since they are not
--   available when Textadept starts. Arguments:<br />
--       * `lang`: The language lexer name.

-- Events.
local events, events_connect = events, events.connect
events.LANGUAGE_MODULE_LOADED = 'language_module_loaded'

---
-- File extensions with their associated lexers.
-- @class table
-- @name extensions
M.extensions = {}

---
-- Shebang words and their associated lexers.
-- @class table
-- @name shebangs
M.shebangs = {}

---
-- First-line patterns and their associated lexers.
-- @class table
-- @name patterns
M.patterns = {}

-- Load mime-types from `modules/textadept/mime_types.conf`.
local mime_types
local f = io.open(_HOME..'/modules/textadept/mime_types.conf', 'rb')
if f then
  mime_types = f:read('*all')
  f:close()
end
f = io.open(_USERHOME..'/mime_types.conf', 'rb')
if f then
  mime_types = mime_types..'\n'..f:read('*all')
  f:close()
end
for line in mime_types:gmatch('[^\r\n]+') do
  if not line:find('^%s*%%') then
    if line:find('^%s*[^#/]') then -- extension definition
      local ext, lexer_name = line:match('^%s*(.+)%s+(%S+)$')
      if ext and lexer_name then M.extensions[ext] = lexer_name end
    else -- shebang or pattern
      local ch, text, lexer_name = line:match('^%s*([#/])(.+)%s+(%S+)$')
      if ch and text and lexer_name then
        (ch == '#' and M.shebangs or M.patterns)[text] = lexer_name
      end
    end
  end
end

---
-- List of detected lexers.
-- Lexers are read from `lexers/` and `~/.textadept/lexers/`.
-- @class table
-- @name lexers
M.lexers = {}

-- Generate lexer list
local lexers_found = {}
for lexer in lfs.dir(_HOME..'/lexers') do
  if lexer:find('%.lua$') and lexer ~= 'lexer.lua' then
    lexers_found[lexer:match('^(.+)%.lua$')] = true
  end
end
if lfs.attributes(_USERHOME..'/lexers') then
  for lexer in lfs.dir(_USERHOME..'/lexers') do
    if lexer:find('%.lua$') and lexer ~= 'lexer.lua' then
      lexers_found[lexer:match('^(.+)%.lua$')] = true
    end
  end
end
for lexer in pairs(lexers_found) do M.lexers[#M.lexers + 1] = lexer end
table.sort(M.lexers)

---
-- Prompts the user to select a lexer from a filtered list for the current
-- buffer.
-- @name select_lexer
function M.select_lexer()
  local lexer = gui.filteredlist(_L['Select Lexer'], _L['Name'], M.lexers)
  if lexer then buffer:set_lexer(lexer) end
end

-- LuaDoc is in core/.buffer.luadoc.
local function get_style_name(buffer, style_num)
  buffer:check_global()
  if style_num < 0 or style_num > 255 then error('0 <= style_num < 256') end
  return buffer:private_lexer_call(style_num)
end

-- Contains the whitespace styles for lexers.
-- These whitespace styles are used to determine the lexer at the current caret
-- position since the styles have the name `[lang]_whitespace`.
-- @class table
-- @name ws_styles
local ws_styles = {}
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.functions.set_lexer_language[1]
-- LuaDoc is in core/.buffer.luadoc.
local function set_lexer(buffer, lang)
  buffer:check_global()
  buffer._lexer = lang
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, lang)
  if package.searchpath(lang, package.path) then
    _m[lang] = require(lang)
    local post_init = lang..'.post_init'
    if package.searchpath(post_init, package.path) then require(post_init) end
    _m[lang].set_buffer_properties()
    events.emit(events.LANGUAGE_MODULE_LOADED, lang)
  end
  buffer:colourise(0, -1)
  -- Create the ws_styles[lexer] lookup table for `get_lexer()`.
  if ws_styles[lang] then return end
  local ws = {}
  for i = 0, 255 do
    ws[i] = buffer:private_lexer_call(i):find('whitespace') ~= nil
  end
  ws_styles[lang] = ws
end

local GETLEXERLANGUAGE = _SCINTILLA.functions.get_lexer_language[1]
-- LuaDoc is in core/.buffer.luadoc.
local function get_lexer(buffer, current)
  buffer:check_global()
  local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE)
  if not current then return lexer end
  local i, ws, style_at = buffer.current_pos, ws_styles[lexer], buffer.style_at
  if ws then while i > 0 and not ws[style_at[i]] do i = i - 1 end end
  return get_style_name(buffer, style_at[i]):match('^(.+)_whitespace$') or lexer
end

events_connect(events.BUFFER_NEW, function()
  buffer.set_lexer, buffer.get_lexer = set_lexer, get_lexer
  buffer.get_style_name = get_style_name
end, 1)
-- Scintilla's first buffer does not have these.
if not RESETTING then
  buffer.set_lexer, buffer.get_lexer = set_lexer, get_lexer
  buffer.get_style_name = get_style_name
end

-- Performs actions suitable for a new buffer.
-- Sets the buffer's lexer language and loads the language module.
local function handle_new()
  local lexer
  local line = buffer:get_line(0)
  if line:find('^#!') then
    for word in line:gsub('[/\\]', ' '):gmatch('%S+') do
      lexer = M.shebangs[word]
      if lexer then break end
    end
  end
  if not lexer then
    for patt, lex in pairs(M.patterns) do
      if line:find(patt) then lexer = lex break end
    end
  end
  if not lexer and buffer.filename then
    lexer = M.extensions[buffer.filename:match('[^/\\.]+$')]
  end
  buffer:set_lexer(lexer or 'container')
end
events_connect(events.FILE_OPENED, handle_new)
events_connect(events.FILE_SAVED_AS, handle_new)

-- Sets the buffer's lexer based on filename, shebang words, or
-- first line pattern.
local function restore_lexer()
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, buffer._lexer or 'container')
end
events_connect(events.BUFFER_AFTER_SWITCH, restore_lexer)
events_connect(events.VIEW_NEW, restore_lexer, 1)

events_connect(events.RESET_AFTER,
               function() buffer:set_lexer(buffer._lexer or 'container') end)

return M

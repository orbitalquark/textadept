-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = _G.locale.localize
local events = _G.events

---
-- Handles file-specific settings.
module('_m.textadept.mime_types', package.seeall)

-- Markdown:
-- ## Overview
--
-- This module adds an extra function to `buffer`:
--
-- * **buffer:set\_lexer** (language)<br />
--   Replacement for [`buffer:set_lexer_language()`][buffer_set_lexer_language].
--   <br /> Sets a buffer._lexer field so it can be restored without querying
--   the mime-types tables. Also if the user manually sets the lexer, it should
--   be restored.<br />
--   Loads the language-specific module if it exists.
--       - lang: The string language to set.
--
-- [buffer_set_lexer_language]: buffer.html#buffer:set_lexer_language
--
-- ## Events
--
-- The following is a list of all mime-type events generated in
-- `event_name(arguments)` format:
--
-- * **language\_module\_loaded** (lang)<br />
--   Called when a language-specific module is loaded. This is useful for
--   overriding its key commands since they are not available when Textadept
--   starts.
--     - lang: The language lexer name.

---
-- File extensions with their associated lexers.
-- @class table
-- @name extensions
extensions = {}

---
-- Shebang words and their associated lexers.
-- @class table
-- @name shebangs
shebangs = {}

---
-- First-line patterns and their associated lexers.
-- @class table
-- @name patterns
patterns = {}

-- Load mime-types from mime_types.conf
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
      if ext and lexer_name then extensions[ext] = lexer_name end
    else -- shebang or pattern
      local ch, text, lexer_name = line:match('^%s*([#/])(.+)%s+(%S+)$')
      if ch and text and lexer_name then
        (ch == '#' and shebangs or patterns)[text] = lexer_name
      end
    end
  end
end

---
-- List of detected lexers.
-- Lexers are read from `lexers/` and `~/.textadept/lexers/`.
-- @class table
-- @name lexers
lexers = {}

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
for lexer in pairs(lexers_found) do lexers[#lexers + 1] = lexer end
table.sort(lexers)

local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.functions.set_lexer_language[1]
--
-- Replacement for buffer:set_lexer_language().
-- Sets a buffer._lexer field so it can be restored without querying the
-- mime-types tables. Also if the user manually sets the lexer, it should be
-- restored.
-- Loads the language-specific module if it exists.
-- @param buffer The buffer to set the lexer language of.
-- @param lang The string language to set.
-- @usage buffer:set_lexer('language_name')
local function set_lexer(buffer, lang)
  gui.check_focused_buffer(buffer)
  buffer._lexer = lang
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, lang)
  local ret, err = pcall(require, lang)
  if ret then
    ret, err = pcall(require, lang..'.post_init')
    _m[lang].set_buffer_properties()
    events.emit('language_module_loaded', lang)
  end
  local module_not_found = "^module '"..lang.."[^\']*' not found:"
  if not ret and not err:find(module_not_found) then error(err) end
  buffer:colourise(0, -1)
end

local GETLEXERLANGUAGE = _SCINTILLA.functions.get_lexer_language[1]
--
-- Replacement for buffer:get_lexer_language().
-- @param buffer The buffer to get the lexer language of.
local function get_lexer(buffer)
  gui.check_focused_buffer(buffer)
  return buffer:private_lexer_call(GETLEXERLANGUAGE)
end

--
-- Returns the name of the style associated with a style number.
-- @param buffer The buffer to get the style name of.
-- @param style_num A style number in the range 0 <= style_num < 256.
-- @see buffer.style_at
local function get_style_name(buffer, style_num)
  gui.check_focused_buffer(buffer)
  if style_num < 0 or style_num > 255 then error('0 <= style_num < 256') end
  return buffer:private_lexer_call(style_num)
end

events.connect('buffer_new', function()
  buffer.set_lexer, buffer.get_lexer = set_lexer, get_lexer
  buffer.get_style_name = get_style_name
end, 1)
-- Scintilla's first buffer doesn't have these.
if not RESETTING then
  buffer.set_lexer, buffer.get_lexer = set_lexer, get_lexer
  buffer.get_style_name = get_style_name
end

-- Performs actions suitable for a new buffer.
-- Sets the buffer's lexer language and loads the language module.
local function handle_new()
  local lexer
  if buffer.filename then
    lexer = extensions[buffer.filename:match('[^/\\.]+$')]
  end
  if not lexer then
    local line = buffer:get_line(0)
    if line:find('^#!') then
      for word in line:gsub('[/\\]', ' '):gmatch('%S+') do
        lexer = shebangs[word]
        if lexer then break end
      end
    end
    if not lexer then
      for patt, lex in pairs(patterns) do
        if line:find(patt) then
          lexer = lex
          break
        end
      end
    end
  end
  buffer:set_lexer(lexer or 'container')
end

-- Sets the buffer's lexer based on filename, shebang words, or
-- first line pattern.
local function restore_lexer()
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, buffer._lexer or 'container')
end

local connect = events.connect
connect('file_opened', handle_new)
connect('file_saved_as', handle_new)
connect('buffer_after_switch', restore_lexer)
connect('view_new', restore_lexer, 1)
connect('reset_after',
        function() buffer:set_lexer(buffer._lexer or 'container') end)

---
-- Prompts the user to select a lexer from a filtered list for the current
-- buffer.
function select_lexer()
  local lexer = gui.filteredlist(L('Select Lexer'), 'Name', lexers)
  if lexer then buffer:set_lexer(lexer) end
end

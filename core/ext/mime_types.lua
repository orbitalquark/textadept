-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Handles file-specific settings.
module('textadept.mime_types', package.seeall)

-- Markdown:
-- ## Overview
--
-- Files can be recognized and associated with programming language lexers in
-- three ways:
--
-- * By file extension.
-- * By keywords in the file's shebang (`#!/path/to/exe`) line.
-- * By a pattern that matches the file's first line.
--
-- If a lexer is not associated with a file you open, first make sure the lexer
-- exists in `lexers/`. If it does not, you will need to write one. Consult the
-- [lexer][lexer] module for a tutorial.
--
-- [lexer]: ../modules/lexer.html
--
-- ## Configuration File
--
-- `core/ext/mime_types.conf` is the configuration file for mime-type detection.
--
-- #### Detection by File Extension
--
--     file_ext lexer
--
-- Note: `file_ext` should not start with a `.` (period).
--
-- #### Detection by Shebang Keywords
--
--     #shebang_word lexer
--
-- Examples of `shebang_word`'s are `lua`, `ruby`, `python`.
--
-- #### Detection by Pattern
--
--     /pattern lexer
--
-- Only the last space, the one separating the pattern from the lexer, is
-- significant. No spaces in the pattern need to be escaped.
--
-- ## Extras
--
-- This module adds an extra function to `buffer`:
--
-- * **buffer:set\_lexer** (language)<br />
--   Replacement for [`buffer:set_lexer_language()`][buffer_set_lexer_language].<br />
--   Sets a buffer._lexer field so it can be restored without querying the
--   mime-types tables. Also if the user manually sets the lexer, it should be
--   restored.<br />
--   Loads the language-specific module if it exists.
--       - lang: The string language to set.
--
-- [buffer_set_lexer_language]: buffer.html#buffer:set_lexer_language

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
local f = io.open(_HOME..'/core/ext/mime_types.conf', 'rb')
if f then
  for line in f:lines() do
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
  f:close()
end

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
  buffer._lexer = lang
  buffer:set_lexer_language(lang)
  if buffer.filename then
    local ret, err = pcall(require, lang)
    if ret then
      _m[lang].set_buffer_properties()
    elseif not ret and not err:find("^module '"..lang.."' not found:") then
      error(err)
    end
  end
end
textadept.events.add_handler('buffer_new',
  function() buffer.set_lexer = set_lexer end)

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
  buffer:set_lexer_language(buffer._lexer or 'container')
end

textadept.events.add_handler('file_opened', handle_new)
textadept.events.add_handler('file_saved_as', handle_new)
textadept.events.add_handler('buffer_after_switch', restore_lexer)
textadept.events.add_handler('view_new', restore_lexer)

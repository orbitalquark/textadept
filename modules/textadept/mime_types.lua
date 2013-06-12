-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Handles file type detection for Textadept.
-- @field _G.events.LANGUAGE_MODULE_LOADED (string)
--   Emitted after loading a language-specific module.
--   This is useful for overriding a language-specific module's key bindings
--   or other properties since the module is not loaded when Textadept starts.
--   Arguments:
--
--   * *`lang`*: The language lexer name.
module('_M.textadept.mime_types')]]

-- Events.
events.LANGUAGE_MODULE_LOADED = 'language_module_loaded'

---
-- Map of file extensions (excluding the leading '.') to their associated
-- lexers.
-- If the file type is not recognized by shebang words or first-line patterns,
-- each file extension is matched against the file's extension.
-- @class table
-- @name extensions
M.extensions = {}

---
-- Map of shebang words to their associated lexers.
-- If the file has a shebang line, a line that starts with "#!" and is the first
-- line in the file, each shebang word is matched against that line.
-- @class table
-- @name shebangs
M.shebangs = {}

---
-- Map of first-line patterns to their associated lexers.
-- If a file type is not recognized by shebang words, each pattern is matched
-- against the first line in the file.
-- @class table
-- @name patterns
M.patterns = {}

---
-- List of available lexers.
-- @class table
-- @name lexers
M.lexers = {}

local GETLEXERLANGUAGE = _SCINTILLA.properties.lexer_language[1]
-- LuaDoc is in core/.buffer.luadoc.
local function get_lexer(buffer, current)
  buffer:check_global()
  local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE)
  return current and lexer:match('[^/]+$') or lexer:match('^[^/]+')
end

local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.properties.lexer_language[2]
-- LuaDoc is in core/.buffer.luadoc.
local function set_lexer(buffer, lang)
  buffer:check_global()

  -- If no language was given, attempt to detect it.
  if not lang then
    local line = buffer:get_line(0)
    -- Detect from shebang line.
    if line:find('^#!') then
      for word in line:gsub('[/\\]', ' '):gmatch('%S+') do
        if M.shebangs[word] then lang = M.shebangs[word] break end
      end
    end
    -- Detect from first line.
    if not lang then
      for patt, lexer in pairs(M.patterns) do
        if line:find(patt) then lang = lexer break end
      end
    end
    -- Detect from file extension.
    if not lang and buffer.filename then
      lang = M.extensions[buffer.filename:match('[^/\\.]+$')]
    end
    if not lang then lang = 'text' end
  end

  -- Set the lexer and load its language-specific module.
  buffer._lexer = lang
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, lang)
  if package.searchpath(lang, package.path) then
    _M[lang] = require(lang)
    local post_init = lang..'.post_init'
    if package.searchpath(post_init, package.path) then require(post_init) end
    events.emit(events.LANGUAGE_MODULE_LOADED, lang)
  end
  local last_line = buffer.first_visible_line + buffer.lines_on_screen
  buffer:colourise(0, buffer:position_from_line(last_line + 1))
end

-- LuaDoc is in core/.buffer.luadoc.
local function get_style_name(buffer, style_num)
  buffer:check_global()
  if style_num < 0 or style_num > 255 then error('0 <= style_num < 256') end
  return buffer:private_lexer_call(style_num)
end

-- Gives new buffers lexer-specific functions.
local function set_lexer_functions()
  buffer.get_lexer, buffer.set_lexer = get_lexer, set_lexer
  buffer.get_style_name = get_style_name
end
events.connect(events.BUFFER_NEW, set_lexer_functions, 1)
-- Scintilla's first buffer does not have these.
if not RESETTING then set_lexer_functions() end

-- Auto-detect lexer on file open or save as.
events.connect(events.FILE_OPENED, function() buffer:set_lexer() end)
events.connect(events.FILE_SAVED_AS, function() buffer:set_lexer() end)

-- Restores the buffer's lexer.
local function restore_lexer() buffer:set_lexer(buffer._lexer) end
events.connect(events.BUFFER_AFTER_SWITCH, restore_lexer)
events.connect(events.VIEW_NEW, restore_lexer)
events.connect(events.RESET_AFTER, restore_lexer)

---
-- Prompts the user to select a lexer for the current buffer.
-- @see buffer.set_lexer
-- @name select_lexer
function M.select_lexer()
  local lexer = gui.filteredlist(_L['Select Lexer'], _L['Name'], M.lexers)
  if lexer then buffer:set_lexer(lexer) end
end

-- Load mime-types.
local function process_line(line)
  if line:find('^%s*%%') then return end
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
local f = io.open(_HOME..'/modules/textadept/mime_types.conf', 'rb')
for line in f:lines() do process_line(line) end
f:close()
f = io.open(_USERHOME..'/mime_types.conf', 'rb')
if f then
  for line in f:lines() do process_line(line) end
  f:close()
end

-- Generate lexer list.
local lexers_found = {}
for _, dir in ipairs{_HOME..'/lexers', _USERHOME..'/lexers'} do
  if lfs.attributes(dir) then
    for lexer in lfs.dir(dir) do
      if lexer:find('%.lua$') and lexer ~= 'lexer.lua' then
        lexers_found[lexer:match('^(.+)%.lua$')] = true
      end
    end
  end
end
for lexer in pairs(lexers_found) do M.lexers[#M.lexers + 1] = lexer end
table.sort(M.lexers)

return M

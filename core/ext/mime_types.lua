-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

--- Handles file-specific settings (based on file extension).
module('textadept.mime_types', package.seeall)

---
-- [Local table] Language names with their associated lexers.
-- @class table
-- @name languages
local languages = {
  cpp = 'cpp',
  css = 'css',
  diff = 'diff',
  html = 'html',
  javascript = 'javascript',
  lua = 'lua',
  makefile = 'makefile',
  php = 'php',
  python = 'python',
  ragel = 'ragel',
  rhtml = 'rhtml',
  ruby = 'ruby',
  xml = 'xml'
}

local l = languages
---
-- [Local table] File extensions with their associated languages.
-- @class table
-- @name extensions
local extensions = {
  c = l.cpp, cpp = l.cpp, cxx = l.cpp, h = l.cpp,
  css = l.css,
  diff = l.diff, patch = l.diff,
  html = l.html, htm = l.html, shtml = l.html,
  iface = l.makefile,
  js = l.javascript,
  lua = l.lua,
  mak = l.makefile, makefile = l.makefile, Makefile = l.makefile,
  php = l.php,
  py = l.python, pyw = l.python,
  rhtml = l.rhtml,
  rb = l.ruby, rbw = l.ruby,
  rl = l.ragel,
  xml = l.xml, xsl = l.xml, xslt = l.xml
}

---
-- [Local table] Shebang words and their associated languages.
-- @class table
-- @name shebangs
local shebangs = {
  lua = l.lua,
  ruby = l.ruby
}

---
-- [Local function] Sets the buffer's lexer language based on a filename.
-- @param filename The filename used to set the lexer language.
-- @return boolean indicating whether or not a lexer language was set.
local function set_lexer_from_filename(filename)
  local lexer
  if filename then
    local ext = filename:match('[^/]+$'):match('[^.]+$')
    lexer = extensions[ext]
  end
  buffer:set_lexer_language(lexer or 'container')
  return lexer
end

---
-- [Local function] Sets the buffer's lexer language based on a shebang line.
local function set_lexer_from_sh_bang()
  local lexer
  local line = buffer:get_line(0)
  if line:match('^#!') then
    line = line:gsub('[\\/]', ' ')
    for word in line:gmatch('%S+') do
      lexer = shebangs[word]
      if lexer then break end
    end
    buffer:set_lexer_language(lexer)
  end
end

---
-- [Local function] Loads a language module based on a filename (if it hasn't
-- been loaded already).
-- @param filename The filename used to load a language module from.
local function load_language_module_from_filename(filename)
  if not filename then return end
  local ext = filename:match('[^/]+$'):match('[^.]+$')
  local lang = extensions[ext]
  if lang then
    local ret, err = pcall(require, lang)
    if ret then
      _m[lang].set_buffer_properties()
    elseif not ret and not err:match("^module '"..lang.."' not found:") then
      textadept.events.error(err)
    end
  end
end

---
-- [Local function] Performs actions suitable for a new buffer.
-- Sets the buffer's lexer language and loads the language module.
local function handle_new()
  local buffer = buffer
  if not set_lexer_from_filename(buffer.filename) then
    set_lexer_from_sh_bang()
  end
  load_language_module_from_filename(buffer.filename)
end

---
-- [Local function] Performs actions suitable for when buffers are switched.
-- Sets the buffer's lexer language.
local function handle_switch()
  if not set_lexer_from_filename(buffer.filename) then
    set_lexer_from_sh_bang()
  end
end

local events = textadept.events
events.add_handler('file_opened', handle_new)
events.add_handler('file_saved_as', handle_new)
events.add_handler('buffer_switch', handle_switch)
events.add_handler('view_new', handle_switch)

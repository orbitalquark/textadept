-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
  rhtml = 'rhtml',
  ruby = 'ruby',
  xml = 'xml'
}

local l = languages
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
  rb = l.rb, rbw = l.rb,
  xml = l.xml, xsl = l.xml, xslt = l.xml
}

---
-- [Local] Sets the buffer's lexer language based on a filename.
-- @param filename The filename used to set the lexer language.
local function set_lexer_from_filename(filename)
  local lexer
  if filename then
    local ext = filename:match('[^/]+$'):match('[^.]+$')
    lexer = extensions[ext]
  end
  buffer:set_lexer_language(lexer or 'container')
end

---
-- [Local] Loads a language module based on a filename (if it hasn't been
-- loaded already).
-- @param filename The filename used to load a language module from.
local function load_language_module_from_filename(filename)
  if not filename then return end
  local ext = filename:match('[^/]+$'):match('[^.]+$')
  local lang = extensions[ext]
  if lang then
    local ret, err = pcall(require, lang)
    if ret then
      modules[lang].set_buffer_properties()
    elseif not ret and not err:match("^module '"..lang.."' not found:") then
      textadept.handlers.error(err)
    end
  end
end

---
-- [Local] Performs actions suitable for a new buffer.
-- Sets the lexer language and loads the language module based on the new
-- buffer's filename.
local function handle_new()
  local buffer = buffer
  set_lexer_from_filename(buffer.filename)
  load_language_module_from_filename(buffer.filename)
end

---
-- [Local] Performs actions suitable for when buffers are switched.
-- Sets the lexer language based on the current buffer's filename.
local function handle_switch()
  set_lexer_from_filename(buffer.filename)
end

local handlers = textadept.handlers
handlers.add_function_to_handler('file_opened', handle_new)
handlers.add_function_to_handler('file_saved_as', handle_new)
handlers.add_function_to_handler('buffer_switch', handle_switch)
handlers.add_function_to_handler('view_new', handle_switch)

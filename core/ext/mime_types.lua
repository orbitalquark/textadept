-- Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

--- Handles file-specific settings (based on file extension).
module('textadept.mime_types', package.seeall)

---
-- [Local table] Language names with their associated lexers.
-- @class table
-- @name languages
local languages = {
  as = 'actionscript',
  ada = 'ada',
  antlr = 'antlr',
  apdl = 'apdl',
  applescript = 'applescript',
  asp = 'asp',
  awk = 'awk',
  batch = 'batch',
  boo = 'boo',
  cpp = 'cpp',
  csharp = 'csharp',
  css = 'css',
  d = 'd',
  diff = 'diff',
  django = 'django',
  eiffel = 'eiffel',
  erlang = 'erlang',
  forth = 'forth',
  fortran = 'fortran',
  gap = 'gap',
  gettext = 'gettext',
  gnuplot = 'gnuplot',
  groovy = 'groovy',
  haskell = 'haskell',
  html = 'html',
  idl = 'idl',
  ini = 'ini',
  io = 'io',
  java = 'java',
  js = 'javascript',
  latex = 'latex',
  lisp = 'lisp',
  lua = 'lua',
  makefile = 'makefile',
  maxima = 'maxima',
  sql = 'sql',
  objc = 'objective_c',
  ocaml = 'ocaml',
  pascal = 'pascal',
  perl = 'perl',
  php = 'php',
  pike = 'pike',
  postscript = 'postscript',
  props = 'props',
  python = 'python',
  r = 'r',
  ragel = 'ragel',
  rebol = 'rebol',
  rexx = 'rexx',
  rhtml = 'rhtml',
  ruby = 'ruby',
  scheme = 'scheme',
  shell = 'shellscript',
  smalltalk = 'smalltalk',
  tcl = 'tcl',
  vala = 'vala',
  verilog = 'verilog',
  vhdl = 'vhdl',
  vb = 'visualbasic',
  xml = 'xml'
}

local l = languages
---
-- [Local table] File extensions with their associated languages.
-- @class table
-- @name extensions
local extensions = {
  -- Actionscript
  as = l.as,
  -- Ada
  ada = l.ada, adb = l.ada, ads = l.ada,
  -- ANTLR
  g = l.antlr,
  -- APDL
  ans = l.apdl,
  inp = l.apdl,
  mac = l.apdl,
  -- Applescript
  applescript = l.applescript,
  -- ASP
  asa = l.asp, asp = l.asp,
  -- AWK
  awk = l.awk,
  -- Batch
  bat = l.batch,
  cmd = l.batch,
  -- Boo
  boo = l.boo,
  -- C/C++
  c = l.cpp, cc = l.cpp, C = l.cpp, cpp = l.cpp, cxx = l.cpp, ['c++'] = l.cpp,
  h = l.cpp, hh = l.cpp, hpp = l.cpp,
  -- C#
  cs = l.csharp,
  -- CSS
  css = l.css,
  -- D
  d = l.d,
  -- Diff
  diff = l.diff,
  patch = l.diff,
  -- Eiffel
  e = l.eiffel, eif = l.eiffel,
  -- Erlang
  erl = l.erlang,
  -- Forth
  f = l.forth, frt = l.forth, fs = l.forth,
  -- Fortran
  ['for'] = l.fortran, fort = l.fortran, f77 = l.fortran, f90 = l.fortran,
    f95 = l.fortran,
  -- Gap
  g = l.gap, gd = l.gap, gi = l.gap, gap = l.gap,
  -- Gettext
  po = l.gettext, pot = l.gettext,
  -- GNUPlot
  dem = l.gnuplot,
  plt = l.gnuplot,
  -- Goovy
  groovy = l.groovy, grv = l.groovy,
  -- Haskell
  hs = l.haskell,
  -- HTML
  htm = l.html, html = l.html,
  shtm = l.html, shtml = l.html,
  -- IDL
  idl = l.idl,
  -- ini
  ini = l.ini,
  reg = l.ini,
  -- Io
  io = l.io,
  -- Java
  bsh = l.java,
  java = l.java,
  -- Javascript
  js = l.js,
  -- Latex
  bbl = l.latex,
  dtx = l.latex,
  ins = l.latex,
  ltx = l.latex,
  tex = l.latex,
  sty = l.latex,
  -- Lisp
  el = l.lisp,
  lisp = l.lisp,
  lsp = l.lisp,
  -- Lua
  lua = l.lua,
  -- Makefile
  GNUmakefile = l.makefile,
  iface = l.makefile,
  mak = l.makefile, makefile = l.makefile, Makefile = l.makefile,
  -- Maxima
  maxima = l.maxima,
  -- Objective C
  m = l.objc,
  objc = l.objc,
  -- OCAML,
  ml = l.ocaml, mli = l.ocaml, mll = l.ocaml, mly = l.ocaml,
  -- Pascal
  dpk = l.pascal, dpr = l.pascal,
  p = l.pascal, pas = l.pascal,
  -- Perl
  al = l.perl,
  perl = l.perl, pl = l.perl, pm = l.perl,
  -- PHP
  inc = l.php,
  php = l.php, php3 = l.php, php4 = l.php, phtml = l.php,
  -- Pike
  pike = l.pike, pmod = l.pike,
  -- Postscript
  eps = l.postscript,
  ps = l.postscript,
  -- Properties
  props = l.props, properties = l.props,
  -- Python
  sc = l.python,
  py = l.python, pyw = l.python,
  -- R
  R = l.r, Rout = l.r, Rhistory = l.r, Rt = l.r, ['Rout.save'] = l.r,
    ['Rout.fail'] = l.r,
  -- Rebol
  r = l.rebol,
  -- Rexx
  orx = l.rexx,
  rex = l.rexx,
  -- RHTML
  rhtml = l.rhtml,
  -- Ruby
  rb = l.ruby, rbw = l.ruby,
  -- Ragel
  rl = l.ragel,
  -- Scheme
  scm = l.scheme,
  -- Shell
  bash = l.shell,
  csh = l.shell,
  sh = l.shell,
  -- Smalltalk
  changes = l.smalltalk,
  st = l.smalltalk, sources = l.smalltalk,
  -- SQL
  sql = l.sql,
  -- TCL
  tcl = l.tcl, tk = l.tk,
  -- Vala
  vala = l.vala,
  -- Verilog
  v = l.verilog, ver = l.verilog,
  -- VHDL
  vh = l.vhdl, vhd = l.vhdl, vhdl = l.vhdl,
  -- Visual Basic
  asa = l.vb,
  bas = l.vb,
  cls = l.vb, ctl = l.vb,
  dob = l.vb, dsm = l.vb, dsr = l.vb,
  frm = l.vb,
  pag = l.vb,
  vb = l.vb, vba = l.vb, vbs = l.vb,
  -- XML
  xhtml = l.xml, xml = l.xml, xsd = l.xml, xsl = l.xml, xslt = l.xml
}

---
-- [Local table] Shebang words and their associated languages.
-- @class table
-- @name shebangs
local shebangs = {
  awk = l.awk,
  lua = l.lua,
  perl = l.perl,
  php = l.php,
  python = l.python,
  ruby = l.ruby,
  sh = l.shell,
}

---
-- [Local table] First-line patterns and their associated languages.
-- @class table
-- @name patterns
local patterns = {
  ['^%s*<%?xml%s'] = l.xml
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
  local line = buffer:get_line(0)
  if line:match('^#!') then
    line = line:gsub('[\\/]', ' ')
    for word in line:gmatch('%S+') do
      if shebangs[word] then
        buffer:set_lexer_language( shebangs[word] )
        return true
      end
    end
  end
end

---
-- [Local function] Sets the buffer's lexer language based on a pattern that
-- matches its first line.
local function set_lexer_from_pattern()
  local line = buffer:get_line(0)
  for patt, lexer in pairs(patterns) do
    if line:match(patt) then
      buffer:set_lexer_language(lexer)
      return true
    end
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
    if not set_lexer_from_sh_bang() then set_lexer_from_pattern() end
  end
end

local events = textadept.events
events.add_handler('file_opened', handle_new)
events.add_handler('file_saved_as', handle_new)
events.add_handler('buffer_switch', handle_switch)
events.add_handler('view_new', handle_switch)

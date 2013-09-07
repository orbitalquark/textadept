-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Handles file type detection for Textadept.
-- @field _G.events.LEXER_LOADED (string)
--   Emitted after loading a language lexer.
--   This is useful for overriding a language module's key bindings or other
--   properties since the module is not loaded when Textadept starts.
--   Arguments:
--
--   * *`lexer`*: The language lexer name.
module('textadept.file_types')]]

-- Events.
events.LEXER_LOADED = 'lexer_loaded'

---
-- Map of file extensions (excluding the leading '.') to their associated
-- lexers.
-- If the file type is not recognized by shebang words or first-line patterns,
-- each file extension is matched against the file's extension.
-- @class table
-- @name extensions
M.extensions = {--[[Actionscript]]as='actionscript',asc='actionscript',--[[ADA]]ada='ada',adb='ada',ads='ada',--[[ANTLR]]g='antlr',--[[APDL]]ans='apdl',inp='apdl',mac='apdl',--[[Applescript]]applescript='applescript',--[[ASP]]asa='asp',asp='asp',hta='asp',--[[AWK]]awk='awk',--[[Batch]]bat='batch',cmd='batch',--[[Bibtex]]bib='bibtex',--[[Boo]]boo='boo',--[[C/C++]]c='cpp',cc='cpp',C='cpp',cpp='cpp',cxx='cpp',['c++']='cpp',h='cpp',hh='cpp',hpp='cpp',hxx='cpp',['h++']='cpp',--[[C#]]cs='csharp',--[[Chuck]]ck='chuck',--[[CMake]]cmake='cmake',['cmake.in']='cmake',ctest='cmake',['ctest.in']='cmake',--[[CoffeeScript]]coffee='coffeescript',--[[CSS]]css='css',--[[CUDA]]cu='cuda',cuh='cuda',--[[D]]d='dmd',di='dmd',--[[Desktop]]desktop='desktop',--[[diff]]diff='diff',patch='diff',--[[dot]]dot='dot',--[[Eiffel]]e='eiffel',eif='eiffel',--[[Erlang]]erl='erlang',hrl='erlang',--[[F#]]fs='fsharp',--[[Forth]]f='forth',forth='forth',frt='forth',fs='forth',--[[Fortran]]['for']='fortran',fort='fortran',fpp='fortran',f77='fortran',f90='fortran',f95='fortran',f03='fortran',f08='fortran',--[[Gap]]g='gap',gd='gap',gi='gap',gap='gap',--[[Gettext]]po='gettext',pot='gettext',--[[GLSL]]glslf='glsl',glslv='glsl',--[[GNUPlot]]dem='gnuplot',plt='gnuplot',--[[Go]]go='go',--[[Groovy]]groovy='groovy',gvy='groovy',--[[Gtkrc]]gtkrc='gtkrc',--[[Haskell]]hs='haskell',--[[HTML]]htm='hypertext',html='hypertext',shtm='hypertext',shtml='hypertext',xhtml='hypertext',--[[IDL]]idl='idl',odl='odl',--[[Inform]]inf='inform',--[[ini]]cfg='ini',cnf='ini',inf='ini',ini='ini',reg='ini',--[[Io]]io='Io',--[[Java]]bsh='java',java='java',--[[Javascript]]js='javascript',jsfl='javascript',--[[JSP]]jsp='jsp',--[[JSON]]json='json',--[[Latex]]bbl='latex',dtx='latex',ins='latex',ltx='latex',tex='latex',sty='latex',--[[Less]]less='less',--[[Lilypond]]lily='lilypond',ly='lilypond',--[[Lisp]]cl='lisp',el='lisp',lisp='lisp',lsp='lisp',--[[Literate Coffeescript]]litcoffee='litcoffee',--[[Lua]]lua='lua',--[[Makefile]]GNUmakefile='makefile',iface='makefile',mak='makefile',makefile='makefile',Makefile='makefile',--[[Markdown]]md='markdown',--[[Nemerle]]n='nemerle',--[[NSIS]]nsh='nsis',nsi='nsis',nsis='nsis',--[[Objective C]]m='objective_c',mm='objective_c',objc='objective_c',--[[OCAML]]caml='caml',ml='caml',mli='caml',mll='caml',mly='caml',--[[Octave]]--[[Pascal]]dpk='pascal',dpr='pascal',p='pascal',pas='pascal',--[[Perl]]al='perl',perl='perl',pl='perl',pm='perl',pod='perl',--[[PHP]]inc='php',php='php',php3='php',php4='php',phtml='php',--[[Pike]]pike='pike',pmod='pike',--[[Postscript]]eps='ps',ps='ps',--[[Prolog]]prolog='prolog',--[[Properties]]props='props',properties='props',--[[Python]]sc='python',py='python',pyw='python',--[[R]]R='rstats',Rout='rstats',Rhistory='rstats',Rt='rstats',['Rout.save']='rstats',['Rout.fail']='rstats',S='rstats',--[[Rebol]]r='rebol',reb='rebol',--[[Rexx]]orx='rexx',rex='rexx',--[[RHTML]]erb='rhtml',rhtml='rhtml',--[[Ruby]]Rakefile='ruby',rake='ruby',rb='ruby',rbw='ruby',--[[Sass CSS]]sass='sass',scss='sass',--[[Scala]]scala='scala',--[[Scheme]]sch='scheme',scm='scheme',--[[Shell]]bash='bash',bashrc='bash',bash_profile='bash',configure='bash',csh='bash',sh='bash',zsh='bash',--[[Smalltalk]]changes='smalltalk',st='smalltalk',sources='smalltalk',--[[SQL]]ddl='sql',sql='sql',--[[TCL]]tcl='tcl',tk='tcl',--[[Vala]]vala='vala',--[[Verilog]]v='verilog',ver='verilog',--[[VHDL]]vh='vhdl',vhd='vhdl',vhdl='vhdl',--[[Visual Basic]]asa='vb',bas='vb',cls='vb',ctl='vb',dob='vb',dsm='vb',dsr='vb',frm='vb',pag='vb',vb='vb',vba='vb',vbs='vb',--[[XML]]dtd='xml',svg='xml',xml='xml',xsd='xml',xsl='xml',xslt='xml',xul='xml'}

---
-- Map of shebang words to their associated lexers.
-- If the file has a shebang line, a line that starts with "#!" and is the first
-- line in the file, each shebang word is matched against that line.
-- @class table
-- @name shebangs
M.shebangs = {awk='awk',lua='lua',octave='matlab',perl='perl',php='php',python='python',ruby='ruby',bash='bash',sh='bash'}

---
-- Map of first-line patterns to their associated lexers.
-- If a file type is not recognized by shebang words, each pattern is matched
-- against the first line in the file.
-- @class table
-- @name patterns
M.patterns = {['^%s*class%s+%S+%s*<%s*ApplicationController']='rails',['^%s*class%s+%S+%s*<%s*ActionController::Base']='rails',['^%s*class%s+%S+%s*<%s*ActiveRecord::Base']='rails',['^%s*class%s+%S+%s*<%s*ActiveRecord::Migration']='rails',['^%s*<%?xml%s']='xml'}

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

  -- Set the lexer and load its language module.
  buffer._lexer = lang
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, lang)
  if package.searchpath(lang, package.path) then
    _M[lang] = require(lang)
    local post_init = lang..'.post_init'
    if package.searchpath(post_init, package.path) then require(post_init) end
  end
  events.emit(events.LEXER_LOADED, lang)
  local last_line = buffer.first_visible_line + buffer.lines_on_screen
  buffer:colourise(0, buffer:position_from_line(last_line + 1))
end

-- Gives new buffers lexer-specific functions.
local function set_lexer_functions()
  buffer.get_lexer, buffer.set_lexer = get_lexer, set_lexer
  buffer.style_name = setmetatable({}, {
    __index = function(t, style_num) -- LuaDoc is in core/.buffer.luadoc
      if style_num < 0 or style_num > 255 then error('0 <= style_num < 256') end
      return buffer:private_lexer_call(style_num)
    end,
    __newindex = function() error('read-only property') end
  })
end
events.connect(events.BUFFER_NEW, set_lexer_functions, 1)

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
  local lexer = ui.filteredlist(_L['Select Lexer'], _L['Name'], M.lexers)
  if lexer then buffer:set_lexer(lexer) end
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

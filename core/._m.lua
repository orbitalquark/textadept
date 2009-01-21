-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global _m table.

---
-- A table of loaded modules.
-- [Dummy file]
module('_m')

-- Usage:
-- Modules utilize the Lua 5.1 package model.
--
-- There are two kinds of modules: generic and language-specific. Both are just
-- single directories full of Lua scripts and maybe additional files. Each
-- module has an init.lua script that loads all of the functionality provided by
-- the module.
--
-- Generic modules are loaded on startup (/init.lua) and available all the time.
--
-- Language-specific modules are loaded when a file with a specific extension is
-- opened or saved and available to that kind of file only. Adding or modifying
-- a language is done in /core/ext/mime_types.lua. Add your language and its
-- associated lexer to the languages table, the language's file extension and
-- associated language to the extensions table, and optionally shebang words
-- with their associated language to the shebangs table.
-- Each module contains the init.lua script, and typically a commands.lua and
-- snippets.lua script. Sometimes .api files can be used by a module. To do so,
-- set an 'api' variable to textadept.io.read_api_file(path, word_chars)'s
-- return value. It will be used for displaying calltips and autocomplete lists
-- by default.
-- You can use the 'modules' Project Manager browser to create and manage
-- language-specific modules.
--
-- When assigning key commands to module functions, do not forget to do so AFTER
-- the function has been defined. Typically key commands are placed at the end
-- of files, like commands.lua in language-specific modules.

---
-- This module contains no functions.
function no_functions()

end

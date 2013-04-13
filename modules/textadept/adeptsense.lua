-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Code autocompletion and documentation support for programming languages.
--
-- ## Overview
--
-- Adeptsense is a form of autocompletion for programming. It has the means to
-- supply a list of potential completions for classes, member functions and
-- fields, packages, etc and display their documentation in the form of a
-- calltip. This document provides the information necessary in order to write a
-- new Adeptsense for a language. For illustrative purposes, an Adeptsense for
-- Lua will be created. More advanced techniques are covered later.
--
-- ## Creating an Adeptsense
--
-- Adeptsenses exist per-language and are typically defined in a
-- [language-specific module][]. First check to see if the module for your
-- language has an Adeptsense. If not, you will need to create one. The language
-- modules included with Textadept have Adeptsenses so they can be used for
-- reference. If your language is similar to any of those languages, you can
-- copy and modify the existing language's Adeptsense, saving some time and
-- effort.
--
-- [language-specific module]: _M.html#Language-Specific.Modules
--
-- ### Terminology
--
-- Not all languages have "classes", "functions", and "fields" in the full sense
-- of the word. Normally classes are referred to as objects in Object Oriented
-- Programming (OOP), functions are class or instance methods,and fields are
-- class or instance properties. For example a "Cat" class may have a "color"
-- field and a "meow" function. To Adeptsense, the term "class" is simply a
-- container for "function" and "field" completions. "functions" and "fields"
-- are only distinguished by an icon in the completion list.
--
-- For Lua, consider modules and tables as "classes", functions as "functions",
-- and module/table keys as "fields".
--
-- ### Introduction
--
-- Open the language-specific module for editing and create a new instance of an
-- Adeptsense.
--
--     $> # from either _HOME or _USERHOME:
--     $> cd modules/lua/
--     $> textadept init.lua
--
--     sense = _M.textadept.adeptsense.new('lua')
--
-- Where 'lua' is replaced by your language's name.
--
-- ### Syntax Options
--
-- The syntax of different languages varies so the Adeptsense must be configured
-- for your language in order to function properly. See the [`syntax`](#syntax)
-- table documentation for all options.
--
-- #### `self`
--
-- The first syntax option is `syntax.self`. While Lua has a `self` identifier,
-- it is not used in the usual sense for a class instance so it will just be
-- ignored.
--
-- #### `class_definition`
--
-- Next is `syntax.class_definition`. Lua does not really have the "class"
-- concept most OOP programmers are used to, but modules do behave somewhat like
-- classes.
--
--     sense.syntax.class_definition = 'module%s*%(?%s*[\'"]([%w_%.]+)'
--
-- The "class"'s name is the identifier in quotes.
--
-- #### `word_chars`
--
-- Lua words already consist of the default `%w_` so no changes are necessary.
--
-- #### `symbol_chars`
--
-- In addition to the usual `[%w_%.]` symbol characters, Lua also allows symbols
-- to contain a ':'.
--
--     sense.syntax.symbol_chars = '[%w_%.:]'
--
-- #### `type_declarations`
--
-- Since Lua has no type declarations (e.g. `int x` in C), the
-- `syntax.type_declarations` table should be empty:
--
--     sense.syntax.type_declarations = {}
--
-- #### `type_declarations_exclude`
--
-- Since Lua has no type declarations, no changes are necessary.
--
-- #### `type_assignments`
--
-- Sometimes a type can be inferred by the right side of a variable assignment.
-- In the Lua code `local foo = 'bar'`, the variable `foo` has type `string`.
-- Similarly, in `local foo = _M.textadept.adeptsense`, `foo` has type
-- `_M.textadept.adeptsense`.
--
--     sense.syntax.type_assignments = {
--       ['^[\'"]'] = 'string', -- foo = 'bar' or foo = "bar"
--       ['^([%w_%.]+)'] = '%1' -- foo = _M.textadept.adeptsense
--     }
--
-- Note the '^' in the pattern. The beginning of the right hand side of the
-- assignment should be matched, otherwise `local foo = bar('baz')` could infer
-- an incorrect type.
--
-- ### Completion Lists
--
-- The [`completions`](#completions) table contains the completion lists for
-- all classes. Each table entry key is the class's name and the value is a
-- table of `functions` and `fields` lists. The general form is:
--
--     sense.completions = {
--       ['class1'] = {
--         functions = {'fun1', 'fun2', ...},
--         fields = {'f1', 'f2', ...}
--       },
--       ['class2'] = ...,
--       ...
--     }
--
-- Obviously manually creating completion lists would be incredibly
-- time-consuming so there is a shortcut method.
--
-- #### Ctags
--
-- Adeptsense recognizes the output from [Ctags][] and can populate the
-- `completions` table from it with a little bit of help. Ctags has a list of
-- "kinds" for every language. You can see them by running `ctags --list-kinds`
-- in your shell. Since Adeptsense only cares about classes, functions, and
-- fields, you need to let it know which kind of tag is which. Unfortunately,
-- Lua support in Ctags is not good at all. Instead, Textadept has a utility
-- (*modules/lua/adeptsensedoc.lua*) to generate a fake set of tags that is more
-- useful. Functions are tagged `'f'` and should be recognized as such; table
-- keys are tagged `'t'` and should be recognized as fields; module fields,
-- `'F'`, should be fields; and modules, `'m'`, should be classes:
--
--     sense.ctags_kinds = {
--       f = _M.textadept.adeptsense.FUNCTION,
--       F = _M.textadept.adeptsense.FIELD,
--       m = _M.textadept.adeptsense.CLASS,
--       t = _M.textadept.adeptsense.FIELD,
--     }
--
-- To load a default set of Ctags, use [`load_ctags()`](#load_ctags).
--
--     sense:load_ctags(_HOME..'/modules/lua/tags', true)
--
-- Textadept comes with a set of Ctags for its Lua API.
--
-- [ctags]: http://ctags.sourceforge.net
--
-- ### API Documentation
--
-- Adeptsense can show API documentation for symbols from files specified in its
-- [`api_files`](#api_files) table. See the previous link for documentation on
-- how the API file should be structured.
--
--     sense.api_files = {_HOME..'/modules/lua/api'}
--
-- ### Triggers
--
-- Triggers are characters or character sequences that trigger an autocompletion
-- list to be displayed. Lua has two characters that can do so: '.' and ':'. The
-- '.' should autocomplete both fields and functions while ':' should
-- autocomplete only functions. This is specified using
-- [`add_trigger()`](#add_trigger).
--
--     sense:add_trigger('.')
--     sense:add_trigger(':', false, true)
--
-- ### User-Settings
--
-- Finally, you should allow the users of your Adeptsense to supply their own
-- Ctags and API files in addition to any default ones you loaded or specified
-- earlier:
--
--     -- Load user tags and apidoc.
--     if lfs.attributes(_USERHOME..'/modules/lua/tags') then
--       sense:load_ctags(_USERHOME..'/modules/lua/tags')
--     end
--     if lfs.attributes(_USERHOME..'/modules/lua/api') then
--       sense.api_files[#sense.api_files + 1] = _USERHOME..'/modules/lua/api'
--     end
--
-- ### Summary
--
-- The above method of setting syntax options, Ctags kinds, and trigger
-- characters for an Adeptsense is sufficient for most static and some dynamic
-- languages. The rest of this document is devoted to more complex techniques.
--
-- ### Fine-Tuning
--
-- Sometimes Adeptsense's default behavior is not sufficient. Maybe the
-- `type_declarations` and `type_assignments` tables used by the
-- [`get_class()`](#get_class) function are not granular enough. Maybe some
-- symbols can contain more than just the `syntax.symbol_chars` used by
-- [`get_symbol()`](#get_symbol). Adeptsense allows these functions to be
-- overridden.
--
--     function sense:get_class(symbol)
--       if condition then
--         return self.super.get_class(self, symbol) -- default behavior
--       else
--         -- different behavior
--       end
--     end
--
-- The default Adeptsense functions are called by using the `self.super`
-- reference.
--
-- #### Examples for Ruby
--
-- In Ruby, everything is an object -- even numbers. Since numbers do not have
-- a type declaration, the [`get_class()`](#get_class) function should return
-- `Integer` or `Float` if the symbol is a number.
--
--     function sense:get_class(symbol)
--       local class = self.super.get_class(self, symbol)
--       if class then return class end
--       -- Integers and Floats.
--       if tonumber(symbol:match('^%d+%.?%d*$')) then
--         return symbol:find('%.') and 'Float' or 'Integer'
--       end
--       return nil
--     end
--
-- Note that there is no plus or minus prefix in the pattern. This is because
-- '+' or '-' characters are not a part of `syntax.symbol_chars` so a symbol
-- will not contain either of them.
--
-- Like numbers, the syntax for constructing strings, arrays, hashes, and the
-- like should also be considered as symbols. `[foo].` should show a completion
-- list with array instance methods:
--
--     function sense:get_symbol()
--       local line, p = buffer:get_cur_line()
--       if line:sub(1, p):match('%[.-%]%s*%.$') then return 'Array', '' end
--       return self.super.get_symbol(self)
--     end
--
-- The Ruby module Adeptsense has a more complicated version of this function
-- that handles strings, hashes, symbols, and regexps as well. Please refer to
-- it for more information.
--
-- #### Examples for Java
--
-- Autocomplete of Java `import` statements is something nice to have. Ctags
-- produces a tag for packages so it is rather straightforward to build an
-- import completion list.
--
-- Since Adeptsense ignores any tags not mapped to `classes`, `functions`, or
-- `fields` in [`ctags_kinds`](#ctags_kinds), it passes an unknown tag to the
-- [`handle_ctag()`](#handle_ctag) function. In this case, package ('p') tags
-- need to be handled.
--
--     function sense:handle_ctag(tag_name, file_name, ex_cmd, ext_fields)
--       if ext_fields:sub(1, 1) ~= 'p' then return end -- not a package
--       if not self.imports then self.imports = {} end
--       local import = self.imports
--       for package in tag_name:gmatch('[^.]+') do
--         if not import[package] then import[package] = {} end
--         import = import[package]
--       end
--       import[#import + 1] = file_name:match('([^/\\]-)%.java$')
--     end
--
-- Now that we have a list of import completions, it should be activated by the
-- normal trigger ('.'), but only on a line that contains an `import` statement.
-- The [`get_completions`](#get_completions) function needs to be overridden to
-- use the `import` table's completions when necessary.
--
--     function sense:get_completions(symbol, ofields, ofunctions)
--       if not buffer:get_cur_line():find('^%s*import') then
--         return self.super.get_completions(self, symbol, ofields, ofunctions)
--       end
--       if symbol == 'import' then symbol = '' end -- top-level import
--       local c = {}
--       local import = self.imports or {}
--       for package in symbol:gmatch('[^%.]+') do
--         if not import[package] then return nil end
--         import = import[package]
--       end
--       for k, v in pairs(import) do
--         c[#c + 1] = type(v) == 'table' and k..'?1' or v..'?2'
--       end
--       table.sort(c)
--       return c
--     end
--
-- Note that `'?1'` and `'?2'` are appended to each completion entry. These tell
-- Adeptsense which icon to display in the autocompletion list. If no icon
-- information is given, no icon is displayed. `1` is for fields and `2` is for
-- functions. In this case, the icons are used only to distinguish between a
-- parent package and a package with no children since parents have an
-- additional list of completions.
--
-- Finally since an `imports` table was created, it should be cleared when the
-- Adeptsense is cleared to free up memory immediately. When this happens,
-- [`handle_clear()`](#handle_clear) is called.
--
--     function sense:handle_clear()
--       self.imports = {}
--     end
--
-- ### Child Language Adeptsenses
--
-- When Adeptsense completion is triggered, the Adeptsense for the language at
-- the *caret position* is used, not necessarily the parent language's
-- Adeptsense. For example, when editing CSS inside of an HTML file, the user
-- expects the CSS Adeptsense to be used. However, child language Adeptsenses
-- are not loaded automatically and must be loaded by the parent language
-- module. For the case of CSS in HTML, the HTML module's *init.lua* must
-- contain:
--
--     -- Load CSS Adeptsense.
--     if not _M.css then _M.css = require 'css' end
--
-- You will have to do something similar if you are writing an Adeptsense for a
-- child lexer language.
--
-- ### Generating Lua Adeptsense
--
-- You can generate Lua Adeptsense for your own modules using the Lua language
-- module's *adeptsensedoc.lua* module with [LuaDoc][]:
--
--     luadoc -d . --doclet _HOME/modules/lua/adeptsensedoc [module(s)]
--
-- where `_HOME` is where Textadept is installed. The *tags* and *api* files are
-- output to the current directory and can be loaded via
-- [`load_ctags()`](#load_ctags) and [`api_files`](#api_files) respectively.
--
-- [LuaDoc]: http://keplerproject.github.com/luadoc/
--
-- #### Module Fields
--
-- Not only does the Lua Adeptsense generator recognize functions and tables
-- within modules, but it also recognizes module fields and their types with a
-- certain syntax:
--
-- <pre><code>---
-- -- Module documentation.
-- -- &#64;field field_name (type)
-- --   Field documentation.
-- </code></pre>
--
-- or
--
-- <pre><code>---
-- -- Module documentation
-- -- * `field_name` (type)
-- --   Field documentation.
-- --   Multiple documentation lines must be indented.
-- </code></pre>
--
-- Please note the latter ``-- * `field_name` `` syntax can appear anywhere
-- inside a module, not just the module LuaDoc.
-- @field always_show_globals (bool)
--   Include globals in the list of completions offered.
--   Globals are classes, functions, and fields that do not belong to another
--   class. They are contained in `sense.completions['']`.
--   The default value is `true`.
-- @field FUNCTIONS (string)
--   XPM image for Adeptsense functions.
-- @field FIELDS (string)
--   XPM image for Adeptsense fields.
-- @field CLASS (string)
--   Ctags kind for Adeptsense classes.
-- @field FUNCTION (string)
--   Ctags kind for Adeptsense functions.
-- @field FIELD (string)
--   Ctags kind for Adeptsense fields.
module('_M.textadept.adeptsense')]]

local senses = {}

M.FUNCTIONS = not CURSES and '/* XPM */\nstatic char *function[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c #000000",\n". c #E0BC38",\n"X c #F0DC5C",\n"o c #FCFC80",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOO  OOOO",\n"OOOOOOOOO oo  OO",\n"OOOOOOOO ooooo O",\n"OOOOOOO ooooo. O",\n"OOOO  O XXoo.. O",\n"OOO oo  XXX... O",\n"OO ooooo XX.. OO",\n"O ooooo.  X. OOO",\n"O XXoo.. O  OOOO",\n"O XXX... OOOOOOO",\n"O XXX.. OOOOOOOO",\n"OO  X. OOOOOOOOO",\n"OOOO  OOOOOOOOOO"\n};' or '*'
M.FIELDS = not CURSES and '/* XPM */\nstatic char *field[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c #000000",\n". c #8C748C",\n"X c #9C94A4",\n"o c #ACB4C0",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOO oo  OOO",\n"OOOOOOO ooooo OO",\n"OOOOOO ooooo. OO",\n"OOOOOO XXoo.. OO",\n"OOOOOO XXX... OO",\n"OOOOOO XXX.. OOO",\n"OOOOOOO  X. OOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOOOOOOOOOO"\n};' or '+'

M.CLASS = 'classes'
M.FUNCTION = 'functions'
M.FIELD = 'fields'

---
-- Returns a full symbol (if any) and current symbol part (if any) behind the
-- caret.
-- For example: `buffer.cur` would return `'buffer'` and `'cur'`. Returns empty
-- strings instead of `nil`.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @return symbol or `''`
-- @return part or `''`
-- @name get_symbol
function M.get_symbol(sense)
  local line, p = buffer:get_cur_line()
  local sc, wc = sense.syntax.symbol_chars, sense.syntax.word_chars
  local patt = string.format('(%s-)[^%s%%s]+([%s]*)$', sc, wc, wc)
  local symbol, part = line:sub(1, p):match(patt)
  if not symbol then part = line:sub(1, p):match('(['..wc..']*)$') end
  return symbol or '', part or ''
end

---
-- Returns the class name for *symbol* name.
-- If *symbol* is `sense.syntax.self` and inside a class definition matching
-- `sense.syntax.class_definition`, that class is returned. Otherwise the
-- buffer is searched backwards for a type declaration of *symbol* according to
-- the patterns in `sense.syntax.type_declarations` or a type assignment of
-- *symbol* according to `sense.syntax.type_assignments`.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param symbol The symbol name to get the class of.
-- @return class or `nil`
-- @see syntax
-- @name get_class
function M.get_class(sense, symbol)
  local buffer = buffer
  local self = sense.syntax.self
  local class_definition = sense.syntax.class_definition
  local completions = sense.completions
  local symbol_chars = sense.syntax.symbol_chars
  local type_declarations = sense.syntax.type_declarations
  local exclude = sense.syntax.type_declarations_exclude
  local type_assignments = sense.syntax.type_assignments
  local assignment_patt = symbol..'%s*=%s*([^\r\n]+)'
  local class, superclass, assignment
  for i = buffer:line_from_position(buffer.current_pos), 0, -1 do
    local s, e
    if symbol == self or symbol == '' then
      -- Determine type from the class declaration.
      s, e, class, superclass = buffer:get_line(i):find(class_definition)
      if class and not completions[class] then
        class = completions[superclass] and superclass or nil
      end
    else
      -- Search for a type declaration or type assignment.
      local line = buffer:get_line(i)
      if line:find(symbol) then
        for _, patt in ipairs(type_declarations) do
          s, e, class = line:find(patt:gsub('%%_', symbol))
          if class and exclude[class] then class = nil end
          if class then break end
        end
        if not class then
          s, e, assignment = line:find(assignment_patt)
          if assignment then
            for patt, type in pairs(type_assignments) do
              local captures = {assignment:match(patt)}
              if #captures > 0 then
                class = type:gsub('%%(%d+)', function(n)
                  return captures[tonumber(n)]
                end)
              end
              if class then break end
            end
          end
        end
      end
    end
    if class then
      -- The type declaration should not be in a comment or string.
      local pos = buffer:position_from_line(i)
      local style = buffer:get_style_name(buffer.style_at[pos + s - 1])
      if style ~= 'comment' and style ~= 'string' then break end
      class = nil
    end
  end
  return class
end

-- Adds an inherited class's completions to the given completion list.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param class The name of the class to add inherited completions from.
-- @param only_fields If `true`, adds only fields to the completion list. The
--   default value is `false`.
-- @param only_funcs If `true`, adds only functions to the completion list. The
--   default value is `false`.
-- @param c The completion list to add completions to.
-- @param added Table that keeps track of what inherited classes have been
--   added. This prevents stack overflow errors. Should be `{}` on the initial
--   call to `add_inherited()`.
local function add_inherited(sense, class, only_fields, only_funcs, c, added)
  local inherited_classes = sense.inherited_classes[class]
  if not inherited_classes or added[class] then return end
  local completions = sense.completions
  for _, inherited_class in ipairs(inherited_classes) do
    local inherited_completions = completions[inherited_class]
    if inherited_completions then
      if not only_fields then
        for _, v in ipairs(inherited_completions.functions) do c[#c + 1] = v end
      end
      if not only_funcs then
        for _, v in ipairs(inherited_completions.fields) do c[#c + 1] = v end
      end
    end
    added[class] = true
    add_inherited(sense, inherited_class, only_fields, only_funcs, c, added)
  end
end

---
-- Returns a list of function (unless *only_fields* is `true`) and field (unless
-- *only_funcs* is `true`) completions for *symbol* name.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param symbol The symbol name to get completions for.
-- @param only_fields Optional flag indicating whether or not to return a list
--   of only fields. The default value is `false`.
-- @param only_functions Optional flag indicating whether or not to return a
--   list of only functions. The default value is `false`.
-- @return completion_list or `nil`
-- @name get_completions
function M.get_completions(sense, symbol, only_fields, only_functions)
  if only_fields and only_functions or not symbol then return nil end
  local compls = sense.completions
  local class = compls[symbol] and symbol or sense:get_class(symbol)
  if not compls[class] then return nil end

  -- If there is no symbol, try to determine the context class. If one exists,
  -- display its completions in addition to global completions.
  local include_globals = false
  if symbol == '' then
    local context_class = sense:get_class(symbol)
    if context_class and compls[context_class] then
      class = context_class
      include_globals = sense.always_show_globals and compls[''] ~= nil
    end
  end

  -- Create list of completions.
  local c = {}
  if not only_fields then
    for _, v in ipairs(compls[class].functions) do c[#c + 1] = v end
    if include_globals and class ~= '' then
      for _, v in ipairs(compls[''].functions) do c[#c + 1] = v end
    end
  end
  if not only_functions then
    for _, v in ipairs(compls[class].fields) do c[#c + 1] = v end
    if include_globals and class ~= '' then
      for _, v in ipairs(compls[''].fields) do c[#c + 1] = v end
    end
  end
  add_inherited(sense, class, only_fields, only_functions, c, {})

  -- Remove duplicates and non-toplevel classes (if necessary).
  if not buffer.auto_c_ignore_case then
    table.sort(c)
  else
    table.sort(c, function(a, b) return a:upper() < b:upper() end)
  end
  local table_remove, nwc = table.remove, '[^'..sense.syntax.word_chars..'%?]'
  for i = #c, 2, -1 do
    if c[i] == c[i - 1] or c[i]:find(nwc) then table_remove(c, i) end
  end
  return c
end

---
-- Shows an autocompletion list of functions (unless *only_fields* is `true`)
-- and fields (unless *only_funcs* is `true`) for the symbol behind the caret,
-- returning `true` on success.
-- @param sense The Adeptsense returned by `adeptsense.new()`. If `nil`, uses
--   the current language's Adeptsense (if it exists).
-- @param only_fields Optional flag indicating whether or not to return a list
--   of only fields. The default value is `false`.
-- @param only_functions Optional flag indicating whether or not to return a
--   list of only functions. The default value is `false`.
-- @return `true` on success or `false`.
-- @see get_symbol
-- @see get_completions
-- @name complete
function M.complete(sense, only_fields, only_functions)
  local buffer = buffer
  sense = sense or (_M[buffer:get_lexer(true)] or {}).sense
  if not sense then return end
  local symbol, part = sense:get_symbol()
  local completions = sense:get_completions(symbol, only_fields, only_functions)
  if not completions then return false end
  buffer:register_image(1, M.FIELDS)
  buffer:register_image(2, M.FUNCTIONS)
  if not buffer.auto_c_choose_single or #completions ~= 1 then
    buffer.auto_c_order = 0 -- pre-sorted
    buffer:auto_c_show(#part, table.concat(completions, ' '))
  else
    -- Scintilla does not emit `AUTO_C_SELECTION` in this case. This is
    -- necessary for autocompletion with multiple selections.
    local text = completions[1]:sub(#part + 1):match('^(.+)%?%d+$')
    events.emit(events.AUTO_C_SELECTION, text, buffer.current_pos)
  end
  return true
end

---
-- Sets the trigger character(s) *c* for autocompletion.
-- If *only_fields* is `true`, the trigger only completes fields. If
-- *only_functions* is `true`, the trigger only completes functions.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param c The character(s) that triggers the autocompletion. You can have up
--   to two characters.
-- @param only_fields Optional flag indicating whether or not this trigger only
--   completes fields. The default value is `false`.
-- @param only_functions Optional flag indicating whether or not this trigger
--   only completes functions. The default value is `false`.
-- @usage sense:add_trigger('.')
-- @usage sense:add_trigger(':', false, true) -- only functions
-- @usage sense:add_trigger('->')
-- @name add_trigger
function M.add_trigger(sense, c, only_fields, only_functions)
  if #c > 2 then return end -- TODO: warn
  local c1, c2 = c:match('.$'):byte(), #c > 1 and c:sub(1, 1):byte()
  local i = events.connect(events.CHAR_ADDED, function(char)
    if char == c1 and buffer:get_lexer(true) == sense.lexer then
      if c2 and buffer.char_at[buffer.current_pos - 2] ~= c2 then return end
      sense:complete(only_fields, only_functions)
    end
  end)
  sense.events[#sense.events + 1] = i
end

---
-- Returns a list of apidocs for *symbol* name.
-- The list contains a `pos` key with the index of the apidoc to show.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param symbol The symbol name to get apidocs for.
-- @return list of apidocs or `nil`
-- @name get_apidoc
function M.get_apidoc(sense, symbol)
  if not symbol then return nil end
  local apidocs = {pos = 1}
  local word_chars = sense.syntax.word_chars
  local patt = string.format('^(.-)[^%s]*([%s]+)$', word_chars, word_chars)
  local entity, func = symbol:match(patt)
  if not func then return nil end
  local c = func:sub(1, 1) -- for quick comparison
  local patt = '^'..func:gsub('([%.%-%?])', '%%%1')..'%s+(.+)$'
  for _, file in ipairs(sense.api_files) do
    if lfs.attributes(file) then
      for line in io.lines(file) do
        if line:sub(1, 1) == c then apidocs[#apidocs + 1] = line:match(patt) end
      end
    end
  end
  if #apidocs == 0 then return nil end
  -- Try to display the type-correct apidoc by getting the entity the function
  -- is being called on and attempting to determine its type. Otherwise, fall
  -- back to the entity itself. In order for this to work, the first line in the
  -- apidoc must start with the entity (e.g. Class.function).
  local class = sense.completions[entity] or sense:get_class(entity)
  if entity == '' then class = sense:get_class(entity) end
  if type(class) ~= 'string' then class = entity end -- fall back to entity
  for i, apidoc in ipairs(apidocs) do
    if apidoc:sub(1, #class) == class then apidocs.pos = i break end
  end
  return apidocs
end

local apidocs = nil
---
-- Shows a call tip with API documentation for the symbol behind the caret.
-- If documentation is already being shown, cycles through multiple definitions.
-- @param sense The Adeptsense returned by `adeptsense.new()`. If `nil`, uses
--   the current language's Adeptsense (if it exists).
-- @return list of apidocs on success or `nil`.
-- @see get_symbol
-- @see get_apidoc
-- @name show_apidoc
function M.show_apidoc(sense)
  local buffer = buffer
  if buffer:call_tip_active() then events.emit(events.CALL_TIP_CLICK) return end
  sense = sense or (_M[buffer:get_lexer(true)] or {}).sense
  if not sense then return end
  local symbol
  local s, e = buffer.selection_start, buffer.selection_end
  if s == e then
    buffer:goto_pos(buffer:word_end_position(s, true))
    local line, p = buffer:get_cur_line()
    line = line:sub(1, p)
    symbol = line:match('('..sense.syntax.symbol_chars..'+)%s*$') or
             line:match('('..sense.syntax.symbol_chars..'+)%s*%([^()]*$') or ''
    buffer:goto_pos(e)
  else
    symbol = buffer:text_range(s, e)
  end
  apidocs = sense:get_apidoc(symbol)
  if not apidocs then return nil end
  for i, doc in ipairs(apidocs) do
    doc = doc:gsub('\\\\', '%%esc%%'):gsub('\\n', '\n'):gsub('%%esc%%', '\\')
    if #apidocs > 1 then
      if not doc:find('\n') then doc = doc..'\n' end
      doc = '\001'..doc:gsub('\n', '\n\002', 1)
    end
    apidocs[i] = doc
  end
  buffer:call_tip_show(buffer.current_pos, apidocs[apidocs.pos or 1])
  return apidocs
end

-- Cycle through apidoc calltips.
events.connect(events.CALL_TIP_CLICK, function(position)
  if not apidocs then return end
  apidocs.pos = apidocs.pos + (position == 1 and -1 or 1)
  if apidocs.pos > #apidocs then apidocs.pos = 1 end
  if apidocs.pos < 1 then apidocs.pos = #apidocs end
  buffer:call_tip_show(buffer.current_pos, apidocs[apidocs.pos])
end)

---
-- Loads the Ctags file *tag_file* for autocompletions.
-- If *nolocations* is `true`, `sense:goto_ctag()` cannot be used with this set
-- of tags. It is recommended to pass `-n` to `ctags` in order to use line
-- numbers instead of text patterns to locate tags. This will greatly reduce
-- memory usage for a large number of symbols if `nolocations` is `false`.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param tag_file The path of the Ctags file to load.
-- @param nolocations Optional flag indicating whether or not to discard the
--   locations of the tags for use by `sense:goto_ctag()`. The default value is
--   `false`.
-- @name load_ctags
function M.load_ctags(sense, tag_file, nolocations)
  local ctags_kinds = sense.ctags_kinds
  local completions = sense.completions
  local locations = sense.locations
  local inherited_classes = sense.inherited_classes
  local ctags_fmt = '^(%S+)\t([^\t]+)\t(.-);"\t(.*)$'
  for line in io.lines(tag_file) do
    local tag_name, file_name, ex_cmd, ext_fields = line:match(ctags_fmt)
    if tag_name then
      local k = ext_fields:sub(1, 1)
      local kind = ctags_kinds[k]
      if kind == M.FUNCTION or kind == M.FIELD then
        -- Update completions.
        -- If no class structure is found, the global namespace is used.
        for _, key in ipairs{'class', 'interface', 'struct', 'union', ''} do
          local class = (key == '') and '' or ext_fields:match(key..':(%S+)')
          if class then
            if not completions[class] then
              completions[class] = {fields = {}, functions = {}}
            end
            local t = completions[class][kind]
            t[#t + 1] = tag_name..(kind == M.FIELD and '?1' or '?2')
            -- Update locations.
            if not nolocations then
              if not locations[k] then locations[k] = {} end
              locations[k][class..'#'..tag_name] = {file_name, ex_cmd}
            end
            break
          end
        end
      elseif kind == M.CLASS then
        -- Update class list.
        local inherits = ext_fields:match('inherits:(%S+)')
        if not inherits then inherits = ext_fields:match('struct:(%S+)') end
        if inherits then
          inherited_classes[tag_name] = {}
          for class in inherits:gmatch('[^,]+') do
            local t = inherited_classes[tag_name]
            t[#t + 1] = class
            -- Even though this class inherits fields and functions from others,
            -- an empty completions table needs to be added to it so
            -- get_completions() does not return prematurely.
            if not completions[tag_name] then
              completions[tag_name] = {fields = {}, functions = {}}
            end
          end
        end
        -- Update completions.
        -- Add the class to the global namespace.
        if not completions[''] then
          completions[''] = {fields = {}, functions = {}}
        end
        local t = completions[''].fields
        t[#t + 1] = tag_name..'?1'
        -- Update locations.
        if not nolocations then
          if not locations[k] then locations[k] = {} end
          locations[k][tag_name] = {file_name, ex_cmd}
        end
      else
        sense:handle_ctag(tag_name, file_name, ex_cmd, ext_fields)
      end
    end
  end
  for _, v in pairs(completions) do
    table.sort(v.functions)
    table.sort(v.fields)
  end
end

---
-- Prompts the user to select a symbol to jump to from a list of all known
-- symbols of kind *kind* (classes, functions, fields, etc.) shown in a filtered
-- list dialog whose title text is *title*.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param kind The Ctag character kind (e.g. `'f'` for a Lua function).
-- @param title The title for the filtered list dialog.
-- @name goto_ctag
function M.goto_ctag(sense, kind, title)
  if not sense.locations[kind] then return end -- no Ctags loaded
  local items = {}
  local kind = sense.ctags_kinds[kind]
  for kind, v in pairs(sense.locations[kind]) do
    items[#items + 1] = kind:match('[^#]+$') -- symbol name
    if kind == M.FUNCTION or kind == M.FIELD then
      items[#items + 1] = kind:match('^[^#]+') -- class name
    end
    items[#items + 1] = v[1]..':'..v[2]
  end
  local columns = {'Name', 'Location'}
  if kind == M.FUNCTION or kind == M.FIELD then
    table.insert(columns, 2, 'Class')
  end
  local location = gui.filteredlist(title, columns, items, false,
                                    '--output-column', '3')
  if not location then return end
  local path, line = location:match('^(%a?:?[^:]+):(.+)$')
  io.open_file(path)
  if not tonumber(line) then
    -- /^ ... $/
    buffer.target_start, buffer.target_end = 0, buffer.length
    buffer.search_flags = _SCINTILLA.constants.SCFIND_REGEXP
    if buffer:search_in_target(line:sub(2, -2)) >= 0 then
      buffer:goto_pos(buffer.target_start)
    end
  else
    _M.textadept.editing.goto_line(tonumber(line))
  end
end

---
-- Called by `load_ctags()` when a Ctag kind is not recognized.
-- The parameters are extracted from Ctags' [tag format][]. This method should
-- be replaced with your own that is specific to the language.
--
-- [tag format]: http://ctags.sourceforge.net/ctags.html#TAG%20FILE%20FORMAT
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @param tag_name The tag name.
-- @param file_name The name of the file the tag belongs to.
-- @param ex_cmd The `ex_cmd` returned by Ctags.
-- @param ext_fields The `ext_fields` returned by Ctags.
-- @name handle_ctag
function M.handle_ctag(sense, tag_name, file_name, ex_cmd, ext_fields) end

---
-- Clears the Adeptsense for loading new Ctags or project files.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @name clear
function M.clear(sense)
  sense.inherited_classes = {}
  sense.completions = {}
  sense.locations = {}
  sense:handle_clear()
  collectgarbage('collect')
end

---
-- Called when clearing the Adeptsense.
-- This function should be replaced with your own if you have any persistant
-- objects that need to be deleted.
-- @param sense The Adeptsense returned by `adeptsense.new()`.
-- @name handle_clear
function M.handle_clear(sense) end

---
-- Creates and returns a new Adeptsense for *lang* name.
-- Only one sense can exist per language.
-- @param lang The lexer language name to create an Adeptsense for.
-- @return adeptsense
-- @usage local lua_sense = _M.textadept.adeptsense.new('lua')
-- @name new
function M.new(lang)
  local sense = senses[lang]
  if sense then
    sense.ctags_kinds = nil
    sense.api_files = nil
    for _, i in ipairs(sense.events) do
      events.disconnect(events.CHAR_ADDED, i)
    end
    sense.events = nil
    sense:clear()
  end

  sense = setmetatable({
    lexer = lang,
    events = {},
    always_show_globals = true,

---
-- A map of Ctags kinds to Adeptsense kinds.
-- Recognized kinds are `FUNCTION`, `FIELD`, and `CLASS`. Classes are quite
-- simply containers for functions and fields so Lua modules would count as
-- classes. Any other kinds will be passed to `handle_ctag()` for user-defined
-- handling.
-- @usage luasense.ctags_kinds = {f = _M.textadept.adeptsense.FUNCTION}
-- @usage csense.ctags_kinds = {m = _M.textadept.adeptsense.FIELD,
--   f = _M.textadept.adeptsense.FUNCTION, c = _M.textadept.adeptsense.CLASS,
--   s = _M.textadept.adeptsense.CLASS}
-- @usage javasense.ctags_kinds = {f = _M.textadept.adeptsense.FIELD,
--   m = _M.textadept.adeptsense.FUNCTION, c = _M.textadept.adeptsense.CLASS,
--   i = _M.textadept.adeptsense.CLASS}
-- @class table
-- @name ctags_kinds
-- @see handle_ctag
ctags_kinds = {},

---
-- A map of classes and a list of their inherited classes, normally populated by
-- `load_ctags()`.
-- @class table
-- @name inherited_classes
inherited_classes = {},

---
-- A list containing lists of possible completions for known symbols.
-- Each symbol key has a table value that contains a list of field completions
-- with a `fields` key and a list of functions completions with a `functions`
-- key. This table is normally populated by `load_ctags()`, but can also be set
-- by the user.
-- @class table
-- @name completions
completions = {},

---
-- A list of the locations of known symbols, normally populated by
-- `load_ctags()`.
-- @class table
-- @name locations
locations = {},

---
-- A list of api files used by `show_apidoc()`.
-- Each line in the api file contains a symbol name (not the full symbol)
-- followed by a space character and then the symbol's documentation. Since
-- there may be many duplicate symbol names, it is recommended to put the full
-- symbol and arguments, if any, on the first line. (e.g. `Class.function(arg1,
-- arg2, ...)`). This allows the correct documentation to be shown based on the
-- current context. In the documentation, newlines are represented with "\n". A
-- '\' before "\n" escapes the newline.
-- @class table
-- @name api_files
api_files = {},

---
-- Map of language-specific syntax settings.
-- @field self The language's syntax-equivalent of `self`. The default value is
--   `'self'`.
-- @field class_definition A Lua pattern representing the language's class
--   definition syntax. The first capture returned must be the class name. A
--   second, optional capture contains the class' superclass (if any). If no
--   completions are found for the class name, completions for the superclass
--   are shown (if any). Completions will not be shown for both a class and
--   superclass unless defined in a previously loaded Ctags file. Also, multiple
--   superclasses cannot be recognized by this pattern; use a Ctags file
--   instead. The default value is `'class%s+([%w_]+)'`.
-- @field word_chars A Lua pattern of characters allowed in a word.
--   The default value is `'%w_'`.
-- @field symbol_chars A Lua pattern of characters allowed in a symbol,
--   including member operators. The pattern should be a character set.
--   The default value is `'[%w_%.]'`.
-- @field type_declarations A list of Lua patterns used for determining the
--   class type of a symbol. The first capture returned must be the class name.
--   Use `%_` to match the symbol.
--   The default value is `'(%u[%w_%.]+)%s+%_'`.
-- @field type_declarations_exclude A table of types to exclude, even if they
--   match a `type_declarations` pattern. Each excluded type is a table key and
--   has a `true` boolean value. For example, `{Foo = true}` excludes any type
--   whose name is `Foo`.
--   The default value is `{}`.
-- @field type_assignments A map of Lua patterns to class types for variable
--   assignments, typically used for dynamically typed languages. For example,
--   `sense.syntax.type_assignments['^"'] = 'string'`  would recognize string
--   assignments in Lua so the `foo` in `foo = "bar"` would be recognized as
--   type `string`. The class type value may contain `%n` pattern captures.
-- @class table
-- @name syntax
-- @see get_class
syntax = {
  self = 'self',
  class_definition = 'class%s+([%w_]+)',
  word_chars = '%w_',
  symbol_chars = '[%w_%.]',
  type_declarations = {'(%u[%w_%.]+)%s+%_'}, -- Foo bar
  type_declarations_exclude = {},
  type_assignments = {}
},

    super = setmetatable({}, {__index = M})
  }, {__index = M})

  senses[lang] = sense
  return sense
end

return M

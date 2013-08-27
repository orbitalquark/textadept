-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Code autocompletion and documentation support for programming languages.
--
-- ## Overview
--
-- Adeptsense is a form of autocompletion for programming. Object-oriented
-- programming languages often have class types with member methods. For
-- example, the Ruby and Java programming languages implement "String" classes
-- with member functions that return the uppercase versions of the strings. This
-- looks like:
--
--     # Ruby      | // Java
--     foo = "bar" | String foo = "bar";
--     foo.upcase! | foo = foo.toUpperCase();
--
-- In both cases, Adeptsense recognizes that the variable "foo" is of type
-- "String" and displays a list of known methods in the "String" class (which
-- includes the appropriate one shown above) after the user types "foo.". Upon
-- request, Adeptsense also displays any known documentation for the symbol
-- under the caret, such as the "upcase!" and "toUpperCase" methods, in the form
-- of a calltip.
--
-- The first part of this document deals with constructing a simple Adeptsense.
-- The second part deals with more advanced techniques for "fine-tuning"
-- Adeptsenses, such as overriding default behaviors and recognizing additional
-- language features. The last part shows you how to generate Adeptsense data
-- for any Lua modules you have so that Textadept can provide additional
-- completions and documentation while you write your scripts.
--
-- ## Adeptsense Basics
--
-- Adeptsenses exist per-language so [language modules][] typically define them.
-- Before attempting to write an Adeptsense, first determine if the module for
-- your language has an Adeptsense. Textadept's official language modules have
-- Adeptsenses and are good reference sources. If your language is similar to
-- any of Textadept's, you may be able to copy and modify that language's
-- Adeptsense, saving some time and effort.
--
-- [language modules]: _M.html#Language.Modules
--
-- Creating a new instance of an Adeptsense from within a language module is
-- easy. Just replace the '?' with the name of your language:
--
--     M.sense = textadept.adeptsense.new('?')
--
-- ### Terminology
--
-- Since some programming languages like Lua are not object-oriented, the terms
-- "classes" and "methods" may not mean anything to those languages. In an
-- attempt to cater to all languages, Adeptsense adopts the terms "class",
-- "function", and "field". However, "classes" are simply containers for
-- "functions" and "fields" while "functions" and "fields" are just entities
-- distinguishable only by an icon in the autocompletion list. The Lua
-- Adeptsense considers modules and tables as "classes", functions as
-- "functions", and module/table keys as "fields".
--
-- ### Syntax Options
--
-- Take a moment to think about your programming language and its syntax. How
-- do you declare "classes"? What characters can you use in identifiers? Is the
-- language statically typed? If so, how do you declare a variable's type? If
-- not, how might you infer a variable's type? You must answer all of these
-- questions in an Adeptsense's [`syntax`](#syntax) table. Please see its
-- documentation for details.
--
-- #### Example Syntax Options
--
-- So, how might you define syntax options for your language? Here are some
-- examples.
--
-- **Lua**
--
-- Lua is a dynamically typed language with no built-in object-oriented
-- features. As noted earlier, the Lua Adeptsense considers modules and tables
-- as "classes" and thus uses Lua 5.1's `module()` as a "class" declaration. Lua
-- allows alphanumerics and underscores in its identifiers and uses the '.' and
-- ':' characters to access the functions and fields of "classes". Since the
-- language is dynamically typed, it has no type declaration and instead relies
-- on type inference through assignment to entities like strings, other tables,
-- or the result of a function call like `io.open()`.
--
--     M.sense.syntax.class_definition = 'module%s*%(?%s*[\'"]([%w_%.]+)'
--     M.sense.syntax.symbol_chars = '[%w_%.:]'
--     M.sense.syntax.type_declarations = {}
--     M.sense.syntax.type_assignments = {
--       ['^[\'"]'] = 'string', -- foo = 'bar' or foo = "bar"
--       ['^([%w_%.]+)%s*$'] = '%1', -- foo = textadept.adeptsense
--       ['^io%.p?open%s*%b()%s*$'] = 'file' -- f = io.open('foo')
--     }
--
-- The beginning '^' in these type assignment patterns is necessary since
-- Adeptsense starts matching on the right-hand side of an assignment.
-- Otherwise, `local foo = bar('baz')` might infer an incorrect type.
--
-- **Java**
--
-- Java is a statically typed, object-oriented language. It has most of the
-- default syntax features that Adeptsense assumes except for parameterized list
-- types.
--
--     local td = M.sense.syntax.type_declarations
--     td[#td + 1] = '(%u[%w_%.]+)%b<>%s+%_' -- List<Foo> bar
--
-- The "%_" sequence in this pattern matches the symbol part of the type
-- declaration.
--
-- ### Completion Lists
--
-- Even though your Adeptsense now understands the basic syntax of your
-- programming language, it is not smart enough to parse code to generate lists
-- of function and field completions for classes. Instead, you must supply this
-- information to your Adeptsense's [`completions`](#completions) table. The
-- table contains string class names assigned to tables that themselves contain
-- `functions` and `fields` completion tables. Here is the general form:
--
--     M.sense.completions = {
--       ['class1'] = {
--         functions = {'fun1', 'fun2', ...},
--         fields = {'f1', 'f2', ...}
--       },
--       ['class2'] = ...,
--       ...
--     }
--
-- Obviously, manually creating completion lists is incredibly time-consuming so
-- Adeptsense provides a shortcut method.
--
-- #### Ctags
--
-- Adeptsense recognizes the output from [Ctags][] and uses the output along
-- with your Adeptsense's [`ctags_kinds`](#ctags_kinds) to populate
-- `completions`. Ctags has a list of "kinds" for every language. View them by
-- running `ctags --list-kinds` in your shell. Since Adeptsense only cares about
-- classes, functions, and fields, you need to let it know which kind of tag is
-- which. After that, load your sets of tags using
-- [`load_ctags()`](#load_ctags). Here are some examples:
--
-- **C/C++**
--
--     local as = textadept.adeptsense
--     M.sense.ctags_kinds = {
--       c = as.CLASS, d = as.FUNCTION, e = as.FIELD, f = as.FUNCTION,
--       g = as.CLASS, m = as.FIELD, s = as.CLASS, t = as.CLASS
--     }
--     M.sense:load_ctags(_HOME..'/modules/cpp/tags', true)
--
-- **Lua**
--
-- Unfortunately, Lua support in Ctags is poor. Instead, Textadept has a tool
-- (*modules/lua/adeptsensedoc.lua*) to generate a more useful set of tags. The
-- tool tags functions as `'f'`, module fields as `'F'`, modules as `'m'`, and
-- table keys as `'t'`.
--
--     M.sense.ctags_kinds = {
--       f = textadept.adeptsense.FUNCTION,
--       F = textadept.adeptsense.FIELD,
--       m = textadept.adeptsense.CLASS,
--       t = textadept.adeptsense.FIELD,
--     }
--     M.sense:load_ctags(_HOME..'/modules/lua/tags', true)
--
-- [ctags]: http://ctags.sourceforge.net
--
-- ### API Documentation
--
-- Like with completion lists, Adeptsense is not smart enough to parse code to
-- generate API documentation. You must do so manually in a set of API files and
-- add them to your Adeptsense's [`api_files`](#api_files) table. The table's
-- documentation describes API file structure and format.
--
-- ### Triggers
--
-- At this point, your Adeptense understands your language's syntax, has a set
-- of completions for classes, and knows where to look up API documentation
-- from. The only thing left to do is to tell your Adeptsense what characters
-- trigger autocompletion. Use [`add_trigger()`](#add_trigger) to do this. Some
-- examples:
--
-- **C/C++**
--
--     M.sense:add_trigger('.')
--     M.sense:add_trigger('->')
--
-- **Lua**
--
--     M.sense:add_trigger('.')
--     M.sense:add_trigger(':', false, true)
--
-- ### Summary
--
-- Adeptsense is flexible enough to support code autocompletion and API
-- reference for many different programming languages. By simply setting some
-- basic syntax parameters in a new Adeptsense instance, loading a set of
-- completions and API documentation, and specifying characters that trigger
-- autocompletion, you created a powerful tool to help write code faster and
-- understand code better.
--
-- ## Advanced Techniques
--
-- ### Fine-Tuning
--
-- Adeptsense's defaults are adequate enough to provide basic autocompletion for
-- a wide range of programming languages. However, sometimes you need more
-- control. For example, when determining the class of the symbol to
-- autocomplete, Adeptsense calls [`get_class()`](#get_class). This function
-- utilizes the Adeptsense's `syntax.type_declarations` and
-- `syntax.type_assignments` to help, but those tables may not be granular
-- enough for your language. (For example, in Ruby, everything is an object --
-- even numbers. "0.to_s" is perfectly valid syntax.) Adeptsense allows you to
-- override its default functionality:
--
--     function M.sense:get_class(symbol)
--       if condition then
--         return self.super.get_class(self, symbol) -- default behavior
--       else
--         -- different behavior
--       end
--     end
--
-- Use the `self.super` table to call on default functionality.
--
-- Below are some examples of overriding default functionality for the Ruby and
-- Java languages.
--
-- **Ruby**
--
-- As mentioned earlier, everything in Ruby is an object, including numbers.
-- Since numbers may exist by themselves, those instances do not have a type
-- declaration or type assignment. In that case, the Ruby Adeptsense's
-- `get_class()` needs to return "Integer" or "Float" if the symbol is a number.
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
-- Since `syntax.symbol_chars` does not contain '+' and '-' characters, *symbol*
-- does not need to match them.
--
-- Another consequence of the "everything is an object" rule is that, like
-- numbers, strings, arrays, hashes, etc. may also exist alone. (For example,
-- "[1, 2, 3]." needs to show Array completions.) Since symbols only contain
-- alphanumerics, '_', '?', and '!' characters, the Ruby Adeptsense needs to
-- override the default [`get_symbol()`](#get_symbol) functionality.
--
--     function sense:get_symbol()
--       local line, p = buffer:get_cur_line()
--       if line:sub(1, p):match('%[.-%]%s*%.$') then
--         return 'Array', ''
--       end
--       -- More checks for strings, hashes, symbols, regexps, etc.
--       return self.super.get_symbol(self)
--     end
--
-- **Java**
--
-- Autocompletion of Java `import` statements is something nice to have. You can
-- construct an import completion list from Ctags's package tags. By default,
-- Adeptsense ignores any tags not mapped to classes, functions, or fields in
-- [`ctags_kinds`](#ctags_kinds) and passes the unknown tags to
-- [`handle_ctag()`](#handle_ctag). In this case, the Java Adeptsense needs to
-- handle package ('p') tags.
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
-- Now that the Adeptsense has a set of import completions, the '.' trigger key
-- should only autocomplete packages on a line that starts with "import". Since
-- [`get_completions()`](#get_completions) is responsible for getting the set of
-- completions for a particular symbol, the Java Adeptsense must override it.
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
-- The "?1" and "?2" appended to each completion entry tell Adeptsense which
-- icon to display for each entry in the autocompletion list. Entries do not
-- need to have icons. '1' is for fields and '2' is for functions. In this case,
-- the icons distinguish between a parent package and a package with no
-- children.
--
-- Finally the Adeptsense should clear the `imports` table it created when the
-- Adeptsense is cleared so-as to free up memory immediately. This is done in
-- [`handle_clear()`](#handle_clear).
--
--     function sense:handle_clear()
--       self.imports = {}
--     end
--
-- ### Child Language Adeptsenses
--
-- When the user triggers autocompletion, Adeptsense uses the Adeptsense for the
-- language at the *caret position*, not necessarily the Adeptsense for the
-- parent language. For example, when editing CSS inside of an HTML file, the
-- user expects CSS completions. However, Textadept does not automatically load
-- child language Adeptsenses. The parent language must do this. For example:
--
--     -- In file *modules/hypertext/init.lua*.
--     -- Load CSS Adeptsense.
--     if not _M.css then _M.css = require('css') end
--
-- ## Generating Lua Adeptsense
--
-- You can generate Lua Adeptsense for your own modules using the Lua language
-- module's *adeptsensedoc.lua* module with [LuaDoc][]:
--
--     luadoc -d . --doclet _HOME/modules/lua/adeptsensedoc [module(s)]
--
-- with `_HOME` being where you installed Textadept. LuaDoc outputs *tags* and
-- *api* files to the current directory. Load them via
-- [`load_ctags()`](#load_ctags) and [`api_files`](#api_files), respectively.
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
-- The latter ``-- * `field_name` `` syntax may appear anywhere inside a module,
-- not just the module LuaDoc.
-- @field always_show_globals (bool)
--   Include globals in the list of completions offered.
--   Globals are classes, functions, and fields that do not belong to another
--   class. They are contained in `sense.completions['']`.
--   The default value is `true`.
-- @field FUNCTION_IMAGE (string)
--   XPM image for Adeptsense functions.
-- @field FIELD_IMAGE (string)
--   XPM image for Adeptsense fields.
-- @field CLASS (string)
--   Ctags kind for Adeptsense classes.
-- @field FUNCTION (string)
--   Ctags kind for Adeptsense functions.
-- @field FIELD (string)
--   Ctags kind for Adeptsense fields.
module('textadept.adeptsense')]]

local senses = {}

M.FUNCTION_IMAGE = not CURSES and '/* XPM */\nstatic char *function[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c #000000",\n". c #E0BC38",\n"X c #F0DC5C",\n"o c #FCFC80",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOO  OOOO",\n"OOOOOOOOO oo  OO",\n"OOOOOOOO ooooo O",\n"OOOOOOO ooooo. O",\n"OOOO  O XXoo.. O",\n"OOO oo  XXX... O",\n"OO ooooo XX.. OO",\n"O ooooo.  X. OOO",\n"O XXoo.. O  OOOO",\n"O XXX... OOOOOOO",\n"O XXX.. OOOOOOOO",\n"OO  X. OOOOOOOOO",\n"OOOO  OOOOOOOOOO"\n};' or '*'
M.FIELD_IMAGE = not CURSES and '/* XPM */\nstatic char *field[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c #000000",\n". c #8C748C",\n"X c #9C94A4",\n"o c #ACB4C0",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOO oo  OOO",\n"OOOOOOO ooooo OO",\n"OOOOOO ooooo. OO",\n"OOOOOO XXoo.. OO",\n"OOOOOO XXX... OO",\n"OOOOOO XXX.. OOO",\n"OOOOOOO  X. OOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOOOOOOOOOO"\n};' or '+'

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
  sense = sense or (_M[buffer:get_lexer(true)] or {}).sense
  if not sense then return end
  local symbol, part = sense:get_symbol()
  local completions = sense:get_completions(symbol, only_fields, only_functions)
  if not completions then return false end
  buffer:register_image(1, M.FIELD_IMAGE)
  buffer:register_image(2, M.FUNCTION_IMAGE)
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
  local location = ui.filteredlist(title, columns, items, false,
                                   '--output-column', '3')
  if not location then return end
  local path, line = location:match('^(%a?:?[^:]+):(.+)$')
  io.open_file(path)
  if not tonumber(line) then
    -- /^ ... $/
    buffer.target_start, buffer.target_end = 0, buffer.length
    buffer.search_flags = buffer.SCFIND_REGEXP
    if buffer:search_in_target(line:sub(2, -2)) >= 0 then
      buffer:goto_pos(buffer.target_start)
    end
  else
    textadept.editing.goto_line(tonumber(line))
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
-- @usage local lua_sense = textadept.adeptsense.new('lua')
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
-- @usage luasense.ctags_kinds = {f = textadept.adeptsense.FUNCTION}
-- @usage csense.ctags_kinds = {m = textadept.adeptsense.FIELD,
--   f = textadept.adeptsense.FUNCTION, c = textadept.adeptsense.CLASS,
--   s = textadept.adeptsense.CLASS}
-- @usage javasense.ctags_kinds = {f = textadept.adeptsense.FIELD,
--   m = textadept.adeptsense.FUNCTION, c = textadept.adeptsense.CLASS,
--   i = textadept.adeptsense.CLASS}
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
--   second, optional capture contains the class's superclass (if any). If no
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

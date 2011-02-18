-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Language autocompletion support for the textadept module.
module('_m.textadept.adeptsense', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `FUNCTIONS`: XPM image for adeptsense functions.
-- * `FIELDS`: XPM image for adeptsense fields.

local senses = {}

FUNCTIONS = '/* XPM */\nstatic char *function[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c black",\n". c #E0BC38",\n"X c #F0DC5C",\n"o c #FCFC80",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOO  OOOO",\n"OOOOOOOOO oo  OO",\n"OOOOOOOO ooooo O",\n"OOOOOOO ooooo. O",\n"OOOO  O XXoo.. O",\n"OOO oo  XXX... O",\n"OO ooooo XX.. OO",\n"O ooooo.  X. OOO",\n"O XXoo.. O  OOOO",\n"O XXX... OOOOOOO",\n"O XXX.. OOOOOOOO",\n"OO  X. OOOOOOOOO",\n"OOOO  OOOOOOOOOO"\n};'
FIELDS = '/* XPM */\nstatic char *field[] = {\n/* columns rows colors chars-per-pixel */\n"16 16 5 1",\n"  c black",\n". c #8C748C",\n"X c #9C94A4",\n"o c #ACB4C0",\n"O c None",\n/* pixels */\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOOOOOOOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOO oo  OOO",\n"OOOOOOO ooooo OO",\n"OOOOOO ooooo. OO",\n"OOOOOO XXoo.. OO",\n"OOOOOO XXX... OO",\n"OOOOOO XXX.. OOO",\n"OOOOOOO  X. OOOO",\n"OOOOOOOOO  OOOOO",\n"OOOOOOOOOOOOOOOO"\n};'

---
-- Returns a full symbol (if any) and current symbol part (if any) behind the
-- caret.
-- For example: buffer.cur would return 'buffer' and 'cur'.
-- @param sense The adeptsense returned by adeptsense.new().
-- @return symbol or '', part or ''.
function get_symbol(sense)
  local line, p = buffer:get_cur_line()
  local symbol, part =
    line:sub(1, p):match('('..sense.syntax.symbol_chars..'-)[^%w_]+([%w_]*)$')
  if not symbol then part = line:sub(1, p):match('([%w_]*)$') end
  return symbol or '', part or ''
end

---
-- Returns the class name for a given symbol.
-- If the symbol is sense.syntax.self and a class definition using the
-- sense.syntax.class_definition keyword is found, that class is returned.
-- Otherwise the buffer is searched backwards for a type declaration of the
-- symbol according to the patterns in sense.syntax.type_declarations.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param symbol The symbol to get the class of.
-- @return class or nil
-- @see syntax
function get_class(sense, symbol)
  local buffer = buffer
  local self = sense.syntax.self
  local class_definition = sense.syntax.class_definition
  local completions = sense.completions
  local symbol_chars = sense.syntax.symbol_chars
  local type_declarations = sense.syntax.type_declarations
  local type_assignments = sense.syntax.type_assignments
  local assignment_patt = symbol..'%s*=%s*([^\r\n]+)'
  local class, assignment
  for i = buffer:line_from_position(buffer.current_pos), 0, -1 do
    local s, e
    if symbol == self or symbol == '' then
      -- Determine type from the class declaration.
      s, e, class = buffer:get_line(i):find(class_definition)
      if class and not completions[class] then class = nil end
    else
      -- Search for a type declaration or type assignment.
      local line = buffer:get_line(i)
      if line:find(symbol) then
        for _, patt in ipairs(type_declarations) do
          s, e, class = line:find(patt:gsub('%%_', symbol))
          if class then break end
        end
        s, e, assignment = line:find(assignment_patt)
        if assignment then
          for patt, type in pairs(type_assignments) do
            local captures = { assignment:match(patt) }
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

---
-- Returns a list of completions for the given symbol.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param symbol The symbol to get completions for.
-- @param only_fields If true, returns list of only fields; defaults to false.
-- @param only_functions If true, returns list of only functions; defaults to
--   false.
-- @return completion_list or nil
function get_completions(sense, symbol, only_fields, only_functions)
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
      include_globals = compls[''] ~= nil
    end
  end

  -- Create list of completions.
  local c = {}
  if not only_fields then
    for _, v in ipairs(compls[class].functions) do c[#c + 1] = v end
    if include_globals then
      for _, v in ipairs(compls[''].functions) do c[#c + 1] = v end
    end
  end
  if not only_functions then
    for _, v in ipairs(compls[class].fields) do c[#c + 1] = v end
    if include_globals then
      for _, v in ipairs(compls[''].fields) do c[#c + 1] = v end
    end
  end
  for _, inherited in ipairs(sense.class_list[class] or {}) do
    if compls[inherited] then
      if not only_fields then
        for _, v in ipairs(compls[inherited].functions) do c[#c + 1] = v end
      end
      if not only_functions then
        for _, v in ipairs(compls[inherited].fields) do c[#c + 1] = v end
      end
    end
  end

  -- Remove duplicates.
  table.sort(c)
  local table_remove = table.remove
  for i = #c, 2, -1 do if c[i] == c[i - 1] then table_remove(c, i) end end
  return c
end

---
-- Shows an autocompletion list for the symbol behind the caret.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param only_fields If true, returns list of only fields; defaults to false.
-- @param only_functions If true, returns list of only functions; defaults to
--   false.
-- @return true on success or false.
-- @see get_symbol
-- @see get_completions
function complete(sense, only_fields, only_functions)
  local buffer = buffer
  local symbol, part = sense:get_symbol()
  local completions = sense:get_completions(symbol, only_fields, only_functions)
  if not completions then return false end
  buffer:clear_registered_images()
  buffer:register_image(1, FIELDS)
  buffer:register_image(2, FUNCTIONS)
  buffer:auto_c_show(#part, table.concat(completions, ' '))
  return true
end

---
-- Sets the trigger for autocompletion.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param c The character(s) that triggers the autocompletion. You can have up
--   to two characters.
-- @param only_fields If true, this trigger only completes fields. Defaults to
--   false.
-- @param only_functions If true, this trigger only completes functions.
--   Defaults to false.
-- @usage sense:add_trigger('.')
-- @usage sense:add_trigger(':', false, true) -- only functions
-- @usage sense:add_trigger('->')
function add_trigger(sense, c, only_fields, only_functions)
  if #c > 2 then return end -- TODO: warn
  local c1, c2 = c:match('.$'):byte(), #c > 1 and c:sub(1, 1):byte()
  local i = events.connect('char_added', function(char)
    if char == c1 and buffer:get_lexer() == sense.lexer then
      if c2 and buffer.char_at[buffer.current_pos - 2] ~= c2 then return end
      sense:complete(only_fields, only_functions)
    end
  end)
  sense.events[#sense.events + 1] = i
end

---
-- Returns a list of apidocs for the given symbol.
-- If there are multiple apidocs, the index of one to display is the value of
-- the 'pos' key in the returned list.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param symbol The symbol to get apidocs for.
-- @return apidoc_list or nil
function get_apidoc(sense, symbol)
  if not symbol then return nil end
  local apidocs = { pos = 1}
  local entity, func = symbol:match('^(.-)[^%w_]*([%w_]+)$')
  local c = func:sub(1, 1) -- for quick comparison
  local patt = '^'..func..'%s+(.+)$'
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
  if type(class) ~= 'string' then class = entity end -- fall back to entity
  for i, apidoc in ipairs(apidocs) do
    if apidoc:match('^[%w_]+') == class then
      apidocs.pos = i
      break
    end
  end
  return apidocs
end

---
-- Shows a calltip with API documentation for the symbol behind the caret.
-- @param sense The adeptsense returned by adeptsense.new().
-- @return true on success or false.
-- @see get_symbol
-- @see get_apidoc
function show_apidoc(sense)
  local symbol = sense:get_symbol()
  local apidocs = sense:get_apidoc(symbol)
  if not apidocs then return false end
  for i, doc in ipairs(apidocs) do
    doc = doc:gsub('\\\\', '%%esc%%'):gsub('\\n', '\n'):gsub('%%esc%%', '\\')
    if #apidocs > 1 then
      if not doc:find('\n') then doc = doc..'\n' end
      doc = '\001'..doc:gsub('\n', '\n\002', 1)
    end
    apidocs[i] = doc
  end
  buffer:call_tip_show(buffer.current_pos, apidocs[apidocs.pos or 1])
  -- Cycle through calltips.
  local event_id = events.connect('call_tip_click', function(position)
    apidocs.pos = apidocs.pos + (position == 1 and -1 or 1)
    if apidocs.pos > #apidocs then apidocs.pos = 1 end
    if apidocs.pos < 1 then apidocs.pos = #apidocs end
    buffer:call_tip_show(buffer.current_pos, apidocs[apidocs.pos])
  end)
  _G.timeout(1, function()
    if buffer:call_tip_active() then return true end
    events.disconnect('call_tip_click', event_id)
  end)
  return true
end

---
-- Loads the given ctags file for autocompletion.
-- It is recommended to pass '-n' to ctags in order to use line numbers instead
-- of text patterns to locate tags. This will greatly reduce memory usage for a
-- large number of symbols if nolocations is not true.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param tag_file The path of the ctags file to load.
-- @param nolocations If true, does not store the locations of the tags for use
--   by goto_ctag(). Defaults to false.
function load_ctags(sense, tag_file, nolocations)
  local ctags_kinds = sense.ctags_kinds
  local completions = sense.completions
  local locations = sense.locations
  local class_list = sense.class_list
  local ctags_fmt = '^(%S+)\t([^\t]+)\t(.-);"\t(.*)$'
  for line in io.lines(tag_file) do
    local tag_name, file_name, ex_cmd, ext_fields = line:match(ctags_fmt)
    if tag_name then
      local k = ext_fields:sub(1, 1)
      local kind = ctags_kinds[k]
      if kind == 'functions' or kind == 'fields' then
        -- Update completions.
        -- If no class structure is found, the global namespace is used.
        for _, key in ipairs{ 'class', 'interface', 'struct', 'union', '' } do
          local class = (#key == 0) and '' or ext_fields:match(key..':(%S+)')
          if class then
            if not completions[class] then
              completions[class] = { fields = {}, functions = {} }
            end
            local t = completions[class][kind]
            t[#t + 1] = tag_name..(kind == 'fields' and '?1' or '?2')
            -- Update locations.
            if not nolocations then
              if not locations[k] then locations[k] = {} end
              locations[k][class..'#'..tag_name] = { file_name, ex_cmd }
            end
            break
          end
        end
      elseif kind == 'classes' then
        -- Update class list.
        local inherits = ext_fields:match('inherits:(%S+)')
        if not inherits then inherits = ext_fields:match('struct:(%S+)') end
        if inherits then
          class_list[tag_name] = {}
          for class in inherits:gmatch('[^,]+') do
            local t = class_list[tag_name]
            t[#t + 1] = class
            -- Even though this class inherits fields and functions from others,
            -- an empty completions table needs to be added to it so
            -- get_completions() does not return prematurely.
            completions[tag_name] = { fields = {}, functions = {} }
          end
        end
        -- Update completions.
        -- Add the class to the global namespace.
        if not completions[''] then
          completions[''] = { fields = {}, functions = {} }
        end
        local t = completions[''].fields
        t[#t + 1] = tag_name..'?1'
        -- Update locations.
        if not nolocations then
          if not locations[k] then locations[k] = {} end
          locations[k][tag_name] = { file_name, ex_cmd }
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
-- Displays a filteredlist of all known symbols of the given kind (classes,
-- functions, fields, etc.) and jumps to the source of the selected one.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param k The ctag character kind (e.g. 'f' for a Lua function).
-- @param title The title for the filteredlist dialog.
function goto_ctag(sense, k, title)
  if not sense.locations[k] then return end -- no ctags loaded
  local items = {}
  local kind = sense.ctags_kinds[k]
  for k, v in pairs(sense.locations[k]) do
    items[#items + 1] = k:match('[^#]+$') -- symbol name
    if kind == 'functions' or kind == 'fields' then
      items[#items + 1] = k:match('^[^#]+') -- class name
    end
    items[#items + 1] = v[1]..':'..v[2]
  end
  local columns = { 'Name', 'Location' }
  if kind == 'functions' or kind == 'fields' then
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
    _m.textadept.editing.goto_line(tonumber(line))
  end
end

---
-- Called by load_ctags when a ctag kind is not recognized.
-- This method should be replaced with your own that is specific to the
-- language.
-- @param sense The adeptsense returned by adeptsense.new().
-- @param tag_name The tag name.
-- @param file_name The name of the file the tag belongs to.
-- @param ex_cmd The ex_cmd returned by ctags.
-- @param ext_fields The ext_fields returned by ctags.
function handle_ctag(sense, tag_name, file_name, ex_cmd, ext_fields) end

---
-- Clears an adeptsense.
-- This is necessary for loading a new ctags file or completions from a
-- different project.
-- @param sense The adeptsense returned by adeptsense.new().
function clear(sense)
  sense.class_list = {}
  sense.completions = {}
  sense.locations = {}
  sense:handle_clear()
  collectgarbage('collect')
end

---
-- Called when clearing an adeptsense.
-- This function should be replaced with your own if you have any persistant
-- objects that need to be deleted.
-- @param sense The adeptsense returned by adeptsense.new().
function handle_clear(sense) end

---
-- Creates a new adeptsense for the given lexer language.
-- Only one sense can exist per language.
-- @param lang The lexer language to create an adeptsense for.
-- @return adeptsense.
-- @usage local lua_sense = _m.textadept.adeptsense.new('lua')
function new(lang)
  local sense = senses[lang]
  if sense then
    sense.ctags_kinds = {}
    sense.api_files = {}
    for _, i in ipairs(sense.events) do events.disconnect('char_added', i) end
    sense.events = {}
    sense:clear()
  end

  sense = setmetatable({
    lexer = lang,
    events = {},

---
-- Contains a map of ctags kinds to adeptsense kinds.
-- Recognized kinds are 'functions', 'fields', and 'classes'. Classes are quite
-- simply containers for functions and fields so Lua modules would count as
-- classes. Any other kinds will be passed to handle_ctag() for user-defined
-- handling.
-- @usage luasense.ctags_kinds = { 'f' = 'functions' }
-- @usage csense.ctags_kinds = { 'm' = 'fields', 'f' = 'functions',
--   c = 'classes', s = 'classes' }
-- @usage javasense.ctags_kinds = { 'f' = 'fields', 'm' = 'functions',
--   c = 'classes', i = 'classes' }
-- @class table
-- @name ctags_kinds
-- @see handle_ctag
ctags_kinds = {},

---
-- Contains a map of classes and a list of their inherited classes.
-- @class table
-- @name class_list
class_list = {},

---
-- Contains lists of possible completions for known symbols.
-- Each symbol key has a table value that contains a list of field completions
-- with a `fields` key and a list of functions completions with a `functions`
-- key. This table is normally populated by load_ctags(), but can also be set
-- by the user.
-- @class table
-- @name completions
completions = {},

---
-- Contains the locations of known symbols.
-- This table is populated by load_ctags().
-- @class table
-- @name locations
locations = {},

---
-- Contains a list of api files used by show_apidoc().
-- Each line in the api file contains a symbol followed by a space character and
-- then the symbol's documentation. It is recommended to put the symbol's full
-- signature (e.g. Class.function(arg1, arg2, ...)) on the first line. Newlines
-- are represented with '\n'. A '\' before '\n' escapes the newline.
-- @class table
-- @name api_files
api_files = {},

---
-- Contains syntax-specific values for the language.
-- @field self The language's syntax-equivalent of 'self'. Default is 'self'.
-- @field class_definition A Lua pattern representing the language's class
--   definition syntax. The first capture returned must be the class name.
--   Defaults to 'class%s+([%w_]+)'.
-- @field symbol_chars A Lua pattern of characters allowed in a symbol,
--   including member operators. Default is '[%w_%.]'.
-- @field type_declarations A list of Lua patterns used for determining the
--   class type of a symbol. The first capture returned must be the class name. 
--   Use '%_' to match the symbol. Defaults to '(%u[%w_%.]+)%s+%_'.
-- @field type_assignments A map of Lua patterns to class types for variable
--   assignments. This is typically used for dynamically typed languages. For
--   example, `sense.type_assignments['^"'] = 'string'`  would recognize string 
--   assignments in Lua so the `foo` in `foo = "bar"` would be recognized as 
--   type `string`. The class type value can contain pattern captures.
-- @class table
-- @name syntax
-- @see get_class
syntax = {
  self = 'self',
  class_definition = 'class%s+([%w_]+)',
  symbol_chars = '[%w_%.]',
  type_declarations = {
    '(%u[%w_%.]+)%s+%_', -- Foo bar
  },
  type_assignments = {}
},

    super = setmetatable({}, { __index = _M })
  }, { __index = _M })

  senses[lang] = sense
  return sense
end

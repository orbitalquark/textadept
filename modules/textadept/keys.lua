-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Manages key commands in Textadept.
-- Default key commands should be defined in a separate file and loaded after
-- all modules.
-- There are several option variables used:
--   SCOPES_ENABLED: Flag indicating whether scopes/styles can be used for key
--     commands.
--   CTRL: The string representing the Control key.
--   SHIFT: The string representing the Shift key.
--   ALT: The string representing the Alt key.
--   ADD: The string representing used to join together a sequence of Control,
--     Shift, or Alt modifier keys.
--
-- @usage
-- Keys are defined in the global table 'keys'. Keys in that table are key
-- sequences, and values are tables of Lua functions and arguments to execute.
-- The exceptions are language names, style names, and keychains (discussed
-- later). Language names have table values of either key commands or style keys
-- with table values of key commands. See /lexers/lexer.lua for some default
-- style names. Each lexer's 'add_style' function adds additional styles, the
-- string argument being the style's name. For example:
--   keys = {
--     ['ctrl+f'] = { 'char_right', 'buffer' },
--     ['ctrl+b'] = { 'char_left',  'buffer' },
--     lua = {
--       ['ctrl+c'] = { 'add_text', 'buffer', '-- ' },
--       whitespace = { function() print('whitespace') end }
--     }
--   }
-- Style and lexer insensitive key commands should be placed in the lexer and
-- keys tables respectively.
--
-- When searching for a key command to execute in the keys table, key commands
-- in the current style have priority, then ones in the current lexer, and
-- finally the ones in the global table.
--
-- As mentioned, key commands are key-value pairs, the key being the key
-- sequence compiled from the CTRL, SHIFT, ALT, and ADD options (discussed
-- below) as well as the key pressed and the value being a table of a function
-- to call and its arguments. For the table, the first item can be either a Lua
-- function or a string (representing a function name). If it is a function, all
-- table items after it are used as arguments. If the first item is a string,
-- the next string is checked to be either 'buffer' or 'view' and the current
-- buffer or view is used as the table with the function name as a field,
-- indexing a function. The current buffer or view is then used as the first
-- argument to that function, with all items after the second following as
-- additional ones. Basically in Lua: {buffer|view}:{first_item}(...)
--
-- As noted previously, key sequences can be compiled differently via the CTRL,
-- SHIFT, ALT, and ADD options. The first three indicate the text for each
-- respective modifier key and ADD is the text inserted between modifiers.
--
-- Key commands can be chained like in Emacs. Instead of a key sequence having
-- a table of a function and its arguments, it has a table of key commands (much
-- like lexer or style specific key commands). My default, the 'escape' key
-- cancels the current keychain, but it can be redefined by setting the
-- 'clear_sequence' key in the global keys table. It cannot be chained however.
--
-- Keys that have values higher than 255 cannot be represented by a string, but
-- can have a string representation defined in the KEYSYMS table.
--
-- Keep in mind that all Lua functions used in key commands must be defined
-- BEFORE the key command references it. Therefore the module containing key
-- commands should be loaded LAST, after all other modules have been loaded.
module('_m.textadept.keys', package.seeall)

-- options
local SCOPES_ENABLED = true
local CTRL, SHIFT, ALT, ADD = 'c', 's', 'a', ''
-- end options

---
-- [Local table] Lookup table for key values higher than 255.
-- If a key value given to 'keypress' is higher than 255, this table is used to
-- return a string representation of the key if it exists.
-- @class table
-- @name KEYSYMS
local KEYSYMS = { -- from <gdk/gdkkeysyms.h>
  [65288] = '\b',
  [65289] = '\t',
  [65293] = '\n',
  [65307] = 'esc',
  [65535] = 'del',
  [65360] = 'home',
  [65361] = 'left',
  [65362] = 'up',
  [65363] = 'right',
  [65364] = 'down',
  [65365] = 'pup',
  [65366] = 'pdown',
  [65367] = 'end',
  [65379] = 'ins',
  [65470] = 'f1', [65471] = 'f2',  [65472] = 'f3',  [65473] = 'f4',
  [65474] = 'f5', [65475] = 'f6',  [65476] = 'f7',  [65477] = 'f8',
  [65478] = 'f9', [65479] = 'f10', [65480] = 'f11', [65481] = 'f12',
}

--- [Local table] The current key sequence.
-- @class table
-- @name keychain
local keychain = {}

-- local functions
local try_get_cmd1, try_get_cmd2, try_get_cmd3, try_get_cmd

---
-- Clears the current key sequence.
function clear_key_sequence() keychain = {} textadept.statusbar_text = '' end

---
-- [Local function] Handles Textadept keypresses.
-- It is called every time a key is pressed, and based on lexer and scope,
-- executes a command. The command is looked up in the global 'keys' key
-- command table.
-- @return whatever the executed command returns, true by default. A true
--   return value will tell Textadept not to handle the key afterwords.
local function keypress(code, shift, control, alt)
  local buffer, textadept = buffer, textadept
  local keys = _G.keys
  local key_seq = ''
  if control then key_seq = key_seq..CTRL..ADD end
  if shift   then key_seq = key_seq..SHIFT..ADD end
  if alt     then key_seq = key_seq..ALT..ADD end
  --print(code, string.char(code))
  if code < 256 then
    key_seq = key_seq..string.char(code):lower()
  else
    if not KEYSYMS[code] then return end
    key_seq = key_seq..KEYSYMS[code]
  end

  if key_seq == keys.clear_sequence and #keychain > 0 then
    clear_key_sequence()
    return true
  end

  local lexer = buffer:get_lexer_language()
  local style = buffer.style_at[buffer.current_pos]
  local scope = buffer:get_style_name(style)
  --print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)

  keychain[#keychain + 1] = key_seq
  local ret, func, args
  if SCOPES_ENABLED then
    ret, func, args = pcall(try_get_cmd1, keys, key_seq, lexer, scope)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd2, keys, key_seq, lexer)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd3, keys, key_seq)
  end

  if ret then
    clear_key_sequence()
    if type(func) == 'function' then
      local ret, retval = pcall( func, unpack(args) )
      if ret then
        if type(retval) == 'boolean' then return retval end
      else textadept.events.error(retval) end -- error
    end
    return true
  else
    -- Clear key sequence because it's not part of a chain.
    -- (try_get_cmd throws error number -1.)
    if func ~= -1 then
      local size = #keychain - 1
      clear_key_sequence()
      if size > 0 then -- previously in a chain
        textadept.statusbar_text = 'Invalid Sequence'
        return true
      end
    else return true end
  end
end
textadept.events.add_handler('keypress', keypress, 1)

---
-- [Local function] Tries to get a key command based on the lexer and current
-- scope.
try_get_cmd1 = function(keys, key_seq, lexer, scope)
  return try_get_cmd( keys[lexer][scope] )
end

---
-- [Local function] Tries to get a key command based on the lexer.
try_get_cmd2 = function(keys, key_seq, lexer)
  return try_get_cmd( keys[lexer] )
end

---
-- [Local function] Tries to get a global key command.
try_get_cmd3 = function(keys, key_seq)
  return try_get_cmd(keys)
end

---
-- [Local function] Helper function that gets commands associated with the
-- current keychain from 'keys'.
-- If the current item in the keychain is part of a chain, throw an error value
-- of -1. This way, pcall will return false and -1, where the -1 can easily and
-- efficiently be checked rather than using a string error message.
try_get_cmd = function(active_table)
  local str_seq = ''
  for _, key_seq in ipairs(keychain) do
    str_seq = str_seq..key_seq..' '
    active_table = active_table[key_seq]
  end
  if #active_table == 0 and next(active_table) then
    textadept.statusbar_text = 'Keychain: '..str_seq
    error(-1, 0)
  else
    local func = active_table[1]
    if type(func) == 'function' then
      return func, { unpack(active_table, 2) }
    elseif type(func) == 'string' then
      local object = active_table[2]
      if object == 'buffer' then
        return buffer[func], { buffer, unpack(active_table, 3) }
      elseif object == 'view' then
        return view[func], { view, unpack(active_table, 3) }
      end
    else
      error( 'Unknown command: '..tostring(func) )
    end
  end
end

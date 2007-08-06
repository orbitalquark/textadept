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
module('modules.textadept.keys', package.seeall)

-- options
local SCOPES_ENABLED = true
local CTRL, SHIFT, ALT, ADD = 'c', 's', 'a', ''
-- end options

---
-- [Local table] Lookup table for key values higher than 255.
-- If a key value given to OnKey is higher than 255, this table is used to
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
function clear_key_sequence()
  keychain = {}
  textadept.statusbar_text = ''
end

---
-- Handles Textadept keypresses.
-- It is called every time a key is pressed and determines which commands to
-- execute or which new key in a chain to enter based on the current key
-- sequence, lexer, and scope.
-- @return keypress returns what the commands it executes return. If nothing is
--   returned, keypress returns true by default. A true return value will tell
--   Textadept not to handle the key afterwords.
function keypress(code, shift, control, alt)
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
      else textadept.handlers.error(retval) end -- error
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
textadept.handlers.add_function_to_handler('keypress', keypress, 1)

-- Note the following functions are called inside pcall so error handling or
-- checking if keys exist etc. is not necessary.

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
-- [Local function] Helper function to get commands with the current keychain.
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

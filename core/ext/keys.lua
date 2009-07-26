-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Manages key commands in Textadept.
-- Default key commands should be defined in a separate file and loaded after
-- all modules.
module('textadept.keys', package.seeall)

-- Markdown:
-- ## Settings
--
-- * `SCOPES_ENABLED`: Flag indicating whether scopes/styles can be used for key
--   commands.
-- * `CTRL`: The string representing the Control key.
-- * `SHIFT`: The string representing the Shift key.
-- * `ALT`: The string representing the Alt key (the Apple key on Mac OSX).
-- * `ADD`: The string representing used to join together a sequence of Control,
--   Shift, or Alt modifier keys.
--

-- settings
local SCOPES_ENABLED = true
local ADD = ''
local CTRL = 'c'..ADD
local SHIFT = 's'..ADD
local ALT = 'a'..ADD
-- end settings

---
-- Global container that holds all key commands.
-- @class table
-- @name _G.keys
_G.keys = {}

-- optimize for speed
local keys = _G.keys
local string = _G.string
local string_char = string.char
local string_format = string.format
local pcall = _G.pcall
local ipairs = _G.ipairs
local next = _G.next
local type = _G.type
local unpack = _G.unpack
local MAC = _G.MAC

-- Lookup table for key values higher than 255.
-- If a key value given to 'keypress' is higher than 255, this table is used to
-- return a string representation of the key if it exists.
local KEYSYMS = { -- from <gdk/gdkkeysyms.h>
  [65056] = '\t', -- backtab; will be 'shift'ed
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

-- The current key sequence.
local keychain = {}

-- local functions
local try_get_cmd1, try_get_cmd2, try_get_cmd3, try_get_cmd

---
-- Clears the current key sequence.
function clear_key_sequence()
  keychain = {}
  textadept.statusbar_text = ''
end

-- Handles Textadept keypresses.
-- It is called every time a key is pressed, and based on lexer and scope,
-- executes a command. The command is looked up in the global 'keys' key
-- command table.
-- @return whatever the executed command returns, true by default. A true
--   return value will tell Textadept not to handle the key afterwords.
local function keypress(code, shift, control, alt)
  local buffer = buffer
  local key
  --print(code, string.char(code))
  if code < 256 then
    key = string_char(code):lower()
    if MAC and not shift and not control and not alt then
      local ch = string_char(code)
      -- work around native GTK-OSX's handling of Alt key
      if ch:find('[%p%d]') and #keychain == 0 then
        if buffer.anchor ~= buffer.current_pos then buffer:delete_back() end
        buffer:add_text(ch)
        textadept.events.handle('char_added', code)
        return true
      end
    end
  else
    if not KEYSYMS[code] then return end
    key = KEYSYMS[code]
  end
  control = control and CTRL or ''
  shift = shift and SHIFT or ''
  alt = alt and ALT or ''
  local key_seq = string_format('%s%s%s%s', control, shift, alt, key)

  if #keychain > 0 and key_seq == keys.clear_sequence then
    clear_key_sequence()
    return true
  end

  local lexer = buffer:get_lexer_language()
  keychain[#keychain + 1] = key_seq
  local ret, func, args
  if SCOPES_ENABLED then
    local style = buffer.style_at[buffer.current_pos]
    local scope = buffer:get_style_name(style)
    --print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)
    ret, func, args = pcall(try_get_cmd1, keys, lexer, scope)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd2, keys, lexer)
  end
  if not ret and func ~= -1 then
    ret, func, args = pcall(try_get_cmd3, keys)
  end

  if ret then
    clear_key_sequence()
    if type(func) == 'function' then
      local ret, retval = pcall(func, unpack(args))
      if ret then
        if type(retval) == 'boolean' then return retval end
      else
        error(retval)
      end
    end
    return true
  else
    -- Clear key sequence because it's not part of a chain.
    -- (try_get_cmd throws error number -1.)
    if func ~= -1 then
      local size = #keychain - 1
      clear_key_sequence()
      if size > 0 then -- previously in a chain
        textadept.statusbar_text = locale.KEYS_INVALID
        return true
      end
    else
      return true
    end
  end
end
textadept.events.add_handler('keypress', keypress, 1)

-- Tries to get a key command based on the lexer and current scope.
try_get_cmd1 = function(keys, lexer, scope)
  return try_get_cmd(keys[lexer][scope])
end

-- Tries to get a key command based on the lexer.
try_get_cmd2 = function(keys, lexer)
  return try_get_cmd(keys[lexer])
end

-- Tries to get a global key command.
try_get_cmd3 = function(keys)
  return try_get_cmd(keys)
end

-- Helper function that gets commands associated with the current keychain from
-- 'keys'.
-- If the current item in the keychain is part of a chain, throw an error value
-- of -1. This way, pcall will return false and -1, where the -1 can easily and
-- efficiently be checked rather than using a string error message.
try_get_cmd = function(active_table)
  for _, key_seq in ipairs(keychain) do active_table = active_table[key_seq] end
  if #active_table == 0 and next(active_table) then
    textadept.statusbar_text = locale.KEYCHAIN..table.concat(keychain, ' ')
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
      error(locale.KEYS_UNKNOWN_COMMAND..tostring(func))
    end
  end
end

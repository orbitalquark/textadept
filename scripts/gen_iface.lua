#!/usr/bin/lua
-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local constants, functions, properties, events = {}, {}, {}, {}
local const_patt = '^val ([%w_]+)=([-%dx%x]+)'
local event_patt = '^evt %a+ ([%w_]+)=(%d+)(%b())'
local msg_patt = '^(%a+) (%a+) (%w+)=(%d+)%((%a*) ?([^,]*),%s*(%a*)'
local types = {
  [''] = 0, void = 0, int = 1, length = 2, position = 1, line = 1, colour = 3,
  bool = 4, keymod = 5, string = 6, stringresult = 7, cells = 8, pointer = 1,
  textrange = 9, findtext = 10, formatrange = 11
}
local ignores = { -- constants to ignore
  '^INDIC[012S]_', '^INVALID_POSITION', '^KEYWORDSET_MAX', '^SC_AC_',
  '^SC_DOCUMENTOPTION_', '^SC_CACHE_', '^SC_CHARSET_', '^SC_EFF_',
  '^SC_FONT_SIZE_MULTIPLIER', '^SC_INDIC', '^SC_LINE_END_TYPE_', '^SC_PHASES_',
  '^SC_POPUP_', '^SC_PRINT_', '^SC_STATUS_', '^SC_TECHNOLOGY_', '^SC_TYPE_',
  '^SC_WEIGHT_', '^SCE_', '^SCEN_', '^SCFIND_POSIX', '^SCI_', '^SCK_',
  '^SCLEX_', '^UNDO_MAY_COALESCE'
}
local changed_setter = {} -- holds properties changed to setter functions
local function to_lua_name(camel_case)
  return camel_case:gsub('([a-z])([A-Z])', '%1_%2'):
    gsub('([A-Z])([A-Z][a-z])', '%1_%2'):lower()
end

for line in io.lines('../src/scintilla/include/Scintilla.iface') do
  if line:find('^val ') then
    local name, value = line:match(const_patt)
    for i = 1, #ignores do if name:find(ignores[i]) then goto continue end end
    name = name:gsub('^SC_', ''):gsub('^SC([^N]%u+)', '%1')
    if name == 'FIND_REGEXP' then
      value = tostring(tonumber(value) + 2^23) -- add SCFIND_CXX11REGEX
      value = value:gsub('%.0$', '') -- Lua 5.3+ may append this
    elseif name == 'MASK_FOLDERS' then
      value = tostring(-33554432)
    end
    constants[#constants + 1] = string.format('%s=%s', name, value)
  elseif line:find('^evt ') then
    local name, value, param_list = line:match(event_patt)
    name = to_lua_name(name)
    local event, has_modifiers = {string.format('%q', name)}, false
    for param in param_list:gmatch('(%a+)[,)]') do
      if param ~= 'void' and param ~= 'modifiers' then
        event[#event + 1] = string.format('%q', to_lua_name(param))
      elseif param == 'modifiers' then
        has_modifiers = true
      end
    end
    if has_modifiers then event[#event + 1] = '"modifiers"' end
    events[#events + 1] = value
    events[value] = table.concat(event, ',')
  elseif line:find('^fun ') then
    local _, rtype, name, id, wtype, param, ltype = line:match(msg_patt)
    if rtype:find('^%u') then rtype = 'int' end
    if wtype:find('^%u') then wtype = 'int' end
    if ltype:find('^%u') then ltype = 'int' end
    name = to_lua_name(name)
    if name == 'convert_eo_ls' then name = 'convert_eols' end
    if types[wtype] == types.int and param == 'length' then wtype = 'length' end
    functions[#functions + 1] = name
    functions[name] = {id, types[rtype], types[wtype], types[ltype]}
  elseif line:find('^get ') or line:find('^set ') then
    local kind, rtype, name, id, wtype, _, ltype = line:match(msg_patt)
    if rtype:find('^%u') then rtype = 'int' end
    if wtype:find('^%u') then wtype = 'int' end
    if ltype:find('^%u') then ltype = 'int' end
    name = to_lua_name(name:gsub('[GS]et%f[%u]', ''))
    if kind == 'get' and types[wtype] == types.int and
       types[ltype] == types.int or wtype == 'bool' and ltype ~= '' or
       changed_setter[name] then
      -- Special case getter/setter; handle as function.
      local fname = kind .. '_' .. name
      functions[#functions + 1] = fname
      functions[fname] = {id, types[rtype], types[wtype], types[ltype]}
      changed_setter[name] = true
      goto continue
    end
    if not properties[name] then
      properties[#properties + 1] = name
      properties[name] = {0, 0, 0, 0}
    end
    local prop = properties[name]
    if kind == 'get' then
      prop[1] = id
      prop[3] = types[ltype ~= 'stringresult' and rtype or ltype]
      if wtype ~= '' then prop[4] = types[wtype] end
    else
      prop[2] = id
      if prop[1] == 0 then
        prop[3] = types[wtype ~= '' and ltype == '' and wtype or ltype]
      end
      prop[4] = types[ltype ~= '' and wtype or ltype]
    end
  elseif line:find('cat Provisional') then
    break
  end
  ::continue::
end

-- Add mouse events from Scintilla curses manually.
constants[#constants + 1] = 'MOUSE_PRESS=1'
constants[#constants + 1] = 'MOUSE_DRAG=2'
constants[#constants + 1] = 'MOUSE_RELEASE=3'

table.sort(constants)
table.sort(functions)
table.sort(properties)
table.sort(events)

local f = io.open('../core/iface.lua', 'wb')
f:write([=[
-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Scintilla constants, functions, and properties.
-- Do not modify anything in this module. Doing so will have unpredictable
-- consequences.
module('_SCINTILLA')]]

]=])
f:write([[
---
-- Map of Scintilla constant names to their numeric values.
-- @class table
-- @name constants
-- @see _G.buffer
M.constants = {]])
f:write(table.concat(constants, ','))
f:write('}\n\n')
f:write([[
---
-- Map of Scintilla function names to tables containing their IDs, return types,
-- wParam types, and lParam types. Types are as follows:
--
--   + `0`: Void.
--   + `1`: Integer.
--   + `2`: Length of the given lParam string.
--   + `3`: Integer position.
--   + `4`: Color, in "0xBBGGRR" format.
--   + `5`: Boolean `true` or `false`.
--   + `6`: Bitmask of Scintilla key modifiers and a key value.
--   + `7`: String parameter.
--   + `8`: String return value.
-- @class table
-- @name functions
M.functions = {]])
for _, func in ipairs(functions) do
  f:write(
    string.format('%s={%d,%d,%d,%d},', func, table.unpack(functions[func])))
end
f:write('}\n\n')
f:write([[
---
-- Map of Scintilla property names to table values containing their "get"
-- function IDs, "set" function IDs, return types, and wParam types.
-- The wParam type will be non-zero if the property is indexable.
-- Types are the same as in the `functions` table.
-- @see functions
-- @class table
-- @name properties
M.properties = {]])
for _, property in ipairs(properties) do
  f:write(string.format(
    '%s={%d,%d,%d,%d},', property, table.unpack(properties[property])))
end
f:write('}\n\n')
f:write([[
---
-- Map of Scintilla event IDs to tables of event names and event parameters.
-- @class table
-- @name events
M.events = {]])
for _, event in ipairs(events) do
  f:write(string.format('[%s]={%s},', event, events[event]))
end
f:write('}\n\n')
f:write([[
local marker_number, indic_number, list_type, image_type = -1, -1, 0, 0

---
-- Returns a unique marker number for use with `buffer.marker_define()`.
-- Use this function for custom markers in order to prevent clashes with
-- identifiers of other custom markers.
-- @usage local marknum = _SCINTILLA.next_marker_number()
-- @see buffer.marker_define
-- @name next_marker_number
function M.next_marker_number()
  assert(marker_number < M.constants.MARKER_MAX, 'too many markers in use')
  marker_number = marker_number + 1
  return marker_number
end

---
-- Returns a unique indicator number for use with custom indicators.
-- Use this function for custom indicators in order to prevent clashes with
-- identifiers of other custom indicators.
-- @usage local indic_num = _SCINTILLA.next_indic_number()
-- @see buffer.indic_style
-- @name next_indic_number
function M.next_indic_number()
  assert(indic_number < M.constants.INDICATOR_MAX, 'too many indicators in use')
  indic_number = indic_number + 1
  return indic_number
end

---
-- Returns a unique user list identier number for use with
-- `buffer.user_list_show()`.
-- Use this function for custom user lists in order to prevent clashes with
-- list identifiers of other custom user lists.
-- @usage local list_type = _SCINTILLA.next_user_list_type()
-- @see buffer.user_list_show
-- @name next_user_list_type
function M.next_user_list_type()
  list_type = list_type + 1
  return list_type
end

---
-- Returns a unique image type identier number for use with
-- `buffer.register_image()` and `buffer.register_rgba_image()`.
-- Use this function for custom image types in order to prevent clashes with
-- identifiers of other custom image types.
-- @usage local image_type = _SCINTILLA.next_image_type()
-- @see buffer.register_image
-- @see buffer.register_rgba_image
-- @name next_image_type
function M.next_image_type()
  image_type = image_type + 1
  return image_type
end

return M
]])
f:close()

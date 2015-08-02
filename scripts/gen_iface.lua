#!/usr/bin/lua
-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

local constants, functions, properties = {}, {}, {}
local const_patt = '^val ([%w_]+)=([-%dx%x]+)'
local event_patt = '^evt %a+ ([%w_]+)=(%d+)'
local msg_patt = '^(%a+) (%a+) (%w+)=(%d+)%((%a*) ?([^,]*),%s*(%a*)'
local types = {
  [''] = 0, void = 0, int = 1, length = 2, position = 3, colour = 4, bool = 5,
  keymod = 6, string = 7, stringresult = 8, cells = 9, textrange = 10,
  findtext = 11, formatrange = 12
}
local ignores = { -- constants to ignore
  '^INDIC[012S]_', '^INVALID_POSITION', '^KEYWORDSET_MAX', '^SC_AC_',
  '^SC_CACHE_', '^SC_CHARSET_', '^SC_CP_DBCS', '^SC_EFF_',
  '^SC_FONT_SIZE_MULTIPLIER', '^SC_INDIC', '^SC_LINE_END_TYPE_', '^SC_PHASES_',
  '^SC_PRINT_', '^SC_STATUS_', '^SC_TECHNOLOGY_', '^SC_TYPE_', '^SC_WEIGHT_',
  '^SCE_', '^SCEN_', '^SCFIND_POSIX', '^SCI_', '^SCK_', '^SCLEX_',
  '^UNDO_MAY_COALESCE'
}
local changed_setter = {} -- holds properties changed to setter functions
local string_format, table_unpack = string.format, table.unpack

for line in io.lines('../src/scintilla/include/Scintilla.iface') do
  if line:find('^val ') then
    local name, value = line:match(const_patt)
    for i = 1, #ignores do if name:find(ignores[i]) then goto continue end end
    name = name:gsub('^SC_', ''):gsub('^SC([^N]%u+)', '%1')
    if name == 'FIND_REGEXP' then
      value = tostring(tonumber(value) + 2^22) -- add SCFIND_POSIX
    elseif name == 'MASK_FOLDERS' then
      value = '-33554432'
    end
    constants[#constants + 1] = string_format('%s=%s', name, value)
  elseif line:find('^evt ') then
    local name, value = line:match(event_patt)
    constants[#constants + 1] = string_format('SCN_%s=%s', name:upper(), value)
  elseif line:find('^fun ') then
    local _, rtype, name, id, wtype, param, ltype = line:match(msg_patt)
    name = name:gsub('([a-z])([A-Z])', '%1_%2')
               :gsub('([A-Z])([A-Z][a-z])', '%1_%2'):lower()
    if name == 'convert_eo_ls' then name = 'convert_eols' end
    if wtype == 'int' and param == 'length' then wtype = 'length' end
    functions[#functions + 1] = name
    functions[name] = {id, types[rtype], types[wtype], types[ltype]}
  elseif line:find('^get ') or line:find('^set ') then
    local kind, rtype, name, id, wtype, _, ltype = line:match(msg_patt)
    name = name:gsub('[GS]et%f[%u]', ''):gsub('([a-z])([A-Z])', '%1_%2')
               :gsub('([A-Z])([A-Z][a-z])', '%1_%2'):lower()
    if kind == 'get' and wtype == 'int' and ltype == 'int' or
       wtype == 'bool' and ltype ~= '' or changed_setter[name] then
      -- Special case getter/setter; handle as function.
      local fname = kind..'_'..name
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

-- Add mouse events from Scinterm manually.
constants[#constants + 1] = 'MOUSE_PRESS=1'
constants[#constants + 1] = 'MOUSE_DRAG=2'
constants[#constants + 1] = 'MOUSE_RELEASE=3'

table.sort(constants)
table.sort(functions)
table.sort(properties)

local f = io.open('../core/iface.lua', 'wb')
f:write([=[
-- Copyright 2007-2015 Mitchell mitchell.att.foicica.com. See LICENSE.

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
for i = 1, #functions do
  f:write(string_format('%s={%d,%d,%d,%d},', functions[i],
                        table_unpack(functions[functions[i]])))
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
for i = 1, #properties do
  f:write(string_format('%s={%d,%d,%d,%d},', properties[i],
                        table_unpack(properties[properties[i]])))
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

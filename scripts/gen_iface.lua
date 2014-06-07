#!/usr/bin/lua
-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

-- This script generates the _SCINTILLA table from SciTE's Lua Interface tables.

local f = io.open(arg[1] or '../../scite-latest/scite/src/IFaceTable.cxx', 'rb')
local iface = f:read('*all')
f:close()

local string_format = string.format
local constants, fielddoc, functions, properties = {}, {}, {}, {}
local types = {
  void = 0, int = 1, length = 2, position = 3, colour = 4, bool = 5,
  keymod = 6, string = 7, stringresult = 8, cells = 9, textrange = 10,
  findtext = 11, formatrange = 12
}
local s = '_G._SCINTILLA.constants'

f = io.open('../core/iface.lua', 'wb')

-- Write header.
f:write [=[
-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Scintilla constants, functions, and properties.
-- Do not modify anything in this module. Doing so will have unpredictable
-- consequences.
module('_SCINTILLA')]]

]=]

-- Constants to ignore.
local ignores = {
  '^IDM_', '^INDIC[012S]_', '^INVALID_POSITION', '^KEYWORDSET_MAX',
  '^SC_CACHE_', '^SC_CHARSET_', '^SC_EFF_', '^SC_FONT_SIZE_MULTIPLIER',
  '^SC_LINE_END_TYPE_', -- provisional
  '^SC_PRINT_', '^SC_STATUS_', '^SC_TECHNOLOGY_', '^SC_TYPE_', '^SC_WEIGHT_',
  '^SCE_', '^SCEN_', '^SCFIND_POSIX', '^SCI_', '^SCK_', '^SCLEX_',
  '^UNDO_MAY_COALESCE'
}
-- Constants ({"constant", value}).
for item in iface:match('Constants%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, value = item:match('^{"(.-)",(.-)}')
  local skip = false
  for i = 1, #ignores do if name:find(ignores[i]) then skip = true break end end
  if not skip then
    name = name:gsub('^SC_', ''):gsub('^SC([^N]%u+)', '%1')
    if name == 'FIND_REGEXP' then
      value = tostring(tonumber(value) + 2^22) -- add SCFIND_POSIX
    elseif name == 'MASK_FOLDERS' then
      value = '-33554432'
    end
    constants[#constants + 1] = string_format('%s=%s', name, value)
    fielddoc[#fielddoc + 1] = string_format('-- * `%s.%s` %d', s, name, value)
  end
end

-- Events added to constants.
local events = {
  SCN_STYLENEEDED = 2000,
  SCN_CHARADDED = 2001,
  SCN_SAVEPOINTREACHED = 2002,
  SCN_SAVEPOINTLEFT = 2003,
  SCN_MODIFYATTEMPTRO = 2004,
  SCN_KEY = 2005,
  SCN_DOUBLECLICK = 2006,
  SCN_UPDATEUI = 2007,
  SCN_MODIFIED = 2008,
  SCN_MACRORECORD = 2009,
  SCN_MARGINCLICK = 2010,
  SCN_NEEDSHOWN = 2011,
  SCN_PAINTED = 2013,
  SCN_USERLISTSELECTION = 2014,
  SCN_URIDROPPED = 2015,
  SCN_DWELLSTART = 2016,
  SCN_DWELLEND = 2017,
  SCN_ZOOM = 2018,
  SCN_HOTSPOTCLICK = 2019,
  SCN_HOTSPOTDOUBLECLICK = 2020,
  SCN_CALLTIPCLICK = 2021,
  SCN_AUTOCSELECTION = 2022,
  SCN_INDICATORCLICK = 2023,
  SCN_INDICATORRELEASE = 2024,
  SCN_AUTOCCANCELLED = 2025,
  SCN_AUTOCCHARDELETED = 2026,
  SCN_HOTSPOTRELEASECLICK = 2027,
  SCN_FOCUSIN = 2028,
  SCN_FOCUSOUT = 2029
}
for event, value in pairs(events) do
  constants[#constants + 1] = string_format('%s=%d', event, value)
end

-- Write constants.
f:write [[
---
-- Map of Scintilla constant names to their numeric values.
-- @class table
-- @name constants
-- @see _G.buffer
M.constants = {]]
f:write(table.concat(constants, ','))
f:write('}\n\n')

-- Functions ({"function", msg_id, iface_*, {iface_*, iface_*}}).
for item in iface:match('Functions%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, msg_id, rt_type, p1_type, p2_type =
    item:match('^{"(.-)"%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  if name == 'convert_eo_ls' then name = 'convert_eols' end
  local line = string_format('%s={%d,%d,%d,%d}', name, msg_id, types[rt_type],
                             types[p1_type], types[p2_type])
  functions[#functions + 1] = line
end

-- Write functions.
f:write [[
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
M.functions = {]]
f:write(table.concat(functions, ','))
f:write('}\n\n')

-- Properties ({"property", get_id, set_id, rt_type, p1_type}).
for item in iface:match('Properties%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, get_id, set_id, rt_type, p1_type =
    item:match('^{"(.-)"%D+(%d+)%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  properties[#properties + 1] = string_format('%s={%d,%d,%d,%d}', name, get_id,
                                              set_id, types[rt_type],
                                              types[p1_type])
end

-- Write properties.
f:write [[
---
-- Map of Scintilla property names to table values containing their "get"
-- function IDs, "set" function IDs, return types, and wParam types.
-- The wParam type will be non-zero if the property is indexable.
-- Types are the same as in the `functions` table.
-- @see functions
-- @class table
-- @name properties
M.properties = {]]
f:write(table.concat(properties, ','))
f:write('}\n\n')

-- Write footer.
f:write [[
local marker_number, indic_number, list_type = -1, -1, 0

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

return M
]]

f:close()

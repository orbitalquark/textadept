#!/usr/bin/lua
-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local f = io.open('../../scite-latest/scite/src/IFaceTable.cxx')
local contents = f:read('*all')
f:close()

local constants = contents:match('ifaceConstants%[%] = (%b{})')
local functions = contents:match('ifaceFunctions%[%] = (%b{})')
local properties = contents:match('ifaceProperties%[%] = (%b{})')

local out = [[
-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Scintilla constants, functions, and properties.
-- Do not modify anything in this module. Doing so will result in instability.
module('_SCINTILLA', package.seeall)

]]

local types = {
  void = 0, int = 1, length = 2, position = 3, colour = 4, bool = 5,
  keymod = 6, string = 7, stringresult = 8, cells = 9, textrange = 10,
  findtext = 11, formatrange = 12
}

out = out..[[
---
-- Scintilla constants.
-- @class table
-- @name constants
constants = {]]
-- {"constant", value}
for item in constants:sub(2, -2):gmatch('%b{}') do
  local name, value = item:match('^{"(.-)",(.-)}')
  if not name:find('^IDM_') and not name:find('^SCE_') and
     not name:find('^SCLEX_') then
    if name == 'SC_MASK_FOLDERS' then value = '-33554432' end
    local line = (" %s = %s,"):format(name, value)
    out = out..line
  end
end
out = out..string.gsub([[
SCLEX_CONTAINER = 0,
SCLEX_NULL = 1,
SCLEX_LPEG = 999,
SCLEX_AUTOMATIC = 1000,
SCN_STYLENEEDED = 2000,
SCN_CHARADDED = 2001,
SCN_SAVEPOINTREACHED = 2002,
SCN_SAVEPOINTLEFT = 2003,
SCN_MODIFYATTEMPTRO = 2004,
SCN_KEY = 2005,
SCN_DOUBLECLICK =2006,
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
SCN_INDICATORRELEASE = 2024,]], '\n', ' ')
out = out..' }\n\n'

out = out..[[
---
-- Scintilla functions.
-- @class table
-- @name functions
functions = {]]
-- {"function", msg_id, iface_*, {iface_*, iface_*}}
for item in functions:sub(2, -2):gmatch('%b{}') do
  local name, msg_id, rt_type, p1_type, p2_type =
    item:match('^{"(.-)"%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  local line = (" %s = {%d, %d, %d, %d},"):format(
    name, msg_id, types[rt_type], types[p1_type], types[p2_type])
  out = out..line
end
out = out..' }\n\n'

out = out..[[
---
-- Scintilla properties.
-- @class table
-- @name properties
properties = {]]
-- {"property", get_id, set_id, rt_type, p1_type}
for item in properties:sub(2, -2):gmatch('%b{}') do
  local name, get_id, set_id, rt_type, p1_type =
    item:match('^{"(.-)"%D+(%d+)%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  local line = (" %s = {%d, %d, %d, %d},"):format(
    name, get_id, set_id, types[rt_type], types[p1_type])
  out = out..line
end
out = out..' }\n'

f = io.open('../core/iface.lua', 'w')
f:write(out)
f:close()

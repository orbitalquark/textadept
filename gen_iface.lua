#!/usr/bin/lua
-- Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local f = io.open('/usr/share/scite-st/src/scite/src/IFaceTable.cxx')
local contents = f:read('*all')
f:close()

local constants = contents:match('ifaceConstants%[%] = (%b{})')
local functions = contents:match('ifaceFunctions%[%] = (%b{})')
local properties = contents:match('ifaceProperties%[%] = (%b{})')

local out = ''

local types = {
  void = 0, int = 1, length = 2, position = 3, colour = 4, bool = 5,
  keymod = 6, string = 7, stringresult = 8, cells = 9, textrange = 10,
  findtext = 11, formatrange = 12
}

out = out..'textadept.constants = {\n'
-- {"constant", value}
for item in constants:sub(2, -2):gmatch('%b{}') do
  local name, value = item:match('^{"(.-)",(.-)}')
  local line = ("  %s = %s,\n"):format(name, value)
  out = out..line
end
out = out..'}\n\n'

out = out..'textadept.buffer_functions = {\n'
-- {"function", msg_id, iface_*, {iface_*, iface_*}}
for item in functions:sub(2, -2):gmatch('%b{}') do
  local name, msg_id, rt_type, p1_type, p2_type =
    item:match('^{"(.-)"%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  local line = ("  %s = {%d, %d, %d, %d},\n"):format(
    name, msg_id, types[rt_type], types[p1_type], types[p2_type])
  out = out..line
end
out = out..'}\n\n'

out = out..'textadept.buffer_properties = {\n'
-- {"property", get_id, set_id, rt_type, p1_type}
for item in properties:sub(2, -2):gmatch('%b{}') do
  local name, get_id, set_id, rt_type, p1_type =
    item:match('^{"(.-)"%D+(%d+)%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  local line = ("  %s = {%d, %d, %d, %d},\n"):format(
    name, get_id, set_id, types[rt_type], types[p1_type])
  out = out..line
end
out = out..'}\n'

f = io.open('/usr/share/textadept/lib/iface.lua', 'w')
f:write(out)
f:close()

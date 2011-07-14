-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize

---
-- Defines additional key commands for Textadept.
-- The primary key commands are loaded from _USERHOME/keys.conf,
-- _HOME/modules/textadept/keys.conf, _USERHOME/keys.osx.conf, or
-- _HOME/modules/textadept/keys.osx.conf depending on the platform by
-- _m.textadept.menu.
-- This module, like _m.textadept.menu, should be 'require'ed last.
module('_m.textadept.keys', package.seeall)

local keys = keys

if OSX then
  -- See keys.osx.conf for unassigned keys.
  keys.mk = function()
    buffer:line_end_extend()
    buffer:cut()
  end
  local buffer = buffer
  keys.mf = buffer.char_right
  keys.mF = buffer.char_right_extend
  keys.amf = buffer.word_right
  keys.amF = buffer.word_right_extend
  keys.mb = buffer.char_left
  keys.mB = buffer.char_left_extend
  keys.amb = buffer.word_left
  keys.amB = buffer.word_left_extend
  keys.mn = buffer.line_down
  keys.mN = buffer.line_down_extend
  keys.mp = buffer.line_up
  keys.mP = buffer.line_up_extend
  keys.ma = buffer.vc_home
  keys.mA = buffer.vc_home_extend
  keys.me = buffer.line_end
  keys.mE = buffer.line_end_extend
  keys.md = buffer.clear
  keys.ml = buffer.vertical_centre_caret
end

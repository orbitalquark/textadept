-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local M = {}
_m.textadept = M

--[[ This comment is for LuaDoc.
---
-- The textadept module.
-- It provides utilities for editing text in Textadept.
module('_m.textadept', package.seeall)]]

M.adeptsense = require 'textadept.adeptsense'
M.bookmarks = require 'textadept.bookmarks'
require 'textadept.command_entry'
M.editing = require 'textadept.editing'
require 'textadept.find'
M.filter_through = require 'textadept.filter_through'
M.mime_types = require 'textadept.mime_types'
M.run = require 'textadept.run'
M.session = require 'textadept.session'
M.snapopen = require 'textadept.snapopen'
M.snippets = require 'textadept.snippets'

-- These need to be loaded last.
M.keys = require 'textadept.keys'
M.menu = require 'textadept.menu'

return M

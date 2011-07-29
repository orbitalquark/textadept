-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- The textadept module.
-- It provides utilities for editing text in Textadept.
module('_m.textadept', package.seeall)

require 'textadept.adeptsense'
require 'textadept.bookmarks'
require 'textadept.command_entry'
require 'textadept.editing'
require 'textadept.find'
require 'textadept.filter_through'
require 'textadept.mime_types'
require 'textadept.run'
require 'textadept.session'
require 'textadept.snapopen'
require 'textadept.snippets'

-- These need to be loaded last.
require 'textadept.keys'
require 'textadept.menu'

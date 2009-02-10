-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- This module contains all messages used by Textadept for localization.
-- Lua strings can contain UTF-8 characters. If you use the \ddd representation
-- though, it must be in DECIMAL format, not Octal as in some other programming
-- languages.
-- However, you must convert any UTF-16, UTF-32, etc. to UTF-8 manually as the
-- \U+xxxx format cannot be represented in Lua.
module('locale', package.seeall)

-- init.lua

-- core/events.lua

-- Untitled
UNTITLED = 'Untitled'
-- [Message Buffer]
MESSAGE_BUFFER = '[Message Buffer]'
-- OVR
STATUS_OVR = 'OVR'
-- INS
STATUS_INS = 'INS'
-- CRLF
STATUS_CRLF = 'CRLF'
-- CR
STATUS_CR = 'CR'
-- LF
STATUS_LF = 'LF'
-- "Tabs: "
STATUS_TABS = 'Tabs: '
-- "Spaces: "
STATUS_SPACES = 'Spaces: '
-- "Line: %d/%d    Col: %d    Lexer: %s    %s    %s    %s"
DOCSTATUSBAR_TEXT = "Line: %d/%d    Col: %d    Lexer: %s    %s    %s    %s"
-- Save?
EVENTS_QUIT_TITLE = 'Save?'
-- Save changes before quitting?
EVENTS_QUIT_TEXT = 'Save changes before quitting?'
-- The following buffers are unsaved:
--
-- %s
--
-- You will have to save changes manually
EVENTS_QUIT_MSG = [[
The following buffers are unsaved:

%s

You will have to save changes manually.
]]
-- [Error Buffer]
ERROR_BUFFER = '[Error Buffer]'

-- core/file_io.lua

-- Open
IO_OPEN_TITLE = 'Open'
-- Select a file(s) to open
IO_OPEN_TEXT = 'Select a file(s) to open'
-- Save
IO_SAVE_TITLE = 'Save'
-- Save?
IO_CLOSE_TITLE = 'Save?'
-- Save changes before closing?
IO_CLOSE_TEXT = 'Save changes before closing?'
-- You will have to save changes manually.
IO_CLOSE_MSG = 'You will have to save changes manually.'

-- core/iface.lua

-- core/init.lua

-- Buffer argument expected.
ERR_BUFFER_EXPECTED = 'Buffer argument expected.'
-- The indexed buffer is not the focused one.
ERR_BUFFER_NOT_FOCUSED = 'The indexed buffer is not the focused one.'

-- core/ext/command_entry.lua

-- core/ext/find.lua

-- Search wrapped
FIND_SEARCH_WRAPPED = 'Search wrapped'
-- No results found
FIND_NO_RESULTS = 'No results found'
-- Error
FIND_ERROR_DIALOG_TITLE = 'Error'
-- An error occured:
FIND_ERROR_DIALOG_TEXT = 'An error occured'
-- "%d replacement(s) made"
FIND_REPLACEMENTS_MADE = '%d replacement(s) made'
-- Find in Files
FIND_IN_FILES_TITLE = 'Find in Files'
-- Select Directory to Search
FIND_IN_FILES_TEXT = 'Select Directory to Search'
-- [Files Found Buffer]
FIND_FILES_FOUND_BUFFER = '[Files Found Buffer]'

-- core/ext/keys.lua

-- "Keychain: "
KEYCHAIN = 'Keychain: '
-- Invalid sequence
KEYS_INVALID = 'Invalid sequence'
-- "Unknown command: "
KEYS_UNKNOWN_COMMAND = 'Unknown command: '

-- core/ext/menu.lua

-- _File
MENU_FILE_TITLE = '_File'
-- gtk-new
MENU_FILE_NEW = 'gtk-new'
-- gtk-open
MENU_FILE_OPEN = 'gtk-open'
-- _Reload
MENU_FILE_RELOAD = '_Reload'
-- gtk-save
MENU_FILE_SAVE = 'gtk-save'
-- gtk-save-as
MENU_FILE_SAVEAS = 'gtk-save-as'
-- gtk-close
MENU_FILE_CLOSE = 'gtk-close'
-- Close A_ll
MENU_FILE_CLOSE_ALL = 'Close A_ll'
-- Loa_d Session...
MENU_FILE_LOAD_SESSION = 'Loa_d Session...'
-- Sa_ve Session...
MENU_FILE_SAVE_SESSION = 'Sa_ve Session...'
-- gtk-quit
MENU_FILE_QUIT = 'gtk-quit'
-- _Edit
MENU_EDIT_TITLE = '_Edit'
-- gtk-undo
MENU_EDIT_UNDO = 'gtk-undo'
-- gtk-redo
MENU_EDIT_REDO = 'gtk-redo'
-- gtk-cut
MENU_EDIT_CUT = 'gtk-cut'
-- gtk-copy
MENU_EDIT_COPY = 'gtk-copy'
-- gtk-paste
MENU_EDIT_PASTE = 'gtk-paste'
-- gtk-delete
MENU_EDIT_DELETE = 'gtk-delete'
-- gtk-select-all
MENU_EDIT_SELECT_ALL = 'gtk-select-all'
-- Match _Brace
MENU_EDIT_MATCH_BRACE = 'Match _Brace'
-- Select t_o Brace
MENU_EDIT_SELECT_TO_BRACE = 'Select t_o Brace'
-- Complete _Word
MENU_EDIT_COMPLETE_WORD = 'Complete _Word'
-- De_lete Word
MENU_EDIT_DELETE_WORD = 'De_lete Word'
-- Tran_spose Characters
MENU_EDIT_TRANSPOSE_CHARACTERS = 'Tran_spose Characters'
-- S_queeze
MENU_EDIT_SQUEEZE = 'S_queeze'
-- _Join Lines
MENU_EDIT_JOIN_LINES = '_Join Lines'
-- Convert _Indentation
MENU_EDIT_CONVERT_INDENTATION = 'Convert _Indentation'
-- _Kill Ring
MENU_EDIT_KR_TITLE = '_Kill Ring'
-- _Cut to Line End
MENU_EDIT_KR_CUT_TO_LINE_END = '_Cut to Line End'
-- C_opy to Line End
MENU_EDIT_KR_COPY_TO_LINE_END = 'C_opy to Line End'
-- _Paste From
MENU_EDIT_KR_PASTE_FROM = '_Paste From'
-- Paste _Next From
MENU_EDIT_KR_PASTE_NEXT_FROM = 'Paste _Next From'
-- Paste _Previous From
MENU_EDIT_KR_PASTE_PREV_FROM = 'Paste _Previous From'
-- S_election
MENU_EDIT_SEL_TITLE = 'S_election'
-- _Enclose in...
MENU_EDIT_SEL_ENC_TITLE = '_Enclose in...'
-- _HTML Tags
MENU_EDIT_SEL_ENC_HTML_TAGS = '_HTML Tags'
-- HTML Single _Tag
MENU_EDIT_SEL_ENC_HTML_SINGLE_TAG = 'HTML Single _Tag'
-- _Double Quotes
MENU_EDIT_SEL_ENC_DOUBLE_QUOTES = '_Double Quotes'
-- _Single Quotes
MENU_EDIT_SEL_ENC_SINGLE_QUOTES = '_Single Quotes'
-- _Parentheses
MENU_EDIT_SEL_ENC_PARENTHESES = '_Parentheses'
-- _Brackets
MENU_EDIT_SEL_ENC_BRACKETS = '_Brackets'
-- B_races
MENU_EDIT_SEL_ENC_BRACES = 'B_races'
-- _Character Sequence
MENU_EDIT_SEL_ENC_CHAR_SEQ = '_Character Sequence'
-- _Grow
MENU_EDIT_SEL_GROW = '_Grow'
-- Select i_n...
MENU_EDIT_SEL_IN_TITLE = 'Select i_n...'
-- S_tructure
MENU_EDIT_SEL_IN_STRUCTURE = 'S_tructure'
-- _HTML Tag
MENU_EDIT_SEL_IN_HTML_TAG = '_HTML Tag'
-- _Double Quote
MENU_EDIT_SEL_IN_DOUBLE_QUOTE = '_Double Quote'
-- _Single Quote
MENU_EDIT_SEL_IN_SINGLE_QUOTE = '_Single Quote'
-- _Parenthesis
MENU_EDIT_SEL_IN_PARENTHESIS = '_Parenthesis'
-- _Bracket
MENU_EDIT_SEL_IN_BRACKET = '_Bracket'
-- B_race
MENU_EDIT_SEL_IN_BRACE = 'B_race'
-- _Word
MENU_EDIT_SEL_IN_WORD = '_Word'
-- _Line
MENU_EDIT_SEL_IN_LINE = '_Line'
-- Para_graph
MENU_EDIT_SEL_IN_PARAGRAPH = 'Para_graph'
-- _Indented Block
MENU_EDIT_SEL_IN_INDENTED_BLOCK = '_Indented Block'
-- S_cope
MENU_EDIT_SEL_IN_SCOPE = 'S_cope'

-- _Search
MENU_SEARCH_TITLE = '_Search'
-- gtk-find
MENU_SEARCH_FIND = 'gtk-find'
-- Find _Next
MENU_SEARCH_FIND_NEXT = 'Find _Next'
-- Find _Previous
MENU_SEARCH_FIND_PREV = 'Find _Previous'
-- gtk-find-and-replace
MENU_SEARCH_FIND_AND_REPLACE = 'gtk-find-and-replace'
-- Replace
MENU_SEARCH_REPLACE = 'Replace'
-- Replace _All
MENU_SEARCH_REPLACE_ALL = 'Replace _All'
-- gtk-jump-to
MENU_SEARCH_GOTO_LINE = 'gtk-jump-to'

-- _Tools
MENU_TOOLS_TITLE = '_Tools'
-- Focus _Command Entry
MENU_TOOLS_FOCUS_COMMAND_ENTRY = 'Focus _Command Entry'
-- _Run
MENU_TOOLS_RUN = '_Run'
-- _Compile
MENU_TOOLS_COMPILE = '_Compile'
-- _Snippets
MENU_TOOLS_SNIPPETS_TITLE = '_Snippets'
-- _Insert Snippet
MENU_TOOLS_SNIPPETS_INSERT = '_Insert'
-- _Previous Placeholder
MENU_TOOLS_SNIPPETS_PREV_PLACE = '_Previous Placeholder'
-- _Cancel
MENU_TOOLS_SNIPPETS_CANCEL = '_Cancel'
-- _List
MENU_TOOLS_SNIPPETS_LIST = '_List'
-- _Show Scope
MENU_TOOLS_SNIPPETS_SHOW_SCOPE = '_Show Scope'
-- _Multiple Line Editing
MENU_TOOLS_ML_TITLE = '_Multiple Line Editing'
-- _Add Line
MENU_TOOLS_ML_ADD = '_Add Line'
-- Add _Multiple Lines
MENU_TOOLS_ML_ADD_MULTIPLE = 'Add _Multiple Lines'
-- _Remove Line
MENU_TOOLS_ML_REMOVE = '_Remove Line'
-- R_emove Multiple Lines
MENU_TOOLS_ML_REMOVE_MULTIPLE = 'R_emove Multiple Lines'
-- _Update Multiple Lines
MENU_TOOLS_ML_UPDATE = '_Update Multiple Lines'
-- _Finish Editing
MENU_TOOLS_ML_FINISH = '_Finish Editing'
-- _Bookmark
MENU_TOOLS_BM_TITLE = '_Bookmark'
-- _Toggle on Current Line
MENU_TOOLS_BM_TOGGLE = '_Toggle on Current Line'
-- _Clear All
MENU_TOOLS_BM_CLEAR_ALL = '_Clear All'
-- _Next
MENU_TOOLS_BM_NEXT = '_Next'
-- _Previous
MENU_TOOLS_BM_PREV = '_Previous'
-- M_acros
MENU_TOOLS_MACROS_TITLE = 'M_acros'
-- _Start Recording
MENU_TOOLS_MACROS_START = '_Start Recording'
-- S_top Recording
MENU_TOOLS_MACROS_STOP = 'S_top Recording'
-- _Play Macro
MENU_TOOLS_MACROS_PLAY = '_Play Macro'

-- _Buffers
MENU_BUF_TITLE = '_Buffers'
-- _Next Buffer
MENU_BUF_NEXT = '_Next Buffer'
-- _Prev Buffer
MENU_BUF_PREV = '_Prev Buffer'
-- Toggle View _EOL
MENU_BUF_TOGGLE_VIEW_EOL = 'Toggle View _EOL'
-- Toggle _Wrap Mode
MENU_BUF_TOGGLE_WRAP = 'Toggle _Wrap Mode'
-- Toggle Show _Indentation Guides
MENU_BUF_TOGGLE_INDENT_GUIDES = 'Toggle Show _Indentation Guides'
-- Toggle Use _Tabs
MENU_BUF_TOGGLE_TABS = 'Toggle Use _Tabs'
-- Toggle View White_space
MENU_BUF_TOGGLE_VIEW_WHITESPACE = 'Toggle View White_space'
-- EOL Mode
MENU_BUF_EOL_MODE_TITLE = 'EOL Mode'
-- CR+LF
MENU_BUF_EOL_MODE_CRLF = 'CR+LF'
-- CR
MENU_BUF_EOL_MODE_CR = 'CR'
-- LF
MENU_BUF_EOL_MODE_LF = 'LF'
-- _Refresh Syntax Highlighting
MENU_BUF_REFRESH = '_Refresh Syntax Highlighting'

-- _Views
MENU_VIEW_TITLE = '_Views'
-- _Next View
MENU_VIEW_NEXT = '_Next View'
-- _Prev View
MENU_VIEW_PREV = '_Prev View'
-- Split _Vertical
MENU_VIEW_SPLIT_VERTICAL = 'Split _Vertical'
-- Split _Horizontal
MENU_VIEW_SPLIT_HORIZONTAL = 'Split _Horizontal'
-- _Unsplit
MENU_VIEW_UNSPLIT = '_Unsplit'
-- Unsplit _All
MENU_VIEW_UNSPLIT_ALL = 'Unsplit _All'
-- _Grow
MENU_VIEW_GROW = '_Grow'
-- _Shrink
MENU_VIEW_SHRINK = '_Shrink'

-- _Lexers
MENU_LEX_TITLE = '_Lexers'

-- "Unknown command: "
MENU_UNKNOWN_COMMAND = 'Unknown command: '

-- core/ext/mime_types.lua

-- core/ext/pm.lua

-- core/ext/pm/buffer_browser.lua

-- gtk-new
PM_BROWSER_BUFFER_NEW = 'gtk-new'
-- gtk-open
PM_BROWSER_BUFFER_OPEN = 'gtk-open'
-- gtk-save
PM_BROWSER_BUFFER_SAVE = 'gtk-save'
-- gtk-save-as
PM_BROWSER_BUFFER_SAVEAS = 'gtk-save-as'
-- gtk-close
PM_BROWSER_BUFFER_CLOSE = 'gtk-close'

-- core/ext/pm/ctags.lua

-- 'Extension "%s" not recognized'
PM_BROWSER_CTAGS_BAD_EXT = 'Extension "%s" not recognized.'
-- "Unmatched ctag: %s"
PM_BROWSER_CTAGS_UNMATCHED = 'Unmatched ctag: %s'
-- '"%s" not found.'
PM_BROWSER_CTAGS_NOT_FOUND = '"%s" not found.'

-- core/ext/pm/file_browser.lua

-- _Change Directory
PM_BROWSER_FILE_CD = '_Change Directory'
-- File _Info
PM_BROWSER_FILE_INFO = 'File _Info'
-- Mode:	%s
-- Size:	%s
-- UID:	%s
-- GID:	%s
-- Device:	%s
-- Accessed:	%s
-- Modified:	%s
-- Changed:	%s
PM_BROWSER_FILE_DATA = [[
Mode:	%s
Size:	%s
UID:	%s
GID:	%s
Device:	%s
Accessed:	%s
Modified:	%s
Changed:	%s
]]
-- 'File info for "%s"'
PM_BROWSER_FILE_INFO_TEXT = 'File info for "%s"'
-- OK
PM_BROWSER_FILE_INFO_OK = 'OK'

-- core/ext/pm/macro_browser.lua

-- _Delete
PM_BROWSER_MACRO_DELETE = '_Delete'

-- core/ext/pm/modules_browser.lua

-- _New Module
PM_BROWSER_MODULE_NEW = '_New Module'
-- _Delete Module
PM_BROWSER_MODULE_DELETE = '_Delete Module'
-- Configure _MIME Types
PM_BROWSER_MODULE_CONF_MIME_TYPES = 'Configure _MIME Types'
-- Configure _Key Commands
PM_BROWSER_MODULE_CONF_KEY_COMMANDS = 'Configure _Key Commands'
-- _Reload Modules
PM_BROWSER_MODULE_RELOAD = '_Reload Modules'
-- Module Name
PM_BROWSER_MODULE_NEW_TITLE = 'Module Name'
-- Module name:
PM_BROWSER_MODULE_NEW_INFO_TEXT = 'Module name:'
-- Language Name
PM_BROWSER_MODULE_NEW_LANG_TITLE = 'Language Name'
-- Language name:
PM_BROWSER_MODULE_NEW_LANG_INFO_TEXT = 'Language name:'
-- Error
PM_BROWSER_MODULE_NEW_ERROR = 'Error'
-- A module by that name already exists or you
-- do not have permission to create the module.
PM_BROWSER_MODULE_NEW_ERROR_TEXT = [[
A module by that name already exists or you
do not have permission to create the module.
]]
-- Delete Module?
PM_BROWSER_MODULE_DELETE_TITLE = 'Delete Module?'
-- Are you sure you want to permanently delete
-- the "%s" module?
PM_BROWSER_MODULE_DELETE_TEXT = [[
Are you sure you want to permanently delete
the "%s" module?
]]

-- core/ext/pm/project_browser.lua

-- _New Project
PM_BROWSER_PROJECT_NEW = '_New Project'
-- _Open Project
PM_BROWSER_PROJECT_OPEN = '_Open Project'
-- _Close Project
PM_BROWSER_PROJECT_CLOSE = '_Close Project'
-- Add New File
PM_BROWSER_PROJECT_NEW_FILE = 'Add New File'
-- Add Existing Files
PM_BROWSER_PROJECT_ADD_FILES = 'Add Existing Files'
-- Add New Directory
PM_BROWSER_PROJECT_NEW_DIR = 'Add New Directory'
-- Add Existing Directory
PM_BROWSER_PROJECT_ADD_DIR = 'Add Existing Directory'
-- _Delete
PM_BROWSER_PROJECT_DELETE_FILE = '_Delete'
-- _Rename
PM_BROWSER_PROJECT_RENAME_FILE = '_Rename'
-- Save Project
PM_BROWSER_PROJECT_NEW_TITLE = 'Save Project'
-- Open Project
PM_BROWSER_PROJECT_OPEN_TITLE = 'Open Project'
-- Save File
PM_BROWSER_PROJECT_NEW_FILE_TITLE = 'Save File'
-- Add to Project Root Instead?
PM_BROWSER_PROJECT_NEW_FILE_LIVE_FOLDER_TITLE = 'Add to Project Root Instead?'
-- You are adding a new file to a live folder
-- which may not show up if the filepaths do
-- not match.
-- Add the file to the project root instead?
PM_BROWSER_PROJECT_NEW_FILE_LIVE_FOLDER_TEXT = [[
You are adding a new file to a live folder
which may not show up if the filepaths do
not match.
Add the file to the project root instead?
]]
-- Select Files
PM_BROWSER_PROJECT_ADD_FILES_TITLE = 'Select Files'
-- Select files to add to the project
PM_BROWSER_PROJECT_ADD_FILES_TEXT = 'Select files to add to the project'
-- Add to Project Root Instead?
PM_BROWSER_PROJECT_ADD_FILES_LIVE_FOLDER_TITLE = 'Add to Project Root Instead?'
-- You are adding existing files to a live
-- folder which is not possible.
-- Add them to the project root instead?
PM_BROWSER_PROJECT_ADD_FILES_LIVE_FOLDER_TEXT = [[
You are adding existing files to a live
folder which is not possible.
Add them to the project root instead?
]]
-- Directory Name?
PM_BROWSER_PROJECT_NEW_DIR_TITLE = 'Directory Name?'
-- Select Directory
PM_BROWSER_PROJECT_ADD_DIR_TITLE = 'Select Directory'
-- Select a directory to add to the project
PM_BROWSER_PROJECT_ADD_DIR_TEXT = 'Select a directory to add to the project'
-- Add to Project Root Instead?
PM_BROWSER_PROJECT_ADD_DIR_LIVE_FOLDER_TITLE = 'Add to Project Root Instead?'
-- You are adding an existing directory to
-- a live folder which is not possible.
-- Add it to the project root instead?
PM_BROWSER_PROJECT_ADD_DIR_LIVE_FOLDER_TEXT = [[
You are adding an existing directory to
a live folder which is not possible.
Add it to the project root instead?
]]
-- Keep on Disk?
PM_BROWSER_PROJECT_DELETE_FILE_TITLE = 'Keep on Disk?'
-- This file will be removed from the project.
-- Leave it on your computer? If not, it will
-- be permanently deleted.
PM_BROWSER_PROJECT_DELETE_FILE_TEXT = [[
This file will be removed from the project.
Leave it on your computer? If not, it will
be permanently deleted.
]]
-- Keep on Disk
PM_BROWSER_PROJECT_DELETE_DIR_TITLE = 'Keep on Disk?'
-- This directory will be removed from the
-- project. Leave it on your computer? If
-- not, it will be permanently deleted.
PM_BROWSER_PROJECT_DELETE_DIR_TEXT = [[
This directory will be removed from the
project. Leave it on your computer? If
not, it will be permanently deleted.
]]
-- Delete Permanently?
PM_BROWSER_PROJECT_DELETE_LIVE_FILE_TITLE = 'Delete Permanently?'
-- You have selected a file from a live folder
-- to delete. It will be deleted PERMANENTLY.
-- Continue?
-- (To delete a live folder from the project,
-- select the highest level live folder.)
PM_BROWSER_PROJECT_DELETE_LIVE_FILE_TEXT = [[
You have selected a file from a live folder
to delete. It will be deleted PERMANENTLY.
Continue?
(To delete a live folder from the project,
select the highest level live folder.)
]]
-- No
PM_BROWSER_PROJECT_DELETE_LIVE_FILE_BUTTON1 = 'No'
-- Yes
PM_BROWSER_PROJECT_DELETE_LIVE_FILE_BUTTON2 = 'Yes'
-- Cancel
PM_BROWSER_PROJECT_DELETE_LIVE_FILE_BUTTON3 = 'Cancel'
-- New Name?
PM_BROWSER_PROJECT_RENAME_FILE_TEXT = 'New Name?'

-- modules/textadept/bookmarks.lua

-- modules/textadept/editing.lua

-- Go To
M_TEXTADEPT_EDITING_GOTO_TITLE = 'Go To'
-- Line Number:
M_TEXTADEPT_EDITING_GOTO_TEXT = 'Line Number:'

-- modules/textadept/init.lua

-- modules/textadept/macros.lua

-- Macro recording
M_TEXTADEPT_MACRO_RECORDING = 'Macro recording'
-- Macro name?
M_TEXTADEPT_MACRO_SAVE_TITLE = 'Macro name?'
-- Macro name
M_TEXTADEPT_MACRO_SAVE_TEXT = 'Macro name'
-- Macro saved
M_TEXTADEPT_MACRO_SAVED = 'Macro saved'
-- Macro not saved
M_TEXTADEPT_MACRO_NOT_SAVED = 'Macro not saved'
-- Select a Macro
M_TEXTADEPT_MACRO_SELECT_TITLE = 'Select a Macro'
-- Macro name:
M_TEXTADEPT_MACRO_SELECT_TEXT = 'Macro name:'

-- modules/textadept/mlines.lua

-- modules/textadept/run.lua
-- The file "%s" does not exist.
M_TEXTADEPT_RUN_FILE_DOES_NOT_EXIST = 'The file "%s" does not exist.'

-- modules/textadept/snippets.lua

-- Lexer %s
-- Style %s (%d)
M_TEXTADEPT_SNIPPETS_SHOW_STYLE = [[
Lexer: %s
Style: %s (%d)]]

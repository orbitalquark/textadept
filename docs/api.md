## Textadept 11.4 beta API Documentation

1. [_G](#_G)
1. [_L](#_L)
1. [_M](#_M)
1. [_M.ansi_c](#_M.ansi_c)
1. [_M.lua](#_M.lua)
1. [_SCINTILLA](#_SCINTILLA)
1. [args](#args)
1. [assert](#assert)
1. [buffer](#buffer)
1. [events](#events)
1. [io](#io)
1. [keys](#keys)
1. [lexer](#lexer)
1. [lfs](#lfs)
1. [os](#os)
1. [string](#string)
1. [textadept](#textadept)
1. [textadept.bookmarks](#textadept.bookmarks)
1. [textadept.editing](#textadept.editing)
1. [textadept.file_types](#textadept.file_types)
1. [textadept.history](#textadept.history)
1. [textadept.keys](#textadept.keys)
1. [textadept.macros](#textadept.macros)
1. [textadept.menu](#textadept.menu)
1. [textadept.run](#textadept.run)
1. [textadept.session](#textadept.session)
1. [textadept.snippets](#textadept.snippets)
1. [ui](#ui)
1. [ui.command_entry](#ui.command_entry)
1. [ui.dialogs](#ui.dialogs)
1. [ui.find](#ui.find)
1. [view](#view)

<a id="_G"></a>
## The `_G` Module
---

Extends Lua's _G table to provide extra functions and fields for Textadept.

### Fields defined by `_G`

<a id="BSD"></a>
#### `BSD` (bool)

Whether or not Textadept is running on BSD.

<a id="CURSES"></a>
#### `CURSES` (bool)

Whether or not Textadept is running in a terminal.
  Curses feature incompatibilities are listed in the [Appendix][].

  [Appendix]: manual.html#terminal-version-compatibility

<a id="LINUX"></a>
#### `LINUX` (bool)

Whether or not Textadept is running on Linux.

<a id="OSX"></a>
#### `OSX` (bool)

Whether or not Textadept is running on macOS as a GUI application.

<a id="WIN32"></a>
#### `WIN32` (bool)

Whether or not Textadept is running on Windows.

<a id="_CHARSET"></a>
#### `_CHARSET` (string)

The filesystem's character encoding.
  This is used when [working with files](#io).

<a id="_HOME"></a>
#### `_HOME` (string)

The path to Textadept's home, or installation, directory.

<a id="_RELEASE"></a>
#### `_RELEASE` (string)

The Textadept release version string.

<a id="_USERHOME"></a>
#### `_USERHOME` (string)

The path to the user's *~/.textadept/* directory, where all preferences and user-data
  is stored.
  On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
  *C:\Users\username\\* or *C:\Documents and Settings\username\\*). On Linux, BSD, and macOS
  machines *~/* is the value of "$HOME" (typically */home/username/* and */Users/username/*
  respectively).


### Functions defined by `_G`

<a id="move_buffer"></a>
#### `move_buffer`(*from, to*)

Moves the buffer at index *from* to index *to* in the `_BUFFERS` table, shifting other buffers
as necessary.
This changes the order buffers are displayed in in the tab bar and buffer browser.

Parameters:

* *`from`*: Index of the buffer to move.
* *`to`*: Index to move the buffer to.

See also:

* [`_BUFFERS`](#_BUFFERS)

<a id="quit"></a>
#### `quit`()

Emits a `QUIT` event, and unless any handler returns `false`, quits Textadept.

See also:

* [`events.QUIT`](#events.QUIT)

<a id="reset"></a>
#### `reset`()

Resets the Lua State by reloading all initialization scripts.
Language modules for opened files are NOT reloaded. Re-opening the files that use them will
reload those modules instead.
This function is useful for modifying user scripts (such as *~/.textadept/init.lua* and
*~/.textadept/modules/textadept/keys.lua*) on the fly without having to restart Textadept. `arg`
is set to `nil` when reinitializing the Lua State. Any scripts that need to differentiate
between startup and reset can test `arg`.

<a id="timeout"></a>
#### `timeout`(*interval, f, ...*)

Calls function *f* with the given arguments after *interval* seconds.
If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long as *f* returns
`true`. A `nil` or `false` return value stops repetition.

Parameters:

* *`interval`*: The interval in seconds to call *f* after.
* *`f`*: The function to call.
* *`...`*: Additional arguments to pass to *f*.


### Tables defined by `_G`

<a id="_BUFFERS"></a>
#### `_BUFFERS`

Table of all open buffers in Textadept.
Numeric keys have buffer values and buffer keys have their associated numeric keys.

Usage:

* `_BUFFERS[n]      --> buffer at index n`
* `_BUFFERS[buffer] --> index of buffer in _BUFFERS`

See also:

* [`_G.buffer`](#_G.buffer)

<a id="_VIEWS"></a>
#### `_VIEWS`

Table of all views in Textadept.
Numeric keys have view values and view keys have their associated numeric keys.

Usage:

* `_VIEWS[n]    --> view at index n`
* `_VIEWS[view] --> index of view in _VIEWS`

See also:

* [`_G.view`](#_G.view)

<a id="arg"></a>
#### `arg`

Table of command line parameters passed to Textadept.

See also:

* [`args`](#args)

<a id="_G.buffer"></a>
#### `_G.buffer`

The current [buffer](#buffer) in the [current view](#_G.view).

<a id="_G.view"></a>
#### `_G.view`

The current [view](#view).

---
<a id="_L"></a>
## The `_L` Module
---

Map of all messages used by Textadept to their localized form.
If the table does not contain the localized version of a given message, it returns a string
that starts with "No Localization:" via a metamethod.
Note: the terminal version ignores any "_" mnemonics the GUI version would use.

---
<a id="_M"></a>
## The `_M` Module
---

A table of loaded Textadept language modules.

Language modules are a special kind of module that Textadept automatically loads when editing
source code in a particular programming language. The only thing "special" about them is they
are named after a lexer. Otherwise they are plain Lua modules. The *~/.textadept/modules/*
directory houses language modules (along with other modules).

A language module is designed to provide extra functionality for a single programming
language. Some examples of what language modules can do:

  * Specify block comment syntax for lines of code
  * Define compile and run commands for source files
  * Set language-specific editor properties like indentation rules
  * Specify code autocompletion routines
  * Declare snippets
  * Define commands and key bindings for them
  * Add to the top-level menu or right-click editor context menu

Examples of these features are described in the sections below.

### Block Comment

Many languages have different syntaxes for single line comments and multi-line comments in
source code. Textadept's block comment feature only uses one of those syntaxes for a given
language. If you prefer the other syntax, or if Textadept does not support block comments
for a particular language, modify the [`textadept.editing.comment_string`](#textadept.editing.comment_string) table. For example:

    textadept.editing.comment_string.ansi_c = '//' -- change from /* ... */

### Compile and Run

Textadept knows most of the commands that compile and/or run code in source files. However,
it does not know all of them, and the ones that it does know may not be completely accurate
in all cases. Compile and run commands are read from the [`textadept.run.compile_commands`](#textadept.run.compile_commands)
and [`textadept.run.run_commands`](#textadept.run.run_commands) tables using the appropriate lexer name key, and thus
can be defined or modified. For Lua, it would look like:

    textadept.run.compile_commands.lua = 'luac "%f"'
    textadept.run.run_commands.lua = 'lua "%f"'

Double-clicking on compile or runtime errors jumps to the error's location. If
Textadept does not recognize your language's errors properly, add an error pattern to
[`textadept.run.error_patterns`](#textadept.run.error_patterns). The Lua error pattern looks like:

    local patterns = textadept.run.error_patterns
    if not patterns.lua then patterns.lua = {} end
    patterns.lua[#patterns.lua + 1] = '^luac?: (.-):(%d+): (.+)$'

### Buffer Properties

By default, Textadept uses 2 spaces for indentation. Some languages have different indentation
guidelines, however. As described in the manual, use `events.LEXER_LOADED` to change this
and any other language-specific editor properties. For example:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= 'python' then return end
      buffer.tab_width = 4
      buffer.use_tabs = false
      view.view_ws = view.WS_VISIBLEALWAYS
    end)

### Autocompletion and Documentation

Textadept has the capability to autocomplete symbols for programming
languages and display API documentation. In order for these to work for a
given language, an [autocompleter](#textadept.editing.autocompleters) and [API
file(s)](#textadept.editing.api_files) must exist. All of Textadept's included language
modules have examples of autocompleters and API documentation, as well as most of its
officially supported language modules.

### Snippets

[Snippets](#textadept.snippets) for common language constructs are useful. Some snippets
for common Lua control structures look like this:

    snippets.lua = {
      f = "function %1(name)(%2(args))\n\t%0\nend",
      ['for'] = "for i = %1(1), %2(10)%3(, -1) do\n\t%0\nend",
      fori = "for %1(i), %2(val) in ipairs(%3(table)) do\n\t%0\nend",
      forp = "for %1(k), %2(v) in pairs(%3(table)) do\n\t%0\nend",
    }

### Commands

Additional editing features for the language can be useful. For example, a C++ module might
have a feature to add a ';' to the end of the current line and insert a new line. This command
could be bound to the `Shift+Enter` (`⇧↩` on macOS | `S-Enter` in the terminal version)
key for easy access:

    keys.cpp['shift+\n'] = function()
      buffer:line_end()
      buffer:add_text(';')
      buffer:new_line()
    end

When defining key bindings for other commands, you may make use of a `Ctrl+L` (`⌘L` on
macOS | `M-L` in the terminal version) keychain. Traditionally this prefix has been reserved
for use by language modules (although neither Textadept nor its modules utilize it at the
moment). Users may define this keychain for new or existing modules and it will not conflict
with any default key bindings. For example:

    keys.lua[CURSES and 'meta+l' or OSX and 'cmd+l' or 'ctrl+l'] = {
      ...
    }

### Menus

It may be useful to add language-specific menu options to the top-level menu and/or right-click
context menu in order to access module features without using key bindings. For example:

    local lua_menu = {
      title = 'Lua',
      {'Item 1', function() ... end},
      {'Item 2', function() ... end}
    }
    local tools = textadept.menu.menubar[_L['Tools']]
    tools[#tools + 1] = lua_menu
    textadept.menu.context_menu[#textadept.menu.context_menu + 1] = lua_menu

---
<a id="_M.ansi_c"></a>
## The `_M.ansi_c` Module
---

The ansi_c module.
It provides utilities for editing C code.

### Fields defined by `_M.ansi_c`

<a id="_M.ansi_c.autocomplete_snippets"></a>
#### `_M.ansi_c.autocomplete_snippets` (boolean)

Whether or not to include snippets in autocompletion lists.
  The default value is `true`.


### Tables defined by `_M.ansi_c`

<a id="_M.ansi_c.tags"></a>
#### `_M.ansi_c.tags`

List of ctags files to use for autocompletion in addition to the current project's top-level
*tags* file or the current directory's *tags* file.

---
<a id="_M.lua"></a>
## The `_M.lua` Module
---

The lua module.
It provides utilities for editing Lua code.

### Fields defined by `_M.lua`

<a id="_M.lua.autocomplete_snippets"></a>
#### `_M.lua.autocomplete_snippets` (boolean)

Whether or not to include snippets in autocompletion lists.
  The default value is `false`.


### Tables defined by `_M.lua`

<a id="_M.lua.expr_types"></a>
#### `_M.lua.expr_types`

Map of expression patterns to their types.
Used for type-hinting when showing autocompletions for variables. Expressions are expected
to match after the '=' sign of a statement.

Usage:

* `_M.lua.expr_types['^spawn%b()%s*$'] = 'proc'`

<a id="_M.lua.tags"></a>
#### `_M.lua.tags`

List of "fake" ctags files (or functions that return such files) to use for autocompletion.
The kind 'm' is recognized as a module, 'f' as a function, 't' as a table and 'F' as a module
or table field.
The *modules/lua/tadoc.lua* script can generate *tags* and [*api*](#textadept.editing.api_files)
files for Lua modules via LuaDoc.

---
<a id="_SCINTILLA"></a>
## The `_SCINTILLA` Module
---

Scintilla constants, functions, and properties.
Do not modify anything in this module. Doing so will have unpredictable consequences.

### Functions defined by `_SCINTILLA`

<a id="_SCINTILLA.next_image_type"></a>
#### `_SCINTILLA.next_image_type`()

Returns a unique image type identier number for use with `view.register_image()` and
`view.register_rgba_image()`.
Use this function for custom image types in order to prevent clashes with identifiers of
other custom image types.

Usage:

* `local image_type = _SCINTILLA.next_image_type()`

See also:

* [`view.register_image`](#view.register_image)
* [`view.register_rgba_image`](#view.register_rgba_image)

<a id="_SCINTILLA.next_indic_number"></a>
#### `_SCINTILLA.next_indic_number`()

Returns a unique indicator number for use with custom indicators.
Use this function for custom indicators in order to prevent clashes with identifiers of
other custom indicators.

Usage:

* `local indic_num = _SCINTILLA.next_indic_number()`

See also:

* [`view.indic_style`](#view.indic_style)

<a id="_SCINTILLA.next_marker_number"></a>
#### `_SCINTILLA.next_marker_number`()

Returns a unique marker number for use with `view.marker_define()`.
Use this function for custom markers in order to prevent clashes with identifiers of other
custom markers.

Usage:

* `local marknum = _SCINTILLA.next_marker_number()`

See also:

* [`view.marker_define`](#view.marker_define)

<a id="_SCINTILLA.next_user_list_type"></a>
#### `_SCINTILLA.next_user_list_type`()

Returns a unique user list identier number for use with `buffer.user_list_show()`.
Use this function for custom user lists in order to prevent clashes with list identifiers
of other custom user lists.

Usage:

* `local list_type = _SCINTILLA.next_user_list_type()`

See also:

* [`buffer.user_list_show`](#buffer.user_list_show)


### Tables defined by `_SCINTILLA`

<a id="_SCINTILLA.constants"></a>
#### `_SCINTILLA.constants`

Map of Scintilla constant names to their numeric values.

See also:

* [`buffer`](#buffer)

<a id="_SCINTILLA.events"></a>
#### `_SCINTILLA.events`

Map of Scintilla event IDs to tables of event names and event parameters.

<a id="_SCINTILLA.functions"></a>
#### `_SCINTILLA.functions`

Map of Scintilla function names to tables containing their IDs, return types, wParam types,
and lParam types. Types are as follows:

  + `0`: Void.
  + `1`: Integer.
  + `2`: Length of the given lParam string.
  + `3`: Integer position.
  + `4`: Color, in "0xBBGGRR" format or "0xAABBGGRR" format where supported.
  + `5`: Boolean `true` or `false`.
  + `6`: Bitmask of Scintilla key modifiers and a key value.
  + `7`: String parameter.
  + `8`: String return value.

<a id="_SCINTILLA.properties"></a>
#### `_SCINTILLA.properties`

Map of Scintilla property names to table values containing their "get" function IDs, "set"
function IDs, return types, and wParam types.
The wParam type will be non-zero if the property is indexable.
Types are the same as in the `functions` table.

See also:

* [`_SCINTILLA.functions`](#_SCINTILLA.functions)

---
<a id="args"></a>
## The `args` Module
---

Processes command line arguments for Textadept.

### Fields defined by `args`

<a id="events.ARG_NONE"></a>
#### `events.ARG_NONE` (string)

Emitted when no command line arguments are passed to Textadept on startup.


### Functions defined by `args`

<a id="args.register"></a>
#### `args.register`(*short, long, narg, f, description*)

Registers a command line option with short and long versions *short* and *long*, respectively.
*narg* is the number of arguments the option accepts, *f* is the function called when the
option is set, and *description* is the option's description when displaying help.

Parameters:

* *`short`*: The string short version of the option.
* *`long`*: The string long version of the option.
* *`narg`*: The number of expected parameters for the option.
* *`f`*: The Lua function to run when the option is set. It is passed *narg* string arguments.
* *`description`*: The string description of the option for command line help.


---
<a id="assert"></a>
## The `assert` Module
---

Extends `_G` with formatted assertions and function argument type checks.

### Functions defined by `assert`

<a id="_G.assert"></a>
#### `_G.assert`(*v, message, ...*)

Asserts that value *v* is not `false` or `nil` and returns *v*, or calls `error()` with
*message* as the error message, defaulting to "assertion failed!".
If *message* is a format string, the remaining arguments are passed to `string.format()`
and the resulting string becomes the error message.

Parameters:

* *`v`*: Value to assert.
* *`message`*: Optional error message to show on error. The default value is "assertion failed!".
* *`...`*: If *message* is a format string, these arguments are passed to `string.format()`.

<a id="_G.assert_type"></a>
#### `_G.assert_type`(*v, expected\_type, narg*)

Asserts that value *v* has type string *expected_type* and returns *v*, or calls `error()`
with an error message that implicates function argument number *narg*.
This is intended to be used with API function arguments so users receive more helpful error
messages.

Parameters:

* *`v`*: Value to assert the type of.
* *`expected_type`*: String type to assert. It may be a non-letter-delimited list of type
  options.
* *`narg`*: The positional argument number *v* is associated with. This is not required to
  be a number.

Usage:

* `assert_type(filename, 'string/nil', 1)`
* `assert_type(option.setting, 'number', 'setting') -- implicates key`


---
<a id="buffer"></a>
## The `buffer` Module
---

A Textadept buffer object.
Constants are documented in the fields they apply to.
While you can work with individual buffer instances, it is really only useful to work with
the global one.
Many of these functions and fields are derived from buffer-specific functionality of the
Scintilla editing component, and additional information can be found on the [Scintilla
website](https://scintilla.org/ScintillaDoc.html). Note that with regard to Scintilla-specific
functionality, this API is a _suggestion_, not a hard requirement. All of that functionality
also exists in [`view`](#view), even if undocumented.
Any buffer fields set on startup (e.g. in *~/.textadept/init.lua*) will be the default,
initial values for all buffers.

### Fields defined by `buffer`

<a id="buffer.CARETSTICKY_OFF"></a>
#### `buffer.CARETSTICKY_OFF` (number, Read-only)




<a id="buffer.CARETSTICKY_ON"></a>
#### `buffer.CARETSTICKY_ON` (number, Read-only)




<a id="buffer.CARETSTICKY_WHITESPACE"></a>
#### `buffer.CARETSTICKY_WHITESPACE` (number, Read-only)




<a id="buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE"></a>
#### `buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE` (number, Read-only)




<a id="buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE"></a>
#### `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE` (number, Read-only)




<a id="buffer.EOL_CR"></a>
#### `buffer.EOL_CR` (number, Read-only)




<a id="buffer.EOL_CRLF"></a>
#### `buffer.EOL_CRLF` (number, Read-only)




<a id="buffer.EOL_LF"></a>
#### `buffer.EOL_LF` (number, Read-only)




<a id="buffer.FIND_MATCHCASE"></a>
#### `buffer.FIND_MATCHCASE` (number, Read-only)




<a id="buffer.FIND_REGEXP"></a>
#### `buffer.FIND_REGEXP` (number, Read-only)




<a id="buffer.FIND_WHOLEWORD"></a>
#### `buffer.FIND_WHOLEWORD` (number, Read-only)




<a id="buffer.FIND_WORDSTART"></a>
#### `buffer.FIND_WORDSTART` (number, Read-only)




<a id="buffer.FOLDLEVELBASE"></a>
#### `buffer.FOLDLEVELBASE` (number, Read-only)




<a id="buffer.FOLDLEVELHEADERFLAG"></a>
#### `buffer.FOLDLEVELHEADERFLAG` (number, Read-only)




<a id="buffer.FOLDLEVELNUMBERMASK"></a>
#### `buffer.FOLDLEVELNUMBERMASK` (number, Read-only)




<a id="buffer.FOLDLEVELWHITEFLAG"></a>
#### `buffer.FOLDLEVELWHITEFLAG` (number, Read-only)




<a id="buffer.INDICATOR_MAX"></a>
#### `buffer.INDICATOR_MAX` (number, Read-only)




<a id="buffer.MARKER_MAX"></a>
#### `buffer.MARKER_MAX` (number, Read-only)




<a id="buffer.MARKNUM_FOLDER"></a>
#### `buffer.MARKNUM_FOLDER` (number, Read-only)




<a id="buffer.MARKNUM_FOLDEREND"></a>
#### `buffer.MARKNUM_FOLDEREND` (number, Read-only)




<a id="buffer.MARKNUM_FOLDERMIDTAIL"></a>
#### `buffer.MARKNUM_FOLDERMIDTAIL` (number, Read-only)




<a id="buffer.MARKNUM_FOLDEROPEN"></a>
#### `buffer.MARKNUM_FOLDEROPEN` (number, Read-only)




<a id="buffer.MARKNUM_FOLDEROPENMID"></a>
#### `buffer.MARKNUM_FOLDEROPENMID` (number, Read-only)




<a id="buffer.MARKNUM_FOLDERSUB"></a>
#### `buffer.MARKNUM_FOLDERSUB` (number, Read-only)




<a id="buffer.MARKNUM_FOLDERTAIL"></a>
#### `buffer.MARKNUM_FOLDERTAIL` (number, Read-only)




<a id="buffer.MARK_AVAILABLE"></a>
#### `buffer.MARK_AVAILABLE` (number, Read-only)




<a id="buffer.MULTIAUTOC_EACH"></a>
#### `buffer.MULTIAUTOC_EACH` (number, Read-only)




<a id="buffer.MULTIAUTOC_ONCE"></a>
#### `buffer.MULTIAUTOC_ONCE` (number, Read-only)




<a id="buffer.MULTIPASTE_EACH"></a>
#### `buffer.MULTIPASTE_EACH` (number, Read-only)




<a id="buffer.MULTIPASTE_ONCE"></a>
#### `buffer.MULTIPASTE_ONCE` (number, Read-only)




<a id="buffer.ORDER_CUSTOM"></a>
#### `buffer.ORDER_CUSTOM` (number, Read-only)




<a id="buffer.ORDER_PERFORMSORT"></a>
#### `buffer.ORDER_PERFORMSORT` (number, Read-only)




<a id="buffer.ORDER_PRESORTED"></a>
#### `buffer.ORDER_PRESORTED` (number, Read-only)




<a id="buffer.SEL_LINES"></a>
#### `buffer.SEL_LINES` (number, Read-only)




<a id="buffer.SEL_RECTANGLE"></a>
#### `buffer.SEL_RECTANGLE` (number, Read-only)




<a id="buffer.SEL_STREAM"></a>
#### `buffer.SEL_STREAM` (number, Read-only)




<a id="buffer.SEL_THIN"></a>
#### `buffer.SEL_THIN` (number, Read-only)




<a id="buffer.UPDATE_CONTENT"></a>
#### `buffer.UPDATE_CONTENT` (number, Read-only)




<a id="buffer.UPDATE_SELECTION"></a>
#### `buffer.UPDATE_SELECTION` (number, Read-only)




<a id="buffer.VS_NONE"></a>
#### `buffer.VS_NONE` (number, Read-only)




<a id="buffer.VS_RECTANGULARSELECTION"></a>
#### `buffer.VS_RECTANGULARSELECTION` (number, Read-only)




<a id="buffer.VS_USERACCESSIBLE"></a>
#### `buffer.VS_USERACCESSIBLE` (number, Read-only)




<a id="buffer.additional_selection_typing"></a>
#### `buffer.additional_selection_typing` (bool)

Type into multiple selections.
  The default value is `false`.

<a id="buffer.anchor"></a>
#### `buffer.anchor` (number)

The anchor's position.

<a id="buffer.annotation_lines"></a>
#### `buffer.annotation_lines` (table, Read-only)

Table of the number of annotation text lines per line number.

<a id="buffer.annotation_style"></a>
#### `buffer.annotation_style` (table)

Table of style numbers for annotation text per line number.
  Only some style attributes are active in annotations: font, size/size_fractional, bold/weight,
  italics, fore, back, and character_set.

<a id="buffer.annotation_text"></a>
#### `buffer.annotation_text` (table)

Table of annotation text per line number.

<a id="buffer.auto_c_auto_hide"></a>
#### `buffer.auto_c_auto_hide` (bool)

Automatically cancel an autocompletion or user list when no entries match typed text.
  The default value is `true`.

<a id="buffer.auto_c_cancel_at_start"></a>
#### `buffer.auto_c_cancel_at_start` (bool)

Cancel an autocompletion list when backspacing to a position before where autocompletion
  started (instead of before the word being completed).
  This option has no effect for a user list.
  The default value is `true`.

<a id="buffer.auto_c_case_insensitive_behavior"></a>
#### `buffer.auto_c_case_insensitive_behavior` (number)

The behavior mode for a case insensitive autocompletion or user list when
  [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`.

  * `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`
    Prefer to select case-sensitive matches.
  * `buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE`
    No preference.

  The default value is `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`.

<a id="buffer.auto_c_choose_single"></a>
#### `buffer.auto_c_choose_single` (bool)

Automatically choose the item in a single-item autocompletion list.
  This option has no effect for a user list.
  The default value is `false`.

<a id="buffer.auto_c_current"></a>
#### `buffer.auto_c_current` (number, Read-only)

The index of the currently selected item in an autocompletion or user list.

<a id="buffer.auto_c_current_text"></a>
#### `buffer.auto_c_current_text` (string, Read-only)

The text of the currently selected item in an autocompletion or user list.

<a id="buffer.auto_c_drop_rest_of_word"></a>
#### `buffer.auto_c_drop_rest_of_word` (bool)

Delete any word characters immediately to the right of autocompleted text.
  The default value is `false`.

<a id="buffer.auto_c_fill_ups"></a>
#### `buffer.auto_c_fill_ups` (string, Write-only)

The set of characters that choose the currently selected item in an autocompletion or user
  list when the user types one of them.
  The default value is `''`.

<a id="buffer.auto_c_ignore_case"></a>
#### `buffer.auto_c_ignore_case` (bool)

Ignore case when searching an autocompletion or user list for matches.
  The default value is `false`.

<a id="buffer.auto_c_multi"></a>
#### `buffer.auto_c_multi` (number)

The multiple selection autocomplete mode.

  * `buffer.MULTIAUTOC_ONCE`
    Autocomplete into only the main selection.
  * `buffer.MULTIAUTOC_EACH`
    Autocomplete into all selections.

  The default value is `buffer.MULTIAUTOC_ONCE`.

<a id="buffer.auto_c_order"></a>
#### `buffer.auto_c_order` (number)

The order setting for autocompletion and user lists.

  * `buffer.ORDER_PRESORTED`
    Lists passed to [`buffer.auto_c_show()`](#buffer.auto_c_show) are in sorted, alphabetical order.
  * `buffer.ORDER_PERFORMSORT`
    Sort autocompletion lists passed to [`buffer.auto_c_show()`](#buffer.auto_c_show).
  * `buffer.ORDER_CUSTOM`
    Lists passed to [`buffer.auto_c_show()`](#buffer.auto_c_show) are already in a custom order.

  The default value is `buffer.ORDER_PRESORTED`.

<a id="buffer.auto_c_separator"></a>
#### `buffer.auto_c_separator` (number)

The byte value of the character that separates autocompletion and user list list items.
  The default value is `32` (' ').

<a id="buffer.auto_c_type_separator"></a>
#### `buffer.auto_c_type_separator` (number)

The character byte that separates autocompletion and user list items and their image types.
  Autocompletion and user list items can display both an image and text. Register images
  and their types using [`view.register_image()`](#view.register_image) or [`view.register_rgba_image()`](#view.register_rgba_image)
  before appending image types to list items after type separator characters.
  The default value is 63 ('?').

<a id="buffer.back_space_un_indents"></a>
#### `buffer.back_space_un_indents` (bool)

Un-indent text when backspacing within indentation.
  The default value is `false`.

<a id="buffer.caret_sticky"></a>
#### `buffer.caret_sticky` (number)

The caret's preferred horizontal position when moving between lines.

  * `buffer.CARETSTICKY_OFF`
    Use the same position the caret had on the previous line.
  * `buffer.CARETSTICKY_ON`
    Use the last position the caret was moved to via the mouse, left/right arrow keys,
    home/end keys, etc. Typing text does not affect the position.
  * `buffer.CARETSTICKY_WHITESPACE`
    Use the position the caret had on the previous line, but prior to any inserted indentation.

  The default value is `buffer.CARETSTICKY_OFF`.

<a id="buffer.char_at"></a>
#### `buffer.char_at` (table, Read-only)

Table of character bytes per position.

<a id="buffer.column"></a>
#### `buffer.column` (table, Read-only)

Table of column numbers (taking tab widths into account) per position.
  Multi-byte characters count as single characters.

<a id="buffer.current_pos"></a>
#### `buffer.current_pos` (number)

The caret's position.
  When set, does not scroll the caret into view.

<a id="buffer.encoding"></a>
#### `buffer.encoding` (string or nil)

The string encoding of the file, or `nil` for binary files.

<a id="buffer.end_styled"></a>
#### `buffer.end_styled` (number, Read-only)

The current styling position or the last correctly styled character's position.

<a id="buffer.eol_annotation_style"></a>
#### `buffer.eol_annotation_style` (table)

Table of style numbers for EOL annotation text per line number.
  Only some style attributes are active in annotations: font, size/size_fractional, bold/weight,
  italics, fore, back, and character_set.

<a id="buffer.eol_annotation_text"></a>
#### `buffer.eol_annotation_text` (table)

Table of EOL annotation text per line number.

<a id="buffer.eol_mode"></a>
#### `buffer.eol_mode` (number)

The current end of line mode.
  Changing the current mode does not convert any of the buffer's existing end of line
  characters. Use [`buffer.convert_eols()`](#buffer.convert_eols) to do so.

  * `buffer.EOL_CRLF`
    Carriage return with line feed ("\r\n").
  * `buffer.EOL_CR`
    Carriage return ("\r").
  * `buffer.EOL_LF`
    Line feed ("\n").

  The default value is `buffer.EOL_CRLF` on Windows platforms, `buffer.EOL_LF` otherwise.

<a id="buffer.filename"></a>
#### `buffer.filename` (string)

The absolute file path associated with the buffer.

<a id="buffer.fold_level"></a>
#### `buffer.fold_level` (table)

Table of fold level bit-masks per line number.
  Fold level masks comprise of an integer level combined with any of the following bit flags:

  * `buffer.FOLDLEVELBASE`
    The initial fold level.
  * `buffer.FOLDLEVELWHITEFLAG`
    The line is blank.
  * `buffer.FOLDLEVELHEADERFLAG`
    The line is a header, or fold point.

<a id="buffer.fold_parent"></a>
#### `buffer.fold_parent` (table, Read-only)

Table of fold point line numbers per child line number.
  A line number of `-1` means no line was found.

<a id="buffer.indent"></a>
#### `buffer.indent` (number)

The number of spaces in one level of indentation.
  The default value is `0`, which uses the value of [`buffer.tab_width`](#buffer.tab_width).

<a id="buffer.indicator_current"></a>
#### `buffer.indicator_current` (number)

The indicator number in the range of `1` to `32` used by [`buffer.indicator_fill_range()`](#buffer.indicator_fill_range)
  and [`buffer.indicator_clear_range()`](#buffer.indicator_clear_range).

<a id="buffer.length"></a>
#### `buffer.length` (number, Read-only)

The number of bytes in the buffer.

<a id="buffer.line_count"></a>
#### `buffer.line_count` (number, Read-only)

The number of lines in the buffer.
  There is always at least one.

<a id="buffer.line_end_position"></a>
#### `buffer.line_end_position` (table, Read-only)

Table of positions at the ends of lines, but before any end of line characters, per
  line number.

<a id="buffer.line_indent_position"></a>
#### `buffer.line_indent_position` (table, Read-only)

Table of positions at the ends of indentation per line number.

<a id="buffer.line_indentation"></a>
#### `buffer.line_indentation` (table)

Table of column indentation amounts per line number.

<a id="buffer.main_selection"></a>
#### `buffer.main_selection` (number)

The number of the main or most recent selection.
  Only an existing selection can be made main.

<a id="buffer.margin_style"></a>
#### `buffer.margin_style` (table)

Table of style numbers in the text margin per line number.
  Only some style attributes are active in text margins: font, size, bold, italics, fore,
  and back.

<a id="buffer.margin_text"></a>
#### `buffer.margin_text` (table)

Table of text displayed in text margins per line number.

<a id="buffer.modify"></a>
#### `buffer.modify` (bool, Read-only)

Whether or not the buffer has unsaved changes.

<a id="buffer.move_extends_selection"></a>
#### `buffer.move_extends_selection` (bool, Read-only)

Whether or not regular caret movement alters the selected text.
  [`buffer.selection_mode`](#buffer.selection_mode) dictates this property.

<a id="buffer.multi_paste"></a>
#### `buffer.multi_paste` (number)

The multiple selection paste mode.

  * `buffer.MULTIPASTE_ONCE`
    Paste into only the main selection.
  * `buffer.MULTIPASTE_EACH`
    Paste into all selections.

  The default value is `buffer.MULTIPASTE_ONCE`.

<a id="buffer.multiple_selection"></a>
#### `buffer.multiple_selection` (bool)

Enable multiple selection.
  The default value is `false`.

<a id="buffer.overtype"></a>
#### `buffer.overtype` (bool)

Enable overtype mode, where typed characters overwrite existing ones.
  The default value is `false`.

<a id="buffer.punctuation_chars"></a>
#### `buffer.punctuation_chars` (string)

The string set of characters recognized as punctuation characters.
  Set this only after setting [`buffer.word_chars`](#buffer.word_chars).
  The default value is a string that contains all non-word and non-whitespace characters.

<a id="buffer.read_only"></a>
#### `buffer.read_only` (bool)

Whether or not the buffer is read-only.
  The default value is `false`.

<a id="buffer.rectangular_selection_anchor"></a>
#### `buffer.rectangular_selection_anchor` (number)

The rectangular selection's anchor position.

<a id="buffer.rectangular_selection_anchor_virtual_space"></a>
#### `buffer.rectangular_selection_anchor_virtual_space` (number)

The amount of virtual space for the rectangular selection's anchor.

<a id="buffer.rectangular_selection_caret"></a>
#### `buffer.rectangular_selection_caret` (number)

The rectangular selection's caret position.

<a id="buffer.rectangular_selection_caret_virtual_space"></a>
#### `buffer.rectangular_selection_caret_virtual_space` (number)

The amount of virtual space for the rectangular selection's caret.

<a id="buffer.search_flags"></a>
#### `buffer.search_flags` (number)

The bit-mask of search flags used by [`buffer.search_in_target()`](#buffer.search_in_target).

  * `buffer.FIND_WHOLEWORD`
    Match search text only when it is surrounded by non-word characters.
  * `buffer.FIND_MATCHCASE`
    Match search text case sensitively.
  * `buffer.FIND_WORDSTART`
    Match search text only when the previous character is a non-word character.
  * `buffer.FIND_REGEXP`
    Interpret search text as a regular expression.

  The default value is `0`.

<a id="buffer.selection_empty"></a>
#### `buffer.selection_empty` (bool, Read-only)

Whether or not no text is selected.

<a id="buffer.selection_end"></a>
#### `buffer.selection_end` (number)

The position of the end of the selected text.
  When set, becomes the current position, but is not scrolled into view.

<a id="buffer.selection_is_rectangle"></a>
#### `buffer.selection_is_rectangle` (bool, Read-only)

Whether or not the selection is a rectangular selection.

<a id="buffer.selection_mode"></a>
#### `buffer.selection_mode` (number)

The selection mode.

  * `buffer.SEL_STREAM`
    Character selection.
  * `buffer.SEL_RECTANGLE`
    Rectangular selection.
  * `buffer.SEL_LINES`
    Line selection.
  * `buffer.SEL_THIN`
    Thin rectangular selection. This is the mode after a rectangular selection has been
    typed into and ensures that no characters are selected.

  When set, caret movement alters the selected text until this field is set again to the
  same value or until [`buffer.cancel()`](#buffer.cancel) is called.

<a id="buffer.selection_n_anchor"></a>
#### `buffer.selection_n_anchor` (table)

Table of positions at the beginning of existing selections numbered from `1`, the main
  selection.

<a id="buffer.selection_n_anchor_virtual_space"></a>
#### `buffer.selection_n_anchor_virtual_space` (table)

Table of positions at the beginning of virtual space selected in existing selections
  numbered from `1`, the main selection.

<a id="buffer.selection_n_caret"></a>
#### `buffer.selection_n_caret` (table)

Table of positions at the end of existing selections numbered from `1`, the main selection.

<a id="buffer.selection_n_caret_virtual_space"></a>
#### `buffer.selection_n_caret_virtual_space` (table)

Table of positions at the end of virtual space selected in existing selections numbered from
  `1`, the main selection.

<a id="buffer.selection_n_end"></a>
#### `buffer.selection_n_end` (table)

Table of positions at the end of existing selections numbered from `1`, the main selection.

<a id="buffer.selection_n_end_virtual_space"></a>
#### `buffer.selection_n_end_virtual_space` (number, Read-only)

Table of positions at the end of virtual space selected in existing selections numbered from
  `1`, the main selection.

<a id="buffer.selection_n_start"></a>
#### `buffer.selection_n_start` (table)

Table of positions at the beginning of existing selections numbered from `1`, the main
  selection.

<a id="buffer.selection_n_start_virtual_space"></a>
#### `buffer.selection_n_start_virtual_space` (number, Read-only)

Table of positions at the beginning of virtual space selected in existing selections
  numbered from `1`, the main selection.

<a id="buffer.selection_start"></a>
#### `buffer.selection_start` (number)

The position of the beginning of the selected text.
  When set, becomes the anchor, but is not scrolled into view.

<a id="buffer.selections"></a>
#### `buffer.selections` (number, Read-only)

The number of active selections. There is always at least one selection.

<a id="buffer.style_at"></a>
#### `buffer.style_at` (table, Read-only)

Table of style numbers per position.

<a id="buffer.tab_indents"></a>
#### `buffer.tab_indents` (bool)

Indent text when tabbing within indentation.
  The default value is `false`.

<a id="buffer.tab_label"></a>
#### `buffer.tab_label` (string)

The buffer's tab label in the tab bar.

<a id="buffer.tab_width"></a>
#### `buffer.tab_width` (number)

The number of space characters represented by a tab character.
  The default value is `8`.

<a id="buffer.tag"></a>
#### `buffer.tag` (table, Read-only)

List of capture text for capture numbers from a regular expression search.

<a id="buffer.target_end"></a>
#### `buffer.target_end` (number)

The position of the end of the target range.
  This is also set by a successful [`buffer.search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_end_virtual_space"></a>
#### `buffer.target_end_virtual_space` (number)

The position of the end of virtual space in the target range.
  This is set to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set,
  or when [`buffer.set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.target_start"></a>
#### `buffer.target_start` (number)

The position of the beginning of the target range.
  This is also set by a successful [`buffer.search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_start_virtual_space"></a>
#### `buffer.target_start_virtual_space` (number)

The position of the beginning of virtual space in the target range.
  This is set to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set,
  or when [`buffer.set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.target_text"></a>
#### `buffer.target_text` (string, Read-only)

The text in the target range.

<a id="buffer.text_length"></a>
#### `buffer.text_length` (number, Read-only)

The number of bytes in the buffer.

<a id="buffer.use_tabs"></a>
#### `buffer.use_tabs` (bool)

Use tabs instead of spaces in indentation.
  Changing the current setting does not convert any of the buffer's existing indentation. Use
  [`textadept.editing.convert_indentation()`](#textadept.editing.convert_indentation) to do so.
  The default value is `true`.

<a id="buffer.virtual_space_options"></a>
#### `buffer.virtual_space_options` (number)

The virtual space mode.

  * `buffer.VS_NONE`
    Disable virtual space.
  * `buffer.VS_RECTANGULARSELECTION`
    Enable virtual space only for rectangular selections.
  * `buffer.VS_USERACCESSIBLE`
    Enable virtual space.
  * `buffer.VS_NOWRAPLINESTART`
    Prevent the caret from wrapping to the previous line via `buffer:char_left()` and
    `buffer:char_left_extend()`. This option is not restricted to virtual space and should
    be added to any of the above options.

  When virtual space is enabled, the caret may move into the space past end of line characters.
  The default value is `buffer.VS_NONE`.

<a id="buffer.whitespace_chars"></a>
#### `buffer.whitespace_chars` (string)

The string set of characters recognized as whitespace characters.
  Set this only after setting [`buffer.word_chars`](#buffer.word_chars).
  The default value is a string that contains all non-newline characters less than ASCII
  value 33.

<a id="buffer.word_chars"></a>
#### `buffer.word_chars` (string)

The string set of characters recognized as word characters.
  The default value is a string that contains alphanumeric characters, an underscore, and
  all characters greater than ASCII value 127.


### Functions defined by `buffer`

<a id="buffer.add_selection"></a>
#### `buffer.add_selection`(*buffer, end\_pos, start\_pos*)

Selects the range of text between positions *start_pos* to *end_pos* as the main selection,
retaining all other selections as additional selections.
Since an empty selection (i.e. the current position) still counts as a selection, use
`buffer.set_selection()` first when setting a list of selections.

Parameters:

* *`buffer`*: A buffer.
* *`end_pos`*: The caret position of the range of text to select in *buffer*.
* *`start_pos`*: The anchor position of the range of text to select in *buffer*.

See also:

* [`buffer.set_selection`](#buffer.set_selection)

<a id="buffer.add_text"></a>
#### `buffer.add_text`(*buffer, text*)

Adds string *text* to the buffer at the caret position and moves the caret to the end of
the added text without scrolling it into view.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to add.

<a id="buffer.annotation_clear_all"></a>
#### `buffer.annotation_clear_all`(*buffer*)

Clears annotations from all lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.append_text"></a>
#### `buffer.append_text`(*buffer, text*)

Appends string *text* to the end of the buffer without modifying any existing selections or
scrolling the text into view.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to append.

<a id="buffer.auto_c_active"></a>
#### `buffer.auto_c_active`(*buffer*)

Returns whether or not an autocompletion or user list is visible.

Parameters:

* *`buffer`*: A buffer.

Return:

* bool

<a id="buffer.auto_c_cancel"></a>
#### `buffer.auto_c_cancel`(*buffer*)

Cancels the displayed autocompletion or user list.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.auto_c_complete"></a>
#### `buffer.auto_c_complete`(*buffer*)

Completes the current word with the one selected in an autocompletion list.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.auto_c_pos_start"></a>
#### `buffer.auto_c_pos_start`(*buffer*)

Returns the position where autocompletion started or where a user list was shown.

Parameters:

* *`buffer`*: A buffer.

Return:

* number

<a id="buffer.auto_c_select"></a>
#### `buffer.auto_c_select`(*buffer, prefix*)

Selects the first item that starts with string *prefix* in an autocompletion or user list,
using the case sensitivity setting `buffer.auto_c_ignore_case`.

Parameters:

* *`buffer`*: A buffer.
* *`prefix`*: The item in the list to select.

<a id="buffer.auto_c_show"></a>
#### `buffer.auto_c_show`(*buffer, len\_entered, items*)

Displays an autocompletion list constructed from string *items* (whose items are delimited by
`buffer.auto_c_separator` characters) using *len_entered* number of characters behind the
caret as the prefix of the word to be autocompleted.
The sorted order of *items* (`buffer.auto_c_order`) must have already been defined.

Parameters:

* *`buffer`*: A buffer.
* *`len_entered`*: The number of characters before the caret used to provide the context.
* *`items`*: The sorted string of words to show, separated by `buffer.auto_c_separator`
  characters (initially spaces).

See also:

* [`buffer.auto_c_separator`](#buffer.auto_c_separator)
* [`buffer.auto_c_order`](#buffer.auto_c_order)

<a id="buffer.auto_c_stops"></a>
#### `buffer.auto_c_stops`(*buffer, chars*)

Allows the user to type any character in string set *chars* in order to cancel an autocompletion
or user list.
The default set is empty.

Parameters:

* *`buffer`*: A buffer.
* *`chars`*: The string of characters that cancel autocompletion. This string is empty
  by default.

<a id="buffer.back_tab"></a>
#### `buffer.back_tab`(*buffer*)

Un-indents the text on the selected lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.begin_undo_action"></a>
#### `buffer.begin_undo_action`(*buffer*)

Starts a sequence of actions to be undone or redone as a single action.
May be nested.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.brace_match"></a>
#### `buffer.brace_match`(*buffer, pos, max\_re\_style*)

Returns the position of the matching brace for the brace character at position *pos*, taking
nested braces into account, or `-1`.
The brace characters recognized are '(', ')', '[', ']', '{', '}', '<', and '>' and must have
the same style.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position of the brace in *buffer* to match.
* *`max_re_style`*: Must be `0`. Reserved for expansion.

Return:

* number

<a id="buffer.can_redo"></a>
#### `buffer.can_redo`(*buffer*)

Returns whether or not there is an action to be redone.

Parameters:

* *`buffer`*: A buffer.

Return:

* bool

<a id="buffer.can_undo"></a>
#### `buffer.can_undo`(*buffer*)

Returns whether or not there is an action to be undone.

Parameters:

* *`buffer`*: A buffer.

Return:

* bool

<a id="buffer.cancel"></a>
#### `buffer.cancel`(*buffer*)

Cancels the active selection mode, autocompletion or user list, call tip, etc.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_left"></a>
#### `buffer.char_left`(*buffer*)

Moves the caret left one character.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_left_extend"></a>
#### `buffer.char_left_extend`(*buffer*)

Moves the caret left one character, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_left_rect_extend"></a>
#### `buffer.char_left_rect_extend`(*buffer*)

Moves the caret left one character, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_right"></a>
#### `buffer.char_right`(*buffer*)

Moves the caret right one character.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_right_extend"></a>
#### `buffer.char_right_extend`(*buffer*)

Moves the caret right one character, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.char_right_rect_extend"></a>
#### `buffer.char_right_rect_extend`(*buffer*)

Moves the caret right one character, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.choose_caret_x"></a>
#### `buffer.choose_caret_x`(*buffer*)

Identifies the current horizontal caret position as the caret's preferred horizontal position
when moving between lines.

Parameters:

* *`buffer`*: A buffer.

See also:

* [`buffer.caret_sticky`](#buffer.caret_sticky)

<a id="buffer.clear"></a>
#### `buffer.clear`(*buffer*)

Deletes the selected text or the character at the caret.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.clear_all"></a>
#### `buffer.clear_all`(*buffer*)

Deletes the buffer's text.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.clear_document_style"></a>
#### `buffer.clear_document_style`(*buffer*)

Clears all styling and folding information.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.close"></a>
#### `buffer.close`(*buffer, force*)

Closes the buffer, prompting the user to continue if there are unsaved changes (unless *force*
is `true`), and returns `true` if the buffer was closed.

Parameters:

* *`buffer`*: A buffer.
* *`force`*: Optional flag that discards unsaved changes without prompting the user. The
  default value is `false`.

Return:

* `true` if the buffer was closed; `nil` otherwise.

<a id="buffer.colorize"></a>
#### `buffer.colorize`(*buffer, start\_pos, end\_pos*)

Instructs the lexer to style and mark fold points in the range of text between *start_pos*
and *end_pos*.
If *end_pos* is `-1`, styles and marks to the end of the buffer.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text in *buffer* to process.
* *`end_pos`*: The end position of the range of text in *buffer* to process, or `-1` to
  process from *start_pos* to the end of *buffer*.

<a id="buffer.convert_eols"></a>
#### `buffer.convert_eols`(*buffer, mode*)

Converts all end of line characters to those in end of line mode *mode*.

Parameters:

* *`buffer`*: A buffer.
* *`mode`*: The end of line mode to convert to. Valid values are:
  * `buffer.EOL_CRLF`
  * `buffer.EOL_CR`
  * `buffer.EOL_LF`

<a id="buffer.copy"></a>
#### `buffer.copy`(*buffer*)

Copies the selected text to the clipboard.
Multiple selections are copied in order with no delimiters. Rectangular selections are copied
from top to bottom with end of line characters. Virtual space is not copied.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.copy_range"></a>
#### `buffer.copy_range`(*buffer, start\_pos, end\_pos*)

Copies to the clipboard the range of text between positions *start_pos* and *end_pos*.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text in *buffer* to copy.
* *`end_pos`*: The end position of the range of text in *buffer* to copy.

<a id="buffer.copy_text"></a>
#### `buffer.copy_text`(*buffer, text*)

Copies string *text* to the clipboard.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to copy.

<a id="buffer.count_characters"></a>
#### `buffer.count_characters`(*buffer, start\_pos, end\_pos*)

Returns the number of whole characters (taking multi-byte characters into account) between
positions *start_pos* and *end_pos*.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text in *buffer* to start counting at.
* *`end_pos`*: The end position of the range of text in *buffer* to stop counting at.

Return:

* number

<a id="buffer.cut"></a>
#### `buffer.cut`(*buffer*)

Cuts the selected text to the clipboard.
Multiple selections are copied in order with no delimiters. Rectangular selections are copied
from top to bottom with end of line characters. Virtual space is not copied.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.del_line_left"></a>
#### `buffer.del_line_left`(*buffer*)

Deletes the range of text from the caret to the beginning of the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.del_line_right"></a>
#### `buffer.del_line_right`(*buffer*)

Deletes the range of text from the caret to the end of the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.del_word_left"></a>
#### `buffer.del_word_left`(*buffer*)

Deletes the word to the left of the caret, including any leading non-word characters.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.del_word_right"></a>
#### `buffer.del_word_right`(*buffer*)

Deletes the word to the right of the caret, including any trailing non-word characters.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.del_word_right_end"></a>
#### `buffer.del_word_right_end`(*buffer*)

Deletes the word to the right of the caret, excluding any trailing non-word characters.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.delete"></a>
#### `buffer.delete`(*buffer*)

Deletes the buffer.
**Do not call this function.** Call `buffer:close()` instead. Emits a `BUFFER_DELETED` event.

Parameters:

* *`buffer`*: A buffer.

See also:

* [`events.BUFFER_DELETED`](#events.BUFFER_DELETED)

<a id="buffer.delete_back"></a>
#### `buffer.delete_back`(*buffer*)

Deletes the character behind the caret if no text is selected.
Otherwise, deletes the selected text.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.delete_back_not_line"></a>
#### `buffer.delete_back_not_line`(*buffer*)

Deletes the character behind the caret unless either the caret is at the beginning of a line
or text is selected.
If text is selected, deletes it.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.delete_range"></a>
#### `buffer.delete_range`(*buffer, pos, length*)

Deletes the range of text from position *pos* to *pos* + *length*.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The start position of the range of text in *buffer* to delete.
* *`length`*: The number of characters in the range of text to delete.

<a id="buffer.document_end"></a>
#### `buffer.document_end`(*buffer*)

Moves the caret to the end of the buffer.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.document_end_extend"></a>
#### `buffer.document_end_extend`(*buffer*)

Moves the caret to the end of the buffer, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.document_start"></a>
#### `buffer.document_start`(*buffer*)

Moves the caret to the beginning of the buffer.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.document_start_extend"></a>
#### `buffer.document_start_extend`(*buffer*)

Moves the caret to the beginning of the buffer, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.drop_selection_n"></a>
#### `buffer.drop_selection_n`(*buffer, n*)

Drops existing selection number *n*.

Parameters:

* *`buffer`*: A buffer.
* *`n`*: The number of the existing selection.

<a id="buffer.edit_toggle_overtype"></a>
#### `buffer.edit_toggle_overtype`(*buffer*)

Toggles `buffer.overtype`.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.empty_undo_buffer"></a>
#### `buffer.empty_undo_buffer`(*buffer*)

Deletes the undo and redo history.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.end_undo_action"></a>
#### `buffer.end_undo_action`(*buffer*)

Ends a sequence of actions to be undone or redone as a single action.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.eol_annotation_clear_all"></a>
#### `buffer.eol_annotation_clear_all`(*buffer*)

Clears EOL annotations from all lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.find_column"></a>
#### `buffer.find_column`(*buffer, line, column*)

Returns the position of column number *column* on line number *line* (taking tab and multi-byte
characters into account), or the position at the end of line *line*.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* to use.
* *`column`*: The column number to use.

<a id="buffer.get_cur_line"></a>
#### `buffer.get_cur_line`(*buffer*)

Returns the current line's text and the caret's position on that line.

Parameters:

* *`buffer`*: A buffer.

Return:

* string, number

<a id="buffer.get_last_child"></a>
#### `buffer.get_last_child`(*buffer, line, level*)

Returns the line number of the last line after line number *line* whose fold level is greater
than *level*.
If *level* is `-1`, returns the level of *line*.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* of a header line.
* *`level`*: The fold level, or `-1` for the level of *line*.

<a id="buffer.get_lexer"></a>
#### `buffer.get_lexer`(*buffer, current*)

Returns the buffer's lexer name.
If *current* is `true`, returns the name of the lexer under the caret in a multiple-language
lexer.

Parameters:

* *`buffer`*: A buffer.
* *`current`*: Whether or not to get the lexer at the current caret position in multi-language
  lexers. The default is `false` and returns the parent lexer.

<a id="buffer.get_line"></a>
#### `buffer.get_line`(*buffer, line*)

Returns the text on line number *line*, including end of line characters.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* to use.

Return:

* string, number

<a id="buffer.get_sel_text"></a>
#### `buffer.get_sel_text`(*buffer*)

Returns the selected text.
Multiple selections are included in order with no delimiters. Rectangular selections are
included from top to bottom with end of line characters. Virtual space is not included.

Parameters:

* *`buffer`*: A buffer.

Return:

* string, number

<a id="buffer.get_text"></a>
#### `buffer.get_text`(*buffer*)

Returns the buffer's text.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.goto_line"></a>
#### `buffer.goto_line`(*buffer, line*)

Moves the caret to the beginning of line number *line* and scrolls it into view, event if
*line* is hidden.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* to go to.

<a id="buffer.goto_pos"></a>
#### `buffer.goto_pos`(*buffer, pos*)

Moves the caret to position *pos* and scrolls it into view.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to go to.

<a id="buffer.home"></a>
#### `buffer.home`(*buffer*)

Moves the caret to the beginning of the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_display"></a>
#### `buffer.home_display`(*buffer*)

Moves the caret to the beginning of the current wrapped line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_display_extend"></a>
#### `buffer.home_display_extend`(*buffer*)

Moves the caret to the beginning of the current wrapped line, extending the selected text
to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_extend"></a>
#### `buffer.home_extend`(*buffer*)

Moves the caret to the beginning of the current line, extending the selected text to the
new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_rect_extend"></a>
#### `buffer.home_rect_extend`(*buffer*)

Moves the caret to the beginning of the current line, extending the rectangular selection
to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_wrap"></a>
#### `buffer.home_wrap`(*buffer*)

Moves the caret to the beginning of the current wrapped line or, if already there, to the
beginning of the actual line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.home_wrap_extend"></a>
#### `buffer.home_wrap_extend`(*buffer*)

Like `buffer.home_wrap()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.indicator_all_on_for"></a>
#### `buffer.indicator_all_on_for`(*buffer, pos*)

Returns a bit-mask that represents which indicators are on at position *pos*.
The first bit is set if indicator 1 is on, the second bit for indicator 2, etc.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to get indicators at.

Return:

* number

<a id="buffer.indicator_clear_range"></a>
#### `buffer.indicator_clear_range`(*buffer, pos, length*)

Clears indicator number `buffer.indicator_current` over the range of text from position *pos*
to *pos* + *length*.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The start position of the range of text in *buffer* to clear indicators over.
* *`length`*: The number of characters in the range of text to clear indicators over.

<a id="buffer.indicator_end"></a>
#### `buffer.indicator_end`(*buffer, indicator, pos*)

Returns the next boundary position, starting from position *pos*, of indicator number
*indicator*, in the range of `1` to `32`.
Returns `1` if *indicator* was not found.

Parameters:

* *`buffer`*: A buffer.
* *`indicator`*: An indicator number in the range of `1` to `32`.
* *`pos`*: The position in *buffer* of the indicator.

<a id="buffer.indicator_fill_range"></a>
#### `buffer.indicator_fill_range`(*buffer, pos, length*)

Fills the range of text from position *pos* to *pos* + *length* with indicator number
`buffer.indicator_current`.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The start position of the range of text in *buffer* to set indicators over.
* *`length`*: The number of characters in the range of text to set indicators over.

<a id="buffer.indicator_start"></a>
#### `buffer.indicator_start`(*buffer, indicator, pos*)

Returns the previous boundary position, starting from position *pos*, of indicator number
*indicator*, in the range of `1` to `32`.
Returns `1` if *indicator* was not found.

Parameters:

* *`buffer`*: A buffer.
* *`indicator`*: An indicator number in the range of `1` to `32`.
* *`pos`*: The position in *buffer* of the indicator.

<a id="buffer.insert_text"></a>
#### `buffer.insert_text`(*buffer, pos, text*)

Inserts string *text* at position *pos*, removing any selections.
If *pos* is `-1`, inserts *text* at the caret position.
If the caret is after the *pos*, it is moved appropriately, but not scrolled into view.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to insert text at, or `-1` for the current position.
* *`text`*: The text to insert.

<a id="buffer.is_range_word"></a>
#### `buffer.is_range_word`(*buffer, start\_pos, end\_pos*)

Returns whether or not the the positions *start_pos* and *end_pos* are at word boundaries.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text in *buffer* to check for a word
  boundary at.
* *`end_pos`*: The end position of the range of text in *buffer* to check for a word
  boundary at.

<a id="buffer.line_copy"></a>
#### `buffer.line_copy`(*buffer*)

Copies the current line to the clipboard.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_cut"></a>
#### `buffer.line_cut`(*buffer*)

Cuts the current line to the clipboard.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_delete"></a>
#### `buffer.line_delete`(*buffer*)

Deletes the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_down"></a>
#### `buffer.line_down`(*buffer*)

Moves the caret down one line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_down_extend"></a>
#### `buffer.line_down_extend`(*buffer*)

Moves the caret down one line, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_down_rect_extend"></a>
#### `buffer.line_down_rect_extend`(*buffer*)

Moves the caret down one line, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_duplicate"></a>
#### `buffer.line_duplicate`(*buffer*)

Duplicates the current line on a new line below.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end"></a>
#### `buffer.line_end`(*buffer*)

Moves the caret to the end of the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_display"></a>
#### `buffer.line_end_display`(*buffer*)

Moves the caret to the end of the current wrapped line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_display_extend"></a>
#### `buffer.line_end_display_extend`(*buffer*)

Moves the caret to the end of the current wrapped line, extending the selected text to the
new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_extend"></a>
#### `buffer.line_end_extend`(*buffer*)

Moves the caret to the end of the current line, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_rect_extend"></a>
#### `buffer.line_end_rect_extend`(*buffer*)

Moves the caret to the end of the current line, extending the rectangular selection to the
new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_wrap"></a>
#### `buffer.line_end_wrap`(*buffer*)

Moves the caret to the end of the current wrapped line or, if already there, to the end of
the actual line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_end_wrap_extend"></a>
#### `buffer.line_end_wrap_extend`(*buffer*)

Like `buffer.line_end_wrap()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_from_position"></a>
#### `buffer.line_from_position`(*buffer, pos*)

Returns the line number of the line that contains position *pos*.
Returns `1` if *pos* is less than 1 or `buffer.line_count` if *pos* is greater than
`buffer.length + 1`.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to get the line number of.

Return:

* number

<a id="buffer.line_length"></a>
#### `buffer.line_length`(*buffer, line*)

Returns the number of bytes on line number *line*, including end of line characters.
To get line length excluding end of line characters, use `buffer.line_end_position[line]
- buffer.position_from_line(line)`.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* to get the length of.

Return:

* number

<a id="buffer.line_reverse"></a>
#### `buffer.line_reverse`(*buffer*)

Reverses the order of the selected lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_transpose"></a>
#### `buffer.line_transpose`(*buffer*)

Swaps the current line with the previous one.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_up"></a>
#### `buffer.line_up`(*buffer*)

Moves the caret up one line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_up_extend"></a>
#### `buffer.line_up_extend`(*buffer*)

Moves the caret up one line, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.line_up_rect_extend"></a>
#### `buffer.line_up_rect_extend`(*buffer*)

Moves the caret up one line, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.lines_join"></a>
#### `buffer.lines_join`(*buffer*)

Joins the lines in the target range, inserting spaces between the words joined at line
boundaries.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.lines_split"></a>
#### `buffer.lines_split`(*buffer, pixel\_width, width*)

Splits the lines in the target range into lines *width* pixels wide.
If *width* is `0`, splits the lines in the target range into lines as wide as the view.

Parameters:

* *`buffer`*: A buffer.
* *`pixel_width`*: 
* *`width`*: The pixel width to split lines at. When `0`, uses the width of the view.

<a id="buffer.lower_case"></a>
#### `buffer.lower_case`(*buffer*)

Converts the selected text to lower case letters.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.margin_text_clear_all"></a>
#### `buffer.margin_text_clear_all`(*buffer*)

Clears all text in text margins.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.marker_add"></a>
#### `buffer.marker_add`(*buffer, line, marker*)

Adds marker number *marker*, in the range of `1` to `32`, to line number *line*, returning
the added marker's handle which can be used in `buffer.marker_delete_handle()` and
`buffer.marker_line_from_handle()`, or `-1` if *line* is invalid.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to add the marker on.
* *`marker`*: The marker number in the range of `1` to `32` to add.

Return:

* number

<a id="buffer.marker_add_set"></a>
#### `buffer.marker_add_set`(*buffer, line, marker\_mask*)

Adds the markers specified in marker bit-mask *marker_mask* to line number *line*.
The first bit is set to add marker number 1, the second bit for marker number 2, and so on
up to marker number 32.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to add the markers on.
* *`marker_mask`*: The mask of markers to set. Set the first bit to set marker 1, the second
  bit for marker 2 and so on.

<a id="buffer.marker_delete"></a>
#### `buffer.marker_delete`(*buffer, line, marker*)

Deletes marker number *marker*, in the range of `1` to `32`, from line number *line*. If
*marker* is `-1`, deletes all markers from *line*.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to delete the marker on.
* *`marker`*: The marker number in the range of `1` to `32` to delete from *line*, or `-1`
  to delete all markers from the line.

<a id="buffer.marker_delete_all"></a>
#### `buffer.marker_delete_all`(*buffer, marker*)

Deletes marker number *marker*, in the range of `1` to `32`, from any line that has it.
If *marker* is `-1`, deletes all markers from all lines.

Parameters:

* *`buffer`*: A buffer.
* *`marker`*: The marker number in the range of `1` to `32` to delete from all lines, or
  `-1` to delete all markers from all lines.

<a id="buffer.marker_delete_handle"></a>
#### `buffer.marker_delete_handle`(*buffer, handle*)

Deletes the marker with handle *handle* returned by `buffer.marker_add()`.

Parameters:

* *`buffer`*: A buffer.
* *`handle`*: The identifier of a marker returned by `buffer.marker_add()`.

<a id="buffer.marker_get"></a>
#### `buffer.marker_get`(*buffer, line*)

Returns a bit-mask that represents the markers on line number *line*.
The first bit is set if marker number 1 is present, the second bit for marker number 2,
and so on.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to get markers on.

Return:

* number

<a id="buffer.marker_handle_from_line"></a>
#### `buffer.marker_handle_from_line`(*buffer, line, n*)

Returns the handle of the *n*th marker on line number *line*, or `-1` if no such marker exists.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to get markers on.
* *`n`*: The marker to get the handle of.

<a id="buffer.marker_line_from_handle"></a>
#### `buffer.marker_line_from_handle`(*buffer, handle*)

Returns the line number of the line that contains the marker with handle *handle* (returned
`buffer.marker_add()`), or `-1` if the line was not found.

Parameters:

* *`buffer`*: A buffer.
* *`handle`*: The identifier of a marker returned by `buffer.marker_add()`.

Return:

* number

<a id="buffer.marker_next"></a>
#### `buffer.marker_next`(*buffer, line, marker\_mask*)

Returns the first line number, starting at line number *line*, that contains all of the
markers represented by marker bit-mask *marker_mask*.
Returns `-1` if no line was found.
The first bit is set if marker 1 is set, the second bit for marker 2, etc., up to marker 32.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The start line to search from.
* *`marker_mask`*: The mask of markers to find. Set the first bit to find marker 1, the
  second bit for marker 2, and so on.

Return:

* number

<a id="buffer.marker_number_from_line"></a>
#### `buffer.marker_number_from_line`(*buffer, line, n*)

Returns the number of the *n*th marker on line number *line*, or `-1` if no such marker exists.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number to get markers on.
* *`n`*: The marker to get the number of.

<a id="buffer.marker_previous"></a>
#### `buffer.marker_previous`(*buffer, line, marker\_mask*)

Returns the last line number, before or on line number *line*, that contains all of the
markers represented by marker bit-mask *marker_mask*.
Returns `-1` if no line was found.
The first bit is set if marker 1 is set, the second bit for marker 2, etc., up to marker 32.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The start line to search from.
* *`marker_mask`*: The mask of markers to find. Set the first bit to find marker 1, the
  second bit for marker 2, and so on.

Return:

* number

<a id="buffer.move_caret_inside_view"></a>
#### `buffer.move_caret_inside_view`(*buffer*)

Moves the caret into view if it is not already, removing any selections.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.move_selected_lines_down"></a>
#### `buffer.move_selected_lines_down`(*buffer*)

Shifts the selected lines down one line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.move_selected_lines_up"></a>
#### `buffer.move_selected_lines_up`(*buffer*)

Shifts the selected lines up one line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.multiple_select_add_each"></a>
#### `buffer.multiple_select_add_each`(*buffer*)

Adds to the set of selections each occurrence of the main selection within the target range.
If there is no selected text, the current word is used.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.multiple_select_add_next"></a>
#### `buffer.multiple_select_add_next`(*buffer*)

Adds to the set of selections the next occurrence of the main selection within the target
range, makes that occurrence the new main selection, and scrolls it into view.
If there is no selected text, the current word is used.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.name_of_style"></a>
#### `buffer.name_of_style`(*buffer, style*)

Returns the name of style number *style*, which is between `1` and `256`.

Parameters:

* *`buffer`*: A buffer.
* *`style`*: The style number between `1` and `256` to get the name of.

Return:

* string

<a id="buffer.new"></a>
#### `buffer.new`()

Creates a new buffer, displays it in the current view, and returns it.
Emits a `BUFFER_NEW` event.

Return:

* the new buffer.

See also:

* [`events.BUFFER_NEW`](#events.BUFFER_NEW)

<a id="buffer.new_line"></a>
#### `buffer.new_line`(*buffer*)

Types a new line at the caret position according to [`buffer.eol_mode`](#buffer.eol_mode).

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_down"></a>
#### `buffer.page_down`(*buffer*)

Moves the caret down one page.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_down_extend"></a>
#### `buffer.page_down_extend`(*buffer*)

Moves the caret down one page, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_down_rect_extend"></a>
#### `buffer.page_down_rect_extend`(*buffer*)

Moves the caret down one page, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_up"></a>
#### `buffer.page_up`(*buffer*)

Moves the caret up one page.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_up_extend"></a>
#### `buffer.page_up_extend`(*buffer*)

Moves the caret up one page, extending the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.page_up_rect_extend"></a>
#### `buffer.page_up_rect_extend`(*buffer*)

Moves the caret up one page, extending the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.para_down"></a>
#### `buffer.para_down`(*buffer*)

Moves the caret down one paragraph.
Paragraphs are surrounded by one or more blank lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.para_down_extend"></a>
#### `buffer.para_down_extend`(*buffer*)

Moves the caret down one paragraph, extending the selected text to the new position.
Paragraphs are surrounded by one or more blank lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.para_up"></a>
#### `buffer.para_up`(*buffer*)

Moves the caret up one paragraph.
Paragraphs are surrounded by one or more blank lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.para_up_extend"></a>
#### `buffer.para_up_extend`(*buffer*)

Moves the caret up one paragraph, extending the selected text to the new position.
Paragraphs are surrounded by one or more blank lines.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.paste"></a>
#### `buffer.paste`(*buffer*)

Pastes the clipboard's contents into the buffer, replacing any selected text according to
`buffer.multi_paste`.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.position_after"></a>
#### `buffer.position_after`(*buffer, pos*)

Returns the position of the character after position *pos* (taking multi-byte characters
into account), or `buffer.length + 1` if there is no character after *pos*.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to get the position after from.

<a id="buffer.position_before"></a>
#### `buffer.position_before`(*buffer, pos*)

Returns the position of the character before position *pos* (taking multi-byte characters
into account), or `1` if there is no character before *pos*.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to get the position before from.

Return:

* number

<a id="buffer.position_from_line"></a>
#### `buffer.position_from_line`(*buffer, line*)

Returns the position at the beginning of line number *line*.
Returns `-1` if *line* is greater than `buffer.line_count + 1`.

Parameters:

* *`buffer`*: A buffer.
* *`line`*: The line number in *buffer* to get the beginning position for.

Return:

* number

<a id="buffer.position_relative"></a>
#### `buffer.position_relative`(*buffer, pos, n*)

Returns the position *n* characters before or after position *pos* (taking multi-byte
characters into account).
Returns `1` if the position is less than 1 or greater than `buffer.length + 1`.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* to get the relative position from.
* *`n`*: The relative number of characters to get the position for. A negative number
  indicates a position before while a positive number indicates a position after.

Return:

* number

<a id="buffer.redo"></a>
#### `buffer.redo`(*buffer*)

Redoes the next undone action.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.reload"></a>
#### `buffer.reload`(*buffer*)

Reloads the buffer's file contents, discarding any changes.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.replace_rectangular"></a>
#### `buffer.replace_rectangular`(*buffer, text*)

Replaces the rectangular selection with string *text*.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to replace the rectangular selection with.

<a id="buffer.replace_sel"></a>
#### `buffer.replace_sel`(*buffer, text*)

Replaces the selected text with string *text*, scrolling the caret into view.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to replace the selected text with.

<a id="buffer.replace_target"></a>
#### `buffer.replace_target`(*buffer, text*)

Replaces the text in the target range with string *text* sans modifying any selections or
scrolling the view.
Setting the target and calling this function with an empty string is another way to delete text.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to replace the target range with.

Return:

* number

<a id="buffer.replace_target_re"></a>
#### `buffer.replace_target_re`(*buffer, text*)

Replaces the text in the target range with string *text* but first replaces any "\d" sequences
with the text of capture number *d* from the regular expression (or the entire match for *d*
= 0), and then returns the replacement text's length.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to replace the target range with.

Return:

* number

<a id="buffer.rotate_selection"></a>
#### `buffer.rotate_selection`(*buffer*)

Designates the next additional selection to be the main selection.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.save"></a>
#### `buffer.save`(*buffer*)

Saves the buffer to its file.
If the buffer does not have a file, the user is prompted for one.
Emits `FILE_BEFORE_SAVE` and `FILE_AFTER_SAVE` events.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.save_as"></a>
#### `buffer.save_as`(*buffer, filename*)

Saves the buffer to file *filename* or the user-specified filename.
Emits a `FILE_AFTER_SAVE` event.

Parameters:

* *`buffer`*: A buffer.
* *`filename`*: Optional new filepath to save the buffer to. If `nil`, the user is prompted
  for one.

<a id="buffer.search_anchor"></a>
#### `buffer.search_anchor`(*buffer*)

Anchors the position that `buffer.search_next()` and `buffer.search_prev()` start at to the
beginning of the current selection or caret position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.search_in_target"></a>
#### `buffer.search_in_target`(*buffer, text*)

Searches for the first occurrence of string *text* in the target range bounded by
`buffer.target_start` and `buffer.target_end` using search flags `buffer.search_flags`
and, if found, sets the new target range to that occurrence, returning its position or `-1`
if *text* was not found.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to search the target range for.

Return:

* number

See also:

* [`buffer.search_flags`](#buffer.search_flags)

<a id="buffer.search_next"></a>
#### `buffer.search_next`(*buffer, flags, text*)

Searches for and selects the first occurrence of string *text* starting at the search
anchor using search flags *flags*, returning that occurrence's position or `-1` if *text*
was not found.
Selected text is not scrolled into view.

Parameters:

* *`buffer`*: A buffer.
* *`flags`*: The search flags to use. See `buffer.search_flags`.
* *`text`*: The text to search for.

Return:

* number

See also:

* [`buffer.search_flags`](#buffer.search_flags)

<a id="buffer.search_prev"></a>
#### `buffer.search_prev`(*buffer, flags, text*)

Searches for and selects the last occurrence of string *text* before the search anchor using
search flags *flags*, returning that occurrence's position or `-1` if *text* was not found.

Parameters:

* *`buffer`*: A buffer.
* *`flags`*: The search flags to use. See `buffer.search_flags`.
* *`text`*: The text to search for.

Return:

* number

See also:

* [`buffer.search_flags`](#buffer.search_flags)

<a id="buffer.select_all"></a>
#### `buffer.select_all`(*buffer*)

Selects all of the buffer's text without scrolling the view.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.selection_duplicate"></a>
#### `buffer.selection_duplicate`(*buffer*)

Duplicates the selected text to its right.
If multiple lines are selected, duplication starts at the end of the selection. If no text
is selected, duplicates the current line on a new line below.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.set_chars_default"></a>
#### `buffer.set_chars_default`(*buffer*)

Resets `buffer.word_chars`, `buffer.whitespace_chars`, and `buffer.punctuation_chars` to
their respective defaults.

Parameters:

* *`buffer`*: A buffer.

See also:

* [`buffer.word_chars`](#buffer.word_chars)
* [`buffer.whitespace_chars`](#buffer.whitespace_chars)
* [`buffer.punctuation_chars`](#buffer.punctuation_chars)

<a id="buffer.set_empty_selection"></a>
#### `buffer.set_empty_selection`(*buffer, pos*)

Moves the caret to position *pos* without scrolling the view and removes any selections.

Parameters:

* *`buffer`*: A buffer
* *`pos`*: The position in *buffer* to move to.

<a id="buffer.set_encoding"></a>
#### `buffer.set_encoding`(*buffer, encoding*)

Converts the buffer's contents to encoding *encoding*.

Parameters:

* *`buffer`*: A buffer.
* *`encoding`*: The string encoding to set. Valid encodings are ones that GNU iconv accepts. If
  `nil`, assumes a binary encoding.

Usage:

* `buffer:set_encoding('CP1252')`

<a id="buffer.set_lexer"></a>
#### `buffer.set_lexer`(*buffer, name*)

Associates string lexer name *name* or the auto-detected lexer name with the buffer and then
loads the appropriate language module if that module exists.

Parameters:

* *`buffer`*: A buffer.
* *`name`*: Optional string lexer name to set. If `nil`, attempts to auto-detect the
  buffer's lexer.

Usage:

* `buffer:set_lexer('lexer_name')`

<a id="buffer.set_save_point"></a>
#### `buffer.set_save_point`(*buffer*)

Indicates the buffer has no unsaved changes.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.set_sel"></a>
#### `buffer.set_sel`(*buffer, start\_pos, end\_pos*)

Selects the range of text between positions *start_pos* and *end_pos*, scrolling the selected
text into view.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text in *buffer* to select. If negative,
  it means the end of the buffer.
* *`end_pos`*: The end position of the range of text in *buffer* to select. If negative,
  it means remove any selection (i.e. set the `anchor` to the same position as `current_pos`).

<a id="buffer.set_selection"></a>
#### `buffer.set_selection`(*buffer, end\_pos, start\_pos*)

Selects the range of text between positions *start_pos* to *end_pos*, removing all other
selections.

Parameters:

* *`buffer`*: A buffer.
* *`end_pos`*: The caret position of the range of text to select in *buffer*.
* *`start_pos`*: The anchor position of the range of text to select in *buffer*.

<a id="buffer.set_styling"></a>
#### `buffer.set_styling`(*buffer, length, style*)

Assigns style number *style*, in the range from `1` to `256`, to the next *length* characters,
starting from the current styling position, and increments the styling position by *length*.
[`buffer:start_styling`](#buffer.start_styling) should be called before `buffer:set_styling()`.

Parameters:

* *`buffer`*: A buffer.
* *`length`*: The number of characters to style.
* *`style`*: The style number to set.

<a id="buffer.set_target_range"></a>
#### `buffer.set_target_range`(*buffer, start\_pos, end\_pos*)

Defines the target range's beginning and end positions as *start_pos* and *end_pos*,
respectively.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The position of the beginning of the target range.
* *`end_pos`*: The position of the end of the target range.

<a id="buffer.set_text"></a>
#### `buffer.set_text`(*buffer, text*)

Replaces the buffer's text with string *text*.

Parameters:

* *`buffer`*: A buffer.
* *`text`*: The text to set.

<a id="buffer.start_styling"></a>
#### `buffer.start_styling`(*buffer, position, unused*)

Begins styling at position *position* with styling bit-mask *style_mask*.
*style_mask* specifies which style bits can be set with `buffer.set_styling()`.

Parameters:

* *`buffer`*: A buffer.
* *`position`*: The position in *buffer* to start styling at.
* *`unused`*: Unused number. `0` can be safely used.

Usage:

* `buffer:start_styling(1, 0)`

See also:

* [`buffer.set_styling`](#buffer.set_styling)

<a id="buffer.stuttered_page_down"></a>
#### `buffer.stuttered_page_down`(*buffer*)

Moves the caret to the bottom of the page or, if already there, down one page.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.stuttered_page_down_extend"></a>
#### `buffer.stuttered_page_down_extend`(*buffer*)

Like `buffer.stuttered_page_down()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.stuttered_page_up"></a>
#### `buffer.stuttered_page_up`(*buffer*)

Moves the caret to the top of the page or, if already there, up one page.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.stuttered_page_up_extend"></a>
#### `buffer.stuttered_page_up_extend`(*buffer*)

Like `buffer.stuttered_page_up()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.style_of_name"></a>
#### `buffer.style_of_name`(*buffer, style\_name, string*)

Returns the style number associated with string *style_name*, or `view.STYLE_DEFAULT` if
*style_name* is not in use.

Parameters:

* *`buffer`*: A buffer.
* *`style_name`*: 
* *`string`*: The style name to get the number of.

Return:

* style number, between `1` and `256`.

See also:

* [`buffer.name_of_style`](#buffer.name_of_style)

<a id="buffer.swap_main_anchor_caret"></a>
#### `buffer.swap_main_anchor_caret`(*buffer*)

Swaps the main selection's beginning and end positions.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.tab"></a>
#### `buffer.tab`(*buffer*)

Indents the text on the selected lines or types a Tab character ("\t") at the caret position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.target_from_selection"></a>
#### `buffer.target_from_selection`(*buffer*)

Defines the target range's beginning and end positions as the beginning and end positions
of the main selection, respectively.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.target_whole_document"></a>
#### `buffer.target_whole_document`(*buffer*)

Defines the target range's beginning and end positions as the beginning and end positions
of the document, respectively.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.text_range"></a>
#### `buffer.text_range`(*buffer, start\_pos, end\_pos*)

Returns the range of text between positions *start_pos* and *end_pos*.

Parameters:

* *`buffer`*: A buffer.
* *`start_pos`*: The start position of the range of text to get in *buffer*.
* *`end_pos`*: The end position of the range of text to get in *buffer*.

<a id="buffer.toggle_caret_sticky"></a>
#### `buffer.toggle_caret_sticky`(*buffer*)

Cycles between `buffer.caret_sticky` option settings `buffer.CARETSTICKY_ON` and
`buffer.CARETSTICKY_OFF`.

Parameters:

* *`buffer`*: A buffer.

See also:

* [`buffer.caret_sticky`](#buffer.caret_sticky)

<a id="buffer.undo"></a>
#### `buffer.undo`(*buffer*)

Undoes the most recent action.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.upper_case"></a>
#### `buffer.upper_case`(*buffer*)

Converts the selected text to upper case letters.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.user_list_show"></a>
#### `buffer.user_list_show`(*buffer, id, items*)

Displays a user list identified by list identifier number *id* and constructed from string
*items* (whose items are delimited by `buffer.auto_c_separator` characters).
The sorted order of *items* (`buffer.auto_c_order`) must have already been defined. When the
user selects an item, *id* is sent in a `USER_LIST_SELECTION` event along with the selection.

Parameters:

* *`buffer`*: A buffer.
* *`id`*: The list identifier number greater than zero to use.
* *`items`*: The sorted string of words to show, separated by `buffer.auto_c_separator`
  characters (initially spaces).

See also:

* [`_SCINTILLA.next_user_list_type`](#_SCINTILLA.next_user_list_type)
* [`events.USER_LIST_SELECTION`](#events.USER_LIST_SELECTION)

<a id="buffer.vc_home"></a>
#### `buffer.vc_home`(*buffer*)

Moves the caret to the first visible character on the current line or, if already there,
to the beginning of the current line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_display"></a>
#### `buffer.vc_home_display`(*buffer*)

Moves the caret to the first visible character on the current wrapped line or, if already
there, to the beginning of the current wrapped line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_display_extend"></a>
#### `buffer.vc_home_display_extend`(*buffer*)

Like `buffer.vc_home_display()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_extend"></a>
#### `buffer.vc_home_extend`(*buffer*)

Like `buffer.vc_home()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_rect_extend"></a>
#### `buffer.vc_home_rect_extend`(*buffer*)

Like `buffer.vc_home()`, but extends the rectangular selection to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_wrap"></a>
#### `buffer.vc_home_wrap`(*buffer*)

Moves the caret to the first visible character on the current wrapped line or, if already
there, to the beginning of the actual line.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.vc_home_wrap_extend"></a>
#### `buffer.vc_home_wrap_extend`(*buffer*)

Like `buffer.vc_home_wrap()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_end_position"></a>
#### `buffer.word_end_position`(*buffer, pos, only\_word\_chars*)

Returns the position of the end of the word at position *pos*.
`buffer.word_chars` contains the set of characters that constitute words. If *pos* has a
non-word character to its right and *only_word_chars* is `false`, returns the first word
character's position.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* of the word.
* *`only_word_chars`*: If `true`, stops searching at the first non-word character in
  the search direction. Otherwise, the first character in the search direction sets the
  type of the search as word or non-word and the search stops at the first non-matching
  character. Searches are also terminated by the start or end of the buffer.

<a id="buffer.word_left"></a>
#### `buffer.word_left`(*buffer*)

Moves the caret left one word.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_left_end"></a>
#### `buffer.word_left_end`(*buffer*)

Moves the caret left one word, positioning it at the end of the previous word.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_left_end_extend"></a>
#### `buffer.word_left_end_extend`(*buffer*)

Like `buffer.word_left_end()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_left_extend"></a>
#### `buffer.word_left_extend`(*buffer*)

Moves the caret left one word, extending the selected text to the new position.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_part_left"></a>
#### `buffer.word_part_left`(*buffer*)

Moves the caret to the previous part of the current word.
Word parts are delimited by underscore characters or changes in capitalization.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_part_left_extend"></a>
#### `buffer.word_part_left_extend`(*buffer*)

Moves the caret to the previous part of the current word, extending the selected text to
the new position.
Word parts are delimited by underscore characters or changes in capitalization.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_part_right"></a>
#### `buffer.word_part_right`(*buffer*)

Moves the caret to the next part of the current word.
Word parts are delimited by underscore characters or changes in capitalization.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_part_right_extend"></a>
#### `buffer.word_part_right_extend`(*buffer*)

Moves the caret to the next part of the current word, extending the selected text to the
new position.
Word parts are delimited by underscore characters or changes in capitalization.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_right"></a>
#### `buffer.word_right`(*buffer*)

Moves the caret right one word.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_right_end"></a>
#### `buffer.word_right_end`(*buffer*)

Moves the caret right one word, positioning it at the end of the current word.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_right_end_extend"></a>
#### `buffer.word_right_end_extend`(*buffer*)

Like `buffer.word_right_end()`, but extends the selected text to the new position.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_right_extend"></a>
#### `buffer.word_right_extend`(*buffer*)

Moves the caret right one word, extending the selected text to the new position.
`buffer.word_chars` contains the set of characters that constitute words.

Parameters:

* *`buffer`*: A buffer.

<a id="buffer.word_start_position"></a>
#### `buffer.word_start_position`(*buffer, pos, only\_word\_chars*)

Returns the position of the beginning of the word at position *pos*.
`buffer.word_chars` contains the set of characters that constitute words. If *pos* has
a non-word character to its left and *only_word_chars* is `false`, returns the last word
character's position.

Parameters:

* *`buffer`*: A buffer.
* *`pos`*: The position in *buffer* of the word.
* *`only_word_chars`*: If `true`, stops searching at the first non-word character in
  the search direction. Otherwise, the first character in the search direction sets the
  type of the search as word or non-word and the search stops at the first non-matching
  character. Searches are also terminated by the start or end of the buffer.


---
<a id="events"></a>
## The `events` Module
---

Textadept's core event structure and handlers.

Textadept emits events when you do things like create a new buffer, press a key, click on
a menu, etc. You can even emit events yourself using Lua. Each event has a set of event
handlers, which are simply Lua functions called in the order they were connected to an
event. For example, if you created a module that needs to do something each time Textadept
creates a new buffer, connect a Lua function to the [`events.BUFFER_NEW`](#events.BUFFER_NEW) event:

    events.connect(events.BUFFER_NEW, function()
      -- Do something here.
    end)

Events themselves are nothing special. You do not have to declare one before using it. Events
are simply strings containing arbitrary event names. When either you or Textadept emits an
event, Textadept runs all event handlers connected to the event, passing any given arguments
to the event's handler functions. If an event handler explicitly returns a value that is not
`nil`, Textadept will not call subsequent handlers. This is useful if you want to stop the
propagation of an event like a keypress if your event handler handled it, or if you want to
use the event framework to pass values.


### Fields defined by `events`

<a id="events.APPLEEVENT_ODOC"></a>
#### `events.APPLEEVENT_ODOC` (string)

Emitted when macOS tells Textadept to open a file.
  Arguments:

  * _`uri`_: The UTF-8-encoded URI to open.

<a id="events.AUTO_C_CANCELED"></a>
#### `events.AUTO_C_CANCELED` (string)

Emitted when canceling an autocompletion or user list.

<a id="events.AUTO_C_CHAR_DELETED"></a>
#### `events.AUTO_C_CHAR_DELETED` (string)

Emitted after deleting a character while an autocompletion or user list is active.

<a id="events.AUTO_C_COMPLETED"></a>
#### `events.AUTO_C_COMPLETED` (string)

Emitted after inserting an item from an autocompletion list into the buffer.
  Arguments:

  * _`text`_: The selection's text.
  * _`position`_: The autocompleted word's beginning position.

<a id="events.AUTO_C_SELECTION"></a>
#### `events.AUTO_C_SELECTION` (string)

Emitted after selecting an item from an autocompletion list, but before inserting that
  item into the buffer.
  Automatic insertion can be canceled by calling [`buffer:auto_c_cancel()`](#buffer.auto_c_cancel) before returning
  from the event handler.
  Arguments:

  * _`text`_: The selection's text.
  * _`position`_: The autocompleted word's beginning position.

<a id="events.AUTO_C_SELECTION_CHANGE"></a>
#### `events.AUTO_C_SELECTION_CHANGE` (string)

Emitted as items are highlighted in an autocompletion or user list.
  Arguments:

  * _`id`_: Either the *id* from [`buffer.user_list_show()`](#buffer.user_list_show) or `0` for an autocompletion list.
  * _`text`_: The current selection's text.
  * _`position`_: The position the list was displayed at.

<a id="events.BUFFER_AFTER_REPLACE_TEXT"></a>
#### `events.BUFFER_AFTER_REPLACE_TEXT` (string)

Emitted after replacing the contents of the current buffer.
  Note that it is not guaranteed that [`events.BUFFER_BEFORE_REPLACE_TEXT`](#events.BUFFER_BEFORE_REPLACE_TEXT) was emitted
  previously.
  The buffer **must not** be modified during this event.

<a id="events.BUFFER_AFTER_SWITCH"></a>
#### `events.BUFFER_AFTER_SWITCH` (string)

Emitted right after switching to another buffer.
  The buffer being switched to is `buffer`.
  Emitted by [`view.goto_buffer()`](#view.goto_buffer).

<a id="events.BUFFER_BEFORE_REPLACE_TEXT"></a>
#### `events.BUFFER_BEFORE_REPLACE_TEXT` (string)

Emitted before replacing the contents of the current buffer.
  Note that it is not guaranteed that [`events.BUFFER_AFTER_REPLACE_TEXT`](#events.BUFFER_AFTER_REPLACE_TEXT) will be emitted
  shortly after this event.
  The buffer **must not** be modified during this event.

<a id="events.BUFFER_BEFORE_SWITCH"></a>
#### `events.BUFFER_BEFORE_SWITCH` (string)

Emitted right before switching to another buffer.
  The buffer being switched from is `buffer`.
  Emitted by [`view.goto_buffer()`](#view.goto_buffer).

<a id="events.BUFFER_DELETED"></a>
#### `events.BUFFER_DELETED` (string)

Emitted after deleting a buffer.
  Emitted by [`buffer.delete()`](#buffer.delete).

<a id="events.BUFFER_NEW"></a>
#### `events.BUFFER_NEW` (string)

Emitted after creating a new buffer.
  The new buffer is `buffer`.
  Emitted on startup and by [`buffer.new()`](#buffer.new).

<a id="events.CALL_TIP_CLICK"></a>
#### `events.CALL_TIP_CLICK` (string)

Emitted when clicking on a calltip.
  Arguments:

  * _`position`_: `1` if the up arrow was clicked, 2 if the down arrow was clicked, and
    0 otherwise.

<a id="events.CHAR_ADDED"></a>
#### `events.CHAR_ADDED` (string)

Emitted after the user types a text character into the buffer.
  Arguments:

  * _`code`_: The text character's character code.

<a id="events.COMMAND_TEXT_CHANGED"></a>
#### `events.COMMAND_TEXT_CHANGED` (string)

Emitted when the text in the command entry changes.
  `ui.command_entry:get_text()` returns the current text.

<a id="events.CSI"></a>
#### `events.CSI` (string)

Emitted when the terminal version receives an unrecognized CSI sequence.
  Arguments:

  * _`cmd`_: The 24-bit CSI command value. The lowest byte contains the command byte. The
    second lowest byte contains the leading byte, if any (e.g. '?'). The third lowest byte
    contains the intermediate byte, if any (e.g. '$').
  * _`args`_: Table of numeric arguments of the CSI sequence.

<a id="events.DOUBLE_CLICK"></a>
#### `events.DOUBLE_CLICK` (string)

Emitted after double-clicking the mouse button.
  Arguments:

  * _`position`_: The position double-clicked.
  * _`line`_: The line number of the position double-clicked.
  * _`modifiers`_: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
    `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
    key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
    `view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
    reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.DWELL_END"></a>
#### `events.DWELL_END` (string)

Emitted after `DWELL_START` when the user moves the mouse, presses a key, or scrolls the view.
  Arguments:

  * _`position`_: The position closest to *x* and *y*.
  * _`x`_: The x-coordinate of the mouse in the view.
  * _`y`_: The y-coordinate of the mouse in the view.

<a id="events.DWELL_START"></a>
#### `events.DWELL_START` (string)

Emitted when the mouse is stationary for [`view.mouse_dwell_time`](#view.mouse_dwell_time) milliseconds.
  Arguments:

  * _`position`_: The position closest to *x* and *y*.
  * _`x`_: The x-coordinate of the mouse in the view.
  * _`y`_: The y-coordinate of the mouse in the view.

<a id="events.ERROR"></a>
#### `events.ERROR` (string)

Emitted when an error occurs.
  Arguments:

  * _`text`_: The error message text.

<a id="events.FIND"></a>
#### `events.FIND` (string)

Emitted to find text via the Find & Replace Pane.
  Arguments:

  * _`text`_: The text to search for.
  * _`next`_: Whether or not to search forward.

<a id="events.FIND_TEXT_CHANGED"></a>
#### `events.FIND_TEXT_CHANGED` (string)

Emitted when the text in the "Find" field of the Find & Replace Pane changes.
  `ui.find.find_entry_text` contains the current text.

<a id="events.FOCUS"></a>
#### `events.FOCUS` (string)

Emitted when Textadept receives focus.
  This event is never emitted when Textadept is running in the terminal.

<a id="events.INDICATOR_CLICK"></a>
#### `events.INDICATOR_CLICK` (string)

Emitted when clicking the mouse on text that has an indicator present.
  Arguments:

  * _`position`_: The clicked text's position.
  * _`modifiers`_: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
    `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
    key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
    `view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
    reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.INDICATOR_RELEASE"></a>
#### `events.INDICATOR_RELEASE` (string)

Emitted when releasing the mouse after clicking on text that has an indicator present.
  Arguments:

  * _`position`_: The clicked text's position.
  * _`modifiers`_: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
    `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
    key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
    `view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
    reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.INITIALIZED"></a>
#### `events.INITIALIZED` (string)

Emitted after Textadept finishes initializing.

<a id="events.KEYPRESS"></a>
#### `events.KEYPRESS` (string)

Emitted when pressing a key.
  If any handler returns `true`, the key is not inserted into the buffer.
  Arguments:

  * _`code`_: The numeric key code.
  * _`shift`_: The "Shift" modifier key is held down.
  * _`ctrl`_: The "Control" modifier key is held down.
  * _`alt`_: The "Alt"/"Option" modifier key is held down.
  * _`cmd`_: The "Command" modifier key on macOS is held down.
  * _`caps_lock`_: The "Caps Lock" modifier is on.

<a id="events.MARGIN_CLICK"></a>
#### `events.MARGIN_CLICK` (string)

Emitted when clicking the mouse inside a sensitive margin.
  Arguments:

  * _`margin`_: The margin number clicked.
  * _`position`_: The beginning position of the clicked margin's line.
  * _`modifiers`_: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
    `view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
    key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
    `view.rectangular_selection_modifier` to `view.MOD_CTRL`, the "Control" modifier is
    reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.MENU_CLICKED"></a>
#### `events.MENU_CLICKED` (string)

Emitted after selecting a menu item.
  Arguments:

  * _`menu_id`_: The numeric ID of the menu item, which was defined in [`ui.menu()`](#ui.menu).

<a id="events.MOUSE"></a>
#### `events.MOUSE` (string)

Emitted by the terminal version for an unhandled mouse event.
  A handler should return `true` if it handled the event. Otherwise Textadept will try again.
  (This side effect for a `false` or `nil` return is useful for sending the original mouse
  event to a different view that a handler has switched to.)
  Arguments:

  * _`event`_: The mouse event: `view.MOUSE_PRESS`, `view.MOUSE_DRAG`, or `view.MOUSE_RELEASE`.
  * _`button`_: The mouse button number.
  * _`y`_: The y-coordinate of the mouse event, starting from 1.
  * _`x`_: The x-coordinate of the mouse event, starting from 1.
  * _`shift`_: The "Shift" modifier key is held down.
  * _`ctrl`_: The "Control" modifier key is held down.
  * _`alt`_: The "Alt"/"Option" modifier key is held down.

<a id="events.QUIT"></a>
#### `events.QUIT` (string)

Emitted when quitting Textadept.
  When connecting to this event, connect with an index of 1 if the handler needs to run
  before Textadept closes all open buffers. If a handler returns `true`, Textadept does not
  quit. It is not recommended to return `false` from a quit handler, as that may interfere
  with Textadept's normal shutdown procedure.
  Emitted by [`quit()`](#quit).

<a id="events.REPLACE"></a>
#### `events.REPLACE` (string)

Emitted to replace selected (found) text.
  Arguments:

  * _`text`_: The replacement text.

<a id="events.REPLACE_ALL"></a>
#### `events.REPLACE_ALL` (string)

Emitted to replace all occurrences of found text.
  Arguments:

  * _`find_text`_: The text to search for.
  * _`repl_text`_: The replacement text.

<a id="events.RESET_AFTER"></a>
#### `events.RESET_AFTER` (string)

Emitted after resetting Textadept's Lua state.
  Emitted by [`reset()`](#reset).
  Arguments:

  * _`persist`_: Table of data persisted by `events.RESET_BEFORE`. All handlers will have
    access to this same table.

<a id="events.RESET_BEFORE"></a>
#### `events.RESET_BEFORE` (string)

Emitted before resetting Textadept's Lua state.
  Emitted by [`reset()`](#reset).
  Arguments:

  * _`persist`_: Table to store persistent data in for use by `events.RESET_AFTER`. All
    handlers will have access to this same table.

<a id="events.RESUME"></a>
#### `events.RESUME` (string)

Emitted when resuming Textadept from a suspended state.
  This event is only emitted by the terminal version.

<a id="events.SAVE_POINT_LEFT"></a>
#### `events.SAVE_POINT_LEFT` (string)

Emitted after leaving a save point.

<a id="events.SAVE_POINT_REACHED"></a>
#### `events.SAVE_POINT_REACHED` (string)

Emitted after reaching a save point.

<a id="events.SUSPEND"></a>
#### `events.SUSPEND` (string)

Emitted when suspending Textadept. If any handler returns `true`, Textadept does not suspend.
  This event is only emitted by the terminal version.

<a id="events.TAB_CLICKED"></a>
#### `events.TAB_CLICKED` (string)

Emitted when the user clicks on a buffer tab.
  When connecting to this event, connect with an index of 1 if the handler needs to run
  before Textadept switches between buffers.
  Note that Textadept always displays a context menu on right-click.
  Arguments:

  * _`index`_: The numeric index of the clicked tab.
  * _`button`_: The mouse button number that was clicked, either `1` (left button), `2`
    (middle button), `3` (right button), `4` (wheel up), or `5` (wheel down).
  * _`shift`_: The "Shift" modifier key is held down.
  * _`ctrl`_: The "Control" modifier key is held down.
  * _`alt`_: The "Alt"/"Option" modifier key is held down.
  * _`cmd`_: The "Command" modifier key on macOS is held down.

<a id="events.UNFOCUS"></a>
#### `events.UNFOCUS` (string)

Emitted when Textadept loses focus.
  This event is never emitted when Textadept is running in the terminal.

<a id="events.UPDATE_UI"></a>
#### `events.UPDATE_UI` (string)

Emitted after the view is visually updated.
  Arguments:

  * _`updated`_: A bitmask of changes since the last update.

    + `buffer.UPDATE_CONTENT`
      Buffer contents, styling, or markers have changed.
    + `buffer.UPDATE_SELECTION`
      Buffer selection has changed (including caret movement).
    + `view.UPDATE_V_SCROLL`
      Buffer has scrolled vertically.
    + `view.UPDATE_H_SCROLL`
      Buffer has scrolled horizontally.

<a id="events.URI_DROPPED"></a>
#### `events.URI_DROPPED` (string)

Emitted after dragging and dropping a URI into a view.
  Arguments:

  * _`text`_: The UTF-8-encoded URI dropped.

<a id="events.USER_LIST_SELECTION"></a>
#### `events.USER_LIST_SELECTION` (string)

Emitted after selecting an item in a user list.
  Arguments:

  * _`id`_: The *id* from [`buffer.user_list_show()`](#buffer.user_list_show).
  * _`text`_: The selection's text.
  * _`position`_: The position the list was displayed at.

<a id="events.VIEW_AFTER_SWITCH"></a>
#### `events.VIEW_AFTER_SWITCH` (string)

Emitted right after switching to another view.
  The view being switched to is `view`.
  Emitted by [`ui.goto_view()`](#ui.goto_view).

<a id="events.VIEW_BEFORE_SWITCH"></a>
#### `events.VIEW_BEFORE_SWITCH` (string)

Emitted right before switching to another view.
  The view being switched from is `view`.
  Emitted by [`ui.goto_view()`](#ui.goto_view).

<a id="events.VIEW_NEW"></a>
#### `events.VIEW_NEW` (string)

Emitted after creating a new view.
  The new view is `view`.
  Emitted on startup and by [`view.split()`](#view.split).

<a id="events.ZOOM"></a>
#### `events.ZOOM` (string)

Emitted after changing [`view.zoom`](#view.zoom).
  Emitted by [`view.zoom_in()`](#view.zoom_in) and [`view.zoom_out()`](#view.zoom_out).


### Functions defined by `events`

<a id="events.connect"></a>
#### `events.connect`(*event, f, index*)

Adds function *f* to the set of event handlers for event *event* at position *index*.
If *index* not given, appends *f* to the set of handlers. *event* may be any arbitrary string
and does not need to have been previously defined.

Parameters:

* *`event`*: The string event name.
* *`f`*: The Lua function to connect to *event*.
* *`index`*: Optional index to insert the handler into.

Usage:

* `events.connect('my_event', function(msg) ui.print(msg) end)`

See also:

* [`events.disconnect`](#events.disconnect)

<a id="events.disconnect"></a>
#### `events.disconnect`(*event, f*)

Removes function *f* from the set of handlers for event *event*.

Parameters:

* *`event`*: The string event name.
* *`f`*: The Lua function connected to *event*.

See also:

* [`events.connect`](#events.connect)

<a id="events.emit"></a>
#### `events.emit`(*event, ...*)

Sequentially calls all handler functions for event *event* with the given arguments.
*event* may be any arbitrary string and does not need to have been previously defined. If
any handler explicitly returns a value that is not `nil`, `emit()` returns that value and
ceases to call subsequent handlers. This is useful for stopping the propagation of an event
like a keypress after it has been handled, or for passing back values from handlers.

Parameters:

* *`event`*: The string event name.
* *`...`*: Arguments passed to the handler.

Usage:

* `events.emit('my_event', 'my message')`

Return:

* `nil` unless any any handler explicitly returned a non-`nil` value; otherwise returns
  that value


---
<a id="io"></a>
## The `io` Module
---

Extends Lua's `io` library with Textadept functions for working with files.

### Fields defined by `io`

<a id="events.FILE_AFTER_SAVE"></a>
#### `events.FILE_AFTER_SAVE` (string)

Emitted right after saving a file to disk.
  Emitted by [`buffer:save()`](#buffer.save) and [`buffer:save_as()`](#buffer.save_as).
  Arguments:

  * _`filename`_: The filename of the file being saved.
  * _`saved_as`_: Whether or not the file was saved under a different filename.

<a id="events.FILE_BEFORE_SAVE"></a>
#### `events.FILE_BEFORE_SAVE` (string)

Emitted right before saving a file to disk.
  Emitted by [`buffer:save()`](#buffer.save).
  Arguments:

  * _`filename`_: The filename of the file being saved.

<a id="events.FILE_CHANGED"></a>
#### `events.FILE_CHANGED` (string)

Emitted when Textadept detects that an open file was modified externally.
  When connecting to this event, connect with an index of 1 in order to override the default
  prompt to reload the file.
  Arguments:

  * _`filename`_: The filename externally modified.

<a id="events.FILE_OPENED"></a>
#### `events.FILE_OPENED` (string)

Emitted after opening a file in a new buffer.
  Emitted by [`io.open_file()`](#io.open_file).
  Arguments:

  * _`filename`_: The opened file's filename.

<a id="io.quick_open_max"></a>
#### `io.quick_open_max` (number)

The maximum number of files listed in the quick open dialog.
  The default value is `1000`.


### Functions defined by `io`

<a id="io.close_all_buffers"></a>
#### `io.close_all_buffers`()

Closes all open buffers, prompting the user to continue if there are unsaved buffers, and
returns `true` if the user did not cancel.
No buffers are saved automatically. They must be saved manually.

Return:

* `true` if user did not cancel; `nil` otherwise.

See also:

* [`buffer.close`](#buffer.close)

<a id="io.get_project_root"></a>
#### `io.get_project_root`(*path, submodule*)

Returns the root directory of the project that contains filesystem path *path*.
In order to be recognized, projects must be under version control. Recognized VCSes are
Bazaar, Fossil, Git, Mercurial, and SVN.

Parameters:

* *`path`*: Optional filesystem path to a project or a file contained within a project. The
  default value is the buffer's filename or the current working directory. This parameter
  may be omitted.
* *`submodule`*: Optional flag that indicates whether or not to return the root of the
  current submodule (if applicable). The default value is `false`.

Return:

* string root or nil

<a id="io.open_file"></a>
#### `io.open_file`(*filenames, encodings*)

Opens *filenames*, a string filename or list of filenames, or the user-selected filename(s).
Emits a `FILE_OPENED` event.

Parameters:

* *`filenames`*: Optional string filename or table of filenames to open. If `nil`, the user
  is prompted with a fileselect dialog.
* *`encodings`*: Optional string encoding or table of encodings file contents are in (one
  encoding per file). If `nil`, encoding auto-detection is attempted via `io.encodings`.

See also:

* [`events`](#events)

<a id="io.open_recent_file"></a>
#### `io.open_recent_file`()

Prompts the user to select a recently opened file to be reopened.

See also:

* [`io.recent_files`](#io.recent_files)

<a id="io.quick_open"></a>
#### `io.quick_open`(*paths, filter, opts*)

Prompts the user to select files to be opened from *paths*, a string directory path or list
of directory paths, using a filtered list dialog.
If *paths* is `nil`, uses the current project's root directory, which is obtained from
`io.get_project_root()`.
String or list *filter* determines which files to show in the dialog, with the default
filter being `io.quick_open_filters[path]` (if it exists) or `lfs.default_filter`. A filter
consists of Lua patterns that match file and directory paths to include or exclude. Patterns
are inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are
given, any path is initially considered. As a convenience, file extensions can be specified
literally instead of as a Lua pattern (e.g. '.lua' vs. '%.lua$'), and '/' also matches the
Windows directory separator ('[/\\]' is not needed).
The number of files in the list is capped at `quick_open_max`.
If *filter* is `nil` and *paths* is ultimately a string, the filter from the
`io.quick_open_filters` table is used. If that filter does not exist, `lfs.default_filter`
is used.
*opts* is an optional table of additional options for `ui.dialogs.filteredlist()`.

Parameters:

* *`paths`*: Optional string directory path or table of directory paths to search. The
  default value is the current project's root directory, if available.
* *`filter`*: Optional filter for files and directories to include and/or exclude. The
  default value is `lfs.default_filter` unless a filter for *paths* is defined in
  `io.quick_open_filters`.
* *`opts`*: Optional table of additional options for `ui.dialogs.filteredlist()`.

Usage:

* `io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list all files in the current
  file's directory, subject to the default filter`
* `io.quick_open(io.get_current_project(), '.lua') -- list all Lua files in the current
  project`
* `io.quick_open(io.get_current_project(), '!/build') -- list all files in the current
  project except those in the build directory`

See also:

* [`io.quick_open_filters`](#io.quick_open_filters)
* [`lfs.default_filter`](#lfs.default_filter)
* [`io.quick_open_max`](#io.quick_open_max)
* [`ui.dialogs.filteredlist`](#ui.dialogs.filteredlist)

<a id="io.save_all_files"></a>
#### `io.save_all_files`()

Saves all unsaved buffers to their respective files.

See also:

* [`buffer.save`](#buffer.save)


### Tables defined by `io`

<a id="io.encodings"></a>
#### `io.encodings`

List of encodings to attempt to decode files as.
You should add to this list if you get a "Conversion failed" error when trying to open a file
whose encoding is not recognized. Valid encodings are [GNU iconv's encodings][] and include:

  * European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
    KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
    Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
    Macintosh.
  * Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
    UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.

[GNU iconv's encodings]: https://www.gnu.org/software/libiconv/

Usage:

* `io.encodings[#io.encodings + 1] = 'UTF-32'`

<a id="io.quick_open_filters"></a>
#### `io.quick_open_filters`

Map of directory paths to filters used by `io.quick_open()`.

See also:

* [`io.quick_open`](#io.quick_open)

<a id="io.recent_files"></a>
#### `io.recent_files`

List of recently opened files, the most recent being towards the top.

---
<a id="keys"></a>
## The `keys` Module
---

Manages key bindings in Textadept.

### Overview

Define key bindings in the global `keys` table in key-value pairs. Each pair consists of
either a string key sequence and its associated command, a string lexer name (from the
*lexers/* directory) with a table of key sequences and commands, a string key mode with a
table of key sequences and commands, or a key sequence with a table of more sequences and
commands. The latter is part of what is called a "key chain", to be discussed below. When
searching for a command to run based on a key sequence, Textadept considers key bindings
in the current key mode to have priority. If no key mode is active, language-specific key
bindings have priority, followed by the ones in the global table. This means if there are
two commands with the same key sequence, Textadept runs the language-specific one. However,
if the command returns the boolean value `false`, Textadept also runs the lower-priority
command. (This is useful for language modules to override commands like autocompletion,
but fall back to word autocompletion if the first command fails.)

### Key Sequences

Key sequences are strings built from an ordered combination of modifier keys and the key's
inserted character. Modifier keys are "Control", "Shift", and "Alt" on Windows, Linux, BSD,
and in the terminal version. On macOS they are "Control" (`^`), "Alt/Option" (`⌥`), "Command"
(`⌘`), and "Shift" (`⇧`). These modifiers have the following string representations:

Modifier |  Linux / Win32 | macOS | Terminal
-|-|-|-
Control | `'ctrl'` | `'ctrl'` | `'ctrl'`
Alt | `'alt'` | `'alt'` | `'meta'`
Command | N/A | `'cmd'` | N/A
Shift | `'shift'` | `'shift'` | `'shift'`

The string representation of key values less than 255 is the character that Textadept would
normally insert if the "Control", "Alt", and "Command" modifiers were not held down. Therefore,
a combination of `Ctrl+Alt+Shift+A` has the key sequence `ctrl+alt+A` on Windows and Linux,
but a combination of `Ctrl+Shift+Tab` has the key sequence `ctrl+shift+\t`. On a United States
English keyboard, since the combination of `Ctrl+Shift+,` has the key sequence `ctrl+<`
(`Shift+,` inserts a `<`), Textadept recognizes the key binding as `Ctrl+<`. This allows
key bindings to be language and layout agnostic. For key values greater than 255, Textadept
uses the [`keys.KEYSYMS`](#keys.KEYSYMS) lookup table. Therefore, `Ctrl+Right Arrow` has the key sequence
`ctrl+right`. Uncommenting the `print()` statements in *core/keys.lua* causes Textadept to
print key sequences to standard out (stdout) for inspection.

### Commands

A command bound to a key sequence is simply a Lua function. For example:

    keys['ctrl+n'] = buffer.new
    keys['ctrl+z'] = buffer.undo
    keys['ctrl+u'] = function() io.quick_open(_USERHOME) end

Textadept handles [`buffer`](#buffer) references properly in static contexts.

### Modes

Modes are groups of key bindings such that when a key [mode](#keys.mode) is active, Textadept
ignores all key bindings defined outside the mode until the mode is unset. Here is a simple
vi mode example:

    keys.command_mode = {
      ['h'] = buffer.char_left,
      ['j'] = buffer.line_up,
      ['k'] = buffer.line_down,
      ['l'] = buffer.char_right,
      ['i'] = function()
        keys.mode = nil
        ui.statusbar_text = 'INSERT MODE'
      end
    }
    keys['esc'] = function() keys.mode = 'command_mode' end
    events.connect(events.UPDATE_UI, function()
      if keys.mode == 'command_mode' then return end
      ui.statusbar_text = 'INSERT MODE'
    end)
    keys.mode = 'command_mode' -- default mode

**Warning**: When creating a mode, be sure to define a way to exit the mode, otherwise you
will probably have to restart Textadept.

### Key Chains

Key chains are a powerful concept. They allow you to assign multiple key bindings to one
key sequence. By default, the `Esc` key cancels a key chain, but you can redefine it via
[`keys.CLEAR`](#keys.CLEAR). An example key chain looks like:

    keys['alt+a'] = {
      a = function1,
      b = function2,
      c = {...}
    }

### Fields defined by `keys`

<a id="keys.CLEAR"></a>
#### `keys.CLEAR` (string)

The key that clears the current key chain.
  It cannot be part of a key chain.
  The default value is `'esc'` for the `Esc` key.

<a id="keys.mode"></a>
#### `keys.mode` (string)

The current key mode.
  When non-`nil`, all key bindings defined outside of `keys[mode]` are ignored.
  The default value is `nil`.


### Tables defined by `keys`

<a id="keys.KEYSYMS"></a>
#### `keys.KEYSYMS`

Lookup table for string representations of key codes higher than 255.
Key codes can be identified by temporarily uncommenting the `print()` statements in
*core/keys.lua*.
Recognized codes are: esc, \b, \t, \n, down, up, left, right, home, end, pgup, pgdn, del,
ins, and f1-f12.
The GUI version also recognizes: menu, kpenter, kphome, kpend, kpleft, kpup, kpright, kpdown,
kppgup, kppgdn, kpmul, kpadd, kpsub, kpdiv, kpdec, and kp0-kp9.

<a id="_G.keys"></a>
#### `_G.keys`

Map of key bindings to commands, with language-specific key tables assigned to a lexer name key.

<a id="keys.keychain"></a>
#### `keys.keychain`

The current chain of key sequences. (Read-only.)

---
<a id="lexer"></a>
## The `lexer` Module
---

Lexes Scintilla documents and source code with Lua and LPeg.

### Writing Lua Lexers

Lexers highlight the syntax of source code. Scintilla (the editing component behind
[Textadept][] and [SciTE][]) traditionally uses static, compiled C++ lexers which are
notoriously difficult to create and/or extend. On the other hand, Lua makes it easy to to
rapidly create new lexers, extend existing ones, and embed lexers within one another. Lua
lexers tend to be more readable than C++ lexers too.

Lexers are Parsing Expression Grammars, or PEGs, composed with the Lua [LPeg library][]. The
following table comes from the LPeg documentation and summarizes all you need to know about
constructing basic LPeg patterns. This module provides convenience functions for creating
and working with other more advanced patterns and concepts.

Operator | Description
-|-
`lpeg.P(string)` | Matches `string` literally.
`lpeg.P(`_`n`_`)` | Matches exactly _`n`_ number of characters.
`lpeg.S(string)` | Matches any character in set `string`.
`lpeg.R("`_`xy`_`")`| Matches any character between range `x` and `y`.
`patt^`_`n`_ | Matches at least _`n`_ repetitions of `patt`.
`patt^-`_`n`_ | Matches at most _`n`_ repetitions of `patt`.
`patt1 * patt2` | Matches `patt1` followed by `patt2`.
`patt1 + patt2` | Matches `patt1` or `patt2` (ordered choice).
`patt1 - patt2` | Matches `patt1` if `patt2` does not also match.
`-patt` | Equivalent to `("" - patt)`.
`#patt` | Matches `patt` but consumes no input.

The first part of this document deals with rapidly constructing a simple lexer. The next part
deals with more advanced techniques, such as custom coloring and embedding lexers within one
another. Following that is a discussion about code folding, or being able to tell Scintilla
which code blocks are "foldable" (temporarily hideable from view). After that are instructions
on how to use Lua lexers with the aforementioned Textadept and SciTE editors. Finally there
are comments on lexer performance and limitations.

[LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Textadept]: https://orbitalquark.github.io/textadept
[SciTE]: https://scintilla.org/SciTE.html

### Lexer Basics

The *lexers/* directory contains all lexers, including your new one. Before attempting to
write one from scratch though, first determine if your programming language is similar to
any of the 100+ languages supported. If so, you may be able to copy and modify that lexer,
saving some time and effort. The filename of your lexer should be the name of your programming
language in lower case followed by a *.lua* extension. For example, a new Lua lexer has the
name *lua.lua*.

Note: Try to refrain from using one-character language names like "c", "d", or "r". For
example, Scintillua uses "ansi_c", "dmd", and "rstats", respectively.

#### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a new lexer. Feel
free to use it, replacing the '?'s with the name of your lexer. Consider this snippet from
the template:

    -- ? LPeg lexer.

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('?')

    -- Whitespace.
    local ws = token(lexer.WHITESPACE, lexer.space^1)
    lex:add_rule('whitespace', ws)

    [...]

    return lex

The first 3 lines of code simply define often used convenience variables. The fourth and
last lines [define](#lexer.new) and return the lexer object Scintilla uses; they are very
important and must be part of every lexer. The fifth line defines something called a "token",
an essential building block of lexers. You will learn about tokens shortly. The sixth line
defines a lexer grammar rule, which you will learn about later, as well as token styles. (Be
aware that it is common practice to combine these two lines for short rules.)  Note, however,
the `local` prefix in front of variables, which is needed so-as not to affect Lua's global
environment. All in all, this is a minimal, working lexer that you can build on.

#### Tokens

Take a moment to think about your programming language's structure. What kind of key
elements does it have? In the template shown earlier, one predefined element all languages
have is whitespace. Your language probably also has elements like comments, strings, and
keywords. Lexers refer to these elements as "tokens". Tokens are the fundamental "building
blocks" of lexers. Lexers break down source code into tokens for coloring, which results
in the syntax highlighting familiar to you. It is up to you how specific your lexer is
when it comes to tokens. Perhaps only distinguishing between keywords and identifiers is
necessary, or maybe recognizing constants and built-in functions, methods, or libraries is
desirable. The Lua lexer, for example, defines 11 tokens: whitespace, keywords, built-in
functions, constants, built-in libraries, identifiers, strings, comments, numbers, labels,
and operators. Even though constants, built-in functions, and built-in libraries are subsets
of identifiers, Lua programmers find it helpful for the lexer to distinguish between them
all. It is perfectly acceptable to just recognize keywords and identifiers.

In a lexer, tokens consist of a token name and an LPeg pattern that matches a sequence of
characters recognized as an instance of that token. Create tokens using the [`lexer.token()`](#lexer.token)
function. Let us examine the "whitespace" token defined in the template shown earlier:

    local ws = token(lexer.WHITESPACE, lexer.space^1)

At first glance, the first argument does not appear to be a string name and the second
argument does not appear to be an LPeg pattern. Perhaps you expected something like:

    local ws = token('whitespace', S('\t\v\f\n\r ')^1)

The `lexer` module actually provides a convenient list of common token names and common LPeg
patterns for you to use. Token names include [`lexer.DEFAULT`](#lexer.DEFAULT), [`lexer.WHITESPACE`](#lexer.WHITESPACE),
[`lexer.COMMENT`](#lexer.COMMENT), [`lexer.STRING`](#lexer.STRING), [`lexer.NUMBER`](#lexer.NUMBER), [`lexer.KEYWORD`](#lexer.KEYWORD),
[`lexer.IDENTIFIER`](#lexer.IDENTIFIER), [`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.ERROR`](#lexer.ERROR), [`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR),
[`lexer.CONSTANT`](#lexer.CONSTANT), [`lexer.VARIABLE`](#lexer.VARIABLE), [`lexer.FUNCTION`](#lexer.FUNCTION), [`lexer.CLASS`](#lexer.CLASS),
[`lexer.TYPE`](#lexer.TYPE), [`lexer.LABEL`](#lexer.LABEL), [`lexer.REGEX`](#lexer.REGEX), and [`lexer.EMBEDDED`](#lexer.EMBEDDED). Patterns
include [`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum),
[`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph), [`lexer.print`](#lexer.print),
[`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space), [`lexer.newline`](#lexer.newline), [`lexer.nonnewline`](#lexer.nonnewline),
[`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num), [`lexer.integer`](#lexer.integer),
[`lexer.float`](#lexer.float), [`lexer.number`](#lexer.number), and [`lexer.word`](#lexer.word). You may use your own token names
if none of the above fit your language, but an advantage to using predefined token names is
that your lexer's tokens will inherit the universal syntax highlighting color theme used by
your text editor.

##### Example Tokens

So, how might you define other tokens like keywords, comments, and strings?  Here are some
examples.

**Keywords**

Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered choices, use another
convenience function: [`lexer.word_match()`](#lexer.word_match). It is much easier and more efficient to
write word matches like:

    local keyword = token(lexer.KEYWORD, lexer.word_match{
      'keyword_1', 'keyword_2', ..., 'keyword_n'
    })

    local case_insensitive_keyword = token(lexer.KEYWORD, lexer.word_match({
      'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
    }, true))

    local hyphened_keyword = token(lexer.KEYWORD, lexer.word_match{
      'keyword-1', 'keyword-2', ..., 'keyword-n'
    })

For short keyword lists, you can use a single string of words. For example:

    local keyword = token(lexer.KEYWORD, lexer.word_match('key_1 key_2 ... key_n'))

**Comments**

Line-style comments with a prefix character(s) are easy to express with LPeg:

    local shell_comment = token(lexer.COMMENT, lexer.to_eol('#'))
    local c_line_comment = token(lexer.COMMENT, lexer.to_eol('//', true))

The comments above start with a '#' or "//" and go to the end of the line. The second comment
recognizes the next line also as a comment if the current line ends with a '\' escape character.

C-style "block" comments with a start and end delimiter are also easy to express:

    local c_comment = token(lexer.COMMENT, lexer.range('/*', '*/'))

This comment starts with a "/\*" sequence and contains anything up to and including an ending
"\*/" sequence. The ending "\*/" is optional so the lexer can recognize unfinished comments
as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a sequence like
"\\&quot;" in a double-quoted string indicates that the '&quot;' is not the end of the
string. [`lexer.range()`](#lexer.range) handles escapes inherently.

    local dq_str = lexer.range('"')
    local sq_str = lexer.range("'")
    local string = token(lexer.STRING, dq_str + sq_str)

In this case, the lexer treats '\' as an escape character in a string sequence.

**Numbers**

Most programming languages have the same format for integer and float tokens, so it might
be as simple as using a predefined LPeg pattern:

    local number = token(lexer.NUMBER, lexer.number)

However, some languages allow postfix characters on integers.

    local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
    local number = token(lexer.NUMBER, lexer.float + lexer.hex_num + integer)

Your language may need other tweaks, but it is up to you how fine-grained you want your
highlighting to be. After all, you are not writing a compiler or interpreter!

#### Rules

Programming languages have grammars, which specify valid token structure. For example,
comments usually cannot appear within a string. Grammars consist of rules, which are simply
combinations of tokens. Recall from the lexer template the [`lexer.add_rule()`](#lexer.add_rule) call,
which adds a rule to the lexer's grammar:

    lex:add_rule('whitespace', ws)

Each rule has an associated name, but rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if text does not
match the first rule added to the grammar, the lexer tries to match the second rule added, and
so on. Right now this lexer simply matches whitespace tokens under a rule named "whitespace".

To illustrate the importance of rule order, here is an example of a simplified Lua lexer:

    lex:add_rule('whitespace', token(lexer.WHITESPACE, ...))
    lex:add_rule('keyword', token(lexer.KEYWORD, ...))
    lex:add_rule('identifier', token(lexer.IDENTIFIER, ...))
    lex:add_rule('string', token(lexer.STRING, ...))
    lex:add_rule('comment', token(lexer.COMMENT, ...))
    lex:add_rule('number', token(lexer.NUMBER, ...))
    lex:add_rule('label', token(lexer.LABEL, ...))
    lex:add_rule('operator', token(lexer.OPERATOR, ...))

Note how identifiers come after keywords. In Lua, as with most programming languages,
the characters allowed in keywords and identifiers are in the same set (alphanumerics
plus underscores). If the lexer added the "identifier" rule before the "keyword" rule,
all keywords would match identifiers and thus incorrectly highlight as identifiers instead
of keywords. The same idea applies to function, constant, etc. tokens that you may want to
distinguish between: their rules should come before identifiers.

So what about text that does not match any rules? For example in Lua, the '!'  character is
meaningless outside a string or comment. Normally the lexer skips over such text. If instead
you want to highlight these "syntax errors", add an additional end rule:

    lex:add_rule('whitespace', ws)
    ...
    lex:add_rule('error', token(lexer.ERROR, lexer.any))

This identifies and highlights any character not matched by an existing rule as a `lexer.ERROR`
token.

Even though the rules defined in the examples above contain a single token, rules may
consist of multiple tokens. For example, a rule for an HTML tag could consist of a tag token
followed by an arbitrary number of attribute tokens, allowing the lexer to highlight all
tokens separately. That rule might look something like this:

    lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)

Note however that lexers with complex rules like these are more prone to lose track of their
state, especially if they span multiple lines.

#### Summary

Lexers primarily consist of tokens and grammar rules. At your disposal are a number of
convenience patterns and functions for rapidly creating a lexer. If you choose to use
predefined token names for your tokens, you do not have to define how the lexer highlights
them. The tokens will inherit the default syntax highlighting color theme your editor uses.

### Advanced Techniques

#### Styles and Styling

The most basic form of syntax highlighting is assigning different colors to different
tokens. Instead of highlighting with just colors, Scintilla allows for more rich highlighting,
or "styling", with different fonts, font sizes, font attributes, and foreground and background
colors, just to name a few. The unit of this rich highlighting is called a "style". Styles
are simply Lua tables of properties. By default, lexers associate predefined token names like
`lexer.WHITESPACE`, `lexer.COMMENT`, `lexer.STRING`, etc. with particular styles as part
of a universal color theme. These predefined styles are contained in [`lexer.styles`](#lexer.styles),
and you may define your own styles. See that table's documentation for more information. As
with token names, LPeg patterns, and styles, there is a set of predefined color names,
but they vary depending on the current color theme in use. Therefore, it is generally not
a good idea to manually define colors within styles in your lexer since they might not fit
into a user's chosen color theme. Try to refrain from even using predefined colors in a
style because that color may be theme-specific. Instead, the best practice is to either use
predefined styles or derive new color-agnostic styles from predefined ones. For example, Lua
"longstring" tokens use the existing `lexer.styles.string` style instead of defining a new one.

##### Example Styles

Defining styles is pretty straightforward. An empty style that inherits the default theme
settings is simply an empty table:

    local style_nothing = {}

A similar style but with a bold font face looks like this:

    local style_bold = {bold = true}

You can derive new styles from predefined ones without having to rewrite them. This operation
leaves the old style unchanged. For example, if you had a "static variable" token whose
style you wanted to base off of `lexer.styles.variable`, it would probably look like:

    local style_static_var = lexer.styles.variable .. {italics = true}

The color theme files in the *lexers/themes/* folder give more examples of style definitions.

#### Token Styles

Lexers use the [`lexer.add_style()`](#lexer.add_style) function to assign styles to particular tokens. Recall
the token definition and from the lexer template:

    local ws = token(lexer.WHITESPACE, lexer.space^1)
    lex:add_rule('whitespace', ws)

Why is a style not assigned to the `lexer.WHITESPACE` token? As mentioned earlier, lexers
automatically associate tokens that use predefined token names with a particular style. Only
tokens with custom token names need manual style associations. As an example, consider a
custom whitespace token:

    local ws = token('custom_whitespace', lexer.space^1)

Assigning a style to this token looks like:

    lex:add_style('custom_whitespace', lexer.styles.whitespace)

Do not confuse token names with rule names. They are completely different entities. In the
example above, the lexer associates the "custom_whitespace" token with the existing style
for `lexer.WHITESPACE` tokens. If instead you prefer to color the background of whitespace
a shade of grey, it might look like:

    lex:add_style('custom_whitespace', lexer.styles.whitespace .. {back = lexer.colors.grey})

Remember to refrain from assigning specific colors in styles, but in this case, all user
color themes probably define `colors.grey`.

#### Line Lexers

By default, lexers match the arbitrary chunks of text passed to them by Scintilla. These
chunks may be a full document, only the visible part of a document, or even just portions
of lines. Some lexers need to match whole lines. For example, a lexer for the output of a
file "diff" needs to know if the line started with a '+' or '-' and then style the entire
line accordingly. To indicate that your lexer matches by line, create the lexer with an
extra parameter:

    local lex = lexer.new('?', {lex_by_line = true})

Now the input text for the lexer is a single line at a time. Keep in mind that line lexers
do not have the ability to look ahead at subsequent lines.

#### Embedded Lexers

Lexers embed within one another very easily, requiring minimal effort. In the following
sections, the lexer being embedded is called the "child" lexer and the lexer a child is
being embedded in is called the "parent". For example, consider an HTML lexer and a CSS
lexer. Either lexer stands alone for styling their respective HTML and CSS files. However, CSS
can be embedded inside HTML. In this specific case, the CSS lexer is the "child" lexer with
the HTML lexer being the "parent". Now consider an HTML lexer and a PHP lexer. This sounds
a lot like the case with CSS, but there is a subtle difference: PHP _embeds itself into_
HTML while CSS is _embedded in_ HTML. This fundamental difference results in two types of
embedded lexers: a parent lexer that embeds other child lexers in it (like HTML embedding CSS),
and a child lexer that embeds itself into a parent lexer (like PHP embedding itself in HTML).

##### Parent Lexer

Before embedding a child lexer into a parent lexer, the parent lexer needs to load the child
lexer. This is done with the [`lexer.load()`](#lexer.load) function. For example, loading the CSS lexer
within the HTML lexer looks like:

    local css = lexer.load('css')

The next part of the embedding process is telling the parent lexer when to switch over
to the child lexer and when to switch back. The lexer refers to these indications as the
"start rule" and "end rule", respectively, and are just LPeg patterns. Continuing with the
HTML/CSS example, the transition from HTML to CSS is when the lexer encounters a "style"
tag with a "type" attribute whose value is "text/css":

    local css_tag = P('<style') * P(function(input, index)
      if input:find('^[^>]+type="text/css"', index) then return index end
    end)

This pattern looks for the beginning of a "style" tag and searches its attribute list for
the text "`type="text/css"`". (In this simplified example, the Lua pattern does not consider
whitespace between the '=' nor does it consider that using single quotes is valid.) If there
is a match, the functional pattern returns a value instead of `nil`. In this case, the value
returned does not matter because we ultimately want to style the "style" tag as an HTML tag,
so the actual start rule looks like this:

    local css_start_rule = #css_tag * tag

Now that the parent knows when to switch to the child, it needs to know when to switch
back. In the case of HTML/CSS, the switch back occurs when the lexer encounters an ending
"style" tag, though the lexer should still style the tag as an HTML tag:

    local css_end_rule = #P('</style>') * tag

Once the parent loads the child lexer and defines the child's start and end rules, it embeds
the child with the [`lexer.embed()`](#lexer.embed) function:

    lex:embed(css, css_start_rule, css_end_rule)

##### Child Lexer

The process for instructing a child lexer to embed itself into a parent is very similar to
embedding a child into a parent: first, load the parent lexer into the child lexer with the
[`lexer.load()`](#lexer.load) function and then create start and end rules for the child lexer. However,
in this case, call [`lexer.embed()`](#lexer.embed) with switched arguments. For example, in the PHP lexer:

    local html = lexer.load('html')
    local php_start_rule = token('php_tag', '<?php ')
    local php_end_rule = token('php_tag', '?>')
    lex:add_style('php_tag', lexer.styles.embedded)
    html:embed(lex, php_start_rule, php_end_rule)

#### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of text in a
document. However, there may be rare cases where a lexer does need to keep track of some
sort of persistent state. Rather than using `lpeg.P` function patterns that set state
variables, it is recommended to make use of Scintilla's built-in, per-line state integers via
[`lexer.line_state`](#lexer.line_state). It was designed to accommodate up to 32 bit flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given to an `lpeg.P`
function pattern. (Any positions derived from that position argument will also work.)

Writing stateful lexers is beyond the scope of this document.

### Code Folding

When reading source code, it is occasionally helpful to temporarily hide blocks of code like
functions, classes, comments, etc. This is the concept of "folding". In the Textadept and
SciTE editors for example, little indicators in the editor margins appear next to code that
can be folded at places called "fold points". When the user clicks an indicator, the editor
hides the code associated with the indicator until the user clicks the indicator again. The
lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences. Examples of
fold keywords are "if" and "end" in Lua and examples of fold character sequences are '{',
'}', "/\*", and "\*/" in C for code block and comment delimiters, respectively. However,
these fold points cannot occur just anywhere. For example, lexers should not recognize fold
keywords that appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function
allows you to conveniently define fold points with such granularity. For example, consider C:

    lex:add_fold_point(lexer.OPERATOR, '{', '}')
    lex:add_fold_point(lexer.COMMENT, '/*', '*/')

The first assignment states that any '{' or '}' that the lexer recognized as an `lexer.OPERATOR`
token is a fold point. Likewise, the second assignment states that any "/\*" or "\*/" that
the lexer recognizes as part of a `lexer.COMMENT` token is a fold point. The lexer does
not consider any occurrences of these characters outside their defined tokens (such as in
a string) as fold points. How do you specify fold keywords? Here is an example for Lua:

    lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and specify keywords in
lower case.

If your lexer needs to do some additional processing in order to determine if a token is
a fold point, pass a function that returns an integer to `lex:add_fold_point()`. Returning
`1` indicates the token is a beginning fold point and returning `-1` indicates the token is
an ending fold point. Returning `0` indicates the token is not a fold point. For example:

    local function fold_strange_token(text, pos, line, s, symbol)
      if ... then
        return 1 -- beginning fold point
      elseif ... then
        return -1 -- ending fold point
      end
      return 0
    end

    lex:add_fold_point('strange_token', '|', fold_strange_token)

Any time the lexer encounters a '|' that is a "strange_token", it calls the `fold_strange_token`
function to determine if '|' is a fold point. The lexer calls these functions with the
following arguments: the text to identify fold points in, the beginning position of the
current line in the text to fold, the current line's text, the position in the current line
the fold point text starts at, and the fold point text itself.

#### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate fold points. If
your lexer falls into this category and you would like to mark fold points based on changes
in indentation, create the lexer with a `fold_by_indentation = true` option:

    local lex = lexer.new('?', {fold_by_indentation = true})

### Using Lexers

**Textadept**

Put your lexer in your *~/.textadept/lexers/* directory so you do not overwrite it when
upgrading Textadept. Also, lexers in this directory override default lexers. Thus, Textadept
loads a user *lua* lexer instead of the default *lua* lexer. This is convenient for tweaking
a default lexer to your liking. Then add a [file type](#textadept.file_types) for your lexer
if necessary.

**SciTE**

Create a *.properties* file for your lexer and `import` it in either your *SciTEUser.properties*
or *SciTEGlobal.properties*. The contents of the *.properties* file should contain:

    file.patterns.[lexer_name]=[file_patterns]
    lexer.$(file.patterns.[lexer_name])=[lexer_name]

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension) and
`[file_patterns]` is a set of file extensions to use your lexer for.

Please note that Lua lexers ignore any styling information in *.properties* files. Your
theme file in the *lexers/themes/* directory contains styling information.

### Migrating Legacy Lexers

Legacy lexers are of the form:

    local l = require('lexer')
    local token, word_match = l.token, l.word_match
    local P, R, S = lpeg.P, lpeg.R, lpeg.S

    local M = {_NAME = '?'}

    [... token and pattern definitions ...]

    M._rules = {
      {'rule', pattern},
      [...]
    }

    M._tokenstyles = {
      'token' = 'style',
      [...]
    }

    M._foldsymbols = {
      _patterns = {...},
      ['token'] = {['start'] = 1, ['end'] = -1},
      [...]
    }

    return M

While Scintillua will handle such legacy lexers just fine without any changes, it is
recommended that you migrate yours. The migration process is fairly straightforward:

1. Replace all instances of `l` with `lexer`, as it's better practice and results in less
   confusion.
2. Replace `local M = {_NAME = '?'}` with `local lex = lexer.new('?')`, where `?` is the
   name of your legacy lexer. At the end of the lexer, change `return M` to `return lex`.
3. Instead of defining rules towards the end of your lexer, define your rules as you define
   your tokens and patterns using [`lex:add_rule()`](#lexer.add_rule).
4. Similarly, any custom token names should have their styles immediately defined using
   [`lex:add_style()`](#lexer.add_style).
5. Optionally convert any table arguments passed to [`lexer.word_match()`](#lexer.word_match) to a
   space-separated string of words.
6. Replace any calls to `lexer.embed(M, child, ...)` and `lexer.embed(parent, M, ...)` with
   [`lex:embed`](#lexer.embed)`(child, ...)` and `parent:embed(lex, ...)`, respectively.
7. Define fold points with simple calls to [`lex:add_fold_point()`](#lexer.add_fold_point). No
   need to mess with Lua patterns anymore.
8. Any legacy lexer options such as `M._FOLDBYINDENTATION`, `M._LEXBYLINE`, `M._lexer`,
   etc. should be added as table options to [`lexer.new()`](#lexer.new).
9. Any external lexer rule fetching and/or modifications via `lexer._RULES` should be changed
   to use [`lexer.get_rule()`](#lexer.get_rule) and [`lexer.modify_rule()`](#lexer.modify_rule).

As an example, consider the following sample legacy lexer:

    local l = require('lexer')
    local token, word_match = l.token, l.word_match
    local P, R, S = lpeg.P, lpeg.R, lpeg.S

    local M = {_NAME = 'legacy'}

    local ws = token(l.WHITESPACE, l.space^1)
    local comment = token(l.COMMENT, '#' * l.nonnewline^0)
    local string = token(l.STRING, l.delimited_range('"'))
    local number = token(l.NUMBER, l.float + l.integer)
    local keyword = token(l.KEYWORD, word_match{'foo', 'bar', 'baz'})
    local custom = token('custom', P('quux'))
    local identifier = token(l.IDENTIFIER, l.word)
    local operator = token(l.OPERATOR, S('+-*/%^=<>,.()[]{}'))

    M._rules = {
      {'whitespace', ws},
      {'keyword', keyword},
      {'custom', custom},
      {'identifier', identifier},
      {'string', string},
      {'comment', comment},
      {'number', number},
      {'operator', operator}
    }

    M._tokenstyles = {
      'custom' = l.STYLE_KEYWORD .. ',bold'
    }

    M._foldsymbols = {
      _patterns = {'[{}]'},
      [l.OPERATOR] = {['{'] = 1, ['}'] = -1}
    }

    return M

Following the migration steps would yield:

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('legacy')

    lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))
    lex:add_rule('keyword', token(lexer.KEYWORD, word_match('foo bar baz')))
    lex:add_rule('custom', token('custom', 'quux'))
    lex:add_style('custom', lexer.styles.keyword .. {bold = true})
    lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))
    lex:add_rule('string', token(lexer.STRING, lexer.range('"')))
    lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#')))
    lex:add_rule('number', token(lexer.NUMBER, lexer.number))
    lex:add_rule('operator', token(lexer.OPERATOR, S('+-*/%^=<>,.()[]{}')))

    lex:add_fold_point(lexer.OPERATOR, '{', '}')

    return lex

### Considerations

#### Performance

There might be some slight overhead when initializing a lexer, but loading a file from disk
into Scintilla is usually more expensive. On modern computer systems, I see no difference in
speed between Lua lexers and Scintilla's C++ ones. Optimize lexers for speed by re-arranging
`lexer.add_rule()` calls so that the most common rules match first. Do keep in mind that
order matters for similar rules.

In some cases, folding may be far more expensive than lexing, particularly in lexers with a
lot of potential fold points. If your lexer is exhibiting signs of slowness, try disabling
folding in your text editor first. If that speeds things up, you can try reducing the number
of fold points you added, overriding `lexer.fold()` with your own implementation, or simply
eliminating folding support from your lexer.

#### Limitations

Embedded preprocessor languages like PHP cannot completely embed in their parent languages
in that the parent's tokens do not support start and end rules. This mostly goes unnoticed,
but code like

    <div id="<?php echo $id; ?>">

will not style correctly.

#### Troubleshooting

Errors in lexers can be tricky to debug. Lexers print Lua errors to `io.stderr` and `_G.print()`
statements to `io.stdout`. Running your editor from a terminal is the easiest way to see
errors as they occur.

#### Risks

Poorly written lexers have the ability to crash Scintilla (and thus its containing application),
so unsaved data might be lost. However, I have only observed these crashes in early lexer
development, when syntax errors or pattern errors are present. Once the lexer actually starts
styling text (either correctly or incorrectly, it does not matter), I have not observed
any crashes.

#### Acknowledgements

Thanks to Peter Odding for his [lexer post][] on the Lua mailing list that provided inspiration,
and thanks to Roberto Ierusalimschy for LPeg.

[lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

### Fields defined by `lexer`

<a id="lexer.CLASS"></a>
#### `lexer.CLASS` (string)

The token name for class tokens.

<a id="lexer.COMMENT"></a>
#### `lexer.COMMENT` (string)

The token name for comment tokens.

<a id="lexer.CONSTANT"></a>
#### `lexer.CONSTANT` (string)

The token name for constant tokens.

<a id="lexer.DEFAULT"></a>
#### `lexer.DEFAULT` (string)

The token name for default tokens.

<a id="lexer.ERROR"></a>
#### `lexer.ERROR` (string)

The token name for error tokens.

<a id="lexer.FOLD_BASE"></a>
#### `lexer.FOLD_BASE` (number)

The initial (root) fold level.

<a id="lexer.FOLD_BLANK"></a>
#### `lexer.FOLD_BLANK` (number)

Flag indicating that the line is blank.

<a id="lexer.FOLD_HEADER"></a>
#### `lexer.FOLD_HEADER` (number)

Flag indicating the line is fold point.

<a id="lexer.FUNCTION"></a>
#### `lexer.FUNCTION` (string)

The token name for function tokens.

<a id="lexer.IDENTIFIER"></a>
#### `lexer.IDENTIFIER` (string)

The token name for identifier tokens.

<a id="lexer.KEYWORD"></a>
#### `lexer.KEYWORD` (string)

The token name for keyword tokens.

<a id="lexer.LABEL"></a>
#### `lexer.LABEL` (string)

The token name for label tokens.

<a id="lexer.NUMBER"></a>
#### `lexer.NUMBER` (string)

The token name for number tokens.

<a id="lexer.OPERATOR"></a>
#### `lexer.OPERATOR` (string)

The token name for operator tokens.

<a id="lexer.PREPROCESSOR"></a>
#### `lexer.PREPROCESSOR` (string)

The token name for preprocessor tokens.

<a id="lexer.REGEX"></a>
#### `lexer.REGEX` (string)

The token name for regex tokens.

<a id="lexer.STRING"></a>
#### `lexer.STRING` (string)

The token name for string tokens.

<a id="lexer.TYPE"></a>
#### `lexer.TYPE` (string)

The token name for type tokens.

<a id="lexer.VARIABLE"></a>
#### `lexer.VARIABLE` (string)

The token name for variable tokens.

<a id="lexer.WHITESPACE"></a>
#### `lexer.WHITESPACE` (string)

The token name for whitespace tokens.

<a id="lexer.alnum"></a>
#### `lexer.alnum` (pattern)

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z', '0'-'9').

<a id="lexer.alpha"></a>
#### `lexer.alpha` (pattern)

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
#### `lexer.any` (pattern)

A pattern that matches any single character.

<a id="lexer.ascii"></a>
#### `lexer.ascii` (pattern)

A pattern that matches any ASCII character (codes 0 to 127).

<a id="lexer.cntrl"></a>
#### `lexer.cntrl` (pattern)

A pattern that matches any control character (ASCII codes 0 to 31).

<a id="lexer.dec_num"></a>
#### `lexer.dec_num` (pattern)

A pattern that matches a decimal number.

<a id="lexer.digit"></a>
#### `lexer.digit` (pattern)

A pattern that matches any digit ('0'-'9').

<a id="lexer.extend"></a>
#### `lexer.extend` (pattern)

A pattern that matches any ASCII extended character (codes 0 to 255).

<a id="lexer.float"></a>
#### `lexer.float` (pattern)

A pattern that matches a floating point number.

<a id="lexer.fold_by_indentation"></a>
#### `lexer.fold_by_indentation` (boolean)

Whether or not to fold based on indentation level if a lexer does not have
  a folder.
  Some lexers automatically enable this option. It is disabled by default.
  This is an alias for `lexer.property['fold.by.indentation'] = '1|0'`.

<a id="lexer.fold_compact"></a>
#### `lexer.fold_compact` (boolean)

Whether or not blank lines after an ending fold point are included in that
  fold.
  This option is disabled by default.
  This is an alias for `lexer.property['fold.compact'] = '1|0'`.

<a id="lexer.fold_level"></a>
#### `lexer.fold_level` (table, Read-only)

Table of fold level bit-masks for line numbers starting from 1.
  Fold level masks are composed of an integer level combined with any of the following bits:

  * `lexer.FOLD_BASE`
    The initial fold level.
  * `lexer.FOLD_BLANK`
    The line is blank.
  * `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.fold_line_groups"></a>
#### `lexer.fold_line_groups` (boolean)

Whether or not to fold multiple, consecutive line groups (such as line comments and import
  statements) and only show the top line.
  This option is disabled by default.
  This is an alias for `lexer.property['fold.line.groups'] = '1|0'`.

<a id="lexer.fold_on_zero_sum_lines"></a>
#### `lexer.fold_on_zero_sum_lines` (boolean)

Whether or not to mark as a fold point lines that contain both an ending and starting fold
  point. For example, `} else {` would be marked as a fold point.
  This option is disabled by default. This is an alias for
  `lexer.property['fold.on.zero.sum.lines'] = '1|0'`.

<a id="lexer.folding"></a>
#### `lexer.folding` (boolean)

Whether or not folding is enabled for the lexers that support it.
  This option is disabled by default.
  This is an alias for `lexer.property['fold'] = '1|0'`.

<a id="lexer.graph"></a>
#### `lexer.graph` (pattern)

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
#### `lexer.hex_num` (pattern)

A pattern that matches a hexadecimal number.

<a id="lexer.indent_amount"></a>
#### `lexer.indent_amount` (table, Read-only)

Table of indentation amounts in character columns, for line numbers starting from 1.

<a id="lexer.integer"></a>
#### `lexer.integer` (pattern)

A pattern that matches either a decimal, hexadecimal, or octal number.

<a id="lexer.line_state"></a>
#### `lexer.line_state` (table)

Table of integer line states for line numbers starting from 1.
  Line states can be used by lexers for keeping track of persistent states.

<a id="lexer.lower"></a>
#### `lexer.lower` (pattern)

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.newline"></a>
#### `lexer.newline` (pattern)

A pattern that matches a sequence of end of line characters.

<a id="lexer.nonnewline"></a>
#### `lexer.nonnewline` (pattern)

A pattern that matches any single, non-newline character.

<a id="lexer.number"></a>
#### `lexer.number` (pattern)

A pattern that matches a typical number, either a floating point, decimal, hexadecimal,
  or octal number.

<a id="lexer.oct_num"></a>
#### `lexer.oct_num` (pattern)

A pattern that matches an octal number.

<a id="lexer.print"></a>
#### `lexer.print` (pattern)

A pattern that matches any printable character (' ' to '~').

<a id="lexer.property"></a>
#### `lexer.property` (table)

Map of key-value string pairs.

<a id="lexer.property_expanded"></a>
#### `lexer.property_expanded` (table, Read-only)

Map of key-value string pairs with `$()` and `%()` variable replacement performed in values.

<a id="lexer.property_int"></a>
#### `lexer.property_int` (table, Read-only)

Map of key-value pairs with values interpreted as numbers, or `0` if not found.

<a id="lexer.punct"></a>
#### `lexer.punct` (pattern)

A pattern that matches any punctuation character ('!' to '/', ':' to '@', '[' to ''',
  '{' to '~').

<a id="lexer.space"></a>
#### `lexer.space` (pattern)

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n', '\r', space).

<a id="lexer.style_at"></a>
#### `lexer.style_at` (table, Read-only)

Table of style names at positions in the buffer starting from 1.

<a id="lexer.upper"></a>
#### `lexer.upper` (pattern)

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
#### `lexer.word` (pattern)

A pattern that matches a typical word. Words begin with a letter or underscore and consist
  of alphanumeric and underscore characters.

<a id="lexer.xdigit"></a>
#### `lexer.xdigit` (pattern)

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').


### Functions defined by `lexer`

<a id="lexer.add_fold_point"></a>
#### `lexer.add_fold_point`(*lexer, token\_name, start\_symbol, end\_symbol*)

Adds to lexer *lexer* a fold point whose beginning and end tokens are string *token_name*
tokens with string content *start_symbol* and *end_symbol*, respectively.
In the event that *start_symbol* may or may not be a fold point depending on context, and that
additional processing is required, *end_symbol* may be a function that ultimately returns
`1` (indicating a beginning fold point), `-1` (indicating an ending fold point), or `0`
(indicating no fold point). That function is passed the following arguments:

  * `text`: The text being processed for fold points.
  * `pos`: The position in *text* of the beginning of the line currently being processed.
  * `line`: The text of the line currently being processed.
  * `s`: The position of *start_symbol* in *line*.
  * `symbol`: *start_symbol* itself.

Parameters:

* *`lexer`*: The lexer to add a fold point to.
* *`token_name`*: The token name of text that indicates a fold point.
* *`start_symbol`*: The text that indicates the beginning of a fold point.
* *`end_symbol`*: Either the text that indicates the end of a fold point, or a function that
  returns whether or not *start_symbol* is a beginning fold point (1), an ending fold point
  (-1), or not a fold point at all (0).

Usage:

* `lex:add_fold_point(lexer.OPERATOR, '{', '}')`
* `lex:add_fold_point(lexer.KEYWORD, 'if', 'end')`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('#'))`
* `lex:add_fold_point('custom', function(text, pos, line, s, symbol) ... end)`

<a id="lexer.add_rule"></a>
#### `lexer.add_rule`(*lexer, id, rule*)

Adds pattern *rule* identified by string *id* to the ordered list of rules for lexer *lexer*.

Parameters:

* *`lexer`*: The lexer to add the given rule to.
* *`id`*: The id associated with this rule. It does not have to be the same as the name
  passed to `token()`.
* *`rule`*: The LPeg pattern of the rule.

See also:

* [`lexer.modify_rule`](#lexer.modify_rule)

<a id="lexer.add_style"></a>
#### `lexer.add_style`(*lexer, token\_name, style*)

Associates string *token_name* in lexer *lexer* with style table *style*.
*style* may have the following fields:

* `font`: String font name.
* `size`: Integer font size.
* `bold`: Whether or not the font face is bold. The default value is `false`.
* `weight`: Integer weight or boldness of a font, between 1 and 999.
* `italics`: Whether or not the font face is italic. The default value is `false`.
* `underlined`: Whether or not the font face is underlined. The default value is `false`.
* `fore`: Font face foreground color in `0xBBGGRR` or `"#RRGGBB"` format.
* `back`: Font face background color in `0xBBGGRR` or `"#RRGGBB"` format.
* `eolfilled`: Whether or not the background color extends to the end of the line. The
  default value is `false`.
* `case`: Font case, `'u'` for upper, `'l'` for lower, and `'m'` for normal, mixed case. The
  default value is `'m'`.
* `visible`: Whether or not the text is visible. The default value is `true`.
* `changeable`: Whether the text is changeable instead of read-only. The default value is
  `true`.

Field values may also contain "$(property.name)" expansions for properties defined in Scintilla,
theme files, etc.

Parameters:

* *`lexer`*: The lexer to add a style to.
* *`token_name`*: The name of the token to associated with the style.
* *`style`*: A style string for Scintilla.

Usage:

* `lex:add_style('longstring', lexer.styles.string)`
* `lex:add_style('deprecated_func', lexer.styles['function'] .. {italics = true}`
* `lex:add_style('visible_ws', lexer.styles.whitespace .. {back = lexer.colors.grey}`

<a id="lexer.embed"></a>
#### `lexer.embed`(*lexer, child, start\_rule, end\_rule*)

Embeds child lexer *child* in parent lexer *lexer* using patterns *start_rule* and *end_rule*,
which signal the beginning and end of the embedded lexer, respectively.

Parameters:

* *`lexer`*: The parent lexer.
* *`child`*: The child lexer.
* *`start_rule`*: The pattern that signals the beginning of the embedded lexer.
* *`end_rule`*: The pattern that signals the end of the embedded lexer.

Usage:

* `html:embed(css, css_start_rule, css_end_rule)`
* `html:embed(lex, php_start_rule, php_end_rule) -- from php lexer`

<a id="lexer.fold"></a>
#### `lexer.fold`(*lexer, text, start\_pos, start\_line, start\_level*)

Determines fold points in a chunk of text *text* using lexer *lexer*, returning a table of
fold levels associated with line numbers.
*text* starts at position *start_pos* on line number *start_line* with a beginning fold
level of *start_level* in the buffer.

Parameters:

* *`lexer`*: The lexer to fold text with.
* *`text`*: The text in the buffer to fold.
* *`start_pos`*: The position in the buffer *text* starts at, counting from 1.
* *`start_line`*: The line number *text* starts on, counting from 1.
* *`start_level`*: The fold level *text* starts on.

Return:

* table of fold levels associated with line numbers.

<a id="lexer.fold_consecutive_lines"></a>
#### `lexer.fold_consecutive_lines`(*prefix*)

Returns for `lexer.add_fold_point()` the parameters needed to fold consecutive lines that
start with string *prefix*.

Parameters:

* *`prefix`*: The prefix string (e.g. a line comment).

Usage:

* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('--'))`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))`
* `lex:add_fold_point(lexer.KEYWORD, lexer.fold_consecutive_lines('import'))`

<a id="lexer.get_rule"></a>
#### `lexer.get_rule`(*lexer, id*)

Returns the rule identified by string *id*.

Parameters:

* *`lexer`*: The lexer to fetch a rule from.
* *`id`*: The id of the rule to fetch.

Return:

* pattern

<a id="lexer.last_char_includes"></a>
#### `lexer.last_char_includes`(*s*)

Creates and returns a pattern that verifies the first non-whitespace character behind the
current match position is in string set *s*.

Parameters:

* *`s`*: String character set like one passed to `lpeg.S()`.

Usage:

* `local regex = lexer.last_char_includes('+-*!%^&|=,([{') * lexer.range('/')`

Return:

* pattern

<a id="lexer.lex"></a>
#### `lexer.lex`(*lexer, text, init\_style*)

Lexes a chunk of text *text* (that has an initial style number of *init_style*) using lexer
*lexer*, returning a table of token names and positions.

Parameters:

* *`lexer`*: The lexer to lex text with.
* *`text`*: The text in the buffer to lex.
* *`init_style`*: The current style. Multiple-language lexers use this to determine which
  language to start lexing in.

Return:

* table of token names and positions.

<a id="lexer.line_from_position"></a>
#### `lexer.line_from_position`(*pos*)

Returns the line number (starting from 1) of the line that contains position *pos*, which
starts from 1.

Parameters:

* *`pos`*: The position to get the line number of.

Return:

* number

<a id="lexer.load"></a>
#### `lexer.load`(*name, alt\_name, cache*)

Initializes or loads and returns the lexer of string name *name*.
Scintilla calls this function in order to load a lexer. Parent lexers also call this function
in order to load child lexers and vice-versa. The user calls this function in order to load
a lexer when using Scintillua as a Lua library.

Parameters:

* *`name`*: The name of the lexing language.
* *`alt_name`*: The alternate name of the lexing language. This is useful for embedding the
  same child lexer with multiple sets of start and end tokens.
* *`cache`*: Flag indicating whether or not to load lexers from the cache. This should only
  be `true` when initially loading a lexer (e.g. not from within another lexer for embedding
  purposes). The default value is `false`.

Return:

* lexer object

<a id="lexer.modify_rule"></a>
#### `lexer.modify_rule`(*lexer, id, rule*)

Replaces in lexer *lexer* the existing rule identified by string *id* with pattern *rule*.

Parameters:

* *`lexer`*: The lexer to modify.
* *`id`*: The id associated with this rule.
* *`rule`*: The LPeg pattern of the rule.

<a id="lexer.new"></a>
#### `lexer.new`(*name, opts*)

Creates a returns a new lexer with the given name.

Parameters:

* *`name`*: The lexer's name.
* *`opts`*: Table of lexer options. Options currently supported:
  * `lex_by_line`: Whether or not the lexer only processes whole lines of text (instead of
    arbitrary chunks of text) at a time. Line lexers cannot look ahead to subsequent lines.
    The default value is `false`.
  * `fold_by_indentation`: Whether or not the lexer does not define any fold points and that
    fold points should be calculated based on changes in line indentation. The default value
    is `false`.
  * `case_insensitive_fold_points`: Whether or not fold points added via
    `lexer.add_fold_point()` ignore case. The default value is `false`.
  * `inherit`: Lexer to inherit from. The default value is `nil`.

Usage:

* `lexer.new('rhtml', {inherit = lexer.load('html')})`

<a id="lexer.range"></a>
#### `lexer.range`(*s, e, single\_line, escapes, balanced*)

Creates and returns a pattern that matches a range of text bounded by strings or patterns *s*
and *e*.
This is a convenience function for matching more complicated ranges like strings with escape
characters, balanced parentheses, and block comments (nested or not). *e* is optional and
defaults to *s*. *single_line* indicates whether or not the range must be on a single line;
*escapes* indicates whether or not to allow '\' as an escape character; and *balanced*
indicates whether or not to handle balanced ranges like parentheses, and requires *s* and *e*
to be different.

Parameters:

* *`s`*: String or pattern start of a range.
* *`e`*: Optional string or pattern end of a range. The default value is *s*.
* *`single_line`*: Optional flag indicating whether or not the range must be on a single
  line. The default value is `false`.
* *`escapes`*: Optional flag indicating whether or not the range end may be escaped by a '\'
  character. The default value is `false` unless *s* and *e* are identical, single-character
  strings. In that case, the default value is `true`.
* *`balanced`*: Optional flag indicating whether or not to match a balanced range, like the
  "%b" Lua pattern. This flag only applies if *s* and *e* are different.

Usage:

* `local dq_str_escapes = lexer.range('"')`
* `local dq_str_noescapes = lexer.range('"', false, false)`
* `local unbalanced_parens = lexer.range('(', ')')`
* `local balanced_parens = lexer.range('(', ')', false, false, true)`

Return:

* pattern

<a id="lexer.starts_line"></a>
#### `lexer.starts_line`(*patt*)

Creates and returns a pattern that matches pattern *patt* only at the beginning of a line.

Parameters:

* *`patt`*: The LPeg pattern to match on the beginning of a line.

Usage:

* `local preproc = token(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#')))`

Return:

* pattern

<a id="lexer.to_eol"></a>
#### `lexer.to_eol`(*prefix, escape*)

Creates and returns a pattern that matches from string or pattern *prefix* until the end of
the line.
*escape* indicates whether the end of the line can be escaped with a '\' character.

Parameters:

* *`prefix`*: String or pattern prefix to start matching at.
* *`escape`*: Optional flag indicating whether or not newlines can be escaped by a '\'
 character. The default value is `false`.

Usage:

* `local line_comment = lexer.to_eol('//')`
* `local line_comment = lexer.to_eol(S('#;'))`

Return:

* pattern

<a id="lexer.token"></a>
#### `lexer.token`(*name, patt*)

Creates and returns a token pattern with token name *name* and pattern *patt*.
If *name* is not a predefined token name, its style must be defined via `lexer.add_style()`.

Parameters:

* *`name`*: The name of token. If this name is not a predefined token name, then a style
  needs to be assiciated with it via `lexer.add_style()`.
* *`patt`*: The LPeg pattern associated with the token.

Usage:

* `local ws = token(lexer.WHITESPACE, lexer.space^1)`
* `local annotation = token('annotation', '@' * lexer.word)`

Return:

* pattern

<a id="lexer.word_match"></a>
#### `lexer.word_match`(*word\_list, case\_insensitive, word\_chars*)

Creates and returns a pattern that matches any single word in list or string *words*.
*case_insensitive* indicates whether or not to ignore case when matching words.
This is a convenience function for simplifying a set of ordered choice word patterns.

Parameters:

* *`word_list`*: A list of words or a string list of words separated by spaces.
* *`case_insensitive`*: Optional boolean flag indicating whether or not the word match is
  case-insensitive. The default value is `false`.
* *`word_chars`*: Unused legacy parameter.

Usage:

* `local keyword = token(lexer.KEYWORD, word_match{'foo', 'bar', 'baz'})`
* `local keyword = token(lexer.KEYWORD, word_match({'foo-bar', 'foo-baz', 'bar-foo',
  'bar-baz', 'baz-foo', 'baz-bar'}, true))`
* `local keyword = token(lexer.KEYWORD, word_match('foo bar baz'))`

Return:

* pattern


### Tables defined by `lexer`

<a id="lexer.colors"></a>
#### `lexer.colors`

Map of color name strings to color values in `0xBBGGRR` or `"#RRGGBB"` format.
Note: for applications running within a terminal emulator, only 16 color values are recognized,
regardless of how many colors a user's terminal actually supports. (A terminal emulator's
settings determines how to actually display these recognized color values, which may end up
being mapped to a completely different color set.) In order to use the light variant of a
color, some terminals require a style's `bold` attribute must be set along with that normal
color. Recognized color values are black (0x000000), red (0x000080), green (0x008000), yellow
(0x008080), blue (0x800000), magenta (0x800080), cyan (0x808000), white (0xC0C0C0), light black
(0x404040), light red (0x0000FF), light green (0x00FF00), light yellow (0x00FFFF), light blue
(0xFF0000), light magenta (0xFF00FF), light cyan (0xFFFF00), and light white (0xFFFFFF).

<a id="lexer.styles"></a>
#### `lexer.styles`

Map of style names to style definition tables.

Style names consist of the following default names as well as the token names defined by lexers.

* `default`: The default style all others are based on.
* `line_number`: The line number margin style.
* `control_char`: The style of control character blocks.
* `indent_guide`: The style of indentation guides.
* `call_tip`: The style of call tip text. Only the `font`, `size`, `fore`, and `back` style
  definition fields are supported.
* `fold_display_text`: The style of text displayed next to folded lines.
* `class`, `comment`, `constant`, `embedded`, `error`, `function`, `identifier`, `keyword`,
  `label`, `number`, `operator`, `preprocessor`, `regex`, `string`, `type`, `variable`,
  `whitespace`: Some token names used by lexers. Some lexers may define more token names,
  so this list is not exhaustive.
* *`lang`*`_whitespace`: A special style for whitespace tokens in lexer name *lang*. It
  inherits from `whitespace`, and is used in place of it for all lexers.

Style definition tables may contain the following fields:

* `font`: String font name.
* `size`: Integer font size.
* `bold`: Whether or not the font face is bold. The default value is `false`.
* `weight`: Integer weight or boldness of a font, between 1 and 999.
* `italics`: Whether or not the font face is italic. The default value is `false`.
* `underlined`: Whether or not the font face is underlined. The default value is `false`.
* `fore`: Font face foreground color in `0xBBGGRR` or `"#RRGGBB"` format.
* `back`: Font face background color in `0xBBGGRR` or `"#RRGGBB"` format.
* `eolfilled`: Whether or not the background color extends to the end of the line. The
  default value is `false`.
* `case`: Font case: `'u'` for upper, `'l'` for lower, and `'m'` for normal, mixed case. The
  default value is `'m'`.
* `visible`: Whether or not the text is visible. The default value is `true`.
* `changeable`: Whether the text is changeable instead of read-only. The default value is
  `true`.

---
<a id="lfs"></a>
## The `lfs` Module
---

Extends the `lfs` library to find files in directories and determine absolute file paths.

### Functions defined by `lfs`

<a id="lfs.abspath"></a>
#### `lfs.abspath`(*filename, prefix*)

Returns the absolute path to string *filename*.
*prefix* or `lfs.currentdir()` is prepended to a relative filename. The returned path is
not guaranteed to exist.

Parameters:

* *`filename`*: The relative or absolute path to a file.
* *`prefix`*: Optional prefix path prepended to a relative filename.

Return:

* string absolute path

<a id="lfs.walk"></a>
#### `lfs.walk`(*dir, filter, n, include\_dirs*)

Returns an iterator that iterates over all files and sub-directories (up to *n* levels deep)
in directory *dir* and yields each file found.
String or list *filter* determines which files to yield, with the default filter being
`lfs.default_filter`. A filter consists of Lua patterns that match file and directory paths
to include or exclude. Exclusive patterns begin with a '!'. If no inclusive patterns are
given, any path is initially considered. As a convenience, file extensions can be specified
literally instead of as a Lua pattern (e.g. '.lua' vs. '%.lua$'), and '/' also matches the
Windows directory separator ('[/\\]' is not needed).

Parameters:

* *`dir`*: The directory path to iterate over.
* *`filter`*: Optional filter for files and directories to include and exclude. The default
  value is `lfs.default_filter`.
* *`n`*: Optional maximum number of directory levels to descend into. The default value is
  `nil`, which indicates no limit.
* *`include_dirs`*: Optional flag indicating whether or not to yield directory names too.
  Directory names are passed with a trailing '/' or '\', depending on the current platform.
  The default value is `false`.

See also:

* [`lfs.filter`](#lfs.filter)


### Tables defined by `lfs`

<a id="lfs.default_filter"></a>
#### `lfs.default_filter`

The filter table containing common binary file extensions and version control directories
to exclude when iterating over files and directories using `walk`.
Extensions excluded: a, bmp, bz2, class, dll, exe, gif, gz, jar, jpeg, jpg, o, pdf, png,
so, tar, tgz, tif, tiff, xz, and zip.
Directories excluded: .bzr, .git, .hg, .svn, _FOSSIL_, and node_modules.

See also:

* [`lfs.walk`](#lfs.walk)

---
<a id="os"></a>
## The `os` Module
---

Extends Lua's `os` library to provide process spawning capabilities.

### Functions defined by `os`

<a id="os.spawn"></a>
#### `os.spawn`(*cmd, cwd, env, stdout\_cb, stderr\_cb, exit\_cb*)

Spawns an interactive child process *cmd* in a separate thread, returning a handle to that
process.
On Windows, *cmd* is passed to `cmd.exe`: `%COMSPEC% /c [cmd]`.
At the moment, only the Windows terminal version spawns processes in the same thread.

Parameters:

* *`cmd`*: A command line string that contains the program's name followed by arguments to
  pass to it. `PATH` is searched for program names.
* *`cwd`*: Optional current working directory (cwd) for the child process. When omitted,
  the parent's cwd is used.
* *`env`*: Optional map of environment variables for the child process. When omitted,
  Textadept's environment is used.
* *`stdout_cb`*: Optional Lua function that accepts a string parameter for a block of standard
  output read from the child. Stdout is read asynchronously in 1KB or 0.5KB blocks (depending
  on the platform), or however much data is available at the time.
  At the moment, only the Win32 terminal version sends all output, whether it be stdout or
  stderr, to this callback after the process finishes.
* *`stderr_cb`*: Optional Lua function that accepts a string parameter for a block of
  standard error read from the child. Stderr is read asynchronously in 1KB or 0.5kB blocks
  (depending on the platform), or however much data is available at the time.
* *`exit_cb`*: Optional Lua function that is called when the child process finishes. The
  child's exit status is passed.

Usage:

* `os.spawn('lua ' .. buffer.filename, print)`
* `proc = os.spawn('lua -e "print(io.read())"', print)
  proc:write('foo\n')`

Return:

* proc or nil plus an error message on failure

<a id="spawn_proc:close"></a>
#### `spawn_proc:close`()

Closes standard input for process *spawn_proc*, effectively sending an EOF (end of file) to it.

<a id="spawn_proc:kill"></a>
#### `spawn_proc:kill`(*signal*)

Kills running process *spawn_proc*, or sends it Unix signal *signal*.

Parameters:

* *`signal`*: Optional Unix signal to send to *spawn_proc*. The default value is 9 (`SIGKILL`),
  which kills the process.

<a id="spawn_proc:read"></a>
#### `spawn_proc:read`(*arg*)

Reads and returns stdout from process *spawn_proc*, according to string format or number *arg*.
Similar to Lua's `io.read()` and blocks for input. *spawn_proc* must still be running. If
an error occurs while reading, returns `nil`, an error code, and an error message.
Ensure any read operations read all stdout available, as the stdout callback function passed
to `os.spawn()` will not be called until the stdout buffer is clear.

Parameters:

* *`arg`*: Optional argument similar to those in Lua's `io.read()`, but "n" is not
  supported. The default value is "l", which reads a line.

Return:

* string of bytes read

<a id="spawn_proc:status"></a>
#### `spawn_proc:status`()

Returns the status of process *spawn_proc*, which is either "running" or "terminated".

Return:

* "running" or "terminated"

<a id="spawn_proc:wait"></a>
#### `spawn_proc:wait`()

Blocks until process *spawn_proc* finishes (if it has not already done so) and returns its
status code.

Return:

* integer status code

<a id="spawn_proc:write"></a>
#### `spawn_proc:write`(*...*)

Writes string input to the stdin of process *spawn_proc*.
Note: On Linux, if more than 65536 bytes (64K) are to be written, it is possible those
bytes need to be written in 65536-byte (64K) chunks, or the process may not receive all
input. However, it is also possible that there is a limit on how many bytes can be written
in a short period of time, perhaps 196608 bytes (192K).

Parameters:

* *`...`*: Standard input for *spawn_proc*.


---
<a id="string"></a>
## The `string` Module
---

Extends Lua's `string` library to provide character set conversions.

### Functions defined by `string`

<a id="string.iconv"></a>
#### `string.iconv`(*text, new, old*)

Converts string *text* from encoding *old* to encoding *new* using GNU libiconv, returning
the string result.
Raises an error if the encoding conversion failed.
Valid encodings are [GNU libiconv's encodings][] and include:

  * European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
    KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
    Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
    Macintosh.
  * Semitic: ISO-8859-{6,8}, CP{1255,1256}, CP862, Mac{Hebrew,Arabic}.
  * Japanese: EUC-JP, SHIFT_JIS, CP932, ISO-2022-JP, ISO-2022-JP-2, ISO-2022-JP-1.
  * Chinese: EUC-CN, HZ, GBK, CP936, GB18030, EUC-TW, BIG5, CP950, BIG5-HKSCS, BIG5-HKSCS:2004,
    BIG5-HKSCS:2001, BIG5-HKSCS:1999, ISO-2022-CN, ISO-2022-CN-EXT.
  * Korean: EUC-KR, CP949, ISO-2022-KR, JOHAB.
  * Armenian: ARMSCII-8.
  * Georgian: Georgian-Academy, Georgian-PS.
  * Tajik: KOI8-T.
  * Kazakh: PT154, RK1048.
  * Thai: ISO-8859-11, TIS-620, CP874, MacThai.
  * Laotian: MuleLao-1, CP1133.
  * Vietnamese: VISCII, TCVN, CP1258.
  * Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
    UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.

[GNU libiconv's encodings]: https://www.gnu.org/software/libiconv/

Parameters:

* *`text`*: The text to convert.
* *`new`*: The string encoding to convert to.
* *`old`*: The string encoding to convert from.


---
<a id="textadept"></a>
## The `textadept` Module
---

The textadept module.
It provides utilities for editing text in Textadept.

---
<a id="textadept.bookmarks"></a>
## The `textadept.bookmarks` Module
---

Bookmarks for Textadept.

### Fields defined by `textadept.bookmarks`

<a id="textadept.bookmarks.MARK_BOOKMARK"></a>
#### `textadept.bookmarks.MARK_BOOKMARK` (number)

The bookmark mark number.


### Functions defined by `textadept.bookmarks`

<a id="textadept.bookmarks.clear"></a>
#### `textadept.bookmarks.clear`()

Clears all bookmarks in the current buffer.

<a id="textadept.bookmarks.goto_mark"></a>
#### `textadept.bookmarks.goto_mark`(*next*)

Prompts the user to select a bookmarked line to move the caret to the beginning of unless
*next* is given.
If *next* is `true` or `false`, moves the caret to the beginning of the next or previously
bookmarked line, respectively.

Parameters:

* *`next`*: Optional flag indicating whether to go to the next or previous bookmarked
  line relative to the current line. The default value is `nil`, prompting the user for a
  bookmarked line to go to.

<a id="textadept.bookmarks.toggle"></a>
#### `textadept.bookmarks.toggle`()

Toggles a bookmark on the current line.


---
<a id="textadept.editing"></a>
## The `textadept.editing` Module
---

Editing features for Textadept.

### Fields defined by `textadept.editing`

<a id="textadept.editing.INDIC_BRACEMATCH"></a>
#### `textadept.editing.INDIC_BRACEMATCH` (number)

The matching brace highlight indicator number.

<a id="textadept.editing.INDIC_HIGHLIGHT"></a>
#### `textadept.editing.INDIC_HIGHLIGHT` (number)

The word highlight indicator number.

<a id="textadept.editing.auto_enclose"></a>
#### `textadept.editing.auto_enclose` (bool)

Whether or not to auto-enclose selected text when typing a punctuation character, taking
  [`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs) into account.
  The default value is `false`.

<a id="textadept.editing.auto_indent"></a>
#### `textadept.editing.auto_indent` (bool)

Match the previous line's indentation level after inserting a new line.
  The default value is `true`.

<a id="textadept.editing.autocomplete_all_words"></a>
#### `textadept.editing.autocomplete_all_words` (bool)

Autocomplete the current word using words from all open buffers.
  If `true`, performance may be slow when many buffers are open.
  The default value is `false`.

<a id="textadept.editing.highlight_words"></a>
#### `textadept.editing.highlight_words` (number)

The word highlight mode.

  * `textadept.editing.HIGHLIGHT_CURRENT`
    Automatically highlight all instances of the current word.
  * `textadept.editing.HIGHLIGHT_SELECTED`
    Automatically highlight all instances of the selected word.
  * `textadept.editing.HIGHLIGHT_NONE`
    Do not automatically highlight words.

  The default value is `textadept.editing.HIGHLIGHT_NONE`.

<a id="textadept.editing.strip_trailing_spaces"></a>
#### `textadept.editing.strip_trailing_spaces` (bool)

Strip trailing whitespace before saving files. (Does not apply to binary files.)
  The default value is `false`.


### Functions defined by `textadept.editing`

<a id="textadept.editing.autocomplete"></a>
#### `textadept.editing.autocomplete`(*name*)

Displays an autocompletion list provided by the autocompleter function associated with string
*name*, and returns `true` if completions were found.

Parameters:

* *`name`*: The name of an autocompleter function in the `autocompleters` table to use for
  providing autocompletions.

See also:

* [`textadept.editing.autocompleters`](#textadept.editing.autocompleters)

<a id="textadept.editing.convert_indentation"></a>
#### `textadept.editing.convert_indentation`()

Converts indentation between tabs and spaces according to `buffer.use_tabs`.
If `buffer.use_tabs` is `true`, `buffer.tab_width` indenting spaces are converted to tabs.
Otherwise, all indenting tabs are converted to `buffer.tab_width` spaces.

See also:

* [`buffer.use_tabs`](#buffer.use_tabs)

<a id="textadept.editing.enclose"></a>
#### `textadept.editing.enclose`(*left, right, select*)

Encloses the selected text or the current word within strings *left* and *right*, taking
multiple selections into account.

Parameters:

* *`left`*: The left part of the enclosure.
* *`right`*: The right part of the enclosure.
* *`select`*: Optional flag that indicates whether or not to keep enclosed text selected. The
  default value is `false`.

<a id="textadept.editing.filter_through"></a>
#### `textadept.editing.filter_through`(*command*)

Passes the selected text or all buffer text to string shell command *command* as standard input
(stdin) and replaces the input text with the command's standard output (stdout). *command*
may contain shell pipes ('|').
Standard input is as follows:

1. If no text is selected, the entire buffer is used.
2. If text is selected and spans a single line, is a multiple selection, or is a rectangular
  selection, only the selected text is used.
3. If text is selected and spans multiple lines, all text on the lines that have text selected
  is passed as stdin. However, if the end of the selection is at the beginning of a line,
  only the line ending delimiters from the previous line are included. The rest of the line
  is excluded.

Note: Be careful when using commands that emit stdout while reading stdin (as opposed
to emitting stdout only after stdin is closed).  Input that generates more output
than an OS-specific pipe can hold may hang Textadept. On Linux, this may be 64K. See
[`spawn_proc:write()`](#spawn_proc:write).

Parameters:

* *`command`*: The Linux, BSD, macOS, or Windows shell command to filter text through. May
  contain pipes.

<a id="textadept.editing.goto_line"></a>
#### `textadept.editing.goto_line`(*line*)

Moves the caret to the beginning of line number *line* or the user-specified line, ensuring
*line* is visible.

Parameters:

* *`line`*: Optional line number to go to. If `nil`, the user is prompted for one.

<a id="textadept.editing.join_lines"></a>
#### `textadept.editing.join_lines`()

Joins the currently selected lines or the current line with the line below it.
As long as any part of a line is selected, the entire line is eligible for joining.

<a id="textadept.editing.paste_reindent"></a>
#### `textadept.editing.paste_reindent`()

Pastes the text from the clipboard, taking into account the buffer's indentation settings
and the indentation of the current and preceding lines.

<a id="textadept.editing.select_enclosed"></a>
#### `textadept.editing.select_enclosed`(*left, right*)

Selects the text between strings *left* and *right* that enclose the caret.
If that range is already selected, toggles between selecting *left* and *right* as well.
If *left* and *right* are not provided, they are assumed to be one of the delimiter pairs
specified in `auto_pairs` and are inferred from the current position or selection.

Parameters:

* *`left`*: Optional left part of the enclosure.
* *`right`*: Optional right part of the enclosure.

See also:

* [`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs)

<a id="textadept.editing.select_line"></a>
#### `textadept.editing.select_line`()

Selects the current line.

<a id="textadept.editing.select_paragraph"></a>
#### `textadept.editing.select_paragraph`()

Selects the current paragraph.
Paragraphs are surrounded by one or more blank lines.

<a id="textadept.editing.select_word"></a>
#### `textadept.editing.select_word`(*all*)

Selects the current word or, if *all* is `true`, all occurrences of the current word.
If a word is already selected, selects the next occurrence as a multiple selection.

Parameters:

* *`all`*: Whether or not to select all occurrences of the current word. The default value is
  `false`.

See also:

* [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.editing.show_documentation"></a>
#### `textadept.editing.show_documentation`(*pos, ignore\_case*)

Displays a call tip with documentation for the symbol under or directly behind position *pos*
or the caret position.
Documentation is read from API files in the `api_files` table.
If a call tip is already shown, cycles to the next one if it exists.
Symbols are determined by using `buffer.word_chars`.

Parameters:

* *`pos`*: Optional position of the symbol to show documentation for. If omitted, the caret
  position is used.
* *`ignore_case`*: Optional flag that indicates whether or not to search API files
  case-insensitively for symbols. The default value is `false`.

See also:

* [`textadept.editing.api_files`](#textadept.editing.api_files)
* [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.editing.toggle_comment"></a>
#### `textadept.editing.toggle_comment`()

Comments or uncomments the selected lines based on the current language.
As long as any part of a line is selected, the entire line is eligible for
commenting/uncommenting.

See also:

* [`textadept.editing.comment_string`](#textadept.editing.comment_string)

<a id="textadept.editing.transpose_chars"></a>
#### `textadept.editing.transpose_chars`()

Transposes characters intelligently.
If the caret is at the end of a line, transposes the two characters before the caret. Otherwise,
the characters to the left and right are.


### Tables defined by `textadept.editing`

<a id="textadept.editing.XPM_IMAGES"></a>
#### `textadept.editing.XPM_IMAGES`

Map of image names to registered image numbers.

Fields:

* `CLASS`: The image number for classes.
* `NAMESPACE`: The image number for namespaces.
* `METHOD`: The image number for methods.
* `SIGNAL`: The image number for signals.
* `SLOT`: The image number for slots.
* `VARIABLE`: The image number for variables.
* `STRUCT`: The image number for structures.
* `TYPEDEF`: The image number for type definitions.

<a id="textadept.editing.api_files"></a>
#### `textadept.editing.api_files`

Map of lexer names to API documentation file tables.
File tables contain API file paths or functions that return such paths. Each line in an
API file consists of a symbol name (not a fully qualified symbol name), a space character,
and that symbol's documentation. "\n" represents a newline character.

See also:

* [`textadept.editing.show_documentation`](#textadept.editing.show_documentation)

<a id="textadept.editing.auto_pairs"></a>
#### `textadept.editing.auto_pairs`

Map of auto-paired characters like parentheses, brackets, braces, and quotes.
The ASCII values of opening characters are assigned to strings that contain complement
characters. The default auto-paired characters are "()", "[]", "{}", "&apos;&apos;",
"&quot;&quot;", and "``".

Usage:

* `textadept.editing.auto_pairs[string.byte('<')] = '>'`
* `textadept.editing.auto_pairs = nil -- disable completely`

<a id="textadept.editing.autocompleters"></a>
#### `textadept.editing.autocompleters`

Map of autocompleter names to autocompletion functions.
Names are typically lexer names and autocompletion functions typically autocomplete symbols.
Autocompletion functions must return two values: the number of characters behind the caret
that are used as the prefix of the entity to be autocompleted, and a list of completions to
be shown. Autocompletion lists are sorted automatically.

See also:

* [`textadept.editing.autocomplete`](#textadept.editing.autocomplete)

<a id="textadept.editing.brace_matches"></a>
#### `textadept.editing.brace_matches`

Table of brace characters to highlight.
The ASCII values of brace characters are keys and are assigned `true`. The default brace
characters are '(', ')', '[', ']', '{', and '}'.

Usage:

* `textadept.editing.brace_matches[string.byte('<')] = true`
* `textadept.editing.brace_matches[string.byte('>')] = true`

<a id="textadept.editing.comment_string"></a>
#### `textadept.editing.comment_string`

Map of lexer names to line comment strings for programming languages, used by the
`toggle_comment()` function.
Keys are lexer names and values are either the language's line comment prefixes or block
comment delimiters separated by a '|' character.

See also:

* [`textadept.editing.toggle_comment`](#textadept.editing.toggle_comment)

<a id="textadept.editing.typeover_chars"></a>
#### `textadept.editing.typeover_chars`

Table of characters to move over when typed.
The ASCII values of characters are keys and are assigned `true` values. The default characters
are ')', ']', '}', '&apos;', '&quot;', and '`'.

Usage:

* `textadept.editing.typeover_chars[string.byte('>')] = true`

---
<a id="textadept.file_types"></a>
## The `textadept.file_types` Module
---

Handles file type detection for Textadept.

### Fields defined by `textadept.file_types`

<a id="events.LEXER_LOADED"></a>
#### `events.LEXER_LOADED` (string)

Emitted after loading a language lexer.
  This is useful for overriding a language module's key bindings or other properties since
  the module is not loaded when Textadept starts.
  Arguments:

  * _`name`_: The language lexer's name.


### Functions defined by `textadept.file_types`

<a id="textadept.file_types.select_lexer"></a>
#### `textadept.file_types.select_lexer`()

Prompts the user to select a lexer for the current buffer.

See also:

* [`buffer.set_lexer`](#buffer.set_lexer)


### Tables defined by `textadept.file_types`

<a id="textadept.file_types.extensions"></a>
#### `textadept.file_types.extensions`

Map of file extensions to their associated lexer names.
If the file type is not recognized by its first-line, each file extension is matched against
the file's extension.

<a id="textadept.file_types.patterns"></a>
#### `textadept.file_types.patterns`

Map of first-line patterns to their associated lexer names.
Each pattern is matched against the first line in the file.

---
<a id="textadept.history"></a>
## The `textadept.history` Module
---

Records buffer positions within Textadept views over time and allows for navigating through
that history.

This module listens for text edit events and buffer switch events. Each time an insertion
or deletion occurs, its location is recorded in the current view's location history. If the
edit is close enough to the previous record, the previous record is amended. Each time a
buffer switch occurs, the before and after locations are also recorded.

### Fields defined by `textadept.history`

<a id="textadept.history.maximum_history_size"></a>
#### `textadept.history.maximum_history_size` (number)

The maximum number of history records to keep per view.
  The default value is `100`.

<a id="textadept.history.minimum_line_distance"></a>
#### `textadept.history.minimum_line_distance` (number)

The minimum number of lines between distinct history records.
  The default value is `3`.


### Functions defined by `textadept.history`

<a id="textadept.history.back"></a>
#### `textadept.history.back`()

Navigates backwards through the current view's history.

<a id="textadept.history.clear"></a>
#### `textadept.history.clear`()

Clears all view history.

<a id="textadept.history.forward"></a>
#### `textadept.history.forward`()

Navigates forwards through the current view's history.

<a id="textadept.history.record"></a>
#### `textadept.history.record`(*filename, line, column, soft*)

Records the given location in the current view's history.

Parameters:

* *`filename`*: Optional string filename, buffer type, or identifier of the buffer to store. If
  `nil`, uses the current buffer.
* *`line`*: Optional Integer line number to store. If `nil`, uses the current line.
* *`column`*: Optional integer column number on line *line* to store. If `nil`, uses the
  current column.
* *`soft`*: Optional flag that indicates whether or not this record should be skipped when
  navigating backward towards it, and updated when navigating away from it. The default
  value is `false`.


---
<a id="textadept.keys"></a>
## The `textadept.keys` Module
---

Defines key bindings for Textadept.
This set of key bindings is pretty standard among other text editors, at least for basic
editing commands and movements.

### Key Bindings

Win32, Linux, BSD | macOS | Terminal | Command
-|-|-|-
**File**|||
Ctrl+N | ⌘N | M-^N | New file
Ctrl+O | ⌘O | ^O | Open file
Ctrl+Alt+O | ^⌘O | M-^O | Open recent file...
Ctrl+Shift+O | ⌘⇧O | M-O | Reload file
Ctrl+S | ⌘S | ^S<br/>M-S^(*) | Save file
Ctrl+Shift+S | ⌘⇧S | M-^S | Save file as..
None | None | None | Save all files
Ctrl+W | ⌘W | ^W | Close file
Ctrl+Shift+W | ⌘⇧W | M-^W | Close all files
None | None | None | Load session...
None | None | None | Save session...
Ctrl+Q | ⌘Q | ^Q<br/>M-Q^(*) | Quit
**Edit**| | |
Ctrl+Z<br/>Alt+Bksp | ⌘Z | ^Z^(†)<br/>M-Z | Undo
Ctrl+Y<br/>Ctrl+Shift+Z | ⌘⇧Z | ^Y<br/>M-S-Z | Redo
Ctrl+X<br/>Shift+Del | ⌘X<br/>⇧⌦ | ^X | Cut
Ctrl+C<br/>Ctrl+Ins | ⌘C | ^C | Copy
Ctrl+V<br/>Shift+Ins | ⌘V | ^V | Paste
Ctrl+Shift+V | ⌘⇧V | M-V | Paste Reindent
Ctrl+D | ⌘D | None | Duplicate line/selection
Del | ⌦<br/>^D | Del<br/>^D | Delete
Alt+Del | ^⌦ | M-Del<br/>M-D | Delete word
Ctrl+A | ⌘A | M-A | Select all
Ctrl+M | ^M | M-M | Match brace
Ctrl+Enter | ^Esc | M-Enter^(‡) | Complete word
Ctrl+/ | ^/ | M-/ | Toggle block comment
Ctrl+T | ^T | ^T | Transpose characters
Ctrl+Shift+J | ^J | M-J | Join lines
Ctrl+&#124; | ⌘&#124; | ^\ | Filter text through
Ctrl+Shift+M | ^⇧M | M-S-M | Select between delimiters
Ctrl+< | ⌘< | M-< | Select between XML tags
Ctrl+> | ⌘> | None | Select in XML tag
Ctrl+Shift+D | ⌘⇧D | M-S-W | Select word
Ctrl+Shift+N | ⌘⇧N | M-S-N | Select line
Ctrl+Shift+P | ⌘⇧P | M-S-P | Select paragraph
Ctrl+Alt+U | ^U | M-^U | Upper case selection
Ctrl+Alt+Shift+U | ^⇧U | M-^L | Lower case selection
Alt+< | ^< | M-> | Enclose as XML tags
Alt+> | ^> | None | Enclose as single XML tag
Alt+" | ^" | None | Enclose in double quotes
Alt+' | ^' | None | Enclose in single quotes
Alt+( | ^( | M-) | Enclose in parentheses
Alt+[ | ^[ | M-] | Enclose in brackets
Alt+{ | ^{ | M-} | Enclose in braces
Ctrl+Shift+Up | ^⇧⇡ | S-^Up | Move selected lines up
Ctrl+Shift+Down | ^⇧⇣ | S-^Down | Move selected lines down
Alt+, | ^, | M-, | Navigate backward
Alt+. | ^. | M-. | Navigate forward
None | None | None | Record location
None | None | None | Clear navigation history
Ctrl+P | ⌘, | M-~ | Preferences
**Search**| | |
Ctrl+F | ⌘F | M-F<br/>M-S-F | Find
Ctrl+G<br/>F3 | ⌘G | M-G | Find next
Ctrl+Shift+G<br/>Shift+F3 | ⌘⇧G | M-S-G | Find previous
Ctrl+Alt+R | ^R | M-R | Replace
Ctrl+Alt+Shift+R | ^⇧R | M-S-R | Replace all
Ctrl+Alt+F | ^⌘F | M-^F | Find incremental
Ctrl+Shift+F | ⌘⇧F | None | Find in files
Ctrl+Alt+G | ^⌘G | None | Goto next file found
Ctrl+Alt+Shift+G | ^⌘⇧G | None | Goto previous file found
Ctrl+J | ⌘J | ^J | Jump to line
**Tools**| | |
Ctrl+E | ⌘E | M-C | Command entry
Ctrl+Shift+E | ⌘⇧E | M-S-C | Select command
Ctrl+R | ⌘R | ^R | Run
Ctrl+Shift+R | ⌘⇧R | M-^R | Compile
Ctrl+Shift+A | ⌘⇧A | None | Set Arguments...
Ctrl+Shift+B | ⌘⇧B | M-^B | Build
Ctrl+Shift+T | ⌘⇧T | M-^T | Run tests
Ctrl+Shift+X | ⌘⇧X | M-^X | Stop
Ctrl+Alt+E | ^⌘E | M-X | Next Error
Ctrl+Alt+Shift+E | ^⌘⇧E | M-S-X | Previous Error
Ctrl+F2 | ⌘F2 | F1 | Toggle bookmark
Ctrl+Shift+F2 | ⌘⇧F2 | F6 | Clear bookmarks
F2 | F2 | F2 | Next bookmark
Shift+F2 | ⇧F2 | F3 | Previous bookmark
Alt+F2 | ⌥F2 | F4 | Goto bookmark...
F9 | F9 | F9 | Start/stop recording macro
Shift+F9 | ⇧F9 | F10 | Play recorded macro
Ctrl+U | ⌘U | ^U | Quickly open `_USERHOME`
None | None | None | Quickly open `_HOME`
Ctrl+Alt+Shift+O | ^⌘⇧O | M-S-O | Quickly open current directory
Ctrl+Alt+Shift+P | ^⌘⇧P | M-^P | Quickly open current project
Ctrl+Shift+K | ⌥⇧⇥ | M-S-K | Insert snippet...
Tab | ⇥ | Tab | Expand snippet or next placeholder
Shift+Tab | ⇧⇥ | S-Tab | Previous snippet placeholder
Esc | Esc | Esc | Cancel snippet
Ctrl+K | ⌥⇥ | M-K | Complete trigger word
Ctrl+Space | ⌥Esc | ^Space | Complete symbol
Ctrl+H | ^H | M-H<br/>M-S-H | Show documentation
Ctrl+I | ⌘I | M-S-I | Show style
**Buffer**| | |
Ctrl+Tab | ^⇥ | M-N | Next buffer
Ctrl+Shift+Tab | ^⇧⇥ | M-P | Previous buffer
Ctrl+B | ⌘B | M-B<br/>M-S-B | Switch to buffer...
None | None | None | Tab width: 2
None | None | None | Tab width: 3
None | None | None | Tab width: 4
None | None | None | Tab width: 8
Ctrl+Alt+Shift+T | ^⇧T | M-T<br/>M-S-T | Toggle use tabs
Ctrl+Alt+I | ^I | M-I | Convert indentation
None | None | None | CR+LF EOL mode
None | None | None | LF EOL mode
None | None | None | UTF-8 encoding
None | None | None | ASCII encoding
None | None | None | CP-1252 encoding
None | None | None | UTF-16 encoding
Ctrl+Alt+\\ | ^\\ | None | Toggle wrap mode
Ctrl+Alt+Shift+S | ^⇧S | None | Toggle view whitespace
Ctrl+Shift+L | ⌘⇧L | M-S-L | Select lexer...
**View**| | |
Ctrl+Alt+N | ^⌥⇥ | M-^V N | Next view
Ctrl+Alt+P | ^⌥⇧⇥ | M-^V P | Previous view
Ctrl+Alt+S<br/>Ctrl+Alt+H | ^S | M-^V S<br/>M-^V H | Split view horizontal
Ctrl+Alt+V | ^V | M-^V V | Split view vertical
Ctrl+Alt+W | ^W | M-^V W | Unsplit view
Ctrl+Alt+Shift+W | ^⇧W | M-^V S-W | Unsplit all views
Ctrl+Alt++<br/>Ctrl+Alt+= | ^+<br/>^= | M-^V +<br/>M-^V = | Grow view
Ctrl+Alt+- | ^- | M-^V - | Shrink view
Ctrl+* | ⌘* | M-* | Toggle current fold
Ctrl+Alt+Shift+I | ^⇧I | N/A | Toggle indent guides
Ctrl+Alt+Shift+V | ^⇧V | None | Toggle virtual space
Ctrl+= | ⌘= | N/A | Zoom in
Ctrl+- | ⌘- | N/A | Zoom out
Ctrl+0 | ⌘0 | N/A | Reset zoom
**Help**|| |
F1 | F1 | None | Open manual
Shift+F1 | ⇧F1 | None | Open LuaDoc
None | None | None | About
**Movement**| | |
Down | ⇣<br/>^N | ^N<br/>Down | Line down
Shift+Down | ⇧⇣<br/>^⇧N | S-Down | Line down extend selection
Ctrl+Down | ^⇣ | ^Down | Scroll line down
Alt+Shift+Down | ⌥⇧⇣ | M-S-Down | Line down extend rect. selection
Up | ⇡<br/>^P | ^P<br/>Up | Line up
Shift+Up | ⇧⇡<br/>^⇧P | S-Up | Line up extend selection
Ctrl+Up | ^⇡ | ^Up | Scroll line up
Alt+Shift+Up | ⌥⇧⇡ | M-S-Up | Line up extend rect. selection
Left | ⇠<br/>^B | ^B<br/>Left | Char left
Shift+Left | ⇧⇠<br/>^⇧B | S-Left | Char left extend selection
Ctrl+Left | ⌥⇠<br/>^⌘B | ^Left | Word left
Ctrl+Shift+Left | ^⇧⇠<br/>^⌘⇧B | S-^Left | Word left extend selection
Alt+Shift+Left | ⌥⇧⇠ | M-S-Left | Char left extend rect. selection
Right | ⇢<br/>^F | ^F<br/>Right | Char right
Shift+Right | ⇧⇢<br/>^⇧F | S-Right | Char right extend selection
Ctrl+Right | ⌥⇢<br/>^⌘F | ^Right | Word right
Ctrl+Shift+Right | ^⇧⇢<br/>^⌘⇧F | S-^Right | Word right extend selection
Alt+Shift+Right | ⌥⇧⇢ | M-S-Right | Char right extend rect. selection
Home | ⌘⇠<br/>^A | ^A<br/>Home | Line start
Shift+Home | ⌘⇧⇠<br/>^⇧A | M-S-A | Line start extend selection
Ctrl+Home | ⌘⇡<br/>⌘↖ | M-^A | Document start
Ctrl+Shift+Home | ⌘⇧⇡<br/>⌘⇧↖ | None | Document start extend selection
Alt+Shift+Home | ⌥⇧↖ | None | Line start extend rect. selection
End | ⌘⇢<br/>^E | ^E<br/>End | Line end
Shift+End | ⌘⇧⇢<br/>^⇧E | M-S-E | Line end extend selection
Ctrl+End | ⌘⇣<br/>⌘↘ | M-^E | Document end
Ctrl+Shift+End | ⌘⇧⇣<br/>⌘⇧↘ | None | Document end extend selection
Alt+Shift+End | ⌥⇧↘ | None | Line end extend rect. selection
PgUp | ⇞ | PgUp | Page up
Shift+PgUp | ⇧⇞ | M-S-U | Page up extend selection
Alt+Shift+PgUp | ⌥⇧⇞ | None | Page up extend rect. selection
PgDn | ⇟ | PgDn | Page down
Shift+PgDn | ⇧⇟ | M-S-D | Page down extend selection
Alt+Shift+PgDn | ⌥⇧⇟ | None | Page down extend rect. selection
Ctrl+Del | ⌘⌦ | ^Del | Delete word right
Ctrl+Shift+Del | ⌘⇧⌦ | S-^Del | Delete line right
Ins | Ins | Ins | Toggle overtype
Bksp | ⌫<br/>⇧⌫ | ^H<br/>Bksp | Delete back
Ctrl+Bksp | ⌘⌫ | None | Delete word left
Ctrl+Shift+Bksp | ⌘⇧⌫ | None | Delete line left
Tab | ⇥ | Tab<br/>^I | Insert tab or indent
Shift+Tab | ⇧⇥ | S-Tab | Dedent
None | ^K | ^K | Cut to line end
None | ^L | None | Center line vertically
N/A | N/A | ^^ | Mark text at the caret position
N/A | N/A | ^] | Swap caret and mark anchor
**UTF-8 Input**|||
Ctrl+Shift+U *xxxx* Enter | ⌘⇧U *xxxx* ↩ | M-U *xxxx* Enter | Insert U-*xxxx* char.
**Find Fields**|||
Left | ⇠<br/>^B | ^B<br/>Left | Cursor left
Right | ⇢<br/>^F | ^F<br/>Right | Cursor right
Del | ⌦ | Del | Delete forward
Bksp | ⌫ | ^H<br/>Bksp | Delete back
Ctrl+V | ⌘V | ^V | Paste
N/A | N/A | ^X | Cut all
N/A | N/A | ^Y | Copy all
N/A | N/A | ^U | Erase all
Home | ↖<br/>⌘⇠<br/>^A | ^A | Home
End | ↘<br/>⌘⇢<br/>^E | ^E | End
N/A | N/A | ^T | Transpose characters
N/A | N/A | Tab | Toggle find/replace buttons
Tab | ⇥ | Down | Focus replace field
Shift+Tab | ⇧⇥ | Up | Focus find field
Up | ⇡ | ^P | Cycle back through history
Down | ⇣ | ^N | Cycle forward through history
N/A | N/A | F1 | Toggle "Match Case"
N/A | N/A | F2 | Toggle "Whole Word"
N/A | N/A | F3 | Toggle "Regex"
N/A | N/A | F4 | Toggle "Find in Files"

*: For use when the `-p` or `--preserve` command line option is given to the non-Windows
terminal version, since ^S and ^Q are flow control sequences.

†: Some terminals interpret ^Z as suspend; see FAQ for workaround.

‡: Ctrl+Enter in Windows terminal version.

---
<a id="textadept.macros"></a>
## The `textadept.macros` Module
---

A module for recording, playing, saving, and loading keyboard macros.
Menu commands are also recorded.
At this time, typing into multiple cursors during macro playback is not supported.

### Functions defined by `textadept.macros`

<a id="textadept.macros.load"></a>
#### `textadept.macros.load`(*filename*)

Loads a macro from file *filename* or the user-selected file.

Parameters:

* *`filename`*: Optional macro file to load. If `nil`, the user is prompted for one.

<a id="textadept.macros.play"></a>
#### `textadept.macros.play`()

Plays a recorded or loaded macro.

See also:

* [`textadept.macros.load`](#textadept.macros.load)

<a id="textadept.macros.record"></a>
#### `textadept.macros.record`()

Toggles between starting and stopping macro recording.

<a id="textadept.macros.save"></a>
#### `textadept.macros.save`(*filename*)

Saves a recorded macro to file *filename* or the user-selected file.

Parameters:

* *`filename`*: Optional filename to save the recorded macro to. If `nil`, the user is
  prompted for one.


---
<a id="textadept.menu"></a>
## The `textadept.menu` Module
---

Defines the menus used by Textadept.
Menus are simply tables of menu items and submenus and may be edited in place. A menu item
itself is a table whose first element is a menu label and whose second element is a menu
command to run. Submenus have `title` keys assigned to string text.

### Functions defined by `textadept.menu`

<a id="textadept.menu.select_command"></a>
#### `textadept.menu.select_command`()

Prompts the user to select a menu command to run.


### Tables defined by `textadept.menu`

<a id="textadept.menu.context_menu"></a>
#### `textadept.menu.context_menu`

The default right-click context menu.
Submenus, and menu items can be retrieved by name in addition to table index number.

Usage:

* `textadept.menu.context_menu[#textadept.menu.context_menu + 1] = {...}`

<a id="textadept.menu.menubar"></a>
#### `textadept.menu.menubar`

The default main menubar.
Individual menus, submenus, and menu items can be retrieved by name in addition to table
index number.

Usage:

* `textadept.menu.menubar[_L['File']][_L['New']]`
* `textadept.menu.menubar[_L['File']][_L['New']][2] = function() .. end`

<a id="textadept.menu.tab_context_menu"></a>
#### `textadept.menu.tab_context_menu`

The default tabbar context menu.
Submenus, and menu items can be retrieved by name in addition to table index number.

---
<a id="textadept.run"></a>
## The `textadept.run` Module
---

Compile and run source code files with Textadept.
[Language modules](#compile-and-run) may tweak the `compile_commands`, `run_commands`, and
`error_patterns` tables for particular languages.
The user may tweak `build_commands` and `test_commands` for particular projects.

### Fields defined by `textadept.run`

<a id="textadept.run.MARK_ERROR"></a>
#### `textadept.run.MARK_ERROR` (number)

The run or compile error marker number.

<a id="textadept.run.MARK_WARNING"></a>
#### `textadept.run.MARK_WARNING` (number)

The run or compile warning marker number.

<a id="events.BUILD_OUTPUT"></a>
#### `events.BUILD_OUTPUT` (string)

Emitted when executing a project's build shell command.
  By default, output is printed to the message buffer. In order to override this behavior,
  connect to the event with an index of `1` and return `true`.
  Arguments:

  * `output`: A line of string output from the command.

<a id="events.COMPILE_OUTPUT"></a>
#### `events.COMPILE_OUTPUT` (string)

Emitted when executing a language's compile shell command.
  By default, compiler output is printed to the message buffer. In order to override this
  behavior, connect to the event with an index of `1` and return `true`.
  Arguments:

  * `output`: A line of string output from the command.
  * `ext_or_lexer`: The file extension or lexer name associated with the executed compile
    command.

<a id="events.RUN_OUTPUT"></a>
#### `events.RUN_OUTPUT` (string)

Emitted when executing a language's run shell command.
  By default, output is printed to the message buffer. In order to override this behavior,
  connect to the event with an index of `1` and return `true`.
  Arguments:

  * `output`: A line of string output from the command.
  * `ext_or_lexer`: The file extension or lexer name associated with the executed run command.

<a id="events.TEST_OUTPUT"></a>
#### `events.TEST_OUTPUT` (string)

Emitted when executing a project's shell command for running tests.
  By default, output is printed to the message buffer. In order to override this behavior,
  connect to the event with an index of `1` and return `true`.
  Arguments:

  * `output`: A line of string output from the command.

<a id="textadept.run.run_in_background"></a>
#### `textadept.run.run_in_background` (bool)

Run shell commands silently in the background.
  This only applies when the message buffer is open, though it does not have to be visible.
  The default value is `false`.


### Functions defined by `textadept.run`

<a id="textadept.run.build"></a>
#### `textadept.run.build`(*root\_directory*)

Builds the project whose root path is *root_directory* or the current project using the
shell command from the `build_commands` table.
If a "makefile" type of build file is found, prompts the user for the full build command. The
current project is determined by either the buffer's filename or the current working directory.
Emits `BUILD_OUTPUT` events.

Parameters:

* *`root_directory`*: The path to the project to build. The default value is the current project.

See also:

* [`textadept.run.build_commands`](#textadept.run.build_commands)
* [`events`](#events)

<a id="textadept.run.compile"></a>
#### `textadept.run.compile`(*filename*)

Compiles file *filename* or the current file using an appropriate shell command from the
`compile_commands` table.
The shell command is determined from the file's filename, extension, or language in that order.
Emits `COMPILE_OUTPUT` events.

Parameters:

* *`filename`*: Optional path to the file to compile. The default value is the current
  file's filename.

See also:

* [`textadept.run.compile_commands`](#textadept.run.compile_commands)
* [`events`](#events)

<a id="textadept.run.goto_error"></a>
#### `textadept.run.goto_error`(*line\_num, next*)

Jumps to the source of the recognized compile/run warning or error on line number *line_num*
in the message buffer.
If *line_num* is `nil`, jumps to the next or previous warning or error, depending on boolean
*next*. Displays an annotation with the warning or error message if possible.

Parameters:

* *`line_num`*: Optional line number in the message buffer that contains the compile/run
  warning or error to go to. This parameter may be omitted completely.
* *`next`*: Optional flag indicating whether to go to the next recognized warning/error or
  the previous one. Only applicable when *line_num* is `nil`.

See also:

* [`textadept.run.error_patterns`](#textadept.run.error_patterns)

<a id="textadept.run.run"></a>
#### `textadept.run.run`(*filename*)

Runs file *filename* or the current file using an appropriate shell command from the
`run_commands` table.
The shell command is determined from the file's filename, extension, or language in that order.
Emits `RUN_OUTPUT` events.

Parameters:

* *`filename`*: Optional path to the file to run. The default value is the current file's
  filename.

See also:

* [`textadept.run.run_commands`](#textadept.run.run_commands)
* [`events`](#events)

<a id="textadept.run.set_arguments"></a>
#### `textadept.run.set_arguments`(*filename, run, compile*)

Appends the command line argument strings *run* and *compile* to their respective run and
compile commands for file *filename* or the current file.
If either is `nil`, prompts the user for missing the arguments. Each filename has its own
set of compile and run arguments.

Parameters:

* *`filename`*: Optional path to the file to set run/compile arguments for.
* *`run`*: Optional string run arguments to set. If `nil`, the user is prompted for them. Pass
  the empty string for no run arguments.
* *`compile`*: Optional string compile arguments to set. If `nil`, the user is prompted
  for them. Pass the empty string for no compile arguments.

See also:

* [`textadept.run.run_commands`](#textadept.run.run_commands)
* [`textadept.run.compile_commands`](#textadept.run.compile_commands)

<a id="textadept.run.stop"></a>
#### `textadept.run.stop`()

Stops the currently running process, if any.

<a id="textadept.run.test"></a>
#### `textadept.run.test`(*root\_directory*)

Runs tests for the project whose root path is *root_directory* or the current project using
the shell command from the `test_commands` table.
The current project is determined by either the buffer's filename or the current working
directory.
Emits `TEST_OUTPUT` events.

Parameters:

* *`root_directory`*: The path to the project to run tests for. The default value is the
  current project.

See also:

* [`textadept.run.test_commands`](#textadept.run.test_commands)
* [`events`](#events)


### Tables defined by `textadept.run`

<a id="textadept.run.build_commands"></a>
#### `textadept.run.build_commands`

Map of project root paths and "makefiles" to their associated "build" shell command line
strings or functions that return such strings.
Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

<a id="textadept.run.compile_commands"></a>
#### `textadept.run.compile_commands`

Map of filenames, file extensions, and lexer names to their associated "compile" shell
command line strings or functions that return such strings.
Command line strings may have the following macros:

  + `%f`: The file's name, including its extension.
  + `%e`: The file's name, excluding its extension.
  + `%d`: The file's directory path.
  + `%p`: The file's full path.

Functions may also return a working directory and process environment table to operate in. By
default, the working directory is the current file's parent directory and the environment
is Textadept's environment.

<a id="textadept.run.error_patterns"></a>
#### `textadept.run.error_patterns`

Map of file extensions and lexer names to their associated lists of string patterns that
match warning and error messages emitted by compile and run commands for those file extensions
and lexers.
Patterns match single lines and contain captures for a filename, line number, column number
(optional), and warning or error message (optional). Double-clicking a warning or error
message takes the user to the source of that warning/error.
Note: `(.-)` captures in patterns are interpreted as filenames; `(%d+)` captures are
interpreted as line numbers first, and then column numbers; and any other capture is treated
as warning/error message text.

<a id="textadept.run.run_commands"></a>
#### `textadept.run.run_commands`

Map of filenames, file extensions, and lexer names to their associated "run" shell command
line strings or functions that return strings.
Command line strings may have the following macros:

  + `%f`: The file's name, including its extension.
  + `%e`: The file's name, excluding its extension.
  + `%d`: The file's directory path.
  + `%p`: The file's full path.

Functions may also return a working directory and process environment table to operate in. By
default, the working directory is the current file's parent directory and the environment
is Textadept's environment.

<a id="textadept.run.test_commands"></a>
#### `textadept.run.test_commands`

Map of project root paths to their associated "test" shell command line strings or functions
that return such strings.
Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

---
<a id="textadept.session"></a>
## The `textadept.session` Module
---

Session support for Textadept.

### Fields defined by `textadept.session`

<a id="events.SESSION_LOAD"></a>
#### `events.SESSION_LOAD` (string)

Emitted when loading a session.
  Arguments:

  * `session`: Table of session data to load. All handlers will have access to this same table.

<a id="events.SESSION_SAVE"></a>
#### `events.SESSION_SAVE` (string)

Emitted when saving a session.
  Arguments:

  * `session`: Table of session data to save. All handlers will have access to this same
    table, and Textadept's default handler reserves the use of some keys.
    Note that functions, userdata, and circular table values cannot be saved. The latter
    case is not recognized at all, so beware.

<a id="textadept.session.save_on_quit"></a>
#### `textadept.session.save_on_quit` (bool)

Save the session when quitting.
  The default value is `true` unless the user passed the command line switch `-n` or
  `--nosession` to Textadept.


### Functions defined by `textadept.session`

<a id="textadept.session.load"></a>
#### `textadept.session.load`(*filename*)

Loads session file *filename* or the user-selected session, returning `true` if a session
file was opened and read.
Textadept restores split views, opened buffers, cursor information, recent files, and bookmarks.

Parameters:

* *`filename`*: Optional absolute path to the session file to load. If `nil`, the user is
  prompted for one.

Usage:

* `textadept.session.load(filename)`

Return:

* `true` if the session file was opened and read; `nil` otherwise.

<a id="textadept.session.save"></a>
#### `textadept.session.save`(*filename*)

Saves the session to file *filename* or the user-selected file.
Saves split views, opened buffers, cursor information, recent files, and bookmarks.
Upon quitting, the current session is saved to *filename* again, unless
`textadept.session.save_on_quit` is `false`.

Parameters:

* *`filename`*: Optional absolute path to the session file to save. If `nil`, the user is
  prompted for one.

Usage:

* `textadept.session.save(filename)`


---
<a id="textadept.snippets"></a>
## The `textadept.snippets` Module
---

Snippets for Textadept.

### Overview

Define snippets in the global `snippets` table in key-value pairs. Each pair consists of
either a string trigger word and its snippet text, or a string lexer name (from the *lexers/*
directory) with a table of trigger words and snippet texts. When searching for a snippet to
insert based on a trigger word, Textadept considers snippets in the current lexer to have
priority, followed by the ones in the global table. This means if there are two snippets
with the same trigger word, Textadept inserts the one specific to the current lexer, not
the global one.

### Special Sequences

#### `%`*n*`(`*text*`)`

Represents a placeholder, where *n* is an integer and *text* is default placeholder
text. Textadept moves the caret to placeholders in numeric order each time it calls
[`textadept.snippets.insert()`](#textadept.snippets.insert), finishing at either the "%0" placeholder if it exists or
at the end of the snippet. Examples are

    snippets['foo'] = 'foobar%1(baz)'
    snippets['bar'] = 'start\n\t%0\nend'

#### `%`*n*`{`*list*`}`

Also represents a placeholder (where *n* is an integer), but presents a list of choices for
placeholder text constructed from comma-separated *list*. Examples are

    snippets['op'] = 'operator(%1(1), %2(1), "%3{add,sub,mul,div}")'

#### `%`*n*

Represents a mirror, where *n* is an integer. Mirrors with the same *n* as a placeholder mirror
any user input in the placeholder. If no placeholder exists for *n*, the first occurrence
of that mirror in the snippet becomes the placeholder, but with no default text. Examples are

    snippets['foo'] = '%1(mirror), %1, on the wall'
    snippets['q'] = '"%1"'

#### `%`*n*`<`*Lua code*`>`<br/>`%`*n*`[`*Shell code*`]`

Represents a transform, where *n* is an integer that has an associated placeholder, *Lua code*
is arbitrary Lua code, and *Shell code* is arbitrary Shell code. Textadept executes the code
as text is typed into placeholder *n*. If the transform omits *n*, Textadept executes the
transform's code the moment the editor inserts the snippet.

Textadept runs Lua code in its Lua State and replaces the transform with the code's return
text. The code may use the temporary `text` and `selected_text` global variables which
contain placeholder *n*'s text and the text originally selected when the snippet was inserted,
respectively. An example is

    snippets['attr'] = [[
    %1(int) %2(foo) = %3;

    %1 get%2<text:gsub('^.', function(c) return c:upper() end)>() {
    	return %2;
    }
    void set%2<text:gsub('^.', function(c) return c:upper() end)>(%1 value) {
    	%2 = value;
    }
    ]]

Textadept executes shell code using Lua's [`io.popen()`][] and replaces the transform with the
process' standard output (stdout). The code may use a `%` character to represent placeholder
*n*'s text. An example is

    snippets['env'] = '$%1(HOME) = %1[echo $%]'

#### `%%`

Stands for a single '%' since '%' by itself has a special meaning in snippets.

#### `%(`<br/>`%{`

Stands for a single '(' or '{', respectively, after a `%`*n* mirror. Otherwise, the mirror
would be interpreted as a placeholder or transform. Note: it is currently not possible to
escape a '<' or '[' immediately after a `%`*n* mirror due to `%<...>` and `%[...]` sequences
being interpreted as code to execute.

#### `\t`

A single unit of indentation based on the buffer's indentation settings ([`buffer.use_tabs`](#buffer.use_tabs)
and [`buffer.tab_width`](#buffer.tab_width)).

#### `\n`

A single set of line ending delimiters based on the buffer's end of line mode
([`buffer.eol_mode`](#buffer.eol_mode)).

[`io.popen()`]: https://www.lua.org/manual/5.3/manual.html#pdf-io.popen


### Fields defined by `textadept.snippets`

<a id="textadept.snippets.INDIC_PLACEHOLDER"></a>
#### `textadept.snippets.INDIC_PLACEHOLDER` (number)

The snippet placeholder indicator number.

<a id="textadept.editing.autocompleters.snippet"></a>
#### `textadept.editing.autocompleters.snippet` (function)

Autocompleter function for snippet trigger words.


### Functions defined by `textadept.snippets`

<a id="textadept.snippets.cancel_current"></a>
#### `textadept.snippets.cancel_current`()

Cancels the active snippet, removing all inserted text.
Returns `false` if no snippet is active.

Return:

* `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.insert"></a>
#### `textadept.snippets.insert`(*text*)

Inserts snippet text *text* or the snippet assigned to the trigger word behind the caret.
Otherwise, if a snippet is active, goes to the active snippet's next placeholder. Returns
`false` if no action was taken.

Parameters:

* *`text`*: Optional snippet text to insert. If `nil`, attempts to insert a new snippet
  based on the trigger, the word behind caret, and the current lexer.

Return:

* `false` if no action was taken; `nil` otherwise.

See also:

* [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.snippets.previous"></a>
#### `textadept.snippets.previous`()

Jumps back to the previous snippet placeholder, reverting any changes from the current one.
Returns `false` if no snippet is active.

Return:

* `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.select"></a>
#### `textadept.snippets.select`()

Prompts the user to select a snippet to insert from a list of global and language-specific
snippets.


### Tables defined by `textadept.snippets`

<a id="_G.snippets"></a>
#### `_G.snippets`

Map of snippet triggers with their snippet text or functions that return such text, with
language-specific snippets tables assigned to a lexer name key.

<a id="textadept.snippets.paths"></a>
#### `textadept.snippets.paths`

List of directory paths to look for snippet files in.
Filenames are of the form *lexer.trigger.ext* or *trigger.ext* (*.ext* is an optional,
arbitrary file extension). If the global `snippets` table does not contain a snippet for
a given trigger, this table is consulted for a matching filename, and the contents of that
file is inserted as a snippet.
Note: If a directory has multiple snippets with the same trigger, the snippet chosen for
insertion is not defined and may not be constant.

---
<a id="ui"></a>
## The `ui` Module
---

Utilities for interacting with Textadept's user interface.

### Fields defined by `ui`

<a id="ui.SHOW_ALL_TABS"></a>
#### `ui.SHOW_ALL_TABS` (number)




<a id="ui.buffer_statusbar_text"></a>
#### `ui.buffer_statusbar_text` (string, Write-only)

The text displayed in the buffer statusbar.

<a id="ui.clipboard_text"></a>
#### `ui.clipboard_text` (string)

The text on the clipboard.

<a id="ui.context_menu"></a>
#### `ui.context_menu` (userdata)

The buffer's context menu, a [`ui.menu()`](#ui.menu).
  This is a low-level field. You probably want to use the higher-level
  [`textadept.menu.context_menu`](#textadept.menu.context_menu).

<a id="ui.maximized"></a>
#### `ui.maximized` (bool)

Whether or not Textadept's window is maximized.

<a id="ui.silent_print"></a>
#### `ui.silent_print` (bool)

Whether or not to print messages to buffers silently.
  This is not guaranteed to be a constant value, as Textadept may change it for the editor's
  own purposes. This flag should be used only in conjunction with a group of [`ui.print()`](#ui.print)
  and [`ui._print()`](#ui._print) function calls.
  The default value is `false`, and focuses buffers when messages are printed to them.

<a id="ui.statusbar_text"></a>
#### `ui.statusbar_text` (string, Write-only)

The text displayed in the statusbar.

<a id="ui.tab_context_menu"></a>
#### `ui.tab_context_menu` (userdata)

The context menu for the buffer's tab, a [`ui.menu()`](#ui.menu).
  This is a low-level field. You probably want to use the higher-level
  [`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu).

<a id="ui.tabs"></a>
#### `ui.tabs` (bool)

Whether or not to display the tab bar when multiple buffers are open.
  The default value is `true`.
  A third option, `ui.SHOW_ALL_TABS` may be used to always show the tab bar, even if only
  one buffer is open.

<a id="ui.title"></a>
#### `ui.title` (string, Write-only)

The title text of Textadept's window.


### Functions defined by `ui`

<a id="ui._print"></a>
#### `ui._print`(*buffer\_type, ...*)

Prints the given string messages to the buffer of string type *buffer_type*.
Opens a new buffer for printing messages to if necessary. If the message buffer is already
open in a view, the message is printed to that view. Otherwise the view is split (unless
`ui.tabs` is `true`) and the message buffer is displayed before being printed to.

Parameters:

* *`buffer_type`*: String type of message buffer.
* *`...`*: Message strings.

Usage:

* `ui._print(_L['[Message Buffer]'], message)`

<a id="ui.dialog"></a>
#### `ui.dialog`(*kind, ...*)

Low-level function for prompting the user with a [gtdialog][] of kind *kind* with the given
string and table arguments, returning a formatted string of the dialog's output.
You probably want to use the higher-level functions in the [`ui.dialogs`](#ui.dialogs) module.
Table arguments containing strings are allowed and expanded in place. This is useful for
filtered list dialogs with many items.

[gtdialog]: https://orbitalquark.github.io/gtdialog/manual.html

Parameters:

* *`kind`*: The kind of gtdialog.
* *`...`*: Parameters to the gtdialog.

Return:

* string gtdialog result.

<a id="ui.get_split_table"></a>
#### `ui.get_split_table`()

Returns a split table that contains Textadept's current split view structure.
This is primarily used in session saving.

Return:

* table of split views. Each split view entry is a table with 4 fields: `1`, `2`,
  `vertical`, and `size`. `1` and `2` have values of either nested split view entries or
  the views themselves; `vertical` is a flag that indicates if the split is vertical or not;
  and `size` is the integer position of the split resizer.

<a id="ui.goto_file"></a>
#### `ui.goto_file`(*filename, split, preferred\_view, sloppy*)

Switches to the existing view whose buffer's filename is *filename*.
If no view was found and *split* is `true`, splits the current view in order to show the
requested file. If *split* is `false`, shifts to the next or *preferred_view* view in order
to show the requested file. If *sloppy* is `true`, requires only the basename of *filename*
to match a buffer's `filename`. If the requested file was not found, it is opened in the
desired view.

Parameters:

* *`filename`*: The filename of the buffer to go to.
* *`split`*: Optional flag that indicates whether or not to open the buffer in a split view
  if there is only one view. The default value is `false`.
* *`preferred_view`*: Optional view to open the desired buffer in if the buffer is not
  visible in any other view.
* *`sloppy`*: Optional flag that indicates whether or not to not match *filename* to
  `buffer.filename` exactly. When `true`, matches *filename* to only the last part of
  `buffer.filename` This is useful for run and compile commands which output relative filenames
  and paths instead of full ones and it is likely that the file in question is already open.
  The default value is `false`.

<a id="ui.goto_view"></a>
#### `ui.goto_view`(*view*)

Shifts to view *view* or the view *view* number of views relative to the current one.
Emits `VIEW_BEFORE_SWITCH` and `VIEW_AFTER_SWITCH` events.

Parameters:

* *`view`*: A view or relative view number (typically 1 or -1).

See also:

* [`_VIEWS`](#_VIEWS)
* [`events.VIEW_BEFORE_SWITCH`](#events.VIEW_BEFORE_SWITCH)
* [`events.VIEW_AFTER_SWITCH`](#events.VIEW_AFTER_SWITCH)

<a id="ui.menu"></a>
#### `ui.menu`(*menu\_table*)

Low-level function for creating a menu from table *menu_table* and returning the userdata.
You probably want to use the higher-level `textadept.menu.menubar`,
`textadept.menu.context_menu`, or `textadept.menu.tab_context_menu` tables.
Emits a `MENU_CLICKED` event when a menu item is selected.

Parameters:

* *`menu_table`*: A table defining the menu. It is an ordered list of tables with a string
  menu item, integer menu ID, and optional GDK keycode and modifier mask. The latter
  two are used to display key shortcuts in the menu. '_' characters are treated as a menu
  mnemonics. If the menu item is empty, a menu separator item is created. Submenus are just
  nested menu-structure tables. Their title text is defined with a `title` key.

Usage:

* `ui.menu{ {'_New', 1}, {'_Open', 2}, {''}, {'_Quit', 4} }`
* `ui.menu{ {'_New', 1, string.byte('n'), 4} } -- 'Ctrl+N'`

See also:

* [`events.MENU_CLICKED`](#events.MENU_CLICKED)
* [`textadept.menu.menubar`](#textadept.menu.menubar)
* [`textadept.menu.context_menu`](#textadept.menu.context_menu)
* [`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu)

<a id="ui.popup_menu"></a>
#### `ui.popup_menu`(*menu*)

Displays a popup menu, typically the right-click context menu.

Parameters:

* *`menu`*: Menu to display.

Usage:

* `ui.popup_menu(ui.context_menu)`

See also:

* [`ui.menu`](#ui.menu)
* [`ui.context_menu`](#ui.context_menu)

<a id="ui.print"></a>
#### `ui.print`(*...*)

Prints the given string messages to the message buffer.
Opens a new buffer if one has not already been opened for printing messages.

Parameters:

* *`...`*: Message strings.

<a id="ui.switch_buffer"></a>
#### `ui.switch_buffer`(*zorder*)

Prompts the user to select a buffer to switch to.
Buffers are listed in the order they were opened unless `zorder` is `true`, in which case
buffers are listed by their z-order (most recently viewed to least recently viewed).

Parameters:

* *`zorder`*: Flag that indicates whether or not to list buffers by their z-order. The
  default value is `false`.

<a id="ui.update"></a>
#### `ui.update`()

Processes pending GTK events, including reading from spawned processes.
This function is primarily used in unit tests.


### Tables defined by `ui`

<a id="ui.menubar"></a>
#### `ui.menubar`

A table of menus defining a menubar. (Write-only).
This is a low-level field. You probably want to use the higher-level `textadept.menu.menubar`.

See also:

* [`textadept.menu.menubar`](#textadept.menu.menubar)

<a id="ui.size"></a>
#### `ui.size`

A table containing the width and height pixel values of Textadept's window.

---
<a id="ui.command_entry"></a>
## The `ui.command_entry` Module
---

Textadept's Command Entry.
It supports multiple modes that each have their own functionality (such as running Lua code
and filtering text through shell commands) and history.

### Fields defined by `ui.command_entry`

<a id="ui.command_entry.active"></a>
#### `ui.command_entry.active` (boolean)

Whether or not the command entry is active.

<a id="ui.command_entry.height"></a>
#### `ui.command_entry.height` (number)

The height in pixels of the command entry.


### Functions defined by `ui.command_entry`

<a id="ui.command_entry.append_history"></a>
#### `ui.command_entry.append_history`(*f, text*)

Appends string *text* to the history for command entry mode *f* or the current or most
recent mode.
This should only be called if `ui.command_entry.run()` is called with a keys table that has a
custom binding for the Enter key ('\n'). Otherwise, history is automatically appended as needed.

Parameters:

* *`f`*: Optional command entry mode to append history to. This is a function passed to
  `ui.command_entry_run()`. If omitted, uses the current or most recent mode.
* *`text`*: String text to append to history.

<a id="ui.command_entry.focus"></a>
#### `ui.command_entry.focus`()

Opens the command entry.

<a id="ui.command_entry.run"></a>
#### `ui.command_entry.run`(*f, keys, lang, height*)

Opens the command entry, subjecting it to any key bindings defined in table *keys*,
highlighting text with lexer name *lang*, and displaying *height* number of lines at a time,
and then when the `Enter` key is pressed, closes the command entry and calls function *f*
(if non-`nil`) with the command entry's text as an argument.
By default with no arguments given, opens a Lua command entry.
The command entry does not respond to Textadept's default key bindings, but instead to the
key bindings defined in *keys* and in `ui.command_entry.editing_keys`.

Parameters:

* *`f`*: Optional function to call upon pressing `Enter` in the command entry, ending the mode.
  It should accept the command entry text as an argument.
* *`keys`*: Optional table of key bindings to respond to. This is in addition to the
  basic editing and movement keys defined in `ui.command_entry.editing_keys`. `Esc` and
  `Enter` are automatically defined to cancel and finish the command entry, respectively.
  This parameter may be omitted completely.
* *`lang`*: Optional string lexer name to use for command entry text. The default value is
  `'text'`.
* *`height`*: Optional number of lines to display in the command entry. The default value is `1`.

Usage:

* `ui.command_entry.run(ui.print)`

See also:

* [`ui.command_entry.editing_keys`](#ui.command_entry.editing_keys)


### Tables defined by `ui.command_entry`

<a id="ui.command_entry.editing_keys"></a>
#### `ui.command_entry.editing_keys`

A metatable with typical platform-specific key bindings for text entries.
This metatable may be used to add basic editing and movement keys to command entry modes. It
is automatically added to command entry modes unless a metatable was previously set.

Usage:

* `setmetatable(mode_keys, ui.command_entry.editing_keys)`

---
<a id="ui.dialogs"></a>
## The `ui.dialogs` Module
---

Provides a set of interactive dialog prompts for user input.

### Functions defined by `ui.dialogs`

<a id="ui.dialogs.colorselect"></a>
#### `ui.dialogs.colorselect`(*options*)

Prompts the user with a color selection dialog defined by dialog options table *options*,
returning the color selected.
If the user canceled the dialog, returns `nil`.

Parameters:

* *`options`*: Table of key-value option pairs for the option select dialog.

  * `title`: The dialog's title text.
  * `color`: The initially selected color as either a number in "0xBBGGRR" format, or as a
    string in "#RRGGBB" format.
  * `palette`: The list of colors to show in the dialog's color palette. Up to 20 colors can
    be specified as either numbers in "0xBBGGRR" format or as strings in "#RRGGBB" format. If
    `true` (no list was given), a default palette is shown.
  * `string_output`: Return the selected color in string "#RRGGBB" format instead of as a
    number. The default value is `false`.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.

Usage:

* `ui.dialogs.colorselect{title = 'Foreground color', color = 0x000000,
  palette = {'#000000', 0x0000FF, '#00FF00', 0xFF0000}}`

Return:

* selected color

<a id="ui.dialogs.dropdown"></a>
#### `ui.dialogs.dropdown`(*options*)

Prompts the user with a drop-down item selection dialog defined by dialog options table
*options*, returning the selected button's index along with the index of the selected item.
If *options*.`string_output` is `true`, returns the selected button's label along with the
selected item's text. If the dialog closed due to *options*.`exit_onchange`, returns `4`
along with either the selected item's index or its text. If the dialog timed out, returns
`0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the drop-down dialog.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `items`: The list of string items to show in the drop-down.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `exit_onchange`: Close the dialog after selecting a new item. The default value is `false`.
  * `select`: The index of the initially selected list item. The default value is `1`.
  * `string_output`: Return the selected button's label (instead of its index) and the selected
    item's text (instead of its index). If no item was selected, returns the dialog's exit
    status (instead of its exit code). The default value is `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.dropdown{title = 'Select Encoding', width = 200, items = io.encodings,
  string_output = true}`

Return:

* selected button or exit code, selected item

<a id="ui.dialogs.filesave"></a>
#### `ui.dialogs.filesave`(*options*)

Prompts the user with a file save dialog defined by dialog options table *options*, returning
the string file chosen.
If the user canceled the dialog, returns `nil`.

Parameters:

* *`options`*: Table of key-value option pairs for the dialog.

  * `title`: The dialog's title text.
  * `with_directory`: The initial filesystem directory to show.
  * `with_file`: The initially chosen filename. This option requires `with_directory` to be set.
  * `with_extension`: The list of extensions selectable files must have.
  * `no_create_directories`: Prevent the user from creating new directories. The default
    value is `false`.

Return:

* filename or nil

<a id="ui.dialogs.fileselect"></a>
#### `ui.dialogs.fileselect`(*options*)

Prompts the user with a file selection dialog defined by dialog options table *options*,
returning the string file selected.
If *options*.`select_multiple` is `true`, returns the list of files selected. If the user
canceled the dialog, returns `nil`.

Parameters:

* *`options`*: Table of key-value option pairs for the dialog.

  * `title`: The dialog's title text.
  * `with_directory`: The initial filesystem directory to show.
  * `with_file`: The initially selected filename. This option requires `with_directory`
    to be set.
  * `with_extension`: The list of extensions selectable files must have.
  * `select_multiple`: Allow the user to select multiple files. The default value is `false`.
  * `select_only_directories`: Only allow the user to select directories. The default value is
    `false`.

Usage:

* `ui.dialogs.fileselect{title = 'Open C File', with_directory = _HOME,
  with_extension = {'c', 'h'}, select_multiple = true}`

Return:

* filename, list of filenames, or nil

<a id="ui.dialogs.filteredlist"></a>
#### `ui.dialogs.filteredlist`(*options*)

Prompts the user with a filtered list item selection dialog defined by dialog options table
*options*, returning the selected button's index along with the index or indices of the
selected item or items (depending on whether or not *options*.`select_multiple` is `true`).
If *options*.`string_output` is `true`, returns the selected button's label along with the
text of the selected item or items. If the dialog timed out, returns `0` or `"timeout"`. If
the user canceled the dialog, returns `-1` or `"delete"`.
Spaces in the filter text are treated as wildcards.

Parameters:

* *`options`*: Table of key-value option pairs for the filtered list dialog.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text.
  * `text`: The dialog's initial input text.
  * `columns`: The list of string column names for list rows.
  * `items`: The list of string items to show in the filtered list.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `select_multiple`: Allow the user to select multiple items. The default value is `false`.
  * `search_column`: The column number to filter the input text against. The default value is
    `1`. This option requires `columns` to be set and contain at least *n* column names.
  * `output_column`: The column number to use for `string_output`. The default value is
    `1`. This option requires `columns` to be set and contain at least *n* column names.
  * `string_output`: Return the selected button's label (instead of its index) and the selected
    item's text (instead of its index). If no item was selected, returns the dialog's exit
    status (instead of its exit code). The default value is `false`.
  * `width`: The dialog's pixel width. The default width stretches nearly the width of
    Textadept's window.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.filteredlist{title = 'Title', columns = {'Foo', 'Bar'},
  items = {'a', 'b', 'c', 'd'}}`

Return:

* selected button or exit code, selected item or list of selected items

<a id="ui.dialogs.fontselect"></a>
#### `ui.dialogs.fontselect`(*options*)

Prompts the user with a font selection dialog defined by dialog options table *options*,
returning the font selected (including style and size).
If the user canceled the dialog, returns `nil`.

Parameters:

* *`options`*: Table of key-value option pairs for the option select dialog.

  * `title`: The dialog's title text.
  * `text`: The font preview text.
  * `font_name`: The initially selected font name.
  * `font_size`: The initially selected font size. The default value is `12`.
  * `font_style`: The initially selected font style. The available options are `"regular"`,
    `"bold"`, `"italic"`, and `"bold italic"`. The default value is `"regular"`.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.

Usage:

* `ui.dialogs.fontselect{title = 'Font', font_name = 'Monospace', font_size = 10}`

Return:

* selected font, including style and size

<a id="ui.dialogs.inputbox"></a>
#### `ui.dialogs.inputbox`(*options*)

Prompts the user with an inputbox dialog defined by dialog options table *options*, returning
the selected button's index along with the user's input text (the latter as a string or table,
depending on the type of *options*.`informative_text`).
If *options*.`string_output` is `true`, returns the selected button's label along with the
user's input text. If the dialog timed out, returns `0` or `"timeout"`. If the user canceled
the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the inputbox.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text. If the value is a table, the first
    table value is the main message text and any subsequent values are used as the labels
    for multiple entry boxes. Providing a single label has no effect.
  * `text`: The dialog's initial input text. If the value is a table, the table values are
    used to populate the multiple entry boxes defined by `informative_text`.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.inputbox{title = 'Goto Line', informative_text = 'Line:',
  text = '1'}`

Return:

* selected button or exit code, input text

<a id="ui.dialogs.msgbox"></a>
#### `ui.dialogs.msgbox`(*options*)

Prompts the user with a generic message box dialog defined by dialog options table *options*,
returning the selected button's index.
If *options*.`string_output` is `true`, returns the selected button's label. If the dialog timed
out, returns `0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the message box.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `informative_text`: The dialog's extra informative text.
  * `icon`: The dialog's icon name, according to the Free Desktop Icon Naming
    Specification. Examples are "dialog-error", "dialog-information", "dialog-question",
    and "dialog-warning". The dialog does not display an icon by default.
  * `icon_file`: The dialog's icon file path. This option has no effect when `icon` is set.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.msgbox{title = 'EOL Mode', text = 'Which EOL?',
  icon = 'dialog-question', button1 = 'CRLF', button2 = 'CR',
  button3 = 'LF'}`

Return:

* selected button or exit code

<a id="ui.dialogs.ok_msgbox"></a>
#### `ui.dialogs.ok_msgbox`(*options*)

Prompts the user with a generic message box dialog defined by dialog options table *options*
and with localized "Ok" and "Cancel" buttons, returning the selected button's index.
If *options*.`string_output` is `true`, returns the selected button's label. If the dialog timed
out, returns `0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the message box.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `informative_text`: The dialog's extra informative text.
  * `icon`: The dialog's icon name, according to the Free Desktop Icon Naming
    Specification. Examples are "dialog-error", "dialog-information", "dialog-question",
    and "dialog-warning". The dialog does not display an icon by default.
  * `icon_file`: The dialog's icon file path. This option has no effect when `icon` is set.
  * `no_cancel`: Do not display the "Cancel" button. The default value is `false`.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code

<a id="ui.dialogs.optionselect"></a>
#### `ui.dialogs.optionselect`(*options*)

Prompts the user with an option selection dialog defined by dialog options table *options*,
returning the selected button's index along with the indices of the selected options.
If *options*.`string_output` is `true`, returns the selected button's label along with the
text of the selected options. If the dialog timed out, returns `0` or `"timeout"`. If the
user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the option select dialog.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `items`: The list of string options to show in the option group.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `select`: The indices of initially selected options.
  * `string_output`: Return the selected button's label or the dialog's exit status along
    with the selected options' text instead of the button's index or the dialog's exit code
    along with the options' indices. The default value is `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.optionselect{title = 'Language',
  informative_text = 'Check the languages you understand',
  items = {'English', 'Romanian'}, select = 1, string_output = true}`

Return:

* selected button or exit code, list of selected options

<a id="ui.dialogs.progressbar"></a>
#### `ui.dialogs.progressbar`(*options, f*)

Displays a progressbar dialog, defined by dialog options table *options*, that receives
updates from function *f*.
Returns "stopped" if *options*.`stoppable` is `true` and the user clicked the "Stop"
button. Otherwise, returns `nil`.

Parameters:

* *`options`*: Table of key-value option pairs for the progressbar dialog.

  * `title`: The dialog's title text.
  * `percent`: The initial progressbar percentage between 0 and 100.
  * `text`: The initial progressbar display text (GTK only).
  * `indeterminate`: Show the progress bar as "busy", with no percentage updates.
  * `stoppable`: Show the "Stop" button.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
* *`f`*: Function repeatedly called to do work and provide progress updates. The function is
  called without arguments and must return either `nil`, which indicates work is complete,
  or a progress percentage number in the range 0-100 and an optional string to display (GTK
  only). If the text is either "stop disable" or "stop enable" and *options*.`stoppable` is
  `true`, the "Stop" button is disabled or enabled, respectively.

Usage:

* `ui.dialogs.progressbar({stoppable = true},
  function() if work() then return percent, status else return nil end end)`

Return:

* nil or "stopped"

<a id="ui.dialogs.secure_inputbox"></a>
#### `ui.dialogs.secure_inputbox`(*options*)

Prompts the user with a masked inputbox dialog defined by dialog options table *options*,
returning the selected button's index along with the user's input text (the latter as a
string or table, depending on the type of *options*.`informative_text`).
If *options*.`string_output` is `true`, returns the selected button's label along with the
user's input text. If the dialog timed out, returns `0` or `"timeout"`. If the user canceled
the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the inputbox.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text. If the value is a table, the first
    table value is the main message text and any subsequent values are used as the labels
    for multiple entry boxes. Providing a single label has no effect.
  * `text`: The dialog's initial input text. If the value is a table, the table values are
    used to populate the multiple entry boxes defined by `informative_text`.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code, input text

<a id="ui.dialogs.secure_standard_inputbox"></a>
#### `ui.dialogs.secure_standard_inputbox`(*options*)

Prompts the user with a masked inputbox dialog defined by dialog options table *options*
and with localized "Ok" and "Cancel" buttons, returning the selected button's index along
with the user's input text (the latter as a string or table, depending on the type of
*options*.`informative_text`).
If *options*.`string_output` is `true`, returns the selected button's label along with the
user's input text. If the dialog timed out, returns `0` or `"timeout"`. If the user canceled
the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the inputbox.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text. If the value is a table, the first
    table value is the main message text and any subsequent values are used as the labels
    for multiple entry boxes. Providing a single label has no effect.
  * `text`: The dialog's initial input text. If the value is a table, the table values are
    used to populate the multiple entry boxes defined by `informative_text`.
  * `no_cancel`: Do not display the "Cancel" button. The default value is `false`.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code, input text

<a id="ui.dialogs.standard_dropdown"></a>
#### `ui.dialogs.standard_dropdown`(*options*)

Prompts the user with a drop-down item selection dialog defined by dialog options table
*options* and with localized "Ok" and "Cancel" buttons, returning the selected button's
index along with the selected item's index.
If *options*.`string_output` is `true`, returns the selected button's label along with the
selected item's text. If the dialog closed due to *options*.`exit_onchange`, returns `4`
along with either the selected item's index or its text. If the dialog timed out, returns
`0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the drop-down dialog.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `items`: The list of string items to show in the drop-down.
  * `no_cancel`: Do not display the "Cancel" button. The default value is `false`.
  * `exit_onchange`: Close the dialog after selecting a new item. The default value is `false`.
  * `select`: The index of the initially selected list item. The default value is `1`.
  * `string_output`: Return the selected button's label (instead of its index) and the selected
    item's text (instead of its index). If no item was selected, returns the dialog's exit
    status (instead of its exit code). The default value is `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code, selected item

<a id="ui.dialogs.standard_inputbox"></a>
#### `ui.dialogs.standard_inputbox`(*options*)

Prompts the user with an inputbox dialog defined by dialog options table *options* and
with localized "Ok" and "Cancel" buttons, returning the selected button's index along
with the user's input text (the latter as a string or table, depending on the type of
*options*.`informative_text`).
If *options*.`string_output` is `true`, returns the selected button's label along with the
user's input text. If the dialog timed out, returns `0` or `"timeout"`. If the user canceled
the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the inputbox.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text. If the value is a table, the first
    table value is the main message text and any subsequent values are used as the labels
    for multiple entry boxes. Providing a single label has no effect.
  * `text`: The dialog's initial input text. If the value is a table, the table values are
    used to populate the multiple entry boxes defined by `informative_text`.
  * `no_cancel`: Do not display the "Cancel" button. The default value is `false`.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code, input text

<a id="ui.dialogs.textbox"></a>
#### `ui.dialogs.textbox`(*options*)

Prompts the user with a multiple-line textbox dialog defined by dialog options table *options*,
returning the selected button's index.
If *options*.`string_output` is `true`, returns the selected button's label. If
*options*.`editable` is `true`, also returns the textbox's text. If the dialog timed out,
returns `0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the dialog.

  * `title`: The dialog's title text.
  * `informative_text`: The dialog's main message text.
  * `text`: The dialog's initial textbox text.
  * `text_from_file`: The filename whose contents are loaded into the textbox. This option
    has no effect when `text` is given.
  * `button1`: The right-most button's label. The default value is `_L['OK']`.
  * `button2`: The middle button's label.
  * `button3`: The left-most button's label. This option requires `button2` to be set.
  * `editable`: Allows the user to edit the textbox's text. The default value is `false`.
  * `focus_textbox`: Focus the textbox instead of the buttons. The default value is `false`.
  * `scroll_to`: Where to scroll the textbox's text. The available values are `"top"` and
    `"bottom"`. The default value is `"top"`.
  * `selected`: Select all of the textbox's text. The default value is `false`.
  * `monospaced_font`: Use a monospaced font in the textbox instead of a proportional one. The
    default value is `false`.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Usage:

* `ui.dialogs.textbox{title = 'License Agreement', informative_text = 'You agree to:',
  text_from_file = _HOME..'/LICENSE'}`

Return:

* selected button or exit code, textbox text

<a id="ui.dialogs.yesno_msgbox"></a>
#### `ui.dialogs.yesno_msgbox`(*options*)

Prompts the user with a generic message box dialog defined by dialog options table *options*
and with localized "Yes", "No", and "Cancel" buttons, returning the selected button's index.
If *options*.`string_output` is `true`, returns the selected button's label. If the dialog timed
out, returns `0` or `"timeout"`. If the user canceled the dialog, returns `-1` or `"delete"`.

Parameters:

* *`options`*: Table of key-value option pairs for the message box.

  * `title`: The dialog's title text.
  * `text`: The dialog's main message text.
  * `informative_text`: The dialog's extra informative text.
  * `icon`: The dialog's icon name, according to the Free Desktop Icon Naming
    Specification. Examples are "dialog-error", "dialog-information", "dialog-question",
    and "dialog-warning". The dialog does not display an icon by default.
  * `icon_file`: The dialog's icon file path. This option has no effect when `icon` is set.
  * `no_cancel`: Do not display the "Cancel" button. The default value is `false`.
  * `string_output`: Return the selected button's label (instead of its index) or the dialog's
    exit status instead of the button's index (instead of its exit code). The default value is
    `false`.
  * `width`: The dialog's pixel width.
  * `height`: The dialog's pixel height.
  * `float`: Show the dialog on top of all desktop windows. The default value is `false`.
  * `timeout`: The integer number of seconds the dialog waits for the user to select a button
    before timing out. Dialogs do not time out by default.

Return:

* selected button or exit code


---
<a id="ui.find"></a>
## The `ui.find` Module
---

Textadept's Find & Replace pane.

### Fields defined by `ui.find`

<a id="ui.find.INDIC_FIND"></a>
#### `ui.find.INDIC_FIND` (number)

The find results highlight indicator number.

<a id="events.FIND_RESULT_FOUND"></a>
#### `events.FIND_RESULT_FOUND` (string)

Emitted when a result is found. It is selected and has been scrolled into view.
  Arguments:

  * _`find_text`_: The text originally searched for.
  * _`wrapped`_: Whether or not the result found is after a text search wrapped.

<a id="events.FIND_WRAPPED"></a>
#### `events.FIND_WRAPPED` (string)

Emitted when a text search wraps (passes through the beginning of the buffer), either
  from bottom to top (when searching for a next occurrence), or from top to bottom (when
  searching for a previous occurrence).
  This is useful for implementing a more visual or audible notice when a search wraps in
  addition to the statusbar message.

<a id="ui.find.active"></a>
#### `ui.find.active` (boolean)

Whether or not the Find & Replace pane is active.

<a id="ui.find.entry_font"></a>
#### `ui.find.entry_font` (string, Write-only)

The font to use in the "Find" and "Replace" entries in "name size" format.
  The default value is system-dependent.

<a id="ui.find.find_entry_text"></a>
#### `ui.find.find_entry_text` (string)

The text in the "Find" entry.

<a id="ui.find.find_label_text"></a>
#### `ui.find.find_label_text` (string, Write-only)

The text of the "Find" label.
  This is primarily used for localization.

<a id="ui.find.find_next_button_text"></a>
#### `ui.find.find_next_button_text` (string, Write-only)

The text of the "Find Next" button.
  This is primarily used for localization.

<a id="ui.find.find_prev_button_text"></a>
#### `ui.find.find_prev_button_text` (string, Write-only)

The text of the "Find Prev" button.
  This is primarily used for localization.

<a id="ui.find.highlight_all_matches"></a>
#### `ui.find.highlight_all_matches` (boolean)

Whether or not to highlight all occurrences of found text in the current buffer.
  The default value is `false`.

<a id="ui.find.in_files"></a>
#### `ui.find.in_files` (bool)

Find search text in a directory of files.
  The default value is `false`.

<a id="ui.find.in_files_label_text"></a>
#### `ui.find.in_files_label_text` (string, Write-only)

The text of the "In files" label.
  This is primarily used for localization.

<a id="ui.find.incremental"></a>
#### `ui.find.incremental` (bool)

Find search text incrementally as it is typed.
  The default value is `false`.

<a id="ui.find.match_case"></a>
#### `ui.find.match_case` (bool)

Match search text case sensitively.
  The default value is `false`.

<a id="ui.find.match_case_label_text"></a>
#### `ui.find.match_case_label_text` (string, Write-only)

The text of the "Match case" label.
  This is primarily used for localization.

<a id="ui.find.regex"></a>
#### `ui.find.regex` (bool)

Interpret search text as a Regular Expression.
  The default value is `false`.

<a id="ui.find.regex_label_text"></a>
#### `ui.find.regex_label_text` (string, Write-only)

The text of the "Regex" label.
  This is primarily used for localization.

<a id="ui.find.replace_all_button_text"></a>
#### `ui.find.replace_all_button_text` (string, Write-only)

The text of the "Replace All" button.
  This is primarily used for localization.

<a id="ui.find.replace_button_text"></a>
#### `ui.find.replace_button_text` (string, Write-only)

The text of the "Replace" button.
  This is primarily used for localization.

<a id="ui.find.replace_entry_text"></a>
#### `ui.find.replace_entry_text` (string)

The text in the "Replace" entry.
  When searching for text in a directory of files, this is the current file and directory filter.

<a id="ui.find.replace_label_text"></a>
#### `ui.find.replace_label_text` (string, Write-only)

The text of the "Replace" label.
  This is primarily used for localization.

<a id="ui.find.show_filenames_in_progressbar"></a>
#### `ui.find.show_filenames_in_progressbar` (boolean)

Whether to show filenames in the find in files search progressbar.
  This can be useful for determining whether or not custom filters are working as expected.
  Showing filenames can slow down searches on computers with really fast SSDs.
  The default value is `true`.

<a id="ui.find.whole_word"></a>
#### `ui.find.whole_word` (bool)

Match search text only when it is surrounded by non-word characters in searches.
  The default value is `false`.

<a id="ui.find.whole_word_label_text"></a>
#### `ui.find.whole_word_label_text` (string, Write-only)

The text of the "Whole word" label.
  This is primarily used for localization.


### Functions defined by `ui.find`

<a id="ui.find.find_in_files"></a>
#### `ui.find.find_in_files`(*dir, filter*)

Searches directory *dir* or the user-specified directory for files that match search text
and search options (subject to optional filter *filter*), and prints the results to a buffer
titled "Files Found", highlighting found text.
Use the `find_entry_text`, `match_case`, `whole_word`, and `regex` fields to set the search
text and option flags, respectively.
A filter determines which files to search in, with the default filter being
`ui.find.find_in_files_filters[dir]` (if it exists) or `lfs.default_filter`. A filter consists
of Lua patterns that match file and directory paths to include or exclude. Patterns are
inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are given,
any filename is initially considered. As a convenience, file extensions can be specified
literally instead of as a Lua pattern (e.g. '.lua' vs. '%.lua$'), and '/' also matches the
Windows directory separator ('[/\\]' is not needed). If *filter* is `nil`, the filter from
the `ui.find.find_in_files_filters` table for *dir* is used. If that filter does not exist,
`lfs.default_filter` is used.

Parameters:

* *`dir`*: Optional directory path to search. If `nil`, the user is prompted for one.
* *`filter`*: Optional filter for files and directories to exclude. The default value is
  `lfs.default_filter` unless a filter for *dir* is defined in `ui.find.find_in_files_filters`.

See also:

* [`ui.find.find_in_files_filters`](#ui.find.find_in_files_filters)

<a id="ui.find.find_next"></a>
#### `ui.find.find_next`()

Mimics pressing the "Find Next" button.

<a id="ui.find.find_prev"></a>
#### `ui.find.find_prev`()

Mimics pressing the "Find Prev" button.

<a id="ui.find.focus"></a>
#### `ui.find.focus`(*options*)

Displays and focuses the Find & Replace Pane.

Parameters:

* *`options`*: Optional table of `ui.find` field options to initially set.

<a id="ui.find.goto_file_found"></a>
#### `ui.find.goto_file_found`(*line\_num, next*)

Jumps to the source of the find in files search result on line number *line_num* in the buffer
titled "Files Found" or, if *line_num* is `nil`, jumps to the next or previous search result,
depending on boolean *next*.

Parameters:

* *`line_num`*: Optional line number in the files found buffer that contains the search
  result to go to. This parameter may be omitted completely.
* *`next`*: Optional flag indicating whether to go to the next search result or the previous
  one. Only applicable when *line_num* is `nil`.

<a id="ui.find.replace"></a>
#### `ui.find.replace`()

Mimics pressing the "Replace" button.

<a id="ui.find.replace_all"></a>
#### `ui.find.replace_all`()

Mimics pressing the "Replace All" button.


### Tables defined by `ui.find`

<a id="ui.find.find_in_files_filters"></a>
#### `ui.find.find_in_files_filters`

Map of directory paths to filters used in `ui.find.find_in_files()`.
This table is updated when the user manually specifies a filter in the "Filter" entry during
an "In files" search.

See also:

* [`ui.find.find_in_files`](#ui.find.find_in_files)

---
<a id="view"></a>
## The `view` Module
---

A Textadept view object.
Constants are documented in the fields they apply to.
While you can work with individual view instances, it is often useful to work with just the
global one.
Many of these functions and fields are derived from view-specific functionality of the
Scintilla editing component, and additional information can be found on the [Scintilla
website](https://scintilla.org/ScintillaDoc.html). Note that with regard to Scintilla-specific
functionality, this API is a _suggestion_, not a hard requirement. All of that functionality
also exists in [`buffer`](#buffer), even if undocumented.
Any view fields set on startup (e.g. in *~/.textadept/init.lua*) will be the default,
initial values for all views.

### Fields defined by `view`

<a id="view.ALPHA_NOALPHA"></a>
#### `view.ALPHA_NOALPHA` (number, Read-only)




<a id="view.ALPHA_OPAQUE"></a>
#### `view.ALPHA_OPAQUE` (number, Read-only)




<a id="view.ALPHA_TRANSPARENT"></a>
#### `view.ALPHA_TRANSPARENT` (number, Read-only)




<a id="view.ANNOTATION_BOXED"></a>
#### `view.ANNOTATION_BOXED` (number, Read-only)




<a id="view.ANNOTATION_HIDDEN"></a>
#### `view.ANNOTATION_HIDDEN` (number, Read-only)




<a id="view.ANNOTATION_INDENTED"></a>
#### `view.ANNOTATION_INDENTED` (number, Read-only)




<a id="view.ANNOTATION_STANDARD"></a>
#### `view.ANNOTATION_STANDARD` (number, Read-only)




<a id="view.CARETSTYLE_BLOCK"></a>
#### `view.CARETSTYLE_BLOCK` (number, Read-only)




<a id="view.CARETSTYLE_INVISIBLE"></a>
#### `view.CARETSTYLE_INVISIBLE` (number, Read-only)




<a id="view.CARETSTYLE_LINE"></a>
#### `view.CARETSTYLE_LINE` (number, Read-only)




<a id="view.CARET_EVEN"></a>
#### `view.CARET_EVEN` (number, Read-only)




<a id="view.CARET_JUMPS"></a>
#### `view.CARET_JUMPS` (number, Read-only)




<a id="view.CARET_SLOP"></a>
#### `view.CARET_SLOP` (number, Read-only)




<a id="view.CARET_STRICT"></a>
#### `view.CARET_STRICT` (number, Read-only)




<a id="view.CASE_CAMEL"></a>
#### `view.CASE_CAMEL` (number, Read-only)




<a id="view.CASE_LOWER"></a>
#### `view.CASE_LOWER` (number, Read-only)




<a id="view.CASE_MIXED"></a>
#### `view.CASE_MIXED` (number, Read-only)




<a id="view.CASE_UPPER"></a>
#### `view.CASE_UPPER` (number, Read-only)




<a id="view.CURSORARROW"></a>
#### `view.CURSORARROW` (number, Read-only)




<a id="view.CURSORNORMAL"></a>
#### `view.CURSORNORMAL` (number, Read-only)




<a id="view.CURSORREVERSEARROW"></a>
#### `view.CURSORREVERSEARROW` (number, Read-only)




<a id="view.CURSORWAIT"></a>
#### `view.CURSORWAIT` (number, Read-only)




<a id="view.EDGE_BACKGROUND"></a>
#### `view.EDGE_BACKGROUND` (number, Read-only)




<a id="view.EDGE_LINE"></a>
#### `view.EDGE_LINE` (number, Read-only)




<a id="view.EDGE_MULTILINE"></a>
#### `view.EDGE_MULTILINE` (number, Read-only)




<a id="view.EDGE_NONE"></a>
#### `view.EDGE_NONE` (number, Read-only)




<a id="view.ELEMENT_CARET"></a>
#### `view.ELEMENT_CARET` (number, Read-only)




<a id="view.ELEMENT_CARET_ADDITIONAL"></a>
#### `view.ELEMENT_CARET_ADDITIONAL` (number, Read-only)




<a id="view.ELEMENT_CARET_LINE_BACK"></a>
#### `view.ELEMENT_CARET_LINE_BACK` (number, Read-only)




<a id="view.ELEMENT_SELECTION_ADDITIONAL_BACK"></a>
#### `view.ELEMENT_SELECTION_ADDITIONAL_BACK` (number, Read-only)




<a id="view.ELEMENT_SELECTION_ADDITIONAL_TEXT"></a>
#### `view.ELEMENT_SELECTION_ADDITIONAL_TEXT` (number, Read-only)




<a id="view.ELEMENT_SELECTION_BACK"></a>
#### `view.ELEMENT_SELECTION_BACK` (number, Read-only)




<a id="view.ELEMENT_SELECTION_INACTIVE_BACK"></a>
#### `view.ELEMENT_SELECTION_INACTIVE_BACK` (number, Read-only)




<a id="view.ELEMENT_SELECTION_INACTIVE_TEXT"></a>
#### `view.ELEMENT_SELECTION_INACTIVE_TEXT` (number, Read-only)




<a id="view.ELEMENT_SELECTION_SECONDARY_BACK"></a>
#### `view.ELEMENT_SELECTION_SECONDARY_BACK` (number, Read-only)




<a id="view.ELEMENT_SELECTION_SECONDARY_TEXT"></a>
#### `view.ELEMENT_SELECTION_SECONDARY_TEXT` (number, Read-only)




<a id="view.ELEMENT_SELECTION_TEXT"></a>
#### `view.ELEMENT_SELECTION_TEXT` (number, Read-only)




<a id="view.ELEMENT_WHITE_SPACE"></a>
#### `view.ELEMENT_WHITE_SPACE` (number, Read-only)




<a id="view.ELEMENT_WHITE_SPACE_BACK"></a>
#### `view.ELEMENT_WHITE_SPACE_BACK` (number, Read-only)




<a id="view.FOLDACTION_CONTRACT"></a>
#### `view.FOLDACTION_CONTRACT` (number, Read-only)




<a id="view.FOLDACTION_EXPAND"></a>
#### `view.FOLDACTION_EXPAND` (number, Read-only)




<a id="view.FOLDACTION_TOGGLE"></a>
#### `view.FOLDACTION_TOGGLE` (number, Read-only)




<a id="view.FOLDDISPLAYTEXT_BOXED"></a>
#### `view.FOLDDISPLAYTEXT_BOXED` (number, Read-only)




<a id="view.FOLDDISPLAYTEXT_HIDDEN"></a>
#### `view.FOLDDISPLAYTEXT_HIDDEN` (number, Read-only)




<a id="view.FOLDDISPLAYTEXT_STANDARD"></a>
#### `view.FOLDDISPLAYTEXT_STANDARD` (number, Read-only)




<a id="view.FOLDFLAG_LEVELNUMBERS"></a>
#### `view.FOLDFLAG_LEVELNUMBERS` (number, Read-only)




<a id="view.FOLDFLAG_LINEAFTER_CONTRACTED"></a>
#### `view.FOLDFLAG_LINEAFTER_CONTRACTED` (number, Read-only)




<a id="view.FOLDFLAG_LINEAFTER_EXPANDED"></a>
#### `view.FOLDFLAG_LINEAFTER_EXPANDED` (number, Read-only)




<a id="view.FOLDFLAG_LINEBEFORE_CONTRACTED"></a>
#### `view.FOLDFLAG_LINEBEFORE_CONTRACTED` (number, Read-only)




<a id="view.FOLDFLAG_LINEBEFORE_EXPANDED"></a>
#### `view.FOLDFLAG_LINEBEFORE_EXPANDED` (number, Read-only)




<a id="view.FOLDFLAG_LINESTATE"></a>
#### `view.FOLDFLAG_LINESTATE` (number, Read-only)




<a id="view.INDIC_BOX"></a>
#### `view.INDIC_BOX` (number, Read-only)




<a id="view.INDIC_COMPOSITIONTHICK"></a>
#### `view.INDIC_COMPOSITIONTHICK` (number, Read-only)




<a id="view.INDIC_COMPOSITIONTHIN"></a>
#### `view.INDIC_COMPOSITIONTHIN` (number, Read-only)




<a id="view.INDIC_DASH"></a>
#### `view.INDIC_DASH` (number, Read-only)




<a id="view.INDIC_DIAGONAL"></a>
#### `view.INDIC_DIAGONAL` (number, Read-only)




<a id="view.INDIC_DOTBOX"></a>
#### `view.INDIC_DOTBOX` (number, Read-only)




<a id="view.INDIC_DOTS"></a>
#### `view.INDIC_DOTS` (number, Read-only)




<a id="view.INDIC_FULLBOX"></a>
#### `view.INDIC_FULLBOX` (number, Read-only)




<a id="view.INDIC_GRADIENT"></a>
#### `view.INDIC_GRADIENT` (number, Read-only)




<a id="view.INDIC_GRADIENTCENTER"></a>
#### `view.INDIC_GRADIENTCENTER` (number, Read-only)




<a id="view.INDIC_HIDDEN"></a>
#### `view.INDIC_HIDDEN` (number, Read-only)




<a id="view.INDIC_PLAIN"></a>
#### `view.INDIC_PLAIN` (number, Read-only)




<a id="view.INDIC_POINT"></a>
#### `view.INDIC_POINT` (number, Read-only)




<a id="view.INDIC_POINTCHARACTER"></a>
#### `view.INDIC_POINTCHARACTER` (number, Read-only)




<a id="view.INDIC_ROUNDBOX"></a>
#### `view.INDIC_ROUNDBOX` (number, Read-only)




<a id="view.INDIC_SQUIGGLE"></a>
#### `view.INDIC_SQUIGGLE` (number, Read-only)




<a id="view.INDIC_SQUIGGLELOW"></a>
#### `view.INDIC_SQUIGGLELOW` (number, Read-only)




<a id="view.INDIC_SQUIGGLEPIXMAP"></a>
#### `view.INDIC_SQUIGGLEPIXMAP` (number, Read-only)




<a id="view.INDIC_STRAIGHTBOX"></a>
#### `view.INDIC_STRAIGHTBOX` (number, Read-only)




<a id="view.INDIC_STRIKE"></a>
#### `view.INDIC_STRIKE` (number, Read-only)




<a id="view.INDIC_TEXTFORE"></a>
#### `view.INDIC_TEXTFORE` (number, Read-only)




<a id="view.INDIC_TT"></a>
#### `view.INDIC_TT` (number, Read-only)




<a id="view.IV_LOOKBOTH"></a>
#### `view.IV_LOOKBOTH` (number, Read-only)




<a id="view.IV_LOOKFORWARD"></a>
#### `view.IV_LOOKFORWARD` (number, Read-only)




<a id="view.IV_NONE"></a>
#### `view.IV_NONE` (number, Read-only)




<a id="view.IV_REAL"></a>
#### `view.IV_REAL` (number, Read-only)




<a id="view.MARGINOPTION_NONE"></a>
#### `view.MARGINOPTION_NONE` (number, Read-only)




<a id="view.MARGINOPTION_SUBLINESELECT"></a>
#### `view.MARGINOPTION_SUBLINESELECT` (number, Read-only)




<a id="view.MARGIN_BACK"></a>
#### `view.MARGIN_BACK` (number, Read-only)




<a id="view.MARGIN_COLOR"></a>
#### `view.MARGIN_COLOR` (number, Read-only)




<a id="view.MARGIN_FORE"></a>
#### `view.MARGIN_FORE` (number, Read-only)




<a id="view.MARGIN_NUMBER"></a>
#### `view.MARGIN_NUMBER` (number, Read-only)




<a id="view.MARGIN_RTEXT"></a>
#### `view.MARGIN_RTEXT` (number, Read-only)




<a id="view.MARGIN_SYMBOL"></a>
#### `view.MARGIN_SYMBOL` (number, Read-only)




<a id="view.MARGIN_TEXT"></a>
#### `view.MARGIN_TEXT` (number, Read-only)




<a id="view.MARK_ARROW"></a>
#### `view.MARK_ARROW` (number, Read-only)




<a id="view.MARK_ARROWDOWN"></a>
#### `view.MARK_ARROWDOWN` (number, Read-only)




<a id="view.MARK_ARROWS"></a>
#### `view.MARK_ARROWS` (number, Read-only)




<a id="view.MARK_BACKGROUND"></a>
#### `view.MARK_BACKGROUND` (number, Read-only)




<a id="view.MARK_BOOKMARK"></a>
#### `view.MARK_BOOKMARK` (number, Read-only)




<a id="view.MARK_BOXMINUS"></a>
#### `view.MARK_BOXMINUS` (number, Read-only)




<a id="view.MARK_BOXMINUSCONNECTED"></a>
#### `view.MARK_BOXMINUSCONNECTED` (number, Read-only)




<a id="view.MARK_BOXPLUS"></a>
#### `view.MARK_BOXPLUS` (number, Read-only)




<a id="view.MARK_BOXPLUSCONNECTED"></a>
#### `view.MARK_BOXPLUSCONNECTED` (number, Read-only)




<a id="view.MARK_CHARACTER"></a>
#### `view.MARK_CHARACTER` (number, Read-only)




<a id="view.MARK_CIRCLE"></a>
#### `view.MARK_CIRCLE` (number, Read-only)




<a id="view.MARK_CIRCLEMINUS"></a>
#### `view.MARK_CIRCLEMINUS` (number, Read-only)




<a id="view.MARK_CIRCLEMINUSCONNECTED"></a>
#### `view.MARK_CIRCLEMINUSCONNECTED` (number, Read-only)




<a id="view.MARK_CIRCLEPLUS"></a>
#### `view.MARK_CIRCLEPLUS` (number, Read-only)




<a id="view.MARK_CIRCLEPLUSCONNECTED"></a>
#### `view.MARK_CIRCLEPLUSCONNECTED` (number, Read-only)




<a id="view.MARK_DOTDOTDOT"></a>
#### `view.MARK_DOTDOTDOT` (number, Read-only)




<a id="view.MARK_EMPTY"></a>
#### `view.MARK_EMPTY` (number, Read-only)




<a id="view.MARK_FULLRECT"></a>
#### `view.MARK_FULLRECT` (number, Read-only)




<a id="view.MARK_LCORNER"></a>
#### `view.MARK_LCORNER` (number, Read-only)




<a id="view.MARK_LCORNERCURVE"></a>
#### `view.MARK_LCORNERCURVE` (number, Read-only)




<a id="view.MARK_LEFTRECT"></a>
#### `view.MARK_LEFTRECT` (number, Read-only)




<a id="view.MARK_MINUS"></a>
#### `view.MARK_MINUS` (number, Read-only)




<a id="view.MARK_PIXMAP"></a>
#### `view.MARK_PIXMAP` (number, Read-only)




<a id="view.MARK_PLUS"></a>
#### `view.MARK_PLUS` (number, Read-only)




<a id="view.MARK_RGBAIMAGE"></a>
#### `view.MARK_RGBAIMAGE` (number, Read-only)




<a id="view.MARK_ROUNDRECT"></a>
#### `view.MARK_ROUNDRECT` (number, Read-only)




<a id="view.MARK_SHORTARROW"></a>
#### `view.MARK_SHORTARROW` (number, Read-only)




<a id="view.MARK_SMALLRECT"></a>
#### `view.MARK_SMALLRECT` (number, Read-only)




<a id="view.MARK_TCORNER"></a>
#### `view.MARK_TCORNER` (number, Read-only)




<a id="view.MARK_TCORNERCURVE"></a>
#### `view.MARK_TCORNERCURVE` (number, Read-only)




<a id="view.MARK_UNDERLINE"></a>
#### `view.MARK_UNDERLINE` (number, Read-only)




<a id="view.MARK_VERTICALBOOKMARK"></a>
#### `view.MARK_VERTICALBOOKMARK` (number, Read-only)




<a id="view.MARK_VLINE"></a>
#### `view.MARK_VLINE` (number, Read-only)




<a id="view.MASK_FOLDERS"></a>
#### `view.MASK_FOLDERS` (number, Read-only)




<a id="view.MOD_ALT"></a>
#### `view.MOD_ALT` (number, Read-only)




<a id="view.MOD_CTRL"></a>
#### `view.MOD_CTRL` (number, Read-only)




<a id="view.MOD_META"></a>
#### `view.MOD_META` (number, Read-only)




<a id="view.MOD_SHIFT"></a>
#### `view.MOD_SHIFT` (number, Read-only)




<a id="view.MOD_SUPER"></a>
#### `view.MOD_SUPER` (number, Read-only)




<a id="view.MOUSE_DRAG"></a>
#### `view.MOUSE_DRAG` (number, Read-only)




<a id="view.MOUSE_PRESS"></a>
#### `view.MOUSE_PRESS` (number, Read-only)




<a id="view.MOUSE_RELEASE"></a>
#### `view.MOUSE_RELEASE` (number, Read-only)




<a id="view.STYLE_BRACEBAD"></a>
#### `view.STYLE_BRACEBAD` (number, Read-only)




<a id="view.STYLE_BRACELIGHT"></a>
#### `view.STYLE_BRACELIGHT` (number, Read-only)




<a id="view.STYLE_CALLTIP"></a>
#### `view.STYLE_CALLTIP` (number, Read-only)




<a id="view.STYLE_CONTROLCHAR"></a>
#### `view.STYLE_CONTROLCHAR` (number, Read-only)




<a id="view.STYLE_DEFAULT"></a>
#### `view.STYLE_DEFAULT` (number, Read-only)




<a id="view.STYLE_FOLDDISPLAYTEXT"></a>
#### `view.STYLE_FOLDDISPLAYTEXT` (number, Read-only)




<a id="view.STYLE_INDENTGUIDE"></a>
#### `view.STYLE_INDENTGUIDE` (number, Read-only)




<a id="view.STYLE_LINENUMBER"></a>
#### `view.STYLE_LINENUMBER` (number, Read-only)




<a id="view.STYLE_MAX"></a>
#### `view.STYLE_MAX` (number, Read-only)




<a id="view.TD_LONGARROW"></a>
#### `view.TD_LONGARROW` (number, Read-only)




<a id="view.TD_STRIKEOUT"></a>
#### `view.TD_STRIKEOUT` (number, Read-only)




<a id="view.TIME_FOREVER"></a>
#### `view.TIME_FOREVER` (number, Read-only)




<a id="view.UPDATE_H_SCROLL"></a>
#### `view.UPDATE_H_SCROLL` (number, Read-only)




<a id="view.UPDATE_NONE"></a>
#### `view.UPDATE_NONE` (number, Read-only)




<a id="view.UPDATE_V_SCROLL"></a>
#### `view.UPDATE_V_SCROLL` (number, Read-only)




<a id="view.VISIBLE_SLOP"></a>
#### `view.VISIBLE_SLOP` (number, Read-only)




<a id="view.VISIBLE_STRICT"></a>
#### `view.VISIBLE_STRICT` (number, Read-only)




<a id="view.WRAPINDENT_DEEPINDENT"></a>
#### `view.WRAPINDENT_DEEPINDENT` (number, Read-only)




<a id="view.WRAPINDENT_FIXED"></a>
#### `view.WRAPINDENT_FIXED` (number, Read-only)




<a id="view.WRAPINDENT_INDENT"></a>
#### `view.WRAPINDENT_INDENT` (number, Read-only)




<a id="view.WRAPINDENT_SAME"></a>
#### `view.WRAPINDENT_SAME` (number, Read-only)




<a id="view.WRAPVISUALFLAGLOC_DEFAULT"></a>
#### `view.WRAPVISUALFLAGLOC_DEFAULT` (number, Read-only)




<a id="view.WRAPVISUALFLAGLOC_END_BY_TEXT"></a>
#### `view.WRAPVISUALFLAGLOC_END_BY_TEXT` (number, Read-only)




<a id="view.WRAPVISUALFLAGLOC_START_BY_TEXT"></a>
#### `view.WRAPVISUALFLAGLOC_START_BY_TEXT` (number, Read-only)




<a id="view.WRAPVISUALFLAG_END"></a>
#### `view.WRAPVISUALFLAG_END` (number, Read-only)




<a id="view.WRAPVISUALFLAG_MARGIN"></a>
#### `view.WRAPVISUALFLAG_MARGIN` (number, Read-only)




<a id="view.WRAPVISUALFLAG_NONE"></a>
#### `view.WRAPVISUALFLAG_NONE` (number, Read-only)




<a id="view.WRAPVISUALFLAG_START"></a>
#### `view.WRAPVISUALFLAG_START` (number, Read-only)




<a id="view.WRAP_CHAR"></a>
#### `view.WRAP_CHAR` (number, Read-only)




<a id="view.WRAP_NONE"></a>
#### `view.WRAP_NONE` (number, Read-only)




<a id="view.WRAP_WHITESPACE"></a>
#### `view.WRAP_WHITESPACE` (number, Read-only)




<a id="view.WRAP_WORD"></a>
#### `view.WRAP_WORD` (number, Read-only)




<a id="view.WS_INVISIBLE"></a>
#### `view.WS_INVISIBLE` (number, Read-only)




<a id="view.WS_VISIBLEAFTERINDENT"></a>
#### `view.WS_VISIBLEAFTERINDENT` (number, Read-only)




<a id="view.WS_VISIBLEALWAYS"></a>
#### `view.WS_VISIBLEALWAYS` (number, Read-only)




<a id="view.WS_VISIBLEONLYININDENT"></a>
#### `view.WS_VISIBLEONLYININDENT` (number, Read-only)




<a id="view.additional_carets_blink"></a>
#### `view.additional_carets_blink` (bool)

Allow additional carets to blink.
  The default value is `true`.

<a id="view.additional_carets_visible"></a>
#### `view.additional_carets_visible` (bool)

Display additional carets.
  The default value is `true`.

<a id="view.all_lines_visible"></a>
#### `view.all_lines_visible` (bool, Read-only)

Whether or not all lines are visible.

<a id="view.annotation_visible"></a>
#### `view.annotation_visible` (number)

The annotation visibility mode.

  * `view.ANNOTATION_HIDDEN`
    Annotations are invisible.
  * `view.ANNOTATION_STANDARD`
    Draw annotations left-justified with no decoration.
  * `view.ANNOTATION_BOXED`
    Indent annotations to match the annotated text and outline them with a box.
  * `view.ANNOTATION_INDENTED`
    Indent non-decorated annotations to match the annotated text.

  The default value is `view.ANNOTATION_HIDDEN`.

<a id="view.auto_c_max_height"></a>
#### `view.auto_c_max_height` (number)

The maximum number of items per page to show in autocompletion and user lists.
  The default value is `5`.

<a id="view.auto_c_max_width"></a>
#### `view.auto_c_max_width` (number)

The maximum number of characters per item to show in autocompletion and user lists.
  The default value is `0`, which automatically sizes the width to fit the longest item.

<a id="view.call_tip_fore_hlt"></a>
#### `view.call_tip_fore_hlt` (number, Write-only)

A call tip's highlighted text foreground color, in "0xBBGGRR" format.

<a id="view.call_tip_pos_start"></a>
#### `view.call_tip_pos_start` (number, Write-only)

The position at which backspacing beyond it hides a visible call tip.

<a id="view.call_tip_position"></a>
#### `view.call_tip_position` (boolean)

Display a call tip above the current line instead of below it.
  The default value is `false`.

<a id="view.call_tip_use_style"></a>
#### `view.call_tip_use_style` (number)

The pixel width of tab characters in call tips.
  When non-zero, also enables the use of style number `view.STYLE_CALLTIP` instead of
  `view.STYLE_DEFAULT` for call tip styles.
  The default value is `0`.

<a id="view.caret_line_frame"></a>
#### `view.caret_line_frame` (number)

The caret line's frame width in pixels.
  When non-zero, the line that contains the caret is framed instead of colored in. The
  `view.caret_line_back` and `view.caret_line_back_alpha` properties apply to the frame.
  The default value is `0`.

<a id="view.caret_line_highlight_subline"></a>
#### `view.caret_line_highlight_subline` (boolean)

Color the background of the subline that contains the caret a different color, rather than
  the whole line.
  The defalt value is `false`.

<a id="view.caret_line_layer"></a>
#### `view.caret_line_layer` (number)

The caret line layer mode.

  * `view.LAYER_BASE`
    Draw the caret line opaquely on the background.
  * `view.LAYER_UNDER_TEXT`
    Draw the caret line translucently under text.
  * `view.LAYER_OVER_TEXT`
    Draw the caret line translucently over text.

  The default value is `view.LAYER_BASE`.

<a id="view.caret_line_visible"></a>
#### `view.caret_line_visible` (bool)

Color the background of the line that contains the caret a different color.
  The default value is `false`.

<a id="view.caret_line_visible_always"></a>
#### `view.caret_line_visible_always` (bool)

Always show the caret line, even when the view is not in focus.
  The default value is `false`, showing the line only when the view is in focus.

<a id="view.caret_period"></a>
#### `view.caret_period` (number)

The time between caret blinks in milliseconds.
  A value of `0` stops blinking.
  The default value is `500`.

<a id="view.caret_style"></a>
#### `view.caret_style` (number)

The caret's visual style.

  * `view.CARETSTYLE_INVISIBLE`
    No caret.
  * `view.CARETSTYLE_LINE`
    A line caret.
  * `view.CARETSTYLE_BLOCK`
    A block caret.

  Any block setting may be combined with `view.CARETSTYLE_BLOCK_AFTER` via bitwise OR (`|`)
  in order to draw the caret after the end of a selection, as opposed to just inside it.

  The default value is `view.CARETSTYLE_LINE`.

<a id="view.caret_width"></a>
#### `view.caret_width` (number)

The line caret's pixel width in insert mode, between `0` and `20`.
  The default value is `1`.

<a id="view.cursor"></a>
#### `view.cursor` (number)

The display cursor type.

  * `view.CURSORNORMAL`
    The text insert cursor.
  * `view.CURSORARROW`
    The arrow cursor.
  * `view.CURSORWAIT`
    The wait cursor.
  * `view.CURSORREVERSEARROW`
    The reversed arrow cursor.

  The default value is `view.CURSORNORMAL`.

<a id="view.edge_color"></a>
#### `view.edge_color` (number)

The color, in "0xBBGGRR" format, of the single edge or background for long lines according
  to `view.edge_mode`.

<a id="view.edge_column"></a>
#### `view.edge_column` (number)

The column number to mark long lines at.

<a id="view.edge_mode"></a>
#### `view.edge_mode` (number)

The long line mark mode.

  * `view.EDGE_NONE`
    Long lines are not marked.
  * `view.EDGE_LINE`
    Draw a single vertical line whose color is [`view.edge_color`](#view.edge_color) at column
    [`view.edge_column`](#view.edge_column).
  * `view.EDGE_BACKGROUND`
    Change the background color of text after column [`view.edge_column`](#view.edge_column) to
    [`view.edge_color`](#view.edge_color).
  * `view.EDGE_MULTILINE`
    Draw vertical lines whose colors and columns are defined by calls to
    [`view:multi_edge_add_line()`](#view.multi_edge_add_line).

<a id="view.element_allows_translucent"></a>
#### `view.element_allows_translucent` (table)

Table of flags for UI element identifiers that indicate whether or not an element supports
  translucent colors.
  See [`view.element_color`](#view.element_color) for element identifiers.

<a id="view.element_base_color"></a>
#### `view.element_base_color` (table, read-only)

Table of default colors on "0xAABBGGRR" format for UI element identifiers.
  If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).
  See [`view.element_color`](#view.element_color) for element identifiers.

<a id="view.element_color"></a>
#### `view.element_color` (table)

Table of colors in "0xAABBGGRR" format for UI element identifiers.
  If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).

  * `view.ELEMENT_SELECTION_TEXT`
    The main selection's text color.
  * `view.ELEMENT_SELECTION_BACK`
    The main selection's background color.
  * `view.ELEMENT_SELECTION_ADDITIONAL_TEXT`
    The text color of additional selections.
  * `view.ELEMENT_SELECTION_ADDITIONAL_BACK`
    The background color of additional selections.
  * `view.ELEMENT_SELECTION_SECONDARY_TEXT`
    The text color of selections when another window contains the primary selection.
    This is only available on Linux.
  * `view.ELEMENT_SELECTION_SECONDARY_BACK`
    The background color of selections when another window contains the primary selection.
    This is only available on Linux.
  * `view.ELEMENT_SELECTION_INACTIVE_TEXT`
    The text color of selections when another window has focus.
  * `view.ELEMENT_SELECTION_INACTIVE_BACK`
    The background color of selections when another window has focus.
  * `view.ELEMENT_CARET`
    The main selection's caret color.
  * `view.ELEMENT_CARET_ADDITIONAL`
    The caret color of additional selections.
  * `view.ELEMENT_CARET_LINE_BACK`
    The background color of the line that contains the caret.
  * `view.ELEMENT_WHITE_SPACE`
    The color of visible whitespace.
  * `view.ELEMENT_WHITE_SPACE_BACK`
    The background color of visible whitespace.
  * `view.ELEMENT_FOLD_LINE`
    The color of fold lines.
  * `view.ELEMENT_HIDDEN_LINE`
    The color of lines shown in place of hidden lines.

<a id="view.element_is_set"></a>
#### `view.element_is_set` (table)

Table of flags for UI element identifiers that indicate whether or not a color has been
  manually set.
  See [`view.element_color`](#view.element_color) for element identifiers.

<a id="view.end_at_last_line"></a>
#### `view.end_at_last_line` (bool)

Disable scrolling past the last line.
  The default value is `true`.

<a id="view.eol_annotation_visible"></a>
#### `view.eol_annotation_visible` (number)

The EOL annotation visibility mode.

  * `view.EOLANNOTATION_HIDDEN`
    EOL Annotations are invisible.
  * `view.EOLANNOTATION_STANDARD`
    Draw EOL annotations no decoration.
  * `view.EOLANNOTATION_BOXED`
    Draw EOL annotations outlined with a box.
  * `view.EOLANNOTATION_STADIUM`
    Draw EOL annotations outline with curved ends.
  * `view.EOLANNOTATION_FLAT_CIRCLE`
    Draw EOL annotations outline with a flat left end and curved right end.
  * `view.EOLANNOTATION_ANGLE_CIRCLE`
    Draw EOL annotations outline with an angled left end and curved right end.
  * `view.EOLANNOTATION_CIRCLE_FLAT`
    Draw EOL annotations outline with a curved left end and flat right end.
  * `view.EOLANNOTATION_FLATS`
    Draw EOL annotations outline with a flat ends.
  * `view.EOLANNOTATION_ANGLE_FLAT`
    Draw EOL annotations outline with an angled left end and flat right end.
  * `view.EOLANNOTATION_CIRCLE_ANGLE`
    Draw EOL annotations outline with a curved left end and angled right end.
  * `view.EOLANNOTATION_FLAT_ANGLE`
    Draw EOL annotations outline with a flat left end and angled right end.
  * `view.EOLANNOTATION_ANGLES`
    Draw EOL annotations outline with angled ends.

  All annotations are drawn with the same shape. The default value is
  `view.EOLANNOTATION_HIDDEN`.

<a id="view.extra_ascent"></a>
#### `view.extra_ascent` (number)

The amount of pixel padding above lines.
  The default value is `0`.

<a id="view.extra_descent"></a>
#### `view.extra_descent` (number)

The amount of pixel padding below lines.
  The default is `0`.

<a id="view.first_visible_line"></a>
#### `view.first_visible_line` (number)

The line number of the line at the top of the view.

<a id="view.fold_display_text_style"></a>
#### `view.fold_display_text_style` (number)

The fold display text mode.

  * `view.FOLDDISPLAYTEXT_HIDDEN`
    Fold display text is not shown.
  * `view.FOLDDISPLAYTEXT_STANDARD`
    Fold display text is shown with no decoration.
  * `view.FOLDDISPLAYTEXT_BOXED`
    Fold display text is shown outlined with a box.

  The default value is `view.FOLDDISPLAYTEXT_HIDDEN`.

<a id="view.fold_expanded"></a>
#### `view.fold_expanded` (table)

Table of flags per line number that indicate whether or not fold points are expanded for
  those line numbers.
  Setting expanded fold states does not toggle folds; it only updates fold margin markers. Use
  [`view.toggle_fold()`](#view.toggle_fold) instead.

<a id="view.fold_flags"></a>
#### `view.fold_flags` (number, Read-only)

Bit-mask of folding lines to draw in the buffer.

  * `view.FOLDFLAG_NONE`
    Do not draw folding lines.
  * `view.FOLDFLAG_LINEBEFORE_EXPANDED`
    Draw lines above expanded folds.
  * `view.FOLDFLAG_LINEBEFORE_CONTRACTED`
    Draw lines above collapsed folds.
  * `view.FOLDFLAG_LINEAFTER_EXPANDED`
    Draw lines below expanded folds.
  * `view.FOLDFLAG_LINEAFTER_CONTRACTED`
    Draw lines below collapsed folds.
  * `view.FOLDFLAG_LEVELNUMBERS`
    Show hexadecimal fold levels in line margins.
    This option cannot be combined with `FOLDFLAG_LINESTATE`.
  * `view.FOLDFLAG_LINESTATE`
    Show line state in line margins.
    This option cannot be combined with `FOLDFLAG_LEVELNUMBERS`.

  The default value is `view.FOLDFLAG_NONE`.

<a id="view.h_scroll_bar"></a>
#### `view.h_scroll_bar` (bool)

Display the horizontal scroll bar.
  The default value is `true`.

<a id="view.highlight_guide"></a>
#### `view.highlight_guide` (number)

The indentation guide column number to also highlight when highlighting matching braces,
  or `0` to stop indentation guide highlighting.

<a id="view.idle_styling"></a>
#### `view.idle_styling` (number)

The idle styling mode.
  This mode has no effect when `view.wrap_mode` is on.

  * `view.IDLESTYLING_NONE`
    Style all the currently visible text before displaying it.
  * `view.IDLESTYLING_TOVISIBLE`
    Style some text before displaying it and then style the rest incrementally in the
    background as an idle-time task.
  * `view.IDLESTYLING_AFTERVISIBLE`
    Style text after the currently visible portion in the background.
  * `view.IDLESTYLING_ALL`
    Style text both before and after the visible text in the background.

  The default value is `view.IDLESTYLING_NONE`.

<a id="view.indentation_guides"></a>
#### `view.indentation_guides` (number)

The indentation guide drawing mode.
  Indentation guides are dotted vertical lines that appear within indentation whitespace at
  each level of indentation.

  * `view.IV_NONE`
    Does not draw any guides.
  * `view.IV_REAL`
    Draw guides only within indentation whitespace.
  * `view.IV_LOOKFORWARD`
    Draw guides beyond the current line up to the next non-empty line's indentation level,
    but with an additional level if the previous non-empty line is a fold point.
  * `view.IV_LOOKBOTH`
    Draw guides beyond the current line up to either the indentation level of the previous
    or next non-empty line, whichever is greater.

  The default value is `view.IV_NONE`.

<a id="view.indic_alpha"></a>
#### `view.indic_alpha` (table)

Table of fill color alpha values, ranging from `0` (transparent) to `255` (opaque),
  for indicator numbers from `1` to `32` whose styles are either `INDIC_ROUNDBOX`,
  `INDIC_STRAIGHTBOX`, or `INDIC_DOTBOX`.
  The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.indic_fore"></a>
#### `view.indic_fore` (table)

Table of foreground colors, in "0xBBGGRR" format, for indicator numbers from `1` to `32`.
  Changing an indicator's foreground color resets that indicator's hover foreground color.

<a id="view.indic_hover_fore"></a>
#### `view.indic_hover_fore` (table)

Table of hover foreground colors, in "0xBBGGRR" format, for indicator numbers from `1` to
  `32`.
  The default values are the respective indicator foreground colors.

<a id="view.indic_hover_style"></a>
#### `view.indic_hover_style` (table)

Table of hover styles for indicators numbers from `1` to `32`.
  An indicator's hover style drawn when either the cursor hovers over that indicator or the
  caret is within that indicator.
  The default values are the respective indicator styles.

<a id="view.indic_outline_alpha"></a>
#### `view.indic_outline_alpha` (table)

Table of outline color alpha values, ranging from `0` (transparent) to `255` (opaque),
  for indicator numbers from `1` to `32` whose styles are either `INDIC_ROUNDBOX`,
  `INDIC_STRAIGHTBOX`, or `INDIC_DOTBOX`.
  The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.indic_stroke_width"></a>
#### `view.indic_stroke_width` (table)

Table of stroke widths in hundredths of a pixel for indicator numbers from `1` to `32`
  whose styles are either `INDIC_PLAIN`, `INDIC_SQUIGGLE`, `INDIC_TT`, `INDIC_DIAGONAL`,
  `INDIC_STRIKE`, `INDIC_BOX`, `INDIC_ROUNDBOX`, `INDIC_STRAIGHTBOX`, `INDIC_FULLBOX`,
  `INDIC_DASH`, `INDIC_DOTS`,  or `INDIC_SQUIGGLELOW`.
  The default values are `100`, or 1 pixel.

<a id="view.indic_style"></a>
#### `view.indic_style` (table)

Table of styles for indicator numbers from `1` to `32`.

  * `view.INDIC_PLAIN`
    An underline.
  * `view.INDIC_SQUIGGLE`
    A squiggly underline 3 pixels in height.
  * `view.INDIC_TT`
    An underline of small 'T' shapes.
  * `view.INDIC_DIAGONAL`
    An underline of diagonal hatches.
  * `view.INDIC_STRIKE`
    Strike out.
  * `view.INDIC_HIDDEN`
    Invisible.
  * `view.INDIC_BOX`
    A bounding box.
  * `view.INDIC_ROUNDBOX`
    A translucent box with rounded corners around the text. Use [`view.indic_alpha`](#view.indic_alpha) and
    [`view.indic_outline_alpha`](#view.indic_outline_alpha) to set the fill and outline transparency, respectively.
    Their default values are `30` and `50`.
  * `view.INDIC_STRAIGHTBOX`
    Similar to `INDIC_ROUNDBOX` but with sharp corners.
  * `view.INDIC_DASH`
    A dashed underline.
  * `view.INDIC_DOTS`
    A dotted underline.
  * `view.INDIC_SQUIGGLELOW`
    A squiggly underline 2 pixels in height.
  * `view.INDIC_DOTBOX`
    Similar to `INDIC_STRAIGHTBOX` but with a dotted outline.
    Translucency alternates between [`view.indic_alpha`](#view.indic_alpha) and [`view.indic_outline_alpha`](#view.indic_outline_alpha)
    starting with the top-left pixel.
  * `view.INDIC_SQUIGGLEPIXMAP`
    Identical to `INDIC_SQUIGGLE` but draws faster by using a pixmap instead of multiple
    line segments.
  * `view.INDIC_COMPOSITIONTHICK`
    A 2-pixel thick underline at the bottom of the line inset by 1 pixel on on either
    side. Similar in appearance to the target in Asian language input composition.
  * `view.INDIC_COMPOSITIONTHIN`
    A 1-pixel thick underline just before the bottom of the line inset by 1 pixel on either
    side. Similar in appearance to the non-target ranges in Asian language input composition.
  * `view.INDIC_FULLBOX`
    Similar to `INDIC_STRAIGHTBOX` but extends to the top of its line, potentially touching
    any similar indicators on the line above.
  * `view.INDIC_TEXTFORE`
    Changes the color of text to an indicator's foreground color.
  * `view.INDIC_POINT`
    A triangle below the start of the indicator range.
  * `view.INDIC_POINTCHARACTER`
    A triangle below the center of the first character of the indicator
    range.
  * `view.INDIC_GRADIENT`
    A box with a vertical gradient from solid on top to transparent on bottom.
  * `view.INDIC_GRADIENTCENTER`
    A box with a centered gradient from solid in the middle to transparent on the top
    and bottom.

  Use [`_SCINTILLA.next_indic_number()`](#_SCINTILLA.next_indic_number) for custom indicators.
  Changing an indicator's style resets that indicator's hover style.

<a id="view.indic_under"></a>
#### `view.indic_under` (table)

Table of flags that indicate whether or not to draw indicators behind text instead of over
  the top of it for indicator numbers from `1` to `32`.
  The default values are `false`.

<a id="view.line_visible"></a>
#### `view.line_visible` (table, Read-only)

Table of flags per line number that indicate whether or not lines are visible for those
  line numbers.

<a id="view.lines_on_screen"></a>
#### `view.lines_on_screen` (number, Read-only)

The number of completely visible lines in the view.
  It is possible to have a partial line visible at the bottom of the view.

<a id="view.margin_back_n"></a>
#### `view.margin_back_n` (table)

Table of background colors, in "0xBBGGRR" format, of margin numbers from `1` to `view.margins`
  (`5` by default).
  Only affects margins of type `view.MARGIN_COLOR`.

<a id="view.margin_cursor_n"></a>
#### `view.margin_cursor_n` (table)

Table of cursor types shown over margin numbers from `1` to `view.margins` (`5` by default).

  * `view.CURSORARROW`
    Normal arrow cursor.
  * `view.CURSORREVERSEARROW`
    Reversed arrow cursor.

  The default values are `view.CURSORREVERSEARROW`.

<a id="view.margin_left"></a>
#### `view.margin_left` (number)

The pixel size of the left margin of the buffer text.
  The default value is `1`.

<a id="view.margin_mask_n"></a>
#### `view.margin_mask_n` (table)

Table of bit-masks of markers whose symbols marker symbol margins can display for margin
  numbers from `1` to `view.margins` (`5` by default).
  Bit-masks are 32-bit values whose bits correspond to the 32 available markers.
  The default values are `0`, `view.MASK_FOLDERS`, `0`, `0`, and `0`, for a line margin and
  logical marker margin.

<a id="view.margin_options"></a>
#### `view.margin_options` (number)

A bit-mask of margin option settings.

  * `view.MARGINOPTION_NONE`
    None.
  * `view.MARGINOPTION_SUBLINESELECT`
    Select only a wrapped line's sub-line (rather than the entire line) when the line number
    margin is clicked.

  The default value is `view.MARGINOPTION_NONE`.

<a id="view.margin_right"></a>
#### `view.margin_right` (number)

The pixel size of the right margin of the buffer text.
  The default value is `1`.

<a id="view.margin_sensitive_n"></a>
#### `view.margin_sensitive_n` (table)

Table of flags that indicate whether or not mouse clicks in margins emit `MARGIN_CLICK`
  events for margin numbers from `1` to `view.margins` (`5` by default).
  The default values are `false`.

<a id="view.margin_type_n"></a>
#### `view.margin_type_n` (table)

Table of margin types for margin numbers from `1` to `view.margins` (`5` by default).

  * `view.MARGIN_SYMBOL`
    A marker symbol margin.
  * `view.MARGIN_NUMBER`
    A line number margin.
  * `view.MARGIN_BACK`
    A marker symbol margin whose background color matches the default text background color.
  * `view.MARGIN_FORE`
    A marker symbol margin whose background color matches the default text foreground color.
  * `view.MARGIN_TEXT`
    A text margin.
  * `view.MARGIN_RTEXT`
    A right-justified text margin.
  * `view.MARGIN_COLOR`
    A marker symbol margin whose background color is configurable.

  The default value for the first margin is `view.MARGIN_NUMBER`, followed by
  `view.MARGIN_SYMBOL` for the rest.

<a id="view.margin_width_n"></a>
#### `view.margin_width_n` (table)

Table of pixel margin widths for margin numbers from `1` to `view.margins` (`5` by default).

<a id="view.margins"></a>
#### `view.margins` (number)

The number of margins.
  The default value is `5`.

<a id="view.marker_alpha"></a>
#### `view.marker_alpha` (table, Write-only)

Table of alpha values, ranging from `0` (transparent) to `255` (opaque), of markers drawn
  in the text area (not the margin) for markers numbers from `1` to `32`.
  The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.marker_back"></a>
#### `view.marker_back` (table, Write-only)

Table of background colors, in "0xBBGGRR" format, of marker numbers from `1` to `32`.

<a id="view.marker_back_selected"></a>
#### `view.marker_back_selected` (table, Write-only)

Table of background colors, in "0xBBGGRR" format, of markers whose folding blocks are
  selected for marker numbers from `1` to `32`.

<a id="view.marker_back_selected_translucent"></a>
#### `view.marker_back_selected_translucent` (table, Write-only)

Table of background colors, in "0xAABBGGRR" format, of markers whose folding blocks are
  selected for marker numbers from `1` to `32`.

<a id="view.marker_back_translucent"></a>
#### `view.marker_back_translucent` (table, Write-only)

Table of background colors, in "0xAABBGGRR" format, of marker numbers from `1` to `32`.

<a id="view.marker_fore"></a>
#### `view.marker_fore` (table, Write-only)

Table of foreground colors, in "0xBBGGRR" format, of marker numbers from `1` to `32`.

<a id="view.marker_fore_translucent"></a>
#### `view.marker_fore_translucent` (table, Write-only)

Table of foreground colors, in "0xAABBGGRR" format, of marker numbers from `1` to `32`.

<a id="view.marker_layer"></a>
#### `view.marker_layer` (table)

Table of layer modes for drawing markers in the text area (not the margin) for marker
  numbers from `1` to `32`.

  * `view.LAYER_BASE`
    Draw markers opaquely on the background.
  * `view.LAYER_UNDER_TEXT`
    Draw markers translucently under text.
  * `view.LAYER_OVER_TEXT`
    Draw markers translucently over text.

  The default values are `view.LAYER_BASE`.

<a id="view.marker_stroke_width"></a>
#### `view.marker_stroke_width` (table, Write-only)

Table of stroke widths in hundredths of a pixel for marker numbers from `1` to `32`.
  The default values are `100`, or 1 pixel.

<a id="view.mouse_dwell_time"></a>
#### `view.mouse_dwell_time` (number)

The number of milliseconds the mouse must idle before generating a `DWELL_START` event. A
  time of `view.TIME_FOREVER` will never generate one.

<a id="view.mouse_selection_rectangular_switch"></a>
#### `view.mouse_selection_rectangular_switch` (bool)

Whether or not pressing [`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) when selecting text
  normally with the mouse turns on rectangular selection.
  The default value is `false`.

<a id="view.multi_edge_column"></a>
#### `view.multi_edge_column` (table, Read-only)

Table of edge column positions per edge column number.
  A position of `-1` means no edge column was found.

<a id="view.property"></a>
#### `view.property` (table)

Map of key-value string pairs used by lexers.

<a id="view.property_int"></a>
#### `view.property_int` (table, Read-only)

Map of key-value pairs used by lexers with values interpreted as numbers, or `0` if not found.

<a id="view.rectangular_selection_modifier"></a>
#### `view.rectangular_selection_modifier` (number)

The modifier key used in combination with a mouse drag in order to create a rectangular
  selection.

  * `view.MOD_CTRL`
    The "Control" modifier key.
  * `view.MOD_ALT`
    The "Alt" modifier key.
  * `view.MOD_SUPER`
    The "Super" modifier key, usually defined as the left "Windows" or
    "Command" key.

  The default value is `view.MOD_CTRL`.

<a id="view.representation"></a>
#### `view.representation` (table)

The alternative string representations of characters.
  Representations are displayed in the same way control characters are. Use the empty
  string for the '\0' character when assigning its representation. Characters are strings,
  not numeric codes, and can be multi-byte characters.
  Call [`view.clear_representation()`](#view.clear_representation) to remove a representation.

<a id="view.representation_appearance"></a>
#### `view.representation_appearance` (table)

Map of characters to their string representation's appearance.

  * `view.REPRESENTATION_PLAIN`
    Draw the representation with no decoration.
  * `view.REPRESENTATION_BLOB`
    Draw the representation within a rounded rectangle and an inverted color.
  * `view.REPRESENTATION_COLOR`
    Draw the representation using the color set in [`view.representation_color`](#view.representation_color).

  The default values are `view.REPRESENTATION_BLOB`.

<a id="view.representation_color"></a>
#### `view.representation_color` (table)

Map of characters to their string representation's color in "0xBBGGRR" format.

<a id="view.rgba_image_height"></a>
#### `view.rgba_image_height` (number)

The height of the RGBA image to be defined using [`view.marker_define_rgba_image()`](#view.marker_define_rgba_image).

<a id="view.rgba_image_scale"></a>
#### `view.rgba_image_scale` (number)

The scale factor in percent of the RGBA image to be defined using
  [`view.marker_define_rgba_image()`](#view.marker_define_rgba_image).
  This is useful on macOS with a retina display where each display unit is 2 pixels: use a
  factor of `200` so that each image pixel is displayed using a screen pixel.
  The default scale, `100`, will stretch each image pixel to cover 4 screen pixels on a
  retina display.

<a id="view.rgba_image_width"></a>
#### `view.rgba_image_width` (number)

The width of the RGBA image to be defined using [`view.marker_define_rgba_image()`](#view.marker_define_rgba_image) and
  [`view.register_rgba_image()`](#view.register_rgba_image).

<a id="view.scroll_width"></a>
#### `view.scroll_width` (number)

The horizontal scrolling pixel width.
  For performance, the view does not measure the display width of the buffer to determine
  the properties of the horizontal scroll bar, but uses an assumed width instead. To ensure
  the width of the currently visible lines can be scrolled use [`view.scroll_width_tracking`](#view.scroll_width_tracking).
  The default value is `2000`.

<a id="view.scroll_width_tracking"></a>
#### `view.scroll_width_tracking` (bool)

Continuously update the horizontal scrolling width to match the maximum width of a displayed
  line beyond [`view.scroll_width`](#view.scroll_width).
  The default value is `false`.

<a id="view.sel_alpha"></a>
#### `view.sel_alpha` (number)

The selection's alpha value, ranging from `0` (transparent) to `255` (opaque).
  The default value is `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.sel_eol_filled"></a>
#### `view.sel_eol_filled` (bool)

Extend the selection to the view's right margin.
  The default value is `false`.

<a id="view.selection_layer"></a>
#### `view.selection_layer` (number)

The layer mode for drawing selections.

  * `view.LAYER_BASE`
    Draw selections opaquely on the background.
  * `view.LAYER_UNDER_TEXT`
    Draw selections translucently under text.
  * `view.LAYER_OVER_TEXT`
    Draw selections translucently over text.

  The default value is `view.LAYER_BASE`.

<a id="view.size"></a>
#### `view.size` (number)

The split resizer's pixel position if the view is a split one.

<a id="view.style_back"></a>
#### `view.style_back` (table)

Table of background colors, in "0xBBGGRR" format, of text for style numbers from `1` to `256`.

<a id="view.style_bold"></a>
#### `view.style_bold` (table)

Table of flags that indicate whether or not text is bold for style numbers from `1` to `256`.
  The default values are `false`.

<a id="view.style_case"></a>
#### `view.style_case` (table)

Table of letter case modes of text for style numbers from `1` to `256`.

  * `view.CASE_MIXED`
    Display text in normally.
  * `view.CASE_UPPER`
    Display text in upper case.
  * `view.CASE_LOWER`
    Display text in lower case.
  * `view.CASE_CAMEL`
    Display text in camel case.

  The default values are `view.CASE_MIXED`.

<a id="view.style_changeable"></a>
#### `view.style_changeable` (table)

Table of flags that indicate whether or not text is changeable for style numbers from `1`
  to `256`.
  The default values are `true`.
  Read-only styles do not allow the caret into the range of text.

<a id="view.style_eol_filled"></a>
#### `view.style_eol_filled` (table)

Table of flags that indicate whether or not the background colors of styles whose characters
  occur last on lines extend all the way to the view's right margin for style numbers from
  `1` to `256`.
  The default values are `false`.

<a id="view.style_font"></a>
#### `view.style_font` (table)

Table of string font names of text for style numbers from `1` to `256`.

<a id="view.style_fore"></a>
#### `view.style_fore` (table)

Table of foreground colors, in "0xBBGGRR" format, of text for style numbers from `1` to `256`.

<a id="view.style_italic"></a>
#### `view.style_italic` (table)

Table of flags that indicate whether or not text is italic for style numbers from `1` to
  `256`.
  The default values are `false`.

<a id="view.style_size"></a>
#### `view.style_size` (table)

Table of font sizes of text for style numbers from `1` to `256`.

<a id="view.style_underline"></a>
#### `view.style_underline` (table)

Table of flags that indicate whether or not text is underlined for style numbers from `1`
  to `256`.
  The default values are `false`.

<a id="view.style_visible"></a>
#### `view.style_visible` (table)

Table of flags that indicate whether or not text is visible for style numbers from `1` to
  `256`.
  The default values are `true`.

<a id="view.tab_draw_mode"></a>
#### `view.tab_draw_mode` (number)

The draw mode of visible tabs.

  * `view.TD_LONGARROW`
    An arrow that stretches until the tabstop.
  * `view.TD_STRIKEOUT`
    A horizontal line that stretches until the tabstop.

  The default value is `view.TD_LONGARROW`.

<a id="view.v_scroll_bar"></a>
#### `view.v_scroll_bar` (bool)

Display the vertical scroll bar.
  The default value is `true`.

<a id="view.view_eol"></a>
#### `view.view_eol` (bool)

Display end of line characters.
  The default value is `false`.

<a id="view.view_ws"></a>
#### `view.view_ws` (number)

The whitespace visibility mode.

  * `view.WS_INVISIBLE`
    Whitespace is invisible.
  * `view.WS_VISIBLEALWAYS`
    Display all space characters as dots and tab characters as arrows.
  * `view.WS_VISIBLEAFTERINDENT`
    Display only non-indentation spaces and tabs as dots and arrows.
  * `view.WS_VISIBLEONLYININDENT`
    Display only indentation spaces and tabs as dots and arrows.

  The default value is `view.WS_INVISIBLE`.

<a id="view.whitespace_size"></a>
#### `view.whitespace_size` (number)

The pixel size of the dots that represent space characters when whitespace is visible.
  The default value is `1`.

<a id="view.wrap_indent_mode"></a>
#### `view.wrap_indent_mode` (number)

The wrapped line indent mode.

  * `view.WRAPINDENT_FIXED`
    Indent wrapped lines by [`view.wrap_start_indent`](#view.wrap_start_indent).
  * `view.WRAPINDENT_SAME`
    Indent wrapped lines the same amount as the first line.
  * `view.WRAPINDENT_INDENT`
    Indent wrapped lines one more level than the level of the first line.
  * `view.WRAPINDENT_DEEPINDENT`
    Indent wrapped lines two more levels than the level of the first line.

  The default value is `view.WRAPINDENT_FIXED`.

<a id="view.wrap_mode"></a>
#### `view.wrap_mode` (number)

Long line wrap mode.

  * `view.WRAP_NONE`
    Long lines are not wrapped.
  * `view.WRAP_WORD`
    Wrap long lines at word (and style) boundaries.
  * `view.WRAP_CHAR`
    Wrap long lines at character boundaries.
  * `view.WRAP_WHITESPACE`
    Wrap long lines at word boundaries (ignoring style boundaries).

  The default value is `view.WRAP_NONE`.

<a id="view.wrap_start_indent"></a>
#### `view.wrap_start_indent` (number)

The number of spaces of indentation to display wrapped lines with if
  [`view.wrap_indent_mode`](#view.wrap_indent_mode) is `view.WRAPINDENT_FIXED`.
  The default value is `0`.

<a id="view.wrap_visual_flags"></a>
#### `view.wrap_visual_flags` (number)

The wrapped line visual flag display mode.

  * `view.WRAPVISUALFLAG_NONE`
    No visual flags.
  * `view.WRAPVISUALFLAG_END`
    Show a visual flag at the end of a wrapped line.
  * `view.WRAPVISUALFLAG_START`
    Show a visual flag at the beginning of a sub-line.
  * `view.WRAPVISUALFLAG_MARGIN`
    Show a visual flag in the sub-line's line number margin.

  The default value is `view.WRAPVISUALFLAG_NONE`.

<a id="view.wrap_visual_flags_location"></a>
#### `view.wrap_visual_flags_location` (number)

The wrapped line visual flag location.

  * `view.WRAPVISUALFLAGLOC_DEFAULT`
    Draw a visual flag near the view's right margin.
  * `view.WRAPVISUALFLAGLOC_END_BY_TEXT`
    Draw a visual flag near text at the end of a wrapped line.
  * `view.WRAPVISUALFLAGLOC_START_BY_TEXT`
    Draw a visual flag near text at the beginning of a subline.

  The default value is `view.WRAPVISUALFLAGLOC_DEFAULT`.

<a id="view.x_offset"></a>
#### `view.x_offset` (number)

The horizontal scroll pixel position.
  A value of `0` is the normal position with the first text column visible at the left of
  the view.

<a id="view.zoom"></a>
#### `view.zoom` (number)

The number of points to add to the size of all fonts.
  Negative values are allowed, down to `-10`.
  The default value is `0`.


### Functions defined by `view`

<a id="view.brace_bad_light"></a>
#### `view.brace_bad_light`(*view, pos*)

Highlights the character at position *pos* as an unmatched brace character using the
`'style.bracebad'` style.
Removes highlighting when *pos* is `-1`.

Parameters:

* *`view`*: A view.
* *`pos`*: The position in *view*'s buffer to highlight, or `-1` to remove the highlight.

<a id="view.brace_bad_light_indicator"></a>
#### `view.brace_bad_light_indicator`(*view, use\_indicator, indicator*)

Highlights unmatched brace characters with indicator number *indicator*, in the range of
`1` to `32`, instead of the `view.STYLE_BRACEBAD` style if *use_indicator* is `true`.

Parameters:

* *`view`*: A view.
* *`use_indicator`*: Whether or not to use an indicator.
* *`indicator`*: The indicator number to use.

<a id="view.brace_highlight"></a>
#### `view.brace_highlight`(*view, pos1, pos2*)

Highlights the characters at positions *pos1* and *pos2* as matching braces using the
`'style.bracelight'` style.
If indent guides are enabled, locates the column with `buffer.column` and sets
`view.highlight_guide` in order to highlight the indent guide.

Parameters:

* *`view`*: A view.
* *`pos1`*: The first position in *view*'s buffer to highlight.
* *`pos2`*: The second position in *view*'s buffer to highlight.

<a id="view.brace_highlight_indicator"></a>
#### `view.brace_highlight_indicator`(*view, use\_indicator, indicator*)

Highlights matching brace characters with indicator number *indicator*, in the range of `1`
to `32`, instead of the `view.STYLE_BRACELIGHT` style if *use_indicator* is `true`.

Parameters:

* *`view`*: A view.
* *`use_indicator`*: Whether or not to use an indicator.
* *`indicator`*: The indicator number to use.

<a id="view.call_tip_active"></a>
#### `view.call_tip_active`(*view*)

Returns whether or not a call tip is visible.

Parameters:

* *`view`*: A view.

Return:

* bool

<a id="view.call_tip_cancel"></a>
#### `view.call_tip_cancel`(*view*)

Removes the displayed call tip from view.

Parameters:

* *`view`*: A view.

<a id="view.call_tip_pos_start"></a>
#### `view.call_tip_pos_start`(*view*)

Returns a call tip's display position.

Parameters:

* *`view`*: A view.

Return:

* number

<a id="view.call_tip_set_hlt"></a>
#### `view.call_tip_set_hlt`(*view, start\_pos, end\_pos*)

Highlights a call tip's text between positions *start_pos* to *end_pos* with the color
`view.call_tip_fore_hlt`.

Parameters:

* *`view`*: A view.
* *`start_pos`*: The start position in a call tip text to highlight.
* *`end_pos`*: The end position in a call tip text to highlight.

<a id="view.call_tip_show"></a>
#### `view.call_tip_show`(*view, pos, text*)

Displays a call tip at position *pos* with string *text* as the call tip's contents.
Any "\001" or "\002" bytes in *text* are replaced by clickable up or down arrow visuals,
respectively. These may be used to indicate that a symbol has more than one call tip,
for example.

Parameters:

* *`view`*: A view.
* *`pos`*: The position in *view*'s buffer to show a call tip at.
* *`text`*: The call tip text to show.

<a id="view.clear_all_representations"></a>
#### `view.clear_all_representations`(*view*)

Removes all alternate string representations of characters.

Parameters:

* *`view`*: A view.

<a id="view.clear_registered_images"></a>
#### `view.clear_registered_images`(*view*)

Clears all images registered using `view.register_image()` and `view.register_rgba_image()`.

Parameters:

* *`view`*: A view.

<a id="view.clear_representation"></a>
#### `view.clear_representation`(*view, char*)

Removes the alternate string representation for character *char* (which may be a multi-byte
character).

Parameters:

* *`view`*: A view.
* *`char`*: The string character in `buffer.representations` to remove the alternate string
  representation for.

<a id="view.contracted_fold_next"></a>
#### `view.contracted_fold_next`(*view, line*)

Returns the line number of the next contracted fold point starting from line number *line*,
or `-1` if none exists.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to start at.

Return:

* number

<a id="view.doc_line_from_visible"></a>
#### `view.doc_line_from_visible`(*view, display\_line*)

Returns the actual line number of displayed line number *display_line*, taking wrapped,
annotated, and hidden lines into account.
If *display_line* is less than or equal to `1`, returns `1`. If *display_line* is greater
than the number of displayed lines, returns `buffer.line_count`.

Parameters:

* *`view`*: A view.
* *`display_line`*: The display line number to use.

Return:

* number

<a id="view.ensure_visible"></a>
#### `view.ensure_visible`(*view, line*)

Ensures line number *line* is visible by expanding any fold points hiding it.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to ensure visible.

<a id="view.ensure_visible_enforce_policy"></a>
#### `view.ensure_visible_enforce_policy`(*view, line*)

Ensures line number *line* is visible by expanding any fold points hiding it based on the
vertical caret policy previously defined in `view.set_visible_policy()`.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to ensure visible.

<a id="view.fold_all"></a>
#### `view.fold_all`(*view, action*)

Contracts, expands, or toggles all fold points, depending on *action*.
When toggling, the state of the first fold point determines whether to expand or contract.

Parameters:

* *`view`*: A view.
* *`action`*: The fold action to perform. Valid values are:
  * `view.FOLDACTION_CONTRACT`
  * `view.FOLDACTION_EXPAND`
  * `view.FOLDACTION_TOGGLE`

<a id="view.fold_children"></a>
#### `view.fold_children`(*view, line, action*)

Contracts, expands, or toggles the fold point on line number *line*, as well as all of its
children, depending on *action*.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to set the fold states for.
* *`action`*: The fold action to perform. Valid values are:
  * `view.FOLDACTION_CONTRACT`
  * `view.FOLDACTION_EXPAND`
  * `view.FOLDACTION_TOGGLE`

<a id="view.fold_line"></a>
#### `view.fold_line`(*view, line, action*)

Contracts, expands, or toggles the fold point on line number *line*, depending on *action*.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to set the fold state for.
* *`action`*: The fold action to perform. Valid values are:
  * `view.FOLDACTION_CONTRACT`
  * `view.FOLDACTION_EXPAND`
  * `view.FOLDACTION_TOGGLE`

<a id="view.get_default_fold_display_text"></a>
#### `view.get_default_fold_display_text`(*view*)

Returns the default fold display text.

Parameters:

* *`view`*: A view.

<a id="view.goto_buffer"></a>
#### `view.goto_buffer`(*view, buffer*)

Switches to buffer *buffer* or the buffer *buffer* number of buffers relative to the
current one.
Emits `BUFFER_BEFORE_SWITCH` and `BUFFER_AFTER_SWITCH` events.

Parameters:

* *`view`*: The view to switch buffers in.
* *`buffer`*: A buffer or relative buffer number (typically 1 or -1).

See also:

* [`_BUFFERS`](#_BUFFERS)
* [`events.BUFFER_BEFORE_SWITCH`](#events.BUFFER_BEFORE_SWITCH)
* [`events.BUFFER_AFTER_SWITCH`](#events.BUFFER_AFTER_SWITCH)

<a id="view.hide_lines"></a>
#### `view.hide_lines`(*view, start\_line, end\_line*)

Hides the range of lines between line numbers *start_line* to *end_line*.
This has no effect on fold levels or fold flags.

Parameters:

* *`view`*: A view.
* *`start_line`*: The start line of the range of lines in *view* to hide.
* *`end_line`*: The end line of the range of lines in *view* to hide.

<a id="view.line_scroll"></a>
#### `view.line_scroll`(*view, columns, lines*)

Scrolls the buffer right *columns* columns and down *lines* lines.
Negative values are allowed.

Parameters:

* *`view`*: A view.
* *`columns`*: The number of columns to scroll horizontally.
* *`lines`*: The number of lines to scroll vertically.

<a id="view.line_scroll_down"></a>
#### `view.line_scroll_down`(*view*)

Scrolls the buffer down one line, keeping the caret visible.

Parameters:

* *`view`*: A view.

<a id="view.line_scroll_up"></a>
#### `view.line_scroll_up`(*view*)

Scrolls the buffer up one line, keeping the caret visible.

Parameters:

* *`view`*: A view.

<a id="view.marker_define"></a>
#### `view.marker_define`(*view, marker, symbol*)

Assigns marker symbol *symbol* to marker number *marker*, in the range of `1` to `32`.
*symbol* is shown in marker symbol margins next to lines marked with *marker*.

Parameters:

* *`view`*: A view.
* *`marker`*: The marker number in the range of `1` to `32` to set *symbol* for.
* *`symbol`*: The marker symbol: `buffer.MARK_*`.

See also:

* [`_SCINTILLA.next_marker_number`](#_SCINTILLA.next_marker_number)

<a id="view.marker_define_pixmap"></a>
#### `view.marker_define_pixmap`(*view, marker, pixmap*)

Associates marker number *marker*, in the range of `1` to `32`, with XPM image *pixmap*.
The `view.MARK_PIXMAP` marker symbol must be assigned to *marker*. *pixmap* is shown in
marker symbol margins next to lines marked with *marker*.

Parameters:

* *`view`*: A view.
* *`marker`*: The marker number in the range of `1` to `32` to define pixmap *pixmap* for.
* *`pixmap`*: The string pixmap data.

<a id="view.marker_define_rgba_image"></a>
#### `view.marker_define_rgba_image`(*view, marker, pixels*)

Associates marker number *marker*, in the range of `1` to `32`, with RGBA image *pixels*.
The dimensions for *pixels* (`view.rgba_image_width` and `view.rgba_image_height`) must
have already been defined. *pixels* is a sequence of 4 byte pixel values (red, blue, green,
and alpha) defining the image line by line starting at the top-left pixel.
The `view.MARK_RGBAIMAGE` marker symbol must be assigned to *marker*. *pixels* is shown in
symbol margins next to lines marked with *marker*.

Parameters:

* *`view`*: A view.
* *`marker`*: The marker number in the range of `1` to `32` to define RGBA data *pixels* for.
* *`pixels`*: The string sequence of 4 byte pixel values starting with the pixels for the
  top line, with the leftmost pixel first, then continuing with the pixels for subsequent
  lines. There is no gap between lines for alignment reasons. Each pixel consists of, in
  order, a red byte, a green byte, a blue byte and an alpha byte. The color bytes are not
  premultiplied by the alpha value. That is, a fully red pixel that is 25% opaque will be
  `[FF, 00, 00, 3F]`.

<a id="view.marker_enable_highlight"></a>
#### `view.marker_enable_highlight`(*view, enabled*)

Highlights the margin fold markers for the current fold block if *enabled* is `true`.

Parameters:

* *`view`*: A view.
* *`enabled`*: Whether or not to enable highlight.

<a id="view.marker_symbol_defined"></a>
#### `view.marker_symbol_defined`(*view, marker*)

Returns the symbol assigned to marker number *marker*, in the range of `1` to `32`, used in
`view.marker_define()`,
`view.marker_define_pixmap()`, or `view.marker_define_rgba_image()`.

Parameters:

* *`view`*: A view.
* *`marker`*: The marker number in the range of `1` to `32` to get the symbol of.

Return:

* number

<a id="view.multi_edge_add_line"></a>
#### `view.multi_edge_add_line`(*view, column, color*)

Adds a new vertical line at column number *column* with color *color*, in "0xBBGGRR" format.

Parameters:

* *`view`*: A view.
* *`column`*: The column number to add a vertical line at.
* *`color`*: The color in "0xBBGGRR" format.

<a id="view.multi_edge_clear_all"></a>
#### `view.multi_edge_clear_all`(*view*)

Clears all vertical lines created by `view:multi_edge_add_line()`.

Parameters:

* *`view`*: A view.

<a id="view.register_image"></a>
#### `view.register_image`(*view, type, xpm\_data*)

Registers XPM image *xpm_data* to type number *type* for use in autocompletion and user lists.

Parameters:

* *`view`*: A view.
* *`type`*: Integer type to register the image with.
* *`xpm_data`*: The XPM data as described in `view.marker_define_pixmap()`.

<a id="view.register_rgba_image"></a>
#### `view.register_rgba_image`(*view, type, pixels*)

Registers RGBA image *pixels* to type number *type* for use in autocompletion and user lists.
The dimensions for *pixels* (`view.rgba_image_width` and `view.rgba_image_height`) must
have already been defined. *pixels* is a sequence of 4 byte pixel values (red, blue, green,
and alpha) defining the image line by line starting at the top-left pixel.

Parameters:

* *`view`*: A view.
* *`type`*: Integer type to register the image with.
* *`pixels`*: The RGBA data as described in `view.marker_define_rgba_image()`.

<a id="view.reset_element_color"></a>
#### `view.reset_element_color`(*view, element*)

Resets the color of UI element *element* to its default color.

Parameters:

* *`view`*: 
* *`element`*: One of the UI elements specified in [`view.element_color`]().

See also:

* [`view.element_color`](#view.element_color)

<a id="view.scroll_caret"></a>
#### `view.scroll_caret`(*view*)

Scrolls the caret into view based on the policies previously defined in
`view.set_x_caret_policy()` and `view.set_y_caret_policy()`.

Parameters:

* *`view`*: A view.

See also:

* [`view.set_x_caret_policy`](#view.set_x_caret_policy)
* [`view.set_y_caret_policy`](#view.set_y_caret_policy)

<a id="view.scroll_range"></a>
#### `view.scroll_range`(*view, secondary\_pos, primary\_pos*)

Scrolls into view the range of text between positions *primary_pos* and *secondary_pos*,
with priority given to *primary_pos*.
Similar to `view.scroll_caret()`, but with *primary_pos* instead of `buffer.current_pos`.
This is useful for scrolling search results into view.

Parameters:

* *`view`*: A view.
* *`secondary_pos`*: The secondary range position to scroll into view.
* *`primary_pos`*: The primary range position to scroll into view.

<a id="view.scroll_to_end"></a>
#### `view.scroll_to_end`(*view*)

Scrolls to the end of the buffer without moving the caret.

Parameters:

* *`view`*: A view.

<a id="view.scroll_to_start"></a>
#### `view.scroll_to_start`(*view*)

Scrolls to the beginning of the buffer without moving the caret.

Parameters:

* *`view`*: A view.

<a id="view.set_default_fold_display_text"></a>
#### `view.set_default_fold_display_text`(*view, text*)

Sets the default fold display text to string *text*.

Parameters:

* *`view`*: A view.
* *`text`*: The text to display by default next to folded lines.

See also:

* [`view.toggle_fold_show_text`](#view.toggle_fold_show_text)

<a id="view.set_fold_margin_color"></a>
#### `view.set_fold_margin_color`(*view, use\_setting, color*)

Overrides the fold margin's default color with color *color*, in "0xBBGGRR" format, if
*use_setting* is `true`.

Parameters:

* *`view`*: A view.
* *`use_setting`*: Whether or not to use *color*.
* *`color`*: The color in "0xBBGGRR" format.

<a id="view.set_fold_margin_hi_color"></a>
#### `view.set_fold_margin_hi_color`(*view, use\_setting, color*)

Overrides the fold margin's default highlight color with color *color*, in "0xBBGGRR" format,
if *use_setting* is `true`.

Parameters:

* *`view`*: A view.
* *`use_setting`*: Whether or not to use *color*.
* *`color`*: The color in "0xBBGGRR" format.

<a id="view.set_theme"></a>
#### `view.set_theme`(*view, name, env*)

Sets the view's color theme to be string *name*, with the contents of table *env* available
as global variables.
User themes override Textadept's default themes when they have the same name. If *name*
contains slashes, it is assumed to be an absolute path to a theme instead of a theme name.

Parameters:

* *`view`*: A view.
* *`name`*: The name or absolute path of a theme to set.
* *`env`*: Optional table of global variables themes can utilize to override default settings
  such as font and size.

Usage:

* `view:set_theme('light', {font = 'Monospace', size = 12})`

See also:

* [`lexer.colors`](#lexer.colors)
* [`lexer.styles`](#lexer.styles)

<a id="view.set_visible_policy"></a>
#### `view.set_visible_policy`(*view, policy, y*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *y* number
of lines away from the vertical margins as `view.ensure_visible_enforce_policy()` redisplays
hidden or folded lines.
It is similar in operation to `view.set_y_caret_policy()`.

Parameters:

* *`view`*: A view.
* *`policy`*: The combination of `view.VISIBLE_SLOP` and `view.VISIBLE_STRICT` policy flags
  to set.
* *`y`*: The number of lines from the vertical margins to keep the caret.

<a id="view.set_whitespace_back"></a>
#### `view.set_whitespace_back`(*view, use\_setting, color*)

Overrides the background color of whitespace with color *color*, in "0xBBGGRR" format,
if *use_setting* is `true`.

Parameters:

* *`view`*: A view.
* *`use_setting`*: Whether or not to use *color*.
* *`color`*: The color in "0xBBGGRR" format.

<a id="view.set_whitespace_fore"></a>
#### `view.set_whitespace_fore`(*view, use\_setting, color*)

Overrides the foreground color of whitespace with color *color*, in "0xBBGGRR" format,
if *use_setting* is `true`.

Parameters:

* *`view`*: 
* *`use_setting`*: Whether or not to use *color*.
* *`color`*: The color in "0xBBGGRR" format.

<a id="view.set_x_caret_policy"></a>
#### `view.set_x_caret_policy`(*view, policy, x*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *x* number
of pixels away from the horizontal margins.

Parameters:

* *`view`*: A view.
* *`policy`*: The combination of `view.CARET_SLOP`, `view.CARET_STRICT`, `view.CARET_EVEN`,
  and `view.CARET_JUMPS` policy flags to set.
* *`x`*: The number of pixels from the horizontal margins to keep the caret.

<a id="view.set_y_caret_policy"></a>
#### `view.set_y_caret_policy`(*view, policy, y*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *y* number
of lines away from the vertical margins.

Parameters:

* *`view`*: A view.
* *`policy`*: The combination of `view.CARET_SLOP`, `view.CARET_STRICT`, `view.CARET_EVEN`,
  and `view.CARET_JUMPS` policy flags to set.
* *`y`*: The number of lines from the vertical margins to keep the caret.

<a id="view.show_lines"></a>
#### `view.show_lines`(*view, start\_line, end\_line*)

Shows the range of lines between line numbers *start_line* to *end_line*.
This has no effect on fold levels or fold flags and the first line cannot be hidden.

Parameters:

* *`view`*: A view.
* *`start_line`*: The start line of the range of lines in *view* to show.
* *`end_line`*: The end line of the range of lines in *view* to show.

<a id="view.split"></a>
#### `view.split`(*view, vertical*)

Splits the view into top and bottom views (unless *vertical* is `true`), focuses the new view,
and returns both the old and new views.
If *vertical* is `false`, splits the view vertically into left and right views.
Emits a `VIEW_NEW` event.

Parameters:

* *`view`*: The view to split.
* *`vertical`*: Optional flag indicating whether or not to split the view vertically. The
  default value is `false`, for horizontal.

Return:

* old view and new view.

See also:

* [`events.VIEW_NEW`](#events.VIEW_NEW)

<a id="view.style_clear_all"></a>
#### `view.style_clear_all`(*view*)

Reverts all styles to having the same properties as `view.STYLE_DEFAULT`.

Parameters:

* *`view`*: A view.

<a id="view.style_reset_default"></a>
#### `view.style_reset_default`(*view*)

Resets `view.STYLE_DEFAULT` to its initial state.

Parameters:

* *`view`*: A view.

<a id="view.text_height"></a>
#### `view.text_height`(*view, line*)

Returns the pixel height of line number *line*.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to get the pixel height of.

Return:

* number

<a id="view.text_width"></a>
#### `view.text_width`(*view, style\_num, text*)

Returns the pixel width string *text* would have when styled with style number *style_num*,
in the range of `1` to `256`.

Parameters:

* *`view`*: A view.
* *`style_num`*: The style number between `1` and `256` to use.
* *`text`*: The text to measure the width of.

Return:

* number

<a id="view.toggle_fold"></a>
#### `view.toggle_fold`(*view, line*)

Toggles the fold point on line number *line* between expanded (where all of its child lines
are displayed) and contracted (where all of its child lines are hidden).

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to toggle the fold on.

See also:

* [`view.set_default_fold_display_text`](#view.set_default_fold_display_text)

<a id="view.toggle_fold_show_text"></a>
#### `view.toggle_fold_show_text`(*view, line, text*)

Toggles a fold point on line number *line* between expanded (where all of its child lines are
displayed) and contracted (where all of its child lines are hidden), and shows string *text*
next to that line.
*text* is drawn with style number `view.STYLE_FOLDDISPLAYTEXT`.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to toggle the fold on and display *text* after.
* *`text`*: The text to display after the line.

<a id="view.unsplit"></a>
#### `view.unsplit`(*view*)

Unsplits the view if possible, returning `true` on success.

Parameters:

* *`view`*: The view to unsplit.

Return:

* boolean if the view was unsplit or not.

<a id="view.vertical_center_caret"></a>
#### `view.vertical_center_caret`(*view*)

Centers current line in the view.

Parameters:

* *`view`*: A view.

<a id="view.visible_from_doc_line"></a>
#### `view.visible_from_doc_line`(*view, line*)

Returns the displayed line number of actual line number *line*, taking wrapped, annotated,
and hidden lines into account, or `-1` if *line* is outside the range of lines in the buffer.
Lines can occupy more than one display line if they wrap.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to use.

Return:

* number

<a id="view.wrap_count"></a>
#### `view.wrap_count`(*view, line*)

Returns the number of wrapped lines needed to fully display line number *line*.

Parameters:

* *`view`*: A view.
* *`line`*: The line number in *view* to use.

Return:

* number

<a id="view.zoom_in"></a>
#### `view.zoom_in`(*view*)

Increases the size of all fonts by one point, up to 20.

Parameters:

* *`view`*: A view.

<a id="view.zoom_out"></a>
#### `view.zoom_out`(*view*)

Decreases the size of all fonts by one point, down to -10.

Parameters:

* *`view`*: A view.


### Tables defined by `view`

<a id="view.buffer"></a>
#### `view.buffer`

The [buffer](#buffer) the view currently contains. (Read-only)

---

# Changelog

[Atom Feed][]

**Please [donate][] or purchase the [book][] to fund continuous development.**

[Atom Feed]: feed
[donate]: http://gum.co/textadept
[book]: MEDIA.html#Book

## 7.6 (01 Sep 2014)

Download:

* [Textadept 7.6 -- Win32][]
* [Textadept 7.6 -- Mac OSX Intel 10.5+][]
* [Textadept 7.6 -- Linux][]
* [Textadept 7.6 -- Linux x86_64][]
* [Textadept 7.6 -- Modules][]

Bugfixes:

* Recognize DEL when emitted by the Backspace key in the terminal version.

Changes:

* Terminal version can truly [`spawn()`][] processes now.
* Added Linux .desktop files for menus and launchers.
* Indicate presence of a BOM in the statusbar.
* Switch to previous buffer after closing a buffer.
* More options for [`lfs.dir_foreach()`][].
* Updated to [Scintilla][] 3.5.0.

[Textadept 7.6 -- Win32]: download/textadept_7.6.win32.zip
[Textadept 7.6 -- Mac OSX Intel 10.5+]: download/textadept_7.6.osx.zip
[Textadept 7.6 -- Linux]: download/textadept_7.6.i386.tgz
[Textadept 7.6 -- Linux x86_64]: download/textadept_7.6.x86_64.tgz
[Textadept 7.6 -- Modules]: download/textadept_7.6.modules.zip
[`spawn()`]: api.html#spawn
[`lfs.dir_foreach()`]: api.html#lfs.dir_foreach
[Scintilla]: http://scintilla.org

## 7.5 (11 Jul 2014)

Download:

* [Textadept 7.5 -- Win32][]
* [Textadept 7.5 -- Mac OSX Intel 10.5+][]
* [Textadept 7.5 -- Linux][]
* [Textadept 7.5 -- Linux x86_64][]
* [Textadept 7.5 -- Modules][]

Bugfixes:

* None.

Changes:

* New [events.FOCUS][] event for when Textadept's window receives focus.
* Condensed manual and API documentation into single files.
* Added Polish translation.
* Updated to [Scintilla][] 3.4.4.

[Textadept 7.5 -- Win32]: download/textadept_7.5.win32.zip
[Textadept 7.5 -- Mac OSX Intel 10.5+]: download/textadept_7.5.osx.zip
[Textadept 7.5 -- Linux]: download/textadept_7.5.i386.tgz
[Textadept 7.5 -- Linux x86_64]: download/textadept_7.5.x86_64.tgz
[Textadept 7.5 -- Modules]: download/textadept_7.5.modules.zip
[events.FOCUS]: api.html#events.FOCUS
[Scintilla]: http://scintilla.org

## 7.4 (11 Jun 2014)

Download:

* [Textadept 7.4 -- Win32][]
* [Textadept 7.4 -- Mac OSX Intel 10.5+][]
* [Textadept 7.4 -- Linux][]
* [Textadept 7.4 -- Linux x86_64][]
* [Textadept 7.4 -- Modules][]

Bugfixes:

* Fix crash in Windows with sending input to spawned processes.
* Fix compile, run, and build command output with split views.
* Fix `#RRGGBB` color interpretation for styles.
* Fix word autocompletion when ignoring case.

Changes:

* Pressing the Enter key in the message buffer and find in files buffer
  simulates a double-click.

[Textadept 7.4 -- Win32]: download/textadept_7.4.win32.zip
[Textadept 7.4 -- Mac OSX Intel 10.5+]: download/textadept_7.4.osx.zip
[Textadept 7.4 -- Linux]: download/textadept_7.4.i386.tgz
[Textadept 7.4 -- Linux x86_64]: download/textadept_7.4.x86_64.tgz
[Textadept 7.4 -- Modules]: download/textadept_7.4.modules.zip

## 7.3 (01 Jun 2014)

Download:

* [Textadept 7.3 -- Win32][]
* [Textadept 7.3 -- Mac OSX Intel 10.5+][]
* [Textadept 7.3 -- Linux][]
* [Textadept 7.3 -- Linux x86_64][]
* [Textadept 7.3 -- Modules][]

Bugfixes:

* Export Lua symbols correctly on Windows.
* Fixed occasional bug when double-clicking in the message buffer.
* Fixed an edge-case in word highlighting.

Changes:

* Added reST and YAML lexers and official language modules for each.
* Use [`spawn()`][] for launching help.
* Renamed `io.set_buffer_encoding()` to [`buffer:set_encoding()`][].
* Removed Adeptsense in favor of [autocompleter functions][], but kept existing
  [api file format][].
* Renamed `textadept.editing.autocomplete_word()` to
  [`textadept.editing.autocomplete`][]`('word')`.
* New [`textadept.editing.AUTOCOMPLETE_ALL`][] field for autocompleting words
  from all open buffers.
* Dropped support for official java, php, rails, and rhtml modules; they are
  on the wiki now.
* Removed `textadept.editing.HIGHLIGHT_BRACES` option, as indicator style can be
  changed to hide highlighting.
* Removed `textadept.editing.select_indented_block()`.
* In-place menu editing via [`textadept.menu.menubar`][],
  [`textadept.menu.context_menu`][], and [`textadept.menu.tab_context_menu`][]
  tables.
* Removed `textadept.command_entry.complete_lua()` and
  `textadept.command_entry.execute_lua()` and moved their key bindings into
  their module.
* Updated to [Scintilla][] 3.4.2.

[Textadept 7.3 -- Win32]: download/textadept_7.3.win32.zip
[Textadept 7.3 -- Mac OSX Intel 10.5+]: download/textadept_7.3.osx.zip
[Textadept 7.3 -- Linux]: download/textadept_7.3.i386.tgz
[Textadept 7.3 -- Linux x86_64]: download/textadept_7.3.x86_64.tgz
[Textadept 7.3 -- Modules]: download/textadept_7.3.modules.zip
[`spawn()`]: api.html#spawn
[`buffer:set_encoding()`]: api.html#buffer.set_encoding
[autocompleter functions]: api.html#textadept.editing.autocompleters
[api file format]: api.html#textadept.editing.api_files
[`textadept.editing.autocomplete`]: api.html#textadept.editing.autocomplete
[`textadept.editing.AUTOCOMPLETE_ALL`]: api.html#textadept.editing.AUTOCOMPLETE_ALL
[`textadept.menu.menubar`]: api.html#textadept.menu.menubar
[`textadept.menu.context_menu`]: api.html#textadept.menu.context_menu
[`textadept.menu.tab_context_menu`]: api.html#textadept.menu.tab_context_menu
[Scintilla]: http://scintilla.org

## 7.2 (01 May 2014)

Download:

* [Textadept 7.2 -- Win32][]
* [Textadept 7.2 -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 -- Linux][]
* [Textadept 7.2 -- Linux x86_64][]
* [Textadept 7.2 -- Modules][]

Bugfixes:

* None.

Changes:

* Message buffer can send input to spawned processes.

[Textadept 7.2 -- Win32]: download/textadept_7.2.win32.zip
[Textadept 7.2 -- Mac OSX Intel 10.5+]: download/textadept_7.2.osx.zip
[Textadept 7.2 -- Linux]: download/textadept_7.2.i386.tgz
[Textadept 7.2 -- Linux x86_64]: download/textadept_7.2.x86_64.tgz
[Textadept 7.2 -- Modules]: download/textadept_7.2.modules.zip

## 7.2 beta 4 (11 Apr 2014)

Download:

* [Textadept 7.2 beta 4 -- Win32][]
* [Textadept 7.2 beta 4 -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 beta 4 -- Linux][]
* [Textadept 7.2 beta 4 -- Linux x86_64][]
* [Textadept 7.2 beta 4 -- Modules][]

Bugfixes:

* Fixed bug in parsing output from a cancelled dropdown dialog.
* Always use absolute file paths so sessions are saved and reloaded properly.
* Temporarily disabled asynchronous spawning on OSX due to GLib crashes.

Changes:

* None.

[Textadept 7.2 beta 4 -- Win32]: download/textadept_7.2_beta_4.win32.zip
[Textadept 7.2 beta 4 -- Mac OSX Intel 10.5+]: download/textadept_7.2_beta_4.osx.zip
[Textadept 7.2 beta 4 -- Linux]: download/textadept_7.2_beta_4.i386.tgz
[Textadept 7.2 beta 4 -- Linux x86_64]: download/textadept_7.2_beta_4.x86_64.tgz
[Textadept 7.2 beta 4 -- Modules]: download/textadept_7.2_beta_4.modules.zip

## 7.2 beta 3 (01 Apr 2014)

Download:

* [Textadept 7.2 beta 3 -- Win32][]
* [Textadept 7.2 beta 3 -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 beta 3 -- Linux][]
* [Textadept 7.2 beta 3 -- Linux x86_64][]
* [Textadept 7.2 beta 3 -- Modules][]

Bugfixes:

* Fixed bug in Win32 terminal version with "shifted" character input.

Changes:

* New [optionselect][] dialog.
* Added [`ui.SILENT_PRINT`][] option for printing messages.
* The GUI version can [spawn processes][] in separate threads.
* Removed experimental Windows `io.popen()` and `os.execute()` replacements due
  to spawning support.
* [Snapopen][] now supports projects; added new menu entry and key command.
* Added support for [building projects][].
* Updated to [LuaJIT][] 2.0.3.
* Updated to [Scintilla][] 3.4.1.

[Textadept 7.2 beta 3 -- Win32]: download/textadept_7.2_beta_3.win32.zip
[Textadept 7.2 beta 3 -- Mac OSX Intel 10.5+]: download/textadept_7.2_beta_3.osx.zip
[Textadept 7.2 beta 3 -- Linux]: download/textadept_7.2_beta_3.i386.tgz
[Textadept 7.2 beta 3 -- Linux x86_64]: download/textadept_7.2_beta_3.x86_64.tgz
[Textadept 7.2 beta 3 -- Modules]: download/textadept_7.2_beta_3.modules.zip
[optionselect]: api.html#ui.dialogs.optionselect
[`ui.SILENT_PRINT`]: api.html#ui.SILENT_PRINT
[spawn processes]: api.html#spawn
[Snapopen]: manual.html#Snapopen
[building projects]: api.html#_M.Build.a.Project
[LuaJIT]: http://luajit.org
[Scintilla]: http://scintilla.org

## 7.2 beta 2 (01 Mar 2014)

Download:

* [Textadept 7.2 beta 2 -- Win32][]
* [Textadept 7.2 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 beta 2 -- Linux][]
* [Textadept 7.2 beta 2 -- Linux x86_64][]
* [Textadept 7.2 beta 2 -- Modules][]

Bugfixes:

* Fixed bug with empty entries in multiple entry inputboxes.

Changes:

* Terminal version now has split views along with key bindings for them.

[Textadept 7.2 beta 2 -- Win32]: download/textadept_7.2_beta_2.win32.zip
[Textadept 7.2 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_7.2_beta_2.osx.zip
[Textadept 7.2 beta 2 -- Linux]: download/textadept_7.2_beta_2.i386.tgz
[Textadept 7.2 beta 2 -- Linux x86_64]: download/textadept_7.2_beta_2.x86_64.tgz
[Textadept 7.2 beta 2 -- Modules]: download/textadept_7.2_beta_2.modules.zip

## 7.2 beta (11 Feb 2014)

Download:

* [Textadept 7.2 beta -- Win32][]
* [Textadept 7.2 beta -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 beta -- Linux][]
* [Textadept 7.2 beta -- Linux x86_64][]
* [Textadept 7.2 beta -- Modules][]

Bugfixes:

* Handle *./* and *../* sequences in filepaths.
* Correctly restore views with word wrap enabled.

Changes:

* Added Swedish translation.
* Added support for multiple entry boxes in [inputdialogs][].
* Updated to [Scintilla][] 3.3.9.

[Textadept 7.2 beta -- Win32]: download/textadept_7.2_beta.win32.zip
[Textadept 7.2 beta -- Mac OSX Intel 10.5+]: download/textadept_7.2_beta.osx.zip
[Textadept 7.2 beta -- Linux]: download/textadept_7.2_beta.i386.tgz
[Textadept 7.2 beta -- Linux x86_64]: download/textadept_7.2_beta.x86_64.tgz
[Textadept 7.2 beta -- Modules]: download/textadept_7.2_beta.modules.zip
[inputdialogs]: api.html#ui.dialogs.inputbox
[Scintilla]: http://scintilla.org

## 7.2 alpha (01 Jan 2014)

Download:

* [Textadept 7.2 alpha -- Win32][]
* [Textadept 7.2 alpha -- Mac OSX Intel 10.5+][]
* [Textadept 7.2 alpha -- Linux][]
* [Textadept 7.2 alpha -- Linux x86_64][]
* [Textadept 7.2 alpha -- Modules][]

Bugfixes:

* Honor [`ui.maximized`][] setting in session files.
* Do not halt opening files if one of them is already open.
* Better key input handling in the terminal version.
* Fixed Makefile bug in grabbing dependencies with older versions of wget.
* Recognize lower-case drive letter names for files passed from external
  programs in Windows.

Changes:

* Added Dart lexer.
* Do not split the view when printing messages if tabs are enabled.
* Look for *~/.textadept/osx_env.sh* for [OSX environment variables][] due to
  changes in Mac OSX 10.9.
* [Experimental] Replaced Lua's `io.popen()` and `os.execute()` with versions
  that do not flash the "black box" on Windows.
* Added read-only access to the current key chain via [`keys.keychain`][].
* Renamed "hypertext" lexer and its corresponding module to "html".
* Added configurable tab context menus via `textadept.menu.set_contextmenus()`.
* New GUI theme for Mac OSX.
* [Experimental] Merged separate lexer states into Textadept's Lua state.
* Updated to [Lua][] 5.2.3.
* Updated to [Scintilla][] 3.3.7.

[Textadept 7.2 alpha -- Win32]: download/textadept_7.2_alpha.win32.zip
[Textadept 7.2 alpha -- Mac OSX Intel 10.5+]: download/textadept_7.2_alpha.osx.zip
[Textadept 7.2 alpha -- Linux]: download/textadept_7.2_alpha.i386.tgz
[Textadept 7.2 alpha -- Linux x86_64]: download/textadept_7.2_alpha.x86_64.tgz
[Textadept 7.2 alpha -- Modules]: download/textadept_7.2_alpha.modules.zip
[`ui.maximized`]: api.html#ui.maximized
[OSX environment variables]: manual.html#Mac.OSX.Environment.Variables
[`keys.keychain`]: api.html#keys.keychain
[Lua]: http://lua.org
[Scintilla]: http://scintilla.org

## 7.1 (11 Nov 2013)

Download:

* [Textadept 7.1 -- Win32][]
* [Textadept 7.1 -- Mac OSX Intel 10.5+][]
* [Textadept 7.1 -- Linux][]
* [Textadept 7.1 -- Linux x86_64][]
* [Textadept 7.1 -- Modules][]

Bugfixes:

* Textbox dialogs' `scroll_to` option works correctly.
* Emit autocompletion and hotspot events properly.
* Handle replacement captures with escapes properly.

Changes:

* Tabs for multiple buffers along with [`ui.tabs`][] API.
* Split C/C++ lexer into separate lexers and replaced default "cpp" module with
  "ansi\_c".
* Find and replace text may utilize "%0" capture containing the entire match.
* Disable [`textadept.editing.STRIP_TRAILING_SPACES`][] by default.
* [`ui.clipboard_text`][] is no longer read-only.
* Added [`events.FILE_CHANGED`][] event.

[Textadept 7.1 -- Win32]: download/textadept_7.1.win32.zip
[Textadept 7.1 -- Mac OSX Intel 10.5+]: download/textadept_7.1.osx.zip
[Textadept 7.1 -- Linux]: download/textadept_7.1.i386.tgz
[Textadept 7.1 -- Linux x86_64]: download/textadept_7.1.x86_64.tgz
[Textadept 7.1 -- Modules]: download/textadept_7.1.modules.zip
[`ui.tabs`]: api.html#ui.tabs
[`textadept.editing.STRIP_TRAILING_SPACES`]: api.html#textadept.editing.STRIP_TRAILING_SPACES
[`ui.clipboard_text`]: api.html#ui.clipboard_text
[`events.FILE_CHANGED`]: api.html#events.FILE_CHANGED

## 7.0 (01 Nov 2013)

Please see the [6 to 7 migration guide][] for upgrading from Textadept 6 to
Textadept 7.

Download:

* [Textadept 7.0 -- Win32][]
* [Textadept 7.0 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 -- Linux][]
* [Textadept 7.0 -- Linux x86_64][]
* [Textadept 7.0 -- Modules][]

Bugfixes:

* Fixed bug with `buffer.SCFIND_REGEX` flag.
* Fixed OSX Command key recognition for click events.
* Fixed compile error with GTK3.

Changes:

* Added Assembly (NASM) lexer with compile and run commands.
* `textadept.adeptsense.goto_ctag()` can show all known tags now.
* [`textadept.editing.enclose()`][] encloses the whole current word.

[6 to 7 migration guide]: manual.html#Textadept.6.to.7
[Textadept 7.0 -- Win32]: download/textadept_7.0.win32.zip
[Textadept 7.0 -- Mac OSX Intel 10.5+]: download/textadept_7.0.osx.zip
[Textadept 7.0 -- Linux]: download/textadept_7.0.i386.tgz
[Textadept 7.0 -- Linux x86_64]: download/textadept_7.0.x86_64.tgz
[Textadept 7.0 -- Modules]: download/textadept_7.0.modules.zip
[`textadept.editing.enclose()`]: api.html#textadept.editing.enclose

## 7.0 beta 5 (21 Oct 2013)

Download:

* [Textadept 7.0 beta 5 -- Win32][]
* [Textadept 7.0 beta 5 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 beta 5 -- Linux][]
* [Textadept 7.0 beta 5 -- Linux x86_64][]
* [Textadept 7.0 beta 5 -- Modules][]

Bugfixes:

* Show more helpful user-init startup error messages.
* Lua run command buffers output correctly.
* Fixed corner case in paragraph selection.
* Fixed corner case in block uncommenting.

Changes:

* Changed [`ui.set_theme()`][] API to accept a table of property assignments.
* Added Nimrod lexer and compile and run commands.
* Use [`textadept.editing.INDIC_BRACEMATCH`][] indicator for brace highlighting
  instead of styles.
* The [`buffer`][] API applies to all buffers now, not just the global one.
* Added "Save All" to the menu.

[Textadept 7.0 beta 5 -- Win32]: download/textadept_7.0_beta_5.win32.zip
[Textadept 7.0 beta 5 -- Mac OSX Intel 10.5+]: download/textadept_7.0_beta_5.osx.zip
[Textadept 7.0 beta 5 -- Linux]: download/textadept_7.0_beta_5.i386.tgz
[Textadept 7.0 beta 5 -- Linux x86_64]: download/textadept_7.0_beta_5.x86_64.tgz
[Textadept 7.0 beta 5 -- Modules]: download/textadept_7.0_beta_5.modules.zip
[`ui.set_theme()`]: api.html#ui.set_theme
[`textadept.editing.INDIC_BRACEMATCH`]: api.html#textadept.editing.INDIC_BRACEMATCH
[`buffer`]: api.html#buffer

## 7.0 beta 4 (01 Oct 2013)

Download:

* [Textadept 7.0 beta 4 -- Win32][]
* [Textadept 7.0 beta 4 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 beta 4 -- Linux][]
* [Textadept 7.0 beta 4 -- Linux x86_64][]
* [Textadept 7.0 beta 4 -- Modules][]

Bugfixes:

* Fixed various compile and install errors.
* Fixed error when block commenting plain text.

Changes:

* [`events.disconnect()`][] now accepts function argument instead of ID.
* [`buffer.filename`][] and all internal filenames are no longer encoded in
  UTF-8, but in [`_CHARSET`][].
* Removed many unused Scintilla constants and stripped many constants of `SC`
  and `SC_` prefixes.
* Changed marker margin symbols via *properties.lua*.
* Calling [`textadept.editing.select_word()`][] repeatedly makes multiple
  selections.
* Renamed `buffer:convert_eo_ls()` to [`convert_eols()`].
* Added [`textadept.run.MARK_WARNING`][] marker.
* Renamed `textadept.run.compile_command` and `textadept.run.run_command` to
  [`compile_commands`][] and [`run_commands`][], respectively.
* Renamed `textadept.run.error_detail` to [`error_patterns`][] and changed its
  internal structure.
* Compile and run commands for languages that support them are now built-in
  along with their respective warning and error messages. The supplemental ones
  on the wiki are no longer needed.
* New [`ui.dialogs`][] module for more user-friendly dialog support. Removed
  `ui.filteredlist()` as a result.
* Changed [`io.open_file()`][] and [`io.snapopen()`][] to accept tables of files
  and paths instead of "\n" delimited strings.

[Textadept 7.0 beta 4 -- Win32]: download/textadept_7.0_beta_4.win32.zip
[Textadept 7.0 beta 4 -- Mac OSX Intel 10.5+]: download/textadept_7.0_beta_4.osx.zip
[Textadept 7.0 beta 4 -- Linux]: download/textadept_7.0_beta_4.i386.tgz
[Textadept 7.0 beta 4 -- Linux x86_64]: download/textadept_7.0_beta_4.x86_64.tgz
[Textadept 7.0 beta 4 -- Modules]: download/textadept_7.0_beta_4.modules.zip
[`events.disconnect()`]: api.html#events.disconnect
[`buffer.filename`]: api.html#buffer.filename
[`_CHARSET`]: api.html#_CHARSET
[`textadept.editing.select_word()`]: api.html#textadept.editing.select_word
[`convert_eols()`]: api.html#buffer.convert_eols
[`textadept.run.MARK_WARNING`]: api.html#textadept.run.MARK_WARNING
[`compile_commands`]: api.html#textadept.run.compile_commands
[`run_commands`]: api.html#textadept.run.run_commands
[`error_patterns`]: api.html#textadept.run.error_patterns
[`ui.dialogs`]: api.html#ui.dialogs
[`io.open_file()`]: api.html#io.open_file
[`io.snapopen()`]: api.html#io.snapopen

## 7.0 beta 3 (11 Sep 2013)

Download:

* [Textadept 7.0 beta 3 -- Win32][]
* [Textadept 7.0 beta 3 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 beta 3 -- Linux][]
* [Textadept 7.0 beta 3 -- Linux x86_64][]
* [Textadept 7.0 beta 3 -- Modules][]

Bugfixes:

* User functions that connect to `events.BUFFER_NEW` and `events.VIEW_NEW` are
  run on startup.
* Fixed potential crash caused by split views.

Changes:

* Copied constants from `_SCINTILLA.constants` into `buffer`.
* Renamed `events.LANGUAGE_MODULE_LOADED` to [`events.LEXER_LOADED`][].
* Renamed `gui` to [`ui`][].
* Renamed `_M.textadept` to [`textadept`][].
* New [`events.INITIALIZED`][] event.
* Renamed `buffer:get_style_name()` to [`buffer.style_name`][].
* Renamed `ui.docstatusbar_text` to [`ui.bufstatusbar_text`][].
* Removed `textadept.bookmarks.BOOKMARK_COLOR`,
  `textadept.editing.HIGHLIGHT_COLOR`, and `textadept.run.ERROR_COLOR` while
  exposing their respective marker and indicator numbers for customization.
* Moved buffer IO functions into [`io` module][].
* Updated to [CDK][] 5.0-20130901.

[Textadept 7.0 beta 3 -- Win32]: download/textadept_7.0_beta_3.win32.zip
[Textadept 7.0 beta 3 -- Mac OSX Intel 10.5+]: download/textadept_7.0_beta_3.osx.zip
[Textadept 7.0 beta 3 -- Linux]: download/textadept_7.0_beta_3.i386.tgz
[Textadept 7.0 beta 3 -- Linux x86_64]: download/textadept_7.0_beta_3.x86_64.tgz
[Textadept 7.0 beta 3 -- Modules]: download/textadept_7.0_beta_3.modules.zip
[`events.LEXER_LOADED`]: api.html#events.LEXER_LOADED
[`ui`]: api.html#ui
[`textadept`]: api.html#textadept
[`events.INITIALIZED`]: api.html#events.INITIALIZED
[`buffer.style_name`]: api.html#buffer.style_name
[`ui.bufstatusbar_text`]: api.html#ui.bufstatusbar_text
[`io` module]: api.html#io
[CDK]: http://invisible-island.net/cdk/cdk.html

## 7.0 beta 2 (11 Aug 2013)

Download:

* [Textadept 7.0 beta 2 -- Win32][]
* [Textadept 7.0 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 beta 2 -- Linux][]
* [Textadept 7.0 beta 2 -- Linux x86_64][]
* [Textadept 7.0 beta 2 -- Modules][]

Bugfixes:

* Fixed bug with theme loading when resetting.
* Fixed bug with property settings in [`gui.set_theme()`][] not persisting.

Changes:

* New [`gui.maximized`][] field so Textadept can remember its maximized state.
* Updated to [Scintilla][] 3.3.4.

[Textadept 7.0 beta 2 -- Win32]: download/textadept_7.0_beta_2.win32.zip
[Textadept 7.0 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_7.0_beta_2.osx.zip
[Textadept 7.0 beta 2 -- Linux]: download/textadept_7.0_beta_2.i386.tgz
[Textadept 7.0 beta 2 -- Linux x86_64]: download/textadept_7.0_beta_2.x86_64.tgz
[Textadept 7.0 beta 2 -- Modules]: download/textadept_7.0_beta_2.modules.zip
[`gui.set_theme()`]: api.html#ui.set_theme
[`gui.maximized`]: api.html#ui.maximized
[Scintilla]: http://scintilla.org

## 7.0 beta (11 Jul 2013)

Download:

* [Textadept 7.0 beta -- Win32][]
* [Textadept 7.0 beta -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 beta -- Linux][]
* [Textadept 7.0 beta -- Linux x86_64][]
* [Textadept 7.0 beta -- Modules][]

Bugfixes:

* Added file type for Go.
* Fixed disorienting scrolling in some instances of splitting views.
* Fixed corner-case bug in Lua Pattern "Replace All".

Changes:

* Renamed `_M.textadept.mime_types` to [`_M.textadept.file_types`][].
* Eliminated *mime_types.conf* files. Add or modify file type tables
  [directly][].
* Changed scrollbar look and feel on Mac OSX.

[Textadept 7.0 beta -- Win32]: download/textadept_7.0_beta.win32.zip
[Textadept 7.0 beta -- Mac OSX Intel 10.5+]: download/textadept_7.0_beta.osx.zip
[Textadept 7.0 beta -- Linux]: download/textadept_7.0_beta.i386.tgz
[Textadept 7.0 beta -- Linux x86_64]: download/textadept_7.0_beta.x86_64.tgz
[Textadept 7.0 beta -- Modules]: download/textadept_7.0_beta.modules.zip
[`_M.textadept.file_types`]: api.html#textadept.file_types
[directly]: manual.html#File.Types

## 7.0 alpha 2 (01 Jul 2013)

Download:

* [Textadept 7.0 alpha 2 -- Win32][]
* [Textadept 7.0 alpha 2 -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 alpha 2 -- Linux][]
* [Textadept 7.0 alpha 2 -- Linux x86_64][]
* [Textadept 7.0 alpha 2 -- Modules][]

Bugfixes:

* Fixed bug in user theme loading.
* Fixed "Enter" key autocompletion in curses.
* Fixed crash when transposing in an empty buffer.
* Fixed bug in find and run double-click event handlers.

Changes:

* Makefile improvements. See [compiling][] for more information. The source
  release is no longer necessary.
* Removed `_G._LEXERPATH` and `_L._EXISTS()`.
* Renamed Adeptsense image fields.
* Renamed `_M.textadept.editing.STRIP_WHITESPACE_ON_SAVE` to
  `STRIP_TRAILING_SPACES`.
* [`_M.textadept.editing.block_comment()`][] supports block comment delimiters.
* Block comments for languages is now built-in. The supplemental ones on the
  wiki are no longer needed.
* [`gui.set_theme()`][] accepts key-value argument pairs for overriding theme
  properties.
* Removed `gui.select_theme()` since selected themes do not persist.
* Removed `_G.RESETTING` flag.
* Consolidated `_M.textadept.bookmarks.goto_*()` functionality into
  [`_M.textadept.bookmarks.goto_mark()`][].
* Updated to [LuaJIT][] 2.0.2.
* New [nightly builds][].

[Textadept 7.0 alpha 2 -- Win32]: download/textadept_7.0_alpha_2.win32.zip
[Textadept 7.0 alpha 2 -- Mac OSX Intel 10.5+]: download/textadept_7.0_alpha_2.osx.zip
[Textadept 7.0 alpha 2 -- Linux]: download/textadept_7.0_alpha_2.i386.tgz
[Textadept 7.0 alpha 2 -- Linux x86_64]: download/textadept_7.0_alpha_2.x86_64.tgz
[Textadept 7.0 alpha 2 -- Modules]: download/textadept_7.0_alpha_2.modules.zip
[compiling]: manual.html#Compiling
[`_M.textadept.editing.block_comment()`]: api.html#textadept.editing.block_comment
[`gui.set_theme()`]: api.html#ui.set_theme
[`_M.textadept.bookmarks.goto_mark()`]: api.html#textadept.bookmarks.goto_mark
[LuaJIT]: http://luajit.org
[nightly builds]: README.html#Download

## 7.0 alpha (01 Jun 2013)

Download:

* [Textadept 7.0 alpha -- Win32][]
* [Textadept 7.0 alpha -- Mac OSX Intel 10.5+][]
* [Textadept 7.0 alpha -- Linux][]
* [Textadept 7.0 alpha -- Linux x86_64][]
* [Textadept 7.0 alpha -- Source][]
* [Textadept 7.0 alpha -- Modules][]

Bugfixes:

* None.

Changes:

* Completely new [theme implementation][].
* New [*properties.lua*][] for custom buffer and view properties.
* Updated to [Scintilla][] 3.3.3.

[Textadept 7.0 alpha -- Win32]: download/textadept_7.0_alpha.win32.zip
[Textadept 7.0 alpha -- Mac OSX Intel 10.5+]: download/textadept_7.0_alpha.osx.zip
[Textadept 7.0 alpha -- Linux]: download/textadept_7.0_alpha.i386.tgz
[Textadept 7.0 alpha -- Linux x86_64]: download/textadept_7.0_alpha.x86_64.tgz
[Textadept 7.0 alpha -- Source]: download/textadept_7.0_alpha.src.zip
[Textadept 7.0 alpha -- Modules]: download/textadept_7.0_alpha.modules.zip
[theme implementation]: manual.html#Themes
[*properties.lua*]: manual.html#Buffer.Settings
[Scintilla]: http://scintilla.org

## 6.6 (01 Jun 2013)

Download:

* [Textadept 6.6 -- Win32][]
* [Textadept 6.6 -- Mac OSX Intel 10.5+][]
* [Textadept 6.6 -- Linux][]
* [Textadept 6.6 -- Linux x86_64][]
* [Textadept 6.6 -- Source][]
* [Textadept 6.6 -- Modules][]

Bugfixes:

* Fixed GTK assertion errors in find/replace history.
* Command entry loses focus less often.
* Allow empty tables as keychains if they have metatables.
* Fixed caret placement in block comment/uncomment.
* Use '\n' keycode in curses instead of '\r'.
* Fixed crash caused by split views.

Changes:

* Removed `_M[lang].set_buffer_properties()` functions. Set properties through
  `events.LANGUAGE_MODULE_LOADED` instead.
* Print the results of '=' Lua commands.
* Updated to [Scintilla][] 3.3.2.

[Textadept 6.6 -- Win32]: download/textadept_6.6.win32.zip
[Textadept 6.6 -- Mac OSX Intel 10.5+]: download/textadept_6.6.osx.zip
[Textadept 6.6 -- Linux]: download/textadept_6.6.i386.tgz
[Textadept 6.6 -- Linux x86_64]: download/textadept_6.6.x86_64.tgz
[Textadept 6.6 -- Source]: download/textadept_6.6.src.zip
[Textadept 6.6 -- Modules]: download/textadept_6.6.modules.zip
[Scintilla]: http://scintilla.org

## 6.6 beta (01 May 2013)

Download:

* [Textadept 6.6 beta -- Win32][]
* [Textadept 6.6 beta -- Mac OSX Intel 10.5+][]
* [Textadept 6.6 beta -- Linux][]
* [Textadept 6.6 beta -- Linux x86_64][]
* [Textadept 6.6 beta -- Source][]
* [Textadept 6.6 beta -- Modules][]

Bugfixes:

* Fixed rendering on Mac OSX retina displays.
* Fixed rectangle indicator display in curses.
* Fixed Fn key recognition on Mac OSX.
* Fixed compile errors for Mac OSX.
* Find Previous for Lua patterns works.

Changes:

* Textadept supports multiple curses platforms, not just ncurses. Make targets
  now use "curses" instead of "ncurses".
* Better 16-color terminal support in lexer theme.
* Reduced the delay when pressing `Esc` in curses.
* [Messagebox][] dialogs can show icons via `--icon` and `--icon-file`.
* New Win32 terminal version.
* New [key modes][] functionality.
* Updated to [Scintilla][] 3.3.1.
* Renamed `_G.buffer_new()` to [`buffer.new()`][].
* Changed the display of highlighted words, including removing
  `_M.textadept.editing.INDIC_HIGHLIGHT_ALPHA`.
* Changed `_M.textadept.editing.autocomplete_word()` API.
* Removed `_M.textadept.menu.menubar`, `_M.textadept.menu.contextmenu`, and
  `events.handlers` tables from the API.
* Moved `_M.textadept.filter_through` module functionality into
  [`_M.textadept.editing.filter_through()`][].
* Mark errors in compile/run commands and added
  [`_M.textadept.run.goto_error()`][] menu options and key shortcuts.
* Renamed `gui.find.goto_file_in_list()` to [`gui.find.goto_file_found()`][].
* Consolidated `_M.textadept.editing.grow_selection()` functionality into
  [`_M.textadept.editing.select_enclosed()`][].
* Renamed `io.try_encodings` to [`io.encodings`][].

[Textadept 6.6 beta -- Win32]: download/textadept_6.6_beta.win32.zip
[Textadept 6.6 beta -- Mac OSX Intel 10.5+]: download/textadept_6.6_beta.osx.zip
[Textadept 6.6 beta -- Linux]: download/textadept_6.6_beta.i386.tgz
[Textadept 6.6 beta -- Linux x86_64]: download/textadept_6.6_beta.x86_64.tgz
[Textadept 6.6 beta -- Source]: download/textadept_6.6_beta.src.zip
[Textadept 6.6 beta -- Modules]: download/textadept_6.6_beta.modules.zip
[Messagebox]: http://foicica.com/gtdialog/manual.html#Messageboxes
[key modes]: api.html#keys.Modes
[Scintilla]: http://scintilla.org
[`buffer.new()`]: api.html#buffer.new
[`_M.textadept.editing.filter_through()`]: api.html#textadept.editing.filter_through
[`_M.textadept.run.goto_error()`]: api.html#textadept.run.goto_error
[`gui.find.goto_file_found()`]: api.html#ui.find.goto_file_found
[`_M.textadept.editing.select_enclosed()`]: api.html#textadept.editing.select_enclosed
[`io.encodings`]: api.html#io.encodings

## 6.5 (01 Apr 2013)

Download:

* [Textadept 6.5 -- Win32][]
* [Textadept 6.5 -- Mac OSX Intel 10.5+][]
* [Textadept 6.5 -- Linux][]
* [Textadept 6.5 -- Linux x86_64][]
* [Textadept 6.5 -- Source][]
* [Textadept 6.5 -- Modules][]

Bugfixes:

* Only consider visible directories in *_USERHOME/themes/* as themes.
* Indicator for highlighted words works in ncurses.
* Improved message double-clicking behavior for compile and run commands by
  adding [`_M.textadept.run.cwd`][].
* Fixed disorienting scrolling when wrapping only one search result.

Changes:

* Reset Lua state after selecting a new theme.
* Added [`lfs.dir_foreach()`][].
* Added file and directory [filtering][] for Find in Files.
* Moved `_M.textadept.snapopen` into [`io`][].
* Renamed some [`lexer` constants][].
* Added Less, Literal Coffeescript, and Sass lexers.
* Updated to [Scintilla][] 3.3.0.
* Updated to [Lua][] 5.2.2.

[Textadept 6.5 -- Win32]: download/textadept_6.5.win32.zip
[Textadept 6.5 -- Mac OSX Intel 10.5+]: download/textadept_6.5.osx.zip
[Textadept 6.5 -- Linux]: download/textadept_6.5.i386.tgz
[Textadept 6.5 -- Linux x86_64]: download/textadept_6.5.x86_64.tgz
[Textadept 6.5 -- Source]: download/textadept_6.5.src.zip
[Textadept 6.5 -- Modules]: download/textadept_6.5.modules.zip
[`_M.textadept.run.cwd`]: api.html#textadept.run.cwd
[`lfs.dir_foreach()`]: api.html#lfs.dir_foreach
[filtering]: api.html#ui.find.FILTER
[`io`]: api.html#io.snapopen
[`lexer` constants]: api.html#lexer.FOLD_BASE
[Scintilla]: http://scintilla.org
[Lua]: http://lua.org

## 6.4 (01 Mar 2013)

Download:

* [Textadept 6.4 -- Win32][]
* [Textadept 6.4 -- Mac OSX Intel 10.5+][]
* [Textadept 6.4 -- Linux][]
* [Textadept 6.4 -- Linux x86_64][]
* [Textadept 6.4 -- Source][]
* [Textadept 6.4 -- Modules][]

Bugfixes:

* Dialogs belong to the Textadept window.
* Fixed bug in documentation link generator.
* Fixed bug with indexable buffer properties that return strings.

Changes:

* Added [command line switches][] for loading sessions on startup.
* Added [command line switches][] for running Lua code on startup.
* Updated to [Scintilla][] 3.2.5.
* Updated to [LuaJIT][] 2.0.1.

[Textadept 6.4 -- Win32]: download/textadept_6.4.win32.zip
[Textadept 6.4 -- Mac OSX Intel 10.5+]: download/textadept_6.4.osx.zip
[Textadept 6.4 -- Linux]: download/textadept_6.4.i386.tgz
[Textadept 6.4 -- Linux x86_64]: download/textadept_6.4.x86_64.tgz
[Textadept 6.4 -- Source]: download/textadept_6.4.src.zip
[Textadept 6.4 -- Modules]: download/textadept_6.4.modules.zip
[command line switches]: manual.html#Command.Line.Parameters
[Scintilla]: http://scintilla.org
[LuaJIT]: http://luajit.org

## 6.3 (01 Feb 2013)

Download:

* [Textadept 6.3 -- Win32][]
* [Textadept 6.3 -- Mac OSX Intel 10.5+][]
* [Textadept 6.3 -- Linux][]
* [Textadept 6.3 -- Linux x86_64][]
* [Textadept 6.3 -- Source][]
* [Textadept 6.3 -- Modules][]

Bugfixes:

* Do not error on non-existant dropped URIs.
* Fixed crash in Python module when parsing some syntax error messages.

Changes:

* Use Scintilla API for ncurses mark mode.
* Updated to [Scintilla][] 3.2.4.
* Added [typeover characters][].

[Textadept 6.3 -- Win32]: download/textadept_6.3.win32.zip
[Textadept 6.3 -- Mac OSX Intel 10.5+]: download/textadept_6.3.osx.zip
[Textadept 6.3 -- Linux]: download/textadept_6.3.i386.tgz
[Textadept 6.3 -- Linux x86_64]: download/textadept_6.3.x86_64.tgz
[Textadept 6.3 -- Source]: download/textadept_6.3.src.zip
[Textadept 6.3 -- Modules]: download/textadept_6.3.modules.zip
[Scintilla]: http://scintilla.org
[typeover characters]: api.html#textadept.editing.TYPEOVER_CHARS

## 6.2 (01 Jan 2013)

Download:

* [Textadept 6.2 -- Win32][]
* [Textadept 6.2 -- Mac OSX Intel 10.5+][]
* [Textadept 6.2 -- Linux][]
* [Textadept 6.2 -- Linux x86_64][]
* [Textadept 6.2 -- Source][]
* [Textadept 6.2 -- Modules][]

Bugfixes:

* None.

Changes:

* Greatly improved speed when loading large files.
* `make install` and `make ncurses install` install separate binaries on Linux.
* Changed API for [`_M.textadept.snapopen.open()`][] and removed `PATHS`.

[Textadept 6.2 -- Win32]: download/textadept_6.2.win32.zip
[Textadept 6.2 -- Mac OSX Intel 10.5+]: download/textadept_6.2.osx.zip
[Textadept 6.2 -- Linux]: download/textadept_6.2.i386.tgz
[Textadept 6.2 -- Linux x86_64]: download/textadept_6.2.x86_64.tgz
[Textadept 6.2 -- Source]: download/textadept_6.2.src.zip
[Textadept 6.2 -- Modules]: download/textadept_6.2.modules.zip
[`_M.textadept.snapopen.open()`]: api.html#io.snapopen

## 6.1 (11 Dec 2012)

Download:

* [Textadept 6.1 -- Win32][]
* [Textadept 6.1 -- Mac OSX Intel 10.5+][]
* [Textadept 6.1 -- Linux][]
* [Textadept 6.1 -- Linux x86_64][]
* [Textadept 6.1 -- Source][]
* [Textadept 6.1 -- Modules][]

Bugfixes:

* Do not set current directory when opening/saving files.
* Detect Linux processor arch better.
* Recognize special ncurses keys better.
* Fixed potential bug with determining `_HOME` on Linux.
* Fixed bug when opening non-existent files from the command line.
* LuaJIT compiles correctly on ARM now.

Changes:

* Improved speed and memory usage of lexers.
* Better Makefile support for building packages for Linux distros.
* Rewrote LuaDoc [API documentation][].
* Added French translation.
* Updated to [LuaJIT][] 2.0.0.

[Textadept 6.1 -- Win32]: download/textadept_6.1.win32.zip
[Textadept 6.1 -- Mac OSX Intel 10.5+]: download/textadept_6.1.osx.zip
[Textadept 6.1 -- Linux]: download/textadept_6.1.i386.tgz
[Textadept 6.1 -- Linux x86_64]: download/textadept_6.1.x86_64.tgz
[Textadept 6.1 -- Source]: download/textadept_6.1.src.zip
[Textadept 6.1 -- Modules]: download/textadept_6.1.modules.zip
[API documentation]: api.html
[LuaJIT]: http://luajit.org

## 6.0 (01 Nov 2012)

Please see the [5 to 6 migration guide][] for upgrading from Textadept 5 to
Textadept 6.

Download:

* [Textadept 6.0 -- Win32][]
* [Textadept 6.0 -- Mac OSX Intel 10.5+][]
* [Textadept 6.0 -- Linux][]
* [Textadept 6.0 -- Linux x86_64][]
* [Textadept 6.0 -- Source][]
* [Textadept 6.0 -- Modules][]

Bugfixes:

* Handle rapidly pressing `Esc` twice in ncurses dialogs.
* Complete transition to `buffer.tab_size` from `buffer.indent`.
* Fixed regression in ncurses command selection.
* Fixed GUI menu key shortcut handling.
* Fixed string collation bug in ncurses due to CDK.
* Pass `Esc` to Scintilla correctly in ncurses.

Changes:

* Added key binding for toggling fold points.
* Added ncurses key bindings for bookmarks.
* Added [`event.FIND_WRAPPED`][] event.
* Removed `_M.textadept.run.execute()`.
* Updated documentation and documentation formatting.
* Added [Python module][].
* Updated to [Scintilla][] 3.2.3.
* Updated to [LuaJIT][] 2.0.0-beta11.

[5 to 6 migration guide]: manual.html#Textadept.5.to.6
[Textadept 6.0 -- Win32]: download/textadept_6.0.win32.zip
[Textadept 6.0 -- Mac OSX Intel 10.5+]: download/textadept_6.0.osx.zip
[Textadept 6.0 -- Linux]: download/textadept_6.0.i386.tgz
[Textadept 6.0 -- Linux x86_64]: download/textadept_6.0.x86_64.tgz
[Textadept 6.0 -- Source]: download/textadept_6.0.src.zip
[Textadept 6.0 -- Modules]: download/textadept_6.0.modules.zip
[`event.FIND_WRAPPED`]: api.html#events.FIND_WRAPPED
[Python module]: api.html#_M.python
[Scintilla]: http://scintilla.org
[LuaJIT]: http://luajit.org

## 6.0 beta 3 (01 Oct 2012)

Download:

* [Textadept 6.0 beta 3 -- Win32][]
* [Textadept 6.0 beta 3 -- Mac OSX Intel 10.5+][]
* [Textadept 6.0 beta 3 -- Linux][]
* [Textadept 6.0 beta 3 -- Linux x86_64][]
* [Textadept 6.0 beta 3 -- Source][]
* [Textadept 6.0 beta 3 -- Modules][]

Bugfixes:

* Cancelling in [`buffer:close()`][] caused unwanted key propagation.
* Correctly emit [`RUN_OUTPUT` events][].
* Fixed bug with extra empty entry in the buffer browser.
* Fixed incremental find in ncurses.
* Fixed ncurses crash when pasting with no clipboard text.
* Keep termios disabled in ncurses CDK widgets.
* Do not write ncurses initialization errors over titlebar.
* Fixed bug in [`string.iconv()`][].

Changes:

* Attempt to autodetect locale using `LANG` environment variable.
* Removed `_M.textadept.menu.rebuild_command_tables()`.
* Manual and Lua API documentation largely re-written.
* Key Bindings reference moved from Appendix to [`_M.textadept.keys`][] LuaDoc.
* Plain text lexer name changed from `container` to `text`.
* New application icon.
* Removed `./?.lua` and `./?.so` from `package.path` and `package.cpath`,
  respectively.
* Added marks for making selections in ncurses.

[Textadept 6.0 beta 3 -- Win32]: download/textadept_6.0_beta_3.win32.zip
[Textadept 6.0 beta 3 -- Mac OSX Intel 10.5+]: download/textadept_6.0_beta_3.osx.zip
[Textadept 6.0 beta 3 -- Linux]: download/textadept_6.0_beta_3.i386.tgz
[Textadept 6.0 beta 3 -- Linux x86_64]: download/textadept_6.0_beta_3.x86_64.tgz
[Textadept 6.0 beta 3 -- Source]: download/textadept_6.0_beta_3.src.zip
[Textadept 6.0 beta 3 -- Modules]: download/textadept_6.0_beta_3.modules.zip
[`buffer:close()`]: api.html#buffer.close
[`RUN_OUTPUT` events]: api.html#textadept.run.Run.Events
[`string.iconv()`]: api.html#string.iconv
[`_M.textadept.keys`]: api.html#textadept.keys

## 6.0 beta 2 (01 Sep 2012)

Download:

* [Textadept 6.0 beta 2 -- Win32][]
* [Textadept 6.0 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 6.0 beta 2 -- Linux][]
* [Textadept 6.0 beta 2 -- Linux x86_64][]
* [Textadept 6.0 beta 2 -- Source][]
* [Textadept 6.0 beta 2 -- Modules][]

Bugfixes:

* Disabled `--help` switch to ncurses version due to terminal output mangling.
* ncurses replace entry can now be focused.
* Fixed ncurses memory leaks.
* Fixed multiple selection in Mac OSX.
* Show key shortcuts in ncurses [`_M.textadept.menu.select_command()`][].

Changes:

* Added `make install` and `make uninstall` rules for optional installation.
* Updated manual with ncurses key commands.
* Consolidated `_M.textadept.bookmarks.add()` and
  `_M.textadept.bookmarks.remove()` into [`_M.textadept.bookmarks.toggle()`][].
* Updated manual images.
* `_M.textadept.snapopen.DEFAULT_DEPTH` is now `99` since [`MAX`][] is the
  limiting factor.
* Use constant names in theme options instead of nondescript integers.
* Updated to [Scintilla][] 3.2.2.

[Textadept 6.0 beta 2 -- Win32]: download/textadept_6.0_beta_2.win32.zip
[Textadept 6.0 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_6.0_beta_2.osx.zip
[Textadept 6.0 beta 2 -- Linux]: download/textadept_6.0_beta_2.i386.tgz
[Textadept 6.0 beta 2 -- Linux x86_64]: download/textadept_6.0_beta_2.x86_64.tgz
[Textadept 6.0 beta 2 -- Source]: download/textadept_6.0_beta_2.src.zip
[Textadept 6.0 beta 2 -- Modules]: download/textadept_6.0_beta_2.modules.zip
[`_M.textadept.menu.select_command()`]: api.html#textadept.menu.select_command
[`_M.textadept.bookmarks.toggle()`]: api.html#textadept.bookmarks.toggle
[`MAX`]: api.html#io.SNAPOPEN_MAX
[Scintilla]: http://scintilla.org

## 6.0 beta (01 Aug 2012)

Download:

* [Textadept 6.0 beta -- Win32][]
* [Textadept 6.0 beta -- Mac OSX Intel 10.5+][]
* [Textadept 6.0 beta -- Linux][]
* [Textadept 6.0 beta -- Linux x86_64][]
* [Textadept 6.0 beta -- Source][]
* [Textadept 6.0 beta -- Modules][]

Bugfixes:

* Lots of bugfixes to the experimental ncurses version.

Changes:

* Removed Lua, Ruby, and PHP modules' `goto_required()` functions.
* Moved `_M.textadept.editing.prepare_for_save()` directly into event handler.
* Moved `_M.textadept.session.prompt_load()` and `prompt_save()` functionality
  into [`_M.textadept.session.load()`][] and [`_M.textadept.session.save()`][].
* Removed `_G.user_dofile()`.
* Converted some `buffer` "get" and "set" functions into properties.
* Moved `_M.textadept.adeptsense.complete_symbol()` and `show_documentation()`
  functionality into `_M.textadept.adeptsense.complete()` and `show_apidoc()`.
* New 64-bit Windows version (note: without LuaJIT).
* Updated to [Scintilla][] 3.2.1.

[Textadept 6.0 beta -- Win32]: download/textadept_6.0_beta.win32.zip
[Textadept 6.0 beta -- Mac OSX Intel 10.5+]: download/textadept_6.0_beta.osx.zip
[Textadept 6.0 beta -- Linux]: download/textadept_6.0_beta.i386.tgz
[Textadept 6.0 beta -- Linux x86_64]: download/textadept_6.0_beta.x86_64.tgz
[Textadept 6.0 beta -- Source]: download/textadept_6.0_beta.src.zip
[Textadept 6.0 beta -- Modules]: download/textadept_6.0_beta.modules.zip
[`_M.textadept.session.load()`]: api.html#textadept.session.load
[`_M.textadept.session.save()`]: api.html#textadept.session.save
[Scintilla]: http://scintilla.org

## 5.5 beta (01 Jul 2012)

Download:

* [Textadept 5.5 beta -- Win32][]
* [Textadept 5.5 beta -- Mac OSX Intel 10.5+][]
* [Textadept 5.5 beta -- Linux][]
* [Textadept 5.5 beta -- Linux x86_64][]
* [Textadept 5.5 beta -- Source][]
* [Textadept 5.5 beta -- Modules][]

Bugfixes:

* None.

Changes:

* Experimental ncurses support.
* No more `'gtk-'` stock menu item support and changed `'separator'` to `''`.
* Renamed `gui.gtkmenu()` to [`gui.menu()`][].
* Changed [`gui.statusbar_text`][] to be write-only.
* Changed 'Quit' key command to 'Ctrl+Q' on Win32 and Linux.
* Show text that could not be localized.
* Changed `make` commands for [compiling][] Textadept.
* x86\_64 binary provides `libpng12` executables by default.
* Can cross compile to Mac OSX from Linux.
* Updated to [Lua 5.2.1][].
* Updated to [LuaJIT][] 2.0.0-beta10.

[Textadept 5.5 beta -- Win32]: download/textadept_5.5_beta.win32.zip
[Textadept 5.5 beta -- Mac OSX Intel 10.5+]: download/textadept_5.5_beta.osx.zip
[Textadept 5.5 beta -- Linux]: download/textadept_5.5_beta.i386.tgz
[Textadept 5.5 beta -- Linux x86_64]: download/textadept_5.5_beta.x86_64.tgz
[Textadept 5.5 beta -- Source]: download/textadept_5.5_beta.src.zip
[Textadept 5.5 beta -- Modules]: download/textadept_5.5_beta.modules.zip
[`gui.menu()`]: api.html#ui.menu
[`gui.statusbar_text`]: api.html#ui.statusbar_text
[compiling]: manual.html#Compiling
[Lua 5.2.1]: http://www.lua.org/manual/5.2/
[LuaJIT]: http://luajit.org

## 5.4 (01 Jun 2012)

Download:

* [Textadept 5.4 -- Win32][]
* [Textadept 5.4 -- Mac OSX Intel 10.5+][]
* [Textadept 5.4 -- Linux][]
* [Textadept 5.4 -- Linux x86_64][]
* [Textadept 5.4 -- Source][]
* [Textadept 5.4 -- Modules][]

Bugfixes:

* None.

Changes:

* Updated to [Scintilla][] 3.2.0.

[Textadept 5.4 -- Win32]: download/textadept_5.4.win32.zip
[Textadept 5.4 -- Mac OSX Intel 10.5+]: download/textadept_5.4.osx.zip
[Textadept 5.4 -- Linux]: download/textadept_5.4.tgz
[Textadept 5.4 -- Linux x86_64]: download/textadept_5.4.x86_64.tgz
[Textadept 5.4 -- Source]: download/textadept_5.4.src.zip
[Textadept 5.4 -- Modules]: download/textadept_5.4.modules.zip
[Scintilla]: http://scintilla.org

## 5.3 (01 May 2012)

Download:

* [Textadept 5.3 -- Win32][]
* [Textadept 5.3 -- Mac OSX Intel 10.5+][]
* [Textadept 5.3 -- Linux][]
* [Textadept 5.3 -- Linux x86_64][]
* [Textadept 5.3 -- Source][]
* [Textadept 5.3 -- Modules][]

Bugfixes:

* Fixed bug with run/compile commands in LuaJIT version.
* User annotation preferences are preserved.
* Fixed bug with number representation in some locales.

Changes:

* Annotations are used for showing run/compile command output.
* Textadept is [single-instance][] by default on Linux and Mac OSX.
* Textadept requires [GTK][] 2.18 or higher now instead of 2.16.
* The provided Textadept binaries [require][] [GLib][] 2.28 or higher.
* Updated to [Scintilla][] 3.1.0.

[Textadept 5.3 -- Win32]: download/textadept_5.3.win32.zip
[Textadept 5.3 -- Mac OSX Intel 10.5+]: download/textadept_5.3.osx.zip
[Textadept 5.3 -- Linux]: download/textadept_5.3.tgz
[Textadept 5.3 -- Linux x86_64]: download/textadept_5.3.x86_64.tgz
[Textadept 5.3 -- Source]: download/textadept_5.3.src.zip
[Textadept 5.3 -- Modules]: download/textadept_5.3.modules.zip
[single-instance]: manual.html#Single.Instance
[GTK]: http://gtk.org
[require]: manual.html#Requirements
[GLib]: http://gtk.org/download/linux.php
[Scintilla]: http://scintilla.org

## 5.2 (01 Apr 2012)

Download:

* [Textadept 5.2 -- Win32][]
* [Textadept 5.2 -- Mac OSX Intel 10.5+][]
* [Textadept 5.2 -- Linux][]
* [Textadept 5.2 -- Linux x86_64][]
* [Textadept 5.2 -- Source][]
* [Textadept 5.2 -- Modules][]

Bugfixes:

* Fixed LuaDoc for [`buffer:get_lexer()`][].
* Fixed bug with relative paths from command line files.
* [`buffer:get_lexer(true)`][] is used more often when it should be.
* Improved message double-clicking behavior for run and compile commands.

Changes:

* [`_M.set_buffer_properties()`][] is now optional for language modules.
* Added keypad keys to [`keys.KEYSYMS`][].
* [`_G.timeout()`][] accepts fractional seconds.
* Replaced `scripts/update_doc` with `src/Makefile` targets.
* New Manual and LuaDoc HTML page formatting.
* `_M.textadept.editing.autocomplete_word()` accepts default words.
* Added documentation on [generating LuaDoc][] and Lua Adeptsense.
* Moved `Markdown:` comments into LuaDoc.
* Added Spanish and German translations.
* Use [GTK][] 2.24 on Windows.
* Updated to [Scintilla][] 3.0.4.

[Textadept 5.2 -- Win32]: download/textadept_5.2.win32.zip
[Textadept 5.2 -- Mac OSX Intel 10.5+]: download/textadept_5.2.osx.zip
[Textadept 5.2 -- Linux]: download/textadept_5.2.tgz
[Textadept 5.2 -- Linux x86_64]: download/textadept_5.2.x86_64.tgz
[Textadept 5.2 -- Source]: download/textadept_5.2.src.zip
[Textadept 5.2 -- Modules]: download/textadept_5.2.modules.zip
[`buffer:get_lexer()`]: api.html#buffer.get_lexer
[`buffer:get_lexer(true)`]: api.html#buffer.get_lexer
[`_M.set_buffer_properties()`]: api.html#_M.Buffer.Properties
[`keys.KEYSYMS`]: api.html#keys.KEYSYMS
[`_G.timeout()`]: api.html#timeout
[generating LuaDoc]: manual.html#Generating.LuaDoc
[GTK]: http://gtk.org
[Scintilla]: http://scintilla.org

## 5.1 (01 Mar 2012)

Download:

* [Textadept 5.1 -- Win32][]
* [Textadept 5.1 -- Mac OSX Intel 10.5+][]
* [Textadept 5.1 -- Linux][]
* [Textadept 5.1 -- Linux x86_64][]
* [Textadept 5.1 -- Source][]
* [Textadept 5.1 -- Modules][]

Bugfixes:

* Fixed crash caused by `gui.filteredlist()` dialogs.
* Support multiple `@return` tags in Lua Adeptsense.
* Fixed display of `buffer._type` when it has slashes in its name.

Changes:

* Better Lua Adeptsense formatting.
* Use new Cocoa-based [GtkOSXApplication][] library for better OSX support.
* Lexers with no tokens can be styled manually.
* Added more OSX default key shortcuts.

[Textadept 5.1 -- Win32]: download/textadept_5.1.win32.zip
[Textadept 5.1 -- Mac OSX Intel 10.5+]: download/textadept_5.1.osx.zip
[Textadept 5.1 -- Linux]: download/textadept_5.1.tgz
[Textadept 5.1 -- Linux x86_64]: download/textadept_5.1.x86_64.tgz
[Textadept 5.1 -- Source]: download/textadept_5.1.src.zip
[Textadept 5.1 -- Modules]: download/textadept_5.1.modules.zip
[GtkOSXApplication]: https://live.gnome.org/GTK%2B/OSX/Integration#Gtk-mac-integration.2BAC8-GtkOSXApplication

## 5.0 (01 Feb 2012)

Please see the [4 to 5 migration guide][] for upgrading from Textadept 4 to
Textadept 5.

Download:

* [Textadept 5.0 -- Win32][]
* [Textadept 5.0 -- Mac OSX Intel 10.5+][]
* [Textadept 5.0 -- Linux][]
* [Textadept 5.0 -- Linux x86_64][]
* [Textadept 5.0 -- Source][]
* [Textadept 5.0 -- Modules][]

Bugfixes:

* Fixed bug with recent files in sessions.

Changes:

* Added default extension and folder filters in
  `modules/textadept/snapopen.lua`.
* Added ChucK lexer.
* Updated to [Scintilla][] 3.0.3.
* Also include [LuaJIT][] executables in releases.

[4 to 5 migration guide]: manual.html#Textadept.4.to.5
[Textadept 5.0 -- Win32]: download/textadept_5.0.win32.zip
[Textadept 5.0 -- Mac OSX Intel 10.5+]: download/textadept_5.0.osx.zip
[Textadept 5.0 -- Linux]: download/textadept_5.0.tgz
[Textadept 5.0 -- Linux x86_64]: download/textadept_5.0.x86_64.tgz
[Textadept 5.0 -- Source]: download/textadept_5.0.src.zip
[Textadept 5.0 -- Modules]: download/textadept_5.0.modules.zip
[Scintilla]: http://scintilla.org
[LuaJIT]: http://luajit.org

## 5.0 beta (11 Jan 2012)

Download:

* [Textadept 5.0 beta -- Win32][]
* [Textadept 5.0 beta -- Mac OSX Intel 10.5+][]
* [Textadept 5.0 beta -- Linux][]
* [Textadept 5.0 beta -- Linux x86_64][]
* [Textadept 5.0 beta -- Source][]
* [Textadept 5.0 beta -- Modules][]

Bugfixes:

* Fixed bug in [`reset()`][] from update to Lua 5.2.

Changes:

* Changed `locale.localize()` to global [`_L`][] table and removed `locale`
  module.
* Renamed `_m` to [`_M`][].
* Do not clear registered images when autocompleting with Adeptsense.
* Renamed editing module's `current_word()` to [`select_word()`][].
* Updated [manual][].

[Textadept 5.0 beta -- Win32]: download/textadept_5.0_beta.win32.zip
[Textadept 5.0 beta -- Mac OSX Intel 10.5+]: download/textadept_5.0_beta.osx.zip
[Textadept 5.0 beta -- Linux]: download/textadept_5.0_beta.tgz
[Textadept 5.0 beta -- Linux x86_64]: download/textadept_5.0_beta.x86_64.tgz
[Textadept 5.0 beta -- Source]: download/textadept_5.0_beta.src.zip
[Textadept 5.0 beta -- Modules]: download/textadept_5.0_beta.modules.zip
[`reset()`]: api.html#reset
[`_L`]: api.html#_L
[`_M`]: api.html#_M
[manual]: manual.html
[`select_word()`]: api.html#textadept.editing.select_word

## 5.0 alpha (21 Dec 2011)

Download:

* [Textadept 5.0 alpha -- Win32][]
* [Textadept 5.0 alpha -- Mac OSX Intel 10.5+][]
* [Textadept 5.0 alpha -- Linux][]
* [Textadept 5.0 alpha -- Linux x86_64][]
* [Textadept 5.0 alpha -- Source][]
* [Textadept 5.0 alpha -- Modules][]

Bugfixes:

* None.

Changes:

* Updated to [Lua 5.2][].
* Updated sections in the [manual][] to reflect Lua 5.2 changes.
* Textadept can be compiled with [LuaJIT][].

[Textadept 5.0 alpha -- Win32]: download/textadept_5.0_alpha.win32.zip
[Textadept 5.0 alpha -- Mac OSX Intel 10.5+]: download/textadept_5.0_alpha.osx.zip
[Textadept 5.0 alpha -- Linux]: download/textadept_5.0_alpha.tgz
[Textadept 5.0 alpha -- Linux x86_64]: download/textadept_5.0_alpha.x86_64.tgz
[Textadept 5.0 alpha -- Source]: download/textadept_5.0_alpha.src.zip
[Textadept 5.0 alpha -- Modules]: download/textadept_5.0_alpha.modules.zip
[Lua 5.2]: http://www.lua.org/manual/5.2/
[manual]: manual.html
[LuaJIT]: http://luajit.org

## 4.3 (01 Dec 2011)

Download:

* [Textadept 4.3 -- Win32][]
* [Textadept 4.3 -- Mac OSX Intel 10.5+][]
* [Textadept 4.3 -- Linux][]
* [Textadept 4.3 -- Linux x86_64][]
* [Textadept 4.3 -- Source][]
* [Textadept 4.3 -- Modules][]

Bugfixes:

* Fixed bug with opening files in the current directory from the command line.
* Fixed erroneous charset conversion.

Changes:

* Added on-the-fly [theme switching][].
* All new `light` and `dark` themes.
* Removed `_m.textadept.editing.select_style()`.
* Simplify theming via [gtkrc][] by naming `GtkWindow` only.
* Updated to [Scintilla][] 3.0.1.

[Textadept 4.3 -- Win32]: download/textadept_4.3.win32.zip
[Textadept 4.3 -- Mac OSX Intel 10.5+]: download/textadept_4.3.osx.zip
[Textadept 4.3 -- Linux]: download/textadept_4.3.tgz
[Textadept 4.3 -- Linux x86_64]: download/textadept_4.3.x86_64.tgz
[Textadept 4.3 -- Source]: download/textadept_4.3.src.zip
[Textadept 4.3 -- Modules]: download/textadept_4.3.modules.zip
[theme switching]: api.html#ui.set_theme
[gtkrc]: manual.html#GUI.Theme
[Scintilla]: http://scintilla.org

## 4.2 (01 Nov 2011)

Download:

* [Textadept 4.2 -- Win32][]
* [Textadept 4.2 -- Mac OSX Intel 10.5+][]
* [Textadept 4.2 -- Linux][]
* [Textadept 4.2 -- Linux x86_64][]
* [Textadept 4.2 -- Source][]
* [Textadept 4.2 -- Modules][]

Bugfixes:

* Fixed bug with `%n` in Replace introduced in 4.1.
* Fixed Adeptsense autocomplete for single item.

Changes:

* Updated to [Scintilla][] 3.0.0.

[Textadept 4.2 -- Win32]: download/textadept_4.2.win32.zip
[Textadept 4.2 -- Mac OSX Intel 10.5+]: download/textadept_4.2.osx.zip
[Textadept 4.2 -- Linux]: download/textadept_4.2.tgz
[Textadept 4.2 -- Linux x86_64]: download/textadept_4.2.x86_64.tgz
[Textadept 4.2 -- Source]: download/textadept_4.2.src.zip
[Textadept 4.2 -- Modules]: download/textadept_4.2.modules.zip
[Scintilla]: http://scintilla.org

## 4.1 (01 Oct 2011)

Download:

* [Textadept 4.1 -- Win32][]
* [Textadept 4.1 -- Mac OSX Intel 10.5+][]
* [Textadept 4.1 -- Linux][]
* [Textadept 4.1 -- Linux x86_64][]
* [Textadept 4.1 -- Source][]
* [Textadept 4.1 -- Modules][]

Bugfixes:

* Only fold when clicking on fold margin, not any sensitive one.
* Fixed bug with `CALL_TIP_CLICK` event disconnect in Adeptsense.
* Fixed bug with autocomplete and capitalization.

Changes:

* Handle mouse [dwell events][] `DWELL_START` and `DWELL_END`.
* Rearranged `Tools` menu slightly.
* Slight API changes:
  + [`_BUFFERS`][] and [`_VIEWS`][] structure changed.
  + Removed `buffer.doc_pointer` and `view.doc_pointer`.
  + Added [`view.buffer`][] field.
  + Renamed `gui.check_focused_buffer()` to `buffer:check_global()`.
  + [`view:goto_buffer()`][] and [`gui.goto_view()`] arguments make sense now.
    (May require changes to custom key commands.)
* Directory is remembered in file chooser dialog after open or save as.
* Added language-specific [context menu][] support.
* Use [LuaCoco][] patch for Lua 5.1.4.
* Use lexer at the caret for key commands and snippets.
* Updated to [Scintilla][] 2.29.

[Textadept 4.1 -- Win32]: download/textadept_4.1.win32.zip
[Textadept 4.1 -- Mac OSX Intel 10.5+]: download/textadept_4.1.osx.zip
[Textadept 4.1 -- Linux]: download/textadept_4.1.tgz
[Textadept 4.1 -- Linux x86_64]: download/textadept_4.1.x86_64.tgz
[Textadept 4.1 -- Source]: download/textadept_4.1.src.zip
[Textadept 4.1 -- Modules]: download/textadept_4.1.modules.zip
[dwell events]: api.html#events
[`_BUFFERS`]: api.html#_BUFFERS
[`_VIEWS`]: api.html#_VIEWS
[`view.buffer`]: api.html#view.buffer
[`view:goto_buffer()`]: api.html#view.goto_buffer
[`gui.goto_view()`]: api.html#ui.goto_view
[context menu]: api.html#_M.Context.Menu
[LuaCoco]: http://coco.luajit.org/
[Scintilla]: http://scintilla.org

## 4.0 (01 Sep 2011)

Please see the [3 to 4 migration guide][] for upgrading from Textadept 3 to
Textadept 4.

Download:

* [Textadept 4.0 -- Win32][]
* [Textadept 4.0 -- Mac OSX Intel 10.5+][]
* [Textadept 4.0 -- Linux][]
* [Textadept 4.0 -- Linux x86_64][]
* [Textadept 4.0 -- Source][]
* [Textadept 4.0 -- Modules][]

Bugfixes:

* Makefile should only link to `libdl.so` on Linux/BSD.
* Fixed memory access bug in [`gui.dialog()`][].
* Autocompletion list sort order respects [`buffer.auto_c_ignore_case`][] now.
* Fixed split view focus bug with the same buffer in two views.
* Set new buffer EOL mode properly on Mac OSX.

Changes:

* Added Russian translation.
* Changed some key commands from 4.0 beta 2.
* Do not hide the statusbar when the command entry has focus.

[3 to 4 migration guide]: manual.html#Textadept.3.to.4
[Textadept 4.0 -- Win32]: download/textadept_4.0.win32.zip
[Textadept 4.0 -- Mac OSX Intel 10.5+]: download/textadept_4.0.osx.zip
[Textadept 4.0 -- Linux]: download/textadept_4.0.tgz
[Textadept 4.0 -- Linux x86_64]: download/textadept_4.0.x86_64.tgz
[Textadept 4.0 -- Source]: download/textadept_4.0.src.zip
[Textadept 4.0 -- Modules]: download/textadept_4.0.modules.zip
[`gui.dialog()`]: api.html#ui.dialog
[`buffer.auto_c_ignore_case`]: api.html#buffer.auto_c_ignore_case

## 4.0 beta 2 (11 Aug 2011)

Download:

* [Textadept 4.0 beta 2 -- Win32][]
* [Textadept 4.0 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 4.0 beta 2 -- Linux][]
* [Textadept 4.0 beta 2 -- Linux x86_64][]
* [Textadept 4.0 beta 2 -- Source][]
* [Textadept 4.0 beta 2 -- Modules][]

Bugfixes:

* Fixed transpose characters bug at end of buffer.
* Do not autosave over explicitly loaded session.
* Fixed startup crash on Mac OSX.
* Fixed resize crash on Mac OSX Lion.

Changes:

* Added Scala lexer.
* Add [recent file list][] to session files.
* Autocomplete supports multiple selections.
* Swapped OSX `c` and `m` key command definition modifiers.
* Changed some key bindings from 4.0 beta.

[Textadept 4.0 beta 2 -- Win32]: download/textadept_4.0_beta_2.win32.zip
[Textadept 4.0 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_4.0_beta_2.osx.zip
[Textadept 4.0 beta 2 -- Linux]: download/textadept_4.0_beta_2.tgz
[Textadept 4.0 beta 2 -- Linux x86_64]: download/textadept_4.0_beta_2.x86_64.tgz
[Textadept 4.0 beta 2 -- Source]: download/textadept_4.0_beta_2.src.zip
[Textadept 4.0 beta 2 -- Modules]: download/textadept_4.0_beta_2.modules.zip
[recent file list]: api.html#io.recent_files

## 4.0 beta (01 Aug 2011)

Download:

* [Textadept 4.0 beta -- Win32][]
* [Textadept 4.0 beta -- Mac OSX Intel 10.5+][]
* [Textadept 4.0 beta -- Linux][]
* [Textadept 4.0 beta -- Linux x86_64][]
* [Textadept 4.0 beta -- Source][]
* [Textadept 4.0 beta -- Modules][]

Bugfixes:

* None.

Changes:

* Mac OSX uses GTK 2.24.
* Added [`io.open_recent_file()`][].
* Changes to localization file again.
* [`buffer`][] functions may omit the first `buffer` argument (e.g.
  `buffer.line_down()` is allowed).
* Complete overhaul of menus and added accelerators to [menu][] items.
* Renamed `_m.textadept.editing.SAVE_STRIPS_WS` to
  [`_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`][].
* Renamed `_m.textadept.editing.select_scope()` to
  `_m.textadept.editing.select_style()`.
* *Completely new set of key commands.*
* Updated to [Scintilla][] 2.28.

[Textadept 4.0 beta -- Win32]: download/textadept_4.0_beta.win32.zip
[Textadept 4.0 beta -- Mac OSX Intel 10.5+]: download/textadept_4.0_beta.osx.zip
[Textadept 4.0 beta -- Linux]: download/textadept_4.0_beta.tgz
[Textadept 4.0 beta -- Linux x86_64]: download/textadept_4.0_beta.x86_64.tgz
[Textadept 4.0 beta -- Source]: download/textadept_4.0_beta.src.zip
[Textadept 4.0 beta -- Modules]: download/textadept_4.0_beta.modules.zip
[`io.open_recent_file()`]: api.html#io.open_recent_file
[`buffer`]: api.html#buffer
[`_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`]: api.html#textadept.editing.STRIP_WHITESPACE_ON_SAVE
[menu]: api.html#ui.menu
[Scintilla]: http://scintilla.org

## 3.9 (01 Jul 2011)

Download:

* [Textadept 3.9 -- Win32][]
* [Textadept 3.9 -- Mac OSX Intel 10.5+][]
* [Textadept 3.9 -- Linux][]
* [Textadept 3.9 -- Linux x86_64][]
* [Textadept 3.9 -- Source][]
* [Textadept 3.9 -- Modules][]

Bugfixes:

* Fixed bug for when [`gui.dialog`][] steals focus.

Changes:

* Added support for [GTK][] 3.0.
* Use ID generator [functions][] for marker, indicator, and user list IDs.
* Updated to [Scintilla][] 2.27.
* Use string constants for event names.
* Compile and run commands [emit events][].
* Enhanced Luadoc and Lua Adeptsense.
* Added `fold.line.comments` property for folding multiple single-line comments.
* Use [GTK][] 2.22 on Windows.
* Can localize the labels and buttons in the GUI [find][] frame.
* Added ConTeXt lexer.

[Textadept 3.9 -- Win32]: download/textadept_3.9.win32.zip
[Textadept 3.9 -- Mac OSX Intel 10.5+]: download/textadept_3.9.osx.zip
[Textadept 3.9 -- Linux]: download/textadept_3.9.tgz
[Textadept 3.9 -- Linux x86_64]: download/textadept_3.9.x86_64.tgz
[Textadept 3.9 -- Source]: download/textadept_3.9.src.zip
[Textadept 3.9 -- Modules]: download/textadept_3.9.modules.zip
[GTK]: http://gtk.org
[`gui.dialog`]: api.html#ui.dialog
[functions]: api.html#_SCINTILLA
[Scintilla]: http://scintilla.org
[emit events]: api.html#events.COMPILE_OUTPUT
[find]: api.html#ui.find

## 3.8 (11 Jun 2011)

Download:

* [Textadept 3.8 -- Win32][]
* [Textadept 3.8 -- Mac OSX Intel 10.5+][]
* [Textadept 3.8 -- Linux][]
* [Textadept 3.8 -- Linux x86_64][]
* [Textadept 3.8 -- Source][]
* [Textadept 3.8 -- Modules][]

Bugfixes:

* Removed non-existant key chain.
* Fixed bug in snippets.

Changes:

* Updated Adeptsense and documentation.
* `events.handlers` is accessible.
* Added menu mnemonics for indentation size.
* Added support for indicator and hotspot [events][].
* Updated [documentation][] for installing [official modules][].
* Updated to [Scintilla][] 2.26.
* Writing custom folding for lexers is much [easier][] now.
* Added native folding for more than 60% of existing lexers. The rest still use
  folding by indentation by default.

[Textadept 3.8 -- Win32]: download/textadept_3.8.win32.zip
[Textadept 3.8 -- Mac OSX Intel 10.5+]: download/textadept_3.8.osx.zip
[Textadept 3.8 -- Linux]: download/textadept_3.8.tgz
[Textadept 3.8 -- Linux x86_64]: download/textadept_3.8.x86_64.tgz
[Textadept 3.8 -- Source]: download/textadept_3.8.src.zip
[Textadept 3.8 -- Modules]: download/textadept_3.8.modules.zip
[events]: api.html#events
[documentation]: manual.html#Getting.Modules
[official modules]: http://foicica.com/hg
[Scintilla]: http://scintilla.org
[easier]: api.html#lexer.Code.Folding

## 3.7 (01 May 2011)

Download:

* [Textadept 3.7 -- Win32][]
* [Textadept 3.7 -- Mac OSX Intel 10.5+][]
* [Textadept 3.7 -- Linux][]
* [Textadept 3.7 -- Linux x86_64][]
* [Textadept 3.7 -- Source][]
* [Textadept 3.7 -- Modules][]

Bugfixes:

* Fixed bug in [`buffer:get_lexer()`][].

Changes:

* Changed Mac OSX Adeptsense complete key command from `~` to `Ctrl+Escape`.
* Added PHP module.

[Textadept 3.7 -- Win32]: download/textadept_3.7.win32.zip
[Textadept 3.7 -- Mac OSX Intel 10.5+]: download/textadept_3.7.osx.zip
[Textadept 3.7 -- Linux]: download/textadept_3.7.tgz
[Textadept 3.7 -- Linux x86_64]: download/textadept_3.7.x86_64.tgz
[Textadept 3.7 -- Source]: download/textadept_3.7.src.zip
[Textadept 3.7 -- Modules]: download/textadept_3.7.modules.zip
[`buffer:get_lexer()`]: api.html#buffer.get_lexer

## 3.7 beta 3 (01 Apr 2011)

Download:

* [Textadept 3.7 beta 3 -- Win32][]
* [Textadept 3.7 beta 3 -- Mac OSX Intel 10.5+][]
* [Textadept 3.7 beta 3 -- Linux][]
* [Textadept 3.7 beta 3 -- Linux x86_64][]
* [Textadept 3.7 beta 3 -- Source][]
* [Textadept 3.7 beta 3 -- Modules][]

Bugfixes:

* Small Adeptsense bugfixes.
* Snapopen respects filesystem encoding.
* Standard input dialogs have "Cancel" button by default.

Changes:

* Adeptsense tweaks for better completion and apidoc support.
* Language modules load a user [`post_init.lua`][] script if it exists.
* Added Ruby on Rails lexer and module.
* Added RHTML module.
* Updated mime-types and prioritize by shebang, pattern, and then file
  extension.
* [`buffer:get_lexer(true)`] returns the lexer at the caret position.
* Adeptsense can be triggered in embedded lexers now.
* Added C standard library and Lua C API to C/C++ Adeptsense.
* Lua module fields are now in Lua Adeptsense.
* Updated to [Scintilla][] 2.25.
* Rewrote [`_m.textadept.snippets`][] with syntax changes.
* `Alt+I` (`Ctrl+I` on Mac OSX) is now "Select Snippet" instead of "Show Style".
  "Show Style" is now `Ctrl+Alt+Shift+I` (`Ctrl+Apple+Shift+I`).
* Adeptsense can exclude types matched by `sense.syntax.type_declarations`
  patterns.
* `Ctrl+T, V` (`Apple+T, V` on Mac OSX) keychain for toggling whitespace, wrap,
  etc. is now `Ctrl+Shift+B` (`Apple+Shift+B`).
* Key commands and menu definition syntax changed.
* Snapopen allows for multiple-selection.
* [`gui.print()`][] handles `nil` and non-string arguments properly.
* Officially supported modules have their own [repositories][] and are available
  as a separate download.

[Textadept 3.7 beta 3 -- Win32]: download/textadept_3.7_beta_3.win32.zip
[Textadept 3.7 beta 3 -- Mac OSX Intel 10.5+]: download/textadept_3.7_beta_3.osx.zip
[Textadept 3.7 beta 3 -- Linux]: download/textadept_3.7_beta_3.tgz
[Textadept 3.7 beta 3 -- Linux x86_64]: download/textadept_3.7_beta_3.x86_64.tgz
[Textadept 3.7 beta 3 -- Source]: download/textadept_3.7_beta_3.src.zip
[Textadept 3.7 beta 3 -- Modules]: download/textadept_3.7_beta_3.modules.zip
[`post_init.lua`]: manual.html#Language.Module.Preferences
[`buffer:get_lexer(true)`]: api.html#buffer.get_lexer
[Scintilla]: http://scintilla.org
[`_m.textadept.snippets`]: api.html#textadept.snippets
[`gui.print()`]: api.html#ui.print
[repositories]: http://foicica.com/hg

## 3.7 beta 2 (01 Mar 2011)

Download:

* [Textadept 3.7 beta 2 -- Win32][]
* [Textadept 3.7 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 3.7 beta 2 -- Linux][]
* [Textadept 3.7 beta 2 -- Linux x86_64][]
* [Textadept 3.7 beta 2 -- Source][]

Bugfixes:

* Fixed bug with Win32 paths in Adeptsense `goto_ctag()`.
* Adeptsense could not recognize some symbols.
* Handle `\n` sequences correctly in Adeptsense apidoc.
* Fixed bug with Adeptsense C/C++ type declarations.
* Adeptsense can now recognize more than 1 level of inheritence.
* Keychain is cleared on key command error.
* Fixed infinite loop bug in `_m.textadept.editing.select_scope()`.

Changes:

* Updated to [Scintilla][] 2.24.
* Updated mime-types.
* Line margin width is now `4`.
* Adeptsense completion list images are accessible via scripts.
* Added class context completion to Adeptsense.
* Added class type-inference through variable assignment to Adeptsense.
* Added Adeptsense tutorial.
* Added `_m.textadept.adeptsense.always_show_globals` setting for showing
  globals in completion lists.
* `Ctrl+H` (highlight word) is now `Ctrl+Shift+H`.
* `Ctrl+H` now shows Adeptsense documentation.
* Added Adeptsense `complete()` and `show_documentation()` functions to the
  menu.
* Language modules condensed into single `init.lua` file.
* Added `sense.syntax.word_chars` to Adeptsense.
* Included libpng12 build for 64-bit Debian-based Linux distros (Ubuntu).
* Added [CSS][], [HTML][], Java, and [Ruby][] modules with Adeptsenses.

[Textadept 3.7 beta 2 -- Win32]: download/textadept_3.7_beta_2.win32.zip
[Textadept 3.7 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_3.7_beta_2.osx.zip
[Textadept 3.7 beta 2 -- Linux]: download/textadept_3.7_beta_2.tgz
[Textadept 3.7 beta 2 -- Linux x86_64]: download/textadept_3.7_beta_2.x86_64.tgz
[Textadept 3.7 beta 2 -- Source]: download/textadept_3.7_beta_2.src.zip
[Scintilla]: http://scintilla.org
[CSS]: api.html#_M.css
[HTML]: api.html#_M.html
[Ruby]: api.html#_M.ruby

## 3.7 beta (01 Feb 2011)

Download:

* [Textadept 3.7 beta -- Win32][]
* [Textadept 3.7 beta -- Mac OSX Intel 10.5+][]
* [Textadept 3.7 beta -- Linux][]
* [Textadept 3.7 beta -- Linux x86_64][]
* [Textadept 3.7 beta -- Source][]

Bugfixes:

* `update_ui` is called properly for `buffer_new` and `view_new` events.
* Use proper pointer type for Scintilla calls.
* Fixed bug with loading lexers from `_USERHOME` on Win32.

Changes:

* More informative error message for unfocused buffer.
* Added Adeptsense, a smarter form of autocompletion for programming languages.
* Emit a `language_module_loaded` as appropriate.
* Added indentation settings to "Buffer" menu (finally).
* Added `gui.filteredlist()` shortcut for `gui.dialog('filteredlist', ...)`.
* Can navigate between bookmarks with a filteredlist.
* Language-specific [`char_matches`][] and [`braces`][] can be defined.
* `command_entry_keypress` event accepts modifier keys.

[Textadept 3.7 beta -- Win32]: download/textadept_3.7_beta.win32.zip
[Textadept 3.7 beta -- Mac OSX Intel 10.5+]: download/textadept_3.7_beta.osx.zip
[Textadept 3.7 beta -- Linux]: download/textadept_3.7_beta.tgz
[Textadept 3.7 beta -- Linux x86_64]: download/textadept_3.7_beta.x86_64.tgz
[Textadept 3.7 beta -- Source]: download/textadept_3.7_beta.src.zip
[`char_matches`]: api.html#textadept.editing.char_matches
[`braces`]: api.html#textadept.editing.braces

## 3.6 (01 Jan 2011)

Download:

* [Textadept 3.6 -- Win32][]
* [Textadept 3.6 -- Mac OSX Intel 10.5+][]
* [Textadept 3.6 -- Linux][]
* [Textadept 3.6 -- Linux x86_64][]
* [Textadept 3.6 -- Source][]

Bugfixes:

* Fixed infinite recursion errors caused in events.
* Fix statusbar update bug with key chains.
* Do not emit `buffer_new` event when splitting the view.

Changes:

* [`buffer.rectangular_selection_modifier`][] on Linux is the Super/Windows key.
* Improved HTML lexer.
* Added Markdown, BibTeX, CMake, CUDA, Desktop Entry, F#, GLSL, and Nemerle
  lexers.
* Added [`_m.textadept.filter_through`][] module for [shell commands][].
* Moved GUI events from `core/events.lua` to `core/gui.lua`.
* Separated key command manager from key command definitions.

[Textadept 3.6 -- Win32]: download/textadept_3.6.win32.zip
[Textadept 3.6 -- Mac OSX Intel 10.5+]: download/textadept_3.6.osx.zip
[Textadept 3.6 -- Linux]: download/textadept_3.6.tgz
[Textadept 3.6 -- Linux x86_64]: download/textadept_3.6.x86_64.tgz
[Textadept 3.6 -- Source]: download/textadept_3.6.src.zip
[`buffer.rectangular_selection_modifier`]: api.html#buffer.rectangular_selection_modifier
[`_m.textadept.filter_through`]: api.html#textadept.editing.filter_through
[shell commands]: manual.html#Shell.Commands.and.Filtering.Text

## 3.5 (01 Dec 2010)

Download:

* [Textadept 3.5 -- Win32][]
* [Textadept 3.5 -- Mac OSX Intel 10.5+][]
* [Textadept 3.5 -- Linux][]
* [Textadept 3.5 -- Linux x86_64][]
* [Textadept 3.5 -- Source][]

Bugfixes:

* Fixed bug introduced when exposing Find in Files API.

Changes:

* Lua files are syntax-checked for errors on save.
* [Menus][] are easier to create.
* Changed [`_m.textadept.editing.enclose()`][] behavior.
* Win32 and Mac OSX packages are all-in-one bundles; GTK is no longer an
  external dependency.
* New [manual][].
* Added [`file_after_save`][] event.

[Textadept 3.5 -- Win32]: download/textadept_3.5.win32.zip
[Textadept 3.5 -- Mac OSX Intel 10.5+]: download/textadept_3.5.osx.zip
[Textadept 3.5 -- Linux]: download/textadept_3.5.tgz
[Textadept 3.5 -- Linux x86_64]: download/textadept_3.5.x86_64.tgz
[Textadept 3.5 -- Source]: download/textadept_3.5.src.zip
[Menus]: api.html#textadept.menu
[`_m.textadept.editing.enclose()`]: api.html#textadept.editing.enclose
[manual]: manual.html
[`file_after_save`]: api.html#events.FILE_AFTER_SAVE

## 3.4 (01 Nov 2010)

Download:

* [Textadept 3.4 -- Win32][]
* [Textadept 3.4 -- Mac OSX Intel 10.5+][]
* [Textadept 3.4 -- Linux][]
* [Textadept 3.4 -- Linux x86_64][]
* [Textadept 3.4 -- Source][]

Bugfixes:

* Fixed menu item conflicts.
* Pressing `Cancel` in the [Switch Buffers][] dialog does not jump to the
  selected buffer anymore.
* Autocomplete lists sort properly for machines with a different locale.
* Statusbar is not cleared when set from a key command.
* Unreadable files are handled appropriately.

Changes:

* Multi-language lexers (HTML, PHP, RHTML, etc.) are processed as fast as single
  language ones, resulting in a huge speed improvement.
* An `update_ui` event is triggered after a Lua command is entered.
* [`gui.dialog()`][] can take tables of strings as arguments now.
* [`_m.textadept.snapopen.open()`][] takes a recursion depth as a parameter and
  falls back on a `DEFAULT_DEPTH` if necessary.
* Removed `_m.textadept.editing.smart_cutcopy()` and
  `_m.textadept.editing.squeeze()` functions.
* Added `_m.textadept.editing.SAVE_STRIPS_WS` option to disable strip whitespace
  on save.
* Changed locale implementation. Locale files are much easier to create now.
* [`gui.statusbar_text`][] is now readable instead of being write-only.
* Can [highlight][] all occurances of a word.
* Added jsp lexer.
* More consistant handling of `\` directory separator for Win32.
* Consolidated `textadept.h` and `lua_interface.c` into single `textadept.c`
  file.
* Added [`_G.timeout()`][] function for calling functions and/or events after a
  period of time.
* Find in files is accessible through [find API][].
* Updated to [Scintilla][] 2.22.
* Renamed `_G.MAC` to [`_G.OSX`][].

[Textadept 3.4 -- Win32]: download/textadept_3.4.win32.zip
[Textadept 3.4 -- Mac OSX Intel 10.5+]: download/textadept_3.4.osx.zip
[Textadept 3.4 -- Linux]: download/textadept_3.4.tgz
[Textadept 3.4 -- Linux x86_64]: download/textadept_3.4.x86_64.tgz
[Textadept 3.4 -- Source]: download/textadept_3.4.src.zip
[Switch Buffers]: manual.html#Buffers
[`gui.dialog()`]: api.html#ui.dialog
[`_m.textadept.snapopen.open()`]: api.html#io.snapopen
[`gui.statusbar_text`]: api.html#ui.statusbar_text
[highlight]: manual.html#Word.Highlight
[`_G.timeout()`]: api.html#timeout
[find API]: api.html#ui.find.find_in_files
[Scintilla]: http://scintilla.org
[`_G.OSX`]: api.html#OSX

## 3.3 (01 Oct 2010)

Download:

* [Textadept 3.3 -- Win32][]
* [Textadept 3.3 -- Mac OSX Intel 10.5+][]
* [Textadept 3.3 -- Linux][]
* [Textadept 3.3 -- Linux x86_64][]
* [Textadept 3.3 -- Source][]

Bugfixes:

* Fixed buggy snippet menu.

Changes:

* Added [`_m.textadept.snapopen`][] module with menu options for rapidly opening
  files.

[Textadept 3.3 -- Win32]: download/textadept_3.3.win32.zip
[Textadept 3.3 -- Mac OSX Intel 10.5+]: download/textadept_3.3.osx.zip
[Textadept 3.3 -- Linux]: download/textadept_3.3.tgz
[Textadept 3.3 -- Linux x86_64]: download/textadept_3.3.x86_64.tgz
[Textadept 3.3 -- Source]: download/textadept_3.3.src.zip
[`_m.textadept.snapopen`]: api.html#io.snapopen

## 3.2 (01 Sep 2010)

Download:

* [Textadept 3.2 -- Win32][]
* [Textadept 3.2 -- Mac OSX Intel 10.5+][]
* [Textadept 3.2 -- Linux][]
* [Textadept 3.2 -- Linux x86_64][]
* [Textadept 3.2 -- Source][]

Bugfixes:

* Fixed "Replace All" infinite loop bug.

Changes:

* Updated to the new [Scintillua][] that does not required patched Scintilla.
* Updated to [Scintilla][] 2.21.

[Textadept 3.2 -- Win32]: download/textadept_3.2.win32.zip
[Textadept 3.2 -- Mac OSX Intel 10.5+]: download/textadept_3.2.osx.zip
[Textadept 3.2 -- Linux]: download/textadept_3.2.tgz
[Textadept 3.2 -- Linux x86_64]: download/textadept_3.2.x86_64.tgz
[Textadept 3.2 -- Source]: download/textadept_3.2.src.zip
[Scintillua]: http://foicica.com/scintillua
[Scintilla]: http://scintilla.org

## 3.1 (21 Aug 2010)

Download:

* [Textadept 3.1 -- Win32][]
* [Textadept 3.1 -- Mac OSX Intel 10.5+][]
* [Textadept 3.1 -- Linux][]
* [Textadept 3.1 -- Linux x86_64][]
* [Textadept 3.1 -- Source][]

Bugfixes:

* Fixed memory leak in Mac OSX.

Changes:

* Refactored key commands to support propagation.
* Updated to [Scintilla][] 2.20.
* Added Lua autocompletion.

[Textadept 3.1 -- Win32]: download/textadept_3.1.win32.zip
[Textadept 3.1 -- Mac OSX Intel 10.5+]: download/textadept_3.1.osx.zip
[Textadept 3.1 -- Linux]: download/textadept_3.1.tgz
[Textadept 3.1 -- Linux x86_64]: download/textadept_3.1.x86_64.tgz
[Textadept 3.1 -- Source]: download/textadept_3.1.src.zip
[Scintilla]: http://scintilla.org

## 3.0 (01 Jul 2010)

Please see the [2 to 3 migration guide][] for upgrading from Textadept 2 to
Textadept 3.

Download:

* [Textadept 3.0 -- Win32][]
* [Textadept 3.0 -- Mac OSX Intel 10.5+][]
* [Textadept 3.0 -- Linux][]
* [Textadept 3.0 -- Linux x86_64][]
* [Textadept 3.0 -- Source][]

Bugfixes:

* None

Changes:

* More accurate CSS and Diff lexers.

[2 to 3 migration guide]: manual.html#Textadept.2.to.3
[Textadept 3.0 -- Win32]: download/textadept_3.0.win32.zip
[Textadept 3.0 -- Mac OSX Intel 10.5+]: download/textadept_3.0.osx.zip
[Textadept 3.0 -- Linux]: download/textadept_3.0.tgz
[Textadept 3.0 -- Linux x86_64]: download/textadept_3.0.x86_64.tgz
[Textadept 3.0 -- Source]: download/textadept_3.0.src.zip

## 3.0 beta (21 Jun 2010)

Download:

* [Textadept 3.0 beta -- Win32][]
* [Textadept 3.0 beta -- Mac OSX Intel 10.5+][]
* [Textadept 3.0 beta -- Linux][]
* [Textadept 3.0 beta -- Linux x86_64][]
* [Textadept 3.0 beta -- Source][]

Bugfixes:

* Fixed Mac OSX paste issue.
* Fixed [`buffer:text_range()`][] argcheck problem.

Changes:

* Remove initial "Untitled" buffer when necessary.
* Moved core extension modules into [`textadept`][] module.
* New [API][].
* `~/.textadept/init.lua` is created for you if one does not exist.
* No more autoload of `~/.textadept/key_commands.lua` and
  `~/.textadept/snippets.lua`
* Updated to [Scintilla][] 2.12.
* [Abbreviated][] Lua commands in the command entry.
* Dynamic command line [arguments][].
* Added statusbar notification on [`reset()`][].
* Added Gtkrc, Prolog, and Go lexers.

[Textadept 3.0 beta -- Win32]: download/textadept_3.0_beta.win32.zip
[Textadept 3.0 beta -- Mac OSX Intel 10.5+]: download/textadept_3.0_beta.osx.zip
[Textadept 3.0 beta -- Linux]: download/textadept_3.0_beta.tgz
[Textadept 3.0 beta -- Linux x86_64]: download/textadept_3.0_beta.x86_64.tgz
[Textadept 3.0 beta -- Source]: download/textadept_3.0_beta.src.zip
[`buffer:text_range()`]: api.html#buffer.text_range
[`textadept`]: api.html#textadept
[API]: api.html
[Scintilla]: http://scintilla.org
[Abbreviated]: manual.html#Lua.Command.Entry
[arguments]: api.html#args
[`reset()`]: api.html#reset

## 2.2 (11 May 2010)

Download:

* [Textadept 2.2 -- Win32][]
* [Textadept 2.2 -- Mac OSX Intel 10.5+][]
* [Textadept 2.2 -- Linux][]
* [Textadept 2.2 -- Linux x86_64][]
* [Textadept 2.2 -- Source][]

Bugfixes:

* Save buffer before compiling or running.
* Fixed error in the manual for `~/.textadept/init.lua` example.
* Ignore `file://` prefix for filenames.

Changes:

* [`_USERHOME`][] comes before [`_HOME`][] in `package.path` so `require`
  searches `~/.textadept/` first.

[Textadept 2.2 -- Win32]: download/textadept_2.2.win32.zip
[Textadept 2.2 -- Mac OSX Intel 10.5+]: download/textadept_2.2.osx.zip
[Textadept 2.2 -- Linux]: download/textadept_2.2.tgz
[Textadept 2.2 -- Linux x86_64]: download/textadept_2.2.x86_64.tgz
[Textadept 2.2 -- Source]: download/textadept_2.2.src.zip
[`_USERHOME`]: api.html#_USERHOME
[`_HOME`]: api.html#_HOME

## 2.2 beta 2 (01 May 2010)

Download:

* [Textadept 2.2 beta 2 -- Win32][]
* [Textadept 2.2 beta 2 -- Mac OSX Intel 10.5+][]
* [Textadept 2.2 beta 2 -- Linux][]
* [Textadept 2.2 beta 2 -- Linux x86_64][]
* [Textadept 2.2 beta 2 -- Source][]

Bugfixes:

* Fixed crash with [`buffer:text_range()`][].
* Fixed snippets bug with `%n` sequences.
* Respect tab settings for snippets.
* Fixed help hanging bug in Win32.
* Fixed Lua module commands bug.

Changes:

* Added BSD support.
* Removed kill-ring from editing module.
* [Compile and Run][] commands are in language modules.
* [Block comment][] strings are in language modules now.
* Remove "Untitled" buffer when necessary.
* Moved "Search" menu into "Tools" menu to prevent `Alt+S` key conflict.
* Rewrote lexers implementation.
* Added Inform, Lilypond, and NSIS lexers.
* `_m.textadept.editing.enclosure` is now an accessible table.

[Textadept 2.2 beta 2 -- Win32]: download/textadept_2.2_beta2.win32.zip
[Textadept 2.2 beta 2 -- Mac OSX Intel 10.5+]: download/textadept_2.2_beta2.osx.zip
[Textadept 2.2 beta 2 -- Linux]: download/textadept_2.2_beta2.tgz
[Textadept 2.2 beta 2 -- Linux x86_64]: download/textadept_2.2_beta2.x86_64.tgz
[Textadept 2.2 beta 2 -- Source]: download/textadept_2.2_beta2.src.zip
[`buffer:text_range()`]: api.html#buffer.text_range
[Compile and run]: api.html#_M.Compile.and.Run
[Block comment]: api.html#textadept.editing.comment_string

## 2.2 beta (01 Apr 2010)

Download:

* [Textadept 2.2 beta -- Win32][]
* [Textadept 2.2 beta -- Mac OSX Intel 10.5+][]
* [Textadept 2.2 beta -- Linux][]
* [Textadept 2.2 beta -- Linux x86_64][]
* [Textadept 2.2 beta -- Source][]

Bugfixes:

* Fixed transform bug in snippets.
* Fixed bug with Io lexer mime-type.
* Fixed embedded css/javascript bug in HTML lexer.

Changes:

* Removed `_m.textadept.mlines` module since Scintilla's multiple selections
  supercedes it.
* Removed side pane.
* New [`gui.dialog('filteredlist', ...)][] from [gtdialog][].
* Can select buffer from filteredlist dialog (replacing side pane buffer list).
* Can select lexer from filteredlist dialog.
* Can have user `key_commands.lua`, `snippets.lua`, `mime_types.conf`,
  `locale.conf` that are loaded by their respective modules.
* Added Matlab/Octave lexer.
* Backspace deletes auto-inserted character pairs.
* Added notification for session files not found.
* Snippets use multiple carets.
* Removed api file support.

[Textadept 2.2 beta -- Win32]: download/textadept_2.2_beta.win32.zip
[Textadept 2.2 beta -- Mac OSX Intel 10.5+]: download/textadept_2.2_beta.osx.zip
[Textadept 2.2 beta -- Linux]: download/textadept_2.2_beta.tgz
[Textadept 2.2 beta -- Linux x86_64]: download/textadept_2.2_beta.x86_64.tgz
[Textadept 2.2 beta -- Source]: download/textadept_2.2_beta.src.zip
[gtdialog]: http://foicica.com/gtdialog
[`gui.dialog('filteredlist', ...)]: api.html#ui.dialog

## 2.1 (01 Mar 2010)

Download:

* [Textadept 2.1 -- Win32][]
* [Textadept 2.1 -- Mac OSX Intel 10.5+][]
* [Textadept 2.1 -- Linux][]
* [Textadept 2.1 -- Linux x86_64][]
* [Textadept 2.1 -- Source][]

Bugfixes:

* Do not close files opened from command line when loading PM session.
* Fixed bug for running a file with no path.
* Fixed error message for session file not being found.
* Fixed key command for word autocomplete on Win32.
* Changed conflicting menu shortcut for Lexers menu.
* Fixed typos in templates generated by modules PM browser.

Changes:

* Added Dot and JSON lexers.
* Search [`_USERHOME`][] in addition to [`_HOME`][] for themes.
* Added command line switch for not loading/saving session.
* Modified key commands to be more key-layout agnostic.
* Added `reset_before` and `reset_after` events while `textadept.reset()` is
  being run.
* Reload current lexer module after `textadept.reset()`.
* Added `~/.textadept/modules/` to `package.path`.
* Updated to [Scintilla][] 2.03.
* Modified quit and close dialogs to be more readable.

[Textadept 2.1 -- Win32]: download/textadept_2.1.win32.zip
[Textadept 2.1 -- Mac OSX Intel 10.5+]: download/textadept_2.1.osx.zip
[Textadept 2.1 -- Linux]: download/textadept_2.1.tgz
[Textadept 2.1 -- Linux x86_64]: download/textadept_2.1.x86_64.tgz
[Textadept 2.1 -- Source]: download/textadept_2.1.src.zip
[`_USERHOME`]: api.html#_USERHOME
[`_HOME`]: api.html#_HOME
[Scintilla]: http://scintilla.org

## 2.0 (01 Oct 2009)

Download:

* [Textadept 2.0 -- Win32][]
* [Textadept 2.0 -- Mac OSX Intel 10.5+][]
* [Textadept 2.0 -- Linux][]
* [Textadept 2.0 -- Linux x86_64][]
* [Textadept 2.0 -- Source][]

Bugfixes:

* Fixed bug with reloading PM width from session file.
* Only show a non-nil PM context menu.
* Fixed bug in `modules/textadept/lsnippets.lua`.
* Fixed bug in `core/ext/mime_types.lua` caused during `textadept.reset()`.
* Close all buffers before loading a session.
* Identify `shellscript` files correctly.
* D lexer no longer has key-command conflicts.

Changes:

* Refactored `modules/textadept/lsnippets.lua`.
* Updated key commands.
* Allow PM modules in the `~/.textadept` user directory.
* Added [`style_whitespace`][] to [lexers][] for custom styles.
* Added standard `F3` key command for "Find Next" for Windows/Linux.

[Textadept 2.0 -- Win32]: download/textadept_2.0.win32.zip
[Textadept 2.0 -- Mac OSX Intel 10.5+]: download/textadept_2.0.dmg
[Textadept 2.0 -- Linux]: download/textadept_2.0.tgz
[Textadept 2.0 -- Linux x86_64]: download/textadept_2.0.x86_64.tgz
[Textadept 2.0 -- Source]: download/textadept_2.0.src.zip
[`style_whitespace`]: api.html#lexer.STYLE_WHITESPACE
[lexers]: api.html#lexer

## 2.0 beta (31 Jul 2009)

Download:

* [Textadept 2.0 beta -- Win32][]
* [Textadept 2.0 beta -- Linux][]
* [Textadept 2.0 beta -- Linux x86_64][]
* [Textadept 2.0 beta -- Source][]

Bugfixes:

* Alphabetize lexer list.
* Fixed some locale issues.
* Fixed some small memory leaks.
* Try a [list of encodings][] rather than just UTF-8 so "conversion failed" does
  not happen so often.
* Restore a manually set lexer.

Changes:

* Removed `_m.textadept.macros` module and respective PM browser (use Lua
  instead).
* Linux version can be installed and run from anywhere; no need to recompile
  anymore.
* Added many more [events][] to hook into lots of core functionality.
* Updated to [Scintilla][] 1.79.
* Run module allows more flexible [compile commands][] and [run commands][].
* Save project manager cursor over sessions.
* Allow mime-types and compile and run commands to be user-redefinable in user
  scripts.
* Use `~/.textadept/` for holding user lexers, themes, sessions, etc.
* Added "Help" menu linking to Manual and LuaDoc.
* Textadept compiles as C99 code. (Drops Microsoft Visual Studio support.)
* Sessions functionality moved to `modules/textadept/session.lua` from
  `core/file_io.lua`.
* The `char_added` event now passes an int, not a string, to handler functions.
* Replaced [cocoaDialog][] and [lua_dialog][] with my C-based [gtdialog][].
* [Incremental find][] via the Lua command entry.
* *NO* dependencies other than [GTK][] on _all_ platforms.

  + Win32 no longer requires the MSVC++ 2008 Runtime.
  + Linux no longer requires `libffi`.
  + Mac OSX no longer requires [cocoaDialog][].

* Can cross compile to Win32 from Linux.
* Removed confusing `local function` and `local table` LuaDoc.
* Rewrote the manual and most of the documentation.

[Textadept 2.0 beta -- Win32]: download/textadept_2.0_beta.win32.zip
[Textadept 2.0 beta -- Linux]: download/textadept_2.0_beta.tgz
[Textadept 2.0 beta -- Linux x86_64]: download/textadept_2.0_beta.x86_64.tgz
[Textadept 2.0 beta -- Source]: download/textadept_2.0_beta.src.zip
[list of encodings]: api.html#io.encodings
[events]: api.html#events
[Scintilla]: http://scintilla.org
[compile commands]: api.html#textadept.run.compile_commands
[run commands]: api.html#textadept.run.run_commands
[gtdialog]: http://foicica.com/gtdialog
[lua_dialog]: http://luaforge.net/projects/lua-dialog
[cocoaDialog]: http://cocoadialog.sf.net
[Incremental find]: manual.html#Incremental.Find
[GTK]: http://gtk.org

## 1.6 (01 Apr 2009)

Download:

* [Textadept 1.6 -- Win32][]
* [Textadept 1.6 -- Mac OSX Intel 10.5+][]
* [Textadept 1.6 -- Linux][]
* [Textadept 1.6 -- Linux x86_64][]
* [Textadept 1.6 -- Source][]

Bugfixes:

* Fixed `NULL` byte bug associated with Lua interface due to multi-encoding
  support.
* Find marker is colored consistently.
* Fixed issue with buffer browser cursor saving.
* Fixed block character insertion issue on GTK-OSX.

Updates:

* Trimmed theme files.
* Added [`file_before_save`][] event.

[Textadept 1.6 -- Win32]: download/textadept_1.6.win32.zip
[Textadept 1.6 -- Mac OSX Intel 10.5+]: download/textadept_1.6.dmg
[Textadept 1.6 -- Linux]: download/textadept_1.6.tgz
[Textadept 1.6 -- Linux x86_64]: download/textadept_1.6.x86_64.tgz
[Textadept 1.6 -- Source]: download/textadept_1.6.src.zip
[`file_before_save`]: api.html#events.FILE_BEFORE_SAVE

## 1.6 beta (01 Mar 2009)

Download:

* [Textadept 1.6 beta -- Win32][]
* [Textadept 1.6 beta -- Mac OSX Intel 10.5+][]
* [Textadept 1.6 beta -- Linux][]
* [Textadept 1.6 beta -- Linux x86_64][]
* [Textadept 1.6 beta -- Source][]

Bugfixes:

* Fixed bookmarks bugs.
* PM browsers are not re-added to the list again on `textadept.reset()`.
* Fixed ctags PM browser bug with filenames.
* Marker colors are set for all views now.
* Fixed never-ending "reload modified file?" dialog bug.
* Fixed key command for `m_snippets.list`.
* Fixed issues with [`_m.textadept.run`][] module.
* Fixed document modification status bug for unfocused split views.
* Fixed filename encoding issues for Windows.

Updates:

* Added key commands and menu items to navigate "Find in Files" list.
* The `recent_files` popup list behaves better.
* Attempt to preserve existing EOL mode for opened files.
* Add drag-and-dropped directories to the PM browser list.
* Removed `project` PM browser.
* Multiple character encoding support for opening and saving files.

[Textadept 1.6 beta -- Win32]: download/textadept_1.6beta.win32.zip
[Textadept 1.6 beta -- Mac OSX Intel 10.5+]: download/textadept_1.6beta.dmg
[Textadept 1.6 beta -- Linux]: download/textadept_1.6beta.tgz
[Textadept 1.6 beta -- Linux x86_64]: download/textadept_1.6beta.x86_64.tgz
[Textadept 1.6 beta -- Source]: download/textadept_1.6beta.src.zip
[`_m.textadept.run`]: api.html#textadept.run

## 1.5 (20 Feb 2009)

Download:

* [Textadept 1.5 -- Win32][]
* [Textadept 1.5 -- Mac OSX Intel 10.5+][]
* [Textadept 1.5 -- Linux][]
* [Textadept 1.5 -- Linux x86_64][]
* [Textadept 1.5 -- Source][]

Bugfixes:

* Fixed some corner cases in Find in Files user interface.
* Fixed some OSX key command issues for consistency.
* Fixed some key command modifiers for "enclose in" series.

Updates:

* Consolidated `core/ext/key_commands_{std,mac}.lua` into single
  `core/ext/key_commands.lua`.
* Can use the `Tab` and `Shift+Tab` keys for snippets now.
* Removed support for Textmate-style snippets in favor of Lua-style snippets.
* Load drag-and-dropped directories into file browser.
* Can toggle showing "dot" files in file browser.
* Prompt for file reload when files are modified outside Textadept.
* Added `textadept.context_menu` field for right-click inside Scintilla.
* Project Manager cursors are saved and restored.
* Only use escape sequences in Lua pattern searches.
* Rewrote `modules/textadept/run.lua` to be easier to use and configure.
* Find in Files marks the selected line for easier reference.
* Save special buffers in session file (e.g. error buffer, message buffer, etc.)
* Moved mime-types into `core/ext/mime_types.conf` configuration file.
* Moved localization into `core/locale.conf` configuration file.

[Textadept 1.5 -- Win32]: download/textadept_1.5.win32.zip
[Textadept 1.5 -- Mac OSX Intel 10.5+]: download/textadept_1.5.dmg
[Textadept 1.5 -- Linux]: download/textadept_1.5.tgz
[Textadept 1.5 -- Linux x86_64]: download/textadept_1.5.x86_64.tgz
[Textadept 1.5 -- Source]: download/textadept_1.5.src.zip

## 1.4 (10 Feb 2009)

Download:

* [Textadept 1.4 -- Win32][]
* [Textadept 1.4 -- Mac OSX Intel 10.5+][]
* [Textadept 1.4 -- Linux][]
* [Textadept 1.4 -- Linux x86_64][]
* [Textadept 1.4 -- Source][]

Bugfixes:

* Handle empty clipboard properly.
* Fixed some widget focus issues.
* Fixed a couple Find in Files bugs.
* Workaround for GTK-OSX pasting issue.

Updates:

* Added menu options for changing line endings.
* The Project Manager Entry responds better.
* Improved Lua State integrity for critical data.
* Keep only 10 items in Find/Replace history.
* Special buffers are not "Untitled" anymore.
* Moved `textadept.locale` table to `_G`.

[Textadept 1.4 -- Win32]: download/textadept_1.4.win32.zip
[Textadept 1.4 -- Mac OSX Intel 10.5+]: download/textadept_1.4.dmg
[Textadept 1.4 -- Linux]: download/textadept_1.4.tgz
[Textadept 1.4 -- Linux x86_64]: download/textadept_1.4.x86_64.tgz
[Textadept 1.4 -- Source]: download/textadept_1.4.src.zip

## 1.3 (30 Jan 2009)

Download:

* [Textadept 1.3 -- Win32][]
* [Textadept 1.3 -- Mac OSX Intel 10.5+][]
* [Textadept 1.3 -- Linux][]
* [Textadept 1.3 -- Linux x86_64][]
* [Textadept 1.3 -- Source][]

Bugfixes:

* Binary files are opened and handled properly.
* Drag-and-dropped files are now opened in the correct split view they were
  dropped in.
* Fixed some various GTK-OSX UI issues.
* Fixed a special case of "Replace All".
* Clicking "Ok" closes any error dialogs on init.
* Fixed statusbar glitch when creating new buffers.
* Windows' CR+LF line endings are handled properly.
* Do not go to non-existent buffer index when loading session.
* Do not attempt to open non-existent files when double-clicking error messages.

Updates:

* Look for `~/.ta_theme` for setting Textadept `_THEME`.
* `_THEME` can now be a directory path.
* Themes now contain their own `lexer.lua` for defining lexer colors.
* Added "Find in Files" support.
* Can set the Project Manager cursor through Lua.
* Look for `~/.ta_modules` to load instead of default modules in `init.lua`.
* Added "Replace All" for just selected text.
* Removed menu label text in favor of using menu id numbers for menu actions.
* Added Find/Replace history.
* Use a combo entry for the Project Manager browser entry.
* Print messages to a split view instead of switching buffers.

[Textadept 1.3 -- Win32]: download/textadept_1.3.win32.zip
[Textadept 1.3 -- Mac OSX Intel 10.5+]: download/textadept_1.3.dmg
[Textadept 1.3 -- Linux]: download/textadept_1.3.tgz
[Textadept 1.3 -- Linux x86_64]: download/textadept_1.3.x86_64.tgz
[Textadept 1.3 -- Source]: download/textadept_1.3.src.zip

## 1.2 (21 Jan 2009)

Download:

* [Textadept 1.2 -- Win32][]
* [Textadept 1.2 -- Mac OSX Intel 10.5+][]
* [Textadept 1.2 -- Linux][]

Bugfixes:

* None.

Updates:

* Windows command line support ("Open With Textadept" works too).
* New [`_m.textadept.run`][] module for compiling and running programs. Output
  is displayed in a message buffer and you can double-click errors and warnings
  to go to them in the source file.

[Textadept 1.2 -- Win32]: download/textadept_1.2.win32.zip
[Textadept 1.2 -- Mac OSX Intel 10.5+]: download/textadept_1.2.dmg
[Textadept 1.2 -- Linux]: download/textadept_1.2.tgz
[`_m.textadept.run`]: api.html#textadept.run

## 1.1 (11 Jan 2009)

Download:

* [Textadept 1.1 -- Win32][]
* [Textadept 1.1 -- Mac OSX Intel 10.5+][]
* [Textadept 1.1 -- Linux][]

Bugfixes:

* Fixed `core/ext/key_commands_std.lua` key conflict (`Ctrl+V`).

Updates:

* Dramatic speed increase in lexing for large, single-language files.
* Added [localization][] support.
* Added [bookmarks][] support.
* All `require` statements have been moved to `init.lua` for easy module
  configuration.
* Various improvements to efficiency, speed, and readability of source code.
* Manually parse `~/.gtkrc-2.0` on Mac since GTK-OSX does not do it.

[Textadept 1.1 -- Win32]: download/textadept_1.1_win32.zip
[Textadept 1.1 -- Mac OSX Intel 10.5+]: download/textadept_1.1.dmg
[Textadept 1.1 -- Linux]: download/textadept_1.1.tgz
[localization]: api.html#_L
[bookmarks]: api.html#textadept.bookmarks

## 1.0 (01 Jan 2009)

Download:

* [Textadept 1.0 -- Win32][]
* [Textadept 1.0 -- Mac OSX Intel 10.5+][]
* [Textadept 1.0 -- Linux][]

Bugfixes:

* Fixed bug with placeholders in Lua-style snippets.
* Fixed view grow/shrink error thrown when the view is not split.
* Various fixes to recognize windows directory separators.
* Fixed some Find bugs.
* Fixed macro recording and playback bugs.

Updates:

* Added actions for all menu items.
* Added Lua interface functions and fields for the [find][] box.
* Nearly full Mac OSX support with [GTK-OSX][].
* Compile [LPeg][] and [LuaFileSystem][] libraries into Textadept by default.
* Use UTF-8 encoding by default.
* Added `light` color theme used by default.
* New Textadept icons.
* Added a true project manager.

[Textadept 1.0 -- Win32]: download/textadept_1.0_win32.zip
[Textadept 1.0 -- Mac OSX Intel 10.5+]: download/textadept_1.0.dmg
[Textadept 1.0 -- Linux]: download/textadept_1.0.tgz
[find]: api.html#ui.find
[GTK-OSX]: http://www.gtk.org/download/macos.php
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[LuaFileSystem]: http://keplerproject.github.com/luafilesystem/

## 0.6 (03 Oct 2008)

Download:

* [Textadept 0.6 -- Win32][]
* [Textadept 0.6 -- Linux][]
* [Textadept 0.6 -- Linux x86_64][]

Bugfixes:

* Gracefully exit when `core/init.lua` fails to load.

Updates:

* Windows support! (finally)
* [Theming][] support (SciTE theme used by default).
* Added `textadept.size` field and save it in session files.
* Some C++ API-simplifying changes.
* Drag-and-drop files into Textadept works as expected.
* Revised [manual][].
* Buffer and View properties are no longer set in C++, but in Lua through
  "buffer_new" and "view_new" event handlers respectively.
* File types can be recognized by [pattern matching][] the first line.

[Textadept 0.6 -- Win32]: download/ta_beta_r6_win32.zip
[Textadept 0.6 -- Linux]: download/ta_beta_r6.tgz
[Textadept 0.6 -- Linux x86_64]: download/ta_beta_r6_x86_64.tgz
[Theming]: manual.html#Themes
[manual]: manual.html
[pattern matching]: manual.html#File.Types

## 0.5 (23 Jul 2008)

Download:

* [Textadept 0.5 -- Linux][]
* [Textadept 0.5 -- Linux x86_64][]

Bugfixes:

* Fixed bug in Lua module when there is no matching file to go to.

Updates:

* Added user-friendly key commands and menus.
* Added 43 more lexers.
* Moved block-comment commands from language modules to `textadept.editing`
  module.
* Updated some Luadoc.

[Textadept 0.5 -- Linux]: download/ta_beta_r5.tgz
[Textadept 0.5 -- Linux x86_64]: download/ta_beta_r5_x86_64.tgz

## 0.4 (25 Jun 2008)

Download:

* [Textadept 0.4 -- Mac OSX Intel 10.5+][]
* [Textadept 0.4 -- Linux][]
* [Textadept 0.4 -- Linux x86_64][]

Bugfixes:

* Fixed bug with "%" being contained in text to replace.
* Fixed compile warnings.
* Fixed bug for menu actions on non-focused buffer.

Updates:

* Added [bookmark][] support through `modules/textadept/bookmarks.lua` (not
  loaded by default).
* Added icons to Textadept.
* Added a modules browser for adding, deleting, and editing modules easily.
* Consolidated source files into `textadept.c`, `textadept.h`, and
  `lua_interface.c`.
* Always load project manager settings from session file if available.
* Include `liblua5.1.a` for compiling Lua into Textadept.
* Added true [tab-completion][] to Lua command entry.
* Added Doxygen documentation for C source files.
* Updated Luadoc, and added Textadept manual.

[Textadept 0.4 -- Mac OSX Intel 10.5+]: download/ta_beta_r4_osx.tgz
[Textadept 0.4 -- Linux]: download/ta_beta_r4.tgz
[Textadept 0.4 -- Linux x86_64]: download/ta_beta_r4_x86_64.tgz
[bookmark]: api.html#textadept.bookmarks
[tab-completion]: manual.html#Command.Entry.Tab.Completion

## 0.3 (04 Mar 2008)

Download:

* [Textadept 0.3 -- Linux][]

Bugfixes:

* Fixed bug in editing module's `select_indented_block()`.
* Fixed empty [`buffer.filename`][] bug in `textadept.io.save_as()`.
* Fixed setting of Ruby lexer after detecting filetype.

Updates:

* Makefile builds Textadept to optimize for small size.
* Lua is no longer an external dependency and built into Textadept.
* [Zenity][] is no longer a dependency on Linux. [lua_dialog][] is used instead.
* Resources from `io.popen()` are handled more appropriately.
* Added `textadept.reset()` function for for reloading Lua scripts.
* Added new find in files project manager browser.
* Fixed some code redundancy and typos in documentation.

[Textadept 0.3 -- Linux]: download/ta_beta_r3.tgz
[`buffer.filename`]: api.html#buffer.filename
[Zenity]: http://live.gnome.org/Zenity
[lua_dialog]: http://luaforge.net/projects/lua-dialog

## 0.2 (20 Dec 2007)

Download:

* [Textadept 0.2 -- Mac OSX Intel 10.5+][]
* [Textadept 0.2 -- Linux][]

Bugfixes:

* Fixed command line parameters bug.
* Fixed `package.path` precedence bug.
* Use 8 style bits by default.

Updates:

* Scintilla-st.
* Lexers.
* Improved support for embedded language-specific snippets.

[Textadept 0.2 -- Mac OSX Intel 10.5+]: download/ta_beta_r2.1_osx.tgz
[Textadept 0.2 -- Linux]: download/ta_beta_r2.tgz

## 0.1 (01 Dec 2007)

Download:

* [Textadept 0.1 -- Mac OSX Intel 10.5+][]
* [Textadept 0.1 -- Linux][]

Initial Release

[Textadept 0.1 -- Mac OSX Intel 10.5+]: download/ta_beta_r1_osx.tgz
[Textadept 0.1 -- Linux]: download/ta_beta_r1.tgz

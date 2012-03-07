# Changelog

## 5.1 (01 Mar 2012)

Bugfixes:

* Fixed crash caused by [`gui.filteredlist()`][] dialogs.
* Support multiple `@return` tags in Lua Adeptsense.
* Fixed display of `buffer._type` when it has slashes in its name.

Changes:

* Better Lua Adeptsense formatting.
* Use new Cocoa-based [GtkOSXApplication][] library for better OSX support.
* Lexers with no tokens can be styled manually.
* Added more OSX default key shortcuts.

[`gui.filteredlist()`]: api/gui.html#filteredlist
[GtkOSXApplication]: https://live.gnome.org/GTK%2B/OSX/Integration#Gtk-mac-integration.2BAC8-GtkOSXApplication

## 5.0 (01 Feb 2012)

Please see the [4 to 5 migration guide][] for upgrading from Textadept 4 to
Textadept 5.

Bugfixes:

* Fixed bug with recent files in sessions.

Changes:

* Added default extension and folder filters in
  `modules/textadept/snapopen.lua`.
* Added ChucK lexer.
* Updated to [Scintilla][] 3.0.3.
* Also include [LuaJIT][] executables in releases.

[4 to 5 migration guide]: manual/14_Appendix.html#Textadept.4.to.5
[Scintilla]: http://scintilla.org
[LuaJIT]: http://luajit.org

## 5.0 beta (11 Jan 2012)

Bugfixes:

* Fixed bug in [`reset()`][] from update to Lua 5.2.

Changes:

* Changed `locale.localize()` to global [`_L`][] table and removed `locale`
  module.
* Renamed `_m` to [`_M`][].
* Do not clear registered images when autocompleting with Adeptsense.
* Renamed editing module's `current_word()` to [`select_word()`][].
* Updated [manual][].

[`reset()`]: api/_G.html#reset
[`_L`]: api/_L.html
[`_M`]: api/_M.html
[manual]: manual
[`select_word()`]: api/_M.textadept.editing.html#select_word

## 5.0 alpha (21 Dec 2012)

Bugfixes:

* None.

Changes:

* Updated to [Lua 5.2][].
* Updated sections in the [manual][] to reflect Lua 5.2 changes.
* Textadept can be compiled with [LuaJIT][].

[Lua 5.2]: http://www.lua.org/manual/5.2/
[manual]: manual
[LuaJIT]: http://luajit.org

## 4.3 (01 Dec 2011)

Bugfixes:

* Fixed bug with opening files in the current directory from the command line.
* Fixed erroneous charset conversion.

Changes:

* Added on-the-fly [theme switching][].
* All new `light` and `dark` themes.
* Removed `_m.textadept.editing.select_style()`.
* Simplify theming via [gtkrc][] by naming `GtkWindow` only.
* Updated to [Scintilla][] 3.0.1.

[theme switching]: api/gui.html#set_theme
[gtkrc]: manual/8_Themes.html#Theming.the.GUI
[Scintilla]: http://scintilla.org

## 4.2 (01 Nov 2011)

Bugfixes:

* Fixed bug with `%n` in Replace introduced in 4.1.
* Fixed Adeptsense autocomplete for single item.

Changes:

* Updated to [Scintilla][] 3.0.0.

[Scintilla]: http://scintilla.org

## 4.1 (01 Oct 2011)

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
  + Added `view.buffer` field.
  + Renamed `gui.check_focused_buffer()` to [`buffer:check_global()`][].
  + [`view:goto_buffer()`][] and [`gui.goto_view()`] arguments make sense now.
    (May require changes to custom key commands.)
* Directory is remembered in file chooser dialog after open or save as.
* Added language-specific [context menu][] support.
* Use [LuaCoco][] patch for Lua 5.1.4.
* Use lexer at the caret for key commands and snippets.
* Updated to [Scintilla][] 2.29.

[dwell events]: api/events.html
[`_BUFFERS`]: api/_G.html#_BUFFERS
[`_VIEWS`]: api/_G.html#_VIEWS
[`buffer:check_global()`]: api/buffer.html#buffer.check_global
[`view:goto_buffer()`]: api/view.html#view:goto_buffer
[`gui.goto_view()`]: api/gui.html#goto_view
[context menu]: api/_M.html#Context.Menu
[LuaCoco]: http://coco.luajit.org/
[Scintilla]: http://scintilla.org

## 4.0 (01 Sep 2011)

Please see the [3 to 4 migration guide][] for upgrading from Textadept 3 to
Textadept 4.

Bugfixes:

* Makefile should only link to `libdl.so` on Linux/BSD.
* Fixed memory access bug in [`gui.dialog()`][].
* Autocompletion list sort order respects `buffer.auto_c_ignore_case` now.
* Fixed split view focus bug with the same buffer in two views.
* Set new buffer EOL mode properly on Mac OSX.

Changes:

* Added Russian translation.
* Changed some key commands from 4.0 beta 2.
* Do not hide the statusbar when the command entry has focus.

[3 to 4 migration guide]: manual/14_Appendix.html#Textadept.3.to.4
[`gui.dialog()`]: api/gui.html#dialog

## 4.0 beta 2 (11 Aug 2011)

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

[recent file list]: api/io.html#recent_files

## 4.0 beta (01 Aug 2011)

Bugfixes:

* None.

Changes:

* Mac OSX uses GTK 2.24.
* Added [`io.open_recent_file()`][].
* Changes to localization file again.
* [`buffer` functions][] may omit the first `buffer` argument (e.g.
  `buffer.line_down()` is allowed).
* Complete overhaul of menus and added accelerators to [menu][] items.
* Renamed `_m.textadept.editing.SAVE_STRIPS_WS` to
  `_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`.
* Renamed `_m.textadept.editing.select_scope()` to
  `_m.textadept.editing.select_style()`.
* *Completely new set of key commands.*
* Updated to [Scintilla][] 2.28.

[`io.open_recent_file()`]: api/io.html#open_recent_file
[`buffer` functions]: api/buffer.html#Functions
[menu]: api/gui.html#gtkmenu
[Scintilla]: http://scintilla.org

## 3.9 (01 Jul 2011)

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

[GTK]: http://gtk.org
[`gui.dialog`]: api/gui.html#dialog
[functions]: api/_SCINTILLA.html#Functions
[Scintilla]: http://scintilla.org
[emit events]: api/_M.textadept.run.html#Run.Events
[find]: api/gui.find.html

## 3.8 (11 Jun 2011)

Bugfixes:

* Removed non-existant key chain.
* Fixed bug in snippets.

Changes:

* Updated Adeptsense and documentation.
* [`events.handlers`][] is accessible.
* Added menu mnemonics for indentation size.
* Added support for indicator and hotspot [events][].
* Updated [documentation][] for installing [official modules][].
* Updated to [Scintilla][] 2.26.
* Writing custom folding for lexers is much [easier][] now.
* Added native folding for more than 60% of existing lexers. The rest still use
  folding by indentation by default.

[`events.handlers`]: api/events.html#handlers
[events]: api/events.html
[documentation]: manual/7_Modules.html#Getting.Modules
[official modules]: http://foicica.com/hg
[Scintilla]: http://scintilla.org
[easier]: api/lexer.html#Simple.Code.Folding

## 3.7 (01 May 2011)

Bugfixes:

* Fixed bug in [`buffer:get_lexer()`][].

Changes:

* Changed Mac OSX Adeptsense complete key command from `~` to `Ctrl+Escape`.
* Added [PHP module][].

[`buffer:get_lexer()`]: api/buffer.html#buffer.get_lexer
[PHP module]: api/_M.php.html

## 3.7 beta 3 (01 Apr 2011)

Bugfixes:

* Small Adeptsense bugfixes.
* Snapopen respects filesystem encoding.
* Standard input dialogs have "Cancel" button by default.

Changes:

* Adeptsense tweaks for better completion and apidoc support.
* Language modules load a user [`post_init.lua`][] script if it exists.
* Added Ruby on Rails lexer and [module][].
* Added [RHTML module][].
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
* [`gui.print()`] handles `nil` and non-string arguments properly.
* Officially supported modules have their own [repositories][] and are available
  as a separate download.

[`post_init.lua`]: manual/7_Modules.html#Customizing.Modules
[module]: api/_M.rails.html
[RHTML module]: api/_M.rhtml.html
[`buffer:get_lexer(true)`]: api/buffer.html#buffer.get_lexer
[Scintilla]: http://scintilla.org
[`_m.textadept.snippets`]: api/_M.textadept.snippets.html
[`gui.print()`]: api/gui.html#print
[repositories]: http://foicica.com/hg

## 3.7 beta 2 (01 Mar 2011)

Bugfixes:

* Fixed bug with Win32 paths in Adeptsense [`goto_ctag()`][].
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
* Added Adeptsense [tutorial][].
* Added `_m.textadept.adeptsense.always_show_globals` setting for showing
  globals in completion lists.
* `Ctrl+H` (highlight word) is now `Ctrl+Shift+H`.
* `Ctrl+H` now shows Adeptsense documentation.
* Added Adeptsense [`complete()`][] and [`show_documentation()`][] functions to
  the menu.
* Language modules condensed into single `init.lua` file.
* Added `sense.syntax.word_chars` to Adeptsense.
* Included libpng12 build for 64-bit Debian-based Linux distros (Ubuntu).
* Added [CSS][], [HTML][], [Java][], and [Ruby][] modules with Adeptsenses.

[`goto_ctag()`]: api/_M.textadept.adeptsense.html#goto_ctag
[Scintilla]: http://scintilla.org
[tutorial]: api/_M.textadept.adeptsense.html
[`complete()`]: api/_M.textadept.adeptsense.html#complete
[`show_documentation()`]: api/_M.textadept.adeptsense.html#show_documentation
[CSS]: api/_M.css.html
[HTML]: api/_M.hypertext.html
[Java]: api/_M.java.html
[Ruby]: api/_M.ruby.html

## 3.7 beta (01 Feb 2011)

Bugfixes:

* `update_ui` is called properly for `buffer_new` and `view_new` events.
* Use proper pointer type for Scintilla calls.
* Fixed bug with loading lexers from `_USERHOME` on Win32.

Changes:

* More informative error message for unfocused buffer.
* Added [Adeptsense][], a smarter form of autocompletion for programming
  languages.
* Emit a [`language_module_loaded`][] as appropriate.
* Added indentation settings to "Buffer" menu (finally).
* Added [`gui.filteredlist()`][] shortcut for `gui.dialog('filteredlist', ...)`.
* Can navigate between bookmarks with a filteredlist.
* Language-specific [`char_matches`][] and [`braces`][] can be defined.
* `command_entry_keypress` event accepts modifier keys.

[Adeptsense]: manual/6_AdeptEditing.html#Adeptsense
[`language_module_loaded`]: api/_M.textadept.mime_types.html#Mime-type.Events
[`gui.filteredlist()`]: api/gui.html#filteredlist
[`char_matches`]: api/_M.textadept.editing.html#char_matches
[`braces`]: api/_M.textadept.editing.html#braces

## 3.6 (01 Jan 2011)

Bugfixes:

* Fixed infinite recursion errors caused in events.
* Fix statusbar update bug with key chains.
* Do not emit `buffer_new` event when splitting the view.

Changes:

* `buffer.rectangular_selection_modifier` on Linux is the Super/Windows key.
* Improved Hypertext lexer.
* Added Markdown, BibTeX, CMake, CUDA, Desktop Entry, F#, GLSL, and Nemerle
  lexers.
* Added [`_m.textadept.filter_through`][] module for [shell commands][].
* Moved GUI events from `core/events.lua` to `core/gui.lua`.
* Separated key command manager from key command definitions.

[`_m.textadept.filter_through`]: api/_M.textadept.filter_through.html
[shell commands]: manual/10_Advanced.html#Shell.Commands.and.Filtering.Text

## 3.5 (01 Dec 2010)

Bugfixes:

* Fixed bug introduced when exposing Find in Files API.

Changes:

* Lua files are syntax-checked for errors on save.
* [Menus][] are easier to create.
* Changed [`_m.textadept.editing.enclose()`][] behavior.
* Win32 and Mac OSX packages are all-in-one bundles; GTK is no longer an
  external dependency.
* New [manual][].
* Added `file_after_save` [event][].

[Menus]: api/_M.textadept.menu.html
[`_m.textadept.editing.enclose()`]: api/_M.textadept.editing.html#enclose
[manual]: manual
[event]: api/io.html#File.Events

## 3.4 (01 Nov 2010)

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
* `gui.statusbar_text` is now readable instead of being write-only.
* Can [highlight][] all occurances of a word.
* Added jsp lexer.
* More consistant handling of `\` directory separator for Win32.
* Consolidated `textadept.h` and `lua_interface.c` into single `textadept.c`
  file.
* Added [`_G.timeout()`][] function for calling functions and/or events after a
  period of time.
* Find in files is accessible through [find API][].
* Updated to [Scintilla][] 2.22.
* Renamed `_G.MAC` to `_G.OSX`.

[Switch Buffers]: manual/4_WorkingWithFiles.html#Buffer.Browser
[`gui.dialog()`]: api/gui.html#dialog
[`_m.textadept.snapopen.open()`]: api/_M.textadept.snapopen.html#open
[highlight]: manual/6_AdeptEditing.html#Word.Highlight
[`_G.timeout()`]: api/_G.html#timeout
[find API]: api/gui.find.html#find_in_files
[Scintilla]: http://scintilla.org

## 3.3 (01 Oct 2010)

Bugfixes:

* Fixed buggy snippet menu.

Changes:

* Added [`_m.textadept.snapopen`][] module with menu options for rapidly opening
  files.

[`_m.textadept.snapopen`]: api/_M.textadept.snapopen.html

## 3.2 (01 Sep 2010)

Bugfixes:

* Fixed "Replace All" infinite loop bug.

Changes:

* Updated to the new [Scintillua][] that does not required patched Scintilla.
* Updated to [Scintilla][] 2.21.

[Scintillua]: http://foicica.com/scintillua
[Scintilla]: http://scintilla.org

## 3.1 (21 Aug 2010)

Bugfixes:

* Fixed memory leak in Mac OSX.

Changes:

* Refactored key commands to support [propagation][].
* Updated to [Scintilla][] 2.20.
* Added Lua autocompletion.

[propagation]: api/keys.html#Propagation
[Scintilla]: http://scintilla.org

## 3.0 (01 Jul 2010)

Please see the [2 to 3 migration guide][] for upgrading from Textadept 2 to
Textadept 3.

Bugfixes:

* None

Changes:

* More accurate CSS and Diff lexers.

[2 to 3 migration guide]: manual/14_Appendix.html#Textadept.2.to.3

## 3.0 beta (21 Jun 2010)

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

[`buffer:text_range()`]: api/buffer.html#buffer.text_range
[`textadept`]: api/_M.textadept.html
[API]: api
[Scintilla]: http://scintilla.org
[Abbreviated]: manual/10_Advanced.html#Command.Entry
[arguments]: api/args.html
[`reset()`]: api/_G.html#reset

## 2.2 (11 May 2010)

Bugfixes:

* Save buffer before compiling or running.
* Fixed error in the manual for `~/.textadept/init.lua` example.
* Ignore `file://` prefix for filenames.

Changes:

* `_USERHOME` comes before `_HOME` in `package.path` so `require` searches
  `~/.textadept/` first.

## 2.2 beta 2 (01 May 2010)

Bugfixes:

* Fixed crash with [`buffer:text_range()`][].
* Fixed snippets bug with `%n` sequences.
* Respect tab settings for snippets.
* Fixed help hanging bug in Win32.
* Fixed Lua module commands bug.

Changes:

* Added BSD support.
* Removed kill-ring from editing module.
* [Run][] and [compile][] commands are in language-specific modules.
* [Block comment][] strings are in language-specific modules now.
* Remove "Untitled" buffer when necessary.
* Moved "Search" menu into "Tools" menu to prevent `Alt+S` key conflict.
* Rewrote lexers implementation.
* Added Inform, Lilypond, and NSIS lexers.
* `_m.textadept.editing.enclosure` is now an accessible table.

[`buffer:text_range()`]: api/buffer.html#buffer.text_range
[run]: api/_M.html#Run
[compile]: api/_M.html#Compile
[Block comment]: api/_M.html#Block.Comment

## 2.2 beta (01 Apr 2010)

Bugfixes:

* Fixed transform bug in snippets.
* Fixed bug with Io lexer mime-type.
* Fixed embedded css/javascript bug in hypertext (HTML) lexer.

Changes:

* Removed `_m.textadept.mlines` module since Scintilla's multiple selections
  supercedes it.
* Removed side pane.
* New [`gui.dialog('filteredlist', ...)] from [gcocoadialog][].
* Can select buffer from filteredlist dialog (replacing side pane buffer list).
* Can select lexer from filteredlist dialog.
* Can have user `key_commands.lua`, `snippets.lua`, `mime_types.conf`,
  `locale.conf` that are loaded by their respective modules.
* Added Matlab/Octave lexer.
* Backspace deletes auto-inserted character pairs.
* Added notification for session files not found.
* Snippets use multiple carets.
* Removed api file support.

[gcocoadialog]: http://foicica.com/gcocoadialog
[`gui.dialog('filteredist', ...)]: api/gui.html#dialog

## 2.1 (01 Mar 2010)

Bugfixes:

* Do not close files opened from command line when loading PM session.
* Fixed bug for running a file with no path.
* Fixed error message for session file not being found.
* Fixed key command for word autocomplete on Win32.
* Changed conflicting menu shortcut for Lexers menu.
* Fixed typos in templates generated by modules PM browser.

Changes:

* Added Dot and JSON lexers.
* Search `_USERHOME` in addition to `_HOME` for themes.
* Added command line switch for not loading/saving session.
* Modified key commands to be more key-layout agnostic.
* Added `reset_before` and `reset_after` events while `textadept.reset()` is
  being run.
* Reload current lexer module after `textadept.reset()`.
* Added `~/.textadept/modules/` to `package.path`.
* Updated to [Scintilla][] 2.03.
* Modified quit and close dialogs to be more readable.

[Scintilla]: http://scintilla.org

## 2.0 (01 Oct 2009)

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
* Added `style_whitespace` to [lexers][] for custom styles.
* Added standard `F3` key command for "Find Next" for Windows/Linux.

[lexers]: api/lexer.html

## 2.0 beta (31 Jul 2009)

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
* Replaced [cocoaDialog][] and [lua_dialog][] with my C-based [gcocoadialog][].
* [Incremental find][] via the Lua command entry.
* *NO* dependencies other than [GTK][] on _all_ platforms.

  + Win32 no longer requires the MSVC++ 2008 Runtime.
  + Linux no longer requires `libffi`.
  + Mac OSX no longer requires [cocoaDialog][].

* Can cross compile to Win32 from Linux.
* Removed confusing `local function` and `local table` LuaDoc.
* Rewrote the manual and most of the documentation.

[list of encodings]: api/io.html#try_encodings
[events]: api/events.html
[Scintilla]: http://scintilla.org
[compile commands]: api/_M.textadept.run.html#compile_command
[run commands]: api/_M.textadept.run.html#run_command
[gcocoadialog]: http://foicica.com/gcocoadialog
[lua_dialog]: http://luaforge.net/projects/lua-dialog
[cocoaDialog]: http://cocoadialog.sf.net
[Incremental find]: manual/6_AdeptEditing.html#Find.Incremental
[GTK]: http://gtk.org

## 1.6 (01 Apr 2009)

Bugfixes:

* Fixed `NULL` byte bug associated with Lua interface due to multi-encoding
  support.
* Find marker is colored consistently.
* Fixed issue with buffer browser cursor saving.
* Fixed block character insertion issue on GTK-OSX.

Updates:

* Trimmed theme files.
* Added `file_before_save` [event][].

[event]: api/io.html#File.Events

## 1.6 beta (01 Mar 2009)

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

[`_m.textadept.run`]: api/_M.textadept.run.html

## 1.5 (20 Feb 2009)

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

## 1.4 (10 Feb 2009)

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

## 1.3 (30 Jan 2009)

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

## 1.2 (21 Jan 2009)

Bugfixes:

* None.

Updates:

* Windows command line support ("Open With Textadept" works too).
* New [`_m.textadept.run`][] module for compiling and running programs. Output
  is displayed in a message buffer and you can double-click errors and warnings
  to go to them in the source file.

[`_m.textadept.run`]: api/_M.textadept.run.html

## 1.1 (11 Jan 2009)

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

[localization]: api/_L.html
[bookmarks]: api/_M.textadept.bookmarks.html

## 1.0 (01 Jan 2009)

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

[find]: api/gui.find.html
[GTK-OSX]: http://www.gtk.org/download/macos.php
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[LuaFileSystem]: http://keplerproject.github.com/luafilesystem/

## 0.6 (03 Oct 2008)

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

[Theming]: manual/8_Themes.html
[manual]: manual
[pattern matching]: manual/9_Preferences.html#Detect.by.Pattern

## 0.5 (23 Jul 2008)

Bugfixes:

* Fixed bug in Lua module when there is no matching file to go to.

Updates:

* Added user-friendly key commands and menus.
* Added 43 more lexers.
* Moved block-comment commands from language modules to `textadept.editing`
  module.
* Updated some Luadoc.

## 0.4 (25 Jun 2008)

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

[bookmark]: api/_M.textadept.bookmarks.html
[tab-completion]: manual/10_Advanced.html#Tab.Completion

## 0.3 (04 Mar 2008)

Bugfixes:

* Fixed bug in editing module's [`select_indented_block()`][].
* Fixed empty `buffer.filename` bug in `textadept.io.save_as()`.
* Fixed setting of Ruby lexer after detecting filetype.

Updates:

* Makefile builds Textadept to optimize for small size.
* Lua is no longer an external dependency and built into Textadept.
* [Zenity][] is no longer a dependency on Linux. [lua_dialog][] is used instead.
* Resources from `io.popen()` are handled more appropriately.
* Added `textadept.reset()` function for for reloading Lua scripts.
* Added new find in files project manager browser.
* Fixed some code redundancy and typos in documentation.

[`select_indented_block()`]: api/_M.textadept.editing.html#select_indented_block
[Zenity]: http://live.gnome.org/Zenity
[lua_dialog]: http://luaforge.net/projects/lua-dialog

## 0.2 (20 Dec 2007)

Bugfixes:

* Fixed command line parameters bug.
* Fixed `package.path` precedence bug.
* Use 8 style bits by default.

Updates:

* Scintilla-st.
* Lexers.
* Improved support for embedded language-specific snippets.

## 0.1 (01 Dec 2007)

Initial Release

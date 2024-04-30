## Changelog

[Atom Feed](https://github.com/orbitalquark/textadept/releases.atom)

### 12.4 (01 May 2024)

Download:

- [Textadept 12.4 -- Windows][]
- [Textadept 12.4 -- macOS 11+][]
- [Textadept 12.4 -- Linux][]
- [Textadept 12.4 -- Modules][]

Bugfixes:

- Fixed macOS bug where message dialogs did not return focus to the editor.
- Fixed Bash lexer to not highlight escaped '#' as comments.

Changes:

- Updated AutoHotkey, Perl, and Rust lexers with minor improvements.
- LSP: notify servers that diagnostics are supported.
- Scintilla: significantly reduce memory used for undo actions.
- Scintilla: added additional selection inactive colors to `view.element_color`.
- Scintilla: scale reverse arrow margin cursor to match user's cursor size.
- Updated to [Scintilla][] 5.5.0.

[Textadept 12.4 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.4/textadept_12.4.win.zip
[Textadept 12.4 -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.4/textadept_12.4.macOS.zip
[Textadept 12.4 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.4/textadept_12.4.linux.tgz
[Textadept 12.4 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.4/textadept_12.4.modules.zip
[Scintilla]: https://scintilla.org

### 12.3 (01 Mar 2024)

Download:

- [Textadept 12.3 -- Windows][]
- [Textadept 12.3 -- macOS 11+][]
- [Textadept 12.3 -- Linux][]
- [Textadept 12.3 -- Modules][]

Bugfixes:

- Fixed help files not showing up in Linux releases.
- Fixed `^⌘` key sequences not working on macOS.
- LSP: fixed diagnostics for some language servers that expect client diagnostic capababilities.
- Scintilla: workaround potential crash when a line contains both left-to-right and right-to-left
  text.

Changes:

- None.

[Textadept 12.3 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3/textadept_12.3.win.zip
[Textadept 12.3 -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3/textadept_12.3.macOS.zip
[Textadept 12.3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3/textadept_12.3.linux.tgz
[Textadept 12.3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3/textadept_12.3.modules.zip

### 12.3 beta (01 Jan 2024)

Download:

- [Textadept 12.3 beta -- Windows][]
- [Textadept 12.3 beta -- macOS 11+][]
- [Textadept 12.3 beta -- Linux][]
- [Textadept 12.3 beta -- Modules][]

Bugfixes:

- Do not assume filter through command output is encoded in `_CHARSET`.
- Only close the initial buffer if it is blank too.
- Fixed CMake constantly redownloading Qt SingleApplication module.
- Qt version: Allow keypad Enter to invoke action in Find & Replace pane entries
- Scintilla: fixed regex reverse search bug where a shortened match was returned.
- Scintilla: avoid character fragments in regular expression search results.
- Scintilla: fixed excessive memory use when deleting contiguous ranges backwards.
- Scintilla: fixed incorrect substitution when searching for a regular expression backwards.
- Scintilla: fix potential Qt crash when using IME with a large amount of text selected.

Changes:

- Added [`textadept.snippets.active`][].
- Scratch: New module for treating untitled buffers as persistent scratch buffers.
- Scintilla: Ctrl+Click on a selection deselects it in multiple selection mode.
- Scintilla: added [`buffer:change_selection_mode()`][].
- Scintilla: allow setting of `buffer.move_extends_selection`.
- Scintilla: improve global replace performance.
- Scintilla: make `buffer:move_selected_lines_up()` and `buffer:move_selected_lines_down()`
  work for regular selections.
- Updated to [Scintilla][] 5.4.1.

[Textadept 12.3 beta -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3_beta/textadept_12.3_beta.win.zip
[Textadept 12.3 beta -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3_beta/textadept_12.3_beta.macOS.zip
[Textadept 12.3 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3_beta/textadept_12.3_beta.linux.tgz
[Textadept 12.3 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.3_beta/textadept_12.3_beta.modules.zip
[`textadept.snippets.active`]: api.html#textadept.snippets.active
[`buffer:change_selection_mode()`]: api.html#buffer.change_selection_mode
[Scintilla]: https://scintilla.org

### 12.2 (01 Nov 2023)

Download:

- [Textadept 12.2 -- Windows][]
- [Textadept 12.2 -- macOS 11+][]
- [Textadept 12.2 -- Linux][]
- [Textadept 12.2 -- Modules][]

Bugfixes:

- Regex replacements with '^' anchors should only match once per line.
- Fix statusbar column number not including virtual space.
- Fixed terminal version crash in some list dialogs with UTF-8 characters in them.
- Gtk input dialogs are resizable.
- Fixed default Gtk icon dialog when none was specified.

Changes:

- Updated Brazilian Portuguese and Spanish localizations.

[Textadept 12.2 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2/textadept_12.2.win.zip
[Textadept 12.2 -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2/textadept_12.2.macOS.zip
[Textadept 12.2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2/textadept_12.2.linux.tgz
[Textadept 12.2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2/textadept_12.2.modules.zip

### 12.2 beta (01 Oct 2023)

Download:

- [Textadept 12.2 beta -- Windows][]
- [Textadept 12.2 beta -- macOS 11+][]
- [Textadept 12.2 beta -- Linux][]
- [Textadept 12.2 beta -- Modules][]

Bugfixes:

- Fixed crash during logout/restart on Windows while Textadept is still running.
- Prevent key bindings in the macOS menu from overriding user-specified bindings.
- Fixed interpretation of '-' command line argument as reading from stdin.
- Prevent duplicate key events from Scintilla.
- Only show message box icons in the Gtk version if they exist.
- Fixed display of window and dialog icons in Gtk.
- Correctly highlight built-in Bash variables surrounded by "${...}".

Changes:

- Implemented single-instance functionality on Windows (and Linux with Qt).
- Dropped legacy 11.x compatibility shims.
- Added Brazilian Portuguese localization.
- Updated Hare, fstab, and Matlab lexers.
- Updated Markdown lexer to detect code blocks delimited by `~~~`.
- Updated Bash lexer to disable conditional and arithmetic operator highlighting due to performance.
- Updated to [Scintilla][] 5.3.7.

[Textadept 12.2 beta -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2_beta/textadept_12.2_beta.win.zip
[Textadept 12.2 beta -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2_beta/textadept_12.2_beta.macOS.zip
[Textadept 12.2 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2_beta/textadept_12.2_beta.linux.tgz
[Textadept 12.2 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.2_beta/textadept_12.2_beta.modules.zip
[Scintilla]: https://scintilla.org

### 12.1 (01 Sep 2023)

Download:

- [Textadept 12.1 -- Windows][]
- [Textadept 12.1 -- macOS 11+][]
- [Textadept 12.1 -- Linux][]
- [Textadept 12.1 -- Modules][]

Bugfixes:

- Correctly recognize projects under Fossil version control.
- Fixed potential crash on GTK when opening a list dialog and immediately arrowing down.
- Fixed crash unsplitting a non-focused view whose other pane contains the focused view.
- Fixed some multi-byte characters in Julia lexer being incorrectly marked as operators.
- Fixed lack of legacy support for `lexer.fold_consecutive_lines()`.
- Do not highlight Bash variable pattern expansion as comments.
- Fixed potential crash with proxy lexers like RHTML.
- Scintilla: fixed crash when using IME with a large amount of text selected.

Changes:

- Added [`textadept.run.run_without_prompt`][] for running commands immediately
- Updated Hare lexer.

[Textadept 12.1 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.1/textadept_12.1.win.zip
[Textadept 12.1 -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.1/textadept_12.1.macOS.zip
[Textadept 12.1 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.1/textadept_12.1.linux.tgz
[Textadept 12.1 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.1/textadept_12.1.modules.zip
[`textadept.run.run_without_prompt`]: api.html#textadept.run.run_without_prompt

### 12.0 (01 Aug 2023)

Please see the [migration guide][] for migrating from Textadept 11 to 12.

Download:

- [Textadept 12.0 -- Windows][]
- [Textadept 12.0 -- macOS 11+][]
- [Textadept 12.0 -- Linux][]
- [Textadept 12.0 -- Modules][]

Bugfixes:

- Fixed potential crash when using legacy lexers.
- Fixed error switching to the only buffer that exists.
- Fixed case insensitive word completion from all buffers.
- Fixed syntax highlighting glitches on Windows.
- LSP: small fixes for language servers that do not play nicely.
- LSP: work around Scintilla repeatedly sending hover events on Windows and Qt.
- LSP: fixed active Lua parameter calculation if documented function uses ':'.
- LSP: fixed inaccurate recording of 'goto' position for history navigation.
- Export: use the correct dialog when prompting for a file to export to.

Changes:

- Updated Python lexer to support soft keywords.
- Removed unnecessary Qt DLLs from Windows release.
- LSP: query for updated diagnostics if the buffer has since been modified.
- Scintilla: input method improvements on Qt.
- Updated to [Lua][] 5.4.6.
- Updated to [LPeg][] 1.1.0.
- Updated to [Scintilla][] 5.3.6.

[migration guide]: manual.html#migrating-from-textadept-11-to-12
[Textadept 12.0 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0/textadept_12.0.win.zip
[Textadept 12.0 -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0/textadept_12.0.macOS.zip
[Textadept 12.0 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0/textadept_12.0.linux.tgz
[Textadept 12.0 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0/textadept_12.0.modules.zip
[Lua]: https://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/
[Scintilla]: https://scintilla.org

### 12.0 beta (01 Jul 2023)

Download:

- [Textadept 12.0 beta -- Windows][]
- [Textadept 12.0 beta -- macOS 11+][]
- [Textadept 12.0 beta -- Linux][]
- [Textadept 12.0 beta -- Modules][]

Bugfixes:

- Fixed a new view resetting a buffer's indentation settings.
- Fixed Qt bug where unsplitting in a second-level split view changed view focus.
- Do not silently print internal Lua errors.
- Fixed compile error with Gtk 2.0.
- Fixed Gtk list dialog display.
- Fixed Qt bug that disallowed literal '*' in list dialog filters.
- Fixed display of bullets in "session files not found" dialog on Windows.
- Do not attempt to show a snippet list without snippets.
- LSP: fixed calculation of character columns when tabs are enabled.
- LSP: Lua language server highlights ':' method parameters starting at 2, not 1.

Changes:

- Windows 10 and macOS 11 are the new minimum system requirements; Linux is unchanged.
- Moved "View Whitespace" and "Word Wrap" back into "View" menu and made them view-specific
  properties.
- Added alphanumeric [macro registers][].
- Autodetect dark mode and implement auto-switching between light and dark modes on Windows.
- Support Qt 6 and use it on Windows and macOS builds.
- Switch default indentation to size 8 tabs.
- Allow autocompleter functions to set separator character and sort order.
- Added [lua-std-regex][] and its `regex` Lua module.
- Support TextMate- and LSP-style snippets, and deprecated old format.
- Alias `Ctrl+Shift+U` (upper-case selection) to `Ctrl+Alt+Shift+U` in case the former is
  consumed by Linux for Unicode input.
- LSP: added support for snippet completions.
- LSP: support per-project language servers.

[Textadept 12.0 beta -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_beta/textadept_12.0_beta.win.zip
[Textadept 12.0 beta -- macOS 11+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_beta/textadept_12.0_beta.macOS.zip
[Textadept 12.0 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_beta/textadept_12.0_beta.linux.tgz
[Textadept 12.0 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_beta/textadept_12.0_beta.modules.zip
[macro registers]: manual.html#macros
[lua-std-regex]: https://github.com/orbitalquark/lua-std-regex

### 12.0 alpha 3 (01 May 2023)

Download:

- [Textadept 12.0 alpha 3 -- Windows][]
- [Textadept 12.0 alpha 3 -- macOS 10.13+][]
- [Textadept 12.0 alpha 3 -- Linux][]
- [Textadept 12.0 alpha 3 -- Modules][]

Bugfixes:

- Fixed syntax highlighting lag regression.
- Fixed updating buffer tab's "dirty" status on save all.
- Fixed error when backspacing over an auto-paired character before a multi-byte character.
- Fixed `events.AUTO_C_CANCELED` not existing.
- Fixed `_L` not returning non-localized messages.
- Do not show an empty quick open list.
- Qt version: fixed `button3` and `return_button` options for `ui.dialogs.list()`.
- LSP: fixed issue sending file URIs to language servers on Windows.
- LSP: fixed startup issue with many language servers that do not support selection ranges.
- LSP: test that call tip triggers are present before trying to find one.
- LSP: Lua language server writes its log to `_USERHOME`.
- Scintilla: fixed GTK bug with too many or too few lines when wrapping.
- Scintilla: draw background color for EOL annotations with no decorations or outlined with a box.
- Scintilla: fixed `buffer:lines_join()` bug where '\r' were incorrectly retained.
- Scintilla: fixed indicator drawing over the left margin in the Qt version.
- Scintilla: fix clipping of line end wrap symbol for `view.WRAPVISUALFLAGLOC_END_BY_TEXT`.

Changes:

- Autodetect dark mode and implement auto-switching between light and dark modes (macOS and
  Linux only for now).
- Revamped API documentation, mainly for buffer and view API to be more readable.
- Allow multiple selections in the recent file dialog.
- Added a dialog button to clear the recent files list.
- Hide the Windows popup console window when running Textadept as a Lua interpreter.
- `ui.print_silent()` and `ui.output_silent()` always print silently and return their print
  buffers.
- Restored `ui.command_entry.height` and `textadept.snippets.paths`.
- Increase `io.quick_open_max`.
- Allow short-hand access notation for menu items in [`textadept.menu.menubar`][].
- `events.MOUSE` emits a bit-mask of modifier keys instead of multiple booleans.
- Format: only ignore header lines that have no content.
- LSP: Lua language server supports local tables and functions.
- LSP: highlight the active call tip parameter when typing, if possible.
- Scintilla: draw lines more consistently by clipping drawing to just the line rectangle.
- Scintilla: draw `view.MARK_BAR` markers underneath other markers.
- Scintilla: enlarge `view.INDIC_POINT*` indicators and scale to be larger with text.
- Scintilla: make `view:line_scroll()` more accurate when the width of a space is not an integer.
- Scintilla: emit `events.AUTO_C_COMPLETED` when `buffer.auto_c_choose_single` is `true`.
- Scintilla: `buffer:para_up*()` go to the start position of the paragraph first.
- Scintilla: `view.rectangular_selection_modifier` works in the Qt version.
- Scintilla: support IME context in the GTK version.
- Scintilla: allow scrolling with mouse wheel when `view.*_scroll_bar` is `false` in the
  Qt version.
- Scintilla: added multi-threaded wrap to significantly improve performance of wrapping large
  files.
- Scintilla: allow individual bytes of multi-byte characters to be styled.
- Updated to [Scintilla][] 5.3.4.
- Updated to [Scinterm][] 5.0.

[Textadept 12.0 alpha 3 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_3/textadept_12.0_alpha_3.win.zip
[Textadept 12.0 alpha 3 -- macOS 10.13+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_3/textadept_12.0_alpha_3.macOS.zip
[Textadept 12.0 alpha 3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_3/textadept_12.0_alpha_3.linux.tgz
[Textadept 12.0 alpha 3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_3/textadept_12.0_alpha_3.modules.zip
[`textadept.menu.menubar`]: api.html#textadept.menu.menubar
[Scintilla]: https://scintilla.org
[Scinterm]: https://github.com/orbitalquark/scinterm

### 12.0 alpha 2 (01 Mar 2023)

Download:

- [Textadept 12.0 alpha 2 -- Windows][]
- [Textadept 12.0 alpha 2 -- macOS 10.13+][]
- [Textadept 12.0 alpha 2 -- Linux][]
- [Textadept 12.0 alpha 2 -- Modules][]

Bugfixes:

- Fixed auto-pair removal bug when backspacing over an auto-paired character.
- Fixed directory filters that contain directories to include.
- `textadept.editing.autocomplete()` should return `false` if no completions are displayed.
- Fixed clearing of a previous buffer's state when switching between buffers after closing one.
- Qt version: ensure the given directory is selected in Linux's directory selection dialog.
- Terminal version: fixed spawning processes on Linux and macOS.
- Terminal version: synchronize paragraph up/down extend selection key binding with GUI version.
- Scintilla: fixed scroll position update after `view:vertical_center_caret()`.
- Scintilla: prevent autocompletion of lists created during `events.CHAR_ADDED`.
- LSP: fixed diagnostic display.
- LSP: silently print to LSP buffer when starting language servers.
- LSP: properly handle incoming server requests.
- LSP: fixed "Find References".
- LSP: gracefully shut down language servers on quit too, not just reset.
- LSP: improved startup and error notifications.
- LSP: synchronize unsaved document changes when switching away from a buffer or view.
- LSP: handle unexpected language server exit (i.e. crash).
- LSP: fixed display of signature help when more than one option is present.

Changes:

- Language modules are no longer auto-loaded when their files are opened.
- All language autocompletion and documentation has been delegated to the external LSP module.
	- Deprecated C, CSS, Go, HTML, Lua, Python, and Ruby language modules.
	- Textadept no longer generates or uses Lua tags and api documentation files.
	- Deprecated the ctags module.
	- Removed "Tools > Complete Symbol" and "Tools > Show Documentation" menu items.
	- Removed `textadept.editing.api_files` and `textadept.editing.show_documentation()`.
- Hide the Find & Replace pane after an "In Files" search.
- Allow lexers to dictate what constitutes a word character.
- Added [`lexer.names()`][].
- Removed `textadept.editing.transpose_chars()`.
- Replaced `textadept.editing.typeover_chars` with [`typeover_auto_paired`][].
- Renamed `textadept.snippets.cancel_current()` to `cancel()`.
- Removed `textadept.snippets.path`.
- Added buffer representation argment to `events.BUFFER_DELETED`.
- Switched documentation format to [LDoc][] from LuaDoc.
- Added `-L` and `--lua` command line option for running Textadept as a standalone Lua interpreter.
- Scroll all views showing print/output buffers when printed to.
- Renamed `_SCINTILLA.next_*` to `_SCINTILLA.new_*`.
- `textadept.run.run_in_background` applies even if the output buffer is not open.
- Notify of compile/run/build/test/project command success or failure in statusbar.
- Autoscroll to the bottom of compile/run/build/test/project output buffer if possible.
- Removed `ui.command_entry.append_history()` and `ui.command_entry.height`.
- Use Scintillua as a Lua library instead of as a Scintilla lexer.
- Removed support for `buffer.property_int` (not `lexer.property_int`).
- LSP: updated to LSP 3.17.
- LSP: implemented selection range.
- LSP: support language-specific completion and signature help trigger characters.
- LSP: support highlighting active parameters in signature help.
- LSP: show relative paths in "Go To ..." dialogs if possible.
- LSP: send "textDocument/didClose" notifications.
- LSP: added simple Lua language server and enable it by default for Lua files.
- LSP: stop logging to a buffer and added "Show Log" menu option instead.
- LSP: allow for launching servers outside a project.

[Textadept 12.0 alpha 2 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_2/textadept_12.0_alpha_2.win.zip
[Textadept 12.0 alpha 2 -- macOS 10.13+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_2/textadept_12.0_alpha_2.macOS.zip
[Textadept 12.0 alpha 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_2/textadept_12.0_alpha_2.linux.tgz
[Textadept 12.0 alpha 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha_2/textadept_12.0_alpha_2.modules.zip
[`lexer.names()`]: api.html#lexer.names
[`typeover_auto_paired`]: api.html#textadept.editing.typeover_auto_paired
[LDoc]: https://stevedonovan.github.io/ldoc/

### 12.0 alpha (01 Jan 2023)

Download:

- [Textadept 12.0 alpha -- Windows][]
- [Textadept 12.0 alpha -- macOS 10.13+][]
- [Textadept 12.0 alpha -- Linux][]
- [Textadept 12.0 alpha -- Modules][]

Bugfixes:

- Fixed `io.get_project_root()` on Windows network shares.
- Fixed display of `Shift+Tab` key bindings in menus.
- Fixed toggling comments in multi-language lexers.
- Do not show duplicate lexer names in the selection list.
- Correctly recognize UTF-8 files with NUL bytes in them.
- GTK version: fixed invalid cast warning for split views.
- GTK version: handle movement keys from the list dialog entry when interactive search is not active.
- Terminal version: fixed crash cleaning up after a spawned process.
- Terminal version: improved spawn command parsing.
- Terminal version: fixed suspend/resume.
- Terminal version: fixed interpretation of backspace key in CDK entry boxes.

Changes:

- Added Qt version and made it the default for all platforms.
- The Qt version of Textadept is not a single-instance application, only the GTK version is.
- The minimum required version of macOS is 10.13 (High Sierra).
- Switched to [CMake-based build][] for building natively on Windows, macOS, and Linux.
- Redesigned key bindings to be more consistent and deterministic across OSes and platforms.
- Added 'Save' buttons to close and quit dialogs when there are unsaved buffers.
- Removed GTK support for Windows and macOS (Linux is still supported).
- Utilize "TEXTADEPT_HOME" environment variable, if it exists, in place of autodetected `_HOME`
  based on Textadept executable location.
- Added `_G.QT`.
- Include Go language module in separate set of modules.
- Quick open list shows relative paths if possible.
- Find in files result paths are relative to the searched directory.
- Buffer browser shows relative paths for files in the current project.
- More reasonable initial list dialog sizes.
- "Save As" dialog falls back onto the current directory if necessary.
- Deprecated reST and YAML modules.
- Added '-' command line option for reading from stdin into a new buffer.
- Removed 10-item find/replace history limit for the GUI version.
- Added [`ui.buffer_list_zorder`][] option and removed *zorder* parameter from `ui.switch_buffer()`.
  The buffer list order is most recently used first by default.
- Added [`ui.suspend()`][] for the terminal version, allowing any key binding to suspend the editor.
- `textadept.editing.auto_pairs` and `textadept.editing.typeover_chars` auto-include '<>'
  characters for XML-like languages and removed `textadept.editing.brace_matches`.
- Added menu option and key binding to undo last selected word.
- `ui.find.show_filenames_in_progressbar` is `false` by default now.
- Filters for `lfs.walk()`, `io.quick_open()`, and `ui.find_in_files()` now use glob patterns
  instead of Lua patterns.
- Changed `events.KEYPRESS` to only emit string key representations.
- Changed `events.TAB_CLICKED` to use key modifier mask like other events.
- Changed `textadept.editing.auto_pairs` and `textadept.editing.typeover_chars` to use string
  character keys instead of bytes.
- Added [`textadept.run.INDIC_WARNING`][] and [`textadept.run.INDIC_ERROR`][] for underlining
  compile, run, build, and test warning and error messages.

[Textadept 12.0 alpha -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha/textadept_12.0_alpha.win.zip
[Textadept 12.0 alpha -- macOS 10.13+]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha/textadept_12.0_alpha.macOS.zip
[Textadept 12.0 alpha -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha/textadept_12.0_alpha.linux.tgz
[Textadept 12.0 alpha -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_12.0_alpha/textadept_12.0_alpha.modules.zip
[CMake-based build]: manual.html#compiling
[`ui.buffer_list_zorder`]: api.html#ui.buffer_list_zorder
[`ui.suspend()`]: api.html#ui.suspend
[`textadept.run.INDIC_WARNING`]: api.html#textadept.run.INDIC_WARNING
[`textadept.run.INDIC_ERROR`]: api.html#textadept.run.INDIC_ERROR

### 11.5 alpha 2 (01 Nov 2022)

Download:

- [Textadept 11.5 alpha 2 -- Windows][]
- [Textadept 11.5 alpha 2 -- Mac OSX 10.10+][]
- [Textadept 11.5 alpha 2 -- Linux][]
- [Textadept 11.5 alpha 2 -- Modules][]

Bugfixes:

- Fixed memory leak after running timeout function.
- Fixed `buffer.eol_annotation_style*` settings.
- Fixed bug showing the buffer browser from the first buffer if zorder is `true`.
- Fixed display of compile/run commands in output.
- Fixed inability to use single-quoted command line arguments to `os.spawn()` in the terminal
  version.
- Open file mode: Fixed bug loading module during Textadept initialization.

Changes:

- Dropped BSD support.
- Separated GUI platform C code from non-GUI C code.
- Added `_G.GTK`.
- `_G.OSX` is now always true on macOS, not just in the GUI version.
- `buffer.tab_label` is now write-only.
- Replaced gtDialog with smaller set of built-in dialogs.
	- Deprecated `ui.dialogs.*msgbox()` in favor of [`ui.dialogs.message()`][],
	  `ui.dialogs.*inputbox()` in favor of [`ui.dialogs.input()`][], `ui.dialogs.fileselect()` in
	  favor of [`ui.dialogs.open()`][], `ui.dialogs.filesave()` in favor of [`ui.dialogs.save()`][],
	  `ui.dialogs.progressbar()` in favor of [`ui.dialogs.progress()`][], and
	  `ui.dialogs.filteredlist()` in favor of [`ui.dialogs.list()`][].
	- Removed `ui.dialogs.textbox()`, `ui.dialogs.*dropdown()`, `ui.dialogs.optionselect()`,
	`ui.dialogs.colorselect()`, and `ui.dialogs.fontselect()`.
	- Input and list dialogs return text and selections first before button indices.
	- Input dialogs no longer accept multiple text entries and labels.
	- Removed `string_output` option from dialogs.
	- Renamed the following dialog options: `with_directory` &rarr; `dir`, `with_file` &rarr; `file`,
	  `select_multiple` &rarr; `multiple`, `select_only_directories` &rarr; `only_dirs`.
- Removed `opts` argument from `io.quick_open()`.
- Find in Files' file scanning is shown with a progress dialog and can be stopped.
- Deprecated `ui._print` in favor of [`ui.print_to()`][].
- `_L` no longer prefixes non-localized messages with "No Localization:".
- `textadept.run.stop()` presents a list dialog if there is more than one process running.
- Moved process spawning into platform C code.

[Textadept 11.5 alpha 2 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha_2/textadept_11.5_alpha_2.win.zip
[Textadept 11.5 alpha 2 -- Mac OSX 10.10+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha_2/textadept_11.5_alpha_2.macOS.zip
[Textadept 11.5 alpha 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha_2/textadept_11.5_alpha_2.linux.tgz
[Textadept 11.5 alpha 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha_2/textadept_11.5_alpha_2.modules.zip
[`ui.dialogs.message()`]: api.html#ui.dialogs.message
[`ui.dialogs.input()`]: api.html#ui.dialogs.input
[`ui.dialogs.open()`]: api.html#ui.dialogs.open
[`ui.dialogs.save()`]: api.html#ui.dialogs.save
[`ui.dialogs.progress()`]: api.html#ui.dialogs.progress
[`ui.dialogs.list()`]: api.html#ui.dialogs.list
[`ui.print_to()`]: api.html#ui.print_to

### 11.5 alpha (01 Oct 2022)

Download:

- [Textadept 11.5 alpha -- Windows][]
- [Textadept 11.5 alpha -- Mac OSX 10.10+][]
- [Textadept 11.5 alpha -- Linux][]
- [Textadept 11.5 alpha -- Modules][]

Bugfixes:

- Better display of startup errors.
- Reset horizontal scroll position after loading files.
- Improved showing API documentation from Lua command entry.
- Do not record history for multiple selection edits.
- Updated Bash lexer to improve heredoc handling

Changes:

- Lexers no longer share the same Lua state with Textadept or each other.
- Deprecated `lexer.colors` and `lexer.styles` in favor of [`view.colors`][] and [`view.styles`][],
  and deprecated `lexer.fold*` in favor of `view.fold*`.
- Implemented `buffer.lexer_language`.
- Added [`view:set_styles()`][] for manually applying styles to views.
- Added [`ui.output()`][] for compile/run/build/test output and removed
  `textadept.run.error_patterns`.
- Refreshed themes.
- Deprecated `textadept.editing.INDIC_BRACEMATCH` in favor of styles.
- Removed `ui.silent_print` in favor of [`ui.print_silent()`][] and [`ui.output_silent()`][].
- Changed [`ui.command_entry.run()`][] to add label, remove height, add initial text, and add
  args to pass to function.
- Compile/run/build/test commands now utilize command entry and have their own command histories.
- Removed `textadept.run.set_arguments()`.
- Added [`textadept.run.run_project()`][] and [`textadept.run.run_project_commands`][] for running
  project commands.
- Deprecated `textadept.file_types.extensions` and `textadept.file_types.patterns` in favor of
  [`lexer.detect_extensions`][] and [`lexer.detect_patterns`][], and moved
  `textadept.file_types.select_lexer` into the menu.
- Added [`io.ensure_final_newline`][] and decoupled this from
  `textadept.editing.strip_trailing_spaces`.
- Replaced "token" concept with "[tags][]" when writing lexers, and deprecated `lexer.token()`
  in favor of [`lex:tag()`][].
- Removed `lexer.property_expanded`.
- All lexers created with `lexer.new()` have a default whitespace style.
- Child lexers can extend their parent's keyword lists.
- Added `allow_indent` option to `lexer.starts_line()`.
- Deprecated `lexer.last_char_includes()` in favor of [`lexer.after_set()`][].
- `lexer.word_match()` can be used as an instance method for enabling users to set, replace,
  or extend word lists.
- Added [`lexer.number_()`][] and friends for creating patterns that match numbers separated
  by arbitrary characters.
- Allow prefix to be optional in `lexer.to_eol()`.
- Added "output" lexer for recognizing tool errors and warnings.
- Removed `lexer.fold_line_groups`.
- Scintilla: added `view.MARK_BAR` marker and `view.INDIC_POINT_TOP` indicator.
- Scintilla: optimized line state to avoid excessive allocations.
- Scintilla: added `view.FOLDACTION_CONTRACT_EVERY_LEVEL` for `view:fold_all()`.
- Scintilla: allow large fonts to be used in `view.STYLE_CALLTIP` without affecting text display.
- Updated to [Scintilla][] 5.3.0.

[Textadept 11.5 alpha -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha/textadept_11.5_alpha.win.zip
[Textadept 11.5 alpha -- Mac OSX 10.10+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha/textadept_11.5_alpha.macOS.zip
[Textadept 11.5 alpha -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha/textadept_11.5_alpha.linux.tgz
[Textadept 11.5 alpha -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.5_alpha/textadept_11.5_alpha.modules.zip
[`view.colors`]: api.html#view.colors
[`view.styles`]: api.html#view.styles
[`view:set_styles()`]: api.html#view.set_styles
[`ui.output()`]: api.html#ui.output
[`ui.print_silent()`]: api.html#ui.print_silent
[`ui.output_silent()`]: api.html#ui.output_silent
[`ui.command_entry.run()`]: api.html#ui.command_entry.run
[`textadept.run.run_project()`]: api.html#textadept.run.run_project
[`textadept.run.run_project_commands`]: api.html#textadept.run.run_project_commands
[`lexer.detect_extensions`]: api.html#lexer.detect_extensions
[`lexer.detect_patterns`]: api.html#lexer.detect_patterns
[`io.ensure_final_newline`]: api.html#io.ensure_final_newline
[tags]: api.html#tags
[`lex:tag()`]: api.html#lexer.tag
[`lexer.after_set()`]: api.html#lexer.after_set
[`lexer.number_()`]: api.html#lexer.number_
[Scintilla]: https://scintilla.org

### 11.4 (01 Aug 2022)

Download:

- [Textadept 11.4 -- Windows][]
- [Textadept 11.4 -- Mac OSX 10.7+][]
- [Textadept 11.4 -- Linux][]
- [Textadept 11.4 -- Modules][]

Bugfixes:

- Fixed line comment toggling for Batch.
- Fixed lack of HTML documentation in releases since 11.3.
- Ensure the statusbar is updated after `buffer:set_lexer()`.
- Ensure `events.LEXER_LOADED` is emitted on `buffer.new()`.
- LSP: Fixed off-by-one errors for go to definition et. al. and find references.
- LSP: Fixed bug attempting to start a language server manually.
- Lua REPL: Fixed key bindings.
- Ruby: Fixed bug when trying to toggle a block at the end of the buffer.
- Scintilla: Fixed hiding selection when `view.selection_layer` is `view.LAYER_UNDER_TEXT`.
- Scintilla: Fix potential issues with drawing non-UTF-8 text.

Changes:

- Changed line duplication to line/selection duplication.
- Added [`ui.popup_menu()`][] for displaying menus like the right-click context menu.
- The GUI version now recognizes the 'menu' key.
- Added support for Hare.
- Updated Spanish translation.
- Updated R, Fortran, and Go lexers.
- Updated to [Scintilla][] 5.2.4.

[Textadept 11.4 -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4/textadept_11.4.win.zip
[Textadept 11.4 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4/textadept_11.4.macOS.zip
[Textadept 11.4 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4/textadept_11.4.linux.tgz
[Textadept 11.4 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4/textadept_11.4.modules.zip
[`ui.popup_menu()`]: api.html#ui.popup_menu
[Scintilla]: https://scintilla.org

### 11.4 beta (01 Jun 2022)

Download:

- [Textadept 11.4 beta -- Windows][]
- [Textadept 11.4 beta -- Mac OSX 10.10+][]
- [Textadept 11.4 beta -- Linux][]
- [Textadept 11.4 beta -- Modules][]

Bugfixes:

- Correctly handle snippet mirrors in placeholders.
- Fixed default button theme on macOS.
- Fixed inability to run executables using some run commands on macOS.
- Scintilla: Fixed crash with unexpected right-to-left text.
- Scintilla: Fixed position of end-of-line annotation when fold display text is visible.
- Scintilla: Fixed partial updates and non-responsive scrollbars.

Changes:

- Scintilla: Improved performance of `view:fold_all(view.FOLDACTION_EXPAND)`.
- Updated to [Scintilla][] 5.2.3.

[Textadept 11.4 beta -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_beta/textadept_11.4_beta.win.zip
[Textadept 11.4 beta -- Mac OSX 10.10+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_beta/textadept_11.4_beta.macOS.zip
[Textadept 11.4 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_beta/textadept_11.4_beta.linux.tgz
[Textadept 11.4 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_beta/textadept_11.4_beta.modules.zip
[Scintilla]: https://scintilla.org

### 11.4 alpha (01 Apr 2022)

Download:

- [Textadept 11.4 alpha -- Windows][]
- [Textadept 11.4 alpha -- Mac OSX 10.10+][]
- [Textadept 11.4 alpha -- Linux][]
- [Textadept 11.4 alpha -- Modules][]

Bugfixes:

- Fixed bug in `ui.goto_view()` when specifying a preferred view.
- Fixed busy loop in `ui.update()` on macOS when monitoring output of spawned processes.
- Ensure preferred "lexer.trigger.ext" snippet files are used over "trigger.ext".
- Improved Windows network directory path handling.
- Fixed alpha color value of brace matches.
- Fixed busy wait on spawned process exit in some cases.
- Resize line number margin on reset.
- Fixed search wrapping indicator not showing up in the statusbar.
- Fixed "Find Next" for zero-width regex searches.
- Fixed calling `view:set_theme()` from the command entry.
- Scintilla: Fixed assertion failure with autocompletion lists when order is `ORDER_CUSTOM` or `ORDER_PERFORMSORT`.
- Scintilla: On Wayland, fixed autocompletion window display on secondary monitor.
- Scintilla: Fixed some scrollbar inaccuracies with annotations and wrapped lines.
- Scintilla: Improved Chinese character alignment with roman characters.

Changes:

- Use [GTK][] 3 by default on all platforms.
- Windows binaries are 64-bit now; dropped support for 32-bit Windows.
- The minimum required version of macOS is 10.10 (Yosemite).
- Tabs are now rearrangeable via drag and drop.
- Makefile allows building both the GUI and terminal versions concurrently.
- Updated test suite to run on Windows and macOS.
- Use Free Desktop Icon Naming Specification icon names in dialogs.
- New [Docker image][] for building with GTK 3.
- Added [`ui.find.show_filenames_in_progressbar`][] option for hiding filenames during Find in
Files searches.
- Added [`move_buffer()`][] function for rearranging buffers.
- Added support for flow control sequences in the non-Windows terminal version with `-p` and
  `--preserve` command line options.
- Updated Fennel lexer.
- Updated Python lexer to highlight class definitions.
- Scintilla: Improve performance for very long lines.
- Scintilla: Shift+Mouse Wheel scrolls horizontally.
- Updated to [Scintilla][] 5.2.0.
- Updated to [Lua][] 5.4.4.
- Updated to libtermkey 0.22.

[Textadept 11.4 alpha -- Windows]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_alpha/textadept_11.4_alpha.win.zip
[Textadept 11.4 alpha -- Mac OSX 10.10+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_alpha/textadept_11.4_alpha.macOS.zip
[Textadept 11.4 alpha -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_alpha/textadept_11.4_alpha.linux.tgz
[Textadept 11.4 alpha -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.4_alpha/textadept_11.4_alpha.modules.zip
[GTK]: https://gtk.org
[Docker image]: manual.html#compiling-using-docker
[`ui.find.show_filenames_in_progressbar`]: api.html#ui.find.show_filenames_in_progressbar
[`move_buffer()`]: api.html#move_buffer
[Scintilla]: https://scintilla.org
[Lua]: https://lua.org

### 11.3 (01 Feb 2022)

Download:

- [Textadept 11.3 -- Win32][]
- [Textadept 11.3 -- Mac OSX 10.7+][]
- [Textadept 11.3 -- Linux][]
- [Textadept 11.3 -- Modules][]

Bugfixes:

- Fixed attempted expansion of lexer name snippet that resolves to a table.
- Allow the line number margin to shrink when zooming out.
- Fixed menubar reset crash on macOS.
- Updated Ruby, C++, D, Gleam, Nim, and Verilog lexers to fix binary number parsing.

Changes:

- Improve repeated building of Textadept.app on macOS.
- Updated Perl lexer to recognize more numbers.

[Textadept 11.3 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3/textadept_11.3.win32.zip
[Textadept 11.3 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3/textadept_11.3.macOS.zip
[Textadept 11.3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3/textadept_11.3.linux.tgz
[Textadept 11.3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3/textadept_11.3.modules.zip

### 11.3 beta 3 (01 Dec 2021)

Download:

- [Textadept 11.3 beta 3 -- Win32][]
- [Textadept 11.3 beta 3 -- Mac OSX 10.7+][]
- [Textadept 11.3 beta 3 -- Linux][]
- [Textadept 11.3 beta 3 -- Modules][]

Bugfixes:

- Format: When formatting on save, check for filename first instead of assuming there is one.
- Scintilla: Fixed primary selection paste within same view.

Changes:

- Added '\`' as an autopair and typeover character.
- `textadept.editing.auto_enclose` keeps text selected.
- Scintilla: DEL (0x7F) is considered a space character.
- Updated to [Scintilla][] 5.1.4.

[Textadept 11.3 beta 3 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_3/textadept_11.3_beta_3.win32.zip
[Textadept 11.3 beta 3 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_3/textadept_11.3_beta_3.macOS.zip
[Textadept 11.3 beta 3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_3/textadept_11.3_beta_3.linux.tgz
[Textadept 11.3 beta 3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_3/textadept_11.3_beta_3.modules.zip
[Scintilla]: https://scintilla.org

### 11.3 beta 2 (01 Nov 2021)

Download:

- [Textadept 11.3 beta 2 -- Win32][]
- [Textadept 11.3 beta 2 -- Mac OSX 10.7+][]
- [Textadept 11.3 beta 2 -- Linux][]
- [Textadept 11.3 beta 2 -- Modules][]

Bugfixes:

- Fixed accidental drawing of whitespace, tab arrows, and indentation guides in margins when
  scrolling horizontally in the terminal version.
- Fixed accidental highlighting in margins when scrolling horizontally in the terminal version.
- Fixed occasional incorrect drawing when scrolling horizontally in the terminal version.
- Lua REPL: Fixed broken REPL on reset.

Changes:

- Hide the terminal cursor when the caret is out of view.
- Format: New module for formatting code and reformatting paragraphs.
- Debugger: Allow watch expressions without breaking on changes.
- Debugger: Implement setting stack frames in Lua and pretty-print variable values.
- Debugger: Prefer status buffers for variables and call stacks.

[Textadept 11.3 beta 2 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_2/textadept_11.3_beta_2.win32.zip
[Textadept 11.3 beta 2 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_2/textadept_11.3_beta_2.macOS.zip
[Textadept 11.3 beta 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_2/textadept_11.3_beta_2.linux.tgz
[Textadept 11.3 beta 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta_2/textadept_11.3_beta_2.modules.zip

### 11.3 beta (01 Oct 2021)

Download:

- [Textadept 11.3 beta -- Win32][]
- [Textadept 11.3 beta -- Mac OSX 10.7+][]
- [Textadept 11.3 beta -- Linux][]
- [Textadept 11.3 beta -- Modules][]

Bugfixes:

- Fixed Windows directory typos in the manual.
- Prevent running the command entry while in the command entry.
- Fixed uncommenting comments that are not initially aligned.
- Scintilla: Fixed display of fold lines when wrapped so they are only drawn once per line.
- Scintilla: Fixed crash with too many subexpressions in regex searches.
- Scintilla: Fixed lack of display of underscores in some monospaced fonts on Linux.
- Scintilla: Respond to changes in Linux font scaling.

Changes:

- Updated Makefile lexer to support multiple targets.
- Updated VB lexer to support folding.
- Lexers support more complex folding keywords and improved case-insensitivity.
- Scintilla: Added to `view.element_color` the ability to color fold lines and hidden lines.
- Scintilla: Added [`view.caret_line_highlight_subline`][] to highlight just the subline containing
  the caret.
- Scintilla: `view:hide_lines()` can now hide the first line or all lines.
- Scintilla: Make negative settings for extra ascent and descent safer.
- Scintilla: Deprecated `view.property_expanded` in favor of `lexer.property_expanded`.
- Updated to [Scintilla][] 5.1.3.

[Textadept 11.3 beta -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta/textadept_11.3_beta.win32.zip
[Textadept 11.3 beta -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta/textadept_11.3_beta.macOS.zip
[Textadept 11.3 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta/textadept_11.3_beta.linux.tgz
[Textadept 11.3 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.3_beta/textadept_11.3_beta.modules.zip
[`view.caret_line_highlight_subline`]: api.html#view.caret_line_highlight_subline
[Scintilla]: https://scintilla.org

### 11.2 (01 Aug 2021)

Download:

- [Textadept 11.2 -- Win32][]
- [Textadept 11.2 -- Mac OSX 10.7+][]
- [Textadept 11.2 -- Linux][]
- [Textadept 11.2 -- Modules][]

Bugfixes:

- Fixed trailing newline bug when filtering through with multiple/rectangular selection.
- Scintilla: Fixed bug in `buffer:get_last_child()` when level is `-1`.
- Scintilla: Word searching behaves more consistently at buffer boundaries.

Changes:

- Scintilla: Allow setting the appearance and color of character [representations][].
- Scintilla: Added [`buffer:replace_rectangular()`][].
- Scintilla: Optimize search in documents that contain mainly ASCII text.
- Updated to [Scintilla][] 5.1.1.

[Textadept 11.2 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2/textadept_11.2.win32.zip
[Textadept 11.2 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2/textadept_11.2.macOS.zip
[Textadept 11.2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2/textadept_11.2.linux.tgz
[Textadept 11.2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2/textadept_11.2.modules.zip
[representations]: api.html#view.representation
[`buffer:replace_rectangular()`]: api.html#buffer.replace_rectangular
[Scintilla]: https://scintilla.org

### 11.2 beta 3 (11 Jun 2021)

Download:

- [Textadept 11.2 beta 3 -- Win32][]
- [Textadept 11.2 beta 3 -- Mac OSX 10.7+][]
- [Textadept 11.2 beta 3 -- Linux][]
- [Textadept 11.2 beta 3 -- Modules][]

Bugfixes:

- Allow "Replace All" for empty regex matches like '^' and '$'.
- Fixed display of secondary selections on Linux.
- Fixed instances of incorrect caret/selection placement when typing after clearing buffer text.

Changes:

- Allow syntax highlighting to be preserved in selected text for default themes.
- `textadept.editing.filter_through()` respects multiple and rectangular selections.
- Support "Replace All" in multiple and rectangular selection.

[Textadept 11.2 beta 3 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_3/textadept_11.2_beta_3.win32.zip
[Textadept 11.2 beta 3 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_3/textadept_11.2_beta_3.macOS.zip
[Textadept 11.2 beta 3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_3/textadept_11.2_beta_3.linux.tgz
[Textadept 11.2 beta 3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_3/textadept_11.2_beta_3.modules.zip

### 11.2 beta 2 (01 Jun 2021)

Download:

- [Textadept 11.2 beta 2 -- Win32][]
- [Textadept 11.2 beta 2 -- Mac OSX 10.7+][]
- [Textadept 11.2 beta 2 -- Linux][]
- [Textadept 11.2 beta 2 -- Modules][]

Bugfixes:

- Fixed some file extension conflicts.
- Restore view scroll state after `textadept.editing.filter_through()`.
- Do not clobber user's terminal on initialization error.
- Modules: Refresh debugger breakpoints when buffer content is replaced and persist breakpoints
  and watchpoints on reset.
- Scintilla: Respect system font settings like antialiasing.
- Scintilla: Fix primary selection on GTK 3 and Wayland.

Changes:

- Save/restore view state when undoing/redoing full-buffer changes (e.g. code formatting).
- Added ability to specify find & replace pane font via [`ui.find.entry_font`][].
- Replaced `events.FILE_BEFORE_RELOAD` and `events.FILE_AFTER_RELOAD` with
  [`events.BUFFER_BEFORE_REPLACE_TEXT`][] and [`events.BUFFER_AFTER_REPLACE_TEXT`][].
- Added support for Gleam.
- Scintilla: Added [`view.indic_stroke_width`][], [`view.marker_fore_translucent`][],
  [`view.marker_back_translucent`][], [`view.marker_back_selected_translucent`][], and
  [`view.marker_stroke_width`][].
- Scintilla: Added new EOL annotation styles.
- Scintilla: Added [`view.element_color`][] for setting UI element colors (e.g. selection,
  caret, etc.) and deprecated `view:set_sel_fore()`, `view.sel_alpha`, `view.caret_fore`,
  etc. Also added [`view.element_allows_translucent`][], [`view.element_base_color`][], and
  [`view.element_is_set`][].
- Scintilla: `view.MARK_CHARACTER` markers now support unicode characters.
- Scintilla: added [`view.selection_layer`][], [`view.caret_line_layer`][], and
  [`view.marker_layer`][] in conjunction with `view.element_color` for alpha transparency.
- Scintilla: Included modifiers in `events.INDICATOR_RELEASE`.
- Scintilla: Update to Unicode 13.
- Updated to [Scintilla][] 5.0.3.

[Textadept 11.2 beta 2 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_2/textadept_11.2_beta_2.win32.zip
[Textadept 11.2 beta 2 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_2/textadept_11.2_beta_2.macOS.zip
[Textadept 11.2 beta 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_2/textadept_11.2_beta_2.linux.tgz
[Textadept 11.2 beta 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta_2/textadept_11.2_beta_2.modules.zip
[`ui.find.entry_font`]: api.html#ui.find.entry_font
[`events.BUFFER_BEFORE_REPLACE_TEXT`]: api.html#events.BUFFER_BEFORE_REPLACE_TEXT
[`events.BUFFER_AFTER_REPLACE_TEXT`]: api.html#events.BUFFER_AFTER_REPLACE_TEXT
[`view.indic_stroke_width`]: api.html#view.indic_stroke_width
[`view.marker_fore_translucent`]: api.html#view.marker_fore_translucent
[`view.marker_back_translucent`]: api.html#view.marker_back_translucent
[`view.marker_back_selected_translucent`]: api.html#view.marker_back_selected_translucent
[`view.marker_stroke_width`]: api.html#view.marker_stroke_width
[`view.element_color`]: api.html#view.element_color
[`view.element_allows_translucent`]: api.html#view.element_allows_translucent
[`view.element_base_color`]: api.html#view.element_base_color
[`view.element_is_set`]: api.html#view.element_is_set
[`view.selection_layer`]: api.html#view.selection_layer
[`view.caret_line_layer`]: api.html#view.caret_line_layer
[`view.marker_layer`]: api.html#view.marker_layer
[Scintilla]: https://scintilla.org

### 11.2 beta (01 Apr 2021)

Download:

- [Textadept 11.2 beta -- Win32][]
- [Textadept 11.2 beta -- Mac OSX 10.7+][]
- [Textadept 11.2 beta -- Linux][]
- [Textadept 11.2 beta -- Modules][]

Bugfixes:

- Fixed inability to replace found text with escapes like '\n' and '\t'.
- Fixed custom theme's overriding of default theme's colors.
- Do not mark GCC-style "note:" output as compile/run/build/test errors.
- Modules: Fixed inability to handle large LSP notifications.
- Modules: Prefer asynchronous LSP response reading on Windows in order to prevent hanging.
- Modules: Fixed bug where LSP is not notified of files opened during a session.
- Modules: Fixed LSP startup errors if the LSP command is ultimately nil.
- Modules: Fixed debugger status when paused.

Changes:

- Added `ui.SHOW_ALL_TABS` option for `ui.tabs`.
- Added support for TypeScript.
- The terminal version now uses a native terminal cursor instead of an artificially drawn one.
- Modules: Keep current line's scroll position when displaying LSP diagnostics.
- Modules: Added option to turn off LSP diagnostic display completely.
- Modules: Added `debugger.project_commands` for making project-specific debugging easier.
- Updated to [Lua][] 5.4.2.
- Updated to [Scintilla][] 5.0.0.

[Textadept 11.2 beta -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta/textadept_11.2_beta.win32.zip
[Textadept 11.2 beta -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta/textadept_11.2_beta.macOS.zip
[Textadept 11.2 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta/textadept_11.2_beta.linux.tgz
[Textadept 11.2 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.2_beta/textadept_11.2_beta.modules.zip
[Lua]: https://lua.org
[Scintilla]: https://scintilla.org

### 11.1 (01 Feb 2021)

Download:

- [Textadept 11.1 -- Win32][]
- [Textadept 11.1 -- Mac OSX 10.7+][]
- [Textadept 11.1 -- Linux][]
- [Textadept 11.1 -- Modules][]

Bugfixes:

- Do not prompt for file reload during `io.close_all_buffers()`.
- Ensure a bare `ui.find.focus()` call resets incremental and in files options.
- Fixed `buffer:reload()` only reloading up to a NUL byte, if present.
- Fixed minor file extension issues.
- Fixed bug restoring view state in an intermediate buffer after closing one.
- Fixed navigating back through history from a print buffer.
- Modules: Fixed incorrect LSP mouse hover query position.
- Modules: Only notify LSP servers about opened files after startup in order to avoid overwhelming
  the connection.

Changes:

- Save the current session prior to loading another one.
- Do not show deleted files in recent file list.
- Updated various lexers and fixed various small lexer issues.
- Added support for Clojure, Elm, Fantom, fstab, Julia, Meson, Pony, Reason, RouterOS, Spin,
  systemd, systemd-networkd, Xs, and Zig.
- Compile, run, and build command functions can also return environment tables.
- Added [`textadept.run.test()`][] and [`textadept.run.test_commands`][].
- `io.get_project_root()` accepts an optional flag for returning a submodule root.

[Textadept 11.1 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.1/textadept_11.1.win32.zip
[Textadept 11.1 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.1/textadept_11.1.macOS.zip
[Textadept 11.1 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.1/textadept_11.1.linux.tgz
[Textadept 11.1 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.1/textadept_11.1.modules.zip
[`textadept.run.test()`]: api.html#textadept.run.test
[`textadept.run.test_commands`]: api.html#textadept.run.test_commands

### 11.0 (01 Dec 2020)

Please see the [10 to 11 migration guide][] for upgrading from Textadept 10 to Textadept 11.

Download:

- [Textadept 11.0 -- Win32][]
- [Textadept 11.0 -- Mac OSX 10.7+][]
- [Textadept 11.0 -- Linux][]
- [Textadept 11.0 -- Modules][]

Bugfixes:

- Fixed find & replace entry unfocus when window is refocused.
- Modules: Fixed bug initializing spellcheck module in some instances.

Changes:

- Added optional mode parameter to `ui.command_entry.append_history()`.
- `keys[`*`lexer`*`]` and `snippets[`*`lexer`*`]` tables are present on init.
- Added [`events.FIND_RESULT_FOUND`][].
- Added [`events.UNFOCUS`][].

[10 to 11 migration guide]: manual.html#migrating-from-textadept-10-to-11
[Textadept 11.0 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0/textadept_11.0.win32.zip
[Textadept 11.0 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0/textadept_11.0.macOS.zip
[Textadept 11.0 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0/textadept_11.0.linux.tgz
[Textadept 11.0 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0/textadept_11.0.modules.zip
[`events.FIND_RESULT_FOUND`]: api.html#events.FIND_RESULT_FOUND
[`events.UNFOCUS`]: api.html#events.UNFOCUS

### 11.0 beta 2 (01 Nov 2020)

Download:

- [Textadept 11.0 beta 2 -- Win32][]
- [Textadept 11.0 beta 2 -- Mac OSX 10.7+][]
- [Textadept 11.0 beta 2 -- Linux][]
- [Textadept 11.0 beta 2 -- Modules][]

Bugfixes:

- Fixed the listing of bookmarks for all open buffers.
- Fixed "Enclose as XML Tags" with multiple selections.
- Fixed clearing of "Replace" entry in Find & Replace pane on reset in the GUI.
- Fixed lack of statusbar updating when setting options like buffer EOL mode, indentation,
  and encoding from the menu.
- Do not clear highlighting when searching inside the "Find in Files" buffer.
- `textadept.editing.strip_trailing_spaces` should not apply to binary files.
- Handle recursive symlinks in `lfs.walk()`.
- Modules: Fixed Lua debugger crash when inspecting variables with very large string
  representations.
- Modules: Support non-UTF-8 spelling dictionaries.
- Modules: Fixed YAML syntax checking notification.
- Modules: Fixed various small issues with the C debugger.

Changes:

- New [`textadept.history`][] module.
- Updated German and Russian translations.
- Added `ui.command_entry.append_history()` for special command entry modes that need to
  manually append history.
- Implement `\U`, `\L`, `\u`, and `\l` case transformations in regex replacements.
- Added [`textadept.run.set_arguments()`][].
- Modules: Each module in the separate modules download has its own repository now, but all
  are still bundled into a single archive for release.
- Modules: Greatly improved the speed of file comparison.
- Modules: Added ability to switch spelling dictionaries on the fly.
- Updated to [CDK][] 5.0-20200923.
- Updated to [LuaFileSystem][] 1.8.0.

[Textadept 11.0 beta 2 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta_2/textadept_11.0_beta_2.win32.zip
[Textadept 11.0 beta 2 -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta_2/textadept_11.0_beta_2.macOS.zip
[Textadept 11.0 beta 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta_2/textadept_11.0_beta_2.linux.tgz
[Textadept 11.0 beta 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta_2/textadept_11.0_beta_2.modules.zip
[`textadept.history`]: api.html#textadept.history
[`textadept.run.set_arguments()`]: api.html#textadept.run.set_arguments
[CDK]: https://invisible-island.net/cdk/
[LuaFileSystem]: https://github.com/keplerproject/luafilesystem

### 11.0 beta (01 Oct 2020)

Download:

- [Textadept 11.0 beta -- Win32][]
- [Textadept 11.0 beta -- Mac OSX 10.7+][]
- [Textadept 11.0 beta -- Linux][]
- [Textadept 11.0 beta -- Modules][]

Bugfixes:

- Fixed word left/right key bindings on macOS.
- Fixed regression with showing "No results found" in searches.
- Fixed regression in showing images in Lua command entry completions.
- Fixed restoration of Replace entry text in various instances, such as after "Find in Files"
  and "Replace All".
- Prevent infinite loops when highlighting found text.
- Fixed bugs in `events.KEYPRESS` handlers when command entry is active.
- Fixed bug in "Find in Files" results highlighting when jumping to a result of length 1.
- Fixed emission of `events.UPDATE_UI` when resuming from terminal suspend.
- Fixed initial query of `ui.find.find_text` and `ui.find.repl_text` in the terminal version.
- Fixed incorrect CSS key prefix incompatibility notice.
- Fixed error reporting the number of zero-length find results.
- Fixed call tip display in the terminal version.
- Always refresh during incremental find in the terminal version.
- Fixed `io.quick_open()` doing nothing when file limit was exceeded.
- gtDialog: Fixed potential crash when canceling a running progressbar dialog.
- Scintilla: Fixed position of marker symbols for `view.MARGIN_RTEXT` which were being moved
  based on width of text.
- Scintilla: Fixed hover indicator appearance when moving out of view.
- Scintilla: Fixed display of `buffer.INDIC_TEXTFORE` and gradient indicators on hover.

Changes:

- Rewrote manual and updated lots of other documentation and the documentation generation pipeline.
- Prefer passing an environment table to `os.spawn()`.
- Updated find & replace key bindings.
- Use comma-separated patterns in find & replace pane's "Filter" field.
- Removed "View EOL" menu item, key binding, and buffer setting.
- Accept a directory as a command line argument.
- Save the current working directory to session files.
- "View > Toggle Fold" toggles folding for the current block, regardless of line.
- Recognize Fossil projects.
- Added [`textadept.editing.auto_enclose()`][] for auto-enclosing selected text.
- Show "Match X/Y" in statusbar when searching for text.
- Added [`ui.command_entry.active`][].
- Improved handling of print buffers and splits.
- Added "Edit > Preferences" menu item and key binding for opening *~/.textadept/init.lua*.
- Disable `ui.find.highlight_all_matches` by default.
- GCC 7.1+ is now required for building, added support for [building with Docker][], and dropped
  automated Linux i386 builds.
- Added [`events.FIND_RESULT_FOUND`][].
- Added [`ui.find.active`][] and prevent word highlighting when searching.
- Added support for jq language.
- Record directory in "Find in Files" searches.
- Added `ui.update()`, mainly for unit tests.
- Added `events.FILE_BEFORE_RELOAD` and `events.FILE_AFTER_RELOAD` events, and save/restore
  bookmarks.
- Added [`events.COMMAND_TEXT_CHANGED`][] for when command entry text changes.
- Added `_NOCOMPAT` option to disable temporary key shortcut compatibility checking.
- Updated Spanish translation.
- gtDialog: Improved responsiveness for huge lists (greater than 10,000 items).
- Scintilla: Added [`view.multi_edge_column`][].
- Updated to [Scintilla][] 4.4.5.
- Switched back to utilizing [Scintillua][] and [Scinterm][].

[Textadept 11.0 beta -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta/textadept_11.0_beta.win32.zip
[Textadept 11.0 beta -- Mac OSX 10.7+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta/textadept_11.0_beta.macOS.zip
[Textadept 11.0 beta -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta/textadept_11.0_beta.linux.tgz
[Textadept 11.0 beta -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_beta/textadept_11.0_beta.modules.zip
[`textadept.editing.auto_enclose()`]: api.html#textadept.editing.auto_enclose
[`ui.command_entry.active`]: api.html#ui.command_entry.active
[building with Docker]: manual.html#compiling-using-docker
[`events.FIND_RESULT_FOUND`]: api.html#events.FIND_RESULT_FOUND
[`ui.find.active`]: api.html#ui.find.active
[`events.COMMAND_TEXT_CHANGED`]: api.html#events.COMMAND_TEXT_CHANGED
[`view.multi_edge_column`]: api.html#view.multi_edge_column
[Scintilla]: https://scintilla.org
[Scintillua]: https://orbitalquark.github.io/scintillua
[Scinterm]: https://orbitalquark.github.io/scinterm

### 11.0 alpha 3 (01 Aug 2020)

Download:

- [Textadept 11.0 alpha 3 -- Win32][]
- [Textadept 11.0 alpha 3 -- Mac OSX 10.6+][]
- [Textadept 11.0 alpha 3 -- Linux][]
- [Textadept 11.0 alpha 3 -- Linux x86_64][]
- [Textadept 11.0 alpha 3 -- Modules][]

Bugfixes:

- Fixed toggling of Find & Replace Pane visibility with `ui.find.focus()`.
- Fixed potential hangs with `os.spawn()` in the terminal version.
- Fixed `--line` command line option.
- Fixed `ui.dialogs.optionselect()`'s `text` option.
- Call `os.spawn()` exit callback after `proc:wait()`.
- Fixed an instance of buffer selection data not being saved to a session.
- Fixed initial setting of `ui.find.replace_entry_text` in the GUI.
- Fixed `keys.keychain[i]` access if its length ever exceeded 1.
- Modules: Fixed custom Lua regex for generating Ctags.
- Modules: Fixed file comparison colors in the terminal version.
- Modules: Fixed many bugs in file comparison and merging.
- Modules: Fixed export of styles defined only in lexers.
- Scintilla: Fixed crash when *lexer.lua* cannot be found.
- Scintilla: Fixed crash when setting a style with no token.

Changes:

- Renamed `buffer:set_theme()` to [`view:set_theme()`][].
- Replaced `lfs.dir_foreach()` with [`lfs.walk()`][] generator.
- Renamed some buffer/view fields to use American English instead of Australian English
  (e.g. "colour" to "color").
- Changed key binding modifier keys from `c` (Ctrl), `m` (Meta/Command), `a` (Alt), and `s`
  (Shift) to `ctrl`, `meta`/`cmd`, `alt`, and `shift`, respectively.
- Renamed `ui.bufstatusbar_text` to `ui.buffer_statusbar_text`.
- Only save before compile/run if the buffer has been modified.
- Added support for Fennel.
- Added [`buffer:style_of_name()`][] as an analogue to `buffer:name_of_style()`.
- When requiring modules, read from `LUA_PATH` and `LUA_CPATH` environment variables instead of
  `TA_LUA_PATH` and `TA_LUA_CPATH`.
- `ui.goto_file_found()` and `textadept.run.goto_error()` arguments are now optional.
- Moved Find Incremental into the Find & Replace pane (via [`ui.find.incremental`][]),
  eliminated `ui.find.find_incremental()` and `ui.find.find_incremental_keys`, and added
  [`events.FIND_TEXT_CHANGED`][].
- Replaced `textadept.editing.highlight_word()` with [`textadept.editing.highlight_words`][]
  auto-highlighting option.
- Find & Replace Pane now allows file filters to be specified for Find in Files.
- Use monospaced font in Find & Replace Pane text entries.
- Removed legacy "refresh syntax highlighting" feature.
- Modules: Added documentation for generating ctags and API files.
- Modules: Improved in-place editing of files during comparison.
- Scintilla: added [`lexer.colors`][] and [`lexer.styles`][] tables for use in themes. Also
  added new way to [define and reference styles][].
- Scintilla: Added [`lexer.fold*`][] options instead of setting view properties.
- Scintilla: Optimized performance when opening huge files.
- Scintilla: Added [`buffer.eol_annotation_text`][] analogue to `buffer.annotation_text`,
  but for EOL annotations.
- Scintilla: Display DEL control characters like other control characters.
- Scintilla: Allow caret width to be up to 20 pixel.
- Scintilla: Updated markdown and C lexers.
- Scintilla: Fixed bug with GTK on recent Linux distributions where underscores were invisible.
- Scintilla: Fixed GTK on Linux bug when pasting from closed application.
- Updated to [Scintilla][] 3.21.0.

[Textadept 11.0 alpha 3 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_3/textadept_11.0_alpha_3.win32.zip
[Textadept 11.0 alpha 3 -- Mac OSX 10.6+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_3/textadept_11.0_alpha_3.osx.zip
[Textadept 11.0 alpha 3 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_3/textadept_11.0_alpha_3.i386.tgz
[Textadept 11.0 alpha 3 -- Linux x86_64]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_3/textadept_11.0_alpha_3.x86_64.tgz
[Textadept 11.0 alpha 3 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_3/textadept_11.0_alpha_3.modules.zip
[`view:set_theme()`]: api.html#view.set_theme
[`lfs.walk()`]: api.html#lfs.walk
[`buffer:style_of_name()`]: api.html#buffer.style_of_name
[`ui.find.incremental`]: api.html#ui.find.incremental
[`events.FIND_TEXT_CHANGED`]: api.html#events.FIND_TEXT_CHANGED
[`textadept.editing.highlight_words`]: api.html#textadept.editing.highlight_words
[`lexer.colors`]: api.html#lexer.colors
[`lexer.styles`]: api.html#lexer.styles
[define and reference styles]: api.html#styles-and-styling
[`lexer.fold*`]: api.html#lexer.fold_by_indentation
[`buffer.eol_annotation_text`]: api.html#buffer.eol_annotation_text
[Scintilla]: https://scintilla.org

### 11.0 alpha 2 (01 Jun 2020)

Download:

- [Textadept 11.0 alpha 2 -- Win32][]
- [Textadept 11.0 alpha 2 -- Mac OSX 10.6+][]
- [Textadept 11.0 alpha 2 -- Linux][]
- [Textadept 11.0 alpha 2 -- Linux x86_64][]
- [Textadept 11.0 alpha 2 -- Modules][]

Bugfixes:

- Fixed some drive letter case issues on Windows resulting in duplicate open files.
- Fixed `os.spawn` exit callback and `spawn_proc:wait()` inconsistencies.
- Restore prior key mode after running the command entry.
- Fixed regression with word completion not respecting `buffer.auto_c_ignore_case`.
- Scintilla: Fixed display of windowed IME on Wayland.

Changes:

- Views can be used as buffers in most places, resulting in new [API suggestions][] for `buffer`
  and `view`.
- Scintilla: Added [`buffer:marker_handle_from_line()`][] and
  [`buffer:marker_number_from_line()`][] for iterating through the marker handles and marker
  numbers on a line.
- Scintilla: Deprecated `lexer.delimited_range()` and `lexer.nested_pair()` in favor of
  [`lexer.range()`][], and added [`lexer.to_eol()`][] and [`lexer.number`][].
- Scintilla: Automatically scroll text while dragging.
- Scintilla: Improved behavior of IME.
- Updated to [Scintilla][] 3.20.0.

[Textadept 11.0 alpha 2 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_2/textadept_11.0_alpha_2.win32.zip
[Textadept 11.0 alpha 2 -- Mac OSX 10.6+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_2/textadept_11.0_alpha_2.osx.zip
[Textadept 11.0 alpha 2 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_2/textadept_11.0_alpha_2.i386.tgz
[Textadept 11.0 alpha 2 -- Linux x86_64]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_2/textadept_11.0_alpha_2.x86_64.tgz
[Textadept 11.0 alpha 2 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha_2/textadept_11.0_alpha_2.modules.zip
[API suggestions]: manual.html#view-api-additions-and-buffer-api-changes
[`buffer:marker_handle_from_line()`]: api.html#buffer.marker_handle_from_line
[`buffer:marker_number_from_line()`]: api.html#buffer.marker_number_from_line
[`lexer.range()`]: api.html#lexer.range
[`lexer.to_eol()`]: api.html#lexer.to_eol
[`lexer.number`]: api.html#lexer.number
[Scintilla]: https://scintilla.org

### 11.0 alpha (31 Mar 2020)

Download:

- [Textadept 11.0 alpha -- Win32][]
- [Textadept 11.0 alpha -- Mac OSX 10.6+][]
- [Textadept 11.0 alpha -- Linux][]
- [Textadept 11.0 alpha -- Linux x86_64][]
- [Textadept 11.0 alpha -- Modules][]

Bugfixes:

- Fixed `--help` command line option.
- Fixed Textadept API autocompletion and documentation on Windows.
- Fixed bug that regards lexer-specific snippet files as global.
- Fixed hangs on Windows terminal version with `textadept.editing.filter_through()`.
- Fixed issues with buffer z-order when switching between views.
- Fixed accidental clipping of first character in a snippet under certain circumstances.
- Fixed C autocompletion error with typerefs.
- Fixed skipping of event handlers that come directly after one that was just run, but
  disconnected.
- Fixed bugs in the return values of `ui.dialogs.standard_dropdown` and `msgbox` dialogs.
- Fixed `events.FILE_CHANGED` not emitting a filename.
- Fixed bug with pipes in `textadept.editing.filter_through()`.
- Fixed tab label display on Windows.
- Fixed bug in syntax highlighting with PHP, Django, and other lexers that embed themselves.

Changes:

- All buffer positions, lines, and countable entities start from 1 instead of 0.
- Support more Alt and Shift+Alt keys in the Windows terminal version.
- `textadept.editing.api_files` acts as if it already has lexer tables defined.
- `textadept.run.goto_error()` wraps searches now.
- Added snippet trigger autocompletion via `textadept.editing.autocomplete('snippet')`.
- Improved Lua API documentation generator.
- Localization keys in `_L` no longer contain GUI mnemonics ('\_').
- `textadept.snippets` functions no longer have a '\_' prefix.
- `--help` command line options are alphabetized.
- The Lua command entry can now run any `view` functions by name (e.g. split).
- Auto-pair, type-over, and auto-deletion of matching braces now works with multiple selections.
- Removed `textadept.file_types.lexers` table in favor of asking the LPeg lexer for known
  lexer names.
- Updated German translation.
- Changed `textadept.bookmarks.toggle()` to only toggle bookmarks on the current line.
- Removed '=' prefix in command entry that would print results; printing results has been the
  default behavior for quite some time.
- Replaced `buffer.style_name[]` with [`buffer:name_of_style()`][].
- Session files are now Lua data files; old formats will no longer work.
- Added [`events.SESSION_SAVE`][] and [`events.SESSION_LOAD`][] events for saving and loading
  custom user data to sessions.
- Removed *~/.textadept/?.lua* and *~/.textadept/?.{so,dll}* from `package.path` and
  `package.cpath`, respectively.
- Lua errors in Textadept can now be jumped to via double-click or Enter.
- `ui.dialogs.filteredlist()` dialogs have a reasonable default width.
- Renamed `keys.MODE` to [`keys.mode`][].
- Moved individual buffer functions in `io` into `buffer`.
- Event handlers can now return any non-`nil` value instead of a boolean value and have that
  value passed back to `events.emit()`.
- Lua command entry completions show images just like in Lua autocompletion.
- Align block comments by column if possible, not indent.
- Added per-mode command entry history which can be cycled through using the `Up` and `Down` keys.
- Added [`ui.dialogs.progressbar()`][], utilize it with Find in Files, and removed
  `ui.find.find_in_files_timeout`.
- GUI find/replace history Up/Down history key bindings swapped, mimicking traditional command
  line history navigation.
- The statusbar now indicates an active snippet.
- Updated to [PDCurses][] 3.9.
- Experimental set of "standard" modules is provided in the modules archive instead of just
  language modules.

[Textadept 11.0 alpha -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha/textadept_11.0_alpha.win32.zip
[Textadept 11.0 alpha -- Mac OSX 10.6+]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha/textadept_11.0_alpha.osx.zip
[Textadept 11.0 alpha -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha/textadept_11.0_alpha.i386.tgz
[Textadept 11.0 alpha -- Linux x86_64]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha/textadept_11.0_alpha.x86_64.tgz
[Textadept 11.0 alpha -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_11.0_alpha/textadept_11.0_alpha.modules.zip
[`buffer:name_of_style()`]: api.html#buffer.name_of_style
[`events.SESSION_SAVE`]: api.html#events.SESSION_SAVE
[`events.SESSION_LOAD`]: api.html#events.SESSION_LOAD
[`keys.mode`]: api.html#keys.mode
[`ui.dialogs.progressbar()`]: api.html#ui.dialogs.progress
[PDCurses]: https://pdcurses.sourceforge.io/

### 10.8 (01 Jan 2020)

Download:

- [Textadept 10.8 -- Win32][]
- [Textadept 10.8 -- Mac OSX 10.6+][]
- [Textadept 10.8 -- Linux][]
- [Textadept 10.8 -- Modules][]

Bugfixes:

- Fixed incorrect event arguments for `events.AUTO_C_SELECTION_CHANGE`.
- Fixed bug in "Replace All in selection" with match at the end of a selection.
- Fixed long line output for run, compile, and build commands.

Changes:

- Changed [`events.TAB_CLICKED`][] to emit button clicked as well as modifier keys.
- Autocompletion and documentation for Textadept's Lua API only happens in Textadept files now
  (i.e. files in `_HOME` and `_USERHOME`).
- `textadept.editing.api_files` and `_M.lua.tags` can contain functions that return file paths.
- Added support for txt2tags.
- Scintilla: Added access to virtual space at the start and end of multiple selections.
- Scintilla: The target can have virtual space.
- Updated to [Scintilla][] 3.11.2.

[Textadept 10.8 -- Win32]: https://github.com/orbitalquark/textadept/releases/download/textadept_10.8/textadept_10.8.win32.zip
[Textadept 10.8 -- Mac OSX 10.6+]: https://github.com/orbitalquark/textadept/releases/download/textadept_10.8/textadept_10.8.macOS.zip
[Textadept 10.8 -- Linux]: https://github.com/orbitalquark/textadept/releases/download/textadept_10.8/textadept_10.8.linux.tgz
[Textadept 10.8 -- Modules]: https://github.com/orbitalquark/textadept/releases/download/textadept_10.8/textadept_10.8.modules.zip
[`events.TAB_CLICKED`]: api.html#events.TAB_CLICKED
[Scintilla]: https://scintilla.org

### 10.7 (01 Nov 2019)

Bugfixes:

- Fixed scroll issues when toggling line wrap.
- Properly handle absolute paths in run/compile/build output and also case-insensitivity
  on Windows.
- Restore virtual space state when switching between buffers.
- Restore rectangular selection state when switching between buffers.
- Fixed opening of non-UTF-8-encoded filenames dropped into a view.
- Fixed macro toggling with some key combinations.
- Ensure `events.BUFFER_AFTER_SWITCH` is emitted properly during `buffer.new()`.
- Prevent double-counting fold points on a single line.

Changes:

- Refactored "Replace All" to be more performant.
- Added back [`textadept.editing.paste_reindent()`][] as a separate menu/key/command from
  `buffer.paste()`.
- Enabled all theme colors by default, and changed line number color in the terminal version.
- Replaced `ui.command_entry.enter_mode()` and `ui.command_entry.finish_mode()` with simplified
  [`ui.command_entry.run()`][].
- Added `ui.find.find_incremental_keys` table of key bindings during "Find Incremental" searches.
- Replaced `textadept.macros.start_recording()` and `textadept.macros.stop_recording()` with
  [`textadept.macros.record()`][].
- Updated C, Rust, Prolog, and Logtalk lexers.
- Added MediaWiki lexer.
- Scintilla: Updated case conversion and character categories to Unicode 12.1.
- Updated to [Scintilla][] 3.11.1.

[Scintilla]: https://scintilla.org
[`textadept.editing.paste_reindent()`]: api.html#textadept.editing.paste_reindent
[`ui.command_entry.run()`]: api.html#ui.command_entry.run
[`textadept.macros.record()`]: api.html#textadept.macros.record

### 10.6 (01 Sep 2019)

Bugfixes:

- Fail more gracefully when users attempt to create buffers on init.
- Improve caret sticky behavior when switching between buffers.
- Do not auto-indent when pressing enter at the start of a non-empty line.
- Scintilla: Fix deletion of isolated invalid bytes.
- Scintilla: Fix position of line caret when overstrike caret is set to block.

Changes:

- Use CP1252 encoding instead of ISO-8859-1.
- Added support for ksh and mksh.
- Updated to [Scintilla][] 3.11.0.

[Scintilla]: https://scintilla.org

### 10.5 (01 Jul 2019)

Bugfixes:

- Do not advance the caret on failed incremental find.
- Fixed bug with filters that have extension includes and pattern excludes.

Changes:

- Added case-insensitive option to `textadept.editing.show_documentation()`.
- Updated the default window size and some default dialog sizes.
- Updated Markdown lexer.
- Improved C++ lexer to support single quotes in C++14 integer literals.
- Scintilla: Improved performance opening and closing large files with fold points.
- Scintilla: Tweaked behavior of `buffer.style_case`'s `buffer.CASE_CAMEL` option to treat only
  letters as word characters.
- Updated to [Scintilla][] 3.10.6.

[Scintilla]: https://scintilla.org

### 10.4 (01 May 2019)

Bugfixes:

- Fixed scrolling found text into view on long lines.
- Fixed crash on Mac with malformed regex patterns.

Changes:

- Recognize `.vue` and `.yml` file extensions.
- Line number margin grows for large files as needed.
- Do not emit `events.SAVE_POINT_LEFT` event for unfocused views.
- Updated CSS lexer to support CSS3.
- Updated YAML lexer.
- Updated to [Scintilla][] 3.10.4.
- Updated to [LuaFileSystem][] 1.7.0 and [LPeg][] 1.0.2.

[Scintilla]: https://scintilla.org
[LuaFileSystem]: https://keplerproject.github.io/luafilesystem/
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/

### 10.3 (01 Mar 2019)

Bugfixes:

- Fixed block comment support for Nim.
- Fixed escaping of newlines (`\n`) in Lua and C API documentation.

Changes:

- Version control markers like `.git` are not limited to directories.
- Allow redefinition of `WGET` in Makefile for
- Updated to [Scintilla][] 3.10.2.

[Scintilla]: https://scintilla.org

### 10.3 beta (01 Jan 2019)

Bugfixes:

- Ensure `Esc` clears highlighted words.
- Fixed behavior of `Home` and `Shift+Home` keys on non-OSX platforms.
- Fixed some instances of snippet next/prev not working correctly.
- Fixed Alt+Gr key handling in the Windows terminal version.
- Only pass command entry text to function passed to `ui.command_entry.finish_mode()`.
- Fixed handling of escaped double-quotes in `os.spawn()` in the terminal version.
- Ensure long filenames are visible in the reload dialog prompt in the terminal version.

Changes:

- Added optional position argument to `textadept.editing.show_documentation()`.
- `textadept.editing.highlight_word()` does not select the word by default anymore.
- Changed [file filter][] format to be more flat and intuitive.
- Added `-l` and `--line` command line options to go to a buffer line.
- Updated to [PDCurses][] 3.6 for the Windows terminal version.

[file filter]: api.html#io.quick_open
[PDCurses]: https://pdcurses.sourceforge.io/

### 10.2 (01 Nov 2018)

Bugfixes:

- Fixed error when performing "select enclosed" on a non-ASCII character.
- Fixed regression of Retina display support of Mac OSX.
- Fixed key handling on some international keyboards.
- Fixed tab labels not updating when loading message buffers from a session.
- Fixed potential crashes in `string.iconv()` with tiny strings.
- Fixed inability to resize one split view configuration with the mouse in the terminal version.

Changes:

- Renamed `spawn()` to [`os.spawn()`][].
- `os.spawn()` now allows omission of `cwd` and `env` parameters.
- `spawn_proc:wait()` returns the process' exit code.
- `textadept.editing.filter_through()` halts on non-zero status instead of clobbering the buffer
  or selected text.
- Removed `textadept.editing.paste()` and `textadept.editing.paste_reindents` option; Textadept
  no longer reindents pasted text by default.
- Experimentally added [`textadept.macros`][] module for recording, playing, saving, and loading
  keyboard macros.
- Scintilla: Improve efficiency of idle wrapping.
- Scintilla: Updated case conversion and character categories to Unicode 11.
- Scintilla: Updated ConTeXt, HTML, and Markdown lexers.
- Updated to [Scintilla][] 3.10.1.

[`os.spawn()`]: api.html#os.spawn
[`textadept.macros`]: api.html#textadept.macros
[Scintilla]: https://scintilla.org

### 10.1 (01 Oct 2018)

Bugfixes:

- Fixed view focus synchronization issues when dropping files into split views.
- Fixed potential crash with non-UTF-8 bytes copy-pasted into non-UTF-8 buffer.
- `spawn_proc:read()` correctly handles `\r\n` sequences.

Changes:

- Added ability to save/restore persistent data during a reset event via [`events.RESET_BEFORE`][]
  and [`events.RESET_AFTER`][].
- Replaced `ui.find.find_in_files_filter` with [`ui.find.find_in_files_filters`][] table for
  project-specific filters.
- Added Chinese localization.
- Updated to GTK 2.24.32 on Windows, which fixes a number of various GTK-related issues.

[`events.RESET_BEFORE`]: api.html#events.RESET_BEFORE
[`events.RESET_AFTER`]: api.html#events.RESET_AFTER
[`ui.find.find_in_files_filters`]: api.html#ui.find.find_in_files_filters

### 10.0 (01 Aug 2018)

Please see the [9 to 10 migration guide][] for upgrading from Textadept 9 to Textadept 10.

Bugfixes:

- Fixed markdown lexer lists and C# lexer keywords.
- Fixed child lexers that embed themselves into parents and fixed proxy lexers.
- Fixed handling of custom fold functions in legacy lexers.
- Fixed `buffer:set_theme()` for lexers that have their own styles.
- Scintilla: Fixed potential crash with newer versions of ncurses.
- Scintilla: Fixed some regex searching corner-cases.

Changes:

- Updated German localization.
- Scintilla: Added new `buffer.INDIC_GRADIENT` and `buffer.INDIC_GRADIENTCENTRE` indicators.
- Scintilla: Added `buffer.WRAPINDENT_DEEPINDENT` line wrapping option.
- Updated to [Scintilla][] 3.10.0.
- Updated to [Lua][] 5.3.5.

[9 to 10 migration guide]: manual.html#textadept-9-to-10
[Scintilla]: https://scintilla.org
[Lua]: https://lua.org

### 10.0 beta 2 (01 Jun 2018)

Bugfixes:

- Fixed unset lexer bug upon splitting a newly created buffer.
- Fixed a potential infinite loop with "replace in selection".
- Fixed crash on Mac OSX with regex searches.
- Fixed selection of "find in files" result if it's at the start of the line.
- Properly handle abbreviated setting of write-only buffer properties via command entry.

Changes:

- Removed `bit32` module in favor of Lua's bitwise operators.
- Makefile can be used to build on case-insensitive filesystems.
- Interpret `\uXXXX` sequences in regex replacement text.

### 10.0 beta (01 May 2018)

Bugfixes:

- Fixed incorrect style settings when splitting views.
- Fixed restoration of vertical scroll for buffers with different line heights.
- Fixed potential crash in terminal version with newer versions of ncurses.

Changes:

- Change SQL comments to use `--` instead of `#`.
- Updated Textadept icon.
- Minimum required Mac OSX version is now 10.6 (Snow Leopard) or higher.
- Removed LuaJIT version of Textadept.

### 10.0 alpha 3 (01 Apr 2018)

Bugfixes:

- Fixed hang in the terminal version on Windows.
- Fixed accidental stripping of leading newlines in pasted text.
- Fixed initialization errors not showing in the terminal version.

Changes:

- Textadept requires GCC 4.9 (circa early-2014) or later to _compile_ (not run).
- C++11 regex replaces old TRE library.
- Scintillua and Scinterm were merged into Scintilla and are no longer dependencies.
- Emacs-style `^K` for OSX and the terminal version joins lines at EOL.
- Pasted text reindents an extra level after a fold header.
- `buffer.set_theme()` now takes an initial buffer argument like all other buffer functions
  and does not have any call restrictions.
- Scintilla: Added [`events.AUTO_C_SELECTION_CHANGE`][] event.
- Updated to [Scintilla][] 3.8.0.

[`events.AUTO_C_SELECTION_CHANGE`]: api.html#events.AUTO_C_SELECTION_CHANGE
[Scintilla]: https://scintilla.org

### 10.0 alpha 2 (01 Mar 2018)

Bugfixes:

- Fixed clang build warnings/errors regarding LuaJIT.
- Fixed busy wait in second instance of Textadept on Windows.
- Fixed bug in remote-controlled Textadept when no arguments were initially given.
- Fixed session loading when only it is provided as a command line argument.
- Fixed copy-paste between views in the terminal version.
- Fixed crash when attempting to show a badly-encoded filename in the titlebar.
- Scintilla: Fixed double-click word selection on Windows 10.
- Scintilla: Fixed rectangular and line modal selection movements.

Changes:

- Added `fold.compact` buffer property.
- Added [`buffer.move_extends_selection`][] for enhanced modal keyboard movement.
- Auto-detect UTF-16-encoded files automatically.
- Save to the loaded session on quit and removed the `textadept.session.default_session` option.
- Various Makefile improvements.
- The terminal version can immediately focus on a clicked split view.
- Textadept only minimally supports GTK3 now -- it still compiles, but deprecated function
  calls have not been, and will not be migrated.
- The terminal key sequence for `Ctrl+Space` is now `'c '` instead of `'c@'`.
- The terminal version can now remap `^H` (which was previously locked to
  `Backspace`).

[`buffer.move_extends_selection`]: api.html#buffer.move_extends_selection

### 10.0 alpha (01 Jan 2018)

Bugfixes:

- Scintilla: Fixed a couple of wrapped line drawing cases.
- Scintilla: Ensure overtype caret is drawn when manually set.
- Scintilla: Fixed some instances of incorrect scrollbar drawing and flickering.
- Scintilla: Fixed line selection when clicking in the margin when scrolled.

Changes:

- Textadept requires GTK 2.24 (circa early-2011) or greater.
- Pasted text is reindented by default via `textadept.editing.paste()`, and is configured with
  `textadept.editing.paste_reindents`.
- Replaced `textadept.editing.match_brace()` with a menu function, enhanced
  `textadept.editing.select_enclosed()` behavior, and removed redundant "Select in ..." menu items.
- Removed the need for *~/.textadept/properties.lua*. All `buffer` settings set in
  *~/.textadept/init.lua* will apply to the first and subsequent buffers.
- Renamed `ui.set_theme()` to `buffer.set_theme()`.
- Enforce extra argument to [`buffer:brace_match()`][] added back in Scintilla 3.7.0.
- Added [`events.ZOOM`][].
- New, object-oriented way to [create lexers][].

[`buffer:brace_match()`]: api.html#buffer.brace_match
[`events.ZOOM`]: api.html#events.ZOOM
[create lexers]: api.html#lexer

### 9.6 (01 Nov 2017)

Bugfixes:

- Regular expressions consider `\r` to be a newline character.
- Fixed block comments for APDL.

Changes:

- Scintilla: Block caret appears after selection end instead of on it. (Reverts change from
  Textadept 9.3)

### 9.5 (01 Sep 2017)

Bugfixes:

- Do not attempt to provide code completions when there is no context.
- Properly handle `buffer.margin_left` and `buffer.margin_right`.
- Ensure context menus are configurable outside of `events.INITIALIZE`.
- Various fixes in diff, Forth, and Elixir lexers.
- Character transposing is now UTF-8-aware.

Changes:

- Added z-order parameter to [`ui.switch_buffer()`][].
- When searching in files, show more lines below a match.
- Added optional encoding parameter to [`io.open_file()`][].
- Improved file associations on Mac OSX.
- Added support for Myrddin.
- The terminal version updates its cursor position for display in tools like tmux.

[`ui.switch_buffer()`]: api.html#ui.switch_buffer
[`io.open_file()`]: api.html#io.open_file

### 9.5 beta (01 Jul 2017)

Bugfixes:

- Fixed bug that deleted characters outside of mangled snippets.
- Fixed start-anchored "Find Prev" regex searches.
- Correctly handle multiple '!'-prefixed patterns in file filters.
- Scintilla: Pressing `Esc` while rectangular selection is active does not collapse it.

Changes:

- Changed "Cancel Snippet" key binding from `Ctrl+Shift+K` (`⌥⇧⇥` on Mac OSX | `M-S-K`
  in curses) to `Esc`.
- Added [`buffer.caret_line_frame`][] option for outlining the current line.
- Added [`buffer:line_reverse()`][] for reversing selected lines.
- Added `ui.dialogs.colorselect()` and `ui.dialogs.fontselect()` dialogs.
- Handle pipes in shell commands for [filter-through][].
- The [Lua command entry][] prints results like Lua 5.3's interactive prompt (e.g. no need for
  explicit '=' prefix).
- The Lua command entry now invokes bare functions as commands (e.g. `copy` invokes
  `buffer:copy()`, `split` invokes `view:split()`, etc.).
- Scintilla: Updated case conversion and character categories to Unicode 9.
- Scintilla: Update scroll bar when annotations are added, removed, or changed.
- Effectively updated to [Scintilla][] 3.7.5.

[`buffer.caret_line_frame`]: api.html#buffer.caret_line_frame
[`buffer:line_reverse()`]: api.html#buffer.line_reverse
[filter-through]: manual.html#shell-commands-and-filtering-text
[Lua command entry]: manual.html#lua-command-entry
[Scintilla]: https://scintilla.org

### 9.4 (01 May 2017)

Bugfixes:

- Fixed some C++ and Moonscript file associations.
- Fixed some bugs in "Replace All".
- Fixed some instances of snippet insertion with selected text.
- Fixed `make install` for desktop files and icons.
- Scintilla: Fixed crash in edge-case for fold tags (text shown next to folds).
- Scintilla: Fixed stream selection collapsing when caret is moved up/down.
- Scintilla: Fixed bugs in fold tag drawing.
- Scintilla: Fixed crash in GTK accessibility (for screen readers) code.
- Scintilla: Only allow smooth scrolling in Wayland.
- Scintilla: Fixed popup positioning on a multi-monitor setup.

Changes:

- Added support for Logtalk.
- Scintilla: Accessibility improvements including the ability to turn it off.
- Effectively updated to [Scintilla][] 3.7.4.

[Scintilla]: https://scintilla.org

### 9.3 (01 Mar 2017)

Bugfixes:

- Improved LuaJIT compatibility with 3rd-party modules.
- Do not move over selected typeover characters.
- Fixed "Match Case" toggling during "Regex" searches.
- Fixed building from the source when dependencies are updated.
- Fixed folding in multiple-language lexers.
- Fixed accidental editing of cached lexers.
- Scintilla: Minimize redrawing for `buffer.selection_n_*` settings.
- Scintilla: Fixed individual line selection in files with more than 16.7 million lines.
- Scintilla: Various accessibility fixes for GTK on Linux.
- Scintilla: Fixed a couple of folding regressions.
- Scintilla: Fixed various issues on GTK 3.22.
- Scintilla: Fixed inability to extend selection up or down in stream selection mode.

Changes:

- Lexer initialization errors are printed to the Message Buffer.
- Updated Polish locale.
- Updated C, C++, Scheme, Shell, and JavaScript lexers.
- Added support for rc and Standard ML.
- Scintilla: Block caret appears on selection end instead of after it.
- Updated to [Scintilla][] 3.7.3.
- Updated to [Lua][] 5.3.4.

[Scintilla]: https://scintilla.org
[Lua]: https://lua.org

### 9.2 (21 Dec 2016)

Bugfixes:

- Scintilla: Fixed crash when destroying Scintilla objects.

Changes:

- None.

### 9.1 (11 Dec 2016)

Bugfixes:

- Fixed bug in find/replace with consecutive matches.
- Fixed encoding detection for encodings with NUL bytes (e.g. UTF-16).
- Fixed duplicate entries in `io.recent_files` when loading sessions.
- Scintilla: Fixed caret placement after left or right movement with rectangular selection.
- Scintilla: Fixed GTK 3 incorrect font size in autocompletion list.
- Scintilla: Fixed various minor GTK bugs.

Changes:

- Added support for Protobuf and Crystal.
- On Linux systems that support it, `make install` installs `.desktop` files too.
- Removed MacRoman encoding detection and options.
- Scintilla: Character-based word selection, navigation, and manipulation.
- Scintilla: Added [`view.EDGE_MULTILINE`][], [`view:multi_edge_add_line()`][], and
  [`view:multi_edge_clear_all()`][] for multiple edge lines.
- Scintilla: Added `buffer.MARGIN_COLOUR` and [`buffer.margin_back_n`][] for setting arbitrary
  margin background colors.
- Scintilla: Added [`buffer.margins`][] for more margins.
- Scintilla: Added accessibility support for GTK on Linux.
- Scintilla: Added [`buffer:toggle_fold_display_text()`][] and [`buffer.fold_display_text_style`][]
  for showing text next to folded lines.
- Scintilla: Added new `buffer.INDIC_POINT` and `buffer.INDIC_POINTCHARACTER` indicators.
- Scintilla: Added [`buffer.tab_draw_mode`][] for changing the appearance of visible tabs.
- Scintilla: Margin click line selection clears rectangular and multiple selection.
- Updated to [Scintilla][] 3.7.1.

[`view.EDGE_MULTILINE`]: api.html#view.EDGE_MULTILINE
[`view:multi_edge_add_line()`]: api.html#view.multi_edge_add_line
[`view:multi_edge_clear_all()`]: api.html#view.multi_edge_clear_all
[`buffer.margin_back_n`]: api.html#buffer.margin_back_n
[`buffer.margins`]: api.html#buffer.margins
[`buffer:toggle_fold_display_text()`]: api.html#buffer.toggle_fold_display_text
[`buffer.fold_display_text_style`]: api.html#buffer.fold_display_text_style
[`buffer.tab_draw_mode`]: api.html#buffer.tab_draw_mode
[Scintilla]: https://scintilla.org

### 9.0 (01 Oct 2016)

Please see the [8 to 9 migration guide][] for upgrading from Textadept 8 to Textadept 9.

Bugfixes:

- Better error handling with "filter-through".
- Fixed error in building projects.
- Better handling of key bindings on international keyboards.
- Scintilla: Respect indentation settings when inserting indentation within virtual space.
- Scintilla: Fixed bug with expanding folds.
- Scintilla: Fix GTK 3 runtime warning.

Changes:

- Added TaskPaper lexer.
- Scintilla: Added `buffer.VS_NOWRAPLINESTART` option to `buffer.virtual_space_options`.
- Updated to [Scintilla][] 3.6.7.

[8 to 9 migration guide]: manual.html#textadept-8-to-9
[Scintilla]: https://scintilla.org

### 9.0 beta (01 Sep 2016)

Bugfixes:

- Fixed potential bug with `events.disconnect()`.
- Fixed potential infinite loop with "Replace All" in selection.
- Fixed passing of quoted arguments to OSX `ta` script.
- Fixed CapsLock key handling.
- Fixed button order in the terminal version's dialogs.
- Fixed potential crash on Windows with `textadept.editing.filter_through()` and some locales.
- Fixed infinite loop in "Replace All" with zero-length regex matches.

Changes:

- Added [`events.TAB_CLICKED`][] event.

[`events.TAB_CLICKED`]: api.html#events.TAB_CLICKED

### 9.0 alpha 2 (11 Jul 2016)

Bugfixes:

- Check range bounds for `buffer:text_range()`.
- Fixed inability to properly halt `lfs.dir_foreach()`.

Changes:

- Replaced Lua pattern searches with [regular expressions][].
- Added timeout prompt to Find in Files. (10 second default.)
- Better differentiation between Python 2 and 3 run commands.

[regular expressions]: manual.html#regular-expressions

### 9.0 alpha (01 Jul 2016)

Bugfixes:

- Fixed stack overflow when accessing `nil` keys in `textadept.menu`.
- Fixed inability to re-encode files incorrectly detected as binary.
- Scintilla: Fixed crash when idle styling is active upon closing Textadept.
- Scintilla: Fixed various bugs on GTK 3.20.
- Lua: Fixed potential crash with four or more expressions in a `for` loop.

Changes:

- Renamed `io.snapopen()` to [`io.quick_open()`][] and tweaked its arguments, renamed
  `io.SNAPOPEN_MAX` to [`io.quick_open_max`][], and renamed `io.snapopen_filters` to
  [`io.quick_open_filters`][].
- Removed BOM (byte order mark) encoding detection. (BOM use is legacy and discouraged.)
- Removed detection and use of extinct `\r` (CR) line endings.
- Removed project support for CVS and assume Subversion v1.8+.
- Key and menu commands [must be Lua functions][]; the table syntax is no longer recognized.
- Renamed `lfs.FILTER` to [`lfs.default_filter`][] and tweaked arguments to `lfs.dir_foreach()`.
- Locale files can optionally use `#` for comments instead of `%`.
- Renamed `ui.SILENT_PRINT` to `ui.silent_print`.
- Renamed all [`textadept.editing`][]`.[A-Z]+` options to their lower-case equivalents and
  renamed `textadept.editing.braces` to `textadept.editing.brace_matches`.
- *post_init.lua* files for language modules are [no longer auto-loaded][]; use
  [`events.LEXER_LOADED`][] to load additional bits instead.
- Renamed `ui.find.FILTER` to [`ui.find.find_in_files_filter`][] and added an optional argument
  to [`ui.find.find_in_files()`][].
- Renamed all [`textadept.session`][]`.[A-Z]+` options to their lower-case equivalents.
- Removed syntax checking support, renamed `textadept.run.RUN_IN_BACKGROUND` to
  [`textadept.run.run_in_background`][], removed `textadept.run.cwd` and `textadept.run.proc`,
  added optional arguments to [`textadept.run.compile()`][], [`textadept.run.run()`][], and
  [`textadept.run.build()`][], and changed the format of `textadept.run.error_patterns`.
- Rewrote sections 7-9 in the [manual][] and added a new part to section 11. Understanding how
  to configure and script Textadept should be easier now.
- `textadept.editing.goto_line()` takes a 0-based line number like all Scintilla functions.
- `ui.goto_view()` and `view:goto_buffer()` now take actual `view` and `buffer` arguments,
  respectively, or a relative number.
- Added [file-based snippet][] capabilities.
- Updated to [Scintilla][] 3.6.6.
- Updated to [Lua][] 5.3.3

[`io.quick_open()`]: api.html#io.quick_open
[`io.quick_open_max`]: api.html#io.quick_open_max
[`io.quick_open_filters`]: api.html#io.quick_open_filters
[must be Lua functions]: manual.html#key-and-menu-command-changes
[`lfs.default_filter`]: api.html#lfs.default_filter
[`textadept.editing`]: api.html#textadept.editing
[no longer auto-loaded]: manual.html#language-module-handling-changes
[`events.LEXER_LOADED`]: api.html#events.LEXER_LOADED
[`ui.find.find_in_files_filter`]: api.html#ui.find.find_in_files_filter
[`ui.find.find_in_files()`]: api.html#ui.find.find_in_files
[`textadept.session`]: api.html#textadept.session
[`textadept.run.run_in_background`]: api.html#textadept.run.run_in_background
[`textadept.run.compile()`]: api.html#textadept.run.compile
[`textadept.run.run()`]: api.html#textadept.run.run
[`textadept.run.build()`]: api.html#textadept.run.build
[manual]: manual.html
[file-based snippet]: manual.html#snippet-preferences
[Scintilla]: https://scintilla.org
[Lua]: https://www.lua.org

### 8.7 (01 May 2016)

Bugfixes:

- Much better UTF-8 support in the terminal version.
- Completely hide the menubar if it is empty.
- Fix building for some BSDs.
- Added some block comment strings for languages lacking them.
- Fixed a number of small encoding issues in various corner cases.
- Fixed bug in `textadept.editing.convert_indentation()` with mixed indentation.
- Fixed an obscure side-effect that reset buffer properties when working with non-focused buffers.
- Fixed incremental find with UTF-8 characters.
- Fixed bug in session restoration of scroll and caret positions in multiple views.
- Fixed bug where existing files were not closed when a session is loaded.
- Fixed corner case in "replace within selection".
- Fixed regression for `%<...>` and `%[...]` in snippets.
- When executing compile/run commands from a different directory, indicate it.
- Fixed error when showing style popup at the end of a buffer.
- "Find in Files" should not print the contents of binary files.
- Fixed lack of environment in spawned processes on Linux.
- Scintilla: Support longer regexes in searches.

Changes:

- Support UTF-8 pattern matching in "Lua Pattern" searches by incorporating bits of [luautf8][].
- Improved efficiency of autocompleting words from all open buffers.
- "Find in Files" defaults to the current project's root directory.
- Submenus and menu items can be accessed by name. (See [`textadept.menu.menubar`][] for an
  example.)
- Only show snippet trigger and text when selecting from a dialog.
- More efficient screen refreshes in the terminal version.
- Save and restore horizontal scroll position when switching buffers.
- The undocumented `keys.utils` was removed. This will break custom key bindings that depend
  on it. See [this mailing list post][] for more information.
- The menubar is loaded on `events.INITIALIZED` now. See the above mailing list post for more
  information.
- Allow file-specific [compile commands][] and [run commands][].
- Added new dialog for specifying compile/run command arguments to "Tools" menu.
- `textadept.editing.enclose()` works with multiple selections.
- Disabled `textadept.run.CHECK_SYNTAX` by default.
- Updated to lspawn 1.5.
- Updated to [Scintilla][] 3.6.5.
- Updated to Scinterm 1.8.

[luautf8]: https://github.com/starwing/luautf8
[`textadept.menu.menubar`]: api.html#textadept.menu.menubar
[this mailing list post]: https://foicica.com/lists/code/201604/3171.html
[compile commands]: api.html#textadept.run.compile_commands
[run commands]: api.html#textadept.run.run_commands
[Scintilla]: https://scintilla.org

### 8.6 (01 Mar 2016)

Bugfixes:

- Prevent silent crash reports from being generated on Mac OSX when child processes fail to
  be spawned.
- Do not "busy wait" for spawned process stdout or stderr on Mac OSX.
- Fixed bug in escaping `([{<` after mirrors in snippets.
- Only change spawned process environment if one was specified on Mac OSX.
- Fixed focus bug in `view:goto_buffer()` with non-focused view.
- Fixed building the terminal version in debug mode.
- Fixed potential crash with malformed style properties.
- Fixed unlikely buffer overflow in messages coming from Scintilla.
- Fixed potential memory access error when closing Textadept while a spawned process is still
  alive.
- Fixed bug in setting view properties when restoring sessions with nested splits.

Changes:

- Added support for APL, Docker, Faust, Ledger, MoonScript, man/roff, PICO-8, and Pure.
- Enabled idle-styling of buffers in the background in the GUI version.
- Undocumented `buffer:clear_cmd_key()` only takes one argument now.
- Added `-v` and `--version` command line parameters.
- Added single-instance functionality on Windows.
- Require GLib 2.28+.
- Recognize the `weight` [style property][].
- Added [`lexer.line_state`][] and [`lexer.line_from_position()`][] for [stateful lexers][].
- Updated to lspawn 1.4.
- Updated to [Scintilla][] 3.6.3.
- Updated to Scinterm 1.7.

[style property]: api.html#styles-and-styling
[`lexer.line_state`]: api.html#lexer.line_state
[`lexer.line_from_position()`]: api.html#lexer.line_from_position
[stateful lexers]: api.html#lexers-with-complex-state
[Scintilla]: https://scintilla.org

### 8.5 (01 Jan 2016)

Bugfixes:

- Fixed some '%' escape sequences in snippets.
- Fixed bug resolving relative paths with multiple '../' components.
- Do not visit buffers that do not need saving in `io.save_all_files()`.
- Fixed various small bugs in snippets.
- Fixed restoration of split view sizes in large windows.
- Lua: Fixed potential crash in `io.lines()` with too many arguments.

Changes:

- Allow [compile, run, and build commands][] functions to specify a working directory.
- Added support for SNOBOL4.
- Added support for Icon.
- Added support for AutoIt.
- Updated to [Lua][] 5.3.2.

[compile, run, and build commands]: api.html#textadept.run.build_commands
[Lua]: https://www.lua.org

### 8.4 (11 Nov 2015)

Bugfixes:

- Various fixes for snippet bugs introduced in the refactoring.
- Fixed `S-Tab` in Find & Replace pane in the terminal version.
- Do not error when attempting to snapopen a non-existant project.
- Scintilla: fixed height of lines in autocompletion lists.
- Scintilla: fixed bug in `buffer:line_end_display()`.

Changes:

- Bookmarks are saved in sessions.
- New snippet placeholder for a list of options (`%`_`n`_`{`_`list`_`}`).
- Snippets can now be functions that return snippet text.
- Added Lua API tags to the "ansi\_c" module.
- Updated Swedish translation.
- Added support for Gherkin.
- Scintilla: whitespace can be shown only in indentation.
- Scintilla: optimized marker redrawing.
- Updated to [Scintilla][] 3.6.2.
- Updated to [LPeg][] 1.0.

[Scintilla]: https://scintilla.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/

### 8.3 (01 Oct 2015)

Bugfixes:

- Stop annoying black box from flashing when saving some files on Windows.
- Fixed bug in parsing Ruby error output.
- Do not emit `events.LEXER_LOADED` for the command entry.
- Fixed bug with Python syntax checking on Windows.
- Scintilla: fixed bug in `buffer:count_characters()`.
- Scintilla: small GTK fixes.

Changes:

- Improved API documentation lookup behind the caret.
- [Refactored snippets][] to longer display placeholder text.
- [`os.spawn()`][] can now optionally specify the child's environment.
- Added Gherkin lexer.
- Updated to [Scintilla][] 3.6.1.

[Refactored snippets]: https://foicica.com/lists/code/201509/2687.html
[`os.spawn()`]: api.html#os.spawn
[Scintilla]: https://scintilla.org

### 8.2 (01 Sep 2015)

Bugfixes:

- Fixed crash when quitting while the command entry is open.
- Block commenting respects indentation levels.
- Handle `typeref` in ansi\_c module's ctags support.
- Do not error when block commenting in an unsupported language.
- Scintilla: fix scrollbar memory leaks.

Changes:

- Highlight found text in "Find in Files" searches.
- Added Italian translation and updated French translation.
- Added automatic syntax checking as source files are saved, along with
  `textadept.run.CHECK_SYNTAX` and `textadept.run.GOTO_SYNTAX_ERRORS` configuration fields.
- Scintilla: multiple selection works over more key commands like caret movement, selections,
  and word and line deletions.
- Scintilla: new [`events.AUTO_C_COMPLETED`][] event for when autocompleted text has been inserted.
- Updated to [Scintilla][] 3.6.0.

[`events.AUTO_C_COMPLETED`]: api.html#events.AUTO_C_COMPLETED
[Scintilla]: https://scintilla.org

### 8.1 (01 Jul 2015)

Bugfixes:

- Detect `#!/usr/bin/env ...` properly.
- Fix incorrect menu shortcut key display on Windows.
- Fixed ASP, Applescript, and Perl lexers.
- Fixed segfault in parsing some instances of style definitions.
- Scintilla: fixed performance when deleting markers from many lines.
- Scintilla: fixed scrollbar drawing on GTK 3.4+.
- Scintilla: respect encoding for margin text.

Changes:

- Added support for Elixir and Windows Script Files (WSF).
- Added parameter to [`textadept.editing.select_word()`][] for selecting all occurrences.
- Scintilla: added [`buffer:multiple_select_add_next()`][] and
  [`buffer:multiple_select_add_each()`][] for creating multiple selections from selected text.
- Scintilla: added [`buffer:is_range_word()`][] and [`buffer:target_whole_document()`][] helper
  functions for search and replace.
- Updated to [Scintilla][] 3.5.7.
- Updated to [Lua][] 5.3.1.

[`textadept.editing.select_word()`]: api.html#textadept.editing.select_word
[`buffer:multiple_select_add_next()`]: api.html#buffer.multiple_select_add_next
[`buffer:multiple_select_add_each()`]: api.html#buffer.multiple_select_add_each
[`buffer:is_range_word()`]: api.html#buffer.is_range_word
[`buffer:target_whole_document()`]: api.html#buffer.target_whole_document
[Scintilla]: https://scintilla.org
[Lua]: https://lua.org

### 8.0 (01 May 2015)

Please see the [7 to 8 migration guide][] for upgrading from Textadept 7 to Textadept 8.

Bugfixes:

- Fixed filename encoding issues on Windows.

Changes:

- Added [`textadept.run.RUN_IN_BACKGROUND`][] for shell commands.

[7 to 8 migration guide]: manual.html#textadept-7-to-8
[`textadept.run.RUN_IN_BACKGROUND`]: api.html#textadept.run.run_in_background

### 8.0 beta (21 Apr 2015)

Bugfixes:

- Fixed `require()` bug with lfs and utf8 libraries in LuaJIT version.
- Fixed Perl lexer corner-case.
- VB lexer keywords are case-insensitive now.

Changes:

- Added `symlink` filter option for ignoring symlinked files and folders to [`io.snapopen()`][],
  `lfs.dir_foreach()`, and [`ui.find.FILTER`][].
- Added [`_FOLDBYINDENTATION`][] field for lexers that fold by indentation.
- Updated to [Scintilla][] 3.5.5.

[`io.snapopen()`]: api.html#io.quick_open
[`ui.find.FILTER`]: api.html#ui.find.find_in_files_filter
[`_FOLDBYINDENTATION`]: api.html#fold-by-indentation
[Scintilla]: https://scintilla.org

### 8.0 alpha (01 Apr 2015)

Bugfixes:

- Ensure `events.BUFFER_AFTER_SWITCH` is fired before `events.BUFFER_DELETED`.
- Prevent command line help options from exiting an open instance of Textadept.

Changes:

- Upgraded to Lua 5.3, LPeg 0.12.2, lfs 1.6.3, and lspawn 1.2.
- Removed `keys.LANGUAGE_MODULE_PREFIX`, but left that prefix unused on all platforms.
- `textadept.editing.filter_through()` now uses `os.spawn()`.
- Removed long-hand [compile and run macros][] in favor of shorter ones.
- [`textadept.bookmarks.toggle()`][] accepts an optional line to bookmark.
- Added support for Rust and TOML.
- "Go To Bookmark" now lists bookmarks in all open buffers.
- [`spawn_proc:kill()`][] can send signals to processes.
- New [`lexer._FOLDBYINDENTATION`][] field for lexers that fold based on indentation.

[compile and run macros]: api.html#textadept.run.compile\_commands
[`textadept.bookmarks.toggle()`]: api.html#textadept.bookmarks.toggle
[`spawn_proc:kill()`]: api.html#spawn_proc:kill
[`lexer._FOLDBYINDENTATION`]: api.html#fold-by-indentation

### 7.9 (11 Mar 2015)

Bugfixes:

- Fixed command entry's abbreviated environment to allow functions to return values.
- Fixed accidental firing of "Escape" key on window focus lost.
- Fixed tab stop calculation in the terminal version.
- Improved performance of lexers that fold by indentation.
- Scintilla: fixed adaptive scrolling on Mac OSX.

Changes:

- The following view-specific properties are now considered buffer-specific: "view EOL", "view
  whitespace", "wrap mode", "margin type", and "margin width"; updated the "Buffer" and "View"
  menus appropriately.
- Officially supported language modules moved to a [new repository][].
- Added Fish lexer and updated PHP and Python lexers.
- Merged `events.FILE_SAVED_AS` into [`events.FILE_AFTER_SAVE`][] as a new parameter.
- Merged `textadept.file_types.shebangs` into `textadept.file_types.patterns`.
- Removed `io.boms`.
- Scintilla: added [`buffer.indic_hover_fore`][] and [`buffer.indic_hover_style`][] for styling
  indicators differently when the mouse is over them.
- Added new `buffer.INDIC_COMPOSITIONTHIN`, `buffer.INDIC_FULLBOX`, and `buffer.INDIC_TEXTFORE`
  indicators.
- Updated to [Scintilla][] 3.5.4.

[new repository]: https://github.com/orbitalquark/textadept-modules
[`events.FILE_AFTER_SAVE`]: api.html#events.FILE_AFTER_SAVE
[`buffer.indic_hover_fore`]: api.html#buffer.indic_hover_fore
[`buffer.indic_hover_style`]: api.html#buffer.indic_hover_style
[Scintilla]: https://scintilla.org

### 7.8 (01 Feb 2015)

Bugfixes:

- Fixed snippets bug where name matches lexer name.

Changes:

- Removed language-specific context menus; manipulate `textadept.menu.context_menu` directly
  from language modules.

### 7.8 beta 3 (21 Jan 2015)

Bugfixes:

- Fixed opening files with network paths on Windows.
- Fixed minor GTK 3 issues.
- Fixed bug in hiding caret when Textadept loses focus.
- Fixed bug in overwriting fold levels set by custom fold functions.
- Scintilla: fixed placement of large call tips.
- Scintilla: fixed background color of annotation lines with text margins.
- Scintilla: fixed some instances of paste on Mac OSX.
- Scintilla: fixed incorrect margin click handling in the terminal version.

Changes:

- Restore `^Z` key binding as "undo" if terminal suspend is disabled.
- Added [`events.SUSPEND`][] and [`events.RESUME`][] events for terminal suspend and resume.
- Updated to [Scintilla][] 3.5.3.

[`events.SUSPEND`]: api.html#events.SUSPEND
[`events.RESUME`]: api.html#events.RESUME
[Scintilla]: https://scintilla.org

### 7.8 beta 2 (11 Jan 2015)

Bugfixes:

- Improved C module's ctags lookups and autocompletion.
- Do not select a line when clicking on its first character in the terminal version.
- Fixed some cases of toggling find options via API in the terminal version.
- Improved folding by indentation.
- Scintilla: fixed caret blinking when holding down `Del`.
- Scintilla: avoid extra space when pasting from external applications.

Changes:

- The terminal version can suspend via `^Z` (changed "undo" key binding to `M-Z` and added
  additional `M-S-Z` "redo" binding).
- Added [`spawn_proc:close()`][] for sending EOF to spawned processes.
- Updated Tcl lexer.
- Scintilla: Added `buffer.ANNOTATION_INDENTED` for indented, non-bordered annotations.
- Scintilla: tab arrows, wrap markers, and line markers are now drawn in the terminal version.
- Updated to [Scintilla][] 3.5.2.

[`spawn_proc:close()`]: api.html#spawn_proc:close
[Scintilla]: https://scintilla.org

### 7.8 beta (01 Dec 2014)

Bugfixes:

- Fixed extra space pasting from external Windows apps.
- Fixed bug in C autocompletion.
- Disable GCC optimizations when compiling with debug symbols.
- Ensure "find in files" is off when activating normal find.
- Fixed return values from `ui.dialogs.optionselect()`.
- The command entry does not hide when the window loses focus.
- Fixed '//' bug when iterating over root directory with `lfs.dir_foreach()`.
- Fixed bug in jumping to compile/run errors and clear annotations before building projects.
- Fixed memory leaks in `ui.dialog()`.

Changes:

- Replaced the command entry text field with a Scintilla buffer and added
  [`ui.command_entry.editing_keys`][] for changing the editing keys in all modes.
- Added lexer and height parameters to `ui.command_entry.enter_mode()`.
- Support bracketed paste in the terminal version.
- Allow handling of unknown [CSI events][].
- Added mouse support for buffers and eliminated many [terminal version incompatibilities][].
- Added [`_G.LINUX`][] and `_G.BSD` platform flags for the sake of completeness.
- [Rectangular selections][] with the mouse on Linux use the `Alt` modifier key instead of `Super`.
- Display the current working directory in fileselect dialogs.
- Added [`_SCINTILLA.next_image_type()`][] for registering images.
- Added Arabic translation.
- File dialogs in the terminal span the whole view.
- Added basic UTF-8 support for terminal widgets -- locales such as Russian now display properly.
- Added UTF-8 input mode for Mac OSX (`⌘⇧U`) and the terminal version (`M-U`).
- Show character information in "Show Style" popup.

[`ui.command_entry.editing_keys`]: api.html#ui.command_entry.editing_keys
[CSI events]: api.html#events.CSI
[terminal version incompatibilities]: manual.html#terminal-version-compatibility
[`_G.LINUX`]: api.html#LINUX
[Rectangular selections]: manual.html#rectangular-selection
[`_SCINTILLA.next_image_type()`]: api.html#_SCINTILLA.new_image_type

### 7.7 (01 Oct 2014)

Bugfixes:

- Fixed corner-case in switching to most recent buffer after closing.
- Fixed find/replace bug when embedded Lua code evaluates to a number.
- Scintilla: fixed some instances of the autocompletion window not showing up.
- Scintilla: fixed sizing of the autocompletion window.

Changes:

- Mac OSX GUI version can truly `os.spawn()` processes now.
- Improved performance for lexers with no grammars and no fold rules.
- Updated to [Scintilla][] 3.5.1.

[Scintilla]: https://scintilla.org

### 7.6 (01 Sep 2014)

Bugfixes:

- Recognize DEL when emitted by the Backspace key in the terminal version.
- Scintilla: fixed `buffer:del_word_right()` selection redrawing bug.
- Scintilla: fixed autocompletion list memory leak.
- Scintilla: fixed overtype caret when it is over multi-byte characters.

Changes:

- Terminal version can truly `os.spawn()` processes now.
- Added Linux .desktop files for menus and launchers.
- Indicate presence of a BOM in the statusbar.
- Switch to previous buffer after closing a buffer.
- More options for `lfs.dir_foreach()`.
- Updated to [Scintilla][] 3.5.0.

[Scintilla]: https://scintilla.org

### 7.5 (11 Jul 2014)

Bugfixes:

- Fixed Bash heredoc highlighting.
- Scintilla: fixed some instances of indicators not being removed properly.
- Scintilla: fixed crash with Ubuntu's overlay scrollbars.

Changes:

- New [`events.FOCUS`][] event for when Textadept's window receives focus.
- Condensed manual and API documentation into single files.
- Added Polish translation.
- Scintilla: added [`buffer.auto_c_multi`][] for autocompleting into multiple selections.
- Updated to [Scintilla][] 3.4.4.

[`events.FOCUS`]: api.html#events.FOCUS
[`buffer.auto_c_multi`]: api.html#buffer.auto_c_multi
[Scintilla]: https://scintilla.org

### 7.4 (11 Jun 2014)

Bugfixes:

- Fix crash in Windows with sending input to spawned processes.
- Fix compile, run, and build command output with split views.
- Fix `#RRGGBB` color interpretation for styles.
- Fix word autocompletion when ignoring case.

Changes:

- Pressing the Enter key in the message buffer and find in files buffer simulates a double-click.

### 7.3 (01 Jun 2014)

Bugfixes:

- Export Lua symbols correctly on Windows.
- Fixed occasional bug when double-clicking in the message buffer.
- Fixed an edge-case in word highlighting.
- Fixed some folding by indentation edge cases.
- Scintilla: fixed caret invisibility when its period is zero.
- Scintilla: fixed flickering when scrolling in GTK 3.10+.

Changes:

- Added reST and YAML lexers and official language modules for each.
- Use `os.spawn()` for launching help.
- Renamed `io.set_buffer_encoding()` to [`buffer:set_encoding()`][].
- Removed Adeptsense in favor of [autocompleter functions][], but kept existing api file format.
- Renamed `textadept.editing.autocomplete_word()` to
  [`textadept.editing.autocomplete`][]`('word')`.
- New [`textadept.editing.AUTOCOMPLETE_ALL`][] field for autocompleting words from all open
  buffers.
- Dropped support for official java, php, rails, and rhtml modules; they are on the wiki now.
- Removed `textadept.editing.HIGHLIGHT_BRACES` option, as indicator style can be changed to
  hide highlighting.
- Removed `textadept.editing.select_indented_block()`.
- In-place menu editing via [`textadept.menu.menubar`][], [`textadept.menu.context_menu`][],
  and [`textadept.menu.tab_context_menu`][] tables.
- Removed `textadept.command_entry.complete_lua()` and `textadept.command_entry.execute_lua()`
  and moved their key bindings into their module.
- Updated D lexer.
- Scintilla: added `buffer.FOLDFLAG_LINESTATE` for lexer debugging aid.
- Updated to [Scintilla][] 3.4.2.

[`buffer:set_encoding()`]: api.html#buffer.set_encoding
[autocompleter functions]: api.html#textadept.editing.autocompleters
[`textadept.editing.autocomplete`]: api.html#textadept.editing.autocomplete
[`textadept.editing.AUTOCOMPLETE_ALL`]: api.html#textadept.editing.autocomplete_all_words
[`textadept.menu.menubar`]: api.html#textadept.menu.menubar
[`textadept.menu.context_menu`]: api.html#textadept.menu.context_menu
[`textadept.menu.tab_context_menu`]: api.html#textadept.menu.tab_context_menu
[Scintilla]: https://scintilla.org

### 7.2 (01 May 2014)

Bugfixes:

- Fixed cases of incorrect Markdown header highlighting.

Changes:

- Message buffer can send input to spawned processes.

### 7.2 beta 4 (11 Apr 2014)

Bugfixes:

- Fixed bug in parsing output from a canceled dropdown dialog.
- Always use absolute file paths so sessions are saved and reloaded properly.
- Temporarily disabled asynchronous spawning on OSX due to GLib crashes.

Changes:

- None.

### 7.2 beta 3 (01 Apr 2014)

Bugfixes:

- Fixed bug in Windows terminal version with "shifted" character input.
- Scintilla: fixed bug when moving caret down on wrapped lines.
- Scintilla: fixed instances of bad caret positioning within characters.
- Scintilla: fixed automatic indentation when the caret is within virtual space.
- Scintilla: fixed annotation deletion from lines.
- Scintilla: fixed placement of large call tips.

Changes:

- New optionselect dialog.
- Added `ui.SILENT_PRINT` option for printing messages.
- The GUI version can [spawn processes][] in separate threads.
- Removed experimental Windows `io.popen()` and `os.execute()` replacements due to spawning
  support.
- [Snapopen][] now supports projects; added new menu entry and key command.
- Added support for [building projects][].
- Scintilla: draw unicode line ends as blobs.
- Scintilla: added `buffer.WRAP_WHITESPACE` for wrapping on whitespace, not style changes.
- Updated to [LuaJIT][] 2.0.3.
- Updated to [Scintilla][] 3.4.1.

[spawn processes]: api.html#os.spawn
[Snapopen]: manual.html#quick-open
[building projects]: api.html#textadept.run.build
[LuaJIT]: https://luajit.org
[Scintilla]: https://scintilla.org

### 7.2 beta 2 (01 Mar 2014)

Bugfixes:

- Fixed bug with empty entries in multiple entry inputboxes.

Changes:

- Terminal version now has split views along with key bindings for them.

### 7.2 beta (11 Feb 2014)

Bugfixes:

- Handle *./* and *../* sequences in filepaths.
- Correctly restore views with word wrap enabled.
- Scintilla: fixed some instances of caret placement when scrolling.

Changes:

- Added Swedish translation.
- Added support for multiple entry boxes in inputdialogs.
- Updated LaTeX and Go lexers.
- Scintilla: added [`buffer:drop_selection_n()`][] for dropping a multiple selection.
- Scintilla: added `buffer.call_tip_pos_start` for altering call tip backspace behavior.
- Scintilla: added `buffer.MARK_BOOKMARK` marker symbol.
- Scintilla: better marker drawing.
- Updated to [Scintilla][] 3.3.9.

[`buffer:drop_selection_n()`]: api.html#buffer.drop_selection_n
[Scintilla]: https://scintilla.org

### 7.2 alpha (01 Jan 2014)

Bugfixes:

- Honor `ui.maximized` setting in session files.
- Do not halt opening files if one of them is already open.
- Better key input handling in the terminal version.
- Fixed Makefile bug in grabbing dependencies with older versions of wget.
- Recognize lower-case drive letter names for files passed from external programs in Windows.
- Scintilla: fixed some instances of adjacent indicator drawing.
- Scintilla: fixed scroll width tracking for annotated lines.
- Scintilla: fixed horizontal scroll bar range.
- Scintilla: fixed caret placement when margins change.
- Scintilla: fixed some instances of incorrect selection redrawing.

Changes:

- Added Dart lexer.
- Do not split the view when printing messages if tabs are enabled.
- Look for *~/.textadept/osx_env.sh* for [OSX environment variables][] due to changes in Mac
  OSX 10.9.
- [Experimental] Replaced Lua's `io.popen()` and `os.execute()` with versions that do not flash
  the "black box" on Windows.
- Added read-only access to the current key chain via `keys.keychain`.
- Renamed "hypertext" lexer and its corresponding module to "html".
- Added configurable tab context menus via `textadept.menu.set_contextmenus()`.
- New GUI theme for Mac OSX.
- [Experimental] Merged separate lexer states into Textadept's Lua state.
- Updated HTML lexer.
- Scintilla: the `Ctrl` modifier in Mac OSX mouse clicks is recognized as `buffer.MOD_META`.
- Scintilla: added [`buffer.representation`][] for changing the representation of characters.
- Scintilla: added [`buffer:position_relative()`][] for character navigation.
- Scintilla: added [`buffer.mouse_selection_rectangular_switch`][] for aiding in rectangular
  selection creation.
- Updated to [Lua][] 5.2.3.
- Updated to [Scintilla][] 3.3.7.

[OSX environment variables]: manual.html#mac-osx-environment-variables
[`buffer.representation`]: api.html#buffer.representation
[`buffer:position_relative()`]: api.html#buffer.position_relative
[`buffer.mouse_selection_rectangular_switch`]: api.html#buffer.mouse_selection_rectangular_switch
[Lua]: https://lua.org
[Scintilla]: https://scintilla.org

### 7.1 (11 Nov 2013)

Bugfixes:

- Textbox dialogs' `scroll_to` option works correctly.
- Emit autocompletion and hotspot events properly.
- Handle replacement captures with escapes properly.
- Fixed slowdown in processing long lines for folding.
- Fixed slowdown with large HTML files.

Changes:

- Tabs for multiple buffers along with [`ui.tabs`][] API.
- Split C/C++ lexer into separate lexers and replaced default "cpp" module with "ansi\_c".
- Find and replace text may utilize "%0" capture containing the entire match.
- Disable `textadept.editing.STRIP_TRAILING_SPACES` by default.
- `ui.clipboard_text` is no longer read-only.
- Added [`events.FILE_CHANGED`][] event.

[`ui.tabs`]: api.html#ui.tabs
[`events.FILE_CHANGED`]: api.html#events.FILE_CHANGED

### 7.0 (01 Nov 2013)

Please see the [6 to 7 migration guide][] for upgrading from Textadept 6 to Textadept 7.

Bugfixes:

- Fixed bug with `buffer.SCFIND_REGEX` flag.
- Fixed OSX Command key recognition for click events.
- Fixed compile error with GTK3.
- HTML and XML lexers maintain their states better.

Changes:

- Added Assembly (NASM) lexer with compile and run commands.
- `textadept.adeptsense.goto_ctag()` can show all known tags now.
- `textadept.editing.enclose()` encloses the whole current word.

[6 to 7 migration guide]: manual.html#textadept-6-to-7

### 7.0 beta 5 (21 Oct 2013)

Bugfixes:

- Show more helpful user-init startup error messages.
- Lua run command buffers output correctly.
- Fixed corner case in paragraph selection.
- Fixed corner case in block uncommenting.
- Disable folding when `fold` property is `0`.

Changes:

- Changed `ui.set_theme()` API to accept a table of property assignments.
- Added Nimrod lexer and compile and run commands.
- Use `textadept.editing.INDIC_BRACEMATCH` indicator for brace highlighting instead of styles.
- The `buffer` API applies to all buffers now, not just the global one.
- Added "Save All" to the menu.
- Updated D lexer.
- Added additional parameter to [`lexer.load()`][] to allow child lexers to be embedded multiple
  times with different start/end tokens.
- Lexers do not need an "any\_char" [rule][] anymore; it is included by default.
- [Child lexers][] do not need an explicit `M._lexer = parent` declaration anymore; it is done
  automatically.

[`lexer.load()`]: api.html#lexer.load
[rule]: api.html#rules
[Child lexers]: api.html#child-lexer

### 7.0 beta 4 (01 Oct 2013)

Bugfixes:

- Fixed various compile and install errors.
- Fixed error when block commenting plain text.
- Fixed occasional crash when getting the lexer name in a multi-language lexer.

Changes:

- [`events.disconnect()`][] now accepts function argument instead of ID.
- `buffer.filename` and all internal filenames are no longer encoded in UTF-8, but in
  [`_CHARSET`][].
- Removed many unused Scintilla constants and stripped many constants of `SC` and `SC_` prefixes.
- Changed marker margin symbols via *properties.lua*.
- Calling `textadept.editing.select_word()` repeatedly makes multiple selections.
- Renamed `buffer:convert_eo_ls()` to [`convert_eols()`][].
- Added [`textadept.run.MARK_WARNING`][] marker.
- Renamed `textadept.run.compile_command` and `textadept.run.run_command` to [`compile_commands`][]
  and [`run_commands`][], respectively.
- Renamed `textadept.run.error_detail` to `error_patterns` and changed its internal structure.
- Compile and run commands for languages that support them are now built-in along with their
  respective warning and error messages. The supplemental ones on the wiki are no longer needed.
- New [`ui.dialogs`][] module for more user-friendly dialog support. Removed `ui.filteredlist()`
  as a result.
- Changed [`io.open_file()`][] and [`io.snapopen()`][] to accept tables of files and paths
  instead of "\n" delimited strings.
- Changed `lexer.get_fold_level()`, `lexer.get_indent_amount()`, `lexer.get_property()`, and
  `lexer.get_style_at()` functions to be [`lexer.fold_level`][], [`lexer.indent_amount`][],
  [`lexer.property`][], and [`lexer.style_at`][] tables, respectively.
- Added [`lexer.property_int`][] and [`lexer.property_expanded`][] tables.
- Changed API for [`lexer.delimited_range()`][] and [`lexer.nested_pair()`][].
- Only enable `fold.by.indentation` property by default in whitespace-significant languages.

[`events.disconnect()`]: api.html#events.disconnect
[`_CHARSET`]: api.html#_CHARSET
[`convert_eols()`]: api.html#buffer.convert_eols
[`textadept.run.MARK_WARNING`]: api.html#textadept.run.MARK_WARNING
[`compile_commands`]: api.html#textadept.run.compile_commands
[`run_commands`]: api.html#textadept.run.run_commands
[`ui.dialogs`]: api.html#ui.dialogs
[`io.open_file()`]: api.html#io.open_file
[`io.snapopen()`]: api.html#io.quick_open
[`lexer.fold_level`]: api.html#lexer.fold_level
[`lexer.indent_amount`]: api.html#lexer.indent_amount
[`lexer.property`]: api.html#lexer.property
[`lexer.style_at`]: api.html#lexer.style_at
[`lexer.property_int`]: api.html#lexer.property_int
[`lexer.property_expanded`]: api.html#lexer.property_expanded
[`lexer.delimited_range()`]: api.html#lexer.delimited_range
[`lexer.nested_pair()`]: api.html#lexer.nested_pair

### 7.0 beta 3 (11 Sep 2013)

Bugfixes:

- User functions that connect to `events.BUFFER_NEW` and `events.VIEW_NEW` are run on startup.
- Fixed potential crash caused by split views.

Changes:

- Copied constants from `_SCINTILLA.constants` into `buffer`.
- Renamed `events.LANGUAGE_MODULE_LOADED` to [`events.LEXER_LOADED`][].
- Renamed `gui` to [`ui`][].
- Renamed `_M.textadept` to [`textadept`][].
- New [`events.INITIALIZED`][] event.
- Renamed `buffer:get_style_name()` to `buffer.style_name`.
- Renamed `ui.docstatusbar_text` to `ui.bufstatusbar_text`.
- Removed `textadept.bookmarks.BOOKMARK_COLOR`, `textadept.editing.HIGHLIGHT_COLOR`, and
  `textadept.run.ERROR_COLOR` while exposing their respective marker and indicator numbers
  for customization.
- Moved buffer IO functions into [`io` module][].
- Updated to [CDK][] 5.0-20130901.

[`events.LEXER_LOADED`]: api.html#events.LEXER_LOADED
[`ui`]: api.html#ui
[`textadept`]: api.html#textadept
[`events.INITIALIZED`]: api.html#events.INITIALIZED
[`io` module]: api.html#io
[CDK]: https://invisible-island.net/cdk/cdk.html

### 7.0 beta 2 (11 Aug 2013)

Bugfixes:

- Fixed bug with theme loading when resetting.
- Fixed bug with property settings in `gui.set_theme()` not persisting.
- Scintilla: fixed some instances of case conversions.
- Scintilla: fixed some instances of word wrapping and improved performance.
- Scintilla: fixed minor memory leak.

Changes:

- New [`gui.maximized`][] field so Textadept can remember its maximized state.
- Changed `lexer._tokenstyles` to be a map instead of a list.
- Scintilla: improved UTF-8 case-insensitive searching.
- Updated to [Scintilla][] 3.3.4.

[`gui.maximized`]: api.html#ui.maximized
[Scintilla]: https://scintilla.org

### 7.0 beta (11 Jul 2013)

Bugfixes:

- Added file type for Go.
- Fixed disorienting scrolling in some instances of splitting views.
- Fixed corner-case bug in Lua Pattern "Replace All".

Changes:

- Renamed `_M.textadept.mime_types` to `_M.textadept.file_types`.
- Eliminated *mime_types.conf* files. Add or modify file type tables [directly][].
- Changed scrollbar look and feel on Mac OSX.

[directly]: manual.html#file-types

### 7.0 alpha 2 (01 Jul 2013)

Bugfixes:

- Fixed bug in user theme loading.
- Fixed "Enter" key autocompletion in the terminal version.
- Fixed crash when transposing in an empty buffer.
- Fixed bug in find and run double-click event handlers.

Changes:

- Makefile improvements. See [compiling][] for more information. The source release is no
  longer necessary.
- Removed `_G._LEXERPATH` and `_L._EXISTS()`.
- Renamed Adeptsense image fields.
- Renamed `_M.textadept.editing.STRIP_WHITESPACE_ON_SAVE` to `STRIP_TRAILING_SPACES`.
- `_M.textadept.editing.block_comment()` supports block comment delimiters.
- Block comments for languages is now built-in. The supplemental ones on the wiki are no
  longer needed.
- `gui.set_theme()` accepts key-value argument pairs for overriding theme properties.
- Removed `gui.select_theme()` since selected themes do not persist.
- Removed `_G.RESETTING` flag.
- Consolidated `_M.textadept.bookmarks.goto_*()` functionality into
  [`_M.textadept.bookmarks.goto_mark()`][].
- Updated to [LuaJIT][] 2.0.2.
- New [nightly builds][].

[compiling]: manual.html#compiling
[`_M.textadept.bookmarks.goto_mark()`]: api.html#textadept.bookmarks.goto_mark
[LuaJIT]: https://luajit.org
[nightly builds]: index.html

### 7.0 alpha (01 Jun 2013)

Bugfixes:

- Scintilla: fixed memory access bug.
- Scintilla: fixed crash when pasting in Windows.
- Scintilla: fixed some event reporting in GTK 3.x.
- Scintilla: fixed undo grouping with tab and backtab.

Changes:

- Completely new [theme implementation][].
- New [*properties.lua*][] for custom buffer and view properties.
- Updated to [Scintilla][] 3.3.3.

[theme implementation]: manual.html#themes
[*properties.lua*]: manual.html#buffer-settings
[Scintilla]: https://scintilla.org

### 6.6 (01 Jun 2013)

Bugfixes:

- Fixed GTK assertion errors in find/replace history.
- Command entry loses focus less often.
- Allow empty tables as keychains if they have metatables.
- Fixed caret placement in block comment/uncomment.
- Use '\n' keycode in the terminal version instead of '\r'.
- Fixed crash caused by split views.
- Scintilla: fixed typing into multiple carets in virtual space.

Changes:

- Removed `_M[lang].set_buffer_properties()` functions. Set properties through
  `events.LANGUAGE_MODULE_LOADED` instead.
- Print the results of '=' Lua commands.
- Updated D lexer.
- Scintilla: added `buffer.INDIC_COMPOSITIONTHICK` indicator.
- Updated to [Scintilla][] 3.3.2.

[Scintilla]: https://scintilla.org

### 6.6 beta (01 May 2013)

Bugfixes:

- Fixed rendering on Mac OSX retina displays.
- Fixed rectangle indicator display in the terminal version.
- Fixed Fn key recognition on Mac OSX.
- Fixed compile errors for Mac OSX.
- Find Previous for Lua patterns works.

Changes:

- Textadept supports multiple curses platforms, not just ncurses. Make targets now use "curses"
  instead of "ncurses".
- Better 16-color terminal support in lexer theme.
- Reduced the delay when pressing `Esc` in the terminal version.
- Messagebox dialogs can show icons via `--icon` and `--icon-file`.
- New Windows terminal version.
- New [key modes][] functionality.
- Scintilla: added [`buffer.auto_c_order`][] for sorting autocompletion lists.
- Updated to [Scintilla][] 3.3.1.
- Renamed `_G.buffer_new()` to [`buffer.new()`][].
- Changed the display of highlighted words, including removing
  `_M.textadept.editing.INDIC_HIGHLIGHT_ALPHA`.
- Changed `_M.textadept.editing.autocomplete_word()` API.
- Removed `_M.textadept.menu.menubar`, `_M.textadept.menu.contextmenu`, and `events.handlers`
  tables from the API.
- Moved `_M.textadept.filter_through` module functionality into
  [`_M.textadept.editing.filter_through()`][].
- Mark errors in compile/run commands and added [`_M.textadept.run.goto_error()`][] menu options
  and key shortcuts.
- Renamed `gui.find.goto_file_in_list()` to [`gui.find.goto_file_found()`][].
- Consolidated `_M.textadept.editing.grow_selection()` functionality into
  [`_M.textadept.editing.select_enclosed()`][].
- Renamed `io.try_encodings` to [`io.encodings`][].
- No need for '!' in front of font faces anymore.

[key modes]: api.html#modes
[`buffer.auto_c_order`]: api.html#buffer.auto_c_order
[Scintilla]: https://scintilla.org
[`buffer.new()`]: api.html#buffer.new
[`_M.textadept.editing.filter_through()`]: api.html#textadept.editing.filter_through
[`_M.textadept.run.goto_error()`]: api.html#textadept.run.goto_error
[`gui.find.goto_file_found()`]: api.html#ui.find.goto_file_found
[`_M.textadept.editing.select_enclosed()`]: api.html#textadept.editing.select_enclosed
[`io.encodings`]: api.html#io.encodings

### 6.5 (01 Apr 2013)

Bugfixes:

- Only consider visible directories in *_USERHOME/themes/* as themes.
- Indicator for highlighted words works in ncurses.
- Improved message double-clicking behavior for compile and run commands by adding
  `_M.textadept.run.cwd`.
- Fixed disorienting scrolling when wrapping only one search result.
- Fixed crash when attempting to load a non-existant lexer.
- Fixed CSS preprocessor styling.
- Fixed labels for inputbox dialogs.
- Scintilla: fixed some instances of incorrect folded text display.
- Scintilla: fixed `buffer:visible_from_doc_line()` to never return a line beyond the end of
  the buffer.
- Scintilla: fixed `buffer:line_scroll()` for negative columns.
- Scintilla: fixed tab marker display when indentation lines are visible.

Changes:

- Reset Lua state after selecting a new theme.
- Added `lfs.dir_foreach()`.
- Added file and directory [filtering][] for Find in Files.
- Moved `_M.textadept.snapopen` into `io`.
- Renamed some [`lexer` constants][].
- Added Less, Literal Coffeescript, and Sass lexers.
- Scintilla: added [`buffer:scroll_range()`][] for scrolling ranges into view.
- Updated to [Scintilla][] 3.3.0.
- Updated to [Lua][] 5.2.2.

[filtering]: api.html#ui.find.find_in_files_filter
[`lexer` constants]: api.html#lexer.FOLD_BASE
[`buffer:scroll_range()`]: api.html#buffer.scroll_range
[Scintilla]: https://scintilla.org
[Lua]: https://lua.org

### 6.4 (01 Mar 2013)

Bugfixes:

- Dialogs belong to the Textadept window.
- Double-clicking a filteredlist item selects it.
- Fixed bug in documentation link generator.
- Fixed bug with indexable buffer properties that return strings.
- Scintilla: fixed scrollbar drawing when toggling visibility.

Changes:

- Added [command line options][] for loading sessions on startup.
- Added [command line options][] for running Lua code on startup.
- Updated AWK lexer.
- Updated to [Scintilla][] 3.2.5.
- Updated to [LuaJIT][] 2.0.1.

[command line options]: manual.html#command-line-parameters
[Scintilla]: https://scintilla.org
[LuaJIT]: https://luajit.org

### 6.3 (01 Feb 2013)

Bugfixes:

- Do not error on non-existant dropped URIs.
- Fixed crash in Python module when parsing some syntax error messages.
- Scintilla: fixed pasting with NULL bytes.
- Scintilla: autocompletion should only have one undo step.
- Scintilla: fixed crash when drawing very long lines.
- Scintilla: fixed unexpected collapse of selections when extending by character.

Changes:

- Use Scintilla API for ncurses mark mode.
- Scintilla: added [`buffer.caret_line_visible_always`][] for showing the caret line despite
  not having focus.
- Updated to [Scintilla][] 3.2.4.
- Added [typeover characters][].

[`buffer.caret_line_visible_always`]: api.html#buffer.caret_line_visible_always
[Scintilla]: https://scintilla.org
[typeover characters]: api.html#textadept.editing.typeover_auto_paired

### 6.2 (01 Jan 2013)

Bugfixes:

- None.

Changes:

- Greatly improved speed when loading large files.
- `make install` and `make ncurses install` install separate binaries on Linux.
- Changed API for [`_M.textadept.snapopen.open()`][] and removed `PATHS`.

[`_M.textadept.snapopen.open()`]: api.html#io.quick_open

### 6.1 (11 Dec 2012)

Bugfixes:

- Do not set current directory when opening/saving files.
- Detect Linux processor arch better.
- Recognize special ncurses keys better.
- Fixed potential bug with determining `_HOME` on Linux.
- Fixed bug when opening non-existent files from the command line.
- LuaJIT compiles correctly on ARM now.

Changes:

- Improved speed and memory usage of lexers.
- Better Makefile support for building packages for Linux distros.
- Rewrote LuaDoc [API documentation][].
- Added French translation.
- Updated to [LuaJIT][] 2.0.0.
- Improved speed and memory usage of lexers.
- Updated Java lexer.

[API documentation]: api.html
[LuaJIT]: https://luajit.org

### 6.0 (01 Nov 2012)

Please see the [5 to 6 migration guide][] for upgrading from Textadept 5 to Textadept 6.

Bugfixes:

- Handle rapidly pressing `Esc` twice in ncurses dialogs.
- Complete transition to `buffer.tab_size` from `buffer.indent`.
- Fixed regression in ncurses command selection.
- Fixed GUI menu key shortcut handling.
- Fixed string collation bug in ncurses due to CDK.
- Pass `Esc` to Scintilla correctly in ncurses.
- Fix errors when specifying directories and files for file dialogs.
- Fixed some operators in Bash lexer.
- Scintilla: fixed hang when removing all characters from an indicator at the the end of a buffer.
- Scintilla: fixed crash when drawing margins in GTK 3.
- Scintilla: do not draw spaces after an italic style at the end of a line in the terminal version.

Changes:

- Added key binding for toggling fold points.
- Added ncurses key bindings for bookmarks.
- Added [`event.FIND_WRAPPED`][] event.
- Removed `_M.textadept.run.execute()`.
- Updated documentation and documentation formatting.
- Added Python module.
- Rewrote Makefile lexer.
- Scintilla: improved performance when performing multiple searches.
- Updated to [Scintilla][] 3.2.3.
- Updated to [LuaJIT][] 2.0.0-beta11.

[5 to 6 migration guide]: manual.html#textadept-5-to-6
[`event.FIND_WRAPPED`]: api.html#events.FIND_WRAPPED
[Scintilla]: https://scintilla.org
[LuaJIT]: https://luajit.org

### 6.0 beta 3 (01 Oct 2012)

Bugfixes:

- Canceling in `buffer:close()` caused unwanted key propagation.
- Correctly emit `RUN_OUTPUT` events.
- Fixed bug with extra empty entry in the buffer browser.
- Fixed incremental find in ncurses.
- Fixed ncurses crash when pasting with no clipboard text.
- Keep termios disabled in ncurses CDK widgets.
- Do not write ncurses initialization errors over titlebar.
- Fixed bug in `string.iconv()`.
- Include `_` as identifier char in Desktop lexer.

Changes:

- Attempt to autodetect locale using `LANG` environment variable.
- Removed `_M.textadept.menu.rebuild_command_tables()`.
- Manual and Lua API documentation largely re-written.
- Key Bindings reference moved from Appendix to [`_M.textadept.keys`][] LuaDoc.
- Plain text lexer name changed from `container` to `text`.
- New application icon.
- Removed `./?.lua` and `./?.so` from `package.path` and `package.cpath`, respectively.
- Added marks for making selections in ncurses.

[`_M.textadept.keys`]: api.html#textadept.keys

### 6.0 beta 2 (01 Sep 2012)

Bugfixes:

- Disabled `--help` option to ncurses version due to terminal output mangling.
- ncurses replace entry can now be focused.
- Fixed ncurses memory leaks.
- Fixed multiple selection in Mac OSX.
- Show key shortcuts in ncurses `_M.textadept.menu.select_command()`.
- Scintilla: fixed rectangular selection range after backspacing.
- Scintilla: fixed bug with negative ranges in call tip highlighting.

Changes:

- Added `make install` and `make uninstall` rules for optional installation.
- Updated manual with ncurses key bindings.
- Consolidated `_M.textadept.bookmarks.add()` and `_M.textadept.bookmarks.remove()` into
  [`_M.textadept.bookmarks.toggle()`][].
- Updated manual images.
- `_M.textadept.snapopen.DEFAULT_DEPTH` is now `99` since `MAX` is the limiting factor.
- Use constant names in theme options instead of nondescript integers.
- Added new lexer.last_char_includes() function for better regex detection.
- Updated AWK lexer.
- Scintilla: added [`buffer.selection_empty`][].
- Scintilla: added [`buffer:vc_home_display()`][] and [`buffer:vc_home_display_extend()`][]
  for navigating wrapped lines.
- Updated to [Scintilla][] 3.2.2.

[`_M.textadept.bookmarks.toggle()`]: api.html#textadept.bookmarks.toggle
[`buffer.selection_empty`]: api.html#buffer.selection_empty
[`buffer:vc_home_display()`]: api.html#buffer.vc_home_display
[`buffer:vc_home_display_extend()`]: api.html#buffer.vc_home_display_extend
[Scintilla]: https://scintilla.org

### 6.0 beta (01 Aug 2012)

Bugfixes:

- Lots of bugfixes to the experimental ncurses version.
- Fixed bug with `$$` variables in Perl lexer.
- Scintilla: do not show empty autocompletion list if `buffer.auto_c_choose_single` is set.
- Scintilla: fixed `buffer:marker_delete()` to only delete one marker per call.
- Scintilla: fixed caret positioning after undoing multiple deletions.
- Scintilla: fixed margin drawing after `buffer.margin_style` is altered.
- Scintilla: fixed margin click handling.
- Scintilla: fixed hang when drawing block carets on a zero-width space at the beginning of
  a buffer.
- Scintilla: fixed crash deleting negative ranges.
- Scintilla: fixed drawing of overlapping characters.

Changes:

- Removed Lua, Ruby, and PHP modules' `goto_required()` functions.
- Moved `_M.textadept.editing.prepare_for_save()` directly into event handler.
- Moved `_M.textadept.session.prompt_load()` and `prompt_save()` functionality into
  [`_M.textadept.session.load()`][] and [`_M.textadept.session.save()`][].
- Removed `_G.user_dofile()`.
- Converted some `buffer` "get" and "set" functions into properties.
- Moved `_M.textadept.adeptsense.complete_symbol()` and `show_documentation()` functionality into
  `_M.textadept.adeptsense.complete()` and `show_apidoc()`.
- New 64-bit Windows version (note: without LuaJIT).
- Updated Perl lexer.
- Scintilla: added [`buffer.punctuation_chars`][], [`buffer.word_chars`][], and
  [`buffer.whitespace_chars`][] for manipulating character sets.
- Updated to [Scintilla][] 3.2.1.

[`_M.textadept.session.load()`]: api.html#textadept.session.load
[`_M.textadept.session.save()`]: api.html#textadept.session.save
[`buffer.punctuation_chars`]: api.html#buffer.punctuation_chars
[`buffer.word_chars`]: api.html#buffer.word_chars
[`buffer.whitespace_chars`]: api.html#buffer.whitespace_chars
[Scintilla]: https://scintilla.org

### 5.5 beta (01 Jul 2012)

Bugfixes:

- None.

Changes:

- Experimental ncurses support.
- No more `'gtk-'` stock menu item support and changed `'separator'` to `''`.
- Renamed `gui.gtkmenu()` to [`gui.menu()`][].
- Changed `gui.statusbar_text` to be write-only.
- Changed 'Quit' key command to 'Ctrl+Q' on Windows and Linux.
- Show text that could not be localized.
- Changed `make` commands for [compiling][] Textadept.
- x86\_64 binary provides `libpng12` executables by default.
- Can cross compile to Mac OSX from Linux.
- Updated AWK lexer.
- Updated HTML lexer to recognize HTML5 'script' and 'style' tags.
- Updated to [Lua 5.2.1][].
- Updated to [LuaJIT][] 2.0.0-beta10.

[`gui.menu()`]: api.html#ui.menu
[compiling]: manual.html#compiling
[Lua 5.2.1]: https://www.lua.org/manual/5.2/
[LuaJIT]: https://luajit.org

### 5.4 (01 Jun 2012)

Bugfixes:

- Scintilla: fixed boxed annotation drawing.
- Scintilla: fixed virtual space selection bug in rectangular selections.
- Scintilla: replacing multiple selections with newlines is a single undo action.
- Scintilla: fixed autocompletion list height in GTK 3.
- Scintilla: fixed mouse scrolling due to recent GTK changes.

Changes:

- Identify more file extensions.
- Updated Batch lexer.
- Scintilla: `Ctrl+Double Click` and `Ctrl+Triple Click` adds words and lines, respectively,
  to selections.
- Scintilla: added [`buffer:delete_range()`][] for deleting ranges of text.
- Scintilla: added `buffer.WRAPVISUALFLAG_MARGIN` for drawing wrap markers in margins.
- Scintilla: improved UTF-8 validity checks.
- Updated to [Scintilla][] 3.2.0.

[`buffer:delete_range()`]: api.html#buffer.delete_range
[Scintilla]: https://scintilla.org

### 5.3 (01 May 2012)

Bugfixes:

- Fixed bug with run/compile commands in LuaJIT version.
- User annotation preferences are preserved.
- Fixed bug with number representation in some locales.
- Scintilla: fixed selection drawing in word wrap indentation.
- Scintilla: fixed styling bug.
- Scintilla: fixed problems with drawing in margins.
- Scintilla: fixed corner case in `buffer:move_selected_lines_*()`.
- Scintilla: fixed scrolling with mousewheel.
- Scintilla: fixed column calculations to count tabs correctly.

Changes:

- Annotations are used for showing run/compile command output.
- Textadept is [single-instance][] by default on Linux and Mac OSX.
- Textadept requires [GTK][] 2.18 or higher now instead of 2.16.
- The provided Textadept binaries [require][] [GLib][] 2.28 or higher.
- Scintilla: added `buffer.auto_c_case_insensitive_behaviour` for controlling case sensitivity
  in autocompletion lists.
- Scintilla: `\0` in regex replacements represents the full found text.
- Updated to [Scintilla][] 3.1.0.

[single-instance]: manual.html#single-instance
[GTK]: https://gtk.org
[require]: manual.html#requirements
[GLib]: https://gtk.org/download/linux.php
[Scintilla]: https://scintilla.org

### 5.2 (01 Apr 2012)

Bugfixes:

- Fixed LuaDoc for `buffer:get_lexer()`.
- Fixed bug with relative paths from command line files.
- `buffer:get_lexer(true)` is used more often when it should be.
- Improved message double-clicking behavior for run and compile commands.
- Scintilla: line and selection duplication is one undo action.
- Scintilla: allow indicators to be set for entire document.
- Scintilla: fixed crash in `buffer:move_selected_lines_*()`.
- Scintilla: fixed image and fold marker drawing.
- Scintilla: fixed some instances of multiple clicks in margins.
- Scintilla: fixed `buffer:page_*()` not returning to the original line.
- Scintilla: fixed various issues with wrapped lines.
- Scintilla: fixed line end selection drawing.

Changes:

- `_M.set_buffer_properties()` is now optional for language modules.
- Added keypad keys to `keys.KEYSYMS`.
- `_G.timeout()` accepts fractional seconds.
- Replaced `scripts/update_doc` with `src/Makefile` targets.
- New Manual and LuaDoc HTML page formatting.
- `_M.textadept.editing.autocomplete_word()` accepts default words.
- Added documentation on [generating LuaDoc][] and Lua Adeptsense.
- Moved `Markdown:` comments into LuaDoc.
- Added Spanish and German translations.
- Updated VB and VBScript lexers.
- Improved the speed of simple code folding.
- Use [GTK][] 2.24 on Windows.
- Updated to [Scintilla][] 3.0.4.

[generating LuaDoc]: manual.html#generating-luadoc
[GTK]: https://gtk.org
[Scintilla]: https://scintilla.org

### 5.1 (01 Mar 2012)

Bugfixes:

- Fixed crash caused by `gui.filteredlist()` dialogs.
- Support multiple `@return` tags in Lua Adeptsense.
- Fixed display of `buffer._type` when it has slashes in its name.

Changes:

- Better Lua Adeptsense formatting.
- Use new Cocoa-based [GtkOSXApplication][] library for better OSX support.
- Lexers with no tokens can be styled manually.
- Added more OSX default key shortcuts.

[GtkOSXApplication]: https://live.gnome.org/GTK%2B/OSX/Integration#Gtk-mac-integration.2BAC8-GtkOSXApplication

### 5.0 (01 Feb 2012)

Please see the [4 to 5 migration guide][] for upgrading from Textadept 4 to
Textadept 5.

Bugfixes:

- Fixed bug with recent files in sessions.
- Scintilla: fixed page up/down in autocompletion lists.
- Scintilla: fixed fold highlighting.

Changes:

- Added default extension and folder filters in `modules/textadept/snapopen.lua`.
- Added ChucK lexer.
- Updated Lua lexer.
- Updated to [Scintilla][] 3.0.3.
- Also include [LuaJIT][] executables in releases.

[4 to 5 migration guide]: manual.html#textadept-4-to-5
[Scintilla]: https://scintilla.org
[LuaJIT]: https://luajit.org

### 5.0 beta (11 Jan 2012)

Bugfixes:

- Fixed bug in `reset()` from update to Lua 5.2.

Changes:

- Changed `locale.localize()` to global [`_L`][] table and removed `locale` module.
- Renamed `_m` to `_M`.
- Do not clear registered images when autocompleting with Adeptsense.
- Renamed editing module's `current_word()` to [`select_word()`][].
- Updated [manual][].
- Updated D lexer.

[`_L`]: api.html#_L
[manual]: manual.html
[`select_word()`]: api.html#textadept.editing.select_word

### 5.0 alpha (21 Dec 2011)

Bugfixes:

- Fixed bug in Matlab lexer for operators.
- Fixed highlighting of variables in Bash.
- Fixed multi-line delimited and token strings in D lexer.

Changes:

- Updated to [Lua 5.2][].
- Updated sections in the [manual][] to reflect Lua 5.2 changes.
- Textadept can be compiled with [LuaJIT][].

[Lua 5.2]: https://www.lua.org/manual/5.2/
[manual]: manual.html
[LuaJIT]: https://luajit.org

### 4.3 (01 Dec 2011)

Bugfixes:

- Fixed bug with opening files in the current directory from the command line.
- Fixed erroneous charset conversion.
- Fixed bug with folding line comments.
- Scintilla: fixed drawing at style boundaries on Mac OSX.
- Scintilla: fixed crash when painting uninitialized pixmaps.

Changes:

- Added on-the-fly theme switching.
- All new `light` and `dark` themes.
- Removed `_m.textadept.editing.select_style()`.
- Simplify theming via [gtkrc][] by naming `GtkWindow` only.
- Added [`lexer.REGEX`][] and [`lexer.LABEL`][] tokens.
- Updated to [Scintilla][] 3.0.1.

[gtkrc]: manual.html#gui-theme
[`lexer.REGEX`]: api.html#lexer.REGEX
[`lexer.LABEL`]: api.html#lexer.LABEL
[Scintilla]: https://scintilla.org

### 4.2 (01 Nov 2011)

Bugfixes:

- Fixed bug with `%n` in Replace introduced in 4.1.
- Fixed Adeptsense autocomplete for single item.
- Scintilla: fixed annotation drawing in multiple, wrapped views.

Changes:

- Scintilla: drawing improvements and various optimizations.
- Scintilla: call tips can be displayed above text.
- Updated to [Scintilla][] 3.0.0.

[Scintilla]: https://scintilla.org

### 4.1 (01 Oct 2011)

Bugfixes:

- Only fold when clicking on fold margin, not any sensitive one.
- Fixed bug with `CALL_TIP_CLICK` event disconnect in Adeptsense.
- Fixed bug with autocomplete and capitalization.
- Scintilla: fixed incorrect mouse cursor changes.
- Scintilla: fixed end-of-document indicator growth.

Changes:

- Handle mouse [dwell events][] `DWELL_START` and `DWELL_END`.
- Rearranged `Tools` menu slightly.
- Slight API changes:
	+ [`_BUFFERS`][] and [`_VIEWS`][] structure changed.
	+ Removed `buffer.doc_pointer` and `view.doc_pointer`.
	+ Added [`view.buffer`][] field.
	+ Renamed `gui.check_focused_buffer()` to `buffer:check_global()`.
	+ [`view:goto_buffer()`][] and [`gui.goto_view()`][] arguments make sense now.
	  (May require changes to custom key bindings.)
- Directory is remembered in file chooser dialog after open or save as.
- Added language-specific context menu support.
- Use [LuaCoco][] patch for Lua 5.1.4.
- Use lexer at the caret for key bindings and snippets.
- Added `selected` and `monospaced-font` options for dropdown and textbox dialogs, respectively.
- Updated to [Scintilla][] 2.29.

[dwell events]: api.html#events
[`_BUFFERS`]: api.html#_BUFFERS
[`_VIEWS`]: api.html#_VIEWS
[`view.buffer`]: api.html#view.buffer
[`view:goto_buffer()`]: api.html#view.goto_buffer
[`gui.goto_view()`]: api.html#ui.goto_view
[LuaCoco]: https://coco.luajit.org/
[Scintilla]: https://scintilla.org

### 4.0 (01 Sep 2011)

Please see the [3 to 4 migration guide][] for upgrading from Textadept 3 to Textadept 4.

Bugfixes:

- Makefile should only link to `libdl.so` on Linux/BSD.
- Fixed memory access bug in `gui.dialog()`.
- Autocompletion list sort order respects `buffer.auto_c_ignore_case` now.
- Fixed split view focus bug with the same buffer in two views.
- Set new buffer EOL mode properly on Mac OSX.
- Fixed some general bugs in folding.

Changes:

- Added Russian translation.
- Changed some key bindings from 4.0 beta 2.
- Do not hide the statusbar when the command entry has focus.

[3 to 4 migration guide]: manual.html#textadept-3-to-4

### 4.0 beta 2 (11 Aug 2011)

Bugfixes:

- Fixed transpose characters bug at end of buffer.
- Do not autosave over explicitly loaded session.
- Fixed startup crash on Mac OSX.
- Fixed resize crash on Mac OSX Lion.

Changes:

- Added Scala lexer.
- Add [recent file list][] to session files.
- Autocomplete supports multiple selections.
- Swapped OSX `c` and `m` key command definition modifiers.
- Changed some key bindings from 4.0 beta.

[recent file list]: api.html#io.recent_files

### 4.0 beta (01 Aug 2011)

Bugfixes:

- Fixed Markdown lexer styles.
- Fixed bug when setting both dialog with and height.
- Scintilla: fixed incorrect mouse cursor changes.
- Scintilla: fixed bug with annotations beyond the document end.
- Scintilla: fixed incorrect drawing of background colors and translucent selection.
- Scintilla: fixed lexer initialization.
- Scintilla: fixed some instances of fold highlight drawing.
- Scintilla: fixed some cases of case insensitive searching.

Changes:

- Mac OSX uses GTK 2.24.
- Added [`io.open_recent_file()`][].
- Changes to localization file again.
- [`buffer`][] functions may omit the first `buffer` argument (e.g. `buffer.line_down()`
  is allowed).
- Complete overhaul of menus and added accelerators to [menu][] items.
- Renamed `_m.textadept.editing.SAVE_STRIPS_WS` to
  [`_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`][].
- Renamed `_m.textadept.editing.select_scope()` to `_m.textadept.editing.select_style()`.
- *Completely new set of key bindings.*
- Scintilla: translucent RGBA images can be used in margins and autocompletion and user lists.
- Scintilla: added new `buffer.INDIC_DOTBOX` indicator.
- Scintilla: IME input now works.
- Scintilla: `Ctrl+Shift+U` used for Unicode input.
- Updated to [Scintilla][] 2.28.

[`io.open_recent_file()`]: api.html#io.open_recent_file
[`buffer`]: api.html#buffer
[`_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`]: api.html#textadept.editing.STRIP_WHITESPACE_ON_SAVE
[menu]: api.html#ui.menu
[Scintilla]: https://scintilla.org

### 3.9 (01 Jul 2011)

Bugfixes:

- Fixed bug for when `gui.dialog()` steals focus.
- Colors are now styled correctly in the Properties lexer.
- Scintilla: fixed bug with wrong colors being drawn.
- Scintilla: fixed font leak.
- Scintilla: fixed automatic scrolling for wrapped lines.
- Scintilla: fixed multiple selection typing when selections collapse.
- Scintilla: expand folds when needed in word wrap mode.
- Scintilla: fixed edge line drawing for wrapped lines.
- Scintilla: fixed unnecessary scrolling in `buffer:goto_line()`.
- Scintilla: fixed undo functionality when deleting within virtual space.

Changes:

- Added support for [GTK][] 3.0.
- Use ID generator [functions][] for marker, indicator, and user list IDs.
- Scintilla: added [`buffer:set_empty_selection()`][] for setting selections without scrolling
  or redrawing.
- Scintilla: added new `buffer.INDIC_DASH`, `buffer.INDIC_DOTS`, and `buffer.INDIC_SQUIGGLELOW`
  indicators.
- Scintilla: added option to allow margin clicks to select wrapped lines.
- Updated to [Scintilla][] 2.27.
- Use string constants for event names.
- Compile and run commands [emit events][].
- Enhanced Luadoc and Lua Adeptsense.
- Added `fold.line.comments` property for folding multiple single-line comments.
- Use [GTK][] 2.22 on Windows.
- Can localize the labels and buttons in the GUI [find][] frame.
- Added ConTeXt lexer and updated Coffeescript, HTML, LaTeX, and TeX lexers.
- Multiple single-line comments can be folded with the `fold.line.comments` property set to `1`.

[GTK]: https://gtk.org
[functions]: api.html#_SCINTILLA
[`buffer:set_empty_selection()`]: api.html#buffer.set_empty_selection
[Scintilla]: https://scintilla.org
[emit events]: api.html#events.COMPILE_OUTPUT
[find]: api.html#ui.find

### 3.8 (11 Jun 2011)

Bugfixes:

- Removed non-existant key chain.
- Fixed bug in snippets.
- Fixed bug in lexers that fold by indentation.
- Scintilla: fixed indentation guide drawing on the first line.
- Scintilla: fixed display of folds for wrapped lines.
- Scintilla: fixed various GTK-related bugs.

Changes:

- Updated Adeptsense and documentation.
- `events.handlers` is accessible.
- Added menu mnemonics for indentation size.
- Added support for indicator and hotspot [events][].
- Updated [documentation][] for installing [official modules][].
- Scintilla: allow highlighting of margin symbols for the current folding block.
- Scintilla: added [`buffer:move_selected_lines_up()`][] and
  [`buffer:move_selected_lines_down()`][] for moving lines.
- Scintilla: added new `buffer.INDIC_STRAIGHTBOX` indicator.
- Scintilla: indicators can be used for brace matching.
- Scintilla: translucency can be changed for `buffer.INDIC_*BOX` indicators.
- Scintilla: improved text drawing and measuring.
- Updated to [Scintilla][] 2.26.
- Writing custom folding for lexers is much [easier][] now.
- Added native folding for more than 60% of existing lexers. The rest still use folding by
  indentation by default.
- Added regex support for Coffeescript lexer.
- Embed Coffeescript lexer in HTML lexer.

[events]: api.html#events
[documentation]: manual.html#getting-modules
[official modules]: https://github.com/orbitalquark/textadept-modules
[`buffer:move_selected_lines_up()`]: api.html#buffer.move_selected_lines_up
[`buffer:move_selected_lines_down()`]: api.html#buffer.move_selected_lines_down
[Scintilla]: https://scintilla.org
[easier]: api.html#code-folding

### 3.7 (01 May 2011)

Bugfixes:

- Fixed bug in `buffer:get_lexer()`.

Changes:

- Changed Mac OSX Adeptsense complete key command from `~` to `Ctrl+Escape`.
- Added PHP module.

### 3.7 beta 3 (01 Apr 2011)

Bugfixes:

- Small Adeptsense bugfixes.
- Snapopen respects filesystem encoding.
- Standard input dialogs have "Cancel" button by default.
- Scintilla: fixed performance with the caret on a long line.

Changes:

- Adeptsense tweaks for better completion and apidoc support.
- Language modules load a user `post_init.lua` script if it exists.
- Added Ruby on Rails lexer and module.
- Added RHTML module.
- Updated mime-types and prioritize by shebang, pattern, and then file extension.
- `buffer:get_lexer(true)` returns the lexer at the caret position.
- Adeptsense can be triggered in embedded lexers now.
- Added C standard library and Lua C API to C/C++ Adeptsense.
- Lua module fields are now in Lua Adeptsense.
- Updated to [Scintilla][] 2.25.
- Rewrote [`_m.textadept.snippets`][] with syntax changes.
- `Alt+I` (`Ctrl+I` on Mac OSX) is now "Select Snippet" instead of "Show Style". "Show Style"
  is now `Ctrl+Alt+Shift+I` (`Ctrl+Apple+Shift+I`).
- Adeptsense can exclude types matched by `sense.syntax.type_declarations` patterns.
- `Ctrl+T, V` (`Apple+T, V` on Mac OSX) keychain for toggling whitespace, wrap, etc. is now
  `Ctrl+Shift+B` (`Apple+Shift+B`).
- Key bindings and menu definition syntax changed.
- Snapopen allows for multiple-selection.
- `gui.print()` handles `nil` and non-string arguments properly.
- Officially supported modules have their own [repository][] and are available as a separate
  download.
- Added cancel button to standard dialogs.

[Scintilla]: https://scintilla.org
[`_m.textadept.snippets`]: api.html#textadept.snippets
[repository]: https://github.com/orbitalquark/textadept-modules

### 3.7 beta 2 (01 Mar 2011)

Bugfixes:

- Fixed bug with Windows paths in Adeptsense `goto_ctag()`.
- Adeptsense could not recognize some symbols.
- Handle `\n` sequences correctly in Adeptsense apidoc.
- Fixed bug with Adeptsense C/C++ type declarations.
- Adeptsense can now recognize more than 1 level of inheritence.
- Keychain is cleared on key command error.
- Fixed infinite loop bug in `_m.textadept.editing.select_scope()`.
- Fixed bug with nested embedded lexers.
- Scintilla: fixed memory leak.
- Scintilla: fixed double-click behavior around word boundaries.
- Scintilla: right-click cancels autocompletion.
- Scintilla: fixed some virtual space problems.
- Scintilla: fixed unnecessary redrawing.
- Scintilla: fixed rectangular selection creation performance.

Changes:

- Scintilla: `events.UPDATE_UI` now occurs when scrolling.
- Scintilla: added per-margin mouse cursors.
- Updated to [Scintilla][] 2.24.
- Updated mime-types.
- Line margin width is now `4`.
- Adeptsense completion list images are accessible via scripts.
- Added class context completion to Adeptsense.
- Added class type-inference through variable assignment to Adeptsense.
- Added Adeptsense tutorial.
- Added `_m.textadept.adeptsense.always_show_globals` setting for showing globals in completion
  lists.
- `Ctrl+H` (highlight word) is now `Ctrl+Shift+H`.
- `Ctrl+H` now shows Adeptsense documentation.
- Added Adeptsense `complete()` and `show_documentation()` functions to the menu.
- Language modules condensed into single `init.lua` file.
- Added `sense.syntax.word_chars` to Adeptsense.
- Included libpng12 build for 64-bit Debian-based Linux distros (Ubuntu).
- Added CSS, HTML, Java, and Ruby modules with Adeptsenses.
- Updated BibTeX lexer.

[Scintilla]: https://scintilla.org

### 3.7 beta (01 Feb 2011)

Bugfixes:

- `update_ui` is called properly for `buffer_new` and `view_new` events.
- Use proper pointer type for Scintilla calls.
- Fixed bug with loading lexers from `_USERHOME` on Windows.

Changes:

- More informative error message for unfocused buffer.
- Added Adeptsense, a smarter form of autocompletion for programming languages.
- Emit a `language_module_loaded` as appropriate.
- Added indentation settings to "Buffer" menu (finally).
- Added `gui.filteredlist()` shortcut for `gui.dialog('filteredlist', ...)`.
- Can navigate between bookmarks with a filteredlist.
- Language-specific [`char_matches`][] and `braces` can be defined.
- `command_entry_keypress` event accepts modifier keys.
- Updated BibTeX and Lua lexers.

[`char_matches`]: api.html#textadept.editing.auto_pairs

### 3.6 (01 Jan 2011)

Bugfixes:

- Fixed infinite recursion errors caused in events.
- Fix statusbar update bug with key chains.
- Do not emit `buffer_new` event when splitting the view.
- Fixed comment bug in Caml lexer.

Changes:

- `buffer.rectangular_selection_modifier` on Linux is the Super/Windows key.
- Improved HTML lexer.
- Added Markdown, BibTeX, CMake, CUDA, Desktop Entry, F#, GLSL, and Nemerle lexers.
- Added [`_m.textadept.filter_through`][] module for [shell commands][].
- Moved GUI events from `core/events.lua` to `core/gui.lua`.
- Separated key command manager from key command definitions.

[`_m.textadept.filter_through`]: api.html#textadept.editing.filter_through
[shell commands]: manual.html#shell-commands-and-filtering-text

### 3.5 (01 Dec 2010)

Bugfixes:

- Fixed bug introduced when exposing Find in Files API.
- Fixed bug in Tcl lexer with comments.

Changes:

- Lua files are syntax-checked for errors on save.
- [Menus][] are easier to create.
- Changed `_m.textadept.editing.enclose()` behavior.
- Windows and Mac OSX packages are all-in-one bundles; GTK is no longer an external dependency.
- New [manual][].
- Added [`file_after_save`][] event.

[Menus]: api.html#textadept.menu
[manual]: manual.html
[`file_after_save`]: api.html#events.FILE_AFTER_SAVE

### 3.4 (01 Nov 2010)

Bugfixes:

- Fixed menu item conflicts.
- Pressing `Cancel` in the [Switch Buffers][] dialog does not go to the selected buffer anymore.
- Autocomplete lists sort properly for machines with a different locale.
- Statusbar is not cleared when set from a key command.
- Unreadable files are handled appropriately.
- Scintilla: fixed scrolling bug where caret was not kept visible.
- Scintilla: fixed caret position caching after autocompletion.
- Scintilla: fixed paging up/down in virtual space.
- Scintilla: fixed crash with negative arguments passed to `buffer:marker_add()` and
  `buffer:marker_add_set()`.
- Scintilla: dwell notifications are not emitted when the mouse is outside the view.

Changes:

- Multi-language lexers (HTML, PHP, RHTML, etc.) are processed as fast as single language ones,
  resulting in a huge speed improvement.
- An `update_ui` event is triggered after a Lua command is entered.
- `gui.dialog()` can take tables of strings as arguments now.
- [`_m.textadept.snapopen.open()`][] takes a recursion depth as a parameter and falls back on a
  `DEFAULT_DEPTH` if necessary.
- Removed `_m.textadept.editing.smart_cutcopy()` and `_m.textadept.editing.squeeze()` functions.
- Added `_m.textadept.editing.SAVE_STRIPS_WS` option to disable strip whitespace on save.
- Changed locale implementation. Locale files are much easier to create now.
- `gui.statusbar_text` is now readable instead of being write-only.
- Can [highlight][] all occurances of a word.
- Added jsp lexer.
- More consistant handling of `\` directory separator for Windows.
- Consolidated `textadept.h` and `lua_interface.c` into single `textadept.c` file.
- Added [`_G.timeout()`][] function for calling functions and/or events after a period of time.
- Find in files is accessible through [find API][].
- Updated XML lexer.
- Added `search-column` and `output-column` options for filteredlist dialogs.
- Scintilla: added [`buffer:contracted_fold_next()`][] for retrieving fold states.
- Scintilla: added `buffer:vertical_centre_caret()`.
- Updated to [Scintilla][] 2.22.
- Renamed `_G.MAC` to [`_G.OSX`][].

[Switch Buffers]: manual.html#buffers
[`_m.textadept.snapopen.open()`]: api.html#io.quick_open
[highlight]: manual.html#word-highlight
[`_G.timeout()`]: api.html#timeout
[find API]: api.html#ui.find.find_in_files
[`buffer:contracted_fold_next()`]: api.html#buffer.contracted_fold_next
[Scintilla]: https://scintilla.org
[`_G.OSX`]: api.html#OSX

### 3.3 (01 Oct 2010)

Bugfixes:

- Fixed buggy snippet menu.
- Comments do not need to begin the line in Properties lexer.

Changes:

- Added [`_m.textadept.snapopen`][] module with menu options for rapidly opening files.
- Added coffeescript lexer.
- Updated D and Java lexers.

[`_m.textadept.snapopen`]: api.html#io.quick_open

### 3.2 (01 Sep 2010)

Bugfixes:

- Fixed "Replace All" infinite loop bug.
- Handle strings properly in Groovy and Vala lexers.
- Scintilla: fixed drawing bug after horizontally scrolling too much.
- Scintilla: fixed various folding bugs.

Changes:

- Updated to the new Scintillua that does not required patched Scintilla.
- Updated to [Scintilla][] 2.21.

[Scintilla]: https://scintilla.org

### 3.1 (21 Aug 2010)

Bugfixes:

- Fixed memory leak in Mac OSX.
- Scintilla: fixed crash when searching for empty strings.
- Scintilla: fixed lexing and folding bugs when pressing enter at the beginning of a line.
- Scintilla: fixed bug in line selection mode.
- Scintilla: fixed alpha indicator value ranges.
- Scintilla: fixed compiler errors for some compilers.
- Scintilla: fixed memory leak in autocompletion and user lists.

Changes:

- Refactored key commands to support propagation.
- Updated TeX lexer.
- Only highlight C/C++ preprocessor words, not the whole line.
- Scintilla: added new `buffer.CARETSTICKY_WHITESPACE` caret sticky option.
- Scintilla: lexing improvements.
- Updated to [Scintilla][] 2.20.
- Added Lua autocompletion.

[Scintilla]: https://scintilla.org

### 3.0 (01 Jul 2010)

Please see the [2 to 3 migration guide][] for upgrading from Textadept 2 to Textadept 3.

Bugfixes:

- None

Changes:

- More accurate CSS and Diff lexers.

[2 to 3 migration guide]: manual.html#textadept-2-to-3

### 3.0 beta (21 Jun 2010)

Bugfixes:

- Fixed Mac OSX paste issue.
- Fixed `buffer:text_range()` argcheck problem.
- Differentiate between division and regex in Javascript lexer.
- Fixed bug with child's main lexer not having a `_tokenstyles` table.
- Scintilla: fixed flashing while scrolling.
- Scintilla: fixed marker movement when inserting newlines.
- Scintilla: fixed middle-click paste in block-selection mode.
- Scintilla: fixed selection bounds returned for rectangular selections.
- Scintilla: fixed case-insensitive searching for non-ASCII characters.
- Scintilla: fixed bad-UTF-8 byte handling.
- Scintilla: fixed bug when rectangular selections were extended into multiple selections.
- Scintilla: fixed incorrect caret placement after scrolling.
- Scintilla: fixed text disappearing after wrapping bug.
- Scintilla: fixed various regex search bugs.
- Scintilla: improved scrolling performance.
- Scintilla: fixed `Shift+Tab` handling for rectangular selection.

Changes:

- Remove initial "Untitled" buffer when necessary.
- Moved core extension modules into [`textadept`][] module.
- New [API][].
- `~/.textadept/init.lua` is created for you if one does not exist.
- No more autoload of `~/.textadept/key_commands.lua` and `~/.textadept/snippets.lua`
- Updated Java and D lexers.
- Scintilla: added [`buffer.multi_paste`][] for pasting into multiple selections.
- Updated to [Scintilla][] 2.12.
- [Abbreviated][] Lua commands in the command entry.
- Dynamic command line [arguments][].
- Added statusbar notification on `reset()`.
- Added Gtkrc, Prolog, and Go lexers.

[`textadept`]: api.html#textadept
[API]: api.html
[`buffer.multi_paste`]: api.html#buffer.multi_paste
[Scintilla]: https://scintilla.org
[Abbreviated]: manual.html#lua-command-entry
[arguments]: api.html#args

### 2.2 (11 May 2010)

Bugfixes:

- Save buffer before compiling or running.
- Fixed error in the manual for `~/.textadept/init.lua` example.
- Ignore `file://` prefix for filenames.

Changes:

- `_USERHOME` comes before `_HOME` in `package.path` so `require` searches `~/.textadept/` first.

### 2.2 beta 2 (01 May 2010)

Bugfixes:

- Fixed crash with `buffer:text_range()`.
- Fixed snippets bug with `%n` sequences.
- Respect tab settings for snippets.
- Fixed help hanging bug in Windows.
- Fixed Lua module commands bug.
- Fixed bug with style metatables.
- Fixed bug with XML namespaces.

Changes:

- Added BSD support.
- Removed kill-ring from editing module.
- [Compile and Run][] commands are in language modules.
- [Block comment][] strings are in language modules now.
- Remove "Untitled" buffer when necessary.
- Moved "Search" menu into "Tools" menu to prevent `Alt+S` key conflict.
- Rewrote lexers implementation.
- Added Inform, Lilypond, and NSIS lexers.
- `_m.textadept.editing.enclosure` is now an accessible table.
- Updated D, Java, and LaTeX lexers.

[Compile and run]: api.html#textadept.run
[Block comment]: api.html#textadept.editing.comment_string

### 2.2 beta (01 Apr 2010)

Bugfixes:

- Fixed transform bug in snippets.
- Fixed bug with Io lexer mime-type.
- Fixed embedded css/javascript bug in HTML lexer.
- Fixed bug in multi-language lexer detection.

Changes:

- Removed `_m.textadept.mlines` module since Scintilla's multiple selections supercedes it.
- Removed side pane.
- New `gui.dialog('filteredlist', ...)` from gtdialog.
- Can select buffer from filteredlist dialog (replacing side pane buffer list).
- Can select lexer from filteredlist dialog.
- Can have user `key_commands.lua`, `snippets.lua`, `mime_types.conf`, `locale.conf` that are
  loaded by their respective modules.
- Added Matlab/Octave lexer and updated Haskell lexer.
- Backspace deletes auto-inserted character pairs.
- Added notification for session files not found.
- Snippets use multiple carets.
- Removed api file support.

### 2.1 (01 Mar 2010)

Bugfixes:

- Do not close files opened from command line when loading PM session.
- Fixed bug for running a file with no path.
- Fixed error message for session file not being found.
- Fixed key command for word autocomplete on Windows.
- Changed conflicting menu shortcut for Lexers menu.
- Fixed typos in templates generated by modules PM browser.
- Scintilla: fixed crash after adding an annotation and then adding a new line below it.
- Scintilla: fixed `buffer:get_sel_text()`.
- Scintilla: fixed some instances of text positioning.
- Scintilla: fixed various problems with rectangular selections and rectangular pastes.
- Scintilla: fixed some instances of navigation through and display of wrapped lines.
- Scintilla: fixed drag and drop.
- Scintilla: fixed extra background styling at the end of the buffer.
- Scintilla: fixed crash when adding markers to non-existant lines.
- Scintilla: fixed indentation guide drawing over text in some cases.

Changes:

- Added Dot and JSON lexers.
- Search `_USERHOME` in addition to `_HOME` for themes.
- Added command line option for not loading/saving session.
- Modified key bindings to be more key-layout agnostic.
- Added `reset_before` and `reset_after` events while `textadept.reset()` is being run.
- Reload current lexer module after `textadept.reset()`.
- Added `~/.textadept/modules/` to `package.path`.
- Scintilla: added support for multiple selections and virtual space.
- Scintilla: `buffer.first_visible_line` is no longer read-only.
- Scintilla: added [`buffer.whitespace_size`][] for changing the size of visible whitespace.
- Scintilla: added [`buffer.auto_c_current_text`][] for retrieving the currently selected
  autocompletion text.
- Updated to [Scintilla][] 2.03.
- Modified quit and close dialogs to be more readable.

[`buffer.whitespace_size`]: api.html#buffer.whitespace_size
[`buffer.auto_c_current_text`]: api.html#buffer.auto_c_current_text
[Scintilla]: https://scintilla.org

### 2.0 (01 Oct 2009)

Bugfixes:

- Fixed bug with reloading PM width from session file.
- Only show a non-nil PM context menu.
- Fixed bug in `modules/textadept/lsnippets.lua`.
- Fixed bug in `core/ext/mime_types.lua` caused during `textadept.reset()`.
- Close all buffers before loading a session.
- Identify `shellscript` files correctly.
- D lexer no longer has key-command conflicts.

Changes:

- Refactored `modules/textadept/lsnippets.lua`.
- Updated key bindings.
- Allow PM modules in the `~/.textadept` user directory.
- Added [`style_whitespace`][] to [lexers][] for custom styles.
- Added standard `F3` key command for "Find Next" for Windows/Linux.

[`style_whitespace`]: api.html#lexer.STYLE_WHITESPACE
[lexers]: api.html#lexer

### 2.0 beta (31 Jul 2009)

Bugfixes:

- Alphabetize lexer list.
- Fixed some locale issues.
- Fixed some small memory leaks.
- Try a [list of encodings][] rather than just UTF-8 so "conversion failed" does not happen
  so often.
- Restore a manually set lexer.

Changes:

- Removed `_m.textadept.macros` module and respective PM browser (use Lua instead).
- Linux version can be installed and run from anywhere; no need to recompile anymore.
- Added many more [events][] to hook into lots of core functionality.
- Updated to [Scintilla][] 1.79.
- Run module allows more flexible [compile commands][] and [run commands][].
- Save project manager cursor over sessions.
- Allow mime-types and compile and run commands to be user-redefinable in user scripts.
- Use `~/.textadept/` for holding user lexers, themes, sessions, etc.
- Added "Help" menu linking to Manual and LuaDoc.
- Textadept compiles as C99 code. (Drops Microsoft Visual Studio support.)
- Sessions functionality moved to `modules/textadept/session.lua` from `core/file_io.lua`.
- The `char_added` event now passes an int, not a string, to handler functions.
- Replaced cocoaDialog and lua_dialog with my C-based gtdialog.
- [Incremental find][] via the Lua command entry.
- *NO* dependencies other than [GTK][] on _all_ platforms.
	+ Windows no longer requires the MSVC++ 2008 Runtime.
	+ Linux no longer requires `libffi`.
	+ Mac OSX no longer requires cocoaDialog.
- Can cross compile to Windows from Linux.
- Removed confusing `local function` and `local table` LuaDoc.
- Rewrote the manual and most of the documentation.

[list of encodings]: api.html#io.encodings
[events]: api.html#events
[Scintilla]: https://scintilla.org
[compile commands]: api.html#textadept.run.compile_commands
[run commands]: api.html#textadept.run.run_commands
[Incremental find]: manual.html#incremental-find
[GTK]: https://gtk.org

### 1.6 (01 Apr 2009)

Bugfixes:

- Fixed `NULL` byte bug associated with Lua interface due to multi-encoding support.
- Find marker is colored consistently.
- Fixed issue with buffer browser cursor saving.
- Fixed block character insertion issue on GTK-OSX.

Updates:

- Trimmed theme files.
- Added [`file_before_save`][] event.

[`file_before_save`]: api.html#events.FILE_BEFORE_SAVE

### 1.6 beta (01 Mar 2009)

Bugfixes:

- Fixed bookmarks bugs.
- PM browsers are not re-added to the list again on `textadept.reset()`.
- Fixed ctags PM browser bug with filenames.
- Marker colors are set for all views now.
- Fixed never-ending "reload modified file?" dialog bug.
- Fixed key command for `m_snippets.list`.
- Fixed issues with `_m.textadept.run` module.
- Fixed document modification status bug for unfocused split views.
- Fixed filename encoding issues for Windows.

Updates:

- Added key bindings and menu items to navigate "Find in Files" list.
- The `recent_files` popup list behaves better.
- Attempt to preserve existing EOL mode for opened files.
- Add drag-and-dropped directories to the PM browser list.
- Removed `project` PM browser.
- Multiple character encoding support for opening and saving files.

### 1.5 (20 Feb 2009)

Bugfixes:

- Fixed some corner cases in Find in Files user interface.
- Fixed some OSX key command issues for consistency.
- Fixed some key command modifiers for "enclose in" series.

Updates:

- Consolidated *core/ext/key_commands_{std,mac}.lua* into single *core/ext/key_commands.lua*.
- Can use the `Tab` and `Shift+Tab` keys for snippets now.
- Removed support for Textmate-style snippets in favor of Lua-style snippets.
- Load drag-and-dropped directories into file browser.
- Can toggle showing "dot" files in file browser.
- Prompt for file reload when files are modified outside Textadept.
- Added `textadept.context_menu` field for right-click inside Scintilla.
- Project Manager cursors are saved and restored.
- Only use escape sequences in Lua pattern searches.
- Rewrote *modules/textadept/run.lua* to be easier to use and configure.
- Find in Files marks the selected line for easier reference.
- Save special buffers in session file (e.g. error buffer, message buffer, etc.)
- Moved mime-types into *core/ext/mime_types.conf* configuration file.
- Moved localization into *core/locale.conf* configuration file.

### 1.4 (10 Feb 2009)

Bugfixes:

- Handle empty clipboard properly.
- Fixed some widget focus issues.
- Fixed a couple Find in Files bugs.
- Workaround for GTK-OSX pasting issue.

Updates:

- Added menu options for changing line endings.
- The Project Manager Entry responds better.
- Improved Lua State integrity for critical data.
- Keep only 10 items in Find/Replace history.
- Special buffers are not "Untitled" anymore.
- Moved `textadept.locale` table to `_G`.

### 1.3 (30 Jan 2009)

Bugfixes:

- Binary files are opened and handled properly.
- Drag-and-dropped files are now opened in the correct split view they were dropped in.
- Fixed some various GTK-OSX UI issues.
- Fixed a special case of "Replace All".
- Clicking "Ok" closes any error dialogs on init.
- Fixed statusbar glitch when creating new buffers.
- Windows' CR+LF line endings are handled properly.
- Do not go to non-existent buffer index when loading session.
- Do not attempt to open non-existent files when double-clicking error messages.

Updates:

- Look for `~/.ta_theme` for setting Textadept `_THEME`.
- `_THEME` can now be a directory path.
- Themes now contain their own *lexer.lua* for defining lexer colors.
- Added "Find in Files" support.
- Can set the Project Manager cursor through Lua.
- Look for *~/.ta_modules* to load instead of default modules in *init.lua*.
- Added "Replace All" for just selected text.
- Removed menu label text in favor of using menu id numbers for menu actions.
- Added Find/Replace history.
- Use a combo entry for the Project Manager browser entry.
- Print messages to a split view instead of switching buffers.

### 1.2 (21 Jan 2009)

Bugfixes:

- None.

Updates:

- Windows command line support ("Open With Textadept" works too).
- New [`_m.textadept.run`][] module for compiling and running programs. Output is displayed in
  a message buffer and you can double-click errors and warnings to go to them in the source file.

[`_m.textadept.run`]: api.html#textadept.run

### 1.1 (11 Jan 2009)

Bugfixes:

- Fixed *core/ext/key_commands_std.lua* key conflict (`Ctrl+V`).

Updates:

- Dramatic speed increase in lexing for large, single-language files.
- Added [localization][] support.
- Added [bookmarks][] support.
- All `require` statements have been moved to *init.lua* for easy module configuration.
- Various improvements to efficiency, speed, and readability of source code.
- Manually parse *~/.gtkrc-2.0* on Mac since GTK-OSX does not do it.

[localization]: api.html#_L
[bookmarks]: api.html#textadept.bookmarks

### 1.0 (01 Jan 2009)

Bugfixes:

- Fixed bug with placeholders in Lua-style snippets.
- Fixed view grow/shrink error thrown when the view is not split.
- Various fixes to recognize windows directory separators.
- Fixed some Find bugs.
- Fixed macro recording and playback bugs.

Updates:

- Added actions for all menu items.
- Added Lua interface functions and fields for the [find][] box.
- Nearly full Mac OSX support with [GTK-OSX][].
- Compile [LPeg][] and [LuaFileSystem][] libraries into Textadept by default.
- Use UTF-8 encoding by default.
- Added `light` color theme used by default.
- New Textadept icons.
- Added a true project manager.

[find]: api.html#ui.find
[GTK-OSX]: https://www.gtk.org/download/macos.php
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[LuaFileSystem]: https://keplerproject.github.com/luafilesystem/

### 0.6 (03 Oct 2008)

Bugfixes:

- Gracefully exit when *core/init.lua* fails to load.

Updates:

- Windows support! (finally)
- [Theming][] support (SciTE theme used by default).
- Added `textadept.size` field and save it in session files.
- Some C++ API-simplifying changes.
- Drag-and-drop files into Textadept works as expected.
- Revised [manual][].
- Buffer and View properties are no longer set in C++, but in Lua through "buffer_new" and
  "view_new" event handlers respectively.
- File types can be recognized by [pattern matching][] the first line.

[Theming]: manual.html#themes
[manual]: manual.html
[pattern matching]: manual.html#file-types

### 0.5 (23 Jul 2008)

Bugfixes:

- Fixed bug in Lua module when there is no matching file to go to.

Updates:

- Added user-friendly key bindings and menus.
- Added 43 more lexers.
- Moved block-comment commands from language modules to `textadept.editing` module.
- Updated some Luadoc.

### 0.4 (25 Jun 2008)

Bugfixes:

- Fixed bug with "%" being contained in text to replace.
- Fixed compile warnings.
- Fixed bug for menu actions on non-focused buffer.

Updates:

- Added [bookmark][] support through *modules/textadept/bookmarks.lua* (not loaded by default).
- Added icons to Textadept.
- Added a modules browser for adding, deleting, and editing modules easily.
- Consolidated source files into *textadept.c*, *textadept.h*, and *lua_interface.c*.
- Always load project manager settings from session file if available.
- Include *liblua5.1.a* for compiling Lua into Textadept.
- Added true [tab-completion][] to Lua command entry.
- Added Doxygen documentation for C source files.
- Updated Luadoc, and added Textadept manual.

[bookmark]: api.html#textadept.bookmarks
[tab-completion]: manual.html#command-entry-tab-completion

### 0.3 (04 Mar 2008)

Bugfixes:

- Fixed bug in editing module's `select_indented_block()`.
- Fixed empty `buffer.filename` bug in `textadept.io.save_as()`.
- Fixed setting of Ruby lexer after detecting filetype.

Updates:

- Makefile builds Textadept to optimize for small size.
- Lua is no longer an external dependency and built into Textadept.
- Zenity is no longer a dependency on Linux. lua_dialog is used instead.
- Resources from `io.popen()` are handled more appropriately.
- Added `textadept.reset()` function for for reloading Lua scripts.
- Added new find in files project manager browser.
- Fixed some code redundancy and typos in documentation.

### 0.2 (20 Dec 2007)

Bugfixes:

- Fixed command line parameters bug.
- Fixed `package.path` precedence bug.
- Use 8 style bits by default.

Updates:

- Scintilla-st.
- Lexers.
- Improved support for embedded language-specific snippets.

### 0.1 (01 Dec 2007)

Initial Release

# Textadept 12.7 nightly API Documentation

1. [_G](#_G)
2. [_L](#_L)
3. [args](#args)
4. [buffer](#the-buffer-module)
5. [events](#events)
6. [io](#io)
7. [keys](#the-keys-module)
8. [lexer](#lexer)
9. [lfs](#lfs)
10. [os](#os)
11. [string](#string)
12. [table](#table)
13. [textadept](#textadept)
14. [textadept.bookmarks](#textadept.bookmarks)
15. [textadept.clipboard](#textadept.clipboard)
16. [textadept.editing](#textadept.editing)
17. [textadept.history](#textadept.history)
18. [textadept.keys](#textadept.keys)
19. [textadept.macros](#textadept.macros)
20. [textadept.menu](#textadept.menu)
21. [textadept.run](#textadept.run)
22. [textadept.session](#textadept.session)
23. [textadept.snippets](#textadept.snippets)
24. [ui](#ui)
25. [ui.command_entry](#ui.command_entry)
26. [ui.dialogs](#ui.dialogs)
27. [ui.find](#ui.find)
28. [view](#the-view-module)

<a id="_G"></a>
## The `_G` module

Extends Lua's _G table to provide extra functions and fields for Textadept.

<a id="BSD"></a>
### `BSD`

Whether or not Textadept is running on BSD.

<a id="CURSES"></a>
### `CURSES`

Whether or not Textadept is running in a terminal.

<a id="GTK"></a>
### `GTK`

Whether or not Textadept is running as a GTK GUI application.

<a id="LINUX"></a>
### `LINUX`

Whether or not Textadept is running on Linux.

<a id="OSX"></a>
### `OSX`

Whether or not Textadept is running on macOS.

<a id="QT"></a>
### `QT`

Whether or not Textadept is running as a Qt GUI application.

<a id="WIN32"></a>
### `WIN32`

Whether or not Textadept is running on Windows.

<a id="_BUFFERS"></a>
### `_BUFFERS`

Table of all open buffers in Textadept.

Numeric keys have buffer values and buffer keys have their associated numeric keys as values.

Usage:

```lua
local buffer = _BUFFERS[n] -- buffer at index n
local i = _BUFFERS[buffer] -- index of buffer in _BUFFERS
```

See also: [`buffer`](#buffer)

<a id="_CHARSET"></a>
### `_CHARSET`

The filesystem's character encoding.

This really only matters on Windows, where there is a mismatch between the UI encoding
(UTF-8), and the filesystem encoding (non-UTF-8).

Usage:

```lua
local utf8_filename = buffer.filename:iconv('UTF-8', _CHARSET)
local f = io.open(utf8_filename:iconv(_CHARSET, 'UTF-8'))
```

See also: [`string.iconv`](#string.iconv)

<a id="_COPYRIGHT"></a>
### `_COPYRIGHT`

Textadept's copyright information.

<a id="_HOME"></a>
### `_HOME`

The path to Textadept's home, or installation, directory.

<a id="_LEXERPATH"></a>
### `_LEXERPATH`

A ';'-separated list of directory paths that contain lexers for syntax highlighting.

The default value contains *~/.textadept/lexers/* and Textadept's *lexers/* directory.

<a id="_RELEASE"></a>
### `_RELEASE`

The Textadept release version string.

<a id="_THEME"></a>
### `_THEME`

Textadept's current UI mode, either "light" or "dark".

Manually changing this field has no effect. It is used internally to set a theme on startup
based on the current OS theme.

See also: [`view.set_theme`](#view.set_theme), [`events.MODE_CHANGED`](#events.MODE_CHANGED)

<a id="_USERHOME"></a>
### `_USERHOME`

The path to the user's *~/.textadept/* directory, where all preferences and user-data is stored.

On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
*C:\Users\username\\*). On macOS and Linux/BSD machines *~/* is the value of "$HOME"
(typically */Users/username/* and */home/username/*, respectively).

<a id="_VIEWS"></a>
### `_VIEWS`

Table of all views in Textadept.

Numeric keys have view values and view keys have their associated numeric keys as values.

Usage:

```lua
local view = _VIEWS[n] -- view at index n
local i = _VIEWS[view] -- index of view in _VIEWS
```

See also: [`view`](#view)

<a id="arg"></a>
### `arg`

Table of command line parameters passed to Textadept, just like in Lua.

See also: [`args`](#args)

<a id="assert"></a>
### `assert`(*v*[, *message*='assertion failed!'[, ...]])

Asserts a value is truthy or raises an error.

Parameters:
- *v*:  Value to assert is not `false` or `nil`.
- *message*:  Message to show on error. It need not be a string.
- *...*:  If *message* is a format string, these arguments are passed to
	`string.format()` and the result is the error message to show.

Returns: *v*

<a id="assert_type"></a>
### `assert_type`(*v*, *expected_type*, *narg*)

Asserts that a value has an expected type or raises an error.

Use this with API function arguments so users receive more helpful error messages.

Parameters:
- *v*:  Value to assert the type of.
- *expected_type*:  String type to assert. Multiple types are allowed, separated by
	non-letter characters.
- *narg*:  Positional argument number or string table field name associated with *v* . An
	error message will reference this.

Returns: *v*

Usage:

```lua
assert_type(filename, 'string/nil', 1) -- assert first arg is optional string
assert_type(option.setting, 'number', 'setting') -- assert 'setting' field is a number
```

<a id="_G.buffer"></a>
### `buffer`

The current [buffer](#the-buffer-module) in the [current view](#_G.view).

<a id="is_hidpi"></a>
### `is_hidpi`()

Returns whether or not Textadept is currently running on a HiDPI/Retina display.

<a id="_G.keys"></a>
### `keys`

Textadept's [key bindings](#the-keys-module), a map of key shortcuts to commands or key chains.

Language-specific keys are in subtables assigned to lexer names.

Usage:

```lua
keys['ctrl+n'] = buffer.new
keys.c['shift+\n'] = function() -- language-specific key
	buffer:line_end()
	buffer:add_text(';')
	buffer:new_line()
end
```

<a id="move_buffer"></a>
### `move_buffer`(*from*, *to*)

Moves buffers within the [`_BUFFERS`](#_BUFFERS) table, changing their display order in the tab bar and
buffer browser.

Parameters:
- *from*:  Index of the buffer to move.
- *to*:  Index to move the buffer to.

<a id="quit"></a>
### `quit`([*status*=0[, *events*=true]])

Attempts to quit Textadept.

Parameters:
- *status*:  Status code for Textadept to exit with.
- *events*:  Emit [`events.QUIT`](#events.QUIT), which could prevent quitting. Passing
	`false` could result in data loss.

<a id="reset"></a>
### `reset`()

Resets Textadept's Lua State by reloading all initialization scripts.

This allows for testing theme and user script modifications (e.g. *~/.textadept/init.lua*)
without having to restart Textadept.

[`arg`](#arg) is `nil` during re-initialization. Scripts that need to differentiate between startup
and reset can test [`arg`](#arg).

See also: [`events.RESET_BEFORE`](#events.RESET_BEFORE), [`events.RESET_AFTER`](#events.RESET_AFTER)

<a id="snippets"></a>
### `snippets`

Map of [snippet](#textadept.snippets) triggers to snippet text or functions that return
such text.

Language-specific snippets are in subtables assigned to lexer names.

Usage:

```lua
snippets.foo = 'bar'
snippets.lua.f = 'function ${1:name}($2)\n\t$0\nend' -- language-specific snippet
```

<a id="timeout"></a>
### `timeout`(*interval*, *f*[, ...])

Calls a function after a timeout interval.

Terminal version note: timeout functions will not be called until an active Find & Replace
pane session finishes, or until an active dialog closes.

Parameters:
- *interval*:  Interval in seconds to call *f* after.
- *f*:  Function to call. If it returns `true`, it will be called again after *interval*
	seconds.
- *...*:  Additional arguments to pass to *f*.

<a id="_G.view"></a>
### `view`

The current [view](#the-view-module).



<a id="_L"></a>
## The `_L` module

Map of all messages used by Textadept to their localized forms.

If the localized form of a given message does not exist, the non-localized message is
returned. Use Lua's `rawget()` to check if a localization exists.

Terminal version note: any "_" or "&" mnemonics the GUI version would use are ignored.



<a id="args"></a>
## The `args` module

Processes command line arguments for Textadept.

You can register your own command line arguments. For example:

```lua
args.register('-r', '--read-only', 0, function()
	events.connect(events.FILE_OPENED, function()
		buffer.read_only = true -- make all opened buffers read-only
	end)
	textadept.menu.menubar = nil -- hide the menubar
end, "Read-only mode")
```

Running `textadept -r file.txt` will open that and all subsequent files in read-only mode.

<a id="args.register"></a>
### `args.register`(*short*, *long*, *narg*, *f*, *description*)

Registers a command line option.

Parameters:
- *short*:  String short version of the option.
- *long*:  String long version of the option.
- *narg*:  Number of expected parameters for the option.
- *f*:  Function to run when the option is set. It is passed *narg* string arguments. If *f*
	returns `true`, [`events.ARG_NONE`](#events.ARG_NONE) will ultimately not be emitted.
- *description*:  String description of the option shown in command line help.

Usage:

```lua
args.register('-r', '--read-only', 0, function() ... end, 'Read-only mode')
```



<a id="buffer"></a>
## The `buffer` module
A Textadept buffer or view object.


Any buffer and view fields set on startup (e.g. in *~/.textadept/init.lua*) will be the
default, initial values for all buffers and views.

### Contents

1. [Buffer and View Introduction](#buffer-and-view-introduction)
2. [Create Buffers and Views](#create-buffers-and-views)
3. [View Information](#view-information)
4. [Work with Files](#work-with-files)
5. [Move Within Lines](#move-within-lines)
6. [Move Between Lines](#move-between-lines)
7. [Move Between Pages](#move-between-pages)
8. [Move Between Buffers](#move-between-buffers)
9. [Other Movements](#other-movements)
10. [Retrieve Text](#retrieve-text)
11. [Set Text](#set-text)
12. [Replace Text](#replace-text)
13. [Delete Text](#delete-text)
14. [Transform Text](#transform-text)
15. [Split and Join Lines](#split-and-join-lines)
16. [Undo and Redo](#undo-and-redo)
17. [Employ the Clipboard](#employ-the-clipboard)
18. [Make Simple Selections](#make-simple-selections)
19. [Make Movement Selections](#make-movement-selections)
20. [Modal Selection](#modal-selection)
21. [Make and Modify Multiple Selections](#make-and-modify-multiple-selections)
22. [Make Rectangular Selections](#make-rectangular-selections)
23. [Simple Search](#simple-search)
24. [Search and Replace](#search-and-replace)
25. [Query Position Information](#query-position-information)
26. [Query Line and Line Number Information](#query-line-and-line-number-information)
27. [Query Measurement Information](#query-measurement-information)
28. [Configure Line Margins](#configure-line-margins)
29. [Mark Lines with Markers](#mark-lines-with-markers)
30. [Annotate Lines](#annotate-lines)
31. [Mark Text with Indicators](#mark-text-with-indicators)
32. [Display an Autocompletion or User List](#display-an-autocompletion-or-user-list)
33. [Display Images in Lists](#display-images-in-lists)
34. [Show a Call Tip](#show-a-call-tip)
35. [Fold or Hide Lines](#fold-or-hide-lines)
36. [Scroll the View](#scroll-the-view)
37. [Configure Indentation and Line Endings](#configure-indentation-and-line-endings)
38. [Configure Character Settings](#configure-character-settings)
39. [Configure the Color Theme](#configure-the-color-theme)
40. [Override Style Settings](#override-style-settings)
41. [Assign Caret, Selection, Whitespace, and Line Colors](#assign-caret,-selection,-whitespace,-and-line-colors)
42. [Configure Caret Display](#configure-caret-display)
43. [Configure Selection Display](#configure-selection-display)
44. [Configure Whitespace Display](#configure-whitespace-display)
45. [Configure Scrollbar Display and Scrolling Behavior](#configure-scrollbar-display-and-scrolling-behavior)
46. [Configure Mouse Cursor Display](#configure-mouse-cursor-display)
47. [Configure Wrapped Line Display](#configure-wrapped-line-display)
48. [Configure Text Zoom](#configure-text-zoom)
49. [Configure Long Line Display](#configure-long-line-display)
50. [Configure Fold Settings and Folded Line Display](#configure-fold-settings-and-folded-line-display)
51. [Highlight Matching Braces](#highlight-matching-braces)
52. [Configure Indentation Guide Display](#configure-indentation-guide-display)
53. [Configure File Types](#configure-file-types)
54. [Manually Style Text](#manually-style-text)
55. [Query Style Information](#query-style-information)
56. [Miscellaneous](#miscellaneous)

### Buffer and View Introduction


Internally, Textadept uses the [Scintilla][] editing component for editing text. It breaks
up Scintilla's monolithic API into two parts: buffers and views. Buffers are responsible for
text editing, selections, and navigation. Views are responsible for visual things like text
and selection display, margins, markers, and highlights. This is a best-effort attempt to
allow for sensible object-oriented scripting with an editing component that combines the data
model and view model into one entity. It is not perfect and my not make complete sense at times.

That said, this buffer and view API is largely interchangeable: `view.field` and
`view:function()` are often equivalent to `buffer.field` and `buffer:function()`, respectively,
and vice-versa.

Only one buffer and one view at a time is considered "current" (i.e. has focus). While
Textadept allows you to work with non-current buffers, you should only work with [`buffer`](#buffer)
unless you know what you are doing.  For example, [`buffer:select_all()`](#buffer.select_all) will visually
select all text in the current buffer, but `buf:select_all()` where `buf ~= buffer` will
not make a visible selection, even if `buf` is visible in another view. Despite this,
`buf:replace_sel('')` will still clear that buffer since it previously selected all text.
(Basically, you can make "background" edits of non-current buffers in an object-oriented way.)

[Scintilla]: https://scintilla.org/ScintillaDoc.html

### Create Buffers and Views

<a id="buffer.new"></a>
#### `buffer.new`()

Creates a new buffer and displays it in the current view.

Returns: the new buffer

See also: [`io.open_file`](#io.open_file), [`events.BUFFER_NEW`](#events.BUFFER_NEW)

<a id="view.split"></a>
#### `view:split`([*vertical*=false])

Splits the view and focuses the new view.

Parameters:
- *vertical*:  Split the view vertically into left and right views instead of
	splitting horizontally into top and bottom views.

Returns: old view, new view

See also: [`events.VIEW_NEW`](#events.VIEW_NEW)

<a id="view.unsplit"></a>
#### `view:unsplit`()

Unsplits the view if possible.

Returns: whether or not the view was unsplit.

### View Information

<a id="view.buffer"></a>
#### `view.buffer`

The [buffer](#the-buffer-module) the view currently contains.
(Read-only)

<a id="view.size"></a>
#### `view.size`

The split resizer's pixel position if the view is a split one.

See also: [`ui.get_split_table`](#ui.get_split_table)

<a id="view.parent_size"></a>
#### `view.parent_size`

The parent split resizer's pixel position if the view's parent is a split one.

See also: [`ui.get_split_table`](#ui.get_split_table)

### Work with Files


**Note:** this module does not open files. [`io.open_file()`](#io.open_file) does.

<a id="buffer.reload"></a>
#### `buffer:reload`()

Reloads the buffer's file contents, discarding any changes.

<a id="buffer.save"></a>
#### `buffer:save`()

Saves the buffer to its file.

If the buffer does not have a file, the user is prompted for one.

Returns: `true` if the file was saved; `nil` otherwise.

See also: [`textadept.editing.strip_trailing_spaces`](#textadept.editing.strip_trailing_spaces), [`io.ensure_final_newline`](#io.ensure_final_newline), [`io.save_all_files`](#io.save_all_files), [`events.FILE_BEFORE_SAVE`](#events.FILE_BEFORE_SAVE), [`events.FILE_AFTER_SAVE`](#events.FILE_AFTER_SAVE)

<a id="buffer.save_as"></a>
#### `buffer:save_as`([*filename*])

Saves the buffer to another file.

Parameters:
- *filename*:  String path to save the buffer to. If `nil`, the user is prompted for one.

Returns: `true` if the file was saved; `nil` otherwise.

See also: [`events.FILE_AFTER_SAVE`](#events.FILE_AFTER_SAVE)

<a id="buffer.close"></a>
#### `buffer:close`([*force*=false])

Closes the buffer.

Parameters:
- *force*:  Discard unsaved changes without prompting the user to confirm.

Returns: `true` if the buffer was closed; `nil` otherwise.

See also: [`io.close_all_buffers`](#io.close_all_buffers)

<a id="buffer.set_encoding"></a>
#### `buffer:set_encoding`(*encoding*)

Converts the buffer's contents to another encoding.

Parameters:
- *encoding*:  String encoding to convert to. Valid encodings are ones that [`string.iconv()`](#string.iconv)
	accepts, or `nil` for a binary encoding.

See also: [`io.encodings`](#io.encodings)

<a id="buffer.filename"></a>
#### `buffer.filename`

The buffer's absolute file path (if any).

See also: [`_CHARSET`](#_CHARSET)

<a id="buffer.modify"></a>
#### `buffer.modify`

Whether or not the buffer has unsaved changes.
(Read-only)

<a id="buffer.set_save_point"></a>
#### `buffer:set_save_point`()

Mark the buffer as having no unsaved changes.

<a id="buffer.encoding"></a>
#### `buffer.encoding`

The buffer's encoding, or `nil` for a binary file.

Do not change this field manually. Call [`buffer:set_encoding()`](#buffer.set_encoding) instead.

### Move Within Lines


Movements within the current buffer scroll the caret into view if it is not already visible.

<a id="buffer.char_left"></a>
#### `buffer:char_left`()

Moves the caret left one character.

<a id="buffer.char_right"></a>
#### `buffer:char_right`()

Moves the caret right one character.

<a id="buffer.word_part_left"></a>
#### `buffer:word_part_left`()

Moves the caret to the previous part of the current word.

Word parts are delimited by underscore characters or changes in capitalization.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_part_right"></a>
#### `buffer:word_part_right`()

Moves the caret to the next part of the current word.

Word parts are delimited by underscore characters or changes in capitalization.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_left_end"></a>
#### `buffer:word_left_end`()

Moves the caret left one word, positioning it at the end of the previous word.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_right_end"></a>
#### `buffer:word_right_end`()

Moves the caret right one word, positioning it at the end of the current word.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_left"></a>
#### `buffer:word_left`()

Moves the caret left one word.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_right"></a>
#### `buffer:word_right`()

Moves the caret right one word.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.home"></a>
#### `buffer:home`()

Moves the caret to the beginning of the current line.

<a id="buffer.line_end"></a>
#### `buffer:line_end`()

Moves the caret to the end of the current line.

<a id="buffer.home_display"></a>
#### `buffer:home_display`()

Moves the caret to the beginning of the current wrapped line.

<a id="buffer.line_end_display"></a>
#### `buffer:line_end_display`()

Moves the caret to the end of the current wrapped line.

<a id="buffer.home_wrap"></a>
#### `buffer:home_wrap`()

Moves the caret to the beginning of the current wrapped line or, if already there, to the
beginning of the actual line.

<a id="buffer.line_end_wrap"></a>
#### `buffer:line_end_wrap`()

Moves the caret to the end of the current wrapped line or, if already there, to the end of
the actual line.

<a id="buffer.vc_home"></a>
#### `buffer:vc_home`()

Moves the caret to the first visible character on the current line or, if already there,
to the beginning of the current line.

<a id="buffer.vc_home_display"></a>
#### `buffer:vc_home_display`()

Moves the caret to the first visible character on the current wrapped line or, if already
there, to the beginning of the current wrapped line.

<a id="buffer.vc_home_wrap"></a>
#### `buffer:vc_home_wrap`()

Moves the caret to the first visible character on the current wrapped line or, if already
there, to the beginning of the actual line.

### Move Between Lines


Movements within the current buffer scroll the caret into view if it is not already visible.

<a id="buffer.goto_pos"></a>
#### `buffer:goto_pos`(*pos*)

Moves the caret to a position and scrolls it into view.

Parameters:
- *pos*:  Position to move to.

<a id="buffer.goto_line"></a>
#### `buffer:goto_line`(*line*)

Moves the caret to the beginning of a line and scrolls it into view, even if that line
is hidden.

Parameters:
- *line*:  Line number to go to.

See also: [`textadept.editing.goto_line`](#textadept.editing.goto_line)

<a id="buffer.line_up"></a>
#### `buffer:line_up`()

Moves the caret up one line.

<a id="buffer.line_down"></a>
#### `buffer:line_down`()

Moves the caret down one line.

<a id="buffer.caret_sticky"></a>
#### `buffer.caret_sticky`

The caret's preferred horizontal position when moving between lines.

- `buffer.CARETSTICKY_OFF`: Use the same position the caret had on the previous line.
- `buffer.CARETSTICKY_ON`: Use the last position the caret was moved to via the mouse,
	left/right arrow keys, home/end keys, etc. Typing text does not affect the position.
- `buffer.CARETSTICKY_WHITESPACE`: Use the position the caret had on the previous line,
	but prior to any inserted indentation.

The default value is `buffer.CARETSTICKY_OFF`.

<a id="buffer.choose_caret_x"></a>
#### `buffer:choose_caret_x`()

Declares the current horizontal caret position as the caret's preferred horizontal position
when moving between lines.

<a id="buffer.toggle_caret_sticky"></a>
#### `buffer:toggle_caret_sticky`()

Toggles [`buffer.caret_sticky`](#buffer.caret_sticky) between `buffer.CARETSTICKY_ON` and `buffer.CARETSTICKY_OFF`.

### Move Between Pages


Movements within the current buffer scroll the caret into view if it is not already visible.

<a id="buffer.stuttered_page_up"></a>
#### `buffer:stuttered_page_up`()

Moves the caret to the top of the page or, if already there, up one page.

<a id="buffer.stuttered_page_down"></a>
#### `buffer:stuttered_page_down`()

Moves the caret to the bottom of the page or, if already there, down one page.

<a id="buffer.page_up"></a>
#### `buffer:page_up`()

Moves the caret up one page.

<a id="buffer.page_down"></a>
#### `buffer:page_down`()

Moves the caret down one page.

### Move Between Buffers


Movements between buffers do not scroll the caret into view if it is not visible.

<a id="view.goto_buffer"></a>
#### `view:goto_buffer`(*buffer*)

Switches to another buffer.

Parameters:
- *buffer*:  Buffer to switch to, or index of a relative buffer to switch to (typically 1
	or -1).

Usage:

```lua
view:goto_buffer(_BUFFERS[1]) -- switch to first buffer
view:goto_buffer(-1) -- switch to the buffer before the current one
```

See also: [`events.BUFFER_BEFORE_SWITCH`](#events.BUFFER_BEFORE_SWITCH), [`events.BUFFER_AFTER_SWITCH`](#events.BUFFER_AFTER_SWITCH)

### Other Movements


Movements within the current buffer scroll the caret into view if it is not already visible.

<a id="buffer.para_up"></a>
#### `buffer:para_up`()

Moves the caret up one paragraph.

Paragraphs are surrounded by one or more blank lines.

<a id="buffer.para_down"></a>
#### `buffer:para_down`()

Moves the caret down one paragraph.

Paragraphs are surrounded by one or more blank lines.

<a id="buffer.move_caret_inside_view"></a>
#### `buffer:move_caret_inside_view`()

Moves the caret into view if it is not already, removing any selections.

<a id="buffer.document_start"></a>
#### `buffer:document_start`()

Moves the caret to the beginning of the buffer.

<a id="buffer.document_end"></a>
#### `buffer:document_end`()

Moves the caret to the end of the buffer.

### Retrieve Text

<a id="buffer.get_text"></a>
#### `buffer:get_text`()

Returns the buffer's text.

<a id="buffer.get_sel_text"></a>
#### `buffer:get_sel_text`()

Returns the selected text.

Multiple selections are included in order, separated by [`buffer.copy_separator`](#buffer.copy_separator). Rectangular
selections are included from top to bottom with end of line characters. Virtual space is
not included.

<a id="buffer.copy_separator"></a>
#### `buffer.copy_separator`

The string added between multiple selections in [`buffer:get_sel_text()`](#buffer.get_sel_text).

The default value is the empty string (no separators).

<a id="buffer.text_range"></a>
#### `buffer:text_range`(*start_pos*, *end_pos*)

Returns a range of text.

Parameters:
- *start_pos*:  Start position of the range.
- *end_pos*:  End position of the range.

<a id="buffer.get_line"></a>
#### `buffer:get_line`(*line*)

Returns the text on a line, including its end of line characters.

Parameters:
- *line*:  Line number to get the text of.

<a id="buffer.get_cur_line"></a>
#### `buffer:get_cur_line`()

Returns the current line's text and the caret's position on that line.

<a id="buffer.char_at"></a>
#### `buffer.char_at`

Map of buffer positions to their character bytes.
(Read-only)

### Set Text

<a id="buffer.set_text"></a>
#### `buffer:set_text`(*text*)

Replaces the buffer's text.

Parameters:
- *text*:  String text to set.

<a id="buffer.add_text"></a>
#### `buffer:add_text`(*text*)

Adds text to the buffer at the caret position, moving the caret without scrolling it into view.

Parameters:
- *text*:  String text to add.

<a id="buffer.insert_text"></a>
#### `buffer:insert_text`(*pos*, *text*)

Inserts text into the buffer, removing any existing selections.

If the caret is after *pos*, it is moved appropriately, but not scrolled into view.

Parameters:
- *pos*:  Position to insert text at, or `-1` for the caret position.
- *text*:  String text to insert.

<a id="buffer.append_text"></a>
#### `buffer:append_text`(*text*)

Appends text to the end of the buffer without modifying any existing selections or scrolling
that text into view.

Parameters:
- *text*:  String text to append.

<a id="buffer.line_duplicate"></a>
#### `buffer:line_duplicate`()

Duplicates the current line on a new line below.

<a id="buffer.selection_duplicate"></a>
#### `buffer:selection_duplicate`()

Duplicates the selected text to its right.

If multiple lines are selected, duplication starts at the end of the selection. If no text
is selected, duplicates the current line on a new line below.

<a id="buffer.new_line"></a>
#### `buffer:new_line`()

Types a new line at the caret position according to [`buffer.eol_mode`](#buffer.eol_mode).

### Replace Text


Replacing an arbitrary range of text makes use of a *target range*, a user-defined defined
region of text that some buffer functions operate on in order to avoid altering the current
selection or scrolling the view.

<a id="buffer.replace_sel"></a>
#### `buffer:replace_sel`(*text*)

Replaces the selected text, scrolling the caret into view.

Parameters:
- *text*:  String text to replace the selected text with.

<a id="buffer.set_target_range"></a>
#### `buffer:set_target_range`(*start_pos*, *end_pos*)

Defines the target range.

Parameters:
- *start_pos*:  Start position of the range.
- *end_pos*:  End position of the range.

<a id="buffer.target_from_selection"></a>
#### `buffer:target_from_selection`()

Defines the target range as the main selection.

<a id="buffer.replace_target"></a>
#### `buffer:replace_target`(*text*)

Replaces the text in the target range without modifying any selections or scrolling the view.

Setting the target and calling this function with an empty string is another way to delete text.

Parameters:
- *text*:  String text to replace the target range with.

Returns: length of replacement text

<a id="buffer.replace_target_minimal"></a>
#### `buffer:replace_target_minimal`(*text*)

Replaces the text in the target range without modifying any selections or scrolling the view,
and tries to minimize change history if [`io.track_changes`](#io.track_changes) is `true`.

Parameters:
- *text*:  String text to replace the target range with.

Returns: length of replacement text

### Delete Text

<a id="buffer.clear"></a>
#### `buffer:clear`()

Deletes the character at the caret if no text is selected, or deletes the selected text.

<a id="buffer.delete_range"></a>
#### `buffer:delete_range`(*pos*, *length*)

Deletes a range of text.

Parameters:
- *pos*:  Start position of the range to delete.
- *length*:  Number of characters in the range to delete.

<a id="buffer.delete_back"></a>
#### `buffer:delete_back`()

Deletes the character behind the caret if no text is selected, or deletes the selected text.

<a id="buffer.delete_back_not_line"></a>
#### `buffer:delete_back_not_line`()

Deletes the character behind the caret if no text is selected and the caret is not at the
beginning of a line.

If text is selected, it is deleted.

<a id="buffer.del_word_left"></a>
#### `buffer:del_word_left`()

Deletes the word to the left of the caret, including any leading non-word characters.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.del_word_right"></a>
#### `buffer:del_word_right`()

Deletes the word to the right of the caret, including any trailing non-word characters.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.del_word_right_end"></a>
#### `buffer:del_word_right_end`()

Deletes the word to the right of the caret, excluding any trailing non-word characters.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.del_line_left"></a>
#### `buffer:del_line_left`()

Deletes the range of text from the caret to the beginning of the current line.

<a id="buffer.del_line_right"></a>
#### `buffer:del_line_right`()

Deletes the range of text from the caret to the end of the current line.

<a id="buffer.line_delete"></a>
#### `buffer:line_delete`()

Deletes the current line.

<a id="buffer.clear_all"></a>
#### `buffer:clear_all`()

Deletes the buffer's text.

### Transform Text

<a id="buffer.tab"></a>
#### `buffer:tab`()

Indents the text on the selected lines, or types a Tab character ('\t') at the caret position
if no text is selected.

<a id="buffer.line_indent"></a>
#### `buffer:line_indent`()

Indents the text on the current or selected lines.

<a id="buffer.back_tab"></a>
#### `buffer:back_tab`()

Un-indents the text on the selected lines.

<a id="buffer.line_dedent"></a>
#### `buffer:line_dedent`()

Un-indents the text on the current or selected lines.

<a id="buffer.line_transpose"></a>
#### `buffer:line_transpose`()

Swaps the current line with the one above it.

<a id="buffer.line_reverse"></a>
#### `buffer:line_reverse`()

Reverses the order of the selected lines.

<a id="buffer.upper_case"></a>
#### `buffer:upper_case`()

Converts the selected text to upper case letters.

<a id="buffer.lower_case"></a>
#### `buffer:lower_case`()

Converts the selected text to lower case letters.

<a id="buffer.move_selected_lines_up"></a>
#### `buffer:move_selected_lines_up`()

Shifts the selected lines up one line.

<a id="buffer.move_selected_lines_down"></a>
#### `buffer:move_selected_lines_down`()

Shifts the selected lines down one line.

### Split and Join Lines


Splitting and joining lines uses a target range (a user-defined defined region of text that
some buffer functions operate on).

<a id="buffer.lines_split"></a>
#### `buffer:lines_split`(*width*)

Splits up lines in the target range that exceed a certain width.

Parameters:
- *width*:  Pixel width to split lines at. If `0`, the width of the view is used.

See also: [`buffer.set_target_range`](#buffer.set_target_range), [`buffer.target_from_selection`](#buffer.target_from_selection), [`view.text_width`](#view.text_width)

<a id="buffer.lines_join"></a>
#### `buffer:lines_join`()

Joins the lines in the target range, inserting spaces between any words joined at line
boundaries.

See also: [`buffer.set_target_range`](#buffer.set_target_range), [`buffer.target_from_selection`](#buffer.target_from_selection), [`textadept.editing.join_lines`](#textadept.editing.join_lines)

### Undo and Redo

<a id="buffer.can_undo"></a>
#### `buffer:can_undo`()

Returns whether or not there is an action that can be undone.

<a id="buffer.can_redo"></a>
#### `buffer:can_redo`()

Returns whether or not there is an action that can be redone.

<a id="buffer.undo"></a>
#### `buffer:undo`()

Undoes the most recent action.

<a id="buffer.redo"></a>
#### `buffer:redo`()

Redoes the next undone action.

<a id="buffer.begin_undo_action"></a>
#### `buffer:begin_undo_action`()

Starts a sequence of actions that can be undone or redone as a single action.

Calls to this function may be nested.

<a id="buffer.end_undo_action"></a>
#### `buffer:end_undo_action`()

Ends a sequence of actions that can be undone or redone as a single action.

<a id="buffer.empty_undo_buffer"></a>
#### `buffer:empty_undo_buffer`()

Deletes the buffer's undo and redo history.

<a id="buffer.undo_selection_history"></a>
#### `buffer.undo_selection_history`

Save and restore the main selection during undo and redo, respectively.

- `buffer.UNDO_SELECTION_HISTORY_DISABLED`: Disable selection undo/redo.
- `buffer.UNDO_SELECTION_HISTORY_ENABLED`: Enable selection undo/redo.

The default value is `buffer.UNDO_SELECTION_HISTORY_ENABLED`.

<a id="buffer.undo_collection"></a>
#### `buffer.undo_collection`

Whether or not to record undo history.

The default value is `true`.

### Employ the Clipboard


The terminal version relies on the commands defined in [`textadept.clipboard`](#textadept.clipboard) in order to
interact with the system clipboard, or else it uses its own internal clipboard.

<a id="buffer.cut"></a>
#### `buffer:cut`()

Cuts the selected text to the clipboard.

Multiple selections are copied in order, separated by [`buffer.copy_separator`](#buffer.copy_separator). Rectangular
selections are copied from top to bottom with end of line characters. Virtual space is
not copied.

<a id="buffer.cut_allow_line"></a>
#### `buffer:cut_allow_line`()

Cuts the selected text to the clipboard or, if no text is selected, cuts the current line.

Multiple selections are copied in order, separated by [`buffer.copy_separator`](#buffer.copy_separator). Rectangular
selections are copied from top to bottom with end of line characters. Virtual space is
not copied.

<a id="buffer.copy"></a>
#### `buffer:copy`()

Copies the selected text to the clipboard.

Multiple selections are copied in order, separated by [`buffer.copy_separator`](#buffer.copy_separator). Rectangular
selections are copied from top to bottom with end of line characters. Virtual space is
not copied.

<a id="buffer.copy_allow_line"></a>
#### `buffer:copy_allow_line`()

Copies the selected text to the clipboard or, if no text is selected, copies the entire line.

Multiple selections are copied in order, separated by [`buffer.copy_separator`](#buffer.copy_separator). Rectangular
selections are copied from top to bottom with end of line characters. Virtual space is
not copied.

<a id="buffer.line_cut"></a>
#### `buffer:line_cut`()

Cuts the current line to the clipboard.

<a id="buffer.line_copy"></a>
#### `buffer:line_copy`()

Copies the current line to the clipboard.

<a id="buffer.copy_range"></a>
#### `buffer:copy_range`(*start_pos*, *end_pos*)

Copies a range of text to the clipboard.

Parameters:
- *start_pos*:  Start position of the range to copy.
- *end_pos*:  End position of the range to copy.

<a id="buffer.copy_text"></a>
#### `buffer:copy_text`(*text*)

Copies text to the clipboard.

Parameters:
- *text*:  String text to copy.

<a id="buffer.paste"></a>
#### `buffer:paste`()

Pastes the clipboard's contents into the buffer, replacing any selected text according to
[`buffer.multi_paste`](#buffer.multi_paste).

See also: [`textadept.editing.paste_reindent`](#textadept.editing.paste_reindent), [`ui.get_clipboard_text`](#ui.get_clipboard_text)

<a id="buffer.multi_paste"></a>
#### `buffer.multi_paste`

Paste into multiple selections.

- `buffer.MULTIPASTE_ONCE`: Paste into only the main selection.
- `buffer.MULTIPASTE_EACH`: Paste into all selections.

The default value is `buffer.MULTIPASTE_EACH`.

### Make Simple Selections

<a id="buffer.set_sel"></a>
#### `buffer:set_sel`(*start_pos*, *end_pos*)

Selects a range of text, scrolling it into view.

Parameters:
- *start_pos*:  Start position of the range to select, with a negative position being the
	end of the buffer.
- *end_pos*:  End position of the range to select, with a negative value being *start_pos*
	(i.e. no selection).

<a id="buffer.selection_start"></a>
#### `buffer.selection_start`

The selected text's start position.

When set, it becomes the anchor, but is not scrolled into view.

<a id="buffer.selection_end"></a>
#### `buffer.selection_end`

The selected text's end position.

When set, it becomes the current position, but is not scrolled into view.

<a id="buffer.swap_main_anchor_caret"></a>
#### `buffer:swap_main_anchor_caret`()

Swaps the main selection's beginning and end positions.

<a id="buffer.select_all"></a>
#### `buffer:select_all`()

Selects all of the buffer's text without scrolling the view.

<a id="buffer.set_empty_selection"></a>
#### `buffer:set_empty_selection`(*pos*)

Moves the caret to a position without scrolling the view, and removes any selections.

Parameters:
- *pos*:  Position to move to.

<a id="buffer.selection_empty"></a>
#### `buffer.selection_empty`

Whether or not there is no text selected.
(Read-only)

<a id="buffer.selection_is_rectangle"></a>
#### `buffer.selection_is_rectangle`

Whether or not the selection is a rectangular selection.
(Read-only)

<a id="buffer.is_range_word"></a>
#### `buffer:is_range_word`(*start_pos*, *end_pos*)

Returns whether or not a range's bounds are at word boundaries.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

Parameters:
- *start_pos*:  Start position of the range to check.
- *end_pos*:  End position of the range to check.

### Make Movement Selections

<a id="buffer.char_left_extend"></a>
#### `buffer:char_left_extend`()

Moves the caret left one character, extending the selected text to the new position.

<a id="buffer.char_right_extend"></a>
#### `buffer:char_right_extend`()

Moves the caret right one character, extending the selected text to the new position.

<a id="buffer.word_part_left_extend"></a>
#### `buffer:word_part_left_extend`()

Moves the caret to the previous part of the current word, extending the selected text to
the new position.

Word parts are delimited by underscore characters or changes in capitalization.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_part_right_extend"></a>
#### `buffer:word_part_right_extend`()

Moves the caret to the next part of the current word, extending the selected text to the
new position.

Word parts are delimited by underscore characters or changes in capitalization.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_left_extend"></a>
#### `buffer:word_left_extend`()

Moves the caret left one word, extending the selected text to the new position.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_right_extend"></a>
#### `buffer:word_right_extend`()

Moves the caret right one word, extending the selected text to the new position.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

<a id="buffer.word_left_end_extend"></a>
#### `buffer:word_left_end_extend`()

Like [`buffer:word_left_end()`](#buffer.word_left_end), but extends the selected text to the new position.

<a id="buffer.word_right_end_extend"></a>
#### `buffer:word_right_end_extend`()

Like [`buffer:word_right_end()`](#buffer.word_right_end), but extends the selected text to the new position.

<a id="buffer.home_extend"></a>
#### `buffer:home_extend`()

Moves the caret to the beginning of the current line, extending the selected text to the
new position.

<a id="buffer.line_end_extend"></a>
#### `buffer:line_end_extend`()

Moves the caret to the end of the current line, extending the selected text to the new
position.

<a id="buffer.home_display_extend"></a>
#### `buffer:home_display_extend`()

Moves the caret to the beginning of the current wrapped line, extending the selected text
to the new position.

<a id="buffer.line_end_display_extend"></a>
#### `buffer:line_end_display_extend`()

Moves the caret to the end of the current wrapped line, extending the selected text to the
new position.

<a id="buffer.home_wrap_extend"></a>
#### `buffer:home_wrap_extend`()

Like [`buffer:home_wrap()`](#buffer.home_wrap), but extends the selected text to the new position.

<a id="buffer.line_end_wrap_extend"></a>
#### `buffer:line_end_wrap_extend`()

Like [`buffer:line_end_wrap()`](#buffer.line_end_wrap), but extends the selected text to the new position.

<a id="buffer.vc_home_extend"></a>
#### `buffer:vc_home_extend`()

Like [`buffer:vc_home()`](#buffer.vc_home), but extends the selected text to the new position.

<a id="buffer.vc_home_display_extend"></a>
#### `buffer:vc_home_display_extend`()

Like [`buffer:vc_home_display()`](#buffer.vc_home_display), but extends the selected text to the new position.

<a id="buffer.vc_home_wrap_extend"></a>
#### `buffer:vc_home_wrap_extend`()

Like [`buffer:vc_home_wrap()`](#buffer.vc_home_wrap), but extends the selected text to the new position.

<a id="buffer.line_up_extend"></a>
#### `buffer:line_up_extend`()

Moves the caret up one line, extending the selected text to the new position.

<a id="buffer.line_down_extend"></a>
#### `buffer:line_down_extend`()

Moves the caret down one line, extending the selected text to the new position.

<a id="buffer.para_up_extend"></a>
#### `buffer:para_up_extend`()

Moves the caret up one paragraph, extending the selected text to the new position.

Paragraphs are surrounded by one or more blank lines.

<a id="buffer.para_down_extend"></a>
#### `buffer:para_down_extend`()

Moves the caret down one paragraph, extending the selected text to the new position.

Paragraphs are surrounded by one or more blank lines.

<a id="buffer.stuttered_page_up_extend"></a>
#### `buffer:stuttered_page_up_extend`()

Like [`buffer:stuttered_page_up()`](#buffer.stuttered_page_up), but extends the selected text to the new position.

<a id="buffer.stuttered_page_down_extend"></a>
#### `buffer:stuttered_page_down_extend`()

Like [`buffer:stuttered_page_down()`](#buffer.stuttered_page_down), but extends the selected text to the new position.

<a id="buffer.page_up_extend"></a>
#### `buffer:page_up_extend`()

Moves the caret up one page, extending the selected text to the new position.

<a id="buffer.page_down_extend"></a>
#### `buffer:page_down_extend`()

Moves the caret down one page, extending the selected text to the new position.

<a id="buffer.document_start_extend"></a>
#### `buffer:document_start_extend`()

Moves the caret to the beginning of the buffer, extending the selected text to the new
position.

<a id="buffer.document_end_extend"></a>
#### `buffer:document_end_extend`()

Moves the caret to the end of the buffer, extending the selected text to the new position.

<a id="buffer.move_extends_selection"></a>
#### `buffer.move_extends_selection`

Allow caret movement to alter the selected text.

Setting [`buffer.selection_mode`](#buffer.selection_mode) also updates this property.
The default value is `false`.

### Modal Selection

<a id="buffer.selection_mode"></a>
#### `buffer.selection_mode`

The selection mode.

- `buffer.SEL_STREAM`: Character selection.
- `buffer.SEL_RECTANGLE`: Rectangular selection.
- `buffer.SEL_LINES`: Line selection.
- `buffer.SEL_THIN`: Thin rectangular selection. This is the mode after a rectangular
	selection has been typed into and ensures that no characters are selected.

When set, caret movement alters the selected text until either this field is set again to
the same value, or until [`buffer:cancel()`](#buffer.cancel) is called.

<a id="buffer.change_selection_mode"></a>
#### `buffer:change_selection_mode`(*mode*)

Changes the selection mode without allowing subsequent caret movement to alter selected text.

Parameters:
- *mode*:  Selection mode to change to. Valid values are:
	- `buffer.SEL_STREAM`: Character selection.
	- `buffer.SEL_RECTANGLE`: Rectangular selection.
	- `buffer.SEL_LINES`: Line selection.
	- `buffer.SEL_THIN`: Thin rectangular selection. This is the mode after a rectangular
	selection has been typed into and ensures that no characters are selected.

### Make and Modify Multiple Selections


**Note:** the `buffer.selection_n_`\* fields cannot be used to create selections.

<a id="buffer.set_selection"></a>
#### `buffer:set_selection`(*end_pos*, *start_pos*)

Selects a range of text, removing all other selections.

Parameters:
- *end_pos*:  Caret position of the range to select.
- *start_pos*:  Anchor position of the range to select.

<a id="buffer.add_selection"></a>
#### `buffer:add_selection`(*end_pos*, *start_pos*)

Selects a range of text as the main selection, retaining all other selections as additional
selections.

Since an empty selection (i.e. the current position) still counts as a selection, use
[`buffer:set_selection()`](#buffer.set_selection) first when setting a list of selections.

Parameters:
- *end_pos*:  Caret position of the range to select.
- *start_pos*:  Anchor position of the range to select.

<a id="buffer.multiple_select_add_next"></a>
#### `buffer:multiple_select_add_next`()

Adds to the set of selections the next occurrence of the main selection within the target
range, makes that occurrence the new main selection, and scrolls it into view.

If there is no selected text, the current word is used.

See also: [`textadept.editing.select_word`](#textadept.editing.select_word), [`buffer.set_target_range`](#buffer.set_target_range), [`buffer.target_whole_document`](#buffer.target_whole_document)

<a id="buffer.multiple_select_add_each"></a>
#### `buffer:multiple_select_add_each`()

Adds to the set of selections each occurrence of the main selection within the target range.

If there is no selected text, the current word is used.

See also: [`textadept.editing.select_word`](#textadept.editing.select_word), [`buffer.set_target_range`](#buffer.set_target_range), [`buffer.target_whole_document`](#buffer.target_whole_document)

<a id="buffer.selections"></a>
#### `buffer.selections`

The number of active selections.
(Read-only) There is always at least one selection, which
may be empty.

<a id="buffer.main_selection"></a>
#### `buffer.main_selection`

The number of the main selection, which is often the most recent selection.

Only an existing selection can be made main.

<a id="buffer.rotate_selection"></a>
#### `buffer:rotate_selection`()

Makes the next additional selection the main selection.

<a id="buffer.drop_selection_n"></a>
#### `buffer:drop_selection_n`(*n*)

Drops an existing selection.

Parameters:
- *n*:  Number of the existing selection to drop.

<a id="buffer.selection_n_anchor"></a>
#### `buffer.selection_n_anchor`

Map of existing selection numbers to their start positions.

<a id="buffer.selection_n_caret"></a>
#### `buffer.selection_n_caret`

Map of existing selection numbers to their end positions.

<a id="buffer.selection_n_start"></a>
#### `buffer.selection_n_start`

Map of existing selection numbers to their start positions.

<a id="buffer.selection_n_end"></a>
#### `buffer.selection_n_end`

Map of existing selection numbers to their end positions.

<a id="buffer.selection_n_anchor_virtual_space"></a>
#### `buffer.selection_n_anchor_virtual_space`

Map of existing selection numbers to their virtual space start positions.

<a id="buffer.selection_n_caret_virtual_space"></a>
#### `buffer.selection_n_caret_virtual_space`

Map of existing selection numbers to their virtual space end positions.

<a id="buffer.selection_n_start_virtual_space"></a>
#### `buffer.selection_n_start_virtual_space`

Map of existing selection numbers to their virtual space start positions.
(Read-only)

<a id="buffer.selection_n_end_virtual_space"></a>
#### `buffer.selection_n_end_virtual_space`

Map of existing selection numbers to their virtual space end positions.
(Read-only)

<a id="buffer.selection_serialized"></a>
#### `buffer.selection_serialized`

Serialized string selection state.

The serialization format may change between releases, so it should not be used in session
saving and loading.

<a id="buffer.multiple_selection"></a>
#### `buffer.multiple_selection`

Enable multiple selection.

The default value is `true`.

<a id="buffer.additional_selection_typing"></a>
#### `buffer.additional_selection_typing`

Type into multiple selections.

The default value is `true`.

### Make Rectangular Selections

<a id="buffer.rectangular_selection_anchor"></a>
#### `buffer.rectangular_selection_anchor`

The rectangular selection's anchor position.

<a id="buffer.rectangular_selection_caret"></a>
#### `buffer.rectangular_selection_caret`

The rectangular selection's caret position.

<a id="buffer.rectangular_selection_anchor_virtual_space"></a>
#### `buffer.rectangular_selection_anchor_virtual_space`

The amount of virtual space for the rectangular selection's anchor.

<a id="buffer.rectangular_selection_caret_virtual_space"></a>
#### `buffer.rectangular_selection_caret_virtual_space`

The amount of virtual space for the rectangular selection's caret.

<a id="buffer.char_left_rect_extend"></a>
#### `buffer:char_left_rect_extend`()

Moves the caret left one character, extending the rectangular selection to the new position.

<a id="buffer.char_right_rect_extend"></a>
#### `buffer:char_right_rect_extend`()

Moves the caret right one character, extending the rectangular selection to the new position.

<a id="buffer.home_rect_extend"></a>
#### `buffer:home_rect_extend`()

Moves the caret to the beginning of the current line, extending the rectangular selection
to the new position.

<a id="buffer.line_end_rect_extend"></a>
#### `buffer:line_end_rect_extend`()

Moves the caret to the end of the current line, extending the rectangular selection to the
new position.

<a id="buffer.vc_home_rect_extend"></a>
#### `buffer:vc_home_rect_extend`()

Like [`buffer:vc_home()`](#buffer.vc_home), but extends the rectangular selection to the new position.

<a id="buffer.line_up_rect_extend"></a>
#### `buffer:line_up_rect_extend`()

Moves the caret up one line, extending the rectangular selection to the new position.

<a id="buffer.line_down_rect_extend"></a>
#### `buffer:line_down_rect_extend`()

Moves the caret down one line, extending the rectangular selection to the new position.

<a id="buffer.page_up_rect_extend"></a>
#### `buffer:page_up_rect_extend`()

Moves the caret up one page, extending the rectangular selection to the new position.

<a id="buffer.page_down_rect_extend"></a>
#### `buffer:page_down_rect_extend`()

Moves the caret down one page, extending the rectangular selection to the new position.

<a id="view.rectangular_selection_modifier"></a>
#### `view.rectangular_selection_modifier`

The modifier key used in combination with a mouse drag in order to create a rectangular
selection.

- `view.MOD_CTRL`: The "Control" modifier key.
- `view.MOD_ALT`: The "Alt" modifier key.
- `view.MOD_SUPER`: The "Super" modifier key, usually defined as the left "Windows" or
	"Command" key.

The default value is `view.MOD_ALT`.

<a id="view.mouse_selection_rectangular_switch"></a>
#### `view.mouse_selection_rectangular_switch`

Turn on rectangular selection when pressing [`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) while
selecting text normally with the mouse.

This works around the Linux/BSD window managers that consume Alt+Mouse Drag.

The default value is `true`.

<a id="buffer.replace_rectangular"></a>
#### `buffer:replace_rectangular`(*text*)

Replaces the rectangular selection's text.

Parameters:
- *text*:  String text to replace the rectangular selection with.

### Simple Search

<a id="buffer.search_anchor"></a>
#### `buffer:search_anchor`()

Marks the caret position as the position [`buffer:search_next()`](#buffer.search_next) and [`buffer:search_prev()`](#buffer.search_prev)
start from.

If text is selected, the selected text's start position is used instead.

<a id="buffer.search_next"></a>
#### `buffer:search_next`(*flags*, *text*)

Searches for text and selects its first occurrence without scrolling the view.

Searches start where [`buffer:search_anchor()`](#buffer.search_anchor) was called.

Parameters:
- *flags*:  A bit-mask of search flags to use:
	- `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
	- `buffer.FIND_MATCHCASE`: Match search text case sensitively.
	- `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
		character.
	- `buffer.FIND_REGEXP`: Interpret search text as a regular expression.
- *text*:  String text to search for.

Returns: found text's position, or `-1` if no text was found

<a id="buffer.search_prev"></a>
#### `buffer:search_prev`(*flags*, *text*)

Searches for text and selects its previous occurrence without scrolling the view.

Searches start where [`buffer:search_anchor()`](#buffer.search_anchor) was called.

Parameters:
- *flags*:  A bit-mask of search flags to use:
	- `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
	- `buffer.FIND_MATCHCASE`: Match search text case sensitively.
	- `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
		character.
	- `buffer.FIND_REGEXP`: Interpret search text as a regular expression.
- *text*:  String text to search for.

Returns: found text's position, or `-1` if no text was found

### Search and Replace


The more complex search and replace API uses a target range (a user-defined region of text
that some buffer functions operate on, or a region of text that some buffer functions define
as output).

<a id="buffer.search_flags"></a>
#### `buffer.search_flags`

The bit-mask of search flags used by [`buffer:search_in_target()`](#buffer.search_in_target).

- `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
- `buffer.FIND_MATCHCASE`: Match search text case sensitively.
- `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
	character.
- `buffer.FIND_REGEXP`: Interpret search text as a regular expression.

The default value is `0`.

<a id="buffer.target_whole_document"></a>
#### `buffer:target_whole_document`()

Defines the target range as the entire buffer's contents.

See also: [`buffer.set_target_range`](#buffer.set_target_range), [`buffer.target_from_selection`](#buffer.target_from_selection)

<a id="buffer.search_in_target"></a>
#### `buffer:search_in_target`(*text*)

Searches the target range for text and updates the target range to the first occurrence found.

[`buffer.search_flags`](#buffer.search_flags) are the flags used in the search.

Parameters:
- *text*:  String text to search the target range for.

Returns: found text's position, or `-1` if no text was found

<a id="buffer.replace_target_re"></a>
#### `buffer:replace_target_re`(*text*)

Replaces the text in the target range with a regular expression replacement.

Parameters:
- *text*:  String text to replace the target range with. Any "\d" sequences will expand to
	the text of capture number *d* from the regular expression search (or the entire match
	for *d* = 0)

Returns: length of replacement text

See also: [`buffer.replace_target`](#buffer.replace_target)

<a id="buffer.target_text"></a>
#### `buffer.target_text`

The text in the target range.
(Read-only)

<a id="buffer.target_start"></a>
#### `buffer.target_start`

The target range's start position.

This is also set by a successful [`buffer:search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_end"></a>
#### `buffer.target_end`

The target range's end position.

This is also set by a successful [`buffer:search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_start_virtual_space"></a>
#### `buffer.target_start_virtual_space`

The start position of the target range's virtual space.

This is reset to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set, or when
[`buffer:set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.target_end_virtual_space"></a>
#### `buffer.target_end_virtual_space`

The end position of the target range's virtual space.

This is reset to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set, or when
[`buffer:set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.tag"></a>
#### `buffer.tag`

Map of a regular expression search's capture numbers to captured text.
(Read-only)

### Query Position Information

<a id="buffer.anchor"></a>
#### `buffer.anchor`

The anchor's position.

<a id="buffer.current_pos"></a>
#### `buffer.current_pos`

The caret's position.

 Setting this does not scroll the caret into view.

<a id="buffer.position_before"></a>
#### `buffer:position_before`(*pos*)

Returns the position before a given position, taking multi-byte characters into account, or
`-1` if there is no such position.

Parameters:
- *pos*:  Position to get the previous position from.

<a id="buffer.position_after"></a>
#### `buffer:position_after`(*pos*)

Returns the position after a given position, taking multi-byte characters into account, or
`buffer.length + 1` if there is no such position.

Parameters:
- *pos*:  Position to get the next position from.

<a id="buffer.position_relative"></a>
#### `buffer:position_relative`(*pos*, *n*)

Returns the position a relative number of characters away from a given position, taking
multi-byte characters into account, or `1` if there is no such position.

Parameters:
- *pos*:  Position to get the relative position from.
- *n*:  Relative number of characters to get the position for. A negative number
	indicates a position before while a positive number indicates a position after.

<a id="buffer.word_start_position"></a>
#### `buffer:word_start_position`(*pos*, *only_word_chars*)

Returns a word's start position.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

Parameters:
- *pos*:  Position of the word.
- *only_word_chars*:  If `true`, stops searching at the first non-word character to the
	left of *pos*. Otherwise, the first character to the left of *pos* sets the type of
	the search as word or non-word and the search stops at the first non-matching character.

Usage:

```lua
-- Consider the buffer text "word....word"
buffer:word_start_position(3, true) --> 1
buffer:word_start_position(7, true) --> 7
buffer:word_start_position(7, false) --> 5
buffer:word_start_position(9, false) --> 5
buffer:word_start_position(9, true) --> 9
```

<a id="buffer.word_end_position"></a>
#### `buffer:word_end_position`(*pos*, *only_word_chars*)

Returns a word's end position.

[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.

Parameters:
- *pos*:  Position of the word.
- *only_word_chars*:  If `true`, stops searching at the first non-word character to the
	right of *pos*. Otherwise, the first character to the right of *pos* sets the type of
	the search as word or non-word and the search stops at the first non-matching character.

Usage:

```lua
-- Consider the buffer text "word....word"
buffer:word_end_position(3, true) --> 5
buffer:word_end_position(5, true) --> 5
buffer:word_end_position(5, false) --> 9
buffer:word_end_position(7, true) --> 7
buffer:word_end_position(7, false) --> 9
```

<a id="buffer.position_from_line"></a>
#### `buffer:position_from_line`(*line*)

Returns a line's start position.

Parameters:
- *line*:  Line number to get the start position for. If *line* exceeds `buffer.line_count +
	1`, `-1` will be returned.

<a id="buffer.line_indent_position"></a>
#### `buffer.line_indent_position`

Map of line numbers to their end-of-line-indentation positions.
(Read-only)

<a id="buffer.line_end_position"></a>
#### `buffer.line_end_position`

Map of line numbers to their end-of-line positions before any end-of-line
characters.
(Read-only)

<a id="buffer.find_column"></a>
#### `buffer:find_column`(*line*, *column*)

Returns the position at a particular line and column, taking tab and multi-byte characters
into account.

Parameters:
- *line*:  Line number to use.
- *column*:  Column number to use. If it exceeds the length of *line*, the position at the
	end of *line* will be returned.

<a id="buffer.brace_match"></a>
#### `buffer:brace_match`(*pos*, *max_re_style*)

Returns the position of a matching brace character, taking nested braces into account, or
`-1` if no match was found.

Matching braces must have the same style.

Parameters:
- *pos*:  Position of the brace to match. Brace characters recognized are '(', ')', '[',
	']', '{', '}', '<', and '>'.
- *max_re_style*:  Must be `0`. Reserved for expansion.

### Query Line and Line Number Information

<a id="buffer.line_count"></a>
#### `buffer.line_count`

The number of lines in the buffer.
(Read-only)
There is always at least one.

<a id="view.lines_on_screen"></a>
#### `view.lines_on_screen`

The number of completely visible lines in the view.
(Read-only)
It is possible to have a partial line visible at the bottom of the view.

<a id="view.first_visible_line"></a>
#### `view.first_visible_line`

The line number of the line at the top of the view.

<a id="buffer.line_from_position"></a>
#### `buffer:line_from_position`(*pos*)

Returns the line number that contains a position.

Parameters:
- *pos*:  Position to get the line number of. If it is less than `1`, `1` is returned. If
	*pos* is greater than `buffer.length + 1`, [`buffer.line_count`](#buffer.line_count) is returned.

<a id="buffer.line_indentation"></a>
#### `buffer.line_indentation`

Map of line numbers to their column indentation amounts.

<a id="buffer.line_length"></a>
#### `buffer:line_length`(*line*)

Returns the number of bytes on a line, including end of line characters.

To get line length excluding end of line characters, use
`buffer.line_end_position[line] - buffer.position_from_line(line)`.

Parameters:
- *line*:  Line number to get the length of.

<a id="view.wrap_count"></a>
#### `view:wrap_count`(*line*)

Returns the number of wrapped lines needed to fully display a line.

Parameters:
- *line*:  Line number to use.

<a id="view.visible_from_doc_line"></a>
#### `view:visible_from_doc_line`(*line*)

Returns the displayed line number of an actual line number, taking wrapped, annotated,
and hidden lines into account.

Lines can occupy more than one display line if they wrap.

Parameters:
- *line*:  Line number to use. If it is outside the range of lines in the buffer, `-1`
	is returned.

<a id="view.doc_line_from_visible"></a>
#### `view:doc_line_from_visible`(*display_line*)

Returns the actual line number of a displayed line number, taking wrapped, annotated, and
hidden lines into account.

Parameters:
- *display_line*:  Display line number to use. If it is less than `1`, `1` is returned. If
	*display_line* is greater than the number of displayed lines, [`buffer.line_count`](#buffer.line_count)
	is returned.

### Query Measurement Information

<a id="buffer.length"></a>
#### `buffer.length`

The number of bytes in the buffer.
(Read-only)

<a id="buffer.text_length"></a>
#### `buffer.text_length`

The number of bytes in the buffer.
(Read-only)

<a id="buffer.column"></a>
#### `buffer.column`

Map of buffer positions to their column numbers, taking tab and multi-byte characters into
account.
(Read-only)

<a id="buffer.count_characters"></a>
#### `buffer:count_characters`(*start_pos*, *end_pos*)

Returns the number of whole characters, taking multi-byte characters into account, between
two positions.

Parameters:
- *start_pos*:  Start position of the range to start counting at.
- *end_pos*:  End position of the range to stop counting at.

<a id="view.text_width"></a>
#### `view:text_width`(*style_num*, *text*)

Returns the pixel width text would have when styled in a particular style.

Parameters:
- *style_num*:  Style number between `1` and `256` to use.
- *text*:  String text to measure the width of.

<a id="view.text_height"></a>
#### `view:text_height`(*line*)

Returns the pixel height of a line.

Parameters:
- *line*:  Line number to get the pixel height of.

### Configure Line Margins


The number of line margins is configurable, with each one displaying either line numbers,
[marker symbols](#mark-lines-with-markers), or text.

<a id="view.margins"></a>
#### `view.margins`

The number of margins.

The default value is `5`.

<a id="view.margin_type_n"></a>
#### `view.margin_type_n`

Map of margin numbers to their types.

Valid margin types are:
- `view.MARGIN_SYMBOL`: A marker symbol margin.
- `view.MARGIN_NUMBER`: A line number margin.
- `view.MARGIN_BACK`: A marker symbol margin whose background color matches the default text
	background color.
- `view.MARGIN_FORE`: A marker symbol margin whose background color matches the default text
	foreground color.
- `view.MARGIN_TEXT`: A text margin.
- `view.MARGIN_RTEXT`: A right-justified text margin.
- `view.MARGIN_COLOR`: A marker symbol margin whose background color is configurable.

The default value for the first margin is `view.MARGIN_NUMBER`, followed by `view.MARGIN_SYMBOL`
for the rest.

<a id="view.margin_width_n"></a>
#### `view.margin_width_n`

Map of margin numbers to their pixel margin widths.

<a id="view.margin_mask_n"></a>
#### `view.margin_mask_n`

Map of margin numbers to their marker symbol bit-masks.

Bit-masks are 32-bit values whose bits correspond to the 32 available markers. A margin
whose type is either `view.MARGIN_SYMBOL`, `view.MARGIN_BACK`, `view.MARGIN_FORE`, or
`view.MARGIN_COLOR` can show any marker whose bit is set in the mask.

The default values are `0`, `~view.MASK_FOLDERS`, `view.MASK_FOLDERS`, and `0` for the rest.

Usage:

```lua
view.margin_mask_n[2] = ~view.MASK_FOLDERS -- display non-folding markers
view.margin_mask_n[3] = view.MASK_FOLDERS -- only display folding markers
```

<a id="view.margin_sensitive_n"></a>
#### `view.margin_sensitive_n`

Map of margin numbers to whether or not mouse clicks in them emit [`events.MARGIN_CLICK`](#events.MARGIN_CLICK).

The default values are `false` for the first margin and `true` for the others.

<a id="view.margin_cursor_n"></a>
#### `view.margin_cursor_n`

Map of margin numbers to their displayed mouse cursors.

- `view.CURSORARROW`: Normal arrow cursor.
- `view.CURSORREVERSEARROW`: Reversed arrow cursor.

The default values are `view.CURSORARROW`.

<a id="buffer.margin_text"></a>
#### `buffer.margin_text`

Map of line numbers to their text margin text.

A margin whose type is either `view.MARGIN_TEXT` or `view.MARGIN_RTEXT` can show text in
this map.

Usage:

```lua
buffer.margin_text[1] = 'Title:'
```

<a id="buffer.margin_style"></a>
#### `buffer.margin_style`

Map of line numbers to their text margin style numbers.

A margin whose type is either `view.MARGIN_TEXT` or `view.MARGIN_RTEXT` will show text in
[`buffer.margin_text`](#buffer.margin_text) in the styles specified here.

Note: text margins can only draw some style attributes: font, size, bold, italics, fore,
and back.

Usage:

```lua
buffer.margin_style[1] = buffer:style_of_name(lexer.BOLD)
```

See also: [`view.styles`](#view.styles), [`buffer.style_of_name`](#buffer.style_of_name)

<a id="buffer.margin_text_clear_all"></a>
#### `buffer:margin_text_clear_all`()

Clears all text margin text.

<a id="view.margin_options"></a>
#### `view.margin_options`

A bit-mask of margin option settings.

- `view.MARGINOPTION_NONE`: None.
- `view.MARGINOPTION_SUBLINESELECT`: Select only a wrapped line's sub-line (rather than the
	entire line) when clicking on the line number margin.

The default value is `view.MARGINOPTION_NONE`.

<a id="view.margin_back_n"></a>
#### `view.margin_back_n`

Map of margin numbers to marker symbol margin background colors in "0xBBGGRR" format.

A margin whose type is `view.MARGIN_COLOR` will use the color specified here.

Usage:

```lua
view.margin_back_n[4] = view.colors.light_grey
```

<a id="view.set_fold_margin_color"></a>
#### `view:set_fold_margin_color`(*use_setting*, *color*)

Overrides the fold margin's default color.

Parameters:
- *use_setting*:  Whether or not to use *color*.
- *color*:  Color in "0xBBGGRR" format.

<a id="view.set_fold_margin_hi_color"></a>
#### `view:set_fold_margin_hi_color`(*use_setting*, *color*)

Overrides the fold margin's default highlight color.

Parameters:
- *use_setting*:  Whether or not to use *color*.
- *color*:  Color in "0xBBGGRR" format.

<a id="view.margin_left"></a>
#### `view.margin_left`

The pixel size of buffer text's left margin.

The default value is `1` in the GUI version and `0` in the terminal version.

<a id="view.margin_right"></a>
#### `view.margin_right`

The pixel size of buffer text's right margin.

The default value is `1` in the GUI version and `0` in the terminal version.

### Mark Lines with Markers


There are 32 markers to mark lines with. Each marker has an assigned symbol that properly
configured [margins](#configure-line-margins) will display. For lines with multiple markers,
markers are drawn over one another in ascending order. Markers move in sync with the lines
they were added to as text is inserted and deleted. When a line that has a marker on it is
deleted, that marker moves to the previous line.

Marker symbol | Visual or description
-|-
`view.MARK_CIRCLE` | ●
`view.MARK_SMALLRECT` | ■
`view.MARK_ROUNDRECT` | A rounded rectangle
`view.MARK_LEFTRECT` | ▌
`view.MARK_FULLRECT` | █
`view.MARK_SHORTARROW` | A small, right-facing arrow
`view.MARK_ARROW` | ►
`view.MARK_ARROWS` | ›››
`view.MARK_DOTDOTDOT` | …
`view.MARK_BOOKMARK` | A horizontal bookmark flag
`view.MARK_VERTICALBOOKMARK` | A vertical bookmark flag
`view.MARK_PIXMAP` | An [XPM image][]
`view.MARK_RGBAIMAGE` | An [RGBA image][]
`view.MARK_CHARACTER` + *i* | The character whose ASCII value is *i*
`view.MARK_EMPTY` | An empty marker
`view.MARK_BACKGROUND` | Changes a line's background color
`view.MARK_UNDERLINE` | Underlines an entire line
**Fold symbols** |
`view.MARK_ARROW` | ►
`view.MARK_ARROWDOWN` | ▼
`view.MARK_MINUS` | −
`view.MARK_BOXMINUS` | ⊟
`view.MARK_BOXMINUSCONNECTED` | A boxed minus sign connected to a vertical line
`view.MARK_CIRCLEMINUS` | ⊖
`view.MARK_CIRCLEMINUSCONNECTED` | A circled minus sign connected to a vertical line
`view.MARK_PLUS` | +
`view.MARK_BOXPLUS` | ⊞
`view.MARK_BOXPLUSCONNECTED` | A boxed plus sign connected to a vertical line
`view.MARK_CIRCLEPLUS` | ⊕
`view.MARK_CIRCLEMINUSCONNECTED` | A circled plus sign connected to a vertical line
`view.MARK_VLINE` | │
`view.MARK_TCORNER` | ├
`view.MARK_LCORNER` | └
`view.MARK_TCORNERCURVE` | A curved, T-shaped corner
`view.MARK_LCORNERCURVE` | A curved, L-shaped corner

There are 7 pre-defined marker numbers used for code folding marker symbols.

Marker Number | Description
-|-
`view.MARKNUM_FOLDEROPEN` | The first line of an expanded fold
`view.MARKNUM_FOLDERSUB` | A line within an expanded fold
`view.MARKNUM_FOLDERTAIL` | The last line of an expanded fold
`view.MARKNUM_FOLDER` | The first line of a collapsed fold
`view.MARKNUM_FOLDEROPENMID` | The first line of an expanded fold within an expanded fold
`view.MARKNUM_FOLDERMIDTAIL` | The last line of an expanded fold within an expanded fold
`view.MARKNUM_FOLDEREND` | The first line of a collapsed fold within an expanded fold

There are 4 pre-defined marker numbers used for showing how a buffer line differs from its
file's saved state if [`io.track_changes`](#io.track_changes) is `true`.

Marker Number | Description
-|-
`view.MARKNUM_HISTORY_MODIFIED` | Line was changed and has not yet been saved
`view.MARKNUM_HISTORY_SAVED` | Line was changed and saved
`view.MARKNUM_HISTORY_REVERTED_TO_MODIFIED` | Line was changed, saved, then partially reverted
`view.MARKNUM_HISTORY_REVERTED_TO_ORIGIN` | Line was changed, saved, then fully reverted

[XPM image]: https://scintilla.org/ScintillaDoc.html#XPM
[RGBA image]: https://scintilla.org/ScintillaDoc.html#RGBA

<a id="view.new_marker_number"></a>
#### `view.new_marker_number`()

Returns a unique marker number for use with [`view:marker_define()`](#view.marker_define).

Use this function for custom markers in order to prevent clashes with the numbers of other
custom markers.

<a id="view.marker_define"></a>
#### `view:marker_define`(*marker*, *symbol*)

Assigns a marker symbol to a marker.

Properly configured marker symbol margins will show the symbol next to lines marked with
that marker.

Parameters:
- *marker*:  Marker number in the range of `1` to `32` to set *symbol* for.
- *symbol*:  Marker symbol to assign: `view.MARK_*`.

<a id="view.marker_define_pixmap"></a>
#### `view:marker_define_pixmap`(*marker*, *pixmap*)

Assigns an XPM image to a pixmap marker.

Parameters:
- *marker*:  Marker number previously defined with a `view.MARK_PIXMAP` symbol.
- *pixmap*:  String [pixmap data](https://scintilla.org/ScintillaDoc.html#XPM).

<a id="view.marker_define_rgba_image"></a>
#### `view:marker_define_rgba_image`(*marker*, *pixels*)

Assigns an RGBA image to an RGBA image marker.

Parameters:
- *marker*:  Marker number previously defined with a `view.MARK_RGBAIMAGE` symbol.
- *pixels*:  String sequence of 4 byte pixel values (red, green, blue, and alpha) starting
	with the pixels for the top line, with the leftmost pixel first, then continuing with
	the pixels for subsequent lines. There is no gap between lines for alignment reasons.
	The image dimensions, [`view.rgba_image_width`](#view.rgba_image_width) and [`view.rgba_image_height`](#view.rgba_image_height), must have
	already been defined.

See also: [`view.rgba_image_scale`](#view.rgba_image_scale)

<a id="buffer.marker_add"></a>
#### `buffer:marker_add`(*line*, *marker*)

Adds a marker to a line.

Parameters:
- *line*:  Line number to add the marker on.
- *marker*:  Marker number in the range of `1` to `32` to add.

Returns: handle for use in [`buffer:marker_delete_handle()`](#buffer.marker_delete_handle) and
	[`buffer:marker_line_from_handle()`](#buffer.marker_line_from_handle), or `-1` if *line* is invalid

<a id="buffer.marker_add_set"></a>
#### `buffer:marker_add_set`(*line*, *marker_mask*)

Adds a set of markers a line.

Parameters:
- *line*:  Line number to add the markers on.
- *marker_mask*:  Bit-mask of markers to set. Set the first bit to set marker 1, the second
	bit for marker 2 and so on up to marker 32.

<a id="buffer.marker_delete_handle"></a>
#### `buffer:marker_delete_handle`(*handle*)

Deletes a marker identified by its handle.

Parameters:
- *handle*:  Marker handle returned by [`buffer:marker_add()`](#buffer.marker_add) or
	[`buffer:marker_handle_from_line()`](#buffer.marker_handle_from_line).

<a id="buffer.marker_delete"></a>
#### `buffer:marker_delete`(*line*, *marker*)

Deletes a marker from a line.

Parameters:
- *line*:  Line number to delete the marker on.
- *marker*:  Marker number in the range of `1` to `32` to delete, or `-1` to delete all
	markers from *line*.

<a id="buffer.marker_delete_all"></a>
#### `buffer:marker_delete_all`(*marker*)

Deletes a marker from any line that has it.

Parameters:
- *marker*:  Marker number in the range of `1` to `32` to delete, or `-1` to delete all
	markers from lines.

<a id="buffer.marker_line_from_handle"></a>
#### `buffer:marker_line_from_handle`(*handle*)

Returns the line number a particular marker is on, or `-1` if the marker was not found.

Parameters:
- *handle*:  Marker handle returned by [`buffer:marker_add()`](#buffer.marker_add) or
	[`buffer:marker_handle_from_line()`](#buffer.marker_handle_from_line).

<a id="buffer.marker_next"></a>
#### `buffer:marker_next`(*line*, *marker_mask*)

Returns the line number of the next line that contains a set of markers, or `-1` if no line
was found.

Parameters:
- *line*:  Line number to start searching from.
- *marker_mask*:  Bit-mask of markers to find. Set the first bit to find marker 1, the
	second bit for marker 2, and so on up to marker 32.

<a id="buffer.marker_previous"></a>
#### `buffer:marker_previous`(*line*, *marker_mask*)

Returns the line number of the previous line that contains a set of markers, or `-1` if no
line was found.

Parameters:
- *line*:  Line number to start searching from.
- *marker_mask*:  Bit-mask of markers to find. Set the first bit to find marker 1, the
	second bit for marker 2, and so on up to marker 32.

<a id="buffer.marker_handle_from_line"></a>
#### `buffer:marker_handle_from_line`(*line*, *n*)

Returns the handle of a marker on a line.

Parameters:
- *line*:  Line number to get a marker from.
- *n*:  *n*th marker to get the handle of. If no such marker exists, `-1` is returned.

<a id="buffer.marker_get"></a>
#### `buffer:marker_get`(*line*)

Returns a bit-mask of all of the markers on a line.

The first bit is set if marker number 1 is present, the second bit for marker number 2,
and so on.

Parameters:
- *line*:  Line number to get markers on.

<a id="buffer.marker_number_from_line"></a>
#### `buffer:marker_number_from_line`(*line*, *n*)

Returns the number of a marker on a line.

Parameters:
- *line*:  Line number to get a marker from.
- *n*:  *n*th marker to get the number of. If no such marker exists, `-1` is returned.

<a id="view.marker_symbol_defined"></a>
#### `view:marker_symbol_defined`(*marker*)

Returns the marker symbol assigned to a marker.

Parameters:
- *marker*:  Marker number in the range of `1` to `32` to get the symbol for.

<a id="view.marker_fore"></a>
#### `view.marker_fore`

Map of marker numbers to their foreground colors in "0xBBGGRR" format.
(Write-only)

<a id="view.marker_fore_translucent"></a>
#### `view.marker_fore_translucent`

Map of marker numbers to their foreground colors in "0xAABBGGRR" format.
(Write-only)

<a id="view.marker_back"></a>
#### `view.marker_back`

Map of marker numbers to their background colors in "0xBBGGRR" format.
(Write-only)

<a id="view.marker_back_translucent"></a>
#### `view.marker_back_translucent`

Map of marker numbers to their background colors in "0xAABBGGRR" format.
(Write-only)

<a id="view.marker_alpha"></a>
#### `view.marker_alpha`

Map of marker numbers to their alpha values.
(Write-only)
A marker whose marker symbol is either `view.MARK_BACKGROUND` or `view.MARK_UNDERLINE`
will use the alpha value specified here.

The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.marker_layer"></a>
#### `view.marker_layer`

Map of marker numbers to their draw layers.

A marker whose marker symbol is either `view.MARK_BACKGROUND` or `view.MARK_UNDERLINE`
will use the draw layer specified here.

- `view.LAYER_BASE`: Draw markers opaquely on the background.
- `view.LAYER_UNDER_TEXT`: Draw markers translucently under text.
- `view.LAYER_OVER_TEXT`: Draw markers translucently over text.

The default values are `view.LAYER_BASE`.

<a id="view.marker_stroke_width"></a>
#### `view.marker_stroke_width`

Map of marker numbers to their draw stroke widths in hundredths of a pixel.
(Write-only)
The default values are `100`, or 1 pixel.

<a id="view.marker_enable_highlight"></a>
#### `view:marker_enable_highlight`(*enabled*)

Enables the highlighting of margin fold markers for the current fold block.

Parameters:
- *enabled*:  Whether or not to enable highlighting.

<a id="view.marker_back_selected"></a>
#### `view.marker_back_selected`

Map of marker numbers to their selected folding block background colors in "0xBBGGRR"
format.
(Write-only)

<a id="view.marker_back_selected_translucent"></a>
#### `view.marker_back_selected_translucent`

Map of marker numbers to their selected folding block background colors in "0xAABBGGRR"
format.
(Write-only)

### Annotate Lines


Lines may be annotated with styled, read-only text displayed underneath them or next to them
at the ends of lines (EOL). This may be useful for displaying compiler errors, runtime errors,
variable values, or other useful information.

<a id="buffer.annotation_text"></a>
#### `buffer.annotation_text`

Map of line numbers to their annotation text.

Usage:

```lua
buffer.annotation_text[1] = 'error: undefined variable "x"'
```

<a id="buffer.eol_annotation_text"></a>
#### `buffer.eol_annotation_text`

Map of line numbers to their EOL annotation text.

Usage:

```lua
buffer.eol_annotation_text[1] = 'x = 1'
```

<a id="buffer.annotation_style"></a>
#### `buffer.annotation_style`

Map of line numbers to their annotation style numbers.

Note: annotations can only draw some style attributes: font, size/size_fractional, bold/weight,
italics, fore, back, and character_set.

Usage:

```lua
buffer.annotation_style[1] = buffer:style_of_name(lexer.ERROR)
```

See also: [`view.styles`](#view.styles), [`buffer.style_of_name`](#buffer.style_of_name)

<a id="buffer.eol_annotation_style"></a>
#### `buffer.eol_annotation_style`

Map of line numbers to their EOL annotation style numbers.

Note: annotations can only draw style attributes: font, size/size_fractional, bold/weight,
italics, fore, back, and character_set.

Usage:

```lua
buffer.eol_annotation_style[1] = buffer:style_of_name(view.STYLE_FOLDDISPLAYTEXT)
```

See also: [`view.styles`](#view.styles), [`buffer.style_of_name`](#buffer.style_of_name)

<a id="buffer.annotation_clear_all"></a>
#### `buffer:annotation_clear_all`()

Clears annotations from all lines.

<a id="buffer.eol_annotation_clear_all"></a>
#### `buffer:eol_annotation_clear_all`()

Clears EOL annotations from all lines.

<a id="view.annotation_visible"></a>
#### `view.annotation_visible`

The annotation display style.

- `view.ANNOTATION_HIDDEN`: Annotations are invisible.
- `view.ANNOTATION_STANDARD`: Draw annotations left-justified with no decoration.
- `view.ANNOTATION_BOXED`: Indent annotations to match the annotated text and outline them
	with a box.
- `view.ANNOTATION_INDENTED`: Indent non-decorated annotations to match the annotated text.

The default value is `view.ANNOTATION_BOXED` in the GUI version and `view.ANNOTATION_STANDARD`
in the terminal version.

<a id="view.eol_annotation_visible"></a>
#### `view.eol_annotation_visible`

The EOL annotation display style.

- `view.EOLANNOTATION_HIDDEN`: Annotations are invisible.
- `view.EOLANNOTATION_STANDARD`: Draw annotations with no decoration.
- `view.EOLANNOTATION_BOXED`: Outline annotations with a box.
- `view.EOLANNOTATION_STADIUM`: Outline annotations with curved ends.
- `view.EOLANNOTATION_FLAT_CIRCLE`: Outline annotations with flat left and curved right ends.
- `view.EOLANNOTATION_ANGLE_CIRCLE`: Outline annotations with angled left and curved right ends.
- `view.EOLANNOTATION_CIRCLE_FLAT`: Outline annotations with curved left and flat right ends.
- `view.EOLANNOTATION_FLATS`: Outline annotations with flat ends.
- `view.EOLANNOTATION_ANGLE_FLAT`: Outline annotations with angled left and flat right ends.
- `view.EOLANNOTATION_CIRCLE_ANGLE`: Outline annotations with curved left and angled right ends.
- `view.EOLANNOTATION_FLAT_ANGLE`: Outline annotations with flat left and angled right ends.
- `view.EOLANNOTATION_ANGLES`: Outline annotations with angled ends.

All annotations have the same shape.

The default value is `view.EOLANNOTATION_BOXED` in the GUI version and
`view.EOLANNOTATION_STANDARD` in the terminal version.

<a id="buffer.annotation_lines"></a>
#### `buffer.annotation_lines`

Map of line numbers to how many annotation text lines they have.
(Read-only)

### Mark Text with Indicators


There are 32 indicators to mark text with. Indicators have an assigned indicator style and
are displayed along with any existing styles text may already have. They can be hovered over
and clicked on. Indicators move along with text.

Indicator style | Description
-|-
`view.INDIC_SQUIGGLE` | A squiggly underline
`view.INDIC_PLAIN` | An underline
`view.INDIC_DASH` | A dashed underline
`view.INDIC_DOTS` | A dotted underline
`view.INDIC_STRIKE` | A strike out line
`view.INDIC_BOX` | A bounding box
`view.INDIC_DOTBOX` | A dotted bounding box<sup>a</sup>
`view.INDIC_STRAIGHTBOX` | A translucent bounding box<sup>b</sup>
`view.INDIC_ROUNDBOX` | A translucent bounding box with rounded corners<sup>b</sup>
`view.INDIC_FULLBOX` | A translucent box that extends to the top of its line<sup>b</sup>
`view.INDIC_GRADIENT` | A bounding box with a vertical gradient from solid to transparent
`view.INDIC_GRADIENTCENTER` | A bounding box with a centered gradient from solid to transparent
`view.INDIC_TT` | An underline of small 'T' shapes
`view.INDIC_DIAGONAL` | An underline of diagonal hatches
`view.INDIC_POINT` | A triangle below the start of the indicator range
`view.INDIC_POINTCHARACTER` | A triangle below the center of the first character
`view.INDIC_POINT_TOP` | A triangle above the start of the indicator range
`view.INDIC_SQUIGGLELOW` | A thin squiggly underline for small fonts
`view.INDIC_SQUIGGLEPIXMAP` | A faster version of `view.INDIC_SQUIGGLE`
`view.INDIC_COMPOSITIONTHICK` | A thick underline that looks like input composition
`view.INDIC_COMPOSITIONTHIN` | A thin underline that looks like input composition
`view.INDIC_TEXTFORE` | Changes text's foreground color
`view.INDIC_HIDDEN` | An indicator with no visual effect

<sup>a</sup>Translucency alternates between [`view.indic_alpha`](#view.indic_alpha) and [`view.indic_outline_alpha`](#view.indic_outline_alpha)
starting with the top-left pixel. Their default values are `30`, and `50`, respectively.<br/>
<sup>b</sup>[`view.indic_alpha`](#view.indic_alpha) and [`view.indic_outline_alpha`](#view.indic_outline_alpha) set the fill and outline
transparency, respectively. Their default values are `30`, and `50`, respectively.

There are 8 pre-defined indicators used for showing how buffer text differs from its file's
saved state if [`io.track_changes`](#io.track_changes) is `true`. These indicators are in addition to the 32
available for general use.

Indicator number | Description
-|-
`INDICATOR_HISTORY_MODIFIED_INSERTION` | Text was inserted and has not yet been saved
`INDICATOR_HISTORY_MODIFIED_DELETION` | Text was deleted but not yet saved
`INDICATOR_HISTORY_SAVED_INSERTION` | Text was inserted and saved
`INDICATOR_HISTORY_SAVED_DELETION` | Text was deleted and saved
`INDICATOR_HISTORY_REVERTED_TO_MODIFIED_INSERTION` | Text was inserted, saved, and semi-reverted
`INDICATOR_HISTORY_REVERTED_TO_MODIFIED_DELETION` | Text was deleted, saved, and semi-reverted
`INDICATOR_HISTORY_REVERTED_TO_ORIGIN_INSERTION` | Text was inserted, saved, and fully reverted
`INDICATOR_HISTORY_REVERTED_TO_ORIGIN_DELETION` | Text was deleted, saved, and fully reverted


<a id="view.new_indic_number"></a>
#### `view.new_indic_number`()

Returns a unique indicator number for use with custom indicators.

Use this function for custom indicators in order to prevent clashes with the numbers of
other custom indicators.

<a id="view.indic_style"></a>
#### `view.indic_style`

Map of indicator numbers to their indicator styles (`view.INDIC_*`).

Changing an indicator's style resets that indicator's hover style ([`view.indic_hover_style`](#view.indic_hover_style)).

<a id="buffer.indicator_current"></a>
#### `buffer.indicator_current`

The indicator number used by [`buffer:indicator_fill_range()`](#buffer.indicator_fill_range) and
[`buffer:indicator_clear_range()`](#buffer.indicator_clear_range).

<a id="buffer.indicator_fill_range"></a>
#### `buffer:indicator_fill_range`(*pos*, *length*)

Draws indicator number [`buffer.indicator_current`](#buffer.indicator_current) over a range of text.

Parameters:
- *pos*:  Start position of the range to indicate.
- *length*:  Number of characters to indicate.

<a id="buffer.indicator_clear_range"></a>
#### `buffer:indicator_clear_range`(*pos*, *length*)

Clears indicator number [`buffer.indicator_current`](#buffer.indicator_current) over a range of text.

Parameters:
- *pos*:  Start position of the range to clear the indicator from.
- *length*:  Number of characters to clear the indicator from.

<a id="buffer.indicator_start"></a>
#### `buffer:indicator_start`(*indicator*, *pos*)

Returns the previous boundary position of an indicator, or `1` if no indicator was found.

Parameters:
- *indicator*:  Indicator number to search for in the range of `1` to `32`.
- *pos*:  Position to start searching from.

<a id="buffer.indicator_end"></a>
#### `buffer:indicator_end`(*indicator*, *pos*)

Returns the next boundary position of an indicator, or `1` if no indicator was found.

Parameters:
- *indicator*:  Indicator number to search for in the range of `1` to `32`.
- *pos*:  Position to start searching from.

<a id="buffer.indicator_all_on_for"></a>
#### `buffer:indicator_all_on_for`(*pos*)

Returns a bit-mask of all of indicators at a position.

The first bit is set if indicator 1 is present, the second bit for indicator 2, and so on.

Parameters:
- *pos*:  Position to get indicators at.

<a id="view.indic_fore"></a>
#### `view.indic_fore`

Map of indicator numbers to their foreground colors in "0xBBGGRR" format.

Changing an indicator's foreground color resets that indicator's hover foreground color
([`view.indic_hover_fore`](#view.indic_hover_fore)).

<a id="view.indic_alpha"></a>
#### `view.indic_alpha`

Map of indicator numbers to their fill color alpha values.

An indicator whose indicator style is either `view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`,
or `view.INDIC_DOTBOX` will use the alpha value specified here.

The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.indic_outline_alpha"></a>
#### `view.indic_outline_alpha`

Map of indicator numbers to their outline color alpha values.

An indicator whose indicator style is either `view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`,
or `view.INDIC_DOTBOX` will use the alpha value specified here.

The default values are `view.ALPHA_NOALPHA`, for no alpha.

<a id="view.indic_under"></a>
#### `view.indic_under`

Map of indicator numbers to whether or not to draw them behind text instead of over the top
of it.

The default values are `false`.

<a id="view.indic_hover_style"></a>
#### `view.indic_hover_style`

Map of indicator numbers to their hover indicator styles.

Textadept draws an indicator's hover style when the mouse cursor is hovering over that
indicator, or when the caret is within the indicator.
The default values are their respective indicator styles; there is no visible hover effect.

See also: [`view.styles`](#view.styles), [`buffer.name_of_style`](#buffer.name_of_style)

<a id="view.indic_hover_fore"></a>
#### `view.indic_hover_fore`

Map of indicator numbers to their hover foreground colors in "0xBBGGRR" format.

The default values are their respective indicator foreground colors; there is no visible
hover effect.

Usage:

```lua
view.indic_hover_fore[indic_link] = 0xFF0000 -- hovering over links colors them blue
```

<a id="view.indic_stroke_width"></a>
#### `view.indic_stroke_width`

Map of indicator numbers to their stroke widths in hundredths of a pixel.

An indicator whose indicator style is either `view.INDIC_PLAIN`, `view.INDIC_SQUIGGLE`,
`view.INDIC_TT`, `view.INDIC_DIAGONAL`, `view.INDIC_STRIKE`, `view.INDIC_BOX`,
`view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`, `view.INDIC_FULLBOX`, `view.INDIC_DASH`,
`view.INDIC_DOTS`,  or `view.INDIC_SQUIGGLELOW` will use the stroke width specified here.

The default values are `100`, or 1 pixel.

### Display an Autocompletion or User List


There are two types of lists: autocompletion lists and user lists. An autocompletion list
is a list of completions shown for the current word. A user list is a more general list
of options presented to the user. Both types of list update as the user types, both have
similar behavior options, and both may [display images](#display-images-in-lists) alongside
text. Autocompletion lists should define a separator character and a list order before showing
the list. User lists should define a separator character, a list order, and an identifier
number before showing the list. An autocompletion list inserts its selected item, while a
user list emits an event with its selected item.

<a id="buffer.auto_c_separator"></a>
#### `buffer.auto_c_separator`

The byte value of the character that separates autocompletion and user list list items.

The default value is `32`, which is a space character (' ').

<a id="buffer.auto_c_order"></a>
#### `buffer.auto_c_order`

The order of an autocompletion or user list.

- `buffer.ORDER_PRESORTED`: Lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show) and [`buffer:user_list_show()`](#buffer.user_list_show)
	are in sorted, alphabetical order.
- `buffer.ORDER_PERFORMSORT`: Sort lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show) and
	[`buffer:user_list_show()`](#buffer.user_list_show).
- `buffer.ORDER_CUSTOM`: Lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show) and [`buffer:user_list_show()`](#buffer.user_list_show)
	are already in a custom order.

The default value is `buffer.ORDER_PRESORTED`.

<a id="buffer.auto_c_show"></a>
#### `buffer:auto_c_show`(*len_entered*, *items*)

Displays an autocompletion list.

Parameters:
- *len_entered*:  Number of characters behind the caret the word being autocompleted is.
- *items*:  String list of completions to show, separated by [`buffer.auto_c_separator`](#buffer.auto_c_separator)
	characters. The sort order of this list ([`buffer.auto_c_order`](#buffer.auto_c_order)) must have already
	been specified.

See also: [`textadept.editing.autocompleters`](#textadept.editing.autocompleters), [`textadept.editing.autocomplete`](#textadept.editing.autocomplete)

<a id="view.new_user_list_type"></a>
#### `view.new_user_list_type`()

Returns a unique user list identifier number for use with [`buffer:user_list_show()`](#buffer.user_list_show).

Use this function for custom user lists in order to prevent clashes with list identifiers
of other custom user lists.

<a id="buffer.user_list_show"></a>
#### `buffer:user_list_show`(*id*, *items*)

Displays a user list.

When the user selects an item, [`events.USER_LIST_SELECTION`](#events.USER_LIST_SELECTION) is emitted.

Parameters:
- *id*:  List identifier number to use, which must be greater than zero.
- *items*:  String list of list items to show, separated by [`buffer.auto_c_separator`](#buffer.auto_c_separator)
	characters. The sort order of this list ([`buffer.auto_c_order`](#buffer.auto_c_order)) must have already
	been specified.

<a id="buffer.auto_c_select"></a>
#### `buffer:auto_c_select`(*prefix*)

Selects the first item that matches a prefix in an autocompletion or user list.

If [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`, searches case-insensitively.

Parameters:
- *prefix*:  String prefix to search for.

<a id="buffer.auto_c_complete"></a>
#### `buffer:auto_c_complete`()

Completes the current word with the one selected in an autocompletion list.

<a id="buffer.auto_c_cancel"></a>
#### `buffer:auto_c_cancel`()

Cancels the active autocompletion or user list.

<a id="buffer.auto_c_active"></a>
#### `buffer:auto_c_active`()

Returns whether or not an autocompletion or user list is visible.

<a id="buffer.auto_c_pos_start"></a>
#### `buffer:auto_c_pos_start`()

Returns the position where autocompletion started or where a user list was shown.

<a id="buffer.auto_c_current"></a>
#### `buffer.auto_c_current`

The index of the currently selected item in an autocompletion or user list.
(Read-only)

<a id="buffer.auto_c_current_text"></a>
#### `buffer.auto_c_current_text`

The text of the currently selected item in an autocompletion or user list.
(Read-only)

<a id="buffer.auto_c_choose_single"></a>
#### `buffer.auto_c_choose_single`

Automatically choose the item in a single-item autocompletion list.

This option has no effect for a user list.
The default value is `true`.

<a id="buffer.auto_c_fill_ups"></a>
#### `buffer.auto_c_fill_ups`

The set of characters that, when the user types one of them, chooses the currently selected
item in an autocompletion or user list.
(Write-only)
The default value is the empty string.

<a id="buffer.auto_c_stops"></a>
#### `buffer:auto_c_stops`(*chars*)

Specify a set of characters that cancels an autocompletion or user list when the user types
one of them.

Parameters:
- *chars*:  String set of characters that cancel autocompletion. This string is empty
	by default.

<a id="buffer.auto_c_auto_hide"></a>
#### `buffer.auto_c_auto_hide`

Automatically cancel an autocompletion or user list when no entries match typed text.

The default value is `true`.

<a id="buffer.auto_c_cancel_at_start"></a>
#### `buffer.auto_c_cancel_at_start`

Cancel an autocompletion list when backspacing to a position before where autocompletion
started (instead of before the word being completed).

This option has no effect for a user list.
The default value is `true`.

<a id="buffer.auto_c_ignore_case"></a>
#### `buffer.auto_c_ignore_case`

Ignore case when searching an autocompletion or user list for matches.

The default value is `false`.

<a id="buffer.auto_c_case_insensitive_behavior"></a>
#### `buffer.auto_c_case_insensitive_behavior`

Prefer case-sensitive matches even if [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`.

- `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`: Prefer to select case-sensitive matches.
- `buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE`: No preference.

The default value is `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`.

<a id="view.auto_c_max_width"></a>
#### `view.auto_c_max_width`

The maximum number of characters per item to show in autocompletion and user lists.

The default value is `0`, which automatically sizes the width to fit the longest item.

<a id="view.auto_c_max_height"></a>
#### `view.auto_c_max_height`

The maximum number of items per page to show in autocompletion and user lists.

The default value is `5`.

<a id="buffer.auto_c_drop_rest_of_word"></a>
#### `buffer.auto_c_drop_rest_of_word`

Delete any word characters immediately to the right of autocompleted text.

The default value is `false`.

<a id="buffer.auto_c_multi"></a>
#### `buffer.auto_c_multi`

Autocomplete into multiple selections.

- `buffer.MULTIAUTOC_ONCE`: Autocomplete into only the main selection.
- `buffer.MULTIAUTOC_EACH`: Autocomplete into all selections.

The default value is `buffer.MULTIAUTOC_EACH`.

### Display Images in Lists


Autocompletion and user lists can render images next to items by appending to each list
item the type separator character specific to lists followed by an image's type number that
uniquely identifies a registered image.

```lua
local image = view.new_image_type()
events.connect(events.VIEW_NEW, function()
	view:register_image(image, [[/* XPM */...]])
end)

local function autocomplete()
	local list = {
		string.format('foo%s%d', string.char(buffer.auto_c_type_separator), image),
		'bar',
		'baz'
	}
	buffer.auto_c_order = buffer.ORDER_PERFORMSORT
	buffer:auto_c_show(0, table.concat(list, string.char(buffer.auto_c_separator)))
end
```

<a id="view.new_image_type"></a>
#### `view.new_image_type`()

Returns a unique image type number for use with [`view:register_image()`](#view.register_image) and
[`view:register_rgba_image()`](#view.register_rgba_image).

Use this function for custom image types in order to prevent clashes with numbers of
other custom image types.

<a id="view.register_image"></a>
#### `view:register_image`(*type*, *pixmap*)

Registers an XPM image to an image type number for use in autocompletion and user lists.

Parameters:
- *type*:  Image type number to register the image with.
- *pixmap*:  String [pixmap data](https://scintilla.org/ScintillaDoc.html#XPM).

<a id="view.rgba_image_width"></a>
#### `view.rgba_image_width`

The width of the RGBA image to be defined using [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image) and
[`view:register_rgba_image()`](#view.register_rgba_image).

<a id="view.rgba_image_height"></a>
#### `view.rgba_image_height`

The height of the RGBA image to be defined using [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image) and
[`view:register_rgba_image()`](#view.register_rgba_image).

<a id="view.rgba_image_scale"></a>
#### `view.rgba_image_scale`

The scale factor in percent of the RGBA image to be defined using
[`view:marker_define_rgba_image()`](#view.marker_define_rgba_image) and [`view:register_rgba_image()`](#view.register_rgba_image).

This is useful on macOS with a retina display where each display unit is 2 pixels: use a
factor of `200` so that each image pixel is displayed using a screen pixel.
The default scale, `100`, will stretch each image pixel to cover 4 screen pixels on a
retina display.

<a id="view.register_rgba_image"></a>
#### `view:register_rgba_image`(*type*, *pixels*)

Registers an RGBA image to an image type number for use in autocompletion and user lists.

Parameters:
- *type*:  Type number to register the image with.
- *pixels*:  String sequence of 4 byte pixel values (red, green, blue, and alpha) starting
	with the pixels for the top line, with the leftmost pixel first, then continuing with
	the pixels for subsequent lines. There is no gap between lines for alignment reasons.
	The image dimensions, [`view.rgba_image_width`](#view.rgba_image_width) and [`view.rgba_image_height`](#view.rgba_image_height), must have
	already been defined.

<a id="buffer.auto_c_type_separator"></a>
#### `buffer.auto_c_type_separator`

The character byte that separates autocompletion and user list items and their image types.

Autocompletion and user list items can display both an image and text. Register images and
their types using [`view:register_image()`](#view.register_image) or [`view:register_rgba_image()`](#view.register_rgba_image) before appending
image types to list items after type separator characters.
The default value is `63` ('?').

<a id="view.clear_registered_images"></a>
#### `view:clear_registered_images`()

Clears all images registered by [`view:register_image()`](#view.register_image) and [`view:register_rgba_image()`](#view.register_rgba_image).

### Show a Call Tip


A call tip is a small pop-up window that conveys a piece of textual information, such as
the arguments and documentation for a function. A call tip may highlight an internal range
of its own text, such as the current argument in a function call.

<a id="view.call_tip_show"></a>
#### `view:call_tip_show`(*pos*, *text*)

Displays a call tip.

Parameters:
- *pos*:  Position in the view's buffer to show a call tip at.
- *text*:  Call tip text to show. Any "\001" or "\002" bytes are replaced by clickable up
 or down arrow visuals, respectively. These may be used to indicate that a symbol has more
 than one call tip, for example.

See also: [`events.CALL_TIP_CLICK`](#events.CALL_TIP_CLICK)

<a id="view.call_tip_set_hlt"></a>
#### `view:call_tip_set_hlt`(*start_pos*, *end_pos*)

Highlights a range of the call tip's text with the color [`view.call_tip_fore_hlt`](#view.call_tip_fore_hlt).

Parameters:
- *start_pos*:  Start position in call tip text to highlight.
- *end_pos*:  End position in call tip text to highlight.

<a id="view.call_tip_cancel"></a>
#### `view:call_tip_cancel`()

Hides the active call tip.

<a id="view.call_tip_active"></a>
#### `view:call_tip_active`()

Returns whether or not a call tip is visible.

<a id="view.call_tip_pos_start"></a>
#### `view:call_tip_pos_start`()

Returns a call tip's display position.

<a id="view.call_tip_position"></a>
#### `view.call_tip_position`

Display a call tip above the current line instead of below it.

The default value is `false`.

<a id="view.call_tip_use_style"></a>
#### `view.call_tip_use_style`

The pixel width of tab characters in call tips.

When non-zero, also enables the use of style number `view.STYLE_CALLTIP` instead of
`view.STYLE_DEFAULT` for call tip styles.

The default value is non-zero and depends on [`buffer.tab_width`](#buffer.tab_width) and the current font.

<a id="view.call_tip_pos_start"></a>
#### `view.call_tip_pos_start`

The position at which backspacing beyond it hides an active call tip.
(Write-only)

<a id="view.call_tip_fore_hlt"></a>
#### `view.call_tip_fore_hlt`

A call tip's highlighted text foreground color in "0xBBGGRR" format.
(Write-only)

### Fold or Hide Lines


Code folding temporarily hide blocks of source code. The buffer's lexer normally determines
code fold points that the view denotes with fold margin markers, but arbitrary lines may be
hidden or shown.

<a id="view.toggle_fold"></a>
#### `view:toggle_fold`(*line*)

Toggles the fold point on a line between expanded (where all of its child lines are visible)
and contracted (where all of its child lines are hidden).

Parameters:
- *line*:  Line number to toggle the fold on.

<a id="view.set_default_fold_display_text"></a>
#### `view:set_default_fold_display_text`(*text*)

Sets the default text shown next to folded lines.

Parameters:
- *text*:  String text to display after folded lines. It is drawn with the
	`view.STYLE_FOLDDISPLAYTEXT` style.

Usage:

```lua
view:set_default_fold_display_text(' ... ')
```

<a id="view.toggle_fold_show_text"></a>
#### `view:toggle_fold_show_text`(*line*, *text*)

Toggles the fold point on a line and shows the given text next to that line if it is collapsed.

This overrides any default text set by [`view:set_default_fold_display_text()`](#view.set_default_fold_display_text).

Parameters:
- *line*:  Line number to toggle the fold on and display *text* next to.
- *text*:  String text to display after the line. It is drawn with the
	`view.STYLE_FOLDDISPLAYTEXT` style.

<a id="view.fold_line"></a>
#### `view:fold_line`(*line*, *action*)

Contracts, expands, or toggles the fold point on a line.

Parameters:
- *line*:  Line number to set the fold state for.
- *action*:  Fold action to perform:
	- `view.FOLDACTION_CONTRACT`
	- `view.FOLDACTION_EXPAND`
	- `view.FOLDACTION_TOGGLE`

<a id="view.fold_children"></a>
#### `view:fold_children`(*line*, *action*)

Contracts, expands, or toggles the fold points on a line and on all of its child lines.

Parameters:
- *line*:  Line number to set the fold states for.
- *action*:  Fold action to perform:
	- `view.FOLDACTION_CONTRACT`
	- `view.FOLDACTION_EXPAND`
	- `view.FOLDACTION_TOGGLE`

<a id="view.fold_all"></a>
#### `view:fold_all`(*action*)

Contracts, expands, or toggles all fold points in the buffer.

When toggling, the state of the first fold point determines whether to expand or contract.

Parameters:
- *action*:  Fold action to perform:
	- `view.FOLDACTION_CONTRACT`
	- `view.FOLDACTION_EXPAND`
	- `view.FOLDACTION_TOGGLE`
	- `view.FOLDACTION_CONTRACT_EVERY_LEVEL`

<a id="view.hide_lines"></a>
#### `view:hide_lines`(*start_line*, *end_line*)

Hides a range of lines.

This has no effect on fold levels or fold flags.

Parameters:
- *start_line*:  Start line of the range to hide.
- *end_line*:  End line of the range to hide.

<a id="view.show_lines"></a>
#### `view:show_lines`(*start_line*, *end_line*)

Shows a range of lines.

This has no effect on fold levels or fold flags and the first line cannot be hidden.

Parameters:
- *start_line*:  Start line of the range to show.
- *end_line*:  End line of the range to show.

<a id="view.ensure_visible"></a>
#### `view:ensure_visible`(*line*)

Ensures a line is visible by expanding any fold points hiding it.

Parameters:
- *line*:  Line number to ensure visible.

<a id="view.ensure_visible_enforce_policy"></a>
#### `view:ensure_visible_enforce_policy`(*line*)

Ensures a line is visible by expanding any fold points hiding it based on the vertical caret
policy previously defined in [`view:set_visible_policy()`](#view.set_visible_policy).

Parameters:
- *line*:  Line number to ensure visible.

<a id="view.get_default_fold_display_text"></a>
#### `view:get_default_fold_display_text`()

Returns the default text shown next to folded lines.

<a id="buffer.fold_level"></a>
#### `buffer.fold_level`

Map of line numbers to their fold level bit-masks.

Fold level bit-masks comprise an integer level combined with any of the following bit flags:
- `buffer.FOLDLEVELBASE`: The initial fold level.
- `buffer.FOLDLEVELWHITEFLAG`: The line is blank.
- `buffer.FOLDLEVELHEADERFLAG`: The line is a header, or fold point.

<a id="buffer.fold_parent"></a>
#### `buffer.fold_parent`

Map of line numbers to their parent fold point line numbers.
(Read-only)
A result of `-1` means the line has no parent fold point.

<a id="buffer.get_last_child"></a>
#### `buffer:get_last_child`(*line*, *level*)

Returns the line number of a fold point's last child line.

Parameters:
- *line*:  Line number of a fold point line.
- *level*:  `-1`. For any other value, the line number of the last line after *line* whose
	fold level is greater than *level* is returned.

<a id="view.fold_expanded"></a>
#### `view.fold_expanded`

Map of line numbers to whether or not their fold points (if any) are expanded.

Setting expanded fold states does not toggle folds; it only updates fold margin markers. Use
[`view:toggle_fold()`](#view.toggle_fold) instead.

<a id="view.contracted_fold_next"></a>
#### `view:contracted_fold_next`(*line*)

Returns the line number of the next contracted fold point, or `-1` if none exists.

Parameters:
- *line*:  Line number to start searching at.

<a id="view.line_visible"></a>
#### `view.line_visible`

Map of line numbers to whether or not they are visible.
(Read-only)

<a id="view.all_lines_visible"></a>
#### `view.all_lines_visible`

Whether or not all lines are visible.
(Read-only)

### Scroll the View

<a id="view.x_offset"></a>
#### `view.x_offset`

The horizontal scroll pixel position.

The default value is `0`.

See also: [`view.first_visible_line`](#view.first_visible_line)

<a id="view.line_scroll_up"></a>
#### `view:line_scroll_up`()

Scrolls the buffer up one line, keeping the caret visible.

<a id="view.line_scroll_down"></a>
#### `view:line_scroll_down`()

Scrolls the buffer down one line, keeping the caret visible.

<a id="view.line_scroll"></a>
#### `view:line_scroll`(*columns*, *lines*)

Scrolls the buffer by columns and lines.

Parameters:
- *columns*:  Number of columns to scroll horizontally. A negative value is allowed.
- *lines*:  Number of lines to scroll vertically. A negative value is allowed.

<a id="view.scroll_caret"></a>
#### `view:scroll_caret`()

Scrolls the caret into view based on the policies previously defined in
[`view:set_x_caret_policy()`](#view.set_x_caret_policy) and [`view:set_y_caret_policy()`](#view.set_y_caret_policy).

<a id="view.scroll_range"></a>
#### `view:scroll_range`(*secondary_pos*, *primary_pos*)

Scrolls a range of text into view.

This is similar to [`view:scroll_caret()`](#view.scroll_caret), but with *primary_pos* instead of the caret.
It is useful for scrolling search results into view.

Parameters:
- *secondary_pos*:  Secondary range position to scroll into view.
- *primary_pos*:  Primary range position to scroll into view. Priority is given to this position.

<a id="view.vertical_center_caret"></a>
#### `view:vertical_center_caret`()

Centers the current line in the view.

<a id="view.scroll_to_start"></a>
#### `view:scroll_to_start`()

Scrolls to the beginning of the buffer without moving the caret.

<a id="view.scroll_to_end"></a>
#### `view:scroll_to_end`()

Scrolls to the end of the buffer without moving the caret.

### Configure Indentation and Line Endings


Each buffer and file has its own indentation and end-of-line character settings.

<a id="buffer.use_tabs"></a>
#### `buffer.use_tabs`

Use tabs instead of spaces in indentation.

Changing this does not convert any of the buffer's existing indentation. Use
[`textadept.editing.convert_indentation()`](#textadept.editing.convert_indentation) to do so.
The default value is `true`.

<a id="buffer.tab_width"></a>
#### `buffer.tab_width`

The number of space characters a tab character represents.

The default value is `8`.

<a id="buffer.indent"></a>
#### `buffer.indent`

The number of spaces in one level of indentation.

The default value is `0`, which uses the value of [`buffer.tab_width`](#buffer.tab_width).

<a id="buffer.tab_indents"></a>
#### `buffer.tab_indents`

Indent text when tabbing within indentation.

The default value is `true`.

See also: [`textadept.editing.auto_indent`](#textadept.editing.auto_indent)

<a id="buffer.back_space_un_indents"></a>
#### `buffer.back_space_un_indents`

Un-indent text when backspacing within indentation.

The default value is `true`.

<a id="buffer.eol_mode"></a>
#### `buffer.eol_mode`

The current end of line mode.

Changing this does not convert any of the buffer's existing end of line characters. Use
[`buffer:convert_eols()`](#buffer.convert_eols) to do so.

- `buffer.EOL_CRLF`: Carriage return with line feed ("\r\n").
- `buffer.EOL_CR`: Carriage return ("\r").
- `buffer.EOL_LF`: Line feed ("\n").

The default value is `buffer.EOL_CRLF` on Windows platforms, and `buffer.EOL_LF` otherwise.

<a id="buffer.convert_eols"></a>
#### `buffer:convert_eols`(*mode*)

Changes all end of line characters in the buffer.

This does not change [`buffer.eol_mode`](#buffer.eol_mode).

Parameters:
- *mode*:  End of line mode to change to.
	- `buffer.EOL_CRLF`
	- `buffer.EOL_CR`
	- `buffer.EOL_LF`

### Configure Character Settings


The classification of characters as word, whitespace, or punctuation characters affects the
buffer's behavior when moving between words or searching for whole words. The display of
individual characters may be changed.

<a id="buffer.word_chars"></a>
#### `buffer.word_chars`

The string set of characters recognized as word characters.

The default value is a string that contains alphanumeric characters, an underscore, and all
characters greater than ASCII value 127.

<a id="buffer.whitespace_chars"></a>
#### `buffer.whitespace_chars`

The string set of characters recognized as whitespace characters.

Set this only after setting [`buffer.word_chars`](#buffer.word_chars).
The default value is a string that contains all non-newline characters less than ASCII value 33.

<a id="buffer.punctuation_chars"></a>
#### `buffer.punctuation_chars`

The string set of characters recognized as punctuation characters.

Set this only after setting [`buffer.word_chars`](#buffer.word_chars).
The default value is a string that contains all non-word and non-whitespace characters.

<a id="buffer.set_chars_default"></a>
#### `buffer:set_chars_default`()

Resets [`buffer.word_chars`](#buffer.word_chars), [`buffer.whitespace_chars`](#buffer.whitespace_chars), and [`buffer.punctuation_chars`](#buffer.punctuation_chars) to
their respective defaults.

<a id="view.representation"></a>
#### `view.representation`

Map of character strings to their alternative string representations.

Use the empty string for the '\0' character when assigning its representation.
Call [`view:clear_representation()`](#view.clear_representation) to remove a representation.

Usage:

```lua
view.representation['⌘'] = '⌘ (U+2318)'
```

<a id="view.clear_representation"></a>
#### `view:clear_representation`(*char*)

Removes a character's alternate string representation.

Parameters:
- *char*:  String character in [`view.representation`](#view.representation) to remove. It may be a multi-byte
	character.

<a id="view.clear_all_representations"></a>
#### `view:clear_all_representations`()

Removes all alternate string representations of characters.

<a id="view.representation_appearance"></a>
#### `view.representation_appearance`

Map of character strings to their representation's appearance.

- `view.REPRESENTATION_PLAIN`: Draw the representation with no decoration.
- `view.REPRESENTATION_BLOB`: Draw the representation within a rounded rectangle and an
	inverted color.
- `view.REPRESENTATION_COLOR`: Draw the representation using the color set in
	[`view.representation_color`](#view.representation_color).

The default values are `view.REPRESENTATION_BLOB`.

<a id="view.representation_color"></a>
#### `view.representation_color`

Map of character strings to their representation's color in "0xBBGGRR" format.

### Configure the Color Theme


Themes are Lua files that define colors, specify how the view displays text, and assign
colors and alpha values to various view properties.

#### Colors

Colors are numbers in "0xBBGGRR" format that range from `0` (black) to `0xFFFFFF` (white). The
low byte (RR) is the red component, the middle byte (GG) is green, and the high byte (BB)
is blue. Each component ranges from `0` to `0xFF` (255).

Alpha transparency values are numbers that range from `0` (transparent) to `0xFF` (opaque),
and also includes `view.ALPHA_NOALPHA` for no transparency.

**Terminal version note:** if your terminal emulator does not support RGB colors, or if you
would like to use your terminal's palette of up to 16 colors, you must use the following colors:

`0x000000` | Black | `0x404040` | Light black
`0x000080` | Red | `0x0000FF` | Light red
`0x008000` | Green | `0x00FF00` | Light green
`0x800000` | Blue | `0xFF0000` | Light blue
`0x800080` | Magenta | `0xFF00FF` | Light magenta
`0x808000` | Cyan | `0xFFFF00` | Light cyan
`0xC0C0C0` | White | `0xFFFFFF` | Light white

Your terminal emulator will map these colors to its palette for display.

#### Styles

Styles define how to display text, from the default font to line numbers in the margin,
to source code comments, strings, and keywords. Each of these elements has a style name
assigned to a table of style properties.

Style name | Target element
-|-
`view.STYLE_DEFAULT` | Everything (all elements inherit from this one)
`view.STYLE_LINENUMBER` | The line number margin
`view.STYLE_BRACELIGHT` | Highlighted brace characters
`view.STYLE_BRACEBAD` | A brace character with no match
`view.STYLE_CONTROLCHAR` | Control character blocks
`view.STYLE_INDENTGUIDE` | Indentation guides
`view.STYLE_CALLTIP` | Call tip text<sup>a</sup>
`view.STYLE_FOLDDISPLAYTEXT` | Text displayed next to folded lines
`lexer.ATTRIBUTE` | Language-specific
`lexer.BOLD` | Language-specific
`lexer.CLASS` | Language-specific
`lexer.CODE` | Language-specific
`lexer.COMMENT` | Language-specific
`lexer.CONSTANT` | Language-specific
`lexer.CONSTANT_BUILTIN` | Language-specific
`lexer.EMBEDDED` | Language-specific
`lexer.ERROR` | Language-specific
`lexer.FUNCTION` | Language-specific
`lexer.FUNCTION_BUILTIN` | Language-specific
`lexer.FUNCTION_METHOD` | Language-specific
`lexer.IDENTIFIER` | Language-specific
`lexer.ITALIC` | Language-specific
`lexer.KEYWORD` | Language-specific
`lexer.LABEL` | Language-specific
`lexer.LINK` | Language-specific
`lexer.NUMBER` | Language-specific
`lexer.OPERATOR` | Language-specific
`lexer.PREPROCESSOR` | Language-specific
`lexer.REFERENCE` | Language-specific
`lexer.REGEX` | Language-specific
`lexer.STRING` | Language-specific
`lexer.TAG` | Language-specific
`lexer.TYPE` | Language-specific
`lexer.UNDERLINE` | Language-specific
`lexer.VARIABLE` | Language-specific
`lexer.VARIABLE_BUILTIN` | Language-specific

<sup>a</sup> Only the `font`, `size`, `fore`, and `back` style properties are supported.

The table above is not an exhaustive list of style names. Some lexers may define their own.

Style property | Description
-|-
`font` | String font name
`size` | Integer font size
`bold` | Use a bold font face (the default value is `false`)
`weight` | Integer weight or boldness of a font, between 1 and 999
`italic` | Use an italic font face (the default value is `false`)
`underline` | Use an underlined font face (the default value is `false`)
`fore` | Font face foreground color in "0xBBGGRR" format
`back` | Font face background color in "0xBBGGRR" format
`eol_filled` | Extend the background color to the end of the line (the default value is `false`)
`case` | Font case<sup>a</sup>
`visible` | The text is visible instead of hidden (the default value is `true`)
`changeable` | The text is changeable instead of read-only t(he default value is `true`)

<sup>a</sup>`view.CASE_UPPER` for upper, `view.CASE_LOWER` for lower, and `view.CASE_MIXED`
for normal, mixed case. The default value is `view.CASE_MIXED`.

<a id="view.set_theme"></a>
#### `view:set_theme`([*name*][, *env*])

Sets the view's color theme.

User themes in *~/.textadept/themes/* override Textadept's default themes when they have
the same name.

Parameters:
- *name*:  String theme name. If it contains slashes, it is assumed to be an absolute
	path to a theme. The default value is either 'light' or 'dark', depending on whether
	the OS is in light mode or dark mode, respectively.
- *env*:  Table of global variables that themes can utilize to override default settings
	such as font and size.

Usage:

```lua
view:set_theme{font = 'Monospace', size = 12} -- keep current theme, but change font
view:set_theme('my_theme', {font = 'Monospace', size = 12})
```

<a id="view.colors"></a>
#### `view.colors`

Map of color name strings to color values in "0xBBGGRR" format.

A theme typically sets this map's contents. Changing colors manually (e.g. via the command
entry) has no effect since colors are referenced by value, not name.

Terminal version note: if your terminal emulator does not support RGB colors, or if you would
like to use your terminal's palette of up to 16 colors, use the following color values:
0x000000 (black), 0x000080 (red), 0x008000 (green), 0x008080 (yellow), 0x800000 (blue),
0x800080 (magenta), 0x808000 (cyan), white (0xC0C0C0), light 0x404040 (black), 0x0000FF
(light red), 0x00FF00 (light green), 0x00FFFF (light yellow), 0xFF0000 (light blue), 0xFF00FF
(light magenta), 0xFFFF00 (light cyan), and 0xFFFFFF (light white).

<a id="view.styles"></a>
#### `view.styles`

Map of style names to style definition tables.

A theme typically sets this map's contents. If you are setting it manually (e.g. via the
command entry), call [`view:set_styles()`](#view.set_styles) to refresh the view and apply the styles.

Predefined style names are `view.STYLE_*` and `lexer.[A-Z]*`, and lexers may define their
own. To see the name of the style under the caret, use the "Tools > Show Style" menu item.

Terminal version note: displaying light colors may require a normal foreground color coupled
with a `bold = true` setting.

Usage:

```lua
view.styles[view.STYLE_DEFAULT] = {
	font = 'Monospace', size = '10', fore = view.colors.black, back = view.colors.white
}
view.styles[lexer.KEYWORD] = {bold = true}
view.styles[lexer.ERROR] = {fore = view.colors.red, italic = true}
```

<a id="view.set_styles"></a>
#### `view:set_styles`()

Applies defined styles to the view.

This should be called any time a style in [`view.styles`](#view.styles) changes.

### Override Style Settings


There are 256 different styles to style text with. The color theme normally dictates
default styles, but custom fonts, colors, and attributes may be applied to styles outside
of themes. However, these custom settings must be re-applied every time a new buffer or view
is created, and every time a lexer is loaded.

<a id="view.style_reset_default"></a>
#### `view:style_reset_default`()

Resets `view.STYLE_DEFAULT` to its initial state.

<a id="view.style_clear_all"></a>
#### `view:style_clear_all`()

Reverts all styles to having the same properties as `view.STYLE_DEFAULT`.

<a id="view.style_font"></a>
#### `view.style_font`

Map of style numbers to their text's string font names.

<a id="view.style_size"></a>
#### `view.style_size`

Map of style numbers to their text's integer font sizes.

<a id="view.style_fore"></a>
#### `view.style_fore`

Map of style numbers to their text's foreground colors in "0xBBGGRR" format.

<a id="view.style_back"></a>
#### `view.style_back`

Map of style numbers to their text's background colors in "0xBBGGRR" format.

<a id="view.style_bold"></a>
#### `view.style_bold`

Map of style numbers to whether or not their text is bold.

The default values are `false`.

<a id="view.style_italic"></a>
#### `view.style_italic`

Map of style numbers to whether or not their text is italic.

The default values are `false`.

<a id="view.style_underline"></a>
#### `view.style_underline`

Map of style numbers to whether or not their text is underlined.

The default values are `false`.

<a id="view.style_eol_filled"></a>
#### `view.style_eol_filled`

Map of style numbers to whether or not their text's background colors extend all the way to
the view's right margin.

This only happens for styles whose characters occur last on lines.

The default values are `false`.

<a id="view.style_case"></a>
#### `view.style_case`

Map of style numbers to their text's letter-cases.

- `view.CASE_MIXED`: Display text normally.
- `view.CASE_UPPER`: Display text in upper case.
- `view.CASE_LOWER`: Display text in lower case.
- `view.CASE_CAMEL`: Display text in camel case.

The default values are `view.CASE_MIXED`.

<a id="view.style_visible"></a>
#### `view.style_visible`

Map of style numbers to whether or not their text is visible.

The default values are `true`.

<a id="view.style_changeable"></a>
#### `view.style_changeable`

Map of style numbers to their text's mutability.

Read-only styles do not allow the caret into ranges of their text.

The default values are `true`.

### Assign Caret, Selection, Whitespace, and Line Colors


The colors of various UI elements can be changed by assigning colors to their element IDs
in the [`view.element_color`](#view.element_color) map.

Element ID | Description
-|-
`view.ELEMENT_SELECTION_TEXT` | Main selection text color
`view.ELEMENT_SELECTION_BACK` | Main selection background color
`view.ELEMENT_SELECTION_ADDITIONAL_TEXT` | Additional selection text color
`view.ELEMENT_SELECTION_ADDITIONAL_BACK` | Additional selection background color
`view.ELEMENT_SELECTION_SECONDARY_TEXT` | Secondary selection text color<sup>a</sup>
`view.ELEMENT_SELECTION_SECONDARY_BACK` | Secondary selection background color<sup>a</sup>
`view.ELEMENT_SELECTION_INACTIVE_TEXT` | Selection text color when another window has focus
`view.ELEMENT_SELECTION_INACTIVE_BACK` | Selection background color when another window has focus
`view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_TEXT` | Inactive additional selection text color
`view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_BACK` | Inactive additional selection background color
`view.ELEMENT_CARET` | Main selection caret color
`view.ELEMENT_CARET_ADDITIONAL` | Additional selection caret color
`view.ELEMENT_CARET_LINE_BACK` | Background color of the line that contains the caret
`view.ELEMENT_WHITE_SPACE` | Visible whitespace color
`view.ELEMENT_WHITE_SPACE_BACK` | Visible whitespace background color
`view.ELEMENT_FOLD_LINE` | Fold line color
`view.ELEMENT_HIDDEN_LINE` | The color of lines shown in place of hidden lines

<sup>a</sup>Linux only


<a id="view.element_color"></a>
#### `view.element_color`

Map of UI element identifiers (`view.ELEMENT_*`) to their colors in "0xAABBGGRR" format.

If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).

<a id="view.element_is_set"></a>
#### `view.element_is_set`

Map of UI element identifiers to whether or not their colors have been manually set.

<a id="view.reset_element_color"></a>
#### `view:reset_element_color`(*element*)

Resets the color of a UI element to its default color.

Parameters:
- *element*:  One of the `view.ELEMENT_*` UI elements.

<a id="view.element_base_color"></a>
#### `view.element_base_color`

Map of UI element identifiers to their default colors in "0xAABBGGRR" format.
(Read-only)

<a id="view.element_allows_translucent"></a>
#### `view.element_allows_translucent`

Map of UI element identifiers to whether or not their elements support translucent colors.

<a id="view.selection_layer"></a>
#### `view.selection_layer`

How selections are drawn.

- `view.LAYER_BASE`: Draw selections opaquely on the background.
- `view.LAYER_UNDER_TEXT`: Draw selections translucently under text.
- `view.LAYER_OVER_TEXT`: Draw selections translucently over text.

The default value is `view.LAYER_BASE`.

### Configure Caret Display

<a id="view.caret_style"></a>
#### `view.caret_style`

The caret's visual style.

- `view.CARETSTYLE_INVISIBLE`: No caret.
- `view.CARETSTYLE_LINE`: A line caret.
- `view.CARETSTYLE_BLOCK`: A block caret.

The default value is `view.CARETSTYLE_LINE`.

<a id="view.caret_width"></a>
#### `view.caret_width`

The line caret's pixel width in insert mode, between `0` and `20`.

The default value is `1`.

<a id="view.caret_period"></a>
#### `view.caret_period`

The time between caret blinks in milliseconds.

A value of `0` stops blinking.

The default value is `500`.

<a id="view.caret_line_frame"></a>
#### `view.caret_line_frame`

The caret line's frame width in pixels.

When non-zero, the line that contains the caret is framed instead of colored in. The
`view.ELEMENT_CARET_LINE_BACK` color applies to the frame.

The default value is `0`.

<a id="view.caret_line_highlight_subline"></a>
#### `view.caret_line_highlight_subline`

Show the caret line on sublines rather than entire wrapped lines.

The defalt value is `false`.

<a id="view.caret_line_visible_always"></a>
#### `view.caret_line_visible_always`

Always show the caret line, even when the view is not in focus.

The default value is `true`, but only for the current view, and only while Textadept has focus.

<a id="view.caret_line_layer"></a>
#### `view.caret_line_layer`

How the caret line is drawn.

- `view.LAYER_BASE`: Draw the caret line opaquely on the background.
- `view.LAYER_UNDER_TEXT`: Draw the caret line translucently under text.
- `view.LAYER_OVER_TEXT`: Draw the caret line translucently over text.

The default value is `view.LAYER_BASE`.

<a id="view.additional_carets_visible"></a>
#### `view.additional_carets_visible`

Display additional carets.

The default value is `true`.

<a id="view.additional_carets_blink"></a>
#### `view.additional_carets_blink`

Allow additional carets to blink.

The default value is `true`.

<a id="buffer.virtual_space_options"></a>
#### `buffer.virtual_space_options`

Enable virtual space, allowing the caret to move into the space past end of line characters.

This is either `buffer.VS_NONE` (disable virtual space) or a bit-mask of the following options:
- `buffer.VS_RECTANGULARSELECTION`: Enable virtual space only for rectangular selections.
- `buffer.VS_USERACCESSIBLE`: Enable virtual space outside of rectangular selections.
- `buffer.VS_NOWRAPLINESTART`: Prevent the caret from wrapping to the previous line via
	[`buffer:char_left()`](#buffer.char_left) and [`buffer:char_left_extend()`](#buffer.char_left_extend).

The default value is `buffer.VS_NONE`.

### Configure Selection Display

<a id="view.sel_eol_filled"></a>
#### `view.sel_eol_filled`

Extend the selection to the view's right margin if it spans multiple lines.

The default value is `false`.

### Configure Whitespace Display


Normally, tab, space, and end of line characters are invisible.

<a id="view.view_ws"></a>
#### `view.view_ws`

Show whitespace characters.

- `view.WS_INVISIBLE`: Whitespace is invisible.
- `view.WS_VISIBLEALWAYS`: Display all space characters as dots and tab characters as arrows.
- `view.WS_VISIBLEAFTERINDENT`: Display only non-indentation spaces and tabs as dots and arrows.
- `view.WS_VISIBLEONLYININDENT`: Display only indentation spaces and tabs as dots and arrows.

The default value is `view.WS_INVISIBLE`.

<a id="view.whitespace_size"></a>
#### `view.whitespace_size`

The pixel size of the dots that represent space characters when whitespace is visible.

The default value is `1`.

<a id="view.tab_draw_mode"></a>
#### `view.tab_draw_mode`

How visible tabs are drawn.

- `view.TD_LONGARROW`: Draw tabs as arrows that stretch up to tabstops.
- `view.TD_STRIKEOUT`: Draw tabs as horizontal lines that stretch up to tabstops.

The default value is `view.TD_LONGARROW`.

<a id="view.view_eol"></a>
#### `view.view_eol`

Display end of line characters.

The default value is `false`.

<a id="view.extra_ascent"></a>
#### `view.extra_ascent`

The amount of pixel padding above lines.

The default value is `0`.

<a id="view.extra_descent"></a>
#### `view.extra_descent`

The amount of pixel padding below lines.

The default is `0`.

### Configure Scrollbar Display and Scrolling Behavior

<a id="view.h_scroll_bar"></a>
#### `view.h_scroll_bar`

Display the horizontal scroll bar.

The default value is `true` in the GUI version and `false` in the terminal version.

<a id="view.v_scroll_bar"></a>
#### `view.v_scroll_bar`

Display the vertical scroll bar.

The default value is `true`.

<a id="view.scroll_width"></a>
#### `view.scroll_width`

The horizontal scrolling pixel width.

If [`view.scroll_width_tracking`](#view.scroll_width_tracking) is `false`, the view uses this static width for horizontal
scrolling instead of measuring the width of buffer lines.

The default value is `1` in conjunction with [`view.scroll_width_tracking`](#view.scroll_width_tracking) being `true`. A
value of `2000` is reasonable if [`view.scroll_width_tracking`](#view.scroll_width_tracking) is `false`.

<a id="view.scroll_width_tracking"></a>
#### `view.scroll_width_tracking`

Grow (but never shrink) [`view.scroll_width`](#view.scroll_width) as needed to match the maximum width of a
displayed line.

Enabling this may have performance implications for buffers with long lines.

The default value is `true`.

<a id="view.end_at_last_line"></a>
#### `view.end_at_last_line`

Disable scrolling past the last line.

The default value is `true`.

<a id="view.set_x_caret_policy"></a>
#### `view:set_x_caret_policy`(*policy*, *x*)

Defines a scrolling policy for keeping the caret away from the horizontal margins.

Parameters:
- *policy*:  Combination of the following policy flags to set:
	- `view.CARET_SLOP`
		When the caret goes out of view, scroll the view so the caret is *x* pixels
		away from the right margin.
	- `view.CARET_STRICT`
		Scroll the view to ensure the caret stays *x* pixels away from the right margin.
	- `view.CARET_EVEN`
		Consider both horizontal margins instead of just the right one.
	- `view.CARET_JUMPS`
		Scroll the view more than usual in order to scroll less often.
- *x*:  Number of pixels from the horizontal margins to keep the caret.

<a id="view.set_y_caret_policy"></a>
#### `view:set_y_caret_policy`(*policy*, *y*)

Defines a scrolling policy for keeping the caret away from the vertical margins.

Parameters:
- *policy*:  Combination of the following policy flags to set:
	- `view.CARET_SLOP`
		When the caret goes out of view, scroll the view so the caret is *y* lines
		below from the top margin.
	- `view.CARET_STRICT`
		Scroll the view to ensure the caret stays *y* lines below from the top margin.
	- `view.CARET_EVEN`
		Consider both vertical margins instead of just the top one.
	- `view.CARET_JUMPS`
		Scroll the view more than usual in order to scroll less often.
- *y*:  Number of lines from the vertical margins to keep the caret.

<a id="view.set_visible_policy"></a>
#### `view:set_visible_policy`(*policy*, *y*)

Defines a scrolling policy for keeping the caret away from the vertical margins when
[`view:ensure_visible_enforce_policy()`](#view.ensure_visible_enforce_policy) redisplays hidden or folded lines.

It is similar in operation to [`view:set_y_caret_policy()`](#view.set_y_caret_policy).

Parameters:
- *policy*:  Combination of the following policy flags to set:
	- `view.VISIBLE_SLOP`
		When the caret is out of view, scroll the view so the caret is *y* lines away
		from the vertical margins.
	- `view.VISIBLE_STRICT`
		Scroll the view to ensure the caret stays a *y* lines away from the vertical
		margins.
- *y*:  Number of lines from the vertical margins to keep the caret.

### Configure Mouse Cursor Display

<a id="view.cursor"></a>
#### `view.cursor`

The mouse cursor to show.

- `view.CURSORNORMAL`: The text insert cursor.
- `view.CURSORARROW`: The arrow cursor.
- `view.CURSORWAIT`: The wait cursor.
- `view.CURSORREVERSEARROW`: The reversed arrow cursor.

The default value is `view.CURSORNORMAL`.

### Configure Wrapped Line Display


By default, lines that contain more characters than the view can show do not wrap into view
and onto sub-lines.

<a id="view.wrap_mode"></a>
#### `view.wrap_mode`

Wrap long lines.

- `view.WRAP_NONE`: Do not wrap long lines.
- `view.WRAP_WORD`: Wrap long lines at word (and style) boundaries.
- `view.WRAP_CHAR`: Wrap long lines at character boundaries.
- `view.WRAP_WHITESPACE`: Wrap long lines at word boundaries (ignoring style boundaries).

The default value is `view.WRAP_NONE`.

<a id="view.wrap_visual_flags"></a>
#### `view.wrap_visual_flags`

How to mark wrapped lines.

- `view.WRAPVISUALFLAG_NONE`: No visual flags.
- `view.WRAPVISUALFLAG_END`: Show a visual flag at the end of a wrapped line.
- `view.WRAPVISUALFLAG_START`: Show a visual flag at the beginning of a sub-line.
- `view.WRAPVISUALFLAG_MARGIN`: Show a visual flag in the sub-line's line number margin.

The default value is `view.WRAPVISUALFLAG_NONE`.

<a id="view.wrap_visual_flags_location"></a>
#### `view.wrap_visual_flags_location`

Where to mark wrapped lines.

- `view.WRAPVISUALFLAGLOC_DEFAULT`: Draw a visual flag near the view's right margin.
- `view.WRAPVISUALFLAGLOC_END_BY_TEXT`: Draw a visual flag near text at the end of a
	wrapped line.
- `view.WRAPVISUALFLAGLOC_START_BY_TEXT`: Draw a visual flag near text at the beginning of
	a subline.

The default value is `view.WRAPVISUALFLAGLOC_DEFAULT`.

<a id="view.wrap_indent_mode"></a>
#### `view.wrap_indent_mode`

Indent wrapped lines.

- `view.WRAPINDENT_FIXED`: Indent wrapped lines by [`view.wrap_start_indent`](#view.wrap_start_indent) number of spaces.
- `view.WRAPINDENT_SAME`: Indent wrapped lines the same amount as the first line.
- `view.WRAPINDENT_INDENT`: Indent wrapped lines one more level than the level of the
	first line.
- `view.WRAPINDENT_DEEPINDENT`: Indent wrapped lines two more levels than the level of the
	first line.

The default value is `view.WRAPINDENT_FIXED`.

<a id="view.wrap_start_indent"></a>
#### `view.wrap_start_indent`

The number of spaces of indentation to display wrapped lines with if
[`view.wrap_indent_mode`](#view.wrap_indent_mode) is `view.WRAPINDENT_FIXED`.

The default value is `0`.

### Configure Text Zoom

<a id="view.zoom_in"></a>
#### `view:zoom_in`()

Increases the size of all fonts by one point, up to a net increase of +60.

<a id="view.zoom_out"></a>
#### `view:zoom_out`()

Decreases the size of all fonts by one point, up to a net decrease of -10.

<a id="view.zoom"></a>
#### `view.zoom`

The number of points to add to the size of all fonts.

Negative values are allowed, down to `-10`.
The default value is `0`.

### Configure Long Line Display


While the view does not enforce a maximum line length, it allows for visual identification
of long lines.

<a id="view.edge_column"></a>
#### `view.edge_column`

The column number to mark long lines at.

<a id="view.edge_mode"></a>
#### `view.edge_mode`

How to mark long lines.

- `view.EDGE_NONE`: Do not mark long lines.
- `view.EDGE_LINE`: Draw a single vertical line whose color is [`view.edge_color`](#view.edge_color) at column
	[`view.edge_column`](#view.edge_column).
- `view.EDGE_BACKGROUND`: Change the background color of text after column [`view.edge_column`](#view.edge_column)
	to [`view.edge_color`](#view.edge_color).
- `view.EDGE_MULTILINE`: Draw vertical lines whose colors and columns are defined by calls to
	[`view:multi_edge_add_line()`](#view.multi_edge_add_line).

The default value is `view.EDGE_NONE`.

<a id="view.multi_edge_add_line"></a>
#### `view:multi_edge_add_line`(*column*, *color*)

Adds a new vertical long line marker.

Parameters:
- *column*:  Column number to add a vertical line at.
- *color*:  Color in "0xBBGGRR" format.

<a id="view.multi_edge_clear_all"></a>
#### `view:multi_edge_clear_all`()

Clears all vertical lines created by [`view:multi_edge_add_line()`](#view.multi_edge_add_line).

<a id="view.multi_edge_column"></a>
#### `view.multi_edge_column`

Map of edge column numbers to their column positions.
(Read-only)
A position of `-1` means no edge column was found.

<a id="view.edge_color"></a>
#### `view.edge_color`

The color, in "0xBBGGRR" format, of the single edge or background for long lines (depending on
[`view.edge_mode`](#view.edge_mode)).

### Configure Fold Settings and Folded Line Display

<a id="buffer.folding"></a>
#### `buffer.folding`

Enable folding for the lexers that support it.

The default value is `true`.

<a id="buffer.fold_compact"></a>
#### `buffer.fold_compact`

Consider any blank lines after an ending fold point as part of the fold.

The default value is `false`.

<a id="buffer.fold_on_zero_sum_lines"></a>
#### `buffer.fold_on_zero_sum_lines`

Mark as fold points lines that contain both an ending and starting fold point.

For example, mark `} else {` as a fold point.

The default value is `false`.

<a id="buffer.fold_by_indentation"></a>
#### `buffer.fold_by_indentation`

Fold based on indentation level if a lexer does not have a folder.

Some lexers automatically enable this option.

The default value is `false`.

<a id="view.fold_flags"></a>
#### `view.fold_flags`

Bit-mask of folding lines to draw in the buffer.
(Read-only)
- `view.FOLDFLAG_NONE`: Do not draw folding lines.
- `view.FOLDFLAG_LINEBEFORE_EXPANDED`: Draw lines above expanded folds.
- `view.FOLDFLAG_LINEBEFORE_CONTRACTED`: Draw lines above collapsed folds.
- `view.FOLDFLAG_LINEAFTER_EXPANDED`: Draw lines below expanded folds.
- `view.FOLDFLAG_LINEAFTER_CONTRACTED`: Draw lines below collapsed folds.
- `view.FOLDFLAG_LEVELNUMBERS`: Show hexadecimal fold levels in line margins.
	This option cannot be combined with `view.FOLDFLAG_LINESTATE`.
- `view.FOLDFLAG_LINESTATE`: Show line state in line margins.
	This option cannot be combined with `view.FOLDFLAG_LEVELNUMBERS`.

The default value is `view.FOLDFLAG_NONE`.

<a id="view.fold_display_text_style"></a>
#### `view.fold_display_text_style`

How to draw text shown next to folded lines.

- `view.FOLDDISPLAYTEXT_HIDDEN`: Do not show fold display text.
- `view.FOLDDISPLAYTEXT_STANDARD`: Show fold display text with no decoration.
- `view.FOLDDISPLAYTEXT_BOXED`: Show fold display text outlined with a box.

The default value is `view.FOLDDISPLAYTEXT_BOXED`.

### Highlight Matching Braces

<a id="view.brace_bad_light"></a>
#### `view:brace_bad_light`(*pos*)

Highlights an unmatched brace character using the `view.STYLE_BRACEBAD` style.

Parameters:
- *pos*:  Position in the view's buffer to highlight, or `-1` to remove the highlight.

<a id="view.brace_bad_light_indicator"></a>
#### `view:brace_bad_light_indicator`(*use_indicator*, *indicator*)

Indicates unmatched brace characters should highlight with an indicator instead of the
`view.STYLE_BRACEBAD` style.

Parameters:
- *use_indicator*:  Whether or not to use an indicator.
- *indicator*:  Indicator number to use.

<a id="view.brace_highlight"></a>
#### `view:brace_highlight`(*pos1*, *pos2*)

Highlights characters as matching braces using the `view.STYLE_BRACELIGHT` style.

If indent guides are enabled, this also uses [`buffer.column`](#buffer.column) to locate the column of the
brace characters and sets [`view.highlight_guide`](#view.highlight_guide) in order to highlight the indent guide too.

Parameters:
- *pos1*:  Position of the first brace in the view's buffer to highlight.
- *pos2*:  Position of the second brace in the view's buffer to highlight.

<a id="view.brace_highlight_indicator"></a>
#### `view:brace_highlight_indicator`(*use_indicator*, *indicator*)

Indicates matching brace characters should highlight with an indicator instead of the
`view.STYLE_BRACELIGHT` style.

Parameters:
- *use_indicator*:  Whether or not to use an indicator.
- *indicator*:  Indicator number to use.

### Configure Indentation Guide Display

<a id="view.indentation_guides"></a>
#### `view.indentation_guides`

Draw indentation guides.

Indentation guides are dotted vertical lines that appear within indentation whitespace at
each level of indentation.

- `view.IV_NONE`: Do not draw any guides.
- `view.IV_REAL`: Draw guides only within indentation whitespace.
- `view.IV_LOOKFORWARD`: Draw guides beyond the current line up to the next non-empty line's
	indentation level, but with an additional level if the previous non-empty line is a
	fold point.
- `view.IV_LOOKBOTH`: Draw guides beyond the current line up to either the indentation level
	of the previous or next non-empty line, whichever is greater.

The default value is `view.IV_LOOKBOTH` in the GUI version, and `view.IV_NONE` in the
terminal version.

<a id="view.highlight_guide"></a>
#### `view.highlight_guide`

The indentation guide column number to also highlight when highlighting matching braces, or
`0` to stop indentation guide highlighting.

### Configure File Types

<a id="buffer.set_lexer"></a>
#### `buffer:set_lexer`([*name*])

Sets the buffer's lexer.

Parameters:
- *name*:  String lexer name to set. If `nil`, Textadept tries to auto-detect the
	buffer's lexer.

See also: [`lexer.detect_extensions`](#lexer.detect_extensions), [`lexer.detect_patterns`](#lexer.detect_patterns)

<a id="buffer.get_lexer"></a>
#### `buffer:get_lexer`([*current*=false])

Returns the buffer's lexer name.

Parameters:
- *current*:  Get the lexer at the current caret position in multi-language
	lexers. If `false`, the parent lexer is always returned.

<a id="buffer.lexer_language"></a>
#### `buffer.lexer_language`

The buffer's lexer name.
(Read-only)
If the lexer is a multi-language lexer, [`buffer:get_lexer()`](#buffer.get_lexer) can obtain the lexer under
the caret.

### Manually Style Text


Plain text can be manually styled after manually [setting up styles](#override-style-settings).

<a id="buffer.colorize"></a>
#### `buffer:colorize`(*start_pos*, *end_pos*)

Instructs the lexer to style and mark fold points in a range of text.

This is useful for reprocessing and refreshing a range of text if that range has incorrect
highlighting or incorrect fold points.

Parameters:
- *start_pos*:  Start position of the range to process.
- *end_pos*:  End position of the range to process, or `-1` for the end of the buffer.

<a id="buffer.clear_document_style"></a>
#### `buffer:clear_document_style`()

Clears all styling and folding information.

<a id="buffer.start_styling"></a>
#### `buffer:start_styling`(*position*, *unused*)

Begins styling at a given position.

This must be called before any calls to [`buffer:set_styling()`](#buffer.set_styling).

Parameters:
- *position*:  Position to start styling at.
- *unused*:  Unused number. `0` can be safely used.

<a id="buffer.set_styling"></a>
#### `buffer:set_styling`(*length*, *style*)

Assigns a style to the next range of buffer text.

This will update the current styling position.
[`buffer:start_styling()`](#buffer.start_styling) must have already been called.

Parameters:
- *length*:  Number of characters to style with *style* starting from the current styling
	position.
- *style*:  Style number to assign, in the range from `1` to `256`.

### Query Style Information

<a id="buffer.style_at"></a>
#### `buffer.style_at`

Map of buffer positions to their style numbers.
(Read-only)

<a id="buffer.named_styles"></a>
#### `buffer.named_styles`

The number of named lexer styles.

<a id="buffer.name_of_style"></a>
#### `buffer:name_of_style`(*style*)

Returns the name of a style number.

Note: due to an implementation detail, the returned style contains '.' instead of '\_'.
When setting styles, the '\_' form is preferred.

Parameters:
- *style*:  Style number between `1` and `256` to get the name of.

<a id="buffer.style_of_name"></a>
#### `buffer:style_of_name`(*style_name*)

Returns the style number associated with a style name, or `view.STYLE_DEFAULT` if that name
is not in use.

Parameters:
- *style_name*:  Style name to get the number of.

<a id="buffer.end_styled"></a>
#### `buffer.end_styled`

The current styling position or the last correctly styled character's position.
(Read-only)

### Miscellaneous

<a id="buffer.tab_label"></a>
#### `buffer.tab_label`

The buffer's tab label in the tab bar.
(Write-only)
Textadept sets this automatically based on the buffer's filename or type, and its save status.

<a id="buffer.read_only"></a>
#### `buffer.read_only`

Whether or not the buffer is read-only.

The default value is `false`.

<a id="buffer.cancel"></a>
#### `buffer:cancel`()

Cancels the active selection mode, autocompletion or user list, call tip, etc.

<a id="buffer.overtype"></a>
#### `buffer.overtype`

Enable overtype mode, where typed characters overwrite existing ones.

The default value is `false`.

<a id="buffer.edit_toggle_overtype"></a>
#### `buffer:edit_toggle_overtype`()

Toggles [`buffer.overtype`](#buffer.overtype).

<a id="view.idle_styling"></a>
#### `view.idle_styling`

Enable background styling while the editor is idle.

This setting has no effect when [`view.wrap_mode`](#view.wrap_mode) is on.

- `view.IDLESTYLING_NONE`: Require text to be styled before displaying it.
- `view.IDLESTYLING_TOVISIBLE`: Style some text before displaying it and then style the rest
	incrementally in the background as an idle-time task.
- `view.IDLESTYLING_AFTERVISIBLE`: Style text after the currently visible portion in the
	background.
- `view.IDLESTYLING_ALL`: Style text both before and after the visible text in the background.

The default value is `view.IDLESTYLING_ALL`.

<a id="view.mouse_dwell_time"></a>
#### `view.mouse_dwell_time`

The number of milliseconds the mouse must idle before generating an [`events.DWELL_START`](#events.DWELL_START) event.

A time of `view.TIME_FOREVER` will never generate one.

<a id="view.change_history"></a>
#### `view.change_history`

A bit-mask of options for showing change history.

This is a low-level field. You probably want to use the higher-level [`io.track_changes`](#io.track_changes) instead.

- `view.CHANGE_HISTORY_DISABLED`: Do not show change history.
- `view.CHANGE_HISTORY_ENABLED`: Track change history.
- `view.CHANGE_HISTORY_MARKERS`: Display changes in the margin with markers.
- `view.CHANGE_HISTORY_INDICATORS`: Display changes in the buffer with indicators.

The default value is `view.CHANGE_HISTORY_DISABLED`.

<a id="buffer.delete"></a>
#### `buffer:delete`()

Deletes the buffer.

**Do not call this function.** Call [`buffer:close()`](#buffer.close) instead.

See also: [`events.BUFFER_DELETED`](#events.BUFFER_DELETED)


<a id="events"></a>
## The `events` module

Textadept's core event structure and handlers.


Textadept emits events when you do things like create a new buffer, press a key, click on
a menu, etc. You can even emit events yourself using Lua. Each event has a set of event
handlers, which are simply Lua functions called in the order they were connected to an
event. For example, if you created a module that needs to do something each time Textadept
creates a new buffer, connect a Lua function to the [`events.BUFFER_NEW`](#events.BUFFER_NEW) event:

```lua
events.connect(events.BUFFER_NEW, function()
	-- Do something here.
end)
```

Events themselves are nothing special. You do not have to declare one before using it. Events
are simply strings containing arbitrary event names. When either you or Textadept emits an
event, Textadept runs all event handlers connected to the event, passing any given arguments
to the event's handler functions. If an event handler explicitly returns a value that is not
`nil`, Textadept will not call subsequent handlers. This is useful if you want to stop the
propagation of an event like a keypress if your event handler handled it, or if you want to
use the event framework to pass values.

<a id="events.APPLEEVENT_ODOC"></a>
### `events.APPLEEVENT_ODOC`

Emitted when macOS tells Textadept to open a file.

Arguments:
- *uri*: The UTF-8-encoded URI to open.

<a id="events.ARG_NONE"></a>
### `events.ARG_NONE`

Emitted when no filename or directory command line arguments are passed to Textadept on startup.

<a id="events.AUTO_C_CANCELED"></a>
### `events.AUTO_C_CANCELED`

Emitted when canceling an autocompletion or user list.

<a id="events.AUTO_C_CHAR_DELETED"></a>
### `events.AUTO_C_CHAR_DELETED`

Emitted after deleting a character while an autocompletion or user list is active.

<a id="events.AUTO_C_COMPLETED"></a>
### `events.AUTO_C_COMPLETED`

Emitted after inserting an item from an autocompletion list into the buffer.

Arguments:
- *text*: The selection's text.
- *position*: The autocompleted word's beginning position.
- *code*: The code of the character from [`buffer.auto_c_fill_ups`](#buffer.auto_c_fill_ups) that made the selection,
	or `0` if no character was used.

<a id="events.AUTO_C_SELECTION"></a>
### `events.AUTO_C_SELECTION`

Emitted after selecting an item from an autocompletion list, but before inserting that item
into the buffer.

Calling [`buffer:auto_c_cancel()`](#buffer.auto_c_cancel) from an event handler will prevent automatic insertion.

Arguments:
- *text*: The selection's text.
- *position*: The autocompleted word's beginning position.
- *code*: The code of the character from [`buffer.auto_c_fill_ups`](#buffer.auto_c_fill_ups) that made the selection,
	or `0` if no character was used.

<a id="events.AUTO_C_SELECTION_CHANGE"></a>
### `events.AUTO_C_SELECTION_CHANGE`

Emitted as items are highlighted in an autocompletion or user list.

Arguments:
- *id*: Either the *id* from [`buffer:user_list_show()`](#buffer.user_list_show) or `0` for an autocompletion list.
- *text*: The current selection's text.
- *position*: The position the list was displayed at.

<a id="events.BUFFER_AFTER_REPLACE_TEXT"></a>
### `events.BUFFER_AFTER_REPLACE_TEXT`

Emitted after replacing the contents of the current buffer.

Note that it is not guaranteed that [`events.BUFFER_BEFORE_REPLACE_TEXT`](#events.BUFFER_BEFORE_REPLACE_TEXT) was emitted previously.
The buffer **must not** be modified during this event.

<a id="events.BUFFER_AFTER_SWITCH"></a>
### `events.BUFFER_AFTER_SWITCH`

Emitted after switching to another buffer.

The buffer being switched to is [`buffer`](#buffer).

See also: [`view.goto_buffer`](#view.goto_buffer)

<a id="events.BUFFER_BEFORE_REPLACE_TEXT"></a>
### `events.BUFFER_BEFORE_REPLACE_TEXT`

Emitted before replacing the contents of the current buffer.

Note that it is not guaranteed that [`events.BUFFER_AFTER_REPLACE_TEXT`](#events.BUFFER_AFTER_REPLACE_TEXT) will be emitted
shortly after this event.
The buffer **must not** be modified during this event.

<a id="events.BUFFER_BEFORE_SWITCH"></a>
### `events.BUFFER_BEFORE_SWITCH`

Emitted before switching to another buffer.

The buffer being switched from is [`buffer`](#buffer).

See also: [`view.goto_buffer`](#view.goto_buffer), [`buffer.new`](#buffer.new)

<a id="events.BUFFER_DELETED"></a>
### `events.BUFFER_DELETED`

Emitted after deleting a buffer.

Arguments:
- *buffer*: Simple representation of the deleted buffer. Buffer operations cannot be performed
	on it, but fields like [`buffer.filename`](#buffer.filename) can be read.

See also: [`buffer.delete`](#buffer.delete)

<a id="events.BUFFER_NEW"></a>
### `events.BUFFER_NEW`

Emitted after creating a new buffer.

The new buffer is [`buffer`](#buffer).

See also: [`buffer.new`](#buffer.new)

<a id="events.BUILD_OUTPUT"></a>
### `events.BUILD_OUTPUT`

Emitted when an executed build command has output.

The default behavior is to print output to the output buffer. In order to override this,
connect to this event with an index of `1` and return `true`.

Arguments:
- *output*: A chunk of string output from the command.

<a id="events.CALL_TIP_CLICK"></a>
### `events.CALL_TIP_CLICK`

Emitted when clicking on a calltip.

This event is not emitted by the Qt version.

Arguments:
- *position*: `1` if the up arrow was clicked, `2` if the down arrow was clicked, and `0`
	otherwise.

<a id="events.CHAR_ADDED"></a>
### `events.CHAR_ADDED`

Emitted after the user types a text character into the buffer.

Arguments:
- *code*: The text character's character code.

<a id="events.COMMAND_TEXT_CHANGED"></a>
### `events.COMMAND_TEXT_CHANGED`

Emitted when the text in the command entry changes.

`ui.command_entry:get_text()` returns the current text.

<a id="events.COMPILE_OUTPUT"></a>
### `events.COMPILE_OUTPUT`

Emitted when an executed compile command has output.

The default behavior is to print output to the output buffer. In order to override this,
connect to this event with an index of `1` and return `true`.

Arguments:
- *output*: A chunk of string output from the command.

<a id="events.CSI"></a>
### `events.CSI`

Emitted when the terminal version receives an unrecognized CSI sequence.

Arguments:
- *cmd*: The 24-bit CSI command value. The lowest byte contains the command byte. The second
	lowest byte contains the leading byte, if any (e.g. '?'). The third lowest byte contains
	the intermediate byte, if any (e.g. '$').
- *args*: Table of numeric arguments of the CSI sequence.

<a id="events.DOUBLE_CLICK"></a>
### `events.DOUBLE_CLICK`

Emitted after double-clicking the mouse button.

Arguments:
- *position*: The position double-clicked.
- *line*: The position's line number.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.DWELL_END"></a>
### `events.DWELL_END`

Emitted after [`events.DWELL_START`](#events.DWELL_START) when the user moves the mouse, presses a key, or scrolls
the view.

Arguments:
- *position*: The position closest to *x* and *y*.
- *x*: The x-coordinate of the mouse in the view.
- *y*: The y-coordinate of the mouse in the view.

<a id="events.DWELL_START"></a>
### `events.DWELL_START`

Emitted when the mouse is stationary for [`view.mouse_dwell_time`](#view.mouse_dwell_time) milliseconds.

Arguments:
- *position*: The position closest to *x* and *y*.
- *x*: The x-coordinate of the mouse in the view.
- *y*: The y-coordinate of the mouse in the view.

<a id="events.ERROR"></a>
### `events.ERROR`

Emitted when an error occurs.

Arguments:
- *text*: The error message text.

<a id="events.FILE_AFTER_SAVE"></a>
### `events.FILE_AFTER_SAVE`

Emitted after saving a file to disk.

Arguments:
- *filename*: The filename of the saved file.
- *saved_as*: Whether or not the file was saved under a different filename.

See also: [`buffer.save`](#buffer.save), [`buffer.save_as`](#buffer.save_as)

<a id="events.FILE_BEFORE_SAVE"></a>
### `events.FILE_BEFORE_SAVE`

Emitted before saving a file to disk.

Arguments:
- *filename*: The filename of the file being saved.

See also: [`buffer.save`](#buffer.save)

<a id="events.FILE_CHANGED"></a>
### `events.FILE_CHANGED`

Emitted when Textadept detects that an open file was modified externally.

The default behavior is to prompt the user to reload the file. In order to override this,
connect to this event with an index of `1` and return `true`.

Arguments:
- *filename*: The filename externally modified.

<a id="events.FILE_OPENED"></a>
### `events.FILE_OPENED`

Emitted after opening a file in a new buffer.

Arguments:
- *filename*: The opened file's filename.

See also: [`io.open_file`](#io.open_file)

<a id="events.FIND"></a>
### `events.FIND`

Emitted to find text.

[`ui.find`](#ui.find) contains active find options.

Arguments:
- *text*: The text to search for.
- *next*: Whether or not to search forward instead of backward.

See also: [`ui.find.find_next`](#ui.find.find_next), [`ui.find.find_prev`](#ui.find.find_prev)

<a id="events.FIND_PANE_HIDE"></a>
### `events.FIND_PANE_HIDE`

Emitted when Textadept hides the find & replace pane.

<a id="events.FIND_PANE_SHOW"></a>
### `events.FIND_PANE_SHOW`

Emitted when Textadept shows the find & replace pane.

<a id="events.FIND_RESULT_FOUND"></a>
### `events.FIND_RESULT_FOUND`

Emitted when finding a text search result.

It is selected and has been scrolled into view.

Arguments:
- *find_text*: The text originally searched for.
- *wrapped*: Whether or not the result found is after a text search wrapped.

<a id="events.FIND_TEXT_CHANGED"></a>
### `events.FIND_TEXT_CHANGED`

Emitted when the text in the "Find" field of the find & replace pane changes.

[`ui.find.find_entry_text`](#ui.find.find_entry_text) contains the current text.

<a id="events.FIND_WRAPPED"></a>
### `events.FIND_WRAPPED`

Emitted when a text search wraps, either from bottom to top (when searching for a next
occurrence), or from top to bottom (when searching for a previous occurrence).

The default behavior is to print a statusbar notification. You can connect to this event to
implement a more visual or audible notice.

<a id="events.FOCUS"></a>
### `events.FOCUS`

Emitted when Textadept receives focus.

This event is never emitted when Textadept is running in the terminal.

<a id="events.INDICATOR_CLICK"></a>
### `events.INDICATOR_CLICK`

Emitted when clicking the mouse on text within an [indicator range](#mark-text-with-indicators).

Arguments:
- *position*: The clicked text's position.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.INDICATOR_RELEASE"></a>
### `events.INDICATOR_RELEASE`

Emitted when releasing the mouse after clicking on text within an [indicator
range](#mark-text-with-indicators).

Arguments:
- *position*: The clicked text's position.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.INITIALIZED"></a>
### `events.INITIALIZED`

Emitted after Textadept finishes initializing.

<a id="events.KEYPRESS"></a>
### `events.KEYPRESS`

Emitted when pressing a recognized key.

If any handler returns `true`, the key is not handled further (e.g. inserted into the buffer).

Arguments:
- *key*: The string representation of the [key sequence](#key-sequences).

<a id="events.LEXER_LOADED"></a>
### `events.LEXER_LOADED`

Emitted after loading a language lexer.

This is useful for automatically loading language modules as source files are opened, or
setting up language-specific editing features for source files.

Arguments:
- *name*: The language lexer's name.

Usage:

```lua
events.connect(events.LEXER_LOADED, function(name)
	if name ~= 'lua' then return end
	-- Use Lua 5.1 keywords instead of Lua 5.2+ keywords.
	buffer.lexer:set_word_list(lexer.KEYWORD, {
		'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in',
		'local', 'or', 'nil', 'not', 'repeat', 'return', 'then', 'true', 'until', 'while'
	})
end)
```

<a id="events.MARGIN_CLICK"></a>
### `events.MARGIN_CLICK`

Emitted when clicking the mouse inside a sensitive margin.

Arguments:
- *margin*: The margin number clicked.
- *position*: The position of the beginning of the clicked margin's line.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.MARGIN_RIGHT_CLICK"></a>
### `events.MARGIN_RIGHT_CLICK`

Emitted when right-clicking the mouse inside a sensitive margin.

Arguments:
- *margin*: The margin number right-clicked.
- *position*: The position of the beginning of the clicked margin's line.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.MENU_CLICKED"></a>
### `events.MENU_CLICKED`

Emitted after selecting a menu item.

Arguments:
- *menu_id*: The numeric ID of the menu item, which was defined in [`ui.menu()`](#ui.menu).

<a id="events.MODE_CHANGED"></a>
### `events.MODE_CHANGED`

Emitted by the GUI version when switching between light mode and dark mode.

Arguments:
- *mode*: Either "light" or "dark".

<a id="events.MOUSE"></a>
### `events.MOUSE`

Emitted by the terminal version for an unhandled mouse event.

A handler should return `true` if it handled the event. Otherwise Textadept will try again.
(This side effect for `nil` return is useful for sending the original mouse event to a
different view that a handler has switched to.)

Arguments:
- *event*: The mouse event: `view.MOUSE_PRESS`, `view.MOUSE_DRAG`, or `view.MOUSE_RELEASE`.
- *button*: The mouse button number.
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`, `view.MOD_SHIFT`,
	and `view.MOD_ALT`.
- *y*: The y-coordinate of the mouse event, starting from 1.
- *x*: The x-coordinate of the mouse event, starting from 1.

<a id="events.QUIT"></a>
### `events.QUIT`

Emitted when quitting Textadept.

The default behavior is to close all buffers and, if that was successful, quit the application.
In order to do something before Textadept closes all open buffers, connect to this event with
an index of `1`. If a handler returns `true`, Textadept does not quit. It is not recommended
to return `false` from a quit handler, as that may interfere with Textadept's normal shutdown
procedure.

See also: [`events.quit`](#events.quit)

<a id="events.REPLACE"></a>
### `events.REPLACE`

Emitted to replace selected (found) text.

[`ui.find`](#ui.find) contains active find options.

Arguments:
- *text*: The replacement text.

See also: [`ui.find.replace`](#ui.find.replace)

<a id="events.REPLACE_ALL"></a>
### `events.REPLACE_ALL`

Emitted to replace all occurrences of found text.

[`ui.find`](#ui.find) contains active find options.

Arguments:
- *find_text*: The text to search for.
- *repl_text*: The replacement text.

See also: [`ui.find.replace_all`](#ui.find.replace_all)

<a id="events.RESET_AFTER"></a>
### `events.RESET_AFTER`

Emitted after resetting Textadept's Lua state.

Arguments:
- *persist*: Table of data persisted by [`events.RESET_BEFORE`](#events.RESET_BEFORE). All handlers will have access
	to this same table.

See also: [`events.reset`](#events.reset)

<a id="events.RESET_BEFORE"></a>
### `events.RESET_BEFORE`

Emitted before resetting Textadept's Lua state.

Arguments:
- *persist*: Table to store persistent data in for use by [`events.RESET_AFTER`](#events.RESET_AFTER). All handlers
	will have access to this same table.

See also: [`events.reset`](#events.reset)

<a id="events.RESUME"></a>
### `events.RESUME`

Emitted when resuming Textadept from a suspended state.

This event is only emitted by the terminal version.

<a id="events.RUN_OUTPUT"></a>
### `events.RUN_OUTPUT`

Emitted when an executed run command has output.

The default behavior is to print output to the output buffer. In order to override this,
connect to this event with an index of `1` and return `true`.

Arguments:
- *output*: A chunk of string output from the command.

<a id="events.SAVE_POINT_LEFT"></a>
### `events.SAVE_POINT_LEFT`

Emitted after leaving a save point.

<a id="events.SAVE_POINT_REACHED"></a>
### `events.SAVE_POINT_REACHED`

Emitted after reaching a save point.

<a id="events.SESSION_LOAD"></a>
### `events.SESSION_LOAD`

Emitted when loading a session.

Arguments:
- *session*: Table of session data to load. All handlers will have access to this same table.

<a id="events.SESSION_SAVE"></a>
### `events.SESSION_SAVE`

Emitted when saving a session.

Arguments:
- *session*: Table of session data to save. All handlers will have access to this same table,
	and Textadept's default handler reserves the use of some keys. Note that functions,
	userdata, and circular table values cannot be saved. The latter case is not recognized
	at all, so beware of creating in infinite loop.

<a id="events.SUSPEND"></a>
### `events.SUSPEND`

Emitted prior to suspending Textadept.

This event is only emitted by the terminal version.

<a id="events.TAB_CLICKED"></a>
### `events.TAB_CLICKED`

Emitted when the user clicks on a buffer tab.

The default behavior is to switch to the clicked tab's buffer. In order to do something
before the switch, connect to this event with an index of `1`.

Note that Textadept always displays a context menu for a right-click.

Arguments:
- *index*: The numeric index of the clicked tab.
- *button*: The mouse button number that was clicked, either `1` (left button), `2` (middle
	button), `3` (right button), `4` (wheel up), or `5` (wheel down).
- *modifiers*: A bit-mask of any modifier keys held down: `view.MOD_CTRL`,
	`view.MOD_SHIFT`, `view.MOD_ALT`, and `view.MOD_META`. On macOS, the Command modifier
	key is reported as `view.MOD_CTRL` and Ctrl is `view.MOD_META`. Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to `view.MOD_CTRL`, the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation in the GTK version.

<a id="events.TAB_CLOSE_CLICKED"></a>
### `events.TAB_CLOSE_CLICKED`

Emitted when the user clicks a buffer tab's close button.

The default behavior is to close the tab's buffer. If you need to do something before
Textadept closes the buffer, connect to this event with an index of `1`.

This event is only emitted in the Qt version.

Arguments:
- *index*: The numeric index of the clicked tab.

<a id="events.TEST_OUTPUT"></a>
### `events.TEST_OUTPUT`

Emitted when an executed test command has output.

The default behavior is to print output to the output buffer. In order to override this,
connect to this event with an index of `1` and return `true`.

Arguments:
- *output*: A chunk of string output from the command.

<a id="events.UNFOCUS"></a>
### `events.UNFOCUS`

Emitted when Textadept loses focus.

This event is never emitted when Textadept is running in the terminal.

<a id="events.UPDATE_UI"></a>
### `events.UPDATE_UI`

Emitted after the view is visually updated.

Arguments:
- *updated*: A bitmask of changes since the last update.

	+ `buffer.UPDATE_CONTENT`
		The buffer's contents, styling, or markers have changed.
	+ `buffer.UPDATE_SELECTION`
		The buffer's selection has changed (including caret movement).
	+ `view.UPDATE_V_SCROLL`
		The view has scrolled vertically.
	+ `view.UPDATE_H_SCROLL`
		The view has scrolled horizontally.

<a id="events.URI_DROPPED"></a>
### `events.URI_DROPPED`

Emitted after dragging and dropping a URI into a view.

Arguments:
- *text*: The UTF-8-encoded URI dropped.

<a id="events.USER_LIST_SELECTION"></a>
### `events.USER_LIST_SELECTION`

Emitted after selecting an item in a user list.

Arguments:
- *id*: The *id* from [`buffer:user_list_show()`](#buffer.user_list_show).
- *text*: The selection's text.
- *position*: The position the list was displayed at.

<a id="events.VIEW_AFTER_SWITCH"></a>
### `events.VIEW_AFTER_SWITCH`

Emitted after switching to another view.

The view being switched to is [`view`](#view).

See also: [`ui.goto_view`](#ui.goto_view)

<a id="events.VIEW_BEFORE_SWITCH"></a>
### `events.VIEW_BEFORE_SWITCH`

Emitted before switching to another view.

The view being switched from is [`view`](#view).

See also: [`ui.goto_view`](#ui.goto_view), [`view.split`](#view.split)

<a id="events.VIEW_NEW"></a>
### `events.VIEW_NEW`

Emitted after creating a new view.

The new view is [`view`](#view).

See also: [`view.split`](#view.split)

<a id="events.ZOOM"></a>
### `events.ZOOM`

Emitted after changing [`view.zoom`](#view.zoom).

See also: [`view.zoom_in`](#view.zoom_in), [`view.zoom_out`](#view.zoom_out)

<a id="events.connect"></a>
### `events.connect`(*event*, *f*[, *index*])

Adds an event handler.

Parameters:
- *event*:  String event name to handle. It does not need to have been previously defined.
- *f*:  Handler function. If it returns a non-`nil` value, subsequent handlers for *event*
	will not be invoked when that event is emitted.
- *index*:  Index to insert the handler at (typically 1 or none). If none is given,
	*f* is appended to the list of handlers for *event*.

<a id="events.disconnect"></a>
### `events.disconnect`(*event*, *f*)

Removes an event handler.

Parameters:
- *event*:  String event name to remove a handler for.
- *f*:  Handler function to remove.

<a id="events.emit"></a>
### `events.emit`(*event*[, ...])

Sequentially invoke all of an event's handler functions.

If any handler returns a non-`nil` value, subsequent handlers will not be called. This is
useful for stopping the propagation of an event like a keypress after it has been handled,
or for passing back values from handlers.

Parameters:
- *event*:  String event name. It does not need to have been previously defined.
- *...*:  Arguments passed to each handler.

Returns: the first non-`nil` value returned by a handler, if any



<a id="io"></a>
## The `io` module

Extends Lua's [`io`](#io) library with Textadept functions for working with files.

<a id="io.close_all_buffers"></a>
### `io.close_all_buffers`()

Closes all open buffers.

If there are any unsaved buffers, the user is prompted to confirm closing without saving
for each one. If the user does not confirm, the remaining open buffers stay open.

Buffers are not saved automatically. They must be saved manually.

Returns: `true` if user did not cancel, and all buffers were closed; `nil` otherwise.

<a id="io.detect_indentation"></a>
### `io.detect_indentation`

Attempt to detect indentation settings for opened files.

If any non-blank line starts with a tab, tabs are used. Otherwise, for the first non-blank
line that starts with between two and eight spaces, that number of spaces is used.

The default value is `true`.

<a id="io.encodings"></a>
### `io.encodings`

Table of encodings to attempt to decode files with.

The default list contains UTF-8, ASCII, CP1252, and UTF-16.

You should add to this list if you work with files encoded in something else. Valid encodings
are [GNU iconv's encodings][], and include:
- European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
	KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
	Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
	Macintosh.
- Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
	UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.

[GNU iconv's encodings]: https://www.gnu.org/software/libiconv/

Usage:

```lua
io.encodings[#io.encodings + 1] = 'UTF-32'
```

See also: [`string.iconv`](#string.iconv)

<a id="io.ensure_final_newline"></a>
### `io.ensure_final_newline`

Ensure there is a final newline when saving text files.

This has no effect on binary files.

The default value is `false` on Windows, and `true` on macOS, Linux, and BSD.

<a id="io.get_project_root"></a>
### `io.get_project_root`([*path*][, *submodule*=false])

Returns a project's root directory.

Textadept only recognizes projects under one of the following version control systems: Git,
Mercurial, SVN, Bazaar, and Fossil.

Parameters:
- *path*:  String path to a project, or the path to a file that belongs to a project. The
	default value is either the buffer's filename (if available) or the current working directory.
- *submodule*:  Return the root of the current submodule instead of the repository
	root (if applicable).

Returns: string root, or `nil` if no project was found

<a id="io.open_file"></a>
### `io.open_file`([*filenames*])

Opens files for editing.

Parameters:
- *filenames*:  String filename or table of filenames to open. If `nil`,
	the user is prompted to open one or more.

See also: [`_CHARSET`](#_CHARSET), [`events.FILE_OPENED`](#events.FILE_OPENED)

<a id="io.open_recent_file"></a>
### `io.open_recent_file`()

Prompts the user to select a recently opened file to reopen.

See also: [`io.recent_files`](#io.recent_files)

<a id="io.quick_open"></a>
### `io.quick_open`([*paths*[, *filter*]])

Prompts the user to select a file to open from a list of files read from a directory.

The number of files shown in the list is capped at [`io.quick_open_max`](#io.quick_open_max).

Parameters:
- *paths*:  String directory path or table of directory paths to search for files
	in. The default value is the current project's root directory.
- *filter*:  [Filter](#filters) that specifies the files and directories the
	iterator should yield. It is a shell-style glob string or table of such glob strings. The
	default value is `io.quick_open_filters[paths]` if it exists, or [`lfs.default_filter`](#lfs.default_filter)
	otherwise. Any non-[`lfs.default_filter`](#lfs.default_filter) filter will be combined with [`lfs.default_filter`](#lfs.default_filter).

Usage:

```lua
io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list files in the buffer's directory
io.quick_open(io.get_project_root(), '**/*.{lua,c}') -- list Lua and C project files
io.quick_open(io.get_project_root(), '!build') -- list non-build project files
```

<a id="io.quick_open_filters"></a>
### `io.quick_open_filters`

Map of directory paths to filters used by [`io.quick_open()`](#io.quick_open).

<a id="io.quick_open_max"></a>
### `io.quick_open_max`

The maximum number of files listed in the quick open list.

The default value is `5000`.

<a id="io.recent_files"></a>
### `io.recent_files`

Table of recently opened files, the most recent being towards the top.

<a id="io.save_all_files"></a>
### `io.save_all_files`([*untitled*=false])

Saves all unsaved buffers to their respective files.

Print and output buffers are ignored.

Parameters:
- *untitled*:  Prompt the user for filenames to save untitled buffers to. If
	the user cancels saving any untitled buffer, the remaining unsaved files stay unsaved.

Returns: `true` if all savable files were saved; `nil` otherwise.

<a id="io.track_changes"></a>
### `io.track_changes`

Track file changes using line markers and buffer indicators.

Changes shown are with respect to the file on disk, not the file's version control state
(if it has one).

The terminal version only shows line markers.

The default value is `false`.



<a id="keys"></a>
## The `keys` module

Manages key bindings in Textadept.


### Key Bindings Overview

Define key bindings in the global [`keys`](#keys) table in key-value pairs. Each pair consists of either:
- A string key sequence and its associated command.
- A string lexer name and its table of key sequences and commands. These are called
	language-specific keys.
- A string key mode and its table of key sequences and commands. This is called a key mode.
- A key sequence and its table of more key sequences and commands. This is called a key chain.

When searching for a command to run based on a key sequence, Textadept considers key bindings
in the current key mode to have priority. If no key mode is active, language-specific key
bindings have priority, followed by the ones in the global table. This means if there are
two commands with the same key sequence, Textadept runs the language-specific one. However,
if the command returns the boolean value `false`, Textadept also runs the lower-priority
command. (This is useful for overriding commands like autocompletion with language-specific
completion, but fall back to word autocompletion if the first command fails.)

### Key Sequences

Key sequences are strings built from an ordered combination of modifier keys and the key's
inserted character. Modifier keys are "Control", "Shift", and "Alt" on Windows, Linux/BSD,
and in the terminal version. On macOS they are "Control" (`^`), "Alt/Option" (`⌥`), "Command"
(`⌘`), and "Shift" (`⇧`). These modifiers have the following string representations:

Modifier |  Windows / Linux / BSD | macOS | Terminal
-|-|-|-
Control | `'ctrl'` | `'ctrl'` | `'ctrl'`
Alt | `'alt'` | `'alt'` | `'meta'`
Command | N/A | `'cmd'` | N/A
Shift | `'shift'` | `'shift'` | `'shift'`

The string representation of key values less than 255 is the character that Textadept would
normally insert if the "Control", "Alt", and "Command" modifiers were not held down. Therefore,
a combination of `Ctrl+Alt+Shift+A` has the key sequence `ctrl+alt+A` on Windows and Linux/BSD,
but a combination of `Ctrl+Shift+Tab` has the key sequence `ctrl+shift+\t`. On a United States
English keyboard, since the combination of `Ctrl+Shift+,` has the key sequence `ctrl+<`
(`Shift+,` inserts a `<`), Textadept recognizes the key binding as `Ctrl+<`. This allows
key bindings to be language and layout agnostic. For key values greater than 255, Textadept
uses the [`keys.KEYSYMS`](#keys.KEYSYMS) lookup table. Therefore, `Ctrl+Right Arrow` has the key sequence
`ctrl+right`.

Activating the "Tools > Show Keys..." menu item or its key binding will start showing key
sequences in the statusbar, along with their assigned commands, if any. For sequences with
a trailing "0x*XXXX*", that number can be aliased to a string representation in [`keys.KEYSYMS`](#keys.KEYSYMS).
For your convenience, Textadept copies key sequences to the clipboard.

### Commands

A command bound to a key sequence is simply a Lua function. For example:

```lua
keys['ctrl+n'] = buffer.new
keys['ctrl+z'] = buffer.undo
keys.c['shift+\n'] = function() -- language-specific key
	buffer:line_end()
	buffer:add_text(';')
	buffer:new_line()
end
keys['0x1234'] = function() ... end -- key code not in keys.KEYSYMS
```

Textadept handles [`buffer`](#buffer) and [`view`](#view) references properly in this context; it will use the
correct buffer and view when running the key command.

### Modes

Modes are groups of key bindings such that when a key [mode](#keys.mode) is active, Textadept
ignores all key bindings defined outside the mode until the mode is unset. Here is a simple
vi mode example:

```lua
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
```

**Warning**: When creating a mode, be sure to define a way to exit the mode, otherwise you
will probably have to restart Textadept.

### Key Chains

Key chains are a powerful concept. They allow you to assign multiple key bindings to one
key sequence. By default, the `Esc` key cancels a key chain, but you can redefine it via
[`keys.CLEAR`](#keys.CLEAR). An example key chain looks like:

```lua
keys['alt+a'] = {
	a = function1,
	b = function2,
	c = {...}
}
```

Pressing `Alt+A` activates the chain, and pressing `A` after that invokes function1. `Alt+A`
followed by `B` invokes function2, and so on.

<a id="keys.CLEAR"></a>
### `keys.CLEAR`

The key that clears the current key chain.

It cannot be part of a key chain.
The default value is `'esc'` for the `Esc` key.

<a id="keys.KEYSYMS"></a>
### `keys.KEYSYMS`

Lookup table for string representations of key codes higher than 255.

Recognized codes are: esc, \b, \t, \n, down, up, left, right, home, end, pgup, pgdn, del, ins,
and f1-f12. Unrecognized key codes can be identified using the "Tools > Show Keys..." menu
item and start with "0x".

The GUI version also recognizes: menu, kpenter, kphome, kpend, kpleft, kpup, kpright, kpdown,
kppgup, kppgdn, kpmul, kpadd, kpsub, kpdiv, kpdec, and kp0-kp9.

Usage:

```lua
keys.KEYSYMS[0x1234] = 'symbol'
keys['ctrl+symbol'] = function() ... end
```

<a id="keys.assign_platform_bindings"></a>
### `keys.assign_platform_bindings`([*keys*=keys], *bindings*)

Assigns key bindings for the current platform based on a map of commands to lists of their
platform-specific key sequences.

Parameters:
- *keys*:  Table to assign key bindings in.
- *bindings*:  Map of Lua functions to tables of key sequences for Windows/Linux/BSD, macOS,
	and the terminal version, in that order. A platform key sequence may itself be a table
	of sequences in order to assign multiple sequences to the same command.

Usage:

```lua
keys.assign_platform_bindings{
	[buffer.new] = {'ctrl+n', 'cmd+n', 'ctrl+n'}
	[buffer.line_down] = {'down', {'down', 'ctrl+n'}, 'down'},
}
```

<a id="keys.keychain"></a>
### `keys.keychain`

The current chain of key sequences.
(Read-only)

<a id="keys.mode"></a>
### `keys.mode`

The current key mode.

When non-`nil`, all key bindings defined outside of `keys[keys.mode]` are ignored.

The default value is `nil`.



<a id="lexer"></a>
## The `lexer` module

Lexes Scintilla documents and source code with Lua and LPeg.


### Contents

1. [Writing Lua Lexers](#writing-lua-lexers)
2. [Lexer Basics](#lexer-basics)
  - [New Lexer Template](#new-lexer-template)
  - [Tags](#tags)
  - [Rules](#rules)
  - [Summary](#summary)
3. [Advanced Techniques](#advanced-techniques)
  - [Line Lexers](#line-lexers)
  - [Embedded Lexers](#embedded-lexers)
  - [Lexers with Complex State](#lexers-with-complex-state)
4. [Code Folding](#code-folding)
5. [Using Lexers](#using-lexers)
6. [Migrating Legacy Lexers](#migrating-legacy-lexers)
7. [Considerations](#considerations)
8. [API Documentation](#lexer.add_fold_point)

### Writing Lua Lexers

Lexers recognize and tag elements of source code for syntax highlighting. Scintilla (the
editing component behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are difficult to create and/or extend. On the other hand, Lua makes it easy to
to rapidly create new lexers, extend existing ones, and embed lexers within one another. Lua
lexers tend to be more readable than C++ lexers too.

While lexers can be written in plain Lua, Scintillua prefers using Parsing Expression
Grammars, or PEGs, composed with the Lua [LPeg library][]. As a result, this document is
devoted to writing LPeg lexers. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This module provides
convenience functions for creating and working with other more advanced patterns and concepts.

Operator | Description
-|-
`lpeg.P`(*string*) | Matches string *string* literally.
`lpeg.P`(*n*) | Matches exactly *n* number of characters.
`lpeg.S`(*string*) | Matches any character in string set *string*.
`lpeg.R`("*xy*") | Matches any character between range *x* and *y*.
*patt*`^`*n* | Matches at least *n* repetitions of *patt*.
*patt*`^`-*n* | Matches at most *n* repetitions of *patt*.
*patt1* `*` *patt2* | Matches *patt1* followed by *patt2*.
*patt1* `+` *patt2* | Matches *patt1* or *patt2* (ordered choice).
*patt1* `-` *patt2* | Matches *patt1* if *patt2* does not also match.
`-`*patt* | Matches if *patt* does not match, consuming no input.
`#`*patt* | Matches *patt* but consumes no input.

The first part of this document deals with rapidly constructing a simple lexer. The next part
deals with more advanced techniques, such as embedding lexers within one another. Following
that is a discussion about code folding, or being able to tell Scintilla which code blocks
are "foldable" (temporarily hideable from view). After that are instructions on how to use
Lua lexers with the aforementioned Textadept and SciTE editors. Finally there are comments
on lexer performance and limitations.

[LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Textadept]: https://orbitalquark.github.io/textadept
[SciTE]: https://scintilla.org/SciTE.html

### Lexer Basics

The *lexers/* directory contains all of Scintillua's Lua lexers, including any new ones you
write. Before attempting to write one from scratch though, first determine if your programming
language is similar to any of the 100+ languages supported. If so, you may be able to copy
and modify, or inherit from that lexer, saving some time and effort. The filename of your
lexer should be the name of your programming language in lower case followed by a *.lua*
extension. For example, a new Lua lexer has the name *lua.lua*.

#### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a new lexer. Feel
free to use it, replacing the '?' with the name of your lexer. Consider this snippet from
the template:

```lua
-- ? LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

--[[... lexer rules ...]]

-- Identifier.
local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
lex:add_rule('identifier', identifier)

--[[... more lexer rules ...]]

return lex
```

The first line of code is a Lua convention to store a global variable into a local variable
for quick access. The second line simply defines often used convenience variables. The third
and last lines [define](#lexer.new) and return the lexer object Scintillua uses; they are
very important and must be part of every lexer. Note the `...` passed to [`lexer.new()`](#lexer.new) is
literal: the lexer will assume the name of its filename or an alternative name specified
by [`lexer.load()`](#lexer.load) in embedded lexer applications. The fourth line uses something called a
"tag", an essential component of lexers. You will learn about tags shortly. The fifth line
defines a lexer grammar rule, which you will learn about later. (Be aware that it is common
practice to combine these two lines for short rules.)  Note, however, the `local` prefix in
front of variables, which is needed so-as not to affect Lua's global environment. All in all,
this is a minimal, working lexer that you can build on.

#### Tags

Take a moment to think about your programming language's structure. What kind of key elements
does it have? Most languages have elements like keywords, strings, and comments. The
lexer's job is to break down source code into these elements and "tag" them for syntax
highlighting. Therefore, tags are an essential component of lexers. It is up to you how
specific your lexer is when it comes to tagging elements. Perhaps only distinguishing between
keywords and identifiers is necessary, or maybe recognizing constants and built-in functions,
methods, or libraries is desirable. The Lua lexer, for example, tags the following elements:
keywords, functions, constants, identifiers, strings, comments, numbers, labels, attributes,
and operators. Even though functions and constants are subsets of identifiers, Lua programmers
find it helpful for the lexer to distinguish between them all. It is perfectly acceptable
to just recognize keywords and identifiers.

In a lexer, LPeg patterns that match particular sequences of characters are tagged with a
tag name using the the [`lexer.tag()`](#lexer.tag) function. Let us examine the "identifier" tag used in
the template shown earlier:

```lua
local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
```

At first glance, the first argument does not appear to be a string name and the second
argument does not appear to be an LPeg pattern. Perhaps you expected something like:

```lua
lex:tag('identifier', (lpeg.R('AZ', 'az')  + '_') * (lpeg.R('AZ', 'az', '09') + '_')^0)
```

The [`lexer`](#lexer) module actually provides a convenient list of common tag names and common LPeg
patterns for you to use. Tag names for programming languages include (but are not limited
to) `lexer.DEFAULT`, `lexer.COMMENT`, `lexer.STRING`, `lexer.NUMBER`, `lexer.KEYWORD`,
`lexer.IDENTIFIER`, `lexer.OPERATOR`, `lexer.ERROR`, `lexer.PREPROCESSOR`, `lexer.CONSTANT`,
`lexer.CONSTANT_BUILTIN`, `lexer.VARIABLE`, `lexer.VARIABLE_BUILTIN`, `lexer.FUNCTION`,
`lexer.FUNCTION_BUILTIN`, `lexer.FUNCTION_METHOD`, `lexer.CLASS`, `lexer.TYPE`, `lexer.LABEL`,
`lexer.REGEX`, `lexer.EMBEDDED`, and `lexer.ANNOTATION`. Tag names for markup languages include
(but are not limited to) `lexer.TAG`, `lexer.ATTRIBUTE`, `lexer.HEADING`, `lexer.BOLD`,
`lexer.ITALIC`, `lexer.UNDERLINE`, `lexer.CODE`, `lexer.LINK`, `lexer.REFERENCE`, and
`lexer.LIST`. Patterns include [`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum),
[`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph), [`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space),
[`lexer.newline`](#lexer.newline), [`lexer.nonnewline`](#lexer.nonnewline), [`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num),
[`lexer.bin_num`](#lexer.bin_num), [`lexer.integer`](#lexer.integer), [`lexer.float`](#lexer.float), [`lexer.number`](#lexer.number), and [`lexer.word`](#lexer.word). You may use
your own tag names if none of the above fit your language, but an advantage to using predefined
tag names is that the language elements your lexer recognizes will inherit any universal syntax
highlighting color theme that your editor uses. You can also "subclass" existing tag names by
appending a '.*subclass*' string to them. For example, the HTML lexer tags unknown tags as
`lexer.TAG .. '.unknown'`. This gives editors the opportunity to highlight those subclassed
tags in a different way than normal tags, or fall back to highlighting them as normal tags.

##### Example Tags

So, how might you recognize and tag elements like keywords, comments, and strings?  Here are
some examples.

**Keywords**

Instead of matching *n* keywords with *n* `P('keyword_n')` ordered choices, use one
of of the following methods:

1. Use the convenience function [`lexer.word_match()`](#lexer.word_match) optionally coupled with
   [`lexer.set_word_list()`](#lexer.set_word_list). It is much easier and more efficient to write word matches like:

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'keyword_1', 'keyword_2', ..., 'keyword_n'
   })

   local case_insensitive_word = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD, true))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
   })

   local hyphenated_keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'keyword-1', 'keyword-2', ..., 'keyword-n'
   })
   ```

   The benefit of using this method is that other lexers that inherit from, embed, or embed
   themselves into your lexer can set, replace, or extend these word lists. For example,
   the TypeScript lexer inherits from JavaScript, but extends JavaScript's keyword and type
   lists with more options.

   This method also allows applications that use your lexer to extend or replace your word
   lists. For example, the Lua lexer includes keywords and functions for the latest version
   of Lua (5.4 at the time of writing). However, editors using that lexer might want to use
   keywords from Lua version 5.1, which is still quite popular.

   Note that calling `lex:set_word_list()` is completely optional. Your lexer is allowed to
   expect the editor using it to supply word lists. Scintilla-based editors can do so via
   Scintilla's `ILexer5` interface.

2. Use the lexer-agnostic form of [`lexer.word_match()`](#lexer.word_match):

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
     'keyword_1', 'keyword_2', ..., 'keyword_n'
   })

   local case_insensitive_keyword = lex:tag(lexer.KEYWORD, lexer.word_match({
     'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
   }, true))

   local hyphened_keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
     'keyword-1', 'keyword-2', ..., 'keyword-n'
   })
   ```

   For short keyword lists, you can use a single string of words. For example:

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('key_1 key_2 ... key_n'))
   ```

   You can use this method for static word lists that do not change, or where it does not
   make sense to allow applications or other lexers to extend or replace a word list.

**Comments**

Line-style comments with a prefix character(s) are easy to express:

```lua
local shell_comment = lex:tag(lexer.COMMENT, lexer.to_eol('#'))
local c_line_comment = lex:tag(lexer.COMMENT, lexer.to_eol('//', true))
```

The comments above start with a '#' or "//" and go to the end of the line (EOL). The second
comment recognizes the next line also as a comment if the current line ends with a '\\'
escape character.

C-style "block" comments with a start and end delimiter are also easy to express:

```lua
local c_comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/'))
```

This comment starts with a "/\*" sequence and contains anything up to and including an ending
"\*/" sequence. The ending "\*/" is optional so the lexer can recognize unfinished comments
as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a sequence like
"\\&quot;" in a double-quoted string indicates that the '&quot;' is not the end of the
string. [`lexer.range()`](#lexer.range) handles escapes inherently.

```lua
local dq_str = lexer.range('"')
local sq_str = lexer.range("'")
local string = lex:tag(lexer.STRING, dq_str + sq_str)
```

In this case, the lexer treats '\\' as an escape character in a string sequence.

**Numbers**

Most programming languages have the same format for integers and floats, so it might be as
simple as using a predefined LPeg pattern:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number)
```

However, some languages allow postfix characters on integers:

```lua
local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
local number = lex:tag(lexer.NUMBER, lexer.float + lexer.hex_num + integer)
```

Other languages allow separaters within numbers for better readability:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number_('_')) -- recognize 1_000_000
```

Your language may need other tweaks, but it is up to you how fine-grained you want your
highlighting to be. After all, you are not writing a compiler or interpreter!

#### Rules

Programming languages have grammars, which specify valid syntactic structure. For example,
comments usually cannot appear within a string, and valid identifiers (like variable names)
cannot be keywords. In Lua lexers, grammars consist of LPeg pattern rules, many of which
are tagged.  Recall from the lexer template the [`lexer.add_rule()`](#lexer.add_rule) call, which adds a rule
to the lexer's grammar:

```lua
lex:add_rule('identifier', identifier)
```

Each rule has an associated name, but rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if text does not
match the first rule added to the grammar, the lexer tries to match the second rule added, and
so on. Right now this lexer simply matches identifiers under a rule named "identifier".

To illustrate the importance of rule order, here is an example of a simplified Lua lexer:

```lua
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, ...))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ...))
lex:add_rule('string', lex:tag(lexer.STRING, ...))
lex:add_rule('comment', lex:tag(lexer.COMMENT, ...))
lex:add_rule('number', lex:tag(lexer.NUMBER, ...))
lex:add_rule('label', lex:tag(lexer.LABEL, ...))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, ...))
```

Notice how identifiers come _after_ keywords. In Lua, as with most programming languages,
the characters allowed in keywords and identifiers are in the same set (alphanumerics plus
underscores). If the lexer added the "identifier" rule before the "keyword" rule, all keywords
would match identifiers and thus would be incorrectly tagged (and likewise incorrectly
highlighted) as identifiers instead of keywords. The same idea applies to function names,
constants, etc. that you may want to distinguish between: their rules should come before
identifiers.

So what about text that does not match any rules? For example in Lua, the '!' character is
meaningless outside a string or comment. Normally the lexer skips over such text. If instead
you want to highlight these "syntax errors", add a final rule:

```lua
lex:add_rule('keyword', keyword)
--[[...]]
lex:add_rule('error', lex:tag(lexer.ERROR, lexer.any))
```

This identifies and tags any character not matched by an existing rule as a `lexer.ERROR`.

Even though the rules defined in the examples above contain a single tagged pattern, rules may
consist of multiple tagged patterns. For example, the rule for an HTML tag could consist of a
tagged tag followed by an arbitrary number of tagged attributes, separated by whitespace. This
allows the lexer to produce all tags separately, but in a single, convenient rule. That rule
might look something like this:

```lua
local ws = lex:get_rule('whitespace') -- predefined rule for all lexers
lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)
```

Note however that lexers with complex rules like these are more prone to lose track of their
state, especially if they span multiple lines.

#### Summary

Lexers primarily consist of tagged patterns and grammar rules. These patterns match language
elements like keywords, comments, and strings, and rules dictate the order in which patterns
are matched. At your disposal are a number of convenience patterns and functions for rapidly
creating a lexer. If you choose to use predefined tag names (or perhaps even subclassed
names) for your patterns, you do not have to update your editor's theme to specify how to
syntax-highlight those patterns. Your language's elements will inherit the default syntax
highlighting color theme your editor uses.

### Advanced Techniques

#### Line Lexers

By default, lexers match the arbitrary chunks of text passed to them by Scintilla. These
chunks may be a full document, only the visible part of a document, or even just portions of
lines. Some lexers need to match whole lines. For example, a lexer for the output of a file
"diff" needs to know if the line started with a '+' or '-' and then highlight the entire
line accordingly. To indicate that your lexer matches by line, create the lexer with an
extra parameter:

```lua
local lex = lexer.new(..., {lex_by_line = true})
```

Now the input text for the lexer is a single line at a time. Keep in mind that line lexers
do not have the ability to look ahead to subsequent lines.

#### Embedded Lexers

Scintillua lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and the lexer a child
is being embedded in is called the "parent". For example, consider an HTML lexer and a CSS
lexer. Either lexer stands alone for tagging their respective HTML and CSS files. However, CSS
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

```lua
local css = lexer.load('css')
```

The next part of the embedding process is telling the parent lexer when to switch over
to the child lexer and when to switch back. The lexer refers to these indications as the
"start rule" and "end rule", respectively, and are just LPeg patterns. Continuing with the
HTML/CSS example, the transition from HTML to CSS is when the lexer encounters a "style"
tag with a "type" attribute whose value is "text/css":

```lua
local css_tag = P('<style') * P(function(input, index)
  if input:find('^[^>]+type="text/css"', index) then return true end
end)
```

This pattern looks for the beginning of a "style" tag and searches its attribute list for
the text "`type="text/css"`". (In this simplified example, the Lua pattern does not consider
whitespace between the '=' nor does it consider that using single quotes is valid.) If there
is a match, the functional pattern returns `true`. However, we ultimately want to tag the
"style" tag as an HTML tag, so the actual start rule looks like this:

```lua
local css_start_rule = #css_tag * tag
```

Now that the parent knows when to switch to the child, it needs to know when to switch
back. In the case of HTML/CSS, the switch back occurs when the lexer encounters an ending
"style" tag, though the lexer should still tag that tag as an HTML tag:

```lua
local css_end_rule = #P('</style>') * tag
```

Once the parent loads the child lexer and defines the child's start and end rules, it embeds
the child with the [`lexer.embed()`](#lexer.embed) function:

```lua
lex:embed(css, css_start_rule, css_end_rule)
```

##### Child Lexer

The process for instructing a child lexer to embed itself into a parent is very similar to
embedding a child into a parent: first, load the parent lexer into the child lexer with the
[`lexer.load()`](#lexer.load) function and then create start and end rules for the child lexer. However,
in this case, call [`lexer.embed()`](#lexer.embed) with switched arguments. For example, in the PHP lexer:

```lua
local html = lexer.load('html')
local php_start_rule = lex:tag('php_tag', '<?php' * lexer.space)
local php_end_rule = lex:tag('php_tag', '?>')
html:embed(lex, php_start_rule, php_end_rule)
```

Note that the use of a 'php_tag' tag will require the editor using the lexer to specify how
to highlight text with that tag. In order to avoid this, you could use the `lexer.PREPROCESSOR`
tag instead.

#### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of text in a
document. However, there may be rare cases where a lexer does need to keep track of some
sort of persistent state. Rather than using `lpeg.P` function patterns that set state
variables, it is recommended to make use of Scintilla's built-in, per-line state integers via
[`lexer.line_state`](#lexer.line_state). It was designed to accommodate up to 32 bit-flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given to an `lpeg.P`
function pattern. (Any positions derived from that position argument will also work.)

Writing stateful lexers is beyond the scope of this document.

### Code Folding

When reading source code, it is occasionally helpful to temporarily hide blocks of code like
functions, classes, comments, etc. This is the concept of "folding". In the Textadept and
SciTE editors for example, little markers in the editor margins appear next to code that
can be folded at places called "fold points". When the user clicks on one of those markers,
the editor hides the code associated with the marker until the user clicks on the marker
again. The lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences. Examples of
fold keywords are "if" and "end" in Lua and examples of fold character sequences are '{',
'}', "/\*", and "\*/" in C for code block and comment delimiters, respectively. However,
these fold points cannot occur just anywhere. For example, lexers should not recognize fold
keywords that appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function allows
you to conveniently define fold points with such granularity. For example, consider C:

```lua
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
```

The first assignment states that any '{' or '}' that the lexer tagged as an `lexer.OPERATOR`
is a fold point. Likewise, the second assignment states that any "/\*" or "\*/" that the
lexer tagged as part of a `lexer.COMMENT` is a fold point. The lexer does not consider any
occurrences of these characters outside their tagged elements (such as in a string) as fold
points. How do you specify fold keywords? Here is an example for Lua:

```lua
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')
```

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and specify keywords in
lower case.

If your lexer needs to do some additional processing in order to determine if a tagged element
is a fold point, pass a function to `lex:add_fold_point()` that returns an integer. A return
value of `1` indicates the element is a beginning fold point and a return value of `-1`
indicates the element is an ending fold point. A return value of `0` indicates the element
is not a fold point. For example:

```lua
local function fold_strange_element(text, pos, line, s, symbol)
  if ... then
    return 1 -- beginning fold point
  elseif ... then
    return -1 -- ending fold point
  end
  return 0
end

lex:add_fold_point('strange_element', '|', fold_strange_element)
```

Any time the lexer encounters a '|' that is tagged as a "strange_element", it calls the
`fold_strange_element` function to determine if '|' is a fold point. The lexer calls these
functions with the following arguments: the text to identify fold points in, the beginning
position of the current line in the text to fold, the current line's text, the position in
the current line the fold point text starts at, and the fold point text itself.

#### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate fold points. If
your lexer falls into this category and you would like to mark fold points based on changes
in indentation, create the lexer with a `fold_by_indentation = true` option:

```lua
local lex = lexer.new(..., {fold_by_indentation = true})
```

#### Custom Folding

Lexers with complex folding needs can implement their own folders by defining their own
[`lex:fold()`](#lexer.fold) method. Writing custom folders is beyond the scope of this document.

### Using Lexers

**Textadept**

Place your lexer in your *~/.textadept/lexers/* directory so you do not overwrite it when
upgrading Textadept. Also, lexers in this directory override default lexers. Thus, Textadept
loads a user *lua* lexer instead of the default *lua* lexer. This is convenient for tweaking
a default lexer to your liking. Then add a [file extension](#lexer.detect_extensions) for
your lexer if necessary.

**SciTE**

Create a *.properties* file for your lexer and `import` it in either your *SciTEUser.properties*
or *SciTEGlobal.properties*. The contents of the *.properties* file should contain:

	file.patterns.[lexer_name]=[file_patterns]
	lexer.$(file.patterns.[lexer_name])=scintillua.[lexer_name]
	keywords.$(file.patterns.[lexer_name])=scintillua
	keywords2.$(file.patterns.[lexer_name])=scintillua
	...
	keywords9.$(file.patterns.[lexer_name])=scintillua

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension) and
`[file_patterns]` is a set of file extensions to use your lexer for. The `keyword` settings are
only needed if another SciTE properties file has defined keyword sets for `[file_patterns]`.
The `scintillua` keyword setting instructs Scintillua to use the keyword sets defined within
the lexer. You can override a lexer's keyword set(s) by specifying your own in the same order
that the lexer calls `lex:set_word_list()`. For example, the Lua lexer's first set of keywords
is for reserved words, the second is for built-in global functions, the third is for library
functions, the fourth is for built-in global constants, and the fifth is for library constants.

SciTE assigns styles to tag names in order to perform syntax highlighting. Since the set of
tag names used for a given language changes, your *.properties* file should specify styles
for tag names instead of style numbers. For example:

	scintillua.styles.my_tag=$(scintillua.styles.keyword),bold

### Migrating Legacy Lexers

Legacy lexers are of the form:

```lua
local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('?')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
  --[[...]]
}))

--[[... other rule definitions ...]]

-- Custom.
lex:add_rule('custom_rule', token('custom_token', ...))
lex:add_style('custom_token', lexer.styles.keyword .. {bold = true})

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

return lex
```

While Scintillua will mostly handle such legacy lexers just fine without any changes, it is
recommended that you migrate yours. The migration process is fairly straightforward:

1. [`lexer`](#lexer) exists in the default lexer environment, so `require('lexer')` should be replaced
   by simply [`lexer`](#lexer). (Keep in mind `local lexer = lexer` is a Lua idiom.)
2. Every lexer created using [`lexer.new()`](#lexer.new) should no longer specify a lexer name by string,
   but should instead use `...` (three dots), which evaluates to the lexer's filename or
   alternative name in embedded lexer applications.
3. Every lexer created using [`lexer.new()`](#lexer.new) now includes a rule to match whitespace. Unless
   your lexer has significant whitespace, you can remove your legacy lexer's whitespace
   token and rule. Otherwise, your defined whitespace rule will replace the default one.
4. The concept of tokens has been replaced with tags. Instead of calling a `token()` function,
   call [`lex:tag()`](#lexer.tag) instead.
5. Lexers now support replaceable word lists. Instead of calling [`lexer.word_match()`](#lexer.word_match) with
   large word lists, call it as an instance method with an identifier string (typically
   something like `lexer.KEYWORD`). Then at the end of the lexer (before `return lex`), call
   [`lex:set_word_list()`](#lexer.set_word_list) with the same identifier and the usual
   list of words to match. This allows users of your lexer to call `lex:set_word_list()`
   with their own set of words should they wish to.
6. Lexers no longer specify styling information. Remove any calls to `lex:add_style()`. You
   may need to add styling information for custom tags to your editor's theme.
7. `lexer.last_char_includes()` has been deprecated in favor of the new [`lexer.after_set()`](#lexer.after_set).
   Use the character set and pattern as arguments to that new function.

As an example, consider the following sample legacy lexer:

```lua
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
```

Following the migration steps would yield:

```lua
local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('custom', lex:tag('custom', 'quux'))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"')))
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('#')))
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%^=<>,.()[]{}')))

lex:add_fold_point(lexer.OPERATOR, '{', '}')

lex:set_word_list(lexer.KEYWORD, {'foo', 'bar', 'baz'})

return lex
```

Any editors using this lexer would have to add a style for the 'custom' tag.

### Considerations

#### Performance

There might be some slight overhead when initializing a lexer, but loading a file from disk
into Scintilla is usually more expensive. Actually painting the syntax highlighted text to
the screen is often more expensive than the lexing operation. On modern computer systems,
I see no difference in speed between Lua lexers and Scintilla's C++ ones. Optimize lexers for
speed by re-arranging [`lexer.add_rule()`](#lexer.add_rule) calls so that the most common rules match first. Do
keep in mind that order matters for similar rules.

In some cases, folding may be far more expensive than lexing, particularly in lexers with a
lot of potential fold points. If your lexer is exhibiting signs of slowness, try disabling
folding in your text editor first. If that speeds things up, you can try reducing the number
of fold points you added, overriding [`lexer.fold()`](#lexer.fold) with your own implementation, or simply
eliminating folding support from your lexer.

#### Limitations

Embedded preprocessor languages like PHP cannot completely embed themselves into their parent
languages because the parent's tagged patterns do not support start and end rules. This
mostly goes unnoticed, but code like

```php
    <div id="<?php echo $id; ?>">
```

will not be tagged correctly. Also, these types of languages cannot currently embed themselves
into their parent's child languages either.

A language cannot embed itself into something like an interpolated string because it is
possible that if lexing starts within the embedded entity, it will not be detected as such,
so a child to parent transition cannot happen. For example, the following Ruby code will
not be tagged correctly:

```ruby
    sum = "1 + 2 = #{1 + 2}"
```

Also, there is the potential for recursion for languages embedding themselves within themselves.

#### Troubleshooting

Errors in lexers can be tricky to debug. Lexers print Lua errors to `io.stderr` and `_G.print()`
statements to `io.stdout`. Running your editor from a terminal is the easiest way to see
errors as they occur.

#### Risks

Poorly written lexers have the ability to crash Scintilla (and thus its containing application),
so unsaved data might be lost. However, I have only observed these crashes in early lexer
development, when syntax errors or pattern errors are present. Once the lexer actually
starts processing and tagging text (either correctly or incorrectly, it does not matter),
I have not observed any crashes.

#### Acknowledgements

Thanks to Peter Odding for his [lexer post][] on the Lua mailing list that provided inspiration,
and thanks to Roberto Ierusalimschy for LPeg.

[lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

<a id="lexer.add_fold_point"></a>
### `lexer.add_fold_point`(*lexer*, *tag_name*, *start_symbol*, *end_symbol*)

Adds a fold point to a lexer.

Parameters:
- *lexer*:  Lexer to add a fold point to.
- *tag_name*:  String tag name of fold point text.
- *start_symbol*:  String fold point start text.
- *end_symbol*:  Either string fold point end text, or a function that returns whether or
   not *start_symbol* is a beginning fold point (1), an ending fold point (-1), or not a fold
   point at all (0). If it is a function, it is passed the following arguments:
   - `text`: The text being processed for fold points.
   - `pos`: The position in *text* of the beginning of the line currently being processed.
   - `line`: The text of the line currently being processed.
   - `s`: The position of *start_symbol* in *line*.
   - `symbol`: *start_symbol* itself.

Usage:

```lua
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point('custom', function(text, pos, line, s, symbol) ... end)
```

<a id="lexer.add_rule"></a>
### `lexer.add_rule`(*lexer*, *id*, *rule*)

Adds a rule to a lexer.

Parameters:
- *lexer*:  Lexer to add *rule* to.
- *id*:  String id associated with this rule. It does not have to be the same as the name
   passed to `lex:tag()`.
- *rule*:  LPeg pattern of the rule to add.

<a id="lexer.after_set"></a>
### `lexer.after_set`(*set*, *patt*, *skip*)

Returns a pattern that only matches when it comes after certain characters (or when there
are no characters behind it).

Parameters:
- *set*:  String character set like one passed to `lpeg.S()`.
- *patt*:  LPeg pattern to match after a character in *set*.
- *skip*:  String character set to skip over when looking backwards from *patt*. The default
   value is " \t\r\n\v\f" (whitespace).

Usage:

```lua
local regex = lexer.after_set('+-*!%^&|=,([{', lexer.range('/'))
   -- matches "var re = /foo/;", but not "var x = 1 / 2 / 3;"
```

<a id="lexer.alnum"></a>
### `lexer.alnum`

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z', '0'-'9').

<a id="lexer.alpha"></a>
### `lexer.alpha`

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
### `lexer.any`

A pattern that matches any single character.

<a id="lexer.bin_num"></a>
### `lexer.bin_num`

A pattern that matches a binary number.

<a id="lexer.bin_num_"></a>
### `lexer.bin_num_`(*c*)

Returns a pattern that matches a binary number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.dec_num"></a>
### `lexer.dec_num`

A pattern that matches a decimal number.

<a id="lexer.dec_num_"></a>
### `lexer.dec_num_`(*c*)

Returns a pattern that matches a decimal number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.detect"></a>
### `lexer.detect`([*filename*[, *line*]])

Returns the name of the lexer often associated a particular filename and/or file content.

Parameters:
- *filename*:  String filename to inspect. The default value is read from the
   "lexer.scintillua.filename" property.
- *line*:  String first content line, such as a shebang line. The default value
   is read from the "lexer.scintillua.line" property.

Returns: string lexer name to pass to [`lexer.load()`](#lexer.load), or `nil` if none was detected

<a id="lexer.detect_extensions"></a>
### `lexer.detect_extensions`

Map of file extensions, without the '.' prefix, to their associated lexer names.

Usage:

```lua
lexer.detect_extensions.luadoc = 'lua'
```

<a id="lexer.detect_patterns"></a>
### `lexer.detect_patterns`

Map of first-line patterns to their associated lexer names.

These are Lua string patterns, not LPeg patterns.

Usage:

```lua
lexer.detect_patterns['^#!.+/zsh'] = 'bash'
```

<a id="lexer.digit"></a>
### `lexer.digit`

A pattern that matches any digit ('0'-'9').

<a id="lexer.embed"></a>
### `lexer.embed`(*lexer*, *child*, *start_rule*, *end_rule*)

Embeds a child lexer into a parent lexer.

Parameters:
- *lexer*:  Parent lexer.
- *child*:  Child lexer.
- *start_rule*:  LPeg pattern matches the beginning of the child lexer.
- *end_rule*:  LPeg pattern that matches the end of the child lexer.

Usage:

```lua
html:embed(css, css_start_rule, css_end_rule)
html:embed(lex, php_start_rule, php_end_rule) -- from php lexer
```

<a id="lexer.float"></a>
### `lexer.float`

A pattern that matches a floating point number.

<a id="lexer.float_"></a>
### `lexer.float_`(*c*)

Returns a pattern that matches a floating point number, whose digits may be separated by a
particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.fold"></a>
### `lexer.fold`(*lexer*, *text*, *start_line*, *start_level*)

Determines fold points in a chunk of text.

Parameters:
- *lexer*:  Lexer to fold text with.
- *text*:  String text to fold, which may be a partial chunk, single line, or full text.
- *start_line*:  Line number *text* starts on, counting from 1.
- *start_level*:  Fold level *text* starts with. It cannot be lower than `lexer.FOLD_BASE`
   (1024).

Returns: table of line numbers mapped to fold levels

Usage:

```lua
lex:fold(...) --> {[1] = 1024, [2] = 9216, [3] = 1025, [4] = 1025, [5] = 1024}
```

<a id="lexer.fold_level"></a>
### `lexer.fold_level`

Map of line numbers (starting from 1) to their fold level bit-masks.
(Read-only)
Fold level masks are composed of an integer level combined with any of the following bits:

  - `lexer.FOLD_BASE`
    The initial fold level (1024).
  - `lexer.FOLD_BLANK`
    The line is blank.
  - `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.get_rule"></a>
### `lexer.get_rule`(*lexer*, *id*)

Returns a lexer's rule.

Parameters:
- *lexer*:  Lexer to fetch a rule from.
- *id*:  String id of the rule to fetch.

<a id="lexer.graph"></a>
### `lexer.graph`

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
### `lexer.hex_num`

A pattern that matches a hexadecimal number.

<a id="lexer.hex_num_"></a>
### `lexer.hex_num_`(*c*)

Returns a pattern that matches a hexadecimal number, whose digits may be separated by
a particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.indent_amount"></a>
### `lexer.indent_amount`

Map of line numbers (starting from 1) to their indentation amounts, measured in character
columns.
(Read-only)

<a id="lexer.integer"></a>
### `lexer.integer`

A pattern that matches either a decimal, hexadecimal, octal, or binary number.

<a id="lexer.integer_"></a>
### `lexer.integer_`(*c*)

Returns a pattern that matches either a decimal, hexadecimal, octal, or binary number,
whose digits may be separated by a particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.lex"></a>
### `lexer.lex`(*lexer*, *text*, *init_style*)

Lexes a chunk of text.

Parameters:
- *lexer*:  Lexer to lex text with.
- *text*:  String text to lex, which may be a partial chunk, single line, or full text.
- *init_style*:  Number of the text's current style. Multiple-language lexers use this to
   determine which language to start lexing in.

Returns: table of tag names and positions.

Usage:

```lua
lex:lex(...) --> {'keyword', 2, 'whitespace.lua', 3, 'identifier', 7}
```

<a id="lexer.line_end"></a>
### `lexer.line_end`

Map of line numbers (starting from 1) to their end positions.
(Read-only)

<a id="lexer.line_from_position"></a>
### `lexer.line_from_position`(*pos*)

Returns a position's line number (starting from 1).

Parameters:
- *pos*:  Position (starting from 1) to get the line number of.

<a id="lexer.line_start"></a>
### `lexer.line_start`

Map of line numbers (starting from 1) to their start positions.
(Read-only)

<a id="lexer.line_state"></a>
### `lexer.line_state`

Map of line numbers (starting from 1) to their 32-bit integer line states.

Line states can be used by lexers for keeping track of persistent states (up to 32 states
with 1 state per bit). For example, the output lexer uses this to mark lines that have
warnings or errors.

<a id="lexer.load"></a>
### `lexer.load`(*name*[, *alt_name*])

Initializes or loads a lexer.

Scintilla calls this function in order to load a lexer. Parent lexers also call this function
in order to load child lexers and vice-versa. The user calls this function in order to load
a lexer when using Scintillua as a Lua library.

Parameters:
- *name*:  String name of the lexing language.
- *alt_name*:  String alternate name of the lexing language. This is useful for
   embedding the same child lexer with multiple sets of start and end tags.

Returns: lexer object

<a id="lexer.lower"></a>
### `lexer.lower`

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.modify_rule"></a>
### `lexer.modify_rule`(*lexer*, *id*, *rule*)

Replaces a lexer's existing rule.

Parameters:
- *lexer*:  Lexer to modify.
- *id*:  String id of the rule to replace.
- *rule*:  LPeg pattern of the new rule.

<a id="lexer.names"></a>
### `lexer.names`([*path*])

Returns a table of all known lexer names.

This function is not available to lexers and requires the LuaFileSystem ([`lfs`](#lfs)) module to
be available.

Parameters:
- *path*:  String list of ';'-separated directories to search for lexers in. The
   default value is Scintillua's configured lexer path.

<a id="lexer.new"></a>
### `lexer.new`(*name*[, *opts*])

Creates a new lexer.

Parameters:
- *name*:  String lexer name. Use `...` to inherit from the file's name.
- *opts*:  Table of lexer options. Options currently supported:
   - `lex_by_line`: Only processes whole lines of text at a time (instead of arbitrary chunks
     of text). Line lexers cannot look ahead to subsequent lines. The default value is `false`.
   - `fold_by_indentation`: Calculate fold points based on changes in line indentation. The
     default value is `false`.
   - `case_insensitive_fold_points`: Fold points added via [`lexer.add_fold_point()`](#lexer.add_fold_point) should
     ignore case. The default value is `false`.
   - `no_user_word_lists`: Do not automatically allocate word lists that can be set by
     users. This should really only be set by non-programming languages like markup languages.
   - `inherit`: Lexer to inherit from. The default value is `nil`.

Returns: lexer object

Usage:

```lua
lexer.new(..., {inherit = lexer.load('html')}) -- name is 'rhtml' in rhtml.lua file
```

<a id="lexer.newline"></a>
### `lexer.newline`

A pattern that matches an end of line, either CR+LF or LF.

<a id="lexer.nonnewline"></a>
### `lexer.nonnewline`

A pattern that matches any single, non-newline character.

<a id="lexer.number"></a>
### `lexer.number`

A pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number.

<a id="lexer.number_"></a>
### `lexer.number_`(*c*)

Returns a pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number, and whose digits may be separated by a particular character.

Parameters:
- *c*:  Digit separator character.

Usage:

```lua
lexer.number_('_') -- matches 1_000_000
```

<a id="lexer.oct_num"></a>
### `lexer.oct_num`

A pattern that matches an octal number.

<a id="lexer.oct_num_"></a>
### `lexer.oct_num_`(*c*)

Returns a pattern that matches an octal number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.property"></a>
### `lexer.property`

Map of key-value string pairs.

The contents of this map are application-dependant.

<a id="lexer.property_int"></a>
### `lexer.property_int`

Alias of [`lexer.property`](#lexer.property), but with values interpreted as numbers, or `0` if not
found.
(Read-only)

<a id="lexer.punct"></a>
### `lexer.punct`

A pattern that matches any punctuation character ('!' to '/', ':' to '@', '[' to ''', '{'
to '~').

<a id="lexer.range"></a>
### `lexer.range`(*s*[, *e*=s[, *single_line*=false[, *escapes*[, *balanced*=false]]]])

Returns a pattern that matches a bounded range of text.

This is a convenience function for matching more complicated ranges like strings with escape
characters, balanced parentheses, and block comments (nested or not).

Parameters:
- *s*:  String or LPeg pattern start of the range.
- *e*:  String or LPeg pattern end of the range. The default value is *s*.
- *single_line*:  Restrict the range to a single line.
- *escapes*:  Allow the range end to be escaped by a '\\' character. The default
   value is `false` unless *s* and *e* are identical, single-character strings. In that case,
   the default value is `true`.
- *balanced*:  Match a balanced range, like the "%b" Lua pattern. This flag
   only applies if *s* and *e* are different.

Usage:

```lua
local dq_str_escapes = lexer.range('"')
local dq_str_noescapes = lexer.range('"', false, false)
local unbalanced_parens = lexer.range('(', ')')
local balanced_parens = lexer.range('(', ')', false, false, true)
```

<a id="lexer.set_word_list"></a>
### `lexer.set_word_list`(*lexer*, *name*, *word_list*[, *append*=false])

Sets the words in a lexer's word list.

This only has an effect if the lexer uses [`lexer.word_match()`](#lexer.word_match) to reference the given list.

Parameters:
- *lexer*:  Lexer to add a word list to.
- *name*:  String name or number of the word list to set.
- *word_list*:  Table of words or a string list of words separated by
   spaces. Case-insensitivity is specified by a [`lexer.word_match()`](#lexer.word_match) reference to this list.
- *append*:  Append *word_list* to an existing word list (if any).

<a id="lexer.space"></a>
### `lexer.space`

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n', '\r', space).

<a id="lexer.starts_line"></a>
### `lexer.starts_line`(*patt*[, *allow_indent*=false])

Returns a pattern that matches only at the beginning of a line.

Parameters:
- *patt*:  LPeg pattern to match at the beginning of a line.
- *allow_indent*:  Allow *patt* to match after line indentation.

Usage:

```lua
local preproc = lex:tag(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#')))
```

<a id="lexer.style_at"></a>
### `lexer.style_at`

Map of buffer positions (starting from 1) to their string style names.
(Read-only)

<a id="lexer.tag"></a>
### `lexer.tag`(*lexer*, *name*, *patt*)

Returns a tagged pattern.

Parameters:
- *lexer*:  Lexer to tag the pattern in.
- *name*:  String name to use for the tag. If it is not a predefined tag name
	(`lexer.[A-Z_]+`), its Scintilla style will likely need to be defined by the editor or
	theme using this lexer.
- *patt*:  LPeg pattern to tag.

Usage:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number)
local addition = lex:tag('addition', '+' * lexer.word)
```

<a id="lexer.text_range"></a>
### `lexer.text_range`(*pos*, *length*)

Returns a range of buffer text.

The current text being lexed or folded may be a subset of buffer text. This function can
return any text in the buffer.

Parameters:
- *pos*:  Position (starting from 1) of the text range to get. It needs to be an absolute
	position. Use a combination of [`lexer.line_from_position()`](#lexer.line_from_position) and [`lexer.line_start`](#lexer.line_start)
	to get one.
- *length*:  Length of the text range to get.

<a id="lexer.to_eol"></a>
### `lexer.to_eol`([*prefix*[, *escape*=false]])

Returns a pattern that matches a prefix until the end of its line.

Parameters:
- *prefix*:  String or pattern prefix to start matching at. The default value is any
   non-newline character.
- *escape*:  Allow newline escapes using a '\\' character.

Usage:

```lua
local line_comment = lexer.to_eol('//')
local line_comment = lexer.to_eol(S('#;'))
```

<a id="lexer.upper"></a>
### `lexer.upper`

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
### `lexer.word`

A pattern that matches a typical word.
Words begin with a letter or underscore and consist
of alphanumeric and underscore characters.

<a id="lexer.word_match"></a>
### `lexer.word_match`([*lexer*], *word_list*[, *case_insensitive*=false])

Returns a pattern that matches a word in a word list.

This is a convenience function for simplifying a set of ordered choice word patterns and
potentially allowing downstream users to configure word lists.

Parameters:
- *lexer*:  Lexer to match a word in a word list for. This parameter may be omitted
   for lexer-agnostic matching.
- *word_list*:  Either a string name of the word list to match from if *lexer* is given, or,
   if *lexer* is omitted, a table of words or a string list of words separated by spaces. If a
   word list name was given and there is ultimately no word list set via `lex:set_word_list()`,
   no error will be raised, but the returned pattern will not match anything.
- *case_insensitive*:  Match the word case-insensitively.

Usage:

```lua
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{'foo', 'bar', 'baz'})
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match({'foo-bar', 'foo-baz',
   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, true))
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('foo bar baz'))
```

<a id="lexer.xdigit"></a>
### `lexer.xdigit`

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').



<a id="lfs"></a>
## The `lfs` module

Extends the [`lfs`](#lfs) library to find files in directories and determine absolute file paths.


### Filters

The [`lfs.walk()`](#lfs.walk) function accepts a filter that specifies which files and directories the
returned iterator should yield. A filter is a shell-style glob string or table of such
strings with the following syntax:
- `/`: directory separator (Windows will expand this to match '\\' too).
- `*`: matches any part of a single file or directory name.
- `?`: matches any character in a file or directory name.
- `[...]`: matches any character in the set; may be a range like `[0-9]`.
- `[!...]` or `[^...]`: matches any character not in the set; may be a range like `[^0-9]`.
- `{...}`: matches any one of the comma-separated items in the group.
- `**`: matches any number of directories, including no directory.
- `!glob`: rejects a matched glob. The `!` must be the first character.

For example:
```lua
'*.lua' -- match all Lua files in the top-level directory
'**/*.lua' -- match all Lua files in any directory
{'**/*.{c,h}', '!build'} -- match all C source files except in the top-level build/ directory
{'include/*', 'src/*'} -- match all immediate children of the 'include/' and 'src/' dirs
{'include/**', 'src/**'} -- match everything in 'include/' and 'src/', including subdirectories
```

<a id="lfs.abspath"></a>
### `lfs.abspath`(*filename*[, *prefix*])

Returns the absolute path to a filename.

The returned path is not guaranteed to exist.

Parameters:
- *filename*:  String path to a file.
- *prefix*:  String prefix path prepended to a relative filename. The default
	value is Textadept's current working directory.

<a id="lfs.default_filter"></a>
### `lfs.default_filter`

The default filter table used when iterating over files and directories using [`lfs.walk()`](#lfs.walk).

- File extensions excluded: a, bmp, bz2, class, dll, exe, gif, gz, jar, jpeg, jpg, o, pdf,
	png, so, tar, tgz, tif, tiff, xz, and zip.
- Directories excluded: .bzr, .git, .hg, .svn, \_FOSSIL\_, and node_modules.

<a id="lfs.walk"></a>
### `lfs.walk`(*dir*[, *filter*=lfs.default_filter[, *n*[, *include_dirs*=false]]])

Returns an iterator that iterates over all files in a directory and its sub-directories.

Parameters:
- *dir*:  String directory path to iterate over.
- *filter*:  [Filter](#filters) that specifies the files and
	directories the iterator should yield. It is a shell-style glob string or table of such
	glob strings. If *filter* is not `nil`, it will be combined with [`lfs.default_filter`](#lfs.default_filter).
- *n*:  Maximum number of directory levels to descend into. The default
	is to have no limit.
- *include_dirs*:  Include directory names in iterator results. Directory
	names will have a trailing '/' or '\\' (depending on the current platform) to distinguish
	them from regular files.

Usage:

```lua
for filename in lfs.walk(buffer.filename:match('^.+[/\\]')) do ... end
```



<a id="os"></a>
## The `os` module

Extends Lua's [`os`](#os) library to provide process spawning capabilities.

<a id="proc.close"></a>
### `proc:close`()

Closes the process's standard input, effectively sending it an EOF (end of file).

<a id="proc.kill"></a>
### `proc:kill`([*signal*=9])

Kills the running process.

Parameters:
- *signal*:  Unix signal to send, if not `SIGKILL`.

<a id="proc.read"></a>
### `proc:read`([*arg*='l'])

Returns stdout read from the running process, or `nil` plus an error code and an error
message if an error occurred.

This may block until stdout is available for reading.

If the process has a stdout callback function, you must manually read all stdout available
before Textadept can call that callback again.

Parameters:
- *arg*:  Argument similar to those in Lua's `io.read()`. In summary:
	- *n*: Read *n* number of bytes, or `nil` at end-of-file (EOF).
	- "a": Read all output, or an empty string at EOF.
	- "l": Read the next line, skipping any end-of-line (EOL) characters; or `nil` at EOF.
	- "L": Read the next line, including any EOL characters; or `nil` at EOF.

<a id="proc.status"></a>
### `proc:status`()

Returns the status of the process, either "running" or "terminated".

<a id="proc.wait"></a>
### `proc:wait`()

Blocks until the process finishes (if it has not already done so).

Returns: status code of the finished process

<a id="proc.write"></a>
### `proc:write`(...)

Writes to the process's stdin.


Linux note: When using the GTK or terminal version, if more than 65536 bytes (64K) are to
be written, it is possible those bytes need to be written in 65536-byte (64K) chunks, or
the process may not receive all input. However, it is also possible that there is a limit
on how many bytes can be written in a short period of time, perhaps 196608 bytes (192K). The
Qt version does not appear to have this limitation.

Parameters:
- *...*:  Standard input to write.

<a id="os.spawn"></a>
### `os.spawn`(*cmd*[, *cwd*][, *env*][, *stdout_cb*[, *stderr_cb*[, *exit_cb*]]])

Spawns an interactive child process in a separate thread.

Parameters:
- *cmd*:  Command line string that contains the program's name followed by arguments to
	pass to it. `$PATH` or `%PATH%` is searched for program names. On Windows, this entire
	string is passed to *cmd.exe*: `%COMSPEC% /c [cmd]`.
- *cwd*:  String current working directory (cwd) for the child process. When omitted,
	Textadept's cwd is used.
- *env*:  Table of environment variables for the child process. It can be a table of
	key-value string pairs, a table of "*key*=*value*" strings, or a combination of the
	two. When omitted, Textadept's environment is used. In order to create a new environment
	that inherits from Textadept's, you can: spawn `env` on macOS and Linux/BSD, or `set`
	on Windows; iterate over output matches of "key=value" pairs (one per line); assign
	them to the new environment table; add your own entries; and finally use that table here.
- *stdout_cb*:  Function that accepts a string parameter for a chunk of standard output
	read from the child. Textadept reads stdout in 1KB or 0.5KB chunks (depending on the
	platform), or however much data is available at the time.
- *stderr_cb*:  Function that accepts a string parameter for a chunk of standard
	error read from the child. Textadept reads stderr in 1KB or 0.5kB chunks (depending on
	the platform), or however much data is available at the time.
- *exit_cb*:  Function to call when the child process finishes. The child's exit
	status is passed as an argument.

Returns: proc or `nil` plus an error message on failure

Usage:

```lua
os.spawn('lua ' .. buffer.filename, print) -- non-interactive
local proc = os.spawn('lua -e "print(io.read())"', print) -- interactive
proc:write('foo\n')
proc:close() -- close stdin, not the process
```



<a id="string"></a>
## The `string` module

Extends Lua's [`string`](#string) library to provide encoding conversion.

<a id="string.iconv"></a>
### `string.iconv`(*text*, *new*, *old*)

Returns text converted from one encoding to another, or raises an error if the conversion
failed.

Valid encodings are [GNU libiconv's encodings][], and include:
- European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
	KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
	Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
	Macintosh.
- Semitic: ISO-8859-{6,8}, CP{1255,1256}, CP862, Mac{Hebrew,Arabic}.
- Japanese: EUC-JP, SHIFT_JIS, CP932, ISO-2022-JP, ISO-2022-JP-2, ISO-2022-JP-1.
- Chinese: EUC-CN, HZ, GBK, CP936, GB18030, EUC-TW, BIG5, CP950, BIG5-HKSCS, BIG5-HKSCS:2004,
	BIG5-HKSCS:2001, BIG5-HKSCS:1999, ISO-2022-CN, ISO-2022-CN-EXT.
- Korean: EUC-KR, CP949, ISO-2022-KR, JOHAB.
- Armenian: ARMSCII-8.
- Georgian: Georgian-Academy, Georgian-PS.
- Tajik: KOI8-T.
- Kazakh: PT154, RK1048.
- Thai: ISO-8859-11, TIS-620, CP874, MacThai.
- Laotian: MuleLao-1, CP1133.
- Vietnamese: VISCII, TCVN, CP1258.
- Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
	UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.

[GNU libiconv's encodings]: https://www.gnu.org/software/libiconv/

Parameters:
- *text*:  String text to convert.
- *new*:  String encoding name to convert to.
- *old*:  String encoding name to convert from.

Usage:

```lua
local utf8_filename = string.iconv(buffer.filename, 'UTF-8', _CHARSET)
local filename = string.iconv(utf8_filename, _CHARSET, 'UTF-8')
```



<a id="table"></a>
## The `table` module

Extends Lua's [`table`](#table) library to provide more utility functions.

<a id="table.map"></a>
### `table.map`(*t*, *f*[, ...])

Applies a map function to a list's items and returns a new table with the results.

Parameters:
- *t*:  Table to map. It may have an `n` field for its length.
- *f*:  Mapping function. The first parameter passed will be a value in *t*.
- *...*:  Additional values to pass to *f*.



<a id="textadept"></a>
## The `textadept` module

The textadept module.

It provides utilities for editing text in Textadept.



<a id="textadept.bookmarks"></a>
## The `textadept.bookmarks` module

Bookmarks for Textadept.

<a id="textadept.bookmarks.MARK_BOOKMARK"></a>
### `textadept.bookmarks.MARK_BOOKMARK`

The bookmark mark number.

<a id="textadept.bookmarks.clear"></a>
### `textadept.bookmarks.clear`()

Clears all bookmarks in the current buffer.

<a id="textadept.bookmarks.goto_mark"></a>
### `textadept.bookmarks.goto_mark`([*next*])

Jumps to a the beginning of a bookmarked line.

Parameters:
- *next*:  Jump to the next bookmarked line in the current buffer instead of the
	previous one. If `nil`, the user is prompted to select bookmarked line to jump to,
	which includes bookmarks from all open buffers.

Usage:

```lua
textadept.bookmarks.goto_mark(true) -- jump to the next bookmark
textadept.bookmarks.goto_mark(false) -- jump to the previous bookmark
```

<a id="textadept.bookmarks.toggle"></a>
### `textadept.bookmarks.toggle`()

Toggles a bookmark on the current line.



<a id="textadept.clipboard"></a>
## The `textadept.clipboard` module

Allows the terminal version's buffer clipboard functions to operate on the system clipboard.

This module is only enabled in the terminal version.

<a id="textadept.clipboard.copy_command"></a>
### `textadept.clipboard.copy_command`

The command to modify the system clipboard's contents.

The default values are:
- Windows: `clip`
- macOS: `pbcopy`
- Linux/BSD: `xsel -n -b -i` if it exists, or `wl-copy -f` otherwise. Note: commands should
	not fork.

<a id="textadept.clipboard.paste_command"></a>
### `textadept.clipboard.paste_command`

The command to retrieve the system clipboard's contents.

The default values are:
- Windows: `powershell get-clipboard`
- macOS: `pbpaste`
- Linux/BSD: `xsel -b -o` if it exists, or `wl-paste -n` otherwise.



<a id="textadept.editing"></a>
## The `textadept.editing` module

Editing features for Textadept.

<a id="textadept.editing.INDIC_HIGHLIGHT"></a>
### `textadept.editing.INDIC_HIGHLIGHT`

The word highlight indicator number.

<a id="textadept.editing.auto_enclose"></a>
### `textadept.editing.auto_enclose`

Auto-enclose selected text when typing a punctuation character, taking
[`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs) into account.

While a snippet is active, only auto-paired punctuation characters can auto-enclose
placeholders.

The default value is `false`.

<a id="textadept.editing.auto_indent"></a>
### `textadept.editing.auto_indent`

Match the previous line's indentation level after inserting a new line.

The default value is `true`.

<a id="textadept.editing.auto_pairs"></a>
### `textadept.editing.auto_pairs`

Map of auto-paired characters like parentheses, brackets, braces, and quotes.

The default auto-paired characters are "()", "[]", "{}", "&apos;&apos;", "&quot;&quot;",
and "``". For certain XML-like lexers, "<>" is also auto-paired.

Usage:

```lua
textadept.editing.auto_pairs['*'] = '*'
textadept.editing.auto_pairs = nil -- disable completely
```

<a id="textadept.editing.autocomplete"></a>
### `textadept.editing.autocomplete`(*name*)

Displays an autocompletion list.

Parameters:
- *name*:  The name of an autocompleter function in the [`textadept.editing.autocompleters`](#textadept.editing.autocompleters)
	table to use for providing autocompletions.

Returns: `true` if autocompletions were found; `nil` otherwise

<a id="textadept.editing.autocomplete_all_words"></a>
### `textadept.editing.autocomplete_all_words`

Autocomplete the current word using words from all open buffers.

If `true`, performance may be slow when many buffers are open.

The default value is `false`.

<a id="textadept.editing.autocompleters"></a>
### `textadept.editing.autocompleters`

Map of autocompleter names to autocompletion functions.

Names are typically lexer names and autocompletion functions typically autocomplete symbols.

Autocompletion functions must return two values:
1. The number of characters behind the caret that are used as the prefix of the entity to
	be autocompleted.
2. A table of completions to show.

If any completion contains a space character, the function should change
[`buffer.auto_c_separator`](#buffer.auto_c_separator). Also, autocompletion lists are sorted automatically by default,
but the function may change [`buffer.auto_c_order`](#buffer.auto_c_order) if it wants to control sort order.

Fields:
- `word`: Autocompletion function for words from the current buffer, or all open buffers if
 [`textadept.editing.autocomplete_all_words`](#textadept.editing.autocomplete_all_words) is `true`.
 [`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words.
 If [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`, completions are not case-sensitive.
- `snippet`: Autocompletion function for snippet trigger words.

<a id="textadept.editing.comment_string"></a>
### `textadept.editing.comment_string`

Map of lexer names to line comment strings for programming languages.

Line comment strings are either prefixes or block comment delimiters separated by a '|'
character. If no comment string exists for a given language, the lexer-supplied string is
used, if available.

Usage:

```lua
textadept.editing.comment_string.c = '/*|*/' -- instead of the default '//'
```

<a id="textadept.editing.convert_indentation"></a>
### `textadept.editing.convert_indentation`()

Converts the buffer's indentation between tabs and spaces according to [`buffer.use_tabs`](#buffer.use_tabs).

If [`buffer.use_tabs`](#buffer.use_tabs) is `true`, this will convert [`buffer.tab_width`](#buffer.tab_width) number of indenting spaces
to tabs. Otherwise, this will convert all indenting tabs to [`buffer.tab_width`](#buffer.tab_width) number of spaces.

<a id="textadept.editing.enclose"></a>
### `textadept.editing.enclose`(*left*, *right*[, *select*=false])

Encloses the selected text within delimiters, or encloses the current word if no text is
selected.

If there are multiple selections, each one will be enclosed.

Parameters:
- *left*:  String left delimiter to enclose with.
- *right*:  String right delimiter to enclose with.
- *select*:  Keep enclosed text selected.

<a id="textadept.editing.filter_through"></a>
### `textadept.editing.filter_through`(*command*)

Filters text through a shell command, replacing it (stdin) with that command's output (stdout).

The standard input sent is as follows:
1. If no text is selected, the entire buffer is used.
2. If text is selected and spans a single line, is a multiple selection, or is a rectangular
	selection, only that selected text is used.
3. If text is selected and spans multiple lines, all text on those lines is used. However,
	if the end of the selection is at the beginning of a line, that line is omitted.

Note: commands that emit stdout while reading stdin (as opposed to emitting stdout only after
stdin is closed) may hang the GTK and terminal versions of Textadept if input generates more
output than stdout can buffer. On Linux, this may be 64K. See [`proc:write()`](#proc.write).

Parameters:
- *command*:  The shell command to filter text through. May contain shell pipes ('\|').

Usage:

```lua
textadept.editing.filter_through('sort | uniq') -- sort lines and remove duplicates
```

<a id="textadept.editing.goto_line"></a>
### `textadept.editing.goto_line`([*line*])

Moves the caret to the beginning of a line, ensuring that line is visible.

Parameters:
- *line*:  Line number to go to. If `nil`, the user is prompted for one.

<a id="textadept.editing.highlight_words"></a>
### `textadept.editing.highlight_words`

Automatically highlight words.

- `textadept.editing.HIGHLIGHT_CURRENT`: Automatically highlight all instances of the
	current word.
- `textadept.editing.HIGHLIGHT_SELECTED`: Automatically highlight all instances of the
	selected word.
- `textadept.editing.HIGHLIGHT_NONE`: Do not automatically highlight words.

The default value is `textadept.editing.HIGHLIGHT_NONE`.

See also: [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.editing.join_lines"></a>
### `textadept.editing.join_lines`()

Joins the currently selected lines, or joins the current line with the line below it if no
lines are selected.

As long as any part of a line is selected, the entire line is eligible for joining.

<a id="textadept.editing.paste_reindent"></a>
### `textadept.editing.paste_reindent`()

Pastes the text from the clipboard, taking into account the buffer's indentation settings
and the indentation of the current and preceding lines.

<a id="textadept.editing.select_enclosed"></a>
### `textadept.editing.select_enclosed`([*left*[, *right*]])

Selects the range of text between delimiters surrounding the caret.

If that range is already selected, this will toggle between selecting those delimiters as well.

Parameters:
- *left*:  String left delimiter. If `nil`, it is assumed to be one of the pairs in
	[`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs) and inferred from the current position or selection.
- *right*:  String right delimiter. If `nil`, it is inferred like *left* is.

<a id="textadept.editing.select_line"></a>
### `textadept.editing.select_line`()

Selects the current line.

If text is selected  and spans multiple lines, that selection will be expanded to include
whole lines.

<a id="textadept.editing.select_paragraph"></a>
### `textadept.editing.select_paragraph`()

Selects the current paragraph.

Paragraphs are surrounded by one or more blank lines.

<a id="textadept.editing.select_word"></a>
### `textadept.editing.select_word`([*all*=false])

Selects the current word.

If that word is already selected, its next occurrence will be selected as a multiple selection.

Parameters:
- *all*:  Select all occurrences of the current word.

See also: [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.editing.strip_trailing_spaces"></a>
### `textadept.editing.strip_trailing_spaces`

Strip trailing whitespace before saving non-binary files.

The default value is `false`.

<a id="textadept.editing.toggle_comment"></a>
### `textadept.editing.toggle_comment`()

Comments or uncomments source lines based on [`textadept.editing.comment_string`](#textadept.editing.comment_string).

If no lines are selected, the current line is toggled. Otherwise, the selected lines are
toggled. As long as any part of a line is selected, that entire line is eligible for toggling.

<a id="textadept.editing.typeover_auto_paired"></a>
### `textadept.editing.typeover_auto_paired`

Type over an auto-paired complement character from [`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs).

The default value is `true`.



<a id="textadept.history"></a>
## The `textadept.history` module

Records buffer positions within Textadept views over time and allows for navigating through
that history.


This module listens for text edit events and buffer switch events. Each time an insertion
or deletion occurs, its location is recorded in the current view's location history. If the
edit is close enough to the previous record, the previous record is amended. Each time a
buffer switch occurs, the before and after locations are also recorded.

<a id="textadept.history.back"></a>
### `textadept.history.back`()

Navigates backwards through the current view's history.

<a id="textadept.history.clear"></a>
### `textadept.history.clear`()

Clears all view history.

<a id="textadept.history.forward"></a>
### `textadept.history.forward`()

Navigates forwards through the current view's history.

<a id="textadept.history.maximum_history_size"></a>
### `textadept.history.maximum_history_size`

The maximum number of history records to keep per view.

The default value is `100`.

<a id="textadept.history.minimum_line_distance"></a>
### `textadept.history.minimum_line_distance`

The minimum number of lines between distinct history records.

The default value is `3`.

<a id="textadept.history.record"></a>
### `textadept.history.record`([*filename*=buffer.filename[, *line*[, *column*[, *soft*=false]]]])

Records a buffer location in the current view's history.

Parameters:
- *filename*:  String filename, buffer type, or identifier of the buffer to store.
- *line*:  Line number to store. If `nil`, the current line is used.
- *column*:  Column number on line *line* to store. If `nil`, the current column
	is used.
- *soft*:  Skip this record when navigating backward towards it, and update
	this record when navigating away from it.



<a id="textadept.keys"></a>
## The `textadept.keys` module

Defines key bindings for Textadept.

This set of key bindings is pretty standard among other text editors, at least for basic
editing commands and movements.

These bindings are designed to be as consistent as possible between operating systems and platforms
so that users familiar with one set of bindings can intuit a given binding on another OS or
platform, minimizing the need for memorization.

In general, bindings for macOS are the same as for Windows/Linux/BSD except the "Control"
modifier key on Windows/Linux/BSD is replaced by "Command" (⌘) and the "Alt" modifier key
is replaced by "Control" (^). The only exception is for word- and paragraph-based movement
keys, which use "Alt" (⌥) instead of "Command" (⌘), as is customary on macOS.

In general, bindings for the terminal version are the same as for Windows/Linux/BSD except:
- Most "Ctrl+Shift+*key*" combinations become "M-^*key*" since most terminals recognize few,
	if any, "Ctrl+Shift" key sequences.
- Most "Ctrl+*symbol*" combinations become "M-*symbol*" since most terminals recognize only
	a few "Ctrl" combinations with symbol keys.
- All "Ctrl+Alt+*key*" combinations become "M-*key*" except for word part movement keys and
	those involving "PgDn" and "PgUp". The former are not supported and the latter use both
	modifier keys.
- "Ctrl+J" and "Ctrl+M" become "M-J" and "M-M", respectively, because control sequences with
	the 'J' and 'M' keys often involve the Enter key.

**Windows Note:** on international keyboard layouts, the "AltGr" key is equivalent to pressing
"Ctrl" and "Alt", so "AltGr+*key*" combinations may unexpectedly trigger one of Textadept's
"Ctrl+Alt+*key*" bindings. In order to avoid this, you will likely have to disable the
"Ctrl+Alt+*key*" binding in your *~/.textadept/init.lua* by setting it to `nil`.

### Key Bindings

Windows, Linux, and BSD | macOS | Terminal | Command
-|-|-|-
**File**|||
Ctrl+N | ⌘N | ^N | New file
Ctrl+O | ⌘O | ^O | Open file
None | None | None | Open recent file...
None | None | None | Reload file
Ctrl+S | ⌘S | ^S<br/>M-S<sup>a</sup> | Save file
Ctrl+Shift+S | ⌘⇧S | M-^S | Save file as..
None | None | None | Save all files
Ctrl+W | ⌘W | ^W | Close file
Ctrl+Shift+W | ⌘⇧W | M-^W | Close all files
None | None | None | Load session...
None | None | None | Save session...
Ctrl+Q | ⌘Q | ^Q<br/>M-Q<sup>a</sup> | Quit
**Edit**| | |
Ctrl+Z<br/>Alt+Bksp | ⌘Z | ^Z<sup>b</sup><br/>M-Bksp | Undo
Ctrl+Y<br/>Ctrl+Shift+Z | ⌘⇧Z<br/>⌘Y | ^Y<br/>M-^Z | Redo
Ctrl+X<br/>Shift+Del | ⌘X<br/>⇧⌦ | ^X<br/>S-Del | Cut selection/line
Ctrl+C<br/>Ctrl+Ins | ⌘C | ^C | Copy selection/line
Ctrl+V<br/>Shift+Ins | ⌘V | ^V<br/>S-Ins | Paste
Ctrl+Shift+V | ⌘⇧V | M-^V | Paste Reindent
Ctrl+Shift+D | ⌘⇧D | M-^D | Duplicate line/selection
Del | ⌦<br/> ^D | Del | Delete
Alt+Del | ^⌦ | M-Del | Delete word
Ctrl+A | ⌘A | ^A | Select all
Ctrl+Shift+A | ⌘⇧A | M-^A | Deselect
Ctrl+M | ⌘M | M-M | Match brace
Ctrl+Enter | ⌘↩ | ^Enter | Complete word
Ctrl+/ | ⌘/ | ^/<br/>M-/ | Toggle block comment
Ctrl+J | ⌘J | M-J | Join lines
Ctrl+&#124; | ⌘&#124; | ^&#124;<br/>^\ | Filter text through
Ctrl+Shift+M | ⌘⇧M | M-^M | Select between delimiters
Ctrl+D | ⌘D | ^D | Select word
Ctrl+Alt+D | ^⌘D | M-D | Deselect word
Ctrl+L | ⌘L | ^L | Select line
Ctrl+Shift+P | ⌘⇧P | M-^P | Select paragraph
Ctrl+Shift+U<sup>c</sup><br/>Ctrl+Alt+Shift+U | ⌘⇧U | M-^U | Upper case selection
Ctrl+U | ⌘U | ^U | Lower case selection
Alt+< | ^< | M-< | Enclose selection as XML tags
Alt+> | ^> | M-> | Enclose selection as single XML tag
Alt+" | ^" | M-" | Enclose selection in double quotes
Alt+' | ^' | M-' | Enclose selection in single quotes
Alt+( | ^( | M-( | Enclose selection in parentheses
Alt+[ | ^[ | None | Enclose selection in brackets
Alt+{ | ^{ | M-{ | Enclose selection in braces
Ctrl+Alt+Shift+Up | ^⌘⇧⇡ | None | Move selected lines up
Ctrl+Alt+Shift+Down | ^⌘⇧⇣ | None | Move selected lines down
Ctrl+[<br/>Alt+Left | ⌘[ | M-[<br/>M-Left | Navigate backward
Ctrl+]<br/>Alt+Right | ⌘] | M-]<br/>M-Right | Navigate forward
None | None | None | Record location
None | None | None | Clear navigation history
None | ⌘, | None | Preferences
**Search**| | |
Ctrl+F | ⌘F | ^F | Find
None | None | None | Find next
None | None | None | Find previous
None | None | None | Replace
None | None | None | Replace all
Ctrl+Alt+F | ^⌘F | M-F | Find incremental
Ctrl+Shift+F | ⌘⇧F | M-^F | Find in files
Ctrl+Alt+G | ^⌘G | M-G | Go to next file found
Ctrl+Alt+Shift+G | ^⌘⇧G | M-S-G | Go to previous file found
Ctrl+G | ⌘G | ^G | Go to line
**Tools**| | |
Ctrl+E | ⌘E | ^E | Command entry
Ctrl+P | ⌘P | ^P | Select command
Ctrl+R | ⌘R | ^R | Run
Ctrl+Shift+C | ⌘⇧C | M-^C | Compile
Ctrl+Shift+B | ⌘⇧B | M-^B | Build
Ctrl+Shift+T | ⌘⇧T | M-^T | Run tests
Ctrl+Shift+R | ⌘⇧R | M-^R | Run project
Ctrl+Shift+X | ⌘⇧X | M-^X | Stop
Ctrl+Alt+E | ^⌘E | M-E | Next Error
Ctrl+Alt+Shift+E | ^⌘⇧E | M-S-E | Previous Error
Ctrl+K | ⌘K | ^K | Toggle bookmark
None | None | None | Clear bookmarks
Ctrl+Alt+K | ^⌘K | M-K | Next bookmark
Ctrl+Alt+Shift+K | ^⌘⇧K | M-S-K | Previous bookmark
Ctrl+Shift+K | ⌘⇧K | M-^K | Go to bookmark...
Alt+, | ^, | M-, | Start/stop recording macro
Alt+. | ^. | M-. | Play recorded macro
None | None | None | Save recorded macro
None | None | None | Load saved macro
Ctrl+Alt+U | ^⌘U | M-U | Quickly open [`_USERHOME`](#_USERHOME)
Ctrl+Alt+H | ^⌘H | M-H | Quickly open [`_HOME`](#_HOME)
None | None | None | Quickly open current directory
Ctrl+Shift+O | ⌘⇧O | M-^O | Quickly open current project
None | None | None | Insert snippet...
Tab | ⇥ | Tab | Expand snippet or next placeholder
Shift+Tab | ⇧⇥ | S-Tab | Previous snippet placeholder
Esc | Esc | Esc | Cancel snippet
None | None | None | Complete trigger word
Ctrl+Shift+H | ⌘⇧H | M-S-H | Show typed keys in statusbar
None | None | None | Show style
**Buffer**| | |
Ctrl+Tab<br/>Ctrl+PgDn | ^⇥<br/>⌘⇟ | M-PgDn<br/> ^Tab<sup>d</sup> | Next buffer
Ctrl+Shift+Tab<br/>Ctrl+PgUp | ^⇧⇥<br/>⌘⇞ | M-PgUp<br/>S-^Tab<sup>d</sup> | Previous buffer
Ctrl+B | ⌘B | ^B | Switch to buffer...
None | None | None | Tab width: 2
None | None | None | Tab width: 3
None | None | None | Tab width: 4
None | None | None | Tab width: 8
Ctrl+Alt+T | ^⌘T | M-T | Toggle use tabs
None | None | None | Convert indentation
None | None | None | CR+LF EOL mode
None | None | None | LF EOL mode
None | None | None | UTF-8 encoding
None | None | None | ASCII encoding
None | None | None | CP-1252 encoding
None | None | None | UTF-16 encoding
None | None | None | Toggle Tab Bar
None | None | None | Toggle Code Folding
Ctrl+Shift+L | ⌘⇧L | M-^L | Select lexer...
**View**| | |
Ctrl+Alt+PgDn | ^⌘⇟ | M-^PgDn<br/>M-PgUp<sup>d</sup> | Next view
Ctrl+Alt+PgUp | ^⌘⇞ | M-^PgUp<br/>M-PgDn<sup>d</sup> | Previous view
Ctrl+Alt+_ | ^⌘_ | M-_ | Split view horizontal
Ctrl+Alt+&#124; | ^⌘&#124; | M-&#124; | Split view vertical
Ctrl+Alt+W | ^⌘W | M-W | Unsplit view
Ctrl+Alt+Shift+W | ^⌘⇧W | M-S-W | Unsplit all views
Ctrl+Alt++<br/>Ctrl+Alt+= | ^⌘+<br/>^⌘= | M-+<br/>M-= | Grow view
Ctrl+Alt+- | ^⌘- | M-- | Shrink view
Ctrl+} | ⌘} | M-} | Toggle current fold
None | None | None | Toggle Level 1 Folds
None | None | None | Toggle Level 2 Folds
None | None | None | Toggle Level 3 Folds
None | None | None | Collapse All Folds
None | None | None | Expand All Folds
Ctrl+\\ | ⌘\\ | M-\\ | Toggle wrap mode
None | None | N/A | Toggle indent guides
None | None | None | Toggle view whitespace
None | None | None | Toggle virtual space
Ctrl+= | ⌘= | N/A | Zoom in
Ctrl+- | ⌘- | N/A | Zoom out
Ctrl+0 | ⌘0 | N/A | Reset zoom
**Help**| | |
F1 | F1 | None | Open manual
Shift+F1 | ⇧F1 | None | Open LuaDoc
None | None | None | About
**Other**| | |
Shift+Enter | ⇧↩ | None | Start a new line below the current one
Ctrl+Shift+Enter | ⌘⇧↩ | None | Start a new line above the current one
Ctrl+Alt+Down | ^⌘⇣ | M-Down | Scroll line down
Ctrl+Alt+Up | ^⌘⇡ | M-Up | Scroll line up
Alt+PgUp | ^⇞ | N/A | Scroll page up
Alt+PgDn | ^⇟ | N/A | Scroll page down
Menu<br/> Shift+F10<sup>d</sup> | ^↩ | N/A | Show context menu
Ctrl+Alt+Shift+R *c* | ^⌘⇧R *c* | M-S-R *c* | Save macro to alphanumeric register *c*
Ctrl+Alt+R *c* | ^⌘R *c* | M-R *c* | Load and play macro from alphanumeric register *c*
**Movement**| | |
Down | ⇣<br/> ^N | Down | Line down
Shift+Down | ⇧⇣<br/>^⇧N | S-Down | Line down extend selection
Alt+Shift+Down | ^⇧⇣ | M-S-Down | Line down extend rect. selection
Ctrl+Down | ⌥⇣ | ^Down | Paragraph down
Ctrl+Shift+Down | ⌥⇧⇣ | S-^Down | Paragraph down extend selection
Up | ⇡<br/> ^P | Up | Line up
Shift+Up | ⇧⇡<br/>^⇧P | S-Up | Line up extend selection
Alt+Shift+Up | ^⇧⇡ | M-S-Up | Line up extend rect. selection
Ctrl+Up | ⌥⇡ | ^Up | Paragraph up
Ctrl+Shift+Up | ⌥⇧⇡ | S-^Up | Paragraph up extend selection
Left | ⇠<br/> ^B | Left | Char left
Shift+Left | ⇧⇠<br/>^⇧B | S-Left | Char left extend selection
Alt+Shift+Left | ^⇧⇠ | M-S-Left | Char left extend rect. selection
Ctrl+Left | ⌥⇠ | ^Left | Word left
Ctrl+Shift+Left | ⌥⇧⇠ | S-^Left | Word left extend selection
Ctrl+Alt+Left | ^⌥⇠ | None | Word part left
Ctrl+Alt+Shift+Left | ^⌥⇧⇠ | None | Word part left extend selection
Right | ⇢<br/> ^F | Right | Char right
Shift+Right | ⇧⇢<br/>^⇧F | S-Right | Char right extend selection
Alt+Shift+Right | ^⇧⇢ | M-S-Right | Char right extend rect. selection
Ctrl+Right | ⌥⇢ | ^Right | Word right
Ctrl+Shift+Right | ⌥⇧⇢ | S-^Right | Word right extend selection
Ctrl+Alt+Right | ^⌥⇢ | None | Word part right
Ctrl+Alt+Shift+Right | ^⌥⇧⇢ | None | Word part right extend selection
Home | ↖<br/>⌘⇠<br/> ^A | Home | Line start
Shift+Home | ⇧↖<br/>⌘⇧⇠<br/>^⇧A | None | Line start extend selection
Alt+Shift+Home | ^⇧↖ | None | Line start extend rect. selection
Ctrl+Home | ⌘↖ | None | Document start
Ctrl+Shift+Home | ⌘⇧↖ | None | Document start extend selection
End | ↘<br/>⌘⇢<br/> ^E | End | Line end
Shift+End | ⇧↘<br/>⌘⇧⇢<br/>^⇧E | None | Line end extend selection
Alt+Shift+End | ^⇧↘ | None | Line end extend rect. selection
Ctrl+End | ⌘↘ | None | Document end
Ctrl+Shift+End | ⌘⇧↘ | None | Document end extend selection
PgUp | ⇞ | PgUp | Page up
Shift+PgUp | ⇧⇞ | None | Page up extend selection
Alt+Shift+PgUp | ^⇧⇞ | None | Page up extend rect. selection
PgDn | ⇟ | PgDn | Page down
Shift+PgDn | ⇧⇟ | None | Page down extend selection
Alt+Shift+PgDn | ^⇧⇟ | None | Page down extend rect. selection
Ctrl+Del | ⌘⌦ | ^Del | Delete word right
Ctrl+Shift+Del | ⌘⇧⌦ | S-^Del | Delete line right
Ins | Ins | Ins | Toggle overtype
Bksp | ⌫<br/> ^H | Bksp<br/> ^H | Delete back
Ctrl+Bksp | ⌘⌫ | None | Delete word left
Ctrl+Shift+Bksp | ⌘⇧⌫ | None | Delete line left
Tab | ⇥ | Tab<br/> ^I | Insert tab or indent
Shift+Tab | ⇧⇥ | S-Tab | Dedent
None | ^K | None | Cut to line end
None | ^L | None | Center line vertically
N/A | N/A | ^^ | Mark text at the caret position
N/A | N/A | ^] | Swap caret and mark anchor
**Find Fields**|||
Left | ⇠<br/> ^B | Left<br/> ^B | Cursor left
Right | ⇢<br/> ^F | Right<br/> ^F | Cursor right
Del | ⌦ | Del | Delete forward
Bksp | ⌫ | Bksp<br/> ^H | Delete back
Ctrl+V | ⌘V | ^V | Paste
N/A | N/A | ^X | Cut all
N/A | N/A | ^Y | Copy all
N/A | N/A | ^U | Erase all
Home | ↖<br/>⌘⇠<br/> ^A | Home<br/> ^A | Home
End | ↘<br/>⌘⇢<br/> ^E | End<br/> ^E | End
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

<sup>a</sup> For use when the `-p` or `--preserve` command line option is given to the
non-Windows terminal version, since ^S and ^Q are flow control sequences.<br/>
<sup>b</sup> If you prefer ^Z to suspend, you can bind it to [`ui.suspend()`](#ui.suspend).<br/>
<sup>c</sup> Some versions of Linux intercept this for Unicode input.<br/>
<sup>d</sup> Only on Windows or the GTK version on Linux.




<a id="textadept.macros"></a>
## The `textadept.macros` module

A module for recording, playing, saving, and loading keyboard macros.

Menu commands are also recorded.
At this time, typing into multiple cursors during macro playback is not supported.

<a id="textadept.macros.load"></a>
### `textadept.macros.load`([*filename*])

Loads a macro.

Parameters:
- *filename*:  String macro file to load. If `nil`, the user is prompted for one. If
	the filename is a relative path, it will be relative to *~/.textadept/macros/*.

<a id="textadept.macros.play"></a>
### `textadept.macros.play`([*filename*])

Plays a recorded or previously loaded macro.

Parameters:
- *filename*:  String filename of a macro to load and play. If the filename is a
	relative path, it will be relative to *~/.textadept/macros/*.

<a id="textadept.macros.record"></a>
### `textadept.macros.record`()

Toggles between starting and stopping macro recording.

<a id="textadept.macros.save"></a>
### `textadept.macros.save`([*filename*])

Saves a recorded macro.

Parameters:
- *filename*:  String filename to save the recorded macro to. If `nil`, the user
	is prompted for one. If the filename is a relative path, it will be relative to
	*~/.textadept/macros/*.



<a id="textadept.menu"></a>
## The `textadept.menu` module

Defines the menus used by Textadept.

Menus are simply tables of menu items and submenus. A menu item itself is a two-element table: a
menu label and a menu command to run. Submenus have `title` keys assigned to string label text.

Menus may be edited in place using normal Lua table operations. You can index a menu with
either an index, a string label name, or a string path with submenus separated by '/'. When
indexing with strings, labels are localized as needed, so you can use either English labels
or their localized equivalent.

```lua
-- Append to the right-click context menu.
table.insert(textadept.menu.context_menu, {'Label', function() ... end})
-- Append an encoding in the "Buffer > Encoding" menu.
table.insert(textadept.menu.menubar['Buffer/Encoding'],
	{'UTF-32', function() buffer:set_encoding('UTF-32') end})
-- Change the "Search > Find" command.
textadept.menu.menubar['Search/Find'][2] = function() ... end
```

<a id="textadept.menu.context_menu"></a>
### `textadept.menu.context_menu`

The default right-click context menu.

Usage:

```lua
table.insert(textadept.menu.context_menu, {'Label', function() ... end})
```

<a id="textadept.menu.menubar"></a>
### `textadept.menu.menubar`

The default main menubar.

Usage:

```lua
table.insert(textadept.menu.menubar['Tools'], {...}) -- Append to the Tools menu
textadept.menu.menubar['File/New'] --> table for "File > New"
textadept.menu.menubar['File/New'][2] = function() ... end -- change "File > New" command
```

<a id="textadept.menu.select_command"></a>
### `textadept.menu.select_command`()

Prompts the user to select a menu command to run.

<a id="textadept.menu.tab_context_menu"></a>
### `textadept.menu.tab_context_menu`

The default tabbar context menu.



<a id="textadept.run"></a>
## The `textadept.run` module

Execute compile, run, build, test, and project shell commands with Textadept.

The editor prompts you with/for shell commands to run, prints output in real-time, and marks
any warning and error messages it recognizes.
Textadept remembers commands on a per-filename and per-directory basis where applicable.

<a id="textadept.run.INDIC_ERROR"></a>
### `textadept.run.INDIC_ERROR`

The run or compile error indicator number.

<a id="textadept.run.INDIC_WARNING"></a>
### `textadept.run.INDIC_WARNING`

The run or compile warning indicator number.

<a id="textadept.run.MARK_ERROR"></a>
### `textadept.run.MARK_ERROR`

The run or compile error marker number.

<a id="textadept.run.MARK_WARNING"></a>
### `textadept.run.MARK_WARNING`

The run or compile warning marker number.

<a id="textadept.run.build"></a>
### `textadept.run.build`([*dir*])

Prompts the user with the command entry to build a project using its shell command from the
[`textadept.run.build_commands`](#textadept.run.build_commands) table.

Parameters:
- *dir*:  String path to the project to build. The default value is the current project,
	which is determined by either the buffer's filename or the current working directory.

See also: [`events.BUILD_OUTPUT`](#events.BUILD_OUTPUT)

<a id="textadept.run.build_commands"></a>
### `textadept.run.build_commands`

Map of project root paths and "makefiles" to their associated "build" shell command line
strings or functions that return such strings.

Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

Usage:

```lua
textadept.run.build_commands['CMakeLists.txt'] = 'cmake --build build'
textadept.run.build_commands['/path/to/project'] = 'make -C src'
```

<a id="textadept.run.compile"></a>
### `textadept.run.compile`([*filename*=buffer.filename])

Prompts the user with the command entry to compile a file using an appropriate shell command
from the [`textadept.run.compile_commands`](#textadept.run.compile_commands) table.

The shell command is determined from the file's filename, extension, or language, in that order.

Parameters:
- *filename*:  String path of the file to compile.

See also: [`events.COMPILE_OUTPUT`](#events.COMPILE_OUTPUT)

<a id="textadept.run.compile_commands"></a>
### `textadept.run.compile_commands`

Map of filenames, file extensions, and lexer names to their associated "compile" shell
command line strings or functions that return such strings.

Command line strings may have the following macros:
- `%f`: The file's name, including its extension.
- `%e`: The file's name, excluding its extension.
- `%d`: The file's directory path.
- `%p`: The file's full path.

Functions may also return a working directory and process environment table to operate in. By
default, the working directory is the current file's parent directory and the environment
is Textadept's environment.

Usage:

```lua
textadept.run.compile_commands.c = 'clang -o "%e" "%f"'
```

<a id="textadept.run.goto_error"></a>
### `textadept.run.goto_error`(*location*)

Jumps to the source of a recognized compile/run/build/test warning or error in the output
buffer, displaying an annotation with the warning or error message if possible.

Parameters:
- *location*:  When `true`, jumps to the next recognized warning/error. When `false`,
	jumps to the previous one. When a line number, jumps to it's source.

<a id="textadept.run.run"></a>
### `textadept.run.run`([*filename*=buffer.filename])

Prompts the user with the command entry to run a file using an appropriate shell command
from the [`textadept.run.run_commands`](#textadept.run.run_commands) table.

The shell command is determined from the file's filename, extension, or language, in that order.

Parameters:
- *filename*:  String path of the file to run.

See also: [`events.RUN_OUTPUT`](#events.RUN_OUTPUT)

<a id="textadept.run.run_commands"></a>
### `textadept.run.run_commands`

Map of filenames, file extensions, and lexer names to their associated "run" shell command
line strings or functions that return strings.

Command line strings may have the following macros:
- `%f`: The file's name, including its extension.
- `%e`: The file's name, excluding its extension.
- `%d`: The file's directory path.
- `%p`: The file's full path.

Functions may also return a working directory and process environment table to operate in. By
default, the working directory is the current file's parent directory and the environment
is Textadept's environment.

Usage:

```lua
textadept.run.run_commands.lua = 'lua5.1 "%f"'
```

<a id="textadept.run.run_in_background"></a>
### `textadept.run.run_in_background`

Run shell commands silently in the background.

The default value is `false`.

<a id="textadept.run.run_project"></a>
### `textadept.run.run_project`([*dir*[, *cmd*]])

Prompts the user with the command entry to run a shell command for a project.

Parameters:
- *dir*:  String path to the project to run a command for. The default value is the
	current project, which is determined by either the buffer's filename or the current
	working directory.
- *cmd*:  String command to run. If given, the command entry initially shows this
	command. The default value comes from [`textadept.run.run_project_commands`](#textadept.run.run_project_commands) and *dir*.

See also: [`events.RUN_OUTPUT`](#events.RUN_OUTPUT)

<a id="textadept.run.run_project_commands"></a>
### `textadept.run.run_project_commands`

Map of project root paths to their associated "run" shell command line strings or functions
that return such strings.

Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

Usage:

```lua
textadept.run.run_project_commands[_HOME] = function()
	local env = {TEXTADEPT_HOME = _HOME}
	for setting in os.spawn('env'):read('a'):gmatch('[^\n]+') do env[#env + 1] = setting end
	return _HOME .. '/build/textadept -f -n', '/tmp', env -- run test instance of Textadept
end
```

<a id="textadept.run.run_without_prompt"></a>
### `textadept.run.run_without_prompt`

Run shell commands without prompting.

The default value is `false`.

<a id="textadept.run.stop"></a>
### `textadept.run.stop`()

Stops the currently running process, if any.

If there is more than one running process, the user is prompted to select the process to stop.
Processes in the list are sorted from longest lived at the top to shortest lived on the bottom.

<a id="textadept.run.test"></a>
### `textadept.run.test`([*dir*])

Prompts the user with the command entry to run tests for a project using its shell command
from the [`textadept.run.test_commands`](#textadept.run.test_commands) table.

Parameters:
- *dir*:  String path to the project to run tests for. The default value is the
	current project, which is determined by either the buffer's filename or the current
	working directory.

See also: [`events.TEST_OUTPUT`](#events.TEST_OUTPUT)

<a id="textadept.run.test_commands"></a>
### `textadept.run.test_commands`

Map of project root paths to their associated "test" shell command line strings or functions
that return such strings.

Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

Usage:

```lua
textadept.run.test_commands['/path/to/project'] = 'pytest'
```



<a id="textadept.session"></a>
## The `textadept.session` module

Session support for Textadept.

<a id="textadept.session.load"></a>
### `textadept.session.load`([*filename*])

Loads a session file.

Textadept restores split views, opened buffers, cursor information, recent files, and bookmarks.

Parameters:
- *filename*:  String absolute path to the session file to load. If `nil`, the user
	is prompted for one.

See also: [`events.SESSION_LOAD`](#events.SESSION_LOAD)

<a id="textadept.session.save"></a>
### `textadept.session.save`(*filename*)

Saves the session to a file.

Textadept saves split views, opened buffers, cursor information, recent files, and bookmarks.

The editor will save the current session to that file again before quitting unless
[`textadept.session.save_on_quit`](#textadept.session.save_on_quit) is `false`.

Parameters:
- *filename*: Optional absolute path to the session file to save. If `nil`, the user
	is prompted for one.

See also: [`events.SESSION_SAVE`](#events.SESSION_SAVE)

<a id="textadept.session.save_on_quit"></a>
### `textadept.session.save_on_quit`

Save the session when quitting.

The default value is `true` unless the user passed the command line switch `-n` or `--nosession`
to Textadept.



<a id="textadept.snippets"></a>
## The `textadept.snippets` module

Snippets for Textadept.


### Snippets Overview

Define snippets in the global [`snippets`](#snippets) table in key-value pairs. Each pair consists of
either:
- A string trigger word and its snippet text.
- A string lexer name with a table of trigger words and snippet texts.

When searching for a snippet to insert based on a trigger word, Textadept considers snippets
in the current lexer to have priority, followed by the ones in the global table. This means
if there are two snippets with the same trigger word, Textadept inserts the one specific to
the current lexer, not the global one.

### Snippet Syntax

Snippets may contain any combination of plain-text sequences, variables, interpolated code,
and placeholders.

#### Plain Text

Plain text consists of any character except '$' and '\`'. Those two characters are reserved for
variables, interpolated code, and placeholders. In order to use either of those two characters
literally, prefix them with '\\' (e.g. "\\$" inserts a literal '$').

#### Variables

Variables are defined in the [`textadept.snippets.variables`](#textadept.snippets.variables) table. Textadept expands
them in place using the '$' prefix (e.g. `$TM_SELECTED_TEXT` references the currently
selected text). You can provide default values for empty or undefined variables using the
"${*variable*:*default*}" syntax (e.g. `${TM_SELECTED_TEXT:no text selected}`). The values of
variables may be transformed in-place using the "${*variable*/*regex*/*format*/*options*}"
syntax (e.g. `${TM_SELECTED_TEXT/.+/"$0"/}` quotes the selected text). The section on
placeholder transforms below describes this syntax in more detail.

#### Interpolated Shell Code

Snippets can execute shell code enclosed within '\`' characters, and insert any standard output
(stdout) emitted by that code. Textadept omits a trailing newline if it exists. For example,
the following snippet evaluates (on macOS and Linux) the currently selected arithmetic
expression and replaces it with the result:

```lua
snippets.eval = '`echo $(( $TM_SELECTED_TEXT ))`'
```

#### Interpolated Lua Code

Snippets can also execute Lua code enclosed within "\`\`\`" sequences, and insert any string
results returned by that code. For example, the following snippet inserts the current date
and time:

```lua
snippets.date = '```os.date()```'
```

Lua code is executed within Textadept's Lua environment, with the addition of snippet
variables available as global variables (e.g. `TM_SELECTED_TEXT` exists as a global).

#### Placeholders

The true power of snippets lies with placeholders. Using placeholders, you can insert a text
template and tab through placeholders one at a time, filling them in. Placeholders may be
linked to one another, either mirroring text or transforming it in-place.

##### Tab Stops

The simplest kind of placeholder is called a tab stop, and its syntax is either "$*n*" or
"${*n*}", where *n* is an integer. When a snippet is inserted, the caret is moved to the
"$1" placeholder. Pressing the `Tab` key jumps to the next placeholder, "$2", and so on. When
there are no more placeholders to jump to, the caret moves to either the "$0" placeholder if
it exists, or it moves to the end of the snippet. For example, the following snippet inserts
a 3-element vector, with tab stops at each element:

```lua
snippets.vec = '[$1, $2, $3]'
```

##### Default Values

Placeholders may have default values using the "${*n*:*default*}" syntax. For example,
the following snippet creates a numeric "for" loop in Lua:

```lua
snippets.lua.fori = [[
for ${1:i} = ${2:1}, $3 do
	$0
end]]
```

Multiline snippets should be indented with tabs. Textadept will apply the buffer's current
indentation settings to the snippet upon insertion.

Placeholders may be nested inside one another. For example, the following snippet inserts
a function call with a mandatory first argument, but an optional second one:

```lua
snippets.call = '${1:func}($2${3:, $4})'
```

Upon arriving at the third placeholder, backspacing and pressing `Tab` completes the snippet
with a single argument. On the other hand, pressing `Tab` again at the third placeholder
jumps to the second argument for input.

Note that plain text inside default values may not contain a '}' character either, as it is
reserved to indicate the end of the placeholder. Use "\\}" to represent a literal '}'.

##### Mirrors

Multiple placeholders can share the same numeric index. When this happens, Textadept visits
the one with a default value if it exists. Otherwise, the editor visits the first one it
finds. As you type text into a placeholder, any other placeholders with the same index mirror
the typed text. For example, the following snippet inserts beginning and ending HTML/XML
tags with the same name:

```lua
snippets.tag = '<${1:div}>$0</$1>'
```

The end tag mirrors whatever name you type into the start tag.

##### Transforms

Sometimes mirrors are not quite good enough. For example, perhaps the mirror's content needs to
deviate slightly from its linked placeholder, like capitalizing the first letter. Or perhaps
the mirror's contents should depend on the presence (or absence) of text in its linked
placeholder. This is where placeholder transforms come in handy.

Transforms use the "${*n*/*regex*/*format*/*options*}" syntax, where *regex* is a [regular
expression][] (regex) to match against the content of placeholder *n*, *format* is a formatted
replacement for matched content, and *options* are regex options to use when matching. *format*
may contain any of the following:
- Plain text.
- "$*m*" and "${*m*}" sequences, which represent the content of the *m*th capture (*m*=0 is
	the entire match for this and all subsequent sequences).
- "${*m*:/upcase}", "${*m*:/downcase}", and "${*m*:/capitalize}" sequences, which
	represent the uppercase, lowercase, and capitalized forms, respectively, of the
	content of the *m*th capture. You can define your own transformation function in
	[`textadept.snippets.transform_methods`](#textadept.snippets.transform_methods).
- A "${*m*:?*if*:*else*}" sequence, which inserts *if* if the content of capture *m* is
	non-empty. Otherwise, *else* is used.
- A "${*m*:+*if*}" sequence, which inserts *if* if the content of capture *m* is
	non-empty. Otherwise nothing is inserted.
- "${*m*:*default*}" and "${*m*:-*default*}" sequences, which insert *default* if the content
	of capture *m* is empty. Otherwise, capture *m* is mirrored.

*options* may include any of the following letters:
- g: Replace all instances of matched text, not just the first one.

For example, the following snippet defines an attribute along with its getter and setter functions:

```lua
snippets.attr = [[
	${1:int} ${2:name};

	${1} get${2/./${0:/upcase}/}() { return $2; }
	void set${2/./${0:/upcase}/}(${1} ${3:value}) { $2 = $3; }
]]
```

Note that the '/' and '}' characters are reserved in certain places within a placeholder
transform. Use "\\/" and "\\}", respectively, to represent literal versions of those characters
where necessary.

[regular expression]: manual.html#regex-and-lua-pattern-syntax

##### Multiple Choices

Placeholders may define a list of options for the user to choose from using the
"${*n*|*items*|}" syntax, where *items* is a comma-separated list of options
(e.g. `${1|foo,bar,baz|}`).

Items may not contain a '\|' character, as it is reserved to indicate the end of the choice list.
Use "\\|" to represent a literal '\|'.

### Migrating Legacy Snippets

Legacy snippets used the following syntax:
- "%*n*" for tab stops and mirrors.
- "%*n*(*default*)" for default placeholders.
- "%*n*<*Lua code*>" for Lua transforms, where *n* is optional.
- "%*n*[*Shell code*]" for Shell transforms, where *n* is optional.
- "%*n*{*items*}" for multiple choice placeholders.

You can migrate your snippets using the following steps:

1. Substitute '%' with '$' in tab stops and mirrors.
2. Substitute "%*n*(*default*)" default placeholders with "${*n*:*default*}". The following
	regex and replacement should work for non-nested placeholders: `%(\d+)\(([^)]+)\)` and
	`${\1:\2}`.
3. Replace *n*-based Lua and Shell transforms with [placeholder transforms](#transforms). You
	can add your own transform function to [`textadept.snippets.transform_methods`](#textadept.snippets.transform_methods) if you
	need to.
4. Replace bare Lua and Shell transforms with interpolated Lua and shell code.
5. Substitute "%*n*{*items*}" choice placeholders with "${*n*\|*items*\|}".


<a id="textadept.snippets.INDIC_PLACEHOLDER"></a>
### `textadept.snippets.INDIC_PLACEHOLDER`

The snippet placeholder indicator number.

<a id="textadept.snippets.active"></a>
### `textadept.snippets.active`

Whether or not a snippet is active.

<a id="textadept.snippets.cancel"></a>
### `textadept.snippets.cancel`()

Cancels the active snippet, removing all inserted text.

Returns: `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.insert"></a>
### `textadept.snippets.insert`([*text*])

Inserts a snippet or, if a snippet is already active, goes to that snippet's next placeholder.

Parameters:
- *text*:  String snippet text to insert. If `nil`, attempts to insert a new snippet
	based on the trigger (the word behind caret) and the current lexer.

Returns: `false` if no action was taken; `nil` otherwise.

See also: [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.snippets.paths"></a>
### `textadept.snippets.paths`

Table of directory paths to look for snippet files in.

Filenames are of the form *lexer.trigger.ext* or *trigger.ext* (*.ext* is an optional,
arbitrary file extension). If the global [`snippets`](#snippets) table does not contain a snippet for
a given trigger, this table is consulted for a matching filename, and the contents of that
file is inserted as a snippet.

Note: If a directory has multiple snippets with the same trigger, the snippet chosen for
insertion is not defined and may not be constant.

<a id="textadept.snippets.previous"></a>
### `textadept.snippets.previous`()

Jumps back to the previous snippet placeholder, reverting any changes from the current one.

Returns: `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.select"></a>
### `textadept.snippets.select`()

Prompts the user to select a snippet to insert from a list of global and language-specific
snippets.

<a id="textadept.snippets.transform_methods"></a>
### `textadept.snippets.transform_methods`

Map of format method names to their functions for text captured in placeholder transforms.

Fields:
- `upcase`:  Uppercases the captured text.
- `downcase`:  Lowercases the captured text.
- `capitalize`:  Capitalizes the captured text.

<a id="textadept.snippets.variables"></a>
### `textadept.snippets.variables`

Map of snippet variable names to string values or functions that return string values.

Each time a snippet is inserted, this map is used to set its variables.

Fields:
- `TM_SELECTED_TEXT`:  The currently selected text, if any.
- `TM_CURRENT_LINE`:  The contents of the current line.
- `TM_CURRENT_WORD`:  The word under the caret, if any.
- `TM_LINE_NUMBER`:  The current line number.
- `TM_LINE_INDEX`:  The current line number, counting from 0.
- `TM_FILENAME`:  The buffer's filename, excluding path, if any.
- `TM_FILENAME_BASE`:  The buffer's bare filename, without extension.
- `TM_DIRECTORY`:  The buffer's parent directory path.
- `TM_FILEPATH`:  The buffer's filename, including path.



<a id="ui"></a>
## The `ui` module

Utilities for interacting with Textadept's user interface.

<a id="ui.SHOW_ALL_TABS"></a>
### `ui.SHOW_ALL_TABS`

Option for [`ui.tabs`](#ui.tabs) that always shows the tab bar, even if only one buffer is open.

<a id="ui.buffer_list_zorder"></a>
### `ui.buffer_list_zorder`

List buffers by their z-order (most recently viewed to least recently viewed) in the switcher
dialog, instead of listing buffers in their left-to-right tab order.

The default value is `true`.

<a id="ui.buffer_statusbar_text"></a>
### `ui.buffer_statusbar_text`

The text displayed in the buffer statusbar.
(Write-only)

<a id="ui.context_menu"></a>
### `ui.context_menu`

The buffer's context menu, a [`ui.menu()`](#ui.menu).

This is a low-level field. You probably want to use the higher-level
[`textadept.menu.context_menu`](#textadept.menu.context_menu).

<a id="ui.get_clipboard_text"></a>
### `ui.get_clipboard_text`([*internal*=false])

Returns the text on the clipboard.

The terminal version relies on [`textadept.clipboard.paste_command`](#textadept.clipboard.paste_command) to retrieve the contents
of the system clipboard, falling back on its own internal clipboard if necessary.

Parameters:
- *internal*:  Get the terminal version's internal clipboard text.

See also: [`buffer.copy_text`](#buffer.copy_text)

<a id="ui.get_split_table"></a>
### `ui.get_split_table`()

Returns a split table that contains Textadept's current split view structure.

This is primarily used in session saving.

Returns:  table of split views. Each split view entry is a table with 4 fields: `1`, `2`,
	`vertical`, and `size`. `1` and `2` have values of either nested split view entries or
	the views themselves; `vertical` is a flag that indicates if the split is vertical or
	not; and `size` is the integer position of the split resizer.

<a id="ui.goto_file"></a>
### `ui.goto_file`(*filename*[, *split*=false[, *preferred_view*[, *sloppy*=false]]])

Go to a particular file, opening it if necessary.

Parameters:
- *filename*:  String filename of the buffer to go to.
- *split*:  Open the buffer in a split view if there is only one view and it is
	not showing *filename*.
- *preferred_view*:  View to open the buffer in if it is not visible in any other
	view. The default value is a view other than the current one.
- *sloppy*:  Matches *filename* to only the last part of [`buffer.filename`](#buffer.filename)
	This is useful for compile/run/test/build commands, which output relative filenames
	and paths instead of full ones, and it is likely that the file in question is already open.

<a id="ui.goto_view"></a>
### `ui.goto_view`(*view*)

Switches focus to another view.

Parameters:
- *view*:  View to switch to, or index of a relative view to switch to (typically 1 or -1).

Usage:

```lua
ui.goto_view(_VIEWS[1]) -- switch to first view
ui.goto_view(-1) -- switch to the view before the current one
```

See also: [`events.VIEW_BEFORE_SWITCH`](#events.VIEW_BEFORE_SWITCH), [`events.VIEW_AFTER_SWITCH`](#events.VIEW_AFTER_SWITCH)

<a id="ui.maximized"></a>
### `ui.maximized`

Whether or not Textadept's window is maximized.

This field is always `false` in the terminal version.

<a id="ui.menu"></a>
### `ui.menu`(*menu_table*)

Low-level function for creating a menu.

You probably want to use the higher-level [`textadept.menu.menubar`](#textadept.menu.menubar),
[`textadept.menu.context_menu`](#textadept.menu.context_menu), or [`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu) tables.

Parameters:
- *menu_table*:  Ordered list of tables with a string menu item, integer menu ID, and
	optional keycode and modifier mask. The latter two are used to display key shortcuts in
	the menu. '&' characters are treated as a menu mnemonics in Qt ('_' is the equivalent
	in GTK). If the menu item is empty, a menu separator item is created. Submenus are just
	nested menu-structure tables. Their title text is defined with a `title` key.

Returns: menu userdata

Usage:

```lua
ui.menu{ {'_New', 1}, {'_Open', 2}, {''}, {'&Quit', 4} }
ui.menu{ {'_New', 1, string.byte('n'), view.MOD_CTRL} } -- 'Ctrl+N'
```

<a id="ui.menubar"></a>
### `ui.menubar`

A table of menus defining a menubar.
(Write-only).
This is a low-level field. You probably want to use the higher-level [`textadept.menu.menubar`](#textadept.menu.menubar).

<a id="ui.output"></a>
### `ui.output`(...)

Prints to the output buffer, creating it if necessary.

The output buffer attempts to understand the error messages and warnings produced by various
tools.

If the output buffer is already open in a view, output is printed to that view. Otherwise
the view is split (unless [`ui.tabs`](#ui.tabs) is `true`) and the output buffer is displayed before
being printed to.

Parameters:
- *...*:  Strings to print.

Returns: the output buffer

<a id="ui.output_silent"></a>
### `ui.output_silent`(...)

Prints to the output buffer (creating it if necessary) without switching to it.

Parameters:
- *...*:  Strings to print.

Returns: the output buffer

<a id="ui.popup_menu"></a>
### `ui.popup_menu`(*menu*)

Displays a popup menu, typically the right-click context menu.

Parameters:
- *menu*:  Menu to display.

Usage:

```lua
ui.popup_menu(ui.context_menu)
```

See also: [`ui.context_menu`](#ui.context_menu), [`ui.menu`](#ui.menu)

<a id="ui.print"></a>
### `ui.print`(...)

Prints to the output buffer (creating it if necessary), along with a trailing newline.

This function is primarily for use in the Lua command entry in place of Lua's `print()`
function.

Parameters:
- *...*:  Values to print. Lua's `tostring()` function is called for each value. They will
	be printed as tab-separated values.

<a id="ui.print_silent_to"></a>
### `ui.print_silent_to`(*type*, *message*)

Prints a message to a typed buffer (creating it if necessary) without switching to it.

Parameters:
- *type*:  String type of print buffer.
- *message*:  String message to print.

Returns: the typed buffer printed to

<a id="ui.print_to"></a>
### `ui.print_to`(*type*, *message*)

Prints a message along with a trailing newline to a typed buffer, creating it if necessary.

If the print buffer is already open in a view, the message is printed to that view. Otherwise
the view is split (unless [`ui.tabs`](#ui.tabs) is `true`) and the print buffer is displayed before
being printed to.

Parameters:
- *type*:  String type of print buffer.
- *message*:  String message to print.

Returns: the typed buffer printed to

Usage:

```lua
ui.print_to('[Typed Buffer]', message)
```

<a id="ui.size"></a>
### `ui.size`

A table that contains the width and height pixel values of Textadept's window.

Usage:

```lua
ui.size = {1000, 625} -- resize window
```

<a id="ui.statusbar_text"></a>
### `ui.statusbar_text`

The text displayed in the statusbar.
(Write-only)

<a id="ui.suspend"></a>
### `ui.suspend`()

Suspends Textadept.

This only works in the terminal version. By default, Textadept ignores ^Z suspend signals from
the terminal.

Usage:

```lua
keys['ctrl+z'] = ui.suspend
```

See also: [`events.SUSPEND`](#events.SUSPEND), [`events.RESUME`](#events.RESUME)

<a id="ui.switch_buffer"></a>
### `ui.switch_buffer`()

Prompts the user to select a buffer to switch to.

Buffers are listed in their left-to-right tab order unless [`ui.buffer_list_zorder`](#ui.buffer_list_zorder) is `true`, in
which case buffers are listed by their z-order (most recently viewed to least recently viewed).

Buffers in the same project as the current buffer are shown with relative paths.

<a id="ui.tab_context_menu"></a>
### `ui.tab_context_menu`

The context menu for the buffer's tab, a [`ui.menu()`](#ui.menu).

This is a low-level field. You probably want to use the higher-level
[`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu).

<a id="ui.tabs"></a>
### `ui.tabs`

Display the tab bar when multiple buffers are open.

The default value is `true` in the GUI version, and `false` in the terminal version.
A third option, [`ui.SHOW_ALL_TABS`](#ui.SHOW_ALL_TABS) may be used to always show the tab bar, even if only one
buffer is open.

<a id="ui.title"></a>
### `ui.title`

The title text of Textadept's window.
(Write-only)

<a id="ui.update"></a>
### `ui.update`()

Processes pending UI events, including reading from spawned processes.

This function is primarily used in Textadept's own unit tests.



<a id="ui.command_entry"></a>
## The `ui.command_entry` module

Textadept's Command Entry.

It supports multiple modes that each have their own functionality (such as running Lua code
and filtering text through shell commands) and history.
In addition to the API listed below, the command entry also shares the same API as [`buffer`](#buffer)
and [`view`](#view).

<a id="ui.command_entry.active"></a>
### `ui.command_entry.active`

Whether or not the command entry is active.

<a id="ui.command_entry.editing_keys"></a>
### `ui.command_entry.editing_keys`

A Lua metatable that contains a set of typical key bindings for text entries.

It is automatically added to keys passed to [`ui.command_entry.run()`](#ui.command_entry.run) unless those keys
already have their own metatable.

<a id="ui.command_entry.focus"></a>
### `ui.command_entry.focus`()

Opens the command entry.
This is a low-level function. You probably want to use the higher-level
[`ui.command_entry.run()`](#ui.command_entry.run).

<a id="ui.command_entry.height"></a>
### `ui.command_entry.height`

The height in pixels of the command entry.

<a id="ui.command_entry.label"></a>
### `ui.command_entry.label`

The text of the command entry label.
(Write-only)

<a id="ui.command_entry.run"></a>
### `ui.command_entry.run`(*label*, *f*[, *keys*][, *lang*='text'[, *initial_text*[, ...]]])

Opens the command entry.

This function may be called with no arguments to open the Lua command entry.

Parameters:
- *label*:  String label to display in front of the entry.
- *f*:  Function to call upon pressing `Enter`. It should accept at a minimum the command
	entry text as an argument.
- *keys*:  Table of key bindings to respond to. This is in addition to the basic
	editing and movement keys defined in [`ui.command_entry.editing_keys`](#ui.command_entry.editing_keys). `Esc` and `Enter`
	are automatically defined to cancel and finish the command entry, respectively. The
	command entry does not respond to Textadept's default key bindings.
- *lang*:  String lexer name to use for syntax highlighting command entry text.
- *initial_text*:  String text to initially show. The default value comes from
	the command history for *f*.
- *...*:  Additional arguments to pass to *f*.

Usage:

```lua
ui.command_entry.run('echo:', ui.print)
ui.command_entry.run('$', os.spawn, 'bash', 'env', ui.print) -- spawn a process
```



<a id="ui.dialogs"></a>
## The `ui.dialogs` module

Provides a set of interactive dialog prompts for user input.

<a id="ui.dialogs.input"></a>
### `ui.dialogs.input`(*options*)

Prompts the user for string input.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `text`: String initial input.
	- `button1`: String label for the primary (accept) button. The default value is `_L['OK']`.
	- `button2`: String label for the secondary (reject) button. The default value is
		`_L['Cancel']`.
	- `button3`: String label for the tertiary button. This option requires `button2`
		to be set. It is not available in the Qt version.
	- `return_button`: Also return the index of the selected button.

Returns: string input text[, selected button index]; or `nil` if the user canceled the dialog

Usage:

```lua
ui.dialogs.input{title = 'Go to line number:', text = '1'}
```

<a id="ui.dialogs.list"></a>
### `ui.dialogs.list`(*options*)

Prompts the user to select an item from a list.

Text typed into the dialog filters the list items. Spaces are treated as wildcards.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `text`: String initial input text.
	- `columns`: Table of string column names for list row headers. If this field is omitted,
		a single column is used.
	- `items`: Table of string items to show in the list. Each item is placed in the next
		available column of the current row. If there is only one column, each item is
		on its own row.
	- `button1`: String label of the primary (accept) button. The default value is `_L['OK']`.
	- `button2`: String label of the secondary (reject) button. The default value is
		`_L['Cancel']`.
	- `button3`: String label of the tertiary button. This option requires `button2` to be set.
	- `multiple`: Allow the user to select multiple items. The terminal version does not
		support this option.
	- `search_column`: Column number to filter the input text against. The default value is `1`.
	- `select`: Row number to initially select. The default value is `1`.
	- `return_button`: Also return the index of the selected button.

Returns: selected item or table of selected items[, selected button index]; or `nil` if the
	user canceled the dialog

Usage:

```lua
ui.dialogs.list{title = 'Title', columns = {'Foo', 'Bar'}, items = {'a', 'b', 'c', 'd'}}
```

<a id="ui.dialogs.message"></a>
### `ui.dialogs.message`(*options*)

Shows a message box.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `text`: String main message.
	- `icon`: String icon name, according to the Free Desktop Icon Naming
		Specification. Examples are "dialog-error", "dialog-information",
		"dialog-question", and "dialog-warning".
	- `button1`: String label for the primary (accept) button. The default value is `_L['OK']`.
	- `button2`: String label for the secondary (reject) button.
	- `button3`: String label for the tertiary button. This option requires `button2` to be set.

Returns: the selected button's index, or `nil` if the user canceled the dialog

Usage:

```lua
ui.dialogs.message{
	title = 'EOL Mode', text = 'Which EOL?', icon = 'dialog-question',
	button1 = 'CRLF', button2 = 'CR', button3 = 'LF'
}
```

<a id="ui.dialogs.open"></a>
### `ui.dialogs.open`(*options*)

Prompts the user to select a file from the filesystem.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `dir`: String directory to initially show.
	- `file`: String file to initially select. This option requires `dir` to be set.
	- `multiple`: Allow the user to select multiple files. The terminal version does not
		support this option.
	- `only_dirs`: Only allow the user to select directories.

Returns: string filename or table of filenames; or `nil` if the user canceled the dialog

Usage:

```lua
ui.dialogs.open{title = 'Open File', dir = _HOME, multiple = true}
```

<a id="ui.dialogs.progress"></a>
### `ui.dialogs.progress`(*options*)

Displays a progress dialog while doing work.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `text`: String initial progressbar display text (GUI version only).
	- `work`: Function repeatedly called to do work and provide progress updates. This function
		is called without arguments and must return either `nil`, which indicates work
		is complete, or a progress percentage number in the range 0-100 and optionally
		a string to display (GUI version only). If progress is indeterminate, the
		percentage can be less than zero.

Returns: `nil` if all work completed, or `true` if the user clicked "Stop"

Usage:

```lua
ui.dialogs.progress{work = function()
	if not work() then return nil end
	return percent, status
end}
```

<a id="ui.dialogs.save"></a>
### `ui.dialogs.save`(*options*)

Prompts the user to select a file to save to.

Parameters:
- *options*:  Table of key-value option pairs for the dialog.

	- `title`: String title.
	- `dir`: String directory to initially show.
	- `file`: String filename to initially select. This option requires `dir` to be set.

Returns: string filename, or `nil` if the user canceled the dialog



<a id="ui.find"></a>
## The `ui.find` module

Textadept's Find & Replace pane.

<a id="ui.find.INDIC_FIND"></a>
### `ui.find.INDIC_FIND`

The find results highlight indicator number.

<a id="ui.find.active"></a>
### `ui.find.active`

Whether or not the Find & Replace pane is active.

<a id="ui.find.entry_font"></a>
### `ui.find.entry_font`

The font to use in the "Find" and "Replace" entries in "name size" format.
(Write-only)
The default value is system-dependent.

<a id="ui.find.find_entry_text"></a>
### `ui.find.find_entry_text`

The text in the "Find" entry.

<a id="ui.find.find_in_files_filters"></a>
### `ui.find.find_in_files_filters`

Map of directory paths to filters used when finding in files.


A filter consists of glob patterns that match file and directory paths to include or
exclude. Exclusive patterns begin with a '!'. If no inclusive patterns are given, any path
is initially considered. As a convenience, '/' also matches the Windows directory separator.

This table is updated when the user manually specifies a filter in the "Filter" entry during
an "In files" search.

<a id="ui.find.find_label_text"></a>
### `ui.find.find_label_text`

The text of the "Find" label.
(Write-only)
This is primarily used for localization.

<a id="ui.find.find_next"></a>
### `ui.find.find_next`()

Mimics pressing the "Find Next" button.

See also: [`events.FIND`](#events.FIND)

<a id="ui.find.find_next_button_text"></a>
### `ui.find.find_next_button_text`

The text of the "Find Next" button.
(Write-only)
This is primarily used for localization.

<a id="ui.find.find_prev"></a>
### `ui.find.find_prev`()

Mimics pressing the "Find Prev" button.

See also: [`events.FIND`](#events.FIND)

<a id="ui.find.find_prev_button_text"></a>
### `ui.find.find_prev_button_text`

The text of the "Find Prev" button.
(Write-only)
This is primarily used for localization.

<a id="ui.find.focus"></a>
### `ui.find.focus`([*options*])

Displays and focuses the Find & Replace Pane.

Parameters:
- *options*:  Table of [`ui.find`](#ui.find) field options to initially set.

Usage:

```lua
ui.find.focus{find_entry_text = buffer:get_sel_text(), match_case = true}
```

<a id="ui.find.goto_file_found"></a>
### `ui.find.goto_file_found`(*location*)

Jumps to the source of a find in files search result in the "Files Found" buffer.

Parameters:
- *location*:  When `true`, jumps to the next search result. When `false`, jumps to the
	previous one. When a line number, jumps to it's source.

<a id="ui.find.highlight_all_matches"></a>
### `ui.find.highlight_all_matches`

Highlight all occurrences of found text in the current buffer.

The default value is `false`.

<a id="ui.find.in_files"></a>
### `ui.find.in_files`

Find search text in a directory of files.

The default value is `false`.

<a id="ui.find.in_files_label_text"></a>
### `ui.find.in_files_label_text`

The text of the "In files" label.
(Write-only)
This is primarily used for localization.

<a id="ui.find.incremental"></a>
### `ui.find.incremental`

Find search text incrementally as it is typed.

The default value is `false`.

<a id="ui.find.match_case"></a>
### `ui.find.match_case`

Match search text case sensitively.

The default value is `false`.

<a id="ui.find.match_case_label_text"></a>
### `ui.find.match_case_label_text`

The text of the "Match case" label.
(Write-only)
This is primarily used for localization.

<a id="ui.find.regex"></a>
### `ui.find.regex`

Interpret search text as a Regular Expression.

The default value is `false`.

<a id="ui.find.regex_label_text"></a>
### `ui.find.regex_label_text`

The text of the "Regex" label.
(Write-only)
This is primarily used for localization.

<a id="ui.find.replace"></a>
### `ui.find.replace`()

Mimics pressing the "Replace" button.

If any [`events.REPLACE`](#events.REPLACE) handler returns `true`, [`events.FIND`](#events.FIND) will not be emitted to mimic
pressing the "Find Next" button.

<a id="ui.find.replace_all"></a>
### `ui.find.replace_all`()

Mimics pressing the "Replace All" button.

See also: [`events.REPLACE_ALL`](#events.REPLACE_ALL)

<a id="ui.find.replace_all_button_text"></a>
### `ui.find.replace_all_button_text`

The text of the "Replace All" button.
(Write-only)
This is primarily used for localization.

<a id="ui.find.replace_button_text"></a>
### `ui.find.replace_button_text`

The text of the "Replace" button.
(Write-only)
This is primarily used for localization.

<a id="ui.find.replace_entry_text"></a>
### `ui.find.replace_entry_text`

The text in the "Replace" entry.

When searching for text in a directory of files, this is the current file and directory filter.

<a id="ui.find.replace_label_text"></a>
### `ui.find.replace_label_text`

The text of the "Replace" label.
(Write-only)
This is primarily used for localization.

<a id="ui.find.show_filenames_in_progressbar"></a>
### `ui.find.show_filenames_in_progressbar`

Show filenames in the find in files search progressbar.

This can be useful for determining whether or not custom filters are working as expected.
Showing filenames can slow down searches on computers with really fast SSDs.

The default value is `false`.

<a id="ui.find.whole_word"></a>
### `ui.find.whole_word`

Match search text only when it is surrounded by non-word characters in searches.

The default value is `false`.

See also: [`buffer.word_chars`](#buffer.word_chars)

<a id="ui.find.whole_word_label_text"></a>
### `ui.find.whole_word_label_text`

The text of the "Whole word" label.
(Write-only)
This is primarily used for localization.



<a id="view"></a>
## The `view` module

See [buffer](#the-buffer-module).




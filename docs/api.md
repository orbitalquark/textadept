## Textadept 12.4 API Documentation

1. [_G](#_G)
1. [_L](#_L)
1. [_SCINTILLA](#_SCINTILLA)
1. [args](#args)
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

<a id="CURSES"></a>
#### `CURSES` 

Whether or not Textadept is running in a terminal.
Curses feature incompatibilities are listed in the [Appendix][].

[Appendix]: manual.html#terminal-version-compatibility

<a id="GTK"></a>
#### `GTK` 

Whether or not Textadept is running as a GTK GUI application.

<a id="LINUX"></a>
#### `LINUX` 

Whether or not Textadept is running on Linux.

<a id="OSX"></a>
#### `OSX` 

Whether or not Textadept is running on macOS.

<a id="QT"></a>
#### `QT` 

Whether or not Textadept is running as a Qt GUI application.

<a id="WIN32"></a>
#### `WIN32` 

Whether or not Textadept is running on Windows.

<a id="_BUFFERS"></a>
#### `_BUFFERS` &lt;table&gt;

Table of all open buffers in Textadept.
Numeric keys have buffer values and buffer keys have their associated numeric keys.

Usage:

- `_BUFFERS[n]      --> buffer at index n
`
- `_BUFFERS[buffer] --> index of buffer in _BUFFERS
`

See also:

- [`buffer`](#buffer)

<a id="_CHARSET"></a>
#### `_CHARSET` 

The filesystem's character encoding.
This is used when [working with files](#io).

<a id="_COPYRIGHT"></a>
#### `_COPYRIGHT` 

Textadept's copyright information.

<a id="_HOME"></a>
#### `_HOME` 

The path to Textadept's home, or installation, directory.

<a id="_LEXERPATH"></a>
#### `_LEXERPATH` 

A ';'-separated list of directory paths that contain lexers for syntax highlighting.

<a id="_RELEASE"></a>
#### `_RELEASE` 

The Textadept release version string.

<a id="_THEME"></a>
#### `_THEME` 

Textadept's current UI mode, either "light" or "dark".
Manually changing this field has no effect.

<a id="_USERHOME"></a>
#### `_USERHOME` 

The path to the user's *~/.textadept/* directory, where all preferences and user-data is stored.
On Windows machines *~/* is the value of the "USERHOME" environment variable (typically
*C:\Users\username\\* or *C:\Documents and Settings\username\\*). On Linux and macOS machines
*~/* is the value of "$HOME" (typically */home/username/* and */Users/username/* respectively).

<a id="_VIEWS"></a>
#### `_VIEWS` &lt;table&gt;

Table of all views in Textadept.
Numeric keys have view values and view keys have their associated numeric keys.

Usage:

- `_VIEWS[n]    --> view at index n
`
- `_VIEWS[view] --> index of view in _VIEWS
`

See also:

- [`view`](#view)

<a id="arg"></a>
#### `arg` &lt;table&gt;

Table of command line parameters passed to Textadept.

See also:

- [`args`](#args)

<a id="_G.buffer"></a>
#### `buffer` &lt;table&gt;

The current [buffer](#buffer) in the [current view](#_G.view).

<a id="_G.keys"></a>
#### `keys` &lt;table&gt;

Map of [key bindings](#keys) to commands, with language-specific key tables assigned to a
lexer name key.

<a id="snippets"></a>
#### `snippets` &lt;table&gt;

Map of [snippet](#textadept.snippets) triggers with their snippet text or functions that
return such text, with language-specific snippets tables assigned to a lexer name key.

<a id="_G.view"></a>
#### `view` &lt;table&gt;

The current [view](#view).


### Functions defined by `_G`

<a id="assert"></a>
#### `assert`(*v*[, *message*='*assertion* *failed*!'[, ...]])

Asserts that value *v* is not `false` or `nil` and returns *v*, or calls `error()` with
*message* as the error message, defaulting to "assertion failed!".
If *message* is a format string, the remaining arguments are passed to `string.format()`
and the resulting string becomes the error message.

Parameters:

- *v*:  Value to assert.
- *message*:  Optional error message to show on error.
- *...*:  If *message* is a format string, these arguments are passed to
	`string.format()`.

<a id="assert_type"></a>
#### `assert_type`(*v*, *expected_type*, *narg*)

Asserts that value *v* has type string *expected_type* and returns *v*, or calls `error()`
with an error message that implicates function argument number *narg*.
This is intended to be used with API function arguments so users receive more helpful error
messages.

Parameters:

- *v*:  Value to assert the type of.
- *expected_type*:  String type to assert. It may be a non-letter-delimited list of type
	options.
- *narg*:  The positional argument number *v* is associated with. This is not required to
	be a number.

Usage:

- `assert_type(filename, 'string/nil', 1)
`
- `assert_type(option.setting, 'number', 'setting') -- implicates key
`

<a id="move_buffer"></a>
#### `move_buffer`(*from*, *to*)

Moves the buffer at index *from* to index *to* in the [`_BUFFERS`](#_BUFFERS) table, shifting other buffers
as necessary.
This changes the order buffers are displayed in in the tab bar and buffer browser.

Parameters:

- *from*:  Index of the buffer to move.
- *to*:  Index to move the buffer to.

<a id="quit"></a>
#### `quit`()

Emits [`events.QUIT`](#events.QUIT), and unless any handler returns `false`, quits Textadept.

<a id="reset"></a>
#### `reset`()

Resets the Lua State by reloading all initialization scripts.
This function is useful for modifying user scripts (such as *~/.textadept/init.lua*) on the
fly without having to restart Textadept. [`arg`](#arg) is set to `nil` when reinitializing the Lua
State. Any scripts that need to differentiate between startup and reset can test [`arg`](#arg).

<a id="timeout"></a>
#### `timeout`(*interval*, *f*[, ...])

Calls function *f* with the given arguments after *interval* seconds.
If *f* returns `true`, calls *f* repeatedly every *interval* seconds as long as *f* returns
`true`. A `nil` or `false` return value stops repetition.

Parameters:

- *interval*:  The interval in seconds to call *f* after.
- *f*:  The function to call.
- *...*:  Additional arguments to pass to *f*.


---
<a id="_L"></a>
## The `_L` Module
---

Map of all messages used by Textadept to their localized form.
If the localized version of a given message does not exist, the non-localized message is
returned. Use `rawget()` to check if a localization exists.
Note: the terminal version ignores any "_" or "&" mnemonics the GUI version would use.

---
<a id="_SCINTILLA"></a>
## The `_SCINTILLA` Module
---

Scintilla constants, functions, and properties.
Do not modify anything in this module. Doing so will have unpredictable consequences.

### Fields defined by `_SCINTILLA`

<a id="_SCINTILLA.constants"></a>
#### `_SCINTILLA.constants` &lt;table&gt;

Map of Scintilla constant names to their numeric values.

See also:

- [`buffer`](#buffer)
- [`view`](#view)

<a id="_SCINTILLA.events"></a>
#### `_SCINTILLA.events` &lt;table&gt;

Map of Scintilla event IDs to tables of event names and event parameters.

<a id="_SCINTILLA.functions"></a>
#### `_SCINTILLA.functions` &lt;table&gt;

Map of Scintilla function names to tables containing their IDs, return types, wParam types,
and lParam types. Types are as follows:

- `0`: Void.
- `1`: Integer.
- `2`: Length of the given lParam string.
- `3`: Integer position.
- `4`: Color, in "0xBBGGRR" format or "0xAABBGGRR" format where supported.
- `5`: Boolean `true` or `false`.
- `6`: Bitmask of Scintilla key modifiers and a key value.
- `7`: String parameter.
- `8`: String return value.

<a id="_SCINTILLA.properties"></a>
#### `_SCINTILLA.properties` &lt;table&gt;

Map of Scintilla property names to table values containing their "get" function IDs, "set"
function IDs, return types, and wParam types.
The wParam type will be non-zero if the property is indexable.
Types are the same as in the [`_SCINTILLA.functions`](#_SCINTILLA.functions) table.


### Functions defined by `_SCINTILLA`

<a id="_SCINTILLA.new_image_type"></a>
#### `_SCINTILLA.new_image_type`()

Returns a unique image type identier number for use with [`view:register_image()`](#view.register_image) and
[`view:register_rgba_image()`](#view.register_rgba_image).
Use this function for custom image types in order to prevent clashes with identifiers of
other custom image types.

Usage:

- `local image_type = _SCINTILLA.new_image_type()
`

<a id="_SCINTILLA.new_indic_number"></a>
#### `_SCINTILLA.new_indic_number`()

Returns a unique indicator number for use with custom indicators.
Use this function for custom indicators in order to prevent clashes with identifiers of
other custom indicators.

Usage:

- `local indic_num = _SCINTILLA.new_indic_number()
`

See also:

- [`view.indic_style`](#view.indic_style)

<a id="_SCINTILLA.new_marker_number"></a>
#### `_SCINTILLA.new_marker_number`()

Returns a unique marker number for use with [`view:marker_define()`](#view.marker_define).
Use this function for custom markers in order to prevent clashes with identifiers of other
custom markers.

Usage:

- `local marknum = _SCINTILLA.new_marker_number()
`

<a id="_SCINTILLA.new_user_list_type"></a>
#### `_SCINTILLA.new_user_list_type`()

Returns a unique user list identier number for use with [`buffer:user_list_show()`](#buffer.user_list_show).
Use this function for custom user lists in order to prevent clashes with list identifiers
of other custom user lists.

Usage:

- `local list_type = _SCINTILLA.new_user_list_type()
`


---
<a id="args"></a>
## The `args` Module
---

Processes command line arguments for Textadept.

### Functions defined by `args`

<a id="args.register"></a>
#### `args.register`(*short*, *long*, *narg*, *f*, *description*)

Registers a command line option with short and long versions *short* and *long*, respectively.
*narg* is the number of arguments the option accepts, *f* is the function called when the
option is set, and *description* is the option's description when displaying help.
Normally, options are not considered command line arguments, so they do not prevent
[`events.ARG_NONE`](#events.ARG_NONE) from being emitted. However, if *f* returns `true`, this option counts as
an argment and it will prevent [`events.ARG_NONE`](#events.ARG_NONE) from being emitted.

Parameters:

- *short*:  The string short version of the option.
- *long*:  The string long version of the option.
- *narg*:  The number of expected parameters for the option.
- *f*:  The Lua function to run when the option is set. It is passed *narg* string arguments.
- *description*:  The string description of the option for command line help.


---
<a id="buffer"></a>
## The `buffer` Module
---

A Textadept buffer or view object.
Constants are documented in the fields they apply to.
While you can work with individual buffer and view instances, it is really only useful to
work with the global one. (In fact, you are strongly discouraged from working with non-global
instances.)
Many of these functions and fields are derived from buffer- and view-specific functionality
of the Scintilla editing component, and additional information can be found on the [Scintilla
website](https://scintilla.org/ScintillaDoc.html).
Any buffer and view fields set on startup (e.g. in *~/.textadept/init.lua*) will be the
default, initial values for all buffers.

**Note:** This [`buffer`](#buffer) and [`view`](#view) API is largely interchangeable. That is, `view.`*field*
and `view:`*function* are often equivalent to `buffer.`*field* and `buffer:`*function*,
respectively. While this reference chooses one notation over the other, these choices are not
always strict requirements. Still, it is recommended to follow this convention. Functions
and fields related to manipulating buffer text and selections should use [`buffer`](#buffer), while
functions and fields related to displaying buffer text and other visuals should use [`view`](#view).

1. [Create Buffers and Views](#create-buffers-and-views)
1. [View Information](#view-information)
1. [Work with Files](#work-with-files)
1. [Move Within Lines](#move-within-lines)
1. [Move Between Lines](#move-between-lines)
1. [Move Between Pages](#move-between-pages)
1. [Move Between Buffers](#move-between-buffers)
1. [Other Movements](#other-movements)
1. [Retrieve Text](#retrieve-text)
1. [Set Text](#set-text)
1. [Replace Text](#replace-text)
1. [Delete Text](#delete-text)
1. [Transform Text](#transform-text)
1. [Split and Join Lines](#split-and-join-lines)
1. [Undo and Redo](#undo-and-redo)
1. [Employ the Clipboard](#employ-the-clipboard)
1. [Make Simple Selections](#make-simple-selections)
1. [Make Movement Selections](#make-movement-selections)
1. [Modal Selection](#modal-selection)
1. [Make and Modify Multiple Selections](#make-and-modify-multiple-selections)
1. [Make Rectangular Selections](#make-rectangular-selections)
1. [Simple Search](#simple-search)
1. [Search and Replace](#search-and-replace)
1. [Query Position Information](#query-position-information)
1. [Query Line and Line Number Information](#query-line-and-line-number-information)
1. [Query Measurement Information](#query-measurement-information)
1. [Configure Line Margins](#configure-line-margins)
1. [Mark Lines with Markers](#mark-lines-with-markers)
1. [Annotate Lines](#annotate-lines)
1. [Mark Text with Indicators](#mark-text-with-indicators)
1. [Display an Autocompletion List](#display-an-autocompletion-list)
1. [Display Images in Lists](#display-images-in-lists)
1. [Show a Call Tip](#show-a-call-tip)
1. [Fold or Hide Lines](#fold-or-hide-lines)
1. [Scroll the View](#scroll-the-view)
1. [Configure Indentation and Line Endings](#configure-indentation-and-line-endings)
1. [Configure Character Settings](#configure-character-settings)
1. [Configure the Color Theme](#configure-the-color-theme)
1. [Override Style Settings](#override-style-settings)
1. [Assign Caret, Selection, Whitespace, and Line Colors](#assign-caret,-selection,-whitespace,-and-line-colors)
1. [Configure Caret Display](#configure-caret-display)
1. [Configure Selection Display](#configure-selection-display)
1. [Configure Whitespace Display](#configure-whitespace-display)
1. [Configure Scrollbar Display and Scrolling Behavior](#configure-scrollbar-display-and-scrolling-behavior)
1. [Configure Mouse Cursor Display](#configure-mouse-cursor-display)
1. [Configure Wrapped Line Display](#configure-wrapped-line-display)
1. [Configure Text Zoom](#configure-text-zoom)
1. [Configure Long Line Display](#configure-long-line-display)
1. [Configure Fold Settings and Folded Line Display](#configure-fold-settings-and-folded-line-display)
1. [Highlight Matching Braces](#highlight-matching-braces)
1. [Configure Indentation Guide Display](#configure-indentation-guide-display)
1. [Configure File Types](#configure-file-types)
1. [Manually Style Text](#manually-style-text)
1. [Query Style Information](#query-style-information)
1. [Miscellaneous](#miscellaneous)

### Create Buffers and Views


<a id="buffer.new"></a>
#### `buffer:new`()

Creates a new buffer, displays it in the current view, and returns it.
Emits [`events.BUFFER_NEW`](#events.BUFFER_NEW).

Return:

- the new buffer.

See also:

- [`io.open_file`](#io.open_file)

<a id="view.split"></a>
#### `view:split`([*vertical*=*false*])

Splits the view into top and bottom views (unless *vertical* is `true`), focuses the new view,
and returns both the old and new views.
If *vertical* is `false`, splits the view vertically into left and right views.
Emits [`events.VIEW_NEW`](#events.VIEW_NEW).

Parameters:

- *vertical*:  Optional flag indicating whether or not to split the view
	vertically. The default is to split horizontally.

Return:

- old view and new view.

<a id="view.unsplit"></a>
#### `view:unsplit`()

Unsplits the view if possible, returning `true` on success.

Return:

- boolean if the view was unsplit or not.

### View Information


<a id="view.buffer"></a>
#### `view.buffer` &lt;table&gt;

The [buffer](#buffer) the view currently contains. (Read-only)

<a id="view.size"></a>
#### `view.size` 

The split resizer's pixel position if the view is a split one.

### Work with Files


<a id="buffer.reload"></a>
#### `buffer:reload`()

Reloads the buffer's file contents, discarding any changes.

<a id="buffer.save"></a>
#### `buffer:save`()

Saves the buffer to its file, returning `true` on success.
If the buffer does not have a file, the user is prompted for one.
Emits [`events.FILE_BEFORE_SAVE`](#events.FILE_BEFORE_SAVE) and [`events.FILE_AFTER_SAVE`](#events.FILE_AFTER_SAVE).

Return:

- `true` if the file was saved; `nil` otherwise.

See also:

- [`textadept.editing.strip_trailing_spaces`](#textadept.editing.strip_trailing_spaces)
- [`io.ensure_final_newline`](#io.ensure_final_newline)
- [`io.save_all_files`](#io.save_all_files)

<a id="buffer.save_as"></a>
#### `buffer:save_as`([*filename*])

Saves the buffer to file *filename* or the user-specified filename, returning `true`
on success.
Emits [`events.FILE_AFTER_SAVE`](#events.FILE_AFTER_SAVE).

Parameters:

- *filename*:  Optional new filepath to save the buffer to. If `nil`, the user is
	prompted for one.

Return:

- `true` if the file was saved; `nil` otherwise.

<a id="buffer.close"></a>
#### `buffer:close`([*force*=*false*])

Closes the buffer, prompting the user to continue if there are unsaved changes (unless *force*
is `true`), and returns `true` if the buffer was closed.

Parameters:

- *force*:  Optional flag that discards unsaved changes without prompting the user.

Return:

- `true` if the buffer was closed; `nil` otherwise.

See also:

- [`io.close_all_buffers`](#io.close_all_buffers)

<a id="buffer.set_encoding"></a>
#### `buffer:set_encoding`(*encoding*)

Converts the buffer's contents to encoding *encoding*.

Parameters:

- *encoding*:  The string encoding to set. Valid encodings are ones that GNU iconv accepts. If
	`nil`, assumes a binary encoding.

Usage:

- `buffer:set_encoding('CP1252')
`

See also:

- [`io.encodings`](#io.encodings)
- [`string.iconv`](#string.iconv)

<a id="buffer.filename"></a>
#### `buffer.filename` 

The absolute file path associated with the buffer.

<a id="buffer.modify"></a>
#### `buffer.modify` 

Whether or not the buffer has unsaved changes. (Read-only)

<a id="buffer.set_save_point"></a>
#### `buffer:set_save_point`()

Indicates the buffer has no unsaved changes.

<a id="buffer.encoding"></a>
#### `buffer.encoding` 

The string encoding of the file, or `nil` for binary files.

### Move Within Lines


 Movements within buffers scroll the caret into view if it is not already visible.
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


 Movements within buffers scroll the caret into view if it is not already visible.
<a id="buffer.goto_pos"></a>
#### `buffer:goto_pos`(*pos*)

Moves the caret to position *pos* and scrolls it into view.

Parameters:

- *pos*:  The position in *buffer* to go to.

<a id="buffer.goto_line"></a>
#### `buffer:goto_line`(*line*)

Moves the caret to the beginning of line number *line* and scrolls it into view, event if
*line* is hidden.

Parameters:

- *line*:  The line number in *buffer* to go to.

See also:

- [`textadept.editing.goto_line`](#textadept.editing.goto_line)

<a id="buffer.line_up"></a>
#### `buffer:line_up`()

Moves the caret up one line.

<a id="buffer.line_down"></a>
#### `buffer:line_down`()

Moves the caret down one line.

<a id="buffer.caret_sticky"></a>
#### `buffer.caret_sticky` 

The caret's preferred horizontal position when moving between lines.

- [`buffer.CARETSTICKY_OFF`](#buffer.CARETSTICKY_OFF)
	Use the same position the caret had on the previous line.
- [`buffer.CARETSTICKY_ON`](#buffer.CARETSTICKY_ON)
	Use the last position the caret was moved to via the mouse, left/right arrow keys,
	home/end keys, etc. Typing text does not affect the position.
- [`buffer.CARETSTICKY_WHITESPACE`](#buffer.CARETSTICKY_WHITESPACE)
	Use the position the caret had on the previous line, but prior to any inserted indentation.

	The default value is [`buffer.CARETSTICKY_OFF`](#buffer.CARETSTICKY_OFF).

<a id="buffer.choose_caret_x"></a>
#### `buffer:choose_caret_x`()

Identifies the current horizontal caret position as the caret's preferred horizontal position
when moving between lines.

<a id="buffer.toggle_caret_sticky"></a>
#### `buffer:toggle_caret_sticky`()

Cycles between [`buffer.caret_sticky`](#buffer.caret_sticky) option settings [`buffer.CARETSTICKY_ON`](#buffer.CARETSTICKY_ON) and
[`buffer.CARETSTICKY_OFF`](#buffer.CARETSTICKY_OFF).

### Move Between Pages


 Movements within buffers scroll the caret into view if it is not already visible.
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

Switches to buffer *buffer* or the buffer *buffer* number of buffers relative to the
current one.
Emits [`events.BUFFER_BEFORE_SWITCH`](#events.BUFFER_BEFORE_SWITCH) and [`events.BUFFER_AFTER_SWITCH`](#events.BUFFER_AFTER_SWITCH).

Parameters:

- *buffer*:  A buffer or relative buffer number (typically 1 or -1).

### Other Movements


 Movements within buffers scroll the caret into view if it is not already visible.
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
Multiple selections are included in order with no delimiters. Rectangular selections are
included from top to bottom with end of line characters. Virtual space is not included.

Return:

- string, number

<a id="buffer.text_range"></a>
#### `buffer:text_range`(*start_pos*, *end_pos*)

Returns the range of text between positions *start_pos* and *end_pos*.

Parameters:

- *start_pos*:  The start position of the range of text to get in *buffer*.
- *end_pos*:  The end position of the range of text to get in *buffer*.

<a id="buffer.get_line"></a>
#### `buffer:get_line`(*line*)

Returns the text on line number *line*, including end of line characters.

Parameters:

- *line*:  The line number in *buffer* to use.

Return:

- string, number

<a id="buffer.get_cur_line"></a>
#### `buffer:get_cur_line`()

Returns the current line's text and the caret's position on that line.

Return:

- string, number

<a id="buffer.char_at"></a>
#### `buffer.char_at` &lt;table&gt;

List of character bytes per position. (Read-only)

### Set Text


<a id="buffer.set_text"></a>
#### `buffer:set_text`(*text*)

Replaces the buffer's text with string *text*.

Parameters:

- *text*:  The text to set.

<a id="buffer.add_text"></a>
#### `buffer:add_text`(*text*)

Adds string *text* to the buffer at the caret position and moves the caret to the end of
the added text without scrolling it into view.

Parameters:

- *text*:  The text to add.

<a id="buffer.insert_text"></a>
#### `buffer:insert_text`(*pos*, *text*)

Inserts string *text* at position *pos*, removing any selections.
If *pos* is `-1`, inserts *text* at the caret position.
If the caret is after the *pos*, it is moved appropriately, but not scrolled into view.

Parameters:

- *pos*:  The position in *buffer* to insert text at, or `-1` for the current position.
- *text*:  The text to insert.

<a id="buffer.append_text"></a>
#### `buffer:append_text`(*text*)

Appends string *text* to the end of the buffer without modifying any existing selections or
scrolling the text into view.

Parameters:

- *text*:  The text to append.

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


 Replacing an arbitrary range of text makes use of a target range, a user-defined defined
 region of text that some buffer functions operate on in order to avoid altering the current
 selection or scrolling the view.
<a id="buffer.replace_sel"></a>
#### `buffer:replace_sel`(*text*)

Replaces the selected text with string *text*, scrolling the caret into view.

Parameters:

- *text*:  The text to replace the selected text with.

<a id="buffer.set_target_range"></a>
#### `buffer:set_target_range`(*start_pos*, *end_pos*)

Defines the target range's beginning and end positions as *start_pos* and *end_pos*,
respectively.

Parameters:

- *start_pos*:  The position of the beginning of the target range.
- *end_pos*:  The position of the end of the target range.

<a id="buffer.target_from_selection"></a>
#### `buffer:target_from_selection`()

Defines the target range's beginning and end positions as the beginning and end positions
of the main selection, respectively.

<a id="buffer.replace_target"></a>
#### `buffer:replace_target`(*text*)

Replaces the text in the target range with string *text* sans modifying any selections or
scrolling the view.
Setting the target and calling this function with an empty string is another way to delete text.

Parameters:

- *text*:  The text to replace the target range with.

Return:

- number

### Delete Text


<a id="buffer.clear"></a>
#### `buffer:clear`()

Deletes the selected text or the character at the caret.

<a id="buffer.delete_range"></a>
#### `buffer:delete_range`(*pos*, *length*)

Deletes the range of text from position *pos* to *pos* + *length*.

Parameters:

- *pos*:  The start position of the range of text in *buffer* to delete.
- *length*:  The number of characters in the range of text to delete.

<a id="buffer.delete_back"></a>
#### `buffer:delete_back`()

Deletes the character behind the caret if no text is selected.
Otherwise, deletes the selected text.

<a id="buffer.delete_back_not_line"></a>
#### `buffer:delete_back_not_line`()

Deletes the character behind the caret unless either the caret is at the beginning of a
line or text is selected.
If text is selected, deletes it.

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

Indents the text on the selected lines or types a Tab character ("\t") at the caret position.

<a id="buffer.back_tab"></a>
#### `buffer:back_tab`()

Un-indents the text on the selected lines.

<a id="buffer.line_transpose"></a>
#### `buffer:line_transpose`()

Swaps the current line with the previous one.

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

Splits the lines in the target range into lines *width* pixels wide.
If *width* is `0`, splits the lines in the target range into lines as wide as the view.

Parameters:

- *width*:  The pixel width to split lines at. When `0`, uses the width of the view.

See also:

- [`buffer.set_target_range`](#buffer.set_target_range)
- [`buffer.target_from_selection`](#buffer.target_from_selection)

<a id="buffer.lines_join"></a>
#### `buffer:lines_join`()

Joins the lines in the target range, inserting spaces between the words joined at line
boundaries.

See also:

- [`buffer.set_target_range`](#buffer.set_target_range)
- [`buffer.target_from_selection`](#buffer.target_from_selection)
- [`textadept.editing.join_lines`](#textadept.editing.join_lines)

### Undo and Redo


<a id="buffer.can_undo"></a>
#### `buffer:can_undo`()

Returns whether or not there is an action to be undone.

Return:

- bool

<a id="buffer.can_redo"></a>
#### `buffer:can_redo`()

Returns whether or not there is an action to be redone.

Return:

- bool

<a id="buffer.undo"></a>
#### `buffer:undo`()

Undoes the most recent action.

<a id="buffer.redo"></a>
#### `buffer:redo`()

Redoes the next undone action.

<a id="buffer.begin_undo_action"></a>
#### `buffer:begin_undo_action`()

Starts a sequence of actions to be undone or redone as a single action.
May be nested.

<a id="buffer.end_undo_action"></a>
#### `buffer:end_undo_action`()

Ends a sequence of actions to be undone or redone as a single action.

<a id="buffer.empty_undo_buffer"></a>
#### `buffer:empty_undo_buffer`()

Deletes the undo and redo history.

### Employ the Clipboard


<a id="buffer.cut"></a>
#### `buffer:cut`()

Cuts the selected text to the clipboard.
Multiple selections are copied in order with no delimiters. Rectangular selections are copied
from top to bottom with end of line characters. Virtual space is not copied.

<a id="buffer.copy"></a>
#### `buffer:copy`()

Copies the selected text to the clipboard.
Multiple selections are copied in order with no delimiters. Rectangular selections are copied
from top to bottom with end of line characters. Virtual space is not copied.

<a id="buffer.line_cut"></a>
#### `buffer:line_cut`()

Cuts the current line to the clipboard.

<a id="buffer.line_copy"></a>
#### `buffer:line_copy`()

Copies the current line to the clipboard.

<a id="buffer.copy_range"></a>
#### `buffer:copy_range`(*start_pos*, *end_pos*)

Copies to the clipboard the range of text between positions *start_pos* and *end_pos*.

Parameters:

- *start_pos*:  The start position of the range of text in *buffer* to copy.
- *end_pos*:  The end position of the range of text in *buffer* to copy.

<a id="buffer.copy_text"></a>
#### `buffer:copy_text`(*text*)

Copies string *text* to the clipboard.

Parameters:

- *text*:  The text to copy.

<a id="buffer.paste"></a>
#### `buffer:paste`()

Pastes the clipboard's contents into the buffer, replacing any selected text according to
[`buffer.multi_paste`](#buffer.multi_paste).

See also:

- [`textadept.editing.paste_reindent`](#textadept.editing.paste_reindent)
- [`ui.clipboard_text`](#ui.clipboard_text)

<a id="buffer.multi_paste"></a>
#### `buffer.multi_paste` 

The multiple selection paste mode.

- `buffer.MULTIPASTE_ONCE`
	Paste into only the main selection.
- `buffer.MULTIPASTE_EACH`
	Paste into all selections.

	The default value is `buffer.MULTIPASTE_EACH`.

### Make Simple Selections


<a id="buffer.set_sel"></a>
#### `buffer:set_sel`(*start_pos*, *end_pos*)

Selects the range of text between positions *start_pos* and *end_pos*, scrolling the selected
text into view.

Parameters:

- *start_pos*:  The start position of the range of text in *buffer* to select. If negative,
	it means the end of the buffer.
- *end_pos*:  The end position of the range of text in *buffer* to select. If negative,
	it means remove any selection (i.e. set [`buffer.anchor`](#buffer.anchor) to the same position as
	[`buffer.current_pos`](#buffer.current_pos)).

<a id="buffer.selection_start"></a>
#### `buffer.selection_start` 

The position of the beginning of the selected text.
When set, becomes the anchor, but is not scrolled into view.

<a id="buffer.selection_end"></a>
#### `buffer.selection_end` 

The position of the end of the selected text.
When set, becomes the current position, but is not scrolled into view.

<a id="buffer.swap_main_anchor_caret"></a>
#### `buffer:swap_main_anchor_caret`()

Swaps the main selection's beginning and end positions.

<a id="buffer.select_all"></a>
#### `buffer:select_all`()

Selects all of the buffer's text without scrolling the view.

<a id="buffer.set_empty_selection"></a>
#### `buffer:set_empty_selection`(*pos*)

Moves the caret to position *pos* without scrolling the view and removes any selections.

Parameters:

- *pos*:  The position in *buffer* to move to.

<a id="buffer.selection_empty"></a>
#### `buffer.selection_empty` 

Whether or not no text is selected. (Read-only)

<a id="buffer.selection_is_rectangle"></a>
#### `buffer.selection_is_rectangle` 

Whether or not the selection is a rectangular selection. (Read-only)

<a id="buffer.is_range_word"></a>
#### `buffer:is_range_word`(*start_pos*, *end_pos*)

Returns whether or not the the positions *start_pos* and *end_pos* are at word boundaries.

Parameters:

- *start_pos*:  The start position of the range of text in *buffer* to check for a word
	boundary at.
- *end_pos*:  The end position of the range of text in *buffer* to check for a word
	boundary at.

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

Whether or not regular caret movement alters the selected text.
Setting [`buffer.selection_mode`](#buffer.selection_mode) also alters this property.

### Modal Selection


<a id="buffer.selection_mode"></a>
#### `buffer.selection_mode` 

The selection mode.

- [`buffer.SEL_STREAM`](#buffer.SEL_STREAM)
	Character selection.
- [`buffer.SEL_RECTANGLE`](#buffer.SEL_RECTANGLE)
	Rectangular selection.
- [`buffer.SEL_LINES`](#buffer.SEL_LINES)
	Line selection.
- [`buffer.SEL_THIN`](#buffer.SEL_THIN)
	Thin rectangular selection. This is the mode after a rectangular selection has been
	typed into and ensures that no characters are selected.

	When set, caret movement alters the selected text until this field is set again to the
	same value or until [`buffer:cancel()`](#buffer.cancel) is called.

<a id="buffer.change_selection_mode"></a>
#### `buffer:change_selection_mode`(*mode*)

Changes the selection mode without subsequent caret movement altering selected text
(i.e. setting [`buffer.move_extends_selection`](#buffer.move_extends_selection)).

Parameters:

- *mode*:  The selection mode to change to. Valid values are:

	- [`buffer.SEL_STREAM`](#buffer.SEL_STREAM)
	- [`buffer.SEL_RECTANGLE`](#buffer.SEL_RECTANGLE)
	- [`buffer.SEL_LINES`](#buffer.SEL_LINES)
	- [`buffer.SEL_THIN`](#buffer.SEL_THIN)

### Make and Modify Multiple Selections


 **Note:** the `buffer.selection_n_`\* fields cannot be used to create selections.
<a id="buffer.set_selection"></a>
#### `buffer:set_selection`(*end_pos*, *start_pos*)

Selects the range of text between positions *start_pos* to *end_pos*, removing all other
selections.

Parameters:

- *end_pos*:  The caret position of the range of text to select in *buffer*.
- *start_pos*:  The anchor position of the range of text to select in *buffer*.

<a id="buffer.add_selection"></a>
#### `buffer:add_selection`(*end_pos*, *start_pos*)

Selects the range of text between positions *start_pos* to *end_pos* as the main selection,
retaining all other selections as additional selections.
Since an empty selection (i.e. the current position) still counts as a selection, use
[`buffer:set_selection()`](#buffer.set_selection) first when setting a list of selections.

Parameters:

- *end_pos*:  The caret position of the range of text to select in *buffer*.
- *start_pos*:  The anchor position of the range of text to select in *buffer*.

<a id="buffer.multiple_select_add_next"></a>
#### `buffer:multiple_select_add_next`()

Adds to the set of selections the next occurrence of the main selection within the target
range, makes that occurrence the new main selection, and scrolls it into view.
If there is no selected text, the current word is used.

See also:

- [`textadept.editing.select_word`](#textadept.editing.select_word)

<a id="buffer.multiple_select_add_each"></a>
#### `buffer:multiple_select_add_each`()

Adds to the set of selections each occurrence of the main selection within the target range.
If there is no selected text, the current word is used.

See also:

- [`textadept.editing.select_word`](#textadept.editing.select_word)

<a id="buffer.main_selection"></a>
#### `buffer.main_selection` 

The number of the main or most recent selection.
Only an existing selection can be made main.

<a id="buffer.rotate_selection"></a>
#### `buffer:rotate_selection`()

Designates the next additional selection to be the main selection.

<a id="buffer.drop_selection_n"></a>
#### `buffer:drop_selection_n`(*n*)

Drops existing selection number *n*.

Parameters:

- *n*:  The number of the existing selection.

<a id="buffer.selection_n_anchor"></a>
#### `buffer.selection_n_anchor` &lt;table&gt;

List of positions at the beginning of existing selections numbered from `1`, the main
selection.

<a id="buffer.selection_n_caret"></a>
#### `buffer.selection_n_caret` &lt;table&gt;

List of positions at the end of existing selections numbered from `1`, the main selection.

<a id="buffer.selection_n_start"></a>
#### `buffer.selection_n_start` &lt;table&gt;

List of positions at the beginning of existing selections numbered from `1`, the main
selection.

<a id="buffer.selection_n_end"></a>
#### `buffer.selection_n_end` &lt;table&gt;

List of positions at the end of existing selections numbered from `1`, the main selection.

<a id="buffer.selection_n_anchor_virtual_space"></a>
#### `buffer.selection_n_anchor_virtual_space` &lt;table&gt;

List of positions at the beginning of virtual space selected in existing selections numbered
from `1`, the main selection.

<a id="buffer.selection_n_caret_virtual_space"></a>
#### `buffer.selection_n_caret_virtual_space` &lt;table&gt;

List of positions at the end of virtual space selected in existing selections numbered from
`1`, the main selection.

<a id="buffer.selection_n_start_virtual_space"></a>
#### `buffer.selection_n_start_virtual_space` &lt;table&gt;

List of positions at the beginning of virtual space selected in existing selections numbered
from `1`, the main selection. (Read-only)

<a id="buffer.selection_n_end_virtual_space"></a>
#### `buffer.selection_n_end_virtual_space` &lt;table&gt;

List of positions at the end of virtual space selected in existing selections numbered from
`1`, the main selection. (Read-only)

<a id="buffer.selections"></a>
#### `buffer.selections` 

The number of active selections. There is always at least one selection. (Read-only)

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

- [`view.MOD_CTRL`](#view.MOD_CTRL)
	The "Control" modifier key.
- [`view.MOD_ALT`](#view.MOD_ALT)
	The "Alt" modifier key.
- [`view.MOD_SUPER`](#view.MOD_SUPER)
	The "Super" modifier key, usually defined as the left "Windows" or "Command" key.

The default value is [`view.MOD_ALT`](#view.MOD_ALT).

<a id="view.mouse_selection_rectangular_switch"></a>
#### `view.mouse_selection_rectangular_switch` 

Whether or not pressing [`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) when selecting text
normally with the mouse turns on rectangular selection.
The default value is `true`.

<a id="buffer.replace_rectangular"></a>
#### `buffer:replace_rectangular`(*text*)

Replaces the rectangular selection with string *text*.

Parameters:

- *text*:  The text to replace the rectangular selection with.

### Simple Search


<a id="buffer.search_anchor"></a>
#### `buffer:search_anchor`()

Anchors the position that [`buffer:search_next()`](#buffer.search_next) and [`buffer:search_prev()`](#buffer.search_prev) start at to the
beginning of the current selection or caret position.

<a id="buffer.search_next"></a>
#### `buffer:search_next`(*flags*, *text*)

Searches for and selects the first occurrence of string *text* starting at the search
anchor using search flags *flags*, returning that occurrence's position or `-1` if *text*
was not found.
Selected text is not scrolled into view.

Parameters:

- *flags*:  The search flags to use. See [`buffer.search_flags`](#buffer.search_flags).
- *text*:  The text to search for.

Return:

- number

See also:

- [`buffer.search_flags`](#buffer.search_flags)

<a id="buffer.search_prev"></a>
#### `buffer:search_prev`(*flags*, *text*)

Searches for and selects the last occurrence of string *text* before the search anchor using
search flags *flags*, returning that occurrence's position or `-1` if *text* was not found.

Parameters:

- *flags*:  The search flags to use. See [`buffer.search_flags`](#buffer.search_flags).
- *text*:  The text to search for.

Return:

- number

See also:

- [`buffer.search_flags`](#buffer.search_flags)

### Search and Replace


 The more complex search and replace API uses a target range (a user-defined region of text
 that some buffer functions operate on, or a region of text that some buffer functions define
 as output).
<a id="buffer.search_flags"></a>
#### `buffer.search_flags` 

The bit-mask of search flags used by [`buffer:search_in_target()`](#buffer.search_in_target).

- [`buffer.FIND_WHOLEWORD`](#buffer.FIND_WHOLEWORD)
	Match search text only when it is surrounded by non-word characters.
- [`buffer.FIND_MATCHCASE`](#buffer.FIND_MATCHCASE)
	Match search text case sensitively.
- [`buffer.FIND_WORDSTART`](#buffer.FIND_WORDSTART)
	Match search text only when the previous character is a non-word character.
- [`buffer.FIND_REGEXP`](#buffer.FIND_REGEXP)
	Interpret search text as a regular expression.

	The default value is `0`.

<a id="buffer.target_whole_document"></a>
#### `buffer:target_whole_document`()

Defines the target range's beginning and end positions as the beginning and end positions
of the document, respectively.

See also:

- [`buffer.set_target_range`](#buffer.set_target_range)
- [`buffer.target_from_selection`](#buffer.target_from_selection)

<a id="buffer.search_in_target"></a>
#### `buffer:search_in_target`(*text*)

Searches for the first occurrence of string *text* in the target range bounded by
[`buffer.target_start`](#buffer.target_start) and [`buffer.target_end`](#buffer.target_end) using search flags [`buffer.search_flags`](#buffer.search_flags)
and, if found, sets the new target range to that occurrence, returning its position or `-1`
if *text* was not found.

Parameters:

- *text*:  The text to search the target range for.

Return:

- number

<a id="buffer.replace_target_re"></a>
#### `buffer:replace_target_re`(*text*)

Replaces the text in the target range with string *text* but first replaces any "\d" sequences
with the text of capture number *d* from the regular expression (or the entire match for *d*
= 0), and then returns the replacement text's length.

Parameters:

- *text*:  The text to replace the target range with.

Return:

- number

See also:

- [`buffer.replace_target`](#buffer.replace_target)

<a id="buffer.target_text"></a>
#### `buffer.target_text` 

The text in the target range. (Read-only)

<a id="buffer.target_start"></a>
#### `buffer.target_start` 

The position of the beginning of the target range.
This is also set by a successful [`buffer:search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_end"></a>
#### `buffer.target_end` 

The position of the end of the target range.
This is also set by a successful [`buffer:search_in_target()`](#buffer.search_in_target).

<a id="buffer.target_start_virtual_space"></a>
#### `buffer.target_start_virtual_space` 

The position of the beginning of virtual space in the target range.
This is set to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set, or when
[`buffer:set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.target_end_virtual_space"></a>
#### `buffer.target_end_virtual_space` 

The position of the end of virtual space in the target range.
This is set to `1` when [`buffer.target_start`](#buffer.target_start) or [`buffer.target_end`](#buffer.target_end) is set, or when
[`buffer:set_target_range()`](#buffer.set_target_range) is called.

<a id="buffer.tag"></a>
#### `buffer.tag` 

List of capture text for capture numbers from a regular expression search. (Read-only)

### Query Position Information


<a id="buffer.anchor"></a>
#### `buffer.anchor` 

The anchor's position.

<a id="buffer.current_pos"></a>
#### `buffer.current_pos` 

The caret's position.
 When set, does not scroll the caret into view.

<a id="buffer.position_before"></a>
#### `buffer:position_before`(*pos*)

Returns the position of the character before position *pos* (taking multi-byte characters
into account), or `1` if there is no character before *pos*.

Parameters:

- *pos*:  The position in *buffer* to get the position before from.

Return:

- number

<a id="buffer.position_after"></a>
#### `buffer:position_after`(*pos*)

Returns the position of the character after position *pos* (taking multi-byte characters
into account), or `buffer.length + 1` if there is no character after *pos*.

Parameters:

- *pos*:  The position in *buffer* to get the position after from.

<a id="buffer.position_relative"></a>
#### `buffer:position_relative`(*pos*, *n*)

Returns the position *n* characters before or after position *pos* (taking multi-byte
characters into account).
Returns `1` if the position is less than 1 or greater than `buffer.length + 1`.

Parameters:

- *pos*:  The position in *buffer* to get the relative position from.
- *n*:  The relative number of characters to get the position for. A negative number
	indicates a position before while a positive number indicates a position after.

Return:

- number

<a id="buffer.word_start_position"></a>
#### `buffer:word_start_position`(*pos*, *only_word_chars*)

Returns the position of the beginning of the word at position *pos*.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words. If *pos* has
a non-word character to its left and *only_word_chars* is `false`, returns the last word
character's position.

Parameters:

- *pos*:  The position in *buffer* of the word.
- *only_word_chars*:  If `true`, stops searching at the first non-word character in the
	search direction. Otherwise, the first character in the search direction sets the
	type of the search as word or non-word and the search stops at the first non-matching
	character. Searches are also terminated by the start or end of the buffer.

<a id="buffer.word_end_position"></a>
#### `buffer:word_end_position`(*pos*, *only_word_chars*)

Returns the position of the end of the word at position *pos*.
[`buffer.word_chars`](#buffer.word_chars) contains the set of characters that constitute words. If *pos* has a
non-word character to its right and *only_word_chars* is `false`, returns the first word
character's position.

Parameters:

- *pos*:  The position in *buffer* of the word.
- *only_word_chars*:  If `true`, stops searching at the first non-word character in the
	search direction. Otherwise, the first character in the search direction sets the
	type of the search as word or non-word and the search stops at the first non-matching
	character. Searches are also terminated by the start or end of the buffer.

<a id="buffer.position_from_line"></a>
#### `buffer:position_from_line`(*line*)

Returns the position at the beginning of line number *line*.
Returns `-1` if *line* is greater than `buffer.line_count + 1`.

Parameters:

- *line*:  The line number in *buffer* to get the beginning position for.

Return:

- number

<a id="buffer.line_indent_position"></a>
#### `buffer.line_indent_position` &lt;table&gt;

List of positions at the ends of indentation per line number. (Read-only)

<a id="buffer.line_end_position"></a>
#### `buffer.line_end_position` &lt;table&gt;

List of positions at the ends of lines, but before any end of line characters, per line
number. (Read-only)

<a id="buffer.find_column"></a>
#### `buffer:find_column`(*line*, *column*)

Returns the position of column number *column* on line number *line* (taking tab and
multi-byte characters into account), or the position at the end of line *line*.

Parameters:

- *line*:  The line number in *buffer* to use.
- *column*:  The column number to use.

<a id="buffer.brace_match"></a>
#### `buffer:brace_match`(*pos*, *max_re_style*)

Returns the position of the matching brace for the brace character at position *pos*, taking
nested braces into account, or `-1`.
The brace characters recognized are '(', ')', '[', ']', '{', '}', '<', and '>' and must have
the same style.

Parameters:

- *pos*:  The position of the brace in *buffer* to match.
- *max_re_style*:  Must be `0`. Reserved for expansion.

Return:

- number

### Query Line and Line Number Information


<a id="buffer.line_count"></a>
#### `buffer.line_count` 

The number of lines in the buffer. (Read-only)
There is always at least one.

<a id="view.lines_on_screen"></a>
#### `view.lines_on_screen` 

The number of completely visible lines in the view. (Read-only)
It is possible to have a partial line visible at the bottom of the view.

<a id="view.first_visible_line"></a>
#### `view.first_visible_line` 

The line number of the line at the top of the view.

<a id="buffer.line_from_position"></a>
#### `buffer:line_from_position`(*pos*)

Returns the line number of the line that contains position *pos*.
Returns `1` if *pos* is less than 1 or [`buffer.line_count`](#buffer.line_count) if *pos* is greater than
`buffer.length + 1`.

Parameters:

- *pos*:  The position in *buffer* to get the line number of.

Return:

- number

<a id="buffer.line_indentation"></a>
#### `buffer.line_indentation` &lt;table&gt;

List of column indentation amounts per line number.

<a id="buffer.line_length"></a>
#### `buffer:line_length`(*line*)

Returns the number of bytes on line number *line*, including end of line characters.
To get line length excluding end of line characters, use `buffer.line_end_position[line]
- buffer.position_from_line(line)`.

Parameters:

- *line*:  The line number in *buffer* to get the length of.

Return:

- number

<a id="view.wrap_count"></a>
#### `view:wrap_count`(*line*)

Returns the number of wrapped lines needed to fully display line number *line*.

Parameters:

- *line*:  The line number in *view* to use.

Return:

- number

<a id="view.visible_from_doc_line"></a>
#### `view:visible_from_doc_line`(*line*)

Returns the displayed line number of actual line number *line*, taking wrapped, annotated,
and hidden lines into account, or `-1` if *line* is outside the range of lines in the buffer.
Lines can occupy more than one display line if they wrap.

Parameters:

- *line*:  The line number in *view* to use.

Return:

- number

<a id="view.doc_line_from_visible"></a>
#### `view:doc_line_from_visible`(*display_line*)

Returns the actual line number of displayed line number *display_line*, taking wrapped,
annotated, and hidden lines into account.
If *display_line* is less than or equal to `1`, returns `1`. If *display_line* is greater
than the number of displayed lines, returns [`buffer.line_count`](#buffer.line_count).

Parameters:

- *display_line*:  The display line number to use.

Return:

- number

### Query Measurement Information


<a id="buffer.length"></a>
#### `buffer.length` 

The number of bytes in the buffer. (Read-only)

<a id="buffer.text_length"></a>
#### `buffer.text_length` 

The number of bytes in the buffer. (Read-only)

<a id="buffer.column"></a>
#### `buffer.column` &lt;table&gt;

List of column numbers (taking tab widths into account) per position. (Read-only)
Multi-byte characters count as single characters.

<a id="buffer.count_characters"></a>
#### `buffer:count_characters`(*start_pos*, *end_pos*)

Returns the number of whole characters (taking multi-byte characters into account) between
positions *start_pos* and *end_pos*.

Parameters:

- *start_pos*:  The start position of the range of text in *buffer* to start counting at.
- *end_pos*:  The end position of the range of text in *buffer* to stop counting at.

Return:

- number

<a id="view.text_width"></a>
#### `view:text_width`(*style_num*, *text*)

Returns the pixel width string *text* would have when styled with style number *style_num*,
in the range of `1` to `256`.

Parameters:

- *style_num*:  The style number between `1` and `256` to use.
- *text*:  The text to measure the width of.

Return:

- number

<a id="view.text_height"></a>
#### `view:text_height`(*line*)

Returns the pixel height of line number *line*.

Parameters:

- *line*:  The line number to get the pixel height of.

Return:

- number

### Configure Line Margins


 The number of line margins is configurable, with each one displaying either line numbers,
 [marker symbols](#mark-lines-with-markers), or text.
<a id="view.margins"></a>
#### `view.margins` 

The number of margins.
The default value is `5`.

<a id="view.margin_type_n"></a>
#### `view.margin_type_n` &lt;table&gt;

List of margin types for margin numbers from `1` to [`view.margins`](#view.margins) (`5` by default).

- [`view.MARGIN_SYMBOL`](#view.MARGIN_SYMBOL)
	A marker symbol margin.
- [`view.MARGIN_NUMBER`](#view.MARGIN_NUMBER)
	A line number margin.
- [`view.MARGIN_BACK`](#view.MARGIN_BACK)
	A marker symbol margin whose background color matches the default text background color.
- [`view.MARGIN_FORE`](#view.MARGIN_FORE)
	A marker symbol margin whose background color matches the default text foreground color.
- [`view.MARGIN_TEXT`](#view.MARGIN_TEXT)
	A text margin.
- [`view.MARGIN_RTEXT`](#view.MARGIN_RTEXT)
	A right-justified text margin.
- [`view.MARGIN_COLOR`](#view.MARGIN_COLOR)
	A marker symbol margin whose background color is configurable.

The default value for the first margin is [`view.MARGIN_NUMBER`](#view.MARGIN_NUMBER), followed by [`view.MARGIN_SYMBOL`](#view.MARGIN_SYMBOL)
for the rest.

<a id="view.margin_width_n"></a>
#### `view.margin_width_n` &lt;table&gt;

List of pixel margin widths for margin numbers from `1` to [`view.margins`](#view.margins) (`5` by default).

<a id="view.margin_mask_n"></a>
#### `view.margin_mask_n` &lt;table&gt;

List of bit-masks of markers whose symbols marker symbol margins can display for margin
numbers from `1` to [`view.margins`](#view.margins) (`5` by default).
Bit-masks are 32-bit values whose bits correspond to the 32 available markers.
The default values are `0`, `~view.MASK_FOLDERS`, [`view.MASK_FOLDERS`](#view.MASK_FOLDERS), `0`, and `0`, for a
line margin and logical marker margin.

<a id="view.margin_sensitive_n"></a>
#### `view.margin_sensitive_n` &lt;table&gt;

List of flags that indicate whether or not mouse clicks in margins emit `MARGIN_CLICK`
events for margin numbers from `1` to [`view.margins`](#view.margins) (`5` by default).
The default values are `false` for the first margin and `true` for the others.

<a id="view.margin_cursor_n"></a>
#### `view.margin_cursor_n` &lt;table&gt;

List of cursor types shown over margin numbers from `1` to [`view.margins`](#view.margins) (`5` by default).

- [`view.CURSORARROW`](#view.CURSORARROW)
	Normal arrow cursor.
- [`view.CURSORREVERSEARROW`](#view.CURSORREVERSEARROW)
	Reversed arrow cursor.

The default values are [`view.CURSORARROW`](#view.CURSORARROW).

<a id="buffer.margin_text"></a>
#### `buffer.margin_text` &lt;table&gt;

List of text displayed in text margins per line number.

<a id="buffer.margin_style"></a>
#### `buffer.margin_style` &lt;table&gt;

List of style numbers in the text margin per line number.
Only some style attributes are active in text margins: font, size, bold, italics, fore,
and back.

<a id="buffer.margin_text_clear_all"></a>
#### `buffer:margin_text_clear_all`()

Clears all text in text margins.

<a id="view.margin_options"></a>
#### `view.margin_options` 

A bit-mask of margin option settings.

- [`view.MARGINOPTION_NONE`](#view.MARGINOPTION_NONE)
	None.
- [`view.MARGINOPTION_SUBLINESELECT`](#view.MARGINOPTION_SUBLINESELECT)
	Select only a wrapped line's sub-line (rather than the entire line) when the line number
	margin is clicked.

The default value is [`view.MARGINOPTION_NONE`](#view.MARGINOPTION_NONE).

<a id="view.margin_back_n"></a>
#### `view.margin_back_n` &lt;table&gt;

List of background colors, in "0xBBGGRR" format, of margin numbers from `1` to [`view.margins`](#view.margins)
(`5` by default).
Only affects margins of type [`view.MARGIN_COLOR`](#view.MARGIN_COLOR).

<a id="view.set_fold_margin_color"></a>
#### `view:set_fold_margin_color`(*use_setting*, *color*)

Overrides the fold margin's default color with color *color*, in "0xBBGGRR" format, if
*use_setting* is `true`.

Parameters:

- *use_setting*:  Whether or not to use *color*.
- *color*:  The color in "0xBBGGRR" format.

<a id="view.set_fold_margin_hi_color"></a>
#### `view:set_fold_margin_hi_color`(*use_setting*, *color*)

Overrides the fold margin's default highlight color with color *color*, in "0xBBGGRR" format,
if *use_setting* is `true`.

Parameters:

- *use_setting*:  Whether or not to use *color*.
- *color*:  The color in "0xBBGGRR" format.

<a id="view.margin_left"></a>
#### `view.margin_left` 

The pixel size of the left margin of the buffer text.
The default value is `1`.

<a id="view.margin_right"></a>
#### `view.margin_right` 

The pixel size of the right margin of the buffer text.
The default value is `1`.

### Mark Lines with Markers


 Each marker has an assigned symbol that is displayed in properly configured
 [margins](#configure-line-margins). For lines with multiple markers, markers are drawn over
 one another in ascending order. Markers move in sync with the lines they were added to as
 text is inserted and deleted. When a line that has a marker on it is deleted, that marker
 moves to the previous line.
<a id="view.marker_define"></a>
#### `view:marker_define`(*marker*, *symbol*)

Assigns marker symbol *symbol* to marker number *marker*, in the range of `1` to `32`.
*symbol* is shown in marker symbol margins next to lines marked with *marker*.

Parameters:

- *marker*:  The marker number in the range of `1` to `32` to set *symbol* for.
- *symbol*:  The marker symbol: `view.MARK_*`.

See also:

- [`_SCINTILLA.new_marker_number`](#_SCINTILLA.new_marker_number)

<a id="view.marker_define_pixmap"></a>
#### `view:marker_define_pixmap`(*marker*, *pixmap*)

Associates marker number *marker*, in the range of `1` to `32`, with XPM image *pixmap*.
The [`view.MARK_PIXMAP`](#view.MARK_PIXMAP) marker symbol must be assigned to *marker*. *pixmap* is shown in
marker symbol margins next to lines marked with *marker*.

Parameters:

- *marker*:  The marker number in the range of `1` to `32` to define pixmap *pixmap* for.
- *pixmap*:  The string pixmap data.

<a id="view.marker_define_rgba_image"></a>
#### `view:marker_define_rgba_image`(*marker*, *pixels*)

Associates marker number *marker*, in the range of `1` to `32`, with RGBA image *pixels*.
The dimensions for *pixels* ([`view.rgba_image_width`](#view.rgba_image_width) and [`view.rgba_image_height`](#view.rgba_image_height)) must
have already been defined. *pixels* is a sequence of 4 byte pixel values (red, blue, green,
and alpha) defining the image line by line starting at the top-left pixel.
The [`view.MARK_RGBAIMAGE`](#view.MARK_RGBAIMAGE) marker symbol must be assigned to *marker*. *pixels* is shown in
symbol margins next to lines marked with *marker*.

Parameters:

- *marker*:  The marker number in the range of `1` to `32` to define RGBA data *pixels* for.
- *pixels*:  The string sequence of 4 byte pixel values starting with the pixels for the
	top line, with the leftmost pixel first, then continuing with the pixels for subsequent
	lines. There is no gap between lines for alignment reasons. Each pixel consists of, in
	order, a red byte, a green byte, a blue byte and an alpha byte. The color bytes are not
	premultiplied by the alpha value. That is, a fully red pixel that is 25% opaque will be
	`[FF, 00, 00, 3F]`.

See also:

- [`view.rgba_image_scale`](#view.rgba_image_scale)

<a id="buffer.marker_add"></a>
#### `buffer:marker_add`(*line*, *marker*)

Adds marker number *marker*, in the range of `1` to `32`, to line number *line*, returning
the added marker's handle which can be used in [`buffer:marker_delete_handle()`](#buffer.marker_delete_handle) and
[`buffer:marker_line_from_handle()`](#buffer.marker_line_from_handle), or `-1` if *line* is invalid.

Parameters:

- *line*:  The line number to add the marker on.
- *marker*:  The marker number in the range of `1` to `32` to add.

Return:

- number

<a id="buffer.marker_add_set"></a>
#### `buffer:marker_add_set`(*line*, *marker_mask*)

Adds the markers specified in marker bit-mask *marker_mask* to line number *line*.
The first bit is set to add marker number 1, the second bit for marker number 2, and so on
up to marker number 32.

Parameters:

- *line*:  The line number to add the markers on.
- *marker_mask*:  The mask of markers to set. Set the first bit to set marker 1, the second
	bit for marker 2 and so on.

<a id="buffer.marker_delete_handle"></a>
#### `buffer:marker_delete_handle`(*handle*)

Deletes the marker with handle *handle* returned by [`buffer:marker_add()`](#buffer.marker_add).

Parameters:

- *handle*:  The identifier of a marker returned by [`buffer:marker_add()`](#buffer.marker_add).

<a id="buffer.marker_delete"></a>
#### `buffer:marker_delete`(*line*, *marker*)

Deletes marker number *marker*, in the range of `1` to `32`, from line number *line*.
If *marker* is `-1`, deletes all markers from *line*.

Parameters:

- *line*:  The line number to delete the marker on.
- *marker*:  The marker number in the range of `1` to `32` to delete from *line*, or `-1`
	to delete all markers from the line.

<a id="buffer.marker_delete_all"></a>
#### `buffer:marker_delete_all`(*marker*)

Deletes marker number *marker*, in the range of `1` to `32`, from any line that has it.
If *marker* is `-1`, deletes all markers from all lines.

Parameters:

- *marker*:  The marker number in the range of `1` to `32` to delete from all lines, or
	`-1` to delete all markers from all lines.

<a id="buffer.marker_line_from_handle"></a>
#### `buffer:marker_line_from_handle`(*handle*)

Returns the line number of the line that contains the marker with handle *handle* (returned
[`buffer:marker_add()`](#buffer.marker_add)), or `-1` if the line was not found.

Parameters:

- *handle*:  The identifier of a marker returned by [`buffer:marker_add()`](#buffer.marker_add).

Return:

- number

<a id="buffer.marker_next"></a>
#### `buffer:marker_next`(*line*, *marker_mask*)

Returns the first line number, starting at line number *line*, that contains all of the
markers represented by marker bit-mask *marker_mask*.
Returns `-1` if no line was found.
The first bit is set if marker 1 is set, the second bit for marker 2, etc., up to marker 32.

Parameters:

- *line*:  The start line to search from.
- *marker_mask*:  The mask of markers to find. Set the first bit to find marker 1, the
	second bit for marker 2, and so on.

Return:

- number

<a id="buffer.marker_previous"></a>
#### `buffer:marker_previous`(*line*, *marker_mask*)

Returns the last line number, before or on line number *line*, that contains all of the
markers represented by marker bit-mask *marker_mask*.
Returns `-1` if no line was found.
The first bit is set if marker 1 is set, the second bit for marker 2, etc., up to marker 32.

Parameters:

- *line*:  The start line to search from.
- *marker_mask*:  The mask of markers to find. Set the first bit to find marker 1, the
	second bit for marker 2, and so on.

Return:

- number

<a id="buffer.marker_handle_from_line"></a>
#### `buffer:marker_handle_from_line`(*line*, *n*)

Returns the handle of the *n*th marker on line number *line*, or `-1` if no such marker exists.

Parameters:

- *line*:  The line number to get markers on.
- *n*:  The marker to get the handle of.

<a id="buffer.marker_get"></a>
#### `buffer:marker_get`(*line*)

Returns a bit-mask that represents the markers on line number *line*.
The first bit is set if marker number 1 is present, the second bit for marker number 2,
and so on.

Parameters:

- *line*:  The line number to get markers on.

Return:

- number

<a id="buffer.marker_number_from_line"></a>
#### `buffer:marker_number_from_line`(*line*, *n*)

Returns the number of the *n*th marker on line number *line*, or `-1` if no such marker exists.

Parameters:

- *line*:  The line number to get markers on.
- *n*:  The marker to get the number of.

<a id="view.marker_symbol_defined"></a>
#### `view:marker_symbol_defined`(*marker*)

Returns the symbol assigned to marker number *marker*, in the range of `1` to `32`, used in
[`view:marker_define()`](#view.marker_define),
[`view:marker_define_pixmap()`](#view.marker_define_pixmap), or [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image).

Parameters:

- *marker*:  The marker number in the range of `1` to `32` to get the symbol of.

Return:

- number

<a id="view.marker_fore"></a>
#### `view.marker_fore` &lt;table&gt;

List of foreground colors, in "0xBBGGRR" format, of marker numbers from `1` to
`32`. (Write-only)

<a id="view.marker_fore_translucent"></a>
#### `view.marker_fore_translucent` &lt;table&gt;

List of foreground colors, in "0xAABBGGRR" format, of marker numbers from `1` to
`32`. (Write-only)

<a id="view.marker_back"></a>
#### `view.marker_back` &lt;table&gt;

List of background colors, in "0xBBGGRR" format, of marker numbers from `1` to
`32`. (Write-only)

<a id="view.marker_back_translucent"></a>
#### `view.marker_back_translucent` &lt;table&gt;

List of background colors, in "0xAABBGGRR" format, of marker numbers from `1` to `32`.

<a id="view.marker_alpha"></a>
#### `view.marker_alpha` &lt;table&gt;

List of alpha values, ranging from `0` (transparent) to `255` (opaque), of markers drawn in
the text area (not the margin) for markers numbers from `1` to `32`. (Write-only)
The default values are [`view.ALPHA_NOALPHA`](#view.ALPHA_NOALPHA), for no alpha.

<a id="view.marker_enable_highlight"></a>
#### `view:marker_enable_highlight`(*enabled*)

Highlights the margin fold markers for the current fold block if *enabled* is `true`.

Parameters:

- *enabled*:  Whether or not to enable highlight.

<a id="view.marker_back_selected"></a>
#### `view.marker_back_selected` &lt;table&gt;

List of background colors, in "0xBBGGRR" format, of markers whose folding blocks are selected
for marker numbers from `1` to `32`. (Write-only)

<a id="view.marker_back_selected_translucent"></a>
#### `view.marker_back_selected_translucent` &lt;table&gt;

List of background colors, in "0xAABBGGRR" format, of markers whose folding blocks are
selected for marker numbers from `1` to `32`. (Write-only)

<a id="view.marker_layer"></a>
#### `view.marker_layer` &lt;table&gt;

Table of layer modes for drawing markers in the text area (not the margin) for marker
numbers from `1` to `32`.

- [`view.LAYER_BASE`](#view.LAYER_BASE)
	Draw markers opaquely on the background.
- [`view.LAYER_UNDER_TEXT`](#view.LAYER_UNDER_TEXT)
	Draw markers translucently under text.
- [`view.LAYER_OVER_TEXT`](#view.LAYER_OVER_TEXT)
	Draw markers translucently over text.

The default values are [`view.LAYER_BASE`](#view.LAYER_BASE).

<a id="view.marker_stroke_width"></a>
#### `view.marker_stroke_width` &lt;table&gt;

List of stroke widths in hundredths of a pixel for marker numbers from `1` to `32`. (Write-only)
The default values are `100`, or 1 pixel.

### Annotate Lines


 Lines may be annotated with styled, read-only text displayed underneath them or next to them
 (after the end of line characters, or EOL). This may be useful for displaying compiler errors,
 runtimeerrors, variable values, or other useful information.
<a id="buffer.annotation_text"></a>
#### `buffer.annotation_text` &lt;table&gt;

List of annotation text per line number.

<a id="buffer.eol_annotation_text"></a>
#### `buffer.eol_annotation_text` &lt;table&gt;

List of EOL annotation text per line number.

<a id="buffer.annotation_style"></a>
#### `buffer.annotation_style` &lt;table&gt;

List of style numbers for annotation text per line number.
Only some style attributes are active in annotations: font, size/size_fractional, bold/weight,
italics, fore, back, and character_set.

<a id="buffer.eol_annotation_style"></a>
#### `buffer.eol_annotation_style` &lt;table&gt;

List of style numbers for EOL annotation text per line number.
Only some style attributes are active in annotations: font, size/size_fractional, bold/weight,
italics, fore, back, and character_set.

<a id="buffer.annotation_clear_all"></a>
#### `buffer:annotation_clear_all`()

Clears annotations from all lines.

<a id="buffer.eol_annotation_clear_all"></a>
#### `buffer:eol_annotation_clear_all`()

Clears EOL annotations from all lines.

<a id="view.annotation_visible"></a>
#### `view.annotation_visible` 

The annotation visibility mode.

- [`view.ANNOTATION_HIDDEN`](#view.ANNOTATION_HIDDEN)
	Annotations are invisible.
- [`view.ANNOTATION_STANDARD`](#view.ANNOTATION_STANDARD)
	Draw annotations left-justified with no decoration.
- [`view.ANNOTATION_BOXED`](#view.ANNOTATION_BOXED)
	Indent annotations to match the annotated text and outline them with a box.
- [`view.ANNOTATION_INDENTED`](#view.ANNOTATION_INDENTED)
	Indent non-decorated annotations to match the annotated text.

The default value is [`view.ANNOTATION_BOXED`](#view.ANNOTATION_BOXED).

<a id="view.eol_annotation_visible"></a>
#### `view.eol_annotation_visible` 

The EOL annotation visibility mode.

- [`view.EOLANNOTATION_HIDDEN`](#view.EOLANNOTATION_HIDDEN)
	EOL Annotations are invisible.
- [`view.EOLANNOTATION_STANDARD`](#view.EOLANNOTATION_STANDARD)
	Draw EOL annotations no decoration.
- [`view.EOLANNOTATION_BOXED`](#view.EOLANNOTATION_BOXED)
	Draw EOL annotations outlined with a box.
- [`view.EOLANNOTATION_STADIUM`](#view.EOLANNOTATION_STADIUM)
	Draw EOL annotations outline with curved ends.
- [`view.EOLANNOTATION_FLAT_CIRCLE`](#view.EOLANNOTATION_FLAT_CIRCLE)
	Draw EOL annotations outline with a flat left end and curved right end.
- [`view.EOLANNOTATION_ANGLE_CIRCLE`](#view.EOLANNOTATION_ANGLE_CIRCLE)
	Draw EOL annotations outline with an angled left end and curved right end.
- [`view.EOLANNOTATION_CIRCLE_FLAT`](#view.EOLANNOTATION_CIRCLE_FLAT)
	Draw EOL annotations outline with a curved left end and flat right end.
- [`view.EOLANNOTATION_FLATS`](#view.EOLANNOTATION_FLATS)
	Draw EOL annotations outline with a flat ends.
- [`view.EOLANNOTATION_ANGLE_FLAT`](#view.EOLANNOTATION_ANGLE_FLAT)
	Draw EOL annotations outline with an angled left end and flat right end.
- [`view.EOLANNOTATION_CIRCLE_ANGLE`](#view.EOLANNOTATION_CIRCLE_ANGLE)
	Draw EOL annotations outline with a curved left end and angled right end.
- [`view.EOLANNOTATION_FLAT_ANGLE`](#view.EOLANNOTATION_FLAT_ANGLE)
	Draw EOL annotations outline with a flat left end and angled right end.
- [`view.EOLANNOTATION_ANGLES`](#view.EOLANNOTATION_ANGLES)
	Draw EOL annotations outline with angled ends.

All annotations are drawn with the same shape. The default value is
[`view.EOLANNOTATION_BOXED`](#view.EOLANNOTATION_BOXED).

<a id="buffer.annotation_lines"></a>
#### `buffer.annotation_lines` &lt;table&gt;

List of the number of annotation text lines per line number. (Read-only)

### Mark Text with Indicators


 Indicators have an assigned indicator style and are displayed along with any existing
 styles text may already have. They can be hovered over and clicked on. Indicators move along
 with text.
<a id="view.indic_style"></a>
#### `view.indic_style` &lt;table&gt;

List of styles for indicator numbers from `1` to `32`.

- [`view.INDIC_PLAIN`](#view.INDIC_PLAIN)
	An underline.
- [`view.INDIC_SQUIGGLE`](#view.INDIC_SQUIGGLE)
	A squiggly underline 3 pixels in height.
- [`view.INDIC_TT`](#view.INDIC_TT)
	An underline of small 'T' shapes.
- [`view.INDIC_DIAGONAL`](#view.INDIC_DIAGONAL)
	An underline of diagonal hatches.
- [`view.INDIC_STRIKE`](#view.INDIC_STRIKE)
	Strike out.
- [`view.INDIC_HIDDEN`](#view.INDIC_HIDDEN)
	Invisible.
- [`view.INDIC_BOX`](#view.INDIC_BOX)
	A bounding box.
- [`view.INDIC_ROUNDBOX`](#view.INDIC_ROUNDBOX)
	A translucent box with rounded corners around the text. Use [`view.indic_alpha`](#view.indic_alpha) and
	[`view.indic_outline_alpha`](#view.indic_outline_alpha) to set the fill and outline transparency, respectively.
	Their default values are `30` and `50`.
- [`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX)
	Similar to [`view.INDIC_ROUNDBOX`](#view.INDIC_ROUNDBOX) but with sharp corners.
- [`view.INDIC_DASH`](#view.INDIC_DASH)
	A dashed underline.
- [`view.INDIC_DOTS`](#view.INDIC_DOTS)
	A dotted underline.
- [`view.INDIC_SQUIGGLELOW`](#view.INDIC_SQUIGGLELOW)
	A squiggly underline 2 pixels in height.
- [`view.INDIC_DOTBOX`](#view.INDIC_DOTBOX)
	Similar to [`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX) but with a dotted outline. Translucency alternates
	between [`view.indic_alpha`](#view.indic_alpha) and [`view.indic_outline_alpha`](#view.indic_outline_alpha) starting with the top-left pixel.
- [`view.INDIC_SQUIGGLEPIXMAP`](#view.INDIC_SQUIGGLEPIXMAP)
	Identical to [`view.INDIC_SQUIGGLE`](#view.INDIC_SQUIGGLE) but draws faster by using a pixmap instead of multiple
	line segments.
- [`view.INDIC_COMPOSITIONTHICK`](#view.INDIC_COMPOSITIONTHICK)
	A 2-pixel thick underline at the bottom of the line inset by 1 pixel on on either
	side. Similar in appearance to the target in Asian language input composition.
- [`view.INDIC_COMPOSITIONTHIN`](#view.INDIC_COMPOSITIONTHIN)
	A 1-pixel thick underline just before the bottom of the line inset by 1 pixel on either
	side. Similar in appearance to the non-target ranges in Asian language input composition.
- [`view.INDIC_FULLBOX`](#view.INDIC_FULLBOX)
	Similar to [`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX) but extends to the top of its line, potentially
	touching any similar indicators on the line above.
- [`view.INDIC_TEXTFORE`](#view.INDIC_TEXTFORE)
	Changes the color of text to an indicator's foreground color.
- [`view.INDIC_POINT`](#view.INDIC_POINT)
	A triangle below the start of the indicator range.
- [`view.INDIC_POINTCHARACTER`](#view.INDIC_POINTCHARACTER)
	A triangle below the center of the first character of the indicator range.
- [`view.INDIC_GRADIENT`](#view.INDIC_GRADIENT)
	A box with a vertical gradient from solid on top to transparent on bottom.
- [`view.INDIC_GRADIENTCENTER`](#view.INDIC_GRADIENTCENTER)
	A box with a centered gradient from solid in the middle to transparent on the top
	and bottom.
- [`view.INDIC_POINT_TOP`](#view.INDIC_POINT_TOP)
	A triangle above the start of the indicator range.

Use [`_SCINTILLA.new_indic_number()`](#_SCINTILLA.new_indic_number) for custom indicators.
Changing an indicator's style resets that indicator's hover style.

<a id="view.indic_under"></a>
#### `view.indic_under` &lt;table&gt;

List of flags that indicate whether or not to draw indicators behind text instead of over
the top of it for indicator numbers from `1` to `32`.
The default values are `false`.

<a id="view.indic_hover_style"></a>
#### `view.indic_hover_style` &lt;table&gt;

List of hover styles for indicators numbers from `1` to `32`.
An indicator's hover style drawn when either the cursor hovers over that indicator or the
caret is within that indicator.
The default values are the respective indicator styles.

<a id="buffer.indicator_current"></a>
#### `buffer.indicator_current` 

The indicator number in the range of `1` to `32` used by [`buffer:indicator_fill_range()`](#buffer.indicator_fill_range)
and [`buffer:indicator_clear_range()`](#buffer.indicator_clear_range).

<a id="buffer.indicator_fill_range"></a>
#### `buffer:indicator_fill_range`(*pos*, *length*)

Fills the range of text from position *pos* to *pos* + *length* with indicator number
[`buffer.indicator_current`](#buffer.indicator_current).

Parameters:

- *pos*:  The start position of the range of text in *buffer* to set indicators over.
- *length*:  The number of characters in the range of text to set indicators over.

<a id="buffer.indicator_clear_range"></a>
#### `buffer:indicator_clear_range`(*pos*, *length*)

Clears indicator number [`buffer.indicator_current`](#buffer.indicator_current) over the range of text from position *pos*
to *pos* + *length*.

Parameters:

- *pos*:  The start position of the range of text in *buffer* to clear indicators over.
- *length*:  The number of characters in the range of text to clear indicators over.

<a id="buffer.indicator_start"></a>
#### `buffer:indicator_start`(*indicator*, *pos*)

Returns the previous boundary position, starting from position *pos*, of indicator number
*indicator*, in the range of `1` to `32`.
Returns `1` if *indicator* was not found.

Parameters:

- *indicator*:  An indicator number in the range of `1` to `32`.
- *pos*:  The position in *buffer* of the indicator.

<a id="buffer.indicator_end"></a>
#### `buffer:indicator_end`(*indicator*, *pos*)

Returns the next boundary position, starting from position *pos*, of indicator number
*indicator*, in the range of `1` to `32`.
Returns `1` if *indicator* was not found.

Parameters:

- *indicator*:  An indicator number in the range of `1` to `32`.
- *pos*:  The position in *buffer* of the indicator.

<a id="buffer.indicator_all_on_for"></a>
#### `buffer:indicator_all_on_for`(*pos*)

Returns a bit-mask that represents which indicators are on at position *pos*.
The first bit is set if indicator 1 is on, the second bit for indicator 2, etc.

Parameters:

- *pos*:  The position in *buffer* to get indicators at.

Return:

- number

<a id="view.indic_fore"></a>
#### `view.indic_fore` &lt;table&gt;

List of foreground colors, in "0xBBGGRR" format, for indicator numbers from `1` to `32`.
Changing an indicator's foreground color resets that indicator's hover foreground color.

<a id="view.indic_alpha"></a>
#### `view.indic_alpha` &lt;table&gt;

List of fill color alpha values, ranging from `0` (transparent) to `255` (opaque),
for indicator numbers from `1` to `32` whose styles are either [`view.INDIC_ROUNDBOX`](#view.INDIC_ROUNDBOX),
[`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX), or [`view.INDIC_DOTBOX`](#view.INDIC_DOTBOX).
The default values are [`view.ALPHA_NOALPHA`](#view.ALPHA_NOALPHA), for no alpha.

<a id="view.indic_outline_alpha"></a>
#### `view.indic_outline_alpha` &lt;table&gt;

List of outline color alpha values, ranging from `0` (transparent) to `255` (opaque),
for indicator numbers from `1` to `32` whose styles are either [`view.INDIC_ROUNDBOX`](#view.INDIC_ROUNDBOX),
[`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX), or [`view.INDIC_DOTBOX`](#view.INDIC_DOTBOX).
The default values are [`view.ALPHA_NOALPHA`](#view.ALPHA_NOALPHA), for no alpha.

<a id="view.indic_hover_fore"></a>
#### `view.indic_hover_fore` &lt;table&gt;

List of hover foreground colors, in "0xBBGGRR" format, for indicator numbers from `1` to `32`.
The default values are the respective indicator foreground colors.

<a id="view.indic_stroke_width"></a>
#### `view.indic_stroke_width` &lt;table&gt;

List of stroke widths in hundredths of a pixel for indicator numbers from `1` to `32`
whose styles are either [`view.INDIC_PLAIN`](#view.INDIC_PLAIN), [`view.INDIC_SQUIGGLE`](#view.INDIC_SQUIGGLE), [`view.INDIC_TT`](#view.INDIC_TT),
[`view.INDIC_DIAGONAL`](#view.INDIC_DIAGONAL), [`view.INDIC_STRIKE`](#view.INDIC_STRIKE), [`view.INDIC_BOX`](#view.INDIC_BOX), [`view.INDIC_ROUNDBOX`](#view.INDIC_ROUNDBOX),
[`view.INDIC_STRAIGHTBOX`](#view.INDIC_STRAIGHTBOX), [`view.INDIC_FULLBOX`](#view.INDIC_FULLBOX), [`view.INDIC_DASH`](#view.INDIC_DASH), [`view.INDIC_DOTS`](#view.INDIC_DOTS),  or
[`view.INDIC_SQUIGGLELOW`](#view.INDIC_SQUIGGLELOW).
The default values are `100`, or 1 pixel.

### Display an Autocompletion List


 There are two types of lists: autocompletion lists and user lists. An autocompletion list
 is a list of completions shown for the current word. A user list is a more general list of
 options presented to the user. Both list types update as the user types, have similar behavior
 options, and may [display images](#display-images-in-lists) alongside text. Autocompletion
 lists should define a separator character and order before showing the list. User lists should
 define a separator character, order, and identifier number before showing the list. When a
 list item is selected, an autocompletion list inserts it while a user list emits an event
<a id="buffer.auto_c_separator"></a>
#### `buffer.auto_c_separator` 

The byte value of the character that separates autocompletion and user list list items.
The default value is `32` (' ').

<a id="buffer.auto_c_order"></a>
#### `buffer.auto_c_order` 

The order setting for autocompletion and user lists.

- [`buffer.ORDER_PRESORTED`](#buffer.ORDER_PRESORTED)
	Lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show) are in sorted, alphabetical order.
- [`buffer.ORDER_PERFORMSORT`](#buffer.ORDER_PERFORMSORT)
	Sort autocompletion lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show).
- [`buffer.ORDER_CUSTOM`](#buffer.ORDER_CUSTOM)
	Lists passed to [`buffer:auto_c_show()`](#buffer.auto_c_show) are already in a custom order.

	The default value is [`buffer.ORDER_PRESORTED`](#buffer.ORDER_PRESORTED).

<a id="buffer.auto_c_show"></a>
#### `buffer:auto_c_show`(*len_entered*, *items*)

Displays an autocompletion list constructed from string *items* (whose items are delimited by
[`buffer.auto_c_separator`](#buffer.auto_c_separator) characters) using *len_entered* number of characters behind the
caret as the prefix of the word to be autocompleted.
The sorted order of *items* ([`buffer.auto_c_order`](#buffer.auto_c_order)) must have already been defined.

Parameters:

- *len_entered*:  The number of characters before the caret used to provide the context.
- *items*:  The sorted string of words to show, separated by [`buffer.auto_c_separator`](#buffer.auto_c_separator)
	characters (initially spaces).

See also:

- [`textadept.editing.autocompleters`](#textadept.editing.autocompleters)
- [`textadept.editing.autocomplete`](#textadept.editing.autocomplete)

<a id="buffer.user_list_show"></a>
#### `buffer:user_list_show`(*id*, *items*)

Displays a user list identified by list identifier number *id* and constructed from string
*items* (whose items are delimited by [`buffer.auto_c_separator`](#buffer.auto_c_separator) characters).
The sorted order of *items* ([`buffer.auto_c_order`](#buffer.auto_c_order)) must have already been defined. When
the user selects an item, *id* is sent in an [`events.USER_LIST_SELECTION`](#events.USER_LIST_SELECTION) event along with
the selection.

Parameters:

- *id*:  The list identifier number greater than zero to use.
- *items*:  The sorted string of words to show, separated by [`buffer.auto_c_separator`](#buffer.auto_c_separator)
	characters (initially spaces).

See also:

- [`_SCINTILLA.new_user_list_type`](#_SCINTILLA.new_user_list_type)

<a id="buffer.auto_c_select"></a>
#### `buffer:auto_c_select`(*prefix*)

Selects the first item that starts with string *prefix* in an autocompletion or user list,
using the case sensitivity setting [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case).

Parameters:

- *prefix*:  The item in the list to select.

<a id="buffer.auto_c_complete"></a>
#### `buffer:auto_c_complete`()

Completes the current word with the one selected in an autocompletion list.

<a id="buffer.auto_c_cancel"></a>
#### `buffer:auto_c_cancel`()

Cancels the displayed autocompletion or user list.

<a id="buffer.auto_c_active"></a>
#### `buffer:auto_c_active`()

Returns whether or not an autocompletion or user list is visible.

Return:

- bool

<a id="buffer.auto_c_pos_start"></a>
#### `buffer:auto_c_pos_start`()

Returns the position where autocompletion started or where a user list was shown.

Return:

- number

<a id="buffer.auto_c_current"></a>
#### `buffer.auto_c_current` 

The index of the currently selected item in an autocompletion or user list. (Read-only)

<a id="buffer.auto_c_current_text"></a>
#### `buffer.auto_c_current_text` 

The text of the currently selected item in an autocompletion or user list. (Read-only)

<a id="buffer.auto_c_choose_single"></a>
#### `buffer.auto_c_choose_single` 

Automatically choose the item in a single-item autocompletion list.
This option has no effect for a user list.
The default value is `true`.

<a id="buffer.auto_c_fill_ups"></a>
#### `buffer.auto_c_fill_ups` 

The set of characters that choose the currently selected item in an autocompletion or user
list when the user types one of them. (Write-only)
The default value is `''`.

<a id="buffer.auto_c_stops"></a>
#### `buffer:auto_c_stops`(*chars*)

Allows the user to type any character in string set *chars* in order to cancel an
autocompletion or user list.
The default set is empty.

Parameters:

- *chars*:  The string of characters that cancel autocompletion. This string is empty
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

The behavior mode for a case insensitive autocompletion or user list when
[`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`.

- [`buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`](#buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE)
	Prefer to select case-sensitive matches.
- [`buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE`](#buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE)
	No preference.

	The default value is [`buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`](#buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE).

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

The multiple selection autocomplete mode.

- [`buffer.MULTIAUTOC_ONCE`](#buffer.MULTIAUTOC_ONCE)
	Autocomplete into only the main selection.
- [`buffer.MULTIAUTOC_EACH`](#buffer.MULTIAUTOC_EACH)
	Autocomplete into all selections.

	The default value is [`buffer.MULTIAUTOC_EACH`](#buffer.MULTIAUTOC_EACH).

### Display Images in Lists


 Autocompletion and user lists can render images next to items by appending to each list
 item the type separator character specific to lists followed by an image's type number,
 which uniquely identifies a registered image.
<a id="view.register_image"></a>
#### `view:register_image`(*type*, *xpm_data*)

Registers XPM image *xpm_data* to type number *type* for use in autocompletion and user lists.

Parameters:

- *type*:  Integer type to register the image with.
- *xpm_data*:  The XPM data as described in [`view:marker_define_pixmap()`](#view.marker_define_pixmap).

See also:

- [`_SCINTILLA.new_image_type`](#_SCINTILLA.new_image_type)
- [`textadept.editing.XPM_IMAGES`](#textadept.editing.XPM_IMAGES)

<a id="view.rgba_image_width"></a>
#### `view.rgba_image_width` 

The width of the RGBA image to be defined using [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image) and
[`view:register_rgba_image()`](#view.register_rgba_image).

<a id="view.rgba_image_height"></a>
#### `view.rgba_image_height` 

The height of the RGBA image to be defined using [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image).

<a id="view.rgba_image_scale"></a>
#### `view.rgba_image_scale` 

The scale factor in percent of the RGBA image to be defined using
[`view:marker_define_rgba_image()`](#view.marker_define_rgba_image).
This is useful on macOS with a retina display where each display unit is 2 pixels: use a
factor of `200` so that each image pixel is displayed using a screen pixel.
The default scale, `100`, will stretch each image pixel to cover 4 screen pixels on a
retina display.

<a id="view.register_rgba_image"></a>
#### `view:register_rgba_image`(*type*, *pixels*)

Registers RGBA image *pixels* to type number *type* for use in autocompletion and user lists.
The dimensions for *pixels* ([`view.rgba_image_width`](#view.rgba_image_width) and [`view.rgba_image_height`](#view.rgba_image_height)) must
have already been defined. *pixels* is a sequence of 4 byte pixel values (red, blue, green,
and alpha) defining the image line by line starting at the top-left pixel.

Parameters:

- *type*:  Integer type to register the image with.
- *pixels*:  The RGBA data as described in [`view:marker_define_rgba_image()`](#view.marker_define_rgba_image).

<a id="buffer.auto_c_type_separator"></a>
#### `buffer.auto_c_type_separator` 

The character byte that separates autocompletion and user list items and their image types.
Autocompletion and user list items can display both an image and text. Register images and
their types using [`view:register_image()`](#view.register_image) or [`view:register_rgba_image()`](#view.register_rgba_image) before appending
image types to list items after type separator characters.
The default value is 63 ('?').

<a id="view.clear_registered_images"></a>
#### `view:clear_registered_images`()

Clears all images registered using [`view:register_image()`](#view.register_image) and [`view:register_rgba_image()`](#view.register_rgba_image).

### Show a Call Tip


 A call tip is a small pop-up window that conveys a piece of textual information, such as the
 arguments and documentation for a function. A call tip may highlight a range of text inside
 of itself, such as the current argument in a function call.
<a id="view.call_tip_show"></a>
#### `view:call_tip_show`(*pos*, *text*)

Displays a call tip at position *pos* with string *text* as the call tip's contents.
Any "\001" or "\002" bytes in *text* are replaced by clickable up or down arrow visuals,
respectively. These may be used to indicate that a symbol has more than one call tip,
for example.

Parameters:

- *pos*:  The position in *view*'s buffer to show a call tip at.
- *text*:  The call tip text to show.

<a id="view.call_tip_set_hlt"></a>
#### `view:call_tip_set_hlt`(*start_pos*, *end_pos*)

Highlights a call tip's text between positions *start_pos* to *end_pos* with the color
[`view.call_tip_fore_hlt`](#view.call_tip_fore_hlt).

Parameters:

- *start_pos*:  The start position in a call tip text to highlight.
- *end_pos*:  The end position in a call tip text to highlight.

<a id="view.call_tip_cancel"></a>
#### `view:call_tip_cancel`()

Removes the displayed call tip from view.

<a id="view.call_tip_active"></a>
#### `view:call_tip_active`()

Returns whether or not a call tip is visible.

Return:

- bool

<a id="view.call_tip_pos_start"></a>
#### `view:call_tip_pos_start`()

Returns a call tip's display position.

Return:

- number

<a id="view.call_tip_position"></a>
#### `view.call_tip_position` 

Display a call tip above the current line instead of below it.
The default value is `false`.

<a id="view.call_tip_use_style"></a>
#### `view.call_tip_use_style` 

The pixel width of tab characters in call tips.
When non-zero, also enables the use of style number [`view.STYLE_CALLTIP`](#view.STYLE_CALLTIP) instead of
[`view.STYLE_DEFAULT`](#view.STYLE_DEFAULT) for call tip styles.
The default value is depends on [`buffer.tab_width`](#buffer.tab_width) and the current font.

<a id="view.call_tip_pos_start"></a>
#### `view.call_tip_pos_start` 

The position at which backspacing beyond it hides a visible call tip. (Write-only)

<a id="view.call_tip_fore_hlt"></a>
#### `view.call_tip_fore_hlt` 

A call tip's highlighted text foreground color, in "0xBBGGRR" format. (Write-only)

### Fold or Hide Lines


 Code folding allows the user to temporarily hide blocks of source code. The buffer's lexer
 normally determines code fold points that the view denotes with fold margin markers, but
 arbitrary lines may be shown or hidden.
<a id="view.toggle_fold"></a>
#### `view:toggle_fold`(*line*)

Toggles the fold point on line number *line* between expanded (where all of its child lines
are displayed) and contracted (where all of its child lines are hidden).

Parameters:

- *line*:  The line number in *view* to toggle the fold on.

<a id="view.toggle_fold_show_text"></a>
#### `view:toggle_fold_show_text`(*line*, *text*)

Toggles a fold point on line number *line* between expanded (where all of its child lines are
displayed) and contracted (where all of its child lines are hidden), and shows string *text*
next to that line.
*text* is drawn with style number [`view.STYLE_FOLDDISPLAYTEXT`](#view.STYLE_FOLDDISPLAYTEXT).

Parameters:

- *line*:  The line number in *view* to toggle the fold on and display *text* after.
- *text*:  The text to display after the line.

See also:

- [`buffer.set_default_fold_display_text`](#buffer.set_default_fold_display_text)

<a id="view.fold_line"></a>
#### `view:fold_line`(*line*, *action*)

Contracts, expands, or toggles the fold point on line number *line*, depending on *action*.

Parameters:

- *line*:  The line number in *view* to set the fold state for.
- *action*:  The fold action to perform. Valid values are:

 - [`view.FOLDACTION_CONTRACT`](#view.FOLDACTION_CONTRACT)
 - [`view.FOLDACTION_EXPAND`](#view.FOLDACTION_EXPAND)
 - [`view.FOLDACTION_TOGGLE`](#view.FOLDACTION_TOGGLE)

<a id="view.fold_children"></a>
#### `view:fold_children`(*line*, *action*)

Contracts, expands, or toggles the fold point on line number *line*, as well as all of its
children, depending on *action*.

Parameters:

- *line*:  The line number in *view* to set the fold states for.
- *action*:  The fold action to perform. Valid values are:

 - [`view.FOLDACTION_CONTRACT`](#view.FOLDACTION_CONTRACT)
 - [`view.FOLDACTION_EXPAND`](#view.FOLDACTION_EXPAND)
 - [`view.FOLDACTION_TOGGLE`](#view.FOLDACTION_TOGGLE)

<a id="view.fold_all"></a>
#### `view:fold_all`(*action*)

Contracts, expands, or toggles all fold points, depending on *action*.
When toggling, the state of the first fold point determines whether to expand or contract.

Parameters:

- *action*:  The fold action to perform. Valid values are:

 - [`view.FOLDACTION_CONTRACT`](#view.FOLDACTION_CONTRACT)
 - [`view.FOLDACTION_EXPAND`](#view.FOLDACTION_EXPAND)
 - [`view.FOLDACTION_TOGGLE`](#view.FOLDACTION_TOGGLE)
 - [`view.FOLDACTION_CONTRACT_EVERY_LEVEL`](#view.FOLDACTION_CONTRACT_EVERY_LEVEL)

<a id="view.hide_lines"></a>
#### `view:hide_lines`(*start_line*, *end_line*)

Hides the range of lines between line numbers *start_line* to *end_line*.
This has no effect on fold levels or fold flags.

Parameters:

- *start_line*:  The start line of the range of lines in *view* to hide.
- *end_line*:  The end line of the range of lines in *view* to hide.

<a id="view.show_lines"></a>
#### `view:show_lines`(*start_line*, *end_line*)

Shows the range of lines between line numbers *start_line* to *end_line*.
This has no effect on fold levels or fold flags and the first line cannot be hidden.

Parameters:

- *start_line*:  The start line of the range of lines in *view* to show.
- *end_line*:  The end line of the range of lines in *view* to show.

<a id="view.ensure_visible"></a>
#### `view:ensure_visible`(*line*)

Ensures line number *line* is visible by expanding any fold points hiding it.

Parameters:

- *line*:  The line number in *view* to ensure visible.

<a id="view.ensure_visible_enforce_policy"></a>
#### `view:ensure_visible_enforce_policy`(*line*)

Ensures line number *line* is visible by expanding any fold points hiding it based on the
vertical caret policy previously defined in [`view:set_visible_policy()`](#view.set_visible_policy).

Parameters:

- *line*:  The line number in *view* to ensure visible.

<a id="view.set_default_fold_display_text"></a>
#### `view:set_default_fold_display_text`(*text*)

Sets the default fold display text to string *text*.

Parameters:

- *text*:  The text to display by default next to folded lines.

See also:

- [`buffer.toggle_fold_show_text`](#buffer.toggle_fold_show_text)

<a id="view.get_default_fold_display_text"></a>
#### `view:get_default_fold_display_text`()

Returns the default fold display text.

<a id="buffer.fold_level"></a>
#### `buffer.fold_level` &lt;table&gt;

List of fold level bit-masks per line number.
Fold level masks comprise of an integer level combined with any of the following bit flags:

- [`buffer.FOLDLEVELBASE`](#buffer.FOLDLEVELBASE)
	The initial fold level.
- [`buffer.FOLDLEVELWHITEFLAG`](#buffer.FOLDLEVELWHITEFLAG)
	The line is blank.
- [`buffer.FOLDLEVELHEADERFLAG`](#buffer.FOLDLEVELHEADERFLAG)
	The line is a header, or fold point.

<a id="buffer.fold_parent"></a>
#### `buffer.fold_parent` &lt;table&gt;

List of fold point line numbers per child line number. (Read-only)
A line number of `-1` means no line was found.

<a id="buffer.get_last_child"></a>
#### `buffer:get_last_child`(*line*, *level*)

Returns the line number of the last line after line number *line* whose fold level is greater
than *level*.
If *level* is `-1`, returns the level of *line*.

Parameters:

- *line*:  The line number in *buffer* of a header line.
- *level*:  The fold level, or `-1` for the level of *line*.

<a id="view.fold_expanded"></a>
#### `view.fold_expanded` &lt;table&gt;

List of flags per line number that indicate whether or not fold points are expanded for
those line numbers.
Setting expanded fold states does not toggle folds; it only updates fold margin markers. Use
[`view:toggle_fold()`](#view.toggle_fold) instead.

<a id="view.contracted_fold_next"></a>
#### `view:contracted_fold_next`(*line*)

Returns the line number of the next contracted fold point starting from line number *line*,
or `-1` if none exists.

Parameters:

- *line*:  The line number in *view* to start at.

Return:

- number

<a id="view.line_visible"></a>
#### `view.line_visible` &lt;table&gt;

List of flags per line number that indicate whether or not lines are visible for those line
numbers. (Read-only)

<a id="view.all_lines_visible"></a>
#### `view.all_lines_visible` 

Whether or not all lines are visible. (Read-only)

### Scroll the View


<a id="view.x_offset"></a>
#### `view.x_offset` 

The horizontal scroll pixel position.
A value of `0` is the normal position with the first text column visible at the left of
the view.

<a id="view.line_scroll_up"></a>
#### `view:line_scroll_up`()

Scrolls the buffer up one line, keeping the caret visible.

<a id="view.line_scroll_down"></a>
#### `view:line_scroll_down`()

Scrolls the buffer down one line, keeping the caret visible.

<a id="view.line_scroll"></a>
#### `view:line_scroll`(*columns*, *lines*)

Scrolls the buffer right *columns* columns and down *lines* lines.
Negative values are allowed.

Parameters:

- *columns*:  The number of columns to scroll horizontally.
- *lines*:  The number of lines to scroll vertically.

<a id="view.scroll_caret"></a>
#### `view:scroll_caret`()

Scrolls the caret into view based on the policies previously defined in
[`view:set_x_caret_policy()`](#view.set_x_caret_policy) and [`view:set_y_caret_policy()`](#view.set_y_caret_policy).

<a id="view.scroll_range"></a>
#### `view:scroll_range`(*secondary_pos*, *primary_pos*)

Scrolls into view the range of text between positions *primary_pos* and *secondary_pos*,
with priority given to *primary_pos*.
Similar to [`view:scroll_caret()`](#view.scroll_caret), but with *primary_pos* instead of [`buffer.current_pos`](#buffer.current_pos).
This is useful for scrolling search results into view.

Parameters:

- *secondary_pos*:  The secondary range position to scroll into view.
- *primary_pos*:  The primary range position to scroll into view.

<a id="view.vertical_center_caret"></a>
#### `view:vertical_center_caret`()

Centers current line in the view.

<a id="view.scroll_to_start"></a>
#### `view:scroll_to_start`()

Scrolls to the beginning of the buffer without moving the caret.

<a id="view.scroll_to_end"></a>
#### `view:scroll_to_end`()

Scrolls to the end of the buffer without moving the caret.

### Configure Indentation and Line Endings


 Indentation settings and end-of-line characters can be configured on a per-buffer and
 per-file basis.
<a id="buffer.use_tabs"></a>
#### `buffer.use_tabs` 

Use tabs instead of spaces in indentation.
Changing the current setting does not convert any of the buffer's existing indentation. Use
[`textadept.editing.convert_indentation()`](#textadept.editing.convert_indentation) to do so.
The default value is `true`.

<a id="buffer.tab_width"></a>
#### `buffer.tab_width` 

The number of space characters represented by a tab character.
The default value is `8`.

<a id="buffer.indent"></a>
#### `buffer.indent` 

The number of spaces in one level of indentation.
The default value is `0`, which uses the value of [`buffer.tab_width`](#buffer.tab_width).

<a id="buffer.tab_indents"></a>
#### `buffer.tab_indents` 

Indent text when tabbing within indentation.
The default value is `true`.

<a id="buffer.back_space_un_indents"></a>
#### `buffer.back_space_un_indents` 

Un-indent text when backspacing within indentation.
The default value is `true`.

<a id="buffer.eol_mode"></a>
#### `buffer.eol_mode` 

The current end of line mode.
Changing the current mode does not convert any of the buffer's existing end of line
characters. Use [`buffer:convert_eols()`](#buffer.convert_eols) to do so.

- [`buffer.EOL_CRLF`](#buffer.EOL_CRLF)
	Carriage return with line feed ("\r\n").
- [`buffer.EOL_CR`](#buffer.EOL_CR)
	Carriage return ("\r").
- [`buffer.EOL_LF`](#buffer.EOL_LF)
	Line feed ("\n").

	The default value is [`buffer.EOL_CRLF`](#buffer.EOL_CRLF) on Windows platforms, [`buffer.EOL_LF`](#buffer.EOL_LF) otherwise.

<a id="buffer.convert_eols"></a>
#### `buffer:convert_eols`(*mode*)

Converts all end of line characters to those in end of line mode *mode*.

Parameters:

- *mode*:  The end of line mode to convert to. Valid values are:
 - [`buffer.EOL_CRLF`](#buffer.EOL_CRLF)
 - [`buffer.EOL_CR`](#buffer.EOL_CR)
 - [`buffer.EOL_LF`](#buffer.EOL_LF)

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
#### `view.representation` &lt;table&gt;

Map of alternative string representations of characters.
Representations are displayed in the same way control characters are. Use the empty string
for the '\0' character when assigning its representation. Characters are strings, not numeric
codes, and can be multi-byte characters.
Call [`view:clear_representation()`](#view.clear_representation) to remove a representation.

<a id="view.clear_representation"></a>
#### `view:clear_representation`(*char*)

Removes the alternate string representation for character *char* (which may be a multi-byte
character).

Parameters:

- *char*:  The string character in [`view.representation`](#view.representation) to remove the alternate string
	representation for.

<a id="view.clear_all_representations"></a>
#### `view:clear_all_representations`()

Removes all alternate string representations of characters.

<a id="view.representation_appearance"></a>
#### `view.representation_appearance` &lt;table&gt;

Map of characters to their string representation's appearance.

- [`view.REPRESENTATION_PLAIN`](#view.REPRESENTATION_PLAIN)
	Draw the representation with no decoration.
- [`view.REPRESENTATION_BLOB`](#view.REPRESENTATION_BLOB)
	Draw the representation within a rounded rectangle and an inverted color.
- [`view.REPRESENTATION_COLOR`](#view.REPRESENTATION_COLOR)
	Draw the representation using the color set in [`view.representation_color`](#view.representation_color).

The default values are [`view.REPRESENTATION_BLOB`](#view.REPRESENTATION_BLOB).

<a id="view.representation_color"></a>
#### `view.representation_color` &lt;table&gt;

Map of characters to their string representation's color in "0xBBGGRR" format.

### Configure the Color Theme


 Themes are Lua files that define colors, specify how the view displays text, and assign
 colors and alpha values to various view properties. Colors are integers that range
 from 0 to 0xFFFFFF. Alpha transparency values are integers that range from 0 to 255
 (`view.ALPHA_TRANSPARENT` to `view.ALPHA_OPAQUE`), or `view.ALPHA_NOALPHA`.
<a id="view.set_theme"></a>
#### `view:set_theme`([*name*][, *env*])

Sets the view's color theme to be string *name*, with the contents of table *env* available
as global variables.
User themes override Textadept's default themes when they have the same name. If *name*
contains slashes, it is assumed to be an absolute path to a theme instead of a theme name.

Parameters:

- *name*:  Optional string name or absolute path of a theme to set. The default value
	is either 'light' or 'dark', depending on whether light mode or dark mode, respectively,
	is enabled.
- *env*:  Optional table of global variables themes can utilize to override default
	settings such as font and size.

Usage:

- `view:set_theme{font = 'Monospace', size = 12}
`
- `view:set_theme('my_theme', {font = 'Monospace', size = 12})
`

<a id="view.colors"></a>
#### `view.colors` &lt;table&gt;

Map of color name strings to color values in `0xBBGGRR` format.
The contents of this map is typically set by a theme.
Note: for applications running within a terminal emulator, only 16 color values are recognized,
regardless of how many colors a user's terminal actually supports. (A terminal emulator's
settings determines how to actually display these recognized color values, which may end
up being mapped to a completely different color set.) In order to use the light variant of
a color, some terminals require a style's `bold` field must be set along with that normal
color. Recognized color values are black (0x000000), red (0x000080), green (0x008000), yellow
(0x008080), blue (0x800000), magenta (0x800080), cyan (0x808000), white (0xC0C0C0), light black
(0x404040), light red (0x0000FF), light green (0x00FF00), light yellow (0x00FFFF), light blue
(0xFF0000), light magenta (0xFF00FF), light cyan (0xFFFF00), and light white (0xFFFFFF).

<a id="view.styles"></a>
#### `view.styles` &lt;table&gt;

Map of style names to style definition tables.
The contents of this map is typically set by a theme. If you are setting it manually (e.g. via
the command entry), call [`view:set_styles()`](#view.set_styles) to refresh the view and apply the styles.

Style names consist of the following:

- [`view.STYLE_DEFAULT`](#view.STYLE_DEFAULT): The default style all others are based on.
- [`view.STYLE_LINENUMBER`](#view.STYLE_LINENUMBER): The line number margin style.
- [`view.STYLE_CONTROLCHAR`](#view.STYLE_CONTROLCHAR): The style of control character blocks.
- [`view.STYLE_INDENTGUIDE`](#view.STYLE_INDENTGUIDE): The style of indentation guides.
- [`view.STYLE_CALLTIP`](#view.STYLE_CALLTIP): The style of call tip text. Only the `font`, `size`, `fore`, and
	`back` style definition fields are supported.
- [`view.STYLE_FOLDDISPLAYTEXT`](#view.STYLE_FOLDDISPLAYTEXT): The style of text displayed next to folded lines.
- [`lexer.ATTRIBUTE`](#lexer.ATTRIBUTE), [`lexer.BOLD`](#lexer.BOLD), [`lexer.CLASS`](#lexer.CLASS), [`lexer.CODE`](#lexer.CODE), [`lexer.COMMENT`](#lexer.COMMENT),
	[`lexer.CONSTANT`](#lexer.CONSTANT), [`lexer.CONSTANT_BUILTIN`](#lexer.CONSTANT_BUILTIN), [`lexer.EMBEDDED`](#lexer.EMBEDDED), [`lexer.ERROR`](#lexer.ERROR),
	[`lexer.FUNCTION`](#lexer.FUNCTION), [`lexer.FUNCTION_BUILTIN`](#lexer.FUNCTION_BUILTIN), [`lexer.FUNCTION_METHOD`](#lexer.FUNCTION_METHOD), [`lexer.IDENTIFIER`](#lexer.IDENTIFIER),
	[`lexer.ITALIC`](#lexer.ITALIC), [`lexer.KEYWORD`](#lexer.KEYWORD), [`lexer.LABEL`](#lexer.LABEL), [`lexer.LINK`](#lexer.LINK), [`lexer.NUMBER`](#lexer.NUMBER),
	[`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR), [`lexer.REFERENCE`](#lexer.REFERENCE), [`lexer.REGEX`](#lexer.REGEX), [`lexer.STRING`](#lexer.STRING),
	[`lexer.TAG`](#lexer.TAG), [`lexer.TYPE`](#lexer.TYPE), [`lexer.UNDERLINE`](#lexer.UNDERLINE), [`lexer.VARIABLE`](#lexer.VARIABLE), [`lexer.VARIABLE_BUILTIN`](#lexer.VARIABLE_BUILTIN):
	Some common, predefined names many lexers use.
- Some lexers may use their own style names. To see the name of the style under the caret,
	use the "Tools > Show Style" menu item.

Style definition tables may contain the following fields:

- `font`: String font name.
- `size`: Integer font size.
- `bold`: Whether or not the font face is bold. The default value is `false`.
- `weight`: Integer weight or boldness of a font, between 1 and 999.
- `italic`: Whether or not the font face is italic. The default value is `false`.
- `underline`: Whether or not the font face is underlined. The default value is `false`.
- `fore`: Font face foreground color in "0xBBGGRR" format.
- `back`: Font face background color in "0xBBGGRR" format.
- `eol_filled`: Whether or not the background color extends to the end of the line. The
	default value is `false`.
- `case`: Font case: [`view.CASE_UPPER`](#view.CASE_UPPER) for upper, [`view.CASE_LOWER`](#view.CASE_LOWER) for lower, and
	[`view.CASE_MIXED`](#view.CASE_MIXED) for normal, mixed case. The default value is [`view.CASE_MIXED`](#view.CASE_MIXED).
- `visible`: Whether or not the text is visible. The default value is `true`.
- `changeable`: Whether the text is changeable instead of read-only. The default value is
	`true`.

<a id="view.set_styles"></a>
#### `view:set_styles`()

Applies defined styles to the view.
This should be called any time a style in [`view.styles`](#view.styles) changes.

### Override Style Settings


 The color theme normally dictates default styles, but custom fonts, colors, and attributes
 may be applied to styles outside of themes. However, these custom settings must be re-applied
 every time a new buffer or view is created, and every time a lexer is loaded.
<a id="view.style_reset_default"></a>
#### `view:style_reset_default`()

Resets [`view.STYLE_DEFAULT`](#view.STYLE_DEFAULT) to its initial state.

<a id="view.style_clear_all"></a>
#### `view:style_clear_all`()

Reverts all styles to having the same properties as [`view.STYLE_DEFAULT`](#view.STYLE_DEFAULT).

<a id="view.style_font"></a>
#### `view.style_font` &lt;table&gt;

List of string font names of text for style numbers from `1` to `256`.

<a id="view.style_size"></a>
#### `view.style_size` &lt;table&gt;

List of font sizes of text for style numbers from `1` to `256`.

<a id="view.style_fore"></a>
#### `view.style_fore` &lt;table&gt;

List of foreground colors, in "0xBBGGRR" format, of text for style numbers from `1` to `256`.

<a id="view.style_back"></a>
#### `view.style_back` &lt;table&gt;

List of background colors, in "0xBBGGRR" format, of text for style numbers from `1` to `256`.

<a id="view.style_bold"></a>
#### `view.style_bold` &lt;table&gt;

List of flags that indicate whether or not text is bold for style numbers from `1` to `256`.
The default values are `false`.

<a id="view.style_italic"></a>
#### `view.style_italic` &lt;table&gt;

List of flags that indicate whether or not text is italic for style numbers from `1` to `256`.
The default values are `false`.

<a id="view.style_underline"></a>
#### `view.style_underline` &lt;table&gt;

List of flags that indicate whether or not text is underlined for style numbers from `1` to
`256`.
The default values are `false`.

<a id="view.style_eol_filled"></a>
#### `view.style_eol_filled` &lt;table&gt;

List of flags that indicate whether or not the background colors of styles whose characters
occur last on lines extend all the way to the view's right margin for style numbers from
`1` to `256`.
The default values are `false`.

<a id="view.style_case"></a>
#### `view.style_case` &lt;table&gt;

List of letter case modes of text for style numbers from `1` to `256`.

- [`view.CASE_MIXED`](#view.CASE_MIXED)
	Display text in normally.
- [`view.CASE_UPPER`](#view.CASE_UPPER)
	Display text in upper case.
- [`view.CASE_LOWER`](#view.CASE_LOWER)
	Display text in lower case.
- [`view.CASE_CAMEL`](#view.CASE_CAMEL)
	Display text in camel case.

The default values are [`view.CASE_MIXED`](#view.CASE_MIXED).

<a id="view.style_visible"></a>
#### `view.style_visible` &lt;table&gt;

List of flags that indicate whether or not text is visible for style numbers from `1` to `256`.
The default values are `true`.

<a id="view.style_changeable"></a>
#### `view.style_changeable` &lt;table&gt;

List of flags that indicate whether or not text is changeable for style numbers from `1` to
`256`.
The default values are `true`.
Read-only styles do not allow the caret into the range of text.

### Assign Caret, Selection, Whitespace, and Line Colors


<a id="view.element_color"></a>
#### `view.element_color` &lt;table&gt;

Map of colors in "0xAABBGGRR" format for UI element identifiers.
If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).

- [`view.ELEMENT_SELECTION_TEXT`](#view.ELEMENT_SELECTION_TEXT)
	The main selection's text color.
- [`view.ELEMENT_SELECTION_BACK`](#view.ELEMENT_SELECTION_BACK)
	The main selection's background color.
- [`view.ELEMENT_SELECTION_ADDITIONAL_TEXT`](#view.ELEMENT_SELECTION_ADDITIONAL_TEXT)
	The text color of additional selections.
- [`view.ELEMENT_SELECTION_ADDITIONAL_BACK`](#view.ELEMENT_SELECTION_ADDITIONAL_BACK)
	The background color of additional selections.
- [`view.ELEMENT_SELECTION_SECONDARY_TEXT`](#view.ELEMENT_SELECTION_SECONDARY_TEXT)
	The text color of selections when another window contains the primary selection.
	This is only available on Linux.
- [`view.ELEMENT_SELECTION_SECONDARY_BACK`](#view.ELEMENT_SELECTION_SECONDARY_BACK)
	The background color of selections when another window contains the primary selection.
	This is only available on Linux.
- [`view.ELEMENT_SELECTION_INACTIVE_TEXT`](#view.ELEMENT_SELECTION_INACTIVE_TEXT)
	The text color of selections when another window has focus.
- [`view.ELEMENT_SELECTION_INACTIVE_BACK`](#view.ELEMENT_SELECTION_INACTIVE_BACK)
	The background color of selections when another window has focus.
- `view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_TEXT`
The text color of additional selections when another window has focus.
- `view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_BACK`
The background color of additional selections when another window has focus.
- [`view.ELEMENT_CARET`](#view.ELEMENT_CARET)
	The main selection's caret color.
- [`view.ELEMENT_CARET_ADDITIONAL`](#view.ELEMENT_CARET_ADDITIONAL)
	The caret color of additional selections.
- [`view.ELEMENT_CARET_LINE_BACK`](#view.ELEMENT_CARET_LINE_BACK)
	The background color of the line that contains the caret.
- [`view.ELEMENT_WHITE_SPACE`](#view.ELEMENT_WHITE_SPACE)
	The color of visible whitespace.
- [`view.ELEMENT_WHITE_SPACE_BACK`](#view.ELEMENT_WHITE_SPACE_BACK)
	The background color of visible whitespace.
- [`view.ELEMENT_FOLD_LINE`](#view.ELEMENT_FOLD_LINE)
	The color of fold lines.
- [`view.ELEMENT_HIDDEN_LINE`](#view.ELEMENT_HIDDEN_LINE)
	The color of lines shown in place of hidden lines.

<a id="view.element_is_set"></a>
#### `view.element_is_set` &lt;table&gt;

Map of flags for UI element identifiers that indicate whether or not a color has been
manually set.

<a id="view.reset_element_color"></a>
#### `view:reset_element_color`(*element*)

Resets the color of UI element *element* to its default color.

Parameters:

- *element*:  One of the UI elements specified in [`view.element_color`](#view.element_color).

<a id="view.element_base_color"></a>
#### `view.element_base_color` &lt;table&gt;

Map of default colors on "0xAABBGGRR" format for UI element identifiers. (Read-only)
If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).

<a id="view.element_allows_translucent"></a>
#### `view.element_allows_translucent` &lt;table&gt;

Map of flags for UI element identifiers that indicate whether or not an element supports
translucent colors.

<a id="view.selection_layer"></a>
#### `view.selection_layer` 

The layer mode for drawing selections.

- [`view.LAYER_BASE`](#view.LAYER_BASE)
	Draw selections opaquely on the background.
- [`view.LAYER_UNDER_TEXT`](#view.LAYER_UNDER_TEXT)
	Draw selections translucently under text.
- [`view.LAYER_OVER_TEXT`](#view.LAYER_OVER_TEXT)
	Draw selections translucently over text.

The default value is [`view.LAYER_BASE`](#view.LAYER_BASE).

### Configure Caret Display


<a id="view.caret_style"></a>
#### `view.caret_style` 

The caret's visual style.

- [`view.CARETSTYLE_INVISIBLE`](#view.CARETSTYLE_INVISIBLE)
	No caret.
- [`view.CARETSTYLE_LINE`](#view.CARETSTYLE_LINE)
	A line caret.
- [`view.CARETSTYLE_BLOCK`](#view.CARETSTYLE_BLOCK)
	A block caret.

Any block setting may be combined with `view.CARETSTYLE_BLOCK_AFTER` via bitwise OR (`|`)
in order to draw the caret after the end of a selection, as opposed to just inside it.

The default value is [`view.CARETSTYLE_LINE`](#view.CARETSTYLE_LINE).

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
[`view.ELEMENT_CARET_LINE_BACK`](#view.ELEMENT_CARET_LINE_BACK) color applies to the frame.
The default value is `0`.

<a id="view.caret_line_highlight_subline"></a>
#### `view.caret_line_highlight_subline` 

Color the background of the subline that contains the caret a different color, rather than
the whole line.
The defalt value is `false`.

<a id="view.caret_line_visible_always"></a>
#### `view.caret_line_visible_always` 

Always show the caret line, even when the view is not in focus.
The default value is `false`, showing the line only when the view is in focus.

<a id="view.caret_line_layer"></a>
#### `view.caret_line_layer` 

The caret line layer mode.

- [`view.LAYER_BASE`](#view.LAYER_BASE)
	Draw the caret line opaquely on the background.
- [`view.LAYER_UNDER_TEXT`](#view.LAYER_UNDER_TEXT)
	Draw the caret line translucently under text.
- [`view.LAYER_OVER_TEXT`](#view.LAYER_OVER_TEXT)
	Draw the caret line translucently over text.

The default value is [`view.LAYER_BASE`](#view.LAYER_BASE).

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

The virtual space mode.

- [`buffer.VS_NONE`](#buffer.VS_NONE)
	Disable virtual space.
- [`buffer.VS_RECTANGULARSELECTION`](#buffer.VS_RECTANGULARSELECTION)
	Enable virtual space only for rectangular selections.
- [`buffer.VS_USERACCESSIBLE`](#buffer.VS_USERACCESSIBLE)
	Enable virtual space.
- [`buffer.VS_NOWRAPLINESTART`](#buffer.VS_NOWRAPLINESTART)
	Prevent the caret from wrapping to the previous line via [`buffer:char_left()`](#buffer.char_left) and
	[`buffer:char_left_extend()`](#buffer.char_left_extend). This option is not restricted to virtual space and should
	be added to any of the above options.

	When virtual space is enabled, the caret may move into the space past end of line characters.
	The default value is [`buffer.VS_NONE`](#buffer.VS_NONE).

### Configure Selection Display


<a id="view.sel_eol_filled"></a>
#### `view.sel_eol_filled` 

Extend the selection to the view's right margin.
The default value is `false`.

### Configure Whitespace Display


 Normally, tab, space, and end of line characters are invisible.
<a id="view.view_ws"></a>
#### `view.view_ws` 

The whitespace visibility mode.

- [`view.WS_INVISIBLE`](#view.WS_INVISIBLE)
	Whitespace is invisible.
- [`view.WS_VISIBLEALWAYS`](#view.WS_VISIBLEALWAYS)
	Display all space characters as dots and tab characters as arrows.
- [`view.WS_VISIBLEAFTERINDENT`](#view.WS_VISIBLEAFTERINDENT)
	Display only non-indentation spaces and tabs as dots and arrows.
- [`view.WS_VISIBLEONLYININDENT`](#view.WS_VISIBLEONLYININDENT)
	Display only indentation spaces and tabs as dots and arrows.

The default value is [`view.WS_INVISIBLE`](#view.WS_INVISIBLE).

<a id="view.whitespace_size"></a>
#### `view.whitespace_size` 

The pixel size of the dots that represent space characters when whitespace is visible.
The default value is `1`.

<a id="view.tab_draw_mode"></a>
#### `view.tab_draw_mode` 

The draw mode of visible tabs.

- [`view.TD_LONGARROW`](#view.TD_LONGARROW)
	An arrow that stretches until the tabstop.
- [`view.TD_STRIKEOUT`](#view.TD_STRIKEOUT)
	A horizontal line that stretches until the tabstop.

The default value is [`view.TD_LONGARROW`](#view.TD_LONGARROW).

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
The default value is `true`.

<a id="view.v_scroll_bar"></a>
#### `view.v_scroll_bar` 

Display the vertical scroll bar.
The default value is `true`.

<a id="view.scroll_width"></a>
#### `view.scroll_width` 

The horizontal scrolling pixel width.
For performance, the view does not measure the display width of the buffer to determine
the properties of the horizontal scroll bar, but uses an assumed width instead. To ensure
the width of the currently visible lines can be scrolled use [`view.scroll_width_tracking`](#view.scroll_width_tracking).
The default value is `2000`.

<a id="view.scroll_width_tracking"></a>
#### `view.scroll_width_tracking` 

Continuously update the horizontal scrolling width to match the maximum width of a displayed
line beyond [`view.scroll_width`](#view.scroll_width).
The default value is `false`.

<a id="view.end_at_last_line"></a>
#### `view.end_at_last_line` 

Disable scrolling past the last line.
The default value is `true`.

<a id="view.set_x_caret_policy"></a>
#### `view:set_x_caret_policy`(*policy*, *x*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *x* number
of pixels away from the horizontal margins.

Parameters:

- *policy*:  The combination of the following policy flags to set:
	- [`view.CARET_SLOP`](#view.CARET_SLOP)
		When the caret goes out of view, scroll the view so the caret is *x* pixels
		away from the right margin.
	- [`view.CARET_STRICT`](#view.CARET_STRICT)
		Scroll the view to ensure the caret stays *x* pixels away from the right margin.
	- [`view.CARET_EVEN`](#view.CARET_EVEN)
		Consider both horizontal margins instead of just the right one.
	- [`view.CARET_JUMPS`](#view.CARET_JUMPS)
		Scroll the view more than usual in order to scroll less often.
- *x*:  The number of pixels from the horizontal margins to keep the caret.

<a id="view.set_y_caret_policy"></a>
#### `view:set_y_caret_policy`(*policy*, *y*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *y* number
of lines away from the vertical margins.

Parameters:

- *policy*:  The combination of the following policy flags to set:
	- [`view.CARET_SLOP`](#view.CARET_SLOP)
		When the caret goes out of view, scroll the view so the caret is *y* lines
		below from the top margin.
	- [`view.CARET_STRICT`](#view.CARET_STRICT)
		Scroll the view to ensure the caret stays *y* lines below from the top margin.
	- [`view.CARET_EVEN`](#view.CARET_EVEN)
		Consider both vertical margins instead of just the top one.
	- [`view.CARET_JUMPS`](#view.CARET_JUMPS)
		Scroll the view more than usual in order to scroll less often.
- *y*:  The number of lines from the vertical margins to keep the caret.

<a id="view.set_visible_policy"></a>
#### `view:set_visible_policy`(*policy*, *y*)

Defines scrolling policy bit-mask *policy* as the policy for keeping the caret *y* number
of lines away from the vertical margins when [`view:ensure_visible_enforce_policy()`](#view.ensure_visible_enforce_policy) redisplays
hidden or folded lines.
It is similar in operation to [`view:set_y_caret_policy()`](#view.set_y_caret_policy).

Parameters:

- *policy*:  The combination of the following policy flags to set:
	- [`view.VISIBLE_SLOP`](#view.VISIBLE_SLOP)
		When the caret is out of view, scroll the view so the caret is *y* lines away
		from the vertical margins.
	- [`view.VISIBLE_STRICT`](#view.VISIBLE_STRICT)
		Scroll the view to ensure the caret stays a *y* lines away from the vertical
		margins.
- *y*:  The number of lines from the vertical margins to keep the caret.

### Configure Mouse Cursor Display


<a id="view.cursor"></a>
#### `view.cursor` 

The display cursor type.

- [`view.CURSORNORMAL`](#view.CURSORNORMAL)
	The text insert cursor.
- [`view.CURSORARROW`](#view.CURSORARROW)
	The arrow cursor.
- [`view.CURSORWAIT`](#view.CURSORWAIT)
	The wait cursor.
- [`view.CURSORREVERSEARROW`](#view.CURSORREVERSEARROW)
	The reversed arrow cursor.

The default value is [`view.CURSORNORMAL`](#view.CURSORNORMAL).

### Configure Wrapped Line Display


 By default, lines that contain more characters than the view can show do not wrap into view
 and onto sub-lines.
<a id="view.wrap_mode"></a>
#### `view.wrap_mode` 

Long line wrap mode.

- [`view.WRAP_NONE`](#view.WRAP_NONE)
	Long lines are not wrapped.
- [`view.WRAP_WORD`](#view.WRAP_WORD)
	Wrap long lines at word (and style) boundaries.
- [`view.WRAP_CHAR`](#view.WRAP_CHAR)
	Wrap long lines at character boundaries.
- [`view.WRAP_WHITESPACE`](#view.WRAP_WHITESPACE)
	Wrap long lines at word boundaries (ignoring style boundaries).

The default value is [`view.WRAP_NONE`](#view.WRAP_NONE).

<a id="view.wrap_visual_flags"></a>
#### `view.wrap_visual_flags` 

The wrapped line visual flag display mode.

- [`view.WRAPVISUALFLAG_NONE`](#view.WRAPVISUALFLAG_NONE)
	No visual flags.
- [`view.WRAPVISUALFLAG_END`](#view.WRAPVISUALFLAG_END)
	Show a visual flag at the end of a wrapped line.
- [`view.WRAPVISUALFLAG_START`](#view.WRAPVISUALFLAG_START)
	Show a visual flag at the beginning of a sub-line.
- [`view.WRAPVISUALFLAG_MARGIN`](#view.WRAPVISUALFLAG_MARGIN)
	Show a visual flag in the sub-line's line number margin.

The default value is [`view.WRAPVISUALFLAG_NONE`](#view.WRAPVISUALFLAG_NONE).

<a id="view.wrap_visual_flags_location"></a>
#### `view.wrap_visual_flags_location` 

The wrapped line visual flag location.

- [`view.WRAPVISUALFLAGLOC_DEFAULT`](#view.WRAPVISUALFLAGLOC_DEFAULT)
	Draw a visual flag near the view's right margin.
- [`view.WRAPVISUALFLAGLOC_END_BY_TEXT`](#view.WRAPVISUALFLAGLOC_END_BY_TEXT)
	Draw a visual flag near text at the end of a wrapped line.
- [`view.WRAPVISUALFLAGLOC_START_BY_TEXT`](#view.WRAPVISUALFLAGLOC_START_BY_TEXT)
	Draw a visual flag near text at the beginning of a subline.

The default value is [`view.WRAPVISUALFLAGLOC_DEFAULT`](#view.WRAPVISUALFLAGLOC_DEFAULT).

<a id="view.wrap_start_indent"></a>
#### `view.wrap_start_indent` 

The number of spaces of indentation to display wrapped lines with if
[`view.wrap_indent_mode`](#view.wrap_indent_mode) is [`view.WRAPINDENT_FIXED`](#view.WRAPINDENT_FIXED).
The default value is `0`.

<a id="view.wrap_indent_mode"></a>
#### `view.wrap_indent_mode` 

The wrapped line indent mode.

- [`view.WRAPINDENT_FIXED`](#view.WRAPINDENT_FIXED)
	Indent wrapped lines by [`view.wrap_start_indent`](#view.wrap_start_indent).
- [`view.WRAPINDENT_SAME`](#view.WRAPINDENT_SAME)
	Indent wrapped lines the same amount as the first line.
- [`view.WRAPINDENT_INDENT`](#view.WRAPINDENT_INDENT)
	Indent wrapped lines one more level than the level of the first line.
- [`view.WRAPINDENT_DEEPINDENT`](#view.WRAPINDENT_DEEPINDENT)
	Indent wrapped lines two more levels than the level of the first line.

The default value is [`view.WRAPINDENT_FIXED`](#view.WRAPINDENT_FIXED).

### Configure Text Zoom


<a id="view.zoom_in"></a>
#### `view:zoom_in`()

Increases the size of all fonts by one point, up to 20.

<a id="view.zoom_out"></a>
#### `view:zoom_out`()

Decreases the size of all fonts by one point, down to -10.

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

The long line mark mode.

- [`view.EDGE_NONE`](#view.EDGE_NONE)
	Long lines are not marked.
- [`view.EDGE_LINE`](#view.EDGE_LINE)
	Draw a single vertical line whose color is [`view.edge_color`](#view.edge_color) at column [`view.edge_column`](#view.edge_column).
- [`view.EDGE_BACKGROUND`](#view.EDGE_BACKGROUND)
	Change the background color of text after column [`view.edge_column`](#view.edge_column) to [`view.edge_color`](#view.edge_color).
- [`view.EDGE_MULTILINE`](#view.EDGE_MULTILINE)
	Draw vertical lines whose colors and columns are defined by calls to
	[`view:multi_edge_add_line()`](#view.multi_edge_add_line).

<a id="view.multi_edge_add_line"></a>
#### `view:multi_edge_add_line`(*column*, *color*)

Adds a new vertical line at column number *column* with color *color*, in "0xBBGGRR" format.

Parameters:

- *column*:  The column number to add a vertical line at.
- *color*:  The color in "0xBBGGRR" format.

<a id="view.multi_edge_clear_all"></a>
#### `view:multi_edge_clear_all`()

Clears all vertical lines created by [`view:multi_edge_add_line()`](#view.multi_edge_add_line).

<a id="view.multi_edge_column"></a>
#### `view.multi_edge_column` &lt;table&gt;

List of edge column positions per edge column number. (Read-only)
A position of `-1` means no edge column was found.

<a id="view.edge_color"></a>
#### `view.edge_color` 

The color, in "0xBBGGRR" format, of the single edge or background for long lines according to
[`view.edge_mode`](#view.edge_mode).

### Configure Fold Settings and Folded Line Display


<a id="view.folding"></a>
#### `view.folding` 

Whether or not folding is enabled for the lexers that support it.
This option is enabled by default.

<a id="view.fold_compact"></a>
#### `view.fold_compact` 

Whether or not blank lines after an ending fold point are included in that fold.
This option is disabled by default.

<a id="view.fold_on_zero_sum_lines"></a>
#### `view.fold_on_zero_sum_lines` 

Whether or not to mark as a fold point lines that contain both an ending and starting fold
point. For example, `} else {` would be marked as a fold point.
This option is disabled by default. This is an alias for

<a id="view.fold_by_indentation"></a>
#### `view.fold_by_indentation` 

Whether or not to fold based on indentation level if a lexer does not have a folder.
Some lexers automatically enable this option. It is disabled by default.

<a id="view.fold_flags"></a>
#### `view.fold_flags` 

Bit-mask of folding lines to draw in the buffer. (Read-only)

- [`view.FOLDFLAG_NONE`](#view.FOLDFLAG_NONE)
	Do not draw folding lines.
- [`view.FOLDFLAG_LINEBEFORE_EXPANDED`](#view.FOLDFLAG_LINEBEFORE_EXPANDED)
	Draw lines above expanded folds.
- [`view.FOLDFLAG_LINEBEFORE_CONTRACTED`](#view.FOLDFLAG_LINEBEFORE_CONTRACTED)
	Draw lines above collapsed folds.
- [`view.FOLDFLAG_LINEAFTER_EXPANDED`](#view.FOLDFLAG_LINEAFTER_EXPANDED)
	Draw lines below expanded folds.
- [`view.FOLDFLAG_LINEAFTER_CONTRACTED`](#view.FOLDFLAG_LINEAFTER_CONTRACTED)
	Draw lines below collapsed folds.
- [`view.FOLDFLAG_LEVELNUMBERS`](#view.FOLDFLAG_LEVELNUMBERS)
	Show hexadecimal fold levels in line margins.
	This option cannot be combined with [`view.FOLDFLAG_LINESTATE`](#view.FOLDFLAG_LINESTATE).
- [`view.FOLDFLAG_LINESTATE`](#view.FOLDFLAG_LINESTATE)
	Show line state in line margins.
	This option cannot be combined with [`view.FOLDFLAG_LEVELNUMBERS`](#view.FOLDFLAG_LEVELNUMBERS).

The default value is [`view.FOLDFLAG_LINEAFTER_CONTRACTED`](#view.FOLDFLAG_LINEAFTER_CONTRACTED) in the GUI version, and
[`view.FOLDFLAG_NONE`](#view.FOLDFLAG_NONE) in the terminal version.

<a id="view.fold_display_text_style"></a>
#### `view.fold_display_text_style` 

The fold display text mode.

- [`view.FOLDDISPLAYTEXT_HIDDEN`](#view.FOLDDISPLAYTEXT_HIDDEN)
	Fold display text is not shown.
- [`view.FOLDDISPLAYTEXT_STANDARD`](#view.FOLDDISPLAYTEXT_STANDARD)
	Fold display text is shown with no decoration.
- [`view.FOLDDISPLAYTEXT_BOXED`](#view.FOLDDISPLAYTEXT_BOXED)
	Fold display text is shown outlined with a box.

The default value is [`view.FOLDDISPLAYTEXT_BOXED`](#view.FOLDDISPLAYTEXT_BOXED).

### Highlight Matching Braces


<a id="view.brace_bad_light"></a>
#### `view:brace_bad_light`(*pos*)

Highlights the character at position *pos* as an unmatched brace character using the
`'style.bracebad'` style.
Removes highlighting when *pos* is `-1`.

Parameters:

- *pos*:  The position in *view*'s buffer to highlight, or `-1` to remove the highlight.

<a id="view.brace_bad_light_indicator"></a>
#### `view:brace_bad_light_indicator`(*use_indicator*, *indicator*)

Highlights unmatched brace characters with indicator number *indicator*, in the range of
`1` to `32`, instead of the [`view.STYLE_BRACEBAD`](#view.STYLE_BRACEBAD) style if *use_indicator* is `true`.

Parameters:

- *use_indicator*:  Whether or not to use an indicator.
- *indicator*:  The indicator number to use.

<a id="view.brace_highlight"></a>
#### `view:brace_highlight`(*pos1*, *pos2*)

Highlights the characters at positions *pos1* and *pos2* as matching braces using the
`'style.bracelight'` style.
If indent guides are enabled, locates the column with [`buffer.column`](#buffer.column) and sets
[`view.highlight_guide`](#view.highlight_guide) in order to highlight the indent guide.

Parameters:

- *pos1*:  The first position in *view*'s buffer to highlight.
- *pos2*:  The second position in *view*'s buffer to highlight.

<a id="view.brace_highlight_indicator"></a>
#### `view:brace_highlight_indicator`(*use_indicator*, *indicator*)

Highlights matching brace characters with indicator number *indicator*, in the range of `1`
to `32`, instead of the [`view.STYLE_BRACELIGHT`](#view.STYLE_BRACELIGHT) style if *use_indicator* is `true`.

Parameters:

- *use_indicator*:  Whether or not to use an indicator.
- *indicator*:  The indicator number to use.

### Configure Indentation Guide Display


<a id="view.indentation_guides"></a>
#### `view.indentation_guides` 

The indentation guide drawing mode.
Indentation guides are dotted vertical lines that appear within indentation whitespace at
each level of indentation.

- [`view.IV_NONE`](#view.IV_NONE)
	Does not draw any guides.
- [`view.IV_REAL`](#view.IV_REAL)
	Draw guides only within indentation whitespace.
- [`view.IV_LOOKFORWARD`](#view.IV_LOOKFORWARD)
	Draw guides beyond the current line up to the next non-empty line's indentation level,
	but with an additional level if the previous non-empty line is a fold point.
- [`view.IV_LOOKBOTH`](#view.IV_LOOKBOTH)
	Draw guides beyond the current line up to either the indentation level of the previous
	or next non-empty line, whichever is greater.

The default value is [`view.IV_LOOKBOTH`](#view.IV_LOOKBOTH) in the GUI version, and [`view.IV_NONE`](#view.IV_NONE) in the
terminal version.

<a id="view.highlight_guide"></a>
#### `view.highlight_guide` 

The indentation guide column number to also highlight when highlighting matching braces, or
`0` to stop indentation guide highlighting.

### Configure File Types


<a id="buffer.set_lexer"></a>
#### `buffer:set_lexer`([*name*])

Associates string lexer name *name* or the auto-detected lexer name with the buffer.

Parameters:

- *name*:  Optional string lexer name to set. If `nil`, attempts to auto-detect the
	buffer's lexer.

Usage:

- `buffer:set_lexer('lexer_name')
`

See also:

- [`lexer.detect_extensions`](#lexer.detect_extensions)
- [`lexer.detect_patterns`](#lexer.detect_patterns)

<a id="buffer.get_lexer"></a>
#### `buffer:get_lexer`(*current*)

Returns the buffer's lexer name.
If *current* is `true`, returns the name of the lexer under the caret in a multiple-language
lexer.

Parameters:

- *current*:  Whether or not to get the lexer at the current caret position in multi-language
	lexers. The default is `false` and returns the parent lexer.

<a id="buffer.lexer_language"></a>
#### `buffer.lexer_language` 

The buffer's lexer name. (Read-only)
If the lexer is a multi-language lexer, [`buffer:get_lexer()`](#buffer.get_lexer) can obtain the lexer under
the caret.

### Manually Style Text


 Plain text can be manually styled after manually [setting up styles](#override-style-settings).
<a id="buffer.colorize"></a>
#### `buffer:colorize`(*start_pos*, *end_pos*)

Instructs the lexer to style and mark fold points in the range of text between *start_pos*
and *end_pos*.
If *end_pos* is `-1`, styles and marks to the end of the buffer.
This is useful for reprocessing and refreshing a range of text if that range has incorrect
highlighting or incorrect fold points.

Parameters:

- *start_pos*:  The start position of the range of text in *buffer* to process.
- *end_pos*:  The end position of the range of text in *buffer* to process, or `-1` to
	process from *start_pos* to the end of *buffer*.

<a id="buffer.clear_document_style"></a>
#### `buffer:clear_document_style`()

Clears all styling and folding information.

<a id="buffer.start_styling"></a>
#### `buffer:start_styling`(*position*, *unused*)

Begins styling at position *position* with styling bit-mask *style_mask*.
*style_mask* specifies which style bits can be set with [`buffer:set_styling()`](#buffer.set_styling).

Parameters:

- *position*:  The position in *buffer* to start styling at.
- *unused*:  Unused number. `0` can be safely used.

Usage:

- `buffer:start_styling(1, 0)
`

<a id="buffer.set_styling"></a>
#### `buffer:set_styling`(*length*, *style*)

Assigns style number *style*, in the range from `1` to `256`, to the next *length* characters,
starting from the current styling position, and increments the styling position by *length*.
[`buffer:start_styling()`](#buffer.start_styling) should be called before [`buffer:set_styling()`](#buffer.set_styling).

Parameters:

- *length*:  The number of characters to style.
- *style*:  The style number to set.

### Query Style Information


<a id="buffer.style_at"></a>
#### `buffer.style_at` &lt;table&gt;

List of style numbers per position. (Read-only)

<a id="buffer.named_styles"></a>
#### `buffer.named_styles` 

The number of named lexer styles.

<a id="buffer.name_of_style"></a>
#### `buffer:name_of_style`(*style*)

Returns the name of style number *style*, which is between `1` and `256`.
Note that due to an implementation detail, the returned style uses '.' instead of '_'.
When setting styles, the '_' form is preferred.

Parameters:

- *style*:  The style number between `1` and `256` to get the name of.

Return:

- string

<a id="buffer.style_of_name"></a>
#### `buffer:style_of_name`(*style_name*)

Returns the style number associated with string *style_name*, or [`view.STYLE_DEFAULT`](#view.STYLE_DEFAULT) if
*style_name* is not in use.

Parameters:

- *style_name*:  The style name to get the number of.

Return:

- style number, between `1` and `256`.

<a id="buffer.end_styled"></a>
#### `buffer.end_styled` 

The current styling position or the last correctly styled character's position. (Read-only)

### Miscellaneous


<a id="buffer.tab_label"></a>
#### `buffer.tab_label` 

The buffer's tab label in the tab bar. (Write-only)
Textadept sets this automatically based on the buffer's filename or type, and its save status.

<a id="buffer.read_only"></a>
#### `buffer.read_only` 

Whether or not the buffer is read-only.
The default value is `false`.

<a id="buffer.cancel"></a>
#### `buffer:cancel`()

Cancels the active selection mode, autocompletion or user list, call tip, etc.

<a id="buffer.edit_toggle_overtype"></a>
#### `buffer:edit_toggle_overtype`()

Toggles [`buffer.overtype`](#buffer.overtype).

<a id="buffer.overtype"></a>
#### `buffer.overtype` 

Enable overtype mode, where typed characters overwrite existing ones.
The default value is `false`.

<a id="view.idle_styling"></a>
#### `view.idle_styling` 

The idle styling mode.
This mode has no effect when [`view.wrap_mode`](#view.wrap_mode) is on.

- [`view.IDLESTYLING_NONE`](#view.IDLESTYLING_NONE)
	Style all the currently visible text before displaying it.
- [`view.IDLESTYLING_TOVISIBLE`](#view.IDLESTYLING_TOVISIBLE)
	Style some text before displaying it and then style the rest incrementally in the
	background as an idle-time task.
- [`view.IDLESTYLING_AFTERVISIBLE`](#view.IDLESTYLING_AFTERVISIBLE)
	Style text after the currently visible portion in the background.
- [`view.IDLESTYLING_ALL`](#view.IDLESTYLING_ALL)
	Style text both before and after the visible text in the background.

	The default value is [`view.IDLESTYLING_ALL`](#view.IDLESTYLING_ALL).

<a id="view.mouse_dwell_time"></a>
#### `view.mouse_dwell_time` 

The number of milliseconds the mouse must idle before generating an [`events.DWELL_START`](#events.DWELL_START) event.
A time of [`view.TIME_FOREVER`](#view.TIME_FOREVER) will never generate one.

<a id="buffer.delete"></a>
#### `buffer:delete`()

Deletes the buffer.
**Do not call this function.** Call [`buffer:close()`](#buffer.close) instead. Emits [`events.BUFFER_DELETED`](#events.BUFFER_DELETED).

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
#### `events.APPLEEVENT_ODOC` 

Emitted when macOS tells Textadept to open a file.
Arguments:

- *uri*: The UTF-8-encoded URI to open.

<a id="events.ARG_NONE"></a>
#### `events.ARG_NONE` 

Emitted when no filename or directory command line arguments are passed to Textadept on startup.

<a id="events.AUTO_C_CANCELED"></a>
#### `events.AUTO_C_CANCELED` 

Emitted when canceling an autocompletion or user list.

<a id="events.AUTO_C_CHAR_DELETED"></a>
#### `events.AUTO_C_CHAR_DELETED` 

Emitted after deleting a character while an autocompletion or user list is active.

<a id="events.AUTO_C_COMPLETED"></a>
#### `events.AUTO_C_COMPLETED` 

Emitted after inserting an item from an autocompletion list into the buffer.
Arguments:

- *text*: The selection's text.
- *position*: The autocompleted word's beginning position.
- *code*: The code of the character from [`buffer.auto_c_fill_ups`](#buffer.auto_c_fill_ups) that made the selection,
	or `0` if no character was used.

<a id="events.AUTO_C_SELECTION"></a>
#### `events.AUTO_C_SELECTION` 

Emitted after selecting an item from an autocompletion list, but before inserting that item
into the buffer.
Automatic insertion can be canceled by calling [`buffer:auto_c_cancel()`](#buffer.auto_c_cancel) before returning
from the event handler.
Arguments:

- *text*: The selection's text.
- *position*: The autocompleted word's beginning position.
- *code*: The code of the character from [`buffer.auto_c_fill_ups`](#buffer.auto_c_fill_ups) that made the selection,
	or `0` if no character was used.

<a id="events.AUTO_C_SELECTION_CHANGE"></a>
#### `events.AUTO_C_SELECTION_CHANGE` 

Emitted as items are highlighted in an autocompletion or user list.
Arguments:

- *id*: Either the *id* from [`buffer:user_list_show()`](#buffer.user_list_show) or `0` for an autocompletion list.
- *text*: The current selection's text.
- *position*: The position the list was displayed at.

<a id="events.BUFFER_AFTER_REPLACE_TEXT"></a>
#### `events.BUFFER_AFTER_REPLACE_TEXT` 

Emitted after replacing the contents of the current buffer.
Note that it is not guaranteed that [`events.BUFFER_BEFORE_REPLACE_TEXT`](#events.BUFFER_BEFORE_REPLACE_TEXT) was emitted previously.
The buffer **must not** be modified during this event.

<a id="events.BUFFER_AFTER_SWITCH"></a>
#### `events.BUFFER_AFTER_SWITCH` 

Emitted right after switching to another buffer.
The buffer being switched to is [`buffer`](#buffer).
Emitted by [`view:goto_buffer()`](#view.goto_buffer).

<a id="events.BUFFER_BEFORE_REPLACE_TEXT"></a>
#### `events.BUFFER_BEFORE_REPLACE_TEXT` 

Emitted before replacing the contents of the current buffer.
Note that it is not guaranteed that [`events.BUFFER_AFTER_REPLACE_TEXT`](#events.BUFFER_AFTER_REPLACE_TEXT) will be emitted
shortly after this event.
The buffer **must not** be modified during this event.

<a id="events.BUFFER_BEFORE_SWITCH"></a>
#### `events.BUFFER_BEFORE_SWITCH` 

Emitted right before switching to another buffer.
The buffer being switched from is [`buffer`](#buffer).
Emitted by [`view:goto_buffer()`](#view.goto_buffer).

<a id="events.BUFFER_DELETED"></a>
#### `events.BUFFER_DELETED` 

Emitted after deleting a buffer.
Emitted by [`buffer:delete()`](#buffer.delete).
Arguments:

- *buffer*: Simple representation of the deleted buffer. Buffer operations cannot be performed
	on it, but fields like [`buffer.filename`](#buffer.filename) can be read.

<a id="events.BUFFER_NEW"></a>
#### `events.BUFFER_NEW` 

Emitted after creating a new buffer.
The new buffer is [`buffer`](#buffer).
Emitted on startup and by `buffer.new()`.

<a id="events.BUILD_OUTPUT"></a>
#### `events.BUILD_OUTPUT` 

Emitted when executing a project's build shell command.
By default, output is printed to the output buffer. In order to override this behavior,
connect to the event with an index of `1` and return `true`.
Arguments:

- *output*: A line of string output from the command.

<a id="events.CALL_TIP_CLICK"></a>
#### `events.CALL_TIP_CLICK` 

Emitted when clicking on a calltip.
This event is not emitted by the Qt version.
Arguments:

- *position*: `1` if the up arrow was clicked, `2` if the down arrow was clicked, and `0`
	otherwise.

<a id="events.CHAR_ADDED"></a>
#### `events.CHAR_ADDED` 

Emitted after the user types a text character into the buffer.
Arguments:

- *code*: The text character's character code.

<a id="events.COMMAND_TEXT_CHANGED"></a>
#### `events.COMMAND_TEXT_CHANGED` 

Emitted when the text in the command entry changes.
`ui.command_entry:get_text()` returns the current text.

<a id="events.COMPILE_OUTPUT"></a>
#### `events.COMPILE_OUTPUT` 

Emitted when executing a language's compile shell command.
By default, compiler output is printed to the output buffer. In order to override this
behavior, connect to the event with an index of `1` and return `true`.
Arguments:

- *output*: A line of string output from the command.

<a id="events.CSI"></a>
#### `events.CSI` 

Emitted when the terminal version receives an unrecognized CSI sequence.
Arguments:

- *cmd*: The 24-bit CSI command value. The lowest byte contains the command byte. The second
	lowest byte contains the leading byte, if any (e.g. '?'). The third lowest byte contains
	the intermediate byte, if any (e.g. '$').
- *args*: Table of numeric arguments of the CSI sequence.

<a id="events.DOUBLE_CLICK"></a>
#### `events.DOUBLE_CLICK` 

Emitted after double-clicking the mouse button.
Arguments:

- *position*: The position double-clicked.
- *line*: The line number of the position double-clicked.
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL),
	[`view.MOD_SHIFT`](#view.MOD_SHIFT), [`view.MOD_ALT`](#view.MOD_ALT), and [`view.MOD_META`](#view.MOD_META). On macOS, the Command modifier
	key is reported as [`view.MOD_CTRL`](#view.MOD_CTRL) and Ctrl is [`view.MOD_META`](#view.MOD_META). Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to [`view.MOD_CTRL`](#view.MOD_CTRL), the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.DWELL_END"></a>
#### `events.DWELL_END` 

Emitted after [`events.DWELL_START`](#events.DWELL_START) when the user moves the mouse, presses a key, or scrolls
the view.
Arguments:

- *position*: The position closest to *x* and *y*.
- *x*: The x-coordinate of the mouse in the view.
- *y*: The y-coordinate of the mouse in the view.

<a id="events.DWELL_START"></a>
#### `events.DWELL_START` 

Emitted when the mouse is stationary for [`view.mouse_dwell_time`](#view.mouse_dwell_time) milliseconds.
Arguments:

- *position*: The position closest to *x* and *y*.
- *x*: The x-coordinate of the mouse in the view.
- *y*: The y-coordinate of the mouse in the view.

<a id="events.ERROR"></a>
#### `events.ERROR` 

Emitted when an error occurs.
Arguments:

- *text*: The error message text.

<a id="events.FILE_AFTER_SAVE"></a>
#### `events.FILE_AFTER_SAVE` 

Emitted right after saving a file to disk.
Emitted by [`buffer:save()`](#buffer.save) and [`buffer:save_as()`](#buffer.save_as).
Arguments:

- *filename*: The filename of the file being saved.
- *saved_as*: Whether or not the file was saved under a different filename.

<a id="events.FILE_BEFORE_SAVE"></a>
#### `events.FILE_BEFORE_SAVE` 

Emitted right before saving a file to disk.
Emitted by [`buffer:save()`](#buffer.save).
Arguments:

- *filename*: The filename of the file being saved.

<a id="events.FILE_CHANGED"></a>
#### `events.FILE_CHANGED` 

Emitted when Textadept detects that an open file was modified externally.
When connecting to this event, connect with an index of 1 in order to override the default
prompt to reload the file.
Arguments:

- *filename*: The filename externally modified.

<a id="events.FILE_OPENED"></a>
#### `events.FILE_OPENED` 

Emitted after opening a file in a new buffer.
Emitted by [`io.open_file()`](#io.open_file).
Arguments:

- *filename*: The opened file's filename.

<a id="events.FIND"></a>
#### `events.FIND` 

Emitted to find text via the Find & Replace Pane.
Arguments:

- *text*: The text to search for.
- *next*: Whether or not to search forward.

<a id="events.FIND_RESULT_FOUND"></a>
#### `events.FIND_RESULT_FOUND` 

Emitted when a result is found. It is selected and has been scrolled into view.
Arguments:

- *find_text*: The text originally searched for.
- *wrapped*: Whether or not the result found is after a text search wrapped.

<a id="events.FIND_TEXT_CHANGED"></a>
#### `events.FIND_TEXT_CHANGED` 

Emitted when the text in the "Find" field of the Find & Replace Pane changes.
[`ui.find.find_entry_text`](#ui.find.find_entry_text) contains the current text.

<a id="events.FIND_WRAPPED"></a>
#### `events.FIND_WRAPPED` 

Emitted when a text search wraps (passes through the beginning of the buffer), either from
bottom to top (when searching for a next occurrence), or from top to bottom (when searching
for a previous occurrence).
This is useful for implementing a more visual or audible notice when a search wraps in
addition to the statusbar message.

<a id="events.FOCUS"></a>
#### `events.FOCUS` 

Emitted when Textadept receives focus.
This event is never emitted when Textadept is running in the terminal.

<a id="events.INDICATOR_CLICK"></a>
#### `events.INDICATOR_CLICK` 

Emitted when clicking the mouse on text that has an indicator present.
Arguments:

- *position*: The clicked text's position.
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL),
	[`view.MOD_SHIFT`](#view.MOD_SHIFT), [`view.MOD_ALT`](#view.MOD_ALT), and [`view.MOD_META`](#view.MOD_META). On macOS, the Command modifier
	key is reported as [`view.MOD_CTRL`](#view.MOD_CTRL) and Ctrl is [`view.MOD_META`](#view.MOD_META). Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to [`view.MOD_CTRL`](#view.MOD_CTRL), the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.INDICATOR_RELEASE"></a>
#### `events.INDICATOR_RELEASE` 

Emitted when releasing the mouse after clicking on text that has an indicator present.
Arguments:

- *position*: The clicked text's position.
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL),
	[`view.MOD_SHIFT`](#view.MOD_SHIFT), [`view.MOD_ALT`](#view.MOD_ALT), and [`view.MOD_META`](#view.MOD_META). On macOS, the Command modifier
	key is reported as [`view.MOD_CTRL`](#view.MOD_CTRL) and Ctrl is [`view.MOD_META`](#view.MOD_META). Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to [`view.MOD_CTRL`](#view.MOD_CTRL), the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.INITIALIZED"></a>
#### `events.INITIALIZED` 

Emitted after Textadept finishes initializing.

<a id="events.KEYPRESS"></a>
#### `events.KEYPRESS` 

Emitted when pressing a recognized key.
If any handler returns `true`, the key is not handled further (e.g. inserted into the buffer).
Arguments:

- *key*: The string representation of the [key sequence](#key-sequences).

<a id="events.LEXER_LOADED"></a>
#### `events.LEXER_LOADED` 

Emitted after loading a language lexer.
This is useful for automatically loading language modules as source files are opened, or
setting up language-specific editing features for source files.
Arguments:

- *name*: The language lexer's name.

<a id="events.MARGIN_CLICK"></a>
#### `events.MARGIN_CLICK` 

Emitted when clicking the mouse inside a sensitive margin.
Arguments:

- *margin*: The margin number clicked.
- *position*: The beginning position of the clicked margin's line.
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL),
	[`view.MOD_SHIFT`](#view.MOD_SHIFT), [`view.MOD_ALT`](#view.MOD_ALT), and [`view.MOD_META`](#view.MOD_META). On macOS, the Command modifier
	key is reported as [`view.MOD_CTRL`](#view.MOD_CTRL) and Ctrl is [`view.MOD_META`](#view.MOD_META). Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to [`view.MOD_CTRL`](#view.MOD_CTRL), the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.MENU_CLICKED"></a>
#### `events.MENU_CLICKED` 

Emitted after selecting a menu item.
Arguments:

- *menu_id*: The numeric ID of the menu item, which was defined in [`ui.menu()`](#ui.menu).

<a id="events.MODE_CHANGED"></a>
#### `events.MODE_CHANGED` 

Emitted by the GUI version when switching between light mode and dark mode.
Arguments:

- *mode*: Either "light" or "dark".

<a id="events.MOUSE"></a>
#### `events.MOUSE` 

Emitted by the terminal version for an unhandled mouse event.
A handler should return `true` if it handled the event. Otherwise Textadept will try again.
(This side effect for a `false` or `nil` return is useful for sending the original mouse
event to a different view that a handler has switched to.)
Arguments:

- *event*: The mouse event: [`view.MOUSE_PRESS`](#view.MOUSE_PRESS), [`view.MOUSE_DRAG`](#view.MOUSE_DRAG), or [`view.MOUSE_RELEASE`](#view.MOUSE_RELEASE).
- *button*: The mouse button number.
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL), [`view.MOD_SHIFT`](#view.MOD_SHIFT),
	and [`view.MOD_ALT`](#view.MOD_ALT).
- *y*: The y-coordinate of the mouse event, starting from 1.
- *x*: The x-coordinate of the mouse event, starting from 1.

<a id="events.QUIT"></a>
#### `events.QUIT` 

Emitted when quitting Textadept.
When connecting to this event, connect with an index of 1 if the handler needs to run before
Textadept closes all open buffers. If a handler returns `true`, Textadept does not quit. It is
not recommended to return `false` from a quit handler, as that may interfere with Textadept's
normal shutdown procedure.
Emitted by [`quit()`](#quit).

<a id="events.REPLACE"></a>
#### `events.REPLACE` 

Emitted to replace selected (found) text.
Arguments:

- *text*: The replacement text.

<a id="events.REPLACE_ALL"></a>
#### `events.REPLACE_ALL` 

Emitted to replace all occurrences of found text.
Arguments:

- *find_text*: The text to search for.
- *repl_text*: The replacement text.

<a id="events.RESET_AFTER"></a>
#### `events.RESET_AFTER` 

Emitted after resetting Textadept's Lua state.
Emitted by [`reset()`](#reset).
Arguments:

- *persist*: Table of data persisted by [`events.RESET_BEFORE`](#events.RESET_BEFORE). All handlers will have access
	to this same table.

<a id="events.RESET_BEFORE"></a>
#### `events.RESET_BEFORE` 

Emitted before resetting Textadept's Lua state.
Emitted by [`reset()`](#reset).
Arguments:

- *persist*: Table to store persistent data in for use by [`events.RESET_AFTER`](#events.RESET_AFTER). All handlers
	will have access to this same table.

<a id="events.RESUME"></a>
#### `events.RESUME` 

Emitted when resuming Textadept from a suspended state.
This event is only emitted by the terminal version.

<a id="events.RUN_OUTPUT"></a>
#### `events.RUN_OUTPUT` 

Emitted when executing a language's or project's run shell command.
By default, output is printed to the output buffer. In order to override this behavior,
connect to the event with an index of `1` and return `true`.
Arguments:

- *output*: A line of string output from the command.

<a id="events.SAVE_POINT_LEFT"></a>
#### `events.SAVE_POINT_LEFT` 

Emitted after leaving a save point.

<a id="events.SAVE_POINT_REACHED"></a>
#### `events.SAVE_POINT_REACHED` 

Emitted after reaching a save point.

<a id="events.SESSION_LOAD"></a>
#### `events.SESSION_LOAD` 

Emitted when loading a session.
Arguments:

- *session*: Table of session data to load. All handlers will have access to this same table.

<a id="events.SESSION_SAVE"></a>
#### `events.SESSION_SAVE` 

Emitted when saving a session.
Arguments:

- *session*: Table of session data to save. All handlers will have access to this same table,
	and Textadept's default handler reserves the use of some keys. Note that functions,
	userdata, and circular table values cannot be saved. The latter case is not recognized
	at all, so beware.

<a id="events.SUSPEND"></a>
#### `events.SUSPEND` 

Emitted prior to suspending Textadept.
This event is only emitted by the terminal version.

<a id="events.TAB_CLICKED"></a>
#### `events.TAB_CLICKED` 

Emitted when the user clicks on a buffer tab.
When connecting to this event, connect with an index of 1 if the handler needs to run before
Textadept switches between buffers.
Note that Textadept always displays a context menu on right-click.
Arguments:

- *index*: The numeric index of the clicked tab.
- *button*: The mouse button number that was clicked, either `1` (left button), `2` (middle
	button), `3` (right button), `4` (wheel up), or `5` (wheel down).
- *modifiers*: A bit-mask of any modifier keys held down: [`view.MOD_CTRL`](#view.MOD_CTRL),
	[`view.MOD_SHIFT`](#view.MOD_SHIFT), [`view.MOD_ALT`](#view.MOD_ALT), and [`view.MOD_META`](#view.MOD_META). On macOS, the Command modifier
	key is reported as [`view.MOD_CTRL`](#view.MOD_CTRL) and Ctrl is [`view.MOD_META`](#view.MOD_META). Note: If you set
	[`view.rectangular_selection_modifier`](#view.rectangular_selection_modifier) to [`view.MOD_CTRL`](#view.MOD_CTRL), the "Control" modifier is
	reported as *both* "Control" and "Alt" due to a Scintilla limitation with GTK.

<a id="events.TAB_CLOSE_CLICKED"></a>
#### `events.TAB_CLOSE_CLICKED` 

Emitted when the user clicks a buffer tab's close button.
When connecting to this event, connect with an index of 1 if the handler needs to run before
Textadept closes the buffer.
This event is only emitted in the Qt GUI version.
Arguments:

- *index*: The numeric index of the clicked tab.

<a id="events.TEST_OUTPUT"></a>
#### `events.TEST_OUTPUT` 

Emitted when executing a project's shell command for running tests.
By default, output is printed to the output buffer. In order to override this behavior,
connect to the event with an index of `1` and return `true`.
Arguments:

- *output*: A line of string output from the command.

<a id="events.UNFOCUS"></a>
#### `events.UNFOCUS` 

Emitted when Textadept loses focus.
This event is never emitted when Textadept is running in the terminal.

<a id="events.UPDATE_UI"></a>
#### `events.UPDATE_UI` 

Emitted after the view is visually updated.
Arguments:

- *updated*: A bitmask of changes since the last update.

	+ [`buffer.UPDATE_CONTENT`](#buffer.UPDATE_CONTENT)
		Buffer contents, styling, or markers have changed.
	+ [`buffer.UPDATE_SELECTION`](#buffer.UPDATE_SELECTION)
		Buffer selection has changed (including caret movement).
	+ [`view.UPDATE_V_SCROLL`](#view.UPDATE_V_SCROLL)
		View has scrolled vertically.
	+ [`view.UPDATE_H_SCROLL`](#view.UPDATE_H_SCROLL)
		View has scrolled horizontally.

<a id="events.URI_DROPPED"></a>
#### `events.URI_DROPPED` 

Emitted after dragging and dropping a URI into a view.
Arguments:

- *text*: The UTF-8-encoded URI dropped.

<a id="events.USER_LIST_SELECTION"></a>
#### `events.USER_LIST_SELECTION` 

Emitted after selecting an item in a user list.
Arguments:

- *id*: The *id* from [`buffer:user_list_show()`](#buffer.user_list_show).
- *text*: The selection's text.
- *position*: The position the list was displayed at.

<a id="events.VIEW_AFTER_SWITCH"></a>
#### `events.VIEW_AFTER_SWITCH` 

Emitted right after switching to another view.
The view being switched to is [`view`](#view).
Emitted by [`ui.goto_view()`](#ui.goto_view).

<a id="events.VIEW_BEFORE_SWITCH"></a>
#### `events.VIEW_BEFORE_SWITCH` 

Emitted right before switching to another view.
The view being switched from is [`view`](#view).
Emitted by [`ui.goto_view()`](#ui.goto_view).

<a id="events.VIEW_NEW"></a>
#### `events.VIEW_NEW` 

Emitted after creating a new view.
The new view is [`view`](#view).
Emitted on startup and by [`view:split()`](#view.split).

<a id="events.ZOOM"></a>
#### `events.ZOOM` 

Emitted after changing [`view.zoom`](#view.zoom).
Emitted by [`view:zoom_in()`](#view.zoom_in) and [`view:zoom_out()`](#view.zoom_out).


### Functions defined by `events`

<a id="events.connect"></a>
#### `events.connect`(*event*, *f*[, *index*])

Adds function *f* to the set of event handlers for event *event* at position *index*.
If *index* not given, appends *f* to the set of handlers. *event* may be any arbitrary string
and does not need to have been previously defined.

Parameters:

- *event*:  The string event name.
- *f*:  The Lua function to connect to *event*.
- *index*:  Optional index to insert the handler into.

Usage:

- `events.connect('my_event', function(msg) ui.print(msg) end)
`

<a id="events.disconnect"></a>
#### `events.disconnect`(*event*, *f*)

Removes function *f* from the set of handlers for event *event*.

Parameters:

- *event*:  The string event name.
- *f*:  The Lua function connected to *event*.

<a id="events.emit"></a>
#### `events.emit`(*event*[, ...])

Sequentially calls all handler functions for event *event* with the given arguments.
*event* may be any arbitrary string and does not need to have been previously defined. If
any handler explicitly returns a value that is not `nil`, `emit()` returns that value and
ceases to call subsequent handlers. This is useful for stopping the propagation of an event
like a keypress after it has been handled, or for passing back values from handlers.

Parameters:

- *event*:  The string event name.
- *...*:  Arguments passed to the handler.

Usage:

- `events.emit('my_event', 'my message')
`

Return:

- `nil` unless any any handler explicitly returned a non-`nil` value; otherwise returns
	that value


---
<a id="io"></a>
## The `io` Module
---

Extends Lua's [`io`](#io) library with Textadept functions for working with files.

### Fields defined by `io`

<a id="io.encodings"></a>
#### `io.encodings` &lt;table&gt;

List of encodings to attempt to decode files as.
The default list contains UTF-8, ASCII, CP1252, and UTF-16.

You should add to this list if you get a "Conversion failed" error when trying to open a file
whose encoding is not recognized. Valid encodings are [GNU iconv's encodings][] and include:

- European: ASCII, ISO-8859-{1,2,3,4,5,7,9,10,13,14,15,16}, KOI8-R,
	KOI8-U, KOI8-RU, CP{1250,1251,1252,1253,1254,1257}, CP{850,866,1131},
	Mac{Roman,CentralEurope,Iceland,Croatian,Romania}, Mac{Cyrillic,Ukraine,Greek,Turkish},
	Macintosh.
- Unicode: UTF-8, UCS-2, UCS-2BE, UCS-2LE, UCS-4, UCS-4BE, UCS-4LE, UTF-16, UTF-16BE,
	UTF-16LE, UTF-32, UTF-32BE, UTF-32LE, UTF-7, C99, JAVA.

[GNU iconv's encodings]: https://www.gnu.org/software/libiconv/

Usage:

- `io.encodings[#io.encodings + 1] = 'UTF-32'
`

<a id="io.ensure_final_newline"></a>
#### `io.ensure_final_newline` 

Whether or not to ensure there is a final newline when saving text files.
This has no effect on binary files.
The default value is `false` on Windows, and `true` on Linux and macOS.

<a id="io.quick_open_filters"></a>
#### `io.quick_open_filters` &lt;table&gt;

Map of directory paths to filters used by [`io.quick_open()`](#io.quick_open).

<a id="io.quick_open_max"></a>
#### `io.quick_open_max` 

The maximum number of files listed in the quick open dialog.
The default value is `5000`.

<a id="io.recent_files"></a>
#### `io.recent_files` &lt;table&gt;

List of recently opened files, the most recent being towards the top.


### Functions defined by `io`

<a id="io.close_all_buffers"></a>
#### `io.close_all_buffers`()

Closes all open buffers, prompting the user to continue if there are unsaved buffers, and
returns `true` if the user did not cancel.
No buffers are saved automatically. They must be saved manually.

Return:

- `true` if user did not cancel; `nil` otherwise.

<a id="io.get_project_root"></a>
#### `io.get_project_root`([*path*][, *submodule*=*false*])

Returns the root directory of the project that contains filesystem path *path*.
In order to be recognized, projects must be under version control. Recognized VCSes are
Bazaar, Fossil, Git, Mercurial, and SVN.

Parameters:

- *path*:  Optional filesystem path to a project or a file contained within a project. The
	default value is the buffer's filename or the current working directory.
- *submodule*:  Optional flag that indicates whether or not to return the root
	of the current submodule (if applicable).

Return:

- string root or nil

<a id="io.open_file"></a>
#### `io.open_file`([*filenames*[, *encodings*]])

Opens *filenames*, a string filename or list of filenames, or the user-selected filename(s).
Emits [`events.FILE_OPENED`](#events.FILE_OPENED).

Parameters:

- *filenames*:  Optional string filename or table of filenames to open. If `nil`,
	the user is prompted with a fileselect dialog.
- *encodings*:  Optional string encoding or table of encodings file contents are in
	(one encoding per file). If `nil`, encoding auto-detection is attempted via [`io.encodings`](#io.encodings).

<a id="io.open_recent_file"></a>
#### `io.open_recent_file`()

Prompts the user to select a recently opened file to be reopened.

See also:

- [`io.recent_files`](#io.recent_files)

<a id="io.quick_open"></a>
#### `io.quick_open`([*paths*[, *filter*]])

Prompts the user to select files to be opened from *paths*, a string directory path or list
of directory paths, using a list dialog.
If *paths* is `nil`, uses the current project's root directory, which is obtained from
[`io.get_project_root()`](#io.get_project_root).
String or list *filter* determines which files to show in the dialog, with the default filter
being `io.quick_open_filters[path]` (if it exists) or [`lfs.default_filter`](#lfs.default_filter). A filter consists
of glob patterns that match file and directory paths to include or exclude. Patterns are
inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are given,
any path is initially considered. As a convenience, '/' also matches the Windows directory
separator ('[/\\]' is not needed).
The number of files in the list is capped at [`io.quick_open_max`](#io.quick_open_max).
If *filter* is `nil` and *paths* is ultimately a string, the filter from the
[`io.quick_open_filters`](#io.quick_open_filters) table is used. If that filter does not exist, [`lfs.default_filter`](#lfs.default_filter)
is used.

Parameters:

- *paths*:  Optional string directory path or table of directory paths to search. The
	default value is the current project's root directory, if available.
- *filter*:  Optional filter for files and directories to include and/or
	exclude. The default value is [`lfs.default_filter`](#lfs.default_filter) unless a filter for *paths* is
	defined in [`io.quick_open_filters`](#io.quick_open_filters).

Usage:

- `io.quick_open(buffer.filename:match('^(.+)[/\\]')) -- list all files in the current
	file's directory, subject to the default filter
`
- `io.quick_open(io.get_current_project(), '.lua') -- list all Lua files in the current
	project
`
- `io.quick_open(io.get_current_project(), '!/build') -- list all files in the current
	project except those in the build directory
`

<a id="io.save_all_files"></a>
#### `io.save_all_files`(*untitled*)

Saves all unsaved buffers to their respective files, prompting the user for filenames for
untitled buffers if *untitled* is `true`, and returns `true` on success.
Print and output buffers are ignored.

Parameters:

- *untitled*:  Whether or not to prompt for filenames for untitled buffers. The default
	value is `false`.

Return:

- `true` if all savable files were saved; `nil` otherwise.


---
<a id="keys"></a>
## The `keys` Module
---

Manages key bindings in Textadept.

### Overview

Define key bindings in the global [`keys`](#keys) table in key-value pairs. Each pair consists of
either a string key sequence and its associated command, a string lexer name (from the
*lexers/* directory) with a table of key sequences and commands, a string key mode with a
table of key sequences and commands, or a key sequence with a table of more sequences and
commands. The latter is part of what is called a "key chain", to be discussed below. When
searching for a command to run based on a key sequence, Textadept considers key bindings
in the current key mode to have priority. If no key mode is active, language-specific key
bindings have priority, followed by the ones in the global table. This means if there are
two commands with the same key sequence, Textadept runs the language-specific one. However,
if the command returns the boolean value `false`, Textadept also runs the lower-priority
command. (This is useful for overriding commands like autocompletion with language-specific
completion, but fall back to word autocompletion if the first command fails.)

### Key Sequences

Key sequences are strings built from an ordered combination of modifier keys and the key's
inserted character. Modifier keys are "Control", "Shift", and "Alt" on Windows, Linux, and
in the terminal version. On macOS they are "Control" (`^`), "Alt/Option" (`⌥`), "Command"
(`⌘`), and "Shift" (`⇧`). These modifiers have the following string representations:

Modifier |  Windows / Linux | macOS | Terminal
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

Textadept handles [`buffer`](#buffer) and [`view`](#view) references properly in static contexts.

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
#### `keys.CLEAR` 

The key that clears the current key chain.
It cannot be part of a key chain.
The default value is `'esc'` for the `Esc` key.

<a id="keys.KEYSYMS"></a>
#### `keys.KEYSYMS` &lt;table&gt;

Lookup table for string representations of key codes higher than 255.
Key codes can be identified by temporarily uncommenting the `print()` statements in
*core/keys.lua*.
Recognized codes are: esc, \b, \t, \n, down, up, left, right, home, end, pgup, pgdn, del,
ins, and f1-f12.
The GUI version also recognizes: menu, kpenter, kphome, kpend, kpleft, kpup, kpright, kpdown,
kppgup, kppgdn, kpmul, kpadd, kpsub, kpdiv, kpdec, and kp0-kp9.

<a id="keys.keychain"></a>
#### `keys.keychain` &lt;table&gt;

The current chain of key sequences. (Read-only.)

<a id="keys.mode"></a>
#### `keys.mode` 

The current key mode.
When non-`nil`, all key bindings defined outside of `keys[mode]` are ignored.
The default value is `nil`.


---
<a id="lexer"></a>
## The `lexer` Module
---

Lexes Scintilla documents and source code with Lua and LPeg.

### Writing Lua Lexers

Lexers recognize and tag elements of source code for syntax highlighting. Scintilla (the
editing component behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are notoriously difficult to create and/or extend. On the other hand, Lua makes
it easy to to rapidly create new lexers, extend existing ones, and embed lexers within one
another. Lua lexers tend to be more readable than C++ lexers too.

While lexers can be written in plain Lua, Scintillua prefers using Parsing Expression
Grammars, or PEGs, composed with the Lua [LPeg library][]. As a result, this document is
devoted to writing LPeg lexers. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This module provides
convenience functions for creating and working with other more advanced patterns and concepts.

Operator | Description
-|-
`lpeg.P(string)` | Matches [`string`](#string) literally.
`lpeg.P(`_`n`_`)` | Matches exactly _`n`_ number of characters.
`lpeg.S(string)` | Matches any character in set [`string`](#string).
`lpeg.R("`_`xy`_`")`| Matches any character between range `x` and `y`.
`patt^`_`n`_ | Matches at least _`n`_ repetitions of `patt`.
`patt^-`_`n`_ | Matches at most _`n`_ repetitions of `patt`.
`patt1 * patt2` | Matches `patt1` followed by `patt2`.
`patt1 + patt2` | Matches `patt1` or `patt2` (ordered choice).
`patt1 - patt2` | Matches `patt1` if `patt2` does not also match.
`-patt` | Matches if `patt` does not match, consuming no input.
`#patt` | Matches `patt` but consumes no input.

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

Note: Try to refrain from using one-character language names like "c", "d", or "r". For
example, Scintillua uses "ansi_c", "dmd", and "rstats", respectively.

#### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a new lexer. Feel
free to use it, replacing the '?' with the name of your lexer. Consider this snippet from
the template:

    -- ? LPeg lexer.

    local lexer = lexer
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new(...)

    [... lexer rules ...]

    -- Identifier.
    local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
    lex:add_rule('identifier', identifier)

    [... more lexer rules ...]

    return lex

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

    local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)

At first glance, the first argument does not appear to be a string name and the second
argument does not appear to be an LPeg pattern. Perhaps you expected something like:

    lex:tag('identifier', (lpeg.R('AZ', 'az')  + '_') * (lpeg.R('AZ', 'az', '09') + '_')^0)

The [`lexer`](#lexer) module actually provides a convenient list of common tag names and common LPeg
patterns for you to use. Tag names for programming languages include (but are not limited
to) [`lexer.DEFAULT`](#lexer.DEFAULT), [`lexer.COMMENT`](#lexer.COMMENT), [`lexer.STRING`](#lexer.STRING), [`lexer.NUMBER`](#lexer.NUMBER), [`lexer.KEYWORD`](#lexer.KEYWORD),
[`lexer.IDENTIFIER`](#lexer.IDENTIFIER), [`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.ERROR`](#lexer.ERROR), [`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR), [`lexer.CONSTANT`](#lexer.CONSTANT),
[`lexer.CONSTANT_BUILTIN`](#lexer.CONSTANT_BUILTIN), [`lexer.VARIABLE`](#lexer.VARIABLE), [`lexer.VARIABLE_BUILTIN`](#lexer.VARIABLE_BUILTIN), [`lexer.FUNCTION`](#lexer.FUNCTION),
[`lexer.FUNCTION_BUILTIN`](#lexer.FUNCTION_BUILTIN), [`lexer.FUNCTION_METHOD`](#lexer.FUNCTION_METHOD), [`lexer.CLASS`](#lexer.CLASS), [`lexer.TYPE`](#lexer.TYPE), [`lexer.LABEL`](#lexer.LABEL),
[`lexer.REGEX`](#lexer.REGEX), [`lexer.EMBEDDED`](#lexer.EMBEDDED), and [`lexer.ANNOTATION`](#lexer.ANNOTATION). Tag names for markup languages include
(but are not limited to) [`lexer.TAG`](#lexer.TAG), [`lexer.ATTRIBUTE`](#lexer.ATTRIBUTE), [`lexer.HEADING`](#lexer.HEADING), [`lexer.BOLD`](#lexer.BOLD),
[`lexer.ITALIC`](#lexer.ITALIC), [`lexer.UNDERLINE`](#lexer.UNDERLINE), [`lexer.CODE`](#lexer.CODE), [`lexer.LINK`](#lexer.LINK), [`lexer.REFERENCE`](#lexer.REFERENCE), and
[`lexer.LIST`](#lexer.LIST). Patterns include [`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum),
[`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph), [`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space),
[`lexer.newline`](#lexer.newline), [`lexer.nonnewline`](#lexer.nonnewline), [`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num),
[`lexer.bin_num`](#lexer.bin_num), [`lexer.integer`](#lexer.integer), [`lexer.float`](#lexer.float), [`lexer.number`](#lexer.number), and [`lexer.word`](#lexer.word). You may
use your own tag names if none of the above fit your language, but an advantage to using
predefined tag names is that the language elements your lexer recognizes will inherit any
universal syntax highlighting color theme that your editor uses. You can also "subclass"
existing tag names by appending a '.*subclass*' string to them. For example, the HTML lexer
tags unknown tags as `lexer.TAG .. '.unknown'`. This gives editors the opportunity to style
those subclassed tags in a different way than normal tags, or fall back to styling them as
normal tags.

##### Example Tags

So, how might you recognize and tag elements like keywords, comments, and strings?  Here are
some examples.

**Keywords**

Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered choices, use one
of of the following methods:

1. Use the convenience function [`lexer.word_match()`](#lexer.word_match) optionally coupled with
  [`lexer.set_word_list()`](#lexer.set_word_list). It is much easier and more efficient to write word matches like:

       local keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
       [...]
       lex:set_word_list(lexer.KEYWORD, {
         'keyword_1', 'keyword_2', ..., 'keyword_n'
       })

       local case_insensitive_word = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD, true))
       [...]
       lex:set_word_list(lexer.KEYWORD, {
         'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
       })

       local hyphenated_keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
       [...]
       lex:set_word_list(lexer.KEYWORD, {
         'keyword-1', 'keyword-2', ..., 'keyword-n'
       })

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

       local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
         'keyword_1', 'keyword_2', ..., 'keyword_n'
       })

       local case_insensitive_keyword = lex:tag(lexer.KEYWORD, lexer.word_match({
         'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
       }, true))

       local hyphened_keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
         'keyword-1', 'keyword-2', ..., 'keyword-n'
       })

   For short keyword lists, you can use a single string of words. For example:

       local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('key_1 key_2 ... key_n'))

   You can use this method for static word lists that do not change, or where it does not
   make sense to allow applications or other lexers to extend or replace a word list.

**Comments**

Line-style comments with a prefix character(s) are easy to express:

    local shell_comment = lex:tag(lexer.COMMENT, lexer.to_eol('#'))
    local c_line_comment = lex:tag(lexer.COMMENT, lexer.to_eol('//', true))

The comments above start with a '#' or "//" and go to the end of the line (EOL). The second
comment recognizes the next line also as a comment if the current line ends with a '\'
escape character.

C-style "block" comments with a start and end delimiter are also easy to express:

    local c_comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/'))

This comment starts with a "/\*" sequence and contains anything up to and including an ending
"\*/" sequence. The ending "\*/" is optional so the lexer can recognize unfinished comments
as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a sequence like
"\\&quot;" in a double-quoted string indicates that the '&quot;' is not the end of the
string. [`lexer.range()`](#lexer.range) handles escapes inherently.

    local dq_str = lexer.range('"')
    local sq_str = lexer.range("'")
    local string = lex:tag(lexer.STRING, dq_str + sq_str)

In this case, the lexer treats '\' as an escape character in a string sequence.

**Numbers**

Most programming languages have the same format for integers and floats, so it might be as
simple as using a predefined LPeg pattern:

    local number = lex:tag(lexer.NUMBER, lexer.number)

However, some languages allow postfix characters on integers.

    local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
    local number = lex:tag(lexer.NUMBER, lexer.float + lexer.hex_num + integer)

Other languages allow separaters within numbers for better readability.

    local number = lex:tag(lexer.NUMBER, lexer.number_('_')) -- recognize 1_000_000

Your language may need other tweaks, but it is up to you how fine-grained you want your
highlighting to be. After all, you are not writing a compiler or interpreter!

#### Rules

Programming languages have grammars, which specify valid syntactic structure. For example,
comments usually cannot appear within a string, and valid identifiers (like variable names)
cannot be keywords. In Lua lexers, grammars consist of LPeg pattern rules, many of which
are tagged.  Recall from the lexer template the [`lexer.add_rule()`](#lexer.add_rule) call, which adds a rule
to the lexer's grammar:

    lex:add_rule('identifier', identifier)

Each rule has an associated name, but rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if text does not
match the first rule added to the grammar, the lexer tries to match the second rule added, and
so on. Right now this lexer simply matches identifiers under a rule named "identifier".

To illustrate the importance of rule order, here is an example of a simplified Lua lexer:

    lex:add_rule('keyword', lex:tag(lexer.KEYWORD, ...))
    lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ...))
    lex:add_rule('string', lex:tag(lexer.STRING, ...))
    lex:add_rule('comment', lex:tag(lexer.COMMENT, ...))
    lex:add_rule('number', lex:tag(lexer.NUMBER, ...))
    lex:add_rule('label', lex:tag(lexer.LABEL, ...))
    lex:add_rule('operator', lex:tag(lexer.OPERATOR, ...))

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

    lex:add_rule('keyword', keyword)
    ...
    lex:add_rule('error', lex:tag(lexer.ERROR, lexer.any))

This identifies and tags any character not matched by an existing rule as a [`lexer.ERROR`](#lexer.ERROR).

Even though the rules defined in the examples above contain a single tagged pattern, rules may
consist of multiple tagged patterns. For example, the rule for an HTML tag could consist of a
tagged tag followed by an arbitrary number of tagged attributes, separated by whitespace. This
allows the lexer to produce all tags separately, but in a single, convenient rule. That rule
might look something like this:

    local ws = lex:get_rule('whitespace') -- predefined rule for all lexers
    lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)

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
chunks may be a full document, only the visible part of a document, or even just portions
of lines. Some lexers need to match whole lines. For example, a lexer for the output of a
file "diff" needs to know if the line started with a '+' or '-' and then style the entire
line accordingly. To indicate that your lexer matches by line, create the lexer with an
extra parameter:

    local lex = lexer.new(..., {lex_by_line = true})

Now the input text for the lexer is a single line at a time. Keep in mind that line lexers
do not have the ability to look ahead to subsequent lines.

#### Embedded Lexers

Scintillua lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and the lexer a child
is being embedded in is called the "parent". For example, consider an HTML lexer and a CSS
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
      if input:find('^[^>]+type="text/css"', index) then return true end
    end)

This pattern looks for the beginning of a "style" tag and searches its attribute list for
the text "`type="text/css"`". (In this simplified example, the Lua pattern does not consider
whitespace between the '=' nor does it consider that using single quotes is valid.) If there
is a match, the functional pattern returns `true`. However, we ultimately want to style the
"style" tag as an HTML tag, so the actual start rule looks like this:

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
    local php_start_rule = lex:tag('php_tag', '<?php' * lexer.space)
    local php_end_rule = lex:tag('php_tag', '?>')
    html:embed(lex, php_start_rule, php_end_rule)

Note that the use of a 'php_tag' tag will require the editor using the lexer to specify how
to highlight text with that tag. In order to avoid this, you could use the [`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR)
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
SciTE editors for example, little indicators in the editor margins appear next to code that
can be folded at places called "fold points". When the user clicks an indicator, the editor
hides the code associated with the indicator until the user clicks the indicator again. The
lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences. Examples of
fold keywords are "if" and "end" in Lua and examples of fold character sequences are '{',
'}', "/\*", and "\*/" in C for code block and comment delimiters, respectively. However,
these fold points cannot occur just anywhere. For example, lexers should not recognize fold
keywords that appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function allows
you to conveniently define fold points with such granularity. For example, consider C:

    lex:add_fold_point(lexer.OPERATOR, '{', '}')
    lex:add_fold_point(lexer.COMMENT, '/*', '*/')

The first assignment states that any '{' or '}' that the lexer tagged as an [`lexer.OPERATOR`](#lexer.OPERATOR)
is a fold point. Likewise, the second assignment states that any "/\*" or "\*/" that the
lexer tagged as part of a [`lexer.COMMENT`](#lexer.COMMENT) is a fold point. The lexer does not consider any
occurrences of these characters outside their tagged elements (such as in a string) as fold
points. How do you specify fold keywords? Here is an example for Lua:

    lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and specify keywords in
lower case.

If your lexer needs to do some additional processing in order to determine if a tagged element
is a fold point, pass a function to `lex:add_fold_point()` that returns an integer. A return
value of `1` indicates the element is a beginning fold point and a return value of `-1`
indicates the element is an ending fold point. A return value of `0` indicates the element
is not a fold point. For example:

    local function fold_strange_element(text, pos, line, s, symbol)
      if ... then
        return 1 -- beginning fold point
      elseif ... then
        return -1 -- ending fold point
      end
      return 0
    end

    lex:add_fold_point('strange_element', '|', fold_strange_element)

Any time the lexer encounters a '|' that is tagged as a "strange_element", it calls the
`fold_strange_element` function to determine if '|' is a fold point. The lexer calls these
functions with the following arguments: the text to identify fold points in, the beginning
position of the current line in the text to fold, the current line's text, the position in
the current line the fold point text starts at, and the fold point text itself.

#### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate fold points. If
your lexer falls into this category and you would like to mark fold points based on changes
in indentation, create the lexer with a `fold_by_indentation = true` option:

    local lex = lexer.new(..., {fold_by_indentation = true})

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

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('?')

    -- Whitespace.
    lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

    -- Keywords.
    lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
      [...]
    }))

    [... other rule definitions ...]

    -- Custom.
    lex:add_rule('custom_rule', token('custom_token', ...))
    lex:add_style('custom_token', lexer.styles.keyword .. {bold = true})

    -- Fold points.
    lex:add_fold_point(lexer.OPERATOR, '{', '}')

    return lex

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
   something like [`lexer.KEYWORD`](#lexer.KEYWORD)). Then at the end of the lexer (before `return lex`), call
   [`lex:set_word_list()`](#lexer.set_word_list) with the same identifier and the usual
   list of words to match. This allows users of your lexer to call `lex:set_word_list()`
   with their own set of words should they wish to.
6. Lexers no longer specify styling information. Remove any calls to `lex:add_style()`. You
   may need to add styling information for custom tags to your editor's theme.
7. `lexer.last_char_includes()` has been deprecated in favor of the new [`lexer.after_set()`](#lexer.after_set).
   Use the character set and pattern as arguments to that new function.

As an example, consider the following sample legacy lexer:

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

Following the migration steps would yield:

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

    <div id="<?php echo $id; ?>">

will not style correctly. Also, these types of languages cannot currently embed themselves
into their parent's child languages either.

A language cannot embed itself into something like an interpolated string because it is
possible that if lexing starts within the embedded entity, it will not be detected as such,
so a child to parent transition cannot happen. For example, the following Ruby code will
not style correctly:

    sum = "1 + 2 = #{1 + 2}"

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

### Fields defined by `lexer`

<a id="lexer.ANNOTATION"></a>
#### `lexer.ANNOTATION` 

The tag name for annotation elements.

<a id="lexer.ATTRIBUTE"></a>
#### `lexer.ATTRIBUTE` 

The tag name for function attribute elements, typically in markup.

<a id="lexer.BOLD"></a>
#### `lexer.BOLD` 

The tag name for bold elements, typically in markup.

<a id="lexer.CLASS"></a>
#### `lexer.CLASS` 

The tag name for class elements.

<a id="lexer.CODE"></a>
#### `lexer.CODE` 

The tag name for code elements, typically in markup.

<a id="lexer.COMMENT"></a>
#### `lexer.COMMENT` 

The tag name for comment elements.

<a id="lexer.CONSTANT"></a>
#### `lexer.CONSTANT` 

The tag name for constant elements.

<a id="lexer.CONSTANT_BUILTIN"></a>
#### `lexer.CONSTANT_BUILTIN` 

The tag name for builtin constant elements.

<a id="lexer.DEFAULT"></a>
#### `lexer.DEFAULT` 

The tag name for default elements.

<a id="lexer.EMBEDDED"></a>
#### `lexer.EMBEDDED` 

The tag name for embedded elements.

<a id="lexer.ERROR"></a>
#### `lexer.ERROR` 

The tag name for error elements.

<a id="lexer.FOLD_BASE"></a>
#### `lexer.FOLD_BASE` 

The initial (root) fold level.

<a id="lexer.FOLD_BLANK"></a>
#### `lexer.FOLD_BLANK` 

Flag indicating that the line is blank.

<a id="lexer.FOLD_HEADER"></a>
#### `lexer.FOLD_HEADER` 

Flag indicating the line is fold point.

<a id="lexer.FUNCTION"></a>
#### `lexer.FUNCTION` 

The tag name for function elements.

<a id="lexer.FUNCTION_BUILTIN"></a>
#### `lexer.FUNCTION_BUILTIN` 

The tag name for builtin function elements.

<a id="lexer.FUNCTION_METHOD"></a>
#### `lexer.FUNCTION_METHOD` 

The tag name for function method elements.

<a id="lexer.HEADING"></a>
#### `lexer.HEADING` 

The tag name for heading elements, typically in markup.

<a id="lexer.IDENTIFIER"></a>
#### `lexer.IDENTIFIER` 

The tag name for identifier elements.

<a id="lexer.ITALIC"></a>
#### `lexer.ITALIC` 

The tag name for builtin italic elements, typically in markup.

<a id="lexer.KEYWORD"></a>
#### `lexer.KEYWORD` 

The tag name for keyword elements.

<a id="lexer.LABEL"></a>
#### `lexer.LABEL` 

The tag name for label elements.

<a id="lexer.LINK"></a>
#### `lexer.LINK` 

The tag name for link elements, typically in markup.

<a id="lexer.LIST"></a>
#### `lexer.LIST` 

The tag name for list item elements, typically in markup.

<a id="lexer.NUMBER"></a>
#### `lexer.NUMBER` 

The tag name for number elements.

<a id="lexer.OPERATOR"></a>
#### `lexer.OPERATOR` 

The tag name for operator elements.

<a id="lexer.PREPROCESSOR"></a>
#### `lexer.PREPROCESSOR` 

The tag name for preprocessor elements.

<a id="lexer.REFERENCE"></a>
#### `lexer.REFERENCE` 

The tag name for reference elements, typically in markup.

<a id="lexer.REGEX"></a>
#### `lexer.REGEX` 

The tag name for regex elements.

<a id="lexer.STRING"></a>
#### `lexer.STRING` 

The tag name for string elements.

<a id="lexer.TAG"></a>
#### `lexer.TAG` 

The tag name for function tag elements, typically in markup.

<a id="lexer.TYPE"></a>
#### `lexer.TYPE` 

The tag name for type elements.

<a id="lexer.UNDERLINE"></a>
#### `lexer.UNDERLINE` 

The tag name for underlined elements, typically in markup.

<a id="lexer.VARIABLE"></a>
#### `lexer.VARIABLE` 

The tag name for variable elements.

<a id="lexer.VARIABLE_BUILTIN"></a>
#### `lexer.VARIABLE_BUILTIN` 

The tag name for builtin variable elements.

<a id="lexer.alnum"></a>
#### `lexer.alnum` 

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z', '0'-'9').

<a id="lexer.alpha"></a>
#### `lexer.alpha` 

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
#### `lexer.any` 

A pattern that matches any single character.

<a id="lexer.bin_num"></a>
#### `lexer.bin_num` 

A pattern that matches a binary number.

<a id="lexer.dec_num"></a>
#### `lexer.dec_num` 

A pattern that matches a decimal number.

<a id="lexer.detect_extensions"></a>
#### `lexer.detect_extensions` &lt;table&gt;

Map of file extensions, without the '.' prefix, to their associated lexer names.
This map has precedence over Scintillua's built-in map.

See also:

- [`lexer.detect`](#lexer.detect)

<a id="lexer.detect_patterns"></a>
#### `lexer.detect_patterns` &lt;table&gt;

Map of line patterns to their associated lexer names.
These are Lua string patterns, not LPeg patterns.
This map has precedence over Scintillua's built-in map.

See also:

- [`lexer.detect`](#lexer.detect)

<a id="lexer.digit"></a>
#### `lexer.digit` 

A pattern that matches any digit ('0'-'9').

<a id="lexer.float"></a>
#### `lexer.float` 

A pattern that matches a floating point number.

<a id="lexer.fold_level"></a>
#### `lexer.fold_level` &lt;table&gt;

Table of fold level bit-masks for line numbers starting from 1. (Read-only)
Fold level masks are composed of an integer level combined with any of the following bits:

  - [`lexer.FOLD_BASE`](#lexer.FOLD_BASE)
    The initial fold level.
  - [`lexer.FOLD_BLANK`](#lexer.FOLD_BLANK)
    The line is blank.
  - [`lexer.FOLD_HEADER`](#lexer.FOLD_HEADER)
    The line is a header, or fold point.

<a id="lexer.graph"></a>
#### `lexer.graph` 

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
#### `lexer.hex_num` 

A pattern that matches a hexadecimal number.

<a id="lexer.indent_amount"></a>
#### `lexer.indent_amount` &lt;table&gt;

Table of indentation amounts in character columns, for line numbers starting from
1. (Read-only)

<a id="lexer.integer"></a>
#### `lexer.integer` 

A pattern that matches either a decimal, hexadecimal, octal, or binary number.

<a id="lexer.line_state"></a>
#### `lexer.line_state` &lt;table&gt;

Table of integer line states for line numbers starting from 1.
Line states can be used by lexers for keeping track of persistent states. For example,
the output lexer uses this to mark lines that have warnings or errors.

<a id="lexer.lower"></a>
#### `lexer.lower` 

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.newline"></a>
#### `lexer.newline` 

A pattern that matches a sequence of end of line characters.

<a id="lexer.nonnewline"></a>
#### `lexer.nonnewline` 

A pattern that matches any single, non-newline character.

<a id="lexer.number"></a>
#### `lexer.number` 

A pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number.

<a id="lexer.oct_num"></a>
#### `lexer.oct_num` 

A pattern that matches an octal number.

<a id="lexer.property"></a>
#### `lexer.property` &lt;table&gt;

Map of key-value string pairs.

<a id="lexer.property_int"></a>
#### `lexer.property_int` &lt;table&gt;

Map of key-value pairs with values interpreted as numbers, or `0` if not found. (Read-only)

<a id="lexer.punct"></a>
#### `lexer.punct` 

A pattern that matches any punctuation character ('!' to '/', ':' to '@', '[' to ''', '{'
to '~').

<a id="lexer.space"></a>
#### `lexer.space` 

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n', '\r', space).

<a id="lexer.style_at"></a>
#### `lexer.style_at` &lt;table&gt;

Table of style names at positions in the buffer starting from 1. (Read-only)

<a id="lexer.upper"></a>
#### `lexer.upper` 

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
#### `lexer.word` 

A pattern that matches a typical word. Words begin with a letter or underscore and consist
of alphanumeric and underscore characters.

<a id="lexer.xdigit"></a>
#### `lexer.xdigit` 

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').


### Functions defined by `lexer`

<a id="lexer.add_fold_point"></a>
#### `lexer.add_fold_point`(*lexer*, *tag_name*, *start_symbol*, *end_symbol*)

Adds to lexer *lexer* a fold point whose beginning and end points are tagged with string
*tag_name* tags and have string content *start_symbol* and *end_symbol*, respectively.
In the event that *start_symbol* may or may not be a fold point depending on context, and that
additional processing is required, *end_symbol* may be a function that ultimately returns
`1` (indicating a beginning fold point), `-1` (indicating an ending fold point), or `0`
(indicating no fold point). That function is passed the following arguments:

  - `text`: The text being processed for fold points.
  - `pos`: The position in *text* of the beginning of the line currently being processed.
  - `line`: The text of the line currently being processed.
  - `s`: The position of *start_symbol* in *line*.
  - `symbol`: *start_symbol* itself.

Parameters:

- *lexer*:  The lexer to add a fold point to.
- *tag_name*:  The tag name for text that indicates a fold point.
- *start_symbol*:  The text that indicates the beginning of a fold point.
- *end_symbol*:  Either the text that indicates the end of a fold point, or a function that
   returns whether or not *start_symbol* is a beginning fold point (1), an ending fold point
   (-1), or not a fold point at all (0).

Usage:

- `lex:add_fold_point(lexer.OPERATOR, '{', '}')
`
- `lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
`
- `lex:add_fold_point('custom', function(text, pos, line, s, symbol) ... end)
`

<a id="lexer.add_rule"></a>
#### `lexer.add_rule`(*lexer*, *id*, *rule*)

Adds pattern *rule* identified by string *id* to the ordered list of rules for lexer *lexer*.

Parameters:

- *lexer*:  The lexer to add the given rule to.
- *id*:  The id associated with this rule. It does not have to be the same as the name
   passed to `tag()`.
- *rule*:  The LPeg pattern of the rule.

See also:

- [`lexer.modify_rule`](#lexer.modify_rule)

<a id="lexer.after_set"></a>
#### `lexer.after_set`(*set*, *patt*, *skip*)

Creates and returns a pattern that matches pattern *patt* only when it comes after one of
the characters in string *set* (or when there are no characters behind *patt*), skipping
over any characters in string *skip*, which is whitespace by default.

Parameters:

- *set*:  String character set like one passed to `lpeg.S()`.
- *patt*:  The LPeg pattern to match after a set character.
- *skip*:  String character set to skip over. The default value is ' \t\r\n\v\f' (whitespace).

Usage:

- `local regex = lexer.after_set('+-*!%^&|=,([{', lexer.range('/'))
`

<a id="lexer.bin_num_"></a>
#### `lexer.bin_num_`(*c*)

Returns a pattern that matches a binary number, whose digits may be separated by character *c*.

Parameters:

- *c*: 

<a id="lexer.dec_num_"></a>
#### `lexer.dec_num_`(*c*)

Returns a pattern that matches a decimal number, whose digits may be separated by character
*c*.

Parameters:

- *c*: 

<a id="lexer.detect"></a>
#### `lexer.detect`([*filename*[, *line*]])

Returns the name of the lexer often associated with filename *filename* and/or content
line *line*.

Parameters:

- *filename*:  Optional string filename. The default value is read from the
   'lexer.scintillua.filename' property.
- *line*:  Optional string first content line, such as a shebang line. The default
   value is read from the 'lexer.scintillua.line' property.

Return:

- string lexer name to pass to `load()`, or `nil` if none was detected

See also:

- [`lexer.detect_extensions`](#lexer.detect_extensions)
- [`lexer.detect_patterns`](#lexer.detect_patterns)

<a id="lexer.embed"></a>
#### `lexer.embed`(*lexer*, *child*, *start_rule*, *end_rule*)

Embeds child lexer *child* in parent lexer *lexer* using patterns *start_rule* and *end_rule*,
which signal the beginning and end of the embedded lexer, respectively.

Parameters:

- *lexer*:  The parent lexer.
- *child*:  The child lexer.
- *start_rule*:  The pattern that signals the beginning of the embedded lexer.
- *end_rule*:  The pattern that signals the end of the embedded lexer.

Usage:

- `html:embed(css, css_start_rule, css_end_rule)
`
- `html:embed(lex, php_start_rule, php_end_rule) -- from php lexer
`

<a id="lexer.float_"></a>
#### `lexer.float_`(*c*)

Returns a pattern that matches a floating point number, whose digits may be separated by
character *c*.

Parameters:

- *c*: 

<a id="lexer.fold"></a>
#### `lexer.fold`(*lexer*, *text*, *start_line*, *start_level*)

Determines fold points in a chunk of text *text* using lexer *lexer*, returning a table of
fold levels associated with line numbers.
*text* starts on line number *start_line* with a beginning fold level of *start_level*
in the buffer.

Parameters:

- *lexer*:  The lexer to fold text with.
- *text*:  The text in the buffer to fold.
- *start_line*:  The line number *text* starts on, counting from 1.
- *start_level*:  The fold level *text* starts on.

Return:

- table of fold levels associated with line numbers.

<a id="lexer.get_rule"></a>
#### `lexer.get_rule`(*lexer*, *id*)

Returns the rule identified by string *id*.

Parameters:

- *lexer*:  The lexer to fetch a rule from.
- *id*:  The id of the rule to fetch.

Return:

- pattern

<a id="lexer.hex_num_"></a>
#### `lexer.hex_num_`(*c*)

Returns a pattern that matches a hexadecimal number, whose digits may be separated by
character *c*.

Parameters:

- *c*: 

<a id="lexer.integer_"></a>
#### `lexer.integer_`(*c*)

Returns a pattern that matches either a decimal, hexadecimal, octal, or binary number,
whose digits may be separated by character *c*.

Parameters:

- *c*: 

<a id="lexer.lex"></a>
#### `lexer.lex`(*lexer*, *text*, *init_style*)

Lexes a chunk of text *text* (that has an initial style number of *init_style*) using lexer
*lexer*, returning a list of tag names and positions.

Parameters:

- *lexer*:  The lexer to lex text with.
- *text*:  The text in the buffer to lex.
- *init_style*:  The current style. Multiple-language lexers use this to determine which
   language to start lexing in.

Return:

- list of tag names and positions.

<a id="lexer.line_from_position"></a>
#### `lexer.line_from_position`(*pos*)

Returns the line number (starting from 1) of the line that contains position *pos*, which
starts from 1.

Parameters:

- *pos*:  The position to get the line number of.

Return:

- number

<a id="lexer.load"></a>
#### `lexer.load`(*name*[, *alt_name*])

Initializes or loads and then returns the lexer of string name *name*.
Scintilla calls this function in order to load a lexer. Parent lexers also call this function
in order to load child lexers and vice-versa. The user calls this function in order to load
a lexer when using Scintillua as a Lua library.

Parameters:

- *name*:  The name of the lexing language.
- *alt_name*:  Optional alternate name of the lexing language. This is useful for
   embedding the same child lexer with multiple sets of start and end tags.

Return:

- lexer object

<a id="lexer.modify_rule"></a>
#### `lexer.modify_rule`(*lexer*, *id*, *rule*)

Replaces in lexer *lexer* the existing rule identified by string *id* with pattern *rule*.

Parameters:

- *lexer*:  The lexer to modify.
- *id*:  The id associated with this rule.
- *rule*:  The LPeg pattern of the rule.

<a id="lexer.names"></a>
#### `lexer.names`([*path*])

Returns a list of all known lexer names.
This function is not available to lexers and requires the LuaFileSystem ([`lfs`](#lfs)) module to
be available.

Parameters:

- *path*:  Optional ';'-delimited list of directories to search for lexers in. The
   default value is Scintillua's configured lexer path.

Return:

- lexer name list

<a id="lexer.new"></a>
#### `lexer.new`(*name*, *opts*)

Creates a returns a new lexer with the given name.

Parameters:

- *name*:  The lexer's name.
- *opts*:  Table of lexer options. Options currently supported:
   - `lex_by_line`: Whether or not the lexer only processes whole lines of text (instead of
     arbitrary chunks of text) at a time. Line lexers cannot look ahead to subsequent lines.
     The default value is `false`.
   - `fold_by_indentation`: Whether or not the lexer does not define any fold points and that
     fold points should be calculated based on changes in line indentation. The default value
     is `false`.
   - `case_insensitive_fold_points`: Whether or not fold points added via
     [`lexer.add_fold_point()`](#lexer.add_fold_point) ignore case. The default value is `false`.
   - `no_user_word_lists`: Does not automatically allocate word lists that can be set by
     users. This should really only be set by non-programming languages like markup languages.
   - `inherit`: Lexer to inherit from. The default value is `nil`.

Usage:

- `lexer.new('rhtml', {inherit = lexer.load('html')})
`

<a id="lexer.number_"></a>
#### `lexer.number_`(*c*)

Returns a pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number, and whose digits may be separated by character *c*.

Parameters:

- *c*: 

<a id="lexer.oct_num_"></a>
#### `lexer.oct_num_`(*c*)

Returns a pattern that matches an octal number, whose digits may be separated by character *c*.

Parameters:

- *c*: 

<a id="lexer.range"></a>
#### `lexer.range`(*s*[, *e*=*s*[, *single_line*=*false*[, *escapes*[, *balanced*=*false*]]]])

Creates and returns a pattern that matches a range of text bounded by strings or patterns *s*
and *e*.
This is a convenience function for matching more complicated ranges like strings with escape
characters, balanced parentheses, and block comments (nested or not). *e* is optional and
defaults to *s*. *single_line* indicates whether or not the range must be on a single line;
*escapes* indicates whether or not to allow '\' as an escape character; and *balanced*
indicates whether or not to handle balanced ranges like parentheses, and requires *s* and *e*
to be different.

Parameters:

- *s*:  String or pattern start of a range.
- *e*:  Optional string or pattern end of a range. The default value is *s*.
- *single_line*:  Optional flag indicating whether or not the range must
   be on a single line.
- *escapes*:  Optional flag indicating whether or not the range end may be
   escaped by a '\' character. The default value is `false` unless *s* and *e* are identical,
   single-character strings. In that case, the default value is `true`.
- *balanced*:  Optional flag indicating whether or not to match a balanced
   range, like the "%b" Lua pattern. This flag only applies if *s* and *e* are different.

Usage:

- `local dq_str_escapes = lexer.range('"')
`
- `local dq_str_noescapes = lexer.range('"', false, false)
`
- `local unbalanced_parens = lexer.range('(', ')')
`
- `local balanced_parens = lexer.range('(', ')', false, false, true)
`

Return:

- pattern

<a id="lexer.set_word_list"></a>
#### `lexer.set_word_list`(*lexer*, *name*, *word_list*, *append*)

Sets in lexer *lexer* the word list identified by string or number *name* to string or
list *word_list*, appending to any existing word list if *append* is `true`.
This only has an effect if *lexer* uses `word_match()` to reference the given list.
Case-insensitivity is specified by `word_match()`.

Parameters:

- *lexer*:  The lexer to add the given word list to.
- *name*:  The string name or number of the word list to set.
- *word_list*:  A list of words or a string list of words separated by spaces.
- *append*:  Whether or not to append *word_list* to the existing word list (if any). The
   default value is `false`.

<a id="lexer.starts_line"></a>
#### `lexer.starts_line`(*patt*, *allow_indent*)

Creates and returns a pattern that matches pattern *patt* only at the beginning of a line,
or after any line indentation if *allow_indent* is `true`.

Parameters:

- *patt*:  The LPeg pattern to match on the beginning of a line.
- *allow_indent*:  Whether or not to consider line indentation as the start of a line. The
   default value is `false`.

Usage:

- `local preproc = lex:tag(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#')))
`

Return:

- pattern

<a id="lexer.tag"></a>
#### `lexer.tag`(*lexer*, *name*, *patt*)

Creates and returns a pattern that tags pattern *patt* with name *name* in lexer *lexer*.
If *name* is not a predefined tag name, its Scintilla style will likely need to be defined
by the editor or theme using this lexer.

Parameters:

- *lexer*:  The lexer to tag the given pattern in.
- *name*:  The name to use.
- *patt*:  The LPeg pattern to tag.

Usage:

- `local number = lex:tag(lexer.NUMBER, lexer.number)
`
- `local addition = lex:tag('addition', '+' * lexer.word)
`

Return:

- pattern

<a id="lexer.to_eol"></a>
#### `lexer.to_eol`([*prefix*[, *escape*=*false*]])

Creates and returns a pattern that matches from string or pattern *prefix* until the end of
the line.
*escape* indicates whether the end of the line can be escaped with a '\' character.

Parameters:

- *prefix*:  Optional string or pattern prefix to start matching at. The default value
   is any non-newline character.
- *escape*:  Optional flag indicating whether or not newlines can be escaped
  by a '\' character.

Usage:

- `local line_comment = lexer.to_eol('//')
`
- `local line_comment = lexer.to_eol(S('#;'))
`

Return:

- pattern

<a id="lexer.word_match"></a>
#### `lexer.word_match`([*lexer*], *word_list*[, *case_insensitive*=*false*])

Either returns a pattern for lexer *lexer* (if given) that matches one word in the word list
identified by string *word_list*, ignoring case if *case_sensitive* is `true`, or, if *lexer*
is not given, creates and returns a pattern that matches any single word in list or string
*word_list*, ignoring case if *case_insensitive* is `true`.
This is a convenience function for simplifying a set of ordered choice word patterns and
potentially allowing downstream users to configure word lists.
If there is ultimately no word list set via `set_word_list()`, no error will be raised,
but the returned pattern will not match anything.

Parameters:

- *lexer*:  Optional lexer to match a word in a wordlist for. This parameter may be
   omitted for lexer-agnostic matching.
- *word_list*:  Either a string name of the word list to match from if *lexer* is given,
   or, if *lexer* is omitted, a list of words or a string list of words separated by spaces.
- *case_insensitive*:  Optional boolean flag indicating whether or not the word
   match is case-insensitive.

Usage:

- `lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
`
- `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{'foo', 'bar', 'baz'})
`
- `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match({'foo-bar', 'foo-baz',
   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, true))
`
- `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('foo bar baz'))
`

Return:

- pattern


---
<a id="lfs"></a>
## The `lfs` Module
---

Extends the [`lfs`](#lfs) library to find files in directories and determine absolute file paths.

### Fields defined by `lfs`

<a id="lfs.default_filter"></a>
#### `lfs.default_filter` &lt;table&gt;

The filter table containing common binary file extensions and version control directories
to exclude when iterating over files and directories using [`lfs.walk`](#lfs.walk).
Extensions excluded: a, bmp, bz2, class, dll, exe, gif, gz, jar, jpeg, jpg, o, pdf, png,
so, tar, tgz, tif, tiff, xz, and zip.
Directories excluded: .bzr, .git, .hg, .svn, _FOSSIL_, and node_modules.


### Functions defined by `lfs`

<a id="lfs.abspath"></a>
#### `lfs.abspath`(*filename*[, *prefix*])

Returns the absolute path to string *filename*.
*prefix* or `lfs.currentdir()` is prepended to a relative filename. The returned path is
not guaranteed to exist.

Parameters:

- *filename*:  The relative or absolute path to a file.
- *prefix*:  Optional prefix path prepended to a relative filename.

Return:

- string absolute path

<a id="lfs.walk"></a>
#### `lfs.walk`(*dir*[, *filter*=*lfs*.*default_filter*[, *n*[, *include_dirs*=*false*]]])

Returns an iterator that iterates over all files and sub-directories (up to *n* levels deep)
in directory *dir* and yields each file found.
String or list *filter* determines which files to yield, with the default filter being
[`lfs.default_filter`](#lfs.default_filter). A filter consists of glob patterns that match file and directory paths to
include or exclude. Exclusive patterns begin with a '!'. If no inclusive patterns are given,
any path is initially considered. As a convenience, '/' also matches the Windows directory
separator ('[/\\]' is not needed).

Parameters:

- *dir*:  The directory path to iterate over.
- *filter*:  Optional filter for files and directories to include
	and exclude.
- *n*:  Optional maximum number of directory levels to descend into. The default
	is to have no limit.
- *include_dirs*:  Optional flag indicating whether or not to yield directory
	names too.  Directory names are passed with a trailing '/' or '\', depending on the
	current platform.


---
<a id="os"></a>
## The `os` Module
---

Extends Lua's [`os`](#os) library to provide process spawning capabilities.

### Functions defined by `os`

<a id="os.spawn"></a>
#### `os.spawn`(*cmd*[, *cwd*][, *env*][, *stdout_cb*[, *stderr_cb*[, *exit_cb*]]])

Spawns an interactive child process *cmd* in a separate thread, returning a handle to that
process.
On Windows, *cmd* is passed to `cmd.exe`: `%COMSPEC% /c [cmd]`.
At the moment, only the Windows terminal version spawns processes in the same thread.

Parameters:

- *cmd*:  A command line string that contains the program's name followed by arguments to
	pass to it. `PATH` is searched for program names.
- *cwd*:  Optional current working directory (cwd) for the child process. When omitted,
	the parent's cwd is used.
- *env*:  Optional map of environment variables for the child process. When omitted,
	Textadept's environment is used. In order to create a new environment that inherits
	from Textadept's, you can spawn 'env' on macOS and Linux, or 'set' on Windows, and
	iterate over output matches of "key=value" pairs (one per line), assigning them to the
	new environment table.
- *stdout_cb*:  Optional Lua function that accepts a string parameter for a block of
	standard output read from the child. Stdout is read asynchronously in 1KB or 0.5KB
	blocks (depending on the platform), or however much data is available at the time.
	At the moment, only the Windows terminal version sends all output, whether it be stdout
	or stderr, to this callback after the process finishes.
- *stderr_cb*:  Optional Lua function that accepts a string parameter for a block
	of standard error read from the child. Stderr is read asynchronously in 1KB or 0.5kB
	blocks (depending on the platform), or however much data is available at the time.
- *exit_cb*:  Optional Lua function that is called when the child process
	finishes. The child's exit status is passed.

Usage:

- `os.spawn('lua ' .. buffer.filename, print)
`
- `proc = os.spawn('lua -e "print(io.read())"', print)
	proc:write('foo\n')
`

Return:

- proc or nil plus an error message on failure

<a id="spawn_proc.close"></a>
#### `spawn_proc:close`()

Closes standard input for process *spawn_proc*, effectively sending an EOF (end of file) to it.

<a id="spawn_proc.kill"></a>
#### `spawn_proc:kill`([*signal*=*9*])

Kills running process *spawn_proc*, or sends it Unix signal *signal*.

Parameters:

- *signal*:  Optional Unix signal to send to *spawn_proc*. The default is to kill
	the process (`SIGKILL`).

<a id="spawn_proc.read"></a>
#### `spawn_proc:read`([*arg*='*l*'])

Reads and returns stdout from process *spawn_proc*, according to string format or number *arg*.
Similar to Lua's `io.read()` and blocks for input. *spawn_proc* must still be running. If
an error occurs while reading, returns `nil`, an error code, and an error message.
Ensure any read operations read all stdout available, as the stdout callback function passed
to [`os.spawn()`](#os.spawn) will not be called until the stdout buffer is clear.

Parameters:

- *arg*:  Optional argument similar to those in Lua's `io.read()`. The default is
	to read a line.

Return:

- string of bytes read

<a id="spawn_proc.status"></a>
#### `spawn_proc:status`()

Returns the status of process *spawn_proc*, which is either "running" or "terminated".

Return:

- "running" or "terminated"

<a id="spawn_proc.wait"></a>
#### `spawn_proc:wait`()

Blocks until process *spawn_proc* finishes (if it has not already done so) and returns its
status code.

Return:

- integer status code

<a id="spawn_proc.write"></a>
#### `spawn_proc:write`(...)

Writes string input to the stdin of process *spawn_proc*.
Note: On Linux when using the GTK or terminal version, if more than 65536 bytes (64K) are
to be written, it is possible those bytes need to be written in 65536-byte (64K) chunks,
or the process may not receive all input. However, it is also possible that there is a limit
on how many bytes can be written in a short period of time, perhaps 196608 bytes (192K). The
Qt version does not appear to have this limitation.

Parameters:

- *...*:  Standard input for *spawn_proc*.


---
<a id="string"></a>
## The `string` Module
---

Extends Lua's [`string`](#string) library to provide character set conversions.

### Functions defined by `string`

<a id="string.iconv"></a>
#### `string.iconv`(*text*, *new*, *old*)

Converts string *text* from encoding *old* to encoding *new* using GNU libiconv, returning
the string result.
Raises an error if the encoding conversion failed.
Valid encodings are [GNU libiconv's encodings][] and include:

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

- *text*:  The text to convert.
- *new*:  The string encoding to convert to.
- *old*:  The string encoding to convert from.


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
#### `textadept.bookmarks.MARK_BOOKMARK` 

The bookmark mark number.


### Functions defined by `textadept.bookmarks`

<a id="textadept.bookmarks.clear"></a>
#### `textadept.bookmarks.clear`()

Clears all bookmarks in the current buffer.

<a id="textadept.bookmarks.goto_mark"></a>
#### `textadept.bookmarks.goto_mark`([*next*])

Prompts the user to select a bookmarked line to move the caret to the beginning of unless
*next* is given.
If *next* is `true` or `false`, moves the caret to the beginning of the next or previously
bookmarked line, respectively.

Parameters:

- *next*:  Optional flag indicating whether to go to the next or previous bookmarked line
	relative to the current line. If `nil`, the user is prompted for a bookmarked line to go to.

<a id="textadept.bookmarks.toggle"></a>
#### `textadept.bookmarks.toggle`()

Toggles a bookmark on the current line.


---
<a id="textadept.editing"></a>
## The `textadept.editing` Module
---

Editing features for Textadept.

### Fields defined by `textadept.editing`

<a id="textadept.editing.INDIC_HIGHLIGHT"></a>
#### `textadept.editing.INDIC_HIGHLIGHT` 

The word highlight indicator number.

<a id="textadept.editing.XPM_IMAGES"></a>
#### `textadept.editing.XPM_IMAGES` &lt;table&gt;

Map of image names to registered image numbers.

Fields:

- `CLASS`:  The image number for classes.
- `NAMESPACE`:  The image number for namespaces.
- `METHOD`:  The image number for methods.
- `SIGNAL`:  The image number for signals.
- `SLOT`:  The image number for slots.
- `VARIABLE`:  The image number for variables.
- `STRUCT`:  The image number for structures.
- `TYPEDEF`:  The image number for type definitions.

<a id="textadept.editing.auto_enclose"></a>
#### `textadept.editing.auto_enclose` 

Whether or not to auto-enclose selected text when typing a punctuation character, taking
[`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs) into account.
The default value is `false`.

<a id="textadept.editing.auto_indent"></a>
#### `textadept.editing.auto_indent` 

Match the previous line's indentation level after inserting a new line.
The default value is `true`.

<a id="textadept.editing.auto_pairs"></a>
#### `textadept.editing.auto_pairs` &lt;table&gt;

Map of auto-paired characters like parentheses, brackets, braces, and quotes.
The default auto-paired characters are "()", "[]", "{}", "&apos;&apos;", "&quot;&quot;",
and "``". For certain XML-like lexers, "<>" is also auto-paired.

Usage:

- `textadept.editing.auto_pairs['*'] = '*'
`
- `textadept.editing.auto_pairs = nil -- disable completely
`

<a id="textadept.editing.autocomplete_all_words"></a>
#### `textadept.editing.autocomplete_all_words` 

Autocomplete the current word using words from all open buffers.
If `true`, performance may be slow when many buffers are open.
The default value is `false`.

<a id="textadept.editing.autocompleters"></a>
#### `textadept.editing.autocompleters` &lt;table&gt;

Map of autocompleter names to autocompletion functions.
Names are typically lexer names and autocompletion functions typically autocomplete symbols.
Autocompletion functions must return two values: the number of characters behind the caret
that are used as the prefix of the entity to be autocompleted, and a list of completions
to be shown. By default, the list of completions should be separated by space characters,
but the function may change [`buffer.auto_c_separator`](#buffer.auto_c_separator) if needed. Also, autocompletion lists
are sorted automatically by default, but the function may change [`buffer.auto_c_order`](#buffer.auto_c_order)
if it wants to control sort order.

Fields:

- `word`: Returns for the word part behind the caret a list of whole word completions
 constructed from the current buffer or all open buffers (depending on
 [`textadept.editing.autocomplete_all_words`](#textadept.editing.autocomplete_all_words)).
 If [`buffer.auto_c_ignore_case`](#buffer.auto_c_ignore_case) is `true`, completions are not case-sensitive.
- `snippet`: Autocompleter function for snippet trigger words.

See also:

- [`textadept.editing.autocomplete`](#textadept.editing.autocomplete)

<a id="textadept.editing.comment_string"></a>
#### `textadept.editing.comment_string` &lt;table&gt;

Map of lexer names to line comment strings for programming languages, used by
`editing.toggle_comment()`.
Keys are lexer names and values are either the language's line comment prefixes or block
comment delimiters separated by a '|' character. If no comment string exists for a given
language, the lexer-supplied string is used, if available.

<a id="textadept.editing.highlight_words"></a>
#### `textadept.editing.highlight_words` 

The word highlight mode.

- `textadept.editing.HIGHLIGHT_CURRENT`
	Automatically highlight all instances of the current word.
- `textadept.editing.HIGHLIGHT_SELECTED`
	Automatically highlight all instances of the selected word.
- `textadept.editing.HIGHLIGHT_NONE`
	Do not automatically highlight words.

The default value is `textadept.editing.HIGHLIGHT_NONE`.

<a id="textadept.editing.strip_trailing_spaces"></a>
#### `textadept.editing.strip_trailing_spaces` 

Strip trailing whitespace before saving files. (Does not apply to binary files.)
The default value is `false`.

<a id="textadept.editing.typeover_auto_paired"></a>
#### `textadept.editing.typeover_auto_paired` 

Whether or not to type over an auto-paired complement character.
The default value is `true`.


### Functions defined by `textadept.editing`

<a id="textadept.editing.autocomplete"></a>
#### `textadept.editing.autocomplete`(*name*)

Displays an autocompletion list provided by the autocompleter function associated with string
*name*, and returns `true` if completions were found.

Parameters:

- *name*:  The name of an autocompleter function in the [`textadept.editing.autocompleters`](#textadept.editing.autocompleters)
	table to use for providing autocompletions.

See also:

- [`textadept.editing.autocompleters`](#textadept.editing.autocompleters)

<a id="textadept.editing.convert_indentation"></a>
#### `textadept.editing.convert_indentation`()

Converts indentation between tabs and spaces according to [`buffer.use_tabs`](#buffer.use_tabs).
If [`buffer.use_tabs`](#buffer.use_tabs) is `true`, [`buffer.tab_width`](#buffer.tab_width) indenting spaces are converted to tabs.
Otherwise, all indenting tabs are converted to [`buffer.tab_width`](#buffer.tab_width) spaces.

<a id="textadept.editing.enclose"></a>
#### `textadept.editing.enclose`(*left*, *right*[, *select*=*false*])

Encloses the selected text or the current word within strings *left* and *right*, taking
multiple selections into account.

Parameters:

- *left*:  The left part of the enclosure.
- *right*:  The right part of the enclosure.
- *select*:  Optional flag that indicates whether or not to keep enclosed text
	selected.

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
	only the line ending delimiters from the previous line are included. The rest of the
	line is excluded.

Note: Be careful when using commands that emit stdout while reading stdin (as opposed
to emitting stdout only after stdin is closed). Input that generates more output
than an OS-specific pipe can hold may hang Textadept. On Linux, this may be 64K. See
[`spawn_proc:write()`](#spawn_proc.write).

Parameters:

- *command*:  The Linux, macOS, or Windows shell command to filter text through. May
	contain pipes.

<a id="textadept.editing.goto_line"></a>
#### `textadept.editing.goto_line`([*line*])

Moves the caret to the beginning of line number *line* or the user-specified line, ensuring
*line* is visible.

Parameters:

- *line*:  Optional line number to go to. If `nil`, the user is prompted for one.

<a id="textadept.editing.join_lines"></a>
#### `textadept.editing.join_lines`()

Joins the currently selected lines or the current line with the line below it.
As long as any part of a line is selected, the entire line is eligible for joining.

<a id="textadept.editing.paste_reindent"></a>
#### `textadept.editing.paste_reindent`()

Pastes the text from the clipboard, taking into account the buffer's indentation settings
and the indentation of the current and preceding lines.

<a id="textadept.editing.select_enclosed"></a>
#### `textadept.editing.select_enclosed`([*left*[, *right*]])

Selects the text between strings *left* and *right* that enclose the caret.
If that range is already selected, toggles between selecting *left* and *right* as well.
If *left* and *right* are not provided, they are assumed to be one of the delimiter pairs
specified in [`textadept.editing.auto_pairs`](#textadept.editing.auto_pairs) and are inferred from the current position
or selection.

Parameters:

- *left*:  Optional left part of the enclosure.
- *right*:  Optional right part of the enclosure.

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

- *all*:  Whether or not to select all occurrences of the current word. The default value is
	`false`.

See also:

- [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.editing.toggle_comment"></a>
#### `textadept.editing.toggle_comment`()

Comments or uncomments the selected lines based on the current language.
As long as any part of a line is selected, the entire line is eligible for
commenting/uncommenting.

See also:

- [`textadept.editing.comment_string`](#textadept.editing.comment_string)


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
#### `textadept.history.maximum_history_size` 

The maximum number of history records to keep per view.
The default value is `100`.

<a id="textadept.history.minimum_line_distance"></a>
#### `textadept.history.minimum_line_distance` 

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
#### `textadept.history.record`([*filename*[, *line*[, *column*[, *soft*=*false*]]]])

Records the given location in the current view's history.

Parameters:

- *filename*:  Optional string filename, buffer type, or identifier of the buffer to
	store. If `nil`, uses the current buffer.
- *line*:  Optional Integer line number to store. If `nil`, uses the current line.
- *column*:  Optional integer column number on line *line* to store. If `nil`,
	uses the current column.
- *soft*:  Optional flag that indicates whether or not this record should
	be skipped when navigating backward towards it, and updated when navigating away from it.


---
<a id="textadept.keys"></a>
## The `textadept.keys` Module
---

Defines key bindings for Textadept.
This set of key bindings is pretty standard among other text editors, at least for basic
editing commands and movements.

They are designed to be as consistent as possible between operating systems and platforms
so that users familiar with one set of bindings can intuit a given binding on another OS or
platform, minimizing the need for memorization.

In general, bindings for macOS are the same as for Windows/Linux except the "Control" modifier
key on Windows/Linux is replaced by "Command" (`⌘`) and the "Alt" modifier key is replaced by
"Control" (`^`). The only exception is for word- and paragraph-based movement keys, which use
"Alt" (`⌥`) instead of "Command" (`⌘`).

In general, bindings for the terminal version are the same as for Windows/Linux except:

- Most `Ctrl+Shift+`*`key`* combinations become `M-^`*`key`* since most terminals recognize
	few, if any, `Ctrl+Shift` key sequences.
- Most `Ctrl+`*`symbol`* combinations become `M-`*`symbol`* since most terminals recognize
	only a few `Ctrl` combinations with symbol keys.
- All `Ctrl+Alt+`*`key`* combinations become `M-`*`key`* except for word part movement keys
	and those involving `PgDn` and `PgUp`. The former are not supported and the latter use
	both modifier keys.
- `Ctrl+J` and `Ctrl+M` become `M-J` and `M-M`, respectively, because control sequences
	involving the `J` and `M` keys are often interpreted as involving the Enter key.

**Windows Note:** on international keyboard layouts, the "AltGr" key is equivalent to pressing
"Ctrl" and "Alt", so `AltGr+`*`key`* combinations may unexpectedly trigger one of Textadept's
`Ctrl+Alt+`*`key`* bindings. In order to avoid this, you will likely have to disable the
`Ctrl+Alt+`*`key`* binding in your *~/.textadept/init.lua* by setting it to `nil`.

### Key Bindings

Windows and Linux | macOS | Terminal | Command
-|-|-|-
**File**|||
Ctrl+N | ⌘N | ^N | New file
Ctrl+O | ⌘O | ^O | Open file
None | None | None | Open recent file...
None | None | None | Reload file
Ctrl+S | ⌘S | ^S<br/>M-S^(*) | Save file
Ctrl+Shift+S | ⌘⇧S | M-^S | Save file as..
None | None | None | Save all files
Ctrl+W | ⌘W | ^W | Close file
Ctrl+Shift+W | ⌘⇧W | M-^W | Close all files
None | None | None | Load session...
None | None | None | Save session...
Ctrl+Q | ⌘Q | ^Q<br/>M-Q^(*) | Quit
**Edit**| | |
Ctrl+Z<br/>Alt+Bksp | ⌘Z | ^Z^(†)<br/>M-Bksp | Undo
Ctrl+Y<br/>Ctrl+Shift+Z | ⌘⇧Z<br/>⌘Y | ^Y<br/>M-^Z | Redo
Ctrl+X<br/>Shift+Del | ⌘X<br/>⇧⌦ | ^X<br/>S-Del | Cut
Ctrl+C<br/>Ctrl+Ins | ⌘C | ^C | Copy
Ctrl+V<br/>Shift+Ins | ⌘V | ^V<br/>S-Ins | Paste
Ctrl+Shift+V | ⌘⇧V | M-^V | Paste Reindent
Ctrl+Shift+D | ⌘⇧D | M-^D | Duplicate line/selection
Del | ⌦<br/> ^D | Del | Delete
Alt+Del | ^⌦ | M-Del | Delete word
Ctrl+A | ⌘A | ^A | Select all
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
Ctrl+Shift+U^(‡)<br/>Ctrl+Alt+Shift+U | ⌘⇧U | M-^U | Upper case selection
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
Ctrl+Alt+U | ⌘⇧U | M-U | Quickly open [`_USERHOME`](#_USERHOME)
Ctrl+Alt+H | ⌘⇧H | M-H | Quickly open [`_HOME`](#_HOME)
None | None | None | Quickly open current directory
Ctrl+Shift+O | ⌘⇧O | M-^O | Quickly open current project
None | None | None | Insert snippet...
Tab | ⇥ | Tab | Expand snippet or next placeholder
Shift+Tab | ⇧⇥ | S-Tab | Previous snippet placeholder
Esc | Esc | Esc | Cancel snippet
None | None | None | Complete trigger word
None | None | None | Show style
**Buffer**| | |
Ctrl+Tab<br/>Ctrl+PgDn | ^⇥<br/>⌘⇟ | M-PgDn<br/> ^Tab^(§) | Next buffer
Ctrl+Shift+Tab<br/>Ctrl+PgUp | ^⇧⇥<br/>⌘⇞ | M-PgUp<br/>S-^Tab^(§) | Previous buffer
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
Ctrl+Shift+L | ⌘⇧L | M-^L | Select lexer...
**View**| | |
Ctrl+Alt+PgDn | ^⌘⇟ | M-^PgDn<br/>M-PgUp^(§) | Next view
Ctrl+Alt+PgUp | ^⌘⇞ | M-^PgUp<br/>M-PgDn^(§) | Previous view
Ctrl+Alt+_ | ^⌘_ | M-_ | Split view horizontal
Ctrl+Alt+&#124; | ^⌘&#124; | M-&#124; | Split view vertical
Ctrl+Alt+W | ^⌘W | M-W | Unsplit view
Ctrl+Alt+Shift+W | ^⌘⇧W | M-S-W | Unsplit all views
Ctrl+Alt++<br/>Ctrl+Alt+= | ^⌘+<br/>^⌘= | M-+<br/>M-= | Grow view
Ctrl+Alt+- | ^⌘- | M-- | Shrink view
Ctrl+} | ⌘} | M-} | Toggle current fold
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
Menu<br/> Shift+F10^(§) | N/A | N/A | Show context menu
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

*: For use when the `-p` or `--preserve` command line option is given to the non-Windows
terminal version, since ^S and ^Q are flow control sequences.

†: If you prefer ^Z to suspend, you can bind it to [`ui.suspend()`](#ui.suspend).

‡: Some versions of Linux intercept this for Unicode input.

§: Only on Windows or the GTK version on Linux.


---
<a id="textadept.macros"></a>
## The `textadept.macros` Module
---

A module for recording, playing, saving, and loading keyboard macros.
Menu commands are also recorded.
At this time, typing into multiple cursors during macro playback is not supported.

### Functions defined by `textadept.macros`

<a id="textadept.macros.load"></a>
#### `textadept.macros.load`([*filename*])

Loads a macro from file *filename* or the user-selected file.

Parameters:

- *filename*:  Optional macro file to load. If `nil`, the user is prompted for one. If
	the filename is a relative path, it will be relative to *[`_USERHOME`](#_USERHOME)/macros/*.

<a id="textadept.macros.play"></a>
#### `textadept.macros.play`([*filename*])

Plays a recorded or previously loaded macro, or loads and plays the macro from file *filename*
if given.

Parameters:

- *filename*:  Optional filename of a macro to load and play. If the filename is a
	relative path, it will be relative to *[`_USERHOME`](#_USERHOME)/macros/*.

<a id="textadept.macros.record"></a>
#### `textadept.macros.record`()

Toggles between starting and stopping macro recording.

<a id="textadept.macros.save"></a>
#### `textadept.macros.save`([*filename*])

Saves a recorded macro to file *filename* or the user-selected file.

Parameters:

- *filename*:  Optional filename to save the recorded macro to. If `nil`, the user
	is prompted for one. If the filename is a relative path, it will be relative to
	*[`_USERHOME`](#_USERHOME)/macros/*.


---
<a id="textadept.menu"></a>
## The `textadept.menu` Module
---

Defines the menus used by Textadept.
Menus are simply tables of menu items and submenus and may be edited in place. A menu item
itself is a table whose first element is a menu label and whose second element is a menu
command to run. Submenus have `title` keys assigned to string text.

### Fields defined by `textadept.menu`

<a id="textadept.menu.context_menu"></a>
#### `textadept.menu.context_menu` &lt;table&gt;

The default right-click context menu.
Submenus, and menu items can be retrieved by name in addition to table index number.

Usage:

- `textadept.menu.context_menu[#textadept.menu.context_menu + 1] = {...}
`

<a id="textadept.menu.menubar"></a>
#### `textadept.menu.menubar` &lt;table&gt;

The default main menubar.
Individual menus, submenus, and menu items can be retrieved by name in addition to table
index number.
As a convenience, a single menu path may be used, with submenus delineated by '/'. Labels
are localized as needed, so English labels or their localized equivalent may be used.

Usage:

- `textadept.menu.menubar['File/New']
`
- `textadept.menu.menubar['File/New'][2] = function() .. end
`

<a id="textadept.menu.tab_context_menu"></a>
#### `textadept.menu.tab_context_menu` &lt;table&gt;

The default tabbar context menu.
Submenus, and menu items can be retrieved by name in addition to table index number.


### Functions defined by `textadept.menu`

<a id="textadept.menu.select_command"></a>
#### `textadept.menu.select_command`()

Prompts the user to select a menu command to run.


---
<a id="textadept.run"></a>
## The `textadept.run` Module
---

Compile and run source code files with Textadept.
Language [modules][] may tweak the [`textadept.run.compile_commands`](#textadept.run.compile_commands), and
[`textadept.run.run_commands`](#textadept.run.run_commands) tables for particular languages. The user may
tweak [`textadept.run.build_commands`](#textadept.run.build_commands), [`textadept.run.test_commands`](#textadept.run.test_commands), and
[`textadept.run.run_project_commands`](#textadept.run.run_project_commands) for particular projects.

[modules]: manual.html#modules

### Fields defined by `textadept.run`

<a id="textadept.run.INDIC_ERROR"></a>
#### `textadept.run.INDIC_ERROR` 

The run or compile error indicator number.

<a id="textadept.run.INDIC_WARNING"></a>
#### `textadept.run.INDIC_WARNING` 

The run or compile warning indicator number.

<a id="textadept.run.MARK_ERROR"></a>
#### `textadept.run.MARK_ERROR` 

The run or compile error marker number.

<a id="textadept.run.MARK_WARNING"></a>
#### `textadept.run.MARK_WARNING` 

The run or compile warning marker number.

<a id="textadept.run.build_commands"></a>
#### `textadept.run.build_commands` &lt;table&gt;

Map of project root paths and "makefiles" to their associated "build" shell command line
strings or functions that return such strings.
Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

<a id="textadept.run.compile_commands"></a>
#### `textadept.run.compile_commands` &lt;table&gt;

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

<a id="textadept.run.run_commands"></a>
#### `textadept.run.run_commands` &lt;table&gt;

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

<a id="textadept.run.run_in_background"></a>
#### `textadept.run.run_in_background` 

Run shell commands silently in the background.
The default value is `false`.

<a id="textadept.run.run_project_commands"></a>
#### `textadept.run.run_project_commands` &lt;table&gt;

Map of project root paths to their associated "run" shell command line strings or functions
that return such strings.
Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.

<a id="textadept.run.run_without_prompt"></a>
#### `textadept.run.run_without_prompt` 

Run shell commands without prompting.
The default value is `false`.

<a id="textadept.run.test_commands"></a>
#### `textadept.run.test_commands` &lt;table&gt;

Map of project root paths to their associated "test" shell command line strings or functions
that return such strings.
Functions may also return a working directory and process environment table to operate
in. By default, the working directory is the project's root directory and the environment
is Textadept's environment.


### Functions defined by `textadept.run`

<a id="textadept.run.build"></a>
#### `textadept.run.build`([*dir*])

Prompts the user with the command entry to build the project whose root path is *dir*
or the current project using the shell command from the [`textadept.run.build_commands`](#textadept.run.build_commands) table.
The current project is determined by either the buffer's filename or the current working
directory.
Emits [`events.BUILD_OUTPUT`](#events.BUILD_OUTPUT).

Parameters:

- *dir*:  Optional path to the project to build. The default value is the current project.

<a id="textadept.run.compile"></a>
#### `textadept.run.compile`([*filename*=*buffer*.*filename*])

Prompts the user with the command entry to compile file *filename* or the current file using
an appropriate shell command from the [`textadept.run.compile_commands`](#textadept.run.compile_commands) table.
The shell command is determined from the file's filename, extension, or language, in that order.
Emits [`events.COMPILE_OUTPUT`](#events.COMPILE_OUTPUT).

Parameters:

- *filename*:  Optional path to the file to compile.

<a id="textadept.run.goto_error"></a>
#### `textadept.run.goto_error`(*location*)

Jumps to the source of the next or previous recognized compile/run warning or error in
the output buffer, or the warning/error on a given line number, depending on the value
of *location*.
Displays an annotation with the warning or error message if possible.

Parameters:

- *location*:  When `true`, jumps to the next recognized warning/error. When `false`,
	jumps to the previous one. When a line number, jumps to it.

<a id="textadept.run.run"></a>
#### `textadept.run.run`([*filename*=*buffer*.*filename*])

Prompts the user with the command entry to run file *filename* or the current file using an
appropriate shell command from the [`textadept.run.run_commands`](#textadept.run.run_commands) table.
The shell command is determined from the file's filename, extension, or language, in that order.
Emits [`events.RUN_OUTPUT`](#events.RUN_OUTPUT).

Parameters:

- *filename*:  Optional path to the file to run.

<a id="textadept.run.run_project"></a>
#### `textadept.run.run_project`([*dir*[, *cmd*]])

Prompts the user with the command entry to run shell command *cmd* or the shell command
from the [`textadept.run.run_project_commands`](#textadept.run.run_project_commands) table for the project whose root path is *dir*
or the current project.
The current project is determined by either the buffer's filename or the current working
directory.
Emits [`events.RUN_OUTPUT`](#events.RUN_OUTPUT).

Parameters:

- *dir*:  Optional path to the project to run a command for. The default value is the
	current project.
- *cmd*:  Optional string command to run. If given, the command entry initially
	shows this command. The default value comes from [`textadept.run.run_project_commands`](#textadept.run.run_project_commands)
	and *dir*.

<a id="textadept.run.stop"></a>
#### `textadept.run.stop`()

Stops the currently running process, if any.
If there is more than one running process, the user is prompted to select the process to stop.
Processes in the list are sorted from longest lived at the top to shortest lived on the bottom.

<a id="textadept.run.test"></a>
#### `textadept.run.test`([*dir*])

Prompts the user with the command entry to run tests for the project whose root path is *dir*
or the current project using the shell command from the [`textadept.run.test_commands`](#textadept.run.test_commands) table.
The current
project is determined by either the buffer's filename or the current working directory.
Emits [`events.TEST_OUTPUT`](#events.TEST_OUTPUT).

Parameters:

- *dir*:  Optional path to the project to run tests for. The default value is the
	current project.


---
<a id="textadept.session"></a>
## The `textadept.session` Module
---

Session support for Textadept.

### Fields defined by `textadept.session`

<a id="textadept.session.save_on_quit"></a>
#### `textadept.session.save_on_quit` 

Save the session when quitting.
The default value is `true` unless the user passed the command line switch `-n` or `--nosession`
to Textadept.


### Functions defined by `textadept.session`

<a id="textadept.session.load"></a>
#### `textadept.session.load`([*filename*])

Loads session file *filename* or the user-selected session, returning `true` if a session
file was opened and read.
Textadept restores split views, opened buffers, cursor information, recent files, and bookmarks.

Parameters:

- *filename*:  Optional absolute path to the session file to load. If `nil`, the user
	is prompted for one.

Usage:

- `textadept.session.load(filename)
`

Return:

- `true` if the session file was opened and read; `nil` otherwise.

<a id="textadept.session.save"></a>
#### `textadept.session.save`(*filename*)

Saves the session to file *filename* or the user-selected file.
Saves split views, opened buffers, cursor information, recent files, and bookmarks.
Upon quitting, the current session is saved to *filename* again, unless
[`textadept.session.save_on_quit`](#textadept.session.save_on_quit) is `false`.

Parameters:

- *filename*: Optional absolute path to the session file to save. If `nil`, the user
	is prompted for one.

Usage:

- `textadept.session.save(filename)
`


---
<a id="textadept.snippets"></a>
## The `textadept.snippets` Module
---

Snippets for Textadept.

### Overview

Define snippets in the global [`snippets`](#snippets) table in key-value pairs. Each pair consists of
either a string trigger word and its snippet text, or a string lexer name (from the *lexers/*
directory) with a table of trigger words and snippet texts. When searching for a snippet to
insert based on a trigger word, Textadept considers snippets in the current lexer to have
priority, followed by the ones in the global table. This means if there are two snippets
with the same trigger word, Textadept inserts the one specific to the current lexer, not
the global one.

### Syntax

Snippets may contain any combination of plain-text sequences, variables, interpolated code,
and placeholders.

#### Plain Text

Plain text consists of any character except '$' and '\`'. Those two characters are reserved for
variables, interpolated code, and placeholders. In order to use either of those two characters
literally, prefix them with '\' (e.g. `\$` inserts a literal '$').

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

	snippets.eval = '`echo $(( $TM_SELECTED_TEXT ))`'

#### Interpolated Lua Code

Snippets can also execute Lua code enclosed within "\`\`\`" sequences, and insert any string
results returned by that code. For example, the following snippet inserts the current date
and time:

	snippets.date = '```os.date()```'

Lua code is executed within Textadept's Lua environment, with the addition of snippet
variables available as global variables (e.g. `TM_SELECTED_TEXT` exists as a global).

#### Placeholders

The true power of snippets lies with placeholders. Using placeholders, you can insert a text
template and tab through placeholders one at a time, filling them in. Placeholders may be
linked to one another, either mirroring text or transforming it in-place.

##### Tab Stops

The simplest kind of placeholder is called a tab stop, and its syntax is either `$`*n*
or `${`*n*`}`, where *n* is an integer. When a snippet is inserted, the caret is moved
to the "$1" placeholder. Pressing the `Tab` key jumps to the next placeholder, "$2", and
so on. When there are no more placeholders to jump to, the caret moves to either the "$0"
placeholder if it exists, or it moves to the end of the snippet. For example, the following
snippet inserts a 3-element vector, with tab stops at each element:

	snippets.vec = '[$1, $2, $3]'

##### Default Values

Placeholders may have default values using the "${*n*:*default*}" syntax. For example,
the following snippet creates a numeric "for" loop in Lua:

	snippets.lua.fori = [[
	for ${1:i} = ${2:1}, $3 do
		$0
	end]]

Multiline snippets should be indented with tabs. Textadept will apply the buffer's current
indentation settings to the snippet upon insertion.

Placeholders may be nested inside one another. For example, the following snippet inserts
a function call with a mandatory first argument, but an optional second one:

	snippets.call = '${1:func}($2${3:, $4})'

Upon arriving at the third placeholder, backspacing and pressing `Tab` completes the snippet
with a single argument. On the other hand, pressing `Tab` again at the third placeholder
jumps to the second argument for input.

Note that plain text inside default values may not contain a '}' character either, as it is
reserved to indicate the end of the placeholder. Use `\}` to represent a literal '}'.

##### Mirrors

Multiple placeholders can share the same numeric index. When this happens, Textadept visits
the one with a default value if it exists. Otherwise, the editor visits the first one it
finds. As you type text into a placeholder, any other placeholders with the same index mirror
the typed text. For example, the following snippet inserts beginning and ending HTML/XML
tags with the same name:

	snippets.tag = '<${1:div}>$0</$1>'

The end tag mirrors whatever name you type into the start tag.

##### Transforms

Sometimes mirrors are not quite good enough. For example, perhaps the mirror's content needs to
deviate slightly from its linked placeholder, like capitalizing the first letter. Or perhaps
the mirror's contents should depend on the presence (or absence) of text in its linked
placeholder. This is where placeholder transforms come in handy. They have the following
syntax: "${*n*/*regex*/*format*/*options*}". *regex* is a [regular expression][] (regex)
to match against the content of placeholder *n*, *format* is a formatted replacement for
matched content, and *options* are regex options to use when matching. *format* may contain
any of the following:

- Plain text.
- "$*n*" and "${*n*}" sequences, which represent the content of the *n*th capture (*n*=0 is
	the entire match for this and all subsequent sequences).
- "${*n*:/upcase}", "${*n*:/downcase}", and "${*n*:/capitalize}" sequences, which
	represent the uppercase, lowercase, and capitalized forms, respectively, of the
	content of the *n*th capture. You can define your own transformation function in
	[`textadept.snippets.transform_methods`](#textadept.snippets.transform_methods).
- A "${*n*:?*if*:*else*}" sequence, which inserts *if* if the content of capture *n* is
	non-empty. Otherwise, *else* is used.
- A "${*n*:+*if*}" sequence, which inserts *if* if the content of capture *n* is
	non-empty. Otherwise nothing is inserted.
- "${*n*:*default*}" and "${*n*:-*default*}" sequences, which insert *default* if the content
	of capture *n* is empty. Otherwise, capture *n* is mirrored.

*options* may include any of the following letters:

- g: Replace all instances of matched text, not just the first one.

For example, the following snippet defines an attribute along with its getter and setter functions:

	snippets.attr = [[
		${1:int} ${2:name};

		${1} get${2/./${0:/upcase}/}() { return $2; }
		void set${2/./${0:/upcase}/}(${1} ${3:value}) { $2 = $3; }
	]]

Note that the '/' and '}' characters are reserved in certain places within a placeholder
transform. Use `\/` and `\}`, respectively, to represent literal versions of those characters
where necessary.

[regular expression]: manual.html#regex-and-lua-pattern-syntax

##### Multiple Choices

Placeholders may define a list of options for the user to choose from using the
"${*n*|*items*|}" syntax, where *items* is a comma-separated list of options
(e.g. `${1|foo,bar,baz|}`).

Items may not contain a '\|' character, as it is reserved to indicate the end of the choice list.
Use `\|` to represent a literal '\|'.

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


### Fields defined by `textadept.snippets`

<a id="textadept.snippets.INDIC_PLACEHOLDER"></a>
#### `textadept.snippets.INDIC_PLACEHOLDER` 

The snippet placeholder indicator number.

<a id="textadept.snippets.active"></a>
#### `textadept.snippets.active` 

Whether or not a snippet is active.

<a id="textadept.snippets.paths"></a>
#### `textadept.snippets.paths` &lt;table&gt;

List of directory paths to look for snippet files in.
Filenames are of the form *lexer.trigger.ext* or *trigger.ext* (*.ext* is an optional,
arbitrary file extension). If the global [`snippets`](#snippets) table does not contain a snippet for
a given trigger, this table is consulted for a matching filename, and the contents of that
file is inserted as a snippet.
Note: If a directory has multiple snippets with the same trigger, the snippet chosen for
insertion is not defined and may not be constant.

<a id="textadept.snippets.transform_methods"></a>
#### `textadept.snippets.transform_methods` &lt;table&gt;

Map of format method names to their functions for text captured in placeholder transforms.

Fields:

- `upcase`:  Uppercases the captured text.
- `downcase`:  Lowercases the captured text.
- `capitalize`:  Capitalizes the captured text.

<a id="textadept.snippets.variables"></a>
#### `textadept.snippets.variables` &lt;table&gt;

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


### Functions defined by `textadept.snippets`

<a id="textadept.snippets.cancel"></a>
#### `textadept.snippets.cancel`()

Cancels the active snippet, removing all inserted text.
Returns `false` if no snippet is active.

Return:

- `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.insert"></a>
#### `textadept.snippets.insert`([*text*])

Inserts snippet text *text* or the snippet assigned to the trigger word behind the caret.
Otherwise, if a snippet is active, goes to the active snippet's next placeholder. Returns
`false` if no action was taken.

Parameters:

- *text*:  Optional snippet text to insert. If `nil`, attempts to insert a new snippet
	based on the trigger, the word behind caret, and the current lexer.

Return:

- `false` if no action was taken; `nil` otherwise.

See also:

- [`buffer.word_chars`](#buffer.word_chars)

<a id="textadept.snippets.previous"></a>
#### `textadept.snippets.previous`()

Jumps back to the previous snippet placeholder, reverting any changes from the current one.
Returns `false` if no snippet is active.

Return:

- `false` if no snippet is active; `nil` otherwise.

<a id="textadept.snippets.select"></a>
#### `textadept.snippets.select`()

Prompts the user to select a snippet to insert from a list of global and language-specific
snippets.


---
<a id="ui"></a>
## The `ui` Module
---

Utilities for interacting with Textadept's user interface.

### Fields defined by `ui`

<a id="ui.SHOW_ALL_TABS"></a>
#### `ui.SHOW_ALL_TABS` 

Option for [`ui.tabs`](#ui.tabs) that always shows the tab bar, even if only one buffer is open.

<a id="ui.buffer_list_zorder"></a>
#### `ui.buffer_list_zorder` 

Whether or not to list buffers by their z-order (most recently viewed to least recently
viewed) in the switcher dialog.
The default value is `true`.

<a id="ui.buffer_statusbar_text"></a>
#### `ui.buffer_statusbar_text` 

The text displayed in the buffer statusbar. (Write-only)

<a id="ui.clipboard_text"></a>
#### `ui.clipboard_text` 

The text on the clipboard.

<a id="ui.context_menu"></a>
#### `ui.context_menu` 

The buffer's context menu, a [`ui.menu()`](#ui.menu).
This is a low-level field. You probably want to use the higher-level
[`textadept.menu.context_menu`](#textadept.menu.context_menu).

<a id="ui.maximized"></a>
#### `ui.maximized` 

Whether or not Textadept's window is maximized.
This field is always `false` in the terminal version.

<a id="ui.menubar"></a>
#### `ui.menubar` &lt;table&gt;

A table of menus defining a menubar. (Write-only).
This is a low-level field. You probably want to use the higher-level [`textadept.menu.menubar`](#textadept.menu.menubar).

<a id="ui.size"></a>
#### `ui.size` &lt;table&gt;

A table containing the width and height pixel values of Textadept's window.

<a id="ui.statusbar_text"></a>
#### `ui.statusbar_text` 

The text displayed in the statusbar. (Write-only)

<a id="ui.tab_context_menu"></a>
#### `ui.tab_context_menu` 

The context menu for the buffer's tab, a [`ui.menu()`](#ui.menu).
This is a low-level field. You probably want to use the higher-level
[`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu).

<a id="ui.tabs"></a>
#### `ui.tabs` 

Whether or not to display the tab bar when multiple buffers are open.
The default value is `true`.
A third option, [`ui.SHOW_ALL_TABS`](#ui.SHOW_ALL_TABS) may be used to always show the tab bar, even if only one
buffer is open.

<a id="ui.title"></a>
#### `ui.title` 

The title text of Textadept's window. (Write-only)


### Functions defined by `ui`

<a id="ui.get_split_table"></a>
#### `ui.get_split_table`()

Returns a split table that contains Textadept's current split view structure.
This is primarily used in session saving.

Return:

-  table of split views. Each split view entry is a table with 4 fields: `1`, `2`,
	`vertical`, and `size`. `1` and `2` have values of either nested split view entries or
	the views themselves; `vertical` is a flag that indicates if the split is vertical or
	not; and `size` is the integer position of the split resizer.

<a id="ui.goto_file"></a>
#### `ui.goto_file`(*filename*[, *split*=*false*[, *preferred_view*[, *sloppy*=*false*]]])

Switches to the existing view whose buffer's filename is *filename*.
If no view was found and *split* is `true`, splits the current view in order to show the
requested file. If *split* is `false`, shifts to the next or *preferred_view* view in order
to show the requested file. If *sloppy* is `true`, requires only the basename of *filename*
to match a buffer's [`buffer.filename`](#buffer.filename). If the requested file was not found, it is opened in
the desired view.

Parameters:

- *filename*:  The filename of the buffer to go to.
- *split*:  Optional flag that indicates whether or not to open the buffer in
	a split view if there is only one view.
- *preferred_view*:  Optional view to open the desired buffer in if the buffer
	is not visible in any other view.
- *sloppy*:  Optional flag that indicates whether or not to not match
	*filename* to [`buffer.filename`](#buffer.filename) exactly. When `true`, matches *filename* to only the
	last part of [`buffer.filename`](#buffer.filename) This is useful for run and compile commands which output
	relative filenames and paths instead of full ones and it is likely that the file in
	question is already open.

<a id="ui.goto_view"></a>
#### `ui.goto_view`(*view*)

Shifts to view *view* or the view *view* number of views relative to the current one.
Emits [`events.VIEW_BEFORE_SWITCH`](#events.VIEW_BEFORE_SWITCH) and [`events.VIEW_AFTER_SWITCH`](#events.VIEW_AFTER_SWITCH).

Parameters:

- *view*:  A view or relative view number (typically 1 or -1).

<a id="ui.menu"></a>
#### `ui.menu`(*menu_table*)

Low-level function for creating a menu from table *menu_table* and returning the userdata.
You probably want to use the higher-level [`textadept.menu.menubar`](#textadept.menu.menubar),
[`textadept.menu.context_menu`](#textadept.menu.context_menu), or [`textadept.menu.tab_context_menu`](#textadept.menu.tab_context_menu) tables.
Emits [`events.MENU_CLICKED`](#events.MENU_CLICKED) when a menu item is selected.

Parameters:

- *menu_table*:  A table defining the menu. It is an ordered list of tables with a string
	menu item, integer menu ID, and optional keycode and modifier mask. The latter two are
	used to display key shortcuts in the menu. '&' characters are treated as a menu mnemonics
	in Qt ('_' is the equivalent in GTK). If the menu item is empty, a menu separator item
	is created. Submenus are just nested menu-structure tables. Their title text is defined
	with a `title` key.

Usage:

- `ui.menu{ {'_New', 1}, {'_Open', 2}, {''}, {'&Quit', 4} }
`
- `ui.menu{ {'_New', 1, string.byte('n'), view.MOD_CTRL} } -- 'Ctrl+N'
`

<a id="ui.output"></a>
#### `ui.output`(...)

Prints the given value(s) to the output buffer, and returns that buffer.
Opens a new buffer if one has not already been opened for printing output. The output buffer
attempts to understand the error messages and warnings produced by various tools.

Parameters:

- *...*:  Output to print.

Return:

- output buffer

See also:

- [`ui.output_silent`](#ui.output_silent)

<a id="ui.output_silent"></a>
#### `ui.output_silent`(...)

Silently prints the given value(s) to the output buffer, and returns that buffer.
Opens a new buffer for printing to if necessary.

Parameters:

- *...*:  Output to print.

Return:

- output buffer

See also:

- [`ui.output`](#ui.output)

<a id="ui.popup_menu"></a>
#### `ui.popup_menu`(*menu*)

Displays a popup menu, typically the right-click context menu.

Parameters:

- *menu*:  Menu to display.

Usage:

- `ui.popup_menu(ui.context_menu)
`

See also:

- [`ui.context_menu`](#ui.context_menu)
- [`ui.menu`](#ui.menu)

<a id="ui.print"></a>
#### `ui.print`(...)

Prints the given value(s) to the message buffer, along with a trailing newline.
Opens a new buffer if one has not already been opened for printing messages.

Parameters:

- *...*:  Message or values to print. Lua's `tostring()` function is called for each value.
	They will be printed as tab-separated values.

<a id="ui.print_silent"></a>
#### `ui.print_silent`(...)

Silently prints the given value(s) to the message buffer, and returns that buffer.

Parameters:

- *...*:  Message or values to print.

Return:

- print buffer

See also:

- [`ui.print`](#ui.print)

<a id="ui.print_silent_to"></a>
#### `ui.print_silent_to`(*type*, ...)

Silently prints the given value(s) to the buffer of string type *type*, and returns that
buffer.
Opens a new buffer for printing to if necessary.

Parameters:

- *type*:  String type of print buffer.
- *...*:  Message or values to print. Lua's `tostring()` function is called for each value.
	They will be printed as tab-separated values.

Return:

- print buffer

See also:

- [`ui.print_to`](#ui.print_to)

<a id="ui.print_to"></a>
#### `ui.print_to`(*type*, ...)

Prints the given value(s) to the buffer of string type *type*, along with a trailing newline,
and returns that buffer.
Opens a new buffer for printing to if necessary. If the print buffer is already open in a
view, the value(s) is printed to that view. Otherwise the view is split (unless [`ui.tabs`](#ui.tabs)
is `true`) and the print buffer is displayed before being printed to.

Parameters:

- *type*:  String type of print buffer.
- *...*:  Message or values to print. Lua's `tostring()` function is called for each value.
	They will be printed as tab-separated values.

Usage:

- `ui.print_to(_L['[Message Buffer]'], message)
`

Return:

- print buffer

See also:

- [`ui.print_silent_to`](#ui.print_silent_to)

<a id="ui.suspend"></a>
#### `ui.suspend`()

Suspends Textadept.
This only works in the terminal version. By default, Textadept ignores ^Z suspend signals from
the terminal.
Emits [`events.SUSPEND`](#events.SUSPEND) and [`events.RESUME`](#events.RESUME).

Usage:

- `keys['ctrl+z'] = ui.suspend
`

<a id="ui.switch_buffer"></a>
#### `ui.switch_buffer`()

Prompts the user to select a buffer to switch to.
Buffers are listed in the order they were opened unless [`ui.buffer_list_zorder`](#ui.buffer_list_zorder) is `true`, in
which case buffers are listed by their z-order (most recently viewed to least recently viewed).
Buffers in the same project as the current buffer are shown with relative paths.

<a id="ui.update"></a>
#### `ui.update`()

Processes pending UI events, including reading from spawned processes.
This function is primarily used in unit tests.


---
<a id="ui.command_entry"></a>
## The `ui.command_entry` Module
---

Textadept's Command Entry.
It supports multiple modes that each have their own functionality (such as running Lua code
and filtering text through shell commands) and history.
In addition to the functions and fields listed below, the command entry also has the same
functions and fields that [`buffer`](#buffer)s and [`view`](#view)s do.

### Fields defined by `ui.command_entry`

<a id="ui.command_entry.active"></a>
#### `ui.command_entry.active` 

Whether or not the command entry is active.

<a id="ui.command_entry.editing_keys"></a>
#### `ui.command_entry.editing_keys` &lt;table&gt;

A metatable with typical platform-specific key bindings for text entries.
This metatable may be used to add basic editing and movement keys to command entry modes. It
is automatically added to command entry modes unless a metatable was previously set.

Usage:

- `setmetatable(mode_keys, ui.command_entry.editing_keys)
`

<a id="ui.command_entry.height"></a>
#### `ui.command_entry.height` 

The height in pixels of the command entry.


### Functions defined by `ui.command_entry`

<a id="ui.command_entry.focus"></a>
#### `ui.command_entry.focus`()

Opens the command entry.

<a id="ui.command_entry.run"></a>
#### `ui.command_entry.run`(*label*, *f*[, *keys*][, *lang*='*text*'[, *initial_text*[, ...]]])

Opens the command entry with label *label* (and optionally with string *initial_text*),
subjecting it to any key bindings defined in table *keys*, highlighting text with lexer
name *lang*, and then when the `Enter` key is pressed, closes the command entry and calls
function *f* (if non-`nil`) with the command entry's text as an argument, along with any
extra arguments passed to this function.
By default with no arguments given, opens a Lua command entry.
The command entry does not respond to Textadept's default key bindings, but instead to the
key bindings defined in *keys* and in [`ui.command_entry.editing_keys`](#ui.command_entry.editing_keys).

Parameters:

- *label*:  String label to display in front of input.
- *f*:  Function to call upon pressing `Enter` in the command entry, ending the mode.
	It should accept at a minimum the command entry text as an argument.
- *keys*:  Optional table of key bindings to respond to. This is in addition to the
	basic editing and movement keys defined in [`ui.command_entry.editing_keys`](#ui.command_entry.editing_keys). `Esc` and
	`Enter` are automatically defined to cancel and finish the command entry, respectively.
- *lang*:  Optional string lexer name to use for command entry text.
- *initial_text*:  Optional string of text to initially show in the command entry. The
	default value comes from the command history for *f*.
- *...*:  Optional additional arguments to pass to *f*.

Usage:

- `ui.command_entry.run('echo:', ui.print)
`


---
<a id="ui.dialogs"></a>
## The `ui.dialogs` Module
---

Provides a set of interactive dialog prompts for user input.

### Functions defined by `ui.dialogs`

<a id="ui.dialogs.input"></a>
#### `ui.dialogs.input`(*options*)

Prompts the user with an input dialog defined by dialog options table *options*, returning
the user's input text.
If the user canceled the dialog, returns `nil`.

Parameters:

- *options*:  Table of key-value option pairs for the inputbox.

 - `title`: The dialog's title text.
 - `text`: The dialog's initial input text.
 - `button1`: The primary (accept) button's label. The default value is `_L['OK']`.
 - `button2`: The secondary (reject) button's label. The default value is `_L['Cancel']`.
 - `button3`: The tertiary button's label. This option requires `button2` to be set. It is
	not available on Qt.
 - `return_button`: Also return the index of the selected button. The default value is `false`.

Usage:

- `ui.dialogs.input{title = 'Go to line number:', text = '1'}
`

Return:

- input text[, selected button]

<a id="ui.dialogs.list"></a>
#### `ui.dialogs.list`(*options*)

Prompts the user with a list item selection dialog defined by dialog options table *options*,
returning the integer index of the selected item or a table of indices of the selected items
(depending on whether or not *options*.`multiple` is `true`).
If the user canceled the dialog, returns `nil`.
Text typed into the dialog filters the list items. Spaces are treated as wildcards.

Parameters:

- *options*:  Table of key-value option pairs for the list dialog.

 - `title`: The dialog's title text.
 - `text`: The dialog's initial input text.
 - `columns`: The list of string column names for list rows. If this field is omitted,
	a single column is used.
 - `items`: The list of string items to show in the list. Each item is placed in the next
	available column of the current row. If there is only one column, each item is on its
	own row.
 - `button1`: The primary (accept) button's label. The default value is `_L['OK']`.
 - `button2`: The secondary (reject) button's label. The default value is `_L['Cancel']`.
 - `button3`: The tertiary button's label. This option requires `button2` to be set.
 - `multiple`: Allow the user to select multiple items. The default value is `false`.
	The terminal version does not support this option.
 - `search_column`: The column number to filter the input text against. The default value is `1`.
 - `return_button`: Also return the index of the selected button. The default value is `false`.

Usage:

- `ui.dialogs.list{title = 'Title', columns = {'Foo', 'Bar'}, items = {'a', 'b', 'c', 'd'}}
`

Return:

- selected item or list of selected items[, selected button]

<a id="ui.dialogs.message"></a>
#### `ui.dialogs.message`(*options*)

Prompts the user with a generic message box dialog defined by dialog options table *options*,
returning the selected button's index.
If the user canceled the dialog, returns `nil`.

Parameters:

- *options*:  Table of key-value option pairs for the message box.

 - `title`: The dialog's title text.
 - `text`: The dialog's main message text.
 - `icon`: The dialog's icon name, according to the Free Desktop Icon Naming
	Specification. Examples are "dialog-error", "dialog-information", "dialog-question",
	and "dialog-warning". The dialog does not display an icon by default.
 - `button1`: The primary (accept) button's label. The default value is `_L['OK']`.
 - `button2`: The secondary (reject) button's label.
 - `button3`: The tertiary button's label. This option requires `button2` to be set.

Usage:

- `ui.dialogs.message{title = 'EOL Mode', text = 'Which EOL?', icon = 'dialog-question',
	button1 = 'CRLF', button2 = 'CR', button3 = 'LF'}
`

Return:

- selected button

<a id="ui.dialogs.open"></a>
#### `ui.dialogs.open`(*options*)

Prompts the user with a file open dialog defined by dialog options table *options*, returning
the string file selected.
If *options*.`multiple` is `true`, returns the list of files selected. If the user canceled
the dialog, returns `nil`.

Parameters:

- *options*:  Table of key-value option pairs for the dialog.

 - `title`: The dialog's title text.
 - `dir`: The initial filesystem directory to show.
 - `file`: The initially selected filename. This option requires `dir` to be set.
 - `multiple`: Allow the user to select multiple files. The default value is `false`.
	The terminal version does not support this option.
 - `only_dirs`: Only allow the user to select directories. The default value is `false`.

Usage:

- `ui.dialogs.open{title = 'Open File', dir = _HOME, multiple = true}
`

Return:

- filename, list of filenames, or nil

<a id="ui.dialogs.progress"></a>
#### `ui.dialogs.progress`(*options*)

Displays a progress dialog, defined by dialog options table *options*, returning true if
the user clicked the "Stop" button, or `nil` if the dialog finishes.

Parameters:

- *options*:  Table of key-value option pairs for the progressbar dialog.

 - `title`: The dialog's title text.
 - `text`: The initial progressbar display text (GUI only).
 - `work`: The function repeatedly called to do work and provide progress updates. The
	function is called without arguments and must return either `nil`, which indicates work
	is complete, or a progress percentage number in the range 0-100 and an optional string
	to display (GUI only). If progress is indeterminate, the percentage can be less than zero.

Usage:

- `ui.dialogs.progress{
	work = function() if work() then return percent, status else return nil end end}
`

Return:

- nil if all work completed, or true if work was stopped

<a id="ui.dialogs.save"></a>
#### `ui.dialogs.save`(*options*)

Prompts the user with a file save dialog defined by dialog options table *options*, returning
the string file chosen.
If the user canceled the dialog, returns `nil`.

Parameters:

- *options*:  Table of key-value option pairs for the dialog.

 - `title`: The dialog's title text.
 - `dir`: The initial filesystem directory to show.
 - `file`: The initially chosen filename. This option requires `dir` to be set.

Return:

- filename or nil


---
<a id="ui.find"></a>
## The `ui.find` Module
---

Textadept's Find & Replace pane.

### Fields defined by `ui.find`

<a id="ui.find.INDIC_FIND"></a>
#### `ui.find.INDIC_FIND` 

The find results highlight indicator number.

<a id="ui.find.active"></a>
#### `ui.find.active` 

Whether or not the Find & Replace pane is active.

<a id="ui.find.entry_font"></a>
#### `ui.find.entry_font` 

The font to use in the "Find" and "Replace" entries in "name size" format. (Write-only)
The default value is system-dependent.

<a id="ui.find.find_entry_text"></a>
#### `ui.find.find_entry_text` 

The text in the "Find" entry.

<a id="ui.find.find_in_files_filters"></a>
#### `ui.find.find_in_files_filters` &lt;table&gt;

Map of directory paths to filters used in [`ui.find.find_in_files()`](#ui.find.find_in_files).
This table is updated when the user manually specifies a filter in the "Filter" entry during
an "In files" search.

<a id="ui.find.find_label_text"></a>
#### `ui.find.find_label_text` 

The text of the "Find" label. (Write-only)
This is primarily used for localization.

<a id="ui.find.find_next_button_text"></a>
#### `ui.find.find_next_button_text` 

The text of the "Find Next" button. (Write-only)
This is primarily used for localization.

<a id="ui.find.find_prev_button_text"></a>
#### `ui.find.find_prev_button_text` 

The text of the "Find Prev" button. (Write-only)
This is primarily used for localization.

<a id="ui.find.highlight_all_matches"></a>
#### `ui.find.highlight_all_matches` 

Whether or not to highlight all occurrences of found text in the current buffer.
The default value is `false`.

<a id="ui.find.in_files"></a>
#### `ui.find.in_files` 

Find search text in a directory of files.
The default value is `false`.

<a id="ui.find.in_files_label_text"></a>
#### `ui.find.in_files_label_text` 

The text of the "In files" label. (Write-only)
This is primarily used for localization.

<a id="ui.find.incremental"></a>
#### `ui.find.incremental` 

Find search text incrementally as it is typed.
The default value is `false`.

<a id="ui.find.match_case"></a>
#### `ui.find.match_case` 

Match search text case sensitively.
The default value is `false`.

<a id="ui.find.match_case_label_text"></a>
#### `ui.find.match_case_label_text` 

The text of the "Match case" label. (Write-only)
This is primarily used for localization.

<a id="ui.find.regex"></a>
#### `ui.find.regex` 

Interpret search text as a Regular Expression.
The default value is `false`.

<a id="ui.find.regex_label_text"></a>
#### `ui.find.regex_label_text` 

The text of the "Regex" label. (Write-only)
This is primarily used for localization.

<a id="ui.find.replace_all_button_text"></a>
#### `ui.find.replace_all_button_text` 

The text of the "Replace All" button. (Write-only)
This is primarily used for localization.

<a id="ui.find.replace_button_text"></a>
#### `ui.find.replace_button_text` 

The text of the "Replace" button. (Write-only)
This is primarily used for localization.

<a id="ui.find.replace_entry_text"></a>
#### `ui.find.replace_entry_text` 

The text in the "Replace" entry.
When searching for text in a directory of files, this is the current file and directory filter.

<a id="ui.find.replace_label_text"></a>
#### `ui.find.replace_label_text` 

The text of the "Replace" label. (Write-only)
This is primarily used for localization.

<a id="ui.find.show_filenames_in_progressbar"></a>
#### `ui.find.show_filenames_in_progressbar` 

Whether to show filenames in the find in files search progressbar.
This can be useful for determining whether or not custom filters are working as expected.
Showing filenames can slow down searches on computers with really fast SSDs.
The default value is `false`.

<a id="ui.find.whole_word"></a>
#### `ui.find.whole_word` 

Match search text only when it is surrounded by non-word characters in searches.
The default value is `false`.

<a id="ui.find.whole_word_label_text"></a>
#### `ui.find.whole_word_label_text` 

The text of the "Whole word" label. (Write-only)
This is primarily used for localization.


### Functions defined by `ui.find`

<a id="ui.find.find_in_files"></a>
#### `ui.find.find_in_files`([*dir*[, *filter*]])

Searches directory *dir* or the user-specified directory for files that match search text
and search options (subject to optional filter *filter*), and prints the results to a buffer
titled "Files Found", highlighting found text.
Use the [`ui.find.find_entry_text`](#ui.find.find_entry_text), [`ui.find.match_case`](#ui.find.match_case), [`ui.find.whole_word`](#ui.find.whole_word), and
[`ui.find.regex`](#ui.find.regex) fields to set the search text and option flags, respectively.
A filter determines which files to search in, with the default filter being
`ui.find.find_in_files_filters[dir]` (if it exists) or [`lfs.default_filter`](#lfs.default_filter). A filter consists
of glob patterns that match file and directory paths to include or exclude. Patterns are
inclusive by default. Exclusive patterns begin with a '!'. If no inclusive patterns are
given, any filename is initially considered. As a convenience, '/' also matches the Windows
directory separator ('[/\\]' is not needed). If *filter* is `nil`, the filter from the
[`ui.find.find_in_files_filters`](#ui.find.find_in_files_filters) table for *dir* is used. If that filter does not exist,
[`lfs.default_filter`](#lfs.default_filter) is used.

Parameters:

- *dir*:  Optional directory path to search. If `nil`, the user is prompted for one.
- *filter*:  Optional filter for files and directories to exclude. The
	default value is [`lfs.default_filter`](#lfs.default_filter) unless a filter for *dir* is defined in
	[`ui.find.find_in_files_filters`](#ui.find.find_in_files_filters).

<a id="ui.find.find_next"></a>
#### `ui.find.find_next`()

Mimics pressing the "Find Next" button.

<a id="ui.find.find_prev"></a>
#### `ui.find.find_prev`()

Mimics pressing the "Find Prev" button.

<a id="ui.find.focus"></a>
#### `ui.find.focus`([*options*])

Displays and focuses the Find & Replace Pane.

Parameters:

- *options*:  Optional table of [`ui.find`](#ui.find) field options to initially set.

<a id="ui.find.goto_file_found"></a>
#### `ui.find.goto_file_found`(*location*)

Jumps to the source of the next or previous find in files search result in the buffer titled
"Files Found", or the result on a given line number, depending on the value of *location*.

Parameters:

- *location*:  When `true`, jumps to the next search result. When `false`, jumps to the
	previous one. When a line number, jumps to it.

<a id="ui.find.replace"></a>
#### `ui.find.replace`()

Mimics pressing the "Replace" button.

<a id="ui.find.replace_all"></a>
#### `ui.find.replace_all`()

Mimics pressing the "Replace All" button.


---
<a id="view"></a>
## The `view` Module
---

See [`buffer`](#buffer).

---

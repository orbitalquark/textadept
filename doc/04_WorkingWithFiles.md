# Working with Files

## Buffers

One of the first things notably absent when opening multiple files in Textadept
is the lack of a tab bar showing the open files. This design decision allowed
Textadept to support unlimited split views from the very beginning. Having a
single tab bar for multiple views causes confusion and having one tab bar per
view clutters the interface.

Instead of having tabs, Textadept has the buffer browser. Press `Ctrl+B` (`⌘B`
on Mac OSX | `M-B` or `M-S-B` in curses) to open it.

![Buffer Browser](images/bufferbrowser.png)

The buffer browser displays a list of currently open buffers, the most recent
towards the bottom. Typing part of any filename filters the list. Spaces are
wildcards. The arrow keys move the selection up and down. Pressing `Enter`,
selecting `OK`, or double-clicking a buffer in the list switches to the selected
buffer.

![Buffer Browser Filtered](images/bufferbrowserfiltered.png)

Textadept shows the name of the active buffer in its titlebar. Pressing
`Ctrl+Tab` (`^⇥` on Mac OSX | `M-N` in curses) cycles to the next buffer and
`Ctrl+Shift+Tab` (`^⇧⇥` | `M-P`) cycles to the previous one.

### Settings

Individual files have three configurable settings: indentation, line endings,
and encoding. Indentation consists of an indentation character and an
indentation size. Line endings are characters that separate lines. File
encoding determines how text characters are displayed. Textadept shows these
settings in the buffer status statusbar.

![Document Statusbar](images/docstatusbar.png)

#### Indentation

Usually, [language modules][] or [user settings][] dictate the buffer's
indentation setting. By default, indentation is 2 spaces. Pressing
`Ctrl+Alt+Shift+T` (`^⇧T` on Mac OSX | `M-T` or `M-S-T` in curses) manually
toggles between using tabs and spaces, although this only affects future
indentation. Existing indentation remains unchanged. `Ctrl+Alt+I` (`^I` | `M-I`)
performs the conversion. (If the buffer uses tabs, all indenting spaces convert
to tabs. If the buffer uses spaces, all indenting tabs convert to spaces.)
Similarly, the "Buffer -> Indentation" menu manually sets indentation size.

[language modules]: 07_Modules.html#Buffer.Properties
[user settings]: 08_Preferences.html#Buffer.Properties

#### Line Endings

The current platform determines which line endings, commonly known as
end-of-line (EOL) markers, to use by default. On Windows it is CRLF ("\r\n"). On
all other platforms it is LF ('\n'). Textadept first tries to auto-detect the
EOL mode of opened files before falling back on the platform default. The
"Buffer -> EOL Mode" menu manually changes line endings and, unlike indentation
settings, automatically converts all existing EOLs.

#### Encodings

Textadept represents all characters and strings internally as UTF-8. UTF-8 is
compatible with ASCII so those files are always detected properly. Textadept
also recognizes ISO-8859-1 and MacRoman, two common encodings used on Windows
and Mac OSX respectively. If you work with files whose encodings Textadept does
not recognize, add the encodings to [`io.encodings`][] in your [preferences][].

UTF-8 is the recommended file encoding because of its wide support by other text
editors and operating systems. The "Buffer -> Encoding" menu changes the file
encoding and performs the conversion. Textadept saves new files as UTF-8 by
default, but does not alter the encoding of existing ones.

[`io.encodings`]: api/io.html#encodings
[preferences]: 08_Preferences.html

### Recent Files

Pressing `Ctrl+Alt+O` (`^⌘O` on Mac OSX | `M-^O` in curses) brings up a dialog
that behaves like the buffer browser, but displays a list of recently opened
files to reopen.

### Sessions

By default, Textadept saves its state when quitting in order to restore it the
next time the editor starts up. Passing the `-n` or `--nosession` switch to
Textadept on startup disables this feature. The "File -> Save Session..." and
"File -> Load Session..." menus manually save and open sessions while the `-s`
and `--session` switches load a session on startup. The switches accept the path
of a session file or the name of a session in *~/.textadept/*. Session files
store information such as open buffers, current split views, caret and scroll
positions in each buffer, Textadept's window size, and recently opened files.
Tampering with session files may have unintended consequences.

### Snapopen

A quicker, though slightly more limited alternative to the standard file
selection dialog is snapopen. It too behaves like the buffer browser, but
displays a list of files to open, including files in sub-directories. Pressing
`Ctrl+Alt+Shift+O` (`^⌘⇧O` on Mac OSX | `M-S-O` in curses) snaps open the
current file's directory and `Ctrl+U` (`⌘U` | `^U`) snaps open *~/.textadept/*.
Snapopen is pretty limited from the "Tools -> Snapopen" menu, but more versatile
in [scripts][].

[scripts]: api/io.html#snapopen

![Snapopen](images/snapopen.png)

## Views

### Split Views

Textadept allows you to split the editor window an unlimited number of times
both horizontally and vertically. `Ctrl+Alt+S` or `Ctrl+Alt+H` splits
horizontally into top and bottom views and `Ctrl+Alt+V` splits vertically (`^S`
and `^V` respectively on Mac OSX | N/A in curses) into side-by-side views.
Clicking and dragging on the splitter bar with the mouse or pressing
`Ctrl+Alt++` and `Ctrl+Alt+-` (`^+` and `^-` | N/A) resizes the split. Textadept
supports viewing a single buffer in two or more views.

Pressing `Ctrl+Alt+N` (`^⌥⇥` on Mac OSX | N/A in curses) jumps to the next view
and `Ctrl+Alt+P` (`^⌥⇧⇥` | N/A) jumps the previous one. However, depending on
the split sequence, the order when cycling between views may not be linear.

To unsplit a view, enter the view to keep open and press `Ctrl+Alt+W` (`^W` on
Mac OSX | N/A in curses). To unsplit all views, use `Ctrl+Alt+Shift+W` (`^⇧W` |
N/A).

Textadept curses does not support split views.

### Settings

Individual views have many configurable settings. Among the more useful settings
are viewing line endings, handling long lines, viewing indentation guides, and
viewing whitespace. These options change how to display buffers in the _current_
view. Changing a setting in one view does not change that setting in
any other split view. You must do it manually.

#### Line Endings

Normally, EOL characters ("\r" and "\n") are invisible. Pressing
`Ctrl+Alt+Enter` (`^↩` on Mac OSX | none in curses) toggles their visibility.

#### Long Lines

By default, lines with more characters than the view can show do not wrap into
view. `Ctrl+Alt+\` (`^\` on Mac OSX | none in curses) toggles line wrapping.

#### Indentation Guides

Views show small guiding lines based on indentation level by default.
`Ctrl+Alt+Shift+I` (`^⇧I` on Mac OSX | N/A in curses) toggles the visibility of
these guides.

Textadept curses does not support indentation guides.

#### Whitespace

Normally, whitespace characters, tabs and spaces, are invisible. Pressing
`Ctrl+Alt+Shift+S` (`^⇧S` on Mac OSX | none in curses) toggles their visibility.
Visible spaces show up as dots and visible tabs show up as arrows.

### Zoom

To temporarily increase or decrease the font size in a view, press `Ctrl+=`
(`⌘=` on Mac OSX | N/A in curses) and `Ctrl+-` (`⌘-` | N/A) respectively.
`Ctrl+0` (`⌘0` | N/A) resets the zoom.

Textadept curses does not support zooming.

# Textadept Manual

**Contents**

1. [Introduction](#Introduction)
2. [Installation](#Installation)
3. [User Interface](#User.Interface)
4. [Working with Files](#Working.with.Files)
5. [File Navigation](#File.Navigation)
6. [Adept Editing](#Adept.Editing)
7. [Modules](#Modules)
8. [Preferences](#Preferences)
9. [Themes](#Themes)
10. [Advanced](#Advanced)
11. [Scripting](#Scripting)
12. [Compiling](#Compiling)
13. [Help](#Help)
14. [Appendix](#Appendix)

- - -

# Introduction

- - -

## Overview

![Textadept](images/textadept.png)

Textadept is a fast, minimalist, and remarkably extensible cross-platform text
editor for programmers. Written in a combination of C and [Lua][] and
relentlessly optimized for speed and minimalism over the years, Textadept is an
ideal editor for programmers who want endless extensibility without sacrificing
speed or succumbing to code bloat and featuritis.

[Lua]: http://www.lua.org

### Fast

Textadept is _fast_. It starts up instantly and has a very responsive user
interface. Even though the editor consists primarily of Lua, Lua is one of the
fastest scripting languages available. With the optional [LuaJIT][] version,
Textadept runs faster than ever before.

[LuaJIT]: http://luajit.org

### Minimalist

Textadept is minimalist. Not only does its appearance exhibit this, but the
editor's C core pledges to never exceed 2000 lines of code and its Lua extension
code avoids going beyond 4000 lines. After more than 5 years of development,
Textadept contains the same amount of code since its inception while evolving
into a vastly superior editor.

### Remarkably Extensible

Textadept is remarkably extensible. Designed to be that way from the very
beginning, the editor's features came later. Most of Textadept's internals use
Lua, from syntax highlighting to opening and saving files to searching and
replacing and more. Textadept gives you complete control over the entire
application using Lua. Everything from moving the caret to changing menus and
key commands on-the-fly to handling core events is possible. Its potential is
vast.

![Split Views](images/splitviews.png)

## Manual Notation

The manual represents directories and file paths like this: */path/to/dir/* and
*/path/to/file*. (Windows machines use '/' and '\' interchangeably as directory
separators.) Paths that do not begin with '/' or "C:\", are relative to the
location of Textadept. *~/* denotes the user's home directory. On Windows
machines this is the value of the "USERHOME" environment variable, typically
*C:\Users\username\\* or *C:\Documents and Settings\username\\*. On Linux, BSD,
and Mac OSX machines it is the value of "$HOME", typically */home/username/* and
*/Users/username/*, respectively.

The manual expresses key bindings like this: `Ctrl+N`. They are not case
sensitive. `Ctrl+N` stands for pressing the "N" key while only holding down the
"Control" modifier key, not the "Shift" modifier key. `Ctrl+Shift+N` stands for
pressing the "N" key while holding down both the "Control" and "Shift"
modifiers. The same notation applies to key chains like `Ctrl+N, N` and
`Ctrl+N, Shift+N`. The first key chain represents pressing "Control" and "N"
followed by "N" with no modifiers. The second represents pressing "Control" and
"N" followed by "Shift" and "N".

When mentioning key bindings, the manual often shows the Mac OSX and curses
equivalents in parenthesis. It may be tempting to assume that some Windows/Linux
keys map to Mac OSX's (e.g. `Ctrl` to `⌘`) or curses' (e.g. `Ctrl` to `^`), but
this is not always the case. To minimize confusion, view key equivalents as
separate entities, not as translations of one another.

- - -

# Installation

- - -

## Requirements

In its bid for minimalism, Textadept also depends on very little to run. The GUI
version needs only [GTK+][], a cross-platform GUI toolkit, version 2.18 or later
on Linux and BSD systems. The application already bundles a GTK+ runtime into
the Windows and Mac OSX packages. The terminal, or curses, version of Textadept
only depends on a curses implementation like [ncurses][] on Linux, Mac OSX, and
BSD systems. The Windows binary includes a precompiled version of [pdcurses][].
Textadept also incorporates its own [copy of Lua](#Lua.Configuration) on all
platforms.

[GTK+]: http://gtk.org
[ncurses]: http://invisible-island.net/ncurses/ncurses.html
[pdcurses]: http://pdcurses.sourceforge.net

### Requirements for Linux and BSD

Most Linux and BSD systems already have GTK+ installed. If not, your package
manager probably makes it available. Otherwise, compile and install GTK+from the
[GTK+ website][].

The Linux binaries for the GUI versions of Textadept require GLib version 2.28
or later to support [single-instance](#Single.Instance) functionality. However,
Textadept compiles with versions of GLib as early as 2.22. For reference, Ubuntu
11.04, Debian Wheezy, Fedora 15, and openSUSE 11.4 support GLib 2.28 or later.

Most Linux and BSD systems already have a curses implementation like ncurses
installed. If not, look for one in your package manager, or compile and install
ncurses from the [ncurses website][]. Ensure it is the wide-character version of
ncurses, which handles multibyte characters. Debian-based distributions like
Ubuntu typically call the package "libncursesw5".

[GTK+ website]: http://www.gtk.org/download/linux.php
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Requirements for Mac OSX

No requirements other than Mac OSX 10.5 (Leopard) or higher with an Intel CPU.

### Requirements for Windows

No requirements.

## Download

Download Textadept from the project's [download page][] by selecting the
appropriate package for your platform. For the Windows and Mac OSX packages, the
bundled GTK+ runtime accounts for more than 3/4 of the download and unpackaged
application sizes. Textadept itself is much smaller.

You also have the option of downloading an official set of
[language modules](#Language.Modules) from the download page. Textadept itself
includes C/C++ and Lua language modules by default.

[download page]: http://foicica.com/textadept/download

## Installation

Installing Textadept is simple and easy. You do not need administrator
privileges.

### Installing on Linux and BSD

Unpack the archive anywhere.

If you downloaded the set of language modules, unpack it where you unpacked the
Textadept archive. The modules are located in the
*/path/to/textadept_x.x/modules/* directory.

### Installing on Mac OSX

Unpack the archive and move *Textadept.app* to your user or system
*Applications/* directory like any other Mac OSX application. The package
contains an optional *ta* script for launching Textadept from the command line
that you can put in a directory in your "$PATH" (e.g. */usr/local/bin/*).

If you downloaded the set of language modules, unpack it, right-click
*Textadept.app*, select "Show Package Contents", navigate to
*Contents/Resources/modules/*, and move the unpacked modules there.

### Installing on Windows

Unpack the archive anywhere.

If you downloaded the set of language modules, unpack it where you unpacked the
Textadept archive. The modules are located in the *textadept_x.x\modules\\*
directory.

## Running

### Running on Linux and BSD

Run Textadept by running */path/to/textadept_x.x/textadept* from the terminal
You can also create a symbolic link to the executable in a directory in your
"$PATH" (e.g. */usr/local/bin/*) or make a GNOME, KDE, XFCE, etc. button or menu
launcher.

The package also contains a *textadeptjit* executable for running Textadept with
[LuaJIT][]. Due to potential [compatibility issues](#LuaJIT), use the
*textadept* executable wherever possible.

The *textadept-curses* and *textadeptjit-curses* executables are the terminal
versions of Textadept. Run them as you would run the *textadept* and
*textadeptjit* executables, but from a terminal instead.

[LuaJIT]: http://luajit.org

#### Runtime Problems

Providing a single binary that runs on all Linux platforms proves challenging,
since the versions of software installed vary widely from distribution to
distribution. Because the Linux version of Textadept uses the version of GTK+
installed on your system, an error like:

    error while loading shared libraries: <lib>: cannot open shared object
    file: No such file or directory

may occur when trying to run the program. The solution is actually quite
painless even though it requires [recompiling](#Compiling) Textadept.

### Running on Mac OSX

Run Textadept by double-clicking *Textadept.app*. You can also pin it to your
dock.

*Textadept.app* also contains an executable for running Textadept with
[LuaJIT][]. Enable it by setting a "TEXTADEPTJIT"
[environment variable](#Mac.OSX.Environment.Variables) or by typing
`export TEXTADEPTJIT=1` in the terminal. Due to potential
[compatibility issues](#LuaJIT), use the non-LuaJIT executable wherever
possible.

[LuaJIT]: http://luajit.org

#### Mac OSX Environment Variables

By default, Mac OSX GUI apps like Textadept do not see shell environment
variables like "$PATH". Consequently, any [modules](#Modules) that utilize
programs contained in "$PATH" (e.g. the progams in */usr/local/bin/*) for run
and compile commands will not find those programs. The solution is to create a
*~/.textadept/osx_env.sh* file that exports all of the environment variables you
need Textadept to see. For example:

    export PATH=$PATH

### Running on Windows

Run Textadept by double-clicking *textadept.exe*. You can also create shortcuts
to the executable in your Start Menu, Quick Launch toolbar, Desktop, etc.

The package also contains a *textadeptjit.exe* executable for running Textadept
with [LuaJIT][]. Due to potential [compatibility issues](#LuaJIT), use the
*textadept.exe* executable wherever possible.

[LuaJIT]: http://luajit.org

### *~/.textadept*

Textadept stores all of your preferences and user-data in your *~/.textadept/*
directory. If this directory does not exist, Textadept creates it on startup.
The manual gives more information on this folder later.

## Single Instance

Textadept is a single-instance application on Linux, BSD, and Mac OSX. This
means that after starting Textadept, running `textadept file.ext` (`ta file.ext`
on Mac OSX) from the command line or opening a file with Textadept from a file
manager opens *file.ext* in the original Textadept instance. Passing a `-f` or
`--force` switch to Textadept overrides this behavior and opens the file in a
new instance: `textadept -f file.ext` (`ta -f file.ext`). Without the force
switch, the original Textadept instance opens files, regardless of the number of
instances open.

The Windows and terminal versions of Textadept do not support single instance.

<span style="display: block; text-align: right; margin-left: -10em;">
![Linux](images/linux.png)
&nbsp;&nbsp;
![Mac OSX](images/macosx.png)
&nbsp;&nbsp;
![Win32](images/win32.png)
&nbsp;&nbsp;
![curses](images/ncurses.png)
</span>

- - -

# User Interface

- - -

![UI](images/ui.png)

Textadept's user interface is sleek and simple. It consists of a menu (GUI
version only), editor view, and statusbar. There is also a find & replace pane
and a command entry, but Textadept initially hides them both. The manual briefly
describes these features below, but provides more details later.

## Menu

The completely customizable menu provides access to all of Textadept's features.
Only the GUI version implements it, though. The terminal version furnishes the
[command selection](#Command.Selection) dialog instead. Textadept is very
keyboard-driven and assigns key shortcuts to most menu items. Your
[key preferences](#Key.Bindings) can change these shortcuts and reflect in the
menu. Here is a [complete list][] of default key bindings.

[complete list]: api.html#textadept.keys

## Tab Bar

The tab bar displays all of Textadept's open buffers, although it's only visible
when two or more buffers are open. While only the GUI version supports tabs,
Textadept's [buffer browser](#Buffers) is always available and far more
powerful.

## Editor View

Most of your time spent with Textadept is in the editor view. Both the GUI
version and the terminal version feature unlimited vertical and horizontal view
splitting. Lua also has complete control over all views.

## Find & Replace Pane

This compact pane is a great way to slice and dice through your document or a
directory of files. It even supports finding and replacing text using Lua
patterns and Lua code. The pane is available only when you need it and quickly
gets out of your way when you do not, minimizing distractions.

## Command Entry

The versatile command entry functions as, among other things, a place to execute
Lua commands with Textadept's internal Lua state, find text incrementally, and
execute shell commands. Lua extensions allow it to do even more. Like the Find &
Replace pane, the command entry pops in and out as you wish.

## Statusbar

The statusbar actually consists of two statusbars. The one on the left-hand
side displays temporary status messages while the one on the right-hand side
persistently shows the current buffer status.

- - -

# Working with Files

- - -

## Buffers

Despite the fact that Textadept can display multiple buffers with a tab bar, the
buffer browser is usually a faster way to switch between buffers or quickly
assess which files are open. Press `Ctrl+B` (`⌘B` on Mac OSX | `M-B` or `M-S-B`
in curses) to display this browser.

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

### Typical Buffer Settings

Individual files have three configurable settings: indentation, line endings,
and encoding. Indentation consists of an indentation character and an
indentation size. Line endings are the characters that separate lines. File
encoding specifies how to display text characters. Textadept shows these
settings in the buffer status statusbar.

![Document Statusbar](images/docstatusbar.png)

#### Buffer Indentation

Normally, a [language module](#Language-Specific.Buffer.Settings) or the
[user settings](#Buffer.Settings) dictate a buffer's indentation settings. By
default, indentation is 2 spaces. Pressing `Ctrl+Alt+Shift+T` (`^⇧T` on Mac OSX
| `M-T` or `M-S-T` in curses) manually toggles between using tabs and spaces,
although this only affects future indentation. Existing indentation remains
unchanged. `Ctrl+Alt+I` (`^I` | `M-I`) performs the conversion. (If the buffer
uses tabs, all indenting spaces convert to tabs. If the buffer uses spaces, all
indenting tabs convert to spaces.) Similarly, the "Buffer -> Indentation" menu
manually sets indentation size.

#### Buffer Line Endings

Textadept determines which default line endings, commonly known as end-of-line
(EOL) markers, to use based on the current platform. On Windows it is CRLF
("\r\n"). On all other platforms it is LF ('\n'). Textadept first tries to
auto-detect the EOL mode of opened files before falling back on the platform
default. The "Buffer -> EOL Mode" menu manually changes line endings and, unlike
indentation settings, automatically converts all existing EOLs.

#### Buffer Encodings

Textadept has the ability to decode files encoded in many different encodings,
but by default it only attempts to decode UTF-8, ASCII, ISO-8859-1, and
MacRoman. If you work with files with encodings Textadept does not recognize,
add those encodings to [`io.encodings`][] in your [preferences](#Preferences).

UTF-8 is the recommended file encoding because of its wide support by other text
editors and operating systems. The "Buffer -> Encoding" menu changes the file
encoding and performs the conversion. Textadept saves new files as UTF-8 by
default, but does not alter the encoding of existing ones.

[`io.encodings`]: api.html#io.encodings

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
current file's directory, `Ctrl+U` (`⌘U` | `^U`) snaps open *~/.textadept/*, and
`Ctrl+Alt+Shift+P` (`^⌘⇧P` | `M-^P`) snaps open the current project (which must
be under version control). Snapopen is pretty limited from the
"Tools -> Snapopen" menu, but more versatile in [scripts][].

[scripts]: api.html#io.snapopen

![Snapopen](images/snapopen.png)

## Views

### Split Views

Textadept allows you to split the editor window an unlimited number of times
both horizontally and vertically. `Ctrl+Alt+S` or `Ctrl+Alt+H` splits
horizontally into top and bottom views and `Ctrl+Alt+V` splits vertically (`^S`
and `^V`, respectively on Mac OSX | `M-^V S` and `M-^V V` in curses) into
side-by-side views. Clicking and dragging on the splitter bar with the mouse or
pressing `Ctrl+Alt++` and `Ctrl+Alt+-` (`^+` and `^-` | `M-^V +` and `M-^V -`)
resizes the split. Textadept supports viewing a single buffer in two or more
views.

Pressing `Ctrl+Alt+N` (`^⌥⇥` on Mac OSX | `M-^V N` in curses) jumps to the next
view and `Ctrl+Alt+P` (`^⌥⇧⇥` | `M-^V P`) jumps the previous one. However,
depending on the split sequence, the order when cycling between views may not be
linear.

To unsplit a view, enter the view to keep open and press `Ctrl+Alt+W` (`^W` on
Mac OSX | `M-^V W` in curses). To unsplit all views, use `Ctrl+Alt+Shift+W`
(`^⇧W` | `M-^V S-W`).

Note: Textadept curses uses the `M-^V` key prefix for split views.

### View Settings

Individual views have many configurable settings. Among the more useful settings
are viewing line endings, handling long lines, viewing indentation guides, and
viewing whitespace. These options change how to display buffers in the _current_
view. Changing a setting in one view does not change that setting in
any other split view. You must do it manually.

#### View Line Endings

Normally, EOL characters ("\r" and "\n") are invisible. Pressing
`Ctrl+Alt+Enter` (`^↩` on Mac OSX | none in curses) toggles their visibility.

#### View Long Lines

By default, lines with more characters than the view can show do not wrap into
view. `Ctrl+Alt+\` (`^\` on Mac OSX | none in curses) toggles line wrapping.

#### View Indentation Guides

Views show small guiding lines based on indentation level by default.
`Ctrl+Alt+Shift+I` (`^⇧I` on Mac OSX | N/A in curses) toggles the visibility of
these guides.

Textadept curses does not support indentation guides.

#### View Whitespace

Normally, whitespace characters, tabs and spaces, are invisible. Pressing
`Ctrl+Alt+Shift+S` (`^⇧S` on Mac OSX | none in curses) toggles their visibility.
Visible spaces show up as dots and visible tabs show up as arrows.

### Zoom

To temporarily increase or decrease the font size in a view, press `Ctrl+=`
(`⌘=` on Mac OSX | N/A in curses) and `Ctrl+-` (`⌘-` | N/A) respectively.
`Ctrl+0` (`⌘0` | N/A) resets the zoom.

Textadept curses does not support zooming.

- - -

# File Navigation

- - -

## Basic Movements

Textadept implements the customary key bindings for navigating text fields on
the current platform. The arrow keys move the caret in a particular direction,
`Ctrl+Left` and `Ctrl+Right` (`^⇠` and `^⇢` on Mac OSX | `^Left` and `^Right` in
curses) move by words, `PgUp` and `PgDn` (`⇞` and `⇟` | `PgUp` and `PgDn`) move
by pages, etc. Mac OSX and curses also handle some Bash-style bindings like
`^B`, `^F`, `^P`, `^N`, `^A`, and `^E`. The "Movement" section of the
[key bindings list][] lists all movement bindings.

[key bindings list]: api.html#textadept.keys

## Brace Match

By default, Textadept highlights the matching brace characters under the caret:
'(', ')', '[', ']', '{', and '}'. Pressing `Ctrl+M` (`^M` on Mac OSX | `M-M` in
curses) moves the caret to the matching brace.

![Matching Braces](images/matchingbrace.png)

## Bookmarks

Textadept supports bookmarking buffer lines to jump back to them later.
`Ctrl+F2` (`⌘F2` on Mac OSX | `F1` in curses) toggles a bookmark on the current
line, `F2` jumps to the next bookmarked line, `Shift+F2` (`⇧F2` | `F3`) jumps to
the previously bookmarked line, `Alt+F2` (`⌥F2` | `F4`) jumps to the bookmark
selected from a list, and `Ctrl+Shift+F2` (`⌘⇧F2` | `F6`) clears all bookmarks
in the current buffer.

## Goto Line

To jump to a specific line in a file, press `Ctrl+J` (`⌘J` on Mac OSX | `^J` in
curses), specify the line number in the prompt, and press `Enter` (`↩` |
`Enter`) or click `Ok`.

- - -

# Adept Editing

- - -

## Basic Editing

Textadept features many common, basic editing features: inserting text,
undo/redo, manipulating the clipboard, deleting characters and words,
duplicating lines, joining lines, and transposing characters. The top-level
"Edit" menu contains these actions and lists their associated key bindings. The
manual discusses more elaborate editing features below.

### Autopaired Characters

Usually, brace ('(', '[', '{') and quote ('&apos;', '&quot;') characters go
together in pairs. Textadept automatically inserts the complement character of
any user-typed opening brace or quote character and allows the user to
subsequently type over it. Similarly, the editor deletes the complement when
you press `Bksp` (`⌫` on Mac OSX | `Bksp` in curses) over the typed one. The
[module preferences](#Generic.Module.Preferences) section details how to
configure or disable these features.

### Word Completion

Textadept provides buffer-based word completion. Start typing a word and press
`Ctrl+Enter` (`^⎋` on Mac OSX | `M-Enter` in curses) to display a list of
suggested completions based on words in the current buffer. Continuing to type
changes the suggestion. Press `Enter` (`↩` | `Enter`) to complete the selected
word.

![Word Completion](images/wordcompletion.png)

### Virtual Space Mode

Pressing `Ctrl+Alt+Shift+V` (`^⇧V` in Mac OSX | none in curses) enables and
disables Virtual space (freehand) mode. When virtual space is enabled, the caret
may move into the space past the ends of lines.

### Overwrite Mode

Enable and disable overwrite mode with the `Insert` key. When enabled, typing
overwrites existing characters in the buffer rather than inserting the typed
characters. The caret also changes to an underline in overwrite mode.

## Selections

Textadept includes many ways of creating and working with selections. Creating
basic selections entails holding down the "Shift" modifier key and then pressing
the arrow keys, clicking and dragging the mouse cursor over a range of text, or
pressing `Ctrl+A` (`⌘A` | `M-A`) to select all text. Creating more advanced
selections like multiple and rectangular selections requires slightly more
effort, but has powerful uses.

### Multiple Selection

Holding down the "Control" modifier key and then clicking and dragging the mouse
cursor over ranges of text creates multiple selections. Holding "Control" and
then clicking without dragging places an additional caret at the clicked
position. Textadept mirrors any typed text at each selection.

### Rectangular Selection

Rectangular selections are a more structured form of multiple selections. A
rectangular selection spanning multiple lines allows typing on each line.
Holding `Alt+Shift` (`⌥⇧` on Mac OSX | `M-S-` in curses) and then pressing the
arrow keys creates a rectangular selection. Holding the `Alt` modifier key and
then clicking and dragging the mouse cursor also creates a rectangular
selection.

![Rectangular Selection](images/rectangularselection.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Rectangular Edit](images/rectangularselection2.png)

Note: In some Linux environments, the window manager consumes `Alt+Shift+Arrow`
combinations, so Textadept's keys may need reconfiguring. Similarly, the window
manager may also consume `Alt+Mouse` in order to move windows. In that case, a
normal text selection may be changed into a rectangular selection by tapping the
`Alt` modifier key.

### Select to Matching Brace

Putting the caret over a brace character ('(', ')', '[', ']', '{', or '}') and
pressing `Ctrl+Shift+M` (`^⇧M` on Mac OSX| `M-S-M` in curses) extends the
selection to the brace character's matching brace.

### Entity Selection

Textadept allows the selection of many different entities from the caret. For
example, `Ctrl+"` (`^"` on Mac OSX | `M-"` in curses) selects all characters in
a double-quoted range. Typing it again selects the double-quotes too. The
"Edit -> Select In..." menu lists all selectable entities with their key
bindings.

### Marks

In curses, since some terminals do not recognize certain key combinations like
`Shift+Arrow` for making selections, marks can create selections. Create a mark
at the current caret position with `^^`. Then use regular movement keys like the
arrows, page up/down, and home/end to extend the selection in one direction.
Pressing `^]` swaps the current caret position with the original mark position
in order to extend the selection in the opposite direction. Typing text,
deleting text, or running a command that does either, removes the mark and
restores ordinary navigation. Pressing `^^` again also stops selecting text.

Only Textadept curses supports marks.

### Transforms

#### Enclose Entities

As a complement to selecting entities, Textadept allows the enclosure of text in
entities. The "Edit -> Selection -> Enclose In..." menu lists all enclosing
entities with their key bindings. Each action encloses either the currently
selected text or the word to the left of the caret. For example, pressing
`Alt+<` (`^<` on Mac OSX | `M->` in curses) at the end of a word encloses it in
XML tags.

#### Change Case

Pressing `Ctrl+Alt+U` or `Ctrl+Alt+Shift+U` (`^U` or `^⇧U` on Mac OSX | `M-^U`
or `M-^L` in curses) converts selected text to upper case letters or lower case
letters, respectively.

#### Change Indent Level

Increase the amount of indentation for a selected set of lines by pressing `Tab`
(`⇥` on Mac OSX | `Tab` in curses). `Shift+Tab` (`⇧⇥` | `S-Tab`) decreases it.
You do not have to select whole lines. Selecting any part of a line renders the
entire line eligible for indenting/dedenting. Using these key sequences when no
selection is present does not have the same effect.

#### Move Lines

Move selected lines up and down with the `Ctrl+Shift+Up` and `Ctrl+Shift+Down`
(`^⇧⇡` and `^⇧⇣` on Mac OSX | `S-^Up` and `S-^Down` in curses) keys,
respectively. Like with changing indent level, selecting any part of a line
renders the entire line eligible for moving.

## Find & Replace

`Ctrl+F` (`⌘F` on Mac OSX | `M-F` or `M-S-F` in curses) brings up the Find &
Replace pane. In addition to offering the usual find and replace with "Match
Case" and "Whole Word" options and find/replace history, Textadept supports
finding with [Lua patterns](#Lua.Patterns) and replacing with Lua captures and
even Lua code! For example: replacing all `%w+` with `%(string.upper('%0'))`
upper cases all words in the buffer. Replacement text only recognizes Lua
captures (`%`_`n`_) from a Lua pattern search, but always allows embedded Lua
code enclosed in `%()`.

Note the `Ctrl+G`, `Ctrl+Shift+G`, `Ctrl+Alt+R`, `Ctrl+Alt+Shift+R` key bindings
for find next, find previous, replace, and replace all (`⌘G`, `⌘⇧G`, `^R`, and
`^⇧R`, respectively on Mac OSX | `M-G`, `M-S-G`, `M-R`, `M-S-R` in curses) only
work after hiding the Find & Replace pane. For at least the English locale in
the GUI version, use the button mnemonics: `Alt+N`, `Alt+P`, `Alt+R`, and
`Alt+A` (`⌘N`, `⌘P`, `⌘R`, `⌘A` | N/A) after bringing up the pane.

In the curses version, `Tab` and `S-Tab` toggles between the find next, find
previous, replace, and replace all buttons; `Up` and `Down` arrows switch
between the find and replace text fields; `^P` and `^N` cycles through history;
and `F1-F4` toggles find options.

Pressing `Esc` (`⎋` | `Esc`) hides the pane after you finish with it.

### Replace in Selection

By default, "Replace All" replaces all text in the buffer. Selecting a
continuous block of text and then "Replace All" replaces all text in the
selection.

### Find in Files

`Ctrl+Shift+F` brings up Find in Files (`⌘⇧F` on Mac OSX | none in curses) and
prompts for a directory to search. A new buffer lists the search results.
Double-clicking a search result jumps to it in the file, as do the the
`Ctrl+Alt+G` and `Ctrl+Alt+Shift+G` (`^⌘G` and `^⌘⇧G` | none) key bindings.
Textadept does not support replacing in files directly. You must "Find in Files"
first, and then "Replace All" for each file containing a result. The "Match
Case", "Whole Word", and "Lua pattern" flags still apply.

_Warning_: currently, the [find API][] provides the only means to specify a
file-type filter. While the default filter excludes many common binary files
and version control folders from searches, Find in Files could still scan
unrecognized binary files or large, unwanted sub-directories. Searches also
block Textadept from receiving additional input, making the interface
temporarily unresponsive. Searching large directories or projects can be very
time consuming and frustrating, so you may prefer to use a specialized, external
tool such as [ack][].

![Find in Files](images/findinfiles.png)

[find API]: api.html#ui.find.FILTER
[ack]: http://betterthangrep.com/

### Incremental Find

Start an incremental search by pressing `Ctrl+Alt+F` (`^⌘F` on Mac OSX | `M-^F`
in curses). Incremental search searches the buffer as you type, but only
recognizes the "Match Case" find option. Pressing `Esc` (`⎋` | `Esc`) stops the
search.

## Source Code Editing

Being a programmer's editor, Textadept excels at editing source code. It
understands the syntax and structure of more than 90 different programming
languages and recognizes hundreds of file types. Textadept uses this knowledge
to make viewing and editing code faster and easier. It can also compile and run
simple source files.

### Lexers

Upon opening a file, Textadept attempts to identify the programming language
associated with it and set a "lexer" to highlight syntactic elements of the
code. Pressing `Ctrl+Shift+L` (`⌘⇧L` on Mac OSX | `M-S-L` in curses) and
selecting a lexer from the list manually sets the lexer instead. Your
[file type preferences](#File.Types) customize how Textadept recognizes files.

Occasionally while you edit, lexers may lose track of their context and
highlight syntax incorrectly. Pressing `F5` triggers a full redraw.

### Code Folding

Some lexers support "code folding", the act of temporarily hiding blocks of code
in order to make viewing easier. Markers in the margin to the left of the code
denote fold points. Clicking on one toggles the folding for that block of code.
Pressing `Ctrl+*` (`⌘*` on Mac OSX | `M-*` in curses) also toggles the fold
point on the current line.

![Folding](images/folding.png)

### Word Highlight

To highlight all occurrences of a given word, such as a variable name, put the
caret over the word and press `Ctrl+Alt+Shift+H` (`⌘⇧H` on Mac OSX | N/A in
curses). This feature also works for plain text.

![Word Highlight](images/wordhighlight.png)

### Autocompletion and Documentation

Textadept has the capability to autocomplete symbols for programming languages
and display API documentation. Pressing `Ctrl+Space` (`⌥⎋` on Mac OSX | `^Space`
in curses) completes the current symbol and `Ctrl+H` (`^H` | `M-H` or `M-S-H`)
shows any known documentation on the current symbol. Note: In order for these
features to work, the language you are working with must have an
[autocompleter][] and [API file(s)][], respectively.
[Language modules](#Language.Modules) usually [define these][]. Most of the
[official][] Textadept language modules support autocompletion and
documentation.

![Autocomplete Lua](images/adeptsense_lua.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Autocomplete Lua String](images/adeptsense_string.png)

![Documentation](images/adeptsense_doc.png)

[autocompleter]: api.html#textadept.editing.autocompleters
[API file(s)]: api.html#textadept.editing.api_files
[define these]: api.html#_M.Autocompletion.and.Documentation
[official]: http://foicica.com/hg

### Snippets

Snippets are essentially pieces of text inserted into source code or plain text.
However, snippets are not bound to static text. They can be dynamic templates
which contain placeholders for further user input, can mirror or transform those
user inputs, and/or can execute arbitrary code. Snippets are useful for rapidly
constructing blocks of code such as control structures, method calls, and
function declarations. Press `Ctrl+K` (`⌥⇥` on Mac OSX | `M-K` in curses) for a
list of available snippets. A snippet consists of a trigger word and snippet
text. Instead of manually selecting a snippet to insert, type its trigger word
followed by the `Tab` (`⇥` | `Tab`) key. Subsequent presses of `Tab` (`⇥` |
`Tab`) cause the caret to enter placeholders in sequential order, `Shift+Tab`
(`⇧⇥` | `S-Tab`) goes back to the previous placeholder, and `Ctrl+Shift+K`
(`⌥⇧⇥` | `M-S-K`) cancels the current snippet. Textadept supports nested
snippets, snippets inserted from within another snippet. Language modules
usually define their [own set][] of snippets, but your
[snippet preferences](#Snippet.Preferences) can define some too.

![Snippet](images/snippet.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Snippet Expanded](images/snippet2.png)

[own set]: api.html#_M.Snippets

### Toggle Comments

Pressing `Ctrl+/` (`⌘/` on Mac OSX | `M-/` in curses) comments or uncomments the
code on the selected lines. Selecting any part of a line renders the entire line
eligible for commenting or uncommenting.

### Compile, Run, and Build

Textadept knows most of the commands that compile and/or run code in source
files. It can also sometimes detect your project's build file and run that.
Pressing `Ctrl+Shift+R` (`⌘⇧R` on Mac OSX | `M-^R` in curses) executes the
command for compiling code in the current file, `Ctrl+R` (`⌘R` | `^R`) executes
the command for running code, and `Ctrl+Shift+B` (`⌘⇧B` on Mac OSX | `M-^B` in
curses) executes the command for building a project. `Ctrl+Shift+X` (`⌘⇧X` |
`M-^X`) stops the currently running process. A new buffer shows the output from
the command and marks any recognized warnings and errors. Pressing `Ctrl+Alt+E`
(`^⌘E` | `M-X`) attempts to jump to the source of the next recognized warning or
error and `Ctrl+Alt+Shift+E` (`^⌘⇧E` | `M-S-X`) attempts to jump to the previous
one. Double-clicking on warnings and errors also jumps to their sources. If
Textadept does not know the correct commands for compiling and/or running your
language's source code, if it does not know how to build your project, or if it
does not detect warning or error messages properly, you can [make changes][] in
your [user-init file](#User.Init).

![Runtime Error](images/runerror.png)

[make changes]: api.html#_M.Compile.and.Run

- - -

# Modules

- - -

Most of Textadept's functionality comes from Lua modules loaded on startup. An
example is the [textadept module][] which implements most of Textadept's
functionality (find & replace, key bindings, menus, snippets, etc.) See the
[loading modules](#Loading.Modules) section for instructions on how to load your
own modules on startup.

Textadept also recognizes a special kind of module: a language module. Language
modules provide functionality specific to their respective programming
languages.

[textadept module]: api.html#textadept

## Language Modules

Language modules have a scope limited to a single programming language. The
module's name matches the language's lexer in the *lexers/* directory. Textadept
automatically loads the module when editing source code in that particular
language. In addition to the source code editing features discussed previously,
these kinds of modules typically also define indentation settings, custom key
bindings, and perhaps a custom context menu. The manual discusses these features
below.

### Language-Specific Buffer Settings

Some programming languages have style guidelines for indentation and/or line
endings which differ from Textadept's defaults. In this case, language modules
[set][] these preferences. You can do so manually with your
[preferences](#Language.Module.Preferences).

[set]: api.html#_M.Buffer.Properties

### Language-Specific Key Bindings

Most language modules assign a set of key bindings to [custom commands][]. The
module's [API documentation][] or code lists which key bindings map to which
commands. The `Ctrl+L` (`⌘L` on Mac OSX | `M-L` in curses) key chain prefix
typically houses them.

[custom commands]: api.html#_M.Commands
[API documentation]: api.html

### Language-Specific Context Menu

Some language modules add extra actions to the context menu. Right-click inside
the view to bring up this menu.

## Getting Modules

Textadept has a set of officially supported language modules available as a
separate download from the Textadept downloads page with their sources hosted
[here][]. To upgrade to the most recent version of a module, either use
[Mercurial][] (run `hg pull` and then `hg update` on or from within the module)
or download a zipped version from the module's repository homepage and overwrite
the existing one.

For now, the [wiki][] hosts third-party, user-created modules.

[here]: http://foicica.com/hg
[Mercurial]: http://mercurial.selenic.com
[wiki]: http://foicica.com/wiki/textadept

## Installing Modules

If you do not have write permissions in Textadept's installed location, place
the module in your *~/.textadept/modules/* folder and replace all instances of
`_HOME` with `_USERHOME` in the module's *init.lua*. Putting all custom or
user-created modules in your *~/.textadept/modules/* directory prevents the
possibility of overwriting them when you update Textadept. Also, modules in that
directory override any modules in Textadept's *modules/* directory. This means
that if you have your own *lua* module, Textadept loads that one instead of its
own.

## Developing Modules

See the [module API documentation][].

[module API documentation]: api.html#_M

- - -

# Preferences

- - -

At this point the manual assumes you are at least familiar with the basics of
[Lua][]. You do not have to know a lot of the language to configure Textadept.

[Lua]: http://www.lua.org

## User Init

Textadept executes a *~/.textadept/init.lua*, your user-init file, on startup.
If this file does not exist, Textadept creates it for you. This file allows you
to indicate what you want Textadept to do when the application starts. Examples
include changing the settings of existing modules, loading new modules, and
running arbitrary Lua code.

### Module Preferences

Try to refrain from modifying the default modules that come with Textadept, even
if you just want to change an option in a generic module, modify the buffer
settings for a language module, edit file types, or add a small bit of custom
code. Upgrading Textadept to a new version may overwrite those changes. Instead
you have two options: load your own module instead of the default one, or run
your custom module code after the default module loads. For the most part, use
the second option because it is simpler and more compatible with future
releases. The manual discusses both options below in the context of generic and
language modules.

#### Generic Module Preferences

Many of Textadept's generic modules have configurable settings changeable from
*~/.textadept/init.lua* after Textadept loads the module. The module's
[API documentation][] lists these settings. For example, to disable character
autopairing with typeover and strip trailing whitespace on save, add the
following to your *~/.textadept/init.lua*:

    textadept.editing.AUTOPAIR = false
    textadept.editing.TYPEOVER_CHARS = false
    textadept.editing.STRIP_TRAILING_SPACES = true

To always hide the tab bar:

    ui.tabs = false

Now suppose you want to load all of Textadept's default modules except for the
menu. You cannot do this after-the-fact from *~/.textadept/init.lua*. Instead
you need Textadept to load your own module rather than the default one. Copy the
`textadept` module's *init.lua* (located in the *modules/textadept/* directory)
to *~/.textadept/modules/textadept/* and change

    M.menu = require 'textadept.menu'

to

    --M.menu = require 'textadept.menu'

Now when Textadept looks for *modules/textadept/init.lua*, it loads yours in
place of its own, thus loading everything but the menu. If instead you want to
completely change the menu structure, first create a new *menu.lua* and then put
it in *~/.textadept/modules/textadept/*. Textadept now loads your *menu.lua*
rather than its own.

[API documentation]: api.html

#### Language Module Preferences

Similar to generic modules, putting your own language module in
*~/.textadept/modules/* causes Textadept to load that module for editing the
language's code instead of the default one in *modules/* (if the latter exists).
For example, copying the default Lua language module from *modules/lua/* to
*~/.textadept/modules/* results in Textadept loading that module for editing Lua
code in place of its own. However, if you make custom changes to that module and
upgrade Textadept later, the module may no longer be compatible. Rather than
potentially wasting time merging changes, run custom code independent of a
module in the module's *post_init.lua* file. In this case, instead of copying
the `lua` module and creating an `events.LEXER_LOADED` event handler to use
tabs, simply put the event handler in *~/.textadept/modules/lua/post_init.lua*:

    events.connect(events.LEXER_LOADED, function(lang)
      if lang == 'lua' then buffer.use_tabs = true end
    end)

Similarly, use *post_init.lua* to change the module's [compile and run][]
commands, load more Autocompletion tags, and add additional
[key bindings](#Key.Bindings) and [snippets](#Snippet.Preferences) (instead of
in *~/.textadept/init.lua*). For example:

    textadept.run.run_commands.lua = 'lua5.2'
    _M.lua.tags[#_M.lua.tags + 1] = '/path/to/my/projects/tags'
    keys.lua['c\n'] = function()
      buffer:line_end() buffer:add_text('end') buffer:new_line()
    end
    snippets.lua['ver'] = '%<_VERSION>'

[compile and run]: api.html#_M.Compile.and.Run

### Loading Modules

After creating or downloading a generic module called `foo` that you want to
load along with the default modules, simply add the following to your
*~/.textadept/init.lua*:

    foo = require('foo')

Textadept automatically loads language modules when opening a source file of
that language, so simply installing the language module is sufficient.

### Key Bindings

For simple changes to key bindings, *~/.textadept/init.lua* is a good place to
put them. For example, maybe you want `Ctrl+Shift+C` to create a new buffer
instead of `Ctrl+N`:

    keys.cC = buffer.new
    keys.cn = nil

If you plan on redefining most key bindings, copy or create a new *keys.lua* and
put it in *~/.textadept/modules/textadept/* to get Textadept to load your set
instead of its own. Learn more about key bindings and how to define them in the
[key bindings documentation][].

[key bindings documentation]: api.html#keys

### Snippet Preferences

Define your own global snippets in *~/.textadept/init.lua*, such as:

    snippets['file'] = '%<buffer.filename>'
    snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` (`⇥` on Mac OSX | `Tab` in
curses) inserts the snippet, regardless of the current programming language.
Learn more about snippet syntax in the [snippets documentation][].

[snippets documentation]: api.html#textadept.snippets

### File Types

Textadept recognizes a wide range of programming language files either by file
extension or by a [Lua pattern](#Lua.Patterns) that matches the text of the
first line. The editor does this by consulting a set of tables in
[`textadept.file_types`][] that are modifiable from *~/.textadept/init.lua*. For
example:

    -- Recognize .luadoc files as Lua code.
    textadept.file_types.extensions.luadoc = 'lua'
    -- Change .html files to be recognized as XML files.
    textadept.file_types.extensions.html = 'xml'
    -- Recognize a shebang line like "#!/usr/bin/zsh" as shell code.
    textadept.file_types.patterns['^#!.+/zsh'] = 'bash'

[`textadept.file_types`]: api.html#textadept.file_types

## Buffer Settings

Since Textadept runs *~/.textadept/init.lua* only once on startup, it is not the
appropriate place to set per-buffer properties (like indentation size) or
view-related properties (like the behaviors for scrolling and autocompletion).
If you do set such properties in *~/.textadept/init.lua*, those settings only
apply to the first buffer and view -- subsequent buffers and split views will
not inherit those settings. Instead, put your settings in a
*~/.textadept/properties.lua* file which runs after creating a new buffer or
split view. Any settings there override Textadept's default *properties.lua*
settings. For example, to use tabs rather than spaces and have a tab size of 4
spaces by default, your *~/.textadept/properties.lua* would contain:

    buffer.use_tabs = true
    buffer.tab_width = 4

(Remember that in order to have per-filetype properties, you need to have a
[language module](#Language-Specific.Buffer.Settings).)

Textadept's *properties.lua* is a good "quick reference" for configurable
properties. It also has many commented out properties that you can copy to your
*~/.textadept/properties.lua* and uncomment to turn on or change the value of.
You can view a property's documentation by pressing `Ctrl+H` (`^H` on Mac OSX |
`M-H` or `M-S-H` in curses) or by reading the [buffer API documentation][].

[buffer API documentation]: api.html#buffer

## Locale Preference

Textadept attempts to auto-detect your locale settings using the "$LANG"
environment variable, falling back on the English locale. To set the locale
manually, copy the desired locale file from the *core/locales/* folder to
*~/.textadept/locale.conf*. If Textadept does not support your language yet,
please translate the English messages in *core/locale.conf* to your language and
send the modified *locale.conf* file to [me][]. I will include it in a future
release.

[me]: README.html#Contact

- - -

# Themes

- - -

Themes customize Textadept's look and feel. The editor's built-in themes are
"light", "dark", and "term". The GUI version uses "light" as its default and the
terminal version uses "term".

<span style="display: block; clear: right;"></span>

![Light Theme](images/lighttheme.png)
&nbsp;&nbsp;
![Dark Theme](images/darktheme.png)
&nbsp;&nbsp;
![Term Theme](images/termtheme.png)

Each theme is a single Lua file. It contains color and style definitions for
displaying syntactic elements like comments, strings, and keywords in
programming language source files. These [definitions][] apply universally to
all programming language elements, resulting in a single, unified theme. Themes
also set view-related editor properties like caret and selection colors.

Note: The only colors that the terminal version of Textadept recognizes are the
standard black, red, green, yellow, blue, magenta, cyan, white, and bold
variants of those colors. Your terminal emulator's settings determine how to
display these standard colors.

[definitions]: api.html#lexer.Styles.and.Styling

## Setting Themes

Override the default theme in your [*~/.textadept/init.lua*](#User.Init) using
the [`ui.set_theme()`][] function. For example:

    ui.set_theme(not CURSES and 'dark' or 'custom_term')

Either restart Textadept for changes to take effect or type [`reset()`][] in the
[command entry](#Lua.Command.Entry).

[`ui.set_theme()`]: api.html#ui.set_theme
[`reset()`]: api.html#reset

## Customizing Themes

Like with modules, try to refrain from editing Textadept's default themes.
Instead, put custom or downloaded themes in your *~/.textadept/themes/*
directory. Doing this not only prevents you from overwriting your themes when
you update Textadept, but causes the editor to load your themes instead of the
default ones in *themes/*. For example, having your own *light.lua* theme
results in Textadept loading that theme in place of its own.

There are two ways to go about customizing themes. You can create a new one from
scratch or tweak an existing one. Creating a new one is straightforward -- all
you need to do is define a set of colors and a set of styles. Just follow the
example of existing themes. If instead you want to use an existing theme like
"light" but only change the font face and font size, you have two options: call
[`ui.set_theme()`][] from your *~/.textadept/init.lua* with additional
parameters, or create an abbreviated *~/.textadept/themes/light.lua* using Lua's
`dofile()` function. For example:

    -- File *~/.textadept/init.lua*
    ui.set_theme('light', {font = 'Monospace', fontsize = 12})

    -- File *~/.textadept/themes/light.lua*
    dofile(_HOME..'/themes/light.lua')
    buffer.property['font'] = 'Monospace'
    buffer.property['fontsize'] = 12

Either one loads Textadept's "light" theme, but applies your font preferences.
The same techniques work for tweaking individual theme colors and/or styles, but
managing more changes is probably easier with the latter.

[`ui.set_theme()`]: api.html#ui.set_theme

### Language-specific Themes

Textadept also allows you to customize themes per-language through the
`events.LEXER_LOADED` event. For example, changing the color of functions in
Java from orange to black in the "light" theme looks like this:

    events.connect(events.LEXER_LOADED, function(lang)
      if lang == 'java' then
        buffer.property['style.function'] = 'fore:%(color.light_black)'
      end
    end)

## GUI Theme

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK+ Resource files][]. The "GtkWindow" name is
"textadept". For example, style all text fields with a "textadept-entry-style"
like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK+ Resource files]: http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html

## Getting Themes

For now, the [wiki][] hosts third-party, user-created themes. The classic
"dark", "light", and "scite" themes prior to version 4.3 are there too.

[wiki]: http://foicica.com/wiki/textadept

- - -

# Advanced

- - -

## Lua Command Entry

The command entry grants access to Textadept's Lua state. Press `Ctrl+E` (`⌘E`
on Mac OSX | `M-C` in curses) to display the entry. It is useful for debugging,
inspecting, and entering `buffer` or `view` commands. If you try to cause
instability in Textadept's Lua state, you will probably succeed so be careful.
The [Lua API][] lists available commands. The command entry provides abbreviated
commands for [`buffer`][], [`view`][] and [`ui`][]: you may reduce the
`buffer:append_text('foo')` command to `append_text('foo')`. Therefore, use
`_G.print()` for Lua's `print()` since `print()` expands to [`ui.print()`][].
These commands are runnable on startup using the `-e` and `--execute` command
line switches.

![Command Entry](images/commandentry.png)

[Lua API]: api.html
[`buffer`]: api.html#buffer
[`view`]: api.html#view
[`ui`]: api.html#ui
[`ui.print()`]: api.html#ui.print

### Command Entry Tab Completion

The command entry also provides tab-completion for functions, variables, tables,
etc. Press the `Tab` (`⇥` on Mac OSX | `Tab` in curses) key to display a list of
available completions. Use the arrow keys to make a selection and press `Enter`
(`↩` | `Enter`) to insert it.

![Command Completion](images/commandentrycompletion.png)

### Extending the Command Entry

Executing Lua commands is just one of the many tools the command entry functions
as. For example, *modules/textadept/find.lua* and *modules/textadept/keys.lua*
extend it to implement [incremental search][].

[incremental search]: api.html#ui.find.find_incremental

## Command Selection

If you did not disable the menu in your [preferences](#User.Init), then pressing
`Ctrl+Shift+E` (`⌘⇧E` on Mac OSX | `M-S-C` in curses) brings up the command
selection dialog. Typing part of any command filters the list, with spaces being
wildcards. This is an easy way to run commands without navigating the menus,
using the mouse, or remembering key bindings. It is also useful for looking up
particular key bindings quickly. Note: the key bindings in the dialog do not
look like those in the menu. Textadept uses this different notation internally.
Learn more about it in the [keys API documentation][].

[keys API documentation]: api.html#keys

## Shell Commands and Filtering Text

Sometimes using an existing shell command to manipulate text is easier than
using the command entry. An example would be sorting all text in a buffer (or a
selection). One way to do this from the command entry is:

    ls={}; for l in buffer:get_text():gmatch('[^\n]+') do ls[#ls+1]=l end;
    table.sort(ls); buffer:set_text(table.concat(ls, '\n'))

A simpler way is pressing `Ctrl+|` (`⌘|` on Mac OSX | `^\` in curses), entering
the shell command `sort`, and pressing `Enter` (`↩` | `Enter`).

This feature determines the standard input (stdin) for shell commands as
follows:

* If text is selected and spans multiple lines, all text on the lines containing
  the selection is used. However, if the end of the selection is at the
  beginning of a line, only the EOL (end of line) characters from the previous
  line are included as input. The rest of the line is excluded.
* If text is selected and spans a single line, only the selected text is used.
* If no text is selected, the entire buffer is used.

The standard output (stdout) of the command replaces the input text.

## Remote Control

Since Textadept executes arbitrary Lua code passed via the `-e` and `--execute`
command line switches, a side-effect of [single instance](#Single.Instance)
functionality on the platforms that support it is that you can remotely control
the original instance. For example:

    ta ~/.textadept/init.lua &
    ta -e "events.emit(events.FIND, 'require')"

- - -

# Scripting

- - -

Since Textadept is entirely scriptable with Lua, the editor has superb support
for editing Lua code. Textadept provides syntax autocompletion and documentation
for the Lua and Textadept APIs. The [`lua` module][] also has more tools for
working with Lua code.

![ta Autocompletion](images/adeptsense_ta.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![ta Documentation](images/adeptsense_tadoc.png)

[`lua` module]: api.html#_M.lua

## LuaDoc and Examples

Textadept's API is heavily documented. The [API documentation][] is the ultimate
resource on scripting Textadept. There are of course abundant scripting examples
since the editor's internals consist primarily of Lua.

[API documentation]: api.html

### Generating LuaDoc

Generate Textadept-like API documentation for your own modules using the
*doc/markdowndoc.lua* [LuaDoc][] module (you must have [Discount][] installed):

    luadoc -d . [-t template_dir] --doclet _HOME/doc/markdowndoc [module(s)]

where `_HOME` is the path where you installed Textadept and `template_dir` is an
optional template directory that contains two Markdown files: *.header.md* and
*.footer.md*. (See *doc/.header.md* and *doc/.footer.md* for examples.) LuaDoc
creates an *api/* directory in the current directory that contains the generated
API documentation HTML files.

[LuaDoc]: http://keplerproject.github.com/luadoc/
[Discount]: http://www.pell.portland.or.us/~orc/Code/discount/

## Lua Configuration

Textadept contains its own copy of [Lua 5.2][] which has the same configuration
(*luaconf.h*) as vanilla Lua with the following exceptions:

* `TA_LUA_PATH` and `TA_LUA_CPATH` replace the `LUA_PATH` and `LUA_CPATH`
  environment variables.
* `LUA_ROOT` is "/usr/" in Linux systems instead of "/usr/local/".
* `LUA_PATH` and `LUA_CPATH` do not have "./?.lua" and "./?.so" in them.
* No Lua 5.1 compatibility flags are set.

[Lua 5.2]: http://www.lua.org/manual/5.2/

### LuaJIT

Even though Textadept runs with [LuaJIT][], LuaJIT does not fully support
Lua 5.2. Therefore, try to write your modules and scripts to be compatible with
both versions. For the most part, LuaJIT only lacks Lua 5.2's new `_ENV`.

[LuaJIT]: http://luajit.org

## Scintilla

Textadept uses the [Scintilla][] editing component. The [buffer][] part of
Textadept's API emulates the [Scintilla API][] so porting any C/C++ Scintilla
calls to Lua should not be difficult.

[Scintilla]: http://scintilla.org
[buffer]: api.html#buffer
[Scintilla API]: http://scintilla.org/ScintillaDoc.html

## Textadept Structure

Because Textadept consists mainly of Lua, its Lua scripts have to be stored in
an organized folder structure.

### The *core* Directory

The *core/* directory contains Textadept's core Lua modules. These modules are
essential for the application to run. They provide Textadept's Lua to C
interface, event structure, file interactions, and localization.

### The *lexers* Directory

Lexer modules analyze source code for syntax highlighting. *lexers/* houses
them.

### The *modules* Directory

*modules/* contains generic and language modules for editing text and source
code.

### The *themes* Directory

*themes/* has built-in themes that customize the look and feel of Textadept.

### The User Directory

The *~/.textadept/* folder houses your preferences, Lua modules, themes, and
user-data. This folder may contain *lexers/*, *modules/*, and *themes/*
sub-directories.

### GTK+ Directories

GTK+ uses the *etc/*, *lib/*, and *share/* directories, which only appear in the
Win32 and Mac OSX packages.

- - -

# Compiling

- - -

## Requirements

Unfortunately, the requirements for building Textadept are not quite as minimal
as running it.

### Requirements for Linux and BSD

First, Linux and BSD systems need either the [GNU C compiler][] (*gcc*) or
[Clang][] (*clang*), as well as [GNU Make][] (*make* or *gmake*). BSD users
additionally need to have [pkg-config][] and [libiconv][] installed. All of
these should be available for your distribution through a package manager. For
example, Ubuntu includes these tools in the "build-essential" package.

Next, the GUI version of Textadept requires the GTK+ development libraries.
Again, your package manager should allow you to install them. Debian-based Linux
distributions like Ubuntu typically call the package "libgtk2.0-dev". Otherwise,
compile and install GTK+ from the [GTK+ website][].

The optional terminal version of Textadept depends on the development library
for a curses implementation like ncurses. Similarly, your package manager should
provide one. Debian-based Linux distributions like Ubuntu typically call the
ncurses package "libncurses5-dev". Otherwise, compile and install ncurses from
the [ncurses website][]. Note: you need the wide-character development version
of ncurses installed, which handles multibyte sequences. (Therefore, Debian
users _also_ need "libncursesw5-dev".)

[GNU C compiler]: http://gcc.gnu.org
[Clang]: http://clang.llvm.org/
[GNU Make]: http://www.gnu.org/software/make/
[pkg-config]: http://www.freedesktop.org/wiki/Software/pkg-config/
[libiconv]: http://www.gnu.org/software/libiconv/
[GTK+ website]: http://www.gtk.org/download/linux.php
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Requirements for Windows

Compiling Textadept on Windows is no longer supported. The preferred way to
compile for Windows is cross-compiling from Linux. To do so, you need [MinGW][]
with the Windows header files. Your package manager should offer them.

Note: compiling on Windows requires a C compiler that supports the C99 standard,
the [GTK+ for Windows bundle][] (2.24 is recommended), and
[libiconv for Windows][] (the "Developer files" and "Binaries" zip files). The
terminal (pdcurses) version requires my [win32curses bundle][] instead of GTK+
and libiconv.

[MinGW]: http://mingw.org
[GTK+ for Windows bundle]: http://www.gtk.org/download/win32.php
[libiconv for Windows]: http://gnuwin32.sourceforge.net/packages/libiconv.htm
[win32curses bundle]: download/win32curses.zip

### Requirements for Mac OSX

Compiling Textadept on Mac OSX is no longer supported. The preferred way is
cross-compiling from Linux. To do so, you need the [Apple Cross-compiler][]
binaries.

[Apple Cross-compiler]: https://launchpad.net/~flosoft/+archive/cross-apple

## Compiling

### Compiling on Linux and BSD

Note: for BSD systems, replace the `make` commands below with `gmake`.

For Linux and BSD systems, simply run `make deps` (or `make deps NIGHTLY=1` when
compiling Textadept from the latest source rather than from a tagged release) in
the *src/* directory to prepare the build environment, followed by `make` to
build the *textadept* and *textadeptjit* executables in the root directory. Make
a symlink from them to */usr/bin/* or elsewhere in your `PATH`.

Similarly, `make curses` builds *textadept-curses* and *textadeptjit-curses*.

Note: you may have to run

    make CFLAGS="-I/usr/local/include" \
         CXXFLAGS="-I/usr/local/include -L/usr/local/lib"

if the prefix where any dependencies are installed is */usr/local/* and your
compiler flags do not include them by default.

#### Installing on Linux and BSD

Textadept is self-contained, meaning you do not have to install it, and runs
from its current location. Should you choose to install Textadept like a normal
Linux application, run `make deps` (or `make deps NIGHTLY=1` as noted in the
previous section) and then the usual `make` and `make install` or
`sudo make install` commands depending on your privileges. The default prefix is
*/usr/local* but setting `DESTDIR` (e.g.
`make install DESTDIR=/prefix/to/install/to`) changes it.

Similarly, `make curses` and `make curses install` installs the curses version.

### Cross Compiling for Windows

When cross-compiling from within Linux, first make a note of your MinGW
compiler names. You may have to either modify the `CROSS` variable in the
"win32" block of *src/Makefile* or append something like "CROSS=i486-mingw32-"
when running `make`. After considering your MinGW compiler names, run
`make win32-deps` or `make CROSS=i486-mingw32- win32-deps` to prepare the build
environment followed by `make win32` or `make CROSS=i486-mingw32- win32` to
build *../textadept.exe* and *../textadeptjit.exe*. Finally, copy the dll files
from *src/win32gtk/bin/* to the directory containing the Textadept executables.

Similarly for the terminal version, run `make win32-curses` or its variant as
suggested above to build *../textadept-curses.exe* and
*../textadeptjit-curses.exe*.

Please note the build process produces a *lua51.dll* for _only_
*textadeptjit.exe* and *textadeptjit-curses.exe* because limitations on external
Lua library loading do not allow statically linking LuaJIT to Textadept.

### Cross Compiling for Mac OSX

When cross-compiling from within Linux, run `make osx-deps` to prepare the build
environment followed by `make osx` to build *../textadept.osx* and
*../textadeptjit.osx*.

Similarly, `make osx-curses` builds *../textadept-curses.osx* and
*../textadeptjit-curses.osx*.

Build a new *Textadept.app* with `make osx-app`.

#### Compiling on OSX (Legacy)

Textadept requires [XCode][] as well as [jhbuild][] (for GTK+). After building
"meta-gtk-osx-bootstrap" and "meta-gtk-osx-core", build "meta-gtk-osx-themes".
Note that the entire compiling process can easily take 30 minutes or more and
ultimately consume nearly 1GB of disk space.

After using *jhbuild*, GTK+ is in *~/gtk/* so make a symlink from *~/gtk/inst*
to *src/gtkosx* in Textadept. Then open *src/Makefile* and uncomment the
"Darwin" block. Finally, run `make osx` to build *../textadept.osx* and
*../textadeptjit.osx*.

Note: to build a GTK+ for OSX bundle, run the following from the *src/*
directory before zipping up *gtkosx/include/* and *gtkosx/lib/*:

    sed -i -e 's|libdir=/Users/username/gtk/inst/lib|libdir=${prefix}/lib|;' \
    gtkosx/lib/pkgconfig/*.pc

where `username` is your username.

Compiling the terminal version is not so expensive and requires no additional
libraries. After uncommenting the "Darwin" block mentioned above, simply run
`make osx-curses` to build *../textadept-curses.osx* and
*../textadeptjit-curses.osx*.

[XCode]: http://developer.apple.com/TOOLS/xcode/
[jhbuild]: http://sourceforge.net/apps/trac/gtk-osx/wiki/Build

### Notes on LuaJIT

[LuaJIT][] is a Just-In-Time Compiler for Lua and can boost the speed of Lua
programs. I have noticed that syntax highlighting can be up to 2 times faster
with LuaJIT than with vanilla Lua. This difference is largely unnoticable on
modern computers and usually only discernable when initially loading large
files. Other than syntax highlighting, LuaJIT offers no real benefit
performance-wise to justify it being Textadept's default runtime. LuaJIT's
[ffi library][], however, appears to be useful for interfacing with external,
non-Lua, libraries.

[LuaJIT]: http://luajit.org
[ffi library]: http://luajit.org/ext_ffi.html

### Notes on CDK

[CDK][] is a library of curses widgets. The terminal version of Textadept
includes a slightly modified, stripped down version of this library. The changes
made to CDK are in *src/cdk.patch* and listed as follows:

* Excluded the following source files: *alphalist.c*, *button.c*, *calendar.c*,
  *cdk_compat.{c,h}*, *cdk_params.c*, *cdk_test.h*, *debug.c*, *dialog.c*,
  *{d,f}scale.{c,h}*, *fslider.{c,h}*, *gen-{scale,slider}.{c,h}*,
  *get_index.c*, *get_string.c*, *graph.c*, *histogram.c*, *marquee.c*,
  *matrix.c*, *menu.c*, *popup_dialog.c*, *position.c*, *radio.c*,
  *scale.{c,h}*, *slider.{c,h}*, *swindow.c*, *template.c*,
  *u{scale,slider}.{c,h}*, *view_{file,info}.c*, and *viewer.c*.
* *binding.c* utilizes libtermkey for universal input.
* *cdk.h* does not `#include` "matrix.h", "viewer.h", and any headers labeled
  "Generated headers" due to their machine-dependence. It also `#define`s
  `boolean` as `CDKboolean` on Windows platforms since the former is already
  `typedef`ed.
* *cdk_config.h* no longer defines `HAVE_SETLOCALE` since Textadept handles
  locale settings, no longer defines `HAVE_NCURSES_H` and `NCURSES` since
  Textadept supports multiple curses implementations (not just ncurses),
  conditionally enables `HAVE_GRP_H`, `HAVE_LSTAT`, and `HAVE_PWD_H` definitions
  on \*nix platforms since Windows does not have them, and explicitly undefines
  `NCURSES_OPAQUE` since newer versions of ncurses on Mac OSX define it.
* *cdk_util.h* `#define`s `Beep` as `CDKBeep` on Windows platforms since Windows
  already defines Beep.
* The `baseName` and `dirName` functions in *cdk.c* recognize Window's '\'
  directory separator.
* Deactivated the `deleteFileCB` function in *fselect.c*.
* Removed some of CDK's initial screen handling code.
* *cdk.c* has some basic UTF-8 handling functions and *draw.c*, *entry.c*, and
  *itemlist.c* use them for UTF-8 drawing and character handling. (Note:
  *mentry.c* cannot handle UTF-8.)

[CDK]: http://invisible-island.net/cdk/

- - -

# Help

- - -

## Command Line Parameters

Passing `-h` or `--help` to Textadept shows a list of available command line
parameters.

Switch             |Arguments|Description
-------------------|:-------:|-----------
`-e`, `--execute`  |    1    |Run Lua [code](#Lua.Command.Entry).
`-f`, `--force`    |    0    |Forces [unique instance](#Single.Instance).
`-h`, `--help`     |    0    |Shows this.
`-n`, `--nosession`|    0    |No [session](#Sessions) functionality.
`-s`, `--session`  |    1    |Loads [session](#Sessions) on startup.
`-u`, `--userhome` |    1    |Sets alternate [`_USERHOME`][].

Textadept curses does not support the help switch.

[`_USERHOME`]: api.html#_USERHOME

## Online Help

Textadept has a [mailing list][] and a [wiki][].

[mailing list]: http://foicica.com/lists
[wiki]: http://foicica.com/wiki/textadept

- - -

# Appendix

- - -

## Lua Patterns

The following is from the [Lua 5.3 Reference Manual][].

_Character Class:_

A character class is used to represent a set of characters. The following
combinations are allowed in describing a character class:

* **_`x`_:** (where _x_ is not one of the magic characters `^%()%.[]*+-?`)
  represents the character _x_ itself.
* **`.`:** (a dot) represents all characters.
* **`%a`:** represents all letters.
* **`%c`:** represents all control characters.
* **`%d`:** represents all digits.
* **`%g`:** represents all printable characters except space.
* **`%l`:** represents all lowercase letters.
* **`%p`:** represents all punctuation characters.
* **`%s`:** represents all space characters.
* **`%u`:** represents all uppercase letters.
* **`%w`:** represents all alphanumeric characters.
* **`%x`:** represents all hexadecimal digits.
* **`%`_`x`_:** (where _x_ is any non-alphanumeric character) represents the
  character _x_. This is the standard way to escape the magic characters. Any
  non-alphanumeric character (including all punctuations, even the non magical)
  can be preceded by a '`%`' when used to represent itself in a pattern.
* **`[set]`:** represents the class which is the union of all characters in set.
  A range of characters can be specified by separating the end characters of the
  range with a '`-`'. All classes `%`_x_ described above can also be used as
  components in set. All other characters in set represent themselves. For
  example, `[%w_]` (or `[_%w]`) represents all alphanumeric characters plus the
  underscore, `[0-7]` represents the octal digits, and `[0-7%l%-]` represents
  the octal digits plus the lowercase letters plus the '`-`' character.
  <br /><br />
  The interaction between ranges and classes is not defined. Therefore, patterns
  like `[%a-z]` or `[a-%%]` have no meaning.
* **`[^set]`:** represents the complement of _set_, where _set_ is interpreted
  as above.

For all classes represented by single letters (`%a`, `%c`, etc.), the
corresponding uppercase letter represents the complement of the class. For
instance, `%S` represents all non-space characters.

The definitions of letter, space, and other character groups depend on the
current locale. In particular, the class `[a-z]` may not be equivalent to `%l`.

_Pattern Item:_

A _pattern item_ can be

* a single character class, which matches any single character in the class;
* a single character class followed by '`*`', which matches zero or more
  repetitions of characters in the class. These repetition items will always
  match the longest possible sequence;
* a single character class followed by '`+`', which matches one or more
  repetitions of characters in the class. These repetition items will always
  match the longest possible sequence;
* a single character class followed by '`-`', which also matches zero or more
  repetitions of characters in the class. Unlike '`*`', these repetition items
  will always match the _shortest_ possible sequence;
* a single character class followed by '`?`', which matches zero or one
  occurrence of a character in the class. It always matches one occurrence if
  possible.
* `%n`, for _n_ between 1 and 9; such item matches a substring equal to the
  _n_-th captured string (see below);
* `%bxy`, where _x_ and _y_ are two distinct characters; such item matches
  strings that start with _x_, end with _y_, and where the _x_ and _y_ are
  balanced. This means that, if one reads the string from left to right,
  counting +_1_ for an _x_ and -_1_ for a _y_, the ending _y_ is the first _y_
  where the count reaches 0. For instance, the item `%b()` matches expressions
  with balanced parentheses.
* `%f[set]`, a _frontier pattern_; such item matches an empty string at any
  position such that the next character belongs to _set_ and the previous
  character does not belong to _set_. The set _set_ is interpreted as previously
  described. The beginning and the end of the subject are handled as if they
  were the character `'\0'`.

_Pattern:_

A _pattern_ is a sequence of pattern items. A '`^`' at the beginning of a
pattern anchors the match at the beginning of the subject string. A '`$`' at the
end of a pattern anchors the match at the end of the subject string. At other
positions, '`^`' and '`$`' have no special meaning and represent themselves.

_Captures:_

A pattern can contain sub-patterns enclosed in parentheses; they describe
_captures_. When a match succeeds, the substrings of the subject string that
match captures are stored (_captured_) for future use. Captures are numbered
according to their left parentheses. For instance, in the pattern
`"(a*(.)%w(%s*))"`, the part of the string matching `"a*(.)%w(%s*)"` is stored
as the first capture (and therefore has number 1); the character matching "`.`"
is captured with number 2, and the part matching "`%s*`" has number 3.

As a special case, the empty capture `()` captures the current string position
(a number). For instance, if we apply the pattern `"()aa()"` on the string
`"flaaap"`, there will be two captures: 3 and 5.

[Lua 5.3 Reference Manual]: http://www.lua.org/manual/5.3/manual.html#6.4.1

## Curses Compatibility

Textadept 5.5 beta introduced a curses version that is capable of running in a
terminal emulator. However, it requires a font with good glyph support (like
DejaVu Sans Mono or Liberation Mono), and lacks some GUI features due to the
terminal's constraints:

* No alpha values or transparency.
* No images in autocompletion lists. Instead, autocompletion lists show the
  first character in the string passed to [`buffer.register_image()`][].
* No buffered or two-phase drawing.
* Carets cannot have a period, line style, or width.
* No drag and drop.
* Edge lines may be obscured by text.
* No extra line ascent or descent.
* No fold lines above and below lines.
* No hotspot underlines on mouse hover.
* No indicators other than `INDIC_ROUNDBOX` and `INDIC_STRAIGHTBOX`, although
  neither has translucent drawing and `INDIC_ROUNDBOX` does not have rounded
  corners.
* Some complex marker symbols are not drawn properly or at all.
* No mouse cursor types.
* Only up to 16 colors recognized, regardless of how many colors the terminal
  supports. They are (in "0xBBGGRR" format): black (`0x000000`), red
  (`0x000080`), green (`0x008000`), yellow (`0x008080`), blue (`0x800000`),
  magenta (`0x800080`), cyan (`0x808000`), white (`0xC0C0C0`), light black
  (`0x404040`), light red (`0x0000FF`), light green (`0x00FF00`), light yellow
  (`0x00FFFF`), light blue (`0xFF0000`), light magenta (`0xFF00FF`), light cyan
  (`0xFFFF00`), and light white (`0xFFFFFF`). Even if your terminal uses a
  different color map, you must use these color values. Your terminal will remap
  them automatically. Unrecognized colors default to white. For some terminals,
  you may need to set a lexer style's `bold` attribute in order to use the light
  color variant.
* Not all key sequences recognized properly.
* No style settings like font name, font size, or italics.
* No X selection, primary or secondary, integration with the clipboard.
* No zoom.

[`buffer.register_image()`]: api.html#buffer.register_image

## Migration Guides

### Textadept 7 to 8

Textadept 8 upgraded its internal copy of Lua from [5.2 to 5.3][]. Nearly all
user scripts will continue to function properly without modification --
Textadept itself only needed to update some instances of numeric division to
account for Lua's new integer/float distinction.

Textadept 8 has no major API changes of note. Instead, the table below lists all
API changes during the 7.x cycle. Please consult this table when upgrading from
your particular version of Textadept 7.

Textadept 8 did introduce changes in language-specific keybindings and macros
for compile and run commands, which are described in the sections below.

[5.2 to 5.3]: http://www.lua.org/manual/5.3/manual.html#8

#### API Changes

Old API                    |Change  |New API                             |Since
---------------------------|:------:|------------------------------------|-----
**_G**                     |        |                                    |
N/A                        |Added   |[spawn()][]                         |7.2
N/A                        |Added   |[LINUX][]                           |7.8
N/A                        |Added   |[BSD][]                             |7.8
**_M**                     |        |                                    |
_lang_.context\_menu       |Removed |                                    |7.8
**_SCINTILLA**             |        |                                    |
N/A                        |Added   |[next\_image\_type()][]             |7.8
**events**                 |        |                                    |
N/A                        |Added   |[FILE\_OPENED][]                    |7.1
N/A                        |Added   |[FOCUS][]                           |7.5
N/A                        |Added   |[CSI][]                             |7.8
N/A                        |Added   |[SUSPEND][]                         |7.8
N/A                        |Added   |[RESUME][]                          |7.8
FILE\_SAVED\_AS            |Replaced|[FILE\_AFTER\_SAVE][]               |7.9
**io**                     |        |                                    |
set\_buffer\_encoding()    |Renamed |[buffer:set\_encoding()]            |7.3
boms                       |Removed |                                    |7.9
**lexer**                  |        |                                    |
N/A                        |Added   |[\_FOLDBYINDENTATION][]             |8.0
**lfs**                    |        |                                    |
dir\_foreach(...)          |Changed |[dir\_foreach][](..., n, incl\_dirs)|7.6
**textadept.adeptsense**   |Removed |                                    |
complete()                 |Replaced|editing.[autocomplete()][]          |7.3
show\_apidoc()             |Replaced|editing.[show\_documentation()][]   |7.3
**textadept.bookmarks**    |        |                                    |
toggle(on)                 |Changed |[toggle][](on, line)                |8.0
**textadept.command_entry**|        |                                    |
complete\_lua()            |Removed |                                    |7.3
execute\_lua()             |Removed |                                    |7.3
**textadept.editing**      |        |                                    |
N/A                        |Added   |[AUTOCOMPLETE\_ALL][]               |7.3
N/A                        |Added   |[autocompleters][]                  |7.3
autocomplete\_word()       |Replaced|autocomplete('word')                |7.3
HIGHLIGHT\_BRACES          |Removed |                                    |7.3
selecte\_indented\_block() |Removed |                                    |7.3
**textadept.file_types**   |        |                                    |
shebangs                   |Replaced|[patterns][]<sup>a</sup>            |7.9
**textadept.menu**         |        |                                    |
set\_menubar(menubar)      |Replaced|[menubar][] = menubar               |7.3
set\_contextmenu(menu)     |Replaced|[context_menu][] = menu             |7.3
set\_tabcontextmenu(menu)  |Replaced|[tab_context_menu][] = menu         |7.3
**textadept.run**          |        |                                    |
N/A                        |Added   |[build()][]                         |7.2
N/A                        |Added   |[build_commands][]                  |7.2
N/A                        |Added   |[stop()][]                          |7.2
N/A                        |Added   |[RUN\_IN\_BACKGROUND][]             |8.0
**ui**                     |        |                                    |
N/A                        |Added   |[tabs][]                            |7.1
N/A                        |Added   |[SILENT\_PRINT][]                   |7.2
**ui.command_entry**       |        |                                    |
N/A                        |Added   |[editing\_keys][]                   |7.8
enter\_mode(mode)          |Changed |[enter\_mode][](mode, lexer, height)|7.8
**ui.dialogs**             |        |                                    |
N/A                        |Added   |[optionselect()][]                  |7.2

<sup>a</sup>`shebangs.lua = 'lua'` converts to `patterns['^#!.+/lua'] = 'lua'`

[spawn()]: api.html#spawn
[LINUX]: api.html#LINUX
[BSD]: api.html#BSD
[next\_image\_type()]: api.html#_SCINTILLA.next_image_type
[FILE\_OPENED]: api.html#events.FILE_OPENED
[FOCUS]: api.html#events.FOCUS
[CSI]: api.html#events.CSI
[SUSPEND]: api.html#events.SUSPEND
[RESUME]: api.html#events.RESUME
[FILE\_AFTER\_SAVE]: api.html#events.FILE_AFTER_SAVE
[buffer:set\_encoding()]: api.html#buffer.set_encoding
[\_FOLDBYINDENTATION]: api.html#lexer.Fold.by.Indentation
[dir\_foreach]: api.html#lfs.dir_foreach
[autocomplete()]: api.html#textadept.editing.autocomplete
[show\_documentation()]: api.html#textadept.editing.show_documentation
[toggle]: api.html#textadept.bookmarks.toggle
[AUTOCOMPLETE\_ALL]: api.html#textadept.editing.AUTOCOMPLETE_ALL
[autocompleters]: api.html#textadept.editing.autocompleters
[patterns]: api.html#textadept.file_types.patterns
[menubar]: api.html#textadept.menu.menubar
[context_menu]: api.html#textadept.menu.context_menu
[tab_context_menu]: api.html#textadept.menu.tab_context_menu
[build()]: api.html#textadept.run.build
[build_commands]: api.html#textadept.run.build_commands
[stop()]: api.html#textadept.run.stop
[RUN\_IN\_BACKGROUND]: api.html#textadept.run.RUN_IN_BACKGROUND
[tabs]: api.html#ui.tabs
[SILENT\_PRINT]: api.html#ui.SILENT_PRINT
[editing\_keys]: api.html#ui.command_entry.editing_keys
[enter\_mode]: api.html#ui.command_entry.enter_mode
[optionselect()]: api.html#ui.dialogs.optionselect

#### Language-specific Key Changes

Textadept 8 removed the `keys.LANGUAGE_MODULE_PREFIX` key binding (which has
been `Ctrl+L` for Win32 and Linux, `⌘L` on Mac OSX, and `M-L` in curses), but
only in name. Textadept 8 does not make use of this key, and it is still
traditionally reserved for use by language-specific modules. You can use as such
from your language module like this:

    keys.lua[not OSX and not CURSES and 'cl' or 'ml'] = {
      ...
    }

#### Compile and Run Macro Changes

Textadept 8 removed the long-hand macros for [compile and run commands][] in
favor or shorthand ones (most of which have been available since 7.1).

Old Macro         |New Macro
------------------|---------
%(filename)       |%f
%(filename\_noext)|%e
%(filedir)        |%d
%(filepath)       |%p

Any modules and language-specific modules using the long-hand notation must be
updated.

[compile and run commands]: api.html#_M.Compile.and.Run

### Textadept 6 to 7

Textadept 7 introduces API changes, a change in module mentality and filename
encodings, and a completely new theme implementation.

#### API Changes

Old API                           |Change  |New API
----------------------------------|:------:|-------
**_G**                            |        |
RESETTING                         |Removed |N/A<sup>a</sup>
buffer\_new()                     |Renamed |\_G.[buffer.new()][]
**_M.textadept**                  |Renamed |[textadept][]
filter\_through                   |Removed |N/A
filter\_through.filter\_through() |Renamed |editing.[filter\_through()][]
mime\_types                       |Renamed |[file\_types][]<sup>b</sup>
**_M.textadept.bookmark**         |        |
N/A                               |New     |[goto\_mark()][]
N/A                               |New     |[MARK\_BOOKMARK][]
MARK\_BOOKMARK\_COLOR             |Removed |N/A<sup>c</sup>
goto\_bookmark                    |Replaced|goto\_mark()
goto\_next                        |Replaced|goto\_mark(true)
goto\_prev                        |Replaced|goto\_mark(false)
**_M.textadept.editing**          |        |
N/A                               |New     |[INDIC\_BRACEMATCH][]
N/A                               |New     |[INDIC\_HIGHLIGHT][]
INDIC\_HIGHLIGHT\_BACK            |Removed |N/A<sup>d</sup>
autocomplete\_word(chars, default)|Changed |autocomplete\_word(default)
grow\_selection()                 |Replaced|[select\_enclosed()][]
**_M.textadept.menu**             |        |
menubar                           |Removed |N/A
contextmenu                       |Removed |N/A
**_M.textadept.run**              |        |
N/A                               |New     |[MARK\_WARNING][]
N/A                               |New     |[MARK\_ERROR][]
MARK\_ERROR\_BACK                 |Removed |N/A<sup>c</sup>
compile\_command                  |Renamed |[compile\_commands][]
run\_command                      |Renamed |[run\_commands][]
error\_detail                     |Renamed |[error\_patterns][]<sup>e</sup>
**_M.textadept.snapopen**         |Removed |N/A
open                              |Changed |\_G.[io.snapopen()][]<sup>f</sup>
**_SCINTILLA.constants**          |        |
SC\_\*                            |Renamed |Removed "SC\_" prefix.
SC(FIND\|MOD\|VS\|WS)             |Renamed |Removed "SC" prefix.
**buffer**                        |        |
check\_global()                   |Removed |
get\_style\_name(buffer, n)       |Renamed |[style\_name][]\[n\]
reload()                          |Renamed |[io.reload\_file()][]
save()                            |Renamed |[io.save\_file()][]
save\_as()                        |Renamed |[io.save\_file\_as()][]
close()                           |Renamed |[io.close\_buffer()][]
set\_encoding()                   |Renamed |[io.set\_buffer\_encoding()][]
convert\_eo\_ls()                 |Renamed |[buffer.convert\_eols()][]
dirty                             |Replaced|[buffer.modify][]
**events**                        |        |
N/A                               |New     |[INITIALIZED][]
handlers                          |Removed |N/A
**gui**                           |Renamed |[ui][]
docstatusbar\_text                |Renamed |[bufstatusbar\_text][]
N/A                               |New     |[maximized][]
find.goto\_file\_in\_list()       |Renamed |find.[goto\_file\_found()][]
select\_theme                     |Removed |N/A
N/A                               |New     |[dialogs][]
filteredlist                      |Removed |N/A
set\_theme(name, ...)             |Changed |[set\_theme][](name, table)
**io**                            |        |
try\_encodings                    |Renamed |[encodings][]
open\_file(string)                |Changed |[open\_file][](string or table)
snapopen(string, ...)             |Changed |[snapopen][](string or table, ...)
save\_all()                       |Renamed |[save\_all\_files()][]
close\_all()                      |Renamed |[close\_all\_buffers()][]

<sup>a</sup>`arg` is `nil` when resetting.

<sup>b</sup>Removed *mime_types.conf* files. Interact with Lua tables directly.

<sup>c</sup>Set [`buffer.marker_back`][] in [`events.VIEW_NEW`][].

<sup>d</sup>Set [`buffer.indic_fore`][] in [`events.VIEW_NEW`][].

<sup>e</sup>Changed structure too.

<sup>f</sup>Changed arguments too.

[buffer.new()]: api.html#buffer.new
[textadept]: api.html#textadept
[filter\_through()]: api.html#textadept.editing.filter_through
[file\_types]: api.html#textadept.file_types
[goto\_mark()]: api.html#textadept.bookmarks.goto_mark
[MARK\_BOOKMARK]: api.html#textadept.bookmarks.MARK_BOOKMARK
[INDIC\_BRACEMATCH]: api.html#textadept.editing.INDIC_BRACEMATCH
[INDIC\_HIGHLIGHT]: api.html#textadept.editing.INDIC_HIGHLIGHT
[select\_enclosed()]: api.html#textadept.editing.select_enclosed
[MARK\_WARNING]: api.html#textadept.run.MARK_WARNING
[MARK\_ERROR]: api.html#textadept.run.MARK_ERROR
[compile\_commands]: api.html#textadept.run.compile_commands
[run\_commands]: api.html#textadept.run.run_commands
[error\_patterns]: api.html#textadept.run.error_patterns
[io.snapopen()]: api.html#io.snapopen
[style\_name]: api.html#buffer.style_name
[io.reload\_file()]: api.html#io.reload_file
[io.save\_file()]: api.html#io.save_file
[io.save\_file\_as()]: api.html#io.save_file_as
[io.close\_buffer()]: api.html#io.close_buffer
[io.set\_buffer\_encoding()]: api.html#buffer.set_encoding
[buffer.convert\_eols()]: api.html#buffer.convert_eols
[buffer.modify]: api.html#buffer.modify
[INITIALIZED]: api.html#events.INITIALIZED
[ui]: api.html#ui
[bufstatusbar\_text]: api.html#ui.bufstatusbar_text
[maximized]: api.html#ui.maximized
[goto\_file\_found()]: api.html#ui.find.goto_file_found
[dialogs]: api.html#ui.dialogs
[set\_theme]: api.html#ui.set_theme
[encodings]: api.html#io.encodings
[open\_file]: api.html#io.open_file
[snapopen]: api.html#io.snapopen
[save\_all\_files()]: api.html#io.save_all_files
[close\_all\_buffers()]: api.html#io.close_all_buffers
[`buffer.marker_back`]: api.html#buffer.marker_back
[`events.VIEW_NEW`]: api.html#events.VIEW_NEW
[`buffer.indic_fore`]: api.html#buffer.indic_fore

#### Module Mentality

Prior to Textadept 7, the `_M` table held all loaded modules (regardless of
whether they were generic modules or language modules) and Textadept encouraged
users to load custom modules into `_M` even though Lua has no such restriction.
The `_M` prefix no longer makes much sense for generic modules like
[`textadept`][], so only language modules are automatically loaded into
[`_M`][]. Textadept 7 does not encourage any prefix for custom, generic modules;
the user is free to choose.

[`textadept`]: api.html#textadept
[`_M`]: api.html#_M

#### Filename Encodings

Prior to Textadept 7, `buffer.filename` was encoded in UTF-8 and any functions
that accepted filenames (such as `io.open_file()`) required the filenames to
also be encoded in UTF-8. This is no longer the case in Textadept 7.
`buffer.filename` is encoded in `_CHARSET` and any filenames passed to functions
should also remain encoded in `_CHARSET`. No more superfluous encoding
conversions. You should only convert to and from UTF-8 when displaying or
retrieving displayed filenames from buffers and/or dialogs.

#### Theme Changes

You can use the following as a reference for converting your Textadept 6 themes
to Textadept 7:

    -- File *theme/lexer.lua*            | -- File *theme.lua*
    -- Textadept 6                       | -- Textadept 7
    local l = lexer                      | local buffer = buffer
    local color = l.color                | local prop = buffer.property
    local style = l.style                | local prop_int =
                                         |   buffer.property_int
                                         |
    l.colors = {                         |
      ...                                | ...
      red = color('99', '4D', '4D'),     | prop['color.red'] = 0x4D4D99
      yellow = color('99', '99', '4D'),  | prop['color.yellow'] = 0x4D9999
      ...                                | ...
    }                                    |
                                         |
    l.style_nothing = style{}            | prop['style.nothing'] = ''
    l.style_class = style{               | prop['style.class'] =
      fore = l.colors.yellow             |   'fore:%(color.yellow)'
    }                                    | ...
    ...                                  | prop['style.identifier'] =
    l.style_identifier = l.style_nothing |   '%(style.nothing)'
                                         |
    ...                                  | ...
                                         |
                                         | prop['font'] = 'Monospace'
    local font, size = 'Monospace', 10   | prop['fontsize'] = 10
    l.style_default = style{             | prop['style.default'] =
      font = font, size = size,          |   'font:%(font),'..
      fore = l.colors.light_black        |   'size:%(fontsize),'..
      back = l.colors.white              |   'fore:%(color.light_black),'..
    }                                    |   'back:%(color.white)'
    ...                                  | ...

    -- File *theme/view.lua*             | -- Same file *theme.lua*!
                                         |
    ...                                  | ...
    -- Caret and Selection Styles.       | -- Caret and Selection Styles.
    buffer:set_sel_fore(true, 0x333333)  | buffer:set_sel_fore(true,
                                         |   prop_int['color.light_black'])
    buffer:set_sel_back(true, 0x999999)  | buffer:set_sel_back(true,
                                         |   prop_int['color.light_grey'])
    --buffer.sel_alpha =                 | --buffer.sel_alpha =
    --buffer.sel_eol_filled = true       |
    buffer.caret_fore = 0x4D4D4D         | buffer.caret_fore =
                                         |   prop_int['color.grey_black']
    ...                                  | ...

Notes:

1. Textadept 7's themes share its Lua state and set lexer colors and styles
   through named buffer properties.
2. Convert colors from "RRGGBB" string format to the "0xBBGGRR" number format
   that Textadept's API documentation uses consistently.
3. The only property names that matter are the "style._name_" ones. Other
   property names are arbitrary.
4. Instead of using variables, which are evaluated immediately, use "%(key)"
   notation, which substitutes the value of property "key" at a later point in
   time. This means you do not have to define properties before use. You can
   also modify existing properties without redefining the properties that depend
   on them. See the [customizing themes](#Customizing.Themes) section for an
   example.
5. Set view properties related to colors directly in *theme.lua* now instead of
   a separate *view.lua*. You may use color properties defined earlier. Try to
   refrain from setting properties like `buffer.sel_eol_filled` which belong in
   a [*properties.lua*](#Buffer.Settings) file.
6. The separate *buffer.lua* is gone. Use [*properties.lua*](#Buffer.Settings)
   or a [language module](#Language-Specific.Buffer.Settings).

##### Theme Preference

Textadept 7 ignores the *~/.textadept/theme* and *~/.textadept/theme_term* files
that specified your preferred Textadept 6 theme. Use *~/.textadept/init.lua* to
[set a preferred theme](#Setting.Themes) instead. For example, if you had custom
GUI and terminal themes:

    -- File *~/.textadept/init.lua*
    ui.set_theme(not CURSES and 'custom' or 'custom_term')

You may still use absolute paths for themes instead of names.

### Textadept 5 to 6

Textadept 6 introduces some API changes. These changes affect themes in
particular, so your themes may require upgrading.

Old API                              | Change | New API
-------------------------------------|:------:|--------
**buffer**                           |        |
annotation\_get\_text(line)          |Renamed |annotation\_text[line]
annotation\_set\_text(line, text)    |Renamed |annotation\_text[line] = text
auto\_c\_get\_current()              |Renamed |auto\_c\_current
auto\_c\_get\_current\_text()        |Renamed |auto\_c\_current\_text
get\_lexer\_language()               |Renamed |lexer\_language
get\_property(key)                   |Renamed |property[key]
get\_property\_expanded(key)         |Renamed |property\_expanded[key]
get\_tag(n)                          |Renamed |tag[n]
margin\_get\_text(line)              |Renamed |margin\_text[line]
margin\_set\_text(line, text)        |Renamed |margin\_text[line] = text
marker\_set\_alpha(n, alpha)         |Renamed |marker\_alpha[n] = alpha
marker\_set\_back(n, color)          |Renamed |marker\_back[n] = color
marker\_set\_back\_selected(n, color)|Renamed |marker\_back\_selected[n] = color
marker\_set\_fore(n, color)          |Renamed |marker\_fore[n] = color
set\_fold\_flags(flags)              |Renamed |fold\_flags = flags
set\_lexer\_language(name)           |Renamed |lexer\_language = name
style\_get\_font(n)                  |Renamed |style\_font[n]
**gui**                              |        |
gtkmenu()                            |Renamed |[menu()][]
**_G**                               |        |
user\_dofile(file)                   |Renamed |dofile(\_USERHOME..'/'..file)
**_M**                               |        |
lua.goto\_required()                 |Removed |N/A
php.goto\_required()                 |Removed |N/A
ruby.goto\_required()                |Removed |N/A
**_M.textadept.adeptsense**          |        |
complete\_symbol()                   |Replaced|complete()
show\_documentation()                |Replaced|show\_apidoc()
**_M.textadept.bookmarks**           |        |
N/A                                  |New     |[toggle()][]
add()                                |Renamed |toggle(true)
remove()                             |Renamed |toggle(false)
**_M.textadept.editing**             |        |
prepare\_for\_save()                 |Removed |N/A
**_M.textadept.menu**                |        |
rebuild\_command\_tables()           |Replaced|set\_menubar()
**_M.textadept.run**                 |        |
execute()                            |Replaced|[run()][] and [compile()][]
**_M.textadept.session**             |        |
prompt\_load()                       |Replaced|[load()][]
prompt\_save()                       |Replaced|[save()][]

[menu()]: api.html#ui.menu
[toggle()]: api.html#textadept.bookmarks.toggle
[run()]: api.html#textadept.run.run
[compile()]: api.html#textadept.run.compile
[load()]: api.html#textadept.session.load
[save()]: api.html#textadept.session.save

### Textadept 4 to 5

Textadept 5 upgraded its copy of Lua from [5.1 to 5.2][]. Many old scripts are
not compatible and need to be upgraded. Since incompatible scripts may cause
crashes on startup, the following guide will help you migrate your scripts from
Textadept 4 to Textadept 5. While this guide is not exhaustive, it covers the
changes I had to make to Textadept's internals.

[5.1 to 5.2]: http://www.lua.org/manual/5.2/manual.html#8

#### API Changes

Old API        |Change  |New API
---------------|:------:|-------
**_G**         |        |
getfenv(f)     |Removed |N/A. Use:<br/>debug.getupvalue(f, 1)
loadstring()   |Replaced|load()
module()       |Removed |N/A
setfenv(f, env)|Removed |N/A. Use:<br/>debug.setupvalue(f, 1, env)<sup>a</sup>
unpack()       |Renamed |table.unpack()
xpcall(f, msgh)|Changed |xpcall(f, msgh, ...)
**\_m**        |Renamed |**[\_M][]**<sup>b</sup>
**_m.textadept.editing**|       |
current\_word(action)   |Renamed|[select\_word()][]<sup>c</sup>
**locale**              |Removed|N/A
localize(message)       |Renamed|\_G.[\_L][][message]
**os**                  |       |
code = execute(cmd)     |Changed|ok, status, code = execute(cmd)

<sup>a</sup>In some cases, use `load()` with an environment instead:

    setfenv(loadstring(str), env)() --> load(str, nil, 'bt', env)()

<sup>b</sup>In Textadept, search for "\_m" and replace with "\_M" with the
"Match Case" and "Whole Words" options checked -- this is what I did when
upgrading Textadept's internals.

<sup>c</sup>To delete, call `_M.textadept.keys.utils.delete_word()` or define
your own:

    local function delete_word()
      _M.textadept.editing.select_word()
      buffer:delete_back()
    end

[\_M]: api.html#_M
[select\_word()]: api.html#textadept.editing.select_word
[\_L]: api.html#_L

#### Module Changes

You can use the following as a reference for converting your Lua 5.1 modules to
Lua 5.2:

    -- File *~/.textadept/modules/foo.lua*
    -- Lua 5.1                    | -- Lua 5.2
                                  |
                                  | local M = {}
                                  | --[[ This comment is for LuaDoc
    ---                           | ---
    -- This is the documentation  | -- This is the documentation
    -- for module foo.            | -- for module foo.
    module('foo', package.seeall) | module('foo')]]
                                  |
    ---                           | ---
    -- Documentation for bar.     | -- Documentation for bar.
    -- ...                        | -- ...
    --                            | -- @name bar
    function bar()                | function M.bar()
      ...                         |   ...
    end                           | end
                                  |
    function baz()                | function M.baz()
      bar()                       |   M.bar()
    end                           | end
                                  |
                                  | return M

    -- File *~/.textadept/init.lua*
    -- Lua 5.1                    | -- Lua 5.2
                                  |
    require 'textadept'           | _M.textadept = require 'textadept'
    require 'foo'                 | foo = require 'foo'

Notes:

1. Even though Lua 5.2 deprecates Lua 5.1's `module()`, Textadept 5 removes it.
2. Prefix all intern module tables and function calls with `M`.
3. Also, replace all instances (if any) of `_M` (a references created by
   `module()` that holds the current module table) with `M`.
4. You can use your existing LuaDoc comments by keeping the `module()` call
   commented out and adding `@name` tags.

#### Theme Changes

You can use the following as a reference for converting your Lua 5.1 themes to
Lua 5.2:

    -- File *~/.textadept/themes/theme/lexer.lua*
    -- Lua 5.1                       | -- Lua 5.2
                                     |
                                     | local l = lexer
    module('lexer', package.seeall)  | local color = l.color
                                     | local style = l.style
                                     |
    colors = {                       | l.colors = {
      ...                            |   ...
    }                                | }
                                     |
    style_nothing = style{}          | l.style_nothing = style{...}
    style_class = style{             | l.style_class = style{
      fore = colors.light_yellow     |   fore = l.colors.light_yellow
    }                                | }
    ...                              | ...
    style_identifier = style_nothing | l.style_identifier = l.style_nothing
                                     |
    ...                              | ...
                                     |
    style_default = style{           | l.style_default = style{
      ...                            |   ...
    }                                | }
    style_line_number = {            | l.style_line_number = {
      fore = colors.dark_grey,       |   fore = l.colors.dark_grey,
      back = colors.black            |   back = l.colors.black
    }                                | }
    ...                              | ...

Note the `l.` prefix before most identifiers.

### Textadept 3 to 4

#### Key and Menu Changes

Textadept 4 features a brand new set of key bindings and menu structure. It also
shows simple key bindings (not keychains) in menus. In order for key bindings to
appear in menus, `_m.textadept.menu` must know which commands map to which keys.
Therefore, the menu module needs to be `require`d *after* `_m.textadept.keys`.
If your *~/.textadept/init.lua* calls `require 'textadept'`, you do not have to
make any changes. If you load individual modules from `_m.textadept`, ensure
`_m.textadept.menu` loads after `_m.textadept.keys`.

Mac OSX has different modifier key definitions. A new `m` indicates ⌘ (command)
and `a` changed from ⌘ to ⌥ (alt/option). `c` remains ^ (control). Keep in mind
that ⌥ functions as a compose key for locale-dependent characters.

#### API Changes

Old API                  |Change | New API
-------------------------|:-----:|--------
**\_m.textadept.editing**|       |
select\_scope()          |Renamed|select\_style()
SAVE\_STRIPS\_WS         |Renamed|STRIP\_WHITESPACE\_ON\_SAVE

### Textadept 2 to 3

#### Module Changes

##### Core Extensions

The core extention modules moved from *core/ext/* to *modules/textadept/*.
Putting

    require 'textadept'

in your *~/.textadept/init.lua* loads all the modules you would expect. The
[loading modules](#Loading.Modules) section has instructions on how to load
specific modules.

##### Autoloading Keys and Snippets

Key bindings in *~/.textadept/key_commands.lua* and snippets in
*~/.textadept/snippets.lua* no longer auto-load. Move them to your
*~/.textadept/init.lua* or a file loaded by *~/.textadept/init.lua*.

#### API Changes

Textadept has a brand new Lua [API][]. Old scripts and themes are likely not
compatible and need to be upgraded.

Old API                   |Change | New API
--------------------------|:-----:|--------
**_G**                    |       |
N/A                       |New    |[\_SCINTILLA][]
N/A                       |New    |[events][]
N/A                       |New    |[gui][]
**_m.textadept.lsnippets**|Renamed|**[_m.textadept.snippets][]**
**textadept**             |Removed|N/A
\_print()                 |Renamed|\_G.[gui.\_print()][]
buffer\_functions         |Renamed|\_G.[\_SCINTILLA.functions][]
buffer\_properties        |Renamed|\_G.[\_SCINTILLA.properties][]
buffers                   |Renamed|\_G.[\_BUFFERS][]
check\_focused\_buffer()  |Renamed|\_G.gui.check\_focused\_buffer()
clipboard\_text           |Renamed|\_G.[gui.clipboard\_text][]
command\_entry            |Renamed|\_G.[gui.command\_entry][]
constants                 |Renamed|\_G.[\_SCINTILLA.constants][]
context\_menu             |Renamed|\_G.[gui.context\_menu][]
dialog                    |Renamed|\_G.[gui.dialog()][]
docstatusbar\_text        |Renamed|\_G.[gui.docstatusbar\_text][]
events                    |Renamed|\_G.[events][]
events.add\_handler()     |Renamed|\_G.[events.connect()][]
events.handle()           |Renamed|\_G.[events.emit()][]
find                      |Renamed|\_G.[gui.find][]
focused\_doc\_pointer     |Renamed|\_G.gui.focused\_doc\_pointer
get\_split\_table()       |Renamed|\_G.[gui.get\_split\_table()][]
goto\_view()              |Renamed|\_G.[gui.goto\_view()][]
gtkmenu()                 |Renamed|\_G.[gui.gtkmenu()][]
iconv()                   |Renamed|\_G.[string.iconv()][]
menubar                   |Renamed|\_G.[gui.menubar][]
new\_buffer()             |Renamed|\_G.[new\_buffer()][]
print()                   |Renamed|\_G.[gui.print()][]
quit()                    |Renamed|\_G.[quit()][]
reset()                   |Renamed|\_G.[reset()][]
session\_file             |Renamed|\_G.\_SESSIONFILE
size                      |Renamed|\_G.[gui.size][]
statusbar\_text           |Renamed|\_G.[gui.statusbar\_text][]
switch\_buffer()          |Renamed|\_G.[gui.switch\_buffer()][]
title                     |Renamed|\_G.[gui.title][]
user\_dofile()            |Renamed|\_G.user\_dofile()
views                     |Renamed|\_G.[\_VIEWS][]

[API]: api
[\_SCINTILLA]: api.html#_SCINTILLA
[events]: api.html#events
[gui]: api.html#ui
[_m.textadept.snippets]: api.html#textadept.snippets
[gui.\_print()]: api.html#ui._print
[\_SCINTILLA.functions]: api.html#_SCINTILLA.functions
[\_SCINTILLA.properties]: api.html#_SCINTILLA.properties
[\_BUFFERS]: api.html#_BUFFERS
[gui.clipboard\_text]: api.html#ui.clipboard_text
[gui.command\_entry]: api.html#ui.command_entry
[\_SCINTILLA.constants]: api.html#_SCINTILLA.constants
[gui.context\_menu]: api.html#ui.context_menu
[gui.dialog()]: api.html#ui.dialog
[gui.docstatusbar\_text]: api.html#ui.docstatusbar_text
[events.connect()]: api.html#events.connect
[events.emit()]: api.html#events.emit
[gui.find]: api.html#ui.find
[gui.get\_split\_table()]: api.html#ui.get_split_table
[gui.goto\_view()]: api.html#ui.goto_view
[gui.gtkmenu()]: api.html#ui.menu
[string.iconv()]: api.html#string.iconv
[gui.menubar]: api.html#ui.menubar
[new\_buffer()]: api.html#buffer.new
[gui.print()]: api.html#ui.print
[quit()]: api.html#quit
[reset()]: api.html#reset
[gui.size]: api.html#ui.size
[gui.statusbar\_text]: api.html#ui.statusbar_text
[gui.switch\_buffer()]: api.html#ui.switch_buffer
[gui.title]: api.html#ui.title
[\_VIEWS]: api.html#_VIEWS

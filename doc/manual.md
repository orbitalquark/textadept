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
speed or succumbing to code bloat and featuritis. The application has both a
graphical user interface (GUI) version that runs in a desktop environment, and a
terminal version that runs within a terminal emulator.

[Lua]: http://www.lua.org

### Fast

Textadept is _fast_. It starts up instantly and has a very responsive user
interface. Even though the editor consists primarily of Lua code, Lua is one of
the fastest scripting languages available.

### Minimalist

Textadept is minimalist. Not only does its appearance exhibit this, but the
editor's C core is limited to around 2000 lines of code and its Lua extension
code tries to avoid going beyond 4000 lines. After more than 12 years of
development, Textadept contains [roughly the same amount of code][] since its
inception while evolving into a vastly superior editor.

[roughly the same amount of code]: https://foicica.com/stats.html#Textadept

### Remarkably Extensible

Textadept is remarkably extensible. Designed to be that way from the very
beginning, the editor's features came later. Most of Textadept's internals are
written in Lua, from syntax highlighting to opening and saving files to
searching and replacing and more. Textadept gives you nearly complete control
over the entire application using Lua. Everything from moving the caret to
changing menus and key bindings on-the-fly to handling core events is possible.
Its potential is vast.

![Split Views](images/splitviews.png)

## Manual Notation

This manual represents directories and file paths like this: */path/to/dir/* and
*/path/to/file*. (Windows machines use '/' and '\' interchangeably as directory
separators.) Paths that do not begin with '/' or "C:\", are relative to the
location of Textadept. *~/* denotes the user's home directory. On Windows
machines this is the value of the "USERHOME" environment variable, typically
*C:\Users\username\\* or *C:\Documents and Settings\username\\*. On Linux/BSD
and macOS machines it is the value of "$HOME", typically */home/username/* and
*/Users/username/*, respectively.

The manual expresses key bindings like this: `Ctrl+N`. They are not case
sensitive. `Ctrl+N` stands for pressing the "N" key while only holding down the
"Control" modifier key, and not the "Shift" modifier key. `Ctrl+Shift+N` stands
for pressing the "N" key while holding down both the "Control" and "Shift"
modifiers. The same notation applies to key chains like `Ctrl+N, N` and
`Ctrl+N, Shift+N`. The first key chain represents pressing "Control" and "N"
followed immediately by "N" with no modifiers. (The comma serves only for
readability.) The second represents pressing "Control" and "N" followed
immediately by "Shift" and "N".

When mentioning key bindings, the manual often shows the macOS and terminal
version equivalents in parenthesis. It may be tempting to assume that some
Windows/Linux keys map to macOS's (e.g. `Ctrl` to `⌘`) or the terminal's (e.g.
`Ctrl` to `^`), but this is not always the case. In order to minimize confusion,
view key equivalents as separate entities, not as translations of one another.
It is also worth pointing out that for the terminal version, the prefix `M-`
represents the Alt (or Meta) modifier key.

## Manual Terminology

The manual uses the following terminology:

* *buffer*: A buffer is an object that contains editable text. Some other
  applications call this object a document or file.
* *view*: A view is an object that displays a single buffer.
* *caret*: The caret is the visual that represents the text insertion point in a
  a buffer. It is usually a blinking line.

- - -

# Installation

- - -

## Requirements

In its bid for minimalism, Textadept also depends on very little to run. The GUI
version needs only [GTK][], a cross-platform GUI toolkit, version 2.24 or later
(circa early-2011) on Linux and BSD systems. The application already bundles a
GTK runtime into the Windows and macOS packages. The terminal version of
Textadept only depends on a curses implementation like [ncurses][] on Linux,
macOS, and BSD systems. The Windows binary includes a precompiled version of
[pdcurses][] that can run in the Windows command prompt. Textadept also
incorporates its own [copy of Lua](#Lua.Configuration) on all platforms.

[GTK]: http://gtk.org
[ncurses]: http://invisible-island.net/ncurses/ncurses.html
[pdcurses]: http://pdcurses.sourceforge.net

### Requirements for Linux and BSD

Most Linux and BSD systems already have GTK installed. If not, your package
manager probably makes it available. Otherwise, compile and install GTK from the
[GTK website][]. Note: the GUI version of Textadept requires GLib (a dependency
of GTK) version 2.28 or later (circa mid-2011) in order to support
[single-instance](#Single.Instance) functionality.

Most Linux and BSD systems already have a curses implementation like ncurses
installed. If not, look for one in your package manager, or compile and install
ncurses from the [ncurses website][]. Ensure it is the wide-character version of
ncurses, which handles multibyte characters. Debian-based distributions like
Ubuntu typically call the package "libncursesw5" or "libncursesw6".

[GTK website]: http://www.gtk.org/download/linux.php
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Requirements for macOS

No requirements other than Mac OSX 10.6 (Snow Leopard) or higher.

### Requirements for Windows

Windows XP or greater.

## Download

Download Textadept from the project's [download page][] by selecting the
appropriate package for your platform. For the Windows and macOS packages, the
bundled GTK runtime accounts for 1/2 - 3/4 of the download and unpackaged
application sizes. Textadept itself is much smaller.

You also have the option of downloading an officially supported set of extra
support [modules](#Modules) from the download page. Textadept itself already
includes a core set of editing modules as well as C and Lua
[language modules](#Language.Modules).

If necessary, you can obtain PGP signatures from the [download page][] along
with a public key in order to verify download integrity. For example on Linux,
after importing the public key via `gpg --import foicica.pgp` and downloading
the appropriate signature, run `gpg --verify [signature]`.

### Approximate Download and Installation Sizes

Platform | Download Size | Installed Size
---------|---------------|----------------------------------
Linux    | 4 MB          | 11 MB
macOS    | 11 MB         | 35 MB (12 MB without GTK Runtime)
Windows  | 16 MB         | 41 MB (23 MB without GTK Runtime)

[download page]: http://foicica.com/textadept/download

## Installation

Installing Textadept is simple and easy. You do not need administrator
privileges.

### Installing on Linux and BSD

Unpack the archive anywhere.

If you downloaded the extra set of modules, you can either unpack it to where
you unpacked the Textadept archive (thus merging the *modules/* directories), or
you can create a *~/.textadept/* directory (if it does not already exist) and
unpack the modules there (thus creating or merging the *modules/* directory).
The *~/.textadept/* directory, which stores user preferences and user-data, will
be discussed shortly in a later section.

### Installing on macOS

Unpack the archive and move *Textadept.app* to your user or system
*Applications/* directory like any other macOS application. The package
contains an optional *ta* script for launching Textadept from the command line
that you can put in a directory in your "$PATH" (e.g. */usr/local/bin/*).

If you downloaded the extra set of modules, you have two options:

1. Unpack it, right-click *Textadept.app*, select "Show Package Contents",
   navigate to *Contents/Resources/modules/*, and move the unpacked modules
   there.
2. Create a *~/.textadept/* directory (if it does not already exist) and unpack
   the modules there (thus creating or merging the *modules/* directory). The
   *~/.textadept/* directory, which stores user preferences and user-data, will
   be discussed shortly in a later section.

### Installing on Windows

Unpack the archive anywhere.

If you downloaded the extra set of modules, you can either unpack it to where
you unpacked the Textadept archive (thus merging the *modules/* directories), or
you can create a *~/.textadept/* directory (if it does not already exist) and
unpack the modules there (thus creating or merging the *modules/* directory).
The *~/.textadept/* directory, which stores user preferences and user-data, will
be discussed shortly in a later section.

## Running

### Running on Linux and BSD

Run Textadept by invoking the */path/to/textadept_x.x/textadept* executable from
either a run dialog or the terminal. You can also create a symbolic link to that
executable in a directory in your "$PATH" (e.g. */usr/local/bin/*) or make a
GNOME, KDE, XFCE, etc. button or menu launcher.

The *textadept-curses* executable is the terminal version of Textadept. Run it
as you would run the *textadept* executable, but inside a terminal emulator
instead.

#### Runtime Problems

Providing a single binary that runs on all Linux platforms proves challenging,
since the versions of software installed vary widely from distribution to
distribution. Because the Linux version of Textadept uses the versions of GTK
and ncurses installed on your system, an error like:

    error while loading shared libraries: <lib>: cannot open shared object
    file: No such file or directory

may occur when trying to run the program. The solution is actually quite
painless even though it requires [recompiling](#Compiling) Textadept.

### Running on macOS

Run Textadept by double-clicking *Textadept.app*. You can also pin it to your
dock.

#### macOS Environment Variables

By default, macOS GUI apps like Textadept do not see shell environment
variables like "$PATH". Consequently, any [modules](#Modules) that utilize
programs contained in "$PATH" (e.g. the progams in */usr/local/bin/*) will not
find those programs. The solution is to create a *~/.textadept/osx_env.sh* file
that exports all of the environment variables you need Textadept to see. For
example:

    export PATH=$PATH

Textadept will automatically invoke this script when it starts.

### Running on Windows

Run Textadept by double-clicking *textadept.exe*. You can also create shortcuts
to the executable in your Start Menu, Quick Launch toolbar, Desktop, etc.

#### Portable Textadept

You can create a portable version of Textadept by creating a shortcut to the
*textadept.exe* executable with the additional command line arguments
`-u userdata`. *~/.textadept/* will now point to *userdata/* in the directory
where *textadept.exe* is located. The *~/.textadept/* directory, which stores
user preferences and user-data, will be discussed in the next section.

### *~/.textadept*

Textadept stores all of your preferences and user-data in your *~/.textadept/*
directory. If this directory does not exist, Textadept creates it on startup.
This manual gives more information on this folder later.

## Single Instance

Textadept is a single-instance application. This means that after starting
Textadept, running `textadept file.ext` on Linux or BSD (`ta file.ext` on macOS)
from the command line or opening a file with Textadept from a file manager (e.g.
Windows) opens *file.ext* in the original Textadept instance. Passing a `-f` or
`--force` switch to Textadept overrides this behavior and opens the file in a
new instance: `textadept -f file.ext` (`ta -f file.ext`); on Windows, you can
create a separate shortcut to *textadept.exe* that passes the switch. Without
the force switch, the original Textadept instance opens files, regardless of the
number of instances open.

The terminal version of Textadept does not support single instance
functionality.

<span style="display: block; text-align: right; margin-left: -10em;">
![Linux](images/linux.png)
&nbsp;&nbsp;
![macOS](images/macosx.png)
&nbsp;&nbsp;
![Win32](images/win32.png)
&nbsp;&nbsp;
![curses](images/ncurses.png)
</span>

- - -

# User Interface

- - -

![UI](images/ui.png)

Textadept's user interface is sleek and simple. It consists of a menu and tab
bar (GUI version only), editor view, and statusbar. There is also a find &
replace pane and a command entry, but Textadept initially hides them both. This
manual briefly describes these features below, but provides more details later.

## Menu

The completely customizable menu provides access to all of Textadept's features.
Only the GUI version implements it, though. The terminal version furnishes the
[command selection](#Command.Selection) dialog instead. Textadept is very
keyboard-driven and assigns key shortcuts to most menu items. Your
[key preferences](#Key.Bindings) can change these shortcuts and will reflect in
the menu. Here is a [complete list][] of default key bindings.

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
directory of files. The pane is available only when you need it and quickly gets
out of your way when you do not, minimizing distractions.

## Command Entry

The versatile command entry has many different roles. Primarily it is the place
to execute Lua commands and interact with Textadept's internal Lua state. In
another context it executes shell commands. Lua extensions allow it to do even
more. Like the find & replace pane, the command entry pops in and out as you
wish.

## Statusbar

The statusbar actually consists of two statusbars. The one on the left-hand
side displays temporary status messages while the one on the right-hand side
persistently shows status information for the current buffer.

- - -

# Working with Files

- - -

## Buffers

Despite the fact that Textadept can display multiple buffers with a tab bar, the
buffer browser is usually a faster way to switch between buffers or quickly
assess which files are open. Press `Ctrl+B` (`⌘B` on macOS | `M-B` or `M-S-B` in
the terminal) to display this browser.

![Buffer Browser](images/bufferbrowser.png)

The buffer browser displays a list of currently open buffers. By default, the
most recent buffers are towards the bottom of the list. The browser can be
[configured](#Key.Bindings) to list the most recently viewed buffers first.
Typing part of any filename filters the list, with spaces being wildcards. The
arrow keys move the selection up and down. Pressing `Enter`, selecting `OK`, or
double-clicking a buffer in the list switches to the selected buffer.

![Buffer Browser Filtered](images/bufferbrowserfiltered.png)

Textadept shows the name of the active buffer in its titlebar. Pressing
`Ctrl+Tab` (`^⇥` on macOS | `M-N` in the terminal) cycles to the next buffer and
`Ctrl+Shift+Tab` (`^⇧⇥` | `M-P`) cycles to the previous one.

### Typical Buffer Settings

Individual files have many configurable settings. Among the more useful settings
are those involving line endings and their visibility, indentation settings,
file encoding, long line wrapping, and the visibility of whitespace. Line
endings are the characters that separate lines. Indentation consists of an
indentation character (either a tab or a space) and an indentation size. File
encoding specifies how to display text characters. Textadept shows these latter
three settings among the contents of the buffer statusbar.

![Document Statusbar](images/docstatusbar.png)

View settings for line endings, long lines, and whitespace only affect the
_current_ buffer. Changing a setting in one buffer does not change that setting
in any other buffer.

#### Buffer Line Endings

Textadept determines which default line endings, commonly known as end-of-line
(EOL) markers, to use based on the current platform. On Windows it is CRLF
("\r\n"). On all other platforms it is LF ('\n'). Textadept first tries to
auto-detect the EOL mode of opened files before falling back on the platform
default. The "Buffer > EOL Mode" menu manually changes line endings and
automatically converts all existing EOLs.

#### Buffer Indentation

Normally, a [language module](#Language.Modules) or
[your preferences](#Buffer.Settings) dictate a buffer's indentation settings. By
default, indentation is 2 spaces. Pressing `Ctrl+Alt+Shift+T` (`^⇧T` on macOS |
`M-T` or `M-S-T` in the terminal) manually toggles between using tabs and
spaces, although this only affects future indentation. Existing indentation
remains unchanged. `Ctrl+Alt+I` (`^I` | `M-I`) performs the conversion. (If the
buffer uses tabs, all indenting spaces convert to tabs. If the buffer uses
spaces, all indenting tabs convert to spaces.) Similarly, the
"Buffer > Indentation" menu manually sets indentation size.

#### Buffer Encodings

Textadept has the ability to decode files encoded in many different encodings,
but by default it only attempts to decode UTF-8, ASCII, CP-1252, and UTF-16
files. If you work with files that have encodings Textadept does not recognize,
add those encodings to [`io.encodings`][] in your [preferences](#Preferences).

UTF-8 is the recommended file encoding because of its wide support by other text
editors and operating systems. The "Buffer > Encoding" menu changes the file
encoding and performs the conversion. Textadept saves new files as UTF-8 by
default, but does not alter the encoding of existing ones.

[`io.encodings`]: api.html#io.encodings

#### View Line Endings

Normally, EOL characters ("\r" and "\n") are invisible. Pressing
`Ctrl+Alt+Enter` (`^↩` on macOS | none in the terminal) toggles their
visibility.

#### View Long Lines

By default, lines with more characters than the view can show do not wrap into
view. `Ctrl+Alt+\` (`^\` on macOS | none in the terminal) toggles line wrapping.

#### View Whitespace

Normally, whitespace characters (tabs and spaces) are invisible. Pressing
`Ctrl+Alt+Shift+S` (`^⇧S` on macOS | none in the terminal) toggles their
visibility. Visible spaces show up as dots and visible tabs show up as arrows.

### Recent Files

Pressing `Ctrl+Alt+O` (`^⌘O` on macOS | `M-^O` in the terminal) brings up a
dialog that behaves like the buffer browser, but displays a list of recently
opened files to reopen.

### Sessions

By default, Textadept saves its state upon quitting in order to restore it the
next time the editor starts up. Passing the `-n` or `--nosession` switch to
Textadept on startup disables this feature. The "File > Save Session..." and
"File > Load Session..." menus manually save and open sessions while the `-s`
and `--session` switches load a particular session on startup. The switches
accept the path of a session file or the name of a session in *~/.textadept/*.
Session files store information such as open buffers, current split views, caret
and scroll positions in each buffer, Textadept's window size, recently opened
files, and bookmarks.

### Quick Open

A quicker, though slightly more limited alternative to the standard file
selection dialog is Quick Open. It too behaves like the buffer browser, but
displays a list of files to open, including files in sub-directories. Pressing
`Ctrl+Alt+Shift+O` (`^⌘⇧O` on macOS | `M-S-O` in the terminal) quickly opens the
current file's directory, `Ctrl+U` (`⌘U` | `^U`) quickly opens *~/.textadept/*,
and `Ctrl+Alt+Shift+P` (`^⌘⇧P` | `M-^P`) quickly opens the current project
(which must be under version control). Quick Open is pretty limited from the
"Tools > Quick Open" menu, but more versatile in [scripts][].

[scripts]: api.html#io.quick_open

![Quick Open](images/snapopen.png)

## Views

### Split Views

Textadept allows you to split the editor window an unlimited number of times
both horizontally and vertically. `Ctrl+Alt+S` or `Ctrl+Alt+H` splits
horizontally into top and bottom views and `Ctrl+Alt+V` splits vertically (`^S`
and `^V`, respectively on macOS | `M-^V, S` and `M-^V, V` in the terminal) into
side-by-side views. Clicking and dragging on the splitter bar with the mouse or
pressing `Ctrl+Alt++` and `Ctrl+Alt+-` (`^+` and `^-` | `M-^V, +` and `M-^V, -`)
resizes the split. Textadept supports viewing a single buffer in two or more
views.

Pressing `Ctrl+Alt+N` (`^⌥⇥` on macOS | `M-^V, N` in the terminal) jumps to the
next view and `Ctrl+Alt+P` (`^⌥⇧⇥` | `M-^V, P`) jumps the previous one. However,
depending on the split sequence, the order when cycling between views may not be
linear.

In order to unsplit a view, enter the view to keep open and press `Ctrl+Alt+W`
(`^W` on macOS | `M-^V, W` in the terminal). In order to unsplit all views, use
`Ctrl+Alt+Shift+W` (`^⇧W` | `M-^V, S-W`).

Note: The terminal version uses the `M-^V` key prefix for split views.

### View Settings

Individual views can configure the view of indentation guides and adjust the
zoom level. These options change how to display buffers in the _current_ view.
Changing a setting in one view does not immediately change that setting in any
other split view. You must switch to that other view first and apply the same
setting.

#### View Indentation Guides

Views show small guiding lines based on indentation level by default.
`Ctrl+Alt+Shift+I` (`^⇧I` on macOS | N/A in the terminal) toggles the visibility
of these guides.

The terminal version does not support indentation guides.

### Zoom

In order to temporarily increase or decrease the font size in a view, press
`Ctrl+=` (`⌘=` on macOS | N/A in the terminal) and `Ctrl+-` (`⌘-` | N/A)
respectively. `Ctrl+0` (`⌘0` | N/A) resets the zoom.

The terminal version does not support zooming.

- - -

# File Navigation

- - -

## Basic Movements

Textadept implements the customary key bindings for navigating text fields on
the current platform. The arrow keys move the caret in a particular direction,
`Ctrl+Left` and `Ctrl+Right` (`^⇠` and `^⇢` on macOS | `^Left` and `^Right` in
the terminal) move by words, `PgUp` and `PgDn` (`⇞` and `⇟` | `PgUp` and `PgDn`)
move by pages, etc. macOS and the terminal version also handle some Bash-style
key bindings like `^B`, `^F`, `^P`, `^N`, `^A`, and `^E`. The "Movement" section
of the [key bindings list][] lists all movement bindings.

[key bindings list]: api.html#textadept.keys

## Brace Match

By default, Textadept highlights the matching brace characters under the caret:
'(', ')', '[', ']', '{', and '}'. Pressing `Ctrl+M` (`^M` on macOS | `M-M` in
the terminal) moves the caret to the matching brace.

![Matching Braces](images/matchingbrace.png)

## Bookmarks

Textadept supports the bookmarking of buffer lines in order to jump back to them
later. `Ctrl+F2` (`⌘F2` on macOS | `F1` in the terminal) toggles a bookmark on
the current line, `F2` jumps to the next bookmarked line, `Shift+F2` (`⇧F2` |
`F3`) jumps to the previously bookmarked line, `Alt+F2` (`⌥F2` | `F4`) jumps to
the bookmark selected from a list, and `Ctrl+Shift+F2` (`⌘⇧F2` | `F6`) clears
all bookmarks in the current buffer.

## Goto Line

In order to jump to a specific line in a file, press `Ctrl+J` (`⌘J` on macOS |
`^J` in the terminal), specify the line number in the prompt, and press `Enter`
(`↩` | `Enter`) or click `Ok`.

- - -

# Adept Editing

- - -

## Basic Editing

Textadept features many common, basic editing features: inserting text,
undo/redo, manipulating the clipboard, deleting characters and words,
duplicating lines, joining lines, and transposing characters. The top-level
"Edit" menu contains these actions and lists their associated key bindings. This
manual discusses more elaborate editing features below.

### Autopaired Characters

Usually, brace ('(', '[', '{') and quote ('&apos;', '&quot;') characters go
together in pairs. Textadept automatically inserts the complement character of
any user-typed opening brace or quote character and allows the user to
subsequently type over it. Similarly, the editor deletes the complement when
you press `Bksp` (`⌫` on macOS | `Bksp` in the terminal) over the typed one. The
[module preferences](#Module.Preferences) section details how to configure or
disable these features.

### Word Completion

Textadept provides buffer-based word completion. Start typing a word and press
`Ctrl+Enter` (`^Esc` on macOS | `M-Enter` in the terminal) to display a list of
suggested completions based on words in the current buffer (you can configure
this feature to suggest completions based on words from all open buffers).
Continuing to type changes the suggestion. Press `Enter` (`↩` | `Enter`) to
complete the selected word.

![Word Completion](images/wordcompletion.png)

### Virtual Space Mode

Pressing `Ctrl+Alt+Shift+V` (`^⇧V` in macOS | none in the terminal) enables and
disables Virtual space (freehand) mode. When virtual space is enabled, the caret
may move into the space past the ends of lines.

### Overwrite Mode

Enable and disable overwrite mode with the `Insert` key. When enabled, typing
overwrites existing characters in the buffer rather than inserting the typed
characters. In the GUI version of Textadept, the caret also changes to an
underline in overwrite mode.

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
Holding `Alt+Shift` (`⌥⇧` on macOS | `M-S-` in the terminal) and then pressing
the arrow keys creates a rectangular selection. Holding the `Alt` modifier key
and then clicking and dragging the mouse cursor also creates a rectangular
selection.

![Rectangular Selection](images/rectangularselection.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Rectangular Edit](images/rectangularselection2.png)

Note: In some Linux environments, the window manager consumes `Alt+Shift+Arrow`
combinations, so Textadept's keys may need reconfiguring. Similarly, the window
manager may also consume `Alt+Mouse` in order to move windows. In that case, a
normal text selection may be changed into a rectangular selection by tapping the
`Alt` modifier key.

### Select between Matching Braces and Other Entities

Placing the caret over a brace character ('(', ')', '[', ']', '{', or '}') or
between matching pairs and then pressing `Ctrl+Shift+M` (`^⇧M` on macOS |
`M-S-M` in the terminal) selects all text between the pair. Repeated use of this
key binding toggles the selection of the brace characters themselves. You can
also use this feature within other entities like single and double quotes.

The "Edit > Select In..." menu lists other selectable entities like HTML/XML
tags.

### Marks

In the terminal version, since some terminals do not recognize certain key
combinations like `Shift+Arrow` for making selections, marks can create
selections. Create a mark at the current caret position with `^^`. Then use
regular movement keys like the arrows, page up/down, and home/end to extend the
selection in one direction. Pressing `^]` swaps the current caret position with
the original mark position in order to extend the selection in the opposite
direction. Typing text, deleting text, or running a command that does either,
removes the mark and restores ordinary navigation. Pressing `^^` again also
stops selecting text.

Only the terminal version natively supports marks.

### Transforms

#### Enclose Entities

As a complement to selecting entities, Textadept allows the enclosure of text in
entities. The "Edit > Selection > Enclose In..." menu lists all enclosing
entities with their key bindings. Each action encloses either the currently
selected text or the word to the left of the caret. For example, pressing
`Alt+<` (`^<` on macOS | `M->` in the terminal) at the end of a word encloses it
in XML tags.

#### Change Case

Pressing `Ctrl+Alt+U` or `Ctrl+Alt+Shift+U` (`^U` or `^⇧U` on macOS | `M-^U`
or `M-^L` in the terminal) converts selected text to upper case letters or lower
case letters, respectively.

#### Change Indent Level

Increase the amount of indentation for a selected set of lines by pressing `Tab`
(`⇥` on macOS | `Tab` in the terminal). `Shift+Tab` (`⇧⇥` | `S-Tab`) decreases
it. You do not have to select whole lines. Selecting any part of a line renders
the entire line eligible for indenting/dedenting. Using these key sequences when
no selection is present does not have the same effect.

#### Move Lines

Move selected lines up and down with the `Ctrl+Shift+Up` and `Ctrl+Shift+Down`
(`^⇧⇡` and `^⇧⇣` on macOS | `S-^Up` and `S-^Down` in the terminal) keys,
respectively. Like with changing indent level, selecting any part of a line
renders the entire line eligible for moving.

## Find & Replace

`Ctrl+F` (`⌘F` on macOS | `M-F` or `M-S-F` in the terminal) brings up the Find &
Replace pane. It has the usual find and replace functionality along with with
"Match Case", "Whole Word", and "[Regex](#Regular.Expressions)" options, coupled
with find/replace history. Textadept highlights all instances of found text in
the current buffer.

Note the `Ctrl+G`, `Ctrl+Shift+G`, `Ctrl+Alt+R`, `Ctrl+Alt+Shift+R` key bindings
for find next, find previous, replace, and replace all (`⌘G`, `⌘⇧G`, `^R`, and
`^⇧R`, respectively on macOS | `M-G`, `M-S-G`, `M-R`, `M-S-R` in the terminal)
only work after hiding the Find & Replace pane. For at least the English locale
in the GUI version, use the button mnemonics: `Alt+N`, `Alt+P`, `Alt+R`, and
`Alt+A` (`⌘N`, `⌘P`, `⌘R`, `⌘A` | N/A) after bringing up the pane.

In the terminal version, `Tab` toggles between the find next, find previous,
replace, and replace all buttons; `Up` and `Down` arrows switch between the find
and replace text fields; `^P` and `^N` cycles through history; and `F1-F4`
toggles find options.

Pressing `Esc` (`Esc` | `Esc`) hides the pane after you finish with it.

### Replace in Selection

By default, "Replace All" replaces all text in the buffer. Selecting a
contiguous block of text and then performing "Replace All" replaces all text in
the selection. "Replace All" within rectangular or multiple selections is
currently not supported.

### Find in Files

`Ctrl+Shift+F` brings up Find in Files (`⌘⇧F` on macOS | none in the terminal)
and prompts for a directory to search. The "Replace" entry has been substituted
for a "Filter" entry that contains files and directories to include or exclude
from the search. A new buffer lists the search results. Double-clicking a search
result jumps to it in the file, as do the the `Ctrl+Alt+G` and
`Ctrl+Alt+Shift+G` (`^⌘G` and `^⌘⇧G` | none) key bindings for cycling through
results.

A filter consists of a comma-separated list of [Lua patterns](#Lua.Patterns)
that match filenames and directories to include or exclude. Patterns are
inclusive by default. Exclusive patterns begin with a '!'. If no inclusive
patterns are given, any filename is initially considered. As a convenience,
file extensions can be specified literally instead of as a Lua pattern (e.g.
'.lua' vs. '%.lua$'), and '/' also matches the Windows directory separator
('[/\\]' is not needed). The default filter excludes many common binary files
and version control folders from searches. Textadept keeps track of
per-directory filters. The [find API][] also allows per-directory filters to be
configured.

Textadept does not support replacing in files directly. You must "Find in Files"
first, and then "Replace All" for each file containing a result. The
"Match Case", "Whole Word", and "Regex" flags still apply.

![Find in Files](images/findinfiles.png)

[find API]: api.html#ui.find.find_in_files_filters

### Incremental Find

Start an incremental search by pressing `Ctrl+Alt+F` (`^⌘F` on macOS | `M-^F`
in the terminal). Incremental search searches the buffer as you type.

## Source Code Editing

Being a programmer's editor, Textadept excels at editing source code. It
understands the syntax and structure of more than 100 different programming
languages and recognizes hundreds of file types. Textadept uses this knowledge
to make viewing and editing code faster and easier. It can also compile and run
simple source files.

### Lexers

Upon opening a file, Textadept attempts to identify the programming language
associated with it and assign a "lexer" to highlight syntactic elements of the
code. Pressing `Ctrl+Shift+L` (`⌘⇧L` on macOS | `M-S-L` in the terminal) and
selecting a lexer from the list manually sets the lexer instead. Your
[file type preferences](#File.Types) customize how Textadept recognizes files.

### Code Folding

Some lexers support "code folding", the act of temporarily hiding blocks of code
in order to make viewing easier. Markers in the margin to the left of the code
denote fold points. Clicking on one toggles the folding for that block of code.
Pressing `Ctrl+*` (`⌘*` on macOS | `M-*` in the terminal) also toggles the fold
point on the current line.

![Folding](images/folding.png)

### Word Highlight

Textadept can be configured to [automatically highlight][] all occurrences of
the word under the caret, or all occurrences of the selected word (e.g. a
variable name). Pressing `Esc` clears highlighting.

![Word Highlight](images/wordhighlight.png)

[automatically highlight]: api.html#textadept.editing.highlight_words

### Autocompletion and Documentation

Textadept has the capability to autocomplete symbols for programming languages
and display API documentation for functions and other symbols. Pressing
`Ctrl+Space` (`⌥Esc` on macOS | `^Space` in the terminal) completes the current
symbol and `Ctrl+H` (`^H` | `M-H` or `M-S-H`) shows any known documentation on
the current symbol. Note: In order for these features to work, the language you
are working with must have an [autocompleter][] and [API file(s)][],
respectively. [Language modules](#Language.Modules) usually [define these][].
Most of the [official][] Textadept language modules support autocompletion and
documentation.

![Autocomplete Lua](images/adeptsense_lua.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Autocomplete Lua String](images/adeptsense_string.png)

![Documentation](images/adeptsense_doc.png)

[autocompleter]: api.html#textadept.editing.autocompleters
[API file(s)]: api.html#textadept.editing.api_files
[define these]: api.html#_M.Autocompletion.and.Documentation
[official]: http://foicica.com/hg/textadept_modules

### Snippets

Snippets are essentially pieces of text inserted into source code or plain text.
However, snippets are not limited to being static text. They can be dynamic
templates which contain placeholders for further user input, can mirror or
transform those user inputs, and can execute arbitrary code. Snippets are useful
for rapidly constructing blocks of code such as control structures, method
calls, and function declarations. Press `Ctrl+Shift+K` (`⌥⇧⇥` on macOS | `M-S-K`
in the terminal) for a list of available snippets. A snippet consists of a
trigger word and snippet text. Instead of manually selecting a snippet to
insert, type its trigger word followed by the `Tab` (`⇥` | `Tab`) key.
Subsequent presses of `Tab` (`⇥` | `Tab`) move the caret into placeholders in
sequential order, `Shift+Tab` (`⇧⇥` | `S-Tab`) goes back to the previous
placeholder, and `Esc` cancels the current snippet. Textadept supports nested
snippets, snippets inserted from within another snippet. Language modules
usually define their [own set][] of snippets, but your
[snippet preferences](#Snippet.Preferences) can define some too.

![Snippet](images/snippet.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Snippet Expanded](images/snippet2.png)

[own set]: api.html#_M.Snippets

### Toggle Comments

Pressing `Ctrl+/` (`⌘/` on macOS | `M-/` in the terminal) comments or uncomments
the code on the selected lines. Selecting any part of a line renders the entire
line eligible for commenting or uncommenting.

### Compile, Run, and Build

Textadept knows most of the commands that compile and/or run code in source
files. It can also sometimes detect your project's build file and run that.
Pressing `Ctrl+Shift+R` (`⌘⇧R` on macOS | `M-^R` in the terminal) executes the
command for compiling code in the current file, `Ctrl+R` (`⌘R` | `^R`) executes
the command for running code, and `Ctrl+Shift+B` (`⌘⇧B` on macOS | `M-^B` in
the terminal) executes the command for building a project. `Ctrl+Shift+X`
(`⌘⇧X` | `M-^X`) stops the currently running process. A new buffer shows the
output from a compile, run, or build command and marks any recognized warnings
and errors. Pressing `Ctrl+Alt+E` (`^⌘E` | `M-X`) attempts to jump to the source
of the next recognized warning or error and `Ctrl+Alt+Shift+E` (`^⌘⇧E` |
`M-S-X`) attempts to jump to the previous one. Double-clicking on warnings and
errors also jumps to their sources. If Textadept does not know the correct
commands for compiling and/or running your language's source code, if it does
not know how to build your project, or if it does not detect warning or error
messages properly, you can make changes in your
[preferences](#Module.Preferences).

![Runtime Error](images/runerror.png)

[make changes]: api.html#_M.Compile.and.Run

- - -

# Modules

- - -

Modules are small packages of Lua code that provide functionality for Textadept.
Textadept can load modules when the application starts up, or it can load
modules on-demand in response to a particular event. Most of Textadept's
functionality comes from modules loaded on startup. An example is the
[textadept module][] which implements most of Textadept's functionality (find &
replace, key bindings, menus, snippets, etc.) You can add additional features
and functionality to Textadept by using custom modules.

Modules follow the Lua package model: a module is either a single Lua file or a
group of Lua files in a directory that has an *init.lua* file as the module's
entry point. For more information on modules, please see the
[Lua documentation][]. (Note that while that resource is a bit outdated, it is
still largely relevant when it comes to Lua modules.) Textadept also ships with
a few modules in its *modules/* directory for reference, and the optional set
of officially supported modules contains more examples.

With one exception, Textadept will not automatically load a given module. You
must explicitly tell Textadept what modules to load and when to do so. The
[loading modules](#Loading.Modules) section describes how to load modules on
startup and how to load them on-demand in response to events.

[textadept module]: api.html#textadept
[Lua documentation]: https://www.lua.org/pil/15.html

## Language Modules

The only kind of modules Textadept will load automatically are called language
modules. Despite this distinction, they are still just plain Lua modules -- the
only thing special about them is that a language module's name matches the
language's lexer name in Textadept's *lexers/* directory. (For example, the Lua
language module has the name "lua", and the C language module has the name
"ansi\_c".)

A language module is designed to provide extra functionality for a single
programming language (in addition to the source code editing features discussed
previously), and Textadept only loads such a module when it opens an applicable
source file for the first time. (Thereafter the module remains loaded in
memory.)

While the scope of a language module is not defined, many language modules
specify custom indentation rules (e.g. 4 spaces per indent in Python per PEP 8),
code autocompletion routines, snippets, and custom commands. See the
[language module API documentation][] for more ideas on what features language
modules can provide.

[language module API documentation]: api.html#_M

## Getting Modules

Textadept has a set of officially supported modules (including language modules)
available as a separate download from the Textadept downloads page. The source
code for those modules is hosted [here][].

For now, the [wiki][] hosts third-party, user-created modules.

[here]: http://foicica.com/hg/textadept_modules
[wiki]: http://foicica.com/wiki/textadept

## Installing Modules

Install a module by placing it in your *~/.textadept/modules/* directory. Even
if you have write permissions in Textadept's installed location, placing all of
your custom or user-created modules in *~/.textadept/modules/* prevents the
possibility of overwriting them when you update Textadept. Also, modules in that
directory override any modules in Textadept's *modules/* directory. This means
that if, for example, you have your own *lua* module, Textadept will load that
one instead of its own when a Lua source file is opened.

## Developing Modules

As mentioned previously, modules can be a single Lua file or a group of files in
a directory headed by an *init.lua* file. The name of a module is based on its
filename or directory name, not its contents.

Here are some basic guidelines for developing modules and some things to keep in
mind:

* For modules that define functions or fields, return a table of those functions
  and fields (which should be defined local to the module), rather than defining
  them globally. (This is standard Lua practice.) That way the construct
  `foo = require('foo')` behaves as expected.
* Try not to define global variables. Loaded modules, even language modules,
  persist in Textadept's Lua state; Textadept never unloads them. You do not
  want to pollute the global namespace or cause unintended conflicts with other
  modules.
* Be aware of the programming languages Textadept supports and do not use any
  module names that match the name of a lexer in the *lexers/* directory unless
  you are creating a language module.
* Do not call any functions that create buffers and views (e.g. `ui.print()`,
  `io.open_file()`, and `buffer.new()`) at file-level scope. Those types of
  function calls must occur within functions (e.g. in a key binding, menu item,
  or [`events.INITIALIZED`][] event handler).
* Additional documentation on creating language modules can be found in the
  the [language module API documentation][].

[`events.INITIALIZED`]: api.html#events.INITIALIZED
[language module API documentation]: api.html#_M

- - -

# Preferences

- - -

Textadept provides a wealth of customization options and extension points. The
two main extension points are when Textadept starts up and when Textadept loads
a file for editing. By now, this manual assumes you are at least familiar with
the basics of [Lua][], but you do not have to know a lot of the language in
order to configure Textadept. The excerpt from [Lua Quick Reference][] may be of
help.

[Lua]: http://www.lua.org
[Lua Quick Reference]: https://foicica.com/lua/

## User Init

Textadept executes a *~/.textadept/init.lua*, your user-init file, on startup.
If this file does not exist, Textadept creates it for you. This file allows you
to write arbitrary Lua code that instructs Textadept what to do when the
application starts. This includes (but is not limited to) changing editor
preferences, changing the settings of existing modules, loading new modules,
modifying key bindings, adding snippets, editing file associations, adding menu
items, and changing the theme. This manual discusses these specific
customizations, minus theming, in the sections below. Theming is covered in a
later section.

Note: Do not call any functions that create buffers and views (e.g.
`ui.print()`, `io.open_file()`, and `buffer.new()`) at the file-level scope of
*~/.textadept/init.lua*. Those types of function calls must occur within
functions (e.g. in a key binding, menu item, or [`events.INITIALIZED`][] event
handler).

[`events.INITIALIZED`]: api.html#events.INITIALIZED

### Editor Preferences

Editor preferences are stored in [`buffer`][] and [`view`][] objects. Normally,
each buffer and view can have its own individual preferences, but on startup,
any preferences set apply to all subsequent buffers and views. For example, in
order to override a setting like Textadept's default indentation setting of 2
spaces per indent, add the following to your *~/.textadept/init.lua*:

    buffer.use_tabs = true
    buffer.tab_width = 4

(If you want to define per-language editor preferences, use the technique shown
in the [Language Preferences](#Language.Preferences) section below.)

Textadept's own *init.lua* contains the application's default editor settings
(like 2 space indentation). This file is a good "quick reference" for
configurable editor settings. It also has many commented out settings that
you can copy to your *~/.textadept/init.lua* and uncomment in order to turn on
(or change the value of before turning on). You can view a settings's
documentation by pressing `Ctrl+H` (`^H` on macOS | `M-H` or `M-S-H` in the
terminal) or by reading the [buffer API documentation][] and
[view API documentation][].

[`buffer`]: api.html#buffer
[`view`]: api.html#view
[buffer API documentation]: api.html#buffer
[view API documentation]: api.html#view

### Module Preferences

Many of Textadept's default modules come with configurable settings that can be
changed from your *~/.textadept/init.lua* (which is executed after those modules
are loaded). Each module's [API documentation][] lists any configurable settings
it has. For example, in order to always hide the tab bar, stop automatically
highlighting all instances of selected words, disable character autopairing with
typeover, strip trailing whitespace on save, and use C99-style line comments in
C code, add the following to *~/.textadept/init.lua*:

    ui.tabs = false
    ui.highlight_words = false
    textadept.editing.auto_pairs = nil
    textadept.editing.typeover_chars = nil
    textadept.editing.strip_trailing_spaces = true
    textadept.editing.comment_string.ansi_c = '//'

As another example, if Textadept's compile and run commands for a particular
language are not working for you, you can use *~/.textadept/init.lua* to
reconfigure them:

    textadept.run.run_commands.lua = 'lua5.3 "%f"'
    textadept.run.run_commands.python = 'python3 "%f"'

Note: you can also place these settings in an appropriate language module.

Finally, if Textadept does not know how to build your project (which must be
under version control in order to be recognized as one), you can tell it how to
do so:

    textadept.run.build_commands['/path/to/project'] = 'shell command'

**Tip:** You can quickly view the documentation for the setting under the caret
by pressing `Ctrl+H` (`^H` on macOS | `M-H` or `M-S-H` in the terminal). This
applies to pretty much any Lua identifier, not just settings.

[API documentation]: api.html

### Language Preferences

Normally, language modules handle per-language preferences such as
language-specific indentation settings. However, if you do not have a
language module installed for a particular programming language (and you do not
want to bother creating one for it), you can still configure Textadept on a
per-language basis by connecting to the [`events.LEXER_LOADED`][] event, which
Textadept emits every time it opens a source file. For example, in order to
ensure your Ruby code always uses 2 spaces for indentation (regardless of what
your default indentation settings are), add the following to your
*~/.textadept/init.lua*:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= 'ruby' then return end
      buffer.use_tabs = false
      buffer.tab_width = 2
    end)

Perhaps you want to auto-pair and brace-match '<' and '>' characters, but only
in HTML and XML files. In order to accomplish this, add the following:

    events.connect(events.LEXER_LOADED, function(name)
      local is_markup = name == 'html' or name == 'xml'
      textadept.editing.auto_pairs[string.byte('<')] = is_markup and '>'
      textadept.editing.brace_matches[string.byte('<')] = is_markup
      textadept.editing.brace_matches[string.byte('>')] = is_markup
    end)

Finally, suppose you have a language module that has a configurable setting that
you want to change without editing the module itself. (This is good practice.)
Since that module is not available at startup, but only once an applicable
source file is loaded, you would use this:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= '...' then return end
      _M[name].setting = 'custom setting'
    end)

[`events.LEXER_LOADED`]: api.html#events.LEXER_LOADED

### Loading Modules

Use Lua's `require()` function from your *~/.textadept/init.lua* in order to
load non-language modules on startup. For example, after creating or downloading
a module called `foo`, you would tell Textadept to load it like this:

    local foo = require('foo')

As for loading language modules, recall that Textadept automatically loads them
when opening a source file of that language, so simply installing the language
module is sufficient. Nothing needs to be added to *~/.textadept/init.lua*. If
on the other hand you wanted to extend an existing language module with a
"sub-module" (i.e. just another Lua file with language-specific functionality),
create the *~/.textadept/modules/*lang*/* directory if it does not already
exist, place your extension script in that folder, and then `require()` it from
an `events.LEXER_LOADED` event. For example, if you wanted to extend Textadept's
Lua module with an *extras.lua* module, add the following to
*~/.textadept/init.lua*:

    events.connect(events.LEXER_LOADED, function(name)
      if name == 'lua' then require('lua.extras') end
    end)


Note that Lua's `require()` function will not run code in *extras.lua* more than
once.

### Key Bindings

Textadept provides key bindings for a vast majority of its features. If you
would like to add, tweak, or remove key bindings, you can do so from your
*~/.textadept/init.lua*. For example, maybe you prefer that `Ctrl+Shift+C`
creates a new buffer instead of `Ctrl+N`, or that the buffer list (`Ctrl+B`)
shows buffers by their z-order (most recently viewed to least recently viewed)
instead of the order they were opened in:

    keys['ctrl+C'] = buffer.new
    keys['ctrl+n'] = nil
    keys['ctrl+b'] = function() ui.switch_buffer(true) end

A key binding is simply a Lua function assigned to a key sequence in the global
`keys` table. Key sequences are composed of an ordered combination of modifier
keys followed by either the key's *inserted character*, or if no such character
exists, the string representation of the key. On Windows and Linux, modifier
keys are "Control", "Alt", and "Shift", represented by `ctrl`, `alt`, and
`shift`, respectively. On macOS, modifier keys are "Control", "Alt/Option",
"Command", and "Shift", represented by `ctrl`, `alt`, `cmd`, and `shift`,
respectively. In the terminal version, modifier keys are "Control", "Alt", and
"Shift", represented by `ctrl`, `meta`, and `shift`, respectively.

Key bindings can also be language-specific by storing them in a
`keys[`*lexer*`]` table. If you wanted to add or modify language-specific key
bindings outside of a language module, you would add something like this to
*~/.textadept/init.lua*:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= '...' then return end
      if not keys[name] then keys[name] = {} end
      keys[name]['ctrl+n'] = function() ... end
    end)

If you plan on redefining most key bindings (e.g. in order to mimic an editor
whose bindings you are used to), copy Textadept's *modules/textadept/keys.lua*
(or create a new *keys.lua* from scratch) and put it in your
*~/.textadept/modules/textadept/* directory. That way, Textadept loads your
set instead of its own.

Textadept also allows you to define key modes (e.g. for Vim-style modal editing)
and key chains (e.g. Emacs `C-x` prefix). Learn more about key bindings and how
to define them in the [key bindings documentation][].

[key bindings documentation]: api.html#keys

### Snippet Preferences

You may define snippets in your *~/.textadept/init.lua*, just like key bindings,
via a global `snippets` table:

    snippets['file'] = '%<buffer.filename>'
    snippets['dir'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"
    events.connect(events.LEXER_LOADED, function(name)
      if name ~= '...' then return end
      snippets[name]['trigger'] = 'snippet text'
    end)

You may also have a directory of snippet files where each file is its own
snippet: filenames emulate the keys in the `snippets` table and file contents
are the snippet text. Adding such snippet directories looks like this:

    textadept.snippets.paths[#textadept.snippets.paths + 1] = '/path/to/dir'

Learn more about snippets, snippet syntax, and snippet files in the
[snippets documentation][].

[snippets documentation]: api.html#textadept.snippets

### File Types

Textadept recognizes a wide range of programming language files either by file
extension or by a [Lua pattern](#Lua.Patterns) that matches the text of the
file's first line. The editor does this by consulting a set of tables in
[`textadept.file_types`][], which you can edit using your
*~/.textadept/init.lua*. For example:

    -- Recognize .luadoc files as Lua code.
    textadept.file_types.extensions.luadoc = 'lua'
    -- Change .html files to be recognized as XML files.
    textadept.file_types.extensions.html = 'xml'
    -- Recognize a shebang line like "#!/usr/bin/zsh" as shell code.
    textadept.file_types.patterns['^#!.+/zsh'] = 'bash'

[`textadept.file_types`]: api.html#textadept.file_types

### Menu Options

Textadept allows you to extend its menus with your own sub-menus and menu items.
Menu items are associated with Lua functions such that when a menu item is
selected, its Lua function is executed. For example, in order to append a menu
item to the "Tools" menu and to the right-click context menu, add the following
to your *~/.textadept/init.lua*:

    local tools = textadept.menu.menubar[_L['Tools']]
    tools[#tools + 1] = {'Extra Tool', function() ... end}
    local context_menu = textadept.menu.context_menu
    context_menu[#context_menu + 1] = tools[#tools]

Learn more about menus and how to customize them in the [menu documentation][].

[menu documentation]: api.html#textadept.menu

## Locale Preference

Textadept attempts to auto-detect your locale settings using the "$LANG"
environment variable, falling back on the English locale. In order to manually
set the locale, copy the desired locale file from the *core/locales/* folder to
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

Each theme is a single Lua file. It contains [color][] and [style][] definitions
for displaying syntactic elements like comments, strings, and keywords in
programming language source files. These definitions apply universally to all
programming language elements, resulting in a single, unified theme. Themes also
set view-related editor properties like caret and selection colors.

Note: The only colors that the terminal version of Textadept recognizes are the
standard black, red, green, yellow, blue, magenta, cyan, white, and bold
variants of those colors. Your terminal emulator's settings determine how to
display these standard colors (which may be completely different in the end).

[color]: api.html#lexer.colors
[style]: api.html#lexer.styles

## Setting Themes

Override the default theme in your [*~/.textadept/init.lua*](#User.Init) using
the [`view.set_theme()`][] function. For example:

    view:set_theme(not CURSES and 'dark' or 'term')

Either restart Textadept for changes to take effect or type [`reset`][] in the
[command entry](#Lua.Command.Entry).

`view.set_theme()` can also tweak theme options like font face and font size
without editing the theme file itself:

    view:set_theme('light', {font = 'Monospace', size = 12})

You can even tweak themes on a per-language basis. For example, in order to
color Java functions black instead of the default orange, add the following to
*~/.textadept/init.lua*:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= 'java' then return end
      local default_fore = view.style_fore[view.STYLE_DEFAULT]
      view.style_fore[buffer:style_of_name('function')] = default_fore
    end)

For a full list of configurable properties and styles, please consult the theme
file you are using.

[`view.set_theme()`]: api.html#view.set_theme
[`reset`]: api.html#reset

## Creating Themes

Creating themes is straightforward. Simply define a set of colors and a set of
styles. Just follow the example of existing themes. Place your themes in your
*~/.textadept/themes/* directory so they are not overwritten whenever you
upgrade Textadept. This applies to downloaded themes too.

## GUI Theme

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK Resource files][]. The "GtkWindow" name is
"textadept". For example, style all text fields with a "textadept-entry-style"
like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK Resource files]: https://developer.gnome.org/gtk2/stable/gtk2-Resource-Files.html

## Getting Themes

For now, the [wiki][] hosts third-party, user-created themes.

[wiki]: http://foicica.com/wiki/textadept

- - -

# Advanced

- - -

## Lua Command Entry

The command entry grants access to Textadept's Lua state. Press `Ctrl+E` (`⌘E`
on macOS | `M-C` in the terminal) to display the entry. It is useful for
entering quick commands (e.g. `buffer`, `view`, or `ui` commands). If you try
to cause instability in Textadept's Lua state, you will probably succeed, so be
careful. The [Lua API][] lists available commands. In addition to behaving like
Lua's interactive prompt, the command entry provides some shortcuts for common
[`buffer`][], [`view`][] and [`ui`][] commands. For example, instead of entering
`buffer:append_text('foo')`, you can use `append_text('foo')`. Also, function
call parentheses can be omitted. For example, instead of `view:split()`, you can
simply use `split`. Finally, these commands can be run on startup using the `-e`
and `--execute` command line switches.

Pressing `Ctrl+H` (`^H` on macOS | `M-H` or `M-S-H` in the terminal) shows help
for the current command. Pressing `Up` or `Down` cycles through command history.

![Command Entry](images/commandentry.png)

[Lua API]: api.html
[`buffer`]: api.html#buffer
[`view`]: api.html#view
[`ui`]: api.html#ui
[`ui.print()`]: api.html#ui.print

### Command Entry Tab Completion

The command entry also provides tab-completion for functions, variables, tables,
etc. Press the `Tab` (`⇥` on macOS | `Tab` in the terminal) key to display a
list of available completions. Use the arrow keys to make a selection and press
`Enter` (`↩` | `Enter`) to insert it.

![Command Completion](images/commandentrycompletion.png)

### Extending the Command Entry

Executing Lua commands is just one of the many "modes" the command entry has.
The [command entry API documentation][] has more information on modes and how to
create new ones. Each mode has its own history that can be cycled through using
the `Up` or `Down` keys.

[command entry API documentation]: api.html#ui.command_entry

## Command Selection

Pressing `Ctrl+Shift+E` (`⌘⇧E` on macOS | `M-S-C` in the terminal) brings up the
command selection dialog. Typing part of any command filters the list, with
spaces being wildcards. This is an easy way to run commands without navigating
the menus, using the mouse, or remembering key bindings. It is also useful for
looking up particular key bindings quickly.

## Shell Commands and Filtering Text

Sometimes using an existing shell command to manipulate text is easier than
using the command entry. An example would be sorting all text in a buffer (or a
selection). One way to do this from the command entry is:

    ls={}; for l in get_text():gmatch('[^\n]+') do ls[#ls+1]=l end;
    table.sort(ls); set_text(table.concat(ls, '\n'))

A simpler way is pressing `Ctrl+|` (`⌘|` on macOS | `^\` in the terminal),
entering the shell command `sort`, and pressing `Enter` (`↩` | `Enter`).

This feature determines the standard input (stdin) for shell commands as
follows:

* If text is selected and spans multiple lines, all text on the lines that have
  have text selected is passed as stdin. However, if the end of the selection is
  at the beginning of a line, only the line ending delimiters from the previous
  line are included. The rest of the line is excluded.
* If text is selected and spans a single line, only the selected text is used.
* If no text is selected, the entire buffer is used.

The standard output (stdout) of the command replaces the input text.

## Macros

While Textadept can be completely scripted with Lua, it is sometimes desirable
to quickly record a series of edits and play them back without writing a custom
script. Pressing `F9` starts a recording session, and `Shift+F9` (`⇧F9` on
macOS | `F10` in the terminal) stops recording. `Alt+F9` (`⌥F9` | `F12`) plays
back the most recently recorded macro. You can use the "Tools > Macros" menu to
save a macro to a file, or load one for subsequent playback.

## Remote Control

Since Textadept executes arbitrary Lua code passed via the `-e` and `--execute`
command line switches, a side-effect of [single instance](#Single.Instance)
functionality on the platforms that support it is that you can remotely control
the original instance. For example:

    ta ~/.textadept/init.lua &
    ta -e "events.emit(events.FIND, 'require')"

This will search for the first instance of the word "require" in the current
file using the find & replace pane.

- - -

# Scripting

- - -

Since Textadept is almost entirely scriptable with Lua, the editor has superb
support for editing Lua code. Textadept provides syntax autocompletion and
documentation for the Lua and Textadept APIs.

![ta Autocompletion](images/adeptsense_ta.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![ta Documentation](images/adeptsense_tadoc.png)

## LuaDoc and Examples

Textadept's API is heavily documented. The [API documentation][] is the ultimate
resource on scripting Textadept. There are of course abundant scripting examples
since the editor's internals consist primarily of Lua.

[API documentation]: api.html

### Getting Started

When it comes to scripting Textadept, what exactly does that mean? Being an
event-driven application, Textadept simply responds to input like keypresses and
mouse clicks. By responding, Textadept just executes Lua functions. For example,
pressing `Ctrl+O` (`⌘O` on macOS | `M-O` in the terminal) executes the
[`io.open_file()`][] function because a default keybinding in
*modules/textadept/keys.lua* says so (you could change this in your
[preferences](#Key.Bindings)). Subsequently, when Textadept opens a file, a
syntax highlighting lexer is applied because `io.open_file()` emitted a
[`events.FILE_OPENED`][] event that *modules/textadept/file_types.lua* was
listening for.

Not only can you define your own key bindings that can do pretty much anything
with Textadept (interact with and manipulate buffer contents, prompt for input
with dialogs, spawn processes, etc.), but you can also listen in on the plethora
of [events][] Textadept emits in order to script nearly every aspect of the
editor's behavior. Would you rather have the "Search > Find" menu option (or
key binding) start a search with the word under the caret already in the find &
replace pane's search box? Create a Lua function that populates
[`ui.find.find_entry_text`][] and [shows the pane][], and then re-assign the
"Search > Find" [menu action][]'s existing function to the one you just
created. Would you like to have Textadept auto-save files as you switch between
buffers? Connect [`buffer.save`][] function to the
[`events.BUFFER_BEFORE_SWITCH`][] event. Would you like the ability to execute
arbitrary code in order to transform replacement text while performing find &
replace? Textadept emits an [`events.REPLACE`][] event every time the "Replace"
button is clicked. You can listen for that event and perform your own
replacements. "Textadept gives you complete control over nearly the entire
application using Lua" is not an exaggeration!

[`io.open_file()`]: api.html#io.open_file
[`events.FILE_OPENED`]: api.html#events.FILE_OPENED
[events]: api.html#events
[`ui.find.find_entry_text`]: api.html#ui.find.find_entry_text
[`buffer.save`]: api.html#buffer.save
[`events.BUFFER_BEFORE_SWITCH`]: api.html#events.BUFFER_BEFORE_SWITCH
[`events.REPLACE`]: api.html#events.REPLACE
[shows the pane]: api.html#ui.find.focus
[menu action]: api.html#textadept.menu.menubar

### Generating Autocompletions and Documentation

Generate Lua
[autocompletion and documentation](#Autocompletion.and.Documentation) files for
your own modules using the *modules/lua/tadoc.lua* [LuaDoc][] module:

    luadoc -d [output_path] --doclet _HOME/modules/lua/tadoc.lua [module(s)]

where `_HOME` is the path where you installed Textadept and `output_path` is
an arbitrary path to write the generated *tags* and *api* files to. You can then
use your *~/.textadept/init.lua* file to load those completions and API docs for
use within Textadept when editing [Lua files][]:

    events.connect(events.LEXER_LOADED, function(name)
      if name ~= 'lua' then return end
      _M.lua.tags[#_M.lua.tags + 1] = '/path/to/tags'
      table.insert(textadept.editing.api_files.lua, '/path/to/api')
    end)

Textadept uses this script to generate its own *tags* and *api* files for its
Lua API.

[LuaDoc]: http://keplerproject.github.com/luadoc/
[Lua files]: api.html#_M.lua

### Generating LuaDoc

Generate Textadept-like API documentation for your own modules using the
*doc/markdowndoc.lua* [LuaDoc][] module (you must have [Discount][] installed):

    luadoc -d . [-t template_dir] --doclet _HOME/doc/markdowndoc [module(s)]

where `_HOME` is the path where you installed Textadept and `template_dir` is an
optional template directory that contains two Markdown files: *.header.md* and
*.footer.md*. (See Textadept's *doc/.header.md* and *doc/.footer.md* for
examples.) LuaDoc creates an *api/* directory in the current directory that
contains the generated API documentation HTML files.

[LuaDoc]: http://keplerproject.github.com/luadoc/
[Discount]: http://www.pell.portland.or.us/~orc/Code/discount/

## Lua Configuration

Textadept contains its own copy of [Lua 5.3][] which has the same configuration
(*luaconf.h*) as vanilla Lua with the following exceptions:

* `LUA_ROOT` is "/usr/" in Linux systems instead of "/usr/local/".
* `LUA_PATH` and `LUA_CPATH` do not have "./?.lua" and "./?.so" in them.
* No compatibility flags are set for previous versions.

[Lua 5.3]: http://www.lua.org/manual/5.3/

## Scintilla

Textadept uses the [Scintilla][] editing component. The [buffer][] and [view][]
parts of
Textadept's API emulate the [Scintilla API][] so porting any C/C++ Scintilla
calls to Lua should not be difficult.

[Scintilla]: http://scintilla.org
[buffer]: api.html#buffer
[view]: api.html#view
[Scintilla API]: http://scintilla.org/ScintillaDoc.html

## Textadept Structure

Textadept's folder structure is organized as follows.

* *core/*: The *core/* directory contains Textadept's core Lua modules. These
  modules are essential for the application to run. They provide Textadept's Lua
  to C interface, event structure, file interactions, and localization.
* *lexers/*: The *lexers/* directory houses the lexer modules that analyze
  source code for syntax highlighting.
* *modules/*: The *modules/* directory contains generic and language modules for
  editing text and source code.
* *themes/*: The *themes/* directory has built-in themes that customize the look
  and feel of Textadept.
* *~/.textadept/*: The *~/.textadept/* directory houses your preferences, Lua
  modules, themes, and user-data. This folder may contain *lexers/*, *modules/*,
  and *themes/* sub-directories.
* *etc/*, *lib/*, and *share/*: These directories are for GTK and only appear in
  the Windows and macOS packages.

- - -

# Compiling

- - -

## Requirements

The requirements for building Textadept are almost as minimal as running it.

### Requirements for Linux and BSD

First, Linux and BSD systems need either the [GNU C compiler][] (*gcc*) version
4.9 or later (circa early 2014) or [Clang][] (*clang*), [libstdc++][] 4.9 or
later (circa early 2014), and [GNU Make][] (*make* or *gmake*). BSD users
additionally need to have [pkg-config][] and [libiconv][] installed. All of
these should be available for your distribution through a package manager. For
example, Ubuntu includes these tools (minus Clang) in the "build-essential"
package.

Next, the GUI version of Textadept requires the GTK 2.24 or later development
libraries. Again, your package manager should allow you to install them.
Debian-based Linux distributions like Ubuntu typically call the package
"libgtk2.0-dev". Otherwise, compile and install GTK from the [GTK website][].
Note that GLib (a dependency of GTK) 2.28 or later is also required.

The optional terminal version of Textadept depends on the development library
for a curses implementation like ncurses. Similarly, your package manager should
provide one. Debian-based Linux distributions like Ubuntu typically call the
ncurses package "libncurses5-dev" or "libncurses6-dev". Otherwise, compile and
install ncurses from the [ncurses website][]. Note: you need the wide-character
development version of ncurses installed, which handles multibyte sequences.
(Therefore, Debian users _also_ need "libncursesw5-dev" or "libncursesw6-dev".)

[GNU C compiler]: http://gcc.gnu.org
[Clang]: http://clang.llvm.org/
[libstdc++]: http://gcc.gnu.org
[GNU Make]: http://www.gnu.org/software/make/
[pkg-config]: http://www.freedesktop.org/wiki/Software/pkg-config/
[libiconv]: http://www.gnu.org/software/libiconv/
[GTK website]: http://www.gtk.org/download/linux.php
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Requirements for Windows

Compiling Textadept on Windows is no longer supported. The preferred way to
compile for Windows is cross-compiling from Linux. In order to do so, you need
[MinGW][] or [mingw-w64][] version 4.9 or later with the Windows header files.
Your package manager should offer them.

Note: attempting to compiling on Windows requires a C compiler that supports the
C99 standard, a C++ compiler that supports the C++11 standard, a C++ standard
library that supports C++11, and my [win32gtk bundle][]. The terminal (pdcurses)
version requires [libiconv for Windows][] and my [win32curses bundle][] instead
of GTK.

[MinGW]: http://mingw.org
[mingw-w64]: http://mingw-w64.org/
[win32gtk bundle]: download/win32gtk-2.24.32.zip
[libiconv for Windows]: http://gnuwin32.sourceforge.net/packages/libiconv.htm
[win32curses bundle]: download/win32curses.zip

### Requirements for macOS

Compiling Textadept on macOS is no longer supported. The preferred way is
cross-compiling from Linux. In order to do so, you need install an
[OSX cross toolchain][] _with GCC_ version 4.9 or later (not Clang). You will
need to run `./build_binutils.sh` _before_ `./build_gcc.sh`. macOS SDK tarballs
like *MacOSX10.5.tar.gz* can be found readily on the internet.

Note that building an OSX toolchain can easily take 30 minutes or more and
ultimately consume nearly 3.5GB of disk space.

[OSX cross toolchain]: https://github.com/tpoechtrager/osxcross

## Compiling

### Makefile Command Summary

The following table provides a brief summary of `make` or `gmake` rules for
building Textadept. Subsequent sections contain more detailed descriptions,
including platform-specific rules and options.

Command              |Description
---------------------|-----------
`make deps`          |Downloads and builds all of Textadept's core dependencies
`make verify-deps`   |Verifies integrity of downloads (for optional security)
`make`               |Builds Textadept, provided all dependencies are in place
`make install`       |Installs Textadept (to */usr/local* by default)
`make curses`        |Builds the terminal version of Textadept
`make curses install`|Installs the terminal version of Textadept
`make uninstall`     |Uninstalls Textadept (from */usr/local* by default)
`make clean`         |Deletes all compiled files, leaving only source files
`make clean-deps`    |Deletes all unpacked dependencies, leaving only downloads

### Compiling on Linux and BSD

Note: for BSD systems, replace the `make` commands below with `gmake`.

For Linux and BSD systems, simply run `make deps` (or `make deps NIGHTLY=1` when
compiling Textadept from the latest source rather than from a tagged release) in
the *src/* directory to prepare the build environment, followed by `make` to
build the *textadept* executable in the root directory. Make a symlink from it
to */usr/bin/* or elsewhere in your `PATH`.

Similarly, `make curses` builds *textadept-curses*.

Note: you may have to run

    make CFLAGS="-I/usr/local/include" \
         CXXFLAGS="-I/usr/local/include -L/usr/local/lib"

if the prefix where any dependencies are installed is */usr/local/* and your
compiler flags do not include them by default.

If it matters, running `make verify-deps` after `make deps` will compare the
downloaded dependencies with the ones Textadept was compiled against.

#### Installing on Linux and BSD

Textadept is self-contained, meaning you do not have to install it, and runs
from its current location. Should you choose to install Textadept like a normal
Linux application, run `make deps` (or `make deps NIGHTLY=1` as noted in the
previous section) and then the usual `make` and `make install` or
`sudo make install` commands depending on your privileges. The default prefix is
*/usr/local* but setting `DESTDIR` (e.g.
`make install DESTDIR=/prefix/to/install/to`) changes it.

Similarly, `make curses` and `make curses install` installs the terminal version.

### Cross Compiling for Windows

When cross-compiling from within Linux, first make a note of your MinGW
compiler names. You may have to either modify the `CROSS` variable in the
"win32" block of *src/Makefile* or append something like
"CROSS=i586-mingw32msvc-" when running `make`. After considering your MinGW
compiler names, run `make win32-deps` or
`make CROSS=i586-mingw32msvc- win32-deps` to prepare the build environment
followed by `make win32` or `make CROSS=i586-mingw32msvc- win32` to build
*../textadept.exe*. Finally, copy the dll files from *src/win32gtk/bin/* to the
directory containing the Textadept executables.

Similarly for the terminal version, run `make win32-curses` or its variant as
suggested above to build *../textadept-curses.exe*.

### Cross Compiling for macOS

When cross-compiling from within Linux, run `make osx-deps` to prepare the build
environment followed by `make osx` to build *../textadept.osx*.

Similarly, `make osx-curses` builds *../textadept-curses.osx*.

Build a new *Textadept.app* with `make osx-app`.

#### Compiling on macOS (Legacy)

Textadept requires [XCode][] as well as [jhbuild][] (for GTK). After building
"meta-gtk-osx-bootstrap" and "meta-gtk-osx-core", build "meta-gtk-osx-themes".
Note that the entire compiling process can easily take 30 minutes or more and
ultimately consume nearly 1GB of disk space.

After using *jhbuild*, GTK is in *~/gtk/* so make a symlink from *~/gtk/inst* to
*src/gtkosx* in Textadept. Then run `make osx` to build *../textadept.osx*.

Developer note: in order to build a GTK for OSX bundle, run the following from
the *src/* directory before zipping up *gtkosx/include/* and *gtkosx/lib/*:

    sed -i -e 's|libdir=/Users/username/gtk/inst/lib|libdir=${prefix}/lib|;' \
    gtkosx/lib/pkgconfig/*.pc

where `username` is your username.

Compiling the terminal version is not so expensive and requires no additional
libraries. Simply run `make osx-curses` to build *../textadept-curses.osx*.

[XCode]: http://developer.apple.com/TOOLS/xcode/
[jhbuild]: https://wiki.gnome.org/Projects/GTK/OSX/Building

### Notes on CDK

[CDK][] is a library of curses widgets. The terminal version of Textadept
includes a slightly modified, stripped down version of this library. The changes
made to CDK are in *src/cdk.patch* and listed as follows:

* Excluded the following source files: *alphalist.c*, *button.c*, *calendar.c*,
  *cdk_compat.{c,h}*, *cdk_params.c*, *cdk_test.h*, *debug.c*, *dialog.c*,
  *{d,f}scale.{c,h}*, *fslider.{c,h}*, *gen-scale.{c,h}*, *get_index.c*,
  *get_string.c*, *graph.c*, *histogram.c*, *marquee.c*, *matrix.c*, *menu.c*,
  *popup_dialog.c*, *position.c*, *radio.c*, *scale.{c,h}*, *swindow.c*,
  *template.c*, *u{scale,slider}.{c,h}*, *view_{file,info}.c*, and *viewer.c*.
* *binding.c* utilizes libtermkey for universal input.
* *cdk.h* does not `#include` "matrix.h", "viewer.h", and any headers labeled
  "Generated headers" due to their machine-dependence, except for "slider.h". It
  also `#define`s `boolean` as `CDKboolean` on Windows platforms since the
  former is already `typedef`ed.
* *cdk_config.h* no longer defines `HAVE_SETLOCALE` since Textadept handles
  locale settings, no longer defines `HAVE_NCURSES_H` and `NCURSES` since
  Textadept supports multiple curses implementations (not just ncurses),
  conditionally enables `HAVE_GRP_H`, `HAVE_LSTAT`, and `HAVE_PWD_H` definitions
  on \*nix platforms since Windows does not have them, and explicitly undefines
  `NCURSES_OPAQUE` since newer versions of ncurses on macOS define it.
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
`-l`, `--line`     |    1    |Jumps to a line in the previously opened file.
`-n`, `--nosession`|    0    |No [session](#Sessions) functionality.
`-s`, `--session`  |    1    |Loads [session](#Sessions) on startup.
`-u`, `--userhome` |    1    |Sets alternate [`_USERHOME`][].
`-v`, `--version`  |    0    |Prints Textadept version and copyright

The terminal version does not support the help switch.

[`_USERHOME`]: api.html#_USERHOME

## Online Help

Textadept has a [mailing list][] and a [wiki][].

[mailing list]: http://foicica.com/lists
[wiki]: http://foicica.com/wiki/textadept

- - -

# Appendix

- - -

## Regular Expressions

Textadept's regular expressions are based on the C++11 standard for ECMAScript.
There are a number of references for this syntax on the internet, including:

* [ECMAScript syntax C++ reference](http://www.cplusplus.com/reference/regex/ECMAScript/)
* [Modified ECMAScript regular expression grammar](http://en.cppreference.com/w/cpp/regex/ecmascript)
* [Regular Expressions (C++)](https://docs.microsoft.com/en-us/cpp/standard-library/regular-expressions-cpp)

Note that Textadept does not support multi-line regex searches. Use Lua scripts
and [Lua patterns](#Lua.Patterns) instead.

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
  You can put a closing square bracket in a set by positioning it as the first
  character in the set. You can put an hyphen in a set by positioning it as the
  first or the last character in the set. (You can also use an escape for both
  cases.)
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

## Terminal Version Compatibility

Textadept 5.5 beta introduced a terminal version that is capable of running in a
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
* Not all key sequences are recognized properly.
* No style settings like font name, font size, or italics.
* No X selection, primary or secondary, integration with the clipboard.
* No zoom.
* When using the mouse in the Windows console, Shift+Double-click extends
  selections and quadruple-clicking inside a selection collapses it.

[`buffer.register_image()`]: api.html#buffer.register_image

## Migration Guides

### Textadept 10 to 11

#### API Changes

Old API                    |Change  |New API
---------------------------|:------:|-------
**buffer**                 |        |
set_theme()                |Renamed |[view:set_theme()][]
style_name[n]              |Replaced|[name_of_style][](n)
CASEINSENSITIVEBEHAVIOUR\_*|Renamed |CASEINSENSITIVEBEHAVIOR\_*
INDIC\_GRADIENTCENTRE      |Renamed |INDIC\_GRADIENTCENTER
MARGIN\_COLOUR             |Renamed |MARGIN\_COLOR
auto\_c\_case_insensitive\_behaviour|Renamed|auto\_c\_case\_insensitive\_behavior
colourise                  |Renamed |colorize
edge\_colour               |Renamed |edge\_color
set\_fold\_margin\_\*colour|Renamed |set\_fold\_margin\_\*color
vertical\_centre\_caret    |Renamed |vertical\_center\_caret
**events**                 |        |
AUTO\_C\_CANCELLED         |Renamed |AUTO\_C\_CANCELED
N/A                        |Added   |[SESSION_SAVE][]
N/A                        |Added   |[SESSION_LOAD][]
**io**                     |        |
reload_file()              |Renamed |[buffer:reload()][]
save_file()                |Renamed |[buffer:save()][]
save_file_as()             |Renamed |[buffer:save_as()][]
close_buffer()             |Renamed |[buffer:close()][]
**keys**                   |        |
MODE                       |Renamed |[mode][]
**lexer**                  |        |
N/A                        |Added   |[to_eol()][]
delimited\_range()         |Replaced|[range()][]
nested\_pair()             |Replaced|[range()][]
fold\_line\_comments()     |Replaced|[fold_consecutive_lines()][]<sup>a</sup>
N/A                        |Added   |[number][]
N/A                        |Added   |[colors][]
N/A                        |Added   |[styles][]
N/A                        |Added   |[folding][] and other fold\* properties
**lfs**                    |        |
dir\_foreach()             |Replaced|for filename in [lfs.walk()][] do ... end
**textadept.bookmarks**    |        |
toggle(line, on)           |Changed |[toggle()][]
**textadept.editing**      |        |
block\_comment()           |Renamed |[toggle_comment()][]
highlight_word()           |Replaced|[highlight_words][]
**textadept.file_types**   |        |
lexers                     |Removed |N/A<sup>b</sup>
**textadept.find**         |        |
find\_incremental()        |Replaced|[incremental][]<sup>c</sup>
find\_incremental\_keys    |Removed |
N/A                        |Added   |[highlight_all_matches][]
**textadept.snippets**     |        |
\_insert()                 |Renamed |[insert()][]
\_previous()               |Renamed |[previous()][]
\_cancel_current()         |Renamed |[cancel_current()][]
\_select()                 |Renamed |[select()][]
\_paths                    |Renamed |[paths][]
**ui**                     |        |
bufstatusbar\_text         |Renamed |[buffer_statusbar_text][]
**ui.dialogs**             |        |
N/A                        |Added   |[progressbar()][]
**ui.find**                |        |
find\_in\_files\_timeout   |Removed |N/A
**view**                   |        |
N/A                        |Added   |_buffer functions and fields_<sup>d</sup>

<sup>a</sup>Returns prefix and function, instead of just function.
<sup>b</sup>Use `for name in buffer:private_lexer_call(_SCINTILLA.functions.property_names[1]):gmatch('[^\n]+') do ... end`.<br/>
<sup>c</sup>Use `textadept.menu.menubar[_L['Search']][_L['Find Incremental']][2]`.<br/>
<sup>d</sup>Most buffer functions and fields are available in views now. See
section below.

[view:set_theme()]: api.html#view.set_theme
[name_of_style]: api.html#buffer.name_of_style
[SESSION_SAVE]: api.html#events.SESSION_SAVE
[SESSION_LOAD]: api.html#events.SESSION_LOAD
[buffer:reload()]: api.html#buffer.reload
[buffer:save()]: api.html#buffer.save
[buffer:save_as()]: api.html#buffer.save_as
[buffer:close()]: api.html#buffer.close
[mode]: api.html#keys.mode
[to_eol()]: api.html#lexer.to_eol
[range()]: api.html#lexer.range
[fold_consecutive_lines()]: api.html#lexer.fold_consecutive_lines
[number]: api.html#lexer.number
[colors]: api.html#lexer.colors
[styles]: api.html#lexer.styles
[folding]: api.html#lexer.folding
[lfs.walk()]: api.html#lfs.walk
[toggle()]: api.html#textadept.bookmarks.toggle
[toggle_comment()]: api.html#textadept.editing.toggle_comment
[highlight_words]: api.html#textadept.editing.highlight_words
[incremental]: api.html#ui.find.incremental
[highlight_all_matches]: api.html#ui.find.highlight_all_matches
[insert()]: api.html#textadept.snippets.insert
[previous()]: api.html#textadept.snippets.previous
[cancel_current()]: api.html#textadept.snippets.cancel_current
[select()]: api.html#textadept.snippets.select
[paths]: api.html#textadept.snippets.paths
[buffer_statusbar_text]: api.html#ui.buffer_statusbar_text
[progressbar()]: api.html#ui.dialogs.progressbar

#### Buffer Indexing Changes

All buffer positions, lines, and countable entities now start from `1` instead
of `0`. For example, `buffer:get_line(1)` now returns the contents of the first
line instead of `buffer:get_line(0)`, and marker and indicator numbers now count
from 1 instead of 0.

While this change may seem daunting for migrating user scripts, in practice it
is not, since most usage is internal, and an offset of 1 or 0 does not matter.
In migrating Textadept's internals, the following changes were made:

* Themes that loop through marker numbers will need to be updated from something
  like `for i = 25, 31 do ... end` to either `for i = 26, 32 do ... end` or
  `for i = buffer.MARKNUM_FOLDEREND, buffer.MARKNUM_FOLDEROPEN do ... end`.
* Most references of `buffer.length` will need to be changed to
  `buffer.length + 1`. For example, something like
  `buffer:goto_pos(buffer.length)` needs to be
  `buffer:goto_pos(buffer.length + 1)`. The exceptions are when `buffer.length`
  is not used as a position, as in
  `buffer:indicator_clear_range(1, buffer.length)`, which is still valid.
* Any `buffer` function calls and property indexing with bare numbers should be
  changed to calls or indexes with those numbers plus 1. For example,
  `buffer:contracted_fold_next(0)` changes to `buffer:contracted_fold_next(1)`,
  and `buffer.margin_n_width[1] = ...` changes to
  `buffer.margin_n_width[2] = ...`.
* Any looping through lines, margins, and selections via
  `for i = 0, buffer.{line_count,margins,selections} - 1 do ... end` needs to be
  `for i = 1, buffer.{line_count,margins,selections} do ... end`.
* Similarly, any language modules that loop back through lines (e.g. to
  determine types for autocompletion) via
  `for i = current_line, 0, -1 do ... end` needs to be
  `for i = current_line, 1, -1 do ... end`.
* Marker or indicator masks are produced by subtracting 1 from marker or
  indicator numbers. For example, `1 << textadept.bookmarks.MARK_BOOKMARK`
  changes to `1 << textadept.bookmarks.MARK_BOOKMARK - 1`.
* Logic that depends on the return value of `buffer:get_cur_line()` may need to
  be changed. For example, any subsequent references to `pos` after
  `local line, pos = buffer:get_cur_line()` like `if line:sub(1, pos) ... end`
  need to be changed to `if line:sub(1, pos - 1) ... end`.

I found it helpful to quickly scan source files for syntax-highlighted numbers
and then seeing if those numbers needed to be changed. Searching for "- 1",
"+ 1", "buffer.length", etc. was also helpful.

#### View API Additions and Buffer API Changes

Textadept's [buffer][] API is largely based on the [Scintilla API][], which does
not distinguish between buffer- and view-specific functionality. Textadept 11
now attempts to separate this functionality, but only superficially. Buffers and
views may be used interchangeably for the most part, but the [buffer][] and
[view][] API provides _guidance_ (not hard requirements) on which functions and
fields are more appropriate for their respective objects. _User scripts do not
need to be updated and will continue to function normally_. The following "Find"
regex can be used to help convert `buffer.*` functionality to `view.*`:

<pre style="word-wrap: break-word;">
<code>(\w+)([.:])\b(additional_caret_fore|additional_carets_blink|additional_carets_visible|additional_sel_alpha|additional_sel_back|additional_sel_fore|all_lines_visible|annotation_visible|auto_c_max_height|auto_c_max_width|call_tip_fore_hlt|call_tip_pos_start|call_tip_position|call_tip_use_style|caret_fore|caret_line_back|caret_line_back_alpha|caret_line_frame|caret_line_visible|caret_line_visible_always|caret_period|caret_style|caret_width|cursor|edge_colour|edge_column|edge_mode|end_at_last_line|extra_ascent|extra_descent|first_visible_line|fold_display_text_style|fold_expanded|fold_flags|h_scroll_bar|highlight_guide|idle_styling|indentation_guides|indic_alpha|indic_fore|indic_hover_fore|indic_hover_style|indic_outline_alpha|indic_style|indic_under|line_visible|lines_on_screen|margins|margin_back_n|margin_cursor_n|margin_left|margin_mask_n|margin_options|margin_right|margin_sensitive_n|margin_type_n|margin_width_n|marker_alpha|marker_back|marker_back_selected|marker_fore|mouse_dwell_time|mouse_selection_rectangular_switch|property|property_expanded|property_int|rectangular_selection_modifier|representation|rgba_image_height|rgba_image_scale|rgba_image_width|scroll_width|scroll_width_tracking|sel_alpha|sel_eol_filled|size|style_back|style_bold|style_case|style_changeable|style_eol_filled|style_font|style_fore|style_italic|style_size|style_underline|style_visible|tab_draw_mode|v_scroll_bar|view_eol|view_ws|whitespace_size|wrap_indent_mode|wrap_mode|wrap_start_indent|wrap_visual_flags|wrap_visual_flags_location|x_offset|zoom|ANNOTATION_BOXED|ANNOTATION_HIDDEN|ANNOTATION_STANDARD|ANNOTATION_INDENTED|CARETSTYLE_BLOCK|CARETSTYLE_INVISIBLE|CARETSTYLE_LINE|CARET_EVEN|CARET_JUMPS|CARET_SLOP|CARET_STRICT|EDGE_BACKGROUND|EDGE_LINE|EDGE_MULTILINE|EDGE_NONE|FOLDACTION_CONTRACT|FOLDACTION_EXPAND|FOLDACTION_TOGGLE|FOLDDISPLAYTEXT_HIDDEN|FOLDDISPLAYTEXT_STANDARD|FOLDDISPLAYTEXT_BOXED|INDIC_BOX|INDIC_COMPOSITIONTHICK|INDIC_COMPOSITIONTHIN|INDIC_DASH|INDIC_DIAGONAL|INDIC_DOTBOX|INDIC_DOTS|INDIC_FULLBOX|INDIC_GRADIENT|INDIC_GRADIENTCENTRE|INDIC_HIDDEN|INDIC_PLAIN|INDIC_POINT|INDIC_POINTCHARACTER|INDIC_ROUNDBOX|INDIC_SQUIGGLE|INDIC_SQUIGGLELOW|INDIC_SQUIGGLEPIXMAP|INDIC_STRAIGHTBOX|INDIC_STRIKE|INDIC_TEXTFORE|INDIC_TT|MOD_ALT|MOD_CTRL|MOD_META|MOD_SHIFT|MOD_SUPER|MOUSE_DRAG|MOUSE_PRESS|MOUSE_RELEASE|WS_INVISIBLE|WS_VISIBLEAFTERINDENT|WS_VISIBLEALWAYS|WS_VISIBLEONLYININDENT|ALPHA_NOALPHA|ALPHA_OPAQUE|ALPHA_TRANSPARENT|CASE_CAMEL|CASE_LOWER|CASE_MIXED|CASE_UPPER|CURSORARROW|CURSORNORMAL|CURSORREVERSEARROW|CURSORWAIT|FOLDFLAG_LEVELNUMBERS|FOLDFLAG_LINEAFTER_CONTRACTED|FOLDFLAG_LINEAFTER_EXPANDED|FOLDFLAG_LINEBEFORE_CONTRACTED|FOLDFLAG_LINEBEFORE_EXPANDED|FOLDFLAG_LINESTATE|IV_LOOKBOTH|IV_LOOKFORWARD|IV_NONE|IV_REAL|MARGINOPTION_NONE|MARGINOPTION_SUBLINESELECT|MARGIN_BACK|MARGIN_COLOUR|MARGIN_FORE|MARGIN_NUMBER|MARGIN_RTEXT|MARGIN_SYMBOL|MARGIN_TEXT|MARK_ARROW|MARK_ARROWDOWN|MARK_ARROWS|MARK_BACKGROUND|MARK_BOOKMARK|MARK_BOXMINUS|MARK_BOXMINUSCONNECTED|MARK_BOXPLUS|MARK_BOXPLUSCONNECTED|MARK_CHARACTER|MARK_CIRCLE|MARK_CIRCLEMINUS|MARK_CIRCLEMINUSCONNECTED|MARK_CIRCLEPLUS|MARK_CIRCLEPLUSCONNECTED|MARK_DOTDOTDOT|MARK_EMPTY|MARK_FULLRECT|MARK_LCORNER|MARK_LCORNERCURVE|MARK_LEFTRECT|MARK_MINUS|MARK_PIXMAP|MARK_PLUS|MARK_RGBAIMAGE|MARK_ROUNDRECT|MARK_SHORTARROW|MARK_SMALLRECT|MARK_TCORNER|MARK_TCORNERCURVE|MARK_UNDERLINE|MARK_VERTICALBOOKMARK|MARK_VLINE|MASK_FOLDERS|TD_LONGARROW|TD_STRIKEOUT|TIME_FOREVER|WRAPINDENT_DEEPINDENT|WRAPINDENT_FIXED|WRAPINDENT_INDENT|WRAPINDENT_SAME|WRAPVISUALFLAGLOC_DEFAULT|WRAPVISUALFLAGLOC_END_BY_TEXT|WRAPVISUALFLAGLOC_START_BY_TEXT|WRAPVISUALFLAG_END|WRAPVISUALFLAG_MARGIN|WRAPVISUALFLAG_NONE|WRAPVISUALFLAG_START|WRAP_CHAR|WRAP_NONE|WRAP_WHITESPACE|WRAP_WORD|STYLE_BRACEBAD|STYLE_BRACELIGHT|STYLE_CALLTIP|STYLE_CONTROLCHAR|STYLE_DEFAULT|STYLE_FOLDDISPLAYTEXT|STYLE_INDENTGUIDE|STYLE_LINENUMBER|STYLE_MAX|UPDATE_H_SCROLL|UPDATE_V_SCROLL|VISIBLE_SLOP|VISIBLE_STRICT|brace_bad_light|brace_bad_light_indicator|brace_highlight|brace_highlight_indicator|call_tip_active|call_tip_cancel|call_tip_pos_start|call_tip_set_hlt|call_tip_show|clear_registered_images|clear_representation|contracted_fold_next|doc_line_from_visible|ensure_visible|ensure_visible_enforce_policy|fold_all|fold_children|fold_line|get_default_fold_display_text|hide_lines|line_scroll|line_scroll_down|line_scroll_up|marker_define|marker_define_pixmap|marker_define_rgba_image|marker_enable_highlight|marker_symbol_defined|multi_edge_add_line|multi_edge_clear_all|register_image|register_rgba_image|scroll_caret|scroll_to_end|scroll_to_start|scroll_range|set_default_fold_display_text|set_fold_margin_colour|set_fold_margin_hi_colour|set_sel_back|set_sel_fore|set_visible_policy|set_whitespace_back|set_whitespace_fore|set_x_caret_policy|set_y_caret_policy|show_lines|style_clear_all|style_reset_default|text_height|text_width|toggle_fold|toggle_fold_show_text|vertical_centre_caret|visible_from_doc_line|wrap_count|zoom_in|zoom_out|split|unsplit|goto_buffer)\b</code>
</pre>

"Replace" with

    view\2\3

It is not recommended to blindly "Replace All". Each change should be manually
confirmed.

[buffer]: api.html#buffer
[Scintilla API]: http://scintilla.org/ScintillaDoc.html
[Scintilla]: http://scintilla.org
[view]: api.html#view

#### Theme and Lexer Changes

Themes and lexers have a new, optional API for defining and using colors and
styles. Previously, all definitions and access to colors and styles was
accomplished through `buffer.property` and `buffer.property_int`. Now it can be
done via the `lexer.colors` and `lexer.styles` variables. For example:

    -- Textadept 10
    local property, property_int = buffer.property, buffer.property_int
    property['color.blue'] = 0xFF0000
    property['style.keyword'] = 'fore:$(color.blue),bold'
    buffer.edge_colour = property_int['color.grey']

    -- Textadept 11
    local colors, styles = lexer.colors, lexer.styles
    colors.blue = 0xFF0000
    styles.keyword = {fore = colors.blue, bold = true}
    view.edge_color = colors.grey

Any additional settings passed `view:set_theme()` are available as global
variables in the theme. Textadept's themes make use of `font` and `size` (the
latter of which used to be `fontsize`) for easily configuring font and size
per-user.

Lexers can also utilize these new features. For example:

    -- Textadept 10
    lex:add_rule('custom_rule', token('custom', P('word')))
    lex:add_style('custom', lexer.STYLE_KEYWORD .. 'italic')

    -- Textadept 11
    lex:add_rule('custom_rule', token('custom', P('word')))
    lex:add_style('custom', lexer.styles.keyword .. {italic = true})

Note that these features are optional. Themes and lexers setting property
strings is still supported.

#### Localization Changes

GUI mnemonics in localization keys have been removed. For example, `_L['_New']`
should be changed to `_L['New']`. Mnemonics can still be used in localization
values; it's just the keys that have changed. See *core/locale.conf* for
examples.

#### Key Bindings Changes

Key sequence modifiers have changed from their shortened form to a longer form
that is more intuitive. `'c'` is now `'ctrl'`, `'a'` is now `'alt'`, `'m'` is
now `'cmd'` on macOS and `'meta'` in the terminal version, and `'s'` is now
`'shift'`. For example, `keys.cn = ...` is now `keys['ctrl+n'] = ...` and
`keys['m<'] = ...` is now `keys['cmd+<'] = ...` or `keys['meta+<'] = ...`.

The key binding for inserting a user-specified snippet from a dialog has changed
from `Ctrl+K` (`⌥⇥` on macOS | `M-K` on the terminal) to `Ctrl+Shift+K`
(`⌥⇧⇥` | `M-S-K`). `Ctrl+K` (`⌥⇥` | `M-K`) now autocompletes snippet names.

#### Session Changes

Textadept saves and loads session from Lua data files instead of structured text
files. As a result, Textadept 11 cannot load session files from 10.x or before.

#### Miscellaneous Changes

* *~/.textadept/?.lua* and *~/.textadept/?.{so,dll}* has been removed from
  `package.path` and `package.cpath`, respectively. All modules should be placed
  in *~/.textadept/modules/*.
* The command entry no longer recognizes a Lua 5.1-style '`=`' prefix for
  printing return values. Printing return values has been the default for quite
  some time.

# Installation

## Requirements

In its bid for minimalism, Textadept also depends on very little to run. The GUI
version needs only [GTK+][], a cross-platform GUI toolkit, version 2.18 or later
on Linux and BSD systems. The application already bundles a GTK+ runtime into
the Windows and Mac OSX packages. The terminal, or curses, version of Textadept
only depends on a curses implementation like [ncurses][] on Linux, Mac OSX, and
BSD systems. The Windows binary includes a precompiled version of [pdcurses][].
Textadept also incorporates its own [copy of Lua][] on all platforms.

[GTK+]: http://gtk.org
[copy of Lua]: 11_Scripting.html#Lua.Configuration
[ncurses]: http://invisible-island.net/ncurses/ncurses.html
[pdcurses]: http://pdcurses.sourceforge.net

### Linux and BSD

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

[GTK+ website]: http://www.gtk.org/download-linux.html
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Mac OSX

No requirements other than Mac OSX 10.5 (Leopard) or higher with an Intel CPU.

### Windows

No requirements.

## Download

Download Textadept from the project's [download page][] by selecting the
appropriate package for your platform. For the Windows and Mac OSX packages, the
bundled GTK+ runtime accounts for more than 3/4 of the download and unpackaged
application sizes. Textadept itself is much smaller.

You also have the option of downloading an official set of
[language-specific modules][] from the download page. Textadept itself includes
C/C++ and Lua language modules by default.

[download page]: http://foicica.com/textadept/download
[language-specific modules]: 07_Modules.html#Language-Specific

## Installation

Installing Textadept is simple and easy. You do not need administrator
privileges.

### Linux and BSD

Unpack the archive anywhere.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules are located in the
*/path/to/textadept_x.x/modules/* directory.

### Mac OSX

Unpack the archive and move *Textadept.app* to your user or system
*Applications/* directory like any other Mac OSX application. The package
contains an optional *ta* script for launching Textadept from the command line
that you can put in a directory in your "$PATH" (e.g. */usr/local/bin/*).

If you downloaded the set of language-specific modules, unpack it, right-click
*Textadept.app*, select "Show Package Contents", navigate to
*Contents/Resources/modules/*, and move the unpacked modules there.

### Windows

Unpack the archive anywhere.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules are located in the
*textadept_x.x\modules\\* directory.

## Running

### Linux and BSD

Run Textadept by running */path/to/textadept_x.x/textadept* from the terminal
You can also create a symbolic link to the executable in a directory in your
"$PATH" (e.g. */usr/local/bin/*) or make a GNOME, KDE, XFCE, etc. button or menu
launcher.

The package also contains a *textadeptjit* executable for running Textadept with
[LuaJIT][]. Due to potential [compatibility issues][], use the *textadept*
executable wherever possible.

The *textadept-curses* and *textadeptjit-curses* executables are the terminal
versions of Textadept. Run them as you would run the *textadept* and
*textadeptjit* executables, but from a terminal instead.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

#### Problems

Providing a single binary that runs on all Linux platforms proves challenging,
since the versions of software installed vary widely from distribution to
distribution. Because the Linux version of Textadept uses the version of GTK+
installed on your system, an error like:

    error while loading shared libraries: <lib>: cannot open shared object
    file: No such file or directory

may occur when trying to run the program. The solution is actually quite
painless even though it requires recompiling Textadept. The [compiling][] page
has more information.

[compiling]: 12_Compiling.html

### Mac OSX

Run Textadept by double-clicking *Textadept.app*. You can also pin it to your
dock.

*Textadept.app* also contains an executable for running Textadept with
[LuaJIT][]. Enable it by setting a "TEXTADEPTJIT"
[environment variable](#Environment.Variables) or by typing
`export TEXTADEPTJIT=1` in the terminal. Due to potential
[compatibility issues][], use the non-LuaJIT executable wherever possible.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

#### Environment Variables

By default, Mac OSX GUI apps like Textadept do not see shell environment
variables like "$PATH". Consequently, any [modules][] that utilize programs
contained in "$PATH" (e.g. the progams in */usr/local/bin/*) for run and compile
commands will not find those programs. Follow [these instructions][] to export
the environment variables you need Textadept to see. At the very least, set
"PATH" to be "$PATH". You must logout and log back in before the changes take
effect.

[modules]: 07_Modules.html
[these instructions]: http://developer.apple.com/library/mac/#qa/qa1067/_index.html

### Windows

Run Textadept by double-clicking *textadept.exe*. You can also create shortcuts
to the executable in your Start Menu, Quick Launch toolbar, Desktop, etc.

The package also contains a *textadeptjit.exe* executable for running Textadept
with [LuaJIT][]. Due to potential [compatibility issues][], use the
*textadept.exe* executable wherever possible.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

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

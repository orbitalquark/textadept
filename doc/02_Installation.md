# Installation

## Requirements

In its bid for minimalism, Textadept also needs very little to run. The GUI
version needs only [GTK+][], a cross-platform GUI toolkit, version 2.18 or later
on Linux and BSD systems. A GTK+ runtime is already bundled into the Windows
and Mac OSX packages. Textadept also has its own [copy of Lua][]. The terminal
(curses) version of Textadept requires a curses implementation like [ncurses][],
but that dependency is only necessary if you wish to run the editor from a
terminal.

[GTK+]: http://gtk.org
[copy of Lua]: 11_Scripting.html#Lua.Configuration
[ncurses]: http://invisible-island.net/ncurses/ncurses.html

### Linux and BSD

Most Linux and BSD systems already have GTK+ installed. If not, it is probably
available through your package manager. Otherwise, compile and install it from
the [GTK+ website][].

The GUI versions of Textadept in the Linux binary downloads require GLib version
2.28 or later to support [single-instance](#Single.Instance) functionality. You
can compile Textadept with earlier versions of GLib down to 2.22. For reference,
Ubuntu 11.04, Debian Wheezy, Fedora 15, and openSUSE 11.4 support GLib 2.28 or
later.

Most Linux and BSD systems already have a curses implementation like ncurses
installed. If not, look for one in your package manager, or compile and install
ncurses from the [ncurses website][]. You need to have or compile the
wide-character version of ncurses, which handles multibyte characters. For
Debian-based distributions like Ubuntu, the package is typically called
"libncursesw5".

[GTK+ website]: http://www.gtk.org/download-linux.html
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses

### Mac OSX

No requirements other than Mac OSX 10.5 (Leopard) or higher with an Intel CPU.

### Windows

No requirements.

## Download

Download Textadept from the project's [download page][] by selecting the
appropriate package for your platform. For Windows and Mac OSX, more than 3/4 of
the download and unpackaged application sizes are due to the bundled GTK+.
Textadept itself is much smaller.

You can also download an official set of [language-specific modules][] from the
download page, but this is optional. The list of language modules in the package
is contained [here][]. Textadept includes C/C++ and Lua language modules by
default.

[download page]: http://foicica.com/textadept/download
[language-specific modules]: 07_Modules.html#Language-Specific
[here]: http://foicica.com/hg

## Installation

Textadept is designed to be as easy as possible to install by any user. You do
not need to have administrator privileges.

### Linux and BSD

Unpack the archive anywhere.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules will be contained in the
*/path/to/textadept_x.x/modules/* directory.

### Mac OSX

Unpack the archive and move *Textadept.app* to your user or system
*Applications/* directory like any other Mac OSX application. There is also a
*ta* script for launching Textadept from the command line that you can put in
a directory in your "$PATH" (e.g. */usr/local/bin/*), but this is optional.

If you downloaded the set of language-specific modules, unpack it, right-click
*Textadept.app*, select "Show Package Contents", navigate to
*Contents/Resources/modules/*, and copy the unpacked modules there.

### Windows

Unpack the archive anywhere.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules will be contained in the
*textadept_x.x\modules\\* directory.

## Running

### Linux and BSD

Run Textadept by running */path/to/textadept_x.x/textadept* from the terminal.
You can also create a symbolic link to the executable in a directory in your
"$PATH" (e.g. */usr/local/bin/*) or make a GNOME, KDE, XFCE, etc. button or menu
launcher.

There is also a *textadeptjit* executable for running Textadept with [LuaJIT][].
Please note there may be [compatibility issues][]. The *textadept* executable is
recommended.

The *textadept-curses* and *textadeptjit-curses* executables are versions of
Textadept for the terminal. Run them as you would run the *textadept* and
*textadeptjit* executables, but from a terminal instead.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

#### Problems

It is difficult to provide a single binary that runs on all Linux platforms
since the versions of software installed vary widely from distribution to
distribution. Because the Linux version of Textadept uses the version of GTK+
installed on your system, an error like:

    error while loading shared libraries: <lib>: cannot open shared object
    file: No such file or directory

may occur when trying to run the program. The solution is actually quite
painless even though it requires recompiling Textadept. See the [compiling][]
page for more information.

[compiling]: 12_Compiling.html

### Mac OSX

Run Textadept by double-clicking *Textadept.app*. You can also pin it to your
dock.

*Textadept.app* also contains an executable for running Textadept with
[LuaJIT][]. You can enable it by setting a "TEXTADEPTJIT"
[environment variable](#Environment.Variables) or using `export TEXTADEPTJIT=1`
in the terminal. Please note there may be [compatibility issues][]. The
non-LuaJIT executable is recommended.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

#### Environment Variables

By default, Mac OSX GUI apps like Textadept do not utilize environment variables
like "$PATH" from your shell profile. Therefore, any [modules][] that use
programs contained in "$PATH" (e.g. the progams in */usr/local/bin/*) for run
and compile commands will not be found. The solution is to follow
[these instructions][] to export whichever environment variables you need. At
the very least, set "PATH" to be "$PATH". You will have to logout and log back
in for the changes to take effect.

[modules]: 07_Modules.html
[these instructions]: http://developer.apple.com/library/mac/#qa/qa1067/_index.html

### Windows

Run Textadept by double-clicking *textadept.exe*. You can also create shortcuts
to the executable in your Start Menu, Quick Launch toolbar, Desktop, etc.

There is also a *textadeptjit.exe* executable for running Textadept with
[LuaJIT][]. Please note there may be [compatibility issues][]. The
*textadept.exe* executable is recommended.

[LuaJIT]: http://luajit.org
[compatibility issues]: 11_Scripting.html#LuaJIT

### *~/.textadept*

Textadept stores all of your preferences and user-data in your *~/.textadept/*
folder. If this folder does not exist, Textadept creates it on startup. You will
learn more about this folder later.

## Single Instance

Textadept is a single-instance application on Linux, BSD, and Mac OSX. This
means that after Textadept is opened, running `textadept file.ext`
(`ta file.ext` on Mac OSX) from the command line or opening a file with
Textadept from a file manager will open *file.ext* in the existing instance of
Textadept. You can override this and open the file in a new instance by passing
a `-f` or `--force` switch to Textadept: `textadept -f file.ext`
(`ta -f file.ext`). When the force switch is not present, files will be opened
in the original Textadept instance, regardless of how many instances are open.

Single instance is not supported on the Windows and terminal versions of
Textadept.

<span style="display: block; text-align: right; margin-left: -10em;">
![Linux](images/linux.png)
&nbsp;&nbsp;
![Mac OSX](images/macosx.png)
&nbsp;&nbsp;
![Win32](images/win32.png)
&nbsp;&nbsp;
![curses](images/ncurses.png)
</span>

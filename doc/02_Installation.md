# Installation

## Requirements

In its bid for minimalism, Textadept also needs very little to run. In fact, the
only thing it needs is [GTK+ 2.0][] >= 2.16 on Linux systems. GTK is already
included in Windows and Mac OSX packages. Textadept also has its own version of
Lua.

Note: for Win32 and Mac OSX, more than 3/4 of the download and unpackaged
application sizes are due to GTK, the cross-platform GUI toolkit Textadept uses.
Textadept itself is much smaller.

[GTK+ 2.0]: http://gtk.org

### Linux

Most Linux systems already have GTK+ installed. If not, it is probably available
through your package manager. Otherwise, compile and install it from the
[GTK+ website][].

[GTK+ website]: http://www.gtk.org/download-linux.html

### Mac OSX

No requirements other than Mac OSX 10.5 (Leopard) or higher with an Intel CPU.

### Windows

No requirements.

## Download

Download Textadept from the [project page][]. Select the appropriate package for
your platform.

You can also download an official set of [language-specific modules][], but this
is optional. The list of language modules in the package is contained [here][].
Textadept includes C/C++ and Lua language modules by default.

[project page]: http://foicica.com/textadept
[language-specific modules]: 7_Modules.html#Language.Specific
[here]: http://foicica.com/hg

## Installation

Textadept is designed to be as easy as possible to install by any user. You do
not need to have administrator privileges.

### Linux

Unpack the archive anywhere. Run Textadept by running
`/path/to/textadept_VERSION/textadept` from the terminal. You can also create a
symlink to the executable in your `PATH` (e.g. `/usr/bin`) or make a GNOME, KDE,
XFCE, etc. button or menu launcher.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules will be contained in
`/path/to/textadept_VERSION/modules/`.

#### Problems

It is difficult to provide a single binary that runs on all Linux platforms
since the versions of software installed vary widely from distribution to
distribution. Because the Linux version of Textadept uses the version of GTK
installed on your system, an error like: `error while loading shared  libraries:
<lib>: cannot open shared object file: No such file or directory` may occur when
trying to run the program.

The most common occurance of this error is for the `libpng12` library on 64-bit
(x86\_64) Debian and Debian-based Linux distributions like Ubuntu because
`libpng12` has not been replaced in favor of the newer `libpng14`. If you are
experiencing this error, simply rename `textadept.lpng12` to `textadept`. The
former has been compiled to use `libpng12`.

If the above situation did not apply to you, do not be alarmed. The solution is
actually quite painless even though it requires recompiling Textadept. See the
[compiling][] page for more information.

[compiling]: 12_Compiling.html

### Mac OSX

Unpack the archive and move `Textadept.app` to your user or system
`Applications` directory like any other Mac OSX application. Run Textadept by
double-clicking `Textadept.app`.

If you downloaded the set of language-specific modules, unpack it, right-click
`Textadept.app`, select `Show Package Contents`, navigate to
`Contents/Resources/modules`, and copy the unpacked modules there.

#### Environment Variables

By default, GUI apps like Textadept do not utilize environment variables such as
`PATH` from your shell profile. Therefore, any [modules][] that use programs
contained in `PATH` (e.g. the progams in `/usr/local/bin/`) for run and compile
commands will not be found. The solution is to follow these [instructions][] to
export whichever environment variables you need. At the very least, set `PATH`
to be `$PATH`. You will have to logout and log back in for the changes to take
effect.

[modules]: 7_Modules.html
[instructions]: http://developer.apple.com/library/mac/#qa/qa1067/_index.html

### Windows

Unpack the archive anywhere. Run Textadept by double-clicking `textadept.exe`.
You can also create shortcuts to the executable in your Start Menu, Quick Launch
toolbar, Desktop, etc.

If you downloaded the set of language-specific modules, unpack it where you
unpacked the Textadept archive. The modules will be contained in
`textadept_VERSION\modules\`.

![Linux](images/linux.png)
&nbsp;&nbsp;
![Mac OSX](images/macosx.png)
&nbsp;&nbsp;
![Win32](images/win32.png)

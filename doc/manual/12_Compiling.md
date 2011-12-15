# Compiling

## Requirements

Unfortunately, the requirements for building Textadept are not quite as minimal
as running it.

#### Linux and BSD

Linux systems need the GTK+ development libraries. Your package manager should
allow you to install them. For Debian-based distributions like Ubuntu, the
package is typically called `libgtk2.0-dev`. Otherwise, compile and install GTK
from the [GTK+ website](http://www.gtk.org/download/linux.html). Additionally
you will need the [GNU C compiler](http://gcc.gnu.org) (`gcc`) and
[GNU Make](http://www.gnu.org/software/make/) (`make`). Both should be available
for your Linux distribution through its package manager. For example, Ubuntu
includes these tools in the `build-essential` package.

#### Windows

Compiling Textadept on Windows is no longer supported. If you wish to do so
however, you need a C compiler that supports the C99 standard (Microsoft's does
not) and the [GTK+ for Windows bundle](http://www.gtk.org/download/win32.html)
(2.22 is recommended).

The preferred way to compile for Windows is cross-compiling from Linux. To do
so, in addition to the GTK bundle mentioned above, you need
[MinGW](http://mingw.org) with the Windows header files. They should be
available from your package manager.

#### Mac OSX

[XCode](http://developer.apple.com/TOOLS/xcode/) is needed for Mac OSX as well
as [jhbuild](http://sourceforge.net/apps/trac/gtk-osx/wiki/Build). After
building `meta-gtk-osx-bootstrap` and `meta-gtk-osx-core`, you need to build
`meta-gtk-osx-themes`. Note that the entire compiling process can easily take
30 minutes or more and ultimately consume nearly 1GB of disk space.

## Compiling

Make sure you downloaded the `textadept_x.x.src.zip` (regardless of what
platform you are on) and not a platform-specific binary package.

#### Linux and BSD

For Linux systems, simply run `make` in the `src/` directory. The `textadept`
executable is created in the root directory. Make a symlink from it to
`/usr/bin/` or elsewhere in your `PATH`.

BSD users please run `make BSD=1`.

#### Cross Compiling for Windows from Linux

When cross-compiling from within Linux, first unzip the GTK+ for Windows bundle
into a new `src/win32gtk` directory. Then modify the `CC`, `CPP`, and `WINDRES`
variables in the `WIN32` block of `src/Makefile` to match your MinGW
installation and run `make WIN32=1` to build `../textadept.exe`.

#### Mac OSX

After using `jhbuild`, GTK is in `~/gtk` so make a symlink from `~/gtk/inst` to
`src/gtkosx` in Textadept. Then run `make OSX=1` to build `../textadept.osx`. At
this point it is recommended to build a new `textadept.app` from an existing
one. Download the most recent app and replace `Contents/MacOS/textadept.osx`,
all `.dylib` files in `Contents/Resources/lib`, and all `.so` files in
`Contents/Resources/lib/gtk-2.0/<version>/{engines,immodules,loaders}` with your
own versions in `src/gtkosx/lib`. If you wish, you may also replace the files
in `Contents/Resources/{etc,share}`, but these rarely change.

##### Problems

If the build fails because of a

    `redefinition of 'struct Sci_TextRange'`

error, open `src/scintilla/include/Scintilla.h` and comment out the following
lines (put `//` at the start of the line):

    #define CharacterRange Sci_CharacterRange
    #define TextRange Sci_TextRange
    #define TextToFind Sci_TextToFind

#### Compiling with LuaJIT

[LuaJIT](http://luajit.org) is a Just-In-Time Compiler for Lua and can boost the
speed of Lua programs. I have noticed that syntax highlighting can be up to 2
times faster with LuaJIT than with vanilla Lua. This difference is largely
unnoticable on modern computers and usually only discernable when initially
loading large files. Other than syntax highlighting, LuaJIT offers no real
benefit performance-wise to justify it being Textadept's default runtime.
LuaJIT's [ffi library](http://luajit.org/ext_ffi.html), however, appears to be
useful for interfacing with external, non-Lua, libraries.

You can compile Textadept with LuaJIT by running `make LUAJIT=1` for non-Windows
systems and `make WIN32=1 LUAJIT=1` for Windows systems.

Please note that a `lua51.dll` is produced for Windows platforms because
limitations on external Lua library loading do not allow statically linking
LuaJIT to Textadept. Static linking occurs on all other platforms.

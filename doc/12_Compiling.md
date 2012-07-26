# Compiling

## Requirements

Unfortunately, the requirements for building Textadept are not quite as minimal
as running it.

### Linux and BSD

Linux systems need the GTK+ development libraries. Your package manager should
allow you to install them. For Debian-based distributions like Ubuntu, the
package is typically called `libgtk2.0-dev`. Otherwise, compile and install GTK
from the [GTK+ website][]. Additionally you will need the [GNU C compiler][]
(`gcc`) and [GNU Make][] (`make`). Both should be available for your Linux
distribution through its package manager. For example, Ubuntu includes these
tools in the `build-essential` package.

If you would like to compile the terminal version of Textadept, you will need
the ncurses development library. Similarly, it should be available from your
package manager. For Debian-based distributions like Ubuntu, the package is
typically called `libncurses5-dev`. Otherwise, compile and install ncurses from
the [ncurses website][]. Note: you should have a development version of ncurses
compiled with "wide" (multibyte) character support installed. (Therefore, Debian
users will also need `libncursesw5-dev`.)

In addition, BSD users will need to have [libiconv][] installed.

[GTK+ website]: http://www.gtk.org/download/linux.html
[GNU C compiler]: http://gcc.gnu.org
[GNU Make]: http://www.gnu.org/software/make/
[ncurses website]: http://invisible-island.net/ncurses/#download_ncurses
[libiconv]: http://www.gnu.org/software/libiconv/

### Windows

Compiling Textadept on Windows is no longer supported. If you wish to do so
however, you need a C compiler that supports the C99 standard (Microsoft's does
not), the [GTK+ for Windows bundle][] (2.24 is recommended), and [libiconv][]
(the "Developer files" zip).

The preferred way to compile for Windows is cross-compiling from Linux. To do
so, in addition to the GTK bundle mentioned above, you need [MinGW][] with the
Windows header files. They should be available from your package manager.

[GTK+ for Windows bundle]: http://www.gtk.org/download/win32.html
[libiconv]: http://gnuwin32.sourceforge.net/packages/libiconv.htm
[MinGW]: http://mingw.org

### Mac OSX

Compiling Textadept on Mac OSX is no longer supported. The preferred way is
cross-compiling from Linux. To do so, you will need my [GTK+ for OSX bundle][]
and the [Apple Crosscompiler][] binaries.

[GTK+ for OSX bundle]: download/gtkosx-2.24.9.zip
[Apple Crosscompiler]: https://launchpad.net/~flosoft/+archive/cross-apple

## Compiling

Make sure you downloaded the `textadept_x.x.src.zip` (regardless of what
platform you are on) and not a platform-specific binary package.

### Linux and BSD

For Linux and BSD systems, simply run `make` in the `src/` directory. The
`textadept` and `textadeptjit` executables are created in the root directory.
Make a symlink from them to `/usr/bin/` or elsewhere in your `PATH`.

Similarly, `make ncurses` builds `textadept-ncurses` and `textadeptjit-ncurses`.

Note: you may have to run `make CFLAGS="-I/usr/local/include"
CXXFLAGS="-I/usr/local/include -L/usr/local/lib"` if the prefix where any
dependencies are installed is `/usr/local` and your compiler flags do not
include them by default.

### Cross Compiling for Windows

When cross-compiling from within Linux, first unzip the GTK+ for Windows bundle
into a new `src/win32gtk` directory. Also, unzip the libiconv zip into the same
directory. Then, depending on your MinGW installation, either run `make win32`,
modify the `CROSS` variable in the `win32` block of `src/Makefile` and run
`make win32`, or run `make CROSS=i486-mingw32- win32` to build
`../textadept.exe` and `../textadeptjit.exe`.

Please note that a `lua51.dll` is produced for _only_ the `textadeptjit.exe`
because limitations on external Lua library loading do not allow statically
linking LuaJIT to Textadept.

### Cross Compiling for Mac OSX

When cross-compiling from within Linux, first unzip the GTK+ for OSX bundle into
a new `src/gtkosx` directory. Then run `make osx` to build `../textadept.osx`
and `../textadeptjit.osx`. At this point it is recommended to build a new
`Textadept.app` from an existing one. Download the most recent app and replace
`Contents/MacOS/textadept.osx` and `Contents/MacOS/textadeptjit.osx` with your
own versions.

Similarly, `make osx-ncurses` builds `../textadept-ncurses.osx` and
`../textadeptjit-ncurses.osx`.

#### Compiling on OSX (Legacy)

[XCode][] is needed for Mac OSX as well as [jhbuild][] (for GTK). After building
`meta-gtk-osx-bootstrap` and `meta-gtk-osx-core`, you need to build
`meta-gtk-osx-themes`. Note that the entire compiling process can easily take 30
minutes or more and ultimately consume nearly 1GB of disk space.

After using `jhbuild`, GTK is in `~/gtk` so make a symlink from `~/gtk/inst` to
`src/gtkosx` in Textadept. Then open `src/Makefile` and uncomment the `Darwin`
block. Finally, run `make osx` to build `../textadept.osx` and
`../textadeptjit.osx`.

Note: to build a GTK+ for OSX bundle, the following needs to be run from the
`src` directory before zipping up `gtkosx/include` and `gtkosx/lib`:

    sed -i -e 's|libdir=/Users/username/gtk/inst/lib|libdir=${prefix}/lib|;' \
    gtkosx/lib/pkgconfig/*.pc

where `username` is replaced with your username.

Compiling the terminal version is not so expensive. After uncommenting the
`Darwin` block mentioned above, simply run `make osx-ncurses` to build
`../textadept-ncurses.osx` and `../textadeptjit-ncurses.osx`.

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

[CDK][] is a library of ncurses widgets. Textadept includes a stripped down
version of this library. The following source files have been removed:
`alphalist.c`, `calendar.c`, `cdk_compat.{c,h}`, `cdk_test.h`, `dialog.c`,
`{d,f}scale.{c,h}`, `fslider.{c,h}`, `gen-{scale,slider}.{c,h}`, `get_index.c`,
`get_string.c`, `graph.c`, `histogram.c`, `marquee.c`, `matrix.c`,
`popup_dialog.c`, `radio.c`, `scale.{c,h}`, `selection.c`, `slider.{c,h}`,
`swindow.c`, `template.c`, `u{scale,slider}.{c,h}`, `view_{file,info}.c`, and
`viewer.c`.

`cdk.h` has been modified to not `#include` "matrix.h", "viewer.h", and any
headers labeled "Generated headers" due to their machine-dependence.

Also, the `deleteFileCB` routine in `fselect.c` has been deactivated.

[CDK]: http://invisible-island.net/cdk/

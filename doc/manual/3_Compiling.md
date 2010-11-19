# Compiling

## Requirements

The requirements for building Textadept are not quite so minimal.

#### Linux & BSD

Linux systems will need the GTK+ development libraries. Your package manager
should allow you to install them. For Debian-based distributions, the package is
typically called `libgtk2.0-dev`. Otherwise, compile and install it from the
[GTK+ website][GTK-Linux]. Additionally you will need the [GNU C compiler][GCC]
(`gcc`) and [GNU Make][Make] (`make`). Both should be available for your Linux
distribution through its package manager.

[GTK-Linux]: http://www.gtk.org/download-linux.html
[GCC]: http://gcc.gnu.org
[Make]: http://www.gnu.org/software/make/

#### Windows

Compiling Textadept on Windows is no longer supported. If you wish to do so
however, you will need a C compiler that supports the C99 standard (Microsoft's
does not) and the [GTK+ for Windows bundle][GTK-Win32] and win_iconv libraries.

The preferred way to compile for Windows is cross-compiling from Linux. To do
so, in addition to the GTK+ development libraries mentioned above, you will need
[MinGW][MinGW] with the Windows header files and the Windows [bundle][GTK-Win32]
along with win_iconv. The former should be available from your package manager.
The latter you will have to download manually.

[GTK-Win32]: http://www.gtk.org/download-windows.html
[MinGW]: http://mingw.org

#### Mac OSX

[XCode][XCode] is needed for Mac OSX as well as [jhbuild][GTK-OSX]. After
building `meta-gtk-osx-bootstrap` and `meta-gtk-osx-core`, you will need to
build `meta-gtk-osx-themes`. Note that the entire compiling process can easily
take 30 minutes or more and ultimately consume nearly 1GB of disk space.

[XCode]: http://developer.apple.com/TOOLS/xcode/
[GTK-OSX]: http://sourceforge.net/apps/trac/gtk-osx/wiki/Build

## Download

Download the `textadept_x.x.src.zip`, regardless of what platform you are on.

## Compiling

#### Linux & BSD

For Linux systems, simply run `make` in the `src/` directory. The `textadept`
executable will be created in the root directory. You can make a symlink from
it to `/usr/bin/` or elsewhere in your `PATH`.

BSD users please run `make BSD=1`.

#### Windows (Cross-Compiling from Linux)

When cross-compiling from within Linux, first unzip the GTK+ for Windows bundle
into a new `src/win32gtk` directory. Then rename all the
`src/win32gtk/lib/*.dll.a` files to `src/win32/gtk/lib/*.a`, removing the `.dll`
part of the filename. Finally, modify the `CC`, `CPP`, and `WINDRES` variables
in the `WIN32` block of `src/Makefile` to match your MinGW installation and run
`make WIN32=1` to build `../textadept.exe`.

#### Mac OSX

After using `jhbuild`, GTK is in `~/gtk` so make a symlink from `~/gtk/inst` to
`src/gtkosx` in Textadept. Then run `make OSX=1` to build `../textadept.osx`. At
this point it is recommended to build a new `textadept.app` from an existing
one. Download the most recent app and replace `Contents/MacOS/textadept.osx`,
all `.dylib` files in `Contents/Resources/lib`, and all `.so` files in
`Contents/Resources/lib/gtk-2.0/[version]/{engines,immodules,loaders}` with your
own versions in `src/gtkosx/lib`. If you wish, you may also replace the files
in `Contents/Resources/{etc,share}`, but these rarely change.

## Problems

#### Mac OSX

In Mac OSX, if the build fails because of a

    `redefinition of 'struct Sci_TextRange'`

error, you will need to open `src/scintilla/include/Scintilla.h` and comment
out the following lines (put `//` at the start of the line):

    #define CharacterRange Sci_CharacterRange
    #define TextRange Sci_TextRange
    #define TextToFind Sci_TextToFind

# Compiling

## Requirements

The requirements for building Textadept are not quite so minimal.

#### Linux

Linux systems will need the GTK+ development libraries. Your package manager
should allow you to install them. For Debian-based distributions, the package is
typically called `libgtk2.0-dev`. Otherwise, compile and install it from the
[GTK+ website][GTK-Linux]. Additionally you will need the [GNU C compiler][GCC]
(`gcc`) and [GNU Make][Make] (`make`). Both should be available for your Linux
distribution through its package manager.

#### Mac OSX

[XCode][XCode] is needed for Mac OSX as well as the
[GTK-OSX Framework][GTK-OSX-Latest].

#### Windows

Compiling Textadept on Windows is no longer supported. If you wish to do so
however, you will need a C compiler that supports the C99 standard (Microsoft's
does not) and the [GTK+ for Windows bundle][GTK-Win32] and win_iconv libraries.

The preferred way to compile for Windows is cross-compiling from Linux. To do
so, in addition to the GTK+ development libraries mentioned above, you will need
[MinGW][MinGW] with the Windows header files and the Windows [bundle][GTK-Win32]
along with win_iconv. The former should be available from your package manager.
The latter you will have to download manually.

[GTK-Linux]: http://www.gtk.org/download-linux.html
[GCC]: http://gcc.gnu.org
[Make]: http://www.gnu.org/software/make/
[XCode]: http://developer.apple.com/TOOLS/xcode/
[GTK-OSX-Latest]: http://people.imendio.com/richard/stuff/Gtk-Framework-2.14.3-2-test1.dmg
[GTK-Win32]: http://www.gtk.org/download-windows.html
[MinGW]: http://mingw.org

## Download

Download the `textadept_x.x.src.zip`, regardless of what platform you are on.

## Compiling

#### Linux

For Linux systems, simply run `make` in the `src/` directory. The `textadept`
executable will be created in the root directory. You can make a symlink from
it to `/usr/bin/` or elsewhere in your `PATH`.

#### Mac OSX

In Mac OSX, open `xcode/textadept.xcodeproj` in XCode, change the active build
configuration combo box from `Debug` to `Release` (if necessary), click `Build`,
and copy the resulting `xcode/build/Release/textadept.app` to your user or
system `Applications` folder.


#### Windows (Cross-Compiling from Linux)

When cross-compiling from within Linux, first unzip the GTK+ for Windows bundle
into a new `src/win32gtk` directory. Then rename all the
`src/win32gtk/lib/*.dll.a` files to `src/win32/gtk/lib/*.a`, removing the `.dll`
part of the filename. Finally, modify the `CC`, `CPP`, and `WINDRES` variables
in the `WIN32` block of `src/Makefile` to match your MinGW installation and run
`make WIN32=1` to build `../textadept.exe`.

## Problems

#### Mac OSX

In Mac OSX, if the build fails because of a

    `redefinition of 'struct Sci_TextRange'`

error, you will need to open `src/scintilla-st/include/Scintilla.h` and comment
out the following lines (put `//` at the start of the line):

    #define CharacterRange Sci_CharacterRange
    #define TextRange Sci_TextRange
    #define TextToFind Sci_TextToFind

`src/scintilla-st/src/LexLPeg.cxx` may need to have `TextRange tr` changed to
`Sci_TextRange tr` as well.

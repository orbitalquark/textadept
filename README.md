# Textadept

Textadept is a fast, minimalist, and remarkably extensible cross-platform text editor for
programmers. Written in a combination of C, C++, and [Lua][] and relentlessly optimized for
speed and minimalism for more than 12 years, Textadept is an ideal editor for programmers who
want endless extensibility without sacrificing speed and disk space, and without succumbing to
code bloat and a superabundance of features. The application has both a graphical user interface
(GUI) version that runs in a desktop environment, and a terminal version that runs within a
terminal emulator.

![Linux](https://orbitalquark.github.io/textadept/images/linux.png)
![macOS](https://orbitalquark.github.io/textadept/images/macosx.png)
![Windows](https://orbitalquark.github.io/textadept/images/win32.png)
![Terminal](https://orbitalquark.github.io/textadept/images/ncurses.png)

[Lua]: https://lua.org

## Features

* Fast and minimalist.
* Cross platform, and with a terminal version, too.
* Self-contained executable -- no installation necessary.
* Support for over 100 programming languages.
* Unlimited split views.
* Can be entirely keyboard driven.
* Powerful snippets and key commands.
* Code autocompletion and documentation lookup.
* Remarkably extensible, with a heavily documented Application Programming Interface (API).

![Textadept](https://orbitalquark.github.io/textadept/images/splitviews.png)

## Requirements

In its bid for minimalism, Textadept depends on very little to run. On Windows and macOS,
it has no external dependencies. On Linux, the GUI version depends only on either [Qt][] or
[GTK][] (cross-platform GUI toolkits), and the terminal version depends only on a wide-character
implementation of curses like [ncurses][](w). Lua and any other third-party dependencies are
compiled into the application itself.

[Qt]: https://www.qt.io/
[GTK]: https://gtk.org
[ncurses]: https://invisible-island.net/ncurses/ncurses.html

## Download

Textadept releases can be found [here][1]. Select the appropriate package for your platform. A
comprehensive list of changes between releases can be found [here][2]. You can also download
a separate set of modules that provide extra features and functionality to the core application.

[1]: https://github.com/orbitalquark/textadept/releases
[2]: https://orbitalquark.github.io/textadept/changelog.html

## Installation and Usage

Textadept comes with a comprehensive [user manual][] in its *docs/* directory.  It covers all
of Textadept's main features, including installation, usage, configuration, theming, scripting,
and compilation.

Since nearly every aspect of Textadept can be scripted using Lua, the editor's API is heavily
documented. This [API documentation][] is also located in *docs/*. It serves as the ultimate
resource when it comes to scripting the application.

A more structured scripting resource is [Textadept Quick Reference][], which contains a wealth
of knowledge on how to script and configure Textadept. It groups the editor's rich API into
a series of tasks in a convenient and easy-to-use manner. This book serves as the perfect
complement to Textadept's Manual and exhaustive API documentation.

[user manual]: https://orbitalquark.github.io/textadept/manual.html
[API documentation]: https://orbitalquark.github.io/textadept/api.html
[Textadept Quick Reference]: https://orbitalquark.github.io/textadept/book.html

## Compile

Textadept can be built on Windows, macOS, or Linux using [CMake][]. CMake will automatically
detect which platforms you can compile Textadept for (e.g. Qt, GTK, and/or Curses) and build
for them. On Windows and macOS you can then use CMake to create a self-contained application
to run from anywhere. On Linux you can either use CMake to install Textadept, or place compiled
binaries into Textadept's root directory and run it from there.

General Requirements:

* [CMake][] 3.16+
* A C and C++ compiler, such as:
  - [GNU C compiler][] (*gcc*) 7.1+
  - [Microsoft Visual Studio][] 2019+
  - [Clang][] 9+
* A UI toolkit (at least one of the following):
  - [Qt][] 5 development libraries for the GUI version
  - [GTK][] 3 development libraries for the GUI version (GTK 2.24 is also supported)
  - [ncurses][](w) development libraries (wide character support) for the terminal version

Basic procedure:

1. Configure CMake to build Textadept by pointing it to Textadept's source directory (where
   *CMakeLists.txt* is) and specifying a binary directory to compile to.
2. Build Textadept.
3. Either copy the built Textadept binaries to Textadept's directory or use CMake to install it.

For example:

    cmake -S . -B build_dir -D CMAKE_BUILD_TYPE=RelWithDebInfo \
      -D CMAKE_INSTALL_PREFIX=build_dir/install
    cmake --build build_dir -j # compiled binaries are in build_dir/
    cmake --install build_dir # self-contained installation is in build_dir/install/

CMake boolean variables that affect the build:

* `NIGHTLY`: Whether or not to build Textadept with bleeding-edge dependencies (i.e. the nightly
   version). Defaults to off.
* `QT`: Unless off, builds the Qt version of Textadept. The default is auto-detected.
* `GTK3`: Unless off, builds the Gtk 3 version of Textadept. The default is auto-detected.
* `GTK2`: Unless off, builds the Gtk 2 version of Textadept. The default is auto-detected.
* `CURSES`: Unless off, builds the Curses (terminal) version of Textadept. The default is
   auto-detected.

For more information on compiling Textadept, please see the [manual][].

[CMake]: https://cmake.org
[GNU C compiler]: https://gcc.gnu.org
[Microsoft Visual Studio]: https://visualstudio.microsoft.com/
[Clang]: https://clang.llvm.org/
[Qt]: https://www.qt.io
[GTK]: https://gtk.org
[ncurses]: https://invisible-island.net/ncurses/ncurses.html
[manual]: https://orbitalquark.github.io/textadept/manual.html#compiling

## Contribute

Your [donation][] or purchase of the [book][] helps fund Textadept's continuous development.

Textadept is [open source][]. Feel free to discuss features, report bugs, and submit patches. You
can also contact me personally (orbitalquark att triplequasar.com).

[donation]: https://gum.co/textadept
[book]: https://orbitalquark.github.io/textadept/book.html
[open source]: https://github.com/orbitalquark/textadept

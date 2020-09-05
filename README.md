# Textadept

Textadept is a fast, minimalist, and remarkably extensible cross-platform text
editor for programmers. Written in a combination of C and [Lua][] and
relentlessly optimized for speed and minimalism for more than 12 years,
Textadept is an ideal editor for programmers who want endless extensibility
without sacrificing speed and disk space, and without succumbing to code bloat
and a superabundance of features. The application has both a graphical user
interface (GUI) version that runs in a desktop environment, and a terminal
version that runs within a terminal emulator.

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
* Remarkably extensible, with a heavily documented Application Programming
  Interface (API).

## Requirements

In its bid for minimalism, Textadept depends on very little to run. On Windows
and macOS, it has no external dependencies. On Linux and BSD, the GUI version
depends only on [GTK][] (a cross-platform GUI toolkit) version 2.24 or later
(circa early 2011), and the terminal version depends only on a wide-character
implementation of curses like [ncurses][](w).

[GTK]: https://gtk.org
[ncurses]: https://invisible-island.net/ncurses/ncurses.html

## Download

Download Textadept from the project's [download page][] by selecting the
appropriate package for your platform. You can also download a separate set of
modules that provide extra features and functionality to the core application.

[download page]: https://foicica.com/textadept/download

## Installation and Usage

Textadept comes with a comprehensive user manual in its *docs/* directory. This
manual is also available [online][1]. It covers all of Textadept's main
features, including installation, usage, configuration, theming, scripting, and
compilation.

Since nearly every aspect of Textadept can be scripted using Lua, the editor's
API is heavily documented. This documentation is also located in *docs/* and
available [online][2]. It serves as the ultimate resource when it comes to
scripting the application.

A more structured scripting resource is [Textadept Quick Reference][], which
contains a wealth of knowledge on how to script and configure Textadept. It
groups the editor's rich API into a series of tasks in a convenient and
easy-to-use manner. This book serves as the perfect complement to Textadept's
Manual and exhaustive API documentation.

[1]: https://foicica.com/textadept/manual.html
[2]: https://foicica.com/textadept/api.html
[Textadept Quick Reference]: https://foicica.com/textadept/MEDIA.html#Book

## Compile

Textadept is a bit unusual in that building it is only supported on Linux and
BSD. The application is cross-compiled for Windows and macOS from Linux. While
it is certainly possible to compile Textadept natively on those platforms, it is
simply not supported in any official capacity.

Textadept is built from its *src/* directory and binaries are placed in the
application's root directory. The general procedure is to have Textadept build
its dependencies first, and then its binaries. Textadept is self-contained,
meaning you do not have to install it; it can run from its current location.

General Requirements:

* [GNU C compiler][] (*gcc*) 4.9+ (circa early 2014)
* [libstdc++][] version 4.9+
* [GNU Make][] (*make*)
* [GTK][] 2.24+ development libraries for the GUI version
* [ncurses][](w) development libraries (wide character support) for the terminal
  version
* [MinGW][] or [mingw-w64][] 4.9+ (circa early 2014) when cross-compiling for
  Windows.
* [OSX cross toolchain][] _with GCC_ 4.9+ (not Clang) when cross-compiling for
  macOS.
* _**OR**_
* [Docker][]

The following table provides a brief list of `make` rules for building Textadept
on Linux and BSD. (On BSD, substitute `make` with `gmake`.)

Command              |Description
---------------------|-----------
`make deps`          |Downloads and builds all of Textadept's core dependencies
`make deps NIGHTLY=1`|Optionally downloads and builds bleeding-edge dependencies
`make`               |Builds Textadept, provided all dependencies are in place
`make DEBUG=1`       |Optionally builds Textadept with debug symbols
`make curses`        |Builds the terminal version of Textadept
`make win32-deps`    |Downloads and builds Textadept's Windows dependencies
`make win32`         |Cross-compiles Textadept for Windows
`make win32-curses`  |Cross-compiles the terminal version for Windows
`make osx-deps`      |Downloads and builds Textadept's macOS dependencies
`make osx`           |Cross-compiles Textadept for macOS
`make osx-curses`    |Cross-compiles the terminal version for macOS

When building within Docker, the relevant [container image][] is
`textadept/build:v1.0`.

For more information on compiling Textadept, please see the [manual][].

[GNU C compiler]: https://gcc.gnu.org
[libstdc++]: https://gcc.gnu.org
[GNU Make]: https://www.gnu.org/software/make/
[GTK]: https://www.gtk.org
[ncurses]: https://invisible-island.net/ncurses/ncurses.html
[MinGW]: https://mingw.org
[mingw-w64]: https://mingw-w64.org/
[OSX cross toolchain]: https://github.com/tpoechtrager/osxcross
[Docker]: https://www.docker.com/
[container image]: https://hub.docker.com/repository/docker/textadept/build
[manual]: https://foicica.com/textadept/manual.html#Compiling

## Contribute

Your [donation][] or purchase of the [book][] helps fund Textadept's continuous
development.

Textadept is 100% [open source][]. Feel free to discuss features, report bugs,
and submit patches either to the [mailing list][], or to me personally
(mitchell.att.foicica.com).

[donation]: https://gum.co/textadept
[book]: https://foicica.com/textadept/MEDIA.html#Book
[open source]: https://foicica.com/hg/textadept
[mailing list]: http://foicica.com/lists

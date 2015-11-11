# Textadept

## Overview

Textadept is a fast, minimalist, and remarkably extensible cross-platform text
editor for programmers. Written in a combination of C and [Lua][] and
relentlessly optimized for speed and minimalism over the years, Textadept is an
ideal editor for programmers who want endless extensibility without sacrificing
speed or succumbing to code bloat and featuritis.

[Lua]: http://lua.org

## Features

* Self-contained executable -- no installation necessary.
* Entirely keyboard driven.
* Unlimited split views.
* Support for over 80 programming languages.
* Powerful snippets and key commands.
* Code autocompletion and API lookup.
* Unparalleled extensibility.
* Terminal (curses) version.

## Requirements

In its bid for minimalism, Textadept has no dependencies on Windows and Mac OSX
operating systems and depends only on [GTK+ 2.0][] version 2.18 or greater on
Linux. Textadept includes its own copy of Lua on all platforms and bundles in a
GTK+ runtime on Windows and Mac OSX.

The terminal version of Textadept requires only an implementation of curses like
[ncurses][].

[GTK+ 2.0]: http://gtk.org
[ncurses]: http://invisible-island.net/ncurses/ncurses.html

## Download

**Please [donate][] or purchase the [book][] to fund continuous development.**

Download Textadept from the project's [download page][] or from these quick
links:

Stable Builds

* [Win32][]
* [Mac OSX][]
* [Linux][]
* [Linux x86\_64][]
* [Modules][]

Unstable Builds

* [Win32 Nightly][]
* [Mac OSX Nightly][]
* [Linux Nightly][]
* [Linux x86\_64 Nightly][]
* [Modules Nightly][]

_Warning_: nightly builds are untested, may have bugs, and are the absolute
cutting-edge versions of Textadept. Do not use them in production, but for
testing purposes only.

If necessary, you can obtain PGP signatures from the [download page][] along
with a public key in order to verify download integrity. For example on Linux,
after importing the public key via `gpg --import foicica.pgp` and downloading
the appropriate signature, run `gpg --verify [signature]`.

[donate]: http://gum.co/textadept
[book]: MEDIA.html#Book
[download page]: http://foicica.com/textadept/download
[Win32]: download/textadept_LATEST.win32.zip
[Mac OSX]: download/textadept_LATEST.osx.zip
[Linux]: download/textadept_LATEST.i386.tgz
[Linux x86\_64]: download/textadept_LATEST.x86_64.tgz
[Modules]: download/textadept_LATEST.modules.zip
[Win32 Nightly]: download/textadept_NIGHTLY.win32.zip
[Mac OSX Nightly]: download/textadept_NIGHTLY.osx.zip
[Linux Nightly]: download/textadept_NIGHTLY.i386.tgz
[Linux x86\_64 Nightly]: download/textadept_NIGHTLY.x86_64.tgz
[Modules Nightly]: download/textadept_NIGHTLY.modules.zip

## Installation and Usage

Textadept comes with a comprehensive manual and API documentation in the *doc/*
directory. They are also available [online][].

[online]: http://foicica.com/textadept

## Buy the Book

<div style="float: left; margin: 0 1em 0 1em;">
  <a href="MEDIA.html#Book">
    <img src="book/ta_quickref_small.png" alt="" style="border-width: 1px;"/>
  </a>
</div>

[*Textadept Quick Reference*][]

Published: May 2015 <span style="color: #ef373a;">[New!]</span><br/>
Pages: 167

Textadept is a fast, minimalist, and remarkably extensible cross-platform text
editor for programmers. This quick reference contains a wealth of knowledge on
how to script and configure Textadept using the Lua programming language. It
groups the editor's rich API into a series of tasks in a convenient and
easy-to-use manner. [Read more...][]

This book serves as the perfect complement to Textadept's Manual and exhaustive
API documentation.

[*Textadept Quick Reference*]: MEDIA.html#Book
[Read more...]: MEDIA.html#Book

## Contact

Contact me by email: mitchell.att.foicica.com.

There is also a [mailing list][].

[mailing list]: http://foicica.com/lists

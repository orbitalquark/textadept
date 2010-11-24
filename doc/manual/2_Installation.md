# Installation

## Requirements

In its bid for minimalism, Textadept also needs very little to run. In fact, the
only thing it needs is [GTK+ 2.0][GTK2] >= 2.16 on Linux systems. GTK is already
included in Windows and Mac OSX packages. Textadept also has it's own version of
Lua.

Note: for Win32 and Mac OSX, more than 3/4 of the download and unpackaged
application sizes are due to GTK, the cross-platform GUI toolkit Textadept uses.
Textadept itself is much smaller.

[GTK2]: http://gtk.org

#### Linux

Most Linux systems already have GTK+ installed. If not, it is probably available
through your package manager. Otherwise, compile and install it from the
[GTK+ website][GTK-Linux].

[GTK-Linux]: http://www.gtk.org/download-linux.html

#### Mac OSX

Prior to 3.5, the GTK+ [Mac OSX Framework][GTK-OSX] was needed. Newer versions
are all-inclusive and do not require anything.

[GTK-OSX]: http://code.google.com/p/textadept/downloads/detail?name=Gtk-Framework-2.14.3-2-test1.dmg

Note that Textadept is designed for Intel Leopard+ Macs.

#### Windows

Prior to 3.5, the [GTK+ 2.0 Runtime][GTK-Runtime] was needed. Newer versions are
all-inclusive and do not require anything.

[GTK-Runtime]: http://sourceforge.net/projects/gtk-win/

## Download

Textadept can be downloaded from the [project page][Download]. Select the
appropriate package for your platform.

[Download]: http://textadept.googlecode.com/

## Installation

#### Linux and Windows

For Linux and Windows machines, simply unpack the archive anywhere and you are
ready to go.

#### Mac OSX

For Mac OSX machines, unpack the archive and move `textadept.app` to your user
or system `Applications` directory like any other application.

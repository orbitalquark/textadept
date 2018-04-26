# Technology

Textadept is composed of many different technologies, which are briefly listed
in the following sections.

## User Interface

Textadept's user interface consists of a graphical user interface (GUI) and a
terminal user interface (TUI).

=[GTK+][] - GIMP Toolkit=
    Textadept uses GTK as its cross-platform GUI toolkit.

=[ncurses][], [pdcurses][] - Libraries for displaying terminal applications=
    Textadept uses ncurses as its Linux, MacOSX, and BSD terminal UI, and uses
    pdcurses as its Windows terminal UI.

=[gtDialog][]\* - Cross-platform tool for creating interactive dialogs=
    Textadept uses gtDialog for displaying interactive GUI and TUI dialogs.

=[cdk][] - Widget library for terminal applications=
    Textadept uses cdk for drawing terminal UI widgets.

=[libtermkey][] - Library for processing keyboard entry for terminal apps=
    Textadept uses libtermkey for advanced keyboard entry handling.

## Editor

Textadept's core text editing component is Scintilla.

=[Scintilla][] - Scintilla=
    Textadept uses Scintilla as its core text editing component.

## Scripting

Textadept uses Lua as its scripting language. The editor is primarily written in
Lua and includes a few external libraries.

=[Lua][] - Lua Programming Language=
    Textadept uses Lua as its internal scripting language. Most of Textadept is
    written in Lua.

=[LPeg][] - Parsing Expression Grammars for Lua=
    Textadept uses LPeg in its Scintilla lexers.

=[LuaFileSystem][] - Library for accessing directories and file attributes=
    Textadept uses LFS for accessing the host filesystem.

=[lspawn][]\* - Lua module for spawning processes=
    Textadept uses lspawn for spawning asynchronous processes.

\* A Foicica.com project.

[GTK+]: http://www.gtk.org
[Scintilla]: http://scintilla.org
[Lua]: http://www.lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[LuaFileSystem]: http://keplerproject.github.io/luafilesystem/
[lspawn]: http://foicica.com/hg/lspawn
[gtDialog]: http://foicica.com/gtdialog/
[ncurses]: http://invisible-island.net/ncurses/
[pdcurses]: http://pdcurses.sourceforge.net/
[cdk]: http://invisible-island.net/cdk/
[libtermkey]: http://www.leonerd.org.uk/code/libtermkey/

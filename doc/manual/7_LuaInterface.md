# Lua Interface

After startup, Textadept relinquishes control to Lua. At this point, having a
Manual is pointless since all of Textadept's functionality is dynamic from here
on out. This is where the most important resource for help comes in: the
[LuaDoc][LuaDoc]. It contains not only documentation for Textadept's Lua API,
but documentation for all of its modules and features as well. It is more up to
date than a manual like this could ever be.

[LuaDoc]: ../index.html

## Global Variables

The following global variables not mentioned in the LuaDoc are available in
Textadept's Lua state:

* `_HOME`: Path to the directory containing Textadept.
* `_LEXERPATH`: Paths to lexers, formatted like [`package.path`][package_path].
* `_RELEASE`: The Textadept release version.
* `_THEME`: The [theme][theme] file to use.
* `_USERHOME`: Path to the user's `~/.textadept/`.
* `MAC`: If Textadept is running on Mac OSX, this flag is `true`.
* `_CHARSET`: The character set encoding of the filesystem. This is used in
  [File I/O][file_io].
* `RESETTING`: If [`textadept.reset()`][textadept_reset] has been called, this
  flag is `true` while the Lua state is being re-initialized.
* `WIN32`: If Textadept is running on Windows, this flag is `true`.
* `arg`: Table containing the command line arguments passed to Textadept.

[package_path]: http://www.lua.org/manual/5.1/manual.html#pdf-package.path
[theme]: 6_Startup.html
[file_io]: ../modules/textadept.io.html
[textadept_reset]: ../modules/textadept.html#reset

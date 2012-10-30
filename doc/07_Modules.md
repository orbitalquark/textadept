# Modules

Most of Textadept's functionality comes from Lua modules. Essentially there are
two classes of module: generic and language-specific. A generic module provides
features for all programming languages while a language-specific module provides
features for a specific programming language.

## Generic

Generic modules have a broad scope and are usually available for programming in
all languages or writing plain-text. An example is the [textadept module][]
which implements most of Textadept's functionality (find & replace, key
bindings, menus, snippets, etc.). These kinds of modules are generally loaded on
startup. See the [preferences][] page for instructions on how to load generic
modules when Textadept starts.

[textadept module]: api/_M.textadept.html
[preferences]: 08_Preferences.html#Loading.Modules

## Language-Specific

Language-specific modules have a scope limited to a single programming language.
The name of the module is named after the language's lexer in the *lexers/*
directory and is automatically loaded when editing source code in that
particular language. In addition to some of the editing features discussed
[earlier][], these kinds of modules typically also have shell commands for
running and compiling code, indentation settings, custom key bindings, and
perhaps a custom context menu. These features are discussed below.

[earlier]: 06_AdeptEditing.html#Source.Code.Editing

### Compile and Run

Most language-specific modules have a command that compiles and/or runs the code
in the current file. Pressing `Ctrl+Shift+R` (`⌘⇧R` on Mac OSX | `M-^R` in
ncurses) executes the command for compiling code and `Ctrl+R` (`⌘R` | `^R`)
executes the command for running code. Double-clicking on any error messages
will jump to where the errors occurred. Note: In order for these features to
work, the language you are working with must have its compile and run commands
and error format defined. If the language-specific module does not exist or does
not [define][] commands or an error format, it can be done [manually][] in your
[user-init file][].

[define]: api/_M.html#Compile.and.Run
[manually]: http://foicica.com/wiki/run-supplemental
[user-init file]: 08_Preferences.html#User.Init

### Buffer Properties

Some programming languages have style guidelines for indentation and/or line
endings which differ from Textadept's defaults. In this case, language-specific
modules [set][] these preferences. If you wish to change them or use your own
preferences, see the [language module preferences][] section.

[set]: api/_M.html#Buffer.Properties
[language module preferences]: 08_Preferences.html#Language-Specific

### Key Bindings

Most language-specific modules have a set of key bindings for
[custom commands][]. See the module's [LuaDoc][] or code to find out which key
bindings are assigned. They are typically stored in the `Ctrl+L` (`⌘L` on Mac
OSX | `M-L` in ncurses) key chain prefix.

[custom commands]: api/_M.html#Commands
[LuaDoc]: api/index.html

### Context Menu

Some language-specific modules add extra actions to the context menu.
Right-click inside the view to bring up this menu.

## Getting Modules

The officially supported language modules are hosted [here][] and are available
as a separate download. To upgrade to the most recent version of a module, you
can either use [Mercurial][] (run `hg pull` and then `hg update` on or from
within the module) or download a zipped version from the module's repository
homepage and overwrite the existing one.

For now, user-created modules are obtained from the [wiki][].

[here]: http://foicica.com/hg
[Mercurial]: http://mercurial.selenic.com
[wiki]: http://foicica.com/wiki/textadept

## Installing Modules

If you do not have write permissions for the directory Textadept is installed
in, place the module in your *~/.textadept/modules/* folder and replace all
instances of `_HOME` with `_USERHOME` in the module's *init.lua*. It is
recommended to put all custom or user-created modules in your
*~/.textadept/modules/* directory so they will not be overwritten when you
update Textadept. Also, modules in that directory override any modules in
Textadept's  *modules/* directory. This means that if you have your own *lua*
module, it will be loaded instead of the one that comes with Textadept.

## Developing Modules

See the [module LuaDoc][].

[module LuaDoc]: api/_M.html

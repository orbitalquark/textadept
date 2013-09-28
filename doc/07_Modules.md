# Modules

Most of Textadept's functionality comes from Lua modules loaded on startup. An
example is the [textadept module][] which implements most of Textadept's
functionality (find & replace, key bindings, menus, snippets, etc.) See the
[preferences][] page for instructions on how to load your own modules on
startup.

Textadept also recognizes a special kind of module: a language module. Language
modules provide functionality specific to their respective programming
languages.

[textadept module]: api/textadept.html
[preferences]: 08_Preferences.html#Loading.Modules

## Language Modules

Language modules have a scope limited to a single programming language. The
module's name matches the language's lexer in the *lexers/* directory. Textadept
automatically loads the module when editing source code in that particular
language. In addition to the source code editing features discussed previously,
these kinds of modules typically also define indentation settings, custom key
bindings, and perhaps a custom context menu. The manual discusses these features
below.

### Buffer Properties

Some programming languages have style guidelines for indentation and/or line
endings which differ from Textadept's defaults. In this case, language modules
[set][] these preferences. You can do so manually with your
[language module preferences][].

[set]: api/_M.html#Buffer.Properties
[language module preferences]: 08_Preferences.html#Language

### Key Bindings

Most language modules assign a set of key bindings to [custom commands][]. The
module's [LuaDoc][] or code lists which key bindings map to which commands. The
`Ctrl+L` (`⌘L` on Mac OSX | `M-L` in curses) key chain prefix typically houses
them.

[custom commands]: api/_M.html#Commands
[LuaDoc]: api/index.html

### Context Menu

Some language modules add extra actions to the context menu. Right-click inside
the view to bring up this menu.

## Getting Modules

Textadept has a set of officially supported language modules available as a
separate download from the Textadept downloads page with their sources hosted
[here][]. To upgrade to the most recent version of a module, either use
[Mercurial][] (run `hg pull` and then `hg update` on or from within the module)
or download a zipped version from the module's repository homepage and overwrite
the existing one.

For now, the [wiki][] hosts third-party, user-created modules.

[here]: http://foicica.com/hg
[Mercurial]: http://mercurial.selenic.com
[wiki]: http://foicica.com/wiki/textadept

## Installing Modules

If you do not have write permissions in Textadept's installed location, place
the module in your *~/.textadept/modules/* folder and replace all instances of
`_HOME` with `_USERHOME` in the module's *init.lua*. Putting all custom or
user-created modules in your *~/.textadept/modules/* directory prevents the
possibility of overwriting them when you update Textadept. Also, modules in that
directory override any modules in Textadept's *modules/* directory. This means
that if you have your own *lua* module, Textadept loads that one instead of its
own.

## Developing Modules

See the [module LuaDoc][].

[module LuaDoc]: api/_M.html

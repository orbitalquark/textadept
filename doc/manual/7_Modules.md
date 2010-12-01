# Modules

Most of Textadept's functionality comes from modules written in Lua. A module
consists of a single directory with an `init.lua` script to load any additional
Lua files (typically in the same location). Essentially there are two classes of
module: generic and language-specific.

## Generic

This class of modules is usually available globally for programming in all
languages or writing plain-text. An example is the
[textadept](../modules/_m.textadept.html) module which implements most of
Textadept's functionality (find/replace, key commands, menus, snippets, etc.).
These kinds of modules are generally loaded on startup. See the
[preferences](9_Preferences.html#user_init) page for instructions on how to load
generic modules when Textadept starts.

## Language Specific

Each module of this class of modules is named after a language lexer in the
`lexers/` directory and is only available only for editing code in that
particular programming language unless you specify otherwise. Examples are the
[cpp](../modules/_m.cpp.html) and [lua](../modules/_m.lua.html) modules which
provide special editing features for the C/C++ and Lua languages respectively.

#### Lexer

All languages have a [lexer](../modules/lexer.html) that performs syntax
highlighting on the source code. While the lexer itself is not part of the
module, its existence in `lexers/` is required.

#### Activation

Language-specific modules are automatically loaded when a file of that language
is loaded or a buffer's lexer is set to that language.

#### Snippets

Most language-specific modules have a set of
[snippets](../modules/_m.textadept.snippets.html). Press `Ctrl+Alt+Shift+I`
(`Ctrl+Apple+Shift+I` on Mac OSX) for a list of available snippets or see the
module's Lua code. To insert a snippet, type its trigger followed by the `Tab`
key. Subsequent presses of `Tab` causes the caret to enter tab stops in
sequential order, `Shift+Tab` goes back to the previous tab stop, and
`Ctrl+Alt+I` (`Ctrl+Apple+I` on Mac OSX) cancels the current snippet. Snippets
can be nested (inserted from within another snippet).

![Snippet](images/snippet.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Snippet Expanded](images/snippet2.png)

#### Commands

Most language-specific modules have a set of [key
commands](../modules/_m.textadept.keys.html). See the module's Lua code for
which key commands are available.

##### Run

Most language-specific modules have a command that runs the code in the current
file. Pressing `Ctrl+R` runs that command.

##### Compile

Most language-specific modules have a command that compiles the code in the
current file. Pressing `Ctrl+Shift+R` runs that command.

##### Block Comments

Pressing `Ctrl+Q` comments or uncomments the code on the selected lines.

#### Buffer Properties

Sometimes language-specific modules set default buffer properties like tabs and
indentation size. See the module's Lua code for these settings and change them
if you prefer something else.

## Getting Modules

For now, user-created modules are obtained from the
[wiki](http://caladbolg.net/textadeptwiki).

## Installing Modules

It is recommended to put all modules in your `~/.textadept/modules/` directory
so they will not be overwritten when you update Textadept. Modules in that
directory override any modules in Textadept's `modules/` directory. This means
that if you have your own `lua` module, it will be loaded instead of the one
that comes with Textadept.

## Developing Modules

See the [LuaDoc](../modules/_m.html) for modules.

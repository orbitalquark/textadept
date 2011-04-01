# Preferences

At this point it is assumed you are at least familiar with the basics of
[Lua](http://www.lua.org). You do not have to know a lot of the language to
configure Textadept.

## User Init

Textadept loads modules from your `~/.textadept/init.lua` on startup. If this
file does not exist, Textadept creates it with a list of default modules to
load. You can then use the file to indicate what else you want Textadept to
load. For example if you created a generic module called `foo` that you wanted
to load alongside the default modules, your `~/.textadept/init.lua` would
contain

    require 'textadept'
    require 'foo'

If instead you wanted to load all Textadept's default modules except for the
menu, replace

    require 'textadept'

with

    require 'textadept.adeptsense'
    require 'textadept.bookmarks'
    require 'textadept.command_entry'
    require 'textadept.editing'
    require 'textadept.find'
    require 'textadept.filter_through'
    require 'textadept.mime_types'
    require 'textadept.run'
    require 'textadept.session'
    require 'textadept.snapopen'
    require 'textadept.snippets'

    --require 'textadept.menu'
    require 'textadept.keys'

Note that his list was obtained from the `textadept` module's `init.lua` which
is located in the `modules/textadept/` directory.

It is important to realize that Textadept will not load anything you do not tell
it to. If your `~/.textadept/init.lua` exists and is empty, no modules are
loaded (pretty much rendering Textadept useless).

#### Module Settings

Many of Textadept's modules have settings you can change from your
`~/.textadept/init.lua`. These settings are viewed from module's
[LuaDoc](../index.html). For example, to disable character autopairing and
whitespace stripping on save, your `~/.textadept/init.lua` might look like:

    require 'textadept'

    _m.textadept.editing.AUTOPAIR = false
    _m.textadept.editing.SAVE_STRIPS_WS = false

#### Other

Your `~/.textadept/init.lua` is not restricted to just loading modules or
setting preferences. It is just Lua code that is run when Textadept loads. For
more information, see the [scripting](11_Scripting.html) page.

##### Snippets

You can add global snippets to `_G.snippets` such as:

    _G.snippets['file'] = '%<buffer.filename>'
    _G.snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` will insert the snippet.

##### Key Commands

It is not recommended to edit Textadept's `modules/textadept/keys.lua` for
changing the key bindings since your changes could be overwritten when updating
Textadept. Instead, modify `_G.keys` from within your `~/.textadept/init.lua` or
from a file loaded by `~/.textadept/init.lua`. For example maybe you want
`Alt+N` to create a new buffer instead of `Ctrl+N`:

    _G.keys.an = new_buffer
    _G.keys.cn = nil

## Locale

Most messages displayed by Textadept are localized. `core/locale.conf` contains
these messages. By default, Textadept is localized in English. To use a
different language, put a translated version of `core/locale.conf` in your
`~/.textadept/` folder.

Feel free to translate Textadept and send your modified `locale.conf` files
to me. I will make them available to other users.

## Mime Types

Textadept recognizes a wide range of programming language files by any of the
following:

* File extension.
* Keywords in the file's shebang (`#!/path/to/exe`) line.
* A pattern that matches the text of the file's first line.

Built-in mime-types are located in `modules/textadept/mime_types.conf`. You
can override or add to them in your `~/.textadept/mime_types.conf`:

    % Recognize .luadoc files as Lua code.
    luadoc lua

    % Change .html files to be recognized as XML files instead of HTML ones.
    html xml

It is not recommended to edit Textadept's `modules/textadept/mime_types.conf`
because your changes may be overwritten when updating Textadept.

#### Detection by File Extension

    file_ext lexer

Note: `file_ext` should not start with a `.` (period).

#### Detection by Shebang Keywords

    #shebang_word lexer

Examples of `shebang_word`'s are `lua`, `ruby`, `python`.

#### Detection by Pattern

    /pattern lexer

Only the last space, the one separating the pattern from the lexer, is
significant. No spaces in the pattern need to be escaped.

## Default Run and Compile Commands and Block Quotes for Languages

Textadept does not come with language-specific modules for all languages so you
can add run commands, compile commands, and block quotes manually:

* [Run/Compile commands](http://caladbolg.net/textadeptwiki/index.php?n=Main.RunSupplemental)
* [Block Quotes](http://caladbolg.net/textadeptwiki/index.php?n=Main.CommentSupplemental)

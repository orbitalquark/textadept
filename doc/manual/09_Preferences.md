# Preferences

At this point it is assumed you are at least familiar with the basics of
[Lua][]. You do not have to know a lot of the language to configure Textadept.

[Lua]: http://www.lua.org

## User Init

Textadept loads modules from your `~/.textadept/init.lua` on startup. If this
file does not exist, Textadept creates it with a list of default modules to
load. You can then use the file to indicate what else you want Textadept to
load. For example if you created a generic module called `foo` that you wanted
to load alongside the default modules, your `~/.textadept/init.lua` would
contain

    require 'textadept'
    _M.foo = require 'foo'

Please note that the `textadept` module populates the `_M.textadept` table
itself because of internal dependencies. Normally, modules do not do this, hence
why `_M.foo = require 'foo'` is used.

If instead you wanted to load all of Textadept's default modules except for the
menu, copy the `textadept` module's `init.lua` (located in the
`modules/textadept/` directory) to `~/.textadept/modules/textadept/` and change

    M.menu = require 'textadept.menu'

to

    --M.menu = require 'textadept.menu'

Of course if you prefer, you can put the relevant code directly in
`~/.textadept/init.lua` instead.

It is important to realize that Textadept will not load anything you do not tell
it to. If your `~/.textadept/init.lua` exists and is empty, no modules are
loaded (pretty much rendering Textadept useless).

### Module Settings

Many of Textadept's modules have settings you can change from your
`~/.textadept/init.lua`. These settings are viewed from module's
[LuaDoc][]. For example, to disable character autopairing and
whitespace stripping on save, your `~/.textadept/init.lua` might look like:

    require 'textadept'

    _M.textadept.editing.AUTOPAIR = false
    _M.textadept.editing.STRIP_WHITESPACE_ON_SAVE = false

[LuaDoc]: ../api/index.html

### Other

Your `~/.textadept/init.lua` is not restricted to just loading modules or
setting preferences. It is just Lua code that is run when Textadept loads. For
more information, see the [scripting][] page.

[scripting]: 11_Scripting.html

#### Snippets

You can add global snippets to `snippets` such as:

    snippets['file'] = '%<buffer.filename>'
    snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` (`⇥` on Mac OSX) will insert
the snippet.

#### Key Commands

It is not recommended to edit Textadept's `modules/textadept/keys.lua` for
changing the key bindings since your changes could be overwritten when updating
Textadept. Instead, modify `keys` from within your `~/.textadept/init.lua` or
from a file loaded by `~/.textadept/init.lua`. For example maybe you want
`Ctrl+Shift+C` to create a new buffer instead of `Ctrl+N`:

    keys.cC = new_buffer
    keys.cn = nil

## Locale

Most messages displayed by Textadept are localized. `core/locale.conf` contains
these messages. By default, Textadept is localized in English. To use a
different language, put a translated version of `core/locale.conf` in your
`~/.textadept/` folder. Translations are located in `core/locales/`.

Feel free to translate Textadept and send your modified `locale.conf` files
to me. I will include them in future releases.

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

### Detect by File Extension

    file_ext lexer

Note: `file_ext` should not start with a `.` (period).

### Detect by Shebang Keywords

    #shebang_word lexer

Examples of `shebang_word`'s are `lua`, `ruby`, `python`.

### Detect by Pattern

    /pattern lexer

Only the last space, the one separating the pattern from the lexer, is
significant. No spaces in the pattern need to be escaped.

## More Language Preferences

Textadept does not come with language-specific modules for all languages so you
can add run commands, compile commands, and block quotes manually:

* [Run/Compile commands][]
* [Block Quotes][]

[Run/Compile commands]: http://caladbolg.net/textadeptwiki/index.php?n=Main.RunSupplemental
[Block Quotes]: http://caladbolg.net/textadeptwiki/index.php?n=Main.CommentSupplemental

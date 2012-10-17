# Preferences

At this point it is assumed you are at least familiar with the basics of
[Lua][]. You do not have to know a lot of the language to configure Textadept.

[Lua]: http://www.lua.org

## User Init

Textadept executes a `~/.textadept/init.lua`, your user-init file, on startup.
If this file does not exist, Textadept creates it for you. You can use the file
to indicate what you want Textadept to do when the application starts. At first,
it simply loads a module that contains most of Textadept's functionality.
However, you are not restricted to just loading modules. You can run any Lua
code you desire. It is important to realize that Textadept will not load
anything you do not tell it to. If your `~/.textadept/init.lua` exists and is
empty, no modules are loaded (pretty much rendering Textadept useless).

## Modules

It is never recommended to modify the default modules that come with Textadept,
even if you just want to change an option in a generic module, modify the buffer
settings for a language-specific module, edit file types, or just add a small
bit of custom code. Those changes may be overwritten when you upgrade Textadept
to a newer version. Instead you have two options: load your own module instead
of the default one, or run your custom module code after the default module
loads. To load your own module, simply place it appropriately in
`~/.textadept/modules/`. To run your module code after a default generic module
loads, put your code in `~/.textadept/init.lua`. To run your module code after a
default language-specific module loads, create a `post_init.lua` Lua script in
the appropriate `~/.textadept/modules/` module folder.

### Generic

Many of Textadept's generic modules have settings you can change from
`~/.textadept/init.lua` after the module is loaded. These settings are viewed
from module's [LuaDoc][]. For example, to disable character autopairing and
stripping whitespace on save, your `~/.textadept/init.lua` might look like:

    _M.textadept = require 'textadept'

    _M.textadept.editing.AUTOPAIR = false
    _M.textadept.editing.STRIP_WHITESPACE_ON_SAVE = false

Now suppose you wanted to load all of Textadept's default modules except for the
menu. Copy the `textadept` module's `init.lua` (located in the
`modules/textadept/` directory) to `~/.textadept/modules/textadept/` and change

    M.menu = require 'textadept.menu'

to

    --M.menu = require 'textadept.menu'

Now when Textadept looks for `modules/textadept/init.lua`, it will load yours
instead of its own, and load everything but the menu. If instead you wanted to
completely change the menu structure, you would first create a new `menu.lua`
and then put it in `~/.textadept/modules/textadept/`. Textadept will now load
your `menu.lua` instead of its own.

[LuaDoc]: api/index.html

### Language-Specific

Similar to generic modules, putting your own language-specific module in
`~/.textadept/modules/` causes Textadept to load that module for editing the
language's code instead of the default one in `modules/` (if the latter exists).
For example, copying the default Lua language-specific module from
`modules/lua/` to `~/.textadept/modules/` causes Textadept to use that module
for editing Lua code instead of the default one. If you make custom changes to
these kinds of copies of language-specific modules, you will likely want to
update them with each new Textadept release. Instead of potentially wasting time
merging your changes, you can run custom code independent of a module in the
module's `post_init.lua` file. For example, instead of copying the `lua` module
and changing its `set_buffer_properties()` function to use tabs, you can do this
from `~/.textadept/modules/lua/post_init.lua`:

    function _M.lua.set_buffer_properties()
      buffer.use_tabs = true
    end

Similarly, you can use `post_init.lua` to change the module's
[compile and run][] commands, load more [Adeptsense tags][], and add additional
[key bindings](#Key.Bindings) and [snippets](#Snippets) (instead of in
`~/.textadept/init.lua`). For example:

    _M.textadept.run.run_command.lua = 'lua5.2'
    _M.lua.sense:load_ctags('/path/to/my/projects/tags')
    keys.lua['c\n'] = function()
      buffer:line_end() buffer:add_text('end') buffer:new_line()
    end
    snippets.lua['ver'] = '%<_VERSION>'

[compile and run]: 07_Modules.html#Compile.and.Run
[Adeptsense tags]: api/_M.textadept.adeptsense.html#load_ctags

### Loading Modules

Suppose you created or downloaded a generic module called `foo` that you wanted
to load along with the default modules Your `~/.textadept/init.lua` would
contain the following:

    _M.textadept = require 'textadept'
    _M.foo = require 'foo'

Language-specific modules are loaded automatically by Textadept when a source
file of that language is opened. No additional action is required after
installing the module.

### Key Bindings

For simple changes to key bindings, `~/.textadept/init.lua` is a good place to
put them. For example, maybe you want `Ctrl+Shift+C` to create a new buffer
instead of `Ctrl+N`:

    keys.cC = new_buffer
    keys.cn = nil

If you plan on redefining most key bindings, you would probably want to copy or
create a new `keys.lua` and then put it in `~/.textadept/modules/textadept/`.
You can learn more about key bindings and how to define them in the
[key bindings LuaDoc][].

[key bindings LuaDoc]: api/keys.html

### Snippets

You can add global snippets in `~/.textadept/init.lua`, such as:

    snippets['file'] = '%<buffer.filename>'
    snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` (`⇥` on Mac OSX | `Tab` in
ncurses) will insert the snippet, regardless of the current programming
language. You can learn about snippet syntax in the [snippets LuaDoc][].

[snippets LuaDoc]: api/_M.textadept.snippets.html

## Locale

Textadept attempts to auto-detect your locale settings using the `LANG`
environment variable. If it is unsuccessful, the English locale is used by
default. To set the locale manually, copy the desired locale file from the
`core/locales/` folder to `~/.textadept/locale.conf`. If your language is not
yet supported by Textadept, please translate the English messages in
`core/locale.conf` to your language and send the modified `locale.conf` file to
[me][]. I will include it in a future release.

[me]: README.html#Contact

## File Types

Textadept recognizes a wide range of programming language files by any of the
following:

* File extension.
* Keywords in the file's shebang (`#!/path/to/exe`) line.
* A pattern that matches the text of the file's first line.

Built-in file types are located in `modules/textadept/mime_types.conf`. You
can override or add to them in your `~/.textadept/mime_types.conf`:

    % Recognize .luadoc files as Lua code.
    luadoc lua

    % Change .html files to be recognized as XML files instead of HTML ones.
    html xml

### Detect by Extension

The syntax for mapping a file extension to a lexer is:

    file_ext lexer

Note: `file_ext` should not start with a `.` (period).

### Detect by Shebang

The syntax for mapping a word contained in a shebang line (the first line of a
file whose first two characters are `#!`) to a lexer is:

    #shebang_word lexer

Examples of `shebang_word`s are `lua`, `ruby`, `python` which match lines like
`#!/usr/bin/lua`, `#!/usr/env/ruby`, and `#!/usr/bin/python3`, respectively.

### Detect by Pattern

The syntax for mapping a Lua pattern that matches the first line of a file to a
lexer is:

    /pattern lexer

[Lua pattern syntax][] is used. Only the last space, the one separating the
pattern from the lexer, is significant. No spaces in the pattern need to be
escaped.

[Lua pattern syntax]: 14_Appendix.html#Lua.Patterns

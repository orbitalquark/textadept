# Preferences

At this point it is assumed you are at least familiar with the basics of
[Lua][]. You do not have to know a lot of the language to configure Textadept.

[Lua]: http://www.lua.org

## User Init

Textadept executes a *~/.textadept/init.lua*, your user-init file, on startup.
If this file does not exist, Textadept creates it for you. You can use the file
to indicate what you want Textadept to do when the application starts, such as
changing the settings of existing modules, loading new ones, and/or running
plain Lua code.

### Modules

It is never recommended to modify the default modules that come with Textadept,
even if you just want to change an option in a generic module, modify the buffer
settings for a language-specific module, edit file types, or add a small bit of
custom code. Those changes may be overwritten when you upgrade Textadept to a
newer version. Instead you have two options: load your own module instead of the
default one, or run your custom module code after the default module loads. For
the most part you will want to use the second option because it is simpler and
more compatible with future releases. Both options are discussed below in the
context of generic and language-specific modules.

#### Generic

Many of Textadept's generic modules have settings you can change from
*~/.textadept/init.lua* after the module is loaded. These settings are viewed
from module's [LuaDoc][]. For example, to disable character autopairing with
typeover and stripping whitespace on save, your *~/.textadept/init.lua* would
contain:

    _M.textadept.editing.AUTOPAIR = false
    _M.textadept.editing.TYPEOVER_CHARS = false
    _M.textadept.editing.STRIP_WHITESPACE_ON_SAVE = false

Now suppose you wanted to load all of Textadept's default modules except for the
menu. You cannot do this after-the-fact from *~/.textadept/init.lua*. Instead
you need Textadept to load your own module rather than the default one. Copy the
`textadept` module's *init.lua* (located in the *modules/textadept/* directory)
to *~/.textadept/modules/textadept/* and change

    M.menu = require 'textadept.menu'

to

    --M.menu = require 'textadept.menu'

Now when Textadept looks for *modules/textadept/init.lua*, it will load yours
in place of its own, and load everything but the menu. If instead you wanted to
completely change the menu structure, you would first create a new *menu.lua*
and then put it in *~/.textadept/modules/textadept/*. Textadept will now load
your *menu.lua* rather than its own.

[LuaDoc]: api/index.html

#### Language-Specific

Similar to generic modules, putting your own language-specific module in
*~/.textadept/modules/* causes Textadept to load that module for editing the
language's code instead of the default one in *modules/* (if the latter exists).
For example, copying the default Lua language-specific module from
*modules/lua/* to *~/.textadept/modules/* causes Textadept to use that module
for editing Lua code in place of the default one. However, if you make custom
changes to that module and upgrade Textadept later, the module may no longer be
compatible. Rather than potentially wasting time merging changes, you can run
custom code independent of a module in the module's *post_init.lua* file. For
example, instead of copying the `lua` module and creating an
`events.LANGUAGE_MODULE_LOADED` event handler to use tabs, you can do this from
*~/.textadept/modules/lua/post_init.lua*:

    events.connect(events.LANGUAGE_MODULE_LOADED, function(lang)
      if lang == 'lua' then buffer.use_tabs = true end
    end)

Similarly, you can use *post_init.lua* to change the module's
[compile and run][] commands, load more [Adeptsense tags][], and add additional
[key bindings](#Key.Bindings) and [snippets](#Snippets) (instead of in
*~/.textadept/init.lua*). For example:

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
to load along with the default modules Your *~/.textadept/init.lua* would
contain the following:

    _M.foo = require 'foo'

Language-specific modules are loaded automatically by Textadept when a source
file of that language is opened. No additional action is required after
installing the module.

### Key Bindings

For simple changes to key bindings, *~/.textadept/init.lua* is a good place to
put them. For example, maybe you want `Ctrl+Shift+C` to create a new buffer
instead of `Ctrl+N`:

    keys.cC = new_buffer
    keys.cn = nil

If you plan on redefining most key bindings, you would probably want to copy or
create a new *keys.lua* and then put it in *~/.textadept/modules/textadept/*.
You can learn more about key bindings and how to define them in the
[key bindings LuaDoc][].

[key bindings LuaDoc]: api/keys.html

### Snippets

You can add global snippets in *~/.textadept/init.lua*, such as:

    snippets['file'] = '%<buffer.filename>'
    snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` (`⇥` on Mac OSX | `Tab` in
curses) will insert the snippet, regardless of the current programming language.
You can learn about snippet syntax in the [snippets LuaDoc][].

[snippets LuaDoc]: api/_M.textadept.snippets.html

## Buffer Settings

Since *~/.textadept/init.lua* is only run once on startup, it is not the
appropriate place to set per-buffer properties like indentation size or
view-related properties like the behaviors for scrolling and autocompletion.
If you do set such properties in *~/.textadept/init.lua*, those settings only
apply to the first buffer and view -- subsequent buffers and split views will
not inherit those settings. Instead, put your settings in a
*~/.textadept/settings.lua* file which is run each time a new buffer or split
view is created. Any settings there override Textadept's default *settings.lua*
settings. For example, to use tabs rather than spaces and have a tab size of 4
spaces by default your *~/.textadept/settings.lua* would contain:

    buffer.tab_width = 4
    buffer.use_tabs = true

(Remember that in order to have per-filetype properties, you need to have a
[language-specific module][].)

You can use Textadept's *settings.lua* as a reference to see what properties are
available. It also has many commented out properties that you can copy to your
*~/.textadept/settings.lua* and uncomment to turn on or change the value of. You
can use [Adeptsense][] to view a property's documentation or read the
[LuaDoc][].

[language-specific module]: 07_Modules.html#Buffer.Properties
[Adeptsense]: 06_AdeptEditing.html#Adeptsense
[LuaDoc]: api/buffer.html

## Locale

Textadept attempts to auto-detect your locale settings using the "$LANG"
environment variable. If it is unsuccessful, the English locale is used by
default. To set the locale manually, copy the desired locale file from the
*core/locales/* folder to *~/.textadept/locale.conf*. If your language is not
yet supported by Textadept, please translate the English messages in
*core/locale.conf* to your language and send the modified *locale.conf* file to
[me][]. I will include it in a future release.

[me]: README.html#Contact

## File Types

Textadept recognizes a wide range of programming language files by any of the
following:

* File extension.
* Keywords in the file's shebang ("#!/path/to/exe") line.
* A pattern that matches the text of the file's first line.

Built-in file types are located in *modules/textadept/mime_types.conf*. You
can override or add to them in your *~/.textadept/mime_types.conf*:

    % Recognize .luadoc files as Lua code.
    luadoc lua

    % Change .html files to be recognized as XML files.
    html xml

### Detect by Extension

The syntax for mapping a file extension to a lexer is:

    file_ext lexer

Note: `file_ext` should not start with a '.' (period).

### Detect by Shebang

The syntax for mapping a word contained in a shebang line (the first line of a
file whose first two characters are "#!") to a lexer is:

    #shebang_word lexer

Examples of `shebang_word`s are "lua", "ruby", "python" which match lines like
"#!/usr/bin/lua", "#!/usr/env/ruby", and "#!/usr/bin/python3", respectively.

### Detect by Pattern

The syntax for mapping a Lua pattern that matches the first line of a file to a
lexer is:

    /pattern lexer

[Lua pattern syntax][] is used. Only the last space, the one separating the
pattern from the lexer, is significant. No spaces in the pattern need to be
escaped.

[Lua pattern syntax]: 14_Appendix.html#Lua.Patterns

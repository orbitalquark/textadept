# Preferences

At this point the manual assumes you are at least familiar with the basics of
[Lua][]. You do not have to know a lot of the language to configure Textadept.

[Lua]: http://www.lua.org

## User Init

Textadept executes a *~/.textadept/init.lua*, your user-init file, on startup.
If this file does not exist, Textadept creates it for you. This file allows you
to indicate what you want Textadept to do when the application starts, such as
change the settings of existing modules, load new ones, and/or run plain Lua
code.

### Modules

Try to refrain from modifying the default modules that come with Textadept, even
if you just want to change an option in a generic module, modify the buffer
settings for a language module, edit file types, or add a small bit of custom
code. Upgrading Textadept to a new version may overwrite those changes. Instead
you have two options: load your own module instead of the default one, or run
your custom module code after the default module loads. For the most part, use
the second option because it is simpler and more compatible with future
releases. The manual discusses both options below in the context of generic and
language modules.

#### Generic

Many of Textadept's generic modules have configurable settings changeable from
*~/.textadept/init.lua* after Textadept loads the module. The module's
[LuaDoc][] lists these settings. For example, to disable character autopairing
with typeover and stripping trailing whitespace on save, add the following to
your *~/.textadept/init.lua*:

    textadept.editing.AUTOPAIR = false
    textadept.editing.TYPEOVER_CHARS = false
    textadept.editing.STRIP_TRAILING_SPACES = false

Now suppose you want to load all of Textadept's default modules except for the
menu. You cannot do this after-the-fact from *~/.textadept/init.lua*. Instead
you need Textadept to load your own module rather than the default one. Copy the
`textadept` module's *init.lua* (located in the *modules/textadept/* directory)
to *~/.textadept/modules/textadept/* and change

    M.menu = require 'textadept.menu'

to

    --M.menu = require 'textadept.menu'

Now when Textadept looks for *modules/textadept/init.lua*, it loads yours in
place of its own, thus loading everything but the menu. If instead you want to
completely change the menu structure, first create a new *menu.lua* and then put
it in *~/.textadept/modules/textadept/*. Textadept now loads your *menu.lua*
rather than its own.

[LuaDoc]: api/index.html

#### Language

Similar to generic modules, putting your own language module in
*~/.textadept/modules/* causes Textadept to load that module for editing the
language's code instead of the default one in *modules/* (if the latter exists).
For example, copying the default Lua language module from *modules/lua/* to
*~/.textadept/modules/* results in Textadept loading that module for editing Lua
code in place of its own. However, if you make custom changes to that module and
upgrade Textadept later, the module may no longer be compatible. Rather than
potentially wasting time merging changes, run custom code independent of a
module in the module's *post_init.lua* file. In this case, instead of copying
the `lua` module and creating an `events.LEXER_LOADED` event handler to use
tabs, simply put the event handler in *~/.textadept/modules/lua/post_init.lua*:

    events.connect(events.LEXER_LOADED, function(lang)
      if lang == 'lua' then buffer.use_tabs = true end
    end)

Similarly, use *post_init.lua* to change the module's [compile and run][]
commands, load more [Adeptsense tags][], and add additional
[key bindings](#Key.Bindings) and [snippets](#Snippets) (instead of in
*~/.textadept/init.lua*). For example:

    textadept.run.run_command.lua = 'lua5.2'
    _M.lua.sense:load_ctags('/path/to/my/projects/tags')
    keys.lua['c\n'] = function()
      buffer:line_end() buffer:add_text('end') buffer:new_line()
    end
    snippets.lua['ver'] = '%<_VERSION>'

[compile and run]: 07_Modules.html#Compile.and.Run
[Adeptsense tags]: api/textadept.adeptsense.html#load_ctags

### Loading Modules

After creating or downloading a generic module called `foo` that you want to
load along with the default modules, simply add the following to your
*~/.textadept/init.lua*:

    foo = require('foo')

Textadept automatically loads language modules when opening a source file of
that language, so simply installing the language module is sufficient.

### Key Bindings

For simple changes to key bindings, *~/.textadept/init.lua* is a good place to
put them. For example, maybe you want `Ctrl+Shift+C` to create a new buffer
instead of `Ctrl+N`:

    keys.cC = buffer.new
    keys.cn = nil

If you plan on redefining most key bindings, copy or create a new *keys.lua* and
put it in *~/.textadept/modules/textadept/* to get Textadept to load your set
instead of its own. Learn more about key bindings and how to define them in the
[key bindings LuaDoc][].

[key bindings LuaDoc]: api/keys.html

### Snippets

Define your own global snippets in *~/.textadept/init.lua*, such as:

    snippets['file'] = '%<buffer.filename>'
    snippets['path'] = "%<(buffer.filename or ''):match('^.+[/\\]')>"

So typing `file` or `path` and then pressing `Tab` (`⇥` on Mac OSX | `Tab` in
curses) inserts the snippet, regardless of the current programming language.
Learn more about snippet syntax in the [snippets LuaDoc][].

[snippets LuaDoc]: api/textadept.snippets.html

### File Types

Textadept recognizes a wide range of programming language files either by file
extension, by a keyword in the shebang ("#!/path/to/exe") line, or by a
[Lua pattern][] that matches the text of the first line. The editor does this by
consulting a set of tables in [`textadept.file_types`][] that are modifiable
from *~/.textadept/init.lua*. For example:

    -- Recognize .luadoc files as Lua code.
    textadept.file_types.extensions.luadoc = 'lua'
    -- Change .html files to be recognized as XML files.
    textadept.file_types.extensions.html = 'xml'
    -- Recognize a shebang line like "#!/usr/bin/zsh" as shell code.
    textadept.file_types.shebangs.zsh = 'bash'

[Lua pattern]: 14_Appendix.html#Lua.Patterns
[`textadept.file_types`]: api/textadept.file_types.html

## Buffer Properties

Since Textadept runs *~/.textadept/init.lua* only once on startup, it is not the
appropriate place to set per-buffer properties like indentation size or
view-related properties like the behaviors for scrolling and autocompletion.
If you do set such properties in *~/.textadept/init.lua*, those settings only
apply to the first buffer and view -- subsequent buffers and split views will
not inherit those settings. Instead, put your settings in a
*~/.textadept/properties.lua* file which runs after creating a new buffer or
split view. Any settings there override Textadept's default *properties.lua*
settings. For example, to use tabs rather than spaces and have a tab size of 4
spaces by default, your *~/.textadept/properties.lua* would contain:

    buffer.use_tabs = true
    buffer.tab_width = 4

(Remember that in order to have per-filetype properties, you need to have a
[language module][].)

Textadept's *properties.lua* is a good reference to see available properties to
set. It also has many commented out properties that you can copy to your
*~/.textadept/properties.lua* and uncomment to turn on or change the value of.
Use [Adeptsense][] to view a property's documentation or read the [LuaDoc][].

[language module]: 07_Modules.html#Buffer.Properties
[Adeptsense]: 06_AdeptEditing.html#Adeptsense
[LuaDoc]: api/buffer.html

## Locale

Textadept attempts to auto-detect your locale settings using the "$LANG"
environment variable, falling back on the English locale. To set the locale
manually, copy the desired locale file from the *core/locales/* folder to
*~/.textadept/locale.conf*. If Textadept does not support your language yet,
please translate the English messages in *core/locale.conf* to your language and
send the modified *locale.conf* file to [me][]. I will include it in a future
release.

[me]: README.html#Contact

# Startup Process

Textadept starts up ridiculously fast. On most computers it starts up around as
fast as you can blink.

## Core (`core/init.lua`)

The key to Textadept's lightning fast start time is that it loads only its core
modules before showing the window.

#### Themes

Textadept loads its theme during the Core startup process. Each theme is its
own folder with three files: `buffer.lua`, `lexer.lua`, and `view.lua`. The
buffer theme sets default buffer properties like tabs and indentation. The view
theme sets default view properties like caret color and current line background
color. Lexer themes set the color and style definitions used by most lexers. By
default the `'light'` theme is used. A `'scite'` theme is provided for users
accustomed to SciTE.

To use a different theme, create a `~/.textadept/theme` file containing the
name of the theme you would like. If you have a custom theme, place it in your
`~/.textadept/themes/` directory. Any errors are printed to standard out.

## Post-Core (`init.lua`)

After loading the core modules, Textadept begins loading additional modules.
It first checks for your `~/.textadept/init.lua`. If the file does not exist,
all default modules listed in `init.lua` are loaded.

Your `~/.textadept/init.lua` is a great place to specify what modules you want
to use. They can be Textadept's default ones, or ones that you create. As an
example:

    -- In ~/.textadept/init.lua

    -- Do not load all of textadept's modules.
    --require 'textadept'

    -- Instead, load a subset of them from 'modules/textadept/init.lua'.
    --require 'textadept.bookmarks'
    --require 'textadept.command_entry'
    require 'textadept.editing'
    require 'textadept.find'
    require 'textadept.mime_types'
    --require 'textadept.run'
    require 'textadept.session'
    require 'textadept.snippets'

    -- These need to be loaded last.
    --require 'textadept.menu'
    require 'textadept.keys'

Please note Textadept does NOT load your `~/.textadept/init.lua`'s modules in
addition to its own. This defeats the purpose of maximum extensibility. If your
`init.lua` exists, Textadept assumes that file tells it exactly what to load.
If you have an empty `init.lua`, no modules are loaded.

After loading the additional modules, Textadept parses command line arguments,
or if none are specified, reloads the last saved session.

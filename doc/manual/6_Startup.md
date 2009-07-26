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
name of the built-in theme you would like. If you have a custom theme, use the
path to its directory instead. Any errors are printed to standard out.

## Post-Core (`init.lua`)

After loading the core modules, Textadept begins loading additional modules.
It first checks for a `~/.textadept/init.lua` user module. If the module is
found, it is run and skips loading the default modules specified in `init.lua`.
Otherwise a mixture of core extension and generic modules are loaded.

After loading the additional modules, Textadept parses command line arguments,
or if none are specified, reloads the last saved session.

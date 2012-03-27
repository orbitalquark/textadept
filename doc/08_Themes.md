# Themes

Textadept's look and feel can be customized with themes. The themes that come
with Textadept are `light` and `dark`'. By default the `light` theme is used. To
change the theme, create a `~/.textadept/theme` file whose first line of text is
the name of the theme you would like to use.

![Light Theme](images/lighttheme.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Dark Theme](images/darktheme.png)

Themes apply to all buffers. You cannot assign a theme to a particular file or
filetype. You can change things like tab and indent settings per filetype
however by creating a [language-specific module].

[language-specific module]: 7_Modules.html#Buffer.Properties

## Creating or Modifying Themes

Each theme is a single folder on the filesystem composed of three files:
`lexer.lua`, `buffer.lua`, and `view.lua`. It is recommended to put themes in
your `~/.textadept/themes/` directory so they will not be overwritten when you
update Textadept. Themes in that directory override any themes in Textadept's
`themes/` directory. This means that if you have your own `light` theme, it will
be loaded instead of the one that comes with Textadept.

To use a theme not located in `~/.textadept/themes/` or Textadept's `themes/`
directory, you need to specify an absolute path to the theme's folder in your
`~/.textadept/theme` file.

### Lexer

Textadept uses lexers to assign names to buffer elements like comments, strings,
and keywords. These elements are assigned styles composed of font and color
information in the theme's `lexer.lua`. See the `Styling Tokens` section of the
[lexer][] page for more information on how to create styles and colors.

[lexer]: api/lexer.html

### Buffer

`buffer.lua` contains buffer-specific properties like indentation size and
whether or not to use tabs. For example, to set the default tab size to 4 and
use tabs:

    buffer.tab_width = 4
    buffer.use_tabs = true
    buffer.indent = 4

See the [LuaDoc][] for documentation on the properties.

[LuaDoc]: api/buffer.html

### View

`view.lua` contains view-specific properties like caret and selection colors.
See the [LuaDoc][] for documentation on the properties.

[LuaDoc]: api/buffer.html

## Testing Themes

You can reload or switch between themes on the fly using `Ctrl+Shift+T` (⌘⇧T on
Mac OSX), but be aware that the Scintilla views do not reset themselves, so any
options set explicitly in the previous theme's `view.lua` file that are not set
explicitly in the new theme will carry over. The switch feature is intended
primarily for theme exploration and/or development and can be slow when many
buffers or views are open.

Any errors that occur in the theme are printed to `io.stderr`.

## Theming the GUI

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK Resource files][]. The `GtkWindow` name is
`textadept`. For example, styling all text fields with a
`"textadept-entry-style"` would be done like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK Resource files]: http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html

## Getting Themes

For now, user-created themes are obtained from the [wiki][]. The classic `dark`,
`light`, and `scite` themes prior to version 4.3 have been moved there.

[wiki]: http://foicica.com/wiki/textadept

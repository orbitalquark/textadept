# Themes

Textadept's look and feel is customized with themes. The themes that come with
Textadept are `light`, `dark`, and `term`. By default the `light` theme is used
for the GUI version and `term` for the terminal version.

<span style="display: block; clear: right;"></span>

![Light Theme](images/lighttheme.png)
&nbsp;&nbsp;
![Dark Theme](images/darktheme.png)
&nbsp;&nbsp;
![Term Theme](images/termtheme.png)

## Structure

Each theme is a single folder composed of three files: `lexer.lua`,
`buffer.lua`, and `view.lua`. It is recommended to put custom or downloaded
themes in your `~/.textadept/themes/` directory so they will not be overwritten
when you update Textadept. Also, themes in that directory override any themes in
Textadept's `themes/` directory. This means that if you have your own `light`
theme, it will be loaded instead of the one that comes with Textadept.

### Lexer

`lexer.lua` contains definitions for how to "style" syntactic elements like
comments, strings, and keywords in programming languages. [Styles][] are
composed of fonts and colors and apply universally to all programming language
elements, resulting in a single, unified theme.

In the terminal version of Textadept, colors are determined by your terminal
emulator's settings. The only colors recognized by Textadept are the standard
black, red, green, yellow, blue, magenta, cyan, white, and bold variants of
those colors. How your terminal chooses to display these colors is up to you.
However, you can still customize which colors are used for particular styles.

[Styles]: api/lexer.html#Styling.Tokens

### Buffer

`buffer.lua` contains [buffer-specific properties][] like the indentation
character and indentation size. For example, to use tabs instead of spaces and
have a tab size of 4 spaces by default:

    buffer.tab_width = 4
    buffer.use_tabs = true

You can use [Adeptsense][] to view a property's documentation or read the
[buffer LuaDoc][].

[buffer-specific properties]: 04_WorkingWithFiles.html#Settings
[Adeptsense]: 06_AdeptEditing.html#Adeptsense
[buffer LuaDoc]: api/buffer.html

### View

`view.lua` contains view-specific properties which apply to all buffers. These
properties are numerous and control many aspects of how buffers are displayed,
from caret and selection colors to margin configurations to marker definitions.
View properties also control editor behaviors like scrolling and autocompletion.
Existing themes have various properties commented out. Uncomment a property to
turn it on or change its value. You can use [Adeptsense][] to view a property's
documentation or read the [LuaDoc][].

[Adeptsense]: 06_AdeptEditing.html#Adeptsense
[LuaDoc]: api/buffer.html

## Switch Themes

You can switch between or reload themes using `Ctrl+Shift+T` (`⌘⇧T` on Mac OSX |
none in ncurses). However, be aware that the views do not reset themselves. Any
properties set explicitly in the previous theme's `view.lua` file that are not
set explicitly in the new theme will carry over. Restarting Textadept will fix
this. Also, be aware that themes apply to all buffers. You cannot assign a theme
to a particular file or file type. (You can change things like tab and indent
settings per filetype, however, by creating a [language-specific module][].)
Behind the scenes, Textadept is setting the theme name in a `~/.textadept/theme`
or `~/.textadept/theme_term` file. To use a theme not listed, specify an
absolute path to the theme's folder in your `~/.textadept/theme` or
`~/.textadept/theme_term` file. When testing themes, any errors that occur are
printed to standard error.

[language-specific module]: 07_Modules.html#Buffer.Properties

## GUI Theme

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK+ Resource files][]. The `GtkWindow` name is
`textadept`. For example, styling all text fields with a
`"textadept-entry-style"` would be done like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK+ Resource files]: http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html

## Getting Themes

For now, user-created themes are obtained from the [wiki][]. The classic `dark`,
`light`, and `scite` themes prior to version 4.3 have been moved there.

[wiki]: http://foicica.com/wiki/textadept

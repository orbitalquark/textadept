# Themes

Textadept's look and feel is customized with themes. The themes that come with
Textadept are "light", "dark", and "term". By default the "light" theme is used
for the GUI version and "term" for the terminal version.

<span style="display: block; clear: right;"></span>

![Light Theme](images/lighttheme.png)
&nbsp;&nbsp;
![Dark Theme](images/darktheme.png)
&nbsp;&nbsp;
![Term Theme](images/termtheme.png)

Each theme is a single Lua file. It is recommended to put custom or downloaded
themes in your *~/.textadept/themes/* directory so they will not be overwritten
when you update Textadept. Also, themes in that directory override any themes in
Textadept's *themes/* directory. This means that if you have your own *light*
theme, it will be loaded instead of the one that comes with Textadept.

Themes contain color definitions and definitions for how to highlight (or
"style") syntactic elements like comments, strings, and keywords in programming
languages. These [definitions][] apply universally to all programming language
elements, resulting in a single, unified theme. Themes also set view-related
editor properties like caret and selection colors.

In the terminal version of Textadept, colors are determined by your terminal
emulator's settings. The only colors recognized by Textadept are the standard
black, red, green, yellow, blue, magenta, cyan, white, and bold variants of
those colors. How your terminal chooses to display these colors is up to your
terminal settings. However, you can still customize which colors are used for
particular styles.

[definitions]: api/lexer.html#Styles.and.Styling

## Switch Themes

You can switch between or reload themes using `Ctrl+Shift+T` (`⌘⇧T` on Mac OSX |
none in curses). You can set that theme to be the default one by putting

    gui.set_theme('name')

somewhere in your [*~/.textadept/init.lua*][].

[*~/.textadept/init.lua*]: 08_Preferences.html#User.Init

## GUI Theme

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK+ Resource files][]. The "GtkWindow" name is
"textadept". For example, styling all text fields with a "textadept-entry-style"
would be done like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK+ Resource files]: http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html

## Getting Themes

For now, user-created themes are obtained from the [wiki][]. The classic "dark",
"light", and "scite" themes prior to version 4.3 have been moved there.

[wiki]: http://foicica.com/wiki/textadept

# Themes

Themes customize Textadept's look and feel. The editor's built-in themes are
"light", "dark", and "term". The GUI version uses "light" as its default and the
terminal version uses "term".

<span style="display: block; clear: right;"></span>

![Light Theme](images/lighttheme.png)
&nbsp;&nbsp;
![Dark Theme](images/darktheme.png)
&nbsp;&nbsp;
![Term Theme](images/termtheme.png)

Each theme is a single Lua file. It contains color definitions and definitions
for how to highlight (or "style") syntactic elements like comments, strings, and
keywords in programming languages. These [definitions][] apply universally to
all programming language elements, resulting in a single, unified theme. Themes
also set view-related editor properties like caret and selection colors.

Note: The only colors that the terminal version of Textadept recognizes are the
standard black, red, green, yellow, blue, magenta, cyan, white, and bold
variants of those colors. Your terminal emulator's settings determine how to
display these standard colors.

[definitions]: api/lexer.html#Styles.and.Styling

## Switch Themes

Switch between or reload themes using `Ctrl+Shift+T` (`⌘⇧T` on Mac OSX | none in
curses). Set that theme to be the default one by putting

    gui.set_theme('name')

somewhere in your [*~/.textadept/init.lua*][].

[*~/.textadept/init.lua*]: 08_Preferences.html#User.Init

## Customizing Themes

Like with modules, try to refrain from editing Textadept's default themes.
Instead, put custom or downloaded themes in your *~/.textadept/themes/*
directory. Doing this not only prevents you from overwriting your themes when
you update Textadept, but causes the editor to load your themes instead of the
default ones in *themes/*. For example, having your own *light.lua* theme
results in Textadept loading that theme in place of its own.

There are two ways to go about customizing themes. You can create a new one from
scratch or tweak an existing one. Creating a new one is straightforward -- all
you need to do is define a set of colors and a set of styles. Just follow the
example of existing themes. If instead you want to use an existing theme like
"light" but only change the font face and font size, you do not have to copy the
whole theme to your *~/.textadept/themes/light.lua* before changing the font
settings. Tweaking themes is very simple with Lua's `dofile()` function. In your
*~/.textadept/themes/light.lua*, put:

    dofile(_HOME..'/themes/light.lua')
    buffer.property['font'] = 'font face'
    buffer.property['fontsize'] = size

This loads Textadept's "light" theme, but applies your font preferences. The
same technique works for tweaking individual theme colors and/or styles.

### Language-Specific

Textadept also allows you to customize themes per-language through the
`events.LANGUAGE_MODULE_LOADED` event. For example, changing the color of
functions in Java from orange to black in the "light" theme looks like this:

    events.connect(events.LANGUAGE_MODULE_LOADED, function(lang)
      if lang == 'java' then
        buffer.property['style.function'] = 'fore:%(color.light_black)'
      end
    end)

## GUI Theme

There is no way to theme GUI controls like text fields and buttons from within
Textadept. Instead, use [GTK+ Resource files][]. The "GtkWindow" name is
"textadept". For example, style all text fields with a "textadept-entry-style"
like this:

    widget "textadept*GtkEntry*" style "textadept-entry-style"

[GTK+ Resource files]: http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html

## Getting Themes

For now, the [wiki][] hosts third-party, user-created themes. The classic
"dark", "light", and "scite" themes prior to version 4.3 are there too.

[wiki]: http://foicica.com/wiki/textadept

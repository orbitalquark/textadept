# File Navigation

## Basic Movements

Textadept supports the key bindings you are accustomed to for navigating text
fields on your platform. The arrow keys move the caret in a particular
direction, `Ctrl+Left` and `Ctrl+Right` (`^⇠` and `^⇢` on Mac OSX | `^Left` and
`^Right` in ncurses) move by words, `PgUp` and `PgDn` (`⇞` and `⇟` | `PgUp` and
`PgDn`) move by pages, etc. Mac OSX and ncurses also support some Bash-style
bindings like `^B`, `^F`, `^P`, `^N`, `^A`, and `^E`. A complete list of
movement bindings is found in the "Movement" section of the
[key bindings list][].

[key bindings list]: api/_M.textadept.keys.html#Key.Bindings

## Brace Match

By default, Textadept will highlight the matching brace characters under the
caret : `(`, `)`, `[`, `]`, `{`, and `}`. Pressing `Ctrl+M` (`^M` on Mac OSX |
`M-M` in ncurses) moves the caret to that matching brace.

![Matching Braces](images/matchingbrace.png)

## Bookmarks

You can place bookmarks on lines in buffers to jump back to them later.
`Ctrl+F2` (`⌘F2` on Mac OSX | none in ncurses) toggles a bookmark on the current
line, `F2` jumps to the next bookmarked line, `Shift+F2` (`⇧F2` | none) jumps to
the previously bookmarked line, `Alt+F2` (`⌥F2` | none) jumps to the bookmark
selected from a list, and `Ctrl+Shift+F2` (`⌘⇧F2` | none) clears all bookmarks
in the current buffer.

## Goto Line

To jump to a specific line in a file, press `Ctrl+J` (`⌘J` on Mac OSX | `^J` in
ncurses) and specify the line number in the prompt and press `Enter` (`↩` |
`Enter`) or select `OK`.

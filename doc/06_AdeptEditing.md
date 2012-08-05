# Adept Editing

## Key Commands

Textadept is entirely keyboard-driven. See the comprehensive list of key
commands in the [appendix][]. Key commands can be modified in your
[key preferences][].

[appendix]: 14_Appendix.html#Key.Bindings
[key preferences]: 9_Preferences.html#Key.Commands

## Character Autopairing

Usually, quote (`'`, `"`) and brace (`(`, `[`, `{`) characters go together in
pairs. By default, Textadept automatically inserts the complement character when
the first is typed. Similarly, the complement is deleted when you press
`Backspace` (`⌫`) over the first. See the [preferences][] page if you would like
to disable this.

[preferences]: 9_Preferences.html#Module.Settings

## Word Completion

Textadept provides buffer-based word completion. Start typing a word, press
`Ctrl+Return` (`^⎋` on Mac OSX | `M-Enter` in ncurses), and a list of suggested
completions based on words in the current document is provided. Continuing to
type changes the suggestion. Press `Enter` (`↩` | `Enter`) to complete the
selected word.

![Word Completion](images/wordcompletion.png)

## Adeptsense

Textadept has the capability to autocomplete symbols for programming languages
and display API documentation. Lua is of course supported extremely well and
other languages have basic support with the help of [ctags][]. Symbol completion
is available by pressing `Ctrl+Space` (`⌥⎋` on Mac OSX | `^Space` in ncurses).
Documentation for symbols is available with `Ctrl+H` (`^H` | `M-H` or `M-S-H`).

![Adeptsense Lua](images/adeptsense_lua.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Adeptsense Lua String](images/adeptsense_string.png)

![Adeptsense Doc](images/adeptsense_doc.png)

For more information on adding adeptsense support for another language, see
the [LuaDoc][].

[ctags]: http://ctags.sf.net
[LuaDoc]: api/_M.textadept.adeptsense.html

## Find and Replace

`Ctrl+F` (`⌘F` on Mac OSX | `M-F` or `M-S-F` in ncurses) brings up the
Find/Replace dialog. In addition to offering the usual find and replace,
Textadept allows you to find with [Lua patterns][] and replace with Lua captures
and even Lua code! For example: replacing all `(%w+)` with
`%(string.upper('%1'))` capitalizes all words in the buffer. Lua captures (`%n`)
are only available from a Lua pattern search, but embedded Lua code enclosed in
`%()` is always allowed.

Note the `Ctrl+G`, `Ctrl+Shift+G`, `Ctrl+Alt+R`, `Ctrl+Alt+Shift+R` key commands
for find next, find previous, replace, and replace all (`⌘G`, `⌘⇧G`, `^R`, `^⇧R`
respectively on Mac OSX | `M-G`, `M-S-G`, `M-R`, `M-S-R` in ncurses) only work
when the Find/Replace dialog is hidden. When it is visible in the GUI version,
use the button mnemonics: `Alt+N`, `Alt+P`, `Alt+R`, and `Alt+A` (`⌘N`, `⌘P`,
`⌘R`, `⌘A` | N/A) for English locale.

In the ncurses version, use `Tab` and `S-Tab` to toggle between the find next,
find previous, replace, and replace all buttons; `Up` and `Down` arrows switch
between the find and replace text fields; `^P` and `^N` cycles through history;
and `F1-F4` toggles find options.

[Lua patterns]: 14_Appendix.html#Lua.Patterns

### Find in Files

`Ctrl+Shift+F` brings up Find in Files (`⌘⇧F` on Mac OSX | none in ncurses) and
will prompt for a directory to search. The results are displayed in a new
buffer. Double-clicking a search result jumps to it in the file. You can also
use the `Ctrl+Alt+G` and `Ctrl+Alt+Shift+G` (`^⌘G` and `^⌘⇧G` on Mac OSX | none
in ncurses) key commands. Replace in Files is not supported. You will have to
`Find in Files` first, and then `Replace All` for each file a result is found
in. The `Match Case`, `Whole Word`, and `Lua pattern` flags still apply.

![Find in Files](images/findinfiles.png)

### Find Incremental

You can start an incremental search by pressing `Ctrl+Alt+F` (`^⌘F` on Mac OSX |
`M-^F` in ncurses). Incremental search searches the buffer as you type. Only the
`Match Case` option is recognized. Pressing `Esc` (`⎋` | `Esc`) stops it.

### Replace in Selection

By default, `Replace All` replaces all text in the buffer. If you want to
replace all text in just a portion of the buffer, select a block of text and
then `Replace All`.

## Indentation

### Change Indent Level

The amount of indentation for a selected set of lines is increased by pressing
`Tab` (`⇥` | `Tab`) and decreased by pressing `Shift+Tab` (`⇧⇥` | `S-Tab`).
Using these key sequences when no selection is present does not have the same
effect.

### Change Indent Size

The indent size is usually set by a [language-specific module][] or the
[theme][]. You can set it manually using the `Buffer -> Indentation` menu.
Textadept shows what it is using for indentation in the document statusbar.

![Document Statusbar](images/docstatusbar.png)

[language-specific module]: 7_Modules.html#Buffer.Properties
[theme]: 8_Themes.html#Buffer

### Using Tabs

You can use tabs instead of the default spaces by pressing `Ctrl+Alt+Shift+T`
(`^⇧T` on Mac OSX | `M-T` or `M-S-T` in ncurses) or using the `Buffer -> Toggle
Use Tabs` menu. Textadept shows what it is using for indentation in the document
statusbar.

The default option is usually set by a [language-specific module][] or the
[theme][].

[language-specific module]: 7_Modules.html#Buffer.Properties
[theme]: 8_Themes.html#Buffer

### Converting Indentation

Use the `Edit -> Convert Indentation` menu to convert indentation. If the buffer
is using tabs, all spaces are converted to tabs. If the buffer is using spaces,
all tabs are converted to spaces.

## Selecting Text

### Rectangular Selection

Holding `Alt+Shift` (`⌥⇧` on Mac OSX | `M-S` in ncurses) and pressing the arrow
keys enables rectangular selections to be made. Start typing to type on each
line.

![Rectangular Selection](images/rectangularselection.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Rectangular Edit](images/rectangularselection2.png)

### Multiple Selection

Clicking the mouse at a point in the buffer while holding `Control` places an
additional caret at that point. Clicking and dragging while holding `Control`
creates multiple selections. Start typing to enter text at each selection.

This is currently unavailable on Mac OSX and in ncurses.

### Selecting Entities

Textadept allows you to select many different entities from the caret. For
example, `Ctrl+"` (`^"` on Mac OSX | `M-"` in ncurses) selects all characters in
a `""` sequence. Typing `Ctrl++` (`^+` | `M-+`) as a follow-up selects the
double-quotes too. See the `Edit -> Select In...` menu for available entities
and their key commands.

## Enclosing Text

As a complement to selecting entities, you can enclose text as entities. The
`Edit -> Selection -> Enclose In...` menu contains all available entities and
their key commands.

If no text is selected, the word to the left of the caret is enclosed.

## Word Highlight

All occurrences of a given word are highlighted by putting the caret over the
word and pressing `Ctrl+Alt+Shift+H` (`⌘⇧H` on Mac OSX | N/A in ncurses). This
is useful to show occurrences of a variable name in source code.

This is not supported in ncurses.

![Word Highlight](images/wordhighlight.png)

## Editing Modes

### Virtual Space

Virtual space (freehand) mode is enabled and disabled with `Ctrl+Alt+Shift+V`
(`^⇧V` in Mac OSX | none in ncurses). When enabled, caret movement is not
restricted by line endings.

### Overwrite

Overwrite mode is enabled and disabled with the `Insert` key. When enabled,
characters in the buffer will be overwritten instead of inserted as you type.
The caret also changes to an underline when in overwrite mode.

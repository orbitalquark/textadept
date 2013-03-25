# Adept Editing

## Basic Editing

Textadept has many basic editing features you are familiar with: basic text
entry, undo/redo, clipboard manipulation, deleting characters and words,
duplicating lines, joining lines, and transposing characters. These are
accessible from the top-level "Edit" menu and have associated key bindings.
Some of the basic editing features you may not be familiar with are discussed
below.

### Autopaired Characters

Usually, quote ('&apos;', '&quot;') and brace ('(', '[', '{') characters go
together in pairs. By default, Textadept automatically inserts the complement
character when the first is typed. Similarly, the complement is deleted when you
press `Bksp` (`⌫` on Mac OSX | `Bksp` in ncurses) over the first. Typing over
complement characters is also supported. See the [preferences][] page if you
would like to disable these features.

[preferences]: 08_Preferences.html#Generic

### Word Completion

Textadept provides buffer-based word completion. Start typing a word, press
`Ctrl+Enter` (`^⎋` on Mac OSX | `M-Enter` in ncurses), and a list of suggested
completions based on words in the current buffer is provided. Continuing to type
changes the suggestion. Press `Enter` (`↩` | `Enter`) to complete the selected
word.

![Word Completion](images/wordcompletion.png)

### Virtual Space Mode

Virtual space (freehand) mode is enabled and disabled with `Ctrl+Alt+Shift+V`
(`^⇧V` in Mac OSX | none in ncurses). When enabled, caret movement is not
restricted by line endings.

### Overwrite Mode

Overwrite mode is enabled and disabled with the `Insert` key. When enabled,
characters in the buffer will be overwritten instead of inserted as you type.
The caret also changes to an underline when in overwrite mode.

## Selections

Textadept has many ways of creating and working with selections. Basic
selections are what you get when you do things like hold the "Shift" modifier
key while pressing the arrow keys, click and drag the mouse over a range of
text, or press `Ctrl+A` (`⌘A` | `M-A`) for "Select All". More advanced
selections like multiple and rectangular selections are more complicated to
create, but have powerful uses.

### Multiple Selection

Clicking the mouse at a point in the buffer while holding the "Control" modifier
key places an additional caret at that point. Clicking and dragging while
holding the same modifier creates multiple selections. When you start typing,
the text is mirrored at each selection.

Creating multiple selections with the mouse is currently unavailable in ncurses.

### Rectangular Selection

Holding `Alt+Shift` (`⌥⇧` on Mac OSX | `M-S-` in ncurses) and pressing the arrow
keys enables rectangular selections to be made. Start typing to type on each
line. You can also hold the "Alt" modifier key ("Super" on Linux) while clicking
and dragging the mouse to create rectangular selections.

![Rectangular Selection](images/rectangularselection.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Rectangular Edit](images/rectangularselection2.png)

Note: In some Linux environments, the `Alt+Shift+Arrow` combinations are used by
the window manager and may need to be reconfigured. Also, `Super+Mouse` is used
because `Alt+Mouse` generally moves windows. If you prefer to use "Alt", you can
change [`buffer.rectangular_selection_modifier`][] in your [theme][]. The
"Super" modifier key is usually defined as the left "Windows" key, but may need
to be reconfigured too.

Creating rectangular selections with the mouse is currently unavailable in
ncurses.

[`buffer.rectangular_selection_modifier`]: api/buffer.html#rectangular_selection_modifier
[theme]: 09_Themes.html#View

### Select to Matching Brace

Putting the caret over a brace character ('(', ')', '[', ']', '{', or '}') and
pressing `Ctrl+Shift+M` (`^⇧M` on Mac OSX| `M-S-M` in ncurses) extends the
selection to the brace character's matching brace.

### Entity Selection

Textadept allows you to select many different entities from the caret. For
example, `Ctrl+"` (`^"` on Mac OSX | `M-"` in ncurses) selects all characters in
a double-quoted range. Typing `Ctrl++` (`^+` | `M-+`) as a follow-up selects the
double-quotes too. See the "Edit -> Select In..." menu for available entities
and their key bindings.

### Marks

In ncurses, since some terminals do not recognize certain key combinations like
`Shift+Arrow` for making selections, you can use marks to create selections.
Create a mark at the current caret position with `^^`. Then use regular movement
keys like the arrows, page up/down, and home/end to extend the selection in one
direction. Pressing `^]` swaps the current caret position with the original mark
position so you can extend the selection in the opposite direction. Any time you
type text, delete text, or run a command that does either, the mark is removed
and ordinary navigation is restored. You can also press `^^` again to stop
selecting text.

Marks are only supported in ncurses.

### Transforms

#### Enclose Entities

As a complement to selecting entities, you can enclose text as entities. The
"Edit -> Selection -> Enclose In..." menu contains all available entities and
their key bindings.

If no text is selected, the word to the left of the caret is enclosed. For
example, pressing `Alt+<` (`^<` on Mac OSX | `M->` in ncurses) at the end of a
word encloses it in XML tags.

#### Change Case

Pressing `Ctrl+Alt+U` or `Ctrl+Alt+Shift+U` (`^U` or `^⇧U` on Mac OSX | `M-^U`
or `M-^L` in ncurses) converts selected text to upper case letters or lower case
letters respectively.

#### Change Indent Level

The amount of indentation for a selected set of lines is increased by pressing
`Tab` (`⇥` on Mac OSX | `Tab` in ncurses) and decreased by pressing `Shift+Tab`
(`⇧⇥` | `S-Tab`). Whole lines do not have to be selected. As long as any part of
a line is selected, the entire line is eligible for indenting/dedenting. Using
these key sequences when no selection is present does not have the same effect.

#### Move Lines

Selected lines are moved with the `Ctrl+Shift+Up` and `Ctrl+Shift+Down` (`^⇧⇡`
and `^⇧⇣` on Mac OSX | `S-^Up` and `S-^Down` in ncurses) keys. Like with
changing indent level, as long as any part of a line is selected, the entire
line is eligible for moving.

## Find & Replace

`Ctrl+F` (`⌘F` on Mac OSX | `M-F` or `M-S-F` in ncurses) brings up the Find &
Replace pane. In addition to offering the usual find and replace with "Match
Case" and "Whole Word" options and find/replace history, Textadept allows you to
find with [Lua patterns][] and replace with Lua captures and even Lua code! For
example: replacing all `(%w+)` with `%(string.upper('%1'))` upper cases all
words in the buffer. Lua captures (`%`_`n`_) are only available from a Lua
pattern search, but embedded Lua code enclosed in `%()` is always allowed.

Note the `Ctrl+G`, `Ctrl+Shift+G`, `Ctrl+Alt+R`, `Ctrl+Alt+Shift+R` key bindings
for find next, find previous, replace, and replace all (`⌘G`, `⌘⇧G`, `^R`, `^⇧R`
respectively on Mac OSX | `M-G`, `M-S-G`, `M-R`, `M-S-R` in ncurses) only work
when the Find & Replace pane is hidden. When the pane is visible in the GUI
version, use the button mnemonics: `Alt+N`, `Alt+P`, `Alt+R`, and `Alt+A` (`⌘N`,
`⌘P`, `⌘R`, `⌘A` | N/A) for English locale.

In the ncurses version, `Tab` and `S-Tab` toggles between the find next, find
previous, replace, and replace all buttons; `Up` and `Down` arrows switch
between the find and replace text fields; `^P` and `^N` cycles through history;
and `F1-F4` toggles find options.

Pressing `Esc` (`⎋` | `Esc`) hides the pane when you are finished.

[Lua patterns]: 14_Appendix.html#Lua.Patterns

### Replace in Selection

By default, "Replace All" replaces all text in the buffer. If you want to
replace all text in just a portion of the buffer, select a block of text and
then "Replace All".

### Find in Files

`Ctrl+Shift+F` brings up Find in Files (`⌘⇧F` on Mac OSX | none in ncurses) and
will prompt for a directory to search. The results are displayed in a new
buffer. Double-clicking a search result jumps to it in the file. You can also
use the `Ctrl+Alt+G` and `Ctrl+Alt+Shift+G` (`^⌘G` and `^⌘⇧G` on Mac OSX | none
in ncurses) key bindings. Replace in Files is not supported. You will have to
"Find in Files" first, and then "Replace All" for each file a result is found
in. The "Match Case", "Whole Word", and "Lua pattern" flags still apply.

_Warning_: currently, the only way to specify a file-type filter is through the
[find API][] and even though the default filter excludes common binary files
and version control folders from searches, Find in Files could still scan
unrecognized binary files or large, unwanted sub-directories. Searches also
block Textadept from receiving additional input, making the interface
temporarily unresponsive. Searching large directories or projects can be very
time consuming and frustrating, so using a specialized, external tool such as
[ack][] is recommended.

![Find in Files](images/findinfiles.png)

[find API]: api/gui.find.html#FILTER
[ack]: http://betterthangrep.com/

### Incremental Find

You can start an incremental search by pressing `Ctrl+Alt+F` (`^⌘F` on Mac OSX |
`M-^F` in ncurses). Incremental search searches the buffer as you type. Only the
"Match Case" option is recognized. Pressing `Esc` (`⎋` | `Esc`) stops the
search.

## Source Code Editing

Textadept would not be a programmer's editor without some features for editing
source code. Textadept understands the syntax and structure of more than 80
different programming languages and recognizes hundreds of file types. It uses
this knowledge to make viewing and editing code faster and easier.

### Lexers

When you open a file, chances are that Textadept will identify the programming
language associated with that file and set a "lexer" to highlight syntactic
elements of the code. You can set or change the lexer manually by pressing
`Ctrl+Shift+L` (`⌘⇧L` on Mac OSX | `M-S-L` in ncurses) and selecting a lexer
from the list. You can customize how Textadept recognizes files in your
[file type preferences][].

Lexers can sometimes lose track of their context while you are editing and
highlight syntax incorrectly. Pressing `F5` triggers a full redraw.

[file type preferences]: 08_Preferences.html#File.Types

### Code Folding

Some lexers support "code folding", where blocks of code can be temporarily
hidden, making viewing easier. Fold points are denoted by arrows in the margin
to the left of the code. Clicking on one toggles the folding for that block of
code. You can also press `Ctrl+*` (`⌘*` on Mac OSX | `M-*` in ncurses) to
toggle the fold point on the current line.

![Folding](images/folding.png)

### Word Highlight

All occurrences of a given word are highlighted by putting the caret over the
word and pressing `Ctrl+Alt+Shift+H` (`⌘⇧H` on Mac OSX | N/A in ncurses). This
is useful to show occurrences of a variable name, but is not limited to source
code.

![Word Highlight](images/wordhighlight.png)

This is not supported in ncurses.

### Adeptsense

Textadept has the capability to autocomplete symbols for programming languages
and display API documentation. Symbol completion is available by pressing
`Ctrl+Space` (`⌥⎋` on Mac OSX | `^Space` in ncurses). Documentation for symbols
is available with `Ctrl+H` (`^H` | `M-H` or `M-S-H`). Note: In order for this
feature to work, the language you are working with must have an [Adeptsense][]
defined. [Language-specific modules][] usually [define Adeptsenses][]. All of
the [official][] Textadept language-specific modules have Adeptsenses.

![Adeptsense Lua](images/adeptsense_lua.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Adeptsense Lua String](images/adeptsense_string.png)

![Adeptsense Doc](images/adeptsense_doc.png)

[Language-specific modules]: 07_Modules.html#Language-Specific
[Adeptsense]: api/_M.textadept.adeptsense.html
[define Adeptsenses]: api/_M.html#Adeptsense
[official]: http://foicica.com/hg

### Snippets

Snippets are essentially pieces of text inserted into a document. However,
snippets are not limited to static text. They can be dynamic templates which
contain placeholders for further user input, can mirror or transform those user
inputs, and/or execute arbitrary code. Snippets are useful for rapidly
constructing blocks of code such as control structures, method calls, and
function declarations. Press `Ctrl+K` (`⌥⇥` on Mac OSX | `M-K` in ncurses) for a
list of available snippets. Snippets are composed of trigger word and snippet
text. Instead of manually selecting a snippet, you can type its trigger word
followed by the `Tab` (`⇥` | `Tab`) key. Subsequent presses of `Tab` (`⇥` |
`Tab`) cause the caret to enter placeholders in sequential order, `Shift+Tab`
(`⇧⇥` | `S-Tab`) goes back to the previous placeholder, and `Ctrl+Shift+K`
(`⌥⇧⇥` | `M-S-K`) cancels the current snippet. Snippets can be nested (inserted
from within another snippet) and are not limited to source code.
Language-specific modules usually [define snippets][], but you can create your
own custom snippets in your [snippet preferences][].

![Snippet](images/snippet.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Snippet Expanded](images/snippet2.png)

[define snippets]: api/_M.html#Snippets
[snippet preferences]: 08_Preferences.html#Snippets

### Toggle Comments

Pressing `Ctrl+/` (`⌘/` on Mac OSX | `M-/` in ncurses) comments or uncomments
the code on the selected lines. As long as any part of a line is selected, the
entire line will be commented or uncommented. Note: In order for this feature to
work, the language you are working with must have its comment prefix defined.
Language-specific modules usually [define prefixes][], but it can also be done
[manually][] in your [user-init file][].

[define prefixes]: api/_M.html#Block.Comment
[manually]: http://foicica.com/wiki/comment-supplemental
[user-init file]: 08_Preferences.html#User.Init

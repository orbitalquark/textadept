# Appendix

## Lua Patterns

The following is from the [Lua 5.2 Reference Manual][].

_Character Class:_

A character class is used to represent a set of characters. The following
combinations are allowed in describing a character class:

* **_`x`_:** (where _x_ is not one of the magic characters `^%()%.[]*+-?`)
  represents the character _x_ itself.
* **`.`:** (a dot) represents all characters.
* **`%a`:** represents all letters.
* **`%c`:** represents all control characters.
* **`%d`:** represents all digits.
* **`%g`:** represents all printable characters except space.
* **`%l`:** represents all lowercase letters.
* **`%p`:** represents all punctuation characters.
* **`%s`:** represents all space characters.
* **`%u`:** represents all uppercase letters.
* **`%w`:** represents all alphanumeric characters.
* **`%x`:** represents all hexadecimal digits.
* **`%`_`x`_:** (where _x_ is any non-alphanumeric character) represents the
  character _x_. This is the standard way to escape the magic characters. Any
  punctuation character (even the non magic) can be preceded by a '`%`' when
  used to represent itself in a pattern.
* **`[set]`:** represents the class which is the union of all characters in set.
  A range of characters can be specified by separating the end characters of the
  range with a '`-`'. All classes `%`_x_ described above can also be used as
  components in set. All other characters in set represent themselves. For
  example, `[%w_]` (or `[_%w]`) represents all alphanumeric characters plus the
  underscore, `[0-7]` represents the octal digits, and `[0-7%l%-]` represents
  the octal digits plus the lowercase letters plus the '`-`' character.
  <br /><br />
  The interaction between ranges and classes is not defined. Therefore, patterns
  like `[%a-z]` or `[a-%%]` have no meaning.
* **`[^set]`:** represents the complement of _set_, where _set_ is interpreted
  as above.

For all classes represented by single letters (`%a`, `%c`, etc.), the
corresponding uppercase letter represents the complement of the class. For
instance, `%S` represents all non-space characters.

The definitions of letter, space, and other character groups depend on the
current locale. In particular, the class `[a-z]` may not be equivalent to `%l`.

_Pattern Item:_

A _pattern item_ can be

* a single character class, which matches any single character in the class;
* a single character class followed by '`*`', which matches 0 or more
  repetitions of characters in the class. These repetition items will always
  match the longest possible sequence;
* a single character class followed by '`+`', which matches 1 or more
  repetitions of characters in the class. These repetition items will always
  match the longest possible sequence;
* a single character class followed by '`-`', which also matches 0 or more
  repetitions of characters in the class. Unlike '`*`', these repetition items
  will always match the _shortest_ possible sequence;
* a single character class followed by '`?`', which matches 0 or 1 occurrence of
  a character in the class;
* `%n`, for _n_ between 1 and 9; such item matches a substring equal to the
  _n_-th captured string (see below);
* `%bxy`, where _x_ and _y_ are two distinct characters; such item matches
  strings that start with _x_, end with _y_, and where the _x_ and _y_ are
  balanced. This means that, if one reads the string from left to right,
  counting +_1_ for an _x_ and -_1_ for a _y_, the ending _y_ is the first _y_
  where the count reaches 0. For instance, the item `%b()` matches expressions
  with balanced parentheses.
* `%f[set]`, a _frontier pattern_; such item matches an empty string at any
  position such that the next character belongs to _set_ and the previous
  character does not belong to _set_. The set _set_ is interpreted as previously
  described. The beginning and the end of the subject are handled as if they
  were the character `'\0'`.

_Pattern:_

A _pattern_ is a sequence of pattern items. A '`^`' at the beginning of a
pattern anchors the match at the beginning of the subject string. A '`$`' at the
end of a pattern anchors the match at the end of the subject string. At other
positions, '`^`' and '`$`' have no special meaning and represent themselves.

_Captures:_

A pattern can contain sub-patterns enclosed in parentheses; they describe
_captures_. When a match succeeds, the substrings of the subject string that
match captures are stored (_captured_) for future use. Captures are numbered
according to their left parentheses. For instance, in the pattern
`"(a*(.)%w(%s*))"`, the part of the string matching `"a*(.)%w(%s*)"` is stored
as the first capture (and therefore has number 1); the character matching "`.`"
is captured with number 2, and the part matching "`%s*`" has number 3.

As a special case, the empty capture `()` captures the current string position
(a number). For instance, if we apply the pattern `"()aa()"` on the string
`"flaaap"`, there will be two captures: 3 and 5.

[Lua 5.2 Reference Manual]: http://www.lua.org/manual/5.2/manual.html#6.4.1

## Curses Compatibility

Textadept 5.5 beta introduced a curses version that is capable of running in a
terminal emulator. However, it lacks some GUI features due to curses'
non-existant graphics capabilities:

* No alpha values or transparency.
* No images in autocompletion lists. Instead, autocompletion lists show the
  first character in the string passed to [`buffer:register_image()`][].
* No buffered or two-phase drawing.
* No arrows on call tips.
* Carets cannot have a period, line style, or width.
* Edge lines may be obscured by text.
* Extra line ascent or descent renders improperly.
* No fold lines.
* No indentation guides.
* No indicators other than `INDIC_ROUNDBOX` and `INDIC_STRAIGHTBOX`, although
  neither has translucent drawing and `INDIC_ROUNDBOX` does not have rounded
  corners.
* Insert mode caret renders improperly.
* When scrolling to the right, long lines overwrite margins.
* No marker symbols other than `SC_MARK_CHARACTER`.
* No mouse interactions, cursor types, or hotspots.
* Only up to 16 colors recognized: black (`0x000000`), red (`0x800000`), green
  (`0x008000`), yellow (`0x808000`), blue (`0x000080`), magenta (`0x800080`),
  cyan (`0x008080`), white (`0xC0C0C0`), light black (`0x404040`), light red
  (`0xFF0000`), light green (`0x00FF00`), light yellow (`0xFFFF00`), light blue
  (`0x0000FF`), light magenta (`0xFF00FF`), light cyan (`0x00FFFF`), and light
  white (`0xFFFFFF`). Even if your terminal uses a different color map, you must
  use these color values; unrecognized colors default to white. For some
  terminals, you may need to set a lexer style's `bold` attribute to use the
  light color variant.
* No scroll bars.
* Not all key sequences recognized properly.
* No style settings like font name, font size, or italics.
* No tab character arrows when viewing whitespace.
* No visual wrap flags.
* No X selection, primary or secondary, integration with the clipboard.
* No zoom.

[`buffer:register_image()`]: api/buffer.html#buffer.register_image

## Migration Guides

### Textadept 6 to 7

Textadept 7 introduces API changes and a completely new theme implementation.

#### API Changes

Old API                           |Change  |New API
----------------------------------|:------:|-------
**_G**                            |        |
buffer\_new()                     |Renamed |\_G.[buffer.new()][]
**_M.textadept**                  |        |
filter\_through                   |Removed |N/A
filter\_through.filter\_through() |Renamed |editing.[filter\_through()][]
**_M.textadept.bookmark**         |        |
MARK\_BOOKMARK\_COLOR             |Renamed |[BOOKMARK\_COLOR][]
**_M.textadept.editing**          |        |
INDIC\_HIGHLIGHT\_BACK            |Renamed |[HIGHLIGHT\_COLOR][]
autocomplete\_word(chars, default)|Changed |[autocomplete\_word][](default)
grow\_selection()                 |Replaced|[select\_enclosed()][]
**_M.textadept.menu**             |        |
menubar                           |Removed |N/A
contextmenu                       |Removed |N/A
**_M.textadept.run**              |        |
MARK\_ERROR\_BACK                 |Renamed |[ERROR\_COLOR][]
**_M.textadept.snapopen**         |Removed |N/A
open                              |Changed |\_G.[io.snapopen()][]<sup>\*</sup>
**events**                        |        |
handlers                          |Removed |N/A
**gui**                           |        |
find.goto\_file\_in\_list()       |Renamed |find.[goto\_file\_found()][]
select\_theme                     |Removed |N/A
**io**                            |        |
try\_encodings                    |Renamed |[encodings][]

<sup>\*</sup>Changed arguments too.

[buffer.new()]: api/buffer.html#new
[filter\_through()]: api/_M.textadept.editing.html#filter_through
[BOOKMARK\_COLOR]: api/_M.textadept.bookmarks.html#BOOKMARK_COLOR
[HIGHLIGHT\_COLOR]: api/_M.textadept.editing.html#HIGHLIGHT_COLOR
[autocomplete\_word]: api/_M.textadept.editing.html#autocomplete_word
[select\_enclosed()]: api/_M.textadept.editing.html#select_enclosed
[ERROR\_COLOR]: api/_M.textadept.run.html#ERROR_COLOR
[io.snapopen()]: api/io.html#snapopen
[goto\_file\_found()]: api/gui.find.html#goto_file_found
[encodings]: api/io.html#encodings

#### Theme Changes

You can use the following as a reference for converting your Textadept 6 themes
to Textadept 7:

    -- File *theme/lexer.lua*            | -- File *theme.lua*
    -- Textadept 6                       | -- Textadept 7
    local l = lexer                      | local buffer = buffer
    local color = l.color                | local prop = buffer.property
    local style = l.style                | local prop_int =
                                         |   buffer.property_int
                                         |
    l.colors = {                         |
      ...                                | ...
      red = color('99', '4D', '4D'),     | prop['color.red'] = 0x4D4D99
      yellow = color('99', '99', '4D'),  | prop['color.yellow'] = 0x4D9999
      ...                                | ...
    }                                    |
                                         |
    l.style_nothing = style{}            | prop['style.nothing'] = ''
    l.style_class = style{               | prop['style.class'] =
      fore = l.colors.yellow             |   'fore:%(color.yellow)'
    }                                    | ...
    ...                                  | prop['style.identifier'] =
    l.style_identifier = l.style_nothing |   '%(style.nothing)'
                                         |
    ...                                  | ...
                                         |
                                         | prop['font'] = 'Monospace'
    local font, size = 'Monospace', 10   | prop['fontsize'] = 10
    l.style_default = style{             | prop['style.default'] =
      font = font, size = size,          |   'font:%(font),'..
      fore = l.colors.light_black        |   'size:%(fontsize),'..
      back = l.colors.white              |   'fore:%(color.light_black),'..
    }                                    |   'back:%(color.white)'
    ...                                  | ...

    -- File *theme/view.lua*             | -- Same file *theme.lua*!
                                         |
    ...                                  | ...
    -- Caret and Selection Styles.       | -- Caret and Selection Styles.
    buffer:set_sel_fore(true, 0x333333)  | buffer:set_sel_fore(true,
                                         |   prop_int['color.light_black'])
    buffer:set_sel_back(true, 0x999999)  | buffer:set_sel_back(true,
                                         |   prop_int['color.light_grey'])
    --buffer.sel_alpha =                 | --buffer.sel_alpha =
    --buffer.sel_eol_filled = true       |
    buffer.caret_fore = 0x4D4D4D         | buffer.caret_fore =
                                         |   prop_int['color.grey_black']
    ...                                  | ...

Notes:

1. Textadept 7's themes share its Lua state and set lexer colors and styles
   through named buffer properties.
2. Convert colors from "RRGGBB" string format to the "0xBBGGRR" number format
   that Textadept's API documentation uses consistently.
3. The only property names that matter are the "style._name_" ones. Other
   property names are arbitrary.
4. Instead of using variables, which are evaluated immediately, use "%(key)"
   notation, which substitutes the value of property "key" at a later point in
   time. This means you do not have to define properties before use. You can
   also modify existing properties without redefining the properties that depend
   on them. See the [customizing themes][] section for an example.
5. Set view properties related to colors directly in *theme.lua* now instead of
   a separate *view.lua*. You may use color properties defined earlier. Try to
   refrain from setting properties like `buffer.sel_eol_filled` which belong in
   a [*properties.lua*][] file.
6. The separate *buffer.lua* is gone. Use [*properties.lua*][] or a
   [language-specific module][].

[customizing themes]: 09_Themes.html#Customizing.Themes
[*properties.lua*]: 08_Preferences.html#Buffer.Properties
[language-specific module]: 07_Modules.html#Buffer.Properties

##### Theme Preference

Textadept 7 ignores the *~/.textadept/theme* and *~/.textadept/theme_term* files
that specified your preferred Textadept 6 theme. Use *~/.textadept/init.lua* to
[set a preferred theme][] instead. For example, if you had custom GUI and
terminal themes:

    -- File *~/.textadept/init.lua*
    gui.set_theme(not CURSES and 'custom' or 'custom_term')

You may still use absolute paths for themes instead of names.

[set a preferred theme]: 09_Themes.html#Setting.Themes

### Textadept 5 to 6

Textadept 6 introduces some API changes. These changes affect themes in
particular, so your themes may require upgrading.

Old API                              | Change | New API
-------------------------------------|:------:|--------
**buffer**                           |        |
annotation\_get\_text(line)          |Renamed |annotation\_text[line]
annotation\_set\_text(line, text)    |Renamed |annotation\_text[line] = text
auto\_c\_get\_current()              |Renamed |auto\_c\_current
auto\_c\_get\_current\_text()        |Renamed |auto\_c\_current\_text
get\_lexer\_language()               |Renamed |lexer\_language
get\_property(key)                   |Renamed |property[key]
get\_property\_expanded(key)         |Renamed |property\_expanded[key]
get\_tag(n)                          |Renamed |tag[n]
margin\_get\_text(line)              |Renamed |margin\_text[line]
margin\_set\_text(line, text)        |Renamed |margin\_text[line] = text
marker\_set\_alpha(n, alpha)         |Renamed |marker\_alpha[n] = alpha
marker\_set\_back(n, color)          |Renamed |marker\_back[n] = color
marker\_set\_back\_selected(n, color)|Renamed |marker\_back\_selected[n] = color
marker\_set\_fore(n, color)          |Renamed |marker\_fore[n] = color
set\_fold\_flags(flags)              |Renamed |fold\_flags = flags
set\_lexer\_language(name)           |Renamed |lexer\_language = name
style\_get\_font(n)                  |Renamed |style\_font[n]
**gui**                              |        |
gtkmenu()                            |Renamed |[menu()][]
**_G**                               |        |
user\_dofile(file)                   |Renamed |dofile(\_USERHOME..'/'..file)
**_M**                               |        |
lua.goto\_required()                 |Removed |N/A
php.goto\_required()                 |Removed |N/A
ruby.goto\_required()                |Removed |N/A
**_M.textadept.adeptsense**          |        |
complete\_symbol()                   |Replaced|[complete()][]
show\_documentation()                |Replaced|[show\_apidoc()][]
**_M.textadept.bookmarks**           |        |
N/A                                  |New     |[toggle()][]
add()                                |Renamed |toggle(true)
remove()                             |Renamed |toggle(false)
**_M.textadept.editing**             |        |
prepare\_for\_save()                 |Removed |N/A
**_M.textadept.menu**                |        |
rebuild\_command\_tables()           |Replaced|[set\_menubar()][]
**_M.textadept.run**                 |        |
execute()                            |Replaced|[run()][] and [compile()][]
**_M.textadept.session**             |        |
prompt\_load()                       |Replaced|[load()][]
prompt\_save()                       |Replaced|[save()][]

[menu()]: api/gui.html#menu
[complete()]: api/_M.textadept.adeptsense.html#complete
[show\_apidoc()]: api/_M.textadept.adeptsense.html#show_apidoc
[toggle()]: api/_M.textadept.bookmarks.html#toggle
[set\_menubar()]: api/_M.textadept.menu.html#set_menubar
[run()]: api/_M.textadept.run.html#run
[compile()]: api/_M.textadept.run.html#compile
[load()]: api/_M.textadept.session.html#load
[save()]: api/_M.textadept.session.html#save

### Textadept 4 to 5

Textadept 5 upgraded its copy of Lua from [5.1 to 5.2][]. Many old scripts are
not compatible and need to be upgraded. Since incompatible scripts may cause
crashes on startup, the following guide will help you migrate your scripts from
Textadept 4 to Textadept 5. While this guide is not exhaustive, it covers the
changes I had to make to Textadept's internals.

[5.1 to 5.2]: http://www.lua.org/manual/5.2/manual.html#8

#### API Changes

Old API        |Change  |New API
---------------|:------:|-------
**_G**         |        |
getfenv(f)     |Removed |N/A. Use:<br/>debug.getupvalue(f, 1)
loadstring()   |Replaced|load()
module()       |Removed |N/A
setfenv(f, env)|Removed |N/A. Use:<br/>debug.setupvalue(f, 1, env)<sup>\*</sup>
unpack()       |Renamed |table.unpack()
xpcall(f, msgh)|Changed |xpcall(f, msgh, ...)
**\_m**        |Renamed |**[\_M][]**<sup>†</sup>
**_m.textadept.editing**|       |
current\_word(action)   |Renamed|[select\_word()][]<sup>‡</sup>
**locale**              |Removed|N/A
localize(message)       |Renamed|\_G.[\_L][][message]
**os**                  |       |
code = execute(cmd)     |Changed|ok, status, code = execute(cmd)

<sup>\*</sup>In some cases, use `load()` with an environment instead:

    setfenv(loadstring(str), env)() --> load(str, nil, 'bt', env)()

<sup>†</sup>In Textadept, search for "\_m" and replace with "\_M" with the
"Match Case" and "Whole Words" options checked -- this is what I did when
upgrading Textadept's internals.

<sup>‡</sup>To delete, call `_M.textadept.keys.utils.delete_word()` or define
your own:

    local function delete_word()
      _M.textadept.editing.select_word()
      buffer:delete_back()
    end

[\_M]: api/_M.html
[select\_word()]: api/_M.textadept.editing.html#select_word
[\_L]: api/_L.html

#### Module Changes

You can use the following as a reference for converting your Lua 5.1 modules to
Lua 5.2:

    -- File *~/.textadept/modules/foo.lua*
    -- Lua 5.1                    | -- Lua 5.2
                                  |
                                  | local M = {}
                                  | --[[ This comment is for LuaDoc
    ---                           | ---
    -- This is the documentation  | -- This is the documentation
    -- for module foo.            | -- for module foo.
    module('foo', package.seeall) | module('foo')]]
                                  |
    ---                           | ---
    -- Documentation for bar.     | -- Documentation for bar.
    -- ...                        | -- ...
    --                            | -- @name bar
    function bar()                | function M.bar()
      ...                         |   ...
    end                           | end
                                  |
    function baz()                | function M.baz()
      bar()                       |   M.bar()
    end                           | end
                                  |
                                  | return M

    -- File *~/.textadept/init.lua*
    -- Lua 5.1                    | -- Lua 5.2
                                  |
    require 'textadept'           | _M.textadept = require 'textadept'
    require 'foo'                 | foo = require 'foo'

Notes:

1. Even though Lua 5.2 deprecates Lua 5.1's `module()`, Textadept 5 removes it.
2. Prefix all intern module tables and function calls with `M`.
3. Also, replace all instances (if any) of `_M` (a references created by
   `module()` that holds the current module table) with `M`.
4. You can use your existing LuaDoc comments by keeping the `module()` call
   commented out and adding `@name` tags.

#### Theme Changes

You can use the following as a reference for converting your Lua 5.1 themes to
Lua 5.2:

    -- File *~/.textadept/themes/theme/lexer.lua*
    -- Lua 5.1                       | -- Lua 5.2
                                     |
                                     | local l = lexer
    module('lexer', package.seeall)  | local color = l.color
                                     | local style = l.style
                                     |
    colors = {                       | l.colors = {
      ...                            |   ...
    }                                | }
                                     |
    style_nothing = style{}          | l.style_nothing = style{...}
    style_class = style{             | l.style_class = style{
      fore = colors.light_yellow     |   fore = l.colors.light_yellow
    }                                | }
    ...                              | ...
    style_identifier = style_nothing | l.style_identifier = l.style_nothing
                                     |
    ...                              | ...
                                     |
    style_default = style{           | l.style_default = style{
      ...                            |   ...
    }                                | }
    style_line_number = {            | l.style_line_number = {
      fore = colors.dark_grey,       |   fore = l.colors.dark_grey,
      back = colors.black            |   back = l.colors.black
    }                                | }
    ...                              | ...

Note the `l.` prefix before most identifiers.

### Textadept 3 to 4

#### Key and Menu Changes

Textadept 4 features a brand new set of key bindings and menu structure. It also
shows simple key bindings (not keychains) in menus. In order for key bindings to
appear in menus, `_m.textadept.menu` must know which commands map to which keys.
Therefore, the menu module needs to be `require`d *after* `_m.textadept.keys`.
If your *~/.textadept/init.lua* calls `require 'textadept'`, you do not have to
make any changes. If you load individual modules from `_m.textadept`, ensure
`_m.textadept.menu` loads after `_m.textadept.keys`.

Mac OSX has different modifier key definitions. A new `m` indicates ⌘ (command)
and `a` changed from ⌘ to ⌥ (alt/option). `c` remains ^ (control). Keep in mind
that ⌥ functions as a compose key for locale-dependent characters.

#### API Changes

Old API                  |Change | New API
-------------------------|:-----:|--------
**\_m.textadept.editing**|       |
select\_scope()          |Renamed|select\_style()
SAVE\_STRIPS\_WS         |Renamed|STRIP\_WHITESPACE\_ON\_SAVE

### Textadept 2 to 3

#### Module Changes

##### Core Extensions

The core extention modules moved from *core/ext/* to *modules/textadept/*.
Putting

    require 'textadept'

in your *~/.textadept/init.lua* loads all the modules you would expect. The
[preferences][] page has instructions on how to load specific modules.

[preferences]: 08_Preferences.html#User.Init

##### Autoloading

Key bindings in *~/.textadept/key_commands.lua* and snippets in
*~/.textadept/snippets.lua* no longer auto-load. Move them to your
*~/.textadept/init.lua* or a file loaded by *~/.textadept/init.lua*.

#### API Changes

Textadept has a brand new Lua [API][]. Old scripts and themes are likely not
compatible and need to be upgraded.

Old API                   |Change | New API
--------------------------|:-----:|--------
**_G**                    |       |
N/A                       |New    |[\_SCINTILLA][]
N/A                       |New    |[events][]
N/A                       |New    |[gui][]
**_m.textadept.lsnippets**|Renamed|**[_m.textadept.snippets][]**
**textadept**             |Removed|N/A
\_print()                 |Renamed|\_G.[gui.\_print()][]
buffer\_functions         |Renamed|\_G.[\_SCINTILLA.functions][]
buffer\_properties        |Renamed|\_G.[\_SCINTILLA.properties][]
buffers                   |Renamed|\_G.[\_BUFFERS][]
check\_focused\_buffer()  |Renamed|\_G.gui.check\_focused\_buffer()
clipboard\_text           |Renamed|\_G.[gui.clipboard\_text][]
command\_entry            |Renamed|\_G.[gui.command\_entry][]
constants                 |Renamed|\_G.[\_SCINTILLA.constants][]
context\_menu             |Renamed|\_G.[gui.context\_menu][]
dialog                    |Renamed|\_G.[gui.dialog()][]
docstatusbar\_text        |Renamed|\_G.[gui.docstatusbar\_text][]
events                    |Renamed|\_G.[events][]
events.add\_handler()     |Renamed|\_G.[events.connect()][]
events.handle()           |Renamed|\_G.[events.emit()][]
find                      |Renamed|\_G.[gui.find][]
focused\_doc\_pointer     |Renamed|\_G.gui.focused\_doc\_pointer
get\_split\_table()       |Renamed|\_G.[gui.get\_split\_table()][]
goto\_view()              |Renamed|\_G.[gui.goto\_view()][]
gtkmenu()                 |Renamed|\_G.[gui.gtkmenu()][]
iconv()                   |Renamed|\_G.[string.iconv()][]
menubar                   |Renamed|\_G.[gui.menubar][]
new\_buffer()             |Renamed|\_G.[new\_buffer()][]
print()                   |Renamed|\_G.[gui.print()][]
quit()                    |Renamed|\_G.[quit()][]
reset()                   |Renamed|\_G.[reset()][]
session\_file             |Renamed|\_G.\_SESSIONFILE
size                      |Renamed|\_G.[gui.size][]
statusbar\_text           |Renamed|\_G.[gui.statusbar\_text][]
switch\_buffer()          |Renamed|\_G.[gui.switch\_buffer()][]
title                     |Renamed|\_G.[gui.title][]
user\_dofile()            |Renamed|\_G.user\_dofile()
views                     |Renamed|\_G.[\_VIEWS][]

[API]: api
[\_SCINTILLA]: api/_SCINTILLA.html
[events]: api/events.html
[gui]: api/gui.html
[_m.textadept.snippets]: api/_M.textadept.snippets.html
[gui.\_print()]: api/gui.html#_print
[\_SCINTILLA.functions]: api/_SCINTILLA.html#functions
[\_SCINTILLA.properties]: api/_SCINTILLA.html#properties
[\_BUFFERS]: api/_G.html#_BUFFERS
[gui.clipboard\_text]: api/gui.html#clipboard_text
[gui.command\_entry]: api/gui.command_entry.html
[\_SCINTILLA.constants]: api/_SCINTILLA.html#constants
[gui.context\_menu]: api/gui.html#context_menu
[gui.dialog()]: api/gui.html#dialog
[gui.docstatusbar\_text]: api/gui.html#docstatusbar_text
[events.connect()]: api/events.html#connect
[events.emit()]: api/events.html#emit
[gui.find]: api/gui.find.html
[gui.get\_split\_table()]: api/gui.html#get_split_table
[gui.goto\_view()]: api/gui.html#goto_view
[gui.gtkmenu()]: api/gui.html#gtkmenu
[string.iconv()]: api/string.html#iconv
[gui.menubar]: api/gui.html#menubar
[new\_buffer()]: api/_G.html#new_buffer
[gui.print()]: api/gui.html#print
[quit()]: api/_G.html#quit
[reset()]: api/_G.html#reset
[gui.size]: api/gui.html#size
[gui.statusbar\_text]: api/gui.html#statusbar_text
[gui.switch\_buffer()]: api/gui.html#switch_buffer
[gui.title]: api/gui.html#title
[\_VIEWS]: api/_G.html#_VIEWS

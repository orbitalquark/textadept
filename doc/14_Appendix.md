# Appendix

## Lua Patterns

The following is taken from the [Lua 5.2 Reference Manual][].

_Character Class:_

A character class is used to represent a set of characters. The following
combinations are allowed in describing a character class:

* **_`x`_:** (where _x_ is not one of the magic characters `^$()%.[]*+-?`)
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

## Ncurses Compatibility

Textadept 5.5 beta introduced an ncurses version that can run in a terminal
emulator. However, since ncurses is quite low-level in terms of graphics
capability compared to GTK+, the ncurses version of Textadept lacks some
features in its editing component Scintilla:

* Any settings with alpha values are not supported.
* Autocompletion lists cannot show images (pixmap surfaces are not supported).
  Instead, they show the first character in the string passed to
  [`buffer:register_image()`][].
* Buffered and two-phase drawing is not supported.
* Call tip arrows are not displayed (`surface->Polygon()` is not supported for
  drawing arrow shapes).
* Caret settings like period, line style, and width are not supported
  (terminals use block carets with their own period definitions).
* Code pages other than UTF-8 have not been tested and it is possible ncurses
  does not support them.
* Edge lines are not displayed properly (the line is drawn over by text lines).
* Extra ascent and decent for lines is not supported.
* Fold lines are not supported (`surface->LineTo()` is not supported).
* Indentation guides are not visible (pixmap surfaces are not supported).
* Indicators are not displayed (they would be drawn over by text lines).
* Insert mode caret is not drawn properly (no way to detect it from within
  `surface->FillRectangle()`).
* Margins are overwritten by long lines when scrolling to the right.
* Marker types other than `SC_MARK_CHARACTER` are not drawn (pixmap surfaces are
  not supported and `surface->LineTo()` is not supported for drawing marker
  shapes).
* Mouse interactions, cursor types, and hotspots are not supported.
* Only 8 colors are supported: black (0x000000), red (0xFF0000), green
  (0x00FF00), yellow (0xFFFF00), blue (0x0000FF), magenta (0xFF00FF), cyan
  (0x00FFFF), and white (0xFFFFFF). Even if your terminal uses a different color
  map, you must use these color values with Scintilla; unrecognized colors are
  set to white by default. Lexers can use up to 8 more colors by setting the
  lexer style's "bold" attribute.
* Scroll bars are not supported.
* Some styles settings like font name, font size, and italic do not display
  properly (terminals use one only font, size and variant).
* Viewing whitespace does not show the "Tab" character arrows
  (`surface->LineTo()` is not supported for drawing arrows).
* Visual wrap flags are not supported (`surface->LineTo()` is not supported).
* X selections (primary and secondary) are not integrated into the clipboard.
* Zoom is not supported (terminal font size is fixed).

[`buffer:register_image()`]: api/buffer.html#buffer.register_image

## Migration Guides

### Textadept 5 to 6

Textadept 6 introduces some API changes.

#### Function Changes

##### `buffer`

Some of the "get" and "set" functions in `buffer` have been converted to
properties:

* `buffer:annotation_get_text(line)` -> `buffer.annotation_text[line]`
* `buffer:annotation_set_text(line, text)` ->
  `buffer.annotation_text[line] = text`
* `buffer:auto_c_get_current()` -> `buffer.auto_c_current`
* `buffer:auto_c_get_current_text()` -> `buffer.auto_c_current_text`
* `buffer:get_lexer_language()` -> `buffer.lexer_language`
* `buffer:get_property(key)` -> `buffer.property[key]`
* `buffer:get_property_expanded(key)` -> `buffer.property_expanded[key]`
* `buffer:get_tag(tag_num)` -> `buffer.tag[tag_num]`
* `buffer:margin_get_text(line)` -> `buffer.margin_text[line]`
* `buffer:margin_set_text(line, text)` -> `buffer.margin_text[line] = text`
* `buffer:marker_set_alpha(marker_num, alpha)` ->
  `buffer.marker_alpha[marker_num] = alpha`
* `buffer:marker_set_back(marker_num, color)` ->
  `buffer.marker_back[marker_num] = color`
* `buffer:marker_set_back_selected(marker_num, color)` ->
  `buffer.marker_back_selected[marker_num] = color`
* `buffer:marker_set_fore(marker_num, color)` ->
  `buffer.marker_fore[marker_num] = color`
* `buffer:set_fold_flags(flags)` -> `buffer.fold_flags = flags`
* `buffer:set_lexer_language(language_name)` ->
  `buffer.lexer_language = language_name`
* `buffer:style_get_font(style_num)` -> `buffer.style_font[style_num]`

These changes will affect custom themes.

##### `goto_required`

`_M.lua.goto_required()`, `_M.php.goto_required()`, and
`_M.ruby.goto_required()` have all been removed. They are inaccurate when
projects re-define or define their own search paths.

##### `prepare_for_save`

`_M.textadept.editing.prepare_for_save()` was moved directly into an event
handler and cannot be called separately anymore.

##### Sessions

`_M.textadept.session.prompt_load()` and `_M.textadept.session.prompt_save()`
functionality has been moved into [`_M.textadept.session.load()`][] and
[`_M.textadept.session.save()`][]. Therefore, replace all instances of
`prompt_load` and `prompt_save` with `load` and `save` respectively.

[`_M.textadept.session.load()`]: api/_M.textadept.session.html#load
[`_M.textadept.session.save()`]: api/_M.textadept.session.html#save

##### Adeptsense

`_M.textadept.adeptsense.complete_symbol()` and
`_M.textadept.adeptsense.show_documentation()` functionality has been moved into
[`_M.textadept.adeptsense.complete()`][] and
[`_M.textadept.adeptsense.show_apidoc()`][]. Therefore, replace all instances
of `complete_symbol` and `show_documentation` with `complete` and `show_apidoc`.

[`_M.textadept.adeptsense.complete()`]: api/_M.textadept.adeptsense.html#complete
[`_M.textadept.adeptsense.show_apidoc()`]: api/_M.textadept.adeptsense.html#show_apidoc

##### `user_dofile`

`_G.user_dofile()` was removed. Use `dofile(_USERHOME..'/file.lua')` instead.

##### `gtkmenu`

`gui.gtkmenu()` was renamed to `gui.menu()`. Therefore, replace all instances of
`gui.gtkmenu` with `gui.menu`.

##### Bookmarks

`_M.textadept.bookmarks.add()` and `_M.textadept.bookmarks.remove()` were
consolidated into [`_M.textadept.bookmarks.toggle()`][]. Replace `add()` with
`toggle(true)` and `remove()` with `toggle(false)`. `toggle()` functionality
otherwise remains the same.

[`_M.textadept.bookmarks.toggle()`]: api/_M.textadept.bookmarks.html#toggle

##### `rebuild_command_tables`

`_M.textadept.menu.rebuild_command_tables()` was integrated into
[`_M.textadept.menu.set_menubar()`][]. Therefore, remove all calls to
`rebuild_command_tables()` after `set_menubar()`.

[`_M.textadept.menu.set_menubar()`]: api/_M.textadept.menu.html#set_menubar

##### `execute`

`_M.textadept.run.execute()` was removed. Use [`_M.textadept.run.run()`][] and
[`_M.textadept.run.compile()`][] exclusively.

[`_M.textadept.run.run()`]: api/_M.textadept.run.html#run
[`_M.textadept.run.compile()`]: api/_M.textadept.run.html#compile

### Textadept 4 to 5

Lua has been upgraded from [5.1 to 5.2][], so many scripts written for Textadept
4 are not compatible with Textadept 5. Since incompatible scripts may cause
crashes on startup, the following guide will help you migrate your scripts from
Textadept 4 to Textadept 5. While this guide is not exhaustive, it covers the
changes I had to make to Textadept's internals.

[5.1 to 5.2]: http://www.lua.org/manual/5.2/manual.html#8

#### Module Changes

##### Syntax Changes

Although Lua 5.2 only deprecates Lua 5.1's `module` syntax, Textadept 5 removes
it. Therefore, replace

    -- File ~/.textadept/modules/foo.lua
    module('_m.foo', package.seeall)

    function bar()
      ...
    end

    ...

and

    -- File ~/.textadept/init.lua
    require 'textadept'
    require 'foo'

with

    -- File ~/.textadept/modules/foo.lua
    local M = {}

    function M.bar()
      ...
    end

    ...

    return M

or

    local M = {}
    local _ENV = M
    if setfenv then setfenv(1, _ENV) end -- LuaJIT support

    function bar()
      ...
    end

    function baz()
      bar()
    end

    return M

and

    -- File ~/.textadept/init.lua
    require 'textadept'
    _M.foo = require 'foo'

Please remember that, as stated in the documentation, `require 'textadept'` is a
special case and `_M.textadept = require 'textadept'` is not necessary because
of internal dependencies. All other modules need the
`_M.module = require 'module'` construct.

Notice that `_M` is the new module table instead of `_m`. More on this
[later](#Global.Module.Table).

##### Module References

Replace all instances of `_M` (a reference created by `module()` that holds the
current module table) with `M` (the local module table you created).

Also, prefix all instances of internal module function calls with `M` if you are
not using `_ENV`. For example, change

    module('foo', package.seeall)

    function bar()
      ...
    end

    function baz()
      bar()
    end

to

    local M = {}

    function M.bar()
      ...
    end

    function M.baz()
      M.bar()
    end

    return M

##### LuaDoc

If you use LuaDoc for your modules, you can still document them like this:

    local M = {}

    --[[ This comment is for LuaDoc
    ---
    -- This is the documentation for module foo.
    module('foo')]]

    ---
    -- Documentation for bar.
    -- ...
    -- @name bar
    function M.bar()
      ...
    end

    return M

##### Global Module Table

Originally, I wanted to use `_M` as the global table that contains modules, but
Lua 5.1's modules used `_M` silently, so I had to settle with `_m`. Now that
modules have been removed, `_M` is available again and is used. Therefore,
replace all instances of `_m` with `_M`. In Textadept, you can easily do a
search and replace with "Match Case" and "Whole Words" checked -- this is what I
did when upgrading Textadept's internals.

#### Function Changes

##### `unpack`

`unpack()` has been renamed to `table.unpack()`. Replace all instances of
`unpack` with `table.unpack`.

##### `xpcall`

`xpcall()` accepts error function parameters so you can change code from

    local args = {...}
    xpcall(function() return f(unpack(args)) end, error_function)

to

    xpcall(f, error_function, ...)

However, this is not required.

##### `loadstring`

`loadstring()` has been replaced by `load()` since the latter now recognizes a
string chunk. Replace all instances of `loadstring` with `load`.

##### `setfenv`

`setfenv()` has been removed. In some cases, use `load()` with an environment
instead. For example, change

    local f, err = loadstring(command)
    if err then error(err) end
    setfenv(f, env)()

to

    local f, err = load(command, nil, 'bt', env)
    if err then error(err) end
    f()

(The `'bt'` is necessary for loading both binary and text chunks.)

If instead you want to set a function's environment, change

    setfenv(f, env)

to

    debug.setupvalue(f, 1, env)

##### `getfenv`

`getfenv()` has been removed. Change

    local env = getfenv(f)

to

    local debug = require 'debug'
    local env = debug.getupvalue(f, 1)

##### `os.execute`

`os.execute()`'s function parameters have changed. If you are only interested in
the return code, change

    local code = os.execute(cmd)

to

    local _, _, code = os.execute(cmd)

##### `localize`

Localization is done using a global table [`_L`][] instead of calling
`locale.localize()`. Replace all instances of `locale.localize('message')` with
`_L['message']`. This allows messages to be modified via scripts if desirable.

[`_L`]: api/_L.html

##### `current_word`

`_M.textadept.editing.current_word()` has been renamed to `select_word()` and
does not take any parameters. There is a `_M.textadept.keys.utils.delete_word()`
function that replaces `current_word('delete')`. You can use it or create a new
function:

    local function delete_word()
      _M.textadept.editing.select_word()
      buffer:delete_back()
    end

#### Theme Changes

Any custom themes need to be changed to remove the `module` syntax. Usually this
involves changing

    module('lexer', package.seeall)

    colors = {
      ...
    }

    style_nothing = style { ... }
    style_class = style { fore = colors.light_yellow }
    ...
    style_identifier = style_nothing

    ...

    style_default = style {
      ...
    }
    style_line_number = { fore = colors.dark_grey, back = colors.black }
    ...

to

    local l, color, style = lexer, lexer.color, lexer.style

    l.colors = {
      ...
    }

    l.style_nothing = style { ... }
    l.style_class = style { fore = l.colors.light_yellow }
    ...
    l.style_identifier = l.style_nothing

    ...

    l.style_default = style {
      ...
    }
    l.style_line_number = { fore = l.colors.dark_grey, back = l.colors.black }
    ...

Notice the `l.` prefix before most identifiers.

### Textadept 3 to 4

#### Key and Menu Changes

Textadept 4 allow key bindings to appear in menus, but only simple ones, not
keychains. Therefore, Textadept's key bindings have changed radically, as has
the menu structure and menu mnemonics. In order for key bindings to appear in
menus, `_m.textadept.menu` needs to know which commands are assigned to which
keys. Therefore, the menu module needs to be `require`d *after*
`_m.textadept.keys`. If your *~/.textadept/init.lua* is calling
`require 'textadept'`, you do not have to make any changes. If you are loading
individual modules from `_m.textadept`, ensure `_m.textadept.menu` is loaded
after `_m.textadept.keys`.

On Mac OSX, key binding definition has changed. `m` is now ⌘ (command) and `a`
is now ⌥ (alt/option). `c` remains ^ (control). Previously `a` was ⌘ and ⌥ was
undefined. Please note, however, that not all ⌥ combinations by themselves will
work since that key is typically used to compose locale-dependent characters.

#### Function Changes

##### `select_scope`

`_m.textadept.editing.select_scope()` was renamed to `select_style()`.
Therefore, replace all instances of `_m.textadept.editing.select_scope` with
`_m.textadept.editing.select_style`.

##### `SAVE_STRIPS_WS`

`_m.textadept.editing.SAVE_STRIPS_WS` was renamed to `STRIP_WHITESPACE_ON_SAVE`.
Replace all instances of `_m.textadept.editing.SAVE_STRIPS_WS` with
`_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE`.

### Textadept 2 to 3

#### Module Changes

##### Core Extensions

There are no more core extention modules (previously in *core/ext/*). They have
been relocated to *modules/textadept/* so putting

    require 'textadept'

in your *~/.textadept/init.lua* will load all the modules you would expect.
Please see the [preferences][] page for instructions on how to load specific
modules.

[preferences]: 08_Preferences.html#User.Init

##### Autoloading

Key bindings in *~/.textadept/key_commands.lua* and snippets in
*~/.textadept/snippets.lua* are no longer auto-loaded. Instead, modify
[`keys`][] and/or [`snippets`][] from within your *~/.textadept/init.lua* or a
file loaded by *~/.textadept/init.lua*.

[`keys`]: api/keys.html
[`snippets`]: api/_M.textadept.snippets.html

#### Function Changes

Textadept has a brand new Lua [API][]. It is likely that any external scripts,
including themes, need to be rewritten.

Here is a summary of API changes:

* `_m.textadept.lsnippets` renamed to [`_m.textadept.snippets`][].
* `textadept.events` renamed to [`_G.events`][].
  * `events.handle()` renamed to [`events.emit()`][].
  * `events.add_handler()` renamed to [`events.connect()`][].
* `textadept.constants` renamed to [`_SCINTILLA.constants`][].
* `textadept.buffer_functions` renamed to [`_SCINTILLA.functions`][].
* `textadept.buffer_properties` renamed to [`_SCINTILLA.properties`][].
* `textadept.buffers` renamed to [`_BUFFERS`][].
* `textadept.views` renamed to [`_VIEWS`][].
* New [`gui`][] module.
  * Renamed `textadept._print()` to [`gui._print()`][].
  * Renamed `textadept.check_focused_buffer()` to `gui.check_focused_buffer()`.
  * Renamed `textadept.clipboard_text` to `gui.clipboard_text`.
  * Renamed `textadept.context_menu` to `gui.context_menu`.
  * Renamed `textadept.command_entry` to [`gui.command_entry`][].
  * Renamed `textadept.dialog` to [`gui.dialog()`][].
  * Renamed `textadept.docstatusbar_text` to `gui.docstatusbar_text`.
  * Renamed `textadept.find` to [`gui.find`][].
  * Renamed `textadept.focused_doc_pointer` to `gui.focused_doc_pointer`.
  * Renamed `textadept.get_split_table()` to [`gui.get_split_table()`][].
  * Renamed `textadept.gtkmenu()` to [`gui.gtkmenu()`][].
  * Renamed `textadept.goto_view()` to [`gui.goto_view()`][].
  * Renamed `textadept.menubar` to `gui.menubar`.
  * Renamed `textadept.print()` to [`gui.print()`][].
  * Renamed `textadept.size` to `gui.size`.
  * Renamed `textadept.statusbar_text` to `gui.statusbar_text`.
  * Renamed `textadept.switch_buffer()` to [`gui.switch_buffer()`][].
  * Renamed `textadept.title` to `gui.title`.
  * Renamed `textadept.new_buffer()` to [`new_buffer()`][].
  * Renamed `textadept.quit()` to [`quit()`][].
  * Renamed `textadept.reset()` to [`reset()`][].
  * Renamed `textadept.user_dofile()` to [`user_dofile()`][].
  * Renamed `textadept.iconv()` to [`string.iconv()`][].
  * Renamed `textadept.session_file` to `_SESSIONFILE`.
* Removed global `textadept` module.

[API]: api
[`_m.textadept.snippets`]: api/_M.textadept.snippets.html
[`_G.events`]: api/events.html
[`events.emit()`]: api/events.html#emit
[`events.connect()`]: api/events.html#connect
[`_SCINTILLA.constants`]: api/_SCINTILLA.html#constants
[`_SCINTILLA.functions`]: api/_SCINTILLA.html#functions
[`_SCINTILLA.properties`]: api/_SCINTILLA.html#properties
[`_BUFFERS`]: api/_G.html#_BUFFERS
[`_VIEWS`]: api/_G.html#_VIEWS
[`gui`]: api/gui.html
[`gui._print()`]: api/gui.html#_print
[`gui.command_entry`]: api/gui.command_entry.html
[`gui.dialog()`]: api/gui.html#dialog
[`gui.find`]: api/gui.find.html
[`gui.get_split_table()`]: api/gui.html#get_split_table
[`gui.gtkmenu()`]: api/gui.html#gtkmenu
[`gui.goto_view()`]: api/gui.html#goto_view
[`gui.print()`]: api/gui.html#print
[`gui.switch_buffer()`]: api/gui.html#switch_buffer
[`new_buffer()`]: api/_G.html#new_buffer
[`quit()`]: api/_G.html#quit
[`reset()`]: api/_G.html#reset
[`user_dofile()`]: api/_G.html#user_dofile
[`string.iconv()`]: api/string.html#iconv

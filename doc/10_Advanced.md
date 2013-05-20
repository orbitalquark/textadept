# Advanced

## Command Entry

The command entry grants access to Textadept's Lua state. Press `Ctrl+E` (`⌘E`
on Mac OSX | `M-C` in curses) to display the entry. It is useful for debugging,
inspecting, and entering `buffer` or `view` commands. If you try to cause
instability in Textadept's Lua state, you will probably succeed so be careful.
The [Lua API][] lists available commands. The command entry provides abbreviated
commands for [`buffer`][], [`view`][] and [`gui`][]: you may reduce the
`buffer:append_text('foo')` command to `append_text('foo')`. Therefore, use
`_G.print()` for Lua's `print()` since `print()` expands to [`gui.print()`][].
These commands are runnable on startup using the `-e` and `--execute` command
line switches.

![Command Entry](images/commandentry.png)

[Lua API]: api/index.html
[`buffer`]: api/buffer.html
[`view`]: api/view.html
[`gui`]: api/gui.html
[`gui.print()`]: api/gui.html#print

### Tab Completion

The command entry also provides tab-completion for functions, variables, tables,
etc. Press the `Tab` (`⇥` on Mac OSX | `Tab` in curses) key to display a list of
available completions. Use the arrow keys to make a selection and press `Enter`
(`↩` | `Enter`) to insert it.

![Command Completion](images/commandentrycompletion.png)

### Extending

Executing Lua commands is just one of the many tools the command entry functions
as. For example, *modules/textadept/find.lua* and *modules/textadept/keys.lua*
extend it to implement [incremental search][].

[incremental search]: api/gui.find.html#find_incremental

## Command Selection

If you did not disable the menu in your [preferences][], then pressing
`Ctrl+Shift+E` (`⌘⇧E` on Mac OSX | `M-S-C` in curses) brings up the command
selection dialog. Typing part of any command filters the list, with spaces being
wildcards. This is an easy way to run commands without navigating the menus,
using the mouse, or remembering key bindings. It is also useful for looking up
particular key bindings quickly. Note: the key bindings in the dialog do not
look like those in the menu. Textadept uses this different notation internally.
Learn more about it in the [keys LuaDoc][].

[preferences]: 08_Preferences.html#User.Init
[keys LuaDoc]: api/keys.html

## Shell Commands and Filtering Text

Sometimes using an existing shell command to manipulate text is easier than
using the command entry. An example would be sorting all text in a buffer (or a
selection). One way to do this from the command entry is:

    ls={}; for l in buffer:get_text():gmatch('[^\n]+') do ls[#ls+1]=l end;
    table.sort(ls); buffer:set_text(table.concat(ls, '\n'))

A simpler way is pressing `Ctrl+|` (`⌘|` on Mac OSX | `^\` in curses), entering
the shell command `sort`, and pressing `Enter` (`↩` | `Enter`).

This feature determines the standard input (stdin) for shell commands as
follows:

* If text is selected and spans multiple lines, all text on the lines containing
  the selection is used. However, if the end of the selection is at the
  beginning of a line, only the EOL (end of line) characters from the previous
  line are included as input. The rest of the line is excluded.
* If text is selected and spans a single line, only the selected text is used.
* If no text is selected, the entire buffer is used.

The standard output (stdout) of the command replaces the input text.

## Remote Control

Since Textadept executes arbitrary Lua code passed via the `-e` and `--execute`
command line switches, a side-effect of [single instance][] functionality on the
platforms that support it is that you can remotely control the original
instance. For example:

    ta ~/.textadept/init.lua &
    ta -e "events.emit(events.FIND, 'require')"

[single instance]: 02_Installation.html#Single.Instance

# FAQ

**Q:**
On Linux I get a `error while loading shared libraries: <lib>: cannot open`
`shared object file: No such file or directory` when trying to run Textadept.
How do I fix it?

**A:**
It is difficult to provide a binary that runs on all Linux platforms since the
library versions installed vary widely from distribution to distribution. For
example, `libpng14` has been available for many distributions since late 2009
while the latest 2012 Ubuntu still uses `libpng12`. Unfortunately in these
cases, the best idea is to compile Textadept. This process is actually very
simple though. See the [compiling][] page. Only the GTK+ development libraries
are needed for the GUI version. (The ncurses development library is required for
the terminal version.)

[compiling]: 12_Compiling.html

- - -

**Q:**
I downloaded the Linux version, but when I try to compile it, some files are not
found. Where do I get these files?

**A:**
You need to download the source version of the release, not the binary version.
The source version contains all the files necessary for compiling Textadept.

- - -

**Q:**
Autocompletion does not work for my language. Why not?

**A:**
`modules/textadept/key_commands.lua` calls
[`_M.textadept.editing.autocomplete_word()`][] with `'%w_'`, which in [Lua][] is
all ASCII alphanumeric characters and underscores. You can add character ranges
in `'\xXX-\xXX'` or `'\ddd-\ddd'` [format][] (e.g. `'%w_\127-\255'`).
Unfortunately this probably will not work for unicode.

[`_M.textadept.editing.autocomplete_word()`]: api/_M.textadept.editing.html#autocomplete_word
[Lua]: 14_Appendix.html#Lua.Patterns
[Format]: http://www.lua.org/manual/5.2/manual.html#3.1

- - -

**Q:**
When I click the "Compile" or "Run" menu item (or execute the key command),
either nothing happens or the wrong command is executed. How can I tell
Textadept which command to run?

**A:**
Take a look at these [commands][].

[commands]: http://foicica.com/wiki/run-supplemental

- - -

**Q:**
Clicking "Block Comment" (or executing the key command) does nothing. Why?

**A:**
Take a look at these [comments][].

[comments]: http://foicica.com/wiki/comment-supplemental

- - -

**Q:**
The ncurses version does not support feature _x_ the GUI version does. Is this a
bug?

**A:**
Maybe. Some terminals do not recognize certain key commands like `Shift+Arrow`
for making selections. Linux's virtual terminals (the ones accessible with
`Ctrl+Alt+FunctionKey`) are an example. GNOME Terminal, LXTerminal and XTerm
seem to work fine. rxvt and rxvt-unicode do not work out of the box, but may be
configurable.

Please see the [ncurses compatibility][] section of the appendix. If the feature
in question is not listed there, it may be a bug. Please [contact][] me with any
bug reports.

[ncurses compatibility]: 14_Appendix.html#Ncurses.Compatibility
[contact]: README.html#Contact

- - -

**Q:**
Pressing "Control+O" in the ncurses version on Mac OSX does not do anything.
Why?

**A:**
For whatever reason, "Control+O" is discarded by the terminal driver. To enable
it, run `stty discard undef` first. You can put the command in your `~/.bashrc`
or `~/.bash_profile` to make it permanent.

- - -

**Q.**
After upgrading to Textadept >= 5 from Textadept 4, Textadept crashes hard with
no messages. What can I do?

**A:**
You likely have old modules that are not compatible with Textadept >= 5. Most
offending modules use the `module()` Lua 5.1 function which was removed in Lua
5.2. You can temporarily move your `~/.textadept/` directory elsewhere and
restart Textadept to be sure old modules are causing problems. You can correct
them using the [migration guide][].

[migration guide]: 14_Appendix.html#Textadept.4.to.5

- - -

**Q:**
Are my Textadept 5.x scripts compatible with Textadept 6.x?

**A:**
Maybe. There were some API changes. See the [migration guide][]. Most themes are
not compatible.

[migration guide]: 14_Appendix.html#Textadept.5.to.6

- - -

**Q:**
Why does Textadept remember its window size but not its window position?

**A:**
Your window manager is to blame. Textadept is not responsible for, and should
never attempt to set its window position.

- - -

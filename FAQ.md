# FAQ

**Q:**
What is the difference between *textadept* and *textadeptjit*? Which one should
I use?

**A:**
*textadept* uses Lua 5.2 while *textadeptjit* uses [LuaJIT][], which is based on
Lua 5.1. Other than access to the [FFI Library][], *textadeptjit* does not
provide any noteworthy benefits. It used to be the case that *textadeptjit* was
slightly faster when loading large files, but Textadept 6.1 was the last version
that had a noticible difference between the two. *textadept* is recommended.

[LuaJIT]: http://luajit.org
[FFI library]: http://luajit.org/ext_ffi.html

- - -

**Q:**
On Linux I get a `error while loading shared libraries: <lib>: cannot open`
`shared object file: No such file or directory` when trying to run Textadept.
How do I fix it?

**A:**
It is difficult to provide a binary that runs on all Linux platforms since the
library versions installed vary widely from distribution to distribution. For
example, "libpng14" has been available for many distributions since late 2009
while the latest 2012 Ubuntu still uses "libpng12". Unfortunately in these
cases, the best idea is to compile Textadept. This process is actually very
simple though. See the [compiling][] page. Only the GTK+ development libraries
are needed for the GUI version. (A development library for a curses
implementation is required for the terminal version.)

[compiling]: 12_Compiling.html

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
The curses version does not support feature _x_ the GUI version does. Is this a
bug?

**A:**
Maybe. Some terminals do not recognize certain key commands like `Shift+Arrow`
for making selections. Linux's virtual terminals (the ones accessible with
`Ctrl+Alt+FunctionKey`) are an example. GNOME Terminal, LXTerminal and XTerm
seem to work fine. rxvt and rxvt-unicode do not work out of the box, but may be
configurable.

Please see the [curses compatibility][] section of the appendix. If the feature
in question is not listed there, it may be a bug. Please [contact][] me with any
bug reports.

[curses compatibility]: 14_Appendix.html#Curses.Compatibility
[contact]: README.html#Contact

- - -

**Q:**
Pressing `^O` in the curses version on Mac OSX does not do anything. Why?

**A:**
For whatever reason, `^O` is discarded by the terminal driver. To enable it, run
`stty discard undef` first. You can put the command in your *~/.bashrc* or
*~/.bash_profile* to make it permanent.

- - -

**Q:**
Why does Textadept remember its window size but not its window position?

**A:**
Your window manager is to blame. Textadept is not responsible for, and should
never attempt to set its window position.

- - -

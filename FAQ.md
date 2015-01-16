# FAQ

**Q:**
I upgraded to Textadept 7 and the editor displays a strange error message on
startup and/or exits. Also my themes do not seem to work anymore.

**A:**
Textadept 7 introduced API changes and a completely new theme implementation.
Please see the [migration guide][] for more information. It may help to either
delete your old `~/.textadept/` folder or move everything within it somewhere
else before gradually copying those files back to see which of them causes an
error.

[migration guide]: manual.html#Textadept.6.to.7

- - -

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
cases, the best idea is to [compile][] Textadept. This process is actually very
simple though. Only the GTK+ development libraries are needed for the GUI
version. (A development library for a curses implementation is required for the
terminal version.)

[compile]: manual.html#Compiling

- - -

**Q:**
Why can't Textadept handle HUGE files very well?

**A:**
Textadept is an editor for programmers. It is unlikely a programmer would be
editing a gigantic log file. There are other tools for that case.

- - -

**Q:**
When I open a file in a non-English language, I see a lot of strange characters.

**A:**
Textadept was not able to detect the file's encoding correctly. You'll need to
[help it][].

[help it]: manual.html#Buffer.Encodings

- - -

**Q:**
When I click the "Compile" or "Run" menu item (or execute the key command),
either nothing happens or the wrong command is executed. How can I tell
Textadept which command to run?

**A:**
Please see the LuaDoc on [compile and run commands][].

[compile and run commands]: api.html#_M.Compile.and.Run

- - -

**Q:**
In Linux, pressing `^Z` suspends Textadept instead of performing an "Undo"
action. How can I disable suspend and perform "Undo" instead?

**A:**
Place the following in your `~/.textadept/init.lua` file:

    events.connect(events.SUSPEND, function()
      buffer:undo()
      return true
    end, 1)

- - -

**Q:**
In Linux, middle-clicking in the curses version does not paste the primary
selection and selecting text does copy to the primary selection. All other
terminal apps support this functionality, why not Textadept?

**A:**
It does; use the `Shift` modifier key with your middle-clicking and text
selecting. Textadept interprets non-`Shift`ed mouse events like a GUI
application.

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

[curses compatibility]: manual.html#Curses.Compatibility
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
How can I get the terminal version on Mac OSX to show more than 8 colors?

**A:**
Enable the "Use bright colors for bold text" setting in your Terminal.app
preferences.

- - -

**Q:**
Why does Textadept remember its window size but not its window position?

**A:**
Your window manager is to blame. Textadept is not responsible for, and should
never attempt to set its window position.

- - -

**Q:**
I'm trying to compile Textadept from one of the download packages, but get some
obscure errors in the `scintilla/term/`, `gtdialog/`, or `scintillua/`
directories. What happened?

**A:**
Prior to Textadept 7.5, some of the dependencies Textadept downloads are the
latest archives in their respective version control repositories. Occasionally
there are compile-time incompatibilities with these "bleeding-edge" downloads.
The solution is to go to the appropriate repository, identify the last revision
whose date is before the release date of your Textadept version, and download
the archive for that revision.

For example, if you have Textadept 7.1 and cannot build the terminal version due
to a file in the `scintilla/term/` directory, go to [scinterm hg][] and look for
the revision before 11 November 2013 (which happens to be [changeset 60][] from
23 October 2013), click on it, download the zip from the link near the top of
the page, and replace the problematic file.

[scinterm hg]: http://foicica.com/hg/scinterm
[changeset 60]: http://foicica.com/hg/scinterm/rev/ea13ae30cfab

- - -

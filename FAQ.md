# FAQ

**Q:**
If Textadept is so minimalist, why are the downloads around 10MB in size and the
unzipped folders 10s of MBs in size?

**A:**
Each download contains 2 executables: a GUI version and a terminal version.
Furthermore, the Windows and OSX packages bundle in GTK+ runtimes, accounting
for some 3/4 of the total application size. (GTK+ is the cross-platform GUI
toolkit Textadept uses.) Then, starting in version 10, in order to be able to
run on older Linux systems whose libstdc++ does not support newer C++11 symbols,
the Linux executables statically link in a newer version of libstdc++. Finally,
nightly builds are compiled with debug symbols enabled in order to aid debugging
of various issues.

- - -

**Q:**
On Linux I get a `error while loading shared libraries: <lib>: cannot open`
`shared object file: No such file or directory` when trying to run Textadept.
How do I fix it?

**A:**
It is difficult to provide a binary that runs on all Linux platforms since the
library versions installed vary widely from distribution to distribution. For
example, "libpng14" was available for many distributions starting in late 2009
while Ubuntu 12.04 (circa 2012) used "libpng12". More recently, some
distributions have started using "libncurses6" while many distributions are
still on "libncurses5". Unfortunately in these cases, the best idea is to
[compile][] Textadept. This process is actually very simple though. Only the
GTK+ development libraries are needed for the GUI version. (A development
library for a curses implementation is required for the terminal version.)

[compile]: manual.html#Compiling

- - -

**Q:**
On Windows my anti-virus software says Textadept contains a virus. Does it? Or
is this a false-positive?

**A:**
Textadept does not contain any viruses and it certainly is a false positive.
The likely culprit is the `textadept-curses.exe` executable, which runs in the
Windows command prompt.

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
The LuaDoc describes [compile and run commands][] and you can configure them in
your [preferences][].

[compile and run commands]: api.html#_M.Compile.and.Run
[preferences]: manual.html#Preferences

- - -

**Q:**
In the curses version on Linux, pressing `^Z` suspends Textadept instead of
performing an "Undo" action. How can I disable suspend and perform "Undo"
instead?

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
I am not able to use the "Consolas" or [insert other Windows font package here]
on Windows. Textadept just uses a default font. How can I get it to use my font?

**A:**
You'll have to provide the full name of the font, such as "Consolas Regular",
rather than just the name of the "ttf" file in your Fonts directory.

- - -

**Q:**
When I use Mercurial >= 3.9 to clone Textadept's source code repository, I get
an "unsupported protocol" error related to TLS. How do I get around this?

**A:**
Set `hostsecurity.foicica.com:minimumprotocol=tls1.0` in your Mercurial
configuration, as stated by the error message. Then try cloning again.

- - -


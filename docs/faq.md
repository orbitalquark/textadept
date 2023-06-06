## FAQ

**Q:**
If Textadept is so minimalist, why are the downloads tens of MB in size and the unzipped
folders more than double that? Why is the Git repository more than 50MB in size?

**A:**
Each download contains 2 executables: a GUI version and a terminal version. Furthermore, the
Windows and macOS packages bundle in Qt runtimes, accounting for 60-90% of the total application
size. (Qt is the cross-platform GUI toolkit Textadept uses.)

The Git repository is an export of an underlying Mercurial repository and is not compressed or
optimized for size. After the initial clone, you can run `git gc --aggressive` to reduce its
footprint to about a third of the original size.

- - -

**Q:**
On Linux, Textadept will not run, or I get odd behavior in the terminal version, even crashes. How
do I fix this?

**A:**
Short answer: you will need to [compile][] Textadept manually for your system, which is a very
straightforward and easy process.

Long answer: it is difficult to provide a binary that runs on all Linux platforms since
the library versions installed vary widely from distribution to distribution. For example,
"libpng14" was available for many distributions starting in late 2009 while Ubuntu 12.04 (circa
2012) used "libpng12". More recently, some distributions have started using "libncurses6"
while many distributions are still on "libncurses5". Finally, C++ runtime libraries are not
always compatible between versions. The only way to avoid problems that stem from these cases
is to compile Textadept for the target system.

[compile]: manual.html#compiling

- - -

**Q:**
On Windows my anti-virus software says Textadept contains a virus. Does it? Or is this a
false-positive?

**A:**
Textadept does not contain any viruses and it certainly is a false positive. The likely culprit
is the `textadept-curses.exe` executable, which runs in the Windows command prompt.

- - -

**Q:**
Why can't Textadept handle HUGE files very well?

**A:**
Textadept is an editor for programmers. It is unlikely a programmer would be editing a gigantic
log file. There are other tools for that case.

- - -

**Q:**
When I open a file in a non-English or non-European language, I see a lot of strange characters.

**A:**
Textadept was not able to detect the file's encoding correctly. You'll need to [help it][].

On Windows, if you are seeing strange characters in the filename (including '?'), your file's
name contains characters outside the system's encoding, and due to Microsoft's C runtime library
limitations, Textadept cannot open files like those.

[help it]: manual.html#encoding

- - -

**Q:**
When I click the "Compile" or "Run" menu item (or execute the key command), either nothing shows up
in the command entry, or the wrong command shows up. How can I tell Textadept which command to run?

**A:**
The LuaDoc describes [compile and run commands][] and you can configure them in your
[preferences][]. Also, Textadept will remember any compile/run commands you manually enter for
the current session.

[compile and run commands]: api.html#textadept.run
[preferences]: manual.html#textadept

- - -

**Q:**
In Linux, middle-clicking in the terminal version does not paste the primary selection and
selecting text does copy to the primary selection. All other terminal apps support this
functionality, why not Textadept?

**A:**
It does; use the `Shift` modifier key with your middle-clicking and text selecting. Textadept
interprets non-`Shift`ed mouse events like a GUI application.

- - -

**Q:**
The terminal version does not support feature _x_ the GUI version does. Is this a bug?

**A:**
Maybe. Some terminals do not recognize certain key sequences like `Shift+Arrow` for making
selections. Linux's virtual terminals (the ones accessible with `Ctrl+Alt+FunctionKey`) are an
example. GNOME Terminal, LXTerminal and XTerm seem to work fine. rxvt and rxvt-unicode do not
work out of the box, but may be configurable.

Please see the [terminal version compatibility][] section of the appendix. If the feature
in question is not listed there, it may be a bug. Please contact me (see README.md) with any
bug reports.

[terminal version compatibility]: manual.html#terminal-version-compatibility

- - -

**Q:**
Pressing `^O` in the terminal version on macOS does not do anything. Why?

**A:**
For whatever reason, `^O` is discarded by the terminal driver. To enable it, run `stty discard
undef` first. You can put the command in your *~/.bashrc* or *~/.bash_profile* to make it
permanent.

- - -

**Q:**
How can I get the terminal version on macOS to show more than 8 colors?

**A:**
Enable the "Use bright colors for bold text" setting in your Terminal.app preferences.

- - -

**Q:**
Why does Textadept remember its window size but not its window position?

**A:**
Your window manager is to blame. Textadept is not responsible for, and should never attempt to
set its window position.

- - -

**Q:**
I am not able to use the "Consolas" or [insert other Windows font package here] on
Windows. Textadept just uses a default font. How can I get it to use my font?

**A:**
You'll have to provide the full name of the font, such as "Consolas Regular", rather than just
the name of the "ttf" file in your Fonts directory.

- - -

**Q:**
Where can I find a complete list of key bindings for Textadept?

**A:**
[Here](api.html#textadept.keys).


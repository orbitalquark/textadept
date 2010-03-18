# Introduction

## Purpose

This manual is not intended to be completely comprehensive.

## Textadept's Philosophy

Textadept is a text editor for programmers.

In a world where code bloat is commonplace and application speed is second to
its number of features, Textadept breaks that trend, aiming to stay minimalist
and fast, but at the same time being ridiculously extensible. At its core lies
less than 2000 lines of C code, and that's how it always will be. While other
editors rely on feature bloat, recordable macros to speed up workflow, and shell
scripts to quickly transform text. Textadept takes it to the extreme: it gives
you complete control over the entire application using the embedded [Lua][Lua]
language. Lua is nearly as fast as C, and has a very small footprint. In fact,
most of Textadept is written in Lua. Its incredibly fast startup time and
operation attest to Lua's worthiness.

Tired of all those features you never use in other editors? With Textadept you
can disable or remove anything you dislike or do not need. Wish you had an
additional feature? Chances are you can add it yourself.

Annoyed of recording complicated macros in other editors, only to find yourself
re-recording them over and over with little changes each time? You may be
surprised to find you can write the same commands in Lua, from moving the caret
to replacing text, performing searches, and much more!

Worried that your existing shell scripts for transforming text in other editors
will not be compatible with Lua or Textadept? No need to be. You can tell Lua to
run them in your shell.

These are just some of Textadept's strengths. Textadept is not about
constraining the user to a certain set of features while allowing minimal
custimization and/or extensibility. Textadept is about allowing that
customization and extensibility from the get-go; the features come after that.

[Lua]: http://lua.org

## Help

Textadept has a [mailing list][mailing_list] and a [wiki][wiki]. You can also
join us on IRC via [freenode.net][freenode] in `#textadept`.

[mailing_list]: http://groups.google.com/group/textadept
[wiki]: http://caladbolg.net/textadeptwiki
[freenode]: http://freenode.net

## Screenshots

<div style="float: left;">
Main window.<br />
<a href="http://caladbolg.net/images/textadept/window.png"><img src="http://caladbolg.net/images/textadept/window_t.png" alt="Main" /></a>
</div>
<div style="float: left; margin-left: 50px;">
Open Buffers.<br />
<a href="http://caladbolg.net/images/textadept/buffers.png"><img src="http://caladbolg.net/images/textadept/buffers_t.png" alt="Buffers" /></a>
</div>
<div style="margin-left: 400px;">
Lua Commands.<br />
<a href="http://caladbolg.net/images/textadept/command.png"><img src="http://caladbolg.net/images/textadept/command_t.png" alt="Command" /></a>
</div>
<div style="float: left;">
Project Manager.<br />
<a href="http://caladbolg.net/images/textadept/project.png"><img src="http://caladbolg.net/images/textadept/project_t.png" alt="PM" /></a>
</div>
<div style="margin-left: 200px;">
Extras.<br />
<a href="http://caladbolg.net/images/textadept/extra.png"><img src="http://caladbolg.net/images/textadept/extra_t.png" alt="Extras" /></a>
</div>
<div style="float: left;">
Windows OS.<br />
<a href="http://caladbolg.net/images/textadept/win32.png"><img src="http://caladbolg.net/images/textadept/win32_t.png" alt="Win32" /></a>
</div>
<div style="margin-left: 200px;">
Linux OS.<br />
<a href="http://caladbolg.net/images/textadept/linux.png"><img src="http://caladbolg.net/images/textadept/linux_t.png" alt="Linux" /></a>
</div>

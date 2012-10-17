# User Interface

![UI](images/ui.png)

Textadept's user interface was designed to be simple. It consists of a menu (GUI
version only), editor view, and statusbar. There is also a find & replace pane
and a command entry, both of which are initially hidden. Below are brief
descriptions of these features. More in-depth discussion about some of them is
provided later in the manual.

## Menu

The completely customizable menu provides access to all of Textadept's features.
It is only available in the GUI version of Textadept. In the terminal version,
you can use the [command selection][] dialog instead. Textadept is very
keyboard-driven so most menu items have an assigned key shortcut. Key bindings
are changeable in your [key preferences][] and will reflect in the menu. Here is
a [complete list][] of default key bindings.

[command selection]: 10_Advanced.html#Command.Selection
[key preferences]: 08_Preferences.html#Key.Bindings
[complete list]: api/_M.textadept.keys.html#Key.Bindings

## Editor View

The editor view is where you will spend most of your time in Textadept. In the
GUI version, you can split this view into as many other views as you would like.
Each view is completely controllable by Lua.

## Find & Replace Pane

This compact pane is a great way to slice and dice through your document or a
directory of files. You can even find and replace text using Lua patterns. It is
available only when you need it and quickly gets out of your way when you do
not, minimizing distractions.

## Command Entry

The versatile command entry functions as, among other things, a place to execute
Lua commands with Textadept's internal Lua state, find text incrementally, and
execute shell commands. You can extend it to do even more. Like the Find &
Replace pane, the command entry pops in and out as you wish.

## Statusbar

The statusbar is actually composed to two statusbars. The one on the left-hand
side displays temporary status messages. The one on the right-hand side
persistently shows the current buffer status.

# User Interface

Textadept's user interface was designed to be simple. It consists of an optional
menubar, left-hand side pane, editor view, and initially hidden dialogs for
find/replace and command entry. Below are brief descriptions of these features.
More in-depth discussion about each of them is provided later in the manual.

## Menubar

The completely customizable (and optional!) menubar typically provides access to
all of Textadept's features.

## Side Pane

From the beginning, the side pane has been called the Project Manager, or PM.
This is a deceptive name though, as it can hold any hierarchical, treeview-based
data structure, not just a list of files in a project. By default, Textadept can
show opened buffers, a filesystem, and a list of Lua modules. (These can be seen
in `core/ext/pm/`.) If you choose, you can resize and/or hide the PM.

## Editor View

The editor view is where you will spend most of your time in Textadept. It
supports unlimited split views and is completely controllable by Lua.

## Find/Replace Dialog

This compact dialog is a great way to slice and dice through your document or
directory of files. You can even find and replace text using Lua patterns. It is
available when you need it and quickly gets out of your way when you do not,
minimizing distractions.

## Command Entry

The versitile command entry functions as both a place to execute Lua commands
with the internal Lua state and find text incrementally. You can extend it to do
even more if you would like. Like the find/replace dialog, the command entry
pops in and out as you wish.

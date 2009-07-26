# Folder Structure

Because Textadept is mostly written in Lua, these Lua files have to be stored in
an organized folder structure.

## Core

Textadept's core Lua modules are contained in `core/`. These are absolutely
necessary in order for Textadept to run. They are responsible for Textadept's
Lua to C interface, event structure, file input/output, and localization.

## Core Extension

Core extension Lua modules are in `core/ext/`. These are optional and not
required, but are stored in `core/` because they could be considered "core
functionality". They are responsible for PM functionality and features like
find/replace and the handling of key commands, menus, and file types.

## Lexers

Lexer Lua modules are responsible for the syntax highlighting of source code.
They are located in `lexers/`.

## Modules

Editor Lua modules are contained in `modules/`. These provide advanced text
editing capabilities and can be available for all programming languages or
targeted at specific ones.

## Themes

Built-in themes to customize the look and behavior of Textadept are located in
`themes/`.

## User

User Lua modules are contained in a `.textadept` folder in your home directory.
In Linux and Mac OSX, your home directory is the location specified by the
`HOME` environment variable (typically `/home/username` and `/Users/username`
respectively). In Windows, it is the `USERPROFILE` environment variable. This
directory will be denoted as `~/.textadept` from now on in the manual.

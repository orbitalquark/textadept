#!/bin/bash
# Copyright 2022 Mitchell. See LICENSE.

# Counts lines of code for the each platform.
# Requires cloc.

files="core modules/ansi_c modules/lua modules/textadept src/textadept.c src/textadept.h \
  src/textadept_platform.h CMakeLists.txt init.lua"
opts="--not-match-f=tadoc.lua --exclude-lang=SVG --force-lang=C,h --quiet"

cd ..
echo -n === Gtk ===
cloc $files src/textadept_gtk.c $opts
echo -n === Curses ===
cloc $files src/textadept_curses.c $opts
echo -n === Qt ===
cloc $files src/textadept_qt.cpp src/textadept_qt.h $opts

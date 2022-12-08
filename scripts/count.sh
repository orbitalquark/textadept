#!/bin/bash
# Copyright 2022 Mitchell. See LICENSE.

# Counts lines of code for the given platform (default is Qt).
# Requires cloc.

if [[ "$1" = "gtk" ]]; then
  ta="src/textadept_gtk.c"
elif [[ "$1" = "curses" ]]; then
  ta="src/textadept_curses.c"
else
  ta="src/textadept_qt.cpp src/textadept_qt.h"
fi

cd ..
cloc core modules/ansi_c modules/lua modules/textadept src/textadept.c src/textadept.h \
  src/textadept_platform.h CMakeLists.txt init.lua $ta \
  --not-match-f=tadoc.lua --exclude-lang=SVG --force-lang=C,h

# Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

.SUFFIXES: .c .o .h .a

INCLUDEDIRS=-Iscintilla-st/include -Ilua
ifdef DEBUG
CXXFLAGS=-DDEBUG -g -DGTK -DSCI_LEXER -W -Wall
else
CXXFLAGS=-DNDEBUG -O -DGTK -DSCI_LEXER -W -Wall
endif
GTKFLAGS=$(shell pkg-config --cflags gtk+-2.0)
GTKLIBS=$(shell pkg-config --libs gtk+-2.0 gthread-2.0)
LUAOBJS=\
	lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o \
	lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o \
	lzio.o lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o loslib.o ltablib.o \
	lstrlib.o loadlib.o linit.o
EXPORTLUASYMS=-rdynamic -Wl,--retain-symbols-file -Wl,lua.sym

all: textadept

$(LUAOBJS): lua/*.c
	gcc $(INCLUDEDIRS) -DLUA_USE_LINUX $(CXXFLAGS) -c lua/*.c
.c.o:
	g++ $(GTKFLAGS) $(INCLUDEDIRS) $(CXXFLAGS) -c $< -o $@
textadept:\
  textadept.o lua_interface.o pm.o find_replace.o \
  scintilla-st/gtk/LexLPeg.o scintilla-st/bin/scintilla.a \
  $(LUAOBJS)
	g++ $(GTKLIBS) $(EXPORTLUASYMS) -DGTK $^ -o $@
clean:
	rm textadept *.o

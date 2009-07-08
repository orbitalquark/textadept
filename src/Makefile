# Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

.SUFFIXES: .c .o .h .a

INCLUDEDIRS=-Iscintilla-st/include -Ilua/include
ifdef DEBUG
CXXFLAGS=-DDEBUG -g -DGTK -DSCI_LEXER -W -Wall -Wno-sign-compare
else
CXXFLAGS=-DNDEBUG -O -DGTK -DSCI_LEXER -W -Wall -Wno-sign-compare
endif
GTKFLAGS=$(shell pkg-config --cflags gtk+-2.0)
GTKLIBS=$(shell pkg-config --libs gtk+-2.0 gthread-2.0)
EXPORTLUASYMS=-rdynamic -Wl,--retain-symbols-file -Wl,lua.sym

ifndef X86_64
ARCHDIR=lib32
else
ARCHDIR=x86_64
endif
GTKSO=../$(ARCHDIR)/core/gtk.so

LUA_OBJS = lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o \
  lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o \
  ltable.o ltm.o lundump.o lvm.o lzio.o \
  lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o ltablib.o \
  lstrlib.o loadlib.o loslib.o linit.o \
  lpeg.o lfs.o

all: textadept

.c.o:
	g++ $(GTKFLAGS) $(INCLUDEDIRS) $(CXXFLAGS) -c $< -o $@
$(LUA_OBJS): lua/src/*.c
	gcc $(INCLUDEDIRS) -DLUA_USE_LINUX $(CXXFLAGS) -c lua/src/*.c
textadept:\
  textadept.o lua_interface.o $(LUA_OBJS) \
  scintilla-st/gtk/LexLPeg.o scintilla-st/bin/scintilla.a
	g++ $(GTKLIBS) $(EXPORTLUASYMS) -DGTK $^ -o $@
	mv textadept ../
	cp $(GTKSO) ../core/
clean:
	rm ../textadept *.o

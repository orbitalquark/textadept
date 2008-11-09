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
EXPORTLUASYMS=-rdynamic -Wl,--retain-symbols-file -Wl,lua.sym

ifndef X86_64
ARCHDIR=lib32
else
ARCHDIR=x86_64
endif
LUA51A=../$(ARCHDIR)/src/liblua5.1.a
GTKSO=../$(ARCHDIR)/core/gtk.so
LPEGSO=../$(ARCHDIR)/lexers/lpeg.so

all: textadept

.c.o:
	g++ $(GTKFLAGS) $(INCLUDEDIRS) $(CXXFLAGS) -c $< -o $@
liblua5.1.a:
	cp $(LUA51A) .
textadept:\
  textadept.o lua_interface.o \
  scintilla-st/gtk/LexLPeg.o scintilla-st/bin/scintilla.a liblua5.1.a
	g++ $(GTKLIBS) $(EXPORTLUASYMS) -DGTK $^ -o $@
	cp $(GTKSO) ../core/
	cp $(LPEGSO) ../lexers/
clean:
	rm textadept *.o

# Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

.SUFFIXES: .c .o .h .a

INCLUDEDIRS=-Iscintilla-st/include
ifdef DEBUG
CXXFLAGS=-DDEBUG -g -DGTK -DSCI_LEXER -W -Wall
else
CXXFLAGS=-DNDEBUG -Os -DGTK -DSCI_LEXER -W -Wall
endif
LEXEROBJS=$(wildcard scintilla-st/gtk/Lex*.o)

all: textadept

.c.o:
	g++ `pkg-config --cflags gtk+-2.0` $(INCLUDEDIRS) $(CXXFLAGS) -c $< -o $@
textadept: textadept.o lua_interface.o pm.o find_replace.o $(LEXEROBJS) scintilla-st/bin/scintilla.a -llua
	g++ `pkg-config --libs gtk+-2.0 gthread-2.0` -lstdc++ -DGTK $^ -o $@
clean:
	rm -rf textadept *.o

# Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

.SUFFIXES: .c .o .h .a .cxx

ifndef WIN32
CC = gcc
CPP = g++
PKG_CONFIG = pkg-config
PKG_CONFIG_PATH = $PKG_CONFIG_PATH
PLAT_FLAGS = -DGTK
SCI_THREAD_FLAG =
LUA_CFLAGS = -DLUA_USE_LINUX
TEXTADEPT = textadept
TEXTADEPT_RC =
else
CC = i486-mingw32-gcc -mms-bitfields
CPP = i486-mingw32-g++ -mms-bitfields -mwindows
PKG_CONFIG = pkg-config --define-variable=prefix=win32gtk
PKG_CONFIG_PATH = $(shell pwd)/win32gtk/lib/pkgconfig
PLAT_FLAGS = -DGTK -D__WIN32__
SCI_THREAD_FLAG = -DG_THREADS_IMPL_NONE
LUA_CFLAGS = -D_WIN32 -DWIN32
TEXTADEPT = textadept.exe
TEXTADEPT_RC = textadept_rc.o
WINDRES = i486-mingw32-windres
endif

ifndef DEBUG
DEBUG_FLAG = -DNDEBUG
else
DEBUG_FLAG = -DDEBUG -g
endif
INCLUDEDIRS = -Iscintilla-st/include -Ilua/include -Igcocoadialog

# Textadept

CFLAGS = -std=c99 $(DEBUG_FLAG) -O $(PLAT_FLAGS) $(INCLUDEDIRS) -W -Wall \
  -Wno-sign-compare -Wno-unused
GTKFLAGS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --cflags gtk+-2.0)
GTKLIBS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --libs gtk+-2.0 gthread-2.0)
EXPORTLUASYMS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym

TEXTADEPT_OBJS = textadept.o lua_interface.o
LUA_OBJS = lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o \
  lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o \
  lvm.o lzio.o \
  lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o ltablib.o lstrlib.o \
  loadlib.o loslib.o linit.o \
  lpeg.o lfs.o
GCOCOADIALOG = gcocoadialog.o

# Scintilla

SCI_CXXFLAGS = $(DEBUG_FLAG) -pedantic -Os $(PLAT_FLAGS) -DSCI_LEXER \
  $(SCI_THREAD_FLAG) $(INCLUDEDIRS) -Iscintilla-st/src -Iscintilla-st/gtk \
  -Wall -Wno-missing-braces -Wno-char-subscripts

SCINTILLA_OBJS = AutoComplete.o CallTip.o CellBuffer.o CharClassify.o \
  ContractionState.o Decoration.o Document.o DocumentAccessor.o Editor.o \
  ExternalLexer.o Indicator.o KeyMap.o KeyWords.o LexLPeg.o LineMarker.o \
  PerLine.o PositionCache.o PropSet.o RESearch.o RunStyles.o ScintillaBase.o \
  Style.o StyleContext.o UniConversion.o ViewStyle.o WindowAccessor.o XPM.o \
  PlatGTK.o ScintillaGTK.o
SCINTILLA_MARSHALLER = scintilla-marshal.o

# Build

all: $(TEXTADEPT)

$(SCINTILLA_OBJS): scintilla-st/gtk/*.cxx scintilla-st/src/*.cxx
	$(CPP) $(SCI_CXXFLAGS) $(GTKFLAGS) -c $^
$(SCINTILLA_MARSHALLER): scintilla-st/gtk/scintilla-marshal.c
	$(CC) $(SCI_CXXFLAGS) $(GTKFLAGS) -w -c $^
$(TEXTADEPT_OBJS): *.c
	$(CC) $(CFLAGS) $(GTKFLAGS) -c $^
$(LUA_OBJS): lua/src/*.c
	$(CC) $(LUA_CFLAGS) $(INCLUDEDIRS) -c $^
$(GCOCOADIALOG): gcocoadialog/gcocoadialog.c
	$(CC) $(GTKFLAGS) $(INCLUDEDIRS) -c $^
$(TEXTADEPT):\
  $(SCINTILLA_OBJS) $(SCINTILLA_MARSHALLER) \
  $(TEXTADEPT_OBJS) $(LUA_OBJS) $(GCOCOADIALOG) \
  $(TEXTADEPT_RC)
	$(CPP) $(EXPORTLUASYMS) -o $@ $^ $(GTKLIBS)
	mv $(TEXTADEPT) ../
$(TEXTADEPT_RC): textadept.rc
	$(WINDRES) $^ $@
clean:
	rm ../$(TEXTADEPT) *.o

# Package (Note: pass 'VERSION=[release version]' to 'make')

ifndef WIN32
ZIP = tar czf
PACKAGE = textadept_$(value VERSION).tgz
UNZIP = tar xzf
else
ZIP = zip -r
PACKAGE = textadept_$(value VERSION).win32.zip
UNZIP = unzip
endif
SRCPACKAGE = textadept.src.zip

RELEASEDIR = textadept_$(value VERSION)
release: ../$(TEXTADEPT)
	hg archive $(RELEASEDIR)
	rm $(RELEASEDIR)/.hg*
	sh -c 'cd ../ && ./update_doc'
	cp -r ../doc $(RELEASEDIR)
	svn export http://scite-tools.googlecode.com/svn/branches/scite-st/lexers \
	  $(RELEASEDIR)/lexers
	cp ../$(TEXTADEPT) $(RELEASEDIR)
	$(ZIP) $(PACKAGE) $(RELEASEDIR)
	rm -r $(RELEASEDIR)
source: $(PACKAGE)
	$(UNZIP) $(PACKAGE)
	cp -r lua scintilla-st gcocoadialog $(RELEASEDIR)/src/
	rm $(RELEASEDIR)/$(TEXTADEPT)
	zip -r $(SRCPACKAGE) $(RELEASEDIR)
	rm -r $(RELEASEDIR)

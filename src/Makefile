# Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

.SUFFIXES: .c .o .h .a .cxx

ifndef WIN32
CC = gcc
CPP = g++
PKG_CONFIG = pkg-config
PKG_CONFIG_PATH = $PKG_CONFIG_PATH
ifndef BSD
PLAT_FLAGS = -DGTK
else
PLAT_FLAGS = -DGTK -D__BSD__
endif
SCI_THREAD_FLAG =
LUA_CFLAGS = -DLUA_USE_LINUX
TEXTADEPT = textadept
TEXTADEPT_RC =
EXPORTLUASYMS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym
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
EXPORTLUASYMS = -Wl,--retain-symbols-file -Wl,lua.sym
WINDRES = i486-mingw32-windres
endif

ifndef DEBUG
DEBUG_FLAG = -DNDEBUG
else
DEBUG_FLAG = -DDEBUG -DTRACE -g
endif
INCLUDEDIRS = -Iscintilla/include -Ilua/include -Igcocoadialog

# Textadept

CFLAGS = -std=c99 $(DEBUG_FLAG) -O $(PLAT_FLAGS) $(INCLUDEDIRS) -W -Wall \
  -Wno-sign-compare -Wno-unused
GTKFLAGS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --cflags gtk+-2.0)
GTKLIBS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --libs gtk+-2.0 gthread-2.0)

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
  $(SCI_THREAD_FLAG) $(INCLUDEDIRS) -Iscintilla/src -Iscintilla/gtk \
  -Iscintilla/lexlib \
  -Wall -Wno-missing-braces -Wno-char-subscripts -Wno-long-long

SCINTILLA_OBJS = AutoComplete.o CallTip.o Catalogue.o CellBuffer.o \
  CharClassify.o ContractionState.o Decoration.o Document.o Editor.o \
  ExternalLexer.o Indicator.o KeyMap.o LineMarker.o  PerLine.o \
  PositionCache.o RESearch.o RunStyles.o ScintillaBase.o Selection.o \
  Style.o UniConversion.o ViewStyle.o XPM.o \
  Accessor.o CharacterSet.o LexerBase.o LexerModule.o LexerNoExceptions.o \
  LexerSimple.o PropSetSimple.o StyleContext.o WordList.o \
  PlatGTK.o ScintillaGTK.o
SCINTILLA_MARSHALLER = scintilla-marshal.o
SCINTILLA_LEXER = LexLPeg.o

# Build

all: $(TEXTADEPT)

$(SCINTILLA_OBJS): scintilla/gtk/*.cxx scintilla/src/*.cxx \
  scintilla/lexlib/*.cxx
	$(CPP) $(SCI_CXXFLAGS) $(GTKFLAGS) -c $^
$(SCINTILLA_MARSHALLER): scintilla/gtk/scintilla-marshal.c
	$(CC) $(SCI_CXXFLAGS) $(GTKFLAGS) -w -c $^
$(SCINTILLA_LEXER): LexLPeg.cxx
	$(CPP) $(SCI_CXXFLAGS) $(GTKFLAGS) $(LUA_CFLAGS) -DLPEG_LEXER -DNO_SCITE -c $^
$(TEXTADEPT_OBJS): *.c
	$(CC) $(CFLAGS) $(GTKFLAGS) -c $^
$(LUA_OBJS): lua/src/*.c
	$(CC) $(LUA_CFLAGS) $(INCLUDEDIRS) -c $^
$(GCOCOADIALOG): gcocoadialog/gcocoadialog.c
	$(CC) $(GTKFLAGS) $(INCLUDEDIRS) -c $^
$(TEXTADEPT):\
  $(SCINTILLA_OBJS) $(SCINTILLA_MARSHALLER) $(SCINTILLA_LEXER) \
  $(TEXTADEPT_OBJS) $(LUA_OBJS) $(GCOCOADIALOG) \
  $(TEXTADEPT_RC)
	$(CPP) $(EXPORTLUASYMS) -o $@ $^ $(GTKLIBS)
	mv $(TEXTADEPT) ../
$(TEXTADEPT_RC): textadept.rc
	$(WINDRES) $^ $@
clean:
	rm ../$(TEXTADEPT) *.o

# Package (only for Linux x86_64)
# Pass 'VERSION=[release version]' to 'make'.

TEXTADEPT32 = $(TEXTADEPT)32
TEXTADEPT64 = $(TEXTADEPT)
TEXTADEPTWIN32 = $(TEXTADEPT).exe
TEXTADEPTMAC = $(TEXTADEPT).osx
RELEASEDIR32 = textadept_$(value VERSION)
RELEASEDIR64 = $(RELEASEDIR32).x86_64
RELEASEDIRWIN32 = $(RELEASEDIR32).win32
RELEASEDIRMAC = $(RELEASEDIR32).osx
TEXTADEPTAPP = $(RELEASEDIRMAC)/$(TEXTADEPT).app
PACKAGE32 = ../releases/$(RELEASEDIR32).tgz
PACKAGE64 = ../releases/$(RELEASEDIR64).tgz
PACKAGEWIN32 = ../releases/$(RELEASEDIRWIN32).zip
PACKAGEMAC = ../releases/$(RELEASEDIRMAC).zip
SRCPACKAGE = ../releases/$(RELEASEDIR32).src.zip

release: ../$(TEXTADEPT) ../$(TEXTADEPT32) ../$(TEXTADEPTWIN32) \
  ../$(TEXTADEPTMAC)
	sh -c 'cd ../scripts && ./update_doc'
	hg archive $(RELEASEDIR32)
	rm $(RELEASEDIR32)/.hg*
	cp -r ../doc $(RELEASEDIR32)
	hg clone http://scintillua.googlecode.com/hg/ tmp
	mv tmp/lexers $(RELEASEDIR32)
	rm -r tmp
	# Linux x64_64
	cp -r $(RELEASEDIR32) $(RELEASEDIR64)
	cp ../$(TEXTADEPT64) $(RELEASEDIR64)
	tar czf $(PACKAGE64) $(RELEASEDIR64)
	rm -r $(RELEASEDIR64)
	# Win32
	cp -r $(RELEASEDIR32) $(RELEASEDIRWIN32)
	cp ../$(TEXTADEPTWIN32) $(RELEASEDIRWIN32)
	zip -r $(PACKAGEWIN32) $(RELEASEDIRWIN32)
	rm -r $(RELEASEDIRWIN32)
	# Linux 32-bit
	cp ../$(TEXTADEPT32) $(RELEASEDIR32)/$(TEXTADEPT)
	tar czf $(PACKAGE32) $(RELEASEDIR32)
	# Mac OSX
	mkdir $(RELEASEDIRMAC)
	mkdir -p $(TEXTADEPTAPP)/Contents/{MacOS,Resources}
	cp ../xcode/{Info.plist,PkgInfo} $(TEXTADEPTAPP)/Contents
	cp -r ../xcode/English.lproj $(TEXTADEPTAPP)/Contents/Resources
	cp -r $(RELEASEDIR32)/* $(TEXTADEPTAPP)/Contents/Resources
	mv $(TEXTADEPTAPP)/Contents/Resources/core/images/textadept.icns \
		$(TEXTADEPTAPP)/Contents/Resources/
	cp ../$(TEXTADEPTMAC) $(TEXTADEPTAPP)/Contents/MacOS/$(TEXTADEPT)
	cp ../xcode/README.txt $(RELEASEDIRMAC)
	zip -r $(PACKAGEMAC) $(RELEASEDIRMAC)
	rm -r $(RELEASEDIRMAC)
	# Source
	rm $(RELEASEDIR32)/$(TEXTADEPT)
	cp -rL lua scintilla gcocoadialog LexLPeg.cxx $(RELEASEDIR32)/src/
	rm -r $(RELEASEDIR32)/src/scintilla/.hg
	cp -r ../xcode $(RELEASEDIR32)/
	zip -r $(SRCPACKAGE) $(RELEASEDIR32)
	# Done
	rm -r $(RELEASEDIR32)

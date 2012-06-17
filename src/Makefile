# Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

.SUFFIXES: .c .o .h .a .cxx

# Linux (default)
CC = gcc
CPP = g++
PKG_CONFIG = pkg-config
PKG_CONFIG_PATH = $PKG_CONFIG_PATH
ifndef NCURSES
PLAT_FLAGS = -DGTK -D_XOPEN_SOURCE=700
else
PLAT_FLAGS = -DNCURSES -D_XOPEN_SOURCE=700
endif
ifdef BSD
PLAT_FLAGS += -D__BSD__
endif
SCI_THREAD_FLAG =
LUAFLAGS = -DLUA_USE_LINUX
TEXTADEPT = textadept
TEXTADEPTJIT = textadeptjit
TEXTADEPT_RC =
EXPORTLUASYMS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym
WINDRES =
LDL = -ldl
LUAJIT_LIB = libluajit.a
LUAJIT_MAKE =
LUADOC = luadoc

# Win32 (WIN32=1)
ifdef WIN32
CC = i486-mingw32-gcc -mms-bitfields
CPP = i486-mingw32-g++ -mms-bitfields -mwindows -static-libgcc -static-libstdc++
PKG_CONFIG = pkg-config --define-variable=prefix=win32gtk
PKG_CONFIG_PATH = $(shell pwd)/win32gtk/lib/pkgconfig
PLAT_FLAGS += -D__WIN32__
SCI_THREAD_FLAG = -DG_THREADS_IMPL_NONE
LUAFLAGS = -D_WIN32 -DWIN32
TEXTADEPT = textadept.exe
TEXTADEPTJIT = textadeptjit.exe
TEXTADEPT_RC = textadept_rc.o
EXPORTLUASYMS = -Wl,--retain-symbols-file -Wl,lua.sym
WINDRES = i486-mingw32-windres
LDL =
LUAJIT_LIB = lua51.dll
LUAJIT_MAKE = HOST_CC="gcc -m32" CROSS=i486-mingw32- TARGET_SYS=Windows
LUADOC = luadoc_start.bat
endif

# Mac OSX (OSX=1)
ifdef OSX
CC = gcc -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
  -isysroot /Developer/SDKs/MacOSX10.5.sdk
CPP = g++ -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
  -isysroot /Developer/SDKs/MacOSX10.5.sdk
PKG_CONFIG = gtkosx/bin/pkg-config --define-variable=prefix=gtkosx
PKG_CONFIG_PATH = $(shell pwd)/gtkosx/lib/pkgconfig
PLAT_FLAGS += -D__OSX__
SCI_THREAD_FLAG =
LUAFLAGS = -DLUA_USE_MACOSX
TEXTADEPT = textadept.osx
TEXTADEPTJIT = textadeptjit.osx
TEXTADEPT_RC =
EXPORTLUASYMS = -rdynamic
WINDRES =
LDL =
LUAJIT_LIB = libluajit.a
LUAJIT_MAKE =
LUADOC = luadoc
endif

# No debugging unless DEBUG=1.
ifndef DEBUG
DEBUG_FLAG = -DNDEBUG
else
DEBUG_FLAG = -DDEBUG -DTRACE -g
endif

# Do not compile with LuaJIT unless LUAJIT=1.
ifndef LUAJIT
LUADIR = lua
LUAJIT_FLAG =
LUAJIT_LIB =
else
LUADIR = luajit
LUAJIT_FLAG = -DLUAJIT
endif

# Single instance unless NO_SINGLE_INSTANCE=1
ifndef NO_SINGLE_INSTANCE
SI_FLAG = -DSINGLE_INSTANCE
else
SI_FLAG =
endif

INCLUDEDIRS = -Iscintilla/include -I$(LUADIR)/src -Igtdialog
ifdef NCURSES
INCLUDEDIRS += -Iscintilla/term -Itermkey
endif

ifdef GTK3
GTKVERSION = gtk+-3.0
else
GTKVERSION = gtk+-2.0
endif

# Textadept

CFLAGS = -std=c99 $(DEBUG_FLAG) $(LUAJIT_FLAG) $(SI_FLAG) -O $(PLAT_FLAGS) \
  $(INCLUDEDIRS) -W -Wall -Wno-sign-compare -Wno-unused
GTKFLAGS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --cflags $(GTKVERSION))
ifndef NCURSES
CFLAGS += $(GTKFLAGS)
endif
GTKLIBS = $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) \
  --libs $(GTKVERSION))
ifdef LIBPNG12
GTKLIBS := $(shell sed -e 's/lpng14/lpng12/;' <<< "$(GTKLIBS)")
endif
ifdef OSX
GTKLIBS += -framework Cocoa -lgtkmacintegration
endif
GTDFLAGS = $(PLAT_FLAGS) -DNOHELP -DLIBRARY
ifndef NCURSES
GTDFLAGS += $(GTKFLAGS)
endif
ifndef NCURSES
LIBS = $(GTKLIBS)
else
LIBS = -lncurses -lcdk
endif

TEXTADEPT_OBJS = textadept.o
LUA_OBJS = lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o \
  linit.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o \
  ltable.o ltm.o lundump.o lvm.o lzio.o \
  lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o lmathlib.o \
  loadlib.o loslib.o ltablib.o lstrlib.o \
  lpeg.o lfs.o
LUA_SRCS = lua/src/*.c lua/src/lib/*.c
LUAJIT_OBJS =
GTDIALOG = gtdialog.o
ifdef NCURSES
TERMKEY_OBJS = termkey.o driver-ti.o driver-csi.o
endif

# Scintilla

SCIFLAGS = $(DEBUG_FLAG) -pedantic -Os $(PLAT_FLAGS) -DSCI_LEXER \
  $(SCI_THREAD_FLAG) $(INCLUDEDIRS) -Iscintilla/src -Iscintilla/lexlib \
  -Wall -Wno-missing-braces -Wno-char-subscripts -Wno-long-long
ifndef NCURSES
SCIFLAGS += -Iscintilla/gtk
endif

SCINTILLA_OBJS = AutoComplete.o CallTip.o Catalogue.o CellBuffer.o \
  CharClassify.o ContractionState.o Decoration.o Document.o Editor.o \
  ExternalLexer.o Indicator.o KeyMap.o LineMarker.o  PerLine.o \
  PositionCache.o RESearch.o RunStyles.o ScintillaBase.o Selection.o \
  Style.o UniConversion.o ViewStyle.o XPM.o \
  Accessor.o CharacterSet.o LexerBase.o LexerModule.o LexerNoExceptions.o \
  LexerSimple.o PropSetSimple.o StyleContext.o WordList.o
ifndef NCURSES
SCINTILLA_GTK_OBJS = PlatGTK.o ScintillaGTK.o
SCINTILLA_MARSHALLER = scintilla-marshal.o
SCINTILLA_PLAT_OBJS = $(SCINTILLA_GTK_OBJS) $(SCINTILLA_MARSHALLER)
else
SCINTILLA_TERM_OBJS = ScintillaTerm.o
SCINTILLA_PLAT_OBJS = $(SCINTILLA_TERM_OBJS)
endif
SCINTILLA_LEXER = LexLPeg.o

# Build

ifdef LUAJIT
TEXTADEPT_OBJS = textadeptjit.o
LUA_OBJS = lpegjit.o lfsjit.o
LUA_SRCS = lua/src/lib/*.c
LUAJIT_OBJS = $(LUAJIT_LIB)
SCINTILLA_LEXER = LexLPegjit.o
TEXTADEPT = $(TEXTADEPTJIT)
endif

all: $(TEXTADEPT)

$(SCINTILLA_OBJS): scintilla/src/*.cxx scintilla/lexlib/*.cxx
	$(CPP) $(SCIFLAGS) -c $^
$(SCINTILLA_GTK_OBJS): scintilla/gtk/*.cxx
	$(CPP) $(SCIFLAGS) $(GTKFLAGS) -c $^
$(SCINTILLA_TERM_OBJS): scintilla/term/*.cxx
	$(CPP) $(SCIFLAGS) -c $^
$(SCINTILLA_MARSHALLER): scintilla/gtk/scintilla-marshal.c
	$(CC) $(SCIFLAGS) $(GTKFLAGS) -w -c $<
$(SCINTILLA_LEXER): LexLPeg.cxx
	$(CPP) $(SCIFLAGS) $(LUAFLAGS) -DLPEG_LEXER -DNO_SCITE -c $< -o $@
$(TEXTADEPT_OBJS): textadept.c
	$(CC) $(CFLAGS) -c $< -o $@
$(LUA_OBJS): $(LUA_SRCS)
	$(CC) $(LUAFLAGS) $(INCLUDEDIRS) -c $^
ifdef LUAJIT
	for lib in $(LUA_OBJS); do mv $$(echo $$lib | sed 's/jit//g') $$lib; done
endif
$(LUAJIT_OBJS):
	cd luajit && make $(LUAJIT_MAKE)
	cp luajit/src/$(LUAJIT_LIB) .
$(GTDIALOG): gtdialog/gtdialog.c
	$(CC) $(GTDFLAGS) $(INCLUDEDIRS) -c $<
$(TERMKEY_OBJS): termkey/*.c
	$(CC) -std=c99 -c $^
$(TEXTADEPT):\
  $(SCINTILLA_OBJS) $(SCINTILLA_PLAT_OBJS) $(SCINTILLA_LEXER) \
  $(TEXTADEPT_OBJS) $(LUA_OBJS) $(LUAJIT_OBJS) $(GTDIALOG) \
  $(TERMKEY_OBJS) $(TEXTADEPT_RC)
	$(CPP) $(EXPORTLUASYMS) -o $@ $^ $(LIBS) $(LDL)
	mv $(TEXTADEPT) ../
$(TEXTADEPT_RC): textadept.rc
	$(WINDRES) $^ $@
clean:
	rm -f ../$(TEXTADEPT) *.o *.a *.dll
	cd luajit && make clean

doc: manual luadoc adeptsense doxygen
manual: ../doc/*.md ../*.md
	../doc/bombay -d ../doc -t ../doc --title Textadept --navtitle Manual $^
luadoc: ../modules ../core ../lexers/lexer.lua
	cd ../doc && $(LUADOC) -d . -t . --doclet markdowndoc $^
adeptsense: ../modules ../core ../lexers/lexer.lua
	cd ../modules && $(LUADOC) -d lua --doclet lua/adeptsensedoc $^
doxygen: ../Doxyfile
	doxygen $<
cleandoc:
	rm -f ../doc/*.html
	rm -rf ../doc/api ../doc/doxygen

# Package (only for Linux x86_64)
# Pass 'VERSION=[release version]' to 'make'.

TEXTADEPT32 = $(TEXTADEPT)32
TEXTADEPTJIT32 = $(TEXTADEPT)jit32
TEXTADEPT64 = $(TEXTADEPT)
TEXTADEPTJIT64 = $(TEXTADEPT)jit
TEXTADEPT64LPNG12 = $(TEXTADEPT).lpng12
TEXTADEPTJIT64LPNG12 = $(TEXTADEPT)jit.lpng12
TEXTADEPTWIN32 = $(TEXTADEPT).exe
TEXTADEPTJITWIN32 = $(TEXTADEPT)jit.exe
TEXTADEPTMAC = $(TEXTADEPT).osx
TEXTADEPTJITMAC = $(TEXTADEPT)jit.osx
RELEASEDIR32 = textadept_$(value VERSION)
RELEASEDIR64 = $(RELEASEDIR32).x86_64
RELEASEDIRWIN32 = $(RELEASEDIR32).win32
RELEASEDIRMAC = $(RELEASEDIR32).osx
TEXTADEPTAPP = $(RELEASEDIRMAC)/Textadept.app
PACKAGE32 = ../releases/$(RELEASEDIR32).tgz
PACKAGE64 = ../releases/$(RELEASEDIR64).tgz
PACKAGEWIN32 = ../releases/$(RELEASEDIRWIN32).zip
PACKAGEMAC = ../releases/$(RELEASEDIRMAC).zip
SRCPACKAGE = ../releases/$(RELEASEDIR32).src.zip
MODULES = css hypertext java rails rhtml ruby php
MODULESDIR = $(RELEASEDIR32)/modules
MODULESPKG = ../releases/$(RELEASEDIR32).modules.zip

release: ../$(TEXTADEPT) ../$(TEXTADEPT32) ../$(TEXTADEPTWIN32) \
  ../$(TEXTADEPTMAC) ../$(TEXTADEPTLPNG12) doc
	hg archive $(RELEASEDIR32)
	rm $(RELEASEDIR32)/.hg*
	cp -rL ../doc $(RELEASEDIR32)
	hg clone http://foicica.com/hg/scintillua tmp
	mv tmp/lexers $(RELEASEDIR32)
	rm -r tmp
	# Linux x64_64
	cp -r $(RELEASEDIR32) $(RELEASEDIR64)
	cp ../$(TEXTADEPT64) $(RELEASEDIR64)
	if [ -f ../$(TEXTADEPTJIT64) ]; then \
		cp ../$(TEXTADEPTJIT64) $(RELEASEDIR64); \
	fi
	cp ../$(TEXTADEPT64LPNG12) $(RELEASEDIR64)
	if [ -f ../$(TEXTADEPTJIT64LPNG12) ]; then \
		cp ../$(TEXTADEPTJIT64LPNG12) $(RELEASEDIR64); \
	fi
	tar czf $(PACKAGE64) $(RELEASEDIR64)
	rm -r $(RELEASEDIR64)
	# Win32
	cp -r $(RELEASEDIR32) $(RELEASEDIRWIN32)
	cp ../$(TEXTADEPTWIN32) $(RELEASEDIRWIN32)
	if [ -f ../$(TEXTADEPTJITWIN32) ]; then \
		cp ../$(TEXTADEPTJITWIN32) lua51.dll $(RELEASEDIRWIN32); \
	fi
	cp win32gtk/bin/*.dll $(RELEASEDIRWIN32)
	cp -r win32gtk/{etc,lib,share} $(RELEASEDIRWIN32)
	rm -r $(RELEASEDIRWIN32)/lib/{*.a,glib-2.0,gtk-2.0/include,pkgconfig}
	zip -r $(PACKAGEWIN32) $(RELEASEDIRWIN32)
	rm -r $(RELEASEDIRWIN32)
	# Linux 32-bit
	cp ../$(TEXTADEPT32) $(RELEASEDIR32)/$(TEXTADEPT)
	if [ -f ../$(TEXTADEPTJIT32) ]; then \
		cp ../$(TEXTADEPTJIT32) $(RELEASEDIR32)/$(TEXTADEPTJIT); \
	fi
	tar czf $(PACKAGE32) $(RELEASEDIR32)
	# Mac OSX
	mkdir $(RELEASEDIRMAC)
	cp -rL gtkosx $(TEXTADEPTAPP)
	mv $(TEXTADEPTAPP)/Contents/MacOS/ta $(RELEASEDIRMAC)
	cp -r $(RELEASEDIR32)/* $(TEXTADEPTAPP)/Contents/Resources/
	rm -f $(TEXTADEPTAPP)/Contents/Resources/{$(TEXTADEPT),$(TEXTADEPTJIT)}
	mv $(TEXTADEPTAPP)/Contents/Resources/core/images/textadept.icns \
		$(TEXTADEPTAPP)/Contents/Resources/
	cp ../$(TEXTADEPTMAC) $(TEXTADEPTAPP)/Contents/MacOS/
	if [ -f ../$(TEXTADEPTJITMAC) ]; then \
		cp ../$(TEXTADEPTJITMAC) $(TEXTADEPTAPP)/Contents/MacOS/; \
	fi
	zip -r $(PACKAGEMAC) $(RELEASEDIRMAC)
	rm -r $(RELEASEDIRMAC)
	# Source
	rm $(RELEASEDIR32)/{$(TEXTADEPT),$(TEXTADEPTJIT)}
	cp -rL lua luajit scintilla gtdialog LexLPeg.cxx $(RELEASEDIR32)/src/
	cd $(RELEASEDIR32)/src/luajit && make clean && cd ../../../
	rm -r $(RELEASEDIR32)/src/scintilla/.hg
	zip -r $(SRCPACKAGE) $(RELEASEDIR32)
	rm -r $(RELEASEDIR32)
	# Modules
	mkdir -p $(MODULESDIR)
	for module in $(MODULES); do \
		hg clone /home/mitchell/code/textadept/modules/$$module \
		$(MODULESDIR)/$$module; \
	done
	zip -r $(MODULESPKG) $(MODULESDIR)
	rm -r $(MODULESDIR)
	# Done
	rm -r $(RELEASEDIR32)

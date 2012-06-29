# Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

ifeq (Linux, $(shell uname -s))
  ifneq (win32, $(MAKECMDGOALS))
    CC = gcc
    CXX = g++
    LUAFLAGS = -DLUA_USE_LINUX
    LDFLAGS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym -ldl

    ifneq (ncurses, $(MAKECMDGOALS))
      plat_flag = -DGTK
      ifndef GTK3
        gtk_version = 2.0
      else
        gtk_version = 3.0
      endif
      gtk_flags = $(shell pkg-config --cflags gtk+-$(gtk_version))
      gtk_libs = $(shell pkg-config --libs gtk+-$(gtk_version))
    else
      plat_flag = -DNCURSES
    endif

    luadoc = luadoc
  else # (make win32)
    CROSS = i586-mingw32msvc-
    CC = gcc
    CFLAGS = -mms-bitfields
    CXX = g++
    CXXFLAGS = -mms-bitfields -mwindows -static-libgcc -static-libstdc++
    LDFLAGS = -liconv -Wl,--retain-symbols-file -Wl,lua.sym
    WINDRES = windres

    plat_flag = -DGTK
    gtk_flags = $(shell PKG_CONFIG_PATH=`pwd`/win32gtk/lib/pkgconfig \
                        pkg-config --define-variable=prefix=win32gtk \
                        --cflags gtk+-2.0)
    gtk_libs = $(shell PKG_CONFIG_PATH=`pwd`/win32gtk/lib/pkgconfig \
                       pkg-config --define-variable=prefix=win32gtk \
                       --libs gtk+-2.0)

    luadoc = luadoc_start.bat
  endif
else ifeq (Darwin, $(shell uname -s))
  CC = gcc
  CFLAGS = -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
           -isysroot /Developer/SDKs/MacOSX10.5.sdk
  CXX = g++
  CXXFLAGS = -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
             -isysroot /Developer/SDKs/MacOSX10.5.sdk
  LUAFLAGS = -DLUA_USE_MACOSX
  LDFLAGS = -liconv -rdynamic

  #ifneq (ncurses, $(MAKECMDGOALS))
    plat_flag = -DGTK
    gtk_flags = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                        gtkosx/bin/pkg-config --define-variable=prefix=gtkosx \
                        --cflags gtk+-2.0)
    gtk_libs = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                       gtkosx/bin/pkg-config --define-variable=prefix=gtkosx \
                       --libs gtk+-2.0) -framework Cocoa -lgtkmacintegration
    .DEFAULT_GOAL := osx
  #else
  #  plat_flag = -DNCURSES
  #  .DEFAULT_GOAL := osx-ncurses
  #endif

  luadoc = luadoc
endif

# No debugging unless DEBUG=1.
ifdef DEBUG
  CFLAGS += -g
  CXXFLAGS += -g
endif

# Scintilla.

sci_flags = -pedantic -Os $(plat_flag) -DSCI_LEXER -DNDEBUG \
            -DG_THREADS_IMPL_NONE -Iscintilla/include -Iscintilla/src \
            -Iscintilla/lexlib -Wall -Wno-missing-braces -Wno-char-subscripts \
            -Wno-long-long

scintilla_objs = AutoComplete.o CallTip.o Catalogue.o CellBuffer.o \
                 CharClassify.o ContractionState.o Decoration.o Document.o \
                 Editor.o ExternalLexer.o Indicator.o KeyMap.o LineMarker.o \
                 PerLine.o PositionCache.o RESearch.o RunStyles.o \
                 ScintillaBase.o Selection.o Style.o UniConversion.o \
                 ViewStyle.o XPM.o \
                 Accessor.o CharacterSet.o LexerBase.o LexerModule.o \
                 LexerNoExceptions.o LexerSimple.o PropSetSimple.o \
                 StyleContext.o WordList.o
scintilla_gtk_objs = PlatGTK.o ScintillaGTK.o

# Textadept.

ta_flags = -std=c99 -O -D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE \
           $(plat_flag) -Iscintilla/include -Igtdialog -W -Wall \
           -Wno-sign-compare -Wno-unused
ifndef NO_SINGLE_INSTANCE
  # Single instance unless NO_SINGLE_INSTANCE=1
  ta_flags += -DSINGLE_INSTANCE
endif

lua_objs = lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o \
           linit.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o \
           lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o \
           lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o \
           lmathlib.o loadlib.o loslib.o ltablib.o lstrlib.o \
           lpeg.o lfs.o
luajit_objs = lpegjit.o lfsjit.o
termkey_objs = termkey.o driver-ti.o driver-csi.o

# Build.

all: textadept textadeptjit
ncurses: textadept-ncurses textadeptjit-ncurses
m32: textadept32 textadeptjit32 textadept32-ncurses textadeptjit32-ncurses
win32: textadept.exe textadeptjit.exe
osx: textadept.osx textadeptjit.osx
osx-ncurses: textadept-ncurses.osx textadeptjit-ncurses.osx

tmp:
	rm -rf /tmp/tabuild && hg clone ../ /tmp/tabuild
	cp -rL Doxygen ../doc ../lexers ../modules /tmp/tabuild/
	cp -r gtdialog gtkosx LexLPeg.cxx lua luajit scintilla termkey win32gtk \
		/tmp/tabuild/src/
	cd /tmp/tabuild/src/luajit && make clean
	ln -s `pwd`/../releases /tmp/tabuild
	@echo /tmp/tabuild ready for building.

# Dependencies.

$(scintilla_objs): scintilla/src/*.cxx scintilla/lexlib/*.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $^
$(scintilla_gtk_objs): scintilla/gtk/*.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $(gtk_flags) $^
scintilla-marshal.o: scintilla/gtk/scintilla-marshal.c
	$(CROSS)$(CC) -c $(CFLAGS) $(gtk_flags) $<
ScintillaTerm.o: scintilla/term/ScintillaTerm.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) -Iscintilla/term -Itermkey $^
LexLPeg.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Ilua/src $<
LexLPegjit.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Iluajit/src $< -o $@
textadept.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src $(gtk_flags) $<
textadeptjit.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src $(gtk_flags) $< \
		-o $@
textadept-ncurses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src -Iscintilla/term -Itermkey \
		$< -o $@
textadeptjit-ncurses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src \
		-Iscintilla/term -Itermkey $< -o $@
$(lua_objs): lua/src/*.c lua/src/lib/*.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUAFLAGS) -Ilua/src $^
$(luajit_objs): lua/src/lib/*.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUAFLAGS) -Iluajit/src $^
	for lib in $(luajit_objs); do mv $$(echo $$lib | sed 's/jit//g') $$lib; done
libluajit.a:
	cd luajit && make CC="$(CC) $(CFLAGS)"
	cp luajit/src/$@ .
lua51.dll:
	cd luajit && make HOST_CC="$(CC) -m32" CROSS=$(CROSS) TARGET_SYS=Windows
	cp luajit/src/$@ .
gtdialog.o: gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -DGTK -DNOHELP -DLIBRARY $(gtk_flags) $<
gtdialog-ncurses.o: gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -DNCURSES -DNOHELP -DLIBRARY $< -o $@
$(termkey_objs): termkey/*.c
	$(CROSS)$(CC) -c $(CFLAGS) -std=c99 $^
textadept_rc.o: textadept.rc
	$(CROSS)$(WINDRES) $^ $@

# Executables.

textadept: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
           LexLPeg.o textadept.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadeptjit: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
              LexLPegjit.o textadeptjit.o $(luajit_objs) libluajit.a gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadept-ncurses: $(scintilla_objs) ScintillaTerm.o LexLPeg.o \
                   textadept-ncurses.o $(lua_objs) gtdialog-ncurses.o \
                   $(termkey_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ -lncursesw -lcdk $(LDFLAGS)
textadeptjit-ncurses: $(scintilla_objs) ScintillaTerm.o LexLPegjit.o \
                      textadeptjit-ncurses.o $(luajit_objs) libluajit.a \
                      gtdialog-ncurses.o $(termkey_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ -lncursesw -lcdk $(LDFLAGS)
textadept32: ../textadept; mv $< ../$@
textadeptjit32: ../textadeptjit; mv $< ../$@
textadept32-ncurses: ../textadept-ncurses; mv $< ../$@
textadeptjit32-ncurses: ../textadeptjit-ncurses; mv $< ../$@
textadept.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
               LexLPeg.o textadept.o textadept_rc.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadeptjit.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
                  LexLPegjit.o textadeptjit.o textadept_rc.o $(luajit_objs) \
                  lua51.dll gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadept.osx: textadept; mv ../$< ../$@
textadeptjit.osx: textadeptjit; mv ../$< ../$@
textadept-ncurses.osx: textadept-ncurses; mv ../$< ../$@
textadeptjit-ncurses.osx: textadeptjit-ncurses; mv ../$< ../$@

# Clean.

mostlyclean:
	rm -f *.o
cleanjit:
	cd luajit && make clean
clean: mostlyclean cleanjit
	rm -f ../textadept* *.a *.dll

# Documentation.

doc: manual luadoc adeptsense doxygen
manual: ../doc/*.md ../*.md
	../doc/bombay -d ../doc -t ../doc --title Textadept --navtitle Manual $^
luadoc: ../modules ../core ../lexers/lexer.lua
	cd ../doc && $(luadoc) -d . -t . --doclet markdowndoc $^
adeptsense: ../modules ../core ../lexers/lexer.lua
	cd ../modules && $(luadoc) -d lua --doclet lua/adeptsensedoc $^
doxygen: ../Doxyfile
	doxygen $<
cleandoc:
	rm -f ../doc/*.html
	rm -rf ../doc/api ../doc/doxygen

# Package.

basedir = textadept_$(shell grep "_RELEASE =" ../core/init.lua | \
                            cut -d ' ' -f 4- | sed -e 's/"//; s/ /_/;')
modules = css hypertext java rails rhtml ruby php

release: ../textadept ../textadeptjit ../textadept-ncurses \
         ../textadeptjit-ncurses ../textadept32 ../textadeptjit32 \
         ../textadept32-ncurses ../textadeptjit32-ncurses ../textadept.exe \
         ../textadeptjit.exe ../textadept.osx ../textadeptjit.osx lua51.dll \
         doc pkg_x86_64 pkg_i386 pkg_win32 pkg_osx pkg_src pkg_modules cleanup

# Release directories.

$(basedir):
	hg archive $@
	rm $@/.hg*
	cp -rL ../doc $@
	hg clone /home/mitchell/code/scintillua tmp && mv tmp/lexers $@ && rm -r tmp
$(basedir).x86_64: ../textadept ../textadeptjit ../textadept-ncurses \
                   ../textadeptjit-ncurses | $(basedir)
	cp -r $| $@ && cp $^ $@
$(basedir).i386: ../textadept32 ../textadeptjit32 ../textadept32-ncurses \
                 ../textadeptjit32-ncurses | $(basedir)
	cp -r $| $@ && cp $^ $@
	for t in `ls $@/textadept*`; do mv $$t `echo $$t | sed -e 's/32//;'`; done
$(basedir).win32: ../textadept.exe ../textadeptjit.exe lua51.dll | $(basedir)
	cp -r $| $@ && cp $^ $@
	cp win32gtk/bin/*.dll $@ && cp -r win32gtk/etc win32gtk/lib win32gtk/share $@
	rm -r $@/lib/*.a $@/lib/glib-2.0 $@/lib/gtk-2.0/include $@/lib/pkgconfig
$(basedir).osx: ../textadept.osx ../textadeptjit.osx | $(basedir)
	mkdir $@ && cp -rL gtkosx $@/Textadept.app
	cp $^ $@/Textadept.app/Contents/MacOS/
	cp -r $|/* $@/Textadept.app/Contents/Resources/
	mv $@/Textadept.app/Contents/Resources/core/images/textadept.icns \
		$@/Textadept.app/Contents/Resources/
	mv $@/Textadept.app/Contents/MacOS/ta $@
$(basedir).src: | $(basedir)
	cp -r $| $@ && cp -rL lua luajit scintilla gtdialog LexLPeg.cxx termkey $@/src
	cd $@/src/luajit && make clean && cd ../../../
	rm -r $@/src/scintilla/.hg
$(basedir).modules:
	mkdir -p $@/modules
	for module in $(modules); do \
		hg clone /home/mitchell/code/textadept/modules/$$module \
			$@/modules/$$module; \
	done

# Release Packages.

pkg_x86_64: $(basedir).x86_64 ; tar czf ../releases/$<.tgz $< && rm -r $<
pkg_i386: $(basedir).i386 ; tar czf ../releases/$<.tgz $< && rm -r $<
pkg_win32: $(basedir).win32 ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_osx: $(basedir).osx ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_src: $(basedir).src ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_modules: $(basedir).modules ; zip -r ../releases/$<.zip $< && rm -r $<

# Clean.

cleanup: ../releases/$(basedir).x86_64.tgz ../releases/$(basedir).i386.tgz \
         ../releases/$(basedir).win32.zip ../releases/$(basedir).osx.zip \
         ../releases/$(basedir).src.zip ../releases/$(basedir).modules.zip | \
         $(basedir)
	rm -r $|

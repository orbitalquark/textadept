# Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

kernel = $(shell uname -s)
ifneq (, $(or $(findstring Linux, $(kernel)), $(findstring BSD, $(kernel))))
  ifeq (win, $(findstring win, $(MAKECMDGOALS)))
    # Cross-compile for Win32.
    ifeq (win32, $(findstring win32, $(MAKECMDGOALS)))
      arch = win32
      CROSS = i686-w64-mingw32-
    else ifeq (win64, $(findstring win64, $(MAKECMDGOALS)))
      arch = win64
      CROSS = x86_64-w64-mingw32-
    endif
    CC = gcc
    CFLAGS = -mms-bitfields
    CXX = g++
    CXXFLAGS = -mms-bitfields -static-libgcc -static-libstdc++
    LDFLAGS = -Wl,--retain-symbols-file -Wl,lua.sym
    ifeq (, $(findstring curses, $(MAKECMDGOALS)))
      CXXFLAGS += -mwindows
      LDFLAGS += -liconv
    endif
    WINDRES = windres
    MAKE = make

    ifeq (, $(findstring curses, $(MAKECMDGOALS)))
      plat_flag = -DGTK
      gtk_flags = $(shell PKG_CONFIG_PATH=`pwd`/$(arch)gtk/lib/pkgconfig \
                          pkg-config --define-variable=prefix=$(arch)gtk \
                          --cflags gtk+-2.0)
      gtk_libs = $(shell PKG_CONFIG_PATH=`pwd`/$(arch)gtk/lib/pkgconfig \
                         pkg-config --define-variable=prefix=$(arch)gtk \
                         --libs gtk+-2.0)
    else
      plat_flag = -DCURSES
      curses_flags = -DLIBICONV_STATIC -I$(arch)curses/include
      curses_libs = $(arch)curses/lib/pdcurses.a $(arch)curses/lib/libiconv.a
    endif

    luadoc = luadoc_start.bat
  else ifeq (osx, $(findstring osx, $(MAKECMDGOALS)))
    # Cross-compile for Mac OSX.
    CROSS = i686-apple-darwin10-
    CC = gcc
    CFLAGS = -m32 -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
             -isysroot /usr/lib/apple/SDKs/MacOSX10.5.sdk
    CXX = g++
    CXXFLAGS = -m32 -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
               -isysroot /usr/lib/apple/SDKs/MacOSX10.5.sdk
    LUAFLAGS = -DLUA_USE_MACOSX
    LDFLAGS = -liconv -rdynamic
    MAKE = make

    ifeq (, $(findstring curses, $(MAKECMDGOALS)))
      plat_flag = -DGTK
      gtk_flags = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                          pkg-config --define-variable=prefix=gtkosx \
                          --cflags gtk+-2.0)
      gtk_libs = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                         pkg-config --define-variable=prefix=gtkosx \
                         --libs gtk+-2.0 gmodule-2.0 gtk-mac-integration) \
                         -framework Cocoa
    else
      plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
      curses_libs = -lncurses
    endif
    libluajit = libluajit.osx.a

    luadoc = luadoc
  else
    # Build for Linux/BSD.
    CC = gcc
    CXX = g++
    LUAFLAGS = -DLUA_USE_LINUX
    LDFLAGS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym
    ifeq (Linux, $(kernel))
      LDFLAGS += -ldl
      MAKE = make
    else
      ifeq (curses, $(findstring curses, $(MAKECMDGOALS)))
        LDFLAGS += -liconv
      endif
      MAKE = gmake
    endif
    PREFIX ?= /usr/local

    bin_dir = $(DESTDIR)$(PREFIX)/bin
    data_dir = $(DESTDIR)$(PREFIX)/share/textadept

    ifeq (, $(findstring curses, $(MAKECMDGOALS)))
      plat_flag = -DGTK
      ifndef GTK3
        gtk_version = 2.0
      else
        gtk_version = 3.0
      endif
      gtk_flags = $(shell pkg-config --cflags gtk+-$(gtk_version))
      gtk_libs = $(shell pkg-config --libs gtk+-$(gtk_version))
      install_targets = ../textadept ../textadeptjit
    else
      plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
      curses_libs = -lncursesw
      install_targets = ../textadept-curses ../textadeptjit-curses
    endif
    x64 = $(shell echo "" | $(CC) -E -dM - | grep __x86_64__ | cut -d ' ' -f 3)
    ifeq (1, $(x64))
      libluajit = libluajit.a
    else
      libluajit = libluajit32.a
    endif

    luadoc = luadoc
  endif
#else ifeq (Darwin, $(shell uname -s))
#  CC = gcc
#  CFLAGS = -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
#           -isysroot /Developer/SDKs/MacOSX10.5.sdk
#  CXX = g++
#  CXXFLAGS = -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
#             -isysroot /Developer/SDKs/MacOSX10.5.sdk
#  LUAFLAGS = -DLUA_USE_MACOSX
#  LDFLAGS = -liconv -rdynamic
#
#  #ifeq (, $(findstring curses, $(MAKECMDGOALS)))
#    plat_flag = -DGTK
#    gtk_flags = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
#                        gtkosx/bin/pkg-config --define-variable=prefix=gtkosx \
#                        --cflags gtk+-2.0)
#    gtk_libs = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
#                       gtkosx/bin/pkg-config --define-variable=prefix=gtkosx \
#                       --libs gtk+-2.0) -framework Cocoa -lgtkmacintegration
#    .DEFAULT_GOAL := osx
#  #else
#  #  plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
#  #  curses_libs = -lncurses
#  #  .DEFAULT_GOAL := osx-curses
#  #endif
#
#  luadoc = luadoc
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
#          lpvm.o lpcap.o lptree.o lpcode.o lpprint.o lfs.o
luajit_objs = lpegjit.o lfsjit.o
#luajit_objs= lpvmjit.o lpcapjit.o lptreejit.o lpcodejit.o lpprintjit.o lfsjit.o
termkey_objs = termkey.o driver-ti.o driver-csi.o
cdk_objs = binding.o buttonbox.o button.o cdk.o cdk_display.o cdk_objs.o \
           cdk_params.o cdkscreen.o debug.o draw.o entry.o fselect.o \
           itemlist.o label.o mentry.o menu.o popup_label.o position.o \
           scroll.o select_file.o traverse.o version.o

# Build.

all: textadept textadeptjit
curses: textadept-curses textadeptjit-curses
m32: textadept32 textadeptjit32 textadept32-curses textadeptjit32-curses
win32: textadept.exe textadeptjit.exe
win32-curses: textadept-curses.exe textadeptjit-curses.exe
win64: textadept64.exe #textadeptjit64.exe
win64-curses: textadept64-curses.exe #textadeptjit64-curses.exe
osx: textadept.osx textadeptjit.osx
osx-curses: textadept-curses.osx textadeptjit-curses.osx

tmp:
	rm -rf /tmp/tabuild && hg clone ../ /tmp/tabuild
	cp -rL ../Doxyfile ../doc ../lexers ../modules /tmp/tabuild/
	cp -rL gtdialog gtkosx LexLPeg.cxx libluajit*.a lua luajit lua51.dll \
		scintilla termkey cdk win*gtk win*curses /tmp/tabuild/src/
	cd /tmp/tabuild/src/luajit && $(MAKE) clean
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
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) -Iscintilla/term $(curses_flags) $^
LexLPeg.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Ilua/src $<
LexLPegjit.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Iluajit/src $< -o $@
LexLPeg-curses.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -DCURSES -Ilua/src $(curses_flags) $< -o $@
LexLPegjit-curses.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -DCURSES -Iluajit/src $(curses_flags) $< -o $@
textadept.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src $(gtk_flags) $<
textadeptjit.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src $(gtk_flags) $< \
		-o $@
textadept-curses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src -Iscintilla/term -Itermkey \
		-Icdk $(curses_flags) $< -o $@
textadeptjit-curses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src \
		-Iscintilla/term -Itermkey -Icdk $(curses_flags) $< -o $@
$(lua_objs): lua/src/*.c lua/src/lib/*.c lua/src/lib/lpeg/*.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUAFLAGS) -Ilua/src $^
$(luajit_objs): lua/src/lib/*.c lua/src/lib/lpeg/*.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUAFLAGS) -Iluajit/src $^
	for lib in $(luajit_objs); do mv $$(echo $$lib | sed 's/jit//g') $$lib; done
libluajit.a:
	cd luajit && $(MAKE) CC="$(CC) $(CFLAGS)"
	cp luajit/src/$@ .
libluajit32.a:
	cd luajit && $(MAKE) CC="$(CC) $(CFLAGS)"
	cp luajit/src/libluajit.a $@
lua51.dll:
	cd luajit && $(MAKE) HOST_CC="$(CC) -m32" CROSS=$(CROSS) TARGET_SYS=Windows
	cp luajit/src/$@ .
lua51_64.dll:
	cd luajit && $(MAKE) HOST_CC="$(CC)" CROSS=$(CROSS) TARGET_SYS=Windows
	cp luajit/src/$@ .
libluajit.osx.a:
	cd luajit && $(MAKE) CC="$(CC) -m32" CROSS=$(CROSS) TARGET_SYS=Darwin || \
		return 0
	cp luajit/src/libluajit.a $@
gtdialog.o: gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -DGTK -DNOHELP -DLIBRARY $(gtk_flags) $<
gtdialog-curses.o: gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -DCURSES -DNOHELP -DLIBRARY -Icdk $(curses_flags) \
		$< -o $@
$(termkey_objs): termkey/*.c
	$(CROSS)$(CC) -c $(CFLAGS) -std=c99 $^
$(cdk_objs): cdk/*.c
	$(CROSS)$(CC) -c $(CFLAGS) -D_GNU_SOURCE -Icdk $(curses_flags) $^
textadept_rc.o: textadept.rc
	$(CROSS)$(WINDRES) $^ $@

# Executables.

textadept: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
           LexLPeg.o textadept.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadeptjit: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
              LexLPegjit.o textadeptjit.o $(luajit_objs) $(libluajit) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadept-curses: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                  textadept-curses.o $(lua_objs) gtdialog-curses.o \
                  $(termkey_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadeptjit-curses: $(scintilla_objs) ScintillaTerm.o LexLPegjit-curses.o \
                     textadeptjit-curses.o $(luajit_objs) $(libluajit) \
                     gtdialog-curses.o $(termkey_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadept32: ../textadept; mv $< ../$@
textadeptjit32: ../textadeptjit; mv $< ../$@
textadept32-curses: ../textadept-curses; mv $< ../$@
textadeptjit32-curses: ../textadeptjit-curses; mv $< ../$@
textadept.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
               LexLPeg.o textadept.o textadept_rc.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadeptjit.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
                  LexLPegjit.o textadeptjit.o textadept_rc.o $(luajit_objs) \
                  lua51.dll gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadept-curses.exe: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                      textadept-curses.o textadept_rc.o $(lua_objs) \
                      gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadeptjit-curses.exe: $(scintilla_objs) ScintillaTerm.o \
                         LexLPegjit-curses.o textadeptjit-curses.o \
                         textadept_rc.o $(luajit_objs) lua51.dll \
                         gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadept64.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
                 LexLPeg.o textadept.o textadept_rc.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadeptjit64.exe: $(scintilla_objs) $(scintilla_gtk_objs) \
                    scintilla-marshal.o LexLPegjit.o textadeptjit.o \
                    textadept_rc.o $(luajit_objs) lua51_64.dll gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(gtk_libs) $(LDFLAGS)
textadept64-curses.exe: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                        textadept-curses.o textadept_rc.o $(lua_objs) \
                        gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadeptjit64-curses.exe: $(scintilla_objs) ScintillaTerm.o \
                           LexLPegjit-curses.o textadeptjit-curses.o \
                           textadept_rc.o $(luajit_objs) lua51_64.dll \
                           gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(curses_libs) $(LDFLAGS)
textadept.osx: textadept; mv ../$< ../$@
textadeptjit.osx: textadeptjit; mv ../$< ../$@
textadept-curses.osx: textadept-curses; mv ../$< ../$@
textadeptjit-curses.osx: textadeptjit-curses; mv ../$< ../$@

# Install/uninstall.

install: $(install_targets) | ../core ../doc ../init.lua ../lexers ../LICENSE \
                              ../modules ../themes
	install -d $(bin_dir) $(data_dir)
	install $^ $(data_dir)
	cp -r $| $(data_dir)
	ln -s $(subst .., $(subst $(DESTDIR),, $(data_dir)), $^) $(bin_dir)
uninstall:
	rm $(bin_dir)/textadept*
	rm -r $(data_dir)

# Clean.

mostlyclean:
	rm -f *.o
cleanjit:
	cd luajit && $(MAKE) clean
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
                            cut -d ' ' -f 4- | sed -e 's/"//; s/ /_/g;')
modules = css hypertext java rails rhtml ruby php python

release: ../textadept ../textadeptjit ../textadept-curses \
         ../textadeptjit-curses ../textadept32 ../textadeptjit32 \
         ../textadept32-curses ../textadeptjit32-curses ../textadept.exe \
         ../textadeptjit.exe ../textadept-curses.exe \
         ../textadeptjit-curses.exe ../textadept64.exe ../textadept.osx \
         ../textadeptjit.osx lua51.dll \
         doc pkg_x86_64 pkg_i386 pkg_win32 pkg_win64 pkg_osx pkg_src \
         pkg_modules cleanup

# Release directories.

$(basedir):
	hg archive $@
	rm $@/.hg*
	cp -rL ../doc $@
	hg clone /home/mitchell/code/scintillua tmp && mv tmp/lexers $@ && rm -r tmp
$(basedir).x86_64: ../textadept ../textadeptjit ../textadept-curses \
                   ../textadeptjit-curses | $(basedir)
	cp -r $| $@ && cp $^ $@
$(basedir).i386: ../textadept32 ../textadeptjit32 ../textadept32-curses \
                 ../textadeptjit32-curses | $(basedir)
	cp -r $| $@ && cp $^ $@
	for t in `ls $@/textadept*`; do mv $$t `echo $$t | sed -e 's/32//;'`; done
$(basedir).win32: ../textadept.exe ../textadeptjit.exe ../textadept-curses.exe \
                  ../textadeptjit-curses.exe lua51.dll | $(basedir)
	cp -r $| $@ && cp $^ $@
	cp win32gtk/bin/*.dll $@ && cp -r win32gtk/etc win32gtk/lib win32gtk/share $@
	rm -r $@/lib/*.a $@/lib/glib-2.0 $@/lib/gtk-2.0/include $@/lib/pkgconfig
$(basedir).win64: ../textadept64.exe | $(basedir)
	cp -r $| $@ && cp $^ $@
	for t in `ls $@/textadept*`; do mv $$t `echo $$t | sed -e 's/64\././;'`; done
	cp win64gtk/bin/*.dll $@ && cp -r win64gtk/etc win64gtk/lib win64gtk/share $@
	rm -r $@/lib/*.a $@/lib/glib-2.0 $@/lib/gtk-2.0/include $@/lib/pkgconfig
$(basedir).osx: ../textadept.osx ../textadeptjit.osx ../textadept-curses.osx \
                ../textadeptjit-curses.osx | $(basedir)
	mkdir $@ && cp -rL gtkosx/app $@/Textadept.app
	cp $^ $@/Textadept.app/Contents/MacOS/
	cp -rL $|/* $@/Textadept.app/Contents/Resources/
	mv $@/Textadept.app/Contents/Resources/core/images/textadept.icns \
		$@/Textadept.app/Contents/Resources/
	mv $@/Textadept.app/Contents/MacOS/ta $@
$(basedir).src: | $(basedir)
	cp -r $| $@
	cp -rL lua luajit scintilla gtdialog LexLPeg.cxx termkey cdk $@/src
	cd $@/src/luajit && $(MAKE) clean && cd ../../../
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
pkg_win64: $(basedir).win64 ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_osx: $(basedir).osx ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_src: $(basedir).src ; zip -r ../releases/$<.zip $< && rm -r $<
pkg_modules: $(basedir).modules ; zip -r ../releases/$<.zip $< && rm -r $<

# Clean.

cleanup: ../releases/$(basedir).x86_64.tgz ../releases/$(basedir).i386.tgz \
         ../releases/$(basedir).win32.zip ../releases/$(basedir).osx.zip \
         ../releases/$(basedir).src.zip ../releases/$(basedir).modules.zip | \
         $(basedir)
	rm -r $|

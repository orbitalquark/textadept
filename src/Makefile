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
      GTK_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/$(arch)gtk/lib/pkgconfig \
                           pkg-config --define-variable=prefix=$(arch)gtk \
                           --cflags gtk+-2.0)
      GTK_LIBS = $(shell PKG_CONFIG_PATH=`pwd`/$(arch)gtk/lib/pkgconfig \
                         pkg-config --define-variable=prefix=$(arch)gtk \
                         --libs gtk+-2.0)
    else
      plat_flag = -DCURSES
      CURSES_CFLAGS = -DLIBICONV_STATIC -I$(arch)curses/include
      CURSES_LIBS = $(arch)curses/lib/pdcurses.a $(arch)curses/lib/libiconv.a
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
      GTK_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                           pkg-config --define-variable=prefix=gtkosx \
                           --cflags gtk+-2.0)
      GTK_LIBS = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                         pkg-config --define-variable=prefix=gtkosx \
                         --libs gtk+-2.0 gmodule-2.0 gtk-mac-integration) \
                         -framework Cocoa
    else
      plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
      CURSES_LIBS = -lncurses
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
      GTK_CFLAGS = $(shell pkg-config --cflags gtk+-$(gtk_version))
      GTK_LIBS = $(shell pkg-config --libs gtk+-$(gtk_version))
      install_targets = ../textadept ../textadeptjit
    else
      plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
      CURSES_LIBS = -lncursesw
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
#    GTK_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
#                         gtkosx/bin/pkg-config --define-variable=prefix=gtkosx\
#                         --cflags gtk+-2.0)
#    GTK_LIBS = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
#                       gtkosx/bin/pkg-config --define-variable=prefix=gtkosx \
#                       --libs gtk+-2.0) -framework Cocoa -lgtkmacintegration
#    .DEFAULT_GOAL := osx
#  #else
#  #  plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
#  #  CURSES_LIBS = -lncurses
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
#          lpcap.o lpcode.o lpprint.o lptree.o lpvm.o lfs.o
luajit_objs = lpegjit.o lfsjit.o
#luajit_objs= lpcapjit.o lpcodejit.o lpprintjit.o lptreejit.o lpvmjit.o lfsjit.o
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
	cp -rL ../doc ../lexers ../modules /tmp/tabuild/
	cp -rL gtdialog gtkosx LexLPeg.cxx libluajit*.a lua luajit lua51.dll \
		scintilla termkey cdk win*gtk win*curses /tmp/tabuild/src/
	cd /tmp/tabuild/src/luajit && $(MAKE) clean
	ln -s `pwd`/../releases /tmp/tabuild
	@echo /tmp/tabuild ready for building.

# Dependencies.

base_deps = scintilla scintilla/term scintillua lua lualibs luajit gtdialog \
            cdk ../doc/bombay
deps: $(base_deps) termkey
win32-deps: $(base_deps) win32gtk win32curses
osx-deps: $(base_deps) gtkosx termkey

$(scintilla_objs): scintilla/src/*.cxx scintilla/lexlib/*.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $^
$(scintilla_gtk_objs): scintilla/gtk/*.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $(GTK_CFLAGS) $^
scintilla-marshal.o: scintilla/gtk/scintilla-marshal.c
	$(CROSS)$(CC) -c $(CFLAGS) $(GTK_CFLAGS) $<
ScintillaTerm.o: scintilla/term/ScintillaTerm.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) -Iscintilla/term $(CURSES_CFLAGS) \
		$^
LexLPeg.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Ilua/src $<
LexLPegjit.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -Iluajit/src $< -o $@
LexLPeg-curses.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -DCURSES -Ilua/src $(CURSES_CFLAGS) $< -o $@
LexLPegjit-curses.o: LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUAFLAGS) $(sci_flags) -DLPEG_LEXER \
		-DNO_SCITE -DCURSES -Iluajit/src $(CURSES_CFLAGS) $< -o $@
textadept.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src $(GTK_CFLAGS) $<
textadeptjit.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src $(GTK_CFLAGS) \
		$< -o $@
textadept-curses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -Ilua/src -Iscintilla/term -Itermkey \
		-Icdk $(CURSES_CFLAGS) $< -o $@
textadeptjit-curses.o: textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(ta_flags) -DLUAJIT -Iluajit/src \
		-Iscintilla/term -Itermkey -Icdk $(CURSES_CFLAGS) $< -o $@
$(lua_objs): lua/src/*.c lua/src/lib/*.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUAFLAGS) -Ilua/src $^
$(luajit_objs): $(addprefix lua/src/lib/, $(luajit_objs:jit.o=.c))
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
	$(CROSS)$(CC) -c $(CFLAGS) -DGTK -DNOHELP -DLIBRARY $(GTK_CFLAGS) $<
gtdialog-curses.o: gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -DCURSES -DNOHELP -DLIBRARY -Icdk \
		$(CURSES_CFLAGS) $< -o $@
$(cdk_objs): $(addprefix cdk/, $(cdk_objs:.o=.c))
	$(CROSS)$(CC) -c $(CFLAGS) -D_GNU_SOURCE -Icdk $(CURSES_CFLAGS) $^
$(termkey_objs): $(addprefix termkey/, $(termkey_objs:.o=.c))
	$(CROSS)$(CC) -c $(CFLAGS) -std=c99 $^
textadept_rc.o: textadept.rc ; $(CROSS)$(WINDRES) $^ $@

# Executables.

textadept: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
           LexLPeg.o textadept.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadeptjit: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
              LexLPegjit.o textadeptjit.o $(luajit_objs) $(libluajit) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadept-curses: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                  textadept-curses.o $(lua_objs) gtdialog-curses.o \
                  $(termkey_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadeptjit-curses: $(scintilla_objs) ScintillaTerm.o LexLPegjit-curses.o \
                     textadeptjit-curses.o $(luajit_objs) $(libluajit) \
                     gtdialog-curses.o $(termkey_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadept32: ../textadept ; mv $< ../$@
textadeptjit32: ../textadeptjit ; mv $< ../$@
textadept32-curses: ../textadept-curses ; mv $< ../$@
textadeptjit32-curses: ../textadeptjit-curses ; mv $< ../$@
textadept.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
               LexLPeg.o textadept.o textadept_rc.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadeptjit.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
                  LexLPegjit.o textadeptjit.o textadept_rc.o $(luajit_objs) \
                  lua51.dll gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadept-curses.exe: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                      textadept-curses.o textadept_rc.o $(lua_objs) \
                      gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadeptjit-curses.exe: $(scintilla_objs) ScintillaTerm.o \
                         LexLPegjit-curses.o textadeptjit-curses.o \
                         textadept_rc.o $(luajit_objs) lua51.dll \
                         gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadept64.exe: $(scintilla_objs) $(scintilla_gtk_objs) scintilla-marshal.o \
                 LexLPeg.o textadept.o textadept_rc.o $(lua_objs) gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadeptjit64.exe: $(scintilla_objs) $(scintilla_gtk_objs) \
                    scintilla-marshal.o LexLPegjit.o textadeptjit.o \
                    textadept_rc.o $(luajit_objs) lua51_64.dll gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadept64-curses.exe: $(scintilla_objs) ScintillaTerm.o LexLPeg-curses.o \
                        textadept-curses.o textadept_rc.o $(lua_objs) \
                        gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadeptjit64-curses.exe: $(scintilla_objs) ScintillaTerm.o \
                           LexLPegjit-curses.o textadeptjit-curses.o \
                           textadept_rc.o $(luajit_objs) lua51_64.dll \
                           gtdialog-curses.o $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadept.osx: textadept ; mv ../$< ../$@
textadeptjit.osx: textadeptjit ; mv ../$< ../$@
textadept-curses.osx: textadept-curses ; mv ../$< ../$@
textadeptjit-curses.osx: textadeptjit-curses ; mv ../$< ../$@

# Install/uninstall.

install: $(install_targets) | ../core ../doc ../init.lua ../lexers ../LICENSE \
                              ../modules ../themes
	install -d $(bin_dir) $(data_dir)
	install $^ $(data_dir)
	cp -r $| $(data_dir)
	ln -s $(subst .., $(subst $(DESTDIR),, $(data_dir)), $^) $(bin_dir)
uninstall: ; rm -r $(bin_dir)/textadept* $(data_dir)

# Clean.

mostlyclean: ; rm -f *.o
cleanjit: ; cd luajit && $(MAKE) clean
clean: mostlyclean cleanjit ; rm -f ../textadept* *.a *.dll

# Documentation.

doc: manual luadoc adeptsense
manual: ../doc/*.md ../*.md
	../doc/bombay -d ../doc -t ../doc --title Textadept --navtitle Manual $^
luadoc: ../modules ../core ../lexers/lexer.lua
	cd ../doc && $(luadoc) -d . -t . --doclet markdowndoc $^
adeptsense: ../modules ../core ../lexers/lexer.lua
	cd ../modules && $(luadoc) -d lua --doclet lua/adeptsensedoc $^
cleandoc: ; rm -rf ../doc/*.html ../doc/api

# Package.

basedir = textadept_$(shell grep "_RELEASE =" ../core/init.lua | \
                            cut -d ' ' -f 4- | sed -e 's/"//; s/ /_/g;')
nightly_basedir = textadept_NIGHTLY_$(shell date +"%F")
ifdef NIGHTLY
  basedir = $(nightly_basedir)
endif
modules = css hypertext java rails rhtml ruby php python
osxapp = Textadept.app
osxapp_bin = $(osxapp)/Contents/MacOS
osxapp_res = $(osxapp)/Contents/Resources
osxapp_libs = libatk-1.0.0.dylib libcairo.2.dylib libexpat.1.dylib \
              libffi.5.dylib libfontconfig.1.dylib libfreetype.6.dylib \
              libgdk_pixbuf-2.0.0.dylib libgdk-quartz-2.0.0.dylib \
              libgio-2.0.0.dylib libglib-2.0.0.dylib libgmodule-2.0.0.dylib \
              libgobject-2.0.0.dylib libgthread-2.0.0.dylib \
              libgtkmacintegration.2.dylib libgtk-quartz-2.0.0.dylib \
              libintl.8.dylib libpango-1.0.0.dylib libpangocairo-1.0.0.dylib \
              libpangoft2-1.0.0.dylib libpixman-1.0.dylib libpng14.14.dylib \
              charset.alias gdk-pixbuf-2.0 gtk-2.0 pango

release: ../textadept ../textadeptjit ../textadept-curses \
         ../textadeptjit-curses ../textadept32 ../textadeptjit32 \
         ../textadept32-curses ../textadeptjit32-curses ../textadept.exe \
         ../textadeptjit.exe ../textadept-curses.exe \
         ../textadeptjit-curses.exe ../textadept64.exe ../textadept.osx \
         ../textadeptjit.osx lua51.dll \
         doc pkg_x86_64 pkg_i386 pkg_win32 pkg_win64 pkg_osx pkg_src \
         pkg_modules cleanup
release-nightly: nightly nightly64 win32-nightly osx-nightly cleanup-nightly

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
osx-app: ../textadept.osx ../textadeptjit.osx ../textadept-curses.osx \
         ../textadeptjit-curses.osx | $(basedir)
	mkdir -p $(osxapp_bin) $(osxapp_res)
	cp Info.plist $(osxapp_bin)/../
	cp ../scripts/osx/textadept $^ $(osxapp_bin)/
	cp -rL $|/* $(osxapp_res)/
	mv $(osxapp_res)/core/images/textadept.icns $(osxapp_res)/
	cp -r gtkosx/etc gtkosx/share $(osxapp_res)/ && mkdir $(osxapp_res)/lib/
	cp -r $(addprefix gtkosx/lib/, $(osxapp_libs)) $(osxapp_res)/lib/
	rm -r $(osxapp_res)/lib/gtk-2.0/include $(osxapp_res)/lib/gtk-2.0/modules
	rm $(osxapp_res)/lib/gtk-2.0/2.10.0/printbackends/*
$(basedir).osx: osx-app | $(basedir)
	mkdir $@ && mv $(osxapp) $@
	cp ../scripts/osx/ta $@
$(basedir).src: | $(basedir)
	cp -r $| $@
	cp -rL lua luajit scintilla gtdialog LexLPeg.cxx termkey cdk $@/src
	cd $@/src/luajit && $(MAKE) clean && cd ../../../
	rm -r $@/src/scintilla/.hg
$(basedir).modules:
	mkdir -p $@/modules
	for mod in $(modules); do \
		hg clone /home/mitchell/code/textadept/modules/$$mod $@/modules/$$mod; \
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

# Nightly builds.

nightly_dir = /tmp/tabuild_nightly

$(nightly_dir):
	hg clone -r tip /home/mitchell/code/textadept $@
	ln -s /tmp $@/releases
nightly: | $(nightly_dir)
	make -C $(nightly_dir)/src deps clean
	PKG_CONFIG_PATH=/opt/gtk/lib/pkgconfig make -C $(nightly_dir)/src
	make -C $(nightly_dir)/src curses
	make -C $(nightly_dir)/src m32
	make -C $(nightly_dir)/src doc NIGHTLY=1 pkg_i386
nightly64: | $(nightly_dir)
	make -C $(nightly_dir)/src clean
	PKG_CONFIG_PATH=/opt/gtk64/lib/pkgconfig make -C $(nightly_dir)/src \
		CFLAGS=-m64 CXXFLAGS=-m64 || return 0
	make -C $(nightly_dir)/src CFLAGS=-m64 CXXFLAGS=-m64 \
		CURSES_CFLAGS=-I/opt/ncursesw64/include/ncursesw \
		CURSES_LIBS="-L/opt/ncursesw64/lib -lncursesw" curses || return 0
	touch $(nightly_dir)/textadeptjit $(nightly_dir)/textadeptjit-curses
	make -C $(nightly_dir)/src doc NIGHTLY=1 pkg_x86_64
win32-nightly: | $(nightly_dir)
	make -C $(nightly_dir)/src clean CROSS=i586-mingw32msvc- win32-deps
	make -C $(nightly_dir)/src CROSS=i586-mingw32msvc- win32
	make -C $(nightly_dir)/src CROSS=i586-mingw32msvc- win32-curses
	make -C $(nightly_dir)/src NIGHTLY=1 pkg_win32
osx-nightly: | $(nightly_dir)
	make -C $(nightly_dir)/src clean osx-deps
	make -C $(nightly_dir)/src osx
	make -C $(nightly_dir)/src osx-curses
	make -C $(nightly_dir)/src NIGHTLY=1 pkg_osx
cleanup-nightly: /tmp/$(nightly_basedir).i386.tgz \
                 /tmp/$(nightly_basedir).win32.zip \
                 /tmp/$(nightly_basedir).osx.zip | $(nightly_dir)
	rm -rf $|

# External dependencies.

scintilla_tgz = scintilla333.tgz?download
scinterm_zip = scinterm.zip
scintillua_zip = scintillua.zip
lua_tgz = lua-5.2.2.tar.gz
lpeg_tgz = lpeg-0.10.2.tar.gz
lfs_zip = master.zip
luajit_tgz = LuaJIT-2.0.2.tar.gz
gtdialog_zip = gtdialog.zip
cdk_tgz = cdk.tar.gz
termkey_tgz = libtermkey-0.16.tar.gz
win32gtk_zip = gtk+-bundle_2.24.10-20120208_win32.zip
win32iconv_bin_zip = libiconv-bin-zip.php
win32iconv_lib_zip = libiconv-lib-zip.php
win32curses_zip = win32curses.zip
pdcurses_zip = download
gtkosx_zip = gtkosx-2.24.16.zip
bombay_zip = bombay.zip

$(scintilla_tgz): ; wget "http://prdownloads.sourceforge.net/scintilla/$@"
scintilla: scintilla.patch | $(scintilla_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(scinterm_zip):
	wget "http://foicica.com/hg/scinterm/archive/tip.zip" && mv tip.zip $@
scintilla/term: | $(scinterm_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
scintillua: ../lexers LexLPeg.cxx
$(scintillua_zip):
	wget "http://foicica.com/hg/scintillua/archive/tip.zip" && mv tip.zip $@
../lexers: | $(scintillua_zip)
	mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
	ln -s $@/lexers/*.lua $@
LexLPeg.cxx: | ../lexers ; ln -s $|/$@ $@
$(lua_tgz): ; wget "http://www.lua.org/ftp/$@"
$(lpeg_tgz): ; wget "http://www.inf.puc-rio.br/~roberto/lpeg/$@"
$(lfs_zip): ; wget "https://github.com/keplerproject/luafilesystem/archive/$@"
lua: lua.patch | $(lua_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
lualibs: lua/src/lib/lpeg lua/src/lib/lfs
lua/src/lib/lpeg: | $(lpeg_tgz)
	mkdir -p $@ && tar xzf $| -C $@ && mv $@/*/*.c $@/*/*.h $(dir $@)
lua/src/lib/lfs: | $(lfs_zip)
	mkdir -p $@ && unzip -d $@ $| && mv $@/*/src/*.c $@/*/src/*.h $(dir $@)
$(luajit_tgz): ; wget "http://luajit.org/download/$@"
luajit: luajit.patch | $(luajit_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(gtdialog_zip):
	wget "http://foicica.com/hg/gtdialog/archive/tip.zip" && mv tip.zip $@
gtdialog: | $(gtdialog_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
$(cdk_tgz): ; wget "http://invisible-island.net/datafiles/release/$@"
cdk: cdk.patch | $(cdk_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	mv $@/include/*.h $@
	patch -d $@ -N -p1 < $<
$(termkey_tgz): ; wget "http://www.leonerd.org.uk/code/libtermkey/$@"
termkey: | $(termkey_tgz) ; mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
$(win32gtk_zip):
	wget "http://ftp.gnome.org/pub/gnome/binaries/win32/gtk+/2.24/$@"
$(win32iconv_bin_zip): ; wget "http://gnuwin32.sourceforge.net/downlinks/$@"
$(win32iconv_lib_zip): ; wget "http://gnuwin32.sourceforge.net/downlinks/$@"
win32gtk: | $(win32gtk_zip) $(win32iconv_bin_zip) $(win32iconv_lib_zip)
	mkdir $@
	unzip -d $@ $(win32gtk_zip)
	for zip in $(win32iconv_bin_zip) $(win32iconv_lib_zip); do \
		unzip -d $@ $$zip; \
	done
	rm -r $@/etc/bash_completion.d $@/lib/gtk-2.0/modules $@/lib/*.def
	cd $@/share && rm -r aclocal doc glib-2.0 gtk-2.0 gtk-doc locale man
$(win32curses_zip): ; wget "http://foicica.com/textadept/download/$@"
$(pdcurses_zip):
	wget "http://sf.net/projects/pdcurses/files/pdcurses/3.4/pdcurs34.zip/$@"
win32curses: | $(win32curses_zip) $(pdcurses_zip)
	unzip $(win32curses_zip)
	mkdir $@/src && unzip -d $@/src $(pdcurses_zip)
	cp $@/lib/pdckbd.c $@/src/win32
	cd $@/src/win32 && $(MAKE) -f gccwin32.mak CC="$(CROSS)$(CC) $(CFLAGS)" \
		LIBEXE=$(CROSS)ar LINK="$(CROSS)$(CC) $(CFLAGS)" WIDE=Y UTF8=Y
	cp $@/src/win32/pdcurses.a $@/lib/
$(gtkosx_zip): ; wget "http://foicica.com/textadept/download/$@"
gtkosx: | $(gtkosx_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
$(bombay_zip):
	wget "http://foicica.com/hg/bombay/archive/tip.zip" && mv tip.zip $@
../doc/bombay: | $(bombay_zip)
	mkdir $(notdir $@) && unzip -d $(notdir $@) $| && \
		mv $(notdir $@)/*/* $(dir $@)

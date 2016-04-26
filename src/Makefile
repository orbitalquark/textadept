# Copyright 2007-2016 Mitchell mitchell.att.foicica.com. See LICENSE.

CC = gcc
CXX = g++
ifeq (win, $(findstring win, $(MAKECMDGOALS)))
  # Cross-compile for Win32.
  CROSS = i686-w64-mingw32-
  CFLAGS = -mms-bitfields -Os
  CXXFLAGS = -mms-bitfields -static-libgcc -static-libstdc++ -Os
  LUA_CFLAGS = -DLUA_BUILD_AS_DLL -DLUA_LIB
  LDFLAGS = -Wl,--retain-symbols-file -Wl,lua.sym
  ifeq (, $(findstring curses, $(MAKECMDGOALS)))
    CXXFLAGS += -mwindows
    LDFLAGS += -liconv
  endif
  WINDRES = windres
  MAKE = make
  ifeq (, $(findstring curses, $(MAKECMDGOALS)))
    plat_flag = -DGTK
    GTK_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/win32gtk/lib/pkgconfig \
                         pkg-config --define-variable=prefix=win32gtk \
                         --cflags gtk+-2.0)
    GTK_LIBS = $(shell PKG_CONFIG_PATH=`pwd`/win32gtk/lib/pkgconfig \
                       pkg-config --define-variable=prefix=win32gtk \
                       --libs gtk+-2.0)
    GLIB_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/win32gtk/lib/pkgconfig \
                          pkg-config --define-variable=prefix=win32gtk \
                          --cflags glib-2.0)
  else
    plat_flag = -DCURSES
    CURSES_CFLAGS = -DLIBICONV_STATIC -Iwin32curses/include
    CURSES_LIBS = win32curses/lib/pdcurses.a win32curses/lib/libiconv.a
  endif
  libluajit = luajit/src/lua51.dll
else ifeq (osx, $(findstring osx, $(MAKECMDGOALS)))
  # Cross-compile for Mac OSX.
  CROSS = i686-apple-darwin10-
  CFLAGS = -m32 -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
           -isysroot /usr/lib/apple/SDKs/MacOSX10.5.sdk -Os
  CXXFLAGS = -m32 -arch i386 -mdynamic-no-pic -mmacosx-version-min=10.5 \
             -isysroot /usr/lib/apple/SDKs/MacOSX10.5.sdk -Os
  LUA_CFLAGS = -DLUA_USE_MACOSX
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
    GLIB_CFLAGS = $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
                          pkg-config --define-variable=prefix=gtkosx \
                          --cflags glib-2.0)
  else
    plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
    CURSES_LIBS = -lncurses
  endif
  libluajit = luajit/src/libluajit.osx.a
else
  # Build for Linux/BSD.
  CFLAGS = -Os
  CXXFLAGS = -Os -std=c++0x
  LUA_CFLAGS = -DLUA_USE_LINUX
  LDFLAGS = -rdynamic -Wl,--retain-symbols-file -Wl,lua.sym
  ifeq (Linux, $(shell uname -s))
    LDFLAGS += -ldl
    MAKE = make
  else
    LDFLAGS += -liconv
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
    GTK_CFLAGS = $(shell pkg-config --cflags gtk+-$(gtk_version) gmodule-2.0)
    GTK_LIBS = $(shell pkg-config --libs gtk+-$(gtk_version) gmodule-2.0)
    GLIB_CFLAGS = $(shell pkg-config --cflags glib-2.0)
    install_targets = ../textadept ../textadeptjit
  else
    plat_flag = -DCURSES -D_XOPEN_SOURCE_EXTENDED
    CURSES_LIBS = -lncursesw
    install_targets = ../textadept-curses ../textadeptjit-curses
  endif
  libluajit = luajit/src/libluajit.a
endif

# Scintilla.

sci_flags = -pedantic $(plat_flag) -DSCI_LEXER -DNDEBUG -DG_THREADS_IMPL_NONE \
            -Iscintilla/include -Iscintilla/src -Iscintilla/lexlib -Wall

sci_objs = AutoComplete.o CallTip.o CaseConvert.o CaseFolder.o Catalogue.o \
           CellBuffer.o CharClassify.o ContractionState.o Decoration.o \
           Document.o EditModel.o Editor.o EditView.o ExternalLexer.o \
           Indicator.o KeyMap.o LineMarker.o MarginView.o PerLine.o \
           PositionCache.o RESearch.o RunStyles.o ScintillaBase.o Selection.o \
           Style.o UniConversion.o ViewStyle.o XPM.o
sci_lex_objs = Accessor.o CharacterSet.o LexerBase.o LexerModule.o \
               LexerNoExceptions.o LexerSimple.o PropSetSimple.o \
               StyleContext.o WordList.o
sci_gtk_objs = PlatGTK.o ScintillaGTK.o
lexlpeg_objs = LexLPeg.o LexLPegjit.o LexLPeg-curses.o LexLPegjit-curses.o

# Textadept.

ta_flags = -std=c99 -pedantic -D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE \
           $(plat_flag) -Iscintilla/include -Igtdialog -W -Wall -Wno-unused

textadept_gtk_objs = textadept.o textadeptjit.o
textadept_curses_objs = textadept-curses.o textadeptjit-curses.o
textadept_objs = $(textadept_gtk_objs) $(textadept_curses_objs)
lua_objs = lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o \
           linit.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o \
           lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o \
           lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o \
           lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o
lua_lib_objs = lpcap.o lpcode.o lpprint.o lptree.o lpvm.o lfs.o lutf8libext.o
luajit_lib_objs = lpcapjit.o lpcodejit.o lpprintjit.o lptreejit.o lpvmjit.o \
                  lfsjit.o lutf8libjit.o lutf8libextjit.o
lua_spawn_objs = lspawn.o lspawnjit.o lspawn-curses.o lspawnjit-curses.o
gtdialog_objs = gtdialog.o gtdialog-curses.o
termkey_unix_objs = driver-ti.o driver-csi.o
termkey_win32_objs = driver-win32-pdcurses.o
termkey_objs = termkey.o $(termkey_unix_objs) $(termkey_win32_objs)
cdk_objs = binding.o buttonbox.o cdk.o cdk_display.o cdk_objs.o cdkscreen.o \
           draw.o entry.o fselect.o itemlist.o label.o mentry.o popup_label.o \
           scroll.o scroller.o select_file.o selection.o traverse.o version.o

# Add debugging symbols and disable optimizations when DEBUG=1.
# Note: In order to profile with gprof (-pg), do not retain symbols in LDFLAGS.
ifdef DEBUG
  CFLAGS += -g -O0
  CXXFLAGS += -g -O0
endif

# Build.

all: textadept textadeptjit
curses: textadept-curses textadeptjit-curses
win32: textadept.exe textadeptjit.exe
win32-curses: textadept-curses.exe textadeptjit-curses.exe
osx: textadept textadeptjit
osx-curses: textadept-curses textadeptjit-curses

$(sci_objs): %.o: scintilla/src/%.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $< -o $@
$(sci_lex_objs): %.o: scintilla/lexlib/%.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $< -o $@
$(sci_gtk_objs): %.o: scintilla/gtk/%.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $(GTK_CFLAGS) $< -o $@
scintilla-marshal.o: scintilla/gtk/scintilla-marshal.c
	$(CROSS)$(CC) -c $(CFLAGS) $(GTK_CFLAGS) $< -o $@
ScintillaTerm.o: scintilla/term/ScintillaTerm.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(sci_flags) $(CURSES_CFLAGS) $< -o $@
$(lexlpeg_objs): LexLPeg.cxx
	$(CROSS)$(CXX) -c $(CXXFLAGS) $(LUA_CFLAGS) $(sci_flags) $< -o $@
$(textadept_objs): textadept.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) $(ta_flags) $< -o $@
$(lua_objs): %.o: lua/src/%.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) -ULUA_LIB $< -o $@
$(lua_lib_objs): %.o: lua/src/lib/%.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) $< -o $@
$(luajit_lib_objs): %jit.o: lua/src/lib/%.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) $< -o $@
$(lua_spawn_objs): lua/src/lib/lspawn.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) -std=c99 -pedantic -D_XOPEN_SOURCE \
		$(spawn_flags) $< -o $@
luajit/src/libluajit.a: ; $(MAKE) -C luajit CC="$(CC) $(CFLAGS)"
luajit/src/lua51.dll:
	$(MAKE) -C luajit HOST_CC="$(CC) -m32" CROSS=$(CROSS) TARGET_SYS=Windows
luajit/src/libluajit.osx.a:
	$(MAKE) -C luajit CC="$(CC) -m32" CROSS=$(CROSS) TARGET_SYS=Darwin \
		LUAJIT_A=$(notdir $@) || return 0
$(gtdialog_objs): gtdialog/gtdialog.c
	$(CROSS)$(CC) -c $(CFLAGS) -std=c99 -pedantic -D_POSIX_C_SOURCE=200809L \
		$(gtdialog_flags) $< -o $@
$(cdk_objs): %.o: cdk/%.c
	$(CROSS)$(CC) -c $(CFLAGS) -D_GNU_SOURCE -Itermkey -Icdk $(CURSES_CFLAGS) $< \
		-o $@
$(termkey_objs): %.o: termkey/%.c
	$(CROSS)$(CC) -c $(CFLAGS) -std=c99 $(termkey_flags) $< -o $@
textadept_rc.o: textadept.rc ; $(CROSS)$(WINDRES) $< $@

# Target-specific variables.

$(lexlpeg_objs): sci_flags += -DLPEG_LEXER -DNO_SCITE -Wno-long-long
LexLPeg-curses.o LexLPegjit-curses.o: sci_flags += -DCURSES $(CURSES_CFLAGS)
lua_dep_objs = LexLPeg.o LexLPeg-curses.o textadept.o textadept-curses.o \
               $(lua_objs) $(lua_lib_objs) lspawn.o lspawn-curses.o
luajit_dep_objs = LexLPegjit.o LexLPegjit-curses.o textadeptjit.o \
                  textadeptjit-curses.o $(luajit_lib_objs) lspawnjit.o \
                  lspawnjit-curses.o
$(lua_dep_objs): LUA_CFLAGS += -Ilua/src
$(luajit_dep_objs): LUA_CFLAGS += -Iluajit/src
$(textadept_gtk_objs): ta_flags += $(GTK_CFLAGS)
$(textadept_curses_objs): \
  ta_flags += -Iscintilla/term -Itermkey -Icdk $(CURSES_CFLAGS)
lspawn.o lspawnjit.o: spawn_flags = -DGTK $(GLIB_CFLAGS)
$(gtdialog_objs): gtdialog_flags = $(plat_flag) -DNOHELP -DLIBRARY
gtdialog.o: gtdialog_flags += $(GTK_CFLAGS)
gtdialog-curses.o: gtdialog_flags += -Icdk $(CURSES_CFLAGS)
$(termkey_win32_objs): termkey_flags += $(CURSES_CFLAGS)
# Lua 5.3 compatibility with LuaJIT.
lbitlib.o linit.o: LUA_CFLAGS += -DLUA_COMPAT_BITLIB -DLUA_COMPAT_APIINTCASTS
lutf8libjit.o: LUA_CFLAGS += -Ilua/src

# Executables.

textadept: $(sci_objs) $(sci_lex_objs) $(sci_gtk_objs) scintilla-marshal.o \
           LexLPeg.o textadept.o $(lua_objs) $(lua_lib_objs) lspawn.o gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadeptjit: $(sci_objs) $(sci_lex_objs) $(sci_gtk_objs) scintilla-marshal.o \
              LexLPegjit.o textadeptjit.o $(luajit_lib_objs) $(libluajit) \
              lspawnjit.o gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadept-curses: $(sci_objs) $(sci_lex_objs) ScintillaTerm.o LexLPeg-curses.o \
                  textadept-curses.o $(lua_objs) $(lua_lib_objs) \
                  lspawn-curses.o gtdialog-curses.o termkey.o \
                  $(termkey_unix_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadeptjit-curses: $(sci_objs) $(sci_lex_objs) ScintillaTerm.o \
                     LexLPegjit-curses.o textadeptjit-curses.o \
                     $(luajit_lib_objs) $(libluajit) lspawnjit-curses.o \
                     gtdialog-curses.o termkey.o $(termkey_unix_objs) \
                     $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadept.exe: $(sci_objs) $(sci_lex_objs) $(sci_gtk_objs) scintilla-marshal.o \
               LexLPeg.o textadept.o textadept_rc.o $(lua_objs) \
               $(lua_lib_objs) lspawn.o gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadeptjit.exe: $(sci_objs) $(sci_lex_objs) $(sci_gtk_objs) \
                  scintilla-marshal.o LexLPegjit.o textadeptjit.o \
                  textadept_rc.o $(luajit_lib_objs) $(libluajit) lspawnjit.o \
                  gtdialog.o
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(GTK_LIBS) $(LDFLAGS)
textadept-curses.exe: $(sci_objs) $(sci_lex_objs) ScintillaTerm.o \
                      LexLPeg-curses.o textadept-curses.o textadept_rc.o \
                      $(lua_objs) $(lua_lib_objs) lspawn-curses.o \
                      gtdialog-curses.o termkey.o $(termkey_win32_objs) \
                      $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)
textadeptjit-curses.exe: $(sci_objs) $(sci_lex_objs) ScintillaTerm.o \
                         LexLPegjit-curses.o textadeptjit-curses.o \
                         textadept_rc.o $(luajit_lib_objs) $(libluajit) \
                         lspawnjit-curses.o gtdialog-curses.o termkey.o \
                         $(termkey_win32_objs) $(cdk_objs)
	$(CROSS)$(CXX) $(CXXFLAGS) -o ../$@ $^ $(CURSES_LIBS) $(LDFLAGS)

# Install/uninstall.

install: $(install_targets) | ../core ../doc ../init.lua ../lexers ../LICENSE \
                              ../modules ../properties.lua ../themes
	install -d $(bin_dir) $(data_dir)
	install $^ $(data_dir)
	cp -r $| $(data_dir)
	ln -s $(subst .., $(subst $(DESTDIR),, $(data_dir)), $^) $(bin_dir)
uninstall: ; rm -r $(bin_dir)/textadept* $(data_dir)

# Clean.

clean:
	$(MAKE) -C luajit clean
	rm -f *.o ../textadept*

# Documentation.

doc: manual luadoc
manual: ../*.md ../doc/manual.md | ../doc/bombay
	$| -d ../doc -t ../doc --title Textadept $^
luadoc: ../modules ../core ../lexers
	cd ../doc && luadoc -d . -t . --doclet markdowndoc $^/lexer.lua
	cd ../modules && luadoc -d lua --doclet lua/tadoc $^/lexer.lua

# Releases.

ifndef NIGHTLY
  basedir = textadept_$(shell grep -m 1 _RELEASE ../core/init.lua | \
                              cut -d ' ' -f4- | tr ' ' '_' | tr -d '"')
else
  basedir = textadept_NIGHTLY_$(shell date +"%F")
endif
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

release-all: release release64 win32-release osx-release modules-release

$(basedir).i386: ; hg archive $@ -X ".hg*"
release: $(basedir).i386
	make deps clean doc sign-deps
	PKG_CONFIG_PATH=/opt/gtk/lib/pkgconfig make -j4
	make -j4 CURSES_CFLAGS=-I/opt/ncursesw/include/ncursesw \
		CURSES_LIBS="-L/opt/ncursesw/lib -lncursesw" curses
	cp -r ../doc ../lexers ../textadept* $< && cp *.asc $</src
	tar czf /tmp/$<.tgz $< && rm -rf $< && gpg -ab /tmp/$<.tgz
$(basedir).x86_64: ; hg archive $@ -X ".hg*"
release64: $(basedir).x86_64
	make clean libluajit64
	PKG_CONFIG_PATH=/opt/gtk64/lib/pkgconfig make -j4 CFLAGS="$(CFLAGS) -m64" \
		CXXFLAGS="$(CXXFLAGS) -m64" || return 0
	make -j4 CFLAGS="$(CFLAGS) -m64" CXXFLAGS="$(CXXFLAGS) -m64" \
		CURSES_CFLAGS=-I/opt/ncursesw64/include/ncursesw \
		CURSES_LIBS="-L/opt/ncursesw64/lib -lncursesw" curses || return 0
	cp -r ../doc ../lexers ../textadept* $< && cp *.asc $</src
	tar czf /tmp/$<.tgz $< && rm -rf $< && gpg -ab /tmp/$<.tgz
$(basedir).win32: ; hg archive $@ -X ".hg*"
win32-release: $(basedir).win32
	make -j4 clean CROSS=i586-mingw32msvc- win32-deps
	cp win32gtk/bin/*.dll $< && cp -r win32gtk/etc \
		win32gtk/lib win32gtk/share $<
	rm -r $</lib/*.a $</lib/glib-2.0 $</lib/gtk-2.0/include $</lib/pkgconfig
	make -j4 CROSS=i586-mingw32msvc- win32
	make -j4 CROSS=i586-mingw32msvc- win32-curses
	cp -r ../doc ../lexers ../textadept* luajit/src/lua51.dll $<
	cp *.asc $</src
	zip -r /tmp/$<.zip $< && rm -rf $< && gpg -ab /tmp/$<.zip
$(basedir).osx: ; mkdir $@ && cp ../scripts/osx/ta $@
osx-release: $(basedir).osx
	make clean osx-deps
	make -j4 osx
	make -j4 osx-curses
	make osx-app && mv $(osxapp) $<
	zip -r /tmp/$<.zip $< && rm -rf $< && gpg -ab /tmp/$<.zip
$(basedir).modules:
	mkdir -p $@/modules
	hg archive -R /home/mitchell/code/textadept_modules/ -r tip $@/modules
modules-release: $(basedir).modules
	zip -r /tmp/$<.zip $< && rm -r $< && gpg -ab /tmp/$<.zip

osx-app: ../textadept ../textadeptjit ../textadept-curses \
         ../textadeptjit-curses ../scripts/osx/textadept_osx
	mkdir -p $(osxapp_bin) $(osxapp_res)
	cp Info.plist $(osxapp_bin)/../
	cp $^ $(osxapp_bin)/
	hg archive $(osxapp_res) -X ".hg*"
	cp -r ../doc ../lexers $(osxapp_res) && cp *.asc $(osxapp_res)/src
	mv $(osxapp_res)/core/images/textadept.icns $(osxapp_res)/
	cp -r gtkosx/etc gtkosx/share $(osxapp_res)/ && mkdir $(osxapp_res)/lib/
	cp -r $(addprefix gtkosx/lib/, $(osxapp_libs)) $(osxapp_res)/lib/
	rm -r $(osxapp_res)/lib/gtk-2.0/include $(osxapp_res)/lib/gtk-2.0/modules
	rm $(osxapp_res)/lib/gtk-2.0/2.10.0/printbackends/*

# External dependencies.

base_deps = scintilla scintilla/term scintillua lua lualibs luajit gtdialog \
            cdk ../doc/bombay
deps: $(base_deps) termkey
win32-deps: $(base_deps) win32gtk win32curses
osx-deps: $(base_deps) gtkosx termkey

ifndef NIGHTLY
  scinterm_url = http://foicica.com/scinterm/download/$@
  scintillua_url = http://foicica.com/scintillua/download/$@
  gtdialog_url = http://foicica.com/gtdialog/download/$@
  lspawn_url = http://foicica.com/lspawn/download/$@
else
  scinterm_url = http://foicica.com/hg/scinterm/archive/tip.zip
  scintillua_url = http://foicica.com/hg/scintillua/archive/tip.zip
  gtdialog_url = http://foicica.com/hg/gtdialog/archive/tip.zip
  lspawn_url = http://foicica.com/hg/lspawn/archive/tip.zip
endif

scintilla_tgz = scintilla365.tgz
scinterm_zip = scinterm_1.8.zip
scintillua_zip = scintillua_3.6.5-1.zip
lua_tgz = lua-5.3.2.tar.gz
lpeg_tgz = lpeg-1.0.0.tar.gz
lfs_zip = v_1_6_3.zip
luautf8_zip = 0.1.1.zip
lspawn_zip = lspawn_1.5.zip
luajit_tgz = LuaJIT-2.0.3.tar.gz
libluajit_tgz = libluajit_2.0.3.x86_64.tgz
gtdialog_zip = gtdialog_1.2.zip
cdk_tgz = cdk-5.0-20150928.tgz
termkey_tgz = libtermkey-0.17.tar.gz
win32gtk_zip = gtk+-bundle_2.24.10-20120208_win32.zip
win32iconv_bin_zip = libiconv-bin-zip.php
win32iconv_lib_zip = libiconv-lib-zip.php
win32curses_zip = win32curses.zip
pdcurses_zip = pdcurs34.zip
gtkosx_zip = gtkosx-2.24.16.zip
bombay_zip = bombay.zip
cloc = cloc-1.60.pl

$(scintilla_tgz): ; wget http://prdownloads.sourceforge.net/scintilla/$@ -O $@
scintilla: scintilla.patch | $(scintilla_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(scinterm_zip): ; wget $(scinterm_url) -O $@
scintilla/term: | $(scinterm_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
scintillua: ../lexers LexLPeg.cxx
$(scintillua_zip): ; wget $(scintillua_url) -O $@
../lexers: | $(scintillua_zip)
	mkdir $@ && unzip -d $@ -j $| "*/lexers/*.lua" "*.txt" "*.cxx" -x "*/themes/*"
LexLPeg.cxx: | ../lexers ; ln -s $|/$@ $@
$(lua_tgz): ; wget http://www.lua.org/ftp/$@
$(lpeg_tgz): ; wget http://www.inf.puc-rio.br/~roberto/lpeg/$@
$(lfs_zip): ; wget http://github.com/keplerproject/luafilesystem/archive/$@
$(luautf8_zip): ; wget https://github.com/starwing/luautf8/archive/$@
$(lspawn_zip): ; wget $(lspawn_url) -O $@
lua: lua.patch | $(lua_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
lualibs: lua/src/lib/lpeg lua/src/lib/lfs lua/src/lib/lutf8libext \
         lua/src/lib/lspawn
lua/src/lib/lpeg: | $(lpeg_tgz)
	mkdir -p $@ && tar xzf $| -C $@ && mv $@/*/*.c $@/*/*.h $(dir $@)
lua/src/lib/lfs: lfs.patch | $(lfs_zip)
	mkdir -p $@ && unzip -d $@ $| && mv $@/*/src/*.c $@/*/src/*.h $(dir $@)
	patch -d $(dir $@) -N -p1 < $<
lua/src/lib/lutf8libext: lutf8libext.patch | $(luautf8_zip)
	mkdir -p $@ && unzip -d $@ $| && mv $@/*/*.h $(dir $@)
	# Rename lutf8lib.c in order to prevent conflicts with Lua's lutf8lib.c,
	# needed by LuaJIT.
	mv $@/*/lutf8lib.c $(dir $@)lutf8libext.c
	patch -d $(dir $@) -N -p1 < $<
lua/src/lib/lspawn: | $(lspawn_zip)
	mkdir -p $@ && unzip -d $@ $| && mv $@/*/*.c $(dir $@)
lua/src/lib/lutf8lib.c: lutf8libjit.patch
	cp lua/src/$(notdir $@) $@
	patch -d $(dir $@) -N -p1 < $<
$(luajit_tgz): ; wget http://luajit.org/download/$@
luajit: luajit.patch | $(luajit_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(libluajit_tgz): ; wget http://foicica.com/textadept/download/$@
libluajit64: | $(libluajit_tgz) ; tar xzf $|
$(gtdialog_zip): ; wget $(gtdialog_url) -O $@
gtdialog: | $(gtdialog_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
$(cdk_tgz): ; wget http://invisible-mirror.net/archives/cdk/$@
cdk: cdk.patch | $(cdk_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	mv $@/include/*.h $@
	patch -d $@ -N -p1 < $<
$(termkey_tgz): ; wget http://www.leonerd.org.uk/code/libtermkey/$@
termkey: termkey.patch | $(termkey_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(win32gtk_zip):
	wget http://ftp.gnome.org/pub/gnome/binaries/win32/gtk+/2.24/$@
$(win32iconv_bin_zip): ; wget http://gnuwin32.sourceforge.net/downlinks/$@
$(win32iconv_lib_zip): ; wget http://gnuwin32.sourceforge.net/downlinks/$@
win32gtk: | $(win32gtk_zip) $(win32iconv_bin_zip) $(win32iconv_lib_zip)
	mkdir $@
	unzip -d $@ $(win32gtk_zip)
	for zip in $(win32iconv_bin_zip) $(win32iconv_lib_zip); do \
		unzip -d $@ $$zip; \
	done
	rm -r $@/etc/bash_completion.d $@/lib/gtk-2.0/modules $@/lib/*.def
	cd $@/share && rm -r aclocal doc glib-2.0 gtk-2.0 gtk-doc locale man
$(win32curses_zip): ; wget http://foicica.com/textadept/download/$@
$(pdcurses_zip): ; wget http://prdownloads.sourceforge.net/pdcurses/$@
win32curses: | $(win32curses_zip) $(pdcurses_zip)
	unzip $(win32curses_zip)
	mkdir $@/src && unzip -d $@/src $(pdcurses_zip)
	cp $@/lib/pdckbd.c $@/src/win32
	cd $@/src/win32 && $(MAKE) -f gccwin32.mak CC="$(CROSS)$(CC) $(CFLAGS)" \
		LIBEXE=$(CROSS)ar LINK="$(CROSS)$(CC) $(CFLAGS)" WIDE=Y UTF8=Y
	cp $@/src/win32/pdcurses.a $@/lib/
$(gtkosx_zip): ; wget http://foicica.com/textadept/download/$@
gtkosx: | $(gtkosx_zip) ; mkdir $@ && unzip -d $@ $| && mv $@/*/* $@
$(bombay_zip): ; wget http://foicica.com/hg/bombay/archive/tip.zip -O $@
../doc/bombay: | $(bombay_zip)
	mkdir $(notdir $@) && unzip -d $(notdir $@) $| && \
		mv $(notdir $@)/*/* $(dir $@)
$(cloc): ; wget http://prdownloads.sourceforge.net/cloc/$@ -O $@
sign-deps: | $(scintilla_tgz) $(scinterm_zip) $(scintillua_zip) $(lua_tgz) \
             $(lpeg_tgz) $(lfs_zip) $(lspawn_zip) $(luajit_tgz) \
             $(libluajit_tgz) $(gtdialog_zip) $(cdk_tgz) $(termkey_tgz) \
             $(win32gtk_zip) $(win32iconv_bin_zip) $(win32iconv_lib_zip) \
             $(win32curses_zip) $(pdcurses_zip) $(gtkosx_zip)
	@for file in $|; do gpg -ab $$file; done
verify-deps: | $(wildcard $(basename $(wildcard *.asc)))
	@for file in $|; do echo "$$file"; gpg --verify $$file.asc || return 1; done

# Count lines of code and generate ctags.

sources = ../core ../modules/ansi_c ../modules/lua ../modules/textadept \
          ../themes textadept.c Makefile ../init.lua ../properties.lua
count: $(cloc) ; perl $< $(sources) --not-match-f=tadoc.lua
ctags:
	ctags -R --langdef=luax --langmap=luax:.lua --exclude="*doc*" \
		--exclude=scintilla/cocoa --exclude=scintilla/lexers \
		--exclude=scintilla/qt --exclude=scintilla/scripts \
		--exclude=scintilla/test --exclude=scintilla/win32 \
		--regex-luax="/^\s*function\s+[^[:space:]\.]*\.?([[:alnum:]_]+)\(/\1/f/" \
		--regex-luax="/^\s*local\s+function\s+([[:alnum:]_]+)\(/\1/F/" \
		--regex-luax="/^[^[:space:]\.]*\.?([[:alnum:]_]+)\s*=\s*[{]/\1/t/" \
		$(sources) LexLPeg.cxx scintilla gtdialog/gtdialog.c

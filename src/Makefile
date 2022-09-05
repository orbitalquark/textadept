# Copyright 2007-2022 Mitchell. See LICENSE.

# Base flags and options.

CFLAGS := -Os
CXXFLAGS := -Os -std=c++17
WGET = wget -O $@

# Define these once for speed and reference them later.
ifdef GTK2
  gtk_flags_linux := $(shell pkg-config --cflags gtk+-2.0 gmodule-2.0)
else
  gtk_flags_linux := $(shell pkg-config --cflags gtk+-3.0 gmodule-2.0) -Wno-deprecated-declarations
endif
glib_flags_linux := $(shell pkg-config --cflags glib-2.0)
curses_flags_linux := $(shell pkg-config --silence-errors --cflags ncursesw || \
  pkg-config --silence-errors --cflags ncurses || pkg-config --silence-errors --cflags curses)
gtk_flags_win := $(shell PKG_CONFIG_PATH=`pwd`/gtkwin/lib/pkgconfig \
  pkg-config --silence-errors --define-variable=prefix=gtkwin --cflags gtk+-3.0)
glib_flags_win := $(shell PKG_CONFIG_PATH=`pwd`/gtkwin/lib/pkgconfig \
  pkg-config --silence-errors --define-variable=prefix=gtkwin --cflags glib-2.0)
gtk_flags_osx := $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
  pkg-config --silence-errors --define-variable=prefix=gtkosx --cflags gtk+-3.0)
glib_flags_osx := $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
  pkg-config --silence-errors --define-variable=prefix=gtkosx --cflags glib-2.0)

# Utility functions.

objs = $(addsuffix .o, $(filter-out $(2), $(basename $(notdir $(wildcard $(1))))))
curses-objs = $(addsuffix -curses.o, $(basename $(notdir $(1))))
win-objs = $(addprefix win-, $(1))
osx-objs = $(addprefix osx-, $(1))
all-objs = $(1) $(call win-objs, $(1)) $(call osx-objs, $(1))

define build-cxx =
  $(CXX) $(CXXFLAGS) -c $< -o $@
endef
define build-cc =
  $(CC) $(CFLAGS) -c $< -o $@
endef
define build-exe =
  $(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)
endef

# Textadept.

textadept_gtk_objs := $(call objs, textadept.c)
textadept_curses_objs := $(call curses-objs, textadept.c)
textadept_objs := $(textadept_gtk_objs) $(textadept_curses_objs)
textadept_rc_objs := win-textadept_rc.o

ta_flags := -std=c99 -pedantic -Iscintilla/include -Igtdialog -Wall

$(call all-objs, $(textadept_objs)): CFLAGS += $(lua_flags) $(ta_flags)
$(call all-objs, $(textadept_gtk_objs)): CFLAGS += -DGTK $(gtk_flags)
$(call all-objs, $(textadept_curses_objs)): CFLAGS += -DCURSES -Iscintilla/curses -Itermkey -Icdk \
  $(curses_flags)

$(call all-objs, $(textadept_objs)): textadept.c ; $(build-cc)
$(textadept_rc_objs): textadept.rc ; $(WINDRES) $< $@

# Scintilla.

sci_objs := $(call objs, scintilla/src/*.cxx)
sci_lexlib_objs := $(call objs, lexilla/lexlib/*.cxx)
sci_lexer_gtk_objs := $(call objs, Scintillua.cxx)
sci_lexer_curses_objs := $(call curses-objs, Scintillua.cxx)
sci_lexer_objs := $(sci_lexer_gtk_objs) $(sci_lexer_curses_objs)
sci_gtk_objs := $(call objs, scintilla/gtk/*.cxx)
sci_gtk_c_objs := $(call objs, scintilla/gtk/*.c)
sci_curses_objs := $(call objs, scintilla/curses/*.cxx)

sci_flags := -pedantic -DSCI_LEXER -DNDEBUG -Iscintilla/include -Iscintilla/src -Ilexilla/include \
  -Ilexilla/lexlib -Wall

$(call all-objs, $(sci_objs)): CXXFLAGS += $(sci_flags)
$(call all-objs, $(sci_lexlib_objs)): CXXFLAGS += $(sci_flags)
$(call all-objs, $(sci_lexer_objs)): CXXFLAGS += $(sci_flags) $(lua_flags) -DNO_DLL
$(call all-objs, $(sci_lexer_gtk_objs)): CXXFLAGS += -DGTK
$(call all-objs, $(sci_lexer_curses_objs)): CXXFLAGS += -DCURSES $(curses_flags)
$(call all-objs, $(sci_gtk_objs)): CXXFLAGS += $(sci_flags) -DGTK $(gtk_flags)
$(call all-objs, $(sci_gtk_c_objs)): CFLAGS += $(gtk_flags)
$(call all-objs, $(sci_curses_objs)): CXXFLAGS += $(sci_flags) -DCURSES $(curses_flags)

$(sci_objs): %.o: scintilla/src/%.cxx ; $(build-cxx)
$(call win-objs, $(sci_objs)): win-%.o: scintilla/src/%.cxx ; $(build-cxx)
$(call osx-objs, $(sci_objs)): osx-%.o: scintilla/src/%.cxx ; $(build-cxx)
$(sci_lexlib_objs): %.o: lexilla/lexlib/%.cxx ; $(build-cxx)
$(call win-objs, $(sci_lexlib_objs)): win-%.o: lexilla/lexlib/%.cxx ; $(build-cxx)
$(call osx-objs, $(sci_lexlib_objs)): osx-%.o: lexilla/lexlib/%.cxx ; $(build-cxx)
$(call all-objs, $(sci_lexer_objs)): Scintillua.cxx ; $(build-cxx)
$(sci_gtk_objs): %.o: scintilla/gtk/%.cxx ; $(build-cxx)
$(call win-objs, $(sci_gtk_objs)): win-%.o: scintilla/gtk/%.cxx ; $(build-cxx)
$(call osx-objs, $(sci_gtk_objs)): osx-%.o: scintilla/gtk/%.cxx ; $(build-cxx)
$(sci_gtk_c_objs): %.o: scintilla/gtk/%.c ; $(build-cc)
$(call win-objs, $(sci_gtk_c_objs)): win-%.o: scintilla/gtk/%.c ; $(build-cc)
$(call osx-objs, $(sci_gtk_c_objs)): osx-%.o: scintilla/gtk/%.c ; $(build-cc)
$(sci_curses_objs): %.o: scintilla/curses/%.cxx ; $(build-cxx)
$(call win-objs, $(sci_curses_objs)): win-%.o: scintilla/curses/%.cxx ; $(build-cxx)
$(call osx-objs, $(sci_curses_objs)): osx-%.o: scintilla/curses/%.cxx ; $(build-cxx)

# Lua.

lua_objs := $(call objs, lua/src/*.c, lua luac loslib)
lua_oslib_gtk_objs := $(call objs, lua/src/loslib.c)
lua_oslib_curses_objs := $(call curses-objs, loslib.c)
lua_oslib_objs := $(lua_oslib_gtk_objs) $(lua_oslib_curses_objs)
lua_lib_objs := $(call objs, lua/src/lib/*.c)

lua_flags := -Ilua/src

$(call all-objs, $(lua_objs)): CFLAGS += $(lua_flags) -ULUA_LIB
$(call all-objs, $(lua_oslib_objs)): CFLAGS += -std=c99 -pedantic $(lua_flags) -ULUA_LIB
$(call all-objs, $(lua_oslib_gtk_objs)): CFLAGS += -DGTK $(glib_flags)
$(call all-objs, $(lua_lib_objs)): CFLAGS += $(lua_flags)

$(lua_objs): %.o: lua/src/%.c ; $(build-cc)
$(call win-objs, $(lua_objs)): win-%.o: lua/src/%.c ; $(build-cc)
$(call osx-objs, $(lua_objs)): osx-%.o: lua/src/%.c ; $(build-cc)
$(call all-objs, $(lua_oslib_objs)): lua/src/loslib.c ; $(build-cc)
$(lua_lib_objs): %.o: lua/src/lib/%.c ; $(build-cc)
$(call win-objs, $(lua_lib_objs)): win-%.o: lua/src/lib/%.c ; $(build-cc)
$(call osx-objs, $(lua_lib_objs)): osx-%.o: lua/src/lib/%.c ; $(build-cc)

# gtDialog.

gtdialog_gtk_objs := $(call objs, gtdialog/gtdialog.c)
gtdialog_curses_objs := $(call curses-objs, gtdialog/gtdialog.c)
gtdialog_objs := $(gtdialog_gtk_objs) $(gtdialog_curses_objs)

$(call all-objs, $(gtdialog_objs)): CFLAGS += -std=c99 -pedantic -DNOHELP -DLIBRARY
$(call all-objs, $(gtdialog_gtk_objs)): CFLAGS += -DGTK $(gtk_flags)
$(call all-objs, $(gtdialog_curses_objs)): CFLAGS += -DCURSES -I. -Icdk $(curses_flags)

$(call all-objs, $(gtdialog_objs)): gtdialog/gtdialog.c ; $(build-cc)

# Termkey.

termkey_objs := $(call objs, termkey/termkey.c)
termkey_unix_objs := $(call objs, termkey/driver-ti.c termkey/driver-csi.c)
termkey_win_objs := $(call objs, termkey/driver-win-pdcurses.c)
termkey_all_objs := $(termkey_objs) $(termkey_unix_objs) $(termkey_win_objs)

$(call all-objs, $(termkey_all_objs)): CFLAGS += -std=c99 $(curses_flags)

$(termkey_all_objs): %.o: termkey/%.c ; $(build-cc)
$(call win-objs, $(termkey_all_objs)): win-%.o: termkey/%.c ; $(build-cc)
$(call osx-objs, $(termkey_all_objs)): osx-%.o: termkey/%.c ; $(build-cc)

# CDK.
# Only compile a subset of cdk and use a prefix to avoid object name conflicts on case-insensitive
# filesystems.

cdk_src := $(addprefix cdk/, $(addsuffix .c, binding buttonbox cdk cdk_display cdk_objs \
  cdkscreen draw entry fselect itemlist label mentry popup_label scroll scroller select_file \
  selection slider traverse version))
cdk_objs := $(addprefix cdk-, $(call objs, $(cdk_src)))

$(call all-objs, $(cdk_objs)): CFLAGS += -D_GNU_SOURCE -Itermkey -Icdk $(curses_flags)

$(cdk_objs): cdk-%.o: cdk/%.c ; $(build-cc)
$(call win-objs, $(cdk_objs)): win-cdk-%.o: cdk/%.c ; $(build-cc)
$(call osx-objs, $(cdk_objs)): osx-cdk-%.o: cdk/%.c ; $(build-cc)

# Add debugging symbols and disable optimizations when DEBUG=1.
ifdef DEBUG
  CFLAGS += -g -O0
  CXXFLAGS += -g -O0
  lua_flags += -DLUA_USE_APICHECK
  sci_flags += -UNDEBUG -DDEBUG
endif
# And add profiling and code coverage capabilities when PROFILE=1.
ifdef PROFILE
  # Profiling with gprof needs -pg. (LDFLAGS cannot retain symbols either.)
  # Code coverage with gcov needs -fprofile-arcs -ftest-coverage.
  CFLAGS += -pg -fprofile-arcs -ftest-coverage
  CXXFLAGS += -pg
endif

# Compilers and platform-specific flags for all objects.

common_objs := $(sci_objs) $(sci_lexlib_objs) $(lua_objs) $(lua_lib_objs)
gui_objs := $(sci_lexer_gtk_objs) $(sci_gtk_objs) $(sci_gtk_c_objs) $(textadept_gtk_objs) \
  $(lua_oslib_gtk_objs) $(gtdialog_gtk_objs)
curses_objs := $(sci_lexer_curses_objs) $(sci_curses_objs) $(textadept_curses_objs) \
  $(lua_oslib_curses_objs) $(gtdialog_curses_objs) $(termkey_objs) $(cdk_objs)

linux_objs := $(common_objs) $(gui_objs) $(curses_objs) $(termkey_unix_objs)
win_objs := $(call win-objs, $(common_objs) $(gui_objs) $(curses_objs)) $(termkey_win_objs) \
  $(textadept_rc_objs)
osx_objs := $(call osx-objs, $(common_objs) $(gui_objs) $(curses_objs) $(termkey_unix_objs))

# Compile natively for Linux or BSD.
ifeq (Linux, $(shell uname -s))
$(linux_objs): CC := gcc
$(linux_objs): CXX := g++
else
$(linux_objs): CC := cc
$(linux_objs): CXX := c++
endif
$(linux_objs): lua_flags += -DLUA_USE_LINUX
$(linux_objs): gtk_flags := $(gtk_flags_linux)
$(linux_objs): glib_flags := $(glib_flags_linux)
$(linux_objs): curses_flags := $(curses_flags_linux)

# Cross-compile for Windows.
$(win_objs): CC := x86_64-w64-mingw32-gcc-posix
$(win_objs): CXX := x86_64-w64-mingw32-g++-posix
$(win_objs): CFLAGS += -mms-bitfields
$(win_objs): CXXFLAGS += -mms-bitfields
$(win_objs): WINDRES := x86_64-w64-mingw32-windres
$(win_objs): lua_flags += -DLUA_BUILD_AS_DLL -DLUA_LIB
$(win_objs): gtk_flags := $(gtk_flags_win)
$(win_objs): glib_flags := $(glib_flags_win)
$(win_objs): curses_flags := -DLIBICONV_STATIC -Ipdcurses

# Cross-compile for macOS.
$(osx_objs): CC := x86_64-apple-darwin17-cc
$(osx_objs): CXX := x86_64-apple-darwin17-c++
$(osx_objs): CFLAGS += -mdynamic-no-pic
$(osx_objs): CXXFLAGS += -mdynamic-no-pic -stdlib=libc++ -Wno-register
$(osx_objs): lua_flags += -DLUA_USE_MACOSX
$(osx_objs): gtk_flags := $(gtk_flags_osx)
$(osx_objs): glib_flags := $(glib_flags_osx)

# Executables.

linux_exes := $(addprefix ../, textadept textadept-curses)
win_exes := $(addprefix ../, textadept.exe textadept-curses.exe)
osx_exes := $(addprefix ../, textadept-osx textadept-osx-curses)

.PHONY: all curses win osx
.DEFAULT_GOAL := all
all: $(linux_exes)
curses: ../textadept-curses
win: $(win_exes)
osx: $(osx_exes)

# Compile natively for Linux or BSD.

$(linux_exes): $(common_objs)
../textadept: $(gui_objs)
../textadept-curses: $(curses_objs) $(termkey_unix_objs)

ifeq (Linux, $(shell uname -s))
$(linux_exes): CXX := g++
else
$(linux_exes): CXX := c++
endif
$(linux_exes): LDFLAGS := -rdynamic
ifndef PROFILE
$(linux_exes): LDFLAGS += -Wl,--retain-symbols-file -Wl,$(shell pwd)/lua.sym
endif
ifdef GTK2
../textadept: LDFLAGS += $(shell pkg-config --libs gtk+-2.0 gmodule-2.0)
else
../textadept: LDFLAGS += $(shell pkg-config --libs gtk+-3.0 gmodule-2.0)
endif
../textadept-curses: LDFLAGS += $(shell pkg-config --silence-errors --libs ncursesw || \
  pkg-config --silence-errors --libs ncurses || pkg-config --silence-errors --libs curses || \
  echo -lncursesw) -lpthread
ifeq (Linux, $(shell uname -s))
$(linux_exes): LDLIBS := -ldl
else
$(linux_exes): LDLIBS := -liconv
endif
ifdef PROFILE
$(linux_exes): LDLIBS += -lgcov
endif

$(linux_exes): ; $(build-exe)

# Cross-compile for Windows.

$(win_exes): $(call win-objs, $(common_objs)) $(textadept_rc_objs)
../textadept.exe: $(call win-objs, $(gui_objs))
../textadept-curses.exe: $(call win-objs, $(curses_objs)) $(termkey_win_objs)

$(win_exes): CXX := x86_64-w64-mingw32-g++-posix
../textadept.exe: CXXFLAGS += -mwindows
$(win_exes): LDFLAGS := -static-libgcc -static-libstdc++ \
  -Wl,--retain-symbols-file -Wl,$(shell pwd)/lua.sym
../textadept.exe: LDFLAGS += $(shell PKG_CONFIG_PATH=`pwd`/gtkwin/lib/pkgconfig \
  pkg-config --define-variable=prefix=gtkwin --libs gtk+-3.0 gmodule-2.0)
../textadept.exe: LDLIBS := -liconv
../textadept-curses.exe: LDLIBS := pdcurses/pdcurses.a pdcurses/libiconv.dll.a

$(win_exes): ; $(build-exe)

# Cross-compile for macOS.

$(osx_exes): $(call osx-objs, $(common_objs))
../textadept-osx: $(call osx-objs, $(gui_objs))
../textadept-osx-curses: $(call osx-objs, $(curses_objs) $(termkey_unix_objs))

$(osx_exes): CXX := x86_64-apple-darwin17-c++
$(osx_exes): CXXFLAGS += -mdynamic-no-pic -stdlib=libc++ -Wno-register
../textadept-osx: LDFLAGS += $(shell PKG_CONFIG_PATH=`pwd`/gtkosx/lib/pkgconfig \
  pkg-config --define-variable=prefix=gtkosx --libs gtk+-3.0 gmodule-2.0 gtk-mac-integration) \
  -framework Cocoa
$(osx_exes): LDLIBS := -liconv
../textadept-osx-curses: LDLIBS += -lncurses

$(osx_exes): ; $(build-exe)

# Install/uninstall.

PREFIX ?= /usr/local
bin_dir := $(PREFIX)/bin
data_dir := $(PREFIX)/share/textadept
XDG_DATA_DIR ?= $(PREFIX)/share/applications
PIXMAPS_DIR ?= /usr/share/pixmaps
desktop_files := $(wildcard *.desktop)
ifeq (, $(findstring curses, $(MAKECMDGOALS)))
  install_targets := ../textadept
else
  install_targets := ../textadept-curses
endif

.PHONY: install uninstall
install: $(install_targets) | ../core ../docs ../init.lua ../lexers ../LICENSE ../modules ../themes
	install -d $(DESTDIR)$(bin_dir) $(DESTDIR)$(data_dir)
	install $^ $(DESTDIR)$(data_dir)
	cp -rL $| $(DESTDIR)$(data_dir)
	ln -s $(subst .., $(data_dir), $^) $(DESTDIR)$(bin_dir)
	if [ -d "$(XDG_DATA_DIR)" ]; then \
		install -d $(DESTDIR)$(XDG_DATA_DIR); \
		install $(desktop_files) $(DESTDIR)$(XDG_DATA_DIR); \
	fi
	if [ -d "$(PIXMAPS_DIR)" ]; then \
		install -d $(DESTDIR)$(PIXMAPS_DIR); \
		ln -s $(data_dir)/core/images/textadept.svg $(DESTDIR)$(PIXMAPS_DIR); \
		ln -s $(data_dir)/core/images/ta_48x48.png $(DESTDIR)$(PIXMAPS_DIR)/textadept.png; \
	fi
uninstall:
	rm -r $(DESTDIR)$(bin_dir)/textadept* $(DESTDIR)$(data_dir)
	if [ -d "$(XDG_DATA_DIR)" ]; then rm $(DESTDIR)$(XDG_DATA_DIR)/textadept*.desktop; fi
	if [ -d "$(PIXMAPS_DIR)" ]; then rm $(DESTDIR)$(PIXMAPS_DIR)/textadept*; fi

# Clean.

.PHONY: clean clean-win clean-osx clean-all
clean: ; rm -f $(linux_objs) $(linux_exes)
clean-win: ; rm -f $(win_objs) $(win_exes)
clean-osx: ; rm -f $(osx_objs) $(osx_exes)
clean-all: clean clean-win clean-osx

# Documentation.

version := $(shell grep -m 1 _RELEASE ../core/init.lua | cut -d ' ' -f4- | tr ' ' '_' | tr -d "'")

ifndef ALL_MODULES
  modules := $(addprefix ../modules/, ansi_c lua textadept)
else
  modules := ../modules
endif
ta_home := $(shell dirname `pwd`)

.PHONY: docs manual luadoc
docs: luadoc manual
manual: ../docs/api.md $(wildcard ../docs/*.md) | ../docs/_layouts/default.html
	for file in $(basename $^); do cat $| | ../scripts/fill_layout.lua $$file.md > $$file.html; done
	sed -i "s/\(\# Textadept\).\*\?\(Manual\|API\)/\1 $(subst _, ,$(version)) \2/;" ../docs/*.md
luadoc: ../core $(modules) ../lexers/lexer.lua | ../modules/lua/lua.luadoc
	cd ../scripts && luadoc --doclet markdowndoc $^ > ../docs/api.md
	cd ../modules && luadoc -d lua --doclet lua/tadoc $^ --ta-home=$(ta_home)
	cd ../modules/lua && mv tags ta_tags && mv api ta_api
	cd ../modules && luadoc -d lua --doclet lua/tadoc $| --ta-home=$(ta_home)

# Releases.

ifndef NIGHTLY
  basedir := textadept_$(version)
else
  basedir := textadept_nightly_$(shell date +"%F")
endif
linux_dir := $(basedir).linux
win_dir := $(basedir).win
osx_dir := $(basedir).macOS

.PHONY: release release-linux release-win release-osx
release: $(linux_dir).tgz $(win_dir).zip $(osx_dir).zip | deps win-deps osx-deps docs

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = cd ../ && git archive HEAD --prefix src/$(1)/ | tar -xf -
endif

# TODO: CXXFLAGS="$(CXXFLAGS) -static-libstdc++"
$(linux_dir): $(linux_exes)
	$(call archive,$@)
	cp -rL ../docs ../lexers $^ $@
$(linux_dir).tgz: $(linux_dir) ; tar czf $<.tgz $< && rm -r $<

$(win_dir): $(win_exes)
	$(call archive,$@)
	cp gtkwin/bin/*.dll $@ && cp -r $(addprefix gtkwin/, etc lib share) $@
	rm -r $(addprefix $@/lib/, *.a glib-2.0 pkgconfig)
	cp -rL ../docs ../lexers $^ $@
$(win_dir).zip: $(win_dir) ; zip -r $<.zip $< && rm -r $<

osxapp := Textadept.app
osxapp_bin := $(osxapp)/Contents/MacOS
osxapp_res := $(osxapp)/Contents/Resources
$(osxapp): $(osx_exes)
	mkdir -p $(osxapp_bin) $(osxapp_res)
	cp Info.plist $(osxapp_bin)/../
	cp ../textadept-osx $(osxapp_bin)/textadept
	cp ../textadept-osx-curses $(osxapp_bin)/textadept-curses
	cp ../scripts/osx/textadept_osx $(osxapp_bin)
	$(call archive,$(osxapp_res))
	cp -rL ../docs ../lexers $(osxapp_res)
	mv $(osxapp_res)/core/images/textadept.icns $(osxapp_res)
	cp -r $(addprefix gtkosx/, etc lib share) $(osxapp_res)
	rm -r $(addprefix $(osxapp_res)/lib/, glib-2.0 pkgconfig)
	find $(osxapp_res)/lib -type l -delete
$(osx_dir): $(osxapp) ../scripts/osx/ta ; mkdir -p $@ && cp -r $^ $@
$(osx_dir).zip: $(osx_dir) ; zip -r $<.zip $< && rm -r $<

# External dependencies.

.PHONY: deps win-deps osx-deps
base_deps := scintilla lexilla ../lexers Scintillua.h Scintillua.cxx scintilla/curses lua \
  $(addprefix lua/src/lib/, lpeg lfs) gtdialog cdk
deps: $(base_deps) termkey
win-deps: $(base_deps) gtkwin pdcurses
osx-deps: $(base_deps) gtkosx termkey

root_url := https://github.com/orbitalquark

ifndef NIGHTLY
  scinterm_url = $(root_url)/scinterm/archive/$@
  scintillua_url = $(root_url)/scintillua/archive/$@
  gtdialog_url = $(root_url)/gtdialog/archive/$@
else
  scinterm_url := $(root_url)/scinterm/archive/default.zip
  scintillua_url := $(root_url)/scintillua/archive/default.zip
  gtdialog_url := $(root_url)/gtdialog/archive/default.zip
endif

scintilla_tgz := scintilla530.tgz
lexilla_tgz := lexilla510.tgz
scinterm_zip := scinterm_4.0.zip
scintillua_zip := 9088723504b19f8611b66c119933a4dc7939d7b8.zip
lua_tgz := lua-5.4.4.tar.gz
lpeg_tgz := lpeg-1.0.2.tar.gz
lfs_zip := v1_8_0.zip
gtdialog_zip := 444af9ca8a73151dbf759e6676d1035af469f01a.zip
cdk_tgz := cdk-5.0-20200923.tgz
termkey_tgz := libtermkey-0.22.tar.gz
gtkwin_zip := gtkwin-3.24.33.zip
pdcurses_zip := PDCurses-3.9.zip
gtkosx_tgz := gtkosx-3.24.30.tar.gz
cloc_zip := v1.90.zip

$(scintilla_tgz): ; $(WGET) https://www.scintilla.org/$@
scintilla: scintilla.patch | $(scintilla_tgz)
	if [ -d $@/.hg ]; then \
		hg --cwd $@ update -C -r `hg --cwd $@ summary | head -1 | cut -d: -f2`; \
	else \
		if [ -d $@ ]; then rm -r $@; fi; \
		tar xzf $|; \
	fi
	for patch in $^; do echo Applying $$patch; patch -d $@ -N -p1 < $$patch; done
$(lexilla_tgz): ; $(WGET) https://www.scintilla.org/$@
lexilla: | $(lexilla_tgz) ; tar xzf $|
$(scinterm_zip): ; $(WGET) $(scinterm_url) -O $@
scintilla/curses: | $(scinterm_zip)
	unzip -d $@ $| && mv $@/*/* $@
	$(MAKE) -C $@ patch
$(scintillua_zip): ; $(WGET) $(scintillua_url) -O $@
../lexers: | $(scintillua_zip) ; unzip -d $@ -j $| "*/lexers/*" -x "*/themes/*"
Scintillua.h Scintillua.cxx: | $(scintillua_zip) ; unzip -j $| "*/*.cxx" "*/*.h"
$(lua_tgz): ; $(WGET) https://www.lua.org/ftp/$@
$(lpeg_tgz): ; $(WGET) http://www.inf.puc-rio.br/~roberto/lpeg/$@
$(lfs_zip): ; $(WGET) https://github.com/keplerproject/luafilesystem/archive/$@
lua: lua.patch | $(lua_tgz)
	if [ -d $@ ]; then rm -rf $@; fi
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
lua/src/lib/lpeg: lua | $(lpeg_tgz)
	mkdir -p $@ && tar xzf $| -C $@ && mv $@/*/*.c $@/*/*.h $(dir $@)
lua/src/lib/lfs: lua | $(lfs_zip)
	if [ -d $@ ]; then rm -r $@; fi
	mkdir -p $@ && unzip -d $(dir $@) -j $| "*/src/*.c" "*/src/*.h"
$(gtdialog_zip): ; $(WGET) $(gtdialog_url) -O $@
gtdialog: | $(gtdialog_zip) ; unzip -d $@ -j $| "*/*.c" "*/*.h"
$(cdk_tgz): ; $(WGET) https://invisible-mirror.net/archives/cdk/$@
cdk: cdk.patch | $(cdk_tgz)
	if [ -d $@ ]; then rm -r $@; fi
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	mv $@/include/*.h $@
	$@/gen-scale.sh SLIDER Slider Int int $@/gen-slider.h > $@/slider.h
	$@/gen-scale.sh SLIDER Slider Int int $@/gen-slider.c > $@/slider.c
	patch -d $@ -N -p1 < $<
$(termkey_tgz): ; $(WGET) http://www.leonerd.org.uk/code/libtermkey/$@
termkey: termkey.patch | $(termkey_tgz)
	if [ -d $@ ]; then rm -r $@; fi
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@ && chmod +w $@/termkey.h
	patch -d $@ -N -p1 < $<
$(gtkwin_zip): ; $(WGET) $(root_url)/textadept-build/raw/default/$@
gtkwin: | $(gtkwin_zip) ; unzip $|
$(pdcurses_zip): ; $(WGET) http://prdownloads.sourceforge.net/pdcurses/$@
pdcurses: pdcurses.patch | $(pdcurses_zip)
	unzip -d $@ $| && mv $@/PDCurses*/* $@
	cp gtkwin/include/iconv.h gtkwin/lib/libiconv.dll.a $@
	patch -d $@ -N -p1 < $<
	# TODO: parameterize CROSS, CC, and CFLAGS.
	cd $@/wincon && $(MAKE) CC="x86_64-w64-mingw32-gcc-posix -Os -mms-bitfields" \
		LIBEXE=x86_64-w64-mingw32-ar LINK="x86_64-w64-mingw32-gcc-posix -Os -mms-bitfields" WIDE=Y \
		UTF8=Y libs
	mv $@/wincon/pdcurses.a $@
$(gtkosx_tgz): ; $(WGET) $(root_url)/textadept-build/raw/default/$@
gtkosx: gtkosx.patch | $(gtkosx_tgz)
	if [ -d $@ ]; then rm -r $@; fi
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	patch -d $@ -N -p1 < $<
$(cloc_zip): ; $(WGET) https://github.com/AlDanial/cloc/archive/refs/tags/$@
cloc: | $(cloc_zip) ; unzip -j $| "*/$@" -x "*/Unix/$@"

.PHONY: clean-deps
clean-deps:
	rm -rf $(base_deps) termkey gtkwin pdcurses gtkosx $(scinterm_zip) $(scintillua_zip) \
		$(gtdialog_zip)

# Count lines of code.

.PHONY: count plots
sources := ../core ../modules/ansi_c ../modules/lua ../modules/textadept textadept.c Makefile \
  ../init.lua
count: cloc ; perl $< $(sources) --not-match-f=tadoc.lua --exclude-lang=SVG
plots: ; ../scripts/gen_plots.sh

# Profiling, code coverage, and linting.

.PHONY: gprof gcov luacov lint

define profile =
	rm -f $(addsuffix .o, $(notdir $(linux_exes)))
	$(MAKE) DEBUG=1 PROFILE=1 GTK2=1
	for exe in $(linux_exes); do xterm -e $$exe -n -f $(1); $(2); done
	rm $(addsuffix .o, $(notdir $(linux_exes))) *.gcno *.gcda
	$(MAKE) DEBUG=1 GTK2=1
endef
run-tests = -t $(1) -e 'events.connect(events.INITIALIZED, os.exit)'

EDITOR := $(word 1, $(linux_exes)) -n -f
gprof:
	$(call profile, -e 'os.exit', gprof $$exe gmon.out | $(EDITOR) -e 'set_text(io.read("a"))')
	rm gmon.out
gcov:
	$(call profile, $(call run-tests, -interactive), gcov `basename $$exe`.c)
	$(EDITOR) textadept.c.gcov
luacov: $(linux_exes)
	rm -f luacov.*.out
	sed -i 's/^-- for/for/;' ../core/init.lua
	xterm -e $(word 1, $(linux_exes)) -n -f $(call run-tests, -locale)
	xterm -e $(word 2, $(linux_exes)) -n -f $(call run-tests, -interactive)
	sed -i 's/^for/-- for/;' ../core/init.lua
	$(EDITOR) luacov.report.out
lint: ../core $(modules) ../lexers/lexer.lua ../test/test.lua | ../modules/lua/ta_api
	luacheck --std lua54 --no-max-line-length --no-color $^ \
		--globals $(shell grep -o '_G\.[[:alnum:]_]\+' $| | cut -d. -f2 | uniq | tr '\n' ' ') lpeg \
		$(shell grep -o 'function test_[[:alnum:]_]\+' ../test/test.lua | cut -d ' ' -f2 | uniq | tr '\n' ' ')

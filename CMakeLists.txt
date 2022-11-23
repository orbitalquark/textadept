# Copyright 2022 Mitchell. See LICENSE.

cmake_minimum_required(VERSION 3.16)

set(ta ${CMAKE_SOURCE_DIR})

# Dependencies.
include(FetchContent)
set(FETCHCONTENT_QUIET off)
FetchContent_Declare(scintilla
  URL https://www.scintilla.org/scintilla530.tgz
  PATCH_COMMAND patch -N -p1 < ${ta}/src/scintilla.patch)
FetchContent_MakeAvailable(scintilla)
FetchContent_Declare(lexilla URL https://www.scintilla.org/lexilla510.tgz)
FetchContent_MakeAvailable(lexilla)
if(NOT DEFINED ENV{NIGHTLY})
  set(scinterm_zip scinterm_4.0.zip)
  set(scintillua_zip scintillua_6.0.zip)
else()
  set(scinterm_zip default.zip)
  set(scintillua_zip default.zip)
endif()
FetchContent_Declare(scinterm URL https://github.com/orbitalquark/scinterm/archive/${scinterm_zip})
FetchContent_MakeAvailable(scinterm)
FetchContent_Declare(scintillua
  URL https://github.com/orbitalquark/scintillua/archive/${scintillua_zip})
FetchContent_MakeAvailable(scintillua)
FetchContent_Declare(lua
  URL https://www.lua.org/ftp/lua-5.4.4.tar.gz
  PATCH_COMMAND patch -N -p1 < ${ta}/src/lua.patch)
FetchContent_MakeAvailable(lua)
FetchContent_Declare(lpeg URL http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.2.tar.gz)
FetchContent_MakeAvailable(lpeg)
FetchContent_Declare(lfs URL https://github.com/keplerproject/luafilesystem/archive/v1_8_0.zip)
FetchContent_MakeAvailable(lfs)
FetchContent_Declare(cdk URL https://invisible-mirror.net/archives/cdk/cdk-5.0-20200923.tgz)
FetchContent_GetProperties(cdk)
if(NOT cdk_POPULATED)
  FetchContent_Populate(cdk)
  set(cdk_dir ${cdk_SOURCE_DIR})
  if(NOT EXISTS ${cdk_dir}/slider.c)
    execute_process(
      COMMAND ${cdk_dir}/gen-scale.sh SLIDER Slider Int int ${cdk_dir}/include/gen-slider.h
      OUTPUT_FILE ${cdk_dir}/include/slider.h)
    execute_process(COMMAND ${cdk_dir}/gen-scale.sh SLIDER Slider Int int ${cdk_dir}/gen-slider.c
      OUTPUT_FILE ${cdk_dir}/slider.c)
    execute_process(COMMAND patch -d ${cdk_dir} -N -p1 INPUT_FILE ${ta}/src/cdk.patch)
  endif()
endif()
if(UNIX)
  FetchContent_Declare(termkey
    URL http://www.leonerd.org.uk/code/libtermkey/libtermkey-0.22.tar.gz
    PATCH_COMMAND patch -N -p1 < ${ta}/src/termkey.patch)
  FetchContent_MakeAvailable(termkey)
endif()
if(WIN32)
  FetchContent_Declare(pdcurses
    URL http://prdownloads.sourceforge.net/pdcurses/PDCurses-3.9.zip
    PATCH_COMMAND patch -N -p1 < ${ta}/src/pdcurses.patch)
  FetchContent_MakeAvailable(pdcurses)
endif()
set(FETCHCONTENT_UPDATES_DISCONNECTED on CACHE BOOL "Do not update deps if already set up")

project(textadept LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED true)

# Determine available platforms.
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
  pkg_check_modules(GTK3 gtk+-3.0)
  if(GTK3_FOUND)
    set(plat_gtk3 on CACHE BOOL "Build Textadept using Gtk 3")
  endif()
  pkg_check_modules(GTK2 gtk+-2.0)
  if(GTK2_FOUND)
    set(plat_gtk2 on CACHE BOOL "Build Textadept using Gtk 2")
  endif()
  pkg_search_module(CURSES ncursesw ncurses curses)
endif()
find_package(Qt5 COMPONENTS Widgets)
if(Qt5_FOUND)
  set(plat_qt on CACHE BOOL "Build Textadept using Qt")
endif()
if(CURSES_FOUND OR WIN32 OR APPLE)
  set(plat_curses on CACHE BOOL "Build Textadept using Curses")
endif()
if(NOT (plat_gtk3 OR plat_gtk2 OR plat_qt OR plat_curses))
  message(FATAL_ERROR "No suitable platform found.")
endif()

# Setup platform requirements.
if(plat_gtk3 OR plat_gtk2)
  pkg_search_module(GTK REQUIRED gtk+-3.0 gtk+-2.0)
endif()
if(plat_qt)
  find_package(Qt5 COMPONENTS Widgets REQUIRED)
  set(CMAKE_AUTOMOC on)
  set(CMAKE_AUTOUIC on)
else()
  set(CMAKE_AUTOMOC off)
  set(CMAKE_AUTOUIC off)
endif()
if(plat_curses)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(CURSES REQUIRED ncursesw ncurses curses)
  elseif(WIN32)
    set(CURSES_LIBRARIES pdcurses) # TODO: iconv
  elseif(APPLE)
    set(CURSES_LIBRARIES ncurses iconv)
  endif()
endif()
find_package(Threads REQUIRED)

# Scintilla core.
add_library(scintilla STATIC)
set(sci_dir ${scintilla_SOURCE_DIR})
file(GLOB sci_src ${sci_dir}/src/*.cxx)
target_sources(scintilla PRIVATE ${sci_src})
target_include_directories(scintilla PUBLIC ${sci_dir}/include ${sci_dir}/src)
target_compile_definitions(scintilla PUBLIC SCI_LEXER)
target_link_libraries(scintilla PRIVATE Threads::Threads)

# Scintilla platform.
if(plat_gtk3 OR plat_gtk2)
  add_library(scintilla_gtk STATIC)
  set(sci_gtk_dir ${sci_dir}/gtk)
  file(GLOB sci_gtk_src ${sci_gtk_dir}/*.c ${sci_gtk_dir}/*.cxx)
  target_sources(scintilla_gtk PRIVATE ${sci_gtk_src})
  target_include_directories(scintilla_gtk PUBLIC ${sci_gtk_dir} ${GTK_INCLUDE_DIRS})
  target_compile_definitions(scintilla_gtk PUBLIC GTK)
  target_compile_options(scintilla_gtk PUBLIC -Wno-deprecated-declarations)
  target_link_directories(scintilla_gtk PRIVATE ${GTK_LIBRARY_DIRS})
  target_link_libraries(scintilla_gtk PUBLIC scintilla PRIVATE ${GTK_LIBRARIES})
endif()
if(plat_qt)
  add_library(scintilla_qt STATIC)
  set(sci_qt_dir ${sci_dir}/qt/ScintillaEditBase)
  file(GLOB sci_qt_src ${sci_qt_dir}/*.cpp)
  target_sources(scintilla_qt PRIVATE ${sci_qt_src})
  target_include_directories(scintilla_qt PUBLIC ${sci_qt_dir})
  target_compile_definitions(scintilla_qt PUBLIC SCINTILLA_QT)
  target_link_libraries(scintilla_qt PUBLIC scintilla PRIVATE Qt5::Widgets)
endif()
if(plat_curses)
  add_library(scintilla_curses STATIC)
  set(sci_curses_dir ${scinterm_SOURCE_DIR})
  file(GLOB sci_curses_src ${sci_curses_dir}/*.cxx)
  target_sources(scintilla_curses PRIVATE ${sci_curses_src})
  target_include_directories(scintilla_curses PUBLIC ${sci_curses_dir} ${CURSES_INCLUDE_DIRS})
  target_compile_definitions(scintilla_curses PUBLIC CURSES)
  target_link_directories(scintilla_curses PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(scintilla_curses PUBLIC scintilla PRIVATE ${CURSES_LIBRARIES})
endif()

# Lexilla.
add_library(lexilla STATIC)
set(lex_dir ${lexilla_SOURCE_DIR})
file(GLOB lex_src ${lex_dir}/lexlib/*.cxx)
target_sources(lexilla PRIVATE ${lex_src})
target_include_directories(lexilla PUBLIC ${lex_dir}/lexlib PRIVATE ${lex_dir}/include)
target_link_libraries(lexilla PRIVATE scintilla)

# Scintillua.
add_library(scintillua STATIC)
set(scilua_dir ${scintillua_SOURCE_DIR})
target_sources(scintillua PRIVATE ${scilua_dir}/Scintillua.cxx)
target_include_directories(scintillua PUBLIC ${scilua_dir})
target_compile_definitions(scintillua PRIVATE NO_DLL)
target_compile_options(scintillua PRIVATE -pedantic -Wall)
target_link_libraries(scintillua PRIVATE scintilla lexilla lua)

# Lua.
add_library(lua STATIC)
set(lua_dir ${lua_SOURCE_DIR})
file(GLOB lua_src ${lua_dir}/src/*.c)
list(FILTER lua_src EXCLUDE REGEX "(lua|luac)\.c$")
target_include_directories(lua PUBLIC ${lua_dir}/src)
if(WIN32)
  set(lua_plat_define LUA_BUILD_AS_DLL)
elseif(APPLE)
  set(lua_plat_define LUA_USE_MACOSX)
else()
  set(lua_plat_define LUA_USE_LINUX)
endif()
target_sources(lua PRIVATE ${lua_src})
target_compile_definitions(lua PRIVATE ${lua_plat_define} $<$<CONFIG:Debug>:LUA_USE_APICHECK>)
target_link_libraries(lua PRIVATE dl)

# LPeg.
add_library(lpeg STATIC)
set(lpeg_dir ${lpeg_SOURCE_DIR})
file(GLOB lpeg_src ${lpeg_dir}/*.c)
target_sources(lpeg PRIVATE ${lpeg_src})
target_link_libraries(lpeg PRIVATE lua)

# LFS.
add_library(lfs STATIC)
set(lfs_dir ${lfs_SOURCE_DIR})
file(GLOB lfs_src ${lfs_dir}/src/*.c)
target_sources(lfs PRIVATE ${lfs_src})
target_link_libraries(lfs PRIVATE lua)

if(plat_curses)
  # PDCurses.
  if(WIN32)
    add_library(pdcurses STATIC)
    set(pdcurses_dir ${pdcurses_SOURCE_DIR})
    file(GLOB pdcurses_src ${pdcurses_dir}/wincon/*.c)
    target_sources(pdcurses PRIVATE ${pdcurses_src})
    target_include_directories(pdcurses PUBLIC ${pdcurses_dir} PRIVATE ${pdcurses_dir}/wincon)
    target_compile_definitions(pdcurses PRIVATE PDC_WIDE PDC_FORCE_UTF8)
  endif()

  # Termkey.
  add_library(termkey STATIC)
  set(termkey_dir ${termkey_SOURCE_DIR})
  set(termkey_src ${termkey_dir}/termkey.c)
  if(UNIX)
    list(APPEND termkey_src ${termkey_dir}/driver-ti.c ${termkey_dir}/driver-csi.c)
  elseif(WIN32)
    list(APPEND termkey_src ${termkey_dir}/driver-win-pdcurses.c)
  endif()
  target_sources(termkey PRIVATE ${termkey_src})
  target_include_directories(termkey PUBLIC ${termkey_dir})
  target_link_directories(termkey PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(termkey PRIVATE ${CURSES_LIBRARIES})

  # CDK.
  add_library(cdk STATIC)
  set(cdk_dir ${cdk_SOURCE_DIR})
  set(cdk_src binding buttonbox cdk cdk_display cdk_objs cdkscreen dialog draw entry fselect
    itemlist label mentry popup_label scroll scroller select_file selection slider traverse version)
  list(TRANSFORM cdk_src APPEND .c)
  list(TRANSFORM cdk_src PREPEND ${cdk_dir}/)
  target_sources(cdk PRIVATE ${cdk_src})
  target_include_directories(cdk PUBLIC ${cdk_dir} ${cdk_dir}/include)
  if(WIN32)
    target_compile_definitions(cdk PRIVATE LIBICONV_STATIC)
  endif()
  target_link_directories(cdk PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(cdk PRIVATE termkey ${CURSES_LIBRARIES})
endif()

set(CMAKE_ENABLE_EXPORTS on)

# Textadept core.
set(ta_src src/textadept.c)
set(ta_compile_opts -pedantic -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers
  -Wno-deprecated-declarations)
set(ta_link_libs scintilla scintillua lua lpeg lfs)

# Textadept Gtk.
if(plat_gtk3 OR plat_gtk2)
  add_library(textadept_gtk STATIC)
  target_sources(textadept_gtk PRIVATE src/textadept_gtk.c)
  target_include_directories(textadept_gtk PRIVATE ${GTK_INCLUDE_DIRS})
  target_compile_options(textadept_gtk PRIVATE ${ta_compile_opts})
  target_link_directories(textadept_gtk PRIVATE ${GTK_LIBRARY_DIRS})
  target_link_libraries(textadept_gtk PRIVATE scintilla_gtk lua ${GTK_LIBRARIES})

  add_executable(textadept)
  target_sources(textadept PRIVATE ${ta_src})
  target_link_libraries(textadept PRIVATE ${ta_link_libs} textadept_gtk)
endif()

# Textadept Qt.
if(plat_qt)
  add_library(textadept_qt STATIC)
  target_sources(textadept_qt PRIVATE src/textadept_qt.cpp src/textadept_qt.ui)
  target_compile_definitions(textadept_qt PRIVATE QT_NO_KEYWORDS)
  target_compile_options(textadept_qt PRIVATE ${ta_compile_opts})
  target_link_libraries(textadept_qt PRIVATE scintilla_qt lua Qt5::Widgets)

  add_executable(textadept-qt)
  target_sources(textadept-qt PRIVATE ${ta_src})
  target_link_libraries(textadept-qt PRIVATE ${ta_link_libs} textadept_qt)
endif()

# Textadept Curses.
if(plat_curses)
  add_library(textadept_curses STATIC)
  target_sources(textadept_curses PRIVATE src/textadept_curses.c)
  target_include_directories(textadept_curses PRIVATE ${CURSES_INCLUDE_DIRS})
  target_compile_options(textadept_curses PRIVATE ${ta_compile_opts})
  target_link_directories(textadept_curses PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(textadept_curses
    PRIVATE scintilla_curses lua termkey cdk ${CURSES_LIBRARIES})

  add_executable(textadept-curses)
  target_sources(textadept-curses PRIVATE ${ta_src})
  target_link_libraries(textadept-curses PRIVATE ${ta_link_libs} textadept_curses)
endif()

# Version information.
file(STRINGS ${ta}/core/init.lua version_line REGEX ^_RELEASE)
string(REGEX MATCH "[1-9][^']+" version ${version_line})
if(NOT DEFINED ENV{NIGHTLY})
  string(REPLACE " " _ version_ ${version})
else()
  string(TIMESTAMP version_ nightly_%Y-%m-%d)
endif()
if(NOT (WIN32 OR APPLE))
  string(APPEND version_ .linux)
elseif(WIN32)
  string(APPEND version_ .win)
elseif(APPLE)
  string(APPEND version_.macOS)
endif()

# Install/release.
if(NOT (WIN32 OR APPLE))
  include(GNUInstallDirs)
  set(ta_bin_dir ${CMAKE_INSTALL_FULL_BINDIR})
  install(CODE "file(MAKE_DIRECTORY ${ta_bin_dir})")
  set(ta_data_dir ${CMAKE_INSTALL_FULL_DATADIR}/textadept)
  if(plat_gtk3 OR plat_gtk2)
    install(TARGETS textadept DESTINATION ${ta_data_dir})
    install(CODE "file(CREATE_LINK ${ta_data_dir}/textadept ${ta_bin_dir}/textadept SYMBOLIC)")
    install(FILES src/textadept.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  endif()
  if(plat_qt)
    install(TARGETS textadept-qt DESTINATION ${ta_data_dir})
    install(CODE "file(CREATE_LINK ${ta_data_dir}/textadept-qt
      ${ta_bin_dir}/textadept-qt SYMBOLIC)")
    install(FILES src/textadept-qt.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  endif()
  if(plat_curses)
    install(TARGETS textadept-curses DESTINATION ${ta_data_dir})
    install(CODE "file(CREATE_LINK ${ta_data_dir}/textadept-curses
      ${ta_bin_dir}/textadept-curses SYMBOLIC)")
    install(FILES src/textadept-curses.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  endif()
  install(FILES init.lua LICENSE DESTINATION ${ta_data_dir})
  install(DIRECTORY core docs ${scilua_dir}/lexers modules themes DESTINATION ${ta_data_dir})
  install(FILES core/images/textadept.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
  install(CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar czf ${CMAKE_BINARY_DIR}/textadept_${version_}.tgz textadept
    WORKING_DIRECTORY ${CMAKE_INSTALL_FULL_DATADIR})")
elseif(WIN32)
  set(ta_dir ${CMAKE_INSTALL_PREFIX}/textadept)
  install(TARGETS textadept-qt DESTINATION ${ta_dir} RENAME textadept)
  install(TARGETS textadept-curses DESTINATION ${ta_dir})
  install(FILES init.lua LICENSE DESTINATION ${ta_dir})
  install(DIRECTORY core docs ${scilua_dir}/lexers modules themes DESTINATION ${ta_dir})
  install(CODE "execute_process(COMMAND windeploy-qt ${ta_dir})")
  install(CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/textadept_${version_}.zip --format=zip
      textadept
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})")
elseif(APPLE)
  set(ta_bin_dir ${CMAKE_INSTALL_PREFIX}/Textadept.app/Contents/MacOS)
  set(ta_data_dir ${CMAKE_INSTALL_PREFIX}/Textadept.app/Contents/Resources)
  install(TARGETS textadept-qt DESTINATION ${ta_bin_dir} RENAME textadept)
  install(TARGETS textadept-curses DESTINATION ${ta_bin_dir})
  install(FILES scripts/osx/textadept_osx DESTINATION ${ta_bin_dir})
  install(FILES init.lua LICENSE DESTINATION ${ta_data_dir})
  install(DIRECTORY core docs ${scilua_dir}/lexers modules themes DESTINATION ${ta_data_dir})
  install(CODE "file(RENAME ${ta_data_dir}/core/images/textadept.icns
    ${ta_data_dir}/textadept.icns)")
  install(CODE "execute_process(COMMAND macdeployqt ${CMAKE_INSTALL_PREFIX}/Textadept.app)")
  install(CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/textadept_${version_}.zip --format=zip
      Textadept.app ${ta}/scripts/osx/ta
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})")
endif()

# Documentation.
file(GLOB ta_md_docs docs/*.md)
add_custom_target(docs DEPENDS manual luadoc)
add_custom_target(manual DEPENDS luadoc
  COMMAND for file in `basename -a -s .md ${ta_md_docs}`\; do
    cat _layouts/default.html | ../scripts/fill_layout.lua $$file.md > $$file.html\; done
  COMMAND sed -i "\"s/\\(\\# Textadept\\).\\*\\?\\(Manual\\|API\\)/\\1 ${version} \\2/;\""
    ${ta_md_docs}
  DEPENDS ${ta_md_docs}
  WORKING_DIRECTORY ${ta}/docs)
add_custom_target(luadoc DEPENDS docs/api.md modules/lua/tags modules/lua/api
  modules/lua/ta_tags modules/lua/ta_api)
file(GLOB ta_lua_src core modules/ansi_c modules/lua modules/textadept
  ${scilua_dir}/lexers/lexer.lua)
add_custom_command(OUTPUT ${ta}/docs/api.md
  COMMAND luadoc --doclet markdowndoc ${ta_lua_src} > ${ta}/docs/api.md
  DEPENDS ${ta_lua_src}
  WORKING_DIRECTORY ${ta}/scripts
  VERBATIM)
add_custom_command(
  OUTPUT ${ta}/modules/lua/tags ${ta}/modules/lua/api ${ta}/modules/lua/ta_tags
    ${ta}/modules/lua/ta_api
  COMMAND luadoc -d . --doclet tadoc ${ta_lua_src} --ta-home=${ta}
  COMMAND mv tags ta_tags COMMAND mv api ta_api
  COMMAND luadoc -d . --doclet tadoc lua.luadoc --ta-home=${ta}
  DEPENDS ${ta_lua_src} modules/lua/lua.luadoc
  WORKING_DIRECTORY ${ta}/modules/lua
  VERBATIM)

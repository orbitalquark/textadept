# Copyright 2022 Mitchell. See LICENSE.

cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "")
endif()

set(ta ${CMAKE_SOURCE_DIR})

# Dependencies.
include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
# Scintilla.
set(deps_dir ${CMAKE_BINARY_DIR}/_deps)
set(scintilla_tgz scintilla530.tgz)
set(scintilla_url file://${deps_dir}/${scintilla_tgz})
if(NOT EXISTS ${deps_dir}/${scintilla_tgz})
  set(scintilla_url https://www.scintilla.org/${scintilla_tgz})
endif()
FetchContent_Declare(scintilla
  URL ${scintilla_url}
  PATCH_COMMAND patch -N -p1 < ${ta}/src/scintilla.patch)
FetchContent_MakeAvailable(scintilla)
# Lexilla.
set(lexilla_tgz lexilla510.tgz)
set(lexilla_url file://${deps_dir}/${lexilla_tgz})
if(NOT EXISTS ${deps_dir}/${lexilla_tgz})
  set(lexilla_url https://www.scintilla.org/${lexilla_tgz})
endif()
FetchContent_Declare(lexilla URL ${lexilla_url})
FetchContent_MakeAvailable(lexilla)
# Scinterm.
set(scinterm_zip scinterm_4.0.zip)
set(scinterm_url file://${deps_dir}/${scinterm_zip})
if(NIGHTLY)
  set(scinterm_zip default.zip)
endif()
if(NIGHTLY OR NOT EXISTS ${deps_dir}/${scinterm_zip})
  set(scinterm_url https://github.com/orbitalquark/scinterm/archive/${scinterm_zip})
endif()
FetchContent_Declare(scinterm URL ${scinterm_url})
FetchContent_MakeAvailable(scinterm)
# Scintillua.
set(scintillua_zip scintillua_6.0.zip)
set(scintillua_url file://${deps_dir}/${scintillua_zip})
if(NIGHTLY)
  set(scintillua_zip default.zip)
endif()
if(NIGHTLY OR NOT EXISTS ${deps_dir}/${scintillua_zip})
  set(scintillua_url https://github.com/orbitalquark/scintillua/archive/${scintillua_zip})
endif()
FetchContent_Declare(scintillua URL ${scintillua_url})
FetchContent_MakeAvailable(scintillua)
# Lua.
set(lua_tgz lua-5.4.4.tar.gz)
set(lua_url file://${deps_dir}/${lua_tgz})
if(NOT EXISTS ${deps_dir}/${lua_tgz})
  set(lua_url https://www.lua.org/ftp/${lua_tgz})
endif()
FetchContent_Declare(lua URL ${lua_url} PATCH_COMMAND patch -N -p1 < ${ta}/src/lua.patch)
FetchContent_MakeAvailable(lua)
# LPeg.
set(lpeg_tgz lpeg-1.0.2.tar.gz)
set(lpeg_url file://${deps_dir}/${lpeg_tgz})
if(NOT EXISTS ${deps_dir}/${lpeg_tgz})
  set(lpeg_url http://www.inf.puc-rio.br/~roberto/lpeg/${lpeg_tgz})
endif()
FetchContent_Declare(lpeg URL ${lpeg_url})
FetchContent_MakeAvailable(lpeg)
# LFS.
set(lfs_zip v1_8_0.zip)
set(lfs_url file://${deps_dir}/${lfs_zip})
if(NOT EXISTS ${deps_dir}/${lfs_zip})
  set(lfs_url https://github.com/keplerproject/luafilesystem/archive/${lfs_zip})
endif()
FetchContent_Declare(lfs URL ${lfs_url})
FetchContent_MakeAvailable(lfs)
# CDK.
set(cdk_tgz cdk-5.0-20200923.tgz)
set(cdk_url file://${deps_dir}/${cdk_tgz})
if(NOT EXISTS ${deps_dir}/${cdk_tgz})
  set(cdk_url https://invisible-mirror.net/archives/cdk/${cdk_tgz})
endif()
FetchContent_Declare(cdk URL ${cdk_url} PATCH_COMMAND patch -N -p1 < ${ta}/src/cdk.patch)
FetchContent_MakeAvailable(cdk)
# Termkey.
set(cdk_tgz libtermkey-0.22.tar.gz)
set(cdk_url file://${deps_dir}/${cdk_tgz})
if(NOT EXISTS ${deps_dir}/${cdk_tgz})
  set(cdk_url http://www.leonerd.org.uk/code/libtermkey/${cdk_tgz})
endif()
FetchContent_Declare(termkey URL ${cdk_url} PATCH_COMMAND patch -N -p1 < ${ta}/src/termkey.patch)
FetchContent_MakeAvailable(termkey)
if(WIN32)
  # PDCurses.
  set(pdcurses_zip PDCurses-3.9.zip)
  set(pdcurses_url file://${deps_dir}/${pdcurses_zip})
  if(NOT EXISTS ${deps_dir}/${pdcurses_zip})
    set(pdcurses_url http://prdownloads.sourceforge.net/pdcurses/${pdcurses_zip})
  endif()
  FetchContent_Declare(pdcurses
    URL ${pdcurses_url}
    PATCH_COMMAND patch -N -p1 < ${ta}/src/pdcurses.patch)
  FetchContent_MakeAvailable(pdcurses)
  # iconv.
  set(iconv_tgz libiconv-1.17.tar.gz)
  set(iconv_url file://${deps_dir}/${iconv_tgz})
  if(NOT EXISTS ${deps_dir}/${iconv_tgz})
    set(iconv_url https://ftp.gnu.org/pub/gnu/libiconv/${iconv_tgz})
  endif()
  FetchContent_Declare(iconv URL ${iconv_url} PATCH_COMMAND patch -N -p1 < ${ta}/src/iconv.patch)
  FetchContent_MakeAvailable(iconv)
endif()
set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL "Do not update deps if already set up")

project(textadept LANGUAGES C CXX)

# Determine available platforms.
find_package(Qt5 COMPONENTS Widgets)
if(Qt5_FOUND)
  set(QT ON CACHE BOOL "Build Textadept using Qt")
endif()
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
  pkg_check_modules(GTK3 gtk+-3.0)
  if(GTK3_FOUND)
    set(GTK3 ON CACHE BOOL "Build Textadept using Gtk 3")
  endif()
  pkg_check_modules(GTK2 gtk+-2.0)
  if(GTK2_FOUND)
    set(GTK2 ON CACHE BOOL "Build Textadept using Gtk 2")
  endif()
  pkg_search_module(CURSES ncursesw ncurses curses)
endif()
if(CURSES_FOUND OR WIN32 OR APPLE)
  set(CURSES ON CACHE BOOL "Build Textadept using Curses")
endif()
if(NOT (QT OR GTK3 OR GTK2 OR CURSES))
  message(FATAL_ERROR "No suitable platform found.")
endif()

# Setup platform requirements.
if(QT)
  find_package(Qt5 COMPONENTS Widgets REQUIRED)
  set(CMAKE_AUTOMOC ON)
  set(CMAKE_AUTOUIC ON)
else()
  set(CMAKE_AUTOMOC OFF)
  set(CMAKE_AUTOUIC OFF)
endif()
if(GTK3 OR GTK2)
  pkg_search_module(GTK REQUIRED gtk+-3.0 gtk+-2.0)
endif()
if(CURSES)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(CURSES REQUIRED ncursesw ncurses curses)
  elseif(WIN32)
    set(CURSES_LIBRARIES pdcurses)
  elseif(APPLE)
    set(CURSES_LIBRARIES ncurses)
  endif()
endif()
find_package(Threads REQUIRED)

# Scintilla core.
add_library(scintilla STATIC)
set(sci_dir ${scintilla_SOURCE_DIR})
file(GLOB sci_src ${sci_dir}/src/*.cxx)
target_sources(scintilla PRIVATE ${sci_src})
target_include_directories(scintilla PUBLIC ${sci_dir}/include PRIVATE ${sci_dir}/src)
target_compile_definitions(scintilla PUBLIC SCI_LEXER)
if(WIN32)
  target_compile_options(scintilla PRIVATE /EHsc)
endif()
target_link_libraries(scintilla PRIVATE Threads::Threads)

# Scintilla platform.
if(QT)
  add_library(scintilla_qt STATIC)
  set(sci_qt_dir ${sci_dir}/qt/ScintillaEditBase)
  file(GLOB sci_qt_src ${sci_qt_dir}/*.cpp)
  target_sources(scintilla_qt PRIVATE ${sci_qt_src})
  target_include_directories(scintilla_qt PUBLIC ${sci_qt_dir} ${sci_dir}/src)
  target_compile_definitions(scintilla_qt PUBLIC SCINTILLA_QT)
  target_link_libraries(scintilla_qt PUBLIC scintilla PRIVATE Qt5::Widgets)
endif()
if(GTK3 OR GTK2)
  add_library(scintilla_gtk STATIC)
  set(sci_gtk_dir ${sci_dir}/gtk)
  file(GLOB sci_gtk_src ${sci_gtk_dir}/*.c ${sci_gtk_dir}/*.cxx)
  target_sources(scintilla_gtk PRIVATE ${sci_gtk_src})
  target_include_directories(scintilla_gtk
    PUBLIC ${sci_gtk_dir}
    PRIVATE ${sci_dir}/src ${GTK_INCLUDE_DIRS})
  target_compile_definitions(scintilla_gtk PUBLIC GTK)
  target_compile_options(scintilla_gtk PUBLIC -Wno-deprecated-declarations)
  target_link_directories(scintilla_gtk PRIVATE ${GTK_LIBRARY_DIRS})
  target_link_libraries(scintilla_gtk PUBLIC scintilla PRIVATE ${GTK_LIBRARIES})
endif()
if(CURSES)
  add_library(scintilla_curses STATIC)
  set(sci_curses_dir ${scinterm_SOURCE_DIR})
  file(GLOB sci_curses_src ${sci_curses_dir}/*.cxx)
  target_sources(scintilla_curses PRIVATE ${sci_curses_src})
  target_include_directories(scintilla_curses
    PUBLIC ${sci_curses_dir}
    PRIVATE ${sci_dir}/src ${CURSES_INCLUDE_DIRS})
  target_compile_definitions(scintilla_curses PUBLIC CURSES)
  if(NOT WIN32)
    target_compile_options(scintilla_curses PRIVATE -pedantic -Wall)
  else()
    target_compile_options(scintilla_curses PRIVATE /W4)
  endif()
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
if(NOT WIN32)
  target_compile_options(scintillua PRIVATE -pedantic -Wall)
elseif(WIN32)
  target_compile_options(scintillua PRIVATE /W4 /EHsc)
endif()
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
if(NOT (WIN32 OR APPLE))
  target_link_libraries(lua PRIVATE dl)
endif()

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

if(CURSES)
  # PDCurses.
  if(WIN32)
    add_library(pdcurses STATIC)
    set(pdcurses_dir ${pdcurses_SOURCE_DIR})
    file(GLOB pdcurses_src ${pdcurses_dir}/pdcurses/*.c ${pdcurses_dir}/wincon/*.c)
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
  target_include_directories(cdk PUBLIC ${cdk_dir}/include)
  target_link_directories(cdk PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(cdk PRIVATE termkey ${CURSES_LIBRARIES})
endif()

# iconv
if(WIN32)
  add_library(iconv SHARED)
  set(iconv_dir ${iconv_SOURCE_DIR})
  target_sources(iconv
    PRIVATE ${iconv_dir}/lib/iconv.c ${iconv_dir}/lib/relocatable.c
      ${iconv_dir}/libcharset/lib/localcharset.c ${iconv_dir}/libcharset/lib/relocatable-stub.c
      ${iconv_dir}/windows/libiconv.rc)
  target_include_directories(iconv
    PUBLIC ${iconv_dir}/include
    PRIVATE ${iconv_dir}/libcharset/include)
  target_compile_definitions(iconv PRIVATE BUILDING_LIBICONV)
endif()

set(CMAKE_ENABLE_EXPORTS ON)

# Textadept core.
set(ta_src src/textadept.c $<$<BOOL:WIN32>:src/textadept.rc>)
if(NOT WIN32)
  set(ta_compile_opts -pedantic -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers)
else()
  set(ta_compile_opts /W4)
endif()
set(ta_link_libs scintilla scintillua lua lpeg lfs)
if(WIN32 OR APPLE)
  list(APPEND ta_link_libs iconv)
endif()

# Textadept Qt.
if(QT)
  add_library(textadept_qt STATIC)
  target_sources(textadept_qt PRIVATE src/textadept_qt.cpp src/textadept_qt.ui)
  target_compile_definitions(textadept_qt PRIVATE QT_NO_KEYWORDS)
  target_compile_options(textadept_qt PRIVATE ${ta_compile_opts})
  target_link_libraries(textadept_qt PRIVATE scintilla_qt lua Qt5::Widgets)

  add_executable(textadept)
  target_sources(textadept PRIVATE ${ta_src})
  if(WIN32)
    target_include_directories(textadept PRIVATE ${iconv_dir}/include)
    set_target_properties(textadept PROPERTIES WIN32_EXECUTABLE ON)
  endif()
  target_link_libraries(textadept PRIVATE ${ta_link_libs} textadept_qt)
endif()

# Textadept GTK.
if(GTK3 OR GTK2)
  add_library(textadept_gtk STATIC)
  target_sources(textadept_gtk PRIVATE src/textadept_gtk.c)
  target_include_directories(textadept_gtk PRIVATE ${GTK_INCLUDE_DIRS})
  target_compile_options(textadept_gtk PRIVATE ${ta_compile_opts})
  target_link_directories(textadept_gtk PRIVATE ${GTK_LIBRARY_DIRS})
  target_link_libraries(textadept_gtk PRIVATE scintilla_gtk lua ${GTK_LIBRARIES})

  add_executable(textadept-gtk)
  target_sources(textadept-gtk PRIVATE ${ta_src})
  target_link_libraries(textadept-gtk PRIVATE ${ta_link_libs} textadept_gtk)
endif()

# Textadept Curses.
if(CURSES)
  add_library(textadept_curses STATIC)
  target_sources(textadept_curses PRIVATE src/textadept_curses.c)
  target_include_directories(textadept_curses PRIVATE ${CURSES_INCLUDE_DIRS})
  target_compile_options(textadept_curses PRIVATE ${ta_compile_opts})
  if(NOT (WIN32 OR APPLE))
    target_compile_definitions(textadept_curses PRIVATE _GNU_SOURCE) # for execvpe from unistd.h
  endif()
  target_link_directories(textadept_curses PRIVATE ${CURSES_LIBRARY_DIRS})
  target_link_libraries(textadept_curses
    PRIVATE scintilla_curses lua termkey cdk ${CURSES_LIBRARIES})

  add_executable(textadept-curses)
  target_sources(textadept-curses PRIVATE ${ta_src})
  if(WIN32)
    target_include_directories(textadept-curses PRIVATE ${iconv_dir}/include)
  endif()
  target_link_libraries(textadept-curses PRIVATE ${ta_link_libs} textadept_curses)
endif()

# Version information.
file(STRINGS core/init.lua version_line REGEX ^_RELEASE)
string(REGEX MATCH "[1-9][^']+" version ${version_line})
if(NOT DEFINED NIGHTLY)
  string(REPLACE " " _ version_ ${version})
else()
  set(version_ nightly)
endif()
if(NOT (WIN32 OR APPLE))
  string(APPEND version_ .linux)
elseif(WIN32)
  string(APPEND version_ .win)
elseif(APPLE)
  string(APPEND version_ .macOS)
endif()

# Install/release.
if(NOT (WIN32 OR APPLE))
  include(GNUInstallDirs)
  set(ta_bin_dir ${CMAKE_INSTALL_FULL_BINDIR})
  install(CODE "file(MAKE_DIRECTORY ${ta_bin_dir})")
  set(ta_data_dir ${CMAKE_INSTALL_FULL_DATADIR}/textadept)
  if(QT)
    install(TARGETS textadept DESTINATION ${ta_data_dir})
    install(CODE "file(CREATE_LINK ${ta_data_dir}/textadept ${ta_bin_dir}/textadept SYMBOLIC)")
    install(FILES src/textadept.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  endif()
  if(GTK3 OR GTK2)
    install(TARGETS textadept-gtk DESTINATION ${ta_data_dir})
    install(CODE "file(CREATE_LINK ${ta_data_dir}/textadept-gtk
      ${ta_bin_dir}/textadept-gtk SYMBOLIC)")
    install(FILES src/textadept-gtk.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  endif()
  if(CURSES)
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
  if(QT)
    install(TARGETS textadept DESTINATION ${ta_dir})
  endif()
  if(CURSES)
    install(TARGETS textadept-curses DESTINATION ${ta_dir})
  endif()
  install(TARGETS iconv DESTINATION ${ta_dir})
  install(FILES init.lua LICENSE DESTINATION ${ta_dir})
  install(DIRECTORY core docs ${scilua_dir}/lexers modules themes DESTINATION ${ta_dir})
  if(NOT (EXISTS ${ta_dir}/Qt5Core.dll OR EXISTS ${ta_dir}/Qt5Cored.dll))
    install(CODE
      "execute_process(COMMAND windeployqt --no-compiler-runtime ${ta_dir}/textadept.exe)")
    if(DEFINED ENV{VCINSTALLDIR})
      execute_process(COMMAND $ENV{COMSPEC} /C dir /S $ENV{VCINSTALLDIR}\\Redist /B
        OUTPUT_FILE ${CMAKE_BINARY_DIR}/vcrun_dlls.txt)
      # Output is of the form:
      # C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Redist\
      #   MSVC\14.16.27012\x64\Microsoft.VC141.CRT\concrt140.dll
      # C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\
      #   MSVC\14.34.31931\x86\Microsoft.VC143.CRT\concrt140.dll
      file(STRINGS ${CMAKE_BINARY_DIR}/vcrun_dlls.txt vcrun_dlls
        REGEX [0-9]\\\\x64\\\\Microsoft\.VC[0-9]+\.CRT.+\.dll$)
    endif()
    if(NOT DEFINED vcrun_dlls OR vcrun_dlls STREQUAL "")
      if(NOT DEFINED ENV{VCINSTALLDIR})
        set(vcrun_dlls "%VCINSTALLDIR% is not defined")
      elseif(NOT EXISTS $ENV{VCINSTALLDIR})
        set(vcrun_dlls"$ENV{VCINSTALLDIR} does not exist")
      else()
        set(vcrun_dlls "No VC runtime dlls were found in $ENV{VCINSTALLDIR}")
      endif()
      message(WARNING "${vcrun_dlls}; compiling will work, but installation will fail")
    else()
      message(STATUS "VC runtime DLLS to install: ${vcrun_dlls}")
    endif()
    # Note that there may be duplicate runtime files installed. However, `dir` shows files in
    # sorted name order so the most recent runtime files will overwrite any older ones.
    install(FILES ${vcrun_dlls} DESTINATION ${ta_dir})
  endif()
  install(CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/textadept_${version_}.zip --format=zip
      textadept
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})")
elseif(APPLE)
  set(ta_bin_dir ${CMAKE_INSTALL_PREFIX}/Textadept.app/Contents/MacOS)
  set(ta_data_dir ${CMAKE_INSTALL_PREFIX}/Textadept.app/Contents/Resources)
  if(QT)
    install(TARGETS textadept DESTINATION ${ta_bin_dir})
  endif()
  if(CURSES)
    install(TARGETS textadept-curses DESTINATION ${ta_bin_dir})
  endif()
  install(PROGRAMS scripts/osx/textadept_osx DESTINATION ${ta_bin_dir})
  install(FILES init.lua LICENSE DESTINATION ${ta_data_dir})
  install(FILES src/Info.plist DESTINATION ${ta_data_dir}/../)
  install(DIRECTORY core docs ${scilua_dir}/lexers modules themes DESTINATION ${ta_data_dir})
  install(CODE "file(RENAME ${ta_data_dir}/core/images/textadept.icns
    ${ta_data_dir}/textadept.icns)")
  if(NOT EXISTS ${ta_data_dir}/qt.conf)
    install(CODE "execute_process(COMMAND macdeployqt ${CMAKE_INSTALL_PREFIX}/Textadept.app
      -executable=${ta_bin_dir}/textadept)")
  endif()
  install(FILES scripts/osx/ta DESTINATION ${CMAKE_INSTALL_PREFIX})
  install(CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/textadept_${version_}.zip --format=zip
      Textadept.app ta
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})")
endif()

# Documentation.
file(GLOB ta_md_docs docs/*.md)
add_custom_target(docs DEPENDS manual luadoc)
add_custom_target(manual DEPENDS luadoc
  COMMAND for file in `basename -a -s .md ${ta_md_docs}`\; do
    cat _layouts/default.html | ../scripts/fill_layout.lua $$file.md > $$file.html\; done
  COMMAND sed -i "\"s/\\(\\# Textadept\\).\\+\\?\\(Manual\\|API\\)/\\1 ${version} \\2/;\""
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

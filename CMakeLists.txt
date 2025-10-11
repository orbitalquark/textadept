# Copyright 2022-2025 Mitchell. See LICENSE.

cmake_minimum_required(VERSION 3.22..3.31)

project(textadept LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(APPLE)
	set(CMAKE_OSX_DEPLOYMENT_TARGET 11 CACHE STRING "")
endif()

# Determine available platforms.
find_package(QT NAMES Qt6 Qt5 COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Widgets)
if(Qt${QT_VERSION_MAJOR}_FOUND)
	option(QT "Build Textadept using Qt" ON)
endif()
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
	pkg_check_modules(GTK3 gtk+-3.0)
	if(GTK3_FOUND)
		option(GTK3 "Build Textadept using Gtk 3" ON)
	endif()
	pkg_check_modules(GTK2 gtk+-2.0)
	if(GTK2_FOUND)
		option(GTK2 "Build Textadept using Gtk 2" ON)
	endif()
endif()
if(NOT WIN32)
	# Note: can use if(LINUX) in CMake 3.25.
	if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
		set(CURSES_NEED_WIDE TRUE)
	endif()
	find_package(Curses)
endif()
if(CURSES_FOUND OR WIN32)
	option(CURSES "Build Textadept using Curses" ON)
endif()
if(NOT (QT OR GTK3 OR GTK2 OR CURSES))
	message(FATAL_ERROR "No suitable platform found.")
endif()

# Setup platform requirements.
if(QT)
	set(qt_major Qt${QT_VERSION_MAJOR})
	if(QT_VERSION_MAJOR GREATER 5)
		find_package(${qt_major} COMPONENTS Widgets Core5Compat REQUIRED)
		set(qt_libraries ${qt_major}::Widgets ${qt_major}::Core5Compat)
	else()
		find_package(${qt_major} COMPONENTS Widgets REQUIRED)
		set(qt_libraries ${qt_major}::Widgets)
	endif()
endif()
set(CMAKE_AUTOMOC ${QT})
set(CMAKE_AUTOUIC ${QT})
if(GTK3)
	pkg_search_module(GTK REQUIRED gtk+-3.0)
elseif(GTK2)
	pkg_search_module(GTK REQUIRED gtk+-2.0)
endif()
if(CURSES)
	if(WIN32)
		set(CURSES_LIBRARIES pdcurses)
	else()
		find_package(Curses REQUIRED)
	endif()
endif()
find_package(Threads REQUIRED)

# Dependencies.
include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
set(nightlies scinterm scintillua regex) # fetch latest version if NIGHTLY is true
set(deps_dir ${CMAKE_BINARY_DIR}/_deps)
if(POLICY CMP0135) # CMake 3.24 adds DOWNLOAD_EXTRACT_TIMESTAMP to FetchContent_Declare()
	cmake_policy(SET CMP0135 NEW)
endif()
function(fetch name url)
	string(REGEX MATCH "[^/]+$" archive ${url})
	list(FIND nightlies ${name} can_use_nightly)
	if(NIGHTLY AND can_use_nightly GREATER -1)
		string(REPLACE ${archive} default.zip url ${url}) # use nightly URL instead
	elseif(EXISTS ${deps_dir}/${archive})
		set(url file://${deps_dir}/${archive}) # use local archive instead of downloading
	endif()
	set(patch ${CMAKE_SOURCE_DIR}/src/${name}.patch)
	if(EXISTS ${patch})
		set(patch_command PATCH_COMMAND patch -N -p1 < ${patch})
	endif()
	FetchContent_Declare(${name} URL ${url} ${patch_command})
	# Note: cannot FetchContent_MakeAvailable(${name}) here, as name must be a literal.
endfunction()
fetch(scintilla https://www.scintilla.org/scintilla557.tgz)
fetch(scinterm https://github.com/orbitalquark/scinterm/archive/scinterm_5.5.zip)
fetch(scintillua https://github.com/orbitalquark/scintillua/archive/scintillua_6.6.zip)
fetch(lua https://www.lua.org/ftp/lua-5.4.8.tar.gz)
fetch(lpeg https://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.1.0.tar.gz)
fetch(lfs https://github.com/keplerproject/luafilesystem/archive/v1_8_0.zip)
fetch(regex https://github.com/orbitalquark/lua-std-regex/archive/1.0.zip)
fetch(cdk https://github.com/ThomasDickey/cdk-snapshots/archive/refs/tags/t20240619.tar.gz)
fetch(termkey https://www.leonerd.org.uk/code/libtermkey/libtermkey-0.22.tar.gz)
fetch(reproc https://github.com/DaanDeMeyer/reproc/archive/refs/tags/v14.2.5.zip)
FetchContent_MakeAvailable(scintilla scinterm lua lpeg lfs regex cdk termkey)
if(POLICY CMP0169) # CMake 3.28 adds EXCLUDE_FROM_ALL to FetchContent_MakeAvailable()
	cmake_policy(SET CMP0169 OLD)
endif()
FetchContent_Populate(scintillua) # do not import targets; only need Lua lexers
if(WIN32)
	fetch(pdcurses https://prdownloads.sourceforge.net/pdcurses/PDCurses-3.9.zip)
	fetch(iconv https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz)
	FetchContent_MakeAvailable(pdcurses iconv)
endif()
if(QT)
	fetch(singleapp https://github.com/itay-grudev/SingleApplication/archive/refs/tags/v3.5.3.zip)
	set(QAPPLICATION_CLASS QApplication CACHE STRING "Inheritance class for SingleApplication")
	set(QT_DEFAULT_MAJOR_VERSION ${QT_VERSION_MAJOR})
	FetchContent_MakeAvailable(singleapp)
endif()
if(CURSES)
	set(REPROC_INSTALL OFF)
	FetchContent_MakeAvailable(reproc)
endif()
option(FETCHCONTENT_UPDATES_DISCONNECTED "Do not update deps if already set up" ON)

# Scintilla core.
file(GLOB sci_src ${scintilla_SOURCE_DIR}/src/*.cxx)
add_library(scintilla STATIC ${sci_src})
target_include_directories(scintilla
	PUBLIC ${scintilla_SOURCE_DIR}/include
	PRIVATE ${scintilla_SOURCE_DIR}/src)
target_compile_definitions(scintilla PUBLIC SCI_LEXER)
target_compile_options(scintilla PRIVATE $<$<BOOL:${WIN32}>:/EHsc>)
target_link_libraries(scintilla PRIVATE Threads::Threads)

# Scintilla platform.
if(QT)
	file(GLOB sci_qt_src ${scintilla_SOURCE_DIR}/qt/ScintillaEditBase/*.cpp)
	add_library(scintilla_qt STATIC ${sci_qt_src})
	target_include_directories(scintilla_qt PUBLIC ${scintilla_SOURCE_DIR}/qt/ScintillaEditBase
		${scintilla_SOURCE_DIR}/src)
	target_compile_definitions(scintilla_qt PUBLIC SCINTILLA_QT)
	target_link_libraries(scintilla_qt PUBLIC scintilla PRIVATE ${qt_libraries})
endif()
if(GTK3 OR GTK2)
	file(GLOB sci_gtk_src ${scintilla_SOURCE_DIR}/gtk/*.c ${scintilla_SOURCE_DIR}/gtk/*.cxx)
	add_library(scintilla_gtk STATIC ${sci_gtk_src})
	target_include_directories(scintilla_gtk
		PUBLIC ${scintilla_SOURCE_DIR}/gtk
		PRIVATE ${scintilla_SOURCE_DIR}/src ${GTK_INCLUDE_DIRS})
	target_compile_definitions(scintilla_gtk PUBLIC GTK)
	target_compile_options(scintilla_gtk PUBLIC -Wno-deprecated-declarations)
	target_link_directories(scintilla_gtk PRIVATE ${GTK_LIBRARY_DIRS})
	target_link_libraries(scintilla_gtk PUBLIC scintilla PRIVATE ${GTK_LIBRARIES})
endif()
if(CURSES)
	file(GLOB sci_curses_src ${scinterm_SOURCE_DIR}/*.cxx)
	if(WIN32)
		# Note: cannot use generator expression in file(GLOB) for some reason.
		list(APPEND sci_curses_src ${scinterm_SOURCE_DIR}/wcwidth.c)
	endif()
	add_library(scintilla_curses STATIC ${sci_curses_src})
	target_include_directories(scintilla_curses
		PUBLIC ${scinterm_SOURCE_DIR}
		PRIVATE ${scintilla_SOURCE_DIR}/src ${CURSES_INCLUDE_DIRS})
	target_compile_definitions(scintilla_curses PUBLIC CURSES)
	target_compile_options(scintilla_curses PRIVATE $<IF:$<NOT:$<BOOL:${WIN32}>>,-pedantic -Wall,/W4>)
	target_link_directories(scintilla_curses PRIVATE ${CURSES_LIBRARY_DIRS})
	target_link_libraries(scintilla_curses PUBLIC scintilla PRIVATE ${CURSES_LIBRARIES})
endif()

# Scintillua.
# Nothing to set up.

# Lua.
file(GLOB lua_src ${lua_SOURCE_DIR}/src/*.c)
list(FILTER lua_src EXCLUDE REGEX "(lua|luac)\.c$")
add_library(lua STATIC ${lua_src})
target_include_directories(lua PUBLIC ${lua_SOURCE_DIR}/src)
target_compile_definitions(lua PRIVATE
	$<IF:$<BOOL:${WIN32}>,LUA_BUILD_AS_DLL,$<IF:$<BOOL:${APPLE}>,LUA_USE_MACOSX,LUA_USE_LINUX>>
	$<$<CONFIG:Debug>:LUA_USE_APICHECK>)
target_link_libraries(lua PRIVATE ${CMAKE_DL_LIBS})

# LPeg.
file(GLOB lpeg_src ${lpeg_SOURCE_DIR}/*.c)
add_library(lpeg STATIC ${lpeg_src})
target_link_libraries(lpeg PRIVATE lua)

# LFS.
file(GLOB lfs_src ${lfs_SOURCE_DIR}/src/*.c)
add_library(lfs STATIC ${lfs_src})
target_link_libraries(lfs PRIVATE lua)

# Regex.
file(GLOB regex_src ${regex_SOURCE_DIR}/*.cpp)
add_library(regex STATIC ${regex_src})
target_link_libraries(regex PRIVATE lua)

if(CURSES)
	# PDCurses.
	if(WIN32)
		file(GLOB pdcurses_src ${pdcurses_SOURCE_DIR}/pdcurses/*.c ${pdcurses_SOURCE_DIR}/wincon/*.c)
		add_library(pdcurses STATIC ${pdcurses_src})
		target_include_directories(pdcurses
			PUBLIC ${pdcurses_SOURCE_DIR}
			PRIVATE ${pdcurses_SOURCE_DIR}/wincon)
		target_compile_definitions(pdcurses PRIVATE PDC_WIDE PDC_FORCE_UTF8)
	endif()

	# Termkey.
	set(termkey_src termkey.c $<IF:$<BOOL:${UNIX}>,driver-ti.c driver-csi.c,driver-win-pdcurses.c>)
	list(TRANSFORM termkey_src PREPEND ${termkey_SOURCE_DIR}/)
	add_library(termkey STATIC ${termkey_src})
	target_include_directories(termkey PUBLIC ${termkey_SOURCE_DIR})
	target_link_directories(termkey PRIVATE ${CURSES_LIBRARY_DIRS})
	target_link_libraries(termkey PRIVATE ${CURSES_LIBRARIES})

	# CDK.
	set(cdk_src binding buttonbox cdk cdk_display cdk_objs cdkscreen dialog draw entry fselect
		itemlist label mentry popup_label scroll scroller select_file selection slider traverse version)
	list(TRANSFORM cdk_src APPEND .c)
	list(TRANSFORM cdk_src PREPEND ${cdk_SOURCE_DIR}/)
	add_library(cdk STATIC ${cdk_src})
	target_include_directories(cdk PUBLIC ${cdk_SOURCE_DIR}/include)
	target_link_directories(cdk PRIVATE ${CURSES_LIBRARY_DIRS})
	target_link_libraries(cdk PRIVATE termkey ${CURSES_LIBRARIES})

	# reproc.
	# Note: no need to do anything because reproc uses CMake and FetchContent_MakeAvailable()
	# sets it all up!
endif()

# iconv
if(WIN32)
	set(iconv_src lib/iconv.c lib/relocatable.c libcharset/lib/localcharset.c
		libcharset/lib/relocatable-stub.c windows/libiconv.rc)
	list(TRANSFORM iconv_src PREPEND ${iconv_SOURCE_DIR}/)
	add_library(iconv SHARED ${iconv_src})
	target_include_directories(iconv
		PUBLIC ${iconv_SOURCE_DIR}/include
		PRIVATE ${iconv_SOURCE_DIR}/libcharset/include)
	target_compile_definitions(iconv PRIVATE BUILDING_LIBICONV)
endif()

set(CMAKE_ENABLE_EXPORTS ON) # allow external Lua modules to link to exe

# Textadept core.
set(ta_src src/textadept.c $<$<BOOL:${WIN32}>:src/textadept.rc>)
set(ta_compile_opts
	$<IF:$<NOT:$<BOOL:${WIN32}>>,-pedantic -Wall -Wextra -Wno-unused-parameter
		-Wno-missing-field-initializers,/W4>
	$<$<BOOL:${PROFILE}>:-pg --coverage>
	$<$<BOOL:${TEXTADEPT_HOME}>:-DTEXTADEPT_HOME="${TEXTADEPT_HOME}">)
set(ta_link_opts $<$<BOOL:${PROFILE}>:--coverage>)
set(ta_link_libs scintilla lua lpeg lfs regex $<$<OR:$<BOOL:${WIN32}>,$<BOOL:${APPLE}>>:iconv>)

# Textadept Qt.
if(QT)
	add_library(textadept_qt OBJECT src/textadept_qt.cpp src/textadept_qt.ui)
	target_compile_definitions(textadept_qt PRIVATE QT_NO_KEYWORDS)
	target_compile_options(textadept_qt PRIVATE ${ta_compile_opts})
	target_link_libraries(textadept_qt PRIVATE scintilla_qt lua ${qt_libraries}
		SingleApplication::SingleApplication)

	add_executable(textadept ${ta_src})
	target_include_directories(textadept PRIVATE $<$<BOOL:${WIN32}>:${iconv_SOURCE_DIR}/include>)
	set_target_properties(textadept PROPERTIES WIN32_EXECUTABLE $<$<BOOL:${WIN32}>:ON>)
	target_compile_options(textadept PRIVATE ${ta_compile_opts})
	target_link_options(textadept PRIVATE ${ta_link_opts})
	target_link_libraries(textadept PRIVATE ${ta_link_libs} textadept_qt)
endif()

# Textadept GTK.
if(GTK3 OR GTK2)
	add_library(textadept_gtk OBJECT src/textadept_gtk.c)
	target_include_directories(textadept_gtk PRIVATE ${GTK_INCLUDE_DIRS})
	target_compile_options(textadept_gtk PRIVATE ${ta_compile_opts})
	target_link_directories(textadept_gtk PRIVATE ${GTK_LIBRARY_DIRS})
	target_link_libraries(textadept_gtk PRIVATE scintilla_gtk lua ${GTK_LIBRARIES})

	add_executable(textadept-gtk ${ta_src})
	target_compile_options(textadept-gtk PRIVATE ${ta_compile_opts})
	target_link_options(textadept-gtk PRIVATE ${ta_link_opts})
	target_link_libraries(textadept-gtk PRIVATE ${ta_link_libs} textadept_gtk)
endif()

# Textadept Curses.
if(CURSES)
	add_library(textadept_curses OBJECT src/textadept_curses.c)
	target_include_directories(textadept_curses PRIVATE ${CURSES_INCLUDE_DIRS})
	target_compile_options(textadept_curses PRIVATE ${ta_compile_opts})
	target_link_directories(textadept_curses PRIVATE ${CURSES_LIBRARY_DIRS})
	target_link_libraries(textadept_curses PRIVATE scintilla_curses lua termkey cdk reproc
		${CURSES_LIBRARIES})

	add_executable(textadept-curses ${ta_src})
	target_include_directories(textadept-curses PRIVATE
		$<$<BOOL:${WIN32}>:${iconv_SOURCE_DIR}/include>)
	target_compile_options(textadept-curses PRIVATE ${ta_compile_opts})
	target_link_options(textadept-curses PRIVATE ${ta_link_opts})
	target_link_libraries(textadept-curses PRIVATE ${ta_link_libs} textadept_curses)
endif()

# Version information.
file(STRINGS core/init.lua version_line REGEX "^_RELEASE")
string(REGEX MATCH "[1-9][^']+" version ${version_line})
if(NOT NIGHTLY)
	string(REPLACE " " "_" version ${version})
else()
	set(version nightly)
endif()
if(NOT (WIN32 OR APPLE))
	string(APPEND version ".linux")
elseif(WIN32)
	string(APPEND version ".win")
elseif(APPLE)
	string(APPEND version ".macOS")
endif()

# Install/release.
function(install_data dir)
	install(FILES init.lua LICENSE DESTINATION ${dir})
	install(DIRECTORY core docs ${scintillua_SOURCE_DIR}/lexers test themes DESTINATION ${dir})
	install(DIRECTORY modules DESTINATION ${dir} PATTERN ".git" EXCLUDE PATTERN "build" EXCLUDE)
endfunction()
if(NOT (WIN32 OR APPLE))
	include(GNUInstallDirs)
	set(ta_bin_dir ${CMAKE_INSTALL_FULL_BINDIR})
	install(CODE "file(MAKE_DIRECTORY ${ta_bin_dir})")
	set(ta_data_dir ${CMAKE_INSTALL_FULL_DATADIR}/textadept)
	file(RELATIVE_PATH ta_bin_to_data_dir ${CMAKE_INSTALL_FULL_BINDIR} ${ta_data_dir})
	install(CODE "file(MAKE_DIRECTORY ${CMAKE_INSTALL_FULL_DATADIR}/applications)")
	file(RELATIVE_PATH ta_app_to_data_dir ${CMAKE_INSTALL_FULL_DATADIR}/applications ${ta_data_dir})
	function(install_links target)
		if(DEFINED TEXTADEPT_HOME)
			install(TARGETS ${target} DESTINATION ${ta_bin_dir})
		else()
			install(TARGETS ${target} DESTINATION ${ta_data_dir})
			install(CODE "file(CREATE_LINK ${ta_bin_to_data_dir}/${target}
				${ta_bin_dir}/${target} SYMBOLIC)")
		endif()
		install(FILES src/${target}.desktop DESTINATION ${ta_data_dir})
		install(CODE "file(CREATE_LINK ${ta_app_to_data_dir}/${target}.desktop
			${CMAKE_INSTALL_FULL_DATADIR}/applications/${target}.desktop SYMBOLIC)")
	endfunction()
	if(QT)
		install_links(textadept)
	endif()
	if(GTK3 OR GTK2)
		install_links(textadept-gtk)
	endif()
	if(CURSES)
		install_links(textadept-curses)
	endif()
	install_data(${ta_data_dir})
	install(FILES core/images/textadept.svg
		DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
	set(textadept_tgz textadept_${version}.tgz)
	if(CMAKE_SYSTEM_PROCESSOR MATCHES "^aarch")
		set(textadept_tgz textadept_${version}.arm.tgz)
	endif()
	# Note: can use file(ARCHIVE_CREATE ... WORKING_DIRECTORY) in CMake 3.31.
	add_custom_target(archive
		COMMAND ${CMAKE_COMMAND} -E tar czf ${CMAKE_BINARY_DIR}/${textadept_tgz} textadept
		WORKING_DIRECTORY ${CMAKE_INSTALL_FULL_DATADIR})
elseif(WIN32)
	set(ta_dir ${CMAKE_INSTALL_PREFIX}/textadept)
	if(QT)
		install(TARGETS textadept DESTINATION ${ta_dir})
	endif()
	if(CURSES)
		install(TARGETS textadept-curses DESTINATION ${ta_dir})
	endif()
	install_data(${ta_dir})
	install(TARGETS iconv DESTINATION ${ta_dir})
	if(NOT (EXISTS ${ta_dir}/${qt_major}Core.dll OR EXISTS ${ta_dir}/${qt_major}Cored.dll))
		install(CODE "execute_process(COMMAND ${WINDEPLOYQT_EXECUTABLE} --no-compiler-runtime
			${ta_dir}/textadept.exe)")
		install(CODE "file(REMOVE ${ta_dir}/d3dcompiler_47.dll ${ta_dir}/opengl32sw.dll)")
		set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${ta_dir}) # put system libs here, not in bin/
		include(InstallRequiredSystemLibraries)
	endif()
	add_custom_target(archive
		COMMAND 7z a ${CMAKE_BINARY_DIR}/textadept_${version}.zip textadept
		WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})
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
	install_data(${ta_data_dir})
	install(CODE "file(RENAME ${ta_data_dir}/core/images/textadept.icns
		${ta_data_dir}/textadept.icns)")
	if(POLICY CMP0177) # CMake 3.31 auto-normalizes .. in install() paths.
		cmake_policy(SET CMP0177 NEW)
	endif()
	install(FILES src/Info.plist DESTINATION ${ta_data_dir}/../)
	if(NOT EXISTS ${ta_data_dir}/qt.conf)
		install(CODE "execute_process(COMMAND ${MACDEPLOYQT_EXECUTABLE}
			${CMAKE_INSTALL_PREFIX}/Textadept.app -executable=${ta_bin_dir}/textadept)")
		# Homebrew Qt's macdeployqt cannot resolve rpaths to Homebrew's lib prefix.
		# Work around this issue by adding Homebrew's lib to the executable's rpaths.
		find_program(BREW brew)
		if(BREW)
			execute_process(COMMAND ${BREW} --prefix OUTPUT_VARIABLE BREW_PREFIX
				OUTPUT_STRIP_TRAILING_WHITESPACE)
			if(QT_DIR MATCHES "^${BREW_PREFIX}")
				install(CODE "execute_process(COMMAND ${CMAKE_INSTALL_NAME_TOOL} -add_rpath ${BREW_PREFIX}/lib
					${ta_bin_dir}/textadept)")
				install(CODE "execute_process(COMMAND codesign --sign - --force --deep
					${CMAKE_INSTALL_PREFIX}/Textadept.app)")
			endif()
		endif()
	endif()
	install(PROGRAMS scripts/osx/ta DESTINATION ${CMAKE_INSTALL_PREFIX})
	add_custom_target(archive
		COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/textadept_${version}.zip --format=zip
			Textadept.app ta
		WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})
endif()

# Generate HTML.
option(GENERATE_HTML "Generate HTML documentation in docs/" OFF)
if(GENERATE_HTML)
	find_program(LUA lua REQUIRED)
	find_program(BUNDLE bundle REQUIRED)
	add_custom_target(html COMMAND ./gen_docs.sh WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/scripts)
endif()

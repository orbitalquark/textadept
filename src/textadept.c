// Copyright 2007-2024 Mitchell. See LICENSE.

#include "textadept.h"

// External dependency includes.
#include "lualib.h" // for luaL_openlibs
#include "lauxlib.h"

// Library includes.
#include <errno.h>
#include <limits.h> // for MB_LEN_MAX
#include <locale.h>
#include <iconv.h>
#include <math.h> // for fmax
#include <stdlib.h>
#include <string.h>
#if __linux__
#include <unistd.h> // for readlink
#elif _WIN32
#include <windows.h> // for GetModuleFileName
#elif __APPLE__
#include <mach-o/dyld.h> // for _NSGetExecutablePath
#endif

// Variables declared in textadept.h.
char *textadept_home;
SciObject *focused_view, *command_entry;
FindButton *find_next, *find_prev, *replace, *replace_all;
FindOption *match_case, *whole_word, *regex, *in_files;
lua_State *lua;
int exit_status;

static char *os;
static SciObject *dummy_view; // for working with documents not shown in an existing view

// Lua objects.
static const char *BUFFERS = "ta_buffers", *VIEWS = "ta_views", *ARG = "ta_arg"; // registry tables
static bool initing, closing;
static int tabs = 1; // int for more options than true/false
enum { SVOID, SINT, SLEN, SINDEX, SCOLOR, SBOOL, SKEYMOD, SSTRING, SSTRINGRET };
LUALIB_API int luaopen_lpeg(lua_State *), luaopen_lfs(lua_State *), luaopen_regex(lua_State *);

// Forward declarations.
static void add_doc(sptr_t doc);
static SciObject *new_view(sptr_t);
static bool init_lua(int, char **);

// Shows the given error in an error message dialog, as well as printing to stderr.
static void show_error(const char *title, const char *message) {
	fprintf(stderr, "%s: %s\n", title, message);
	DialogOptions opts = {title, message, "dialog-error", {"OK", NULL, NULL}};
	lua_pop(lua, message_dialog(opts, lua)); // pop results
}

bool emit(const char *name, ...) {
	bool ret = false;
	if (lua_getglobal(lua, "events") != LUA_TTABLE) return (lua_pop(lua, 1), ret); // pop non-table
	if (lua_getfield(lua, -1, "emit") != LUA_TFUNCTION) return (lua_pop(lua, 2), ret); // pop non-func
	lua_pushstring(lua, name);
	int n = 1, ref;
	va_list ap;
	va_start(ap, name);
	for (int type = va_arg(ap, int); type != -1; type = va_arg(ap, int), n++) switch (type) {
		case LUA_TBOOLEAN: lua_pushboolean(lua, va_arg(ap, int)); break;
		case LUA_TNUMBER: lua_pushinteger(lua, va_arg(ap, int)); break;
		case LUA_TSTRING: lua_pushstring(lua, va_arg(ap, char *)); break;
		case LUA_TLIGHTUSERDATA:
		case LUA_TTABLE:
			ref = va_arg(ap, int);
			lua_rawgeti(lua, LUA_REGISTRYINDEX, ref), luaL_unref(lua, LUA_REGISTRYINDEX, ref);
			break;
		default: lua_pushnil(lua);
		}
	va_end(ap);
	if (lua_pcall(lua, n, 1, 0) != LUA_OK)
		// An error occurred within `events.emit()` itself, not an event handler.
		return (show_error("Error", lua_tostring(lua, -1)), lua_pop(lua, 2), ret); // pop error, events
	ret = lua_toboolean(lua, -1);
	return (lua_pop(lua, 2), ret); // pop result, events
}

// `string.iconv()` Lua function.
static int iconv_lua(lua_State *L) {
	size_t inbytesleft = 0;
	char *inbuf = (char *)luaL_checklstring(L, 1, &inbytesleft);
	const char *to = luaL_checkstring(L, 2), *from = luaL_checkstring(L, 3);
	iconv_t cd = iconv_open(to, from);
	if (cd == (iconv_t)-1) return luaL_error(L, "invalid encoding(s)");
	luaL_Buffer buf;
	luaL_buffinit(L, &buf);
	// Ensure the minimum buffer size can hold a potential output BOM and one multibyte character.
	size_t bufsiz = 4 + fmax(inbytesleft, MB_LEN_MAX), outbytesleft = bufsiz;
	char *outbuf = malloc(bufsiz + 1), *p = outbuf;
	while (iconv(cd, &inbuf, &inbytesleft, &p, &outbytesleft) == (size_t)-1) {
		if (errno != E2BIG) return (free(outbuf), iconv_close(cd), luaL_error(L, "conversion failed"));
		luaL_addlstring(&buf, outbuf, p - outbuf), p = outbuf, outbytesleft = bufsiz;
	}
	luaL_addlstring(&buf, outbuf, p - outbuf), lua_checkstack(L, 1), luaL_pushresult(&buf);
	return (free(outbuf), iconv_close(cd), 1);
}

void process_output(Process *proc, const char *buf, size_t len, bool is_stdout) {
	lua_rawgetp(lua, LUA_REGISTRYINDEX, proc), lua_getiuservalue(lua, -1, is_stdout ? 1 : 2),
		lua_replace(lua, -2);
	if (lua_pushlstring(lua, buf, len), lua_pcall(lua, 1, 0, 0) != LUA_OK)
		emit("error", LUA_TSTRING, lua_tostring(lua, -1), -1), lua_pop(lua, 1);
}

void process_exited(Process *proc, int code) {
	bool monitoring_exit = (lua_rawgetp(lua, LUA_REGISTRYINDEX, proc), lua_getiuservalue(lua, -1, 3));
	monitoring_exit ? lua_replace(lua, -2) : lua_pop(lua, 2); // pop nil, proc
	if (monitoring_exit && (lua_pushinteger(lua, code), lua_pcall(lua, 1, 0, 0) != LUA_OK))
		emit("error", LUA_TSTRING, lua_tostring(lua, -1), -1), lua_pop(lua, 1);
	lua_pushnil(lua), lua_rawsetp(lua, LUA_REGISTRYINDEX, proc); // t[proc] = nil; allow GC
}

// `proc:status()` Lua method.
static int proc_status(lua_State *L) {
	Process *proc = luaL_checkudata(L, 1, "ta_spawn");
	return (lua_pushstring(L, is_process_running(proc) ? "running" : "terminated"), 1);
}

// `proc:wait()` Lua method.
static int proc_wait(lua_State *L) {
	Process *proc = luaL_checkudata(L, 1, "ta_spawn");
	if (is_process_running(proc)) wait_process(luaL_checkudata(L, 1, "ta_spawn"));
	return (lua_pushinteger(L, get_process_exit_status(proc)), 1);
}

// `proc:read()` Lua method.
static int proc_read(lua_State *L) {
	Process *proc = luaL_checkudata(L, 1, "ta_spawn");
	luaL_argcheck(L, is_process_running(proc), 1, "process terminated");
	const char *p = luaL_optstring(L, 2, "l");
	if (*p == '*') p++; // skip optional '*' (for compatibility)
	luaL_argcheck(L, *p == 'l' || *p == 'L' || *p == 'a' || lua_isnumber(L, 2), 2, "invalid option");
	size_t len = lua_tointeger(L, 2);
	const char *error;
	int code;
	char *buf = read_process_output(proc, !lua_isnumber(L, 2) ? *p : 'n', &len, &error, &code);
	if (!buf && error) return (lua_pushnil(L), lua_pushstring(L, error), lua_pushinteger(L, code), 3);
	return (buf ? (lua_pushlstring(L, buf, len), free(buf)) : lua_pushnil(L), 1);
}

// `proc:write()` Lua method.
static int proc_write(lua_State *L) {
	Process *proc = luaL_checkudata(L, 1, "ta_spawn");
	luaL_argcheck(L, is_process_running(proc), 1, "process terminated");
	for (int i = 2; i <= lua_gettop(L); i++) {
		size_t len;
		const char *s = luaL_checklstring(L, i, &len);
		write_process_input(proc, s, len);
	}
	return 0;
}

// `proc:close()` Lua method.
static int proc_close(lua_State *L) {
	Process *proc = luaL_checkudata(L, 1, "ta_spawn");
	luaL_argcheck(L, is_process_running(proc), 1, "process terminated");
	return (close_process_input(proc), 0);
}

// `proc:kill()` Lua method.
static int proc_kill(lua_State *L) {
	return (kill_process(luaL_checkudata(L, 1, "ta_spawn"), lua_tointeger(L, 2)), 0);
}

// `proc:__gc()` Lua metamethod.
static int proc_gc(lua_State *L) { return (cleanup_process(luaL_checkudata(L, 1, "ta_spawn")), 0); }

// Returns whether or not the value at the given index is callable (i.e. it is either a function
// or a table with a `__call` metafield).
static int lua_iscallable(lua_State *L, int index) {
	if (lua_isfunction(L, index)) return true;
	return luaL_getmetafield(L, index, "__call") ? (lua_pop(L, 1), 1) : 0;
}

// `os.spawn()` Lua function.
static int spawn_lua(lua_State *L) {
	int narg = 1, top = lua_gettop(L);
	const char *cmd = luaL_checkstring(L, narg++),
						 *cwd = lua_isstring(L, narg) ? lua_tostring(L, narg++) : NULL;
	// Replace optional environment table with a pure "key=value" list for platform processing.
	int envi = lua_istable(L, narg) && !lua_iscallable(L, narg) ? narg++ : 0;
	if (envi) {
		lua_newtable(L);
		for (lua_pushnil(L); lua_next(L, envi); lua_pop(L, 1)) {
			if (!lua_isstring(L, -2) || !lua_isstring(L, -1)) continue;
			if (lua_type(L, -2) == LUA_TSTRING)
				lua_pushvalue(L, -2), lua_pushliteral(L, "="), lua_pushvalue(L, -3), lua_concat(L, 3),
					lua_replace(L, -2); // construct "KEY=VALUE"
			lua_pushvalue(L, -1), lua_rawseti(L, -4, lua_rawlen(L, -4) + 1);
		}
		lua_replace(L, envi);
	}

	// Create process object to be returned and link callback functions from optional function params.
	Process *proc = lua_newuserdatauv(L, process_size(), 3);
	for (int i = narg; i <= top && i < narg + 3; i++)
		luaL_argcheck(L, lua_iscallable(L, i) || lua_isnil(L, i), i, "function or nil expected"),
			lua_pushvalue(L, i), lua_setiuservalue(L, -2, i - narg + 1);

	// Spawn the process and return it.
	top = lua_gettop(L);
	bool monitor_stdout = lua_getiuservalue(L, -1, 1), monitor_stderr = lua_getiuservalue(L, -2, 2);
	const char *error = NULL;
	bool ok = spawn(L, proc, top, cmd, cwd, envi, monitor_stdout, monitor_stderr, &error);
	if (lua_settop(L, top), !ok)
		return (lua_pushnil(L), lua_pushfstring(L, "%s: %s", lua_tostring(L, 1), error), 2);
	if (luaL_newmetatable(L, "ta_spawn")) {
		lua_pushcfunction(L, proc_status), lua_setfield(L, -2, "status");
		lua_pushcfunction(L, proc_wait), lua_setfield(L, -2, "wait");
		lua_pushcfunction(L, proc_read), lua_setfield(L, -2, "read");
		lua_pushcfunction(L, proc_write), lua_setfield(L, -2, "write");
		lua_pushcfunction(L, proc_close), lua_setfield(L, -2, "close");
		lua_pushcfunction(L, proc_kill), lua_setfield(L, -2, "kill");
		lua_pushcfunction(L, proc_gc), lua_setfield(L, -2, "__gc");
		lua_pushvalue(L, -1), lua_setfield(L, -2, "__index");
	}
	lua_setmetatable(L, -2);
	lua_pushvalue(L, -1), lua_rawsetp(L, LUA_REGISTRYINDEX, proc); // t[proc] = proc; prevent GC
	return 1;
}

void find_clicked(FindButton *button) {
	const char *find_text = get_find_text(), *repl_text = get_repl_text();
	if (find_text && !*find_text) return;
	(button == find_next || button == find_prev) ? add_to_find_history(find_text) :
																								 add_to_repl_history(repl_text);
	if (button == find_next || button == find_prev)
		emit("find", LUA_TSTRING, find_text, LUA_TBOOLEAN, button == find_next, -1);
	else if (button == replace) {
		if (!emit("replace", LUA_TSTRING, repl_text, -1))
			emit("find", LUA_TSTRING, find_text, LUA_TBOOLEAN, true, -1);
	} else if (button == replace_all)
		emit("replace_all", LUA_TSTRING, find_text, LUA_TSTRING, repl_text, -1);
}

// `find.find_next()` Lua function.
static int click_find_next(lua_State *L) { return (find_clicked(find_next), 0); }

// `find.find_prev()` Lua function.
static int click_find_prev(lua_State *L) { return (find_clicked(find_prev), 0); }

// `find.replace()` Lua function.
static int click_replace(lua_State *L) { return (find_clicked(replace), 0); }

// `find.replace_all()` Lua function.
static int click_replace_all(lua_State *L) { return (find_clicked(replace_all), 0); }

// `find.focus()` Lua function.
static int focus_find_lua(lua_State *L) { return (focus_find(), 0); }

// `find.__index` Lua metamethod.
static int find_index(lua_State *L) {
	const char *key = lua_tostring(L, 2);
	if (strcmp(key, "find_entry_text") == 0)
		return (get_find_text() ? lua_pushstring(L, get_find_text()) : lua_pushliteral(L, ""), 1);
	if (strcmp(key, "replace_entry_text") == 0)
		return (get_repl_text() ? lua_pushstring(L, get_repl_text()) : lua_pushliteral(L, ""), 1);
	if (strcmp(key, "match_case") == 0) return (lua_pushboolean(L, is_checked(match_case)), 1);
	if (strcmp(key, "whole_word") == 0) return (lua_pushboolean(L, is_checked(whole_word)), 1);
	if (strcmp(key, "regex") == 0) return (lua_pushboolean(L, is_checked(regex)), 1);
	if (strcmp(key, "in_files") == 0) return (lua_pushboolean(L, is_checked(in_files)), 1);
	if (strcmp(key, "active") == 0) return (lua_pushboolean(L, is_find_active()), 1);
	return (lua_rawget(L, 1), 1);
}

// `find.__newindex` Lua metamethod.
static int find_newindex(lua_State *L) {
	const char *key = lua_tostring(L, 2);
	if (strcmp(key, "find_entry_text") == 0) return (set_find_text(luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "replace_entry_text") == 0) return (set_repl_text(luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "match_case") == 0) return (toggle(match_case, lua_toboolean(L, -1)), 0);
	if (strcmp(key, "whole_word") == 0) return (toggle(whole_word, lua_toboolean(L, -1)), 0);
	if (strcmp(key, "regex") == 0) return (toggle(regex, lua_toboolean(L, -1)), 0);
	if (strcmp(key, "in_files") == 0) return (toggle(in_files, lua_toboolean(L, -1)), 0);
	if (strcmp(key, "find_label_text") == 0) return (set_find_label(luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "replace_label_text") == 0) return (set_repl_label(luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "find_next_button_text") == 0)
		return (set_button_label(find_next, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "find_prev_button_text") == 0)
		return (set_button_label(find_prev, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "replace_button_text") == 0)
		return (set_button_label(replace, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "replace_all_button_text") == 0)
		return (set_button_label(replace_all, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "match_case_label_text") == 0)
		return (set_option_label(match_case, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "whole_word_label_text") == 0)
		return (set_option_label(whole_word, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "regex_label_text") == 0)
		return (set_option_label(regex, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "in_files_label_text") == 0)
		return (set_option_label(in_files, luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "entry_font") == 0) return (set_entry_font(luaL_checkstring(L, 3)), 0);
	return (lua_rawset(L, 1), 0);
}

// `command_entry.focus()` Lua function.
static int focus_command_entry_lua(lua_State *L) { return (focus_command_entry(), 0); }

// Returns whether or not the value on the Lua stack at the given index has a metatable with
// the given name.
static bool is_type(lua_State *L, int index, const char *tname) {
	if (!lua_getmetatable(L, index)) return false;
	bool has_metatable = (luaL_getmetatable(L, tname), lua_rawequal(L, -1, -2));
	return (lua_pop(L, 2), has_metatable); // pop metatable, metatable
}

// Returns the Scintilla document on the Lua stack at the given acceptable index.
static sptr_t lua_todoc(lua_State *L, int index) {
	sptr_t doc = (lua_getfield(L, index, "doc_pointer"), (sptr_t)lua_touserdata(L, -1));
	return (lua_pop(L, 1), doc); // pop doc_pointer
}

// Pushes the given Scintilla document onto the Lua stack.
// The document must have previously been added with `add_doc()`.
static void lua_pushdoc(lua_State *L, sptr_t doc) {
	lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawgetp(L, -1, (sptr_t *)doc),
		lua_replace(L, -2);
}

// Returns a suitable Scintilla view that can operate on the Scintilla document on the Lua
// stack at the given index.
// For non-global, non-command entry documents, loads that document in `dummy_view` (unless
// it is already loaded). Raises and error if the value is not a Scintilla document or if the
// document no longer exists.
static SciObject *view_for_doc(lua_State *L, int index) {
	luaL_argcheck(L, is_type(L, index, "ta_buffer"), index, "Buffer expected");
	sptr_t doc = lua_todoc(L, index);
	if (doc == SS(focused_view, SCI_GETDOCPOINTER, 0, 0)) return focused_view;
	luaL_argcheck(L,
		(lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushdoc(L, doc), lua_gettable(L, -2)), index,
		"this Buffer does not exist"),
		lua_pop(L, 2); // pop buffer, _BUFFERS
	if (doc == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) return command_entry;
	if (doc == SS(dummy_view, SCI_GETDOCPOINTER, 0, 0)) return dummy_view;
	return (SS(dummy_view, SCI_SETDOCPOINTER, 0, doc), dummy_view);
}

// Returns the Scintilla view on the Lua stack at the given acceptable index.
static SciObject *lua_toview(lua_State *L, int index) {
	SciObject *view = (lua_getfield(L, index, "widget_pointer"), lua_touserdata(L, -1));
	return (lua_pop(L, 1), view); // pop widget_pointer
}

// Checks whether the given function argument is of the given Scintilla parameter type and
// returns it in a form suitable for use in a Scintilla message.
static sptr_t luaL_checkscintilla(lua_State *L, int *arg, int type) {
	if (type == SSTRING) return (sptr_t)luaL_checkstring(L, (*arg)++);
	if (type == SBOOL) return lua_toboolean(L, (*arg)++);
	if (type == SINDEX) {
		int i = luaL_checkinteger(L, (*arg)++);
		return i >= 0 ? i - 1 : i; // do not adjust significant values like -1
	} else if (type == SCOLOR) {
		unsigned int color = luaL_checkinteger(L, (*arg)++);
		return color > 0xFFFFFF ? color : color | 0xFF000000; // backward compatibility
	}
	return type >= SINT && type <= SKEYMOD ? luaL_checkinteger(L, (*arg)++) : 0;
}

// Sends a message to the given Scintilla view (i.e. calls a Scintilla function) using the
// given message identifier and parameter types.
// Lua values to pass start at the given Lua stack index. This function does not remove any
// arguments from the stack, but does push results and return the number of results pushed.
static int call_scintilla(
	lua_State *L, SciObject *view, int msg, int wtype, int ltype, int rtype, int arg) {
	uptr_t wparam = 0;
	sptr_t lparam = 0, len = 0;
	int params_needed = 2, nresults = 0;
	bool string_return = false;
	char *text = NULL;

	// Set wParam and lParam appropriately for Scintilla based on wtype and ltype.
	if (wtype == SLEN && ltype == SSTRING)
		wparam = (uptr_t)lua_rawlen(L, arg), lparam = (sptr_t)luaL_checkstring(L, arg),
		params_needed = 0;
	else if (ltype == SSTRINGRET || rtype == SSTRINGRET)
		string_return = true, params_needed = wtype == SLEN ? 0 : 1;
	if (params_needed > 0) wparam = luaL_checkscintilla(L, &arg, wtype);
	if (params_needed > 1) lparam = luaL_checkscintilla(L, &arg, ltype);
	if (string_return) { // create a buffer for the return string
		lparam = (sptr_t)(text = malloc((len = SS(view, msg, wparam, 0)) + 1));
		if (wtype == SLEN) wparam = len;
	}

	// Send the message to Scintilla and return the appropriate values.
	sptr_t result = SS(view, msg, wparam, lparam);
	if (string_return) lua_pushlstring(L, text, len), nresults++, free(text);
	if (rtype == SINDEX && result >= 0) result++;
	if (rtype > SVOID && rtype < SBOOL)
		lua_pushinteger(L, result), nresults++;
	else if (rtype == SBOOL)
		lua_pushboolean(L, result), nresults++;
	return nresults;
}

int get_int_field(lua_State *L, int index, int n) {
	int i = (lua_rawgeti(L, index, n), lua_tointeger(L, -1));
	return (lua_pop(L, 1), i); // pop integer
}

// `buffer:method()` Lua function.
static int call_scintilla_lua(lua_State *L) {
	SciObject *view = focused_view;
	// If optional buffer/view argument is given, check it.
	if (is_type(L, 1, "ta_buffer"))
		view = view_for_doc(L, 1);
	else if (is_type(L, 1, "ta_view"))
		view = lua_toview(L, 1);
	// Interface table is of the form {msg, rtype, wtype, ltype}.
	return call_scintilla(L, view, get_int_field(L, lua_upvalueindex(1), 1),
		get_int_field(L, lua_upvalueindex(1), 3), get_int_field(L, lua_upvalueindex(1), 4),
		get_int_field(L, lua_upvalueindex(1), 2), lua_istable(L, 1) ? 2 : 1);
}

// Sets the metatable for the value at the given Lua stack index to be the given metatable.
// Creates the metatable with the given __index and __newindex functions if necessary.
static void set_metatable(
	lua_State *L, int index, const char *name, lua_CFunction __index, lua_CFunction __newindex) {
	if (luaL_newmetatable(L, name))
		lua_pushcfunction(L, __index), lua_setfield(L, -2, "__index"), lua_pushcfunction(L, __newindex),
			lua_setfield(L, -2, "__newindex");
	lua_setmetatable(L, index > 0 ? index : index - 1);
}

// `buffer[k].__index` metamethod.
static int property_index(lua_State *L) {
	bool not_view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view"));
	SciObject *view = not_view ? view_for_doc(L, -1) : lua_toview(L, -1);
	lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
	int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4), ltype = SVOID,
			rtype = get_int_field(L, -1, 3);
	luaL_argcheck(L, msg, 2, "write-only property");
	return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 1);
}

// `buffer[k].__newindex` metamethod.
static int property_newindex(lua_State *L) {
	bool not_view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view"));
	SciObject *view = not_view ? view_for_doc(L, -1) : lua_toview(L, -1);
	lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
	int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 4),
			ltype = get_int_field(L, -1, 3), rtype = SVOID;
	luaL_argcheck(L, msg, 3, "read-only property");
	if (ltype == SSTRINGRET) ltype = SSTRING;
	return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 0);
}

// Helper function for `buffer_index()` and `view_index()` that gets Scintilla properties.
static void get_property(lua_State *L) {
	SciObject *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) : lua_toview(L, 1);
	// Interface table is of the form {get_id, set_id, rtype, wtype}.
	int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4), ltype = SVOID,
			rtype = get_int_field(L, -1, 3);
	luaL_argcheck(L, msg || wtype != SVOID, 2, "write-only property");
	if (wtype != SVOID) { // indexible property
		// return setmetatable({_self = view, _iface = {...}}, {__index = index, __newindex = newindex})
		lua_createtable(L, 0, 2);
		lua_pushvalue(L, 1), lua_setfield(L, -2, "_self");
		lua_pushvalue(L, -2), lua_setfield(L, -2, "_iface");
		set_metatable(L, -1, "ta_property", property_index, property_newindex);
	} else
		call_scintilla(L, view, msg, wtype, ltype, rtype, 2);
}

// `buffer.__index` metamethod.
static int buffer_index(lua_State *L) {
	if (lua_getglobal(L, "_SCINTILLA"), lua_pushvalue(L, 2), lua_rawget(L, -2)) {
		if (lua_type(L, -1) != LUA_TTABLE) return 1; // constant
		// If the key is a Scintilla function (4 iface values), return a callable closure.
		// If the key is a Scintilla property, determine if it is an indexible one or not. If so,
		// return a table with the appropriate metatable; otherwise call Scintilla to get the
		// property's value.
		return (
			lua_rawlen(L, -1) == 4 ? lua_pushcclosure(L, call_scintilla_lua, 1) : get_property(L), 1);
	}
	if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
		lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
		return luaL_argerror(L, 3, "write-only property");
	if (strcmp(lua_tostring(L, 2), "active") == 0 &&
		lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
		return (lua_pushboolean(L, is_command_entry_active()), 1);
	if (strcmp(lua_tostring(L, 2), "height") == 0 &&
		lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
		return (lua_pushinteger(L, get_command_entry_height()), 1);
	return (lua_settop(L, 2), lua_rawget(L, 1), 1);
}

// Helper function for `buffer_newindex()` and `view_newindex()` that sets Scintilla properties.
static void set_property(lua_State *L) {
	SciObject *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) : lua_toview(L, 1);
	// Interface table is of the form {get_id, set_id, wtype, ltype}.
	int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 3),
			ltype = get_int_field(L, -1, 4), rtype = SVOID, temp;
	luaL_argcheck(L, msg && ltype == SVOID, 3, "read-only property");
	if (wtype == SSTRING || wtype == SSTRINGRET || msg == SCI_SETMARGINLEFT ||
		msg == SCI_SETMARGINRIGHT)
		temp = wtype != SSTRINGRET ? wtype : SSTRING, wtype = ltype, ltype = temp;
	call_scintilla(L, view, msg, wtype, ltype, rtype, 3);
}

// `buffer.__newindex` metamethod.
static int buffer_newindex(lua_State *L) {
	// If the key is a Scintilla property (more than 4 iface values), call Scintilla to set its value.
	if (lua_getglobal(L, "_SCINTILLA"), lua_pushvalue(L, 2),
		lua_rawget(L, -2) == LUA_TTABLE && lua_rawlen(L, -1) > 4)
		return (set_property(L), 0);
	if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
		lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
		return (set_tab_label((lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushvalue(L, 1),
														lua_gettable(L, -2), lua_tointeger(L, -1) - 1),
							luaL_checkstring(L, 3)),
			0);
	if (strcmp(lua_tostring(L, 2), "height") == 0 &&
		lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
		return (set_command_entry_height(
							fmax(luaL_checkinteger(L, 3), SS(command_entry, SCI_TEXTHEIGHT, 0, 0))),
			0);
	return (lua_settop(L, 3), lua_rawset(L, 1), 0);
}

// Returns a DialogOptions constructed from the table at the top of the Lua stack.
// If no buttons are specified, uses the given one.
static DialogOptions read_opts(lua_State *L, const char *button) {
#define strf(k) (lua_getfield(L, 1, k), lua_tostring(L, -1))
#define boolf(k) (lua_getfield(L, 1, k), lua_toboolean(L, -1))
#define tablef(k) (lua_getfield(L, 1, k) == LUA_TTABLE ? lua_absindex(L, -1) : 0)
#define intf(k) (lua_getfield(L, 1, k), fmax(lua_tointeger(L, -1), 0))
	lua_checkstack(L, LUA_MINSTACK + 20); // dialog options persist on the stack
	DialogOptions opts = {strf("title"), strf("text"), strf("icon"),
		{strf("button1"), strf("button2"), strf("button3")}, strf("dir"), strf("file"),
		boolf("only_dirs"), boolf("multiple"), boolf("return_button"), tablef("columns"),
		intf("search_column"), tablef("items")};
	if (!opts.buttons[0] && button) // localize default button, e.g. _L['OK']
		opts.buttons[0] = (lua_getglobal(L, "_L"), lua_getfield(L, -1, button), lua_tostring(L, -1));
	return opts;
}

// `ui.dialogs.message()` Lua function.
static int message_dialog_lua(lua_State *L) { return message_dialog(read_opts(L, "OK"), L); }

// `ui.dialogs.input()` Lua function.
static int input_dialog_lua(lua_State *L) {
	DialogOptions opts = read_opts(L, "OK");
	if (!opts.buttons[1]) // add localized cancel button, _L['Cancel']
		opts.buttons[1] = (lua_getglobal(L, "_L"), lua_getfield(L, -1, "Cancel"), lua_tostring(L, -1));
	return input_dialog(opts, L);
}

// `ui.dialogs.open()` Lua function.
static int open_dialog_lua(lua_State *L) { return open_dialog(read_opts(L, NULL), L); }

// `ui.dialogs.save()` Lua function.
static int save_dialog_lua(lua_State *L) { return save_dialog(read_opts(L, NULL), L); }

// Calls the work function passed to `ui.dialogs.progress()`, passes intermediate progress to
// the given callback function, and returns true if there is still work to be done.
// This function is passed to the platform-defined `progress_dialog()` function. The platform
// should repeatedly call this function for as long as it returns true.
static bool do_work(void (*update)(double, const char *, void *), void *userdata) {
	lua_getfield(lua, LUA_REGISTRYINDEX, "ta_update");
	bool ok = lua_pcall(lua, 0, 2, 0) == LUA_OK, repeat = ok && lua_isnumber(lua, -2);
	if (repeat)
		return (update(lua_tonumber(lua, -2), lua_tostring(lua, -1), userdata), lua_pop(lua, 2), true);
	if (!ok) emit("error", LUA_TSTRING, lua_tostring(lua, -1), -1);
	return (lua_pushnil(lua), lua_setfield(lua, LUA_REGISTRYINDEX, "ta_update"),
		lua_pop(lua, ok ? 2 : 1), false); // pop results
}

// `ui.dialogs.progress()` Lua function.
static int progress_dialog_lua(lua_State *L) {
	DialogOptions opts = read_opts(L, "Stop");
	luaL_argcheck(L, lua_getfield(L, 1, "work") == LUA_TFUNCTION, 1, "'work' function expected"),
		lua_setfield(L, LUA_REGISTRYINDEX, "ta_update");
	return progress_dialog(opts, L, do_work);
}

// `ui.dialogs.list()` Lua function.
static int list_dialog_lua(lua_State *L) {
	DialogOptions opts = read_opts(L, "OK");
	int num_columns = opts.columns ? lua_rawlen(L, opts.columns) : 1;
	if (!opts.search_column) opts.search_column = 1;
	luaL_argcheck(
		L, opts.search_column > 0 && opts.search_column <= num_columns, 1, "invalid 'search_column'");
	luaL_argcheck(
		L, opts.items && lua_rawlen(L, opts.items) > 0, 1, "non-empty 'items' table expected");
	if (!opts.buttons[1]) // add localized cancel button, _L['Cancel']
		opts.buttons[1] = (lua_getglobal(L, "_L"), lua_getfield(L, -1, "Cancel"), lua_tostring(L, -1));
	return list_dialog(opts, L);
}

// Pushes the given Scintilla view onto the Lua stack.
// The view must have previously been added with `add_view()`.
static void lua_pushview(lua_State *L, SciObject *view) {
	lua_getfield(L, LUA_REGISTRYINDEX, VIEWS), lua_rawgetp(L, -1, view), lua_replace(L, -2);
}

// Pushes onto the Lua stack the given pane, which may contain a Scintilla view or split views.
static void lua_pushsplit(lua_State *L, Pane *pane) {
	PaneInfo info = get_pane_info(pane);
	if (info.is_split) {
		lua_newtable(L);
		lua_pushsplit(L, info.child1), lua_rawseti(L, -2, 1);
		lua_pushsplit(L, info.child2), lua_rawseti(L, -2, 2);
		lua_pushboolean(L, info.vertical), lua_setfield(L, -2, "vertical");
		lua_pushinteger(L, info.size), lua_setfield(L, -2, "size");
	} else
		lua_pushview(L, info.view);
}

// `ui.get_split_table()` Lua function.
static int get_split_table(lua_State *L) { return (lua_pushsplit(L, get_top_pane()), 1); }

// Checks whether the given function argument is a Scintilla view and returns it.
static SciObject *luaL_checkview(lua_State *L, int arg) {
	return (luaL_argcheck(L, is_type(L, arg, "ta_view"), arg, "View expected"), lua_toview(L, arg));
}

// `ui.goto_view()` Lua function.
static int goto_view(lua_State *L) {
	if (!lua_isnumber(L, 1)) return (focus_view(luaL_checkview(L, 1)), 0);
	lua_getfield(L, LUA_REGISTRYINDEX, VIEWS);
	// i = _VIEWS[view], i = (i + n) % #_VIEWS, _VIEWS[i]
	int i = (lua_pushview(L, focused_view), lua_gettable(L, -2), lua_tointeger(L, -1));
	if ((i = (i + lua_tointeger(L, 1)) % lua_rawlen(L, -2)) == 0) i = lua_rawlen(L, -2);
	return (lua_rawgeti(L, -2, i), focus_view(lua_toview(L, -1)), 0);
}

// `ui.menu()` Lua function.
static int menu(lua_State *L) {
	return (lua_pushlightuserdata(L, (luaL_checktype(L, 1, LUA_TTABLE), read_menu(L, 1))), 1);
}

// `ui.popup_menu()` Lua function.
static int popup_menu_lua(lua_State *L) {
	luaL_argcheck(L, lua_type(L, 1) == LUA_TLIGHTUSERDATA, 1, "menu expected");
	return (popup_menu(lua_touserdata(L, 1), NULL), 0);
}

// `ui.update()` Lua function.
static int update_ui_lua(lua_State *L) { return (update_ui(), 0); }

// `ui.suspend()` Lua function.
static int suspend_lua(lua_State *L) { return (suspend(), 0); }

// `ui.__index` Lua metamethod.
static int ui_index(lua_State *L) {
	const char *key = lua_tostring(L, 2);
	if (strcmp(key, "clipboard_text") == 0) {
		int len;
		char *text = get_clipboard_text(&len);
		if (text) return (lua_pushlstring(L, text, len), free(text), 1);
		return (lua_pushliteral(L, ""), 1);
	}
	if (strcmp(key, "maximized") == 0) return (lua_pushboolean(L, is_maximized()), 1);
	if (strcmp(key, "size") == 0) {
		int width, height;
		get_size(&width, &height);
		return (lua_createtable(L, 2, 0), lua_pushinteger(L, width), lua_rawseti(L, -2, 1),
			lua_pushinteger(L, height), lua_rawseti(L, -2, 2), 1); // {[1] = width, [2] = height}
	}
	if (strcmp(key, "tabs") == 0)
		return (tabs <= 1 ? lua_pushboolean(L, tabs) : lua_pushinteger(L, tabs), 1);
	return (lua_rawget(L, 1), 1);
}

// `ui.__newindex` Lua metatable.
static int ui_newindex(lua_State *L) {
	const char *key = lua_tostring(L, 2);
	if (strcmp(key, "title") == 0) return (set_title(lua_tostring(L, 3)), 0);
	if (strcmp(key, "clipboard_text") == 0)
		return (SS(focused_view, SCI_COPYTEXT, lua_rawlen(L, 3), (sptr_t)luaL_checkstring(L, 3)), 0);
	if (strcmp(key, "statusbar_text") == 0 || strcmp(key, "buffer_statusbar_text") == 0)
		return (set_statusbar_text(*key == 's' ? 0 : 1, lua_tostring(L, 3)), 0);
	if (strcmp(key, "menubar") == 0) {
		luaL_argcheck(L, lua_istable(L, 3), 3, "table of menus expected");
		for (size_t i = 1; i <= lua_rawlen(L, 3); lua_pop(L, 1), i++)
			luaL_argcheck(L, lua_rawgeti(L, 3, i) == LUA_TLIGHTUSERDATA, 3, "table of menus expected");
		return (set_menubar(L, 3), 0);
	}
	if (strcmp(key, "maximized") == 0) return (set_maximized(lua_toboolean(L, 3)), 0);
	if (strcmp(key, "size") == 0) {
		luaL_argcheck(
			L, lua_istable(L, 3) && lua_rawlen(L, 3) == 2, 3, "{width, height} table expected");
		int width = get_int_field(L, 3, 1), height = get_int_field(L, 3, 2);
		luaL_argcheck(L, width > 0 && height > 0, 3, "width and height must be greater than zero");
		return (set_size(width, height), 0);
	}
	if (strcmp(key, "tabs") == 0)
		return (show_tabs((tabs = !lua_isinteger(L, 3) ? lua_toboolean(L, 3) : lua_tointeger(L, 3)) &&
							((lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawlen(L, -1)) > 1 || tabs > 1)),
			0);
	return (lua_rawset(L, 1), 0);
}

void move_buffer(int from, int to, bool reorder_tabs) {
	lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
	// table.insert(_BUFFERS, to, table.remove(_BUFFERS, from)
	lua_getglobal(lua, "table"), lua_getfield(lua, -1, "insert"), lua_replace(lua, -2),
		lua_pushvalue(lua, -2), lua_pushinteger(lua, to), lua_getglobal(lua, "table"),
		lua_getfield(lua, -1, "remove"), lua_replace(lua, -2), lua_pushvalue(lua, -5),
		lua_pushinteger(lua, from), lua_call(lua, 2, 1), lua_call(lua, 3, 0);
	// for i = 1, #_BUFFERS do _BUFFERS[_BUFFERS[i]] = i end
	for (size_t i = 1; i <= lua_rawlen(lua, -1); i++)
		lua_rawgeti(lua, -1, i), lua_pushinteger(lua, i), lua_rawset(lua, -3);
	if (lua_pop(lua, 1), reorder_tabs) move_tab(from - 1, to - 1); // pop _BUFFERS
}

// `_G.move_buffer` Lua function.
static int move_buffer_lua(lua_State *L) {
	int from = luaL_checkinteger(L, 1), to = luaL_checkinteger(L, 2);
	lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
	luaL_argcheck(L, from >= 1 && (size_t)from <= lua_rawlen(L, -1), 1, "position out of bounds");
	luaL_argcheck(L, to >= 1 && (size_t)to <= lua_rawlen(L, -1), 2, "position out of bounds");
	return (move_buffer(from, to, true), 0);
}

// Note: lua may be NULL, e.g. Qt session manager doing odd things on logout/restart while
// Textadept is still running.
bool can_quit(void) { return closing || !lua || !emit("quit", -1); }

// `_G.quit()` Lua function.
static int quit_lua(lua_State *L) {
	if ((lua_isnone(L, 2) || lua_toboolean(L, 2)) && !can_quit()) return 0;
	return (closing = true, quit(), exit_status = luaL_optnumber(L, 1, 0), 0);
}

// Runs the given Lua file, which is relative to `textadept_home`, and returns `true` on success.
// If there are errors, shows an error dialog and returns `false`.
static bool run_file(const char *filename) {
	char *file = malloc(strlen(textadept_home) + 1 + strlen(filename) + 1);
	sprintf(file, "%s/%s", textadept_home, filename);
	bool ok = luaL_dofile(lua, file) == LUA_OK;
	if (!ok) show_error("Initialization Error", lua_tostring(lua, -1)), lua_settop(lua, 0);
	return (free(file), ok);
}

// `_G.reset()` Lua function.
static int reset(lua_State *L) {
	int persist_ref = (lua_newtable(L), luaL_ref(L, LUA_REGISTRYINDEX));
	emit("reset_before", LUA_TTABLE,
		(lua_rawgeti(L, LUA_REGISTRYINDEX, persist_ref), luaL_ref(L, LUA_REGISTRYINDEX)), -1);
	init_lua(0, NULL);
	lua_pushview(L, focused_view), lua_setglobal(L, "view");
	lua_pushdoc(L, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(L, "buffer");
	lua_pushnil(L), lua_setglobal(L, "arg");
	run_file("init.lua"), emit("initialized", -1);
	lua_getfield(L, LUA_REGISTRYINDEX, ARG), lua_setglobal(L, "arg");
	return (emit("reset_after", LUA_TTABLE, persist_ref, -1), 0); // emit will unref
}

// Calls the given timeout function passed to `_G.timeout()`.
// Platforms should repeatedly call this function when the timeout interval has passed for as
// long as it returns true.
static bool call_timeout_function(int *refs) {
	int nargs = 0;
	lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
	while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
	bool ok = lua_pcall(lua, nargs - 1, 1, 0) == LUA_OK, repeat = ok && lua_toboolean(lua, -1);
	if (repeat) return (lua_pop(lua, 1), true); // pop result
	if (!ok) emit("error", LUA_TSTRING, lua_tostring(lua, -1), -1);
	while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
	return (free(refs), lua_pop(lua, 1), false); // pop result
}

// `_G.timeout()` Lua function.
static int add_timeout_lua(lua_State *L) {
	double interval = luaL_checknumber(L, 1);
	luaL_argcheck(L, interval > 0, 1, "interval must be > 0"), luaL_checktype(L, 2, LUA_TFUNCTION);
	int n = lua_gettop(L), *refs = calloc(n, sizeof(int));
	for (int i = 2; i <= n; i++) lua_pushvalue(L, i), refs[i - 2] = luaL_ref(L, LUA_REGISTRYINDEX);
	return (add_timeout(interval, call_timeout_function, refs), 0);
}

// Initializes or re-initializes the Lua state and with the given command-line arguments.
// Populates the state with global variables and functions, runs the 'core/init.lua' script,
// and returns `true` on success.
static bool init_lua(int argc, char **argv) {
	lua_State *L = !lua ? luaL_newstate() : lua;
	if (!lua) {
		lua_createtable(L, argc, 0);
		for (int i = 0; i < argc; i++) lua_pushstring(L, argv[i]), lua_rawseti(L, -2, i);
		lua_setfield(L, LUA_REGISTRYINDEX, ARG);
		lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, BUFFERS);
		lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, VIEWS);
	} else {
		// Clear package.loaded and _G.
		lua_getfield(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
		while (lua_pushnil(L), lua_next(L, -2)) lua_pushnil(L), lua_replace(L, -2), lua_rawset(L, -3);
		lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
		while (lua_pushnil(L), lua_next(L, -2)) lua_pushnil(L), lua_replace(L, -2), lua_rawset(L, -3);
		lua_pop(L, 2); // package.loaded, _G
		lua_gc(L, LUA_GCCOLLECT, 0);
	}
	luaL_openlibs(L);
	luaL_requiref(L, "lpeg", luaopen_lpeg, 1), lua_pop(L, 1);
	luaL_requiref(L, "lfs", luaopen_lfs, 1), lua_pop(L, 1);
	luaL_requiref(L, "regex", luaopen_regex, 1), lua_pop(L, 1);

	// Check for invoking Textadept as a Lua interpreter.
	for (int i = 0; i < argc; i++)
		if ((strcmp("-L", argv[i]) == 0 || strcmp("--lua", argv[i]) == 0) && i + 1 < argc) {
#if _WIN32
			if (AllocConsole()) ShowWindow(GetConsoleWindow(), SW_HIDE);
#endif
			int n = i + 1; // shift all elements of arg down by n
			// arg = table.move(arg, 0, #len + n, -n)
			lua_getglobal(L, "table"), lua_getfield(L, -1, "move"),
				lua_getfield(L, LUA_REGISTRYINDEX, ARG), lua_pushinteger(L, 0),
				lua_pushinteger(L, luaL_len(L, -2) + n), lua_pushinteger(L, -n), lua_call(L, 4, 1),
				lua_setglobal(L, "arg");
			bool ok = luaL_dofile(L, argv[i + 1]) == LUA_OK;
			if (!ok) fprintf(stderr, "%s\n", lua_tostring(L, -1));
			return (lua_close(L), lua = NULL, exit_status = ok ? 0 : 1, false);
		}

	lua_getglobal(L, "string"), lua_pushcfunction(L, iconv_lua), lua_setfield(L, -2, "iconv"),
		lua_pop(L, 1); // string.iconv
	lua_getglobal(L, "os"), lua_pushcfunction(L, spawn_lua), lua_setfield(L, -2, "spawn"),
		lua_pop(L, 1); // os.spawn

	lua_newtable(L), lua_newtable(L); // ui, ui.find
	lua_pushcfunction(L, click_find_next), lua_setfield(L, -2, "find_next");
	lua_pushcfunction(L, click_find_prev), lua_setfield(L, -2, "find_prev");
	lua_pushcfunction(L, click_replace), lua_setfield(L, -2, "replace");
	lua_pushcfunction(L, click_replace_all), lua_setfield(L, -2, "replace_all");
	lua_pushcfunction(L, focus_find_lua), lua_setfield(L, -2, "focus");
	set_metatable(L, -1, "ta_find", find_index, find_newindex), lua_setfield(L, -2, "find");
	if (!lua) {
		lua_newtable(L); // ui.command_entry
		lua_pushcfunction(L, focus_command_entry_lua), lua_setfield(L, -2, "focus");
		set_metatable(L, -1, "ta_buffer", buffer_index, buffer_newindex);
	} else
		lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawgeti(L, -1, 0),
			lua_replace(L, -2); // _BUFFERS[0] is the command_entry
	lua_setfield(L, -2, "command_entry");
	lua_newtable(L); // ui.dialogs
	lua_pushcfunction(L, message_dialog_lua), lua_setfield(L, -2, "message");
	lua_pushcfunction(L, input_dialog_lua), lua_setfield(L, -2, "input");
	lua_pushcfunction(L, open_dialog_lua), lua_setfield(L, -2, "open");
	lua_pushcfunction(L, save_dialog_lua), lua_setfield(L, -2, "save");
	lua_pushcfunction(L, progress_dialog_lua), lua_setfield(L, -2, "progress");
	lua_pushcfunction(L, list_dialog_lua), lua_setfield(L, -2, "list");
	lua_setfield(L, -2, "dialogs");
	lua_pushcfunction(L, get_split_table), lua_setfield(L, -2, "get_split_table");
	lua_pushcfunction(L, goto_view), lua_setfield(L, -2, "goto_view");
	lua_pushcfunction(L, menu), lua_setfield(L, -2, "menu");
	lua_pushcfunction(L, popup_menu_lua), lua_setfield(L, -2, "popup_menu");
	lua_pushcfunction(L, update_ui_lua), lua_setfield(L, -2, "update");
	lua_pushcfunction(L, suspend_lua), lua_setfield(L, -2, "suspend");
	set_metatable(L, -1, "ta_ui", ui_index, ui_newindex), lua_setglobal(L, "ui");

	// _G
	lua_getfield(L, LUA_REGISTRYINDEX, ARG), lua_setglobal(L, "arg");
	lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_setglobal(L, "_BUFFERS");
	lua_getfield(L, LUA_REGISTRYINDEX, VIEWS), lua_setglobal(L, "_VIEWS");
	lua_pushstring(L, textadept_home), lua_setglobal(L, "_HOME");
	lua_pushboolean(L, true), lua_setglobal(L, os);
	lua_pushboolean(L, true), lua_setglobal(L, get_platform());
	lua_pushstring(L, get_charset()), lua_setglobal(L, "_CHARSET");
	lua_pushstring(L, !is_dark_mode() ? "light" : "dark"), lua_setglobal(L, "_THEME");
	lua_pushcfunction(L, move_buffer_lua), lua_setglobal(L, "move_buffer");
	lua_pushcfunction(L, quit_lua), lua_setglobal(L, "quit");
	lua_pushcfunction(L, reset), lua_setglobal(L, "reset");
	lua_pushcfunction(L, add_timeout_lua), lua_setglobal(L, "timeout");

	if (lua = L, !run_file("core/init.lua"))
		return (lua_close(L), lua = NULL, exit_status = 1, false);
	return (exit_status = 0, true);
}

// Synchronizes the tabbar after switching between Scintilla views or documents.
static void sync_tabbar(void) {
	set_tab((lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS),
		lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(lua, -2),
		lua_replace(lua, -2), lua_tointeger(lua, -1) - 1)), // _BUFFERS[buffer]
		lua_pop(lua, 1); // pop index
}

// Signal that focus has changed to the given Scintilla view.
// Generates 'view_before_switch' and 'view_after_switch' events.
static void view_focused(SciObject *view) {
	if (!initing && !closing) emit("view_before_switch", -1);
	lua_pushview(lua, focused_view = view), lua_setglobal(lua, "view"), sync_tabbar();
	lua_pushdoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
	if (!initing && !closing) emit("view_after_switch", -1);
}

// Emits the given Scintilla notification to Lua.
static void emit_notification(SCNotification *n) {
	if (n->nmhdr.code == SCN_KEY) return; // platforms are handling key events; avoid duplicates
	lua_newtable(lua);
	lua_pushinteger(lua, n->nmhdr.code), lua_setfield(lua, -2, "code");
	lua_pushinteger(lua, n->position + 1), lua_setfield(lua, -2, "position");
	lua_pushinteger(lua, n->ch), lua_setfield(lua, -2, "ch");
	lua_pushinteger(lua, n->modifiers), lua_setfield(lua, -2, "modifiers");
	lua_pushinteger(lua, n->modificationType), lua_setfield(lua, -2, "modification_type");
	if (n->text)
		lua_pushlstring(lua, n->text, n->length ? (size_t)n->length : strlen(n->text)),
			lua_setfield(lua, -2, "text");
	lua_pushinteger(lua, n->length), lua_setfield(lua, -2, "length");
	lua_pushinteger(lua, n->linesAdded), lua_setfield(lua, -2, "lines_added");
	// lua_pushinteger(lua, n->message), lua_setfield(lua, -2, "message");
	// lua_pushinteger(lua, n->wParam), lua_setfield(lua, -2, "wParam");
	// lua_pushinteger(lua, n->lParam), lua_setfield(lua, -2, "lParam");
	lua_pushinteger(lua, n->line + 1), lua_setfield(lua, -2, "line");
	// lua_pushinteger(lua, n->foldLevelNow), lua_setfield(lua, -2, "fold_level_now");
	// lua_pushinteger(lua, n->foldLevelPrev), lua_setfield(lua, -2, "fold_level_prev");
	lua_pushinteger(lua, n->margin + 1), lua_setfield(lua, -2, "margin");
	lua_pushinteger(lua, n->listType), lua_setfield(lua, -2, "list_type");
	lua_pushinteger(lua, n->x), lua_setfield(lua, -2, "x");
	lua_pushinteger(lua, n->y), lua_setfield(lua, -2, "y");
	// lua_pushinteger(lua, n->token), lua_setfield(lua, -2, "token");
	// lua_pushinteger(lua, n->annotationLinesAdded), lua_setfield(lua, -2, "annotation_lines_added");
	lua_pushinteger(lua, n->updated), lua_setfield(lua, -2, "updated");
	// lua_pushinteger(lua, n->listCompletionMethod), lua_setfield(lua, -2, "list_completion_method");
	// lua_pushinteger(lua, n->characterSource), lua_setfield(lua, -2, "character_source");
	emit("SCN", LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
}

// Signal for a Scintilla notification.
static void notified(SciObject *view, int _, SCNotification *n, void *__) {
	if (n->nmhdr.code == SCN_STYLENEEDED)
		emit("style_needed", LUA_TNUMBER, n->position + 1, LUA_TTABLE,
			(lua_pushdoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0)), luaL_ref(lua, LUA_REGISTRYINDEX)), -1);
	else if (view == command_entry) {
		if (n->nmhdr.code == SCN_MODIFIED &&
			(n->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT)))
			emit("command_text_changed", -1);
		else if (n->nmhdr.code == SCN_FOCUSOUT) // TODO: do not emit if Esc triggered this
			emit("key", LUA_TNUMBER, SCK_ESCAPE, LUA_TNUMBER, 0, -1);
	} else if (view == focused_view || n->nmhdr.code == SCN_URIDROPPED) {
		if (view != focused_view) view_focused(view);
		emit_notification(n);
	} else if (n->nmhdr.code == SCN_FOCUSIN)
		view_focused(view);
}

// Switches, in the given view, to a Scintilla document at a relative or absolute index.
// An absolute value of -1 represents the last document.
static void goto_doc(lua_State *L, SciObject *view, int n, bool relative) {
	if (relative && n == 0) return;
	lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS);
	if (relative) {
		// i = _BUFFERS[buffer], i = (i + n) % #_BUFFERS, _BUFFERS[i]
		int i = (lua_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(L, -2),
			lua_tointeger(L, -1));
		if (lua_pop(L, 1), (i = (i + n) % lua_rawlen(L, -1)) == 0) i = lua_rawlen(L, -1); // pop index
		lua_rawgeti(L, -1, i), lua_replace(L, -2);
	} else
		lua_rawgeti(L, -1, n > 0 ? n : (int)lua_rawlen(L, -1)), lua_replace(L, -2);
	luaL_argcheck(L, !lua_isnil(L, -1), 2, "no Buffer exists at that index");
	SS(view, SCI_SETDOCPOINTER, 0, lua_todoc(L, -1)), lua_setglobal(L, "buffer"), sync_tabbar();
}

// Adds to Lua either a newly created Scintilla document, or the first Scintilla view's
// preexisting document.
// Generates 'buffer_before_switch' and 'buffer_new' events.
static void new_buffer(sptr_t doc) {
	if (!doc) {
		emit("buffer_before_switch", -1);
		add_doc(doc = SS(focused_view, SCI_CREATEDOCUMENT, 0, 0));
		goto_doc(lua, focused_view, -1, false);
	} else
		add_doc(doc), SS(focused_view, SCI_ADDREFDOCUMENT, 0, doc);
	lua_pushdoc(lua, doc), lua_setglobal(lua, "buffer");
	int n = (lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS), lua_rawlen(lua, -1));
	add_tab(), show_tabs(tabs && ((lua_pop(lua, 1), n) > 1 || tabs > 1)); // pop _BUFFERS
	if (!initing) emit("buffer_new", -1);
}

// Removes the given Scintilla document from the 'buffers' Lua registry table.
// The document must have been previously added with `add_doc()`.
// It is removed from any other views showing it first. Therefore, ensure the length of '_BUFFERS'
// is more than one unless quitting the application.
// Generates a 'buffer_deleted' event.
static void remove_doc(sptr_t doc) {
	lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
	for (lua_pushnil(lua); lua_next(lua, -2); lua_pop(lua, 1))
		if (lua_isnumber(lua, -2) && doc == SS(lua_toview(lua, -1), SCI_GETDOCPOINTER, 0, 0))
			goto_doc(lua, lua_toview(lua, -1), -1, true);
	if (doc == SS(dummy_view, SCI_GETDOCPOINTER, 0, 0)) SS(dummy_view, SCI_SETDOCPOINTER, 0, 0);
	lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS), lua_replace(lua, -2); // replaces _VIEWS
	for (size_t i = 1; i <= lua_rawlen(lua, -1); lua_pop(lua, 1), i++)
		if (doc == (lua_rawgeti(lua, -1, i), lua_todoc(lua, -1))) { // popped on loop
			// _BUFFERS[buffer] = nil, _BUFFERS[buffer.doc_pointer] = nil, table.remove(_BUFFERS, i)
			lua_pushnil(lua), lua_rawset(lua, -3);
			lua_pushnil(lua), lua_rawsetp(lua, -2, (sptr_t *)doc);
			lua_getglobal(lua, "table"), lua_getfield(lua, -1, "remove"), lua_replace(lua, -2),
				lua_pushvalue(lua, -2), lua_pushinteger(lua, i), lua_call(lua, 2, !closing ? 1 : 0);
			// Save the removed buffer for use in the 'buffer_deleted' event (remove its metatable first).
			if (!closing) lua_pushnil(lua), lua_setmetatable(lua, -2), lua_insert(lua, -2);
			// for j = 1, #_BUFFERS do _BUFFERS[_BUFFERS[j]] = j end
			for (size_t j = 1; j <= lua_rawlen(lua, -1); j++)
				lua_rawgeti(lua, -1, j), lua_pushinteger(lua, j), lua_rawset(lua, -3);
			remove_tab(i - 1), show_tabs(tabs && (lua_rawlen(lua, -1) > 1 || tabs > 1));
			break;
		}
	lua_pop(lua, 1); // pop _BUFFERS
	if (!closing) emit("buffer_deleted", LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
}

// Removes the given Scintilla document from the current Scintilla view.
static void delete_buffer(sptr_t doc) {
	remove_doc(doc), SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

// `buffer.delete()` Lua function.
static int delete_buffer_lua(lua_State *L) {
	SciObject *view = view_for_doc(L, 1);
	luaL_argcheck(L, view != command_entry, 1, "cannot delete command entry");
	sptr_t doc = SS(view, SCI_GETDOCPOINTER, 0, 0);
	if (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawlen(L, -1) == 1) new_buffer(0);
	if (view == focused_view) goto_doc(L, focused_view, -1, true);
	delete_buffer(doc);
	if (view == focused_view) emit("buffer_after_switch", -1);
	return 0;
}

// `_G.buffer_new()` Lua function.
static int new_buffer_lua(lua_State *L) {
	if (initing) return luaL_error(L, "cannot create buffers during initialization");
	new_buffer(0);
	return (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawgeti(L, -1, lua_rawlen(L, -1)), 1);
}

// Adds the given Scintilla document along with a metatable to the 'buffers' Lua registry table.
// If the document is 0, adds the command entry's document at a constant index (0).
static void add_doc(sptr_t doc) {
	lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
	if (doc) {
		lua_newtable(lua); // buffer = {}
		lua_pushlightuserdata(lua, (sptr_t *)doc), lua_setfield(lua, -2, "doc_pointer");
		lua_pushcfunction(lua, delete_buffer_lua), lua_setfield(lua, -2, "delete");
		lua_pushcfunction(lua, new_buffer_lua), lua_setfield(lua, -2, "new");
		set_metatable(lua, -1, "ta_buffer", buffer_index, buffer_newindex);
	} else
		lua_getglobal(lua, "ui"), lua_getfield(lua, -1, "command_entry"), lua_replace(lua, -2),
			lua_pushstring(lua, "doc_pointer"),
			lua_pushlightuserdata(lua, (sptr_t *)SS(command_entry, SCI_GETDOCPOINTER, 0, 0)),
			lua_rawset(lua, -3); // ui.command_entry.doc_pointer = doc
	// t[buffer.doc_pointer] = buffer, t[doc and #t + 1 or 0] = buffer, t[buffer] = doc and #t or 0
	lua_getfield(lua, -1, "doc_pointer"), lua_pushvalue(lua, -2), lua_rawset(lua, -4);
	lua_pushvalue(lua, -1), lua_rawseti(lua, -3, doc ? lua_rawlen(lua, -3) + 1 : 0);
	lua_pushinteger(lua, doc ? lua_rawlen(lua, -2) : 0), lua_rawset(lua, -3);
	lua_pop(lua, 1); // pop _BUFFERS
}

// `view.goto_buffer()` Lua function.
static int goto_doc_lua(lua_State *L) {
	SciObject *view = luaL_checkview(L, 1), *prev_view = focused_view;
	bool relative = lua_isnumber(L, 2);
	if (!relative)
		lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushvalue(L, 2), lua_gettable(L, -2),
			lua_replace(L, 2), // i = _BUFFERS[buffer]
			luaL_argcheck(L, lua_isnumber(L, 2), 2, "Buffer or relative index expected");
	// If the indexed view is not currently focused, temporarily focus it so `_G.buffer` in
	// handlers is accurate.
	if (view != focused_view) focus_view(view);
	if (!initing) emit("buffer_before_switch", -1);
	goto_doc(L, view, lua_tointeger(L, 2), relative);
	if (!initing) emit("buffer_after_switch", -1);
	if (focused_view != prev_view) focus_view(prev_view);
	return 0;
}

// `view.split()` Lua function.
static int split_view_lua(lua_State *L) {
	SciObject *view = luaL_checkview(L, 1);
	int first_line = SS(view, SCI_GETFIRSTVISIBLELINE, 0, 0),
			x_offset = SS(view, SCI_GETXOFFSET, 0, 0), current_pos = SS(view, SCI_GETCURRENTPOS, 0, 0),
			anchor = SS(view, SCI_GETANCHOR, 0, 0);
	SciObject *view2 = new_view(SS(view, SCI_GETDOCPOINTER, 0, 0));
	split_view(view, view2, lua_toboolean(L, 2)), focus_view(view2), update_ui();
	SS(view2, SCI_SETSEL, anchor, current_pos), SS(view2, SCI_SETFIRSTVISIBLELINE, first_line, 0),
		SS(view2, SCI_SETXOFFSET, x_offset, 0);
	return (lua_pushvalue(L, 1), lua_getglobal(L, "view"), 2); // old, new view
}

// Removes the given Scintilla view from the 'views' Lua registry table.
// The view must have been previously added with `add_view()`.
static void remove_view(SciObject *view) {
	lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
	for (size_t i = 1; i <= lua_rawlen(lua, -1); lua_pop(lua, 1), i++)
		if (view == (lua_rawgeti(lua, -1, i), lua_toview(lua, -1))) { // popped on loop
			// _VIEWS[view] = nil, _VIEWS[view.widget_pointer] = nil, table.remove(_VIEWS, i)
			lua_pushnil(lua), lua_rawset(lua, -3);
			lua_pushnil(lua), lua_rawsetp(lua, -2, view);
			lua_getglobal(lua, "table"), lua_getfield(lua, -1, "remove"), lua_replace(lua, -2),
				lua_pushvalue(lua, -2), lua_pushinteger(lua, i), lua_call(lua, 2, 0);
			// for j = 1, #_VIEWS do _VIEWS[_VIEWS[j]] = j end
			for (size_t j = 1; j <= lua_rawlen(lua, -1); j++)
				lua_rawgeti(lua, -1, j), lua_pushinteger(lua, j), lua_rawset(lua, -3);
			break;
		}
	lua_pop(lua, 1); // pop _VIEWS
}

// Removes the given Scintilla view, typically after unsplitting a pane.
static void delete_view(SciObject *view) { remove_view(view), delete_scintilla(view); }

// `view.unsplit()` Lua function.
static int unsplit_view_lua(lua_State *L) {
	return (lua_pushboolean(L, unsplit_view(luaL_checkview(L, 1), delete_view)), 1);
}

// `view.__index` metamethod.
static int view_index(lua_State *L) {
	if (strcmp(lua_tostring(L, 2), "buffer") == 0)
		return (lua_pushdoc(L, SS(lua_toview(L, 1), SCI_GETDOCPOINTER, 0, 0)), 1);
	if (strcmp(lua_tostring(L, 2), "size") == 0) {
		PaneInfo info = get_pane_info_from_view(lua_toview(L, 1));
		return (info.is_split ? lua_pushinteger(L, info.size) : lua_pushnil(L), 1);
	}
	if (lua_getglobal(L, "_SCINTILLA"), lua_pushvalue(L, 2), lua_rawget(L, -2)) {
		if (lua_type(L, -1) != LUA_TTABLE) return 1; // constant or function
		// If the key is a Scintilla function (4 iface values), return a callable closure.
		// If the key is a Scintilla property, determine if it is an indexible one or not. If so,
		// return a table with the appropriate metatable; otherwise call Scintilla to get the
		// property's value.
		return (
			lua_rawlen(L, -1) == 4 ? lua_pushcclosure(L, call_scintilla_lua, 1) : get_property(L), 1);
	}
	return (lua_settop(L, 2), lua_rawget(L, 1), 1);
}

// `view.__newindex` metamethod.
static int view_newindex(lua_State *L) {
	if (strcmp(lua_tostring(L, 2), "buffer") == 0)
		return (luaL_argerror(L, 2, "read-only property"), 0);
	if (strcmp(lua_tostring(L, 2), "size") == 0) {
		PaneInfo info = get_pane_info_from_view(lua_toview(L, 1));
		if (info.is_split) set_pane_size(info.self, fmax(luaL_checkinteger(L, 3), 0));
		return 0;
	}
	// If the key is a Scintilla property (more than 4 iface values), call Scintilla to set its value.
	if (lua_getglobal(L, "_SCINTILLA"), lua_pushvalue(L, 2),
		lua_rawget(L, -2) == LUA_TTABLE && lua_rawlen(L, -1) > 4)
		return (set_property(L), 0);
	return (lua_settop(L, 3), lua_rawset(L, 1), 0);
}

// Adds the given Scintilla view with a metatable to the 'views' Lua registry table.
static void add_view(SciObject *view) {
	lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
	lua_newtable(lua); // view = {}
	lua_pushlightuserdata(lua, view), lua_setfield(lua, -2, "widget_pointer");
	lua_pushcfunction(lua, goto_doc_lua), lua_setfield(lua, -2, "goto_buffer");
	lua_pushcfunction(lua, split_view_lua), lua_setfield(lua, -2, "split");
	lua_pushcfunction(lua, unsplit_view_lua), lua_setfield(lua, -2, "unsplit");
	set_metatable(lua, -1, "ta_view", view_index, view_newindex);
	// _VIEWS[view.widget_pointer] = view, _VIEWS[#_VIEWS + 1] = view, _VIEWS[view] = #_VIEWS
	lua_pushvalue(lua, -1), lua_rawsetp(lua, -3, view);
	lua_pushvalue(lua, -1), lua_rawseti(lua, -3, lua_rawlen(lua, -3) + 1);
	lua_pushinteger(lua, lua_rawlen(lua, -2)), lua_rawset(lua, -3);
	lua_pop(lua, 1); // pop _VIEWS
}

// Creates, adds to Lua, and returns a Scintilla view with the given Scintilla document to load
// in it.
// The document can only be zero if this is the first Scintilla view being created.
// Generates a 'view_new' event.
static SciObject *new_view(sptr_t doc) {
	SciObject *view = new_scintilla(notified);
	SS(view, SCI_USEPOPUP, SC_POPUP_NEVER, 0);
	add_view(view), lua_pushview(lua, view), lua_setglobal(lua, "view");
	if (doc) SS(view, SCI_SETDOCPOINTER, 0, doc);
	focus_view(view), focused_view = view;
	if (!doc) new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
	if (!initing) emit("view_new", -1);
	return view;
}

// Creates and returns the first Scintilla view when the platform is ready for it.
static SciObject *create_first_view(void) { return new_view(0); }

void close_textadept(void) {
	if (lua) {
		closing = true;
		while (unsplit_view(focused_view, delete_view)) {}
		lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
		for (int i = lua_rawlen(lua, -1); i > 0; lua_pop(lua, 1), i--)
			lua_rawgeti(lua, -1, i), delete_buffer(lua_todoc(lua, -1)); // popped on loop
		delete_scintilla(focused_view), delete_scintilla(command_entry), delete_scintilla(dummy_view);
		lua_close(lua), lua = NULL;
	}
	if (textadept_home) free(textadept_home), textadept_home = NULL;
}

bool init_textadept(int argc, char **argv) {
	char *last_slash = NULL;
	textadept_home = malloc(FILENAME_MAX + 1);
#if __linux__
	textadept_home[readlink("/proc/self/exe", textadept_home, FILENAME_MAX + 1)] = '\0';
	if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
	os = "LINUX";
#elif _WIN32
	GetModuleFileName(NULL, textadept_home, FILENAME_MAX + 1);
	if ((last_slash = strrchr(textadept_home, '\\'))) *last_slash = '\0';
	os = "WIN32";
#elif __APPLE__
	uint32_t size = FILENAME_MAX + 1;
	_NSGetExecutablePath(textadept_home, &size);
	char *p = textadept_home;
	textadept_home = realpath(textadept_home, NULL), free(p);
	p = strstr(textadept_home, "MacOS"), strcpy(p, "Resources\0");
	os = "OSX";
#endif
	if (getenv("TEXTADEPT_HOME")) strcpy(textadept_home, getenv("TEXTADEPT_HOME"));

	setlocale(LC_COLLATE, "C"), setlocale(LC_NUMERIC, "C"); // for Lua
	if (!init_lua(argc, argv)) return (close_textadept(), false); // exit_status has been set
	command_entry = new_scintilla(notified), add_doc(0);
	dummy_view = new_scintilla(notified), SS(dummy_view, SCI_SETMODEVENTMASK, SC_MOD_NONE, 0);
	initing = true, new_window(create_first_view), run_file("init.lua"), initing = false;
	emit("buffer_new", -1), emit("view_new", -1); // first ones
	lua_pushdoc(lua, SS(command_entry, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
	emit("buffer_new", -1), emit("view_new", -1); // command entry
	lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
	return (emit("initialized", -1), true); // ready
}

// Note: this function is entirely dependent on Lua to create `ui.context_menu` and
// `ui.tab_context_menu` on its own.
void show_context_menu(const char *name, void *userdata) {
	if (lua_getglobal(lua, "ui") == LUA_TTABLE && lua_getfield(lua, -1, name) == LUA_TLIGHTUSERDATA)
		popup_menu((lua_replace(lua, -2), lua_touserdata(lua, -1)), userdata);
	lua_pop(lua, 1); // pop menu or non-menu
}

void mode_changed(void) {
	const char *mode = !is_dark_mode() ? "light" : "dark";
	lua_pushstring(lua, mode), lua_setglobal(lua, "_THEME");
	emit("mode_changed", LUA_TSTRING, mode, -1);
}

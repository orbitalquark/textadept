// Copyright 2007-2022 Mitchell. See LICENSE.

#include "textadept.h"

// External dependency includes.
#include "gtdialog.h"
#include "lualib.h" // for luaL_openlibs
#include "lauxlib.h"
#include "Scintillua.h"

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
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

// TODO: ideally would be a function.
#define set_metatable(l, n, name, __index, __newindex) \
  if (luaL_newmetatable(l, name)) \
    lua_pushcfunction(l, __index), lua_setfield(l, -2, "__index"), \
      lua_pushcfunction(l, __newindex), lua_setfield(l, -2, "__newindex"); \
  lua_setmetatable(l, n > 0 ? n : n - 1);

static char *textadept_home, *os;
Scintilla *dummy_view; // for working with documents not shown in an existing view

// Lua objects.
static const char *BUFFERS = "ta_buffers", *VIEWS = "ta_views", *ARG = "ta_arg"; // registry tables
static bool initing, closing;
static int tabs = 1; // int for more options than true/false
enum { SVOID, SINT, SLEN, SINDEX, SCOLOR, SBOOL, SKEYMOD, SSTRING, SSTRINGRET };
LUALIB_API int luaopen_lpeg(lua_State *), luaopen_lfs(lua_State *);

// Forward declarations.
static void new_buffer(sptr_t);
static Scintilla *new_view(sptr_t);
static bool init_lua(int, char **);

bool emit(const char *name, ...) {
  bool ret = false;
  if (lua_getglobal(lua, "events") != LUA_TTABLE) return (lua_pop(lua, 1), ret);
  if (lua_getfield(lua, -1, "emit") != LUA_TFUNCTION) return (lua_pop(lua, 2), ret);
  lua_pushstring(lua, name);
  int n = 1;
  va_list ap;
  va_start(ap, name);
  sptr_t arg;
  for (int type = va_arg(ap, int); type != -1; type = va_arg(ap, int), n++) switch (type) {
    case LUA_TBOOLEAN: lua_pushboolean(lua, va_arg(ap, int)); break;
    case LUA_TNUMBER: lua_pushinteger(lua, va_arg(ap, int)); break;
    case LUA_TSTRING: lua_pushstring(lua, va_arg(ap, char *)); break;
    case LUA_TLIGHTUSERDATA:
    case LUA_TTABLE:
      arg = va_arg(ap, sptr_t);
      lua_rawgeti(lua, LUA_REGISTRYINDEX, arg), luaL_unref(lua, LUA_REGISTRYINDEX, arg);
      break;
    default: lua_pushnil(lua);
    }
  va_end(ap);
  if (lua_pcall(lua, n, 1, 0) != LUA_OK) {
    // An error occurred within `events.emit()` itself, not an event handler.
    const char *argv[] = {"--title", "Error", "--text", lua_tostring(lua, -1)};
    return (free(gtdialog(GTDIALOG_TEXTBOX, 4, argv)), lua_pop(lua, 2), ret); // result, events
  } else
    ret = lua_toboolean(lua, -1);
  return (lua_pop(lua, 2), ret); // result, events
}

void find_clicked(FindButton *button, void *unused) {
  const char *find_text = get_find_text(), *repl_text = get_repl_text();
  if (find_text && !*find_text) return;
  (button == find_next || button == find_prev) ? add_to_find_history(find_text) :
                                                 add_to_repl_history(repl_text);
  if (button == find_next || button == find_prev)
    emit("find", LUA_TSTRING, find_text, LUA_TBOOLEAN, button == find_next, -1);
  else if (button == replace) {
    emit("replace", LUA_TSTRING, repl_text, -1);
    emit("find", LUA_TSTRING, find_text, LUA_TBOOLEAN, true, -1);
  } else if (button == replace_all)
    emit("replace_all", LUA_TSTRING, find_text, LUA_TSTRING, repl_text, -1);
}

// `find.find_next()` Lua function.
static int click_find_next(lua_State *L) { return (find_clicked(find_next, NULL), 0); }

// `find.find_prev()` Lua function.
static int click_find_prev(lua_State *L) { return (find_clicked(find_prev, NULL), 0); }

// `find.replace()` Lua function.
static int click_replace(lua_State *L) { return (find_clicked(replace, NULL), 0); }

// `find.replace_all()` Lua function.
static int click_replace_all(lua_State *L) { return (find_clicked(replace_all, NULL), 0); }

// `find.focus()` Lua function.
static int focus_find_lua(lua_State *L) { return (focus_find(), 0); }

// `find.__index` Lua metamethod.
static int find_index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    get_find_text() ? lua_pushstring(L, get_find_text()) : lua_pushliteral(L, "");
  else if (strcmp(key, "replace_entry_text") == 0)
    get_repl_text() ? lua_pushstring(L, get_repl_text()) : lua_pushliteral(L, "");
  else if (strcmp(key, "match_case") == 0)
    lua_pushboolean(L, is_checked(match_case));
  else if (strcmp(key, "whole_word") == 0)
    lua_pushboolean(L, is_checked(whole_word));
  else if (strcmp(key, "regex") == 0)
    lua_pushboolean(L, is_checked(regex));
  else if (strcmp(key, "in_files") == 0)
    lua_pushboolean(L, is_checked(in_files));
  else if (strcmp(key, "active") == 0)
    lua_pushboolean(L, is_find_active());
  else
    lua_rawget(L, 1);
  return 1;
}

// `find.__newindex` Lua metamethod.
static int find_newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    set_find_text(luaL_checkstring(L, 3));
  else if (strcmp(key, "replace_entry_text") == 0)
    set_repl_text(luaL_checkstring(L, 3));
  else if (strcmp(key, "match_case") == 0)
    toggle(match_case, lua_toboolean(L, -1));
  else if (strcmp(key, "whole_word") == 0)
    toggle(whole_word, lua_toboolean(L, -1));
  else if (strcmp(key, "regex") == 0)
    toggle(regex, lua_toboolean(L, -1));
  else if (strcmp(key, "in_files") == 0)
    toggle(in_files, lua_toboolean(L, -1));
  else if (strcmp(key, "find_label_text") == 0)
    set_find_label(luaL_checkstring(L, 3));
  else if (strcmp(key, "replace_label_text") == 0)
    set_repl_label(luaL_checkstring(L, 3));
  else if (strcmp(key, "find_next_button_text") == 0)
    set_button_label(find_next, luaL_checkstring(L, 3));
  else if (strcmp(key, "find_prev_button_text") == 0)
    set_button_label(find_prev, luaL_checkstring(L, 3));
  else if (strcmp(key, "replace_button_text") == 0)
    set_button_label(replace, luaL_checkstring(L, 3));
  else if (strcmp(key, "replace_all_button_text") == 0)
    set_button_label(replace_all, luaL_checkstring(L, 3));
  else if (strcmp(key, "match_case_label_text") == 0)
    set_option_label(match_case, luaL_checkstring(L, 3));
  else if (strcmp(key, "whole_word_label_text") == 0)
    set_option_label(whole_word, luaL_checkstring(L, 3));
  else if (strcmp(key, "regex_label_text") == 0)
    set_option_label(regex, luaL_checkstring(L, 3));
  else if (strcmp(key, "in_files_label_text") == 0)
    set_option_label(in_files, luaL_checkstring(L, 3));
  else if (strcmp(key, "entry_font") == 0)
    set_entry_font(luaL_checkstring(L, 3));
  else
    lua_rawset(L, 1);
  return 0;
}

// `command_entry.focus()` Lua function.
static int focus_command_entry_lua(lua_State *L) { return (focus_command_entry(), 0); }

// Runs the work function passed to `ui.dialogs.progressbar()`.
static char *work(void *L) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_workf");
  if (lua_pcall(L, 0, 2, 0) == LUA_OK) {
    if (lua_isnil(L, -2)) return (lua_pop(L, 2), NULL); // done
    if (lua_isnil(L, -1)) lua_pushliteral(L, ""), lua_replace(L, -2);
    if (lua_isnumber(L, -2) && lua_isstring(L, -1)) {
      lua_pushliteral(L, " "), lua_insert(L, -2), lua_pushliteral(L, "\n"), lua_concat(L, 4);
      char *input = strcpy(malloc(lua_rawlen(L, -1) + 1), lua_tostring(L, -1)); // "num str\n"
      return (lua_pop(L, 1), input); // will be freed by gtdialog
    } else
      lua_pop(L, 2), lua_pushliteral(L, "invalid return values");
  }
  return (emit("error", LUA_TSTRING, lua_tostring(L, -1), -1), lua_pop(L, 1), NULL);
}

// `ui.dialog()` Lua function.
static int dialog(lua_State *L) {
  GTDialogType type = gtdialog_type(luaL_checkstring(L, 1));
  int n = lua_gettop(L) - 1, argc = n;
  for (int i = 2; i < n + 2; i++)
    if (lua_istable(L, i)) argc += lua_rawlen(L, i) - 1;
  if (type == GTDIALOG_PROGRESSBAR)
    lua_pushnil(L), lua_setfield(L, LUA_REGISTRYINDEX, "ta_workf"), argc--;
  const char *argv[argc + 1]; // not malloc since luaL_checkstring throws
  for (int i = 0, j = 2; j < n + 2; j++)
    if (lua_istable(L, j))
      for (int k = 1, len = lua_rawlen(L, j); k <= len; lua_pop(L, 1), k++)
        argv[i++] = (lua_rawgeti(L, j, k), luaL_checkstring(L, -1)); // ^popped
    else if (lua_isfunction(L, j) && type == GTDIALOG_PROGRESSBAR) {
      lua_pushvalue(L, j), lua_setfield(L, LUA_REGISTRYINDEX, "ta_workf");
      gtdialog_set_progressbar_callback(work, L);
    } else
      argv[i++] = luaL_checkstring(L, j);
  argv[argc] = NULL;
  char *out;
  dialog_active = true, out = gtdialog(type, argc, argv), dialog_active = false;
  return (lua_pushstring(L, out), free(out), 1);
}

// Pushes the given Scintilla view onto the Lua stack.
// The view must have previously been added with `add_view()`.
static void lua_pushview(lua_State *L, Scintilla *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, VIEWS), lua_pushlightuserdata(L, view), lua_gettable(L, -2),
    lua_replace(L, -2);
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

// Returns the Scintilla view on the Lua stack at the given acceptable index.
static Scintilla *lua_toview(lua_State *L, int index) {
  Scintilla *view = (lua_getfield(L, index, "widget_pointer"), lua_touserdata(L, -1));
  return (lua_pop(L, 1), view); // widget pointer
}

// Pushes the given Scintilla document onto the Lua stack.
// The document must have previously been added with `add_doc()`.
static void lua_pushdoc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushlightuserdata(L, (sptr_t *)doc),
    lua_gettable(L, -2), lua_replace(L, -2);
}

// Synchronizes the tabbar after switching between Scintilla views or documents.
static void sync_tabbar() {
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS),
    lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(lua, -2);
  set_tab(lua_tointeger(lua, -1) - 1);
  lua_pop(lua, 2); // index and buffers
}

// Returns whether or not the value on the Lua stack at the given index has a metatable with
// the given name.
static bool is_type(lua_State *L, int index, const char *tname) {
  if (!lua_getmetatable(L, index)) return false;
  luaL_getmetatable(L, tname);
  bool has_metatable = lua_rawequal(L, -1, -2);
  return (lua_pop(L, 2), has_metatable); // metatable, metatable
}

// Checks whether the given function argument is a Scintilla view and returns it.
static Scintilla *luaL_checkview(lua_State *L, int arg) {
  return (luaL_argcheck(L, is_type(L, arg, "ta_view"), arg, "View expected"), lua_toview(L, arg));
}

// `ui.goto_view()` Lua function.
static int goto_view(lua_State *L) {
  if (lua_isnumber(L, 1)) {
    lua_getfield(L, LUA_REGISTRYINDEX, VIEWS);
    lua_pushview(L, focused_view);
    int n = ((lua_gettable(L, -2), lua_tointeger(L, -1)) + lua_tointeger(L, 1)) % lua_rawlen(L, -2);
    if (n == 0) n = lua_rawlen(L, -2);
    lua_rawgeti(L, -2, n), lua_replace(L, 1); // index
  }
  return (focus_view(luaL_checkview(L, 1)), 0);
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

void show_context_menu(const char *name, void *userdata) {
  int n = lua_gettop(lua);
  if (lua_getglobal(lua, "ui") == LUA_TTABLE && lua_getfield(lua, -1, name) == LUA_TLIGHTUSERDATA)
    popup_menu(lua_touserdata(lua, -1), userdata);
  lua_settop(lua, n);
}

// `ui.update()` Lua function.
static int update_ui_lua(lua_State *L) { return (update_ui(), 0); }

// `ui.__index` Lua metamethod.
static int ui_index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "clipboard_text") == 0) {
    int len;
    char *text = get_clipboard_text(&len);
    text ? lua_pushlstring(L, text, len) : lua_pushliteral(L, "");
    if (text) free(text);
  } else if (strcmp(key, "maximized") == 0)
    lua_pushboolean(L, is_maximized());
  else if (strcmp(key, "size") == 0) {
    int width, height;
    get_size(&width, &height);
    lua_newtable(L);
    lua_pushinteger(L, width), lua_rawseti(L, -2, 1);
    lua_pushinteger(L, height), lua_rawseti(L, -2, 2);
  } else if (strcmp(key, "tabs") == 0)
    tabs <= 1 ? lua_pushboolean(L, tabs) : lua_pushinteger(L, tabs);
  else
    lua_rawget(L, 1);
  return 1;
}

int get_int_field(lua_State *L, int index, int n) {
  int i = (lua_rawgeti(L, index, n), lua_tointeger(L, -1));
  return (lua_pop(L, 1), i); // integer
}

// `ui.__newindex` Lua metatable.
static int ui_newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0)
    set_title(lua_tostring(L, 3));
  else if (strcmp(key, "clipboard_text") == 0)
    SS(focused_view, SCI_COPYTEXT, lua_rawlen(L, 3), (sptr_t)luaL_checkstring(L, 3));
  else if (strcmp(key, "statusbar_text") == 0 || strcmp(key, "buffer_statusbar_text") == 0)
    set_statusbar_text(*key == 's' ? 0 : 1, lua_tostring(L, 3));
  else if (strcmp(key, "menubar") == 0)
    set_menubar(L, 3);
  else if (strcmp(key, "maximized") == 0)
    set_maximized(lua_toboolean(L, 3));
  else if (strcmp(key, "size") == 0) {
    luaL_argcheck(
      L, lua_istable(L, 3) && lua_rawlen(L, 3) == 2, 3, "{width, height} table expected");
    int width = get_int_field(L, 3, 1), height = get_int_field(L, 3, 2);
    if (width > 0 && height > 0) set_size(width, height);
  } else if (strcmp(key, "tabs") == 0) {
    tabs = !lua_isinteger(L, 3) ? lua_toboolean(L, 3) : lua_tointeger(L, 3);
    show_tabs(
      tabs && (tabs > 1 || (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawlen(L, -1)) > 1));
  } else
    lua_rawset(L, 1);
  return 0;
}

// Returns the Scintilla document on the Lua stack at the given acceptable index.
static sptr_t lua_todoc(lua_State *L, int index) {
  sptr_t doc = (lua_getfield(L, index, "doc_pointer"), (sptr_t)lua_touserdata(L, -1));
  return (lua_pop(L, 1), doc); // doc_pointer
}

// Returns a suitable Scintilla view that can operate on the Scintilla document on the Lua
// stack at the given index.
// For non-global, non-command entry documents, loads that document in `dummy_view` (unless
// it is already loaded). Raises and error if the value is not a Scintilla document or if the
// document no longer exists.
static Scintilla *view_for_doc(lua_State *L, int index) {
  luaL_argcheck(L, is_type(L, index, "ta_buffer"), index, "Buffer expected");
  sptr_t doc = lua_todoc(L, index);
  if (doc == SS(focused_view, SCI_GETDOCPOINTER, 0, 0)) return focused_view;
  luaL_argcheck(L,
    (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushdoc(L, doc),
      lua_gettable(L, -2) != LUA_TNIL),
    index, "this Buffer does not exist");
  lua_pop(L, 2); // buffer, ta_buffers
  if (doc == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) return command_entry;
  if (doc == SS(dummy_view, SCI_GETDOCPOINTER, 0, 0)) return dummy_view;
  return (SS(dummy_view, SCI_SETDOCPOINTER, 0, doc), dummy_view);
}

// Switches, in the given view, to a Scintilla document at a relative or absolute index.
// An absolute value of -1 represents the last document.
static void goto_doc(lua_State *L, Scintilla *view, int n, bool relative) {
  if (relative && n == 0) return;
  lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS);
  if (relative) {
    lua_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0));
    n = ((lua_gettable(L, -2), lua_tointeger(L, -1)) + n) % lua_rawlen(L, -2);
    if (n == 0) n = lua_rawlen(L, -2);
    lua_pop(L, 1), lua_rawgeti(L, -1, n), lua_replace(L, -2); // index
  } else
    lua_rawgeti(L, -1, n > 0 ? n : (int)lua_rawlen(L, -1)), lua_replace(L, -2);
  luaL_argcheck(L, !lua_isnil(L, -1), 2, "no Buffer exists at that index");
  sptr_t doc = lua_todoc(L, -1);
  SS(view, SCI_SETDOCPOINTER, 0, doc), sync_tabbar();
  lua_setglobal(L, "buffer");
}

// Removes the given Scintilla document from the 'buffers' Lua registry table.
// The document must have been previously added with `add_doc()`.
// It is removed from any other views showing it first. Therefore, ensure the length of 'buffers'
// is more than one unless quitting the application.
static void remove_doc(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
  for (size_t i = 1; i <= lua_rawlen(lua, -1); lua_pop(lua, 1), i++) {
    Scintilla *view = (lua_rawgeti(lua, -1, i), lua_toview(lua, -1)); // popped on loop
    if (doc == SS(view, SCI_GETDOCPOINTER, 0, 0)) goto_doc(lua, view, -1, true);
  }
  lua_pop(lua, 1); // views
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
  for (size_t i = 1; i <= lua_rawlen(lua, -1); lua_pop(lua, 1), i++)
    if (doc == (lua_rawgeti(lua, -1, i), lua_todoc(lua, -1))) {
      // t[buf] = nil, t[doc_pointer] = nil, table.remove(t, i)
      lua_pushnil(lua), lua_rawset(lua, -3);
      lua_pushlightuserdata(lua, (sptr_t *)doc), lua_pushnil(lua), lua_rawset(lua, -3);
      lua_getglobal(lua, "table"), lua_getfield(lua, -1, "remove"), lua_replace(lua, -2),
        lua_pushvalue(lua, -2), lua_pushinteger(lua, i), lua_call(lua, 2, 0);
      for (int i = 1; i <= lua_rawlen(lua, -1); i++)
        lua_rawgeti(lua, -1, i), lua_pushinteger(lua, i), lua_rawset(lua, -3); // t[buf] = i
      remove_tab(i - 1), show_tabs(tabs && (tabs > 1 || lua_rawlen(lua, -1) > 1));
      break;
    }
  lua_pop(lua, 1); // buffers
}

// Removes the given Scintilla document from the current Scintilla view.
static void delete_buffer(sptr_t doc) {
  remove_doc(doc), SS(dummy_view, SCI_SETDOCPOINTER, 0, 0);
  SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

// `buffer.delete()` Lua function.
static int delete_buffer_lua(lua_State *L) {
  Scintilla *view = view_for_doc(L, 1);
  luaL_argcheck(L, view != command_entry, 1, "cannot delete command entry");
  sptr_t doc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  if (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawlen(L, -1) == 1) new_buffer(0);
  if (view == focused_view) goto_doc(L, focused_view, -1, true);
  delete_buffer(doc), emit("buffer_deleted", -1);
  if (view == focused_view) emit("buffer_after_switch", -1);
  return 0;
}

// `_G.buffer_new()` Lua function.
static int new_buffer_lua(lua_State *L) {
  if (initing) luaL_error(L, "cannot create buffers during initialization");
  new_buffer(0);
  return (lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawgeti(L, -1, lua_rawlen(L, -1)), 1);
}

// Checks whether the given function argument is of the given Scintilla parameter type and
// returns it in a form suitable for use in a Scintilla message.
static sptr_t luaL_checkscintilla(lua_State *L, int *arg, int type) {
  if (type == SSTRING) return (sptr_t)luaL_checkstring(L, (*arg)++);
  if (type == SBOOL) return lua_toboolean(L, (*arg)++);
  if (type == SINDEX) {
    int i = luaL_checkinteger(L, (*arg)++);
    return i >= 0 ? i - 1 : i; // do not adjust significant values like -1
  }
  if (type == SCOLOR) {
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
  lua_State *L, Scintilla *view, int msg, int wtype, int ltype, int rtype, int arg) {
  uptr_t wparam = 0;
  sptr_t lparam = 0, len = 0;
  int params_needed = 2, nresults = 0;
  bool string_return = false;
  char *text = NULL;

  // Create Scintillua lexer from incoming lexer name string.
  if (msg == SCI_SETILEXER) {
    lua_getglobal(L, "_LEXERPATH"), SetLibraryProperty("scintillua.lexers", lua_tostring(L, -1)),
      lua_pop(L, 1);
    lparam = (sptr_t)CreateLexer(luaL_checkstring(L, arg)), params_needed = 0;
    if (!lparam) luaL_error(L, "error creating lexer: %s", GetCreateLexerError());
  }

  // Set wParam and lParam appropriately for Scintilla based on wtype and ltype.
  if (wtype == SLEN && ltype == SSTRING) {
    wparam = (uptr_t)lua_rawlen(L, arg);
    lparam = (sptr_t)luaL_checkstring(L, arg);
    params_needed = 0;
  } else if (ltype == SSTRINGRET || rtype == SSTRINGRET)
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

// `buffer:method()` Lua function.
static int call_scintilla_lua(lua_State *L) {
  Scintilla *view = focused_view;
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

// `buffer[k].__index` metamethod.
static int property_index(lua_State *L) {
  bool not_view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view"));
  Scintilla *view = not_view ? view_for_doc(L, -1) : lua_toview(L, -1);
  lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4), ltype = SVOID,
      rtype = get_int_field(L, -1, 3);
  luaL_argcheck(L, msg, 2, "write-only property");
  return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 1);
}

// `buffer[k].__newindex` metamethod.
static int property_newindex(lua_State *L) {
  bool not_view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view"));
  Scintilla *view = not_view ? view_for_doc(L, -1) : lua_toview(L, -1);
  lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 4),
      ltype = get_int_field(L, -1, 3), rtype = SVOID;
  luaL_argcheck(L, msg, 3, "read-only property");
  if (ltype == SSTRINGRET) ltype = SSTRING;
  return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 0);
}

// Helper function for `buffer_index()` and `view_index()` that gets Scintilla properties.
static void get_property(lua_State *L) {
  Scintilla *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) : lua_toview(L, 1);
  // Interface table is of the form {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4), ltype = SVOID,
      rtype = get_int_field(L, -1, 3);
  luaL_argcheck(L, msg || wtype != SVOID, 2, "write-only property");
  if (wtype != SVOID) { // indexible property
    lua_createtable(L, 2, 0);
    lua_pushvalue(L, 1), lua_setfield(L, -2, "_self");
    lua_pushvalue(L, -2), lua_setfield(L, -2, "_iface");
    set_metatable(L, -1, "ta_property", property_index, property_newindex);
  } else
    call_scintilla(L, view, msg, wtype, ltype, rtype, 2);
}

// Helper function for `buffer_newindex()` and `view_newindex()` that sets Scintilla properties.
static void set_property(lua_State *L) {
  Scintilla *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) : lua_toview(L, 1);
  // Interface table is of the form {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 3),
      ltype = get_int_field(L, -1, 4), rtype = SVOID, temp;
  luaL_argcheck(L, msg && ltype == SVOID, 3, "read-only property");
  if (wtype == SSTRING || wtype == SSTRINGRET || msg == SCI_SETMARGINLEFT ||
    msg == SCI_SETMARGINRIGHT)
    temp = wtype != SSTRINGRET ? wtype : SSTRING, wtype = ltype, ltype = temp;
  call_scintilla(L, view, msg, wtype, ltype, rtype, 3);
}

// `buffer.__index` metamethod.
static int buffer_index(lua_State *L) {
  if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_functions"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla function, return a callable closure.
    lua_pushcclosure(L, call_scintilla_lua, 1);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, determine if it is an indexible one or not. If so,
    // return a table with the appropriate metatable; otherwise call Scintilla to get the
    // property's value.
    get_property(L);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_constants"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TNUMBER) { // pushed
    // If the key is a Scintilla constant, return its value.
  } else if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
    lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
    luaL_argerror(L, 3, "write-only property");
  else if (strcmp(lua_tostring(L, 2), "active") == 0 &&
    lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
    lua_pushboolean(L, is_command_entry_active());
  else if (strcmp(lua_tostring(L, 2), "height") == 0 &&
    lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    lua_pushinteger(L, get_command_entry_height());
  } else
    lua_settop(L, 2), lua_rawget(L, 1);
  return 1;
}

// `buffer.__newindex` metamethod.
static int buffer_newindex(lua_State *L) {
  if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, call Scintilla to set its value.
    // Interface table is of the form {get_id, set_id, rtype, wtype}.
    set_property(L);
  else if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
    lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushvalue(L, 1), lua_gettable(L, -2);
    set_tab_label(lua_tointeger(L, -1) - 1, luaL_checkstring(L, 3));
  } else if (strcmp(lua_tostring(L, 2), "height") == 0 &&
    lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
    set_command_entry_height(
      fmax(luaL_checkinteger(L, 3), SS(command_entry, SCI_TEXTHEIGHT, 0, 0)));
  else
    lua_settop(L, 3), lua_rawset(L, 1);
  return 0;
}

// Adds the given Scintilla document along with a metatable to the 'buffers' Lua registry table.
// If the document is 0, adds the command entry's document at a constant index (0).
static void add_doc(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
  if (doc) {
    lua_newtable(lua);
    lua_pushlightuserdata(lua, (sptr_t *)doc), lua_setfield(lua, -2, "doc_pointer");
    lua_pushcfunction(lua, delete_buffer_lua), lua_setfield(lua, -2, "delete");
    lua_pushcfunction(lua, new_buffer_lua), lua_setfield(lua, -2, "new");
    set_metatable(lua, -1, "ta_buffer", buffer_index, buffer_newindex);
  } else {
    lua_getglobal(lua, "ui"), lua_getfield(lua, -1, "command_entry"), lua_replace(lua, -2);
    lua_pushstring(lua, "doc_pointer"),
      lua_pushlightuserdata(lua, (sptr_t *)SS(command_entry, SCI_GETDOCPOINTER, 0, 0)),
      lua_rawset(lua, -3);
  }
  // t[doc_pointer] = buffer, t[doc and #t + 1 or 0] = buffer, t[buffer] = doc and #t or 0
  lua_getfield(lua, -1, "doc_pointer"), lua_pushvalue(lua, -2), lua_rawset(lua, -4);
  lua_pushvalue(lua, -1), lua_rawseti(lua, -3, doc ? lua_rawlen(lua, -3) + 1 : 0);
  lua_pushinteger(lua, doc ? lua_rawlen(lua, -2) : 0), lua_rawset(lua, -3);
  lua_pop(lua, 1); // buffers
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
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
  add_tab(), show_tabs(tabs && (tabs > 1 || lua_rawlen(lua, -1) > 0));
  lua_pop(lua, 1); // buffers
  lua_pushdoc(lua, doc), lua_setglobal(lua, "buffer");
  if (!initing) emit("buffer_new", -1);
}

void move_buffer(int from, int to, bool reorder_tabs) {
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
  lua_getglobal(lua, "table"), lua_getfield(lua, -1, "insert"), lua_replace(lua, -2),
    lua_pushvalue(lua, -2), lua_pushinteger(lua, to); // table.remove(_BUFFERS, from) --> buf
  lua_getglobal(lua, "table"), lua_getfield(lua, -1, "remove"), lua_replace(lua, -2),
    lua_pushvalue(lua, -5), lua_pushinteger(lua, from), lua_call(lua, 2, 1);
  lua_call(lua, 3, 0); // table.insert(_BUFFERS, to, buf)
  for (int i = 1; i <= lua_rawlen(lua, -1); i++)
    lua_rawgeti(lua, -1, i), lua_pushinteger(lua, i), lua_rawset(lua, -3); // _BUFFERS[buf] = i
  if (lua_pop(lua, 1), reorder_tabs) move_tab(from - 1, to - 1);
}

// `_G.move_buffer` Lua function.
static int move_buffer_lua(lua_State *L) {
  int from = luaL_checkinteger(L, 1), to = luaL_checkinteger(L, 2);
  lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
  luaL_argcheck(L, from >= 1 && from <= lua_rawlen(L, -1), 1, "position out of bounds");
  luaL_argcheck(L, to >= 1 && to <= lua_rawlen(L, -1), 2, "position out of bounds");
  return (lua_pop(L, 1), move_buffer(from, to, true), 0);
}

// `_G.quit()` Lua function.
static int quit_lua(lua_State *L) { return (quit(), 0); }

// Runs the given Lua file, which is relative to `textadept_home`, and returns `true` on success.
// If there are errors, shows an error dialog and returns `false`.
static bool run_file(const char *filename) {
  char *file = malloc(strlen(textadept_home) + 1 + strlen(filename) + 1);
  sprintf(file, "%s/%s", textadept_home, filename);
  bool ok = luaL_dofile(lua, file) == LUA_OK;
  if (!ok) {
    const char *argv[] = {"--title", "Initialization Error", "--text", lua_tostring(lua, -1)};
    free(gtdialog(GTDIALOG_TEXTBOX, 4, argv));
    lua_settop(lua, 0);
  }
  return (free(file), ok);
}

// `_G.reset()` Lua function.
static int reset(lua_State *L) {
  int persist_ref = (lua_newtable(L), luaL_ref(L, LUA_REGISTRYINDEX));
  lua_rawgeti(L, LUA_REGISTRYINDEX, persist_ref); // emit will unref
  emit("reset_before", LUA_TTABLE, luaL_ref(L, LUA_REGISTRYINDEX), -1);
  init_lua(0, NULL);
  lua_pushview(L, focused_view), lua_setglobal(L, "view");
  lua_pushdoc(L, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(L, "buffer");
  lua_pushnil(L), lua_setglobal(L, "arg");
  run_file("init.lua"), emit("initialized", -1);
  lua_getfield(L, LUA_REGISTRYINDEX, ARG), lua_setglobal(L, "arg");
  return (emit("reset_after", LUA_TTABLE, persist_ref, -1), 0);
}

bool call_timeout_function(void *f) {
  int *refs = f, nargs = 0;
  lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
  while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
  bool ok = lua_pcall(lua, nargs - 1, 1, 0) == LUA_OK, repeat;
  if (!(repeat = ok && lua_toboolean(lua, -1))) {
    while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
    free(refs);
    if (!ok) emit("error", LUA_TSTRING, lua_tostring(lua, -1), -1);
  }
  return (lua_pop(lua, 1), repeat); // result
}

// `_G.timeout()` Lua function.
static int add_timeout_lua(lua_State *L) {
  double interval = luaL_checknumber(L, 1);
  luaL_argcheck(L, interval > 0, 1, "interval must be > 0");
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  int n = lua_gettop(L), *refs = calloc(n, sizeof(int));
  for (int i = 2; i <= n; i++) lua_pushvalue(L, i), refs[i - 2] = luaL_ref(L, LUA_REGISTRYINDEX);
  if (!add_timeout(interval, refs)) {
    for (int i = 2; i <= n; i++) luaL_unref(L, LUA_REGISTRYINDEX, refs[i - 2]);
    free(refs);
    return luaL_error(L, "could not add timeout");
  }
  return 0;
}

// `string.iconv()` Lua function.
static int iconv_lua(lua_State *L) {
  size_t inbytesleft = 0;
  char *inbuf = (char *)luaL_checklstring(L, 1, &inbytesleft);
  const char *to = luaL_checkstring(L, 2), *from = luaL_checkstring(L, 3);
  iconv_t cd = iconv_open(to, from);
  if (cd == (iconv_t)-1) luaL_error(L, "invalid encoding(s)");
  // Ensure the minimum buffer size can hold a potential output BOM and one multibyte character.
  size_t bufsiz = 4 + (inbytesleft > MB_LEN_MAX ? inbytesleft : MB_LEN_MAX);
  char *outbuf = malloc(bufsiz + 1), *p = outbuf;
  size_t outbytesleft = bufsiz;
  int n = 1; // concat this many converted strings
  while (iconv(cd, &inbuf, &inbytesleft, &p, &outbytesleft) == (size_t)-1)
    if (errno == E2BIG && p - outbuf > 0) {
      // Buffer was too small to store converted string. Push the partially converted string
      // for later concatenation.
      lua_checkstack(L, 2), lua_pushlstring(L, outbuf, p - outbuf), n++;
      p = outbuf, outbytesleft = bufsiz;
    } else
      free(outbuf), iconv_close(cd), luaL_error(L, "conversion failed");
  lua_pushlstring(L, outbuf, p - outbuf);
  return (lua_concat(L, n), free(outbuf), iconv_close(cd), 1);
}

// Initializes or re-initializes the Lua state and with the given command-line arguments.
// Populates the state with global variables and functions, runs the 'core/init.lua' script,
// and returns `true` on success.
static bool init_lua(int argc, char **argv) {
  lua_State *L = !lua ? luaL_newstate() : lua;
  if (!lua) {
    lua_newtable(L);
    for (int i = 0; i < argc; i++) lua_pushstring(L, argv[i]), lua_rawseti(L, -2, i);
    lua_setfield(L, LUA_REGISTRYINDEX, ARG);
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, BUFFERS);
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, VIEWS);
  } else { // clear package.loaded and _G
    lua_getfield(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
    while (lua_pushnil(L), lua_next(L, -2))
      lua_pushnil(L), lua_replace(L, -2), lua_rawset(L, -3); // clear
    lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
    while (lua_pushnil(L), lua_next(L, -2))
      lua_pushnil(L), lua_replace(L, -2), lua_rawset(L, -3); // clear
    lua_pop(L, 2); // package.loaded, _G
    lua_gc(L, LUA_GCCOLLECT, 0);
  }
  luaL_openlibs(L);
  luaL_requiref(L, "lpeg", luaopen_lpeg, 1), lua_pop(L, 1);
  luaL_requiref(L, "lfs", luaopen_lfs, 1), lua_pop(L, 1);

  lua_newtable(L);
  lua_newtable(L);
  lua_pushcfunction(L, click_find_next), lua_setfield(L, -2, "find_next");
  lua_pushcfunction(L, click_find_prev), lua_setfield(L, -2, "find_prev");
  lua_pushcfunction(L, click_replace), lua_setfield(L, -2, "replace");
  lua_pushcfunction(L, click_replace_all), lua_setfield(L, -2, "replace_all");
  lua_pushcfunction(L, focus_find_lua), lua_setfield(L, -2, "focus");
  set_metatable(L, -1, "ta_find", find_index, find_newindex);
  lua_setfield(L, -2, "find");
  if (!lua) {
    lua_newtable(L);
    lua_pushcfunction(L, focus_command_entry_lua), lua_setfield(L, -2, "focus");
    set_metatable(L, -1, "ta_buffer", buffer_index, buffer_newindex);
  } else
    lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_rawgeti(L, -1, 0),
      lua_replace(L, -2); // _BUFFERS[0] == command_entry
  lua_setfield(L, -2, "command_entry");
  lua_pushcfunction(L, dialog), lua_setfield(L, -2, "dialog");
  lua_pushcfunction(L, get_split_table), lua_setfield(L, -2, "get_split_table");
  lua_pushcfunction(L, goto_view), lua_setfield(L, -2, "goto_view");
  lua_pushcfunction(L, menu), lua_setfield(L, -2, "menu");
  lua_pushcfunction(L, popup_menu_lua), lua_setfield(L, -2, "popup_menu");
  lua_pushcfunction(L, update_ui_lua), lua_setfield(L, -2, "update");
  set_metatable(L, -1, "ta_ui", ui_index, ui_newindex);
  lua_setglobal(L, "ui");

  lua_pushcfunction(L, move_buffer_lua), lua_setglobal(L, "move_buffer");
  lua_pushcfunction(L, quit_lua), lua_setglobal(L, "quit");
  lua_pushcfunction(L, reset), lua_setglobal(L, "reset");
  lua_pushcfunction(L, add_timeout_lua), lua_setglobal(L, "timeout");

  lua_getglobal(L, "string"), lua_pushcfunction(L, iconv_lua), lua_setfield(L, -2, "iconv"),
    lua_pop(L, 1);

  lua_getfield(L, LUA_REGISTRYINDEX, ARG), lua_setglobal(L, "arg");
  lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_setglobal(L, "_BUFFERS");
  lua_getfield(L, LUA_REGISTRYINDEX, VIEWS), lua_setglobal(L, "_VIEWS");
  lua_pushstring(L, textadept_home), lua_setglobal(L, "_HOME");
  lua_pushboolean(L, true), lua_setglobal(L, os);
  lua_pushboolean(L, true), lua_setglobal(L, get_platform());
  lua_pushstring(L, get_charset()), lua_setglobal(L, "_CHARSET");

  if (lua = L, !run_file("core/init.lua")) return (lua_close(L), lua = NULL, false);
  lua_getglobal(L, "_SCINTILLA");
  lua_getfield(L, -1, "constants"), lua_setfield(L, LUA_REGISTRYINDEX, "ta_constants");
  lua_getfield(L, -1, "functions"), lua_setfield(L, LUA_REGISTRYINDEX, "ta_functions");
  lua_getfield(L, -1, "properties"), lua_setfield(L, LUA_REGISTRYINDEX, "ta_properties");
  lua_pop(L, 1); // _SCINTILLA
  return true;
}

// Removes the given Scintilla view from the 'views' Lua registry table.
// The view must have been previously added with `add_view()`.
static void remove_view(Scintilla *view) {
  lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
  for (size_t i = 1; i <= lua_rawlen(lua, -1); lua_pop(lua, 1), i++)
    if (view == (lua_rawgeti(lua, -1, i), lua_toview(lua, -1))) {
      // t[view] = nil, t[widget_pointer] = nil, table.remove(t, i)
      lua_pushnil(lua), lua_rawset(lua, -3);
      lua_pushlightuserdata(lua, view), lua_pushnil(lua), lua_rawset(lua, -3);
      lua_getglobal(lua, "table"), lua_getfield(lua, -1, "remove"), lua_replace(lua, -2),
        lua_pushvalue(lua, -2), lua_pushinteger(lua, i), lua_call(lua, 2, 0);
      for (int i = 1; i <= lua_rawlen(lua, -1); i++)
        lua_rawgeti(lua, -1, i), lua_pushinteger(lua, i), lua_rawset(lua, -3); // t[view] = i
      break;
    }
  lua_pop(lua, 1); // views
}

// Emits the given Scintilla notification to Lua.
static void emit_notification(SCNotification *n) {
  lua_newtable(lua);
  lua_pushinteger(lua, n->nmhdr.code), lua_setfield(lua, -2, "code");
  lua_pushinteger(lua, n->position + 1), lua_setfield(lua, -2, "position");
  lua_pushinteger(lua, n->ch), lua_setfield(lua, -2, "ch");
  lua_pushinteger(lua, n->modifiers), lua_setfield(lua, -2, "modifiers");
  lua_pushinteger(lua, n->modificationType), lua_setfield(lua, -2, "modification_type");
  if (n->text)
    lua_pushlstring(lua, n->text, n->length ? n->length : strlen(n->text)),
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

// Signal that focus has changed to the given Scintilla view.
// Generates 'view_before_switch' and 'view_after_switch' events.
static void view_focused(Scintilla *view) {
  if (!initing && !closing) emit("view_before_switch", -1);
  lua_pushview(lua, focused_view = view), lua_setglobal(lua, "view"), sync_tabbar();
  lua_pushdoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
  if (!initing && !closing) emit("view_after_switch", -1);
}

// Signal for a Scintilla notification.
static void notified(Scintilla *view, int _, SCNotification *n, void *__) {
  if (view == command_entry) {
    if (n->nmhdr.code == SCN_MODIFIED &&
      (n->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT)))
      emit("command_text_changed", -1);
    else if (n->nmhdr.code == SCN_FOCUSOUT) // TODO: do not emit if Esc triggered this
      emit("keypress", LUA_TNUMBER, SCK_ESCAPE, -1);
  } else if (view == focused_view || n->nmhdr.code == SCN_URIDROPPED) {
    if (view != focused_view) view_focused(view);
    emit_notification(n);
  } else if (n->nmhdr.code == SCN_FOCUSIN)
    view_focused(view);
}

// `view.goto_buffer()` Lua function.
static int goto_doc_lua(lua_State *L) {
  Scintilla *view = luaL_checkview(L, 1), *prev_view = focused_view;
  bool relative = lua_isnumber(L, 2);
  if (!relative) {
    lua_getfield(L, LUA_REGISTRYINDEX, BUFFERS), lua_pushvalue(L, 2), lua_gettable(L, -2),
      lua_replace(L, 2);
    luaL_argcheck(L, lua_isnumber(L, 2), 2, "Buffer or relative index expected");
  }
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
  Scintilla *view = luaL_checkview(L, 1);
  int first_line = SS(view, SCI_GETFIRSTVISIBLELINE, 0, 0),
      x_offset = SS(view, SCI_GETXOFFSET, 0, 0), current_pos = SS(view, SCI_GETCURRENTPOS, 0, 0),
      anchor = SS(view, SCI_GETANCHOR, 0, 0);
  Scintilla *view2 = new_view(SS(view, SCI_GETDOCPOINTER, 0, 0));
  split_view(view, view2, lua_toboolean(L, 2)), focus_view(view2);
  SS(view2, SCI_SETSEL, anchor, current_pos);
  SS(view2, SCI_LINESCROLL, first_line - SS(view2, SCI_GETFIRSTVISIBLELINE, 0, 0), 0);
  SS(view2, SCI_SETXOFFSET, x_offset, 0);
  return (lua_pushvalue(L, 1), lua_getglobal(L, "view"), 2); // old, new view
}

// Removes the given Scintilla view, typically after unsplitting a pane.
static void delete_view(Scintilla *view) { remove_view(view), delete_scintilla(view); }

// `view.unsplit()` Lua function.
static int unsplit_view_lua(lua_State *L) {
  return (lua_pushboolean(L, unsplit_view(luaL_checkview(L, 1), delete_view)), 1);
}

// `view.__index` metamethod.
static int view_index(lua_State *L) {
  if (strcmp(lua_tostring(L, 2), "buffer") == 0)
    lua_pushdoc(L, SS(lua_toview(L, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (strcmp(lua_tostring(L, 2), "size") == 0) {
    PaneInfo info = get_pane_info_from_view(lua_toview(L, 1));
    info.is_split ? lua_pushinteger(L, info.size) : lua_pushnil(L);
  } else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_functions"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla function, return a callable closure.
    lua_pushcclosure(L, call_scintilla_lua, 1);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, determine if it is an indexible one or not. If so,
    // return a table with the appropriate metatable; otherwise call Scintilla to get the
    // property's value.
    get_property(L);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_constants"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TNUMBER) { // pushed
    // If the key is a Scintilla constant, return its value.
  } else
    lua_settop(L, 2), lua_rawget(L, 1);
  return 1;
}

// `view.__newindex` metamethod.
static int view_newindex(lua_State *L) {
  if (strcmp(lua_tostring(L, 2), "buffer") == 0)
    luaL_argerror(L, 2, "read-only property");
  else if (strcmp(lua_tostring(L, 2), "size") == 0) {
    PaneInfo info = get_pane_info_from_view(lua_toview(L, 1));
    if (info.is_split) set_pane_size(info.self, fmax(luaL_checkinteger(L, 3), 0));
  } else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"), lua_pushvalue(L, 2),
    lua_rawget(L, -2) == LUA_TTABLE)
    set_property(L);
  else
    lua_settop(L, 3), lua_rawset(L, 1);
  return 0;
}

// Adds the given Scintilla view with a metatable to the 'views' Lua registry table.
static void add_view(Scintilla *view) {
  lua_getfield(lua, LUA_REGISTRYINDEX, VIEWS);
  lua_newtable(lua);
  lua_pushlightuserdata(lua, view), lua_setfield(lua, -2, "widget_pointer");
  lua_pushcfunction(lua, goto_doc_lua), lua_setfield(lua, -2, "goto_buffer");
  lua_pushcfunction(lua, split_view_lua), lua_setfield(lua, -2, "split");
  lua_pushcfunction(lua, unsplit_view_lua), lua_setfield(lua, -2, "unsplit");
  set_metatable(lua, -1, "ta_view", view_index, view_newindex);
  // t[widget_pointer] = view, t[#t + 1] = view, t[view] = #t
  lua_getfield(lua, -1, "widget_pointer"), lua_pushvalue(lua, -2), lua_rawset(lua, -4);
  lua_pushvalue(lua, -1), lua_rawseti(lua, -3, lua_rawlen(lua, -3) + 1);
  lua_pushinteger(lua, lua_rawlen(lua, -2)), lua_rawset(lua, -3);
  lua_pop(lua, 1); // views
}

// Creates, adds to Lua, and returns a Scintilla view with the given Scintilla document to load
// in it.
// The document can only be zero if this is the first Scintilla view being created.
// Generates a 'view_new' event.
static Scintilla *new_view(sptr_t doc) {
  Scintilla *view = new_scintilla(notified);
  SS(view, SCI_USEPOPUP, SC_POPUP_NEVER, 0);
  add_view(view);
  lua_pushview(lua, view), lua_setglobal(lua, "view");
  if (doc) SS(view, SCI_SETDOCPOINTER, 0, doc);
  focus_view(view), focused_view = view;
  if (!doc) new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!initing) emit("view_new", -1);
  return view;
}

// Creates and returns the first Scintilla view when the platform is ready for it.
static Scintilla *create_first_view() { return new_view(0); }

bool init_textadept(int argc, char **argv) {
  char *last_slash = NULL;
#if __linux__
  textadept_home = malloc(FILENAME_MAX + 1);
  textadept_home[readlink("/proc/self/exe", textadept_home, FILENAME_MAX + 1)] = '\0';
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
  os = "LINUX";
#elif _WIN32
  textadept_home = malloc(FILENAME_MAX + 1);
  GetModuleFileName(NULL, textadept_home, FILENAME_MAX + 1);
  if ((last_slash = strrchr(textadept_home, '\\'))) *last_slash = '\0';
  os = "WIN32";
#elif __APPLE__
  char *path = malloc(FILENAME_MAX + 1), *p = NULL;
  uint32_t size = FILENAME_MAX + 1;
  _NSGetExecutablePath(path, &size);
  textadept_home = realpath(path, NULL), free(path);
  p = strstr(textadept_home, "MacOS"), strcpy(p, "Resources\0");
  os = "OSX";
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
  textadept_home = malloc(FILENAME_MAX + 1);
  int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1};
  size_t cb = FILENAME_MAX + 1;
  sysctl(mib, 4, textadept_home, &cb, NULL, 0);
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
  os = "BSD";
#endif

  setlocale(LC_COLLATE, "C"), setlocale(LC_NUMERIC, "C"); // for Lua
  if (!init_lua(argc, argv)) return (close_textadept(), false);
  command_entry = new_scintilla(notified), add_doc(0), dummy_view = new_scintilla(NULL);
  initing = true, new_window(create_first_view), run_file("init.lua"), initing = false;
  emit("buffer_new", -1), emit("view_new", -1); // first ones
  lua_pushdoc(lua, SS(command_entry, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
  emit("buffer_new", -1), emit("view_new", -1); // command entry
  lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(lua, "buffer");
  return (emit("initialized", -1), true); // ready
}

void close_textadept() {
  if (lua) {
    closing = true;
    while (unsplit_view(focused_view, delete_view)) {}
    lua_getfield(lua, LUA_REGISTRYINDEX, BUFFERS);
    for (int i = lua_rawlen(lua, -1); i > 0; lua_pop(lua, 1), i--)
      lua_rawgeti(lua, -1, i), delete_buffer(lua_todoc(lua, -1)); // popped on loop
    lua_pop(lua, 1); // buffers
    delete_scintilla(focused_view), delete_scintilla(command_entry), delete_scintilla(dummy_view);
    lua_close(lua), lua = NULL;
  }
  if (textadept_home) free(textadept_home), textadept_home = NULL;
}

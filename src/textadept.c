// Copyright 2007-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

#include <locale.h>
#include <iconv.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if __WIN32__
#include <windows.h>
#define main main_
#elif __OSX__
#include <gtkmacintegration/gtkosxapplication.h>
#elif __BSD__
#include <sys/types.h>
#include <sys/sysctl.h>
#else
#include <unistd.h>
#endif
#if GTK
#include <gtk/gtk.h>
#define PLAT_GTK 1
#elif NCURSES
#include <ncurses.h>
#define PLAT_TERM 1
#endif

#include "gcocoadialog.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "Scintilla.h"
#include "SciLexer.h"
#if GTK
#include "ScintillaWidget.h"
#elif NCURSES
#include "ScintillaTerm.h"
#include "termkey.h"
#endif

#if GTK
typedef GtkWidget Scintilla;
#define SS(view, m, w, l) scintilla_send_message(SCINTILLA(view), m, w, l)
#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)
#define osx_signal(a, s, c) g_signal_connect(a, s, G_CALLBACK(c), 0)
#define focus_view(v) gtk_widget_grab_focus(v)
#define scintilla_delete(w) gtk_widget_destroy(w)
#if GTK_CHECK_VERSION(3,0,0)
#define gtk_statusbar_set_has_resize_grip(_,__)
#define gtk_combo_box_entry_new_with_model(m,_) \
  gtk_combo_box_new_with_model_and_entry(m)
#define gtk_combo_box_entry_set_text_column gtk_combo_box_set_entry_text_column
#define GTK_COMBO_BOX_ENTRY GTK_COMBO_BOX
#endif
#elif NCURSES
#define SS(view, m, w, l) scintilla_send_message(view, m, w, l)
#define focus_view(v) \
  SS(focused_view, SCI_SETFOCUS, 0, 0), SS(v, SCI_SETFOCUS, 1, 0)
#endif
#define copy(s) strcpy(malloc(strlen(s) + 1), s)

// Window
char *textadept_home = NULL;
Scintilla *focused_view;
#if GTK
GtkWidget *window, *menubar, *statusbar[2];
GtkAccelGroup *accel;
#if __OSX__
GtkOSXApplication *osxapp;
#endif
#endif
static void new_buffer(sptr_t);
static Scintilla *new_view(sptr_t);

// Find/Replace
#if GTK
typedef GtkWidget FindBox;
GtkWidget *find_entry, *replace_entry, *flabel, *rlabel;
typedef GtkWidget * FindButton;
FindButton fnext_button, fprev_button, r_button, ra_button;
typedef GtkWidget * Option;
typedef GtkListStore ListStore;
ListStore *find_store, *repl_store;
#elif NCURSES
typedef WINDOW FindBox;
char *find_text = NULL, *repl_text = NULL, *flabel = NULL, *rlabel = NULL;
typedef int FindButton;
FindButton fnext_button = 1, fprev_button = 2, r_button = 3, ra_button = 4;
typedef int Option;
typedef char * ListStore;
ListStore find_store[10] = {
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
}, repl_store[10] = {
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};
#endif
FindBox *findbox;
Option match_case = 0, whole_word = 0, lua_pattern = 0, in_files = 0;

// Command Entry
#if GTK
GtkWidget *command_entry;
GtkListStore *cc_store;
GtkEntryCompletion *command_entry_completion;
#elif NCURSES
char *command_text = NULL;
#endif

// Lua
lua_State *lua;
#if NCURSES
int quit = FALSE;
#endif
int closing = FALSE;
char *statusbar_text = NULL;
static int tVOID = 0, tINT = 1, tLENGTH = 2, /*tPOSITION = 3, tCOLOUR = 4,*/
           tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;
static int lL_init(lua_State *, int, char **, int);

#define l_setglobalview(l, v) (l_pushview(l, v), lua_setglobal(l, "view"))
#define l_setglobaldoc(l, d) (l_pushdoc(l, d), lua_setglobal(l, "buffer"))
#define l_setcfunction(l, n, k, f) \
  (lua_pushcfunction(l, f), lua_setfield(l, (n > 0) ? n : n - 1, k))
#define l_setmetatable(l, n, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_setcfunction(l, -1, "__index", i); \
    l_setcfunction(l, -1, "__newindex", ni); \
  } \
  lua_setmetatable(l, (n > 0) ? n : n - 1); \
}
LUALIB_API int (luaopen_lpeg) (lua_State *);
LUALIB_API int (luaopen_lfs) (lua_State *);

#if LUAJIT
#define LUA_OK 0
#define lua_rawlen lua_objlen
#define LUA_OPEQ 0
#define lua_compare(l, a, b, _) lua_equal(l, a, b)
#define lL_openlib(l, n, f) \
  (lua_pushcfunction(l, f), lua_pushstring(l, n), lua_call(l, 1, 0))
#else
#define lL_openlib(l, n, f) (luaL_requiref(l, n, f, 1), lua_pop(l, 1))
#endif

/**
 * Prints a warning.
 * @param s The warning to print.
 */
static void warn(const char *s) { printf("Warning: %s\n", s); }

/**
 * Emits an event.
 * @param L The Lua state.
 * @param name The event name.
 * @param ... Arguments to pass with the event. Each pair of arguments should be
 *   a Lua type followed by the data value itself. For LUA_TLIGHTUSERDATA and
 *   LUA_TTABLE types, push the data values to the stack and give the value
 *   returned by luaL_ref(); luaL_unref() will be called appropriately. The list
 *   must be terminated with a -1.
 * @return TRUE or FALSE depending on the boolean value returned by the event
 *   handler, if any.
 */
static int lL_event(lua_State *L, const char *name, ...) {
  int ret = FALSE;
  lua_getglobal(L, "events");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "emit");
    lua_remove(L, -2); // events table
    if (lua_isfunction(L, -1)) {
      lua_pushstring(L, name);
      int n = 1;
      va_list ap;
      va_start(ap, name);
      int type = va_arg(ap, int);
      while (type != -1) {
        void *arg = va_arg(ap, void*);
        if (type == LUA_TNIL)
          lua_pushnil(L);
        else if (type == LUA_TBOOLEAN)
          lua_pushboolean(L, (long)arg);
        else if (type == LUA_TNUMBER)
          lua_pushinteger(L, (long)arg);
        else if (type == LUA_TSTRING)
          lua_pushstring(L, (char *)arg);
        else if (type == LUA_TLIGHTUSERDATA || type == LUA_TTABLE) {
          long ref = (long)arg;
          lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
          luaL_unref(L, LUA_REGISTRYINDEX, ref);
        } else warn("events.emit: ignored invalid argument type");
        n++;
        type = va_arg(ap, int);
      }
      va_end(ap);
      if (lua_pcall(L, n, 1, 0) == LUA_OK)
        ret = lua_toboolean(L, -1);
      else
        lL_event(L, "error", LUA_TSTRING, lua_tostring(L, -1), -1);
      lua_pop(L, 1); // result
    } else lua_pop(L, 1); // non-function
  } else lua_pop(L, 1); // non-table
  return ret;
}

#if GTK
#if GLIB_CHECK_VERSION(2,28,0) && SINGLE_INSTANCE
/**
 * Processes a remote Textadept's command line arguments.
 */
static int a_command_line(GApplication *app, GApplicationCommandLine *cmdline,
                          void*_) {
  if (!lua) return 0; // only process argv for secondary/remote instances
  int argc = 0;
  char **argv = g_application_command_line_get_arguments(cmdline, &argc);
  if (argc > 1) {
    lua_getglobal(lua, "args"), lua_getfield(lua, -1, "process");
    lua_newtable(lua);
    const char *cwd = g_application_command_line_get_cwd(cmdline);
    lua_pushstring(lua, cwd ? cwd : ""), lua_rawseti(lua, -2, -1);
    for (int i = 0; i < argc; i++)
      lua_pushstring(lua, argv[i]), lua_rawseti(lua, -2, i);
    if (lua_pcall(lua, 1, 0, 0) != LUA_OK) {
      lL_event(lua, "error", LUA_TSTRING, lua_tostring(lua, -1), -1);
      lua_pop(lua, 1); // error message
    }
    lua_pop(lua, 1); // args
  }
  g_strfreev(argv);
  gtk_window_present(GTK_WINDOW(window));
  return 0;
}
#endif
#endif

/**
 * Adds the given text to the find/replace history list if it is not at the top.
 * @param text The text to add.
 * @param store The ListStore to add the text to.
 */
static void find_add_to_history(const char *text, ListStore *store) {
#if GTK
  char *first_item = NULL;
  GtkTreeIter iter;
  if (gtk_tree_model_get_iter_first(GTK_TREE_MODEL(store), &iter))
    gtk_tree_model_get(GTK_TREE_MODEL(store), &iter, 0, &first_item, -1);
  if (!first_item || strcmp(text, first_item) != 0) {
    gtk_list_store_prepend(store, &iter);
    gtk_list_store_set(store, &iter, 0, text, -1);
    g_free(first_item);
    int count = 1;
    while (gtk_tree_model_iter_next(GTK_TREE_MODEL(store), &iter))
      if (++count > 10) gtk_list_store_remove(store, &iter); // keep 10 items
  }
#elif NCURSES
  if (!store[0] || strcmp(text, store[0]) != 0) {
    if (store[9]) free(store[9]);
    for (int i = 0; i < 9; i++) store[i + 1] = store[i];
    store[0] = copy(text);
  }
#endif
}

/**
 * Signal for a find box button click.
 */
static void f_clicked(FindButton button, void*_) {
#if GTK
  const char *find_text = gtk_entry_get_text(GTK_ENTRY(find_entry));
  const char *repl_text = gtk_entry_get_text(GTK_ENTRY(replace_entry));
#endif
  if (strlen(find_text) == 0) return;
  if (button == fnext_button || button == fprev_button) {
    find_add_to_history(find_text, find_store);
    lL_event(lua, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN,
             button == fnext_button, -1);
  } else {
    find_add_to_history(repl_text, repl_store);
    if (button == r_button) {
      lL_event(lua, "replace", LUA_TSTRING, repl_text, -1);
      lL_event(lua, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN, 1, -1);
    } else
      lL_event(lua, "replace_all", LUA_TSTRING, find_text, LUA_TSTRING,
               repl_text, -1);
  }
}

static int lfind_next(lua_State *L) {
  return (f_clicked(fnext_button, NULL), 0);
}

static int lfind_prev(lua_State *L) {
  return (f_clicked(fprev_button, NULL), 0);
}

static int lfind_focus(lua_State *L) {
#if GTK
  if (!gtk_widget_has_focus(findbox)) {
    gtk_widget_show(findbox);
    gtk_widget_grab_focus(find_entry);
    gtk_widget_grab_default(fnext_button);
  } else {
    gtk_widget_grab_focus(focused_view);
    gtk_widget_hide(findbox);
  }
#elif NCURSES
  // TODO: toggle findbox focus.
#endif
  return 0;
}

static int lfind_replace(lua_State *L) {
  return (f_clicked(r_button, NULL), 0);
}

static int lfind_replace_all(lua_State *L) {
  return (f_clicked(ra_button, NULL), 0);
}

#if GTK
#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
#elif NCURSES
#define toggled(w) w
#endif
static int lfind__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
#if GTK
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(find_entry)));
#elif NCURSES
    lua_pushstring(L, find_text);
#endif
  else if (strcmp(key, "replace_entry_text") == 0)
#if GTK
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(replace_entry)));
#elif NCURSES
    lua_pushstring(L, repl_text);
#endif
  else if (strcmp(key, "match_case") == 0)
    lua_pushboolean(L, toggled(match_case));
  else if (strcmp(key, "whole_word") == 0)
    lua_pushboolean(L, toggled(whole_word));
  else if (strcmp(key, "lua") == 0)
    lua_pushboolean(L, toggled(lua_pattern));
  else if (strcmp(key, "in_files") == 0)
    lua_pushboolean(L, toggled(in_files));
  else
    lua_rawget(L, 1);
  return 1;
}

#if GTK
#define toggle(w, b) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), b)
#elif NCURSES
#define toggle(w, b) w = b
#endif
static int lfind__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0) {
#if GTK
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(L, 3));
#elif NCURSES
    if (find_text) free(find_text);
    find_text = copy(lua_tostring(L, 3));
#endif
  } else if (strcmp(key, "replace_entry_text") == 0) {
#if GTK
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(L, 3));
#elif NCURSES
    if (repl_text) free(repl_text);
    repl_text = copy(lua_tostring(L, 3));
#endif
  } else if (strcmp(key, "match_case") == 0)
    toggle(match_case, lua_toboolean(L, -1));
  else if (strcmp(key, "whole_word") == 0)
    toggle(whole_word, lua_toboolean(L, -1));
  else if (strcmp(key, "lua") == 0)
    toggle(lua_pattern, lua_toboolean(L, -1));
  else if (strcmp(key, "in_files") == 0)
    toggle(in_files, lua_toboolean(L, -1));
#if GTK
  else if (strcmp(key, "find_label_text") == 0)
    gtk_label_set_text_with_mnemonic(GTK_LABEL(flabel), lua_tostring(L, 3));
  else if (strcmp(key, "replace_label_text") == 0)
    gtk_label_set_text_with_mnemonic(GTK_LABEL(rlabel), lua_tostring(L, 3));
  else if (strcmp(key, "find_next_button_text") == 0)
    gtk_button_set_label(GTK_BUTTON(fnext_button), lua_tostring(L, 3));
  else if (strcmp(key, "find_prev_button_text") == 0)
    gtk_button_set_label(GTK_BUTTON(fprev_button), lua_tostring(L, 3));
  else if (strcmp(key, "replace_button_text") == 0)
    gtk_button_set_label(GTK_BUTTON(r_button), lua_tostring(L, 3));
  else if (strcmp(key, "replace_all_button_text") == 0)
    gtk_button_set_label(GTK_BUTTON(ra_button), lua_tostring(L, 3));
  else if (strcmp(key, "match_case_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(match_case), lua_tostring(L, 3));
  else if (strcmp(key, "whole_word_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(whole_word), lua_tostring(L, 3));
  else if (strcmp(key, "lua_pattern_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(lua_pattern), lua_tostring(L, 3));
  else if (strcmp(key, "in_files_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(in_files), lua_tostring(L, 3));
#endif
  else
    lua_rawset(L, 1);
  return 0;
}

static int lce_focus(lua_State *L) {
#if GTK
  if (!gtk_widget_has_focus(command_entry)) {
    gtk_widget_show(command_entry);
    gtk_widget_grab_focus(command_entry);
  } else {
    gtk_widget_hide(command_entry);
    gtk_widget_grab_focus(focused_view);
  }
#elif NCURSES
  // TODO: ce toggle focus.
#endif
  return 0;
}

static int lce_show_completions(lua_State *L) {
#if GTK
  luaL_checktype(L, 1, LUA_TTABLE);
  GtkEntryCompletion *completion = gtk_entry_get_completion(
                                   GTK_ENTRY(command_entry));
  GtkListStore *store = GTK_LIST_STORE(
                        gtk_entry_completion_get_model(completion));
  gtk_list_store_clear(store);
  lua_pushnil(L);
  while (lua_next(L, 1)) {
    if (lua_type(L, -1) == LUA_TSTRING) {
      GtkTreeIter iter;
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, 0, lua_tostring(L, -1), -1);
    } else warn("command_entry.show_completions: non-string value ignored");
    lua_pop(L, 1); // value
  }
  gtk_entry_completion_complete(completion);
#endif
  return 0;
}

static int lce__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0)
#if GTK
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(command_entry)));
#elif NCURSES
    lua_pushstring(L, command_text);
#endif
  else
    lua_rawget(L, 1);
  return 1;
}

static int lce__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0) {
#if GTK
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(L, 3));
#elif NCURSES
    if (command_text) free(command_text);
    command_text = copy(lua_tostring(L, 3));
#endif
  } else lua_rawset(L, 1);
  return 0;
}

static int lgui_dialog(lua_State *L) {
  GCDialogType type = gcocoadialog_type(luaL_checkstring(L, 1));
  int i, j, k, n = lua_gettop(L) - 1, argc = n;
  for (i = 2; i < n + 2; i++)
    if (lua_istable(L, i)) argc += lua_rawlen(L, i) - 1;
  const char **argv = malloc((argc + 1) * sizeof(const char *));
  for (i = 0, j = 2; j < n + 2; j++)
    if (lua_istable(L, j)) {
      int len = lua_rawlen(L, j);
      for (k = 1; k <= len; k++) {
        lua_rawgeti(L, j, k);
        argv[i++] = luaL_checkstring(L, -1);
        lua_pop(L, 1);
      }
    } else argv[i++] = luaL_checkstring(L, j);
  argv[argc] = 0;
  char *out = gcocoadialog(type, argc, argv);
  lua_pushstring(L, out);
  free(out), free(argv);
  return 1;
}

/**
 * Pushes the Scintilla view onto the stack.
 * The view must have previously been added with lL_addview.
 * @param L The Lua state.
 * @param view The Scintilla view to push.
 * @see lL_addview
 */
static void l_pushview(lua_State *L, Scintilla *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_pushlightuserdata(L, view), lua_gettable(L, -2);
  lua_remove(L, -2); // views
}

#if GTK
#define child1(p) gtk_paned_get_child1(GTK_PANED(p))
#define child2(p) gtk_paned_get_child2(GTK_PANED(p))

static void l_pushsplittable(lua_State *L, GtkWidget *c1, GtkWidget *c2) {
  lua_newtable(L);
  if (GTK_IS_PANED(c1))
    l_pushsplittable(L, child1(c1), child2(c1));
  else
    l_pushview(L, c1);
  lua_rawseti(L, -2, 1);
  if (GTK_IS_PANED(c2))
    l_pushsplittable(L, child1(c2), child2(c2));
  else
    l_pushview(L, c2);
  lua_rawseti(L, -2, 2);
  lua_pushboolean(L, GTK_IS_HPANED(gtk_widget_get_parent(c1)));
  lua_setfield(L, -2, "vertical");
  int size = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(c1)));
  lua_pushinteger(L, size), lua_setfield(L, -2, "size");
}
#endif

static int lgui_get_split_table(lua_State *L) {
#if GTK
  GtkWidget *pane = gtk_widget_get_parent(focused_view);
  if (GTK_IS_PANED(pane)) {
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_pushsplittable(L, child1(pane), child2(pane));
  } else l_pushview(L, focused_view);
#elif NCURSES
  l_pushview(L, focused_view); // TODO: push split table
#endif
  return 1;
}

/**
 * Returns the view at the given acceptable index as a Scintilla view.
 * @param L The Lua state.
 * @param index Stack index of the view.
 * @return Scintilla view
 */
static Scintilla *l_toview(lua_State *L, int index) {
  lua_getfield(L, index, "widget_pointer");
  Scintilla *view = (Scintilla *)lua_touserdata(L, -1);
  lua_pop(L, 1); // widget pointer
  return view;
}

/**
 * Pushes the Scintilla document onto the stack.
 * The document must have previously been added with lL_adddoc.
 * @param L The Lua state.
 * @param doc The document to push.
 * @see lL_adddoc
 */
static void l_pushdoc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_pushlightuserdata(L, (sptr_t *)doc), lua_gettable(L, -2);
  lua_remove(L, -2); // buffers
}

/**
 * Change focus to the given Scintilla view.
 * Generates 'view_before_switch' and 'view_after_switch' events.
 * @param view The Scintilla view to focus.
 */
static void goto_view(Scintilla *view) {
  if (!closing) lL_event(lua, "view_before_switch", -1);
  focused_view = view;
  l_setglobalview(lua, view);
  l_setglobaldoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!closing) lL_event(lua, "view_after_switch", -1);
}

static int lgui_goto_view(lua_State *L) {
  int n = luaL_checkinteger(L, 1), relative = lua_toboolean(L, 2);
  if (relative && n == 0) return 0;
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  if (relative) {
    l_pushview(L, focused_view), lua_gettable(L, -2);
    n = lua_tointeger(L, -1) + n;
    if (n > lua_rawlen(L, -2))
      n = 1;
    else if (n < 1)
      n = lua_rawlen(L, -2);
    lua_rawgeti(L, -2, n);
  } else {
    luaL_argcheck(L, n > 0 && n <= lua_rawlen(L, -1), 1,
                  "no View exists at that index");
    lua_rawgeti(L, -1, n);
  }
  Scintilla *view = l_toview(L, -1);
  focus_view(view);
#if GTK
  // gui.dialog() interferes with focus so gtk_widget_grab_focus() does not
  // always work. If this is the case, ensure goto_view() is called.
  if (!gtk_widget_has_focus(view)) goto_view(view);
#endif
  return 0;
}

/**
 * Returns the value t[n] as an integer where t is the value at the given valid
 * index.
 * The access is raw; that is, it does not invoke metamethods.
 * @param L The Lua state.
 * @param index The stack index of the table.
 * @param n The index in the table to get.
 * @return integer
 */
static int l_rawgetiint(lua_State *L, int index, int n) {
  lua_rawgeti(L, index, n);
  int ret = lua_tointeger(L, -1);
  lua_pop(L, 1); // integer
  return ret;
}

/**
 * Pushes a menu created from the table at the given valid index onto the stack.
 * Consult the LuaDoc for the table format.
 * @param L The Lua state.
 * @param index The stack index of the table to create the menu from.
 * @param callback An optional GTK callback function associated with each menu
 *   item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 */
static void l_pushmenu(lua_State *L, int index, void (*callback)(void),
                       int submenu) {
#if GTK
  GtkWidget *menu = gtk_menu_new(), *menu_item = 0, *submenu_root = 0;
  const char *label;
  lua_pushvalue(L, index); // copy to stack top so relative indices can be used
  lua_getfield(L, -1, "title");
  if (!lua_isnil(L, -1) || submenu) { // title required for submenu
    label = !lua_isnil(L, -1) ? lua_tostring(L, -1) : "notitle";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(L, 1); // title
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_istable(L, -1)) {
      lua_getfield(L, -1, "title");
      int is_submenu = !lua_isnil(L, -1);
      lua_pop(L, 1); // title
      if (is_submenu) {
        l_pushmenu(L, -1, callback, TRUE);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              (GtkWidget *)lua_touserdata(L, -1));
        lua_pop(L, 1); // menu
      } else if (lua_rawlen(L, -1) == 2 || lua_rawlen(L, -1) == 4) {
        lua_rawgeti(L, -1, 1);
        label = lua_tostring(L, -1);
        lua_pop(L, 1); // label
        int menu_id = l_rawgetiint(L, -1, 2);
        int key = l_rawgetiint(L, -1, 3);
        int modifiers = l_rawgetiint(L, -1, 4);
        if (label) {
          if (g_str_has_prefix(label, "gtk-"))
            menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
          else if (strcmp(label, "separator") == 0)
            menu_item = gtk_separator_menu_item_new();
          else
            menu_item = gtk_menu_item_new_with_mnemonic(label);
          if (key || modifiers)
              gtk_widget_add_accelerator(menu_item, "activate", accel, key,
                                         modifiers, GTK_ACCEL_VISIBLE);
          g_signal_connect(menu_item, "activate", G_CALLBACK(callback),
                           GINT_TO_POINTER(menu_id));
          gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
        }
      } else warn("menu: { 'label', id_num [, keycode, mods] } expected");
    }
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // table copy
  lua_pushlightuserdata(L, !submenu_root ? menu : submenu_root);
#elif NCURSES
  lua_pushnil(L); // TODO: create and push menu (memory management?).
#endif
}

#if GTK
static void m_clicked(GtkWidget *menu, void *id) {
  lL_event(lua, "menu_clicked", LUA_TNUMBER, GPOINTER_TO_INT(id), -1);
}
#endif

static int lgui_menu(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
#if GTK
  l_pushmenu(L, -1, m_clicked, FALSE);
#elif NCURSES
  // TODO: create menu and manage memory.
#endif
  return 1;
}

static int lgui__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "statusbar_text") == 0)
    lua_pushstring(L, statusbar_text);
  else if (strcmp(key, "clipboard_text") == 0) {
#if GTK
    char *text = gtk_clipboard_wait_for_text(
                 gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    lua_pushstring(L, text ? text : "");
    if (text) free(text);
#elif NCURSES
    lua_pushstring(L, ""); // TODO: get Xclipboard text?
#endif
  } else if (strcmp(key, "size") == 0) {
#if GTK
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
#elif NCURSES
    int width = COLS, height = LINES;
#endif
    lua_newtable(L);
    lua_pushinteger(L, width), lua_rawseti(L, -2, 1);
    lua_pushinteger(L, height), lua_rawseti(L, -2, 2);
  } else lua_rawget(L, 1);
  return 1;
}

static void set_statusbar_text(const char *text, int bar) {
#if GTK
  if (!statusbar[0] || !statusbar[1]) return; // unavailable on startup
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar[bar]), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[bar]), 0, text);
#elif NCURSES
  for (int i = ((bar == 0) ? 0 : 20); i < ((bar == 0) ? 20 : COLS); i++)
    mvaddch(LINES - 1, i, ' '); // clear statusbar
  mvaddstr(LINES - 1, (bar == 0) ? 0 : COLS - strlen(text), text), refresh();
#endif
}

static int lgui__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0) {
#if GTK
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(L, 3));
#elif NCURSES
    for (int i = 0; i < COLS; i++) mvaddch(0, i, ' '); // clear titlebar
    mvaddstr(0, 0, lua_tostring(L, 3)), refresh();
#endif
  } else if (strcmp(key, "clipboard_text") == 0)
    luaL_argerror(L, 3, "read-only property");
  else if (strcmp(key, "docstatusbar_text") == 0)
    set_statusbar_text(lua_tostring(L, 3), 1);
  else if (strcmp(key, "statusbar_text") == 0) {
    if (statusbar_text) free(statusbar_text);
    statusbar_text = copy(luaL_optstring(L, 3, ""));
    set_statusbar_text(statusbar_text, 0);
  } else if (strcmp(key, "menubar") == 0) {
#if GTK
    luaL_argcheck(L, lua_istable(L, 3), 3, "table of menus expected");
    GtkWidget *new_menubar = gtk_menu_bar_new();
    lua_pushnil(L);
    while (lua_next(L, 3)) {
      luaL_argcheck(L, lua_isuserdata(L, -1), 3, "table of menus expected");
      GtkWidget *menu_item = (GtkWidget *)lua_touserdata(L, -1);
      gtk_menu_shell_append(GTK_MENU_SHELL(new_menubar), menu_item);
      lua_pop(L, 1); // value
    }
    GtkWidget *vbox = gtk_widget_get_parent(menubar);
    gtk_container_remove(GTK_CONTAINER(vbox), menubar);
    menubar = new_menubar;
    gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);
    gtk_box_reorder_child(GTK_BOX(vbox), menubar, 0);
    gtk_widget_show_all(menubar);
#if __OSX__
    gtk_osxapplication_set_menu_bar(osxapp, GTK_MENU_SHELL(menubar));
    gtk_widget_hide(menubar);
#endif
#endif
  } else if (strcmp(key, "size") == 0) {
#if GTK
    luaL_argcheck(L, lua_istable(L, 3) && lua_rawlen(L, 3) == 2, 3,
                  "{ width, height } table expected");
    int w = l_rawgetiint(L, 3, 1), h = l_rawgetiint(L, 3, 2);
    if (w > 0 && h > 0) gtk_window_resize(GTK_WINDOW(window), w, h);
#endif
  } else lua_rawset(L, 1);
  return 0;
}

/**
 * Checks whether the function argument narg is a Scintilla document. If not,
 * raises an error.
 * @param L The Lua state.
 * @param narg The stack index of the Scintilla document.
 * @return Scintilla document
 */
static void lL_globaldoccheck(lua_State *L, int narg) {
  luaL_getmetatable(L, "ta_buffer");
  lua_getmetatable(L, (narg > 0) ? narg : narg - 1);
  luaL_argcheck(L, lua_compare(L, -1, -2, LUA_OPEQ), narg, "Buffer expected");
  lua_getfield(L, (narg > 0) ? narg : narg - 2, "doc_pointer");
  sptr_t doc = (sptr_t)lua_touserdata(L, -1);
  luaL_argcheck(L, doc == SS(focused_view, SCI_GETDOCPOINTER, 0, 0), narg,
                "this buffer is not the current one");
  lua_pop(L, 3); // doc_pointer, metatable, metatable
}

static int lbuffer_check_global(lua_State *L) {
  lL_globaldoccheck(L, 1);
  return 0;
}

/**
 * Returns the buffer at the given acceptable index as a Scintilla document.
 * @param L The Lua state.
 * @param index Stack index of the buffer.
 * @return Scintilla document
 */
static sptr_t l_todoc(lua_State *L, int index) {
  lua_getfield(L, index, "doc_pointer");
  sptr_t doc = (sptr_t)lua_touserdata(L, -1);
  lua_pop(L, 1); // doc_pointer
  return doc;
}

/**
 * Switches to a document in the given view.
 * @param L The Lua state.
 * @param view The Scintilla view.
 * @param n Relative or absolute index of the document to switch to. An absolute
 *   n of -1 represents the last document.
 * @param relative Flag indicating whether or not n is relative.
 */
static void lL_gotodoc(lua_State *L, Scintilla *view, int n, int relative) {
  if (relative && n == 0) return;
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (relative) {
    l_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(L, -2);
    n = lua_tointeger(L, -1) + n;
    lua_pop(L, 1); // index
    if (n > lua_rawlen(L, -1))
      n = 1;
    else if (n < 1)
      n = lua_rawlen(L, -1);
    lua_rawgeti(L, -1, n);
  } else {
    luaL_argcheck(L, (n > 0 && n <= lua_rawlen(L, -1)) || n == -1, 2,
                  "no Buffer exists at that index");
    lua_rawgeti(L, -1, (n > 0) ? n : lua_rawlen(L, -1));
  }
  sptr_t doc = l_todoc(L, -1);
  SS(view, SCI_SETDOCPOINTER, 0, doc);
  l_setglobaldoc(L, doc);
  lua_pop(L, 2); // buffer table and buffers
}

/**
 * Removes the Scintilla document from the 'buffers' registry table.
 * The document must have been previously added with lL_adddoc.
 * It is removed from any other views showing it first. Therefore, ensure the
 * length of 'buffers' is more than one unless quitting the application.
 * @param L The Lua state.
 * @param doc The Scintilla document to remove.
 * @see lL_adddoc
 */
static void lL_removedoc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_isnumber(L, -2)) {
      Scintilla *view = l_toview(L, -1);
      if (doc == SS(view, SCI_GETDOCPOINTER, 0, 0))
        lL_gotodoc(L, view, -1, TRUE);
    }
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // views
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_isnumber(L, -2) && doc != l_todoc(L, -1)) {
      lua_getfield(L, -1, "doc_pointer");
      // bs[userdata] = b, bs[#bs + 1] = b, bs[b] = #bs
      lua_pushvalue(L, -2), lua_rawseti(L, -6, lua_rawlen(L, -6) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -6);
      lua_pushinteger(L, lua_rawlen(L, -4)), lua_settable(L, -5);
    } else lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // buffers
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_setglobal(L, "_BUFFERS");
}

/**
 * Removes the Scintilla buffer from the current Scintilla view.
 * @param doc The Scintilla document.
 * @see lL_removedoc
 */
static void delete_buffer(sptr_t doc) {
  lL_removedoc(lua, doc);
  SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

static int lbuffer_delete(lua_State *L) {
  lL_globaldoccheck(L, 1);
  sptr_t doc = SS(focused_view, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (lua_rawlen(L, -1) == 1) new_buffer(0);
  lL_gotodoc(L, focused_view, -1, TRUE);
  delete_buffer(doc);
  lL_event(L, "buffer_deleted", -1),
  lL_event(L, "buffer_after_switch", -1);
  return 0;
}

static int lbuffer_text_range(lua_State *L) {
  lL_globaldoccheck(L, 1);
  struct Sci_TextRange tr;
  tr.chrg.cpMin = luaL_checkinteger(L, 2);
  tr.chrg.cpMax = luaL_checkinteger(L, 3);
  luaL_argcheck(L, tr.chrg.cpMin <= tr.chrg.cpMax, 3, "start > end");
  tr.lpstrText = malloc(tr.chrg.cpMax - tr.chrg.cpMin + 1);
  SS(focused_view, SCI_GETTEXTRANGE, 0, (long)(&tr));
  lua_pushlstring(L, tr.lpstrText, tr.chrg.cpMax - tr.chrg.cpMin);
  if (tr.lpstrText) free(tr.lpstrText);
  return 1;
}

/**
 * Checks whether the function argument narg is the given Scintilla parameter
 * type and returns it cast to the proper type.
 * @param L The Lua state.
 * @param narg The stack index of the Scintilla parameter.
 * @param type The Scintilla type to convert to.
 * @return Scintilla param
 */
static long lL_checkscintillaparam(lua_State *L, int *narg, int type) {
  if (type == tSTRING)
    return (long)luaL_checkstring(L, (*narg)++);
  else if (type == tBOOL)
    return lua_toboolean(L, (*narg)++);
  else if (type == tKEYMOD) {
    int key = luaL_checkinteger(L, (*narg)++) & 0xFFFF;
    return key | ((luaL_checkinteger(L, (*narg)++) &
                 (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  } else if (type > tVOID && type < tBOOL)
    return luaL_checklong(L, (*narg)++);
  else
    return 0;
}

/**
 * Calls a function as a Scintilla function.
 * Does not remove any arguments from the stack, but does push results.
 * @param L The Lua state.
 * @param msg The Scintilla message.
 * @param wtype The type of Scintilla wParam.
 * @param ltype The type of Scintilla lParam.
 * @param rtype The type of the Scintilla return.
 * @param arg The stack index of the first Scintilla parameter. Subsequent
 *   elements will also be passed to Scintilla as needed.
 * @return number of results pushed onto the stack.
 * @see lL_checkscintillaparam
 */
static int l_callscintilla(lua_State *L, int msg, int wtype, int ltype,
                           int rtype, int arg) {
  uptr_t wparam = 0;
  sptr_t lparam = 0, len = 0;
  int params_needed = 2, string_return = FALSE;
  char *return_string = 0;

  // Even though the SCI_PRIVATELEXERCALL interface has ltype int, the LPeg
  // lexer API uses different types depending on wparam. Modify ltype
  // appropriately. See the LPeg lexer API for more information.
  if (msg == SCI_PRIVATELEXERCALL) {
    ltype = tSTRINGRESULT;
    int c = luaL_checklong(L, arg);
    if (c == SCI_GETDIRECTFUNCTION || c == SCI_SETDOCPOINTER)
      ltype = tINT;
    else if (c == SCI_SETLEXERLANGUAGE)
      ltype = tSTRING;
  }

  // Set wParam and lParam appropriately for Scintilla based on wtype and ltype.
  if (wtype == tLENGTH && ltype == tSTRING) {
    wparam = (uptr_t)lua_rawlen(L, arg);
    lparam = (sptr_t)luaL_checkstring(L, arg);
    params_needed = 0;
  } else if (ltype == tSTRINGRESULT) {
    string_return = TRUE;
    params_needed = (wtype == tLENGTH) ? 0 : 1;
  }
  if (params_needed > 0) wparam = lL_checkscintillaparam(L, &arg, wtype);
  if (params_needed > 1) lparam = lL_checkscintillaparam(L, &arg, ltype);
  if (string_return) { // create a buffer for the return string
    len = SS(focused_view, msg, wparam, 0);
    if (wtype == tLENGTH) wparam = len;
    return_string = malloc(len + 1), return_string[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    lparam = (sptr_t)return_string;
  }

  // Send the message to Scintilla and return the appropriate values.
  sptr_t result = SS(focused_view, msg, wparam, lparam);
  arg = lua_gettop(L);
  if (string_return) lua_pushlstring(L, return_string, len);
  if (rtype == tBOOL) lua_pushboolean(L, result);
  if (rtype > tVOID && rtype < tBOOL) lua_pushinteger(L, result);
  if (return_string) free(return_string);
  return lua_gettop(L) - arg;
}

static int lbuf_closure(lua_State *L) {
  // If optional buffer argument is given, check it.
  if (lua_istable(L, 1)) lL_globaldoccheck(L, 1);
  // Interface table is of the form { msg, rtype, wtype, ltype }.
  return l_callscintilla(L, l_rawgetiint(L, lua_upvalueindex(1), 1),
                         l_rawgetiint(L, lua_upvalueindex(1), 3),
                         l_rawgetiint(L, lua_upvalueindex(1), 4),
                         l_rawgetiint(L, lua_upvalueindex(1), 2),
                         lua_istable(L, 1) ? 2 : 1);
}

static int lbuf_property(lua_State *L) {
  int newindex = (lua_gettop(L) == 3);
  luaL_getmetatable(L, "ta_buffer");
  lua_getmetatable(L, 1); // metatable can be either ta_buffer or ta_bufferp
  int is_buffer = lua_compare(L, -1, -2, LUA_OPEQ);
  lua_pop(L, 2); // metatable, metatable

  // If the key is a Scintilla function, return a callable closure.
  if (is_buffer && !newindex) {
    lua_getfield(L, LUA_REGISTRYINDEX, "ta_functions");
    lua_pushvalue(L, 2), lua_gettable(L, -2);
    if (lua_istable(L, -1)) return (lua_pushcclosure(L, lbuf_closure, 1), 1);
    lua_pop(L, 2); // non-table, ta_functions
  }

  // If the key is a Scintilla property, determine if it is an indexible one or
  // not. If so, return a table with the appropriate metatable; otherwise call
  // Scintilla to get or set the property's value.
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties");
  if (is_buffer)
    lua_pushvalue(L, 2); // key is given
  else
    lua_getfield(L, 1, "property"); // indexible property
  lua_gettable(L, -2);
  if (lua_istable(L, -1)) {
    // Interface table is of the form { get_id, set_id, rtype, wtype }.
    if (!is_buffer)
      lua_getfield(L, 1, "buffer"), lL_globaldoccheck(L, -1), lua_pop(L, 1);
    else
      lL_globaldoccheck(L, 1);
    if (is_buffer && l_rawgetiint(L, -1, 4) != tVOID) { // indexible property
      lua_newtable(L);
      lua_pushvalue(L, 2), lua_setfield(L, -2, "property");
      lua_pushvalue(L, 1), lua_setfield(L, -2, "buffer");
      l_setmetatable(L, -1, "ta_bufferp", lbuf_property, lbuf_property);
      return 1;
    }
    int msg = l_rawgetiint(L, -1, !newindex ? 1 : 2);
    int wtype = l_rawgetiint(L, -1, !newindex ? 4 : 3);
    int ltype = !newindex ? tVOID : l_rawgetiint(L, -1, 4);
    int rtype = !newindex ? l_rawgetiint(L, -1, 3) : tVOID;
    if (newindex && (ltype != tVOID || wtype == tSTRING)) {
      int temp = wtype;
      wtype = ltype, ltype = temp;
    }
    luaL_argcheck(L, msg != 0, !newindex ? 2 : 3,
                  !newindex ? "write-only property" : "read-only property");
    return l_callscintilla(L, msg, wtype, ltype, rtype,
                           (!is_buffer || !newindex) ? 2 : 3);
  } else lua_pop(L, 2); // non-table, ta_properties

  !newindex ? lua_rawget(L, 1) : lua_rawset(L, 1);
  return 1;
}

/**
 * Adds a Scintilla document with a metatable to the 'buffers' registry table.
 * @param L The Lua state.
 * @param doc The Scintilla document to add.
 */
static void lL_adddoc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_newtable(L);
  lua_pushlightuserdata(L, (sptr_t *)doc); // TODO: can this fail?
  lua_pushvalue(L, -1), lua_setfield(L, -3, "doc_pointer");
  l_setcfunction(L, -2, "check_global", lbuffer_check_global);
  l_setcfunction(L, -2, "delete", lbuffer_delete);
  l_setcfunction(L, -2, "text_range", lbuffer_text_range);
  l_setmetatable(L, -2, "ta_buffer", lbuf_property, lbuf_property);
  // bs[userdata] = b, bs[#bs + 1] = b, bs[b] = #bs
  lua_pushvalue(L, -2), lua_settable(L, -4);
  lua_pushvalue(L, -1), lua_rawseti(L, -3, lua_rawlen(L, -3) + 1);
  lua_pushinteger(L, lua_rawlen(L, -2)), lua_settable(L, -3);
  lua_pop(L, 1); // buffers
}

/**
 * Creates a new Scintilla document and adds it to the Lua state.
 * Generates 'buffer_before_switch' and 'buffer_new' events.
 * @param doc Almost always zero, except for the first Scintilla view created,
 *   in which its doc pointer would be given here.
 * @see lL_adddoc
 */
static void new_buffer(sptr_t doc) {
  if (!doc) { // create the new document
    doc = SS(focused_view, SCI_CREATEDOCUMENT, 0, 0);
    lL_event(lua, "buffer_before_switch", -1);
    lL_adddoc(lua, doc);
    lL_gotodoc(lua, focused_view, -1, FALSE);
  } else {
    // The first Scintilla window already has a pre-created buffer.
    lL_adddoc(lua, doc);
    SS(focused_view, SCI_ADDREFDOCUMENT, 0, doc);
  }
  l_setglobaldoc(lua, doc);
  lL_event(lua, "buffer_new", -1);
}

static int lbuffer_new(lua_State *L) {
  new_buffer(0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_rawgeti(L, -1, lua_rawlen(L, -1));
  return 1;
}

static int lquit(lua_State *L) {
#if GTK
  GdkEventAny event;
  event.type = GDK_DELETE;
  event.window = gtk_widget_get_window(window);
  event.send_event = TRUE;
  gdk_event_put((GdkEvent *)(&event));
#elif NCURSES
  quit = true;
#endif
  return 0;
}

/**
 * Loads and runs the given file.
 * @param L The Lua state.
 * @param filename The file name relative to textadept_home.
 * @return 1 if there are no errors or 0 in case of errors.
 */
static int lL_dofile(lua_State *L, const char *filename) {
  char *file = malloc(strlen(textadept_home) + 1 + strlen(filename) + 1);
  stpcpy(stpcpy(stpcpy(file, textadept_home), "/"), filename);
  int ok = (luaL_dofile(L, file) == LUA_OK);
  if (!ok) {
#if GTK
    GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                               GTK_MESSAGE_ERROR,
                                               GTK_BUTTONS_OK, "%s\n",
                                               lua_tostring(L, -1));
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
#elif NCURSES
    WINDOW *win = newwin(0, 0, 0, 0);
    wprintw(win, lua_tostring(L, -1)), wrefresh(win);
    getch();
    delwin(win);
#endif
    lua_settop(L, 0);
  }
  free(file);
  return ok;
}

static int lreset(lua_State *L) {
  lL_event(L, "reset_before", -1);
  lL_init(L, 0, NULL, TRUE);
  lua_pushboolean(L, TRUE), lua_setglobal(L, "RESETTING");
  l_setglobalview(L, focused_view);
  l_setglobaldoc(L, SS(focused_view, SCI_GETDOCPOINTER, 0, 0));
  lL_dofile(L, "init.lua");
  lua_pushnil(L), lua_setglobal(L, "RESETTING");
  lL_event(L, "reset_after", -1);
  return 0;
}

#if GTK
static int emit_timeout(void *data) {
  int *refs = (int *)data;
  lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
  int nargs = 0, repeat = TRUE;
  while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
  int ok = (lua_pcall(lua, nargs - 1, 1, 0) == LUA_OK);
  if (!ok || !lua_toboolean(lua, -1)) {
    while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
    repeat = FALSE;
    if (!ok) lL_event(lua, "error", LUA_TSTRING, lua_tostring(lua, -1), -1);
  }
  lua_pop(lua, 1); // result
  return repeat;
}
#endif

static int ltimeout(lua_State *L) {
#if GTK
  double timeout = luaL_checknumber(L, 1);
  luaL_argcheck(L, timeout > 0, 1, "timeout must be > 0");
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  int n = lua_gettop(L);
  int *refs = (int *)calloc(n, sizeof(int));
  lua_pushvalue(L, 2);
  refs[0] = luaL_ref(L, LUA_REGISTRYINDEX);
  for (int i = 3; i <= n; i++) {
    lua_pushvalue(L, i);
    refs[i - 2] = luaL_ref(L, LUA_REGISTRYINDEX);
  }
  g_timeout_add(timeout * 1000, emit_timeout, (void *)refs);
#elif NCURSES
  luaL_error(L, "not implemented in this environment");
#endif
  return 0;
}

static int lstring_iconv(lua_State *L) {
  size_t text_len = 0;
  char *text = (char *)luaL_checklstring(L, 1, &text_len);
  const char *to = luaL_checkstring(L, 2);
  const char *from = luaL_checkstring(L, 3);
  int converted = FALSE;
  iconv_t cd = iconv_open(to, from);
  if (cd != (iconv_t) -1) {
    char *out = malloc(text_len + 1);
    char *outp = out;
    size_t inbytesleft = text_len, outbytesleft = text_len;
    if (iconv(cd, &text, &inbytesleft, &outp, &outbytesleft) != -1) {
      lua_pushlstring(L, out, outp - out);
      converted = TRUE;
    }
    free(out);
    iconv_close(cd);
  }
  if (!converted) luaL_error(L, "Conversion failed");
  return 1;
}

/**
 * Clears a table at the given valid index by setting all of its keys to nil.
 * @param L The Lua state.
 * @param index The stack index of the table.
 */
static void lL_cleartable(lua_State *L, int index) {
  lua_pushvalue(L, index); // copy to stack top so relative indices can be used
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    lua_pop(L, 1); // value
    lua_pushnil(L), lua_rawset(L, -3);
    lua_pushnil(L); // key for lua_next
  }
  lua_pop(L, 1); // table copy
}

/**
 * Initializes or re-initializes the Lua state.
 * Populates the state with global variables and functions, then runs the
 * 'core/init.lua' script.
 * @param L The Lua state.
 * @param argc The number of command line parameters.
 * @param argv The array of command line parameters.
 * @param reinit Flag indicating whether or not to reinitialize the Lua state.
 * @return TRUE on success, FALSE otherwise.
 */
static int lL_init(lua_State *L, int argc, char **argv, int reinit) {
  if (!reinit) {
    lua_newtable(L);
    for (int i = 0; i < argc; i++)
      lua_pushstring(L, argv[i]), lua_rawseti(L, -2, i);
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_arg");
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, "ta_buffers");
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, "ta_views");
  } else { // clear package.loaded and _G
    lua_getglobal(L, "package"), lua_getfield(L, -1, "loaded");
    lL_cleartable(L, -1);
    lua_pop(L, 2); // package and package.loaded
#if !LUAJIT
    lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
    lL_cleartable(L, -1);
    lua_pop(L, 1); // _G
#else
    lL_cleartable(L, LUA_GLOBALSINDEX);
#endif
  }
  luaL_openlibs(L);
  lL_openlib(L, "lpeg", luaopen_lpeg);
  lL_openlib(L, "lfs", luaopen_lfs);

  lua_newtable(L);
  lua_newtable(L);
  l_setcfunction(L, -1, "find_next", lfind_next);
  l_setcfunction(L, -1, "find_prev", lfind_prev);
  l_setcfunction(L, -1, "focus", lfind_focus);
  l_setcfunction(L, -1, "replace", lfind_replace);
  l_setcfunction(L, -1, "replace_all", lfind_replace_all);
  l_setmetatable(L, -1, "ta_find", lfind__index, lfind__newindex);
  lua_setfield(L, -2, "find");
  lua_newtable(L);
  l_setcfunction(L, -1, "focus", lce_focus);
  l_setcfunction(L, -1, "show_completions", lce_show_completions);
  l_setmetatable(L, -1, "ta_command_entry", lce__index, lce__newindex);
  lua_setfield(L, -2, "command_entry");
  l_setcfunction(L, -1, "dialog", lgui_dialog);
  l_setcfunction(L, -1, "get_split_table", lgui_get_split_table);
  l_setcfunction(L, -1, "goto_view", lgui_goto_view);
  l_setcfunction(L, -1, "menu", lgui_menu);
  l_setmetatable(L, -1, "ta_gui", lgui__index, lgui__newindex);
  lua_setglobal(L, "gui");

  lua_getglobal(L, "_G");
  l_setcfunction(L, -1, "new_buffer", lbuffer_new);
  l_setcfunction(L, -1, "quit", lquit);
  l_setcfunction(L, -1, "reset", lreset);
  l_setcfunction(L, -1, "timeout", ltimeout);
  lua_pop(L, 1); // _G

  lua_getglobal(L, "string");
  l_setcfunction(L, -1, "iconv", lstring_iconv);
  lua_pop(L, 1); // string

  lua_getfield(L, LUA_REGISTRYINDEX, "ta_arg"), lua_setglobal(L, "arg");
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_setglobal(L, "_BUFFERS");
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views"), lua_setglobal(L, "_VIEWS");
  lua_pushstring(L, textadept_home), lua_setglobal(L, "_HOME");
#if __WIN32__
  lua_pushboolean(L, 1), lua_setglobal(L, "WIN32");
#elif __OSX__
  lua_pushboolean(L, 1), lua_setglobal(L, "OSX");
#endif
#if GTK
  const char *charset = 0;
  g_get_charset(&charset);
  lua_pushstring(L, charset), lua_setglobal(L, "_CHARSET");
#elif NCURSES
  lua_pushboolean(L, 1), lua_setglobal(L, "NCURSES");
  lua_pushstring(L, "UTF-8"), lua_setglobal(L, "_CHARSET"); // TODO: get charset
#endif


  if (lL_dofile(L, "core/init.lua")) {
    lua_getglobal(L, "_SCINTILLA");
    lua_getfield(L, -1, "constants");
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_constants");
    lua_getfield(L, -1, "functions");
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_functions");
    lua_getfield(L, -1, "properties");
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_properties");
    lua_pop(L, 1); // _SCINTILLA
    return TRUE;
  }
  lua_close(L);
  return FALSE;
}

#if GTK
/**
 * Signal for a Textadept window focus change.
 */
static int w_focus(GtkWidget*_, GdkEventFocus *event, void*__) {
  if (focused_view && !gtk_widget_has_focus(focused_view))
    gtk_widget_grab_focus(focused_view);
  return FALSE;
}

/**
 * Signal for a Textadept keypress.
 * Currently handled keypresses:
 *  - Escape: hides the find box if it is open.
 */
static int w_keypress(GtkWidget*_, GdkEventKey *event, void*__) {
  if (event->keyval == 0xff1b && gtk_widget_get_visible(findbox) &&
      !gtk_widget_has_focus(command_entry)) {
    gtk_widget_hide(findbox);
    gtk_widget_grab_focus(focused_view);
    return TRUE;
  } else return FALSE;
}
#endif

/**
 * Removes the Scintilla view from the 'views' registry table.
 * The view must have been previously added with lL_addview.
 * @param L The Lua state.
 * @param view The Scintilla view to remove.
 * @see lL_addview
 */
static void lL_removeview(lua_State *L, Scintilla *view) {
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_isnumber(L, -2) && view != l_toview(L, -1)) {
      lua_getfield(L, -1, "widget_pointer");
      // vs[userdata] = v, vs[#vs + 1] = v, vs[v] = #vs
      lua_pushvalue(L, -2), lua_rawseti(L, -6, lua_rawlen(L, -6) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -6);
      lua_pushinteger(L, lua_rawlen(L, -4)), lua_settable(L, -5);
    } else lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // views
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_setglobal(L, "_VIEWS");
}

/**
 * Removes a Scintilla view.
 * @param view The Scintilla view to remove.
 * @see lL_removeview
 */
static void delete_view(Scintilla *view) {
  lL_removeview(lua, view);
  scintilla_delete(view);
}

#if GTK
/**
 * Remove all Scintilla views from the given pane and delete them.
 * @param pane The GTK pane to remove Scintilla views from.
 * @see delete_view
 */
static void remove_views_from_pane(GtkWidget *pane) {
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane));
  GtkWidget *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_views_from_pane(child1) : delete_view(child1);
  GTK_IS_PANED(child2) ? remove_views_from_pane(child2) : delete_view(child2);
}
#endif

/**
 * Unsplits the pane a given Scintilla view is in and keeps the view.
 * All views in the other pane are deleted.
 * @param view The Scintilla view to keep when unsplitting.
 * @see remove_views_from_pane
 * @see delete_view
 */
static int unsplit_view(Scintilla *view) {
#if GTK
  GtkWidget *pane = gtk_widget_get_parent(view);
  if (!GTK_IS_PANED(pane)) return FALSE;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane));
  if (other == view) other = gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(view), g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), view);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_views_from_pane(other) : delete_view(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent)) {
    if (!gtk_paned_get_child1(GTK_PANED(parent)))
      gtk_paned_add1(GTK_PANED(parent), view);
    else
      gtk_paned_add2(GTK_PANED(parent), view);
  } else gtk_container_add(GTK_CONTAINER(parent), view);
  gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(view));
  g_object_unref(view), g_object_unref(other);
  return TRUE;
#elif NCURSES
  return FALSE;
#endif
}

/**
 * Closes the Lua state.
 * Unsplits and destroys all Scintilla views and removes all Scintilla
 * documents, before closing the state.
 * @param L The Lua state.
 */
static void l_close(lua_State *L) {
  closing = TRUE;
  while (unsplit_view(focused_view)) ; // need space to fix compiler warning
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_isnumber(L, -2)) delete_buffer(l_todoc(L, -1));
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // buffers
  scintilla_delete(focused_view);
  lua_close(L);
}

#if GTK
/**
 * Signal for exiting Textadept.
 * Generates a 'quit' event.
 * Closes the Lua state and releases resources.
 * @see l_close
 */
static int w_exit(GtkWidget*_, GdkEventAny*__, void*___) {
  if (!lL_event(lua, "quit", -1)) return TRUE;
  l_close(lua);
  scintilla_release_resources();
  gtk_main_quit();
  return FALSE;
}

#if __OSX__
/**
 * Signal for opening files from OSX.
 * Generates an 'appleevent_odoc' event for each document sent.
 */
static int w_open_osx(GtkOSXApplication*_, char *path, void*__) {
  lL_event(lua, "appleevent_odoc", LUA_TSTRING, path, -1);
  return TRUE;
}

/**
 * Signal for block terminating Textadept from OSX.
 * Generates a 'quit' event.
 */
static int w_exit_osx(GtkOSXApplication*_, void*__) {
  return !lL_event(lua, "quit", -1);
}

/**
 * Signal for terminating Textadept from OSX.
 * Closes the Lua state and releases resources.
 * @see l_close
 */
static void w_quit_osx(GtkOSXApplication*_, void*__) {
  l_close(lua);
  scintilla_release_resources();
  g_object_unref(osxapp);
  gtk_main_quit();
}
#endif
#endif // if GTK

/**
 * Emits a Scintilla notification event.
 * @param L The Lua state.
 * @param n The Scintilla notification struct.
 * @see lL_event
 */
static void lL_notify(lua_State *L, struct SCNotification *n) {
  lua_newtable(L);
  lua_pushinteger(L, n->nmhdr.code), lua_setfield(L, -2, "code");
  lua_pushinteger(L, n->position), lua_setfield(L, -2, "position");
  lua_pushinteger(L, n->ch), lua_setfield(L, -2, "ch");
  lua_pushinteger(L, n->modifiers), lua_setfield(L, -2, "modifiers");
  //lua_pushinteger(L, n->modificationType);
  //lua_setfield(L, -2, "modification_type");
  lua_pushstring(L, n->text), lua_setfield(L, -2, "text");
  //lua_pushinteger(L, n->length), lua_setfield(L, -2, "length");
  //lua_pushinteger(L, n->linesAdded), lua_setfield(L, -2, "lines_added");
  //lua_pushinteger(L, n->message), lua_setfield(L, -2, "message");
  lua_pushinteger(L, n->wParam), lua_setfield(L, -2, "wParam");
  lua_pushinteger(L, n->lParam), lua_setfield(L, -2, "lParam");
  lua_pushinteger(L, n->line), lua_setfield(L, -2, "line");
  //lua_pushinteger(L, n->foldLevelNow), lua_setfield(L, -2, "fold_level_now");
  //lua_pushinteger(L, n->foldLevelPrev);
  //lua_setfield(L, -2, "fold_level_prev");
  lua_pushinteger(L, n->margin), lua_setfield(L, -2, "margin");
  lua_pushinteger(L, n->x), lua_setfield(L, -2, "x");
  lua_pushinteger(L, n->y), lua_setfield(L, -2, "y");
  lL_event(L, "SCN", LUA_TTABLE, luaL_ref(L, LUA_REGISTRYINDEX), -1);
}

/**
 * Signal for a Scintilla notification.
 */
static void s_notify(Scintilla *view, int _, void *lParam, void*__) {
  struct SCNotification *n = (struct SCNotification *)lParam;
  if (focused_view == view || n->nmhdr.code == SCN_URIDROPPED) {
    if (focused_view != view) goto_view(view);
    lL_notify(lua, n);
  } else if (n->nmhdr.code == SCN_SAVEPOINTLEFT) {
    Scintilla *prev = focused_view;
    goto_view(view);
    lL_notify(lua, n);
    goto_view(prev); // do not let a split view steal focus
  }
}

#if GTK
/**
 * Signal for a Scintilla command.
 * Currently handles SCEN_SETFOCUS.
 */
static void s_command(GtkWidget *view, int wParam, void*_, void*__) {
  if (wParam >> 16 == SCEN_SETFOCUS) goto_view(view);
}

/**
 * Signal for a Scintilla keypress.
 */
static int s_keypress(GtkWidget *view, GdkEventKey *event, void*_) {
  return lL_event(lua, "keypress", LUA_TNUMBER, event->keyval, LUA_TBOOLEAN,
                  event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN,
                  event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD1_MASK, LUA_TBOOLEAN,
                  event->state & GDK_META_MASK, -1);
}

/**
 * Shows the context menu for a Scintilla view based on a mouse event.
 * @param L The Lua state.
 * @param event An optional GTK mouse button event.
 */
static void lL_showcontextmenu(lua_State *L, void *event) {
  lua_getglobal(L, "gui");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "context_menu");
    if (lua_isuserdata(L, -1)) {
#if GTK
      GtkWidget *menu = (GtkWidget *)lua_touserdata(L, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? ((GdkEventButton *)event)->button : 0,
                     gdk_event_get_time((GdkEvent *)event));
#elif NCURSES
      // TODO: popup context menu.
#endif
    } else if (!lua_isnil(L, -1))
      warn("gui.context_menu: menu expected");
    lua_pop(L, 1); // gui.context_menu
  } else lua_pop(L, 1); // non-table
}

/**
 * Signal for a Scintilla mouse click.
 */
static int s_buttonpress(GtkWidget*_, GdkEventButton *event, void*__) {
  if (event->type == GDK_BUTTON_PRESS && event->button == 3)
    return (lL_showcontextmenu(lua, (void *)event), TRUE);
  return FALSE;
}
#endif

/**
 * Checks whether the function argument narg is a Scintilla view and returns
 * this view cast to a Scintilla.
 * @param L The Lua state.
 * @param narg The stack index of the Scintilla view.
 * @return Scintilla view
 */
static Scintilla *lL_checkview(lua_State *L, int narg) {
  luaL_getmetatable(L, "ta_view");
  lua_getmetatable(L, narg);
  luaL_argcheck(L, lua_compare(L, -1, -2, LUA_OPEQ), narg, "View expected");
  lua_getfield(L, (narg > 0) ? narg : narg - 2, "widget_pointer");
  Scintilla *view = (Scintilla *)lua_touserdata(L, -1);
  lua_pop(L, 3); // widget_pointer, metatable, metatable
  return view;
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
static int lview_goto_buffer(lua_State *L) {
  Scintilla *view = lL_checkview(L, 1), *prev_view = focused_view;
  int n = luaL_checkinteger(L, 2), relative = lua_toboolean(L, 3);
  int switch_focus = (view != focused_view);
  if (switch_focus) SS(view, SCI_SETFOCUS, TRUE, 0);
  lL_event(L, "buffer_before_switch", -1);
  lL_gotodoc(L, view, n, relative);
  lL_event(L, "buffer_after_switch", -1);
  if (switch_focus) SS(view, SCI_SETFOCUS, FALSE, 0), focus_view(prev_view);
  return 0;
}

/**
 * Splits the given Scintilla view into two views.
 * The new view shows the same document as the original one.
 * @param view The Scintilla view to split.
 * @param vertical Flag indicating whether to split the view vertically or
 *   horozontally.
 */
static void split_view(Scintilla *view, int vertical) {
  sptr_t curdoc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  int first_line = SS(view, SCI_GETFIRSTVISIBLELINE, 0, 0);
  int current_pos = SS(view, SCI_GETCURRENTPOS, 0, 0);
  int anchor = SS(view, SCI_GETANCHOR, 0, 0);

#if GTK
  GtkAllocation allocation;
  gtk_widget_get_allocation(view, &allocation);
  int middle = (vertical ? allocation.width : allocation.height) / 2;

  g_object_ref(view);
  GtkWidget *view2 = new_view(curdoc);
  GtkWidget *parent = gtk_widget_get_parent(view);
  gtk_container_remove(GTK_CONTAINER(parent), view);
  GtkWidget *pane = vertical ? gtk_hpaned_new() : gtk_vpaned_new();
  gtk_paned_add1(GTK_PANED(pane), view), gtk_paned_add2(GTK_PANED(pane), view2);
  gtk_container_add(GTK_CONTAINER(parent), pane);
  gtk_paned_set_position(GTK_PANED(pane), middle);
  gtk_widget_show_all(pane);
  g_object_unref(view);
#elif NCURSES
  WINDOW *win = scintilla_get_window(view);
  int x, y;
  getbegyx(win, y, x);
  int width = getmaxx(win) - x, height = getmaxy(win) - y;
  wresize(win, vertical ? height : height / 2, vertical ? width / 2 : width);
  Scintilla *view2 = new_view(curdoc);
  wresize(scintilla_get_window(view2), vertical ? height : height / 2,
                                       vertical ? width / 2 : width);
  mvwin(scintilla_get_window(view2), vertical ? y : y + height / 2,
                                     vertical ? x + width / 2 : x);
  // TODO: draw split
#endif
  focus_view(view2);

  SS(view2, SCI_SETSEL, anchor, current_pos);
  int new_first_line = SS(view2, SCI_GETFIRSTVISIBLELINE, 0, 0);
  SS(view2, SCI_LINESCROLL, first_line - new_first_line, 0);
}

static int lview_split(lua_State *L) {
  split_view(lL_checkview(L, 1), lua_toboolean(L, 2));
  lua_pushvalue(L, 1); // old view
  lua_getglobal(L, "view"); // new view
  return 2;
}

static int lview_unsplit(lua_State *L) {
  lua_pushboolean(L, unsplit_view(lL_checkview(L, 1)));
  return 1;
}

static int lview__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "buffer") == 0)
    l_pushdoc(L, SS(lL_checkview(L, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (strcmp(key, "size") == 0) {
    Scintilla *view = lL_checkview(L, 1);
#if GTK
    if (GTK_IS_PANED(gtk_widget_get_parent(view))) {
      int pos = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(view)));
      lua_pushinteger(L, pos);
    } else lua_pushnil(L);
#elif NCURSES
    lua_pushnil(L);
#endif
  } else lua_rawget(L, 1);
  return 1;
}

static int lview__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "buffer") == 0)
    luaL_argerror(L, 3, "read-only property");
  else if (strcmp(key, "size") == 0) {
#if GTK
    GtkWidget *pane = gtk_widget_get_parent(lL_checkview(L, 1));
    int size = luaL_checkinteger(L, 3);
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
#elif NCURSES
    // TODO: set size.
#endif
  } else lua_rawset(L, 1);
  return 0;
}

/**
 * Adds the Scintilla view with a metatable to the 'views' registry table.
 * @param L The Lua state.
 * @param view The Scintilla view to add.
 */
static void lL_addview(lua_State *L, Scintilla *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_newtable(L);
  lua_pushlightuserdata(L, view);
  lua_pushvalue(L, -1), lua_setfield(L, -3, "widget_pointer");
  l_setcfunction(L, -2, "goto_buffer", lview_goto_buffer);
  l_setcfunction(L, -2, "split", lview_split);
  l_setcfunction(L, -2, "unsplit", lview_unsplit);
  l_setmetatable(L, -2, "ta_view", lview__index, lview__newindex);
  // vs[userdata] = v, vs[#vs + 1] = v, vs[v] = #vs
  lua_pushvalue(L, -2), lua_settable(L, -4);
  lua_pushvalue(L, -1), lua_rawseti(L, -3, lua_rawlen(L, -3) + 1);
  lua_pushinteger(L, lua_rawlen(L, -2)), lua_settable(L, -3);
  lua_pop(L, 1); // views
}

/**
 * Creates a new Scintilla view.
 * Generates a 'view_new' event.
 * @param doc The document to load in the new view. Almost never zero, except
 *   for the first Scintilla view created, in which there is no doc pointer.
 * @return Scintilla view
 * @see lL_addview
 */
static Scintilla *new_view(sptr_t doc) {
#if GTK
  Scintilla *view = scintilla_new();
  gtk_widget_set_size_request(view, 1, 1); // minimum size
  signal(view, SCINTILLA_NOTIFY, s_notify);
  signal(view, "command", s_command);
  signal(view, "key-press-event", s_keypress);
  signal(view, "button-press-event", s_buttonpress);
#elif NCURSES
  Scintilla *view = scintilla_new(s_notify);
#endif
  SS(view, SCI_USEPOPUP, 0, 0);
  lL_addview(lua, view);
  focused_view = view;
  focus_view(view);
  if (doc) {
    SS(view, SCI_SETDOCPOINTER, 0, doc);
    l_setglobaldoc(lua, doc);
  } else new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
  l_setglobalview(lua, view);
  lL_event(lua, "view_new", -1);
  return view;
}

/**
 * Creates the Find box.
 */
static FindBox *new_findbox() {
#if GTK
#define attach(w, x1, x2, y1, y2, xo, yo, xp, yp) \
  gtk_table_attach(GTK_TABLE(findbox), w, x1, x2, y1, y2, xo, yo, xp, yp)
#define EXPAND_FILL (GtkAttachOptions)(GTK_EXPAND | GTK_FILL)
#define SHRINK_FILL (GtkAttachOptions)(GTK_SHRINK | GTK_FILL)

  findbox = gtk_table_new(2, 6, FALSE);
  find_store = gtk_list_store_new(1, G_TYPE_STRING);
  repl_store = gtk_list_store_new(1, G_TYPE_STRING);

  flabel = gtk_label_new_with_mnemonic("_Find:");
  rlabel = gtk_label_new_with_mnemonic("R_eplace:");
  GtkWidget *find_combo = gtk_combo_box_entry_new_with_model(
                          GTK_TREE_MODEL(find_store), 0);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(find_combo), 0);
  g_object_unref(find_store);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(find_combo), FALSE);
  find_entry = gtk_bin_get_child(GTK_BIN(find_combo));
  gtk_entry_set_activates_default(GTK_ENTRY(find_entry), TRUE);
  GtkWidget *replace_combo = gtk_combo_box_entry_new_with_model(
                             GTK_TREE_MODEL(repl_store), 0);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(replace_combo), 0);
  g_object_unref(repl_store);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(replace_combo), FALSE);
  replace_entry = gtk_bin_get_child(GTK_BIN(replace_combo));
  gtk_entry_set_activates_default(GTK_ENTRY(replace_entry), TRUE);
  fnext_button = gtk_button_new_with_mnemonic("Find _Next");
  fprev_button = gtk_button_new_with_mnemonic("Find _Prev");
  r_button = gtk_button_new_with_mnemonic("_Replace");
  ra_button = gtk_button_new_with_mnemonic("Replace _All");
  match_case = gtk_check_button_new_with_mnemonic("_Match case");
  whole_word = gtk_check_button_new_with_mnemonic("_Whole word");
  lua_pattern = gtk_check_button_new_with_mnemonic("_Lua pattern");
  in_files = gtk_check_button_new_with_mnemonic("_In files");

  gtk_label_set_mnemonic_widget(GTK_LABEL(flabel), find_entry);
  gtk_label_set_mnemonic_widget(GTK_LABEL(rlabel), replace_entry);

  attach(find_combo, 1, 2, 0, 1, EXPAND_FILL, SHRINK_FILL, 5, 0);
  attach(replace_combo, 1, 2, 1, 2, EXPAND_FILL, SHRINK_FILL, 5, 0);
  attach(flabel, 0, 1, 0, 1, SHRINK_FILL, SHRINK_FILL, 5, 0);
  attach(rlabel, 0, 1, 1, 2, SHRINK_FILL, SHRINK_FILL, 5, 0);
  attach(fnext_button, 2, 3, 0, 1, SHRINK_FILL, SHRINK_FILL, 0, 0);
  attach(fprev_button, 3, 4, 0, 1, SHRINK_FILL, SHRINK_FILL, 0, 0);
  attach(r_button, 2, 3, 1, 2, SHRINK_FILL, SHRINK_FILL, 0, 0);
  attach(ra_button, 3, 4, 1, 2, SHRINK_FILL, SHRINK_FILL, 0, 0);
  attach(match_case, 4, 5, 0, 1, SHRINK_FILL, SHRINK_FILL, 5, 0);
  attach(whole_word, 4, 5, 1, 2, SHRINK_FILL, SHRINK_FILL, 5, 0);
  attach(lua_pattern, 5, 6, 0, 1, SHRINK_FILL, SHRINK_FILL, 5, 0);
  attach(in_files, 5, 6, 1, 2, SHRINK_FILL, SHRINK_FILL, 5, 0);

  signal(fnext_button, "clicked", f_clicked);
  signal(fprev_button, "clicked", f_clicked);
  signal(r_button, "clicked", f_clicked);
  signal(ra_button, "clicked", f_clicked);

  gtk_widget_set_can_default(fnext_button, TRUE);
  gtk_widget_set_can_focus(fnext_button, FALSE);
  gtk_widget_set_can_focus(fprev_button, FALSE);
  gtk_widget_set_can_focus(r_button, FALSE);
  gtk_widget_set_can_focus(ra_button, FALSE);
  gtk_widget_set_can_focus(match_case, FALSE);
  gtk_widget_set_can_focus(whole_word, FALSE);
  gtk_widget_set_can_focus(lua_pattern, FALSE);
  gtk_widget_set_can_focus(in_files, FALSE);
#endif

  return findbox;
}

#if GTK
/**
 * Signal for the 'enter' key being pressed in the Command Entry.
 */
static void c_activate(GtkWidget *entry, void*_) {
  lL_event(lua, "command_entry_command", LUA_TSTRING,
           gtk_entry_get_text(GTK_ENTRY(entry)), -1);
}

/**
 * Signal for a keypress inside the Command Entry.
 */
static int c_keypress(GtkWidget*_, GdkEventKey *event, void*__) {
  return lL_event(lua, "command_entry_keypress", LUA_TNUMBER, event->keyval,
                  LUA_TBOOLEAN, event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN,
                  event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD1_MASK, LUA_TBOOLEAN,
                  event->state & GDK_META_MASK, -1);
}

/**
 * Replaces the current word (consisting of alphanumeric and underscore
 * characters) with the match text.
 */
static int cc_matchselected(GtkEntryCompletion*_, GtkTreeModel *model,
                                 GtkTreeIter *iter, void*__) {
  const char *text = gtk_entry_get_text(GTK_ENTRY(command_entry)), *p;
  for (p = text + strlen(text) - 1; g_ascii_isalnum(*p) || *p == '_'; p--)
    g_signal_emit_by_name(G_OBJECT(command_entry), "move-cursor",
                          GTK_MOVEMENT_VISUAL_POSITIONS, -1, TRUE, 0);
  if (p < text + strlen(text) - 1)
    g_signal_emit_by_name(G_OBJECT(command_entry), "backspace", 0);

  char *match;
  gtk_tree_model_get(model, iter, 0, &match, -1);
  g_signal_emit_by_name(G_OBJECT(command_entry), "insert-at-cursor", match, 0);
  g_free(match);

  gtk_list_store_clear(cc_store);
  return TRUE;
}

/**
 * The match function for the command entry.
 * Since the completion list is filled by Lua, every item is a "match".
 */
static int cc_matchfunc(GtkEntryCompletion*_, const char *__, GtkTreeIter*___,
                        void*____) { return 1; }

#endif // if GTK

/**
 * Creates the Textadept window.
 * The window contains a menubar, frame for Scintilla views, hidden find box,
 * hidden command entry, and two status bars: one for notifications and the
 * other for buffer status.
 */
static void new_window() {
#if GTK
  GList *icon_list = NULL;
  const char *icons[] = { "16x16", "32x32", "48x48", "64x64", "128x128" };
  for (int i = 0; i < 5; i++) {
    char *icon_file = g_strconcat(textadept_home, "/core/images/ta_", icons[i],
                                  ".png", NULL);
    GdkPixbuf *pb = gdk_pixbuf_new_from_file(icon_file, NULL);
    if (pb) icon_list = g_list_prepend(icon_list, pb);
    g_free(icon_file);
  }
  gtk_window_set_default_icon_list(icon_list);
  g_list_foreach(icon_list, (GFunc)g_object_unref, NULL);
  g_list_free(icon_list);

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_name(window, "textadept");
  gtk_window_set_default_size(GTK_WINDOW(window), 500, 400);
  signal(window, "delete-event", w_exit);
  signal(window, "focus-in-event", w_focus);
  signal(window, "key-press-event", w_keypress);
  accel = gtk_accel_group_new();

#if __OSX__
  gtk_osxapplication_set_use_quartz_accelerators(osxapp, FALSE);
  osx_signal(osxapp, "NSApplicationOpenFile", w_open_osx);
  osx_signal(osxapp, "NSApplicationBlockTermination", w_exit_osx);
  osx_signal(osxapp, "NSApplicationWillTerminate", w_quit_osx);
#endif

  GtkWidget *vbox = gtk_vbox_new(FALSE, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);

  GtkWidget *hbox = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hbox, TRUE, TRUE, 0);

  GtkWidget *view = new_view(0);
  gtk_box_pack_start(GTK_BOX(hbox), view, TRUE, TRUE, 0);

  GtkWidget *find = new_findbox();
  gtk_box_pack_start(GTK_BOX(vbox), find, FALSE, FALSE, 5);

  command_entry = gtk_entry_new();
  signal(command_entry, "activate", c_activate);
  signal(command_entry, "key-press-event", c_keypress);
  gtk_box_pack_start(GTK_BOX(vbox), command_entry, FALSE, FALSE, 0);

  command_entry_completion = gtk_entry_completion_new();
  signal(command_entry_completion, "match-selected", cc_matchselected);
  gtk_entry_completion_set_match_func(command_entry_completion, cc_matchfunc,
                                      NULL, NULL);
  gtk_entry_completion_set_popup_set_width(command_entry_completion, FALSE);
  gtk_entry_completion_set_text_column(command_entry_completion, 0);
  cc_store = gtk_list_store_new(1, G_TYPE_STRING);
  gtk_entry_completion_set_model(command_entry_completion,
                                 GTK_TREE_MODEL(cc_store));
  gtk_entry_set_completion(GTK_ENTRY(command_entry), command_entry_completion);

  GtkWidget *hboxs = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, FALSE, FALSE, 0);

  statusbar[0] = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[0]), 0, "");
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar[0]), FALSE);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[0], TRUE, TRUE, 0);

  statusbar[1] = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[1]), 0, "");
  g_object_set(G_OBJECT(statusbar[1]), "width-request", 400, NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], FALSE, FALSE, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar); // hide initially
  gtk_widget_hide(findbox); // hide initially
  gtk_widget_hide(command_entry); // hide initially
#elif NCURSES
  Scintilla *view = new_view(0);
  wresize(scintilla_get_window(view), LINES - 2, COLS);
  mvwin(scintilla_get_window(view), 1, 0);
#endif
}

/**
 * Runs Textadept.
 * Initializes the Lua state, creates the user interface, and then runs
 * `core/init.lua` followed by `init.lua`.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
#if GTK
  gtk_init(&argc, &argv);
#elif NCURSES
  TermKey *tk = termkey_new(0, TERMKEY_FLAG_NOTERMIOS);
  initscr(); // raw()/cbreak() and noecho() are taken care of in libtermkey
#endif

#if !(__WIN32__ || __OSX__ || __BSD__)
  textadept_home = malloc(FILENAME_MAX);
  readlink("/proc/self/exe", textadept_home, FILENAME_MAX);
#elif __WIN32__
  textadept_home = malloc(FILENAME_MAX);
  GetModuleFileName(0, textadept_home, FILENAME_MAX);
#elif __OSX__
  osxapp = g_object_new(GTK_TYPE_OSX_APPLICATION, NULL);
  char *path = quartz_application_get_resource_path();
  textadept_home = g_filename_from_utf8((const char *)path, -1, NULL, NULL,
                                        NULL);
  g_free(path);
#elif __BSD__
  textadept_home = malloc(FILENAME_MAX);
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
  size_t cb = FILENAME_MAX;
  sysctl(mib, 4, textadept_home, &cb, NULL, 0);
#endif
#if !(__WIN32__ || __OSX__)
  char *last_slash = strrchr(textadept_home, '/');
#elif !__OSX__
  char *last_slash = strrchr(textadept_home, '\\');
#endif
  if (last_slash) *last_slash = '\0';

#if GTK
#if GLIB_CHECK_VERSION(2,28,0) && SINGLE_INSTANCE
  int force = FALSE;
  for (int i = 0; i < argc; i++)
    if (strcmp("-f", argv[i]) == 0 || strcmp("--force", argv[i]) == 0) {
      force = TRUE;
      break;
    }
  GApplication *app = g_application_new("textadept.editor",
                                        G_APPLICATION_HANDLES_COMMAND_LINE);
  g_signal_connect(app, "command-line", G_CALLBACK(a_command_line), 0);
  int registered = g_application_register(app, NULL, NULL);
  if (!registered || !g_application_get_is_remote(app) || force) {
#endif
#endif

  setlocale(LC_NUMERIC, "C");
  if (lua = luaL_newstate(), !lL_init(lua, argc, argv, FALSE)) return 1;
  new_window();
  lL_dofile(lua, "init.lua");
#if __OSX__
  gtk_osxapplication_ready(osxapp);
#endif

#if GTK
#if GLIB_CHECK_VERSION(2,28,0) && SINGLE_INSTANCE
    gtk_main();
  } else g_application_run(app, argc, argv);
  g_object_unref(app);
#else
  gtk_main();
#endif
#elif NCURSES
  TermKeyResult res;
  TermKeyKey key;
  int c = 0;
  while ((res = termkey_waitkey(tk, &key)) != TERMKEY_RES_EOF) {
    if (res == TERMKEY_RES_ERROR) continue;
    switch (key.type) {
      case TERMKEY_TYPE_UNICODE: c = key.code.codepoint; break;
      case TERMKEY_TYPE_KEYSYM:
        switch (key.code.sym) {
          case TERMKEY_SYM_BACKSPACE: c = SCK_BACK; break;
          case TERMKEY_SYM_TAB: c = SCK_TAB; break;
          case TERMKEY_SYM_ENTER: c = SCK_RETURN; break;
          case TERMKEY_SYM_ESCAPE: c = SCK_ESCAPE; break;
          case TERMKEY_SYM_UP: c = SCK_UP; break;
          case TERMKEY_SYM_DOWN: c = SCK_DOWN; break;
          case TERMKEY_SYM_LEFT: c = SCK_LEFT; break;
          case TERMKEY_SYM_RIGHT: c = SCK_RIGHT; break;
          case TERMKEY_SYM_INSERT: c = SCK_INSERT; break;
          case TERMKEY_SYM_DELETE: c = SCK_DELETE; break;
          case TERMKEY_SYM_PAGEUP: c = SCK_PRIOR; break;
          case TERMKEY_SYM_PAGEDOWN: c = SCK_NEXT; break;
          case TERMKEY_SYM_HOME: c = SCK_HOME; break;
          case TERMKEY_SYM_END: c = SCK_END; break;
          default: break;
        }
        break;
      default: continue;
    }
//    if (c == SCK_ESCAPE && gtk_widget_get_visible(findbox) &&
//        !gtk_widget_has_focus(command_entry)) {
//      gtk_widget_hide(findbox);
//      gtk_widget_grab_focus(focused_view);
//    } else
    curs_set(0); // disable cursor when Scintilla has focus
    if (!lL_event(lua, "keypress", LUA_TNUMBER, c, LUA_TBOOLEAN,
                  key.modifiers & TERMKEY_KEYMOD_SHIFT, LUA_TBOOLEAN,
                  key.modifiers & TERMKEY_KEYMOD_CTRL, LUA_TBOOLEAN,
                  key.modifiers & TERMKEY_KEYMOD_ALT, LUA_TBOOLEAN, FALSE, -1))
      scintilla_send_key(focused_view, c, key.modifiers & TERMKEY_KEYMOD_SHIFT,
                         key.modifiers & TERMKEY_KEYMOD_CTRL,
                         key.modifiers & TERMKEY_KEYMOD_ALT);
    if (quit && lL_event(lua, "quit", -1)) {
      l_close(lua);
      break;
    } else quit = FALSE;
//    redrawwin(stdscr);
    wrefresh(scintilla_get_window(focused_view));
    redrawwin(scintilla_get_window(focused_view));
  }
  endwin();
  termkey_destroy(tk);
#endif

  free(textadept_home);
  return 0;
}

#if __WIN32__
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE _, HINSTANCE __, LPSTR lpCmdLine, int ___) {
  return main(1, &lpCmdLine);
}
#endif

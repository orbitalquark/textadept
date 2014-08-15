// Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

// Library includes.
#include <errno.h>
#include <locale.h>
#include <iconv.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if __linux__
#include <unistd.h>
#elif _WIN32
#include <windows.h>
#define main main_
#elif __APPLE__
#include <mach-o/dyld.h>
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
#define u_int unsigned int // 'u_int' undefined when _POSIX_SOURCE is defined
#include <sys/types.h>
#include <sys/sysctl.h>
#endif
#if GTK
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#if __APPLE__
#include <gtkmacintegration/gtkosxapplication.h>
#endif
#elif CURSES
#if !_WIN32
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <termios.h>
#else
#undef main
#endif
#include <curses.h>
#endif

// External dependency includes.
#include "gtdialog.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "Scintilla.h"
#if GTK
#include "ScintillaWidget.h"
#elif CURSES
#include "ScintillaTerm.h"
#include "windowman.h"
#include "cdk_int.h"
#if !_WIN32
#include "termkey.h"
#endif
#endif

// GTK definitions and macros.
#if GTK
typedef GtkWidget Scintilla;
// Translate GTK 2.x API to GTK 3.0 for compatibility.
#if GTK_CHECK_VERSION(3,0,0)
#define GDK_Return GDK_KEY_Return
#define GDK_Escape GDK_KEY_Escape
#define gtk_container_add(c, w) \
  (GTK_IS_BOX(c) ? gtk_box_pack_start(GTK_BOX(c), w, TRUE, TRUE, 0) \
                 : gtk_container_add(c, w))
#define gtk_hpaned_new() gtk_paned_new(GTK_ORIENTATION_HORIZONTAL)
#define gtk_vpaned_new() gtk_paned_new(GTK_ORIENTATION_VERTICAL)
#define gtk_combo_box_entry_new_with_model(m,_) \
  gtk_combo_box_new_with_model_and_entry(m)
#define gtk_combo_box_entry_set_text_column gtk_combo_box_set_entry_text_column
#define GTK_COMBO_BOX_ENTRY GTK_COMBO_BOX
#define gtk_vbox_new(_,s) gtk_box_new(GTK_ORIENTATION_VERTICAL, s)
#define gtk_hbox_new(_,s) gtk_box_new(GTK_ORIENTATION_HORIZONTAL, s)
#define gtk_statusbar_set_has_resize_grip(...)
#endif
#endif

// Lua definitions and macros.
#define l_setglobalview(l, view) (l_pushview(l, view), lua_setglobal(l, "view"))
#define l_setglobaldoc(l, doc) (l_pushdoc(l, doc), lua_setglobal(l, "buffer"))
#define l_setcfunction(l, n, name, f) \
  (lua_pushcfunction(l, f), lua_setfield(l, (n > 0) ? n : n - 1, name))
#define l_setmetatable(l, n, name, __index, __newindex) { \
  if (luaL_newmetatable(l, name)) { \
    l_setcfunction(l, -1, "__index", __index); \
    l_setcfunction(l, -1, "__newindex", __newindex); \
  } \
  lua_setmetatable(l, (n > 0) ? n : n - 1); \
}
// Translate Lua 5.2 API to LuaJIT API (Lua 5.1) for compatibility.
#if LUA_VERSION_NUM == 501
#define LUA_OK 0
#define lua_rawlen lua_objlen
#define LUA_OPEQ 0
#define lL_openlib(l, n, f) \
  (lua_pushcfunction(l, f), lua_pushstring(l, n), lua_call(l, 1, 0))
#else
#define lL_openlib(l, n, f) (luaL_requiref(l, n, f, 1), lua_pop(l, 1))
#endif

static char *textadept_home;

// User interface objects and related macros.
static Scintilla *focused_view, *dummy_view;
#if GTK
// GTK window.
static GtkWidget *window, *menubar, *tabbar, *statusbar[2];
static GtkAccelGroup *accel;
#if __APPLE__
static GtkosxApplication *osxapp;
#endif
#define SS(view, msg, w, l) scintilla_send_message(SCINTILLA(view), msg, w, l)
#define signal(w, sig, cb) g_signal_connect(G_OBJECT(w), sig, G_CALLBACK(cb), 0)
#define osx_signal(app, sig, cb) g_signal_connect(app, sig, G_CALLBACK(cb), 0)
#define focus_view(view) gtk_widget_grab_focus(view)
#define scintilla_delete(view) gtk_widget_destroy(view)
#define child(n, pane) gtk_paned_get_child##n(GTK_PANED(pane))
#define event_mod(modifier) LUA_TBOOLEAN, event->state & GDK_##modifier##_MASK
// GTK find & replace pane.
static GtkWidget *findbox, *find_entry, *replace_entry, *flabel, *rlabel;
#define find_text gtk_entry_get_text(GTK_ENTRY(find_entry))
#define repl_text gtk_entry_get_text(GTK_ENTRY(replace_entry))
typedef GtkWidget * FindButton;
static FindButton fnext_button, fprev_button, r_button, ra_button;
static GtkWidget *match_case, *whole_word, *lua_pattern, *in_files;
typedef GtkListStore ListStore;
static ListStore *find_store, *repl_store;
#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
#define toggle(w, on) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), on)
#define set_label_text(l, t) gtk_label_set_text_with_mnemonic(GTK_LABEL(l), t)
#define set_button_label(b, l) gtk_button_set_label(GTK_BUTTON(b), l)
#define set_option_label(o, _, l) gtk_button_set_label(GTK_BUTTON(o), l)
#if !GTK_CHECK_VERSION(3,4,0)
#define attach(...) gtk_table_attach(GTK_TABLE(findbox), __VA_ARGS__)
#define FILL(option) (GtkAttachOptions)(GTK_FILL | GTK_##option)
#else
// GTK 3.4 deprecated tables; translate from 2.x for compatibility.
#define gtk_table_new(...) \
  gtk_grid_new(), gtk_grid_set_column_spacing(GTK_GRID(findbox), 5)
#define attach(w, x1, _, y1, __, ...) \
  gtk_grid_attach(GTK_GRID(findbox), w, x1, y1, 1, 1)
#endif
// GTK command entry.
static GtkWidget *command_entry;
#define command_text gtk_entry_get_text(GTK_ENTRY(command_entry))
static GtkListStore *cc_store;
static GtkEntryCompletion *command_entry_completion;
#elif CURSES
// curses window.
static struct WindowManager *wm;
#if !_WIN32
TermKey *ta_tk; // global for CDK use
#endif
#define SS(view, msg, w, l) scintilla_send_message(view, msg, w, l)
#define focus_view(view) \
  (focused_view ? SS(focused_view, SCI_SETFOCUS, 0, 0) : 0, \
   SS(view, SCI_SETFOCUS, 1, 0))
/** Callback for refreshing a single Scintilla view. */
static void r_cb(void *view, void*_) {scintilla_refresh((Scintilla *)view);}
#define refresh_all() (wman_walk(wm, r_cb, NULL), wman_refresh(wm), refresh())
#define flushch() (timeout(0), getch(), timeout(-1))
// curses find & replace pane.
static CDKSCREEN *findbox;
static CDKENTRY *find_entry, *replace_entry, *focused_entry;
static char *find_text, *repl_text, *flabel, *rlabel;
typedef int FindButton;
enum FindButton {fnext_button, r_button, fprev_button, ra_button};
static int find_options[4];
static int *match_case = &find_options[0], *whole_word = &find_options[1],
           *lua_pattern = &find_options[2], *in_files = &find_options[3];
static char *button_labels[4], *option_labels[4];
typedef char * ListStore;
static ListStore find_store[10], repl_store[10];
#define max(a, b) (((a) > (b)) ? (a) : (b))
#define bind(k, d) (bindCDKObject(vENTRY, find_entry, k, entry_keypress, d), \
                    bindCDKObject(vENTRY, replace_entry, k, entry_keypress, d))
#define toggled(find_option) *find_option
// Use pointer arithmetic to highlight/unhighlight options as necessary.
#define toggle(o, on) (*o = on, option_labels[o - match_case] += *o ? -4 : 4)
#define set_label_text(label, text) fcopy(&label, text)
#define set_button_label(button, label) fcopy(&button_labels[button], label)
// Prepend "</R>" to each option label because pointer arithmetic will be used
// to make the "</R>" visible or invisible (thus highlighting or unhighlighting
// the label) depending on whether or not the option is enabled by the user.
#define set_option_label(option, i, label) { \
  lua_pushstring(L, "</R>"), lua_pushstring(L, label), lua_concat(L, 2); \
  if (option_labels[i] && !*option) option_labels[i] -= 4; \
  fcopy(&option_labels[i], lua_tostring(L, -1)); \
  if (!*option) option_labels[i] += 4; \
}
// curses command entry.
static CDKENTRY *command_entry;
static char *command_text;
#endif
#define set_clipboard(s) SS(focused_view, SCI_COPYTEXT, strlen(s), (sptr_t)s)

// Lua objects.
static lua_State *lua;
#if CURSES
static int quit;
#endif
static int initing, closing;
static int show_tabs = TRUE, tab_sync;
enum {SVOID, SINT, SLEN, SPOS, SCOLOR, SBOOL, SKEYMOD, SSTRING, SSTRINGRET};

// Forward declarations.
static void new_buffer(sptr_t);
static Scintilla *new_view(sptr_t);
static int lL_init(lua_State *, int, char **, int);
LUALIB_API int luaopen_lpeg(lua_State *), luaopen_lfs(lua_State *);
LUALIB_API int luaopen_spawn(lua_State *);
LUALIB_API int lspawn_pushfds(lua_State *), lspawn_readfds(lua_State *);

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
      int n = 1, type;
      va_list ap;
      va_start(ap, name);
      for (type = va_arg(ap, int); type != -1; type = va_arg(ap, int), n++)
        if (type == LUA_TNIL)
          lua_pushnil(L);
        else if (type == LUA_TBOOLEAN)
          lua_pushboolean(L, va_arg(ap, sptr_t));
        else if (type == LUA_TNUMBER)
          lua_pushinteger(L, va_arg(ap, sptr_t));
        else if (type == LUA_TSTRING)
          lua_pushstring(L, va_arg(ap, char *));
        else if (type == LUA_TLIGHTUSERDATA || type == LUA_TTABLE) {
          sptr_t arg = va_arg(ap, sptr_t);
          lua_rawgeti(L, LUA_REGISTRYINDEX, arg);
          luaL_unref(L, LUA_REGISTRYINDEX, arg);
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
#if GLIB_CHECK_VERSION(2,28,0)
/** Processes a remote Textadept's command line arguments. */
static int a_command_line(GApplication*_, GApplicationCommandLine *cmdline,
                          void*__) {
  if (!lua) return 0; // only process argv for secondary/remote instances
  int argc = 0;
  char **argv = g_application_command_line_get_arguments(cmdline, &argc);
  if (argc > 1) {
    lua_getglobal(lua, "args");
    if (lua_istable(lua, -1)) {
      lua_getfield(lua, -1, "process");
      if (lua_isfunction(lua, -1)) {
        lua_newtable(lua);
        const char *cwd = g_application_command_line_get_cwd(cmdline);
        lua_pushstring(lua, cwd ? cwd : ""), lua_rawseti(lua, -2, -1);
        for (int i = 0; i < argc; i++)
          lua_pushstring(lua, argv[i]), lua_rawseti(lua, -2, i);
        if (lua_pcall(lua, 1, 0, 0) != LUA_OK) {
          lL_event(lua, "error", LUA_TSTRING, lua_tostring(lua, -1), -1);
          lua_pop(lua, 1); // error message
        }
      } else lua_pop(lua, 1); // non-function
    }
    lua_pop(lua, 1); // args
  }
  g_strfreev(argv);
  return (gtk_window_present(GTK_WINDOW(window)), 0);
}
#endif
#endif

#if CURSES
/**
 * Frees the given string's current value, if any, and copies the given value to
 * it.
 * The given string must be freed when finished.
 * @param s The address of the string to copy value to.
 * @param value The new value to copy. It may be freed immediately.
 */
static void fcopy(char **s, const char *value) {
  if (*s) free(*s);
  *s = strcpy(malloc(strlen(value) + 1), value);
}
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
    while (iter.stamp && gtk_tree_model_iter_next(GTK_TREE_MODEL(store), &iter))
      if (++count > 10) gtk_list_store_remove(store, &iter); // keep 10 items
  }
#elif CURSES
  if (text && (!store[0] || strcmp(text, store[0]) != 0)) {
    if (store[9]) free(store[9]);
    for (int i = 9; i > 0; i--) store[i] = store[i - 1];
    store[0] = NULL, fcopy(&store[0], text);
  }
#endif
}

/** Signal for a find box button click. */
static void f_clicked(FindButton button, void*_) {
  if (find_text && !*find_text) return;
  if (button == fnext_button || button == fprev_button) {
    find_add_to_history(find_text, find_store);
    lL_event(lua, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN,
             button == fnext_button, -1);
  } else {
    find_add_to_history(repl_text, repl_store);
    if (button == r_button) {
      lL_event(lua, "replace", LUA_TSTRING, repl_text, -1);
      lL_event(lua, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN, 1, -1);
    } else lL_event(lua, "replace_all", LUA_TSTRING, find_text, LUA_TSTRING,
                    repl_text, -1);
  }
}

/** `find.find_next()` Lua function. */
static int lfind_next(lua_State *L) {return (f_clicked(fnext_button, NULL), 0);}

/** `find.find_prev()` Lua function. */
static int lfind_prev(lua_State *L) {return (f_clicked(fprev_button, NULL), 0);}

#if CURSES
/**
 * Signal for a keypress in the Find/Replace Entry.
 * For tab keys, toggle through find/replace buttons.
 * For ^N and ^P keys, cycle through find/replace history.
 * For F1-F4 keys, toggle the respective search option.
 * For up and down keys, toggle entry focus.
 */
static int entry_keypress(EObjectType _, void *object, void *data, chtype key) {
  if (key == KEY_TAB || key == KEY_BTAB)
    injectCDKButtonbox((CDKBUTTONBOX *)data, key);
  else if (key == CDK_PREV || key == CDK_NEXT) {
    CDKENTRY *entry = (CDKENTRY *)object;
    ListStore *store = (entry == find_entry) ? find_store : repl_store;
    int i;
    for (i = 9; i >= 0; i--)
      if (store[i] && strcmp(store[i], getCDKEntryValue(entry)) == 0) break;
    (key == CDK_PREV) ? i++ : i--;
    if (i >= 0 && i <= 9 && store[i])
      setCDKEntryValue(entry, store[i]), drawCDKEntry(entry, FALSE);
  } else if (key >= KEY_F(1) && key <= KEY_F(4)) {
    int i = key - KEY_F(1), option = find_options[key - KEY_F(1)];
    // Use pointer arithmetic to highlight/unhighlight options as necessary.
    find_options[i] = !option, option_labels[i] += !option ? -4 : 4;
    // Redraw the optionbox.
    CDKBUTTONBOX **optionbox = (CDKBUTTONBOX **)data;
    int width = (*optionbox)->boxWidth - 1;
    destroyCDKButtonbox(*optionbox);
    *optionbox = newCDKButtonbox(findbox, RIGHT, TOP, 2, width, NULL, 2, 2,
                                 option_labels, 4, A_NORMAL, FALSE, FALSE);
    drawCDKButtonbox(*optionbox, FALSE);
  } else if (key == KEY_UP || key == KEY_DOWN) {
    CDKENTRY *entry = (CDKENTRY *)object;
    focused_entry = (entry == find_entry) ? replace_entry : find_entry;
    injectCDKEntry(entry, KEY_ENTER);
  }
  return TRUE;
}

/**
 * Returns the text on Scintilla's clipboard.
 * The return value needs to be freed.
 */
static char *get_clipboard() {
  char *text = malloc(scintilla_get_clipboard(focused_view, NULL));
  return (scintilla_get_clipboard(focused_view, text), text);
}
#endif

/** `find.focus()` Lua function. */
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
#elif CURSES
  if (findbox) return 0; // already active
  wresize(scintilla_get_window(focused_view), LINES - 4, COLS);
  findbox = initCDKScreen(newwin(2, 0, LINES - 3, 0)), eraseCDKScreen(findbox);
  int b_width = max(strlen(button_labels[0]), strlen(button_labels[1])) +
                max(strlen(button_labels[2]), strlen(button_labels[3])) + 3;
  int o_width = max(strlen(option_labels[0]), strlen(option_labels[1])) +
                max(strlen(option_labels[2]), strlen(option_labels[3])) + 3;
  int l_width = max(strlen(flabel), strlen(rlabel));
  int e_width = COLS - o_width - b_width - l_width - 1;
  find_entry = newCDKEntry(findbox, l_width - strlen(flabel), TOP, NULL, flabel,
                           A_NORMAL, '_', vMIXED, e_width, 0, 64, FALSE, FALSE);
  replace_entry = newCDKEntry(findbox, l_width - strlen(rlabel), BOTTOM, NULL,
                              rlabel, A_NORMAL, '_', vMIXED, e_width, 0, 64,
                              FALSE, FALSE);
  CDKBUTTONBOX *buttonbox, *optionbox;
  buttonbox = newCDKButtonbox(findbox, COLS - o_width - b_width, TOP, 2,
                              b_width, NULL, 2, 2, button_labels, 4, A_REVERSE,
                              FALSE, FALSE);
  optionbox = newCDKButtonbox(findbox, RIGHT, TOP, 2, o_width, NULL, 2, 2,
                              option_labels, 4, A_NORMAL, FALSE, FALSE);
  bind(KEY_TAB, buttonbox), bind(KEY_BTAB, buttonbox);
  bind(CDK_NEXT, NULL), bind(CDK_PREV, NULL);
  bind(KEY_F(1), &optionbox), bind(KEY_F(2), &optionbox);
  bind(KEY_F(3), &optionbox), bind(KEY_F(4), &optionbox);
  bind(KEY_DOWN, NULL), bind(KEY_UP, NULL);
  setCDKEntryValue(find_entry, find_text);
  setCDKEntryValue(replace_entry, repl_text);
  // Draw these widgets manually since activateCDKEntry() only draws find_entry.
  drawCDKEntry(replace_entry, FALSE);
  drawCDKButtonbox(buttonbox, FALSE), drawCDKButtonbox(optionbox, FALSE);
  char *clipboard = get_clipboard();
  GPasteBuffer = copyChar(clipboard); // set the CDK paste buffer
  curs_set(1);
  activateCDKEntry(focused_entry = find_entry, NULL);
  while (focused_entry->exitType == vNORMAL ||
         focused_entry->exitType == vNEVER_ACTIVATED) {
    fcopy(&find_text, getCDKEntryValue(find_entry));
    fcopy(&repl_text, getCDKEntryValue(replace_entry));
    if (focused_entry->exitType == vNORMAL) {
      f_clicked(getCDKButtonboxCurrentButton(buttonbox), NULL);
      refresh_all();
    }
    find_entry->exitType = replace_entry->exitType = vNEVER_ACTIVATED;
    activateCDKEntry(focused_entry, NULL);
  }
  curs_set(0);
  // Set Scintilla clipboard with new CDK paste buffer if necessary.
  if (strcmp(clipboard, GPasteBuffer)) set_clipboard(GPasteBuffer);
  free(clipboard), free(GPasteBuffer), GPasteBuffer = NULL;
  destroyCDKEntry(find_entry), destroyCDKEntry(replace_entry);
  destroyCDKButtonbox(buttonbox), destroyCDKButtonbox(optionbox);
  delwin(findbox->window), destroyCDKScreen(findbox), findbox = NULL, flushch();
  wresize(scintilla_get_window(focused_view), LINES - 2, COLS);
#endif
  return 0;
}

/** `find.replace()` Lua function. */
static int lfind_replace(lua_State *L) {return (f_clicked(r_button, NULL), 0);}

/** `find.replace_all()` Lua function. */
static int lfind_replace_all(lua_State *L) {
  return (f_clicked(ra_button, NULL), 0);
}

/** `find.__index` Lua metatable. */
static int lfind__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    lua_pushstring(L, find_text);
  else if (strcmp(key, "replace_entry_text") == 0)
    lua_pushstring(L, repl_text);
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

/** `find.__newindex` Lua metatable. */
static int lfind__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
#if GTK
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(L, 3));
#elif CURSES
    fcopy(&find_text, lua_tostring(L, 3));
#endif
  else if (strcmp(key, "replace_entry_text") == 0)
#if GTK
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(L, 3));
#elif CURSES
    fcopy(&repl_text, lua_tostring(L, 3));
#endif
  else if (strcmp(key, "match_case") == 0)
    toggle(match_case, lua_toboolean(L, -1));
  else if (strcmp(key, "whole_word") == 0)
    toggle(whole_word, lua_toboolean(L, -1));
  else if (strcmp(key, "lua") == 0)
    toggle(lua_pattern, lua_toboolean(L, -1));
  else if (strcmp(key, "in_files") == 0)
    toggle(in_files, lua_toboolean(L, -1));
  else if (strcmp(key, "find_label_text") == 0)
    set_label_text(flabel, lua_tostring(L, 3));
  else if (strcmp(key, "replace_label_text") == 0)
    set_label_text(rlabel, lua_tostring(L, 3));
  else if (strcmp(key, "find_next_button_text") == 0)
    set_button_label(fnext_button, lua_tostring(L, 3));
  else if (strcmp(key, "find_prev_button_text") == 0)
    set_button_label(fprev_button, lua_tostring(L, 3));
  else if (strcmp(key, "replace_button_text") == 0)
    set_button_label(r_button, lua_tostring(L, 3));
  else if (strcmp(key, "replace_all_button_text") == 0)
    set_button_label(ra_button, lua_tostring(L, 3));
  else if (strcmp(key, "match_case_label_text") == 0) {
    set_option_label(match_case, 0, lua_tostring(L, 3));
  } else if (strcmp(key, "whole_word_label_text") == 0) {
    set_option_label(whole_word, 1, lua_tostring(L, 3));
  } else if (strcmp(key, "lua_pattern_label_text") == 0) {
    set_option_label(lua_pattern, 2, lua_tostring(L, 3));
  } else if (strcmp(key, "in_files_label_text") == 0) {
    set_option_label(in_files, 3, lua_tostring(L, 3));
  } else lua_rawset(L, 1);
  return 0;
}

#if CURSES
/**
 * Signal for a keypress inside the Command Entry.
 * As a BINDFN, returns `TRUE` to stop key propagation.
 * As a PROCESSFN, returns `TRUE` to continue key propagation.
 */
static int c_keypress(EObjectType _, void *object, void *data, chtype key) {
  if (!data && key == KEY_TAB) return TRUE; // do not exit on Tab
  int ctrl = key < 0x20 && key != 9 && key != 27;
  if (ctrl) key = tolower(key ^ 0x40);
  if (key == 27) key = SCK_ESCAPE;
  int halt = lL_event(lua, "command_entry_keypress", LUA_TNUMBER, key,
                      LUA_TBOOLEAN, FALSE, LUA_TBOOLEAN, ctrl, -1);
  refresh_all(), drawCDKEntry((CDKENTRY *)object, FALSE);
  return !halt || key == SCK_ESCAPE;
}
#endif

/** `command_entry.focus()` Lua function. */
static int lce_focus(lua_State *L) {
#if GTK
  if (!gtk_widget_get_visible(command_entry))
    gtk_widget_show(command_entry), gtk_widget_grab_focus(command_entry);
  else
    gtk_widget_hide(command_entry), gtk_widget_grab_focus(focused_view);
#elif CURSES
  if (command_entry) return 0; // already active
  CDKSCREEN *screen = initCDKScreen(newwin(1, 0, LINES - 2, 0));
  command_entry = newCDKEntry(screen, LEFT, TOP, NULL, NULL, A_NORMAL, '_',
                              vMIXED, 0, 0, 256, FALSE, FALSE);
  bindCDKObject(vENTRY, command_entry, KEY_TAB, c_keypress, NULL);
  setCDKEntryPreProcess(command_entry, c_keypress, "");
  setCDKEntryValue(command_entry, command_text);
  char *clipboard = get_clipboard();
  GPasteBuffer = copyChar(clipboard); // set the CDK paste buffer
  curs_set(1), activateCDKEntry(command_entry, NULL), curs_set(0);
  // Set Scintilla clipboard with new CDK paste buffer if necessary.
  if (strcmp(clipboard, GPasteBuffer)) set_clipboard(GPasteBuffer);
  free(clipboard), free(GPasteBuffer), GPasteBuffer = NULL;
  destroyCDKEntry(command_entry), command_entry = NULL;
  delwin(screen->window), destroyCDKScreen(screen), flushch();
#if _WIN32
  redrawwin(scintilla_get_window(focused_view)); // needed for pdcurses
#endif
#endif
  return 0;
}

/** `command_entry.show_completions()` Lua function. */
static int lce_show_completions(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  int len = lua_rawlen(L, 1);
#if GTK
  if (!gtk_widget_get_visible(command_entry))
    luaL_error(L, "command entry inactive");
  GtkEntryCompletion *completion = gtk_entry_get_completion(
                                   GTK_ENTRY(command_entry));
  GtkListStore *store = GTK_LIST_STORE(
                        gtk_entry_completion_get_model(completion));
  gtk_list_store_clear(store);
#elif CURSES
  if (!command_entry) luaL_error(L, "command entry inactive");
  const char **items = malloc(len * sizeof(const char *));
  int width = 0;
#endif
  for (int i = 1; i <= len; i++) {
    lua_rawgeti(L, 1, i);
    if (lua_type(L, -1) == LUA_TSTRING) {
#if GTK
      GtkTreeIter iter;
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, 0, lua_tostring(L, -1), -1);
#elif CURSES
      items[i - 1] = lua_tostring(L, -1);
      if (width < strlen(items[i - 1])) width = strlen(items[i - 1]);
#endif
    }
    lua_pop(L, 1); // value
  }
#if GTK
  gtk_entry_completion_complete(completion);
#elif CURSES
  // Screen needs to take into account border width and scroll bar width.
  int height = (len < LINES - 3) ? len : LINES - 5;
  CDKSCREEN *screen = initCDKScreen(newwin(height + 2, width + 4,
                                           LINES - 4 - height, 0));
  CDKSCROLL *scrolled = newCDKScroll(screen, LEFT, TOP, RIGHT, 0, 0, NULL,
                                     (char **)items, len, FALSE, A_REVERSE,
                                     TRUE, FALSE);
  curs_set(0);
  if (len > 0 && activateCDKScroll(scrolled, NULL) >= 0) {
    char *text = getCDKEntryValue(command_entry), *p = text + strlen(text);
    while (p > text && (isalnum(*(p - 1)) || *(p - 1) == '_')) p--;
    lua_pushlstring(L, text, p - text);
    lua_pushstring(L, items[getCDKScrollCurrentItem(scrolled)]);
    lua_concat(L, 2);
    setCDKEntryValue(command_entry, (char *)lua_tostring(L, -1));
  }
  curs_set(1);
  destroyCDKScroll(scrolled);
  delwin(screen->window), destroyCDKScreen(screen), flushch();
  free(items);
#if _WIN32
  redrawwin(scintilla_get_window(focused_view)); // needed for pdcurses
#endif
  drawCDKEntry(command_entry, FALSE);
#endif
  return 0;
}

/** `command_entry.__index` Lua metatable. */
static int lce__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0) {
    lua_pushstring(L, command_text);
#if CURSES
    if (command_entry) lua_pushstring(L, getCDKEntryValue(command_entry));
#endif
  } else lua_rawget(L, 1);
  return 1;
}

/** `command_entry.__newindex` Lua metatable. */
static int lce__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0) {
#if GTK
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(L, 3));
#elif CURSES
    if (command_entry) setCDKEntryValue(command_entry, lua_tostring(L, 3));
    fcopy(&command_text, lua_tostring(L, 3));
#endif
  } else lua_rawset(L, 1);
  return 0;
}

/** `ui.dialog()` Lua function. */
static int lui_dialog(lua_State *L) {
  GTDialogType type = gtdialog_type(luaL_checkstring(L, 1));
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
  argv[argc] = NULL;
  char *out = gtdialog(type, argc, argv);
  lua_pushstring(L, out);
  free(out), free(argv);
#if (CURSES && _WIN32)
  redrawwin(scintilla_get_window(focused_view)); // needed for pdcurses
#endif
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
  lua_pushlightuserdata(L, view), lua_gettable(L, -2), lua_replace(L, -2);
}

#if GTK
static void l_pushsplittable(lua_State *L, GtkWidget *w) {
  if (GTK_IS_PANED(w)) {
    lua_newtable(L);
    l_pushsplittable(L, child(1, w)), lua_rawseti(L, -2, 1);
    l_pushsplittable(L, child(2, w)), lua_rawseti(L, -2, 2);
    lua_pushboolean(L, GTK_IS_HPANED(w)), lua_setfield(L, -2, "vertical");
    int size = gtk_paned_get_position(GTK_PANED(w));
    lua_pushinteger(L, size), lua_setfield(L, -2, "size");
  } else l_pushview(L, w);
}
#elif CURSES
static void l_pushsplittable(lua_State *L, struct WindowManager *wm) {
  if (wm->dir != SPLIT_LEAF) {
    lua_newtable(L);
    l_pushsplittable(L, wm->first), lua_rawseti(L, -2, 1);
    l_pushsplittable(L, wm->second), lua_rawseti(L, -2, 2);
    lua_pushboolean(L, wm->dir == SPLIT_VER), lua_setfield(L, -2, "vertical");
    lua_pushinteger(L, wm->splitpos), lua_setfield(L, -2, "size");
  } else l_pushview(L, wm->view);
}
#endif

/** `ui.get_split_table()` Lua function. */
static int lui_get_split_table(lua_State *L) {
#if GTK
  GtkWidget *w = focused_view;
  while (GTK_IS_PANED(gtk_widget_get_parent(w))) w = gtk_widget_get_parent(w);
  l_pushsplittable(L, w);
#elif CURSES
  l_pushsplittable(L, wm);
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
  lua_replace(L, -2);
}

/**
 * Synchronizes the tabbar after switching between Scintilla views or documents.
 */
static void sync_tabbar() {
#if GTK
  lua_getfield(lua, LUA_REGISTRYINDEX, "ta_buffers");
  l_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0));
  lua_gettable(lua, -2);
  int i = lua_tointeger(lua, -1) - 1;
  lua_pop(lua, 2); // index and buffers
  GtkNotebook *tabs = GTK_NOTEBOOK(tabbar);
  tab_sync = TRUE, gtk_notebook_set_current_page(tabs, i), tab_sync = FALSE;
//#elif CURSES
  // TODO: tabs
#endif
}

/**
 * Change focus to the given Scintilla view.
 * Generates 'view_before_switch' and 'view_after_switch' events.
 * @param view The Scintilla view to focus.
 */
static void goto_view(Scintilla *view) {
  if (!initing && !closing) lL_event(lua, "view_before_switch", -1);
  l_setglobalview(lua, focused_view = view), sync_tabbar();
  l_setglobaldoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!initing && !closing) lL_event(lua, "view_after_switch", -1);
}

/** `ui.goto_view()` Lua function. */
static int lui_goto_view(lua_State *L) {
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
  // ui.dialog() interferes with focus so gtk_widget_grab_focus() does not
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
  int i = lua_tointeger(L, -1);
  lua_pop(L, 1); // integer
  return i;
}

#if GTK
/**
 * Pushes a menu created from the table at the given valid index onto the stack.
 * Consult the LuaDoc for the table format.
 * @param L The Lua state.
 * @param index The stack index of the table to create the menu from.
 * @param callback An optional GTK callback function associated with each menu
 *   item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 */
static void l_pushmenu(lua_State *L, int index, GCallback callback,
                       int submenu) {
  GtkWidget *menu = gtk_menu_new(), *menu_item = NULL, *submenu_root = NULL;
  const char *label;
  lua_pushvalue(L, index); // copy to stack top so relative indices can be used
  lua_getfield(L, -1, "title");
  if (!lua_isnil(L, -1) || submenu) { // title required for submenu
    label = !lua_isnil(L, -1) ? lua_tostring(L, -1) : "notitle";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(L, 1); // title
  for (int i = 1; i <= lua_rawlen(L, -1); i++) {
    lua_rawgeti(L, -1, i);
    if (lua_istable(L, -1)) {
      lua_getfield(L, -1, "title");
      int is_submenu = !lua_isnil(L, -1);
      lua_pop(L, 1); // title
      if (is_submenu) {
        l_pushmenu(L, -1, callback, TRUE);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              (GtkWidget *)lua_touserdata(L, -1));
        lua_pop(L, 1); // menu
      } else {
        lua_rawgeti(L, -1, 1), label = lua_tostring(L, -1), lua_pop(L, 1);
        int menu_id = l_rawgetiint(L, -1, 2);
        int key = l_rawgetiint(L, -1, 3), modifiers = l_rawgetiint(L, -1, 4);
        if (label) {
          menu_item = (*label) ? gtk_menu_item_new_with_mnemonic(label)
                               : gtk_separator_menu_item_new();
          if (*label && key > 0)
              gtk_widget_add_accelerator(menu_item, "activate", accel, key,
                                         modifiers, GTK_ACCEL_VISIBLE);
          g_signal_connect(menu_item, "activate", callback,
                           GINT_TO_POINTER(menu_id));
          gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
        }
      }
    }
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // table copy
  lua_pushlightuserdata(L, !submenu_root ? menu : submenu_root);
}

/** Signal for a menu item click. */
static void m_clicked(GtkWidget*_, void *id) {
  lL_event(lua, "menu_clicked", LUA_TNUMBER, GPOINTER_TO_INT(id), -1);
}
#endif

/** `ui.menu()` Lua function. */
static int lui_menu(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
#if GTK
  return (l_pushmenu(L, -1, G_CALLBACK(m_clicked), FALSE), 1);
#elif CURSES
  return (lua_pushnil(L), 1);
#endif
}

/** `ui.__index` Lua metatable. */
static int lui__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "clipboard_text") == 0) {
#if GTK
    char *text = gtk_clipboard_wait_for_text(
                 gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    lua_pushstring(L, text ? text : "");
    if (text) free(text);
#elif CURSES
    char *text = get_clipboard();
    lua_pushlstring(L, text, scintilla_get_clipboard(focused_view, NULL));
    free(text);
#endif
  } else if (strcmp(key, "maximized") == 0)
#if GTK
    lua_pushboolean(L, gdk_window_get_state(gtk_widget_get_window(window)) &
                       GDK_WINDOW_STATE_MAXIMIZED);
#elif CURSES
    lua_pushboolean(L, FALSE);
#endif
  else if (strcmp(key, "size") == 0) {
#if GTK
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
#elif CURSES
    int width = COLS, height = LINES;
#endif
    lua_newtable(L);
    lua_pushinteger(L, width), lua_rawseti(L, -2, 1);
    lua_pushinteger(L, height), lua_rawseti(L, -2, 2);
  } else if (strcmp(key, "tabs") == 0)
    lua_pushboolean(L, show_tabs);
  else
    lua_rawget(L, 1);
  return 1;
}

static void set_statusbar_text(const char *text, int bar) {
#if GTK
  if (!statusbar[0] || !statusbar[1]) return; // unavailable on startup
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar[bar]), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[bar]), 0, text);
#elif CURSES
  for (int i = ((bar == 0) ? 0 : 20); i < ((bar == 0) ? 20 : COLS); i++)
    mvaddch(LINES - 1, i, ' '); // clear statusbar
  mvaddstr(LINES - 1, (bar == 0) ? 0 : COLS - strlen(text), text), refresh();
#endif
}

/** `ui.__newindex` Lua metatable. */
static int lui__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0) {
#if GTK
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(L, 3));
#elif CURSES
    for (int i = 0; i < COLS; i++) mvaddch(0, i, ' '); // clear titlebar
    mvaddstr(0, 0, lua_tostring(L, 3)), refresh();
#endif
  } else if (strcmp(key, "clipboard_text") == 0)
    set_clipboard(luaL_checkstring(L, 3));
  else if (strcmp(key, "statusbar_text") == 0)
    set_statusbar_text(lua_tostring(L, 3), 0);
  else if (strcmp(key, "bufstatusbar_text") == 0)
    set_statusbar_text(lua_tostring(L, 3), 1);
  else if (strcmp(key, "menubar") == 0) {
#if GTK
    luaL_argcheck(L, lua_istable(L, 3), 3, "table of menus expected");
    GtkWidget *new_menubar = gtk_menu_bar_new(); // TODO: this leaks on error
    for (int i = 1; i <= lua_rawlen(L, 3); i++) {
      lua_rawgeti(L, 3, i);
      luaL_argcheck(L, lua_isuserdata(L, -1), 3, "table of menus expected");
      GtkWidget *menu_item = (GtkWidget *)lua_touserdata(L, -1);
      gtk_menu_shell_append(GTK_MENU_SHELL(new_menubar), menu_item);
      lua_pop(L, 1); // value
    }
    GtkWidget *vbox = gtk_widget_get_parent(menubar);
    gtk_container_remove(GTK_CONTAINER(vbox), menubar);
    gtk_box_pack_start(GTK_BOX(vbox), menubar = new_menubar, FALSE, FALSE, 0);
    gtk_box_reorder_child(GTK_BOX(vbox), new_menubar, 0);
    gtk_widget_show_all(new_menubar);
#if (__APPLE__ && !CURSES)
    gtkosx_application_set_menu_bar(osxapp, GTK_MENU_SHELL(new_menubar));
    gtk_widget_hide(new_menubar);
#endif
#endif
  } else if (strcmp(key, "maximized") == 0) {
#if GTK
    lua_toboolean(L, 3) ? gtk_window_maximize(GTK_WINDOW(window))
                        : gtk_window_unmaximize(GTK_WINDOW(window));
#endif
  } else if (strcmp(key, "size") == 0) {
#if GTK
    luaL_argcheck(L, lua_istable(L, 3) && lua_rawlen(L, 3) == 2, 3,
                  "{width, height} table expected");
    int w = l_rawgetiint(L, 3, 1), h = l_rawgetiint(L, 3, 2);
    if (w > 0 && h > 0) gtk_window_resize(GTK_WINDOW(window), w, h);
#endif
  } else if (strcmp(key, "tabs") == 0) {
    show_tabs = lua_toboolean(L, 3);
#if GTK
    gtk_widget_set_visible(tabbar, show_tabs &&
                           gtk_notebook_get_n_pages(GTK_NOTEBOOK(tabbar)) > 1);
//#elif CURSES
    // TODO: tabs
#endif
  } else lua_rawset(L, 1);
  return 0;
}

/**
 * Compares the Scintilla document at the given index with the global one and
 * returns 0 if they are equivalent, non-zero otherwise.
 * If non-equivalent, loads the document in `dummy_view` for non-global document
 * use. Raises and error if the value is not a Scintilla document or if the
 * document no longer exists.
 * @param L The Lua state.
 * @param index The stack index of the Scintilla document.
 * @return 0 or the Scintilla document's pointer
 */
static sptr_t l_globaldoccompare(lua_State *L, int index) {
  luaL_getmetatable(L, "ta_buffer");
  lua_getmetatable(L, (index > 0) ? index : index - 1);
  luaL_argcheck(L, lua_rawequal(L, -1, -2), index, "Buffer expected");
  lua_getfield(L, (index > 0) ? index : index - 2, "doc_pointer");
  sptr_t doc = (sptr_t)lua_touserdata(L, -1);
  lua_pop(L, 3); // doc_pointer, metatable, metatable
  if (doc != SS(focused_view, SCI_GETDOCPOINTER, 0, 0)) {
    lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
    l_pushdoc(L, doc), lua_gettable(L, -2);
    luaL_argcheck(L, !lua_isnil(L, -1), index, "this Buffer does not exist");
    lua_pop(L, 2); // buffer, ta_buffers
    return (SS(dummy_view, SCI_SETDOCPOINTER, 0, doc), doc);
  } else return 0;
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
  SS(view, SCI_SETDOCPOINTER, 0, doc), sync_tabbar();
  l_setglobaldoc(L, doc);
  lua_pop(L, 2); // buffer and buffers
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
  for (int i = 1; i <= lua_rawlen(L, -1); i++) {
    lua_rawgeti(L, -1, i);
    Scintilla *view = l_toview(L, -1);
    if (doc == SS(view, SCI_GETDOCPOINTER, 0, 0)) lL_gotodoc(L, view, -1, TRUE);
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // views
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  for (int i = 1; i <= lua_rawlen(L, -1); i++) {
    lua_rawgeti(L, -1, i);
    if (doc != l_todoc(L, -1)) {
      lua_getfield(L, -1, "doc_pointer");
      // bs[userdata] = b, bs[#bs + 1] = b, bs[b] = #bs
      lua_pushvalue(L, -2), lua_rawseti(L, -5, lua_rawlen(L, -5) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -5);
      lua_pushinteger(L, lua_rawlen(L, -3)), lua_settable(L, -4);
    } else {
#if GTK
      // Remove the tab from the tabbar.
      gtk_notebook_remove_page(GTK_NOTEBOOK(tabbar), i - 1);
      gtk_widget_set_visible(tabbar, show_tabs && lua_rawlen(L, -2) > 2);
//#elif CURSES
      // TODO: tabs
#endif
      lua_pop(L, 1); // value
    }
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
  lL_removedoc(lua, doc), SS(dummy_view, SCI_SETDOCPOINTER, 0, 0);
  SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

/** `buffer.delete()` Lua function. */
static int lbuffer_delete(lua_State *L) {
  Scintilla *view = l_globaldoccompare(L, 1) == 0 ? focused_view : dummy_view;
  sptr_t doc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (lua_rawlen(L, -1) == 1) new_buffer(0);
  lL_gotodoc(L, focused_view, -1, TRUE);
  delete_buffer(doc);
  lL_event(L, "buffer_deleted", -1), lL_event(L, "buffer_after_switch", -1);
  return 0;
}

/** `_G.buffer_new()` Lua function. */
static int lbuffer_new(lua_State *L) {
  new_buffer(0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  return (lua_rawgeti(L, -1, lua_rawlen(L, -1)), 1);
}

/** `buffer.text_range()` Lua function. */
static int lbuffer_text_range(lua_State *L) {
  Scintilla *view = l_globaldoccompare(L, 1) == 0 ? focused_view : dummy_view;
  long min = luaL_checklong(L, 2), max = luaL_checklong(L, 3);
  luaL_argcheck(L, min <= max, 3, "start > end");
  struct Sci_TextRange tr = {{min, max}, malloc(max - min + 1)};
  SS(view, SCI_GETTEXTRANGE, 0, (sptr_t)&tr);
  lua_pushlstring(L, tr.lpstrText, max - min);
  if (tr.lpstrText) free(tr.lpstrText);
  return 1;
}

/**
 * Checks whether the function argument arg is the given Scintilla parameter
 * type and returns it cast to the proper type.
 * @param L The Lua state.
 * @param arg The stack index of the Scintilla parameter.
 * @param type The Scintilla type to convert to.
 * @return Scintilla param
 */
static sptr_t lL_checkscintillaparam(lua_State *L, int *arg, int type) {
  switch (type) {
    case SSTRING: return (sptr_t)luaL_checkstring(L, (*arg)++);
    case SBOOL: return lua_toboolean(L, (*arg)++);
    case SKEYMOD: {
      int key = luaL_checkinteger(L, (*arg)++) & 0xFFFF;
      return key | ((luaL_checkinteger(L, (*arg)++) &
                    (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
    } case SINT: case SLEN: case SPOS: case SCOLOR:
      return luaL_checklong(L, (*arg)++);
    default: return 0;
  }
}

/**
 * Calls a function as a Scintilla function.
 * Does not remove any arguments from the stack, but does push results.
 * @param L The Lua state.
 * @param view The Scintilla view to call.
 * @param msg The Scintilla message.
 * @param wtype The type of Scintilla wParam.
 * @param ltype The type of Scintilla lParam.
 * @param rtype The type of the Scintilla return.
 * @param arg The stack index of the first Scintilla parameter. Subsequent
 *   elements will also be passed to Scintilla as needed.
 * @return number of results pushed onto the stack.
 * @see lL_checkscintillaparam
 */
static int l_callscintilla(lua_State *L, Scintilla *view, int msg, int wtype,
                           int ltype, int rtype, int arg) {
  uptr_t wparam = 0;
  sptr_t lparam = 0, len = 0;
  int params_needed = 2, string_return = FALSE;
  char *text = NULL;

  // Even though the SCI_PRIVATELEXERCALL interface has ltype int, the LPeg
  // lexer API uses different types depending on wparam. Modify ltype
  // appropriately. See the LPeg lexer API for more information.
  if (msg == SCI_PRIVATELEXERCALL) {
    ltype = SSTRINGRET;
    int c = luaL_checklong(L, arg);
    if (c == SCI_GETDIRECTFUNCTION || c == SCI_SETDOCPOINTER ||
        c == SCI_CHANGELEXERSTATE)
      ltype = SINT;
    else if (c == SCI_SETLEXERLANGUAGE)
      ltype = SSTRING;
  }

  // Set wParam and lParam appropriately for Scintilla based on wtype and ltype.
  if (wtype == SLEN && ltype == SSTRING) {
    wparam = (uptr_t)lua_rawlen(L, arg);
    lparam = (sptr_t)luaL_checkstring(L, arg);
    params_needed = 0;
  } else if (ltype == SSTRINGRET || rtype == SSTRINGRET)
    string_return = TRUE, params_needed = (wtype == SLEN) ? 0 : 1;
  if (params_needed > 0) wparam = lL_checkscintillaparam(L, &arg, wtype);
  if (params_needed > 1) lparam = lL_checkscintillaparam(L, &arg, ltype);
  if (string_return) { // create a buffer for the return string
    len = SS(view, msg, wparam, 0);
    if (wtype == SLEN) wparam = len;
    text = malloc(len + 1), text[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    lparam = (sptr_t)text;
  }

  // Send the message to Scintilla and return the appropriate values.
  sptr_t result = SS(view, msg, wparam, lparam);
  arg = lua_gettop(L);
  if (string_return) lua_pushlstring(L, text, len), free(text);
  if (rtype > SVOID && rtype < SBOOL)
    lua_pushinteger(L, result);
  else if (rtype == SBOOL)
    lua_pushboolean(L, result);
  return lua_gettop(L) - arg;
}

static int lbuf_closure(lua_State *L) {
  Scintilla *view = focused_view;
  // If optional buffer argument is given, check it.
  if (lua_istable(L, 1) && l_globaldoccompare(L, 1) != 0) view = dummy_view;
  // Interface table is of the form { msg, rtype, wtype, ltype }.
  return l_callscintilla(L, view, l_rawgetiint(L, lua_upvalueindex(1), 1),
                         l_rawgetiint(L, lua_upvalueindex(1), 3),
                         l_rawgetiint(L, lua_upvalueindex(1), 4),
                         l_rawgetiint(L, lua_upvalueindex(1), 2),
                         lua_istable(L, 1) ? 2 : 1);
}

/** `buffer.__index` Lua metatable. */
static int lbuf_property(lua_State *L) {
  int newindex = (lua_gettop(L) == 3);
  luaL_getmetatable(L, "ta_buffer");
  lua_getmetatable(L, 1); // metatable can be either ta_buffer or ta_bufferp
  int is_buffer = lua_rawequal(L, -1, -2);
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
  // If the table is a buffer, the key is given; otherwise the table is an
  // indexible property.
  is_buffer ? lua_pushvalue(L, 2) : lua_getfield(L, 1, "property");
  lua_gettable(L, -2);
  if (lua_istable(L, -1)) {
    Scintilla *view = focused_view;
    // Interface table is of the form {get_id, set_id, rtype, wtype}.
    if (!is_buffer) lua_getfield(L, 1, "buffer");
    if (l_globaldoccompare(L, is_buffer ? 1 : -1) != 0) view = dummy_view;
    if (!is_buffer) lua_pop(L, 1);
    if (is_buffer && l_rawgetiint(L, -1, 4) != SVOID) { // indexible property
      lua_newtable(L);
      lua_pushvalue(L, 2), lua_setfield(L, -2, "property");
      lua_pushvalue(L, 1), lua_setfield(L, -2, "buffer");
      l_setmetatable(L, -1, "ta_bufferp", lbuf_property, lbuf_property);
      return 1;
    }
    int msg = l_rawgetiint(L, -1, !newindex ? 1 : 2);
    int wtype = l_rawgetiint(L, -1, !newindex ? 4 : 3);
    int ltype = !newindex ? SVOID : l_rawgetiint(L, -1, 4);
    int rtype = !newindex ? l_rawgetiint(L, -1, 3) : SVOID;
    if (newindex &&
        (ltype != SVOID || wtype == SSTRING || wtype == SSTRINGRET)) {
      int temp = (wtype != SSTRINGRET) ? wtype : SSTRING;
      wtype = ltype, ltype = temp;
    }
    luaL_argcheck(L, msg != 0, !newindex ? 2 : 3,
                  !newindex ? "write-only property" : "read-only property");
    return l_callscintilla(L, view, msg, wtype, ltype, rtype,
                           (!is_buffer || !newindex) ? 2 : 3);
  } else lua_pop(L, 2); // non-table, ta_properties

  if (strcmp(lua_tostring(L, 2), "tab_label") == 0) {
    // Return or update the buffer's tab label.
    lua_getfield(L, 1, "tab_pointer");
#if GTK
    GtkNotebook *tabs = GTK_NOTEBOOK(tabbar);
    GtkWidget *tab = (GtkWidget *)lua_touserdata(L, -1);
    lua_pushstring(L, gtk_notebook_get_tab_label_text(tabs, tab));
    if (newindex)
      gtk_notebook_set_tab_label_text(tabs, tab, luaL_checkstring(L, 3));
//#elif CURSES
    // TODO: tabs
#endif
    return !newindex ? 1 : 0;
  } else if (!newindex) {
    // If the key is a Scintilla constant, return its value.
    lua_getfield(L, LUA_REGISTRYINDEX, "ta_constants");
    lua_pushvalue(L, 2), lua_gettable(L, -2);
    if (lua_isnumber(L, -1)) return 1;
    lua_pop(L, 2); // non-number, ta_constants
  }

  return !newindex ? (lua_rawget(L, 1), 1) : (lua_rawset(L, 1), 0);
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
#if GTK
  GtkWidget *tab = gtk_vbox_new(FALSE, 0); // placeholder in GtkNotebook
  lua_pushlightuserdata(L, tab), lua_setfield(L, -3, "tab_pointer");
//#elif CURSES
  // TODO: tabs
#endif
  l_setcfunction(L, -2, "delete", lbuffer_delete);
  l_setcfunction(L, -2, "new", lbuffer_new);
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
#if GTK
  // Add a tab to the tabbar.
  l_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0));
  lua_getfield(lua, -1, "tab_pointer");
  GtkWidget *tab = (GtkWidget *)lua_touserdata(lua, -1);
  tab_sync = TRUE;
  int i = gtk_notebook_append_page(GTK_NOTEBOOK(tabbar), tab, NULL);
  gtk_widget_show(tab), gtk_widget_set_visible(tabbar, show_tabs && i > 0);
  gtk_notebook_set_current_page(GTK_NOTEBOOK(tabbar), i);
  tab_sync = FALSE;
  lua_pop(lua, 2); // tab_pointer and buffer
//#elif CURSES
  // TODO: tabs
#endif
  l_setglobaldoc(lua, doc);
  if (!initing) lL_event(lua, "buffer_new", -1);
}

/** `_G.quit()` Lua function. */
static int lquit(lua_State *L) {
#if GTK
  GdkEventAny event = {GDK_DELETE, gtk_widget_get_window(window), TRUE};
  gdk_event_put((GdkEvent *)&event);
#elif CURSES
  quit = TRUE;
#endif
  return 0;
}

#if _WIN32
char *stpcpy(char *dest, const char *src) {
  return (strcpy(dest, src), dest + strlen(src));
}
#endif

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
    gtk_dialog_run(GTK_DIALOG(dialog)), gtk_widget_destroy(dialog);
#elif CURSES
    WINDOW *win = newwin(0, 0, 1, 0);
    wprintw(win, lua_tostring(L, -1)), wrefresh(win);
    getch(), delwin(win);
#endif
    lua_settop(L, 0);
  }
  free(file);
  return ok;
}

/** `_G.reset()` Lua function. */
static int lreset(lua_State *L) {
  lL_event(L, "reset_before", -1);
  lL_init(L, 0, NULL, TRUE);
  l_setglobalview(L, focused_view);
  l_setglobaldoc(L, SS(focused_view, SCI_GETDOCPOINTER, 0, 0));
  lua_pushnil(L), lua_setglobal(L, "arg");
  lL_dofile(L, "init.lua"), lL_event(L, "initialized", -1);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_arg"), lua_setglobal(L, "arg");
  lL_event(L, "reset_after", -1);
  return 0;
}

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

/** `_G.timeout()` Lua function. */
static int ltimeout(lua_State *L) {
#if GTK
  double timeout = luaL_checknumber(L, 1);
  luaL_argcheck(L, timeout > 0, 1, "timeout must be > 0");
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  int n = lua_gettop(L), *refs = (int *)calloc(n, sizeof(int));
  for (int i = 2; i <= n; i++)
    lua_pushvalue(L, i), refs[i - 2] = luaL_ref(L, LUA_REGISTRYINDEX);
  g_timeout_add(timeout * 1000, emit_timeout, (void *)refs);
#elif CURSES
  luaL_error(L, "not implemented in this environment");
#endif
  return 0;
}

/** `string.iconv()` Lua function. */
static int lstring_iconv(lua_State *L) {
  size_t inbytesleft = 0;
  char *inbuf = (char *)luaL_checklstring(L, 1, &inbytesleft);
  const char *to = luaL_checkstring(L, 2), *from = luaL_checkstring(L, 3);
  iconv_t cd = iconv_open(to, from);
  if (cd != (iconv_t)-1) {
    char *outbuf = malloc(inbytesleft + 1), *outbufp = outbuf;
    size_t outbytesleft = inbytesleft, bufsize = inbytesleft;
    int n = 1; // concat this many converted strings
    while (iconv(cd, &inbuf, &inbytesleft, &outbufp, &outbytesleft) == -1)
      if (errno == E2BIG) {
        // Buffer was too small to store converted string. Push the partially
        // converted string for later concatenation.
        lua_checkstack(L, 2), lua_pushlstring(L, outbuf, outbufp - outbuf), n++;
        outbufp = outbuf, outbytesleft = bufsize;
      } else {
        free(outbuf), iconv_close(cd);
        luaL_error(L, "conversion failed");
      }
    lua_pushlstring(L, outbuf, outbufp - outbuf);
    lua_concat(L, n);
    free(outbuf), iconv_close(cd);
  } else luaL_error(L, "invalid encoding(s)");
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
    lua_pop(L, 2); // package.loaded and package
#if LUA_VERSION_NUM >= 502
    lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
    lL_cleartable(L, -1);
    lua_pop(L, 1); // _G
#else
    lL_cleartable(L, LUA_GLOBALSINDEX);
#endif
  }
  lua_pushinteger(L, (sptr_t)L), lua_setglobal(L, "_LUA");
  luaL_openlibs(L);
  lL_openlib(L, "lpeg", luaopen_lpeg);
  lL_openlib(L, "lfs", luaopen_lfs);
  lL_openlib(L, "spawn", luaopen_spawn);

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
  l_setcfunction(L, -1, "dialog", lui_dialog);
  l_setcfunction(L, -1, "get_split_table", lui_get_split_table);
  l_setcfunction(L, -1, "goto_view", lui_goto_view);
  l_setcfunction(L, -1, "menu", lui_menu);
  l_setmetatable(L, -1, "ta_ui", lui__index, lui__newindex);
  lua_setglobal(L, "ui");

  lua_getglobal(L, "_G");
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
#if _WIN32
  lua_pushboolean(L, 1), lua_setglobal(L, "WIN32");
#elif (__APPLE__ && !CURSES)
  lua_pushboolean(L, 1), lua_setglobal(L, "OSX");
#endif
#if CURSES
  lua_pushboolean(L, 1), lua_setglobal(L, "CURSES");
  show_tabs = 0; // TODO: tabs
#endif
  const char *charset = NULL;
#if GTK
  g_get_charset(&charset);
#elif (CURSES && !_WIN32)
  charset = getenv("CHARSET");
  if (!charset || !*charset) {
    char *locale = getenv("LC_ALL");
    if (!locale || !*locale) locale = getenv("LANG");
    if (locale && (charset = strchr(locale, '.'))) charset++;
  }
#elif (CURSES && _WIN32)
  char codepage[8];
  sprintf(codepage, "CP%d", GetACP()), charset = codepage;
#endif
  lua_pushstring(L, charset), lua_setglobal(L, "_CHARSET");

  if (!lL_dofile(L, "core/init.lua")) return (lua_close(L), FALSE);
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

#if GTK
/** Signal for a Textadept window focus change. */
static int w_focus(GtkWidget*_, GdkEventFocus*__, void*___) {
  if (focused_view && !gtk_widget_has_focus(focused_view))
    gtk_widget_grab_focus(focused_view);
  return (lL_event(lua, "focus", -1), FALSE);
}

/** Signal for a Textadept keypress. */
static int w_keypress(GtkWidget*_, GdkEventKey *event, void*__) {
  if (event->keyval == GDK_Escape && gtk_widget_get_visible(findbox) &&
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
  for (int i = 1; i <= lua_rawlen(L, -1); i++) {
    lua_rawgeti(L, -1, i);
    if (view != l_toview(L, -1)) {
      lua_getfield(L, -1, "widget_pointer");
      // vs[userdata] = v, vs[#vs + 1] = v, vs[v] = #vs
      lua_pushvalue(L, -2), lua_rawseti(L, -5, lua_rawlen(L, -5) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -5);
      lua_pushinteger(L, lua_rawlen(L, -3)), lua_settable(L, -4);
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
  GtkWidget *child1 = child(1, pane), *child2 = child(2, pane);
  GTK_IS_PANED(child1) ? remove_views_from_pane(child1) : delete_view(child1);
  GTK_IS_PANED(child2) ? remove_views_from_pane(child2) : delete_view(child2);
}
#elif CURSES
/**
 * Signal that the curses window manager removed a view.
 * @param view The view removed.
 * @see delete_view
 */
static void view_removed(void *view, void*_) {delete_view((Scintilla *)view);}
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
  GtkWidget *other = (child(1, pane) != view) ? child(1, pane) : child(2, pane);
  g_object_ref(view), g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), view);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_views_from_pane(other) : delete_view(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent))
    !child(1, parent) ? gtk_paned_add1(GTK_PANED(parent), view)
                      : gtk_paned_add2(GTK_PANED(parent), view);
  else
    gtk_container_add(GTK_CONTAINER(parent), view);
  //gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(view));
  g_object_unref(view), g_object_unref(other);
#elif CURSES
  if (wm->dir == SPLIT_LEAF) return FALSE;
  wman_unsplit_view(wm, view, view_removed), scintilla_refresh(view);
#endif
  return TRUE;
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
  for (int i = 1; i <= lua_rawlen(L, -1); i++)
    lua_rawgeti(L, -1, i), delete_buffer(l_todoc(L, -1)), lua_pop(L, 1);
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

#if (__APPLE__ && !CURSES)
/**
 * Signal for opening files from OSX.
 * Generates an 'appleevent_odoc' event for each document sent.
 */
static int w_open_osx(GtkosxApplication*_, char *path, void*__) {
  return (lL_event(lua, "appleevent_odoc", LUA_TSTRING, path, -1), TRUE);
}

/**
 * Signal for block terminating Textadept from OSX.
 * Generates a 'quit' event.
 */
static int w_exit_osx(GtkosxApplication*_, void*__) {
  return !lL_event(lua, "quit", -1);
}

/**
 * Signal for terminating Textadept from OSX.
 * Closes the Lua state and releases resources.
 * @see l_close
 */
static void w_quit_osx(GtkosxApplication*_, void*__) {
  l_close(lua);
  scintilla_release_resources();
  g_object_unref(osxapp);
  gtk_main_quit();
}
#endif

/**
 * Signal for switching buffer tabs.
 * When triggered by the user (i.e. not synchronizing the tabbar), switches to
 * the specified buffer.
 * Generates 'buffer_before_switch' and 'buffer_after_switch' events.
 */
static void t_tabchange(GtkNotebook*_, GtkWidget*__, int page_num, void*___) {
  if (tab_sync) return;
  lL_event(lua, "buffer_before_switch", -1);
  lL_gotodoc(lua, focused_view, page_num + 1, FALSE);
  lL_event(lua, "buffer_after_switch", -1);
}

/**
 * Shows the context menu for a widget based on a mouse event.
 * @param L The Lua state.
 * @param event An optional GTK mouse button event.
 * @param field The ui table field that contains the context menu.
 */
static void lL_showcontextmenu(lua_State *L, void *event, char *field) {
  lua_getglobal(L, "ui");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, field);
    if (lua_isuserdata(L, -1)) {
      GtkWidget *menu = (GtkWidget *)lua_touserdata(L, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? ((GdkEventButton *)event)->button : 0,
                     gdk_event_get_time((GdkEvent *)event));
    }
    lua_pop(L, 1); // ui context menu field
  } else lua_pop(L, 1); // non-table
}

/** Signal for a tabbar mouse click. */
static int t_tabbuttonpress(GtkWidget*_, GdkEventButton *event, void*__) {
  if (event->type != GDK_BUTTON_PRESS || event->button != 3) return FALSE;
  GtkNotebook *tabs = GTK_NOTEBOOK(tabbar);
  for (int i = 0; i < gtk_notebook_get_n_pages(tabs); i++) {
    GtkWidget *page = gtk_notebook_get_nth_page(tabs, i);
    GtkWidget *label = gtk_notebook_get_tab_label(tabs, page);
    int x0, y0;
    gdk_window_get_origin(gtk_widget_get_window(label), &x0, &y0);
    GtkAllocation allocation;
    gtk_widget_get_allocation(label, &allocation);
    if (event->x_root > x0 + allocation.x + allocation.width) continue;
    gtk_notebook_set_current_page(tabs, i);
    return (lL_showcontextmenu(lua, (void *)event, "tab_context_menu"), TRUE);
  }
  return FALSE;
}
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
  lua_pushinteger(L, n->modificationType);
  lua_setfield(L, -2, "modification_type");
  lua_pushstring(L, n->text), lua_setfield(L, -2, "text");
  //lua_pushinteger(L, n->length), lua_setfield(L, -2, "length");
  //lua_pushinteger(L, n->linesAdded), lua_setfield(L, -2, "lines_added");
  //lua_pushinteger(L, n->message), lua_setfield(L, -2, "message");
  lua_pushinteger(L, n->wParam), lua_setfield(L, -2, "wParam");
  //lua_pushinteger(L, n->lParam), lua_setfield(L, -2, "lParam");
  lua_pushinteger(L, n->line), lua_setfield(L, -2, "line");
  //lua_pushinteger(L, n->foldLevelNow), lua_setfield(L, -2, "fold_level_now");
  //lua_pushinteger(L, n->foldLevelPrev);
  //lua_setfield(L, -2, "fold_level_prev");
  lua_pushinteger(L, n->margin), lua_setfield(L, -2, "margin");
  lua_pushinteger(L, n->x), lua_setfield(L, -2, "x");
  lua_pushinteger(L, n->y), lua_setfield(L, -2, "y");
  //lua_pushinteger(L, n->token), lua_setfield(L, -2, "token");
  //lua_pushinteger(L, n->annotationLinesAdded);
  //lua_setfield(L, -2, "annotation_lines_added");
  lua_pushinteger(L, n->updated), lua_setfield(L, -2, "updated");
  lL_event(L, "SCN", LUA_TTABLE, luaL_ref(L, LUA_REGISTRYINDEX), -1);
}

/** Signal for a Scintilla notification. */
static void s_notify(Scintilla *view, int _, void *lParam, void*__) {
  struct SCNotification *n = (struct SCNotification *)lParam;
  if (focused_view == view || n->nmhdr.code == SCN_URIDROPPED) {
    if (focused_view != view) goto_view(view);
    lL_notify(lua, n);
  } else if (n->nmhdr.code == SCN_SAVEPOINTLEFT) {
    Scintilla *prev = focused_view;
    // Do not let a split view steal focus.
    goto_view(view), lL_notify(lua, n), goto_view(prev);
  } else if (n->nmhdr.code == SCN_FOCUSIN) goto_view(view);
}

#if GTK
/** Signal for a Scintilla keypress. */
static int s_keypress(GtkWidget*_, GdkEventKey *event, void*__) {
  return lL_event(lua, "keypress", LUA_TNUMBER, event->keyval, event_mod(SHIFT),
                  event_mod(CONTROL), event_mod(MOD1), event_mod(META), -1);
}

/** Signal for a Scintilla mouse click. */
static int s_buttonpress(GtkWidget*_, GdkEventButton *event, void*__) {
  if (event->type == GDK_BUTTON_PRESS && event->button == 3)
    return (lL_showcontextmenu(lua, (void *)event, "context_menu"), TRUE);
  return FALSE;
}
#endif

/**
 * Checks whether the function argument narg is a Scintilla view and returns
 * this view cast to a Scintilla.
 * @param L The Lua state.
 * @param arg The stack index of the Scintilla view.
 * @return Scintilla view
 */
static Scintilla *lL_checkview(lua_State *L, int arg) {
  luaL_getmetatable(L, "ta_view");
  lua_getmetatable(L, arg);
  luaL_argcheck(L, lua_rawequal(L, -1, -2), arg, "View expected");
  lua_getfield(L, (arg > 0) ? arg : arg - 2, "widget_pointer");
  Scintilla *view = (Scintilla *)lua_touserdata(L, -1);
  lua_pop(L, 3); // widget_pointer, metatable, metatable
  return view;
}

/** `view.goto_buffer()` Lua function. */
static int lview_goto_buffer(lua_State *L) {
  Scintilla *view = lL_checkview(L, 1), *prev_view = focused_view;
  int n = luaL_checkinteger(L, 2), relative = lua_toboolean(L, 3);
  // If the indexed view is not currently focused, temporarily focus it so calls
  // to handlers will not throw 'indexed buffer is not the focused one' error.
  int switch_focus = (view != focused_view);
  if (switch_focus) SS(view, SCI_SETFOCUS, TRUE, 0);
  if (!initing) lL_event(L, "buffer_before_switch", -1);
  lL_gotodoc(L, view, n, relative);
  if (!initing) lL_event(L, "buffer_after_switch", -1);
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

  GtkWidget *parent = gtk_widget_get_parent(view);
  if (!parent) return; // error on startup (e.g. loading theme or settings)
  GtkWidget *view2 = new_view(curdoc);
  g_object_ref(view);
  gtk_container_remove(GTK_CONTAINER(parent), view);
  GtkWidget *pane = vertical ? gtk_hpaned_new() : gtk_vpaned_new();
  gtk_paned_add1(GTK_PANED(pane), view), gtk_paned_add2(GTK_PANED(pane), view2);
  gtk_container_add(GTK_CONTAINER(parent), pane);
  gtk_paned_set_position(GTK_PANED(pane), middle);
  gtk_widget_show_all(pane);
  g_object_unref(view);

  while (gtk_events_pending()) gtk_main_iteration(); // ensure view2 is painted
#elif CURSES
  Scintilla *view2 = new_view(curdoc);
  wman_split_view(wm, vertical, view, view2, scintilla_get_window(view2));
#endif
  focus_view(view2);
  SS(view2, SCI_SETSEL, anchor, current_pos);
  int new_first_line = SS(view2, SCI_GETFIRSTVISIBLELINE, 0, 0);
  SS(view2, SCI_LINESCROLL, first_line - new_first_line, 0);
}

/** `view.split()` Lua function. */
static int lview_split(lua_State *L) {
  split_view(lL_checkview(L, 1), lua_toboolean(L, 2));
  // Return old view, new view.
  return (lua_pushvalue(L, 1), lua_getglobal(L, "view"), 2);
}

/** `view.unsplit()` Lua function. */
static int lview_unsplit(lua_State *L) {
  return (lua_pushboolean(L, unsplit_view(lL_checkview(L, 1))), 1);
}

/** `view.__index` Lua metatable. */
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
#elif CURSES
    struct WindowManager *parent = wman_parent(wm, wman_view_owner(wm, view));
    parent ? lua_pushinteger(L, parent->splitpos) : lua_pushnil(L);
#endif
  } else lua_rawget(L, 1);
  return 1;
}

/** `view.__newindex` Lua metatable. */
static int lview__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "buffer") == 0)
    luaL_argerror(L, 2, "read-only property");
  else if (strcmp(key, "size") == 0) {
    int size = luaL_checkinteger(L, 3);
    if (size < 0) size = 0;
#if GTK
    GtkWidget *pane = gtk_widget_get_parent(lL_checkview(L, 1));
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
#elif CURSES
    Scintilla *view = lL_checkview(L, 1);
    struct WindowManager *split = wman_parent(wm, wman_view_owner(wm, view));
    if (split) wman_move_split(split, size);
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
  signal(view, "key-press-event", s_keypress);
  signal(view, "button-press-event", s_buttonpress);
#elif CURSES
  Scintilla *view = scintilla_new(s_notify);
#endif
  SS(view, SCI_USEPOPUP, 0, 0);
  lL_addview(lua, view);
  l_setglobalview(lua, view);
  if (doc) SS(view, SCI_SETDOCPOINTER, 0, doc);
  focus_view(view), focused_view = view;
  if (!doc) new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!initing) lL_event(lua, "view_new", -1);
  return view;
}

#if GTK
/** Creates the Find box. */
static GtkWidget *new_findbox() {
  findbox = gtk_table_new(2, 6, FALSE);
  find_store = gtk_list_store_new(1, G_TYPE_STRING);
  repl_store = gtk_list_store_new(1, G_TYPE_STRING);

  flabel = gtk_label_new_with_mnemonic("_Find:");
  rlabel = gtk_label_new_with_mnemonic("R_eplace:");
  GtkWidget *find_combo = gtk_combo_box_entry_new_with_model(
                          GTK_TREE_MODEL(find_store), 0);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(find_combo), 0);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(find_combo), FALSE);
  find_entry = gtk_bin_get_child(GTK_BIN(find_combo));
  gtk_entry_set_activates_default(GTK_ENTRY(find_entry), TRUE);
  GtkWidget *replace_combo = gtk_combo_box_entry_new_with_model(
                             GTK_TREE_MODEL(repl_store), 0);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(replace_combo), 0);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(replace_combo), FALSE);
  replace_entry = gtk_bin_get_child(GTK_BIN(replace_combo));
  gtk_entry_set_activates_default(GTK_ENTRY(replace_entry), TRUE);
  g_object_unref(find_store), g_object_unref(repl_store);
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

  attach(find_combo, 1, 2, 0, 1, FILL(EXPAND), FILL(SHRINK), 5, 0);
  attach(replace_combo, 1, 2, 1, 2, FILL(EXPAND), FILL(SHRINK), 5, 0);
  attach(flabel, 0, 1, 0, 1, FILL(SHRINK), FILL(SHRINK), 5, 0);
  attach(rlabel, 0, 1, 1, 2, FILL(SHRINK), FILL(SHRINK), 5, 0);
  attach(fnext_button, 2, 3, 0, 1, FILL(SHRINK), FILL(SHRINK), 0, 0);
  attach(fprev_button, 3, 4, 0, 1, FILL(SHRINK), FILL(SHRINK), 0, 0);
  attach(r_button, 2, 3, 1, 2, FILL(SHRINK), FILL(SHRINK), 0, 0);
  attach(ra_button, 3, 4, 1, 2, FILL(SHRINK), FILL(SHRINK), 0, 0);
  attach(match_case, 4, 5, 0, 1, FILL(SHRINK), FILL(SHRINK), 5, 0);
  attach(whole_word, 4, 5, 1, 2, FILL(SHRINK), FILL(SHRINK), 5, 0);
  attach(lua_pattern, 5, 6, 0, 1, FILL(SHRINK), FILL(SHRINK), 5, 0);
  attach(in_files, 5, 6, 1, 2, FILL(SHRINK), FILL(SHRINK), 5, 0);

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

  return findbox;
}

/** Signal for the "Enter" key being pressed in the Command Entry. */
static void c_activate(GtkWidget*_, void*__) {
  lL_event(lua, "command_entry_keypress", LUA_TNUMBER, GDK_Return, -1);
}

/** Signal for a keypress inside the Command Entry. */
static int c_keypress(GtkWidget*_, GdkEventKey *event, void*__) {
  // If "Enter" is pressed by itself, pass it to the entry completion.
  if (event->keyval == GDK_Return && event->state == 0) return FALSE;
  return lL_event(lua, "command_entry_keypress", LUA_TNUMBER, event->keyval,
                  event_mod(SHIFT), event_mod(CONTROL), event_mod(MOD1),
                  event_mod(META), -1);
}

/** Emit "Escape" key to the command entry on focus lost. */
static int c_focusout(GtkWidget*_, GdkEvent *__, void*___) {
  lL_event(lua, "command_entry_keypress", LUA_TNUMBER, GDK_Escape, -1);
  return FALSE;
}

/**
 * Replaces the current word (consisting of alphanumeric and underscore
 * characters) with the match text.
 */
static int cc_matchselected(GtkEntryCompletion*_, GtkTreeModel *model,
                                 GtkTreeIter *iter, void*__) {
  const char *text = gtk_entry_get_text(GTK_ENTRY(command_entry)), *p, *match;
  p = text + strlen(text) - 1;
  for (; p >= text && (g_ascii_isalnum(*p) || *p == '_'); p--)
    g_signal_emit_by_name(G_OBJECT(command_entry), "move-cursor",
                          GTK_MOVEMENT_VISUAL_POSITIONS, -1, TRUE, 0);
  if (p < text + strlen(text) - 1)
    g_signal_emit_by_name(G_OBJECT(command_entry), "backspace", 0); // for undo
  gtk_tree_model_get(model, iter, 0, &match, -1);
  g_signal_emit_by_name(G_OBJECT(command_entry), "insert-at-cursor", match, 0);
  g_free((char *)match);
  gtk_list_store_clear(cc_store);
  return TRUE;
}

/**
 * The match function for the command entry.
 * Since the completion list is filled by Lua, every item is a "match".
 */
static int cc_matchfunc(GtkEntryCompletion*_, const char *__, GtkTreeIter*___,
                        void*____) {return 1;}

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
  const char *icons[] = {"16x16", "32x32", "48x48", "64x64", "128x128"};
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
  gtdialog_set_parent(GTK_WINDOW(window));
  accel = gtk_accel_group_new();

#if (__APPLE__ && !CURSES)
  gtkosx_application_set_use_quartz_accelerators(osxapp, FALSE);
  osx_signal(osxapp, "NSApplicationOpenFile", w_open_osx);
  osx_signal(osxapp, "NSApplicationBlockTermination", w_exit_osx);
  osx_signal(osxapp, "NSApplicationWillTerminate", w_quit_osx);
#endif

  GtkWidget *vbox = gtk_vbox_new(FALSE, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);

  tabbar = gtk_notebook_new();
  signal(tabbar, "switch-page", t_tabchange);
  signal(tabbar, "button-press-event", t_tabbuttonpress);
  gtk_notebook_set_scrollable(GTK_NOTEBOOK(tabbar), TRUE);
  gtk_box_pack_start(GTK_BOX(vbox), tabbar, FALSE, FALSE, 0);
  gtk_widget_set_can_focus(tabbar, FALSE);

  GtkWidget *hbox = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hbox, TRUE, TRUE, 0);

  gtk_box_pack_start(GTK_BOX(hbox), new_view(0), TRUE, TRUE, 0);

  gtk_box_pack_start(GTK_BOX(vbox), new_findbox(), FALSE, FALSE, 5);

  command_entry = gtk_entry_new();
  signal(command_entry, "activate", c_activate);
  signal(command_entry, "key-press-event", c_keypress);
  signal(command_entry, "focus-out-event", c_focusout);
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
  g_object_unref(cc_store);

  GtkWidget *hboxs = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, FALSE, FALSE, 0);

  statusbar[0] = gtk_statusbar_new(), statusbar[1] = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[0]), 0, "");
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar[0]), FALSE);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[0], TRUE, TRUE, 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[1]), 0, "");
  g_object_set(G_OBJECT(statusbar[1]), "width-request", 400, NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], FALSE, FALSE, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar), gtk_widget_hide(tabbar); // hide initially
  gtk_widget_hide(findbox), gtk_widget_hide(command_entry); // hide initially

  dummy_view = scintilla_new();
#elif CURSES
  Scintilla *view = new_view(0);
  wm = wman_create(view, scintilla_get_window(view));
  wman_resize(wm, LINES - 2, COLS, 1, 0);
  dummy_view = scintilla_new(NULL);
#endif
}

#if (CURSES && !_WIN32)
/** Signal for a terminal resize. */
static void resize(int signal) {
  struct winsize win;
  ioctl(0, TIOCGWINSZ, &win);
  resizeterm(win.ws_row, win.ws_col);
  wman_resize(wm, LINES - 2, COLS, 1, 0);
  lL_event(lua, "update_ui", -1);
  refresh_all();
}

/** Replacement for `termkey_waitkey()` that handles asynchronous I/O. */
static TermKeyResult textadept_waitkey(TermKey *tk, TermKeyKey *key) {
  int force = FALSE;
  struct timeval timeout = {0, termkey_get_waittime(tk)};
  while (1) {
    TermKeyResult res = !force ? termkey_getkey(tk, key)
                               : termkey_getkey_force(tk, key);
    if (res != TERMKEY_RES_AGAIN && res != TERMKEY_RES_NONE) return res;
    if (res == TERMKEY_RES_AGAIN) force = TRUE;
    // Wait for input.
    int nfds = lspawn_pushfds(lua);
    fd_set *fds = (fd_set *)lua_touserdata(lua, -1);
    FD_SET(0, fds); // monitor stdin
    if (select(nfds, fds, NULL, NULL, force ? &timeout : NULL) > 0) {
      if (FD_ISSET(0, fds)) termkey_advisereadable(tk);
      if (lspawn_readfds(lua) > 0) refresh_all();
    }
    lua_pop(lua, 1); // fd_set
  }
}
#endif

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
#elif CURSES
#if !_WIN32
  ta_tk = termkey_new(0, 0);
#endif
  setlocale(LC_CTYPE, ""); // for displaying UTF-8 characters properly
  initscr(); // raw()/cbreak() and noecho() are taken care of in libtermkey
  curs_set(0); // disable cursor when Scintilla has focus
#if _WIN32
  raw(), noecho();
#endif
#if NCURSES_REENTRANT
  ESCDELAY = getenv("ESCDELAY") ? atoi(getenv("ESCDELAY")) : 100;
#endif
#endif

  char *last_slash = NULL;
#if __linux__
  textadept_home = malloc(FILENAME_MAX);
  int len = readlink("/proc/self/exe", textadept_home, FILENAME_MAX);
  textadept_home[len] = '\0';
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
#elif _WIN32
  textadept_home = malloc(FILENAME_MAX);
  GetModuleFileName(0, textadept_home, FILENAME_MAX);
  if ((last_slash = strrchr(textadept_home, '\\'))) *last_slash = '\0';
#elif __APPLE__
  char *path = malloc(FILENAME_MAX), *p = NULL;
  uint32_t size = FILENAME_MAX;
  _NSGetExecutablePath(path, &size);
  textadept_home = realpath(path, NULL);
  p = strstr(textadept_home, "MacOS"), strcpy(p, "Resources\0");
  free(path);
#if !CURSES
  osxapp = g_object_new(GTKOSX_TYPE_APPLICATION, NULL);
#endif
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
  textadept_home = malloc(FILENAME_MAX);
  int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1};
  size_t cb = FILENAME_MAX;
  sysctl(mib, 4, textadept_home, &cb, NULL, 0);
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
#endif

#if GTK
#if GLIB_CHECK_VERSION(2,28,0)
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

  setlocale(LC_COLLATE, "C"), setlocale(LC_NUMERIC, "C");
  if (lua = luaL_newstate(), !lL_init(lua, argc, argv, FALSE)) return 1;
  initing = TRUE, new_window(), lL_dofile(lua, "init.lua"), initing = FALSE;
  lL_event(lua, "buffer_new", -1), lL_event(lua, "view_new", -1); // first ones
  lL_event(lua, "initialized", -1);
#if (__APPLE__ && !CURSES)
  gtkosx_application_ready(osxapp);
#endif

#if GTK
#if GLIB_CHECK_VERSION(2,28,0)
    gtk_main();
  } else g_application_run(app, argc, argv);
  g_object_unref(app);
#else
  gtk_main();
#endif
#elif CURSES
  refresh_all();

#if !_WIN32
  stderr = freopen("/dev/null", "w", stderr); // redirect stderr
  // Prevent ^C from generating SIGINT. TERMKEY_FLAG_CTRLC is ineffective since
  // initscr() overrides it.
  struct termios term;
  tcgetattr(0, &term), term.c_lflag &= ~ISIG, tcsetattr(0, TCSANOW, &term);
  // Set terminal resize handler.
  struct sigaction act;
  memset(&act, 0, sizeof(struct sigaction));
  act.sa_handler = resize, sigaction(SIGWINCH, &act, NULL);
#else
  freopen("NUL", "w", stderr); // redirect stderr
  PDC_save_key_modifiers(TRUE);
#endif

  int c = 0;
#if _WIN32
  int keysyms[] = {0,SCK_DOWN,SCK_UP,SCK_LEFT,SCK_RIGHT,SCK_HOME,SCK_BACK,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_DELETE,SCK_INSERT,0,0,0,0,0,0,SCK_NEXT,SCK_PRIOR,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_END};
  int shift_keysyms[] = {SCK_TAB,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_DELETE,0,0,SCK_END,0,0,0,SCK_HOME,SCK_INSERT,0,SCK_LEFT,0,0,0,0,0,0,0,0,SCK_RIGHT,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_UP,SCK_DOWN};
  int ctrl_keysyms[] = {SCK_LEFT,SCK_RIGHT,SCK_PRIOR,SCK_NEXT,SCK_HOME,SCK_END,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_INSERT,0,0,SCK_UP,SCK_DOWN,SCK_TAB,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_BACK,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,SCK_DELETE,0,SCK_RETURN};
  int alt_keysyms[] = {SCK_DELETE,SCK_INSERT,0,0,0,SCK_TAB,'-','=',SCK_HOME,SCK_PRIOR,SCK_NEXT,SCK_END,SCK_UP,SCK_DOWN,SCK_RIGHT,SCK_LEFT,SCK_RETURN,SCK_ESCAPE,'`','[',']',';','\'',',','.','/',SCK_BACK,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'\\'}; // SCK_RETURN, '\\' do not work for me
  while ((c = wgetch(scintilla_get_window(focused_view))) != ERR) {
    if (c < 0x20 && c != 8 && c != 9 && c != 13 && c != 27)
      c = tolower(c ^ 0x40);
    else if (c == 27)
      c = SCK_ESCAPE;
    else if (c >= KEY_MIN && c <= KEY_END && keysyms[c - KEY_MIN])
      c = keysyms[c - KEY_MIN];
    else if (c >= KEY_F(1) && c <= KEY_F(48))
      c = 0xFFBE + (c - KEY_F(1)) % 12; // use GDK keysym values for now
    else if (c >= KEY_BTAB && c <= KEY_SDOWN && shift_keysyms[c - KEY_BTAB])
      c = shift_keysyms[c - KEY_BTAB];
    else if (c >= CTL_LEFT && c <= CTL_ENTER && ctrl_keysyms[c - CTL_LEFT])
      c = ctrl_keysyms[c - CTL_LEFT];
    else if (c >= ALT_DEL && c <= ALT_BSLASH && alt_keysyms[c - ALT_DEL])
      c = alt_keysyms[c - ALT_DEL];
    int shift = PDC_get_key_modifiers() & PDC_KEY_MODIFIER_SHIFT;
    int ctrl = PDC_get_key_modifiers() & PDC_KEY_MODIFIER_CONTROL;
    int alt = PDC_get_key_modifiers() & PDC_KEY_MODIFIER_ALT;
    if (c >= 32 && c <= 127) shift = 0; // do not shift printable keys
#else
  TermKeyResult res;
  TermKeyKey key;
  int keysyms[] = {0,SCK_BACK,SCK_TAB,SCK_RETURN,SCK_ESCAPE,0,SCK_BACK,SCK_UP,SCK_DOWN,SCK_LEFT,SCK_RIGHT,0,0,SCK_INSERT,SCK_DELETE,0,SCK_PRIOR,SCK_NEXT,SCK_HOME,SCK_END};
  while ((res = textadept_waitkey(ta_tk, &key)) != TERMKEY_RES_EOF) {
    if (res == TERMKEY_RES_ERROR) continue;
    if (key.type == TERMKEY_TYPE_UNICODE)
      c = key.code.codepoint;
    else if (key.type == TERMKEY_TYPE_FUNCTION)
      c = 0xFFBD + key.code.number; // use GDK keysym values for now
    else if (key.type == TERMKEY_TYPE_KEYSYM &&
             key.code.sym >= 0 && key.code.sym <= TERMKEY_SYM_END)
      c = keysyms[key.code.sym];
    int shift = key.modifiers & TERMKEY_KEYMOD_SHIFT;
    int ctrl = key.modifiers & TERMKEY_KEYMOD_CTRL;
    int alt = key.modifiers & TERMKEY_KEYMOD_ALT;
#endif
    if (!lL_event(lua, "keypress", LUA_TNUMBER, c, LUA_TBOOLEAN, shift,
                  LUA_TBOOLEAN, ctrl, LUA_TBOOLEAN, alt, -1))
      scintilla_send_key(focused_view, c, shift, ctrl, alt);
    if (quit && lL_event(lua, "quit", -1)) {
      l_close(lua);
      // Free some memory.
      free(flabel), free(rlabel);
      if (find_text) free(find_text);
      if (repl_text) free(repl_text);
      for (int i = 0; i < 10; i++) {
        if (find_store[i]) free(find_store[i]);
        if (repl_store[i]) free(repl_store[i]);
        if (i > 3) continue;
        free(find_options[i] ? option_labels[i] : option_labels[i] - 4);
        free(button_labels[i]);
      }
      break;
    } else quit = FALSE;
    refresh_all();
  }
  endwin();
#if !_WIN32
  termkey_destroy(ta_tk);
#endif
#endif

  free(textadept_home);
}

#if (_WIN32 && !CURSES)
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE _, HINSTANCE __, LPSTR lpCmdLine, int ___) {
  return main(1, &lpCmdLine);
}
#endif

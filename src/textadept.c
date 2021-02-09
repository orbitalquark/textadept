// Copyright 2007-2021 Mitchell. See LICENSE.

#if __linux__
#define _XOPEN_SOURCE 500 // for readlink from unistd.h
#endif

// Library includes.
#include <errno.h>
#include <limits.h> // for MB_LEN_MAX
#include <locale.h>
#include <iconv.h>
#include <math.h> // for fmax
//#include <stdarg.h>
#include <stdbool.h>
//#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if __linux__
//#include <unistd.h>
#elif _WIN32
#include <windows.h>
#include <fcntl.h> // for _open_osfhandle, _O_RDONLY
#define main main_
#elif __APPLE__
#include <mach-o/dyld.h> // for _NSGetExecutablePath
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
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
//#include <sys/select.h>
#include <sys/time.h>
//#include <termios.h>
#else
#undef main
#endif
#include <curses.h>
#endif

// External dependency includes.
#include "gtdialog.h"
//#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "Scintilla.h"
#include "LexLPeg.h"
#if GTK
#include "ScintillaWidget.h"
#elif CURSES
#include "ScintillaCurses.h"
#include "cdk_int.h"
#include "termkey.h"
#endif

#if GTK
typedef GtkWidget Scintilla;
// Translate GTK 2.x API to GTK 3.0 for compatibility.
#if GTK_CHECK_VERSION(3,0,0)
#define gtk_combo_box_entry_new_with_model(m,_) \
  gtk_combo_box_new_with_model_and_entry(m)
#define gtk_combo_box_entry_set_text_column gtk_combo_box_set_entry_text_column
#define GTK_COMBO_BOX_ENTRY GTK_COMBO_BOX
#endif
#if !_WIN32
#define ID "textadept.editor"
#else
#define ID "\\\\.\\pipe\\textadept.editor"
// Win32 single-instance functionality.
#define g_application_command_line_get_arguments(_,__) \
  g_strsplit(buf, "\n", 0); argc = g_strv_length(argv)
#define g_application_command_line_get_cwd(_) argv[0]
#define g_application_register(_,__,___) true
#define g_application_get_is_remote(_) \
  (WaitNamedPipe(ID, NMPWAIT_WAIT_FOREVER) != 0)
#define gtk_main() \
  HANDLE pipe = NULL, thread = NULL; \
  if (!g_application_get_is_remote(app)) \
    pipe = CreateNamedPipe( \
      ID, PIPE_ACCESS_INBOUND, PIPE_WAIT, 1, 0, 0, INFINITE, NULL), \
      thread = CreateThread(NULL, 0, &pipe_listener, pipe, 0, NULL); \
  gtk_main(); \
  if (pipe && thread) \
    TerminateThread(thread, 0), CloseHandle(thread), CloseHandle(pipe);
#endif
#elif CURSES
typedef void Scintilla;
#endif
#define set_metatable(l, n, name, __index, __newindex) \
  if (luaL_newmetatable(l, name)) \
    lua_pushcfunction(l, __index), lua_setfield(l, -2, "__index"), \
      lua_pushcfunction(l, __newindex), lua_setfield(l, -2, "__newindex"); \
  lua_setmetatable(l, n > 0 ? n : n - 1);

static char *textadept_home, *platform;

// User interface objects and related macros for GTK and curses
// interoperability.
static Scintilla *focused_view, *dummy_view, *command_entry;
#if GTK
// GTK window.
static GtkWidget *window, *menubar, *tabbar, *statusbar[2];
static GtkAccelGroup *accel;
#if __APPLE__
static GtkosxApplication *osxapp;
#endif
typedef GtkWidget Pane;
#define SS(view, msg, w, l) scintilla_send_message(SCINTILLA(view), msg, w, l)
#define focus_view(view) gtk_widget_grab_focus(view)
#define scintilla_delete(view) gtk_widget_destroy(view)
// GTK find & replace pane.
static GtkWidget *findbox, *find_entry, *repl_entry, *find_label, *repl_label;
#define find_text gtk_entry_get_text(GTK_ENTRY(find_entry))
#define repl_text gtk_entry_get_text(GTK_ENTRY(repl_entry))
#define set_entry_text(entry, text) gtk_entry_set_text( \
  GTK_ENTRY(entry == find_text ? find_entry : repl_entry), text)
typedef GtkWidget *FindButton;
static FindButton find_next, find_prev, replace, replace_all;
static GtkWidget *match_case, *whole_word, *regex, *in_files;
typedef GtkListStore ListStore;
static ListStore *find_history, *repl_history;
#define checked(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
#define toggle(w, on) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), on)
#define set_label_text(l, t) gtk_label_set_text_with_mnemonic(GTK_LABEL(l), t)
#define set_button_label(b, l) gtk_button_set_label(GTK_BUTTON(b), l)
#define set_option_label(o, _, l) gtk_button_set_label(GTK_BUTTON(o), l)
#define find_active(w) gtk_widget_get_visible(w)
// GTK command entry.
#define command_entry_active gtk_widget_has_focus(command_entry)
#elif CURSES
// curses window.
typedef struct Pane {
  int y, x, rows, cols, split_size; // dimensions
  enum {SINGLE, VSPLIT, HSPLIT} type; // pane type
  WINDOW *win; // either the Scintilla curses window or the split bar's window
  Scintilla *view; // Scintilla view for a non-split view
  struct Pane *child1, *child2; // each pane in a split view
} Pane; // Pane implementation based on code by Chris Emerson.
static Pane *pane;
TermKey *ta_tk; // global for CDK use
#define SS(view, msg, w, l) scintilla_send_message(view, msg, w, l)
#define focus_view(view) ( \
  focused_view ? SS(focused_view, SCI_SETFOCUS, 0, 0) : 0, \
  SS(view, SCI_SETFOCUS, 1, 0))
// curses find & replace pane.
static CDKSCREEN *findbox;
static CDKENTRY *find_entry, *repl_entry, *focused_entry;
static char *find_text, *repl_text, *find_label, *repl_label;
#define set_entry_text(entry, text) copyfree(&entry, text)
typedef enum {find_next, replace, find_prev, replace_all} FindButton;
static bool find_options[4], *match_case = &find_options[0],
  *whole_word = &find_options[1], *regex = &find_options[2],
  *in_files = &find_options[3];
static char *button_labels[4], *option_labels[4];
typedef char *ListStore;
static ListStore find_history[10], repl_history[10];
#define checked(find_option) *find_option
// Use pointer arithmetic to highlight/unhighlight options as necessary.
#define toggle(o, on) do { \
  if (*o != on) *o = on, option_labels[o - match_case] += *o ? -4 : 4; \
} while (false)
#define set_label_text(label, text) copyfree(&label, text)
#define set_button_label(button, label) copyfree(&button_labels[button], label)
// Prepend "</R>" to each option label because pointer arithmetic will be used
// to make the "</R>" visible or invisible (thus highlighting or unhighlighting
// the label) depending on whether or not the option is enabled by the user.
#define set_option_label(option, i, label) do { \
  lua_pushstring(L, "</R>"), lua_pushstring(L, label), lua_concat(L, 2); \
  if (option_labels[i] && !*option) option_labels[i] -= 4; \
  copyfree(&option_labels[i], lua_tostring(L, -1)); \
  if (!*option) option_labels[i] += 4; \
} while (false)
#define find_active(w) (w != NULL)
// Curses command entry and statusbar.
static bool command_entry_active;
int statusbar_length[2];
#endif

// Lua objects.
static lua_State *lua;
#if CURSES
static bool quitting;
#endif
static bool initing, closing, tab_sync, dialog_active;
static int tabs = 1; // int for more options than true/false
#define show_tabs(condition) tabs && (condition || tabs > 1)
enum {SVOID, SINT, SLEN, SINDEX, SCOLOR, SBOOL, SKEYMOD, SSTRING, SSTRINGRET};

// Forward declarations.
static void new_buffer(sptr_t);
static Scintilla *new_view(sptr_t);
static bool init_lua(lua_State *, int, char **, bool);
LUALIB_API int luaopen_lpeg(lua_State *), luaopen_lfs(lua_State *);
LUALIB_API int os_spawn_pushfds(lua_State *), os_spawn_readfds(lua_State *);

/**
 * Emits an event.
 * @param L The Lua state.
 * @param name The event name.
 * @param ... Arguments to pass with the event. Each pair of arguments should be
 *   a Lua type followed by the data value itself. For LUA_TLIGHTUSERDATA and
 *   LUA_TTABLE types, push the data values to the stack and give the value
 *   returned by luaL_ref(); luaL_unref() will be called appropriately. The list
 *   must be terminated with a -1.
 * @return true or false depending on the boolean value returned by the event
 *   handler, if any.
 */
static bool emit(lua_State *L, const char *name, ...) {
  bool ret = false;
  if (lua_getglobal(L, "events") != LUA_TTABLE) return (lua_pop(L, 1), ret);
  if (lua_getfield(L, -1, "emit") != LUA_TFUNCTION) return (lua_pop(L, 2), ret);
  lua_pushstring(L, name);
  int n = 1;
  va_list ap;
  va_start(ap, name);
  for (int type = va_arg(ap, int); type != -1; type = va_arg(ap, int), n++)
    switch (type) {
      case LUA_TBOOLEAN: lua_pushboolean(L, va_arg(ap, int)); break;
      case LUA_TNUMBER: lua_pushinteger(L, va_arg(ap, int)); break;
      case LUA_TSTRING: lua_pushstring(L, va_arg(ap, char *)); break;
      case LUA_TLIGHTUSERDATA: case LUA_TTABLE: {
        sptr_t arg = va_arg(ap, sptr_t);
        lua_rawgeti(L, LUA_REGISTRYINDEX, arg);
        luaL_unref(L, LUA_REGISTRYINDEX, arg);
        break;
      } default: lua_pushnil(L);
    }
  va_end(ap);
  if (lua_pcall(L, n, 1, 0) != LUA_OK) {
    // An error occurred within `events.emit()` itself, not an event handler.
    const char *argv[] = {"--title", "Error", "--text", lua_tostring(L, -1)};
    free(gtdialog(GTDIALOG_TEXTBOX, 4, argv));
    return (lua_pop(L, 2), ret); // result, events
  } else ret = lua_toboolean(L, -1);
  return (lua_pop(L, 2), ret); // result, events
}

#if GTK
/** Processes a remote Textadept's command line arguments. */
static int process(GApplication *_, GApplicationCommandLine *line, void *buf) {
  if (!lua) return 0; // only process argv for secondary/remote instances
  int argc = 0;
  char **argv = g_application_command_line_get_arguments(line, &argc);
  if (argc > 1) {
    lua_newtable(lua);
    lua_pushstring(lua, g_application_command_line_get_cwd(line)),
      lua_rawseti(lua, -2, -1);
    while (--argc) lua_pushstring(lua, argv[argc]), lua_rawseti(lua, -2, argc);
    emit(lua, "command_line", LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
  }
  g_strfreev(argv);
  return (gtk_window_present(GTK_WINDOW(window)), 0);
}
#endif

#if CURSES
/**
 * Copies the given value to the given string after freeing that string's
 * existing value (if any).
 * The given string must be freed when finished.
 * @param s The address of the string to copy value to.
 * @param value String value to copy. It may be freed immediately.
 */
static void copyfree(char **s, const char *value) {
  if (*s) free(*s);
  *s = strcpy(malloc(strlen(value) + 1), value);
}
#endif

/**
 * Adds the given text to the find/replace history list if it is not at the top.
 * @param store The ListStore to add the text to.
 * @param text The text to add.
 */
static void add_to_history(ListStore* store, const char *text) {
#if GTK
  // Note: GtkComboBoxEntry key navigation behaves contrary to command line
  // history navigation. Down cycles from newer to older, and up cycles from
  // older to newer. In order to mimic traditional command line history
  // navigation, append to the list instead of prepending to it.
  int n = gtk_tree_model_iter_n_children(GTK_TREE_MODEL(store), NULL);
  GtkTreeIter iter;
  if (n > 9)
    gtk_tree_model_get_iter_first(GTK_TREE_MODEL(store), &iter),
      gtk_list_store_remove(store, &iter), n--; // keep 10 items
  char *last_text = NULL;
  if (n > 0)
    gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(store), &iter, NULL, n - 1),
      gtk_tree_model_get(GTK_TREE_MODEL(store), &iter, 0, &last_text, -1);
  if (!last_text || strcmp(text, last_text) != 0)
    gtk_list_store_append(store, &iter),
      gtk_list_store_set(store, &iter, 0, text, -1);
  g_free(last_text);
#elif CURSES
  if (!text || (store[0] && strcmp(text, store[0]) == 0)) return;
  if (store[9]) free(store[9]);
  for (int i = 9; i > 0; i--) store[i] = store[i - 1];
  store[0] = NULL, copyfree(&store[0], text);
#endif
}

/** Signal for a find box button click. */
static void find_clicked(FindButton button, void *L) {
  if (find_text && !*find_text) return;
  if (button == find_next || button == find_prev)
    add_to_history(find_history, find_text);
  else
    add_to_history(repl_history, repl_text);
  if (button == find_next || button == find_prev)
    emit(
      L, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN, button == find_next, -1);
  else if (button == replace) {
    emit(L, "replace", LUA_TSTRING, repl_text, -1);
    emit(L, "find", LUA_TSTRING, find_text, LUA_TBOOLEAN, true, -1);
  } else if (button == replace_all)
    emit(L, "replace_all", LUA_TSTRING, find_text, LUA_TSTRING, repl_text, -1);
}

/** `find.find_next()` Lua function. */
static int click_find_next(lua_State *L) {
  return (find_clicked(find_next, L), 0);
}

/** `find.find_prev()` Lua function. */
static int click_find_prev(lua_State *L) {
  return (find_clicked(find_prev, L), 0);
}

/** `find.replace()` Lua function. */
static int click_replace(lua_State *L) {
  return (find_clicked(replace, L), 0);
}

/** `find.replace_all()` Lua function. */
static int click_replace_all(lua_State *L) {
  return (find_clicked(replace_all, L), 0);
}

#if CURSES
/**
 * Redraws an entire pane and its children.
 * @param pane The pane to redraw.
 */
static void refresh_pane(Pane *pane) {
  if (pane->type == VSPLIT) {
    mvwvline(pane->win, 0, 0, 0, pane->rows), wrefresh(pane->win);
    refresh_pane(pane->child1), refresh_pane(pane->child2);
  } else if (pane->type == HSPLIT) {
    mvwhline(pane->win, 0, 0, 0, pane->cols), wrefresh(pane->win);
    refresh_pane(pane->child1), refresh_pane(pane->child2);
  } else scintilla_noutrefresh(pane->view);
}

/** Refreshes the entire screen. */
static void refresh_all() {
  refresh_pane(pane);
  if (command_entry_active) scintilla_noutrefresh(command_entry);
  refresh();
}

/**
 * Signal for Find/Replace entry keypress.
 * For tab keys, toggle through find/replace buttons.
 * For ^N and ^P keys, cycle through find/replace history.
 * For F1-F4 keys, toggle the respective search option.
 * For up and down keys, toggle entry focus.
 * Otherwise, emit events for entry text changes.
 */
static int find_keypress(EObjectType _, void *object, void *data, chtype key) {
  CDKENTRY *entry = (CDKENTRY *)object;
  char *text = getCDKEntryValue(entry);
  if (key == KEY_TAB) {
    CDKBUTTONBOX *box = (CDKBUTTONBOX *)data;
    FindButton button = entry == find_entry ?
      (getCDKButtonboxCurrentButton(box) == find_next ? find_prev : find_next) :
      (getCDKButtonboxCurrentButton(box) == replace ? replace_all : replace);
    setCDKButtonboxCurrentButton(box, button);
    drawCDKButtonbox(box, false), drawCDKEntry(entry, false);
  } else if (key == CDK_PREV || key == CDK_NEXT) {
    ListStore *store = entry == find_entry ? find_history : repl_history;
    int i;
    for (i = 9; i >= 0; i--) if (store[i] && strcmp(store[i], text) == 0) break;
    key == CDK_PREV ? i++ : i--;
    if (i >= 0 && i <= 9 && store[i])
      setCDKEntryValue(entry, store[i]), drawCDKEntry(entry, false);
  } else if (key >= KEY_F(1) && key <= KEY_F(4)) {
    toggle(&find_options[key - KEY_F(1)], !find_options[key - KEY_F(1)]);
    // Redraw the optionbox.
    CDKBUTTONBOX **optionbox = (CDKBUTTONBOX **)data;
    int width = (*optionbox)->boxWidth - 1;
    destroyCDKButtonbox(*optionbox);
    *optionbox = newCDKButtonbox(
      findbox, RIGHT, TOP, 2, width, NULL, 2, 2, option_labels, 4, A_NORMAL,
      false, false);
    drawCDKButtonbox(*optionbox, false);
  } else if (key == KEY_UP || key == KEY_DOWN) {
    focused_entry = entry == find_entry ? repl_entry : find_entry;
    setCDKButtonboxCurrentButton(
      (CDKBUTTONBOX *)data, focused_entry == find_entry ? find_next : replace);
    injectCDKEntry(entry, KEY_ENTER); // exit this entry
  } else if ((!find_text || strcmp(find_text, text) != 0)) {
    copyfree(&find_text, text);
    if (emit(lua, "find_text_changed", -1)) refresh_all();
  }
  return true;
}
#endif

/** `find.focus()` Lua function. */
static int focus_find(lua_State *L) {
#if GTK
  if (!gtk_widget_has_focus(find_entry) && !gtk_widget_has_focus(repl_entry))
    gtk_widget_show(findbox), gtk_widget_grab_focus(find_entry);
  else
    gtk_widget_hide(findbox), gtk_widget_grab_focus(focused_view);
#elif CURSES
  if (findbox) return 0; // already active
  wresize(scintilla_get_window(focused_view), LINES - 4, COLS);
  findbox = initCDKScreen(newwin(2, 0, LINES - 3, 0)), eraseCDKScreen(findbox);
  int b_width = fmax(strlen(button_labels[0]), strlen(button_labels[1])) +
    fmax(strlen(button_labels[2]), strlen(button_labels[3])) + 3;
  int o_width = fmax(strlen(option_labels[0]), strlen(option_labels[1])) +
    fmax(strlen(option_labels[2]), strlen(option_labels[3])) + 3;
  int l_width = fmax(strlen(find_label), strlen(repl_label));
  int e_width = COLS - o_width - b_width - l_width - 1;
  find_entry = newCDKEntry(
    findbox, l_width - strlen(find_label), TOP, NULL, find_label, A_NORMAL, '_',
    vMIXED, e_width, 0, 1024, false, false);
  repl_entry = newCDKEntry(
    findbox, l_width - strlen(repl_label), BOTTOM, NULL, repl_label, A_NORMAL,
    '_', vMIXED, e_width, 0, 1024, false, false);
  CDKBUTTONBOX *buttonbox, *optionbox;
  buttonbox = newCDKButtonbox(
    findbox, COLS - o_width - b_width, TOP, 2, b_width, NULL, 2, 2,
    button_labels, 4, A_REVERSE, false, false);
  optionbox = newCDKButtonbox(
    findbox, RIGHT, TOP, 2, o_width, NULL, 2, 2, option_labels, 4, A_NORMAL,
    false, false);
  // TODO: ideally no #define here.
  #define bind(k, d) (bindCDKObject(vENTRY, find_entry, k, find_keypress, d), \
    bindCDKObject(vENTRY, repl_entry, k, find_keypress, d))
  bind(KEY_TAB, buttonbox), bind(CDK_NEXT, NULL), bind(CDK_PREV, NULL);
  for (int i = 1; i <= 4; i++) bind(KEY_F(i), &optionbox);
  bind(KEY_DOWN, buttonbox), bind(KEY_UP, buttonbox);
  setCDKEntryValue(find_entry, find_text);
  setCDKEntryValue(repl_entry, repl_text);
  setCDKEntryPostProcess(find_entry, find_keypress, NULL);
  char *clipboard = scintilla_get_clipboard(focused_view, NULL);
  GPasteBuffer = copyChar(clipboard); // set the CDK paste buffer
  curs_set(1);
  refreshCDKScreen(findbox), activateCDKEntry(focused_entry = find_entry, NULL);
  while (focused_entry->exitType == vNORMAL ||
         focused_entry->exitType == vNEVER_ACTIVATED) {
    copyfree(&find_text, getCDKEntryValue(find_entry));
    copyfree(&repl_text, getCDKEntryValue(repl_entry));
    if (focused_entry->exitType == vNORMAL)
      find_clicked(getCDKButtonboxCurrentButton(buttonbox), L), refresh_all();
    find_entry->exitType = repl_entry->exitType = vNEVER_ACTIVATED;
    refreshCDKScreen(findbox), activateCDKEntry(focused_entry, NULL);
  }
  curs_set(0);
  // Set Scintilla clipboard with new CDK paste buffer if necessary.
  if (strcmp(clipboard, GPasteBuffer) != 0)
    SS(focused_view, SCI_COPYTEXT, strlen(GPasteBuffer), (sptr_t)GPasteBuffer);
  free(clipboard), free(GPasteBuffer), GPasteBuffer = NULL;
  destroyCDKEntry(find_entry), destroyCDKEntry(repl_entry);
  destroyCDKButtonbox(buttonbox), destroyCDKButtonbox(optionbox);
  delwin(findbox->window), destroyCDKScreen(findbox), findbox = NULL;
  timeout(0), getch(), timeout(-1); // flush potential extra Escape
  wresize(scintilla_get_window(focused_view), LINES - 2, COLS);
#endif
  return 0;
}

/** `find.__index` Lua metamethod. */
static int find_index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    lua_pushstring(L, find_text ? find_text : "");
  else if (strcmp(key, "replace_entry_text") == 0)
    lua_pushstring(L, repl_text ? repl_text : "");
  else if (strcmp(key, "match_case") == 0)
    lua_pushboolean(L, checked(match_case));
  else if (strcmp(key, "whole_word") == 0)
    lua_pushboolean(L, checked(whole_word));
  else if (strcmp(key, "regex") == 0)
    lua_pushboolean(L, checked(regex));
  else if (strcmp(key, "in_files") == 0)
    lua_pushboolean(L, checked(in_files));
  else if (strcmp(key, "active") == 0)
    lua_pushboolean(L, find_active(findbox));
  else
    lua_rawget(L, 1);
  return 1;
}

/** `find.__newindex` Lua metamethod. */
static int find_newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    set_entry_text(find_text, lua_tostring(L, 3));
  else if (strcmp(key, "replace_entry_text") == 0)
    set_entry_text(repl_text, lua_tostring(L, 3));
  else if (strcmp(key, "match_case") == 0)
    toggle(match_case, lua_toboolean(L, -1));
  else if (strcmp(key, "whole_word") == 0)
    toggle(whole_word, lua_toboolean(L, -1));
  else if (strcmp(key, "regex") == 0)
    toggle(regex, lua_toboolean(L, -1));
  else if (strcmp(key, "in_files") == 0)
    toggle(in_files, lua_toboolean(L, -1));
  else if (strcmp(key, "find_label_text") == 0)
    set_label_text(find_label, lua_tostring(L, 3));
  else if (strcmp(key, "replace_label_text") == 0)
    set_label_text(repl_label, lua_tostring(L, 3));
  else if (strcmp(key, "find_next_button_text") == 0)
    set_button_label(find_next, lua_tostring(L, 3));
  else if (strcmp(key, "find_prev_button_text") == 0)
    set_button_label(find_prev, lua_tostring(L, 3));
  else if (strcmp(key, "replace_button_text") == 0)
    set_button_label(replace, lua_tostring(L, 3));
  else if (strcmp(key, "replace_all_button_text") == 0)
    set_button_label(replace_all, lua_tostring(L, 3));
  else if (strcmp(key, "match_case_label_text") == 0)
    set_option_label(match_case, 0, lua_tostring(L, 3));
  else if (strcmp(key, "whole_word_label_text") == 0)
    set_option_label(whole_word, 1, lua_tostring(L, 3));
  else if (strcmp(key, "regex_label_text") == 0)
    set_option_label(regex, 2, lua_tostring(L, 3));
  else if (strcmp(key, "in_files_label_text") == 0)
    set_option_label(in_files, 3, lua_tostring(L, 3));
  else
    lua_rawset(L, 1);
  return 0;
}

/** `command_entry.focus()` Lua function. */
static int focus_command_entry(lua_State *L) {
#if GTK
  if (!gtk_widget_get_visible(command_entry))
    gtk_widget_show(command_entry), gtk_widget_grab_focus(command_entry);
  else
    gtk_widget_hide(command_entry), gtk_widget_grab_focus(focused_view);
#elif CURSES
  command_entry_active = !command_entry_active;
  if (!command_entry_active) SS(command_entry, SCI_SETFOCUS, 0, 0);
  focus_view(command_entry_active ? command_entry : focused_view);
#endif
  return 0;
}

/** Runs the work function passed to `ui.dialogs.progressbar()`. */
static char *work(void *L) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_workf");
  if (lua_pcall(L, 0, 2, 0) == LUA_OK) {
    if (lua_isnil(L, -2)) return (lua_pop(L, 2), NULL); // done
    if (lua_isnil(L, -1)) lua_pushliteral(L, ""), lua_replace(L, -2);
    if (lua_isnumber(L, -2) && lua_isstring(L, -1)) {
      lua_pushliteral(L, " "), lua_insert(L, -2), lua_pushliteral(L, "\n"),
        lua_concat(L, 4); // "num str\n"
      char *input = strcpy(malloc(lua_rawlen(L, -1) + 1), lua_tostring(L, -1));
      return (lua_pop(L, 1), input); // will be freed by gtdialog
    } else lua_pop(L, 2), lua_pushliteral(L, "invalid return values");
  }
  emit(L, "error", LUA_TSTRING, lua_tostring(L, -1), -1);
  return (lua_pop(L, 1), NULL);
}

/** `ui.dialog()` Lua function. */
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
    } else argv[i++] = luaL_checkstring(L, j);
  argv[argc] = NULL;
  char *out;
  dialog_active = true, out = gtdialog(type, argc, argv), dialog_active = false;
  return (lua_pushstring(L, out), free(out), 1);
}

/**
 * Pushes the Scintilla view onto the stack.
 * The view must have previously been added with add_view.
 * @param L The Lua state.
 * @param view The Scintilla view to push.
 * @see add_view
 */
static void lua_pushview(lua_State *L, Scintilla *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views"),
    lua_pushlightuserdata(L, view), lua_gettable(L, -2), lua_replace(L, -2);
}

/**
 * Pushes onto the stack a split view.
 * @param L The Lua state.
 * @param pane The pane of the split to push.
 */
static void lua_pushsplit(lua_State *L, Pane *pane) {
#if GTK
  if (GTK_IS_PANED(pane)) {
    GtkPaned *p = GTK_PANED(pane);
    lua_newtable(L);
    lua_pushsplit(L, gtk_paned_get_child1(p)), lua_rawseti(L, -2, 1);
    lua_pushsplit(L, gtk_paned_get_child2(p)), lua_rawseti(L, -2, 2);
    lua_pushboolean(
      L, gtk_orientable_get_orientation(GTK_ORIENTABLE(pane)) ==
      GTK_ORIENTATION_HORIZONTAL), lua_setfield(L, -2, "vertical");
    lua_pushinteger(L, gtk_paned_get_position(p)), lua_setfield(L, -2, "size");
  } else lua_pushview(L, pane);
#elif CURSES
  if (pane->type != SINGLE) {
    lua_newtable(L);
    lua_pushsplit(L, pane->child1), lua_rawseti(L, -2, 1);
    lua_pushsplit(L, pane->child2), lua_rawseti(L, -2, 2);
    lua_pushboolean(L, pane->type == VSPLIT), lua_setfield(L, -2, "vertical");
    lua_pushinteger(L, pane->split_size), lua_setfield(L, -2, "size");
  } else lua_pushview(L, pane->view);
#endif
}

/** `ui.get_split_table()` Lua function. */
static int get_split_table(lua_State *L) {
#if GTK
  GtkWidget *pane = focused_view;
  while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
    pane = gtk_widget_get_parent(pane);
#endif
  return (lua_pushsplit(L, pane), 1);
}

/**
 * Returns the view at the given acceptable index as a Scintilla view.
 * @param L The Lua state.
 * @param index Stack index of the view.
 * @return Scintilla view
 */
static Scintilla *lua_toview(lua_State *L, int index) {
  Scintilla *view = (lua_getfield(L, index, "widget_pointer"),
    lua_touserdata(L, -1));
  return (lua_pop(L, 1), view); // widget pointer
}

/**
 * Pushes the Scintilla document onto the stack.
 * The document must have previously been added with add_doc.
 * @param L The Lua state.
 * @param doc The document to push.
 * @see add_doc
 */
static void lua_pushdoc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"),
    lua_pushlightuserdata(L, (sptr_t *)doc), lua_gettable(L, -2),
    lua_replace(L, -2);
}

/**
 * Synchronizes the tabbar after switching between Scintilla views or documents.
 */
static void sync_tabbar() {
#if GTK
  int i = (lua_getfield(lua, LUA_REGISTRYINDEX, "ta_buffers"),
    lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)),
    lua_gettable(lua, -2), lua_tointeger(lua, -1) - 1);
  lua_pop(lua, 2); // index and buffers
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  tab_sync = true, gtk_notebook_set_current_page(notebook, i), tab_sync = false;
//#elif CURSES
  // TODO: tabs
#endif
}

/**
 * Returns whether or not the value at the given index has a given metatable.
 * @param L The Lua state.
 * @param index The stack index of the value to test.
 * @param tname The name of the expected metatable.
 */
static bool is_type(lua_State *L, int index, const char *tname) {
  if (!lua_getmetatable(L, index)) return false;
  luaL_getmetatable(L, tname);
  bool has_metatable = lua_rawequal(L, -1, -2);
  return (lua_pop(L, 2), has_metatable); // metatable, metatable
}

/**
 * Checks whether the function argument arg is a Scintilla view and returns
 * this view cast to a Scintilla.
 * @param L The Lua state.
 * @param arg The stack index of the Scintilla view.
 * @return Scintilla view
 */
static Scintilla *luaL_checkview(lua_State *L, int arg) {
  luaL_argcheck(L, is_type(L, arg, "ta_view"), arg, "View expected");
  return lua_toview(L, arg);
}

/**
 * Change focus to the given Scintilla view.
 * Generates 'view_before_switch' and 'view_after_switch' events.
 * @param view The Scintilla view to focus.
 * @param L The Lua state.
 */
static void view_focused(Scintilla *view, lua_State *L) {
  if (!initing && !closing) emit(L, "view_before_switch", -1);
  lua_pushview(L, focused_view = view), lua_setglobal(L, "view"), sync_tabbar();
  lua_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_setglobal(L, "buffer");
  if (!initing && !closing) emit(L, "view_after_switch", -1);
}

/** `ui.goto_view()` Lua function. */
static int goto_view(lua_State *L) {
  if (lua_isnumber(L, 1)) {
    int n = (lua_getfield(L, LUA_REGISTRYINDEX, "ta_views"),
      lua_pushview(L, focused_view), lua_gettable(L, -2),
      lua_tointeger(L, -1)) + lua_tointeger(L, 1);
    if (n > (int)lua_rawlen(L, -2))
      n = 1;
    else if (n < 1)
      n = lua_rawlen(L, -2);
    lua_rawgeti(L, -2, n), lua_replace(L, 1); // index
  }
  Scintilla *view = luaL_checkview(L, 1);
  focus_view(view);
#if GTK
  // ui.dialog() interferes with focus so gtk_widget_grab_focus() does not
  // always work. If this is the case, ensure view_focused() is called.
  if (!gtk_widget_has_focus(view)) view_focused(view, L);
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
static int get_int_field(lua_State *L, int index, int n) {
  int i = (lua_rawgeti(L, index, n), lua_tointeger(L, -1));
  return (lua_pop(L, 1), i); // integer
}

#if GTK
/**
 * Pushes a menu created from the table at the given valid index onto the stack.
 * Consult the LuaDoc for the table format.
 * @param L The Lua state.
 * @param index The stack index of the table to create the menu from.
 * @param f An optional GTK callback function associated with each menu item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 */
static void lua_pushmenu(lua_State *L, int index, GCallback f, bool submenu) {
  GtkWidget *menu = gtk_menu_new(), *submenu_root = NULL;
  if (lua_getfield(L, index, "title") != LUA_TNIL || submenu) { // submenu title
    const char *label = !lua_isnil(L, -1) ? lua_tostring(L, -1) : "no title";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(L, 1); // title
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
    if (lua_rawgeti(L, -1, i) != LUA_TTABLE) continue; // popped on loop
    bool is_submenu = lua_getfield(L, -1, "title") != LUA_TNIL;
    if (lua_pop(L, 1), is_submenu) {
      lua_pushmenu(L, -1, f, true);
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), lua_touserdata(L, -1));
      lua_pop(L, 1); // menu
      continue;
    }
    const char *label = (lua_rawgeti(L, -1, 1), lua_tostring(L, -1));
    if (lua_pop(L, 1), !label) continue;
    // Menu item table is of the form {label, id, key, modifiers}.
    GtkWidget *menu_item = *label ?
      gtk_menu_item_new_with_mnemonic(label) : gtk_separator_menu_item_new();
    if (*label && get_int_field(L, -1, 3) > 0)
      gtk_widget_add_accelerator(
        menu_item, "activate", accel, get_int_field(L, -1, 3),
        get_int_field(L, -1, 4), GTK_ACCEL_VISIBLE);
    g_signal_connect(
      menu_item, "activate", f, (void*)(long)get_int_field(L, -1, 2));
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
  }
  lua_pushlightuserdata(L, !submenu_root ? menu : submenu_root);
}

/** Signal for a menu item click. */
static void menu_clicked(GtkWidget *_, void *id) {
  emit(lua, "menu_clicked", LUA_TNUMBER, (int)(long)id, -1);
}
#endif

/** `ui.menu()` Lua function. */
static int menu(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
#if GTK
  return (lua_pushmenu(L, -1, G_CALLBACK(menu_clicked), false), 1);
#elif CURSES
  return (lua_pushnil(L), 1);
#endif
}

/** `ui.update()` Lua function. */
static int update_ui(lua_State *L) {
#if GTK
  while (gtk_events_pending()) gtk_main_iteration();
#elif (CURSES && !_WIN32)
  struct timeval timeout = {0, 1e5}; // 0.1s
  int nfds = os_spawn_pushfds(L);
  while (select(nfds, lua_touserdata(L, -1), NULL, NULL, &timeout) > 0)
    if (os_spawn_readfds(L) >= 0) refresh_all();
  lua_pop(L, 1); // fd_set
#endif
  return 0;
}

/** `ui.__index` Lua metamethod. */
static int ui_index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "clipboard_text") == 0) {
#if GTK
    char *text = gtk_clipboard_wait_for_text(
      gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    text ? lua_pushstring(L, text) : lua_pushliteral(L, "");
    g_free(text);
#elif CURSES
    int len;
    char *text = scintilla_get_clipboard(focused_view, &len);
    lua_pushlstring(L, text, len), free(text);
#endif
  } else if (strcmp(key, "maximized") == 0) {
#if GTK
    GdkWindowState state = gdk_window_get_state(gtk_widget_get_window(window));
    lua_pushboolean(L, state & GDK_WINDOW_STATE_MAXIMIZED);
#elif CURSES
    lua_pushboolean(L, false);
#endif
  } else if (strcmp(key, "size") == 0) {
    int width, height;
#if GTK
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
#elif CURSES
    width = COLS, height = LINES;
#endif
    lua_newtable(L);
    lua_pushinteger(L, width), lua_rawseti(L, -2, 1);
    lua_pushinteger(L, height), lua_rawseti(L, -2, 2);
  } else if (strcmp(key, "tabs") == 0)
    tabs <= 1 ? lua_pushboolean(L, tabs) : lua_pushinteger(L, tabs);
  else
    lua_rawget(L, 1);
  return 1;
}

static void set_statusbar_text(const char *text, int bar) {
#if GTK
  if (statusbar[bar]) gtk_label_set_text(GTK_LABEL(statusbar[bar]), text);
#elif CURSES
  int start = bar == 0 ? 0 : statusbar_length[0];
  int end = bar == 0 ? COLS - statusbar_length[1] : COLS;
  for (int i = start; i < end; i++) mvaddch(LINES - 1, i, ' '); // clear
  int len = utf8strlen(text);
  mvaddstr(LINES - 1, bar == 0 ? 0 : COLS - len, text), refresh();
  statusbar_length[bar] = len;
#endif
}

/** `ui.__newindex` Lua metatable. */
static int ui_newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0) {
#if GTK
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(L, 3));
#elif CURSES
    for (int i = 0; i < COLS; i++) mvaddch(0, i, ' '); // clear titlebar
    mvaddstr(0, 0, lua_tostring(L, 3)), refresh();
#endif
  } else if (strcmp(key, "clipboard_text") == 0) {
    const char *text = luaL_checkstring(L, 3);
    SS(focused_view, SCI_COPYTEXT, lua_rawlen(L, 3), (sptr_t)text);
  } else if (strcmp(key, "statusbar_text") == 0 ||
             strcmp(key, "buffer_statusbar_text") == 0)
    set_statusbar_text(lua_tostring(L, 3), *key == 's' ? 0 : 1);
  else if (strcmp(key, "menubar") == 0) {
#if GTK
    luaL_argcheck(L, lua_istable(L, 3), 3, "table of menus expected");
    for (size_t i = 1; i <= lua_rawlen(L, 3); lua_pop(L, 1), i++)
      luaL_argcheck(
        L, lua_rawgeti(L, 3, i) == LUA_TLIGHTUSERDATA, 3,
        "table of menus expected"); // popped on loop
    GtkWidget *new_menubar = gtk_menu_bar_new();
    for (size_t i = 1; i <= lua_rawlen(L, 3); lua_pop(L, 1), i++)
      gtk_menu_shell_append(
        GTK_MENU_SHELL(new_menubar),
        (lua_rawgeti(L, 3, i), lua_touserdata(L, -1))); // popped on loop
    GtkWidget *vbox = gtk_widget_get_parent(menubar);
    gtk_container_remove(GTK_CONTAINER(vbox), menubar);
    gtk_box_pack_start(GTK_BOX(vbox), menubar = new_menubar, false, false, 0);
    gtk_box_reorder_child(GTK_BOX(vbox), new_menubar, 0);
    if (lua_rawlen(L, 3) > 0) gtk_widget_show_all(new_menubar);
#if __APPLE__
    gtkosx_application_set_menu_bar(osxapp, GTK_MENU_SHELL(new_menubar));
    gtk_widget_hide(new_menubar); // hide in window
#endif
//#elif CURSES
    // TODO: menus
#endif
  } else if (strcmp(key, "maximized") == 0) {
#if GTK
    lua_toboolean(L, 3) ? gtk_window_maximize(
      GTK_WINDOW(window)) : gtk_window_unmaximize(GTK_WINDOW(window));
#endif
  } else if (strcmp(key, "size") == 0) {
#if GTK
    luaL_argcheck(
      L, lua_istable(L, 3) && lua_rawlen(L, 3) == 2, 3,
      "{width, height} table expected");
    int w = get_int_field(L, 3, 1), h = get_int_field(L, 3, 2);
    if (w > 0 && h > 0) gtk_window_resize(GTK_WINDOW(window), w, h);
#endif
  } else if (strcmp(key, "tabs") == 0) {
    tabs = !lua_isinteger(L, 3) ? lua_toboolean(L, 3) : lua_tointeger(L, 3);
#if GTK
    gtk_widget_set_visible(
      tabbar, show_tabs(gtk_notebook_get_n_pages(GTK_NOTEBOOK(tabbar)) > 1));
//#elif CURSES
    // TODO: tabs
#endif
  } else lua_rawset(L, 1);
  return 0;
}

/**
 * Returns the buffer at the given acceptable index as a Scintilla document.
 * @param L The Lua state.
 * @param index Stack index of the buffer.
 * @return Scintilla document
 */
static sptr_t lua_todoc(lua_State *L, int index) {
  sptr_t doc = (lua_getfield(L, index, "doc_pointer"),
    (sptr_t)lua_touserdata(L, -1));
  return (lua_pop(L, 1), doc); // doc_pointer
}

/**
 * Returns for the Scintilla document at the given index a suitable Scintilla
 * view that can operate on it.
 * For non-global, non-command entry documents, loads that document in
 * `dummy_view` for non-global document use (unless it is already loaded).
 * Raises and error if the value is not a Scintilla document or if the document
 * no longer exists.
 * @param L The Lua state.
 * @param index The stack index of the Scintilla document.
 */
static Scintilla *view_for_doc(lua_State *L, int index) {
  luaL_argcheck(
    L, is_type(L, index, "ta_buffer"), index, "Buffer expected");
  sptr_t doc = lua_todoc(L, index);
  if (doc == SS(focused_view, SCI_GETDOCPOINTER, 0, 0)) return focused_view;
  luaL_argcheck(
    L, (lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"), lua_pushdoc(L, doc),
      lua_gettable(L, -2) != LUA_TNIL), index, "this Buffer does not exist");
  lua_pop(L, 2); // buffer, ta_buffers
  if (doc == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) return command_entry;
  if (doc == SS(dummy_view, SCI_GETDOCPOINTER, 0, 0)) return dummy_view;
  return (SS(dummy_view, SCI_SETDOCPOINTER, 0, doc), dummy_view);
}

/**
 * Switches to a document in the given view.
 * @param L The Lua state.
 * @param view The Scintilla view.
 * @param n Relative or absolute index of the document to switch to. An absolute
 *   n of -1 represents the last document.
 * @param relative Flag indicating whether or not n is relative.
 */
static void goto_doc(lua_State *L, Scintilla *view, int n, bool relative) {
  if (relative && n == 0) return;
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (relative) {
    n = (lua_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(L, -2),
      lua_tointeger(L, -1)) + n;
    if (n > (int)lua_rawlen(L, -2))
      n = 1;
    else if (n < 1)
      n = lua_rawlen(L, -2);
    lua_rawgeti(L, -2, n), lua_replace(L, -2); // index
  } else lua_rawgeti(L, -1, n > 0 ? n : (int)lua_rawlen(L, -1));
  luaL_argcheck(L, !lua_isnil(L, -1), 2, "no Buffer exists at that index");
  sptr_t doc = lua_todoc(L, -1);
  SS(view, SCI_SETDOCPOINTER, 0, doc), sync_tabbar();
  lua_setglobal(L, "buffer");
  lua_pop(L, 1); // buffers
}

/**
 * Adds the command entry's buffer to the 'buffers' registry table at a constant
 * index (0).
 */
static void register_command_entry_doc() {
  sptr_t doc = SS(command_entry, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(lua, LUA_REGISTRYINDEX, "ta_buffers");
  lua_getglobal(lua, "ui"), lua_getfield(lua, -1, "command_entry"),
    lua_replace(lua, -2);
  lua_pushstring(lua, "doc_pointer"), lua_pushlightuserdata(lua, (sptr_t *)doc),
    lua_rawset(lua, -3);
  // t[doc_pointer] = command_entry, t[0] = command_entry, t[command_entry] = 0
  lua_pushlightuserdata(lua, (sptr_t *)doc), lua_pushvalue(lua, -2),
    lua_settable(lua, -4);
  lua_pushvalue(lua, -1), lua_rawseti(lua, -3, 0);
  lua_pushinteger(lua, 0), lua_settable(lua, -3);
  lua_pop(lua, 1); // buffers
}

/**
 * Removes the Scintilla document from the 'buffers' registry table.
 * The document must have been previously added with add_doc.
 * It is removed from any other views showing it first. Therefore, ensure the
 * length of 'buffers' is more than one unless quitting the application.
 * @param L The Lua state.
 * @param doc The Scintilla document to remove.
 * @see add_doc
 */
static void remove_doc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  for (size_t i = 1; i <= lua_rawlen(L, -1); lua_pop(L, 1), i++) {
    Scintilla *view = (lua_rawgeti(L, -1, i), lua_toview(L, -1)); // ^popped
    if (doc == SS(view, SCI_GETDOCPOINTER, 0, 0)) goto_doc(L, view, -1, true);
  }
  lua_pop(L, 1); // views
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  for (size_t i = 1; i <= lua_rawlen(L, -1); i++)
    if (doc != (lua_rawgeti(L, -1, i), lua_todoc(L, -1))) {
      // t[doc_pointer] = buffer, t[#t + 1] = buffer, t[buffer] = #t
      lua_getfield(L, -1, "doc_pointer"), lua_pushvalue(L, -2),
        lua_settable(L, -5);
      lua_pushvalue(L, -1), lua_rawseti(L, -4, lua_rawlen(L, -4) + 1);
      lua_pushinteger(L, lua_rawlen(L, -3)), lua_settable(L, -4);
    } else {
#if GTK
      // Remove the tab from the tabbar.
      gtk_notebook_remove_page(GTK_NOTEBOOK(tabbar), i - 1);
      gtk_widget_set_visible(tabbar, show_tabs(lua_rawlen(L, -2) > 2));
//#elif CURSES
      // TODO: tabs
#endif
      lua_pop(L, 1); // buffer
    }
  lua_pop(L, 1); // buffers
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  register_command_entry_doc();
  lua_setglobal(L, "_BUFFERS");
}

/**
 * Removes the Scintilla buffer from the current Scintilla view.
 * @param doc The Scintilla document.
 * @see remove_doc
 */
static void delete_buffer(sptr_t doc) {
  remove_doc(lua, doc), SS(dummy_view, SCI_SETDOCPOINTER, 0, 0);
  SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

/** `buffer.delete()` Lua function. */
static int delete_buffer_lua(lua_State *L) {
  Scintilla *view = view_for_doc(L, 1);
  luaL_argcheck(L, view != command_entry, 1, "cannot delete command entry");
  sptr_t doc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"), lua_rawlen(L, -1) == 1)
    new_buffer(0);
  if (view == focused_view) goto_doc(L, focused_view, -1, true);
  delete_buffer(doc), emit(L, "buffer_deleted", -1);
  if (view == focused_view) emit(L, "buffer_after_switch", -1);
  return 0;
}

/** `_G.buffer_new()` Lua function. */
static int new_buffer_lua(lua_State *L) {
  if (initing) luaL_error(L, "cannot create buffers during initialization");
  new_buffer(0);
  return (lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"),
    lua_rawgeti(L, -1, lua_rawlen(L, -1)), 1);
}

/**
 * Checks whether the function argument arg is the given Scintilla parameter
 * type and returns it cast to the proper type.
 * @param L The Lua state.
 * @param arg The stack index of the Scintilla parameter.
 * @param type The Scintilla type to convert to.
 * @return Scintilla param
 */
static sptr_t luaL_checkscintilla(lua_State *L, int *arg, int type) {
  if (type == SSTRING) return (sptr_t)luaL_checkstring(L, (*arg)++);
  if (type == SBOOL) return lua_toboolean(L, (*arg)++);
  if (type == SINDEX) {
    int i = luaL_checkinteger(L, (*arg)++);
    return i >= 0 ? i - 1 : i; // do not adjust significant values like -1
  }
  return type >= SINT && type <= SKEYMOD ? luaL_checkinteger(L, (*arg)++) : 0;
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
 * @see luaL_checkscintilla
 */
static int call_scintilla(
  lua_State *L, Scintilla *view, int msg, int wtype, int ltype, int rtype,
  int arg)
{
  uptr_t wparam = 0;
  sptr_t lparam = 0, len = 0;
  int params_needed = 2, nresults = 0;
  bool string_return = false;
  char *text = NULL;

  // Even though the SCI_PRIVATELEXERCALL interface has ltype int, the LPeg
  // lexer API uses different types depending on wparam. Modify ltype
  // appropriately. See the LPeg lexer API for more information.
  if (msg == SCI_PRIVATELEXERCALL)
    switch (luaL_checkinteger(L, arg)) {
      case SCI_GETDIRECTFUNCTION: case SCI_SETDOCPOINTER:
      case SCI_CHANGELEXERSTATE:
        ltype = SINT; break;
      case SCI_SETLEXERLANGUAGE: case SCI_LOADLEXERLIBRARY:
        ltype = SSTRING; break;
      case SCI_GETNAMEDSTYLES: ltype = SSTRING, rtype = SINDEX; break;
      default: ltype = SSTRINGRET;
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
    len = SS(view, msg, wparam, 0);
    if (wtype == SLEN) wparam = len;
    text = malloc(len + 1), text[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    lparam = (sptr_t)text;
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

/** `buffer:method()` Lua function. */
static int call_scintilla_lua(lua_State *L) {
  Scintilla *view = focused_view;
  // If optional buffer/view argument is given, check it.
  if (is_type(L, 1, "ta_buffer"))
    view = view_for_doc(L, 1);
  else if (is_type(L, 1, "ta_view"))
    view = lua_toview(L, 1);
  // Interface table is of the form {msg, rtype, wtype, ltype}.
  return call_scintilla(
    L, view, get_int_field(L, lua_upvalueindex(1), 1),
    get_int_field(L, lua_upvalueindex(1), 3),
    get_int_field(L, lua_upvalueindex(1), 4),
    get_int_field(L, lua_upvalueindex(1), 2), lua_istable(L, 1) ? 2 : 1);
}

#if GTK
/**
 * Shows the context menu for a widget based on a mouse event.
 * @param L The Lua state.
 * @param event An optional GTK mouse button event.
 * @param k The ui table field that contains the context menu.
 */
static void show_context_menu(lua_State *L, GdkEventButton *event, char *k) {
  if (lua_getglobal(L, "ui") == LUA_TTABLE) {
    if (lua_getfield(L, -1, k) == LUA_TLIGHTUSERDATA) {
      GtkWidget *menu = lua_touserdata(L, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(
        GTK_MENU(menu), NULL, NULL, NULL, NULL, event ? event->button : 0,
        gdk_event_get_time((GdkEvent *)event));
    }
    lua_pop(L, 2); // ui context menu field, ui
  } else lua_pop(L, 1); // non-table
}

/** Signal for a tab label mouse click. */
static bool tab_clicked(GtkWidget *label, GdkEventButton *event, void *L) {
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  for (int i = 0; i < gtk_notebook_get_n_pages(notebook); i++) {
    GtkWidget *page = gtk_notebook_get_nth_page(notebook, i);
    if (label != gtk_notebook_get_tab_label(notebook, page)) continue;
    emit(
      L, "tab_clicked", LUA_TNUMBER, i + 1, LUA_TNUMBER, event->button,
      LUA_TBOOLEAN, event->state & GDK_SHIFT_MASK,
      LUA_TBOOLEAN, event->state & GDK_CONTROL_MASK,
      LUA_TBOOLEAN, event->state & GDK_MOD1_MASK,
      LUA_TBOOLEAN, event->state & GDK_META_MASK, -1);
    if (event->button == 3) show_context_menu(L, event, "tab_context_menu");
    break;
  }
  return true;
}
#endif

/** `buffer[k].__index` metamethod. */
static int property_index(lua_State *L) {
  Scintilla *view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view")) ?
    view_for_doc(L, -1) : lua_toview(L, -1);
  lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4),
    ltype = SVOID, rtype = get_int_field(L, -1, 3);
  luaL_argcheck(L, msg, 2, "write-only property");
  return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 1);
}

/** `buffer[k].__newindex` metamethod. */
static int property_newindex(lua_State *L) {
  Scintilla *view = (lua_getfield(L, 1, "_self"), !is_type(L, -1, "ta_view")) ?
    view_for_doc(L, -1) : lua_toview(L, -1);
  lua_getfield(L, 1, "_iface"); // {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 4),
    ltype = get_int_field(L, -1, 3), rtype = SVOID;
  luaL_argcheck(L, msg, 3, "read-only property");
  if (ltype == SSTRINGRET) ltype = SSTRING;
  return (call_scintilla(L, view, msg, wtype, ltype, rtype, 2), 0);
}

// Helper function for `buffer_index()` and `view_index()` that gets Scintilla
// properties.
static void get_property(lua_State *L) {
  Scintilla *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) :
    lua_toview(L, 1);
  // Interface table is of the form {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 1), wtype = get_int_field(L, -1, 4),
    ltype = SVOID, rtype = get_int_field(L, -1, 3);
  luaL_argcheck(L, msg || wtype != SVOID, 2, "write-only property");
  if (wtype != SVOID) { // indexible property
    lua_createtable(L, 2, 0);
    lua_pushvalue(L, 1), lua_setfield(L, -2, "_self");
    lua_pushvalue(L, -2), lua_setfield(L, -2, "_iface");
    set_metatable(L, -1, "ta_property", property_index, property_newindex);
  } else call_scintilla(L, view, msg, wtype, ltype, rtype, 2);
}

// Helper function for `buffer_newindex()` and `view_newindex()` that sets
// Scintilla properties.
static void set_property(lua_State *L) {
  Scintilla *view = is_type(L, 1, "ta_buffer") ? view_for_doc(L, 1) :
    lua_toview(L, 1);
  // Interface table is of the form {get_id, set_id, rtype, wtype}.
  int msg = get_int_field(L, -1, 2), wtype = get_int_field(L, -1, 3),
    ltype = get_int_field(L, -1, 4), rtype = SVOID, temp;
  luaL_argcheck(L, msg && ltype == SVOID, 3, "read-only property");
  if (wtype == SSTRING || wtype == SSTRINGRET ||
      msg == SCI_SETMARGINLEFT || msg == SCI_SETMARGINRIGHT)
    temp = wtype != SSTRINGRET ? wtype : SSTRING, wtype = ltype, ltype = temp;
  call_scintilla(L, view, msg, wtype, ltype, rtype, 3);
}

/** `buffer.__index` metamethod. */
static int buffer_index(lua_State *L) {
  if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_functions"), lua_pushvalue(L, 2),
      lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla function, return a callable closure.
    lua_pushcclosure(L, call_scintilla_lua, 1);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"),
           lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, determine if it is an indexible one
    // or not. If so, return a table with the appropriate metatable; otherwise
    // call Scintilla to get the property's value.
    get_property(L);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_constants"),
           lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TNUMBER); // pushed
    // If the key is a Scintilla constant, return its value.
  else if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
           lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    // Return the buffer's tab label.
    lua_getfield(L, 1, "tab_pointer");
#if GTK
    lua_pushstring(
      L, gtk_notebook_get_tab_label_text(GTK_NOTEBOOK(tabbar),
      lua_touserdata(L, -1)));
//#elif CURSES
    // TODO: tabs
#endif
  } else if (strcmp(lua_tostring(L, 2), "active") == 0 &&
             lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0))
    lua_pushboolean(L, command_entry_active);
  else if (strcmp(lua_tostring(L, 2), "height") == 0 &&
             lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    // Return the command entry's pixel height.
#if GTK
    GtkAllocation allocation;
    gtk_widget_get_allocation(command_entry, &allocation);
    lua_pushinteger(L, allocation.height);
#elif CURSES
    lua_pushinteger(L, getmaxy(scintilla_get_window(command_entry)));
#endif
  } else lua_settop(L, 2), lua_rawget(L, 1);
  return 1;
}

/** `buffer.__newindex` metamethod. */
static int buffer_newindex(lua_State *L) {
  if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"), lua_pushvalue(L, 2),
      lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, call Scintilla to set its value.
    // Interface table is of the form {get_id, set_id, rtype, wtype}.
    set_property(L);
  else if (strcmp(lua_tostring(L, 2), "tab_label") == 0 &&
           lua_todoc(L, 1) != SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    // Update the buffer's tab label.
    lua_getfield(L, 1, "tab_pointer");
#if GTK
    GtkWidget *box = gtk_event_box_new();
    gtk_event_box_set_visible_window(GTK_EVENT_BOX(box), false);
    GtkWidget *label = gtk_label_new(luaL_checkstring(L, 3));
    gtk_container_add(GTK_CONTAINER(box), label), gtk_widget_show(label);
    gtk_notebook_set_tab_label(
      GTK_NOTEBOOK(tabbar), lua_touserdata(L, -1), box);
    g_signal_connect(box, "button-press-event", G_CALLBACK(tab_clicked), L);
//#elif CURSES
    // TODO: tabs
#endif
  } else if (strcmp(lua_tostring(L, 2), "height") == 0 &&
             lua_todoc(L, 1) == SS(command_entry, SCI_GETDOCPOINTER, 0, 0)) {
    // Set the command entry's pixel height.
    int height = fmax(
      luaL_checkinteger(L, 3), SS(command_entry, SCI_TEXTHEIGHT, 0, 0));
#if GTK
    GtkWidget *paned = gtk_widget_get_parent(command_entry);
    GtkAllocation allocation;
    gtk_widget_get_allocation(paned, &allocation);
    gtk_widget_set_size_request(command_entry, -1, height);
    gtk_paned_set_position(GTK_PANED(paned), allocation.height - height);
#elif CURSES
    WINDOW *win = scintilla_get_window(command_entry);
    wresize(win, height, COLS), mvwin(win, LINES - 1 - height, 0);
#endif
  } else lua_settop(L, 3), lua_rawset(L, 1);
  return 0;
}

/**
 * Adds a Scintilla document with a metatable to the 'buffers' registry table.
 * @param L The Lua state.
 * @param doc The Scintilla document to add.
 */
static void add_doc(lua_State *L, sptr_t doc) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_newtable(L);
  lua_pushlightuserdata(L, (sptr_t *)doc), lua_setfield(L, -2, "doc_pointer");
#if GTK
  GtkWidget *tab = gtk_vbox_new(false, 0); // placeholder in GtkNotebook
  lua_pushlightuserdata(L, tab), lua_setfield(L, -2, "tab_pointer");
//#elif CURSES
  // TODO: tabs
#endif
  lua_pushcfunction(L, delete_buffer_lua), lua_setfield(L, -2, "delete");
  lua_pushcfunction(L, new_buffer_lua) , lua_setfield(L, -2, "new");
  set_metatable(L, -1, "ta_buffer", buffer_index, buffer_newindex);
  // t[doc_pointer] = buffer, t[#t + 1] = buffer, t[buffer] = #t
  lua_getfield(L, -1, "doc_pointer"), lua_pushvalue(L, -2), lua_settable(L, -4);
  lua_pushvalue(L, -1), lua_rawseti(L, -3, lua_rawlen(L, -3) + 1);
  lua_pushinteger(L, lua_rawlen(L, -2)), lua_settable(L, -3);
  lua_pop(L, 1); // buffers
}

/**
 * Creates a new Scintilla document and adds it to the Lua state.
 * Generates 'buffer_before_switch' and 'buffer_new' events.
 * @param doc Almost always zero, except for the first Scintilla view created,
 *   in which its doc pointer would be given here since it already has a
 *   pre-created buffer.
 * @see add_doc
 */
static void new_buffer(sptr_t doc) {
  if (!doc) {
    emit(lua, "buffer_before_switch", -1);
    add_doc(lua, doc = SS(focused_view, SCI_CREATEDOCUMENT, 0, 0));
    goto_doc(lua, focused_view, -1, false);
  } else add_doc(lua, doc), SS(focused_view, SCI_ADDREFDOCUMENT, 0, doc);
#if GTK
  // Add a tab to the tabbar.
  GtkWidget *tab = (lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)),
    lua_getfield(lua, -1, "tab_pointer"), lua_touserdata(lua, -1));
  tab_sync = true;
  int i = gtk_notebook_append_page(GTK_NOTEBOOK(tabbar), tab, NULL);
  gtk_widget_show(tab), gtk_widget_set_visible(tabbar, show_tabs(i > 0));
  gtk_notebook_set_current_page(GTK_NOTEBOOK(tabbar), i);
  tab_sync = false;
  lua_pop(lua, 2); // tab_pointer and buffer
//#elif CURSES
  // TODO: tabs
#endif
  SS(focused_view, SCI_SETILEXER, 0, (sptr_t)CreateLexer(NULL));
  lua_pushdoc(lua, doc), lua_setglobal(lua, "buffer");
  if (!initing) emit(lua, "buffer_new", -1);
}

/** `_G.quit()` Lua function. */
static int quit(lua_State *L) {
#if GTK
  GdkEventAny event = {GDK_DELETE, gtk_widget_get_window(window), true};
  gdk_event_put((GdkEvent *)&event);
#elif CURSES
  quitting = !emit(L, "quit", -1);
#endif
  return 0;
}

/**
 * Loads and runs the given file.
 * @param L The Lua state.
 * @param filename The file name relative to textadept_home.
 * @return true if there are no errors or false in case of errors.
 */
static bool run_file(lua_State *L, const char *filename) {
  char *file = malloc(strlen(textadept_home) + 1 + strlen(filename) + 1);
  sprintf(file, "%s/%s", textadept_home, filename);
  bool ok = luaL_dofile(L, file) == LUA_OK;
  if (!ok) {
    const char *argv[] = {
      "--title", "Initialization Error", "--text", lua_tostring(L, -1)
    };
    free(gtdialog(GTDIALOG_TEXTBOX, 4, argv));
    lua_settop(L, 0);
  }
  return (free(file), ok);
}

/** `_G.reset()` Lua function. */
static int reset(lua_State *L) {
  int persist_ref = (lua_newtable(L), luaL_ref(L, LUA_REGISTRYINDEX));
  lua_rawgeti(L, LUA_REGISTRYINDEX, persist_ref); // emit will unref
  emit(L, "reset_before", LUA_TTABLE, luaL_ref(L, LUA_REGISTRYINDEX), -1);
  init_lua(L, 0, NULL, true);
  lua_pushview(L, focused_view), lua_setglobal(L, "view");
  lua_pushdoc(L, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)),
    lua_setglobal(L, "buffer");
  lua_pushnil(L), lua_setglobal(L, "arg");
  run_file(L, "init.lua"), emit(L, "initialized", -1);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_arg"), lua_setglobal(L, "arg");
  return (emit(L, "reset_after", LUA_TTABLE, persist_ref, -1), 0);
}

/** Runs the timeout function passed to `_G.timeout()`. */
static int timed_out(void *args) {
  int *refs = args, nargs = 0;
  lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
  while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
  bool ok = lua_pcall(lua, nargs - 1, 1, 0) == LUA_OK, repeat = true;
  if (!ok || !lua_toboolean(lua, -1)) {
    while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
    repeat = false;
    if (!ok) emit(lua, "error", LUA_TSTRING, lua_tostring(lua, -1), -1);
  }
  return (lua_pop(lua, 1), repeat); // result
}

/** `_G.timeout()` Lua function. */
static int add_timeout(lua_State *L) {
#if GTK
  double interval = luaL_checknumber(L, 1);
  luaL_argcheck(L, interval > 0, 1, "interval must be > 0");
  luaL_argcheck(L, lua_isfunction(L, 2), 2, "function expected");
  int n = lua_gettop(L), *refs = (int *)calloc(n, sizeof(int));
  for (int i = 2; i <= n; i++)
    lua_pushvalue(L, i), refs[i - 2] = luaL_ref(L, LUA_REGISTRYINDEX);
  return (g_timeout_add(interval * 1000, timed_out, refs), 0);
#elif CURSES
  return luaL_error(L, "not implemented in this environment");
#endif
}

/** `string.iconv()` Lua function. */
static int iconv_lua(lua_State *L) {
  size_t inbytesleft = 0;
  char *inbuf = (char *)luaL_checklstring(L, 1, &inbytesleft);
  const char *to = luaL_checkstring(L, 2), *from = luaL_checkstring(L, 3);
  iconv_t cd = iconv_open(to, from);
  if (cd == (iconv_t)-1) luaL_error(L, "invalid encoding(s)");
  // Ensure the minimum buffer size can hold a potential output BOM and one
  // multibyte character.
  size_t bufsiz = 4 + (inbytesleft > MB_LEN_MAX ? inbytesleft : MB_LEN_MAX);
  char *outbuf = malloc(bufsiz + 1), *p = outbuf;
  size_t outbytesleft = bufsiz;
  int n = 1; // concat this many converted strings
  while (iconv(cd, &inbuf, &inbytesleft, &p, &outbytesleft) == (size_t)-1)
    if (errno == E2BIG && p - outbuf > 0) {
      // Buffer was too small to store converted string. Push the partially
      // converted string for later concatenation.
      lua_checkstack(L, 2), lua_pushlstring(L, outbuf, p - outbuf), n++;
      p = outbuf, outbytesleft = bufsiz;
    } else free(outbuf), iconv_close(cd), luaL_error(L, "conversion failed");
  lua_pushlstring(L, outbuf, p - outbuf);
  free(outbuf), iconv_close(cd);
  return (lua_concat(L, n), 1);
}

/**
 * Initializes or re-initializes the Lua state.
 * Populates the state with global variables and functions, then runs the
 * 'core/init.lua' script.
 * @param L The Lua state.
 * @param argc The number of command line parameters.
 * @param argv The array of command line parameters.
 * @param reinit Flag indicating whether or not to reinitialize the Lua state.
 * @return true on success, false otherwise.
 */
static bool init_lua(lua_State *L, int argc, char **argv, bool reinit) {
  if (!reinit) {
    lua_newtable(L);
    for (int i = 0; i < argc; i++)
      lua_pushstring(L, argv[i]), lua_rawseti(L, -2, i);
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_arg");
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, "ta_buffers");
    lua_newtable(L), lua_setfield(L, LUA_REGISTRYINDEX, "ta_views");
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
  lua_pushinteger(L, (intptr_t)L), lua_setglobal(L, "_LUA"); // for LPeg lexer
  luaL_openlibs(L);
  luaL_requiref(L, "lpeg", luaopen_lpeg, 1), lua_pop(L, 1);
  luaL_requiref(L, "lfs", luaopen_lfs, 1), lua_pop(L, 1);

  lua_newtable(L);
  lua_newtable(L);
  lua_pushcfunction(L, click_find_next), lua_setfield(L, -2, "find_next");
  lua_pushcfunction(L, click_find_prev), lua_setfield(L, -2, "find_prev");
  lua_pushcfunction(L, click_replace), lua_setfield(L, -2, "replace");
  lua_pushcfunction(L, click_replace_all), lua_setfield(L, -2, "replace_all");
  lua_pushcfunction(L, focus_find), lua_setfield(L, -2, "focus");
  set_metatable(L, -1, "ta_find", find_index, find_newindex);
  lua_setfield(L, -2, "find");
  if (!reinit) {
    lua_newtable(L);
    lua_pushcfunction(L, focus_command_entry), lua_setfield(L, -2, "focus");
    set_metatable(L, -1, "ta_buffer", buffer_index, buffer_newindex);
  } else
    lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"), lua_rawgeti(L, -1, 0),
      lua_replace(L, -2); // _BUFFERS[0] == command_entry
  lua_setfield(L, -2, "command_entry");
  lua_pushcfunction(L, dialog), lua_setfield(L, -2, "dialog");
  lua_pushcfunction(L, get_split_table), lua_setfield(L, -2, "get_split_table");
  lua_pushcfunction(L, goto_view), lua_setfield(L, -2, "goto_view");
  lua_pushcfunction(L, menu), lua_setfield(L, -2, "menu");
  lua_pushcfunction(L, update_ui), lua_setfield(L, -2, "update");
  set_metatable(L, -1, "ta_ui", ui_index, ui_newindex);
  lua_setglobal(L, "ui");

  lua_pushcfunction(L, quit), lua_setglobal(L, "quit");
  lua_pushcfunction(L, reset), lua_setglobal(L, "reset");
  lua_pushcfunction(L, add_timeout), lua_setglobal(L, "timeout");

  lua_getglobal(L, "string"), lua_pushcfunction(L, iconv_lua),
    lua_setfield(L, -2, "iconv"), lua_pop(L, 1);

  lua_getfield(L, LUA_REGISTRYINDEX, "ta_arg"), lua_setglobal(L, "arg");
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"),
    lua_setglobal(L, "_BUFFERS");
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views"), lua_setglobal(L, "_VIEWS");
  lua_pushstring(L, textadept_home), lua_setglobal(L, "_HOME");
  if (platform) lua_pushboolean(L, true), lua_setglobal(L, platform);
#if CURSES
  lua_pushboolean(L, true), lua_setglobal(L, "CURSES");
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

  if (!run_file(L, "core/init.lua")) return (lua_close(L), false);
  lua_getglobal(L, "_SCINTILLA");
  lua_getfield(L, -1, "constants"),
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_constants");
  lua_getfield(L, -1, "functions"),
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_functions");
  lua_getfield(L, -1, "properties"),
    lua_setfield(L, LUA_REGISTRYINDEX, "ta_properties");
  lua_pop(L, 1); // _SCINTILLA
  return true;
}

#if GTK
/** Signal for a Textadept window focus change. */
static bool window_focused(GtkWidget *_, GdkEventFocus *__, void *L) {
  if (!command_entry_active) emit(L, "focus", -1);
  return false;
}

/** Signal for a Textadept keypress. */
static bool window_keypress(GtkWidget *_, GdkEventKey *event, void *__) {
  if (event->keyval != GDK_KEY_Escape || !gtk_widget_get_visible(findbox) ||
      gtk_widget_has_focus(command_entry))
    return false;
  return (gtk_widget_hide(findbox), gtk_widget_grab_focus(focused_view), true);
}
#endif

/**
 * Removes the Scintilla view from the 'views' registry table.
 * The view must have been previously added with add_view.
 * @param L The Lua state.
 * @param view The Scintilla view to remove.
 * @see add_view
 */
static void remove_view(lua_State *L, Scintilla *view) {
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  for (size_t i = 1; i <= lua_rawlen(L, -1); i++) {
    if (view != (lua_rawgeti(L, -1, i), lua_toview(L, -1))) {
      // t[widget_pointer] = view, t[#t + 1] = view, t[view] = #t
      lua_getfield(L, -1, "widget_pointer"), lua_pushvalue(L, -2),
        lua_settable(L, -5);
      lua_pushvalue(L, -1), lua_rawseti(L, -4, lua_rawlen(L, -4) + 1);
      lua_pushinteger(L, lua_rawlen(L, -3)), lua_settable(L, -4);
    } else lua_pop(L, 1); // view
  }
  lua_pop(L, 1); // views
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_setglobal(L, "_VIEWS");
}

/**
 * Removes a Scintilla view.
 * @param view The Scintilla view to remove.
 * @see remove_view
 */
static void delete_view(Scintilla *view) {
  remove_view(lua, view), scintilla_delete(view);
}

/**
 * Removes all Scintilla views from the given pane and deletes them along with
 * the child panes themselves.
 * @param pane The pane to remove Scintilla views from.
 * @see delete_view
 */
static void remove_views_from_pane(Pane *pane) {
#if GTK
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane)),
    *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_views_from_pane(child1) : delete_view(child1);
  GTK_IS_PANED(child2) ? remove_views_from_pane(child2) : delete_view(child2);
#elif CURSES
  if (pane->type == VSPLIT || pane->type == HSPLIT) {
    remove_views_from_pane(pane->child1), remove_views_from_pane(pane->child2);
    delwin(pane->win), pane->win = NULL; // delete split bar
  } else delete_view(pane->view);
  free(pane);
#endif
}

#if CURSES
/**
 * Resizes and repositions a pane.
 * @param pane the pane to resize and move.
 * @param rows The number of rows the pane should show.
 * @param cols The number of columns the pane should show.
 * @param y The y-coordinate to place the pane at.
 * @param x The x-coordinate to place the pane at.
 */
static void resize_pane(Pane *pane, int rows, int cols, int y, int x) {
  if (pane->type == VSPLIT) {
    int ssize = pane->split_size * cols / fmax(pane->cols, 1);
    if (ssize < 1 || ssize >= cols - 1) ssize = ssize < 1 ? 1 : cols - 2;
    pane->split_size = ssize;
    resize_pane(pane->child1, rows, ssize, y, x);
    resize_pane(pane->child2, rows, cols - ssize - 1, y, x + ssize + 1);
    wresize(pane->win, rows, 1), mvwin(pane->win, y, x + ssize); // split bar
  } else if (pane->type == HSPLIT) {
    int ssize = pane->split_size * rows / fmax(pane->rows, 1);
    if (ssize < 1 || ssize >= rows - 1) ssize = ssize < 1 ? 1 : rows - 2;
    pane->split_size = ssize;
    resize_pane(pane->child1, ssize, cols, y, x);
    resize_pane(pane->child2, rows - ssize - 1, cols, y + ssize + 1, x);
    wresize(pane->win, 1, cols), mvwin(pane->win, y + ssize, x); // split bar
  } else wresize(pane->win, rows, cols), mvwin(pane->win, y, x);
  pane->rows = rows, pane->cols = cols, pane->y = y, pane->x = x;
}

/**
 * Helper for unsplitting a view.
 * @param pane The pane that contains the view to unsplit.
 * @param view The view to unsplit.
 * @param parent The parent of pane. Used recursively.
 * @return true if the view can be split and was; false otherwise
 * @see unsplit_view
 */
static bool unsplit_pane(Pane *pane, Scintilla *view, Pane *parent) {
  if (pane->type != SINGLE)
    return unsplit_pane(pane->child1, view, pane) ||
      unsplit_pane(pane->child2, view, pane);
  if (pane->view != view) return false;
  remove_views_from_pane(
    pane == parent->child1 ? parent->child2 : parent->child1);
  delwin(parent->win); // delete split bar
  // Inherit child's properties.
  parent->type = pane->type, parent->split_size = pane->split_size;
  parent->win = pane->win, parent->view = pane->view;
  parent->child1 = pane->child1, parent->child2 = pane->child2;
  free(pane);
  // Update.
  resize_pane(parent, parent->rows, parent->cols, parent->y, parent->x);
  return true;
}
#endif

/**
 * Unsplits the pane the given Scintilla view is in and keeps the view.
 * All views in the other pane are deleted.
 * @param view The Scintilla view to keep when unsplitting.
 * @return true if the view was split; false otherwise
 * @see remove_views_from_pane
 * @see delete_view
 */
static bool unsplit_view(Scintilla *view) {
#if GTK
  GtkWidget *pane = gtk_widget_get_parent(view);
  if (!GTK_IS_PANED(pane)) return false;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane)) != view ?
    gtk_paned_get_child1(GTK_PANED(pane)) :
    gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(view), g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), view);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_views_from_pane(other) : delete_view(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent))
    !gtk_paned_get_child1(GTK_PANED(parent)) ?
      gtk_paned_add1(GTK_PANED(parent), view) :
      gtk_paned_add2(GTK_PANED(parent), view);
  else
    gtk_container_add(GTK_CONTAINER(parent), view);
  //gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(view));
  g_object_unref(view), g_object_unref(other);
#elif CURSES
  if (pane->type == SINGLE) return false;
  unsplit_pane(pane, view, NULL), scintilla_noutrefresh(view);
#endif
  return true;
}

/**
 * Closes the Lua state.
 * Unsplits and destroys all Scintilla views and removes all Scintilla
 * documents, before closing the state.
 * @param L The Lua state.
 */
static void close_lua(lua_State *L) {
  closing = true;
  while (unsplit_view(focused_view)) ; // need space to fix compiler warning
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  for (size_t i = 1; i <= lua_rawlen(L, -1); i++)
    lua_rawgeti(L, -1, i), delete_buffer(lua_todoc(L, -1)), lua_pop(L, 1);
  lua_pop(L, 1); // buffers
  scintilla_delete(focused_view), scintilla_delete(dummy_view);
  scintilla_delete(command_entry);
  lua_close(L);
}

#if GTK
/**
 * Signal for exiting Textadept.
 * Generates a 'quit' event.
 * Closes the Lua state and releases resources.
 * @see close_lua
 */
static bool exiting(GtkWidget *_, GdkEventAny *__, void *L) {
  if (emit(L, "quit", -1)) return true; // halt
  close_lua(L);
  scintilla_release_resources();
  return (gtk_main_quit(), false);
}

#if (__APPLE__ && !CURSES)
/**
 * Signal for opening files from macOS.
 * Generates an 'appleevent_odoc' event for each document sent.
 */
static bool open_file(GtkosxApplication*_, char *path, void *L) {
  return (emit(L, "appleevent_odoc", LUA_TSTRING, path, -1), true);
}

/**
 * Signal for block terminating Textadept from macOS.
 * Generates a 'quit' event.
 */
static bool terminating(GtkosxApplication *_, void *L) {
  return emit(L, "quit", -1);
}

/**
 * Signal for terminating Textadept from macOS.
 * Closes the Lua state and releases resources.
 * @see close_lua
 */
static void terminate(GtkosxApplication *_, void *L) {
  close_lua(L);
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
static void tab_changed(GtkNotebook *_, GtkWidget *__, int tab_num, void *L) {
  if (!tab_sync)
    emit(L, "tab_clicked", LUA_TNUMBER, tab_num + 1, LUA_TNUMBER, 1, -1);
}
#endif // if GTK

/**
 * Emits a Scintilla notification event.
 * @param L The Lua state.
 * @param n The Scintilla notification struct.
 * @see emit
 */
static void emit_notification(lua_State *L, SCNotification *n) {
  lua_newtable(L);
  lua_pushinteger(L, n->nmhdr.code), lua_setfield(L, -2, "code");
  lua_pushinteger(L, n->position + 1), lua_setfield(L, -2, "position");
  lua_pushinteger(L, n->ch), lua_setfield(L, -2, "ch");
  lua_pushinteger(L, n->modifiers), lua_setfield(L, -2, "modifiers");
  lua_pushinteger(L, n->modificationType),
    lua_setfield(L, -2, "modification_type");
  if (n->text)
    lua_pushlstring(L, n->text, n->length ? n->length : strlen(n->text)),
      lua_setfield(L, -2, "text");
  lua_pushinteger(L, n->length), lua_setfield(L, -2, "length");
  lua_pushinteger(L, n->linesAdded), lua_setfield(L, -2, "lines_added");
  //lua_pushinteger(L, n->message), lua_setfield(L, -2, "message");
  //lua_pushinteger(L, n->wParam), lua_setfield(L, -2, "wParam");
  //lua_pushinteger(L, n->lParam), lua_setfield(L, -2, "lParam");
  lua_pushinteger(L, n->line + 1), lua_setfield(L, -2, "line");
  //lua_pushinteger(L, n->foldLevelNow), lua_setfield(L, -2, "fold_level_now");
  //lua_pushinteger(L, n->foldLevelPrev),
  //  lua_setfield(L, -2, "fold_level_prev");
  lua_pushinteger(L, n->margin + 1), lua_setfield(L, -2, "margin");
  lua_pushinteger(L, n->listType), lua_setfield(L, -2, "list_type");
  lua_pushinteger(L, n->x), lua_setfield(L, -2, "x");
  lua_pushinteger(L, n->y), lua_setfield(L, -2, "y");
  //lua_pushinteger(L, n->token), lua_setfield(L, -2, "token");
  //lua_pushinteger(L, n->annotationLinesAdded),
  //  lua_setfield(L, -2, "annotation_lines_added");
  lua_pushinteger(L, n->updated), lua_setfield(L, -2, "updated");
  //lua_pushinteger(L, n->listCompletionMethod),
  //  lua_setfield(L, -2, "list_completion_method");
  //lua_pushinteger(L, n->characterSource),
  //  lua_setfield(L, -2, "character_source");
  emit(L, "SCN", LUA_TTABLE, luaL_ref(L, LUA_REGISTRYINDEX), -1);
}

/** Signal for a Scintilla notification. */
static void notified(Scintilla *view, int _, SCNotification *n, void *L) {
  if (view == command_entry) {
    if (n->nmhdr.code == SCN_MODIFIED &&
        (n->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT)))
      emit(L, "command_text_changed", -1);
  } else if (view == focused_view || n->nmhdr.code == SCN_URIDROPPED) {
    if (view != focused_view) view_focused(view, L);
    emit_notification(L, n);
  } else if (n->nmhdr.code == SCN_FOCUSIN)
    view_focused(view, L);
}

#if GTK
/**
 * Signal for a Scintilla keypress.
 * Note: cannot use bool return value due to modern i686-w64-mingw32-gcc issue.
 */
static int keypress(GtkWidget *_, GdkEventKey *event, void *L) {
  return emit(
    L, "keypress", LUA_TNUMBER, event->keyval,
    LUA_TBOOLEAN, event->state & GDK_SHIFT_MASK,
    LUA_TBOOLEAN, event->state & GDK_CONTROL_MASK,
    LUA_TBOOLEAN, event->state & GDK_MOD1_MASK,
    LUA_TBOOLEAN, event->state & GDK_META_MASK,
    LUA_TBOOLEAN, event->state & GDK_LOCK_MASK, -1);
}

/** Signal for a Scintilla mouse click. */
static bool mouse_clicked(GtkWidget *_, GdkEventButton *event, void *L) {
  if (event->type != GDK_BUTTON_PRESS || event->button != 3) return false;
  return (show_context_menu(L, event, "context_menu"), true);
}
#endif

/** `view.goto_buffer()` Lua function. */
static int goto_doc_lua(lua_State *L) {
  Scintilla *view = luaL_checkview(L, 1), *prev_view = focused_view;
  bool relative = lua_isnumber(L, 2);
  if (!relative) {
    lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers"), lua_pushvalue(L, 2),
      lua_gettable(L, -2), lua_replace(L, 2);
    luaL_argcheck(
      L, lua_isnumber(L, 2), 2, "Buffer or relative index expected");
  }
  // If the indexed view is not currently focused, temporarily focus it so
  // `_G.buffer` in handlers is accurate.
  if (view != focused_view) focus_view(view);
  if (!initing) emit(L, "buffer_before_switch", -1);
  goto_doc(L, view, lua_tointeger(L, 2), relative);
  if (!initing) emit(L, "buffer_after_switch", -1);
  if (focused_view != prev_view) focus_view(prev_view);
  return 0;
}

#if CURSES
/**
 * Creates a new pane that contains a Scintilla view.
 * @param view The Scintilla view to place in the pane.
 */
static Pane *new_pane(Scintilla *view) {
  Pane *p = calloc(1, sizeof(Pane));
  p->type = SINGLE, p->win = scintilla_get_window(view), p->view = view;
  return p;
}

/**
 * Helper for splitting a view.
 * Recursively propagates a split to child panes.
 * @param pane The pane to split.
 * @param vertical Whether to split the pane vertically or horizontally.
 * @param view The first Scintilla view to place in the split view.
 * @param view2 The second Scintilla view to place in the split view.
 * @see split_view
 */
static bool split_pane(
  Pane *pane, bool vertical, Scintilla *view, Scintilla *view2)
{
  if (pane->type != SINGLE)
    return split_pane(pane->child1, vertical, view, view2) ||
      split_pane(pane->child2, vertical, view, view2);
  if (view != pane->view) return false;
  Pane *child1 = new_pane(view), *child2 = new_pane(view2);
  pane->type = vertical ? VSPLIT : HSPLIT;
  pane->child1 = child1, pane->child2 = child2, pane->view = NULL;
  // Resize children and create a split bar.
  if (vertical) {
    pane->split_size = pane->cols / 2;
    resize_pane(child1, pane->rows, pane->split_size, pane->y, pane->x);
    resize_pane(
      child2, pane->rows, pane->cols - pane->split_size - 1, pane->y,
      pane->x + pane->split_size + 1);
    pane->win = newwin(pane->rows, 1, pane->y, pane->x + pane->split_size);
  } else {
    pane->split_size = pane->rows / 2;
    resize_pane(child1, pane->split_size, pane->cols, pane->y, pane->x);
    resize_pane(
      child2, pane->rows - pane->split_size - 1, pane->cols,
      pane->y + pane->split_size + 1, pane->x);
    pane->win = newwin(1, pane->cols, pane->y + pane->split_size, pane->x);
  }
  return (refresh_pane(pane), true);
}
#endif

/**
 * Splits the given Scintilla view into two views.
 * The new view shows the same document as the original one.
 * @param view The Scintilla view to split.
 * @param vertical Flag indicating whether to split the view vertically or
 *   horozontally.
 */
static void split_view(Scintilla *view, bool vertical) {
  sptr_t curdoc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  int first_line = SS(view, SCI_GETFIRSTVISIBLELINE, 0, 0),
    x_offset = SS(view, SCI_GETXOFFSET, 0, 0),
    current_pos = SS(view, SCI_GETCURRENTPOS, 0, 0),
    anchor = SS(view, SCI_GETANCHOR, 0, 0);

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
  split_pane(pane, vertical, view, view2);
#endif
  focus_view(view2);

  SS(view2, SCI_SETSEL, anchor, current_pos);
  SS(view2, SCI_LINESCROLL, first_line - SS(
    view2, SCI_GETFIRSTVISIBLELINE, 0, 0), 0);
  SS(view2, SCI_SETXOFFSET, x_offset, 0);
}

/** `view.split()` Lua function. */
static int split_view_lua(lua_State *L) {
  split_view(luaL_checkview(L, 1), lua_toboolean(L, 2));
  return (lua_pushvalue(L, 1), lua_getglobal(L, "view"), 2); // old, new view
}

/** `view.unsplit()` Lua function. */
static int unsplit_view_lua(lua_State *L) {
  return (lua_pushboolean(L, unsplit_view(luaL_checkview(L, 1))), 1);
}

#if CURSES
/**
 * Searches for the given view and returns its parent pane.
 * @param pane The pane that contains the desired view.
 * @param view The view to get the parent pane of.
 */
static Pane *get_parent_pane(Pane *pane, Scintilla *view) {
  if (pane->type == SINGLE) return NULL;
  if (pane->child1->view == view || pane->child2->view == view) return pane;
  Pane *parent = get_parent_pane(pane->child1, view);
  return parent ? parent : get_parent_pane(pane->child2, view);
}
#endif

/** `view.__index` metamethod. */
static int view_index(lua_State *L) {
  if (strcmp(lua_tostring(L, 2), "buffer") == 0)
    lua_pushdoc(L, SS(lua_toview(L, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (strcmp(lua_tostring(L, 2), "size") == 0) {
    lua_pushnil(L); // default
    Pane *p;
#if GTK
    if (GTK_IS_PANED(p = gtk_widget_get_parent(lua_toview(L, 1))))
      lua_pushinteger(L, gtk_paned_get_position(GTK_PANED(p)));
#elif CURSES
    if ((p = get_parent_pane(pane, lua_toview(L, 1))))
      lua_pushinteger(L, p->split_size);
#endif
  } else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_functions"),
             lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla function, return a callable closure.
    lua_pushcclosure(L, call_scintilla_lua, 1);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"),
           lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TTABLE)
    // If the key is a Scintilla property, determine if it is an indexible one
    // or not. If so, return a table with the appropriate metatable; otherwise
    // call Scintilla to get the property's value.
    get_property(L);
  else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_constants"),
           lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TNUMBER); // pushed
    // If the key is a Scintilla constant, return its value.
  else
    lua_settop(L, 2), lua_rawget(L, 1);
  return 1;
}

/** `view.__newindex` metamethod. */
static int view_newindex(lua_State *L) {
  if (strcmp(lua_tostring(L, 2), "buffer") == 0)
    luaL_argerror(L, 2, "read-only property");
  else if (strcmp(lua_tostring(L, 2), "size") == 0) {
    Pane *p;
#if GTK
    if (GTK_IS_PANED(p = gtk_widget_get_parent(lua_toview(L, 1))))
      gtk_paned_set_position(GTK_PANED(p), fmax(luaL_checkinteger(L, 3), 0));
#elif CURSES
    if ((p = get_parent_pane(pane, lua_toview(L, 1))))
      p->split_size = fmax(luaL_checkinteger(L, 3), 0),
        resize_pane(p, p->rows, p->cols, p->y, p->x);
#endif
  } else if (lua_getfield(L, LUA_REGISTRYINDEX, "ta_properties"),
             lua_pushvalue(L, 2), lua_rawget(L, -2) == LUA_TTABLE)
    set_property(L);
  else
    lua_settop(L, 3), lua_rawset(L, 1);
  return 0;
}

/**
 * Adds the Scintilla view with a metatable to the 'views' registry table.
 * @param L The Lua state.
 * @param view The Scintilla view to add.
 */
static void add_view(lua_State *L, Scintilla *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_newtable(L);
  lua_pushlightuserdata(L, view), lua_setfield(L, -2, "widget_pointer");
  lua_pushcfunction(L, goto_doc_lua), lua_setfield(L, -2, "goto_buffer");
  lua_pushcfunction(L, split_view_lua), lua_setfield(L, -2, "split");
  lua_pushcfunction(L, unsplit_view_lua), lua_setfield(L, -2, "unsplit");
  set_metatable(L, -1, "ta_view", view_index, view_newindex);
  // t[widget_pointer] = view, t[#t + 1] = view, t[view] = #t
  lua_getfield(L, -1, "widget_pointer"), lua_pushvalue(L, -2),
    lua_settable(L, -4);
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
 * @see add_view
 */
static Scintilla *new_view(sptr_t doc) {
#if GTK
  Scintilla *view = scintilla_new();
  gtk_widget_set_size_request(view, 1, 1); // minimum size
  g_signal_connect(view, SCINTILLA_NOTIFY, G_CALLBACK(notified), lua);
  g_signal_connect(view, "key-press-event", G_CALLBACK(keypress), lua);
  g_signal_connect(view, "button-press-event", G_CALLBACK(mouse_clicked), lua);
#elif CURSES
  Scintilla *view = scintilla_new(notified, lua);
#endif
  SS(view, SCI_USEPOPUP, SC_POPUP_NEVER, 0);
  add_view(lua, view);
  lua_pushview(lua, view), lua_setglobal(lua, "view");
  if (doc) SS(view, SCI_SETDOCPOINTER, 0, doc);
  focus_view(view), focused_view = view;
  if (!doc) new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!initing) emit(lua, "view_new", -1);
  return view;
}

#if GTK
/** Signal for a Find/Replace entry keypress. */
static bool find_keypress(GtkWidget *widget, GdkEventKey *event, void *L) {
  if (event->keyval != GDK_KEY_Return) return false;
  FindButton button = (event->state & GDK_SHIFT_MASK) == 0 ?
    (widget == find_entry ? find_next : replace) :
    (widget == find_entry ? find_prev : replace_all);
  return (find_clicked(button, L), true);
}

/**
 * Creates and returns for the findbox a new GtkComboBoxEntry, storing its
 * GtkLabel, GtkEntry, and GtkListStore in the given pointers.
 */
static GtkWidget *new_combo(
  GtkWidget **label, GtkWidget **entry, ListStore **history)
{
  *label = gtk_label_new(""); // localized label text set later via Lua
  *history = gtk_list_store_new(1, G_TYPE_STRING);
  GtkWidget *combo = gtk_combo_box_entry_new_with_model(
    GTK_TREE_MODEL(*history), 0);
  g_object_unref(*history);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(combo), 0);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(combo), false);
  *entry = gtk_bin_get_child(GTK_BIN(combo));
  gtk_entry_set_text(GTK_ENTRY(*entry), " "),
    gtk_entry_set_text(GTK_ENTRY(*entry), ""); // initialize with non-NULL
  PangoFontDescription *font = pango_font_description_new();
  pango_font_description_set_family_static(font, "monospace");
  gtk_widget_modify_font(*entry, font);
  pango_font_description_free(font);
  gtk_label_set_mnemonic_widget(GTK_LABEL(*label), *entry);
  g_signal_connect(*entry, "key-press-event", G_CALLBACK(find_keypress), lua);
  return combo;
}

/** Signal for a Find entry keypress. */
static void find_changed(GtkEditable *_, void *L) {
  emit(L, "find_text_changed", -1);
}

/** Creates and returns a new button for the findbox. */
static GtkWidget *new_button() {
  GtkWidget *button = gtk_button_new_with_mnemonic(""); // localized via Lua
  g_signal_connect(button, "clicked", G_CALLBACK(find_clicked), lua);
  gtk_widget_set_can_focus(button, false);
  return button;
}

/** Creates and returns a new checkbox option for the findbox. */
static GtkWidget *new_option() {
  GtkWidget *option = gtk_check_button_new_with_mnemonic(""); // localized later
  gtk_widget_set_can_focus(option, false);
  return option;
}

/** Creates the Find box. */
static GtkWidget *new_findbox() {
  findbox = gtk_table_new(2, 6, false);

  GtkWidget *find_combo = new_combo(&find_label, &find_entry, &find_history),
    *replace_combo = new_combo(&repl_label, &repl_entry, &repl_history);
  g_signal_connect(
    GTK_EDITABLE(find_entry), "changed", G_CALLBACK(find_changed), lua);
  find_next = new_button(), find_prev = new_button(), replace = new_button(),
    replace_all = new_button(), match_case = new_option(),
    whole_word = new_option(), regex = new_option(), in_files = new_option();

  GtkTable *table = GTK_TABLE(findbox);
  int expand = GTK_FILL | GTK_EXPAND, shrink = GTK_FILL | GTK_SHRINK;
  gtk_table_attach(table, find_label, 0, 1, 0, 1, shrink, shrink, 5, 0);
  gtk_table_attach(table, repl_label, 0, 1, 1, 2, shrink, shrink, 5, 0);
  gtk_table_attach(table, find_combo, 1, 2, 0, 1, expand, shrink, 5, 0);
  gtk_table_attach(table, replace_combo, 1, 2, 1, 2, expand, shrink, 5, 0);
  gtk_table_attach(table, find_next, 2, 3, 0, 1, shrink, shrink, 0, 0);
  gtk_table_attach(table, find_prev, 3, 4, 0, 1, shrink, shrink, 0, 0);
  gtk_table_attach(table, replace, 2, 3, 1, 2, shrink, shrink, 0, 0);
  gtk_table_attach(table, replace_all, 3, 4, 1, 2, shrink, shrink, 0, 0);
  gtk_table_attach(table, match_case, 4, 5, 0, 1, shrink, shrink, 5, 0);
  gtk_table_attach(table, whole_word, 4, 5, 1, 2, shrink, shrink, 5, 0);
  gtk_table_attach(table, regex, 5, 6, 0, 1, shrink, shrink, 5, 0);
  gtk_table_attach(table, in_files, 5, 6, 1, 2, shrink, shrink, 5, 0);

  return findbox;
}

/**
 * Signal for window or command entry focus loss.
 * Emit "Escape" key for the command entry on focus lost unless the window is
 * losing focus or the application is quitting.
 */
static bool focus_lost(GtkWidget *widget, GdkEvent *_, void *L) {
  if (widget == window) {
    if (!dialog_active) emit(L, "unfocus", -1);
    if (command_entry_active) return true; // keep focus if window losing focus
  } else if (!closing)
    emit(L, "keypress", LUA_TNUMBER, GDK_KEY_Escape, -1);
  return false;
}
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
    char icon_file[strlen(textadept_home) + 30];
    sprintf(icon_file, "%s/core/images/ta_%s.png", textadept_home, icons[i]);
    GdkPixbuf *icon = gdk_pixbuf_new_from_file(icon_file, NULL);
    if (icon) icon_list = g_list_prepend(icon_list, icon);
  }
  gtk_window_set_default_icon_list(icon_list);
  g_list_foreach(icon_list, (GFunc)g_object_unref, NULL);
  g_list_free(icon_list);

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_name(window, "textadept");
  gtk_window_set_default_size(GTK_WINDOW(window), 1000, 600);
  g_signal_connect(window, "delete-event", G_CALLBACK(exiting), lua);
  g_signal_connect(window, "focus-in-event", G_CALLBACK(window_focused), lua);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(focus_lost), lua);
  g_signal_connect(
    window, "key-press-event", G_CALLBACK(window_keypress), NULL);
  gtdialog_set_parent(GTK_WINDOW(window));
  accel = gtk_accel_group_new();

#if (__APPLE__ && !CURSES)
  gtkosx_application_set_use_quartz_accelerators(osxapp, false);
  g_signal_connect(osxapp, "NSApplicationOpenFile", G_CALLBACK(open_file), lua);
  g_signal_connect(
    osxapp, "NSApplicationBlockTermination", G_CALLBACK(terminating), lua);
  g_signal_connect(
    osxapp, "NSApplicationWillTerminate", G_CALLBACK(terminate), lua);
#endif

  GtkWidget *vbox = gtk_vbox_new(false, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, false, false, 0);

  tabbar = gtk_notebook_new();
  g_signal_connect(tabbar, "switch-page", G_CALLBACK(tab_changed), lua);
  gtk_notebook_set_scrollable(GTK_NOTEBOOK(tabbar), true);
  gtk_widget_set_can_focus(tabbar, false);
  gtk_box_pack_start(GTK_BOX(vbox), tabbar, false, false, 0);

  GtkWidget *paned = gtk_vpaned_new();
  gtk_box_pack_start(GTK_BOX(vbox), paned, true, true, 0);

  GtkWidget *vboxp = gtk_vbox_new(false, 0);
  gtk_paned_add1(GTK_PANED(paned), vboxp);

  GtkWidget *hbox = gtk_hbox_new(false, 0);
  gtk_box_pack_start(GTK_BOX(vboxp), hbox, true, true, 0);

  gtk_box_pack_start(GTK_BOX(hbox), new_view(0), true, true, 0);
  gtk_widget_grab_focus(focused_view);

  gtk_box_pack_start(GTK_BOX(vboxp), new_findbox(), false, false, 5);

  command_entry = scintilla_new();
  gtk_widget_set_size_request(command_entry, 1, 1);
  g_signal_connect(command_entry, SCINTILLA_NOTIFY, G_CALLBACK(notified), lua);
  g_signal_connect(command_entry, "key-press-event", G_CALLBACK(keypress), lua);
  g_signal_connect(
    command_entry, "focus-out-event", G_CALLBACK(focus_lost), lua);
  gtk_paned_add2(GTK_PANED(paned), command_entry);
  gtk_container_child_set(
    GTK_CONTAINER(paned), command_entry, "shrink", false, NULL);

  GtkWidget *hboxs = gtk_hbox_new(false, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, false, false, 1);

  statusbar[0] = gtk_label_new(NULL), statusbar[1] = gtk_label_new(NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[0], true, true, 5);
  gtk_misc_set_alignment(GTK_MISC(statusbar[0]), 0, 0);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], true, true, 5);
  gtk_misc_set_alignment(GTK_MISC(statusbar[1]), 1, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar), gtk_widget_hide(tabbar),
    gtk_widget_hide(findbox), gtk_widget_hide(command_entry); // hide initially

  dummy_view = scintilla_new();
#elif CURSES
  pane = new_pane(new_view(0)), resize_pane(pane, LINES - 2, COLS, 1, 0);
  command_entry = scintilla_new(notified, lua);
  wresize(scintilla_get_window(command_entry), 1, COLS);
  mvwin(scintilla_get_window(command_entry), LINES - 2, 0);
  dummy_view = scintilla_new(NULL, NULL);
#endif
  SS(command_entry, SCI_SETILEXER, 0, (sptr_t)CreateLexer(NULL));
  register_command_entry_doc();
}

#if GTK && _WIN32
/** Reads and processes a remote Textadept's command line arguments. */
static bool read_pipe(GIOChannel *source, GIOCondition _, HANDLE pipe) {
  char *buf;
  size_t len;
  g_io_channel_read_to_end(source, &buf, &len, NULL);
  for (char *p = buf; p < buf + len - 2; p++) if (!*p) *p = '\n'; // '\0\0' end
  process(NULL, NULL, buf);
  return (g_free(buf), DisconnectNamedPipe(pipe), false);
}

/** Listens for remote Textadept communications. */
static DWORD WINAPI pipe_listener(HANDLE pipe) {
  while (true)
    if (pipe != INVALID_HANDLE_VALUE && ConnectNamedPipe(pipe, NULL)) {
      GIOChannel *channel = g_io_channel_win32_new_fd(
        _open_osfhandle((intptr_t)pipe, _O_RDONLY));
      g_io_add_watch(channel, G_IO_IN, read_pipe, pipe),
        g_io_channel_unref(channel);
    }
  return 0;
}

/** Replacement for `g_application_run()` that handles multiple instances. */
int g_application_run(GApplication *_, int __, char **___) {
  HANDLE pipe = CreateFile(ID, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  char cwd[FILENAME_MAX + 1]; // TODO: is this big enough?
  GetCurrentDirectory(FILENAME_MAX + 1, cwd);
  DWORD len_written;
  WriteFile(pipe, cwd, strlen(cwd) + 1, &len_written, NULL);
  for (int i = 1; i < __argc; i++)
    WriteFile(pipe, __argv[i], strlen(__argv[i]) + 1, &len_written, NULL);
  return (CloseHandle(pipe), 0);
}
#endif

#if CURSES
#if !_WIN32
/**
 * Signal for a terminal suspend, continue, and resize.
 * libtermkey has been patched to enable suspend as well as enable/disable mouse
 * mode (1002).
 */
static void signalled(int signal) {
  if (signal != SIGTSTP) {
    if (signal == SIGCONT) termkey_start(ta_tk);
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    resizeterm(w.ws_row, w.ws_col), resize_pane(pane, LINES - 2, COLS, 1, 0);
    WINDOW *win = scintilla_get_window(command_entry);
    wresize(win, 1, COLS), mvwin(win, LINES - 1 - getmaxy(win), 0);
    if (signal == SIGCONT) emit(lua, "resume", -1);
    emit(lua, "update_ui", LUA_TNUMBER, 0, -1);
  } else if (!emit(lua, "suspend", -1))
    endwin(), termkey_stop(ta_tk), kill(0, SIGSTOP);
  refresh_all();
}
#endif

/** Replacement for `termkey_waitkey()` that handles asynchronous I/O. */
static TermKeyResult textadept_waitkey(TermKey *tk, TermKeyKey *key) {
#if !_WIN32
  bool force = false;
  struct timeval timeout = {0, termkey_get_waittime(tk)};
  while (true) {
    TermKeyResult res = !force ?
      termkey_getkey(tk, key) : termkey_getkey_force(tk, key);
    if (res != TERMKEY_RES_AGAIN && res != TERMKEY_RES_NONE) return res;
    if (res == TERMKEY_RES_AGAIN) force = true;
    // Wait for input.
    int nfds = os_spawn_pushfds(lua);
    fd_set *fds = lua_touserdata(lua, -1);
    FD_SET(0, fds); // monitor stdin
    if (select(nfds, fds, NULL, NULL, force ? &timeout : NULL) > 0) {
      if (FD_ISSET(0, fds)) termkey_advisereadable(tk);
      if (os_spawn_readfds(lua) > 0) refresh_all();
    }
    lua_pop(lua, 1); // fd_set
  }
#else
  // TODO: ideally computation of view would not be done twice.
  Scintilla *view = !command_entry_active ? focused_view : command_entry;
  termkey_set_fd(ta_tk, scintilla_get_window(view));
  mouse_set(ALL_MOUSE_EVENTS); // _popen() and system() change console mode
  return termkey_getkey(tk, key);
#endif
}
#endif

/**
 * Runs Textadept.
 * Initializes the Lua state, creates the user interface, and then runs
 * `core/init.lua` followed by `init.lua`.
 * On Windows, creates a pipe and thread for communication with remote
 * instances.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
#if GTK
  gtk_init(&argc, &argv);
#elif CURSES
  ta_tk = termkey_new(0, 0);
  setlocale(LC_CTYPE, ""); // for displaying UTF-8 characters properly
  initscr(); // raw()/cbreak() and noecho() are taken care of in libtermkey
  curs_set(0); // disable cursor when Scintilla has focus
#if NCURSES_REENTRANT
  ESCDELAY = getenv("ESCDELAY") ? atoi(getenv("ESCDELAY")) : 100;
#endif
#endif

  char *last_slash = NULL;
#if __linux__
  textadept_home = malloc(FILENAME_MAX + 1);
  int len = readlink("/proc/self/exe", textadept_home, FILENAME_MAX + 1);
  textadept_home[len] = '\0';
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
  platform = "LINUX";
#elif _WIN32
  textadept_home = malloc(FILENAME_MAX + 1);
  GetModuleFileName(NULL, textadept_home, FILENAME_MAX + 1);
  if ((last_slash = strrchr(textadept_home, '\\'))) *last_slash = '\0';
  platform = "WIN32";
#elif __APPLE__
  char *path = malloc(FILENAME_MAX + 1), *p = NULL;
  uint32_t size = FILENAME_MAX + 1;
  _NSGetExecutablePath(path, &size);
  textadept_home = realpath(path, NULL);
  p = strstr(textadept_home, "MacOS"), strcpy(p, "Resources\0");
  free(path);
#if !CURSES
  osxapp = g_object_new(GTKOSX_TYPE_APPLICATION, NULL);
  platform = "OSX"; // OSX is only set for GUI version
#endif
#elif (__FreeBSD__ || __NetBSD__ || __OpenBSD__)
  textadept_home = malloc(FILENAME_MAX + 1);
  int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1};
  size_t cb = FILENAME_MAX + 1;
  sysctl(mib, 4, textadept_home, &cb, NULL, 0);
  if ((last_slash = strrchr(textadept_home, '/'))) *last_slash = '\0';
  platform = "BSD";
#endif

#if GTK
  bool force = false;
  for (int i = 0; i < argc; i++)
    if (strcmp("-f", argv[i]) == 0 || strcmp("--force", argv[i]) == 0) {
      force = true;
      break;
    }
  GApplication *app = g_application_new(ID, G_APPLICATION_HANDLES_COMMAND_LINE);
  g_signal_connect(app, "command-line", G_CALLBACK(process), NULL);
  bool registered = g_application_register(app, NULL, NULL);
  if (!registered || !g_application_get_is_remote(app) || force) {
#endif

  setlocale(LC_COLLATE, "C"), setlocale(LC_NUMERIC, "C"); // for Lua
  if (lua = luaL_newstate(), !init_lua(lua, argc, argv, false)) return 1;
  initing = true, new_window(), run_file(lua, "init.lua"), initing = false;
  emit(lua, "buffer_new", -1), emit(lua, "view_new", -1); // first ones
  lua_pushdoc(lua, SS(command_entry, SCI_GETDOCPOINTER, 0, 0)),
    lua_setglobal(lua, "buffer");
  emit(lua, "buffer_new", -1), emit(lua, "view_new", -1); // command entry
  lua_pushdoc(lua, SS(focused_view, SCI_GETDOCPOINTER, 0, 0)),
    lua_setglobal(lua, "buffer");
  emit(lua, "initialized", -1); // ready
#if (__APPLE__ && !CURSES)
  gtkosx_application_ready(osxapp);
#endif

#if GTK
    gtk_main();
  } else g_application_run(app, argc, argv);
  g_object_unref(app);
#elif CURSES
  refresh_all();

#if !_WIN32
  freopen("/dev/null", "w", stderr); // redirect stderr
  // Set terminal suspend, resume, and resize handlers, preventing any signals
  // in them from causing interrupts.
  struct sigaction act;
  memset(&act, 0, sizeof(struct sigaction));
  act.sa_handler = signalled, sigfillset(&act.sa_mask);
  sigaction(SIGTSTP, &act, NULL), sigaction(SIGCONT, &act, NULL),
    sigaction(SIGWINCH, &act, NULL);
#else
  freopen("NUL", "w", stdout), freopen("NUL", "w", stderr); // redirect
#endif

  Scintilla *view = focused_view;
  int ch = 0, event = 0, button = 0, y = 0, x = 0, millis = 0;
  TermKeyResult res;
  TermKeyKey key;
  int keysyms[] = {0,SCK_BACK,SCK_TAB,SCK_RETURN,SCK_ESCAPE,0,SCK_BACK,SCK_UP,SCK_DOWN,SCK_LEFT,SCK_RIGHT,0,0,SCK_INSERT,SCK_DELETE,0,SCK_PRIOR,SCK_NEXT,SCK_HOME,SCK_END};
  while ((ch = 0, res = textadept_waitkey(ta_tk, &key)) != TERMKEY_RES_EOF) {
    if (res == TERMKEY_RES_ERROR) continue;
    if (key.type == TERMKEY_TYPE_UNICODE)
      ch = key.code.codepoint;
    else if (key.type == TERMKEY_TYPE_FUNCTION)
      ch = 0xFFBD + key.code.number; // use GDK keysym values for now
    else if (key.type == TERMKEY_TYPE_KEYSYM &&
             key.code.sym >= 0 && key.code.sym <= TERMKEY_SYM_END)
      ch = keysyms[key.code.sym];
    else if (key.type == TERMKEY_TYPE_UNKNOWN_CSI) {
      long args[16];
      size_t nargs = 16;
      unsigned long cmd;
      termkey_interpret_csi(ta_tk, &key, args, &nargs, &cmd);
      lua_newtable(lua);
      for (size_t i = 0; i < nargs; i++)
        lua_pushinteger(lua, args[i]), lua_rawseti(lua, -2, i + 1);
      emit(lua, "csi", LUA_TNUMBER, cmd, LUA_TTABLE, luaL_ref(
        lua, LUA_REGISTRYINDEX), -1);
    } else if (key.type == TERMKEY_TYPE_MOUSE) {
      termkey_interpret_mouse(
        ta_tk, &key, (TermKeyMouseEvent*)&event, &button, &y, &x), y--, x--;
#if !_WIN32
      struct timeval time = {0, 0};
      gettimeofday(&time, NULL);
      millis = time.tv_sec * 1000 + time.tv_usec / 1000;
#else
      FILETIME time;
      GetSystemTimeAsFileTime(&time);
      ULARGE_INTEGER ticks;
      ticks.LowPart = time.dwLowDateTime, ticks.HighPart = time.dwHighDateTime;
      millis = ticks.QuadPart / 10000; // each tick is a 100-nanosecond interval
#endif
    } else continue; // skip unknown types
    bool shift = key.modifiers & TERMKEY_KEYMOD_SHIFT;
    bool ctrl = key.modifiers & TERMKEY_KEYMOD_CTRL;
    bool alt = key.modifiers & TERMKEY_KEYMOD_ALT;
    if (ch && !emit(
          lua, "keypress", LUA_TNUMBER, ch, LUA_TBOOLEAN, shift,
          LUA_TBOOLEAN, ctrl, LUA_TBOOLEAN, alt, -1))
      scintilla_send_key(view, ch, shift, ctrl, alt);
    else if (!ch && !scintilla_send_mouse(
               view, event, millis, button, y, x, shift, ctrl, alt) &&
             !emit(
               lua, "mouse", LUA_TNUMBER, event, LUA_TNUMBER, button,
               LUA_TNUMBER, y, LUA_TNUMBER, x, LUA_TBOOLEAN, shift,
               LUA_TBOOLEAN, ctrl, LUA_TBOOLEAN, alt, -1))
      // Try again with possibly another view.
      scintilla_send_mouse(
        focused_view, event, millis, button, y, x, shift, ctrl, alt);
    if (quitting) {
      close_lua(lua);
      // Free some memory.
      free(pane), free(find_label), free(repl_label);
      if (find_text) free(find_text);
      if (repl_text) free(repl_text);
      for (int i = 0; i < 10; i++) {
        if (find_history[i]) free(find_history[i]);
        if (repl_history[i]) free(repl_history[i]);
        if (i > 3) continue;
        free(find_options[i] ? option_labels[i] : option_labels[i] - 4);
        free(button_labels[i]);
      }
      break;
    }
    refresh_all();
    view = !command_entry_active ? focused_view : command_entry;
  }
  endwin();
  termkey_destroy(ta_tk);
#endif

  return (free(textadept_home), 0);
}

#if (_WIN32 && !CURSES)
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE _, HINSTANCE __, LPSTR ___, int ____) {
  return main(__argc, __argv); // MSVC extensions
}
#endif

// Copyright 2007-2022 Mitchell. See LICENSE.

#include "textadept.h"

#include "gtdialog.h"
#include "lauxlib.h"
#include "ScintillaWidget.h"

#if _WIN32
#include <windows.h>
#define main main_ // entry point should be WinMain
#endif
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#if __APPLE__
#include <gtkmacintegration/gtkosxapplication.h>
#endif

// Translate GTK 2.x API to GTK 3.0 for compatibility.
#if GTK_CHECK_VERSION(3, 0, 0)
#define gtk_combo_box_entry_new_with_model(m, _) gtk_combo_box_new_with_model_and_entry(m)
#define gtk_combo_box_entry_set_text_column gtk_combo_box_set_entry_text_column
#define GTK_COMBO_BOX_ENTRY GTK_COMBO_BOX
#endif
#if !_WIN32
#define ID "textadept.editor"
#else
#define ID "\\\\.\\pipe\\textadept.editor"
// Win32 single-instance functionality.
#define g_application_command_line_get_arguments(_, __) \
  g_strsplit(buf, "\n", 0); \
  argc = g_strv_length(argv)
#define g_application_command_line_get_cwd(_) argv[0]
#define g_application_register(_, __, ___) true
#define g_application_get_is_remote(_) (WaitNamedPipe(ID, NMPWAIT_WAIT_FOREVER) != 0)
#define gtk_main() \
  HANDLE pipe = NULL, thread = NULL; \
  if (!g_application_get_is_remote(app)) \
    pipe = CreateNamedPipe(ID, PIPE_ACCESS_INBOUND, PIPE_WAIT, 1, 0, 0, INFINITE, NULL), \
    thread = CreateThread(NULL, 0, &pipe_listener, pipe, 0, NULL); \
  gtk_main(); \
  if (pipe && thread) TerminateThread(thread, 0), CloseHandle(thread), CloseHandle(pipe);
#endif

const char *get_platform() { return "GTK"; }

// Window.
static GtkWidget *window, *menubar, *tabbar, *statusbar[2];
static GtkAccelGroup *accel;
#if __APPLE__
static GtkosxApplication *osxapp;
#endif
sptr_t SS(Scintilla *view, int message, uptr_t wparam, sptr_t lparam) {
  return scintilla_send_message(SCINTILLA(view), message, wparam, lparam);
}
void focus_view(Scintilla *view) {
  gtk_widget_grab_focus(view);
  // ui.dialog() interferes with focus so gtk_widget_grab_focus() does not
  // always work. If this is the case, ensure view_focused() is called.
  if (!gtk_widget_has_focus(view)) view_focused(view);
}
void delete_scintilla(Scintilla *view) { gtk_widget_destroy(view); }
// Find & replace pane.
static GtkWidget *findbox, *find_entry, *repl_entry, *find_label, *repl_label;
const char *get_find_text() { return gtk_entry_get_text(GTK_ENTRY(find_entry)); }
const char *get_repl_text() { return gtk_entry_get_text(GTK_ENTRY(repl_entry)); }
void set_find_text(const char *text) { gtk_entry_set_text(GTK_ENTRY(find_entry), text); }
void set_repl_text(const char *text) { gtk_entry_set_text(GTK_ENTRY(repl_entry), text); }
static GtkListStore *find_history, *repl_history;
bool checked(FindOption *option) { return gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option)); }
void toggle(FindOption *option, bool on) {
  gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option), on);
}
void set_find_label(const char *text) {
  gtk_label_set_text_with_mnemonic(GTK_LABEL(find_label), text);
}
void set_repl_label(const char *text) {
  gtk_label_set_text_with_mnemonic(GTK_LABEL(repl_label), text);
}
void set_button_label(FindButton *button, const char *text) {
  gtk_button_set_label(GTK_BUTTON(button), text);
}
void set_option_label(FindOption *option, const char *text) {
  gtk_button_set_label(GTK_BUTTON(option), text);
}
bool find_active() { return gtk_widget_get_visible(findbox); }
// Command entry.
bool is_command_entry_active() { return gtk_widget_has_focus(command_entry); }

// Lua objects.
static bool tab_sync;
static int current_tab;

// Note: GtkComboBoxEntry key navigation behaves contrary to command line history
// navigation. Down cycles from newer to older, and up cycles from older to newer. In order to
// mimic traditional command line history navigation, append to the list instead of prepending
// to it.
static void add_to_history(GtkListStore *store, const char *text) {
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
    gtk_list_store_append(store, &iter), gtk_list_store_set(store, &iter, 0, text, -1);
  g_free(last_text);
}

void add_to_find_history(const char *text) { add_to_history(find_history, text); }
void add_to_repl_history(const char *text) { add_to_history(repl_history, text); }

void focus_find() {
  if (!gtk_widget_has_focus(find_entry) && !gtk_widget_has_focus(repl_entry))
    gtk_widget_show(findbox), gtk_widget_grab_focus(find_entry);
  else
    gtk_widget_hide(findbox), gtk_widget_grab_focus(focused_view);
}

void set_entry_font(const char *name) {
  PangoFontDescription *font = pango_font_description_from_string(name);
  gtk_widget_modify_font(find_entry, font), gtk_widget_modify_font(repl_entry, font);
  pango_font_description_free(font);
}

void focus_command_entry() {
  if (!gtk_widget_get_visible(command_entry))
    gtk_widget_show(command_entry), gtk_widget_grab_focus(command_entry);
  else
    gtk_widget_hide(command_entry), gtk_widget_grab_focus(focused_view);
}

PaneInfo get_pane_info(Pane *pane) {
  PaneInfo info = {GTK_IS_PANED(pane), false, pane, pane, NULL, NULL, 0};
  if (info.is_split) {
    info.vertical =
      gtk_orientable_get_orientation(GTK_ORIENTABLE(pane)) == GTK_ORIENTATION_HORIZONTAL;
    GtkPaned *p = GTK_PANED(pane);
    info.child1 = gtk_paned_get_child1(p), info.child2 = gtk_paned_get_child2(p);
    info.size = gtk_paned_get_position(p);
  }
  return info;
}

Pane *get_top_pane() {
  GtkWidget *pane = focused_view;
  while (GTK_IS_PANED(gtk_widget_get_parent(pane))) pane = gtk_widget_get_parent(pane);
  return pane;
}

void set_tab(int index) {
  tab_sync = true, gtk_notebook_set_current_page(GTK_NOTEBOOK(tabbar), index), tab_sync = false;
}

/** Signal for a menu item click. */
static void menu_clicked(GtkWidget *_, void *id) {
  emit(lua, "menu_clicked", LUA_TNUMBER, (int)(long)id, -1);
}

void *read_menu(lua_State *L, int index) {
  GtkWidget *menu = gtk_menu_new(), *submenu_root = NULL;
  if (lua_getfield(L, index, "title") != LUA_TNIL) { // submenu title
    submenu_root = gtk_menu_item_new_with_mnemonic(lua_tostring(L, -1));
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(L, 1); // title
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
    if (lua_rawgeti(L, -1, i) != LUA_TTABLE) continue; // popped on loop
    bool is_submenu = lua_getfield(L, -1, "title") != LUA_TNIL;
    if (lua_pop(L, 1), is_submenu) {
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), read_menu(L, -1));
      continue;
    }
    const char *label = (lua_rawgeti(L, -1, 1), lua_tostring(L, -1));
    if (lua_pop(L, 1), !label) continue;
    // Menu item table is of the form {label, id, key, modifiers}.
    GtkWidget *menu_item =
      *label ? gtk_menu_item_new_with_mnemonic(label) : gtk_separator_menu_item_new();
    if (*label && get_int_field(L, -1, 3) > 0)
      gtk_widget_add_accelerator(menu_item, "activate", accel, get_int_field(L, -1, 3),
        get_int_field(L, -1, 4), GTK_ACCEL_VISIBLE);
    g_signal_connect(
      menu_item, "activate", G_CALLBACK(menu_clicked), (void *)(long)get_int_field(L, -1, 2));
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
  }
  return !submenu_root ? menu : submenu_root;
}

void popup_menu(void *menu, void *userdata) {
  GdkEventButton *event = (GdkEventButton *)userdata;
  gtk_widget_show_all(menu);
  gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, event ? event->button : 0,
    gdk_event_get_time((GdkEvent *)event));
}

void update_ui() {
#if !__APPLE__
  while (gtk_events_pending()) gtk_main_iteration();
#else
  // The idle event monitor created by os.spawn() on macOS is considered to be a pending event,
  // so use its provided registry key to help determine when there are no longer any non-idle
  // events pending.
  lua_pushboolean(lua, false), lua_setfield(lua, LUA_REGISTRYINDEX, "spawn_procs_polled");
  while (gtk_events_pending()) {
    bool polled =
      (lua_getfield(lua, LUA_REGISTRYINDEX, "spawn_procs_polled"), lua_toboolean(lua, -1));
    if (lua_pop(lua, 1), polled) break;
    gtk_main_iteration();
  }
#endif
}

char *get_clipboard_text(int *len) {
  char *text = gtk_clipboard_wait_for_text(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
  *len = text ? strlen(text) : 0;
  return text;
}

bool is_maximized() {
  return (gdk_window_get_state(gtk_widget_get_window(window)) & GDK_WINDOW_STATE_MAXIMIZED) > 0;
}

void get_size(int *width, int *height) { gtk_window_get_size(GTK_WINDOW(window), width, height); }

void set_statusbar_text(int bar, const char *text) {
  gtk_label_set_text(GTK_LABEL(statusbar[bar]), text);
}

void set_title(const char *title) { gtk_window_set_title(GTK_WINDOW(window), title); }

void set_menubar(lua_State *L, int index) {
#if __APPLE__
  // TODO: gtkosx_application_set_menu_bar does not like being called more than once in an app.
  // Random segfaults will happen after a second reset, even if menubar is g_object_ref/unrefed
  // properly.
  if (lua_getglobal(L, "arg") == LUA_TNIL) return;
#endif
  luaL_argcheck(L, lua_istable(L, index), index, "table of menus expected");
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++)
    luaL_argcheck(L, lua_rawgeti(L, index, i) == LUA_TLIGHTUSERDATA, index,
      "table of menus expected"); // popped on loop
  GtkWidget *new_menubar = gtk_menu_bar_new();
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++)
    gtk_menu_shell_append(GTK_MENU_SHELL(new_menubar),
      (lua_rawgeti(L, index, i), lua_touserdata(L, -1))); // popped on loop
  GtkWidget *vbox = gtk_widget_get_parent(menubar);
  gtk_container_remove(GTK_CONTAINER(vbox), menubar);
  gtk_box_pack_start(GTK_BOX(vbox), menubar = new_menubar, false, false, 0);
  gtk_box_reorder_child(GTK_BOX(vbox), new_menubar, 0);
  if (lua_rawlen(L, index) > 0) gtk_widget_show_all(new_menubar);
#if __APPLE__
  gtkosx_application_set_menu_bar(osxapp, GTK_MENU_SHELL(new_menubar));
  gtk_widget_hide(new_menubar); // hide in window
#endif
}

void set_maximized(bool maximize) {
  maximize ? gtk_window_maximize(GTK_WINDOW(window)) : gtk_window_unmaximize(GTK_WINDOW(window));
}

void set_size(int width, int height) { gtk_window_resize(GTK_WINDOW(window), width, height); }

void show_tabs(bool show) { gtk_widget_set_visible(tabbar, show); }

void remove_tab(int index) { gtk_notebook_remove_page(GTK_NOTEBOOK(tabbar), index); }

// TODO: this doesn't work with event boxes.
const char *get_tab_label(int index) {
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  return gtk_notebook_get_tab_label_text(notebook, gtk_notebook_get_nth_page(notebook, index));
}

int get_command_entry_height() {
  GtkAllocation allocation;
  gtk_widget_get_allocation(command_entry, &allocation);
  return allocation.height;
}

/** Signal for a tab label mouse click. */
static bool tab_clicked(GtkWidget *label, GdkEventButton *event, void *_) {
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  for (int i = 0; i < gtk_notebook_get_n_pages(notebook); i++) {
    GtkWidget *page = gtk_notebook_get_nth_page(notebook, i);
    if (label != gtk_notebook_get_tab_label(notebook, page)) continue;
    emit(lua, "tab_clicked", LUA_TNUMBER, i + 1, LUA_TNUMBER, event->button, LUA_TBOOLEAN,
      event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN, event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
      event->state & GDK_MOD1_MASK, LUA_TBOOLEAN, event->state & GDK_META_MASK, -1);
    if (event->button == 3) show_context_menu("tab_context_menu", event);
    break;
  }
  return true;
}

void set_tab_label(int index, const char *text) {
  GtkWidget *box = gtk_event_box_new();
  gtk_event_box_set_visible_window(GTK_EVENT_BOX(box), false);
  GtkWidget *label = gtk_label_new(text);
  gtk_container_add(GTK_CONTAINER(box), label), gtk_widget_show(label);
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  gtk_notebook_set_tab_label(notebook, gtk_notebook_get_nth_page(notebook, index), box);
  g_signal_connect(box, "button-press-event", G_CALLBACK(tab_clicked), NULL);
}

void set_command_entry_height(int height) {
  GtkWidget *paned = gtk_widget_get_parent(command_entry);
  GtkAllocation allocation;
  gtk_widget_get_allocation(paned, &allocation);
  gtk_widget_set_size_request(command_entry, -1, height);
  gtk_paned_set_position(GTK_PANED(paned), allocation.height - height);
}

void add_tab() {
  GtkWidget *tab = gtk_vbox_new(false, 0); // placeholder in GtkNotebook
  tab_sync = true;
  int i = gtk_notebook_append_page(GTK_NOTEBOOK(tabbar), tab, NULL);
  gtk_widget_show(tab);
  gtk_notebook_set_tab_reorderable(GTK_NOTEBOOK(tabbar), tab, true);
  gtk_notebook_set_current_page(GTK_NOTEBOOK(tabbar), i);
  tab_sync = false;
}

void move_tab(int from, int to) {
  GtkNotebook *notebook = GTK_NOTEBOOK(tabbar);
  gtk_notebook_reorder_child(notebook, gtk_notebook_get_nth_page(notebook, from), current_tab = to);
}

void quit() {
  GdkEventAny event = {GDK_DELETE, gtk_widget_get_window(window), true};
  gdk_event_put((GdkEvent *)&event);
}

static int timed_out(void *f) { return call_timeout_function(f); }

bool add_timeout(double interval, void *f) {
  return (g_timeout_add(interval * 1000, timed_out, f), true);
}

const char *get_charset() {
  const char *charset;
  g_get_charset(&charset);
  return charset;
}

void remove_views(Pane *pane) {
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane)),
            *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_views(child1) : delete_view(child1);
  GTK_IS_PANED(child2) ? remove_views(child2) : delete_view(child2);
}

bool unsplit_view(Scintilla *view) {
  GtkWidget *pane = gtk_widget_get_parent(view);
  if (!GTK_IS_PANED(pane)) return false;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane)) != view ?
    gtk_paned_get_child1(GTK_PANED(pane)) :
    gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(view), g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), view);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_views(other) : delete_view(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent))
    !gtk_paned_get_child1(GTK_PANED(parent)) ? gtk_paned_add1(GTK_PANED(parent), view) :
                                               gtk_paned_add2(GTK_PANED(parent), view);
  else
    gtk_container_add(GTK_CONTAINER(parent), view);
  // gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(view));
  g_object_unref(view), g_object_unref(other);
  return true;
}

Scintilla *split_view(Scintilla *view, bool vertical) {
  GtkAllocation allocation;
  gtk_widget_get_allocation(view, &allocation);
  int middle = (vertical ? allocation.width : allocation.height) / 2;

  GtkWidget *parent = gtk_widget_get_parent(view);
  if (!parent) return NULL; // error on startup (e.g. loading theme or settings)
  GtkWidget *view2 = new_view(SS(view, SCI_GETDOCPOINTER, 0, 0));
  g_object_ref(view);
  gtk_container_remove(GTK_CONTAINER(parent), view);
  GtkWidget *pane = vertical ? gtk_hpaned_new() : gtk_vpaned_new();
  gtk_paned_add1(GTK_PANED(pane), view), gtk_paned_add2(GTK_PANED(pane), view2);
  gtk_container_add(GTK_CONTAINER(parent), pane);
  gtk_paned_set_position(GTK_PANED(pane), middle);
  gtk_widget_show_all(pane);
  g_object_unref(view);

  return (update_ui(), view2); // ensure view2 is painted
}

/**
 * Signal for a Scintilla keypress.
 * Note: cannot use bool return value due to modern i686-w64-mingw32-gcc issue.
 */
static int keypress(GtkWidget *_, GdkEventKey *event, void *__) {
  return emit(lua, "keypress", LUA_TNUMBER, event->keyval, LUA_TBOOLEAN,
    event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN, event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
    event->state & GDK_MOD1_MASK, LUA_TBOOLEAN, event->state & GDK_META_MASK, LUA_TBOOLEAN,
    event->state & GDK_LOCK_MASK, -1);
}

/** Signal for a Scintilla mouse click. */
static bool mouse_clicked(GtkWidget *w, GdkEventButton *event, void *_) {
  if (w == command_entry || event->type != GDK_BUTTON_PRESS || event->button != 3) return false;
  return (show_context_menu("context_menu", event), true);
}

Scintilla *new_scintilla(void (*notified)(Scintilla *, int, SCNotification *, void *)) {
  Scintilla *view = scintilla_new();
  gtk_widget_set_size_request(view, 1, 1); // minimum size
  g_signal_connect(view, SCINTILLA_NOTIFY, G_CALLBACK(notified), NULL);
  g_signal_connect(view, "key-press-event", G_CALLBACK(keypress), NULL);
  g_signal_connect(view, "button-press-event", G_CALLBACK(mouse_clicked), NULL);
  return view;
}

PaneInfo get_pane_info_from_view(Scintilla *view) {
  return get_pane_info(gtk_widget_get_parent(view));
}

void set_pane_size(Pane *pane, int size) { gtk_paned_set_position(GTK_PANED(pane), size); }

/**
 * Signal for exiting Textadept.
 * Generates a 'quit' event.
 */
static bool exiting(GtkWidget *_, GdkEventAny *__, void *___) {
  if (emit(lua, "quit", -1)) return true; // halt
  return (close_textadept(), scintilla_release_resources(), gtk_main_quit(), false);
}

/** Signal for a Textadept window focus change. */
static bool window_focused(GtkWidget *_, GdkEventFocus *__, void *___) {
  if (!is_command_entry_active()) emit(lua, "focus", -1);
  return false;
}

/** Signal for window focus loss. */
static bool focus_lost(GtkWidget *_, GdkEvent *__, void *___) {
  if (!dialog_active) emit(lua, "unfocus", -1);
  return is_command_entry_active(); // keep focus if the window is losing focus
}

/** Signal for a Textadept keypress. */
static bool window_keypress(GtkWidget *_, GdkEventKey *event, void *__) {
  if (event->keyval != GDK_KEY_Escape || !gtk_widget_get_visible(findbox) ||
    gtk_widget_has_focus(command_entry))
    return false;
  return (gtk_widget_hide(findbox), gtk_widget_grab_focus(focused_view), true);
}

#if __APPLE__
/**
 * Signal for opening files from macOS.
 * Generates an 'appleevent_odoc' event for each document sent.
 */
static bool open_file(GtkosxApplication *_, char *path, void *__) {
  return (emit(lua, "appleevent_odoc", LUA_TSTRING, path, -1), true);
}

/**
 * Signal for block terminating Textadept from macOS.
 * Generates a 'quit' event.
 */
static bool terminating(GtkosxApplication *_, void *__) { return emit(lua, "quit", -1); }

/**
 * Signal for terminating Textadept from macOS.
 * Closes the Lua state and releases resources.
 * @see close_textadept
 */
static void terminate(GtkosxApplication *_, void *__) {
  close_textadept(), scintilla_release_resources(), g_object_unref(osxapp), gtk_main_quit();
}
#endif

/**
 * Signal for switching buffer tabs.
 * When triggered by the user (i.e. not synchronizing the tabbar), switches to the specified
 * buffer.
 * Generates 'buffer_before_switch' and 'buffer_after_switch' events.
 */
static void tab_changed(GtkNotebook *_, GtkWidget *__, int tab_num, void *___) {
  current_tab = tab_num;
  if (!tab_sync) emit(lua, "tab_clicked", LUA_TNUMBER, tab_num + 1, LUA_TNUMBER, 1, -1);
}

/** Signal for reordering tabs. */
static void tab_reordered(GtkNotebook *_, GtkWidget *__, int tab_num, void *___) {
  move_buffer(current_tab + 1, tab_num + 1, false);
}

/** Signal for a Find/Replace entry keypress. */
static bool find_keypress(GtkWidget *widget, GdkEventKey *event, void *_) {
  if (event->keyval != GDK_KEY_Return) return false;
  FindButton *button = (event->state & GDK_SHIFT_MASK) == 0 ?
    (widget == find_entry ? find_next : replace) :
    (widget == find_entry ? find_prev : replace_all);
  return (find_clicked(button, NULL), true);
}

/**
 * Creates and returns for the findbox a new GtkComboBoxEntry, storing its GtkLabel, GtkEntry,
 * and GtkListStore in the given pointers.
 */
static GtkWidget *new_combo(GtkWidget **label, GtkWidget **entry, GtkListStore **history) {
  *label = gtk_label_new(""); // localized label text set later via Lua
  *history = gtk_list_store_new(1, G_TYPE_STRING);
  GtkWidget *combo = gtk_combo_box_entry_new_with_model(GTK_TREE_MODEL(*history), 0);
  g_object_unref(*history);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(combo), 0);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(combo), false);
  *entry = gtk_bin_get_child(GTK_BIN(combo));
  gtk_entry_set_text(GTK_ENTRY(*entry), " "),
    gtk_entry_set_text(GTK_ENTRY(*entry), ""); // initialize with non-NULL
  gtk_label_set_mnemonic_widget(GTK_LABEL(*label), *entry);
  g_signal_connect(*entry, "key-press-event", G_CALLBACK(find_keypress), NULL);
  return combo;
}

/** Signal for a Find entry keypress. */
static void find_changed(GtkEditable *_, void *__) { emit(lua, "find_text_changed", -1); }

/** Creates and returns a new button for the findbox. */
static GtkWidget *new_button() {
  GtkWidget *button = gtk_button_new_with_mnemonic(""); // localized via Lua
  g_signal_connect(button, "clicked", G_CALLBACK(find_clicked), NULL);
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
  g_signal_connect(GTK_EDITABLE(find_entry), "changed", G_CALLBACK(find_changed), NULL);
  find_next = new_button(), find_prev = new_button(), replace = new_button(),
  replace_all = new_button(), match_case = new_option(), whole_word = new_option(),
  regex = new_option(), in_files = new_option();

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

void new_window() {
  gtk_window_set_default_icon_name("textadept");

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_name(window, "textadept");
  gtk_window_set_default_size(GTK_WINDOW(window), 1000, 600);
  g_signal_connect(window, "delete-event", G_CALLBACK(exiting), NULL);
  g_signal_connect(window, "focus-in-event", G_CALLBACK(window_focused), NULL);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(focus_lost), NULL);
  g_signal_connect(window, "key-press-event", G_CALLBACK(window_keypress), NULL);
  gtdialog_set_parent(GTK_WINDOW(window));
  accel = gtk_accel_group_new();

#if __APPLE__
  gtkosx_application_set_use_quartz_accelerators(osxapp, false);
  g_signal_connect(osxapp, "NSApplicationOpenFile", G_CALLBACK(open_file), NULL);
  g_signal_connect(osxapp, "NSApplicationBlockTermination", G_CALLBACK(terminating), NULL);
  g_signal_connect(osxapp, "NSApplicationWillTerminate", G_CALLBACK(terminate), NULL);
#endif

  GtkWidget *vbox = gtk_vbox_new(false, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, false, false, 0);

  tabbar = gtk_notebook_new();
  g_signal_connect(tabbar, "switch-page", G_CALLBACK(tab_changed), NULL);
  g_signal_connect(tabbar, "page-reordered", G_CALLBACK(tab_reordered), NULL);
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

  gtk_paned_add2(GTK_PANED(paned), (command_entry = new_scintilla(notified)));
  gtk_container_child_set(GTK_CONTAINER(paned), command_entry, "shrink", false, NULL);

  gtk_box_pack_start(GTK_BOX(vboxp), new_findbox(), false, false, 5);

  GtkWidget *hboxs = gtk_hbox_new(false, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, false, false, 1);

  statusbar[0] = gtk_label_new(NULL), statusbar[1] = gtk_label_new(NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[0], true, true, 5);
  gtk_misc_set_alignment(GTK_MISC(statusbar[0]), 0, 0);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], true, true, 5);
  gtk_misc_set_alignment(GTK_MISC(statusbar[1]), 1, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar), gtk_widget_hide(tabbar), gtk_widget_hide(findbox),
    gtk_widget_hide(command_entry); // hide initially

  dummy_view = scintilla_new();
}

/** Processes a remote Textadept's command line arguments. */
static int process(GApplication *_, GApplicationCommandLine *line, void *buf) {
  if (!lua) return 0; // only process argv for secondary/remote instances
  int argc = 0;
  char **argv = g_application_command_line_get_arguments(line, &argc);
  if (argc > 1) {
    lua_newtable(lua);
    lua_pushstring(lua, g_application_command_line_get_cwd(line)), lua_rawseti(lua, -2, -1);
    while (--argc) lua_pushstring(lua, argv[argc]), lua_rawseti(lua, -2, argc);
    emit(lua, "command_line", LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
  }
  g_strfreev(argv);
  return (gtk_window_present(GTK_WINDOW(window)), 0);
}

#if _WIN32
/** Processes a remote Textadept's command line arguments. */
static int pipe_read(void *buf) { return (process(NULL, NULL, buf), free(buf), false); }

/**
 * Listens for remote Textadept communications and reads command line arguments.
 * Processing can only happen in the GTK main thread because GTK is single-threaded.
 */
static DWORD WINAPI pipe_listener(HANDLE pipe) {
  while (true)
    if (pipe != INVALID_HANDLE_VALUE && ConnectNamedPipe(pipe, NULL)) {
      char *buf = malloc(65536 * sizeof(char)), *p = buf; // arbitrary size
      DWORD len;
      while (ReadFile(pipe, p, buf + 65536 - 1 - p, &len, NULL) && len > 0) p += len;
      for (*p = '\0', len = p - buf - 1, p = buf; p < buf + len; p++)
        if (!*p) *p = '\n'; // but preserve trailing '\0'
      g_idle_add(pipe_read, buf), DisconnectNamedPipe(pipe);
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

/**
 * Runs Textadept.
 * Initializes the Lua state, creates the user interface, and then runs `core/init.lua` followed
 * by `init.lua`. On Windows, creates a pipe and thread for communication with remote instances.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
  gtk_init(&argc, &argv);

  bool force = false;
  for (int i = 0; i < argc; i++)
    if (strcmp("-f", argv[i]) == 0 || strcmp("--force", argv[i]) == 0) {
      force = true;
      break;
    }
  GApplication *app = g_application_new(ID, G_APPLICATION_HANDLES_COMMAND_LINE);
  g_signal_connect(app, "command-line", G_CALLBACK(process), NULL);
  if (!g_application_register(app, NULL, NULL) || !g_application_get_is_remote(app) || force) {
#if __APPLE__
    osxapp = g_object_new(GTKOSX_TYPE_APPLICATION, NULL);
#endif
    if (!init_textadept(argc, argv)) return (close_textadept(), 1);
#if __APPLE__
    gtkosx_application_ready(osxapp);
#endif
    gtk_main();
  } else
    g_application_run(app, argc, argv), close_textadept();
  g_object_unref(app);

  return 0;
}

#if _WIN32
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE _, HINSTANCE __, LPSTR ___, int ____) {
  return main(__argc, __argv); // MSVC extensions
}
#endif

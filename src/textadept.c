// Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>

#define PLAT_GTK 1
#include <Scintilla.h>
#include <SciLexer.h>
#include <ScintillaWidget.h>

#include <gcocoadialog.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#if __WIN32__
#include <windows.h>
#define main main_
#elif __OSX__
#include <Carbon/Carbon.h>
#include "igemacintegration/ige-mac-menu.h"
#elif __BSD__
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

#define gbool gboolean
#define SS(editor, m, w, l) scintilla_send_message(SCINTILLA(editor), m, w, l)
#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)
#define streq(s1, s2) strcmp(s1, s2) == 0
#define l_append(l, i) lua_rawseti(l, i, lua_objlen(l, i) + 1)
#define l_cfunc(l, f, k) { \
  lua_pushcfunction(l, f); \
  lua_setfield(l, -2, k); \
}
#define l_mt(l, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_cfunc(l, i, "__index"); \
    l_cfunc(l, ni, "__newindex"); \
  } \
  lua_setmetatable(l, -2); \
}
#define l_togtkwidget(l, i) (GtkWidget *)lua_touserdata(l, i)

/******************************************************************************/
/***************************** Forward Declarations ***************************/
/******************************************************************************/

// Window
GtkWidget *window, *focused_editor, *menubar, *statusbar[2];
char *textadept_home;

void create_ui();
GtkWidget *new_view(sptr_t);
void new_buffer(GtkWidget *, int, int);

static void s_notification(GtkWidget *, gint, gpointer, gpointer);
static void s_command(GtkWidget *, gint, gpointer, gpointer);
static gbool s_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gbool s_buttonpress(GtkWidget *, GdkEventButton *, gpointer);
static gbool w_focus(GtkWidget *, GdkEventFocus *, gpointer);
static gbool w_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gbool w_exit(GtkWidget *, GdkEventAny *, gpointer);
#if __OSX__
static OSErr w_ae_open(const AppleEvent *, AppleEvent *, long);
static OSErr w_ae_quit(const AppleEvent *, AppleEvent *, long);
#endif

// Find/Replace
GtkWidget *findbox, *find_entry, *replace_entry, *fnext_button, *fprev_button,
          *r_button, *ra_button, *match_case_opt, *whole_word_opt, *lua_opt,
          *in_files_opt;
GtkWidget *find_create_ui();
GtkListStore *find_store, *repl_store;

static void find_button_clicked(GtkWidget *, gpointer);

// Command Entry
GtkWidget *command_entry;
GtkListStore *cc_store;
GtkEntryCompletion *command_entry_completion;

static int cc_match_func(GtkEntryCompletion *, const char *, GtkTreeIter *,
                         gpointer);
static gbool cc_match_selected(GtkEntryCompletion *, GtkTreeModel *,
                               GtkTreeIter *, gpointer);
static void c_activated(GtkWidget *, gpointer);
static gbool c_keypress(GtkWidget *, GdkEventKey *, gpointer);

// Lua
lua_State *lua;
int closing = FALSE;
const char *statusbar_text = "";
static int tVOID = 0, tINT = 1, tLENGTH = 2, /*tPOSITION = 3, tCOLOUR = 4,*/
           tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;

int l_init(int, char **, int);
void l_close();
int l_load_script(const char *);
void l_add_view(GtkWidget *);
void l_remove_view(GtkWidget *);
void l_set_view_global(GtkWidget *);
int  l_add_buffer(sptr_t);
void l_remove_buffer(sptr_t);
void l_goto_buffer(GtkWidget *, int, int);
void l_set_buffer_global(GtkWidget *);
int l_emit_event(const char *, ...);
void l_emit_scnnotification(struct SCNotification *);
void l_gui_popup_context_menu(GdkEventButton *);
// Extra Lua libraries.
LUALIB_API int (luaopen_lpeg) (lua_State *L);
LUALIB_API int (luaopen_lfs) (lua_State *L);

static void clear_table(lua_State *, int);
static int l_buffer_mt_index(lua_State *), l_buffer_mt_newindex(lua_State *),
           l_bufferp_mt_index(lua_State *), l_bufferp_mt_newindex(lua_State *),
           l_view_mt_index(lua_State *), l_view_mt_newindex(lua_State *),
           l_gui_mt_index(lua_State *), l_gui_mt_newindex(lua_State *),
           l_find_mt_index(lua_State *), l_find_mt_newindex(lua_State *),
           l_ce_mt_index(lua_State *), l_ce_mt_newindex(lua_State *);
static int l_cf_buffer_delete(lua_State *), l_cf_buffer_text_range(lua_State *),
           l_cf_view_focus(lua_State *), l_cf_view_split(lua_State *),
           l_cf_view_unsplit(lua_State *), l_cf_buffer_new(lua_State *),
           l_cf_gui_dialog(lua_State *), l_cf_gui_get_split_table(lua_State *),
           l_cf_gui_goto_view(lua_State *), l_cf_view_goto_buffer(lua_State *),
           l_cf_gui_gtkmenu(lua_State *), l_cf_string_iconv(lua_State *),
           l_cf_reset(lua_State *), l_cf_quit(lua_State *),
           l_cf_find_focus(lua_State *), l_cf_find_next(lua_State *),
           l_cf_find_prev(lua_State *), l_cf_find_replace(lua_State *),
           l_cf_find_replace_all(lua_State *), l_cf_ce_focus(lua_State *),
           l_cf_ce_show_completions(lua_State *), l_cf_timeout(lua_State *);

/******************************************************************************/
/******************************* GUI Interface ********************************/
/******************************************************************************/

/**
 * Runs Textadept in Linux or Mac.
 * Inits the Lua State, creates the user interface, loads the core/init.lua
 * script, and also loads init.lua.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
#if !(__WIN32__ || __OSX__ || __BSD__)
  textadept_home = g_file_read_link("/proc/self/exe", NULL);
#elif __OSX__
  CFURLRef bundle = CFBundleCopyBundleURL(CFBundleGetMainBundle());
  if (bundle) {
    CFStringRef path = CFURLCopyFileSystemPath(bundle, kCFURLPOSIXPathStyle);
    const char *p = CFStringGetCStringPtr(path, kCFStringEncodingMacRoman);
    textadept_home = g_strconcat(p, "/Contents/Resources/", NULL);
    CFRelease(path);
    CFRelease(bundle);
  } else textadept_home = calloc(1, 1);
#elif __BSD__
  textadept_home = malloc(FILENAME_MAX);
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
  size_t cb = FILENAME_MAX;
  sysctl(mib, 4, textadept_home, &cb, NULL, 0);
#endif
  char *last_slash = strrchr(textadept_home, G_DIR_SEPARATOR);
  if (last_slash) *last_slash = '\0';
  gtk_init(&argc, &argv);
  if (!l_init(argc, argv, FALSE)) return 1;
  create_ui();
  l_load_script("init.lua");
  gtk_main();
  free(textadept_home);
  return 0;
}

#if __WIN32__
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
  textadept_home = malloc(FILENAME_MAX);
  GetModuleFileName(0, textadept_home, FILENAME_MAX);
  return main(1, &lpCmdLine);
}
#endif

/**
 * Creates the user interface.
 * The UI consists of:
 *   - A menubar initially hidden and empty. It should be populated by script
 *     and then shown.
 *   - A frame for Scintilla views.
 *   - A find text frame initially hidden.
 *   - A command entry initially hidden. This entry accepts and runs Lua code
 *     in the current Lua state.
 *   - Two status bars: one for notifications, the other for document status.
 */
void create_ui() {
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
  gtk_window_set_default_size(GTK_WINDOW(window), 500, 400);
  signal(window, "delete-event", w_exit);
  signal(window, "focus-in-event", w_focus);
  signal(window, "key-press-event", w_keypress);

#if __OSX__
  AEInstallEventHandler(kCoreEventClass, kAEOpenDocuments,
                        NewAEEventHandlerUPP(w_ae_open), 0, FALSE);
  AEInstallEventHandler(kCoreEventClass, kAEQuitApplication,
                        NewAEEventHandlerUPP(w_ae_quit), 0, FALSE);
#endif

  GtkWidget *vbox = gtk_vbox_new(FALSE, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);

  GtkWidget *hbox = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hbox, TRUE, TRUE, 0);

  GtkWidget *editor = new_view(0);
  gtk_box_pack_start(GTK_BOX(hbox), editor, TRUE, TRUE, 0);

  GtkWidget *find = find_create_ui();
  gtk_box_pack_start(GTK_BOX(vbox), find, FALSE, FALSE, 5);

  GtkWidget *hboxs = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, FALSE, FALSE, 0);

  statusbar[0] = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[0]), 0, "");
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar[0]), FALSE);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[0], TRUE, TRUE, 0);

  command_entry = gtk_entry_new();
  gtk_widget_set_name(command_entry, "textadept-command-entry");
  signal(command_entry, "activate", c_activated);
  signal(command_entry, "key-press-event", c_keypress);
  gtk_box_pack_start(GTK_BOX(hboxs), command_entry, TRUE, TRUE, 0);

  command_entry_completion = gtk_entry_completion_new();
  signal(command_entry_completion, "match-selected", cc_match_selected);
  gtk_entry_completion_set_match_func(command_entry_completion, cc_match_func,
                                      NULL, NULL);
  gtk_entry_completion_set_popup_set_width(command_entry_completion, FALSE);
  gtk_entry_completion_set_text_column(command_entry_completion, 0);
  cc_store = gtk_list_store_new(1, G_TYPE_STRING);
  gtk_entry_completion_set_model(command_entry_completion,
                                 GTK_TREE_MODEL(cc_store));
  gtk_entry_set_completion(GTK_ENTRY(command_entry), command_entry_completion);

  statusbar[1] = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[1]), 0, "");
  g_object_set(G_OBJECT(statusbar[1]), "width-request", 400, NULL);
#if __OSX__
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar[1]), FALSE);
#endif
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], FALSE, FALSE, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar); // hide initially
  gtk_widget_hide(findbox); // hide initially
  gtk_widget_hide(command_entry); // hide initially
  gtk_widget_grab_focus(editor);
}

/**
 * Creates a new Scintilla view.
 * The Scintilla view is the GTK widget that displays a Scintilla buffer.
 * Generates a 'view_new' event.
 * @param buffer_id A Scintilla buffer ID to load into the new window. If NULL,
 *   creates a new Scintilla buffer and loads it into the new window.
 * @return the Scintilla view.
 * @see l_add_view
 */
GtkWidget *new_view(sptr_t buffer_id) {
  GtkWidget *editor = scintilla_new();
  gtk_widget_set_size_request(editor, 1, 1); // minimum size
  SS(editor, SCI_USEPOPUP, 0, 0);
  signal(editor, SCINTILLA_NOTIFY, s_notification);
  signal(editor, "command", s_command);
  signal(editor, "key-press-event", s_keypress);
  signal(editor, "button-press-event", s_buttonpress);
  l_add_view(editor);
  gtk_widget_grab_focus(editor);
  focused_editor = editor;
  if (buffer_id) {
    SS(editor, SCI_SETDOCPOINTER, 0, buffer_id);
    new_buffer(editor, FALSE, FALSE);
  } else new_buffer(editor, FALSE, TRUE);
  l_set_view_global(editor);
  l_emit_event("view_new", -1);
  return editor;
}

/**
 * Removes a Scintilla view.
 * @param editor The Scintilla view to remove.
 * @see l_remove_view
 */
void remove_view(GtkWidget *editor) {
  l_remove_view(editor);
  gtk_widget_destroy(editor);
}

/**
 * Creates a new Scintilla buffer for a newly created Scintilla view.
 * Generates a 'buffer_new' event.
 * @param editor The Scintilla view to associate the buffer with.
 * @param create Flag indicating whether or not to create a buffer. If FALSE,
 *   the Scintilla view already has a buffer associated with it (typically
 *   because new_view was passed a non-NULL buffer_id).
 * @param addref Flag indicating whether or not to add a reference to the buffer
 *   in the Scintilla view when create is FALSE. This is necessary for creating
 *   Scintilla views in split views. If a buffer appears in two separate
 *   Scintilla views, that buffer should have multiple references so when one
 *   Scintilla view closes, the buffer is not deleted because its reference
 *   count is not zero.
 * @see l_add_buffer
 */
void new_buffer(GtkWidget *editor, int create, int addref) {
  sptr_t doc;
  doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  if (create) { // create the new document
    doc = SS(editor, SCI_CREATEDOCUMENT, 0, 0);
    l_emit_event("buffer_before_switch", -1);
    l_goto_buffer(focused_editor, l_add_buffer(doc), TRUE);
  } else if (addref) {
    l_add_buffer(doc);
    SS(editor, SCI_ADDREFDOCUMENT, 0, doc);
  }
  l_set_buffer_global(editor);
  l_emit_event("buffer_new", -1);
  l_emit_event("update_ui", -1); // update document status
}

/**
 * Removes the Scintilla buffer from the current Scintilla view.
 * @param doc The Scintilla buffer ID to remove.
 * @see l_remove_buffer
 */
void remove_buffer(sptr_t doc) {
  l_remove_buffer(doc);
  SS(focused_editor, SCI_RELEASEDOCUMENT, 0, doc);
}

/**
 * Splits a Scintilla view into two windows separated by a GTK pane.
 * The buffer in the original pane is also shown in the new pane.
 * @param editor The Scintilla view to split.
 * @param vertical Flag indicating whether to split the window vertically or
 *   horozontally.
 */
void split_view(GtkWidget *editor, int vertical) {
  g_object_ref(editor);
  int first_line = SS(editor, SCI_GETFIRSTVISIBLELINE, 0, 0);
  int current_pos = SS(editor, SCI_GETCURRENTPOS, 0, 0);
  int anchor = SS(editor, SCI_GETANCHOR, 0, 0);
  int middle = (vertical ? editor->allocation.width
                         : editor->allocation.height) / 2;

  sptr_t curdoc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  GtkWidget *neweditor = new_view(curdoc);
  GtkWidget *parent = gtk_widget_get_parent(editor);
  gtk_container_remove(GTK_CONTAINER(parent), editor);
  GtkWidget *pane = vertical ? gtk_hpaned_new() : gtk_vpaned_new();
  gtk_paned_add1(GTK_PANED(pane), editor);
  gtk_paned_add2(GTK_PANED(pane), neweditor);
  gtk_container_add(GTK_CONTAINER(parent), pane);
  gtk_paned_set_position(GTK_PANED(pane), middle);
  gtk_widget_show_all(pane);
  gtk_widget_grab_focus(neweditor);

  SS(neweditor, SCI_SETSEL, anchor, current_pos);
  int new_first_line = SS(neweditor, SCI_GETFIRSTVISIBLELINE, 0, 0);
  SS(neweditor, SCI_LINESCROLL, first_line - new_first_line, 0);
  g_object_unref(editor);
}

/**
 * For a given GTK pane, remove the Scintilla views inside it recursively.
 * @param pane The GTK pane to remove Scintilla views from.
 * @see remove_view
 */
void remove_views_in_pane(GtkWidget *pane) {
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane));
  GtkWidget *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_views_in_pane(child1) : remove_view(child1);
  GTK_IS_PANED(child2) ? remove_views_in_pane(child2) : remove_view(child2);
}

/**
 * Unsplits the pane a given Scintilla view is in and keeps that window.
 * If the pane to discard contains other Scintilla views, they are removed
 * recursively.
 * @param editor The Scintilla view to keep when unsplitting.
 * @see remove_views_in_pane
 * @see remove_view
 */
int unsplit_view(GtkWidget *editor) {
  GtkWidget *pane = gtk_widget_get_parent(editor);
  if (!GTK_IS_PANED(pane)) return FALSE;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane));
  if (other == editor) other = gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(editor);
  g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), editor);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_views_in_pane(other) : remove_view(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent)) {
    if (!gtk_paned_get_child1(GTK_PANED(parent)))
      gtk_paned_add1(GTK_PANED(parent), editor);
    else
      gtk_paned_add2(GTK_PANED(parent), editor);
  } else gtk_container_add(GTK_CONTAINER(parent), editor);
  gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(editor));
  g_object_unref(editor);
  g_object_unref(other);
  return TRUE;
}

/**
 * Sets a user-defined GTK menubar and displays it.
 * @param new_menubar The GTK menubar.
 * @see l_gui_mt_newindex
 */
void set_menubar(GtkWidget *new_menubar) {
  GtkWidget *vbox = gtk_widget_get_parent(menubar);
  gtk_container_remove(GTK_CONTAINER(vbox), menubar);
  menubar = new_menubar;
  gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);
  gtk_box_reorder_child(GTK_BOX(vbox), menubar, 0);
  gtk_widget_show_all(menubar);
#if __OSX__
  ige_mac_menu_set_menu_bar(GTK_MENU_SHELL(menubar));
  gtk_widget_hide(menubar);
#endif
}

/**
 * Sets the notification statusbar text.
 * @param text The text to display.
 * @param bar Statusbar. 0 for statusbar, 1 for docstatusbar.
 */
void set_statusbar_text(const char *text, int bar) {
  if (!statusbar[0] || !statusbar[1]) return; // unavailable on startup
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar[bar]), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[bar]), 0, text);
}

/******************************************************************************/
/************************* GUI Notifications/Signals **************************/
/******************************************************************************/

/**
 * Helper function for switching the focused view to the given one.
 * @param editor The Scintilla view to focus.
 * @see s_notification
 * @see s_command
 */
static void switch_to_view(GtkWidget *editor) {
  l_emit_event("view_before_switch", -1);
  focused_editor = editor;
  l_set_view_global(editor);
  l_set_buffer_global(editor);
  l_emit_event("view_after_switch", -1);
}

/**
 * Signal for a Scintilla notification.
 */
static void s_notification(GtkWidget *editor, gint wParam, gpointer lParam,
                           gpointer udata) {
  struct SCNotification *n = (struct SCNotification *)lParam;
  if (focused_editor != editor &&
      (n->nmhdr.code == SCN_URIDROPPED || n->nmhdr.code == SCN_SAVEPOINTLEFT))
    switch_to_view(editor);
  l_emit_scnnotification(n);
}

/**
 * Signal for a Scintilla command.
 * Currently handles SCEN_SETFOCUS.
 */
static void s_command(GtkWidget *editor, gint wParam, gpointer lParam,
                      gpointer udata) {
  if (wParam >> 16 == SCEN_SETFOCUS) switch_to_view(editor);
}

/**
 * Signal for a Scintilla keypress.
 * Collects the modifier states as flags and calls Lua to handle the keypress.
 */
static gbool s_keypress(GtkWidget *editor, GdkEventKey *event, gpointer udata) {
  return l_emit_event("keypress",
                      LUA_TNUMBER, event->keyval,
                      LUA_TBOOLEAN, event->state & GDK_SHIFT_MASK,
                      LUA_TBOOLEAN, event->state & GDK_CONTROL_MASK,
                      LUA_TBOOLEAN, event->state & GDK_MOD1_MASK,
                      -1) ? TRUE : FALSE;
}

/**
 * Signal for a Scintilla mouse click.
 * If it is a right-click, popup a context menu.
 * @see l_gui_popup_context_menu
 */
static gbool s_buttonpress(GtkWidget *editor, GdkEventButton *event,
                           gpointer udata) {
  if (event->type != GDK_BUTTON_PRESS || event->button != 3) return FALSE;
  l_gui_popup_context_menu(event);
  return TRUE;
}

/**
 * Signal for a Textadept window focus change.
 */
static gbool w_focus(GtkWidget *window, GdkEventFocus *event, gpointer udata) {
  if (focused_editor && !GTK_WIDGET_HAS_FOCUS(focused_editor))
    gtk_widget_grab_focus(focused_editor);
  return FALSE;
}

/**
 * Signal for a Textadept keypress.
 * Currently handled keypresses:
 *  - Escape - hides the search frame if it's open.
 */
static gbool w_keypress(GtkWidget *window, GdkEventKey *event, gpointer udata) {
  if (event->keyval == 0xff1b && GTK_WIDGET_VISIBLE(findbox) &&
      !GTK_WIDGET_HAS_FOCUS(command_entry)) {
    gtk_widget_hide(findbox);
    gtk_widget_grab_focus(focused_editor);
    return TRUE;
  } else return FALSE;
}

/**
 * Signal for exiting Textadept.
 * Closes the Lua State and releases resources.
 * Generates a 'quit' event.
 * @see l_close
 */
static gbool w_exit(GtkWidget *window, GdkEventAny *event, gpointer udata) {
  if (!l_emit_event("quit", -1)) return TRUE;
  l_close();
  scintilla_release_resources();
  gtk_main_quit();
  return FALSE;
}

#if __OSX__
/**
 * Signal for an Open Document AppleEvent.
 * Generates a 'appleevent_odoc' event for each document sent.
 */
static OSErr w_ae_open(const AppleEvent *event, AppleEvent *reply, long ref) {
  AEDescList file_list;
  if (AEGetParamDesc(event, keyDirectObject, typeAEList, &file_list) == noErr) {
    long count = 0;
    AECountItems(&file_list, &count);
    for (int i = 1; i <= count; i++) {
      FSRef fsref;
      AEGetNthPtr(&file_list, i, typeFSRef, NULL, NULL, &fsref, sizeof(FSRef),
                  NULL);
      CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsref);
      if (url) {
        CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        const char *p = CFStringGetCStringPtr(path, kCFStringEncodingMacRoman);
        l_emit_event("appleevent_odoc", LUA_TSTRING, p, -1);
        CFRelease(path);
        CFRelease(url);
      }
    }
    AEDisposeDesc(&file_list);
  }
  return noErr;
}

/**
 * Signal for a Quit Application AppleEvent.
 * Calls the signal for exiting Textadept.
 * @see w_exit
 */
static OSErr w_ae_quit(const AppleEvent *event, AppleEvent *reply, long ref) {
  return w_exit(NULL, NULL, NULL) ? (OSErr) noErr : errAEEventNotHandled;
}
#endif

/******************************************************************************/
/************************* Find/Replace GUI Interface *************************/
/******************************************************************************/

#define attach(w, x1, x2, y1, y2, xo, yo, xp, yp) \
  gtk_table_attach(GTK_TABLE(findbox), w, x1, x2, y1, y2, xo, yo, xp, yp)
#define ao_expand (GtkAttachOptions)(GTK_EXPAND | GTK_FILL)
#define ao_normal (GtkAttachOptions)(GTK_SHRINK | GTK_FILL)

/**
 * Creates the Find/Replace text frame.
 */
GtkWidget *find_create_ui() {
  findbox = gtk_table_new(2, 6, FALSE);
  find_store = gtk_list_store_new(1, G_TYPE_STRING);
  repl_store = gtk_list_store_new(1, G_TYPE_STRING);

  GtkWidget *flabel = gtk_label_new_with_mnemonic("_Find:");
  GtkWidget *rlabel = gtk_label_new_with_mnemonic("R_eplace:");
  GtkWidget *find_combo = gtk_combo_box_entry_new_with_model(
                          GTK_TREE_MODEL(find_store), 0);
  g_object_unref(find_store);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(find_combo), FALSE);
  find_entry = gtk_bin_get_child(GTK_BIN(find_combo));
  gtk_widget_set_name(find_entry, "textadept-find-entry");
  gtk_entry_set_activates_default(GTK_ENTRY(find_entry), TRUE);
  GtkWidget *replace_combo = gtk_combo_box_entry_new_with_model(
                             GTK_TREE_MODEL(repl_store), 0);
  g_object_unref(repl_store);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(replace_combo), FALSE);
  replace_entry = gtk_bin_get_child(GTK_BIN(replace_combo));
  gtk_widget_set_name(replace_entry, "textadept-replace-entry");
  gtk_entry_set_activates_default(GTK_ENTRY(replace_entry), TRUE);
  fnext_button = gtk_button_new_with_mnemonic("Find _Next");
  fprev_button = gtk_button_new_with_mnemonic("Find _Prev");
  r_button = gtk_button_new_with_mnemonic("_Replace");
  ra_button = gtk_button_new_with_mnemonic("Replace _All");
  match_case_opt = gtk_check_button_new_with_mnemonic("_Match case");
  whole_word_opt = gtk_check_button_new_with_mnemonic("_Whole word");
  lua_opt = gtk_check_button_new_with_mnemonic("_Lua pattern");
  in_files_opt = gtk_check_button_new_with_mnemonic("_In Files");

  gtk_label_set_mnemonic_widget(GTK_LABEL(flabel), find_entry);
  gtk_label_set_mnemonic_widget(GTK_LABEL(rlabel), replace_entry);

  attach(find_combo, 1, 2, 0, 1, ao_expand, ao_normal, 5, 0);
  attach(replace_combo, 1, 2, 1, 2, ao_expand, ao_normal, 5, 0);
  attach(flabel, 0, 1, 0, 1, ao_normal, ao_normal, 5, 0);
  attach(rlabel, 0, 1, 1, 2, ao_normal, ao_normal, 5, 0);
  attach(fnext_button, 2, 3, 0, 1, ao_normal, ao_normal, 0, 0);
  attach(fprev_button, 3, 4, 0, 1, ao_normal, ao_normal, 0, 0);
  attach(r_button, 2, 3, 1, 2, ao_normal, ao_normal, 0, 0);
  attach(ra_button, 3, 4, 1, 2, ao_normal, ao_normal, 0, 0);
  attach(match_case_opt, 4, 5, 0, 1, ao_normal, ao_normal, 5, 0);
  attach(whole_word_opt, 4, 5, 1, 2, ao_normal, ao_normal, 5, 0);
  attach(lua_opt, 5, 6, 0, 1, ao_normal, ao_normal, 5, 0);
  attach(in_files_opt, 5, 6, 1, 2, ao_normal, ao_normal, 5, 0);

  signal(fnext_button, "clicked", find_button_clicked);
  signal(fprev_button, "clicked", find_button_clicked);
  signal(r_button, "clicked", find_button_clicked);
  signal(ra_button, "clicked", find_button_clicked);

  GTK_WIDGET_SET_FLAGS(fnext_button, GTK_CAN_DEFAULT);
  GTK_WIDGET_UNSET_FLAGS(fnext_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(fprev_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(r_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(ra_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(match_case_opt, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(whole_word_opt, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(lua_opt, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(in_files_opt, GTK_CAN_FOCUS);

  return findbox;
}

/**
 * Toggles the focus between the Find/Replace frame and the current Scintilla
 * window.
 */
void find_toggle_focus() {
  if (!GTK_WIDGET_HAS_FOCUS(findbox)) {
    gtk_widget_show(findbox);
    gtk_widget_grab_focus(find_entry);
    gtk_widget_grab_default(fnext_button);
  } else {
    gtk_widget_grab_focus(focused_editor);
    gtk_widget_hide(findbox);
  }
}

/**
 * Adds the given text to the Find/Replace history list if it's not the first
 * item.
 * @param text The text to add.
 * @param store The GtkListStore to add the text to.
 */
static void find_add_to_history(const char *text, GtkListStore *store) {
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
}

/******************************************************************************/
/**************************** Find/Replace Signals ****************************/
/******************************************************************************/

/**
 * Signal for a Find frame button click.
 * Performs the appropriate action depending on the button clicked.
 */
static void find_button_clicked(GtkWidget *button, gpointer udata) {
  const char *find_text = gtk_entry_get_text(GTK_ENTRY(find_entry));
  const char *repl_text = gtk_entry_get_text(GTK_ENTRY(replace_entry));
  if (strlen(find_text) == 0) return;
  if (button == fnext_button || button == fprev_button) {
    find_add_to_history(find_text, find_store);
    l_emit_event("find", LUA_TSTRING, find_text, LUA_TBOOLEAN,
                 button == fnext_button, -1);
  } else {
    find_add_to_history(repl_text, repl_store);
    if (button == r_button) {
      l_emit_event("replace", LUA_TSTRING, repl_text, -1);
      l_emit_event("find", LUA_TSTRING, find_text, LUA_TBOOLEAN, 1, -1);
    } else
      l_emit_event("replace_all", LUA_TSTRING, find_text, LUA_TSTRING,
                   repl_text, -1);
  }
}

/******************************************************************************/
/************************ Command Entry GUI Interface *************************/
/******************************************************************************/

/**
 * Toggles focus between a Scintilla view and the Command Entry.
 * When the entry is visible, the statusbars are temporarily hidden.
 */
void ce_toggle_focus() {
  if (!GTK_WIDGET_HAS_FOCUS(command_entry)) {
    gtk_widget_hide(statusbar[0]);
    gtk_widget_hide(statusbar[1]);
    gtk_widget_show(command_entry);
    gtk_widget_grab_focus(command_entry);
  } else {
    gtk_widget_show(statusbar[0]);
    gtk_widget_show(statusbar[1]);
    gtk_widget_hide(command_entry);
    gtk_widget_grab_focus(focused_editor);
  }
}

/**
 * Sets every item in the Command Entry Model to be a match.
 * For each attempted completion, the Command Entry Model is filled with the
 * results from a call to Lua to make a list of possible completions. Therefore,
 * every item in the list is valid.
 */
static int cc_match_func(GtkEntryCompletion *entry, const char *key,
                         GtkTreeIter *iter, gpointer udata) { return 1; }

/**
 * Enters the requested completion text into the Command Entry.
 * The last word at the cursor is replaced with the completion. A word consists
 * of any alphanumeric character or underscore.
 */
static gbool cc_match_selected(GtkEntryCompletion *entry, GtkTreeModel *model,
                               GtkTreeIter *iter, gpointer udata) {
  const char *entry_text = gtk_entry_get_text(GTK_ENTRY(command_entry));
  const char *p = entry_text + strlen(entry_text) - 1;
  while ((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z') ||
         (*p >= '0' && *p <= '9') || *p == '_') {
    g_signal_emit_by_name(G_OBJECT(command_entry), "move-cursor",
                          GTK_MOVEMENT_VISUAL_POSITIONS, -1, TRUE, 0);
    p--;
  }
  if (p < entry_text + strlen(entry_text) - 1)
    g_signal_emit_by_name(G_OBJECT(command_entry), "backspace", 0);

  char *text;
  gtk_tree_model_get(model, iter, 0, &text, -1);
  g_signal_emit_by_name(G_OBJECT(command_entry), "insert-at-cursor", text, 0);
  g_free(text);

  gtk_list_store_clear(cc_store);
  return TRUE;
}

/******************************************************************************/
/*************************** Command Entry Signals ****************************/
/******************************************************************************/

/**
 * Signal for the 'enter' key being pressed in the Command Entry.
 */
static void c_activated(GtkWidget *entry, gpointer udata) {
  l_emit_event("command_entry_command", LUA_TSTRING,
               gtk_entry_get_text(GTK_ENTRY(entry)), -1);
}

/**
 * Signal for a keypress inside the Command Entry.
 */
static gbool c_keypress(GtkWidget *entry, GdkEventKey *event, gpointer udata) {
  return l_emit_event("command_entry_keypress", LUA_TNUMBER, event->keyval, -1);
}

/******************************************************************************/
/******************************** Lua Interface *******************************/
/******************************************************************************/

#define l_openlib(l, n, f) { \
  lua_pushcfunction(l, f); \
  lua_pushstring(l, n); \
  lua_call(l, 1, 0); \
}
#define l_archive(l, k) { \
  lua_pushstring(l, k); \
  lua_rawget(l, -2); \
  lua_setfield(l, LUA_REGISTRYINDEX, k); \
}

/**
 * Inits or re-inits the Lua State.
 * Populates the state with global variables and functions, then runs the
 * 'core/init.lua' script.
 * @param argc The number of command line parameters.
 * @param argv The array of command line parameters.
 * @param reinit Flag indicating whether or not to reinitialize the Lua State.
 * @return TRUE on success, FALSE on failure.
 */
int l_init(int argc, char **argv, int reinit) {
  if (!reinit) {
    lua = lua_open();
    lua_newtable(lua);
    for (int i = 0; i < argc; i++) {
      lua_pushstring(lua, argv[i]);
      lua_rawseti(lua, -2, i);
    }
    lua_setfield(lua, LUA_REGISTRYINDEX, "arg");
    lua_newtable(lua);
    lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
    lua_newtable(lua);
    lua_setfield(lua, LUA_REGISTRYINDEX, "views");
  } else { // clear package.loaded and _G
    lua_getglobal(lua, "package");
    lua_getfield(lua, -1, "loaded");
    clear_table(lua, lua_gettop(lua));
    lua_pop(lua, 2); // package and package.loaded
    clear_table(lua, LUA_GLOBALSINDEX);
  }
  luaL_openlibs(lua);
  l_openlib(lua, "lpeg", luaopen_lpeg);
  l_openlib(lua, "lfs", luaopen_lfs);

  lua_newtable(lua);
    lua_newtable(lua);
      l_cfunc(lua, l_cf_find_next, "find_next");
      l_cfunc(lua, l_cf_find_prev, "find_prev");
      l_cfunc(lua, l_cf_find_focus, "focus");
      l_cfunc(lua, l_cf_find_replace, "replace");
      l_cfunc(lua, l_cf_find_replace_all, "replace_all");
      l_mt(lua, "_find_mt", l_find_mt_index, l_find_mt_newindex);
    lua_setfield(lua, -2, "find");
    lua_newtable(lua);
      l_cfunc(lua, l_cf_ce_focus, "focus");
      l_cfunc(lua, l_cf_ce_show_completions, "show_completions");
      l_mt(lua, "_ce_mt", l_ce_mt_index, l_ce_mt_newindex);
    lua_setfield(lua, -2, "command_entry");
    l_cfunc(lua, l_cf_gui_dialog, "dialog");
    l_cfunc(lua, l_cf_gui_get_split_table, "get_split_table");
    l_cfunc(lua, l_cf_gui_goto_view, "goto_view");
    l_cfunc(lua, l_cf_gui_gtkmenu, "gtkmenu");
    l_mt(lua, "_gui_mt", l_gui_mt_index, l_gui_mt_newindex);
  lua_setglobal(lua, "gui");

  lua_getglobal(lua, "_G");
  l_cfunc(lua, l_cf_buffer_new, "new_buffer");
  l_cfunc(lua, l_cf_quit, "quit");
  l_cfunc(lua, l_cf_reset, "reset");
  l_cfunc(lua, l_cf_timeout, "timeout");
  lua_pop(lua, 1); // _G

  lua_getglobal(lua, "string");
  l_cfunc(lua, l_cf_string_iconv, "iconv");
  lua_pop(lua, 1); // string

  lua_getfield(lua, LUA_REGISTRYINDEX, "arg");
  lua_setglobal(lua, "arg");
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_setglobal(lua, "_BUFFERS");
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_setglobal(lua, "_VIEWS");
  lua_pushstring(lua, textadept_home);
  lua_setglobal(lua, "_HOME");
#if __WIN32__
  lua_pushboolean(lua, 1);
  lua_setglobal(lua, "WIN32");
#elif __OSX__
  lua_pushboolean(lua, 1);
  lua_setglobal(lua, "OSX");
#endif
  const char *charset = 0;
  g_get_charset(&charset);
  lua_pushstring(lua, charset);
  lua_setglobal(lua, "_CHARSET");

  if (l_load_script("core/init.lua")) {
    lua_getglobal(lua, "_SCINTILLA");
    l_archive(lua, "constants");
    l_archive(lua, "functions");
    l_archive(lua, "properties");
    lua_pop(lua, 1); // _SCINTILLA
    return TRUE;
  }
  lua_close(lua);
  return FALSE;
}

/**
 * Loads and runs a given Lua script.
 * @param script_file The path of the Lua script relative to textadept_home.
 * @return TRUE on success, FALSE otherwise.
 */
int l_load_script(const char *script_file) {
  char *script = g_strconcat(textadept_home, "/", script_file, NULL);
  int retval = luaL_dofile(lua, script) == 0;
  if (!retval) {
    const char *errmsg = lua_tostring(lua, -1);
    lua_settop(lua, 0);
    GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                               GTK_MESSAGE_ERROR,
                                               GTK_BUTTONS_OK, "%s\n", errmsg);
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
  }
  g_free(script);
  return retval;
}

/**
 * Checks a specified stack element to see if it is a Scintilla view and returns
 * it as a GtkWidget.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a Scintilla view.
 * @return GtkWidget Scintilla view.
 */
static GtkWidget *l_checkview(lua_State *lua, int narg) {
  luaL_argcheck(lua, lua_istable(lua, narg), narg, "View expected");
  lua_pushstring(lua, "widget_pointer");
  lua_rawget(lua, (narg > 0) ? narg : narg - 1);
  luaL_argcheck(lua, lua_islightuserdata(lua, -1), narg, "View expected");
  GtkWidget *editor = l_togtkwidget(lua, -1);
  lua_pop(lua, 1); // widget_pointer
  return editor;
}

/**
 * Adds a Scintilla view to the global '_VIEWS' table with a metatable.
 * @param editor The Scintilla view to add.
 */
void l_add_view(GtkWidget *editor) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_newtable(lua);
    lua_pushlightuserdata(lua, (GtkWidget *)editor);
    lua_setfield(lua, -2, "widget_pointer");
    l_cfunc(lua, l_cf_view_focus, "focus");
    l_cfunc(lua, l_cf_view_goto_buffer, "goto_buffer");
    l_cfunc(lua, l_cf_view_split, "split");
    l_cfunc(lua, l_cf_view_unsplit, "unsplit");
    l_mt(lua, "_view_mt", l_view_mt_index, l_view_mt_newindex);
  l_append(lua, -2); // pops table
  lua_pop(lua, 1); // views
}

/**
 * Removes a Scintilla view from the global '_VIEWS' table.
 * @param editor The Scintilla view to remove.
 */
void l_remove_view(GtkWidget *editor) {
  lua_newtable(lua);
    lua_getfield(lua, LUA_REGISTRYINDEX, "views");
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      (editor != l_checkview(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
    lua_pop(lua, 1); // views
  lua_pushvalue(lua, -1);
  lua_setfield(lua, LUA_REGISTRYINDEX, "views");
  lua_setglobal(lua, "_VIEWS");
}

/**
 * Changes focus a Scintilla view in the global '_VIEWS' table.
 * @param editor The currently focused Scintilla view.
 * @param n The index of the window in the '_VIEWS' table to focus.
 * @param absolute Flag indicating whether or not the index specified in
 *   '_VIEWS' is absolute. If FALSE, focuses the window relative to the
 *   currently focused window for the given index.
 *   Throws an error if the view does not exist.
 */
void l_goto_view(GtkWidget *editor, int n, int absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (!absolute) {
    unsigned int idx = 1;
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (editor == l_checkview(lua, -1)) {
        idx = lua_tointeger(lua, -2);
        lua_pop(lua, 2); // key and value
        break;
      } else lua_pop(lua, 1); // value
    idx += n;
    if (idx > lua_objlen(lua, -1))
      idx = 1;
    else if (idx < 1)
      idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else {
    luaL_argcheck(lua, n >= 0 && n <= lua_objlen(lua, -1), 1,
                  "no View exists at that index");
    lua_rawgeti(lua, -1, n);
  }
  editor = l_checkview(lua, -1);
  if (!closing) l_emit_event("view_before_switch", -1);
  gtk_widget_grab_focus(editor);
  if (!closing) l_emit_event("view_after_switch", -1);
  lua_pop(lua, 2); // view table and views
}

/**
 * Sets the global 'view' variable to be the specified Scintilla view.
 * @param editor The Scintilla view to set 'view' to.
 */
void l_set_view_global(GtkWidget *editor) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (editor == l_checkview(lua, -1)) {
      lua_setglobal(lua, "view"); // value (view table)
      lua_pop(lua, 1); // key
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // views
}

/**
 * Checks a specified element to see if it is a buffer table and returns the
 * Scintilla document pointer associated with it.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a buffer table.
 */
static sptr_t l_checkdocpointer(lua_State *lua, int narg) {
  luaL_argcheck(lua, lua_istable(lua, narg), narg, "Buffer expected");
  lua_pushstring(lua, "doc_pointer");
  lua_rawget(lua, (narg > 0) ? narg : narg - 1);
  luaL_argcheck(lua, lua_isnumber(lua, -1), narg, "Buffer expected");
  sptr_t doc = lua_tointeger(lua, -1);
  lua_pop(lua, 1); // doc_pointer
  return doc;
}

/**
 * Adds a Scintilla document to the global '_BUFFERS' table with a metatable.
 * @param doc The Scintilla document to add.
 * @return integer index of the new buffer in _BUFFERS.
 */
int l_add_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_newtable(lua);
    lua_pushinteger(lua, doc);
    lua_setfield(lua, -2, "doc_pointer");
    l_cfunc(lua, l_cf_buffer_delete, "delete");
    l_cfunc(lua, l_cf_buffer_text_range, "text_range");
    l_mt(lua, "_buffer_mt", l_buffer_mt_index, l_buffer_mt_newindex);
  l_append(lua, -2); // pops table
  int index = lua_objlen(lua, -1);
  lua_pop(lua, 1); // buffers
  return index;
}

/**
 * Removes a Scintilla document from the global '_BUFFERS' table.
 * If any views currently show the document to be removed, change the documents
 * they show first.
 * @param doc The Scintilla buffer to remove.
 */
void l_remove_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    GtkWidget *editor = l_checkview(lua, -1);
    sptr_t that_doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
    if (that_doc == doc) l_goto_buffer(editor, -1, FALSE);
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // views
  lua_newtable(lua);
    lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      (doc != l_checkdocpointer(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
    lua_pop(lua, 1); // buffers
  lua_pushvalue(lua, -1);
  lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_setglobal(lua, "_BUFFERS");
}

/**
 * Retrieves the index in the global '_BUFFERS' table for a given Scintilla
 * document.
 * @param doc The Scintilla document to get the index of.
 * @return int buffer index.
 */
unsigned int l_get_docpointer_index(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  unsigned int idx = 1;
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (doc == l_checkdocpointer(lua, -1)) {
      idx = lua_tointeger(lua, -2);
      lua_pop(lua, 2); // key and value
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // buffers
  return idx;
}

/**
 * Changes a Scintilla view's document to one in the global '_BUFFERS' table.
 * Before doing so, it saves the scroll and caret positions in the current
 * Scintilla document. Then when the new document is shown, its scroll and caret
 * positions are restored.
 * @param editor The Scintilla view to change the document of.
 * @param n The index of the document in '_BUFFERS' to focus.
 * @param absolute Flag indicating whether or not the index specified in
 *   '_BUFFERS' is absolute. If FALSE, focuses the document relative to the
 *   currently focused document for the given index.
 *   Throws an error if the buffer does not exist.
 */
void l_goto_buffer(GtkWidget *editor, int n, int absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  if (!absolute) {
    sptr_t doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
    unsigned int idx = l_get_docpointer_index(doc);
    idx += n;
    if (idx > lua_objlen(lua, -1))
      idx = 1;
    else if (idx < 1)
      idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else {
    luaL_argcheck(lua, n >= 0 && n <= lua_objlen(lua, -1), 2,
                  "no Buffer exists at that index");
    lua_rawgeti(lua, -1, n);
  }
  sptr_t doc = l_checkdocpointer(lua, -1);
  SS(editor, SCI_SETDOCPOINTER, 0, doc);
  l_set_buffer_global(editor);
  lua_pop(lua, 2); // buffer table and buffers
}

/**
 * Sets the global 'buffer' variable to be the document in the specified
 * Scintilla object.
 * @param editor The Scintilla widget housing the buffer to be 'buffer'.
 */
void l_set_buffer_global(GtkWidget *editor) {
  sptr_t doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (doc == l_checkdocpointer(lua, -1)) {
      lua_setglobal(lua, "buffer"); // value (buffer table)
      lua_pop(lua, 1); // key
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // buffers
}

/**
 * Closes the Lua State.
 * Unsplits all Scintilla views recursively, removes all Scintilla documents,
 * and deletes the last Scintilla view before closing the state.
 */
void l_close() {
  closing = TRUE;
  while (unsplit_view(focused_editor)) ; // need space to fix compiler warning
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    sptr_t doc = l_checkdocpointer(lua, -1);
    remove_buffer(doc);
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // buffers
  gtk_widget_destroy(focused_editor);
  lua_close(lua);
}

/******************************************************************************/
/*************************** Lua Utility Functions ****************************/
/******************************************************************************/

/**
 * Recurses through a Lua table, setting each of its keys and values to nil,
 * effectively clearing the table.
 * @param lua The Lua State.
 * @param abs_index The absolute stack index of the table to clear.
 */
static void clear_table(lua_State *lua, int abs_index) {
  lua_pushnil(lua);
  while (lua_next(lua, abs_index)) {
    lua_pop(lua, 1); // value
    lua_pushnil(lua);
    lua_rawset(lua, abs_index);
    lua_pushnil(lua); // get 'new' first key
  }
}

/**
 * Prints a warning.
 * @param s The warning to print.
 */
static void warn(const char *s) { printf("Warning: %s\n", s); }

/**
 * Returns whether or not the value of the key of the given global table is a
 * function.
 * @param table The table to check for key in.
 * @param key String key to check for in table.
 * @return TRUE for function, FALSE otherwise.
 */
int l_is2function(const char *table, const char *key) {
  lua_getglobal(lua, table);
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, key);
    lua_remove(lua, -2); // table
    if (lua_isfunction(lua, -1)) return TRUE;
    lua_pop(lua, 1); // non-function
  } else lua_pop(lua, 1); // non-table
  return FALSE;
}

/**
 * Calls a Lua function with a number of arguments and expected return values.
 * The last argument is at the stack top, and each argument in reverse order is
 * one element lower on the stack with the Lua function being under the first
 * argument.
 * @param nargs The number of arguments to pass to the Lua function to call.
 * @param retn Optional number of expected return values. Defaults to 0.
 * @param keep_return Optional flag indicating whether or not to keep the return
 *   values at the top of the stack. If FALSE, discards the return values.
 *   Defaults to FALSE.
 * @return FALSE if an error occured or the function returns false explicitly;
 *   TRUE otherwise.
 */
static int l_call_function(int nargs, int retn, int keep_return) {
  int ret = lua_pcall(lua, nargs, retn, 0);
  if (ret == 0) {
    int result = (retn > 0) ? lua_toboolean(lua, -1) == 1 : TRUE;
    if (retn > 0 && !keep_return) lua_pop(lua, retn); // retn
    return result;
  } else {
    if (focused_editor)
      l_emit_event("error", LUA_TSTRING, lua_tostring(lua, -1), -1);
    else
      printf("Lua Error: %s\n", lua_tostring(lua, -1));
    lua_settop(lua, 0);
  }
  return FALSE;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns an int.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param n The index in the table to rawget.
 * @return int result of lua_rawgeti().
 */
static int l_rawgeti_int(lua_State *lua, int index, int n) {
  lua_rawgeti(lua, index, n);
  int ret = lua_tointeger(lua, -1);
  lua_pop(lua, 1); // integer
  return ret;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns a string.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param k String key in the table to rawget.
 * @return string result of lua_rawget().
 */
static const char *l_rawget_str(lua_State *lua, int index, const char *k) {
  lua_pushstring(lua, k);
  lua_rawget(lua, index);
  const char *str = lua_tostring(lua, -1);
  lua_pop(lua, 1); // string
  return str;
}

/**
 * Creates a GtkMenu from a table at the top of the Lua stack.
 * The table has a key 'title' and a numeric list of subitems.
 * @param lua The Lua State.
 * @param callback A GCallback associated with each menu item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 * @return GtkWidget menu.
 */
GtkWidget *l_create_gtkmenu(lua_State *lua, GCallback callback, int submenu) {
  GtkWidget *menu = gtk_menu_new(), *menu_item = 0, *submenu_root = 0;
  const char *label;
  lua_getfield(lua, -1, "title");
  if (!lua_isnil(lua, -1) || submenu) { // title required for submenu
    label = !lua_isnil(lua, -1) ? lua_tostring(lua, -1) : "notitle";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(lua, 1); // title
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_istable(lua, -1)) {
      lua_getfield(lua, -1, "title");
      int is_submenu = !lua_isnil(lua, -1);
      lua_pop(lua, 1); // title
      if (is_submenu)
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              l_create_gtkmenu(lua, callback, TRUE));
      else
        if (lua_objlen(lua, -1) == 2) {
          lua_rawgeti(lua, -1, 1);
          lua_rawgeti(lua, -2, 2);
          label = lua_tostring(lua, -2);
          int menu_id = lua_tointeger(lua, -1);
          lua_pop(lua, 2); // label and id
          if (label) {
            if (g_str_has_prefix(label, "gtk-"))
              menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
            else if (streq(label, "separator"))
              menu_item = gtk_separator_menu_item_new();
            else
              menu_item = gtk_menu_item_new_with_mnemonic(label);
            g_signal_connect(menu_item, "activate", callback,
                             GINT_TO_POINTER(menu_id));
            gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
          }
        } else warn("gtkmenu: { 'menu label', id_number } expected");
    }
    lua_pop(lua, 1); // value
  }
  return !submenu_root ? menu : submenu_root;
}

/**
 * Convert the stack element at a specified index to a Scintilla w and/or l long
 * parameter based on type.
 * @param lua The Lua State.
 * @param type The Lua type the top stack element is.
 * @param arg_idx The initial stack index to start converting at. It is
 *   incremented as parameters are read from the stack.
 * @return long for Scintilla.
 */
static long l_toscintillaparam(lua_State *lua, int type, int *arg_idx) {
  if (type == tSTRING)
    return (long)luaL_checkstring(lua, (*arg_idx)++);
  else if (type == tBOOL)
    return lua_toboolean(lua, (*arg_idx)++);
  else if (type == tKEYMOD) {
    int key = luaL_checkinteger(lua, (*arg_idx)++) & 0xFFFF;
    return key | ((luaL_checkinteger(lua, (*arg_idx)++) &
                 (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  } else if (type > tVOID && type < tBOOL)
    return luaL_checklong(lua, (*arg_idx)++);
  else
    return 0;
}

/**
 * Checks if the Scintilla document of the buffer table at the index specified
 * is the document of the focused Scintilla view.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg The relative stack position of the buffer table.
 */
static void l_check_focused_buffer(lua_State *lua, int narg) {
  sptr_t cur_doc = SS(focused_editor, SCI_GETDOCPOINTER, 0, 0);
  luaL_argcheck(lua, cur_doc == l_checkdocpointer(lua, narg), 1,
                "the indexed Buffer is not the focused one");
}

/******************************************************************************/
/********************** Lua Notifications/Event Handlers **********************/
/******************************************************************************/

/**
 * Handles a Textadept event.
 * @param s String event name.
 * @param ... Optional arguments to pass to the handler. The variable argument
 *   list should contain Lua types followed by the data of that type to pass.
 *   The list is terminated by a -1.
 * @return FALSE on error or if event returns false explicitly; TRUE otherwise.
 */
int l_emit_event(const char *s, ...) {
  if (!l_is2function("events", "emit")) return FALSE;
  lua_pushstring(lua, s);
  int n = 1;
  va_list ap;
  va_start(ap, s);
  int type = va_arg(ap, int);
  while (type != -1) {
    void *arg = va_arg(ap, void*);
    if (type == LUA_TNIL)
      lua_pushnil(lua);
    else if (type == LUA_TBOOLEAN)
      lua_pushboolean(lua, (long)arg);
    else if (type == LUA_TNUMBER)
      lua_pushinteger(lua, (long)arg);
    else if (type == LUA_TSTRING)
      lua_pushstring(lua, (char *)arg);
    else if (type == LUA_TLIGHTUSERDATA || type == LUA_TTABLE) {
      long ref = (long)arg;
      lua_rawgeti(lua, LUA_REGISTRYINDEX, ref);
      luaL_unref(lua, LUA_REGISTRYINDEX, ref);
    } else warn("events.emit: ignored invalid argument type");
    n++;
    type = va_arg(ap, int);
  }
  va_end(ap);
  return l_call_function(n, 1, FALSE);
}

#define l_pushscninteger(i, n) { \
  lua_pushinteger(lua, i); \
  lua_setfield(lua, -2, n); \
}

/**
 * Handles a Scintilla notification.
 * @param n The Scintilla notification struct.
 */
void l_emit_scnnotification(struct SCNotification *n) {
  if (!l_is2function("events", "notification")) return;
  lua_newtable(lua);
  l_pushscninteger(n->nmhdr.code, "code");
  l_pushscninteger(n->position, "position");
  l_pushscninteger(n->ch, "ch");
  l_pushscninteger(n->modifiers, "modifiers");
  //l_pushscninteger(n->modificationType, "modification_type");
  lua_pushstring(lua, n->text);
  lua_setfield(lua, -2, "text");
  //l_pushscninteger(n->length, "length");
  //l_pushscninteger(n->linesAdded, "lines_added");
  //l_pushscninteger(n->message, "message");
  l_pushscninteger(n->wParam, "wParam");
  l_pushscninteger(n->lParam, "lParam");
  l_pushscninteger(n->line, "line");
  //l_pushscninteger(n->foldLevelNow, "fold_level_now");
  //l_pushscninteger(n->foldLevelPrev, "fold_level_prev");
  l_pushscninteger(n->margin, "margin");
  //l_pushscninteger(n->x, "x");
  //l_pushscninteger(n->y, "y");
  l_call_function(1, 0, FALSE);
}

/**
 * Requests and pops up a context menu for the Scintilla view.
 * @param event The mouse button event.
 */
void l_gui_popup_context_menu(GdkEventButton *event) {
  lua_getglobal(lua, "gui");
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, "context_menu");
    if (lua_isuserdata(lua, -1)) {
      GtkWidget *menu = l_togtkwidget(lua, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? event->button : 0,
                     gdk_event_get_time((GdkEvent *)event));
    } else if (!lua_isnil(lua, -1))
      warn("gui.context_menu: gtkmenu expected");
    lua_pop(lua, 1); // gui.context_menu
  } else lua_pop(lua, 1);
}

/******************************************************************************/
/*********************           Lua Functions            *********************/
/********************* (Stack Maintenence is Unnecessary) *********************/
/******************************************************************************/

/**
 * Calls Scintilla with appropriate parameters and returs appropriate values.
 * @param lua The Lua State.
 * @param editor The Scintilla view to call.
 * @param msg The integer message index to call Scintilla with.
 * @param p1_type The Lua type of p1, the Scintilla w parameter.
 * @param p2_type The Lua type of p2, the Scintilla l parameter.
 * @param rt_type The Lua type of the Scintilla return parameter.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 */
static int l_call_scintilla(lua_State *lua, GtkWidget *editor, int msg,
                            int p1_type, int p2_type, int rt_type, int arg) {
  long params[2] = {0, 0};
  int params_needed = 2, len = 0, string_return = FALSE;
  char *return_string = 0;

  // SCI_PRIVATELEXERCALL iface has p1_type int, p2_type int. Change p2_type
  // appropriately. See LPeg lexer API for more info.
  if (msg == SCI_PRIVATELEXERCALL) {
    p2_type = tSTRINGRESULT;
    int c = luaL_checklong(lua, arg);
    if (c == SCI_GETDIRECTFUNCTION || c == SCI_SETDOCPOINTER) p2_type = tINT;
    else if (c == SCI_SETLEXERLANGUAGE) p2_type = tSTRING;
  }

  // Set the w and l parameters appropriately for Scintilla.
  if (p1_type == tLENGTH && p2_type == tSTRING) {
    params[0] = (long)lua_strlen(lua, arg);
    params[1] = (long)luaL_checkstring(lua, arg);
    params_needed = 0;
  } else if (p2_type == tSTRINGRESULT) {
    string_return = TRUE;
    params_needed = (p1_type == tLENGTH) ? 0 : 1;
  }
  if (params_needed > 0) params[0] = l_toscintillaparam(lua, p1_type, &arg);
  if (params_needed > 1) params[1] = l_toscintillaparam(lua, p2_type, &arg);
  if (string_return) { // if a string return, create a buffer for it
    len = SS(editor, msg, params[0], 0);
    if (p1_type == tLENGTH) params[0] = len;
    return_string = malloc(len + 1);
    return_string[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    params[1] = (long)return_string;
  }

  // Send the message to Scintilla and return the appropriate values.
  int result = SS(editor, msg, params[0], params[1]);
  arg = lua_gettop(lua);
  if (string_return) lua_pushlstring(lua, return_string, len);
  if (rt_type == tBOOL) lua_pushboolean(lua, result);
  if (rt_type > tVOID && rt_type < tBOOL) lua_pushinteger(lua, result);
  g_free(return_string);
  return lua_gettop(lua) - arg;
}

/**
 * Calls a Scintilla buffer function with upvalues from a closure.
 * @param lua The Lua State.
 * @see l_buffer_mt_index
 */
static int l_call_buffer_function(lua_State *lua) {
  GtkWidget *editor = l_togtkwidget(lua, lua_upvalueindex(1));
  int buffer_func_table_idx = lua_upvalueindex(2);
  int msg = l_rawgeti_int(lua, buffer_func_table_idx, 1);
  int rt_type = l_rawgeti_int(lua, buffer_func_table_idx, 2);
  int p1_type = l_rawgeti_int(lua, buffer_func_table_idx, 3);
  int p2_type = l_rawgeti_int(lua, buffer_func_table_idx, 4);
  return l_call_scintilla(lua, editor, msg, p1_type, p2_type, rt_type, 2);
}

/**
 * Metatable index for a buffer table.
 * If the key is a Scintilla buffer function, push a closure so it can be called
 * as a function. If the key is a non-indexable buffer property, call Scintilla
 * to get it. If the key is an indexible buffer property, push a table with a
 * metatable to access buffer property indices.
 * @param lua The Lua State.
 */
static int l_buffer_mt_index(lua_State *lua) {
  const char *key = luaL_checkstring(lua, 2);

  lua_getfield(lua, LUA_REGISTRYINDEX, "functions");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // buffer functions
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { msg, rt_type, p1_type, p2_type }
    lua_pushlightuserdata(lua, (GtkWidget *)focused_editor);
    lua_insert(lua, lua_gettop(lua) - 1); // shift buffer functions down
    lua_pushcclosure(lua, l_call_buffer_function, 2);
    return 1;
  } else lua_pop(lua, 1); // non-table

  lua_getfield(lua, LUA_REGISTRYINDEX, "properties");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // buffer properties
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { get_id, set_id, rt_type, p1_type }
    int msg = l_rawgeti_int(lua, -1, 1); // getter
    int rt_type = l_rawgeti_int(lua, -1, 3);
    int p1_type = l_rawgeti_int(lua, -1, 4);
    if (p1_type != tVOID) { // indexible property
      sptr_t doc = SS(focused_editor, SCI_GETDOCPOINTER, 0, 0);
      lua_newtable(lua);
      lua_pushstring(lua, key);
      lua_setfield(lua, -2, "property");
      lua_pushinteger(lua, doc);
      lua_setfield(lua, -2, "doc_pointer");
      l_mt(lua, "_bufferp_mt", l_bufferp_mt_index, l_bufferp_mt_newindex);
      return 1;
    } else return l_call_scintilla(lua, focused_editor, msg, p1_type, tVOID,
                                   rt_type, 2);
  } else lua_pop(lua, 1); // non-table

  lua_rawget(lua, 1);
  return 1;
}

/**
 * Helper function for the buffer property metatable.
 * Throws an error when trying to write to a read-only property or when trying
 * to read a write-only property.
 * @param lua The Lua State.
 * @param n 1 for getter property, 2 for setter.
 * @param prop String property name.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 *   For setter properties, it is 3 because the index is not an argument. For
 *   getter and setter properties, it is 2 because the index is an argument.
 */
static int l_bufferp_mt_(lua_State *lua, int n, const char *prop, int arg) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "properties");
  lua_getfield(lua, -1, prop);
  lua_remove(lua, -2); // buffer properties
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    int msg = l_rawgeti_int(lua, -1, n); // getter (1) or setter (2)
    int rt_type = (n == 1) ? l_rawgeti_int(lua, -1, 3) : tVOID;
    int p1_type = l_rawgeti_int(lua, -1, (n == 1) ? 4 : 3);
    int p2_type = (n == 2) ? l_rawgeti_int(lua, -1, 4) : tVOID;
    if (n == 2 &&
        (p2_type != tVOID || (p2_type == tVOID && p1_type == tSTRING))) {
      int temp = p1_type;
      p1_type = p2_type;
      p2_type = temp;
    }
    luaL_argcheck(lua, msg != 0, arg,
                  (n == 1) ? "write-only property" : "read-only property");
    return l_call_scintilla(lua, focused_editor, msg, p1_type, p2_type, rt_type,
                            arg);
  } else lua_pop(lua, 1); // non-table

  (lua_gettop(lua) > 2) ? lua_rawset(lua, 1) : lua_rawget(lua, 1);
  return 0;
}

static int l_buffer_mt_newindex(lua_State *lua) {
  return l_bufferp_mt_(lua, 2, lua_tostring(lua, 2), 3);
}

static int l_bufferp_mt_index(lua_State *lua) {
  return l_bufferp_mt_(lua, 1, l_rawget_str(lua, 1, "property"), 2);
}

static int l_bufferp_mt_newindex(lua_State *lua) {
  return l_bufferp_mt_(lua, 2, l_rawget_str(lua, 1, "property"), 2);
}

static int l_view_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "doc_pointer"))
    lua_pushinteger(lua, SS(l_checkview(lua, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (streq(key, "size")) {
    GtkWidget *editor = l_checkview(lua, 1);
    if (GTK_IS_PANED(gtk_widget_get_parent(editor))) {
      int pos = gtk_paned_get_position(
                GTK_PANED(gtk_widget_get_parent(editor)));
      lua_pushinteger(lua, pos);
    } else lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_view_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "size")) {
    GtkWidget *pane = gtk_widget_get_parent(l_checkview(lua, 1));
    int size = luaL_checkinteger(lua, 3);
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
  } else lua_rawset(lua, 1);
  return 0;
}

static int l_gui_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    lua_pushstring(lua, gtk_window_get_title(GTK_WINDOW(window)));
  else if (streq(key, "focused_doc_pointer"))
    lua_pushinteger(lua, SS(focused_editor, SCI_GETDOCPOINTER, 0, 0));
  else if (streq(key, "statusbar_text"))
    lua_pushstring(lua, statusbar_text);
  else if (streq(key, "clipboard_text")) {
    char *text = gtk_clipboard_wait_for_text(
                 gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    if (text) {
      lua_pushstring(lua, text);
      g_free(text);
    } else lua_pushstring(lua, "");
  } else if (streq(key, "size")) {
    lua_newtable(lua);
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
    lua_pushinteger(lua, width);
    lua_rawseti(lua, -2, 1);
    lua_pushinteger(lua, height);
    lua_rawseti(lua, -2, 2);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_gui_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(lua, 3));
  else if (streq(key, "focused_doc_pointer") || streq(key, "clipboard_text"))
    luaL_argerror(lua, 3, "read-only property");
  else if (streq(key, "docstatusbar_text"))
    set_statusbar_text(lua_tostring(lua, 3), 1);
  else if (streq(key, "statusbar_text")) {
    statusbar_text = !lua_isnil(lua, 3) ? lua_tostring(lua, 3) : "";
    set_statusbar_text(statusbar_text, 0);
  } else if (streq(key, "menubar")) {
    luaL_argcheck(lua, lua_istable(lua, 3), 3, "table of menus expected");
    GtkWidget *menubar = gtk_menu_bar_new();
    lua_pushnil(lua);
    while (lua_next(lua, 3)) {
      luaL_argcheck(lua, lua_isuserdata(lua, -1), 3, "table of menus expected");
      GtkWidget *menu_item = l_togtkwidget(lua, -1);
      gtk_menu_bar_append(GTK_MENU_BAR(menubar), menu_item);
      lua_pop(lua, 1); // value
    }
    set_menubar(menubar);
  } else if (streq(key, "size")) {
    luaL_argcheck(lua, lua_istable(lua, 3) && lua_objlen(lua, 3) == 2, 3,
                  "{ width, height } table expected");
    int width = l_rawgeti_int(lua, 3, 1);
    int height = l_rawgeti_int(lua, 3, 2);
    if (width > 0 && height > 0)
      gtk_window_resize(GTK_WINDOW(window), width, height);
  } else lua_rawset(lua, 1);
  return 0;
}

#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
static int l_find_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(find_entry)));
  else if (streq(key, "replace_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(replace_entry)));
  else if (streq(key, "match_case"))
    lua_pushboolean(lua, toggled(match_case_opt));
  else if (streq(key, "whole_word"))
    lua_pushboolean(lua, toggled(whole_word_opt));
  else if (streq(key, "lua"))
    lua_pushboolean(lua, toggled(lua_opt));
  else if (streq(key, "in_files"))
    lua_pushboolean(lua, toggled(in_files_opt));
  else
    lua_rawget(lua, 1);
  return 1;
}

#define toggle(w, b) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), b)
static int l_find_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(lua, 3));
  else if (streq(key, "replace_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(lua, 3));
  else if (streq(key, "match_case"))
    toggle(match_case_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "whole_word"))
    toggle(whole_word_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "lua"))
    toggle(lua_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "in_files"))
    toggle(in_files_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else
    lua_rawset(lua, 1);
  return 0;
}

static int l_ce_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(command_entry)));
  else
    lua_rawget(lua, 1);
  return 1;
}

static int l_ce_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(lua, 3));
  else
    lua_rawset(lua, 1);
  return 0;
}

/******************************************************************************/
/******************             Lua CFunctions             *******************/
/****************** (For documentation, consult the LuaDoc) *******************/
/******************************************************************************/

static int l_cf_buffer_delete(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
  sptr_t doc = l_checkdocpointer(lua, 1);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  if (lua_objlen(lua, -1) > 1)
    l_goto_buffer(focused_editor, -1, FALSE);
  else
    new_buffer(focused_editor, TRUE, TRUE);
  remove_buffer(doc);
  l_emit_event("buffer_deleted", -1);
  l_emit_event("buffer_after_switch", -1);
  return 0;
}

static int l_cf_buffer_new(lua_State *lua) {
  new_buffer(focused_editor, TRUE, TRUE);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_rawgeti(lua, -1, lua_objlen(lua, -1));
  return 1;
}

static int l_cf_buffer_text_range(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
  struct Sci_TextRange tr;
  tr.chrg.cpMin = luaL_checkinteger(lua, 2);
  tr.chrg.cpMax = luaL_checkinteger(lua, 3);
  luaL_argcheck(lua, tr.chrg.cpMin <= tr.chrg.cpMax, 3, "start > end");
  int length = tr.chrg.cpMax - tr.chrg.cpMin;
  char *text = malloc(length + 1);
  tr.lpstrText = text;
  SS(focused_editor, SCI_GETTEXTRANGE, 0, (long)(&tr));
  lua_pushlstring(lua, text, length);
  g_free(text);
  return 1;
}

static int l_cf_view_focus(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  // editor might be an old reference; GTK_IS_WIDGET checks for a valid widget
  if (GTK_IS_WIDGET(editor)) gtk_widget_grab_focus(editor);
  return 0;
}

static int l_cf_view_split(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  int vertical = TRUE;
  if (lua_gettop(lua) > 1) vertical = lua_toboolean(lua, 2) == 1;
  split_view(editor, vertical);
  lua_pushvalue(lua, 1); // old view
  lua_getglobal(lua, "view"); // new view
  return 2;
}

static int l_cf_view_unsplit(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  lua_pushboolean(lua, unsplit_view(editor));
  return 1;
}

#define child1(p) gtk_paned_get_child1(GTK_PANED(p))
#define child2(p) gtk_paned_get_child2(GTK_PANED(p))
#define editor_dpi(editor) \
  l_get_docpointer_index(SS(editor, SCI_GETDOCPOINTER, 0, 0))

void l_create_entry(lua_State *lua, GtkWidget *c1, GtkWidget *c2,
                    int vertical) {
  lua_newtable(lua);
  if (GTK_IS_PANED(c1))
    l_create_entry(lua, child1(c1), child2(c1), GTK_IS_HPANED(c1) == 1);
  else
    lua_pushinteger(lua, editor_dpi(c1));
  lua_rawseti(lua, -2, 1);
  if (GTK_IS_PANED(c2))
    l_create_entry(lua, child1(c2), child2(c2), GTK_IS_HPANED(c2) == 1);
  else
    lua_pushinteger(lua, editor_dpi(c2));
  lua_rawseti(lua, -2, 2);
  lua_pushboolean(lua, vertical);
  lua_setfield(lua, -2, "vertical");
  int size = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(c1)));
  lua_pushinteger(lua, size);
  lua_setfield(lua, -2, "size");
}

static int l_cf_gui_get_split_table(lua_State *lua) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (lua_objlen(lua, -1) > 1) {
    GtkWidget *pane = gtk_widget_get_parent(focused_editor);
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_create_entry(lua, child1(pane), child2(pane), GTK_IS_HPANED(pane) == 1);
  } else lua_pushinteger(lua, editor_dpi(focused_editor));
  return 1;
}

static int l_cf_gui_goto_(lua_State *lua, GtkWidget *editor, int buffer) {
  int n = luaL_checkinteger(lua, 1);
  int abs = (lua_gettop(lua) > 1) ? lua_toboolean(lua, 2) == 1 : TRUE;
  buffer ? l_goto_buffer(editor, n, abs) : l_goto_view(editor, n, abs);
  return 0;
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
static int l_cf_view_goto_buffer(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  int switch_focus = editor != focused_editor;
  GtkWidget *orig_focused_editor = focused_editor;
  if (switch_focus) SS(editor, SCI_SETFOCUS, TRUE, 0);
  lua_remove(lua, 1); // view table
  l_emit_event("buffer_before_switch", -1);
  l_cf_gui_goto_(lua, editor, TRUE);
  l_emit_event("buffer_after_switch", -1);
  if (switch_focus) {
    SS(editor, SCI_SETFOCUS, FALSE, 0);
    gtk_widget_grab_focus(orig_focused_editor);
  }
  return 0;
}

static int l_cf_gui_dialog(lua_State *lua) {
  GCDialogType type = gcocoadialog_type(luaL_checkstring(lua, 1));
  int i, j, k, n = lua_gettop(lua) - 1, argc = n;
  for (i = 2; i < n + 2; i++)
    if (lua_type(lua, i) == LUA_TTABLE) argc += lua_objlen(lua, i) - 1;
  const char **argv = malloc(argc * sizeof(const char *));
  for (i = 0, j = 2; j < n + 2; j++)
    if (lua_type(lua, j) == LUA_TTABLE) {
      int len = lua_objlen(lua, j);
      for (k = 1; k <= len; k++) {
        lua_rawgeti(lua, j, k);
        argv[i++] = luaL_checkstring(lua, -1);
        lua_pop(lua, 1);
      }
    } else argv[i++] = luaL_checkstring(lua, j);
  char *out = gcocoadialog(type, argc, argv);
  lua_pushstring(lua, out);
  free(out);
  free(argv);
  return 1;
}

static int l_cf_gui_goto_view(lua_State *lua) {
  return l_cf_gui_goto_(lua, focused_editor, FALSE);
}

static void t_menu_activate(GtkWidget *menu, gpointer id) {
  l_emit_event("menu_clicked", LUA_TNUMBER, GPOINTER_TO_INT(id), -1);
}

static int l_cf_gui_gtkmenu(lua_State *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkWidget *menu = l_create_gtkmenu(lua, G_CALLBACK(t_menu_activate), FALSE);
  lua_pushlightuserdata(lua, (GtkWidget *)menu);
  return 1;
}

static int l_cf_string_iconv(lua_State *lua) {
  size_t text_len = 0, conv_len = 0;
  const char *text = luaL_checklstring(lua, 1, &text_len);
  const char *to = luaL_checkstring(lua, 2);
  const char *from = luaL_checkstring(lua, 3);
  char *converted = g_convert(text, text_len, to, from, NULL, &conv_len, NULL);
  if (converted) {
    lua_pushlstring(lua, converted, conv_len);
    g_free(converted);
  } else luaL_error(lua, "Conversion failed");
  return 1;
}

static int l_cf_quit(lua_State *lua) {
  GdkEventAny event;
  event.type = GDK_DELETE;
  event.window = window->window;
  event.send_event = TRUE;
  gdk_event_put((GdkEvent *)(&event));
  return 0;
}

static int l_cf_reset(lua_State *lua) {
  l_emit_event("reset_before", -1);
  l_init(0, NULL, TRUE);
  lua_pushboolean(lua, TRUE);
  lua_setglobal(lua, "RESETTING");
  l_load_script("init.lua");
  lua_pushnil(lua);
  lua_setglobal(lua, "RESETTING");
  l_set_view_global(focused_editor);
  l_set_buffer_global(focused_editor);
  l_emit_event("reset_after", -1);
  return 0;
}

static gbool emit_timeout(gpointer data) {
  int *refs = (int *)data;
  lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
  int nargs = 0, repeat = TRUE;
  while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
  l_call_function(nargs - 1, 1, TRUE);
  if (lua_toboolean(lua, -1) == 0 || lua_isnil(lua, -1)) {
    while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
    repeat = FALSE;
  }
  lua_pop(lua, 1); // boolean or nil
  return repeat;
}

static int l_cf_timeout(lua_State *lua) {
  int timeout = luaL_checkinteger(lua, 1);
  luaL_argcheck(lua, timeout > 0, 1, "timeout must be > 0");
  luaL_argcheck(lua, lua_isfunction(lua, 2), 2, "function expected");
  int n = lua_gettop(lua);
  int *refs = (int *)calloc(n, sizeof(int));
  lua_pushvalue(lua, 2);
  refs[0] = luaL_ref(lua, LUA_REGISTRYINDEX);
  for (int i = 3; i <= n; i++) {
    lua_pushvalue(lua, i);
    refs[i - 2] = luaL_ref(lua, LUA_REGISTRYINDEX);
  }
  g_timeout_add_seconds(timeout, emit_timeout, (gpointer)refs);
  return 0;
}

static int l_cf_find_focus(lua_State *lua) {
  find_toggle_focus();
  return 0;
}

#define emit(o, s) { \
  g_signal_emit_by_name(G_OBJECT(o), s); \
  return 0; \
}
static int l_cf_find_next(lua_State *lua) { emit(fnext_button, "clicked") }
static int l_cf_find_prev(lua_State *lua) { emit(fprev_button, "clicked") }
static int l_cf_find_replace(lua_State *lua) { emit(r_button, "clicked") }
static int l_cf_find_replace_all(lua_State *lua) { emit(ra_button, "clicked") }

static int l_cf_ce_focus(lua_State *lua) {
  ce_toggle_focus();
  return 0;
}

static int l_cf_ce_show_completions(lua_State *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkEntryCompletion *completion = gtk_entry_get_completion(
                                   GTK_ENTRY(command_entry));
  GtkListStore *store = GTK_LIST_STORE(
                        gtk_entry_completion_get_model(completion));
  gtk_list_store_clear(store);
  lua_pushnil(lua);
  while (lua_next(lua, 1)) {
    if (lua_type(lua, -1) == LUA_TSTRING) {
      GtkTreeIter iter;
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, 0, lua_tostring(lua, -1), -1);
    } else warn("command_entry.show_completions: non-string value ignored");
    lua_pop(lua, 1); // value
  }
  gtk_entry_completion_complete(completion);
  return 0;
}

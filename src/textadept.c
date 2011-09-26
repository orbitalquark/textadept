// Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>

#define PLAT_GTK 1
#include "Scintilla.h"
#include "SciLexer.h"
#include "ScintillaWidget.h"

#include "gcocoadialog.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#if __WIN32__
#include <windows.h>
#define main main_
#elif __OSX__
#include <Carbon/Carbon.h>
#include "igemacintegration/ige-mac-menu.h"
#define GDK_MOD1_MASK 1 << 7 // Alt/option key (1 << 7 == GDK_MOD5_MASK)
#define GDK_MOD5_MASK 1 << 3 // Command key (1 << 3 == GDK_MOD1_MASK)
#elif __BSD__
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

#define SS(view, m, w, l) scintilla_send_message(SCINTILLA(view), m, w, l)
#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)

// Defines for different GTK versions.
#if !(GTK_CHECK_VERSION(2,18,0) || GTK_CHECK_VERSION(3,0,0))
#define gtk_widget_set_can_default(w,_) GTK_WIDGET_SET_FLAGS(w, GTK_CAN_DEFAULT)
#define gtk_widget_set_can_focus(w,_) GTK_WIDGET_UNSET_FLAGS(w, GTK_CAN_FOCUS)
#define gtk_widget_get_allocation(e, a) \
  ((a)->width = e->allocation.width, (a)->height = e->allocation.height)
#define gtk_widget_has_focus GTK_WIDGET_HAS_FOCUS
#define gtk_widget_get_visible GTK_WIDGET_VISIBLE
#define gtk_widget_get_window(w) w->window
#endif
#if GTK_CHECK_VERSION(3,0,0)
#define gtk_statusbar_set_has_resize_grip(_,__)
#define gtk_combo_box_entry_new_with_model(m,_) \
  gtk_combo_box_new_with_model_and_entry(m)
#define gtk_combo_box_entry_set_text_column gtk_combo_box_set_entry_text_column
#define GTK_COMBO_BOX_ENTRY GTK_COMBO_BOX
#endif

/******************************************************************************/
/***************************** Forward Declarations ***************************/
/******************************************************************************/

// Window
GtkWidget *window, *focused_view, *menubar, *statusbar[2];
GtkAccelGroup *accel;
char *textadept_home;
static void new_window();
static GtkWidget *new_view(sptr_t);
static void new_buffer(sptr_t);
static void s_notify(GtkWidget *, gint, gpointer, gpointer);
static void s_command(GtkWidget *, gint, gpointer, gpointer);
static gboolean s_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gboolean s_buttonpress(GtkWidget *, GdkEventButton *, gpointer);
static gboolean w_focus(GtkWidget *, GdkEventFocus *, gpointer);
static gboolean w_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gboolean w_exit(GtkWidget *, GdkEventAny *, gpointer);
#if __OSX__
static OSErr w_ae_open(const AppleEvent *, AppleEvent *, long);
static OSErr w_ae_quit(const AppleEvent *, AppleEvent *, long);
#endif

// Find/Replace
GtkWidget *findbox, *find_entry, *replace_entry, *fnext_button, *fprev_button,
          *r_button, *ra_button, *match_case_opt, *whole_word_opt, *lua_opt,
          *in_files_opt, *flabel, *rlabel;
GtkListStore *find_store, *repl_store;
static GtkWidget *new_findbox();
static void f_clicked(GtkWidget *, gpointer);

// Command Entry
GtkWidget *command_entry;
GtkListStore *cc_store;
GtkEntryCompletion *command_entry_completion;
static int cc_matchfunc(GtkEntryCompletion *, const char *, GtkTreeIter *,
                        gpointer);
static gboolean cc_matchselected(GtkEntryCompletion *, GtkTreeModel *,
                                 GtkTreeIter *, gpointer);
static void c_activate(GtkWidget *, gpointer);
static gboolean c_keypress(GtkWidget *, GdkEventKey *, gpointer);

// Lua
lua_State *lua;
int closing = FALSE;
char *statusbar_text = 0;
static int tVOID = 0, tINT = 1, tLENGTH = 2, /*tPOSITION = 3, tCOLOUR = 4,*/
           tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;
static int lL_init(lua_State *, int, char **, int);
static void l_close(lua_State *);
static int lL_dofile(lua_State *, const char *);
static void lL_addview(lua_State *, GtkWidget *);
static void lL_removeview(lua_State *, GtkWidget *);
static void lL_adddoc(lua_State *, sptr_t);
static void lL_removedoc(lua_State *, sptr_t);
static void lL_gotodoc(lua_State *, GtkWidget *, int, int);
static int lL_event(lua_State *, const char *, ...);
static void lL_notify(lua_State *, struct SCNotification *);
static void lL_showcontextmenu(lua_State *, GdkEventButton *);
static void lL_cleartable(lua_State *, int);
static void l_pushview(lua_State *, GtkWidget *);
static void l_pushdoc(lua_State *, sptr_t);
#define l_setglobalview(l, v) (l_pushview(l, v), lua_setglobal(l, "view"))
#define l_setglobaldoc(l, d) (l_pushdoc(l, d), lua_setglobal(l, "buffer"))
LUALIB_API int (luaopen_lpeg) (lua_State *);
LUALIB_API int (luaopen_lfs) (lua_State *);
static int lbuf_property(lua_State *),
           lview__index(lua_State *), lview__newindex(lua_State *),
           lgui__index(lua_State *), lgui__newindex(lua_State *),
           lfind__index(lua_State *), lfind__newindex(lua_State *),
           lce__index(lua_State *), lce__newindex(lua_State *),
           lbuffer_check_global(lua_State *), lbuffer_delete(lua_State *),
           lbuffer_new(lua_State *), lbuffer_text_range(lua_State *),
           lview_split(lua_State *), lview_unsplit(lua_State *),
           lgui_dialog(lua_State *), lgui_get_split_table(lua_State *),
           lgui_goto_view(lua_State *), lview_goto_buffer(lua_State *),
           lgui_gtkmenu(lua_State *), lstring_iconv(lua_State *),
           lquit(lua_State *), lreset(lua_State *), ltimeout(lua_State *),
           lfind_focus(lua_State *), lfind_next(lua_State *),
           lfind_prev(lua_State *), lfind_replace(lua_State *),
           lfind_replace_all(lua_State *),
           lce_focus(lua_State *), lce_show_completions(lua_State *);

/******************************************************************************/
/******************************* GUI Interface ********************************/
/******************************************************************************/

/**
 * Runs Textadept in Linux or Mac.
 * Inits the Lua state, creates the user interface, and then runs core/init.lua
 * followed by init.lua.
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
    CFRelease(path), CFRelease(bundle);
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
  if (lua = lua_open(), !lL_init(lua, argc, argv, FALSE)) return 1;
  new_window();
  lL_dofile(lua, "init.lua");
  gtk_main();
  free(textadept_home);
  return 0;
}

#if __WIN32__
/**
 * Runs Textadept in Windows.
 * @see main
 */
int WINAPI WinMain(HINSTANCE _, HINSTANCE __, LPSTR lpCmdLine, int ___) {
  textadept_home = malloc(FILENAME_MAX);
  GetModuleFileName(0, textadept_home, FILENAME_MAX);
  return main(1, &lpCmdLine);
}
#endif

/**
 * Creates the Textadept window.
 * The window contains a menubar, frame for Scintilla views, hidden find box,
 * hidden command entry, and two status bars: one for notifications and the
 * other for buffer status.
 */
static void new_window() {
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
  accel = gtk_accel_group_new();

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

  GtkWidget *view = new_view(0);
  gtk_box_pack_start(GTK_BOX(hbox), view, TRUE, TRUE, 0);

  GtkWidget *find = new_findbox();
  gtk_box_pack_start(GTK_BOX(vbox), find, FALSE, FALSE, 5);

  command_entry = gtk_entry_new();
  gtk_widget_set_name(command_entry, "textadept-command-entry");
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
#if __OSX__
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar[1]), FALSE);
#endif
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar[1], FALSE, FALSE, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar); // hide initially
  gtk_widget_hide(findbox); // hide initially
  gtk_widget_hide(command_entry); // hide initially
}

/**
 * Creates a new Scintilla view.
 * Generates a 'view_new' event.
 * @param doc The document to load in the new view. Almost never zero, except
 *   for the first Scintilla view created, in which there is no doc pointer.
 * @return Scintilla view
 * @see lL_addview
 */
static GtkWidget *new_view(sptr_t doc) {
  GtkWidget *view = scintilla_new();
  gtk_widget_set_size_request(view, 1, 1); // minimum size
  SS(view, SCI_USEPOPUP, 0, 0);
  signal(view, SCINTILLA_NOTIFY, s_notify);
  signal(view, "command", s_command);
  signal(view, "key-press-event", s_keypress);
  signal(view, "button-press-event", s_buttonpress);
  lL_addview(lua, view);
  gtk_widget_grab_focus(view);
  focused_view = view;
  if (doc) {
    SS(view, SCI_SETDOCPOINTER, 0, doc);
    l_setglobaldoc(lua, doc);
  } else new_buffer(SS(view, SCI_GETDOCPOINTER, 0, 0));
  l_setglobalview(lua, view);
  lL_event(lua, "view_new", -1);
  return view;
}

/**
 * Removes a Scintilla view.
 * @param view The Scintilla view to remove.
 * @see lL_removeview
 */
static void delete_view(GtkWidget *view) {
  lL_removeview(lua, view);
  gtk_widget_destroy(view);
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

/**
 * Removes the Scintilla buffer from the current Scintilla view.
 * @param doc The Scintilla document.
 * @see lL_removedoc
 */
static void delete_buffer(sptr_t doc) {
  lL_removedoc(lua, doc);
  SS(focused_view, SCI_RELEASEDOCUMENT, 0, doc);
}

/**
 * Splits the given Scintilla view into two views.
 * The new view shows the same document as the original one.
 * @param view The Scintilla view to split.
 * @param vertical Flag indicating whether to split the view vertically or
 *   horozontally.
 */
static void split_view(GtkWidget *view, int vertical) {
  g_object_ref(view);
  int first_line = SS(view, SCI_GETFIRSTVISIBLELINE, 0, 0);
  int current_pos = SS(view, SCI_GETCURRENTPOS, 0, 0);
  int anchor = SS(view, SCI_GETANCHOR, 0, 0);
  GtkAllocation allocation;
  gtk_widget_get_allocation(view, &allocation);
  int middle = (vertical ? allocation.width : allocation.height) / 2;

  sptr_t curdoc = SS(view, SCI_GETDOCPOINTER, 0, 0);
  GtkWidget *view2 = new_view(curdoc);
  GtkWidget *parent = gtk_widget_get_parent(view);
  gtk_container_remove(GTK_CONTAINER(parent), view);
  GtkWidget *pane = vertical ? gtk_hpaned_new() : gtk_vpaned_new();
  gtk_paned_add1(GTK_PANED(pane), view), gtk_paned_add2(GTK_PANED(pane), view2);
  gtk_container_add(GTK_CONTAINER(parent), pane);
  gtk_paned_set_position(GTK_PANED(pane), middle);
  gtk_widget_show_all(pane);
  gtk_widget_grab_focus(view2);

  SS(view2, SCI_SETSEL, anchor, current_pos);
  int new_first_line = SS(view2, SCI_GETFIRSTVISIBLELINE, 0, 0);
  SS(view2, SCI_LINESCROLL, first_line - new_first_line, 0);
  g_object_unref(view);
}

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

/**
 * Unsplits the pane a given Scintilla view is in and keeps the view.
 * All views in the other pane are deleted.
 * @param view The Scintilla view to keep when unsplitting.
 * @see remove_views_from_pane
 * @see delete_view
 */
static int unsplit_view(GtkWidget *view) {
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
}

/******************************************************************************/
/************************* GUI Notifications/Signals **************************/
/******************************************************************************/

/**
 * Change focus to the given Scintilla view.
 * Generates 'view_before_switch' and 'view_after_switch' events.
 * @param view The Scintilla view to focus.
 */
static void goto_view(GtkWidget *view) {
  if (!closing) lL_event(lua, "view_before_switch", -1);
  focused_view = view;
  l_setglobalview(lua, view);
  l_setglobaldoc(lua, SS(view, SCI_GETDOCPOINTER, 0, 0));
  if (!closing) lL_event(lua, "view_after_switch", -1);
}

/**
 * Signal for a Scintilla notification.
 */
static void s_notify(GtkWidget *view, gint _, gpointer lParam, gpointer __) {
  struct SCNotification *n = (struct SCNotification *)lParam;
  if (focused_view == view || n->nmhdr.code == SCN_URIDROPPED) {
    if (focused_view != view) goto_view(view);
    lL_notify(lua, n);
  } else if (n->nmhdr.code == SCN_SAVEPOINTLEFT) {
    GtkWidget *prev = focused_view;
    goto_view(view);
    lL_notify(lua, n);
    goto_view(prev); // do not let a split view steal focus
  }
}

/**
 * Signal for a Scintilla command.
 * Currently handles SCEN_SETFOCUS.
 */
static void s_command(GtkWidget *view, gint wParam, gpointer _, gpointer __) {
  if (wParam >> 16 == SCEN_SETFOCUS) goto_view(view);
}

/**
 * Signal for a Scintilla keypress.
 */
static gboolean s_keypress(GtkWidget *view, GdkEventKey *event, gpointer _) {
  return lL_event(lua, "keypress", LUA_TNUMBER, event->keyval, LUA_TBOOLEAN,
                  event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN,
                  event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD1_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD5_MASK, -1);
}

/**
 * Signal for a Scintilla mouse click.
 */
static gboolean s_buttonpress(GtkWidget*_, GdkEventButton *event, gpointer __) {
  if (event->type == GDK_BUTTON_PRESS && event->button == 3)
    return (lL_showcontextmenu(lua, event), TRUE);
  return FALSE;
}

/**
 * Signal for a Textadept window focus change.
 */
static gboolean w_focus(GtkWidget*_, GdkEventFocus *event, gpointer __) {
  if (focused_view && !gtk_widget_has_focus(focused_view))
    gtk_widget_grab_focus(focused_view);
  return FALSE;
}

/**
 * Signal for a Textadept keypress.
 * Currently handled keypresses:
 *  - Escape: hides the find box if it is open.
 */
static gboolean w_keypress(GtkWidget*_, GdkEventKey *event, gpointer __) {
  if (event->keyval == 0xff1b && gtk_widget_get_visible(findbox) &&
      !gtk_widget_has_focus(command_entry)) {
    gtk_widget_hide(findbox);
    gtk_widget_grab_focus(focused_view);
    return TRUE;
  } else return FALSE;
}

/**
 * Signal for exiting Textadept.
 * Generates a 'quit' event.
 * Closes the Lua state and releases resources.
 * @see l_close
 */
static gboolean w_exit(GtkWidget*_, GdkEventAny*__, gpointer ___) {
  if (!lL_event(lua, "quit", -1)) return TRUE;
  l_close(lua);
  scintilla_release_resources();
  gtk_main_quit();
  return FALSE;
}

#if __OSX__
/**
 * Signal for an Open Document AppleEvent.
 * Generates an 'appleevent_odoc' event for each document sent.
 */
static OSErr w_ae_open(const AppleEvent *event, AppleEvent*_, long __) {
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
        lL_event(lua, "appleevent_odoc", LUA_TSTRING, p, -1);
        CFRelease(path), CFRelease(url);
      }
    }
    AEDisposeDesc(&file_list);
  }
  return noErr;
}

/**
 * Signal for a Quit Application AppleEvent.
 */
static OSErr w_ae_quit(const AppleEvent*_, AppleEvent*__, long ___) {
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
 * Creates the Find box.
 */
static GtkWidget *new_findbox() {
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
  gtk_widget_set_name(find_entry, "textadept-find-entry");
  gtk_entry_set_activates_default(GTK_ENTRY(find_entry), TRUE);
  GtkWidget *replace_combo = gtk_combo_box_entry_new_with_model(
                             GTK_TREE_MODEL(repl_store), 0);
  gtk_combo_box_entry_set_text_column(GTK_COMBO_BOX_ENTRY(replace_combo), 0);
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
  in_files_opt = gtk_check_button_new_with_mnemonic("_In files");

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

  signal(fnext_button, "clicked", f_clicked);
  signal(fprev_button, "clicked", f_clicked);
  signal(r_button, "clicked", f_clicked);
  signal(ra_button, "clicked", f_clicked);

  gtk_widget_set_can_default(fnext_button, TRUE);
  gtk_widget_set_can_focus(fnext_button, FALSE);
  gtk_widget_set_can_focus(fprev_button, FALSE);
  gtk_widget_set_can_focus(r_button, FALSE);
  gtk_widget_set_can_focus(ra_button, FALSE);
  gtk_widget_set_can_focus(match_case_opt, FALSE);
  gtk_widget_set_can_focus(whole_word_opt, FALSE);
  gtk_widget_set_can_focus(lua_opt, FALSE);
  gtk_widget_set_can_focus(in_files_opt, FALSE);

  return findbox;
}

/******************************************************************************/
/**************************** Find/Replace Signals ****************************/
/******************************************************************************/

/**
 * Adds the given text to the find/replace history list if it is not at the top.
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

/**
 * Signal for a find box button click.
 */
static void f_clicked(GtkWidget *button, gpointer _) {
  const char *find_text = gtk_entry_get_text(GTK_ENTRY(find_entry));
  const char *repl_text = gtk_entry_get_text(GTK_ENTRY(replace_entry));
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

/******************************************************************************/
/************************ Command Entry GUI Interface *************************/
/******************************************************************************/

/**
 * The match function for the command entry.
 * Since the completion list is filled by Lua, every item is a "match".
 */
static int cc_matchfunc(GtkEntryCompletion*_, const char *__, GtkTreeIter*___,
                        gpointer ____) { return 1; }

/**
 * Replaces the current word (consisting of alphanumeric and underscore
 * characters) with the match text.
 */
static gboolean cc_matchselected(GtkEntryCompletion*_, GtkTreeModel *model,
                                 GtkTreeIter *iter, gpointer __) {
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

/******************************************************************************/
/*************************** Command Entry Signals ****************************/
/******************************************************************************/

/**
 * Signal for the 'enter' key being pressed in the Command Entry.
 */
static void c_activate(GtkWidget *entry, gpointer _) {
  lL_event(lua, "command_entry_command", LUA_TSTRING,
           gtk_entry_get_text(GTK_ENTRY(entry)), -1);
}

/**
 * Signal for a keypress inside the Command Entry.
 */
static gboolean c_keypress(GtkWidget*_, GdkEventKey *event, gpointer __) {
  return lL_event(lua, "command_entry_keypress", LUA_TNUMBER, event->keyval,
                  LUA_TBOOLEAN, event->state & GDK_SHIFT_MASK, LUA_TBOOLEAN,
                  event->state & GDK_CONTROL_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD1_MASK, LUA_TBOOLEAN,
                  event->state & GDK_MOD5_MASK, -1);
}

/******************************************************************************/
/******************************** Lua Interface *******************************/
/******************************************************************************/

#define lL_openlib(l, n, f) \
  (lua_pushcfunction(l, f), lua_pushstring(l, n), lua_call(l, 1, 0))
#define l_setcfunction(l, n, k, f) \
  (lua_pushcfunction(l, f), lua_setfield(l, (n > 0) ? n : n - 1, k))
#define l_setmetatable(l, n, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_setcfunction(l, -1, "__index", i); \
    l_setcfunction(l, -1, "__newindex", ni); \
  } \
  lua_setmetatable(l, (n > 0) ? n : n - 1); \
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
    lL_cleartable(L, lua_gettop(L));
    lua_pop(L, 2); // package and package.loaded
    lL_cleartable(L, LUA_GLOBALSINDEX);
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
  l_setcfunction(L, -1, "gtkmenu", lgui_gtkmenu);
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
  const char *charset = 0;
  g_get_charset(&charset);
  lua_pushstring(L, charset), lua_setglobal(L, "_CHARSET");

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

/**
 * Loads and runs the given file.
 * @param L The Lua state.
 * @param filename The file name relative to textadept_home.
 * @return 1 if there are no errors or 0 in case of errors.
 */
static int lL_dofile(lua_State *L, const char *filename) {
  char *file = g_strconcat(textadept_home, "/", filename, NULL);
  int ok = (luaL_dofile(L, file) == 0);
  if (!ok) {
    GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                               GTK_MESSAGE_ERROR,
                                               GTK_BUTTONS_OK, "%s\n",
                                               lua_tostring(L, -1));
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    lua_settop(L, 0);
  }
  g_free(file);
  return ok;
}

/**
 * Returns the view at the given acceptable index as a Scintilla view.
 * @param L The Lua state.
 * @param index Stack index of the view.
 * @return Scintilla view
 */
static GtkWidget *l_toview(lua_State *L, int index) {
  lua_getfield(L, index, "widget_pointer");
  GtkWidget *view = (GtkWidget *)lua_touserdata(L, -1);
  lua_pop(L, 1); // widget pointer
  return view;
}

/**
 * Adds the Scintilla view with a metatable to the 'views' registry table.
 * @param L The Lua state.
 * @param view The Scintilla view to add.
 */
static void lL_addview(lua_State *L, GtkWidget *view) {
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
  lua_pushvalue(L, -1), lua_rawseti(L, -3, lua_objlen(L, -3) + 1);
  lua_pushinteger(L, lua_objlen(L, -2)), lua_settable(L, -3);
  lua_pop(L, 1); // views
}

/**
 * Removes the Scintilla view from the 'views' registry table.
 * The view must have been previously added with lL_addview.
 * @param L The Lua state.
 * @param view The Scintilla view to remove.
 * @see lL_addview
 */
static void lL_removeview(lua_State *L, GtkWidget *view) {
  lua_newtable(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (lua_isnumber(L, -2) && view != l_toview(L, -1)) {
      lua_getfield(L, -1, "widget_pointer");
      // vs[userdata] = v, vs[#vs + 1] = v, vs[v] = #vs
      lua_pushvalue(L, -2), lua_rawseti(L, -6, lua_objlen(L, -6) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -6);
      lua_pushinteger(L, lua_objlen(L, -4)), lua_settable(L, -5);
    } else lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // views
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_setglobal(L, "_VIEWS");
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
  lua_pushvalue(L, -1), lua_rawseti(L, -3, lua_objlen(L, -3) + 1);
  lua_pushinteger(L, lua_objlen(L, -2)), lua_settable(L, -3);
  lua_pop(L, 1); // buffers
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
      GtkWidget *view = l_toview(L, -1);
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
      lua_pushvalue(L, -2), lua_rawseti(L, -6, lua_objlen(L, -6) + 1);
      lua_pushvalue(L, -2), lua_settable(L, -6);
      lua_pushinteger(L, lua_objlen(L, -4)), lua_settable(L, -5);
    } else lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // buffers
  lua_pushvalue(L, -1), lua_setfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_setglobal(L, "_BUFFERS");
}

/**
 * Switches to a document in the given view.
 * @param L The Lua state.
 * @param view The Scintilla view.
 * @param n Relative or absolute index of the document to switch to. An absolute
 *   n of -1 represents the last document.
 * @param relative Flag indicating whether or not n is relative.
 */
static void lL_gotodoc(lua_State *L, GtkWidget *view, int n, int relative) {
  if (relative && n == 0) return;
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (relative) {
    l_pushdoc(L, SS(view, SCI_GETDOCPOINTER, 0, 0)), lua_gettable(L, -2);
    n = lua_tointeger(L, -1) + n;
    lua_pop(L, 1); // index
    if (n > lua_objlen(L, -1))
      n = 1;
    else if (n < 1)
      n = lua_objlen(L, -1);
    lua_rawgeti(L, -1, n);
  } else {
    luaL_argcheck(L, (n > 0 && n <= lua_objlen(L, -1)) || n == -1, 2,
                  "no Buffer exists at that index");
    lua_rawgeti(L, -1, (n > 0) ? n : lua_objlen(L, -1));
  }
  sptr_t doc = l_todoc(L, -1);
  SS(view, SCI_SETDOCPOINTER, 0, doc);
  l_setglobaldoc(L, doc);
  lua_pop(L, 2); // buffer table and buffers
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
  gtk_widget_destroy(focused_view);
  lua_close(L);
}

/******************************************************************************/
/*************************** Lua Utility Functions ****************************/
/******************************************************************************/

/**
 * Clears a table at the given valid index by setting all of its keys to nil.
 * Cannot be called with a pseudo-index.
 * @param L The Lua state.
 * @param index The stack index of the table.
 */
static void lL_cleartable(lua_State *L, int index) {
  lua_pushnil(L);
  while (lua_next(L, index)) {
    lua_pop(L, 1); // value
    lua_pushnil(L), lua_rawset(L, index);
    lua_pushnil(L); // get 'new' first key
  }
}

/**
 * Pushes the Scintilla view onto the stack.
 * The view must have previously been added with lL_addview.
 * @param L The Lua state.
 * @param view The Scintilla view to push.
 * @see lL_addview
 */
static void l_pushview(lua_State *L, GtkWidget *view) {
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  lua_pushlightuserdata(L, view), lua_gettable(L, -2);
  lua_remove(L, -2); // views
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
 * Prints a warning.
 * @param s The warning to print.
 */
static void warn(const char *s) { printf("Warning: %s\n", s); }

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
 * Returns the value t[k] as a string where t is the value at the given valid
 * index.
 * The access is raw; that is, it does not invoke metamethods.
 * @param L The Lua state.
 * @param index The stack index of the table.
 * @param k String key in the table to get.
 * @return string
 */
static const char *l_rawgetstr(lua_State *L, int index, const char *k) {
  lua_pushstring(L, k);
  lua_rawget(L, index);
  const char *str = lua_tostring(L, -1);
  lua_pop(L, 1); // string
  return str;
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
 * Checks whether the function argument narg is a Scintilla view and returns
 * this view cast to a GtkWidget.
 * @param L The Lua state.
 * @param narg The stack index of the Scintilla view.
 * @return Scintilla view
 */
static GtkWidget *lL_checkview(lua_State *L, int narg) {
  luaL_getmetatable(L, "ta_view");
  lua_getmetatable(L, narg);
  luaL_argcheck(L, lua_equal(L, -1, -2), narg, "View expected");
  lua_getfield(L, (narg > 0) ? narg : narg - 2, "widget_pointer");
  GtkWidget *view = (GtkWidget *)lua_touserdata(L, -1);
  lua_pop(L, 3); // widget_pointer, metatable, metatable
  return view;
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
  luaL_argcheck(L, lua_equal(L, -1, -2), narg, "Buffer expected");
  lua_getfield(L, (narg > 0) ? narg : narg - 2, "doc_pointer");
  sptr_t doc = (sptr_t)lua_touserdata(L, -1);
  luaL_argcheck(L, doc == SS(focused_view, SCI_GETDOCPOINTER, 0, 0), narg,
                "this buffer is not the current one");
  lua_pop(L, 3); // doc_pointer, metatable, metatable
}

/**
 * Pushes a GTK menu created from the table at the given valid index onto the
 * stack.
 * Consult the LuaDoc for the table format.
 * @param L The Lua state.
 * @param index The stack index of the table to create the menu from.
 * @param callback A GCallback associated with each menu item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 */
static void l_pushgtkmenu(lua_State *L, int index, GCallback callback,
                          int submenu) {
  GtkWidget *menu = gtk_menu_new(), *menu_item = 0, *submenu_root = 0;
  const char *label;
  lua_pushvalue(L, index); // copy to stack top so pseudo-indices can be used
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
        l_pushgtkmenu(L, -1, callback, TRUE);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              (GtkWidget *)lua_touserdata(L, -1));
        lua_pop(L, 1); // gtkmenu
      } else if (lua_objlen(L, -1) == 2 || lua_objlen(L, -1) == 4) {
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
          g_signal_connect(menu_item, "activate", callback,
                           GINT_TO_POINTER(menu_id));
          gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
        }
      } else warn("gtkmenu: { 'label', id_num [, keycode, mods] } expected");
    }
    lua_pop(L, 1); // value
  }
  lua_pop(L, 1); // table copy
  lua_pushlightuserdata(L, !submenu_root ? menu : submenu_root);
}

/******************************************************************************/
/********************** Lua Notifications/Event Handlers **********************/
/******************************************************************************/

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
      if (lua_pcall(L, n, 1, 0) == 0)
        ret = lua_toboolean(L, -1);
      else
        lL_event(L, "error", LUA_TSTRING, lua_tostring(L, -1), -1);
      lua_pop(L, 1); // result
    } else lua_pop(L, 1); // non-function
  } else lua_pop(L, 1); // non-table
  return ret;
}

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
 * Shows the context menu for a Scintilla view based on a mouse event.
 * @param L The Lua state.
 * @param event The mouse button event.
 */
static void lL_showcontextmenu(lua_State *L, GdkEventButton *event) {
  lua_getglobal(L, "gui");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "context_menu");
    if (lua_isuserdata(L, -1)) {
      GtkWidget *menu = (GtkWidget *)lua_touserdata(L, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? event->button : 0,
                     gdk_event_get_time((GdkEvent *)event));
    } else if (!lua_isnil(L, -1))
      warn("gui.context_menu: gtkmenu expected");
    lua_pop(L, 1); // gui.context_menu
  } else lua_pop(L, 1); // non-table
}

/******************************************************************************/
/*********************           Lua Functions            *********************/
/********************* (Stack Maintenence is Unnecessary) *********************/
/******************************************************************************/

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
    wparam = (uptr_t)lua_strlen(L, arg);
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
  g_free(return_string);
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
  int is_buffer = lua_equal(L, -1, -2);
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

static int lview__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "buffer") == 0)
    l_pushdoc(L, SS(lL_checkview(L, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (strcmp(key, "size") == 0) {
    GtkWidget *view = lL_checkview(L, 1);
    if (GTK_IS_PANED(gtk_widget_get_parent(view))) {
      int pos = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(view)));
      lua_pushinteger(L, pos);
    } else lua_pushnil(L);
  } else lua_rawget(L, 1);
  return 1;
}

static int lview__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "buffer") == 0)
    luaL_argerror(L, 3, "read-only property");
  else if (strcmp(key, "size") == 0) {
    GtkWidget *pane = gtk_widget_get_parent(lL_checkview(L, 1));
    int size = luaL_checkinteger(L, 3);
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
  } else lua_rawset(L, 1);
  return 0;
}

static int lgui__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0)
    lua_pushstring(L, gtk_window_get_title(GTK_WINDOW(window)));
  else if (strcmp(key, "statusbar_text") == 0)
    lua_pushstring(L, statusbar_text);
  else if (strcmp(key, "clipboard_text") == 0) {
    char *text = gtk_clipboard_wait_for_text(
                 gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    lua_pushstring(L, text ? text : "");
    if (text) g_free(text);
  } else if (strcmp(key, "size") == 0) {
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
    lua_newtable(L);
    lua_pushinteger(L, width), lua_rawseti(L, -2, 1);
    lua_pushinteger(L, height), lua_rawseti(L, -2, 2);
  } else lua_rawget(L, 1);
  return 1;
}

static void set_statusbar_text(const char *text, int bar) {
  if (!statusbar[0] || !statusbar[1]) return; // unavailable on startup
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar[bar]), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar[bar]), 0, text);
}

static int lgui__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "title") == 0)
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(L, 3));
  else if (strcmp(key, "clipboard_text") == 0)
    luaL_argerror(L, 3, "read-only property");
  else if (strcmp(key, "docstatusbar_text") == 0)
    set_statusbar_text(lua_tostring(L, 3), 1);
  else if (strcmp(key, "statusbar_text") == 0) {
    g_free(statusbar_text);
    statusbar_text = g_strdup(luaL_optstring(L, 3, ""));
    set_statusbar_text(statusbar_text, 0);
  } else if (strcmp(key, "menubar") == 0) {
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
    ige_mac_menu_set_menu_bar(GTK_MENU_SHELL(menubar));
    gtk_widget_hide(menubar);
#endif
  } else if (strcmp(key, "size") == 0) {
    luaL_argcheck(L, lua_istable(L, 3) && lua_objlen(L, 3) == 2, 3,
                  "{ width, height } table expected");
    int w = l_rawgetiint(L, 3, 1), h = l_rawgetiint(L, 3, 2);
    if (w > 0 && h > 0) gtk_window_resize(GTK_WINDOW(window), w, h);
  } else lua_rawset(L, 1);
  return 0;
}

#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
static int lfind__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(find_entry)));
  else if (strcmp(key, "replace_entry_text") == 0)
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(replace_entry)));
  else if (strcmp(key, "match_case") == 0)
    lua_pushboolean(L, toggled(match_case_opt));
  else if (strcmp(key, "whole_word") == 0)
    lua_pushboolean(L, toggled(whole_word_opt));
  else if (strcmp(key, "lua") == 0)
    lua_pushboolean(L, toggled(lua_opt));
  else if (strcmp(key, "in_files") == 0)
    lua_pushboolean(L, toggled(in_files_opt));
  else
    lua_rawget(L, 1);
  return 1;
}

#define toggle(w, b) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), b)
static int lfind__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "find_entry_text") == 0)
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(L, 3));
  else if (strcmp(key, "replace_entry_text") == 0)
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(L, 3));
  else if (strcmp(key, "match_case") == 0)
    toggle(match_case_opt, lua_toboolean(L, -1));
  else if (strcmp(key, "whole_word") == 0)
    toggle(whole_word_opt, lua_toboolean(L, -1));
  else if (strcmp(key, "lua") == 0)
    toggle(lua_opt, lua_toboolean(L, -1));
  else if (strcmp(key, "in_files") == 0)
    toggle(in_files_opt, lua_toboolean(L, -1));
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
    gtk_button_set_label(GTK_BUTTON(match_case_opt), lua_tostring(L, 3));
  else if (strcmp(key, "whole_word_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(whole_word_opt), lua_tostring(L, 3));
  else if (strcmp(key, "lua_pattern_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(lua_opt), lua_tostring(L, 3));
  else if (strcmp(key, "in_files_label_text") == 0)
    gtk_button_set_label(GTK_BUTTON(in_files_opt), lua_tostring(L, 3));
  else
    lua_rawset(L, 1);
  return 0;
}

static int lce__index(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0)
    lua_pushstring(L, gtk_entry_get_text(GTK_ENTRY(command_entry)));
  else
    lua_rawget(L, 1);
  return 1;
}

static int lce__newindex(lua_State *L) {
  const char *key = lua_tostring(L, 2);
  if (strcmp(key, "entry_text") == 0)
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(L, 3));
  else
    lua_rawset(L, 1);
  return 0;
}

/******************************************************************************/
/******************             Lua CFunctions              *******************/
/****************** (For documentation, consult the LuaDoc) *******************/
/******************************************************************************/

static int lbuffer_check_global(lua_State *L) {
  lL_globaldoccheck(L, 1);
  return 0;
}

static int lbuffer_delete(lua_State *L) {
  lL_globaldoccheck(L, 1);
  sptr_t doc = SS(focused_view, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  if (lua_objlen(L, -1) == 1) new_buffer(0);
  lL_gotodoc(L, focused_view, -1, TRUE);
  delete_buffer(doc);
  lL_event(L, "buffer_deleted", -1),
  lL_event(L, "buffer_after_switch", -1);
  return 0;
}

static int lbuffer_new(lua_State *L) {
  new_buffer(0);
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_buffers");
  lua_rawgeti(L, -1, lua_objlen(L, -1));
  return 1;
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
  g_free(tr.lpstrText);
  return 1;
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

static int lgui_get_split_table(lua_State *L) {
  GtkWidget *pane = gtk_widget_get_parent(focused_view);
  if (GTK_IS_PANED(pane)) {
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_pushsplittable(L, child1(pane), child2(pane));
  } else l_pushview(L, focused_view);
  return 1;
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
static int lview_goto_buffer(lua_State *L) {
  GtkWidget *view = lL_checkview(L, 1), *prev_view = focused_view;
  int n = luaL_checkinteger(L, 2), relative = lua_toboolean(L, 3);
  int switch_focus = (view != focused_view);
  if (switch_focus) SS(view, SCI_SETFOCUS, TRUE, 0);
  lL_event(L, "buffer_before_switch", -1);
  lL_gotodoc(L, view, n, relative);
  lL_event(L, "buffer_after_switch", -1);
  if (switch_focus)
    SS(view, SCI_SETFOCUS, FALSE, 0), gtk_widget_grab_focus(prev_view);
  return 0;
}

static int lgui_dialog(lua_State *L) {
  GCDialogType type = gcocoadialog_type(luaL_checkstring(L, 1));
  int i, j, k, n = lua_gettop(L) - 1, argc = n;
  for (i = 2; i < n + 2; i++)
    if (lua_istable(L, i)) argc += lua_objlen(L, i) - 1;
  const char **argv = malloc((argc + 1) * sizeof(const char *));
  for (i = 0, j = 2; j < n + 2; j++)
    if (lua_istable(L, j)) {
      int len = lua_objlen(L, j);
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

static int lgui_goto_view(lua_State *L) {
  int n = luaL_checkinteger(L, 1), relative = lua_toboolean(L, 2);
  if (relative && n == 0) return 0;
  lua_getfield(L, LUA_REGISTRYINDEX, "ta_views");
  if (relative) {
    l_pushview(L, focused_view), lua_gettable(L, -2);
    n = lua_tointeger(L, -1) + n;
    if (n > lua_objlen(L, -2))
      n = 1;
    else if (n < 1)
      n = lua_objlen(L, -2);
    lua_rawgeti(L, -2, n);
  } else {
    luaL_argcheck(L, n > 0 && n <= lua_objlen(L, -1), 1,
                  "no View exists at that index");
    lua_rawgeti(L, -1, n);
  }
  GtkWidget *view = l_toview(L, -1);
  gtk_widget_grab_focus(view);
  // gui.dialog() interferes with focus so gtk_widget_grab_focus() does not
  // always work. If this is the case, ensure goto_view() is called.
  if (!gtk_widget_has_focus(view)) goto_view(view);
  return 0;
}

static void m_clicked(GtkWidget *menu, gpointer id) {
  lL_event(lua, "menu_clicked", LUA_TNUMBER, GPOINTER_TO_INT(id), -1);
}

static int lgui_gtkmenu(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  l_pushgtkmenu(L, -1, G_CALLBACK(m_clicked), FALSE);
  return 1;
}

static int lstring_iconv(lua_State *L) {
  size_t text_len = 0, conv_len = 0;
  const char *text = luaL_checklstring(L, 1, &text_len);
  const char *to = luaL_checkstring(L, 2);
  const char *from = luaL_checkstring(L, 3);
  char *converted = g_convert(text, text_len, to, from, NULL, &conv_len, NULL);
  if (!converted) luaL_error(L, "Conversion failed");
  lua_pushlstring(L, converted, conv_len);
  g_free(converted);
  return 1;
}

static int lquit(lua_State *L) {
  GdkEventAny event;
  event.type = GDK_DELETE;
  event.window = gtk_widget_get_window(window);
  event.send_event = TRUE;
  gdk_event_put((GdkEvent *)(&event));
  return 0;
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

static gboolean emit_timeout(gpointer data) {
  int *refs = (int *)data;
  lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[0]); // function
  int nargs = 0, repeat = TRUE;
  while (refs[++nargs]) lua_rawgeti(lua, LUA_REGISTRYINDEX, refs[nargs]);
  int ok = (lua_pcall(lua, nargs - 1, 1, 0) == 0);
  if (!ok || !lua_toboolean(lua, -1)) {
    while (--nargs >= 0) luaL_unref(lua, LUA_REGISTRYINDEX, refs[nargs]);
    repeat = FALSE;
    if (!ok) lL_event(lua, "error", LUA_TSTRING, lua_tostring(lua, -1), -1);
  }
  lua_pop(lua, 1); // result
  return repeat;
}

static int ltimeout(lua_State *L) {
  int timeout = luaL_checkinteger(L, 1);
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
  g_timeout_add_seconds(timeout, emit_timeout, (gpointer)refs);
  return 0;
}

static int lfind_focus(lua_State *L) {
  if (!gtk_widget_has_focus(findbox)) {
    gtk_widget_show(findbox);
    gtk_widget_grab_focus(find_entry);
    gtk_widget_grab_default(fnext_button);
  } else {
    gtk_widget_grab_focus(focused_view);
    gtk_widget_hide(findbox);
  }
  return 0;
}

static int lfind_next(lua_State *L) {
  return (g_signal_emit_by_name(G_OBJECT(fnext_button), "clicked"), 0);
}

static int lfind_prev(lua_State *L) {
  return (g_signal_emit_by_name(G_OBJECT(fprev_button), "clicked"), 0);
}

static int lfind_replace(lua_State *L) {
  return (g_signal_emit_by_name(G_OBJECT(r_button), "clicked"), 0);
}

static int lfind_replace_all(lua_State *L) {
  return (g_signal_emit_by_name(G_OBJECT(ra_button), "clicked"), 0);
}

static int lce_focus(lua_State *L) {
  if (!gtk_widget_has_focus(command_entry)) {
    gtk_widget_show(command_entry);
    gtk_widget_grab_focus(command_entry);
  } else {
    gtk_widget_hide(command_entry);
    gtk_widget_grab_focus(focused_view);
  }
  return 0;
}

static int lce_show_completions(lua_State *L) {
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
  return 0;
}

// Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"
#if __WIN32__
#include <windows.h>
#define main main_
#elif MAC
#include <Carbon/Carbon.h>
#include "ige-mac-menu.h"
#elif __BSD__
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

#define gbool gboolean
#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)

// Textadept
GtkWidget *window, *focused_editor, *menubar, *statusbar, *docstatusbar;
char *textadept_home;

static void s_notification(GtkWidget *, gint, gpointer, gpointer);
static void s_command(GtkWidget *, gint, gpointer, gpointer);
static gbool s_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gbool s_buttonpress(GtkWidget *, GdkEventButton *, gpointer);
static gbool w_focus(GtkWidget *, GdkEventFocus *, gpointer);
static gbool w_keypress(GtkWidget *, GdkEventKey *, gpointer);
static gbool w_exit(GtkWidget *, GdkEventAny *, gpointer);
#if MAC
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

/**
 * Runs Textadept in Linux or Mac.
 * Inits the Lua State, creates the user interface, loads the core/init.lua
 * script, and also loads init.lua.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
#if !(__WIN32__ || MAC || __BSD__)
  textadept_home = g_file_read_link("/proc/self/exe", NULL);
#elif MAC
  CFURLRef bundle = CFBundleCopyBundleURL(CFBundleGetMainBundle());
  if (bundle) {
    CFStringRef path = CFURLCopyFileSystemPath(bundle, kCFURLPOSIXPathStyle);
    const char *p = CFStringGetCStringPtr(path, kCFStringEncodingMacRoman);
    textadept_home = g_strconcat(p, "/Contents/Resources/", NULL);
    CFRelease(path);
    CFRelease(bundle);
  } else textadept_home = calloc(1, 1);
  // GTK-OSX does not parse ~/.gtkrc-2.0; parse it manually
  char *user_home = g_strconcat(getenv("HOME"), "/.gtkrc-2.0", NULL);
  gtk_rc_parse(user_home);
  g_free(user_home);
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
 *   - A frame for Scintilla windows.
 *   - A find text frame initially hidden.
 *   - A command entry initially hidden. This entry accepts and runs Lua code
 *     in the current Lua state.
 *   - Two status bars: one for notifications, the other for document status.
 */
void create_ui() {
  GList *icon_list = NULL;
  const char *icons[] = { "16x16", "32x32", "48x48", "64x64", "128x128" };
  for (int i = 0; i < 5; i++) {
    char *icon_file =
      g_strconcat(textadept_home, "/core/images/ta_", icons[i], ".png", NULL);
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

#if MAC
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

  GtkWidget *editor = new_scintilla_window(0);
  gtk_box_pack_start(GTK_BOX(hbox), editor, TRUE, TRUE, 0);

  GtkWidget *find = find_create_ui();
  gtk_box_pack_start(GTK_BOX(vbox), find, FALSE, FALSE, 5);

  GtkWidget *hboxs = gtk_hbox_new(FALSE, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, FALSE, FALSE, 0);

  statusbar = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), 0, "");
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar), FALSE);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar, TRUE, TRUE, 0);

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

  docstatusbar = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(docstatusbar), 0, "");
  g_object_set(G_OBJECT(docstatusbar), "width-request", 400, NULL);
#if MAC
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(docstatusbar), FALSE);
#endif
  gtk_box_pack_start(GTK_BOX(hboxs), docstatusbar, FALSE, FALSE, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar); // hide initially
  gtk_widget_hide(findbox); // hide initially
  gtk_widget_hide(command_entry); // hide initially
  gtk_widget_grab_focus(editor);
}

/**
 * Creates a new Scintilla window.
 * The Scintilla window is the GTK widget that displays a Scintilla buffer.
 * Generates a 'view_new' event.
 * @param buffer_id A Scintilla buffer ID to load into the new window. If NULL,
 *   creates a new Scintilla buffer and loads it into the new window.
 * @return the Scintilla window.
 * @see l_add_scintilla_window
 */
GtkWidget *new_scintilla_window(sptr_t buffer_id) {
  GtkWidget *editor = scintilla_new();
  gtk_widget_set_size_request(editor, 1, 1); // minimum size
  SS(editor, SCI_USEPOPUP, 0, 0);
  signal(editor, SCINTILLA_NOTIFY, s_notification);
  signal(editor, "command", s_command);
  signal(editor, "key-press-event", s_keypress);
  signal(editor, "button-press-event", s_buttonpress);
  l_add_scintilla_window(editor);
  gtk_widget_grab_focus(editor);
  focused_editor = editor;
  if (buffer_id) {
    SS(editor, SCI_SETDOCPOINTER, 0, buffer_id);
    new_scintilla_buffer(editor, FALSE, FALSE);
  } else new_scintilla_buffer(editor, FALSE, TRUE);
  l_set_view_global(editor);
  l_emit_event("view_new", -1);
  return editor;
}

/**
 * Removes a Scintilla window.
 * @param editor The Scintilla window to remove.
 * @see l_remove_scintilla_window
 */
void remove_scintilla_window(GtkWidget *editor) {
  l_remove_scintilla_window(editor);
  gtk_widget_destroy(editor);
}

/**
 * Creates a new Scintilla buffer for a newly created Scintilla window.
 * Generates a 'buffer_new' event.
 * @param editor The Scintilla window to associate the buffer with.
 * @param create Flag indicating whether or not to create a buffer. If FALSE,
 *   the Scintilla window already has a buffer associated with it (typically
 *   because new_scintilla_window was passed a non-NULL buffer_id).
 * @param addref Flag indicating whether or not to add a reference to the buffer
 *   in the Scintilla window when create is FALSE. This is necessary for
 *   creating Scintilla windows in split views. If a buffer appears in two
 *   separate Scintilla windows, that buffer should have multiple references so
 *   when one Scintilla window closes, the buffer is not deleted because its
 *   reference count is not zero.
 * @see l_add_scintilla_buffer
 */
void new_scintilla_buffer(GtkWidget *editor, int create, int addref) {
  sptr_t doc;
  doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  if (create) { // create the new document
    doc = SS(editor, SCI_CREATEDOCUMENT, 0, 0);
    l_goto_scintilla_buffer(focused_editor, l_add_scintilla_buffer(doc), TRUE);
  } else if (addref) {
    l_add_scintilla_buffer(doc);
    SS(editor, SCI_ADDREFDOCUMENT, 0, doc);
  }
  l_set_buffer_global(editor);
  l_emit_event("buffer_new", -1);
  l_emit_event("update_ui", -1); // update document status
}

/**
 * Removes the Scintilla buffer from the current Scintilla window.
 * @param doc The Scintilla buffer ID to remove.
 * @see l_remove_scintilla_buffer
 */
void remove_scintilla_buffer(sptr_t doc) {
  l_remove_scintilla_buffer(doc);
  SS(focused_editor, SCI_RELEASEDOCUMENT, 0, doc);
}

/**
 * Splits a Scintilla window into two windows separated by a GTK pane.
 * The buffer in the original pane is also shown in the new pane.
 * @param editor The Scintilla window to split.
 * @param vertical Flag indicating whether to split the window vertically or
 *   horozontally.
 */
void split_window(GtkWidget *editor, int vertical) {
  g_object_ref(editor);
  int first_line = SS(editor, SCI_GETFIRSTVISIBLELINE, 0, 0);
  int current_pos = SS(editor, SCI_GETCURRENTPOS, 0, 0);
  int anchor = SS(editor, SCI_GETANCHOR, 0, 0);
  int middle =
    (vertical ? editor->allocation.width : editor->allocation.height) / 2;

  sptr_t curdoc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  GtkWidget *neweditor = new_scintilla_window(curdoc);
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
 * For a given GTK pane, remove the Scintilla windows inside it recursively.
 * @param pane The GTK pane to remove Scintilla windows from.
 * @see remove_scintilla_window
 */
void remove_scintilla_windows_in_pane(GtkWidget *pane) {
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane));
  GtkWidget *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_scintilla_windows_in_pane(child1)
                       : remove_scintilla_window(child1);
  GTK_IS_PANED(child2) ? remove_scintilla_windows_in_pane(child2)
                       : remove_scintilla_window(child2);
}

/**
 * Unsplits the pane a given Scintilla window is in and keeps that window.
 * If the pane to discard contains other Scintilla windows, they are removed
 * recursively.
 * @param editor The Scintilla window to keep when unsplitting.
 * @see remove_scintilla_windows_in_pane
 * @see remove_scintilla_window
 */
int unsplit_window(GtkWidget *editor) {
  GtkWidget *pane = gtk_widget_get_parent(editor);
  if (!GTK_IS_PANED(pane)) return FALSE;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane));
  if (other == editor) other = gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(editor);
  g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), editor);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_scintilla_windows_in_pane(other)
                      : remove_scintilla_window(other);
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
#if MAC
  ige_mac_menu_set_menu_bar(GTK_MENU_SHELL(menubar));
  gtk_widget_hide(menubar);
#endif
}

/**
 * Sets the notification statusbar text.
 * @param text The text to display.
 * @param docbar Flag indicating whether or not the statusbar text is for the
 *   docstatusbar.
 */
void set_statusbar_text(const char *text, int docbar) {
  GtkWidget *bar = docbar ? docstatusbar : statusbar;
  if (!bar) return; // this is sometimes called before a bar is available
  gtk_statusbar_pop(GTK_STATUSBAR(bar), 0);
  gtk_statusbar_push(GTK_STATUSBAR(bar), 0, text);
}

// Notifications/signals

/**
 * Helper function for switching the focused view to the given one.
 * @param editor The Scintilla window to focus.
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
#if !MAC
                      LUA_TBOOLEAN, event->state & GDK_MOD1_MASK,
#else
                      LUA_TBOOLEAN, event->state & GDK_META_MASK,
#endif
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

#if MAC
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

// Find/Replace

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
  GtkWidget *find_combo =
    gtk_combo_box_entry_new_with_model(GTK_TREE_MODEL(find_store), 0);
  g_object_unref(find_store);
  gtk_combo_box_set_focus_on_click(GTK_COMBO_BOX(find_combo), FALSE);
  find_entry = gtk_bin_get_child(GTK_BIN(find_combo));
  gtk_widget_set_name(find_entry, "textadept-find-entry");
  gtk_entry_set_activates_default(GTK_ENTRY(find_entry), TRUE);
  GtkWidget *replace_combo =
    gtk_combo_box_entry_new_with_model(GTK_TREE_MODEL(repl_store), 0);
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

// Signals

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

// Command Entry

/**
 * Toggles focus between a Scintilla window and the Command Entry.
 * When the entry is visible, the statusbars are temporarily hidden.
 */
void ce_toggle_focus() {
  if (!GTK_WIDGET_HAS_FOCUS(command_entry)) {
    gtk_widget_hide(statusbar);
    gtk_widget_hide(docstatusbar);
    gtk_widget_show(command_entry);
    gtk_widget_grab_focus(command_entry);
  } else {
    gtk_widget_show(statusbar);
    gtk_widget_show(docstatusbar);
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
                         GtkTreeIter *iter, gpointer udata) {
  return 1;
}

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

// Signals

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

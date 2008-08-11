// Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)

// Textadept
GtkWidget
  *window, *focused_editor, *command_entry,
  *menubar, *statusbar, *docstatusbar;
GtkEntryCompletion *command_entry_completion;
GtkTreeStore *cec_store;

static void c_activated(GtkWidget *widget, gpointer);
static bool c_keypress(GtkWidget *widget, GdkEventKey *event, gpointer);
static int cec_match_func(GtkEntryCompletion *, const char *, GtkTreeIter *,
                          gpointer);
static bool cec_match_selected(GtkEntryCompletion *, GtkTreeModel *model,
                               GtkTreeIter *iter, gpointer);
static void t_notification(GtkWidget*, gint, gpointer lParam, gpointer);
static void t_command(GtkWidget *editor, gint wParam, gpointer, gpointer);
static bool t_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static bool w_focus(GtkWidget*, GdkEventFocus *, gpointer);
static bool w_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static bool w_exit(GtkWidget*, GdkEventAny*, gpointer);

// Project Manager
GtkWidget *pm_view, *pm_entry, *pm_container;
GtkTreeStore *pm_store;

static int pm_search_equal_func(GtkTreeModel *model, int col, const char *key,
                                GtkTreeIter *iter, gpointer);
static int pm_sort_iter_compare_func(GtkTreeModel *model, GtkTreeIter *a,
                                     GtkTreeIter *b, gpointer);
static void pm_entry_activated(GtkWidget *widget, gpointer);
static bool pm_keypress(GtkWidget *, GdkEventKey *event, gpointer);
static void pm_row_expanded(GtkTreeView *, GtkTreeIter *iter,
                            GtkTreePath *path, gpointer);
static void pm_row_collapsed(GtkTreeView *, GtkTreeIter *iter,
                             GtkTreePath *path, gpointer);
static void pm_row_activated(GtkTreeView *, GtkTreePath *, GtkTreeViewColumn *,
                             gpointer);
static bool pm_button_press(GtkTreeView *, GdkEventButton *event, gpointer);
static bool pm_popup_menu(GtkWidget *, gpointer);
static void pm_menu_activate(GtkWidget *menu_item, gpointer);

// Find/Replace
GtkWidget *findbox, *find_entry, *replace_entry;
GtkWidget *fnext_button, *fprev_button, *r_button, *ra_button;
GtkWidget *match_case_opt, *whole_word_opt, /**incremental_opt,*/ *lua_opt;
GtkAttachOptions
  normal = static_cast<GtkAttachOptions>(GTK_SHRINK | GTK_FILL),
  expand = static_cast<GtkAttachOptions>(GTK_EXPAND | GTK_FILL);

static bool fe_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static bool re_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static void button_clicked(GtkWidget *button, gpointer);

/**
 * Runs Textadept.
 * Inits the Lua State, creates the user interface, and loads the core/init.lua
 * script.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
  gtk_init(&argc, &argv);
  l_init(argc, argv, false);
  create_ui();
  l_load_script("init.lua");
  gtk_main();
  return 0;
}

/**
 * Creates the user interface.
 * The UI consists of:
 *   - A menubar initially hidden and empty. It should be populated by script
 *     and then shown.
 *   - A side pane. It contains a treeview for hierarchical data sets, such as
 *     a file structure for project management.
 *   - A frame for Scintilla windows.
 *   - A find text frame initially hidden.
 *   - A command entry initially hidden. This entry accepts and runs Lua code
 *     in the current Lua state.
 *   - Two status bars: one for notifications, the other for document status.
 */
void create_ui() {
  GList *icons = NULL;
  const char *icon_files[] = {
    "ta_16x16.png", "ta_32x32.png", "ta_48x48.png",
    "ta_64x64.png", "ta_128x128.png"
  };
  for (int i = 0; i < 5; i++) {
    char *icon_file = g_strconcat(textadept_home, "/core/images/",
                                  icon_files[i], NULL);
    GdkPixbuf *pb = gdk_pixbuf_new_from_file(icon_file, NULL);
    if (pb) icons = g_list_prepend(icons, pb);
    g_free(icon_file);
  }
  gtk_window_set_default_icon_list(icons);
  g_list_foreach(icons, (GFunc) g_object_unref, NULL);
  g_list_free(icons);

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_default_size(GTK_WINDOW(window), 500, 400);
  signal(window, "delete_event", w_exit);
  signal(window, "focus-in-event", w_focus);
  signal(window, "key_press_event", w_keypress);

  GtkWidget *vbox = gtk_vbox_new(false, 0);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  menubar = gtk_menu_bar_new();
  gtk_box_pack_start(GTK_BOX(vbox), menubar, false, false, 0);

  GtkWidget *pane = gtk_hpaned_new();
  gtk_box_pack_start(GTK_BOX(vbox), pane, true, true, 0);

  GtkWidget *pm = pm_create_ui();
  gtk_paned_add1(GTK_PANED(pane), pm);

  GtkWidget *hbox = gtk_hbox_new(false, 0);
  gtk_paned_add2(GTK_PANED(pane), hbox);

  GtkWidget *editor = new_scintilla_window();
  gtk_box_pack_start(GTK_BOX(hbox), editor, true, true, 0);

  GtkWidget *find = find_create_ui();
  gtk_box_pack_start(GTK_BOX(vbox), find, false, false, 5);

  GtkWidget *hboxs = gtk_hbox_new(false, 0);
  gtk_box_pack_start(GTK_BOX(vbox), hboxs, false, false, 0);

  statusbar = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), 0, "");
  gtk_statusbar_set_has_resize_grip(GTK_STATUSBAR(statusbar), false);
  gtk_box_pack_start(GTK_BOX(hboxs), statusbar, true, true, 0);

  command_entry = gtk_entry_new();
  gtk_widget_set_name(command_entry, "textadept-command-entry");
  signal(command_entry, "activate", c_activated);
  signal(command_entry, "key_press_event", c_keypress);
  g_object_set(G_OBJECT(command_entry), "width-request", 200, NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), command_entry, true, true, 0);

  command_entry_completion = gtk_entry_completion_new();
  signal(command_entry_completion, "match-selected", cec_match_selected);
  gtk_entry_completion_set_match_func(command_entry_completion, cec_match_func,
                                      NULL, NULL);
  gtk_entry_completion_set_popup_set_width(command_entry_completion, false);
  gtk_entry_completion_set_text_column(command_entry_completion, 0);
  cec_store = gtk_tree_store_new(1, G_TYPE_STRING);
  gtk_entry_completion_set_model(command_entry_completion,
                                 GTK_TREE_MODEL(cec_store));
  gtk_entry_set_completion(GTK_ENTRY(command_entry), command_entry_completion);

  docstatusbar = gtk_statusbar_new();
  gtk_statusbar_push(GTK_STATUSBAR(docstatusbar), 0, "");
  g_object_set(G_OBJECT(docstatusbar), "width-request", 400, NULL);
  gtk_box_pack_start(GTK_BOX(hboxs), docstatusbar, false, false, 0);

  gtk_widget_show_all(window);
  gtk_widget_hide(menubar); // hide initially
  gtk_widget_hide(findbox); // hide initially
  gtk_widget_hide(command_entry); // hide initially
  gtk_widget_grab_focus(editor);
}

/**
 * Creates a new Scintilla window.
 * The Scintilla window is the GTK widget that displays a Scintilla buffer.
 * The window's default properties are set via 'set_default_editor_properties'.
 * Generates a 'view_new' event.
 * @param buffer_id A Scintilla buffer ID to load into the new window. If NULL,
 *   creates a new Scintilla buffer and loads it into the new window.
 *   Defaults to NULL.
 * @return the Scintilla window.
 * @see set_default_editor_properties
 * @see l_add_scintilla_window
 */
GtkWidget* new_scintilla_window(sptr_t buffer_id) {
  GtkWidget *editor = scintilla_new();
  gtk_widget_set_size_request(editor, 1, 1); // minimum size
  signal(editor, "key_press_event", t_keypress);
  signal(editor, "command", t_command);
  signal(editor, SCINTILLA_NOTIFY, t_notification);
  l_add_scintilla_window(editor);
  gtk_widget_grab_focus(editor); focused_editor = editor;
  if (buffer_id) {
    SS(SCINTILLA(editor), SCI_SETDOCPOINTER, 0, buffer_id);
    new_scintilla_buffer(SCINTILLA(editor), false, false);
  } else new_scintilla_buffer(SCINTILLA(editor), false, true);
  l_set_view_global(editor);
  l_handle_event("view_new");
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
 * The buffer's default properties are set via 'set_default_buffer_properties',
 * but the default style is set here.
 * Generates a 'buffer_new' event.
 * @param sci The ScintillaObject to associate the buffer with.
 * @param create Flag indicating whether or not to create a buffer. If false,
 *   the ScintillaObject already has a buffer associated with it (typically
 *   because new_scintilla_window was passed a non-NULL buffer_id).
 *   Defaults to true.
 * @param addref Flag indicating whether or not to add a reference to the buffer
 *   in the ScintillaObject when create is false. This is necessary for creating
 *   Scintilla windows in split views. If a buffer appears in two separate
 *   Scintilla windows, that buffer should have multiple references so when one
 *   Scintilla window closes, the buffer is not deleted because its reference
 *   count is not zero.
 *   Defaults to true.
 * @see set_default_buffer_properties
 * @see l_add_scintilla_buffer
 */
void new_scintilla_buffer(ScintillaObject *sci, bool create, bool addref) {
  sptr_t doc;
  doc = SS(sci, SCI_GETDOCPOINTER);
  if (create) { // create the new document
    doc = SS(sci, SCI_CREATEDOCUMENT);
    l_goto_scintilla_buffer(focused_editor, l_add_scintilla_buffer(doc));
  } else if (addref) {
    l_add_scintilla_buffer(doc);
    SS(sci, SCI_ADDREFDOCUMENT, 0, doc);
  }
  l_set_buffer_global(sci);
  l_handle_event("buffer_new");
}

/**
 * Removes the Scintilla buffer from the current Scintilla window.
 * @param doc The Scintilla buffer ID to remove.
 * @see l_remove_scintilla_buffer
 */
void remove_scintilla_buffer(sptr_t doc) {
  l_remove_scintilla_buffer(doc);
  SS(SCINTILLA(focused_editor), SCI_RELEASEDOCUMENT, 0, doc);
}

/**
 * Splits a Scintilla window into two windows separated by a GTK pane.
 * The buffer in the original pane is also shown in the new pane.
 * @param editor The Scintilla window to split.
 * @param vertical Flag indicating whether to split the window vertically or
 *   horozontally.
 *   Defaults to true.
 */
void split_window(GtkWidget *editor, bool vertical) {
  g_object_ref(editor);
  int first_line = SS(SCINTILLA(editor), SCI_GETFIRSTVISIBLELINE);
  int current_pos = SS(SCINTILLA(editor), SCI_GETCURRENTPOS);
  int anchor = SS(SCINTILLA(editor), SCI_GETANCHOR);
  int middle = (vertical ? editor->allocation.width
                         : editor->allocation.height) / 2;

  sptr_t curdoc = SS(SCINTILLA(editor), SCI_GETDOCPOINTER);
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

  SS(SCINTILLA(neweditor), SCI_SETSEL, anchor, current_pos);
  int new_first_line = SS(SCINTILLA(neweditor), SCI_GETFIRSTVISIBLELINE);
  SS(SCINTILLA(neweditor), SCI_LINESCROLL, first_line - new_first_line);
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
bool unsplit_window(GtkWidget *editor) {
  GtkWidget *pane = gtk_widget_get_parent(editor);
  if (!GTK_IS_PANED(pane)) return false;
  GtkWidget *other = gtk_paned_get_child1(GTK_PANED(pane));
  if (other == editor) other = gtk_paned_get_child2(GTK_PANED(pane));
  g_object_ref(editor); g_object_ref(other);
  gtk_container_remove(GTK_CONTAINER(pane), editor);
  gtk_container_remove(GTK_CONTAINER(pane), other);
  GTK_IS_PANED(other) ? remove_scintilla_windows_in_pane(other)
                      : remove_scintilla_window(other);
  GtkWidget *parent = gtk_widget_get_parent(pane);
  gtk_container_remove(GTK_CONTAINER(parent), pane);
  if (GTK_IS_PANED(parent))
    if (!gtk_paned_get_child1(GTK_PANED(parent)))
      gtk_paned_add1(GTK_PANED(parent), editor);
    else
      gtk_paned_add2(GTK_PANED(parent), editor);
  else
    gtk_container_add(GTK_CONTAINER(parent), editor);
  gtk_widget_show_all(parent);
  gtk_widget_grab_focus(GTK_WIDGET(editor));
  g_object_unref(editor); g_object_unref(other);
  return true;
}

/**
 * Resizes a GTK pane.
 * @param editor The Scintilla window (typically the current one) contained in
 *   the GTK pane to resize.
 * @param pos The position to resize to.
 * @param increment Flag indicating whether or not the resizing is incremental.
 *   If true, pos is added to the current pane position; otherwise the position
 *   is absolute.
 *   Defaults to true.
 */
void resize_split(GtkWidget *editor, int pos, bool increment) {
  GtkWidget *pane = gtk_widget_get_parent(editor);
  int width = gtk_paned_get_position(GTK_PANED(pane));
  gtk_paned_set_position(GTK_PANED(pane), pos + (increment ? width : 0));
}

/**
 * Sets a user-defined GTK menubar and displays it.
 * @param new_menubar The GTK menubar.
 * @see l_ta_mt_newindex
 */
void set_menubar(GtkWidget *new_menubar) {
  GtkWidget *vbox = gtk_widget_get_parent(menubar);
  gtk_container_remove(GTK_CONTAINER(vbox), menubar);
  menubar = new_menubar;
  gtk_box_pack_start(GTK_BOX(vbox), menubar, false, false, 0);
  gtk_box_reorder_child(GTK_BOX(vbox), menubar, 0);
  gtk_widget_show_all(menubar);
}

/**
 * Sets the notification statusbar text.
 * @param text The text to display.
 */
void set_statusbar_text(const char *text) {
  if (!statusbar) return;
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), 0, text);
}

/**
 * Sets the document status statusbar text.
 * This is typically set via a Scintilla 'UpdateUI' notification.
 * @param text The text to display.
 */
void set_docstatusbar_text(const char *text) {
  if (!docstatusbar) return;
  gtk_statusbar_pop(GTK_STATUSBAR(docstatusbar), 0);
  gtk_statusbar_push(GTK_STATUSBAR(docstatusbar), 0, text);
}

/**
 * Toggles focus between a Scintilla window and the Lua command entry.
 * When the entry is visible, the statusbars are temporarily hidden.
 */
void ce_toggle_focus() {
  if (!GTK_WIDGET_HAS_FOCUS(command_entry)) {
    gtk_widget_hide(statusbar); gtk_widget_hide(docstatusbar);
    gtk_widget_show(command_entry);
    gtk_widget_grab_focus(command_entry);
  } else {
    gtk_widget_show(statusbar); gtk_widget_show(docstatusbar);
    gtk_widget_hide(command_entry);
    gtk_widget_grab_focus(focused_editor);
  }
}

// Notifications/signals

/**
 * Signal for the 'enter' key being pressed in the Lua command entry.
 * Evaluates the input text as Lua code.
 */
static void c_activated(GtkWidget *widget, gpointer) {
  l_ta_command(gtk_entry_get_text(GTK_ENTRY(widget)));
  ce_toggle_focus();
}

/**
 * Signal for a keypress inside the Lua command entry.
 * Currently handled keypresses:
 *  - Escape - Hide the completion buffer if it is open.
 *  - Tab - Display possible completions.
 */
static bool c_keypress(GtkWidget *widget, GdkEventKey *event, gpointer) {
  if (event->state == 0)
    switch(event->keyval) {
      case 0xff1b:
        ce_toggle_focus();
        return true;
      case 0xff09:
        if (l_cec_get_completions_for(gtk_entry_get_text(GTK_ENTRY(widget)))) {
          l_cec_populate();
          gtk_entry_completion_complete(command_entry_completion);
        }
        return true;
    }
  return false;
}

/**
 * Sets every item in the Command Entry Model to be a match.
 * For each attempted completion, the Command Entry Model is filled with the
 * results from a call to Lua to make a list of possible completions. Therefore,
 * every item in the list is valid.
 */
static int cec_match_func(GtkEntryCompletion*, const char*, GtkTreeIter*,
                          gpointer) {
  return true;
}

/**
 * Enters the requested completion text into the Command Entry.
 * The last word at the cursor is replaced with the completion. A word consists
 * of any alphanumeric character or underscore.
 */
static bool cec_match_selected(GtkEntryCompletion*, GtkTreeModel *model,
                               GtkTreeIter *iter, gpointer) {
  const char *entry_text = gtk_entry_get_text(GTK_ENTRY(command_entry));
  const char *p = entry_text + strlen(entry_text) - 1;
  while ((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z') ||
         (*p >= '0' && *p <= '9') || *p == '_') {
    g_signal_emit_by_name(G_OBJECT(command_entry), "move-cursor",
                          GTK_MOVEMENT_VISUAL_POSITIONS, -1, true, 0);
    p--;
  }
  if (p < entry_text + strlen(entry_text) - 1)
    g_signal_emit_by_name(G_OBJECT(command_entry), "backspace", 0);

  char *text;
  gtk_tree_model_get(model, iter, 0, &text, -1);
  g_signal_emit_by_name(G_OBJECT(command_entry), "insert-at-cursor", text, 0);
  g_free(text);

  gtk_tree_store_clear(cec_store);
  return true;
}

/**
 * Signal for a Scintilla notification.
 */
static void t_notification(GtkWidget*, gint, gpointer lParam, gpointer) {
  SCNotification *n = reinterpret_cast<SCNotification*>(lParam);
  l_handle_scnnotification(n);
}

/**
 * Signal for a Scintilla command.
 * Currently handles SCEN_SETFOCUS.
 */
static void t_command(GtkWidget *editor, gint wParam, gpointer, gpointer) {
  if (wParam >> 16 == SCEN_SETFOCUS) {
    focused_editor = editor;
    l_set_view_global(editor);
    l_set_buffer_global(SCINTILLA(editor));
  }
}

/**
 * Signal for a Scintilla keypress.
 * Collects the modifier states as flags and calls Lua to handle the keypress.
 * @see l_handle_keypress
 */
static bool t_keypress(GtkWidget*, GdkEventKey *event, gpointer) {
  bool shift = event->state & GDK_SHIFT_MASK;
  bool control = event->state & GDK_CONTROL_MASK;
  bool alt = event->state & GDK_MOD1_MASK;
  return l_handle_keypress(event->keyval, shift, control, alt);
}

/**
 * Signal for a Textadept window focus change.
 */
static bool w_focus(GtkWidget*, GdkEventFocus*, gpointer) {
  if (focused_editor && !GTK_WIDGET_HAS_FOCUS(focused_editor))
    gtk_widget_grab_focus(focused_editor);
  return false;
}

/**
 * Signal for a Textadept keypress.
 * Currently handled keypresses:
 *  - Escape - hides the search frame if it's open.
 */
static bool w_keypress(GtkWidget*, GdkEventKey *event, gpointer) {
  if (event->keyval == 0xff1b && GTK_WIDGET_VISIBLE(findbox)) {
    gtk_widget_hide(findbox);
    gtk_widget_grab_focus(focused_editor);
    return true;
  } else return false;
}

/**
 * Signal for exiting Textadept.
 * Closes the Lua State and releases resources.
 * Generates a 'quit' event.
 * @see l_close
 */
static bool w_exit(GtkWidget*, GdkEventAny*, gpointer) {
  if (!l_handle_event("quit")) return true;
  l_close();
  scintilla_release_resources();
  gtk_main_quit();
  return false;
}

// Project Manager

/**
 * Creates the Project Manager pane.
 * It consists of an entry box and a treeview called 'textadept-pm-entry' and
 * 'textadept-pm-view' respectively for styling via gtkrc. The treeview model
 * consists of a gdk-pixbuf for icons and markup text.
 */
GtkWidget* pm_create_ui() {
  pm_container = gtk_vbox_new(false, 1);

  pm_entry = gtk_entry_new();
  gtk_widget_set_name(pm_entry, "textadept-pm-entry");
  gtk_box_pack_start(GTK_BOX(pm_container), pm_entry, false, false, 0);

  pm_store = gtk_tree_store_new(3, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING);
  GtkTreeSortable *sortable = GTK_TREE_SORTABLE(pm_store);
  gtk_tree_sortable_set_sort_column_id(sortable, 1, GTK_SORT_ASCENDING);
  gtk_tree_sortable_set_sort_func(sortable, 1, pm_sort_iter_compare_func,
                                  GINT_TO_POINTER(1), NULL);

  pm_view = gtk_tree_view_new_with_model(GTK_TREE_MODEL(pm_store));
  g_object_unref(pm_store);
  gtk_widget_set_name(pm_view, "textadept-pm-view");
  gtk_tree_view_set_headers_visible(GTK_TREE_VIEW(pm_view), false);
  gtk_tree_view_set_enable_search(GTK_TREE_VIEW(pm_view), true);
  gtk_tree_view_set_search_column(GTK_TREE_VIEW(pm_view), 2);
  gtk_tree_view_set_search_equal_func(GTK_TREE_VIEW(pm_view),
                                      pm_search_equal_func, NULL, NULL);

  GtkTreeViewColumn *column = gtk_tree_view_column_new();
  GtkCellRenderer *renderer;
  renderer = gtk_cell_renderer_pixbuf_new(); // pixbuf
  gtk_tree_view_column_pack_start(column, renderer, FALSE);
  gtk_tree_view_column_set_attributes(column, renderer, "stock-id", 0, NULL);
  renderer = gtk_cell_renderer_text_new(); // markup text
  gtk_tree_view_column_pack_start(column, renderer, TRUE);
  gtk_tree_view_column_set_attributes(column, renderer, "markup", 2, NULL);
  gtk_tree_view_append_column(GTK_TREE_VIEW(pm_view), column);

  GtkWidget *scrolled = gtk_scrolled_window_new(NULL, NULL);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled),
                                 GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
  gtk_container_add(GTK_CONTAINER(scrolled), pm_view);
  gtk_box_pack_start(GTK_BOX(pm_container), scrolled, true, true, 0);

  signal(pm_entry, "activate", pm_entry_activated);
  signal(pm_entry, "key_press_event", pm_keypress);
  signal(pm_view, "key_press_event", pm_keypress);
  signal(pm_view, "row_expanded", pm_row_expanded);
  signal(pm_view, "row_collapsed", pm_row_collapsed);
  signal(pm_view, "row_activated", pm_row_activated);
  signal(pm_view, "button_press_event", pm_button_press);
  signal(pm_view, "popup-menu", pm_popup_menu);
  return pm_container;
}

/**
 * Requests contents for a Project Manager parent node being opened.
 * Since parents have a dummy child by default just to indicate they are indeed
 * parents, that dummy child is removed now.
 * @param iter The parent GtkTreeIter.
 * @param path The parent GtkTreePath.
 * @see l_pm_get_contents_for
 */
void pm_open_parent(GtkTreeIter *iter, GtkTreePath *path) {
  l_pm_get_full_path(path);
  if (l_pm_get_contents_for(NULL, true)) l_pm_populate(iter);
  GtkTreeIter child;
  char *filename;
  gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(pm_store), &child, iter, 0);
  gtk_tree_model_get(GTK_TREE_MODEL(pm_store), &child, 1, &filename, -1);
  if (strcmp(reinterpret_cast<const char*>(filename), "\0dummy") == 0)
    gtk_tree_store_remove(pm_store, &child);
  g_free(filename);
}

/**
 * Removes all Project Manager children from a parent node being closed.
 * It does add a dummy child by default to indicate the parent is indeed a
 * parent. It will be removed when the parent is opened.
 * @param iter The parent GtkTreeIter.
 */
void pm_close_parent(GtkTreeIter *iter, GtkTreePath *) {
  GtkTreeIter child;
  gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(pm_store), &child, iter, 0);
  while (gtk_tree_model_iter_has_child(GTK_TREE_MODEL(pm_store), iter))
    gtk_tree_store_remove(pm_store, &child);
  gtk_tree_store_append(pm_store, &child, iter);
  gtk_tree_store_set(pm_store, &child, 1, "\0dummy", -1);
}

/**
 * Performs the appropriate action on a selected Project Manager node.
 * If the node is a collapsed parent, it is expanded; otherwise the parent is
 * collapsed. If the node is not a parent at all, a Lua action is performed.
 * @see l_pm_perform_action
 */
void pm_activate_selection() {
  GtkTreeIter iter;
  GtkTreePath *path;
  GtkTreeViewColumn *column;
  gtk_tree_view_get_cursor(GTK_TREE_VIEW(pm_view), &path, &column);
  gtk_tree_model_get_iter(GTK_TREE_MODEL(pm_store), &iter, path);
  if (gtk_tree_model_iter_has_child(GTK_TREE_MODEL(pm_store), &iter))
    if (gtk_tree_view_row_expanded(GTK_TREE_VIEW(pm_view), path))
      gtk_tree_view_collapse_row(GTK_TREE_VIEW(pm_view), path);
    else
      gtk_tree_view_expand_row(GTK_TREE_VIEW(pm_view), path, false);
  else {
    l_pm_get_full_path(path);
    l_pm_perform_action();
  }
  gtk_tree_path_free(path);
}

/**
 * Pops up a context menu for the selected Project Manager node.
 * @param event The mouse button event.
 * @see l_pm_popup_context_menu
 */
void pm_popup_context_menu(GdkEventButton *event) {
  l_pm_popup_context_menu(event, G_CALLBACK(pm_menu_activate));
}

/**
 * Performs a Lua action for a selected Project Manager menu item.
 * @param menu_item The menu item.
 * @see l_pm_perform_menu_action
 */
void pm_process_selected_menu_item(GtkWidget *menu_item) {
  GtkWidget *label = gtk_bin_get_child(GTK_BIN(menu_item));
  const char *text = gtk_label_get_text(GTK_LABEL(label));
  GtkTreePath *path;
  GtkTreeViewColumn *column;
  gtk_tree_view_get_cursor(GTK_TREE_VIEW(pm_view), &path, &column);
  l_pm_get_full_path(path);
  l_pm_perform_menu_action(text);
}

/**
 * Toggles the focus between the Project Manager and the current Scintilla
 * window.
 */
void pm_toggle_focus() {
  gtk_widget_grab_focus(
    GTK_WIDGET_HAS_FOCUS(focused_editor) ? pm_entry : focused_editor);
}

/**
 * When searching the Project Manager treeview, matches are tree items that
 * contain the search text as a substring.
 * @param model The GtkTreeModel for the treeview.
 * @param col The column number to use for comparing search text to.
 * @param key The search text.
 * @param iter The GtkTreeIter for each tree node being compared.
 */
static int pm_search_equal_func(GtkTreeModel *model, int col, const char *key,
                                GtkTreeIter *iter, gpointer) {
  const char *text;
  gtk_tree_model_get(model, iter, col, &text, -1);
  return strstr(text, key) == NULL; // false is really a match like strcmp
}

/**
 * Sorts the Project Manager treeview case sensitively.
 * @param model The GtkTreeModel for the treeview.
 * @param a The GtkTreeIter for one tree node being compared.
 * @param b The GtkTreeIter for the other tree node being compared.
 */
static int pm_sort_iter_compare_func(GtkTreeModel *model, GtkTreeIter *a,
                                     GtkTreeIter *b, gpointer) {
  const char *a_text, *b_text;
  gtk_tree_model_get(model, a, 1, &a_text, -1);
  gtk_tree_model_get(model, b, 1, &b_text, -1);
  if (a_text == NULL && b_text == NULL) return 0;
  else if (a_text == NULL) return -1;
  else if (b_text == NULL) return 1;
  else return strcasecmp(a_text, b_text);
}

// Signals

/**
 * Signal for the activation of the Project Manager entry.
 * Requests contents for the treeview.
 * @see l_pm_get_contents_for
 */
static void pm_entry_activated(GtkWidget *widget, gpointer) {
  const char *entry_text = gtk_entry_get_text(GTK_ENTRY(widget));
  if (l_pm_get_contents_for(entry_text)) l_pm_populate();
}

/**
 * Signal for a Project Manager keypress.
 * Currently handled keypresses:
 *   - Ctrl+Tab - Refocuses the Scintilla view.
 *   - Escape - Refocuses the Scintilla view.
 */
static bool pm_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  if ((event->keyval == 0xff09 && event->state == GDK_CONTROL_MASK) ||
      event->keyval == 0xff1b) {
    gtk_widget_grab_focus(focused_editor);
    return true;
  } else return false;
}

/**
 * Signal for a Project Manager parent expansion.
 * @see pm_open_parent
 */
static void pm_row_expanded(GtkTreeView *, GtkTreeIter *iter,
                            GtkTreePath *path, gpointer) {
  pm_open_parent(iter, path);
}

/**
 * Signal for a Project Manager parent collapse.
 * @see pm_close_parent
 */
static void pm_row_collapsed(GtkTreeView *, GtkTreeIter *iter,
                             GtkTreePath *path, gpointer) {
  pm_close_parent(iter, path);
}

/**
 * Signal for the activation of a Project Manager node.
 * @see pm_activate_selection
 */
static void pm_row_activated(GtkTreeView *, GtkTreePath *, GtkTreeViewColumn *,
                             gpointer) {
  pm_activate_selection();
}

/**
 * Signal for a Project Manager mouse click.
 * If it is a right-click, popup a context menu for the selected node.
 * @see pm_popup_context_menu
 */
static bool pm_button_press(GtkTreeView *, GdkEventButton *event, gpointer) {
  if (event->type != GDK_BUTTON_PRESS || event->button != 3) return false;
  pm_popup_context_menu(event); return true;
}

/**
 * Signal for popping up a Project Manager context menu.
 * Typically Shift+F10 activates this event.
 * @see pm_popup_context_menu
 */
static bool pm_popup_menu(GtkWidget *, gpointer) {
  pm_popup_context_menu(NULL); return true;
}

/**
 * Signal for a selected Project Manager menu item.
 * @see pm_process_selected_menu_item
 */
static void pm_menu_activate(GtkWidget *menu_item, gpointer) {
  pm_process_selected_menu_item(menu_item);
}

// Find/Replace

#define attach(w, x1, x2, y1, y2, xo, yo, xp, yp) \
  gtk_table_attach(GTK_TABLE(findbox), w, x1, x2, y1, y2, xo, yo, xp, yp)
#define find_text gtk_entry_get_text(GTK_ENTRY(find_entry))
#define repl_text gtk_entry_get_text(GTK_ENTRY(replace_entry))
#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))

/**
 * Creates the Find/Replace text frame.
 */
GtkWidget* find_create_ui() {
  findbox = gtk_table_new(2, 6, false);

  GtkWidget *flabel = gtk_label_new_with_mnemonic("_Find:");
  GtkWidget *rlabel = gtk_label_new_with_mnemonic("R_eplace:");
  find_entry = gtk_entry_new();
  gtk_widget_set_name(find_entry, "textadept-find-entry");
  replace_entry = gtk_entry_new();
  gtk_widget_set_name(replace_entry, "textadept-replace-entry");
  fnext_button = gtk_button_new_with_mnemonic("Find _Next");
  fprev_button = gtk_button_new_with_mnemonic("Find _Prev");
  r_button = gtk_button_new_with_mnemonic("_Replace");
  ra_button = gtk_button_new_with_mnemonic("Replace _All");
  match_case_opt = gtk_check_button_new_with_mnemonic("_Match case");
  whole_word_opt = gtk_check_button_new_with_mnemonic("_Whole word");
  //incremental_opt = gtk_check_button_new_with_mnemonic("_Incremental");
  lua_opt = gtk_check_button_new_with_mnemonic("_Lua pattern");

  gtk_label_set_mnemonic_widget(GTK_LABEL(flabel), find_entry);
  gtk_label_set_mnemonic_widget(GTK_LABEL(rlabel), replace_entry);
  //gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(lua_opt), true);

  attach(find_entry, 1, 2, 0, 1, expand, normal, 5, 0);
  attach(replace_entry, 1, 2, 1, 2, expand, normal, 5, 0);
  attach(flabel, 0, 1, 0, 1, normal, normal, 5, 0);
  attach(rlabel, 0, 1, 1, 2, normal, normal, 5, 0);
  attach(fnext_button, 2, 3, 0, 1, normal, normal, 0, 0);
  attach(fprev_button, 3, 4, 0, 1, normal, normal, 0, 0);
  attach(r_button, 2, 3, 1, 2, normal, normal, 0, 0);
  attach(ra_button, 3, 4, 1, 2, normal, normal, 0, 0);
  attach(match_case_opt, 4, 5, 0, 1, normal, normal, 5, 0);
  attach(whole_word_opt, 4, 5, 1, 2, normal, normal, 5, 0);
  //attach(incremental_opt, 5, 6, 0, 1, normal, normal, 5, 0);
  attach(lua_opt, 5, 6, 0, 1, normal, normal, 5, 0);

  signal(find_entry, "key_press_event", fe_keypress);
  signal(replace_entry, "key_press_event", re_keypress);
  signal(fnext_button, "clicked", button_clicked);
  signal(fprev_button, "clicked", button_clicked);
  signal(r_button, "clicked", button_clicked);
  signal(ra_button, "clicked", button_clicked);

  GTK_WIDGET_UNSET_FLAGS(fnext_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(fprev_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(r_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(ra_button, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(match_case_opt, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(whole_word_opt, GTK_CAN_FOCUS);
  //GTK_WIDGET_UNSET_FLAGS(incremental_opt, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(lua_opt, GTK_CAN_FOCUS);

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
  } else {
    gtk_widget_grab_focus(focused_editor);
    gtk_widget_hide(findbox);
  }
}

/**
 * Builds the integer flags for a Find/Replace depending on the options that are
 * checked.
 */
static int get_flags() {
  int flags = 0;
  if (toggled(match_case_opt)) flags |= SCFIND_MATCHCASE; // 2
  if (toggled(whole_word_opt)) flags |= SCFIND_WHOLEWORD; // 4
  if (toggled(lua_opt)) flags |= 8;
  return flags;
}

/**
 * Signal for a Find entry keypress.
 * Currently handled keypresses:
 *   - Enter - Find next or previous.
 */
static bool fe_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  // TODO: if incremental, call l_find()
  if (event->keyval == 0xff0d) {
    l_find(find_text, get_flags(), true);
    return true;
  } else return false;
}

/**
 * Signal for a Replace entry keypress.
 * Currently handled keypresses:
 *   - Enter - Find next or previous.
 */
static bool re_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  if (event->keyval == 0xff0d) {
    l_find(find_text, get_flags(), true);
    return true;
  } else return false;
}

/**
 * Signal for a button click.
 * Performs the appropriate action depending on the button clicked.
 */
static void button_clicked(GtkWidget *button, gpointer) {
  if (button == ra_button)
    l_find_replace_all(find_text, repl_text, get_flags());
  else if (button == r_button) {
    l_find_replace(repl_text);
    l_find(find_text, get_flags(), true);
  } else l_find(find_text, get_flags(), button == fnext_button);
}

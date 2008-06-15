// Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)

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
  if (event->keyval == 0xff09 && event->state == GDK_CONTROL_MASK ||
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

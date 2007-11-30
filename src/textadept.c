// Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"
#include "properties.h"

#define signal(o, s, c) g_signal_connect(G_OBJECT(o), s, G_CALLBACK(c), 0)

GtkWidget
  *window, *focused_editor, *command_entry,
  *menubar, *statusbar, *docstatusbar;

static void c_activated(GtkWidget *widget, gpointer);
static bool c_keypress(GtkWidget *widget, GdkEventKey *event, gpointer);
static void t_notification(GtkWidget*, gint, gpointer lParam, gpointer);
static void t_command(GtkWidget *editor, gint wParam, gpointer, gpointer);
static bool t_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static bool w_focus(GtkWidget*, GdkEventFocus *, gpointer);
static bool w_keypress(GtkWidget*, GdkEventKey *event, gpointer);
static bool w_exit(GtkWidget*, GdkEventAny*, gpointer);

int main(int argc, char **argv) {
  gtk_init(&argc, &argv);
  l_init(argc, argv);
  create_ui();
  l_load_script("init.lua");
  gtk_main();
  return 0;
}

void create_ui() {
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

GtkWidget* new_scintilla_window(sptr_t buffer_id) {
  GtkWidget *editor = scintilla_new();
  gtk_widget_set_size_request(editor, 1, 1); // minimum size
  signal(editor, "key_press_event", t_keypress);
  signal(editor, "command", t_command);
  signal(editor, SCINTILLA_NOTIFY, t_notification);
  set_default_editor_properties(SCINTILLA(editor));
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

void remove_scintilla_window(GtkWidget *editor) {
  l_remove_scintilla_window(editor);
  gtk_widget_destroy(editor);
}

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
  // Setup default styling and properties.
  SS(sci, SCI_STYLESETFONT, 32,
     reinterpret_cast<long>("!Bitstream Vera Sans Mono"));
  SS(sci, SCI_STYLESETSIZE, 32, 8);
  SS(sci, SCI_STYLESETFORE, 32, 0xAA | (0xAA << 8) | (0xAA << 16));
  SS(sci, SCI_STYLESETBACK, 32, 0x33 | (0x33 << 8) | (0x33 << 16));
  set_default_buffer_properties(sci);
  l_set_buffer_global(sci);
  l_handle_event("buffer_new");
}

void remove_scintilla_buffer(sptr_t doc) {
  l_remove_scintilla_buffer(doc);
  SS(SCINTILLA(focused_editor), SCI_RELEASEDOCUMENT, 0, doc);
}

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

void remove_scintilla_windows_in_pane(GtkWidget *pane) {
  GtkWidget *child1 = gtk_paned_get_child1(GTK_PANED(pane));
  GtkWidget *child2 = gtk_paned_get_child2(GTK_PANED(pane));
  GTK_IS_PANED(child1) ? remove_scintilla_windows_in_pane(child1)
                       : remove_scintilla_window(child1);
  GTK_IS_PANED(child2) ? remove_scintilla_windows_in_pane(child2)
                       : remove_scintilla_window(child2);
}

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

void resize_split(GtkWidget *editor, int pos, bool increment) {
  GtkWidget *pane = gtk_widget_get_parent(editor);
  int width = gtk_paned_get_position(GTK_PANED(pane));
  gtk_paned_set_position(GTK_PANED(pane), pos + (increment ? width : 0));
}

void set_menubar(GtkWidget *new_menubar) {
  GtkWidget *vbox = gtk_widget_get_parent(menubar);
  gtk_container_remove(GTK_CONTAINER(vbox), menubar);
  menubar = new_menubar;
  gtk_box_pack_start(GTK_BOX(vbox), menubar, false, false, 0);
  gtk_box_reorder_child(GTK_BOX(vbox), menubar, 0);
  gtk_widget_show_all(menubar);
}

void set_statusbar_text(const char *text) {
  gtk_statusbar_pop(GTK_STATUSBAR(statusbar), 0);
  gtk_statusbar_push(GTK_STATUSBAR(statusbar), 0, text);
}

void set_docstatusbar_text(const char *text) {
  gtk_statusbar_pop(GTK_STATUSBAR(docstatusbar), 0);
  gtk_statusbar_push(GTK_STATUSBAR(docstatusbar), 0, text);
}

void command_toggle_focus() {
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

static void c_activated(GtkWidget *widget, gpointer) {
  l_handle_event("hide_completions");
  l_ta_command(gtk_entry_get_text(GTK_ENTRY(widget)));
  command_toggle_focus();
}

/** Command entry key events.
 *  Escape - Hide the completion buffer if it's open.
 *  Tab - Show completion buffer.
 */
static bool c_keypress(GtkWidget *widget, GdkEventKey *event, gpointer) {
  if (event->state == 0)
    switch(event->keyval) {
      case 0xff1b:
        l_handle_event("hide_completions");
        command_toggle_focus();
        return true;
      case 0xff09:
        l_handle_event("show_completions",
                        gtk_entry_get_text(GTK_ENTRY(widget)));
        return true;
    }
  return false;
}

static void t_notification(GtkWidget*, gint, gpointer lParam, gpointer) {
  SCNotification *n = reinterpret_cast<SCNotification*>(lParam);
  l_handle_scnnotification(n);
}

static void t_command(GtkWidget *editor, gint wParam, gpointer, gpointer) {
  if (wParam >> 16 == SCEN_SETFOCUS) {
    focused_editor = editor;
    l_set_view_global(editor);
    l_set_buffer_global(SCINTILLA(editor));
  }
}

static bool t_keypress(GtkWidget*, GdkEventKey *event, gpointer) {
  bool shift = event->state & GDK_SHIFT_MASK;
  bool control = event->state & GDK_CONTROL_MASK;
  bool alt = event->state & GDK_MOD1_MASK;
  return l_handle_keypress(event->keyval, shift, control, alt);
}

static bool w_focus(GtkWidget*, GdkEventFocus*, gpointer) {
  if (focused_editor && !GTK_WIDGET_HAS_FOCUS(focused_editor))
    gtk_widget_grab_focus(focused_editor);
  return false;
}

/** Window key events.
 *  Escape - hides the search dialog if it's open.
 */
static bool w_keypress(GtkWidget*, GdkEventKey *event, gpointer) {
  if (event->keyval == 0xff1b && GTK_WIDGET_VISIBLE(findbox)) {
    gtk_widget_hide(findbox);
    gtk_widget_grab_focus(focused_editor);
    return true;
  } else return false;
}

static bool w_exit(GtkWidget*, GdkEventAny*, gpointer) {
  if (!l_handle_event("quit")) return true;
  l_close();
  scintilla_release_resources();
  gtk_main_quit();
  return false;
}

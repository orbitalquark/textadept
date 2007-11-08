// Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

#define attach(w, x1, x2, y1, y2, xo, yo, xp, yp) \
  gtk_table_attach(GTK_TABLE(findbox), w, x1, x2, y1, y2, xo, yo, xp, yp)
#define find_text gtk_entry_get_text(GTK_ENTRY(find_entry))
#define repl_text gtk_entry_get_text(GTK_ENTRY(replace_entry))
#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))

GtkWidget *findbox, *find_entry, *replace_entry;
GtkWidget *fnext_button, *fprev_button, *r_button, *ra_button;
GtkWidget *match_case_opt, *whole_word_opt, /**incremental_opt,*/ *lua_opt;
GtkAttachOptions
  normal = static_cast<GtkAttachOptions>(GTK_SHRINK | GTK_FILL),
  expand = static_cast<GtkAttachOptions>(GTK_EXPAND | GTK_FILL);

static bool
  fe_keypress(GtkWidget*, GdkEventKey *event, gpointer),
  re_keypress(GtkWidget*, GdkEventKey *event, gpointer);

static void button_clicked(GtkWidget *button, gpointer);

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

  g_signal_connect(G_OBJECT(find_entry), "key_press_event",
                   G_CALLBACK(fe_keypress), 0);
  g_signal_connect(G_OBJECT(replace_entry), "key_press_event",
                   G_CALLBACK(re_keypress), 0);
  g_signal_connect(G_OBJECT(fnext_button), "clicked",
                   G_CALLBACK(button_clicked), 0);
  g_signal_connect(G_OBJECT(fprev_button), "clicked",
                   G_CALLBACK(button_clicked), 0);
  g_signal_connect(G_OBJECT(r_button), "clicked",
                   G_CALLBACK(button_clicked), 0);
  g_signal_connect(G_OBJECT(ra_button), "clicked",
                   G_CALLBACK(button_clicked), 0);

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

void find_toggle_focus() {
  if (!GTK_WIDGET_HAS_FOCUS(findbox)) {
    gtk_widget_show(findbox);
    gtk_widget_grab_focus(find_entry);
  } else {
    gtk_widget_grab_focus(focused_editor);
    gtk_widget_hide(findbox);
  }
}

static int get_flags() {
  int flags = 0;
  if (toggled(match_case_opt)) flags |= SCFIND_MATCHCASE; // 2
  if (toggled(whole_word_opt)) flags |= SCFIND_WHOLEWORD; // 4
  if (toggled(lua_opt)) flags |= 8;
  return flags;
}

/** Find entry key event.
 *  Enter - Find next or previous.
 */
static bool fe_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  // TODO: if incremental, call l_find()
  if (event->keyval == 0xff0d) {
    l_find(find_text, get_flags(), true);
    return true;
  } else return false;
}

/** Replace entry key event.
 *  Enter - Find next or previous.
 */
static bool re_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  if (event->keyval == 0xff0d) {
    l_find(find_text, get_flags(), true);
    return true;
  } else return false;
}

static void button_clicked(GtkWidget *button, gpointer) {
  if (button == ra_button)
    l_find_replace_all(find_text, repl_text, get_flags());
  else if (button == r_button) {
    l_find_replace(repl_text);
    l_find(find_text, get_flags(), true);
  } else l_find(find_text, get_flags(), button == fnext_button);
}

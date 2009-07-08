// Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#ifndef TEXTADEPT_H
#define TEXTADEPT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>

#define PLAT_GTK 1
#include <Scintilla.h>
#include <SciLexer.h>
#include <ScintillaWidget.h>

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#ifdef MAC
using namespace Scintilla;
#endif

// globals
extern GtkWidget *window, *focused_editor, *command_entry, *pm_container,
                 *pm_entry, *pm_view, *findbox, *find_entry, *replace_entry,
                 *fnext_button, *fprev_button, *r_button, *ra_button,
                 *match_case_opt, *whole_word_opt, *lua_opt, *in_files_opt;
extern char *textadept_home;

static long SS(ScintillaObject *sci, unsigned int msg, unsigned long wParam=0,
               long lParam=0) {
  return scintilla_send_message(sci, msg, wParam, lParam);
}

// textadept.c
void create_ui();
GtkWidget *new_scintilla_window(sptr_t default_id);
void remove_scintilla_window(GtkWidget *editor);
void new_scintilla_buffer(ScintillaObject *sci, bool create, bool addref);
void remove_scintilla_buffer(sptr_t doc);
void split_window(GtkWidget *editor, bool vertical);
bool unsplit_window(GtkWidget *editor);
void set_menubar(GtkWidget *menubar);
void set_statusbar_text(const char *text, bool docbar);
void pm_toggle_focus();
void find_toggle_focus();
void ce_toggle_focus();

// lua_interface.c
bool l_init(int argc, char **argv, bool reinit);
void l_close();
bool l_load_script(const char *script_file);
void l_add_scintilla_window(GtkWidget *editor);
void l_remove_scintilla_window(GtkWidget *editor);
void l_goto_scintilla_window(GtkWidget *editor, int n, bool absolute);
void l_set_view_global(GtkWidget *editor);
int  l_add_scintilla_buffer(sptr_t doc);
void l_remove_scintilla_buffer(sptr_t doc);
void l_goto_scintilla_buffer(GtkWidget *editor, int n, bool absolute);
void l_set_buffer_global(ScintillaObject *sci);

void l_handle_error(const char *errmsg);
bool l_handle_event(const char *e, const char *arg=NULL);
bool l_handle_keypress(int keyval, bool shift, bool control, bool alt);
void l_handle_scnnotification(SCNotification *n);
void l_ta_popup_context_menu(GdkEventButton *event);

void l_pm_view_fill(GtkTreeStore *store, GtkTreeIter *initial_iter);
void l_pm_perform_action(GtkTreeStore *store, GtkTreePath *path);
void l_pm_popup_context_menu(GtkTreeStore *store, GtkTreePath *path,
                             GdkEventButton *event, GCallback callback);
void l_pm_perform_menu_action(GtkTreeStore *store, GtkTreePath *path, int id);

void l_find(const char *ftext, bool next);
void l_find_replace(const char *rtext);
void l_find_replace_all(const char *ftext, const char *rtext);

void l_ce_command(const char *command);
void l_cec_fill(GtkListStore *store);

#endif

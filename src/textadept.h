// Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#ifndef TEXTADEPT_H
#define TEXTADEPT_H

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

// globals
extern GtkWidget *window, *focused_editor, *command_entry,
                 *findbox, *find_entry, *replace_entry,
                 *fnext_button, *fprev_button, *r_button, *ra_button,
                 *match_case_opt, *whole_word_opt, *lua_opt, *in_files_opt;
extern char *textadept_home;

#define SS(editor, m, w, l) scintilla_send_message(SCINTILLA(editor), m, w, l)

// textadept.c
void create_ui();
GtkWidget *new_scintilla_window(sptr_t);
void remove_scintilla_window(GtkWidget *);
void new_scintilla_buffer(GtkWidget *, int, int);
void remove_scintilla_buffer(sptr_t);
void split_window(GtkWidget *, int);
int unsplit_window(GtkWidget *);
void set_menubar(GtkWidget *);
void set_statusbar_text(const char *, int);
void find_toggle_focus();
void ce_toggle_focus();

// lua_interface.c
int l_init(int, char **, int);
void l_close();
int l_load_script(const char *);
void l_add_scintilla_window(GtkWidget *);
void l_remove_scintilla_window(GtkWidget *);
void l_goto_scintilla_window(GtkWidget *, int, int);
void l_set_view_global(GtkWidget *);
int  l_add_scintilla_buffer(sptr_t);
void l_remove_scintilla_buffer(sptr_t);
void l_goto_scintilla_buffer(GtkWidget *, int, int);
void l_set_buffer_global(GtkWidget *);

int l_handle_event(const char *, ...);
void l_handle_scnnotification(struct SCNotification *);
void l_ta_popup_context_menu(GdkEventButton *);

#endif

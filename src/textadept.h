// Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#ifndef TEXTADEPT_H
#define TEXTADEPT_H

#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>

#define PLAT_GTK 1
#include <Scintilla.h>
#include <SciLexer.h>
#include <ScintillaWidget.h>

#ifdef WIN32
#include "Windows.h"
#define strcasecmp _stricmp
#endif

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

// globals
extern GtkWidget
  *window, *focused_editor, *command_entry,
  *pm_container, *pm_entry, *pm_view,
  *findbox, *find_entry, *replace_entry;
extern GtkEntryCompletion *command_entry_completion;
extern GtkTreeStore *cec_store, *pm_store;
extern lua_State *lua;
#ifndef WIN32
static const char *textadept_home = "/usr/share/textadept/";
#else
extern char *textadept_home;
#endif

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
void set_statusbar_text(const char *text);
void set_docstatusbar_text(const char *text);
void ce_toggle_focus();

GtkWidget *pm_create_ui();
void pm_toggle_focus();
void pm_open_parent(GtkTreeIter *iter, GtkTreePath *path);
void pm_close_parent(GtkTreeIter *iter, GtkTreePath *path);
void pm_activate_selection();
void pm_popup_context_menu(GdkEventButton *event, GCallback callback);
void pm_process_selected_menu_item(GtkWidget *menu_item);

GtkWidget *find_create_ui();
void find_toggle_focus();

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

void l_handle_error(lua_State *lua, const char *errmsg);
bool l_handle_event(const char *e);
bool l_handle_event(const char *e, const char *arg);
bool l_handle_keypress(int keyval, bool shift, bool control, bool alt);
void l_handle_scnnotification(SCNotification *n);
void l_ta_command(const char *command);

bool l_cec_get_completions_for(const char *entry_text);
void l_cec_populate();

bool l_pm_get_contents_for(const char *entry_text, bool expanding);
void l_pm_populate(GtkTreeIter *initial_iter);
void l_pm_get_full_path(GtkTreePath *path);
void l_pm_perform_action();
void l_pm_popup_context_menu(GdkEventButton *event, GCallback callback);
void l_pm_perform_menu_action(const char *menu_item);

void l_find(const char *ftext, int flags, bool next);
void l_find_replace(const char *rtext);
void l_find_replace_all(const char *ftext, const char *rtext, int flags);

#endif

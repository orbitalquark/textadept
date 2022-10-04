// Copyright 2007-2022 Mitchell. See LICENSE.
// Interface between Textadept and platforms.

#include "platform.h"

// The currently focused view and command entry.
// Platforms are responsible for updating the focused view.
Scintilla *focused_view, *command_entry;

FindButton *find_next, *find_prev, *replace, *replace_all;
FindOption *match_case, *whole_word, *regex, *in_files;

lua_State *lua;
bool dialog_active; // for platforms with window focus issues when showing dialogs

bool emit(lua_State *L, const char *name, ...);

void find_clicked(FindButton *button, void *unused);

/**
 * Change focus to the given Scintilla view.
 * Generates 'view_before_switch' and 'view_after_switch' events.
 * @param view The Scintilla view to focus.
 */
void view_focused(Scintilla *view);

int get_int_field(lua_State *L, int index, int n);

/**
 * Shows the context menu.
 * @param name The ui table field that contains the context menu.
 * @param userdata Userdata to pass to `popup_menu()`.
 */
void show_context_menu(const char *name, void *userdata);

void move_buffer(int from, int to, bool reorder_tabs);

bool call_timeout_function(void *f);

void delete_view(Scintilla *view);

/** Signal for a Scintilla notification. */
void notified(Scintilla *view, int _, SCNotification *n, void *userdata);

bool init_textadept(int argc, char **argv);
void close_textadept();

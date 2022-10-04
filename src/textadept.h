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

/**
 * Emits an event.
 * @param name The event name.
 * @param ... Arguments to pass with the event. Each pair of arguments should be a Lua type
 *   followed by the data value itself. For LUA_TLIGHTUSERDATA and LUA_TTABLE types, push the
 *   data values to the stack and give the value returned by luaL_ref(); luaL_unref() will be
 *   called appropriately. The list must be terminated with a -1.
 * @return true or false depending on the boolean value returned by the event handler, if any.
 */
bool emit(const char *name, ...);

void find_clicked(FindButton *button, void *unused);

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

bool init_textadept(int argc, char **argv);
void close_textadept();

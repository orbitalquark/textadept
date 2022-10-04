// Copyright 2007-2022 Mitchell. See LICENSE.

#include "lua.h"
#include "Scintilla.h"

#include <stdbool.h>

typedef void Scintilla;
typedef void Pane;
typedef void FindButton;
typedef void FindOption;

const char *get_platform();

// Window.
sptr_t SS(Scintilla *view, int message, uptr_t wparam, sptr_t lparam);
void focus_view(Scintilla *view);
void delete_scintilla(Scintilla *view);
typedef struct PaneInfo {
  bool is_split, vertical;
  Scintilla *view;
  Pane *self, *child1, *child2;
  int size;
} PaneInfo;
// Find & replace pane.
const char *get_find_text();
const char *get_repl_text();
void set_find_text(const char *text);
void set_repl_text(const char *text);
bool checked(FindOption *option);
void toggle(FindOption *option, bool on);
void set_find_label(const char *text);
void set_repl_label(const char *text);
void set_button_label(FindButton *button, const char *text);
void set_option_label(FindOption *option, const char *text);
bool find_active();
// Command entry.
bool is_command_entry_active();

/**
 * Adds the given text to the find history list if it is not at the top.
 * @param text The text to add.
 */
void add_to_find_history(const char *text);
void add_to_repl_history(const char *text);

void focus_find();

void set_entry_font(const char *name);

void focus_command_entry();

PaneInfo get_pane_info(Pane *pane);

Pane *get_top_pane();

// 0-based index.
void set_tab(int index);

/**
 * Creates and returns a menu from the table at the given valid index.
 * Consult the LuaDoc for the table format.
 * @param L The Lua state.
 * @param index The stack index of the table to create the menu from.
 */
void *read_menu(lua_State *L, int index);

/**
 * Displays a popup menu.
 * @param menu The menu produced by `read_menu()` to display.
 * @param userdata Userdata for platform use.
 */
void popup_menu(void *menu, void *userdata);

void update_ui();

// Returned value must be allocated; will be freed.
char *get_clipboard_text(int *len);

bool is_maximized();

void get_size(int *width, int *height);

void set_statusbar_text(int bar, const char *text);

void set_title(const char *title);

void set_menubar(lua_State *L, int index);

void set_maximized(bool maximize);

void set_size(int width, int height);

void show_tabs(bool show);

// 0-based index.
void remove_tab(int index);

// 0-based index.
const char *get_tab_label(int index);

int get_command_entry_height();

// 0-based index.
void set_tab_label(int index, const char *text);

void set_command_entry_height(int height);

// Added to end.
void add_tab();

// 0-based indices.
void move_tab(int from, int to);

void quit();

bool add_timeout(double interval, void *f);

const char *get_charset();

/**
 * Removes all Scintilla views from the given pane and deletes them along with the child panes
 * themselves.
 * @param pane The pane to remove Scintilla views from.
 * @see delete_view
 */
void remove_views(Pane *pane);

/**
 * Unsplits the pane the given Scintilla view is in and keeps the view.
 * All views in the other pane are deleted.
 * @param view The Scintilla view to keep when unsplitting.
 * @return true if the view was split; false otherwise
 * @see remove_views
 * @see delete_view
 */
bool unsplit_view(Scintilla *view);

/**
 * Splits the pane holding the given Scintilla view into two views.
 * @param view The Scintilla view whose pane is to be split.
 * @param view2 The Scintilla view to add to the the newly split pane.
 * @param vertical Flag indicating whether to split the view vertically or horizontally.
 */
void split_view(Scintilla *view, Scintilla *view2, bool vertical);

Scintilla *new_scintilla(
  void (*notified)(Scintilla *sci, int iMessage, SCNotification *n, void *userdata));

PaneInfo get_pane_info_from_view(Scintilla *view);

void set_pane_size(Pane *pane, int size);

/**
 * Creates the Textadept window on the current platform.
 * The window contains a menubar, frame for Scintilla views, hidden find box, hidden command
 * entry, and two status bars: one for notifications and the other for buffer status.
 * @param get_view Function to call when the platform is ready to accept the first Scintilla view.
 *   The platform should be ready to create tab for that view at the very least.
 */
void new_window(Scintilla *(*get_view)(void));

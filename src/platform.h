// Copyright 2007-2022 Mitchell. See LICENSE.
// Interface between Textadept and platforms.
// Textadept calls these functions to communicate with the platform.

#include "lua.h"
#include "Scintilla.h"

#include <stdbool.h>

typedef void Scintilla;
typedef void Pane;
typedef void FindButton;
typedef void FindOption;

/** Returns the name of the platform. */
const char *get_platform();

/**
 * Sends a message to the given Scintilla view.
 * @param view The Scintilla view to send a message to.
 * @param message Message ID.
 * @param wparam First message parameter.
 * @param lparam Second message parameter.
 * @return Scintilla result
 */
sptr_t SS(Scintilla *view, int message, uptr_t wparam, sptr_t lparam);

/** Signals the platform to focus the given Scintilla view. */
void focus_view(Scintilla *view);

/** Signals the platform to delete the given Scintilla view. */
void delete_scintilla(Scintilla *view);

/** Contains information about the pane holding one or more Scintilla views. */
typedef struct PaneInfo {
  bool is_split, vertical;
  Scintilla *view;
  Pane *self, *child1, *child2;
  int size;
} PaneInfo;

/** Returns the find & replace pane's find entry text. */
const char *get_find_text();
/** Returns the find & replace pane's replace entry text. */
const char *get_repl_text();
/** Sets the find & replace pane's find entry text. */
void set_find_text(const char *text);
/** Sets the find & replace pane's replace entry text. */
void set_repl_text(const char *text);
/** Returns whether or not the given find & replace pane option is checked. */
bool is_checked(FindOption *option);
/** Toggles the given find & replace pane option to on or off. */
void toggle(FindOption *option, bool on);
/** Sets the find & replace pane's find label text. */
void set_find_label(const char *text);
/** Sets the find & replace pane's replace label text. */
void set_repl_label(const char *text);
/** Sets the given find & replace pane button's text. */
void set_button_label(FindButton *button, const char *text);
/** Sets the given find & replace pane option's text. */
void set_option_label(FindOption *option, const char *text);
/** Returns whether or not the find & replace pane is active. */
bool is_find_active();
/** Returns whether or not the command entry is active. */
bool is_command_entry_active();

/** Adds the given text to the find & replace pane's find history list. */
void add_to_find_history(const char *text);
/** Adds the given text to the find & replace pane's replace history list. */
void add_to_repl_history(const char *text);

/** Toggles the focus of the find & replace pane. */
void focus_find();

/** Sets the font of the find & replace pane's find and replace entries to the given name. */
void set_entry_font(const char *name);

/** Toggles the command entry between active and hidden. */
void focus_command_entry();

/**
 * Returns information about the given pane.
 * @see get_pane_info_from_view
 */
PaneInfo get_pane_info(Pane *pane);

/** Returns the top-most pane. */
Pane *get_top_pane();

/** Signals the platform to switch to the tab at the given index. */
void set_tab(int index); // 0-based

/**
 * Asks the platform to create and return a menu from the Lua table at the given valid index.
 * Consult the LuaDoc for the table format.
 */
void *read_menu(lua_State *L, int index);

/**
 * Asks the platform to display the given popup menu.
 * @param menu The menu produced by `read_menu()` to display.
 * @param userdata Userdata for platform use (e.g. from `show_context_menu()`).
 * @see show_context_menu
 */
void popup_menu(void *menu, void *userdata);

/** Asks the platform to update the UI by painting views, processing the main event queue, etc. */
void update_ui();

/**
 * Asks the platform to return the text currently on its clipboard.
 * The length of the returned text is stored in the given integer.
 * The platform must return an allocated string -- Textadept will call free() on it.
 */
char *get_clipboard_text(int *len);

/** Returns whether or not the Textadept window is maximized. */
bool is_maximized();

/** Stores the width and height of the Textadept window into the given variables. */
void get_size(int *width, int *height);

/** Sets the content of statusbar number 0 or 1 to the given text. */
void set_statusbar_text(int bar, const char *text);

/** Sets the title of the Textadept window to the given text. */
void set_title(const char *title);

/**
 * Asks the platform to read and set a menubar from the Lua table at the given valid index.
 * This is a list of menu tables. Consult the LuaDoc for the table format.
 */
void set_menubar(lua_State *L, int index);

/** Sets the maximized state of the Textadept window. */
void set_maximized(bool maximize);

/** Sets the width and height of the Textadept window. */
void set_size(int width, int height);

/** Sets whether or not the Textadept window should show tabs for its buffers. */
void show_tabs(bool show);

/** Signals the platform to remove the tab at the given index. */
void remove_tab(int index); // 0-based

/** Returns the height of the command entry. */
int get_command_entry_height();

/** Sets the text of the tab label at the given index. */
void set_tab_label(int index, const char *text); // 0-based

/** Sets the height of the command entry. The command entry must be active. */
void set_command_entry_height(int height);

/** Signals the platform to add a tab to the end of its tab list. */
void add_tab();

/** Signals the platform to move one of its buffer tabs. */
void move_tab(int from, int to); // 0-based

/** Signals the platform to quit. The user has already been prompted to confirm. */
void quit();

/**
 * Asks the platform to run the given function after the given number of seconds using
 * `call_timeout_function()`.
 * The platform should continue calling `call_timeout_function()` for as long as it returns `true`.
 * @param interval Number of seconds between calls to the given function.
 * @param f Function to call using `call_timeout_function()`.
 * @see call_timeout_function
 */
bool add_timeout(double interval, void *f);

/** Returns the character set used by the platform's filesystem. */
const char *get_charset();

/**
 * Unsplits the pane the given Scintilla view is in and keeps the view.
 * All views in the other pane should be deleted using the given deleter function.
 * @param view The Scintilla view to keep when unsplitting.
 * @param delete_view Deleter function to call for each view removed from split panes.
 * @return true if the view was in a split pane; false otherwise
 * @see delete_view
 */
bool unsplit_view(Scintilla *view, void (*delete_view)(Scintilla *));

/**
 * Splits the pane holding the given Scintilla view into two views.
 * @param view The Scintilla view whose pane is to be split.
 * @param view2 The Scintilla view to add to the the newly split pane.
 * @param vertical Flag indicating whether to split the view vertically or horizontally.
 */
void split_view(Scintilla *view, Scintilla *view2, bool vertical);

/**
 * Asks the platform to create a return a new Scintilla view that notifies the given callback
 * function with Scintilla notifications.
 * @param notified Scintilla notification function. It may be NULL.
 * @return Scintilla view
 */
Scintilla *new_scintilla(
  void (*notified)(Scintilla *sci, int iMessage, SCNotification *n, void *userdata));

/**
 * Returns information about the pane that contains the given Scintilla view.
 * @see get_pane_info
 */
PaneInfo get_pane_info_from_view(Scintilla *view);

/** Sets the Pane's divider position to the given size. */
void set_pane_size(Pane *pane, int size);

/**
 * Creates the Textadept window on the current platform.
 * The window contains a menubar, frame for Scintilla views, hidden find box, hidden command
 * entry, and two status bars: one for notifications and the other for buffer status.
 * @param get_view Function to call when the platform is ready to accept the first Scintilla view.
 *   The platform should be ready to create tab for that view at the very least.
 */
void new_window(Scintilla *(*get_view)(void));

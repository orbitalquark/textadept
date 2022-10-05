// Copyright 2007-2022 Mitchell. See LICENSE.
// Interface between Textadept and platforms.
// Textadept calls these functions to communicate with the platform.
//
// Platforms are expected to implement the `main()` entry point of the program, perform any
// platform-specific initialization required on startup, call `init_textadept()` to initialize
// Textadept (which in turn creates the window, etc.), and then start the main event loop. Prior
// to exiting the main loop, platforms will typically want to call `close_textadept()` to clean
// up and release resources before quitting for good.

#include "lua.h"
#include "Scintilla.h"

#include <stdbool.h>

typedef void Scintilla;
typedef void Pane;
typedef void FindButton;
typedef void FindOption;

/** Contains information about the pane holding one or more Scintilla views. */
typedef struct PaneInfo {
  bool is_split, vertical;
  Scintilla *view;
  Pane *self, *child1, *child2;
  int size;
} PaneInfo;

/** Returns the name of the platform. */
const char *get_platform();
/** Returns the character set used by the platform's filesystem. */
const char *get_charset();

/**
 * Asks the platform to create the Textadept window.
 * The window contains a menubar, frame for Scintilla views, hidden find box, hidden command
 * entry, and two status bars: one for notifications and the other for buffer status.
 *
 * At this time, platforms are expected only to construct the bare essentials of the
 * window. Textadept will call on the platform to fill in more details later, such as setting
 * a title, defining menus in a menubar, adding tabs, setting find & replace pane button and
 * option labels, and setting statusbar text. The exception to this is that the platform must
 * call the given function to create the first Scintilla view when it is ready to accept it.
 *
 * Note that Textadept does not create one view per tab, so platforms are expected to keep the
 * tab bar and Scintilla views separate.
 *
 * @param get_view Function to call when the platform is ready to accept the first Scintilla view.
 *   The platform should be ready to create tab for that view at the very least.
 */
void new_window(Scintilla *(*get_view)(void));
/** Sets the title of the Textadept window to the given text. */
void set_title(const char *title);
/** Returns whether or not the Textadept window is maximized. */
bool is_maximized();
/** Sets the maximized state of the Textadept window. */
void set_maximized(bool maximize);
/** Stores the current width and height of the Textadept window into the given variables. */
void get_size(int *width, int *height);
/** Sets the width and height of the Textadept window to the given values. */
void set_size(int width, int height);

/**
 * Asks the platform to create and return a new Scintilla view that calls the given callback
 * function with Scintilla notifications.
 * @param notified Scintilla notification function. It may be NULL.
 * @return Scintilla view
 */
Scintilla *new_scintilla(void (*notified)(Scintilla *, int, SCNotification *, void *));
/** Signals the platform to focus the given Scintilla view. */
void focus_view(Scintilla *view);
/**
 * Asks the platform to send a message to the given Scintilla view.
 * @param view The Scintilla view to send a message to.
 * @param message Message ID.
 * @param wparam First message parameter.
 * @param lparam Second message parameter.
 * @return Scintilla result
 */
sptr_t SS(Scintilla *view, int message, uptr_t wparam, sptr_t lparam);
/**
 * Asks the platform to split the pane holding the given Scintilla view into two views.
 * @param view The Scintilla view whose pane is to be split.
 * @param view2 The Scintilla view to add to the the newly split pane.
 * @param vertical Flag indicating whether to split the view vertically or horizontally.
 */
void split_view(Scintilla *view, Scintilla *view2, bool vertical);
/**
 * Asks the platform to unsplit the pane the given Scintilla view is in and keep the view.
 * All views in the other pane should be deleted using the given deleter function.
 * If the given view is not in a split pane, the platform should return `false` and do nothing.
 * @param view The Scintilla view to keep when unsplitting.
 * @param delete_view Deleter function to call for each view removed from split panes.
 * @return true if the view was in a split pane, false otherwise
 */
bool unsplit_view(Scintilla *view, void (*delete_view)(Scintilla *));
/**
 * Asks the platform to delete the given Scintilla view.
 * All the platform needs to do here is call Scintilla's platform-specific delete function. The
 * view has already been removed from any split panes (if any).
 */
void delete_scintilla(Scintilla *view);

/** Returns the top-most pane that contains Scintilla views. */
Pane *get_top_pane();
/**
 * Returns information about the given pane.
 * @see get_pane_info_from_view
 */
PaneInfo get_pane_info(Pane *pane);
/**
 * Returns information about the pane that contains the given Scintilla view.
 * @see get_pane_info
 */
PaneInfo get_pane_info_from_view(Scintilla *view);
/** Sets the given pane's divider position to the given size. */
void set_pane_size(Pane *pane, int size);

/** Sets whether or not the Textadept window should show tabs for its buffers. */
void show_tabs(bool show);
/**
 * Asks the platform to add a tab to the end of its tab list.
 * The platform is not expected to attach anything to the tab, as Textadept does not create
 * one view per tab.
 */
void add_tab();
/** Asks the platform to switch to the tab at the given index. */
void set_tab(int index); // 0-based
/** Sets the text of the tab label at the given index to the given text. */
void set_tab_label(int index, const char *text); // 0-based
/** Asks the platform to move one of its buffer tabs. */
void move_tab(int from, int to); // 0-based
/**
 * Asks the platform to remove the tab at the given index.
 * As Textadept does not have one view per tab, the platform is not expected to manage any
 * Scintilla views that might have been associated with that tab. It should simply delete the
 * tab and nothing else.
 */
void remove_tab(int index); // 0-based

/** Returns the find & replace pane's find entry text. */
const char *get_find_text();
/** Returns the find & replace pane's replace entry text. */
const char *get_repl_text();
/** Sets the find & replace pane's find entry text. */
void set_find_text(const char *text);
/** Sets the find & replace pane's replace entry text. */
void set_repl_text(const char *text);
/**
 * Asks the platform to add the given text to the find & replace pane's find history list.
 * The given text could be a duplicate. The platform is expected to handle them as it sees fit.
 */
void add_to_find_history(const char *text);
/**
 * Asks the platform to add the given text to the find & replace pane's replace history list.
 * The given text could be a duplicate. The platform is expected to handle them as it sees fit.
 */
void add_to_repl_history(const char *text);
/** Sets the font of the find & replace pane's find and replace entries to the given name. */
void set_entry_font(const char *name);
/** Returns whether or not the given find & replace pane option is checked. */
bool is_checked(FindOption *option);
/** Toggles the given find & replace pane option to on or off. */
void toggle(FindOption *option, bool on);
/** Sets the find & replace pane's find label text to the given text. */
void set_find_label(const char *text);
/** Sets the find & replace pane's replace label text to the given text. */
void set_repl_label(const char *text);
/** Sets the given find & replace pane button's text to the given text. */
void set_button_label(FindButton *button, const char *text);
/** Sets the given find & replace pane option's text to the given text. */
void set_option_label(FindOption *option, const char *text);
/**
 * Asks the platform to toggle the state of the find & replace pane.
 * If it is hidden, the platform should show it and set focus to the find entry. If the pane
 * is visible but unfocused, the platform should refocus it. Otherwise, the platform should
 * hide the pane and refocus the focused view.
 */
void focus_find();
/** Returns whether or not the find & replace pane is active. */
bool is_find_active();

/**
 * Asks the platform to toggle the command entry between active and hidden.
 * The command entry should never be unfocused and visible.
 */
void focus_command_entry();
/** Returns whether or not the command entry is active. */
bool is_command_entry_active();
/** Returns the height of the command entry. */
int get_command_entry_height();
/** Sets the height of the command entry. The command entry must be active. */
void set_command_entry_height(int height);

/** Sets the content of statusbar number 0 or 1 to the given text. */
void set_statusbar_text(int bar, const char *text);

/**
 * Asks the platform to create and return a menu from the Lua table at the given valid index.
 *
 * A menu is an ordered list of length-4 sub-tables with a string menu item, integer menu ID,
 * optional keycode, and modifier mask. The latter two are used to display key shortcuts in
 * the menu. '_' characters should be treated as menu mnemonics. If the menu item is empty,
 * a menu separator item should be created. Submenus are nested menu-structure tables. Their
 * title text is defined with a `title` key.
 *
 * The following Lua table is a simple menu: {{'_New', 1}, {'_Open', '2'}, {''}, {'_Quit', 4}}
 * The following Lua menu item contains a 'Ctrl+N' shortcut: {'_New', 1, string.byte('n'), 4}
 *
 * Note that at this time, keycodes and modifier masks are assumed to conform to GDK standards.
 *
 * Textadept will store the returned menu and either pass it to `popup_menu()` or put it in a
 * menubar table to be read from `set_menubar()`.
 * @see get_int_field
 */
void *read_menu(lua_State *L, int index);
/**
 * Asks the platform to display the given popup menu.
 * @param menu The menu produced by `read_menu()` to display.
 * @param userdata Userdata for platform use (e.g. from `show_context_menu()`).
 * @see show_context_menu
 */
void popup_menu(void *menu, void *userdata);
/**
 * Asks the platform to read and set a menubar from the Lua table at the given valid index.
 * This is a list of menu tables. Consult the documentation for `read_menu()` for the format
 * of individual menus.
 * @see read_menu
 */
void set_menubar(lua_State *L, int index);

/**
 * Asks the platform to return the text currently on its clipboard and store the length of that
 * text in the given integer.
 * The platform must return an allocated string -- Textadept will call free() on it.
 */
char *get_clipboard_text(int *len);

/**
 * Asks the platform to run the given function after the given number of seconds using
 * `call_timeout_function()`.
 * The platform should continue calling `call_timeout_function()` for as long as it returns `true`.
 * @param interval Number of seconds between calls to the given function.
 * @param f Function to call using `call_timeout_function()`.
 * @see call_timeout_function
 */
bool add_timeout(double interval, void *f);

/**
 * Asks the platform to update the UI by painting views, processing any pending events in the
 * main event queue, etc.
 * This primarily called to perform asynchronous actions like polling for spawned process output
 * and invoking Lua callback functions to process it.
 */
void update_ui();

/** Asks the platform to quit the application. The user has already been prompted to confirm. */
void quit();

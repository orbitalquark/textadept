// Copyright 2007-2024 Mitchell. See LICENSE.
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

typedef void SciObject;
typedef void Pane;
typedef void FindButton;
typedef void FindOption;

/** Contains information about the pane holding one or more Scintilla views. */
typedef struct {
	bool is_split, vertical;
	SciObject *view;
	Pane *self, *child1, *child2;
	int size;
} PaneInfo;

/** Contains dialog options.
 * Each type of dialog will only use a subset of options, not all of them.
 * The `columns` and `items` fields are Lua stack indices of the tables that contain them. The
 * `search_column` is 1-based.
 */
typedef struct {
	const char *title, *text, *icon, *buttons[3], *dir, *file;
	bool only_dirs, multiple, return_button;
	int columns, search_column, items, select;
} DialogOptions;

/** Contains information about a spawned child process.
 * The platform is expected to implement this (i.e. via a struct).
 */
typedef void Process;

/** Returns the upper-cased name of the platform. */
const char *get_platform(void);
/** Returns the character set used by the platform's filesystem. */
const char *get_charset(void);

/** Asks the platform to create the Textadept window.
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
 *	The platform should be ready to create tab for that view at the very least.
 */
void new_window(SciObject *(*get_view)(void));
/** Sets the title of the Textadept window to the given text. */
void set_title(const char *title);
/** Returns whether or not the Textadept window is maximized. */
bool is_maximized(void);
/** Sets the maximized state of the Textadept window. */
void set_maximized(bool maximize);
/** Stores the current width and height of the Textadept window into the given variables. */
void get_size(int *width, int *height);
/** Sets the width and height of the Textadept window to the given values. */
void set_size(int width, int height);

/** Asks the platform to create and return a new Scintilla view that calls the given callback
 * function with Scintilla notifications.
 * @param notified Scintilla notification function. It may be NULL. The int and void* parameters
 *	are unused and may be passed 0 and `NULL`, respectively. Only the view and notification
 *	parameters are needed.
 * @return Scintilla view
 */
SciObject *new_scintilla(void (*notified)(SciObject *, int, SCNotification *, void *));
/** Signals the platform to focus the given Scintilla view. */
void focus_view(SciObject *view);
/** Asks the platform to send a message to the given Scintilla view.
 * @param view The Scintilla view to send a message to.
 * @param message Message ID.
 * @param wparam First message parameter.
 * @param lparam Second message parameter.
 * @return Scintilla result
 */
sptr_t SS(SciObject *view, int message, uptr_t wparam, sptr_t lparam);
/** Asks the platform to split the pane holding the given Scintilla view into two views.
 * @param view The Scintilla view whose pane is to be split.
 * @param view2 The Scintilla view to add to the the newly split pane.
 * @param vertical Flag indicating whether to split the view vertically or horizontally.
 */
void split_view(SciObject *view, SciObject *view2, bool vertical);
/** Asks the platform to unsplit the pane the given Scintilla view is in and keep the view.
 * All views in the other pane should be deleted using the given deleter function.
 * If the given view is not in a split pane, the platform should return `false` and do nothing.
 * @param view The Scintilla view to keep when unsplitting.
 * @param delete_view Deleter function to call for each view removed from split panes.
 * @return true if the view was in a split pane, false otherwise
 */
bool unsplit_view(SciObject *view, void (*delete_view)(SciObject *));
/** Asks the platform to delete the given Scintilla view.
 * All the platform needs to do here is call Scintilla's platform-specific delete function. The
 * view has already been removed from any split panes (if any).
 */
void delete_scintilla(SciObject *view);

/** Returns the top-most pane that contains Scintilla views. */
Pane *get_top_pane(void);
/** Returns information about the given pane.
 * @see get_pane_info_from_view
 */
PaneInfo get_pane_info(Pane *pane);
/** Returns information about the pane that contains the given Scintilla view.
 * @see get_pane_info
 */
PaneInfo get_pane_info_from_view(SciObject *view);
/** Sets the given pane's divider position to the given size. */
void set_pane_size(Pane *pane, int size);

/** Sets whether or not the Textadept window should show tabs for its buffers. */
void show_tabs(bool show);
/** Asks the platform to add a tab to the end of its tab list.
 * The platform is not expected to attach anything to the tab, as Textadept does not create
 * one view per tab.
 */
void add_tab(void);
/** Asks the platform to switch to the tab at the given index. */
void set_tab(int index); // 0-based
/** Sets the text of the tab label at the given index to the given text. */
void set_tab_label(int index, const char *text); // 0-based
/** Asks the platform to move one of its buffer tabs. */
void move_tab(int from, int to); // 0-based
/** Asks the platform to remove the tab at the given index.
 * As Textadept does not have one view per tab, the platform is not expected to manage any
 * Scintilla views that might have been associated with that tab. It should simply delete the
 * tab and nothing else.
 */
void remove_tab(int index); // 0-based

/** Returns the find & replace pane's find entry text. */
const char *get_find_text(void);
/** Returns the find & replace pane's replace entry text. */
const char *get_repl_text(void);
/** Sets the find & replace pane's find entry text. */
void set_find_text(const char *text);
/** Sets the find & replace pane's replace entry text. */
void set_repl_text(const char *text);
/** Asks the platform to add the given text to the find & replace pane's find history list.
 * The given text could be a duplicate. The platform is expected to handle them as it sees fit.
 */
void add_to_find_history(const char *text);
/** Asks the platform to add the given text to the find & replace pane's replace history list.
 * The given text could be a duplicate. The platform is expected to handle them as it sees fit.
 */
void add_to_repl_history(const char *text);
/** Sets the font of the find & replace pane's find and replace entries based on the given
 * "name size" string (e.g. "Monospace 12").
 */
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
/** Asks the platform to toggle the state of the find & replace pane.
 * If it is hidden, the platform should show it and set focus to the find entry. If the pane
 * is visible but unfocused, the platform should refocus it. Otherwise, the platform should
 * hide the pane and refocus the focused view.
 */
void focus_find(void);
/** Returns whether or not the find & replace pane is active. */
bool is_find_active(void);

/** Asks the platform to toggle the command entry between active and hidden.
 * The command entry should never be unfocused and visible.
 */
void focus_command_entry(void);
/** Returns whether or not the command entry is active. */
bool is_command_entry_active(void);
/** Sets the command entry's label text to the given text. */
void set_command_entry_label(const char *text);
/** Returns the height of the command entry. */
int get_command_entry_height(void);
/** Sets the height of the command entry. The command entry must be active. */
void set_command_entry_height(int height);

/** Sets the content of statusbar number 0 or 1 to the given text. */
void set_statusbar_text(int bar, const char *text);

/** Asks the platform to create and return a menu from the Lua table at the given valid index.
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
/** Asks the platform to display the given popup menu.
 * @param menu The menu produced by `read_menu()` to display.
 * @param userdata Userdata for platform use (e.g. from `show_context_menu()`).
 * @see show_context_menu
 */
void popup_menu(void *menu, void *userdata);
/** Asks the platform to read and set a menubar from the Lua table at the given valid index.
 * This is a list of menu tables. Consult the documentation for `read_menu()` for the format
 * of individual menus.
 * @see read_menu
 */
void set_menubar(lua_State *L, int index);

/** Asks the platform to return the text currently on its clipboard and store the length of that
 * text in the given integer.
 * The platform must return an allocated string -- Textadept will call free() on it.
 */
char *get_clipboard_text(int *len);

/** Asks the platform to run the given function after the given number of seconds.
 * The platform should continue calling `f(reference)` for as long as it returns `true`.
 */
void add_timeout(double interval, bool (*f)(int *), int *reference);

/** Asks the platform to update the UI by painting views, processing any pending events in the
 * main event queue, etc.
 * This primarily called to perform asynchronous actions like polling for spawned process output
 * and invoking Lua callback functions to process it.
 */
void update_ui(void);

/** Returns whether or not dark mode is currently enabled on the platform. */
bool is_dark_mode(void);

/** Asks the platform to show a message dialog using the given options.
 * If the user presses a button, the platform should push onto the Lua stack the index (starting
 * from 1) of the button pushed, and then return 1 (the number of results pushed). Otherwise
 * the platform should push nothing and return 0.
 */
int message_dialog(DialogOptions opts, lua_State *L);

/** Asks the platform to show an input dialog using the given options.
 * If the user provides input, the platform should push onto the Lua stack the string input
 * text and then return 1 (the number of results pushed). If `opts.return_button` is `true`,
 * the platform should also push the index (starting from 1) of the button pushed (or 1 to
 * signal an affirmation) and return 2. Otherwise the platform should push nothing and return 0.
 */
int input_dialog(DialogOptions opts, lua_State *L);

/** Asks the platform to show a file selection dialog using the given options.
 * If the user selected a file(s), the platform should push onto the Lua stack the string filename
 * or table of filenames selected, and then return 1 (the number of results pushed). Otherwise
 * the platform should push nothing and return 0.
 * If `opts.multiple` is `true`, the platform should push and populate table, even if only one
 * file was selected.
 * The returned filenames should be encoded in the filesystem's encoding (`get_charset()`)
 * such that the results could be passed to `open()` or `fopen()`.
 */
int open_dialog(DialogOptions opts, lua_State *L);

/** Asks the platform to show a file save dialog using the given options.
 * If the user selected a file, the platform should push onto the Lua stack the string filename
 * selected, and then return 1 (the number of results pushed). Otherwise the platform should
 * push nothing and return 0.
 * The returned filenames should be encoded in the filesystem's encoding (`get_charset()`)
 * such that the results could be passed to `open()` or `fopen()`.
 */
int save_dialog(DialogOptions opts, lua_State *L);

/** Asks the platform to show a progress dialog using the given options.
 * The platform is expected to repeatedly call the given `work()` function for as long as it
 * returns `true`. The `update()` function given to `work()` will be called back with progress
 * made so the platform can update its progress bar.
 * If the work was stopped prior to completion, the platform should push onto the Lua stack the
 * the boolean true and return 1. Otherwise, the platform should push nothing and return 0.
 */
int progress_dialog(DialogOptions opts, lua_State *L,
	bool (*work)(void (*update)(double percent, const char *text, void *userdata), void *userdata));

/** Asks the platform to show a list dialog using the given options.
 * The list data may consist of multiple columns of data. The dialog should contain a text entry
 * that allows the user to filter the items shown based on the a given search column. Spaces
 * in the text entry should be treated as wildcards.
 * If the user selected an item(s), the platform should push onto the Lua stack the integer row
 * index or table of row indices (starting from 1) of the item(s) selected, and then return 1
 * (the number of results pushed). If `opts.return_button` is `true`, the platform should also
 * push the index (starting from 1) of the button pushed (or 1 to signal an affirmation) and
 * return 2. Otherwise the platform should push nothing and return 0.
 * If `opts.multiple` is `true`, the platform should push and populate table, even if only one
 * item was selected.
 * The pushed row index or indices should be relative to the full item list, not a filtered list.
 */
int list_dialog(DialogOptions opts, lua_State *L);

/** Asks the platform to spawn a child process asynchronously and return whether or not it
 * successfully spawned that process.
 * When the process exits, it needs to notify Textadept via `process_exited()`.
 * While the platform is allowed to push values to the given Lua state, it may not pop off any
 * values it did not push.
 * @param proc Platform-specific process identifier. This pre-allocated chunk of memory should
 *	be filled in by the platform (i.e. its implementing struct's members). The size of
 *	`proc` is defined by `process_size()`.
 * @param index Lua stack index that contains `proc` in case the platform needs to store or
 *	refer to it.
 * @param cmd The command line string of the child process to spawn. The platform is expected
 *	to perform any processing needed to launch the process.
 * @param cwd Optional directory to spawn the process in.
 * @param envi Optional stack index of a Lua table that contains a list of "key=value" environment
 *	strings. The platform is expected to read from this table in order to create a valid
 *	process environment. If this index is not provided, the child should inherit Textadept's
 *	environment.
 * @param monitor_stdout Whether or not the platform should notify Textadept of any process
 *	stdout as it comes in via `process_output()`.
 * @param monitor_stderr Whether or not the platform should notify Textadept of any process
 *	stderr as it comes in via `process_output()`.
 * @param error A message that describes the error that occurred if this function returns
 *	`false`. This pointer will not be freed -- it is expected to be a stored message.
 * @return whether or not the child process was successfully spawned
 * @see process_size
 * @see process_output
 * @see process_exited
 */
bool spawn(lua_State *L, Process *proc, int index, const char *cmd, const char *cwd, int envi,
	bool monitor_stdout, bool monitor_stderr, const char **error);

/** Returns the size of the platform's implemented Process struct. */
size_t process_size(void);

/** Returns whether or not the given process is running. */
bool is_process_running(Process *proc);

/** Asks the platform to wait (blocking) until the given process finishes if it has not already. */
void wait_process(Process *proc);

/** Asks the platform to read from the given process' stdout stream, return the data read,
 * and store the number of bytes read in the given pointer.
 * The platform should return NULL on EOF. If a read error occurs, it should return NULL and
 * store the error message and code in the given pointers.
 * @param option Like Lua's `io.read()` option: 'l' to read a single line excluding end-of-line
 *	(EOL) characters, 'L' to read a single line including EOL characters, 'a' to read until
 *	the end-of-file (EOF), or 'n' to read `*len` bytes.
 */
char *read_process_output(Process *proc, char option, size_t *len, const char **error, int *code);

/** Asks the platform to write the given data to the given process. */
void write_process_input(Process *proc, const char *s, size_t len);

/** Asks the platform to close the given process' stdin (i.e. send it an EOF). */
void close_process_input(Process *proc);

/** Asks the platform to kill the given process, optionally with the given signal.
 * Not all operating systems support signals, so the platform should use its discretion.
 */
void kill_process(Process *proc, int signal);

/** Returns the exit status of the given process.
 * Textadept will only call this after the platform has indicated the process exited.
 */
int get_process_exit_status(Process *proc);

/** Allows the platform to cleanup a process about to be garbage-collected by Lua. */
void cleanup_process(Process *proc);

/** Asks the platform to suspend execution of Textadept, if possible. */
void suspend(void);

/** Asks the platform quit the application.
 * The user has already been prompted to handle unsaved changes, etc. `can_quit()` will return
 * `true`.
 */
void quit(void);

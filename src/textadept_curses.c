// Copyright 2007-2022 Mitchell. See LICENSE.

#include "textadept.h"

#include "lauxlib.h" // for luaL_ref
#include "ScintillaCurses.h"
#include "termkey.h"

#include <locale.h>
#include <math.h> // for fmax
#if !_WIN32
#include <signal.h>
#include <sys/ioctl.h>
#else
#include <windows.h>
#endif
#include "cdk_int.h" // must come after <windows.h>

const char *get_platform() { return "CURSES"; }

/**
 * Copies the given value to the given string after freeing that string's existing value (if any).
 * The given string must be freed when finished.
 * @param s The address of the string to copy value to.
 * @param value String value to copy. It may be freed immediately.
 */
static void copyfree(char **s, const char *value) {
  if (*s) free(*s);
  *s = strcpy(malloc(strlen(value) + 1), value);
}

// Curses window.
struct Pane {
  int y, x, rows, cols, split_size; // dimensions
  enum { SINGLE, VSPLIT, HSPLIT } type; // pane type
  WINDOW *win; // either the Scintilla curses window or the split bar's window
  Scintilla *view; // Scintilla view for a non-split view
  struct Pane *child1, *child2; // each pane in a split view
}; // Pane implementation based on code by Chris Emerson.
static inline struct Pane *PANED(Pane *pane) { return (struct Pane *)pane; }
static Pane *pane;
TermKey *ta_tk; // global for CDK use
sptr_t SS(Scintilla *view, int message, uptr_t wparam, sptr_t lparam) {
  return scintilla_send_message(view, message, wparam, lparam);
}
void focus_view(Scintilla *view) {
  (focused_view ? SS(focused_view, SCI_SETFOCUS, 0, 0) : 0, SS(view, SCI_SETFOCUS, 1, 0));
}
void delete_scintilla(Scintilla *view) { scintilla_delete(view); }
// Find & replace pane.
static CDKSCREEN *findbox;
static CDKENTRY *find_entry, *repl_entry, *focused_entry;
static char *find_text, *repl_text, *find_label, *repl_label;
const char *get_find_text() { return find_text; }
const char *get_repl_text() { return repl_text; }
void set_find_text(const char *text) { copyfree(&find_text, text); }
void set_repl_text(const char *text) { copyfree(&repl_text, text); }
static bool find_options[4];
static char *button_labels[4], *option_labels[4], *find_history[10], *repl_history[10];
bool checked(FindOption *option) { return *(bool *)option; }
// Use pointer arithmetic to highlight/unhighlight options as necessary.
void toggle(FindOption *option, bool on) {
  bool *opt = (bool *)option;
  if (*opt != on) *opt = on, option_labels[opt - find_options] += *opt ? -4 : 4;
}
void set_find_label(const char *text) { copyfree(&find_label, text); }
void set_repl_label(const char *text) { copyfree(&repl_label, text); }
void set_button_label(FindButton *button, const char *text) {
  copyfree(&button_labels[(char **)button - button_labels], text);
}
void set_option_label(FindOption *option, const char *text) {
  bool *opt = (bool *)option;
  lua_pushstring(lua, "</R>"), lua_pushstring(lua, text), lua_concat(lua, 2);
  if (option_labels[opt - find_options] && !*opt) option_labels[opt - find_options] -= 4;
  copyfree(&option_labels[opt - find_options], lua_tostring(lua, -1));
  if (!*opt) option_labels[opt - find_options] += 4;
}
bool find_active() { return findbox != NULL; }
// Command entry.
static bool command_entry_active;
bool is_command_entry_active() { return command_entry_active; }
static int statusbar_length[2];

// Lua objects.
static bool quitting;

// Forward declarations.
LUALIB_API int os_spawn_pushfds(lua_State *), os_spawn_readfds(lua_State *);

static void add_to_history(char **store, const char *text) {
  if (!text || (store[0] && strcmp(text, store[0]) == 0)) return;
  if (store[9]) free(store[9]);
  for (int i = 9; i > 0; i--) store[i] = store[i - 1];
  store[0] = NULL, copyfree(&store[0], text);
}

void add_to_find_history(const char *text) { add_to_history(find_history, text); }
void add_to_repl_history(const char *text) { add_to_history(repl_history, text); }

/**
 * Redraws an entire pane and its children.
 * @param pane The pane to redraw.
 */
static void refresh_pane(struct Pane *pane) {
  if (pane->type == VSPLIT) {
    mvwvline(pane->win, 0, 0, 0, pane->rows), wrefresh(pane->win);
    refresh_pane(pane->child1), refresh_pane(pane->child2);
  } else if (pane->type == HSPLIT) {
    mvwhline(pane->win, 0, 0, 0, pane->cols), wrefresh(pane->win);
    refresh_pane(pane->child1), refresh_pane(pane->child2);
  } else
    scintilla_noutrefresh(pane->view);
}

/** Refreshes the entire screen. */
static void refresh_all() {
  refresh_pane(pane);
  if (command_entry_active) scintilla_noutrefresh(command_entry);
  refresh();
  if (!findbox) scintilla_update_cursor(!command_entry_active ? focused_view : command_entry);
}

/**
 * Signal for Find/Replace entry keypress.
 * For tab keys, toggle through find/replace buttons.
 * For ^N and ^P keys, cycle through find/replace history.
 * For F1-F4 keys, toggle the respective search option.
 * For up and down keys, toggle entry focus.
 * Otherwise, emit events for entry text changes.
 */
static int find_keypress(EObjectType _, void *object, void *data, chtype key) {
  CDKENTRY *entry = (CDKENTRY *)object;
  char *text = getCDKEntryValue(entry);
  if (key == KEY_TAB) {
    CDKBUTTONBOX *box = (CDKBUTTONBOX *)data;
    FindButton *current = button_labels + getCDKButtonboxCurrentButton(box);
    char **button = entry == find_entry ? (current == find_next ? find_prev : find_next) :
                                          (current == replace ? replace_all : replace);
    setCDKButtonboxCurrentButton(box, button - button_labels);
    drawCDKButtonbox(box, false), drawCDKEntry(entry, false);
  } else if (key == CDK_PREV || key == CDK_NEXT) {
    char **store = entry == find_entry ? find_history : repl_history;
    int i;
    for (i = 9; i >= 0; i--)
      if (store[i] && strcmp(store[i], text) == 0) break;
    key == CDK_PREV ? i++ : i--;
    if (i >= 0 && i <= 9 && store[i]) setCDKEntryValue(entry, store[i]), drawCDKEntry(entry, false);
  } else if (key >= KEY_F(1) && key <= KEY_F(4)) {
    toggle(&find_options[key - KEY_F(1)], !find_options[key - KEY_F(1)]);
    // Redraw the optionbox.
    CDKBUTTONBOX **optionbox = (CDKBUTTONBOX **)data;
    int width = (*optionbox)->boxWidth - 1;
    destroyCDKButtonbox(*optionbox);
    *optionbox = newCDKButtonbox(
      findbox, RIGHT, TOP, 2, width, NULL, 2, 2, option_labels, 4, A_NORMAL, false, false);
    drawCDKButtonbox(*optionbox, false);
  } else if (key == KEY_UP || key == KEY_DOWN) {
    focused_entry = entry == find_entry ? repl_entry : find_entry;
    FindButton *button = focused_entry == find_entry ? find_next : replace;
    setCDKButtonboxCurrentButton((CDKBUTTONBOX *)data, (char **)button - button_labels);
    injectCDKEntry(entry, KEY_ENTER); // exit this entry
  } else if ((!find_text || strcmp(find_text, text) != 0)) {
    copyfree(&find_text, text);
    if (emit("find_text_changed", -1)) refresh_all();
  }
  return true;
}

void focus_find() {
  if (findbox) return; // already active
  wresize(scintilla_get_window(focused_view), LINES - 4, COLS);
  findbox = initCDKScreen(newwin(2, 0, LINES - 3, 0)), eraseCDKScreen(findbox);
  int b_width = fmax(strlen(button_labels[0]), strlen(button_labels[1])) +
    fmax(strlen(button_labels[2]), strlen(button_labels[3])) + 3;
  int o_width = fmax(strlen(option_labels[0]), strlen(option_labels[1])) +
    fmax(strlen(option_labels[2]), strlen(option_labels[3])) + 3;
  int l_width = fmax(strlen(find_label), strlen(repl_label));
  int e_width = COLS - o_width - b_width - l_width - 1;
  find_entry = newCDKEntry(findbox, l_width - strlen(find_label), TOP, NULL, find_label, A_NORMAL,
    '_', vMIXED, e_width, 0, 1024, false, false);
  repl_entry = newCDKEntry(findbox, l_width - strlen(repl_label), BOTTOM, NULL, repl_label,
    A_NORMAL, '_', vMIXED, e_width, 0, 1024, false, false);
  CDKBUTTONBOX *buttonbox, *optionbox;
  buttonbox = newCDKButtonbox(findbox, COLS - o_width - b_width, TOP, 2, b_width, NULL, 2, 2,
    button_labels, 4, A_REVERSE, false, false);
  optionbox = newCDKButtonbox(
    findbox, RIGHT, TOP, 2, o_width, NULL, 2, 2, option_labels, 4, A_NORMAL, false, false);
// TODO: ideally no #define here.
#define bind(k, d) \
  (bindCDKObject(vENTRY, find_entry, k, find_keypress, d), \
    bindCDKObject(vENTRY, repl_entry, k, find_keypress, d))
  bind(KEY_TAB, buttonbox), bind(CDK_NEXT, NULL), bind(CDK_PREV, NULL);
  for (int i = 1; i <= 4; i++) bind(KEY_F(i), &optionbox);
  bind(KEY_DOWN, buttonbox), bind(KEY_UP, buttonbox);
  setCDKEntryValue(find_entry, find_text), setCDKEntryValue(repl_entry, repl_text);
  setCDKEntryPostProcess(find_entry, find_keypress, NULL);
  char *clipboard = scintilla_get_clipboard(focused_view, NULL);
  GPasteBuffer = copyChar(clipboard); // set the CDK paste buffer
  curs_set(1); // ensure visible, even if cursor is out of view in focused_view
  refreshCDKScreen(findbox), activateCDKEntry(focused_entry = find_entry, NULL);
  while (focused_entry->exitType == vNORMAL || focused_entry->exitType == vNEVER_ACTIVATED) {
    copyfree(&find_text, getCDKEntryValue(find_entry));
    copyfree(&repl_text, getCDKEntryValue(repl_entry));
    if (focused_entry->exitType == vNORMAL)
      find_clicked(button_labels + getCDKButtonboxCurrentButton(buttonbox), NULL), refresh_all();
    find_entry->exitType = repl_entry->exitType = vNEVER_ACTIVATED;
    refreshCDKScreen(findbox), activateCDKEntry(focused_entry, NULL);
  }
  // Set Scintilla clipboard with new CDK paste buffer if necessary.
  if (strcmp(clipboard, GPasteBuffer) != 0)
    SS(focused_view, SCI_COPYTEXT, strlen(GPasteBuffer), (sptr_t)GPasteBuffer);
  free(clipboard), free(GPasteBuffer), GPasteBuffer = NULL;
  destroyCDKEntry(find_entry), destroyCDKEntry(repl_entry);
  destroyCDKButtonbox(buttonbox), destroyCDKButtonbox(optionbox);
  delwin(findbox->window), destroyCDKScreen(findbox), findbox = NULL;
  timeout(0), getch(), timeout(-1); // flush potential extra Escape
  wresize(scintilla_get_window(focused_view), LINES - 2, COLS);
}

void set_entry_font(const char *name) {}

void focus_command_entry() {
  if (!(command_entry_active = !command_entry_active)) SS(command_entry, SCI_SETFOCUS, 0, 0);
  focus_view(command_entry_active ? command_entry : focused_view);
}

PaneInfo get_pane_info(Pane *pane_) {
  struct Pane *pane = PANED(pane_);
  PaneInfo info = {pane->type != SINGLE, pane->type == VSPLIT, pane->view, pane, pane->child1,
    pane->child2, pane->split_size};
  return info;
}

Pane *get_top_pane() { return pane; }

void set_tab(int index) {}

void *read_menu(lua_State *L, int index) { return NULL; }

void popup_menu(void *menu, void *userdata) {}

void update_ui() {
#if !_WIN32
  struct timeval timeout = {0, 1e5}; // 0.1s
  int nfds = os_spawn_pushfds(lua);
  while (select(nfds, lua_touserdata(lua, -1), NULL, NULL, &timeout) > 0)
    if (os_spawn_readfds(lua) >= 0) refresh_all();
  lua_pop(lua, 1); // fd_set
#endif
}

char *get_clipboard_text(int *len) { return scintilla_get_clipboard(focused_view, len); }

bool is_maximized() { return false; }

void get_size(int *width, int *height) { *width = COLS, *height = LINES; }

void set_statusbar_text(int bar, const char *text) {
  int start = bar == 0 ? 0 : statusbar_length[0];
  int end = bar == 0 ? COLS - statusbar_length[1] : COLS;
  for (int i = start; i < end; i++) mvaddch(LINES - 1, i, ' '); // clear
  int len = utf8strlen(text);
  mvaddstr(LINES - 1, bar == 0 ? 0 : COLS - len, text), refresh();
  statusbar_length[bar] = len;
}

void set_title(const char *title) {
  for (int i = 0; i < COLS; i++) mvaddch(0, i, ' '); // clear titlebar
  mvaddstr(0, 0, title), refresh();
}

void set_menubar(lua_State *L, int index) {}

void set_maximized(bool maximize) {}

void set_size(int width, int height) {}

void show_tabs(bool show) {}

void remove_tab(int index) {}

const char *get_tab_label(int index) { return NULL; }

int get_command_entry_height() { return getmaxy(scintilla_get_window(command_entry)); }

void set_tab_label(int index, const char *text) {}

void set_command_entry_height(int height) {
  WINDOW *win = scintilla_get_window(command_entry);
  wresize(win, height, COLS), mvwin(win, LINES - 1 - height, 0);
}

void add_tab() {}

void move_tab(int from, int to) {}

void quit() { quitting = !emit("quit", -1); }

bool add_timeout(double interval, void *f) { return false; }

const char *get_charset() {
#if !_WIN32
  const char *charset = getenv("CHARSET");
  if (!charset || !*charset) {
    char *locale = getenv("LC_ALL");
    if (!locale || !*locale) locale = getenv("LANG");
    if (locale && (charset = strchr(locale, '.'))) charset++;
  }
  return charset;
#elif _WIN32
  static char codepage[8];
  return (sprintf(codepage, "CP%d", GetACP()), codepage);
#endif
}

/**
 * Searches for the given view and returns its parent pane, if there is one.
 * @param pane The pane that contains the desired view.
 * @param view The view to get the parent pane of.
 */
static struct Pane *get_parent_pane(struct Pane *pane, Scintilla *view) {
  if (pane->type == SINGLE) return NULL;
  if (pane->child1->view == view || pane->child2->view == view) return pane;
  struct Pane *parent = get_parent_pane(pane->child1, view);
  return parent ? parent : get_parent_pane(pane->child2, view);
}

/**
 * Removes all Scintilla views from the given pane and deletes them along with the child panes
 * themselves.
 * @param pane The pane to remove Scintilla views from.
 * @param delete_view Function for deleting views.
 * @see delete_view
 */
static void remove_views(Pane *pane_, void (*delete_view)(Scintilla *view)) {
  struct Pane *pane = PANED(pane_);
  if (pane->type == VSPLIT || pane->type == HSPLIT) {
    remove_views(pane->child1, delete_view), remove_views(pane->child2, delete_view);
    delwin(pane->win), pane->win = NULL; // delete split bar
  } else
    delete_view(pane->view);
  free(pane);
}

/**
 * Resizes and repositions a pane.
 * @param pane the pane to resize and move.
 * @param rows The number of rows the pane should show.
 * @param cols The number of columns the pane should show.
 * @param y The y-coordinate to place the pane at.
 * @param x The x-coordinate to place the pane at.
 */
static void resize_pane(struct Pane *pane, int rows, int cols, int y, int x) {
  if (pane->type == VSPLIT) {
    int ssize = pane->split_size * cols / fmax(pane->cols, 1);
    if (ssize < 1 || ssize >= cols - 1) ssize = ssize < 1 ? 1 : cols - 2;
    pane->split_size = ssize;
    resize_pane(pane->child1, rows, ssize, y, x);
    resize_pane(pane->child2, rows, cols - ssize - 1, y, x + ssize + 1);
    wresize(pane->win, rows, 1), mvwin(pane->win, y, x + ssize); // split bar
  } else if (pane->type == HSPLIT) {
    int ssize = pane->split_size * rows / fmax(pane->rows, 1);
    if (ssize < 1 || ssize >= rows - 1) ssize = ssize < 1 ? 1 : rows - 2;
    pane->split_size = ssize;
    resize_pane(pane->child1, ssize, cols, y, x);
    resize_pane(pane->child2, rows - ssize - 1, cols, y + ssize + 1, x);
    wresize(pane->win, 1, cols), mvwin(pane->win, y + ssize, x); // split bar
  } else
    wresize(pane->win, rows, cols), mvwin(pane->win, y, x);
  pane->rows = rows, pane->cols = cols, pane->y = y, pane->x = x;
}

bool unsplit_view(Scintilla *view, void (*delete_view)(Scintilla *)) {
  struct Pane *parent = get_parent_pane(pane, view);
  if (!parent) return false;
  struct Pane *child = parent->child1->view == view ? parent->child1 : parent->child2;
  remove_views(child == parent->child1 ? parent->child2 : parent->child1, delete_view);
  delwin(parent->win); // delete split bar
  // Inherit child's properties.
  parent->type = child->type, parent->split_size = child->split_size;
  parent->win = child->win, parent->view = child->view;
  parent->child1 = child->child1, parent->child2 = child->child2;
  free(child);
  resize_pane(parent, parent->rows, parent->cols, parent->y, parent->x); // update
  return (scintilla_noutrefresh(view), true);
}

/**
 * Creates a new pane that contains a Scintilla view.
 * @param view The Scintilla view to place in the pane.
 */
static Pane *new_pane(Scintilla *view) {
  struct Pane *p = calloc(1, sizeof(struct Pane));
  p->type = SINGLE, p->win = scintilla_get_window(view), p->view = view;
  return p;
}

void split_view(Scintilla *view, Scintilla *view2, bool vertical) {
  struct Pane *parent = get_parent_pane(pane, view);
  parent = parent ? (parent->child1->view == view ? parent->child1 : parent->child2) : pane;
  Pane *child1 = new_pane(view), *child2 = new_pane(view2);
  parent->type = vertical ? VSPLIT : HSPLIT;
  parent->child1 = child1, parent->child2 = child2, parent->view = NULL;
  // Resize children and create a split bar.
  if (vertical) {
    parent->split_size = parent->cols / 2;
    resize_pane(child1, parent->rows, parent->split_size, parent->y, parent->x);
    resize_pane(child2, parent->rows, parent->cols - parent->split_size - 1, parent->y,
      parent->x + parent->split_size + 1);
    parent->win = newwin(parent->rows, 1, parent->y, parent->x + parent->split_size);
  } else {
    parent->split_size = parent->rows / 2;
    resize_pane(child1, parent->split_size, parent->cols, parent->y, parent->x);
    resize_pane(child2, parent->rows - parent->split_size - 1, parent->cols,
      parent->y + parent->split_size + 1, parent->x);
    parent->win = newwin(1, parent->cols, parent->y + parent->split_size, parent->x);
  }
  refresh_pane(parent);
}

Scintilla *new_scintilla(void (*notified)(Scintilla *, int, SCNotification *, void *)) {
  return scintilla_new(notified, NULL);
}

PaneInfo get_pane_info_from_view(Scintilla *view) {
  return get_pane_info(get_parent_pane(pane, view));
}

void set_pane_size(Pane *pane_, int size) {
  struct Pane *pane = PANED(pane_);
  pane->split_size = size, resize_pane(pane, pane->rows, pane->cols, pane->y, pane->x);
}

void new_window(Scintilla *(*get_view)(void)) {
  pane = new_pane(get_view()), resize_pane(pane, LINES - 2, COLS, 1, 0);
  wresize(scintilla_get_window(command_entry), 1, COLS);
  mvwin(scintilla_get_window(command_entry), LINES - 2, 0);
}

#if !_WIN32
/**
 * Signal for a terminal suspend, continue, and resize.
 * libtermkey has been patched to enable suspend as well as enable/disable mouse mode (1002).
 */
static void signalled(int signal) {
  if (signal != SIGTSTP) {
    if (signal == SIGCONT) termkey_start(ta_tk);
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    resizeterm(w.ws_row, w.ws_col), resize_pane(pane, LINES - 2, COLS, 1, 0);
    WINDOW *win = scintilla_get_window(command_entry);
    wresize(win, 1, COLS), mvwin(win, LINES - 1 - getmaxy(win), 0);
    if (signal == SIGCONT) emit("resume", -1);
    emit("update_ui", LUA_TNUMBER, 0, -1);
  } else if (!emit("suspend", -1))
    endwin(), termkey_stop(ta_tk), kill(0, SIGSTOP);
  refresh_all();
}
#endif

/** Replacement for `termkey_waitkey()` that handles asynchronous I/O. */
static TermKeyResult textadept_waitkey(TermKey *tk, TermKeyKey *key) {
#if !_WIN32
  bool force = false;
  struct timeval timeout = {0, termkey_get_waittime(tk)};
  while (true) {
    TermKeyResult res = !force ? termkey_getkey(tk, key) : termkey_getkey_force(tk, key);
    if (res != TERMKEY_RES_AGAIN && res != TERMKEY_RES_NONE) return res;
    if (res == TERMKEY_RES_AGAIN) force = true;
    // Wait for input.
    int nfds = os_spawn_pushfds(lua);
    fd_set *fds = lua_touserdata(lua, -1);
    FD_SET(0, fds); // monitor stdin
    if (select(nfds, fds, NULL, NULL, force ? &timeout : NULL) > 0) {
      if (FD_ISSET(0, fds)) termkey_advisereadable(tk);
      if (os_spawn_readfds(lua) > 0) refresh_all();
    }
    lua_pop(lua, 1); // fd_set
  }
#else
  // TODO: ideally computation of view would not be done twice.
  Scintilla *view = !command_entry_active ? focused_view : command_entry;
  termkey_set_fd(ta_tk, scintilla_get_window(view));
  mouse_set(ALL_MOUSE_EVENTS); // _popen() and system() change console mode
  return termkey_getkey(tk, key);
#endif
}

/**
 * Runs Textadept.
 * Initializes the Lua state, creates the user interface, and then runs `core/init.lua` followed
 * by `init.lua`. On Windows, creates a pipe and thread for communication with remote instances.
 * @param argc The number of command line params.
 * @param argv The array of command line params.
 */
int main(int argc, char **argv) {
  int termkey_flags = 0; // TERMKEY_FLAG_CTRLC does not work; SIGINT is patched out
  for (int i = 0; i < argc; i++)
    if (strcmp("-p", argv[i]) == 0 || strcmp("--preserve", argv[i]) == 0) {
      termkey_flags |= TERMKEY_FLAG_FLOWCONTROL;
      break;
    }
  ta_tk = termkey_new(0, termkey_flags);
  setlocale(LC_CTYPE, ""); // for displaying UTF-8 characters properly
  initscr(); // raw()/cbreak() and noecho() are taken care of in libtermkey
#if NCURSES_REENTRANT
  ESCDELAY = getenv("ESCDELAY") ? atoi(getenv("ESCDELAY")) : 100;
#endif
  find_next = &button_labels[0], replace = &button_labels[1], find_prev = &button_labels[2],
  replace_all = &button_labels[3], match_case = &find_options[0], whole_word = &find_options[1],
  regex = &find_options[2], in_files = &find_options[3]; // typedefed, so cannot static initialize

  if (!init_textadept(argc, argv)) return (endwin(), termkey_destroy(ta_tk), 1);
  refresh_all();

#if !_WIN32
  freopen("/dev/null", "w", stderr); // redirect stderr
  // Set terminal suspend, resume, and resize handlers, preventing any signals in them from
  // causing interrupts.
  struct sigaction act;
  memset(&act, 0, sizeof(struct sigaction));
  act.sa_handler = signalled, sigfillset(&act.sa_mask);
  sigaction(SIGTSTP, &act, NULL), sigaction(SIGCONT, &act, NULL), sigaction(SIGWINCH, &act, NULL);
#else
  freopen("NUL", "w", stdout), freopen("NUL", "w", stderr); // redirect
#endif

  Scintilla *view = focused_view;
  int ch = 0, event = 0, button = 0, y = 0, x = 0;
  TermKeyResult res;
  TermKeyKey key;
  // clang-format off
  int keysyms[] = {0,SCK_BACK,SCK_TAB,SCK_RETURN,SCK_ESCAPE,0,SCK_BACK,SCK_UP,SCK_DOWN,SCK_LEFT,SCK_RIGHT,0,0,SCK_INSERT,SCK_DELETE,0,SCK_PRIOR,SCK_NEXT,SCK_HOME,SCK_END};
  // clang-format on
  while ((ch = 0, res = textadept_waitkey(ta_tk, &key)) != TERMKEY_RES_EOF) {
    if (res == TERMKEY_RES_ERROR) continue;
    if (key.type == TERMKEY_TYPE_UNICODE)
      ch = key.code.codepoint;
    else if (key.type == TERMKEY_TYPE_FUNCTION)
      ch = 0xFFBD + key.code.number; // use GDK keysym values for now
    else if (key.type == TERMKEY_TYPE_KEYSYM && key.code.sym >= 0 &&
      key.code.sym <= TERMKEY_SYM_END)
      ch = keysyms[key.code.sym];
    else if (key.type == TERMKEY_TYPE_UNKNOWN_CSI) {
      long args[16];
      size_t nargs = 16;
      unsigned long cmd;
      termkey_interpret_csi(ta_tk, &key, args, &nargs, &cmd);
      lua_newtable(lua);
      for (size_t i = 0; i < nargs; i++) lua_pushinteger(lua, args[i]), lua_rawseti(lua, -2, i + 1);
      emit("csi", LUA_TNUMBER, cmd, LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
    } else if (key.type == TERMKEY_TYPE_MOUSE)
      termkey_interpret_mouse(ta_tk, &key, (TermKeyMouseEvent *)&event, &button, &y, &x), y--, x--;
    else
      continue; // skip unknown types
    bool shift = key.modifiers & TERMKEY_KEYMOD_SHIFT, ctrl = key.modifiers & TERMKEY_KEYMOD_CTRL,
         alt = key.modifiers & TERMKEY_KEYMOD_ALT;
    if (ch &&
      !emit("keypress", LUA_TNUMBER, ch, LUA_TBOOLEAN, shift, LUA_TBOOLEAN, ctrl, LUA_TBOOLEAN, alt,
        -1))
      scintilla_send_key(view, ch, shift, ctrl, alt);
    else if (!ch && !scintilla_send_mouse(view, event, button, y, x, shift, ctrl, alt) &&
      !emit("mouse", LUA_TNUMBER, event, LUA_TNUMBER, button, LUA_TNUMBER, y, LUA_TNUMBER, x,
        LUA_TBOOLEAN, shift, LUA_TBOOLEAN, ctrl, LUA_TBOOLEAN, alt, -1))
      // Try again with possibly another view.
      scintilla_send_mouse(focused_view, event, button, y, x, shift, ctrl, alt);
    if (quitting) break;
    refresh_all();
    view = !command_entry_active ? focused_view : command_entry;
  }
  close_textadept(), endwin(), termkey_destroy(ta_tk);

  free(pane), free(find_label), free(repl_label);
  if (find_text) free(find_text);
  if (repl_text) free(repl_text);
  for (int i = 0; i < 10; i++) {
    if (find_history[i]) free(find_history[i]);
    if (repl_history[i]) free(repl_history[i]);
    if (i < 4) free(button_labels[i]), free(option_labels[i] - (find_options[i] ? 0 : 4));
  }
  return 0;
}

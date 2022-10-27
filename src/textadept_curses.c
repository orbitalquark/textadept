// Copyright 2007-2022 Mitchell. See LICENSE.
// Curses platform for Textadept.

#include "textadept.h"

#include "lauxlib.h" // for luaL_ref
#include "ScintillaCurses.h"
#include "termkey.h"

#include <locale.h>
#include <math.h> // for fmax
#if !_WIN32
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#else
#include <windows.h>
#define strncasecmp _strnicmp
#endif
#include "cdk_int.h" // must come after <windows.h>

// Curses objects.
static Pane *pane;
static CDKSCREEN *findbox;
static CDKENTRY *find_entry, *repl_entry, *focused_entry;
static char *find_text, *repl_text, *find_label, *repl_label;
static bool find_options[4];
static char *button_labels[4], *option_labels[4], *find_history[10], *repl_history[10];
static bool command_entry_active;
static int statusbar_length[2];
TermKey *ta_tk; // global for CDK use

// Lua objects.
static bool quitting;

// Implementation of a Pane.
struct Pane {
  int y, x, rows, cols, split_size; // dimensions
  enum { SINGLE, VSPLIT, HSPLIT } type; // pane type
  WINDOW *win; // either the Scintilla curses window or the split bar's window
  SciObject *view; // Scintilla view for a non-split view
  struct Pane *child1, *child2; // each pane in a split view
}; // Pane implementation based on code by Chris Emerson.

const char *get_platform() { return "CURSES"; }

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

// Creates and returns a new pane that contains the given Scintilla view.
static Pane *new_pane(SciObject *view) {
  struct Pane *p = calloc(1, sizeof(struct Pane));
  p->type = SINGLE, p->win = scintilla_get_window(view), p->view = view;
  return p;
}

// Resizes and repositions the given pane.
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

void new_window(SciObject *(*get_view)(void)) {
  pane = new_pane(get_view()), resize_pane(pane, LINES - 2, COLS, 1, 0);
  wresize(scintilla_get_window(command_entry), 1, COLS);
  mvwin(scintilla_get_window(command_entry), LINES - 2, 0);
}

void set_title(const char *title) {
  for (int i = 0; i < COLS; i++) mvaddch(0, i, ' '); // clear titlebar
  mvaddstr(0, 0, title), refresh();
}

bool is_maximized() { return false; }

void set_maximized(bool maximize) {}

void get_size(int *width, int *height) { *width = COLS, *height = LINES; }

void set_size(int width, int height) {}

SciObject *new_scintilla(void (*notified)(SciObject *, int, SCNotification *, void *)) {
  return scintilla_new(notified, NULL);
}

void focus_view(SciObject *view) {
  (focused_view ? SS(focused_view, SCI_SETFOCUS, 0, 0) : 0, SS(view, SCI_SETFOCUS, 1, 0));
}

sptr_t SS(SciObject *view, int message, uptr_t wparam, sptr_t lparam) {
  return scintilla_send_message(view, message, wparam, lparam);
}

// Searches the given pane for the given view and returns that view's parent pane, if there is one.
static struct Pane *get_parent_pane(struct Pane *pane, SciObject *view) {
  if (pane->type == SINGLE) return NULL;
  if (pane->child1->view == view || pane->child2->view == view) return pane;
  struct Pane *parent = get_parent_pane(pane->child1, view);
  return parent ? parent : get_parent_pane(pane->child2, view);
}

// Redraws the given pane and its children.
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

void split_view(SciObject *view, SciObject *view2, bool vertical) {
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

// Removes all Scintilla views from the given pane and deletes them along with the child panes
// themselves.
static void remove_views(Pane *pane_, void (*delete_view)(SciObject *view)) {
  struct Pane *pane = pane_;
  if (pane->type == VSPLIT || pane->type == HSPLIT) {
    remove_views(pane->child1, delete_view), remove_views(pane->child2, delete_view);
    delwin(pane->win), pane->win = NULL; // delete split bar
  } else
    delete_view(pane->view);
  free(pane);
}

bool unsplit_view(SciObject *view, void (*delete_view)(SciObject *)) {
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

void delete_scintilla(SciObject *view) { scintilla_delete(view); }

Pane *get_top_pane() { return pane; }

PaneInfo get_pane_info(Pane *pane_) {
  struct Pane *pane = pane_;
  PaneInfo info = {pane->type != SINGLE, pane->type == VSPLIT, pane->view, pane, pane->child1,
    pane->child2, pane->split_size};
  return info;
}

PaneInfo get_pane_info_from_view(SciObject *v) { return get_pane_info(get_parent_pane(pane, v)); }

void set_pane_size(Pane *pane_, int size) {
  struct Pane *pane = pane_;
  pane->split_size = size, resize_pane(pane, pane->rows, pane->cols, pane->y, pane->x);
}

void show_tabs(bool show) {}

void add_tab() {}

void set_tab(int index) {}

void set_tab_label(int index, const char *text) {}

void move_tab(int from, int to) {}

void remove_tab(int index) {}

// Copies to the given string address the given value after freeing that string's existing value
// (if any).
// The given string must be freed when finished. The value may be freed immediately.
static void copyfree(char **s, const char *value) {
  if (*s) free(*s);
  *s = strcpy(malloc(strlen(value) + 1), value);
}

const char *get_find_text() { return find_text; }
const char *get_repl_text() { return repl_text; }
void set_find_text(const char *text) { copyfree(&find_text, text); }
void set_repl_text(const char *text) { copyfree(&repl_text, text); }

// Adds the given text to the given store.
static void add_to_history(char **store, const char *text) {
  if (!text || (store[0] && strcmp(text, store[0]) == 0)) return;
  if (store[9]) free(store[9]);
  for (int i = 9; i > 0; i--) store[i] = store[i - 1];
  store[0] = NULL, copyfree(&store[0], text);
}

void add_to_find_history(const char *text) { add_to_history(find_history, text); }
void add_to_repl_history(const char *text) { add_to_history(repl_history, text); }

void set_entry_font(const char *name) {}
bool is_checked(FindOption *option) { return *(bool *)option; }
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
  // TODO: stop using Lua for this.
  lua_pushstring(lua, "</R>"), lua_pushstring(lua, text), lua_concat(lua, 2);
  if (option_labels[opt - find_options] && !*opt) option_labels[opt - find_options] -= 4;
  copyfree(&option_labels[opt - find_options], lua_tostring(lua, -1));
  if (!*opt) option_labels[opt - find_options] += 4;
}

// Refreshes the entire screen.
static void refresh_all() {
  refresh_pane(pane);
  if (command_entry_active) scintilla_noutrefresh(command_entry);
  refresh();
  if (!findbox) scintilla_update_cursor(!command_entry_active ? focused_view : command_entry);
}

// Signal for a Find/Replace entry keypress.
// For tab keys, toggle through find/replace buttons.
// For ^N and ^P keys, cycle through find/replace history.
// For F1-F4 keys, toggle the respective search option.
// For up and down keys, toggle entry focus.
// Otherwise, emit 'find_text_changed' events for entry text changes.
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
      find_clicked(button_labels + getCDKButtonboxCurrentButton(buttonbox)), refresh_all();
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

bool is_find_active() { return findbox != NULL; }

void focus_command_entry() {
  if (!(command_entry_active = !command_entry_active)) SS(command_entry, SCI_SETFOCUS, 0, 0);
  focus_view(command_entry_active ? command_entry : focused_view);
}

bool is_command_entry_active() { return command_entry_active; }

int get_command_entry_height() { return getmaxy(scintilla_get_window(command_entry)); }

void set_command_entry_height(int height) {
  WINDOW *win = scintilla_get_window(command_entry);
  wresize(win, height, COLS), mvwin(win, LINES - 1 - height, 0);
}

void set_statusbar_text(int bar, const char *text) {
  int start = bar == 0 ? 0 : statusbar_length[0];
  int end = bar == 0 ? COLS - statusbar_length[1] : COLS;
  for (int i = start; i < end; i++) mvaddch(LINES - 1, i, ' '); // clear
  int len = utf8strlen(text);
  mvaddstr(LINES - 1, bar == 0 ? 0 : COLS - len, text), refresh();
  statusbar_length[bar] = len;
}

void *read_menu(lua_State *L, int index) { return NULL; }

void popup_menu(void *menu, void *userdata) {}

void set_menubar(lua_State *L, int index) {}

// Contains information about an active process.
struct Process {
  int pid, fstdin, fstdout, fstderr, exit_status;
  bool monitor_stdout, monitor_stderr;
};
static inline struct Process *PROCESS(struct Process *proc) { return proc; }

#if !_WIN32
// Creates and returns an `fd_set` for all spawned processes that can be used with `select()`
// and `read_fds()` to wait for input or output.
// The caller is expected to free the returned pointer.
fd_set *new_fds(int *nfds) {
  *nfds = 0;
  fd_set *fds = malloc(sizeof(fd_set));
  FD_ZERO(fds); // TODO: is calloc enough?
  lua_getfield(lua, LUA_REGISTRYINDEX, "spawn_procs");
  for (lua_pushnil(lua); lua_next(lua, -2); lua_pop(lua, 1)) {
    struct Process *proc = lua_touserdata(lua, -2);
    // Note: need to read from pipes so they do not get clogged, even if monitoring is not
    // requested.
    FD_SET(proc->fstdout, fds); // note: this is a do/while macro on OSX
    *nfds = fmax(*nfds, proc->fstdout + 1);
    FD_SET(proc->fstderr, fds); // note: this is a do/while macro on OSX
    *nfds = fmax(*nfds, proc->fstderr + 1);
  }
  return (lua_pop(lua, 1), fds); // spawn_procs
}

// Signal that a process has output to read.
static void read_proc(struct Process *proc, bool is_stdout) {
  char buf[BUFSIZ];
  ssize_t len;
  do {
    // Note: need to read from pipes to prevent clogging, but only report output if monitoring.
    bool monitoring = is_stdout ? proc->monitor_stdout : proc->monitor_stderr;
    if ((len = read(is_stdout ? proc->fstdout : proc->fstderr, buf, BUFSIZ)) > 0 && monitoring)
      process_output(proc, buf, len, is_stdout);
  } while (len == BUFSIZ);
}

// Cleans up after the process finished executing and returned the given status code.
static void cleanup_process(struct Process *proc, int status) {
  // Stop tracking and monitoring this proc.
  lua_getfield(lua, LUA_REGISTRYINDEX, "spawn_procs");
  for (lua_pushnil(lua); lua_next(lua, -2); lua_pop(lua, 1))
    if (((struct Process *)lua_touserdata(lua, -2))->pid == proc->pid) {
      lua_pushnil(lua), lua_replace(lua, -2), lua_settable(lua, -3); // t[proc] = nil
      break;
    }
  lua_pop(lua, 1); // spawn_procs
  proc->pid = 0, close(proc->fstdin), close(proc->fstdout), close(proc->fstderr);
  process_exited(proc, proc->exit_status = status);
}

// Reads output from the given fd_set and returns the number of fds read from.
// Also monitors child processes for completion and cleans up after them.
int read_fds(fd_set *fds) {
  int n = 0;
  lua_getfield(lua, LUA_REGISTRYINDEX, "spawn_procs");
  for (lua_pushnil(lua); lua_next(lua, -2); lua_pop(lua, 1)) {
    struct Process *proc = lua_touserdata(lua, -2);
    // Read output if any is available.
    if (FD_ISSET(proc->fstdout, fds)) read_proc(proc, true), n++;
    if (FD_ISSET(proc->fstderr, fds)) read_proc(proc, false), n++;
    // Check process status. If finished, read anything left and cleanup.
    int status;
    if (waitpid(proc->pid, &status, WNOHANG) > 0)
      read_proc(proc, true), read_proc(proc, false), cleanup_process(proc, status);
  }
  return (lua_pop(lua, 1), n); // spawn_procs
}
#endif

void update_ui() {
#if !_WIN32
  struct timeval timeout = {0, 1e5}; // 0.1s
  int nfds;
  fd_set *fds = new_fds(&nfds);
  while (select(nfds, fds, NULL, NULL, &timeout) > 0)
    if (read_fds(fds) >= 0) refresh_all();
  free(fds);
#endif
}

char *get_clipboard_text(int *len) { return scintilla_get_clipboard(focused_view, len); }

bool add_timeout(double interval, bool (*f)(int *), int *refs) { return false; }

// Contains information about a generic dialog shell.
// Widgets can be added to its 'screen' field.
typedef struct {
  WINDOW *border, *content;
  CDKSCREEN *screen;
  CDKBUTTONBOX *buttonbox;
} Dialog;

// Reads the specified button labels into the given array and returns the number of buttons read.
// Note: buttons are right-to-left.
static int read_buttons(DialogOptions *opts, const char *rtl_labels[3]) {
  int num_buttons = 0;
  if (opts->buttons[2]) rtl_labels[num_buttons++] = opts->buttons[2];
  if (opts->buttons[1]) rtl_labels[num_buttons++] = opts->buttons[1];
  rtl_labels[num_buttons++] = opts->buttons[0];
  return num_buttons;
}

int message_dialog(DialogOptions opts, lua_State *L) {
  const char *rtl_buttons[3];
  int num_buttons = read_buttons(&opts, rtl_buttons), lines = 2;
  char *text = strcpy(malloc((opts.text ? strlen(opts.text) : 0) + 1), opts.text ? opts.text : "");
  for (const char *p = text; *p; p++)
    if (*p == '\n') lines++;
  const char *message[lines];
  int i = 0;
  message[i++] = opts.title, message[i++] = text;
  for (char *p = text; *p; p++)
    if (*p == '\n') *p = '\0', message[i++] = p + 1;
  CDKSCREEN *screen = initCDKScreen(newwin(10, 40, 0, 0));
  CDKDIALOG *dialog = newCDKDialog(screen, 0, 1, (char **)message, lines, (char **)rtl_buttons,
    num_buttons, A_REVERSE, true, true, false);
  int button = (injectCDKDialog(dialog, KEY_BTAB), activateCDKDialog(dialog, NULL));
  button = (dialog->exitType == vNORMAL) ? num_buttons - button : 0; // buttons are right-to-left
  destroyCDKDialog(dialog), delwin(screen->window), destroyCDKScreen(screen);
  return (free(text), button ? (lua_pushinteger(L, button), 1) : 0);
}

// Returns a new dialog with given specified dimensions.
static Dialog new_dialog(DialogOptions *opts, int height, int width) {
  Dialog dialog;
  dialog.border = newwin(height, width, 1, 1), dialog.content = newwin(height - 2, width - 2, 2, 2);
  dialog.screen = initCDKScreen(dialog.content);
  const char *rtl_buttons[3];
  int num_buttons = read_buttons(opts, rtl_buttons);
  dialog.buttonbox = newCDKButtonbox(dialog.screen, 0, BOTTOM, 1, 0, "", 1, num_buttons,
    (char **)rtl_buttons, num_buttons, A_REVERSE, true, false);
  setCDKButtonboxCurrentButton(dialog.buttonbox, num_buttons - 1);
  return dialog;
}

// Draws the given dialog to the screen.
static void draw_dialog(Dialog *dialog) {
  box(dialog->border, 0, 0), wrefresh(dialog->border), refreshCDKScreen(dialog->screen);
}

// Deletes the given dialog and frees its resources.
static void destroy_dialog(Dialog *dialog) {
  destroyCDKButtonbox(dialog->buttonbox), delwin(dialog->content), delwin(dialog->border),
    destroyCDKScreen(dialog->screen);
}

// Signals a buttonbox to process the given key as if it was pressed.
// This is typically either KEY_TAB or KEY_BTAB in order to cycle the focus between buttons.
static int buttonbox_keypress(EObjectType _, void *__, void *data, chtype key) {
  return (injectCDKButtonbox((CDKBUTTONBOX *)data, key), true);
}

int input_dialog(DialogOptions opts, lua_State *L) {
  Dialog dialog = new_dialog(&opts, 10, 40);
  CDKENTRY *entry = newCDKEntry(dialog.screen, LEFT, TOP, (char *)opts.title, "", A_NORMAL, '_',
    vMIXED, 0, 0, 100, false, false);
  CDKBUTTONBOX *box = dialog.buttonbox;
  bindCDKObject(vENTRY, entry, KEY_TAB, buttonbox_keypress, box),
    bindCDKObject(vENTRY, entry, KEY_BTAB, buttonbox_keypress, box);
  if (opts.text) setCDKEntryValue(entry, (char *)opts.text);
  draw_dialog(&dialog), activateCDKEntry(entry, NULL);
  // Note: buttons are right-to-left.
  int button = (entry->exitType == vNORMAL) ? box->buttonCount - box->currentButton : 0;
  if (!button || (button == 2 && !opts.return_button))
    return (destroyCDKEntry(entry), destroy_dialog(&dialog), 0);
  lua_pushstring(L, getCDKEntryValue(entry));
  if (opts.return_button) lua_pushinteger(L, button);
  return (destroyCDKEntry(entry), destroy_dialog(&dialog), !opts.return_button ? 1 : 2);
}

// `ui.dialogs.open{...}` or `ui.dialogs.save{...}` Lua function.
static int open_save(DialogOptions *opts, lua_State *L, bool open) {
  char cwd[FILENAME_MAX];
  getcwd(cwd, FILENAME_MAX); // save because cdk changes it
  WINDOW *window = newwin(LINES - 2, COLS - 2, 1, 1);
  CDKSCREEN *dialog = initCDKScreen(window);
  CDKFSELECT *select = newCDKFselect(dialog, LEFT, TOP, LINES - 2, COLS - 2, (char *)opts->title,
    (char *)opts->text, A_NORMAL, '_', A_REVERSE, "</B>", "</N>", "</N>", "</N>", TRUE, FALSE);
  if (opts->dir) setCDKFselectDirectory(select, (char *)opts->dir);
  if (opts->file) {
    char *dir = dirName((char *)opts->file);
    setCDKFselectDirectory(select, dir);
    // TODO: select file in the list.
    free(dir);
  }
  lua_pushstring(L, activateCDKFselect(select, NULL)); // returns NULL/pushes nil if canceled
  if (select->exitType == vNORMAL && opts->only_dirs)
    lua_pushstring(L, getCDKFselectDirectory(select)), lua_replace(L, -2);
  if (opts->multiple) lua_createtable(L, 0, 1), lua_insert(L, -2), lua_rawseti(L, -2, 1);
  return (destroyCDKFselect(select), delwin(window), destroyCDKScreen(dialog), chdir(cwd), 1);
}

int open_dialog(DialogOptions opts, lua_State *L) { return open_save(&opts, L, true); }
int save_dialog(DialogOptions opts, lua_State *L) { return open_save(&opts, L, false); }

// Updates the given progressbar with the given percentage and text.
static void update(double percent, const char *text, void *bar) {
  if (percent >= 0) setCDKSliderValue(bar, (int)percent);
}

int progress_dialog(
  DialogOptions opts, lua_State *L, bool (*work)(void (*)(double, const char *, void *), void *)) {
  Dialog dialog = new_dialog(&opts, 10, 40);
  CDKSLIDER *bar = newCDKSlider(dialog.screen, LEFT, TOP, (char *)opts.title, "", ' ' | A_REVERSE,
    0, 0, 0, 100, 1, 2, false, false);
  bool stop = false;
  while (work(update, bar)) {
    draw_dialog(&dialog);
    int key;
    timeout(0), key = getch(), timeout(-1);
    if (key == KEY_ENTER || key == '\n') {
      stop = true;
      break;
    }
  }
  return (destroyCDKSlider(bar), destroy_dialog(&dialog), stop ? (lua_pushboolean(L, true), 1) : 0);
}

// Signals a scroll view to process the given key as if it was pressed.
static int scroll_keypress(EObjectType _, void *__, void *data, chtype key) {
  HasFocusObj(ObjOf((CDKSCROLL *)data)) = true; // needed to draw highlight
  injectCDKScroll((CDKSCROLL *)data, key);
  HasFocusObj(ObjOf((CDKSCROLL *)data)) = false;
  return true;
}

// Contains information about a list view.
typedef struct {
  int num_columns, search_column, num_items;
  char **items, **rows, **filtered_rows;
  CDKSCROLL *scroll;
} ListData;

// Shows and hides a list's item/row depending on the current search key.
// Iterates over all space-separated words in the key, matching each word to the item/row
// case-insensitively  and sequentially. If all key words match, shows the item/row.
static int refilter(EObjectType _, void *entry, void *data, chtype __) {
  char *key = getCDKEntryValue((CDKENTRY *)entry);
  ListData *list_data = (ListData *)data;
  if (*key) {
    int row = 0;
    for (int i = 0; i < list_data->num_items; i += list_data->num_columns) {
      char *item = list_data->items[i + list_data->search_column - 1];
      bool visible = false;
      const char *match_pos = item;
      for (const char *s = key, *e = s;; s = e) {
        while (*e && *e != ' ') e++;
        bool match = false;
        for (const char *p = match_pos; *p; p++)
          if (strncasecmp(s, p, e - s) == 0) {
            match_pos = p + (e - s), match = true;
            break;
          }
        if (match && !*e) visible = true;
        if (!match || !*e++) break;
      }
      if (visible) list_data->filtered_rows[row++] = list_data->rows[i / list_data->num_columns];
    }
    setCDKScrollItems(list_data->scroll, list_data->filtered_rows, row, false);
  } else
    setCDKScrollItems(
      list_data->scroll, list_data->rows, list_data->num_items / list_data->num_columns, false);
  HasFocusObj(ObjOf(list_data->scroll)) = true; // needed to draw highlight
  eraseCDKScroll(list_data->scroll); // drawCDKScroll does not completely redraw
  drawCDKScroll(list_data->scroll, true), drawCDKEntry((CDKENTRY *)entry, false);
  HasFocusObj(ObjOf(list_data->scroll)) = false;
  return true;
}

int list_dialog(DialogOptions opts, lua_State *L) {
  int num_columns = opts.columns ? lua_rawlen(L, opts.columns) : 1,
      num_items = lua_rawlen(L, opts.items);
  // There is an item store for filtering against, a row store that contains column data joined
  // by '|' separators, and a filtered row store that contains the actual rows to display.
  // Note the row store also contains a header line which is displayed separately.
  char *items[num_items];
  for (int i = 1; i <= num_items; i++) {
    const char *item = (lua_rawgeti(L, opts.items, i), lua_tostring(L, -1));
    items[i - 1] = strcpy(malloc(strlen(item) + 1), item), lua_pop(L, 1); // item
  }
  int num_rows = (num_items + num_columns - 1) / num_columns; // account for non-full rows
  char *rows[1 + num_rows] /* include header */, *filtered_rows[num_rows];
  // Compute the column sizes needed to fit all row items in.
  int column_widths[num_columns], row_len = 0;
  for (int i = 1; i <= num_columns; i++) {
    const char *column = opts.columns ? (lua_rawgeti(L, opts.columns, i), lua_tostring(L, -1)) : "";
    int utf8max = utf8strlen(column), max = strlen(column);
    for (int j = i - 1; j < num_items; j += num_columns) {
      int utf8len = utf8strlen(items[j]);
      if (utf8len > utf8max) utf8max = utf8len, max = strlen(items[j]);
    }
    column_widths[i - 1] = utf8max, row_len += max + 1; // include space for '|' separator or '\0'
  }
  // Generate the display rows, padding row items to fit column widths and separating columns
  // with '|'s.
  // The column headers are a special case and need to be underlined too.
  for (int i = -num_columns; i < num_items; i += num_columns) {
    char *row = malloc((i < 0) ? row_len + 4 : row_len);
    char *p = (i < 0) ? strcpy(row, "</U>") + 4 : row;
    for (int j = i; j < i + num_columns && j < num_items; j++) {
      const char *item = (i < 0) ?
        (opts.columns ? (lua_rawgeti(L, opts.columns, j - i + 1), lua_tostring(L, -1)) : "") :
        items[j];
      p = strcpy(p, item) + strlen(item);
      int padding = column_widths[j - i] - utf8strlen(item);
      while (padding-- > 0) *p++ = ' ';
      *p++ = (i < 0) ? '|' : ' ';
      if (i < 0 && opts.columns) lua_pop(L, 1); // header
    }
    if (p > row) *(p - 1) = '\0';
    rows[i / num_columns + 1] = row;
    if (i >= 0) filtered_rows[i / num_columns] = row;
  }

  Dialog dialog = new_dialog(&opts, LINES - 2, COLS - 2);
  CDKENTRY *entry = newCDKEntry(dialog.screen, LEFT, TOP, (char *)opts.title, "", A_NORMAL, '_',
    vMIXED, 0, 0, 100, false, false);
  CDKSCROLL *scroll = newCDKScroll(dialog.screen, LEFT, CENTER, RIGHT, -6, 0,
    opts.columns ? rows[0] : "", &rows[1], num_rows, false, A_REVERSE, true, false);
  // TODO: select multiple.
  CDKBUTTONBOX *box = dialog.buttonbox;
  bindCDKObject(vENTRY, entry, KEY_TAB, buttonbox_keypress, box),
    bindCDKObject(vENTRY, entry, KEY_BTAB, buttonbox_keypress, box),
    bindCDKObject(vENTRY, entry, KEY_UP, scroll_keypress, scroll),
    bindCDKObject(vENTRY, entry, KEY_DOWN, scroll_keypress, scroll),
    bindCDKObject(vENTRY, entry, KEY_PPAGE, scroll_keypress, scroll),
    bindCDKObject(vENTRY, entry, KEY_NPAGE, scroll_keypress, scroll);
  // TODO: commands to scroll the list to the right and left.
  ListData data = {
    num_columns, opts.search_column, num_items, items, &rows[1], filtered_rows, scroll};
  setCDKEntryPostProcess(entry, refilter, &data);
  if (opts.text) setCDKEntryValue(entry, (char *)opts.text);

  draw_dialog(&dialog), refilter(vENTRY, entry, &data, 0), activateCDKEntry(entry, NULL);
  // Note: buttons are right-to-left.
  int button = (entry->exitType == vNORMAL) ? box->buttonCount - box->currentButton : 0;
  int index = getCDKScrollItems(scroll, NULL) > 0 ? getCDKScrollCurrentItem(scroll) + 1 : 0;
  if (index) {
    char *item = filtered_rows[index - 1];
    for (int j = 1; j < num_rows + 1; j++) // account for and skip header
      if (strcmp(item, rows[j]) == 0) {
        index = j; // non-filtered index of selected item (no +1 due to skipped header)
        break;
      }
  }
  // Note: table will be replaced by a single result if multiple is false.
  lua_createtable(L, 0, 1), lua_pushinteger(L, index), lua_rawseti(L, -2, 1);
  if (!opts.multiple) lua_rawgeti(L, -1, 1), lua_replace(L, -2); // single result
  if (opts.return_button) lua_pushinteger(L, button);
  destroyCDKScroll(scroll), destroyCDKEntry(entry), destroy_dialog(&dialog);
  for (int i = 0; i < num_rows + 1; i++) free(rows[i]); // includes header
  for (int i = 0; i < num_items; i++) free(items[i]);
  bool cancelled = !button || (button == 2 && !opts.return_button);
  return (cancelled || !index ? 0 : (!opts.return_button ? 1 : 2));
}

bool spawn(lua_State *L, Process *proc, int index, const char *cmd, const char *cwd, int envi,
  bool monitor_stdout, bool monitor_stderr, const char **error) {
#if !_WIN32
  int argc = 0, top = lua_gettop(L);
  // Construct argv from cmd and envp from envi.
  const char *p = cmd, *param;
  while (*p) {
    while (*p == ' ') p++;
    param = p;
    if (*p == '"' || *p == '\'') {
      char q = *p;
      param = ++p;
      while (*p && (*p != q || *(p - 1) == '\\')) p++;
    } else
      while (*p && *p != ' ') p++;
    lua_checkstack(L, 1), lua_pushlstring(L, param, p - param), argc++;
    if (*p == '"' || *p == '\'') p++;
  }
  int envc = envi ? lua_rawlen(L, envi) : 0;
  char *argv[argc + 1], *envp[envc + 1];
  for (int i = 0; i < argc; i++) argv[i] = (char *)lua_tostring(L, top + 1 + i);
  argv[argc] = NULL;
  if (lua_checkstack(L, envc), envi)
    for (int i = (lua_pushnil(L), 0); lua_next(L, envi); lua_pop(L, 1), i++)
      envp[i] = (char *)(lua_pushvalue(L, -1), lua_insert(L, -3), lua_tostring(L, -3));
  envp[envc] = NULL;

  // Adapted from Chris Emerson and GLib.
  // Attempt to create pipes for stdin, stdout, and stderr and fork process.
  int pstdin[2] = {-1, -1}, pstdout[2] = {-1, -1}, pstderr[2] = {-1, -1}, pid = -1;
  if (pipe(pstdin) == 0 && pipe(pstdout) == 0 && pipe(pstderr) == 0 && (pid = fork()) < 0) {
    if (pstdin[0] >= 0) close(pstdin[0]), close(pstdin[1]);
    if (pstdout[0] >= 0) close(pstdout[0]), close(pstdout[1]);
    if (pstderr[0] >= 0) close(pstderr[0]), close(pstderr[1]);
    return (*error = strerror(errno), false);
  }
  if (pid > 0) {
    // Parent process: register child for monitoring its fds and pid.
    close(pstdin[0]), close(pstdout[1]), close(pstderr[1]);
    PROCESS(proc)->pid = pid, PROCESS(proc)->fstdin = pstdin[1],
    PROCESS(proc)->fstdout = pstdout[0], PROCESS(proc)->fstderr = pstderr[0],
    PROCESS(proc)->monitor_stdout = monitor_stdout, PROCESS(proc)->monitor_stderr = monitor_stderr;
    lua_checkstack(L, 3), lua_getfield(L, LUA_REGISTRYINDEX, "spawn_procs"),
      lua_pushvalue(L, index), lua_pushboolean(L, 1), lua_settable(L, -3); // t[proc] = true
    return true;
  }
  // Child process: redirect stdin, stdout, and stderr, chdir, and exec.
  close(pstdin[1]), close(pstdout[0]), close(pstderr[0]), close(0), close(1), close(2);
  dup2(pstdin[0], 0), dup2(pstdout[1], 1), dup2(pstderr[1], 2);
  close(pstdin[0]), close(pstdout[1]), close(pstderr[1]);
  if (cwd && chdir(cwd) < 0)
    fprintf(stderr, "Failed to change directory '%s' (%s)", cwd, strerror(errno)), exit(1);
  extern char **environ;
#if __linux__
  execvpe(argv[0], argv, envi ? envp : environ); // does not return on success
#else
  if (envi) environ = envp;
  execvp(argv[0], argv); // does not return on success
#endif
  fprintf(stderr, "Failed to execute child process \"%s\" (%s)", argv[0], strerror(errno)), exit(1);
#else // _WIN32
  return (*error = "not implemented in this environment", NULL);
#endif
}

size_t process_size() { return sizeof(struct Process); }

bool is_process_running(Process *proc) { return PROCESS(proc)->pid; }

void wait_process(Process *proc) {
#if !_WIN32
  int status;
  waitpid(PROCESS(proc)->pid, &status, 0), status = WIFEXITED(status) ? WEXITSTATUS(status) : 1;
  cleanup_process(proc, status);
#endif
}

char *read_process_output(Process *proc, char option, size_t *len, const char **error, int *code) {
#if !_WIN32
  char *buf;
  if (option == 'n') {
    *len = read(PROCESS(proc)->fstdout, buf = malloc(*len), *len);
    return (*len == 0 ? (*error = NULL, NULL) : buf);
  }
  int n;
  char ch;
  luaL_Buffer lbuf;
  luaL_buffinit(lua, &lbuf);
  *len = 0;
  while ((n = read(PROCESS(proc)->fstdout, &ch, 1)) > 0) {
    if ((ch != '\r' && ch != '\n') || option == 'L' || option == 'a')
      luaL_addchar(&lbuf, ch), (*len)++;
    if (ch == '\n' && option != 'a') break;
  }
  luaL_pushresult(&lbuf);
  if (n < 0 && *len == 0) return (lua_pop(lua, 1), *error = strerror(errno), *code = errno, NULL);
  if (n == 0 && *len == 0 && option != 'a') return (lua_pop(lua, 1), *error = NULL, NULL); // EOF
  buf = strcpy(malloc(*len + 1), lua_tostring(lua, -1));
  return (lua_pop(lua, 1), *error = NULL, buf); // pop buf
#else
  return NULL;
#endif
}

void write_process_input(Process *proc, const char *s, size_t len) {
#if !_WIN32
  write(PROCESS(proc)->fstdin, s, len);
#endif
}

void close_process_input(Process *proc) {
#if !_WIN32
  close(PROCESS(proc)->fstdin);
#endif
}

void kill_process(Process *proc, int signal) {
#if !_WIN32
  kill(PROCESS(proc)->pid, signal ? signal : SIGKILL);
#endif
}

int get_process_exit_status(Process *proc) { return PROCESS(proc)->exit_status; }

void quit() { quitting = !emit("quit", -1); }

#if !_WIN32
// Signal for a terminal suspend, continue, and resize.
// libtermkey has been patched to enable suspend as well as enable/disable mouse mode (1002).
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

// Replacement for `termkey_waitkey()` that handles asynchronous I/O.
static TermKeyResult textadept_waitkey(TermKey *tk, TermKeyKey *key) {
  refresh_all();
#if !_WIN32
  bool force = false;
  struct timeval timeout = {0, termkey_get_waittime(tk)};
  while (true) {
    TermKeyResult res = !force ? termkey_getkey(tk, key) : termkey_getkey_force(tk, key);
    if (res != TERMKEY_RES_AGAIN && res != TERMKEY_RES_NONE) return res;
    if (res == TERMKEY_RES_AGAIN) force = true;
    // Wait for input.
    int nfds;
    fd_set *fds = new_fds(&nfds);
    FD_SET(0, fds); // monitor stdin (note: this is a do/while macro on OSX)
    nfds = fmax(nfds, 1);
    if (select(nfds, fds, NULL, NULL, force ? &timeout : NULL) > 0) {
      if (FD_ISSET(0, fds)) termkey_advisereadable(tk);
      if (read_fds(fds) > 0) refresh_all();
    }
    free(fds);
  }
#else
  // TODO: ideally computation of view would not be done twice.
  SciObject *view = !command_entry_active ? focused_view : command_entry;
  termkey_set_fd(ta_tk, scintilla_get_window(view));
  mouse_set(ALL_MOUSE_EVENTS); // _popen() and system() change console mode
  return termkey_getkey(tk, key);
#endif
}

// Runs Textadept.
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
  // Need to keep track of running processes for monitoring fds and pids.
  lua_newtable(lua), lua_setfield(lua, LUA_REGISTRYINDEX, "spawn_procs");

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

  SciObject *view = focused_view;
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

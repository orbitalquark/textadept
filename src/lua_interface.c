// Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

#define streq(s1, s2) strcmp(s1, s2) == 0
#define l_insert(l, i) lua_insert(l, (i < 0) ? lua_gettop(l) + i : i)
#define l_append(l, i) lua_rawseti(l, i, lua_objlen(l, i) + 1)
#define l_cfunc(l, f, k) { \
  lua_pushcfunction(l, f); \
  lua_setfield(l, -2, k); \
}
#define l_archive(l, k) { \
  lua_pushstring(l, k); \
  lua_rawget(l, -2); \
  lua_setfield(l, LUA_REGISTRYINDEX, k); \
}
#define l_togtkwidget(l, i) (GtkWidget *)lua_touserdata(l, i)
#define l_mt(l, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_cfunc(l, i, "__index"); \
    l_cfunc(l, ni, "__newindex"); \
  } \
  lua_setmetatable(l, -2); \
}

lua_State *lua;
int closing = FALSE;
const char *statusbar_text = 0;

static int tVOID = 0, tINT = 1, tLENGTH = 2, /*tPOSITION = 3, tCOLOUR = 4,*/
           tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;

static void clear_table(lua_State *lua, int index);
static void warn(const char *s) { printf("Warning: %s\n", s); }

static int l_buffer_mt_index(lua_State *), l_buffer_mt_newindex(lua_State *),
           l_bufferp_mt_index(lua_State *), l_bufferp_mt_newindex(lua_State *),
           l_view_mt_index(lua_State *), l_view_mt_newindex(lua_State *),
           l_gui_mt_index(lua_State *), l_gui_mt_newindex(lua_State *),
           l_find_mt_index(lua_State *), l_find_mt_newindex(lua_State *),
           l_ce_mt_index(lua_State *), l_ce_mt_newindex(lua_State *);

static int l_cf_buffer_delete(lua_State *), l_cf_buffer_text_range(lua_State *),
           l_cf_view_focus(lua_State *), l_cf_view_split(lua_State *),
           l_cf_view_unsplit(lua_State *), l_cf_buffer_new(lua_State *),
           l_cf_gui_dialog(lua_State *), l_cf_gui_get_split_table(lua_State *),
           l_cf_gui_goto_view(lua_State *), l_cf_view_goto_buffer(lua_State *),
           l_cf_gui_gtkmenu(lua_State *), l_cf_string_iconv(lua_State *),
           l_cf_reset(lua_State *), l_cf_quit(lua_State *),
           l_cf_find_focus(lua_State *), l_cf_find_next(lua_State *),
           l_cf_find_prev(lua_State *), l_cf_find_replace(lua_State *),
           l_cf_find_replace_all(lua_State *), l_cf_ce_focus(lua_State *),
           l_cf_ce_show_completions(lua_State *);

/**
 * Inits or re-inits the Lua State.
 * Populates the state with global variables and functions, then runs the
 * 'core/init.lua' script.
 * @param argc The number of command line parameters.
 * @param argv The array of command line parameters.
 * @param reinit Flag indicating whether or not to reinitialize the Lua State.
 */
int l_init(int argc, char **argv, int reinit) {
  if (!reinit) {
    lua = lua_open();
    lua_newtable(lua);
    for (int i = 0; i < argc; i++) {
      lua_pushstring(lua, argv[i]);
      lua_rawseti(lua, -2, i);
    }
    lua_setfield(lua, LUA_REGISTRYINDEX, "arg");
    lua_newtable(lua);
    lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
    lua_newtable(lua);
    lua_setfield(lua, LUA_REGISTRYINDEX, "views");
  } else { // clear package.loaded and _G
    lua_getglobal(lua, "package");
    lua_getfield(lua, -1, "loaded");
    clear_table(lua, lua_gettop(lua));
    lua_pop(lua, 2); // package and package.loaded
    clear_table(lua, LUA_GLOBALSINDEX);
  }
  luaL_openlibs(lua);

  lua_newtable(lua);
    lua_newtable(lua);
      l_cfunc(lua, l_cf_find_next, "find_next");
      l_cfunc(lua, l_cf_find_prev, "find_prev");
      l_cfunc(lua, l_cf_find_focus, "focus");
      l_cfunc(lua, l_cf_find_replace, "replace");
      l_cfunc(lua, l_cf_find_replace_all, "replace_all");
      l_mt(lua, "_find_mt", l_find_mt_index, l_find_mt_newindex);
    lua_setfield(lua, -2, "find");
    lua_newtable(lua);
      l_cfunc(lua, l_cf_ce_focus, "focus");
      l_cfunc(lua, l_cf_ce_show_completions, "show_completions");
      l_mt(lua, "_ce_mt", l_ce_mt_index, l_ce_mt_newindex);
    lua_setfield(lua, -2, "command_entry");
    l_cfunc(lua, l_cf_gui_dialog, "dialog");
    l_cfunc(lua, l_cf_gui_get_split_table, "get_split_table");
    l_cfunc(lua, l_cf_gui_goto_view, "goto_view");
    l_cfunc(lua, l_cf_gui_gtkmenu, "gtkmenu");
    l_mt(lua, "_gui_mt", l_gui_mt_index, l_gui_mt_newindex);
  lua_setglobal(lua, "gui");

  lua_getglobal(lua, "_G");
  l_cfunc(lua, l_cf_buffer_new, "new_buffer");
  l_cfunc(lua, l_cf_quit, "quit");
  l_cfunc(lua, l_cf_reset, "reset");
  lua_pop(lua, 1); // _G

  lua_getglobal(lua, "string");
  l_cfunc(lua, l_cf_string_iconv, "iconv");
  lua_pop(lua, 1); // string

  lua_getfield(lua, LUA_REGISTRYINDEX, "arg");
  lua_setglobal(lua, "arg");
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_setglobal(lua, "_BUFFERS");
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_setglobal(lua, "_VIEWS");
  lua_pushstring(lua, textadept_home);
  lua_setglobal(lua, "_HOME");
#if __WIN32__
  lua_pushboolean(lua, 1);
  lua_setglobal(lua, "WIN32");
#elif MAC
  lua_pushboolean(lua, 1);
  lua_setglobal(lua, "MAC");
#endif
  const char *charset = 0;
  g_get_charset(&charset);
  lua_pushstring(lua, charset);
  lua_setglobal(lua, "_CHARSET");

  if (l_load_script("core/init.lua")) {
    lua_getglobal(lua, "_SCINTILLA");
    l_archive(lua, "constants");
    l_archive(lua, "functions");
    l_archive(lua, "properties");
    lua_pop(lua, 1); // _SCINTILLA
    return TRUE;
  }
  lua_close(lua);
  return FALSE;
}

/**
 * Loads and runs a given Lua script.
 * @param script_file The path of the Lua script relative to textadept_home.
 */
int l_load_script(const char *script_file) {
  char *script = g_strconcat(textadept_home, "/", script_file, NULL);
  int retval = luaL_dofile(lua, script) == 0;
  if (!retval) {
    const char *errmsg = lua_tostring(lua, -1);
    lua_settop(lua, 0);
    GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                               GTK_MESSAGE_ERROR,
                                               GTK_BUTTONS_OK, "%s\n", errmsg);
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
  }
  g_free(script);
  return retval;
}

/**
 * Checks a specified stack element to see if it is a Scintilla window and
 * returns it as a GtkWidget.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a Scintilla window.
 */
static GtkWidget *l_checkview(lua_State *lua, int narg) {
  luaL_argcheck(lua, lua_istable(lua, narg), narg, "View expected");
  lua_pushstring(lua, "widget_pointer");
  lua_rawget(lua, (narg > 0) ? narg : narg - 1);
  luaL_argcheck(lua, lua_islightuserdata(lua, -1), narg, "View expected");
  GtkWidget *editor = l_togtkwidget(lua, -1);
  lua_pop(lua, 1); // widget_pointer
  return editor;
}

/**
 * Adds a Scintilla window to the global '_VIEWS' table with a metatable.
 * @param editor The Scintilla window to add.
 */
void l_add_scintilla_window(GtkWidget *editor) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_newtable(lua);
    lua_pushlightuserdata(lua, (GtkWidget *)editor);
    lua_setfield(lua, -2, "widget_pointer");
    l_cfunc(lua, l_cf_view_focus, "focus");
    l_cfunc(lua, l_cf_view_goto_buffer, "goto_buffer");
    l_cfunc(lua, l_cf_view_split, "split");
    l_cfunc(lua, l_cf_view_unsplit, "unsplit");
    l_mt(lua, "_view_mt", l_view_mt_index, l_view_mt_newindex);
  l_append(lua, -2); // pops table
  lua_pop(lua, 1); // views
}

/**
 * Removes a Scintilla window from the global '_VIEWS' table.
 * @param editor The Scintilla window to remove.
 */
void l_remove_scintilla_window(GtkWidget *editor) {
  lua_newtable(lua);
    lua_getfield(lua, LUA_REGISTRYINDEX, "views");
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      (editor != l_checkview(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
    lua_pop(lua, 1); // views
  lua_pushvalue(lua, -1);
  lua_setfield(lua, LUA_REGISTRYINDEX, "views");
  lua_setglobal(lua, "_VIEWS");
}

/**
 * Changes focus a Scintilla window in the global '_VIEWS' table.
 * @param editor The currently focused Scintilla window.
 * @param n The index of the window in the '_VIEWS' table to focus.
 * @param absolute Flag indicating whether or not the index specified in
 *   '_VIEWS' is absolute. If FALSE, focuses the window relative to the
 *   currently focused window for the given index.
 *   Throws an error if the view does not exist.
 */
void l_goto_scintilla_window(GtkWidget *editor, int n, int absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (!absolute) {
    unsigned int idx = 1;
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (editor == l_checkview(lua, -1)) {
        idx = lua_tointeger(lua, -2);
        lua_pop(lua, 2); // key and value
        break;
      } else lua_pop(lua, 1); // value
    idx += n;
    if (idx > lua_objlen(lua, -1))
      idx = 1;
    else if (idx < 1)
      idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else {
    luaL_argcheck(lua, n >= 0 && n <= lua_objlen(lua, -1), 1,
                  "no View exists at that index");
    lua_rawgeti(lua, -1, n);
  }
  editor = l_checkview(lua, -1);
  if (!closing) l_emit_event("view_before_switch", -1);
  gtk_widget_grab_focus(editor);
  if (!closing) l_emit_event("view_after_switch", -1);
  lua_pop(lua, 2); // view table and views
}

/**
 * Sets the global 'view' variable to be the specified Scintilla window.
 * @param editor The Scintilla window to set 'view' to.
 */
void l_set_view_global(GtkWidget *editor) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (editor == l_checkview(lua, -1)) {
      lua_setglobal(lua, "view"); // value (view table)
      lua_pop(lua, 1); // key
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // views
}

/**
 * Checks a specified element to see if it is a buffer table and returns the
 * Scintilla document pointer associated with it.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a buffer table.
 */
static sptr_t l_checkdocpointer(lua_State *lua, int narg) {
  luaL_argcheck(lua, lua_istable(lua, narg), narg, "Buffer expected");
  lua_pushstring(lua, "doc_pointer");
  lua_rawget(lua, (narg > 0) ? narg : narg - 1);
  luaL_argcheck(lua, lua_isnumber(lua, -1), narg, "Buffer expected");
  sptr_t doc = lua_tointeger(lua, -1);
  lua_pop(lua, 1); // doc_pointer
  return doc;
}

/**
 * Adds a Scintilla document to the global '_BUFFERS' table with a metatable.
 * @param doc The Scintilla document to add.
 * @return integer index of the new buffer in _BUFFERS.
 */
int l_add_scintilla_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_newtable(lua);
    lua_pushinteger(lua, doc);
    lua_setfield(lua, -2, "doc_pointer");
    l_cfunc(lua, l_cf_buffer_delete, "delete");
    l_cfunc(lua, l_cf_buffer_text_range, "text_range");
    l_mt(lua, "_buffer_mt", l_buffer_mt_index, l_buffer_mt_newindex);
  l_append(lua, -2); // pops table
  int index = lua_objlen(lua, -1);
  lua_pop(lua, 1); // buffers
  return index;
}

/**
 * Removes a Scintilla document from the global '_BUFFERS' table.
 * If any views currently show the document to be removed, change the documents
 * they show first.
 * @param doc The Scintilla buffer to remove.
 */
void l_remove_scintilla_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    GtkWidget *editor = l_checkview(lua, -1);
    sptr_t that_doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
    if (that_doc == doc) l_goto_scintilla_buffer(editor, -1, FALSE);
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // views
  lua_newtable(lua);
    lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      (doc != l_checkdocpointer(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
    lua_pop(lua, 1); // buffers
  lua_pushvalue(lua, -1);
  lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_setglobal(lua, "_BUFFERS");
}

/**
 * Retrieves the index in the global '_BUFFERS' table for a given Scintilla
 * document.
 * @param doc The Scintilla document to get the index of.
 */
unsigned int l_get_docpointer_index(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  unsigned int idx = 1;
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (doc == l_checkdocpointer(lua, -1)) {
      idx = lua_tointeger(lua, -2);
      lua_pop(lua, 2); // key and value
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // buffers
  return idx;
}

/**
 * Changes a Scintilla window's document to one in the global '_BUFFERS' table.
 * Before doing so, it saves the scroll and caret positions in the current
 * Scintilla document. Then when the new document is shown, its scroll and caret
 * positions are restored.
 * @param editor The Scintilla window to change the document of.
 * @param n The index of the document in '_BUFFERS' to focus.
 * @param absolute Flag indicating whether or not the index specified in
 *   '_BUFFERS' is absolute. If FALSE, focuses the document relative to the
 *   currently focused document for the given index.
 *   Throws an error if the buffer does not exist.
 */
void l_goto_scintilla_buffer(GtkWidget *editor, int n, int absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  if (!absolute) {
    sptr_t doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
    unsigned int idx = l_get_docpointer_index(doc);
    idx += n;
    if (idx > lua_objlen(lua, -1))
      idx = 1;
    else if (idx < 1)
      idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else {
    luaL_argcheck(lua, n >= 0 && n <= lua_objlen(lua, -1), 2,
                  "no Buffer exists at that index");
    lua_rawgeti(lua, -1, n);
  }
  sptr_t doc = l_checkdocpointer(lua, -1);
  if (!closing) l_emit_event("buffer_before_switch", -1);
  SS(editor, SCI_SETDOCPOINTER, 0, doc);
  l_set_buffer_global(editor);
  if (!closing) l_emit_event("buffer_after_switch", -1);
  lua_pop(lua, 2); // buffer table and buffers
}

/**
 * Sets the global 'buffer' variable to be the document in the specified
 * Scintilla object.
 * @param editor The Scintilla widget housing the buffer to be 'buffer'.
 */
void l_set_buffer_global(GtkWidget *editor) {
  sptr_t doc = SS(editor, SCI_GETDOCPOINTER, 0, 0);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (doc == l_checkdocpointer(lua, -1)) {
      lua_setglobal(lua, "buffer"); // value (buffer table)
      lua_pop(lua, 1); // key
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // buffers
}

/**
 * Closes the Lua State.
 * Unsplits all Scintilla windows recursively, removes all Scintilla documents,
 * and deletes the last Scintilla window before closing the state.
 */
void l_close() {
  closing = TRUE;
  while (unsplit_window(focused_editor)) ; // need space to fix compiler warning
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    sptr_t doc = l_checkdocpointer(lua, -1);
    remove_scintilla_buffer(doc);
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // buffers
  gtk_widget_destroy(focused_editor);
  lua_close(lua);
}

// Utility Functions

/**
 * Recurses through a Lua table, setting each of its keys and values to nil,
 * effectively clearing the table.
 * @param lua The Lua State.
 * @param abs_index The absolute stack index of the table to clear.
 */
static void clear_table(lua_State *lua, int abs_index) {
  lua_pushnil(lua);
  while (lua_next(lua, abs_index)) {
    lua_pop(lua, 1); // value
    lua_pushnil(lua);
    lua_rawset(lua, abs_index);
    lua_pushnil(lua); // get 'new' first key
  }
}

/**
 * Returns whether or not the value of the key of the given global table is a
 * function.
 * @param table The table to check for key in.
 * @param key String key to check for in table.
 */
int l_is2function(const char *table, const char *key) {
  lua_getglobal(lua, table);
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, key);
    lua_remove(lua, -2); // table
    if (lua_isfunction(lua, -1)) return TRUE;
    lua_pop(lua, 1); // non-function
  } else lua_pop(lua, 1); // non-table
  return FALSE;
}

/**
 * Calls a Lua function with a number of arguments and expected return values.
 * The last argument is at the stack top, and each argument in reverse order is
 * one element lower on the stack with the Lua function being under the first
 * argument.
 * @param nargs The number of arguments to pass to the Lua function to call.
 * @param retn Optional number of expected return values. Defaults to 0.
 * @param keep_return Optional flag indicating whether or not to keep the return
 *   values at the top of the stack. If FALSE, discards the return values.
 *   Defaults to FALSE.
 */
static int l_call_function(int nargs, int retn, int keep_return) {
  int ret = lua_pcall(lua, nargs, retn, 0);
  if (ret == 0) {
    int result = (retn > 0) ? lua_toboolean(lua, -1) == 1 : TRUE;
    if (retn > 0 && !keep_return) lua_pop(lua, retn); // retn
    return result;
  } else {
    if (focused_editor)
      l_emit_event("error", LUA_TSTRING, lua_tostring(lua, -1), -1);
    else
      printf("Lua Error: %s\n", lua_tostring(lua, -1));
    lua_settop(lua, 0);
  }
  return FALSE;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns an int.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param n The index in the table to rawget.
 */
static int l_rawgeti_int(lua_State *lua, int index, int n) {
  lua_rawgeti(lua, index, n);
  int ret = lua_tointeger(lua, -1);
  lua_pop(lua, 1); // integer
  return ret;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns a string.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param k String key in the table to rawget.
 */
static const char *l_rawget_str(lua_State *lua, int index, const char *k) {
  lua_pushstring(lua, k);
  lua_rawget(lua, index);
  const char *str = lua_tostring(lua, -1);
  lua_pop(lua, 1); // string
  return str;
}

/**
 * Creates a GtkMenu from a table at the top of the Lua stack.
 * The table has a key 'title' and a numeric list of subitems.
 * @param lua The Lua State.
 * @param callback A GCallback associated with each menu item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 */
GtkWidget *l_create_gtkmenu(lua_State *lua, GCallback callback, int submenu) {
  GtkWidget *menu = gtk_menu_new(), *menu_item = 0, *submenu_root = 0;
  const char *label;
  lua_getfield(lua, -1, "title");
  if (!lua_isnil(lua, -1) || submenu) { // title required for submenu
    label = !lua_isnil(lua, -1) ? lua_tostring(lua, -1) : "notitle";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  }
  lua_pop(lua, 1); // title
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_istable(lua, -1)) {
      lua_getfield(lua, -1, "title");
      int is_submenu = !lua_isnil(lua, -1);
      lua_pop(lua, 1); // title
      if (is_submenu)
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              l_create_gtkmenu(lua, callback, TRUE));
      else
        if (lua_objlen(lua, -1) == 2) {
          lua_rawgeti(lua, -1, 1);
          lua_rawgeti(lua, -2, 2);
          label = lua_tostring(lua, -2);
          int menu_id = lua_tointeger(lua, -1);
          lua_pop(lua, 2); // label and id
          if (label) {
            if (g_str_has_prefix(label, "gtk-"))
              menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
            else if (streq(label, "separator"))
              menu_item = gtk_separator_menu_item_new();
            else
              menu_item = gtk_menu_item_new_with_mnemonic(label);
            g_signal_connect(menu_item, "activate", callback,
                             GINT_TO_POINTER(menu_id));
            gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
          }
        } else warn("gtkmenu: { 'menu label', id_number } expected");
    }
    lua_pop(lua, 1); // value
  }
  return !submenu_root ? menu : submenu_root;
}

/**
 * Convert the stack element at a specified index to a Scintilla w and/or l long
 * parameter based on type.
 * @param lua The Lua State.
 * @param type The Lua type the top stack element is.
 * @param arg_idx The initial stack index to start converting at. It is
 *   incremented as parameters are read from the stack.
 */
static long l_toscintillaparam(lua_State *lua, int type, int *arg_idx) {
  if (type == tSTRING)
    return (long)lua_tostring(lua, (*arg_idx)++);
  else if (type == tBOOL)
    return lua_toboolean(lua, (*arg_idx)++);
  else if (type == tKEYMOD) {
    int key = luaL_checkinteger(lua, (*arg_idx)++) & 0xFFFF;
    return key | ((luaL_checkinteger(lua, (*arg_idx)++) &
                 (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  } else if (type > tVOID && type < tBOOL)
    return luaL_checklong(lua, (*arg_idx)++);
  else
    return 0;
}

/**
 * Checks if the Scintilla document of the buffer table at the index specified
 * is the document of the focused Scintilla window.
 * Throws an error if the check is not satisfied.
 * @param lua The Lua State.
 * @param narg The relative stack position of the buffer table.
 */
static void l_check_focused_buffer(lua_State *lua, int narg) {
  sptr_t cur_doc = SS(focused_editor, SCI_GETDOCPOINTER, 0, 0);
  luaL_argcheck(lua, cur_doc == l_checkdocpointer(lua, narg), 1,
                "the indexed Buffer is not the focused one");
}

// Notification/event handlers

/**
 * Handles a Textadept event.
 * @param s String event name.
 * @param ... Optional arguments to pass to the handler. The variable argument
 *   list should contain Lua types followed by the data of that type to pass.
 *   The list is terminated by a -1.
 */
int l_emit_event(const char *s, ...) {
  if (!l_is2function("events", "emit")) return FALSE;
  lua_pushstring(lua, s);
  int n = 1;
  va_list ap;
  va_start(ap, s);
  int type = va_arg(ap, int);
  while (type != -1) {
    void *arg = va_arg(ap, void*);
    if (type == LUA_TNIL)
      lua_pushnil(lua);
    else if (type == LUA_TBOOLEAN)
      lua_pushboolean(lua, (long)arg);
    else if (type == LUA_TNUMBER)
      lua_pushinteger(lua, (long)arg);
    else if (type == LUA_TSTRING)
      lua_pushstring(lua, (char *)arg);
    else if (type == LUA_TLIGHTUSERDATA || type == LUA_TTABLE) {
      long ref = (long)arg;
      lua_rawgeti(lua, LUA_REGISTRYINDEX, ref);
      luaL_unref(lua, LUA_REGISTRYINDEX, ref);
    } else warn("events.emit: ignored invalid argument type");
    n++;
    type = va_arg(ap, int);
  }
  va_end(ap);
  return l_call_function(n, 1, FALSE);
}

#define l_pushscninteger(i, n) { \
  lua_pushinteger(lua, i); \
  lua_setfield(lua, -2, n); \
}

/**
 * Handles a Scintilla notification.
 * @param n The Scintilla notification struct.
 */
void l_emit_scnnotification(struct SCNotification *n) {
  if (!l_is2function("events", "notification")) return;
  lua_newtable(lua);
  l_pushscninteger(n->nmhdr.code, "code");
  l_pushscninteger(n->position, "position");
  l_pushscninteger(n->ch, "ch");
  l_pushscninteger(n->modifiers, "modifiers");
  //l_pushscninteger(n->modificationType, "modification_type");
  lua_pushstring(lua, n->text);
  lua_setfield(lua, -2, "text");
  //l_pushscninteger(n->length, "length");
  //l_pushscninteger(n->linesAdded, "lines_added");
  //l_pushscninteger(n->message, "message");
  l_pushscninteger(n->wParam, "wParam");
  l_pushscninteger(n->lParam, "lParam");
  l_pushscninteger(n->line, "line");
  //l_pushscninteger(n->foldLevelNow, "fold_level_now");
  //l_pushscninteger(n->foldLevelPrev, "fold_level_prev");
  l_pushscninteger(n->margin, "margin");
  //l_pushscninteger(n->x, "x");
  //l_pushscninteger(n->y, "y");
  l_call_function(1, 0, FALSE);
}

/**
 * Requests and pops up a context menu for the Scintilla view.
 * @param event The mouse button event.
 */
void l_gui_popup_context_menu(GdkEventButton *event) {
  lua_getglobal(lua, "gui");
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, "context_menu");
    if (lua_isuserdata(lua, -1)) {
      GtkWidget *menu = l_togtkwidget(lua, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? event->button : 0,
                     gdk_event_get_time((GdkEvent *)event));
    } else if (!lua_isnil(lua, -1))
      warn("gui.context_menu: gtkmenu expected");
    lua_pop(lua, 1); // gui.context_menu
  } else lua_pop(lua, 1);
}

// Lua functions (stack maintenence is unnecessary)

/**
 * Calls Scintilla with appropriate parameters and returs appropriate values.
 * @param lua The Lua State.
 * @param editor The Scintilla window to call.
 * @param msg The integer message index to call Scintilla with.
 * @param p1_type The Lua type of p1, the Scintilla w parameter.
 * @param p2_type The Lua type of p2, the Scintilla l parameter.
 * @param rt_type The Lua type of the Scintilla return parameter.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 */
static int l_call_scintilla(lua_State *lua, GtkWidget *editor, int msg,
                            int p1_type, int p2_type, int rt_type, int arg) {
  long params[2] = {0, 0};
  int params_needed = 2, len = 0, string_return = FALSE;
  char *return_string = 0;

  // SCI_PRIVATELEXERCALL iface has p1_type int, p2_type int. Change p2_type
  // appropriately. See LPeg lexer API for more info.
  if (msg == SCI_PRIVATELEXERCALL) {
    p2_type = tSTRINGRESULT;
    int c = luaL_checklong(lua, arg);
    if (c == SCI_GETDIRECTFUNCTION || c == SCI_SETDOCPOINTER) p2_type = tINT;
    else if (c == SCI_SETLEXERLANGUAGE) p2_type = tSTRING;
  }

  // Set the w and l parameters appropriately for Scintilla.
  if (p1_type == tLENGTH && p2_type == tSTRING) {
    params[0] = (long)lua_strlen(lua, arg);
    params[1] = (long)lua_tostring(lua, arg);
    params_needed = 0;
  } else if (p2_type == tSTRINGRESULT) {
    string_return = TRUE;
    params_needed = (p1_type == tLENGTH) ? 0 : 1;
  }
  if (params_needed > 0) params[0] = l_toscintillaparam(lua, p1_type, &arg);
  if (params_needed > 1) params[1] = l_toscintillaparam(lua, p2_type, &arg);
  if (string_return) { // if a string return, create a buffer for it
    len = SS(editor, msg, params[0], 0);
    if (p1_type == tLENGTH) params[0] = len;
    return_string = malloc(len + 1);
    return_string[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    params[1] = (long)return_string;
  }

  // Send the message to Scintilla and return the appropriate values.
  int result = SS(editor, msg, params[0], params[1]);
  arg = lua_gettop(lua);
  if (string_return) lua_pushlstring(lua, return_string, len);
  if (rt_type == tBOOL) lua_pushboolean(lua, result);
  if (rt_type > tVOID && rt_type < tBOOL) lua_pushinteger(lua, result);
  g_free(return_string);
  return lua_gettop(lua) - arg;
}

/**
 * Calls a Scintilla buffer function with upvalues from a closure.
 * @param lua The Lua State.
 * @see l_buffer_mt_index
 */
static int l_call_buffer_function(lua_State *lua) {
  GtkWidget *editor = l_togtkwidget(lua, lua_upvalueindex(1));
  int buffer_func_table_idx = lua_upvalueindex(2);
  int msg = l_rawgeti_int(lua, buffer_func_table_idx, 1);
  int rt_type = l_rawgeti_int(lua, buffer_func_table_idx, 2);
  int p1_type = l_rawgeti_int(lua, buffer_func_table_idx, 3);
  int p2_type = l_rawgeti_int(lua, buffer_func_table_idx, 4);
  return l_call_scintilla(lua, editor, msg, p1_type, p2_type, rt_type, 2);
}

/**
 * Metatable index for a buffer table.
 * If the key is a Scintilla buffer function, push a closure so it can be called
 * as a function. If the key is a non-indexable buffer property, call Scintilla
 * to get it. If the key is an indexible buffer property, push a table with a
 * metatable to access buffer property indices.
 * @param lua The Lua State.
 */
static int l_buffer_mt_index(lua_State *lua) {
  const char *key = luaL_checkstring(lua, 2);

  lua_getfield(lua, LUA_REGISTRYINDEX, "functions");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // buffer functions
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { msg, rt_type, p1_type, p2_type }
    lua_pushlightuserdata(lua, (GtkWidget *)focused_editor);
    l_insert(lua, -1); // shift buffer functions down
    lua_pushcclosure(lua, l_call_buffer_function, 2);
    return 1;
  } else lua_pop(lua, 1); // non-table

  lua_getfield(lua, LUA_REGISTRYINDEX, "properties");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // buffer properties
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { get_id, set_id, rt_type, p1_type }
    int msg = l_rawgeti_int(lua, -1, 1); // getter
    int rt_type = l_rawgeti_int(lua, -1, 3);
    int p1_type = l_rawgeti_int(lua, -1, 4);
    if (p1_type != tVOID) { // indexible property
      sptr_t doc = SS(focused_editor, SCI_GETDOCPOINTER, 0, 0);
      lua_newtable(lua);
      lua_pushstring(lua, key);
      lua_setfield(lua, -2, "property");
      lua_pushinteger(lua, doc);
      lua_setfield(lua, -2, "doc_pointer");
      l_mt(lua, "_bufferp_mt", l_bufferp_mt_index, l_bufferp_mt_newindex);
      return 1;
    } else return l_call_scintilla(lua, focused_editor, msg, p1_type, tVOID,
                                   rt_type, 2);
  } else lua_pop(lua, 1); // non-table

  lua_rawget(lua, 1);
  return 1;
}

/**
 * Helper function for the buffer property metatable.
 * Throws an error when trying to write to a read-only property or when trying
 * to read a write-only property.
 * @param lua The Lua State.
 * @param n 1 for getter property, 2 for setter.
 * @param prop String property name.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 *   For setter properties, it is 3 because the index is not an argument. For
 *   getter and setter properties, it is 2 because the index is an argument.
 */
static int l_bufferp_mt_(lua_State *lua, int n, const char *prop, int arg) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "properties");
  lua_getfield(lua, -1, prop);
  lua_remove(lua, -2); // buffer properties
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    int msg = l_rawgeti_int(lua, -1, n); // getter (1) or setter (2)
    int rt_type = (n == 1) ? l_rawgeti_int(lua, -1, 3) : tVOID;
    int p1_type = l_rawgeti_int(lua, -1, (n == 1) ? 4 : 3);
    int p2_type = (n == 2) ? l_rawgeti_int(lua, -1, 4) : tVOID;
    if (n == 2 &&
        (p2_type != tVOID || (p2_type == tVOID && p1_type == tSTRING))) {
      int temp = p1_type;
      p1_type = p2_type;
      p2_type = temp;
    }
    luaL_argcheck(lua, msg != 0, arg,
                  (n == 1) ? "write-only property" : "read-only property");
    return l_call_scintilla(lua, focused_editor, msg, p1_type, p2_type, rt_type,
                            arg);
  } else lua_pop(lua, 1); // non-table

  (lua_gettop(lua) > 2) ? lua_rawset(lua, 1) : lua_rawget(lua, 1);
  return 0;
}

static int l_buffer_mt_newindex(lua_State *lua) {
  return l_bufferp_mt_(lua, 2, lua_tostring(lua, 2), 3);
}

static int l_bufferp_mt_index(lua_State *lua) {
  return l_bufferp_mt_(lua, 1, l_rawget_str(lua, 1, "property"), 2);
}

static int l_bufferp_mt_newindex(lua_State *lua) {
  return l_bufferp_mt_(lua, 2, l_rawget_str(lua, 1, "property"), 2);
}

static int l_view_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "doc_pointer"))
    lua_pushinteger(lua, SS(l_checkview(lua, 1), SCI_GETDOCPOINTER, 0, 0));
  else if (streq(key, "size")) {
    GtkWidget *editor = l_checkview(lua, 1);
    if (GTK_IS_PANED(gtk_widget_get_parent(editor))) {
      int pos = gtk_paned_get_position(
                GTK_PANED(gtk_widget_get_parent(editor)));
      lua_pushinteger(lua, pos);
    } else lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_view_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "size")) {
    GtkWidget *pane = gtk_widget_get_parent(l_checkview(lua, 1));
    int size = luaL_checkinteger(lua, 3);
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
  } else lua_rawset(lua, 1);
  return 0;
}

static int l_gui_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    lua_pushstring(lua, gtk_window_get_title(GTK_WINDOW(window)));
  else if (streq(key, "focused_doc_pointer"))
    lua_pushinteger(lua, SS(focused_editor, SCI_GETDOCPOINTER, 0, 0));
  else if (streq(key, "statusbar_text"))
    lua_pushstring(lua, statusbar_text);
  else if (streq(key, "clipboard_text")) {
    char *text = gtk_clipboard_wait_for_text(
                 gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    if (text) {
      lua_pushstring(lua, text);
      g_free(text);
    } else lua_pushstring(lua, "");
  } else if (streq(key, "size")) {
    lua_newtable(lua);
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
    lua_pushinteger(lua, width);
    lua_rawseti(lua, -2, 1);
    lua_pushinteger(lua, height);
    lua_rawseti(lua, -2, 2);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_gui_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(lua, 3));
  else if (streq(key, "focused_doc_pointer") || streq(key, "clipboard_text"))
    luaL_argerror(lua, 3, "read-only property");
  else if (streq(key, "docstatusbar_text"))
    set_statusbar_text(lua_tostring(lua, 3), 1);
  else if (streq(key, "statusbar_text")) {
    statusbar_text = lua_tostring(lua, 3);
    set_statusbar_text(statusbar_text, 0);
  } else if (streq(key, "menubar")) {
    luaL_argcheck(lua, lua_istable(lua, 3), 3, "table of menus expected");
    GtkWidget *menubar = gtk_menu_bar_new();
    lua_pushnil(lua);
    while (lua_next(lua, 3)) {
      luaL_argcheck(lua, lua_isuserdata(lua, -1), 3, "table of menus expected");
      GtkWidget *menu_item = l_togtkwidget(lua, -1);
      gtk_menu_bar_append(GTK_MENU_BAR(menubar), menu_item);
      lua_pop(lua, 1); // value
    }
    set_menubar(menubar);
  } else if (streq(key, "size")) {
    luaL_argcheck(lua, lua_istable(lua, 3) && lua_objlen(lua, 3) == 2, 3,
                  "{ width, height } table expected");
    int width = l_rawgeti_int(lua, 3, 1);
    int height = l_rawgeti_int(lua, 3, 2);
    if (width > 0 && height > 0)
      gtk_window_resize(GTK_WINDOW(window), width, height);
  } else lua_rawset(lua, 1);
  return 0;
}

#define toggled(w) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(w))
static int l_find_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(find_entry)));
  else if (streq(key, "replace_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(replace_entry)));
  else if (streq(key, "match_case"))
    lua_pushboolean(lua, toggled(match_case_opt));
  else if (streq(key, "whole_word"))
    lua_pushboolean(lua, toggled(whole_word_opt));
  else if (streq(key, "lua"))
    lua_pushboolean(lua, toggled(lua_opt));
  else if (streq(key, "in_files"))
    lua_pushboolean(lua, toggled(in_files_opt));
  else
    lua_rawget(lua, 1);
  return 1;
}

#define toggle(w, b) gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(w), b)
static int l_find_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(lua, 3));
  else if (streq(key, "replace_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(lua, 3));
  else if (streq(key, "match_case"))
    toggle(match_case_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "whole_word"))
    toggle(whole_word_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "lua"))
    toggle(lua_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else if (streq(key, "in_files"))
    toggle(in_files_opt, lua_toboolean(lua, -1) ? TRUE : FALSE);
  else
    lua_rawset(lua, 1);
  return 0;
}

static int l_ce_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(command_entry)));
  else
    lua_rawget(lua, 1);
  return 1;
}

static int l_ce_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(lua, 3));
  else
    lua_rawset(lua, 1);
  return 0;
}

// Lua CFunctions. For documentation, consult the LuaDoc.

static int l_cf_buffer_delete(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
  sptr_t doc = l_checkdocpointer(lua, 1);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  if (lua_objlen(lua, -1) > 1)
    l_goto_scintilla_buffer(focused_editor, -1, FALSE);
  else
    new_scintilla_buffer(focused_editor, TRUE, TRUE);
  remove_scintilla_buffer(doc);
  l_emit_event("buffer_deleted", -1);
  return 0;
}

static int l_cf_buffer_new(lua_State *lua) {
  new_scintilla_buffer(focused_editor, TRUE, TRUE);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_rawgeti(lua, -1, lua_objlen(lua, -1));
  return 1;
}

static int l_cf_buffer_text_range(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
  struct Sci_TextRange tr;
  tr.chrg.cpMin = luaL_checkinteger(lua, 2);
  tr.chrg.cpMax = luaL_checkinteger(lua, 3);
  luaL_argcheck(lua, tr.chrg.cpMin <= tr.chrg.cpMax, 3, "start > end");
  int length = tr.chrg.cpMax - tr.chrg.cpMin;
  char *text = malloc(length + 1);
  tr.lpstrText = text;
  SS(focused_editor, SCI_GETTEXTRANGE, 0, (long)(&tr));
  lua_pushlstring(lua, text, length);
  g_free(text);
  return 1;
}

static int l_cf_view_focus(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  // editor might be an old reference; GTK_IS_WIDGET checks for a valid widget
  if (GTK_IS_WIDGET(editor)) gtk_widget_grab_focus(editor);
  return 0;
}

static int l_cf_view_split(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  int vertical = TRUE;
  if (lua_gettop(lua) > 1) vertical = lua_toboolean(lua, 2) == 1;
  split_window(editor, vertical);
  lua_pushvalue(lua, 1); // old view
  lua_getglobal(lua, "view"); // new view
  return 2;
}

static int l_cf_view_unsplit(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  lua_pushboolean(lua, unsplit_window(editor));
  return 1;
}

#define child1(p) gtk_paned_get_child1(GTK_PANED(p))
#define child2(p) gtk_paned_get_child2(GTK_PANED(p))
#define editor_dpi(editor) \
  l_get_docpointer_index(SS(editor, SCI_GETDOCPOINTER, 0, 0))

void l_create_entry(lua_State *lua, GtkWidget *c1, GtkWidget *c2,
                    int vertical) {
  lua_newtable(lua);
  if (GTK_IS_PANED(c1))
    l_create_entry(lua, child1(c1), child2(c1), GTK_IS_HPANED(c1) == 1);
  else
    lua_pushinteger(lua, editor_dpi(c1));
  lua_rawseti(lua, -2, 1);
  if (GTK_IS_PANED(c2))
    l_create_entry(lua, child1(c2), child2(c2), GTK_IS_HPANED(c2) == 1);
  else
    lua_pushinteger(lua, editor_dpi(c2));
  lua_rawseti(lua, -2, 2);
  lua_pushboolean(lua, vertical);
  lua_setfield(lua, -2, "vertical");
  int size = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(c1)));
  lua_pushinteger(lua, size);
  lua_setfield(lua, -2, "size");
}

static int l_cf_gui_get_split_table(lua_State *lua) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (lua_objlen(lua, -1) > 1) {
    GtkWidget *pane = gtk_widget_get_parent(focused_editor);
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_create_entry(lua, child1(pane), child2(pane), GTK_IS_HPANED(pane) == 1);
  } else lua_pushinteger(lua, editor_dpi(focused_editor));
  return 1;
}

static int l_cf_gui_goto_(lua_State *lua, GtkWidget *editor, int buffer) {
  int n = luaL_checkinteger(lua, 1);
  int absolute = (lua_gettop(lua) > 1) ? lua_toboolean(lua, 2) == 1 : TRUE;
  buffer ? l_goto_scintilla_buffer(editor, n, absolute)
         : l_goto_scintilla_window(editor, n, absolute);
  return 0;
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
static int l_cf_view_goto_buffer(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  int switch_focus = editor != focused_editor;
  GtkWidget *orig_focused_editor = focused_editor;
  if (switch_focus) SS(editor, SCI_SETFOCUS, TRUE, 0);
  lua_remove(lua, 1); // view table
  l_cf_gui_goto_(lua, editor, TRUE);
  if (switch_focus) {
    SS(editor, SCI_SETFOCUS, FALSE, 0);
    gtk_widget_grab_focus(orig_focused_editor);
  }
  return 0;
}

static int l_cf_gui_dialog(lua_State *lua) {
  GCDialogType type = gcocoadialog_type(luaL_checkstring(lua, 1));
  int i, j, k, n = lua_gettop(lua) - 1, argc = n;
  for (i = 2; i < n + 2; i++)
    if (lua_type(lua, i) == LUA_TTABLE) argc += lua_objlen(lua, i) - 1;
  const char *argv[argc];
  for (i = 0, j = 2; j < n + 2; j++)
    if (lua_type(lua, j) == LUA_TTABLE) {
      int len = lua_objlen(lua, j);
      for (k = 1; k <= len; k++) {
        lua_rawgeti(lua, j, k);
        argv[i++] = luaL_checkstring(lua, j + 1);
        lua_pop(lua, 1);
      }
    } else argv[i++] = luaL_checkstring(lua, j);
  char *out = gcocoadialog(type, argc, argv);
  lua_pushstring(lua, out);
  free(out);
  return 1;
}

static int l_cf_gui_goto_view(lua_State *lua) {
  return l_cf_gui_goto_(lua, focused_editor, FALSE);
}

static void t_menu_activate(GtkWidget *menu, gpointer id) {
  l_emit_event("menu_clicked", LUA_TNUMBER, GPOINTER_TO_INT(id), -1);
}

static int l_cf_gui_gtkmenu(lua_State *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkWidget *menu = l_create_gtkmenu(lua, G_CALLBACK(t_menu_activate), FALSE);
  lua_pushlightuserdata(lua, (GtkWidget *)menu);
  return 1;
}

static int l_cf_string_iconv(lua_State *lua) {
  size_t text_len = 0, conv_len = 0;
  const char *text = luaL_checklstring(lua, 1, &text_len);
  const char *to = luaL_checkstring(lua, 2);
  const char *from = luaL_checkstring(lua, 3);
  char *converted = g_convert(text, text_len, to, from, NULL, &conv_len, NULL);
  if (converted) {
    lua_pushlstring(lua, converted, conv_len);
    g_free(converted);
  } else luaL_error(lua, "Conversion failed");
  return 1;
}

static int l_cf_quit(lua_State *lua) {
  GdkEventAny event;
  event.type = GDK_DELETE;
  event.window = window->window;
  event.send_event = TRUE;
  gdk_event_put((GdkEvent *)(&event));
  return 0;
}

static int l_cf_reset(lua_State *lua) {
  l_emit_event("reset_before", -1);
  l_init(0, NULL, TRUE);
  lua_pushboolean(lua, TRUE);
  lua_setglobal(lua, "RESETTING");
  l_load_script("init.lua");
  lua_pushnil(lua);
  lua_setglobal(lua, "RESETTING");
  l_set_view_global(focused_editor);
  l_set_buffer_global(focused_editor);
  l_emit_event("reset_after", -1);
  return 0;
}

static int l_cf_find_focus(lua_State *lua) {
  find_toggle_focus();
  return 0;
}

static int l_cf_find_next(lua_State *lua) {
  g_signal_emit_by_name(G_OBJECT(fnext_button), "clicked");
  return 0;
}

static int l_cf_find_prev(lua_State *lua) {
  g_signal_emit_by_name(G_OBJECT(fprev_button), "clicked");
  return 0;
}

static int l_cf_find_replace(lua_State *lua) {
  g_signal_emit_by_name(G_OBJECT(r_button), "clicked");
  return 0;
}

static int l_cf_find_replace_all(lua_State *lua) {
  g_signal_emit_by_name(G_OBJECT(ra_button), "clicked");
  return 0;
}

static int l_cf_ce_focus(lua_State *lua) {
  ce_toggle_focus();
  return 0;
}

static int l_cf_ce_show_completions(lua_State *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkEntryCompletion *completion = gtk_entry_get_completion(
                                   GTK_ENTRY(command_entry));
  GtkListStore *store = GTK_LIST_STORE(
                        gtk_entry_completion_get_model(completion));
  gtk_list_store_clear(store);
  lua_pushnil(lua);
  while (lua_next(lua, 1)) {
    if (lua_type(lua, -1) == LUA_TSTRING) {
      GtkTreeIter iter;
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, 0, lua_tostring(lua, -1), -1);
    } else warn("command_entry.show_completions: non-string value ignored");
    lua_pop(lua, 1); // value
  }
  gtk_entry_completion_complete(completion);
  return 0;
}

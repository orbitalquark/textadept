// Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
  lua_pushstring(l, k); \
  lua_pushnil(l); \
  lua_rawset(l, -3); \
}
#define l_todocpointer(l, i) static_cast<sptr_t>(lua_tonumber(l, i))
#define l_togtkwidget(l, i) reinterpret_cast<GtkWidget*>(lua_touserdata(l, i))
#define l_mt(l, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_cfunc(l, i, "__index"); \
    l_cfunc(l, ni, "__newindex"); \
  } \
  lua_setmetatable(l, -2); \
}

#ifdef MAC
using namespace Scintilla;
#endif

lua_State *lua;
bool closing = false;

static int tVOID = 0, /*tINT = 1,*/ tLENGTH = 2, /*tPOSITION = 3,*/
           /*tCOLOUR = 4,*/ tBOOL = 5, tKEYMOD = 6, tSTRING = 7,
           tSTRINGRESULT = 8;

static void clear_table(lua_State *lua, int index);
static void warn(const char *s) {
  printf("Warning: %s\n", s);
}

static int l_buffer_mt_index(lua_State *lua),
           l_buffer_mt_newindex(lua_State *lua),
           l_bufferp_mt_index(lua_State *lua),
           l_bufferp_mt_newindex(lua_State *lua),
           l_view_mt_index(lua_State *lua),
           l_view_mt_newindex(lua_State *lua),
           l_ta_mt_index(lua_State *lua),
           l_ta_mt_newindex(lua_State *lua),
           l_pm_mt_index(lua_State *lua),
           l_pm_mt_newindex(lua_State *lua),
           l_find_mt_index(lua_State *lua),
           l_find_mt_newindex(lua_State *lua),
           l_ce_mt_index(lua_State *lua),
           l_ce_mt_newindex(lua_State *lua);

static int l_cf_ta_buffer_new(lua_State *lua),
           l_cf_buffer_delete(lua_State *lua),
           l_cf_buffer_text_range(lua_State *lua),
           l_cf_view_focus(lua_State *lua),
           l_cf_view_split(lua_State *lua),
           l_cf_view_unsplit(lua_State *lua),
           l_cf_ta_get_split_table(lua_State *lua),
           l_cf_ta_goto_window(lua_State *lua),
           l_cf_view_goto_buffer(lua_State *lua),
           l_cf_ta_gtkmenu(lua_State *lua),
           l_cf_ta_iconv(lua_State *lua),
           l_cf_ta_reset(lua_State *lua),
           l_cf_ta_quit(lua_State *lua),
           l_cf_pm_focus(lua_State *lua),
           l_cf_pm_clear(lua_State *lua),
           l_cf_pm_activate(lua_State *lua),
           l_cf_pm_add_browser(lua_State *lua),
           l_cf_find_focus(lua_State *lua),
           l_cf_call_find_next(lua_State *lua),
           l_cf_call_find_prev(lua_State *lua),
           l_cf_call_replace(lua_State *lua),
           l_cf_call_replace_all(lua_State *lua),
           l_cf_ce_focus(lua_State *lua);

/**
 * Inits or re-inits the Lua State.
 * Populates the state with global variables and functions, then runs the
 * 'core/init.lua' script.
 * @param argc The number of command line parameters.
 * @param argv The array of command line parameters.
 * @param reinit Flag indicating whether or not to reinitialize the Lua State.
 */
bool l_init(int argc, char **argv, bool reinit) {
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
    l_cfunc(lua, l_cf_pm_focus, "focus");
    l_cfunc(lua, l_cf_pm_clear, "clear");
    l_cfunc(lua, l_cf_pm_activate, "activate");
    l_cfunc(lua, l_cf_pm_add_browser, "add_browser");
    l_mt(lua, "_pm_mt", l_pm_mt_index, l_pm_mt_newindex);
  lua_setfield(lua, -2, "pm");
  lua_newtable(lua);
    l_cfunc(lua, l_cf_find_focus, "focus");
    l_cfunc(lua, l_cf_call_find_next, "call_find_next");
    l_cfunc(lua, l_cf_call_find_prev, "call_find_prev");
    l_cfunc(lua, l_cf_call_replace, "call_replace");
    l_cfunc(lua, l_cf_call_replace_all, "call_replace_all");
    l_mt(lua, "_find_mt", l_find_mt_index, l_find_mt_newindex);
  lua_setfield(lua, -2, "find");
  lua_newtable(lua);
    l_cfunc(lua, l_cf_ce_focus, "focus");
    l_mt(lua, "_ce_mt", l_ce_mt_index, l_ce_mt_newindex);
  lua_setfield(lua, -2, "command_entry");
  l_cfunc(lua, l_cf_ta_buffer_new, "new_buffer");
  l_cfunc(lua, l_cf_ta_goto_window, "goto_view");
  l_cfunc(lua, l_cf_ta_get_split_table, "get_split_table");
  l_cfunc(lua, l_cf_ta_gtkmenu, "gtkmenu");
  l_cfunc(lua, l_cf_ta_iconv, "iconv");
  l_cfunc(lua, l_cf_ta_reset, "reset");
  l_cfunc(lua, l_cf_ta_quit, "quit");
  l_mt(lua, "_textadept_mt", l_ta_mt_index, l_ta_mt_newindex);
  lua_setglobal(lua, "textadept");

  lua_getfield(lua, LUA_REGISTRYINDEX, "arg");
  lua_setglobal(lua, "arg");
  lua_pushstring(lua, textadept_home);
  lua_setglobal(lua, "_HOME");
#if WIN32
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
    lua_getglobal(lua, "textadept");
    l_archive(lua, "constants");
    l_archive(lua, "buffer_functions");
    l_archive(lua, "buffer_properties");
    lua_pop(lua, 1); // textadept
    return true;
  }
  lua_close(lua);
  return false;
}

/**
 * Loads and runs a given Lua script.
 * @param script_file The path of the Lua script relative to textadept_home.
 */
bool l_load_script(const char *script_file) {
  bool retval = true;
  char *script = g_strconcat(textadept_home, "/", script_file, NULL);
  if (luaL_dofile(lua, script) != 0) {
    const char *errmsg = lua_tostring(lua, -1);
    lua_settop(lua, 0);
    GtkWidget *dialog =
      gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL, GTK_MESSAGE_ERROR,
                             GTK_BUTTONS_OK, "%s\n", errmsg);
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    retval = false;
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
 * Adds a Scintilla window to the global 'views' table with a metatable.
 * @param editor The Scintilla window to add.
 */
void l_add_scintilla_window(GtkWidget *editor) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_newtable(lua);
  lua_pushlightuserdata(lua, const_cast<GtkWidget*>(editor));
  lua_setfield(lua, -2, "widget_pointer");
  l_cfunc(lua, l_cf_view_split, "split");
  l_cfunc(lua, l_cf_view_unsplit, "unsplit");
  l_cfunc(lua, l_cf_view_goto_buffer, "goto_buffer");
  l_cfunc(lua, l_cf_view_focus, "focus");
  l_mt(lua, "_view_mt", l_view_mt_index, l_view_mt_newindex);
  l_append(lua, -2); // pops table
  lua_pop(lua, 1); // views
}

/**
 * Removes a Scintilla window from the global 'views' table.
 * @param editor The Scintilla window to remove.
 */
void l_remove_scintilla_window(GtkWidget *editor) {
  lua_newtable(lua);
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    (editor != l_checkview(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
  lua_pop(lua, 1); // views
  lua_setfield(lua, LUA_REGISTRYINDEX, "views");
}

/**
 * Changes focus a Scintilla window in the global 'views' table.
 * @param editor The currently focused Scintilla window.
 * @param n The index of the window in the 'views' table to focus.
 * @param absolute Flag indicating whether or not the index specified in 'views'
 *   is absolute. If false, focuses the window relative to the currently focused
 *   window for the given index.
 *   Throws an error if the view does not exist.
 */
void l_goto_scintilla_window(GtkWidget *editor, int n, bool absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (!absolute) {
    unsigned int idx = 1;
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (editor == l_checkview(lua, -1)) {
        idx = static_cast<int>(lua_tointeger(lua, -2));
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
  gtk_widget_grab_focus(editor);
  if (!closing) l_handle_event("view_switch");
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
  sptr_t doc = l_todocpointer(lua, -1);
  lua_pop(lua, 1); // doc_pointer
  return doc;
}

/**
 * Adds a Scintilla document to the global 'buffers' table with a metatable.
 * @param doc The Scintilla document to add.
 * @return integer index of the new buffer in textadept.buffers.
 */
int l_add_scintilla_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_newtable(lua);
  lua_pushnumber(lua, doc);
  lua_setfield(lua, -2, "doc_pointer");
  l_cfunc(lua, l_cf_buffer_text_range, "text_range");
  l_cfunc(lua, l_cf_buffer_delete, "delete");
  l_mt(lua, "_buffer_mt", l_buffer_mt_index, l_buffer_mt_newindex);
  l_append(lua, -2); // pops table
  int index = lua_objlen(lua, -1);
  lua_pop(lua, 1); // buffers
  return index;
}

/**
 * Removes a Scintilla document from the global 'buffers' table.
 * If any views currently show the document to be removed, change the documents
 * they show first.
 * @param doc The Scintilla buffer to remove.
 */
void l_remove_scintilla_buffer(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    GtkWidget *editor = l_checkview(lua, -1);
    sptr_t that_doc = SS(SCINTILLA(editor), SCI_GETDOCPOINTER);
    if (that_doc == doc) l_goto_scintilla_buffer(editor, -1, false);
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // views
  lua_newtable(lua);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    (doc != l_checkdocpointer(lua, -1)) ? l_append(lua, -4) : lua_pop(lua, 1);
  lua_pop(lua, 1); // buffers
  lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
}

/**
 * Retrieves the index in the global 'buffers' table for a given Scintilla
 * document.
 * @param doc The Scintilla document to get the index of.
 */
unsigned int l_get_docpointer_index(sptr_t doc) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  unsigned int idx = 1;
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    if (doc == l_checkdocpointer(lua, -1)) {
      idx = static_cast<int>(lua_tointeger(lua, -2));
      lua_pop(lua, 2); // key and value
      break;
    } else lua_pop(lua, 1); // value
  lua_pop(lua, 1); // buffers
  return idx;
}

#define l_set_bufferp(k, v) { \
  lua_pushstring(lua, k); \
  lua_pushinteger(lua, v); \
  lua_rawset(lua, -3); \
}
#define l_get_bufferp(k, i) { \
  lua_pushstring(lua, k); \
  lua_rawget(lua, (i < 0) ? i - 1 : i); \
}

/**
 * Changes a Scintilla window's document to one in the global 'buffers' table.
 * Before doing so, it saves the scroll and caret positions in the current
 * Scintilla document. Then when the new document is shown, its scroll and caret
 * positions are restored.
 * @param editor The Scintilla window to change the document of.
 * @param n The index of the document in 'buffers' to focus.
 * @param absolute Flag indicating whether or not the index specified in 'views'
 *   is absolute. If false, focuses the document relative to the currently
 *   focused document for the given index.
 *   Throws an error if the buffer does not exist.
 */
void l_goto_scintilla_buffer(GtkWidget *editor, int n, bool absolute) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  ScintillaObject *sci = SCINTILLA(editor);
  if (!absolute) {
    sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
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
  // Save previous buffer's properties.
  lua_getglobal(lua, "buffer");
  if (lua_istable(lua, -1)) {
    l_set_bufferp("_anchor", SS(sci, SCI_GETANCHOR));
    l_set_bufferp("_current_pos", SS(sci, SCI_GETCURRENTPOS));
    l_set_bufferp("_first_visible_line", SS(sci, SCI_DOCLINEFROMVISIBLE,
                                            SS(sci, SCI_GETFIRSTVISIBLELINE)));
  }
  lua_pop(lua, 1); // buffer
  // Change the view.
  SS(sci, SCI_SETDOCPOINTER, 0, doc);
  l_set_buffer_global(sci);
  // Restore this buffer's properties.
  lua_getglobal(lua, "buffer");
  l_get_bufferp("_anchor", -1);
  l_get_bufferp("_current_pos", -2);
  SS(sci, SCI_SETSEL, lua_tointeger(lua, -2), lua_tointeger(lua, -1));
  l_get_bufferp("_first_visible_line", -3);
  SS(sci, SCI_LINESCROLL, 0,
     SS(sci, SCI_VISIBLEFROMDOCLINE, lua_tointeger(lua, -1)) -
       SS(sci, SCI_GETFIRSTVISIBLELINE));
  lua_pop(lua, 4); // _anchor, _current_pos, _first_visible_line, and buffer
  if (!closing) l_handle_event("buffer_switch");
  lua_pop(lua, 2); // buffer table and buffers
}

/**
 * Sets the global 'buffer' variable to be the document in the specified
 * Scintilla object.
 * @param sci The Scintilla object whose buffer is to be 'buffer'.
 */
void l_set_buffer_global(ScintillaObject *sci) {
  sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
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
  closing = true;
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
 * Returns whether or not the value of the key of the given table in the global
 * 'textadept' table is a function.
 * @param lua The Lua State.
 * @param table The table in 'textadept' to check for key in.
 * @param key String key to check for in table.
 */
bool l_ista2function(const char *table, const char *key) {
  lua_getglobal(lua, "textadept");
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, table);
    lua_remove(lua, -2); // textadept
    if (lua_istable(lua, -1)) {
      lua_getfield(lua, -1, key);
      lua_remove(lua, -2); // table
      if (lua_isfunction(lua, -1)) return true;
      lua_pop(lua, 1); // non-function
    } else lua_pop(lua, 1); // non-table
  } else lua_pop(lua, 1); // textadept
  return false;
}

/**
 * Calls a Lua function with a number of arguments and expected return values.
 * The last argument is at the stack top, and each argument in reverse order is
 * one element lower on the stack with the Lua function being under the first
 * argument.
 * @param nargs The number of arguments to pass to the Lua function to call.
 * @param retn Optional number of expected return values. Defaults to 0.
 * @param keep_return Optional flag indicating whether or not to keep the return
 *   values at the top of the stack. If false, discards the return values.
 *   Defaults to false.
 */
bool l_call_function(int nargs, int retn=0, bool keep_return=false) {
  int ret = lua_pcall(lua, nargs, retn, 0);
  if (ret == 0) {
    bool result = (retn > 0) ? lua_toboolean(lua, -1) == 1 : true;
    if (retn > 0 && !keep_return) lua_pop(lua, retn); // retn
    return result;
  } else l_handle_error(NULL);
  return false;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns an int.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param n The index in the table to rawget.
 */
static int l_rawgeti_int(lua_State *lua, int index, int n) {
  lua_rawgeti(lua, index, n);
  int ret = static_cast<int>(lua_tointeger(lua, -1));
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
GtkWidget *l_create_gtkmenu(lua_State *lua, GCallback callback, bool submenu) {
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
      bool is_submenu = !lua_isnil(lua, -1);
      lua_pop(lua, 1); // title
      if (is_submenu)
        gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                              l_create_gtkmenu(lua, callback, true));
      else
        if (lua_objlen(lua, -1) == 2) {
          lua_rawgeti(lua, -1, 1);
          lua_rawgeti(lua, -2, 2);
          label = lua_tostring(lua, -2);
          int menu_id = static_cast<int>(lua_tonumber(lua, -1));
          lua_pop(lua, 2); // label and id
          if (label) {
            if (g_str_has_prefix(label, "gtk-"))
              menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
            else if (streq(label, "separator"))
              menu_item = gtk_separator_menu_item_new();
            else
              menu_item = gtk_menu_item_new_with_mnemonic(label);
            g_signal_connect(menu_item, "activate", callback,
                             reinterpret_cast<gpointer>(menu_id));
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
static long l_toscintillaparam(lua_State *lua, int type, int &arg_idx) {
  if (type == tSTRING)
    return reinterpret_cast<long>(lua_tostring(lua, arg_idx++));
  else if (type == tBOOL)
    return lua_toboolean(lua, arg_idx++);
  else if (type == tKEYMOD)
    return (static_cast<int>(luaL_checkinteger(lua, arg_idx++)) & 0xFFFF) |
           ((static_cast<int>(luaL_checkinteger(lua, arg_idx++)) &
           (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  else if (type > tVOID && type < tBOOL)
    return luaL_checklong(lua, arg_idx++);
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
  ScintillaObject *sci = SCINTILLA(focused_editor);
  sptr_t cur_doc = SS(sci, SCI_GETDOCPOINTER);
  luaL_argcheck(lua, cur_doc == l_checkdocpointer(lua, narg), 1,
                "the indexed Buffer is not the focused one");
}

// Notification/event handlers

/**
 * Handles a Lua error.
 * The main error message is at the top of the Lua stack.
 * @param lua The Lua State.
 * @param extramsg An additional error message to display.
 */
void l_handle_error(const char *extramsg) {
  if (focused_editor && l_ista2function("events", "error")) {
    l_insert(lua, -1); // shift error message down
    if (extramsg) lua_pushstring(lua, extramsg);
    l_call_function(extramsg ? 2 : 1);
  } else {
    printf("Lua Error: %s\n", lua_tostring(lua, -1));
    if (extramsg) printf("%s\n", extramsg);
  }
  lua_settop(lua, 0);
}

/**
 * Handles a Textadept event.
 * @param s String event name.
 * @param arg Optional string argument.
 */
bool l_handle_event(const char *s, const char *arg) {
  if (!l_ista2function("events", s)) return false;
  if (arg) lua_pushstring(lua, arg);
  return l_call_function(arg ? 1 : 0, 1);
}

/**
 * Handles a Textadept keypress.
 * @param keyval The key value of the key pressed.
 * @param shift Flag indicating whether or not the shift modifier was held.
 * @param control Flag indicating whether or not the control modifier was held.
 * @param alt Flag indicating whether or not the alt modifier was held.
 */
bool l_handle_keypress(int keyval, bool shift, bool control, bool alt) {
  if (!l_ista2function("events", "keypress")) return false;
  lua_pushinteger(lua, keyval);
  lua_pushboolean(lua, shift);
  lua_pushboolean(lua, control);
  lua_pushboolean(lua, alt);
  return l_call_function(4, 1);
}

#define l_pushscninteger(i, n) { \
  lua_pushinteger(lua, i); \
  lua_setfield(lua, idx, n); \
}
#define l_pushscnstring(s, n) { \
  lua_pushstring(lua, s); \
  lua_setfield(lua, idx, n); \
}

/**
 * Handles a Scintilla notification.
 * @param n The Scintilla notification struct.
 */
void l_handle_scnnotification(SCNotification *n) {
  if (!l_ista2function("events", "notification")) return;
  lua_newtable(lua);
  int idx = lua_gettop(lua);
  l_pushscninteger(n->nmhdr.code, "code");
  l_pushscninteger(n->position, "position");
  l_pushscninteger(n->ch, "ch");
  l_pushscninteger(n->modifiers, "modifiers");
  l_pushscninteger(n->modificationType, "modification_type");
  l_pushscnstring(n->text, "text");
  l_pushscninteger(n->length, "length");
  l_pushscninteger(n->linesAdded, "lines_added");
  l_pushscninteger(n->message, "message");
  if (n->nmhdr.code == SCN_MACRORECORD) {
    lua_getfield(lua, LUA_REGISTRYINDEX, "buffer_functions");
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (l_rawgeti_int(lua, -1, 1) == n->message) {
        if (l_rawgeti_int(lua, -1, 3) == tSTRING) {
          l_pushscnstring(reinterpret_cast<char*>(n->wParam), "wParam");
        } else l_pushscninteger(static_cast<int>(n->wParam), "wParam");
        if (l_rawgeti_int(lua, -1, 4) == tSTRING) {
          l_pushscnstring(reinterpret_cast<char*>(n->lParam), "lParam");
        } else l_pushscninteger(static_cast<int>(n->lParam), "lParam");
        lua_pop(lua, 2); // key and value
        break;
      } else lua_pop(lua, 1); // value
    lua_pop(lua, 1); // ta_buffer_functions
  } else {
    l_pushscninteger(static_cast<int>(n->wParam), "wParam");
    l_pushscninteger(static_cast<int>(n->lParam), "lParam");
  }
  l_pushscninteger(n->line, "line");
  l_pushscninteger(n->foldLevelNow, "fold_level_now");
  l_pushscninteger(n->foldLevelPrev, "fold_level_prev");
  l_pushscninteger(n->margin, "margin");
  l_pushscninteger(n->x, "x");
  l_pushscninteger(n->y, "y");
  l_call_function(1);
}

/**
 * Requests and pops up a context menu for the Scintilla view.
 * @param event The mouse button event.
 */
void l_ta_popup_context_menu(GdkEventButton *event) {
  lua_getglobal(lua, "textadept");
  if (lua_istable(lua, -1)) {
    lua_getfield(lua, -1, "context_menu");
    if (lua_isuserdata(lua, -1)) {
      GtkWidget *menu = l_togtkwidget(lua, -1);
      gtk_widget_show_all(menu);
      gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                     event ? event->button : 0,
                     gdk_event_get_time(reinterpret_cast<GdkEvent*>(event)));
    } else if (!lua_isnil(lua, -1))
      warn("textadept.context_menu: gtkmenu expected");
    lua_pop(lua, 1); // textadept.context_menu
  } else lua_pop(lua, 1);
}

// Project Manager

/**
 * Creates and pushes a Lua table of parent nodes for the given Project Manager
 * treeview path.
 * The first table item is the PM Entry text, the next items are parents of the
 * given node in descending order, and the last item is the given node itself.
 * @param store The GtkTreeStore of the PM view.
 * @param path The GtkTreePath of the node. If NULL, only the PM Entry text is
 *   contained in the resulting table.
 */
void l_pushpathtable(GtkTreeStore *store, GtkTreePath *path) {
  lua_newtable(lua);
  lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(pm_entry)));
  lua_rawseti(lua, -2, 1);
  if (!path) return;
  GtkTreeIter iter;
  while (gtk_tree_path_get_depth(path) > 0) {
    char *item = 0;
    gtk_tree_model_get_iter(GTK_TREE_MODEL(store), &iter, path);
    gtk_tree_model_get(GTK_TREE_MODEL(store), &iter, 1, &item, -1);
    lua_pushstring(lua, item);
    lua_rawseti(lua, -2, gtk_tree_path_get_depth(path) + 1);
    g_free(item);
    gtk_tree_path_up(path);
  }
}

/**
 * Requests and adds contents to the Project Manager view.
 * @param store The GtkTreeStore of the PM view.
 * @param initial_iter An initial GtkTreeIter. If NULL, contents will be added
 *   to the treeview root. Otherwise they will be added to this parent node.
 */
void l_pm_view_fill(GtkTreeStore *store, GtkTreeIter *initial_iter) {
  if (!l_ista2function("pm", "get_contents_for")) return;
  if (initial_iter) {
    GtkTreePath *path =
      gtk_tree_model_get_path(GTK_TREE_MODEL(store), initial_iter);
    l_pushpathtable(store, path);
    gtk_tree_path_free(path);
  } else l_pushpathtable(store, NULL);
  lua_pushboolean(lua, initial_iter != NULL);
  l_call_function(2, 1, true);
  if (!lua_istable(lua, -1)) {
    if (!lua_isnil(lua, -1)) warn("pm.get_contents_for: table expected");
    lua_pop(lua, 1); // non-table return
    return;
  }

  if (!initial_iter) gtk_tree_store_clear(store);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_istable(lua, -1) && lua_type(lua, -2) == LUA_TSTRING) {
      GtkTreeIter iter, child;
      gtk_tree_store_append(store, &iter, initial_iter);
      gtk_tree_store_set(store, &iter, 1, lua_tostring(lua, -2), -1);
      lua_getfield(lua, -1, "parent");
      if (lua_toboolean(lua, -1)) {
        gtk_tree_store_append(store, &child, &iter);
        gtk_tree_store_set(store, &child, 1, "\0dummy", -1);
      }
      lua_pop(lua, 1); // parent
      lua_getfield(lua, -1, "pixbuf");
      if (lua_isstring(lua, -1))
        gtk_tree_store_set(store, &iter, 0, lua_tostring(lua, -1), -1);
      else if (!lua_isnil(lua, -1))
        warn("pm.fill: non-string pixbuf key ignored");
      lua_pop(lua, 1); // pixbuf
      lua_getfield(lua, -1, "text");
      gtk_tree_store_set(store, &iter, 2, lua_isstring(lua, -1) ?
                         lua_tostring(lua, -1) : lua_tostring(lua, -3), -1);
      lua_pop(lua, 1); // display text
    } else warn("pm.fill: string id key must have table value");
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // returned table

  l_handle_event("pm_view_filled");
}

/**
 * Requests and pops up a context menu for a selected Project Manager item.
 * @param store The GtkTreeStore of the PM view.
 * @param path The GtkTreePath of the item.
 * @param event The mouse button event.
 * @param callback The GCallback associated with each menu item.
 */
void l_pm_popup_context_menu(GtkTreeStore *store, GtkTreePath *path,
                             GdkEventButton *event, GCallback callback) {
  if (!l_ista2function("pm", "get_context_menu")) return;
  l_pushpathtable(store, path);
  l_call_function(1, 1, true);
  if (lua_istable(lua, -1)) {
    GtkWidget *menu = l_create_gtkmenu(lua, callback, false);
    gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                   event ? event->button : 0,
                   gdk_event_get_time(reinterpret_cast<GdkEvent*>(event)));
  } else warn("pm.get_context_menu: table expected");
  lua_pop(lua, 1); // returned value
}

/**
 * Performs an action for the selected Project Manager item.
 * @param store The GtkTreeStore of the PM view.
 * @param path The GtkTreePath of the item.
 */
void l_pm_perform_action(GtkTreeStore *store, GtkTreePath *path) {
  if (!l_ista2function("pm", "perform_action")) return;
  l_pushpathtable(store, path);
  l_call_function(1);
}

/**
 * Performs a selected menu action from a Project Manager item's context menu.
 * @param store The GtkTreeStore of the PM view.
 * @param path The GtkTreePath of the item.
 * @param id The numeric ID for the menu item.
 */
void l_pm_perform_menu_action(GtkTreeStore *store, GtkTreePath *path, int id) {
  if (!l_ista2function("pm", "perform_menu_action")) return;
  lua_pushnumber(lua, id);
  l_pushpathtable(store, path);
  l_call_function(2);
}

// Find/Replace

/**
 * Finds text in the current document.
 * @param ftext The text to find.
 * @param next Flag indicating whether or not to find next. If false, finds
 *   previous matches.
 */
void l_find(const char *ftext, bool next) {
  if (!l_ista2function("find", "find")) return;
  lua_pushstring(lua, ftext);
  lua_pushboolean(lua, next);
  l_call_function(2);
}

/**
 * Replaces text in the current document.
 * @param rtext The text to replace the found text with.
 */
void l_find_replace(const char *rtext) {
  if (!l_ista2function("find", "replace")) return;
  lua_pushstring(lua, rtext);
  l_call_function(1);
}

/**
 * Replaces all found text in the current document.
 * @param ftext The text to find.
 * @param rtext The text to replace the found text with.
 */
void l_find_replace_all(const char *ftext, const char *rtext) {
  if (!l_ista2function("find", "replace_all")) return;
  lua_pushstring(lua, ftext);
  lua_pushstring(lua, rtext);
  l_call_function(2);
}

// Command Entry

/**
 * Executes a given command string as Lua code.
 * @param command Lua code to execute.
 */
void l_ce_command(const char *command) {
  int top = lua_gettop(lua);
  if (luaL_dostring(lua, command) == 0) {
    l_handle_event("update_ui");
    lua_settop(lua, top);
  } else l_handle_error("Error executing command");
}

/**
 * Requests and adds completions for the Command Entry Completion.
 * @param store The GtkListStore to populate.
 */
void l_cec_fill(GtkListStore *store) {
  if (!l_ista2function("command_entry", "get_completions_for")) return;
  lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(command_entry)));
  l_call_function(1, 1, true);
  if (!lua_istable(lua, -1)) {
    if (!lua_isnil(lua, -1)) warn("ce.get_completions_for: table expected");
    lua_pop(lua, 1); // non-table return
    return;
  }

  gtk_list_store_clear(store);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_type(lua, -1) == LUA_TSTRING) {
      GtkTreeIter iter;
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, 0, lua_tostring(lua, -1), -1);
    } else warn("ce.get_completions_for: non-string value ignored");
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // returned table
}

// Lua functions (stack maintenence is unnecessary)

/**
 * Calls Scintilla with appropriate parameters and returs appropriate values.
 * @param lua The Lua State.
 * @param sci The Scintilla object to call.
 * @param msg The integer message index to call Scintilla with.
 * @param p1_type The Lua type of p1, the Scintilla w parameter.
 * @param p2_type The Lua type of p2, the Scintilla l parameter.
 * @param rt_type The Lua type of the Scintilla return parameter.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 */
static int l_call_scintilla(lua_State *lua, ScintillaObject *sci, int msg,
                    int p1_type, int p2_type, int rt_type, int arg) {
  if (!sci) luaL_error(lua, "Scintilla object not initialized.");
  long params[2] = {0, 0};
  int params_needed = 2;
  bool string_return = false;
  int len = 0;
  char *return_string = 0;

  // Set the w and l parameters appropriately for Scintilla.
  if (p1_type == tLENGTH && p2_type == tSTRING) {
    params[0] = static_cast<long>(lua_strlen(lua, arg));
    params[1] = reinterpret_cast<long>(lua_tostring(lua, arg));
    params_needed = 0;
  } else if (p2_type == tSTRINGRESULT) {
    string_return = true;
    params_needed = (p1_type == tLENGTH) ? 0 : 1;
  }
  if (params_needed > 0) params[0] = l_toscintillaparam(lua, p1_type, arg);
  if (params_needed > 1) params[1] = l_toscintillaparam(lua, p2_type, arg);
  if (string_return) { // if a string return, create a buffer for it
    len = SS(sci, msg, params[0], 0);
    if (p1_type == tLENGTH) params[0] = len;
    return_string = reinterpret_cast<char*>(malloc(sizeof(char) * len + 1));
    return_string[len] = '\0';
    if (msg == SCI_GETTEXT || msg == SCI_GETSELTEXT || msg == SCI_GETCURLINE)
      len--; // Scintilla appends '\0' for these messages; compensate
    params[1] = reinterpret_cast<long>(return_string);
  }

  // Send the message to Scintilla and return the appropriate values.
  int result = SS(sci, msg, params[0], params[1]);
  arg = lua_gettop(lua);
  if (string_return) lua_pushlstring(lua, return_string, len);
  if (rt_type == tBOOL) lua_pushboolean(lua, result);
  if (rt_type > tVOID && rt_type < tBOOL) lua_pushnumber(lua, result);
  g_free(return_string);
  return lua_gettop(lua) - arg;
}

/**
 * Calls a Scintilla buffer function with upvalues from a closure.
 * @param lua The Lua State.
 * @see l_buffer_mt_index
 */
static int l_call_buffer_function(lua_State *lua) {
  int sci_idx = lua_upvalueindex(1); // closure from __index
  ScintillaObject *sci =
    reinterpret_cast<ScintillaObject*>(lua_touserdata(lua, sci_idx));
  int buffer_func_table_idx = lua_upvalueindex(2);
  int msg = l_rawgeti_int(lua, buffer_func_table_idx, 1);
  int rt_type = l_rawgeti_int(lua, buffer_func_table_idx, 2);
  int p1_type = l_rawgeti_int(lua, buffer_func_table_idx, 3);
  int p2_type = l_rawgeti_int(lua, buffer_func_table_idx, 4);
  return l_call_scintilla(lua, sci, msg, p1_type, p2_type, rt_type, 2);
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
  ScintillaObject *sci = SCINTILLA(focused_editor);
  const char *key = luaL_checkstring(lua, 2);

  lua_getfield(lua, LUA_REGISTRYINDEX, "buffer_functions");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // ta_buffer_functions
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { msg, rt_type, p1_type, p2_type }
    lua_pushlightuserdata(lua, const_cast<ScintillaObject*>(sci));
    l_insert(lua, -1); // shift buffer_functions down
    lua_pushcclosure(lua, l_call_buffer_function, 2);
    return 1;
  } else lua_pop(lua, 1); // non-table

  lua_getfield(lua, LUA_REGISTRYINDEX, "buffer_properties");
  lua_getfield(lua, -1, key);
  lua_remove(lua, -2); // ta_buffer_properties
  if (lua_istable(lua, -1)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { get_id, set_id, rt_type, p1_type }
    int msg = l_rawgeti_int(lua, -1, 1); // getter
    int rt_type = l_rawgeti_int(lua, -1, 3);
    int p1_type = l_rawgeti_int(lua, -1, 4);
    if (p1_type != tVOID) { // indexible property
      sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
      lua_newtable(lua);
      lua_pushstring(lua, key);
      lua_setfield(lua, -2, "property");
      lua_pushnumber(lua, doc);
      lua_setfield(lua, -2, "doc_pointer");
      l_mt(lua, "_bufferp_mt", l_bufferp_mt_index, l_bufferp_mt_newindex);
      return 1;
    } else return l_call_scintilla(lua, sci, msg, p1_type, tVOID, rt_type, 2);
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
  ScintillaObject *sci = SCINTILLA(focused_editor);

  lua_getfield(lua, LUA_REGISTRYINDEX, "buffer_properties");
  lua_getfield(lua, -1, prop);
  lua_remove(lua, -2); // ta_buffer_properties
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
    return l_call_scintilla(lua, sci, msg, p1_type, p2_type, rt_type, arg);
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
    lua_pushnumber(lua, SS(SCINTILLA(l_checkview(lua, 1)), SCI_GETDOCPOINTER));
  else if (streq(key, "size")) {
    GtkWidget *editor = l_checkview(lua, 1);
    if (GTK_IS_PANED(gtk_widget_get_parent(editor))) {
      int pos =
        gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(editor)));
      lua_pushnumber(lua, pos);
    } else lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_view_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "size")) {
    GtkWidget *pane = gtk_widget_get_parent(l_checkview(lua, 1));
    int size = static_cast<int>(lua_tonumber(lua, 3));
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
  } else lua_rawset(lua, 1);
  return 0;
}

static int l_ta_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "buffers") || streq(key, "views") || streq(key, "constants") ||
      streq(key, "buffer_functions") || streq(key, "buffer_properties"))
    lua_getfield(lua, LUA_REGISTRYINDEX, key);
  else if (streq(key, "title"))
    lua_pushstring(lua, gtk_window_get_title(GTK_WINDOW(window)));
  else if (streq(key, "focused_doc_pointer"))
    lua_pushnumber(lua, SS(SCINTILLA(focused_editor), SCI_GETDOCPOINTER));
  else if (streq(key, "clipboard_text")) {
    char *text =
      gtk_clipboard_wait_for_text(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    if (text) {
      lua_pushstring(lua, text);
      g_free(text);
    } else lua_pushstring(lua, "");
  } else if (streq(key, "size")) {
    lua_newtable(lua);
    int width, height;
    gtk_window_get_size(GTK_WINDOW(window), &width, &height);
    lua_pushnumber(lua, width);
    lua_rawseti(lua, -2, 1);
    lua_pushnumber(lua, height);
    lua_rawseti(lua, -2, 2);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_ta_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "buffers") || streq(key, "views") || streq(key, "constants") ||
      streq(key, "buffer_functions") || streq(key, "buffer_properties"))
    luaL_argerror(lua, 3, "read-only property");
  else if (streq(key, "title"))
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(lua, 3));
  else if (streq(key, "statusbar_text"))
    set_statusbar_text(lua_tostring(lua, 3), false);
  else if (streq(key, "docstatusbar_text"))
    set_statusbar_text(lua_tostring(lua, 3), true);
  else if (streq(key, "focused_doc_pointer") || streq(key, "clipboard_text"))
    luaL_argerror(lua, 3, "read-only property");
  else if (streq(key, "menubar")) {
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
    lua_rawgeti(lua, 3, 1);
    lua_rawgeti(lua, 3, 2);
    int width = static_cast<int>(lua_tonumber(lua, -2));
    int height = static_cast<int>(lua_tonumber(lua, -1));
    lua_pop(lua, 2); // width, height
    if (width > 0 && height > 0)
      gtk_window_resize(GTK_WINDOW(window), width, height);
  } else lua_rawset(lua, 1);
  return 0;
}

static int l_pm_mt_index(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(pm_entry)));
  else if (streq(key, "width")) {
    int pos =
      gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(pm_container)));
    lua_pushnumber(lua, pos);
  } else if (streq(key, "cursor")) {
    GtkTreePath *path = NULL;
    gtk_tree_view_get_cursor(GTK_TREE_VIEW(pm_view), &path, NULL);
    if (path) {
      lua_pushstring(lua, gtk_tree_path_to_string(path));
      gtk_tree_path_free(path);
    } else lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

static int l_pm_mt_newindex(lua_State *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    gtk_entry_set_text(GTK_ENTRY(pm_entry), lua_tostring(lua, 3));
  else if (streq(key, "width"))
    gtk_paned_set_position(GTK_PANED(gtk_widget_get_parent(pm_container)),
                           luaL_checkinteger(lua, 3));
  else if (streq(key, "cursor")) {
    GtkTreePath *path = gtk_tree_path_new_from_string(lua_tostring(lua, 3));
    luaL_argcheck(lua, path, 3, "bad path");
    int *indices = gtk_tree_path_get_indices(path);
    GtkTreePath *ipath = gtk_tree_path_new_from_indices(indices[0], -1);
    for (int i = 1; i < gtk_tree_path_get_depth(path); i++)
      if (gtk_tree_view_row_expanded(GTK_TREE_VIEW(pm_view), ipath) ||
          gtk_tree_view_expand_row(GTK_TREE_VIEW(pm_view), ipath, FALSE))
        gtk_tree_path_append_index(ipath, indices[i]);
      else
        break;
    GtkTreeViewColumn *col =
      gtk_tree_view_get_column(GTK_TREE_VIEW(pm_view), 0);
    gtk_tree_view_set_cursor(GTK_TREE_VIEW(pm_view), ipath, col, FALSE);
    gtk_tree_path_free(ipath);
    gtk_tree_path_free(path);
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

static int l_cf_ta_buffer_new(lua_State *lua) {
  new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_rawgeti(lua, -1, lua_objlen(lua, -1));
  return 1;
}

static int l_cf_buffer_delete(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
  sptr_t doc = l_checkdocpointer(lua, 1);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  if (lua_objlen(lua, -1) > 1)
    l_goto_scintilla_buffer(focused_editor, -1, false);
  else
    new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  remove_scintilla_buffer(doc);
  l_handle_event("buffer_deleted");
  return 0;
}

static int l_cf_buffer_text_range(lua_State *lua) {
  l_check_focused_buffer(lua, 1);
#ifndef MAC
  TextRange tr;
#else
  Scintilla::TextRange tr;
#endif
  tr.chrg.cpMin = luaL_checkinteger(lua, 2);
  tr.chrg.cpMax = luaL_checkinteger(lua, 3);
  int length = tr.chrg.cpMax - tr.chrg.cpMin;
  char *text = reinterpret_cast<char*>(malloc(sizeof(char) * length + 1));
  tr.lpstrText = text;
  SS(SCINTILLA(focused_editor), SCI_GETTEXTRANGE, 0,
     reinterpret_cast<long>(&tr));
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
  bool vertical = true;
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
#define editor_dpi(e) \
  l_get_docpointer_index(SS(SCINTILLA(e), SCI_GETDOCPOINTER))

void l_create_entry(lua_State *lua, GtkWidget *c1, GtkWidget *c2,
                    bool vertical) {
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

static int l_cf_ta_get_split_table(lua_State *lua) {
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  if (lua_objlen(lua, -1) > 1) {
    GtkWidget *pane = gtk_widget_get_parent(focused_editor);
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_create_entry(lua, child1(pane), child2(pane), GTK_IS_HPANED(pane) == 1);
  } else lua_pushinteger(lua, editor_dpi(focused_editor));
  return 1;
}

static int l_cf_ta_goto_(lua_State *lua, GtkWidget *editor, bool buffer) {
  int n = static_cast<int>(luaL_checkinteger(lua, 1));
  bool absolute = (lua_gettop(lua) > 1) ? lua_toboolean(lua, 2) == 1 : true;
  buffer ? l_goto_scintilla_buffer(editor, n, absolute)
         : l_goto_scintilla_window(editor, n, absolute);
  return 0;
}

static int l_cf_ta_goto_window(lua_State *lua) {
  return l_cf_ta_goto_(lua, focused_editor, false);
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
static int l_cf_view_goto_buffer(lua_State *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  bool switch_focus = editor != focused_editor;
  GtkWidget *orig_focused_editor = focused_editor;
  if (switch_focus) SS(SCINTILLA(editor), SCI_SETFOCUS, true);
  lua_remove(lua, 1); // view table
  l_cf_ta_goto_(lua, editor, true);
  if (switch_focus) {
    SS(SCINTILLA(editor), SCI_SETFOCUS, false);
    gtk_widget_grab_focus(orig_focused_editor);
  }
  return 0;
}

static void t_menu_activate(GtkWidget *, gpointer id) {
  int menu_id = GPOINTER_TO_INT(id);
  char *menu_id_str = static_cast<char*>(malloc(sizeof(char) * 12));
  sprintf(menu_id_str, "%i", menu_id);
  l_handle_event("menu_clicked", menu_id_str);
  g_free(menu_id_str);
}

static int l_cf_ta_gtkmenu(lua_State *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkWidget *menu = l_create_gtkmenu(lua, G_CALLBACK(t_menu_activate), false);
  lua_pushlightuserdata(lua, const_cast<GtkWidget*>(menu));
  return 1;
}

static int l_cf_ta_iconv(lua_State *lua) {
  size_t text_len = 0, conv_len = 0;
  const char *text = luaL_checklstring(lua, 1, &text_len);
  const char *to = luaL_checkstring(lua, 2);
  const char *from = luaL_checkstring(lua, 3);
  char *converted = g_convert(text, text_len, to, from, NULL, &conv_len, NULL);
  if (converted) {
    lua_pushlstring(lua, const_cast<char*>(converted), conv_len);
    g_free(converted);
  } else luaL_error(lua, "Conversion failed");
  return 1;
}

static int l_cf_ta_reset(lua_State *lua) {
  l_handle_event("resetting");
  l_init(0, NULL, true);
  lua_pushboolean(lua, true);
  lua_setglobal(lua, "RESETTING");
  l_load_script("init.lua");
  lua_pushnil(lua);
  lua_setglobal(lua, "RESETTING");
  l_set_view_global(focused_editor);
  l_set_buffer_global(SCINTILLA(focused_editor));
  return 0;
}

static int l_cf_ta_quit(lua_State *) {
  GdkEventAny event;
  event.type = GDK_DELETE;
  event.window = window->window;
  event.send_event = TRUE;
  gdk_event_put(reinterpret_cast<GdkEvent*>(&event));
  return 0;
}

static int l_cf_pm_focus(lua_State *) {
  pm_toggle_focus();
  return 0;
}

static int l_cf_pm_clear(lua_State *) {
  gtk_tree_store_clear(
    GTK_TREE_STORE(gtk_tree_view_get_model(GTK_TREE_VIEW(pm_view))));
  return 0;
}

static int l_cf_pm_activate(lua_State *) {
  g_signal_emit_by_name(G_OBJECT(pm_entry), "activate");
  return 0;
}

static int l_cf_pm_add_browser(lua_State *lua) {
  GtkWidget *pm_combo = gtk_widget_get_parent(pm_entry);
  gtk_combo_box_append_text(GTK_COMBO_BOX(pm_combo), lua_tostring(lua, -1));
  return 0;
}

static int l_cf_find_focus(lua_State *) {
  find_toggle_focus();
  return 0;
}

static int l_cf_call_find_next(lua_State *) {
  g_signal_emit_by_name(G_OBJECT(fnext_button), "clicked");
  return 0;
}

static int l_cf_call_find_prev(lua_State *) {
  g_signal_emit_by_name(G_OBJECT(fprev_button), "clicked");
  return 0;
}

static int l_cf_call_replace(lua_State *) {
  g_signal_emit_by_name(G_OBJECT(r_button), "clicked");
  return 0;
}

static int l_cf_call_replace_all(lua_State *) {
  g_signal_emit_by_name(G_OBJECT(ra_button), "clicked");
  return 0;
}

static int l_cf_ce_focus(lua_State *) {
  ce_toggle_focus();
  return 0;
}

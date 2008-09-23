// Copyright 2007-2008 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

#define LS lua_State
#define LF static int
#define streq(s1, s2) strcmp(s1, s2) == 0
#define l_insert(l, i) lua_insert(l, i < 0 ? lua_gettop(l) + i : i)
#define l_append(l, i) lua_rawseti(l, i, lua_objlen(l, i) + 1)
#define l_cfunc(l, f, k) { lua_pushcfunction(l, f); lua_setfield(l, -2, k); }
#define l_todocpointer(l, i) static_cast<sptr_t>(lua_tonumber(l, i))
#define l_togtkwidget(l, i) reinterpret_cast<GtkWidget*>(lua_touserdata(l, i))
#define l_mt(l, k, i, ni) { \
  if (luaL_newmetatable(l, k)) { \
    l_cfunc(l, i, "__index"); \
    l_cfunc(l, ni, "__newindex"); \
  } lua_setmetatable(l, -2); }

LS *lua;
bool closing = false;

static int // parameter/return types
  tVOID = 0, /*tINT = 1,*/ tLENGTH = 2, /*tPOSITION = 3,*/ /*tCOLOUR = 4,*/
  tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;

static void clear_table(LS *lua, int index);
static void warn(const char *s) { printf("Warning: %s\n", s); }

LF l_buffer_mt_index(LS *lua), l_buffer_mt_newindex(LS *lua),
   l_bufferp_mt_index(LS *lua), l_bufferp_mt_newindex(LS *lua),
   l_view_mt_index(LS *lua), l_view_mt_newindex(LS *lua),
   l_ta_mt_index(LS *lua), l_ta_mt_newindex(LS *lua),
   l_pm_mt_index(LS *lua), l_pm_mt_newindex(LS *lua),
   l_find_mt_index(LS *lua), l_find_mt_newindex(LS *lua),
   l_ce_mt_index(LS *lua), l_ce_mt_newindex(LS *lua);

LF l_cf_ta_buffer_new(LS *lua),
   l_cf_buffer_delete(LS *lua),
   l_cf_buffer_find(LS *lua),
   l_cf_buffer_text_range(LS *lua),
   l_cf_view_focus(LS *lua),
   l_cf_view_split(LS *lua), l_cf_view_unsplit(LS *lua),
   l_cf_ta_get_split_table(LS *lua),
   l_cf_ta_goto_window(LS *lua),
   l_cf_view_goto_buffer(LS *lua),
   l_cf_ta_gtkmenu(LS *lua),
   l_cf_ta_popupmenu(LS *lua),
   l_cf_ta_reset(LS *lua),
   l_cf_pm_focus(LS *lua), l_cf_pm_clear(LS *lua), l_cf_pm_activate(LS *lua),
   l_cf_find_focus(LS *lua),
   l_cf_ce_focus(LS *lua);

const char
  *views_dne = "textadept.views doesn't exist or was overwritten.",
  *buffers_dne = "textadept.buffers doesn't exist or was overwritten.";

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
    lua_newtable(lua); lua_setfield(lua, LUA_REGISTRYINDEX, "buffers");
    lua_newtable(lua); lua_setfield(lua, LUA_REGISTRYINDEX, "views");
  } else { // clear package.loaded and _G
    lua_getglobal(lua, "package"); lua_getfield(lua, -1, "loaded");
    clear_table(lua, lua_gettop(lua));
    lua_pop(lua, 2); // package and package.loaded
    clear_table(lua, LUA_GLOBALSINDEX);
  }
  luaL_openlibs(lua);

  lua_newtable(lua);
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffers");
  lua_setfield(lua, -2, "buffers");
  lua_getfield(lua, LUA_REGISTRYINDEX, "views");
  lua_setfield(lua, -2, "views");
  lua_newtable(lua);
    l_cfunc(lua, l_cf_pm_focus, "focus");
    l_cfunc(lua, l_cf_pm_clear, "clear");
    l_cfunc(lua, l_cf_pm_activate, "activate");
    l_mt(lua, "_pm_mt", l_pm_mt_index, l_pm_mt_newindex);
  lua_setfield(lua, -2, "pm");
  lua_newtable(lua);
    l_cfunc(lua, l_cf_find_focus, "focus");
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
  l_cfunc(lua, l_cf_ta_popupmenu, "popupmenu");
  l_cfunc(lua, l_cf_ta_reset, "reset");
  l_mt(lua, "_textadept_mt", l_ta_mt_index, l_ta_mt_newindex);
  lua_setglobal(lua, "textadept");

  lua_getfield(lua, LUA_REGISTRYINDEX, "arg"); lua_setglobal(lua, "arg");
  lua_pushstring(lua, textadept_home); lua_setglobal(lua, "_HOME");
#ifdef WIN32
  lua_pushboolean(lua, 1); lua_setglobal(lua, "WIN32");
#endif

  return l_load_script("core/init.lua");
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
#ifndef WIN32
    GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
      GTK_MESSAGE_ERROR, GTK_BUTTONS_OK, "%s\n", errmsg);
    gtk_dialog_run(GTK_DIALOG(dialog));
#else
    MessageBox(0, static_cast<LPCSTR>(errmsg), "Error", 0);
#endif
    retval = false;
  }
  g_free(script);
  return retval;
}

/**
 * Retrieves the value of a given key in the global 'textadept' table.
 * @param lua The Lua State.
 * @param k The string key to lookup.
 */
bool l_ta_get(LS *lua, const char *k) {
  lua_getglobal(lua, "textadept");
  lua_pushstring(lua, k); lua_rawget(lua, -2);
  lua_remove(lua, -2); // textadept
  return lua_istable(lua, -1);
}

/**
 * Sets the value for a given key in the global 'textadept' table.
 * The value to set should be at the top of the stack in the Lua State.
 * @param lua The Lua State.
 * @param k The string key to set the value of.
 */
void l_ta_set(LS *lua, const char *k) {
  lua_getglobal(lua, "textadept");
  lua_pushstring(lua, k); lua_pushvalue(lua, -3); lua_rawset(lua, -3);
  lua_pop(lua, 2); // value and textadept
}

/**
 * Sets the value for a given key in the LUA_REGISTRYINDEX and global
 * 'textadept' table.
 * The value to set should be at the top of the stack in the Lua State.
 * @param lua The Lua State.
 * @param k The string key to set the value of.
 */
void l_reg_set(LS *lua, const char *k) {
  lua_setfield(lua, LUA_REGISTRYINDEX, k);
  lua_getfield(lua, LUA_REGISTRYINDEX, k);
  l_ta_set(lua, k);
}

/**
 * Checks a specified stack element to see if it is a Scintilla window and
 * returns it as a GtkWidget.
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a Scintilla window.
 * @param errstr Optional error string to use if the stack element is not a
 *   Scintilla window.
 *   Defaults to "View argument expected.".
 */
static GtkWidget *l_checkview(LS *lua, int narg, const char *errstr=0) {
  if (lua_type(lua, narg) == LUA_TTABLE) {
    lua_pushstring(lua, "widget_pointer");
    lua_rawget(lua, narg > 0 ? narg : narg - 1);
    if (lua_type(lua, -1) != LUA_TLIGHTUSERDATA)
      luaL_error(lua, errstr ? errstr : "View argument expected.");
  } else luaL_error(lua, errstr ? errstr : "View argument expected.");
  GtkWidget *editor = l_togtkwidget(lua, -1);
  lua_pop(lua, 1); // widget_pointer
  return editor;
}

/**
 * Adds a Scintilla window to the global 'views' table with a metatable.
 * @param editor The Scintilla window to add.
 */
void l_add_scintilla_window(GtkWidget *editor) {
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
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
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    editor != l_checkview(lua, -1) ? l_append(lua, -4) : lua_pop(lua, 1);
  lua_pop(lua, 1); // views
  l_reg_set(lua, "views");
}

/**
 * Changes focus a Scintilla window in the global 'views' table.
 * @param editor The currently focused Scintilla window.
 * @param n The index of the window in the 'views' table to focus.
 * @param absolute Flag indicating whether or not the index specified in 'views'
 *   is absolute. If false, focuses the window relative to the currently focused
 *   window for the given index.
 *   Defaults to true.
 */
void l_goto_scintilla_window(GtkWidget *editor, int n, bool absolute) {
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
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
    if (idx > lua_objlen(lua, -1)) idx = 1;
    else if (idx < 1) idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else lua_rawgeti(lua, -1, n);
  editor = l_checkview(lua, -1, "No view exists at that index.");
  gtk_widget_grab_focus(editor);
  if (!closing) l_handle_event("view_switch");
  lua_pop(lua, 2); // view table and views
}

/**
 * Sets the global 'view' variable to be the specified Scintilla window.
 * @param editor The Scintilla window to set 'view' to.
 */
void l_set_view_global(GtkWidget *editor) {
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
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
 * @param lua The Lua State.
 * @param narg Relative stack index to check for a buffer table.
 * @param errstr Optional error string to use if the stack element is not a
 *   buffer table.
 *   Defaults to "Buffer argument expected.".
 */
static sptr_t l_checkdocpointer(LS *lua, int narg, const char *errstr=0) {
  if (lua_type(lua, narg) == LUA_TTABLE) {
    lua_pushstring(lua, "doc_pointer");
    lua_rawget(lua, narg > 0 ? narg : narg - 1);
    if (lua_type(lua, -1) != LUA_TNUMBER)
      luaL_error(lua, errstr ? errstr : "Buffer argument expected.");
  } else luaL_error(lua, errstr ? errstr : "Buffer argument expected.");
  sptr_t doc = l_todocpointer(lua, -1);
  lua_pop(lua, 1); // doc_pointer
  return doc;
}

/**
 * Adds a Scintilla document to the global 'buffers' table with a metatable.
 * @param doc The Scintilla document to add.
 */
int l_add_scintilla_buffer(sptr_t doc) {
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  lua_newtable(lua);
  lua_pushnumber(lua, doc); lua_setfield(lua, -2, "doc_pointer");
  lua_pushboolean(lua, false); lua_setfield(lua, -2, "dirty");
  l_cfunc(lua, l_cf_buffer_find, "find");
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
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    GtkWidget *editor = l_checkview(lua, -1);
    sptr_t that_doc = SS(SCINTILLA(editor), SCI_GETDOCPOINTER);
    if (that_doc == doc) l_goto_scintilla_buffer(editor, -1, false);
    lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // views
  lua_newtable(lua);
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  lua_pushnil(lua);
  while (lua_next(lua, -2))
    doc != l_checkdocpointer(lua, -1) ? l_append(lua, -4) : lua_pop(lua, 1);
  lua_pop(lua, 1); // buffers
  l_reg_set(lua, "buffers");
}

/**
 * Retrieves the index in the global 'buffers' table for a given Scintilla
 * document.
 * @param doc The Scintilla document to get the index of.
 */
unsigned int l_get_docpointer_index(sptr_t doc) {
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
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

#define l_set_bufferp(k, v) \
  { lua_pushstring(lua, k); lua_pushinteger(lua, v); lua_rawset(lua, -3); }
#define l_get_bufferp(k, i) \
  { lua_pushstring(lua, k); lua_rawget(lua, i < 0 ? i - 1 : i); }

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
 *   Defaults to true.
 */
void l_goto_scintilla_buffer(GtkWidget *editor, int n, bool absolute) {
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  ScintillaObject *sci = SCINTILLA(editor);
  if (!absolute) {
    sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
    unsigned int idx = l_get_docpointer_index(doc);
    idx += n;
    if (idx > lua_objlen(lua, -1)) idx = 1;
    else if (idx < 1) idx = lua_objlen(lua, -1);
    lua_rawgeti(lua, -1, idx);
  } else lua_rawgeti(lua, -1, n);
  sptr_t doc = l_checkdocpointer(lua, -1, "No buffer exists at that index.");
  // Save previous buffer's properties.
  lua_getglobal(lua, "buffer");
  if (lua_istable(lua, -1)) {
    l_set_bufferp("_anchor", SS(sci, SCI_GETANCHOR));
    l_set_bufferp("_current_pos", SS(sci, SCI_GETCURRENTPOS));
    l_set_bufferp("_first_visible_line",
      SS(sci, SCI_DOCLINEFROMVISIBLE, SS(sci, SCI_GETFIRSTVISIBLELINE)));
  } lua_pop(lua, 1); // buffer
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
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
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
  while (unsplit_window(focused_editor)) ;
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    sptr_t doc = l_checkdocpointer(lua, -1);
    remove_scintilla_buffer(doc);
    lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // buffers
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
static void clear_table(LS *lua, int abs_index) {
  lua_pushnil(lua);
  while (lua_next(lua, abs_index)) {
    lua_pop(lua, 1); // value
    lua_pushnil(lua); lua_rawset(lua, abs_index);
    lua_pushnil(lua); // get 'new' first key
  }
}

/**
 * Checks if the Scintilla document of the buffer table at the index specified
 * is the document of the focused Scintilla window.
 * @param lua The Lua State.
 * @param narg The relative stack position of the buffer table.
 */
static void l_check_focused_buffer(LS *lua, int narg) {
  ScintillaObject *sci = SCINTILLA(focused_editor);
  sptr_t cur_doc = SS(sci, SCI_GETDOCPOINTER);
  if (cur_doc != l_checkdocpointer(lua, narg))
    luaL_error(lua, "The indexed buffer is not the focused one.");
}

/**
 * Checks whether or not a table in the global 'textadept' table has the
 * specified key and returns true or false.
 * @param lua The Lua State.
 * @param table The table in 'textadept' to check for key in.
 * @param key String key to check for in table.
 */
static bool l_is_ta_table_key(LS *lua, const char *table, const char *key) {
  if (l_ta_get(lua, table)) {
    lua_getfield(lua, -1, key);
    lua_remove(lua, -2); // table
    if (lua_istable(lua, -1)) return true;
    lua_pop(lua, 1); // non-table
  } else lua_pop(lua, 1); // non-table
  return false;
}

/**
 * Checks whether or not a table in the global 'textadept' table has the
 * specified function and returns true or false.
 * @param table The table in 'textadept' to check for function in.
 * @param function String function name to check for in table.
 */
bool l_is_ta_table_function(const char *table, const char *function) {
  if (l_ta_get(lua, table)) {
    lua_getfield(lua, -1, function);
    lua_remove(lua, -2); // table
    if (lua_isfunction(lua, -1)) return true;
    lua_pop(lua, 1); // non-function
  } else lua_pop(lua, 1); // non-table
  return false;
}

/**
 * Calls a Lua function with a number of arguments and expected return values.
 * The last argument is at the stack top, and each argument in reverse order is
 * one element lower on the stack with the Lua function being under the first
 * argument.
 * @param nargs The number of arguments to pass to the Lua function to call.
 * @param retn Optional number of expected return values. Defaults to 0.
 * @param keep_return Optoinal flag indicating whether or not to keep the return
 *   values at the top of the stack. If false, discards the return values.
 *   Defaults to false.
 */
bool l_call_function(int nargs, int retn=0, bool keep_return=false) {
  int ret = lua_pcall(lua, nargs, retn, 0);
  if (ret == 0) {
    bool result = retn > 0 ? lua_toboolean(lua, -1) == 1 : true;
    if (retn > 0 && !keep_return) lua_pop(lua, retn); // retn
    return result;
  } else l_handle_error(lua, NULL);
  return false;
}

/**
 * Performs a Lua rawget on a table at a given stack index and returns an int.
 * @param lua The Lua State.
 * @param index The relative index of the table to rawget from.
 * @param n The index in the table to rawget.
 */
static int l_rawgeti_int(LS *lua, int index, int n) {
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
static const char *l_rawget_str(LS *lua, int index, const char *k) {
  lua_pushstring(lua, k); lua_rawget(lua, index);
  const char *str = lua_tostring(lua, -1);
  lua_pop(lua, 1); // string
  return str;
}

/**
 * Convert the stack element at a specified index to a Scintilla w and/or l long
 * parameter based on type.
 * @param lua The Lua State.
 * @param type The Lua type the top stack element is.
 * @param arg_idx The initial stack index to start converting at. It is
 *   incremented as parameters are read from the stack.
 */
static long l_toscintillaparam(LS *lua, int type, int &arg_idx) {
  if (type == tSTRING)
    return reinterpret_cast<long>(lua_tostring(lua, arg_idx++));
  else if (type == tBOOL)
    return lua_toboolean(lua, arg_idx++);
  else if (type == tKEYMOD)
    return (static_cast<int>(luaL_checkinteger(lua, arg_idx++)) & 0xFFFF) |
           ((static_cast<int>(luaL_checkinteger(lua, arg_idx++)) &
           (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  else if (type > tVOID && type < tBOOL)
    return static_cast<long>(luaL_checknumber(lua, arg_idx++));
  else return 0;
}

/**
 * Creates a GtkMenu from a table at the top of the Lua stack.
 * The table has a key 'title' and a numeric list of subitems.
 * @param lua The Lua State.
 * @param callback A GCallback associated with each menu item.
 * @param submenu Flag indicating whether or not this menu is a submenu.
 *   Defaults to false.
 */
GtkWidget *l_create_gtkmenu(LS *lua, GCallback callback, bool submenu) {
  GtkWidget *menu = gtk_menu_new(), *menu_item = 0, *submenu_root = 0;
  const char *label;
  lua_getfield(lua, -1, "title");
  if (!lua_isnil(lua, -1) || submenu) { // title required for submenu
    label = !lua_isnil(lua, -1) ? lua_tostring(lua, -1) : "notitle";
    submenu_root = gtk_menu_item_new_with_mnemonic(label);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(submenu_root), menu);
  } lua_pop(lua, 1); // title
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_type(lua, -2) == LUA_TNUMBER && lua_isstring(lua, -1)) {
      label = lua_tostring(lua, -1);
      if (g_str_has_prefix(label, "gtk-"))
        menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
      else if (streq(label, "separator"))
        menu_item = gtk_separator_menu_item_new();
      else menu_item = gtk_menu_item_new_with_mnemonic(label);
      g_signal_connect(menu_item, "activate", callback, 0);
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
    } else if (lua_istable(lua, -1))
      gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                            l_create_gtkmenu(lua, callback, true));
    lua_pop(lua, 1); // value
  } return !submenu_root ? menu : submenu_root;
}

// Notification/event handlers

/**
 * Handles a Lua error.
 * The main error message is at the top of the Lua stack.
 * @param lua The Lua State.
 * @param errmsg An additional error message to display.
 */
void l_handle_error(LS *lua, const char *errmsg) {
  if (focused_editor && l_is_ta_table_function("events", "error")) {
    l_insert(lua, -1); // shift error message down
    if (errmsg) lua_pushstring(lua, errmsg);
    l_call_function(errmsg ? 2 : 1);
  } else {
    printf("Lua Error: %s\n", lua_tostring(lua, -1));
    if (errmsg) printf("%s\n", errmsg);
  }
  lua_settop(lua, 0);
}

/**
 * Handles a Textadept event.
 * @param s String event name.
 */
bool l_handle_event(const char *s) {
  return l_is_ta_table_function("events", s) ? l_call_function(0, 1) : false;
}

/**
 * Handles a Textadept event.
 * @param s String event name.
 * @param arg String first argument.
 */
bool l_handle_event(const char *s, const char *arg) {
  if (!l_is_ta_table_function("events", s)) return false;
  lua_pushstring(lua, arg);
  return l_call_function(1, 1);
}

/**
 * Handles a Textadept keypress.
 * @param keyval The key value of the key pressed.
 * @param shift Flag indicating whether or not the shift modifier was held.
 * @param control Flag indicating whether or not the control modifier was held.
 * @param alt Flag indicating whether or not the alt modifier was held.
 */
bool l_handle_keypress(int keyval, bool shift, bool control, bool alt) {
  if (!l_is_ta_table_function("events", "keypress")) return false;
  lua_pushinteger(lua, keyval);
  lua_pushboolean(lua, shift);
  lua_pushboolean(lua, control);
  lua_pushboolean(lua, alt);
  return l_call_function(4, 1);
}

#define l_scn_int(i, n) { lua_pushinteger(lua, i); lua_setfield(lua, -2,  n); }
#define l_scn_str(s, n) { lua_pushstring(lua, s); lua_setfield(lua, -2, n); }

/**
 * Handles a Scintilla notification.
 * @param n The Scintilla notification struct.
 */
void l_handle_scnnotification(SCNotification *n) {
  if (!l_is_ta_table_function("events", "notification")) return;
  lua_newtable(lua);
  l_scn_int(n->nmhdr.code, "code");
  l_scn_int(n->position, "position");
  l_scn_int(n->ch, "ch");
  l_scn_int(n->modifiers, "modifiers");
  l_scn_int(n->modificationType, "modification_type");
  l_scn_str(n->text, "text");
  l_scn_int(n->length, "length");
  l_scn_int(n->linesAdded, "lines_added");
  l_scn_int(n->message, "message");
  if (n->nmhdr.code == SCN_MACRORECORD) {
    l_scn_str(reinterpret_cast<char*>(n->wParam), "wParam");
    l_scn_str(reinterpret_cast<char*>(n->lParam), "lParam");
  } else {
    l_scn_int(static_cast<int>(n->wParam), "wParam");
    l_scn_int(static_cast<int>(n->lParam), "lParam");
  }
  l_scn_int(n->line, "line");
  l_scn_int(n->foldLevelNow, "fold_level_now");
  l_scn_int(n->foldLevelPrev, "fold_level_prev");
  l_scn_int(n->margin, "margin");
  l_scn_int(n->x, "x");
  l_scn_int(n->y, "y");
  l_call_function(1);
}

/**
 * Executes a given command string as Lua code.
 * @param command Lua code to execute.
 */
void l_ta_command(const char *command) {
  int top = lua_gettop(lua);
  if (luaL_dostring(lua, command) == 0) {
    l_handle_event("update_ui");
    lua_settop(lua, top);
  } else l_handle_error(lua, "Error executing command.");
}

// Command Entry

/**
 * Requests completions for the Command Entry Completion.
 * @param entry_text The text in the Command Entry.
 * @see l_cec_populate
 */
bool l_cec_get_completions_for(const char *entry_text) {
  if (!l_is_ta_table_function("command_entry", "get_completions_for"))
    return false;
  lua_pushstring(lua, entry_text);
  return l_call_function(1, 1, true);
}

/**
 * Populates the Command Entry Completion with the contents of a Lua table at
 * the stack top.
 * @see l_cec_get_completions_for
 */
void l_cec_populate() {
  GtkTreeIter iter;
  if (!lua_istable(lua, -1))
    return warn("command_entry.get_completions_for return not a table.");
  gtk_tree_store_clear(cec_store);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_type(lua, -1) == LUA_TSTRING) {
      gtk_tree_store_append(cec_store, &iter, NULL);
      gtk_tree_store_set(cec_store, &iter, 0, lua_tostring(lua, -1), -1);
    } else warn("command_entry.get_completions_for: string value expected.");
    lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // returned table
}

// Project Manager

/**
 * Requests contents for the Project Manager.
 * @param entry_text The text in the Project Manager Entry. If NULL, the full
 *   path table is at the top of the Lua stack.
 * @param expanding Flag indicating whether or not a treenode is being expanded.
 *   If true, the tree is walked up from the node to top creating a full path
 *   table at the stack top to be used essentially as entry_text.
 *   Defaults to false.
 * @see l_pm_get_full_path
 */
bool l_pm_get_contents_for(const char *entry_text, bool expanding) {
  if (!l_is_ta_table_function("pm", "get_contents_for")) return false;
  if (entry_text) {
    lua_newtable(lua);
    lua_pushstring(lua, entry_text);
    lua_rawseti(lua, -2, 1);
  } else l_insert(lua, -1); // shift full_path down
  lua_pushboolean(lua, expanding);
  return l_call_function(2, 1, true);
}

/**
 * Populates the Project Manager pane with the contents of a Lua table at the
 * stack top.
 * @param initial_iter The initial GtkTreeIter. If not NULL, it is a treenode
 *   being expanded and the contents will be added to that expanding node.
 *   Defaults to NULL.
 * @see l_pm_get_contents_for
 */
void l_pm_populate(GtkTreeIter *initial_iter) {
  GtkTreeIter iter, child;
  if (!lua_istable(lua, -1))
    return warn("pm.get_contents_for return not a table.");
  if (!initial_iter) gtk_tree_store_clear(pm_store);
  lua_pushnil(lua);
  while (lua_next(lua, -2)) {
    if (lua_istable(lua, -1) && lua_type(lua, -2) == LUA_TSTRING) {
      gtk_tree_store_append(pm_store, &iter, initial_iter);
      gtk_tree_store_set(pm_store, &iter, 1, lua_tostring(lua, -2), -1);
      lua_getfield(lua, -1, "parent");
      if (lua_toboolean(lua, -1)) {
        gtk_tree_store_append(pm_store, &child, &iter);
        gtk_tree_store_set(pm_store, &child, 1, "\0dummy", -1);
      }
      lua_pop(lua, 1); // parent
      lua_getfield(lua, -1, "pixbuf");
      if (lua_isstring(lua, -1))
        gtk_tree_store_set(pm_store, &iter, 0, lua_tostring(lua, -1), -1);
      else if (!lua_isnil(lua, -1))
        warn("pm.populate: pixbuf key must have string value.");
      lua_pop(lua, 1); // pixbuf
      lua_getfield(lua, -1, "text");
      gtk_tree_store_set(pm_store, &iter, 2, lua_isstring(lua, -1) ?
                         lua_tostring(lua, -1) : lua_tostring(lua, -3), -1);
      lua_pop(lua, 1); // display text
    } else warn("pm.populate: string id key must have table value.");
    lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // returned table
}

/**
 * For a Project Manager given node, get the full path to that node.
 * It leaves a full path table at the top of the Lua stack.
 * @param path The GtkTreePath of the node.
 */
void l_pm_get_full_path(GtkTreePath *path) {
  lua_newtable(lua);
  lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(pm_entry)));
  lua_rawseti(lua, -2, 1);
  if (!path) return;
  GtkTreeIter iter;
  char *filename;
  while (gtk_tree_path_get_depth(path) > 0) {
    gtk_tree_model_get_iter(GTK_TREE_MODEL(pm_store), &iter, path);
    gtk_tree_model_get(GTK_TREE_MODEL(pm_store), &iter, 1, &filename, -1);
    lua_pushstring(lua, filename);
    lua_rawseti(lua, -2, gtk_tree_path_get_depth(path) + 1);
    g_free(filename);
    gtk_tree_path_up(path);
  }
}

/**
 * Requests and pops up a context menu for the Project Manager.
 * @param event The mouse button event.
 * @param callback The GCallback associated with each menu item.
 */
void l_pm_popup_context_menu(GdkEventButton *event, GCallback callback) {
  if (!l_is_ta_table_function("pm", "get_context_menu")) return;
  GtkTreeIter iter;
  GtkTreePath *path = 0;
  GtkTreeSelection *sel = gtk_tree_view_get_selection(GTK_TREE_VIEW(pm_view));
  if (gtk_tree_selection_get_selected(sel, NULL, &iter))
    path = gtk_tree_model_get_path(GTK_TREE_MODEL(pm_store), &iter);
  l_pm_get_full_path(path);
  if (path) gtk_tree_path_free(path);
  if (lua_objlen(lua, -1) == 0) {
    lua_pop(lua, 2); // function and full_path
    return;
  }
  if (l_call_function(1, 1, true) && lua_istable(lua, -1)) {
    GtkWidget *menu = l_create_gtkmenu(lua, callback, false);
    lua_pop(lua, 1); // returned table
    gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                   event ? event->button : 0,
                   gdk_event_get_time(reinterpret_cast<GdkEvent*>(event)));
  } else warn("pm.get_context_menu return was not a table.");
}

/**
 * Performs an action for an activated item in the Project Manager.
 * The full path table for the item is at the top of the Lua stack.
 */
void l_pm_perform_action() {
  if (!l_is_ta_table_function("pm", "perform_action")) return;
  l_insert(lua, -1); // shift full_path down
  l_call_function(1);
}

/**
 * Performs a selected menu action from an item's context menu in the Project
 * Manager.
 * The full path table for the item is at the top of the Lua stack.
 * @param menu_item The label text for the menu item clicked.
 */
void l_pm_perform_menu_action(const char *menu_item) {
  if (!l_is_ta_table_function("pm", "perform_menu_action")) return;
  l_insert(lua, -1); // shift full_path down
  lua_pushstring(lua, menu_item);
  l_insert(lua, -1); // shift full_path down
  l_call_function(2);
}

// Find/Replace

/**
 * Finds text in the current document.
 * @param ftext The text to find.
 * @param flags Integer flags for the find.
 * @param next Flag indicating whether or not to find next. If false, finds
 *   previous matches.
 */
void l_find(const char *ftext, int flags, bool next) {
  if (!l_is_ta_table_function("find", "find")) return;
  lua_pushstring(lua, ftext);
  lua_pushinteger(lua, flags);
  lua_pushboolean(lua, next);
  l_call_function(3);
}

/**
 * Replaces text in the current document.
 * @param rtext The text to replace the found text with.
 */
void l_find_replace(const char *rtext) {
  if (!l_is_ta_table_function("find", "replace")) return;
  lua_pushstring(lua, rtext);
  l_call_function(1);
}

/**
 * Replaces all found text in the current document.
 * @param ftext The text to find.
 * @param rtext The text to replace the found text with.
 * @param flags Integer flags for the find.
 */
void l_find_replace_all(const char *ftext, const char *rtext, int flags) {
  if (!l_is_ta_table_function("find", "replace_all")) return;
  lua_pushstring(lua, ftext);
  lua_pushstring(lua, rtext);
  lua_pushinteger(lua, flags);
  l_call_function(3);
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
LF l_call_scintilla(LS *lua, ScintillaObject *sci, int msg,
                    int p1_type, int p2_type, int rt_type, int arg) {
  if (!sci) luaL_error(lua, "Scintilla object not initialized.");
  long params[2] = {0, 0};
  int params_needed = 2;
  bool string_return = false;
  char *return_string = 0;

  // Set the w and l parameters appropriately for Scintilla.
  if (p1_type == tLENGTH && p2_type == tSTRING) {
    params[0] = static_cast<long>(lua_strlen(lua, arg));
    params[1] = reinterpret_cast<long>(lua_tostring(lua, arg));
    params_needed = 0;
  } else if (p2_type == tSTRINGRESULT) {
    string_return = true;
    params_needed = p1_type == tLENGTH ? 0 : 1;
  }
  if (params_needed > 0) params[0] = l_toscintillaparam(lua, p1_type, arg);
  if (params_needed > 1) params[1] = l_toscintillaparam(lua, p2_type, arg);
  if (string_return) { // if a string return, create a buffer for it
    int len = SS(sci, msg, params[0], 0);
    if (p1_type == tLENGTH) params[0] = len;
    return_string = new char[len + 1]; return_string[len] = '\0';
    params[1] = reinterpret_cast<long>(return_string);
  }

  // Send the message to Scintilla and return the appropriate values.
  int result = SS(sci, msg, params[0], params[1]);
  arg = lua_gettop(lua);
  if (string_return) lua_pushstring(lua, return_string);
  if (rt_type == tBOOL) lua_pushboolean(lua, result);
  if (rt_type > tVOID && rt_type < tBOOL) lua_pushnumber(lua, result);
  delete[] return_string;
  return lua_gettop(lua) - arg;
}

/**
 * Calls a Scintilla buffer function with upvalues from a closure.
 * @param lua The Lua State.
 * @see l_buffer_mt_index
 */
LF l_call_buffer_function(LS *lua) {
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
LF l_buffer_mt_index(LS *lua) {
  ScintillaObject *sci = SCINTILLA(focused_editor);
  const char *key = luaL_checkstring(lua, 2);
  if (l_is_ta_table_key(lua, "buffer_functions", key)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { msg, rt_type, p1_type, p2_type }
    lua_pushlightuserdata(lua, const_cast<ScintillaObject*>(sci));
    l_insert(lua, -1); // shift buffer_functions down
    lua_pushcclosure(lua, l_call_buffer_function, 2);
  } else if (l_is_ta_table_key(lua, "buffer_properties", key)) {
    l_check_focused_buffer(lua, 1);
    // Of the form { get_id, set_id, rt_type, p1_type }
    int msg = l_rawgeti_int(lua, -1, 1); // getter
    int rt_type = l_rawgeti_int(lua, -1, 3);
    int p1_type = l_rawgeti_int(lua, -1, 4);
    if (p1_type != tVOID) { // indexible property
      sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
      lua_newtable(lua);
      lua_pushstring(lua, key); lua_setfield(lua, -2, "property");
      lua_pushnumber(lua, doc); lua_setfield(lua, -2, "doc_pointer");
      l_mt(lua, "_bufferp_mt", l_bufferp_mt_index, l_bufferp_mt_newindex);
    } else return l_call_scintilla(lua, sci, msg, p1_type, tVOID, rt_type, 2);
  } else lua_rawget(lua, 1);
  return 1;
}

/**
 * Helper function for the buffer property metatable.
 * @param lua The Lua State.
 * @param n 1 for getter property, 2 for setter.
 * @param prop String property name.
 * @param arg The index on the Lua stack where arguments to Scintilla begin.
 *   For setter properties, it is 3 because the index is not an argument. For
 *   getter and setter properties, it is 2 because the index is an argument.
 */
LF l_bufferp_mt_(LS *lua, int n, const char *prop, int arg) {
  ScintillaObject *sci = SCINTILLA(focused_editor);
  if (l_is_ta_table_key(lua, "buffer_properties", prop)) {
    l_check_focused_buffer(lua, 1);
    int msg = l_rawgeti_int(lua, -1, n); // getter (1) or setter (2)
    int rt_type = n == 1 ? l_rawgeti_int(lua, -1, 3) : tVOID;
    int p1_type = l_rawgeti_int(lua, -1, n == 1 ? 4 : 3);
    int p2_type = n == 2 ? l_rawgeti_int(lua, -1, 4) : tVOID;
    if (n == 2 &&
        (p2_type != tVOID || (p2_type == tVOID && p1_type == tSTRING))) {
      int temp = p1_type; p1_type = p2_type; p2_type = temp; // swap
    }
    if (msg != 0)
      return l_call_scintilla(lua, sci, msg, p1_type, p2_type, rt_type, arg);
    else luaL_error(lua, "The property '%s' is %s-only.", prop,
                    n == 1 ? "write" : "read");
  } else (lua_gettop(lua) > 2) ? lua_rawset(lua, 1) : lua_rawget(lua, 1);
  return 0;
}

LF l_buffer_mt_newindex(LS *lua) {
  return streq(lua_tostring(lua, 2), "doc_pointer")
    ? luaL_error(lua, "'doc_pointer' is read-only")
    : l_bufferp_mt_(lua, 2, lua_tostring(lua, 2), 3);
}

LF l_bufferp_mt_index(LS *lua) {
  return l_bufferp_mt_(lua, 1, l_rawget_str(lua, 1, "property"), 2);
}

LF l_bufferp_mt_newindex(LS *lua) {
  return l_bufferp_mt_(lua, 2, l_rawget_str(lua, 1, "property"), 2);
}

LF l_view_mt_index(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "doc_pointer"))
    lua_pushnumber(lua, SS(SCINTILLA(l_checkview(lua, 1)), SCI_GETDOCPOINTER));
  else if (streq(key, "size")) {
    GtkWidget *editor = l_checkview(lua, 1);
    if (GTK_IS_PANED(gtk_widget_get_parent(editor)))
      lua_pushnumber(lua,
        gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(editor))));
    else lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

LF l_view_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "doc_pointer") || streq(key, "widget_pointer"))
    luaL_error(lua, "'%s' is read-only.", key);
  else if (streq(key, "size")) {
    GtkWidget *pane = gtk_widget_get_parent(l_checkview(lua, 1));
    int size = static_cast<int>(lua_tonumber(lua, 3));
    if (size < 0) size = 0;
    if (GTK_IS_PANED(pane)) gtk_paned_set_position(GTK_PANED(pane), size);
  } else lua_rawset(lua, 1);
  return 0;
}

LF l_ta_mt_index(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    lua_pushstring(lua, gtk_window_get_title(GTK_WINDOW(window)));
  else if (streq(key, "focused_doc_pointer"))
    lua_pushnumber(lua, SS(SCINTILLA(focused_editor), SCI_GETDOCPOINTER));
  else if (streq(key, "clipboard_text")) {
    char *text = gtk_clipboard_wait_for_text(
      gtk_clipboard_get(GDK_SELECTION_CLIPBOARD));
    if (text) lua_pushstring(lua, text);
    g_free(text);
  } else lua_rawget(lua, 1);
  return 1;
}

LF l_ta_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "title"))
    gtk_window_set_title(GTK_WINDOW(window), lua_tostring(lua, 3));
  else if (streq(key, "statusbar_text"))
    set_statusbar_text(lua_tostring(lua, 3));
  else if (streq(key, "docstatusbar_text"))
    set_docstatusbar_text(lua_tostring(lua, 3));
  else if (streq(key, "focused_doc_pointer") || streq(key, "clipboard_text"))
    luaL_error(lua, "'%s' is read-only.", key);
  else if (streq(key, "menubar")) {
    const char *errmsg = "textadept.menubar must be a table of menus.";
    if (!lua_istable(lua, 3)) luaL_error(lua, errmsg);
    GtkWidget *menubar = gtk_menu_bar_new();
    lua_pushnil(lua);
    while (lua_next(lua, 3)) {
      if (!lua_isuserdata(lua, -1)) luaL_error(lua, errmsg);
      GtkWidget *menu_item = l_togtkwidget(lua, -1);
      gtk_menu_bar_append(GTK_MENU_BAR(menubar), menu_item);
      lua_pop(lua, 1); // value
    } set_menubar(menubar);
  } else lua_rawset(lua, 1);
  return 0;
}

LF l_pm_mt_index(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(pm_entry)));
  else if (streq(key, "width"))
    lua_pushnumber(lua,
      gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(pm_container))));
  else lua_rawget(lua, 1);
  return 1;
}

LF l_pm_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    gtk_entry_set_text(GTK_ENTRY(pm_entry), lua_tostring(lua, 3));
  else if (streq(key, "width"))
    gtk_paned_set_position(GTK_PANED(gtk_widget_get_parent(pm_container)),
      luaL_checkinteger(lua, 3));
  else lua_rawset(lua, 1);
  return 0;
}

LF l_find_mt_index(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(find_entry)));
  else if (streq(key, "replace_entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(replace_entry)));
  else lua_rawget(lua, 1);
  return 1;
}

LF l_find_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "find_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(find_entry), lua_tostring(lua, 3));
  else if (streq(key, "replace_entry_text"))
    gtk_entry_set_text(GTK_ENTRY(replace_entry), lua_tostring(lua, 3));
  else lua_rawset(lua, 1);
  return 0;
}

LF l_ce_mt_index(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    lua_pushstring(lua, gtk_entry_get_text(GTK_ENTRY(command_entry)));
  else lua_rawget(lua, 1);
  return 1;
}

LF l_ce_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "entry_text"))
    gtk_entry_set_text(GTK_ENTRY(command_entry), lua_tostring(lua, 3));
  else lua_rawset(lua, 1);
  return 0;
}

// Lua CFunctions. For documentation, consult the LuaDoc.

LF l_cf_ta_buffer_new(LS *lua) {
  new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  lua_rawgeti(lua, -1, lua_objlen(lua, -1));
  return 1;
}

LF l_cf_buffer_delete(LS *lua) {
  l_check_focused_buffer(lua, 1);
  sptr_t doc = l_checkdocpointer(lua, 1);
  if (!l_ta_get(lua, "buffers")) luaL_error(lua, buffers_dne);
  if (lua_objlen(lua, -1) > 1)
    l_goto_scintilla_buffer(focused_editor, -1, false);
  else
    new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  remove_scintilla_buffer(doc);
  l_handle_event("buffer_deleted");
  return 0;
}

LF l_cf_buffer_find(LS *lua) {
  l_check_focused_buffer(lua, 1);
  TextToFind ttf = {{0, 0}, 0, {0, 0}};
  ttf.lpstrText = const_cast<char*>(luaL_checkstring(lua, 2));
  int args = lua_gettop(lua), flags = 0;
  if (args > 2) flags = luaL_checkinteger(lua, 3);
  if (args > 3) ttf.chrg.cpMin = luaL_checkinteger(lua, 4);
  ttf.chrg.cpMax = args > 4 ? luaL_checkinteger(lua, 5)
                            : SS(SCINTILLA(focused_editor), SCI_GETLENGTH);
  int pos = SS(SCINTILLA(focused_editor), SCI_FINDTEXT, flags,
               reinterpret_cast<sptr_t>(&ttf));
  if (pos > -1) {
    lua_pushinteger(lua, ttf.chrgText.cpMin);
    lua_pushinteger(lua, ttf.chrgText.cpMax);
    return 2;
  } else return 0;
}

LF l_cf_buffer_text_range(LS *lua) {
  l_check_focused_buffer(lua, 1);
  TextRange tr;
  tr.chrg.cpMin = luaL_checkinteger(lua, 2);
  tr.chrg.cpMax = luaL_checkinteger(lua, 3);
  char *text = new char[tr.chrg.cpMax - tr.chrg.cpMin + 1];
  tr.lpstrText = text;
  SS(SCINTILLA(focused_editor), SCI_GETTEXTRANGE, 0,
     reinterpret_cast<long>(&tr));
  lua_pushstring(lua, text);
  delete[] text;
  return 1;
}

LF l_cf_view_focus(LS *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  gtk_widget_grab_focus(editor);
  return 0;
}

LF l_cf_view_split(LS *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  bool vertical = true;
  if (lua_gettop(lua) > 1) vertical = lua_toboolean(lua, 2) == 1;
  split_window(editor, vertical);
  lua_pushvalue(lua, 1); // old view
  lua_getglobal(lua, "view"); // new view
  return 2;
}

LF l_cf_view_unsplit(LS *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  lua_pushboolean(lua, unsplit_window(editor));
  return 1;
}

#define child1(p) gtk_paned_get_child1(GTK_PANED(p))
#define child2(p) gtk_paned_get_child2(GTK_PANED(p))

void l_create_entry(LS *lua, GtkWidget *c1, GtkWidget *c2, bool vertical) {
  lua_newtable(lua);
  if (GTK_IS_PANED(c1))
    l_create_entry(lua, child1(c1), child2(c1), GTK_IS_HPANED(c1) == 1);
  else
    lua_pushinteger(lua,
      l_get_docpointer_index(SS(SCINTILLA(c1), SCI_GETDOCPOINTER)));
  lua_rawseti(lua, -2, 1);
  if (GTK_IS_PANED(c2))
    l_create_entry(lua, child1(c2), child2(c2), GTK_IS_HPANED(c2) == 1);
  else
    lua_pushinteger(lua,
      l_get_docpointer_index(SS(SCINTILLA(c2), SCI_GETDOCPOINTER)));
  lua_rawseti(lua, -2, 2);
  lua_pushboolean(lua, vertical); lua_setfield(lua, -2, "vertical");
  int size = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(c1)));
  lua_pushinteger(lua, size); lua_setfield(lua, -2, "size");
}

LF l_cf_ta_get_split_table(LS *lua) {
  if (!l_ta_get(lua, "views")) luaL_error(lua, views_dne);
  if (lua_objlen(lua, -1) > 1) {
    GtkWidget *pane = gtk_widget_get_parent(focused_editor);
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_create_entry(lua, child1(pane), child2(pane), GTK_IS_HPANED(pane) == 1);
  } else lua_pushinteger(lua, l_get_docpointer_index(
                         SS(SCINTILLA(focused_editor), SCI_GETDOCPOINTER)));
  return 1;
}

LF l_cf_ta_goto_(LS *lua, GtkWidget *editor, bool buffer) {
  int n = static_cast<int>(luaL_checkinteger(lua, 1));
  bool absolute = lua_gettop(lua) > 1 ? lua_toboolean(lua, 2) == 1 : true;
  buffer ? l_goto_scintilla_buffer(editor, n, absolute)
         : l_goto_scintilla_window(editor, n, absolute);
  return 0;
}

LF l_cf_ta_goto_window(LS *lua) {
  return l_cf_ta_goto_(lua, focused_editor, false);
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
LF l_cf_view_goto_buffer(LS *lua) {
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

static void t_menu_activate(GtkWidget *menu_item, gpointer) {
  GtkWidget *label = gtk_bin_get_child(GTK_BIN(menu_item));
  const char *text = gtk_label_get_text(GTK_LABEL(label));
  l_handle_event("menu_clicked", text);
}

LF l_cf_ta_gtkmenu(LS *lua) {
  luaL_checktype(lua, 1, LUA_TTABLE);
  GtkWidget *menu = l_create_gtkmenu(lua, G_CALLBACK(t_menu_activate), false);
  lua_pushlightuserdata(lua, const_cast<GtkWidget*>(menu));
  return 1;
}

LF l_cf_ta_popupmenu(LS *lua) {
  if (!lua_isuserdata(lua, 1)) luaL_error(lua, "Menu userdata expected.");
  GtkWidget *menu = l_togtkwidget(lua, 1);
  gtk_widget_show_all(menu);
  gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, 0, NULL);
  return 0;
}

LF l_cf_ta_reset(LS *lua) {
  l_handle_event("resetting");
  lua_getglobal(lua, "buffer"); lua_setfield(lua, LUA_REGISTRYINDEX, "buffer");
  lua_getglobal(lua, "view"); lua_setfield(lua, LUA_REGISTRYINDEX, "view");
  l_init(0, NULL, true);
  lua_pushboolean(lua, true); lua_setglobal(lua, "RESETTING");
  l_load_script("init.lua");
  lua_pushnil(lua); lua_setglobal(lua, "RESETTING");
  lua_getfield(lua, LUA_REGISTRYINDEX, "buffer"); lua_setglobal(lua, "buffer");
  lua_getfield(lua, LUA_REGISTRYINDEX, "view"); lua_setglobal(lua, "view");
  return 0;
}

LF l_cf_pm_focus(LS *) { pm_toggle_focus(); return 0; }
LF l_cf_pm_clear(LS *) { gtk_tree_store_clear(pm_store); return 0; }
LF l_cf_pm_activate(LS *) {
  g_signal_emit_by_name(G_OBJECT(pm_entry), "activate"); return 0;
}
LF l_cf_find_focus(LS *) { find_toggle_focus(); return 0; }

LF l_cf_ce_focus(LS *) { ce_toggle_focus(); return 0; }

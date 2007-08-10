// Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

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
  tVOID = 0, tINT = 1, tLENGTH = 2, tPOSITION = 3, tCOLOUR = 4,
  tBOOL = 5, tKEYMOD = 6, tSTRING = 7, tSTRINGRESULT = 8;

LF l_buffer_mt_index(LS *lua), l_buffer_mt_newindex(LS *lua),
   l_bufferp_mt_index(LS *lua), l_bufferp_mt_newindex(LS *lua),
   l_view_mt_index(LS *lua), l_view_mt_newindex(LS *lua),
   l_ta_mt_index(LS *lua), l_ta_mt_newindex(LS *lua),
   l_pm_mt_index(LS *lua), l_pm_mt_newindex(LS *lua),
   l_find_mt_index(LS *lua), l_find_mt_newindex(LS *lua);

LF l_cf_ta_buffer_new(LS *lua),
   l_cf_buffer_delete(LS *lua),
   l_cf_buffer_find(LS *lua),
   l_cf_buffer_text_range(LS *lua),
   l_cf_view_focus(LS *lua),
   l_cf_view_split(LS *lua), l_cf_view_unsplit(LS *lua),
   l_cf_ta_get_split_table(LS *lua),
   l_cf_ta_focus_command(LS *lua),
   l_cf_ta_goto_window(LS *lua),
   l_cf_view_goto_buffer(LS *lua),
   l_cf_pm_focus(LS *lua), l_cf_pm_clear(LS *lua), l_cf_pm_activate(LS *lua),
   l_cf_find_focus(LS *lua);

void l_init(int argc, char **argv) {
  lua = lua_open();
  luaL_openlibs(lua);
  lua_newtable(lua);
  for (int i = 0; i < argc; i++) {
    lua_pushstring( lua, argv[i] ); lua_rawseti(lua, -2, i);
  }
  lua_setglobal(lua, "arg");

  lua_newtable(lua);
  lua_newtable(lua); lua_setfield(lua, -2, "buffers");
  lua_newtable(lua); lua_setfield(lua, -2, "views");
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
  l_cfunc(lua, l_cf_ta_buffer_new, "new_buffer");
  l_cfunc(lua, l_cf_ta_goto_window, "goto_view");
  l_cfunc(lua, l_cf_ta_get_split_table, "get_split_table");
  l_cfunc(lua, l_cf_ta_focus_command, "focus_command");
  l_mt(lua, "_textadept_mt", l_ta_mt_index, l_ta_mt_newindex);
  lua_setglobal(lua, "textadept");
  lua_pushstring(lua, textadept_home); lua_setglobal(lua, "_HOME");

  l_load_script("core/init.lua");
}

void l_load_script(const char *script_file) {
  char *script = g_strconcat(textadept_home, "/", script_file, NULL);
  if (luaL_dofile(lua, script) != 0) l_handle_error(lua);
  g_free(script);
}

bool l_ta_get(LS *lua, const char *k) {
  lua_getglobal(lua, "textadept");
  lua_pushstring(lua, k); lua_rawget(lua, -2);
  lua_remove(lua, -2); // textadept
  return lua_istable(lua, -1);
}

// value is at stack top
void l_ta_set(LS *lua, const char *k) {
  lua_getglobal(lua, "textadept");
  lua_pushstring(lua, k);
  lua_pushvalue(lua, -3);
  lua_rawset(lua, -3);
  lua_pop(lua, 2); // value and textadept
}

/** Checks for a view and returns the GtkWidget associated with it. */
static GtkWidget* l_checkview(LS *lua, int narg, const char *errstr=NULL) {
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

void l_add_scintilla_window(GtkWidget *editor) {
  if (!l_ta_get(lua, "views")) { lua_pop(lua, 1); return; }
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

void l_remove_scintilla_window(GtkWidget *editor) {
  lua_newtable(lua);
  if (l_ta_get(lua, "views")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      editor != l_checkview(lua, -1) ? l_append(lua, -4) : lua_pop(lua, 1);
  } lua_pop(lua, 1); // views
  l_ta_set(lua, "views");
}

void l_goto_scintilla_window(GtkWidget *editor, int n, bool absolute) {
  if (!l_ta_get(lua, "views")) { lua_pop(lua, 1); return; }
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
  } else lua_rawgeti(lua, -1, n);
  editor = l_checkview(lua, -1, "No view exists at that index.");
  gtk_widget_grab_focus(editor);
  if (!closing) l_handle_signal("view_switch");
  lua_pop(lua, 2); // view table and views
}

void l_set_view_global(GtkWidget *editor) {
  if (l_ta_get(lua, "views")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (editor == l_checkview(lua, -1)) {
        lua_setglobal(lua, "view"); // value (view table)
        lua_pop(lua, 1); // key
        break;
      } else lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // views
}

/** Checks for a buffer and returns the doc_pointer associated with it. */
static sptr_t l_checkdocpointer(LS *lua, int narg, const char *errstr=NULL) {
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

int l_add_scintilla_buffer(sptr_t doc) {
  if (!l_ta_get(lua, "buffers")) { lua_pop(lua, 1); return 1; }
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

void l_remove_scintilla_buffer(sptr_t doc) {
  // Switch documents for all views that show the current document.
  if (l_ta_get(lua, "views")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2)) {
      GtkWidget *editor = l_checkview(lua, -1);
      sptr_t that_doc = SS(SCINTILLA(editor), SCI_GETDOCPOINTER);
      if (that_doc == doc) l_goto_scintilla_buffer(editor, -1, false);
      lua_pop(lua, 1); // value
    }
  } lua_pop(lua, 1); // views

  lua_newtable(lua);
  if (l_ta_get(lua, "buffers")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      doc != l_checkdocpointer(lua, -1) ? l_append(lua, -4) : lua_pop(lua, 1);
  } lua_pop(lua, 1); // buffers
  l_ta_set(lua, "buffers");
}

unsigned int l_get_docpointer_index(sptr_t doc) {
  if (!l_ta_get(lua, "buffers")) { lua_pop(lua, 1); return 1; }
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

#define l_set_buffer_prop(k, v) \
  { lua_pushstring(lua, k); lua_pushinteger(lua, v); lua_rawset(lua, -3); }
#define l_get_buffer_prop(k, i) { lua_pushstring(lua, k); lua_rawget(lua, i); }

void l_goto_scintilla_buffer(GtkWidget *editor, int n, bool absolute) {
  if (!l_ta_get(lua, "buffers")) { lua_pop(lua, 1); return; }
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
  } else lua_rawgeti(lua, -1, n);
  sptr_t doc = l_checkdocpointer(lua, -1, "No buffer exists at that index.");
  // Save previous buffer's properties.
  lua_getglobal(lua, "buffer");
  l_set_buffer_prop("_anchor", SS(sci, SCI_GETANCHOR));
  l_set_buffer_prop("_current_pos", SS(sci, SCI_GETCURRENTPOS));
  l_set_buffer_prop("_first_visible_line",
    SS(sci, SCI_DOCLINEFROMVISIBLE, SS(sci, SCI_GETFIRSTVISIBLELINE)));
  lua_pop(lua, 1); // buffer
  // Change the view.
  SS(sci, SCI_SETDOCPOINTER, 0, doc);
  l_set_buffer_global(sci);
  // Restore this buffer's properties.
  lua_getglobal(lua, "buffer");
  l_get_buffer_prop("_first_visible_line", -2);
  SS(sci, SCI_LINESCROLL, 0,
     SS(sci, SCI_VISIBLEFROMDOCLINE, lua_tointeger(lua, -1)));
  l_get_buffer_prop("_anchor", -3);
  l_get_buffer_prop("_current_pos", -4);
  SS(sci, SCI_SETSEL, lua_tointeger(lua, -2), lua_tointeger(lua, -1));
  lua_pop(lua, 4); // _first_visible_line, _anchor, _current_pos, and buffer
  if (!closing) l_handle_signal("buffer_switch");
  lua_pop(lua, 2); // buffer table and buffers
}

void l_set_buffer_global(ScintillaObject *sci) {
  sptr_t doc = SS(sci, SCI_GETDOCPOINTER);
  if (l_ta_get(lua, "buffers")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2))
      if (doc == l_checkdocpointer(lua, -1)) {
        lua_setglobal(lua, "buffer"); // value (buffer table)
        lua_pop(lua, 1); // key
        break;
      } else lua_pop(lua, 1); // value
  } lua_pop(lua, 1); // buffers
}

void l_close() {
  closing = true;
  while (unsplit_window(focused_editor));
  if (l_ta_get(lua, "buffers")) {
    lua_pushnil(lua);
    while (lua_next(lua, -2)) {
      sptr_t doc = l_checkdocpointer(lua, -1);
      remove_scintilla_buffer(doc);
      lua_pop(lua, 1); // value
    }
  } lua_pop(lua, 1); // buffers
  gtk_widget_destroy(focused_editor);
  lua_close(lua);
}

// Notification/signal handlers

bool l_is_ta_table_function(const char *table, const char *function) {
  if (l_ta_get(lua, table)) {
    lua_getfield(lua, -1, function);
    lua_remove(lua, -2); // table
    if (lua_isfunction(lua, -1)) return true;
    lua_pop(lua, 1); // non-function
  } else lua_pop(lua, 1); // non-table
  return false;
}

bool l_call_function(int nargs, int retn=0, bool keep_return=false) {
  int ret = lua_pcall(lua, nargs, retn, 0);
  if (ret == 0) {
    bool result = retn > 0 ? lua_toboolean(lua, -1) == 1 : true;
    if (retn > 0 && !keep_return) lua_pop(lua, retn); // retn
    return result;
  } else l_handle_error(lua);
  return false;
}

// error message is at stack top
void l_handle_error(LS *lua, const char *errmsg) {
  if (focused_editor && l_is_ta_table_function("handlers", "error")) {
    l_insert(lua, -1); // shift error message down
    if (errmsg) lua_pushstring(lua, errmsg);
    l_call_function(errmsg ? 2 : 1);
  } else {
    printf("Lua Error: %s\n", lua_tostring(lua, -1));
    if (errmsg) printf("%s\n", errmsg);
  }
  lua_settop(lua, 0);
}

bool l_handle_signal(const char *s) {
  return l_is_ta_table_function("handlers", s) ? l_call_function(0, 1) : true;
}

bool l_handle_keypress(int keyval, GdkEventKey *event) {
  if (!l_is_ta_table_function("handlers", "keypress")) return false;
  lua_pushinteger(lua, keyval);
  lua_pushboolean(lua, (event->state & GDK_SHIFT_MASK) > 0 ? 1 : 0);
  lua_pushboolean(lua, (event->state & GDK_CONTROL_MASK) > 0 ? 1 : 0);
  lua_pushboolean(lua, (event->state & GDK_MOD1_MASK) > 0 ? 1 : 0);
  return l_call_function(4, 1);
}

void l_handle_completion(const char *command) {
  if (!l_is_ta_table_function("handlers",
      command ? "show_completions" : "hide_completions")) return;
  if (command) lua_pushstring(lua, command);
  l_call_function(command ? 1 : 0);
}

#define l_scn_int(i, n) { lua_pushinteger(lua, i); lua_setfield(lua, -2,  n); }
#define l_scn_str(s, n) { lua_pushstring(lua, s); lua_setfield(lua, -2, n); }

void l_handle_scnnotification(SCNotification *n) {
  if (!l_is_ta_table_function("handlers", "notification")) return;
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

void l_ta_command(const char *command) {
  int top = lua_gettop(lua);
  if (luaL_dostring(lua, command) == 0) {
    l_handle_signal("update_ui");
    lua_settop(lua, top);
  } else l_handle_error(lua, "Error executing command.");
}

// full_path is at stack top if entry_text is NULL
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

void warn(const char *s) { printf("Warning: %s\n", s); }

// table is at stack top
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
      else warn("pm.populate: pixbuf key must have string value.");
      lua_pop(lua, 1); // pixbuf
      lua_getfield(lua, -1, "text");
      gtk_tree_store_set(pm_store, &iter, 2, lua_isstring(lua, -1) ?
                         lua_tostring(lua, -1) : lua_tostring(lua, -3));
      lua_pop(lua, 1); // display text
    } else warn("pm.populate: id key must have table value.");
    lua_pop(lua, 1); // value
  }
  lua_pop(lua, 1); // returned table
}

void l_pm_get_full_path(GtkTreePath *path) {
  lua_newtable(lua); // will be at stack top
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
    GtkWidget *menu = gtk_menu_new();
    lua_pushnil(lua);
    while (lua_next(lua, -2)) {
      GtkWidget *menu_item;
      const char *label = lua_tostring(lua, -1);
      if (g_str_has_prefix(label, "gtk-"))
        menu_item = gtk_image_menu_item_new_from_stock(label, NULL);
      else if (streq(label, "separator"))
        menu_item = gtk_separator_menu_item_new();
      else
        menu_item = gtk_menu_item_new_with_mnemonic(label);
      g_signal_connect(menu_item, "activate", callback, 0);
      gtk_menu_shell_append(GTK_MENU_SHELL(menu), menu_item);
      lua_pop(lua, 1); // value
    }
    lua_pop(lua, 1); // returned table
    gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL,
                   event ? event->button : 0,
                   gdk_event_get_time(reinterpret_cast<GdkEvent*>(event)));
  } else warn("pm.get_context_menu return was not a table.");
}

// full_path is at stack top
void l_pm_perform_action() {
  if (!l_is_ta_table_function("pm", "perform_action")) return;
  l_insert(lua, -1); // shift full_path down
  l_call_function(1);
}

// full_path is at stack top
void l_pm_perform_menu_action(const char *menu_item) {
  if (!l_is_ta_table_function("pm", "perform_menu_action")) return;
  l_insert(lua, -1); // shift full_path down
  lua_pushstring(lua, menu_item);
  l_insert(lua, -1); // shift full_path down
  l_call_function(2);
}

void l_find(const char *ftext, int flags, bool next) {
  if (!l_is_ta_table_function("find", "find")) return;
  lua_pushstring(lua, ftext);
  lua_pushinteger(lua, flags);
  lua_pushboolean(lua, next);
  l_call_function(3);
}

void l_find_replace(const char *rtext) {
  if (!l_is_ta_table_function("find", "replace")) return;
  lua_pushstring(lua, rtext);
  l_call_function(1);
}

void l_find_replace_all(const char *ftext, const char *rtext, int flags) {
  if (!l_is_ta_table_function("find", "replace_all")) return;
  lua_pushstring(lua, ftext);
  lua_pushstring(lua, rtext);
  lua_pushinteger(lua, flags);
  l_call_function(3);
}

/** Behaves like lua_rawgeti but casts the result to an integer. */
static int l_rawgeti_int(LS *lua, int index, int n) {
  lua_rawgeti(lua, index, n);
  int ret = static_cast<int>(lua_tointeger(lua, -1));
  lua_pop(lua, 1); // integer
  return ret;
}

/** Behaves like lua_rawget but casts the result to a string. */
static const char* l_rawget_str(LS *lua, int index, const char *k) {
  lua_pushstring(lua, k); lua_rawget(lua, index);
  const char *str = lua_tostring(lua, -1);
  lua_pop(lua, 1); // string
  return str;
}

/** Get a long for Scintilla w or l parameter based on type. */
static long l_toscintillaparam(LS *lua, int type, int &arg_idx) {
  if (type == tSTRING)
    return reinterpret_cast<long>(lua_tostring(lua, arg_idx++));
  else if (type == tBOOL)
    return lua_toboolean(lua, arg_idx++);
  else if (type == tKEYMOD)
    return static_cast<int>(luaL_checkinteger(lua, arg_idx++)) & 0xFFFF |
           ((static_cast<int>(luaL_checkinteger(lua, arg_idx++)) &
           (SCMOD_SHIFT | SCMOD_CTRL | SCMOD_ALT)) << 16);
  else if (type > tVOID && type < tBOOL)
    return static_cast<long>(luaL_checknumber(lua, arg_idx++));
  else
    return 0;
}

static bool l_is_ta_table_key(LS *lua, const char *table, const char *key) {
  if (l_ta_get(lua, table)) {
    lua_getfield(lua, -1, key);
    lua_remove(lua, -2); // table
    if (lua_istable(lua, -1)) return true;
    lua_pop(lua, 1); // non-table
  } else lua_pop(lua, 1); // non-table
  return false;
}

static void l_check_focused_buffer(LS *lua, int narg) {
  ScintillaObject *sci = SCINTILLA(focused_editor);
  sptr_t cur_doc = SS(sci, SCI_GETDOCPOINTER);
  if (cur_doc != l_checkdocpointer(lua, narg))
    luaL_error(lua, "The indexed buffer is not the focused one.");
}

// Lua functions to follow

/** Calls Scintilla returning appropriate values.
 *  The p1, p2, and rt types are integer types of the w, l, and return
 *  parameters respectively. arg is the Lua stack index where user arguments
 *  begin. The appropriate value(s) are returned to Lua.
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

/** Helper function for the buffer property metatable.
 *  n indicates a getter or setter (1 or 2) and arg is the Lua stack index
 *  where user arguments begin. For setting buffer properties, it is 3 because
 *  the index is not an argument, but for getting and setting indexed buffer
 *  properties it is 2 because the index is an argument.
 */
LF l_bufferp_mt_(LS *lua, int n, const char *prop, int arg) {
  ScintillaObject *sci = SCINTILLA(focused_editor);
  if (l_is_ta_table_key(lua, "buffer_properties", prop)) {
    l_check_focused_buffer(lua, 1);
    int msg = l_rawgeti_int(lua, -1, n); // getter (1) or setter (2)
    int rt_type = n == 1 ? l_rawgeti_int(lua, -1, 3) : tVOID;
    int p1_type = l_rawgeti_int(lua, -1, n == 1 ? 4 : 3);
    int p2_type = n == 2 ? l_rawgeti_int(lua, -1, 4) : tVOID;
    if (n == 2 && (p2_type != tVOID || p2_type == tVOID && p1_type == tSTRING))
      p1_type ^= p2_type ^= p1_type ^= p2_type;
    if (msg != 0)
      return l_call_scintilla(lua, sci, msg, p1_type, p2_type, rt_type, arg);
    else luaL_error(lua, "The property '%s' is %s-only.", prop,
                    n == 1 ? "write" : "read");
  } else (lua_gettop(lua) > 2) ? lua_rawset(lua, 1) : lua_rawget(lua, 1);
  return 0;
}

LF l_buffer_mt_newindex(LS *lua) {
  if (streq(lua_tostring(lua, 2), "doc_pointer"))
    return luaL_error(lua, "'doc_pointer' is read-only.");
  else
    return l_bufferp_mt_(lua, 2, lua_tostring(lua, 2), 3);
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
    else
      lua_pushnil(lua);
  } else lua_rawget(lua, 1);
  return 1;
}

LF l_view_mt_newindex(LS *lua) {
  const char *key = lua_tostring(lua, 2);
  if (streq(key, "doc_pointer") || streq(key, "widget_pointer"))
    luaL_error(lua, "'%s' is read-only.", key);
  else if (streq(key, "size")) {
    GtkWidget *pane = gtk_widget_get_parent(l_checkview(lua, 1));
    if (GTK_IS_PANED(pane))
      gtk_paned_set_position(GTK_PANED(pane), lua_tonumber(lua, 3));
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
  else lua_rawset(lua, 1);
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

// Lua CFunctions

LF l_cf_ta_buffer_new(LS *lua) {
  new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  l_ta_get(lua, "buffers"); lua_rawgeti(lua, -1, lua_objlen(lua, -1));
  return 1;
}

LF l_cf_buffer_delete(LS *lua) {
  l_check_focused_buffer(lua, 1);
  sptr_t doc = l_checkdocpointer(lua, 1);
  l_ta_get(lua, "buffers");
  if (lua_objlen(lua, -1) > 1)
    l_goto_scintilla_buffer(focused_editor, -1, false);
  else
    new_scintilla_buffer(SCINTILLA(focused_editor), true, true);
  remove_scintilla_buffer(doc);
  l_handle_signal("buffer_deleted");
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
  bool vertical = lua_gettop(lua) > 1 ? lua_toboolean(lua, 2) : true;
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

#define child2(p) gtk_paned_get_child2(GTK_PANED(p))
#define child1(p) gtk_paned_get_child1(GTK_PANED(p))
#define vertical(p) GTK_IS_HPANED(p) ? true : false

void l_create_entry(LS *lua, GtkWidget *c1, GtkWidget *c2, bool vertical) {
  lua_newtable(lua);
  if (GTK_IS_PANED(c1))
    l_create_entry(lua, child1(c1), child2(c1), vertical(c1));
  else
    lua_pushinteger(lua,
      l_get_docpointer_index(SS(SCINTILLA(c1), SCI_GETDOCPOINTER)));
  lua_rawseti(lua, -2, 1);
  if (GTK_IS_PANED(c2))
    l_create_entry(lua, child1(c2), child2(c2), vertical(c2));
  else
    lua_pushinteger(lua,
      l_get_docpointer_index(SS(SCINTILLA(c2), SCI_GETDOCPOINTER)));
  lua_rawseti(lua, -2, 2);
  lua_pushboolean(lua, vertical); lua_setfield(lua, -2, "vertical");
  int size = gtk_paned_get_position(GTK_PANED(gtk_widget_get_parent(c1)));
  lua_pushinteger(lua, size); lua_setfield(lua, -2, "size");
}

LF l_cf_ta_get_split_table(LS *lua) {
  l_ta_get(lua, "views");
  if (lua_objlen(lua, -1) > 1) {
    GtkWidget *pane = gtk_widget_get_parent(focused_editor);
    while (GTK_IS_PANED(gtk_widget_get_parent(pane)))
      pane = gtk_widget_get_parent(pane);
    l_create_entry(lua, child1(pane), child2(pane), vertical(pane));
  } else lua_pushinteger(lua, l_get_docpointer_index(
                         SS(SCINTILLA(focused_editor), SCI_GETDOCPOINTER)));
  return 1;
}

LF l_cf_ta_focus_command(LS *) { command_toggle_focus(); return 0; }

LF l_cf_goto_(LS *lua, GtkWidget *editor, bool buffer=true) {
  int n = static_cast<int>(luaL_checkinteger(lua, 1));
  bool absolute = lua_gettop(lua) > 1 ? lua_toboolean(lua, 2) == 1 : true;
  buffer ? l_goto_scintilla_buffer(editor, n, absolute)
         : l_goto_scintilla_window(editor, n, absolute);
  return 0;
}

LF l_cf_ta_goto_window(LS *lua) {
  return l_cf_goto_(lua, focused_editor, false);
}

// If the indexed view is not currently focused, temporarily focus it so calls
// to handlers will not throw 'indexed buffer is not the focused one' error.
LF l_cf_view_goto_buffer(LS *lua) {
  GtkWidget *editor = l_checkview(lua, 1);
  bool switch_focus = editor != focused_editor;
  GtkWidget *orig_focused_editor = focused_editor;
  if (switch_focus) SS(SCINTILLA(editor), SCI_SETFOCUS, true);
  lua_remove(lua, 1); // view table
  l_cf_goto_(lua, editor, true);
  if (switch_focus) {
    SS(SCINTILLA(editor), SCI_SETFOCUS, false);
    gtk_widget_grab_focus(orig_focused_editor);
  }
  return 0;
}

LF l_cf_pm_focus(LS *) { pm_toggle_focus(); return 0; }

LF l_cf_pm_clear(LS *) { gtk_tree_store_clear(pm_store); return 0; }

LF l_cf_pm_activate(LS *) {
  g_signal_emit_by_name(G_OBJECT(pm_entry), "activate"); return 0;
}

LF l_cf_find_focus(LS *) { find_toggle_focus(); return 0; }

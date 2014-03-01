-- Copyright 2007-2014 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors. If
-- applicable, load this module second to last in your *~/.textadept/init.lua*,
-- before `textadept.menu`.
--
-- ## Key Bindings
--
-- Linux / Win32 | Mac OSX | Terminal | Command
-- --------------|---------|----------|--------
-- **File**      |         |          |
-- Ctrl+N        |⌘N       |M-^N      |New file
-- Ctrl+O        |⌘O       |^O        |Open file
-- Ctrl+Alt+O    |^⌘O      |M-^O      |Open recent file...
-- Ctrl+Shift+O  |⌘⇧O      |M-O       |Reload file
-- Ctrl+S        |⌘S       |^S        |Save file
-- Ctrl+Shift+S  |⌘⇧S      |M-^S      |Save file as..
-- Ctrl+W        |⌘W       |^W        |Close file
-- Ctrl+Shift+W  |⌘⇧W      |M-^W      |Close all files
-- None          |None     |None      |Load session...
-- None          |None     |None      |Load session...
-- Ctrl+Q        |⌘Q       |^Q        |Quit
-- **Edit**                |         |             |
-- Ctrl+Z<br/>Alt+Bksp     |⌘Z       |^Z           |Undo
-- Ctrl+Y<br/>Ctrl+Shift+Z |⌘⇧Z      |^Y           |Redo
-- Ctrl+X<br/>Shift+Del    |⌘X<br/>⇧⌦|^X           |Cut
-- Ctrl+C<br/>Ctrl+Ins     |⌘C       |^C           |Copy
-- Ctrl+V<br/>Shift+Ins    |⌘V       |^V           |Paste
-- Ctrl+D                  |⌘D       |None         |Duplicate line
-- Del                     |⌦<br/>^D |Del<br/>^D   |Delete
-- Alt+Del                 |^⌦       |M-Del<br/>M-D|Delete word
-- Ctrl+A                  |⌘A       |M-A          |Select all
-- Ctrl+M                  |^M       |M-M          |Match brace
-- Ctrl+Enter              |^⎋       |M-Enter^(†)  |Complete word
-- Ctrl+Alt+Shift+H        |⌘⇧H      |None         |Highlight word
-- Ctrl+/                  |^/       |M-/          |Toggle block comment
-- Ctrl+T                  |^T       |^T           |Transpose characters
-- Ctrl+Shift+J            |^J       |M-J          |Join lines
-- Ctrl+&#124;             |⌘&#124;  |^\           |Filter text through
-- Ctrl+Shift+M            |^⇧M      |M-S-M        |Select to matching brace
-- Ctrl+<                  |⌘<       |M-<          |Select between XML tags
-- Ctrl+>                  |⌘>       |None         |Select in XML tag
-- Ctrl+"                  |⌘"       |M-"          |Select in double quotes
-- Ctrl+'                  |⌘'       |M-'          |Select in single quotes
-- Ctrl+(                  |⌘(       |M-(          |Select in parentheses
-- Ctrl+[                  |⌘[       |M-[          |Select in brackets
-- Ctrl+{                  |⌘{       |M-{          |Select in braces
-- Ctrl+Shift+D            |⌘⇧D      |M-S-W        |Select word
-- Ctrl+Shift+N            |⌘⇧N      |M-S-N        |Select line
-- Ctrl+Shift+P            |⌘⇧P      |M-S-P        |Select paragraph
-- Ctrl+Shift+I            |⌘⇧I      |M-S-I        |Select indented block
-- Ctrl+Alt+U              |^U       |M-^U         |Upper case selection
-- Ctrl+Alt+Shift+U        |^⇧U      |M-^L         |Lower case selection
-- Alt+<                   |^<       |M->          |Enclose as XML tags
-- Alt+>                   |^>       |None         |Enclose as single XML tag
-- Alt+"                   |^"       |None         |Enclose in double quotes
-- Alt+'                   |^'       |None         |Enclose in single quotes
-- Alt+(                   |^(       |M-)          |Enclose in parentheses
-- Alt+[                   |^[       |M-]          |Enclose in brackets
-- Alt+{                   |^{       |M-}          |Enclose in braces
-- Ctrl+Shift+Up           |^⇧⇡      |S-^Up        |Move selected lines up
-- Ctrl+Shift+Down         |^⇧⇣      |S-^Down      |Move selected lines down
-- **Search**               |    |             |
-- Ctrl+F                   |⌘F  |M-F<br/>M-S-F|Find
-- Ctrl+G<br/>F3            |⌘G  |M-G          |Find next
-- Ctrl+Shift+G<br/>Shift+F3|⌘⇧G |M-S-G        |Find previous
-- Ctrl+Alt+R               |^R  |M-R          |Replace
-- Ctrl+Alt+Shift+R         |^⇧R |M-S-R        |Replace all
-- Ctrl+Alt+F               |^⌘F |M-^F         |Find incremental
-- Ctrl+Shift+F             |⌘⇧F |None         |Find in files
-- Ctrl+Alt+G               |^⌘G |None         |Goto next file found
-- Ctrl+Alt+Shift+G         |^⌘⇧G|None         |Goto previous file found
-- Ctrl+J                   |⌘J  |^J           |Jump to line
-- **Tools**       |       |             |
-- Ctrl+E          |⌘E     |M-C          |Command entry
-- Ctrl+Shift+E    |⌘⇧E    |M-S-C        |Select command
-- Ctrl+R          |⌘R     |^R           |Run
-- Ctrl+Shift+R    |⌘⇧R    |M-^R         |Compile
-- Ctrl+Alt+E      |^⌘E    |M-X          |Next Error
-- Ctrl+Alt+Shift+E|^⌘⇧E   |M-S-X        |Previous Error
-- Ctrl+Space      |⌥⎋     |^Space       |Complete symbol
-- Ctrl+H          |^H     |M-H<br/>M-S-H|Show documentation
-- Tab             |⇥      |Tab          |Expand snippet or next placeholder
-- Ctrl+K          |⌥⇥     |M-K          |Insert snippet...
-- Shift+Tab       |⇧⇥     |S-Tab        |Previous snippet placeholder
-- Ctrl+Shift+K    |⌥⇧⇥    |M-S-K        |Cancel snippet
-- Ctrl+F2         |⌘F2    |F1           |Toggle bookmark
-- Ctrl+Shift+F2   |⌘⇧F2   |F6           |Clear bookmarks
-- F2              |F2     |F2           |Next bookmark
-- Shift+F2        |⇧F2    |F3           |Previous bookmark
-- Alt+F2          |⌥F2    |F4           |Goto bookmark...
-- Ctrl+U          |⌘U     |^U           |Snapopen `_USERHOME`
-- None            |None   |None         |Snapopen `_HOME`
-- Ctrl+Alt+Shift+O|^⌘⇧O   |M-S-O        |Snapopen current directory
-- Ctrl+I          |⌘I     |None         |Show style
-- **Buffer**      |      |             |
-- Ctrl+Tab        |^⇥    |M-N          |Next buffer
-- Ctrl+Shift+Tab  |^⇧⇥   |M-P          |Previous buffer
-- Ctrl+B          |⌘B    |M-B<br/>M-S-B|Switch to buffer...
-- None            |None  |None         |Tab width: 2
-- None            |None  |None         |Tab width: 3
-- None            |None  |None         |Tab width: 4
-- None            |None  |None         |Tab width: 8
-- Ctrl+Alt+Shift+T|^⇧T   |M-T<br/>M-S-T|Toggle use tabs
-- Ctrl+Alt+I      |^I    |M-I          |Convert indentation
-- None            |None  |None         |CR+LF EOL mode
-- None            |None  |None         |CR EOL mode
-- None            |None  |None         |LF EOL mode
-- None            |None  |None         |UTF-8 encoding
-- None            |None  |None         |ASCII encoding
-- None            |None  |None         |ISO-8859-1 encoding
-- None            |None  |None         |MacRoman encoding
-- None            |None  |None         |UTF-16 encoding
-- Ctrl+Shift+L    |⌘⇧L   |M-S-L        |Select lexer...
-- F5              |F5    |^L<br/>F5    |Refresh syntax highlighting
-- **View**                 |         |                 |
-- Ctrl+Alt+N               |^⌥⇥      |M-^V N           |Next view
-- Ctrl+Alt+P               |^⌥⇧⇥     |M-^V P           |Previous view
-- Ctrl+Alt+S<br/>Ctrl+Alt+H|^S       |M-^V S<br/>M-^V H|Split view horizontal
-- Ctrl+Alt+V               |^V       |M-^V V           |Split view vertical
-- Ctrl+Alt+W               |^W       |M-^V W           |Unsplit view
-- Ctrl+Alt+Shift+W         |^⇧W      |M-^V S-W         |Unsplit all views
-- Ctrl+Alt++<br/>Ctrl+Alt+=|^+<br/>^=|M-^V +<br/>M-^V =|Grow view
-- Ctrl+Alt+-               |^-       |M-^V -           |Shrink view
-- Ctrl+*                   |⌘*       |M-*              |Toggle current fold
-- Ctrl+Alt+Enter           |^↩       |None             |Toggle view EOL
-- Ctrl+Alt+\\              |^\\      |None             |Toggle wrap mode
-- Ctrl+Alt+Shift+I         |^⇧I      |N/A              |Toggle indent guides
-- Ctrl+Alt+Shift+S         |^⇧S      |None             |Toggle view whitespace
-- Ctrl+Alt+Shift+V         |^⇧V      |None             |Toggle virtual space
-- Ctrl+=                   |⌘=       |N/A              |Zoom in
-- Ctrl+-                   |⌘-       |N/A              |Zoom out
-- Ctrl+0                   |⌘0       |N/A              |Reset zoom
-- **Help**|    |    |
-- F1      |F1  |None|Open manual
-- Shift+F1|⇧F1 |None|Open LuaDoc
-- None    |None|None|About
-- **Movement**    |            |            |
-- Down            |⇣<br/>^N    |^N<br/>Down |Line down
-- Shift+Down      |⇧⇣<br/>^⇧N  |S-Down      |Line down extend selection
-- Ctrl+Down       |^⇣          |^Down       |Scroll line down
-- Alt+Shift+Down  |⌥⇧⇣         |M-S-Down    |Line down extend rect. selection
-- Up              |⇡<br/>^P    |^P<br/>Up   |Line up
-- Shift+Up        |⇧⇡<br/>^⇧P  |S-Up        |Line up extend selection
-- Ctrl+Up         |^⇡          |^Up         |Scroll line up
-- Alt+Shift+Up    |⌥⇧⇡         |M-S-Up      |Line up extend rect. selection
-- Left            |⇠<br/>^B    |^B<br/>Left |Char left
-- Shift+Left      |⇧⇠<br/>^⇧B  |S-Left      |Char left extend selection
-- Ctrl+Left       |^⇠<br/>^⌘B  |^Left       |Word left
-- Ctrl+Shift+Left |^⇧⇠<br/>^⌘⇧B|S-^Left     |Word left extend selection
-- Alt+Shift+Left  |⌥⇧⇠         |M-S-Left    |Char left extend rect. selection
-- Right           |⇢<br/>^F    |^F<br/>Right|Char right
-- Shift+Right     |⇧⇢<br/>^⇧F  |S-Right     |Char right extend selection
-- Ctrl+Right      |^⇢<br/>^⌘F  |^Right      |Word right
-- Ctrl+Shift+Right|^⇧⇢<br/>^⌘⇧F|S-^Right    |Word right extend selection
-- Alt+Shift+Right |⌥⇧⇢         |M-S-Right   |Char right extend rect. selection
-- Home            |⌘⇠<br/>^A   |^A<br/>Home |Line start
-- Shift+Home      |⌘⇧⇠<br/>^⇧A |M-S-A       |Line start extend selection
-- Ctrl+Home       |⌘⇡<br/>⌘↖   |M-^A        |Document start
-- Ctrl+Shift+Home |⌘⇧⇡<br/>⌘⇧↖ |None        |Document start extend selection
-- Alt+Shift+Home  |⌥⇧↖         |None        |Line start extend rect. selection
-- End             |⌘⇢<br/>^E   |^E<br/>End  |Line end
-- Shift+End       |⌘⇧⇢<br/>^⇧E |M-S-E       |Line end extend selection
-- Ctrl+End        |⌘⇣<br/>⌘↘   |M-^E        |Document end
-- Ctrl+Shift+End  |⌘⇧⇣<br/>⌘⇧↘ |None        |Document end extend selection
-- Alt+Shift+End   |⌥⇧↘         |None        |Line end extend rect. selection
-- PgUp            |⇞           |PgUp        |Page up
-- Shift+PgUp      |⇧⇞          |M-S-U       |Page up extend selection
-- Alt+Shift+PgUp  |⌥⇧⇞         |None        |Page up extend rect. selection
-- PgDn            |⇟           |PgDn        |Page down
-- Shift+PgDn      |⇧⇟          |M-S-D       |Page down extend selection
-- Alt+Shift+PgDn  |⌥⇧⇟         |None        |Page down extend rect. selection
-- Ctrl+Del        |⌘⌦          |^Del        |Delete word right
-- Ctrl+Shift+Del  |⌘⇧⌦         |S-^Del      |Delete line right
-- Ins             |Ins         |Ins         |Toggle overtype
-- Bksp            |⌫<br/>⇧⌫    |^H<br/>Bksp |Delete back
-- Ctrl+Bksp       |⌘⌫          |None        |Delete word left
-- Ctrl+Shift+Bksp |⌘⇧⌫         |None        |Delete line left
-- Tab             |⇥           |Tab<br/>^I  |Insert tab or indent
-- Shift+Tab       |⇧⇥          |S-Tab       |Dedent
-- None            |^K          |^K          |Cut to line end
-- None            |^L          |None        |Center line vertically
-- N/A             |N/A         |^^          |Mark text at the caret position
-- N/A             |N/A         |^]          |Swap caret and mark anchor
-- **Other**                |    |    |
-- Ctrl+Shift+U *xxxx* Enter|None|None|Input Unicode character U-*xxxx*.
-- **Entry Fields**|               |            |
-- Left            |⇠<br/>^B       |^B<br/>Left |Cursor left
-- Right           |⇢<br/>^F       |^F<br/>Right|Cursor right
-- Del             |⌦              |Del         |Delete forward
-- Bksp            |⌫              |^H<br/>Bksp |Delete back
-- Ctrl+V          |⌘V             |^V          |Paste
-- N/A             |N/A            |^X          |Cut all
-- N/A             |N/A            |^Y          |Copy all
-- N/A             |N/A            |^U          |Erase all
-- Home            |↖<br/>⌘⇠<br/>^A|^A          |Home
-- End             |↘<br/>⌘⇢<br/>^E|^E          |End
-- N/A             |N/A            |^T          |Transpose characters
-- N/A             |N/A            |^L          |Refresh
-- **Find Fields**|   |     |
-- N/A            |N/A|Tab  |Focus find buttons
-- N/A            |N/A|S-Tab|Focus replace buttons
-- Tab            |⇥  |Down |Focus replace field
-- Shift+Tab      |⇧⇥ |Up   |Focus find field
-- Down           |⇣  |^P   |Cycle back through find/replace history
-- Up             |⇡  |^N   |Cycle forward through find/replace history
-- N/A            |N/A|F1   |Toggle "Match Case"
-- N/A            |N/A|F2   |Toggle "Whole Word"
-- N/A            |N/A|F3   |Toggle "Lua Pattern"
-- N/A            |N/A|F4   |Toggle "Find in Files"
--
-- †: Ctrl+Enter in Win32 curses.
module('textadept.keys')]]

-- Utility functions.
M.utils = {
  delete_word = function()
    textadept.editing.select_word()
    buffer:delete_back()
  end,
  enclose_as_xml_tags = function()
    textadept.editing.enclose('<', '>')
    local pos = buffer.current_pos
    while buffer.char_at[pos - 1] ~= 60 do pos = pos - 1 end -- '<'
    buffer:insert_text(-1, '</'..buffer:text_range(pos, buffer.current_pos))
  end,
  find_in_files = function()
    ui.find.in_files = true
    ui.find.focus()
  end,
  select_command = function() textadept.menu.select_command() end,
  snapopen_filedir = function()
    if buffer.filename then io.snapopen(buffer.filename:match('^(.+)[/\\]')) end
  end,
  show_style = function()
    local style = buffer.style_at[buffer.current_pos]
    local text = string.format("%s %s\n%s %s (%d)", _L['Lexer'],
                               buffer:get_lexer(true), _L['Style'],
                               buffer.style_name[style], style)
    buffer:call_tip_show(buffer.current_pos, text)
  end,
  set_indentation = function(i)
    buffer.tab_width = i
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  toggle_property = function(property, i)
    local state = buffer[property]
    if type(state) == 'boolean' then
      buffer[property] = not state
    elseif type(state) == 'number' then
      buffer[property] = state == 0 and (i or 1) or 0
    end
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  set_encoding = function(encoding)
    io.set_buffer_encoding(encoding)
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  set_eol_mode = function(mode)
    buffer.eol_mode = mode
    buffer:convert_eols(mode)
    events.emit(events.UPDATE_UI) -- for updating statusbar
  end,
  unsplit_all = function() while view:unsplit() do end end,
  grow = function(i) if view.size then view.size = view.size + i end end,
  shrink = function(i) if view.size then view.size = view.size - i end end,
  toggle_current_fold = function()
    buffer:toggle_fold(buffer:line_from_position(buffer.current_pos))
  end,
  reset_zoom = function() buffer.zoom = 0 end,
  open_webpage = function(url)
    if WIN32 then
      local p = io.popen(string.format('start "" "%s"', url))
      assert(p, _L['Error loading webpage:']..url)
      p:close()
    else
      local _, _, code = os.execute(string.format(OSX and 'open "file://%s"' or
                                                  'xdg-open "%s" &', url))
      assert(code == 0, _L['Error loading webpage:']..url)
    end
  end,
  cut_to_eol = function()
    buffer:line_end_extend()
    buffer:cut()
  end
}

local keys, buffer, view = keys, buffer, view
local editing, utils = textadept.editing, M.utils
local OSX, CURSES = OSX, CURSES

-- The following buffer functions need to be constantized in order for menu
-- items to identify the key associated with the functions.
local menu_buffer_functions = {
  'undo', 'redo', 'cut', 'copy', 'paste', 'line_duplicate', 'clear',
  'select_all', 'upper_case', 'lower_case', 'move_selected_lines_up',
  'move_selected_lines_down', 'zoom_in', 'zoom_out', 'colourise'
}
for _, f in ipairs(menu_buffer_functions) do buffer[f] = buffer[f] end

-- Windows and Linux key bindings.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:   A B C         H              p  Q     T ~ V   X Y  _   ) ] }   +
-- a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=\n\s
-- ca: aAbBcCdD   F      jJkKlLmM N   PqQ    t       xXy zZ_"'()[]{}<>*  /   \s
--
-- CTRL = 'c' (Control ^)
-- ALT = 'a' (Alt)
-- META = [unused]
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Control, Alt, Shift, and 'a' = 'caA'
-- Control, Shift, and '\t' = 'cs\t'
--
-- Mac OSX key bindings.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- m:   A B C        ~    JkK  ~M    p  ~    tT U V   XyY  _   ) ] }   +   ~~\n
-- c:      cC D    gG H  J K L    oO  qQ             xXyYzZ_   ) ] }  *  /
-- cm: aAbBcC~D   F  ~HiIjJkKlL~MnN  pPq~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=\t\n
--
-- CTRL = 'c' (Control ^)
-- ALT = 'a' (Alt/option ⌥)
-- META = 'm' (Command ⌘)
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Command, Option, Shift, and 'a' = 'amA'
-- Command, Shift, and '\t' = 'ms\t'
--
-- Curses key bindings.
--
-- Key bindings available depend on your implementation of curses.
--
-- For ncurses (Linux, Mac OSX, BSD):
--   * The only Control keys recognized are 'ca'-'cz', 'c@', 'c\\', 'c]', 'c^',
--     and 'c_'.
--   * Control+Shift and Control+Meta+Shift keys are not recognized.
--   * Modifiers for function keys F1-F12 are not recognized.
-- For pdcurses (Win32):
--   * Control+Shift+Letter keys are not recognized. Other Control+Shift keys
--     are.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:        g~~   ~
-- cm:  bcd  g~~ k ~  pq  t   xyz
-- m:          e          J            qQ  sS  u vVw   yYzZ_          +
-- Note: m[befhstv] may be used by Linux/BSD GUI terminals for menu access.
--
-- CTRL = 'c' (Control ^)
-- ALT = [unused]
-- META = 'm' (Alt)
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Control, Meta, and 'a' = 'cma'

-- File.
keys[not OSX and (not CURSES and 'cn' or 'cmn') or 'mn'] = buffer.new
keys[not OSX and 'co' or 'mo'] = io.open_file
keys[not OSX and not CURSES and 'cao' or 'cmo'] = io.open_recent_file
keys[not OSX and (not CURSES and 'cO' or 'mo') or 'mO'] = io.reload_file
keys[not OSX and 'cs' or 'ms'] = io.save_file
keys[not OSX and (not CURSES and 'cS' or 'cms') or 'mS'] = io.save_file_as
-- TODO: io.save_all_files
keys[not OSX and 'cw' or 'mw'] = io.close_buffer
keys[not OSX and (not CURSES and 'cW' or 'cmw') or 'mW'] = io.close_all_buffers
-- TODO: textadept.sessions.load
-- TODO: textadept.sessions.save
keys[not OSX and 'cq' or 'mq'] = quit

-- Edit.
keys[not OSX and 'cz' or 'mz'] = buffer.undo
if not OSX then keys.cy = buffer.redo end
if not CURSES then keys[not OSX and 'cZ' or 'mZ'] = buffer.redo end
keys[not OSX and 'cx' or 'mx'] = buffer.cut
keys[not OSX and 'cc' or 'mc'] = buffer.copy
keys[not OSX and 'cv' or 'mv'] = buffer.paste
if not CURSES then keys[not OSX and 'cd' or 'md'] = buffer.line_duplicate end
keys.del = buffer.clear
keys[not OSX and (not CURSES and 'adel' or 'mdel')
             or 'cdel'] = utils.delete_word
keys[not OSX and not CURSES and 'ca' or 'ma'] = buffer.select_all
keys[not CURSES and 'cm' or 'mm'] = editing.match_brace
keys[not OSX and (not CURSES and 'c\n' or 'cmj')
             or 'cesc'] = editing.autocomplete_word
if CURSES and WIN32 then keys['c\r'] = keys['cmj'] end
if not CURSES then
  keys[not OSX and 'caH' or 'mH'] = editing.highlight_word
end
keys[not OSX and not CURSES and 'c/' or 'm/'] = editing.block_comment
keys.ct = editing.transpose_chars
keys[not OSX and (not CURSES and 'cJ' or 'mj') or 'cj'] = editing.join_lines
keys[not OSX and (not CURSES and 'c|' or 'c\\')
             or 'm|'] = {ui.command_entry.enter_mode, 'filter_through'}
-- Select.
keys[not CURSES and 'cM' or 'mM'] = {editing.match_brace, 'select'}
keys[not OSX and not CURSES and 'c<'
                            or 'm<'] = {editing.select_enclosed, '>', '<'}
if not CURSES then
  keys[not OSX and 'c>' or 'm>'] = {editing.select_enclosed, '<', '>'}
end
keys[not OSX and not CURSES and "c'"
                            or "m'"] = {editing.select_enclosed, "'", "'"}
keys[not OSX and not CURSES and 'c"'
                            or 'm"'] = {editing.select_enclosed, '"', '"'}
keys[not OSX and not CURSES and 'c('
                            or 'm('] = {editing.select_enclosed, '(', ')'}
keys[not OSX and not CURSES and 'c['
                            or 'm['] = {editing.select_enclosed, '[', ']'}
keys[not OSX and not CURSES and 'c{'
                            or 'm{'] = {editing.select_enclosed, '{', '}'}
keys[not OSX and (not CURSES and 'cD' or 'mW') or 'mD'] = editing.select_word
keys[not OSX and not CURSES and 'cN' or 'mN'] = editing.select_line
keys[not OSX and not CURSES and 'cP' or 'mP'] = editing.select_paragraph
keys[not OSX and not CURSES and 'cI' or 'mI'] = editing.select_indented_block
-- Selection.
keys[not OSX and (not CURSES and 'cau' or 'cmu') or 'cu'] = buffer.upper_case
keys[not OSX and (not CURSES and 'caU' or 'cml') or 'cU'] = buffer.lower_case
keys[not OSX and (not CURSES and 'a<' or 'm>')
             or 'c<'] = utils.enclose_as_xml_tags
if not CURSES then
  keys[not OSX and 'a>' or 'c>'] = {editing.enclose, '<', ' />'}
  keys[not OSX and "a'" or "c'"] = {editing.enclose, "'", "'"}
  keys[not OSX and 'a"' or 'c"'] = {editing.enclose, '"', '"'}
end
keys[not OSX and (not CURSES and 'a(' or 'm)')
             or 'c('] = {editing.enclose, '(', ')'}
keys[not OSX and (not CURSES and 'a[' or 'm]')
             or 'c['] = {editing.enclose, '[', ']'}
keys[not OSX and (not CURSES and 'a{' or 'm}')
             or 'c{'] = {editing.enclose, '{', '}'}
keys.csup = buffer.move_selected_lines_up
keys.csdown = buffer.move_selected_lines_down

-- Search.
keys[not OSX and not CURSES and 'cf' or 'mf'] = ui.find.focus
if CURSES then keys.mF = keys.mf end -- in case mf is used by GUI terminals
keys[not OSX and not CURSES and 'cg' or 'mg'] = ui.find.find_next
if not OSX and not CURSES then keys.f3 = keys.cg end
keys[not OSX and not CURSES and 'cG' or 'mG'] = ui.find.find_prev
if not OSX and not CURSES then keys.sf3 = keys.cG end
keys[not OSX and (not CURSES and 'car' or 'mr') or 'cr'] = ui.find.replace
keys[not OSX and (not CURSES and 'caR' or 'mR') or 'cR'] = ui.find.replace_all
-- Find Next is an when find pane is focused in GUI.
-- Find Prev is ap when find pane is focused in GUI.
-- Replace is ar when find pane is focused in GUI.
-- Replace All is aa when find pane is focused in GUI.
keys[not OSX and not CURSES and 'caf' or 'cmf'] = ui.find.find_incremental
if not CURSES then keys[not OSX and 'cF' or 'mF'] = utils.find_in_files end
-- Find in Files is ai when find pane is focused in GUI.
if not CURSES then
  keys[not OSX and 'cag' or 'cmg'] = {ui.find.goto_file_found, false, true}
  keys[not OSX and 'caG' or 'cmG'] = {ui.find.goto_file_found, false, false}
end
keys[not OSX and 'cj' or 'mj'] = editing.goto_line

-- Tools.
keys[not OSX and (not CURSES and 'ce' or 'mc')
             or 'me'] = {ui.command_entry.enter_mode, 'lua_command'}
keys[not OSX and (not CURSES and 'cE' or 'mC') or 'mE'] = utils.select_command
keys[not OSX and 'cr' or 'mr'] = textadept.run.run
keys[not OSX and (not CURSES and 'cR' or 'cmr') or 'mR'] = textadept.run.compile
keys[not OSX and (not CURSES and 'cae' or 'mx')
             or 'cme'] = {textadept.run.goto_error, false, true}
keys[not OSX and (not CURSES and 'caE' or 'mX')
             or 'cmE'] = {textadept.run.goto_error, false, false}
-- Adeptsense.
keys[not OSX and ((not CURSES or WIN32) and 'c ' or 'c@')
             or 'aesc'] = textadept.adeptsense.complete
keys[not CURSES and 'ch' or 'mh'] = textadept.adeptsense.show_apidoc
if CURSES then keys.mH = keys.mh end -- in case mh is used by GUI terminals
-- Snippets.
keys[not OSX and (not CURSES and 'ck' or 'mk')
             or 'a\t'] = textadept.snippets._select
keys['\t'] = textadept.snippets._insert
keys['s\t'] = textadept.snippets._previous
keys[not OSX and (not CURSES and 'cK' or 'mK')
             or 'as\t'] = textadept.snippets._cancel_current
-- Bookmark.
keys[not OSX and (not CURSES and 'cf2' or 'f1')
             or 'mf2'] = textadept.bookmarks.toggle
keys[not OSX and (not CURSES and 'csf2' or 'f6')
             or 'msf2'] = textadept.bookmarks.clear
keys.f2 = {textadept.bookmarks.goto_mark, true}
keys[not CURSES and 'sf2' or 'f3'] = {textadept.bookmarks.goto_mark, false}
keys[not CURSES and 'af2' or 'f4'] = textadept.bookmarks.goto_mark
-- Snapopen.
keys[not OSX and 'cu' or 'mu'] = {io.snapopen, _USERHOME}
-- TODO: {io.snapopen, _HOME}
keys[not OSX and (not CURSES and 'caO' or 'mO')
             or 'cmO'] = utils.snapopen_filedir
if not CURSES then keys[not OSX and 'ci' or 'mi'] = utils.show_style end

-- Buffer.
keys[not CURSES and 'c\t' or 'mn'] = {view.goto_buffer, view, 1, true}
keys[not CURSES and 'cs\t' or 'mp'] = {view.goto_buffer, view, -1, true}
keys[not OSX and not CURSES and 'cb' or 'mb'] = ui.switch_buffer
if CURSES then keys.mB = keys.mb end -- in case mb is used by GUI terminals
-- Indentation.
-- TODO: {utils.set_indentation, 2}
-- TODO: {utils.set_indentation, 3}
-- TODO: {utils.set_indentation, 4}
-- TODO: {utils.set_indentation, 8}
keys[not OSX and (not CURSES and 'caT' or 'mt')
             or 'cT'] = {utils.toggle_property, 'use_tabs'}
if CURSES then keys.mT = keys.mt end -- in case mt is used by GUI terminals
keys[not OSX and (not CURSES and 'cai' or 'mi')
             or 'ci'] = editing.convert_indentation
-- EOL Mode.
-- TODO: {utils.set_eol_mode, buffer.EOL_CRLF}
-- TODO: {utils.set_eol_mode, buffer.EOL_CR}
-- TODO: {utils.set_eol_mode, buffer.EOL_LF}
-- Encoding.
-- TODO: {utils.set_encoding, 'UTF-8'}
-- TODO: {utils.set_encoding, 'ASCII'}
-- TODO: {utils.set_encoding, 'ISO-8859-1'}
-- TODO: {utils.set_encoding, 'MacRoman'}
-- TODO: {utils.set_encoding, 'UTF-16LE'}
keys[not OSX and not CURSES and 'cL'
                            or 'mL'] = textadept.file_types.select_lexer
keys.f5 = {buffer.colourise, buffer, 0, -1}
if CURSES then keys.cl = keys.f5 end

-- View.
local view_next, view_prev = {ui.goto_view, 1, true}, {ui.goto_view, -1, true}
local view_splith, view_splitv = {view.split, view}, {view.split, view, true}
local view_unsplit = {view.unsplit, view}
if not CURSES then
  keys[not OSX and 'can' or 'ca\t'] = view_next
  keys[not OSX and 'cap' or 'cas\t'] = view_prev
  keys[not OSX and 'cas' or 'cs'] = view_splith
  if not OSX then keys.cah = view_splith end
  keys[not OSX and 'cav' or 'cv'] = view_splitv
  keys[not OSX and 'caw' or 'cw'] = view_unsplit
  keys[not OSX and 'caW' or 'cW'] = utils.unsplit_all
  keys[not OSX and 'ca+' or 'c+'] = {utils.grow, 10}
  keys[not OSX and 'ca=' or 'c='] = {utils.grow, 10}
  keys[not OSX and 'ca-' or 'c-'] = {utils.shrink, 10}
else
  keys.cmv = {
    n = view_next, p = view_prev,
    s = view_splith, v = view_splitv,
    w = view_unsplit, W = utils.unsplit_all,
    ['+'] = {utils.grow, 1}, ['='] = {utils.grow, 1}, ['-'] = {utils.shrink, 1}
  }
  if not OSX then keys.cmv.h = view_splith end
end
keys[not OSX and not CURSES and 'c*' or 'm*'] = utils.toggle_current_fold
if not CURSES then
  keys[not OSX and 'ca\n' or 'c\n'] = {utils.toggle_property, 'view_eol'}
  if not OSX then keys['ca\n\r'] = keys['ca\n'] end
  keys[not OSX and 'ca\\' or 'c\\'] = {utils.toggle_property, 'wrap_mode'}
  keys[not OSX and 'caI' or 'cI'] =
    {utils.toggle_property, 'indentation_guides'}
  keys[not OSX and 'caS' or 'cS'] = {utils.toggle_property, 'view_ws'}
  keys[not OSX and 'caV' or 'cV'] =
    {utils.toggle_property, 'virtual_space_options', buffer.VS_USERACCESSIBLE}
end
keys[not OSX and not CURSES and 'c=' or 'm='] = buffer.zoom_in
keys[not OSX and not CURSES and 'c-' or 'm-'] = buffer.zoom_out
keys[not OSX and not CURSES and 'c0' or 'm0'] = utils.reset_zoom

-- Help.
if not CURSES then
  keys.f1 = {utils.open_webpage, _HOME..'/doc/01_Introduction.html'}
  keys.sf1 = {utils.open_webpage, _HOME..'/doc/api/index.html'}
end

-- Movement commands.
if OSX then
  keys.cf, keys.cF = buffer.char_right, buffer.char_right_extend
  keys.cmf, keys.cmF = buffer.word_right, buffer.word_right_extend
  keys.cb, keys.cB = buffer.char_left, buffer.char_left_extend
  keys.cmb, keys.cmB = buffer.word_left, buffer.word_left_extend
  keys.cn, keys.cN = buffer.line_down, buffer.line_down_extend
  keys.cp, keys.cP = buffer.line_up, buffer.line_up_extend
  keys.ca, keys.cA = buffer.vc_home, buffer.vc_home_extend
  keys.ce, keys.cE = buffer.line_end, buffer.line_end_extend
  keys.aright, keys.aleft = buffer.word_right, buffer.word_left
  keys.cd = buffer.clear
  keys.ck = utils.cut_to_eol
  keys.cl = buffer.vertical_centre_caret
  -- GTKOSX reports Fn-key as a single keycode which confuses Scintilla. Do
  -- not propagate it.
  keys.fn = function() return true end
elseif CURSES then
  keys['c^'] = function() _G.buffer.selection_mode = 0 end
  keys['c]'] = buffer.swap_main_anchor_caret
  keys.cf, keys.cb = buffer.char_right, buffer.char_left
  keys.cn, keys.cp = buffer.line_down, buffer.line_up
  keys.ca, keys.ce = buffer.vc_home, buffer.line_end
  keys.mA, keys.mE = buffer.vc_home_extend, buffer.line_end_extend
  keys.mU, keys.mD = buffer.page_up_extend, buffer.page_down_extend
  keys.cma, keys.cme = buffer.document_start, buffer.document_end
  keys.cd, keys.md = buffer.clear, utils.delete_word
  keys.ck = utils.cut_to_eol
end

-- Modes.
keys.lua_command = {
  ['\t'] = ui.command_entry.complete_lua,
  ['\n'] = {ui.command_entry.finish_mode, ui.command_entry.execute_lua}
}
keys.filter_through = {
  ['\n'] = {ui.command_entry.finish_mode, editing.filter_through},
}
keys.find_incremental = {
  ['\n'] = function()
    ui.find.find_incremental(ui.command_entry.entry_text, true, true)
  end,
  ['cr'] = function()
    ui.find.find_incremental(ui.command_entry.entry_text, false, true)
  end,
  ['\b'] = function()
    ui.find.find_incremental(ui.command_entry.entry_text:sub(1, -2), true)
    return false -- propagate
  end
}
-- Add the character for any key pressed without modifiers to incremental find.
setmetatable(keys.find_incremental, {__index = function(t, k)
               if #k > 1 and k:find('^[cams]*.+$') then return end
               ui.find.find_incremental(ui.command_entry.entry_text..k, true)
             end})

return M

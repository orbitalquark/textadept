-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Defines key commands for Textadept.
-- This set of key commands is pretty standard among other text editors, at
-- least for basic editing commands and movements.
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
-- **Edit**                |         |              |
-- Ctrl+Z<br/>Alt+Bksp     |⌘Z       |^Z^(†)<br/>M-Z|Undo
-- Ctrl+Y<br/>Ctrl+Shift+Z |⌘⇧Z      |^Y<br/>M-S-Z  |Redo
-- Ctrl+X<br/>Shift+Del    |⌘X<br/>⇧⌦|^X            |Cut
-- Ctrl+C<br/>Ctrl+Ins     |⌘C       |^C            |Copy
-- Ctrl+V<br/>Shift+Ins    |⌘V       |^V            |Paste
-- Ctrl+D                  |⌘D       |None          |Duplicate line
-- Del                     |⌦<br/>^D |Del<br/>^D    |Delete
-- Alt+Del                 |^⌦       |M-Del<br/>M-D |Delete word
-- Ctrl+A                  |⌘A       |M-A           |Select all
-- Ctrl+M                  |^M       |M-M           |Match brace
-- Ctrl+Enter              |^Esc     |M-Enter^(‡)   |Complete word
-- Ctrl+Alt+Shift+H        |⌘⇧H      |None          |Highlight word
-- Ctrl+/                  |^/       |M-/           |Toggle block comment
-- Ctrl+T                  |^T       |^T            |Transpose characters
-- Ctrl+Shift+J            |^J       |M-J           |Join lines
-- Ctrl+&#124;             |⌘&#124;  |^\            |Filter text through
-- Ctrl+Shift+M            |^⇧M      |M-S-M         |Select between delimiters
-- Ctrl+<                  |⌘<       |M-<           |Select between XML tags
-- Ctrl+>                  |⌘>       |None          |Select in XML tag
-- Ctrl+Shift+D            |⌘⇧D      |M-S-W         |Select word
-- Ctrl+Shift+N            |⌘⇧N      |M-S-N         |Select line
-- Ctrl+Shift+P            |⌘⇧P      |M-S-P         |Select paragraph
-- Ctrl+Alt+U              |^U       |M-^U          |Upper case selection
-- Ctrl+Alt+Shift+U        |^⇧U      |M-^L          |Lower case selection
-- Alt+<                   |^<       |M->           |Enclose as XML tags
-- Alt+>                   |^>       |None          |Enclose as single XML tag
-- Alt+"                   |^"       |None          |Enclose in double quotes
-- Alt+'                   |^'       |None          |Enclose in single quotes
-- Alt+(                   |^(       |M-)           |Enclose in parentheses
-- Alt+[                   |^[       |M-]           |Enclose in brackets
-- Alt+{                   |^{       |M-}           |Enclose in braces
-- Ctrl+Shift+Up           |^⇧⇡      |S-^Up         |Move selected lines up
-- Ctrl+Shift+Down         |^⇧⇣      |S-^Down       |Move selected lines down
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
-- Ctrl+Shift+A    |⌘⇧A    |None         |Set Arguments...
-- Ctrl+Shift+B    |⌘⇧B    |M-^B         |Build
-- Ctrl+Shift+X    |⌘⇧X    |M-^X         |Stop
-- Ctrl+Alt+E      |^⌘E    |M-X          |Next Error
-- Ctrl+Alt+Shift+E|^⌘⇧E   |M-S-X        |Previous Error
-- Ctrl+Space      |⌥Esc   |^Space       |Complete symbol
-- Ctrl+H          |^H     |M-H<br/>M-S-H|Show documentation
-- Tab             |⇥      |Tab          |Expand snippet or next placeholder
-- Ctrl+K          |⌥⇥     |M-K          |Insert snippet...
-- Shift+Tab       |⇧⇥     |S-Tab        |Previous snippet placeholder
-- Esc             |Esc    |Esc          |Cancel snippet
-- Ctrl+F2         |⌘F2    |F1           |Toggle bookmark
-- Ctrl+Shift+F2   |⌘⇧F2   |F6           |Clear bookmarks
-- F2              |F2     |F2           |Next bookmark
-- Shift+F2        |⇧F2    |F3           |Previous bookmark
-- Alt+F2          |⌥F2    |F4           |Goto bookmark...
-- Ctrl+U          |⌘U     |^U           |Quickly open `_USERHOME`
-- None            |None   |None         |Quickly open `_HOME`
-- Ctrl+Alt+Shift+O|^⌘⇧O   |M-S-O        |Quickly open current directory
-- Ctrl+Alt+Shift+P|^⌘⇧P   |M-^P         |Quickly open current project
-- Ctrl+I          |⌘I     |M-S-I        |Show style
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
-- None            |None  |None         |LF EOL mode
-- None            |None  |None         |UTF-8 encoding
-- None            |None  |None         |ASCII encoding
-- None            |None  |None         |ISO-8859-1 encoding
-- None            |None  |None         |UTF-16 encoding
-- Ctrl+Alt+Enter  |^↩    |None         |Toggle view EOL
-- Ctrl+Alt+\\     |^\\   |None         |Toggle wrap mode
-- Ctrl+Alt+Shift+S|^⇧S   |None         |Toggle view whitespace
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
-- Ctrl+Alt+Shift+I         |^⇧I      |N/A              |Toggle indent guides
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
-- **UTF-8 Input**          |            |                |
-- Ctrl+Shift+U *xxxx* Enter|⌘⇧U *xxxx* ↩|M-U *xxxx* Enter|Insert U-*xxxx* char.
-- **Find Fields**|               |            |
-- Left           |⇠<br/>^B       |^B<br/>Left |Cursor left
-- Right          |⇢<br/>^F       |^F<br/>Right|Cursor right
-- Del            |⌦              |Del         |Delete forward
-- Bksp           |⌫              |^H<br/>Bksp |Delete back
-- Ctrl+V         |⌘V             |^V          |Paste
-- N/A            |N/A            |^X          |Cut all
-- N/A            |N/A            |^Y          |Copy all
-- N/A            |N/A            |^U          |Erase all
-- Home           |↖<br/>⌘⇠<br/>^A|^A          |Home
-- End            |↘<br/>⌘⇢<br/>^E|^E          |End
-- N/A            |N/A            |^T          |Transpose characters
-- N/A            |N/A            |Tab         |Focus find buttons
-- N/A            |N/A            |S-Tab       |Focus replace buttons
-- Tab            |⇥              |Down        |Focus replace field
-- Shift+Tab      |⇧⇥             |Up          |Focus find field
-- Down           |⇣              |^P          |Cycle back through history
-- Up             |⇡              |^N          |Cycle forward through history
-- N/A            |N/A            |F1          |Toggle "Match Case"
-- N/A            |N/A            |F2          |Toggle "Whole Word"
-- N/A            |N/A            |F3          |Toggle "Regex"
-- N/A            |N/A            |F4          |Toggle "Find in Files"
--
-- †: Some terminals interpret ^Z as suspend; see FAQ for workaround.
--
-- ‡: Ctrl+Enter in Win32 curses.
module('textadept.keys')]]

-- Windows and Linux key bindings.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:       C         H I   K        p  Q     T ~ V     Y  _   ) ] }   +
-- a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=\n\s
-- ca: aAbBcCdD   F      jJkKlLmM N    qQ    t       xXy zZ_"'()[]{}<>*  /   \s
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
-- m:       C        ~  I JkK  ~M    p  ~    tT   V    yY  _   ) ] }   +   ~~\n
-- c:      cC D    gG H   J K L    oO  qQ            xXyYzZ_   ) ] }  *  /
-- cm: aAbBcC~D   F  ~HiIjJkKlL~MnN  p q~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=\t\n
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
--   * The only Control keys recognized are 'ca'-'cz', 'c ', 'c\\', 'c]', 'c^',
--     and 'c_'.
--   * Control+Shift and Control+Meta+Shift keys are not recognized.
--   * Modifiers for function keys F1-F12 are not recognized.
-- For pdcurses (Win32):
--   * Control+Shift+Letter keys are not recognized. Other Control+Shift keys
--     are.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:        g~~   ~            ~
-- cm:   cd  g~~ k ~   q  t    yz
-- m:          e          J K          qQ  sS    vVw   yY  _          +
-- Note: m[befhstv] may be used by Linux/BSD GUI terminals for menu access.
--
-- CTRL = 'c' (Control ^)
-- ALT = [unused]
-- META = 'm' (Alt)
-- SHIFT = 's' (Shift ⇧)
-- ADD = ''
-- Control, Meta, and 'a' = 'cma'

local keys, OSX, GUI, CURSES, _L = keys, OSX, not CURSES, CURSES, _L

-- File.
keys[not OSX and (GUI and 'cn' or 'cmn') or 'mn'] = buffer.new
keys[not OSX and 'co' or 'mo'] = io.open_file
keys[not OSX and GUI and 'cao' or 'cmo'] = io.open_recent_file
keys[not OSX and (GUI and 'cO' or 'mo') or 'mO'] = io.reload_file
keys[not OSX and 'cs' or 'ms'] = io.save_file
keys[not OSX and (GUI and 'cS' or 'cms') or 'mS'] = io.save_file_as
-- TODO: io.save_all_files
keys[not OSX and 'cw' or 'mw'] = io.close_buffer
keys[not OSX and (GUI and 'cW' or 'cmw') or 'mW'] = io.close_all_buffers
-- TODO: textadept.sessions.load
-- TODO: textadept.sessions.save
keys[not OSX and 'cq' or 'mq'] = quit

-- Edit.
local m_edit = textadept.menu.menubar[_L['_Edit']]
keys[not OSX and 'cz' or 'mz'] = buffer.undo
if CURSES then keys.mz = keys.cz end -- ^Z suspends in some terminals
if not OSX then keys.cy = buffer.redo end
keys[not OSX and GUI and 'cZ' or 'mZ'] = buffer.redo
keys[not OSX and 'cx' or 'mx'] = buffer.cut
keys[not OSX and 'cc' or 'mc'] = buffer.copy
keys[not OSX and 'cv' or 'mv'] = textadept.editing.paste
if GUI then keys[not OSX and 'cd' or 'md'] = buffer.line_duplicate end
keys.del = buffer.clear
keys[not OSX and (GUI and 'adel' or 'mdel')
             or 'cdel'] = m_edit[_L['D_elete Word']][2]
keys[not OSX and GUI and 'ca' or 'ma'] = buffer.select_all
keys[GUI and 'cm' or 'mm'] = m_edit[_L['_Match Brace']][2]
keys[not OSX and ((GUI or WIN32) and 'c\n' or 'cmj')
             or 'cesc'] = m_edit[_L['Complete _Word']][2]
if GUI then
  keys[not OSX and 'caH' or 'mH'] = textadept.editing.highlight_word
end
keys[not OSX and GUI and 'c/' or 'm/'] = textadept.editing.block_comment
keys.ct = textadept.editing.transpose_chars
keys[not OSX and (GUI and 'cJ' or 'mj') or 'cj'] = textadept.editing.join_lines
keys[not OSX and (GUI and 'c|' or 'c\\')
             or 'm|'] = m_edit[_L['_Filter Through']][2]
-- Select.
local m_sel = m_edit[_L['_Select']]
keys[GUI and 'cM' or 'mM'] = m_sel[_L['Select between _Matching Delimiters']][2]
keys[not OSX and GUI and 'c<'
                     or 'm<'] = m_sel[_L['Select between _XML Tags']][2]
if GUI then
  keys[not OSX and 'c>' or 'm>'] = m_sel[_L['Select in XML _Tag']][2]
end
keys[not OSX and (GUI and 'cD' or 'mW') or 'mD'] = textadept.editing.select_word
keys[not OSX and GUI and 'cN' or 'mN'] = textadept.editing.select_line
keys[not OSX and GUI and 'cP' or 'mP'] = textadept.editing.select_paragraph
-- Selection.
m_sel = m_edit[_L['Selectio_n']]
keys[not OSX and (GUI and 'cau' or 'cmu') or 'cu'] = buffer.upper_case
keys[not OSX and (GUI and 'caU' or 'cml') or 'cU'] = buffer.lower_case
keys[not OSX and (GUI and 'a<' or 'm>')
             or 'c<'] = m_sel[_L['Enclose as _XML Tags']][2]
if GUI then
  keys[not OSX and 'a>' or 'c>'] = m_sel[_L['Enclose as Single XML _Tag']][2]
  keys[not OSX and "a'" or "c'"] = m_sel[_L['Enclose in Single _Quotes']][2]
  keys[not OSX and 'a"' or 'c"'] = m_sel[_L['Enclose in _Double Quotes']][2]
end
keys[not OSX and (GUI and 'a(' or 'm)')
             or 'c('] = m_sel[_L['Enclose in _Parentheses']][2]
keys[not OSX and (GUI and 'a[' or 'm]')
             or 'c['] = m_sel[_L['Enclose in _Brackets']][2]
keys[not OSX and (GUI and 'a{' or 'm}')
             or 'c{'] = m_sel[_L['Enclose in B_races']][2]
keys.csup = buffer.move_selected_lines_up
keys.csdown = buffer.move_selected_lines_down

-- Search.
local m_search = textadept.menu.menubar[_L['_Search']]
keys[not OSX and GUI and 'cf' or 'mf'] = m_search[_L['_Find']][2]
if CURSES then keys.mF = keys.mf end -- mf is used by some GUI terminals
keys[not OSX and GUI and 'cg' or 'mg'] = ui.find.find_next
if not OSX and GUI then keys.f3 = keys.cg end
keys[not OSX and GUI and 'cG' or 'mG'] = ui.find.find_prev
if not OSX and GUI then keys.sf3 = keys.cG end
keys[not OSX and (GUI and 'car' or 'mr') or 'cr'] = ui.find.replace
keys[not OSX and (GUI and 'caR' or 'mR') or 'cR'] = ui.find.replace_all
-- Find Next is an when find pane is focused in GUI.
-- Find Prev is ap when find pane is focused in GUI.
-- Replace is ar when find pane is focused in GUI.
-- Replace All is aa when find pane is focused in GUI.
keys[not OSX and GUI and 'caf' or 'cmf'] = ui.find.find_incremental
if GUI then
  keys[not OSX and 'cF' or 'mF'] = m_search[_L['Find in Fi_les']][2]
end
-- Find in Files is ai when find pane is focused in GUI.
if GUI then
  keys[not OSX and 'cag' or 'cmg'] = m_search[_L['Goto Nex_t File Found']][2]
  keys[not OSX and 'caG'
               or 'cmG'] = m_search[_L['Goto Previou_s File Found']][2]
end
keys[not OSX and 'cj' or 'mj'] = textadept.editing.goto_line

-- Tools.
local m_tools = textadept.menu.menubar[_L['_Tools']]
keys[not OSX and (GUI and 'ce' or 'mc')
             or 'me'] = m_tools[_L['Command _Entry']][2]
keys[not OSX and (GUI and 'cE' or 'mC')
             or 'mE'] = m_tools[_L['Select Co_mmand']][2]
keys[not OSX and 'cr' or 'mr'] = textadept.run.run
keys[not OSX and (GUI and 'cR' or 'cmr') or 'mR'] = textadept.run.compile
keys[not OSX and (GUI and 'cB' or 'cmb') or 'mB'] = textadept.run.build
if GUI then
  keys[not OSX and 'cA' or 'mA'] = m_tools[_L['Set _Arguments...']][2]
end
keys[not OSX and (GUI and 'cX' or 'cmx') or 'mX'] = textadept.run.stop
keys[not OSX and (GUI and 'cae' or 'mx')
             or 'cme'] = m_tools[_L['_Next Error']][2]
keys[not OSX and (GUI and 'caE' or 'mX')
             or 'cmE'] = m_tools[_L['_Previous Error']][2]
-- Bookmark.
local m_bookmark = m_tools[_L['_Bookmark']]
keys[not OSX and (GUI and 'cf2' or 'f1') or 'mf2'] = textadept.bookmarks.toggle
keys[not OSX and (GUI and 'csf2' or 'f6') or 'msf2'] = textadept.bookmarks.clear
keys.f2 = m_bookmark[_L['_Next Bookmark']][2]
keys[GUI and 'sf2' or 'f3'] = m_bookmark[_L['_Previous Bookmark']][2]
keys[GUI and 'af2' or 'f4'] = textadept.bookmarks.goto_mark
-- Quick Open.
local m_quick_open = m_tools[_L['Quick _Open']]
keys[not OSX and 'cu' or 'mu'] = m_quick_open[_L['Quickly Open _User Home']][2]
-- TODO: m_quick_open[_L['Quickly Open _Textadept Home']][2]
keys[not OSX and (GUI and 'caO' or 'mO')
             or 'cmO'] = m_quick_open[_L['Quickly Open _Current Directory']][2]
keys[not OSX and (GUI and 'caP' or 'cmp') or 'cmP'] = io.quick_open
-- Snippets.
keys[not OSX and (GUI and 'ck' or 'mk') or 'a\t'] = textadept.snippets._select
keys['\t'] = textadept.snippets._insert
keys['s\t'] = textadept.snippets._previous
keys.esc = textadept.snippets._cancel_current
-- Other.
keys[not OSX and 'c ' or 'aesc'] = m_tools[_L['_Complete Symbol']][2]
keys[GUI and 'ch' or 'mh'] = textadept.editing.show_documentation
if CURSES then keys.mH = keys.mh end -- mh is used by some GUI terminals
keys[not OSX and (GUI and 'ci' or 'mI') or 'mi'] = m_tools[_L['Show St_yle']][2]

-- Buffer.
local m_buffer = textadept.menu.menubar[_L['_Buffer']]
keys[GUI and 'c\t' or 'mn'] = m_buffer[_L['_Next Buffer']][2]
keys[GUI and 'cs\t' or 'mp'] = m_buffer[_L['_Previous Buffer']][2]
keys[not OSX and GUI and 'cb' or 'mb'] = ui.switch_buffer
if CURSES then keys.mB = keys.mb end -- mb is used by some GUI terminals
-- Indentation.
local m_indentation = m_buffer[_L['_Indentation']]
-- TODO: m_indentation[_L['Tab width: _2']][2]
-- TODO: m_indentation[_L['Tab width: _3']][2]
-- TODO: m_indentation[_L['Tab width: _4']][2]
-- TODO: m_indentation[_L['Tab width: _8']][2]
keys[not OSX and (GUI and 'caT' or 'mt')
             or 'cT'] = m_indentation[_L['_Toggle Use Tabs']][2]
if CURSES then keys.mT = keys.mt end -- mt is used by some GUI terminals
keys[not OSX and (GUI and 'cai' or 'mi')
             or 'ci'] = textadept.editing.convert_indentation
-- EOL Mode.
-- TODO: m_buffer[_L['_EOL Mode']][_L['CRLF']][2]
-- TODO: m_buffer[_L['_EOL Mode']][_L['LF']][2]
-- Encoding.
-- TODO: m_buffer[_L['E_ncoding']][_L['_UTF-8 Encoding']][2]
-- TODO: m_buffer[_L['E_ncoding']][_L['_ASCII Encoding']][2]
-- TODO: m_buffer[_L['E_ncoding']][_L['_ISO-8859-1 Encoding']][2]
-- TODO: m_buffer[_L['E_ncoding']][_L['UTF-1_6 Encoding']][2]
if GUI then
  keys[not OSX and 'ca\n' or 'c\n'] = m_buffer[_L['Toggle View _EOL']][2]
  keys[not OSX and 'ca\\' or 'c\\'] = m_buffer[_L['Toggle _Wrap Mode']][2]
  keys[not OSX and 'caS' or 'cS'] = m_buffer[_L['Toggle View White_space']][2]
end
keys[not OSX and GUI and 'cL' or 'mL'] = textadept.file_types.select_lexer
keys.f5 = m_buffer[_L['_Refresh Syntax Highlighting']][2]
if CURSES then keys.cl = keys.f5 end

-- View.
local m_view = textadept.menu.menubar[_L['_View']]
if GUI then
  keys[not OSX and 'can' or 'ca\t'] = m_view[_L['_Next View']][2]
  keys[not OSX and 'cap' or 'cas\t'] = m_view[_L['_Previous View']][2]
  keys[not OSX and 'cas' or 'cs'] = m_view[_L['Split View _Horizontal']][2]
  if not OSX then keys.cah = keys.cas end
  keys[not OSX and 'cav' or 'cv'] = m_view[_L['Split View _Vertical']][2]
  keys[not OSX and 'caw' or 'cw'] = m_view[_L['_Unsplit View']][2]
  keys[not OSX and 'caW' or 'cW'] = m_view[_L['Unsplit _All Views']][2]
  keys[not OSX and 'ca+' or 'c+'] = m_view[_L['_Grow View']][2]
  keys[not OSX and 'ca=' or 'c='] = keys[not OSX and 'ca+' or 'c+']
  keys[not OSX and 'ca-' or 'c-'] = m_view[_L['Shrin_k View']][2]
else
  keys.cmv = {
    n = m_view[_L['_Next View']][2],
    p = m_view[_L['_Previous View']][2],
    s = m_view[_L['Split View _Horizontal']][2],
    v = m_view[_L['Split View _Vertical']][2],
    w = m_view[_L['_Unsplit View']][2],
    W = m_view[_L['Unsplit _All Views']][2],
    ['+'] = m_view[_L['_Grow View']][2],
    ['-'] = m_view[_L['Shrin_k View']][2]
  }
  if not OSX then keys.cmv.h = keys.cmv.s end
  keys.cmv['='] = keys.cmv['+']
end
keys[not OSX and GUI and 'c*' or 'm*'] = m_view[_L['Toggle Current _Fold']][2]
if GUI then
  keys[not OSX and 'caI' or 'cI'] = m_view[_L['Toggle Show In_dent Guides']][2]
  keys[not OSX and 'caV' or 'cV'] = m_view[_L['Toggle _Virtual Space']][2]
end
keys[not OSX and GUI and 'c=' or 'm='] = buffer.zoom_in
keys[not OSX and GUI and 'c-' or 'm-'] = buffer.zoom_out
keys[not OSX and GUI and 'c0' or 'm0'] = m_view[_L['_Reset Zoom']][2]

-- Help.
if GUI then
  keys.f1 = textadept.menu.menubar[_L['_Help']][_L['Show _Manual']][2]
  keys.sf1 = textadept.menu.menubar[_L['_Help']][_L['Show _LuaDoc']][2]
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
  keys.ck = function()
    buffer:line_end_extend()
    if not buffer.selection_empty then buffer:cut() else buffer:clear() end
  end
  keys.cl = buffer.vertical_centre_caret
  -- GTK-OSX reports Fn-key as a single keycode which confuses Scintilla. Do
  -- not propagate it.
  keys.fn = function() return true end
elseif CURSES then
  keys['c^'] = function() buffer.selection_mode = 0 end
  keys['c]'] = buffer.swap_main_anchor_caret
  keys.cf, keys.cb = buffer.char_right, buffer.char_left
  keys.cn, keys.cp = buffer.line_down, buffer.line_up
  keys.ca, keys.ce = buffer.vc_home, buffer.line_end
  keys.mA, keys.mE = buffer.vc_home_extend, buffer.line_end_extend
  keys.mU, keys.mD = buffer.page_up_extend, buffer.page_down_extend
  keys.cma, keys.cme = buffer.document_start, buffer.document_end
  keys.cd, keys.md, keys.ch = buffer.clear, keys.mdel, buffer.delete_back
  keys.ck = function()
    buffer:line_end_extend()
    if not buffer.selection_empty then buffer:cut() else buffer:clear() end
  end
end

-- Modes.
keys.filter_through = {
  ['\n'] = function()
    return ui.command_entry.finish_mode(textadept.editing.filter_through)
  end,
}
keys.find_incremental = {
  ['\n'] = function()
    ui.find.find_entry_text = ui.command_entry:get_text() -- save
    ui.find.find_incremental(ui.command_entry:get_text(), true, true)
  end,
  ['cr'] = function()
    ui.find.find_incremental(ui.command_entry:get_text(), false, true)
  end,
  ['\b'] = function()
    local e = ui.command_entry:position_before(ui.command_entry.length)
    ui.find.find_incremental(ui.command_entry:text_range(0, e), true)
    return false -- propagate
  end
}
-- Add the character for any key pressed without modifiers to incremental find.
setmetatable(keys.find_incremental, {__index = function(_, k)
               if #k > 1 and k:find('^[cams]*.+$') then return end
               ui.find.find_incremental(ui.command_entry:get_text()..k, true)
             end})
-- Show documentation for symbols in the Lua command entry.
keys.lua_command[GUI and 'ch' or 'mh'] = function()
  -- Temporarily change _G.buffer since ui.command_entry is the "active" buffer.
  local orig_buffer = _G.buffer
  _G.buffer = ui.command_entry
  textadept.editing.show_documentation()
  _G.buffer = orig_buffer
end
if OSX or CURSES then
  -- UTF-8 input.
  keys.utf8_input = {
    ['\n'] = function()
      return ui.command_entry.finish_mode(function(code)
        buffer:add_text(utf8.char(tonumber(code, 16)))
      end)
    end
  }
  keys[OSX and 'mU' or 'mu'] = function()
    ui.command_entry.enter_mode('utf8_input')
  end
end

return M

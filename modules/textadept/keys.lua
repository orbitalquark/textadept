-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

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
-- None          |None     |None      |Save all files
-- Ctrl+W        |⌘W       |^W        |Close file
-- Ctrl+Shift+W  |⌘⇧W      |M-^W      |Close all files
-- None          |None     |None      |Load session...
-- None          |None     |None      |Save session...
-- Ctrl+Q        |⌘Q       |^Q        |Quit
-- **Edit**                |         |              |
-- Ctrl+Z<br/>Alt+Bksp     |⌘Z       |^Z^(†)<br/>M-Z|Undo
-- Ctrl+Y<br/>Ctrl+Shift+Z |⌘⇧Z      |^Y<br/>M-S-Z  |Redo
-- Ctrl+X<br/>Shift+Del    |⌘X<br/>⇧⌦|^X            |Cut
-- Ctrl+C<br/>Ctrl+Ins     |⌘C       |^C            |Copy
-- Ctrl+V<br/>Shift+Ins    |⌘V       |^V            |Paste
-- Ctrl+Shift+V            |⌘⇧V      |M-V           |Paste Reindent
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
-- Ctrl+F2         |⌘F2    |F1           |Toggle bookmark
-- Ctrl+Shift+F2   |⌘⇧F2   |F6           |Clear bookmarks
-- F2              |F2     |F2           |Next bookmark
-- Shift+F2        |⇧F2    |F3           |Previous bookmark
-- Alt+F2          |⌥F2    |F4           |Goto bookmark...
-- F9              |F9     |F9           |Start/stop recording macro
-- Shift+F9        |⇧F9    |F10          |Play recorded macro
-- Ctrl+U          |⌘U     |^U           |Quickly open `_USERHOME`
-- None            |None   |None         |Quickly open `_HOME`
-- Ctrl+Alt+Shift+O|^⌘⇧O   |M-S-O        |Quickly open current directory
-- Ctrl+Alt+Shift+P|^⌘⇧P   |M-^P         |Quickly open current project
-- Ctrl+Shift+K    |⌥⇧⇥    |M-S-K        |Insert snippet...
-- Tab             |⇥      |Tab          |Expand snippet or next placeholder
-- Shift+Tab       |⇧⇥     |S-Tab        |Previous snippet placeholder
-- Esc             |Esc    |Esc          |Cancel snippet
-- Ctrl+K          |⌥⇥     |M-K          |Complete trigger word
-- Ctrl+Space      |⌥Esc   |^Space       |Complete symbol
-- Ctrl+H          |^H     |M-H<br/>M-S-H|Show documentation
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
-- None            |None  |None         |CP-1252 encoding
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
-- Up             |⇡              |^P          |Cycle back through history
-- Down           |⇣              |^N          |Cycle forward through history
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
-- c:       C         H I            p  Q     T ~ V     Y  _   ) ] }   +
-- a:  aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_   ) ] }  *+-/=\n\s
-- ca: aAbBcCdD   F      jJkKlLmM N    qQ    t       xXy zZ_"'()[]{}<>*  /   \s
--
-- c = 'ctrl' (Control ^)
-- a = 'alt' (Alt)
-- s = 'shift' (Shift ⇧)
-- Control, Alt, Shift, and 'a' = 'ctrl+alt+A'
-- Control, Shift, and '\t' = 'ctrl+shift+\t'
--
-- Mac OSX key bindings.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- m:       C        ~  I JkK  ~M    p  ~    tT   V    yY  _   ) ] }   +   ~~\n
-- c:      cC D    gG H   J K L    oO  qQ            xXyYzZ_   ) ] }  *  /
-- cm: aAbBcC~D   F  ~HiIjJkKlL~MnN  p q~rRsStTuUvVwWxXyYzZ_"'()[]{}<>*+-/=\t\n
--
-- c = 'ctrl' (Control ^)
-- a = 'alt' (Alt/option ⌥)
-- m = 'cmd' (Command ⌘)
-- s = 'shift' (Shift ⇧)
-- Command, Option, Shift, and 'a' = 'alt+cmd+A'
-- Command, Shift, and '\t' = 'cmd+shift+\t'
--
-- Curses key bindings.
--
-- Key bindings available depend on your implementation of curses.
--
-- For ncurses (Linux, Mac OSX, BSD):
--   * The only Control keys recognized are 'ctrl+a'-'ctrl+z', 'ctrl+ ',
--     'ctrl+\\', 'ctrl+]', 'ctrl+^', and 'ctrl+_'.
--   * Control+Shift and Control+Meta+Shift keys are not recognized.
--   * Modifiers for function keys F1-F12 are not recognized.
-- For pdcurses (Win32):
--   * Many Control+Symbol keys are not recognized, but most
--     Control+Shift+Symbol keys are.
--   * Ctrl+Meta+Symbol keys are not recognized.
--
-- Unassigned keys (~ denotes keys reserved by the operating system):
-- c:        g~~   ~            ~
-- cm:   cd  g~~ k ~   q  t    yz
-- m:          e          J            qQ  sS    vVw   yY  _          +
-- Note: m[befhstv] may be used by Linux/BSD GUI terminals for menu access.
--
-- c = 'ctrl' (Control ^)
-- m = 'meta' (Alt)
-- s = 'shift' (Shift ⇧)
-- Control, Meta, and 'a' = 'ctrl+meta+a'

local _L = _L
local m_edit = textadept.menu.menubar[_L['Edit']]
local m_sel, m_seln = m_edit[_L['Select']], m_edit[_L['Selection']]
local m_search = textadept.menu.menubar[_L['Search']]
local m_tools = textadept.menu.menubar[_L['Tools']]
local m_bookmark = m_tools[_L['Bookmarks']]
local m_qopen = m_tools[_L['Quick Open']]
local m_snippets = m_tools[_L['Snippets']]
local m_buffer = textadept.menu.menubar[_L['Buffer']]
local m_indentation = m_buffer[_L['Indentation']]
local m_view = textadept.menu.menubar[_L['View']]
local m_help = textadept.menu.menubar[_L['Help']]

-- Bindings for Linux/Win32, Mac OSX, Terminal.
local bindings = {
  -- File.
  [buffer.new] = {'ctrl+n', 'cmd+n', 'ctrl+meta+n'},
  [io.open_file] = {'ctrl+o', 'cmd+o', 'ctrl+o'},
  [io.open_recent_file] = {'ctrl+alt+o', 'ctrl+cmd+o', 'ctrl+alt+o'},
  [buffer.reload] = {'ctrl+O', 'cmd+O', 'meta+o'},
  [buffer.save] = {'ctrl+s', 'cmd+s', 'ctrl+s'},
  [buffer.save_as] = {'ctrl+S', 'cmd+S', 'ctrl+meta+s'},
  -- TODO: io.save_all_files
  [buffer.close] = {'ctrl+w', 'cmd+w', 'ctrl+w'},
  [io.close_all_buffers] = {'ctrl+W', 'cmd+W', 'ctrl+meta+w'},
  -- TODO: textadept.sessions.load
  -- TODO: textadept.sessions.save
  [quit] = {'ctrl+q', 'cmd+q', 'ctrl+q'},

  -- Edit.
  [buffer.undo] = {'ctrl+z', 'cmd+z', {'ctrl+z', 'meta+z'}},
  [buffer.redo] = {{'ctrl+y', 'ctrl+Z'}, 'cmd+Z', {'ctrl+y', 'meta+Z'}},
  [buffer.cut] = {'ctrl+x', 'cmd+x', 'ctrl+x'},
  [buffer.copy] = {'ctrl+c', 'cmd+c', 'ctrl+c'},
  [buffer.paste] = {'ctrl+v', 'cmd+v', 'ctrl+v'},
  [textadept.editing.paste_reindent] = {'ctrl+V', 'cmd+V', 'meta+v'},
  [buffer.line_duplicate] = {'ctrl+d', 'cmd+d', nil},
  [buffer.clear] = {'del', {'del', 'ctrl+d'}, {'del', 'ctrl+d'}},
  [m_edit[_L['Delete Word']][2]] =
    {'alt+del', 'ctrl+del', {'meta+del', 'meta+d'}},
  [buffer.select_all] = {'ctrl+a', 'cmd+a', 'meta+a'},
  [m_edit[_L['Match Brace']][2]] = {'ctrl+m', 'ctrl+m', 'meta+m'},
  [m_edit[_L['Complete Word']][2]] =
    {'ctrl+\n', 'ctrl+esc', {'ctrl+meta+j', 'ctrl+\n'}},
  [textadept.editing.highlight_word] = {'ctrl+alt+H', 'cmd+H', nil},
  [textadept.editing.block_comment] = {'ctrl+/', 'ctrl+/', 'meta+/'},
  [textadept.editing.transpose_chars] = {'ctrl+t', 'ctrl+t', 'ctrl+t'},
  [textadept.editing.join_lines] = {'ctrl+J', 'ctrl+j', 'meta+j'},
  [m_edit[_L['Filter Through']][2]] = {'ctrl+|', 'cmd+|', 'ctrl+\\'},
  -- Select.
  [m_sel[_L['Select between Matching Delimiters']][2]] =
    {'ctrl+M', 'ctrl+M', 'meta+M'},
  [m_sel[_L['Select between XML Tags']][2]] = {'ctrl+<', 'cmd+<', 'meta+<'},
  [m_sel[_L['Select in XML Tag']][2]] = {'ctrl+>', 'cmd+>', nil},
  [textadept.editing.select_word] = {'ctrl+D', 'cmd+D', 'meta+W'},
  [textadept.editing.select_line] = {'ctrl+N', 'cmd+N', 'meta+N'},
  [textadept.editing.select_paragraph] = {'ctrl+P', 'cmd+P', 'meta+P'},
  -- Selection.
  [buffer.upper_case] = {'ctrl+alt+u', 'ctrl+u', 'ctrl+meta+u'},
  [buffer.lower_case] = {'ctrl+alt+U', 'ctrl+U', 'ctrl+meta+l'},
  [m_seln[_L['Enclose as XML Tags']][2]] = {'alt+<', 'ctrl+<', 'meta+>'},
  [m_seln[_L['Enclose as Single XML Tag']][2]] = {'alt+>', 'ctrl+>', nil},
  [m_seln[_L['Enclose in Single Quotes']][2]] = {"alt+'", "ctrl+'", nil},
  [m_seln[_L['Enclose in Double Quotes']][2]] = {'alt+"', 'ctrl+"', nil},
  [m_seln[_L['Enclose in Parentheses']][2]] = {'alt+(', 'ctrl+(', 'meta+)'},
  [m_seln[_L['Enclose in Brackets']][2]] = {'alt+[', 'ctrl+[', 'meta+]'},
  [m_seln[_L['Enclose in Braces']][2]] = {'alt+{', 'ctrl+{', 'meta+}'},
  [buffer.move_selected_lines_up] =
    {'ctrl+shift+up', 'ctrl+shift+up', 'ctrl+shift+up'},
  [buffer.move_selected_lines_down] =
    {'ctrl+shift+down', 'ctrl+shift+down', 'ctrl+shift+down'},

  -- Search.
  [m_search[_L['Find']][2]] = {'ctrl+f', 'cmd+f', {'meta+f', 'meta+F'}},
  [ui.find.find_next] = {{'ctrl+g', 'f3'}, 'cmd+g', 'meta+g'},
  [ui.find.find_prev] = {{'ctrl+G', 'shift+f3'}, 'cmd+G', 'meta+G'},
  [ui.find.replace] = {'ctrl+alt+r', 'ctrl+r', 'meta+r'},
  [ui.find.replace_all] = {'ctrl+alt+R', 'ctrl+R', 'meta+R'},
  -- Find Next is an when find pane is focused in GUI.
  -- Find Prev is ap when find pane is focused in GUI.
  -- Replace is ar when find pane is focused in GUI.
  -- Replace All is aa when find pane is focused in GUI.
  [ui.find.find_incremental] = {'ctrl+alt+f', 'ctrl+cmd+f', 'ctrl+meta+f'},
  [m_search[_L['Find in Files']][2]] = {'ctrl+F', 'cmd+F', nil},
  -- Find in Files is ai when find pane is focused in GUI.
  [m_search[_L['Goto Next File Found']][2]] = {'ctrl+alt+g', 'ctrl+cmd+g', nil},
  [m_search[_L['Goto Previous File Found']][2]] =
    {'ctrl+alt+G', 'ctrl+cmd+G', nil},
  [textadept.editing.goto_line] = {'ctrl+j', 'cmd+j', 'ctrl+j'},

  -- Tools.
  [m_tools[_L['Command Entry']][2]] = {'ctrl+e', 'cmd+e', 'meta+c'},
  [m_tools[_L['Select Command']][2]] = {'ctrl+E', 'cmd+E', 'meta+C'},
  [textadept.run.run] = {'ctrl+r', 'cmd+r', 'ctrl+r'},
  [textadept.run.compile] = {'ctrl+R', 'cmd+R', 'ctrl+meta+r'},
  [m_tools[_L['Set Arguments...']][2]] = {'ctrl+A', 'cmd+A', nil},
  [textadept.run.build] = {'ctrl+B', 'cmd+B', 'ctrl+meta+b'},
  [textadept.run.stop] = {'ctrl+X', 'cmd+X', 'ctrl+meta+x'},
  [m_tools[_L['Next Error']][2]] = {'ctrl+alt+e', 'ctrl+cmd+e', 'meta+x'},
  [m_tools[_L['Previous Error']][2]] = {'ctrl+alt+E', 'ctrl+cmd+E', 'meta+X'},
  -- Bookmark.
  [textadept.bookmarks.toggle] = {'ctrl+f2', 'cmd+f2', 'f1'},
  [textadept.bookmarks.clear] = {'ctrl+shift+f2', 'cmd+shift+f2', 'f6'},
  [m_bookmark[_L['Next Bookmark']][2]] = {'f2', 'f2', 'f2'},
  [m_bookmark[_L['Previous Bookmark']][2]] = {'shift+f2', 'shift+f2', 'f3'},
  [textadept.bookmarks.goto_mark] = {'alt+f2', 'alt+f2', 'f4'},
  -- Macros.
  [textadept.macros.record] = {'f9', 'f9', 'f9'},
  [textadept.macros.play] = {'shift+f9', 'shift+f9', 'f10'},
  -- Quick Open.
  [m_qopen[_L['Quickly Open User Home']][2]] = {'ctrl+u', 'cmd+u', 'ctrl+u'},
  -- TODO: m_qopen[_L['Quickly Open Textadept Home']][2]
  [m_qopen[_L['Quickly Open Current Directory']][2]] =
    {'ctrl+alt+O', 'ctrl+cmd+O', 'meta+O'},
  [io.quick_open] = {'ctrl+alt+P', 'ctrl+cmd+P', 'ctrl+meta+p'},
  -- Snippets.
  [textadept.snippets.select] = {'ctrl+K', 'shift+alt+\t', 'meta+K'},
  [textadept.snippets.insert] = {'\t', '\t', '\t'},
  [textadept.snippets.previous] = {'shift+\t', 'shift+\t', 'shift+\t'},
  [textadept.snippets.cancel_current] = {'esc', 'esc', 'esc'},
  [m_snippets[_L['Complete Trigger Word']][2]] = {'ctrl+k', 'alt+\t', 'meta+k'},
  -- Other.
  [m_tools[_L['Complete Symbol']][2]] = {'ctrl+ ', 'alt+esc', 'ctrl+ '},
  [textadept.editing.show_documentation] =
    {'ctrl+h', 'ctrl+h', {'meta+h', 'meta+H'}},
  [m_tools[_L['Show Style']][2]] = {'ctrl+i', 'cmd+i', 'meta+I'},

  -- Buffer.
  [m_buffer[_L['Next Buffer']][2]] = {'ctrl+\t', 'ctrl+\t', 'meta+n'},
  [m_buffer[_L['Previous Buffer']][2]] =
    {'ctrl+shift+\t', 'ctrl+shift+\t', 'meta+p'},
  [ui.switch_buffer] = {'ctrl+b', 'cmd+b', {'meta+b', 'meta+B'}},
  -- Indentation.
  -- TODO: m_indentation[_L['Tab width: 2']][2]
  -- TODO: m_indentation[_L['Tab width: 3']][2]
  -- TODO: m_indentation[_L['Tab width: 4']][2]
  -- TODO: m_indentation[_L['Tab width: 8']][2]
  [m_indentation[_L['Toggle Use Tabs']][2]] =
    {'ctrl+alt+T', 'ctrl+T', {'meta+t', 'meta+T'}},
  [textadept.editing.convert_indentation] = {'ctrl+alt+i', 'ctrl+i', 'meta+i'},
  -- EOL Mode.
  -- TODO: m_buffer[_L['EOL Mode']][_L['CRLF']][2]
  -- TODO: m_buffer[_L['EOL Mode']][_L['LF']][2]
  -- Encoding.
  -- TODO: m_buffer[_L['Encoding']][_L['UTF-8 Encoding']][2]
  -- TODO: m_buffer[_L['Encoding']][_L['ASCII Encoding']][2]
  -- TODO: m_buffer[_L['Encoding']][_L['CP-1252 Encoding']][2]
  -- TODO: m_buffer[_L['Encoding']][_L['UTF-16 Encoding']][2]
  [m_buffer[_L['Toggle View EOL']][2]] = {'ctrl+alt+\n', 'ctrl+\n', nil},
  [m_buffer[_L['Toggle Wrap Mode']][2]] = {'ctrl+alt+\\', 'ctrl+\\', nil},
  [m_buffer[_L['Toggle View Whitespace']][2]] = {'ctrl+alt+S', 'ctrl+S', nil},
  [textadept.file_types.select_lexer] = {'ctrl+L', 'cmd+L', 'meta+L'},
  [m_buffer[_L['Refresh Syntax Highlighting']][2]] =
    {'f5', 'f5', {'f5', 'ctrl+l'}},

  -- View.
  [m_view[_L['Next View']][2]] = {'ctrl+alt+n', 'ctrl+alt+\t', nil},
  [m_view[_L['Previous View']][2]] = {'ctrl+alt+p', 'ctrl+alt+shift+\t', nil},
  [m_view[_L['Split View Horizontal']][2]] =
    {{'ctrl+alt+s', 'ctrl+alt+h'}, 'ctrl+s', nil},
  [m_view[_L['Split View Vertical']][2]] = {'ctrl+alt+v', 'ctrl+v', nil},
  [m_view[_L['Unsplit View']][2]] = {'ctrl+alt+w', 'ctrl+w', nil},
  [m_view[_L['Unsplit All Views']][2]] = {'ctrl+alt+W', 'ctrl+W', nil},
  [m_view[_L['Grow View']][2]] =
    {{'ctrl+alt++', 'ctrl+alt+='}, {'ctrl++', 'ctrl+='}, nil},
  [m_view[_L['Shrink View']][2]] = {'ctrl+alt+-', 'ctrl+-', nil},
  [m_view[_L['Toggle Current Fold']][2]] = {'ctrl+*', 'cmd+*', 'meta+*'},
  [m_view[_L['Toggle Show Indent Guides']][2]] = {'ctrl+alt+I', 'ctrl+I', nil},
  [m_view[_L['Toggle Virtual Space']][2]] = {'ctrl+alt+V', 'ctrl+V', nil},
  [view.zoom_in] = {'ctrl+=', 'cmd+=', nil},
  [view.zoom_out] = {'ctrl+-', 'cmd+-', nil},
  [m_view[_L['Reset Zoom']][2]] = {'ctrl+0', 'cmd+0', nil},

  -- Help.
  [m_help[_L['Show Manual']][2]] = {'f1', 'f1', nil},
  [m_help[_L['Show LuaDoc']][2]] = {'shift+f1', 'shift+f1', nil},

  -- Movement commands.
  -- Unbound keys are handled by Scintilla, but when playing back a macro, this
  -- is not possible. Define some useful default key bindings so Scintilla does
  -- not have to handle them. Note that Scintilla still will handle some keys.
  [buffer.line_down] = {'down', {'down', 'ctrl+n'}, {'down', 'ctrl+n'}},
  [buffer.line_down_extend] =
    {'shift+down', {'shift+down', 'ctrl+N'}, 'shift+down'},
  [buffer.line_up] = {'up', {'up', 'ctrl+p'}, {'up', 'ctrl+p'}},
  [buffer.line_up_extend] = {'shift+up', {'shift+up', 'ctrl+P'}, 'shift+up'},
  [buffer.char_left] = {'left', {'left', 'ctrl+b'}, {'left', 'ctrl+b'}},
  [buffer.char_left_extend] =
    {'shift+left', {'shift+left', 'ctrl+B'}, 'shift+left'},
  [buffer.word_left] = {'ctrl+left', {'ctrl+left', 'ctrl+cmd+b'}, 'ctrl+left'},
  [buffer.word_left_extend] =
    {'ctrl+shift+left', {'ctrl+shift+left', 'ctrl+cmd+B'}, 'ctrl+shift+left'},
  [buffer.char_right] = {'right', {'right', 'ctrl+f'}, {'right', 'ctrl+f'}},
  [buffer.char_right_extend] =
    {'shift+right', {'shift+right', 'ctrl+F'}, 'shift+right'},
  [buffer.word_right] =
    {'ctrl+right', {'ctrl+right', 'ctrl+cmd+f'}, 'ctrl+right'},
  [buffer.word_right_end_extend] = {
    'ctrl+shift+right', {'ctrl+shift+right', 'ctrl+cmd+F'}, 'ctrl+shift+right'
  },
  [buffer.vc_home] = {'home', {'cmd+left', 'ctrl+a'}, {'home', 'ctrl+a'}},
  [buffer.vc_home_extend] =
    {'shift+home', {'cmd+shift+left', 'ctrl+A'}, 'meta+A'},
  [buffer.line_end] = {'end', {'cmd+right', 'ctrl+e'}, {'end', 'ctrl+e'}},
  [buffer.line_end_extend] =
    {'shift+end', {'cmd+shift+right', 'ctrl+E'}, 'meta+E'},
  [view.vertical_center_caret] = {nil, 'ctrl+l', nil},
  [buffer.page_up_extend] = {nil, nil, 'meta+U'},
  [buffer.page_down_extend] = {nil, nil, 'meta+D'},
  [buffer.document_start] = {nil, nil, 'ctrl+meta+a'},
  [buffer.document_end] = {nil, nil, 'ctrl+meta+e'},

  [function(b)
    buffer:line_end_extend()
    if not buffer.selection_empty then buffer:cut() else buffer:clear() end
  end] = {nil, 'ctrl+k', 'ctrl+k'},
  [buffer.del_word_right] = {'ctrl+del', 'cmd+del', 'ctrl+del'},
  [buffer.del_line_right] =
    {'ctrl+shift+del', 'cmd+shift+del', 'ctrl+shift+del'},
  [buffer.delete_back] = {'\b', '\b', {'\b', 'ctrl+h'}},
  [buffer.del_word_left] = {'ctrl+\b', 'cmd+\b', nil},
  [buffer.del_line_left] = {'ctrl+shift+\b', 'cmd+shift+\b', nil},
  [function() buffer.selection_mode = 0 end] = {nil, nil, 'ctrl+^'},
  [buffer.swap_main_anchor_caret] = {nil, nil, 'ctrl+]'},

  -- Other.
  -- UTF-8 input.
  [function()
    ui.command_entry.run(
      function(code) buffer:add_text(utf8.char(tonumber(code, 16))) end)
  end] = {nil, 'cmd+U', 'meta+u'}
}

local keys, plat = keys, CURSES and 3 or OSX and 2 or 1
for f, plat_keys in pairs(bindings) do
  local key = plat_keys[plat]
  if type(key) == 'string' then
    keys[key] = f
  elseif type(key) == 'table' then
    for _, key in ipairs(key) do keys[key] = f end
  end
end

if CURSES then
  keys['ctrl+meta+v'] = {
    n = m_view[_L['Next View']][2],
    p = m_view[_L['Previous View']][2],
    s = m_view[_L['Split View Horizontal']][2],
    h = m_view[_L['Split View Horizontal']][2],
    v = m_view[_L['Split View Vertical']][2],
    w = m_view[_L['Unsplit View']][2],
    W = m_view[_L['Unsplit All Views']][2],
    ['+'] = m_view[_L['Grow View']][2],
    ['='] = m_view[_L['Grow View']][2],
    ['-'] = m_view[_L['Shrink View']][2]
  }
end

-- GTK-OSX reports Fn-key as a single keycode which confuses Scintilla. Do
-- not propagate it.
if OSX then keys.fn = function() return true end end

-- Reverse incremental find.
ui.find.find_incremental_keys['ctrl+r'] = function()
  ui.find.find_incremental(ui.command_entry:get_text(), false, true)
end

return M

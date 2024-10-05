-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Defines key bindings for Textadept.
-- This set of key bindings is pretty standard among other text editors, at least for basic
-- editing commands and movements.
--
-- They are designed to be as consistent as possible between operating systems and platforms
-- so that users familiar with one set of bindings can intuit a given binding on another OS or
-- platform, minimizing the need for memorization.
--
-- In general, bindings for macOS are the same as for Windows/Linux/BSD except the "Control"
-- modifier key on Windows/Linux/BSD is replaced by "Command" (`⌘`) and the "Alt" modifier
-- key is replaced by "Control" (`^`). The only exception is for word- and paragraph-based
-- movement keys, which use "Alt" (`⌥`) instead of "Command" (`⌘`).
--
-- In general, bindings for the terminal version are the same as for Windows/Linux/BSD except:
--
-- - Most `Ctrl+Shift+`*`key`* combinations become `M-^`*`key`* since most terminals recognize
--	few, if any, `Ctrl+Shift` key sequences.
-- - Most `Ctrl+`*`symbol`* combinations become `M-`*`symbol`* since most terminals recognize
--	only a few `Ctrl` combinations with symbol keys.
-- - All `Ctrl+Alt+`*`key`* combinations become `M-`*`key`* except for word part movement keys
--	and those involving `PgDn` and `PgUp`. The former are not supported and the latter use
--	both modifier keys.
-- - `Ctrl+J` and `Ctrl+M` become `M-J` and `M-M`, respectively, because control sequences
--	involving the `J` and `M` keys are often interpreted as involving the Enter key.
--
-- **Windows Note:** on international keyboard layouts, the "AltGr" key is equivalent to pressing
-- "Ctrl" and "Alt", so `AltGr+`*`key`* combinations may unexpectedly trigger one of Textadept's
-- `Ctrl+Alt+`*`key`* bindings. In order to avoid this, you will likely have to disable the
-- `Ctrl+Alt+`*`key`* binding in your *~/.textadept/init.lua* by setting it to `nil`.
--
-- ### Key Bindings
--
-- Windows, Linux, and BSD | macOS | Terminal | Command
-- -|-|-|-
-- **File**|||
-- Ctrl+N | ⌘N | ^N | New file
-- Ctrl+O | ⌘O | ^O | Open file
-- None | None | None | Open recent file...
-- None | None | None | Reload file
-- Ctrl+S | ⌘S | ^S<br/>M-S^(*) | Save file
-- Ctrl+Shift+S | ⌘⇧S | M-^S | Save file as..
-- None | None | None | Save all files
-- Ctrl+W | ⌘W | ^W | Close file
-- Ctrl+Shift+W | ⌘⇧W | M-^W | Close all files
-- None | None | None | Load session...
-- None | None | None | Save session...
-- Ctrl+Q | ⌘Q | ^Q<br/>M-Q^(*) | Quit
-- **Edit**| | |
-- Ctrl+Z<br/>Alt+Bksp | ⌘Z | ^Z^(†)<br/>M-Bksp | Undo
-- Ctrl+Y<br/>Ctrl+Shift+Z | ⌘⇧Z<br/>⌘Y | ^Y<br/>M-^Z | Redo
-- Ctrl+X<br/>Shift+Del | ⌘X<br/>⇧⌦ | ^X<br/>S-Del | Cut
-- Ctrl+C<br/>Ctrl+Ins | ⌘C | ^C | Copy
-- Ctrl+V<br/>Shift+Ins | ⌘V | ^V<br/>S-Ins | Paste
-- Ctrl+Shift+V | ⌘⇧V | M-^V | Paste Reindent
-- Ctrl+Shift+D | ⌘⇧D | M-^D | Duplicate line/selection
-- Del | ⌦<br/> ^D | Del | Delete
-- Alt+Del | ^⌦ | M-Del | Delete word
-- Ctrl+A | ⌘A | ^A | Select all
-- Ctrl+Shift+A | ⌘⇧A | M-^A | Deselect
-- Ctrl+M | ⌘M | M-M | Match brace
-- Ctrl+Enter | ⌘↩ | ^Enter | Complete word
-- Ctrl+/ | ⌘/ | ^/<br/>M-/ | Toggle block comment
-- Ctrl+J | ⌘J | M-J | Join lines
-- Ctrl+&#124; | ⌘&#124; | ^&#124;<br/>^\ | Filter text through
-- Ctrl+Shift+M | ⌘⇧M | M-^M | Select between delimiters
-- Ctrl+D | ⌘D | ^D | Select word
-- Ctrl+Alt+D | ^⌘D | M-D | Deselect word
-- Ctrl+L | ⌘L | ^L | Select line
-- Ctrl+Shift+P | ⌘⇧P | M-^P | Select paragraph
-- Ctrl+Shift+U^(‡)<br/>Ctrl+Alt+Shift+U | ⌘⇧U | M-^U | Upper case selection
-- Ctrl+U | ⌘U | ^U | Lower case selection
-- Alt+< | ^< | M-< | Enclose selection as XML tags
-- Alt+> | ^> | M-> | Enclose selection as single XML tag
-- Alt+" | ^" | M-" | Enclose selection in double quotes
-- Alt+' | ^' | M-' | Enclose selection in single quotes
-- Alt+( | ^( | M-( | Enclose selection in parentheses
-- Alt+[ | ^[ | None | Enclose selection in brackets
-- Alt+{ | ^{ | M-{ | Enclose selection in braces
-- Ctrl+Alt+Shift+Up | ^⌘⇧⇡ | None | Move selected lines up
-- Ctrl+Alt+Shift+Down | ^⌘⇧⇣ | None | Move selected lines down
-- Ctrl+[<br/>Alt+Left | ⌘[ | M-[<br/>M-Left | Navigate backward
-- Ctrl+]<br/>Alt+Right | ⌘] | M-]<br/>M-Right | Navigate forward
-- None | None | None | Record location
-- None | None | None | Clear navigation history
-- None | ⌘, | None | Preferences
-- **Search**| | |
-- Ctrl+F | ⌘F | ^F | Find
-- None | None | None | Find next
-- None | None | None | Find previous
-- None | None | None | Replace
-- None | None | None | Replace all
-- Ctrl+Alt+F | ^⌘F | M-F | Find incremental
-- Ctrl+Shift+F | ⌘⇧F | M-^F | Find in files
-- Ctrl+Alt+G | ^⌘G | M-G | Go to next file found
-- Ctrl+Alt+Shift+G | ^⌘⇧G | M-S-G | Go to previous file found
-- Ctrl+G | ⌘G | ^G | Go to line
-- **Tools**| | |
-- Ctrl+E | ⌘E | ^E | Command entry
-- Ctrl+P | ⌘P | ^P | Select command
-- Ctrl+R | ⌘R | ^R | Run
-- Ctrl+Shift+C | ⌘⇧C | M-^C | Compile
-- Ctrl+Shift+B | ⌘⇧B | M-^B | Build
-- Ctrl+Shift+T | ⌘⇧T | M-^T | Run tests
-- Ctrl+Shift+R | ⌘⇧R | M-^R | Run project
-- Ctrl+Shift+X | ⌘⇧X | M-^X | Stop
-- Ctrl+Alt+E | ^⌘E | M-E | Next Error
-- Ctrl+Alt+Shift+E | ^⌘⇧E | M-S-E | Previous Error
-- Ctrl+K | ⌘K | ^K | Toggle bookmark
-- None | None | None | Clear bookmarks
-- Ctrl+Alt+K | ^⌘K | M-K | Next bookmark
-- Ctrl+Alt+Shift+K | ^⌘⇧K | M-S-K | Previous bookmark
-- Ctrl+Shift+K | ⌘⇧K | M-^K | Go to bookmark...
-- Alt+, | ^, | M-, | Start/stop recording macro
-- Alt+. | ^. | M-. | Play recorded macro
-- None | None | None | Save recorded macro
-- None | None | None | Load saved macro
-- Ctrl+Alt+U | ⌘⇧U | M-U | Quickly open `_USERHOME`
-- Ctrl+Alt+H | ⌘⇧H | M-H | Quickly open `_HOME`
-- None | None | None | Quickly open current directory
-- Ctrl+Shift+O | ⌘⇧O | M-^O | Quickly open current project
-- None | None | None | Insert snippet...
-- Tab | ⇥ | Tab | Expand snippet or next placeholder
-- Shift+Tab | ⇧⇥ | S-Tab | Previous snippet placeholder
-- Esc | Esc | Esc | Cancel snippet
-- None | None | None | Complete trigger word
-- None | None | None | Show style
-- **Buffer**| | |
-- Ctrl+Tab<br/>Ctrl+PgDn | ^⇥<br/>⌘⇟ | M-PgDn<br/> ^Tab^(§) | Next buffer
-- Ctrl+Shift+Tab<br/>Ctrl+PgUp | ^⇧⇥<br/>⌘⇞ | M-PgUp<br/>S-^Tab^(§) | Previous buffer
-- Ctrl+B | ⌘B | ^B | Switch to buffer...
-- None | None | None | Tab width: 2
-- None | None | None | Tab width: 3
-- None | None | None | Tab width: 4
-- None | None | None | Tab width: 8
-- Ctrl+Alt+T | ^⌘T | M-T | Toggle use tabs
-- None | None | None | Convert indentation
-- None | None | None | CR+LF EOL mode
-- None | None | None | LF EOL mode
-- None | None | None | UTF-8 encoding
-- None | None | None | ASCII encoding
-- None | None | None | CP-1252 encoding
-- None | None | None | UTF-16 encoding
-- Ctrl+Shift+L | ⌘⇧L | M-^L | Select lexer...
-- **View**| | |
-- Ctrl+Alt+PgDn | ^⌘⇟ | M-^PgDn<br/>M-PgUp^(§) | Next view
-- Ctrl+Alt+PgUp | ^⌘⇞ | M-^PgUp<br/>M-PgDn^(§) | Previous view
-- Ctrl+Alt+_ | ^⌘_ | M-_ | Split view horizontal
-- Ctrl+Alt+&#124; | ^⌘&#124; | M-&#124; | Split view vertical
-- Ctrl+Alt+W | ^⌘W | M-W | Unsplit view
-- Ctrl+Alt+Shift+W | ^⌘⇧W | M-S-W | Unsplit all views
-- Ctrl+Alt++<br/>Ctrl+Alt+= | ^⌘+<br/>^⌘= | M-+<br/>M-= | Grow view
-- Ctrl+Alt+- | ^⌘- | M-- | Shrink view
-- Ctrl+} | ⌘} | M-} | Toggle current fold
-- Ctrl+\\ | ⌘\\ | M-\\ | Toggle wrap mode
-- None | None | N/A | Toggle indent guides
-- None | None | None | Toggle view whitespace
-- None | None | None | Toggle virtual space
-- Ctrl+= | ⌘= | N/A | Zoom in
-- Ctrl+- | ⌘- | N/A | Zoom out
-- Ctrl+0 | ⌘0 | N/A | Reset zoom
-- **Help**| | |
-- F1 | F1 | None | Open manual
-- Shift+F1 | ⇧F1 | None | Open LuaDoc
-- None | None | None | About
-- **Other**| | |
-- Shift+Enter | ⇧↩ | None | Start a new line below the current one
-- Ctrl+Shift+Enter | ⌘⇧↩ | None | Start a new line above the current one
-- Ctrl+Alt+Down | ^⌘⇣ | M-Down | Scroll line down
-- Ctrl+Alt+Up | ^⌘⇡ | M-Up | Scroll line up
-- Alt+PgUp | ^⇞ | N/A | Scroll page up
-- Alt+PgDn | ^⇟ | N/A | Scroll page down
-- Menu<br/> Shift+F10^(§) | N/A | N/A | Show context menu
-- Ctrl+Alt+Shift+R *c* | ^⌘⇧R *c* | M-S-R *c* | Save macro to alphanumeric register *c*
-- Ctrl+Alt+R *c* | ^⌘R *c* | M-R *c* | Load and play macro from alphanumeric register *c*
-- **Movement**| | |
-- Down | ⇣<br/> ^N | Down | Line down
-- Shift+Down | ⇧⇣<br/>^⇧N | S-Down | Line down extend selection
-- Alt+Shift+Down | ^⇧⇣ | M-S-Down | Line down extend rect. selection
-- Ctrl+Down | ⌥⇣ | ^Down | Paragraph down
-- Ctrl+Shift+Down | ⌥⇧⇣ | S-^Down | Paragraph down extend selection
-- Up | ⇡<br/> ^P | Up | Line up
-- Shift+Up | ⇧⇡<br/>^⇧P | S-Up | Line up extend selection
-- Alt+Shift+Up | ^⇧⇡ | M-S-Up | Line up extend rect. selection
-- Ctrl+Up | ⌥⇡ | ^Up | Paragraph up
-- Ctrl+Shift+Up | ⌥⇧⇡ | S-^Up | Paragraph up extend selection
-- Left | ⇠<br/> ^B | Left | Char left
-- Shift+Left | ⇧⇠<br/>^⇧B | S-Left | Char left extend selection
-- Alt+Shift+Left | ^⇧⇠ | M-S-Left | Char left extend rect. selection
-- Ctrl+Left | ⌥⇠ | ^Left | Word left
-- Ctrl+Shift+Left | ⌥⇧⇠ | S-^Left | Word left extend selection
-- Ctrl+Alt+Left | ^⌥⇠ | None | Word part left
-- Ctrl+Alt+Shift+Left | ^⌥⇧⇠ | None | Word part left extend selection
-- Right | ⇢<br/> ^F | Right | Char right
-- Shift+Right | ⇧⇢<br/>^⇧F | S-Right | Char right extend selection
-- Alt+Shift+Right | ^⇧⇢ | M-S-Right | Char right extend rect. selection
-- Ctrl+Right | ⌥⇢ | ^Right | Word right
-- Ctrl+Shift+Right | ⌥⇧⇢ | S-^Right | Word right extend selection
-- Ctrl+Alt+Right | ^⌥⇢ | None | Word part right
-- Ctrl+Alt+Shift+Right | ^⌥⇧⇢ | None | Word part right extend selection
-- Home | ↖<br/>⌘⇠<br/> ^A | Home | Line start
-- Shift+Home | ⇧↖<br/>⌘⇧⇠<br/>^⇧A | None | Line start extend selection
-- Alt+Shift+Home | ^⇧↖ | None | Line start extend rect. selection
-- Ctrl+Home | ⌘↖ | None | Document start
-- Ctrl+Shift+Home | ⌘⇧↖ | None | Document start extend selection
-- End | ↘<br/>⌘⇢<br/> ^E | End | Line end
-- Shift+End | ⇧↘<br/>⌘⇧⇢<br/>^⇧E | None | Line end extend selection
-- Alt+Shift+End | ^⇧↘ | None | Line end extend rect. selection
-- Ctrl+End | ⌘↘ | None | Document end
-- Ctrl+Shift+End | ⌘⇧↘ | None | Document end extend selection
-- PgUp | ⇞ | PgUp | Page up
-- Shift+PgUp | ⇧⇞ | None | Page up extend selection
-- Alt+Shift+PgUp | ^⇧⇞ | None | Page up extend rect. selection
-- PgDn | ⇟ | PgDn | Page down
-- Shift+PgDn | ⇧⇟ | None | Page down extend selection
-- Alt+Shift+PgDn | ^⇧⇟ | None | Page down extend rect. selection
-- Ctrl+Del | ⌘⌦ | ^Del | Delete word right
-- Ctrl+Shift+Del | ⌘⇧⌦ | S-^Del | Delete line right
-- Ins | Ins | Ins | Toggle overtype
-- Bksp | ⌫<br/> ^H | Bksp<br/> ^H | Delete back
-- Ctrl+Bksp | ⌘⌫ | None | Delete word left
-- Ctrl+Shift+Bksp | ⌘⇧⌫ | None | Delete line left
-- Tab | ⇥ | Tab<br/> ^I | Insert tab or indent
-- Shift+Tab | ⇧⇥ | S-Tab | Dedent
-- None | ^K | None | Cut to line end
-- None | ^L | None | Center line vertically
-- N/A | N/A | ^^ | Mark text at the caret position
-- N/A | N/A | ^] | Swap caret and mark anchor
-- **Find Fields**|||
-- Left | ⇠<br/> ^B | Left<br/> ^B | Cursor left
-- Right | ⇢<br/> ^F | Right<br/> ^F | Cursor right
-- Del | ⌦ | Del | Delete forward
-- Bksp | ⌫ | Bksp<br/> ^H | Delete back
-- Ctrl+V | ⌘V | ^V | Paste
-- N/A | N/A | ^X | Cut all
-- N/A | N/A | ^Y | Copy all
-- N/A | N/A | ^U | Erase all
-- Home | ↖<br/>⌘⇠<br/> ^A | Home<br/> ^A | Home
-- End | ↘<br/>⌘⇢<br/> ^E | End<br/> ^E | End
-- N/A | N/A | ^T | Transpose characters
-- N/A | N/A | Tab | Toggle find/replace buttons
-- Tab | ⇥ | Down | Focus replace field
-- Shift+Tab | ⇧⇥ | Up | Focus find field
-- Up | ⇡ | ^P | Cycle back through history
-- Down | ⇣ | ^N | Cycle forward through history
-- N/A | N/A | F1 | Toggle "Match Case"
-- N/A | N/A | F2 | Toggle "Whole Word"
-- N/A | N/A | F3 | Toggle "Regex"
-- N/A | N/A | F4 | Toggle "Find in Files"
--
-- *: For use when the `-p` or `--preserve` command line option is given to the non-Windows
-- terminal version, since ^S and ^Q are flow control sequences.
--
-- †: If you prefer ^Z to suspend, you can bind it to `ui.suspend()`.
--
-- ‡: Some versions of Linux intercept this for Unicode input.
--
-- §: Only on Windows or the GTK version on Linux.
--
-- @module textadept.keys
local M = {}

-- Windows, Linux, and BSD key bindings.
--
-- Unassigned keys:
-- ctrl:  EGhHiIJNQtY_(){;:'",<.>?\s
-- alt: -_=+)]}\|;:/?\s\n
-- ctrl+alt: aAbBcCDFHiIjJlLmMnNoOpPqQsSTUvVxXyYzZ()[]{}\;:'",<.>/?\s\t\n
--
-- macOS key bindings.
--
-- Unassigned keys:
-- cmd:  EGhHiIJNQtY_(){;:'"<.>?\s
-- ctrl: cCDgGHiIjJKLmMoOqQrRsStTuUvVwWxXyYzZ-_=+)]}\|;:/?\s\n
-- ctrl+cmd: aAbBcCDFHiIjJlLmMnNoOpPqQsSTUvVxXyYzZ()[]{}\;:'",<.>/?\s\t\n
--
-- Curses key bindings.
--
-- Key bindings available depend on your implementation of curses.
--
-- For ncurses (macOS, Linux, and BSD):
-- - The only Control keys recognized are 'ctrl+a'-'ctrl+z', 'ctrl+ ', 'ctrl+\\', 'ctrl+]',
--	'ctrl+^', and 'ctrl+_'.
-- - Control+Shift and Control+Meta+Shift keys are not recognized.
-- - Modifiers for function keys F1-F12 are not recognized.
-- For pdcurses (Windows):
-- - Many Control+Symbol keys are not recognized, but most Control+Shift+Symbol keys are.
-- - Ctrl+Meta+Symbol keys are not recognized.
--
-- Unassigned keys:
-- ctrl: t\s
-- meta: aAbBcCDHiIjJlLMnNoOpPQUvVxXyYzZ);:?\s
-- ctrl+meta:  eghijnqy_]\^
--
-- Note: meta+[befhstv] may be used by Linux/BSD GUI terminals for menu access.

--- Returns the menu command associated with the given menu path.
-- @param path Path to the menu item.
-- @usage m('Edit/Select/Select in XML Tag')
local function m(path) return textadept.menu.menubar[path][2] end

--- Starts a new line below or above the current one.
-- @param above Whether or not to start a new line above the current one. The default value is
--	`false.`
local function start_new_line(above)
	local line = buffer:line_from_position(buffer.current_pos)
	if above then buffer:line_up() end
	if not above or above and line > 1 then buffer:line_end() end
	buffer:new_line()
	if above and line == 1 then buffer:line_up() end
end

--- Shows the popup context menu.
local function show_context_menu() ui.popup_menu(ui.context_menu) end

--- Returns a macro register key chain for the given macro function (save or play).
-- Non-alphanumeric keys are invalid registers.
local function macro_register(f)
	return setmetatable({}, {
		__index = function(_, k) return k:find('^%w$') and function() f(k) end or false end
	})
end

-- Bindings for Windows/Linux/BSD, macOS, Terminal.
local bindings = {
	-- File.
	[buffer.new] = {'ctrl+n', 'cmd+n', 'ctrl+n'}, --
	[io.open_file] = {'ctrl+o', 'cmd+o', 'ctrl+o'},
	-- TODO: io.open_recent_file
	-- TODO: buffer.reload
	[buffer.save] = {'ctrl+s', 'cmd+s', {'ctrl+s', 'meta+s', 'meta+S'}}, --
	[buffer.save_as] = {'ctrl+S', 'cmd+S', 'ctrl+meta+s'},
	-- TODO: io.save_all_files
	[buffer.close] = {'ctrl+w', 'cmd+w', 'ctrl+w'}, --
	[io.close_all_buffers] = {'ctrl+W', 'cmd+W', 'ctrl+meta+w'},
	-- TODO: textadept.sessions.load
	-- TODO: textadept.sessions.save
	[quit] = {'ctrl+q', 'cmd+q', {'ctrl+q', 'meta+q'}},

	-- Edit.
	[buffer.undo] = {'ctrl+z', 'cmd+z', 'ctrl+z'},
	[buffer.redo] = {{'ctrl+y', 'ctrl+Z'}, {'cmd+Z', 'cmd+y'}, {'ctrl+y', 'ctrl+meta+z'}},
	[buffer.cut] = {'ctrl+x', 'cmd+x', 'ctrl+x'}, --
	[buffer.copy] = {'ctrl+c', 'cmd+c', 'ctrl+c'}, --
	[buffer.paste] = {'ctrl+v', 'cmd+v', 'ctrl+v'},
	[textadept.editing.paste_reindent] = {'ctrl+V', 'cmd+V', 'ctrl+meta+v'},
	[buffer.selection_duplicate] = {'ctrl+D', 'cmd+D', 'ctrl+meta+d'},
	[buffer.clear] = {'del', {'del', 'ctrl+d'}, 'del'},
	[m('Edit/Delete Word')] = {'alt+del', 'ctrl+del', 'meta+del'},
	[buffer.select_all] = {'ctrl+a', 'cmd+a', 'ctrl+a'},
	[m('Edit/Deselect')] = {'ctrl+A', 'cmd+A', 'ctrl+meta+a'},
	[m('Edit/Match Brace')] = {'ctrl+m', 'cmd+m', 'meta+m'},
	[m('Edit/Complete Word')] = {'ctrl+\n', 'cmd+\n', {'ctrl+j', 'ctrl+\n'}},
	[textadept.editing.toggle_comment] = {'ctrl+/', 'cmd+/', {'ctrl+_', 'ctrl+@', 'meta+/'}},
	[textadept.editing.join_lines] = {'ctrl+j', 'cmd+j', 'meta+j'},
	[m('Edit/Filter Through')] = {'ctrl+|', 'cmd+|', {'ctrl+\\', 'ctrl+|'}},
	-- Select.
	[m('Edit/Select/Select between Matching Delimiters')] = {
		'ctrl+M', 'cmd+M', {'ctrl+meta+m', 'meta+\n', 'ctrl+shift+\n'}
	}, [textadept.editing.select_word] = {'ctrl+d', 'cmd+d', 'ctrl+d'},
	[m('Edit/Select/Deselect Word')] = {'ctrl+alt+d', 'ctrl+cmd+d', 'meta+d'},
	[textadept.editing.select_line] = {'ctrl+l', 'cmd+l', 'ctrl+l'},
	[textadept.editing.select_paragraph] = {'ctrl+P', 'cmd+P', 'ctrl+meta+p'},
	-- Selection.
	[m('Edit/Selection/Upper Case Selection')] = {{'ctrl+U', 'ctrl+alt+U'}, 'cmd+U', 'ctrl+meta+u'},
	[m('Edit/Selection/Lower Case Selection')] = {'ctrl+u', 'cmd+u', 'ctrl+u'},
	[m('Edit/Selection/Enclose as XML Tags')] = {'alt+<', 'ctrl+<', 'meta+<'},
	[m('Edit/Selection/Enclose as Single XML Tag')] = {'alt+>', 'ctrl+>', 'meta+>'},
	[m('Edit/Selection/Enclose in Single Quotes')] = {"alt+'", "ctrl+'", "meta+'"},
	[m('Edit/Selection/Enclose in Double Quotes')] = {'alt+"', 'ctrl+"', 'meta+"'},
	[m('Edit/Selection/Enclose in Parentheses')] = {'alt+(', 'ctrl+(', 'meta+('},
	[m('Edit/Selection/Enclose in Brackets')] = {'alt+[', 'ctrl+[', nil},
	[m('Edit/Selection/Enclose in Braces')] = {'alt+{', 'ctrl+{', 'meta+{'},
	[buffer.move_selected_lines_down] = {'ctrl+alt+shift+down', 'ctrl+cmd+shift+down', nil},
	[buffer.move_selected_lines_up] = {'ctrl+alt+shift+up', 'ctrl+cmd+shift+up', nil},
	-- History.
	[textadept.history.back] = {{'ctrl+[', 'alt+left'}, 'cmd+[', {'meta+[', 'meta+left'}},
	[textadept.history.forward] = {{'ctrl+]', 'alt+right'}, 'cmd+]', {'meta+]', 'meta+right'}},
	-- TODO: textadept.history.record
	-- TODO: textadept.history.clear
	-- Preferences.
	[m('Edit/Preferences')] = {nil, 'cmd+,', nil},

	-- Search.
	[ui.find.focus] = {'ctrl+f', 'cmd+f', 'ctrl+f'},
	-- TODO: ui.find.find_next
	-- TODO: ui.find.find_prev
	-- TODO: ui.find.replace
	-- TODO: ui.find.replace_all
	-- Find Next is alt+n when find pane is focused in GUI.
	-- Find Prev is alt+p when find pane is focused in GUI.
	-- Replace is alt+r when find pane is focused in GUI.
	-- Replace All is alt+a when find pane is focused in GUI.
	[m('Search/Find Incremental')] = {'ctrl+alt+f', 'ctrl+cmd+f', 'meta+f'},
	[m('Search/Find in Files')] = {'ctrl+F', 'cmd+F', {'ctrl+meta+f', 'ctrl+meta+F'}},
	-- Find in Files is alt+i when find pane is focused in GUI.
	[m('Search/Go To Next File Found')] = {'ctrl+alt+g', 'ctrl+cmd+g', 'meta+g'},
	[m('Search/Go To Previous File Found')] = {'ctrl+alt+G', 'ctrl+cmd+G', 'meta+G'},
	[textadept.editing.goto_line] = {'ctrl+g', 'cmd+g', 'ctrl+g'},

	-- Tools.
	[ui.command_entry.run] = {'ctrl+e', 'cmd+e', 'ctrl+e'},
	[m('Tools/Select Command')] = {'ctrl+p', 'cmd+p', 'ctrl+p'},
	[textadept.run.run] = {'ctrl+r', 'cmd+r', 'ctrl+r'},
	[textadept.run.compile] = {'ctrl+C', 'cmd+C', 'ctrl+meta+c'},
	[textadept.run.build] = {'ctrl+B', 'cmd+B', 'ctrl+meta+b'},
	[textadept.run.test] = {'ctrl+T', 'cmd+T', 'ctrl+meta+t'},
	[textadept.run.run_project] = {'ctrl+R', 'cmd+R', 'ctrl+meta+r'},
	[textadept.run.stop] = {'ctrl+X', 'cmd+X', 'ctrl+meta+x'},
	[m('Tools/Next Error')] = {'ctrl+alt+e', 'ctrl+cmd+e', 'meta+e'},
	[m('Tools/Previous Error')] = {'ctrl+alt+E', 'ctrl+cmd+E', 'meta+E'},
	-- Bookmark.
	[textadept.bookmarks.toggle] = {'ctrl+k', 'cmd+k', 'ctrl+k'},
	-- TODO: textadept.bookmarks.clear
	[m('Tools/Bookmarks/Next Bookmark')] = {'ctrl+alt+k', 'ctrl+cmd+k', 'meta+k'},
	[m('Tools/Bookmarks/Previous Bookmark')] = {'ctrl+alt+K', 'ctrl+cmd+K', 'meta+K'},
	[textadept.bookmarks.goto_mark] = {'ctrl+K', 'cmd+K', 'ctrl+alt+k'},
	-- Macros.
	[textadept.macros.record] = {'alt+,', 'ctrl+,', 'meta+,'},
	[textadept.macros.play] = {'alt+.', 'ctrl+.', 'meta+.'},
	-- TODO: textadept.macros.save
	-- TODO: textadept.macros.load
	-- Quick Open.
	[m('Tools/Quick Open/Quickly Open User Home')] = {'ctrl+alt+u', 'ctrl+cmd+u', 'meta+u'},
	[m('Tools/Quick Open/Quickly Open Textadept Home')] = {'ctrl+alt+h', 'ctrl+cmd+h', 'meta+h'},
	-- TODO: m('Tools/Quick Open/Quickly Open Current Directory')
	[io.quick_open] = {'ctrl+O', 'cmd+O', 'ctrl+meta+o'},
	-- Snippets.
	-- TODO: textadept.snippets.select
	[textadept.snippets.insert] = {'\t', '\t', '\t'},
	[textadept.snippets.previous] = {'shift+\t', 'shift+\t', 'shift+\t'},
	[textadept.snippets.cancel] = {'esc', 'esc', 'esc'},
	-- TODO: m('Tools/Snippets/Complete Trigger Word')
	-- Other.
	-- TODO: m('Tools/Show Style')
	
	-- Buffer.
	[m('Buffer/Next Buffer')] = {
		{'ctrl+\t', 'ctrl+pgdn'}, {'ctrl+\t', 'cmd+pgdn'}, WIN32 and 'ctrl+\t' or 'meta+pgdn'
	}, [m('Buffer/Previous Buffer')] = {
		{'ctrl+shift+\t', 'ctrl+pgup'}, {'ctrl+shift+\t', 'cmd+pgup'},
		WIN32 and 'ctrl+shift+\t' or 'meta+pgup'
	}, [ui.switch_buffer] = {'ctrl+b', 'cmd+b', 'ctrl+b'},
	-- Indentation.
	-- TODO: m('Buffer/Indentation/Tab width: 2')
	-- TODO: m('Buffer/Indentation/Tab width: 3')
	-- TODO: m('Buffer/Indentation/Tab width: 4')
	-- TODO: m('Buffer/Indentation/Tab width: 8')
	[m('Buffer/Indentation/Toggle Use Tabs')] = {'ctrl+alt+t', 'ctrl+cmd+t', {'meta+t', 'meta+T'}},
	-- TODO: textadept.editing.convert_indentation
	-- EOL Mode.
	-- TODO: m('Buffer/EOL Mode/CRLF')
	-- TODO: m('Buffer/EOL Mode/LF')
	-- Encoding.
	-- TODO: m('Buffer/Encoding/UTF-8 Encoding')
	-- TODO: m('Buffer/Encoding/ASCII Encoding')
	-- TODO: m('Buffer/Encoding/CP-1252 Encoding')
	-- TODO: m('Buffer/Encoding/UTF-16 Encoding')
	[m('Buffer/Select Lexer...')] = {'ctrl+L', 'cmd+L', 'ctrl+meta+l'},

	-- View.
	[m('View/Next View')] = {
		'ctrl+alt+pgdn', 'ctrl+cmd+pgdn', WIN32 and 'meta+pgdn' or 'ctrl+meta+pgdn'
	}, [m('View/Previous View')] = {
		'ctrl+alt+pgup', 'ctrl+cmd+pgup', WIN32 and 'meta+pgup' or 'ctrl+meta+pgup'
	}, [m('View/Split View Horizontal')] = {'ctrl+alt+_', 'ctrl+cmd+_', 'meta+_'},
	[m('View/Split View Vertical')] = {'ctrl+alt+|', 'ctrl+cmd+|', 'meta+|'},
	[m('View/Unsplit View')] = {'ctrl+alt+w', 'ctrl+cmd+w', 'meta+w'},
	[m('View/Unsplit All Views')] = {'ctrl+alt+W', 'ctrl+cmd+W', 'meta+W'}, --
	[m('View/Grow View')] = {
		{'ctrl+alt++', 'ctrl+alt+='}, {'ctrl+cmd++', 'ctrl+cmd+='}, {'meta++', 'meta+='}
	}, [m('View/Shrink View')] = {'ctrl+alt+-', 'ctrl+cmd+-', 'meta+-'},
	[m('View/Toggle Current Fold')] = {'ctrl+}', 'cmd+}', 'meta+}'},
	[m('View/Toggle Wrap Mode')] = {'ctrl+\\', 'cmd+\\', 'meta+\\'},
	-- TODO: m('View/Toggle Show Indent Guides')
	-- TODO: m('View/Toggle View Whitespace')
	-- TODO: m('View/Toggle Virtual Space')
	[view.zoom_in] = {'ctrl+=', 'cmd+=', nil}, --
	[view.zoom_out] = {'ctrl+-', 'cmd+-', nil}, --
	[m('View/Reset Zoom')] = {'ctrl+0', 'cmd+0', nil},

	-- Help.
	[m('Help/Show Manual')] = {'f1', 'f1', nil},
	[m('Help/Show LuaDoc')] = {'shift+f1', 'shift+f1', nil},

	-- Other.
	[view.line_scroll_down] = {'ctrl+alt+down', 'ctrl+cmd+down', 'meta+down'},
	[view.line_scroll_up] = {'ctrl+alt+up', 'ctrl+cmd+up', 'meta+up'},
	[function() view:line_scroll(0, view.lines_on_screen) end] = {'alt+pgdn', 'ctrl+pgdn', nil},
	[function() view:line_scroll(0, -view.lines_on_screen) end] = {'alt+pgup', 'ctrl+pgup', nil},
	[start_new_line] = {'shift+\n', 'shift+\n', nil},
	[function() start_new_line(true) end] = {'ctrl+shift+\n', 'cmd+shift+\n', nil},
	[show_context_menu] = {'menu', nil, nil},
	[macro_register(textadept.macros.save)] = {'ctrl+alt+R', 'ctrl+cmd+R', 'meta+R'},
	[macro_register(textadept.macros.play)] = {'ctrl+alt+r', 'ctrl+cmd+r', 'meta+r'},

	-- Unbound keys are handled by Scintilla, but when playing back a macro, this is not possible.
	-- Define some useful default key bindings so Scintilla does not have to handle them. Note
	-- that Scintilla still will handle some keys.
	
	-- Built-in movement commands.
	[buffer.line_down] = {'down', {'down', 'ctrl+n'}, 'down'},
	[buffer.line_down_extend] = {'shift+down', {'shift+down', 'ctrl+N'}, 'shift+down'},
	[buffer.line_up] = {'up', {'up', 'ctrl+p'}, 'up'},
	[buffer.line_up_extend] = {'shift+up', {'shift+up', 'ctrl+P'}, 'shift+up'},
	[buffer.char_left] = {'left', {'left', 'ctrl+b'}, 'left'},
	[buffer.char_left_extend] = {'shift+left', {'shift+left', 'ctrl+B'}, 'shift+left'},
	[buffer.word_left] = {'ctrl+left', 'alt+left', 'ctrl+left'},
	[buffer.word_left_extend] = {'ctrl+shift+left', 'alt+shift+left', 'ctrl+shift+left'},
	[buffer.char_right] = {'right', {'right', 'ctrl+f'}, 'right'},
	[buffer.char_right_extend] = {'shift+right', {'shift+right', 'ctrl+F'}, 'shift+right'},
	[buffer.word_right] = {'ctrl+right', 'alt+right', 'ctrl+right'},
	[buffer.word_right_end_extend] = {'ctrl+shift+right', 'alt+shift+right', 'ctrl+shift+right'},
	[buffer.vc_home] = {'home', {'home', 'cmd+left', 'ctrl+a'}, 'home'},
	[buffer.vc_home_extend] = {'shift+home', {'shift+home', 'cmd+shift+left', 'ctrl+A'}, nil},
	[buffer.line_end] = {'end', {'end', 'cmd+right', 'ctrl+e'}, 'end'},
	[buffer.line_end_extend] = {'shift+end', {'shift+end', 'cmd+shift+right', 'ctrl+E'}, nil},
	-- Custom movement commands.
	[buffer.word_part_right] = {'ctrl+alt+right', 'ctrl+alt+right', nil},
	[buffer.word_part_right_extend] = {'ctrl+alt+shift+right', 'ctrl+alt+shift+right', nil},
	[buffer.word_part_left] = {'ctrl+alt+left', 'ctrl+alt+left', nil},
	[buffer.word_part_left_extend] = {'ctrl+alt+shift+left', 'ctrl+alt+shift+left', nil},
	[buffer.para_down] = {'ctrl+down', 'alt+down', 'ctrl+down'},
	[buffer.para_down_extend] = {'ctrl+shift+down', 'alt+shift+down', 'ctrl+shift+down'},
	[buffer.para_up] = {'ctrl+up', 'alt+up', 'ctrl+up'},
	[buffer.para_up_extend] = {'ctrl+shift+up', 'alt+shift+up', 'ctrl+shift+up'},
	-- Change rectangular selection modifier on macOS to ^.
	[buffer.line_down_rect_extend] = {nil, 'ctrl+shift+down', nil},
	[buffer.line_up_rect_extend] = {nil, 'ctrl+shift+up', nil},
	[buffer.char_left_rect_extend] = {nil, 'ctrl+shift+left', nil},
	[buffer.char_right_rect_extend] = {nil, 'ctrl+shift+right', nil},
	[buffer.vc_home_rect_extend] = {nil, 'ctrl+shift+home', nil},
	[buffer.line_end_rect_extend] = {nil, 'ctrl+shift+end', nil},
	[buffer.page_down_rect_extend] = {nil, 'ctrl+shift+pgdn', nil},
	[buffer.page_up_rect_extend] = {nil, 'ctrl+shift+pgup', nil},

	-- Built-in editing commands.
	[buffer.del_word_right] = {'ctrl+del', 'cmd+del', 'ctrl+del'},
	[buffer.del_line_right] = {'ctrl+shift+del', 'cmd+shift+del', 'ctrl+shift+del'},
	[buffer.delete_back] = {'\b', {'\b', 'ctrl+h'}, {'\b', 'ctrl+h'}},
	[buffer.del_word_left] = {'ctrl+\b', 'cmd+\b', nil},
	[buffer.del_line_left] = {'ctrl+shift+\b', 'cmd+shift+\b', nil},
	-- Custom editing commands.
	[function()
		buffer:line_end_extend()
		buffer[not buffer.selection_empty and 'cut' or 'clear'](buffer)
	end] = {nil, 'ctrl+k', nil}, --
	[view.vertical_center_caret] = {nil, 'ctrl+l', nil},
	[function() buffer.selection_mode = 0 end] = {nil, nil, 'ctrl+^'},
	[buffer.swap_main_anchor_caret] = {nil, nil, 'ctrl+]'}
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

if WIN32 or GTK then keys['shift+f10'] = show_context_menu end

return M

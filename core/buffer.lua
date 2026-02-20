-- Copyright 2007-2026 Mitchell. See LICENSE.

--- A Textadept buffer or view object.
--
-- Any buffer and view fields set on startup (e.g. in *~/.textadept/init.lua*) will be the
-- default, initial values for all buffers and views.
--
-- ### Contents
-- @classmod buffer

--- Replacement for original `buffer:text_range()`, which has a C struct for an argument.
local function text_range(buffer, start_pos, end_pos)
	local target_start, target_end = buffer.target_start, buffer.target_end
	buffer:set_target_range(math.max(1, assert_type(start_pos, 'number', 2)),
		math.min(assert_type(end_pos, 'number', 3), buffer.length + 1))
	local text = buffer.target_text
	buffer:set_target_range(target_start, target_end) -- restore
	return text
end
events.connect(events.BUFFER_NEW, function() buffer.text_range = text_range end, 1)

-- Implement `events.BUFFER_{BEFORE,AFTER}_REPLACE_TEXT` as a convenience in lieu of the
-- undocumented `events.MODIFIED`.
local DELETE, INSERT, UNDOREDO = _SCINTILLA.MOD_BEFOREDELETE, _SCINTILLA.MOD_INSERTTEXT,
	_SCINTILLA.MULTILINEUNDOREDO
--- Helper function for emitting `events.BUFFER_AFTER_REPLACE_TEXT` after a full-buffer undo/redo
-- operation, e.g. after reloading buffer contents and then performing an undo.
local function emit_after_replace_text()
	events.disconnect(events.UPDATE_UI, emit_after_replace_text)
	events.emit(events.BUFFER_AFTER_REPLACE_TEXT)
end
-- Emits events prior to and after replacing buffer text.
events.connect(events.MODIFIED, function(_, mod, _, length)
	if mod & (DELETE | INSERT) == 0 or length ~= buffer.length then return end
	if mod & (INSERT | UNDOREDO) == INSERT | UNDOREDO then
		-- Cannot emit BUFFER_AFTER_REPLACE_TEXT here because Scintilla will do things like update
		-- the selection afterwards, which could undo what event handlers do.
		events.connect(events.UPDATE_UI, emit_after_replace_text)
		return
	end
	events.emit(mod & DELETE > 0 and events.BUFFER_BEFORE_REPLACE_TEXT or
		events.BUFFER_AFTER_REPLACE_TEXT)
end)

--- Buffer and View Introduction.
-- Internally, Textadept uses the [Scintilla][] editing component for editing text. It breaks
-- up Scintilla's monolithic API into two parts: buffers and views. Buffers are responsible for
-- text editing, selections, and navigation. Views are responsible for visual things like text
-- and selection display, margins, markers, and highlights. This is a best-effort attempt to
-- allow for sensible object-oriented scripting with an editing component that combines the data
-- model and view model into one entity. It is not perfect and my not make complete sense at times.
--
-- That said, this buffer and view API is largely interchangeable: `view.field` and
-- `view:function()` are often equivalent to `buffer.field` and `buffer:function()`, respectively,
-- and vice-versa.
--
-- Only one buffer and one view at a time is considered "current" (i.e. has focus). While
-- Textadept allows you to work with non-current buffers, you should only work with `buffer`
-- unless you know what you are doing.  For example, `buffer:select_all()` will visually
-- select all text in the current buffer, but `buf:select_all()` where `buf ~= buffer` will
-- not make a visible selection, even if `buf` is visible in another view. Despite this,
-- `buf:replace_sel('')` will still clear that buffer since it previously selected all text.
-- (Basically, you can make "background" edits of non-current buffers in an object-oriented way.)
--
-- [Scintilla]: https://scintilla.org/ScintillaDoc.html
-- @section

--- Placeholder for introduction section.
-- @field _

--- Create Buffers and Views.
-- @section

--- Creates a new buffer and displays it in the current view.
-- @return the new buffer
-- @see io.open_file
-- @see events.BUFFER_NEW
-- @function new

--- Splits the view and focuses the new view.
-- @param[opt=false] vertical Split the view vertically into left and right views instead of
--	splitting horizontally into top and bottom views.
-- @return old view, new view
-- @see events.VIEW_NEW
-- @function view:split

--- Unsplits the view if possible.
-- @return whether or not the view was unsplit.
-- @function view:unsplit

--- View Information.
-- @section

--- The [buffer](#the-buffer-module) the view currently contains. (Read-only)
-- @table view.buffer

--- The split resizer's pixel position if the view is a split one.
-- @see ui.get_split_table
-- @field view.split_pos

--- The parent split resizer's pixel position if the view's parent is a split one.
-- @see ui.get_split_table
-- @field view.parent_split_pos

--- Work with Files.
-- **Note:** this module does not open files. `io.open_file()` does.
-- @section

--- Reloads the buffer's file contents, discarding any changes.
-- @function reload

--- Saves the buffer to its file.
-- If the buffer does not have a file, the user is prompted for one.
-- @return `true` if the file was saved; `nil` otherwise.
-- @see textadept.editing.strip_trailing_spaces
-- @see io.ensure_final_newline
-- @see io.save_all_files
-- @see events.FILE_BEFORE_SAVE
-- @see events.FILE_AFTER_SAVE
-- @function save

--- Saves the buffer to another file.
-- @param[opt] filename String path to save the buffer to. If `nil`, the user is prompted for one.
-- @return `true` if the file was saved; `nil` otherwise.
-- @see events.FILE_AFTER_SAVE
-- @function save_as

--- Closes the buffer.
-- @param[opt=false] force Discard unsaved changes without prompting the user to confirm.
-- @return `true` if the buffer was closed; `nil` otherwise.
-- @see io.close_all_buffers
-- @function close

--- Converts the buffer's contents to another encoding.
-- @param encoding String encoding to convert to. Valid encodings are ones that `string.iconv()`
--	accepts, or `nil` for a binary encoding.
-- @see io.encodings
-- @function set_encoding

--- The buffer's absolute file path (if any).
-- @see _G._CHARSET
-- @field filename

--- Whether or not the buffer has unsaved changes. (Read-only)
-- @field modify

--- Mark the buffer as having no unsaved changes.
-- @function set_save_point

--- The buffer's encoding, or `nil` for a binary file.
-- Do not change this field manually. Call `buffer:set_encoding()` instead.
-- @field encoding

--- Move Within Lines.
-- Movements within the current buffer scroll the caret into view if it is not already visible.
-- @section

--- Moves the caret left one character.
-- @function char_left

--- Moves the caret right one character.
-- @function char_right

--- Moves the caret to the previous part of the current word.
-- Word parts are delimited by underscore characters or changes in capitalization.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_part_left

--- Moves the caret to the next part of the current word.
-- Word parts are delimited by underscore characters or changes in capitalization.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_part_right

--- Moves the caret left one word, positioning it at the end of the previous word.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_left_end

--- Moves the caret right one word, positioning it at the end of the current word.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_right_end

--- Moves the caret left one word.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_left

--- Moves the caret right one word.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_right

--- Moves the caret to the beginning of the current line.
-- @function home

--- Moves the caret to the end of the current line.
-- @function line_end

--- Moves the caret to the beginning of the current wrapped line.
-- @function home_display

--- Moves the caret to the end of the current wrapped line.
-- @function line_end_display

--- Moves the caret to the beginning of the current wrapped line or, if already there, to the
-- beginning of the actual line.
-- @function home_wrap

--- Moves the caret to the end of the current wrapped line or, if already there, to the end of
-- the actual line.
-- @function line_end_wrap

--- Moves the caret to the first visible character on the current line or, if already there,
-- to the beginning of the current line.
-- @function vc_home

--- Moves the caret to the first visible character on the current wrapped line or, if already
-- there, to the beginning of the current wrapped line.
-- @function vc_home_display

--- Moves the caret to the first visible character on the current wrapped line or, if already
-- there, to the beginning of the actual line.
-- @function vc_home_wrap

--- Move Between Lines.
-- Movements within the current buffer scroll the caret into view if it is not already visible.
-- @section

--- Moves the caret to a position and scrolls it into view.
-- @param pos Position to move to.
-- @function goto_pos

--- Moves the caret to the beginning of a line and scrolls it into view, even if that line
-- is hidden.
-- @param line Line number to go to.
-- @see textadept.editing.goto_line
-- @function goto_line

--- Moves the caret up one line.
-- @function line_up

--- Moves the caret down one line.
-- @function line_down

--- The caret's preferred horizontal position when moving between lines.
-- - `buffer.CARETSTICKY_OFF`: Use the same position the caret had on the previous line.
-- - `buffer.CARETSTICKY_ON`: Use the last position the caret was moved to via the mouse,
--	left/right arrow keys, home/end keys, etc. Typing text does not affect the position.
-- - `buffer.CARETSTICKY_WHITESPACE`: Use the position the caret had on the previous line,
--	but prior to any inserted indentation.
--
-- The default value is `buffer.CARETSTICKY_OFF`.
-- @field caret_sticky

--- Use the same position the caret had on the previous line.
-- @field CARETSTICKY_OFF

--- Use the last position the caret was moved to via the mouse, left/right arrow keys, home/end
--	keys, etc. Typing text does not affect the position.
-- @field CARETSTICKY_ON

--- Use the position the caret had on the previous line, but prior to any inserted indentation.
-- @field CARETSTICKY_WHITESPACE

--- Declares the current horizontal caret position as the caret's preferred horizontal position
-- when moving between lines.
-- @function choose_caret_x

--- Toggles `buffer.caret_sticky` between `buffer.CARETSTICKY_ON` and `buffer.CARETSTICKY_OFF`.
-- @function toggle_caret_sticky

--- Move Between Pages.
-- Movements within the current buffer scroll the caret into view if it is not already visible.
-- @section

--- Moves the caret to the top of the page or, if already there, up one page.
-- @function stuttered_page_up

--- Moves the caret to the bottom of the page or, if already there, down one page.
-- @function stuttered_page_down

--- Moves the caret up one page.
-- @function page_up

--- Moves the caret down one page.
-- @function page_down

--- Move Between Buffers.
-- Movements between buffers do not scroll the caret into view if it is not visible.
-- @section

--- Switches to another buffer.
-- @param buffer Buffer to switch to, or index of a relative buffer to switch to (typically 1
--	or -1).
-- @see events.BUFFER_BEFORE_SWITCH
-- @see events.BUFFER_AFTER_SWITCH
-- @usage view:goto_buffer(_BUFFERS[1]) -- switch to first buffer
-- @usage view:goto_buffer(-1) -- switch to the buffer before the current one
-- @function view:goto_buffer

--- Other Movements.
-- Movements within the current buffer scroll the caret into view if it is not already visible.
-- @section

--- Moves the caret up one paragraph.
-- Paragraphs are surrounded by one or more blank lines.
-- @function para_up

--- Moves the caret down one paragraph.
-- Paragraphs are surrounded by one or more blank lines.
-- @function para_down

--- Moves the caret into view if it is not already, removing any selections.
-- @function move_caret_inside_view

--- Moves the caret to the beginning of the buffer.
-- @function document_start

--- Moves the caret to the end of the buffer.
-- @function document_end

--- Retrieve Text.
-- @section

--- Returns the buffer's text.
-- @function get_text

--- Returns the selected text.
-- Multiple selections are included in order, separated by `buffer.copy_separator`. Rectangular
-- selections are included from top to bottom with end of line characters. Virtual space is
-- not included.
-- @function get_sel_text

--- The string added between multiple selections in `buffer:get_sel_text()`.
-- The default value is the empty string (no separators).
-- @field copy_separator

--- Returns a range of text.
-- @param start_pos Start position of the range.
-- @param end_pos End position of the range.
-- @function text_range

--- Returns the text on a line, including its end of line characters.
-- @param line Line number to get the text of.
-- @function get_line

--- Returns the current line's text and the caret's position on that line.
-- @function get_cur_line

--- Map of buffer positions to their character bytes. (Read-only)
-- @table char_at

--- Set Text.
-- @section

--- Replaces the buffer's text.
-- @param text String text to set.
-- @function set_text

--- Adds text to the buffer at the caret position, moving the caret without scrolling it into view.
-- @param text String text to add.
-- @function add_text

--- Inserts text into the buffer, removing any existing selections.
-- If the caret is after *pos*, it is moved appropriately, but not scrolled into view.
-- @param pos Position to insert text at, or `-1` for the caret position.
-- @param text String text to insert.
-- @function insert_text

--- Appends text to the end of the buffer without modifying any existing selections or scrolling
-- that text into view.
-- @param text String text to append.
-- @function append_text

--- Duplicates the current line on a new line below.
-- @function line_duplicate

--- Duplicates the selected text to its right.
-- If multiple lines are selected, duplication starts at the end of the selection. If no text
-- is selected, duplicates the current line on a new line below.
-- @function selection_duplicate

--- Types a new line at the caret position according to `buffer.eol_mode`.
-- @function new_line

--- Replace Text.
-- Replacing an arbitrary range of text makes use of a *target range*, a user-defined defined
-- region of text that some buffer functions operate on in order to avoid altering the current
-- selection or scrolling the view.
-- @section

--- Replaces the selected text, scrolling the caret into view.
-- @param text String text to replace the selected text with.
-- @function replace_sel

--- Defines the target range.
-- @param start_pos Start position of the range.
-- @param end_pos End position of the range.
-- @function set_target_range

--- Defines the target range as the main selection.
-- @function target_from_selection

--- Replaces the text in the target range without modifying any selections or scrolling the view.
-- Setting the target and calling this function with an empty string is another way to delete text.
-- @param text String text to replace the target range with.
-- @return length of replacement text
-- @function replace_target

--- Replaces the text in the target range without modifying any selections or scrolling the view,
-- and tries to minimize change history if `io.track_changes` is `true`.
-- @param text String text to replace the target range with.
-- @return length of replacement text
-- @function replace_target_minimal

--- Delete Text.
-- @section

--- Deletes the character at the caret if no text is selected, or deletes the selected text.
-- @function clear

--- Deletes a range of text.
-- @param pos Start position of the range to delete.
-- @param length Number of characters in the range to delete.
-- @function delete_range

--- Deletes the character behind the caret if no text is selected, or deletes the selected text.
-- @function delete_back

--- Deletes the character behind the caret if no text is selected and the caret is not at the
-- beginning of a line.
-- If text is selected, it is deleted.
-- @function delete_back_not_line

--- Deletes the word to the left of the caret, including any leading non-word characters.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function del_word_left

--- Deletes the word to the right of the caret, including any trailing non-word characters.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function del_word_right

--- Deletes the word to the right of the caret, excluding any trailing non-word characters.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function del_word_right_end

--- Deletes the range of text from the caret to the beginning of the current line.
-- @function del_line_left

--- Deletes the range of text from the caret to the end of the current line.
-- @function del_line_right

--- Deletes the current line.
-- @function line_delete

--- Deletes the buffer's text.
-- @function clear_all

--- Transform Text.
-- @section

--- Indents the text on the selected lines, or types a Tab character ('\t') at the caret position
-- if no text is selected.
-- @function tab

--- Indents the text on the current or selected lines.
-- @function line_indent

--- Un-indents the text on the selected lines.
-- @function back_tab

--- Un-indents the text on the current or selected lines.
-- @function line_dedent

--- Swaps the current line with the one above it.
-- @function line_transpose

--- Reverses the order of the selected lines.
-- @function line_reverse

--- Converts the selected text to upper case letters.
-- @function upper_case

--- Converts the selected text to lower case letters.
-- @function lower_case

--- Shifts the selected lines up one line.
-- @function move_selected_lines_up

--- Shifts the selected lines down one line.
-- @function move_selected_lines_down

--- Split and Join Lines.
-- Splitting and joining lines uses a target range (a user-defined defined region of text that
-- some buffer functions operate on).
-- @section

--- Splits up lines in the target range that exceed a certain width.
-- @param width Pixel width to split lines at. If `0`, the width of the view is used.
-- @see set_target_range
-- @see target_from_selection
-- @see view.text_width
-- @function lines_split

--- Joins the lines in the target range, inserting spaces between any words joined at line
-- boundaries.
-- @see set_target_range
-- @see target_from_selection
-- @see textadept.editing.join_lines
-- @function lines_join

--- Undo and Redo.
-- @section

--- Returns whether or not there is an action that can be undone.
-- @function can_undo

--- Returns whether or not there is an action that can be redone.
-- @function can_redo

--- Undoes the most recent action.
-- @function undo

--- Redoes the next undone action.
-- @function redo

--- Starts a sequence of actions that can be undone or redone as a single action.
-- Calls to this function may be nested.
-- @function begin_undo_action

--- Ends a sequence of actions that can be undone or redone as a single action.
-- @function end_undo_action

--- Deletes the buffer's undo and redo history.
-- @function empty_undo_buffer

--- Save and restore the main selection during undo and redo, respectively.
-- - `buffer.UNDO_SELECTION_HISTORY_DISABLED`: Disable selection undo/redo.
-- - `buffer.UNDO_SELECTION_HISTORY_ENABLED`: Enable selection undo/redo.
--
-- The default value is `buffer.UNDO_SELECTION_HISTORY_ENABLED`.
-- @field undo_selection_history

--- Disable selection undo/redo.
-- @field UNDO_SELECTION_HISTORY_DISABLED

--- Enable selection undo/redo.
-- @field UNDO_SELECTION_HISTORY_ENABLED

--- Whether or not to record undo history.
-- The default value is `true`.
-- @field undo_collection

--- Employ the Clipboard.
-- The terminal version relies on the commands defined in `textadept.clipboard` in order to
-- interact with the system clipboard, or else it uses its own internal clipboard.
-- @section

--- Cuts the selected text to the clipboard.
-- Multiple selections are copied in order, separated by `buffer.copy_separator`. Rectangular
-- selections are copied from top to bottom with end of line characters. Virtual space is
-- not copied.
-- @function cut

--- Cuts the selected text to the clipboard or, if no text is selected, cuts the current line.
-- Multiple selections are copied in order, separated by `buffer.copy_separator`. Rectangular
-- selections are copied from top to bottom with end of line characters. Virtual space is
-- not copied.
-- @function cut_allow_line

--- Copies the selected text to the clipboard.
-- Multiple selections are copied in order, separated by `buffer.copy_separator`. Rectangular
-- selections are copied from top to bottom with end of line characters. Virtual space is
-- not copied.
-- @function copy

--- Copies the selected text to the clipboard or, if no text is selected, copies the entire line.
-- Multiple selections are copied in order, separated by `buffer.copy_separator`. Rectangular
-- selections are copied from top to bottom with end of line characters. Virtual space is
-- not copied.
-- @function copy_allow_line

--- Cuts the current line to the clipboard.
-- @function line_cut

--- Copies the current line to the clipboard.
-- @function line_copy

--- Copies a range of text to the clipboard.
-- @param start_pos Start position of the range to copy.
-- @param end_pos End position of the range to copy.
-- @function copy_range

--- Copies text to the clipboard.
-- @param text String text to copy.
-- @function copy_text

--- Pastes the clipboard's contents into the buffer, replacing any selected text according to
-- `buffer.multi_paste`.
-- @see textadept.editing.paste_reindent
-- @see ui.get_clipboard_text
-- @function paste

--- Paste into multiple selections.
-- - `buffer.MULTIPASTE_ONCE`: Paste into only the main selection.
-- - `buffer.MULTIPASTE_EACH`: Paste into all selections.
--
-- The default value is `buffer.MULTIPASTE_EACH`.
-- @field multi_paste

--- Paste into only the main selection.
-- @field MULTIPASTE_ONCE

--- Paste into all selections.
-- @field MULTIPASTE_EACH

--- Make Simple Selections.
-- @section

--- Selects a range of text, scrolling it into view.
-- @param start_pos Start position of the range to select, with a negative position being the
--	end of the buffer.
-- @param end_pos End position of the range to select, with a negative value being *start_pos*
--	(i.e. no selection).
-- @function set_sel

--- The selected text's start position.
-- When set, it becomes the anchor, but is not scrolled into view.
-- @field selection_start

--- The selected text's end position.
-- When set, it becomes the current position, but is not scrolled into view.
-- @field selection_end

--- Swaps the main selection's beginning and end positions.
-- @function swap_main_anchor_caret

--- Selects all of the buffer's text without scrolling the view.
-- @function select_all

--- Moves the caret to a position without scrolling the view, and removes any selections.
-- @param pos Position to move to.
-- @function set_empty_selection

--- Whether or not there is no text selected. (Read-only)
-- @field selection_empty

--- Whether or not the selection is a rectangular selection. (Read-only)
-- @field selection_is_rectangle

--- Returns whether or not a range's bounds are at word boundaries.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @param start_pos Start position of the range to check.
-- @param end_pos End position of the range to check.
-- @function is_range_word

--- Make Movement Selections.
-- @section

--- Moves the caret left one character, extending the selected text to the new position.
-- @function char_left_extend

--- Moves the caret right one character, extending the selected text to the new position.
-- @function char_right_extend

--- Moves the caret to the previous part of the current word, extending the selected text to
-- the new position.
-- Word parts are delimited by underscore characters or changes in capitalization.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_part_left_extend

--- Moves the caret to the next part of the current word, extending the selected text to the
-- new position.
-- Word parts are delimited by underscore characters or changes in capitalization.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_part_right_extend

--- Moves the caret left one word, extending the selected text to the new position.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_left_extend

--- Moves the caret right one word, extending the selected text to the new position.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @function word_right_extend

--- Like `buffer:word_left_end()`, but extends the selected text to the new position.
-- @function word_left_end_extend

--- Like `buffer:word_right_end()`, but extends the selected text to the new position.
-- @function word_right_end_extend

--- Moves the caret to the beginning of the current line, extending the selected text to the
-- new position.
-- @function home_extend

--- Moves the caret to the end of the current line, extending the selected text to the new
-- position.
-- @function line_end_extend

--- Moves the caret to the beginning of the current wrapped line, extending the selected text
-- to the new position.
-- @function home_display_extend

--- Moves the caret to the end of the current wrapped line, extending the selected text to the
-- new position.
-- @function line_end_display_extend

--- Like `buffer:home_wrap()`, but extends the selected text to the new position.
-- @function home_wrap_extend

--- Like `buffer:line_end_wrap()`, but extends the selected text to the new position.
-- @function line_end_wrap_extend

--- Like `buffer:vc_home()`, but extends the selected text to the new position.
-- @function vc_home_extend

--- Like `buffer:vc_home_display()`, but extends the selected text to the new position.
-- @function vc_home_display_extend

--- Like `buffer:vc_home_wrap()`, but extends the selected text to the new position.
-- @function vc_home_wrap_extend

--- Moves the caret up one line, extending the selected text to the new position.
-- @function line_up_extend

--- Moves the caret down one line, extending the selected text to the new position.
-- @function line_down_extend

--- Moves the caret up one paragraph, extending the selected text to the new position.
-- Paragraphs are surrounded by one or more blank lines.
-- @function para_up_extend

--- Moves the caret down one paragraph, extending the selected text to the new position.
-- Paragraphs are surrounded by one or more blank lines.
-- @function para_down_extend

--- Like `buffer:stuttered_page_up()`, but extends the selected text to the new position.
-- @function stuttered_page_up_extend

--- Like `buffer:stuttered_page_down()`, but extends the selected text to the new position.
-- @function stuttered_page_down_extend

--- Moves the caret up one page, extending the selected text to the new position.
-- @function page_up_extend

--- Moves the caret down one page, extending the selected text to the new position.
-- @function page_down_extend

--- Moves the caret to the beginning of the buffer, extending the selected text to the new
-- position.
-- @function document_start_extend

--- Moves the caret to the end of the buffer, extending the selected text to the new position.
-- @function document_end_extend

--- Allow caret movement to alter the selected text.
-- Setting `buffer.selection_mode` also updates this property.
-- The default value is `false`.
-- @field move_extends_selection

--- Modal Selection.
-- @section

--- The selection mode.
-- - `buffer.SEL_STREAM`: Character selection.
-- - `buffer.SEL_RECTANGLE`: Rectangular selection.
-- - `buffer.SEL_LINES`: Line selection.
-- - `buffer.SEL_THIN`: Thin rectangular selection. This is the mode after a rectangular
--	selection has been typed into and ensures that no characters are selected.
--
-- When set, caret movement alters the selected text until either this field is set again to
-- the same value, or until `buffer:cancel()` is called.
-- @field selection_mode

--- Line selection.
-- @field SEL_LINES

--- Rectangular selection.
-- @field SEL_RECTANGLE

--- Character selection.
-- @field SEL_STREAM

--- Thin rectangular selection. This is the mode after a rectangular selection has been typed
-- into and ensures that no characters are selected.
-- @field SEL_THIN

--- Changes the selection mode without allowing subsequent caret movement to alter selected text.
-- @param mode Selection mode to change to. Valid values are:
--	- `buffer.SEL_STREAM`: Character selection.
--	- `buffer.SEL_RECTANGLE`: Rectangular selection.
--	- `buffer.SEL_LINES`: Line selection.
--	- `buffer.SEL_THIN`: Thin rectangular selection. This is the mode after a rectangular
--	selection has been typed into and ensures that no characters are selected.
-- @function change_selection_mode

--- Make and Modify Multiple Selections.
-- **Note:** the `buffer.selection_n_`\* fields cannot be used to create selections.
-- @section

--- Selects a range of text, removing all other selections.
-- @param end_pos Caret position of the range to select.
-- @param start_pos Anchor position of the range to select.
-- @function set_selection

--- Selects a range of text as the main selection, retaining all other selections as additional
-- selections.
-- Since an empty selection (i.e. the current position) still counts as a selection, use
-- `buffer:set_selection()` first when setting a list of selections.
-- @param end_pos Caret position of the range to select.
-- @param start_pos Anchor position of the range to select.
-- @function add_selection

--- Adds to the set of selections the next occurrence of the main selection within the target
-- range, makes that occurrence the new main selection, and scrolls it into view.
-- If there is no selected text, the current word is used.
-- @see textadept.editing.select_word
-- @see buffer.set_target_range
-- @see buffer.target_whole_document
-- @function multiple_select_add_next

--- Adds to the set of selections each occurrence of the main selection within the target range.
-- If there is no selected text, the current word is used.
-- @see textadept.editing.select_word
-- @see buffer.set_target_range
-- @see buffer.target_whole_document
-- @function multiple_select_add_each

--- The number of active selections. (Read-only) There is always at least one selection, which
-- may be empty.
-- @field selections

--- The number of the main selection, which is often the most recent selection.
-- Only an existing selection can be made main.
-- @field main_selection

--- Makes the next additional selection the main selection.
-- @function rotate_selection

--- Drops an existing selection.
-- @param n Number of the existing selection to drop.
-- @function drop_selection_n

--- Map of existing selection numbers to their start positions.
-- @table selection_n_anchor

--- Map of existing selection numbers to their end positions.
-- @table selection_n_caret

--- Map of existing selection numbers to their start positions.
-- @table selection_n_start

--- Map of existing selection numbers to their end positions.
-- @table selection_n_end

--- Map of existing selection numbers to their virtual space start positions.
-- @table selection_n_anchor_virtual_space

--- Map of existing selection numbers to their virtual space end positions.
-- @table selection_n_caret_virtual_space

--- Map of existing selection numbers to their virtual space start positions. (Read-only)
-- @table selection_n_start_virtual_space

--- Map of existing selection numbers to their virtual space end positions. (Read-only)
-- @table selection_n_end_virtual_space

--- Serialized string selection state.
-- The serialization format may change between releases, so it should not be used in session
-- saving and loading.
-- @field selection_serialized

--- Enable multiple selection.
-- The default value is `true`.
-- @field multiple_selection

--- Type into multiple selections.
-- The default value is `true`.
-- @field additional_selection_typing

--- Make Rectangular Selections.
-- @section

--- The rectangular selection's anchor position.
-- @field rectangular_selection_anchor

--- The rectangular selection's caret position.
-- @field rectangular_selection_caret

--- The amount of virtual space for the rectangular selection's anchor.
-- @field rectangular_selection_anchor_virtual_space

--- The amount of virtual space for the rectangular selection's caret.
-- @field rectangular_selection_caret_virtual_space

--- Moves the caret left one character, extending the rectangular selection to the new position.
-- @function char_left_rect_extend

--- Moves the caret right one character, extending the rectangular selection to the new position.
-- @function char_right_rect_extend

--- Moves the caret to the beginning of the current line, extending the rectangular selection
-- to the new position.
-- @function home_rect_extend

--- Moves the caret to the end of the current line, extending the rectangular selection to the
-- new position.
-- @function line_end_rect_extend

--- Like `buffer:vc_home()`, but extends the rectangular selection to the new position.
-- @function vc_home_rect_extend

--- Moves the caret up one line, extending the rectangular selection to the new position.
-- @function line_up_rect_extend

--- Moves the caret down one line, extending the rectangular selection to the new position.
-- @function line_down_rect_extend

--- Moves the caret up one page, extending the rectangular selection to the new position.
-- @function page_up_rect_extend

--- Moves the caret down one page, extending the rectangular selection to the new position.
-- @function page_down_rect_extend

--- The modifier key used in combination with a mouse drag in order to create a rectangular
-- selection.
-- - `view.MOD_CTRL`: The "Control" modifier key.
-- - `view.MOD_ALT`: The "Alt" modifier key.
-- - `view.MOD_SUPER`: The "Super" modifier key, usually defined as the left "Windows" or
--	"Command" key.
--
-- The default value is `view.MOD_ALT`.
-- @field view.rectangular_selection_modifier

--- The "Alt" modifier key.
-- @field view.MOD_ALT

--- The "Control" modifier key on Windows and Linux, and the "Command" modifier key on macOS.
-- @field view.MOD_CTRL

--- The "Control" modifier key on macOS.
-- @field view.MOD_META

--- The "Shift" modifier key.
-- @field view.MOD_SHIFT

--- The "Super" modifier key, usually defined as the left "Windows" key.
-- @field view.MOD_SUPER

--- Turn on rectangular selection when pressing `view.rectangular_selection_modifier` while
-- selecting text normally with the mouse.
-- This works around the Linux/BSD window managers that consume Alt+Mouse Drag.
--
-- The default value is `true`.
-- @field view.mouse_selection_rectangular_switch

--- Replaces the rectangular selection's text.
-- @param text String text to replace the rectangular selection with.
-- @function replace_rectangular

--- Simple Search.
-- @section

--- Marks the caret position as the position `buffer:search_next()` and `buffer:search_prev()`
-- start from.
-- If text is selected, the selected text's start position is used instead.
-- @function search_anchor

--- Searches for text and selects its first occurrence without scrolling the view.
-- Searches start where `buffer:search_anchor()` was called.
-- @param flags A bit-mask of search flags to use:
--	- `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
--	- `buffer.FIND_MATCHCASE`: Match search text case sensitively.
--	- `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
--		character.
--	- `buffer.FIND_REGEXP`: Interpret search text as a regular expression.
-- @param text String text to search for.
-- @return found text's position, or `-1` if no text was found
-- @function search_next

--- Searches for text and selects its previous occurrence without scrolling the view.
-- Searches start where `buffer:search_anchor()` was called.
-- @param flags A bit-mask of search flags to use:
--	- `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
--	- `buffer.FIND_MATCHCASE`: Match search text case sensitively.
--	- `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
--		character.
--	- `buffer.FIND_REGEXP`: Interpret search text as a regular expression.
-- @param text String text to search for.
-- @return found text's position, or `-1` if no text was found
-- @function search_prev

--- Search and Replace.
-- The more complex search and replace API uses a target range (a user-defined region of text
-- that some buffer functions operate on, or a region of text that some buffer functions define
-- as output).
-- @section

--- The bit-mask of search flags used by `buffer:search_in_target()`.
-- - `buffer.FIND_WHOLEWORD`: Match search text only when it is surrounded by non-word characters.
-- - `buffer.FIND_MATCHCASE`: Match search text case sensitively.
-- - `buffer.FIND_WORDSTART`: Match search text only when the previous character is a non-word
--	character.
-- - `buffer.FIND_REGEXP`: Interpret search text as a regular expression.
--
-- The default value is `0`.
-- @field search_flags

--- Match search text only when it is surrounded by non-word characters.
-- @field FIND_WHOLEWORD

--- Match search text case sensitively.
-- @field FIND_MATCHCASE

--- Match search text only when the previous character is a non-word character.
-- @field FIND_WORDSTART

--- Interpret search text as a regular expression.
-- @field FIND_REGEXP

--- Defines the target range as the entire buffer's contents.
-- @see set_target_range
-- @see target_from_selection
-- @function target_whole_document

--- Searches the target range for text and updates the target range to the first occurrence found.
-- `buffer.search_flags` are the flags used in the search.
-- @param text String text to search the target range for.
-- @return found text's position, or `-1` if no text was found
-- @function search_in_target

--- Replaces the text in the target range with a regular expression replacement.
-- @param text String text to replace the target range with. Any "\d" sequences will expand to
--	the text of capture number *d* from the regular expression search (or the entire match
--	for *d* = 0)
-- @see replace_target
-- @return length of replacement text
-- @function replace_target_re

--- The text in the target range. (Read-only)
-- @field target_text

--- The target range's start position.
-- This is also set by a successful `buffer:search_in_target()`.
-- @field target_start

--- The target range's end position.
-- This is also set by a successful `buffer:search_in_target()`.
-- @field target_end

--- The start position of the target range's virtual space.
-- This is reset to `1` when `buffer.target_start` or `buffer.target_end` is set, or when
-- `buffer:set_target_range()` is called.
-- @field target_start_virtual_space

--- The end position of the target range's virtual space.
-- This is reset to `1` when `buffer.target_start` or `buffer.target_end` is set, or when
-- `buffer:set_target_range()` is called.
-- @field target_end_virtual_space

--- Map of a regular expression search's capture numbers to captured text. (Read-only)
-- @field tag

--- Query Position Information.
-- @section

--- The anchor's position.
-- @field anchor

--- The caret's position.
--  Setting this does not scroll the caret into view.
-- @field current_pos

--- Returns the position before a given position, taking multi-byte characters into account, or
-- `-1` if there is no such position.
-- @param pos Position to get the previous position from.
-- @function position_before

--- Returns the position after a given position, taking multi-byte characters into account, or
-- `buffer.length + 1` if there is no such position.
-- @param pos Position to get the next position from.
-- @function position_after

--- Returns the position a relative number of characters away from a given position, taking
-- multi-byte characters into account, or `1` if there is no such position.
-- @param pos Position to get the relative position from.
-- @param n Relative number of characters to get the position for. A negative number
--	indicates a position before while a positive number indicates a position after.
-- @function position_relative

--- Returns a word's start position.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @param pos Position of the word.
-- @param only_word_chars If `true`, stops searching at the first non-word character to the
--	left of *pos*. Otherwise, the first character to the left of *pos* sets the type of
--	the search as word or non-word and the search stops at the first non-matching character.
-- @usage -- Consider the buffer text "word....word"
--	buffer:word_start_position(3, true) --> 1
--	buffer:word_start_position(7, true) --> 7
--	buffer:word_start_position(7, false) --> 5
--	buffer:word_start_position(9, false) --> 5
--	buffer:word_start_position(9, true) --> 9
-- @function word_start_position

--- Returns a word's end position.
-- `buffer.word_chars` contains the set of characters that constitute words.
-- @param pos Position of the word.
-- @param only_word_chars If `true`, stops searching at the first non-word character to the
--	right of *pos*. Otherwise, the first character to the right of *pos* sets the type of
--	the search as word or non-word and the search stops at the first non-matching character.
-- @usage -- Consider the buffer text "word....word"
--	buffer:word_end_position(3, true) --> 5
--	buffer:word_end_position(5, true) --> 5
--	buffer:word_end_position(5, false) --> 9
--	buffer:word_end_position(7, true) --> 7
--	buffer:word_end_position(7, false) --> 9
-- @function word_end_position

--- Returns a line's start position.
-- @param line Line number to get the start position for. If *line* exceeds `buffer.line_count +
--	1`, `-1` will be returned.
-- @function position_from_line

--- Map of line numbers to their end-of-line-indentation positions. (Read-only)
-- @table line_indent_position

--- Map of line numbers to their end-of-line positions before any end-of-line
-- characters. (Read-only)
-- @table line_end_position

--- Returns the position at a particular line and column, taking tab and multi-byte characters
-- into account.
-- @param line Line number to use.
-- @param column Column number to use. If it exceeds the length of *line*, the position at the
--	end of *line* will be returned.
-- @function find_column

--- Returns the position of a matching brace character, taking nested braces into account, or
-- `-1` if no match was found.
-- Matching braces must have the same style.
-- @param pos Position of the brace to match. Brace characters recognized are '(', ')', '[',
--	']', '{', '}', '<', and '>'.
-- @param max_re_style Must be `0`. Reserved for expansion.
-- @function brace_match

--- Query Line and Line Number Information.
-- @section

--- The number of lines in the buffer. (Read-only)
-- There is always at least one.
-- @field line_count

--- The number of completely visible lines in the view. (Read-only)
-- It is possible to have a partial line visible at the bottom of the view.
-- @field view.lines_on_screen

--- The line number of the line at the top of the view.
-- @field view.first_visible_line

--- Returns the line number that contains a position.
-- @param pos Position to get the line number of. If it is less than `1`, `1` is returned. If
--	*pos* is greater than `buffer.length + 1`, `buffer.line_count` is returned.
-- @function line_from_position

--- Map of line numbers to their column indentation amounts.
-- @table line_indentation

--- Returns the number of bytes on a line, including end of line characters.
-- To get line length excluding end of line characters, use
-- `buffer.line_end_position[line] - buffer.position_from_line(line)`.
-- @param line Line number to get the length of.
-- @function line_length

--- Returns the number of wrapped lines needed to fully display a line.
-- @param line Line number to use.
-- @function view:wrap_count

--- Returns the displayed line number of an actual line number, taking wrapped, annotated,
-- and hidden lines into account.
-- Lines can occupy more than one display line if they wrap.
-- @param line Line number to use. If it is outside the range of lines in the buffer, `-1`
--	is returned.
-- @function view:visible_from_doc_line

--- Returns the actual line number of a displayed line number, taking wrapped, annotated, and
-- hidden lines into account.
-- @param display_line Display line number to use. If it is less than `1`, `1` is returned. If
--	*display_line* is greater than the number of displayed lines, `buffer.line_count`
--	is returned.
-- @function view:doc_line_from_visible

--- Query Measurement Information.
-- @section

--- The number of bytes in the buffer. (Read-only)
-- @field length

--- The number of bytes in the buffer. (Read-only)
-- @field text_length

--- Map of buffer positions to their column numbers, taking tab and multi-byte characters into
-- account. (Read-only)
-- @table column

--- Returns the number of whole characters, taking multi-byte characters into account, between
-- two positions.
-- @param start_pos Start position of the range to start counting at.
-- @param end_pos End position of the range to stop counting at.
-- @function count_characters

--- Returns the pixel width text would have when styled in a particular style.
-- @param style_num Style number between `1` and `256` to use.
-- @param text String text to measure the width of.
-- @function view:text_width

--- Returns the pixel height of a line.
-- @param line Line number to get the pixel height of.
-- @function view:text_height

--- Configure Line Margins.
-- The number of line margins is configurable, with each one displaying either line numbers,
-- [marker symbols](#mark-lines-with-markers), or text.
-- @section

--- The number of margins.
-- The default value is `5`.
-- @field view.margins

--- Map of margin numbers to their types.
-- Valid margin types are:
-- - `view.MARGIN_SYMBOL`: A marker symbol margin.
-- - `view.MARGIN_NUMBER`: A line number margin.
-- - `view.MARGIN_BACK`: A marker symbol margin whose background color matches the default text
--	background color.
-- - `view.MARGIN_FORE`: A marker symbol margin whose background color matches the default text
--	foreground color.
-- - `view.MARGIN_TEXT`: A text margin.
-- - `view.MARGIN_RTEXT`: A right-justified text margin.
-- - `view.MARGIN_COLOR`: A marker symbol margin whose background color is configurable.
--
-- The default value for the first margin is `view.MARGIN_NUMBER`, followed by `view.MARGIN_SYMBOL`
-- for the rest.
-- @table view.margin_type_n

--- A marker symbol margin whose background color matches the default text background color.
-- @field view.MARGIN_BACK

--- A marker symbol margin whose background color is configurable.
-- @field view.MARGIN_COLOR

--- A marker symbol margin whose background color matches the default text foreground color.
-- @field view.MARGIN_FORE

--- A line number margin.
-- @field view.MARGIN_NUMBER

--- A right-justified text margin.
-- @field view.MARGIN_RTEXT

--- A marker symbol margin.
-- @field view.MARGIN_SYMBOL

--- A text margin.
-- @field view.MARGIN_TEXT

--- Map of margin numbers to their pixel margin widths.
-- @table view.margin_width_n

--- Map of margin numbers to their marker symbol bit-masks.
-- Bit-masks are 32-bit values whose bits correspond to the 32 available markers. A margin
-- whose type is either `view.MARGIN_SYMBOL`, `view.MARGIN_BACK`, `view.MARGIN_FORE`, or
-- `view.MARGIN_COLOR` can show any marker whose bit is set in the mask.
--
-- The default values are `0`, `~view.MASK_FOLDERS`, `view.MASK_FOLDERS`, and `0` for the rest.
-- @usage view.margin_mask_n[2] = ~view.MASK_FOLDERS -- display non-folding markers
-- @usage view.margin_mask_n[3] = view.MASK_FOLDERS -- only display folding markers
-- @table view.margin_mask_n

--- @field view.MASK_FOLDERS

--- Map of margin numbers to whether or not mouse clicks in them emit `events.MARGIN_CLICK`.
-- The default values are `false` for the first margin and `true` for the others.
-- @table view.margin_sensitive_n

--- Map of margin numbers to their displayed mouse cursors.
-- - `view.CURSORARROW`: Normal arrow cursor.
-- - `view.CURSORREVERSEARROW`: Reversed arrow cursor.
--
-- The default values are `view.CURSORARROW`.
-- @table view.margin_cursor_n

--- Map of line numbers to their text margin text.
-- A margin whose type is either `view.MARGIN_TEXT` or `view.MARGIN_RTEXT` can show text in
-- this map.
-- @usage buffer.margin_text[1] = 'Title:'
-- @table margin_text

--- Map of line numbers to their text margin style numbers.
-- A margin whose type is either `view.MARGIN_TEXT` or `view.MARGIN_RTEXT` will show text in
-- `buffer.margin_text` in the styles specified here.
--
-- Note: text margins can only draw some style attributes: font, size, bold, italics, fore,
-- and back.
-- @see view.styles
-- @see buffer.style_of_name
-- @usage buffer.margin_style[1] = buffer:style_of_name(lexer.BOLD)
-- @table margin_style

--- Clears all text margin text.
-- @function margin_text_clear_all

--- A bit-mask of margin option settings.
-- - `view.MARGINOPTION_NONE`: None.
-- - `view.MARGINOPTION_SUBLINESELECT`: Select only a wrapped line's sub-line (rather than the
--	entire line) when clicking on the line number margin.
--
-- The default value is `view.MARGINOPTION_NONE`.
-- @field view.margin_options

--- @field view.MARGINOPTION_NONE

--- Select only a wrapped line's sub-line (rather than the entire line) when the line number
-- margin is clicked.
-- @field view.MARGINOPTION_SUBLINESELECT

--- Map of margin numbers to marker symbol margin background colors in "0xBBGGRR" format.
-- A margin whose type is `view.MARGIN_COLOR` will use the color specified here.
-- @usage view.margin_back_n[4] = view.colors.light_grey
-- @table view.margin_back_n

--- Overrides the fold margin's default color.
-- @param use_setting Whether or not to use *color*.
-- @param color Color in "0xBBGGRR" format.
-- @function view:set_fold_margin_color

--- Overrides the fold margin's default highlight color.
-- @param use_setting Whether or not to use *color*.
-- @param color Color in "0xBBGGRR" format.
-- @function view:set_fold_margin_hi_color

--- The pixel size of buffer text's left margin.
-- The default value is `1` in the GUI version and `0` in the terminal version.
-- @field view.margin_left

--- The pixel size of buffer text's right margin.
-- The default value is `1` in the GUI version and `0` in the terminal version.
-- @field view.margin_right

--- Mark Lines with Markers.
-- There are 32 markers to mark lines with. Each marker has an assigned symbol that properly
-- configured [margins](#configure-line-margins) will display. For lines with multiple markers,
-- markers are drawn over one another in ascending order. Markers move in sync with the lines
-- they were added to as text is inserted and deleted. When a line that has a marker on it is
-- deleted, that marker moves to the previous line.
--
-- Marker symbol | Visual or description
-- -|-
-- `view.MARK_CIRCLE` | ●
-- `view.MARK_SMALLRECT` | ■
-- `view.MARK_ROUNDRECT` | A rounded rectangle
-- `view.MARK_LEFTRECT` | ▌
-- `view.MARK_FULLRECT` | █
-- `view.MARK_SHORTARROW` | A small, right-facing arrow
-- `view.MARK_ARROW` | ►
-- `view.MARK_ARROWS` | ›››
-- `view.MARK_DOTDOTDOT` | …
-- `view.MARK_BOOKMARK` | A horizontal bookmark flag
-- `view.MARK_VERTICALBOOKMARK` | A vertical bookmark flag
-- `view.MARK_PIXMAP` | An [XPM image][]
-- `view.MARK_RGBAIMAGE` | An [RGBA image][]
-- `view.MARK_CHARACTER` + *i* | The character whose ASCII value is *i*
-- `view.MARK_EMPTY` | An empty marker
-- `view.MARK_BACKGROUND` | Changes a line's background color
-- `view.MARK_UNDERLINE` | Underlines an entire line
-- **Fold symbols** |
-- `view.MARK_ARROW` | ►
-- `view.MARK_ARROWDOWN` | ▼
-- `view.MARK_MINUS` | −
-- `view.MARK_BOXMINUS` | ⊟
-- `view.MARK_BOXMINUSCONNECTED` | A boxed minus sign connected to a vertical line
-- `view.MARK_CIRCLEMINUS` | ⊖
-- `view.MARK_CIRCLEMINUSCONNECTED` | A circled minus sign connected to a vertical line
-- `view.MARK_PLUS` | +
-- `view.MARK_BOXPLUS` | ⊞
-- `view.MARK_BOXPLUSCONNECTED` | A boxed plus sign connected to a vertical line
-- `view.MARK_CIRCLEPLUS` | ⊕
-- `view.MARK_CIRCLEMINUSCONNECTED` | A circled plus sign connected to a vertical line
-- `view.MARK_VLINE` | │
-- `view.MARK_TCORNER` | ├
-- `view.MARK_LCORNER` | └
-- `view.MARK_TCORNERCURVE` | A curved, T-shaped corner
-- `view.MARK_LCORNERCURVE` | A curved, L-shaped corner
--
-- There are 7 pre-defined marker numbers used for code folding marker symbols.
--
-- Marker Number | Description
-- -|-
-- `view.MARKNUM_FOLDEROPEN` | The first line of an expanded fold
-- `view.MARKNUM_FOLDERSUB` | A line within an expanded fold
-- `view.MARKNUM_FOLDERTAIL` | The last line of an expanded fold
-- `view.MARKNUM_FOLDER` | The first line of a collapsed fold
-- `view.MARKNUM_FOLDEROPENMID` | The first line of an expanded fold within an expanded fold
-- `view.MARKNUM_FOLDERMIDTAIL` | The last line of an expanded fold within an expanded fold
-- `view.MARKNUM_FOLDEREND` | The first line of a collapsed fold within an expanded fold
--
-- There are 4 pre-defined marker numbers used for showing how a buffer line differs from its
-- file's saved state if `io.track_changes` is `true`.
--
-- Marker Number | Description
-- -|-
-- `view.MARKNUM_HISTORY_MODIFIED` | Line was changed and has not yet been saved
-- `view.MARKNUM_HISTORY_SAVED` | Line was changed and saved
-- `view.MARKNUM_HISTORY_REVERTED_TO_MODIFIED` | Line was changed, saved, then partially reverted
-- `view.MARKNUM_HISTORY_REVERTED_TO_ORIGIN` | Line was changed, saved, then fully reverted
--
-- [XPM image]: https://scintilla.org/ScintillaDoc.html#XPM
-- [RGBA image]: https://scintilla.org/ScintillaDoc.html#RGBA
-- @section

--- Returns a unique marker number for use with `view:marker_define()`.
-- Use this function for custom markers in order to prevent clashes with the numbers of other
-- custom markers.
-- @function view.new_marker_number

--- Assigns a marker symbol to a marker.
-- Properly configured marker symbol margins will show the symbol next to lines marked with
-- that marker.
-- @param marker Marker number in the range of `1` to `32` to set *symbol* for.
-- @param symbol Marker symbol to assign: `view.MARK_*`.
-- @function view:marker_define

--- @field view.MARK_ARROW

--- @field view.MARK_ARROWDOWN

--- @field view.MARK_ARROWS

--- @field view.MARK_BACKGROUND

--- @field view.MARK_BAR

--- @field view.MARK_BOOKMARK

--- @field view.MARK_BOXMINUS

--- @field view.MARK_BOXMINUSCONNECTED

--- @field view.MARK_BOXPLUS

--- @field view.MARK_BOXPLUSCONNECTED

--- @field view.MARK_CHARACTER

--- @field view.MARK_CIRCLE

--- @field view.MARK_CIRCLEMINUS

--- @field view.MARK_CIRCLEMINUSCONNECTED

--- @field view.MARK_CIRCLEPLUS

--- @field view.MARK_CIRCLEPLUSCONNECTED

--- @field view.MARK_DOTDOTDOT

--- @field view.MARK_EMPTY

--- @field view.MARK_FULLRECT

--- @field view.MARK_LCORNER

--- @field view.MARK_LCORNERCURVE

--- @field view.MARK_LEFTRECT

--- @field view.MARK_MINUS

--- @field view.MARK_PIXMAP

--- @field view.MARK_PLUS

--- @field view.MARK_RGBAIMAGE

--- @field view.MARK_ROUNDRECT

--- @field view.MARK_SHORTARROW

--- @field view.MARK_SMALLRECT

--- @field view.MARK_TCORNER

--- @field view.MARK_TCORNERCURVE

--- @field view.MARK_UNDERLINE

--- @field view.MARK_VERTICALBOOKMARK

--- @field view.MARK_VLINE

--- @field view.MARK_AVAILABLE

--- @field view.MARKNUM_FOLDER

--- @field view.MARKNUM_FOLDEREND

--- @field view.MARKNUM_FOLDERMIDTAIL

--- @field view.MARKNUM_FOLDEROPEN

--- @field view.MARKNUM_FOLDEROPENMID

--- @field view.MARKNUM_FOLDERSUB

--- @field view.MARKNUM_FOLDERTAIL

--- @field view.MARKNUM_HISTORY_REVERTED_TO_ORIGIN

--- @field view.MARKNUM_HISTORY_SAVED

--- @field view.MARKNUM_HISTORY_MODIFIED

--- @field view.MARKNUM_HISTORY_REVERTED_TO_MODIFIED

--- @field view.MARKER_MAX

--- Assigns an XPM image to a pixmap marker.
-- @param marker Marker number previously defined with a `view.MARK_PIXMAP` symbol.
-- @param pixmap String [pixmap data](https://scintilla.org/ScintillaDoc.html#XPM).
-- @function view:marker_define_pixmap

--- Assigns an RGBA image to an RGBA image marker.
-- @param marker Marker number previously defined with a `view.MARK_RGBAIMAGE` symbol.
-- @param pixels String sequence of 4 byte pixel values (red, green, blue, and alpha) starting
--	with the pixels for the top line, with the leftmost pixel first, then continuing with
--	the pixels for subsequent lines. There is no gap between lines for alignment reasons.
--	The image dimensions, `view.rgba_image_width` and `view.rgba_image_height`, must have
--	already been defined.
-- @see view.rgba_image_scale
-- @function view:marker_define_rgba_image

--- Adds a marker to a line.
-- @param line Line number to add the marker on.
-- @param marker Marker number in the range of `1` to `32` to add.
-- @return handle for use in `buffer:marker_delete_handle()` and
--	`buffer:marker_line_from_handle()`, or `-1` if *line* is invalid
-- @function marker_add

--- Adds a set of markers a line.
-- @param line Line number to add the markers on.
-- @param marker_mask Bit-mask of markers to set. Set the first bit to set marker 1, the second
--	bit for marker 2 and so on up to marker 32.
-- @function marker_add_set

--- Deletes a marker identified by its handle.
-- @param handle Marker handle returned by `buffer:marker_add()` or
--	`buffer:marker_handle_from_line()`.
-- @function marker_delete_handle

--- Deletes a marker from a line.
-- @param line Line number to delete the marker on.
-- @param marker Marker number in the range of `1` to `32` to delete, or `-1` to delete all
--	markers from *line*.
-- @function marker_delete

--- Deletes a marker from any line that has it.
-- @param marker Marker number in the range of `1` to `32` to delete, or `-1` to delete all
--	markers from lines.
-- @function marker_delete_all

--- Returns the line number a particular marker is on, or `-1` if the marker was not found.
-- @param handle Marker handle returned by `buffer:marker_add()` or
--	`buffer:marker_handle_from_line()`.
-- @function marker_line_from_handle

--- Returns the line number of the next line that contains a set of markers, or `-1` if no line
-- was found.
-- @param line Line number to start searching from.
-- @param marker_mask Bit-mask of markers to find. Set the first bit to find marker 1, the
--	second bit for marker 2, and so on up to marker 32.
-- @function marker_next

--- Returns the line number of the previous line that contains a set of markers, or `-1` if no
-- line was found.
-- @param line Line number to start searching from.
-- @param marker_mask Bit-mask of markers to find. Set the first bit to find marker 1, the
--	second bit for marker 2, and so on up to marker 32.
-- @function marker_previous

--- Returns the handle of a marker on a line.
-- @param line Line number to get a marker from.
-- @param n *n*th marker to get the handle of. If no such marker exists, `-1` is returned.
-- @function marker_handle_from_line

--- Returns a bit-mask of all of the markers on a line.
-- The first bit is set if marker number 1 is present, the second bit for marker number 2,
-- and so on.
-- @param line Line number to get markers on.
-- @function marker_get

--- Returns the number of a marker on a line.
-- @param line Line number to get a marker from.
-- @param n *n*th marker to get the number of. If no such marker exists, `-1` is returned.
-- @function marker_number_from_line

--- Returns the marker symbol assigned to a marker.
-- @param marker Marker number in the range of `1` to `32` to get the symbol for.
-- @function view:marker_symbol_defined

--- Map of marker numbers to their foreground colors in "0xBBGGRR" format. (Write-only)
-- @table view.marker_fore

--- Map of marker numbers to their foreground colors in "0xAABBGGRR" format. (Write-only)
-- @table view.marker_fore_translucent

--- Map of marker numbers to their background colors in "0xBBGGRR" format. (Write-only)
-- @table view.marker_back

--- Map of marker numbers to their background colors in "0xAABBGGRR" format. (Write-only)
-- @table view.marker_back_translucent

--- Map of marker numbers to their alpha values. (Write-only)
-- A marker whose marker symbol is either `view.MARK_BACKGROUND` or `view.MARK_UNDERLINE`
-- will use the alpha value specified here.
--
-- The default values are `view.ALPHA_NOALPHA`, for no alpha.
-- @table view.marker_alpha

--- Map of marker numbers to their draw layers.
-- A marker whose marker symbol is either `view.MARK_BACKGROUND` or `view.MARK_UNDERLINE`
-- will use the draw layer specified here.
--
-- - `view.LAYER_BASE`: Draw markers opaquely on the background.
-- - `view.LAYER_UNDER_TEXT`: Draw markers translucently under text.
-- - `view.LAYER_OVER_TEXT`: Draw markers translucently over text.
--
-- The default values are `view.LAYER_BASE`.
-- @table view.marker_layer

--- Map of marker numbers to their draw stroke widths in hundredths of a pixel. (Write-only)
-- The default values are `100`, or 1 pixel.
-- @table view.marker_stroke_width

--- Enables the highlighting of margin fold markers for the current fold block.
-- @param enabled Whether or not to enable highlighting.
-- @function view:marker_enable_highlight

--- Map of marker numbers to their selected folding block background colors in "0xBBGGRR"
-- format. (Write-only)
-- @table view.marker_back_selected

--- Map of marker numbers to their selected folding block background colors in "0xAABBGGRR"
-- format. (Write-only)
-- @table view.marker_back_selected_translucent

--- Annotate Lines.
-- Lines may be annotated with styled, read-only text displayed underneath them or next to them
-- at the ends of lines (EOL). This may be useful for displaying compiler errors, runtime errors,
-- variable values, or other useful information.
-- @section

--- Map of line numbers to their annotation text.
-- @usage buffer.annotation_text[1] = 'error: undefined variable "x"'
-- @table annotation_text

--- Map of line numbers to their EOL annotation text.
-- @usage buffer.eol_annotation_text[1] = 'x = 1'
-- @table eol_annotation_text

--- Map of line numbers to their annotation style numbers.
-- Note: annotations can only draw some style attributes: font, size/size_fractional, bold/weight,
-- italics, fore, back, and character_set.
-- @see view.styles
-- @see buffer.style_of_name
-- @usage buffer.annotation_style[1] = buffer:style_of_name(lexer.ERROR)
-- @table annotation_style

--- Map of line numbers to their EOL annotation style numbers.
-- Note: annotations can only draw style attributes: font, size/size_fractional, bold/weight,
-- italics, fore, back, and character_set.
-- @see view.styles
-- @see buffer.style_of_name
-- @usage buffer.eol_annotation_style[1] = buffer:style_of_name(view.STYLE_FOLDDISPLAYTEXT)
-- @table eol_annotation_style

--- Clears annotations from all lines.
-- @function annotation_clear_all

--- Clears EOL annotations from all lines.
-- @function eol_annotation_clear_all

--- The annotation display style.
-- - `view.ANNOTATION_HIDDEN`: Annotations are invisible.
-- - `view.ANNOTATION_STANDARD`: Draw annotations left-justified with no decoration.
-- - `view.ANNOTATION_BOXED`: Indent annotations to match the annotated text and outline them
--	with a box.
-- - `view.ANNOTATION_INDENTED`: Indent non-decorated annotations to match the annotated text.
--
-- The default value is `view.ANNOTATION_BOXED` in the GUI version and `view.ANNOTATION_STANDARD`
-- in the terminal version.
-- @field view.annotation_visible

--- Indent annotations to match the annotated text and outline them with a box.
-- @field view.ANNOTATION_BOXED

--- Annotations are invisible.
-- @field view.ANNOTATION_HIDDEN

--- Draw annotations left-justified with no decoration.
-- @field view.ANNOTATION_STANDARD

--- Indent non-decorated annotations to match the annotated text.
-- @field view.ANNOTATION_INDENTED

--- The EOL annotation display style.
-- - `view.EOLANNOTATION_HIDDEN`: Annotations are invisible.
-- - `view.EOLANNOTATION_STANDARD`: Draw annotations with no decoration.
-- - `view.EOLANNOTATION_BOXED`: Outline annotations with a box.
-- - `view.EOLANNOTATION_STADIUM`: Outline annotations with curved ends.
-- - `view.EOLANNOTATION_FLAT_CIRCLE`: Outline annotations with flat left and curved right ends.
-- - `view.EOLANNOTATION_ANGLE_CIRCLE`: Outline annotations with angled left and curved right ends.
-- - `view.EOLANNOTATION_CIRCLE_FLAT`: Outline annotations with curved left and flat right ends.
-- - `view.EOLANNOTATION_FLATS`: Outline annotations with flat ends.
-- - `view.EOLANNOTATION_ANGLE_FLAT`: Outline annotations with angled left and flat right ends.
-- - `view.EOLANNOTATION_CIRCLE_ANGLE`: Outline annotations with curved left and angled right ends.
-- - `view.EOLANNOTATION_FLAT_ANGLE`: Outline annotations with flat left and angled right ends.
-- - `view.EOLANNOTATION_ANGLES`: Outline annotations with angled ends.
--
-- All annotations have the same shape.
--
-- The default value is `view.EOLANNOTATION_BOXED` in the GUI version and
-- `view.EOLANNOTATION_STANDARD` in the terminal version.
-- @field view.eol_annotation_visible

--- @field view.EOLANNOTATION_HIDDEN

--- @field view.EOLANNOTATION_STANDARD

--- @field view.EOLANNOTATION_BOXED

--- @field view.EOLANNOTATION_STADIUM

--- @field view.EOLANNOTATION_FLAT_CIRCLE

--- @field view.EOLANNOTATION_ANGLE_CIRCLE

--- @field view.EOLANNOTATION_CIRCLE_FLAT

--- @field view.EOLANNOTATION_FLATS

--- @field view.EOLANNOTATION_ANGLE_FLAT

--- @field view.EOLANNOTATION_CIRCLE_ANGLE

--- @field view.EOLANNOTATION_FLAT_ANGLE

--- @field view.EOLANNOTATION_ANGLES

--- Map of line numbers to how many annotation text lines they have. (Read-only)
-- @table annotation_lines

--- Mark Text with Indicators.
-- There are 32 indicators to mark text with. Indicators have an assigned indicator style and
-- are displayed along with any existing styles text may already have. They can be hovered over
-- and clicked on. Indicators move along with text.
--
-- Indicator style | Description
-- -|-
-- `view.INDIC_SQUIGGLE` | A squiggly underline
-- `view.INDIC_PLAIN` | An underline
-- `view.INDIC_DASH` | A dashed underline
-- `view.INDIC_DOTS` | A dotted underline
-- `view.INDIC_STRIKE` | A strike out line
-- `view.INDIC_BOX` | A bounding box
-- `view.INDIC_DOTBOX` | A dotted bounding box<sup>a</sup>
-- `view.INDIC_STRAIGHTBOX` | A translucent bounding box<sup>b</sup>
-- `view.INDIC_ROUNDBOX` | A translucent bounding box with rounded corners<sup>b</sup>
-- `view.INDIC_FULLBOX` | A translucent box that extends to the top of its line<sup>b</sup>
-- `view.INDIC_GRADIENT` | A bounding box with a vertical gradient from solid to transparent
-- `view.INDIC_GRADIENTCENTER` | A bounding box with a centered gradient from solid to transparent
-- `view.INDIC_TT` | An underline of small 'T' shapes
-- `view.INDIC_DIAGONAL` | An underline of diagonal hatches
-- `view.INDIC_POINT` | A triangle below the start of the indicator range
-- `view.INDIC_POINTCHARACTER` | A triangle below the center of the first character
-- `view.INDIC_POINT_TOP` | A triangle above the start of the indicator range
-- `view.INDIC_SQUIGGLELOW` | A thin squiggly underline for small fonts
-- `view.INDIC_SQUIGGLEPIXMAP` | A faster version of `view.INDIC_SQUIGGLE`
-- `view.INDIC_COMPOSITIONTHICK` | A thick underline that looks like input composition
-- `view.INDIC_COMPOSITIONTHIN` | A thin underline that looks like input composition
-- `view.INDIC_TEXTFORE` | Changes text's foreground color
-- `view.INDIC_HIDDEN` | An indicator with no visual effect
--
-- <sup>a</sup>Translucency alternates between `view.indic_alpha` and `view.indic_outline_alpha`
-- starting with the top-left pixel. Their default values are `30`, and `50`, respectively.<br/>
-- <sup>b</sup>`view.indic_alpha` and `view.indic_outline_alpha` set the fill and outline
-- transparency, respectively. Their default values are `30`, and `50`, respectively.
--
-- There are 8 pre-defined indicators used for showing how buffer text differs from its file's
-- saved state if `io.track_changes` is `true`. These indicators are in addition to the 32
-- available for general use.
--
-- Indicator number | Description
-- -|-
-- `INDICATOR_HISTORY_MODIFIED_INSERTION` | Text was inserted and has not yet been saved
-- `INDICATOR_HISTORY_MODIFIED_DELETION` | Text was deleted but not yet saved
-- `INDICATOR_HISTORY_SAVED_INSERTION` | Text was inserted and saved
-- `INDICATOR_HISTORY_SAVED_DELETION` | Text was deleted and saved
-- `INDICATOR_HISTORY_REVERTED_TO_MODIFIED_INSERTION` | Text was inserted, saved, and semi-reverted
-- `INDICATOR_HISTORY_REVERTED_TO_MODIFIED_DELETION` | Text was deleted, saved, and semi-reverted
-- `INDICATOR_HISTORY_REVERTED_TO_ORIGIN_INSERTION` | Text was inserted, saved, and fully reverted
-- `INDICATOR_HISTORY_REVERTED_TO_ORIGIN_DELETION` | Text was deleted, saved, and fully reverted
--
-- @section

--- Returns a unique indicator number for use with custom indicators.
-- Use this function for custom indicators in order to prevent clashes with the numbers of
-- other custom indicators.
-- @function view.new_indic_number

--- Map of indicator numbers to their indicator styles (`view.INDIC_*`).
-- Changing an indicator's style resets that indicator's hover style (`view.indic_hover_style`).
-- @table view.indic_style

--- A bounding box.
-- @field view.INDIC_BOX

--- A 2-pixel thick underline at the bottom of the line inset by 1 pixel on on either side.
-- Similar in appearance to the target in Asian language input composition.
-- @field view.INDIC_COMPOSITIONTHICK

--- A 1-pixel thick underline just before the bottom of the line inset by 1 pixel on either side.
-- Similar in appearance to the non-target ranges in Asian language input composition.
-- @field view.INDIC_COMPOSITIONTHIN

--- A dashed underline.
-- @field view.INDIC_DASH

--- An underline of diagonal hatches.
-- @field view.INDIC_DIAGONAL

--- A dotted bounding box.
-- Translucency alternates between `view.indic_alpha` and `view.indic_outline_alpha`
-- starting with the top-left pixel. Their default values are `30` and `50`, respectively.
-- @field view.INDIC_DOTBOX

--- A dotted underline.
-- @field view.INDIC_DOTS

--- Similar to `view.INDIC_STRAIGHTBOX` but extends to the top of its line, potentially touching
-- any similar indicators on the line above.
-- @field view.INDIC_FULLBOX

--- A bounding box with a vertical gradient from solid on top to transparent on bottom.
-- @field view.INDIC_GRADIENT

--- A bounding box with a centered gradient from solid in the middle to transparent on the top
-- and bottom.
-- @field view.INDIC_GRADIENTCENTER

--- An indicator with no visual effect.
-- @field view.INDIC_HIDDEN

--- An underline.
-- @field view.INDIC_PLAIN

--- A triangle below the start of the indicator range.
-- @field view.INDIC_POINT

--- A triangle above the start of the indicator range.
-- @field view.INDIC_POINT_TOP

--- A triangle below the center of the first character of the indicator range.
-- @field view.INDIC_POINTCHARACTER

--- A translucent bounding box with rounded corners. Use `view.indic_alpha` and
-- `view.indic_outline_alpha` to set the fill and outline transparency, respectively.
-- Their default values are `30` and `50`, respectively.
-- @field view.INDIC_ROUNDBOX

--- A squiggly underline 3 pixels in height.
-- @field view.INDIC_SQUIGGLE

--- A squiggly underline 2 pixels in height for small fonts.
-- @field view.INDIC_SQUIGGLELOW

--- Identical to `view.INDIC_SQUIGGLE` but draws faster by using a pixmap instead of multiple line
-- segments.
-- @field view.INDIC_SQUIGGLEPIXMAP

--- Similar to `view.INDIC_ROUNDBOX` but with sharp corners.
-- @field view.INDIC_STRAIGHTBOX

--- Strike out.
-- @field view.INDIC_STRIKE

--- Changes text's foreground color to the indicator's foreground color.
-- @field view.INDIC_TEXTFORE

--- An underline of small 'T' shapes.
-- @field view.INDIC_TT

--- @field view.INDICATOR_HISTORY_REVERTED_TO_ORIGIN_INSERTION

--- @field view.INDICATOR_HISTORY_REVERTED_TO_ORIGIN_DELETION

--- @field view.INDICATOR_HISTORY_SAVED_INSERTION

--- @field view.INDICATOR_HISTORY_SAVED_DELETION

--- @field view.INDICATOR_HISTORY_MODIFIED_INSERTION

--- @field view.INDICATOR_HISTORY_MODIFIED_DELETION

--- @field view.INDICATOR_HISTORY_REVERTED_TO_MODIFIED_INSERTION

--- @field view.INDICATOR_HISTORY_REVERTED_TO_MODIFIED_DELETION

--- @field view.INDICATOR_MAX

--- The indicator number used by `buffer:indicator_fill_range()` and
-- `buffer:indicator_clear_range()`.
-- @field indicator_current

--- Draws indicator number `buffer.indicator_current` over a range of text.
-- @param pos Start position of the range to indicate.
-- @param length Number of characters to indicate.
-- @function indicator_fill_range

--- Clears indicator number `buffer.indicator_current` over a range of text.
-- @param pos Start position of the range to clear the indicator from.
-- @param length Number of characters to clear the indicator from.
-- @function indicator_clear_range

--- Returns the previous boundary position of an indicator, or `1` if no indicator was found.
-- @param indicator Indicator number to search for in the range of `1` to `32`.
-- @param pos Position to start searching from.
-- @function indicator_start

--- Returns the next boundary position of an indicator, or `1` if no indicator was found.
-- @param indicator Indicator number to search for in the range of `1` to `32`.
-- @param pos Position to start searching from.
-- @function indicator_end

--- Returns a bit-mask of all of indicators at a position.
-- The first bit is set if indicator 1 is present, the second bit for indicator 2, and so on.
-- @param pos Position to get indicators at.
-- @function indicator_all_on_for

--- Map of indicator numbers to their foreground colors in "0xBBGGRR" format.
-- Changing an indicator's foreground color resets that indicator's hover foreground color
-- (`view.indic_hover_fore`).
-- @table view.indic_fore

--- Map of indicator numbers to their fill color alpha values.
-- An indicator whose indicator style is either `view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`,
-- or `view.INDIC_DOTBOX` will use the alpha value specified here.
--
-- The default values are `view.ALPHA_NOALPHA`, for no alpha.
-- @table view.indic_alpha

--- Map of indicator numbers to their outline color alpha values.
-- An indicator whose indicator style is either `view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`,
-- or `view.INDIC_DOTBOX` will use the alpha value specified here.
--
-- The default values are `view.ALPHA_NOALPHA`, for no alpha.
-- @table view.indic_outline_alpha

--- Map of indicator numbers to whether or not to draw them behind text instead of over the top
-- of it.
-- The default values are `false`.
-- @table view.indic_under

--- Map of indicator numbers to their hover indicator styles.
-- Textadept draws an indicator's hover style when the mouse cursor is hovering over that
-- indicator, or when the caret is within the indicator.
-- The default values are their respective indicator styles; there is no visible hover effect.
-- @see view.styles
-- @see buffer.name_of_style
-- @table view.indic_hover_style

--- Map of indicator numbers to their hover foreground colors in "0xBBGGRR" format.
-- The default values are their respective indicator foreground colors; there is no visible
-- hover effect.
-- @usage view.indic_hover_fore[indic_link] = 0xFF0000 -- hovering over links colors them blue
-- @table view.indic_hover_fore

--- Map of indicator numbers to their stroke widths in hundredths of a pixel.
-- An indicator whose indicator style is either `view.INDIC_PLAIN`, `view.INDIC_SQUIGGLE`,
-- `view.INDIC_TT`, `view.INDIC_DIAGONAL`, `view.INDIC_STRIKE`, `view.INDIC_BOX`,
-- `view.INDIC_ROUNDBOX`, `view.INDIC_STRAIGHTBOX`, `view.INDIC_FULLBOX`, `view.INDIC_DASH`,
-- `view.INDIC_DOTS`,  or `view.INDIC_SQUIGGLELOW` will use the stroke width specified here.
--
-- The default values are `100`, or 1 pixel.
-- @table view.indic_stroke_width

--- Display an Autocompletion or User List.
-- There are two types of lists: autocompletion lists and user lists. An autocompletion list
-- is a list of completions shown for the current word. A user list is a more general list
-- of options presented to the user. Both types of list update as the user types, both have
-- similar behavior options, and both may [display images](#display-images-in-lists) alongside
-- text. Autocompletion lists should define a separator character and a list order before showing
-- the list. User lists should define a separator character, a list order, and an identifier
-- number before showing the list. An autocompletion list inserts its selected item, while a
-- user list emits an event with its selected item.
-- @section

--- The byte value of the character that separates autocompletion and user list list items.
-- The default value is `32`, which is a space character (' ').
-- @field auto_c_separator

--- The order of an autocompletion or user list.
-- - `buffer.ORDER_PRESORTED`: Lists passed to `buffer:auto_c_show()` and `buffer:user_list_show()`
--	are in sorted, alphabetical order.
-- - `buffer.ORDER_PERFORMSORT`: Sort lists passed to `buffer:auto_c_show()` and
--	`buffer:user_list_show()`.
-- - `buffer.ORDER_CUSTOM`: Lists passed to `buffer:auto_c_show()` and `buffer:user_list_show()`
--	are already in a custom order.
--
-- The default value is `buffer.ORDER_PRESORTED`.
-- @field auto_c_order

--- Lists passed to `buffer:auto_c_show()` and `buffer:user_list_show()` are already in a
--	custom order.
-- @field ORDER_CUSTOM

--- Sort lists passed to `buffer:auto_c_show()` and `buffer:user_list_show()`.
-- @field ORDER_PERFORMSORT

--- Lists passed to `buffer:auto_c_show()` and `buffer:user_list_show()` are in sorted,
--	alphabetical order.
-- @field ORDER_PRESORTED

--- Displays an autocompletion list.
-- @param len_entered Number of characters behind the caret the word being autocompleted is.
-- @param items String list of completions to show, separated by `buffer.auto_c_separator`
--	characters. The sort order of this list (`buffer.auto_c_order`) must have already
--	been specified.
-- @see textadept.editing.autocompleters
-- @see textadept.editing.autocomplete
-- @function auto_c_show

--- Returns a unique user list identifier number for use with `buffer:user_list_show()`.
-- Use this function for custom user lists in order to prevent clashes with list identifiers
-- of other custom user lists.
-- @function view.new_user_list_type

--- Displays a user list.
-- When the user selects an item, `events.USER_LIST_SELECTION` is emitted.
-- @param id List identifier number to use, which must be greater than zero.
-- @param items String list of list items to show, separated by `buffer.auto_c_separator`
--	characters. The sort order of this list (`buffer.auto_c_order`) must have already
--	been specified.
-- @function user_list_show

--- Selects the first item that matches a prefix in an autocompletion or user list.
-- If `buffer.auto_c_ignore_case` is `true`, searches case-insensitively.
-- @param prefix String prefix to search for.
-- @function auto_c_select

--- Completes the current word with the one selected in an autocompletion list.
-- @function auto_c_complete

--- Cancels the active autocompletion or user list.
-- @function auto_c_cancel

--- Returns whether or not an autocompletion or user list is visible.
-- @function auto_c_active

--- Returns the position where autocompletion started or where a user list was shown.
-- @function auto_c_pos_start

--- The index of the currently selected item in an autocompletion or user list. (Read-only)
-- @field auto_c_current

--- The text of the currently selected item in an autocompletion or user list. (Read-only)
-- @field auto_c_current_text

--- Automatically choose the item in a single-item autocompletion list.
-- This option has no effect for a user list.
-- The default value is `true`.
-- @field auto_c_choose_single

--- The set of characters that, when the user types one of them, chooses the currently selected
-- item in an autocompletion or user list. (Write-only)
-- The default value is the empty string.
-- @field auto_c_fill_ups

--- Specify a set of characters that cancels an autocompletion or user list when the user types
-- one of them.
-- @param chars String set of characters that cancel autocompletion. This string is empty
--	by default.
-- @function auto_c_stops

--- Automatically cancel an autocompletion or user list when no entries match typed text.
-- The default value is `true`.
-- @field auto_c_auto_hide

--- Cancel an autocompletion list when backspacing to a position before where autocompletion
-- started (instead of before the word being completed).
-- This option has no effect for a user list.
-- The default value is `true`.
-- @field auto_c_cancel_at_start

--- Ignore case when searching an autocompletion or user list for matches.
-- The default value is `false`.
-- @field auto_c_ignore_case

--- Prefer case-sensitive matches even if `buffer.auto_c_ignore_case` is `true`.
-- - `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`: Prefer to select case-sensitive matches.
-- - `buffer.CASEINSENSITIVEBEHAVIOR_IGNORECASE`: No preference.
--
-- The default value is `buffer.CASEINSENSITIVEBEHAVIOR_RESPECTCASE`.
-- @field auto_c_case_insensitive_behavior

--- No preference.
-- @field CASEINSENSITIVEBEHAVIOR_IGNORECASE

--- Prefer to select case-sensitive matches.
-- @field CASEINSENSITIVEBEHAVIOR_RESPECTCASE

--- The maximum number of characters per item to show in autocompletion and user lists.
-- The default value is `0`, which automatically sizes the width to fit the longest item.
-- @field view.auto_c_max_width

--- The maximum number of items per page to show in autocompletion and user lists.
-- The default value is `5`.
-- @field view.auto_c_max_height

--- Delete any word characters immediately to the right of autocompleted text.
-- The default value is `false`.
-- @field auto_c_drop_rest_of_word

--- Autocomplete into multiple selections.
-- - `buffer.MULTIAUTOC_ONCE`: Autocomplete into only the main selection.
-- - `buffer.MULTIAUTOC_EACH`: Autocomplete into all selections.
--
-- The default value is `buffer.MULTIAUTOC_EACH`.
-- @field auto_c_multi

--- Autocomplete into all selections.
-- @field MULTIAUTOC_EACH

--- Autocomplete into only the main selection.
-- @field MULTIAUTOC_ONCE

--- Display Images in Lists.
-- Autocompletion and user lists can render images next to items by appending to each list
-- item the type separator character specific to lists followed by an image's type number that
-- uniquely identifies a registered image.
--
-- ```lua
-- local image = view.new_image_type()
-- events.connect(events.VIEW_NEW, function()
-- 	view:register_image(image, [[/* XPM */...]])
-- end)
--
-- local function autocomplete()
-- 	local list = {
-- 		string.format('foo%s%d', string.char(buffer.auto_c_type_separator), image),
-- 		'bar',
-- 		'baz'
-- 	}
-- 	buffer.auto_c_order = buffer.ORDER_PERFORMSORT
-- 	buffer:auto_c_show(0, table.concat(list, string.char(buffer.auto_c_separator)))
-- end
-- ```
-- @section

--- Returns a unique image type number for use with `view:register_image()` and
-- `view:register_rgba_image()`.
-- Use this function for custom image types in order to prevent clashes with numbers of
-- other custom image types.
-- @function view.new_image_type

--- Registers an XPM image to an image type number for use in autocompletion and user lists.
-- @param type Image type number to register the image with.
-- @param pixmap String [pixmap data](https://scintilla.org/ScintillaDoc.html#XPM).
-- @function view:register_image

--- The width of the RGBA image to be defined using `view:marker_define_rgba_image()` and
-- `view:register_rgba_image()`.
-- @field view.rgba_image_width

--- The height of the RGBA image to be defined using `view:marker_define_rgba_image()` and
-- `view:register_rgba_image()`.
-- @field view.rgba_image_height

--- The scale factor in percent of the RGBA image to be defined using
-- `view:marker_define_rgba_image()` and `view:register_rgba_image()`.
-- This is useful on macOS with a retina display where each display unit is 2 pixels: use a
-- factor of `200` so that each image pixel is displayed using a screen pixel.
-- The default scale, `100`, will stretch each image pixel to cover 4 screen pixels on a
-- retina display.
-- @field view.rgba_image_scale

--- Registers an RGBA image to an image type number for use in autocompletion and user lists.
-- @param type Type number to register the image with.
-- @param pixels String sequence of 4 byte pixel values (red, green, blue, and alpha) starting
--	with the pixels for the top line, with the leftmost pixel first, then continuing with
--	the pixels for subsequent lines. There is no gap between lines for alignment reasons.
--	The image dimensions, `view.rgba_image_width` and `view.rgba_image_height`, must have
--	already been defined.
-- @function view:register_rgba_image

--- The scale factor in percent of *all* list images shown.
-- This is useful on macOS with a retina display where each display unit is 2 pixels: use a
-- factor of `200` so that each image pixel is displayed using a screen pixel.
-- The default scale, `100`, will stretch each image pixel to cover 4 screen pixels on a
-- retina display.
-- @field view.auto_c_image_scale

--- The character byte that separates autocompletion and user list items and their image types.
-- Autocompletion and user list items can display both an image and text. Register images and
-- their types using `view:register_image()` or `view:register_rgba_image()` before appending
-- image types to list items after type separator characters.
-- The default value is `63` ('?').
-- @field auto_c_type_separator

--- Clears all images registered by `view:register_image()` and `view:register_rgba_image()`.
-- @function view:clear_registered_images

--- Show a Call Tip.
-- A call tip is a small pop-up window that conveys a piece of textual information, such as
-- the arguments and documentation for a function. A call tip may highlight an internal range
-- of its own text, such as the current argument in a function call.
-- @section

--- Displays a call tip.
-- @param pos Position in the view's buffer to show a call tip at.
-- @param text Call tip text to show. Any "\001" or "\002" bytes are replaced by clickable up
-- or down arrow visuals, respectively. These may be used to indicate that a symbol has more
-- than one call tip, for example.
-- @see events.CALL_TIP_CLICK
-- @function view:call_tip_show

--- Highlights a range of the call tip's text with the color `view.call_tip_fore_hlt`.
-- @param start_pos Start position in call tip text to highlight.
-- @param end_pos End position in call tip text to highlight.
-- @function view:call_tip_set_hlt

--- Hides the active call tip.
-- @function view:call_tip_cancel

--- Returns whether or not a call tip is visible.
-- @function view:call_tip_active

--- Returns a call tip's display position.
-- @function view:call_tip_pos_start

--- Display a call tip above the current line instead of below it.
-- The default value is `false`.
-- @field view.call_tip_position

--- The pixel width of tab characters in call tips.
-- When non-zero, also enables the use of style number `view.STYLE_CALLTIP` instead of
-- `view.STYLE_DEFAULT` for call tip styles.
--
-- The default value is non-zero and depends on `buffer.tab_width` and the current font.
-- @field view.call_tip_use_style

--- The position at which backspacing beyond it hides an active call tip. (Write-only)
-- @field view.call_tip_pos_start

--- A call tip's highlighted text foreground color in "0xBBGGRR" format. (Write-only)
-- @field view.call_tip_fore_hlt

--- Fold or Hide Lines.
-- Code folding temporarily hide blocks of source code. The buffer's lexer normally determines
-- code fold points that the view denotes with fold margin markers, but arbitrary lines may be
-- hidden or shown.
-- @section

--- Toggles the fold point on a line between expanded (where all of its child lines are visible)
-- and contracted (where all of its child lines are hidden).
-- @param line Line number to toggle the fold on.
-- @function view:toggle_fold

--- Sets the default text shown next to folded lines.
-- @param text String text to display after folded lines. It is drawn with the
--	`view.STYLE_FOLDDISPLAYTEXT` style.
-- @usage view:set_default_fold_display_text(' ... ')
-- @function view:set_default_fold_display_text

--- Toggles the fold point on a line and shows the given text next to that line if it is collapsed.
-- This overrides any default text set by `view:set_default_fold_display_text()`.
-- @param line Line number to toggle the fold on and display *text* next to.
-- @param text String text to display after the line. It is drawn with the
--	`view.STYLE_FOLDDISPLAYTEXT` style.
-- @function view:toggle_fold_show_text

--- Contracts, expands, or toggles the fold point on a line.
-- @param line Line number to set the fold state for.
-- @param action Fold action to perform:
--	- `view.FOLDACTION_CONTRACT`
--	- `view.FOLDACTION_EXPAND`
--	- `view.FOLDACTION_TOGGLE`
-- @function view:fold_line

--- @field view.FOLDACTION_CONTRACT

--- @field view.FOLDACTION_EXPAND

--- @field view.FOLDACTION_TOGGLE

--- Contracts, expands, or toggles the fold points on a line and on all of its child lines.
-- @param line Line number to set the fold states for.
-- @param action Fold action to perform:
--	- `view.FOLDACTION_CONTRACT`
--	- `view.FOLDACTION_EXPAND`
--	- `view.FOLDACTION_TOGGLE`
-- @function view:fold_children

--- Contracts, expands, or toggles all fold points in the buffer.
-- When toggling, the state of the first fold point determines whether to expand or contract.
-- @param action Fold action to perform:
--	- `view.FOLDACTION_CONTRACT`
--	- `view.FOLDACTION_EXPAND`
--	- `view.FOLDACTION_TOGGLE`
--	- `view.FOLDACTION_CONTRACT_EVERY_LEVEL`
-- @function view:fold_all

--- @field view.FOLDACTION_CONTRACT_EVERY_LEVEL

--- Hides a range of lines.
-- This has no effect on fold levels or fold flags.
-- @param start_line Start line of the range to hide.
-- @param end_line End line of the range to hide.
-- @function view:hide_lines

--- Shows a range of lines.
-- This has no effect on fold levels or fold flags and the first line cannot be hidden.
-- @param start_line Start line of the range to show.
-- @param end_line End line of the range to show.
-- @function view:show_lines

--- Ensures a line is visible by expanding any fold points hiding it.
-- @param line Line number to ensure visible.
-- @function view:ensure_visible

--- Ensures a line is visible by expanding any fold points hiding it based on the vertical caret
-- policy previously defined in `view:set_visible_policy()`.
-- @param line Line number to ensure visible.
-- @function view:ensure_visible_enforce_policy

--- Returns the default text shown next to folded lines.
-- @function view:get_default_fold_display_text

--- Map of line numbers to their fold level bit-masks.
-- Fold level bit-masks comprise an integer level combined with any of the following bit flags:
-- - `buffer.FOLDLEVELBASE`: The initial fold level.
-- - `buffer.FOLDLEVELWHITEFLAG`: The line is blank.
-- - `buffer.FOLDLEVELHEADERFLAG`: The line is a header, or fold point.
-- @table fold_level

--- The initial fold level.
-- @field FOLDLEVELBASE

--- The line is a header, or fold point.
-- @field FOLDLEVELHEADERFLAG

--- @field FOLDLEVELNUMBERMASK

--- The line is blank.
-- @field FOLDLEVELWHITEFLAG

--- Map of line numbers to their parent fold point line numbers. (Read-only)
-- A result of `-1` means the line has no parent fold point.
-- @table fold_parent

--- Returns the line number of a fold point's last child line.
-- @param line Line number of a fold point line.
-- @param level `-1`. For any other value, the line number of the last line after *line* whose
--	fold level is greater than *level* is returned.
-- @function get_last_child

--- Map of line numbers to whether or not their fold points (if any) are expanded.
-- Setting expanded fold states does not toggle folds; it only updates fold margin markers. Use
-- `view:toggle_fold()` instead.
-- @table view.fold_expanded

--- Returns the line number of the next contracted fold point, or `-1` if none exists.
-- @param line Line number to start searching at.
-- @function view:contracted_fold_next

--- Map of line numbers to whether or not they are visible. (Read-only)
-- @table view.line_visible

--- Whether or not all lines are visible. (Read-only)
-- @field view.all_lines_visible

--- Scroll the View.
-- @section

--- The horizontal scroll pixel position.
-- The default value is `0`.
-- @see view.first_visible_line
-- @field view.x_offset

--- Scrolls the buffer up one line, keeping the caret visible.
-- @function view:line_scroll_up

--- Scrolls the buffer down one line, keeping the caret visible.
-- @function view:line_scroll_down

--- Scrolls the buffer by columns and lines.
-- @param columns Number of columns to scroll horizontally. A negative value is allowed.
-- @param lines Number of lines to scroll vertically. A negative value is allowed.
-- @function view:line_scroll

--- Scrolls the top line of the view to be the wrapped sub-line of a displayed line number.
-- @param display_line Display line number to use (taking wrapped, annotated, and hidden lines
--	into account).
-- @param subline The sub-line of *display_line* to scroll to. A value of 1 is equivalent to
--	*display_line*. This is ignored if wrapping is off.
-- @function view:scroll_vertical

--- Scrolls the caret into view based on the policies previously defined in
-- `view:set_x_caret_policy()` and `view:set_y_caret_policy()`.
-- @function view:scroll_caret

--- Scrolls a range of text into view.
-- This is similar to `view:scroll_caret()`, but with *primary_pos* instead of the caret.
-- It is useful for scrolling search results into view.
-- @param secondary_pos Secondary range position to scroll into view.
-- @param primary_pos Primary range position to scroll into view. Priority is given to this position.
-- @function view:scroll_range

--- Centers the current line in the view.
-- @function view:vertical_center_caret

--- Scrolls to the beginning of the buffer without moving the caret.
-- @function view:scroll_to_start

--- Scrolls to the end of the buffer without moving the caret.
-- @function view:scroll_to_end

--- Configure Indentation and Line Endings.
-- Each buffer and file has its own indentation and end-of-line character settings.
-- @section

--- Use tabs instead of spaces in indentation.
-- Changing this does not convert any of the buffer's existing indentation. Use
-- `textadept.editing.convert_indentation()` to do so.
-- The default value is `true`.
-- @field use_tabs

--- The number of space characters a tab character represents.
-- The default value is `8`.
-- @field tab_width

--- The number of spaces in one level of indentation.
-- The default value is `0`, which uses the value of `buffer.tab_width`.
-- @field indent

--- Indent text when tabbing within indentation.
-- The default value is `true`.
-- @see textadept.editing.auto_indent
-- @field tab_indents

--- Un-indent text when backspacing within indentation.
-- The default value is `true`.
-- @field back_space_un_indents

--- The current end of line mode.
-- Changing this does not convert any of the buffer's existing end of line characters. Use
-- `buffer:convert_eols()` to do so.
--
-- - `buffer.EOL_CRLF`: Carriage return with line feed ("\r\n").
-- - `buffer.EOL_CR`: Carriage return ("\r").
-- - `buffer.EOL_LF`: Line feed ("\n").
--
-- The default value is `buffer.EOL_CRLF` on Windows platforms, and `buffer.EOL_LF` otherwise.
-- @field eol_mode

--- Carriage return ("\r").
-- @field EOL_CR

--- Carriage return with line feed ("\r\n").
-- @field EOL_CRLF

--- Line feed ("\n").
-- @field EOL_LF

--- Changes all end of line characters in the buffer.
-- This does not change `buffer.eol_mode`.
-- @param mode End of line mode to change to.
--	- `buffer.EOL_CRLF`
--	- `buffer.EOL_CR`
--	- `buffer.EOL_LF`
-- @function convert_eols

--- Configure Character Settings.
-- The classification of characters as word, whitespace, or punctuation characters affects the
-- buffer's behavior when moving between words or searching for whole words. The display of
-- individual characters may be changed.
-- @section

--- The string set of characters recognized as word characters.
-- The default value is a string that contains alphanumeric characters, an underscore, and all
-- characters greater than ASCII value 127.
-- @field word_chars

--- The string set of characters recognized as whitespace characters.
-- Set this only after setting `buffer.word_chars`.
-- The default value is a string that contains all non-newline characters less than ASCII value 33.
-- @field whitespace_chars

--- The string set of characters recognized as punctuation characters.
-- Set this only after setting `buffer.word_chars`.
-- The default value is a string that contains all non-word and non-whitespace characters.
-- @field punctuation_chars

--- Resets `buffer.word_chars`, `buffer.whitespace_chars`, and `buffer.punctuation_chars` to
-- their respective defaults.
-- @function set_chars_default

--- Map of character strings to their alternative string representations.
-- Use the empty string for the '\0' character when assigning its representation.
-- Call `view:clear_representation()` to remove a representation.
-- @usage view.representation['⌘'] = '⌘ (U+2318)'
-- @table view.representation

--- Removes a character's alternate string representation.
-- @param char String character in `view.representation` to remove. It may be a multi-byte
--	character.
-- @function view:clear_representation

--- Removes all alternate string representations of characters.
-- @function view:clear_all_representations

--- Map of character strings to their representation's appearance.
-- - `view.REPRESENTATION_PLAIN`: Draw the representation with no decoration.
-- - `view.REPRESENTATION_BLOB`: Draw the representation within a rounded rectangle and an
--	inverted color.
-- - `view.REPRESENTATION_COLOR`: Draw the representation using the color set in
--	`view.representation_color`.
--
-- The default values are `view.REPRESENTATION_BLOB`.
-- @table view.representation_appearance

--- Draw the representation with no decoration.
-- @field view.REPRESENTATION_PLAIN

--- Draw the representation within a rounded rectangle and an inverted color.
-- @field view.REPRESENTATION_BLOB

--- Draw the representation using the color set in `view.representation_color`.
-- @field view.REPRESENTATION_COLOR

--- Map of character strings to their representation's color in "0xBBGGRR" format.
-- @table view.representation_color

--- Configure the Color Theme.
-- Themes are Lua files that define colors, specify how the view displays text, and assign
-- colors and alpha values to various view properties.
--
-- #### Colors
--
-- Colors are numbers in "0xBBGGRR" format that range from `0` (black) to `0xFFFFFF` (white). The
-- low byte (RR) is the red component, the middle byte (GG) is green, and the high byte (BB)
-- is blue. Each component ranges from `0` to `0xFF` (255).
--
-- Alpha transparency values are numbers that range from `0` (transparent) to `0xFF` (opaque),
-- and also includes `view.ALPHA_NOALPHA` for no transparency.
--
-- **Terminal version note:** if your terminal emulator does not support RGB colors, or if you
-- would like to use your terminal's palette of up to 16 colors, you must use the following colors:
--
-- `0x000000` | Black | `0x404040` | Light black
-- `0x000080` | Red | `0x0000FF` | Light red
-- `0x008000` | Green | `0x00FF00` | Light green
-- `0x800000` | Blue | `0xFF0000` | Light blue
-- `0x800080` | Magenta | `0xFF00FF` | Light magenta
-- `0x808000` | Cyan | `0xFFFF00` | Light cyan
-- `0xC0C0C0` | White | `0xFFFFFF` | Light white
--
-- Your terminal emulator will map these colors to its palette for display.
--
-- #### Styles
--
-- Styles define how to display text, from the default font to line numbers in the margin,
-- to source code comments, strings, and keywords. Each of these elements has a style name
-- assigned to a table of style properties.
--
-- Style name | Target element
-- -|-
-- `view.STYLE_DEFAULT` | Everything (all elements inherit from this one)
-- `view.STYLE_LINENUMBER` | The line number margin
-- `view.STYLE_BRACELIGHT` | Highlighted brace characters
-- `view.STYLE_BRACEBAD` | A brace character with no match
-- `view.STYLE_CONTROLCHAR` | Control character blocks
-- `view.STYLE_INDENTGUIDE` | Indentation guides
-- `view.STYLE_CALLTIP` | Call tip text<sup>a</sup>
-- `view.STYLE_FOLDDISPLAYTEXT` | Text displayed next to folded lines
-- `lexer.ATTRIBUTE` | Language-specific
-- `lexer.BOLD` | Language-specific
-- `lexer.CLASS` | Language-specific
-- `lexer.CODE` | Language-specific
-- `lexer.COMMENT` | Language-specific
-- `lexer.CONSTANT` | Language-specific
-- `lexer.CONSTANT_BUILTIN` | Language-specific
-- `lexer.EMBEDDED` | Language-specific
-- `lexer.ERROR` | Language-specific
-- `lexer.FUNCTION` | Language-specific
-- `lexer.FUNCTION_BUILTIN` | Language-specific
-- `lexer.FUNCTION_METHOD` | Language-specific
-- `lexer.IDENTIFIER` | Language-specific
-- `lexer.ITALIC` | Language-specific
-- `lexer.KEYWORD` | Language-specific
-- `lexer.LABEL` | Language-specific
-- `lexer.LINK` | Language-specific
-- `lexer.NUMBER` | Language-specific
-- `lexer.OPERATOR` | Language-specific
-- `lexer.PREPROCESSOR` | Language-specific
-- `lexer.REFERENCE` | Language-specific
-- `lexer.REGEX` | Language-specific
-- `lexer.STRING` | Language-specific
-- `lexer.TAG` | Language-specific
-- `lexer.TYPE` | Language-specific
-- `lexer.UNDERLINE` | Language-specific
-- `lexer.VARIABLE` | Language-specific
-- `lexer.VARIABLE_BUILTIN` | Language-specific
--
-- <sup>a</sup> Only the `font`, `size`, `fore`, and `back` style properties are supported.
--
-- The table above is not an exhaustive list of style names. Some lexers may define their own.
--
-- Style property | Description
-- -|-
-- `font` | String font name
-- `size` | Integer font size
-- `bold` | Use a bold font face (the default value is `false`)
-- `weight` | Integer weight or boldness of a font, between 1 and 999
-- `italic` | Use an italic font face (the default value is `false`)
-- `underline` | Use an underlined font face (the default value is `false`)
-- `fore` | Font face foreground color in "0xBBGGRR" format
-- `back` | Font face background color in "0xBBGGRR" format
-- `eol_filled` | Extend the background color to the end of the line (the default value is `false`)
-- `case` | Font case<sup>a</sup>
-- `visible` | The text is visible instead of hidden (the default value is `true`)
-- `changeable` | The text is changeable instead of read-only t(he default value is `true`)
--
-- <sup>a</sup>`view.CASE_UPPER` for upper, `view.CASE_LOWER` for lower, and `view.CASE_MIXED`
-- for normal, mixed case. The default value is `view.CASE_MIXED`.
-- @section

--- Sets the view's color theme.
-- User themes in *~/.textadept/themes/* override Textadept's default themes when they have
-- the same name.
-- @param[opt] name String theme name. If it contains slashes, it is assumed to be an absolute
--	path to a theme. The default value is either 'light' or 'dark', depending on whether
--	the OS is in light mode or dark mode, respectively.
-- @param[opt] env Table of global variables that themes can utilize to override default settings
--	such as font and size.
-- @usage view:set_theme{font = 'Monospace', size = 12} -- keep current theme, but change font
-- @usage view:set_theme('my_theme', {font = 'Monospace', size = 12})
-- @function view:set_theme

--- Map of color name strings to color values in "0xBBGGRR" format.
-- A theme typically sets this map's contents. Changing colors manually (e.g. via the command
-- entry) has no effect since colors are referenced by value, not name.
--
-- Terminal version note: if your terminal emulator does not support RGB colors, or if you would
-- like to use your terminal's palette of up to 16 colors, use the following color values:
-- 0x000000 (black), 0x000080 (red), 0x008000 (green), 0x008080 (yellow), 0x800000 (blue),
-- 0x800080 (magenta), 0x808000 (cyan), white (0xC0C0C0), light 0x404040 (black), 0x0000FF
-- (light red), 0x00FF00 (light green), 0x00FFFF (light yellow), 0xFF0000 (light blue), 0xFF00FF
-- (light magenta), 0xFFFF00 (light cyan), and 0xFFFFFF (light white).
-- @table view.colors

--- Map of style names to style definition tables.
-- A theme typically sets this map's contents. If you are setting it manually (e.g. via the
-- command entry), call `view:set_styles()` to refresh the view and apply the styles.
--
-- Predefined style names are `view.STYLE_*` and `lexer.[A-Z]*`, and lexers may define their
-- own. To see the name of the style under the caret, use the "Tools > Show Style" menu item.
--
-- Terminal version note: displaying light colors may require a normal foreground color coupled
-- with a `bold = true` setting.
-- @usage view.styles[view.STYLE_DEFAULT] = {
--		font = 'Monospace', size = '10', fore = view.colors.black, back = view.colors.white
-- }
-- @usage view.styles[lexer.KEYWORD] = {bold = true}
-- @usage view.styles[lexer.ERROR] = {fore = view.colors.red, italic = true}
-- @table view.styles

--- The style of call tip text.
-- @field view.STYLE_CALLTIP

--- The style for control character blocks.
-- @field view.STYLE_CONTROLCHAR

--- The base style all styles inherit from.
-- @field view.STYLE_DEFAULT

--- The style of text displayed next to folded lines.
-- @field view.STYLE_FOLDDISPLAYTEXT

--- The style of indentation guides.
-- @field view.STYLE_INDENTGUIDE

--- The style of the line number margin.
-- @field view.STYLE_LINENUMBER

--- @field view.STYLE_MAX

--- Applies defined styles to the view.
-- This should be called any time a style in `view.styles` changes.
-- @function view:set_styles

--- Override Style Settings.
-- There are 256 different styles to style text with. The color theme normally dictates
-- default styles, but custom fonts, colors, and attributes may be applied to styles outside
-- of themes. However, these custom settings must be re-applied every time a new buffer or view
-- is created, and every time a lexer is loaded.
-- @section

--- Resets `view.STYLE_DEFAULT` to its initial state.
-- @function view:style_reset_default

--- Reverts all styles to having the same properties as `view.STYLE_DEFAULT`.
-- @function view:style_clear_all

--- Map of style numbers to their text's string font names.
-- @table view.style_font

--- Map of style numbers to their text's integer font sizes.
-- @table view.style_size

--- Map of style numbers to their text's foreground colors in "0xBBGGRR" format.
-- @table view.style_fore

--- Map of style numbers to their text's background colors in "0xBBGGRR" format.
-- @table view.style_back

--- Map of style numbers to whether or not their text is bold.
-- The default values are `false`.
-- @table view.style_bold

--- Map of style numbers to whether or not their text is italic.
-- The default values are `false`.
-- @table view.style_italic

--- Map of style numbers to whether or not their text is underlined.
-- The default values are `false`.
-- @table view.style_underline

--- Map of style numbers to whether or not their text's background colors extend all the way to
-- the view's right margin.
-- This only happens for styles whose characters occur last on lines.
--
-- The default values are `false`.
-- @table view.style_eol_filled

--- Map of style numbers to their text's letter-cases.
-- - `view.CASE_MIXED`: Display text normally.
-- - `view.CASE_UPPER`: Display text in upper case.
-- - `view.CASE_LOWER`: Display text in lower case.
-- - `view.CASE_CAMEL`: Display text in camel case.
--
-- The default values are `view.CASE_MIXED`.
-- @table view.style_case

--- Display text in camel case.
-- @field view.CASE_CAMEL

--- Display text in lower case.
-- @field view.CASE_LOWER

--- Display text normally.
-- @field view.CASE_MIXED

--- Display text in upper case.
-- @field view.CASE_UPPER

--- Map of style numbers to whether or not their text is visible.
-- The default values are `true`.
-- @table view.style_visible

--- Map of style numbers to their text's mutability.
-- Read-only styles do not allow the caret into ranges of their text.
--
-- The default values are `true`.
-- @table view.style_changeable

--- Assign Caret, Selection, Whitespace, and Line Colors.
-- The colors of various UI elements can be changed by assigning colors to their element IDs
-- in the `view.element_color` map.
--
-- Element ID | Description
-- -|-
-- `view.ELEMENT_SELECTION_TEXT` | Main selection text color
-- `view.ELEMENT_SELECTION_BACK` | Main selection background color
-- `view.ELEMENT_SELECTION_ADDITIONAL_TEXT` | Additional selection text color
-- `view.ELEMENT_SELECTION_ADDITIONAL_BACK` | Additional selection background color
-- `view.ELEMENT_SELECTION_SECONDARY_TEXT` | Secondary selection text color<sup>a</sup>
-- `view.ELEMENT_SELECTION_SECONDARY_BACK` | Secondary selection background color<sup>a</sup>
-- `view.ELEMENT_SELECTION_INACTIVE_TEXT` | Selection text color when another window has focus
-- `view.ELEMENT_SELECTION_INACTIVE_BACK` | Selection background color when another window has focus
-- `view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_TEXT` | Inactive additional selection text color
-- `view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_BACK` | Inactive additional selection background color
-- `view.ELEMENT_CARET` | Main selection caret color
-- `view.ELEMENT_CARET_ADDITIONAL` | Additional selection caret color
-- `view.ELEMENT_CARET_LINE_BACK` | Background color of the line that contains the caret
-- `view.ELEMENT_WHITE_SPACE` | Visible whitespace color
-- `view.ELEMENT_WHITE_SPACE_BACK` | Visible whitespace background color
-- `view.ELEMENT_FOLD_LINE` | Fold line color
-- `view.ELEMENT_HIDDEN_LINE` | The color of lines shown in place of hidden lines
--
-- <sup>a</sup>Linux only
--
-- @section

--- Map of UI element identifiers (`view.ELEMENT_*`) to their colors in "0xAABBGGRR" format.
-- If the alpha byte is omitted, it is assumed to be `0xFF` (opaque).
-- @table view.element_color

--- The main selection's text color.
-- @field view.ELEMENT_SELECTION_TEXT

--- The main selection's background color.
-- @field view.ELEMENT_SELECTION_BACK

--- The text color of additional selections.
-- @field view.ELEMENT_SELECTION_ADDITIONAL_TEXT

--- The background color of additional selections.
-- @field view.ELEMENT_SELECTION_ADDITIONAL_BACK

--- The text color of selections when another window contains the primary selection.
-- This is only available on Linux.
-- @field view.ELEMENT_SELECTION_SECONDARY_TEXT

--- The background color of selections when another window contains the primary selection.
-- This is only available on Linux.
-- @field view.ELEMENT_SELECTION_SECONDARY_BACK

--- The text color of selections when another window has focus.
-- @field view.ELEMENT_SELECTION_INACTIVE_TEXT

--- The background color of selections when another window has focus.
-- @field view.ELEMENT_SELECTION_INACTIVE_BACK

--- The text color of additional selections when another window has focus.
-- @field view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_TEXT

--- The background color of additional selections when another window has focus.
-- @field view.ELEMENT_SELECTION_INACTIVE_ADDITIONAL_BACK

--- The main selection's caret color.
-- @field view.ELEMENT_CARET

--- The caret color of additional selections.
-- @field view.ELEMENT_CARET_ADDITIONAL

--- The background color of the line that contains the caret.
-- @field view.ELEMENT_CARET_LINE_BACK

--- The color of visible whitespace.
-- @field view.ELEMENT_WHITE_SPACE

--- The background color of visible whitespace.
-- @field view.ELEMENT_WHITE_SPACE_BACK

--- The color of fold lines.
-- @field view.ELEMENT_FOLD_LINE

--- The color of lines shown in place of hidden lines.
-- @field view.ELEMENT_HIDDEN_LINE

--- Map of UI element identifiers to whether or not their colors have been manually set.
-- @table view.element_is_set

--- Resets the color of a UI element to its default color.
-- @param element One of the `view.ELEMENT_*` UI elements.
-- @function view:reset_element_color

--- Map of UI element identifiers to their default colors in "0xAABBGGRR" format. (Read-only)
-- @table view.element_base_color

--- Map of UI element identifiers to whether or not their elements support translucent colors.
-- @table view.element_allows_translucent

--- How selections are drawn.
-- - `view.LAYER_BASE`: Draw selections opaquely on the background.
-- - `view.LAYER_UNDER_TEXT`: Draw selections translucently under text.
-- - `view.LAYER_OVER_TEXT`: Draw selections translucently over text.
--
-- The default value is `view.LAYER_BASE`.
-- @field view.selection_layer

--- Configure Caret Display.
-- @section

--- The caret's visual style.
-- - `view.CARETSTYLE_INVISIBLE`: No caret.
-- - `view.CARETSTYLE_LINE`: A line caret.
-- - `view.CARETSTYLE_BLOCK`: A block caret.
--
-- The default value is `view.CARETSTYLE_LINE`.
-- @field view.caret_style

--- A block caret.
-- @field view.CARETSTYLE_BLOCK

--- No caret.
-- @field view.CARETSTYLE_INVISIBLE

--- A line caret.
-- @field view.CARETSTYLE_LINE

--- The line caret's pixel width in insert mode, between `0` and `20`.
-- The default value is `1`.
-- @field view.caret_width

--- The time between caret blinks in milliseconds.
-- A value of `0` stops blinking.
--
-- The default value is `500`.
-- @field view.caret_period

--- The caret line's frame width in pixels.
-- When non-zero, the line that contains the caret is framed instead of colored in. The
-- `view.ELEMENT_CARET_LINE_BACK` color applies to the frame.
--
-- The default value is `0`.
-- @field view.caret_line_frame

--- Show the caret line on sub-lines rather than entire wrapped lines.
-- The defalt value is `false`.
-- @field view.caret_line_highlight_subline

--- Always show the caret line, even when the view is not in focus.
-- The default value is `true`, but only for the current view, and only while Textadept has focus.
-- @field view.caret_line_visible_always

--- How the caret line is drawn.
-- - `view.LAYER_BASE`: Draw the caret line opaquely on the background.
-- - `view.LAYER_UNDER_TEXT`: Draw the caret line translucently under text.
-- - `view.LAYER_OVER_TEXT`: Draw the caret line translucently over text.
--
-- The default value is `view.LAYER_BASE`.
-- @field view.caret_line_layer

--- Draw opaquely on the background.
-- @field view.LAYER_BASE

--- Draw translucently under text.
-- @field view.LAYER_UNDER_TEXT

--- Draw translucently over text.
-- @field view.LAYER_OVER_TEXT

--- Display additional carets.
-- The default value is `true`.
-- @field view.additional_carets_visible

--- Allow additional carets to blink.
-- The default value is `true`.
-- @field view.additional_carets_blink

--- Enable virtual space, allowing the caret to move into the space past end of line characters.
-- This is either `buffer.VS_NONE` (disable virtual space) or a bit-mask of the following options:
-- - `buffer.VS_RECTANGULARSELECTION`: Enable virtual space only for rectangular selections.
-- - `buffer.VS_USERACCESSIBLE`: Enable virtual space outside of rectangular selections.
-- - `buffer.VS_NOWRAPLINESTART`: Prevent the caret from wrapping to the previous line via
--	`buffer:char_left()` and `buffer:char_left_extend()`.
--
-- The default value is `buffer.VS_NONE`.
-- @field virtual_space_options

--- Disable virtual space.
-- @field VS_NONE

--- Enable virtual space only for rectangular selections.
-- @field VS_RECTANGULARSELECTION

--- Enable virtual space outside of rectangular selections.
-- @field VS_USERACCESSIBLE

--- Prevent the caret from wrapping to the previous line via `buffer:char_left()` and
-- `buffer:char_left_extend()`. This option is not restricted to virtual space and should be
-- added to any of the above options.
-- @field VS_NOWRAPLINESTART

--- Configure Selection Display.
-- @section

--- Extend the selection to the view's right margin if it spans multiple lines.
-- The default value is `false`.
-- @field view.sel_eol_filled

--- Configure Whitespace Display.
-- Normally, tab, space, and end of line characters are invisible.
-- @section

--- Show whitespace characters.
-- - `view.WS_INVISIBLE`: Whitespace is invisible.
-- - `view.WS_VISIBLEALWAYS`: Display all space characters as dots and tab characters as arrows.
-- - `view.WS_VISIBLEAFTERINDENT`: Display only non-indentation spaces and tabs as dots and arrows.
-- - `view.WS_VISIBLEONLYININDENT`: Display only indentation spaces and tabs as dots and arrows.
--
-- The default value is `view.WS_INVISIBLE`.
-- @field view.view_ws

--- Whitespace is invisible.
-- @field view.WS_INVISIBLE

--- Display only non-indentation spaces and tabs as dots and arrows.
-- @field view.WS_VISIBLEAFTERINDENT

--- Display all space characters as dots and tab characters as arrows.
-- @field view.WS_VISIBLEALWAYS

--- Display only indentation spaces and tabs as dots and arrows.
-- @field view.WS_VISIBLEONLYININDENT

--- The pixel size of the dots that represent space characters when whitespace is visible.
-- The default value is `1`.
-- @field view.whitespace_size

--- How visible tabs are drawn.
-- - `view.TD_LONGARROW`: Draw tabs as arrows that stretch up to tabstops.
-- - `view.TD_STRIKEOUT`: Draw tabs as horizontal lines that stretch up to tabstops.
--
-- The default value is `view.TD_LONGARROW`.
-- @field view.tab_draw_mode

--- An arrow that stretches until the tabstop.
-- @field view.TD_LONGARROW

--- A horizontal line that stretches until the tabstop.
-- @field view.TD_STRIKEOUT

--- Display end of line characters.
-- The default value is `false`.
-- @field view.view_eol

--- The amount of pixel padding above lines.
-- The default value is `0`.
-- @field view.extra_ascent

--- The amount of pixel padding below lines.
-- The default is `0`.
-- @field view.extra_descent

--- Configure Scrollbar Display and Scrolling Behavior.
-- @section

--- Display the horizontal scroll bar.
-- The default value is `true` in the GUI version and `false` in the terminal version.
-- @field view.h_scroll_bar

--- Display the vertical scroll bar.
-- The default value is `true`.
-- @field view.v_scroll_bar

--- The horizontal scrolling pixel width.
-- If `view.scroll_width_tracking` is `false`, the view uses this static width for horizontal
-- scrolling instead of measuring the width of buffer lines.
--
-- The default value is `1` in conjunction with `view.scroll_width_tracking` being `true`. A
-- value of `2000` is reasonable if `view.scroll_width_tracking` is `false`.
-- @field view.scroll_width

--- Grow (but never shrink) `view.scroll_width` as needed to match the maximum width of a
-- displayed line.
-- Enabling this may have performance implications for buffers with long lines.
--
-- The default value is `true`.
-- @field view.scroll_width_tracking

--- Disable scrolling past the last line.
-- The default value is `true`.
-- @field view.end_at_last_line

--- Defines a scrolling policy for keeping the caret away from the horizontal margins.
-- @param policy Combination of the following policy flags to set:
--	- `view.CARET_SLOP`
--		When the caret goes out of view, scroll the view so the caret is *x* pixels
--		away from the right margin.
--	- `view.CARET_STRICT`
--		Scroll the view to ensure the caret stays *x* pixels away from the right margin.
--	- `view.CARET_EVEN`
--		Consider both horizontal margins instead of just the right one.
--	- `view.CARET_JUMPS`
--		Scroll the view more than usual in order to scroll less often.
-- @param x Number of pixels from the horizontal margins to keep the caret.
-- @function view:set_x_caret_policy

--- When the caret goes out of view, scroll the view so the caret is a number of pixels away
-- from the right margin, or a number of lines below the top margin.
-- @field view.CARET_SLOP

--- Scroll the view to ensure the caret stays a number of pixels away from the right margin,
-- or a number of lines below the top margin.
-- @field view.CARET_STRICT

--- Consider both horizontal or vertical margins instead of just the right or top ones,
-- respectively.
-- @field view.CARET_EVEN

--- Scroll the view more than usual in order to scroll less often.
-- @field view.CARET_JUMPS

--- Defines a scrolling policy for keeping the caret away from the vertical margins.
-- @param policy Combination of the following policy flags to set:
--	- `view.CARET_SLOP`
--		When the caret goes out of view, scroll the view so the caret is *y* lines
--		below from the top margin.
--	- `view.CARET_STRICT`
--		Scroll the view to ensure the caret stays *y* lines below from the top margin.
--	- `view.CARET_EVEN`
--		Consider both vertical margins instead of just the top one.
--	- `view.CARET_JUMPS`
--		Scroll the view more than usual in order to scroll less often.
-- @param y Number of lines from the vertical margins to keep the caret.
-- @function view:set_y_caret_policy

--- Defines a scrolling policy for keeping the caret away from the vertical margins when
-- `view:ensure_visible_enforce_policy()` redisplays hidden or folded lines.
-- It is similar in operation to `view:set_y_caret_policy()`.
-- @param policy Combination of the following policy flags to set:
--	- `view.VISIBLE_SLOP`
--		When the caret is out of view, scroll the view so the caret is *y* lines away
--		from the vertical margins.
--	- `view.VISIBLE_STRICT`
--		Scroll the view to ensure the caret stays a *y* lines away from the vertical
--		margins.
-- @param y Number of lines from the vertical margins to keep the caret.
-- @function view:set_visible_policy

--- When the caret is out of view, scroll the view so the caret is a number of lines away from
-- the vertical margins.
-- @field view.VISIBLE_SLOP

--- Scroll the view to ensure the caret stays a number of lines away from the vertical margins.
-- @field view.VISIBLE_STRICT

--- Configure Mouse Cursor Display.
-- @section

--- The mouse cursor to show.
-- - `view.CURSORNORMAL`: The text insert cursor.
-- - `view.CURSORARROW`: The arrow cursor.
-- - `view.CURSORWAIT`: The wait cursor.
-- - `view.CURSORREVERSEARROW`: The reversed arrow cursor.
--
-- The default value is `view.CURSORNORMAL`.
-- @field view.cursor

--- The arrow cursor.
-- @field view.CURSORARROW

--- The text insert cursor.
-- @field view.CURSORNORMAL

--- The reversed arrow cursor.
-- @field view.CURSORREVERSEARROW

--- The wait cursor.
-- @field view.CURSORWAIT

--- Configure Wrapped Line Display.
-- By default, lines that contain more characters than the view can show do not wrap into view
-- and onto sub-lines.
-- @section

--- Wrap long lines.
-- - `view.WRAP_NONE`: Do not wrap long lines.
-- - `view.WRAP_WORD`: Wrap long lines at word (and style) boundaries.
-- - `view.WRAP_CHAR`: Wrap long lines at character boundaries.
-- - `view.WRAP_WHITESPACE`: Wrap long lines at word boundaries (ignoring style boundaries).
--
-- The default value is `view.WRAP_NONE`.
-- @field view.wrap_mode

--- Wrap long lines at character boundaries.
-- @field view.WRAP_CHAR

--- Long lines are not wrapped.
-- @field view.WRAP_NONE

--- Wrap long lines at word boundaries (ignoring style boundaries).
-- @field view.WRAP_WHITESPACE

--- Wrap long lines at word (and style) boundaries.
-- @field view.WRAP_WORD

--- How to mark wrapped lines.
-- - `view.WRAPVISUALFLAG_NONE`: No visual flags.
-- - `view.WRAPVISUALFLAG_END`: Show a visual flag at the end of a wrapped line.
-- - `view.WRAPVISUALFLAG_START`: Show a visual flag at the beginning of a sub-line.
-- - `view.WRAPVISUALFLAG_MARGIN`: Show a visual flag in the sub-line's line number margin.
--
-- The default value is `view.WRAPVISUALFLAG_NONE`.
-- @field view.wrap_visual_flags

--- Show a visual flag at the end of a wrapped line.
-- @field view.WRAPVISUALFLAG_END

--- Show a visual flag in the sub-line's line number margin.
-- @field view.WRAPVISUALFLAG_MARGIN

--- No visual flags.
-- @field view.WRAPVISUALFLAG_NONE

--- Show a visual flag at the beginning of a sub-line.
-- @field view.WRAPVISUALFLAG_START

--- Where to mark wrapped lines.
-- - `view.WRAPVISUALFLAGLOC_DEFAULT`: Draw a visual flag near the view's right margin.
-- - `view.WRAPVISUALFLAGLOC_END_BY_TEXT`: Draw a visual flag near text at the end of a
--	wrapped line.
-- - `view.WRAPVISUALFLAGLOC_START_BY_TEXT`: Draw a visual flag near text at the beginning of
--	a sub-line.
--
-- The default value is `view.WRAPVISUALFLAGLOC_DEFAULT`.
-- @field view.wrap_visual_flags_location

--- Draw a visual flag near the view's right margin.
-- @field view.WRAPVISUALFLAGLOC_DEFAULT

--- Draw a visual flag near text at the end of a wrapped line.
-- @field view.WRAPVISUALFLAGLOC_END_BY_TEXT

--- Draw a visual flag near text at the beginning of a sub-line.
-- @field view.WRAPVISUALFLAGLOC_START_BY_TEXT

--- Indent wrapped lines.
-- - `view.WRAPINDENT_FIXED`: Indent wrapped lines by `view.wrap_start_indent` number of spaces.
-- - `view.WRAPINDENT_SAME`: Indent wrapped lines the same amount as the first line.
-- - `view.WRAPINDENT_INDENT`: Indent wrapped lines one more level than the level of the
--	first line.
-- - `view.WRAPINDENT_DEEPINDENT`: Indent wrapped lines two more levels than the level of the
--	first line.
--
-- The default value is `view.WRAPINDENT_FIXED`.
-- @field view.wrap_indent_mode

--- Indent wrapped lines two more levels than the level of the first line.
-- @field view.WRAPINDENT_DEEPINDENT

--- Indent wrapped lines by `view.wrap_start_indent`.
-- @field view.WRAPINDENT_FIXED

--- Indent wrapped lines one more level than the level of the first line.
-- @field view.WRAPINDENT_INDENT

--- Indent wrapped lines the same amount as the first line.
-- @field view.WRAPINDENT_SAME

--- The number of spaces of indentation to display wrapped lines with if
-- `view.wrap_indent_mode` is `view.WRAPINDENT_FIXED`.
-- The default value is `0`.
-- @field view.wrap_start_indent

--- Configure Text Zoom.
-- @section

--- Increases the size of all fonts by one point, up to a net increase of +60.
-- @function view:zoom_in

--- Decreases the size of all fonts by one point, up to a net decrease of -10.
-- @function view:zoom_out

--- The number of points to add to the size of all fonts.
-- Negative values are allowed, down to `-10`.
-- The default value is `0`.
-- @field view.zoom

--- Configure Long Line Display.
-- While the view does not enforce a maximum line length, it allows for visual identification
-- of long lines.
-- @section

--- The column number to mark long lines at.
-- @field view.edge_column

--- How to mark long lines.
-- - `view.EDGE_NONE`: Do not mark long lines.
-- - `view.EDGE_LINE`: Draw a single vertical line whose color is `view.edge_color` at column
--	`view.edge_column`.
-- - `view.EDGE_BACKGROUND`: Change the background color of text after column `view.edge_column`
--	to `view.edge_color`.
-- - `view.EDGE_MULTILINE`: Draw vertical lines whose colors and columns are defined by calls to
--	`view:multi_edge_add_line()`.
--
-- The default value is `view.EDGE_NONE`.
-- @field view.edge_mode

--- Change the background color of text after column `view.edge_column` to `view.edge_color`.
-- @field view.EDGE_BACKGROUND

--- Draw a single vertical line whose color is `view.edge_color` at column `view.edge_column`.
-- @field view.EDGE_LINE

--- Draw vertical lines whose colors and columns are defined by calls to
-- `view:multi_edge_add_line()`.
-- @field view.EDGE_MULTILINE

--- Long lines are not marked.
-- @field view.EDGE_NONE

--- Adds a new vertical long line marker.
-- @param column Column number to add a vertical line at.
-- @param color Color in "0xBBGGRR" format.
-- @function view:multi_edge_add_line

--- Clears all vertical lines created by `view:multi_edge_add_line()`.
-- @function view:multi_edge_clear_all

--- Map of edge column numbers to their column positions. (Read-only)
-- A position of `-1` means no edge column was found.
-- @table view.multi_edge_column

--- The color, in "0xBBGGRR" format, of the single edge or background for long lines (depending on
-- `view.edge_mode`).
-- @field view.edge_color

--- Configure Fold Settings and Folded Line Display.
-- @section

--- Enable folding for the lexers that support it.
-- The default value is `true`.
-- @field folding

--- Consider any blank lines after an ending fold point as part of the fold.
-- The default value is `false`.
-- @field fold_compact

--- Mark as fold points lines that contain both an ending and starting fold point.
-- For example, mark `} else {` as a fold point.
--
-- The default value is `false`.
-- @field fold_on_zero_sum_lines

--- Fold based on indentation level if a lexer does not have a folder.
-- Some lexers automatically enable this option.
--
-- The default value is `false`.
-- @field fold_by_indentation

--- Bit-mask of folding lines to draw in the buffer. (Read-only)
-- - `view.FOLDFLAG_NONE`: Do not draw folding lines.
-- - `view.FOLDFLAG_LINEBEFORE_EXPANDED`: Draw lines above expanded folds.
-- - `view.FOLDFLAG_LINEBEFORE_CONTRACTED`: Draw lines above collapsed folds.
-- - `view.FOLDFLAG_LINEAFTER_EXPANDED`: Draw lines below expanded folds.
-- - `view.FOLDFLAG_LINEAFTER_CONTRACTED`: Draw lines below collapsed folds.
-- - `view.FOLDFLAG_LEVELNUMBERS`: Show hexadecimal fold levels in line margins.
--	This option cannot be combined with `view.FOLDFLAG_LINESTATE`.
-- - `view.FOLDFLAG_LINESTATE`: Show line state in line margins.
--	This option cannot be combined with `view.FOLDFLAG_LEVELNUMBERS`.
--
-- The default value is `view.FOLDFLAG_NONE`.
-- @field view.fold_flags

--- Do not draw folding lines.
-- @field view.FOLDFLAG_NONE

--- Draw lines above expanded folds.
-- @field view.FOLDFLAG_LINEBEFORE_EXPANDED

--- Draw lines above collapsed folds.
-- @field view.FOLDFLAG_LINEBEFORE_CONTRACTED

--- Draw lines below expanded folds.
-- @field view.FOLDFLAG_LINEAFTER_EXPANDED

--- Draw lines below collapsed folds.
-- @field view.FOLDFLAG_LINEAFTER_CONTRACTED

--- Show hexadecimal fold levels in line margins.
-- Cannot be combined with `view.FOLDFLAG_LINESTATE`.
-- @field view.FOLDFLAG_LEVELNUMBERS

--- Show line state in fold margins.
-- Cannot be combined with `view.FOLDFLAG_LEVELNUMBERS`.
-- @field view.FOLDFLAG_LINESTATE

--- How to draw text shown next to folded lines.
-- - `view.FOLDDISPLAYTEXT_HIDDEN`: Do not show fold display text.
-- - `view.FOLDDISPLAYTEXT_STANDARD`: Show fold display text with no decoration.
-- - `view.FOLDDISPLAYTEXT_BOXED`: Show fold display text outlined with a box.
--
-- The default value is `view.FOLDDISPLAYTEXT_BOXED`.
-- @field view.fold_display_text_style

--- Fold display text is not shown.
-- @field view.FOLDDISPLAYTEXT_HIDDEN

--- Fold display text is shown with no decoration.
-- @field view.FOLDDISPLAYTEXT_STANDARD

--- Fold display text is shown outlined with a box.
-- @field view.FOLDDISPLAYTEXT_BOXED

--- Highlight Matching Braces.
-- @section

--- Highlights an unmatched brace character using the `view.STYLE_BRACEBAD` style.
-- @param pos Position in the view's buffer to highlight, or `-1` to remove the highlight.
-- @function view:brace_bad_light

--- Indicates unmatched brace characters should highlight with an indicator instead of the
-- `view.STYLE_BRACEBAD` style.
-- @param use_indicator Whether or not to use an indicator.
-- @param indicator Indicator number to use.
-- @function view:brace_bad_light_indicator

--- Highlights characters as matching braces using the `view.STYLE_BRACELIGHT` style.
-- If indent guides are enabled, this also uses `buffer.column` to locate the column of the
-- brace characters and sets `view.highlight_guide` in order to highlight the indent guide too.
-- @param pos1 Position of the first brace in the view's buffer to highlight.
-- @param pos2 Position of the second brace in the view's buffer to highlight.
-- @function view:brace_highlight

--- Indicates matching brace characters should highlight with an indicator instead of the
-- `view.STYLE_BRACELIGHT` style.
-- @param use_indicator Whether or not to use an indicator.
-- @param indicator Indicator number to use.
-- @function view:brace_highlight_indicator

--- The style for a brace character with no match.
-- @field view.STYLE_BRACEBAD

--- The style number for a highlighted brace character.
-- @field view.STYLE_BRACELIGHT

--- Configure Indentation Guide Display.
-- @section

--- Draw indentation guides.
-- Indentation guides are dotted vertical lines that appear within indentation whitespace at
-- each level of indentation.
--
-- - `view.IV_NONE`: Do not draw any guides.
-- - `view.IV_REAL`: Draw guides only within indentation whitespace.
-- - `view.IV_LOOKFORWARD`: Draw guides beyond the current line up to the next non-empty line's
--	indentation level, but with an additional level if the previous non-empty line is a
--	fold point.
-- - `view.IV_LOOKBOTH`: Draw guides beyond the current line up to either the indentation level
--	of the previous or next non-empty line, whichever is greater.
--
-- The default value is `view.IV_LOOKBOTH` in the GUI version, and `view.IV_NONE` in the
-- terminal version.
-- @field view.indentation_guides

--- Draw guides beyond the current line up to either the indentation level of the previous or
-- next non-empty line, whichever is greater.
-- @field view.IV_LOOKBOTH

--- Draw guides beyond the current line up to the next non-empty line's indentation level,
-- but with an additional level if the previous non-empty line is a fold point.
-- @field view.IV_LOOKFORWARD

--- Does not draw any guides.
-- @field view.IV_NONE

--- Draw guides only within indentation whitespace.
-- @field view.IV_REAL

--- The indentation guide column number to also highlight when highlighting matching braces, or
-- `0` to stop indentation guide highlighting.
-- @field view.highlight_guide

--- Configure File Types.
-- @section

--- Sets the buffer's lexer.
-- @param[opt] name String lexer name to set. If `nil`, Textadept tries to auto-detect the
--	buffer's lexer.
-- @see lexer.detect_extensions
-- @see lexer.detect_patterns
-- @function set_lexer

--- Returns the buffer's lexer name.
-- @param[opt=false] current Get the lexer at the current caret position in multi-language
--	lexers. If `false`, the parent lexer is always returned.
-- @function get_lexer

--- The buffer's lexer name. (Read-only)
-- If the lexer is a multi-language lexer, `buffer:get_lexer()` can obtain the lexer under
-- the caret.
-- @field lexer_language

--- Manually Style Text.
-- Plain text can be manually styled after manually [setting up styles](#override-style-settings).
-- @section

--- Instructs the lexer to style and mark fold points in a range of text.
-- This is useful for reprocessing and refreshing a range of text if that range has incorrect
-- highlighting or incorrect fold points.
-- @param start_pos Start position of the range to process.
-- @param end_pos End position of the range to process, or `-1` for the end of the buffer.
-- @function colorize

--- Clears all styling and folding information.
-- @function clear_document_style

--- Begins styling at a given position.
-- This must be called before any calls to `buffer:set_styling()`.
-- @param position Position to start styling at.
-- @param unused Unused number. `0` can be safely used.
-- @function start_styling

--- Assigns a style to the next range of buffer text.
-- This will update the current styling position.
-- `buffer:start_styling()` must have already been called.
-- @param length Number of characters to style with *style* starting from the current styling
--	position.
-- @param style Style number to assign, in the range from `1` to `256`.
-- @function set_styling

--- Query Style Information.
-- @section

--- Map of buffer positions to their style numbers. (Read-only)
-- @table style_at

--- The number of named lexer styles.
-- @field named_styles

--- Returns the name of a style number.
-- Note: due to an implementation detail, the returned style contains '.' instead of '\_'.
-- When setting styles, the '\_' form is preferred.
-- @param style Style number between `1` and `256` to get the name of.
-- @function name_of_style

--- Returns the style number associated with a style name, or `view.STYLE_DEFAULT` if that name
-- is not in use.
-- @param style_name Style name to get the number of.
-- @function style_of_name

--- The current styling position or the last correctly styled character's position. (Read-only)
-- @field end_styled

--- Miscellaneous.
-- @section

--- The buffer's tab label in the tab bar. (Write-only)
-- Textadept sets this automatically based on the buffer's filename or type, and its save status.
-- @field tab_label

--- Whether or not the buffer is read-only.
-- The default value is `false`.
-- @field read_only

--- Cancels the active selection mode, autocompletion or user list, call tip, etc.
-- @function cancel

--- Enable overtype mode, where typed characters overwrite existing ones.
-- The default value is `false`.
-- @field overtype

--- Toggles `buffer.overtype`.
-- @function edit_toggle_overtype

--- Enable background styling while the editor is idle.
-- This setting has no effect when `view.wrap_mode` is on.
--
-- - `view.IDLESTYLING_NONE`: Require text to be styled before displaying it.
-- - `view.IDLESTYLING_TOVISIBLE`: Style some text before displaying it and then style the rest
--	incrementally in the background as an idle-time task.
-- - `view.IDLESTYLING_AFTERVISIBLE`: Style text after the currently visible portion in the
--	background.
-- - `view.IDLESTYLING_ALL`: Style text both before and after the visible text in the background.
--
-- The default value is `view.IDLESTYLING_ALL`.
-- @field view.idle_styling

--- Style all the currently visible text before displaying it.
-- @field view.IDLESTYLING_NONE

--- Style some text before displaying it and then style the rest incrementally in the background
--	as an idle-time task.
-- @field view.IDLESTYLING_TOVISIBLE

--- Style some text before displaying it and then style the rest incrementally in the background
--	as an idle-time task.
-- @field view.IDLESTYLING_AFTERVISIBLE

--- Style text both before and after the visible text in the background.
-- @field view.IDLESTYLING_ALL

--- The number of milliseconds the mouse must idle before generating an `events.DWELL_START` event.
-- A time of `view.TIME_FOREVER` will never generate one.
-- @field view.mouse_dwell_time

--- @field view.TIME_FOREVER

--- A bit-mask of options for showing change history.
-- This is a low-level field. You probably want to use the higher-level `io.track_changes` instead.
--
-- - `view.CHANGE_HISTORY_DISABLED`: Do not show change history.
-- - `view.CHANGE_HISTORY_ENABLED`: Track change history.
-- - `view.CHANGE_HISTORY_MARKERS`: Display changes in the margin with markers.
-- - `view.CHANGE_HISTORY_INDICATORS`: Display changes in the buffer with indicators.
--
-- The default value is `view.CHANGE_HISTORY_DISABLED`.
-- @field view.change_history

--- Do not show change history.
-- @field view.CHANGE_HISTORY_DISABLED

--- Track change history.
-- @field view.CHANGE_HISTORY_ENABLED

--- Display changes in the margin with markers.
-- @field view.CHANGE_HISTORY_MARKERS

--- Display changes in the buffer with indicators.
-- @field view.CHANGE_HISTORY_INDICATORS

--- Buffer contents, styling, or markers have changed.
-- @field UPDATE_CONTENT

--- Buffer selection has changed (including caret movement).
-- @field UPDATE_SELECTION

--- View has scrolled horizontally.
-- @field view.UPDATE_H_SCROLL

--- @field view.UPDATE_NONE

--- View has scrolled vertically.
-- @field view.UPDATE_V_SCROLL

--- @field view.MOUSE_DRAG

--- @field view.MOUSE_PRESS

--- @field view.MOUSE_RELEASE

--- @field view.ALPHA_NOALPHA

--- @field view.ALPHA_OPAQUE

--- @field view.ALPHA_TRANSPARENT

--- Deletes the buffer.
-- **Do not call this function.** Call `buffer:close()` instead.
-- @see events.BUFFER_DELETED
-- @function delete

-- Unused Fields.
-- - accessibility
-- - annotation_style_offset
-- - annotation_styles
-- - automatic_fold
-- - auto_c_style
-- - buffered_draw
-- - call_tip_back
-- - call_tip_fore
-- - caret_line_visible
-- - character_category_optimization
-- - character_pointer
-- - code_page
-- - command_events
-- - control_char_symbol
-- - direct_function
-- - direct_pointer
-- - direct_status_function
-- - distance_to_secondary_styles
-- - doc_pointer
-- - eol_annotation_style_offset
-- - focus
-- - font_quality
-- - gap_position
-- - hotspot_active_underline
-- - hotspot_single_line
-- - identifier
-- - identifiers
-- - ime_interaction
-- - indic_flags
-- - indicator_value
-- - key_words
-- - layout_cache
-- - lexer
-- - line_character_index
-- - line_end_types_active
-- - line_end_types_allowed
-- - line_end_types_supported
-- - line_state
-- - margin_style_offset
-- - margin_styles
-- - max_line_state
-- - mod_event_mask
-- - mouse_down_captures
-- - paste_convert_endings
-- - phases_draw
-- - position_cache
-- - primary_style_from_style
-- - print_color_mode
-- - print_magnification
-- - print_wrap_mode
-- - property
-- - property_int
-- - selection_hidden
-- - status
-- - style_character_set
-- - style_check_monospaced
-- - style_from_sub_style
-- - style_hotspot
-- - style_index_at
-- - style_size_fractional
-- - style_stretch
-- - style_weight
-- - sub_style_bases
-- - sub_styles_length
-- - sub_styles_start
-- - supports_feature
-- - tab_minimum_width
-- - technology
-- - two_phase_draw
-- - undo_action_position
-- - undo_action_text
-- - undo_action_type
-- - undo_actions
-- - undo_current
-- - undo_detach
-- - undo_save_point
-- - undo_sequence
-- - undo_tentative
-- - INDICATOR_CONTAINER
-- - MOD_NORM
-- - CP_UTF8
-- - LASTSTEPINUNDOREDO
-- - MAX_MARGIN
-- - MODEVENTMASKALL
-- - MOD_BEFOREDELETE
-- - MOD_BEFOREINSERT
-- - MOD_CHANGEANNOTATION
-- - MOD_CHANGEFOLD
-- - MOD_CHANGEINDICATOR
-- - MOD_CHANGELINESTATE
-- - MOD_CHANGEMARGIN
-- - MOD_CHANGEMARKER
-- - MOD_CHANGESTYLE
-- - MOD_CONTAINER
-- - MOD_DELETETEXT
-- - MOD_INSERTCHECK
-- - MOD_INSERTTEXT
-- - MOD_LEXERSTATE
-- - MULTILINEUNDOREDO
-- - MULTISTEPUNDOREDO
-- - PERFORMED_REDO
-- - PERFORMED_UNDO
-- - PERFORMED_USER
-- - STARTACTION
-- - STYLE_LASTPREDEFINED

-- Unused Functions.
-- - add_ref_document
-- - add_styled_text
-- - add_tab_stop
-- - add_undo_action
-- - allocate
-- - allocate_lines
-- - allocate_extended_styles
-- - allocate_line_character_index
-- - allocate_sub_styles
-- - assign_cmd_key
-- - auto_c_set_options
-- - brace_match_next
-- - can_paste
-- - caret_fore
-- - caret_line_back
-- - caret_line_back_alpha
-- - change_insertion
-- - change_last_undo_action_text
-- - change_lexer_state
-- - char_position_from_point
-- - char_position_from_point_close
-- - character_category_optimization
-- - clear_all_cmd_keys
-- - clear_cmd_key
-- - clear_selections
-- - clear_tab_stops
-- - count_code_units
-- - create_document
-- - create_loader
-- - describe_property
-- - describe_key_word_sets
-- - description_of_style
-- - encoded_from_utf8
-- - expand_children
-- - find_indicator_flash
-- - find_indicator_hide
-- - find_indicator_show
-- - find_text
-- - find_text_full
-- - form_feed
-- - format_range
-- - format_range_full
-- - free_sub_styles
-- - get_font_locale
-- - get_hotspot_active_back
-- - get_hotspot_active_fore
-- - get_line_sel_end_position
-- - get_line_sel_start_position
-- - get_next_tab_stop
-- - get_range_pointer
-- - get_styled_text
-- - get_styled_text_full
-- - grab_focus
-- - hide_selection
-- - index_position_from_line
-- - indicator_value_at
-- - layout_threads
-- - line_from_index_position
-- - load_lexer_library
-- - mouse_wheel_captures
-- - null
-- - point_x_from_position
-- - point_y_from_position
-- - position_from_point
-- - position_from_point_close
-- - position_relative_code_units
-- - private_lexer_call
-- - property_expanded
-- - property_names
-- - property_type
-- - push_undo_action_type
-- - release_all_extended_styles
-- - release_document
-- - release_line_character_index
-- - sel_alpha
-- - selection_from_point
-- - set_font_locale
-- - set_hotspot_active_back
-- - set_hotspot_active_fore
-- - set_length_for_encode
-- - set_sel_back
-- - set_sel_fore
-- - set_styling_ex
-- - start_record
-- - stop_record
-- - style_invisible_representation
-- - tags_of_style
-- - target_as_utf8
-- - text_range_full
-- - use_pop_up

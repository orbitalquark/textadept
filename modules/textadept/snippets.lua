-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Snippets for Textadept.
--
-- ### Overview
--
-- Define snippets in the global `snippets` table in key-value pairs. Each pair consists of
-- either a string trigger word and its snippet text, or a string lexer name (from the *lexers/*
-- directory) with a table of trigger words and snippet texts. When searching for a snippet to
-- insert based on a trigger word, Textadept considers snippets in the current lexer to have
-- priority, followed by the ones in the global table. This means if there are two snippets
-- with the same trigger word, Textadept inserts the one specific to the current lexer, not
-- the global one.
--
-- ### Syntax
--
-- Snippets may contain any combination of plain-text sequences, variables, interpolated code,
-- and placeholders.
--
-- #### Plain Text
--
-- Plain text consists of any character except '$' and '\`'. Those two characters are reserved for
-- variables, interpolated code, and placeholders. In order to use either of those two characters
-- literally, prefix them with '\' (e.g. `\$` inserts a literal '$').
--
-- #### Variables
--
-- Variables are defined in the `textadept.snippets.variables` table. Textadept expands
-- them in place using the '$' prefix (e.g. `$TM_SELECTED_TEXT` references the currently
-- selected text). You can provide default values for empty or undefined variables using the
-- "${*variable*:*default*}" syntax (e.g. `${TM_SELECTED_TEXT:no text selected}`). The values of
-- variables may be transformed in-place using the "${*variable*/*regex*/*format*/*options*}"
-- syntax (e.g. `${TM_SELECTED_TEXT/.+/"$0"/}` quotes the selected text). The section on
-- placeholder transforms below describes this syntax in more detail.
--
-- #### Interpolated Shell Code
--
-- Snippets can execute shell code enclosed within '\`' characters, and insert any standard output
-- (stdout) emitted by that code. Textadept omits a trailing newline if it exists. For example,
-- the following snippet evaluates (on macOS and Linux) the currently selected arithmetic
-- expression and replaces it with the result:
--
--	snippets.eval = '`echo $(( $TM_SELECTED_TEXT ))`'
--
-- #### Interpolated Lua Code
--
-- Snippets can also execute Lua code enclosed within "\`\`\`" sequences, and insert any string
-- results returned by that code. For example, the following snippet inserts the current date
-- and time:
--
--	snippets.date = '```os.date()```'
--
-- Lua code is executed within Textadept's Lua environment, with the addition of snippet
-- variables available as global variables (e.g. `TM_SELECTED_TEXT` exists as a global).
--
-- #### Placeholders
--
-- The true power of snippets lies with placeholders. Using placeholders, you can insert a text
-- template and tab through placeholders one at a time, filling them in. Placeholders may be
-- linked to one another, either mirroring text or transforming it in-place.
--
-- ##### Tab Stops
--
-- The simplest kind of placeholder is called a tab stop, and its syntax is either `$`*n*
-- or `${`*n*`}`, where *n* is an integer. When a snippet is inserted, the caret is moved
-- to the "$1" placeholder. Pressing the `Tab` key jumps to the next placeholder, "$2", and
-- so on. When there are no more placeholders to jump to, the caret moves to either the "$0"
-- placeholder if it exists, or it moves to the end of the snippet. For example, the following
-- snippet inserts a 3-element vector, with tab stops at each element:
--
--	snippets.vec = '[$1, $2, $3]'
--
-- ##### Default Values
--
-- Placeholders may have default values using the "${*n*:*default*}" syntax. For example,
-- the following snippet creates a numeric "for" loop in Lua:
--
--	snippets.lua.fori = [[
--	for ${1:i} = ${2:1}, $3 do
--		$0
--	end]]
--
-- Multiline snippets should be indented with tabs. Textadept will apply the buffer's current
-- indentation settings to the snippet upon insertion.
--
-- Placeholders may be nested inside one another. For example, the following snippet inserts
-- a function call with a mandatory first argument, but an optional second one:
--
--	snippets.call = '${1:func}($2${3:, $4})'
--
-- Upon arriving at the third placeholder, backspacing and pressing `Tab` completes the snippet
-- with a single argument. On the other hand, pressing `Tab` again at the third placeholder
-- jumps to the second argument for input.
--
-- Note that plain text inside default values may not contain a '}' character either, as it is
-- reserved to indicate the end of the placeholder. Use `\}` to represent a literal '}'.
--
-- ##### Mirrors
--
-- Multiple placeholders can share the same numeric index. When this happens, Textadept visits
-- the one with a default value if it exists. Otherwise, the editor visits the first one it
-- finds. As you type text into a placeholder, any other placeholders with the same index mirror
-- the typed text. For example, the following snippet inserts beginning and ending HTML/XML
-- tags with the same name:
--
--	snippets.tag = '<${1:div}>$0</$1>'
--
-- The end tag mirrors whatever name you type into the start tag.
--
-- ##### Transforms
--
-- Sometimes mirrors are not quite good enough. For example, perhaps the mirror's content needs to
-- deviate slightly from its linked placeholder, like capitalizing the first letter. Or perhaps
-- the mirror's contents should depend on the presence (or absence) of text in its linked
-- placeholder. This is where placeholder transforms come in handy.
--
-- Transforms use the "${*n*/*regex*/*format*/*options*}" syntax, where *regex* is a [regular
-- expression][] (regex) to match against the content of placeholder *n*, *format* is a formatted
-- replacement for matched content, and *options* are regex options to use when matching. *format*
-- may contain any of the following:
--
-- - Plain text.
-- - "$*m*" and "${*m*}" sequences, which represent the content of the *m*th capture (*m*=0 is
--	the entire match for this and all subsequent sequences).
-- - "${*m*:/upcase}", "${*m*:/downcase}", and "${*m*:/capitalize}" sequences, which
--	represent the uppercase, lowercase, and capitalized forms, respectively, of the
--	content of the *m*th capture. You can define your own transformation function in
--	`textadept.snippets.transform_methods`.
-- - A "${*m*:?*if*:*else*}" sequence, which inserts *if* if the content of capture *m* is
--	non-empty. Otherwise, *else* is used.
-- - A "${*m*:+*if*}" sequence, which inserts *if* if the content of capture *m* is
--	non-empty. Otherwise nothing is inserted.
-- - "${*m*:*default*}" and "${*m*:-*default*}" sequences, which insert *default* if the content
--	of capture *m* is empty. Otherwise, capture *m* is mirrored.
--
-- *options* may include any of the following letters:
--
-- - g: Replace all instances of matched text, not just the first one.
--
-- For example, the following snippet defines an attribute along with its getter and setter functions:
--
--	snippets.attr = [[
--		${1:int} ${2:name};
--
--		${1} get${2/./${0:/upcase}/}() { return $2; }
--		void set${2/./${0:/upcase}/}(${1} ${3:value}) { $2 = $3; }
--	]]
--
-- Note that the '/' and '}' characters are reserved in certain places within a placeholder
-- transform. Use `\/` and `\}`, respectively, to represent literal versions of those characters
-- where necessary.
--
-- [regular expression]: manual.html#regex-and-lua-pattern-syntax
--
-- ##### Multiple Choices
--
-- Placeholders may define a list of options for the user to choose from using the
-- "${*n*|*items*|}" syntax, where *items* is a comma-separated list of options
-- (e.g. `${1|foo,bar,baz|}`).
--
-- Items may not contain a '\|' character, as it is reserved to indicate the end of the choice list.
-- Use `\|` to represent a literal '\|'.
--
-- ### Migrating Legacy Snippets
--
-- Legacy snippets used the following syntax:
--
-- - "%*n*" for tab stops and mirrors.
-- - "%*n*(*default*)" for default placeholders.
-- - "%*n*<*Lua code*>" for Lua transforms, where *n* is optional.
-- - "%*n*[*Shell code*]" for Shell transforms, where *n* is optional.
-- - "%*n*{*items*}" for multiple choice placeholders.
--
-- You can migrate your snippets using the following steps:
--
-- 1. Substitute '%' with '$' in tab stops and mirrors.
-- 2. Substitute "%*n*(*default*)" default placeholders with "${*n*:*default*}". The following
--	regex and replacement should work for non-nested placeholders: `%(\d+)\(([^)]+)\)` and
--	`${\1:\2}`.
-- 3. Replace *n*-based Lua and Shell transforms with [placeholder transforms](#transforms). You
--	can add your own transform function to `textadept.snippets.transform_methods` if you
--	need to.
-- 4. Replace bare Lua and Shell transforms with interpolated Lua and shell code.
-- 5. Substitute "%*n*{*items*}" choice placeholders with "${*n*\|*items*\|}".
--
-- @module textadept.snippets
local M = {}

--- The snippet placeholder indicator number.
M.INDIC_PLACEHOLDER = _SCINTILLA.new_indic_number()

--- List of directory paths to look for snippet files in.
-- Filenames are of the form *lexer.trigger.ext* or *trigger.ext* (*.ext* is an optional,
-- arbitrary file extension). If the global `snippets` table does not contain a snippet for
-- a given trigger, this table is consulted for a matching filename, and the contents of that
-- file is inserted as a snippet.
-- Note: If a directory has multiple snippets with the same trigger, the snippet chosen for
-- insertion is not defined and may not be constant.
M.paths = {}

--- Map of snippet variable names to string values or functions that return string values.
-- Each time a snippet is inserted, this map is used to set its variables.
-- @field TM_SELECTED_TEXT The currently selected text, if any.
-- @field TM_CURRENT_LINE The contents of the current line.
-- @field TM_CURRENT_WORD The word under the caret, if any.
-- @field TM_LINE_NUMBER The current line number.
-- @field TM_LINE_INDEX The current line number, counting from 0.
-- @field TM_FILENAME The buffer's filename, excluding path, if any.
-- @field TM_FILENAME_BASE The buffer's bare filename, without extension.
-- @field TM_DIRECTORY The buffer's parent directory path.
-- @field TM_FILEPATH The buffer's filename, including path.
M.variables = {}

--- Map of format method names to their functions for text captured in placeholder transforms.
-- @field upcase Uppercases the captured text.
-- @field downcase Lowercases the captured text.
-- @field capitalize Capitalizes the captured text.
M.transform_methods = {
	upcase = string.upper, downcase = string.lower, capitalize = function(s)
		return s:gsub('^(.)(.*)$', function(first, rest) return first:upper() .. rest:lower() end)
	end
}

local INDIC_SNIPPET = _SCINTILLA.new_indic_number()
local INDIC_CURRENTPLACEHOLDER = _SCINTILLA.new_indic_number()

--- Map of [snippet](#textadept.snippets) triggers with their snippet text or functions that
-- return such text, with language-specific snippets tables assigned to a lexer name key.
_G.snippets = {}
for _, name in ipairs(lexer.names()) do snippets[name] = {} end

--- Finds the snippet assigned to the trigger word behind the caret and returns the trigger word
-- and snippet text.
-- If *grep* is `true`, returns a table of snippets (trigger-text key-value pairs) that match
-- the trigger word instead of snippet text. Snippets are searched for in the global snippets
-- table followed by snippet directories. Lexer-specific snippets are preferred.
-- @param grep Flag that indicates whether or not to return a table of snippets that match the
--	trigger word.
-- @param no_trigger Flag that indicates whether or not to ignore the trigger word and return
--	all snippets.
-- @return trigger word, snippet text or table of matching snippets
local function find_snippet(grep, no_trigger)
	local matching_snippets = {}
	local trigger = not no_trigger and
		buffer:text_range(buffer:word_start_position(buffer.current_pos), buffer.current_pos) or ''
	if no_trigger then grep = true end
	local lang = buffer:get_lexer(true)
	local name_patt = '^' .. trigger
	-- Search in the snippet tables.
	local snippet_tables = {snippets}
	if type(snippets[lang]) == 'table' then table.insert(snippet_tables, 1, snippets[lang]) end
	for _, snippets in ipairs(snippet_tables) do
		if not grep and snippets[trigger] then return trigger, snippets[trigger] end
		if not grep then goto continue end
		for name, text in pairs(snippets) do
			if name:find(name_patt) and type(text) ~= 'table' then
				matching_snippets[name] = tostring(text)
			end
		end
		::continue::
	end
	-- Search in snippet files.
	for i = 1, #M.paths do
		for basename in lfs.dir(M.paths[i]) do
			-- Snippet files are either of the form "lexer.trigger.ext" or "trigger.ext". Prefer
			-- "lexer."-prefixed snippets.
			local p1, p2, p3 = basename:match('^([^.]+)%.?([^.]*)%.?([^.]*)$')
			if not grep and (p1 == lang and p2 == trigger or p1 == trigger and p3 == '') or
				(grep and
					(p1 == lang and p2 and p2:find(name_patt) or p1 and p1:find(name_patt) and p3 == '')) then
				local f = io.open(string.format('%s/%s', M.paths[i], basename))
				local text = f:read('a')
				f:close()
				if not grep and p1 == lang then return trigger, text end
				matching_snippets[p1 == lang and p2 or p1] = text
			end
		end
		if not grep and next(matching_snippets) then
			return trigger, select(2, next(matching_snippets)) -- non-preferred "trigger.ext" was found
		end
	end
	if not grep then return nil, nil end
	return trigger, matching_snippets
end

--- A snippet object.
-- @field trigger The word that triggered this snippet.
-- @field original_sel_text The text originally selected when this snippet was inserted.
-- @field start_pos This snippet's start position.
-- @field end_pos This snippet's end position. This is a metafield that is computed based on the
--	`INDIC_SNIPPET` sentinel.
-- @field placeholder_pos The beginning of the current placeholder in this snippet. This is
--	used by transforms to identify text to transform. This is a metafield that is computed
--	based on `INDIC_CURRENTPLACEHOLDER`.
-- @field index This snippet's current placeholder index.
-- @field max_index The number of different placeholders in this snippet.
-- @field snapshots A record of this snippet's text over time. The snapshot for a given placeholder
--	index contains the state of the snippet with all placeholders of that index filled in
--	(prior to moving to the next placeholder index). Snippet state consists of a `text`
--	string field and a `placeholders` table field.
-- @field variables A map of snippet variable names to their string values.
-- @field finished Whether or not the snippet has no more placeholders to visit.
local snippet = {}

local P, S, R, V = lpeg.P, lpeg.S, lpeg.R, lpeg.V
local C, Cs, Cp, Ct, Cg, Cc = lpeg.C, lpeg.Cs, lpeg.Cp, lpeg.Ct, lpeg.Cg, lpeg.Cc

--- Returns a pattern that matches any character other than the one in string *chars*, but
-- allowing for escapes.
-- Escaped characters are captured without their forward slashes.
-- @param chars String character set to exclude.
local function any_but(chars) return Cs((1 - S(chars .. '\\') + '\\' * C(1) / 1)^1) end

--- A snippet placeholder object, constructed in part by LPeg.
-- Each placeholder is stored in a snippet snapshot.
-- @field index This placeholder's index.
-- @field default List of parts comprising this placeholder's default text, if any. Each part
--	is either a string or another placeholder object.
-- @field simple Whether or not this placeholder is a simple one (i.e. a tab stop).
-- @field transform Whether or not this placeholder is a transform.
-- @field regex The regex for this transform.
-- @field repl List of replacement parts for this transform. Each part is either a string or
--	format table for a capture. Format tables have 'index', 'method', 'if', and 'else' fields.
-- @field opts Regex options for this transform.
-- @field choice A list of options to insert from an autocompletion list for this placeholder.
-- @field id This placeholder's unique ID. This field is used as an indicator's value for
--	identification purposes.
-- @field position This placeholder's initial position in its snapshot. This field will not
--	update until the next snapshot is taken. Use `snippet:each_placeholder()` to determine
--	a placeholder's current position.
-- @field length This placeholder's initial length in its snapshot. This field will never
--	update. Use `buffer:indicator_end()` in conjunction with `snippet:each_placeholder()`
--	to determine a placeholder's current length.
-- @table placeholder
-- @local
local grammar = P{
	Ct((V('text') + V('variable') + V('code') + V('placeholder') + C(1))^0), --
	text = any_but('$`'), --
	variable = '$' * Ct(V('name') + '{' * V('name') * (V('format') + V('transform'))^-1 * '}'),
	name = Cg((R('AZ', 'az') + '_') * (R('AZ', 'az', '09') + '_')^0, 'variable'), --
	format = ':' * ('/' * Cg(R('az')^1, 'method') +
		('?' * Cg(any_but(':')^-1, 'if') * ':' * Cg(any_but('}')^-1, 'else')) +
		('+' * Cg(any_but('}')^-1, 'if')) + P('-')^-1 * Cg(any_but('}')^-1, 'else')),
	transform = '/' * V('regex') * '/' * V('repl') * '/' * V('opts') * Cg(Cc(true), 'transform'),
	regex = Cg(any_but('/')^-1, 'regex'),
	repl = Cg(Ct((any_but('/$') + ('$' * Ct(V('int') + '{' * V('int') * V('format')^-1 * '}')))^0),
		'repl'), --
	opts = Cg(R('az')^0, 'opts'), --
	code = V('lua') + V('shell'), lua = '```' * Ct(Cg(any_but('`'), 'lua')) * '```',
	shell = '`' * Ct(Cg(any_but('`'), 'shell')) * '`',
	placeholder = '$' * Ct((V('int') * Cg(Cc(true), 'simple') +
		('{' * V('int') * (V('default') + V('transform') + V('choice') + Cg(Cc(true), 'simple')) * '}'))),
	int = Cg(R('09')^1 / tonumber, 'index'),
	default = ':' * Cg(Ct((any_but('$`}') + V('placeholder') + V('code'))^0), 'default'),
	choice = '|' * Cg(any_but('|'), 'choice') * '|'
}

--- Creates and returns new snippet from text *text* and trigger text *trigger*.
-- @param text The new snippet to insert.
-- @param trigger The trigger text used to expand the snippet, if any.
-- @local
function snippet.new(text, trigger)
	local snip = setmetatable({
		trigger = trigger, original_sel_text = buffer:get_sel_text(),
		start_pos = buffer.selection_start - (trigger and #trigger or 0), index = 0, max_index = 0,
		snapshots = {[0] = {text = '', placeholders = {}}}
	}, snippet)

	-- Convert and match indentation.
	local lines = {}
	local indent = {[true] = '\t', [false] = string.rep(' ', buffer.tab_width)}
	local use_tabs = buffer.use_tabs
	for line in (text .. '\n'):gmatch('([^\r\n]*)\r?\n') do
		lines[#lines + 1] = line:gsub('^(%s*)', function(indentation)
			return indentation:gsub(indent[not use_tabs], indent[use_tabs])
		end)
	end
	if #lines > 1 then
		-- Match indentation on all lines after the first.
		local line = buffer:line_from_position(buffer.current_pos)
		local level = buffer.line_indentation[line] // buffer.tab_width
		local additional_indent = indent[use_tabs]:rep(level)
		for i = 2, #lines do lines[i] = additional_indent .. lines[i] end
	end
	text = table.concat(lines, ({[0] = '\r\n', '\r', '\n'})[buffer.eol_mode])

	-- Set variables.
	local line, pos = buffer:line_from_position(buffer.current_pos), buffer.current_pos
	local dir, name = (buffer.filename or ''):match('^(.-)([^/\\]*)$')
	snip.variables = {
		TM_SELECTED_TEXT = snip.original_sel_text, TM_CURRENT_LINE = buffer:get_cur_line(),
		TM_CURRENT_WORD = buffer:text_range(buffer:word_start_position(pos, true),
			buffer:word_end_position(pos, true)), TM_LINE_INDEX = tostring(line - 1),
		TM_LINE_NUMBER = tostring(line), TM_FILENAME = name,
		TM_FILENAME_BASE = name:gsub('%.[^.]+$', ''), TM_DIRECTORY = dir, TM_FILEPATH = buffer.filename
	}
	for name, value in pairs(M.variables) do
		snip.variables[name] = tostring(type(value) == 'function' and value() or value)
	end

	-- Parse snippet and add text and placeholders.
	for _, part in ipairs(grammar:match(text)) do snip:add_part(part) end

	return snip
end

--- Adds string, variable, interpolated shell or Lua code, or placeholder *part* to this snippet.
-- @param part The LPeg-generated part to add.
-- @local
function snippet:add_part(part)
	if type(part) == 'string' then
		self.snapshots[0].text = self.snapshots[0].text .. part
	elseif part.variable then
		self:add_part(part.transform and self:transform(part) or self.variables[part.variable] or '')
	elseif part.shell then
		-- Linux and macOS need a shell to expand environment variables in, so execute
		-- the shell code in a script.
		local tmpfile = not WIN32 and os.tmpname()
		if tmpfile then io.open(tmpfile, 'w'):write(part.shell):close() end
		local cmd, env_cmd = not WIN32 and 'sh ' .. tmpfile or part.shell, not WIN32 and 'env' or 'set'
		local env = {}
		for k, v in os.spawn(env_cmd):read('a'):gmatch('([^=]+)=([^\r\n]*)\r?\n') do env[k] = v end
		for k, v in pairs(self.variables) do env[k] = v end
		self:add_part(os.spawn(cmd, env):read('a'):match('^(.-)\r?\n?$')) -- omit trailing newline
		if tmpfile then os.remove(tmpfile) end
	elseif part.lua then
		local env = setmetatable({}, {__index = _G})
		for k, v in pairs(self.variables) do env[k] = v end
		local f, result = load('return ' .. part.lua, nil, 't', env)
		self:add_part(f and select(2, pcall(f)) or result or '')
	else
		local placeholder = setmetatable({}, {__index = part})
		self.max_index = math.max(self.max_index, placeholder.index)
		placeholder.id = #self.snapshots[0].placeholders + 1
		self.snapshots[0].placeholders[placeholder.id] = placeholder
		local position = #self.snapshots[0].text
		if placeholder.default then
			for _, part in ipairs(placeholder.default) do self:add_part(part) end
			placeholder.default = self.snapshots[0].text:sub(position + 1)
		else
			self:add_part(' ') -- fill empty placeholder for display
		end
		placeholder.position = self.start_pos + position -- absolute
		placeholder.length = #self.snapshots[0].text - position
	end
end

--- Provides dynamic field values and methods for this snippet.
-- @local
function snippet:__index(k)
	if k == 'end_pos' then
		local end_pos = buffer:indicator_end(INDIC_SNIPPET, self.start_pos)
		return end_pos > self.start_pos and end_pos or self.start_pos
	elseif k == 'placeholder_pos' then
		-- Normally the marker is one character behind the placeholder. However it will not exist
		-- at all if the placeholder is at the beginning of the snippet. Also account for the marker
		-- being at the beginning of the snippet. (If so, pos will point to the correct position.)
		local pos = buffer:indicator_end(INDIC_CURRENTPLACEHOLDER, self.start_pos)
		if pos == 1 then pos = self.start_pos end
		return buffer:indicator_all_on_for(pos) & 1 << INDIC_CURRENTPLACEHOLDER - 1 > 0 and pos + 1 or
			pos
	end
	return getmetatable(self)[k]
end

--- Inserts the current snapshot (based on `self.index`) of this snippet into the buffer and
-- marks placeholders.
-- @local
function snippet:insert()
	buffer:set_target_range(self.start_pos, self.end_pos)
	buffer:replace_target(self.snapshots[self.index].text)
	buffer.indicator_current = M.INDIC_PLACEHOLDER
	for id, placeholder in pairs(self.snapshots[self.index].placeholders) do
		buffer.indicator_value = id
		buffer:indicator_fill_range(placeholder.position, placeholder.length)
	end
end

--- Jumps to the next placeholder in this snippet and adds additional carets at mirrors.
-- @local
function snippet:next()
	if buffer:auto_c_active() then buffer:auto_c_complete() end

	-- Take a snapshot of the current state in order to restore it later if necessary.
	if self.index > 0 and self.start_pos < self.end_pos then
		local text = buffer:text_range(self.start_pos, self.end_pos)
		local phs = {}
		for pos, ph in self:each_placeholder() do
			-- Only the position and length of placeholders changes between snapshots; save it and
			-- keep all other existing properties.
			-- Note that nested placeholders will return the same placeholder id twice: once before
			-- a nested placeholder, and again after. (e.g. [foo[bar]baz] will will return the '[foo'
			-- and 'baz]' portions of the same placeholder.) Update the length on the second occurrence.
			if not phs[ph.id] then phs[ph.id] = setmetatable({position = pos}, {__index = ph}) end
			local length = buffer:indicator_end(M.INDIC_PLACEHOLDER, pos) - phs[ph.id].position
			if length > phs[ph.id].length then phs[ph.id].length = length end
		end
		self.snapshots[self.index] = {text = text, placeholders = phs}
	end
	self.index = self.index < self.max_index and self.index + 1 or 0

	-- Find the default placeholder, which may be the first mirror.
	local ph = select(2, self:each_placeholder(self.index, 'default')()) or
		select(2, self:each_placeholder(self.index, 'choice')()) or
		select(2, self:each_placeholder(self.index, 'simple')()) or
		(self.index == 0 and {position = self.end_pos, length = 0})
	if not ph then
		self:next() -- try next placeholder
		return
	end

	-- Mark the position of the placeholder so transforms can identify it.
	buffer.indicator_current = INDIC_CURRENTPLACEHOLDER
	buffer:indicator_clear_range(self.placeholder_pos - 1, 1)
	if ph.position > self.start_pos and self.index > 0 then
		-- Place it directly behind the placeholder so it will be preserved.
		buffer:indicator_fill_range(ph.position - 1, 1)
	end

	buffer:begin_undo_action()

	-- Go to the default placeholder and clear its marker.
	buffer:set_sel(ph.position, ph.position + ph.length)
	local e = buffer:indicator_end(M.INDIC_PLACEHOLDER, ph.position)
	buffer.indicator_current = M.INDIC_PLACEHOLDER
	buffer:indicator_clear_range(ph.position, e - ph.position)
	if not ph.default then buffer:replace_sel('') end -- delete filler ' '
	if ph.choice then
		buffer.auto_c_separator, buffer.auto_c_order = string.byte(','), buffer.ORDER_CUSTOM
		buffer:auto_c_show(0, ph.choice)
	end

	-- Add additional carets at mirrors and clear their markers.
	local text = ph.default or ''
	::redo::
	for pos in self:each_placeholder(self.index, 'simple') do
		e = buffer:indicator_end(M.INDIC_PLACEHOLDER, pos)
		buffer:indicator_clear_range(pos, e - pos)
		buffer:set_target_range(pos, pos + 1)
		buffer:replace_target(text)
		buffer:add_selection(pos, pos + #text)
		goto redo -- indicator positions have changed
	end
	buffer.main_selection = 1

	-- Update transforms.
	self:update_transforms()

	buffer:end_undo_action()

	if self.index == 0 then self:finish() end
end

--- Jumps to the previous placeholder in this snippet and restores the state associated with
-- that placeholder.
-- @local
function snippet:previous()
	if self.index < 2 then
		self:finish(true) -- cancel
		return
	end
	self.index = self.index - 2
	self:insert()
	self:next()
end

--- Finishes or cancels this snippet depending on boolean *canceling*.
-- The snippet cleans up after itself regardless.
-- @param canceling Whether or not to cancel inserting this snippet. When `true`, the buffer
--	is restored to its state prior to snippet expansion.
-- @local
function snippet:finish(canceling)
	local s, e = self.start_pos, self.end_pos
	if e ~= s then buffer:delete_range(e, 1) end -- clear initial padding space
	if not canceling then
		buffer.indicator_current = M.INDIC_PLACEHOLDER
		buffer:indicator_clear_range(s, e - s)
	else
		buffer:set_sel(s, e)
		buffer:replace_sel(self.trigger or self.original_sel_text)
	end
	self.finished = true
end

--- Returns a generator that returns each placeholder's position and state for all placeholders
-- in this snippet.
-- DO NOT modify the buffer while this generator is running. Doing so will affect the generator's
-- state and cause errors. Re-run the generator each time a buffer edit is made (e.g. via `goto`).
-- @param index Optional placeholder index to constrain results to.
-- @param type Optional placeholder type to constrain results to.
-- @local
function snippet:each_placeholder(index, type)
	local snapshot = self.snapshots[self.index > 0 and self.index - 1 or #self.snapshots]
	local i = self.start_pos
	return function()
		local s = buffer:indicator_end(M.INDIC_PLACEHOLDER, i)
		while s > 1 and s <= self.end_pos do
			if buffer:indicator_all_on_for(i) & 1 << M.INDIC_PLACEHOLDER - 1 > 0 then
				-- This next indicator comes directly after the previous one; adjust start and end
				-- positions to compensate.
				s, i = buffer:indicator_start(M.INDIC_PLACEHOLDER, i), s
			else
				i = buffer:indicator_end(M.INDIC_PLACEHOLDER, s)
			end
			local id = buffer:indicator_value_at(M.INDIC_PLACEHOLDER, s)
			local ph = snapshot.placeholders[id]
			if ph and (not index or ph.index == index) and (not type or ph[type]) then return s, ph end
			s = buffer:indicator_end(M.INDIC_PLACEHOLDER, i)
		end
	end
end

--- Returns the result of applying the transform in placeholder *placeholder* in the context
-- of this snippet.
-- @param placeholder The placeholder that contains the transform.
-- @local
function snippet:transform(placeholder)
	local text = not placeholder.variable and
		buffer:text_range(self.placeholder_pos, buffer.selection_end) or
		tostring(self.variables[placeholder.variable])
	return regex.gsub(text, string.format('(%s)', placeholder.regex), function(...)
		local repl, captures = {}, {...}
		for _, part in ipairs(placeholder.repl) do
			if type(part) == 'table' then
				local capture = captures[part.index + 1] -- $0 is captures[1]
				part = part.method and M.transform_methods[part.method](capture) or
					(capture ~= '' and (part['if'] or capture) or part['else'])
			end
			repl[#repl + 1] = part
		end
		return table.concat(repl)
	end, placeholder.opts:find('g') and 0 or 1)
end

--- Updates transforms in place based on the current placeholder's text.
-- @local
function snippet:update_transforms()
	buffer.indicator_current = M.INDIC_PLACEHOLDER
	local processed = {}
	::redo::
	for s, ph in self:each_placeholder(nil, 'transform') do
		if ph.index == self.index and not processed[ph] then
			-- Execute the code and replace any existing transform text.
			local result = self:transform(ph)
			if result == '' then result = ' ' end -- fill for display
			local id = buffer:indicator_value_at(M.INDIC_PLACEHOLDER, s)
			buffer:set_target_range(s, buffer:indicator_end(M.INDIC_PLACEHOLDER, s))
			buffer:replace_target(result)
			buffer.indicator_value = id
			buffer:indicator_fill_range(s, #result) -- re-mark
			processed[ph] = true
			goto redo -- indicator positions have changed
		elseif ph.index < self.index or self.index == 0 then
			-- Clear obsolete transforms, deleting filler text if necessary.
			local e = buffer:indicator_end(M.INDIC_PLACEHOLDER, s)
			buffer:indicator_clear_range(s, e - s)
			if buffer:text_range(s, e) == ' ' then
				buffer:delete_range(s, e - s) -- delete filler ' '
				goto redo
			end
		end
		-- TODO: insert initial transform for ph.index > self.index
	end
end

local active_snippet

--- The stack of currently running snippets.
local stack = {}

--- Inserts snippet text *text* or the snippet assigned to the trigger word behind the caret.
-- Otherwise, if a snippet is active, goes to the active snippet's next placeholder. Returns
-- `false` if no action was taken.
-- @param[opt] text Optional snippet text to insert. If `nil`, attempts to insert a new snippet
--	based on the trigger, the word behind caret, and the current lexer.
-- @return `false` if no action was taken; `nil` otherwise.
-- @see buffer.word_chars
function M.insert(text)
	local trigger
	if not assert_type(text, 'string/nil', 1) then
		trigger, text = find_snippet()
		if type(text) == 'table' then text = nil end -- assume lexer table and ignore
		if type(text) == 'function' then text = text() end
		assert_type(text, 'string/nil', trigger or '?')
	end
	if text then
		if active_snippet then stack[#stack + 1] = active_snippet end
		active_snippet = snippet.new(text, trigger)
		-- Insert the snippet into the buffer and mark its end position.
		buffer:begin_undo_action()
		buffer:set_target_range(active_snippet.start_pos, buffer.selection_end)
		buffer:replace_target('  ') -- placeholder for snippet text
		buffer.indicator_current = INDIC_SNIPPET
		buffer:indicator_fill_range(active_snippet.start_pos + 1, 1)
		active_snippet:insert() -- insert into placeholder
		buffer:end_undo_action()
	end
	if not active_snippet then return false end
	active_snippet:next()
	if active_snippet.finished then active_snippet = table.remove(stack) end
end

--- Jumps back to the previous snippet placeholder, reverting any changes from the current one.
-- Returns `false` if no snippet is active.
-- @return `false` if no snippet is active; `nil` otherwise.
function M.previous()
	if not active_snippet then return false end
	active_snippet:previous()
	if active_snippet.finished then active_snippet = table.remove(stack) end
end

--- Cancels the active snippet, removing all inserted text.
-- Returns `false` if no snippet is active.
-- @return `false` if no snippet is active; `nil` otherwise.
function M.cancel()
	if not active_snippet then return false end
	active_snippet:finish(true)
	active_snippet = table.remove(stack)
end

--- Prompts the user to select a snippet to insert from a list of global and language-specific
-- snippets.
function M.select()
	local all_snippets, items = {}, {}
	for trigger, snippet in pairs(select(2, find_snippet(true, true))) do
		all_snippets[#all_snippets + 1], all_snippets[trigger] = trigger, snippet
	end
	if #all_snippets == 0 then return end
	table.sort(all_snippets)
	for _, trigger in ipairs(all_snippets) do
		items[#items + 1], items[#items + 2] = trigger, all_snippets[trigger]
	end
	local i = ui.dialogs.list{
		title = _L['Select Snippet'], columns = {_L['Trigger'], _L['Snippet Text']}, items = items
	}
	if i then M.insert(items[i * 2]) end
end

--- Whether or not a snippet is active.
-- @field active

setmetatable(M,
	{__index = function(_, k) if k == 'active' then return active_snippet ~= nil end end})

-- Update snippet transforms when text is added or deleted.
events.connect(events.UPDATE_UI, function(updated)
	if not active_snippet then return end
	if updated & buffer.UPDATE_CONTENT > 0 then active_snippet:update_transforms() end
	if #keys.keychain == 0 then ui.statusbar_text = _L['Snippet active'] end
end)

events.connect(events.VIEW_NEW, function()
	view.indic_style[INDIC_SNIPPET] = view.INDIC_HIDDEN
	view.indic_style[INDIC_CURRENTPLACEHOLDER] = view.INDIC_HIDDEN
end)

--- Autocompleter function for snippet trigger words.
-- @see textadept.editing.autocomplete
-- @function _G.textadept.editing.autocompleters.snippet
textadept.editing.autocompleters.snippet = function()
	local list, trigger, snippets = {}, find_snippet(true)
	local sep = string.char(buffer.auto_c_type_separator)
	local xpm = textadept.editing.XPM_IMAGES.NAMESPACE
	for name in pairs(snippets) do list[#list + 1] = name .. sep .. xpm end
	return #trigger, list
end

return M

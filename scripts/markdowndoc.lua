-- Copyright 2007-2026 Mitchell. See LICENSE.

--- Markdown filter for LDoc.
-- @usage ldoc --filter markdowndoc.ldoc [ldoc opts] > api.md
-- @module markdowndoc
local M = {}

local TOC = '%d. [%s](#%s)\n'
local MODULE = '<a id="%s"></a>\n## The `%s` module\n'
local FIELD = '<a id="%s"></a>\n%s `%s`\n\n'
local FUNCTION = '<a id="%s"></a>\n%s `%s`(%s)\n\n'
local FUNCTION_NO_PARAMS = '<a id="%s"></a>\n%s `%s`()\n\n'
local DESCRIPTION = '%s\n\n'
local PARAM = '- *%s*: %s\n'
local USAGE = '```lua\n%s```\n'
local RETURN = '%s'
local SEE = '[`%s`](#%s)'
local TABLE = '<a id="%s"></a>\n%s `%s`\n\n'
local TFIELD = '- `%s`: %s\n'
local titles = {
	[PARAM] = 'Parameters:\n', [USAGE] = 'Usage:\n\n', [RETURN] = 'Returns: ', [SEE] = 'See also: ',
	[TFIELD] = 'Fields:\n'
}

-- Parse command line options for defining non-LDoc behavior.
local TITLE, single
for i = 1, #arg do
	local title = arg[i]:match('^%-%-title="?([^"]-)"?$')
	if title then TITLE = title:gsub('%p', '%%%0') end
	if arg[i] == '--single' then single = true end
	-- if arg[i] == '-d' then output_dir = arg[i + 1] end
end

--- Set of all known symbols that can be linked to.
-- Symbol names are mapped to `true` values.
-- This set must be populated after LDoc parses sources, but before writing anything.
local known_symbols = {}
--- Returns the given markdown with code spans linked to their symbols, if known.
-- @param md Markdown to auto-link symbols in.
local function link_known_symbols(md)
	return md:gsub('(`([%w_.:]+)%(?%)?`)', function(code, symbol)
		return known_symbols[symbol] and string.format('[%s](#%s)', code, symbol:gsub(':', '.')) or nil
	end)
end

--- Writes an LDoc description to a file.
-- @param f File to write to.
-- @param item LDoc item to describe.
-- @param name String name of the module the item belongs to. Used for headers in module
--	descriptions.
local function write_description(f, item, name)
	local description = item.summary
	if item.description ~= '' then description = description .. '\n' .. item.description end
	description = link_known_symbols(description):gsub('\n ', '\n') -- strip leading spaces
	f:write(string.format(DESCRIPTION, description))
end

--- Writes an LDoc hashmap to a file.
-- @param f File to write to.
-- @param fmt String format of a hashmap item.
-- @param hashmap LDoc hashmap to write.
local function write_hashmap(f, fmt, hashmap)
	if not hashmap or #hashmap == 0 then return end
	f:write(titles[fmt])
	for _, name in ipairs(hashmap) do
		local description = hashmap.map and hashmap.map[name] or hashmap[name] or ''
		if fmt == PARAM or fmt == TFIELD then description = link_known_symbols(description) end
		if fmt == PARAM then description = description:gsub('^%[opt%] ', '') end
		f:write(string.format(fmt, name, description))
	end
	f:write('\n')
end

--- Writes an LDoc list to a file.
-- @param f File to write to.
-- @param fmt String format of a list item.
-- @param list LDoc list to write.
-- @param name String name of the module the list belongs to. Used for @see.
local function write_list(f, fmt, list, name)
	if not list or #list == 0 then return end
	if type(list) == 'string' then list = {list} end
	f:write(titles[fmt])
	for i, value in ipairs(list) do
		if fmt == SEE and name ~= '_G' then
			if not value:find('%.') then
				-- Prepend module name to identifier if necessary.
				value = name .. '.' .. value
			else
				value = value:gsub('^_G%.', '') -- `_G` anchors do not have this prefix
			end
		end
		if fmt == RETURN then value = link_known_symbols(value) end
		f:write(string.format(fmt, value, value))
		if (fmt == SEE or fmt == RETURN) and i < #list then f:write(', ') end
	end
	if (fmt == SEE or fmt == RETURN) then f:write('\n') end
	f:write('\n')
end

--- Writes an LDoc item to a file.
-- @param f File to write to.
-- @param item LDoc item to write.
-- @param module_name String LDoc item's module name.
-- @function write
local write

--- Writes an LDoc field to a file.
-- @param f File to write to.
-- @param field LDoc field to write.
-- @param module_name String LDoc field's module name.
local function write_field(f, field, module_name)
	if not field.name:find('%.') and module_name ~= '_G' then
		field.name = module_name .. '.' .. field.name -- absolute name
	elseif field.name:find('^_G%.[^.]+%.[^.]+') then
		field.name = field.name:gsub('^_G%.', '') -- strip _G required for LDoc
	end
	local skip_constant =
		field.name:find('^buffer%.[A-Z_]+$') or field.name:find('^view%.[A-Z_]+$') or
			field.name:find('^lexer%.[A-Z_]+$')
	if not skip_constant then
		local level = module_name ~= 'buffer' and 3 or 4
		if single then level = level - 1 end
		f:write(string.format(FIELD, field.name:gsub('^_G%.', ''), string.rep('#', level), field.name))
		write_description(f, field)
		if field.usage then write_list(f, USAGE, table.concat(field.usage)) end
		write_list(f, SEE, field.tags.see, module_name)
	end
end

--- Writes an LDoc function to a file.
-- @param f File to write to.
-- @param func LDoc function to write.
-- @param module_name String LDoc function's module name.
local function write_function(f, func, module_name)
	if not func.name:find('[%.:]') and module_name ~= '_G' then
		func.name = module_name .. '.' .. func.name -- absolute name
	end
	local level = module_name ~= 'buffer' and 3 or 4
	if single then level = level - 1 end
	local args = func.args:sub(2, -2)
	args = args:gsub('[%w_]+', '*%0*') -- italicize args
	args = args:gsub('=[^[%]]+', function(default) return default:gsub('*', '') end) -- de-italicize
	f:write(string.format(FUNCTION, func.name:gsub(':', '.'), string.rep('#', level), func.name, args))
	write_description(f, func)
	write_hashmap(f, PARAM, func.params)
	write_list(f, RETURN, func.ret)
	if func.usage then write_list(f, USAGE, table.concat(func.usage)) end
	write_list(f, SEE, func.tags.see, module_name)
end

--- Writes an LDoc table to a file.
-- @param f File to write to.
-- @param tbl LDoc table to write.
-- @param module_name String LDoc table's module name.
local function write_table(f, tbl, module_name)
	if not tbl.name:find('%.') and module_name ~= '_G' then
		tbl.name = module_name .. '.' .. tbl.name -- absolute name
	else
		tbl.name = tbl.name:gsub('^_G%.', '') -- strip _G required for LDoc
	end
	local tbl_id = tbl.name ~= 'buffer' and tbl.name ~= 'view' and tbl.name ~= 'keys' and
		tbl.name:gsub('^_G.', '') or ('_G.' .. tbl.name)
	local level = module_name ~= 'buffer' and 3 or 4
	if single then level = level - 1 end
	f:write(string.format(TABLE, tbl_id, string.rep('#', level), tbl.name))
	write_description(f, tbl)
	write_hashmap(f, TFIELD, tbl.params)
	if tbl.usage then write_list(f, USAGE, table.concat(tbl.usage)) end
	write_list(f, SEE, tbl.tags.see, module_name)
end

--- Writes an LDoc module to a file.
-- @param f File to write to.
-- @param module LDoc module to write.
local function write_module(f, module)
	local name = module.name

	-- Write the header and description.
	if not single then
		f:write(string.format(MODULE, name, name))
		f:write('\n')
	end
	write_description(f, module, name)

	table.sort(module.items, function(a, b) return a.name < b.name end)
	for _, item in ipairs(module.items) do write(f, item, name) end
	f:write('\n')
end

--- Writes an LDoc section to a file.
-- @param f File to write to.
-- @param section LDoc section to write.
local function write_section(f, section)
	f:write('### ', section.display_name, '\n\n')
	if section.description:find('^%s*$') then return end
	local description = link_known_symbols(section.description):gsub('\n ', '\n') -- strip leading spaces
	f:write(description, '\n\n')
end

--- Writes an LDoc class module to a file.
-- @param f File to write to.
-- @param module LDoc class module to write.
local function write_classmod(f, module)
	local name = module.name

	-- Write the header and description.
	f:write(string.format(MODULE, name, name))
	write_description(f, module, name)

	-- Write the table of contents for the module's sections.
	for i, item in ipairs(module.sections) do
		local section = item.display_name
		f:write(string.format(TOC, i, section, section:gsub(' ', '-'):lower()))
	end
	f:write('\n')

	-- Write module items.
	local section
	for _, item in ipairs(module.items) do
		if item.section ~= section then
			section = item.section
			write(f, module.sections.by_name[section:gsub('[ %p]', '_')])
		end
		write(f, item, name)
	end
end

--- Map of LDoc item types to their writer functions.
local writers = {
	field = write_field, ['function'] = write_function, table = write_table, module = write_module,
	section = write_section, classmod = write_classmod
}
function write(f, item, module_name)
	writers[item.type](f, item, module_name)
end

--- Called by LDoc to process a doc object.
-- @param doc LDoc doc object to process.
function M.ldoc(doc)
	local f = io.stdout
	f:write(string.format('# %s\n\n', TITLE))

	table.sort(doc, function(a, b) return a.name < b.name end)

	-- Relocate '_G.' fields in modules to their target modules.
	for _, module in ipairs(doc) do
		local i = 1
		while i <= #module.items do
			local item, relocated = module.items[i], false
			if item.name:find('^_G%.[^.]+') and module.name ~= '_G' then
				local target_module = item.name:match('^_G.(.-)%.[^.]+$') or '_G'
				for _, module2 in ipairs(doc) do
					if module2.name == target_module then
						item.name = item.name:gsub('^_G%.[^.]+%.', ''):gsub('^_G%.', '')
						module2.items[#module2.items + 1] = item
						table.remove(module.items, i)
						relocated = true
						break
					elseif module2.name == target_module:match('^(.+)%.[^.]+$') then
						local target_item = target_module:match('[^.]+$')
						for _, item2 in ipairs(module2.items) do
							if item2.name == target_item then
								item2.params[#item2.params + 1] = item.name:match('[^.]+$')
								item2.params.map[item.name:match('[^.]+$')] = item.summary .. item.description
								table.remove(module.items, i)
								relocated = true
							end
						end
					end
				end
				if not relocated then print('[WARN] Could not find target module for ' .. item.name) end
			end
			if not relocated then i = i + 1 end
		end
	end

	-- Populate `known_symbols`, but skip some buffer/view/lexer field constants.
	for _, module in ipairs(doc) do
		known_symbols[module.name] = true
		for _, item in ipairs(module.items) do
			local skip_constant = item.name:find('buffer.[A-Z]+') or item.name:find('view.[A-Z]+') or
				(module.name == 'lexer' and item.name:find('^[A-Z]+'))
			if skip_constant then goto continue end
			if item.name == 'buffer:new' then item.name = 'buffer.new' end -- fix
			known_symbols[not item.name:find('[.:]') and module.name ~= '_G' and module.name .. '.' ..
				item.name or item.name] = true
			::continue::
		end
	end

	-- Create the table of contents.
	if #doc > 1 then
		for i, module in ipairs(doc) do
			local anchor = module.name
			if anchor == 'buffer' or anchor == 'keys' or anchor == 'view' then
				-- Jekyll auto-creates id tags for headers, so ensure TOC buffer and view links go to their
				-- modules instead of _G.buffer, _G.keys, and _G.view.
				anchor = 'the-' .. anchor .. '-module'
			end
			f:write(string.format(TOC, i, module.name, anchor))
		end
		f:write('\n')
	end

	-- Loop over modules, writing the Markdown document (to stdout).
	for _, module in ipairs(doc) do
		write(f, module, module.name)
		f:write('\n')
	end
end

return M

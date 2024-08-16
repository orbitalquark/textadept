#!/usr/bin/lua
-- Copyright 2024 Mitchell. See LICENSE.

-- Outputs an actionable code coverage list from a luacov report.
-- Usage: gen_cov.lua [format] luacov.report.out
-- Format is optional and may be one of: github

if not arg[2] then arg[1], arg[2] = '', arg[1] end

local format = arg[1] or ''

local print_headers = {
	[''] = function() end,
	-- Prints a GitHub Markdown table header.
	github = function()
		print('Code Coverage')
		print('| File | Hits | Missed | Coverage | Uncovered Lines |')
		print('|---|---|---|---|---|')
	end
}

--- Returns an iterator for each range of uncovered lines.
-- The first value returned by the iterator is the start line. If the range spans more than
-- one line, the second value returned is the end line. Otherwise, it is nil.
-- @param uncovered_lines List of uncovered line numbers for a given file.
-- @usage for s, e in ranges(uncovered[filename]) do ... end
local function ranges(uncovered_lines)
	return coroutine.wrap(function()
		local i = 1
		while i < #uncovered_lines do
			local s = uncovered_lines[i]
			local e = s
			while uncovered_lines[i + 1] == e + 1 do e, i = e + 1, i + 1 end
			coroutine.yield(s, e > s and e or nil)
			i = i + 1
		end
	end)
end

local print_summaries = {
	-- Prints a set of warning lines that Textadept can jump to.
	[''] = function(filename, hits, missed, percent, uncovered_lines)
		local relative_filename = filename:match('textadept/(.+)$')
		print(string.format('%s: %s (%s lines missed)', relative_filename, percent, missed))
		for s, e in ranges(uncovered_lines) do
			local warning = 'warning: no coverage'
			if e then warning = warning .. ' through line ' .. e end
			print(string.format('%s:%d: %s', filename, s, warning))
		end
		print()
	end,
	-- Prints a GitHub Markdown table row with links to uncovered lines.
	github = function(filename, hits, missed, percent, uncovered_lines)
		if not link_list then link_list = {} end -- global
		local url = 'https://github.com/orbitalquark/textadept/blob/default'
		local function new_link(anchor)
			local link = string.format('[%d]: %s/%s', #link_list + 1, url, filename)
			if anchor then link = link .. anchor end
			link_list[#link_list + 1] = link
			return #link_list
		end
		local missed_lines = {}
		local filename = filename:match('textadept/(.+)$')
		for s, e in ranges(uncovered_lines) do
			local line, anchor = s, 'L' .. s
			if e then line, anchor = line .. '-' .. e, anchor .. '-L' .. e end
			missed_lines[#missed_lines + 1] = string.format('[%s][%d]', line, new_link(anchor))
		end
		print(string.format('| [%s][%d] | %s | %s | %s | %s |', filename, new_link(), hits, missed,
			percent, table.concat(missed_lines, ', ')))
	end
}

local print_footers = {
	[''] = function() end,
	--
	github = function()
		print()
		print(table.concat(link_list, '\n'))
	end
}

print_headers[format]()

local uncovered = {}
local filename, line_num
local reading = true
local summarizing = false
for line in io.lines(arg[2]) do
	if line:find('^/') then
		if not summarizing then
			filename = line
			line_num = 1
			uncovered[filename] = {}
			reading = false
		else
			local filename, hits, missed, percent = line:match('^(%S+)%s+(%d+)%s+(%d+)%s+([%d.]+%%)$')
			print_summaries[format](filename, hits, missed, percent, uncovered[filename])
		end
	elseif line:find('^=') then
		reading = not reading
	elseif reading then
		if line:find('^%*') then table.insert(uncovered[filename], line_num) end
		line_num = line_num + 1
	elseif line == 'Summary' then
		summarizing = true
	end
end

print_footers[format]()

#!/usr/bin/lua
-- Copyright 2024 Mitchell. See LICENSE.

-- Outputs an actionable code coverage list from LuaCov and Gcovr reports.
-- Requires luacov and gcovr to be installed.
-- Usage: gen_cov.lua [format] [textadept_home]
-- format is optional and may be one of:
--   - github: outputs markdown tables showing coverage with GitHub links to uncovered lines.
--   - otherwise outputs recognizable warnings to uncovered lines.
-- textadept_home is the path to Textadept's home directory, which should contain luacov.report.out
--	and *.gcno files.

if not arg[2] then arg[1], arg[2] = '', arg[1] end

local format = arg[1] or ''
local dir = arg[2] or '..'

local f = io.popen('realpath ' .. dir)
dir = f:read()
f:close()

local print_headers = {
	[''] = function() end,
	-- Prints a GitHub Markdown table header.
	github = function()
		print()
		print('Code Coverage')
		print('| File | Coverage | Missed Lines |')
		print('|---|---|---|')
	end
}

--- Returns an iterator for each range of uncovered lines.
-- The first value returned by the iterator is the start line. If the range spans more than
-- one line, the second value returned is the end line. Otherwise, it is nil.
-- @param uncovered_lines List of uncovered line numbers for a given file.
-- @usage for s, e in ranges(uncovered[filename]) do ... end
local function ranges(uncovered_lines)
	return coroutine.wrap(function()
		if not uncovered_lines then return end -- total
		if type(uncovered_lines) == 'table' then
			local i = 1
			while i <= #uncovered_lines do
				local s = uncovered_lines[i]
				local e = s
				while uncovered_lines[i + 1] == e + 1 do e, i = e + 1, i + 1 end
				coroutine.yield(s, e > s and e or nil)
				i = i + 1
			end
		elseif type(uncovered_lines) == 'string' then
			for range in uncovered_lines:gmatch('[^,]+') do
				local s, e = range:match('^(%d+)%-?(%d*)$')
				coroutine.yield(tonumber(s), tonumber(e))
			end
		end
	end)
end

local print_summaries = {
	-- Prints a set of warning lines that Textadept can jump to.
	[''] = function(filename, hits, missed, percent, uncovered_lines)
		local relative_filename = filename:sub(#dir + 2)
		if relative_filename == '' then return end -- total
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
		if filename:find('^/') then filename = filename:sub(#dir + 2) end
		--- Creates a new link to this file and returns its reference number.
		-- @param[opt] anchor Optional link anchor (e.g. line number).
		local function new_link(anchor)
			local link = string.format('[%d]: %s/%s', #link_list + (link_list.offset or 0) + 1, url,
				filename)
			if anchor then link = link .. '#' .. anchor end
			link_list[#link_list + 1] = link
			return #link_list + (link_list.offset or 0)
		end
		local missed_lines = {}
		for s, e in ranges(uncovered_lines) do
			local line, anchor = s, 'L' .. s
			if e then line, anchor = line .. '-' .. e, anchor .. '-L' .. e end
			missed_lines[#missed_lines + 1] = string.format('[%s][%d]', line, new_link(anchor))
		end
		print(string.format('| %s | %s | %s |', filename, percent, table.concat(missed_lines, ', ')))
	end
}

local print_footers = {
	[''] = function() end,
	--
	github = function()
		print()
		print(table.concat(link_list, '\n'))
		link_list = {offset = #link_list}
	end
}

-- LuaCov.

print_headers[format]()

local uncovered = {}
local filename, line_num
local reading = true
local summarizing = false
for line in io.lines(dir .. '/luacov.report.out') do
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
	elseif line:find('^=') and not summarizing then
		reading = not reading
	elseif reading then
		if line:find('^%*') then table.insert(uncovered[filename], line_num) end
		line_num = line_num + 1
	elseif line == 'Summary' then
		summarizing = true
		reading = false
	elseif line:find('^Total') then
		local total, hits, missed, percent = line:match('^(%S+)%s+(%d+)%s+(%d+)%s+([%d.]+%%)$')
		print_summaries[format](total, hits, missed, percent)
	end
end

print_footers[format]()

-- Gcovr.

print_headers[format]()

local f<close> = io.popen('gcovr -r ' .. dir .. ' --txt')
for line in f:lines() do
	if line:find('^src') then
		local filename, lines, hits, percent, missing = line:match(
			'^(%S+)%s+(%d+)%s+(%d+)%s+(%d+%%)%s*(%S*)$')
		filename = dir .. '/' .. filename
		print_summaries[format](filename, hits, lines - hits, percent, missing)
	elseif line:find('^TOTAL') then
		local total, lines, hits, percent = line:match('^(%S+)%s+(%d+)%s+(%d+)%s+(%d+%%)$')
		print_summaries[format](total, hits, lines - hits, percent)
	end
end

print_footers[format]()

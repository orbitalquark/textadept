#!/usr/bin/env lua

-- Generates a code count plot by iterating over tagged revisions and running cloc.
-- Requires cloc, graph-cli (https://github.com/orbitalquark/graph-cli), and pngcrush.
-- Note: `pip install graph-cli` and replace its files with the above repo's changes.

local lfs = require('lfs')

local repo = io.popen('git rev-parse --show-toplevel'):read()

local dir = os.tmpname()
os.remove(dir)
lfs.mkdir(dir)
local _<close> = setmetatable({}, {__close = function() os.execute('rm -rf ' .. dir) end})

os.execute(string.format('git clone %s %s', repo, dir))

lfs.chdir(dir)

local counts, langs = {}, {}

local function count(tag)
	if tag == 'textadept_nightly' then return end

	print('Counting ' .. tag)
	os.execute('git checkout -q ' .. tag)
	local time = io.popen('git show -s --format=%at'):read()

	counts[#counts + 1], counts[time] = time, {}
	local sum_code, sum_comments, sum_blanks = 0, 0, 0

	local other_uis = 'textadept_(curses|gtk)'
	if not lfs.attributes(dir .. '/src/textadept_qt.cpp') then other_uis = 'textadept_curses' end
	local cmd = string.format([[
		cloc --force-lang=C,h --include-lang=C,Lua,make,C++,CMake --quiet --csv \
		--exclude-dir=doc,docs,scripts,themes,test,.github \
		--not-match-f="adeptsensedoc|tadoc|%s|_test" .]], other_uis)
	for line in io.popen(cmd):lines() do
		local fields = {}
		for field in line:gmatch('[^,]+') do fields[#fields + 1] = field end
		local lang, blanks, comments, code = fields[2], tonumber(fields[3]), tonumber(fields[4]),
			tonumber(fields[5])
		if lang == 'language' or lang == 'SUM' then goto continue end
		if not langs[lang] then langs[#langs + 1], langs[lang] = lang, true end
		counts[time][lang] = code
		sum_code = sum_code + code
		sum_comments = sum_comments + comments
		sum_blanks = sum_blanks + blanks
		::continue::
	end

	counts[time].sum = {sum_code, sum_comments, sum_blanks}
end

for tag in io.popen('git tag --sort=authordate'):lines() do count(tag) end
count('default') -- latest commit
table.sort(langs)

local csv_file = os.tmpname()
local _<close> = setmetatable({}, {__close = function() os.remove(csv_file) end})
local csv = io.open(csv_file, 'wb')
print('Writing CSV to ' .. csv_file)

csv:write('Lines,')
for _, lang in ipairs(langs) do csv:write(lang, ',') end
csv:write('Total,Comments\n')

for _, time in ipairs(counts) do
	csv:write(time, ',')
	for _, lang in ipairs(langs) do csv:write(counts[time][lang] or '', ',') end
	csv:write(counts[time].sum[1], ',', counts[time].sum[2], '\n')
end

csv:close()

print('Plotting')

local start_day = counts[1] / (60 * 60 * 24)
local end_day = counts[#counts] / (60 * 60 * 24)
local styles = {}
for i = 1, #langs do styles[i] = '-' end
styles[#styles + 1] = ':' -- code
styles[#styles + 1] = ':' -- comments

local png = repo .. '/docs/assets/images/loc.png'
cmd = table.concat({
	string.format('graph %s -o %s', csv_file, png), --
	'--figsize 900x325', --
	'--fontsize 10', --
	'-X "" -Y "" -T "Code Line Counts"', --
	'-f epoch -F "%Y %b"', --
	string.format('--xrange="%f:%f" --yrange=0:8600', start_day, end_day),
	string.format('-m "" -w 1 --style="%s"', table.concat(styles, ',')), --
	'--legend-ncols=' .. #langs + 2, --
	'--transparent-bg', --
	'2&>1'
}, ' ')
print(cmd)

-- Note: write to a shell script and execute it since os.execute() with such a complex command
-- line string causes trouble.
local sh = os.tmpname()
io.open(sh, 'wb'):write(cmd):close()
os.execute('sh "' .. sh .. '"')
os.remove(sh)

os.execute('pngcrush -ow ' .. png) -- compress result

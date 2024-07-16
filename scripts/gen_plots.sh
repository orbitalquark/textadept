#!/bin/bash

# Generates code count plots by iterating over tagged revisions and running cloc.
# Requires cloc and gnuplot.

# Output images.
loc="`hg root`/docs/images/loc.png"
languages="`hg root`/docs/images/languages.png"

# Clone a temporary repository and generate code count data for gnuplot to plot.
tmp=/tmp/count
hg clone `hg root` $tmp && pushd $tmp || exit 1
plotfile=gnuplot.dat
for rev in `hg tags | awk "{print $2}" | cut -d: -f1 | tac`; do
	date=`hg log -r $rev | grep ^date | cut -d: -f2- | tr + - | cut -d- -f1`
	hg update -r $rev -q
	timestamp=`date -d "$date" "+%s"`
	if [[ -f $tmp/src/textadept_qt.cpp ]]; then
		other_platforms="textadept_(curses|gtk)"
	else
		other_platforms="textadept_curses"
	fi
	counts=`cloc --force-lang=C,h --include-lang=C,Lua,make,C++,CMake --quiet --csv \
		--exclude-dir=doc,docs,scripts,themes,test,.github \
		--not-match-f="adeptsensedoc|tadoc|$other_platforms|_test" . | \
		tail -n +3 | head -n -1 | cut -d, -f2- | sort | tr '\n' ,`
	echo $timestamp,$counts
done | lua -e "
	-- Filter counts from cloc into a data format readable by gnuplot.
	-- Input is of the form:
	--  timestamp1,lang1,blanks1,comments1,code2,lang2,blanks2,comments2,code2,...
	--  timestamp2,lang1,blanks1,comments1,code2,lang2,blanks2,comments2,code2,...
	-- Output is of the form:
	--  Lang1
	--  Time Blanks Comments Code
	--  ts1  bl1    cm1      co1
	--  ts2  bl2    cm2      co2
	--  ...
	--
	--
	--  Lang2
	--  Time Blanks Comments Code
	--  ts1  bl1    cm1      co1
	--  ts2  bl2    cm2      co2
	--  ...

	-- Read in counts.
	local counts, langs = {}, {}
	for line in io.lines() do
		local time, data = line:match('^(%d+),(.+)$')
		if counts[time] then goto continue end
		counts[#counts + 1], counts[time] = time, {}
		for lang, data in data:gmatch('([^,]+),([^,]+,[^,]+,[^,]+)') do
			lang = lang:match('%S+$')
			if not langs[lang] then langs[#langs + 1], langs[lang] = lang, true end
			counts[time][lang] = data
		end
		::continue::
	end
	table.sort(langs)
	-- Output a data series for each language counted.
	for i = 1, #langs do
		print(langs[i])
		print('Time', 'Blanks', 'Comments', 'Code')
		for j = 1, #counts do
			local data = (counts[counts[j]][langs[i]] or '0,0,0'):gsub(',', '\t')
			print(counts[j], data)
		end
		print('\n') -- double-newline needed to delimit gnuplot data series
	end
	-- Output a data series for code, comments, and blanks counted.
	for i = 1, #counts do
		local sum_code, sum_comments, sum_blanks = 0, 0, 0
		for j = 1, #langs do
			local data = counts[counts[i]][langs[j]] or '0,0,0'
			local blanks, comments, code = data:match('([^,]+),([^,]+),([^,]+)')
			sum_code = sum_code + tonumber(code)
			sum_comments = sum_comments + tonumber(comments)
			sum_blanks = sum_blanks + tonumber(blanks)
		end
		counts[counts[i]] = {sum_code, sum_comments, sum_blanks}
	end
	for i, measure in ipairs{'Code', 'Comments', 'Blanks'} do
		print(measure)
		print('Time', measure)
		for j = 1, #counts do print(counts[j], counts[counts[j]][i]) end
		print('\n') -- double-newline needed to delimit gnuplot data series
	end
" > $plotfile
nlangs=$((`grep ^Time $plotfile | wc -l` - 3)) # ignore blanks, comments, code

# Define gnuplot plot settings and plot commands.
plotcmd=gnuplot.plt
echo "
	set term png transparent font 'Ubuntu,10' size 450,275;
	set border linewidth 1.5;
	set style line 1 linecolor rgb '#999900' linewidth 2;
	set style line 2 linecolor rgb '#0066cc' linewidth 2;
	set style line 3 linecolor rgb '#990000' linewidth 2;
	set style line 4 linecolor rgb '#009900' linewidth 2;
	set style line 5 linecolor rgb '#990099' linewidth 2;
	set grid linecolor rgb '#cccccc' linetype 1;
	set tics scale 0;
	set key left top horizontal Left reverse samplen 1;
	set xdata time; set timefmt '%s'; set format x \"%Y\n%b\";
	set autoscale xfix;

	set title 'Code Summary'
	set output '$loc'
	plot for [i=0:2] '$plotfile' index $nlangs+i using 1:2 with lines title columnhead(1) linestyle i+1
	set title 'Code Line Counts'
	set output '$languages'
	plot for [i=0:$nlangs-1] '$plotfile' index i using 1:4 with lines title columnhead(1) linestyle i+1
" > $plotcmd

# Invoke gnuplot.
gnuplot $plotcmd

# Cleanup.
popd && rm -r $tmp

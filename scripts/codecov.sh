#!/bin/sh
# Runs the specified tests and shows overall C/C++ and Lua code coverage.

delete_previous_coverage=
tests="-locale,-buffer_view_usage"

cd ..
export TEXTADEPT_HOME=`pwd`
if [[ ! -z "$delete_previous_coverage" ]]; then
  find build -name "*.gcda" -delete
  rm luacov.*.out
fi
cmake build -D PROFILE=1
cmake --build build -j
sed -i 's/^-- for/for/;' core/init.lua
xterm -e build/textadept -n -t $tests -e 'events.connect(events.INITIALIZED, os.exit)'
#xterm -e build/textadept-gtk -n -f -t $tests -e 'events.connect(events.INITIALIZED, os.exit)'
xterm -e build/textadept-curses -n -t $tests -e 'events.connect(events.INITIALIZED, os.exit)'
sed -i 's/^for/-- for/;' core/init.lua
find build -name "*.gcno" | xargs gcov -t | build/textadept -n luacov.report.out -
cmake build -U PROFILE
cmake --build build -j

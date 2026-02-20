-- Copyright 2025-2026 Mitchell. See LICENSE.

--- Extends Lua's `table` library to provide more utility functions.
-- @module table

--- Applies a map function to a list's items and returns a new table with the results.
-- @param t Table to map. It may have an `n` field for its length.
-- @param f Mapping function. The first parameter passed will be a value in *t*.
-- @param[opt] ... Additional values to pass to *f*.
function table.map(t, f, ...)
	local t2 = {}
	for i = 1, t.n or #t do t2[i] = f(t[i], ...) end
	return t2
end

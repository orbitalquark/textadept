-- Copyright 2007-2024 Mitchell. See LICENSE.

--- Map of all messages used by Textadept to their localized form.
-- If the localized version of a given message does not exist, the non-localized message is
-- returned. Use `rawget()` to check if a localization exists.
-- Note: the terminal version ignores any "_" or "&" mnemonics the GUI version would use.
-- @module _L
local M = {}

local f = io.open(_USERHOME .. '/locale.conf', 'rb')
if not f then
	local lang = (os.getenv('LANG') or ''):match('^[^_.@]+') -- TODO: LC_MESSAGES?
	if lang then f = io.open(string.format('%s/core/locales/locale.%s.conf', _HOME, lang)) end
end
if not f then f = io.open(_HOME .. '/core/locale.conf', 'rb') end
assert(f, '"core/locale.conf" not found')
for line in f:lines() do
	-- Any line that starts with a non-word character except '[' is considered a comment.
	if not line:find('^%s*[%w_%[]') then goto continue end
	local id, str = line:match('^(.-)%s*=%s*(.-)\r?$')
	if id and str and assert(not M[id], 'duplicate locale key "%s"', id) then
		M[id] = GTK and str or str:gsub('_', QT and '&' or '')
	end
	::continue::
end
f:close()

setmetatable(M, {__index = function(_, k) return k end})
if QT then getmetatable(M).__newindex = function(t, k, v) rawset(t, k, v:gsub('_', '&')) end end
return M

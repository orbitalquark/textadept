-- Copyright 2007-2025 Mitchell. See LICENSE.

--- Map of all messages used by Textadept to their localized forms.
-- If the localized form of a given message does not exist, the non-localized message is
-- returned. Use Lua's `rawget()` to check if a localization exists.
--
-- Terminal version note: any "_" or "&" mnemonics the GUI version would use are ignored.
-- @module _L
local M = {}

local files = {_USERHOME .. '/locale.conf'}
local locale, lang = (os.getenv('LANG') or ''):match('^(([^_.@]+)_?[^.@]*)')
if locale then
	files[#files + 1] = string.format('%s/core/locales/locale.%s.conf', _HOME, locale)
	files[#files + 1] = string.format('%s/core/locales/locale.%s.conf', _HOME, lang)
end
files[#files + 1] = _HOME .. '/core/locale.conf'

for _, locale_file in ipairs(files) do
	if not lfs.attributes(locale_file) then goto continue end
	for line in io.lines(locale_file) do
		-- Localization entries must start with a word or '['.
		local id, str = line:match('^([%w_%[].-)%s*=%s*(.-)\r?$')
		if id then
			assert(not M[id], 'duplicate locale key: %s', id)
			M[id] = GTK and str or str:gsub('_', QT and '&' or '')
		end
	end
	break
	::continue::
end

return setmetatable(M, {
	__index = function(_, k) return k end,
	__newindex = QT and function(t, k, v) rawset(t, k, v:gsub('_', '&')) end or nil
})

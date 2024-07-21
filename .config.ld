file = {
	'lexers/lexer.lua',
	'core/args.lua', 'core/assert.lua', 'core/.buffer.luadoc', 'core/events.lua', 'core/file_io.lua',
	'core/.iconv.luadoc', 'core/init.lua', 'core/keys.lua', 'core/lexer.lua', 'core/lfs_ext.lua',
	'core/locale.lua', 'core/.os.luadoc', 'core/ui.lua', 'core/.ui.dialogs.luadoc',
	'core/.view.luadoc',
	'modules/textadept',
}
merge = true
custom_see_handler('.+', function(ref) return ref, ref end)
convert_opt = true

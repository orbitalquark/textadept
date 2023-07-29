file = {'lexers/lexer.lua', 'core', 'modules/textadept'}
merge = true
custom_see_handler('.+', function(ref) return ref, ref end)
convert_opt = true

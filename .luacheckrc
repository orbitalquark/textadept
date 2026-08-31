allow_defined_top = true
codes = true
ignore = {'611'} -- line contains only whitespace
std = 'lua54'
formatter = 'plain'
max_line_length = false
globals = {
	'_BUFFERS', '_CHARSET', '_COPYRIGHT', '_HOME', '_L', '_LEXERPATH', '_RELEASE', '_SCINTILLA',
	'_THEME', '_USERHOME', '_VIEWS', --
	'args', 'assert_type', 'buffer', 'events', --
	'io.close_all_buffers', 'io.detect_indentation', 'io.encodings', 'io.ensure_final_newline',
	'io.get_project_root', 'io.open_file', 'io.open_recent_file', 'io.quick_open',
	'io.quick_open_filters', 'io.quick_open_max', 'io.recent_files', 'io.save_all_files', --
	'keys', 'lexer', 'lfs', 'lpeg', 'move_buffer', 'OS', 'os.spawn', 'quit', 'regex', 'reset',
	'snippets', 'string.iconv', 'table.map', 'textadept', 'timeout', 'UI', 'ui', 'view'
}
include_files = {
	'init.lua', 'core/*.lua', 'modules/textadept/*.lua', --
	'modules/*/*.lua', 'modules/debugger/*/init*.lua'
}
exclude_files = {'**/dkjson.lua', 'modules/lsp/ldoc.lua'}
files["**/*_test.lua"].globals = {'expected_failure', 'retry', 'setup', 'skip', 'teardown', 'test'}

-- Copyright 2020 Mitchell mitchell.att.foicica.com. See LICENSE.

-- In the past, Scintilla used 0-based indices as opposed to Lua's 1-based
-- indices, so these conversions were needed. Now, they are vestigal.
local function LINE(i) return i end
local function POS(i) return i end
local function INDEX(i) return i end

local _tostring = tostring
-- Overloads tostring() to print more user-friendly output for `assert_equal()`.
function tostring(value)
  if type(value) == 'table' then
    return string.format('{%s}', table.concat(value, ', '))
  elseif type(value) == 'string' then
    return string.format('%q', value)
  else
    return _tostring(value)
  end
end

-- Asserts that values *v1* and *v2* are equal.
-- Tables are compared by value, not by reference.
function assert_equal(v1, v2)
  if v1 == v2 then return end
  if type(v1) == 'table' and type(v2) == 'table' then
    if #v1 == #v2 then
      for k, v in pairs(v1) do if v2[k] ~= v then goto continue end end
      for k, v in pairs(v2) do if v1[k] ~= v then goto continue end end
      return
    end
    ::continue::
    v1 = string.format('{%s}', table.concat(v1, ', '))
    v2 = string.format('{%s}', table.concat(v2, ', '))
  end
  error(string.format('%s ~= %s', v1, v2), 2)
end


-- Asserts that function *f* raises an error whose error message contains string
-- *expected_errmsg*.
-- @param f Function to call.
-- @param expected_errmsg String the error message should contain.
function assert_raises(f, expected_errmsg)
  local ok, errmsg = pcall(f)
  if ok then error('error expected', 2) end
  if expected_errmsg ~= errmsg and
     not tostring(errmsg):find(expected_errmsg, 1, true) then
    error(string.format(
      'error message %q expected, was %q', expected_errmsg, errmsg), 2)
  end
end

local expected_failures = {}
function expected_failure(f) expected_failures[f] = true end

--------------------------------------------------------------------------------

function test_assert()
  assert_equal(assert(true, 'okay'), true)
  assert_raises(function() assert(false, 'not okay') end, 'not okay')
  assert_raises(function() assert(false, 'not okay: %s', false) end, 'not okay: false')
  assert_raises(function() assert(false, 'not okay: %s') end, 'no value')
  assert_raises(function() assert(false, 1234) end, '1234')
  assert_raises(function() assert(false) end, 'assertion failed!')
end

function test_assert_types()
  function foo(bar, baz, quux)
    assert_type(bar, 'string', 1)
    assert_type(baz, 'boolean/nil', 2)
    assert_type(quux, 'string/table/nil', 3)
    return bar
  end
  assert_equal(foo('bar'), 'bar')
  assert_raises(function() foo(1) end, "bad argument #1 to 'foo' (string expected, got number")
  assert_raises(function() foo('bar', 'baz') end, "bad argument #2 to 'foo' (boolean/nil expected, got string")
  assert_raises(function() foo('bar', true, 1) end, "bad argument #3 to 'foo' (string/table/nil expected, got number")

  function foo(bar) assert_type(bar, string) end
  assert_raises(function() foo(1) end, "bad argument #2 to 'assert_type' (string expected, got table")
  function foo(bar) assert_type(bar, 'string') end
  assert_raises(function() foo(1) end, "bad argument #3 to 'assert_type' (value expected, got nil")
end

function test_events_basic()
  local emitted = false
  local event, handler = 'test_basic', function() emitted = true end
  events.connect(event, handler)
  events.emit(event)
  assert(emitted, 'event not emitted or handled')
  emitted = false
  events.disconnect(event, handler)
  events.emit(event)
  assert(not emitted, 'event still handled')

  assert_raises(function() events.connect(nil) end, 'string expected')
  assert_raises(function() events.connect(event, nil) end, 'function expected')
  assert_raises(function() events.connect(event, function() end, 'bar') end, 'number/nil expected')
  assert_raises(function() events.disconnect() end, 'expected, got nil')
  assert_raises(function() events.disconnect(event, nil) end, 'function expected')
  assert_raises(function() events.emit(nil) end, 'string expected')
end

function test_events_single_handle()
  local count = 0
  local event, handler = 'test_single_handle', function() count = count + 1 end
  events.connect(event, handler)
  events.connect(event, handler) -- should disconnect first
  events.emit(event)
  assert_equal(count, 1)
end

function test_events_insert()
  local foo = {}
  local event = 'test_insert'
  events.connect(event, function() foo[#foo + 1] = 2 end)
  events.connect(event, function() foo[#foo + 1] = 1 end, 1)
  events.emit(event)
  assert_equal(foo, {1, 2})
end

function test_events_short_circuit()
  local emitted = false
  local event = 'test_short_circuit'
  events.connect(event, function() return true end)
  events.connect(event, function() emitted = true end)
  assert_equal(events.emit(event), true)
  assert_equal(emitted, false)
end

function test_events_disconnect_during_handle()
  local foo = {}
  local event, handlers = 'test_disconnect_during_handle', {}
  for i = 1, 3 do
    handlers[i] = function()
      foo[#foo + 1] = i
      events.disconnect(event, handlers[i])
    end
    events.connect(event, handlers[i])
  end
  events.emit(event)
  assert_equal(foo, {1, 2, 3})
end

function test_events_error()
  local errmsg
  local event, handler = 'test_error', function(message)
    errmsg = message
    return false -- halt propagation
  end
  events.connect(events.ERROR, handler, 1)
  events.connect(event, function() error('foo') end)
  events.emit(event)
  events.disconnect(events.ERROR, handler)
  assert(errmsg:find('foo'), 'error handler did not run')
end

function test_events_value_passing()
  local event = 'test_value_passing'
  events.connect(event, function() return end)
  events.connect(event, function() return {1, 2, 3} end) -- halts propagation
  events.connect(event, function() return 'foo' end)
  assert_equal(events.emit(event), {1, 2, 3})
end

local locales = {}
-- Load localizations from *locale_conf* and return them in a table.
-- @param locale_conf String path to a local file to load.
local function load_locale(locale_conf)
  if locales[locale_conf] then return locales[locale_conf] end
  print(string.format('Loading locale "%s"', locale_conf))
  local L = {}
  for line in io.lines(locale_conf) do
    if not line:find('^%s*[^%w_%[]') then
      local id, str = line:match('^(.-)%s*=%s*(.+)$')
      if id and str and assert(not L[id], 'duplicate locale id "%s"', id) then
        L[id] = str
      end
    end
  end
  locales[locale_conf] = L
  return L
end

-- Looks for use of localization in the given Lua file and verifies that each
-- use is okay.
-- @param filename String filename of the Lua file to check.
-- @param L Table of localizations to read from.
local function check_localizations(filename, L)
  print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
  local count = 0
  for line in io.lines(filename) do
    for id in line:gmatch([=[_L%[['"]([^'"]+)['"]%]]=]) do
      assert(L[id], 'locale missing id "%s"', id)
      count = count + 1
    end
  end
  print(string.format('Checked %d localizations.', count))
end

local loaded_extra = {}
-- Records localization assignments in the given Lua file for use in subsequent
-- checks.
-- @param L Table of localizations to add to.
local function load_extra_localizations(filename, L)
  if loaded_extra[filename] then return end
  print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
  local count = 0
  for line in io.lines(filename) do
    if line:find('_L%b[]%s*=') then
      for id in line:gmatch([=[_L%[['"]([^'"]+)['"]%]%s*=]=]) do
        assert(not L[id], 'duplicate locale id "%s"', id)
        L[id], count = true, count + 1
      end
    end
  end
  loaded_extra[filename] = true
  print(string.format('Added %d localizations.', count))
end

local LOCALE_CONF = _HOME .. '/core/locale.conf'
local LOCALE_DIR = _HOME .. '/core/locales'

function test_locale_load()
  local L = load_locale(LOCALE_CONF)
  for locale_conf in lfs.walk(LOCALE_DIR) do
    local l = load_locale(locale_conf)
    for id in pairs(L) do assert(l[id], 'locale missing id "%s"', id) end
    for id in pairs(l) do assert(L[id], 'locale has extra id "%s"', id) end
  end
end

function test_locale_use_core()
  local L = load_locale(LOCALE_CONF)
  local ta_dirs = {'core', 'modules/ansi_c', 'modules/lua', 'modules/textadept'}
  for _, dir in ipairs(ta_dirs) do
    dir = _HOME .. '/' .. dir
    for filename in lfs.walk(dir, '.lua') do
      check_localizations(filename, L)
    end
  end
  check_localizations(_HOME .. '/init.lua', L)
end

function test_locale_use_extra()
  local L = load_locale(LOCALE_CONF)
  for filename in lfs.walk(_HOME, '.lua') do
    load_extra_localizations(filename, L)
  end
  for filename in lfs.walk(_HOME, '.lua') do
    check_localizations(filename, L)
  end
end

function test_locale_use_userhome()
  local L = load_locale(LOCALE_CONF)
  for filename in lfs.walk(_HOME, '.lua') do
    load_extra_localizations(filename, L)
  end
  for filename in lfs.walk(_USERHOME, '.lua') do
    load_extra_localizations(filename, L)
  end
  L['%1'] = true -- snippet
  for filename in lfs.walk(_USERHOME, '.lua') do
    check_localizations(filename, L)
  end
end

function test_file_io_open_file_detect_encoding()
  io.recent_files = {} -- clear
  local recent_files = {}
  local files = {
    [_HOME .. '/test/file_io/utf8'] = 'UTF-8',
    [_HOME .. '/test/file_io/cp1252'] = 'CP1252',
    [_HOME .. '/test/file_io/utf16'] = 'UTF-16',
    [_HOME .. '/test/file_io/binary'] = '',
  }
  for filename, encoding in pairs(files) do
    print(string.format('Opening file %s', filename))
    io.open_file(filename)
    assert_equal(buffer.filename, filename)
    local f = io.open(filename, 'rb')
    local contents = f:read('a')
    f:close()
    if encoding ~= '' then
      --assert_equal(buffer:get_text():iconv(encoding, 'UTF-8'), contents)
      assert_equal(buffer.encoding, encoding)
      assert_equal(buffer.code_page, buffer.CP_UTF8)
    else
      assert_equal(buffer:get_text(), contents)
      assert_equal(buffer.encoding, nil)
      assert_equal(buffer.code_page, 0)
    end
    buffer:close()
    table.insert(recent_files, 1, filename)
  end
  assert_equal(io.recent_files, recent_files)

  assert_raises(function() io.open_file(1) end, 'string/table/nil expected, got number')
  assert_raises(function() io.open_file('/tmp/foo', true) end, 'string/table/nil expected, got boolean')
  -- TODO: encoding failure
end

function test_file_io_open_file_detect_newlines()
  local files = {
    [_HOME .. '/test/file_io/lf'] = buffer.EOL_LF,
    [_HOME .. '/test/file_io/crlf'] = buffer.EOL_CRLF,
  }
  for filename, mode in pairs(files) do
    io.open_file(filename)
    assert_equal(buffer.eol_mode, mode)
    buffer:close()
  end
end

function test_file_io_open_file_with_encoding()
  local num_buffers = #_BUFFERS
  local files = {
    _HOME .. '/test/file_io/utf8',
    _HOME .. '/test/file_io/cp1252',
    _HOME .. '/test/file_io/utf16'
  }
  local encodings = {nil, 'CP1252', 'UTF-16'}
  io.open_file(files, encodings)
  assert_equal(#_BUFFERS, num_buffers + #files)
  for i = #files, 1, -1 do
    view:goto_buffer(_BUFFERS[num_buffers + i])
    assert_equal(buffer.filename, files[i])
    if encodings[i] then assert_equal(buffer.encoding, encodings[i]) end
    buffer:close()
  end
end

function test_file_io_open_file_already_open()
  local filename = _HOME .. '/test/file_io/utf8'
  io.open_file(filename)
  buffer.new()
  local num_buffers = #_BUFFERS
  io.open_file(filename)
  assert_equal(buffer.filename, filename)
  assert_equal(#_BUFFERS, num_buffers)
  view:goto_buffer(1)
  buffer:close() -- untitled
  buffer:close() -- filename
end

function test_file_io_open_file_interactive()
  local num_buffers = #_BUFFERS
  io.open_file()
  if #_BUFFERS > num_buffers then buffer:close() end
end

function test_file_io_open_file_errors()
  if LINUX then
    assert_raises(function() io.open_file('/etc/group-') end, 'cannot open /etc/group-: Permission denied')
  end
  -- TODO: find a case where the file can be opened, but not read
end

function test_file_io_reload_file()
  io.open_file(_HOME .. '/test/file_io/utf8')
  local pos = 10
  buffer:goto_pos(pos)
  local text = buffer:get_text()
  buffer:append_text('foo')
  assert(buffer:get_text() ~= text, 'buffer text is unchanged')
  buffer:reload()
  assert_equal(buffer:get_text(), text)
  assert_equal(buffer.current_pos, pos)
  buffer:close()
end

function test_file_io_set_encoding()
  io.open_file(_HOME .. '/test/file_io/utf8')
  local pos = 10
  buffer:goto_pos(pos)
  local text = buffer:get_text()
  buffer:set_encoding('CP1252')
  assert_equal(buffer.encoding, 'CP1252')
  assert_equal(buffer.code_page, buffer.CP_UTF8)
  assert_equal(buffer:get_text(), text) -- fundamentally the same
  assert_equal(buffer.current_pos, pos)
  buffer:reload()
  buffer:close()

  assert_raises(function() buffer:set_encoding(true) end, 'string/nil expected, got boolean')
end

function test_file_io_save_file()
  buffer.new()
  buffer._type = '[Foo Buffer]'
  buffer:append_text('foo')
  local filename = os.tmpname()
  buffer:save_as(filename)
  local f = assert(io.open(filename))
  local contents = f:read('a')
  f:close()
  assert_equal(buffer:get_text(), contents)
  assert(not buffer._type, 'still has a type')
  buffer:append_text('bar')
  io.save_all_files()
  f = assert(io.open(filename))
  contents = f:read('a')
  f:close()
  assert_equal(buffer:get_text(), contents)
  buffer:close()
  os.remove(filename)

  assert_raises(function() buffer:save_as(1) end, 'string/nil expected, got number')
end

function test_file_io_non_global_buffer_functions()
  local filename = os.tmpname()
  local buf = buffer.new()
  buf:append_text('foo')
  view:goto_buffer(-1)
  assert(buffer ~= buf, 'still in untitled buffer')
  assert_equal(buf:get_text(), 'foo')
  assert(buffer ~= buf, 'jumped to untitled buffer')
  buf:save_as(filename)
  assert(buffer ~= buf, 'jumped to untitled buffer')
  view:goto_buffer(1)
  assert(buffer == buf, 'not in saved buffer')
  assert_equal(buffer.filename, filename)
  assert(not buffer.modify, 'saved buffer still marked modified')
  local f = io.open(filename, 'rb')
  local contents = f:read('a')
  f:close()
  assert_equal(buffer:get_text(), contents)
  buffer:append_text('bar')
  view:goto_buffer(-1)
  assert(buffer ~= buf, 'still in saved buffer')
  buf:save()
  assert(buffer ~= buf, 'jumped to untitled buffer')
  f = io.open(filename, 'rb')
  contents = f:read('a')
  f:close()
  assert_equal(buf:get_text(), contents)
  buf:append_text('baz')
  assert_equal(buf:get_text(), contents .. 'baz')
  assert(buf.modify, 'buffer not marked modified')
  buf:reload()
  assert_equal(buf:get_text(), contents)
  assert(not buf.modify, 'buffer still marked modified')
  buf:append_text('baz')
  buf:close(true)
  assert(buffer ~= buf, 'closed the wrong buffer')
  os.remove(filename)
end

function test_file_io_file_detect_modified()
  local modified = false
  local handler = function(filename)
    assert_type(filename, 'string', 1)
    modified = true
    return false -- halt propagation
  end
  events.connect(events.FILE_CHANGED, handler, 1)
  local filename = os.tmpname()
  local f = assert(io.open(filename, 'w'))
  f:write('foo\n'):flush()
  io.open_file(filename)
  assert_equal(buffer:get_text(), 'foo\n')
  view:goto_buffer(-1)
  os.execute('sleep 1') -- filesystem mod time has 1-second granularity
  f:write('bar\n'):flush()
  view:goto_buffer(1)
  assert_equal(modified, true)
  buffer:close()
  f:close()
  os.remove(filename)
  events.disconnect(events.FILE_CHANGED, handler)
end

function test_file_io_file_detect_modified_interactive()
  local filename = os.tmpname()
  local f = assert(io.open(filename, 'w'))
  f:write('foo\n'):flush()
  io.open_file(filename)
  assert_equal(buffer:get_text(), 'foo\n')
  view:goto_buffer(-1)
  os.execute('sleep 1') -- filesystem mod time has 1-second granularity
  f:write('bar\n'):flush()
  view:goto_buffer(1)
  assert_equal(buffer:get_text(), 'foo\nbar\n')
  buffer:close()
  f:close()
  os.remove(filename)
end

function test_file_io_recent_files()
  io.recent_files = {} -- clear
  local recent_files = {}
  local files = {
    _HOME .. '/test/file_io/utf8',
    _HOME .. '/test/file_io/cp1252',
    _HOME .. '/test/file_io/utf16',
    _HOME .. '/test/file_io/binary'
  }
  for _, filename in ipairs(files) do
    io.open_file(filename)
    buffer:close()
    table.insert(recent_files, 1, filename)
  end
  assert_equal(io.recent_files, recent_files)
end

function test_file_io_open_recent_interactive()
  local filename = _HOME .. '/test/file_io/utf8'
  io.open_file(filename)
  buffer:close()
  io.open_recent_file()
  assert_equal(buffer.filename, filename)
  buffer:close()
end

function test_file_io_get_project_root()
  local cwd = lfs.currentdir()
  lfs.chdir(_HOME)
  assert_equal(io.get_project_root(), _HOME)
  lfs.chdir(cwd)
  assert_equal(io.get_project_root(_HOME), _HOME)
  assert_equal(io.get_project_root(_HOME .. '/core'), _HOME)
  assert_equal(io.get_project_root(_HOME .. '/core/init.lua'), _HOME)
  assert_equal(io.get_project_root('/tmp'), nil)

  assert_raises(function() io.get_project_root(1) end, 'string/nil expected, got number')
end

function test_file_io_quick_open_interactive()
  local num_buffers = #_BUFFERS
  local cwd = lfs.currentdir()
  local dir = _HOME .. '/core'
  lfs.chdir(dir)
  io.quick_open_filters[dir] = '.lua'
  io.quick_open(dir)
  if #_BUFFERS > num_buffers then
    assert(buffer.filename:find('%.lua$'), '.lua file filter did not work')
    buffer:close()
  end
  io.quick_open_filters[dir] = true
  assert_raises(function() io.quick_open(dir) end, 'string/table/nil expected, got boolean')
  io.quick_open_filters[_HOME] = '.lua'
  io.quick_open()
  if #_BUFFERS > num_buffers then
    assert(buffer.filename:find('%.lua$'), '.lua file filter did not work')
    buffer:close()
  end
  lfs.chdir(cwd)

  assert_raises(function() io.quick_open(1) end, 'string/table/nil expected, got number')
  assert_raises(function() io.quick_open(_HOME, true) end, 'string/table/nil expected, got boolean')
  assert_raises(function() io.quick_open(_HOME, nil, 1) end, 'table/nil expected, got number')
end

function test_keys_keychain()
  local ctrl_a = keys['ctrl+a']
  local foo = false
  keys['ctrl+a'] = {a = function() foo = true end}
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(not foo, 'foo set outside keychain')
  events.emit(events.KEYPRESS, string.byte('a'), false, true)
  assert_equal(#keys.keychain, 1)
  assert_equal(keys.keychain[1], 'ctrl+a')
  events.emit(events.KEYPRESS, not CURSES and 0xFF1B or 7) -- esc
  assert_equal(#keys.keychain, 0, 'keychain not canceled')
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(not foo, 'foo set outside keychain')
  events.emit(events.KEYPRESS, string.byte('a'), false, true)
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(foo, 'foo not set')
  keys['ctrl+a'] = ctrl_a -- restore
end

function test_keys_propagation()
  buffer:new()
  local foo, bar, baz = false, false, false
  keys.a = function() foo = true end
  keys.b = function() bar = true end
  keys.c = function() baz = true end
  keys.cpp = {
    a = function() end, -- halt
    b = function() return false end, -- propagate
    c = function()
      keys.mode = 'test_mode'
      return false -- propagate
    end
  }
  buffer:set_lexer('cpp')
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(not foo, 'foo set')
  events.emit(events.KEYPRESS, string.byte('b'))
  assert(bar, 'bar set')
  events.emit(events.KEYPRESS, string.byte('c'))
  assert(not baz, 'baz set') -- mode changed, so cannot propagate to keys.c
  assert_equal(keys.mode, 'test_mode')
  keys.mode = nil
  keys.a, keys.b, keys.c, keys.cpp = nil, nil, nil, nil -- reset
  buffer:close()
end

function test_keys_modes()
  buffer.new()
  local foo, bar = false, false
  keys.a = function() foo = true end
  keys.test_mode = {a = function()
    bar = true
    keys.mode = nil
    return false -- propagate
  end}
  keys.cpp = {a = function() keys.mode = 'test_mode' end}
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(foo, 'foo not set')
  assert(not keys.mode, 'key mode entered')
  assert(not bar, 'bar set outside mode')
  foo = false
  buffer:set_lexer('cpp')
  events.emit(events.KEYPRESS, string.byte('a'))
  assert_equal(keys.mode, 'test_mode')
  assert(not foo, 'foo set outside mode')
  assert(not bar, 'bar set outside mode')
  events.emit(events.KEYPRESS, string.byte('a'))
  assert(bar, 'bar not set')
  assert(not keys.mode, 'key mode still active')
  assert(not foo, 'foo set') -- TODO: should this propagate?
  keys.a, keys.test_mode, keys.cpp = nil, nil, nil -- reset
  buffer:close()
end

function test_lfs_ext_walk()
  local files, directories = 0, 0
  for filename in lfs.walk(_HOME .. '/core', nil, nil, true) do
    if not filename:find('/$') then
      files = files + 1
    else
      directories = directories + 1
    end
  end
  assert(files > 0, 'no files found')
  assert(directories > 0, 'no directories found')

  assert_raises(function() lfs.walk() end, 'string expected, got nil')
  assert_raises(function() lfs.walk(_HOME, 1) end, 'string/table/nil expected, got number')
  assert_raises(function() lfs.walk(_HOME, nil, true) end, 'number/nil expected, got boolean')
end

function test_lfs_ext_walk_filter_lua()
  local count = 0
  for filename in lfs.walk(_HOME .. '/core', '.lua') do
    assert(filename:find('%.lua$'), '"%s" not a Lua file', filename)
    count = count + 1
  end
  assert(count > 0, 'no Lua files found')
end

function test_lfs_ext_walk_filter_exclusive()
  local count = 0
  for filename in lfs.walk(_HOME .. '/core', '!.lua') do
    assert(not filename:find('%.lua$'), '"%s" is a Lua file', filename)
    count = count + 1
  end
  assert(count > 0, 'no non-Lua files found')
end

function test_lfs_ext_walk_filter_dir()
  local count = 0
  for filename in lfs.walk(_HOME, '/core') do
    assert(filename:find('/core/'), '"%s" is not in core/', filename)
    count = count + 1
  end
  assert(count > 0, 'no core files found')
end
expected_failure(test_lfs_ext_walk_filter_dir)

function test_lfs_ext_walk_filter_mixed()
  local count = 0
  for filename in lfs.walk(_HOME .. '/core', {'!/locales', '.lua'}) do
    assert(not filename:find('/locales/') and filename:find('%.lua$'), '"%s" should not match', filename)
    count = count + 1
  end
  assert(count > 0, 'no matching files found')
end

function test_lfs_ext_walk_max_depth()
  local count = 0
  for filename in lfs.walk(_HOME, '.lua', 0) do count = count + 1 end
  assert_equal(count, 1) -- init.lua
end

function test_lfs_ext_walk_halt()
  local count, count_at_halt = 0, 0
  for filename in lfs.walk(_HOME .. '/core') do
    count = count + 1
    if filename:find('/locales/.') then
      count_at_halt = count
      break
    end
  end
  assert_equal(count, count_at_halt)

  for filename in lfs.walk(_HOME .. '/core', nil, nil, true) do
    count = count + 1
    if filename:find('[/\\]$') then
      count_at_halt = count
      break
    end
  end
  assert_equal(count, count_at_halt)
end

function test_lfs_ext_walk_win32()
  local win32 = _G.WIN32
  _G.WIN32 = true
  local count = 0
  for filename in lfs.walk(_HOME, {'/core'}) do
    assert(not filename:find('/'), '"%s" has /', filename)
    if filename:find('\\core') then count = count + 1 end
  end
  assert(count > 0, 'no core files found')
  _G.WIN32 = win32 -- reset just in case
end

function test_lfs_ext_abs_path()
  assert_equal(lfs.abspath('bar', '/foo'), '/foo/bar')
  assert_equal(lfs.abspath('./bar', '/foo'), '/foo/bar')
  assert_equal(lfs.abspath('../bar', '/foo'), '/bar')
  assert_equal(lfs.abspath('/bar', '/foo'), '/bar')
  assert_equal(lfs.abspath('../../././baz', '/foo/bar'), '/baz')
  local win32 = _G.WIN32
  _G.WIN32 = true
  assert_equal(lfs.abspath('bar', 'C:\\foo'), 'C:\\foo\\bar')
  assert_equal(lfs.abspath('.\\bar', 'C:\\foo'), 'C:\\foo\\bar')
  assert_equal(lfs.abspath('..\\bar', 'C:\\foo'), 'C:\\bar')
  assert_equal(lfs.abspath('C:\\bar', 'C:\\foo'), 'C:\\bar')
  assert_equal(lfs.abspath('c:\\bar', 'c:\\foo'), 'C:\\bar')
  assert_equal(lfs.abspath('..\\../.\\./baz', 'C:\\foo\\bar'), 'C:\\baz')
  _G.WIN32 = win32 -- reset just in case

  assert_raises(function() lfs.abspath() end, 'string expected, got nil')
  assert_raises(function() lfs.abspath('foo', 1) end, 'string/nil expected, got number')
end

function test_ui_print()
  local tabs = ui.tabs
  local silent_print = ui.silent_print

  ui.tabs = true
  ui.silent_print = false
  ui.print('foo')
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert_equal(#_VIEWS, 1)
  assert_equal(buffer:get_text(), 'foo\n')
  assert(buffer:line_from_position(buffer.current_pos) > LINE(1), 'still on first line')
  ui.print('bar', 'baz')
  assert_equal(buffer:get_text(), 'foo\nbar\tbaz\n')
  buffer:close()

  ui.tabs = false
  ui.print(1, 2, 3)
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert_equal(#_VIEWS, 2)
  assert_equal(buffer:get_text(), '1\t2\t3\n')
  ui.goto_view(-1) -- first view
  assert(buffer._type ~= _L['[Message Buffer]'], 'still in message buffer')
  ui.print(4, 5, 6) -- should jump to second view
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert_equal(buffer:get_text(), '1\t2\t3\n4\t5\t6\n')
  ui.goto_view(-1) -- first view
  assert(buffer._type ~= _L['[Message Buffer]'], 'still in message buffer')
  ui.silent_print = true
  ui.print(7, 8, 9) -- should stay in first view
  assert(buffer._type ~= _L['[Message Buffer]'], 'switched to message buffer')
  assert_equal(_BUFFERS[#_BUFFERS]:get_text(), '1\t2\t3\n4\t5\t6\n7\t8\t9\n')
  ui.silent_print = false
  ui.goto_view(1) -- second view
  assert_equal(buffer._type, _L['[Message Buffer]'])
  view:goto_buffer(-1)
  assert(buffer._type ~= _L['[Message Buffer]'], 'message buffer still visible')
  ui.print()
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert_equal(buffer:get_text(), '1\t2\t3\n4\t5\t6\n7\t8\t9\n\n')
  view:unsplit()

  buffer:close()
  ui.tabs = tabs
  ui.silent_print = silent_print
end

function test_ui_dialogs_colorselect_interactive()
  local color = ui.dialogs.colorselect{title = 'Blue', color = 0xFF0000}
  assert_equal(color, 0xFF0000)
  color = ui.dialogs.colorselect{
    title = 'Red', color = '#FF0000', palette = {'#FF0000', 0x00FF00},
    string_output = true
  }
  assert_equal(color, '#FF0000')

  assert_raises(function() ui.dialogs.colorselect{title = function() end} end, "bad argument #title to 'colorselect' (string/number/table/boolean expected, got function")
  assert_raises(function() ui.dialogs.colorselect{palette = {true}} end, "bad argument #palette[1] to 'colorselect' (string/number expected, got boolean")
end

function test_ui_dialogs_dropdown_interactive()
  local dropdowns = {'dropdown', 'standard_dropdown'}
  for _, dropdown in ipairs(dropdowns) do
    print('Running ' .. dropdown)
    local button, i = ui.dialogs[dropdown]{items = {'foo', 'bar', 'baz'}}
    assert_equal(type(button), 'number')
    assert_equal(i, 1)
    button, i = ui.dialogs[dropdown]{
      text = 'foo', items = {'bar', 'baz', 'quux'}, select = 2,
      no_cancel = true, width = 400, height = 400
    }
    assert_equal(i, 2)
  end

  assert_raises(function() ui.dialogs.dropdown{items = {'foo', 'bar', 'baz'}, select = true} end, "bad argument #select to 'dropdown' (number expected, got boolean")
  assert_raises(function() ui.dialogs.dropdown{items = {'foo', 'bar', 'baz', true}} end, "bad argument #items[4] to 'dropdown' (string/number expected, got boolean")
end

function test_ui_dialogs_filesave_fileselect_interactive()
  local test_filename = _HOME .. '/test/ui/empty'
  local test_dir, test_file = test_filename:match('^(.+[/\\])([^/\\]+)$')
  local filename = ui.dialogs.filesave{
    with_directory = test_dir, with_file = test_file,
    no_create_directories = true
  }
  assert_equal(filename, test_filename)
  filename = ui.dialogs.fileselect{
    with_directory = test_dir, with_file = test_file, select_multiple = true
  }
  assert_equal(filename, {test_filename})
  filename = ui.dialogs.fileselect{
    with_directory = test_dir, select_only_directories = true
  }
  assert_equal(filename, test_dir:match('^(.+)/$'))
end

function test_ui_dialogs_filteredlist_interactive()
  local _, i = ui.dialogs.filteredlist{
    informative_text = 'foo', columns = '1', items = {'bar', 'baz', 'quux'},
    text = 'b z'
  }
  assert_equal(i, 2)
  local _, text = ui.dialogs.filteredlist{
    columns = {'1', '2'},
    items = {'foo', 'foobar', 'bar', 'barbaz', 'baz', 'bazfoo'},
    search_column = 2, text = 'baz', output_column = 2, string_output = true,
    select_multiple = true, button1 = _L['OK'], button2 = _L['Cancel'],
    button3 = 'Other', width = ui.size[1] / 2
  }
  assert_equal(text, {'barbaz'})
end

function test_ui_dialogs_fontselect_interactive()
  local font = ui.dialogs.fontselect{
    font_name = 'Monospace', font_size = 14, font_style = 'Bold'
  }
  assert_equal(font, 'Monospace Bold 14')
end

function test_ui_dialogs_inputbox_interactive()
  local inputboxes = {
    'inputbox', 'secure_inputbox', 'standard_inputbox',
    'secure_standard_inputbox'
  }
  for _, inputbox in ipairs(inputboxes) do
    print('Running ' .. inputbox)
    local button, text = ui.dialogs[inputbox]{text = 'foo'}
    assert_equal(type(button), 'number')
    assert_equal(text, 'foo')
    button, text = ui.dialogs[inputbox]{
      text = 'foo', string_output = true, no_cancel = true
    }
    assert_equal(type(button), 'string')
    assert_equal(text, 'foo')
  end

  local button, text = ui.dialogs.inputbox{
    informative_text = {'info', 'foo', 'baz'}, text = {'bar', 'quux'}
  }
  assert_equal(type(button), 'number')
  assert_equal(text, {'bar', 'quux'})
  button = ui.dialogs.inputbox{
    informative_text = {'info', 'foo', 'baz'}, text = {'bar', 'quux'},
    string_output = true
  }
  assert_equal(type(button), 'string')
end

function test_ui_dialogs_msgbox_interactive()
  local msgboxes = {'msgbox', 'ok_msgbox', 'yesno_msgbox'}
  local icons = {'gtk-dialog-info', 'gtk-dialog-warning', 'gtk-dialog-question'}
  for i, msgbox in ipairs(msgboxes) do
    print('Running ' .. msgbox)
    local button = ui.dialogs[msgbox]{icon = icons[i]}
    assert_equal(type(button), 'number')
    button = ui.dialogs[msgbox]{
      icon_file = _HOME .. '/core/images/ta_32x32.png', string_output = true,
      no_cancel = true
    }
    assert_equal(type(button), 'string')
  end
end

function test_ui_dialogs_optionselect_interactive()
  local _, selected = ui.dialogs.optionselect{items = 'foo', select = 1}
  assert_equal(selected, {1})
  _, selected = ui.dialogs.optionselect{
    items = {'foo', 'bar', 'baz'}, select = {1, 3}, string_output = true
  }
  assert_equal(selected, {'foo', 'baz'})

  assert_raises(function() ui.dialogs.optionselect{items = {'foo', 'bar', 'baz'}, select = {1, 'bar'}} end, "bad argument #select[2] to 'optionselect' (number expected, got string")
end

function test_ui_dialogs_progressbar_interactive()
  local i = 0
  ui.dialogs.progressbar({title = 'foo'}, function()
    os.execute('sleep 0.1')
    i = i + 10
    if i > 100 then return nil end
    return i, i .. '%'
  end)

  local stopped = ui.dialogs.progressbar({
    title = 'foo', indeterminite = true, stoppable = true
  }, function()
    os.execute('sleep 0.1')
    return 50
  end)
  assert(stopped, 'progressbar not stopped')

  ui.update() -- allow GTK to remove callback for previous function
  i = 0
  ui.dialogs.progressbar({title = 'foo', stoppable = true}, function()
    os.execute('sleep 0.1')
    i = i + 10
    if i > 100 then return nil end
    return i, i <= 50 and "stop disable" or "stop enable"
  end)

  local errmsg
  local handler = function(message)
    errmsg = message
    return false -- halt propagation
  end
  events.connect(events.ERROR, handler, 1)
  ui.dialogs.progressbar({}, function() error('foo') end)
  assert(errmsg:find('foo'), 'error handler did not run')
  ui.dialogs.progressbar({}, function() return true end)
  assert(errmsg:find('invalid return values'), 'error handler did not run')
  events.disconnect(events.ERROR, handler)
end

function test_ui_dialogs_textbox_interactive()
  ui.dialogs.textbox{
    text = 'foo', editable = true, selected = true, monospaced_font = true
  }
  ui.dialogs.textbox{text_from_file = _HOME .. '/LICENSE', scroll_to = 'bottom'}
end

function test_ui_switch_buffer_interactive()
  buffer.new()
  buffer:append_text('foo')
  buffer.new()
  buffer:append_text('bar')
  buffer:new()
  buffer:append_text('baz')
  ui.switch_buffer() -- back to [Test Output]
  local text = buffer:get_text()
  assert(text ~= 'foo' and text ~= 'bar' and text ~= 'baz')
  for i = 1, 3 do view:goto_buffer(1) end -- cycle back to baz
  ui.switch_buffer(true)
  assert_equal(buffer:get_text(), 'bar')
  for i = 1, 3 do buffer:close(true) end
end

function test_ui_goto_file()
  local dir1_file1 = _HOME .. '/core/ui/dir1/file1'
  local dir1_file2 = _HOME .. '/core/ui/dir1/file2'
  local dir2_file1 = _HOME .. '/core/ui/dir2/file1'
  local dir2_file2 = _HOME .. '/core/ui/dir2/file2'
  ui.goto_file(dir1_file1) -- current view
  assert_equal(#_VIEWS, 1)
  assert_equal(buffer.filename, dir1_file1)
  ui.goto_file(dir1_file2, true) -- split view
  assert_equal(#_VIEWS, 2)
  assert_equal(buffer.filename, dir1_file2)
  assert_equal(_VIEWS[1].buffer.filename, dir1_file1)
  ui.goto_file(dir1_file1) -- should go back to first view
  assert_equal(buffer.filename, dir1_file1)
  assert_equal(_VIEWS[2].buffer.filename, dir1_file2)
  ui.goto_file(dir2_file2, true, nil, true) -- should sloppily go back to second view
  assert_equal(buffer.filename, dir1_file2) -- sloppy
  assert_equal(_VIEWS[1].buffer.filename, dir1_file1)
  ui.goto_file(dir2_file1) -- should go back to first view
  assert_equal(buffer.filename, dir2_file1)
  assert_equal(_VIEWS[2].buffer.filename, dir1_file2)
  ui.goto_file(dir2_file2, false, _VIEWS[1]) -- should go to second view
  assert_equal(#_VIEWS, 2)
  assert_equal(buffer.filename, dir2_file2)
  assert_equal(_VIEWS[1].buffer.filename, dir2_file1)
  view:unsplit()
  assert_equal(#_VIEWS, 1)
  for i = 1, 4 do buffer:close() end
end

function test_ui_uri_drop()
  local filename = _HOME .. '/test/ui/uri drop'
  local uri = 'file://' .. _HOME .. '/test/ui/uri%20drop'
  events.emit(events.URI_DROPPED, uri)
  assert_equal(buffer.filename, filename)
  buffer:close()
  local buffer = buffer
  events.emit(events.URI_DROPPED, 'file://' .. _HOME)
  assert_equal(buffer, _G.buffer) -- do not open directory

  -- TODO: WIN32
  -- TODO: OSX
end

function test_ui_buffer_switch_save_restore_properties()
  local filename = _HOME .. '/test/ui/test.lua'
  io.open_file(filename)
  buffer:goto_pos(10)
  view:fold_line(
    buffer:line_from_position(buffer.current_pos), view.FOLDACTION_CONTRACT)
  view.view_eol = true
  view.margin_width_n[INDEX(1)] = 0 -- hide line numbers
  view:goto_buffer(-1)
  assert(view.margin_width_n[INDEX(1)] > 0, 'line numbers are still hidden')
  view:goto_buffer(1)
  assert_equal(buffer.current_pos, 10)
  assert_equal(view.fold_expanded[buffer:line_from_position(buffer.current_pos)], false)
  assert_equal(view.view_eol, true)
  assert_equal(view.margin_width_n[INDEX(1)], 0)
  buffer:close()
end

if CURSES then
  -- TODO: clipboard, mouse events, etc.
end

if WIN32 and CURSES then
  function test_spawn()
    -- TODO:
  end
end

function test_buffer_text_range()
  buffer.new()
  buffer:set_text('foo\nbar\nbaz')
  buffer:set_target_range(POS(5), POS(8))
  assert_equal(buffer.target_text, 'bar')
  assert_equal(buffer:text_range(POS(1), buffer.length + 1), 'foo\nbar\nbaz')
  assert_equal(buffer:text_range(-1, POS(4)), 'foo')
  assert_equal(buffer:text_range(POS(9), POS(16)), 'baz')
  assert_equal(buffer.target_text, 'bar') -- assert target range is unchanged
  buffer:close(true)

  assert_raises(function() buffer:text_range() end, 'number expected, got nil')
  assert_raises(function() buffer:text_range(POS(5)) end, 'number expected, got nil')
end

function test_bookmarks()
  local function has_bookmark(line)
    return buffer:marker_get(line) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
  end

  buffer.new()
  buffer:new_line()
  assert(buffer:line_from_position(buffer.current_pos) > LINE(1), 'still on first line')
  textadept.bookmarks.toggle()
  assert(has_bookmark(LINE(2)), 'no bookmark')
  textadept.bookmarks.toggle()
  assert(not has_bookmark(LINE(2)), 'bookmark still there')

  buffer:goto_pos(buffer:position_from_line(LINE(1)))
  textadept.bookmarks.toggle()
  buffer:goto_pos(buffer:position_from_line(LINE(2)))
  textadept.bookmarks.toggle()
  textadept.bookmarks.goto_mark(true)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(1))
  textadept.bookmarks.goto_mark(true)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(2))
  textadept.bookmarks.goto_mark(false)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(1))
  textadept.bookmarks.goto_mark(false)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(2))
  textadept.bookmarks.clear()
  assert(not has_bookmark(LINE(1)), 'bookmark still there')
  assert(not has_bookmark(LINE(2)), 'bookmark still there')
  buffer:close(true)
end

function test_bookmarks_interactive()
  buffer.new()
  buffer:new_line()
  textadept.bookmarks.toggle()
  buffer:line_up()
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(1))
  textadept.bookmarks.goto_mark()
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(2))
  buffer:close(true)
end

function test_command_entry_run()
  local command_run, tab_pressed = false, false
  ui.command_entry.run(function(command) command_run = command end, {
    ['\t'] = function() tab_pressed = true end
  }, nil, 2)
  ui.update() -- redraw command entry
  assert_equal(ui.command_entry:get_lexer(), 'text')
  assert(ui.command_entry.height > ui.command_entry:text_height(0), 'height < 2 lines')
  ui.command_entry:set_text('foo')
  events.emit(events.KEYPRESS, string.byte('\t'))
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(command_run, 'foo')
  assert(tab_pressed, '\\t not registered')

  assert_raises(function() ui.command_entry.run(function() end, 1) end, 'table/string/nil expected, got number')
  assert_raises(function() ui.command_entry.run(function() end, {}, 1) end, 'string/nil expected, got number')
  assert_raises(function() ui.command_entry.run(function() end, {}, 'lua', true) end, 'number/nil expected, got boolean')
  assert_raises(function() ui.command_entry.run(function() end, 'lua', true) end, 'number/nil expected, got boolean')
end

local function run_lua_command(command)
  ui.command_entry.run()
  ui.command_entry:set_text(command)
  assert_equal(ui.command_entry:get_lexer(), 'lua')
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
end

function test_command_entry_run_lua()
  run_lua_command('print(_HOME)')
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert_equal(buffer:get_text(), _HOME .. '\n')
  run_lua_command('{key="value"}')
  assert(buffer:get_text():find('{key = value}'), 'table not pretty-printed')
  -- TODO: multi-line table pretty print.
  if #_VIEWS > 1 then view:unsplit() end
  buffer:close()
end

function test_command_entry_run_lua_abbreviated_env()
  -- buffer get/set.
  run_lua_command('length')
  assert(buffer:get_text():find('%d+%s*$'), 'buffer.length result not a number')
  run_lua_command('auto_c_active')
  assert(buffer:get_text():find('false%s*$'), 'buffer:auto_c_active() result not false')
  run_lua_command('view_eol=true')
  assert_equal(view.view_eol, true)
  -- view get/set.
  if #_VIEWS > 1 then view:unsplit() end
  run_lua_command('split')
  assert_equal(#_VIEWS, 2)
  run_lua_command('size=1')
  assert_equal(view.size, 1)
  run_lua_command('unsplit')
  assert_equal(#_VIEWS, 1)
  -- ui get/set.
  run_lua_command('dialogs')
  assert(buffer:get_text():find('%b{}%s*$'), 'ui.dialogs result not a table')
  run_lua_command('statusbar_text="foo"')
  -- _G get/set.
  run_lua_command('foo="bar"')
  run_lua_command('foo')
  assert(buffer:get_text():find('bar%s*$'), 'foo result not "bar"')
  buffer:close()
end

local function assert_lua_autocompletion(text, first_item)
  ui.command_entry:set_text(text)
  ui.command_entry:goto_pos(ui.command_entry.length + 1)
  events.emit(events.KEYPRESS, string.byte('\t'))
  assert_equal(ui.command_entry:auto_c_active(), true)
  assert_equal(ui.command_entry.auto_c_current_text, first_item)
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), text) -- no history cycling
  assert_equal(ui.command_entry:auto_c_active(), true)
  assert_equal(ui.command_entry.auto_c_current_text, first_item)
  ui.command_entry:auto_c_cancel()
end

function test_command_entry_complete_lua()
  ui.command_entry.run()
  assert_lua_autocompletion('string.', 'byte')
  assert_lua_autocompletion('auto', 'auto_c_active')
  assert_lua_autocompletion('buffer.auto', 'auto_c_auto_hide')
  assert_lua_autocompletion('buffer:auto', 'auto_c_active')
  assert_lua_autocompletion('goto', 'goto_buffer')
  assert_lua_autocompletion('_', '_BUFFERS')
  -- TODO: textadept.editing.show_documentation key binding.
  ui.command_entry:focus() -- hide
end

function test_command_entry_history()
  local one, two = function() end, function() end

  ui.command_entry.run(one)
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), '') -- no prior history
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  assert_equal(ui.command_entry:get_text(), '') -- no further history
  ui.command_entry:add_text('foo')
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n

  ui.command_entry.run(two)
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), '') -- no prior history
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  assert_equal(ui.command_entry:get_text(), '') -- no further history
  ui.command_entry:add_text('bar')
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n

  ui.command_entry.run(one)
  assert_equal(ui.command_entry:get_text(), 'foo')
  assert_equal(ui.command_entry.selection_start, 1)
  assert_equal(ui.command_entry.selection_end, 4)
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), 'foo') -- no prior history
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  assert_equal(ui.command_entry:get_text(), 'foo') -- no further history
  ui.command_entry:set_text('baz')
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n

  ui.command_entry.run(one)
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), 'foo')
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  assert_equal(ui.command_entry:get_text(), 'baz')
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up, 'foo'
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n

  ui.command_entry.run(one)
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), 'baz')
  events.emit(events.KEYPRESS, not CURSES and 0xFF52 or 301) -- up
  assert_equal(ui.command_entry:get_text(), 'foo')
  events.emit(events.KEYPRESS, not CURSES and 0xFF1B or 7) -- esc

  ui.command_entry.run(two)
  assert_equal(ui.command_entry:get_text(), 'bar')
  events.emit(events.KEYPRESS, not CURSES and 0xFF1B or 7) -- esc
end

function test_command_entry_mode_restore()
  local mode = 'test_mode'
  keys.mode = mode
  ui.command_entry.run(nil)
  assert(keys.mode ~= mode)
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(keys.mode, mode)
  keys.mode = nil
end

function test_editing_auto_pair()
  buffer.new()
  -- Single selection.
  buffer:add_text('foo(')
  events.emit(events.CHAR_ADDED, string.byte('('))
  assert_equal(buffer:get_text(), 'foo()')
  events.emit(events.KEYPRESS, string.byte(')'))
  assert_equal(buffer.current_pos, buffer.line_end_position[LINE(1)])
  buffer:char_left()
  -- Note: cannot check for brace highlighting; indicator search does not work.
  events.emit(events.KEYPRESS, not CURSES and 0xFF08 or 263) -- \b
  assert_equal(buffer:get_text(), 'foo')
  -- Multi-selection.
  buffer:set_text('foo(\nfoo(')
  local pos1 = buffer.line_end_position[LINE(1)]
  local pos2 = buffer.line_end_position[LINE(2)]
  buffer:set_selection(pos1, pos1)
  buffer:add_selection(pos2, pos2)
  events.emit(events.CHAR_ADDED, string.byte('('))
  assert_equal(buffer:get_text(), 'foo()\nfoo()')
  assert_equal(buffer.selections, 2)
  assert_equal(buffer.selection_n_start[INDEX(1)], buffer.selection_n_end[INDEX(1)])
  assert_equal(buffer.selection_n_start[INDEX(1)], pos1)
  assert_equal(buffer.selection_n_start[INDEX(2)], buffer.selection_n_end[INDEX(2)])
  assert_equal(buffer.selection_n_start[INDEX(2)], pos2 + 1)
  -- TODO: typeover.
  events.emit(events.KEYPRESS, not CURSES and 0xFF08 or 263) -- \b
  assert_equal(buffer:get_text(), 'foo\nfoo')
  -- Verify atomic undo for multi-select.
  buffer:undo() -- simulated backspace
  buffer:undo() -- normal undo that a user would perform
  assert_equal(buffer:get_text(), 'foo()\nfoo()')
  buffer:undo()
  assert_equal(buffer:get_text(), 'foo(\nfoo(')
  buffer:close(true)
end

function test_editing_auto_indent()
  buffer.new()
  buffer:add_text('foo')
  buffer:new_line()
  assert_equal(buffer.line_indentation[LINE(2)], 0)
  buffer:tab()
  buffer:add_text('bar')
  buffer:new_line()
  assert_equal(buffer.line_indentation[LINE(3)], buffer.tab_width)
  assert_equal(buffer.current_pos, buffer.line_indent_position[LINE(3)])
  buffer:new_line()
  buffer:back_tab()
  assert_equal(buffer.line_indentation[LINE(4)], 0)
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(4)))
  buffer:new_line() -- should indent since previous line is blank
  assert_equal(buffer.line_indentation[LINE(5)], buffer.tab_width)
  assert_equal(buffer.current_pos, buffer.line_indent_position[LINE(5)])
  buffer:goto_pos(buffer:position_from_line(LINE(2))) -- "\tbar"
  buffer:new_line() -- should not change indentation
  assert_equal(buffer.line_indentation[LINE(3)], buffer.tab_width)
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(3)))
  buffer:close(true)
end

function test_editing_strip_trailing_spaces()
  local strip = textadept.editing.strip_trailing_spaces
  textadept.editing.strip_trailing_spaces = true
  buffer.new()
  local text = table.concat({
    'foo ',
    '  bar\t\r',
    'baz\t '
  }, '\n')
  buffer:set_text(text)
  buffer:goto_pos(buffer.line_end_position[LINE(2)])
  events.emit(events.FILE_BEFORE_SAVE)
  assert_equal(buffer:get_text(), table.concat({
    'foo',
    '  bar',
    'baz',
    ''
  }, '\n'))
  assert_equal(buffer.current_pos, buffer.line_end_position[LINE(2)])
  buffer:undo()
  assert_equal(buffer:get_text(), text)
  buffer:close(true)
  textadept.editing.strip_trailing_spaces = strip -- restore
end

function test_editing_paste_reindent_tabs_to_tabs()
  ui.clipboard_text = table.concat({
    '\tfoo',
    '',
    '\t\tbar',
    '\tbaz'
  }, '\n')
  buffer.new()
  buffer.use_tabs, buffer.eol_mode = true, buffer.EOL_CRLF
  buffer:add_text('quux\r\n')
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    'quux',
    'foo',
    '',
    '\tbar',
    'baz'
  }, '\r\n'))
  buffer:clear_all()
  buffer:add_text('\t\tquux\r\n\r\n') -- no auto-indent
  assert_equal(buffer.line_indentation[LINE(2)], 0)
  assert_equal(buffer.line_indentation[LINE(3)], 0)
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    '\t\tquux',
    '',
    '\t\tfoo',
    '\t\t',
    '\t\t\tbar',
    '\t\tbaz'
  }, '\r\n'))
  buffer:clear_all()
  buffer:add_text('\t\tquux\r\n')
  assert_equal(buffer.line_indentation[LINE(2)], 0)
  buffer:new_line() -- auto-indent
  assert_equal(buffer.line_indentation[LINE(3)], 2 * buffer.tab_width)
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    '\t\tquux',
    '',
    '\t\tfoo',
    '\t\t',
    '\t\t\tbar',
    '\t\tbaz'
  }, '\r\n'))
  buffer:close(true)
end
expected_failure(test_editing_paste_reindent_tabs_to_tabs)

function test_editing_paste_reindent_spaces_to_spaces()
  ui.clipboard_text = table.concat({
    '    foo',
    '',
    '        bar',
    '            baz',
    '    quux'
  }, '\n')
  buffer.new()
  buffer.use_tabs, buffer.tab_width = false, 2
  buffer:add_text('foobar\n')
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    'foobar',
    'foo',
    '',
    '  bar',
    '    baz',
    'quux'
  }, '\n'))
  buffer:clear_all()
  buffer:add_text('    foobar\n\n') -- no auto-indent
  assert_equal(buffer.line_indentation[LINE(2)], 0)
  assert_equal(buffer.line_indentation[LINE(3)], 0)
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    '    foobar',
    '',
    '    foo',
    '    ',
    '      bar',
    '        baz',
    '    quux'
  }, '\n'))
  buffer:clear_all()
  buffer:add_text('    foobar\n')
  assert_equal(buffer.line_indentation[LINE(2)], 0)
  buffer:new_line() -- auto-indent
  assert_equal(buffer.line_indentation[LINE(3)], 4)
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    '    foobar',
    '',
    '    foo',
    '    ',
    '      bar',
    '        baz',
    '    quux'
  }, '\n'))
  buffer:close(true)
end
expected_failure(test_editing_paste_reindent_spaces_to_spaces)

function test_editing_paste_reindent_spaces_to_tabs()
  ui.clipboard_text = table.concat({
    '  foo',
    '    bar',
    '  baz'
  }, '\n')
  buffer.new()
  buffer.use_tabs, buffer.tab_width = true, 4
  buffer:add_text('\tquux')
  buffer:new_line()
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    '\tquux',
    '\tfoo',
    '\t\tbar',
    '\tbaz'
  }, '\n'))
  buffer:close(true)
end

function test_editing_paste_reindent_tabs_to_spaces()
  ui.clipboard_text = table.concat({
    '\tif foo and',
    '\t   bar then',
    '\t\tbaz()',
    '\tend',
    ''
  }, '\n')
  buffer.new()
  buffer.use_tabs, buffer.tab_width = false, 2
  buffer:set_lexer('lua')
  buffer:add_text('function quux()')
  buffer:new_line()
  buffer:insert_text(-1, 'end')
  buffer:colorize(POS(1), -1) -- first line should be a fold header
  textadept.editing.paste_reindent()
  assert_equal(buffer:get_text(), table.concat({
    'function quux()',
    '  if foo and',
    '     bar then',
    '    baz()',
    '  end',
    'end'
  }, '\n'))
  buffer:close(true)
end
expected_failure(test_editing_paste_reindent_tabs_to_spaces)

function test_editing_toggle_comment_lines()
  buffer.new()
  buffer:add_text('foo')
  textadept.editing.toggle_comment()
  assert_equal(buffer:get_text(), 'foo')
  buffer:set_lexer('lua')
  local text = table.concat({
    '',
    'local foo = "bar"',
    '  local baz = "quux"',
    ''
  }, '\n')
  buffer:set_text(text)
  buffer:goto_pos(buffer:position_from_line(LINE(2)))
  textadept.editing.toggle_comment()
  assert_equal(buffer:get_text(), table.concat({
    '',
    '--local foo = "bar"',
    '  local baz = "quux"',
    ''
  }, '\n'))
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(2)) + 2)
  textadept.editing.toggle_comment() -- uncomment
  assert_equal(buffer:get_line(LINE(2)), 'local foo = "bar"\n')
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(2)))
  local offset = 5
  buffer:set_sel(buffer:position_from_line(LINE(2)) + offset, buffer:position_from_line(LINE(4)) - offset)
  textadept.editing.toggle_comment()
  assert_equal(buffer:get_text(), table.concat({
    '',
    '--local foo = "bar"',
    '--  local baz = "quux"',
    ''
  }, '\n'))
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)) + offset + 2)
  assert_equal(buffer.selection_end, buffer:position_from_line(LINE(4)) - offset)
  textadept.editing.toggle_comment() -- uncomment
  assert_equal(buffer:get_text(), table.concat({
    '',
    'local foo = "bar"',
    '  local baz = "quux"',
    ''
  }, '\n'))
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)) + offset)
  assert_equal(buffer.selection_end, buffer:position_from_line(LINE(4)) - offset)
  buffer:undo() -- comment
  buffer:undo() -- uncomment
  assert_equal(buffer:get_text(), text) -- verify atomic undo
  buffer:close(true)
end

function test_editing_toggle_comment()
  buffer.new()
  buffer:set_lexer('ansi_c')
  buffer:set_text(table.concat({
    '',
    '  const char *foo = "bar";',
    'const char *baz = "quux";',
    ''
  }, '\n'))
  buffer:set_sel(buffer:position_from_line(LINE(2)), buffer:position_from_line(LINE(4)))
  textadept.editing.toggle_comment()
  assert_equal(buffer:get_text(), table.concat({
    '',
    '  /*const char *foo = "bar";*/',
    '/*const char *baz = "quux";*/',
    ''
  }, '\n'))
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)) + 2)
  assert_equal(buffer.selection_end, buffer:position_from_line(LINE(4)))
  textadept.editing.toggle_comment() -- uncomment
  assert_equal(buffer:get_text(), table.concat({
    '',
    '  const char *foo = "bar";',
    'const char *baz = "quux";',
    ''
  }, '\n'))
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)))
  assert_equal(buffer.selection_end, buffer:position_from_line(LINE(4)))
  buffer:close(true)
end

function test_editing_goto_line()
  buffer.new()
  buffer:new_line()
  textadept.editing.goto_line(LINE(1))
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(1))
  textadept.editing.goto_line(LINE(2))
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(2))
  buffer:close(true)

  assert_raises(function() textadept.editing.goto_line(true) end, 'number/nil expected, got boolean')
end

-- TODO: test_editing_goto_line_interactive

function test_editing_transpose_chars()
  buffer.new()
  buffer:add_text('foobar')
  textadept.editing.transpose_chars()
  assert_equal(buffer:get_text(), 'foobra')
  buffer:char_left()
  textadept.editing.transpose_chars()
  assert_equal(buffer:get_text(), 'foobar')
  buffer:clear_all()
  buffer:add_text('⌘⇧⌥')
  textadept.editing.transpose_chars()
  assert_equal(buffer:get_text(), '⌘⌥⇧')
  buffer:char_left()
  textadept.editing.transpose_chars()
  assert_equal(buffer:get_text(), '⌘⇧⌥')
  -- TODO: multiple selection?
  buffer:close(true)
end

function test_editing_join_lines()
  buffer.new()
  buffer:append_text('foo\nbar\n  baz\nquux\n')
  textadept.editing.join_lines()
  assert_equal(buffer:get_text(), 'foo bar\n  baz\nquux\n')
  assert_equal(buffer.current_pos, POS(4))
  buffer:set_sel(buffer:position_from_line(LINE(2)) + 5, buffer:position_from_line(LINE(4)) - 5)
  textadept.editing.join_lines()
  assert_equal(buffer:get_text(), 'foo bar\n  baz quux\n')
  buffer:close(true)
end

function test_editing_enclose()
  buffer.new()
  buffer.add_text('foo bar')
  textadept.editing.enclose('"', '"')
  assert_equal(buffer:get_text(), 'foo "bar"')
  buffer:undo()
  buffer:select_all()
  textadept.editing.enclose('(', ')')
  assert_equal(buffer:get_text(), '(foo bar)')
  buffer:undo()
  buffer:append_text('\nfoo bar')
  buffer:set_selection(buffer.line_end_position[LINE(1)], buffer.line_end_position[LINE(1)])
  buffer:add_selection(buffer.line_end_position[LINE(2)], buffer.line_end_position[LINE(2)])
  textadept.editing.enclose('<', '>')
  assert_equal(buffer:get_text(), 'foo <bar>\nfoo <bar>')
  buffer:undo()
  assert_equal(buffer:get_text(), 'foo bar\nfoo bar') -- verify atomic undo
  buffer:set_selection(buffer:position_from_line(LINE(1)), buffer.line_end_position[LINE(1)])
  buffer:add_selection(buffer:position_from_line(LINE(2)), buffer.line_end_position[LINE(2)])
  textadept.editing.enclose('-', '-')
  assert_equal(buffer:get_text(), '-foo bar-\n-foo bar-')
  buffer:close(true)

  assert_raises(function() textadept.editing.enclose() end, 'string expected, got nil')
  assert_raises(function() textadept.editing.enclose('<', 1) end, 'string expected, got number')
end

function test_editing_select_enclosed()
  buffer.new()
  buffer:add_text('("foo bar")')
  buffer:goto_pos(POS(6))
  textadept.editing.select_enclosed()
  assert_equal(buffer:get_sel_text(), 'foo bar')
  textadept.editing.select_enclosed()
  assert_equal(buffer:get_sel_text(), '"foo bar"')
  textadept.editing.select_enclosed()
  assert_equal(buffer:get_sel_text(), 'foo bar')
  buffer:goto_pos(POS(6))
  textadept.editing.select_enclosed('("', '")')
  assert_equal(buffer:get_sel_text(), 'foo bar')
  textadept.editing.select_enclosed('("', '")')
  assert_equal(buffer:get_sel_text(), '("foo bar")')
  textadept.editing.select_enclosed('("', '")')
  assert_equal(buffer:get_sel_text(), 'foo bar')
  buffer:append_text('"baz"')
  buffer:goto_pos(POS(10)) -- last " on first line
  textadept.editing.select_enclosed()
  assert_equal(buffer:get_sel_text(), 'foo bar')
  buffer:close(true)

  assert_raises(function() textadept.editing.select_enclosed('"') end, 'string expected, got nil')
end
expected_failure(test_editing_select_enclosed)

function test_editing_select_word()
  buffer.new()
  buffer:append_text(table.concat({
    'foo',
    'foobar',
    'bar foo',
    'baz foo bar',
    'fooquux',
    'foo'
  }, '\n'))
  textadept.editing.select_word()
  assert_equal(buffer:get_sel_text(), 'foo')
  textadept.editing.select_word()
  assert_equal(buffer.selections, 2)
  assert_equal(buffer:get_sel_text(), 'foofoo') -- Scintilla stores it this way
  textadept.editing.select_word(true)
  assert_equal(buffer.selections, 4)
  assert_equal(buffer:get_sel_text(), 'foofoofoofoo')
  local lines = {}
  for i = INDEX(1), INDEX(buffer.selections) do
    lines[#lines + 1] = buffer:line_from_position(buffer.selection_n_start[i])
  end
  table.sort(lines)
  assert_equal(lines, {LINE(1), LINE(3), LINE(4), LINE(6)})
  buffer:close(true)
end

function test_editing_select_line()
  buffer.new()
  buffer:add_text('foo\n  bar')
  textadept.editing.select_line()
  assert_equal(buffer:get_sel_text(), '  bar')
  buffer:close(true)
end

function test_editing_select_paragraph()
  buffer.new()
  buffer:set_text(table.concat({
    'foo',
    '',
    'bar',
    'baz',
    '',
    'quux'
  }, '\n'))
  buffer:goto_pos(buffer:position_from_line(LINE(3)))
  textadept.editing.select_paragraph()
  assert_equal(buffer:get_sel_text(), 'bar\nbaz\n\n')
  buffer:close(true)
end

function test_editing_convert_indentation()
  buffer.new()
  local text = table.concat({
    '\tfoo',
    '  bar',
    '\t    baz',
    '    \tquux'
  }, '\n')
  buffer:set_text(text)
  buffer.use_tabs, buffer.tab_width = true, 4
  textadept.editing.convert_indentation()
  assert_equal(buffer:get_text(), table.concat({
    '\tfoo',
    '  bar',
    '\t\tbaz',
    '\t\tquux'
  }, '\n'))
  buffer:undo()
  assert_equal(buffer:get_text(), text) -- verify atomic undo
  buffer.use_tabs, buffer.tab_width = false, 2
  textadept.editing.convert_indentation()
  assert_equal(buffer:get_text(), table.concat({
    '  foo',
    '  bar',
    '      baz',
    '      quux'
  }, '\n'))
  buffer:close(true)
end

function test_ui_highlight_word()
  buffer.new()
  buffer:append_text(table.concat({
    'foo',
    'foobar',
    'bar foo',
    'baz foo bar',
    'fooquux',
    'foo'
  }, '\n'))
  textadept.editing.select_word()
  ui.update()
  local indics = {
    buffer:position_from_line(LINE(1)),
    buffer:position_from_line(LINE(3)) + 4,
    buffer:position_from_line(LINE(4)) + 4,
    buffer:position_from_line(LINE(6))
  }
  local bit = 1 << ui.INDIC_HIGHLIGHT - 1
  for _, pos in ipairs(indics) do
    local mask = buffer:indicator_all_on_for(pos)
    assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
  end
  events.emit(events.KEYPRESS, not CURSES and 0xFF1B or 7) -- esc
  local pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 1)
  assert_equal(pos, 1) -- highlights cleared
  -- Verify turning off word highlighting.
  ui.highlight_words = false
  textadept.editing.select_word()
  ui.update()
  pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 2)
  assert_equal(pos, 1) -- no highlights
  ui.highlight_words = true -- reset
  -- Verify partial word selections do not highlight words.
  buffer:set_sel(1, 3)
  pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 2)
  assert_equal(pos, 1) -- no highlights
  -- Verify multi-word selections do not highlight words.
  buffer:set_sel(buffer:position_from_line(LINE(3)), buffer.line_end_position[LINE(3)])
  assert(buffer:is_range_word(buffer.selection_start, buffer.selection_end))
  pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 2)
  assert_equal(pos, 1) -- no highlights
  buffer:close(true)
end

function test_editing_filter_through()
  buffer.new()
  buffer:set_text('3|baz\n1|foo\n5|foobar\n1|foo\n4|quux\n2|bar\n')
  textadept.editing.filter_through('sort')
  assert_equal(buffer:get_text(), '1|foo\n1|foo\n2|bar\n3|baz\n4|quux\n5|foobar\n')
  buffer:undo()
  textadept.editing.filter_through('sort | uniq|cut -d "|" -f2')
  assert_equal(buffer:get_text(), 'foo\nbar\nbaz\nquux\nfoobar\n')
  buffer:undo()
  buffer:set_sel(buffer:position_from_line(LINE(2)) + 2, buffer.line_end_position[LINE(2)])
  textadept.editing.filter_through('sed -e "s/o/O/g;"')
  assert_equal(buffer:get_text(), '3|baz\n1|fOO\n5|foobar\n1|foo\n4|quux\n2|bar\n')
  buffer:undo()
  buffer:set_sel(buffer:position_from_line(LINE(2)), buffer:position_from_line(LINE(5)))
  textadept.editing.filter_through('sort')
  assert_equal(buffer:get_text(), '3|baz\n1|foo\n1|foo\n5|foobar\n4|quux\n2|bar\n')
  buffer:undo()
  buffer:set_sel(buffer:position_from_line(LINE(2)), buffer:position_from_line(LINE(5)) + 1)
  textadept.editing.filter_through('sort')
  assert_equal(buffer:get_text(), '3|baz\n1|foo\n1|foo\n4|quux\n5|foobar\n2|bar\n')
  buffer:close(true)

  assert_raises(function() textadept.editing.filter_through() end, 'string expected, got nil')
end

function test_editing_autocomplete()
  assert_raises(function() textadept.editing.autocomplete() end, 'string expected, got nil')
end

function test_editing_autocomplete_word()
  local all_words = textadept.editing.autocomplete_all_words
  textadept.editing.autocomplete_all_words = false
  buffer.new()
  buffer:add_text('foo f')
  textadept.editing.autocomplete('word')
  assert_equal(buffer:get_text(), 'foo foo')
  buffer:add_text('bar f')
  textadept.editing.autocomplete('word')
  assert(buffer:auto_c_active(), 'autocomplete list not shown')
  buffer:auto_c_select('foob')
  buffer:auto_c_complete()
  assert_equal(buffer:get_text(), 'foo foobar foobar')
  local ignore_case = buffer.auto_c_ignore_case
  buffer.auto_c_ignore_case = false
  buffer:add_text(' Bar b')
  textadept.editing.autocomplete('word')
  assert_equal(buffer:get_text(), 'foo foobar foobar Bar b')
  buffer.auto_c_ignore_case = true
  textadept.editing.autocomplete('word')
  assert_equal(buffer:get_text(), 'foo foobar foobar Bar Bar')
  buffer.auto_c_ignore_case = ignore_case
  buffer.new()
  buffer:add_text('foob')
  textadept.editing.autocomplete_all_words = true
  textadept.editing.autocomplete('word')
  textadept.editing.autocomplete_all_words = all_words
  assert_equal(buffer:get_text(), 'foobar')
  buffer:close(true)
  buffer:close(true)
end

function test_editing_show_documentation()
  buffer.new()
  textadept.editing.api_files['text'] = {
    _HOME .. '/test/modules/textadept/editing/api',
    function() return _HOME .. '/test/modules/textadept/editing/api2' end
  }
  buffer:add_text('foo')
  textadept.editing.show_documentation()
  assert(view:call_tip_active(), 'documentation not found')
  view:call_tip_cancel()
  buffer:add_text('2')
  textadept.editing.show_documentation()
  assert(view:call_tip_active(), 'documentation not found')
  view:call_tip_cancel()
  buffer:add_text('bar')
  textadept.editing.show_documentation()
  assert(not view:call_tip_active(), 'documentation found')
  buffer:clear_all()
  buffer:add_text('FOO')
  textadept.editing.show_documentation(nil, true)
  assert(view:call_tip_active(), 'documentation not found')
  view:call_tip_cancel()
  buffer:add_text('(')
  textadept.editing.show_documentation(nil, true)
  assert(view:call_tip_active(), 'documentation not found')
  view:call_tip_cancel()
  buffer:add_text('bar')
  textadept.editing.show_documentation(nil, true)
  assert(view:call_tip_active(), 'documentation not found')
  events.emit(events.CALL_TIP_CLICK, 1)
  -- TODO: test calltip cycling.
  buffer:close(true)
  textadept.editing.api_files['text'] = nil

  assert_raises(function() textadept.editing.show_documentation(true) end, 'number/nil expected, got boolean')
end

function test_file_types_get_lexer()
  buffer.new()
  buffer:set_lexer('html')
  buffer:set_text(table.concat({
    '<html><head><style type="text/css">',
    'h1 {}',
    '</style></head></html>'
  }, '\n'))
  buffer:colorize(POS(1), -1)
  buffer:goto_pos(buffer:position_from_line(LINE(2)))
  assert_equal(buffer:get_lexer(), 'html')
  assert_equal(buffer:get_lexer(true), 'css')
  assert_equal(buffer:name_of_style(buffer.style_at[buffer.current_pos]), 'identifier')
  buffer:close(true)
end

function test_file_types_set_lexer()
  local lexer_loaded
  local handler = function(lexer) lexer_loaded = lexer end
  events.connect(events.LEXER_LOADED, handler)
  buffer.new()
  buffer.filename = 'foo.lua'
  buffer:set_lexer()
  assert_equal(buffer:get_lexer(), 'lua')
  assert_equal(lexer_loaded, 'lua')
  buffer.filename = 'foo'
  buffer:set_text('#!/bin/sh')
  buffer:set_lexer()
  assert_equal(buffer:get_lexer(), 'bash')
  buffer:undo()
  buffer.filename = 'Makefile'
  buffer:set_lexer()
  assert_equal(buffer:get_lexer(), 'makefile')
  -- Verify lexer after certain events.
  buffer.filename = 'foo.c'
  events.emit(events.FILE_AFTER_SAVE, nil, true)
  assert_equal(buffer:get_lexer(), 'ansi_c')
  buffer.filename = 'foo.cpp'
  events.emit(events.FILE_OPENED)
  assert_equal(buffer:get_lexer(), 'cpp')
  view:goto_buffer(1)
  view:goto_buffer(-1)
  assert_equal(buffer:get_lexer(), 'cpp')
  events.disconnect(events.LEXER_LOADED, handler)
  buffer:close(true)

  assert_raises(function() buffer:set_lexer(true) end, 'string/nil expected, got boolean')
end

function test_file_types_select_lexer_interactive()
  buffer.new()
  local lexer = buffer:get_lexer()
  textadept.file_types.select_lexer()
  assert(buffer:get_lexer() ~= lexer, 'lexer unchanged')
  buffer:close()
end

function test_file_types_load_lexers()
  local lexers = {}
  for name in buffer:private_lexer_call(_SCINTILLA.functions.property_names[1]):gmatch('[^\n]+') do
    lexers[#lexers + 1] = name
  end
  print('Loading lexers...')
  if #_VIEWS > 1 then view:unsplit() end
  view:goto_buffer(-1)
  ui.silent_print = true
  buffer.new()
  for _, name in ipairs(lexers) do
    print('Loading lexer ' .. name)
    buffer:set_lexer(name)
  end
  buffer:close()
  ui.silent_print = false
end

function test_ui_find_find_text()
  local wrapped = false
  local handler = function() wrapped = true end
  buffer.new()
  buffer:set_text(table.concat({
    ' foo',
    'foofoo',
    'FOObar',
    'foo bar baz',
  }, '\n'))
  ui.find.find_entry_text = 'foo'
  ui.find.find_next()
  assert_equal(buffer.selection_start, POS(1) + 1)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.whole_word = true
  ui.find.find_next()
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(4)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  events.connect(events.FIND_WRAPPED, handler)
  ui.find.find_next()
  assert(wrapped, 'search did not wrap')
  events.disconnect(events.FIND_WRAPPED, handler)
  assert_equal(buffer.selection_start, POS(1) + 1)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.find_prev()
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(4)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.match_case, ui.find.whole_word = true, false
  ui.find.find_entry_text = 'FOO'
  ui.find.find_next()
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(3)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.find_next()
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(3)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.regex = true
  ui.find.find_entry_text = 'f(.)\\1'
  ui.find.find_next()
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(4)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.find_entry_text = 'quux'
  ui.find.find_next()
  assert_equal(buffer.selection_start, buffer.selection_end) -- no match
  ui.find.find_entry_text = '' -- reset
  ui.find.match_case, ui.find.regex = false, false -- reset
  buffer:close(true)
end

function test_ui_find_highlight_results()
  local function assert_indics(indics)
    local bit = 1 << ui.INDIC_HIGHLIGHT - 1
    for _, pos in ipairs(indics) do
      local mask = buffer:indicator_all_on_for(pos)
      assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
    end
  end

  buffer.new()
  buffer:append_text(table.concat({
    'foo',
    'foobar',
    'bar foo',
    'baz foo bar',
    'fooquux',
    'foo'
  }, '\n'))
  -- Normal search.
  ui.find.find_entry_text = 'foo'
  ui.find.find_next()
  assert_indics{
    buffer:position_from_line(LINE(1)),
    buffer:position_from_line(LINE(3)) + 4,
    buffer:position_from_line(LINE(4)) + 4,
    buffer:position_from_line(LINE(6))
  }
  -- Regex search.
  ui.find.find_entry_text = 'ba.'
  ui.find.regex = true
  ui.find.find_next()
  assert_indics{
    buffer:position_from_line(LINE(2)) + 3,
    buffer:position_from_line(LINE(3)),
    buffer:position_from_line(LINE(4)),
    buffer:position_from_line(LINE(4)) + 8,
  }
  ui.find.regex = false -- reset
  -- Do not highlight short searches (potential performance issue).
  ui.find.find_entry_text = 'f'
  ui.find.find_next()
  local pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 2)
  assert_equal(pos, 1)
  ui.find.find_entry_text = '' -- reset
  buffer:close(true)
end

function test_ui_find_incremental()
  if not rawget(ui.find.find_incremental_keys, '\n') then
    -- Overwritten in _USERHOME.
    ui.find.find_incremental_keys['\n'] = function()
      ui.find.find_entry_text = ui.command_entry:get_text() -- save
      ui.find.find_incremental(ui.command_entry:get_text(), true, true)
    end
  end

  buffer.new()
  buffer:set_text(table.concat({
    ' foo',
    'foobar',
    'FOObaz',
    'FOOquux'
  }, '\n'))
  assert_equal(buffer.current_pos, POS(1))
  ui.find.find_incremental()
  events.emit(events.KEYPRESS, string.byte('f'))
  ui.command_entry:add_text('f') -- simulate keypress
  assert_equal(buffer.selection_start, POS(1) + 1)
  assert_equal(buffer.selection_end, buffer.selection_start + 1)
  events.emit(events.KEYPRESS, string.byte('o'))
  ui.command_entry:add_text('o') -- simulate keypress
  events.emit(events.KEYPRESS, string.byte('o'))
  ui.command_entry:add_text('o') -- simulate keypress
  assert_equal(buffer.selection_start, POS(1) + 1)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  events.emit(events.KEYPRESS, string.byte('q'))
  ui.command_entry:add_text('q') -- simulate keypress
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(4)))
  assert_equal(buffer.selection_end, buffer.selection_start + 4)
  events.emit(events.KEYPRESS, not CURSES and 0xFF08 or 263) -- \b
  ui.command_entry:delete_back() -- simulate keypress
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(2)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(buffer.selection_start, buffer:position_from_line(LINE(3)))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.match_case = true
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n, wrap
  assert_equal(buffer.selection_start, POS(1) + 1)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  ui.find.match_case = false
  ui.find.find_entry_text = '' -- reset
  buffer:close(true)

  assert_raises(function() ui.find.find_incremental(1) end, 'string/nil expected, got number')
end

function test_ui_find_incremental_highlight()
  buffer.new()
  buffer:set_text(table.concat({
    ' foo',
    'foobar',
    'FOObaz',
    'FOOquux'
  }, '\n'))
  ui.find.find_incremental()
  events.emit(events.KEYPRESS, string.byte('f'))
  ui.command_entry:add_text('f') -- simulate keypress
  local pos = buffer:indicator_end(ui.INDIC_HIGHLIGHT, 2)
  assert_equal(pos, 1) -- too short
  events.emit(events.KEYPRESS, string.byte('o'))
  ui.command_entry:add_text('o') -- simulate keypress
  local indics = {
    buffer:position_from_line(LINE(1)) + 1,
    buffer:position_from_line(LINE(2)),
    buffer:position_from_line(LINE(3)),
    buffer:position_from_line(LINE(4))
  }
  local bit = 1 << ui.INDIC_HIGHLIGHT - 1
  for _, pos in ipairs(indics) do
    local mask = buffer:indicator_all_on_for(pos)
    assert(mask & bit > 0, 'no indicator on line %d', buffer:line_from_position(pos))
  end
  ui.find.find_entry_text = '' -- reset
  buffer:close(true)
end

function test_ui_find_find_in_files()
  ui.find.find_entry_text = 'foo'
  ui.find.match_case = true
  ui.find.find_in_files(_HOME .. '/test')
  assert_equal(buffer._type, _L['[Files Found Buffer]'])
  if #_VIEWS > 1 then view:unsplit() end
  local count = 0
  for filename, line, text in buffer:get_text():gmatch('\n([^:]+):(%d+):([^\n]+)') do
    assert(filename:find('^' .. _HOME .. '/test'), 'invalid filename "%s"', filename)
    assert(text:find('foo'), '"foo" not found in "%s"', text)
    count = count + 1
  end
  assert(count > 0, 'no files found')
  local s = buffer:indicator_end(ui.find.INDIC_FIND, 0)
  while true do
    local e = buffer:indicator_end(ui.find.INDIC_FIND, s + 1)
    if e == s then break end -- no more results
    assert_equal(buffer:text_range(s, e), 'foo')
    s = buffer:indicator_end(ui.find.INDIC_FIND, e + 1)
  end
  ui.find.goto_file_found(true) -- wraps around
  assert_equal(#_VIEWS, 2)
  assert(buffer.filename, 'not in file found result')
  ui.goto_view(1)
  assert_equal(view.buffer._type, _L['[Files Found Buffer]'])
  local filename, line_num = view.buffer:get_sel_text():match('^([^:]+):(%d+)')
  ui.goto_view(-1)
  assert_equal(buffer.filename, filename)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(tonumber(line_num)))
  assert_equal(buffer:get_sel_text(), 'foo')
  ui.goto_view(1) -- files found buffer
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(buffer.filename, filename)
  ui.goto_view(1) -- files found buffer
  events.emit(events.DOUBLE_CLICK, nil, buffer:line_from_position(buffer.current_pos))
  assert_equal(buffer.filename, filename)
  buffer:close()
  ui.goto_view(1) -- files found buffer
  ui.find.goto_file_found(nil, false) -- wraps around
  assert(buffer.filename and buffer.filename ~= filename, 'opened the same file')
  buffer:close()
  ui.goto_view(1) -- files found buffer
  ui.find.find_entry_text = ''
  view:unsplit()
  buffer:close()
  -- TODO: ui.find.find_in_files() -- no param

  assert_raises(function() ui.find.find_in_files('', 1) end, 'string/table/nil expected, got number')
end

function test_ui_find_replace()
  buffer.new()
  buffer:set_text('foofoo')
  ui.find.find_entry_text = 'foo'
  ui.find.find_next()
  ui.find.replace_entry_text = 'bar'
  ui.find.replace()
  assert_equal(buffer.selection_start, POS(4))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  assert_equal(buffer:get_sel_text(), 'foo')
  assert_equal(buffer:get_text(), 'barfoo')
  ui.find.regex = true
  ui.find.find_entry_text = 'f(.)\\1'
  ui.find.find_next()
  ui.find.replace_entry_text = 'b\\1\\1\\u1234'
  ui.find.replace()
  assert_equal(buffer:get_text(), 'barbooሴ')
  ui.find.regex = false
  ui.find.find_entry_text = 'quux'
  ui.find.find_next()
  ui.find.replace_entry_text = ''
  ui.find.replace()
  assert_equal(buffer:get_text(), 'barbooሴ')
  ui.find.find_entry_text, ui.find.replace_entry_text = '', '' -- reset
  buffer:close(true)
end

function test_ui_find_replace_all()
  buffer.new()
  local text = table.concat({
    'foo',
    'foobar',
    'foobaz',
    'foofoo'
  }, '\n')
  buffer:set_text(text)
  ui.find.find_entry_text, ui.find.replace_entry_text = 'foo', 'bar'
  ui.find.replace_all()
  assert_equal(buffer:get_text(), 'bar\nbarbar\nbarbaz\nbarbar')
  buffer:undo()
  assert_equal(buffer:get_text(), text) -- verify atomic undo
  ui.find.regex = true
  buffer:set_sel(buffer:position_from_line(LINE(2)), buffer:position_from_line(LINE(4)) + 3)
  ui.find.find_entry_text, ui.find.replace_entry_text = 'f(.)\\1', 'b\\1\\1'
  ui.find.replace_all() -- replace in selection
  assert_equal(buffer:get_text(), 'foo\nboobar\nboobaz\nboofoo')
  ui.find.regex = false
  buffer:undo()
  ui.find.find_entry_text, ui.find.replace_entry_text = 'foo', ''
  ui.find.replace_all()
  assert_equal(buffer:get_text(), '\nbar\nbaz\n')
  ui.find.find_entry_text, ui.find.replace_entry_text = 'quux', ''
  ui.find.replace_all()
  assert_equal(buffer:get_text(), '\nbar\nbaz\n')
  ui.find.find_entry_text, ui.find.replace_entry_text = '', '' -- reset
  buffer:close(true)
end

function test_macro_record_play_save_load()
  textadept.macros.save() -- should not do anything
  textadept.macros.play() -- should not do anything
  assert_equal(#_BUFFERS, 1)
  assert(not buffer.modify, 'a macro was played')

  textadept.macros.record()
  events.emit(events.MENU_CLICKED, 1) -- File > New
  buffer:add_text('f')
  events.emit(events.CHAR_ADDED, string.byte('f'))
  events.emit(events.FIND, 'f', true)
  events.emit(events.REPLACE, 'b')
  buffer:replace_sel('a') -- typing would do this
  events.emit(events.CHAR_ADDED, string.byte('a'))
  buffer:add_text('r')
  events.emit(events.CHAR_ADDED, string.byte('r'))
  events.emit(events.KEYPRESS, string.byte('t'), false, true) -- transpose
  textadept.macros.play() -- should not do anything
  textadept.macros.save() -- should not do anything
  textadept.macros.load() -- should not do anything
  textadept.macros.record() -- stop
  assert_equal(#_BUFFERS, 2)
  assert_equal(buffer:get_text(), 'ra')
  buffer:close(true)
  textadept.macros.play()
  assert_equal(#_BUFFERS, 2)
  assert_equal(buffer:get_text(), 'ra')
  buffer:close(true)
  local filename = os.tmpname()
  textadept.macros.save(filename)
  textadept.macros.record()
  textadept.macros.record()
  textadept.macros.load(filename)
  textadept.macros.play()
  assert_equal(#_BUFFERS, 2)
  assert_equal(buffer:get_text(), 'ra')
  buffer:close(true)
  os.remove(filename)

  assert_raises(function() textadept.macros.save(1) end, 'string/nil expected, got number')
  assert_raises(function() textadept.macros.load(1) end, 'string/nil expected, got number')
end

function test_macro_record_play_with_keys_only()
  if keys.f9 ~= textadept.macros.record then
    print('Note: not running since F9 does not toggle macro recording')
    return
  end
  buffer.new()
  buffer:append_text('foo\nbar\nbaz\n')
  events.emit(events.KEYPRESS, 0xFFC6) -- f9; start recording
  events.emit(events.KEYPRESS, not CURSES and 0xFF57 or 305) -- end
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 13) -- \n
  buffer:new_line()
  events.emit(events.KEYPRESS, not CURSES and 0xFF54 or 300) -- down
  events.emit(events.KEYPRESS, 0xFFC6) -- f9; stop recording
  assert_equal(buffer:get_text(), 'foo\n\nbar\nbaz\n');
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(3)))
  if not CURSES then
    events.emit(events.KEYPRESS, 0xFFC6, true) -- sf9; play
  else
    events.emit(events.KEYPRESS, 0xFFC7) -- f10; play
  end
  assert_equal(buffer:get_text(), 'foo\n\nbar\n\nbaz\n');
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(5)))
  if not CURSES then
    events.emit(events.KEYPRESS, 0xFFC6, true) -- sf9; play
  else
    events.emit(events.KEYPRESS, 0xFFC7) -- f10; play
  end
  assert_equal(buffer:get_text(), 'foo\n\nbar\n\nbaz\n\n');
  assert_equal(buffer.current_pos, buffer:position_from_line(LINE(7)))
  buffer:close(true)
end

function test_menu_menu_functions()
  buffer.new()
  textadept.menu.menubar[_L['Buffer']][_L['Indentation']][_L['Tab width: 8']][2]()
  assert_equal(buffer.tab_width, 8)
  textadept.menu.menubar[_L['Buffer']][_L['EOL Mode']][_L['CRLF']][2]()
  assert_equal(buffer.eol_mode, buffer.EOL_CRLF)
  textadept.menu.menubar[_L['Buffer']][_L['Encoding']][_L['CP-1252 Encoding']][2]()
  assert_equal(buffer.encoding, 'CP1252')
  buffer:set_text('foo')
  textadept.menu.menubar[_L['Edit']][_L['Delete Word']][2]()
  assert_equal(buffer:get_text(), '')
  buffer:set_text('(foo)')
  textadept.menu.menubar[_L['Edit']][_L['Match Brace']][2]()
  assert_equal(buffer.char_at[buffer.current_pos], string.byte(')'))
  buffer:set_text('foo f')
  buffer:line_end()
  textadept.menu.menubar[_L['Edit']][_L['Complete Word']][2]()
  assert_equal(buffer:get_text(), 'foo foo')
  buffer:set_text('2\n1\n3\n')
  textadept.menu.menubar[_L['Edit']][_L['Filter Through']][2]()
  ui.command_entry:set_text('sort')
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(buffer:get_text(), '1\n2\n3\n')
  buffer:set_text('foo')
  buffer:line_end()
  textadept.menu.menubar[_L['Edit']][_L['Selection']][_L['Enclose as XML Tags']][2]()
  assert_equal(buffer:get_text(), '<foo></foo>')
  assert_equal(buffer.current_pos, POS(6))
  buffer:undo()
  assert_equal(buffer:get_text(), 'foo') -- verify atomic undo
  textadept.menu.menubar[_L['Edit']][_L['Selection']][_L['Enclose as Single XML Tag']][2]()
  assert_equal(buffer:get_text(), '<foo />')
  assert_equal(buffer.current_pos, buffer.line_end_position[LINE(1)])
  if not CURSES then -- there are focus issues in curses
    textadept.menu.menubar[_L['Search']][_L['Find in Files']][2]()
    assert(ui.find.in_files, 'not finding in files')
    textadept.menu.menubar[_L['Search']][_L['Find']][2]()
    assert(not ui.find.in_files, 'finding in files')
  end
  buffer:clear_all()
  buffer:set_lexer('lua')
  buffer:add_text('string.')
  textadept.menu.menubar[_L['Tools']][_L['Complete Symbol']][2]()
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'byte')
  buffer:auto_c_cancel()
  buffer:char_left()
  textadept.menu.menubar[_L['Tools']][_L['Show Style']][2]()
  assert(view:call_tip_active(), 'style not shown')
  view:call_tip_cancel()
  local use_tabs = buffer.use_tabs
  textadept.menu.menubar[_L['Buffer']][_L['Indentation']][_L['Toggle Use Tabs']][2]()
  assert(buffer.use_tabs ~= use_tabs, 'use tabs not toggled')
  local view_eol = view.view_eol
  textadept.menu.menubar[_L['Buffer']][_L['Toggle View EOL']][2]()
  assert(view.view_eol ~= view_eol, 'view EOL not toggled')
  local wrap_mode = view.wrap_mode
  textadept.menu.menubar[_L['Buffer']][_L['Toggle Wrap Mode']][2]()
  assert(view.wrap_mode ~= wrap_mode, 'wrap mode not toggled')
  local view_whitespace = view.view_ws
  textadept.menu.menubar[_L['Buffer']][_L['Toggle View Whitespace']][2]()
  assert(view.view_ws ~= view_whitespace, 'view whitespace not toggled')
  view:split()
  ui.update()
  local size = view.size
  textadept.menu.menubar[_L['View']][_L['Grow View']][2]()
  assert(view.size > size, 'view shrunk')
  textadept.menu.menubar[_L['View']][_L['Shrink View']][2]()
  assert_equal(view.size, size)
  view:unsplit()
  buffer:set_text('if foo then\n  bar\nend')
  buffer:colorize(POS(1), -1)
  textadept.menu.menubar[_L['View']][_L['Toggle Current Fold']][2]()
  assert_equal(view.fold_expanded[buffer:line_from_position(buffer.current_pos)], false)
  local indentation_guides = view.indentation_guides
  textadept.menu.menubar[_L['View']][_L['Toggle Show Indent Guides']][2]()
  assert(view.indentation_guides ~= indentation_guides, 'indentation guides not toggled')
  local virtual_space = buffer.virtual_space_options
  textadept.menu.menubar[_L['View']][_L['Toggle Virtual Space']][2]()
  assert(buffer.virtual_space_options ~= virtual_space, 'virtual space not toggled')
  buffer:close(true)
end

function test_menu_functions_interactive()
  buffer.new()
  buffer.filename = '/tmp/test.lua'
  textadept.menu.menubar[_L['Tools']][_L['Set Arguments...']][2]()
  textadept.menu.menubar[_L['Help']][_L['About']][2]()
  buffer:close(true)
end

-- TODO: test set arguments more thoroughly.

function test_menu_select_command_interactive()
  local num_buffers = #_BUFFERS
  textadept.menu.select_command()
  assert(#_BUFFERS > num_buffers, 'new buffer not created')
  buffer:close()
end

function test_run_compile_run()
  textadept.run.compile() -- should not do anything
  textadept.run.run() -- should not do anything
  assert_equal(#_BUFFERS, 1)
  assert(not buffer.modify, 'a command was run')

  local compile_file = _HOME .. '/test/modules/textadept/run/compile.lua'
  textadept.run.compile(compile_file)
  assert_equal(#_BUFFERS, 2)
  assert_equal(buffer._type, _L['[Message Buffer]'])
  ui.update() -- process output
  assert(buffer:get_text():find("'end' expected"), 'no compile error')
  assert(buffer:get_text():find('> exit status: 256'), 'no compile error')
  if #_VIEWS > 1 then view:unsplit() end
  textadept.run.goto_error(true) -- wraps
  assert_equal(#_VIEWS, 2)
  assert_equal(buffer.filename, compile_file)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(3))
  assert(buffer.annotation_text[LINE(3)]:find("'end' expected"), 'annotation not visible')
  ui.goto_view(1) -- message buffer
  assert_equal(buffer._type, _L['[Message Buffer]'])
  assert(buffer:get_sel_text():find("'end' expected"), 'compile error not selected')
  assert(buffer:marker_get(buffer:line_from_position(buffer.current_pos)) & 1 << textadept.run.MARK_ERROR - 1 > 0)
  events.emit(events.KEYPRESS, not CURSES and 0xFF0D or 343) -- \n
  assert_equal(buffer.filename, compile_file)
  ui.goto_view(1) -- message buffer
  events.emit(events.DOUBLE_CLICK, nil, buffer:line_from_position(buffer.current_pos))
  assert_equal(buffer.filename, compile_file)
  local compile_command = textadept.run.compile_commands.lua
  textadept.run.compile() -- clears annotation
  ui.update() -- process output
  view:goto_buffer(1)
  assert(not buffer.annotation_text[LINE(3)]:find("'end' expected"), 'annotation visible')
  buffer:close() -- compile_file

  local run_file = _HOME .. '/test/modules/textadept/run/run.lua'
  textadept.run.run_commands[run_file] = function()
    return textadept.run.run_commands.lua, run_file:match('^(.+[/\\])') -- intentional trailing '/'
  end
  io.open_file(run_file)
  textadept.run.run()
  assert_equal(buffer._type, _L['[Message Buffer]'])
  ui.update() -- process output
  assert(buffer:get_text():find('attempt to call a nil value'), 'no run error')
  textadept.run.goto_error(false)
  assert_equal(buffer.filename, run_file)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(2))
  textadept.run.goto_error(nil, false)
  assert_equal(buffer.filename, run_file)
  assert_equal(buffer:line_from_position(buffer.current_pos), LINE(1))
  ui.goto_view(1)
  assert(buffer:marker_get(buffer:line_from_position(buffer.current_pos)) & 1 << textadept.run.MARK_WARNING - 1 > 0)
  ui.goto_view(-1)
  textadept.run.goto_error(false)
  assert_equal(buffer.filename, compile_file)
  if #_VIEWS > 1 then view:unsplit() end
  buffer:close() -- compile_file
  buffer:close() -- run_file
  buffer:close() -- message buffer

  assert_raises(function() textadept.run.compile({}) end, 'string/nil expected, got table')
  assert_raises(function() textadept.run.run({}) end, 'string/nil expected, got table')
end

function test_run_build()
  textadept.run.build_commands[_HOME] = function()
    return 'lua modules/textadept/run/build.lua', _HOME .. '/test/' -- intentional trailing '/'
  end
  textadept.run.stop() -- should not do anything
  textadept.run.build(_HOME)
  if #_VIEWS > 1 then view:unsplit() end
  assert_equal(buffer._type, _L['[Message Buffer]'])
  os.execute('sleep 0.1') -- ensure process is running
  buffer:add_text('foo')
  buffer:new_line() -- should send previous line as stdin
  os.execute('sleep 0.1') -- ensure process processed stdin
  textadept.run.stop()
  ui.update() -- process output
  assert(buffer:get_text():find('> cd '), 'did not change directory')
  assert(buffer:get_text():find('build%.lua'), 'did not run build command')
  assert(buffer:get_text():find('read "foo"'), 'did not send stdin')
  assert(buffer:get_text():find('> exit status: 9'), 'build not stopped')
  textadept.run.stop() -- should not do anything
  buffer:close()
  -- TODO: chdir(_HOME) and textadept.run.build() -- no param.
  -- TODO: project whose makefile is autodetected.
end

function test_run_goto_internal_lua_error()
  xpcall(error, function(message) events.emit(events.ERROR, debug.traceback(message)) end, 'internal error', 2)
  if #_VIEWS > 1 then view:unsplit() end
  textadept.run.goto_error(LINE(1))
  assert(buffer.filename:find('/test/test%.lua$'), 'did not detect internal Lua error')
  view:unsplit()
  buffer:close()
  buffer:close()
end

-- TODO: test textadept.run.run_in_background

function test_session_save()
  local handler = function(session)
    session.baz = true
    session.quux = assert
    session.foobar = buffer.doc_pointer
    session.foobaz = coroutine.create(function() end)
  end
  events.connect(events.SESSION_SAVE, handler)
  buffer.new()
  buffer.filename = 'foo.lua'
  textadept.bookmarks.toggle()
  view:split()
  buffer.new()
  buffer.filename = 'bar.lua'
  local session_file = os.tmpname()
  textadept.session.save(session_file)
  local session = assert(loadfile(session_file, 't', {}))()
  assert_equal(session.buffers[#session.buffers - 1].filename, 'foo.lua')
  assert_equal(session.buffers[#session.buffers - 1].bookmarks, {1})
  assert_equal(session.buffers[#session.buffers].filename, 'bar.lua')
  assert_equal(session.ui.maximized, false)
  assert_equal(type(session.views[1]), 'table')
  assert_equal(session.views[1][1], #_BUFFERS - 1)
  assert_equal(session.views[1][2], #_BUFFERS)
  assert(not session.views[1].vertical, 'split vertical')
  assert(session.views[1].size > 1, 'split size not set properly')
  assert_equal(session.views.current, #_VIEWS)
  assert_equal(session.baz, true)
  assert(not session.quux, 'function serialized')
  assert(not session.foobar, 'userdata serialized')
  assert(not session.foobaz, 'thread serialized')
  view:unsplit()
  buffer:close()
  buffer:close()
  os.remove(session_file)
  events.disconnect(events.SESSION_SAVE, handler)
end

function test_snippets_find_snippet()
  snippets.foo = 'bar'
  textadept.snippets.paths[1] = _HOME .. '/test/modules/textadept/snippets'

  buffer.new()
  buffer:add_text('foo')
  assert(textadept.snippets.insert() == nil, 'snippet not inserted')
  assert_equal(buffer:get_text(), 'bar') -- from snippets
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'baz\n') -- from bar file
  buffer:delete_back()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'quux\n') -- from baz.txt file
  buffer:delete_back()
  assert(not textadept.snippets.insert(), 'snippet inserted')
  assert_equal(buffer:get_text(), 'quux')
  buffer:clear_all()
  buffer:set_lexer('lua') -- prefer lexer-specific snippets
  snippets.lua = {foo = 'baz'} -- overwrite language module
  buffer:add_text('foo')
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'baz') -- from snippets.lua
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'bar\n') -- from lua.baz.lua file
  buffer:delete_back()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'quux\n') -- from lua.bar file
  buffer:close(true)

  snippets.foo = nil
  table.remove(textadept.snippets.paths, 1)
end

function test_snippets_match_indentation()
  local snippet = '\t    foo'
  local multiline_snippet = table.concat({
    'foo',
    '\tbar',
    '\t    baz',
    'quux'
  }, '\n')
  buffer.new()

  buffer.use_tabs, buffer.tab_width, buffer.eol_mode = true, 4, buffer.EOL_CRLF
  textadept.snippets.insert(snippet)
  assert_equal(buffer:get_text(), '\t\tfoo')
  buffer:clear_all()
  buffer:add_text('\t')
  textadept.snippets.insert(snippet)
  assert_equal(buffer:get_text(), '\t\t\tfoo')
  buffer:clear_all()
  buffer:add_text('\t')
  textadept.snippets.insert(multiline_snippet)
  assert_equal(buffer:get_text(), table.concat({
    '\tfoo',
    '\t\tbar',
    '\t\t\tbaz',
    '\tquux'
  }, '\r\n'))
  buffer:clear_all()

  buffer.use_tabs, buffer.tab_width, buffer.eol_mode = false, 2, buffer.EOL_LF
  textadept.snippets.insert(snippet)
  assert_equal(buffer:get_text(), '      foo')
  buffer:clear_all()
  buffer:add_text('  ')
  textadept.snippets.insert(snippet)
  assert_equal(buffer:get_text(), '        foo')
  buffer:clear_all()
  buffer:add_text('  ')
  textadept.snippets.insert(multiline_snippet)
  assert_equal(buffer:get_text(), table.concat({
    '  foo',
    '    bar',
    '        baz',
    '  quux'
  }, '\n'))
  buffer:close(true)

  assert_raises(function() textadept.snippets.insert(true) end, 'string/nil expected, got boolean')
end

function test_snippets_placeholders()
  buffer.new()
  local lua_date = os.date()
  local p = io.popen('date')
  local shell_date = p:read()
  p:close()
  textadept.snippets.insert(table.concat({
    '%0placeholder: %1(foo) %2(bar)',
    'choice: %3{baz,quux}',
    'mirror: %2%3',
    'Lua: %<os.date()> %1<text:upper()>',
    'Shell: %[date] %1[echo %]',
    'escape: %%1 %4%( %4%{',
  }, '\n'))
  assert_equal(buffer.selections, 1)
  assert_equal(buffer.selection_start, POS(1) + 14)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  assert_equal(buffer:get_sel_text(), 'foo')
  buffer:replace_sel('baz')
  events.emit(events.UPDATE_UI, buffer.UPDATE_CONTENT + buffer.UPDATE_SELECTION) -- simulate typing
  assert_equal(buffer:get_text(), string.format(table.concat({
    ' placeholder: baz bar', -- placeholders to visit have 1 empty space
    'choice:  ', -- placeholder choices are initially empty
    'mirror:   ', -- placeholder mirrors are initially empty
    'Lua: %s BAZ', -- verify real-time transforms
    'Shell: %s baz', -- verify real-time transforms
    'escape: %%1  (  { ' -- trailing space for snippet sentinel
  }, '\n'), lua_date, shell_date))
  textadept.snippets.insert()
  assert_equal(buffer.selections, 2)
  assert_equal(buffer.selection_start, POS(1) + 18)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  for i = INDEX(1), INDEX(buffer.selections) do
    assert_equal(buffer.selection_n_end[i], buffer.selection_n_start[i] + 3)
    assert_equal(buffer:text_range(buffer.selection_n_start[i], buffer.selection_n_end[i]), 'bar')
  end
  assert(buffer:get_text():find('mirror: bar'), 'mirror not updated')
  textadept.snippets.insert()
  assert_equal(buffer.selections, 2)
  assert(buffer:auto_c_active(), 'no choice')
  buffer:auto_c_select('quux')
  buffer:auto_c_complete()
  assert(buffer:get_text():find('\nmirror: barquux\n'), 'choice mirror not updated')
  textadept.snippets.insert()
  assert_equal(buffer.selection_start, buffer.selection_end) -- no default placeholder (escaped)
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), string.format(table.concat({
    'placeholder: baz bar',
    'choice: quux',
    'mirror: barquux',
    'Lua: %s BAZ',
    'Shell: %s baz',
    'escape: %%1 ( {'
  }, '\n'), lua_date, shell_date))
  assert_equal(buffer.selection_start, POS(1))
  assert_equal(buffer.selection_start, POS(1))
  buffer:close(true)
end

function test_snippets_irregular_placeholders()
  buffer.new()
  textadept.snippets.insert('%1(foo %2(bar))%5(quux)')
  assert_equal(buffer:get_sel_text(), 'foo bar')
  buffer:delete_back()
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'quux')
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'quux')
  buffer:close(true)
end

function test_snippets_previous_cancel()
  buffer.new()
  textadept.snippets.insert('%1(foo) %2(bar) %3(baz)')
  assert_equal(buffer:get_text(), 'foo bar baz ') -- trailing space for snippet sentinel
  buffer:delete_back()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), ' bar baz ')
  buffer:delete_back()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), '  baz ')
  textadept.snippets.previous()
  textadept.snippets.previous()
  assert_equal(buffer:get_text(), 'foo bar baz ')
  assert_equal(buffer:get_sel_text(), 'foo')
  textadept.snippets.insert()
  textadept.snippets.cancel_current()
  assert_equal(buffer.length, 0)
  buffer:close(true)
end

function test_snippets_nested()
  snippets.foo = '%1(foo)%2(bar)%3(baz)'
  buffer.new()

  buffer:add_text('foo')
  textadept.snippets.insert()
  buffer:char_right()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'foobarbaz barbaz ') -- trailing spaces for snippet sentinels
  assert_equal(buffer:get_sel_text(), 'foo')
  assert_equal(buffer.selection_start, POS(1))
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  buffer:replace_sel('quux')
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'bar')
  assert_equal(buffer.selection_start, POS(1) + 4)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'baz')
  assert_equal(buffer.selection_start, POS(1) + 7)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer.current_pos, POS(1) + 10)
  assert_equal(buffer.selection_start, buffer.selection_end)
  assert_equal(buffer:get_text(), 'quuxbarbazbarbaz ')
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'bar')
  assert_equal(buffer.selection_start, POS(1) + 10)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'baz')
  assert_equal(buffer.selection_start, POS(1) + 13)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'quuxbarbazbarbaz')
  buffer:clear_all()

  buffer:add_text('foo')
  textadept.snippets.insert()
  buffer:char_right()
  textadept.snippets.insert()
  textadept.snippets.cancel_current()
  assert_equal(buffer.current_pos, POS(1) + 3)
  assert_equal(buffer.selection_start, buffer.selection_end)
  assert_equal(buffer:get_text(), 'foobarbaz ')
  buffer:add_text('quux')
  assert_equal(buffer:get_text(), 'fooquuxbarbaz ')
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'bar')
  assert_equal(buffer.selection_start, POS(1) + 7)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer:get_sel_text(), 'baz')
  assert_equal(buffer.selection_start, POS(1) + 10)
  assert_equal(buffer.selection_end, buffer.selection_start + 3)
  textadept.snippets.insert()
  assert_equal(buffer.current_pos, buffer.line_end_position[LINE(1)])
  assert_equal(buffer.selection_start, buffer.selection_end)
  assert_equal(buffer:get_text(), 'fooquuxbarbaz')

  buffer:close(true)
  snippets.foo = nil
end

function test_snippets_select_interactive()
  snippets.foo = 'bar'
  buffer.new()
  textadept.snippets.select()
  assert(buffer.length > 0, 'no snippet inserted')
  buffer:close(true)
  snippets.foo = nil
end

function test_snippets_autocomplete()
  snippets.bar = 'baz'
  snippets.baz = 'quux'
  buffer.new()
  buffer:add_text('ba')
  textadept.editing.autocomplete('snippet')
  assert(buffer:auto_c_active(), 'snippet autocompletion list not shown')
  buffer:auto_c_complete()
  textadept.snippets.insert()
  assert_equal(buffer:get_text(), 'baz')
  buffer:close(true)
  snippets.bar = nil
  snippets.baz = nil
end

function test_lua_autocomplete()
  buffer.new()
  buffer:set_lexer('lua')

  buffer:add_text('raw')
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'rawequal')
  buffer:auto_c_cancel()
  buffer:clear_all()

  buffer:add_text('string.')
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'byte')
  buffer:auto_c_cancel()
  buffer:clear_all()

  buffer:add_text('s = "foo"\ns:')
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'byte')
  buffer:auto_c_cancel()
  buffer:clear_all()

  buffer:add_text('f = io.open("path")\nf:')
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'close')
  buffer:auto_c_cancel()
  buffer:clear_all()

  buffer:add_text('buffer:auto_c')
  textadept.editing.autocomplete('lua')
  assert(not buffer:auto_c_active(), 'autocompletions available')
  buffer.filename = _HOME .. '/test/autocomplete_lua.lua'
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'auto_c_active')
  buffer:auto_c_cancel()
  buffer:clear_all()

  local autocomplete_snippets = _M.lua.autocomplete_snippets
  _M.lua.autocomplete_snippets = false
  buffer:add_text('for')
  textadept.editing.autocomplete('lua')
  assert(not buffer:auto_c_active(), 'autocompletions available')
  _M.lua.autocomplete_snippets = true
  textadept.editing.autocomplete('lua')
  assert(buffer:auto_c_active(), 'no autocompletions')
  buffer:auto_c_cancel()
  buffer:clear_all()
  _M.lua.autocomplete_snippets = autocomplete_snippets -- restore

  buffer:close(true)
end

function test_ansi_c_autocomplete()
  buffer.new()
  buffer:set_lexer('ansi_c')

  buffer:add_text('str');
  textadept.editing.autocomplete('ansi_c')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'strcat')
  buffer:auto_c_cancel()
  buffer:clear_all()

  buffer:add_text('div_t d;\nd->')
  textadept.editing.autocomplete('ansi_c')
  assert(buffer:auto_c_active(), 'no autocompletions')
  assert_equal(buffer.auto_c_current_text, 'quot')
  buffer:auto_c_cancel()
  buffer:clear_all()

  local autocomplete_snippets = _M.ansi_c.autocomplete_snippets
  _M.ansi_c.autocomplete_snippets = false
  buffer:add_text('for')
  textadept.editing.autocomplete('ansi_c')
  assert(not buffer:auto_c_active(), 'autocompletions available')
  _M.ansi_c.autocomplete_snippets = true
  textadept.editing.autocomplete('ansi_c')
  assert(buffer:auto_c_active(), 'no autocompletions')
  buffer:auto_c_cancel()
  buffer:clear_all()
  _M.ansi_c.autocomplete_snippets = autocomplete_snippets -- restore

  -- TODO: typeref and rescan

  buffer:close(true)
end

function test_lexer_api()
  buffer.new()
  buffer.use_tabs, buffer.tab_width = true, 4
  buffer:set_text(table.concat({
    'if foo then',
    '\tbar',
    '',
    'end',
    'baz'
  }, '\n'))
  buffer:set_lexer('lua')
  buffer:colorize(POS(1), -1)
  local lexer = require('lexer')
  assert(lexer.fold_level[LINE(1)] & lexer.FOLD_HEADER > 0, 'not a fold header')
  assert_equal(lexer.fold_level[LINE(2)], lexer.fold_level[LINE(3)])
  assert(lexer.fold_level[LINE(4)] > lexer.fold_level[LINE(5)], 'incorrect fold levels')
  assert(lexer.indent_amount[LINE(1)] < lexer.indent_amount[LINE(2)], 'incorrect indent level')
  assert(lexer.indent_amount[LINE(2)] > lexer.indent_amount[LINE(3)], 'incorrect indent level')
  lexer.line_state[LINE(1)] = 2
  assert_equal(lexer.line_state[LINE(1)], 2)
  assert_equal(lexer.property['foo'], '')
  lexer.property['foo'] = 'bar'
  assert_equal(lexer.property['foo'], 'bar')
  lexer.property['bar'] = '$(foo),$(foo)'
  assert_equal(lexer.property_expanded['bar'], 'bar,bar')
  lexer.property['baz'] = '1'
  assert_equal(lexer.property_int['baz'], 1)
  lexer.property['baz'] = ''
  assert_equal(lexer.property_int['baz'], 0)
  assert_equal(lexer.property_int['quux'], 0)
  assert_equal(lexer.style_at[2], 'keyword')
  assert_equal(lexer.line_from_position(15), LINE(2))
  buffer:close(true)

  assert_raises(function() lexer.fold_level = nil end, 'read-only')
  assert_raises(function() lexer.fold_level[LINE(1)] = 0 end, 'read-only')
  assert_raises(function() lexer.indent_amount = nil end, 'read-only')
  assert_raises(function() lexer.indent_amount[LINE(1)] = 0 end, 'read-only')
  assert_raises(function() lexer.property = nil end, 'read-only')
  assert_raises(function() lexer.property_int = nil end, 'read-only')
  assert_raises(function() lexer.property_int['foo'] = 1 end, 'read-only')
  --TODO: assert_raises(function() lexer.property_expanded = nil end, 'read-only')
  assert_raises(function() lexer.property_expanded['foo'] = 'bar' end, 'read-only')
  assert_raises(function() lexer.style_at = nil end, 'read-only')
  assert_raises(function() lexer.style_at[1] = 0 end, 'read-only')
  assert_raises(function() lexer.line_state = nil end, 'read-only')
  assert_raises(function() lexer.line_from_position = nil end, 'read-only')
end

function test_ui_size()
  local size = ui.size
  ui.size = {size[1] - 50, size[2] + 50}
  assert_equal(ui.size, size)
  ui.size = size
end

function test_ui_maximized()
  local maximized = ui.maximized
  ui.maximized = not maximized
  local not_maximized = ui.maximized
  ui.maximized = maximized -- reset
  -- For some reason, the following fails, even though the window maximized
  -- status is toggled. `ui.update()` does not seem to help.
  assert_equal(not_maximized, not maximized)
end
expected_failure(test_ui_maximized)

function test_reset()
  local _persist
  _G.foo = 'bar'
  reset()
  assert(not _G.foo, 'Lua not reset')
  _G.foo = 'bar'
  events.connect(events.RESET_BEFORE, function(persist)
    persist.foo = _G.foo
    _persist = persist -- store
  end)
  reset()
  -- events.RESET_AFTER has already been run, but there was no opportunity to
  -- connect to it in this test, so connect and simulate the event again.
  events.connect(events.RESET_AFTER, function(persist) _G.foo = persist.foo end)
  events.emit(events.RESET_AFTER, _persist)
  assert_equal(_G.foo, 'bar')
end

function test_timeout()
  if CURSES then
    assert_raises(function() timeout(1, function() end) end, 'not implemented')
    return
  end

  local count = 0
  local function f()
    count = count + 1
    return count < 2
  end
  timeout(0.4, f)
  assert_equal(count, 0)
  os.execute('sleep 0.5')
  ui.update()
  assert_equal(count, 1)
  os.execute('sleep 0.5')
  ui.update()
  assert_equal(count, 2)
  os.execute('sleep 0.5')
  ui.update()
  assert_equal(count, 2)
end

function test_view_split_resize_unsplit()
  view:split()
  local size = view.size
  view.size = view.size - 1
  assert_equal(view.size, size - 1)
  assert_equal(#_VIEWS, 2)
  view:split(true)
  size = view.size
  view.size = view.size + 1
  assert_equal(view.size, size + 1)
  assert_equal(#_VIEWS, 3)
  view:unsplit()
  assert_equal(#_VIEWS, 2)
  view:split(true)
  ui.goto_view(_VIEWS[1])
  view:unsplit() -- unsplits split view, leaving single view
  assert_equal(#_VIEWS, 1)
end

function test_view_split_refresh_styles()
  io.open_file(_HOME .. '/init.lua')
  local style = buffer:style_of_name('library')
  assert(style > 1, 'cannot retrieve number of library style')
  local color = view.style_fore[style]
  assert(color ~= view.style_fore[view.STYLE_DEFAULT], 'library style not set')
  view:split()
  for _, view in ipairs(_VIEWS) do
    local view_style = buffer:style_of_name('library')
    assert_equal(view_style, style)
    local view_color = view.style_fore[view_style]
    assert_equal(view_color, color)
  end
  view:unsplit()
  buffer:close(true)
end

function test_buffer_read_write_only_properties()
  assert_raises(function() view.all_lines_visible = false end, 'read-only property')
  assert_raises(function() return buffer.auto_c_fill_ups end, 'write-only property')
  assert_raises(function() buffer.annotation_text = {} end, 'read-only property')
  assert_raises(function() buffer.char_at[POS(1)] = string.byte(' ') end, 'read-only property')
  assert_raises(function() return view.marker_alpha[INDEX(1)] end, 'write-only property')
end

function test_set_theme()
  local current_theme = view.style_fore[view.STYLE_DEFAULT]
  view:split()
  io.open_file(_HOME .. '/init.lua')
  view:split(true)
  io.open_file(_HOME .. '/src/textadept.c')
  _VIEWS[2]:set_theme('dark')
  _VIEWS[3]:set_theme('light')
  assert(_VIEWS[2].style_fore[view.STYLE_DEFAULT] ~= _VIEWS[3].style_fore[view.STYLE_DEFAULT], 'same default styles')
  buffer:close(true)
  buffer:close(true)
  ui.goto_view(_VIEWS[1])
  view:unsplit()
end

function test_set_lexer_style()
  buffer.new()
  buffer:set_lexer('java')
  buffer:add_text('foo()')
  buffer:colorize(1, -1)
  local style = buffer:style_of_name('function')
  assert_equal(buffer.style_at[1], style)
  local default_fore = view.style_fore[view.STYLE_DEFAULT]
  assert(view.style_fore[style] ~= default_fore, 'function name style_fore same as default style_fore')
  view.style_fore[style] = view.style_fore[view.STYLE_DEFAULT]
  assert_equal(view.style_fore[style], default_fore)
  assert(lexer.colors.orange > 0 and lexer.colors.orange ~= default_fore)
  lexer.styles['function'] = {fore = lexer.colors.orange}
  assert_equal(view.style_fore[style], lexer.colors.orange)
  buffer:close(true)
  -- Defined in Lua lexer, which is not currently loaded.
  assert(buffer:style_of_name('library'), view.STYLE_DEFAULT)
  -- Emulate a theme setting to trigger an LPeg lexer style refresh, but without
  -- a token defined.
  view.property['style.library'] = view.property['style.library']
end

-- TODO: test init.lua's buffer settings

function test_ctags()
  local ctags = require('ctags')

  -- Setup project.
  local dir = os.tmpname()
  os.remove(dir)
  lfs.mkdir(dir)
  os.execute(string.format('cp -r %s/test/modules/ctags/c/* %s', _HOME, dir))
  lfs.mkdir(dir .. '/.hg') -- simulate version control
  local foo_h, foo_c = dir .. '/include/foo.h', dir .. '/src/foo.c'

  -- Generate tags and api.
  io.open_file(dir .. '/src/foo.c')
  textadept.menu.menubar[_L['Search']][_L['Ctags']][_L['Generate Project Tags and API']][2]()
  assert(lfs.attributes(dir .. '/tags'), 'tags file not generated')
  assert(lfs.attributes(dir .. '/api'), 'api file not generated')
  local f = io.open(dir .. '/api')
  local contents = f:read('a')
  f:close()
  assert(contents:find('main int main(int argc, char **argv) {', 1, true), 'did not properly generate api')

  -- Test `ctags.goto_tag()`.
  ctags.goto_tag('main')
  assert_equal(buffer.filename, foo_c)
  assert(buffer:get_cur_line():find('^int main%('), 'not at "main" function')
  buffer:line_down()
  buffer:vc_home()
  ctags.goto_tag() -- foo(FOO)
  assert_equal(buffer.filename, foo_h)
  assert(buffer:get_cur_line():find('^void foo%('), 'not at "foo" function')
  view:goto_buffer(-1) -- back to src/foo.c
  assert_equal(buffer.filename, foo_c)
  buffer:word_right()
  buffer:word_right()
  ctags.goto_tag() -- FOO
  assert_equal(buffer.filename, foo_h)
  assert(buffer:get_cur_line():find('^#define FOO 1'), 'not at "FOO" definition')

  -- Test tag autocompletion.
  buffer:line_end()
  buffer:new_line()
  buffer:add_text('m')
  textadept.editing.autocomplete('ctag')
  assert(buffer:get_cur_line():find('^main'), 'did not autocomplete "main" function')

  -- Test `ctags.goto_tag()` with custom tags path.
  ctags.ctags_flags[dir] = '-R ' .. dir -- for writing absolute paths
  textadept.menu.menubar[_L['Search']][_L['Ctags']][_L['Generate Project Tags and API']][2]()
  os.execute(string.format('mv %s/tags %s/src', dir, dir))
  assert(not lfs.attributes(dir .. '/tags') and lfs.attributes(dir .. '/src/tags'), 'did not move tags file')
  ctags[dir] = dir .. '/src/tags'
  ctags.goto_tag('main')
  assert_equal(buffer.filename, foo_c)
  assert(buffer:get_cur_line():find('^int main%('), 'not at "main" function')

  -- Test `ctags.goto_tag()` with no tags file and using current file contents.
  os.remove(dir .. '/src/tags')
  assert(not lfs.attributes(dir .. '/src/tags'), 'did not remove tags file')
  buffer:line_down()
  buffer:line_down()
  buffer:vc_home()
  ctags.goto_tag() -- bar()
  assert_equal(buffer.filename, foo_c)
  assert(buffer:get_cur_line():find('^void bar%('))

  view:goto_buffer(1)
  buffer:close(true)
  buffer:close(true)
  os.execute('rm -r ' .. dir)
end

function test_ctags_lua()
  local ctags = require('ctags')

  -- Setup project.
  local dir = os.tmpname()
  os.remove(dir)
  lfs.mkdir(dir)
  os.execute(string.format('cp -r %s/test/modules/ctags/lua/* %s', _HOME, dir))
  lfs.mkdir(dir .. '/.hg') -- simulate version control

  -- Generate tags and api.
  io.open_file(dir .. '/foo.lua')
  ctags.ctags_flags[dir] = '-R ' .. ctags.LUA_FLAGS
  textadept.menu.menubar[_L['Search']][_L['Ctags']][_L['Generate Project Tags and API']][2]()
  assert(lfs.attributes(dir .. '/tags'), 'tags file not generated')
  assert(lfs.attributes(dir .. '/api'), 'api file not generated')

  if not CURSES then -- TODO: cannot properly spawn with ctags.LUA_FLAGS on curses
    ctags.goto_tag('foo')
    assert(buffer:get_cur_line():find('^function foo%('), 'not at "foo" function')
    ctags.goto_tag('bar')
    assert(buffer:get_cur_line():find('^local function bar%('), 'not at "bar" function')
    ctags.goto_tag('baz')
    assert(buffer:get_cur_line():find('^baz = %{'), 'not at "baz" table')
    ctags.goto_tag('quux')
    assert(buffer:get_cur_line():find('^function baz:quux%('), 'not at "baz.quux" function')
  end

  -- Test using Textadept's tags and api generator.
  ctags.ctags_flags[dir] = ctags.LUA_GENERATOR
  ctags.api_commands[dir] = ctags.LUA_GENERATOR
  textadept.menu.menubar[_L['Search']][_L['Ctags']][_L['Generate Project Tags and API']][2]()
  ctags.goto_tag('new')
  assert(buffer:get_cur_line():find('^function M%.new%('), 'not at "M.new" function')
  local f = io.open(dir .. '/api')
  local contents = f:read('a')
  f:close()
  assert(contents:find('new foo%.new%(%)\\nFoo'), 'did not properly generate api')

  buffer:close(true)
  os.execute('rm -r ' .. dir)
end

function test_export_interactive()
  local export = require('export')
  buffer.new()
  buffer:add_text("_G.foo=table.concat{1,'bar',true,print}\nbar=[[<>& ]]")
  buffer:set_lexer('lua')
  local filename = os.tmpname()
  export.to_html(nil, filename)
  _G.timeout(0.5, function() os.remove(filename) end)
  buffer:close(true)
end

function test_file_diff()
  local diff = require('file_diff')

  local filename1 = _HOME .. '/test/modules/file_diff/1'
  local filename2 = _HOME .. '/test/modules/file_diff/2'
  io.open_file(filename1)
  io.open_file(filename2)
  view:split()
  ui.goto_view(-1)
  view:goto_buffer(-1)
  diff.start('-', '-')
  assert_equal(#_VIEWS, 2)
  assert_equal(view, _VIEWS[1])
  local buffer1, buffer2 = _VIEWS[1].buffer, _VIEWS[2].buffer
  assert_equal(buffer1.filename, filename1)
  assert_equal(buffer2.filename, filename2)

  local function verify(buffer, markers, indicators, annotations)
    for i = 1, buffer.line_count do
      if not markers[i] then
        assert(buffer:marker_get(i) == 0, 'unexpected marker on line %d', i)
      else
        assert(buffer:marker_get(i) & 1 << markers[i] - 1 > 0, 'incorrect marker on line %d', i)
      end
      if not annotations[i] then
        assert(buffer.annotation_text[i] == '', 'unexpected annotation on line %d', i)
      else
        assert(buffer.annotation_text[i] == annotations[i], 'incorrect annotation on line %d', i)
      end
    end
    for _, indic in ipairs{diff.INDIC_DELETION, diff.INDIC_ADDITION} do
      local s = buffer:indicator_end(indic, 1)
      local e = buffer:indicator_end(indic, s)
      while s < buffer.length and e > s do
        local text = buffer:text_range(s, e)
        assert(indicators[text] == indic, 'incorrect indicator for "%s"', text)
        s = buffer:indicator_end(indic, e)
        e = buffer:indicator_end(indic, s)
      end
    end
  end

  -- Verify line markers.
  verify(buffer1, {
    [1] = diff.MARK_MODIFICATION,
    [2] = diff.MARK_MODIFICATION,
    [3] = diff.MARK_MODIFICATION,
    [4] = diff.MARK_MODIFICATION,
    [5] = diff.MARK_MODIFICATION,
    [6] = diff.MARK_MODIFICATION,
    [7] = diff.MARK_MODIFICATION,
    [12] = diff.MARK_MODIFICATION,
    [14] = diff.MARK_MODIFICATION,
    [15] = diff.MARK_MODIFICATION,
    [16] = diff.MARK_DELETION
  }, {
    ['is'] = diff.INDIC_DELETION,
    ['line\n'] = diff.INDIC_DELETION,
    ['    '] = diff.INDIC_DELETION,
    ['+'] = diff.INDIC_DELETION,
    ['pl'] = diff.INDIC_DELETION,
    ['one'] = diff.INDIC_DELETION,
    ['wo'] = diff.INDIC_DELETION,
    ['three'] = diff.INDIC_DELETION,
    ['will'] = diff.INDIC_DELETION
  }, {[11] = ' \n'})
  verify(buffer2, {
    [1] = diff.MARK_MODIFICATION,
    [2] = diff.MARK_MODIFICATION,
    [3] = diff.MARK_MODIFICATION,
    [4] = diff.MARK_MODIFICATION,
    [5] = diff.MARK_MODIFICATION,
    [6] = diff.MARK_MODIFICATION,
    [7] = diff.MARK_MODIFICATION,
    [12] = diff.MARK_ADDITION,
    [13] = diff.MARK_ADDITION,
    [14] = diff.MARK_MODIFICATION,
    [16] = diff.MARK_MODIFICATION,
    [17] = diff.MARK_MODIFICATION
  }, {
    ['at'] = diff.INDIC_ADDITION,
    ['paragraph\n    '] = diff.INDIC_ADDITION,
    ['-'] = diff.INDIC_ADDITION,
    ['min'] = diff.INDIC_ADDITION,
    ['two'] = diff.INDIC_ADDITION,
    ['\t'] = diff.INDIC_ADDITION,
    ['hree'] = diff.INDIC_ADDITION,
    ['there are '] = diff.INDIC_ADDITION,
    ['four'] = diff.INDIC_ADDITION,
    ['have'] = diff.INDIC_ADDITION,
    ['d'] = diff.INDIC_ADDITION
  }, {[17] = ' '})

  -- Stop comparing, verify the buffers are restored to normal, and then start
  -- comparing again.
  textadept.menu.menubar[_L['Tools']][_L['Compare Files']][_L['Stop Comparing']][2]()
  verify(buffer1, {}, {}, {})
  verify(buffer2, {}, {}, {})
  textadept.menu.menubar[_L['Tools']][_L['Compare Files']][_L['Compare Buffers']][2]()

  -- Test goto next/prev change.
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
  diff.goto_change()
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
  diff.goto_change()
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 15)
  diff.goto_change()
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
  diff.goto_change()
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 7)
  ui.goto_view(1)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 1)
  diff.goto_change(true)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 12)
  diff.goto_change(true)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 14)
  diff.goto_change(true)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 16)
  diff.goto_change(true)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 17)
  diff.goto_change(true)
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 1)
  diff.goto_change()
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 17)
  diff.goto_change()
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 14)
  diff.goto_change()
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 13)
  diff.goto_change()
  assert_equal(buffer2:line_from_position(buffer2.current_pos), 7)
  ui.goto_view(-1)
  buffer1:goto_line(1)

  -- Merge first block right to left and verify.
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
  diff.merge(true)
  assert(buffer1:get_line(1):find('^that'), 'did not merge from right to left')
  local function verify_first_merge()
    for i = 1, 7 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
    verify(buffer1, {
      [12] = diff.MARK_MODIFICATION,
      [14] = diff.MARK_MODIFICATION,
      [15] = diff.MARK_MODIFICATION,
      [16] = diff.MARK_DELETION
    }, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {[11] = ' \n'})
    verify(buffer2, {
      [12] = diff.MARK_ADDITION,
      [13] = diff.MARK_ADDITION,
      [14] = diff.MARK_MODIFICATION,
      [16] = diff.MARK_MODIFICATION,
      [17] = diff.MARK_MODIFICATION
    }, {
      ['four'] = diff.INDIC_ADDITION,
      ['have'] = diff.INDIC_ADDITION,
      ['d'] = diff.INDIC_ADDITION
    }, {[17] = ' '})
  end
  verify_first_merge()
  -- Undo, merge left to right, and verify.
  buffer1:undo()
  buffer1:goto_line(1)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 1)
  diff.merge()
  assert(buffer2:get_line(1):find('^this'), 'did not merge from left to right')
  verify_first_merge()

  if CURSES then goto curses_skip end do -- TODO: curses chokes trying to automate this

  -- Go to next difference, merge second block right to left, and verify.
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
  ui.update()
  diff.merge(true)
  assert(buffer1:get_line(12):find('^%('), 'did not merge from right to left')
  for i = 12, 13 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
  verify(buffer1, {
    [14] = diff.MARK_MODIFICATION,
    [16] = diff.MARK_MODIFICATION,
    [17] = diff.MARK_MODIFICATION,
    [18] = diff.MARK_DELETION
  }, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {})
  verify(buffer2, {
    [14] = diff.MARK_MODIFICATION,
    [16] = diff.MARK_MODIFICATION,
    [17] = diff.MARK_MODIFICATION
  }, {
    ['four'] = diff.INDIC_ADDITION,
    ['have'] = diff.INDIC_ADDITION,
    ['d'] = diff.INDIC_ADDITION
  }, {[17] = ' '})
  -- Undo, merge left to right, and verify.
  buffer1:undo()
  buffer1:goto_line(11)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 11)
  diff.merge()
  assert(buffer2:get_line(12):find('^be changed'), 'did not merge from left to right')
  verify(buffer1, {
    [12] = diff.MARK_MODIFICATION,
    [14] = diff.MARK_MODIFICATION,
    [15] = diff.MARK_MODIFICATION,
    [16] = diff.MARK_DELETION
  }, {['three'] = diff.INDIC_DELETION, ['will'] = diff.INDIC_DELETION}, {})
  verify(buffer2, {
    [12] = diff.MARK_MODIFICATION,
    [14] = diff.MARK_MODIFICATION,
    [15] = diff.MARK_MODIFICATION
  }, {
    ['four'] = diff.INDIC_ADDITION,
    ['have'] = diff.INDIC_ADDITION,
    ['d'] = diff.INDIC_ADDITION
  }, {[15] = ' '})

  -- Already on next difference; merge third block from right to left, and
  -- verify.
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
  diff.merge(true)
  assert(buffer1:get_line(12):find('into four'), 'did not merge from right to left')
  assert_equal(buffer1:get_line(12), buffer2:get_line(12))
  local function verify_third_merge()
    verify(buffer1, {
      [14] = diff.MARK_MODIFICATION,
      [15] = diff.MARK_MODIFICATION,
      [16] = diff.MARK_DELETION
    }, {['will'] = diff.INDIC_DELETION}, {})
    verify(buffer2, {
      [14] = diff.MARK_MODIFICATION,
      [15] = diff.MARK_MODIFICATION
    }, {['have'] = diff.INDIC_ADDITION, ['d'] = diff.INDIC_ADDITION}, {[15] = ' '})
  end
  verify_third_merge()
  -- Undo, merge left to right, and verify.
  buffer1:undo()
  buffer1:goto_line(12)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 12)
  diff.merge()
  assert(buffer2:get_line(12):find('into three'), 'did not merge from left to right')
  verify_third_merge()

  -- Go to next difference, merge fourth block from right to left, and verify.
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
  diff.merge(true)
  assert(buffer1:get_line(14):find('have'), 'did not merge from right to left')
  local function verify_fourth_merge()
    for i = 14, 15 do assert_equal(buffer1:get_line(i), buffer2:get_line(i)) end
    verify(buffer1, {[16] = diff.MARK_DELETION}, {}, {})
    verify(buffer2, {}, {}, {[15] = ' '})
  end
  verify_fourth_merge()
  -- Undo, merge left to right, and verify.
  buffer1:undo()
  buffer1:goto_line(14)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 14)
  diff.merge()
  assert(buffer2:get_line(14):find('will'), 'did not merge from left to right')
  verify_fourth_merge()

  -- Go to next difference, merge fifth block from right to left, and verify.
  diff.goto_change(true)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
  diff.merge(true)
  assert(buffer1:get_line(16):find('^\n'), 'did not merge from right to left')
  local function verify_fifth_merge()
    assert_equal(buffer1.length, buffer2.length)
    for i = 1, buffer1.length do
      assert_equal(buffer1:get_line(i), buffer2:get_line(i))
    end
    verify(buffer1, {}, {}, {})
    verify(buffer2, {}, {}, {})
  end
  verify_fifth_merge()
  -- Undo, merge left to right, and verify.
  buffer1:undo()
  buffer1:goto_line(16)
  assert_equal(buffer1:line_from_position(buffer1.current_pos), 16)
  diff.merge()
  assert(buffer2:get_line(16):find('^%('), 'did not merge from left to right')
  verify_fifth_merge()

  -- Test scroll synchronization.
  _VIEWS[1].x_offset = 50
  ui.update()
  assert_equal(_VIEWS[2].x_offset, _VIEWS[1].x_offset)
  _VIEWS[1].x_offset = 0
  -- TODO: test vertical synchronization

  end ::curses_skip::
  textadept.menu.menubar[_L['Tools']][_L['Compare Files']][_L['Stop Comparing']][2]()
  ui.goto_view(_VIEWS[#_VIEWS])
  buffer:close(true)
  ui.goto_view(-1)
  view:unsplit()
  buffer:close(true)
  -- Make sure nothing bad happens.
  diff.goto_change()
  diff.merge()
end

function test_file_diff_interactive()
  local diff = require('file_diff')
  diff.start(_HOME .. '/test/modules/file_diff/1')
  assert_equal(#_VIEWS, 2)
  textadept.menu.menubar[_L['Tools']][_L['Compare Files']][_L['Stop Comparing']][2]()
  local different_files = _VIEWS[1].buffer.filename ~= _VIEWS[2].buffer.filename
  ui.goto_view(1)
  buffer:close(true)
  view:unsplit()
  if different_files then buffer:close(true) end
end

function test_history()
  local history = require('history')
  history.disable_listening() -- clear preexisting history
  history.enable_listening()
  local filename1 = _HOME .. '/test/modules/history/1'
  io.open_file(filename1)
  buffer:goto_line(5)
  history.back() -- should not do anything (ignore initial file load)
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 5)
  buffer:add_text('foo')
  buffer:goto_line(5 + history.minimum_line_distance + 1)
  history.back()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 5)
  assert_equal(buffer.current_pos, buffer.line_end_position[5])
  history.forward() -- should stay put (no edits have been made since)
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 5)
  buffer:new_line()
  buffer:add_text('bar') -- close changes should update current history
  local filename2 = _HOME .. '/test/modules/history/2'
  io.open_file(filename2)
  buffer:goto_line(10)
  buffer:add_text('baz')
  history.back() -- should ignore initial file load and go back to file 1
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 6)
  history.back() -- should stay put (updated history from line 5 to line 6)
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 6)
  history.forward()
  assert_equal(buffer.filename, filename2)
  assert_equal(buffer:line_from_position(buffer.current_pos), 10)
  history.back()
  buffer:goto_line(15)
  buffer:clear() -- erases forward history to file 2
  history.forward() -- should not do anything
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 15)
  history.back()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 6)
  history.forward()
  view:goto_buffer(1)
  assert_equal(buffer.filename, filename2)
  buffer:goto_line(20)
  buffer:add_text('quux')
  view:goto_buffer(-1)
  assert_equal(buffer.filename, filename1)
  buffer:undo() -- undo delete of '\n'
  buffer:undo() -- undo add of 'foo'
  buffer:redo() -- re-add 'foo'
  history.back() -- undo and redo should not affect history
  assert_equal(buffer.filename, filename2)
  assert_equal(buffer:line_from_position(buffer.current_pos), 20)
  history.back()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 15)
  history.back()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 6)
  buffer:target_whole_document()
  buffer:replace_target(string.rep('\n', buffer.line_count)) -- whole buffer replacements should not affect history (e.g. clang-format)
  history.forward()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 15)
  view:goto_buffer(1)
  assert_equal(buffer.filename, filename2)
  buffer:close(true)
  history.forward() -- should re-open file 2
  assert_equal(buffer.filename, filename2)
  assert_equal(buffer:line_from_position(buffer.current_pos), 20)
  buffer:close(true)
  buffer:close(true)
end

function test_history_per_view()
  local history = require('history')
  history.disable_listening() -- clear preexisting history
  history.enable_listening()
  local filename1 = _HOME .. '/test/modules/history/1'
  io.open_file(filename1)
  buffer:goto_line(5)
  buffer:add_text('foo')
  buffer:goto_line(10)
  buffer:add_text('bar')
  view:split()
  history.back() -- no history for this view
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 10)
  local filename2 = _HOME .. '/test/modules/history/2'
  io.open_file(filename2)
  buffer:goto_line(15)
  buffer:add_text('baz')
  buffer:goto_line(20)
  history.back()
  assert_equal(buffer.filename, filename2)
  assert_equal(buffer:line_from_position(buffer.current_pos), 15)
  history.back() -- no more history for this view
  assert_equal(buffer.filename, filename2)
  assert_equal(buffer:line_from_position(buffer.current_pos), 15)
  ui.goto_view(-1)
  history.back()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 5)
  history.forward()
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 10)
  history.forward() -- no more history for this view
  assert_equal(buffer.filename, filename1)
  assert_equal(buffer:line_from_position(buffer.current_pos), 10)
  view:unsplit()
  view:goto_buffer(1)
  buffer:close(true)
  buffer:close(true)
end

function test_spellcheck()
  local spellcheck = require('spellcheck')
  local SPELLING_ID = 1 -- not accessible
  buffer:new()
  buffer:add_text('-- foo bar\nbaz = "quux"')

  -- Test background highlighting.
  spellcheck.check_spelling()
  local function get_misspellings()
    local misspellings = {}
    local s = buffer:indicator_end(spellcheck.INDIC_SPELLING, 1)
    local e = buffer:indicator_end(spellcheck.INDIC_SPELLING, s)
    while e > s do
      misspellings[#misspellings + 1] = buffer:text_range(s, e)
      s = buffer:indicator_end(spellcheck.INDIC_SPELLING, e)
      e = buffer:indicator_end(spellcheck.INDIC_SPELLING, s)
    end
    return misspellings
  end
  assert_equal(get_misspellings(), {'foo', 'baz', 'quux'})
  buffer:set_lexer('lua')
  spellcheck.check_spelling()
  assert_equal(get_misspellings(), {'foo', 'quux'})

  -- Test interactive parts.
  spellcheck.check_spelling(true)
  assert(buffer:auto_c_active(), 'no misspellings')
  local s, e = buffer.current_pos, buffer:word_end_position(buffer.current_pos)
  assert_equal(buffer:text_range(s, e), 'foo')
  buffer:cancel()
  events.emit(events.USER_LIST_SELECTION, 1, 'goo', s)
  assert_equal(buffer:text_range(s, e), 'goo')
  ui.update()
  if CURSES then spellcheck.check_spelling() end -- not needed when interactive
  spellcheck.check_spelling(true)
  assert(buffer:auto_c_active(), 'spellchecker not active')
  s, e = buffer.current_pos, buffer:word_end_position(buffer.current_pos)
  assert_equal(buffer:text_range(s, e), 'quux')
  buffer:cancel()
  events.emit(events.INDICATOR_CLICK, s)
  assert(buffer:auto_c_active(), 'spellchecker not active')
  buffer:cancel()
  events.emit(events.USER_LIST_SELECTION, 1, '(Ignore)', s)
  assert_equal(get_misspellings(), {})
  spellcheck.check_spelling(true)
  assert(not buffer:auto_c_active(), 'misspellings')

  -- TODO: test add.

  buffer:close(true)
end

-- Load buffer and view API from their respective LuaDoc files.
local function load_buffer_view_props()
  local buffer_props, view_props = {}, {}
  for name, props in pairs{buffer = buffer_props, view = view_props} do
    for line in io.lines(string.format('%s/core/.%s.luadoc', _HOME, name)) do
      if line:find('@field') then
        props[line:match('@field ([%w_]+)')] = true
      elseif line:find('^function') then
        props[line:match('^function ([%w_]+)')] = true
      end
    end
  end
  return buffer_props, view_props
end

local function check_property_usage(filename, buffer_props, view_props)
  print(string.format('Processing file "%s"', filename:gsub(_HOME, '')))
  local line_num, count = 1, 0
  for line in io.lines(filename) do
    for pos, id, prop in line:gmatch('()([%w_]+)[.:]([%w_]+)') do
      if id == 'M' or id == 'f' or id == 'p' or id == 'lexer' or id == 'spawn_proc' then goto continue end
      if id == 'textadept' and prop == 'MARK_BOOKMARK' then goto continue end
      if (id == 'ui' or id == 'split') and prop == 'size' then goto continue end
      if id == 'keys' and prop == 'home' then goto continue end
      if id == 'Rout' and prop == 'save' then goto continue end
      if id == 'detail' and (prop == 'filename' or prop == 'column') then goto continue end
      if (id == 'placeholder' or id == 'ph') and prop == 'length' then goto continue end
      if id == 'client' and prop == 'close' then goto continue end
      if (id == 'Foo' or id == 'Array' or id == 'Server') and prop == 'new' then goto continue end
      if buffer_props[prop] then
        assert(
          id == 'buffer' or id == 'buf' or id == 'buffer1' or id == 'buffer2',
          'line %d:%d: "%s" should be a buffer property', line_num, pos, prop)
        count = count + 1
      elseif view_props[prop] then
        assert(
          id == 'view', 'line %d:%d: "%s" should be a view property', line_num,
          pos, prop)
        count = count + 1
      end
      ::continue::
    end
    line_num = line_num + 1
  end
  print(string.format('Checked %d buffer/view property usages.', count))
end

function test_buffer_view_usage()
  local buffer_props, view_props = load_buffer_view_props()
  local filter = {
    '.lua', '.luadoc', '!/lexers', '!/modules/lsp/dkjson.lua',
    '!/modules/lua/lua.luadoc', '!/modules/debugger/lua/mobdebug.lua',
    '!/modules/yaml/lyaml.lua', '!/scripts', '!/src'
  }
  for filename in lfs.walk(_HOME, filter) do
    check_property_usage(filename, buffer_props, view_props)
  end
end

--------------------------------------------------------------------------------

assert(not WIN32 and not OSX, 'Test suite currently only runs on Linux')

local TEST_OUTPUT_BUFFER = '[Test Output]'
function print(...) ui._print(TEST_OUTPUT_BUFFER, ...) end
-- Clean up after a previously failed test.
local function cleanup()
  while #_BUFFERS > 1 do
    if buffer._type == TEST_OUTPUT_BUFFER then view:goto_buffer(1) end
    buffer:close(true)
  end
  while view:unsplit() do end
end

-- Determines whether or not to run the test whose name is string *name*.
-- If no arg patterns are provided, returns true.
-- If only inclusive arg patterns are provided, returns true if *name* matches
-- at least one of those patterns.
-- If only exclusive arg patterns are provided ('-' prefix), returns true if
-- *name* does not match any of them.
-- If both inclusive and exclusive arg patterns are provided, returns true if
-- *name* matches at least one of the inclusive ones, but not any of the
-- exclusive ones.
-- @param name Name of the test to check for inclusion.
-- @return true or false
local function include_test(name)
  if #arg == 0 then return true end
  local include, includes, excludes = false, false, false
  for _, patt in ipairs(arg) do
    if patt:find('^%-') then
      if name:find(patt:sub(2)) then return false end
      excludes = true
    else
      if name:find(patt) then include = true end
      includes = true
    end
  end
  return include or not includes and excludes
end

local tests = {}
for k in pairs(_ENV) do
  if k:find('^test_') and include_test(k) then
    tests[#tests + 1] = k
  end
end
table.sort(tests)

print('Starting test suite')

local tests_run, tests_failed, tests_failed_expected = 0, 0, 0

for i = 1, #tests do
  cleanup()
  assert_equal(#_BUFFERS, 1)
  assert_equal(#_VIEWS, 1)

  _ENV = setmetatable({}, {__index = _ENV})
  local name, f, attempts = tests[i], _ENV[tests[i]], 1
  print(string.format('Running %s', name))
  ui.update()
  local ok, errmsg = xpcall(f, function(errmsg)
    local fail = not expected_failures[f] and 'Failed!' or 'Expected failure.'
    return string.format('%s %s', fail, debug.traceback(errmsg, 3))
  end)
  ui.update()
  if not errmsg then
    if #_BUFFERS > 1 then
      ok, errmsg = false, 'Failed! Test did not close the buffer(s) it created'
    elseif #_VIEWS > 1 then
      ok, errmsg = false, 'Failed! Test did not unsplit the view(s) it created'
    elseif expected_failures[f] then
      ok, errmsg = false, 'Failed! Test should have failed'
      expected_failures[f] = nil
    end
  end
  print(ok and 'Passed.' or errmsg)

  tests_run = tests_run + 1
  if not ok then
    tests_failed = tests_failed + 1
    if expected_failures[f] then
      tests_failed_expected = tests_failed_expected + 1
    end
  end
end

print(string.format('%d tests run, %d unexpected failures, %d expected failures', tests_run, tests_failed - tests_failed_expected, tests_failed_expected))

-- Note: stock luacov crashes on hook.lua lines 51 and 58 every other run.
-- `file.max` and `file.max_hits` are both `nil`, so change comparisons to be
-- `(file.max or 0)` and `(file.max_hits or 0)`, respectively.
if package.loaded['luacov'] then
  require('luacov').save_stats()
  os.execute('luacov')
  local f = assert(io.open('luacov.report.out'))
  buffer:append_text(f:read('a'):match('\nSummary.+$'))
  f:close()
else
  buffer:new_line()
  buffer:append_text('No LuaCov coverage to report.')
end
buffer:set_save_point()

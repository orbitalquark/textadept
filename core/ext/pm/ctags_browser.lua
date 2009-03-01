-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- CTags Browser for the Textadept project manager.
-- It is enabled with the prefix 'ctags' in the project manager entry field
-- followed by either nothing or ':' and the path to a ctags file. If no path
-- is specified, the current file is parsed via ctags and its structure shown.
module('textadept.pm.browsers.ctags', package.seeall)

if not RESETTING then textadept.pm.add_browser('ctags') end

local FILE_OUT = '/tmp/textadept_output'

---
-- The current ctags file and current directory.
-- When a ctags file is opened, current_dir is set to its dirname.
local current_file, current_dir

---
-- The table of ctags with property values.
-- Each key is the name of a ctags identifier (function, class, etc.) and the
-- value is a table containing:
--   * The GTK stock-id for the pixbuf to display next to the identifier in the
--     tree view (pixbuf key).
--   * The display text used for displaying the identifier in the tree view
--     (text key).
--   * Boolean parent value if the identifier is a container.
--   * The line number or pattern used to goto the identifier.
-- Note this table is returned by get_contents_for, but only 'pixbuf',
-- 'text' and 'parent' fields are read; all others are ignored.
-- @class table
-- @name tags
local tags

---
-- Table of associations of tag identifier types for specific languages with
-- GTK stock-id pixbufs.
-- @class table
-- @name pixbuf
local pixbuf = {
  lua = { f = 'prog-method' },
  ruby = {
    c = 'prog-class',
    f = 'prog-method',
    F = 'prog-method',
    m = 'prog-namespace'
  },
  cpp = {
    c = 'prog-class',
    e = 'prog-enum',
    f = 'prog-method',
    g = 'prog-enum',
    m = 'prog-field',
    n = 'prog-namespace',
    s = 'prog-struct'
  }
}

---
-- Table of associations of file extensions with languages.
-- @class table
-- @name language
local language = {
  lua = 'lua',
  rb = 'ruby',
  h = 'cpp', c = 'cpp', cxx = 'cpp' -- C++
}

---
-- Table used to determine if a tag kind is a container or not in a specific
-- language.
-- Top-level keys are language names from the languages table with table
-- values. These table values have tag kind keys with boolean values indicating
-- if they are containers or not.
-- @class table
-- @name container
-- @return true if the tag kind is a container.
-- @see language
local container = {
  lua = {},
  ruby = { c = true, m = true },
  cpp = { c = true, g = true, s = true }
}

---
-- Table used to determine if a construct name is a container or not in a
-- specific language.
-- Top-level keys are language names from the languages table with table
-- values. These table values have construct name keys with boolean values
-- indicating if they are containers or not.
-- @class table
-- @name container_construct
-- @return true if the construct name is a container.
-- @see language
local container_construct = {
  lua = {},
  ruby = { class = true, module = true },
  cpp = { class = true, enum = true, struct = true }
}

--- Matches 'ctags:[/absolute/path/to/ctags/file]'
function matches(entry_text)
  return entry_text:sub(1, 5) == 'ctags'
end

---
-- If not expanding, creates the entire tree; otherwise returns the child table
-- of the parent being expanded.
function get_contents_for(full_path, expanding)
  local ctags_file = full_path[1]:sub(7) -- ignore 'ctags:'
  local f
  if #ctags_file == 0 then
    tags = {}
    current_file = nil
    current_dir = '' -- ctags file will specify absolute paths
    os.execute('ctags -f "'..FILE_OUT..'" '..(buffer.filename or ''))
    f = io.open(FILE_OUT, 'rb')
    if not f then return {} end
  elseif not expanding then
    tags = {}
    current_file = ctags_file
    current_dir = ctags_file:match('^.+/') -- ctags file dirname
    f = io.open(ctags_file, 'rb')
    if not f then return {} end
  else
    local parent = tags
    for i = 2, #full_path do
      local identifier = full_path[i]
      if not parent[identifier] then return {} end
      parent = parent[identifier].children
    end
    return parent
  end
  for line in f:lines() do
    if line:sub(1, 2) ~= '!_' then
      -- Parse ctags line to get identifier attributes.
      local name, filepath, pattern, line_num, ext
      name, filepath, pattern, ext =
        line:match('^([^\t]+)\t([^\t]+)\t/^(.+)$/;"\t(.*)$')
      if not name then
        name, filepath, line_num, ext =
          line:match('^([^\t]+)\t([^\t]+)\t(%d+);"\t(.*)$')
      end
      -- If the ctag line is parsed correctly, create the entry.
      if name and #name > 0 then
        local entry = {}
        local file_ext = filepath:match('%.([^.]+)$')
        local lang = language[file_ext]
        if lang then
          -- Parse the extension fields for details on if this identifier is a
          -- child or parent and where to put it.
          local fields = {}
          --print(ext)
          for key, val in ext:gmatch('([^:%s]+):?(%S*)') do
            if #val == 0 and #key == 1 then -- kind
              if container[lang][key] then
                -- This identifier is a container. Place it in the toplevel of
                -- tags.
                entry.parent = true
                entry.children = {}
                if tags[name] then
                  -- If previously defined by a child, preserve the children
                  -- field.
                  entry.children = tags[name].children
                end
                tags[name] = entry
                entry.set = true
              end
              entry.pixbuf = pixbuf[lang][key]
            elseif container_construct[lang][key] then
              -- This identifier belongs to a container, so define the
              -- container if it hasn't been already and place this identifier
              -- in it. Just in case there is no ctag entry for container later
              -- on, define 'parent' and 'text'.
              if not tags[val] then
                tags[val] = { parent = true, text = val }
              end
              local parent = tags[val]
              if not parent.children then parent.children = {} end
              parent.children[name] = entry -- add to parent
              entry.set = true
            end
          end
          entry.text = name
          -- The following keys are ignored by caller.
          entry.filepath =
            filepath:sub(1, 1) == '/' and filepath or current_dir..filepath
          entry.pattern = pattern
          entry.line_num = line_num
          if not entry.set then tags[name] = entry end
        else
          print(string.format(locale.PM_BROWSER_CTAGS_BAD_EXT, file_ext))
        end
      else
        print(string.format(locale.PM_BROWSER_CTAGS_UNMATCHED, line))
      end
    end
  end
  f:close()
  return tags
end

function perform_action(selected_item)
  local item = tags
  for i = 2, #selected_item do
    local identifier = selected_item[i]
    item = item[identifier]
    if item.children then item = item.children end
  end
  if item.pattern then
    local buffer_text = buffer:get_text(buffer.length)
    local search_text = item.pattern:gsub('\\/', '/')
    local s = buffer_text:find(search_text, 1, true)
    if s then
      textadept.io.open(item.filepath)
      local line = buffer:line_from_position(s)
      buffer:ensure_visible_enforce_policy(line)
      buffer:goto_line(line)
    else
      error(
        string.format(locale.PM_BROWSER_CTAGS_NOT_FOUND, item.text))
    end
  elseif item.line_num then
    textadept.io.open(item.filepath)
    buffer:goto_line(item.line_num - 1)
  end
  view:focus()
end

function get_context_menu(selected_item)

end

function perform_menu_action(menu_id, selected_item)

end

local function update_view()
  if matches(textadept.pm.entry_text) then
    if buffer.filename then
      textadept.pm.activate()
    else
      textadept.pm.clear()
    end
  end
end
textadept.events.add_handler('file_opened', update_view)
textadept.events.add_handler('buffer_deleted', update_view)
textadept.events.add_handler('buffer_switch', update_view)
textadept.events.add_handler('save_point_reached', update_view)

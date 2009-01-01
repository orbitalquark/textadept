-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Find in files browser for the Textadept project manager.
-- It is enabled with the prefix 'find' in the project manager entry field.
module('textadept.pm.browsers.find', package.seeall)

---
-- The directory recursively searched. If pm.search_directory is not specified,
-- defaults to the current working directory.
local search_directory

---
-- The table of file matches.
-- Each key is a filename and the value is a table containing the usual as well
-- as a children key that contains entries for line number matches.
-- @class table
-- @name find_matches
local find_matches

--- Matches 'file:search text' (search text can contain spaces)
function matches(entry_text)
  return entry_text:sub(1, 4) == 'find'
end

---
-- If not expanding, creates the entire tree; otherwise returns the child table
-- of the parent being expanded.
function get_contents_for(full_path, expanding)
  local search_string, recursive
  if full_path[1]:sub(1, 5) == 'findr' then
    search_string = full_path[1]:sub(7) -- ignore 'findr:'
    recursive = true
  else
    search_string = full_path[1]:sub(6) -- ignore 'find:'
    recursive = false
  end
  if #search_string == 0 then return {} end
  if expanding then
    local parent = find_matches
    for i = 2, #full_path do
      local filename = full_path[i]
      if not parent[filename] then return {} end
      parent = parent[filename].children
    end
    return parent
  else
    find_matches = {}
    local p
    search_directory = _G.textadept.pm.search_directory
    if not search_directory then
      p = io.popen('pwd')
      search_directory = p:read('*all'):match('^[^\n]+')
      p:close()
    end
    search_string = search_string:gsub('"', '\\"')
    search_directory = search_directory:gsub('"', '\\"')
    local opts = 'nH'..(recursive and 'r' or '')
    p = io.popen('grep -'..opts..' "'..search_string..'" "'..
                 search_directory..'"')
    for line in p:lines() do
      local filename, line_num, line_text = line:match('^([^:]+):(%d+):%s-(.+)$')
      if filename and line_num and line_text then
        if not find_matches[filename] then
          find_matches[filename] = {
            parent = true,
            children = {},
            display_text = filename
          }
        end
        local entry = {}
        entry.display_text = line_num..':'..line_text
        entry.line_num = line_num
        entry.filepath = filename
        find_matches[filename].children[line_num] = entry
      end
    end
    p:close()
    return find_matches
  end
end

function perform_action(selected_item)
  local item = find_matches
  for i = 2, #selected_item do
    local match = selected_item[i]
    item = item[match]
    if item.children then item = item.children end
  end
  textadept.io.open(item.filepath)
  buffer:goto_line(item.line_num - 1)
  view:focus()
end

function get_context_menu(selected_item)

end

function perform_menu_action(menu_item, selected_item)

end

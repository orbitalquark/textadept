-- Copyright 2007-2026 Mitchell. See LICENSE.

--- See [buffer](#the-buffer-module).
-- @module view

--- A table of style properties that can be concatenated with other tables of properties.
local style_object = {}
style_object.__index = style_object

--- Creates a new style object.
-- @param props Table of style properties to use.
local function style_obj(props)
	local style = {}
	for k, v in pairs(props) do style[k] = v end
	return setmetatable(style, style_object)
end

--- Returns a new style object with a set of merged properties.
-- @param props Table of style properties to merge into this one.
-- @local
function style_object:__concat(props)
	local style = style_obj(self) -- copy
	for k, v in pairs(assert_type(props, 'table', 2)) do style[k] = v end
	return style
end

--- Applies a style's settings to a view.
-- @param view View to apply style settings to.
-- @param style_num Style number to set the style for.
local function set_style(view, style_num)
	local styles = buffer ~= ui.command_entry and view.styles or _G.view.styles
	local style = styles[style_num] or styles[buffer:name_of_style(style_num):gsub('%.', '_')]
	if style then for k, v in pairs(style) do view['style_' .. k][style_num] = v end end
end

-- Documentation is in core/buffer.lua.
local function set_styles(view)
	if buffer == ui.command_entry then view = ui.command_entry end
	view:style_reset_default()
	set_style(view, view.STYLE_DEFAULT)
	view:style_clear_all()
	local num_styles, num_predefined = buffer.named_styles, 8 -- DEFAULT to FOLDDISPLAYTEXT
	for i = 1, math.max(num_styles - num_predefined, view.STYLE_DEFAULT - 1) do set_style(view, i) end
	for i = view.STYLE_DEFAULT + 1, view.STYLE_FOLDDISPLAYTEXT do set_style(view, i) end
	for i = view.STYLE_FOLDDISPLAYTEXT + 1, num_styles do set_style(view, i) end
end

-- Documentation is in core/buffer.lua.
local function set_theme(view, name, env)
	if not name or type(name) == 'table' then name, env = _THEME, name end
	if not assert_type(name, 'string', 2):find('[/\\]') then
		name = package.searchpath(name,
			string.format('%s/themes/?.lua;%s/themes/?.lua', _USERHOME, _HOME))
	end
	if not name or not lfs.attributes(name) then return end
	if not assert_type(env, 'table/nil', 3) then env = {} end
	env.view = view
	for style_name in pairs(view.styles) do view.styles[style_name] = nil end -- reset
	assert(loadfile(name, 't', setmetatable(env, {__index = _G})))()
	view:set_styles()
end

--- Metatable for `view.styles`, whose documentation is in core/buffer.lua.
local styles_mt = {
	__index = function(t, k) return type(k) == 'string' and t[k:match('^(.+)[_%.]')] or rawget(t, k) end,
	__newindex = function(t, k, v)
		rawset(t, type(k) == 'string' and k:gsub('%.', '_') or k, style_obj(assert_type(v, 'table', 3)))
	end
}

events.connect(events.VIEW_NEW, function()
	local view = buffer ~= ui.command_entry and view or ui.command_entry
	view.colors, view.styles = {}, setmetatable({}, styles_mt)
	view.set_styles, view.set_theme = set_styles, set_theme
end, 1)

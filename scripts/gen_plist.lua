#!/usr/bin/lua
-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

-- This script generates the "Info.plist" file for the Mac OSX App bundle.

local lang, exts
local languages, extensions = {}, {}

-- Read languages and extensions.
local f = io.open('../modules/textadept/file_types.lua')
local types = f:read('*all'):match('M.extensions = (%b{})'):sub(2)
f:close()
for type in types:gmatch('(.-)[%],}]+') do
  if type:find('^%-%-') then
    lang, exts = type:match('([^%[]+)$'), {}
    if lang then languages[#languages + 1], extensions[lang] = lang, exts end
  else
    exts[#exts + 1] = type:match('^%[?\'?([^\'=]+)')
  end
end

-- Generate and write the XML.
local xml = {[[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleDocumentTypes</key>
	<array>]]}
for i = 1, #languages do
  lang, exts = languages[i], extensions[languages[i]]
  if #exts > 0 then
    xml[#xml + 1] = "\t\t<dict>"
    xml[#xml + 1] = "\t\t\t<key>CFBundleTypeExtensions</key>"
    xml[#xml + 1] = "\t\t\t<array>"
    for j = 1, #exts do
      xml[#xml + 1] = "\t\t\t\t<string>"..exts[j].."</string>"
    end
    xml[#xml + 1] = "\t\t\t</array>"
    xml[#xml + 1] = "\t\t\t<key>CFBundleTypeName</key>"
    xml[#xml + 1] = "\t\t\t<string>"..lang.." source</string>"
    xml[#xml + 1] = "\t\t\t<key>CFBundleTypeRole</key>"
    xml[#xml + 1] = "\t\t\t<string>Editor</string>"
    xml[#xml + 1] = "\t\t</dict>"
  end
end
xml[#xml + 1] = [[
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>*</string>
			</array>
			<key>CFBundleTypeName</key>
			<string>Document</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Document</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>****</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>textadept_osx</string>
	<key>CFBundleIconFile</key>
	<string>textadept.icns</string>
	<key>CFBundleIdentifier</key>
	<string>com.textadept</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Textadept</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>7.0 beta</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
]]
f = io.open('../src/Info.plist', 'w')
f:write(table.concat(xml, '\n'))
f:close()

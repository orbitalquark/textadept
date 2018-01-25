#!/usr/bin/lua
-- Copyright 2007-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

-- This script generates the "Info.plist" file for the Mac OSX App bundle.

local lang, exts
local languages, extensions = {}, {}

-- Read languages and extensions.
local f = io.open('../modules/textadept/file_types.lua')
local types = f:read('*a'):match('M.extensions = (%b{})'):sub(2)
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
	<key>CFBundleDocumentTypes</key>]]}
xml[#xml + 1] = [[
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Textadept document</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.apple.property-list</string>
				<string>com.apple.applescript.text</string>
				<string>com.apple.xcode.commands</string>
				<string>com.apple.xcode.csh-script</string>
				<string>com.apple.xcode.ksh-script</string>
				<string>com.apple.xcode.lex-source</string>
				<string>com.apple.xcode.make-script</string>
				<string>com.apple.xcode.mig-source</string>
				<string>com.apple.xcode.tcsh-script</string>
				<string>com.apple.xcode.yacc-source</string>
				<string>com.apple.xcode.zsh-script</string>
				<string>com.apple.xml-property-list</string>
				<string>com.netscape.javascript-source</string>
				<string>com.sun.java-source</string>]]
for i = 1, #languages do
  lang, exts = languages[i], extensions[languages[i]]
  if #exts > 0 then
    xml[#xml + 1] = "\t\t\t\t<string>com.textadept."..lang:gsub(' ', '-')..
                    "-source</string>"
  end
end
xml[#xml + 1] = [[
				<string>net.daringfireball.markdown</string>
				<string>public.c-header</string>
				<string>public.c-plus-plus-header </string>
				<string>public.c-plus-plus-source</string>
				<string>public.c-source</string>
				<string>public.csh-script</string>
				<string>public.css</string>
				<string>public.html</string>
				<string>public.lex-source</string>
				<string>public.mig-source</string>
				<string>public.objective-c-plus-plus-source</string>
				<string>public.objective-c-source</string>
				<string>public.perl-script</string>
				<string>public.php-script</string>
				<string>public.plain-text</string>
				<string>public.python-script</string>
				<string>public.rtf</string>
				<string>public.ruby-script</string>
				<string>public.script</string>
				<string>public.shell-script</string>
				<string>public.source-code</string>
				<string>public.text</string>
				<string>public.utf16-external-plain-text</string>
				<string>public.utf16-plain-text</string>
				<string>public.utf8-plain-text</string>
				<string>public.xml</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Anything</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.data</string>
				<string>public.text</string>
			</array>
		</dict>
	</array>
	<key>UTImportedTypeDeclarations</key>
	<array>]]
for i = 1, #languages do
  lang, exts = languages[i], extensions[languages[i]]
  if #exts > 0 then
    xml[#xml + 1] = "\t\t<dict>"
    xml[#xml + 1] = "\t\t\t<key>UTTypeTagSpecification</key>"
    xml[#xml + 1] = "\t\t\t<dict>"
    xml[#xml + 1] = "\t\t\t\t<key>public.filename-extension</key>"
    xml[#xml + 1] = "\t\t\t\t<array>"
    for j = 1, #exts do
      xml[#xml + 1] = "\t\t\t\t\t<string>"..exts[j].."</string>"
    end
    xml[#xml + 1] = "\t\t\t\t</array>"
    xml[#xml + 1] = "\t\t\t</dict>"
    xml[#xml + 1] = "\t\t\t<key>UTTypeDescription</key>"
    xml[#xml + 1] = "\t\t\t<string>"..lang.." source</string>"
    xml[#xml + 1] = "\t\t\t<key>UTTypeIdentifier</key>"
    xml[#xml + 1] = "\t\t\t<string>com.textadept."..lang:gsub(' ', '-')..
                    "-source</string>"
    xml[#xml + 1] = "\t\t\t<key>UTTypeConformsTo</key>"
    xml[#xml + 1] = "\t\t\t<array>"
    xml[#xml + 1] = "\t\t\t\t<string>public.source-code</string>"
    xml[#xml + 1] = "\t\t\t</array>"
    xml[#xml + 1] = "\t\t</dict>"
  end
end
xml[#xml + 1] = [[
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
	<string>9.5beta</string>
	<key>CFBundleShortVersionString</key>
	<string>9.5 beta</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
]]
f = io.open('../src/Info.plist', 'w')
f:write(table.concat(xml, '\n'))
f:close()

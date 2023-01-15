#!/bin/bash
# Copyright 2022-2023 Mitchell. See LICENSE.

# Generates Textadept's documentation.
# Requires LuaDoc and Discount.

# Generate API documentation using LuaDoc.
cd ../scripts
lua_src="../core ../modules/ansi_c ../modules/lua ../modules/textadept ../lexers/lexer.lua"
luadoc --doclet markdowndoc $lua_src > ../docs/api.md

# Generate HTML from Markdown (docs/*.html from docs/*.md)
cd ../docs
for file in `ls *.md`; do
  cat _layouts/default.html | ../scripts/fill_layout.lua $file > `basename -s .md $file`.html
done

# Generate Lua tags and api documentation files using LuaDoc.
cd ../modules
luadoc -d lua --doclet lua.tadoc $lua_src --ta-home=`realpath ..`
mv lua/tags lua/ta_tags
mv lua/api lua/ta_api
luadoc -d lua --doclet lua.tadoc lua/lua.luadoc --ta-home=`realpath ..`

# Update version information in Manual and API documentation.
cd ../docs
version=`grep -m 1 _RELEASE ../core/init.lua | cut -d ' ' -f4- | tr -d "'"`
sed -i "s/\(\# Textadept\).\+\?\(Manual\|API\)/\1 $version \2/;" *.md

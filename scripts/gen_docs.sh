#!/bin/bash
# Copyright 2022-2024 Mitchell. See LICENSE.

# Generates Textadept's documentation.
# Requires LDoc and Discount.

if [ "`uname`" = "Darwin" ]; then
	sed () {
		gsed "$@"
	}
fi

# Update API documentation, if possible. (This is unnecessary on end-user machines.)
if command -v ldoc &>/dev/null; then
	ldoc -c ../.config.ld --filter scripts.markdowndoc.ldoc . > ../docs/api.md
	line=`grep -m1 -n '#' ../docs/api.md | cut -d: -f1` # strip any leading LDoc stdout
	sed -i -e "1,$(( $line - 1 ))d" ../docs/api.md
fi

# Generate HTML from Markdown (docs/*.html from docs/*.md)
cd ../docs
for file in `ls *.md`; do
	cat _layouts/default.html | ../scripts/fill_layout.lua $file > `basename -s .md $file`.html
done

# Update version information in Manual and API documentation.
cd ../docs
version=`grep -m 1 _RELEASE ../core/init.lua | cut -d ' ' -f4- | tr -d "'"`
sed -i "s/\(\# Textadept\).\+\?\(Manual\|API\)/\1 $version \2/;" *.md

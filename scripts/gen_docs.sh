#!/bin/bash
# Copyright 2022-2026 Mitchell. See LICENSE.

# Generates Textadept's API documentation.
# Requires LDoc and Ruby.

if [ "$(uname)" == "Darwin" ]; then
	sed () {
		gsed "$@"
	}
fi

# Update API documentation, if possible. (This is unnecessary on end-user machines.)
if command -v ldoc &>/dev/null; then
	ldoc -c ../.config.ld --filter scripts.markdowndoc.ldoc . --title="Textadept API Documentation" \
		> ../docs/api.md
	line=$(grep -m1 -n '#' ../docs/api.md | cut -d: -f1) # strip any leading LDoc stdout
	sed -i -e "1,$(( $line - 1 ))d" ../docs/api.md
fi

# Update version information in Manual and API documentation.
cd ../docs
version=$(grep -m 1 _RELEASE ../core/init.lua | cut -d ' ' -f4- | tr -d "'")
sed -i "s/\(\# Textadept\).\+\?\(Manual\|API\)/\1 $version \2/;" *.md

# Build html pages.
pushd ../docs
rm -f *.html # prevent any previous docs from being copied
bundle install
if [ -z "$LANG" ]; then export LANG="en_US.UTF-8"; fi
bundle exec jekyll build --quiet
cp _site/*.html .
sed -i 's|href="/|href="|g;' *.html
cp -r _site/assets/css assets
rm -rf _site vendor
popd

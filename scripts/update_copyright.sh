#!/bin/bash
# Copyright 2025-2026 Mitchell. See LICENSE.
# Updates the copyright year of repository files.

if [ "$(uname)" == "Darwin" ]; then
	sed () {
		gsed "$@"
	}
fi

new_year=2026
prev_year=$(( $new_year - 1 ))
repo=$(git rev-parse --show-toplevel)
skip='\.\(icns\|ico\|svg\|png\)$'

git ls-files $repo | grep -v $skip | xargs sed -i '' -e "s/\-$prev_year M/-$new_year M/;"
git ls-files $repo | grep -v $skip | xargs sed -i '' -e "s/ $prev_year M/ $prev_year-$new_year M/;"

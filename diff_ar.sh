#!/bin/bash
# Creates an archive useable by diff/patch as a base directory.
# Archives are actually tar with an additionnal compression (LZMA), but not directly "7z" or such, which may not be comparable by the delta tool (rdiff, xdelta3) the same way.
#
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4

archive="$(basename "$1")$archiveSuffix"

rm "archive" > /dev/null
if [[ "$has_pv" != "0" ]]; then
	XZ_OPT=-9 tar -Jcf - --directory="$1" . | pv > "$archive"
	res=${PIPESTATUS[0]}
else
	XZ_OPT=-9 tar -acf "$archive" --directory="$1" . --checkpoint=.10
	res="$?"
fi

if [[ "$res" == "0" ]]; then echo "Created '$archive'."; fi
exit "$res"

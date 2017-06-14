#!/bin/bash
# Creates an archive useable by diff/patch as a base directory.
# Archives are actually tar with an additionnal compression (LZMA2), but not directly "7z" or such, which may not be comparable by the delta tool (rdiff, xdelta3) the same way.
#
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)
# To-do: make this script accept arguments, have an help & usage, etc.

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4

archive="$(basename "$1")$archiveSuffix"

rm "$archive" 2> /dev/null
if [[ "$has_pv" != "0" ]]; then
	tar -Jcf - --directory="$1" . | pv > "$archive"
	res=${PIPESTATUS[0]}
else
	tar -acf "$archive" --directory="$1" . --checkpoint=.10
	res="$?"
fi

if (( $verbosity >= 1 )); then
	if [[ "$res" == "0" ]]; then echo "Created '$archive'."; fi
fi
exit "$res"

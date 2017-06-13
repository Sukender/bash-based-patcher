#!/bin/bash
# Unit test for Sukender's rdiff-based patcher.
# This is veeeeeery basic, and should be improved with true unit test framework(s).
#
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)
# Version (of the unit test): 0.1
# Version (of the tested tool): 0.2

# TODO:
#  - Test patch upload / retreival
#  - Test various options (especially -p)

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
#initDir="$PWD"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4

baseDir="_diff_unit_test"

#set -e
err_report() {
	echo "Error on line $1"
	cd "$DIR"
	rm -r "$baseDir"
	exit 1
}
trap 'err_report $LINENO' ERR

# --------------------------------------------------------------------------------
# Test 1 - Simple patch creation/application

# Clear
rm -rf "$baseDir"

# Setup
mkdir -p "$baseDir/1"
mkdir -p "$baseDir/2"

cd "$baseDir"

echo "aaaaaa" > "1/a.txt"			# Will be updated
echo "bbbbbbbbbb" > "1/b.txt"		# Will be deleted
echo "ccccc" > "1/c.txt"			# Will be left as-is

echo "aaaaaa v2!" > "2/a.txt"
cp "1/c.txt" "2/c.txt"
echo "ddd-dddddddd-ddddd" > "2/d.txt"		# Will be added

# Operate
"$DIR/diff.sh" "1" "2" -p delta.patch		# Build
"$DIR//patch.sh" "1" -p delta.patch "2_"	# Apply

# Test
if [ ! -f "2_/a.txt" ]; then err_report $LINENO; fi
if [   -f "2_/b.txt" ]; then err_report $LINENO; fi
if [ ! -f "2_/c.txt" ]; then err_report $LINENO; fi
if [ ! -f "2_/d.txt" ]; then err_report $LINENO; fi

read line < "2_/a.txt"; if [ "$line" != "aaaaaa v2!"         ]; then err_report $LINENO; fi
read line < "2_/c.txt"; if [ "$line" != "ccccc"              ]; then err_report $LINENO; fi
read line < "2_/d.txt"; if [ "$line" != "ddd-dddddddd-ddddd" ]; then err_report $LINENO; fi

# Clear
cd -
rm -rf "$baseDir"

echo ""
echo $separatorDisplay
echo "$toolName: Tests sucessful"

#!/bin/bash
# Unit test for Sukender's bash-based patcher.
# This is veeeeeery basic, and should be improved with true unit test framework(s).
#
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)

# TODO:
#  - Test patch upload / retreival
#  - Test various options (especially -p)

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
#initDir="$PWD"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4
export defaultVerbosity=0		# Globally change verbosity

baseDir="_diff_unit_test"

#set -e
err_report() {
	echo "Error on line $1"
	cd "$DIR"
	rm -r "$baseDir" 2> /dev/null
	exit 1
}
trap 'err_report $LINENO' ERR

testLabel() {
	#if (( $verbosity >= 1 )); then
	echo ""
	echo "*** Entering test: $1 ***"
}

# --------------------------------------------------------------------------------
# Test 1 - Simple patch creation/application

testSimple_Setup() {
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
}

testSimple_Test() {
	if [ ! -f "2_/a.txt" ]; then err_report $LINENO; fi
	if [   -f "2_/b.txt" ]; then err_report $LINENO; fi
	if [ ! -f "2_/c.txt" ]; then err_report $LINENO; fi
	if [ ! -f "2_/d.txt" ]; then err_report $LINENO; fi

	read line < "2_/a.txt"; if [ "$line" != "aaaaaa v2!"         ]; then err_report $LINENO; fi
	read line < "2_/c.txt"; if [ "$line" != "ccccc"              ]; then err_report $LINENO; fi
	read line < "2_/d.txt"; if [ "$line" != "ddd-dddddddd-ddddd" ]; then err_report $LINENO; fi
}

# testSimple deltaTool
testSimple() {
	testLabel "Simple $1"

	# Setup
	testSimple_Setup

	# Operate
	"$diffTool" -D "$1" "1" "2" -p delta.patch       # Build
	"$patchTool" -D "$1" "1" -p delta.patch "2_"    # Apply

	# Test
	testSimple_Test

	# Clear
	cd -
	rm -rf "$baseDir"
}

# Test may fallback to another delta tool. This is intended.
testSimple "rdiff"
testSimple "xdelta3"

# --------------------------------------------------------------------------------
# Test 2 - As test 1 but base directory may now be an archive

# testFromArchive deltaTool diffSourceName patchSourceName
testFromArchive() {
	testLabel "archive $1 '$2' '$3'"

	# Setup
	testSimple_Setup   # As the previous test
	"$arTool" "1"      # Create archive
	#rm -r "1"         # Remove original "1"

	# Operate
	"$diffTool" -D "$1" "$2" "2" -p delta.patch       # Build
	"$patchTool" -D "$1" "$3" -p delta.patch "2_"     # Apply

	# Test
	testSimple_Test    # As the previous test

	# Clear
	cd -
	rm -rf "$baseDir"
}

testFromArchive "xdelta3" "1$archiveSuffix" "1$archiveSuffix"    # Build from archive, apply from archive
testFromArchive "xdelta3" "1" "1$archiveSuffix"                  # Build from directory, apply from archive
testFromArchive "xdelta3" "1$archiveSuffix" "1"                  # Build from archive, apply from directory

testFromArchive "rdiff"   "1$archiveSuffix" "1$archiveSuffix"    # Build from archive, apply from archive
testFromArchive "rdiff"   "1" "1$archiveSuffix"                  # Build from directory, apply from archive
testFromArchive "rdiff"   "1$archiveSuffix" "1"                  # Build from archive, apply from directory

# --------------------------------------------------------------------------------

echo ""
echo $separatorDisplay
echo "$toolName: Tests sucessful"

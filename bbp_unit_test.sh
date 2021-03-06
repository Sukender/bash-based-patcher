#!/bin/bash
# Unit test for Sukender's bash-based patcher.
# This is veeeeeery basic, and should be improved with true unit test framework(s).
#
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)

# TODO:
#  - Test patch upload / retreival

# Dependencies, error codes, documentation: see "bbp_config.sh"
#initDir="$PWD"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/bbp_config.sh" || exit 4

export defaultVerbosity=0		# Globally change verbosity
#set -x  # Debug bash
#set +e  # Continue on error

baseDir="_diff_unit_test"

err_report() {
	echo "Error on line ${1}"
	if [ -n "${2:-}" ]; then echo "Result: $2"; fi
	cd "$DIR"
	rm -r "$baseDir" 2> /dev/null || true
	exit 1
}
trap 'err_report ${LINENO}' ERR

testLabel() {
	#if (( $verbosity >= 1 )); then
	echo ""
	echo "*** Entering test: $1 ***"
}

# --------------------------------------------------------------------------------
# Test - Some utility functions

testLabel "Utility functions"

# *** Patch name generation and parsing ***

res="$(autoPatchName "subdir" "subdir2/")"		# One with trailing slash, one without
if [ "$res" != "Patch_(subdir)_to_(subdir2).xz" ]; then err_report $LINENO "$res"; fi

res="$(autoPatchName "some dir/some subdir" "some dir2/some subdir2/")"		# One with trailing slash, one without
if [ "$res" != "Patch_(some subdir)_to_(some subdir2).xz" ]; then err_report $LINENO "$res"; fi

res="$(autoPatchName "some dir/some subdir$archiveSuffix" "some dir2/some subdir2$archiveSuffix")"
if [ "$res" != "Patch_(some subdir)_to_(some subdir2).xz" ]; then err_report $LINENO "$res"; fi

res="$(extractNewName "some dir/some patch")"
if [ -n "$res" ]; then err_report $LINENO "$res"; fi

res="$(extractNewName "Patch_(old name)_to_(new name).xz")"
if [ "$res" != "new name" ]; then err_report $LINENO "$res"; fi

res="$(extractNewName "./Patch_(old name)_to_(new name).xz")"
if [ "$res" != "new name" ]; then err_report $LINENO "$res"; fi

res="$(extractNewName "some dir/Patch_(_to_(old name)_to_(new @name (a.b)).xz")"
if [ "$res" != "new @name (a.b)" ]; then err_report $LINENO "$res"; fi

res="$(extractUrlName "http://some.server.com/some/dir/some cool patch.xz")"
if [ "$res" != "some cool patch.xz" ]; then err_report $LINENO "$res"; fi

res="$(extractUrlName "dummy://dummy/dummy/ab%20c+%28d+ef%29%21")"
if [ "$res" != "ab c (d ef)!" ]; then err_report $LINENO "$res"; fi

# *** bbpinfo ***

res="$("$infoTool" "dummyName")"
if [[ ! "$res" =~ ^UNKNOWN ]]; then err_report $LINENO "$res"; fi

# --------------------------------------------------------------------------------
# Test - Archive

testLabel "Archiving"

# Clear
rm -rf "$baseDir"

# Operate & test
mkdir -p "$baseDir"
echo "abcdefghijklmnopq" > "$baseDir/aaa"

"$arTool" "$baseDir"
rm -rf "$baseDir"

if [ ! -f "$baseDir$archiveSuffix" ]; then err_report $LINENO "$res"; fi
if [   -d "$baseDir" ]; then err_report $LINENO "$res"; fi

"$arTool" x "$baseDir$archiveSuffix"
if [ ! -d "$baseDir" ]; then err_report $LINENO "$res"; fi
if [ ! -f "$baseDir/aaa" ]; then err_report $LINENO "$res"; fi
read line < "$baseDir/aaa"; if [ "$line" != "abcdefghijklmnopq" ]; then err_report $LINENO; fi

rm -rf "$baseDir" "$baseDir$archiveSuffix"

# --------------------------------------------------------------------------------
# Test - Simple patch creation/application

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
	head -c 100000 /dev/urandom > "1/e" # Will be completely new
	head -c 100000 /dev/urandom > "1/f" # Will be renamed

	echo "aaaaaa v2!" > "2/a.txt"
	cp "1/c.txt" "2/c.txt"
	echo "ddd-dddddddd-ddddd" > "2/d.txt"	# Will be added
	head -c 110000 /dev/urandom > "2/e"
	cp "1/f" "2/f2"
}

testSimple_Test() {
	if [ ! -f "2_/a.txt" ]; then err_report $LINENO; fi
	if [   -f "2_/b.txt" ]; then err_report $LINENO; fi
	if [ ! -f "2_/c.txt" ]; then err_report $LINENO; fi
	if [ ! -f "2_/d.txt" ]; then err_report $LINENO; fi
	if [ ! -f "2_/e"     ]; then err_report $LINENO; fi
	if [   -f "2_/f"     ]; then err_report $LINENO; fi
	if [ ! -f "2_/f2"    ]; then err_report $LINENO; fi

	read line < "2_/a.txt"; if [ "$line" != "aaaaaa v2!"         ]; then err_report $LINENO; fi
	read line < "2_/c.txt"; if [ "$line" != "ccccc"              ]; then err_report $LINENO; fi
	read line < "2_/d.txt"; if [ "$line" != "ddd-dddddddd-ddddd" ]; then err_report $LINENO; fi
	eSize="$(du -sb "2_/e" | awk '{ print $1 }')"
	if (( eSize != 110000 )); then err_report $LINENO; fi
	eSize="$(du -sb "2_/f2" | awk '{ print $1 }')"
	if (( eSize != 100000 )); then err_report $LINENO; fi
}

# testSimple deltaTool
testSimple() {
	testLabel "Simple $1"

	# Setup
	testSimple_Setup

	# Operate
	"$diffTool" -D "$1" "1" "2" -p delta.patch    # Build
	"$patchTool" "1" -p delta.patch -o "2_"       # Apply
	rm delta.patch

	# Test
	testSimple_Test

	# Clear
	cd "$DIR" > /dev/null
	rm -rf "$baseDir"
}

# Test may fallback to another delta tool. This is intended.
testSimple "rdiff"
testSimple "xdelta3"

# --------------------------------------------------------------------------------
# Test - As test 1 but base directory may now be an archive

# testFromArchive deltaTool diffSourceName patchSourceName
testFromArchive() {
	testLabel "Archive $1 / '$2' '$3' / '$4'"

	# Setup
	testSimple_Setup   # As the previous test
	"$arTool" "1"      # Create archive
	if [[ "$3" == *$archiveExtension ]]; then
		"$arTool" "2"      # Create archive if 'new' is an archive
	fi
	#rm -r "1"         # Remove original "1"

	# Operate
	"$diffTool" -D "$1" "$2" "$3"     # Build
	"$patchTool" "$4" -o "2_"         # Apply
	local patchfile="$(autoPatchName "$2" "$3")"
	rm "$patchfile"

	# Test
	testSimple_Test    # As the previous test

	# Clear
	cd "$DIR" > /dev/null
	rm -rf "$baseDir"
}

testFromArchive "xdelta3" "1$archiveSuffix" "2" "1$archiveSuffix"    # Build from archive/directory, apply from archive
testFromArchive "xdelta3" "1" "2" "1$archiveSuffix"                  # Build from directory/directory, apply from archive
testFromArchive "xdelta3" "1$archiveSuffix" "2" "1"                  # Build from archive/directory, apply from directory

testFromArchive "rdiff"   "1$archiveSuffix" "2" "1$archiveSuffix"    # Build from archive/directory, apply from archive
testFromArchive "rdiff"   "1" "2" "1$archiveSuffix"                  # Build from directory/directory, apply from archive
testFromArchive "rdiff"   "1$archiveSuffix" "2" "1"                  # Build from archive/directory, apply from directory

testFromArchive "xdelta3" "1$archiveSuffix" "2$archiveSuffix" "1$archiveSuffix"    # Build from archive/archive, apply from archive
testFromArchive "rdiff"   "1$archiveSuffix" "2$archiveSuffix" "1$archiveSuffix"    # Build from archive/archive, apply from archive

# --------------------------------------------------------------------------------
# Test - Initial release

testLabel "Empty source"

# Clear
testSimple_Setup

"$diffTool" "/dev/null" "1"
rm -rf "1"

"$patchTool" "/dev/null" -p "Patch_(null)_to_(1).xz"
read line < "1/c.txt"; if [ "$line" != "ccccc" ]; then err_report $LINENO; fi

cd "$DIR" > /dev/null
rm -rf "$baseDir"

# --------------------------------------------------------------------------------
# Test - Chained patching workflow

testLabel "Chained patching workflow"

# testSetup NAME
testSetup() {
	local name="$1"
	mkdir -p "$name"
	head -c 100000 /dev/urandom > "$name/a"
}

# Clear
rm -rf "$baseDir"

mkdir -p "$baseDir"
cd "$baseDir"

testSetup "1"	# Sender v1
"$arTool" "1"
rm -rf "1"

testSetup "2"	# Sender patch v2
"$diffTool" "1$archiveSuffix" "2"
"$arTool" "2"
mv "2$archiveSuffix" "2.sender$archiveSuffix"
rm -rf "2"

"$patchTool" "1$archiveSuffix"	# Recipient, patch v2 (auto name)
"$arTool" "2"
mv "2$archiveSuffix" "2.recipient$archiveSuffix"
rm -rf "2"

testSetup "3"	# Sender patch v3
"$diffTool" "2.sender$archiveSuffix" "3"
"$arTool" "3"
mv "3$archiveSuffix" "3.sender$archiveSuffix"
rm -rf "3"

"$patchTool" "2.recipient$archiveSuffix" -p "Patch_(2.sender)_to_(3).xz"	# Recipient, patch v3
"$arTool" "3"
mv "3$archiveSuffix" "3.recipient$archiveSuffix"
rm -rf "3"

diff "3.sender$archiveSuffix" "3.recipient$archiveSuffix" > /dev/null
if [[ "$?" != 0 ]]; then err_report $LINENO; fi

cd "$DIR" > /dev/null
rm -rf "$baseDir"


# --------------------------------------------------------------------------------
# Test - Various command line options

testLabel "XZ compression option"

# Setup
testSimple_Setup

# Operate
"$arTool" -0 "1"      # Create archive
rm -r "1"             # Remove original "1"
"$diffTool" "1$archiveSuffix" "2" -p delta.patch -0     # Build
"$patchTool" "1$archiveSuffix" -p delta.patch -o "2_"   # Apply
rm delta.patch

# Test
testSimple_Test

# Clear
cd "$DIR" > /dev/null
rm -rf "$baseDir"

# --------------------------------------------------------------------------------
# Test from a directory that is not the parent of dir1 and dir2

testSubdir_noLabel() {
	# Setup
	testSimple_Setup
	cd "$DIR" > /dev/null

	# Operate
	"$diffTool" "$baseDir/1" "$baseDir/2"         # Build
	"$patchTool" "$baseDir/1" -o "$baseDir/2_"    # Apply
	local patchfile="$(autoPatchName "$baseDir/1" "$baseDir/2")"
	rm "$patchfile"

	# Test
	cd "$baseDir"
	testSimple_Test

	# Clear
	cd "$DIR" > /dev/null
	rm -rf "$baseDir"
}

testLabel "Sub directory"
testSubdir_noLabel

# --------------------------------------------------------------------------------
# Test using an absolute path

# Switch base dir to an absolute path
initialBaseDir="$baseDir"
baseDir="$(pwd)/$baseDir"

testLabel "Absolute directory"
testSubdir_noLabel

# Restore baseDir
baseDir="$initialBaseDir"

# --------------------------------------------------------------------------------
# End

echo ""
echo $separatorDisplay
echo "$toolName: Tests sucessful"

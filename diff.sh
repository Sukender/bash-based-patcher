#!/bin/bash
# Creates a compressed binary diff (patch) between two directories.
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)
# Version: 0.2

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4

# --------------------------------------------------------------------------------
# Parameters parsing and usage

positionalOption() {
	if [ -z "$dir1" ]; then
		dir1="$1"
	else
		if [ -z "$dir2" ]; then
			dir2="$1"
		else
			echo "Unrecognized option: $1"
			exit 1
		fi
	fi
}

usage() {
	echo ""
	echo "$toolName"
	echo "Creates a compressed binary diff (patch) between two directories."
	echo
	echo "Syntax:"
	echo "  diff [options] oldDirectory newDirectory"
	echo
	echo "Options:"
	echo "  -h, --help"
	echo "      Displays this help text and exits."
	echo "  --man"
	echo "      Displays all documentation available and exits."
	echo "  --version"
	echo "      Displays a short (parsable) version information and exits."
	echo "  -p, --patch NAME"
	echo "      Changes the output patch file name to NAME (default: '$defaultpatchfile')."
	echo "      File is always overwritten without confirmation."
	echo "  -v, --verbose"
	echo "      Adds more information."
	echo "  --"
	echo "      Do not interpret any more arguments as options."
	echo
}


while [ "$#" -gt 0 ]; do
case "$1" in
	-v|--verbose)
		shift; verbose=1;
		;;
	-h|--help)
		shift; usage; exit 0;
		;;
	--man)
		shift; usage; displayDoc; exit 0;
		;;
	--version)
		shift; echo "$toolVersion"; exit 0;
		;;
	-p|--patch)
		shift; patchfile="$1"; shift;
		;;
	--)
		shift;
		break;
		;;
	# an option argument, continue
	*)
		positionalOption "$1"
		shift;
		;;
esac
done

if [ -z "$dir1" ] || [ -z "$dir2" ]; then
	usage;
	exit 1;
fi

chooseDelta ""

if [[ $verbose != 0 ]]; then
	echo "$toolName"
	echo $separatorDisplay
	echo ""
	echo "Generating patch from '$dir1' to '$dir2'"
	echo "Patch file: $patchfile"
	echo "Delta: $delta"
fi

# --------------------------------------------------------------------------------

echo $separatorDisplay
echo "[$(date +%H:%M:%S)] Creating patch. This may take a while."
echo "    Please note this is a multiple phases creation: the output compressor may stall (especially at 0%) for a long time."
echo ""

if [ "$delta" == "xdelta3" ]; then
	# xdelta3
	rm pipe1 pipe2 "$patchfile" 2> /dev/null
	mkfifo pipe1 pipe2 || exit 2
	#tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & tar -c --sort=name --no-auto-compress --directory="$dir2" . > pipe2 & xdelta3 -e -S "none" -s pipe1 pipe2 | 7za a -mx9 -si "$patchfile" || exit 2
	#tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & tar -c --sort=name --no-auto-compress --directory="$dir2" . > pipe2 & xdelta3 -e -s pipe1 pipe2 | 7za a -mx9 -si "$patchfile" || exit 2
	tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & tar -c --sort=name --no-auto-compress --directory="$dir2" . > pipe2 & xdelta3 -e -S lzma -s pipe1 pipe2 "$patchfile" || exit 2
	rm pipe1 pipe2
else
	# rdiff
	rm pipe1 pipe2 pipe1sig "$patchfile" 2> /dev/null
	mkfifo pipe1 pipe1sig pipe2 || exit 2
	tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & rdiff signature pipe1 pipe1sig & tar -c --sort=name --no-auto-compress --directory="$dir2" . > pipe2 & rdiff delta pipe1sig pipe2 | 7za a -mx9 -si "$patchfile" || exit 2
		# > /dev/null
	rm pipe1 pipe1sig pipe2
fi

echo $separatorDisplay
echo "[$(date +%H:%M:%S)] Patch created. Size = $(du -sb "$patchfile" | awk '{ print $1 }') ($(du -sh "$patchfile" | awk '{ print $1 }'))"
echo ""

# --------------------------------------------------------------------------------

# Insecure FTP upload:
# HOST='transfert.virtuelcity.com'
# USER='transfert'
# PASSWD='???????'

# ftp -n $HOST <<END_SCRIPT
# quote USER $USER
# quote PASS $PASSWD
# binary
# put $patchfile
# quit
# END_SCRIPT

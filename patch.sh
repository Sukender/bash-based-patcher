#!/bin/bash
# Applies a compressed binary diff (patch) on a directory, creating a copy (ie. not in-place).
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)
# Version: 0.2

# Dependencies, error codes, documentation: see "diff_patch_config.sh"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir
source "$DIR/diff_patch_config.sh" || exit 4

intermediate1="1.tar"

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
	echo "Applies a compressed binary diff (patch) on a directory, creating a copy (ie. not in-place)."
	echo
	echo "Syntax:"
	echo "  patch [options] oldDirectory [newDirectory]"
	echo "  If newDirectory is omitted, it is automatically generated."
	echo
	echo "Options:"
	echo
	echo "  -h, --help"
	echo "      Displays this help text and exits."
	echo "  --man"
	echo "      Displays all documentation available and exits."
	echo "  --version"
	echo "      Displays a short (parsable) version information and exits."
	echo "  -g, --get URL"
	echo "      Downloads URL as the patch to apply."
	echo "  -p, --patch NAME"
	echo "      Uses the patch file NAME (default: '$defaultpatchfile')."
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
	-g|--get)
		shift; patchUrl="$1"; shift;
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

if [ -z "$dir1" ]; then
	usage;
	exit 1;
fi

if [ -z "$dir2" ]; then
	dir2="$dir1_patched"
fi

chooseDelta ""

if [[ $verbose != 0 ]]; then
	echo "$toolName"
	echo $separatorDisplay
	echo ""
	echo "Applying patch on '$dir1', to '$dir2'"
	echo "Patch file: $patchfile"
	echo "Patch URL: $patchUrl"
	echo "Delta: $delta"
fi

# --------------------------------------------------------------------------------

if [ -n "$patchUrl" ]; then
	echo $separatorDisplay
	echo "[$(date +%H:%M:%S)] Getting the patch file."
	echo ""
	wget "$patchUrl" -O "$patchfile" || exit 3
fi

rm -r "$dir2" 2> /dev/null
mkdir -p "$dir2"

# (rdiff only) Theorical call would be:
#   7za x -so "$patchfile" > pipe2ar & tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & rdiff patch pipe1 pipe2ar pipe2 & tar -x --directory="$dir2" . < pipe2
# Unfortunately, rdiff needs the base (here 'pipe1') to be seekable. But named pipes aren't (even if seekable pipes may have been proposed).
# We thus rely on an intermediate file.
if [ "$delta" == "rdiff" ]; then
	echo $separatorDisplay
	echo "[$(date +%H:%M:%S)] Creating intermediate file before applying patch. This may take a while."
	echo ""
	rm "$intermediate1" 2> /dev/null
	tar -cf "$intermediate1" --sort=name --no-auto-compress --directory="$dir1" . || exit 2
fi

echo $separatorDisplay
echo "[$(date +%H:%M:%S)] Applying patch. This may take a while."
echo ""

if [ "$delta" == "xdelta3" ]; then
	# xdelta3
	rm pipe1 pipe2 pipe2ar 2> /dev/null
	mkfifo pipe1 pipe2 pipe2ar || exit 2
	#7za x -so "$patchfile" > pipe2ar & tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & xdelta3 -d -s pipe1 pipe2ar pipe2 & tar -x --directory="$dir2" . < pipe2
	tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & xdelta3 -d -s pipe1 "$patchfile" pipe2 & tar -x --directory="$dir2" . < pipe2
	rm pipe1 pipe2 pipe2ar
else
	# rdiff
	rm pipe2 pipe2ar 2> /dev/null
	mkfifo pipe2 pipe2ar || exit 2
	7za x -so "$patchfile" > pipe2ar & rdiff patch "$intermediate1" pipe2ar pipe2 & tar -xf pipe2 --directory="$dir2" . || exit 2
	rm "$intermediate1" pipe2 pipe2ar
fi

echo $separatorDisplay
echo "[$(date +%H:%M:%S)] Patch applied."
echo ""

#!/bin/bash
# Creates a compressed binary diff (patch) between two directories.
# This uses :
#   - 'tar' to make the directory a single stream (file)
#   - 'rdiff' to make the binary diff
#   - named pipes to avoid storing intermediate files to disk (much faster: everything in memory).
#   - 7-zip (7za) to LZMA compress the output and make an efficient patch.

echo "[$(date +%H:%M:%S)] Creating patch. This may take a while."
echo "    Please note this is a multiple phases creation: the output compressor may stall (especially at 0%) for a long time."

# dir1="$(cygpath "1")"
# dir2="$(cygpath "2")"
# dir1="$(cygpath "D:\Prog\VStory-Maquette\VStory Vierge - Unity 5.5.1 - VStory 4.3.0.0 - 64bits")"
# dir2="$(cygpath "D:\Prog\VStory-Maquette\VStory Vierge - Unity 5.5.2 - VStory 5.0.0.0 - 64bits")"
dir1="$1"
dir2="$2"
patchfile="patch.7z"

rm pipe1 pipe2 "$patchfile" 2> /dev/null
mkfifo pipe1 pipe1sig pipe2
tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & rdiff signature pipe1 pipe1sig & tar -c --sort=name --no-auto-compress --directory="$dir2" . > pipe2 & rdiff delta pipe1sig pipe2 | 7za a -mx9 -si "$patchfile"
	# > /dev/null
rm pipe1 pipe1sig pipe2

echo "[$(date +%H:%M:%S)] Patch created."

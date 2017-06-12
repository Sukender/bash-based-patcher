#!/bin/bash
# Applies a compressed binary diff (patch) on a directory, creating a copy (ie. not in-place).
# This uses :
#   - 'tar' to make the directory a single stream (file)
#   - 'rdiff' to make the binary diff
#   - named pipes to avoid storing intermediate files to disk (much faster: everything in memory).
#   - 7-zip (7za) to LZMA compress the output and make an efficient patch.

# Theorical call would be:
#   7za x -so "$patchFile" > pipe2ar & tar -c --sort=name --no-auto-compress --directory="$dir1" . > pipe1 & rdiff patch pipe1 pipe2ar pipe2 & tar -x --directory="$dir2" . > pipe2
# Unfortunately, rdiff needs the base (here 'pipe1') to be seekable. But named pipes aren't (even if seekable pipes may have been proposed).
# We thus rely on an intermediate file.
#
#rm pipe1 pipe2 pipe2ar 2> /dev/null
#mkfifo pipe1 pipe2 pipe2ar
#rm pipe1 pipe2 pipe2ar

echo "[$(date +%H:%M:%S)] Creating intermediate file before applying patch. This may take a while."

# dir1="$(cygpath "1")"
#dir2="$(cygpath "2bis")"
dir1="$1"
dir2="$1_patched"
patchFile="patch.7z"
intermediate1="1.tar"

mkdir -p "$dir2"
rm "$intermediate1" pipe2 pipe2ar 2> /dev/null
mkfifo pipe2 pipe2ar
tar -cf "$intermediate1" --sort=name --no-auto-compress --directory="$dir1" .

echo "[$(date +%H:%M:%S)] Applying patch. This may take a while."

#7za x -so "$patchFile" > _testpatch
7za x -so "$patchFile" > pipe2ar & rdiff patch "$intermediate1" pipe2ar pipe2 & tar -xf pipe2 --directory="$dir2" .
rm "$intermediate1" pipe2 pipe2ar

echo "[$(date +%H:%M:%S)] Patch applied."

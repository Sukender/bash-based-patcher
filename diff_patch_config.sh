#!/bin/bash
# Configuration, documentation, and common functions & variables for Sukender's bash-based patcher
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)

# --------------------------------------------------------------------------------
# Constants
toolVersion="0.3"
toolNameUnversionned="Sukender's bash-based patcher"
toolName="$toolNameUnversionned v$toolVersion"
separatorDisplay="--------------------------------------------------------------------------------"
defaultpatchfile="patch.xz"
if [ -z "$defaultVerbosity" ]; then defaultVerbosity=1; fi

BBD_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir

# Tools names
diffTool="$BBD_HOME/diff.sh"
patchTool="$BBD_HOME/patch.sh"
arTool="$BBD_HOME/diff_ar.sh"

# Other
archiveSuffix=".reference.tar.xz"		# "-J" option of tar is used to select the XZ compressor. Do not change extension without changing tar arguments.
XZ_OPT=-9	# Global compression ratio for .tar.xz

# --------------------------------------------------------------------------------
# Documentation

doc_dependencies="Dependencies:
  - tar to make the directory a single stream (file).
  - rdiff or xdelta3 to make the binary diff.
  - named pipes to avoid storing intermediate files to disk (much faster: everything in memory).
  - XZ (xz-utils) for tar to compress the output and make patches space-efficient.
  - (optional) pv to display progress.
  - [patch only] wget to retreive a distant patch.
All-in-one apt-style command line:
  sudo apt install tar rdiff xdelta3 xz-utils wget pv
"

doc_errorCodes="Error codes:
  0: Ok
  1: Error in arguments
  2: Error in process
  3: [patch only] Error downloading patch
  4: Error in configuration (internal error, installation error)
  5: Missing dependency
"

doc_license="License:
This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://www.wtfpl.net/ for more details.


           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004
 
Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
 
Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.
 
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
 
 0. You just DO WHAT THE FUCK YOU WANT TO.
"

displayDoc() {
	echo $separatorDisplay
	echo "$doc_dependencies"
	echo $separatorDisplay
	echo "$doc_errorCodes"
	echo $separatorDisplay
	echo "$doc_license"
	echo $separatorDisplay
}

# --------------------------------------------------------------------------------
# Delta tools availability

evalHas() {
	which "$1" > /dev/null 2> /dev/null
	if [[ "$?" == 0 ]]; then
		eval "has_$1=1"
	else
		eval "has_$1=0"
	fi
}

# assertHas command packageNameInfo
assertHas() {
	which "$1" > /dev/null 2> /dev/null
	if [[ "$?" != 0 ]]; then
		echo "Missing: '$1' seems not installed and in your path. Please install (the package you need is probably '$2')."
		exit 5
	fi
}

evalHas xdelta3
evalHas rdiff

# chooseDelta_explicit userChoice currentDeltaIteration
chooseDelta_explicit() {
	hasVariable="has_$2"
	if [ "$1" == "$2" ]; then
		if [[ "${!hasVariable}" != "0" ]]; then
			delta="$2"
		else
			echo "Delta tool '$2' was choosen but seems not installed and in your path."
		fi
	fi
}

chooseDelta() {
	# Honor explicit choices if possible
	chooseDelta_explicit "$1" "rdiff"
	if [ -n "$delta" ]; then return; fi
	chooseDelta_explicit "$1" "xdelta3"
	if [ -n "$delta" ]; then return; fi
	#if [ "$1" == "xdelta"  ] && [[ "$has_xdelta3" != "0" ]]; then delta="xdelta3"; return; fi		# Alias
	#if [ -n "$delta" ]; then return; fi

	# Default choice
	if [[ "$has_xdelta3" != "0" ]]; then delta="xdelta3"; return; fi
	if [[ "$has_rdiff"   != "0" ]]; then delta="rdiff";   return; fi

	echo "Error: your need either rdiff or xdelta3 installed and in your path. Please install."
	exit 1
}

# --------------------------------------------------------------------------------
# Mandatory tools availability

assertHas tar tar
assertHas wget wget
assertHas xz "xz-utils"

# --------------------------------------------------------------------------------
# Optional tools availability

evalHas pv

# --------------------------------------------------------------------------------
# Common functions & calls

tarDir="tar -c --sort=name --no-auto-compress"

# readBase dir1 outFile useSubshell
readBase_sub() {
	if [ -f "$1" ]; then
		# Archive (file) mode
		#TODO: Ensure this is an adequate archive!
		if [[ "$useSubshell" != 0 ]]; then
			xz -kd "$1" --stdout > "$2" &
		else
			xz -kd "$1" --stdout > "$2"
		fi
	else
		# Directory mode
		if [ ! -d "$1" ]; then
			echo "\"$1\" ('newDirectory') is not a valid directory!"
			exit 1
		fi
		if [[ "$useSubshell" != 0 ]]; then
			$tarDir --directory="$1" . > "$2" &
		else
			$tarDir --directory="$1" . > "$2"
		fi
	fi
}

# Opens or reads base (directory or archive) to an output file (generally "pipe1"), into a subshell.
# readBase dir1 outFile
readBase() {
	readBase_sub "$1" "$2" "1"
}

# Opens or reads base (directory or archive) to an output file (generally "pipe1"), into the current shell.
# readBase dir1 outFile
readBaseSync() {
	readBase_sub "$1" "$2" "0"
}

# --------------------------------------------------------------------------------
# Default-initialized variables
verbosity="$defaultVerbosity"
patchfile="$defaultpatchfile"

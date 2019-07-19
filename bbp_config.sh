#!/bin/bash
# Configuration, documentation, and common functions & variables for Sukender's bash-based patcher
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)

# --------------------------------------------------------------------------------
# Constants
toolVersion="0.6.2"
toolNameUnversionned="Sukender's Bash-Based Patcher (BBP)"
toolName="$toolNameUnversionned v$toolVersion"
separatorDisplay="--------------------------------------------------------------------------------"
defaultpatchfile="patch.xz"
if [ -z "${defaultVerbosity:-}" ]; then defaultVerbosity=1; fi

BBP_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"		# Script dir

# Tools names
diffToolName="bbpdiff"
diffTool="$BBP_HOME/$diffToolName"
patchToolName="bbppatch"
patchTool="$BBP_HOME/$patchToolName"
arToolName="bbpar"
arTool="$BBP_HOME/$arToolName"
infoToolName="bbpinfo"
infoTool="$BBP_HOME/$infoToolName"

# Other
archiveExtension=".tar.xz"		# "-J" option of tar is used to select the XZ compressor. Do not change extension without changing tar arguments.
archiveSuffix=".reference$archiveExtension"

# Sets the global environment variable XZ_OPT, given a compression level.
# This adds other options (here, "-T0") to XZ_OPT.
# Example: "xzOpt 9", or "xzOpt -9"
xzOpt() {
	local opt="$1"
	if [[ "$opt" =~ ^[0-9]$ ]]; then opt="-$opt"; fi		# Auto-add hyphen ('-')
	if [[ ! "$opt" =~ ^\-[0-9]$ ]]; then
		echo "Illegal XZ compression level. Ignoring."
		return
	fi
	#export XZ_OPT="$opt -T0"		# Global compression ratio for .tar.xz, with "auto multithreading"
	export XZ_OPT="$opt"		# Global compression ratio for .tar.xz, single threaded. Some archives created with -T0 generate errors (unknown reason) under Cygwin / xz v5.2.3
}
xzOpt 9

set -euo pipefail

# --------------------------------------------------------------------------------
# Documentation

doc_dependencies="Dependencies:
  - tar to make the directory a single stream (file).
  - rdiff or xdelta3 to make the binary diff.
  - named pipes to avoid storing intermediate files to disk (much faster: everything in memory).
  - XZ (xz-utils) for tar to compress the output and make patches space-efficient.
  - awk for some text processing.
  - [patch only] wget to retreive a distant patch.
  - (optional) pv, to display progress.
  - (optional) make, to install, test, and package.
All-in-one apt-style command line:
  sudo apt install tar rdiff xdelta3 xz-utils wget pv awk
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

# Tests if command $1 exists (built-in or in path), and set the global variable "has_$1" to 0 or 1.
evalHas() {
	which "$1" > /dev/null 2> /dev/null || true
	if [[ "$?" == 0 ]]; then
		eval "has_$1=1"
	else
		eval "has_$1=0"
	fi
}

# Tests if command $1 exists (built-in or in path), and exits after displaying a message with $2 if not.
# assertHas command packageNameInfo
assertHas() {
	which "$1" > /dev/null 2> /dev/null || true
	if [[ "$?" != 0 ]]; then
		echo "Missing: '$1' seems not installed and in your path. Please install (the package you need is probably '$2')."
		exit 5
	fi
}

evalHas xdelta3
evalHas rdiff

# chooseDelta_explicit userChoice currentDeltaIteration
chooseDelta_explicit() {
	if [[ "$1" =~ ^UNKNOWN ]]; then
		# Case where this function is used with the result of bbpinfo, and that result is not valid.
		echo "Delta tool could not be detected. Please ensure your patch file is valid."
		exit 1
	fi

	hasVariable="has_$2"
	if [ "$1" == "$2" ]; then
		if [[ "${!hasVariable}" != "0" ]]; then
			delta="$2"
		else
			echo "Delta tool '$2' was selected but seems not installed and in your path."
		fi
	fi
}

chooseDelta() {
	# Honor explicit choices if possible
	if [ -n "${1:-}" ]; then
		chooseDelta_explicit "$1" "rdiff"
		if [ -n "${delta:-}" ]; then return; fi
		chooseDelta_explicit "$1" "xdelta3"
		if [ -n "${delta:-}" ]; then return; fi
		#if [ "$1" == "xdelta"  ] && [[ "$has_xdelta3" != "0" ]]; then delta="xdelta3"; return; fi		# Alias
		#if [ -n "${delta:-}" ]; then return; fi
	fi

	# Default choice
	if [[ "$has_xdelta3" != "0" ]]; then delta="xdelta3"; return; fi
	if [[ "$has_rdiff"   != "0" ]]; then delta="rdiff";   return; fi

	echo "Error: your need either rdiff or xdelta3 installed and in your path. Please install."
	exit 1
}

autoDetectedDelta() {
	local d="$("$infoTool" "$1")"
	chooseDelta_explicit "$d" "$d"
	if [ -n "${delta:-}" ]; then return; fi

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
	local dir="$1"
	local outFile="$2"
	local useSubshell="$3"
	if [ -f "$dir" ]; then
		# Archive (file) mode
		if [[ "$dir" != *$archiveExtension ]]; then
			echo "\"$dir\" ('new') is a file, but it is not a valid archive (named '*$archiveExtension')!"
			exit 1
		fi
		if [[ "$useSubshell" != 0 ]]; then
			xz -kd "$dir" --stdout > "$outFile" &
		else
			xz -kd "$dir" --stdout > "$outFile"
		fi
	else
		# Directory mode
		if [ ! -d "$dir" ]; then
			echo "\"$dir\" ('new') is not a valid directory, nor a valid archive!"
			exit 1
		fi
		if [[ "$useSubshell" != 0 ]]; then
			$tarDir --directory="$dir" . > "$outFile" &
		else
			$tarDir --directory="$dir" . > "$outFile"
		fi
	fi
}

# Opens or reads base (directory or archive) to an output file (generally "pipe1"), into a subshell.
# readBase dir1 outFile
readBase() {
	readBase_sub "$1" "$2" "1"
}

# Opens or reads base (directory or archive) to an output file, into the current shell.
# readBase dir1 outFile
readBaseSync() {
	readBase_sub "$1" "$2" "0"
}

# Prints the patch name from dir1 and 2 ($1 $2).
autoPatchName() {
	local b1="${1%$archiveSuffix}"		# Remove suffix
	local b2="${2%$archiveSuffix}"		# Remove suffix
	local b1="$(basename "$b1")"
	local b2="$(basename "$b2")"
	echo "Patch_($b1)_to_($b2).xz"
}

# Prints the first patch search expression
autoPatchSearch1() {
	local b1="${1%$archiveSuffix}"		# Remove suffix
	local b1="$(basename "$b1")"
	echo "Patch_($b1)_to_(*).xz"
}

# Prints the second patch search expression
# autoPatchSearch2() {
# }

# Extract 'dir2' part (= 'new') from an explicit patch name.
extractNewName() {
	local b1="$(basename "$1")"
	if [[ "$b1" =~ ^Patch_\((.*)\)_to_\((.*)\)\.xz$ ]]; then
		echo "$(basename "${BASH_REMATCH[2]}")"
	else
		echo ""
	fi
}

# Extracts base name of a file from an URL (for download), interpreting escaped characters.
extractUrlName() {
	local dlBaseName="$(basename "$1")"
	dlBaseName="$(printf '%b' "${dlBaseName//%/\\x}")"
	dlBaseName="$(echo "$dlBaseName" | sed "s/+/ /g")"
	#dlBaseName="$(echo "$dlBaseName" | awk 'gsub( "+"," " )')"
	echo "$dlBaseName"
}

# Extracts base name of an archive
directoryNameFromArchive() {
	local res="${1%$archiveSuffix}"		# Remove suffix
	res="${res%$archiveExtension}"		# Remove suffix if no ".reference"
	echo "$(basename "$res")"			# Remove dirs
}

# Writes the size in bytes of the first argument.
# Example: size=$(getSize "myDirectory")
getSize() {
	du -bs "$1" | sed -E 's/^([0-9]+).*/\1/'
}

# --------------------------------------------------------------------------------
# Default-initialized variables
verbosity="$defaultVerbosity"
patchfile=""

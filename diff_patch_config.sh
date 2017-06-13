#!/bin/bash
# Configuration, documentation, and common functions & variables for Sukender's rdiff-based patcher
# Author: Sukender (Benoit Neil)
# Licence: WTFPL v2 (see COPYING.txt)
# Version: 0.2

# --------------------------------------------------------------------------------
# Constants
toolVersion="0.2"
toolNameUnversionned="Sukender's rdiff-based patcher"
toolName="$toolNameUnversionned v$toolVersion"
separatorDisplay="--------------------------------------------------------------------------------"
defaultpatchfile="patch.7z"

# --------------------------------------------------------------------------------
# Documentation

doc_dependencies="Dependencies:
  - tar to make the directory a single stream (file).
  - rdiff to make the binary diff.
  - named pipes to avoid storing intermediate files to disk (much faster: everything in memory).
  - 7-zip (7za) to LZMA compress the output and make an efficient patch.
  - [patch only] wget to retreive a distant patch.
All-in-one apt-style command line:
  sudo apt install tar rdiff p7zip wget
"

doc_errorCodes="Error codes:
  0: Ok
  1: Error in arguments
  2: Error in process
  3: [patch only] Error downloading patch
  4: Error in configuration (internal error, installation error)
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
# Default-initialized variables
verbose=0
patchfile="$defaultpatchfile"


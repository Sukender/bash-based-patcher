# BBP: Sukender's Bash-Based Patcher
![Cross-platform](https://img.shields.io/badge/platform-windows%20cygwin%20%7C%20linux-lightgrey.svg) [![WTFPL license](https://img.shields.io/badge/license-WTFPL-green.svg)](https://github.com/Sukender/bash-based-patcher/blob/master/docs/LICENSE.md) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-blue.svg)](https://github.com/Sukender/bash-based-patcher/pulls)   

## Description
Simple command-line diff/patch of **directories** (or archives).

![BBP principle schema](bbp-diff-patch-principle.svg "BBP helps sending small updates")

BBP helps maintaining a large (remote) directory up-to-date, as a mirror.  
BBP computes the difference between two directories (or archives). Then it applies the patch to an "old" directory/archive and get an updated ("new") one.

## Goals
- **Time efficient** - Distribute new versions much faster.
  - Sending a *huge* folder over a network may be unrealistic when it becomes over-sized.
- **Space efficient** - Build the smallest possible patch.
  - Bandwidth and disk space are not free!
  - BBP uses either [xdelta3](http://xdelta.org/) or [rdiff](https://linux.die.net/man/1/rdiff) . Those are particularly space-efficient.
- **Free** - Be used by anyone, anywhere, free of charge (hence the choice of a [permissive license](LICENSE.md)).
- **Straightforward** - Be simple and basic (not necessarily user friendly).
  - This is why it is only a simple wrapper around commonly used GNU/Linux tools.

### Why use it?
Sending a few megabytes nowadays is just a matter of zipping a folder and mailing it. However BBP comes to help (and may become unavoidable) when:
- the *size* of the data to send gets larger, and/or
- the *delay* to distribute shortens, and/or
- the *number of recipients* increases, and/or
- the *difference* between versions decreases (or at least stays relatively small).

## Features
- BBP processes a whole directory as a **single unit**.
  - The patch will thus contain changes, additions, and deletions.
  - BBP is efficient because it does not handle each file separately.
- Support **archives**, which can replace source directories.
  - The ```bbp ar``` command can be used to create compatible (```tar.xz```) archives.
  - Only one archive type is currently supported. You will not be able to use your previously "zipped" folder unless you extract it first.
- "Portable":
  - Tested on *GNU/Linux* (Ubuntu) and *Cygwin* (Windows).
  - Actually the bash scripts should run on many other systems, including OSX.
  - Please note that even if targeted at the *bash* interpreter, this may work with others, or be easily adapted.

## Examples
### Basic
```bash
# On a first machine:
bbp diff "oldDir" "newDir"     # Generate the patch ("Patch_(oldDir)_to_(newDir).xz")

# On a second machine, where the patch has been copied to:
bbp patch "oldDir"             # Apply patch by auto-finding it in the current directory.
```

### Remote
```bash
# On a first machine:
bbp diff "oldDir" "newDir"     # Generate the patch
./myUploadScript               # Upload generated file somewhere, say "some.server.com/patch.xz"

# On a second machine:
bbp patch "oldDirCopy" -g https://some.server.com/patch.xz      # Download and apply patch
```

### Archives
Directories and tar.xz archives are used the same way and are exchangeable.
```bash
# On a first machine:
                               # I want to archive my (heavy) "oldDir", but keep it bbp-compatible.
bbp ar "oldDir"                # Using 'bbp ar', with default archive name ("oldDir.reference.tar.xz").

bbp diff "oldDir.reference.tar.xz" "newDir"     # Now generate the patch, but use the newly created "reference"
                                                # archive in lieu of the source directory.
                                                # Note we can do the same with "newDir".

# On a second machine, where the patch has been copied to:
bbp patch "oldDir.reference.tar.xz"             # Apply on an archive (also works with directory)
```

## Installation and dependencies
See the [installation documentation](INSTALL.md).

## Documentation
Each script can print its own documentation, via the usual ```--help``` argument:
- Type ```bbp --help``` to start.
- Type ```bbp TOOL --help``` to get the documentation for the given *TOOL*.
Please note the ```--man``` argument will give you additional and more technical information.

### Tools and aliases
Here is a brief description of each tool, alongside with are aliases (synonyms) for some commands:
- **diff** generates the patch by finding differences.
  - ```bbpdiff```, ```bbp diff```, ```bbp sub``` (stands for "subtract")
- **patch** applies a patch.
  - ```bbppatch```, ```bbp patch```, ```bbp add```, ```bbp apply```
- **ar** creates compatible archives.
  - ```bbpar```, ```bbp ar```, ```bbp archive```
  - Also, ```bbp unar``` and ```bbp unarchive``` stand for ```bbpar -x``` (extract archive)
- **info** prints information about a patch (the choosen underlying tool used to create it).
  - ```bbpinfo```, ```bbp info```

## Future work & ideas
### To-do
Stuff that should be done:
- [```bbppatch```] Upon failure, cleanup everything: delete or rename patched directory, pipes and temporary downloaded patch.
- [```bbppatch```] Apply multiple patches in a batch (ex: update from *v1* to *v4*).
- [```bbpar```] Add progress bar for decompression.
- ```make install``` should have a way to configure install path.
- Add a resilience towards "small changes" in base directories (maintainer and users).
  - "Small changes" has to be clearly defined.
  - The goal is to allow both sides (maintainer & users) to tweak some files (say, config files), and still make the patch work properly.
  - Allowed changes may be somewhat hard-coded. Ex: a list of files that must be completely included in the patch when changed, even if a portion of them would suffice to describe differences.
- Allow exclusions, to "skip" paths (files or directories), as if they were removed from the base ('old'). This would allow patching a **part** of a directory.
  - Open question: how can we be sure to get the same filter when applying the patch?
- Add a true '*man*' page, or at least make ```man bbp``` trigger some help display.
- Add colors to outputs, as well as a universal ```--no-color``` option to disable it.

### Maybe to-do
Nice ideas that may require too much amount of work regarding to the usefulness of the feature:
- [```bbpdiff```] Handle upload of patches (FTP or such).
- Add support for custom archives (anything, not just ".tar.something") as base directory (both for diff and patch).
  - This may imply issues in creating proper diffs.
- Add an option for in-place patching.
- Add better progress bars display.
- [```bbppatch```] Add better patch name auto-detection: list available patches (with the same 'old' part), and try to guess the highest version if multiple are found.

### Will probably never be done
...beacause the toolset is supposedly basic:
- Translation into another language than English (even though this is not my mother tongue language).

### Won't-do
What is was not meant for:
- The toolset is not designed to get cool/beautiful installers. This is only an ugly command line maintaining two directories. Maybe building a GUI *ontop* of it would be clever (*ncurses*-like could be an option).

## Author
- **Sukender** (Benoit NEIL) - sukender at free dot fr
- Maybe you? Feel free to [participate](https://github.com/Sukender/bash-based-patcher/pulls)!
See also the list of [contributors](https://github.com/Sukender/bash-based-patcher/contributors) who participated in this project.

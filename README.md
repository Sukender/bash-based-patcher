# BBP: Sukender's bash-based patcher

## Description
Basic and simple toolset to help diff/patch directories.

### Goals
- Maintain a (remote) directory up-to-date. The "maintainer" sends updates to "users".
- Distribute small updates (which may not take forever to upload/download), even when the target directory is hundreds of gigabytes.
- Be a simple & basic toolset. This is why it is only a simple wrapper around commonly used GNU/Linux tools. Toolset is not necessarily user friendly nor error-proof.
- Be used by anyone, anywhere (hence the choice of a permissive license).

### Example
On a first machine:
```bash
bbp diff "oldDir" "newDir"
# Upload generated file somewhere
```

On a second machine:
```bash
bbp patch "oldDir" -g https://some.server.com/patch.xz
```

### Author
- **Sukender** (Benoit NEIL) - sukender at free dot fr
- Maybe you? Feel free to participate!
See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## Features
- Creates the smallest possible "patch" (difference) between two directories.
- Apply the patch to a directory and get an updated one.
- Do this in a "portable" way. Actually the bash scripts should run on (at least) common Linux distributions (Debian, Ubuntu...) and Cygwin.
- Please note that even if targeted at the "bash" interpreter, this may work with others, or be easily adapted.

### What is was not meant for:
- The toolset is not designed to get cool/beautiful installers. This is only an ugly command line maintaining two directories.

### To-do
- Name patches explicitely, such as "Patch 'MyOldDir' to 'MyNewDir'.xz". Handle auto-detection of which patch to choose (if multiple ones) when applying. Rename "patched" directory accordingly.
- Delete or renamed patched directory upon failure.
- Test all pipe statuses (${PIPESTATUS[i]}) and async statuses everywhere, and stop on error.
- Handle upload & downloads of patches (FTP or such).
- "make install" should have a way to configure install path.
- Add a resilience towards "small changes" in base directories (maintainer and users).
  - "Small changes" has to be clearly defined.
  - The goal is to allow both sides (maintainer & users) to tweak some files (say, config files), and still make the patch work properly.
  - Allowed changes may be somewhat hard-coded. Ex : a list of files that must be completely included in the patch when changed, even if a portion of them would suffice to describe differences.
- (Maybe) Add support for custom archives (anything, not just ".tar.something") as base directory (both for diff and patch).
  - This may imply issues in creating proper diffs.
- (Maybe) Handling the initial release (such as a patch of "nothing" to "something"), especially if upload/download is handled.
- (Maybe) Add an option for in-place patching.

Will probably never be done, beacause the toolset is supposedly basic:
  - Translation into another language than English (even though this is not my mother tongue language)

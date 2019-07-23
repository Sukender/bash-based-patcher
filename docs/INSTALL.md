# BBP - Installation
BBP is solely composed of Bash scripts, which use a set of GNU/Linux executable dependencies.

## Dependencies
- **tar**, to make the directory a single stream (file).
- **rdiff** or **xdelta3**, to make the binary diff.
  - Default one is *xdelta3*.
  - You can use either one to build patches.
  - There is no need for both executables, unless you receive a patch created with a specific one.
- **xz** ('xz-utils' package), for *tar* to compress the output and make patches space-efficient.
- **awk**, **grep**, and **sed** for some text processing.
- **wget** with **openssl**, to retrieve a distant patch [```bbppatch``` only].

Optional, but recommended:
- **pv**, to display progress.
- **make**, to install, test, and package.

Other, optional:
- **diff**, for unit testing.
- **git**, if you wish to clone the repository, and/or be involved in development.

### Notes about system support
System must support:
- Named pipes, to avoid storing intermediate files to disk.

### Command-line installation
To install all recommended packages, you may use one of the following command lines.

GNU/Linux (*apt*-style):
```bash
sudo apt install gawk sed pv tar xz-utils openssl wget rdiff xdelta3 diffutils git
```

Cygwin (64 bits):
```bat
"setup-x86_64.exe" -g -P bash,binutils,coreutils,cygutils,findutils,which,gawk,grep,sed,pv,tar,xz,openssl,wget,make,rdiff,rdiff-backup,xdelta3,diffutils,git
```

## Install BBP
To make *bbp* scripts available whatever the current path, you may install it using ```make install``` from the repository or a full release. Example:
```bash
# Clone repository
git clone https://github.com/Sukender/bash-based-patcher.git
cd bash-based-patcher

# Install scripts
sudo make install      # GNU/Linux
  # OR
make install           # Cygwin
```

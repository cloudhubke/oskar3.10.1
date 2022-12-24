## GOTCHAS

ArangoDB no longer uses AppleClang to compile.

Use LLVM clang.

download from https://github.com/llvm/llvm-project/releases/tag/llvmorg-14.0.6

after you extract in a folder,

place the environment variables:

```
export PATH="/Users/bernardgaitho/clang+llvm-14.0.6-x86_64-apple-darwin/bin:$PATH"


export CC="/Users/bernardgaitho/clang+llvm-14.0.6-x86_64-apple-darwin/bin/clang"
export CXX:=$(CC)++



```

# ARM

`findUseARM` option should be turned on only when building for M1 chips.
Otherwise you get an error like

```
2022-12-23T10:01:34Z [9537] FATAL [a7902] {crash} 💥 ArangoDB 3.10.2 [darwin], thread 8 caught unexpected signal 4 (SIGILL): signal handler invoked
2022-12-23T10:01:34Z [9537] INFO [ded81] {crash} available physical memory: 17179869184, rss usage: 38371328, vsz usage: 34712027136, threads: 12
[1]    9537 illegal hardware instruction  arangod -c etc/relative/arangod.conf --server.endpoint tcp://127.0.0.1:8529
```

# How to Build And Package

These instructions are for building .dmg(macOs) and .deb(debian) packages in a mac computer.

They have been tested to work on MacOs Big Sur (11.0.1);

Docker is required.

## Environment Variables

config/environment.fish

```
set -xg COMMUNITY_DOWNLOAD_LINK "https://community.arangodb.com"
set -xg ENTERPRISE_DOWNLOAD_LINK "https://enterprise.arangodb.com"

set -gx USE_CCACHE "sccache"
set -gx NOTARIZE_USER "exampleUser"
set -gx NOTARIZE_PASSWORD "examplePassword"
set -gx MACOS_ADMIN_KEYCHAIN_PASS "-"
```

## USE MAKE for development

Run the makeArangoDB in the oskar folder

```
fish
source config/environment.fish
source helper.fish
community

makeArangoDB
```

then run arangod in the while in the ArangoDb directory

```
cd work/ArangoDB

build/bin/arangod -c etc/relative/arangod.conf --server.endpoint tcp://127.0.0.1:8529 /tmp/database-dir

```

Run ArangoSh in another terminal while in the same folder

```
build/bin/arangosh
```

## Building DMG

```
fish
source config/environment.fish
source helper.fish
findArangoDBVersion
community
maintainerOff

buildCommunityPackage

```

the above commands will build the application and place the build files in work/ArangoDb/build/bin.

After that. It will run the `buildPackage` and generate .dmg files.

## Building .DEB (Use a debian dist like Ubuntu).

### The instructions below have been tested on ubuntu desktop 20.04 LTS

Log in to ubuntu and clone the oskar project as well as the work/ArangoDb project inside the oskar directory.

```
fish
source config/environment.fish
source helper.fish
source helper.linux.fish
community
maintainerOff
findArangoDBVersion

buildCommunityPackage
```

If building on linux throws an error, consider restarting the terminal, remove the folders work/debian, work/targz, work/arangodb3-3.0...

restart the build.

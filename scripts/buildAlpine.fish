#!/usr/bin/env fish
if test "$PARALLELISM" = ""
  set -xg PARALLELISM 64
end
echo "Using parallelism $PARALLELISM"

if test "$COMPILER_VERSION" = ""
  set -xg COMPILER_VERSION 6.4.0
end
echo "Using compiler version $COMPILER_VERSION"

if test "$COMPILER_VERSION" = "6.4.0"
  set -xg CC_NAME gcc
  set -xg CXX_NAME g++
else
  set -xg CC_NAME gcc-$COMPILER_VERSION
  set -xg CXX_NAME g++-$COMPILER_VERSION
end

if test "$OPENSSL_VERSION" = ""
  set -xg OPENSSL_VERSION 1.1.0
end
echo "Using openssl version $OPENSSL_VERSION"

cd $INNERWORKDIR
if test "$USE_CCACHE" = "Off"
  set -xg CCACHE_DISABLE true
  echo "ccache is DISABLED"
end

mkdir -p .ccache.alpine
set -x CCACHE_DIR $INNERWORKDIR/.ccache.alpine
if test "$CCACHEBINPATH" = ""
  set -xg CCACHEBINPATH /usr/lib/ccache/bin
end
if test "$CCACHESIZE" = ""
  set -xg CCACHESIZE 50G
end
ccache -M $CCACHESIZE
cd $INNERWORKDIR/ArangoDB

if test -z "$NO_RM_BUILD"
  echo "Cleaning build directory"
  rm -rf build
end
mkdir -p build
cd build
rm -rf install
and mkdir install

echo "Starting build at "(date)" on "(hostname)
set -g t0 (date "+%Y%m%d")
set -g t1 (date -u +%s)
rm -f $INNERWORKDIR/buildTimes.csv
rm -f $INNERWORKDIR/.ccache.log
ccache --zero-stats

set -g FULLARGS $argv \
 -DCMAKE_BUILD_TYPE=$BUILDMODE \
 -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/$CXX_NAME \
 -DCMAKE_C_COMPILER=$CCACHEBINPATH/$CC_NAME \
 -DCMAKE_EXE_LINKER_FLAGS="-Wl,--build-id -no-pie"\
 -DCMAKE_INSTALL_PREFIX=/ \
 -DSTATIC_EXECUTABLES=On \
 -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
 -DUSE_MAINTAINER_MODE=$MAINTAINER \
 -DCMAKE_LIBRARY_PATH=/opt/openssl-$OPENSSL_VERSION/lib \
 -DOPENSSL_ROOT_DIR=/opt/openssl-$OPENSSL_VERSION

if test "$argv" = ""
  echo "using default architecture 'nehalem'"
  set -g FULLARGS $FULLARGS \
    -DTARGET_ARCHITECTURE=nehalem
end

if test "$MAINTAINER" != "On"
  set -g FULLARGS $FULLARGS \
    -DUSE_CATCH_TESTS=Off \
    -DUSE_GOOGLE_TESTS=Off
end

if test "$ASAN" = "On"
  echo "ASAN is not support in this environment"
else if test "$COVERAGE" = "On"
  echo "Building with Coverage"
  set -g FULLARGS $FULLARGS \
    -DUSE_JEMALLOC=$JEMALLOC_OSKAR \
    -DCMAKE_C_FLAGS="-fno-stack-protector -fprofile-arcs -ftest-coverage" \
    -DCMAKE_CXX_FLAGS="-fno-stack-protector -fprofile-arcs -ftest-coverage"
else
  set -g FULLARGS $FULLARGS \
   -DUSE_JEMALLOC=$JEMALLOC_OSKAR \
   -DCMAKE_C_FLAGS=-fno-stack-protector \
   -DCMAKE_CXX_FLAGS=-fno-stack-protector
end

echo cmake $FULLARGS

if test "$SHOW_DETAILS" = "On"
  cmake $FULLARGS .. ^&1
else
  echo cmake output in $INNERWORKDIR/cmakeArangoDB.log
  cmake $FULLARGS .. > $INNERWORKDIR/cmakeArangoDB.log ^&1
end
or exit $status

set -g t2 (date -u +%s)
and echo $t0,cmake,(expr $t2 - $t1) >> $INNERWORKDIR/buildTimes.csv

echo "Finished cmake at "(date)", now starting build"

set -g MAKEFLAGS -j$PARALLELISM 
if test "$VERBOSEBUILD" = "On"
  echo "Building verbosely"
  set -g MAKEFLAGS $MAKEFLAGS V=1 VERBOSE=1 Verbose=1
end

set -x DESTDIR (pwd)/install
echo Running make $MAKEFLAGS for static build

if test "$SHOW_DETAILS" = "On"
  make $MAKEFLAGS install ^&1
else
  echo make output in work/buildArangoDB.log
  nice make $MAKEFLAGS install > $INNERWORKDIR/buildArangoDB.log ^&1
end
or exit $status

set -g t3 (date -u +%s)
and echo $t0,make,(expr $t3 - $t2) >> $INNERWORKDIR/buildTimes.csv

cd install
and if test -z "$NOSTRIP"
  echo Stripping executables...
  strip usr/sbin/arangod usr/bin/arangoimp usr/bin/arangosh usr/bin/arangovpack usr/bin/arangoexport usr/bin/arangobench usr/bin/arangodump usr/bin/arangorestore
  if test -f usr/bin/arangobackup
    strip usr/bin/arangobackup
  end
end

and echo "Finished at "(date)
and ccache --show-stats
and set -g t4 (date -u +%s)
and echo $t0,strip,(expr $t4 - $t3) >> $INNERWORKDIR/buildTimes.csv

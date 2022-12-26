set -gx SCRIPTSDIR $WORKDIR/scripts
set -gx PLATFORM darwin
set -gx UID (id -u)
set -gx GID (id -g)
set -gx INNERWORKDIR $WORKDIR/work
set -gx THIRDPARTY_BIN third_party/bin
set -gx THIRDPARTY_SBIN third_party/sbin
set -gx CCACHEBINPATH /usr/local/opt/ccache/libexec
set -gx CMAKE_INSTALL_PREFIX /opt/arangodb
set -gx CURRENT_PATH $PATH
set -xg IONICE ""
set -gx ARCH (uname -m)
set -gx DUMPDEVICE "lo0"

if test "$ARCH" = "arm64"
  set CCACHEBINPATH /opt/homebrew/opt/ccache/libexec
end


set -gx UBUNTUBUILDIMAGE3_NAME arangodb/ubuntubuildarangodb3-$ARCH
set -gx UBUNTUBUILDIMAGE3_TAG 18
set -gx UBUNTUBUILDIMAGE3 $UBUNTUBUILDIMAGE3_NAME:$UBUNTUBUILDIMAGE3_TAG

set -gx UBUNTUBUILDIMAGE4_NAME arangodb/ubuntubuildarangodb4-$ARCH
set -gx UBUNTUBUILDIMAGE4_TAG 19
set -gx UBUNTUBUILDIMAGE4 $UBUNTUBUILDIMAGE4_NAME:$UBUNTUBUILDIMAGE4_TAG

set -gx UBUNTUBUILDIMAGE5_NAME arangodb/ubuntubuildarangodb5-$ARCH
set -gx UBUNTUBUILDIMAGE5_TAG 12
set -gx UBUNTUBUILDIMAGE5 $UBUNTUBUILDIMAGE5_NAME:$UBUNTUBUILDIMAGE5_TAG

set -gx UBUNTUBUILDIMAGE6_NAME arangodb/ubuntubuildarangodb6-$ARCH
set -gx UBUNTUBUILDIMAGE6_TAG 5
set -gx UBUNTUBUILDIMAGE6 $UBUNTUBUILDIMAGE6_NAME:$UBUNTUBUILDIMAGE6_TAG

set -gx UBUNTUPACKAGINGIMAGE arangodb/ubuntupackagearangodb-$ARCH:1

set -gx ALPINEBUILDIMAGE3_NAME arangodb/alpinebuildarangodb3-$ARCH
set -gx ALPINEBUILDIMAGE3_TAG 21
set -gx ALPINEBUILDIMAGE3 $ALPINEBUILDIMAGE3_NAME:$ALPINEBUILDIMAGE3_TAG

set -gx ALPINEBUILDIMAGE4_NAME arangodb/alpinebuildarangodb4-$ARCH
set -gx ALPINEBUILDIMAGE4_TAG 22
set -gx ALPINEBUILDIMAGE4 $ALPINEBUILDIMAGE4_NAME:$ALPINEBUILDIMAGE4_TAG

set -gx ALPINEBUILDIMAGE5_NAME arangodb/alpinebuildarangodb5-$ARCH
set -gx ALPINEBUILDIMAGE5_TAG 12
set -gx ALPINEBUILDIMAGE5 $ALPINEBUILDIMAGE5_NAME:$ALPINEBUILDIMAGE5_TAG

set -gx ALPINEBUILDIMAGE6_NAME arangodb/alpinebuildarangodb6-$ARCH
set -gx ALPINEBUILDIMAGE6_TAG 4
set -gx ALPINEBUILDIMAGE6 $ALPINEBUILDIMAGE6_NAME:$ALPINEBUILDIMAGE6_TAG

set -gx ALPINEUTILSIMAGE_NAME arangodb/alpineutils-$ARCH
set -gx ALPINEUTILSIMAGE_TAG 4
set -gx ALPINEUTILSIMAGE $ALPINEUTILSIMAGE_NAME:$ALPINEUTILSIMAGE_TAG

set -gx CENTOSPACKAGINGIMAGE_NAME arangodb/centospackagearangodb-$ARCH
set -gx CENTOSPACKAGINGIMAGE_TAG 3
set -gx CENTOSPACKAGINGIMAGE $CENTOSPACKAGINGIMAGE_NAME:$CENTOSPACKAGINGIMAGE_TAG

set -gx CPPCHECKIMAGE_NAME arangodb/cppcheck-$ARCH
set -gx CPPCHECKIMAGE_TAG 7
set -gx CPPCHECKIMAGE $CPPCHECKIMAGE_NAME:$CPPCHECKIMAGE_TAG

set -gx LDAPIMAGE_NAME arangodb/ldap-test-$ARCH
set -gx LDAPIMAGE_TAG 1
set -gx LDAPIMAGE $LDAPIMAGE_NAME:$LDAPIMAGE_TAG

set -gx LDAPDOCKERCONTAINERNAME ldapserver1
set -gx LDAP2DOCKERCONTAINERNAME ldapserver2
set -gx LDAPNETWORK ldaptestnet


rm -f $SCRIPTSDIR/tools/sccache
ln -s $SCRIPTSDIR/tools/sccache-apple-darwin-$ARCH $SCRIPTSDIR/tools/sccache

function defaultMacOSXDeploymentTarget
  set -xg MACOSX_DEPLOYMENT_TARGET 10.14
  if string match --quiet --regex '^arm64$|^aarch64$' $ARCH >/dev/null
    set -xg MACOSX_DEPLOYMENT_TARGET 11.0
  end
end

if test -z "$MACOSX_DEPLOYMENT_TARGET"
  defaultMacOSXDeploymentTarget
end

set -gx SYSTEM_IS_MACOSX true

## #############################################################################
## config
## #############################################################################

# disable JEMALLOC for now in oskar on MacOSX, since we never tried it:
jemallocOff

# disable strange TAR feature from MacOSX
set -xg COPYFILE_DISABLE 1

function minMacOS
  set -l min $argv[1]

  if test "$min" = ""
    set -e MACOSX_DEPLOYMENT_TARGET
    return 0
  end

  switch $min
    case '10.12'
      set -gx MACOSX_DEPLOYMENT_TARGET $min

    case '10.13'
      set -gx MACOSX_DEPLOYMENT_TARGET $min

    case '10.14'
      set -gx MACOSX_DEPLOYMENT_TARGET $min

    case '10.15'
      set -gx MACOSX_DEPLOYMENT_TARGET $min

    case '*'
      echo "unknown macOS version $min"
  end
end

function findRequiredMinMacOS
  set -l f $WORKDIR/work/ArangoDB/VERSIONS

  test -f $f
  or begin
    echo "Cannot find $f; make sure source is checked out"
    return 1
  end

  set -l v (fgrep MACOS_MIN $f | awk '{print $2}' | tr -d '"' | tr -d "'")

  if test "$v" = ""
    defaultMacOSXDeploymentTarget
    echo "$f: no MACOS_MIN specified, using $MACOSX_DEPLOYMENT_TARGET"
    minMacOS $MACOSX_DEPLOYMENT_TARGET
  else
    if test "$USE_ARM" = "On"
      if string match --quiet --regex '^arm64$|^aarch64$' $ARCH >/dev/null
        echo "Using MACOS_MIN version '11.0' instead of '$v' from '$f' for ARM!"
        set v "11.0"
      end
    else
      echo "Using MACOS_MIN version '$v' from '$f'"
    end
    minMacOS $v
  end
end

function compiler
  set -l cversion $argv[1]

  if test "$cversion" = ""
    set -e COMPILER_VERSION
    return 0
  end

  switch $cversion
    case 12
      set -gx COMPILER_VERSION $cversion

    case 13
      set -gx COMPILER_VERSION $cversion

    case 14
      set -gx COMPILER_VERSION $cversion

    case '*'
      echo "unknown compiler version $cversion"
  end
end

function opensslVersion
  set -gx OPENSSL_VERSION $argv[1]
end

function downloadOpenSSL
  findRequiredOpenSSL
  set -l directory $WORKDIR/work/openssl
  set -l url https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz  
  mkdir -p $directory
  cd $directory
  echo "Downloading sources to $directory from URL: $url"
  curl -LO $url
  rm -rf openssl-$OPENSSL_VERSION
  tar -xzvf openssl-$OPENSSL_VERSION.tar.gz
  set -xg OPENSSL_SOURCE_DIR "$directory/openssl-$OPENSSL_VERSION"
end

function buildOpenSSL
  if test "$OPENSSL_SOURCE_DIR" = ""; or ! test -d $OPENSSL_SOURCE_DIR
    echo "Please download OpenSSL source with `downloadOpenSSL` function before building it!"
    return 1
  else if checkOskarOpenSSL
    echo "OpenSSL was already built! No need to rebuild it."
    return
  end
  cd $OPENSSL_SOURCE_DIR
  mkdir build
  
  if test -z "$ARCH"
    echo "ARCH is not set! Can't decide wether to build OpenSSL for arm64 or x86_64."
    return 1
  end

  if test "$ARCH" = "x86_64"
    set -xg OPENSSL_PLATFORM darwin64-x86_64-cc
  else if test "$ARCH" = "arm64"
    set -xg OPENSSL_PLATFORM darwin64-arm64-cc
  else
    echo "Unsupported architecture: $ARCH. OpenSSL oskar build is supported for x86_64 or arm64!"
    return 1
  end

  for type in shared no-shared
    for mode in debug release
      set -l cmd "perl ./Configure --prefix=$OPENSSL_SOURCE_DIR/build/$mode/$type --openssldir=$OPENSSL_SOURCE_DIR/build/$mode/$type/openssl --$mode $type $OPENSSL_PLATFORM"
      echo "Executing: $cmd"
      eval $cmd
      make
      make test
      make install_dev
    end
  end
end

function findOpenSSLPath
  set -gx OPENSSL_SOURCE_DIR $WORKDIR/work/openssl/openssl-$OPENSSL_VERSION
  set -xg OPENSSL_ROOT $OPENSSL_SOURCE_DIR/build  

  switch $BUILDMODE
    case "Debug"
      set mode debug
    case "Release" "RelWithDebInfo" "MinSizeRel"
      set mode release
    case '*'
      echo "Unknown BUILDMODE value: $BUILDMODE! Please, use `releaseMode` or `debugMode` oskar functions to set it."
      return 1
  end
    
  set -gx OPENSSL_USE_STATIC_LIBS "On"
  set -gx OPENSSL_PATH "$OPENSSL_ROOT/$mode/no-shared"
end

set -xg OPENSSL_ROOT_HOMEBREW ""

function checkBrewOpenSSL
  set -xg OPENSSL_ROOT_HOMEBREW ""
  if which -s brew
    set -l prefix (brew --prefix)
    if count $prefix/Cellar/openssl*/* > /dev/null
      set -l matcher "[0-9]\.[0-9]\.[0-9]"
      set -l sslVersion ""
      set -l sslPath ""
      findRequiredOpenSSL
      if test "$USE_STRICT_OPENSSL" = "On"
        set matcher $matcher"[a-z]"
        set sslVersion (echo "$OPENSSL_VERSION" | grep -o $matcher)
        set sslPath (realpath $prefix/Cellar/openssl*/* | grep -m 1 $sslVersion)
      else
        set sslVersion (echo "$OPENSSL_VERSION" | grep -o $matcher)'*'
        set sslPath (realpath $prefix/Cellar/openssl*/* | grep -m 1 $sslVersion)
    end

      if test "$sslPath" != ""; and test -e $sslPath/bin/openssl > /dev/null; and count $sslPath/lib/* > /dev/null
        set -l executable "$sslPath/bin/openssl"
        set -l cmd "$executable version | grep -o $matcher"
        set -l output (eval "arch -$ARCH $cmd")
        if test "$output" = (echo "$OPENSSL_VERSION" | grep -o $matcher)
          echo "Found matching OpenSSL $sslPath installed by Homebrew."
          set -xg OPENSSL_ROOT_HOMEBREW $sslPath
          return  
        end
      end
    end
  end
  echo "Couldn't find matching OpenSSL version installed by Homebrew! Please, try `brew install openssl` prior to check."
  return 1
end

function checkOskarOpenSSL
  findOpenSSLPath
  set -l executable "$OPENSSL_SOURCE_DIR/apps/openssl"
  if ! test -f "$executable"
    echo "Couldn't find OpenSSL $OPENSSL_VERSION at $OPENSSL_SOURCE_DIR!"
    false
    return 1
  end
  set -l cmd "$executable version | grep -o \"[0-9]\.[0-9]\.[0-9][a-z]\""
  set -l output (eval "arch -$ARCH $cmd")
  if test "$output" = "$OPENSSL_VERSION"
    echo "Found OpenSSL $OPENSSL_VERSION"
    true
    return
  else
    echo "Couldn't find OpenSSL $OPENSSL_VERSION!"
    false
    return 1
  end
end

function findRequiredCompiler
  set -l f $WORKDIR/work/ArangoDB/VERSIONS

  test -f $f
  or begin
    echo "Cannot find $f; make sure source is checked out"
    return 1
  end

  #if test "$COMPILER_VERSION" != ""
  #  echo "Compiler version already set to '$COMPILER_VERSION'"
  #  return 0
  #end

  set -l v (fgrep LLVM_CLANG_MACOS $f | awk '{print $2}' | tr -d '"' | tr -d "'")

  if test "$v" = ""
    echo "$f: no LLVM_CLANG_MACOS specified, using 13"
    compiler 13
  else
    echo "Using compiler '$v' from '$f'"
    compiler $v
  end
end

function findRequiredOpenSSL
  set -l f $WORKDIR/work/ArangoDB/VERSIONS

  test -f $f
  or begin
    echo "Cannot find $f; make sure source is checked out"
    return 1
  end

  #if test "$OPENSSL_VERSION" != ""
  #  echo "OpenSSL version already set to '$OPENSSL_VERSION'"
  #  return 0
  #end

  set -l v (fgrep OPENSSL_MACOS $f | awk '{print $2}' | tr -d '"' | tr -d "'" | grep -o "[0-9]\.[0-9]\.[0-9][a-z]")

  if test "$v" = ""
    echo "$f: no OPENSSL_MACOS specified, using 1.1.1g"
    opensslVersion 1.1.1g
  else
    echo "Using OpenSSL version '$v' from '$f'"
    opensslVersion $v
  end
end

function oskarOpenSSL
  set -xg USE_OSKAR_OPENSSL "On"
end

function ownOpenSSL
  set -xg USE_OSKAR_OPENSSL "Off"
end

if test -z "$USE_OSKAR_OPENSSL"
  if test "$IS_JENKINS" = "true"
    oskarOpenSSL
  else
    ownOpenSSL
  end
else
  set -gx USE_OSKAR_OPENSSL $USE_OSKAR_OPENSSL
end

function prepareOpenSSL
  if test "$USE_OSKAR_OPENSSL" = "On"
    findRequiredOpenSSL
    echo "Use OpenSSL within oskar: build $OPENSSL_VERSION if not present"

    if not checkOskarOpenSSL
      downloadOpenSSL
      and buildOpenSSL
      or return 1
    end

    echo "Set OPENSSL_ROOT_DIR via environment variable to $OPENSSL_PATH"
    set -xg OPENSSL_ROOT_DIR $OPENSSL_PATH
  else
    if checkBrewOpenSSL
      echo "Use local OpenSSL installed by Homebrew and set OPENSSL_ROOT_DIR environment variable to "
      set -xg OPENSSL_ROOT_DIR $OPENSSL_ROOT_HOMEBREW
    else
      echo "Use local OpenSSL: expect OPENSSL_ROOT_DIR environment variable"
      if test -z $OPENSSL_ROOT_DIR
        echo "Need OPENSSL_ROOT_DIR global variable!"
        return 1
      end
    end 
  end
end

## #############################################################################
## run without docker
## #############################################################################

function runLocal
  if test -z "$SSH_AUTH_SOCK"
    eval (ssh-agent -c) > /dev/null
    for key in ~/.ssh/id_rsa ~/.ssh/id_ed25519
      if test -f $key
        ssh-add $key
      end
    end
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end
  set -xg GIT_SSH_COMMAND "ssh -o StrictHostKeyChecking=no"
  set s 1
  begin
    pushd $WORKDIR
    eval $argv
    set s $status
    popd
  end
  if test -n "$agentstarted"
    ssh-agent -k > /dev/null
    set -e SSH_AUTH_SOCK
    set -e SSH_AGENT_PID
  end
  return $s
end

function checkoutArangoDB
  runLocal $SCRIPTSDIR/checkoutArangoDB.fish
  or return $status
  community
end

function checkoutEnterprise
  runLocal $SCRIPTSDIR/checkoutEnterprise.fish
  or return $status
  enterprise
end

function switchBranches
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/switchBranches.fish $argv
  and convertSItoJSON
  and set -gx MINIMAL_DEBUG_INFO (findMinimalDebugInfo)
  and findDefaultArchitecture
  and findRequiredCompiler
  and findUseARM
end

function clearWorkdir
  runLocal $SCRIPTSDIR/clearWorkdir.fish
end

function buildArangoDB
  checkoutIfNeeded
  and findDefaultArchitecture
  and findRequiredCompiler
  and findUseARM
  and findRequiredMinMacOS
  and prepareOpenSSL
  and runLocal $SCRIPTSDIR/buildArangoDB.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function buildArangoDB
  checkoutIfNeeded
  and findDefaultArchitecture
  and findRequiredCompiler
  and findUseARM
  and findRequiredMinMacOS
  and prepareOpenSSL
  and runLocal $SCRIPTSDIR/buildMacOs.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function makeArangoDB
  findDefaultArchitecture
  and findRequiredCompiler
  and findUseARM
  and findRequiredMinMacOS
  and prepareOpenSSL
  and runLocal $SCRIPTSDIR/makeArangoDB.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function buildStaticArangoDB
  buildArangoDB $argv
end

function makeStaticArangoDB
  makeArangoDB $argv
end

# ==============================================================================
# Build a Debian package
# ==============================================================================
function runInContainer
  if test -z "$SSH_AUTH_SOCK"
    sudo killall --older-than 8h ssh-agent 2>&1 > /dev/null
    eval (ssh-agent -c) > /dev/null
    for key in ~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/id_deploy
      if test -f $key
        ssh-add $key
      end
    end
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end

  set -l mirror

  if test -n "$GITHUB_MIRROR" -a -d "$GITHUB_MIRROR/mirror"
    set mirror -v $GITHUB_MIRROR/mirror:/mirror
  end

  # Run script in container in background, but print output and react to
  # a TERM signal to the shell or to a foreground subcommand. Note that the
  # container process itself will run as root and will be immune to SIGTERM
  # from a regular user. Therefore we have to do some Eiertanz to stop it
  # if we receive a TERM outside the container. Note that this does not
  # cover SIGINT, since this will directly abort the whole function.
  set c (docker run -d --cap-add=SYS_PTRACE --privileged --security-opt seccomp=unconfined \
             -v $WORKDIR/work/:$INNERWORKDIR \
             -v $SSH_AUTH_SOCK:/ssh-agent \
             -v "$WORKDIR/jenkins/helper":"$WORKSPACE/jenkins/helper" \
             -v "$WORKDIR/scripts/":"/scripts" \
             $mirror \
             -e ARANGODB_DOCS_BRANCH="$ARANGODB_DOCS_BRANCH" \
             -e ARANGODB_PACKAGES="$ARANGODB_PACKAGES" \
             -e ARANGODB_REPO="$ARANGODB_REPO" \
             -e ARANGODB_VERSION="$ARANGODB_VERSION" \
             -e DUMPDEVICE=$DUMPDEVICE \
             -e ARCH="$ARCH" \
             -e SAN="$SAN" \
             -e SAN_MODE="$SAN_MODE" \
             -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
             -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
             -e BUILD_SEPP="$BUILD_SEPP" \
             -e BUILDMODE="$BUILDMODE" \
             -e CCACHEBINPATH="$CCACHEBINPATH" \
             -e COMPILER_VERSION=(echo (string replace -r '[_\-].*$' "" $COMPILER_VERSION)) \
             -e COVERAGE="$COVERAGE" \
             -e DEFAULT_ARCHITECTURE="$DEFAULT_ARCHITECTURE" \
             -e ENTERPRISEEDITION="$ENTERPRISEEDITION" \
             -e FORCE_DISABLE_AVX="$FORCE_DISABLE_AVX" \
             -e GID=(id -g) \
             -e GIT_CURL_VERBOSE="$GIT_CURL_VERBOSE" \
             -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
             -e GIT_TRACE="$GIT_TRACE" \
             -e GIT_TRACE_PACKET="$GIT_TRACE_PACKET" \
             -e INNERWORKDIR="$INNERWORKDIR" \
             -e IONICE="$IONICE" \
             -e JEMALLOC_OSKAR="$JEMALLOC_OSKAR" \
             -e KEYNAME="$KEYNAME" \
             -e LDAPHOST="$LDAPHOST" \
             -e LDAPHOST2="$LDAPHOST2" \
             -e MAINTAINER="$MAINTAINER" \
             -e MINIMAL_DEBUG_INFO="$MINIMAL_DEBUG_INFO" \
             -e NODE_NAME="$NODE_NAME" \
             -e NOSTRIP="$NOSTRIP" \
             -e NO_RM_BUILD="$NO_RM_BUILD" \
             -e ONLYGREY="$ONLYGREY" \
             -e OPENSSL_VERSION="$OPENSSL_VERSION" \
             -e PACKAGE_STRIP="$PACKAGE_STRIP" \
             -e PARALLELISM="$PARALLELISM" \
             -e PLATFORM="$PLATFORM" \
             -e SCCACHE_BUCKET="$SCCACHE_BUCKET" \
             -e SCCACHE_ENDPOINT="$SCCACHE_ENDPOINT" \
             -e SCCACHE_GCS_BUCKET="$SCCACHE_GCS_BUCKET" \
             -e SCCACHE_GCS_KEY_PATH="$SCCACHE_GCS_KEY_PATH" \
             -e SCCACHE_IDLE_TIMEOUT="$SCCACHE_IDLE_TIMEOUT" \
             -e SCCACHE_MEMCACHED="$SCCACHE_MEMCACHED" \
             -e SCCACHE_REDIS="$SCCACHE_REDIS" \
             -e SCRIPTSDIR="$SCRIPTSDIR" \
             -e SHOW_DETAILS="$SHOW_DETAILS" \
             -e SKIPGREY="$SKIPGREY" \
             -e SKIPNONDETERMINISTIC="$SKIPNONDETERMINISTIC" \
             -e SKIPTIMECRITICAL="$SKIPTIMECRITICAL" \
             -e SKIP_MAKE="$SKIP_MAKE" \
             -e SSH_AUTH_SOCK=/ssh-agent \
             -e STORAGEENGINE="$STORAGEENGINE" \
             -e TEST="$TEST" \
             -e TESTSUITE="$TESTSUITE" \
             -e UID=(id -u) \
             -e USE_ARM="$USE_ARM" \
             -e USE_CCACHE="$USE_CCACHE" \
             -e USE_STRICT_OPENSSL="$USE_STRICT_OPENSSL" \
             -e VERBOSEBUILD="$VERBOSEBUILD" \
             -e VERBOSEOSKAR="$VERBOSEOSKAR" \
             -e WORKSPACE="$WORKSPACE" \
             -e PROMTOOL_PATH="$PROMTOOL_PATH" \
             $argv)
  function termhandler --on-signal TERM --inherit-variable c
    if test -n "$c"
      docker stop $c >/dev/null
      docker rm $c >/dev/null
    end
  end
  docker logs -f $c          # print output to stdout
  docker stop $c >/dev/null  # happens when the previous command gets a SIGTERM
  set s (docker inspect $c --format "{{.State.ExitCode}}")
  docker rm $c >/dev/null
  functions -e termhandler
  # Cleanup ownership:
  docker run \
      -v $WORKDIR/work:$INNERWORKDIR \
      -e UID=(id -u) \
      -e GID=(id -g) \
      -e INNERWORKDIR=$INNERWORKDIR \
      --rm \
      $ALPINEUTILSIMAGE $SCRIPTSDIR/recursiveChown.fish

  if test -n "$agentstarted"
    ssh-agent -k > /dev/null
    set -e SSH_AUTH_SOCK
    set -e SSH_AGENT_PID
  end
  return $s
end


function buildDebianPackage
  if test ! -d $WORKDIR/work/ArangoDB/build
    echo buildDebianPackage: build directory does not exist
    return 1
  end

  set -l pd "default"

  if test -d $WORKDIR/debian/$ARANGODB_PACKAGES
    set pd "$ARANGODB_PACKAGES"
  end

  # This assumes that a static build has already happened
  # Must have set ARANGODB_DEBIAN_UPSTREAM and ARANGODB_DEBIAN_REVISION,
  # for example by running findArangoDBVersion.
  set -l v "$ARANGODB_DEBIAN_UPSTREAM-$ARANGODB_DEBIAN_REVISION"
  set -l ch $WORKDIR/work/debian/changelog
  set -l SOURCE $WORKDIR/debian/$pd
  set -l TARGET $WORKDIR/work/debian
  set -l EDITION arangodb3
  set -l EDITIONFOLDER $SOURCE/community
  set -l ARCH (dpkg --print-architecture)

  if test "$ENTERPRISEEDITION" = "On"
    echo Building enterprise edition debian package...
    set EDITION arangodb3e
    set EDITIONFOLDER $SOURCE/enterprise
  else
    echo Building community edition debian package...
  end

  rm -rf $TARGET
  and cp -a $EDITIONFOLDER $TARGET
  and for f in arangodb3.init arangodb3.service compat config templates preinst prerm postinst postrm rules
    cp $SOURCE/common/$f $TARGET/$f
    sed -e "s/@EDITION@/$EDITION/g" -i $TARGET/$f
    if test $PACKAGE_STRIP = All
      sed -i -e "s/@DEBIAN_STRIP_ALL@//"                 -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_EXCEPT_ARANGOD@/echo /" -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_NONE@/echo /"           -i $TARGET/$f
    else if test $PACKAGE_STRIP = ExceptArangod
      sed -i -e "s/@DEBIAN_STRIP_ALL@/echo /"            -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_EXCEPT_ARANGOD@//"      -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_NONE@/echo /"           -i $TARGET/$f
    else
      sed -i -e "s/@DEBIAN_STRIP_ALL@/echo /"            -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_EXCEPT_ARANGOD@/echo /" -i $TARGET/$f
      sed -i -e "s/@DEBIAN_STRIP_NONE@//"                -i $TARGET/$f
    end
  end
  and echo -n "$EDITION " > $ch
  and cp -a $SOURCE/common/source $TARGET
  and echo "($v) UNRELEASED; urgency=medium" >> $ch
  and echo >> $ch
  and echo "  * New version." >> $ch
  and echo >> $ch
  and echo -n " -- ArangoDB <hackers@arangodb.com>  " >> $ch
  and date -R >> $ch
  and sed -i "s/@ARCHITECTURE@/$ARCH/g" $TARGET/control
  and runInContainer $UBUNTUPACKAGINGIMAGE $SCRIPTSDIR/buildDebianPackage.fish
  set -l s $status
  if test $s -ne 0
    echo Error when building a debian package
    return $s
  end
end

function downloadStarterWithAlpine
  mkdir -p $WORKDIR/work/$THIRDPARTY_BIN
  and runInContainer $ALPINEUTILSIMAGE $SCRIPTSDIR/downloadStarter.fish $INNERWORKDIR/$THIRDPARTY_BIN $argv
  and convertSItoJSON
end

function findStaticBuildImage
      echo $ALPINEBUILDIMAGE
end
function findStaticBuildScript
      echo buildAlpine3.fish
end



function buildStaticArangoDBWithAlpine
  checkoutIfNeeded
  and findRequiredCompiler
  and findRequiredOpenSSL
  and findDefaultArchitecture
  and findUseARM
  and runInContainer (findStaticBuildImage) $SCRIPTSDIR/(findStaticBuildScript) $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function buildCommunityPackageWithAlpine
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  sanOff
  and maintainerOff
  and releaseMode
  and community
  and set -xg NOSTRIP 1
  and buildStaticArangoDBWithAlpine
  and downloadStarterWithAlpine
  and buildDebianPackage

  if test $status -ne 0
    echo Building community release failed.
    return 1
  end
end

# ==============================================================================
# End Additions
# ==============================================================================

function oskar
  checkoutIfNeeded
  and findRequiredCompiler
  and runLocal $SCRIPTSDIR/runTests.fish
end

function oskarFull
  checkoutIfNeeded
  and findRequiredCompiler
  and runLocal $SCRIPTSDIR/runFullTests.fish
end

function rlogTests
  checkoutIfNeeded
  and findRequiredCompiler
  and runLocal $SCRIPTSDIR/rlog/pr.fish $argv
end

function pushOskar
  pushd $WORKDIR
  and source helper.fish
  and git push
  or begin ; popd ; return 1 ; end
  popd
end

function updateOskarOnly
  pushd $WORKDIR
  and git checkout -- .
  and git pull
  and source helper.fish
  or begin ; popd ; return 1 ; end
  popd
end

function updateOskar
  updateOskarOnly
end

function updateDockerBuildImage
end

function downloadStarter
  mkdir -p $WORKDIR/work/$THIRDPARTY_BIN
  and runLocal $SCRIPTSDIR/downloadStarter.fish $INNERWORKDIR/$THIRDPARTY_BIN $argv
  and convertSItoJSON
end

function downloadSyncer
  mkdir -p $WORKDIR/work/$THIRDPARTY_SBIN
  and runLocal $SCRIPTSDIR/downloadSyncer.fish $INNERWORKDIR/$THIRDPARTY_SBIN $argv
  and convertSItoJSON
end

function buildPackage
  # This assumes that a build has already happened

  if test "$ENTERPRISEEDITION" = "On"
    echo Building enterprise edition MacOs bundle...
  else
    echo Building community edition MacOs bundle...
  end

  runLocal $SCRIPTSDIR/buildMacOsPackage.fish $ARANGODB_PACKAGES
  and buildTarGzPackage
end

function cleanupThirdParty
  rm -rf $WORKDIR/work/$THIRDPARTY_BIN
  rm -rf $WORKDIR/work/$THIRDPARTY_SBIN
end

function buildEnterprisePackage
  if test "$DOWNLOAD_SYNC_USER" = ""
    echo "Need to set environment variable DOWNLOAD_SYNC_USER."
    return 1
  end
 
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  sanOff
  and maintainerOff
  and releaseMode
  and enterprise
  and set -xg NOSTRIP 1
  and cleanupThirdParty
  and set -gx THIRDPARTY_SBIN_LIST $WORKDIR/work/$THIRDPARTY_SBIN/arangosync
  and downloadStarter
  and downloadSyncer
  and copyRclone "macos"
  and if test "$USE_RCLONE" = "true"
    set -gx THIRDPARTY_SBIN_LIST "$THIRDPARTY_SBIN_LIST\;$WORKDIR/work/$THIRDPARTY_SBIN/rclone-arangodb"
  end
  and buildArangoDB \
      -DPACKAGING=Bundle \
      -DPACKAGE_TARGET_DIR=$INNERWORKDIR \
      -DTHIRDPARTY_SBIN=$THIRDPARTY_SBIN_LIST \
      -DTHIRDPARTY_BIN=$WORKDIR/work/$THIRDPARTY_BIN/arangodb \
      -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX
  and buildPackage

  if test $status != 0
    echo Building enterprise release failed, stopping.
    return 1
  end
end

function buildCommunityPackage
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  sanOff
  and maintainerOff
  and releaseMode
  and community
  and set -xg NOSTRIP 1
  and cleanupThirdParty
  and downloadStarter
  and buildArangoDB \
      -DPACKAGING=Bundle \
      -DPACKAGE_TARGET_DIR=$INNERWORKDIR \
      -DTHIRDPARTY_BIN=$WORKDIR/work/$THIRDPARTY_BIN/arangodb \
      -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX
  and buildPackage

  if test $status != 0
    echo Building community release failed.
    return 1
  end
end

function buildTarGzPackage
  pushd $INNERWORKDIR/ArangoDB/build
  and rm -rf install
  and make install DESTDIR=install
  and makeJsSha1Sum (pwd)/install/opt/arangodb/share/arangodb3/js
  and if test "$ENTERPRISEEDITION" = "On"
        pushd install/opt/arangodb/bin
        ln -s ../sbin/arangosync
        popd
      end
  and mkdir -p install/usr
  and mv install/opt/arangodb/bin install/usr
  and mv install/opt/arangodb/sbin install/usr
  and mv install/opt/arangodb/share install/usr
  and mv install/opt/arangodb/etc install
  and rm -rf install/opt
  and buildTarGzPackageHelper "macos"
  or begin ; popd ; return 1 ; end
  popd
end

## #############################################################################
## helper functions
## #############################################################################

function findCompilerVersion
  echo $COMPILER_VERSION
end

function findOpenSSLVersion
  echo $OPENSSL_VERSION
end

## #############################################################################
## set PARALLELISM in a sensible way
## #############################################################################

parallelism (sysctl -n hw.logicalcpu)

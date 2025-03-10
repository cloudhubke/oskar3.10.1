#!/bin/sh
set -e

export OPENSSLVERSION=$1
test -n "$OPENSSLVERSION"
export OPENSSLPATH=`echo $OPENSSLVERSION | tr -d "a-zA-Z"`

# Compile openldap library:
export OPENLDAPVERSION=2.6.3
cd /tmp
curl -O ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-$OPENLDAPVERSION.tgz
tar xzf openldap-$OPENLDAPVERSION.tgz
cd openldap-$OPENLDAPVERSION
# cp -a /tools/config.* ./build
CPPFLAGS=-I/opt/openssl-$OPENSSLPATH/include \
LDFLAGS=-L/opt/openssl-$OPENSSLPATH/lib \
  ./configure --prefix=/opt/openssl-$OPENSSLPATH --with-threads --with-tls=openssl --enable-static --disable-shared
make depend && make -j64
make install
cd /tmp
rm -rf openldap-$OPENLDAPVERSION.tgz openldap-$OPENLDAPVERSION


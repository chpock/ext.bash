#!/bin/bash

set -e

TAR_VERSION="1.35"

BUILD_DOCKER_IMAGE="dokken/centos-6"
MY_HOME="$(cd "$(dirname "$0")"; pwd)"
MY_NAME="$(basename "$0")"

if [ ! -e /.dockerenv ]; then
    exec docker run --rm -ti \
        -w /tmp/work \
        -v "${MY_HOME}:/tmp/work" \
        -e EUID="$(id -u)" -e EGID="$(id -g)" \
        "$BUILD_DOCKER_IMAGE" \
        bash "/tmp/work/$MY_NAME"
fi

OUTPUT="$MY_HOME/tar-portable"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
OUTPUT="${OUTPUT}.${TAR_VERSION}.${OS}.${ARCH}"

DIR_BUILD="/tmp/build"
DIR_INSTALL="/tmp/install"

set -x

rm -f "$OUTPUT"

yum install -y make gcc libtool glibc-static

mkdir -p "$DIR_BUILD"
cd "$DIR_BUILD"

curl --silent --fail https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.gz | tar xz
cd tar-*
LDFLAGS="-static-libgcc" FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=$DIR_INSTALL/tar --with-gzip=gzip-portable
make -j8
#make check
make install-strip

sed "s/!TAR_VERSION!/$TAR_VERSION/g" "$MY_HOME/stub.sh" > "$OUTPUT"
gzip < "$DIR_INSTALL/tar/bin/tar" >> "$OUTPUT"

chown ${EUID}:${EGID} "$OUTPUT"
chmod +x "$OUTPUT"
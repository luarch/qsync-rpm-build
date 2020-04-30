#!/bin/bash

set -eu

BUILD_DIR="_build"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

URL=$(\
    curl -s https://www.qnap.com.cn/zh-cn/utilities/essentials | \
    grep 'http.*Qsync.*Ubuntu.*deb' -o \
)

echo "Parsed deb download url: ${URL}. Downloading..."

curl $URL -O

echo "Downloaded. Unpacking with alien..."

alien -r -g QNAPQsyncClientUbuntux64-*.deb
rm QNAPQsyncClientUbuntux64-*.deb

cd qnapqsyncclient*

mv usr/lib usr/lib64

echo "Patching RPMBuild spec..."

LINE=$(grep -no '%description' QNAPQsyncClient-*.spec | cut  -f1 -d':')

sed -i "${LINE},\$d" QNAPQsyncClient-*.spec

cat >> QNAPQsyncClient-*.spec << EOM
# disable automatic dependency and provides generation with:
%define __find_provides %{nil}
%define __find_requires %{nil}
%define _use_internal_dependency_generator 0
Autoprov: 0
Autoreq: 0

Requires: nautilus-extensions

%description
QNAP Qsync Client for Ubuntu x64.

%files
#XXX need to move nautilus extensions
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.a"
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.la"
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.so"
"/usr/local/bin/QNAP/QsyncClient/"
"/usr/local/lib/QNAP/QsyncClient/"
"/usr/share/applications/QNAPQsyncClient.desktop"
"/usr/share/pixmaps/Qsync.png"
"/usr/share/nautilus-qsync/"
EOM

echo "Building rpm..."

rpmbuild -bb QNAPQsyncClient-*.spec --buildroot ${PWD}


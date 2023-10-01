#!/bin/sh

BASE_DIR="${PWD}"
BUILD_DIR="${BASE_DIR}/build"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

curl -Lk https://www.samba.org/ftp/talloc/talloc-2.4.1.tar.gz | gzip -d | tar -x
curl -Lk https://github.com/termux/proot/archive/refs/heads/master.tar.gz | gzip -d | tar -x

# Generate diff file
# cd proot-master
# git init
# git add -A
# git commit -m untoucheds
# cd -

patch --directory="proot-master" --strip=1 --input="${BASE_DIR}/patches/proot-base.patch"
patch --directory="proot-master" --strip=1 --input="${BASE_DIR}/patches/proot-try-TMPDIR.patch"

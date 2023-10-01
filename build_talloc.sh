#!/bin/bash

set -eu

BASE_DIR="${PWD}"
BUILD_DIR="${BASE_DIR}/build"

: ${ANDROID_NDK_HOME:=/media/user/SAMSUNG_64GB/programs/android-ndk-r26}

for ARCH in arm arm64 x86 x86_64; do
	. ./android-toolchain "${ANDROID_NDK_HOME}" 24 "${ARCH}"

	INSTALL_ROOT="${BUILD_DIR}/root-${ARCH}/root"
	STATIC_ROOT="${BUILD_DIR}/static-${ARCH}/root"

	cd "${BUILD_DIR}/talloc-2.4.1"

	make distclean || true

	cat <<EOF >cross-answers.txt
Checking uname sysname type: "Linux"
Checking uname machine type: "dontcare"
Checking uname release type: "dontcare"
Checking uname version type: "dontcare"
Checking simple C program: OK
rpath library support: OK
-Wl,--version-script support: FAIL
Checking getconf LFS_CFLAGS: OK
Checking for large file support without additional flags: OK
Checking for -D_FILE_OFFSET_BITS=64: $FILE_OFFSET_BITS
Checking for -D_LARGE_FILES: OK
Checking correct behavior of strtoll: OK
Checking for working strptime: OK
Checking for C99 vsnprintf: OK
Checking for HAVE_SHARED_MMAP: OK
Checking for HAVE_MREMAP: OK
Checking for HAVE_INCOHERENT_MMAP: OK
Checking for HAVE_SECURE_MKSTEMP: OK
Checking getconf large file support flags work: OK
Checking for HAVE_IFACE_IFCONF: FAIL
EOF

	./configure build \
		--prefix="${INSTALL_ROOT}" \
		--disable-rpath \
		--disable-python --cross-compile \
		--cross-answers=cross-answers.txt

	mkdir -p "$STATIC_ROOT/include"
	mkdir -p "$STATIC_ROOT/lib"

	"$AR" rcs "$STATIC_ROOT/lib/libtalloc.a" bin/default/talloc*.o
	cp -f talloc.h "$STATIC_ROOT/include"
	cd -
done

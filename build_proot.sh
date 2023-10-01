#!/bin/bash

set -eu

BASE_DIR="${PWD}"
BUILD_DIR="${BASE_DIR}/build"

: ${ANDROID_NDK_HOME:=/media/user/SAMSUNG_64GB/programs/android-ndk-r26}

DEFAULT_CFLAGS="${CFLAGS-}"

reset_env() {
	unset LDFLAGS
	unset PROOT_UNBUNDLE_LOADER
	unset PROOT_UNBUNDLE_LOADER_NAME
	unset PROOT_UNBUNDLE_LOADER_NAME_32
	export CFLAGS="${DEFAULT_CFLAGS} -I${STATIC_ROOT}/include -Werror=implicit-function-declaration"
}

for ARCH in arm arm64 x86 x86_64; do
	# for ARCH in arm64; do
	. ./android-toolchain "${ANDROID_NDK_HOME}" 24 "${ARCH}"

	INSTALL_ROOT="${BUILD_DIR}/root-${ARCH}/root"
	STATIC_ROOT="${BUILD_DIR}/static-${ARCH}/root"

	cd "${BUILD_DIR}/proot-master/src"

	# build unbundled
	reset_env
	export LDFLAGS="-L${STATIC_ROOT}/lib"
	export PROOT_UNBUNDLE_LOADER='../libexec/proot'

	make distclean || true
	make V=1 "PREFIX=${INSTALL_ROOT}" install
	make distclean || true
	CFLAGS="${CFLAGS} -DUSERLAND" make V=1 "PREFIX=${INSTALL_ROOT}" proot
	cp -a ./proot "${INSTALL_ROOT}/bin/proot-userland"

	# build statically
	reset_env
	export LDFLAGS="-L${STATIC_ROOT}/lib -static -ffunction-sections -fdata-sections -Wl,--gc-sections"

	make distclean || true
	make V=1 "PREFIX=${INSTALL_ROOT}-static" install
	make distclean || true
	CFLAGS="${CFLAGS} -DUSERLAND" make V=1 "PREFIX=${INSTALL_ROOT}-static" proot
	cp -a ./proot "${INSTALL_ROOT}-static/bin/proot-userland"
	rm -rf "${INSTALL_ROOT}-static/libexec"

	# build .so for android apk
	reset_env
	export LDFLAGS="-L${STATIC_ROOT}/lib"
	export PROOT_UNBUNDLE_LOADER='.'
	export PROOT_UNBUNDLE_LOADER_NAME='libproot-loader.so'
	export PROOT_UNBUNDLE_LOADER_NAME_32='libproot-loader32.so'

	make distclean || true
	make V=1 "PREFIX=${INSTALL_ROOT}-apk" install
	mv "${INSTALL_ROOT}-apk/bin/proot" "${INSTALL_ROOT}-apk/bin/libproot.so"
	make distclean || true
	CFLAGS="${CFLAGS} -DUSERLAND" make V=1 "PREFIX=${INSTALL_ROOT}-apk" proot
	cp -a ./proot "${INSTALL_ROOT}-apk/bin/libproot-userland.so"

	cd -
done

# strip binary
find build/ -path '*/root-*' -type f -executable -exec "${STRIP}" {} \;

tree build/root-*

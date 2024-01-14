#!/bin/bash

## This is where the tools will end up
export PREFIX="$PWD/out"
export SRC="$PWD/src"
export BUILD="$PWD/build"

# Prefix of the produced assemblies (for example i686-elf-gcc)
export TARGET=i686-elf

# Add the new installation to the PATH variable temporarily
# since it is required for the gcc build
export PATH="$PREFIX/bin:$PATH"

readonly BINUTILS_VERSION="2.41"
readonly GCC_VERSION="13.2.0"

fatal()
{
    echo "Nooo....$1"
    exit 1
}

rm -rf "$BUILD"
rm -rf "$PREFIX"

mkdir -p "$SRC"
mkdir -p "$PREFIX"
mkdir -p "$BUILD"/{gcc,binutils}

# Download/unpack sources
cd "$SRC" || fatal
wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz || fatal "can't download binutils"
wget https://ftp.mpi-inf.mpg.de/mirrors/gnu/mirror/gcc.gnu.org/pub/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz || fatal "can't download gcc"
tar xf binutils-${BINUTILS_VERSION}.tar.xz
tar xf gcc-${GCC_VERSION}.tar.xz

# Build
cd "$BUILD/binutils" || fatal

echo "Binutils:build..."
../../src/binutils-$BINUTILS_VERSION/configure \
  --target=$TARGET \
  --prefix="$PREFIX" \
  --with-sysroot \
  --disable-nls \
  --disable-werror || fatal "can't configure"

make -j"$(nproc)" > /dev/null || fatal "can't build"
make install

cd "$BUILD/gcc" || fatal
echo "GCC:build..."
../../src/gcc-${GCC_VERSION}/configure \
  --target=$TARGET \
  --prefix="$PREFIX" \
  --disable-nls \
  --enable-languages=c,c++ \
  --without-headers || fatal "can't configure"

make -j"$(nproc)" all-gcc > /dev/null || fatal "can't build"
make -j"$(nproc)" all-target-libgcc > /dev/null || fatal "can't build"
make -j"$(nproc)" install-gcc > /dev/null || fatal "can't build"
make -j"$(nproc)" install-target-libgcc > /dev/null || fatal "can't build"

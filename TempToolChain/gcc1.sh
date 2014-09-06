#!/bin/bash

tar -Jxf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -Jxf ../gmp-5.1.3.tar.xz
mv -v gmp-5.1.3 gmp
tar -zxf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

# The following command will change the location of GCC's default dynamic linker to use the one installed in /tools. It also removes /usr/include from GCC's include search path. Issue:

for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

# In case the above seems hard to follow, let's break it down a bit. First we find all the files under the gcc/config directory that are named either linux.h, linux64.h or sysv4.h. For each file found, we copy it to a file of the same name but with an added suffix of “.orig”. Then the first sed expression prepends “/tools” to every instance of “/lib/ld”, “/lib64/ld” or “/lib32/ld”, while the second one replaces hard-coded instances of “/usr”. Next, we add our define statements which alter the default startfile prefix to the end of the file. Note that the trailing “/” in “/tools/lib/” is required. Finally, we use touch to update the timestamp on the copied files. When used in conjunction with cp -u, this prevents unexpected changes to the original files in case the commands are inadvertently run twice.

# GCC doesn't detect stack protection correctly, which causes problems for the build of Glibc-2.19, so fix that by issuing the following command:

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

mkdir -v ../gcc-build
cd ../gcc-build

../gcc-4.8.2/configure                               \
    --target=$LFS_TGT                                \
    --prefix=/tools                                  \
    --with-sysroot=$LFS                              \
    --with-newlib                                    \
    --without-headers                                \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --disable-nls                                    \
    --disable-shared                                 \
    --disable-multilib                               \
    --disable-decimal-float                          \
    --disable-threads                                \
    --disable-libatomic                              \
    --disable-libgomp                                \
    --disable-libitm                                 \
    --disable-libmudflap                             \
    --disable-libquadmath                            \
    --disable-libsanitizer                           \
    --disable-libssp                                 \
    --disable-libstdc++-v3                           \
    --enable-languages=c,c++                         \
    --with-mpfr-include=$(pwd)/../gcc-4.8.2/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs

	
# The meaning of the configure options:
# --with-newlib
# Since a working C library is not yet available, this ensures that the inhibit_libc constant is defined when building libgcc. This prevents the compiling of any code that requires libc support.
# --without-headers
# When creating a complete cross-compiler, GCC requires standard headers compatible with the target system. For our purposes these headers will not be needed. This switch prevents GCC from looking for them.

# --with-local-prefix=/tools
# The local prefix is the location in the system that GCC will search for locally installed include files. The default is /usr/local. Setting this to /tools helps keep the host location of /usr/local out of this GCC's search path.

# --with-native-system-header-dir=/tools/include
# By default GCC searches /usr/include for system headers. In conjunction with the sysroot switch, this would translate normally to $LFS/usr/include. However the headers that will be installed in the next two sections will go to $LFS/tools/include. This switch ensures that gcc will find them correctly. In the second pass of GCC, this same switch will ensure that no headers from the host system are found.

# --disable-shared
# This switch forces GCC to link its internal libraries statically. We do this to avoid possible issues with the host system.
# --disable-decimal-float, --disable-threads, --disable-libatomic, --disable-libgomp, --disable-libitm, --disable-libmudflap, --disable-libquadmath, --disable-libsanitizer, --disable-libssp, --disable-libstdc++-v3
# These switches disable support for the decimal floating point extension, threading, libatomic, libgomp, libitm, libmudflap, libquadmath, libsanitizer, libssp and the C++ standard library respectively. These features will fail to compile when building a cross-compiler and are not necessary for the task of cross-compiling the temporary libc.

# --disable-multilib
# On x86_64, LFS does not yet support a multilib configuration. This switch is harmless for x86.
# --enable-languages=c,c++
# This option ensures that only the C and C++ compilers are built. These are the only languages needed now.

# --with-mpfr-*
# These options enable the build system to correctly use the in-tree copy of the MPFR sources.

# Compile GCC by running:
make

# Compilation is now complete. At this point, the test suite would normally be run, but, as mentioned before, the test suite framework is not in place yet. The benefits of running the tests at this point are minimal since the programs from this first pass will soon be replaced.

# Install the package:
make install

# Using --disable-shared means that the libgcc_eh.a file isn't created and installed. The Glibc package depends on this library as it uses -lgcc_eh within its build system. This dependency can be satisfied by creating a symlink to libgcc.a, since that file will end up containing the objects normally contained in libgcc_eh.a:

ln -sv libgcc.a `$LFS_TGT-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`
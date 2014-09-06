#!/bin/bash
mkdir -v ../binutils-build
cd ../binutils-build.
../binutils-2.24/configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror
	
# The meaning of the configure options:

# --prefix=/tools
# This tells the configure script to prepare to install the Binutils programs in the /tools directory.
# --with-sysroot=$LFS
# For cross compilation, this tells the build system to look in $LFS for the target system libraries as needed.

# --with-lib-path=/tools/lib
# This specifies which library path the linker should be configured to use.

# --target=$LFS_TGT
# Because the machine description in the LFS_TGT variable is slightly different than the value returned by the config.guess script, this switch will tell the configure script to adjust Binutil's build system for building a cross linker.

# --disable-nls
# This disables internationalization as i18n is not needed for the temporary tools.
# --disable-werror
# This prevents the build from stopping in the event that there are warnings from the host's compiler.
# Continue with compiling the package:

make

# Compilation is now complete. Ordinarily we would now run the test suite, but at this early stage the test suite framework (Tcl, Expect, and DejaGNU) is not yet in place. The benefits of running the tests at this point are minimal since the programs from this first pass will soon be replaced by those from the second.

# If building on x86_64, create a symlink to ensure the sanity of the toolchain:


case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
# Install the package:
make install

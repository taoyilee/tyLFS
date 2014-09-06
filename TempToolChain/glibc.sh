#!/bin/bash

if [ ! -r /usr/include/rpc/types.h ]; then
  su -c 'mkdir -pv /usr/include/rpc'
  su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
fi

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.19/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.19/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes
	  
# The meaning of the configure options:

# --host=$LFS_TGT, --build=$(../glibc-2.19/scripts/config.guess)
# The combined effect of these switches is that Glibc's build system configures itself to cross-compile, using the cross-linker and cross-compiler in /tools.
# --disable-profile
# This builds the libraries without profiling information. Omit this option if profiling on the temporary tools is necessary.
# --enable-kernel=2.6.32
# This tells Glibc to compile the library with support for 2.6.32 and later Linux kernels. Workarounds for older kernels are not enabled.
# --with-headers=/tools/include
# This tells Glibc to compile itself against the headers recently installed to the tools directory, so that it knows exactly what features the kernel has and can optimize itself accordingly.
# libc_cv_forced_unwind=yes
# The linker installed during Section 5.4, “Binutils-2.24 - Pass 1” was cross-compiled and as such cannot be used until Glibc has been installed. This means that the configure test for force-unwind support will fail, as it relies on a working linker. The libc_cv_forced_unwind=yes variable is passed in order to inform configure that force-unwind support is available without it having to run the test.
# libc_cv_c_cleanup=yes
# Simlarly, we pass libc_cv_c_cleanup=yes through to the configure script so that the test is skipped and C cleanup handling support is configured.
# libc_cv_ctors_header=yes
# Simlarly, we pass libc_cv_ctors_header=yes through to the configure script so that the test is skipped and gcc constructor support is configured.

# During this stage the following warning might appear:
	# configure: WARNING:
	# *** These auxiliary programs are missing or
	# *** incompatible versions: msgfmt
	# *** some features will be disabled.
	# *** Check the INSTALL file for required versions.
	
# The missing or incompatible msgfmt program is generally harmless. This msgfmt program is part of the Gettext package which the host distribution should provide.

# Compile the package:
make
# Install the package:
make install

# At this point, it is imperative to stop and ensure that the basic functions (compiling and linking) of the new toolchain are working as expected. To perform a sanity check, run the following commands:
echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'

# If everything is working correctly, there should be no errors, and the output of the last command will be of the form:

# [Requesting program interpreter: /tools/lib/ld-linux.so.2]

# TODO: Write a auto checker for this; throw error and pause if anything goes wrong

# Note that /tools/lib, or /tools/lib64 for 64-bit machines appears as the prefix of the dynamic linker.
# If the output is not shown as above or there was no output at all, then something is wrong. Investigate and retrace the steps to find out where the problem is and correct it. This issue must be resolved before continuing on.
# Once all is well, clean up the test files:
rm -v dummy.c a.out

#!/bin/bash

# First, apply the following patch to fix various bugs that have been addressed upstream:
patch -Np1 -i ../bash-4.2-fixes-12.patch
# Prepare Bash for compilation:

./configure --prefix=/tools --without-bash-malloc
# The meaning of the configure options:

# --without-bash-malloc
# This option turns off the use of Bash's memory allocation (malloc) function which is known to cause segmentation faults. By turning this option off, Bash will use the malloc functions from Glibc which are more stable.
# Compile the package:

make
make tests
make install

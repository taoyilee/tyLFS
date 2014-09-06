#!/bin/bash
./configure --prefix=/tools --enable-install-program=hostname

# The meaning of the configure options:

# --enable-install-program=hostname
# This enables the hostname binary to be built and installed ¡V it is disabled by default but is required by the Perl test suite.

# Compile the package:
make
# Compilation is now complete. As discussed earlier, running the test suite is not mandatory for the temporary tools here in this chapter. To run the Coreutils test suite anyway, issue the following command:
make RUN_EXPENSIVE_TESTS=yes check

#!/bin/bash
export LFS=/mnt/lfs
mkdir -v $LFS/sources
wget -i tarball.list -P $LFS/sources

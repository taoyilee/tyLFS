#!/bin/bash
export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 /dev/sda1 $LFS

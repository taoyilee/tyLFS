#!/bin/bash
mkdir $LFS/sources/extracted
cd $LFS/sources/extracted
find $LFS/sources -name "*tar*" | xargs -i tar -xvf {}

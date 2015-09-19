#!/bin/bash

# This script use to genrate package MD5 value fit for Moss packages.info
# Usage: package_info.sh package

if [ -z ${1} ]; then
    echo 'You should specify a package file!'
    exit 1
fi

if [ ! -x "/usr/bin/md5sum" ]; then
    echo 'md5sum not found! Installing...'
    yum install -y coreutils || echo 'md5sum install failed!' && exit 1
fi

PKG=$(basename ${1})

MD5=$(md5sum ${1} | awk -F ' ' '{print $1}')
echo "'${PKG}|${MD5}'"

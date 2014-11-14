#!/bin/bash
if ! grep '^LIBXML2$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${LIBXML2_SRC}
    get_file
    unpack

## get dependent library dir
    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}

## use ldflags and cppflags for compile and link
    LDFLAGS="-L${ZLIB_DIR}/lib -Wl,-rpath,${ZLIB_DIR}/lib"
    CPPFLAGS="-I${ZLIB_DIR}/include"

## compile
    CONFIG="./configure \
    --prefix=${INST_DIR}/${SRC_DIR} \
    --disable-static \
    --with-zlib=${ZLIB_DIR}"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/libxml2'
    compile

## record installed tag 
    echo 'LIBXML2' >> ${INST_LOG}
else
    succ_msg "libmxl2 already installed!"
fi

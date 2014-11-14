#!/bin/bash
if ! grep '^LIBEVENT$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${LIBEVENT_SRC}
    get_file
    unpack

## get dependent library dir
    OPENSSL_SYMLINK=$(readlink -f /usr/local/openssl)
    OPENSSL_DIR=${OPENSSL_SYMLINK:-/usr/local/openssl}

    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}

## use ldflags and cppflags for compile and link
    LDFLAGS="-L${ZLIB_DIR}/lib -L${OPENSSL_DIR}/lib -Wl,-rpath,${ZLIB_DIR}/lib -Wl,-rpath,${OPENSSL_DIR}/lib"
    CPPFLAGS="-I${ZLIB_DIR}/include -I${OPENSSL_DIR}/include"
    
    CONFIG="./configure \
    --prefix=${INST_DIR}/${SRC_DIR} \
    --disable-static"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/libevent'
    compile

## record installed tag
    echo 'LIBEVENT' >> ${INST_LOG}
else
    succ_msg "libevent already installed!"
fi

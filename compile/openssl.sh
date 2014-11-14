#!/bin/bash
if ! grep '^OPENSSL$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${OPENSSL_SRC}
    get_file
    unpack
    
    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}

    PRE_CONFIG="./config \
    --prefix=${INST_DIR}/${SRC_DIR} \
    --openssldir=${INST_DIR}/${SRC_DIR} \
    shared threads zlib"
    
    CONFIG='make depend'
    MAKE='make'
    MAKE_TEST='make test'
    INSTALL='make install'
    SYMLINK='/usr/local/openssl'
    compile

## record installed tag
    echo 'OPENSSL' >> ${INST_LOG}
else
    succ_msg "OpenSSL already installed!"
fi

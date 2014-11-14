#!/bin/bash
if ! grep '^LIBMCRYPT$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${LIBMCRYPT_SRC}
    get_file
    unpack

## compile
    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR}"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/libmcrypt'
    compile

## record installed tag 
    echo 'LIBMCRYPT' >> ${INST_LOG}
else
    succ_msg "libmcrypt already installed!"
fi

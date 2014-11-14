#!/bin/bash
if ! grep '^ZLIB$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${ZLIB_SRC}
    get_file
    unpack
    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR}"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/zlib'
    compile

## record installed tag    
    echo 'ZLIB' >> ${INST_LOG}
else
    succ_msg "zlib already installed!"
fi

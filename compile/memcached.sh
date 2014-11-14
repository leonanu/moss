#!/bin/bash
if ! grep '^MEMCACHED$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${MEMCACHED_SRC}
    get_file
    unpack
    
    LIBEVENT_SYMLINK=$(readlink -f /usr/local/libevent)
    LIBEVENT_DIR=${LIBEVENT_SYMLINK:-/usr/local/libevent}

    LDFLAGS="-L${LIBEVENT_DIR}/lib -Wl,-rpath,${LIBEVENT_DIR}/lib"
    CPPFLAGS="-I${LIBEVENT_DIR}/include"

    CONFIG="./configure \
    --prefix=${INST_DIR}/${SRC_DIR} \
    --enable-64bit \
    --with-libevent=${LIBEVENT_DIR}"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/memcached'
    compile

## record installed tag   
    echo 'MEMCACHED' >> ${INST_LOG}
else
    succ_msg "memcached already installed!"
fi

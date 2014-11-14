#!/bin/bash
if ! grep '^PECL_MEMCACHED$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${PECL_MEMCACHED_SRC}
    get_file
    unpack

## find php installed dir
    PHP_SYMLINK=$(readlink -f /usr/local/php)
    PHP_DIR=${PHP_SYMLINK:-/usr/local/php}

    LIBMEMCACHED_SYMLINK=$(readlink -f /usr/local/libmemcached)
    LIBMEMCACHED_DIR=${LIBMEMCACHED_SYMLINK:-/usr/local/libmemcached}

    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}
    LDFLAGS="-L${ZLIB_DIR}/lib -Wl,-rpath,${ZLIB_DIR}/lib"
    CPPFLAGS="-I${ZLIB_DIR}/include"

    PRE_CONFIG="${PHP_DIR}/bin/phpize"
    CONFIG="./configure --enable-memcached --with-libmemcached-dir=${LIBMEMCACHED_DIR} --with-php-config=${PHP_DIR}/bin/php-config"
    MAKE='make'
    INSTALL='install -s -m 0755 modules/memcached.so ${PHP_DIR}/ext'
    compile
    cat ${TOP_DIR}/conf/php/memcached.ini >> /usr/local/php/etc/php.ini
    service php-fpm restart

## record installed tag
    echo 'PECL_MEMCACHED' >> ${INST_LOG}
else
    succ_msg "PECL-memcached already installed!"
fi

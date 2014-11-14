#!/bin/bash
if ! grep -E  '^PECL_MEMCACHE$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${PECL_MEMCACHE_SRC}
    get_file
    unpack

## find php installed dir
    PHP_SYMLINK=$(readlink -f /usr/local/php)
    PHP_DIR=${PHP_SYMLINK:-/usr/local/php}

    PRE_CONFIG="${PHP_DIR}/bin/phpize"
    CONFIG="./configure --enable-memcache --with-php-config=${PHP_DIR}/bin/php-config"
    MAKE='make'
    INSTALL='install -s -m 0755 modules/memcache.so ${PHP_DIR}/ext'
    compile
    cat ${TOP_DIR}/conf/php/memcache.ini >> /usr/local/php/etc/php.ini
    service php-fpm restart

## record installed tag
    echo 'PECL_MEMCACHE' >> ${INST_LOG}
else
    succ_msg "PECL-memcache already installed!"
fi

#!/bin/bash
if ! grep '^XCACHE$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${XCACHE_SRC}
    get_file

## find php installed dir
    PHP_SYMLINK=$(readlink -f /usr/local/php)
    PHP_DIR=${PHP_SYMLINK:-/usr/local/php}
    
    PRE_CONFIG="${PHP_DIR}/bin/phpize"
    CONFIG="./configure --with-php-config=${PHP_DIR}/bin/php-config --enable-xcache"
    MAKE='make'
    INSTALL='install -s -m 0755 modules/xcache.so ${PHP_DIR}/ext'

    unpack 
    compile
    cat ${TOP_DIR}/conf/php/xcache.ini >> /usr/local/php/etc/php.ini
    cp -r ${TOP_DIR}/conf/xcache/xcache_admin ${NGX_DOCROOT}/
    chown -R www.www ${NGX_DOCROOT}
    service php-fpm restart
## record installed tag    
    echo 'XCACHE' >> ${INST_LOG}
else
    succ_msg "XCache already installed!"
fi
